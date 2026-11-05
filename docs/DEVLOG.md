# Flourish Forever — creative and technical development journal

## 5 November 2026 — the larger editor becomes the next version

The recovered Flourish editor is finally back where it belongs. After installing the merged build in Forever, the larger ability overview, searchable selection and finer emote controls worked well enough that I chose to bring them forward for everyone rather than leave them in a private test branch. The work also restores the custom little gestures that make individual characters feel more like themselves.

My AI assistant handled the merge from the old archive, preserved the safety fixes, and prepared the next version's documentation and packaging checks. With that substantial expansion, `0.4.0-beta` is a more fitting release step than another tiny patch. The public version is still a separate decision: no publishing tag has been authorized in this preparation.

## 5 November 2026 — recovering the expanded editor

An older local ZIP turned out to contain the fuller ability editor I had already developed. Rather than replace the current addon with an old checkout, the test branch brings its ability overview, searchable pickers, custom emotes and individual cooldowns together with the more recent safety fixes.

My AI assistant handled the source reconciliation and offline checks. The recovered interface is committed for development testing, not released; the live Forever UI and custom chat behavior still need verification.


**Human creative:** Babuni · **Portfolio:** babuni.dev · **Historical public identity:** Babunigaming  
**Historical source:** October 22 and 26, 2026 Git commits; three Lua files; README and metadata; Babuni's recorded October conversation about project previews and descriptions. This is a **source-supported retrospective**, not a reconstruction of private messages which were not available.

## Making ability casts feel like character moments

Flourish Forever belongs to a particular thread of my experiments: allowing a character to do more than mechanically repeat a combat ability. A player may associate an important attack with a roar, a cheer, a gesture or a sudden burst of personality. But the game normally presents the ability as a spell and its ordinary combat animation, without adding this small expressive choice.

The idea was to make **automatic random emotes on selected abilities** possible. That small phrase captures the concept: not a system that chooses what the character casts, not a macro that must be pressed separately every time, and not a scripted roleplay monologue that speaks for the player without limits. A configured combat action becomes an opportunity for a tiny, variable flourish.

The public repository describes it as allowing the player to pick abilities from the spellbook, then set an independent chance, a cooldown and the emotes that might appear. The program expresses that in a way which leaves taste with the player. A powerful defensive ability might rarely produce one emblematic gesture, while a different move has a small menu of possible actions. The random choice introduces surprise but the source of variation remains the player's own selection.

As Babuni, the original creative direction is mine. The available material does not provide a full original ideation transcript, exact rejected names or whether a particular coding assistant typed each October 22 Lua function. The October 27 documentation assistant is recording source and conversation evidence, not claiming to have originated the concept.

## October 22, 2026 — a first Git commit that already contains a full interface

The first repository commit, **`b60d08024cdd`**, carries the message “Ship Flourish Forever 0.3.0-beta with configurable ability emotes.” There is no preceding 0.1 or 0.2 commit in this particular Git history. The first visible state is already a working-intent addon with a three-part source structure and a Blizzard-style configuration window.

One module, **FlourishForever_Storage.lua**, manages account-wide SavedVariables and individual character profiles. A second, **FlourishForever.lua**, routes slash commands. The largest module, **FlourishForever_ActionEmotes.lua**, discovers eligible spells and emote tokens, creates the editor, processes the chance/cooldown logic and listens for cast-success events.

The TOC sets **interface 16001**, declares `FlourishForeverStorage` and loads those three modules in that order. The repo's `.pkgmeta` indicates an intent to package the addon as FlourishForever with a manual changelog.

The first source already had a crucial autonomy detail: **every character gets its own choices**. The account-wide SavedVariables root is divided into profiles indexed by `UnitGUID("player")`, not by a name which might be ambiguous or by a set of separate realms. In World of Warcraft: Forever's relevant identity model there are **no separate realms**. The presence of optional older name-realm keys in migration code simply preserves an earlier storage format; it does not introduce cross-realm behavior.

The config defaults to **enabled** for the current character, but the ability list starts empty. That means the addon does not begin roaring on its own merely because it is installed. The player selects an actual spellbook ability first. This is a better creative fit than globally hooking every spell without asking: the character's expressive habits are authored through configuration.

## Building a controllable moment rather than an uncontrolled reflex

The configuration window is about **620×520 pixels** and uses the game's own inset frame, buttons, checkboxes, sliders and scroll surfaces. The player opens it through `/flourish`, chooses a non-passive ability from the spellbook dropdown, then sees configured abilities on the left and the selected one's options on the right.

Chance runs from **0 to 100 percent** in 1% steps and defaults to **100%** for a newly added spell. Cooldown runs from **0 to 120 seconds** and defaults to **six seconds**. Each configured spell starts with **ROAR** enabled as its possible emote, but the player can check other emotes from the client-provided emote list or uncheck ROAR entirely.

The collection of available emotes comes from the client's global `EMOTE*_TOKEN` values, not from a hand-written list of three or four favorite animations. The source sorts and labels those tokens, using `GetEmoteSlashCmd` when the client provides it. If no checkbox is selected for one spell, there is no valid outcome for that spell and the addon stays silent.

At runtime, the addon listens for **UNIT_SPELLCAST_SUCCEEDED** for the player. It resolves the spell ID into a spell name, finds a configuration for the lowercase/trimmed name, checks the ability's last-played emote timestamp, rolls the configured probability and randomly selects a permitted token. It then calls **DoEmote**. Importantly, the local timestamp is updated **only after a token is chosen**, so a failed chance roll doesn't consume an otherwise available cooldown.

This sequence is simple enough to describe in one paragraph, but it combines several decisions with a meaningful effect on the player's experience. A 20% chance is not “every fifth cast”; it may trigger twice in a row or remain silent for longer. A cooldown is not the game spell cooldown; it is a minimum time since this ability's previous flourish. The two controls shape a rhythm without giving the program control of the combat rotation.

## What “successful” means—and why that distinction matters

The initial prose described the feature as an emote appearing when an ability “lands.” Source review reveals that the code does **not** inspect combat-log hits or the eventual effect on a target. It responds when the game announces that the **spellcast succeeded**. A spell could be cast successfully while its damage later misses or is resisted, or its target effect doesn't occur the way the player expected.

This isn't necessarily a mistake; choosing cast-success events is a reasonable way to capture a broad range of combat and utility actions without complicated hit correlation. But it is a semantic difference the README must not conceal. The documentation now calls it *cast success*, and marks any proposal to switch to landed-hit triggers as **undecided**.

Another static finding is the first-cast timer. `lastFireByAbility[key]` begins absent and falls back to the number **0**. On a very early cast, if `GetTime()` has advanced less than the configured six-second cooldown, the expression `now - last < cooldown` is true and prevents that emote. The audit hasn't reproduced the event in-game; the code path makes it a plausible edge case worth testing.

The source also stores its current spell configuration under a **normalized ability name**, though it receives actual spell IDs from the event and dropdown. This can conveniently unify ranks whose names match, but may confuse players who see distinct spellbook entries with the same name. Localized spell-name changes can also make a saved configuration stop matching. These risks deserve targeted tests rather than an assumption of universal compatibility.

## Profiles, older names and the importance of not losing choices

The storage module includes two backward-compatibility mechanisms. If the current `FlourishForeverStorage` root is absent and an old **ROARitFOREVERStorage** global is already loaded, it adopts that data. Then, if the current character's GUID profile is missing, it looks for a profile stored under the plain character name or a legacy name-realm-style key and moves that table to the GUID key.

The intent visible in code is preserving previous character choices rather than discarding them during a rename or identity-model change. The availability of that old global isn't guaranteed by simply installing the newer addon: the current TOC loads only `FlourishForeverStorage`. Someone migrating real user data should preserve backups and explicitly test how the older SavedVariables file becomes available.

A second detail is that **settings persist but cooldown history doesn't**. The last-emote timestamps exist only as a local Lua table in the runtime module, so reload and relog reset them. The program does not keep a ledger of emotes it has played or synchronize cooldowns among characters or other addon users.

The full `/flourish status` output reports whether the system is enabled, the number of configured abilities, and a diagnostic profile identifier containing the character GUID. That can be useful for debugging, but the identifying status should be redacted in public screenshots.

## Later October 22 — 0.3.1-beta without a new gameplay engine

Commit **`56d8b67d719a`**, “Ship Flourish Forever 0.3.1-beta for the CurseForge packager,” is an instructive little development step. It changed the README's current version, the TOC's version and the changelog. Its changelog explicitly says **no change to how emotes play**.

That means the feature's first source state and the later beta packaging state are distinct distribution milestones, not evidence of a second gameplay implementation. Both [v0.3.0-beta](https://github.com/babunidev/FlourishForever/releases/tag/v0.3.0-beta) and [v0.3.1-beta](https://github.com/babunidev/FlourishForever/releases/tag/v0.3.1-beta) were published as GitHub release entries October 22. The GitHub API currently lists **no attached ZIP/assets** for either, and no confirmed CurseForge packaging result was inspected in this audit.

A discussion about the public presentation later on October 22 focused on presenting Flourish Forever to the public: crafting a one-sentence project preview, comparing descriptions to other addons on babuni.dev, and designing promotional imagery from provided in-game screenshots. This demonstrates another part of the creative work: the addon was not merely a script, but something I wanted to communicate visually and consistently with a wider collection. The conversation's exact accepted copy and image artifact are not preserved as commits in this particular repository, so this journal does not assert they were added to the codebase.

## October 26–27 — documenting the development as part of the artwork

On **October 26**, the project received a visible authorship pass: **`61c7aaddc1d6`** standardized the addon TOC's author from Babunigaming to **Babuni.dev** and **`7e36f7156b51`** added README author credit. Later commits **`24013323e692`** and **`b73fed5344bd`** created and linked a brief initial concept, roadmap, architecture, design-evidence and development-journal set.

On **October 27**, the current documentation assistant inspected the main Git tree, all three Lua modules, TOC, `.pkgmeta`, first two version commits, prior editorial files and the public release metadata. It expanded the record into eleven consistent documents with a deeper creative concept, state/lifecycle architecture, UI design, data inventory, decisions register, concrete verification roadmap and this publishable narrative.

This review found **no LICENSE**, no `tests/` path, no GitHub CI workflow, no project screenshots and no GitHub release assets in the repository tree/metadata. These absences are documented because it would be misleading to invent tests, download links or rights. The review did **not** open a WoW client, invoke `DoEmote`, check event payloads, run Lua tests, reproduce the early cooldown edge case or test live installation.

**Human contribution:** Babuni's original expressive concept, creative direction and eventual choices, with earlier Babunigaming credit retained as historical context. **AI contribution in this session:** code/history interpretation, identification of source-level limitations, editorial writing and the documentation Git commit. Git alone doesn't identify precisely who typed each function of the initial source, and this record doesn't claim to.

## What the next chapter should actually observe

The next useful evidence will come from the Forever release client: select one ability, check an emote, and cast it repeatedly at known timestamps. Watch what happens at 0%, 100%, under a cooldown, after a reload, and when a cast succeeds but does not land damage. Try two configured abilities in quick succession and verify that one doesn't consume the other's cooldown. Switch characters and confirm saved choices stay separate.

Then inspect the creative quality: Does the random flourish make a character feel more alive, or does a particular combination become repetitive? Which gestures convey the right personality? Do two fast emotes overwhelm normal social play? These are design findings for me to make in the game itself, not things an assistant can certify from source alone.

Flourish Forever is a compact demonstration of **authored spontaneity**: the player chooses the moments and possible actions, and a modest system adds variation at playtime. The technical work matters because its restraints—per-character preferences, chance, cooldown, successful-cast events and honest data migration—let that spontaneous character expression remain under the player's control.

## October 27, 2026 — preserving the portfolio artwork

I supplied the accepted FF medallion logo, gnome-roar promotional showcase, and smaller JPEG thumbnail, and explicitly requested their addition to the repository for the Babuni.dev portfolio. The visual direction was to match the other Forever addons, show the addon alongside an appealing composition, and keep the upload thumbnail below 2 MB. Earlier AI work generated the artwork and prepared the smaller export.

This asset addition preserves the three supplied files unchanged under `assets/portfolio/`, using URL-safe filenames. The assistant added an index and JSON manifest with dimensions, byte sizes, roles, suggested alt text and display paths, identifying the JPEG as the preferred web preview. Image decoding, dimensions and byte-for-byte equality with the supplied originals were checked. The JPEG is 481,703 bytes. This records the actual supplied file, rather than relying on an earlier conversational size estimate.

No portfolio website integration or in-game behavior was tested by this addition. The promotional composition is not an unedited gameplay screenshot. The exact date of the earlier creative exchange is not established by the supplied excerpts; October 27 dates this repository addition.

## 4 November 2026 — small fixes, documentation and clean installations

Having used the addon during the Forever beta, I considered its original feature set working. The aim of this maintenance pass was not a new emote engine; it was to keep the native `DoEmote` behavior and correct specific weaknesses without surprising players. My AI assistant implemented the first-cast cooldown correction, safer saved values and spellbook filtering on a **separate development branch**. The Lua syntax and mocked regression tests passed on GitHub Actions and my Nobara system, but that does not replace another check inside the live game.

The GitHub repository should continue carrying the concept, history, development notes and portfolio images, without sending those files into everyone's AddOns directory. That led to a minimal CurseForge package configuration, merged into `main`. A matching MIT license was documented because CurseForge already listed this project as MIT. The README and release notes now keep the public CurseForge file, GitHub tag, development code and actual verification clearly separate. No new version was published or authorized.

## 4 November 2026 — preparing the next beta update

The first game launch seemed like a good point to gather the small improvements into one version rather than keep them scattered across separate branches. Since the beta gameplay had worked for me, the release candidate keeps the familiar spellcast trigger and native emotes, while incorporating the tested fixes and lean installation package. My AI assistant assembled the proposed `0.3.2-beta` code and version notes, then added a dry-run packaging check that does not upload to CurseForge.

This is a development checkpoint, not the announcement of a public update. The modified code still needs its release-client check, and the private CurseForge integration settings need confirmation before a publishing tag is pushed.

## 1 November 2026 — connecting Flourish to the earlier experiments

The earlier action-emote addons helped me explore an idea that kept returning in new forms: character expression should grow naturally from what the player is already doing. After reviewing the complete family, I asked my AI assistant to distinguish the old watched-button model from **Flourish Forever's spellcast-success model**. The new GUI allows per-ability selection among existing client emotes, with ROAR as the starting choice, rather than a free-form text creator. The [cross-project record](EMOTE_FAMILY_HISTORY.md) also keeps Roar Forever's separate voice-restoration purpose clear. This was documentation research, not new game testing.
