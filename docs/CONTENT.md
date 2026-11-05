# Flourish Forever — emote vocabulary, character settings and assets

## Expanded UI development content

Search covers configured ability names, spellbook names, and native/custom emote labels. User-defined emote text is kept in per-character storage using stable `c:` token IDs. No third-party assets or new runtime dependencies were added in this branch. See [merge notes](EXPANDED_UI_MERGE.md).


**Creative direction:** Babuni · **Portfolio:** babuni.dev · **Platform:** WoW: Forever interface 16001.  
**Evidence:** `FlourishForever_ActionEmotes.lua`, storage module, TOC and release records.

## What is configurable content?

This addon has **no custom prose library** and no manually authored class dialogue lines. It binds two kinds of game-provided content:

| Content | Source | Persistence |
| --- | --- | --- |
| Ability display names, IDs | Client `C_SpellBook`/legacy spellbook APIs | Config records last selected spellID and name |
| Spell cast event | `UNIT_SPELLCAST_SUCCEEDED` from client | Not stored as a log |
| Emote tokens | `EMOTE%d+_TOKEN` globals + ROAR fallback | Each configured spell has enabled token set |
| Native emote animation/chat | `DoEmote(token)` | Determined by game, not stored in addon |
| Chance and cooldown settings | Slider input | Saved by character profile |
| Last emote-fire timestamp | `GetTime()` table | **Session-only**; resets on reload/relog |

Emotes are **discoverable from the installed client** rather than hardcoded as a fixed number of choices. A client update may change how many tokens appear, which ones have a slash command, or how specific gestures display on an individual character.

The result is a single native game emote each time a configured ability's chance and cooldown conditions are met. The source calls `DoEmote(token)`; it does not generate sentences, modify spell tooltips, attach sound files or alter game combat mechanics.

## Defaults and saved profiles

The TOC has **`SavedVariables: FlourishForeverStorage`**. Its root includes a `profiles` table indexed by **player character GUID**. That choice matches the realmless Forever client identity model rather than relying on identical first names or any supposed separate-realm collision behavior.

Each profile stores:
- `actionEmotesEnabled`, default **true**.
- `instances` map keyed by a trimmed lowercase **spell name**, initially empty.
- Per instance: `name`, `spellID`, `chance` (default **100**), `cooldown` (default **6**), `emotes` enabled-token map (default **ROAR=true**).

The `instances` field name is a historical code key; it does **not** imply instance or dungeon-specific settings. Configuration is by character and ability-name, not by WoW dungeon, raid, zone or server realm.

Older `ROARitFOREVERStorage` may be adopted if already loaded. Legacy character profiles may also have been stored under plain name or name-realm keys; current code moves a matching old table to the character's GUID key when needed. Do not assume a removed addon automatically loads its old variables for migration.

**Not saved:** last emote timestamp, every cast event, a chat transcript, cooldown between logout/reloads, party-member identity, target information or cross-player communications.

## Commands and UI text

- `/flourish`, `/flourishforever`, `/rit` with `config`, `ui`, and `status`.
- Window title **Flourish Forever**.
- Labels **Enable ability emotes**, **Add ability**, **Configured abilities**, **Emotes (one is chosen at random)**, **Chance**, **Cooldown**, **Remove**.
- Status prints master enabled state, configured ability count, and a **GUID-bearing** profile reference.

The source relies on English UI strings and fallback emote labels, with game-global tokens/spell names potentially localized. There is no dedicated localization table, translated settings copy, or runtime icon bundle. Portfolio artwork is stored separately under `assets/portfolio/`.

## Content provenance and rights

The runtime consists of **three Lua files** and a TOC. The repository also contains `.pkgmeta`, project documentation, and creator-supplied promotional artwork under `assets/portfolio/`. See the [asset index](../assets/portfolio/README.md) and [manifest](../assets/portfolio/manifest.json). These promotional images are not loaded by the addon. No sound library or runtime dependency was added. Current main contains the development-only static package inventory test under `tests/`; the release-preparation branch also has mocked Lua tests and package ZIP checks. All tests are excluded from the installable addon by `.pkgmeta`.

The original text names **Babunigaming** as the developer; October 26 metadata credited **Babuni.dev** as the public byline. Babuni is the human creative, and babuni.dev the portfolio. WoW emote animations and client assets belong to their rightsholders. The prepared release candidate includes an MIT `LICENSE`, matching CurseForge's pre-existing declaration. That source license does not relicense Blizzard's game assets.

## Related development history

Flourish Forever is the October 2026 WoW Forever expression of the action-emote idea. Unlike the earlier action-slot hooks, it responds to the player’s **reported successful spellcast** event and lets the player select spellbook abilities and existing client-native emotes in a GUI. Each new ability initially has ROAR selected, but the player may choose other available emote tokens. This is client-token selection rather than creation of arbitrary new emotes, and cast success does not prove a landed hit. See the [source-grounded expressive-addon timeline](EMOTE_FAMILY_HISTORY.md) for related projects and historical boundaries.
