# Game Development Plan — Competitive 1v1 Mercenary Tactics

**Working title:** TBD (candidates: Apotheosis variant, Squirrel Wars, etc.)
**Author:** Scott Lee
**Created:** 2026-04-02
**Status:** Planning

---

## 1. Game Overview

A competitive 1v1 real-time turn-based strategy game for mobile (iOS/Android) and PC. Players draft mercenaries from a shared pool via pick/ban, arrange them on a 3x3 grid, then take alternating turns activating mercs to destroy the opponent's main character.

**Core pillars:**
- Deep drafting and positioning strategy
- Asymmetric merc abilities with high skill ceiling
- Quick 5-10 minute matches
- Purely competitive — no pay-to-win, no persistent gameplay advantages
- Cross-platform play (mobile + PC)

---

## 2. Core Gameplay Design

### 2.1 Match Flow

```
Matchmaking → Pick/Ban Phase → Grid Placement → Combat → Victory/Defeat
```

1. **Matchmaking:** Players queue for 1v1 ranked. ELO-based pairing.
2. **Pick/Ban Phase:** Both players see the full roster (30+ mercs). Alternating bans and picks until each player has 9 mercs + 1 main character designation. Format TBD — likely similar to MOBA drafts (ban 2, pick 3, ban 2, pick 3, etc.).
3. **Grid Placement:** Short timer to arrange 9 mercs on a 3x3 grid. Players choose which merc is their main character (enhanced merc — same grid slot but with extra abilities/stats). Positioning is critical (front row = melee, back row = ranged, etc.).
4. **Combat:** Alternating turns. Each player activates available mercs on their turn.
5. **Win condition:** Destroy the enemy main character.

### 2.2 Battlefield

- Each player has their own separate 3x3 grid (9 cells).
- Grids do not overlap — attacks cross over based on weapon targeting patterns.
- Positions are labeled for targeting:

```
Player 1 Grid          Player 2 Grid
[BL][BM][BR]  ←→  [BL][BM][BR]    (Back row)
[ML][MM][MR]  ←→  [ML][MM][MR]    (Mid row)
[FL][FM][FR]  ←→  [FL][FM][FR]    (Front row)
```

- Dead mercs leave their cell empty and locked (no swapping into it).

### 2.3 Action Point System

**Per-merc AP pools:**
- Each merc has an individual AP pool that regenerates each turn.
- AP regen rate is a stat — slow mercs (axe-wielder) gain ~60-70 AP/turn, fast mercs (gunslinger) gain more.
- A merc requires **100 AP** to be eligible for activation.
- Using a merc can bring them into negative AP (they'll need multiple turns to recharge).
- AP can be modified by abilities (passive/active) from other mercs.

**Actions per turn:**
- Turn 1: 1 action (activate 1 merc)
- Turn 2: 2 actions
- ...up to a max of 5 actions per turn.
- Available mercs (100+ AP) are pooled, and which ones you can activate is **randomly selected** from that pool.
- This introduces controlled randomness — you build your team to have good options regardless of the draw.

### 2.4 Common Abilities

Every merc has access to these baseline abilities (in addition to unique ones):

- **Guard:** Skip this merc's action. Take 50% less damage and become immune to critical hits until your next turn. Costs the player one of their actions for the turn.
- **Swap:** Switch positions with an adjacent merc on your grid. Costs both mercs 50 AP. Cannot swap with a dead merc (empty cell is locked).

### 2.5 Weapon Targeting Patterns

Weapons determine which cells on the **enemy grid** a merc can hit. Valid targets are resolved by the grid based on which mercs are alive.

| Weapon Type | Valid Targets | Hit Pattern |
|---|---|---|
| Sword | Frontmost alive per column | Single target |
| Axe | Frontmost alive per column | Primary target (100%) + left/right neighbors in same row (70% splash) |
| Spear | Frontmost alive per column | 2 deep in that column (front + one behind) |
| Gun | Frontmost alive per column | Entire column (shoots through all ranks) |
| Cannon | Any cell with alive merc | Cross pattern (+) centered on target |
| Staff | Any cell with alive merc | Single target |
| Bow | Any cell with alive merc | Single target |

**Two-step attack UX:** Select Attack → orange highlights show valid targets → hover a target → red highlights show the cells that will actually be hit → click to confirm.

**Target types:** Not all actions target the enemy grid. Each action/ability specifies a target type:
- **ENEMY** — attack, offensive abilities → highlights on enemy grid
- **ALLY** — heal, buff, swap → highlights on player's own grid
- **SELF** — guard, self-buff → no grid highlight needed

### 2.6 Merc Stats

Complex stat system:

- **HP** — health pool
- **ATK** — base attack damage
- **DEF** — damage reduction
- **SPD** — AP regeneration rate per turn
- **CRIT** — critical hit chance
- **CRIT DMG** — critical hit damage multiplier
- **ACC** — accuracy / hit chance
- **EVA** — evasion chance
- **Resistances** — elemental or damage type resistances (TBD)

Stats vary widely across the 30+ merc roster to create distinct archetypes (glass cannon, tank, support, etc.).

### 2.7 Main Character

- Occupies a grid slot like a regular merc.
- Has enhanced stats and/or a unique passive aura that benefits nearby mercs.
- Killing the enemy main character wins the game.
- Player chooses which of their 9 drafted mercs is the main character during the placement phase.

### 2.8 Turn Order & First-Turn Balance

- Alternating turns: P1 activates all their available mercs, then P2.
- Who goes first is influenced by the pick/ban phase, with compensation for the second player (e.g., extra starting AP, a small stat buff, or an additional ban). Exact balancing TBD.

---

## 3. Technical Architecture

### 3.1 Engine Recommendation: Godot 4

**Why Godot:**
- Free and open source — $0 cost, no revenue share
- GDScript is approachable from a JS/TS background (Python-like syntax)
- First-class export to iOS, Android, Windows, macOS, Linux, and **Web (HTML5)**
- Lightweight — ideal for a 2D grid-based game
- Strong AI tooling support for code generation
- Active community and growing ecosystem

**Why not alternatives:**
- Unity: overkill for 2D grid game, licensing concerns, heavier toolchain
- Flutter/Flame: weaker game-specific tooling (no built-in physics, scene system, etc.)
- Web-only (React/Phaser): limits mobile app store presence

### 3.2 Cross-Platform Strategy

**Recommendation: Mobile (iOS/Android) + Web (PC)**

| Platform | Distribution | Notes |
|---|---|---|
| iOS | App Store | Godot exports to iOS natively |
| Android | Google Play | Godot exports to Android natively |
| PC (Web) | Browser (itch.io, custom domain) | Godot HTML5 export — zero install, instant play |
| PC (Steam) | **Post-launch** | Only if player base justifies it ($100 fee, Steamworks integration) |

**Why web for PC instead of Steam at launch:**
- $0 cost (Steam costs $100 per app)
- No additional build/distribution pipeline to maintain
- Players can play instantly — no download
- Godot's HTML5 export handles this natively
- Cross-play is simple: all clients talk to the same Firebase backend
- Can add Steam later if demand warrants it

### 3.3 Backend: Firebase

| Service | Use |
|---|---|
| **Firebase Auth** | Player accounts (Google Sign-In, Apple Sign-In, email) |
| **Cloud Firestore** | Match state, player profiles, merc roster data, ranked ratings |
| **Cloud Functions** | Server-side move validation, anti-cheat, matchmaking logic, turn timer enforcement |
| **Firebase Realtime DB** | Live match updates (lower latency than Firestore for real-time state) |
| **Firebase Analytics** | Player behavior, match data, balance insights |
| **Firebase Remote Config** | Balance tuning without app updates (stat changes, AP values) |

**Match flow (technical):**
1. Player queues → Cloud Function pairs players by ELO.
2. Match document created in Firestore with initial state.
3. Both clients listen to match document for updates.
4. On each action, client sends move → Cloud Function validates → updates match state.
5. Turn timer enforced server-side (Cloud Function auto-ends turn on timeout).
6. Match result written, ELO updated.

**Anti-cheat:** All game logic validation happens server-side in Cloud Functions. Clients are "dumb" — they send intentions, server validates and resolves.

### 3.4 Networking Model

- **Authoritative server** (Cloud Functions) — clients never trust each other.
- **Optimistic client updates** — show the action immediately, roll back if server rejects.
- **Reconnection handling** — client can rejoin by re-reading match state from Firestore. Turn timer pauses briefly on disconnect (configurable).
- Cross-platform play works automatically since all platforms hit the same backend.

---

## 4. Monetization

### 4.1 Principles
- **Zero pay-to-win.** All mercs available to all players. No stat boosts for money.
- Purely cosmetic monetization.
- Ranked play is always on equal footing.

### 4.2 Revenue Streams

| Stream | Details |
|---|---|
| **Battle Pass** | Seasonal (e.g., 8-week seasons). Free track + premium track. Rewards: skins, grid themes, emotes, profile items. |
| **Merc Skins** | Alternate visual appearances for mercenaries. Direct purchase or earned via battle pass. |
| **Grid/Board Themes** | Custom grid visuals, backgrounds, particle effects. |
| **Emotes** | In-match emotes/reactions. |
| **Profile Cosmetics** | Avatars, borders, titles, ranked badges. |

### 4.3 Pricing (Indicative)
- Battle Pass: ~$5-10/season
- Individual skins: ~$1-5 depending on rarity
- Grid themes: ~$2-5
- Emote packs: ~$1-3

### 4.4 Implementation
- iOS: StoreKit 2 (Apple IAP)
- Android: Google Play Billing Library
- Web: Stripe or similar (if selling directly — avoids 30% platform cut)
- Firebase stores purchase records and unlocks

---

## 5. Art Direction

**Undecided — two directions being considered:**

1. **Atlantica Online-inspired:** Semi-realistic, detailed character art, fantasy/historical aesthetic. Higher art cost (more complex assets), but visually striking.
2. **Stylized/Abstract:** Could go cartoony, chibi, or even humorous (e.g., "Squirrel Wars"). Lower art cost, more accessible, easier to produce at scale for 30+ mercs.

**Recommendation for solo + $0 budget:**
- Start with **placeholder/programmer art** during prototyping.
- Use AI art generation tools for concept art and potentially production assets.
- The abstract/minimal aesthetic is more achievable solo, but either direction can work with AI tooling.
- Art style will influence the game's name and branding — decide this before investing in assets.

---

## 6. Development Phases

### Phase 1: Prototype — Core Loop (Weeks 1-8)

**Goal:** Prove the game is fun with local play.

- [x] Set up Godot 4 project
- [x] Implement 3x3 grid rendering and cell selection
- [x] Build merc data model (stats, weapon type, abilities)
- [x] Implement AP system (per-merc pools, regen, randomized speed range)
- [x] Implement action system (scaling 1-5 actions, random selection from eligible pool)
- [x] Implement weapon targeting patterns (sword, spear, gun, cannon, staff, bow)
- [x] Implement combat resolution (basic ATK vs DEF — CRIT/EVA/ACC to be added)
- [x] Implement Guard and Swap common abilities
- [x] Implement main character (visual indicator, win condition — enhancement TBD)
- [x] Build turn flow (alternating turns, turn timer)
- [x] Create 6-8 test mercs with distinct archetypes
- [x] Local hotseat 2-player mode for playtesting
- [ ] **Playtest heavily — is the core loop fun?**

### Phase 1.5: Merc Design & Placeholder Art

**Goal:** Flesh out the roster with distinct mercs, placeholder icons, and balanced stats. This feeds into both playtesting and the draft phase.

- [x] Create placeholder merc icons (64x64 stick figure PNGs via Pillow)
- [x] Add icon display to grid cells
- [x] Add icon support to MercData resource
- [x] Design and balance 18 mercs with distinct stats and weapon types (1-5 scoring system)
- [x] Refactor merc definitions from inline code to individual `.tres` resource files (`data/mercs/`)
- [x] Implement grid-state-aware targeting (frontmost alive resolution)
- [x] Implement hover hit preview (orange valid targets → red hit zone on hover)
- [x] Clarify and implement axe weapon pattern (frontmost + 70% splash to row neighbors)
- [ ] Design unique abilities for all 18 mercs (3/18 done — Swordsman, Axeman, Shielder)
- [ ] Implement ability system in code (Resource type, cooldowns, buffs/debuffs)
- [ ] Implement Axe splash damage (70% to neighbors, requires damage multiplier per hit cell)
- [ ] Playtest with full roster and refined stats

### Phase 2: Draft System (Weeks 9-12)

**Goal:** Pick/ban phase works and feels strategic.

- [ ] Design draft format (number of bans/picks, order)
- [ ] Implement pick/ban UI
- [ ] Implement grid placement phase with timer
- [ ] Expand roster to 15+ mercs (enough for meaningful drafting)
- [ ] Test draft balance — are there dominant strategies? Is every merc pickable?

### Phase 3: Online Multiplayer (Weeks 13-20)

**Goal:** Two players can play a full match online.

- [ ] Set up Firebase project (Auth, Firestore, Cloud Functions)
- [ ] Implement player accounts and authentication
- [ ] Build matchmaking queue (Cloud Function)
- [ ] Implement match state sync via Firestore/Realtime DB
- [ ] Server-side move validation in Cloud Functions
- [ ] Server-side turn timer enforcement
- [ ] Reconnection handling
- [ ] Basic anti-cheat (server validates all moves)
- [ ] Stress test with multiple concurrent matches

### Phase 4: Ranked System (Weeks 21-24)

**Goal:** Competitive ladder is functional.

- [ ] Implement ELO or Glicko-2 rating system
- [ ] Leaderboard (top players, your rank)
- [ ] Seasonal resets (configurable via Remote Config)
- [ ] Match history (viewable past games)
- [ ] First-turn balancing mechanism (compensation for P2)

### Phase 5: Content & Polish (Weeks 25-36)

**Goal:** Game feels complete and has enough content for launch.

- [ ] Expand roster to 30+ mercs with unique abilities
- [ ] Balance pass — stat tuning, ability adjustments
- [ ] Tutorial / onboarding (teaches positioning, AP, weapon types, guard/swap)
- [ ] Practice mode (vs AI or sandbox)
- [ ] Art pass — merc visuals, grid themes, UI polish
- [ ] Sound effects and music
- [ ] Settings (audio, controls, accessibility)
- [ ] Finalize art direction and game name

### Phase 6: Monetization & Store Integration (Weeks 37-42)

**Goal:** IAP works, battle pass is ready.

- [ ] Implement cosmetics system (skins, themes, emotes, profile items)
- [ ] Implement battle pass (free + premium tracks, XP progression)
- [ ] iOS: StoreKit 2 integration
- [ ] Android: Google Play Billing integration
- [ ] Web: Stripe or equivalent (if applicable)
- [ ] Test purchase flows end-to-end on all platforms

### Phase 7: Launch Prep (Weeks 43-48)

**Goal:** Ready to ship.

- [ ] Apple Developer Account ($99/year)
- [ ] Google Play Developer Account ($25 one-time)
- [ ] App Store metadata, screenshots, preview video
- [ ] Privacy policy, terms of service
- [ ] TestFlight beta (iOS) + Google Play internal testing (Android)
- [ ] Web version deployed (itch.io or custom domain)
- [ ] Cross-platform play verified (mobile vs web)
- [ ] Soft launch in a small region or limited beta
- [ ] Performance testing on low-end devices
- [ ] Bug fixes from beta feedback

### Phase 8: Launch & Post-Launch

**Goal:** Ship it, then iterate.

- [ ] Full release on iOS, Android, and Web
- [ ] Monitor analytics (Firebase Analytics)
- [ ] Hotfix critical bugs
- [ ] First battle pass season goes live
- [ ] Community channels (Discord server)
- [ ] Ongoing: new mercs, balance patches, seasonal content
- [ ] Future: PvE content, Steam release (if demand warrants)

---

## 7. Costs Summary

| Item | Cost | When |
|---|---|---|
| Godot Engine | Free | Day 1 |
| Firebase (free tier) | Free | Phase 3 |
| Apple Developer Account | $99/year | Phase 7 |
| Google Play Developer Account | $25 (one-time) | Phase 7 |
| Domain (optional, for web version) | ~$12/year | Phase 7 |
| Steam (optional, post-launch) | $100 (one-time) | Post-launch |
| **Total to launch** | **~$125-136** | |

Firebase free tier limits (Spark plan):
- 50K reads/day, 20K writes/day, 20K deletes/day
- 1GB storage, 10GB bandwidth/month
- Cloud Functions: 2M invocations/month
- Sufficient for early launch; upgrade to Blaze (pay-as-you-go) when needed.

---

## 8. Risks & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Balancing 30+ mercs solo | High | Launch with fewer mercs (15-20), expand post-launch. Use data analytics to identify imbalances. |
| Firebase free tier limits | Medium | Monitor usage. Blaze plan is pay-as-you-go with no minimum. Optimize read/write patterns. |
| Art production at $0 budget | High | Lean on AI art tools. Start with a simpler art style. Consider commissioning key assets later if revenue supports it. |
| Cross-platform input differences | Low | Grid-based game is naturally touch and mouse friendly. Minimal adaptation needed. |
| Matchmaking with small player base | High | Widen ELO range over time if no match found. Add AI opponents as fallback. Cross-platform helps pool players. |
| Godot mobile performance | Low | 2D grid game is lightweight. Test early on low-end devices. |
| Scope creep with complex stat system | Medium | Lock stat design early. Resist adding more stats post-prototype. |

---

## 9. Key Design Decisions Still TBD

- [ ] Exact pick/ban format (number of bans, pick order, timer per pick)
- [ ] First-turn compensation mechanism
- [ ] Weapon targeting specifics (can you choose target within the pattern?)
- [ ] Merc ability design for 30+ characters
- [ ] Art direction (Atlantica-style vs stylized/abstract)
- [ ] Game name
- [ ] Exact stat formulas (damage calc, crit formula, evasion check)
- [ ] Main character passive aura design
- [ ] How "force control" abilities work exactly
- [ ] Whether dead cells are truly locked or if abilities can interact with them

---

## 10. Future Considerations

### 10.1 Camera & Player POV

Each player's point of view is from **behind their own 3×3 grid**, looking across the battlefield toward the enemy. The player's back row (magic/support) is closest to the camera, and the front row (melee) is furthest away, facing the enemy.

From a given player's perspective, the battlefield depth reads:

```
[Camera / Player]
  Your back row    (magic/support — closest to you)
  Your mid row     (agi — archers, gunners)
  Your front row   (melee — swords, shields)
  ─── battlefield gap ───
  Enemy front row  (melee — closest to you across the gap)
  Enemy mid row    (agi)
  Enemy back row   (magic/support — furthest from you)
```

In the eventual 3D version, the camera sits behind the player's grid with the ability to rotate to a desired viewing angle. This perspective reinforces the tactical feel — you're a commander looking over your army at the enemy formation.

For the current 2D hotseat prototype, this is approximated by the side-by-side mirrored grids (P1 front row adjacent to P2 front row in the center).

---

## 11. Merc Ability Designs

Abilities are unique per merc (in addition to the common Guard and Swap). Each ability has: AP cost, target type, effect, cooldown, and whether it starts on cooldown.

### Stat Score Mapping (1-5 → actual values)

Used when scoring merc stats. All 18 mercs have been scored and saved to `.tres` files.

| Stat | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| HP | 60 | 80 | 100 | 130 | 160 |
| ATK | 5 | 10 | 15 | 20 | 25 |
| DEF | 2 | 5 | 8 | 12 | 16 |
| SPD | 40-55 | 55-70 | 65-85 | 80-100 | 90-110 |
| CRIT | 0.03 | 0.05 | 0.10 | 0.15 | 0.20 |
| CRIT DMG | 1.25 | 1.5 | 1.75 | 2.0 | 2.5 |
| ACC | 0.80 | 0.85 | 0.90 | 0.95 | 1.0 |
| EVA | 0.02 | 0.05 | 0.10 | 0.15 | 0.20 |
| Magic | 0.0 | 0.25 | 0.5 | 0.75 | 1.0 |

### Completed Abilities (3/18)

**1. Swordsman — Sharpen Blades**
- AP Cost: 75 | Target: Self | Cooldown: 3 turns | Starts on CD: No
- Effect: Next 3 basic attacks deal x2 damage (final multiplier, applied after crit/def/everything)
- Duration: No turn limit — lasts until all 3 charges are consumed

**2. Axeman — Arctic Swing**
- AP Cost: 150 | Target: Frontmost alive in a column | Cooldown: 2 turns | Starts on CD: Yes
- Hit Pattern: Entire row of the primary target (all 3 cells)
- Damage: Minimal (flat 5, ignores ATK scaling)
- Debuff: Freeze (1 enemy turn) — frozen mercs skip their action if selected. AP still gained normally.
- Note: 50% uptime ceiling by design

**3. Shielder — Under My Shield**
- AP Cost: 150 | Target: Any ally (not self), single target | Cooldown: 3 turns | Starts on CD: No
- Effect: For 2 turns, Shielder absorbs 75% of damage dealt to the target. Target only takes 25%.
- Redirected damage uses Shielder's DEF
- Ends early if Shielder dies

### Remaining (15)

4. Spearman — TBD
5. Bowman — TBD
6. Gunslinger — TBD
7. Staffmage — TBD
8. Cannoneer — TBD
9. Healer — TBD
10. Knight — TBD
11. Berserker — TBD
12. Paladin — TBD
13. Pirate — TBD
14. Chariot — TBD
15. Poseidon — TBD
16. Priest — TBD
17. Puppet — TBD
18. Heretic — TBD

---

## 12. Handoff Notes (for continuing work)

### Current State (as of 2026-04-15)

**Phase:** 1.5 — Merc Design & Placeholder Art

### What's done

- Core gameplay loop fully playable in local hotseat mode (2 players, same screen)
- 18 mercs on board (9 per player), each with individual `.tres` resource files in `data/mercs/`
- All mercs have placeholder 64x64 stick figure icons in `assets/icons/`
- All 18 mercs scored with 1-5 stat system and actual values written to `.tres` files (see mapping table in section 11)
- Grid-state-aware targeting implemented (frontmost alive resolution per weapon type)
- Two-step attack UX: orange highlights show valid targets → hover a target → red highlights show hit zone → click to confirm
- Mirrored grid rendering (P2 grid flipped so front rows face each other)

### What's in progress

- **Designing unique abilities** for each merc (3/18 complete: Swordsman, Axeman, Shielder)
- **Next merc to design: Spearman (#4 in the list)**
- Full ability specs are in section 11 above

**Ability design process:** Go through the merc list in order (section 11). For each merc, prompt the user: "Next — [Merc Name]. What's your skill idea?" The user will describe a concept — sometimes with specific numbers (AP cost, cooldown), sometimes just a vibe or mechanic. Claude fleshes out the remaining details (AP cost, target type, cooldown, whether it starts on CD, damage values) and presents a clean spec. User confirms or asks for adjustments. Once confirmed, move to the next merc. Record the final spec in section 11.

### Combat resolution — what's implemented vs NOT

**Implemented:**
- Damage = ATK - DEF (minimum 1 damage always dealt)
- Guard: halves incoming damage, prevents crits
- Basic attack costs 100 AP, guard costs 50 AP, swap costs 50 AP (both mercs)

**NOT yet implemented (stats exist in MercData but are not wired in):**
- CRIT — critical hit chance (random roll against `crit`, multiplies damage by `crit_dmg`)
- ACC — accuracy (random roll, miss deals 0 damage)
- EVA — evasion (random roll, dodge negates the hit)
- Magic — magic damage/resistance multiplier (no magic abilities exist yet)
- Axe splash damage — currently all hit cells deal 100%. Axe should deal 100% to primary target and 70% to left/right neighbors in the same row. `get_hit_cells()` returns positions only, no damage multipliers yet.

### Common abilities (every merc has these)

- **Guard:** Costs 50 AP, costs the player 1 action. Merc takes 50% less damage and is immune to crits until their next activation (guard clears when `on_activated()` is called).
- **Swap:** Costs 50 AP to **both** mercs involved. Can swap with **any alive friendly unit** on the grid (not just adjacent). Cannot swap with dead/empty cells. Does NOT cost the player an action — but the merc is still considered "used" by TurnManager.

### AP and activation system

- Each merc has an individual AP pool. AP regenerates each turn by a random amount in `[spd_min, spd_max]`.
- A merc needs **≥100 AP to be eligible** for activation. This is a threshold check, not a cost — being selected doesn't spend 100 AP.
- Each action (attack, guard, swap, ability) has its own AP cost deducted separately.
- AP can go negative after spending. Merc simply won't be eligible again until they regenerate back above 100.
- Actions per turn scale: turn 1 = 1 action, turn 2 = 2, ..., up to 5 max.
- Available mercs are **randomly selected** from the eligible pool (shuffled, sliced to action count). This is intentional controlled randomness.

### Turn timer

- Turn 1 and 2: 15 seconds each. Turn 3+: 30 seconds.
- Counts down every second. Auto-ends turn when it hits 0.
- Timer turns red at ≤5 seconds remaining.

### Grid layout

```
         Col 0    Col 1    Col 2
       ┌────────┬────────┬────────┐
Back   │ row 0  │ row 0  │ row 0  │  ← magic/support (furthest from enemy)
       ├────────┼────────┼────────┤
Mid    │ row 1  │ row 1  │ row 1  │  ← agi (archers, gunners)
       ├────────┼────────┼────────┤
Front  │ row 2  │ row 2  │ row 2  │  ← melee (closest to enemy)
       └────────┴────────┴────────┘
```

P2's grid is rendered with `mirrored = true` (front row at top), so front rows face each other in the center of the screen.

### Board layout (mercs on grid)

**Player 1 (left grid):**
| Row | Col 0 | Col 1 | Col 2 |
|---|---|---|---|
| Back (0) | Staffmage | Cannoneer | Healer |
| Mid (1) | Spearman | Bowman | Gunslinger |
| Front (2) | Swordsman (MC) | Axeman | Shielder |

**Player 2 (right grid, mirrored):**
| Row | Col 0 | Col 1 | Col 2 |
|---|---|---|---|
| Back (0) | Priest | Puppet | Heretic |
| Mid (1) | Pirate | Chariot | Poseidon |
| Front (2) | Knight (MC) | Berserker | Paladin |

### Benched mercs (have icons but are not on the board)

5 mercs have placeholder icons in `assets/icons/` but no `.tres` files and are not placed on either grid:
- `sorcerer.png`, `archer.png`, `dualblade.png`, `formation-breaker.png`, `tank-buster.png`
- Also `chariot-supporter.png` is the icon file for the merc called "Chariot" in-game
- `pitch-black-exorcist.png` and `sniper.png` and `time-traveller.png` have icons but no `.tres` files — they are reserved for future roster expansion

### What needs implementation after ability design

- **Ability system in code:** New AbilityData Resource type, cooldown tracking per merc, buff/debuff state tracking on Merc
- **Axe splash damage:** `get_hit_cells()` currently returns only positions. Needs to return damage multipliers per cell (100% primary, 70% splash). Damage pipeline in `main.gd:_on_target_grid_clicked()` must apply per-cell multipliers.
- **Freeze debuff (Axeman):** `TurnManager._select_available_mercs()` must exclude frozen mercs, or if they're selected, the action is wasted (lost). Freeze lasts 1 enemy turn. AP still gained normally.
- **Sharpen Blades buff (Swordsman):** `merc.gd:take_damage()` pipeline needs a final multiplier hook. Charge-based (3 attacks), not turn-based.
- **Under My Shield (Shielder):** Damage redirect system — when a shielded merc takes damage, 75% is redirected to Shielder (using Shielder's DEF). Ends early if Shielder dies. 2 turn duration.
- **Wire in CRIT/EVA/ACC** into combat resolution (currently just ATK - DEF)

### Key files

| File | Purpose |
|---|---|
| `scenes/main.gd` | Game controller — turn flow, action handling, grid click routing, UI |
| `scenes/main.tscn` | Scene tree — contains PlayerGrid and EnemyGrid nodes |
| `scenes/grid.gd` | 3x3 grid — cell management, targeting resolution, highlights |
| `scenes/cell.gd` | Individual cell — state (selected, targeted, hit preview, swap target), merc slot |
| `scenes/cell.tscn` | Cell scene — Area2D with ColorRect and CollisionShape2D |
| `scenes/merc.gd` | Runtime merc — HP, AP, guard, damage, label rendering |
| `scenes/turn_manager.gd` | Turn flow — AP distribution, random merc selection, action counting |
| `data/merc_data.gd` | MercData Resource class — blueprint/template for merc stats |
| `data/targeting.gd` | Static targeting patterns — `get_valid_targets()` (being superseded by grid) and `get_hit_cells()` (still authoritative) |
| `data/mercs/*.tres` | 18 individual merc resource files with stats and icon references |

### `.tres` file format (for creating new mercs)

```
[gd_resource type="Resource" script_class="MercData" format=3]

[ext_resource type="Script" path="res://data/merc_data.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://assets/icons/MERC_NAME.png" id="2_icon"]

[resource]
script = ExtResource("1_script")
merc_name = "Display Name"
icon = ExtResource("2_icon")
weapon_type = 0
max_hp = 100
atk = 10
def = 5
spd_min = 65
spd_max = 85
crit = 0.05
crit_dmg = 1.5
acc = 0.90
eva = 0.05
magic = 0.0
```

`weapon_type` enum values: 0=SWORD, 1=SPEAR, 2=GUN, 3=CANNON, 4=STAFF, 5=BOW, 6=AXE

### User working style

- Scott is hands-on with game design decisions — always confirm mechanics with him, don't assume
- He prefers terse responses, no trailing summaries
- For stat/ability design: present a clean spec, he'll say "good" to confirm or give specific adjustments
- He sometimes gives precise numbers upfront (AP cost, cooldown), sometimes just describes the vibe — fill in the gaps and propose
- Use ASCII art diagrams when explaining grid mechanics — he finds row/col number references hard to parse
- Icons were generated with Python/Pillow (64x64 RGBA stick figures). If more are needed, check existing icons for style reference

---

## 13. References & Inspiration

- **Atlantica Online** — art direction reference, mercenary grid combat
- **Advance Wars** — grid tactics, unit variety
- **MOBA pick/ban systems** (League of Legends, Dota 2) — draft phase inspiration
- **Auto Chess / Teamfight Tactics** — grid positioning, synergy-based team building
- **Chess** — abstract competitive purity, ELO system
