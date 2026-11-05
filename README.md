# FlourishForever

**WoW Forever only** · **Interface:** `16001` · **Development test build:** `0.4.2-beta-dev` (not published)  
**Latest confirmed Git tag:** `v0.4.2-beta` · **Creative:** Babuni · **Portfolio:** [babuni.dev](https://babuni.dev)

Flourish Forever links player-selected abilities to native or custom emotes, with per-ability chance, per-emote cooldowns and per-character settings. It does not cast abilities automatically.

## Experimental group-play correction (not released)

A player report after `v0.4.2-beta` found that Flourish was silent while grouped. Review found an overly broad restriction check: the addon treated `Map`, `Encounter` and `ChallengeMode` *addon data restrictions* as a blanket prohibition on player-triggered emotes. The development patch allows emotes in normal outdoor parties, party dungeons and raids while those unrelated restriction types are active.

**Security remains enforced:** the addon still suppresses output when Forever reports actual chat messaging lockdown, an activating/active `Chat` or `PvPMatch` restriction, or a battleground/arena instance. It does not attempt to bypass protected actions. If the game reports genuine chat lockdown while grouped, automatic emotes remain silent rather than causing another blocked-action error.

The same settings, action-press native/custom emotes and cooldowns are retained. Mocked tests cover party/raid scenarios; **actual grouped play has not yet been retested with this development patch**. A disabled addon, individual ability settings, unavailable action hooks or server rejection may also cause silence, and cannot be ruled out from the report alone.

## What's changing in 0.4.2-beta

- Replaces the delayed `UNIT_SPELLCAST_SUCCEEDED` -> `DoEmote` route that still caused protected `PerformEmote()` errors in `0.4.1-beta`.
- Native `C_ChatInfo.PerformEmote` and custom `/e` attempts now run during eligible player ability-action hooks, with **no delayed native-emote retry**.
- Suppresses addon-triggered emotes during battleground/arena or relevant chat/match/map/encounter restrictions.
- Retains existing character configurations, ability overview, emote pools, chance and individual cooldowns.

**Trigger trade-off:** An emote can occur on an attempted spell even if that spell later fails; abilities outside the observed player-action hooks may not trigger an emote. These are deliberate changes to avoid the protected delayed-call path.

**Testing:** Babuni installed and used the development build `0.4.1-beta-dev` on November 5, 2026 and said it appears to work as before, with no noticeable difference. This is a general in-game report, **not** explicit confirmation of the previously failing battleground situation. Lua/UI mock tests and packaging validation support the code but cannot prove every Forever protected-action state.

## Features and controls

The 810×676 configuration window provides a searchable overview of configured abilities, categorized spellbook picker with search, individual enable switches, native/custom emote search and selection, an editable custom `/e` list, independent **0–120-second cooldowns per emote**, and **0–100% chance per ability**. New characters start with no configured abilities.

| Command | Function |
| --- | --- |
| `/flourish`, `/flourish ui`, `/flourish config` | Toggle editor |
| `/flourish status` | Print current profile status |
| `/flourishforever`, `/rit`, `/ffsh` | Aliases |

Install the latest publicly available Forever file from [CurseForge](https://www.curseforge.com/wow/addons/flourishforever), or use the development branch for group regression testing. The game addon directory `_forever_/Interface/AddOns/FlourishForever/` must contain `FlourishForever.toc`, `FlourishForever_Storage.lua`, `FlourishForever.lua`, and `FlourishForever_ActionEmotes.lua`.

Settings persist in `FlourishForeverStorage`, indexed by character GUID. Older boolean emote selections are migrated; actual last-fired timestamps reset on reload.

## Development checks

```bash
luac -p FlourishForever_Storage.lua
luac -p FlourishForever.lua
luac -p FlourishForever_ActionEmotes.lua
lua tests/test_action_emotes.lua
lua tests/test_ui_mock.lua
python3 tests/check_package_layout.py
```

GitHub CI also creates an **upload-disabled** BigWigs packager preview for Forever `1.60.1` and validates its six files: TOC, three Lua modules, changelog and MIT license. Do not treat a dry run or a Git tag as proof of CurseForge approval.

Original source is [MIT licensed](LICENSE); Blizzard game assets are not. Babuni directs the creative concept, historical Babunigaming attribution is preserved, and AI technical work is recorded separately.

[Concept](CONCEPT.md) · [Changelog](CHANGELOG.md) · [Roadmap](ROADMAP.md) · [Architecture](docs/ARCHITECTURE.md) · [Design](docs/DESIGN.md) · [Decisions](docs/DECISIONS.md) · [Development journal](docs/DEVLOG.md)
