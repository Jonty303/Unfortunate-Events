# Visual Prototype 01C — Smaller shuttle and readable opposition

11 November 2026. Continues the existing `visual-prototype-01` branch and folder. No changes to `main`, `milestone-01` or `initial prototype`.

## What changed

Player scale defaults to **75% of the original 01A hull**, while ground objects and enemies remain at **85%**. The debug scale button now changes only the player, including its collision geometry, hardpoints and engine attachments. The 1920 x 1080 canvas, background parallax, UI sizes and projectile readability are unchanged. Changing player size restarts the encounter for comparison.

An authored **64-second encounter** introduces one interceptor, ground defences, a breathing space, then combined attacks. Eight targets are scheduled reproducibly. The interceptor enters from the right, settles, warns and fires a three-shot horizontal burst, then leaves. Tanks traverse/elevate their barrel, lock aim, warn, fire a single shell, recoil and reload. Launchers raise their rail, warn, release a visible missile, then lower the empty rail and reload. Hostile missiles fly straight after launch; player rockets retain the unguided drop/ignite/downward arc. No auto-aim or homing upgrade has been introduced.

Enemy gun, rail and projectile positions share the same geometry. Offscreen enemies, enemies behind the shuttle, and enemies too close to the shuttle cannot fire. Moving airborne targets use relative swept collisions. Warning periods cancel and restart when a target leaves/re-enters the safe firing window. Telegraph timings and projectile speeds remain playtest values.

Destroyed vehicles retain scorched chassis and collapsed equipment. Buildings retain a shortened dark shell and rubble. Aircraft break into three sprite fragments; ground kills eject a few metal pieces. Wrecks remain world-anchored until scrolled out of view. Smoke/fire are short-lived and bounded. Debris is cosmetic, not damaging, and does not obstruct the player; no chain-reaction system yet. Completion is explicit, clears remaining threats, and supports touch/keyboard/controller restart.

Six original synthesised sound effects cover cannon, hostile fire, ignition, impact, vehicle destruction and larger building destruction. A visible **SOUND ON/OFF** control and `M` key toggle audio. Touch/mouse/controller/keyboard input unlocks playback; no sound starts before interaction. Eight voices bound simultaneous playback. Focus loss/pause stops sound and releases held controls.

## Art status — not final production art

The first flat-vector enemy-body test was rejected during visual review because it did not match the painted environment. This build retains the **painted tank/launcher body pixels**, with non-destructive polygon alpha extraction cached once at startup, plus a separate mirrored turret and animated weapon pieces. The interceptor is isolated from the earlier mountain-battle concept in this conversation, with its baked sky, exhaust and projectiles removed. It is an indexed PNG with transparency. Weapon pieces are small, shaded SVG source textures, not backdrop replacements. All required assets are in this repository; there is no download dependency at runtime.

These are **cleaner modular prototype assets**, not a claim that the final production-art pipeline is complete. Some silhouette/masking and material matching still need art review. The existing environment seams, repeated landmarks and baked damage in the facility crop are unchanged and still need the later dedicated environment pass. No background or camera rewrite was part of 01C.

## Testing

`tools/export_web.sh` imports, runs touchscreen, existing combat, and new encounter regressions, then exports the single-threaded Web build. The new suite checks independent scales, enemy telegraphs/reloads/origins/directions, no offscreen or rear fire, missile trajectory, persistent wrecks, bounded debris, restart and full encounter completion. CI also captures four real Compatibility-renderer frames. Test existence alone is not evidence of passing; use the current commit's Actions result.

On iPad, check the smaller hull, dodge the first interceptor burst, strafe the tank, rocket the launcher during preparation, observe wreckage, and verify the sound switch. Browser audio quality, actual device frame rate and touch ergonomics remain manual acceptance gates. `preview.jpg` is the old 01A composite; current real-engine captures are in the `visual-prototype-01c-review` Actions artifact.
