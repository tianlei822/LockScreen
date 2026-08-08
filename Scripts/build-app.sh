#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bundle_path="$project_root/.build/Threshold.app"
default_signing_identity="B4035AE98DA51B2F173CF52BAACC758E5B35DF63"
signing_identity=${APPLE_SIGNING_IDENTITY:-$default_signing_identity}
staging_root=""
previous_bundle=""
published=0

cleanup() {
  if [ "$published" -eq 0 ] && [ -n "$previous_bundle" ] \
    && [ -e "$previous_bundle" ] && [ ! -e "$bundle_path" ]; then
    /bin/mv "$previous_bundle" "$bundle_path" || true
  fi

  if [ -n "$staging_root" ] && [ -d "$staging_root" ]; then
    /bin/rm -rf -- "$staging_root"
  fi
}

trap cleanup EXIT
trap 'exit 1' HUP INT TERM

if [ "$signing_identity" = "-" ]; then
  echo "ad-hoc signing is disabled because it changes Threshold's macOS code identity after every rebuild" >&2
  exit 1
fi

available_identities=$(/usr/bin/security find-identity -v -p codesigning 2>/dev/null || true)
if ! printf '%s\n' "$available_identities" | /usr/bin/grep -Fq -- "$signing_identity"; then
  echo "code-signing identity not found: $signing_identity" >&2
  echo "install the local identity or set APPLE_SIGNING_IDENTITY to another certificate identity" >&2
  exit 1
fi

cd "$project_root"
swift build -c release
binary_dir=$(swift build -c release --show-bin-path)

mkdir -p "$project_root/.build"
staging_root=$(mktemp -d "$project_root/.build/Threshold.staging.XXXXXX")
staged_bundle="$staging_root/Threshold.app"
asset_info_path="$staging_root/ThresholdAppIcon-info.plist"

mkdir -p "$staged_bundle/Contents/MacOS" "$staged_bundle/Contents/Resources"
cp -f "$binary_dir/LockScreen" "$staged_bundle/Contents/MacOS/LockScreen"
cp -f "$project_root/Support/Info.plist" "$staged_bundle/Contents/Info.plist"

xcrun actool "$project_root/Support/Assets.xcassets" \
  --compile "$staged_bundle/Contents/Resources" \
  --platform macosx \
  --minimum-deployment-target 14.0 \
  --app-icon AppIcon \
  --output-partial-info-plist "$asset_info_path"

/usr/bin/codesign \
  --force \
  --options runtime \
  --timestamp=none \
  --sign "$signing_identity" \
  "$staged_bundle"
/usr/bin/codesign --verify --deep --strict "$staged_bundle"

domain="gui/$(id -u)"
label="com.tianlei.threshold"
service_info=$(launchctl print "$domain/$label" 2>/dev/null || true)
if printf '%s\n' "$service_info" \
  | /usr/bin/grep -Fq -- "$bundle_path/Contents/MacOS/LockScreen"; then
  echo "refusing to replace the bundle used by the running workspace LaunchAgent" >&2
  echo "stop it first: launchctl bootout $domain/$label" >&2
  exit 1
fi

if /usr/bin/pgrep -f "$bundle_path/Contents/MacOS/LockScreen" >/dev/null 2>&1; then
  echo "refusing to replace the bundle while Threshold is running from $bundle_path" >&2
  exit 1
fi

if [ -e "$bundle_path" ]; then
  previous_bundle="$staging_root/Previous.app"
  /bin/mv "$bundle_path" "$previous_bundle"
fi

/bin/mv "$staged_bundle" "$bundle_path"
published=1

if [ -n "$previous_bundle" ] && [ -e "$previous_bundle" ]; then
  /bin/rm -rf -- "$previous_bundle"
  previous_bundle=""
fi

echo "signed Threshold with $signing_identity"
echo "$bundle_path"
