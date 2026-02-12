🟥 Product Requirements Document (PRD): Ippo Engine-Building Progression System
A unified progression, reward, pet, and reputation engine built on top of the IEI and Chase Systems.

1. PURPOSE & CONTEXT
1.1 What This PRD Defines
This document defines the entire game layer of Ippo:
The player’s long-term progression


Reputation Points (RP) as the core identity metric


Pets, pet care, pet mood, and pet progression


Loot boxes, shop, currencies, and reward structure


Player upgrades and engine-building systems


How all systems interact with the fixed IEI + Chase systems


How players rank up and maintain runner identity


This PRD does not define:
Exact reward values


Exact pet abilities


Exact upgrade tree node names


Exact item lists


Final tuning
 These will be established later.


1.2 Relationship to IEI + Chase
The IEI System and Chase System drive:
When encounters happen


How chases are structured


Chase difficulty


Chase rarity


Safety, fairness, effort personalization


This PRD defines what happens after the chase ends.
The game layer cannot modify:
Encounter frequency


Pity timer


Chase segments


Grace/tolerance rules


Recovery structure


Safety logic


These are fixed constraints.
 The game layer modifies rewards and progression only.

2. CORE GAME LOOP
High-Level Loop
Run


Chases occur based on IEI & other related systems


Encounter + Chase


The player succeeds/fails based on effort/responses to haptic feedback.


Receive Rewards


Loot boxes, soft currency, pet shards, resources, RP.


Between Runs


Feed pets, open boxes, upgrade pets/player, shop, equip items.


Engine Strengthens


Higher RP output and better rewards.


Rank Up


Gains new identity titles and unlocks new systems.


Repeat indefinitely.


The loop is intended to feel:
Addictive in a healthy way


Predictably rewarding


Personal to player identity


Simple to interact with


Deep enough to support long-term engagement



3. REPUTATION SYSTEM (RP)
The central metric and identity axis of Ippo.
3.1 Purpose of RP
RP = Reputation Points, the universal measure of:
Player identity as a runner


Progression


Mastery


Competitive standing


 RP is not a currency.
 RP is not spent.
 RP is a permanent progression metric.
3.2 How RP Is Earned
RP is earned indirectly through multiple sources:
Session RP from running


Chase performance


Pet contributions


Pet mood


Player upgrades


Streak activity


Temporary RP-boosting items


Small RP bonuses from loot boxes


Pet care bonuses (feeding / interacting with pets)


RP cannot be earned through:
Buying items in shop


Grinding non-run actions


Any direct real-world purchase


3.3 Session RP Formula (High-Level)
Session RP =
 Personalized Run Performance × RP Multipliers + Pet RP Contributions + Bonus RP
Where:
Performance is based on relative effort & chase success, not speed.


Multipliers come from player upgrades, pets, streaks, etc.


Pet RP is based on pet level, mood, and abilities.


3.4 Rank Structure
RP determines rank.
 Each rank:
Has a name/title that reinforces identity (“Elite”, “Resolute”, etc.).


Has a broad RP range.


Has rank floors which protect players from falling below the rank threshold for a period.


Unlocks new upgrade tiers, items, or pets.


Grants small permanent perks (e.g., slight RP multiplier).


3.5 RP Decay
To maintain tension:
After X days of inactivity, soft RP decay begins.


Decay is slow, capped, and cannot break rank floors.


Pet care actions (feeding pets) also help slow or prevent decay.


This prevents complete disengagement without punishing normal life events.

4. RUN → ENCOUNTER → REWARD PIPELINE
4.1 Run
Player starts a run.


IEI drives zone detection and effort responsiveness.


4.2 Encounter
Triggered strictly using the Chase System’s VRR + pity timer model.


Untouched by any game-layer modifiers.


4.3 Chase
Player increases/decreases/maintains effort.


Performance tracked via IEI_fast and IEI_stable.


Segment success → chase success rate.


4.4 Reward Distribution
Chase rarity + performance define the reward package, consisting of:
Loot box (rarity = chase rarity)


Soft currency


Pet shards


Pet XP


Pet RP


Player RP


Temporary boosts


Upgrade resources


Game layer can modify reward contents, not chase logic.

5. LOOT BOX SYSTEM
5.1 Loot Box Rarities
Common


Uncommon


Rare


Epic


Legendary


Reward generosity scales with rarity.
5.2 Potential Loot Box Contents
Soft Currency


Pet Shards


Pet Upgrade Resources


Player Upgrade Resources


Full Pet (rare)


Temporary Boost Items


Rarity Bump Tokens


Small RP Bonus


5.3 Design Principles
Loot boxes never contain RP in large quantities.


Loot boxes never modify encounter frequency or chase logic.


Drops maintain excitement without creating gambling-like patterns.



6. PET SYSTEM
6.1 Pet Roles & Classes
Each pet has:
Rarity


Level


Mood


Class (system focus)


Abilities (1–2 passives)


Synergy tags


Shard requirements for leveling


6.2 Pet Classes (High-Level)
Reward Pets – Increase loot yield or improve contents


RP Pets – Increase RP gain (pet or player RP)


Shard/Progression Pets – Improve shard yields or evolution paths


Item Pets – Increase drop chances for items/charms


Synergy Pets – Combo bonuses with other pets


6.3 Pet Mood (1–10 Scale)
+1 when fed each day


+1 for each run with the pet equipped


−1 for missed feeding days


−1 if no run for 3 days


Clamped between 1 and 10


Mood affects:
Pet XP gain


Ability growth


Pet RP generation


Slight influence on loot outcomes


6.4 Pet Care Loop
Between runs, the player:
Selects a pet


Enters a simple feeding interaction


Maintains mood → increases pet performance


Low mood never disables pets; it simply makes them less effective.

7. SHOP SYSTEM
7.1 Purpose
The shop smooths randomness and gives players long-term goals.
7.2 Shop Currency
Soft currency earned from:
Runs


Chases


Loot boxes


RP rank rewards


7.3 Shop Stock
Players can buy:
Pet shards


Upgrade resources


Temporary items/charms


Lower-tier loot boxes


Forbidden in shop:
RP


Pets that modify encounter/chase logic


Direct sale of top-rarity pets


7.4 Optional Shop Upgrades
Player upgrades may:
Expand shop stock


Provide mild discounts


Improve odds of seeing relevant items



8. PLAYER UPGRADE SYSTEM
8.1 Categories of Upgrades
A. Loot Engine Upgrades
More items per box


Higher shard yield


Slightly better soft currency yield


Increased chance for temporary items/charms


Higher chance for full pet drop (capped)


B. RP Engine Upgrades
RP multiplier (overall)


RP multiplier (pets)


RP bonus per run completion


RP bonus for streaks


RP scaling for player level milestones


C. Pet Engine Upgrades
More pet equip slots (1 → 2 → 3)


Global pet XP multiplier


Higher pet mood effect scaling


Higher synergy bonuses


Higher pet level caps


Bonus shards for pets you own


D. Shop / Economy Upgrades
Mild discounts


More stock slots


Better chance of discounted shard bundles


More frequent refreshes


E. Quality of Life Upgrades
Additional loadouts


Pet sorting/filtering enhancements


Cosmetic badges/titles



9. TEMPORARY BOOSTS
9.1 Rules
Temporary boosts never affect:
Encounter frequency


Encounter rarity distribution


Pity timers


Chase segment structure


IEI system logic


Temporary boosts may affect:
RP multiplier for next run


Loot box rarity for next N boxes


Shard or soft currency yield


Pet XP gain


Item drop rates


Boosts create run variety without destabilizing core pacing.

10. PROGRESSION + ECONOMY STRUCTURE
10.1 Player Level
Levels unlock:
New upgrade tiers


Shop expansions


Small RP multipliers


New pet families (later)


10.2 Rank Gating
Ranks unlock:
Higher pet rarities


Better shop items


New charm/item types


Power ceilings for upgrades


10.3 Long-Term Economy Stability
Shards and upgrade resources are main bottlenecks.


RP is the main high-level progression.


Soft currency provides direction but not major power.



11. ALL ENGINE VARIABLES
11.1 Immutable (Fixed by Chase/IEI PRDs)
Encounter frequency


Encounter rarity baseline


Pity timer logic


Chase segment structure


Segment duration rules


Recovery structure


IEI zone thresholds


Safety logic


11.2 Player/Engine Variables
RP Variables
Session RP


Pet RP contributions


RP multipliers


RP bonuses


RP streak bonuses


RP decay


Rank floors


Rank multipliers


Seasonal multipliers


Pet Variables
Pet rarity


Level


XP curve


Mood


Mood effects


Abilities


Shard requirements


Synergy categories


Loot Variables
Loot box rarity


Soft currency yield


Item quantity


Shard yields


Resource yields


Item/boost probabilities


Rarity bump tokens


Player Upgrade Variables
RP multipliers


Loot multipliers


Shop modifiers


Pet XP multipliers


Pet equip slots


Mood scaling


Max level caps


Shop Variables
Inventory rotation


Soft currency costs


Discounts


Purchase limits


Temporary Boost Variables
Duration


Strength


Type


Stacking rules



12. SYSTEM INTERACTIONS (Summary)
RUN
│
│ (IEI → Chase)
▼
ENCOUNTER
│
▼
CHASE
│
▼
REWARDS
• Loot boxes
• Soft currency
• Pet shards
• Resources
• Pet XP
• RP
• Boosts
│
▼
META LAYER
• Feed pets (mood)
• Open boxes
• Buy items
• Upgrade pets
• Upgrade player
• Equip items
│
▼
ENGINE IMPROVES
│
▼
MORE RP
│
▼
RANK UP
(New identity titles, unlocks, bonuses)
│
└─► LOOP REPEATS


13. SYSTEMS THAT UNLOCK OVER TIME
These systems unlock gradually to prevent overload:
Pet slots (1 at start → more later)


Shop categories


Higher loot box rarities


Higher pet rarities


New upgrade tiers


Seasonal systems


Special charm/item types


Advanced synergy mechanics


Exact progression order will be detailed later.

14. DESIGN PRINCIPLES (Guiding Rules)
Fairness: RP progression scales to effort and consistency, not raw fitness.


Identity: Ranks should feel emotionally meaningful.


Safety: No mechanics push excessive exercise.


Non-exploitative: No gambling-like structures.


Run-Centric: Most value comes from running, not sitting in menus.


Engine-Building Depth: Pets + items + upgrades multiply long-term progression.


Simplicity: Only a few currencies, clear loops, minimal confusion.


Stability: Chase system pacing remains sacred and untouched.



15. NEXT STEPS (For Future Iterations)
We will later add:
RP rank ladder naming + structure


Loot box reward tables (per rarity)


Pet class → actual ability lists


Player upgrade tree (tiers + branches)


RP session formula (exact math)


RP decay model details


Progression gating specifics