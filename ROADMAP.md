# Flourish Forever — roadmap and verification status

**Creative decision authority:** Babuni · **Game:** WoW Forever 1.60.1 / Interface 16001  
**Latest confirmed Git tag:** `v0.4.3-beta` · **Current development:** per-ability trigger modes (unreleased, not tagged).  
**Development:** Expanded UI restored from Babuni's older local archive and committed to `dev/expanded-ui-merge`. Preparation occurs separately; no public release tag was created.


## Approved cooldown behavior — 7 November 2026

- [x] Babuni confirmed the preceding per-token cooldown implementation works in-game and approved a refined design: every token keeps its own duration, but the chosen emote locks the **entire ability** until that duration expires.
- [x] Implement per-ability lock state with the chosen token and duration, persisted across `/reload`, while preserving older per-token history records and character settings.
- [x] Preserve rate-limiting of actual native-emote calls returning `false`, without recording them as confirmed successful dispatches.
- [x] Update UI guidance and read-only cooldown diagnostics to show which emote is locking the ability and for how long.
- [x] GitHub mocked Lua regressions cover 3s/20s locks, other-token suppression, independent abilities, changes to slider durations, custom `/e`, false native returns, reload, 0s, and malformed saves; packaging dry run passed.
- [ ] Validate the new shared lock directly in the Forever client: 3-second giggle versus 20-second ROAR on the same ability, mixed native/custom pools, reload, and group/PvP security restrictions.
- [ ] No release tag, main merge or CurseForge upload is authorized for this specific change.

## Native emote false-return diagnosis — 7 November 2026

- [x] Use Babuni's in-game output: `accepted=0`, `rejected=9`, `lastToken=FAINT`, six-second duration and no reported chat lockdown.
- [x] Identify that the previous implementation never recorded a timestamp after native `PerformEmote` returned false, allowing repeated attempts every eligible press.
- [x] Historical implementation added separate per-token attempt and success timestamps; the 7 November design supersedes individual dispatch gating with a lock scoped to one configured ability.
- [x] Add simulated false-return-but-visible `FAINT` regression, rapid presses, reload and six-second retry expiry.
- [ ] Confirm exact release-branch CI and upload-disabled package checks after final docs.
- [ ] Live client: repeat one emote on a six-second Button press trigger; inspect `/flourish cooldowns find treasure` (or `/flourish cooldowns`) for the real configured ability and `attemptStamp`, `savedStamp`, remaining seconds.
- [ ] If a visible emote still appears without an incrementing Flourish attempt counter, check other addon or macro sources. Whether a false native API result itself produces a visible emote remains unconfirmed.
- [ ] No merge/public tag/CurseForge publication until separate approval and real-world verification.

## Reported continuing cooldown issue — 7 November 2026

- [x] Review real source after the player's six-second Mobility Button press test continued to show an emote on every press.
- [x] Confirm that timers are per selected emote token, not a global ability timer; several individually ready tokens can play on successive presses.
- [x] Refactor readiness/reporting around one cooldown-remaining calculator, with no undocumented change of timing semantics.
- [x] Add exact six-second single- and multi-token regression mocks and per-ability `/flourish cooldowns` output.
- [ ] In-game, inspect `/flourish cooldowns find treasure` or `/flourish cooldowns` (last matched ability); the previous `mobility` lookup did not find a saved ability under that name.
- [ ] Compare `/flourish debug` before/after apparent repeated emotes. If acceptance does not increment, investigate macros or another enabled addon rather than assuming Flourish generated the emote.
- [x] Babuni confirmed the earlier individual timers worked and explicitly approved the new ability-wide lock determined by the selected token. Live verification of the revised design remains open.
- [ ] Confirm the fix in-game before proposing a release. Existing `v0.4.3-beta` remains untouched.

## Individual emote cooldown investigation — 6 November 2026

- [x] Identify that the active cooldown history was stored only in `lastFireByAbility` and cleared on UI reload; configuration values alone survived.
- [x] Persist server epoch timestamps per accepted native/custom emote in the existing per-character emote records; keep `GetTime()` precision during one session.
- [x] Add regressions for independent 0–120-second emote delays, other ready tokens, distinct abilities, changing the slider, UI reopen, simulated reload, rejected native sends and invalid timestamps.
- [x] Confirm the test suite fails on the previous nonpersistent implementation and passes with the correction.
- [ ] Test in WoW Forever after `/reload`: choose one ability with a single emote at 30 or 60 seconds, fire twice rapidly, reload, and confirm it remains suppressed until its actual delay ends.
- [ ] Test separate emotes on one ability, the same emote on multiple abilities, custom /e on Button press, and changing a slider while a cooldown is active.
- [ ] Verify reported timer failure during one uninterrupted live session. The source-level reset explains reload tests, not necessarily every report of rapid repetition.
- [ ] No public release tag approved; keep the existing `v0.4.3-beta` tag unchanged.

## Search bug and battleground silence — 6 November 2026

- [x] Identify search indexing only a displayed slash-command label, not the canonical native emote token.
- [x] Index both native token and displayed/localized slash alias, with a mock where ROAR displays as `/rawr`.
- [x] Remove `IsSpellUsable` gating from the explicit Button press path and Success-to-press PvP fallback; chance/cooldowns still apply.
- [x] Add `/flourish debug` as a manual, read-only, session-local report of security states, hook counts and emote API responses.
- [ ] Run exact-commit Lua/UI tests and BigWigs no-upload ZIP dry run after docs changes.
- [ ] Verify in-game in Forever: search for ROAR and alias, Button press while an ability is unavailable, group and overworld Success, and the same selected ability inside battlegrounds.
- [ ] Inspect diagnostic output if PvP remains silent, distinguishing a hook not firing, a configured-mode mismatch, actual chat lockdown and native API refusal. Never bypass protected functions.
- [ ] No public tag or CurseForge upload until the design is verified and separately approved.

## Per-ability trigger timing — 6 November 2026

- [x] Babuni approved three choices per ability: Success (default), Button press and Failure, via a dropdown beside Chance.
- [x] Implement per-ability SavedVariables migration/normalization, separate player cast-success/failure event listeners, duplicate-outcome guards and press-time selection.
- [x] Implement Success-to-Button-press runtime fallback in battlegrounds/arenas without modifying settings, while keeping actual chat-lockdown suppression.
- [x] Handle Forever's custom `/e` hardware-only rule by allowing custom text from press mode but never sending it from delayed success/failure events.
- [x] Add mocked trigger, storage, PvP fallback, party/dungeon/raid and UI dropdown tests.
- [ ] Exact-commit GitHub Lua/UI CI and real upload-disabled packager ZIP checks must pass.
- [ ] Verify in the real Forever client: successful cast, failed/quiet failed cast, interruption, action press, selected native and custom text, dropdown persistence and chances/cooldowns.
- [ ] Verify entering/leaving battlegrounds and arenas, real chat lockdown, and no `ADDON_ACTION_BLOCKED` errors. PvP button-press fallback cannot guarantee emote output under active chat restrictions.
- [ ] Verify ordinary group/dungeon/raid triggers remain functional.
- [ ] No new public version is approved or tagged; do not merge or publish before local testing.
## Group-play regression — 0.4.3-beta release preparation

- [x] Inspect the `0.4.2-beta` trigger code and identify overbroad `Map`, `Encounter` and `ChallengeMode` restriction-state suppression.
- [x] Keep genuine chat lockdown, `Chat`/`PvPMatch` restrictions, and battleground/arena safeguards while allowing ordinary party/raid action-press emotes.
- [x] Add mocked tests for outdoor party, party dungeon and raid states, both native and custom text, and actual chat lockdown.
- [x] Development-branch Lua/UI and six-file no-upload ZIP checks passed.
- [ ] Confirm final release-candidate checks on the exact commit before tagging.
- [x] Babuni reports that the group-play fix seems to work fine in-game (general observation, not a detailed scenario log).
- [ ] Explicitly verify outdoor party, dungeon, raid, combat and chat-restriction edge cases without protected-action errors.
- [ ] If still silent in a group, inspect real `IsInInstance`, chat lockdown and restriction-state values before changing safety policy.
- [x] Babuni requested public distribution of the group-play fix.
- [ ] Push only the approved new `v0.4.3-beta` annotated tag; do not modify `v0.4.2-beta`. Verify the resulting CurseForge Beta file and approval.

## 0.4.2-beta hotfix release gate

- [x] Remove delayed native `DoEmote` and add player-action native emotes and security checks.
- [x] Development-branch CI passed Lua/UI mocks and no-upload ZIP validation.
- [x] Babuni installed the experiment in-game and reported no noticeable difference, requesting publication.
- [ ] Verify the candidate commit and six-file packaging checks.
- [ ] Specific live battleground/arena protected-action retest remains unconfirmed; do not invent that result.
- [ ] Push only the approved `v0.4.2-beta` tag and verify its CurseForge file, flavor and Beta classification.

## Urgent investigation — protected native emotes persist

- [x] Confirm second player's `ADDON_ACTION_BLOCKED` stack matches the still-present native `DoEmote` call on the asynchronous cast-success handler in `v0.4.1-beta`.
- [x] Research Forever's hardware-event chat requirements, modern `C_ChatInfo.PerformEmote` and `C_ChatInfo.InChatMessagingLockdown`, plus `C_RestrictedActions.GetAddOnRestrictionState`.
- [x] **Implement for experimental testing only:** native `C_ChatInfo.PerformEmote` during ability press, remove delayed native-emote dispatch and add chat/PvP/encounter/map restriction checks.
- [x] Update offline mocks for no delayed native emote calls, native return failure, chance/cooldown, custom emotes, and restriction transitions.
- [ ] Run exact-commit GitHub CI and real packager ZIP dry-run; verify preserved Lua syntax and packaging.
- [ ] Verify in-game: ordinary attack buttons, custom and native output, failed casts, cooldowns, action bar vs macro vs spellbook, combat and battleground restriction transitions. Observe BugGrabber errors.
- [x] Babuni found the revised trigger behavior acceptable in general use and requested release preparation; detailed PvP testing remains open.

## Current bugfix work — PvP emote restrictions

- [x] Diagnose a reported `ADDON_ACTION_BLOCKED` after battleground entry to `DoEmote` → protected `PerformEmote()` inside a cast-success handler.
- [x] Implement conservative no-emote behavior for both native and custom Flourish triggers whenever Forever reports `IsInInstance()` as `pvp` or `arena`.
- [x] Add mocked tests for suppressed PvP output and restored non-PvP behavior.
- [ ] Retest entering a battleground, ability presses, combat, and leaving the battleground with BugGrabber enabled; verify no protected-action errors.
- [ ] Confirm custom and native emotes still work in the overworld and ordinary party/raid instances.
- [ ] Revisit PvP silence only if player experience demands it; do not bypass protected APIs or change trigger semantics without approval.
- [x] Babuni requested prompt publication of the protected-action mitigation; `0.4.1-beta` is the prepared patch version.
- [ ] Final candidate's Lua/UI mocks and no-upload ZIP checks pass, and the tagged commit matches the approved contents.
- [ ] Push only the approved publishing tag, verify Beta classification and Forever `1.60.1` on CurseForge, then confirm final file approval.

## Completed implementation

- [x] Expanded **810×676** multi-page editor with configured-ability overview, icons and per-ability enable switches.
- [x] Categorized spellbook-style picker, search for configured and available abilities, and searchable native/custom emote list.
- [x] User-written custom `/e` emotes with stable selection IDs.
- [x] Independent 0–120-second cooldowns per emote token plus existing per-ability chance controls.
- [x] `/ffsh` alias, new-character empty configuration, per-character GUID storage.
- [x] Legacy boolean-emote migration, first-cast cooldown safeguard, malformed SavedVariables validation and spellbook filters.
- [x] Lua 5.4 syntax and mocked gameplay/UI regression tests, static package inventory, and BigWigs no-upload packager dry run passed on `dev/expanded-ui-merge` (GitHub Actions).
- [x] **General in-game confirmation:** Babuni installed and used `0.3.2-beta-dev` in WoW Forever on November 5 and reported it working well.

## Historical release-preparation checklist — 0.4.0-beta

- [ ] Final release candidate's Lua syntax, gameplay/UI mocked regressions, static inventory and real dry-run ZIP pass on its **exact commit**.
- [ ] Actual preview ZIP contains the expected three Lua files, TOC, CHANGELOG and MIT LICENSE, with no project-only files.
- [ ] Check precise Forever client build, interface 16001 and game flavor 1.60.1 against the currently installed launcher/game.
- [ ] Confirm CurseForge's private source integration and ensure untagged commits do not auto-publish Alpha files. Prior `v0.3.2-beta` tag pushed successfully and a CurseForge Beta upload was observed processing, but exact private settings remain unavailable here.
- [ ] Receive explicit approval for **the exact public version and commit**; only then create and push the approved annotated publishing tag.
- [ ] Verify resulting CurseForge Beta file, version, supported Forever game version, installed file list, classification and final publication status.

## In-game regression cases to keep separate from the general positive report

- [ ] First cast immediately after reload, repeated casts, 0/100% chance, per-token cooldown independence, and player-only cast-success event.
- [ ] Custom `/e` through action bars and macros, including protected chat errors and casts interrupted or denied after a press.
- [ ] Profile migration from `v0.3.2-beta`, persistence across reload/relog, custom ID preservation after editing, multiple character GUIDs.
- [ ] Ability picker after talent/spellbook change; search across classes/abilities and multiple UI scales.
- [ ] Interaction with RoarForever, chat moderation and normal combat restrictions.

Do not call these cases tested solely because the overall interface works well.

## Future ideas — not approved or implemented

Optional native-emote preview, a global social-volume limit across abilities, more localization, additional accessibility features, and adjustments to custom-text trigger timing. These are separate creative decisions, not release requirements.

## Historic baseline

The original `0.3.0-beta` and `0.3.1-beta` used a 620×520 window, a single cooldown per ability and native-only `DoEmote`. `v0.3.2-beta` improved first-cast handling, saved values and spellbook filtering. `0.4.0-beta` brings the recovered expanded editor and custom emotes into the existing Forever codebase while retaining those safeguards. See [CHANGELOG](CHANGELOG.md), [technical architecture](docs/ARCHITECTURE.md) and [recovery notes](docs/EXPANDED_UI_MERGE.md).
