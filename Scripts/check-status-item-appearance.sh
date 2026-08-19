#!/bin/sh

# Keep the menu-bar item on AppKit's standard, template-image path. Historical
# attempts to fight NSStatusBarButton drawing introduced intermittent backing
# state instead of fixing it.

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_file="$project_root/Sources/LockScreenApp/StatusItemController.swift"
app_delegate_file="$project_root/Sources/LockScreenApp/AppDelegate.swift"
window_presentation_file="$project_root/Sources/LockScreenApp/WindowPresentation.swift"
info_plist="$project_root/Support/Info.plist"

require_source() {
  if ! /usr/bin/grep -Fq -- "$1" "$source_file"; then
    echo "status-item appearance guard missing: $1" >&2
    exit 1
  fi
}

require_source 'image.isTemplate = true'
require_source 'button.image = image'
require_source 'item.menu = menu'

if [ "$(/usr/libexec/PlistBuddy -c 'Print :LSUIElement' "$info_plist")" != "true" ]; then
  echo 'LSUIElement must be true so LaunchServices registers a menu-bar app from process launch' >&2
  exit 1
fi

if /usr/bin/grep -Eq '^[[:space:]]*button\.cell[[:space:]]*=' "$source_file"; then
  echo 'do not replace the AppKit-managed status-bar button cell' >&2
  exit 1
fi

for obsolete_pattern in \
  'NSImageView(' \
  'button.addSubview' \
  'configureTransparentAppearance' \
  'appearanceRefresh' \
  'refreshAppearance' \
  'cancelPendingRefresh' \
  'button.isTransparent' \
  'button.isBordered' \
  'button.highlight(' \
  'button.state' \
  'button.cell' \
  'buttonCell.highlightsBy' \
  'statusMenu.popUp' \
  'NSMenuDelegate'
do
  if /usr/bin/grep -Fq -- "$obsolete_pattern" "$source_file"; then
    echo "obsolete status-item appearance logic found: $obsolete_pattern" >&2
    exit 1
  fi
done

if /usr/bin/grep -Fq -- 'NSApp.hide(nil)' "$app_delegate_file"; then
  echo 'do not hide the application while installing the background status item' >&2
  exit 1
fi

if /usr/bin/grep -Fq -- 'NSApp.hide(nil)' "$window_presentation_file"; then
  echo 'do not hide the application when retreating a status-item app' >&2
  exit 1
fi

echo "status-item appearance guard passed"
