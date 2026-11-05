# Flourish Forever — roadmap and verification status

**Creative decision authority:** Babuni · **Game:** WoW Forever 1.60.1 / Interface 16001  
**Latest confirmed Git tag:** `v0.4.1-beta` · **Prepared version:** `0.4.2-beta` (not yet tagged).  
**Development:** Expanded UI restored from Babuni's older local archive and committed to `dev/expanded-ui-merge`. Preparation occurs separately; no public release tag was created.

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
