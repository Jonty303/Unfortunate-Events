# Current verification scope: 01C

Run `bash tools/export_web.sh` for touch, combat, encounter and Web-export checks. The current CI also renders four actual frames. Historical validation below describes the original package, not the latest commit. iPad Safari/Edge audio, multitouch and device performance still require manual testing.

# Validation record - repository delivery

Prepared 11 November 2026. Source: the previously supplied `Unfortunate_Events_Visual_Prototype_01_Touch_Web.zip`.

## Verified before commit

- Original ZIP integrity and its complete SHA-256 manifest.
- All 11 PNG assets and the JPEG preview transferred byte-for-byte. The one-time GitHub artwork import verified SHA-256 before committing any image.
- Source references, export configuration and the existing shell/Python tooling were inspected. Artwork has not been regenerated or substituted.
- The complete project is self-contained under `visual-prototype-01`; original prototype files are not replaced.

## Automated runtime checks

`Visual Prototype Web Check` runs on this branch for project changes. It verifies the manifest, installs pinned Godot 4.5.2 with matching templates, imports the project, executes the touch smoke suite, performs a short headless scene run, and exports Web files. Consult the completed workflow run for the result; existence of this workflow is not itself a passing test.

No local Godot execution is claimed in the preparation container. The included test suite exercises synthetic multi-pointer state and integration, not real hardware touches.

## Still requires device and art review

Real iPad/Safari multitouch, rotation/layout, touch cancellation, browser focus behaviour, loading through Codespaces, performance, projectile readability and the quality of parallax/compositing. The art remains temporary concept-derived material. Passing automated checks does not approve production art or establish complete gameplay functionality.
