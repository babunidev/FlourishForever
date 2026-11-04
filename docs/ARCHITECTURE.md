# Flourish Forever — technical architecture

**Static inspection:** FlourishForever_Storage.lua (84 lines), FlourishForever.lua (30 lines), FlourishForever_ActionEmotes.lua (554 lines), TOC and `.pkgmeta`, October 27, 2026. No actual game or automated test executed.

## Installed load sequence

```text
FlourishForever.toc
   Interface: 16001 / Version: 0.3.1-beta
   SavedVariables: FlourishForeverStorage (account-wide)
   1. FlourishForever_Storage.lua       => bind current character profile
   2. FlourishForever.lua               => slash command dispatch
   3. FlourishForever_ActionEmotes.lua  => spellbook/emote discovery, config UI, cast event
```

All three scripts rely on the client global Lua environment and Blizzard UI templates. No external library, network endpoint, data exporter or sound asset directory is bundled.

## Storage model and migration

```text
FlourishForeverStorage = {
  profiles = {
    ["<UnitGUID(player)>"] = {
       actionEmotesEnabled = true,
       instances = {
          ["<lowercased trimmed spell name>"] = {
             name = "...",
             spellID = number,
             chance = 100,        -- UI slider 0..100
             cooldown = 6,        -- UI slider 0..120 seconds
             emotes = { ROAR = true, OTHER_TOKEN = true }
          }
       }
    }
  }
}
FlourishForeverDB = currentCharacterProfile  -- runtime alias, not TOC root
```

`FlourishForever_BindCharacterDB` calls `UnitGUID("player")`, binds an existing `profiles[guid]` or creates it, and assigns the alias. It executes on **PLAYER_LOGIN** and also on every `EnsureDB` access so a late GUID can be bound before later edits.

If the new root isn't a table, `AdoptPreviousStorage` can use an already loaded **ROARitFOREVERStorage** global. If a GUID profile isn't found, `LegacyKeys` tests an earlier plain **name** key and (when client returns one) an old **name-realm** form, migrates the found table to GUID and removes that old key. The source comment explicitly calls Forever **realmless**; legacy name-realm shapes are backward-compatibility only. It does not automatically read another addon SavedVariables file that the client never loaded, and does not merge two profile roots when both exist.

`EnsureDB` initializes master switch true, instances table, and missing per-ability name/chance/cooldown/emote defaults. It only `tonumber`s stored values; out-of-range numeric values aren't clamped during this normalization.

## Spellbook and emote enumeration

On config frame **OnShow**:
1. `RefreshKnownAbilities` attempts `C_SpellBook.GetNumSpellBookSkillLines` and related current-client routines; if absent it falls back to `GetNumSpellTabs/GetSpellTabInfo/GetSpellBookItemInfo`.
2. It collects entries with a real spell ID, removes duplicate **IDs**, filters passives via `C_Spell.IsSpellPassive` or legacy `IsPassiveSpell`, then sorts by name and ID.
3. `RefreshKnownEmotes` enumerates global names matching **`^EMOTE%d+_TOKEN$`**, retains distinct uppercase token values, adds `ROAR` if unavailable, and sorts the list.
4. For UI labels, `GetEmoteSlashCmd(token)` is used if available, otherwise `"/"..lower(token)`.

Ability configurations are keyed by **`AbilityKey(name)=lowercase(trim(name))`**, not by ID. Two ranks or alternate spell IDs with the same name intentionally converge on the same key because the event spell ID is resolved back to name before lookup. This is observable behavior; whether every same-name collision is desirable is an open decision.

## Cast-success dispatch

```text
UNIT_SPELLCAST_SUCCEEDED(unit, _, spellID)
  if unit != "player" or no spellID: stop
  GetSpellNameByID(spellID) -> AbilityKey()
  EnsureDB / db.actionEmotesEnabled?
  db.instances[key] exists?
  now = GetTime()
  last = lastFireByAbility[key] or 0
  if now-last < cfg.cooldown: stop
  if random(1,100) > cfg.chance: stop
  pool = all truthy entries in cfg.emotes
  if pool empty: stop
  token = pool[random(1,#pool)]
  lastFireByAbility[key] = now
  DoEmote(token)
```

The source registers **UNIT_SPELLCAST_SUCCEEDED** and **SPELLS_CHANGED** only. It does not observe actual damage hits, resist outcomes or target effects, and does not cast an ability automatically. It queues no retries when a chance fails.

Cooldown is **per normalized ability key** and only advances after a successful emote choice. The dictionary is **local session memory**; `/reload` and relog clear it. A small source-level edge case: the first spell cast when `GetTime() < cooldown` may be suppressed, because missing `lastFireByAbility` defaults to **0** rather than an unbounded-past timestamp.

The code sets lastFire **before** calling `DoEmote`, with no return-status check. An unsupported emote token may still consume cooldown even if the client doesn't visibly play it. The source doesn't include its own extra spam filter or cross-addon synchronization.

## Configuration UI

`CreateUI` creates one lazy **620×520** movable `BasicFrameTemplateWithInset` frame with title Flourish Forever, a master enable checkbox, spellbook dropdown, scrollable left list of configured abilities, Remove button, and selected ability editor on right.

Editor uses **two whole-number sliders** (chance 0–100 and cooldown 0–120) and scrollable checkboxes for discovered emote tokens. The user's checkbox choices directly update `db.instances[key].emotes`. If all entries are unchecked, `PickRandomEmote` returns nil and the cast remains silent.

The frame calls `RefreshKnownAbilities/RefreshKnownEmotes` on show; `SPELLS_CHANGED` refreshes spellbook data only if the window is currently open. The code attempts `C_AddOns.LoadAddOn("Blizzard_UIDropDownMenu")` when needed but still presumes the dropdown templates/functions are subsequently available. Some alternative Forever client builds may not supply all globals.

A slash-only UI hook `FlourishForever_OpenConfig` toggles that frame, and `FlourishForever_ActionStatus` returns master switch and configured-ability count. `/flourish status` also prints the storage module's GUID-bearing diagnostic status. Three aliases are registered: `/flourish`, `/flourishforever`, `/rit`.

## Risks, tests and publication evidence

**The October 27 source snapshot contained no tests or CI.** A subsequent development change added a static package-file inventory guard under `tests/`, but there is still no automated gameplay regression test or CI workflow. GitHub published tags/releases [v0.3.0-beta](https://github.com/babunidev/FlourishForever/releases/tag/v0.3.0-beta) and [v0.3.1-beta](https://github.com/babunidev/FlourishForever/releases/tag/v0.3.1-beta), each with **zero uploaded assets**. `.pkgmeta` is CurseForge-packager metadata, not itself test evidence.

The repository also has **no LICENSE** in its main tree. Exact target client event payloads, slider persistence and emote output still require **actual in-game tests**.

## Related development history

Flourish Forever is the October 2026 WoW Forever expression of the action-emote idea. Unlike the earlier action-slot hooks, it responds to the player’s **reported successful spellcast** event and lets the player select spellbook abilities and existing client-native emotes in a GUI. Each new ability initially has ROAR selected, but the player may choose other available emote tokens. This is client-token selection rather than creation of arbitrary new emotes, and cast success does not prove a landed hit. See the [source-grounded expressive-addon timeline](EMOTE_FAMILY_HISTORY.md) for related projects and historical boundaries.
