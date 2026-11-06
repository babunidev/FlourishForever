# FlourishForever

**WoW Forever only** · **Interface:** `16001` · **Unreleased development:** `0.4.3-beta-dev` trigger-selection branch  
**Latest confirmed Git tag:** `v0.4.3-beta` · **Creative:** Babuni · **Portfolio:** [babuni.dev](https://babuni.dev)

Flourish Forever links player-selected abilities to native or custom emotes, with per-ability chance, per-emote cooldowns and per-character settings. It does not cast abilities automatically.

## 6 November 2026 — Emote search and battleground diagnostics (unreleased)

A report identified that searching the emote editor for `ROAR` did not reliably find the emote when its displayed alias differed. Search now indexes **both the canonical emote token** (e.g. `ROAR`) **and the displayed slash command** (e.g. `/rawr`), without changing the label or stored choice. A mocked UI regression tests both queries and confirms unrelated entries are hidden.

For the new **Button press** trigger and battleground Success-to-press fallback, an ability's usability check was too restrictive: cooldown, global cooldown and unavailable spells can report unusable although the player really pressed the button. Button press now follows the configured player action hook, while chance and per-emote cooldown continue to limit output.

**Battleground behavior is not yet solved or confirmed.** Native `C_ChatInfo.PerformEmote` is restricted, and chat lockdown may prevent any addon-sent emote even on a hardware press. The development build now provides a read-only `/flourish debug` command showing the actual client instance type, chat-lockdown status, Chat/PvPMatch restriction states, press-hook/outcome counts, emote attempts, accepted/refused API calls and last suppression reason. No player GUID or name is included, the counters are session-only, and no automatic chat logging occurs. If actual chat lockdown is active, Flourish will stay silent rather than bypass the game's protections.

**Testing:** This is an instrumented hypothesis and search correction, not a verified battleground workaround. Run `/flourish debug` after attempting a configured press-triggered ability in a battleground and compare with an overworld test. Addon Lua can normally be reloaded using `/reload` after files are copied; a full game restart is not generally required.

## Triggered by — per-ability timing (development)

Each ability has a **Triggered by** dropdown beside the **Chance** slider:

- **Success** (default, including existing saved abilities): attempts a native emote on the player's `UNIT_SPELLCAST_SUCCEEDED` event. A resisted hit can still be a successful cast.
- **Button press:** attempts the emote during a player button/action hook, without waiting for a cast result.
- **Failure:** attempts a native emote on player `UNIT_SPELLCAST_FAILED`, `UNIT_SPELLCAST_FAILED_QUIET` or `UNIT_SPELLCAST_INTERRUPTED`. Not every unusable button attempt yields a cast-failure event.

**Battleground/arena safety:** an ability saved with Success temporarily uses Button press while `IsInInstance()` reports `pvp` or `arena`. The saved selection never changes. If Forever reports actual chat lockdown, no emote is sent. Explicit Failure remains Failure, but asynchronous failures are suppressed during PvP restrictions. A PvPMatch addon restriction by itself is not treated as chat lockdown for genuine player press; whether Forever permits a native emote in every PvP state must be tested in-game.

**Custom `/e` limitation:** Forever requires a hardware event for custom chat emotes. Custom text is therefore available with **Button press** (also the automatic PvP fallback), but cannot be emitted from the asynchronous Success or Failure event. For outcome modes, the engine considers only selected native tokens, leaving custom selection and cooldown preferences intact. No delayed chat retry or protected-action bypass is attempted.

The dropdown is character-specific per ability and does not change chance, cooldowns, emote lists or the recovered editor. It is **implemented for local testing only**; neither new public tag nor game-client verification exists yet.
## Group-play emotes restored — 0.4.3-beta

A player report after `v0.4.2-beta` found that Flourish was silent while grouped. Review found an overly broad restriction check: the addon treated `Map`, `Encounter` and `ChallengeMode` *addon data restrictions* as a blanket prohibition on player-triggered emotes. The 0.4.3-beta candidate allows emotes in outdoor parties, party dungeons and raids while those unrelated restriction types are active.

**Security remains enforced:** the addon still suppresses output when Forever reports actual chat messaging lockdown, an activating/active `Chat` or `PvPMatch` restriction, or a battleground/arena instance. It does not attempt to bypass protected actions. If the game reports genuine chat lockdown while grouped, automatic emotes remain silent rather than causing another blocked-action error.

The same settings, action-press native/custom emotes and cooldowns are retained. Mocked tests cover party/raid scenarios. **Babuni reports that the updated build now seems to work fine in-game.** The report does not identify every tested group or instance type, and exhaustive dungeon/raid security cases remain unverified. A disabled addon, individual ability settings, unavailable action hooks or server rejection may also cause silence, and cannot be ruled out from the report alone.

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

Install the latest available Forever file from [CurseForge](https://www.curseforge.com/wow/addons/flourishforever). Version `0.4.3-beta` is prepared but has not yet been confirmed there. The game addon directory `_forever_/Interface/AddOns/FlourishForever/` must contain `FlourishForever.toc`, `FlourishForever_Storage.lua`, `FlourishForever.lua`, and `FlourishForever_ActionEmotes.lua`.

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
