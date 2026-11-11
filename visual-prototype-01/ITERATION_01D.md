# Visual Prototype 01D - Flight and combat tuning

11 November 2026. Same `visual-prototype-01` branch and project directory. This is a tuning-tool pass, not a new level or an artwork replacement. Original 01C gameplay defaults remain unchanged.

## Open and use

Tap **TUNING / F4** at the top of the game, or press F4. The encounter pauses, audio stops and gameplay touch captures are released. The panel accepts real multitouch without globally emulating mouse input. Drag a slider, or use the large minus/plus buttons. Numeric values and units are always visible.

Edits are staged. **Apply / return** applies them to the existing encounter and restores its previous pause state. **Apply / restart** applies and restarts the same encounter. **Cancel**, Escape or F4 closes without applying. Focus loss while editing leaves the game paused on return. Existing projectiles keep their launch speeds; an applied change restarts enemy warning preparation to avoid surprise fire. Weapon buttons held across closing require release before firing again.

**Defaults** restores the original 01C values in the panel, not immediately in play. **Save preset** stores the current draft in `user://visual_tuning_v1.cfg`. **Load preset** loads that one saved preset into the draft. Apply is still required. Saving is local to the browser/device, not GitHub or another device. Profiles are deliberately NOT auto-loaded on launch: a new build always starts at known defaults until Load/Apply is requested. Browser data clearing, private browsing and a different forwarded origin can affect persistence. Save failures are shown in the panel. No runtime settings alter the source files.

Keyboard in the panel: arrows select/adjust a row, Page Up/Down changes category, Enter applies/returns. Controller: D-pad selects/adjusts, shoulders change category, A applies/returns, B/Start cancels. Open via the on-screen button or F4. The existing Debug toggle continues to show muzzle lines/hitboxes and now reports actual movement speed, scroll speed, simulation multiplier, cannon rate and FPS.

## Controls and limits

| Group | Settings | Default / supported range |
| --- | --- | --- |
| Flight | Ship scale | 75%; 40-100% of the original hull. Hitbox and mounts follow. |
| Flight | Player movement | 445 world px/s; 150-900 |
| Flight | World scrolling | 145 world px/s; 60-350. Does not change the encounter clock. |
| Flight | Simulation speed | 1x; 0.25-1.5x. Scales movement, weapons, effects and encounter time together. |
| Cannon | Rate | 1 / 0.13 seconds = about 7.69 shots/s; 1-20 |
| Cannon | Shot speed | 1250 view-relative world px/s; 400-2200 |
| Cannon | Damage | 1 HP; 1-5 |
| Cannon | Projectile visibility | 100%; 50-150% art scale for all rounds. Does not change hit radii. |
| Rockets | Reload | 0.78 s; 0.25-2 s |
| Rockets | Forward speed | 675 view-relative world px/s; 250-1200 |
| Rockets | Downward acceleration | 380 world px/s squared; 100-800 |
| Rockets | Blast radius | 100 world px; 30-180, retaining existing splash falloff |
| Opposition | Enemy/building scale | 85%; 60-100%, independent of the player |
| Opposition | Projectile speed | 1x; 0.5-1.5x |
| Opposition | Reload duration | 1x; 0.5-2x; burst spacing unchanged |
| Opposition | Warning duration | 1x; 0.5-2x; larger means more reaction time |
| Inspection | Invulnerable player | Off |
| Inspection | Enemy fire enabled | On; disabling also removes existing hostile rounds |
| Inspection | Hitboxes / muzzle line | Off |

Ranges are bounded prototype experiments, not balanced combinations. The camera, touch UI and background geometry are unchanged. World px are the authored 1920 x 1080 coordinates, not physical iPad pixels. No shields, homing or new upgrades. Applying prints an exact JSON setting summary to the game log for reproducibility; a panel screenshot is also useful for discussing values.

## Verification

`tools/export_web.sh` runs touchscreen, combat, encounter and tuning tests before Web export. The tuning tests cover invalid values and clamping, profile round-trips, actual multi-touch input routing, captured-slider ownership, canceled touches, pause/focus handling, staged changes, independent scale, weapon timing/damage/speed, warning/reload multipliers, invulnerability, enemy fire, slow motion and resized-viewport input. They also check that held fire cannot leak through closing the panel. The renderer test captures the four existing gameplay frames and all five panel pages. Passing results must be read from actual logs or CI, not inferred from the existence of these tests.

Real iPad ergonomics, browser persistence and performance remain manual acceptance gates. The panel is a development interface, not the final player options menu.

## Proposed next pass - Environment and effects quality (not implemented here)

First use this panel to settle player size, movement speed, scroll speed and cannon rhythm on iPad and desktop. Change one family of values at a time; use the identical restarted encounter for comparison. Do not permanently change defaults until reviewed.

Then replace ONE overland section with purpose-made raster layers: distant sky/ridges, midground forest/industrial skyline, a readable building strip, drivable road and sparse fast foreground. Remove baked-in explosions, hard extraction edges and conspicuous repeat landmarks. Road, targetable buildings and vehicles still use shared world coordinates at 1x; their separate visual bands do not imply incompatible collision spaces. Decorative parallax stays non-colliding. Keep the battle corridor and warning/projectile contrast clear.

Give the same small combat set deliberate intact, damaged and wrecked states, consistent lighting and clean alpha, then tune compact muzzle flashes, engine exhaust, rocket trails, impacts and short explosions at the chosen gameplay scale. Build restrained, reusable effect assets rather than more full-screen bloom. Measure frame rate on the actual iPad; a desktop software-renderer test is not a device benchmark.

Acceptance: one repeatable 60-64-second section, no obvious terrain seams at slow and normal scroll, grounded tracks/buildings, readable weapons against bright sky and dark terrain, persistent coherent wreckage, unchanged touch ergonomics, and a recorded preferred tuning preset. Defer additional enemy types, bosses, capital-ship encounters and damaging chain-reaction debris until this section is visually approved.
