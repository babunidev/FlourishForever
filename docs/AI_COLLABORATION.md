# Flourish Forever — human–AI collaboration and attribution

## 5 November 2026 — in-game confirmation and 0.4.0-beta preparation

Babuni reported the merged expanded UI functioning well when installed in the Forever client, and directed preparation of a public update. The feature concept and decision to restore the earlier editor belong to Babuni; AI's work comprises code reconciliation, SavedVariables migration safeguards, tests, package checks and documentation. This report is a real but general hands-on observation. No individual detailed combat, protected-chat, cross-character or RoarForever regression results were supplied.

For the next version AI prepared `0.4.0-beta` release copy, the updated manifest, and technical documentation while preserving attribution, the original Git history and the MIT license. Preparation and merging are development work; publishing requires explicit version-specific approval and a separate CurseForge file check.

## 5 November 2026 — local-archive feature recovery

Babuni supplied the expanded addon archive and requested the recovered features be developed through GitHub. AI integrated the expanded interface, saved-setting migration, searches and tests with current release safeguards on a separate branch. Offline tests do not prove Forever-client compatibility or protected custom-emote behavior. No public release was created.


**Original idea, creative direction and final decisions:** Babuni · **Portfolio:** babuni.dev.  
**Earlier public developer identity:** Babunigaming, preserved from the original October 22 README/TOC.  
**Retrospective date:** October 27, 2026.

## Authorship isn't inferred from who writes the documentation

Babuni's original direction was to let **selected player ability casts trigger random native emotes**, with freedom to curate abilities, emote pools, chance and cooldown. The October 22 project discussion explicitly concerned how to describe and present the addon as part of Babuni.dev's work. The first source commit already contained a substantial implementation.

The code and commit history do not preserve the complete initial brainstorm, human/AI arguments, every earlier experiment or the precise authorship of the Lua routines. The assistant writing this October 27 documentation therefore does not claim to have invented Babuni's ability-emote idea or to know which previous changes were AI-generated.

There is no evidence here that the **0.3.1-beta** version bump changed gameplay. The changelog says it did not. And there is no in-game test result in this audit, even though a public beta release entry exists.

## Explicit AI contribution during this audit

The assistant:
- Recovered repository **#26** from the original audit ordering: **`babunidev/FlourishForever`**, following #25 Redridge-Recipe-Planner.
- Read the actual three Lua source files, manifest, packaging metadata, README and existing documentary baseline.
- Inspected the October 22 **0.3.0-beta** initial full-system commit and **0.3.1-beta** packaging/version-only change, plus October 26 author/documentation commits.
- Checked the two GitHub release entries and confirmed **zero attached release assets**; identified **no LICENSE, test scripts or CI** in the October 27 historical tree (before later maintenance).
- Described the `UNIT_SPELLCAST_SUCCEEDED` trigger accurately instead of claiming landed damage; charted normalized spell-name matching, per-ability random pool, chance/cooldown checks and GUID-keyed persistence.
- Noted the possible first-cast early cooldown, lack of cooldown persistence, conditional old storage migration, UI dependencies and privacy of the status GUID output.
- Wrote and committed eleven Markdown files, separated historical creative direction from code evidence and future proposals, and verified relative links and preservation of executable files.

This was **repository inspection, technical/historical analysis and documentation writing**, not a new gameplay implementation, an approval of future features, a WoW test, original authorship of the idea, or proof a CurseForge package was produced.

## November 4, 2026 — verified work and authority

Babuni confirmed using FlourishForever successfully on the Forever beta and directed selective improvements without speculative API replacement. AI implemented first-cast, SavedVariables and spellbook safeguards in draft PR #2, with mocked Lua checks passed on GitHub and Nobara. At the time of this November 4 checkpoint the changes were in a **release-preparation branch**; they were subsequently merged to `main` and tagged as `v0.3.2-beta`. The later expanded-interface testing is recorded above. In parallel, the approved packaging work was merged into `main` without modifying gameplay Lua.

The public CurseForge project was already labeled MIT before this review. The repository now contains the corresponding license and package directive. Documentation distinguishes Babuni (human creative), babuni.dev (portfolio), historical Babunigaming credit and AI technical contributions. This is not authorization to release a new public version.

## Proposed 0.3.2-beta release preparation

AI combined the previously tested gameplay fixes with the merged packaging and documentation baseline on a separate release branch. The candidate updates its TOC version and changelog, and adds an upload-disabled package preview check. Babuni remains responsible for authorizing the exact public version; development preparation is not release approval or proof of CurseForge publication.

## Rules for continued collaboration

Each meaningful future feature or change should preserve:
1. **Human creative direction:** what Babuni wanted, the feeling to achieve and clear constraints.
2. **AI contribution:** actually suggested designs, drafts, code, debugging and test work—distinct from the human's original creative direction.
3. **Creative iteration:** experiments, mistakes, misunderstandings, alternatives and discarded approaches.
4. **Babuni decision:** explicitly accepted/rejected/deferred, not an inferred approval.
5. **Implementation:** source/doc paths, version and commit.
6. **Verification:** actual client build, emote behavior, event traces, tests performed, screenshots and still-open questions.

Publish readable, faithful narratives rather than raw private chat logs. Avoid exposing character GUIDs or unrelated player/account information in a public portfolio. Respect the client's external game assets and preserve the existing MIT source license and the separate rights in Blizzard assets. Historical copyright and contributor credits must be retained.

No Lua, manifest, packager metadata or other non-document content was changed by this audit.

## Related development history

Flourish Forever is the October 2026 WoW Forever expression of the action-emote idea. Unlike the earlier action-slot hooks, it responds to the player’s **reported successful spellcast** event and lets the player select spellbook abilities and existing client-native emotes in a GUI. Each new ability initially has ROAR selected, but the player may choose other available emote tokens. This is client-token selection rather than creation of arbitrary new emotes, and cast success does not prove a landed hit. See the [source-grounded expressive-addon timeline](EMOTE_FAMILY_HISTORY.md) for related projects and historical boundaries.
