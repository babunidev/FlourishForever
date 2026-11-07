# Flourish Forever — dated changelog and development evidence

**Creative direction:** Babuni · **Portfolio:** babuni.dev · **Target:** WoW Forever 1.60.1 / Interface 16001.


## Unreleased development — chosen emote sets the whole ability's cooldown (2026-11-07)

- Babuni confirmed that the preceding cooldown implementation works in-game and approved a change to **ability-wide cooldown gating** without removing individual emote duration sliders.
- Whenever a selected emote is attempted, snapshot its 0–120-second duration and lock **all emotes on that configured ability** until it expires. Afterward, randomly select from the eligible native/custom pool again; other configured abilities remain independent.
- Preserve native-emote false-return retry protection: a real native API attempt starts the ability lock even if the function returns false, without claiming a successful dispatch. Custom `/e` starts the lock when submitted; blocked chat calls, empty pools and chance rejections do not start one.
- Persist `cfg.abilityLock` with chosen token, duration and server timestamp; keep high-resolution in-session timing and validate corrupt saved values. Existing token preferences and historical per-token timestamps are retained.
- Update editor guidance and `/flourish cooldowns` diagnostics to show the current ability lock and the duration each token would impose if selected.
- **Verification:** Lua syntax, mocked trigger, duration, independent ability, custom chat, native false-return, reload and malformed-save regression checks, and upload-disabled BigWigs packaging ZIP validation passed on the development branch. **New behavior has not yet been tested in the Forever client. No public tag.**

## Unreleased fix — native false-result retry throttling (2026-11-07)

- Babuni supplied live diagnostics showing nine native attempts, zero reported successful calls and nine `false` API results; the last attempted token was `FAINT`, with a six-second configured timer. A `Mobility` cooldown lookup found no saved ability under that name, while the last matched ability was `Find Treasure`.
- Keep `lastFiredAt` exclusively for native API successes and custom `/e` dispatches. Add `lastAttemptAt` for actual native API invocations **regardless of the boolean result**; use the larger remaining interval of precise session and both saved timestamps for per-token rate-limiting.
- Failed native results continue to be reported as rejected, not mislabeled as success. They now impose the configured retry delay to prevent repeated immediate calls or possible visible animations on every press.
- Do not consume a timer on chance rejection, client chat lockdown or when the native API is unavailable. Preserve separate emotes/abilities and a zero-second setting.
- Extend mocked regressions for a native API that returns false while the simulated client displays an emote, including rapid presses, exact six-second expiry, persistence across reload and truthful diagnostics.
- **Verification:** offline Lua/UI tests and no-upload ZIP checks run on the development branch. The real-client false-return behavior is not fully explained and the throttling fix remains unverified in-game. No new public tag.

## Unreleased investigation — 6-second emote repeat report (2026-11-07)

- Babuni reported that the installed persistence build still emits an emote every time Mobility is pressed despite a six-second setting. Root cause remains unconfirmed.
- Refactor per-token cooldown eligibility and manual readout to share one remaining-time calculation; preserve existing timer semantics, independent emotes and no global ability throttle.
- Add read-only `/flourish cooldowns [ability]` to show each selected token, configured duration, remaining seconds, server/session timestamps and last attempted token. Extend `/flourish debug` with last matched ability, token and token cooldown.
- Test a single six-second emote across consecutive presses and exact expiry; also test that two separate selected emotes can each fire once while their own cooldowns run.
- **Verification:** GitHub mocked logic/UI and no-upload package preview passed. Live reproduction and confirmation of the user's six-second issue remain pending. No new tag or public release.

## Unreleased development — individual emote cooldown persistence (2026-11-06)

- Fix cooldown history resetting on every `/reload` or relog. Successful native dispatches and submitted custom `/e` messages now save an individual `lastFiredAt` Unix timestamp alongside each emote's configured cooldown.
- Retain precise `GetTime()` checking within a session and use Forever's `GetServerTime()` to honor the unexpired time across reloads. No polling or additional events.
- Preserve per-ability/per-token independence, 0–120-second editable settings, immediate first use and chance. Rejected native sends do not count as success; the later development correction adds a separate per-token retry interval for them. Invalid or malformed saved timestamps are discarded.
- Add offline regressions for 0/15/30/60/120-second cases, separate tokens, separate abilities, native API failure, custom emotes, corrupt saved timestamps, simulated reload, and slider save/reopen.
- **Evidence:** Lua/UI mock tests and real no-upload packaging checks passed on the development branch. The user's timer problem was reported in-game; **this corrective implementation has not yet been retested in-game**. No new public tag.

## Unreleased development — search and battleground diagnostics (2026-11-06)

- Fix emote editor search to match canonical native tokens such as `ROAR` as well as displayed slash aliases/localized labels. Add a UI mock verifying search works with a nonmatching alias.
- Remove `IsSpellUsable` from the press-trigger path: a real player press remains a press even if a spell is temporarily unusable or on cooldown. Preserve existing emote chance, per-token cooldowns and deduplication.
- Add read-only `/flourish debug` showing instance type, chat lockdown and Chat/PvPMatch state, press/outcome counts, native/custom attempts and whether the emote API returned success. No identifiers, constant polling, persistent logs or chat spam.
- **Caution:** the user's battleground test reported no emote output with the earlier development build. Actual restriction state and API rejection cause are not yet known. The new diagnostics do not bypass protected functions or guarantee PvP output.
- Verify with mocked UI/gameplay tests and the no-upload packaging dry run; local Forever battleground and group retesting remain open.

## Unreleased development — configurable ability trigger modes (2026-11-06)

- Add a per-ability **Triggered by** dropdown next to Chance, with Success (new/default for older saved configurations), Button press and Failure.
- Listen to `UNIT_SPELLCAST_SUCCEEDED`, `UNIT_SPELLCAST_FAILED`, `UNIT_SPELLCAST_FAILED_QUIET` and `UNIT_SPELLCAST_INTERRUPTED` for the player; deduplicate duplicate reports per cast where possible.
- Temporarily resolve a saved Success trigger to Button press in battlegrounds/arenas without writing the fallback into SavedVariables. Keep genuine chat lockdown restrictions and suppress delayed native emotes during PvP restrictions.
- Respect Forever's custom `/e` hardware-input restriction: outcome events send **native tokens only**, while custom `/e` stays on hardware press. No silent fallback for explicitly selected Failure.
- Preserve existing character profiles, emote pools, independent chance/cooldowns and ordinary group/dungeon/raid behavior. Add mocked UI and gameplay coverage.
- **Verification status:** code implemented on the `feat/ability-trigger-modes` development branch, pending exact-commit automated checks and local WoW Forever testing. No release tag or CurseForge upload.
## 0.4.3-beta — restore group-play emotes (prepared; not yet published)

- Stop treating `Map`, `Encounter` and `ChallengeMode` addon data-restriction states as blanket emote bans. Normal outdoor parties, dungeons and raids can attempt native and custom emotes through existing player-action hooks.
- Keep actual `C_ChatInfo.InChatMessagingLockdown()`, activating/active `Chat` and `PvPMatch` state checks, and battleground/arena suppression. No protected function bypass or delayed native-emote dispatch is added.
- Add mocked regressions for ordinary parties, dungeon groups and raids with unrelated restriction states active, along with actual chat-lockdown suppression.
- **Verification:** GitHub Lua/UI mock checks and a no-upload packager ZIP passed on the development branch. Babuni reports the revised build now seems to work fine in-game, without an itemized list of group/dungeon/raid cases. Exact release-candidate checks remain required. **Publication:** no `v0.4.3-beta` tag or CurseForge file has been created yet.

## 0.4.2-beta — protected native emotes (tagged; final CurseForge approval not independently confirmed)

- Stop calling `DoEmote` from delayed `UNIT_SPELLCAST_SUCCEEDED` events, which continued to trigger protected `PerformEmote()` errors after the 0.4.1-beta PvP guard.
- Attempt native `C_ChatInfo.PerformEmote` and custom `/e` only during direct player-action hooks, without deferred native replay.
- Respect battleground/arena, chat messaging lockdown, and active/activating chat, PvP, map, encounter and challenge restrictions.
- Preserve configuration, chance, cooldowns and the expanded interface; failed native send results do not consume cooldowns.
- **Behavioral trade-off:** native emotes may happen on failed attempted casts and may not trigger for unhooked spell activation paths.
- **Verification:** Babuni installed the development build in Forever and observed no noticeable difference in ordinary use. This does **not** explicitly verify a successful battleground retest or every secure-action condition. The final candidate must pass automated checks and package dry run.
- **Release status:** candidate only; publication requires the approved new tag and confirmed CurseForge file.

## 0.4.1-beta — PvP protected-emote hotfix (Git tag pushed; CurseForge upload observed processing)

- Suppress addon-triggered native and custom emotes in battlegrounds (`pvp`) and arenas (`arena`) after a player-reported blocked `PerformEmote()` call on battleground entry.
- Preserve SavedVariables, enabled abilities, and individual emote cooldown timestamps while PvP suppression is active. Ordinary world and dungeon emotes remain enabled.
- Add offline mocked checks for both PvP instance types, both emote trigger paths and restoration outside PvP.
- **Verification:** the fix passed offline Lua/UI mocks and a no-upload packaging dry run on the development branch. The exact release candidate must also pass CI; **no successful live battleground/arena retest has been reported**. Publication is not confirmed until the new tag is pushed and CurseForge processing is verified.

## 0.4.0-beta — expanded editor (tagged; CurseForge Beta upload observed processing)

- **New overview:** a larger 810×676 configuration window with spell icons, configured ability summaries and individual enable/disable switches.
- **Find abilities faster:** a categorized, spellbook-style picker plus search fields for both available and configured abilities.
- **More emote choices:** search native emotes; create and edit custom `/e` lines, then assign them to individual abilities.
- **Finer timing:** separate 0–120-second cooldown settings for each selected emote, alongside the existing per-ability chance control.
- **Compatibility:** `/ffsh` joins the existing slash commands; previously configured native emotes migrate from boolean selections into cooldown records. Preserves saved character profiles, first-cast cooldown safety and spellbook filtering.
- **Forever behavior:** native emotes still fire on reported successful casts; custom chat emotes are attempted from an ability button press and may appear even if the later cast fails.
- **Distribution:** existing six-file packaging structure and MIT license remain unchanged.

**Verification:** Babuni installed and used the expanded development build in the Forever game client on November 5, 2026 and reported it working well. Offline Lua logic/UI tests and package checks were previously successful; final release-candidate CI is required separately. This confirmation does not establish complete coverage of protected custom chat, failed casts, all profile migrations or addon interactions.

**Release status:** `v0.4.0-beta` is tagged and a matching CurseForge Beta upload was observed in Processing. Final approval was not independently confirmed.

## 0.3.2-beta — World of Warcraft: Forever

- **First-cast cooldown:** a configured ability can now play its first eligible emote immediately after login or UI reload, without waiting for a cooldown that never started.
- **Saved settings:** saved chance and cooldown values stay within the existing 0–100% and 0–120-second limits. Malformed saved values are handled safely.
- **Spellbook selection:** skip passive, off-spec, future and non-spell entries instead of offering unusable actions.
- **Cleaner installations:** future packaged downloads omit portfolio artwork, development documentation and test files; the MIT license and changelog are included.
- **Existing behavior preserved:** player-selected abilities, per-character settings, native game emotes, successful-cast trigger and default options remain unchanged.

**Client target:** WoW Forever 1.60.1 / Interface 16001.

**Verification:** original addon functionality was beta-tested by Babuni. Lua syntax, mocked regressions, static file inventory and a six-file BigWigs packager dry run passed for the prepared update. Live testing of the changed code on the launch client remains unverified.

## Unreleased development — 2026-11-04 (packaging and documentation milestones)

- Updated `.pkgmeta` to exclude portfolio artwork, project documentation, agent instructions and tests from future CurseForge packages; preserved `CHANGELOG.md` for release-note generation.
- Added a dependency-free, static package-inventory guard at `tests/check_package_layout.py` and clarified installation documentation.
- Aligned the GitHub repository with CurseForge's pre-existing MIT designation by adding a formal `LICENSE` and `license-output` packaging directive.
- Finalized the README for Forever launch, corrected human creative/portfolio attribution, and clarified public version differences, offline test evidence and remaining release-client checks.
- The packaging and documentation commits on `main` did not alter gameplay Lua or the TOC. The later `release/0.3.2-beta-prep` candidate integrates the separately tested gameplay fixes and prepares the next version without publishing it. Actual CurseForge publication and launch-client verification remain outstanding.


## October 27, 2026 — portfolio artwork

- Added three creator-supplied images under `assets/portfolio/`: square logo, PNG showcase and JPEG thumbnail.
- Added an asset index and JSON manifest for Babuni.dev display paths, dimensions and alt text.
- Preserved original file bytes; checked image decoding, dimensions and the JPEG's size below 2 MB.
- Updated README, content inventory, design notes and development history. No gameplay behavior changed; portfolio rendering remains unverified.

## October 27, 2026 — portfolio documentation audit

- Expanded/created 11 substantial Markdown files describing the human-directed character-expression concept, implementation, UI, saved-data migration, release chronology, design decisions and test gaps.
- Clarified that the real gameplay trigger is **UNIT_SPELLCAST_SUCCEEDED**, not verification that an attack landed; that cooldowns are **session-only**, and that spell settings are keyed by normalized **name** within a GUID-based character profile.
- Recorded the source-level first-cast `GetTime()`/zero-timestamp edge case, optional legacy-root migration behavior, `/rit` alias and raw-GUID status output.
- At the time of that historical audit, published GitHub beta entries had **no downloadable release assets** and the main repository had **no LICENSE** (the license was added during subsequent development).
- Only Markdown documentation changed; no gameplay Lua, TOC, packaging metadata or assets were edited. This review **did not run WoW or automated tests**.

## October 22, 2026 — 0.3.0-beta: the original committed behavior

**`b60d08024cdd`**, “Ship Flourish Forever 0.3.0-beta with configurable ability emotes,” is the **first commit in this repository**. It already contains the complete three-file Lua architecture, UI, chance/cooldown controls, event listener and per-character storage. There is no preceding visible development commit for an earlier FlourishForever version in this repository.

- **Trigger:** player `UNIT_SPELLCAST_SUCCEEDED`, match configured ability by normalized name derived from event spell ID.
- **Randomness:** one uniformly random chosen enabled game emote token after independent chance and cooldown checks.
- **Configuration:** spellbook non-passives, ability-specific chance (0–100%), cooldown (0–120s), selected emote pool and per-character master enable.
- **Persistence:** account-wide TOC root with per-GUID character profiles; migration helper for previously loaded `ROARitFOREVERStorage` and name-keyed profiles.
- **UI:** Blizzard-style movable frame, dropdown, configured ability list, sliders, scrolling emote checkboxes, remove action.
- **Distribution:** `.pkgmeta` with `package-as: FlourishForever`, manual changelog.

The initial README describes casts as “landing”; source evidence narrows that to **reported cast success**. It is not an observed hit-condition check.

## October 22 — 0.3.1-beta: packaging/version-only update

**`56d8b67d719a`**, “Ship Flourish Forever 0.3.1-beta for the CurseForge packager,” updated **CHANGELOG.md, README.md and the TOC version only**. Its contemporaneous changelog says explicitly: **“No change to how emotes play.”**

GitHub release entries for [0.3.0-beta](https://github.com/babunidev/FlourishForever/releases/tag/v0.3.0-beta) and [0.3.1-beta](https://github.com/babunidev/FlourishForever/releases/tag/v0.3.1-beta) exist, published the same day. GitHub release metadata lists **no attached assets** for either. A packager-oriented commit does not prove the external publication or live game-client behavior.

## October 26 — attribution and initial history scaffold

- **`61c7aaddc1d6`** standardized the TOC author to **Babuni.dev** from an earlier Babunigaming credit.
- **`7e36f7156b51`** placed the creator credit in README, while retaining original Babunigaming development context.
- **`24013323e692`** created concise CONCEPT, ROADMAP, AGENTS, ARCHITECTURE, DECISIONS and DEVLOG files.
- **`b73fed5344bd`** linked those initial project-history files from README.

This October 27 editorial pass deepens the record without claiming the creator approved any new behavior or that the code was verified in game.

## 2026-11-01 — expressive-addon family history

- Connected Flourish Forever's cast-success and per-ability graphical selection to earlier action-slot emote addons.
- Clarified that available emote options come from the client, not arbitrary user-created animations. See [family history](docs/EMOTE_FAMILY_HISTORY.md). Documentation only.
