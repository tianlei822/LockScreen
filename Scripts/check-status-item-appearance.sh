#!/bin/sh

# Protect the transparent menu-bar item from regressions. An NSMenu attached
# through NSStatusItem.menu re-enables AppKit's standard dark highlight path.

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_file="$project_root/Sources/LockScreenApp/LockScreenApp.swift"

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
require_source 'button.action = #selector(showStatusMenu(_:))'
require_source 'statusMenu.popUp(positioning: nil, at: .zero, in: sender)'

if /usr/bin/grep -Eq '^[[:space:]]*item\.menu[[:space:]]*=' "$source_file"; then
  echo 'do not attach the menu through NSStatusItem.menu; it restores the dark highlight' >&2
  exit 1
fi

echo "status-item appearance guard passed"
