# Flourish Forever — recorded design decisions and open alternatives

## 5 November 2026 — group-play correction approved for distribution

After installing the test branch, Babuni reported that Flourish seems to work fine again and requested that the correction be made available to other players. The next prepared version is `0.4.3-beta`. The actual change remains narrowly scoped: don't conflate Map, Encounter and ChallengeMode data restrictions with chat restrictions, but retain actual chat lockdown, Chat/PvPMatch restriction checks and battleground/arena suppression.

This is a general player confirmation rather than a documented full party/dungeon/raid or protected-action test. Public distribution is approved in principle; the exact tag must be pushed and the CurseForge file verified separately.

## 5 November 2026 — group play and security restriction scope

After the action-triggered fix, Babuni reported that Flourish no longer appeared to emote while grouped. The subsequent code review found a plausible over-restriction: the dispatch guard blocked on `Map`, `Encounter` and `ChallengeMode` addon data restrictions in addition to actual chat and PvP restrictions.

The test-branch correction permits ordinary parties, dungeon instances and raids despite those unrelated states, while retaining native/custom player-action timing and the real chat/PvP safeguards. This respects the priority of Flourish as a group-visible expression tool without attempting to bypass restricted chat APIs. The precise cause of Babuni's experience remains **inferred from the code**, not verified by runtime measurements. An in-game group retest is still required; no public tag has been approved.

## 5 November 2026 — release decision for action-triggered emotes

After installing `0.4.1-beta-dev`, Babuni reported that the new emote behavior looked and worked like the old version, and requested its public release. The prepared successor is `0.4.2-beta`. Both native and custom emotes now originate at the player-action hook to avoid the protected delayed cast-success call. This may produce an emote for a failed attempted cast or miss activations outside the hooked paths. That trade-off is documented for players. The user did **not** specifically confirm a successful battleground retest; automated security mocks cannot substitute for it.

## 5 November 2026 — experimental change after recurring protected-action error

The `v0.4.1-beta` hotfix did not eliminate the blocked `PerformEmote()` call: Babuni supplied a second BugGrabber trace with the new source-line numbers. `IsInInstance()` alone could not account for the restriction. Forever's API notes establish hardware-event requirements for custom `EMOTE` messages, and its native `C_ChatInfo.PerformEmote` API is marked as restricted.

AI has **proposed and implemented on a separate, unreleased test branch** a different trigger model: native emotes join custom `/e` on direct player action hooks; the delayed cast-success listener cannot call the protected function. The branch also checks active/activating chat, match and encounter restrictions. This is a material trade-off: an emote can occur on a failed attempted cast, and some spell activation paths might not be observed. The original cast-success behavior remains the public design until Babuni accepts the alternative.

No in-game testing, approval of that trade-off, or publishing tag has been recorded.

## 5 November 2026 — urgent hotfix publication decision

After seeing the protected `PerformEmote()` error from a battleground, Babuni explicitly requested that the conservative PvP suppression fix be released promptly rather than remain only in a test branch. The next proposed patch version is `0.4.1-beta`, following the existing `v0.4.0-beta` tag. This permits release preparation, with the actual publishing tag remaining a separate step on the exact verified commit. The known tradeoff is deliberate silence of both native and custom automatic emotes in battlegrounds/arenas; the fix has passed mocked tests but not an actual battleground retest.

## 5 November 2026 — battleground protected-emote bug and temporary guard

After uploading `v0.4.0-beta`, Babuni reported BugGrabber's `ADDON_ACTION_BLOCKED` when entering a battleground. Source code confirmed the call path from cast-success to `DoEmote` and protected `PerformEmote()`. A conservative **development-only** guard now suppresses automatic native and custom flourishes in battlegrounds and arenas, instead of attempting an insecure workaround. This changes automatic PvP behavior, but keeps saved player choices and normal-world emotes. It remains open whether this should be the final PvP design; real battleground confirmation has not yet been reported.

## 5 November 2026 — approved expanded editor, next beta preparation

Babuni installed the merged development version in the actual Forever client and reported that it works well, then explicitly asked to commit the upgrade and prepare it for players. The enlarged searchable editor, spellbook picker, custom `/e` text, individual token cooldowns and existing safety work therefore move from an earlier test-only proposal to an **approved implemented design**. The release candidate is named **0.4.0-beta** as a significant feature update after `v0.3.2-beta`; it is a proposed publishing version until Babuni authorizes the exact tag and commit.

Native emotes remain cast-success triggered. Custom chat emotes use press-time hooks because ordinary chat sending is more restricted after the event; this intentionally means custom text can run for a cast that later fails. The broad in-game success report does not verify every secure-action case, SavedVariables migration or other addon interactions. This tradeoff is documented, not silently hidden.

**Git development vs public release:** Committing or merging this work is not authorization for a new CurseForge file. Public publication remains behind a separate explicit release gate and verification.

## 5 November 2026 — recovered interface merged for testing

Babuni directed the recovery of the more developed UI from a local archive, without changing the published release. A separate GitHub development branch now holds the restored features and safety reconciliation; no automatic public release is permitted. A custom `/e` may fire on a press even if the spell subsequently fails, unlike native success-event emotes. This is documented rather than silently changing the original design.


**Creative decision authority:** Babuni · **Portfolio:** babuni.dev. **Evidence:** initial October 22 source commit, beta packaging change, README, project conversation context and October 26 attribution/docs. Missing early discussion and game tests are not invented.

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
| Oct 26 `61c7aadd`, `7e36f715` | Standardize the public byline to babuni.dev while retaining Babunigaming history | Current documentation distinguishes Babuni (human creative) from babuni.dev (portfolio) |

The code and commit messages do not prove the full initial brainstorming, all alternatives or which tool generated each earlier code line.

## November 4, 2026 — confirmed maintenance decisions

Babuni confirmed functional beta use and approved targeted source improvements while retaining the existing spellcast event and native `DoEmote` path. Draft PR #2 implemented first-cast timing, bounded saved values and castable spellbook filtering; earlier GitHub and Nobara mocks passed. Those precise gameplay changes have now been integrated into a separate `0.3.2-beta` release-preparation branch, but remain unmerged to main and not live-client tested.

The previously selected **MIT** designation is visible on CurseForge. Repository documentation now carries the matching `LICENSE` with credit to Babuni, and `.pkgmeta` requests inclusion in a future package. This aligns the already-public license declaration; it does not grant rights to separate Blizzard assets.

## Release preparation — November 4, 2026

Version `0.3.2-beta` is prepared as a proposed patch-level beta increment from the prior GitHub `0.3.1-beta`, carrying fixes and packaging cleanup without expanding the feature set. The TOC is updated on the release-preparation branch; the actual version and exact tagged commit still require Babuni's approval. Automated packaging is configured only for **no-upload** dry runs on pull requests. Public CurseForge source settings and the real published ZIP remain unverified.

## Source-level tradeoffs

**Cast success versus damage hit:** The original introductory text said “when that ability lands.” The actual implementation observes **UNIT_SPELLCAST_SUCCEEDED**. That avoids parsing combat damage/target effects but may emit a flourish even when a cast later misses, is resisted or has no meaningful target hit. No new trigger is approved.

**Name-key versus ID-key:** The event carries a spell ID and the UI lists spellbook IDs, but saved configurations are keyed by **normalized spell name**. This can make multiple ranks share one expressive identity, while risking same-name collisions and localization-induced mismatches.

**Independent cooldowns versus global social volume (original model):** The 0.3.x version gave every configured ability its own timestamp; there is no overall emote budget. That respects distinctive spell personalities but two different abilities can emote close together. Any future global throttling is a creator decision.

**Cooldown only on a fired emote:** A failed chance check or empty emote pool doesn't consume it. Chance therefore determines frequency independently from the *last actual emote*, though the zero default timestamp may suppress a very early first attempt.

**Transient runtime state versus persisted preferences:** Ability choices persist by GUID; timers reset on UI reload/relog. This is simpler but won't provide a durable anti-spam cooldown if a player logs in and out quickly.

**Native emotes versus custom writing (revised in 0.4.0-beta):** The original scope was native token discovery only. The expanded version also supports player-written `/e` lines; they still do not create new sounds or animations, and must be triggered during a player-button press.

**Legacy compatibility versus fully automatic migration:** Current source can adopt `ROARitFOREVERStorage` only when already loaded. It doesn't read an arbitrary old disk file. Name-realm legacy keys are not evidence of separate game realms on Forever.

**Packaging vs release assets:** The repository has CurseForge packager metadata and two GitHub release entries with no attached assets. No installer, ZIP checksum or distribution success should be invented.

## Unapproved questions for later discussion

Should cooldowns survive reload? Should live hits (when knowable) be used rather than cast success? Should duplicated spell names be distinct configurations? Should a global emote frequency ceiling coexist with per-ability cooldowns? Should there be a preview button? The repository now mirrors its pre-existing CurseForge MIT license; no new public release has been approved. Record Babuni's choice before treating any other alternative as accepted.

## Related development history

Flourish Forever is the October 2026 WoW Forever expression of the action-emote idea. Unlike the earlier action-slot hooks, it responds to the player’s **reported successful spellcast** event and lets the player select spellbook abilities and existing client-native emotes in a GUI. Each new ability initially has ROAR selected, but the player may choose other available emote tokens. This is client-token selection rather than creation of arbitrary new emotes, and cast success does not prove a landed hit. See the [source-grounded expressive-addon timeline](EMOTE_FAMILY_HISTORY.md) for related projects and historical boundaries.
