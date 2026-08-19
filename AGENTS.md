# Threshold Agent Notes

## Status-item background regression / 状态栏图标黑底回归

### Incident and cause / 现象与原因

- Symptom: the lock status item can intermittently retain a black pressed background after its menu closes or application/menu-bar state changes. / 现象：锁形状态栏图标会在菜单关闭或应用、菜单栏状态变化后，间歇性残留黑色按压背景。
- Confirmed primary cause: background startup and ritual retreat called `NSApp.hide(nil)` while the accessory app owned a live status item. On the first LaunchAgent bootstrap this whole-application hide transition could leave AppKit's system-managed status-item backing pressed. The same signed binary rendered correctly after KeepAlive restarted it, isolating process startup state rather than stale code as the differentiator. / 已确认主因：后台启动和仪式退回路径在 accessory app 持有状态项时调用了 `NSApp.hide(nil)`；首次 LaunchAgent bootstrap 的整应用隐藏转换可能让 AppKit 管理的状态项底色停留在按压态。同一签名二进制经 KeepAlive 重启后显示正常，说明差异来自进程启动状态，而不是旧代码。
- Independent contributing risk: presenting `NSMenu` synchronously with `statusMenu.popUp(..., in: sender)` associates menu tracking with `NSStatusBarButton` and can also let AppKit reapply its pressed backing after local cell flags are cleared. / 独立风险：同步调用 `statusMenu.popUp(..., in: sender)` 会把菜单跟踪与 `NSStatusBarButton` 关联，也可能在本地 cell 标志被清除后重新设置按压底色。
- Repaint delays, activation observers, and repeated `highlight(false)` calls only mask either race and are not root-cause fixes. / 延迟重绘、激活观察器和反复调用 `highlight(false)` 只能掩盖竞争条件，不是根因修复。

### Required design / 必须保持的设计

- Keep the background application unhidden. Use `.accessory` activation policy to suppress Dock/application-menu presence and `window.orderOut(nil)` to hide ritual windows. Do not call `NSApp.hide(nil)` from `AppDelegate` background startup or `WindowPresentation.retreatToBackground`.
- Keep the menu detached from the status-bar button: compute a screen-coordinate anchor with `StatusItemController.detachedMenuPresentation(from:)`, yield until button tracking has completed, then call `NSMenu.popUp` with `view = nil`.
- Keep the status-item image as a template image rendered by the child `NSImageView`, and preserve the AppKit-managed button cell.
- Never assign the menu to `NSStatusItem.menu` and never pass `NSStatusBarButton` (or `sender`) as the `in:` view of `NSMenu.popUp`.
- Do not treat additional timers, activation observers, or repeated `highlight(false)` calls as a root-cause fix. They may remain defensive, but the unhidden accessory lifecycle and detached menu presentation are invariants.

### Fix status / 修复状态

- Menu-tracking safeguard: commit `c5a6160` (`fix: detach status menu from menu bar button`), 2026-08-19.
- Background-lifecycle fix: `fix: keep status-item app unhidden in background`, 2026-08-19. It removes whole-application hiding from initial background setup and ritual retreat.
- Regression coverage: `WindowPresentationTests.testStatusMenuPresentationIsDetachedFromStatusBarButton` verifies the screen anchor and `view = nil`; `Scripts/check-status-item-appearance.sh` rejects button-anchored menus and `NSApp.hide(nil)` in the status-item lifecycle.
- The signed lifecycle fix must be deployed and pass the first-bootstrap plus post-ritual runtime sequence below before claiming the incident closed.

### Required verification / 必须验证

```sh
swift test --filter WindowPresentationTests
sh Scripts/check-status-item-appearance.sh
xcrun swift-format lint -r Sources Tests Package.swift
swift test
APPLE_SIGNING_IDENTITY=B4035AE98DA51B2F173CF52BAACC758E5B35DF63 sh Scripts/build-app.sh
/usr/bin/codesign --verify --deep --strict --verbose=2 .build/Threshold.app
```

Runtime acceptance: verify the very first LaunchAgent bootstrap without manually restarting it; open and close the status menu repeatedly; complete a background ritual and return to the desktop; click elsewhere, switch Spaces, and exercise sleep/wake or display changes. The icon may use the normal pressed appearance while the pointer is actively down, but no black background may remain afterward. / 运行验收：必须检查 LaunchAgent 首次 bootstrap，不能先手动重启；反复打开关闭菜单；完成一次后台仪式并返回桌面；再覆盖点击其他区域、切换 Space、睡眠唤醒和显示器变化。鼠标按下期间可出现系统正常按压效果，但之后不得残留黑底。
