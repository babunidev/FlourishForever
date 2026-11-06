# Flourish Forever — emote content, character settings and assets

**Creative direction:** Babuni · **Portfolio:** babuni.dev · **Target:** World of Warcraft Forever / interface 16001.  
**Public baseline:** v0.4.3-beta · **Development:** Success/press/failure choice per ability, pending in-game verification.

## Content sources

| Content | Source | Persistence |
| --- | --- | --- |
| Spell names, IDs, icons and categories | Player spellbook and spell APIs | Name/key/ID in configured abilities |
| Native emotes | Client `EMOTE*_TOKEN` globals, with ROAR fallback | Token-keyed selection and cooldown |
| Custom `/e` text | Player-authored text entered in the custom emote editor | `customEmotes` entries with stable IDs |
| Per-ability chance and enabled switch | Player configuration | Character profile |
| Per-emote cooldowns | Player configuration | Emote selection records |
| Actual last-fired times | Session `GetTime()` | **Not saved** across reload/relog |

## Per-ability trigger preference (development)

Each configured ability may include `trigger = "success"`, `"press"`, or `"failure"`. Older and malformed records normalize to `"success"` without deleting saved emote preferences. The value is per ability and per character, rather than global. Battleground/arena fallback is computed at runtime and is never saved.

Native tokens can be considered on success/failure events, but custom `c:id` /e text is only sent during a genuine hardware press. As a result, selecting only custom emotes with Success or Failure yields no automatic message in those contexts. The ability editor communicates this limitation; it is not evidence of a broken SavedVariables migration.
## Storage and defaults

The TOC declares `SavedVariables: FlourishForeverStorage`. Profiles are isolated by `UnitGUID("player")`, and configured abilities are keyed by normalized spell name. The base data shape is:

```lua
FlourishForeverStorage = {
  profiles = {
    ["<player GUID>"] = {
      actionEmotesEnabled = true,
      customEmotes = { { id = "1", text = "waves a tiny flag." } },
      instances = {
        ["<normalized spell name>"] = {
          name = "Spell Name",
          spellID = 123,
          enabled = true,
          chance = 100,
          cooldown = 6, -- retained migration/default value
          emotes = {
            ROAR = { cooldown = 6 },
            ["c:1"] = { cooldown = 12 },
          }
        },
      },
    },
  },
}
```

This is a structural illustration, not an actual character profile. A new character has no configured abilities. The first added ability starts with native ROAR selected; user-defined emotes are never assigned without explicit player choice.

Older `cfg.emotes[token] = true` entries are normalized into `{ cooldown = legacyAbilityCooldown }`; valid per-emote tables are retained. Unsupported SavedVariables records remain recoverable where possible. Stored cooldown preferences persist, but runtime last-fired timestamps do not.

Custom emotes have `c:`-prefixed saved references and text entries under `customEmotes`. Deleting or editing custom lines can affect assigned selections; the editor tries to preserve IDs where corresponding lines remain.

## Commands and actual output

- `/flourish`, `/flourishforever`, `/rit`, `/ffsh` open the UI; `/flourish status` gives the current diagnostic summary.
- **Native emotes (0.4.2-beta candidate):** attempted with `C_ChatInfo.PerformEmote(token)` only from a player-action hook. The public 0.4.1-beta instead calls `DoEmote` from cast-success, which has produced blocked-action errors.
- **Custom text:** sent as an `EMOTE` chat message during eligible player action-button hooks. It may fire even if the cast ultimately fails or is interrupted.
- The status diagnostic may print a character GUID. Do not post identifiable profile information in public examples.

## Assets, licensing and provenance

The installable addon includes a TOC, three Lua runtime files, changelog and the [MIT license](../LICENSE). Tests, documentation and [promotional artwork](../assets/portfolio/README.md) stay in the GitHub source repository, not the CurseForge package. No custom animation, texture, sound library or addon messaging dependency was added.

Creative direction belongs to Babuni; historical Babunigaming credit is preserved, and AI implementation work is documented separately. Blizzard-owned game assets remain Blizzard's property.
