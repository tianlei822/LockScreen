#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bundle_path="$project_root/.build/Threshold.app"
default_signing_identity="B4035AE98DA51B2F173CF52BAACC758E5B35DF63"
signing_identity=${APPLE_SIGNING_IDENTITY:-$default_signing_identity}

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

mkdir -p "$bundle_path/Contents/MacOS" "$bundle_path/Contents/Resources"
cp -f "$binary_dir/LockScreen" "$bundle_path/Contents/MacOS/LockScreen"
cp -f "$project_root/Support/Info.plist" "$bundle_path/Contents/Info.plist"

/usr/bin/codesign \
  --force \
  --options runtime \
  --timestamp=none \
  --sign "$signing_identity" \
  "$bundle_path"
/usr/bin/codesign --verify --deep --strict "$bundle_path"

echo "signed Threshold with $signing_identity"
echo "$bundle_path"
