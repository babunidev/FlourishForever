# FlourishForever

**World of Warcraft: Forever only** · **Interface:** `16001` · **Prepared hotfix:** `0.4.1-beta` (not yet tagged)  
**Last confirmed Git tag:** `v0.4.0-beta` · **Creative direction:** Babuni · **Portfolio:** [babuni.dev](https://babuni.dev) · **Historical credit:** Babunigaming

Flourish Forever adds character expression to abilities the player chooses. An ability may trigger a random native WoW emote or a player-written `/e` emote, subject to configurable chance and individual emote cooldowns. It never casts spells on the player's behalf.

## 0.4.1-beta — battleground and arena protected-emote safeguard

A player-reported `ADDON_ACTION_BLOCKED` occurred after entering a Forever battleground: a cast-success `DoEmote` call reached protected `PerformEmote()`. In this prepared hotfix, automatic Flourish emotes are intentionally **silent in battlegrounds and arenas**, detected via `IsInInstance()` (`pvp`/`arena`). The guard covers both native `DoEmote` and player-written `/e`, without deleting settings or consuming cooldowns. It leaves normal world and dungeon behavior unchanged. This is a preventive workaround, not a bypass of protected APIs, and **has not been retested in a live battleground**. This mitigation is being prepared for prompt distribution because the current release can generate protected-action errors; remaining compatibility uncertainty must remain visible. Manual player emotes are not changed.

## What's new in 0.4.0-beta

The expanded interface recovered from Babuni's earlier local work is now prepared for its first public release:

- An **810×676** multi-page window with an overview of configured abilities, spell icons, summaries and individual enable/disable switches.
- A **categorized spellbook-style ability picker** with search; search also works in the configured-ability overview and the emote selection list.
- An **emote editor** with native client emotes, custom `/e` text and a separate **0–120-second cooldown for each selected emote**.
- Retained per-ability chance (0–100%), character-wide enable switch and additional `/ffsh` command.
- Migration from older boolean emote selections and the previously fixed first-cast cooldown, saved-data validation and spellbook filtering.

## Current status and compatibility

- **In-game report (November 5, 2026):** Babuni installed and used the expanded development build in WoW Forever and confirmed that it works well. This is a general hands-on confirmation, **not an exhaustive test report** for failed casts, every secure action path, character switching or all other addon combinations.
- **Automated checks:** GitHub runs Lua syntax and mocked gameplay/UI regressions, static package inventory, and an **upload-disabled** packager ZIP inspection. Tests are not substitutes for the game client.
- **Publication:** `v0.4.0-beta` was tagged and its CurseForge Beta upload was observed Processing. Final approval was not independently rechecked here. The PvP guard is prepared for `v0.4.1-beta`, not part of the previously tagged `v0.4.0-beta`. A new tag and CurseForge file have not yet been verified.
- **Target:** Forever `1.60.1` / interface `16001`. No Retail, Classic or other client is supported.

## Installation and controls

Install from [FlourishForever on CurseForge](https://www.curseforge.com/wow/addons/flourishforever) when a Forever-specific file is available, or put the following runtime files into `World of Warcraft/_forever_/Interface/AddOns/FlourishForever/`:

```text
FlourishForever/
├── FlourishForever.toc
├── FlourishForever_Storage.lua
├── FlourishForever.lua
└── FlourishForever_ActionEmotes.lua
```

Restart WoW when first installing; open the configuration with `/flourish`. New characters have no configured abilities, so the addon does not emote automatically until the player selects one.

| Command | Purpose |
| --- | --- |
| `/flourish`, `/flourish config`, `/flourish ui` | Open or close the expanded editor |
| `/flourish status` | Inspect current profile and configured ability count |
| `/flourishforever`, `/rit`, `/ffsh` | Alternative aliases |

### How emote triggers differ

**Native emotes** use the player's `UNIT_SPELLCAST_SUCCEEDED` event and `DoEmote`, so they follow reported successful casts, not confirmed target hits. **Custom `/e` text** is attempted from the player's action-button/spell press using a chat API; it can therefore appear even if the following cast is interrupted or fails. This tradeoff is preserved from the recovered implementation and requires care when testing different action bindings and macros.

Each enabled emote has its own cooldown; the chosen emote's timestamp is kept in memory and resets after `/reload` or relog. Chance is per configured ability. Character profiles use `UnitGUID("player")` within account-wide `FlourishForeverStorage`; older boolean emote selections are converted to cooldown entries. **Back up SavedVariables before switching between the old and expanded versions**, as the saved configuration format differs.

## Development and verification

```bash
luac -p FlourishForever_Storage.lua
luac -p FlourishForever.lua
luac -p FlourishForever_ActionEmotes.lua
lua tests/test_action_emotes.lua
lua tests/test_ui_mock.lua
python3 tests/check_package_layout.py
```

The GitHub pull-request workflow also performs a BigWigs packager dry run (`-d -g 1.60.1`) and verifies the resulting ZIP through `tests/check_packaged_zip.py`. The expected packaged content is three Lua modules, one TOC, the changelog and MIT license; development docs, tests and portfolio artwork are excluded. The ZIP and actual CurseForge publication are separate checks.

## License and project history

Source code is covered by the [MIT license](LICENSE). WoW game content remains Blizzard's property. Babuni provides creative direction, earlier Babunigaming credit is preserved, and AI technical contributions are recorded separately.

[Concept](CONCEPT.md) · [Roadmap](ROADMAP.md) · [Changelog](CHANGELOG.md) · [Architecture](docs/ARCHITECTURE.md) · [Design](docs/DESIGN.md) · [Decisions](docs/DECISIONS.md) · [Development journal](docs/DEVLOG.md) · [Recovery notes](docs/EXPANDED_UI_MERGE.md) · [Project instructions](AGENTS.md)
