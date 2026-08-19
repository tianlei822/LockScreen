# Threshold Agent Notes

## Status-item black-background regression / 状态栏图标黑底回归

### Confirmed design error / 已确认的设计错误

- Symptom: the lock status item intermittently retained a black pressed background after menu or application-state transitions. / 现象：锁形状态栏图标会在菜单或应用状态切换后间歇性残留黑色按压背景。
- Runtime evidence from an affected process showed LaunchServices checking it in as `foreground=1 uiElement=0`. `Support/Info.plist` did not declare `LSUIElement`, so the process was born as a foreground app and only changed to `.accessory` after launch. A KeepAlive restart happened to avoid the visible bad state, but did not fix the registration race. / 故障进程日志显示 LaunchServices 以 `foreground=1 uiElement=0` 注册它；当时 `Support/Info.plist` 未声明 `LSUIElement`，导致进程先按前台应用启动，启动后才切到 `.accessory`。KeepAlive 重启后偶然正常，只是绕过了注册时序，并非修复。
- Historical workarounds fought AppKit's state machine: a child `NSImageView`, button transparency/border changes, `NSButtonCell` highlight mutations, repeated refresh timers and activation observers, detached/manual `NSMenu.popUp`, and repeated `highlight(false)`. They increased state and race surfaces and have been removed. / 历史补丁直接干预 AppKit 状态机，包括子 `NSImageView`、按钮透明度/边框、`NSButtonCell` 高亮标志、重复刷新计时器与激活观察器、分离/手动 `NSMenu.popUp`、反复 `highlight(false)`；这些逻辑扩大了状态和竞态面，现已删除。
- Calling `NSApp.hide(nil)` while the background status item is alive is an additional lifecycle risk. Background windows must be hidden with `orderOut(nil)` while the application remains unhidden. / 后台状态项存活时调用 `NSApp.hide(nil)` 也是额外生命周期风险；应使用 `orderOut(nil)` 隐藏窗口，应用本身保持未隐藏。

### Required invariant / 必须保持的约束

- `Support/Info.plist` must contain `LSUIElement = true`, so LaunchServices registers the menu-bar app correctly from process birth. / `Support/Info.plist` 必须包含 `LSUIElement = true`，让 LaunchServices 从进程启动时就按菜单栏应用注册。
- `applicationWillFinishLaunching` must use `.accessory` in background mode and `.regular` for foreground previews. / `applicationWillFinishLaunching` 必须在后台模式使用 `.accessory`，前台预览使用 `.regular`。
- Use the standard AppKit contract only: create `NSStatusItem`, mark the symbol as a template image, assign it to `NSStatusBarButton.image`, and attach the menu with `NSStatusItem.menu`. / 只使用 AppKit 标准契约：创建 `NSStatusItem`，将图标标记为模板图并赋给 `NSStatusBarButton.image`，菜单赋给 `NSStatusItem.menu`。
- Do not add status-button subviews; mutate button transparency, borders, state, highlight, or cell flags; schedule appearance-refresh tasks; observe activation solely to redraw the icon; or present its menu manually. / 禁止添加状态按钮子视图；禁止修改透明度、边框、状态、高亮或 cell 标志；禁止外观刷新任务、仅为重绘图标的激活观察器、手动弹出菜单。
- In background mode, hide ritual windows with `orderOut(nil)` and do not call `NSApp.hide(nil)` from startup or `WindowPresentation.retreatToBackground`. / 后台模式用 `orderOut(nil)` 隐藏仪式窗口；启动和 `WindowPresentation.retreatToBackground` 不得调用 `NSApp.hide(nil)`。

### Fix status / 修复状态

- The earlier detached-menu change `c5a6160` and later repaint/lifecycle workarounds were interim attempts, not the durable model; do not restore them. / 早期分离菜单提交 `c5a6160` 及后续重绘/生命周期补丁只是阶段性尝试，不是长期设计，禁止恢复。
- The durable fix adds static `LSUIElement` registration and replaces the controller with the standard template-image/menu path. `Scripts/check-status-item-appearance.sh` guards this invariant and rejects the removed patterns. / 长期修复是静态声明 `LSUIElement`，并把控制器恢复为标准模板图/菜单实现；`Scripts/check-status-item-appearance.sh` 固化约束并拒绝已删除模式。
- A system-drawn pressed background while the menu is open is normal. A background remaining after the menu closes is a regression. / 菜单打开时系统绘制的按压底色属于正常；菜单关闭后仍残留才是回归。

### Required verification / 必须验证

```sh
swift test --filter WindowPresentationTests
sh Scripts/check-status-item-appearance.sh
xcrun swift-format lint -r Sources Tests Package.swift
swift test
APPLE_SIGNING_IDENTITY=B4035AE98DA51B2F173CF52BAACC758E5B35DF63 sh Scripts/build-app.sh
/usr/bin/codesign --verify --deep --strict --verbose=2 .build/Threshold.app
```

Runtime acceptance: verify the first LaunchAgent bootstrap without manually restarting it; confirm LaunchServices registers the process as a UI element; repeatedly open and close the menu; complete a background ritual; then test Space and display-state changes. No black background may remain after menu tracking ends. / 运行验收：检查 LaunchAgent 首次 bootstrap，不先手动重启；确认 LaunchServices 将进程注册为 UI element；反复开关菜单，完成一次后台仪式，再测试 Space 与显示状态切换。菜单跟踪结束后不得残留黑底。
