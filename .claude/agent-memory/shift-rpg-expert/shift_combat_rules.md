---
name: SHIFT Combat Rules — Core Mechanics
description: Definitive SHIFT rulebook combat mechanics as mapped to the Godot implementation
type: project
---

# SHIFT Combat Rules

## Action Declaration
- Player picks one **core trait** (Mind/Body/Soul) — mandatory
- Player picks one **focus trait** (sub-trait) — optional, adds a second die
- Target is declared at the same time, before any roll
- No menu of named actions; traits + fiction determine the action

## No Defensive Roll
- SHIFT uses a single-roll system: the attacker rolls, the defender is passive
- The defender's traits are only relevant for determining which trait degrades
- Enemies act in their own ADVERSARY phase, not in reaction to player turns

## Dice Resolution (System.resolve)
- Roll each die in the pool independently
- Any die showing 1 → CRITICAL_SUCCESS (checked first, unconditional)
- Any die ≤ 3, none at max → SUCCESS
- Any die ≤ 3, and any die at its max → MITIGATED_SUCCESS
- No die ≤ 3, any die at max → CRITICAL_FAILURE
- No die ≤ 3, no die at max → FAILURE

## Consequence Table
| Result | Effect on Target | Effect on Attacker |
|---|---|---|
| CRITICAL_SUCCESS | Two traits shift down (strongest first) | None |
| SUCCESS | One trait shifts down (strongest) | None |
| MITIGATED_SUCCESS | One trait shifts down (strongest) | Die at max value: that trait shifts down |
| FAILURE | None | None |
| CRITICAL_FAILURE | None | Core trait used shifts down |

## Shift Down
Die degrades one step: D12 → D10 → D8 → D6 → D4 → EXHAUSTED
EXHAUSTED traits cannot be used.

## Turn Order (per round)
1. TURN_ORDER: each player rolls Body die; ≤3 → Phase 1, >3 → Phase 2
2. PHASE_ONE: Phase 1 players act sequentially
3. ADVERSARY: all living enemies act (one by one, may have multiple actions)
4. PHASE_TWO: Phase 2 players act sequentially
5. ROUND_END: check defeat; loop or end combat

Enemies always act between Phase 1 and Phase 2 — they never have initiative.

## Defeat Condition — Adversaries (Chapter 4, p.39/42)
Adversaries are overcome when a number of their Traits equal to their **Power** are Exhausted.
- Power 1 → 1 Trait exhausted; Power 2 → 2 Traits; Power 3 → 3 Traits; Power 4 → 4 Traits; Power 5 → 5 Traits
- Special Traits add to the threshold: ARMORED +1, HEAVILY ARMORED +2, A SMALL GROUP OF… +1, A LARGE GROUP OF… +2
- Exhausting the Attitude Trait counts toward the threshold (p.42)
- "What happens when an Adversary is overcome is up to the players' intentions, the GM's discretion, and the story so far." (p.42)
- The current code threshold `power + special_trait_bonuses` is CORRECT per the rulebook.

## Attitude Trait — Full Rules (Chapter 4, p.39–42)

### Structure
- Every adversary has **exactly one** Attitude Trait — it is their single Core Trait (p.39, p.43)
- Attitude consists of: a description, a Shift Die, and one or more Keywords (p.39)
- Its **Max Die is D4** (p.44 — "Because an Adversary's Attitude is its main driving force, the Attitude Trait's Max Die is a D4")
- Attitude counts toward the adversary's total Trait count (Power + 2 traits total, Attitude is one of them)

### In Combat (Encounter Use)
- Adversaries combine **up to two Traits** per Action Roll; Attitude **can** be one of them — "Adversaries make Action Rolls … by combining up to two of their Traits (one of which can be their Attitude Trait)" (p.28/32)
- Players **can** target and shift down Attitude like any other trait (p.41–42)
- Exhausting Attitude **counts toward** the defeat threshold (p.42)
- Exhausting Attitude during combat **does not necessarily change its Keywords** (but can, at GM's discretion) (p.42)
- After combat ends with the adversary still alive, Attitude resets to D4 (p.42)

### Outside Combat (Narrative/Social Use)
- Attitude is primarily a **narrative tool**: it colors ALL adversary actions, not just those using its die (p.39)
- Players can influence Attitude by shifting its die down through social/roleplay action rolls
- When Attitude is Exhausted outside combat, its **Keywords must change** and the die resets to D4 (p.41)
- The GM must inform players if the narrative makes changing Attitude impossible (p.41)
- Example: player rolls Soul to shift down a suspicious commander's Attitude D10→D12, then a second success Exhausts it, changing "suspicious" to "intrigued" and resetting to D4 (p.42 example)

### Key Design Rule: Keywords vs. Shift Die
- The Keyword is the narrative/behavioral color for ALL of the adversary's actions
- The Shift Die is only rolled when Attitude is included in an action roll
- These are two separate dimensions — an adversary can have an "angry" Attitude even if the die isn't being rolled

### Implementation Notes
- `EnemyEntity` has single `attitude: TraitData` — CORRECT (one per adversary)
- `CombatState.from_enemy()` adds Attitude to `dice_state["Attitude"]` — CORRECT
- `get_available()` includes Attitude — CORRECT (it is targetable like any other trait)
- `get_focus_traits()` excludes "Attitude" from focus trait list — CORRECT (it is a Core Trait, not a Focus Trait)
- `is_core_exhausted()` includes "Attitude" check — CORRECT
- Attitude Max Die should be D4 — verify in `.tres` resources that attitude TraitData always has die = D4

## Defeat Condition — Player Characters
**The rulebook does NOT define an explicit trait-exhaustion threshold for PC defeat.**
- The only statement is: "Exhausting a Core Trait can be disastrous; it could result in your Character falling unconscious or even dying, depending on how perilous the situation is." (p.11)
- There is NO rule stating that exhausting ANY single trait defeats a PC, nor that ALL traits must be exhausted.
- PC defeat/incapacitation is **narrative and GM discretion**, not a fixed mechanical threshold.
- Implication for the Godot implementation: the game must define its own PC defeat rule. The most rulebook-faithful approach is: GM/game decides, but a reasonable default is treating exhaustion of all three Core Traits (Mind, Body, Soul) as defeat, since Core Trait exhaustion is explicitly flagged as potentially fatal/incapacitating.

## Known Ambiguity
Body roll threshold (≤3 = Phase 1) means a D4 Body character almost always acts in Phase 1.
Interpretation used: low Body = desperate/reactive, so acts first. May need rulebook verification.

**Why:** Established when mapping SHIFT turn order to the CombatTurnManager implementation (2026-05-02)
**How to apply:** Use this as the authoritative reference for any combat loop implementation decisions.
