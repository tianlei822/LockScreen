#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
info_plist="$project_root/Support/Info.plist"
display_name=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$info_plist")
executable_name=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$info_plist")
bundle_identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$info_plist")
minimum_system_version=$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$info_plist")
default_bundle_path="$project_root/.build/$display_name.app"
configured_bundle_path=${THRESHOLD_BUILD_PATH:-$default_bundle_path}
case "$configured_bundle_path" in
  /*) bundle_path=$configured_bundle_path ;;
  *) bundle_path="$project_root/$configured_bundle_path" ;;
esac
bundle_parent=$(dirname -- "$bundle_path")
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
  echo "ad-hoc signing is disabled because it changes $display_name's macOS code identity after every rebuild" >&2
  exit 1
fi

case "$bundle_path" in
  *.app) ;;
  *)
    echo "THRESHOLD_BUILD_PATH must end in .app: $bundle_path" >&2
    exit 1
    ;;
esac

available_identities=$(/usr/bin/security find-identity -v -p codesigning 2>/dev/null || true)
if ! printf '%s\n' "$available_identities" | /usr/bin/grep -Fq -- "$signing_identity"; then
  echo "code-signing identity not found: $signing_identity" >&2
  echo "install the local identity or set APPLE_SIGNING_IDENTITY to another certificate identity" >&2
  exit 1
fi

cd "$project_root"
swift build -c release
binary_dir=$(swift build -c release --show-bin-path)

mkdir -p "$bundle_parent"
staging_root=$(mktemp -d "$bundle_parent/$display_name.staging.XXXXXX")
staged_bundle="$staging_root/$display_name.app"
asset_info_path="$staging_root/AppIcon-info.plist"

mkdir -p "$staged_bundle/Contents/MacOS" "$staged_bundle/Contents/Resources"
cp -f "$binary_dir/$executable_name" "$staged_bundle/Contents/MacOS/$executable_name"
cp -f "$info_plist" "$staged_bundle/Contents/Info.plist"

for resource_bundle in "$binary_dir"/*.bundle; do
  if [ -d "$resource_bundle" ]; then
    /usr/bin/ditto "$resource_bundle" \
      "$staged_bundle/Contents/Resources/$(basename -- "$resource_bundle")"
  fi
done

xcrun actool "$project_root/Support/Assets.xcassets" \
  --compile "$staged_bundle/Contents/Resources" \
  --platform macosx \
  --minimum-deployment-target "$minimum_system_version" \
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
label="$bundle_identifier"
service_info=$(launchctl print "$domain/$label" 2>/dev/null || true)
if printf '%s\n' "$service_info" \
  | /usr/bin/grep -Fq -- "$bundle_path/Contents/MacOS/$executable_name"; then
  echo "refusing to replace the bundle used by the running workspace LaunchAgent" >&2
  echo "stop it first: launchctl bootout $domain/$label" >&2
  exit 1
fi

if /usr/bin/pgrep -f "$bundle_path/Contents/MacOS/$executable_name" >/dev/null 2>&1; then
  echo "refusing to replace the bundle while $display_name is running from $bundle_path" >&2
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

echo "signed $display_name with $signing_identity"
echo "$bundle_path"
