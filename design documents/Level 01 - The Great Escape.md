# Level 01 — The Great Escape: narrative and gameplay design

**Date:** 10 November 2026  
**Status:** Working narrative and mission design. Current gameplay and visual requirements below are the direction for the first-level build; this document does not claim the features are implemented.

## Design boundaries

- **Core game:** 2D horizontal, right-facing, Nemesis/Gradius-inspired scrolling shooter. One playable shuttle, one initial level, movement in two axes, ground and air combat.
- **Platform:** PC-first prototype, with landscape phone/touch control implications worth considering later. Portrait vertical-scrolling was discussed, but horizontal remains the chosen direction.
- **Visual target:** Build for modern high-resolution screens, with a larger view that uses screen space well. Move beyond the current 640 × 360 presentation as needed; keep the image crisp at 1080p and higher. Aim for production-quality visuals as far as practical for this prototype.
- **Backdrop target:** Create polished, high-resolution backdrops for the hangar breakout, planetary ground combat and orbital transition. Use layered depth and environmental detail while keeping the shuttle, enemies, weapons, terrain and hazards easy to read.
- **Avoid scope inflation:** no ship transformations, flight modes, free exploration, alternate camera configurations or persistent upgrade framework are required for the opening gameplay milestone.
- **Current code vs design:** the existing playable experimental slice already includes in-level speed and weapon pickups, as documented in Design overview.md. This document describes the intended opening mission and updated combat direction; it does not claim the expanded story, buildings, bosses or progression are implemented.

## Opening mission: seven story beats

1. **Hangar breakout.** The shuttle forces its way out of a hangar or facility under fire. Its Mind reports that the engines are undergoing emergency reconfiguration and it cannot leave orbit yet; the plan is to survive long enough without exploding.
2. **Planetary gauntlet.** Horizontal forced-scroll across ground and air defences: tanks, launchers, fixed guns, hostile aircraft and destructible structures. Occasional human–Mind exchanges respond to events without interrupting normal play.
3. **Surface mini-boss.** A more substantial defensive emplacement or interceptor with readable attack patterns, defeated before the flight can continue.
4. **Reconfiguration complete.** The Mind declares the engines ready, departs the planet, and the level visually transitions from atmosphere to space.
5. **Orbital pursuit.** Additional combat waves establish the new environment and escalating danger.
6. **Overwhelming encounter and escape.** A huge hostile boss arrives. Player weapons cannot meaningfully hurt it. The vessel tries to compromise our systems using effectors. After growing irritated, the Mind diverts power from armour and propulsion systems into locomotion. The objective becomes escape/survive, not win the firefight; scrolling accelerates and hull hits become especially dangerous. Convey the invulnerability and changed objective clearly so the player does not mistake this for a winnable battle.
7. **Aftermath.** Narrative exchange explains the situation, considers the next mission and opens the door to ship modifications.

This is one level with contrasting phases, rather than multiple standalone missions.

## Human and Mind narrative

The human and the ship's Mind should have distinct reactions to events. Use short, occasional, context-sensitive exchanges during play, with larger scripted story beats at transitions. Dialogue should remain brief and must not obscure threats or block normal control. The first-level experiment can use a small set of authored event lines rather than a general-purpose dialogue system.

The Mind is capable, clever, dry, indignant and increasingly exasperated by the enemy's conduct. The joke is that a furious “RIGHT! That does it!” cues what sounds like a devastating counterattack, but the Mind's sensible response is to run away very, very fast.

### Effector encounter — dialogue treatment

The following includes user-provided anchor lines and exploratory suggested connective writing. Preserve the distinction.

**User-provided dialogue (near-verbatim, lightly corrected for spelling):**

> “They're attempting to take us over via effector, and I don't know how much longer I'm willing to put up with that.”  
> “RIGHT! That does it!”

**Proposed staging and additional dialogue (draft, not locked script):**

An enemy vessel begins an effector intrusion. The ship shudders; displays flicker. Player controls may briefly feel disrupted, if fair and readable.

**Mind:** “They're attempting to take us over via effector, and I don't know how much longer I'm willing to put up with that.”

Another effector pulse.

**Mind:** “I did ask them to stop.”

Systems flicker again.

**Mind:** “RIGHT! That does it!”

The apparent setup for retaliation is deliberately misleading. The engines flare.

**Mind:** “We're leaving.”

**Mind:** “I've diverted power from the shields and armour fields. So, if we could avoid being shot for the next seventeen seconds, that would be marvellous.”

### Other exploratory Mind lines (not approved final script)

- Breakout: “Good news: we're airborne. Bad news: that was rather more of the hangar than I intended to demolish.”
- Under heavy fire: “They do seem quite committed to killing us.”
- Engine work: “Almost finished. I should mention that ‘almost’ is doing some considerable work there.”
- Big boss appears: “Oh. That's unfortunate.”
- Futile shooting: “Well, we've established that shooting it isn't helping.”
- Escape decision: “Right. New plan. We leave. Immediately.”
- Escape peril: “I'm diverting the shields into propulsion. Please avoid getting shot. I realise that's not entirely within your control.”

The shorter original user wording about hoping not to explode during reconfiguration should also be preserved as the opening's intended tone, rather than presenting any assistant version as final.

## Combat and damage direction

Current first-level design decisions:

- **No shields for now.** Hits go directly against the shuttle's hull. Show each hit with a small debris cloud. Do not add a shield bar or shield-hit layer for the current build.
- **Main gun autofire.** Holding the fire button fires at a fixed rate. Tapping rapidly cannot exceed that rate. A fire-rate upgrade may increase the cap.
- **Shot-pattern upgrades are separate.** Double- and triple-shot patterns remain distinct upgrades and do not replace or bypass the fire-rate cap.
- **Ground-strike missiles.** Missiles release from the shuttle, drop away, then arc toward a ground target. Make the launch, arc and impact easy to follow. Exact guidance, blast radius and target-selection rules remain to be tuned.
- **Missile power.** Each missile consumes a substantial amount of a regenerating power resource. Capacity, cost, regeneration rate and upgrade effects need playtesting.

## Destructible ground buildings — provisional idea

Add buildings as ground props that can be destroyed. Some may be identified as military targets and reward bonus points or resources. Destroying a civilian building could prompt a snarky human or Mind comment. This is an idea to explore, not a locked scoring, resource or civilian-consequence system.

## Progression philosophy (later feature)

- **Between missions:** chosen ship improvements are permanent for the current run, not necessarily permanent across runs.
- **During missions:** power-ups are normally temporary, expiring at mission conclusion.
- **Exception:** scripted events may grant an upgrade that stays permanently for the run.
- Potential upgrades include weapon, missile, propulsion or manoeuvrability improvements, but no specific upgrade tree has been selected.
- The Mind can narrate modifications in character. Do not confuse these future rules with the existing experimental S/C/M pickup implementation.

## Parking lot — explicitly not agreed for implementation yet

- Free-scrolling infiltration through tunnels and installations; locating and destroying command-and-control nodes, power plants and defensive systems.
- Levels that mix forced-scroll interception, freely explored regions and later scripted escape.
- Reversing ship direction / Uridium-style turnover.
- Adaptive or transforming craft that trade open-combat speed for precision manoeuvrability in confined spaces.
- Station-keeping, drones, branching missions and broader upgrades.
- Decoupling movement, camera/scroll behaviour and mission-state logic may help future experiments, but is not a requirement to add those systems now.

## Recommended first build milestone

Create a high-resolution playable opening slice from hangar breakout through the planetary gauntlet and surface mini-boss, ending at the engine-reconfiguration transition into space. Prioritise a larger modern-screen presentation, a polished backdrop pass, responsive ground-strike missiles, capped main-gun autofire with separate shot-pattern upgrades, direct hull damage with debris, destructible building prototypes and a small set of human–Mind event lines.

Treat military/civilian building rewards and comments as a prototype experiment until their scoring and consequences are decided. Leave the orbital pursuit, effector boss escape and aftermath for a later milestone.

## Source and intent

Updated from the Unfortunate Events design discussion on 10 November 2026. This is a working creative reference, with user decisions separated from assistant proposals. No game code was changed by this document.
