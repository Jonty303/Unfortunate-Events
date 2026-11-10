# Visual Prototype 01 — Art Direction and Layered Rendering

**Started:** 10 November 2026  
**Status:** in-progress renderer/art acceptance exercise; no merge approval; independent of `milestone-01`.  
**Baseline:** new branch `visual-prototype-01` from `main` (the previous HD/SVG attempt on `milestone-01` is deliberately excluded).

## Goals

Prove an attractive and legible horizontal-scrolling scene before generating a complete asset library. Begin with the antique hangar breakout and early overland gameplay, then preserve extensibility for orbital scenes and immense Culture-style encounters.

## Visual design

- Early era: recognisable, battered, repaired Space Shuttle orbiter, rusty tiles and bolt-on systems; militarised ground opposition should look visibly less advanced than Culture technology.
- Later era: refinements ultimately transition into **smooth, strange, seamless, enormous** spacecraft. Avoid conventional wings, exposed gun barrels, fighter-jet shapes and naval battleship styling as default late-era motifs.
- Rich cinematic raster assets / high-detail painted pixel-art feel, modern restrained lighting and atmospheric depth.
- Avoid a flattened background image pretending to be parallax; isolate true bands with independent scenery, clean alpha, deliberate repeat seams, uniform horizons and lighting.
- The bright white core and cyan bloom/trail of friendly cannon rounds must remain legible against sky **and** terrain. Enemy fire receives a separate warm colour family and silhouette; collision radii are smaller than visual effects.
- Exaggerate scale through composition and camera/environment transitions, not simply through denser weapons and detail.

## Target canvas and coordinates

- Author at **1920×1080**, 16:9. A smaller window may present the same canvas at a fractional scale, preserving a fixed aspect ratio and unchanged gameplay bounds.
- One shared world X distance and one scrolling camera origin.
- Decorative images scroll at their depth fraction; physical **terrain, ground objects, missiles, player interactions and debris collisions** use world coordinates at 100%.
- A descriptive debug overlay should show parallax rates, collision rectangles, world travel and visual safe areas; pause must not obscure screenshots.

## Proposed layers (adjust after review)

| Order (back→front) | Typical world-scroll multiplier | Role |
|---|---:|---|
| Sky / distant space | 0.025 | Atmosphere or stars |
| Distant mountain range | 0.18 | Far landscape |
| Cliffs and valley | 0.44 | Middle-distance |
| Near forest / industrial skyline | 0.72 | Near-distance scenic objects |
| Ground and roads | 1.00 | Gameplay surface |
| Hangar, structures and ground vehicles | 1.00 | Hitboxes and destruction |
| Shuttle, enemies and projectiles | 1.00 | Gameplay |
| Fast foreground rocks / vegetation | 1.17 | Speed and depth cues |
| HUD | camera-locked | Unobtrusive status and instructions |

## World object separation

The **terrain renderer** supplies the visible road/surface baseline and future terrain masks. A distinct **world object manager** anchors targets to world X, with health, weapon collision, debris and destruction states. Decorative parallax bands do not receive collisions. Large structures can extend beyond a screen without changing their world position; visible art and collision geometry remain separately authored.

## Art and performance acceptance

1. One test scene (hangar → overland) renders with consistent shuttle size and no sudden camera or viewport expansion.
2. The image fills a 16:9 view without letterboxing errors, clipping or unexpected image jumps.
3. Foreground, near forest, cliffs, mountains and sky have independently visible but not distracting parallax.
4. No harsh raster seams, unintentional mirrored mountain landmarks, repeated ships built into backgrounds or obvious inpainting.
5. Tanks and buildings remain on the road and only disappear when hit; particles are decorative, while harmful debris later receives its own lightweight collisions.
6. Single cannon rounds can be tracked by eye against the brightest cloud and darkest forest. Projectiles must look refined, not oversized cartoon sprites.
7. Rockets leave the shuttle, separate visibly, arc downward, then detonate on ground or targets.
8. Pause supports screenshot inspection and F1 debug explains exactly what is being shown.
9. Space, capital-scale and Culture-vessel art follow the same material/light/contrast language but are not required for this milestone.
10. Do not approve or mass-produce production art until a real Godot run and visual review.

## Prototype package status

A **separate local experimental Godot package** has been assembled containing `visual_test.gd`, `parallax_layer.gd`, `main.tscn`, `project.godot` and 11 cut-out PNG textures, plus a composited preview. These raster assets are **temporary proof-of-pipeline material extracted from earlier generated concepts**, **not** clean production art. Their alpha/tiling and environment reuse still require a dedicated paint pass.

The local package has not been run through a Godot executable in this environment. As the GitHub integration currently writes UTF-8 text files but does not accept local container files as binary uploads, the package must be imported into the repository by a separate binary-capable route before claiming the code/assets are committed. This branch records the accepted architecture and quality gates; it intentionally does not replace the original working prototype.
