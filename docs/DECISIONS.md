# Flourish Forever — recorded design decisions and open alternatives

**Creative decision authority:** Babuni.dev. **Evidence:** initial October 22 source commit, beta packaging change, README, project conversation context and October 26 attribution/docs. Missing early discussion and game tests are not invented.

## Implemented decisions

| Evidence | Observable choice | Why it matters |
| --- | --- | --- |
| Oct 22 `b60d0802` | Use **selected ability cast success** as trigger | Player remains in control of the actual combat ability |
| Oct 22 `b60d0802` | Give each ability its **own chance, cooldown and allowed-emote set** | Dramatic actions needn't produce constant spam |
| Oct 22 `b60d0802` | Populate ability list from non-passive spellbook entries | No fixed global/class spell list, player curates |
| Oct 22 `b60d0802` | Use native `DoEmote` tokens; ROAR starter default | Expressive result relies on the game, not authored custom prose |
| Oct 22 `b60d0802` | Store settings by **character GUID** with legacy migration fallback | Supports the realmless character identity model and independent personalities |
| Oct 22 `b60d0802` | Use a movable Blizzard-themed **620×520** editor | Keep decision UI separate from ongoing combat |
| Oct 22 `56d8b67d` | Bump to **0.3.1-beta** for CurseForge packaging; runtime Lua unchanged | Distribution update isn't a new feature or proof of testing |
| Oct 26 `61c7aadd`, `7e36f715` | Standardize displayed creator credit from Babunigaming to Babuni.dev | Preserve prior creative identity and actual project authorship |

The code and commit messages do not prove the full initial brainstorming, all alternatives or which tool generated each earlier code line.

## November 4, 2026 — approved maintenance boundary

Babuni confirmed that Flourish Forever worked across its intended features during the Forever beta, authorized targeted architectural/code fixes, and asked to preserve functioning APIs rather than replace them speculatively. The development patch therefore keeps `UNIT_SPELLCAST_SUCCEEDED`, `DoEmote`, spell-name configuration and character GUID storage. It fixes first-cast cooldown handling, bounds saved configuration, and filters non-castable spellbook entries. Mock tests and CI are development checks; the patch is **not** an in-game-tested or publicly approved release.

## Source-level tradeoffs

**Cast success versus damage hit:** The original introductory text said “when that ability lands.” The actual implementation observes **UNIT_SPELLCAST_SUCCEEDED**. That avoids parsing combat damage/target effects but may emit a flourish even when a cast later misses, is resisted or has no meaningful target hit. No new trigger is approved.

**Name-key versus ID-key:** The event carries a spell ID and the UI lists spellbook IDs, but saved configurations are keyed by **normalized spell name**. This can make multiple ranks share one expressive identity, while risking same-name collisions and localization-induced mismatches.

**Independent cooldowns versus global social volume:** Every configured ability has its own timestamp; there is no overall emote budget. That respects distinctive spell personalities but two different abilities can emote close together. Any future global throttling is a creator decision.

**Cooldown only on a fired emote:** A failed chance check or empty emote pool doesn't consume it. Chance therefore determines frequency independently from the *last actual emote*, and the development branch now avoids the earlier zero-default first-cast issue.

**Transient runtime state versus persisted preferences:** Ability choices persist by GUID; timers reset on UI reload/relog. This is simpler but won't provide a durable anti-spam cooldown if a player logs in and out quickly.

**Game-native emotes versus custom writing:** Native token discovery gives many options and localized game behavior, but does not let the player write unique roleplay lines or choose custom sounds. That keeps scope small.

**Legacy compatibility versus fully automatic migration:** Current source can adopt `ROARitFOREVERStorage` only when already loaded. It doesn't read an arbitrary old disk file. Name-realm legacy keys are not evidence of separate game realms on Forever.

**Packaging vs release assets:** The repository has CurseForge packager metadata and two GitHub release entries with no attached assets. No installer, ZIP checksum or distribution success should be invented.

## Unapproved questions for later discussion

Should cooldowns survive reload? Should live hits (when knowable) be used rather than cast success? Should duplicated spell names be distinct configurations? Should a global emote frequency ceiling coexist with per-ability cooldowns? Should there be a preview button? Should the addon publish explicit license terms? Record an actual Babuni.dev choice before treating any as accepted.

## Related development history

Flourish Forever is the October 2026 WoW Forever expression of the action-emote idea. Unlike the earlier action-slot hooks, it responds to the player’s **reported successful spellcast** event and lets the player select spellbook abilities and existing client-native emotes in a GUI. Each new ability initially has ROAR selected, but the player may choose other available emote tokens. This is client-token selection rather than creation of arbitrary new emotes, and cast success does not prove a landed hit. See the [source-grounded expressive-addon timeline](EMOTE_FAMILY_HISTORY.md) for related projects and historical boundaries.
