# Threshold Agent Notes

## Status-item background regression / 状态栏图标黑底回归

### Incident and cause / 现象与原因

- Symptom: the lock status item can intermittently retain a black pressed background after its menu closes or application/menu-bar state changes. / 现象：锁形状态栏图标会在菜单关闭或应用、菜单栏状态变化后，间歇性残留黑色按压背景。
- Root cause: presenting `NSMenu` synchronously from the button action with `statusMenu.popUp(..., in: sender)` keeps menu tracking associated with `NSStatusBarButton`. AppKit can then reapply the status-item container's pressed backing after local `NSButtonCell` flags have been cleared. The timing dependency is why repaint delays appeared to fix the bug temporarily but did not prevent recurrence. / 根因：在按钮 action 中同步调用 `statusMenu.popUp(..., in: sender)`，会让菜单跟踪与 `NSStatusBarButton` 保持关联；即使已清除本地 `NSButtonCell` 高亮标志，AppKit 仍可能重新设置状态项容器的按压底色。该竞争条件导致延迟重绘只能暂时掩盖问题。

### Required design / 必须保持的设计

- Keep the menu detached from the status-bar button: compute a screen-coordinate anchor with `StatusItemController.detachedMenuPresentation(from:)`, yield until button tracking has completed, then call `NSMenu.popUp` with `view = nil`.
- Keep the status-item image as a template image rendered by the child `NSImageView`, and preserve the AppKit-managed button cell.
- Never assign the menu to `NSStatusItem.menu` and never pass `NSStatusBarButton` (or `sender`) as the `in:` view of `NSMenu.popUp`.
- Do not treat additional timers, activation observers, or repeated `highlight(false)` calls as a root-cause fix. They may remain defensive, but detached menu presentation is the invariant.

### Fix status / 修复状态

- Root-cause implementation: commit `c5a6160` (`fix: detach status menu from menu bar button`), 2026-08-19.
- Regression coverage: `WindowPresentationTests.testStatusMenuPresentationIsDetachedFromStatusBarButton` verifies the screen anchor and `view = nil`; `Scripts/check-status-item-appearance.sh` rejects button-anchored menu presentation.
- At the time this note was added, all 68 tests, Swift format lint, and the status-item appearance guard passed. A signed runtime build must still be deployed and checked before claiming the incident closed.

### Required verification / 必须验证

```sh
swift test --filter WindowPresentationTests
sh Scripts/check-status-item-appearance.sh
xcrun swift-format lint -r Sources Tests Package.swift
swift test
APPLE_SIGNING_IDENTITY=B4035AE98DA51B2F173CF52BAACC758E5B35DF63 sh Scripts/build-app.sh
/usr/bin/codesign --verify --deep --strict --verbose=2 .build/Threshold.app
```

Runtime acceptance: open and close the status menu repeatedly, click elsewhere, switch Spaces, and exercise sleep/wake or display changes. The icon may use the normal pressed appearance while the pointer is actively down, but no black background may remain after tracking/menu close. / 运行验收：反复打开关闭菜单、点击其他区域、切换 Space，并覆盖睡眠唤醒或显示器变化；鼠标按下期间可出现系统正常按压效果，但跟踪或菜单关闭后不得残留黑底。
