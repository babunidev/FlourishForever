# Flourish Forever — development and AI collaboration rules

**Human creative and final decision-maker:** Babuni. **Portfolio:** babuni.dev. **Historical project credit:** Babunigaming.  
**Game:** World of Warcraft **Forever only**, client 1.60.1 / interface 16001. Recheck after each game update.  
**Current tagged baseline:** `v0.4.2-beta` · **Prepared patch:** `0.4.3-beta` (not yet tagged/published).

## Creative boundaries

Flourish Forever gives a player control over expressive emotes associated with **chosen character abilities**. Never cast an ability for the player, automatically configure every ability, or create unsolicited chat spam. A fresh character starts with no configured abilities; enabling the master switch alone does not trigger emotes.

The expanded interface and custom `/e` text are now part of the approved development direction, recovered from an earlier local version. The original native-emote-only design remains documented as history, not a restriction on the approved new version.

## Current runtime invariants

- Keep TOC load order: `FlourishForever_Storage.lua`, `FlourishForever.lua`, `FlourishForever_ActionEmotes.lua`.
- `FlourishForeverStorage` is account-wide, with character profiles keyed by `UnitGUID("player")`; earlier name or name-realm keys are migration only. `ROARitFOREVERStorage` can be adopted **only when already loaded**.
- Configured abilities remain keyed by lowercased, trimmed **spell name**. Ranks/localization or duplicate names can affect matching. Profiles are not dungeon-instance-scoped.
- Each ability has `enabled`, `chance` (0–100), and selected `emotes`. Each selected native/custom token stores `{ cooldown = 0..120 }`. The old ability-level `cfg.cooldown` stays for migration/defaults; older `true` token values migrate using that cooldown. An empty emote pool is intentionally silent.
- **Published 0.4.1-beta PvP guard:** the reported Forever client blocked protected `PerformEmote()` during a battleground cast-success event. For safety, both native and custom addon-driven emotes are suppressed in `IsInInstance()` types `pvp` and `arena`; normal settings are preserved. This is supported by mocked checks but has not yet had a live battleground retest; record that limitation even if an urgently approved public hotfix is distributed.
- **Group-play compatibility:** only `Chat` and `PvPMatch` addon restriction states are relevant to the emote dispatch guard. Do not block ordinary player-triggered emotes merely because `Map`, `Encounter` or `ChallengeMode` addon data restrictions are active. Keep `C_ChatInfo.InChatMessagingLockdown()` and battleground/arena checks; never try to bypass genuine protected-action restrictions. This correction is prepared for release after Babuni reported it working in-game; the report does not establish a full party/dungeon/raid or combat regression suite.
- **Current native trigger:** native emotes now use `C_ChatInfo.PerformEmote` directly from player ability-action hooks, and no native emotes are attempted from `UNIT_SPELLCAST_SUCCEEDED`. This sacrifices cast-success timing and may miss non-action-bar spell activations. Babuni reported no noticeable difference during general in-game use and requested publication; a specific successful battleground retest remains unconfirmed. Never route a protected call through a delayed event/timer or attempt to bypass its security.
- First presses must not be throttled by a synthetic zero timestamp; runtime cooldown timestamps are session-only. Failed API returns must not consume cooldown.
- Custom `/e` text uses `c:id` tokens and is attempted during player button-press hooks (`UseAction`, `CastSpellByID`, `C_Spell.CastSpell` where available). It can trigger **before cast success**, including on failed/aborted casts. Preserve this distinction and verify secure-chat restrictions in Forever before claiming complete compatibility.
- Spellbook selection excludes passive, future, off-spec and non-spell entries. Actual modern API availability must be verified on the target Forever build, not guessed from an interface number.
- `EnsureDB` validates saved data; keep backward migration compatible and avoid unnecessary allocations on routine casts. Preserve malformed/unknown saved records for possible recovery when safe.
- The UI uses an 810×676 multi-page editor with searchable overview, categorized spellbook picker, emote search, per-token cooldowns, custom-emote editor and per-ability enable switches.
- Slash commands: `/flourish`, `/flourishforever`, `/rit`, `/ffsh`, plus `status` and `config`. `status` may print the player's GUID; redact public screenshots/logs.
- MIT `LICENSE` and `.pkgmeta` package policy are authoritative; do not ship project docs, tests or portfolio assets with the addon.

## Repository and documentation protocol

1. **Read this file and [docs/DOCUMENTATION.md](docs/DOCUMENTATION.md) first**, then inspect README, CONCEPT, ROADMAP, CHANGELOG, relevant source, TOC, `.pkgmeta`, docs and repository state before modifying anything.
2. Preserve Babuni's approved concept, history, attribution, existing license, SavedVariables and unrelated changes. Discuss materially different gameplay designs instead of silently substituting them.
3. Make small, maintainable edits. Validate inputs, handle absent APIs, avoid excessive allocations, chat output, sound repetition, unnecessary hooks and addon communications.
4. Run Lua syntax checks, mocked gameplay and UI tests, static package inventory, and an upload-disabled real packager ZIP preview for release candidates. Record exact results and limitations. **Do not claim mocked tests prove in-game behavior.**
5. Babuni reported the installed expanded development build working in WoW Forever on November 5, 2026. This is real hands-on confirmation at a general level, but does **not** establish complete verification of protected custom chat, every macro path, migration across characters, reloads or interactions with RoarForever.
6. Keep README, CHANGELOG, ROADMAP, CONCEPT, architectural/design decisions and DEVLOG accurate, distinguishing proposals, implementation, testing, release and publication. Public first-person journals follow the repository documentation standard.
7. Ordinary `feat:`, `fix:`, `docs:`, `test:`, `refactor:` and `chore:` commits are **development checkpoints**. No publication tag, GitHub Release or CurseForge upload without Babuni's explicit version-specific authorization. Confirm CurseForge's untagged-commit/Alpha behavior and target flavor before a publishing tag; verify actual public file separately.

## Related history

The October 2026 original implementation began as native-emote-only ability expression. The November 2026 recovered UI introduced more extensive selection and custom text. Do not confuse this project with the action-slot emote family or [Roar Forever](https://github.com/babunidev/RoarForever) audio restoration. See [the family history](docs/EMOTE_FAMILY_HISTORY.md) and [expanded merge technical notes](docs/EXPANDED_UI_MERGE.md).
