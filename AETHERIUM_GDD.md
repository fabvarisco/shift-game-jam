# AETHERIUM
## Game Design Document — v1.0
### SHIFT RPG Game Jam 2026

---

> *This work was created using Hit Point Press' Powered by SHIFT Open License v1.0, ©2026, Hit Point Press Inc. Learn more at rpgshift.com. **AETHERIUM** is an independent production by [Team Name] and is not affiliated with Hit Point Press.*

---

## TABLE OF CONTENTS

1. [Vision Statement](#1-vision-statement)
2. [Design Pillars](#2-design-pillars)
3. [Game Overview](#3-game-overview)
4. [Story Synopsis](#4-story-synopsis)
5. [Characters](#5-characters)
6. [World](#6-world)
7. [Mechanics Specification](#7-mechanics-specification)
8. [Content Scope](#8-content-scope)
9. [UX/UI Specification](#9-uxui-specification)
10. [Art Direction & Briefs](#10-art-direction--briefs)
11. [Audio Direction & Briefs](#11-audio-direction--briefs)
12. [28-Day Production Schedule](#12-28-day-production-schedule)
13. [Team Responsibilities Matrix](#13-team-responsibilities-matrix)
14. [Risk Register](#14-risk-register)
15. [Cut List Priority](#15-cut-list-priority)
16. [Submission Checklist](#16-submission-checklist)

---

## 1. VISION STATEMENT

**AETHERIUM** is a 40-60 minute narrative-driven JRPG built on the SHIFT RPG system. The player follows Dr. Vera Issen — a brilliant xenobiologist working for AETHON Industries — as she travels three planets cataloguing alien life with her aetherium-powered bionic arm. Joined by a deserter combat robot (WREN) and a vengeful local guide (Kael), Vera slowly discovers that her research is being weaponized. The game ends with a single, devastating choice: the corporation fails, but at the cost of the friend she came to love.

A steampunk space opera in pixel art. Dark, intimate, cinematic. Combat that mirrors SHIFT mechanics faithfully. A story about complicity, friendship, and the weight of what you didn't know.

---

## 2. DESIGN PILLARS

The five pillars below are the project's truth-tellers. Every feature, asset, and design decision must serve at least one. Anything that serves none gets cut.

### Pillar 1 — **SHIFT, FAITHFULLY DIGITAL**
The combat is SHIFT, exactly. Dice tumble on screen. Trait cards display. Critical Successes/Failures cascade with the same emotional weight as the tabletop. We honor the system that hosts us.

### Pillar 2 — **EMPATHY OVER VIOLENCE**
The party never kills creatures. They subdue, observe, document. The combat system rewards understanding over destruction. This pillar drives encounter design, journal mechanics, and the moral architecture of the entire story.

### Pillar 3 — **THE WEIGHT OF WHAT YOU DIDN'T KNOW**
Vera is complicit before she is heroic. Kael lies before he loves. WREN survives before it cares. The game is about the gap between intention and consequence. Every system supports this gap.

### Pillar 4 — **BRASS WARM, VOID COLD**
Visual identity is non-negotiable. Warm aetherium-gold and brass against deep blue/black void. Iron Kingdoms grit, Arcane glow. Every screen must look like one of those two things or both at once.

### Pillar 5 — **40 MINUTES, FELT LIKE A LIFETIME**
We are not building scope. We are building moments. A quiet campfire. A held handshake. A robot's last sentence. We will cut content before we cut feeling.

---

## 3. GAME OVERVIEW

### Genre
JRPG / Narrative Adventure with turn-based dice combat

### Engine
Godot 4.x

### Platform
PC (jam submission), Web build if scope permits

### Target Length
40–60 minutes single playthrough, single ending

### Player Activities
- **Explore** HD-2D pixel-art environments (Octopath Traveler-style depth movement)
- **Engage** creatures in turn-based SHIFT-mechanic combat
- **Document** subdued creatures into Vera's journal (codex)
- **Solve** trait-based puzzles using party cooperation
- **Choose** dialogue options that affect cutscenes (no branching endings — narrative decisions affect tone, not outcome)
- **Manage** trait dice between encounters (rest, recover, reflect)

### Visual Reference
Octopath Traveler II + Sea of Stars + Iron Kingdoms aesthetic. Pixel sprites with HD lighting. Brass-warm palette against cold void backgrounds.

### Audio Reference
Arcane (Imagine Dragons / League of Legends OST) for emotional swells. Sea of Stars for combat music. Sparse, atmospheric ambience over hi-fi pixel-style instrumentation.

---

## 4. STORY SYNOPSIS

**ACT 1 — THE SCORE** *(Cinder Station, ~10 min)*
Vera's bionic arm is stolen by a small robot, WREN. She chases it into the lower decks. A Cinder Syndicate reclamation drone arrives to collect WREN's debt. Vera and WREN team up to defeat the drone (tutorial fight). Vera, moved by WREN's situation, invites it to be her field assistant for an upcoming three-planet research expedition.

**ACT 2 — THE FIELD** *(3 planets, ~30 min)*
- **KORVA-IX (The Copperwood):** Bioluminescent forest. Vera, WREN bond. Mysterious AETHON terminal hints at hidden agenda.
- **ORREVAL-VI (The Hollow Coast):** Salt-bleached ruined coast. Vera and WREN are nearly killed by a Shore-Walker; **Kael Mourne** saves them. He recognizes her AETHON credentials and sees an opportunity for revenge — he agrees to be their guide. He starts caring about them anyway.
- **KOROVAN'S GIFT (The Weeping Cathedral):** Singing stone-cathedral world. The party bond crystallizes. Vera, Kael, and WREN find an AETHON archive. The truth breaks: her research feeds **PROJECT REQUIEM**, a neural-resonance weapon that will mass-paralyze entire species. Every creature she has catalogued is now indexed as a target.

**ACT 3 — THE WEIGHT** *(Argent Prow vessel, ~10 min)*
Chamber piece. The party returns to Cinder Station. WREN reveals the live data subroutine in Vera's arm. Kael confesses his original deception. Vera decides to destroy the Requiem index from the inside. WREN volunteers to be the broadcast vector — knowing it will end its life. Kael volunteers to hold security while it transmits — knowing it may end his.

**ACT 4 — REQUIEM** *(AETHON HQ, ~10-15 min)*
The infiltration. Three intercut sequences: Vera + WREN at the broadcast console, Kael's last stand in the security wing, Director Veyl realizing her empire is collapsing in real time. WREN dies completing the transmission. Kael does not return from the corridor. Vera walks out alone.

**EPILOGUE** — Three months later. Vera publishes everything. AETHON falls. She opens a new journal: *"Field Notes, Volume II. For the species we did not save. And the ones we still might."* Fade.

---

## 5. CHARACTERS

### DR. VERA ISSEN — *Soul-primary*
Senior Field Xenobiologist, AETHON Research Division. Brilliant, driven, true believer in AETHON's mission. Lost her left arm at 26 in a lab accident; the AEGIS-7 prosthetic was awarded to her as recognition. Doesn't know what her arm actually does.

| Stat | Value |
|---|---|
| Mind | D8 |
| Body | D10 |
| **Soul** | **D6** *(strongest)* |
| AEGIS-7 Bionic Arm *(Primary Focus)* | D4 — *Interface, Record, Aetherium-Powered* — Drawback: *AETHON-Tagged* |
| Field Researcher | D6 — *Observe, Catalogue, Empathy* |
| Quick Thinking | D6 — *Improvise, Adapt* |

### KAEL MOURNE — *Body-primary*
Salvager from Orreval-VI. Lost his family fifteen years ago to AETHON's "decommissioning" of his planet. Has been hunting AETHON ever since. Meets Vera by accident; uses her to access AETHON HQ. Falls into genuine friendship despite himself.

| Stat | Value |
|---|---|
| Mind | D8 |
| **Body** | **D6** *(strongest)* |
| Soul | D10 |
| Salvaged Pulse Hammer *(Primary Focus)* | D4 — *Heavy, Strike, Aetherium-Charged* — Drawback: *Worn Mechanism* |
| Survivor | D6 — *Endure, Take a Hit, Tough* |
| Local Knowledge | D6 — *Track, Navigate, Hidden Routes* |
| **HIDDEN: Hidden Agenda** *(invisible until Act 2 reveal, then deleted)* | D6 — *Deceive* |

### W.R.E.N. — *Mind-primary*
**W**arfare **R**obot **E**nhanced **N**etwork, designation 0773. AETHON military-grade combat asset. Deserted during a deployment after experiencing a "logic cascade" — its first refusal. Lives in Cinder Station's lower decks, paying for its own survival in stolen aetherium. Vera doesn't know what WREN is.

| Stat | Value |
|---|---|
| **Mind** | **D6** *(strongest)* |
| Body | D10 |
| Soul | D8 |
| Tactical Network *(Primary Focus)* | D4 — *Analyze, Predict, Identify Weakness* — Drawback: *Limited Speech* (shifts up across game) |
| Hacking Suite | D6 — *Interface, Decrypt, Override* — Drawback: *Trace-able* |
| **Warfare Protocols** | D6 — *Precision Strike, Evasion* — **STARTS EXHAUSTED** *(self-locked)* |

### DIRECTOR MAREN VEYL *(antagonist)*
Project Lead, Special Programs Division. The human face of Project Requiem. Speaks softly, dresses in brass-trimmed grey. Believes she is doing good. Vera trusts her completely until the final act.

---

## 6. WORLD

### Setting
Steampunk space opera. The galaxy is run on **Planetary Licenses** issued to corporations, with citizens born into **Civic Debt**. AETHON Industries holds more licenses than any other corporation in the inner sector and specializes in **AETHERIUM** — a resonant energy refined from crystalline deposits in dead-world mantles.

### Locations Built for the Game
1. **CINDER STATION** — AETHON's flagship orbital city. Brass corridors, copper markets, steam vents. The lower levels are run by the **Cinder Syndicate**.
2. **ARGENT PROW** — The survey vessel. Hub between planets. Crew quarters, lab, journal terminal.
3. **KORVA-IX (The Copperwood)** — Bioluminescent forest world. Aetherium veins under the soil. Tone: wonder.
4. **ORREVAL-VI (The Hollow Coast)** — Salt-bleached coastal world with rusted AETHON ruins. Tone: dread.
5. **KOROVAN'S GIFT (The Weeping Cathedral)** — Cathedral stone-world that sings. Tone: awe.
6. **AETHON HQ** — Brass-and-velvet executive interior. Site of the finale.

### Faction: AETHON Industries
The most generous sponsor and most ruthless owner in the inner sector. Faces of warmth covering machineries of consumption.

### Faction: Cinder Syndicate ("The Hooks")
Lower-deck criminal organization. Brass hook insignia. Specializes in aetherium debt collection. Operates only on Cinder Station.

---

## 7. MECHANICS SPECIFICATION

### 7.1 Action Roll System

Every uncertain action uses a **SHIFT Action Roll**:

```
1. Player selects Core Trait (Mind/Body/Soul) → roll 1 die
2. Player optionally selects Focus Trait → roll 2nd die alongside
3. Both dice resolve together
4. Apply Result Type:
    - All 1s         = Critical Success (pick bonus)
    - Any 1/2/3      = Success
    - 1/2/3 + max    = Mitigated Success (own trait shifts down)
    - No success     = Failure
    - All max        = Critical Failure (own trait shifts down + Drawback possible)
```

### 7.2 Combat Loop

**Encounter Begin** → adversary card displays with all Traits and current dice
**Round Structure:**
1. Each PC takes one action in player-chosen order
2. Adversary takes actions equal to its Scale (1, 2, 3, or 4)
3. Round repeats

**On a successful PC action:** the targeted adversary Trait shifts DOWN one die.
**When trait would shift below D12:** Trait becomes EXHAUSTED (gray out, flip card).
**When count of Exhausted Traits = Resistance Number:** encounter ends; data captured to journal.

### 7.3 Targeting & Matchups

Each adversary trait has a defined matchup profile:
- **Strong matchup** (e.g., Body+Hammer vs Plated Carapace) → roll is **Inspired**
- **Neutral matchup** → standard roll
- **Weak matchup** (e.g., Mind+Empathy vs Plated Carapace) → roll is **Risky**

The combat UI displays matchup hints with color glow on action options:
- 🟢 Green = Inspired
- ⚪ White = Neutral
- 🔴 Red = Risky

### 7.4 Trait Recovery

- **Mid-combat:** Critical Success bonus can shift up an ally's trait
- **Between encounters on a planet:** Aetherium Caches (placed in environments) restore one Focus Trait
- **At Argent Prow:** All traits return to Max Die; Drawbacks can be removed
- **Between planets (cutscene):** Full restoration

### 7.5 Drawback System

Drawbacks attach to traits during play (typically on Critical Failure or specific story beats). They make rolls involving that trait Risky when the Drawback applies. Predefined Drawback list (in code, not GM-improv):

| Drawback | Trigger | Effect |
|---|---|---|
| *Bleeding* | Crit Fail on Body | Body rolls Risky until rested |
| *Confused* | Crit Fail on Mind | Mind rolls Risky for 2 rounds |
| *Shaken* | Crit Fail on Soul | Soul rolls Risky for 2 rounds |
| *Damaged* | Focus Trait Crit Fail | That Focus Trait rolls Risky |
| *Deafened* | Sonic adversary attack | Mind rolls Risky for 2 rounds |
| *AETHON-Tagged* | Permanent on AEGIS-7 | Becomes mechanical in Act 3 |

### 7.6 Journal Mechanic (Codex)

Each subdued creature is recorded as a **Journal Entry** containing:
- Creature illustration (artist deliverable)
- Vera's handwritten field notes (writer deliverable)
- Trait list (auto-generated)
- Behavioral observations
- One personal note from Vera per entry (humanizes her)

**Story payoff:** In Act 3, the journal becomes the weapon. The player has been writing the index the whole game.

### 7.7 Puzzle System

Puzzles are mechanically identical to combat encounters — the puzzle is represented by a **Trait** (e.g., *"ENCRYPTED AETHON TERMINAL D8"*) that the party must Exhaust through Action Rolls.

Puzzle types in the game:
1. **Environmental observation** — observe creature behavior to navigate
2. **Terminal decryption** — WREN-led, reveals lore fragments
3. **Cooperative trust puzzles** — multiple PCs roll together (Act 3 finale planning sequence)
4. **Aetherium routing** — physical environment puzzles using lit conduits

### 7.8 Dialog System

Already built by your devs. Story integration:
- Branching dialogue choices that affect tone, not outcome
- Trust meter (invisible) tracks Vera's growing doubt about AETHON
- Some dialogue options become available only after specific journal entries

---

## 8. CONTENT SCOPE

### 8.1 Locations (6 total)
| # | Location | Time | Encounters | Puzzles |
|---|---|---|---|---|
| 1 | Cinder Station (alley + apartment) | ~10 min | 1 (Reclamation Drone tutorial) | 1 (chase) |
| 2 | Argent Prow (hub) | recurring | 0 (cutscenes only) | 1 (Act 3 finale planning) |
| 3 | Korva-IX | ~10 min | 2 + 1 mini-boss | 1 (Aetherium routing) |
| 4 | Orreval-VI | ~10 min | 2 + 1 mini-boss | 1 (Terminal decryption) |
| 5 | Korovan's Gift | ~10 min | 2 + 1 boss | 1 (Resonance puzzle) |
| 6 | AETHON HQ | ~10-15 min | 1 (security wing waves) | 1 (broadcast console) |

### 8.2 Creatures (10 total)
- **Tutorial:** Reclamation Drone *(Cinder Syndicate)*
- **Korva-IX:** Hushwing, Copper-Mole, Grove-Warden *(mini-boss)*
- **Orreval-VI:** Gear-Mite Swarm, Husk-Eel, Shore-Walker *(mini-boss, Kael's intro)*
- **Korovan's Gift:** Chorus-Beast, Vault-Shrike, The Korovan Mother *(boss)*
- **Finale:** AETHON Security Drone *(reskin of Reclamation Drone, Act 4)*

### 8.3 Cutscenes (12 keyed)
1. Vera's apartment intro
2. WREN's theft + chase
3. Alley confrontation (drone arrives, Vera offers deal)
4. Boarding Argent Prow
5. Korva-IX arrival + mother-name moment
6. Orreval-VI Shore-Walker encounter (Kael's intro)
7. Orreval-VI campfire scene
8. Korovan's Gift arrival
9. AETHON archive discovery (truth reveals)
10. Argent Prow chamber piece (full reveal + plan)
11. AETHON HQ intercut climax
12. Epilogue

### 8.4 Items
- Aetherium Cache (consumable, restores 1 Focus Trait)
- Field Toolkit (Vera-only, removes 1 Drawback)
- Salvage Cell (Kael-only, restores 1 Drawback)
- Diagnostic Module (WREN-only, shifts up 1 Trait)
- *Plot items:* The Journal, AEGIS-7, Counter-Signal Module

---

## 9. UX/UI SPECIFICATION

*This is your section, [UX teammate]. Outline below — refine and own it.*

### 9.1 Screens Required
1. **Main Menu** (start, continue, credits)
2. **Exploration HUD** (party indicators, journal access, mini-map)
3. **Combat UI** (party panel, adversary card, action menu, dice tray, log)
4. **Dialogue UI** (portraits, text, choice buttons)
5. **Journal/Codex** (creature entries, browse-able)
6. **Pause Menu** (settings, save, quit)
7. **Cutscene Frame** (letterbox, skip option)

### 9.2 Combat UI Anatomy *(matches your reference mockup)*
- Top: turn order indicator
- Left: 3 PC portraits with Core Trait dice + active Drawbacks
- Center: scene art with sprites
- Right: adversary trait cards (all visible per SHIFT)
- Bottom: action menu (Attack / Ability / Tactic / Defend / Item / Flee)
- Bottom-right: dice tray (animated rolls) + battle log

### 9.3 Dice Animation Spec
- Roll duration: 1.2–1.8 seconds including settle
- Dice physics: light tumble, cinematic pause before lock
- Crit Success VFX: aetherium-bright gold flash, sound stinger
- Crit Failure VFX: dice crack visual, low resonant thud
- Result text appears with typewriter delay

### 9.4 Onboarding
- First combat doubles as tutorial — guided UI hints overlay each new system
- Codex unlocks first entry with a "Journal updated" notification (teaches the codex)
- No separate tutorial mode — story IS the tutorial

### 9.5 Accessibility (Minimum)
- Subtitles always on
- Skip dialogue option
- Pause anywhere
- Configurable text speed
- Color-blind-safe matchup indicators (icons + color, not color alone)

---

## 10. ART DIRECTION & BRIEFS

### 10.1 Visual Identity

**Style:** HD-2D pixel art (Octopath Traveler II reference)
**Palette:**
- WARM: brass, copper, fire-orange, aetherium-gold
- COLD: deep blue/black void, vapor-white, electric-cyan
- ACCENT: brass-hook red (Cinder Syndicate), AETHON-grey

**Lighting:** Dramatic, cinematic. Strong directional light, deep shadows, glowing aetherium accents.

### 10.2 Asset Briefs

#### Characters (3 PCs + 1 antagonist)
- 3/4 isometric walk cycles (8 directions or mirror)
- Combat poses: idle, attack, hurt, victory
- Portrait art for dialogue (3 expressions each minimum)
- WREN: small chassis, no humanoid form, but expressive optic + posture animation

#### Adversaries (10 creatures)
- Combat sprite (4-frame idle minimum)
- Attack animation
- Hurt animation
- Subdued/captured pose (for journal art)
- Trait card illustration

#### Environments (6 locations)
- 1-2 hero backgrounds per location (parallax-ready)
- Tileset for explorable areas
- 1-2 distinctive landmarks per planet
- Lit aetherium props (caches, terminals, conduits)

#### UI Elements
- Trait cards (template + 30+ trait illustrations)
- Dice sprites (D4–D12, all faces)
- Menu frames, buttons, icons
- Journal page templates

### 10.3 Asset Naming Convention
```
char_[name]_[action]_[direction]_[frame].png
ex: char_vera_walk_north_01.png

env_[planet]_[area]_[layer].png
ex: env_korva_grove_bg.png

ui_[screen]_[element].png
ex: ui_combat_traitcard.png
```

### 10.4 Critical Constraint
**NO GENERATIVE AI.** Per jam rules. All art hand-made by team. Reference, study, sketch, paint — no Midjourney, no Stable Diffusion, no exceptions. This protects our submission.

---

## 11. AUDIO DIRECTION & BRIEFS

### 11.1 Music Tone Per Location
| Location | Mood | Instrumentation Reference |
|---|---|---|
| Cinder Station | Industrial unease | Low brass, mechanical percussion, steam hiss |
| Argent Prow | Quiet, hopeful | Solo cello, light piano, distant aetherium hum |
| Korva-IX | Wonder, mystery | Glockenspiel, soft strings, ambient pad |
| Orreval-VI | Decay, weight | Detuned strings, low drone, salt wind |
| Korovan's Gift | Awe, melancholy | Choral vocals (wordless), pipe organ, wind |
| AETHON HQ | Cold, terminal | Synth pulse, brass stabs, military percussion |

### 11.2 Combat Music
- Standard combat track (2-3 min loop, intensity ramp)
- Boss combat track (Korovan Mother + finale)
- Tutorial fight track (lower-stakes variant)

### 11.3 SFX Required
- Dice tumble + lock (variants for each die size)
- Crit Success / Crit Failure stingers
- Aetherium hum (ambient, looping)
- Hammer impact, drone hum, creature calls (per creature)
- Footsteps per surface (metal grate, stone, salt, soil)
- UI clicks, journal open/close, menu navigation

### 11.4 Stinger Cues for Story Beats
- WREN's theft moment
- Kael's "Hidden Agenda" reveal
- Truth discovery in AETHON archive
- WREN's death
- Kael's last words

### 11.5 No Voice-Over
Text-only dialogue for scope reasons. Sound designer focuses on music and SFX. Optional: short non-verbal vocalizations (Vera's gasp, WREN's chirps, Kael's grunts) if time permits.

---

## 12. 28-DAY PRODUCTION SCHEDULE

> **Today is Day 1.** Submission due **June 1st, 23:59**. Hard deadline.

### WEEK 1 — PRE-PRODUCTION & VERTICAL SLICE FOUNDATION (Days 1-7)

**Goal:** Pre-production complete. Combat system fully functional. Act 1 prototype playable end-to-end (no final art).

| Day | Devs | Artists | Writer | Sound | UX |
|---|---|---|---|---|---|
| 1 | Read GDD; finalize combat data structure | Style sheet finalized; palette locked | Read GDD; outline all dialogue | Read GDD; gather references | Combat UI wireframes |
| 2 | Implement adversary trait card system | Vera sprite + walk cycle | Act 1 dialogue draft | Cinder Station ambient track | Dialogue UI wireframes |
| 3 | Implement dice roll + result resolution | WREN sprite + walk cycle | Act 1 dialogue revision | Combat music track v1 | Journal UI wireframes |
| 4 | Implement matchup logic (Risky/Inspired) | Reclamation Drone sprite | Tutorial copy + onboarding hints | UI sound pack | Onboarding flow |
| 5 | Implement Drawback system | Cinder Station BG (alley) | WREN dialogue style guide | Dice SFX pack | Combat UI mockups |
| 6 | Tutorial encounter wired | Trait card template + 5 cards | Codex template + first 3 entries | Aetherium ambient loop | Accessibility audit checklist |
| 7 | **MILESTONE: Act 1 playable (placeholder art OK)** | Vera + WREN portraits | Act 2 dialogue starts | Cinder track polish | UI v1 integrated |

### WEEK 2 — ACT 2 (Days 8-14)

**Goal:** All three planets implemented at gray-box level. All creatures statted in code. First two planets art-polished.

| Day | Devs | Artists | Writer | Sound | UX |
|---|---|---|---|---|---|
| 8 | Korva-IX scene; aetherium cache item | Kael sprite + portraits | Korva-IX dialogue | Korva-IX music | Codex UI polish |
| 9 | Korva-IX creatures coded | Korva-IX BG art | Korva-IX dialogue revision | Korva-IX SFX | Save/load UI |
| 10 | Orreval-VI scene wired | Orreval-VI BG art | Orreval-VI dialogue (Kael intro) | Orreval-VI music | Pause menu |
| 11 | Orreval-VI creatures coded | Orreval-VI creatures | Campfire scene script | Combat track v2 | Settings menu |
| 12 | Korovan's Gift scene wired | Korovan BG art | Korovan dialogue | Korovan music (key emotional) | Tutorial overlays |
| 13 | Korovan creatures + Mother boss | Korovan creatures | Truth-reveal cutscene script | Stinger pack | Cutscene UI |
| 14 | **MILESTONE: All Act 2 playable** | Polish pass on planets 1-2 | Act 3 + 4 dialogue draft | Boss music | UX polish pass |

### WEEK 3 — ACT 3 & 4 + JOURNAL CONTENT (Days 15-21)

**Goal:** Acts 3 and 4 implemented. Journal entries finalized. Full single playthrough functional.

| Day | Devs | Artists | Writer | Sound | UX |
|---|---|---|---|---|---|
| 15 | Argent Prow hub + chamber piece scene | Argent Prow BG | Act 3 chamber piece script | Argent Prow music | Journal entry layout |
| 16 | Cooperative trust puzzle | Argent Prow props | Kael's confession scene | Confession music cue | Final pause/menu pass |
| 17 | AETHON HQ scene wired | AETHON HQ BG | Act 4 broadcast scene | AETHON HQ music | HUD polish |
| 18 | Intercut sequence logic | Director Veyl portrait + sprite | Director Veyl dialogue | Veyl theme | Director cutscene UI |
| 19 | WREN death + Kael death cutscenes | Death scene art | Final dialogue | Death cue tracks | Final cutscene UI |
| 20 | Epilogue scene | Epilogue art | Epilogue script | Epilogue music | Credits screen |
| 21 | **MILESTONE: Full game playable end-to-end** | All journal illustrations | All codex entries | Full audio pass | Full UX pass |

### WEEK 4 — POLISH, BUG FIX, BUILD (Days 22-28)

**Goal:** Submission-ready build. No new content after Day 24.

| Day | Devs | Artists | Writer | Sound | UX |
|---|---|---|---|---|---|
| 22 | Bug bash day 1 | Polish pass on all sprites | Final dialogue editing | Mix pass | Final UX pass |
| 23 | Bug bash day 2 + balance pass | Polish pass on environments | Codex final review | SFX balance | Accessibility check |
| 24 | **CONTENT FREEZE.** Bug fix only. | Final UI polish | DONE | Final mix | Final accessibility check |
| 25 | Performance optimization | DONE (on call for fixes) | DONE (on call) | DONE (on call) | Playtest 1 |
| 26 | Build + submission test | On call | On call | On call | Playtest 2 |
| 27 | Final build + buffer day | On call | On call | On call | Final playtest |
| 28 | **SUBMIT** | — | — | — | — |

---

## 13. TEAM RESPONSIBILITIES MATRIX

| Role | Owner | Hard Deliverables |
|---|---|---|
| **Tech Lead / Combat Dev** | Dev 1 | Combat system, adversary scripts, save system |
| **Systems Dev** | Dev 2 | Dialog system tie-ins, journal mechanic, puzzles, build pipeline |
| **Character Artist** | Artist 1 | All character sprites, portraits, animations |
| **Environment Artist** | Artist 2 | All backgrounds, tilesets, props, UI assets, trait card illustrations |
| **Writer** | Writer | All dialogue, codex entries, item descriptions, narrative consistency |
| **Sound Designer** | Sound | All music, SFX, ambient loops, stingers, mix |
| **UX Designer (You)** | UX | UI wireframes, mockups, flow, accessibility, playtest coordination |

### Standing Meetings
- **Daily standup, 15 min** — same time every day, async if needed
- **Weekly demo, end of each week** — full team plays current build, commits to next week's scope

### Single Source of Truth
- This GDD = canonical narrative + mechanics
- Trello/Notion board = task state
- Discord = real-time
- Git/Godot = code + assets

---

## 14. RISK REGISTER

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| 1 | Combat system more complex than expected | High | High | Start Week 1; cut Drawback variety if needed |
| 2 | Art workload exceeds 2 artists | High | High | Prioritize hero assets; use simpler tile-based environments for late planets |
| 3 | Writer can't finish all dialogue in time | Medium | High | Dialogue draft Week 1; revise across project; cut optional dialogue first |
| 4 | Sound underestimated | Medium | Medium | Use loopable ambient over composed tracks where possible |
| 5 | Godot performance on builds | Low | High | Test build pipeline Week 1; profile early |
| 6 | Team member illness | Medium | Variable | Build in 1-2 day buffer; document handoffs |
| 7 | Scope creep from new ideas | High | High | This GDD is canonical. New ideas → post-jam list |
| 8 | Final cutscene art quality dip | Medium | High | Reserve best artist for Acts 3-4 |
| 9 | Submission technical issues | Low | Critical | Test submission on Day 26, not Day 28 |
| 10 | SHIFT licensing attribution missed | Low | Critical | Attribution in main menu, credits, AND submission page (3 places) |

---

## 15. CUT LIST PRIORITY

If we fall behind, cut in this order. **Do not deviate.**

### Cut First (Day 22 if behind)
1. Optional dialogue branches
2. Vault-Shrike (use Chorus-Beast variant instead)
3. Argent Prow trust puzzle (reduce to dialogue scene)
4. Aetherium Cache items (keep Argent Prow rest only)

### Cut Second (Day 25 if still behind)
5. Director Veyl portrait variants (use 1 portrait)
6. Some Drawback variations (keep Bleeding/Confused/Shaken only)
7. Combat tutorial overlays (rely on text dialogue)
8. Korova-IX reduced to 1 creature + mini-boss

### Never Cut
- Tutorial fight (Reclamation Drone)
- Kael intro scene (Shore-Walker)
- Korovan archive truth-reveal cutscene
- Argent Prow chamber piece
- WREN's death
- Kael's death
- Epilogue
- SHIFT attribution

---

## 16. SUBMISSION CHECKLIST

### Required for Submission

- [ ] Build runs on target platform (PC standalone)
- [ ] Game completes single playthrough without crash
- [ ] SHIFT Open License attribution in:
  - [ ] Main menu / credits
  - [ ] Submission page on itch.io
  - [ ] README in build folder
- [ ] Attribution string verbatim:
  > *"This work was created using Hit Point Press' Powered by SHIFT Open License v1.0, ©2026, Hit Point Press Inc. Learn more at rpgshift.com. AETHERIUM is an independent production by [Team Name] and is not affiliated with Hit Point Press."*
- [ ] No generative AI assets confirmed
- [ ] Team credits screen complete
- [ ] Game tagged with `#SHIFTGameJam` on submission
- [ ] Playable demo / GIF / screenshots prepared for jam page
- [ ] Description includes: genre, length, content warnings (loss, corporate themes)

### Submission Page Content
- Title + tagline
- 3-5 screenshots (one per location)
- 30-second gameplay GIF
- Game description (300-500 words)
- Controls
- Credits
- Attribution

---

## APPENDIX A — DIALOGUE SAMPLES (REFERENCE)

### The Alley Scene Closing
> **VERA:** "I leave for a field assignment in the morning. Three planets. I need an assistant. Pay's nothing fancy, but it's off-station. Three months out of Syndicate range."
>
> *(she offers her bionic hand, palm-up)*
>
> **VERA:** "What do I call you?"
>
> **WREN:** *"...W.R.E.N."*
>
> **VERA:** *(smiling)* "Wren. Like the bird. Welcome aboard."

### WREN's Final Words *(end of Act 4)*
> **WREN:** *"It is okay, Vera. I am glad. I learned to feel things. Even afraid. Even this."*

### Kael's Last Words *(end of Act 4)*
> **KAEL:** *"You did it?"*
> **VERA:** *"We did it."*
> **KAEL:** *"Good. Tell them. All of them. Tell everyone."*

### Final Journal Entry *(epilogue text)*
> *"Field Notes, Volume II. For the species we did not save. And the ones we still might."*
> — *Dr. Vera Issen*

---

## APPENDIX B — DESIGN PRINCIPLES (THE TEAM SHOULD KNOW THESE BY HEART)

1. **If a system serves no pillar, cut it.**
2. **The dice roll is sacred. The animation has weight.**
3. **Empathy is the mechanic. Violence is the failure state.**
4. **Brass warm. Void cold. Always.**
5. **One ending. One cost. One catalogue. One Vera.**

---

*End of Document — v1.0*
*Owner: [UX Lead, Project Manager]*
*Next revision: end of Week 1*
