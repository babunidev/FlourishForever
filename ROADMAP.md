# Flourish Forever — verified baseline and roadmap

## Development branch — expanded UI testing

- **Implemented in `dev/expanded-ui-merge` only:** expanded overview/picker, three searches, custom text, individual emote cooldowns, ability toggles and data migration.
- **Offline:** run `lua tests/test_action_emotes.lua`, `lua tests/test_ui_mock.lua`, `python3 tests/check_package_layout.py`; mocked tests are not live Forever tests.
- **In-game still needed:** GUI creation, combat/secure interactions, failed casts vs custom text, character profile migration and persistence, slash aliases, UI scale, RoarForever coexistence.
- **Publication:** no release tag, CurseForge file or public version change from this branch.


**Creative decision authority:** Babuni. **Release candidate:** 0.3.2-beta (not tagged or published). **Latest GitHub Release:** 0.3.1-beta. **Latest confirmed CurseForge file:** 0.3.0-beta (October 22, 2026).  
**Status:** Current `main` contains the packaging and documentation updates; the release-preparation branch integrates the tested gameplay safety fixes. Tasks distinguish offline verification from in-game proof.

## Launch readiness — November 4, 2026

- **Confirmed by Babuni:** the original addon worked with its intended features on the Forever beta.
- **Merged to `main`:** minimal CurseForge packaging rules, static package file inventory guard, MIT license matching CurseForge, and documentation corrections.
- **Release candidate:** `release/0.3.2-beta-prep` includes the first-cast cooldown fix, bounded SavedVariables, spellbook filtering, mock Lua tests, PR-only CI and versioned changelog. These source changes originally passed GitHub and Nobara checks on draft PR #2.
- **Still unverified:** in-game behavior of the combined candidate on the launch client, the final CurseForge-generated ZIP, CurseForge auto-publishing settings and whether the next file will be tagged for the correct Forever game flavor.
- **Release gate:** no tag, public GitHub Release or CurseForge publication without explicit authorization.

## What exists in current source

- Player-only **UNIT_SPELLCAST_SUCCEEDED** listener; ability configured by lowercased spell **name** and resolved from event spell ID.
- Spellbook enumeration via `C_SpellBook` or legacy spell-tab APIs; passive spells skipped when detectable.
- Configurable enabled emotes discovered from the game's `EMOTE*_TOKEN` globals, with ROAR fallback; each selected uniformly with `math.random`.
- Per-ability **0–100% chance**, **0–120 seconds cooldown** via sliders; defaults **100%** and **6s**, with only ROAR enabled.
- Rate limiting timestamp updated **only after DoEmote is selected**; failed chance / empty pool doesn't spend a cooldown.
- Separate character settings using GUID-based profiles inside account-wide `FlourishForeverStorage`; conditional adoption of `ROARitFOREVERStorage` and name-keyed profile migration.
- Movable **620×520** Blizzard-style window with enable checkbox, ability dropdown/list, selected ability editor, sliders and emote checkboxes.
- Slash aliases `/flourish`, `/flourishforever`, `/rit`, with `config`, `ui`, `status`.
- GitHub tags v0.3.0-beta and v0.3.1-beta have no uploaded assets; CurseForge lists v0.3.0-beta. The release candidate includes lean-package `.pkgmeta`, MIT LICENSE, mock Lua regressions and two independent PR-only CI checks (Lua and packager dry-run).

## P0 — gameplay event correctness

1. Install all three Lua files and TOC on intended **WoW: Forever** client interface 16001, and confirm `/flourish` opens without Lua errors.
2. Select one spell and verify that the client actually fires `UNIT_SPELLCAST_SUCCEEDED` with parameters the addon expects (`unit, _, spellID`); record version and event payload.
3. Distinguish successful cast from actual **target hit/effect application**. Test a cast that succeeds but misses/resists or doesn't affect its target; the current listener may still emote.
4. Test interrupts, failed casts, duplicate cast-success events, triggered/proc spells, different ranks with one name, channelled casts, spells on cooldown and abilities that cannot be selected from the spellbook.
5. Verify the passive filter and dropdown's available spell list under both new and legacy API paths. Test changed talent/spellbook lists while the window remains open via `SPELLS_CHANGED`.
6. Confirm `math.random` chance with 0%, 100% and intermediate values across repeated casts; distinguish probability from deterministic “every nth cast.”
7. Confirm cooldown **per normalized ability name**, independence of two configured spells, and zero/6/120-second intervals.
8. **Integrated into release candidate; earlier Nobara mocks passed:** remove the synthetic zero timestamp for first-cast cooldown. **Remaining:** verify first and subsequent casts in-game on the release client.
9. Confirm cooldown timestamps reset on `/reload` and relog; the source doesn't save them. Document whether that is acceptable for play.

## P1 — saved character profiles and emote behavior

10. Test fresh character GUID binding and settings after reload, logout/login and switching characters. Confirm no selections leak across characters.
11. Test old `ROARitFOREVERStorage` migration using **backed-up SavedVariables**, including name-keyed or old name-realm-keyed entries. The old root must actually have been loaded; current TOC declaring a new root doesn't automatically load a missing old file.
12. Test character setup when `UnitGUID` is briefly unavailable; `EnsureDB` creates a fallback session table and rebinds when the GUID returns. Ensure early edits aren't lost.
13. Test no emotes checked, one enabled, several enabled and a token unsupported by `DoEmote`. Inspect actual client chat/sound/animation and behavior with other emote addons.
14. Inspect `status` printing the raw character GUID and decide whether diagnostic privacy/readability should change.
15. **Integrated into release candidate; earlier Nobara mocks passed:** clamp saved chance/cooldown to UI ranges and safely handle malformed settings. **Remaining:** verify with backed-up real SavedVariables on release client.
16. Test duplicate spell names, spell localization changing the persisted ability key, and spell IDs changing rank/specialization.
17. Test dropdown menu templates and their optional dynamic load; `CreateUI` still assumes several globals exist after attempting to load them.

## P2 — packaging and portfolio evidence

18. Confirm CurseForge packager successfully processes `.pkgmeta`. A development change excludes portfolio assets, project docs, and tests, while retaining the manual CHANGELOG. The local inventory check is not proof of a real packaged ZIP; publication and package contents remain **unverified**.
19. **Integrated into release candidate; previously passed GitHub Actions and Nobara:** mocked spell filtering, chance, cooldown, malformed settings and profile migration. **Not yet covered:** full UI construction or real-client behavior.
20. Verify public GitHub beta release entries: currently v0.3.0-beta and v0.3.1-beta have **no uploaded release assets**. Do not advertise a ZIP at their release URLs.
21. **Completed in development:** match the existing public CurseForge MIT declaration with the repository `LICENSE` and `license-output: LICENSE`; verify its inclusion in the next actual package.
22. Obtain actual client screenshots/recordings of the config panel and sample in-world emote, recording consent/character names appropriately.
23. Test UI legibility and keyboard accessibility for the ability/emote scroll frames at common display scales.

## Release gate — before any public tag

1. Confirm the candidate branch passes Lua regression checks, static package inventory and real BigWigs packager dry-run (uploads disabled).
2. Compare the exact approved commit against v0.3.1-beta and check the final player-facing changelog, installed ZIP and MIT notice.
3. Verify private CurseForge source settings: correct GitHub repository/branch or tagged-ref integration; **untagged commits must not auto-publish Alpha**.
4. Recheck Forever interface 16001 and supported game file version 1.60.1 against the installed launch client.
5. Record remaining client tests as unverified if not performed; do not invent gameplay proof.
6. Receive Babuni's explicit approval for the **specific public version and exact commit** before any publishing tag, GitHub Release or CurseForge upload.
7. After approval, push only the approved tag and verify the exact resulting CurseForge file and classification. No step above constitutes publication.

## Open creative directions requiring Babuni's approval

Would per-ability preview help select the right flourish? Should emotes triggered close together be globally rate limited to keep chat quieter? Should cooldowns survive reload? Should the addon distinguish cast success from actual hit? Should a user be able to supply custom text or keep the native emote-only boundary? Are certain class/proc spells too noisy? These are **proposals, not implemented features or accepted decisions**.

## Related development history

Flourish Forever is the October 2026 WoW Forever expression of the action-emote idea. Unlike the earlier action-slot hooks, it responds to the player’s **reported successful spellcast** event and lets the player select spellbook abilities and existing client-native emotes in a GUI. Each new ability initially has ROAR selected, but the player may choose other available emote tokens. This is client-token selection rather than creation of arbitrary new emotes, and cast success does not prove a landed hit. See the [source-grounded expressive-addon timeline](docs/EMOTE_FAMILY_HISTORY.md) for related projects and historical boundaries.
