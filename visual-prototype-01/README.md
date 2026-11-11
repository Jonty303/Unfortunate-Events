# Current iteration: 01D - debug tuning

Open **TUNING / F4** for touch-native, bounded flight and combat settings. See [ITERATION_01D.md](ITERATION_01D.md) for controls, save/load behaviour and the next-pass proposal. Original encounter: [ITERATION_01C.md](ITERATION_01C.md). The shuttle now defaults to 75%; enemies/world objects stay at 85%. Includes a 64-second encounter, animated enemy weapons, wreckage and optional audio. Build and serve commands below are unchanged.

# Unfortunate Events - Visual Prototype 01

The complete Touch + Web source project lives in this directory on branch `visual-prototype-01`. Clone or pull the branch; no separate artwork ZIP is required. The original `initial prototype` and `milestone-01` work are unchanged.

## Run and build

Open this directory's `project.godot` in Godot 4.5.2 standard, or follow [CODESPACES.md](CODESPACES.md) to install, export and serve the Web version. The project is independent of the original build.

```bash
bash tools/install_godot.sh
bash tools/export_web.sh
python3 tools/serve_web.py --port 8080
```

The export script imports, runs the included touch smoke tests and checks the logs before exporting. To reuse an existing 4.5.2 installation, set `GODOT_BIN` to its executable. Matching Web export templates must already be installed.

## Controls

- Keyboard: WASD/arrows move; hold Z/Space for cannon; X for rocket; P/Escape pauses; R resets; F1 shows layer/hitbox diagnostics; F2 changes scroll speed; T cycles touch mode.
- Controller: left stick/D-pad move; A cannon; B/RB rocket; Start pauses; Y resets while paused.
- Touch: left analogue joystick, right FIRE and ROCKET buttons, plus Pause/Resume, Restart, Debug and Speed. Separate fingers can hold movement and both weapons together.

The top-right TOUCH selector cycles AUTO / ON / OFF and stays accessible when the other controls are hidden. Auto uses touchscreen detection, browser maxTouchPoints and a first-touch fallback. Preferences are saved where local storage is available. Touch cancellation, hiding controls, pause, restart and application focus loss release held touch inputs. Leaving the tab pauses the test. Keyboard/controller remain available in every mode. Mouse clicks can inspect forced-on controls, but cannot simulate simultaneous fingers.

## Rendering test

This is an isolated art/rendering experiment, not a complete game or a replacement for the original prototype. It uses a fixed 1920 x 1080 authored canvas, a default 1280 x 720 window and a preserved 16:9 aspect ratio.

| Layer | World-scroll multiplier |
| --- | ---: |
| Atmosphere | 0.025 |
| Far mountains | 0.18 |
| Mid-valley | 0.44 |
| Near forest | 0.72 |
| Road and gameplay objects | 1.00 |
| Foreground rocks | 1.17 |

Ground targets and projectiles share world X coordinates. Decorative layers do not collide. Cannon shots use bright blue-white cores; rockets arc downward. Targets can be destroyed, with simple decorative debris particles. There is no complete hull/damage/progression system; the HUD hull value is a placeholder. The finite target sequence does not represent a finished level.

## Artwork status

All 11 PNGs and the preview are byte-identical copies of the previously supplied Touch + Web package. They are temporary cutouts/composites from concept imagery, not approved production sprites. Known limitations include repeated scenery, compositing/alpha artefacts and an antique-inspired shuttle that is not yet a signed-off Space Shuttle design. The preview is a composited reference, not a verified gameplay capture.

The intended visual progression remains battered industrial machinery early, then smoother, stranger and much larger Culture-inspired craft later. No mass production of artwork is implied by this commit.

## Validation and files

See [VALIDATION.md](VALIDATION.md) for the test boundary. The GitHub workflow `Visual Prototype Web Check` imports, runs touch tests and exports with Godot 4.5.2. Real iPad/Safari behaviour, visual presentation and performance require device testing even when automated checks pass.

`MANIFEST.sha256` records the source package contents. Verify it with `sha256sum -c MANIFEST.sha256` from this directory. Generated `.godot/`, `build/`, logs and Python bytecode are ignored; engine binaries and export-template downloads are not committed.
