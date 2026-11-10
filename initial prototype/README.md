# Unfortunate Events

A standalone Godot 4.x 2D pixel-art prototype. Tested with Godot 4.5.2. No dependencies, plugins, or connection to Gauntlands.

## Play

Import `project.godot` in Godot 4.x and press F6/F5, then Enter to launch. The project uses the Compatibility renderer and a 640 × 360 viewport with nearest-neighbour integer scaling. The default window is 1280 × 720.

| Control | Action |
| --- | --- |
| WASD / arrows | Move; diagonal speed is normalized |
| Z / Space / left mouse | Cannon: one shot per press, no cooldown |
| X / right mouse | Unguided ground-attack rocket, 0.45-second reload |
| P / Escape | Pause / resume |
| R | Restart immediately |
| Enter | Start / retry from title or result |
| Left stick / D-pad | Move (20% stick deadzone) |
| Pad A / bottom face button | Cannon; start from title/result |
| Pad B / right face button, or RB | Ground-attack rocket |
| Pad Start | Pause / resume; launch from title/result |
| Pad Y / top face button | Restart while paused or on result screen |
| M | Mute / unmute sounds |

Your ship always faces right. The route scrolls continuously even when you move left. Space has seven formations, followed by an atmospheric transition at 32 seconds. The ground section alternates tanks and missile launchers with airborne formations. Survive 80 seconds to complete the sortie. Five hull points, short protection after each hit, and visible hit flashes make damage readable. Flying into the ground also damages the ship. Release a belly-mounted rocket from above and ahead of an approaching ground vehicle. The rocket travels forward and drops progressively. A miss bursts against the terrain. A fighter takes two cannon hits; a ground vehicle takes four. A missile deals four damage. Holding the cannon button does not fire repeatedly. Multiple press events within a frame each produce a shot.

Collect S, C and M capsules by flying into them. They cycle in that order every eight seconds, beginning at six seconds, and drift in from the right at your ship's altitude (clamped away from the ground). The restored Shuttle starts at 130 px/s. Each S capsule adds 22 px/s, up to 196 px/s for the sortie. C upgrades the cannon from single to twin to three-way fire. Each press still fires exactly one volley with no cannon cooldown. M upgrades missiles from single to twin, then to twin heavy missiles (six damage each, 0.28-second reload). Both rocket sizes follow the same unguided downward arc. Both weapons cap at level three, retain upgrades after damage, and reset on restart. Missed capsules are harmless; more arrive throughout the sortie.

Original synthesized arcade effects cover firing, damage, explosions, collection, launch, atmosphere entry and completion. M toggles sound. No music or external audio assets are required. Controllers can be connected while the game is running. Button labels use Xbox naming; equivalent physical positions apply to other mapped pads. There is no persistent progression or between-mission gameplay.

## Structure and art

- `main.tscn`: entry scene.
- `game.gd`: input, schedule, simulation, swept projectile collisions, rendering and UI.
- `assets/flight/` holds the 30 × 16 Shuttle, its weapons and transparent effect strips. The flight renderer selects cells at native resolution. A five-pose strip banks the near wing with vertical movement.
- `assets/hostiles/` holds the fighter, both tracked chassis, their articulated weapons and enemy ammunition. The fighter fires pink pulses, the tank recoils as it fires amber shells, and the launcher elevates a loaded rail, releases its missile and lowers to reload.
- `tests.gd`: executable checks, including rapid input and a full 80-second simulated sortie.

Run checks using your Godot executable:

```
godot --headless --path . --import
godot --headless --path . --script tests.gd
```

Run the game with `godot --path .`. A Godot installation is required; this is an editable project, not an exported Windows executable.
