# Flourish Forever — human–AI collaboration and attribution

**Original idea, creative direction and final decisions:** Babuni.dev.  
**Earlier public developer identity:** Babunigaming, preserved from the original October 22 README/TOC.  
**Retrospective date:** October 27, 2026.

## Authorship isn't inferred from who writes the documentation

The creator's original direction was to let **selected player ability casts trigger random native emotes**, with freedom to curate abilities, emote pools, chance and cooldown. The October 22 project discussion explicitly concerned how to describe and present the addon as part of Babuni.dev's work. The first source commit already contained a substantial implementation.

The code and commit history do not preserve the complete initial brainstorm, creator/AI arguments, every earlier experiment or the precise authorship of the Lua routines. The assistant writing this October 27 documentation therefore does not claim to have invented the ability-emote idea or to know which previous changes were AI-generated.

There is no evidence here that the **0.3.1-beta** version bump changed gameplay. The changelog says it did not. And there is no in-game test result in this audit, even though a public beta release entry exists.

## Explicit AI contribution during this audit

The assistant:
- Recovered repository **#26** from the original audit ordering: **`babunidev/FlourishForever`**, following #25 Redridge-Recipe-Planner.
- Read the actual three Lua source files, manifest, packaging metadata, README and existing documentary baseline.
- Inspected the October 22 **0.3.0-beta** initial full-system commit and **0.3.1-beta** packaging/version-only change, plus October 26 author/documentation commits.
- Checked the two GitHub release entries and confirmed **zero attached release assets**; identified **no LICENSE, test scripts or CI** in the inspected main tree.
- Described the `UNIT_SPELLCAST_SUCCEEDED` trigger accurately instead of claiming landed damage; charted normalized spell-name matching, per-ability random pool, chance/cooldown checks and GUID-keyed persistence.
- Noted the possible first-cast early cooldown, lack of cooldown persistence, conditional old storage migration, UI dependencies and privacy of the status GUID output.
- Wrote and committed eleven Markdown files, separated historical creator direction from code evidence and future proposals, and verified relative links and preservation of executable files.

This was **repository inspection, technical/historical analysis and documentation writing**, not a new gameplay implementation, an approval of future features, a WoW test, original authorship of the idea, or proof a CurseForge package was produced.

## November 4, 2026 — targeted code maintenance

Babuni reported complete functional use on the Forever beta and directed that working event and emote APIs remain unchanged. AI inspected the Lua source, researched Forever spellbook item types, implemented bounded saved settings, actual-prior-fire cooldown behavior and spellbook filtering, then added mocked tests and pull-request checks. This work is not a claim of launch-client or CurseForge verification; it remains on a development branch until reviewed.

## Rules for continued collaboration

Each meaningful future feature or change should preserve:
1. **User direction:** what Babuni.dev wanted, the feeling to achieve and clear constraints.
2. **AI contribution:** actually suggested designs, drafts, code, debugging and test work—distinct from creator inspiration.
3. **Creative iteration:** experiments, mistakes, misunderstandings, alternatives and discarded approaches.
4. **Creator decision:** explicitly accepted/rejected/deferred, not an inferred approval.
5. **Implementation:** source/doc paths, version and commit.
6. **Verification:** actual client build, emote behavior, event traces, tests performed, screenshots and still-open questions.

Publish readable, faithful narratives rather than raw private chat logs. Avoid exposing character GUIDs or unrelated player/account information in a public portfolio. Respect the client's external game assets and seek a creator decision on the repository's absent LICENSE before claiming source reuse permission.

No Lua, manifest, packager metadata or other non-document content was changed by this audit.

## Related development history

Flourish Forever is the October 2026 WoW Forever expression of the action-emote idea. Unlike the earlier action-slot hooks, it responds to the player’s **reported successful spellcast** event and lets the player select spellbook abilities and existing client-native emotes in a GUI. Each new ability initially has ROAR selected, but the player may choose other available emote tokens. This is client-token selection rather than creation of arbitrary new emotes, and cast success does not prove a landed hit. See the [source-grounded expressive-addon timeline](EMOTE_FAMILY_HISTORY.md) for related projects and historical boundaries.
