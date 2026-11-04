# FlourishForever

**World of Warcraft: Forever only** · **TOC interface:** `16001` · **Latest GitHub version:** `0.3.1-beta`  
**Creative direction:** Babuni · **Portfolio:** [babuni.dev](https://babuni.dev) · **Earlier project credit:** Babunigaming

FlourishForever lets a character express themselves through ordinary ability casts. Choose a spellbook ability, select the game-native emotes it may trigger, and configure that ability's chance and cooldown. The addon listens for a **successful cast event**, not a confirmed damage hit. It never casts an ability for the player.

## Current status

- **Beta-tested:** Babuni used the existing addon successfully throughout the WoW Forever beta, including its intended features.
- **Forever launch:** Blizzard announced November 4, 2026, at 23:00 UTC (November 5, 00:00 CET). Launch-client compatibility still requires confirmation; successful beta use is not a launch-client test.
- **Public files:** [CurseForge](https://www.curseforge.com/wow/addons/flourishforever) currently lists `v0.3.0-beta` for Forever `1.60.1`. The latest [GitHub release](https://github.com/babunidev/FlourishForever/releases/tag/v0.3.1-beta) is `v0.3.1-beta` and has no attached binary ZIP.
- **Development:** Packaging improvements are merged into `main`. First-cast cooldown, SavedVariables and spellbook fixes are implemented and tested offline in [draft PR #2](https://github.com/babunidev/FlourishForever/pull/2), **not merged or publicly released**.

## Installation

Install the Forever-specific file using the [CurseForge addon page](https://www.curseforge.com/wow/addons/flourishforever), or place these four files in `World of Warcraft/_forever_/Interface/AddOns/FlourishForever/`:

```text
FlourishForever/
├── FlourishForever.toc
├── FlourishForever_Storage.lua
├── FlourishForever.lua
└── FlourishForever_ActionEmotes.lua
```

Restart the game, enable **Flourish Forever**, and enter `/flourish`.

The GitHub **source archive is not an installable CurseForge package**: it also includes development documents, tests and portfolio artwork. The repository's [`.pkgmeta`](.pkgmeta) excludes those project-only files from **future generated CurseForge packages**. A changelog and [MIT license](LICENSE) may accompany the four runtime files. The [static package inventory test](tests/check_package_layout.py) checks this intended layout, but the actual next CurseForge ZIP still needs inspection.

## Features and controls

- Select non-passive abilities from the player's spellbook. A new character starts with **no abilities configured**; the master switch alone never causes unsolicited emotes.
- Give each ability its own **chance (0–100%, default 100%)** and **emote cooldown (0–120 seconds, default 6 seconds)**. Cooldown applies between fired emotes and does not modify the spell's game cooldown.
- Choose one or several built-in game emotes; one enabled token is selected randomly when a cast qualifies. A new ability initially allows **ROAR**, but that selection is editable. An empty emote pool stays silent.
- Save settings separately for each character in the account-wide `FlourishForeverStorage` SavedVariables root. The runtime cooldown timer resets on `/reload` or a new session.

| Command | Purpose |
| --- | --- |
| `/flourish`, `/flourish config`, `/flourish ui` | Open/close settings |
| `/flourish status` | Show profile and configuration status |
| `/flourishforever`, `/rit` | Alternative command aliases |

**Important:** The success event `UNIT_SPELLCAST_SUCCEEDED` does not prove that a target was hit. Settings are keyed by normalized spell **name**; matching names or language changes can affect how configurations map to abilities. `/flourish status` can show the character GUID in chat; redact it from publicly shared screenshots.

## Compatibility and testing

The current public source retains the beta-tested `DoEmote` and `UNIT_SPELLCAST_SUCCEEDED` behavior. Draft PR #2 deliberately keeps those APIs unchanged while addressing edge cases. Its GitHub Lua 5.4 regression workflow passed, and Babuni also ran Lua syntax and mocked regression checks successfully on Nobara Linux. **Mocks are not in-game proof.**

The merged packaging check runs from the repository root using:

```bash
python3 tests/check_package_layout.py
```

After checking out draft PR #2, the offline Lua checks can be run with:

```bash
luac -p FlourishForever_Storage.lua
luac -p FlourishForever.lua
luac -p FlourishForever_ActionEmotes.lua
lua tests/test_action_emotes.lua
```

In-game validation remains necessary for the development fixes, the config UI, multiplayer emotes and RoarForever coexistence.

## License, history and project records

The addon source is distributed under the [MIT License](LICENSE), consistent with the existing CurseForge listing. WoW's emotes, animations, sounds and other Blizzard assets remain their respective owners' property. Historical credit to Babunigaming is preserved; Babuni is the human creative directing the project, while AI contributions are recorded separately.

[Concept](CONCEPT.md) · [Roadmap](ROADMAP.md) · [Changelog](CHANGELOG.md) · [Architecture](docs/ARCHITECTURE.md) · [Decisions](docs/DECISIONS.md) · [Development journal](docs/DEVLOG.md) · [AI collaboration](docs/AI_COLLABORATION.md) · [Project instructions](AGENTS.md) · [Portfolio assets](assets/portfolio/README.md)
