# Level 01 — The Great Escape: narrative and gameplay design

**Date:** 10 November 2026  
**Status:** Narrative and mission concept; **not** an instruction to implement all features in Prototype 01.

## Design boundaries

- **Core game:** 2D horizontal, right-facing, Nemesis/Gradius-inspired scrolling shooter. One playable ship, one initial level, rapid single-shot-per-press forward cannon, forward unguided missile, movement in two axes.
- **Platform:** PC-first prototype, with landscape phone/touch control implications worth considering later. Portrait vertical-scrolling was discussed, but **horizontal remains the chosen direction**.
- **Avoid scope inflation:** no ship transformations, flight modes, exploration, alternate camera configurations, or persistent upgrade framework required for the initial mechanical milestone.
- **Current code vs future design:** the existing playable experimental slice already includes simple in-level weapon pickups, as documented in `Design overview.md`. This new document describes the *intended opening mission* and future progression rules; it does not claim the expanded story, bosses or progression have been implemented.

## Opening mission: seven story beats

1. **Hangar breakout (cutscene).** Ship forces its way out of a hangar or facility under fire. Its Mind reports that the engines are undergoing emergency reconfiguration and it **cannot leave orbit yet**; the plan is to survive long enough without exploding.
2. **Planetary gauntlet.** Horizontal forced-scroll across ground and air defences: tanks, launchers, fixed guns, and hostile aircraft. Conversational commentary is occasional, contextual and does not interrupt normal play.
3. **Surface mini-boss.** A more substantial defensive emplacement or interceptor with readable attack patterns, defeated before the flight can continue.
4. **Reconfiguration complete.** The Mind declares the engines ready, departs the planet, and the level visually transitions from atmosphere to space.
5. **Orbital pursuit.** Additional combat waves establish the new environment and escalating danger.
6. **Overwhelming encounter and escape.** A **huge hostile boss** arrives. Player weapons cannot meaningfully hurt it. The vessel tries to compromise our systems using **effectors**. After growing irritated, the Mind diverts power from armour/shields to locomotion. The objective becomes **escape/survive**, not win the firefight; scrolling accelerates and hits become especially dangerous. Convey the invulnerability and changed objective clearly so the player does not mistake this for a winnable battle.
7. **Aftermath.** Narrative exchange explains the situation, considers the next mission and opens the door to ship modifications.

This is **one level** with contrasting phases, rather than multiple standalone missions.

## The Mind — voice and comedy

The Mind is capable, clever, dry, indignant and increasingly exasperated by the enemy's conduct. The joke is that a furious `RIGHT! That does it!` cues what sounds like a devastating counterattack, but the Mind's sensible response is **to run away very, very fast**.

### Effector encounter — dialogue treatment

The following includes user-provided anchor lines and exploratory suggested connective writing. Preserve the distinction.

**User-provided dialogue (near-verbatim, lightly corrected for spelling):**
> “They're attempting to take us over via effector, and I don't know how much longer I'm willing to put up with that.”  
> “RIGHT! That does it!”

**Proposed staging and additional dialogue (draft, not locked script):**

*An enemy vessel begins an effector intrusion. The ship shudders; displays flicker. Player controls may briefly feel disrupted, if fair and readable.*

**Mind:** “They're attempting to take us over via effector, and I don't know how much longer I'm willing to put up with that.”

*Another effector pulse.*

**Mind:** “I did ask them to stop.”

*Systems flicker again.*

**Mind:** “RIGHT! That does it!”

*The apparent setup for retaliation is deliberately misleading. The engines flare.*

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

The shorter original user wording about hope of not exploding during reconfiguration should also be preserved as the opening's intended tone, rather than presenting any assistant version as final.

## Progression philosophy (later feature)

- **Between missions:** chosen ship improvements are **permanent for the current run**, not necessarily permanent across runs.
- **During missions:** power-ups are **normally temporary**, expiring at mission conclusion.
- **Exception:** scripted events may grant an upgrade that stays permanently for the run.
- Potential upgrades include weapon, missile, shield, propulsion or manoeuvrability improvements, but **no specific upgrade tree has been selected**.
- The Mind can narrate modifications in character. Do not confuse these future rules with the existing experimental C/M pickup implementation.

## Parking lot — explicitly not agreed for implementation yet

- Free-scrolling infiltration through tunnels and installations; locating and destroying command-and-control nodes, power plants, defensive systems.
- Levels that mix forced-scroll interception, freely explored regions, and later scripted escape.
- Reversing ship direction / Uridium-style turnover.
- Adaptive or transforming craft that trade open-combat speed for precision manoeuvrability in confined spaces.
- Station-keeping, drones, branching missions and broader upgrades.
- Technically, decoupling movement, camera/scroll behaviour and mission-state logic may help future experiments, but is **not** a requirement to add those systems now.

## Proposed development boundary

First prove the arcade fundamentals: movement, rapid manual cannon fire, missile, enemies, scrolling, terrain and responsiveness. The fully scripted cutscene, mini-boss, huge unwinnable boss, contextual voice, post-mission story and run upgrade mechanics are subsequent work to scope independently.

## Source and intent

Captured from the Unfortunate Events design discussion on 10 November 2026. This is a working creative reference, with user decisions separated from assistant proposals. No game code was changed by this document.
