# Flourish Forever — dated changelog and development evidence

**Creator and creative director:** Babuni.dev. **Interface:** WoW: Forever 16001.

## Unreleased development — 2026-11-04 (not publicly released)

- Fixed the first eligible cast being subject to a cooldown despite no earlier emote.
- Validated loaded chance/cooldown values against existing slider limits; invalid master switches disable automatic emotes rather than enabling unexpectedly.
- Preserved unusable old records for recovery while skipping them during live selection, and ignored nonstring emote tokens.
- Restricted spellbook selection to learned, non-passive, usable spell entries in the modern and legacy enumerators; existing cast-success and `DoEmote` behavior remain unchanged.
- Added mocked Lua regression tests and pull-request-only CI. In-game verification and a new CurseForge package are **not** claimed.

## October 27, 2026 — portfolio artwork

- Added three creator-supplied images under `assets/portfolio/`: square logo, PNG showcase and JPEG thumbnail.
- Added an asset index and JSON manifest for Babuni.dev display paths, dimensions and alt text.
- Preserved original file bytes; checked image decoding, dimensions and the JPEG's size below 2 MB.
- Updated README, content inventory, design notes and development history. No gameplay behavior changed; portfolio rendering remains unverified.

## October 27, 2026 — portfolio documentation audit

- Expanded/created 11 substantial Markdown files describing the human-directed character-expression concept, implementation, UI, saved-data migration, release chronology, design decisions and test gaps.
- Clarified that the real gameplay trigger is **UNIT_SPELLCAST_SUCCEEDED**, not verification that an attack landed; that cooldowns are **session-only**, and that spell settings are keyed by normalized **name** within a GUID-based character profile.
- Recorded the source-level first-cast `GetTime()`/zero-timestamp edge case, optional legacy-root migration behavior, `/rit` alias and raw-GUID status output.
- Confirmed published GitHub beta entries have **no downloadable release assets** and the main repository has **no LICENSE**.
- Only Markdown documentation changed; no gameplay Lua, TOC, packaging metadata or assets were edited. This review **did not run WoW or automated tests**.

## October 22, 2026 — 0.3.0-beta: the original committed behavior

**`b60d08024cdd`**, “Ship Flourish Forever 0.3.0-beta with configurable ability emotes,” is the **first commit in this repository**. It already contains the complete three-file Lua architecture, UI, chance/cooldown controls, event listener and per-character storage. There is no preceding visible development commit for an earlier FlourishForever version in this repository.

- **Trigger:** player `UNIT_SPELLCAST_SUCCEEDED`, match configured ability by normalized name derived from event spell ID.
- **Randomness:** one uniformly random chosen enabled game emote token after independent chance and cooldown checks.
- **Configuration:** spellbook non-passives, ability-specific chance (0–100%), cooldown (0–120s), selected emote pool and per-character master enable.
- **Persistence:** account-wide TOC root with per-GUID character profiles; migration helper for previously loaded `ROARitFOREVERStorage` and name-keyed profiles.
- **UI:** Blizzard-style movable frame, dropdown, configured ability list, sliders, scrolling emote checkboxes, remove action.
- **Distribution:** `.pkgmeta` with `package-as: FlourishForever`, manual changelog.

The initial README describes casts as “landing”; source evidence narrows that to **reported cast success**. It is not an observed hit-condition check.

## October 22 — 0.3.1-beta: packaging/version-only update

**`56d8b67d719a`**, “Ship Flourish Forever 0.3.1-beta for the CurseForge packager,” updated **CHANGELOG.md, README.md and the TOC version only**. Its contemporaneous changelog says explicitly: **“No change to how emotes play.”**

GitHub release entries for [0.3.0-beta](https://github.com/babunidev/FlourishForever/releases/tag/v0.3.0-beta) and [0.3.1-beta](https://github.com/babunidev/FlourishForever/releases/tag/v0.3.1-beta) exist, published the same day. GitHub release metadata lists **no attached assets** for either. A packager-oriented commit does not prove the external publication or live game-client behavior.

## October 26 — attribution and initial history scaffold

- **`61c7aaddc1d6`** standardized the TOC author to **Babuni.dev** from an earlier Babunigaming credit.
- **`7e36f7156b51`** placed the creator credit in README, while retaining original Babunigaming development context.
- **`24013323e692`** created concise CONCEPT, ROADMAP, AGENTS, ARCHITECTURE, DECISIONS and DEVLOG files.
- **`b73fed5344bd`** linked those initial project-history files from README.

This October 27 editorial pass deepens the record without claiming the creator approved any new behavior or that the code was verified in game.

## 2026-11-01 — expressive-addon family history

- Connected Flourish Forever's cast-success and per-ability graphical selection to earlier action-slot emote addons.
- Clarified that available emote options come from the client, not arbitrary user-created animations. See [family history](docs/EMOTE_FAMILY_HISTORY.md). Documentation only.
