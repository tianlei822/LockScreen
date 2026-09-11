# Artwork refinement — 2026-09-11

The wood panels now have opaque recessed surfaces, natural wood microtexture, fine grain and brass patina. Lightning retains seeded geometry during each flash, with smaller leader segments and secondary forks. Rain has depth-dependent width/speed and ripples tied to each drop's landing position. The fire dragon has a tapered silhouette and three staggered rows of curved scales.

木门使用独立凹入嵌板、自然木材微纹理、细木纹与黄铜氧化细节。雷电保留单次闪电内稳定的随机几何，增加细小先导和二级分叉。细雨按远近改变粗细与速度，涟漪与落水位置关联。火龙改为渐细轮廓及三排交错弧形鳞片。

## Assets / 素材

Both assets were produced with the built-in image generation tool. The original ink painting is retained. No external runtime service is used.

两张素材均由内置图像生成工具制作。原水墨素材保留，运行时无需外部服务。

- `Sources/LockScreenApp/Resources/InkLandscapeDetailed.png`: 1672 × 941, edited from `InkLandscapeRefined.png`. Boat target remains `(0.64, 0.77, 0.23, 0.167)`. The generator retained the original resolution; this is not a native 4K asset.
- `Sources/LockScreenApp/Resources/WoodSurface.png`: 1024 × 1536, generated material, cached once and cropped into the existing door geometry.

## Verification / 验证

- All 89 Swift tests passed after the final code changes, including 15 `WindowPresentationTests`.
- Recursive `swift-format lint`, `git diff --check`, and the status-item appearance guard passed.
- Release bundle built with identity `B4035AE98DA51B2F173CF52BAACC758E5B35DF63`; strict signature verification passed outside the sandbox.
- Updated `.build/Threshold.app` and bootstrapped the existing LaunchAgent. LaunchServices reported `ApplicationType = UIElement`; initial final-build PID was `65492`, with one run and no exits.
- Inspected live wood, ink, rain, fire-dragon, and thunder-seal rendering. Checked three-knock, boat, and formation activation. The image tool preserved the boat composition and target location.
- Full status-menu, Space, and display-state acceptance is incomplete: the system UI automation timed out during menu inspection. These checks must not be represented as passed.
- The original app is retained at `.build/Threshold-before-artwork.app`. No commit or push was made.

最终修改后 89 项测试全部通过；格式、状态栏静态约束和签名验证通过，已更新本机应用并观察实际图案与交互。状态栏菜单检查发生系统界面工具超时，Space 与显示器状态切换未完成验收。旧应用备份保留，未提交或推送 Git。

## Foliage and solar follow-up / 树叶与太阳系追加优化

`InkLandscapeFoliage.png` replaces the detailed painting at runtime, retaining the earlier assets. The built-in image editor differentiated pine needle fans, pointed leaves and broadleaf clusters while preserving the boat target and composition.

水墨运行素材改为 `InkLandscapeFoliage.png`，区分松针、尖叶和阔叶簇，保留旧素材、构图和船的点击位置。

The solar renderer projects packaged equirectangular maps onto a sphere with bilinear sampling, rotation, sun-facing illumination, an Earth cloud layer and a self-luminous solar surface. Saturn has fine radial bands and a dark division, with separate front/back arcs. Atmosphere glow is restrained. The cache retains one projected frame per body. Existing procedural surfaces remain as resource-loading fallbacks.

太阳系加入球面贴图、自转、朝向太阳的光照、地球云层及太阳表面；土星环细分并保留暗缝与前后遮挡，减弱大气泛光，每个天体仅缓存一帧投影，加载失败保留原程序绘制。

Maps: [Solar System Scope / INOVE](https://www.solarsystemscope.com/textures/), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Attribution is included in the resource bundle. These are visualization maps, not uniformly true-color observations; orbital layout, scale, rotation rates and night-side fill remain artistic, not an ephemeris or physically exact simulation.

贴图来源与 CC BY 4.0 署名已随应用打包。贴图包含可视化加工；轨道布局、尺度、转速和暗面补光仍为艺术表现，并非精确天文模拟。

Fresh verification: 94 Swift tests passed, including five sphere/texture tests and 15 window-presentation tests. Format lint, status-item guard and diff whitespace checks passed. Exported Earth, Jupiter and Sun renderings were visually inspected for sphere mapping and detail. Pre-update backup: `.build/Threshold-before-foliage-planets.app`.

本轮 94 项测试通过，包括 5 项球面贴图测试与 15 项窗口测试；格式、状态栏约束及差异空白检查通过。已检查导出的地球、木星和太阳图像。

The signed release was installed at `.build/Threshold.app`; strict code-sign verification passed. First LaunchAgent process `68822` had one run and no exits and registered as `UIElement`. Live solar and foliage screenshots were inspected; the solar double-click interaction reached `THRESHOLD OPEN`. The pre-inspection Solar Atlas theme was restored. Full system-menu/Space/display acceptance remains incomplete as noted above.

已安装签名版，严格签名校验通过；首次后台进程 `68822` 注册为 `UIElement`，一次运行且未退出。已检查太阳系和水墨实机画面，太阳双击进入 `THRESHOLD OPEN`，主题恢复为检查前的 Solar Atlas。系统菜单、Space 和显示器状态完整验收仍未完成。

## Final prompts / 最终提示词

### Sun rotation correction / 太阳旋转修正

The 240-angle texture cache held the Sun still for roughly 0.58 seconds at 0.045 radians/second, then jumped 1.5 degrees. A regression test reproduced 22 stalled transitions across 24 frames. The Sun now samples the continuous wrapped phase on each timeline frame at the same constant angular speed; other planets retain their existing cache policy. Cache memory remains one image per body. The regression and all 95 tests pass, along with format lint, the status-item guard and diff checks. This verifies rendered-frame progression, not a measured display-refresh guarantee. Backup: `.build/Threshold-before-sun-smoothing.app`.

240 档角度缓存使太阳约每 0.58 秒才跳动 1.5 度；回归测试在 24 帧中复现 22 次停顿。太阳现按每帧连续相位采样，保持原匀速，其他行星缓存策略不变，每个天体仍仅缓存一张图。95 项测试及格式、状态栏约束、差异检查通过；测试证明渲染帧连续变化，不代表已测得屏幕刷新率保证。

### Foliage-only edit prompt

Use case: precise-object-edit. Edit target: this existing Chinese ink landscape. Change ONLY the foliage and fine branch structure of existing trees and shrubs. The current foliage is uniformly stamped round black dots; replace this throughout the painting with visibly diverse traditional brushwork. Foreground left cliff pines: fine radial needle sprays, jagged horizontal fans, negative-space gaps and exposed angular twigs. Central island: distinct individual trees, one with layered airy pine needle fans, another with elongated pointed leaf clusters in varied directions, a third with irregular broad leaves rendered in small angular broken brush strokes; preserve all existing trunks and tree locations. Nearby shrubs: interlocking tapered leaf strokes, varied cluster sizes, dry-brush edges, ink ranging from gray washes to saturated accents. Distant ridge trees: simplify to soft uneven washes and tapered silhouettes fading into mist, never rows of identical beads. Very important: make needle bundles and pointed leaves visually legible at normal viewing size, not tiny dot texture; avoid uniformly round stipples, repeated circles, cloned foliage stamps, broccoli-shaped crowns, and identical tree crowns. Keep Chinese monochrome ink painting character and restrained detail, no photographic leaves and no color. Preserve exact canvas proportions, original framing, mountain and rock silhouettes and textures, waterfall, mist, central island shape, water and reflections, ivory paper, and the fishing boat and fisherman in their exact original positions and sizes. Boat stays in normalized box x .64 y .77 width .23 height .167. No new objects, no text, no stamps, no borders. Output a new edited image.

### Ink landscape (edit)

Edit this existing Chinese shan-shui ink landscape artwork for a native fullscreen lock-screen background. Preserve exact 16:9 composition, all mountain silhouettes, waterfall location, central island, and especially fishing boat and fisherman in lower right at normalized bounding box x .64 y .77 width .23 height .167. Refine craftsmanship and realism within traditional monochrome Chinese ink painting, not a photograph: fine dry-brush rock texture following geology, varied pine needles and convincing branching, waterfall splitting around rock edges with translucent spray at its base, distant ridges fading softly into pale atmospheric mist. Reduce repetitive water contour loops: delicate broken horizontal ripples, subtle reflections aligned below island and boat. Refine existing boat planks, woven canopy, fishing rod and fisherman's hands without moving or enlarging them. Pale warm ivory rice paper, much subtler fine paper fiber than original; avoid dirty mottled background and uniform sepia veil. Keep generous mist negative space. No text, no seals, no added objects, no borders, no UI. High resolution, ideally 3840x2160. Save edited output as a new file; keep original.

### Wood material (generate)

Generate a photorealistic material texture for an aged Chinese wooden door in a native macOS app. One single continuous piece of quarter-sawn dark warm brown oak wood, straight-on orthographic close view, vertical grain running top to bottom. Fine densely packed longitudinal pores, subtle irregular growth rings, a few very small elongated knots with grain naturally bending around them, occasional hairline age splits, subdued rubbed surface and dry satin finish. Natural medium-dark warm umber, restrained amber undertones, absolutely not orange varnish. Neutral soft diffuse illumination, uniform across frame with no spotlight, no vignette, no glossy specular patches. Texture must remain visible in a dark scene. Edge-to-edge wood material only: no door hardware, panels, plank seams, nails, handles, frames, carvings, text, objects or background. Tall 2:3 composition. High detail and natural photographic microtexture, not illustration, no artificial parallel drawn lines. Used as physically believable wood surface within existing procedural door geometry.
