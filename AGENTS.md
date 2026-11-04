# Flourish Forever — development and AI collaboration rules

**Human creative / final decision-maker:** Babuni.  
**Latest GitHub release:** 0.3.1-beta · **Prepared candidate:** 0.3.2-beta (unpublished) / WoW: Forever 16001. **Prior development credit:** Babunigaming.

## Preserve the human-directed expression concept

The creative's idea is **automatic random native-game emotes on selected ability casts**, with individual ability chance, cooldown and curated emote pools. Do not reimagine it as a chat spam bot, combat spell automation, AI-generated roleplay dialogue, or universal “every ability emotes” feature without explicit creative approval.

The player must choose eligible non-passive abilities; a fresh character's configured ability list is empty. The default enabled switch alone does not cause unsolicited emotes. Respect per-character autonomy and the `DoEmote` pipeline.

## Source invariants and implementation risks

- The TOC order is **Storage.lua → FlourishForever.lua → ActionEmotes.lua**, with account-wide `FlourishForeverStorage`.
- Character profiles are keyed by **`UnitGUID("player")`**. Forever's model is realmless; name-realm keys occur only in the **legacy migration fallback**, not as a cross-realm identity feature.
- `EnsureDB()` binds on access; it can create a temporary local profile when the GUID isn't ready. Test early actions and verify persistence after login.
- `ROARitFOREVERStorage` is adopted **only if the old global has been loaded** and new root doesn't exist; avoid claiming automatic disk migration from a deleted previous addon.
- Per-name `instances` store `name`, `spellID`, `chance`, `cooldown`, `emotes`. Spell **names** are normalized by trim/lowercase; event spell IDs are resolved back to names, so ranks/locale changes may collide or lose match.
- Trigger event is **player `UNIT_SPELLCAST_SUCCEEDED`**, not combat-log proof that a spell hit. Failed casts shouldn't be described as landed or as the event source.
- Default chance **100%**, cooldown **6 seconds**, default allowed token **ROAR**; UI bounds chance 0–100 and cooldown 0–120. The prepared candidate clamps malformed saved numeric values to the supported ranges.
- **Cooldown is consumed only on an actual successful emote selection**; a failed probability check or empty pool does not spend it. Runtime timestamps live in `lastFireByAbility`, **not SavedVariables**.
- The prepared candidate checks for an actual prior emote timestamp, so an unseen ability's first cast is not throttled by a synthetic zero. This passed earlier mocked tests but remains unverified in-game.
- Emote list is discovered from `EMOTE*_TOKEN` globals, with ROAR fallback; `DoEmote(token)` executes client behavior. No custom chat strings/sounds.
- Slash commands `/flourish`, `/flourishforever`, `/rit`; `status` currently exposes a character GUID in chat—redact when sharing.
- The repository contains an MIT `LICENSE` aligned to CurseForge's declaration and included via `.pkgmeta` `license-output`. The release candidate integrates both the package inventory test and the mocked Lua regression suite; the dry-run packager check verifies a generated ZIP, not CurseForge publishing. In-game checks remain separate.

## Development protocol

1. Inspect the live source and Git history; preserve README, concept, architecture, design, decisions and DEVLOG as the shared specification.
2. Record **creative direction**, assistant proposal, alternatives and constraints separately. Do not claim an AI proposal was accepted unless Babuni explicitly approved it.
3. Record actual implementation files, dates, commit and release metadata; note that version 0.3.1 updated packaging/version text without runtime changes.
4. For code changes, test client event signatures, abilities/spellbook enumeration, native emote output, per-character saved profiles, cooldown edge cases, reloads and compatibility with other emote addons.
5. Distinguish source review, a mocked Lua test and real in-game proof. The historical October 27 audit ran no tests, but Babuni later confirmed beta gameplay and passed offline Lua checks for draft PR #2 on Nobara. Neither validates the altered code on the launch client.
6. Keep private chat/character GUIDs out of public portfolio examples. Respect third-party WoW assets and the existing declared MIT licensing; preserve Babuni's and historical Babunigaming's credit.
7. Update README, CONCEPT, ROADMAP, CHANGELOG, AGENTS, docs/ARCHITECTURE, DESIGN, CONTENT, DECISIONS, DEVLOG, AI_COLLABORATION for material changes.

The earlier documentation-only audit did not authorize code changes; subsequent Babuni instructions explicitly authorized targeted code maintenance and separate lean-package work. Merge and release authorization must still be distinguished; never publish a public version without specific approval.

## Related projects and provenance

Review [the expressive-addon family history](docs/EMOTE_FAMILY_HISTORY.md) when documenting this addon. Do not conflate the older button-press hooks, the guild's user-registered token table, Flourish Forever's spellbook/client-token selection, or Roar Forever's voice-restoration purpose. A successful cast event does not imply a successful target hit. Respect first-person creative authorship and evidence limitations.

## Repository-local documentation standard

Before writing or changing project documentation, read [docs/DOCUMENTATION.md](docs/DOCUMENTATION.md). These rules travel with this repository and do not depend on the babuni.dev ChatGPT Project. Preserve all project-specific technical, creative, canon, safety, licensing, and historical rules in this file; follow the linked standard for public first-person narrative, human–AI attribution, concise development journals, decision records, and evidence-based verification. **Babuni** is the human creative; **babuni.dev** is the website/portfolio, not the person. Preserve third-party credits and historical legal notices. References above to a dated “documentation-only audit” describe that past task, not a permanent ban on later authorized implementation.
