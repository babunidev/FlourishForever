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

The spellbook's top-left book icon is the Flourish medallion. Click it to open or close the Flourish window. `/flourish` opens that same window.

The editor includes a searchable ability list, spellbook picker, enable switches, emote choices, custom text and duration/chance controls. New characters begin with no abilities configured.

## Installation

Get the latest **confirmed available** Forever package from [CurseForge](https://www.curseforge.com/wow/addons/flourishforever). For manual installation, place these files together in `_forever_/Interface/AddOns/FlourishForever/`:

```text
FlourishForever.toc
FlourishForever_Storage.lua
FlourishForever.lua
FlourishForever_ActionEmotes.lua
FlourishForever_SpellBook.lua
CHANGELOG.md
LICENSE
```

The saved profile is `FlourishForeverStorage`. Existing per-character selections are migrated rather than discarded when the data format changes.

## Status and important limitations

**0.6.1-beta** adds a Flourish medallion on the spellbook's top-left book icon. Clicking it opens the Flourish window. The previous public tag is `v0.5.0-beta`. A Git tag does not by itself prove the CurseForge file is published.

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
python3 tests/pack_test_zip.py --install
```

CI checks a packaging preview, but an upload-disabled dry run is **not** a verified CurseForge release. The package contains the TOC, the Lua files it names, the changelog and the license.

`python3 tests/pack_test_zip.py --install` writes `dist/FlourishForever-<version>-test.zip` from the files on disk, including uncommitted edits, and installs that package into the local Forever `Interface/AddOns` folder. Do this whenever the runnable addon changes locally, so the game copy stays current. The game folder receives that package only. This repository stays the working copy, outside the game folder.

## Read more

| Topic | Document |
| --- | --- |
| Creative purpose and future direction | [Concept](docs/CONCEPT.md) · [Roadmap](docs/ROADMAP.md) |
| Layout, implementation and interfaces | [Design](docs/DESIGN.md) · [Architecture](docs/ARCHITECTURE.md) |
| What changed and why | [Changelog](CHANGELOG.md) · [Decisions](docs/DECISIONS.md) |
| Experiments and earlier interpretations | [Development notes](docs/RELEASE_DEVELOPMENT_NOTES.md) · [Development journal](docs/DEVLOG.md) |
| Contributing and attribution | [AGENTS.md](AGENTS.md) · [AI collaboration](docs/AI_COLLABORATION.md) |

The game supplies the original emote assets. Babuni directs the concept; documented AI assistance does not transfer authorship of that creative direction.
