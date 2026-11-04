# Flourish Forever

**Creative direction:** Babuni · **Portfolio:** babuni.dev (earlier project credit: Babunigaming)  
**Version:** **0.3.1-beta** · **Game:** World of Warcraft: Forever · **Interface:** 16001  
**GitHub releases:** [0.3.1-beta](https://github.com/babunidev/FlourishForever/releases/tag/v0.3.1-beta) and [0.3.0-beta](https://github.com/babunidev/FlourishForever/releases/tag/v0.3.0-beta)

**Flourish Forever gives player-selected abilities a little character.** Choose non-passive abilities from the spellbook, assign each a pool of familiar game emotes, and control how often an emote can appear. On the player's `UNIT_SPELLCAST_SUCCEEDED` event, the addon may call `DoEmote` with one randomly selected enabled token.

**Important distinction:** the event means the client reported a successful **spellcast**, not necessarily a successful **hit, damage event, or effect landing on a target**. Earlier release wording said “when that ability lands”; the actual trigger is cast success. Failed/interrupted casts do not explicitly trigger this handler.

## Installing

Copy this repository's **FlourishForever** addon files into the folder `Interface/AddOns/FlourishForever/`:

```text
Interface/AddOns/FlourishForever/
    FlourishForever.toc
    FlourishForever_Storage.lua
    FlourishForever.lua
    FlourishForever_ActionEmotes.lua
```

Restart WoW, enable **Flourish Forever** in the addon list, and type `/flourish`. The TOC is built for the Forever **16001** interface, not a generic Vanilla 1.12 client. The two GitHub beta release entries **have no uploaded ZIP or binary assets** in their release metadata. Download the individual runtime files for manual installation, or use the Forever file on CurseForge. A GitHub **source** ZIP is not the same as a CurseForge **addon** ZIP: source archives also contain project documentation, portfolio artwork and tests.

The [`.pkgmeta`](.pkgmeta) excludes `assets/`, `docs/`, `tests/`, `AGENTS.md`, `CONCEPT.md`, `README.md` and `ROADMAP.md` from **future CurseForge-packaged downloads**. It retains `CHANGELOG.md` for the packager's manual release notes. Hidden metadata such as `.pkgmeta` is excluded by the packager automatically. The development-only check `python3 tests/check_package_layout.py` verifies the expected file list locally, **not** an actual CurseForge ZIP. The existing published beta file was built from an earlier repository revision; verify the next package before publishing.

## Configuring the experience

The movable Blizzard-style config window (approximately **620×520**) provides:

1. **Enable ability emotes** — one switch for the current character; defaults **on**, but does nothing until at least one ability is configured.
2. **Add ability** — choose a non-passive spell from the client spellbook list. A configured ability appears on the left; click it to edit or remove it.
3. **Chance** — an independent whole-number **0–100%** chance for each ability; defaults **100%**. A failed chance roll **does not consume cooldown**.
4. **Cooldown** — an independent **0–120-second** minimum interval *between fired emotes* for each configured ability; defaults **6 seconds**. It is an addon rate limit, **not** an alteration to the game's actual spell cooldown.
5. **Emotes** — check any available game emote tokens in the right-hand scroll list. On a qualifying cast, one enabled emote is chosen at random. New entries start with only **ROAR** enabled. With no emotes checked, **nothing plays**, even if the chance succeeds.

The emote options come from the current client's `EMOTE*_TOKEN` globals, with **ROAR** added as a fallback. The addon uses the game's existing `DoEmote` behavior, not custom emote sentences or a proprietary sound pack. The actual tokens and animation/sound effects can vary by client, race and context.

The configuration uses **normalized spell names** as keys, not spell IDs: the current display name is lowercased and trimmed for matching. Rank variants or spells with the same localized name may share one configuration. Different client languages may change the name used for matching.

## Commands

| Command | Behavior |
| --- | --- |
| `/flourish`, `/flourish config`, `/flourish ui` | Open or close the configuration window |
| `/flourish status` | Print saved-storage status, master switch and number of configured abilities |
| `/flourishforever` | Full alias; supports the same arguments |
| `/rit` | Additional short alias present in source; supports the same arguments |

The `status` command currently includes a **character GUID** in the chat line when available. Consider that diagnostic output private if sharing screenshots/logs.

## Saved versus session-only behavior

The TOC declares account-wide **`FlourishForeverStorage`**, but its `profiles[UnitGUID("player")]` map provides a separate profile for each character. A profile saves `actionEmotesEnabled`, and per-name `instances` with ability name, latest spell ID, chance, cooldown and a table of enabled emote tokens. The runtime alias `FlourishForeverDB` points to the active profile.

**Cooldown timestamps are not saved.** `lastFireByAbility` is a Lua table belonging to the current game session, so `/reload`, relogging or a restarted UI resets it. There is no account-wide shared cooldown and no persistent history of sent emotes.

On startup the storage module can adopt a **previously loaded `ROARitFOREVERStorage` global** when the new root is absent. It also tries moving a matching older **name** or **name-realm** profile into the current character GUID key. This is conditional code-level migration: simply uninstalling the former addon does **not** automatically make an old SavedVariables root load. Back up saved data before migration and test older installations on copies.

## Technical limitations and known review points

- **First-cast timing:** the code initializes an unseen ability's last-fire timestamp to **0**. If the client's `GetTime()` is still smaller than the configured cooldown (default 6 seconds), an otherwise eligible **first emote may be skipped**. This is a source-level edge case; it has not been reproduced in game in this audit.
- **Chance/cooldown boundaries:** normal slider input is limited to 0–100 and 0–120; when loading modified/old saves the source converts values with `tonumber` but does **not clamp** them to these bounds. Test malformed saved data before assuming all entries always respect the UI limits.
- **Spellbook APIs:** the addon tries the current `C_SpellBook` API and a legacy `GetSpellBookItemInfo` fallback, and filters passives with `C_Spell.IsSpellPassive` or `IsPassiveSpell`. Unrecognized spellbook entries or unsupported localized names won't necessarily be configurable.
- **UI dependencies:** it tries loading `Blizzard_UIDropDownMenu` if needed. Missing dropdown globals/templates on a particular client could still prevent the window from building.
- **Testing:** a static packaging inventory check exists under `tests/`; there is still **no automated gameplay regression suite or CI workflow**. Source inspection and packaging checks cannot replace beta or release-client testing.
- **Licensing:** the inspected main tree contains **no LICENSE file**. No license should be invented or inferred from a public GitHub repository.

## Version story and portfolio documentation

The initial **0.3.0-beta** implementation was committed **October 22, 2026**, already including per-character GUID storage, the cast-success handler, spellbook list, emote checkbox pool, sliders and configuration UI. **0.3.1-beta**, committed the same day, adjusted TOC/changelog/version packaging **without changing the trigger implementation**. On October 26, documentation and author credits were standardized to **Babuni.dev**.

- [Creative concept](CONCEPT.md) · [Verification roadmap](ROADMAP.md) · [Version changelog](CHANGELOG.md)
- [Architecture](docs/ARCHITECTURE.md) · [Visual/interaction design](docs/DESIGN.md) · [Emotes and saved data](docs/CONTENT.md)
- [Decisions and alternatives](docs/DECISIONS.md) · [Narrative development journal](docs/DEVLOG.md) · [Human–AI collaboration](docs/AI_COLLABORATION.md) · [Developer rules](AGENTS.md)

The original expressive-addon idea and creative decisions belong to Babuni.dev. The October 27 documentation audit is AI-assisted **analysis and writing**, not an in-game validation or a gameplay-code change.

## Portfolio artwork

[Portfolio assets](assets/portfolio/README.md) include the creator-supplied logo, promotional showcase and smaller JPEG preview. [Asset manifest](assets/portfolio/manifest.json) provides paths and alt text for Babuni.dev.

## The longer history of ability emotes

Flourish Forever is the October 2026 WoW Forever expression of the action-emote idea. Unlike the earlier action-slot hooks, it responds to the player’s **reported successful spellcast** event and lets the player select spellbook abilities and existing client-native emotes in a GUI. Each new ability initially has ROAR selected, but the player may choose other available emote tokens. This is client-token selection rather than creation of arbitrary new emotes, and cast success does not prove a landed hit. The [comparative history](docs/EMOTE_FAMILY_HISTORY.md) traces the earlier Buxbrew experiments, fixed ROAR pools, multi-slot configurations, editable guild emote registries and related sound-restoration addons.
