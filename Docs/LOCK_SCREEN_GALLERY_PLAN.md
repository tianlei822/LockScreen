# Lock-Screen Gallery Plan

## Direction

Threshold should feel like a gallery of short, cinematic unlocking rituals rather than four skins on the same puzzle. Each page keeps the clock and safe fullscreen escape path, but owns a distinct material, motion system, input, and reveal.

| Page | Visual language | Ambient motion | Unlock ritual | Reveal |
| --- | --- | --- | --- | --- |
| Solar Atlas | Ink-black space, warm stellar light, scientific orbit markings | Eight planets orbit at different speeds and depths; stars shimmer subtly | Double-click the sun; keyboard and VoiceOver users activate the named sun control | The sun blooms into a white-gold portal |
| Five-Phase Formation | Jade aether, rotating sigils, five-element cycles | Concentric formations rotate and pulse continuously | Trace Circle, Infinity, or Triangle | Charged formation opens along its central seam |
| Wooden Door | Charred oak, oxidized brass and ember | Warm light rolls across carved wooden leaves | Knock either brass ring three times | The wooden doors swing apart |
| Cipher Vault | Brushed steel, amber instrument light, mechanical calibration marks | Dials and indicator light move with restrained precision | Enter the local 4–8 digit ritual code | The vault splits into two heavy leaves |

## Divergent Bench

These directions stay outside this delivery so the four shipped pages remain focused:

- Abyssal Lantern: drifting jellyfish; hold the pearl until its bioluminescent ring closes.
- Chrono Archive: layered calendar machinery; align three time rings with the current minute.
- Zen Weather: rain, fog, and raked sand; draw one continuous ensō.
- Magnetic Aurora: field lines respond to pointer movement; connect opposite poles.

## Visual System

- Keep each page edge-to-edge with no central card frame.
- Use one restrained theme identity control in the upper-left, the clock at top center, and keep artwork as the visual priority.
- Use an 8-point spacing rhythm, readable contrast, reduced chrome, and semantic accessibility labels.
- Pause timelines whenever the ritual is hidden in background mode.
- Keep every page procedural: no network access, third-party dependencies, or raster asset requirement.

## Verification

- Core tests prove four themes, Solar Atlas ordering, double-click activation state, ignored activation on other themes, reset, and theme switching.
- `swift format lint --recursive Sources Tests`, `swift test`, and `swift build -c release` pass.
- The signed app launches at windowed and fullscreen sizes with the configured stable signing identity.
- Runtime inspection confirms all four pages are selectable, Solar Atlas animates, the sun has an accessible name, and double-clicking it completes the ritual.
