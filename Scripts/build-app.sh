#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bundle_path="$project_root/.build/Threshold.app"

cd "$project_root"
swift build -c release
binary_dir=$(swift build -c release --show-bin-path)

mkdir -p "$bundle_path/Contents/MacOS" "$bundle_path/Contents/Resources"
cp -f "$binary_dir/LockScreen" "$bundle_path/Contents/MacOS/LockScreen"
cp -f "$project_root/Support/Info.plist" "$bundle_path/Contents/Info.plist"

codesign --force --sign - "$bundle_path"

echo "$bundle_path"
