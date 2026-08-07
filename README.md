# Threshold for macOS

Threshold is a native, full-bleed SwiftUI lock-screen ritual for macOS. Knock the wooden door rings, trace a configurable formation, or open a steel vault with a locally configured ritual code. It does not collect system credentials or replace macOS authentication.

Threshold 是一个全屏铺底的原生 SwiftUI macOS 锁屏仪式应用：敲击木门门环、沿阵法轨迹充能，或输入本地配置的仪式密码打开钢制保险库。它不会收集系统密码，也不会替换 macOS 系统认证。

## Run / 运行

Requirements: macOS 14 or later and Xcode 16 or later.

要求：macOS 14 或更高版本、Xcode 16 或更高版本。

```sh
# Build and run; covers the current workspace with an immersive borderless window.
# 构建并运行；启动后以无边框沉浸窗口覆盖当前工作页面。
swift run LockScreen

# Development preview without automatic fullscreen.
# 使用窗口化开发预览。
swift run LockScreen --windowed

# Open the formation theme directly in a windowed preview.
# 直接以窗口模式预览阵法主题。
swift run LockScreen --windowed --formation

# Open the vault directly. Its default ritual code is 1024.
# 直接打开密码箱；默认仪式密码为 1024。
swift run LockScreen --vault

# Configure a 4–8 digit ritual code for this launch.
# 为本次启动配置 4–8 位仪式密码。
swift run LockScreen --vault --passcode=2580

# Create a certificate-signed local app bundle at .build/Threshold.app.
# 在 .build/Threshold.app 创建证书签名的本地应用包。
sh Scripts/build-app.sh
open .build/Threshold.app

# Lurk in the background (status-menu lock icon) and summon the ritual with ⌘L.
# 后台潜伏（状态栏锁形图标），随时按 ⌘L 召唤锁屏仪式。
open .build/Threshold.app --args --background

# Start the background lurker automatically at login (remove with --uninstall).
# 登录时自动启动后台潜伏；应用会安装到 ~/Applications/Threshold.app（用 --uninstall 移除启动项）。
sh Scripts/install-login-agent.sh
```

`⌘L` is registered by Threshold's status-bar-only background process. A macOS App Shortcut cannot
launch a terminated app, so run the installer above once: launchd keeps the receiver alive and
restarts it if it exits. The main window and Dock icon do not need to be open. Carbon registers only
this exact key combination, so Threshold does not request Accessibility or Input Monitoring access.
`⌘L` 由 Threshold 仅驻留状态栏的后台进程注册。macOS“App 快捷键”无法启动已退出的应用，
因此请至少执行一次上面的安装脚本：launchd 会让接收进程保持运行，并在退出后自动重启；
主窗口和 Dock 图标都不需要打开。Carbon 只注册这一组按键，因此 Threshold 不会申请“辅助功能”
或“输入监控”权限。

Local builds default to the login-keychain identity `Jarvis Codex Local Development` (SHA-1
`B4035AE98DA51B2F173CF52BAACC758E5B35DF63`), matching the Jarvis packaging setup on this Mac.
The build stops if that identity is unavailable and never falls back to ad-hoc signing, whose
build-specific `cdhash` can invalidate macOS code-identity and TCC continuity. Override the identity
for another certificate with `APPLE_SIGNING_IDENTITY`; public distribution still requires an Apple
Developer ID certificate and notarization.

本机默认使用登录钥匙串中的 `Jarvis Codex Local Development` identity（SHA-1
`B4035AE98DA51B2F173CF52BAACC758E5B35DF63`），与 Jarvis 的打包配置一致。找不到该 identity
时构建会直接失败，不会回退到随每次构建改变 `cdhash` 的 ad-hoc 签名，从而保持 macOS 代码身份和
TCC 权限连续性。可通过 `APPLE_SIGNING_IDENTITY` 指定其他证书；对外发布仍需 Apple Developer ID
证书和 notarization。

## Controls / 操作

- Choose `Wooden Door`, `Formation Gate`, or `Cipher Vault` in the upper-left corner. / 在左上角选择木门、阵法门或密码箱。
- On `Wooden Door`, knock either brass ring three times. / 在 `Wooden Door` 中，敲击任意黄铜门环三次。
- On `Formation Gate`, choose `Circle`, `Infinity`, or `Triangle`, then drag along the glowing track to charge it. Press `Return` for the keyboard-accessible channel action. / 在 `Formation Gate` 中选择 `Circle`、`Infinity` 或 `Triangle`，然后沿发光轨迹拖动充能；也可按 `Return` 使用键盘触发。
- On `Cipher Vault`, enter the configured code with the keyboard or keypad, then press `Return` or the unlock key. The default is `1024`; this is only an app ritual code, never your macOS password. / 在 `Cipher Vault` 中使用键盘或数字键盘输入配置密码，再按 `Return` 或开锁键。默认值为 `1024`；它只是应用仪式密码，绝不能使用 macOS 系统密码。
- After a successful ritual, the doors finish opening, the app hides immediately, and the previous workspace becomes active without an intermediate window. / 仪式成功后，门完成开启，应用立即隐藏并激活之前的工作页面，不再出现中间窗口。
- Press `⇧⌘F` or use the upper-right button to toggle immersive/windowed mode. / 按 `⇧⌘F` 或点击右上角按钮切换沉浸/窗口模式。
- Press `⌘L` anywhere to summon the ritual while the background lurker runs (registered globally via Carbon, so it also works on top of other apps; it takes precedence over apps that use `⌘L` themselves, e.g. browser address bars). / 后台潜伏运行时在任意处按 `⌘L` 召唤仪式（经 Carbon 全局注册，在其他应用之上也生效；会抢占浏览器地址栏等自身使用 `⌘L` 的场景）。
- Immersive mode is a kiosk-style takeover: the menu bar and Dock are hidden, secondary displays are blanked, and app switching/force quit are disabled while the ritual is frontmost. Exit with `⇧⌘F` or `⌘Q`. Note that an unbundled `swift run` binary is not allowed to become the frontmost app on recent macOS, so full coverage requires the bundled app from `sh Scripts/build-app.sh`. / 沉浸模式是 kiosk 式接管：隐藏菜单栏与程序坞、副屏黑屏遮盖，且仪式在前台时禁用应用切换与强制退出；可用 `⇧⌘F` 或 `⌘Q` 退出。注意 macOS 不允许未打包的 `swift run` 二进制成为最前应用，完整覆盖效果需使用 `sh Scripts/build-app.sh` 打包后的应用。

## Verification / 验证

```sh
swift format lint --recursive Sources Tests
swift test
swift build -c release
plutil -lint Support/Info.plist
sh Scripts/build-app.sh
codesign --verify --deep --strict .build/Threshold.app
codesign -d -r- .build/Threshold.app
```

## System lock integration / 系统锁屏衔接

Apple's public APIs do not provide a supported way for a third-party app to replace the password or Touch ID lock interface. The immersive mode therefore hardens the app itself (kiosk presentation options, edge-to-edge coverage, blanked secondary displays) instead of intercepting system authentication. While the ritual is up it also holds an `IOPMAssertion` and periodically declares user activity, so the system screen saver / display sleep cannot fire the real loginwindow underneath it. A later release can provide the passive animation as a `.saver` module and ask macOS to perform the real lock; the interactive ritual remains an app experience before or after that secure boundary.

Apple 公开 API 不支持第三方应用替换密码或 Touch ID 锁屏界面。因此沉浸模式改为加固应用自身（kiosk 展示选项、无死角落满屏、副屏遮盖），而不拦截系统认证。仪式覆盖期间还会持有 `IOPMAssertion` 并周期性声明用户活动，避免系统屏保/显示器休眠在其下方触发真正的登录窗口。后续版本可以把被动动画封装为 `.saver` 模块，并交由 macOS 执行真实锁定；互动仪式仍作为系统安全边界之前或之后的应用体验。
