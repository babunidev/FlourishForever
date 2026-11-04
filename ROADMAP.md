# Flourish Forever — verified baseline and roadmap

**Creative decision authority:** Babuni.dev. **Release:** 0.3.1-beta, October 22, 2026.  
**Status of this roadmap:** proposed checks and unapproved alternatives, not implementation instructions.

## What exists in current source

- Player-only **UNIT_SPELLCAST_SUCCEEDED** listener; ability configured by lowercased spell **name** and resolved from event spell ID.
- Spellbook enumeration via `C_SpellBook` or legacy spell-tab APIs; passive spells skipped when detectable.
- Configurable enabled emotes discovered from the game's `EMOTE*_TOKEN` globals, with ROAR fallback; each selected uniformly with `math.random`.
- Per-ability **0–100% chance**, **0–120 seconds cooldown** via sliders; defaults **100%** and **6s**, with only ROAR enabled.
- Rate limiting timestamp updated **only after DoEmote is selected**; failed chance / empty pool doesn't spend a cooldown.
- Separate character settings using GUID-based profiles inside account-wide `FlourishForeverStorage`; conditional adoption of `ROARitFOREVERStorage` and name-keyed profile migration.
- Movable **620×520** Blizzard-style window with enable checkbox, ability dropdown/list, selected ability editor, sliders and emote checkboxes.
- Slash aliases `/flourish`, `/flourishforever`, `/rit`, with `config`, `ui`, `status`.
- Two GitHub beta release tags with **no uploaded release assets**, a CurseForge-oriented `.pkgmeta`, and **no LICENSE**. A development-only package inventory check now exists under `tests/`; there is still no gameplay test harness or CI.

## P0 — gameplay event correctness

1. Install all three Lua files and TOC on intended **WoW: Forever** client interface 16001, and confirm `/flourish` opens without Lua errors.
2. Select one spell and verify that the client actually fires `UNIT_SPELLCAST_SUCCEEDED` with parameters the addon expects (`unit, _, spellID`); record version and event payload.
3. Distinguish successful cast from actual **target hit/effect application**. Test a cast that succeeds but misses/resists or doesn't affect its target; the current listener may still emote.
4. Test interrupts, failed casts, duplicate cast-success events, triggered/proc spells, different ranks with one name, channelled casts, spells on cooldown and abilities that cannot be selected from the spellbook.
5. Verify the passive filter and dropdown's available spell list under both new and legacy API paths. Test changed talent/spellbook lists while the window remains open via `SPELLS_CHANGED`.
6. Confirm `math.random` chance with 0%, 100% and intermediate values across repeated casts; distinguish probability from deterministic “every nth cast.”
7. Confirm cooldown **per normalized ability name**, independence of two configured spells, and zero/6/120-second intervals.
8. Specifically test **first eligible cast shortly after login**: `lastFireByAbility[key] or 0` may suppress it if `GetTime() < cooldown`. Decide whether to repair only after reproducing or designing the intended behavior.
9. Confirm cooldown timestamps reset on `/reload` and relog; the source doesn't save them. Document whether that is acceptable for play.

## P1 — saved character profiles and emote behavior

10. Test fresh character GUID binding and settings after reload, logout/login and switching characters. Confirm no selections leak across characters.
11. Test old `ROARitFOREVERStorage` migration using **backed-up SavedVariables**, including name-keyed or old name-realm-keyed entries. The old root must actually have been loaded; current TOC declaring a new root doesn't automatically load a missing old file.
12. Test character setup when `UnitGUID` is briefly unavailable; `EnsureDB` creates a fallback session table and rebinds when the GUID returns. Ensure early edits aren't lost.
13. Test no emotes checked, one enabled, several enabled and a token unsupported by `DoEmote`. Inspect actual client chat/sound/animation and behavior with other emote addons.
14. Inspect `status` printing the raw character GUID and decide whether diagnostic privacy/readability should change.
15. Test saved chance/cooldown values outside slider bounds or in nonnumeric legacy formats; source converts with `tonumber` but does not clamp on load.
16. Test duplicate spell names, spell localization changing the persisted ability key, and spell IDs changing rank/specialization.
17. Test dropdown menu templates and their optional dynamic load; `CreateUI` still assumes several globals exist after attempting to load them.

## P2 — packaging and portfolio evidence

18. Confirm CurseForge packager successfully processes `.pkgmeta`. A development change excludes portfolio assets, project docs, and tests, while retaining the manual CHANGELOG. The local inventory check is not proof of a real packaged ZIP; publication and package contents remain **unverified**.
19. Consider adding a small mocked Lua harness for spellcast matching, cooldown, chance boundaries, GUID migration and UI creation, then run it and record output.
20. Verify public GitHub beta release entries: currently v0.3.0-beta and v0.3.1-beta have **no uploaded release assets**. Do not advertise a ZIP at their release URLs.
21. Decide on an explicit repository license; **no LICENSE** was found in the inspected main tree.
22. Obtain actual client screenshots/recordings of the config panel and sample in-world emote, recording consent/character names appropriately.
23. Test UI legibility and keyboard accessibility for the ability/emote scroll frames at common display scales.

## Open creative directions requiring creator approval

Would per-ability preview help select the right flourish? Should emotes triggered close together be globally rate limited to keep chat quieter? Should cooldowns survive reload? Should the addon distinguish cast success from actual hit? Should a user be able to supply custom text or keep the native emote-only boundary? Are certain class/proc spells too noisy? These are **proposals, not implemented features or accepted decisions**.

## Related development history

Flourish Forever is the October 2026 WoW Forever expression of the action-emote idea. Unlike the earlier action-slot hooks, it responds to the player’s **reported successful spellcast** event and lets the player select spellbook abilities and existing client-native emotes in a GUI. Each new ability initially has ROAR selected, but the player may choose other available emote tokens. This is client-token selection rather than creation of arbitrary new emotes, and cast success does not prove a landed hit. See the [source-grounded expressive-addon timeline](docs/EMOTE_FAMILY_HISTORY.md) for related projects and historical boundaries.
