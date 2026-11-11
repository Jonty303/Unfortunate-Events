# Visual Prototype 01B — Ground combat, scale and weapon mounts

11 November 2026. Continues `visual-prototype-01`; no changes to `main`, `milestone-01`, or the original prototype. Existing concept-extracted scenery is retained, not reclassified as production art.

## Implemented scope

Default ship, vehicle and building width/height are 85% of 01A. Ground anchors stay on the road. The fixed 1920 x 1080 canvas, background layers and touch control sizes are unchanged. Projectile cores/trails are tuned independently, not multiplied by actor scale.

The shuttle is now a reusable `player_ship.tscn` with cannon/barrel/muzzle, belly rocket rail, engines and attitude-thruster markers. A visible bolt-on forward cannon recoils and flashes; shots originate at its transformed muzzle. A loaded rocket is visible on the separate rail. Banking, scaling and weapon origins share the same transform. This is a fixed gun, not an auto-aiming turret.

Lowest altitude is derived from the ship's transformed visible underside plus a 10-unit road clearance. At all three review scales, the low cannon line intersects tank and launcher hitboxes. Swept collisions use the earliest hit, account for hostile-round/player relative motion and keep hit radii separate from luminous trails. Solid targets also damage the hull on contact; the opening hangar is exempt. The road retains a protective flight clamp for this test.

Unguided rockets drop for 0.12 seconds before ignition, then travel forward/down. A 100-world-unit blast measures nearest distance to each target's collision rectangle: 3 damage within 30 units, decreasing to 2/1 towards the edge. Direct-hit and splash damage are not double-counted. Splash only damages hostile test objects, not the player; these are provisional tuning values.

Hull starts at 5. Hostile fire/contact removes hull, gives brief 0.85-second damage protection and a warm hit flash/fragments. Hull <= 2 emits smoke. At zero hull the ship is destroyed, firing/movement stop and touch holds are cleared. Restart restores the same encounter. No shields have been added.

Two tapered engine plumes remain active during cruise and backwards-on-screen movement. Manoeuvres vary thrust and add small attitude jets. Smoke, sparks and explosion effects are bounded and world-anchored; pause freezes them. Debris is cosmetic in this pass, not a chain-reaction damage system.

## Review on iPad

Pull this branch, then run the existing export/serve scripts from `visual-prototype-01/`. The top status reads **01B**. Use the left stick and hold FIRE at minimum altitude to strafe the first tank. From higher up, launch ROCKET and observe its separation, ignition and near-ground blast. Deliberately take hits to check hull loss and touch restart.

Tap DEBUG, then the new **SCALE / RESTART** button to compare 85%, 75% and 100% using the same encounter. Desktop: F1 debug, F3 scale. Scale changes reset the encounter; they do not resize the UI or change the viewport/camera. Compare projectile contrast, gun visibility and ground clearance. Keep a screenshot with the debug muzzle line and hitboxes when reporting a miss.

## Verification

`tools/export_web.sh` runs the original touch suite and `tests/combat_smoke.gd` before exporting. Combat regressions exercise all scales, muzzle alignment, low strafing, fast shots, first-hit ordering, splash falloff, rocket release, hull/invulnerability/death/restart and pause. CI also runs the scene headlessly and renders four comparison frames through the Compatibility renderer. Consult the commit's Actions run for actual pass/fail results; the existence of tests is not a passing result.

Real iPad touch ergonomics, browser performance and final art approval remain manual acceptance gates. `preview.jpg` is the earlier 01A composite, not a new engine capture. New CI captures are available as the `visual-prototype-01b-review` workflow artifact.
