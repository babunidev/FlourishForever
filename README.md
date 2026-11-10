# Flourish Forever

**World of Warcraft Forever only** · **Interface:** `16001` · **Creative:** Babuni · **License:** [MIT](LICENSE)

Flourish Forever adds personality to your character's abilities. Choose a spell or action, attach one or more Warcraft emotes or custom `/e` lines, and decide when and how often a flourish should appear. The addon handles the expression; **it never casts abilities for you**.

## How it works

Each configured ability has its own chance setting and trigger choice:

- **Success** — react when the selected action succeeds, where the client exposes an eligible result.
- **Button press** — attempt the flourish from an eligible player action.
- **Failure** — react to supported unsuccessful outcomes.

Choose native emotes or custom text, search for emotes by command or displayed name, and adjust each selection's duration. When an emote is chosen, **its duration locks that ability** against another flourish until the time expires; a different ability has its own lock. A short giggle might last three seconds, while a dramatic roar could keep the same ability quiet for twenty.

The setting is 0–120 seconds per emote and 0–100% chance per ability. Character profiles persist across logins, and the chosen ability lock survives `/reload`.

## Open the editor

| Command | Action |
| --- | --- |
| `/flourish`, `/flourish ui`, `/flourish config` | Open or close the editor |
| `/flourish status` | Show current profile status |
| `/flourishforever`, `/rit`, `/ffsh` | Command aliases |

The editor includes a searchable ability list, spellbook picker, enable switches, emote choices, custom text and duration/chance controls. New characters begin with no abilities configured.

## Installation

Get the latest **confirmed available** Forever package from [CurseForge](https://www.curseforge.com/wow/addons/flourishforever). For manual installation, place these files together in `_forever_/Interface/AddOns/FlourishForever/`:

```text
FlourishForever.toc
FlourishForever_Storage.lua
FlourishForever.lua
FlourishForever_ActionEmotes.lua
```

The saved profile is `FlourishForeverStorage`. Existing per-character selections are migrated rather than discarded when the data format changes.

## Status and important limitations

A **0.5.0-beta release candidate** was prepared, with per-ability trigger choices, searchable native emotes and the chosen-emote ability-lock behavior. The creative confirmed the revised lock in the Forever client on **7 November 2026**, and automated Lua/UI checks and a local packaging preview passed. **Tag publication and CurseForge approval must be verified separately**; a prepared release is not proof of a published file. The last public tag confirmed in that preparation record was `v0.4.3-beta`.

Forever places restrictions on automated chat. Custom `/e` text remains tied to eligible hardware presses; native emotes can also be blocked by actual chat lockdown. Battleground and arena fallback behavior is not fully verified in-game. Do not assume a successful mock test means that protected-action behavior works in every game context.

The long sequence of cooldown investigations, false API-return cases and replaced designs has been moved out of this introduction into [dated development and release notes](docs/RELEASE_DEVELOPMENT_NOTES.md). The [changelog](CHANGELOG.md) and [test record](docs/DEVLOG.md) retain further evidence.

## For development

```sh
luac -p FlourishForever_Storage.lua
luac -p FlourishForever.lua
luac -p FlourishForever_ActionEmotes.lua
lua tests/test_action_emotes.lua
lua tests/test_ui_mock.lua
python3 tests/check_package_layout.py
```

CI checks a packaging preview, but an upload-disabled dry run is **not** a verified CurseForge release. The package is intended to include its TOC, three runtime Lua files, changelog and license.

## Read more

| Topic | Document |
| --- | --- |
| Creative purpose and future direction | [Concept](CONCEPT.md) · [Roadmap](ROADMAP.md) |
| Layout, implementation and interfaces | [Design](docs/DESIGN.md) · [Architecture](docs/ARCHITECTURE.md) |
| What changed and why | [Changelog](CHANGELOG.md) · [Decisions](docs/DECISIONS.md) |
| Experiments and earlier interpretations | [Development notes](docs/RELEASE_DEVELOPMENT_NOTES.md) · [Development journal](docs/DEVLOG.md) |
| Contributing and attribution | [AGENTS.md](AGENTS.md) · [AI collaboration](docs/AI_COLLABORATION.md) |

The game supplies the original emote assets. Babuni directs the concept; documented AI assistance does not transfer authorship of that creative direction.
