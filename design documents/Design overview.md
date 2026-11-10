# Unfortunate Events design overview

## Direction

A standalone 2D pixel-art spacecraft game, initially a traditional Nemesis or Gradius-style horizontal shooter. The small player ship always faces right while the world scrolls left. Begin with a few waves in space, then transition overland with ground tanks and missile launchers.

The project began as a small, enjoyable diversion from Gauntlands, with room to develop further if the core play feels good. It remains a separate project.

## Prototype decisions

Responsive movement on both axes; normalized diagonal speed. The projectile cannon fires once per button press with no imposed cooldown, including multiple presses received within one engine frame. A separate unguided rocket launches forward and downward from the belly rail. Basic collision, hull damage, enemy attacks, destruction, completion and immediate restart form the playable loop.

The first version deliberately omitted pickups and upgrades. A subsequent request added simple cannon and missile powerups to explore their feel, along with arcade sounds and joypad support. This supersedes the original no-powerups constraint for the current prototype. There is no persistent progression or between-mission gameplay.

## Current playable slice

An 80-second sortie contains seven space formations, an atmosphere transition beginning at 32 seconds, and a ground section alternating tanks and missile launchers alongside airborne enemies. The ship has five hull points and brief protection after a hit. Ground contact causes damage. Ground vehicles can be attacked by flying low and firing forward.

The view is 640 by 360 pixels, enlarged with integer scaling. The player pilots a 30 × 16 antique Space Shuttle orbiter with patched tiles, oxidised repair plates and a bolt-on rocket rail. Its provenance is open. It could be a Culture citizen’s restoration project, or something a bored Mind keeps airworthy for its own amusement. The shield briefly showing through on impact hints at newer hardware inside. The atmosphere-entry message was specifically well received by the user and is worth preserving as part of the transition's character.

## Weapon experiments

| Weapon | Level 1 | Level 2 | Level 3 |
| --- | --- | --- | --- |
| Cannon | Single shot | Twin parallel shots | Three-way volley |
| Missile | Single, four damage | Twin, four damage each | Twin, six damage each, faster reload |

C and M capsules alternate, beginning six seconds into the sortie and then every eight seconds until the final stretch. They drift in from the right near the player's altitude, constrained away from the ground. Fly into a capsule to upgrade its weapon. Levels cap at three, survive damage, and reset each run. Each cannon press produces one volley at every level; holding the button does not auto-fire. Missile reload is 0.45 seconds, reducing to 0.28 seconds at level three. The Shuttle starts at 130 px/s. Three S pickups raise movement to 152, 174 and 196 px/s for the sortie. Both rocket sizes arc down toward ground targets and burst on terrain contact.

## Input and sound

Keyboard movement uses WASD or arrows. Z, Space or left mouse fires the cannon; X or right mouse launches missiles. P or Escape pauses; R restarts; Enter launches. M toggles sound.

Joypad movement uses the left stick or D-pad, with a 20 percent stick deadzone. A fires the cannon or launches from a result screen, B or RB fires missiles, Start pauses or launches, and Y restarts while paused or on a result screen. Names use the Xbox layout and corresponding physical positions on other mapped controllers.

Original synthesized effects cover cannon, missiles, damage, explosions, pickup, launch, atmosphere entry and completion. There is no music yet. Automated checks cover gameplay and simulated controller buttons; physical controller feel still needs hands-on evaluation.

## Ideas for later exploration

The earlier discussion recalled Parallax, including leaving a ship and walking around. A possible later direction is top-down flight over terrain, with landing and short on-foot run-and-shoot sections to expand the human role. These were exploratory ideas, not commitments for the current slice. The user explicitly did not commit to eight-way flying.

Side-scrolling was considered especially suitable for space combat. Uridium and its turnover mechanic were also mentioned as an interesting reference, without a decision to implement that mechanic.

## Sources and status

Compiled on 10 November 2026 from the user-supplied preview of “Discussing The Culture”, the prototype requests in this chat, and the existing prototype documentation. This is a consolidation of the accessible material, not a complete export of the original design conversation. See `Archive status.md` for the missing material.
