# Flourish Forever — technical architecture

**Target:** World of Warcraft Forever 1.60.1, interface 16001.  
**Prepared release:** `0.4.0-beta` (unpublished). **Public baseline:** `v0.3.2-beta`.  
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

## Protected PvP instance handling — development branch

Both native and custom trigger paths resolve the configured spell through `ResolveAbility`. On the development fix branch, that function first calls Forever's `IsInInstance()`. When the instance type is `pvp` (battleground) or `arena`, it returns immediately: no `DoEmote`, no custom chat, and no cooldown consumption. Saved settings are not erased. This is a precaution based on a reported `ADDON_ACTION_BLOCKED` for protected `PerformEmote()`; real in-game verification is still needed.

## Native and custom trigger paths

```text
Player action-button/spell press (UseAction, CastSpellByID, C_Spell.CastSpell hooks)
  -> resolve configured ability, enabled/chance/cooldown checks
  -> choose eligible emote
  -> custom `c:id`: send chat EMOTE immediately, record token timestamp
  -> native token: store pending emote for matching successful spellcast

UNIT_SPELLCAST_SUCCEEDED(unit="player", spellID)
  -> complete matching pending native selection if within the press window
  -> else, choose eligible native emote and call DoEmote(token)
  -> record per-ability/per-token last fire in session memory
```

This difference is important: a native `DoEmote` follows reported cast success, **not confirmed damage**, while a custom chat `/e` may precede a successful cast and can occur on a failed or interrupted attempt. The press hooks use `hooksecurefunc` where available. Their secure-chat behavior on every Forever build, macro and combat state is not exhaustively verified.

Cooldown timers are per ability **and** emote token, and reset on a reload/relog. A first eligible emote is never throttled by a fabricated zero timestamp. The engine does not cast combat spells itself, send addon messages, or poll a game state timer.

## Automated and in-game evidence

- `luac -p` checks the three Lua runtime files.
- `tests/test_action_emotes.lua` mocks spellbook, chance, migration, cooldown and native/custom trigger paths.
- `tests/test_ui_mock.lua` mocks overview, search, picker, editor and custom text saving.
- `tests/check_package_layout.py` validates the tracked file set relative to `.pkgmeta`.
- GitHub's pull-request workflow builds an **upload-disabled** BigWigs packager preview and `tests/check_packaged_zip.py` inspects the real preview ZIP.
- **In game:** Babuni reports the installed expanded development build works well on November 5. No detailed per-case log is available, so individual custom-chat, reload/migration, macro and RoarForever scenarios remain without explicit confirmation.

## Publishing boundary

The repository's `.pkgmeta` expects a six-file package: three Lua files, TOC, changelog and MIT license. A GitHub development commit or preview ZIP is not evidence of CurseForge publication. Public release tags must have specific approval and the resulting CurseForge file must be inspected. Earlier implementation and design evolution are recorded in [the recovery notes](EXPANDED_UI_MERGE.md), [changelog](../CHANGELOG.md) and [family history](EMOTE_FAMILY_HISTORY.md).
