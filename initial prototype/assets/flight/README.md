# Starter Shuttle flight sprites

Transparent RGBA PNGs for a 640 × 360 viewport. Draw at native size using nearest-neighbour sampling. Strips run left to right with equal cells and zero gutters. Use the cell centre as the drawing pivot. The Shuttle's native grid is 30 × 16, facing right. Its cannon port is at (29, 12), its rocket rail is under the near wing, and its drive bells are on the left.

| PNG | Cell (px) | Frames | Playback |
| --- | --- | --- | --- |
| shuttle | 30 × 16 | 1 | Static hull |
| cannon_round | 10 × 5 | 1 | Align with velocity |
| hostile_round | 6 × 6 | 1 | Enemy fire |
| rocket | 14 × 6 | 1 | Align with velocity |
| heavy_rocket | 16 × 7 | 1 | Align with velocity |
| main_drive | 14 × 8 | 6 | Loop at 14 fps, add 3 fps per speed pickup |
| rocket_drive | 10 × 5 | 4 | Loop at 20 fps |
| muzzle_flash | 12 × 10 | 4 | Once at 48 fps, attached to cannon |
| impact | 20 × 20 | 6 | Once at 28 fps |
| shield_hit | 44 × 30 | 8 | Once at 18 fps, centred on Shuttle |
| small_explosion | 34 × 32 | 9 | Once at 22 fps |
| debris_cloud | 36 × 32 | 9 | Once at 14 fps, behind explosion |

Both rockets launch with forward and downward velocity. Their amber exhaust follows the motor as the rocket pitches down. The shield strip shows contact during the existing damage-protection window.
