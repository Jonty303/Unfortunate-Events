# Unfortunate Events

A standalone Godot 4.x 2D side-scrolling prototype. Tested with Godot 4.5.2. No dependencies, plugins, or connection to Gauntlands.

## Play

Import `project.godot` in Godot 4.x and press F6/F5, then Enter to launch. The project uses the Compatibility renderer and a 1280 × 720 viewport, with a 1920 × 1080 default window and canvas scaling for other modern screen sizes. Existing game-space coordinates are drawn at double scale. Authored 2560 × 720 SVG backdrops cover the hangar, overland and orbital phases. Gameplay sprites are deliberately enlarged for the new view; four high-resolution power-up sprites use distinct silhouettes for speed, shot pattern, missiles and fire rate.

| Control | Action |
| --- | --- |
| WASD / arrows | Move; diagonal speed is normalized |
| Hold Z / Space / left mouse | Capped-rate cannon autofire |
| X / right mouse | Ground-strike missile salvo; consumes regenerating power |
| P / Escape | Pause / resume |
| R | Restart immediately |
| Enter | Start / retry from title or result |
| Left stick / D-pad | Move (20% stick deadzone) |
| Hold Pad A / bottom face button | Capped-rate cannon autofire; start from title/result |
| Pad B / right face button, or RB | Ground-strike missiles |
| Pad Start | Pause / resume; launch from title/result |
| Pad Y / top face button | Restart while paused or on result screen |
| M | Mute / unmute sounds |

The opening begins in the hangar, then enters the overland section after eight seconds. The route scrolls continuously even when you move left; ground vehicles, aircraft and destructible buildings arrive in waves. The orbital backdrop appears later in the sortie. Survive 80 seconds to complete this experimental run. Five hull points and a short collision cooldown prevent one contact from draining the whole hull; hits create small debris clouds with no shield layer. Flying into the ground also damages the ship. The cannon fires while held at a capped rate, so rapid taps cannot exceed the configured rate. Double and triple shot patterns remain separate from rate-of-fire upgrades. Missiles release from the shuttle and arc toward the ground; each salvo spends a chunk of regenerating missile power. A fighter takes two cannon hits; a ground vehicle takes four. Destroying military buildings adds score and restores some missile power. Civilian buildings currently trigger a short pilot/Mind exchange; this is an experiment, with no penalty system.

Collect S, C, M and F capsules by flying into them. They cycle in that order every eight seconds, beginning at six seconds, and drift in from the right at your ship's altitude (clamped away from the ground). The shuttle starts at 130 px/s. Each S capsule adds 22 px/s, up to 196 px/s for the sortie. C upgrades the cannon from single to twin to three-way fire. F upgrades the capped fire rate. Each firing interval produces one volley; double and triple patterns remain separate from fire-rate upgrades. M upgrades missile patterns. All missile salvos spend the same power chunk for now and follow the same ground-bound arc. Weapon upgrades retain through hull damage and reset on restart. Missed capsules are harmless; more arrive throughout the sortie.

Original synthesized arcade effects cover firing, damage, explosions, collection, launch, atmosphere entry and completion. M toggles sound. No music or external audio assets are required. Controllers can be connected while the game is running. Button labels use Xbox naming; equivalent physical positions apply to other mapped pads. There is no persistent progression or between-mission gameplay.

## Structure and art

- `main.tscn`: entry scene.
- `game.gd`: input, schedule, simulation, swept projectile collisions, rendering and UI.
- `assets/flight/` holds the 30 × 16 Shuttle, its weapons and transparent effect strips. The flight renderer selects cells at native resolution. A five-pose strip banks the near wing with vertical movement.
- `assets/hostiles/` holds the fighter, both tracked chassis, their articulated weapons and enemy ammunition.
- `assets/backdrops/` holds high-resolution SVG backdrops for the hangar breakout, planetary flight and orbital view, plus the 2 × 2 transparent power-up sprite sheet.
- The fighter fires pink pulses, the tank recoils as it fires amber shells, and the launcher elevates a loaded rail, releases its missile and lowers to reload. Ground buildings have destructible military and civilian variants.
- `tests.gd`: executable checks, including rapid input and a full 80-second simulated sortie.

Run checks using your Godot executable:

```
godot --headless --path . --import
godot --headless --path . --script tests.gd
```

Run the game with `godot --path .`. A Godot installation is required; this is an editable project, not an exported Windows executable.
