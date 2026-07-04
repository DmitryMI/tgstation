# Small-Crew Expedition Mode Plan

This feature is intended to be upstream-friendly by behaving as a normal space ruin with ghost spawners, while also allowing a private server to force-spawn it and use it as the primary gameplay loop.

## Core Gameplay

- Spawn a small crew on a damaged whiteship or shuttle via finite ghost-role sleepers.
- Restrict navigation at round start so the crew cannot freely reach all z-levels or the station.
- Let the crew scavenge accessible ruin z-levels for supplies and navigation progress.
- Use GPS devices as navigation data sources:
  - GPS records the z-level it originally spawned on.
  - The special navigation computer can upload a GPS and use its origin z-level as progression input.
  - Each eligible source z-level can only unlock progression once.
- Unlock whole z-levels, not individual destinations.
- After all eligible random ruin z-levels are exhausted, unlock station access as the final step.

## Implementation Steps

1. ~~Add a generic configuration path for forcing specific space ruins to spawn at round start.~~
2. ~~Add ghost-role sleeper spawners for the expedition crew and test them on existing whiteships first.~~
3. ~~Add a map helper / startup effector that converts a local whiteship navigation setup into the expedition version, so existing whiteship patterns can be reused with minimal map changes.~~
4. ~~Create a special expedition navigation computer:~~
   - ~~starts with limited z-level access~~
   - ~~accepts GPS uploads~~
   - ~~tracks which source z-levels were already consumed~~
   - ~~unlocks new eligible z-levels~~
   - ~~unlocks the station after all eligible ruin z-levels are exhausted~~
   - make the computer dis/re-assemblable with its own circuit board.
5. Create a new expedition ruin / shuttle template that can exist as a normal upstream space ruin after the sleeper flow is validated.
6. ~~Remove "Z-level" terminology from in-game messages.~~

## Constraints

- Keep changes additive and generic where possible.
- Do not modify main station gameplay or regular game mode flow.
- Allow private-server configuration to force the expedition ruin, while upstream treats it as optional content.
- Avoid softlocks:
  - exclude invalid source z-levels such as station, lavaland, transit, centcom, and reserved levels
  - ensure progression only uses eligible z-levels
  - keep unlock state on the expedition navigation computer

## Follow-Ups

- Add lore and presentation for the expedition start.
- Add more expedition-compatible shuttle or whiteship variants.
- Add more space ruins or progression flavor tailored for small crews.

## Known issues

- [TEST NEEDED] Bluespace vector resolution percentage takes GPS devices from previous levels into calculation.
- APCs are rotated wrong on whiteship rotations. But AFAIR this did not happen with custom shuttles.
- [TEST NEEDED] GPS scanning should be disabled in hyperspace
- Shuttle timing overrides are not working
- Sort Sectors by Z-level index, not alphabetically
