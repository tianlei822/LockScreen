# Codex Project Experience

## Never overwrite a running signed app bundle

### Incident

On 2026-08-08, macOS repeatedly reported that Threshold had quit unexpectedly while the
workspace LaunchAgent was enabled. Most reports were not application logic crashes:

- `SIGKILL (Code Signature Invalid)`
- termination namespace `CODESIGNING`
- indicators `Taskgated Invalid Signature` and `Invalid Page`

The two reports often appeared as a pair during one rebuild.

### Root cause

`com.tianlei.threshold` runs this bundle with `KeepAlive`:

```text
.build/Threshold.app/Contents/MacOS/LockScreen --background
```

The packaging script copied a new executable and resources directly into that same bundle before
signing it. This mutated code pages belonging to the running, already-signed process. macOS killed
the process when its loaded pages no longer matched its code signature. `KeepAlive` then raced to
launch the partially rebuilt bundle before signing completed, producing the second invalid-signature
report.

This can look like a SwiftUI or animation crash, but a `CODESIGNING` termination has no application
stack-based fix.

### Project invariants

1. Never copy, strip, re-sign, or replace files inside the app bundle currently used by a running
   process.
2. Never expose a partially assembled or unsigned bundle at the path referenced by the LaunchAgent.
3. Build and sign a complete candidate in a unique sibling staging directory first.
4. Verify the staged signature before stopping the healthy process.
5. Stop the LaunchAgent, atomically move the verified candidate into place, and then bootstrap the
   LaunchAgent again.
6. If atomic staging is unavailable, stop the LaunchAgent before the first in-place bundle write.
7. Do not fall back to ad-hoc signing. Threshold uses the stable Jarvis development identity
   `B4035AE98DA51B2F173CF52BAACC758E5B35DF63` to preserve code identity and TCC continuity.
8. For local use, keep the LaunchAgent pointed at `.build/Threshold.app` with `--workspace`; do not
   install an application copy unless the user explicitly requests it.

### Safe rebuild order

```text
swift release build
  -> assemble a unique sibling staging bundle
  -> codesign the staging bundle
  -> codesign --verify the staging bundle
  -> launchctl bootout com.tianlei.threshold
  -> atomically replace .build/Threshold.app
  -> launchctl bootstrap com.tianlei.threshold
  -> verify the new process and global hot-key registration
```

Keep the currently working bundle and process intact if compilation, asset compilation, signing, or
signature verification fails.

### Diagnosis commands

List Threshold crash reports:

```sh
rg --files "$HOME/Library/Logs/DiagnosticReports" | rg '/(LockScreen|Threshold).*\.(ips|crash)$'
```

Inspect the structured body of an `.ips` report; the first line is separate metadata:

```sh
tail -n +2 /path/to/LockScreen-report.ips \
  | jq '{captureTime, exception, termination, faultingThread}'
```

Inspect the live workspace service:

```sh
launchctl print "gui/$(id -u)/com.tianlei.threshold"
```

Verify the completed bundle:

```sh
codesign --verify --deep --strict .build/Threshold.app
codesign -d -r- .build/Threshold.app
```

The sandbox may report `0 valid identities found` even when the login keychain contains the Jarvis
identity. Before diagnosing a missing certificate, repeat this read-only check outside the sandbox:

```sh
security find-identity -v -p codesigning
```

### Verification checklist

- The build never writes into the live bundle before the old service is stopped.
- The candidate passes `codesign --verify --deep --strict` before publication.
- `launchctl print` shows `state = running` and the expected workspace executable path.
- The new process remains alive and registers the global shortcut.
- No new `CODESIGNING` report appears during the rebuild and reload.

### Distinguish unrelated historical crashes

Two reports from 2026-08-06 were real `SIGSEGV` failures in
`VaultDoorArtwork.body`/`TimelineView`. A 2026-08-07 `SIGABRT` occurred while AppKit registration was
attempted from a Codex-launched environment. Treat those separately; do not conflate them with the
recurring paired `CODESIGNING` reports caused by live-bundle mutation.

## Keep the status-bar icon background transparent

### Why the black background returned

The first transparency fix replaced the status button's normal image with a template symbol in a
child `NSImageView` and set `isTransparent`. That only controlled the button's own resting draw.
The menu was still assigned through `NSStatusItem.menu`, so AppKit retained ownership of the
standard pressed/menu-tracking highlight. Menu interaction and later status-item state changes could
therefore restore the dark rounded backing even though the icon asset itself was transparent.

This was a behavioral gap in the original fix, not a black background embedded in the SF Symbol or
app icon. Rebuilding or changing unrelated formation artwork could make the stale behavior visible
again, which made it look like unrelated iterations had reverted the icon.

### Project invariants

1. Use a template SF Symbol rendered by the child `NSImageView`; do not introduce a bitmap
   background.
2. Keep `NSStatusBarButton.isTransparent` enabled and clear `NSButtonCell.highlightsBy` and
   `showsStateBy`.
3. Retain the menu separately and open it from the status button action with `NSMenu.popUp`.
4. Never assign the menu through `NSStatusItem.menu`; that reconnects AppKit's automatic dark
   highlight path.
5. Clear the button's state and highlight before and after menu tracking.
6. Run `sh Scripts/check-status-item-appearance.sh` after changes to application startup, status-bar
   behavior, menus, icons, or `LockScreenApp.swift`.

The automated guard intentionally fails if any required transparent-button configuration disappears
or if `item.menu = ...` is reintroduced.
