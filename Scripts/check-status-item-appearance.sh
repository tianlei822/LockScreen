#!/bin/sh

# Protect the transparent menu-bar item from regressions. An NSMenu attached
# through NSStatusItem.menu re-enables AppKit's standard dark highlight path.

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_file="$project_root/Sources/LockScreenApp/StatusItemController.swift"

require_source() {
  if ! /usr/bin/grep -Fq -- "$1" "$source_file"; then
    echo "status-item appearance guard missing: $1" >&2
    exit 1
  fi
}

require_source 'image?.isTemplate = true'
require_source 'button.isTransparent = true'
require_source 'buttonCell.highlightsBy = []'
require_source 'buttonCell.showsStateBy = []'
require_source 'buttonCell.isHighlighted = false'
require_source 'button.action = #selector(showStatusMenu(_:))'
require_source 'statusMenu.popUp(positioning: nil, at: .zero, in: sender)'
require_source 'private func applyTransparentAppearance'
require_source 'static let appearanceRefreshDelays'
require_source 'scheduleAppearanceRefresh()'
require_source 'try await Task.sleep(for: delay)'
require_source 'Self.configureTransparentAppearance(button)'

if /usr/bin/grep -Eq '^[[:space:]]*button\.cell[[:space:]]*=' "$source_file"; then
  echo 'do not replace the AppKit-managed status-bar button cell' >&2
  exit 1
fi

if /usr/bin/grep -Eq '^[[:space:]]*item\.menu[[:space:]]*=' "$source_file"; then
  echo 'do not attach the menu through NSStatusItem.menu; it restores the dark highlight' >&2
  exit 1
fi

echo "status-item appearance guard passed"
