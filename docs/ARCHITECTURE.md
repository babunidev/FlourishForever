# Flourish Forever — technical architecture

**Target:** World of Warcraft Forever 1.60.1, interface 16001.  
**Public baseline:** `v0.4.1-beta` · **Experimental branch:** `fix/hardware-native-emotes` / `0.4.1-beta-dev`.  
**Evidence:** current Lua source, package configuration, mocked test suites and Babuni's November 5, 2026 general in-game confirmation.

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

The account-wide `FlourishForeverStorage.profiles[UnitGUID("player")]` contains `actionEmotesEnabled`, an `instances` table keyed by normalized spell name, and `customEmotes` with text and stable `id` values. An ability entry holds `name`, `spellID`, `enabled`, `chance`, legacy/default `cooldown`, and `emotes` mapping selected native tokens or `c:id` custom tokens to `{ cooldown = seconds }`.

`FlourishForever_BindCharacterDB` binds a character profile at login and from other DB entry points. It can migrate older name or name-realm keys into the current GUID key, and conditionally adopt an already-loaded `ROARitFOREVERStorage` global. It cannot load another addon's absent SavedVariables file.

`EnsureDB` bounds chance and cooldowns, handles malformed master/ability switches, preserves otherwise unrecognized records for manual recovery, and translates previous `ROAR = true` and other boolean emotes to per-token cooldown tables using the saved ability cooldown. An intentionally empty emote pool remains silent. Valid token entries are normalized in place, not repeatedly copied; the custom-emote list itself is normalized on access.

## Spellbook and UI

Spellbook data is discovered using the Forever client's `C_SpellBook` family, with guarded legacy fallback where present. Passive, off-spec, future and non-spell entries are skipped; ID/name deduplication and sorting protect the list. The available-ability UI groups the spellbook into categorized columns; search filters the cached results.

`CreateUI` constructs an 810×676 movable window with four pages: configured-ability overview, spellbook picker, ability editor and custom-text editor. The overview and picker each have a search field; the ability editor has a third search for native/custom emotes, individual cooldown sliders, per-ability chance and enable/disable. The editor preserves custom IDs where possible when saving edited text. The actual UI has been used in-game by Babuni, but exhaustive UI/combat states are not proven.

## Protected emote restrictions — experimental branch

The public `v0.4.1-beta` tag still calls deprecated `DoEmote` from `UNIT_SPELLCAST_SUCCEEDED`. A subsequent BugGrabber report caught the same protected `PerformEmote()` call, demonstrating that checking only `IsInInstance()` for `pvp` and `arena` is insufficient.

The experimental implementation never registers `UNIT_SPELLCAST_SUCCEEDED` or calls the native emote API from an asynchronous event. Native and custom emotes share direct player `UseAction`, `CastSpellByID` and `C_Spell.CastSpell` hooks where supported.

```text
Player ability press -> identify action spell -> resolve configured ability
  -> IsInInstance: suppress pvp/arena
  -> C_ChatInfo.InChatMessagingLockdown: suppress during chat security state
  -> C_RestrictedActions.GetAddOnRestrictionState:
       suppress Chat/PvPMatch/Map/Encounter/ChallengeMode when activating or active
  -> check ability enabled, emote pool, per-emote cooldown, and chance
  -> custom c:id: send EMOTE chat message in the press context
  -> native token: C_ChatInfo.PerformEmote(token) in the press context
  -> consume token cooldown only when the native API reports success

SPELLS_CHANGED -> refresh spellbook picker data when applicable
UNIT_SPELLCAST_SUCCEEDED -> not registered, never dispatches an emote
```

**Behavioral limitation:** an action press may not complete a successful spellcast, yet the experimental implementation may already have played an emote. A cast through a path not intercepted by the configured hooks may not trigger a flourish. The switch from cast-success timing is therefore an open creative decision, not a silently approved behavior change.

The modern `C_ChatInfo.PerformEmote` API is documented for Forever 1.60.1 with restrictions, but whether it actually succeeds in all relevant hardware-press/combat contexts remains **unverified in-game**. The guards are preventative, not circumventions. They cannot guarantee that all `ADDON_ACTION_BLOCKED` situations disappear. No deferred retries, synthetic clicks or protected API bypasses were added.

Cooldown timers are per ability and emote token; last-fired timestamps live only in session memory and reset on reload. Failure to send a native emote does not consume cooldown. Character SavedVariables and the expanded interface are otherwise unchanged.

## Automated and in-game evidence

- `luac -p` checks the three Lua runtime files.
- `tests/test_action_emotes.lua` mocks spellbook, chance, migration, cooldown and native/custom trigger paths.
- `tests/test_ui_mock.lua` mocks overview, search, picker, editor and custom text saving.
- `tests/check_package_layout.py` validates the tracked file set relative to `.pkgmeta`.
- GitHub's pull-request workflow builds an **upload-disabled** BigWigs packager preview and `tests/check_packaged_zip.py` inspects the real preview ZIP.
- **In game:** Babuni reports the installed expanded development build works well on November 5. No detailed per-case log is available, so individual custom-chat, reload/migration, macro and RoarForever scenarios remain without explicit confirmation.

## Publishing boundary

The repository's `.pkgmeta` expects a six-file package: three Lua files, TOC, changelog and MIT license. A GitHub development commit or preview ZIP is not evidence of CurseForge publication. Public release tags must have specific approval and the resulting CurseForge file must be inspected. Earlier implementation and design evolution are recorded in [the recovery notes](EXPANDED_UI_MERGE.md), [changelog](../CHANGELOG.md) and [family history](EMOTE_FAMILY_HISTORY.md).
