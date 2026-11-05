# FlourishForever local UI merge — technical notes

**Source:** `FlourishForever.zip` supplied by Babuni on 2026-11-05. Its uncommitted local `FlourishForever_ActionEmotes.lua` contained a 1664-line implementation based on the older `v0.3.1-beta` checkout.

**Baseline:** current GitHub `main`, tagged `v0.3.2-beta` at `c15fe1bdc81563cc8f0a4215b706ca8c47daf0f6`. This development merge does not alter `main` or that public tag.

## Follow-up — November 5, 2026

Babuni installed the merged development build in WoW Forever and confirmed it works well in ordinary use. The exact scope of this in-game check was not itemized, so individual protected-chat paths, macros, migration across all profiles and RoarForever coexistence remain without recorded proof. A proposed `0.4.0-beta` release preparation now builds on the tested development branch. The earlier sections below document the original recovery stage; their "no tag" wording remains historically accurate for that stage.

## Restored features

- Multi-page 810 × 676 GUI with scrollable configured-ability overview, icons and per-ability on/off toggles.
- Spellbook-style categorized picker, emote search, individual emote cooldown sliders and custom `/e` text editor.
- Explicit search fields for both the configured-ability overview and the spellbook picker (new integration improvements).
- `/ffsh` alias alongside existing slash commands.

## Reconciliation with published safeguards

- Preserve current GUID-based profile storage and native `DoEmote` on player `UNIT_SPELLCAST_SUCCEEDED`.
- Normalize old `cfg.emotes[token] = true` using legacy per-ability `cfg.cooldown`; new saves store `{ cooldown = N }` per token.
- Do not spend a phantom cooldown before the first emote; keep independent cooldowns per token and ability.
- Validate numeric/finite skillbook IDs and skip passive, off-spec, future and non-spell entries.
- Bound chance, old cooldown and individual cooldown values, handle nonboolean master or per-ability switches, and retain unrecognized SavedVariables records for recovery.
- Keep custom emote IDs when changing text on an existing line; preserve selections referencing those IDs.
- Defer custom `/e` messages to a hardware-press hook when it is available and retain native `DoEmote` on cast success. A failed/aborted ability may still send custom text: custom messages are press-time while standard emotes are event-time.

## Testing evidence

- Syntax: `texlua` Lua 5.3 `assert(loadfile(...))` succeeded for all runtime modules.
- `texlua tests/test_action_emotes.lua` passed mocked migration, cooldown, chance, spellbook and custom/native trigger scenarios.
- `texlua tests/test_ui_mock.lua` passed a synthetic UI smoke test including home search, spellbook filtering, editor and custom text save.
- These are offline mocks, **not** confirmation against Forever's protected UI, actual spellbook, custom chat hardware requirements, or full in-game layout.

## Live regression checks still needed

1. Load a backed-up existing character profile, open `/flourish`, and verify previous ability/emote selections survive migration.
2. Verify overview on/off, searches, picker, icon layout, and emote editing at common UI scales; monitor Lua errors.
3. Test native emotes: first cast after `/reload`, per-emote cooldowns, two configured abilities, 0/100% chance, failed/interrupted casts.
4. Test custom `/e` text from normal action-bar use and macro/spellbook buttons while observing Forever's hardware restrictions. Custom text is intentionally issued at press time and may trigger even on failed cast; no proof of in-game success yet.
5. Inspect SavedVariables after reload and logout and verify different character GUID profiles do not share changes.
6. Validate compatibility with RoarForever and secure combat restrictions.

**Status:** GitHub development branch only. No Git tag or public release.
