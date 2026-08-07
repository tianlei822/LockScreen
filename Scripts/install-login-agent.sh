#!/bin/sh

# Installs (or with --uninstall, removes) a LaunchAgent that starts Threshold
# in background mode at login, so ⌘L summons the lock ritual anytime.

set -eu

label="com.tianlei.threshold"
plist="$HOME/Library/LaunchAgents/$label.plist"
project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_app="$project_root/.build/Threshold.app"
installed_app=${THRESHOLD_INSTALL_PATH:-$HOME/Applications/Threshold.app}
binary="$installed_app/Contents/MacOS/LockScreen"
domain="gui/$(id -u)"

if [ "${1:-}" = "--uninstall" ]; then
  launchctl bootout "$domain/$label" 2>/dev/null || true
  rm -f "$plist"
  echo "removed $label; kept $installed_app"
  exit 0
fi

if [ ! -x "$source_app/Contents/MacOS/LockScreen" ]; then
  echo "bundle not found at $source_app — run sh Scripts/build-app.sh first" >&2
  exit 1
fi

/usr/bin/codesign --verify --deep --strict "$source_app"
source_requirement=$(/usr/bin/codesign -d -r- "$source_app" 2>&1)
if printf '%s\n' "$source_requirement" | /usr/bin/grep -Fq "cdhash "; then
  echo "refusing to install an ad-hoc build with a rebuild-specific code identity" >&2
  exit 1
fi

mkdir -p "$(dirname -- "$installed_app")"
/usr/bin/ditto --rsrc --extattr "$source_app" "$installed_app"
/usr/bin/codesign --verify --deep --strict "$installed_app"

cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$label</string>
    <key>ProgramArguments</key>
    <array>
        <string>$binary</string>
        <string>--background</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

launchctl bootout "$domain/$label" 2>/dev/null || true

# `bootout` may return before launchd finishes removing the old service.
# Wait for that asynchronous removal before loading the replacement plist.
retry_count=0
while launchctl print "$domain/$label" >/dev/null 2>&1; do
  retry_count=$((retry_count + 1))
  if [ "$retry_count" -ge 20 ]; then
    echo "timed out waiting for $label to stop" >&2
    exit 1
  fi
  sleep 0.1
done

launchctl bootstrap "$domain" "$plist"

retry_count=0
until launchctl print "$domain/$label" 2>/dev/null | /usr/bin/grep -Fq "state = running"; do
  retry_count=$((retry_count + 1))
  if [ "$retry_count" -ge 30 ]; then
    echo "$label did not reach the running state" >&2
    exit 1
  fi
  sleep 0.1
done

echo "installed $label at $installed_app — Threshold stays ready in the background; press ⌘L to lock"
