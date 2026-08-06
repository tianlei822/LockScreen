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

# Create a signed local app bundle at .build/Threshold.app.
# 在 .build/Threshold.app 创建本地签名应用包。
sh Scripts/build-app.sh
open .build/Threshold.app
```

## Controls / 操作

- Choose `Wooden Door`, `Formation Gate`, or `Cipher Vault` in the upper-left corner. / 在左上角选择木门、阵法门或密码箱。
- On `Wooden Door`, knock either brass ring three times. / 在 `Wooden Door` 中，敲击任意黄铜门环三次。
- On `Formation Gate`, choose `Circle`, `Infinity`, or `Triangle`, then drag along the glowing track to charge it. Press `Return` for the keyboard-accessible channel action. / 在 `Formation Gate` 中选择 `Circle`、`Infinity` 或 `Triangle`，然后沿发光轨迹拖动充能；也可按 `Return` 使用键盘触发。
- On `Cipher Vault`, enter the configured code with the keyboard or keypad, then press `Return` or the unlock key. The default is `1024`; this is only an app ritual code, never your macOS password. / 在 `Cipher Vault` 中使用键盘或数字键盘输入配置密码，再按 `Return` 或开锁键。默认值为 `1024`；它只是应用仪式密码，绝不能使用 macOS 系统密码。
- After a successful ritual, the doors finish opening, the app hides immediately, and the previous workspace becomes active without an intermediate window. / 仪式成功后，门完成开启，应用立即隐藏并激活之前的工作页面，不再出现中间窗口。
- Press `⇧⌘F` or use the upper-right button to toggle immersive/windowed mode. / 按 `⇧⌘F` 或点击右上角按钮切换沉浸/窗口模式。

## Verification / 验证

```sh
swift format lint --recursive Sources Tests
swift test
swift build -c release
plutil -lint Support/Info.plist
sh Scripts/build-app.sh
```

## System lock integration / 系统锁屏衔接

Apple's public APIs do not provide a supported way for a third-party app to replace the password or Touch ID lock interface. A later release can provide the passive animation as a `.saver` module and ask macOS to perform the real lock; the interactive ritual remains an app experience before or after that secure boundary.

Apple 公开 API 不支持第三方应用替换密码或 Touch ID 锁屏界面。后续版本可以把被动动画封装为 `.saver` 模块，并交由 macOS 执行真实锁定；互动仪式仍作为系统安全边界之前或之后的应用体验。
