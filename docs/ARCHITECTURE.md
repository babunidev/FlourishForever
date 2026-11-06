# Flourish Forever — technical architecture

**Target:** World of Warcraft Forever 1.60.1, interface 16001.  
**Latest confirmed Git tag:** `v0.4.3-beta` · **Unreleased work:** `feat/ability-trigger-modes`.  
**Evidence:** current Lua source, package configuration, mocked test suites and Babuni's November 5, 2026 general in-game confirmation.

## Per-emote cooldown persistence (development only)

Each selected emote uses `cfg.emotes[token].cooldown` (0–120 seconds) and may include `cfg.emotes[token].lastFiredAt` (integer Unix seconds from `GetServerTime()`). Both values live inside the character's existing SavedVariables profile and are keyed by configured ability and native/custom emote token. In-session `lastFireByAbility[key][token]` still uses high-resolution `GetTime()`, while `ReadyEmotes` requires both the in-session and persisted wall-clock checks to expire before selecting a token. This retains sub-second precision between reloads and prevents the previous reload bypass.

Only `RememberEmote` writes the wall timestamp when a native `C_ChatInfo.PerformEmote` reports success or the custom `/e` dispatch returns success. Chance rejection, no eligible token, or a failed native API return do not update the timer. A zero-second preference is never blocked by its timestamp. Increasing/decreasing a slider applies to the elapsed time since the last dispatch. `NormalizeEmotes` discards impossible saved stamps, including NaN, infinity and non-positive values. Future clock values do not create an indefinite lock.

`GetServerTime()` is available on the Forever 1.60.1 API and gives Unix seconds, with one-second precision for persisted durations; `GetTime()` tracks the exact per-session elapsed interval. There is no `OnUpdate`, scheduled callback, timer scanning or addon communication. A UI reload recreates the precise Lua table but leaves each saved last-dispatch time intact.

**Evidence:** automatic Lua mocks test individual tokens, 0/15/30/60/120-second boundaries, independent abilities, a simulated fresh module load, and corrupt saves. The actual in-game report prompted the fix, but no post-fix in-client timer test is recorded.

## Search and PvP observability (development only)

Search rows store the displayed slash-command label for the UI, but their case-insensitive search index now concatenates the underlying native token with that label. This permits finding `ROAR` even if an alias or localization makes the displayed command different. The saved token remains unchanged.

For `press`, `TryAbilityEmoteFromPress` no longer rejects attempts when `C_Spell.IsSpellUsable` (or its legacy equivalent) reports false. Usability is not a security permission, and the trigger is the player's action attempt rather than spell execution. The existing 0.2-second duplicate-press limit and per-token cooldown remain active.

Session-only `debugState` tracks player-action hook calls, spell-outcome events, attempted emotes, reported API successes/refusals, last numeric spellID and a short reason. `FlourishForever_EmoteDiagnostics()` reads `IsInInstance()`, `InChatMessagingLockdown()`, and `GetAddOnRestrictionState` for `Chat`/`PvPMatch`, returning a concise status line for `/flourish debug`. No background polling, SavedVariables writes, player identifiers or automated output. A native API success boolean confirms only that the call was accepted, not that nearby players saw the emote.

The new diagnostic tool is intended to distinguish an unobserved player-action hook from a game security denial. The presence of a PvP restriction **does not by itself** establish chat lockdown; the two states must be observed separately. Client enforcement of `C_ChatInfo.PerformEmote()` in battlegrounds is unverified.

## Trigger-mode engine (development only)

`FlourishForever_ActionEmotes.lua` now validates `cfg.trigger` as `success` (default), `press`, or `failure` for each saved ability. The editor dropdown next to Chance updates only that ability's setting. No default is written to a different character's profile.

```text
Player action hook:
  configured mode=press -> native or custom emote immediately
  mode=success + battleground/arena -> temporary press fallback (if chat allowed)
  other modes -> no emote on press

Player UNIT_SPELLCAST_SUCCEEDED:
  mode=success + no PvP/chat restriction -> native eligible token only

Player UNIT_SPELLCAST_FAILED / FAILED_QUIET / INTERRUPTED:
  mode=failure + no PvP/chat restriction -> native eligible token only

No outcome callback may send custom /e chat (Forever requires hardware input).
Both paths retain per-ability chance and individual token cooldown.
```

PvP fallback is derived from `IsInInstance()` (`pvp`/`arena`) every time; it does not persist. Player-action dispatch checks actual `InChatMessagingLockdown()` and `Chat` restrictions; asynchronous outcomes additionally suppress PvP matches. `Map`/`Encounter`/`ChallengeMode` addon data restrictions do not block party/dungeon/raid expression. Restricted native APIs can still fail; this branch has no live game-client compatibility proof yet.

Outcome reports are deduplicated by non-secret cast GUID when available, falling back to a short same-spell/event window. Failure includes interruptions and quiet failures. Not every invalid button attempt creates a cast-failure event. Successful cast is not a confirmed hit.

The popup dropdown is a lightweight local frame with three choices, not a new dependency. It is contained inside the existing four-page UI; SaveVariables and runtime package layout remain unchanged.
## Runtime files and load order

```text
FlourishForever.toc
  ## Interface: 16001
  ## SavedVariables: FlourishForeverStorage
  1. FlourishForever_Storage.lua       -> per-GUID persistent profile
  2. FlourishForever.lua               -> slash command dispatch
  3. FlourishForever_ActionEmotes.lua  -> spellbook, emote engine, UI, hooks
```

There is no external library or server component.

## Profile model and migration

The account-wide `FlourishForeverStorage.profiles[UnitGUID("player")]` contains `actionEmotesEnabled`, an `instances` table keyed by normalized spell name, and `customEmotes` with text and stable `id` values. An ability entry holds `name`, `spellID`, `enabled`, `chance`, legacy/default `cooldown`, and `emotes` mapping selected native tokens or `c:id` custom tokens to `{ cooldown = seconds, lastFiredAt = optionalServerUnixSeconds }` on the current development branch.

`FlourishForever_BindCharacterDB` binds a character profile at login and from other DB entry points. It can migrate older name or name-realm keys into the current GUID key, and conditionally adopt an already-loaded `ROARitFOREVERStorage` global. It cannot load another addon's absent SavedVariables file.

`EnsureDB` bounds chance and cooldowns, handles malformed master/ability switches, preserves otherwise unrecognized records for manual recovery, and translates previous `ROAR = true` and other boolean emotes to per-token cooldown tables using the saved ability cooldown. An intentionally empty emote pool remains silent. Valid token entries are normalized in place, not repeatedly copied; the custom-emote list itself is normalized on access.

## Spellbook and UI

Spellbook data is discovered using the Forever client's `C_SpellBook` family, with guarded legacy fallback where present. Passive, off-spec, future and non-spell entries are skipped; ID/name deduplication and sorting protect the list. The available-ability UI groups the spellbook into categorized columns; search filters the cached results.

`CreateUI` constructs an 810×676 movable window with four pages: configured-ability overview, spellbook picker, ability editor and custom-text editor. The overview and picker each have a search field; the ability editor has a third search for native/custom emotes, individual cooldown sliders, per-ability chance and enable/disable. The editor preserves custom IDs where possible when saving edited text. The actual UI has been used in-game by Babuni, but exhaustive UI/combat states are not proven.

## Group-play guard refinement — 0.4.3-beta candidate

The `0.4.2-beta` player-action handler incorrectly treated `Map`, `Encounter` and `ChallengeMode` restriction states as reasons to skip every emote. These states signal restrictions on addon information and features, not necessarily a restriction on the player-triggered chat APIs. When active during group/instance play, this policy could suppress Flourish without a chat failure.

In the 0.4.3-beta candidate, `IsRestrictedEmoteContext()` instead checks only explicitly relevant conditions: `IsInInstance()` reporting `pvp` or `arena`, `C_ChatInfo.InChatMessagingLockdown()`, and `GetAddOnRestrictionState` for `Chat` and `PvPMatch` (including `Activating`). Normal party/raid membership and `Map`/`Encounter`/`ChallengeMode` data restrictions are not automatic reasons to suppress a player-action emote. Native and custom emotes share this check. No deferred chat retries or protected-function bypasses exist.

These conditions preserve security checks but cannot prove the client allows a particular emote. The new group behavior has mocked coverage, and Babuni reported the development version seems to work fine in-game. Specific dungeon, raid and protected-action scenarios remain unverified.

## Protected emote restrictions — 0.4.2-beta candidate

The public `v0.4.1-beta` tag still calls deprecated `DoEmote` from `UNIT_SPELLCAST_SUCCEEDED`. A subsequent BugGrabber report caught the same protected `PerformEmote()` call, demonstrating that checking only `IsInInstance()` for `pvp` and `arena` is insufficient.

The release candidate never registers `UNIT_SPELLCAST_SUCCEEDED` or calls the native emote API from an asynchronous event. Native and custom emotes share direct player `UseAction`, `CastSpellByID` and `C_Spell.CastSpell` hooks where supported.

```text
Player ability press -> identify action spell -> resolve configured ability
  -> IsInInstance: suppress pvp/arena
  -> C_ChatInfo.InChatMessagingLockdown: suppress during chat security state
  -> C_RestrictedActions.GetAddOnRestrictionState:
       suppress Chat/PvPMatch when activating or active;
       unrelated Map/Encounter/ChallengeMode restrictions do not block
  -> check ability enabled, emote pool, per-emote cooldown, and chance
  -> custom c:id: send EMOTE chat message in the press context
  -> native token: C_ChatInfo.PerformEmote(token) in the press context
  -> consume token cooldown only when the native API reports success

SPELLS_CHANGED -> refresh spellbook picker data when applicable
UNIT_SPELLCAST_SUCCEEDED -> not registered, never dispatches an emote
```

**Behavioral limitation:** an action press may not complete a successful spellcast, yet the experimental implementation may already have played an emote. A cast through a path not intercepted by the configured hooks may not trigger a flourish. Babuni reported no noticeable difference in ordinary gameplay and requested release; this timing change and its limitations are documented explicitly.

The modern `C_ChatInfo.PerformEmote` API is documented for Forever 1.60.1 with restrictions, but whether it actually succeeds in all relevant hardware-press/combat contexts remains **unverified in-game**. The guards are preventative, not circumventions. They cannot guarantee that all `ADDON_ACTION_BLOCKED` situations disappear. No deferred retries, synthetic clicks or protected API bypasses were added.

Cooldown timers are per ability and emote token. The current development build retains last-fired timestamps both in session memory for precision and in per-emote SavedVariables for reload persistence. Native API refusal does not consume a cooldown. The expanded interface and other character settings are otherwise unchanged.

## Automated and in-game evidence

- `luac -p` checks the three Lua runtime files.
- `tests/test_action_emotes.lua` mocks spellbook, chance, migration, cooldown and native/custom trigger paths.
- `tests/test_ui_mock.lua` mocks overview, search, picker, editor and custom text saving.
- `tests/check_package_layout.py` validates the tracked file set relative to `.pkgmeta`.
- GitHub's pull-request workflow builds an **upload-disabled** BigWigs packager preview and `tests/check_packaged_zip.py` inspects the real preview ZIP.
- **In game:** Babuni reports the installed expanded development build works well on November 5. No detailed per-case log is available, so individual custom-chat, reload/migration, macro and RoarForever scenarios remain without explicit confirmation.

## Publishing boundary

The repository's `.pkgmeta` expects a six-file package: three Lua files, TOC, changelog and MIT license. A GitHub development commit or preview ZIP is not evidence of CurseForge publication. Public release tags must have specific approval and the resulting CurseForge file must be inspected. Earlier implementation and design evolution are recorded in [the recovery notes](EXPANDED_UI_MERGE.md), [changelog](../CHANGELOG.md) and [family history](EMOTE_FAMILY_HISTORY.md).
