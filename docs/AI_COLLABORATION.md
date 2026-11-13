# Flourish Forever — human–AI collaboration and attribution

Follow [the documentation standard](DOCUMENTATION.md) for first-person author voice throughout project documentation, factual changelogs, and naming the AI tool and verified model for each contribution.


## 7 November 2026 — release preparation after live verification

Babuni confirmed the new emote-dependent ability cooldown works in the Forever client and explicitly requested a publishing tag for other players. AI reviewed the development commit against the last tagged public baseline, prepared `0.5.0-beta` manifest/changelog documentation and synchronized the package validation test. Release tests and packaging must be verified against the final exact commit; a GitHub tag does not on its own establish a live CurseForge file. No additional game-client testing of battlegrounds or protected messaging was claimed.

## 7 November 2026 — Babuni approves chosen-duration ability locks

Babuni confirmed the preceding individual-emote cooldown implementation works in-game, then directed a new behavior: each emote retains an independently configured duration, but the *one selected* locks its whole ability until that duration expires. The three-second giggle and twenty-second dramatic emote example is Babuni's creative direction, not an AI-generated feature proposal.

AI implemented the new per-ability runtime and SavedVariables lock, preserved native attempt/success evidence and Forever's chat/PvP guards, updated editor guidance and diagnostics, and revised mocked regressions. GitHub Lua/package checks passed; **no live test of the new shared-lock behavior** has been reported. The implementation remains in a development branch, with no authorized new publication.

## 7 November 2026 — decoding the native emote diagnostic

Babuni supplied Forever diagnostic output showing nine attempted native emotes, zero API-accepted results, nine false returns, FAINT as the last selected token with a six-second timer, and no chat/PvP lockdown. AI traced the missing cooldown to a native dispatch path that wrote no timestamp when `PerformEmote` returned false. The new development implementation records a separate `lastAttemptAt` for any actual native call, while retaining `lastFiredAt` only for accepted results. This deliberately rate-limits ambiguous or unsuccessful native attempts without falsely claiming their delivery. Regression mocks simulate visible output even from a false-result call and exercise six-second expiry, reload and accepted/refused diagnostics. Actual client delivery on false returns and the effectiveness of the new throttle are still unverified in-game; no release is authorized.

## 7 November 2026 — continued live cooldown investigation

Babuni reported that even after the new persistence code was installed, Mobility with Button press and six seconds configured still appeared to send an emote on every press. AI confirmed that the source applies individual token cooldowns, which permit different eligible tokens to fire on successive presses, but do not justify early repetition of one token. The source change centralizes cooldown calculations and adds manually invoked token-level diagnostics; tests include the exact six-second single-token and multi-token scenarios. This is *not* a verified live fix. No release tag, merge or CurseForge upload is authorized.

## 6 November 2026 — independent cooldown investigation

Babuni reported that per-emote cooldowns seemed ineffective and requested a thorough correction. AI examined the SavedVariables migration, UI slider handler, `GetTime()` comparisons and accepted-emote dispatch path. The documented source weakness was session-only last-dispatch history, lost on `/reload`; a new automated test reproduced the missing persistent timestamp. AI implemented per-token `GetServerTime()` persistence with precise in-session `GetTime()` checks, regression coverage for independent emotes/abilities, zero and nonzero durations, failure returns and corrupt saves, and UI slider save/reopen tests. Offline verification is distinguished from a still-pending WoW Forever retest.

## 6 November 2026 — native emote search and PvP observability

Babuni reported a missing Roar search result and no emote activity in a battleground while testing the new selectable trigger system. AI identified and corrected the native-token search omission, removed unnecessary spell-usability gating for press-triggered behavior, added mocked UI/gameplay cases, and implemented a manual `/flourish debug` status report with no player-identifying data. Current battleground restrictions remain under investigation. Tests and packaging status are recorded separately; no successful live PvP test or public distribution is claimed.

## 6 November 2026 — per-ability trigger design

Babuni supplied the new design: a Triggered by dropdown next to Chance offering Success as the default, Button press and Failure, with battleground/arena Success falling back to Button press rather than producing protected-action errors. AI reviewed the Forever spellcast events and restricted chat behavior, implemented per-ability stored preferences, event filtering, the UI and automated regressions. The native outcome path and press fallback remain pending local in-game verification, and no release was authorized. Custom `/e` requires hardware input and cannot honestly be represented as a guaranteed success/failure event response.


## 5 November 2026 — group-play follow-up and release preparation

Babuni reported that the tested group-emote correction now seems to work fine and directed publication for all players. AI updated the `0.4.3-beta` manifest, public notes, project decisions, verification roadmap and package test. The user's confirmation is general in-game feedback rather than proof of every raid, dungeon and combat restriction case. No publication is claimed until an approved tag is pushed and the resulting CurseForge file is verified.

## 5 November 2026 — group-play silence investigation

Babuni reported that Flourish did not appear to trigger during group play and emphasized preserving its social expression purpose. AI reviewed the published action-press restriction guard, identified its overly broad treatment of unrelated Map/Encounter/ChallengeMode states, narrowed the guard while preserving real chat and PvP safeguards, and added mocked party/raid coverage. The cause is a code-backed hypothesis, not an observed runtime diagnosis; no in-game group test or public release is claimed.

## 5 November 2026 — general in-game confirmation and release preparation

Babuni installed the hardware-action experiment and reported that it works like the previous version, without a noticeable difference, then directed a public release. AI prepared the `0.4.2-beta` version metadata, release notes, documentation and package checks. The change to action-press timing is explicit. A successful battleground-specific retest has not been reported, and publication requires the separately pushed tag and CurseForge verification.

## 5 November 2026 — second protected-action investigation

Babuni reported another `PerformEmote()` block after the first PvP hotfix. AI compared source line numbers, researched Forever's chat restriction APIs, and implemented an experimental hardware-action native emote path with stricter chat/PvP restrictions and mocked regressions. This changes native trigger semantics from cast success to action press and is **not yet approved as the permanent gameplay design**. Neither game-client success nor publication is claimed.

## 5 November 2026 — PvP protected-action hotfix preparation

Babuni reported a protected-function error when entering a Forever battleground and then asked to publish a preventive fix. AI traced the report to the native emote dispatch, implemented the PvP/arena suppression guard, added mocked regression checks, and prepared a `0.4.1-beta` patch candidate and documentation. This work does not constitute a live battleground test or evidence of CurseForge publication. The public tag and subsequent file verification remain distinct steps.

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
