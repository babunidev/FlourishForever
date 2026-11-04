# Flourish Forever — concept and creative direction

**Creative direction:** Babuni · **Portfolio:** babuni.dev.  
**Platform:** World of Warcraft: Forever, TOC interface 16001 (beta-tested; release client requires confirmation).  
**Latest GitHub release:** 0.3.1-beta; this is a version identifier, not a statement that the client remains in beta.

## A flourish of personality at the moment of action

Combat abilities can be mechanically identical every time they are used, while the character using them may have a very different personality. **Flourish Forever** links ordinary, player-chosen ability casts to an expressive action: an in-game emote. A Warrior's moment of aggression might produce a roar; another chosen spell might draw from entirely different gestures. The goal is **atmosphere and character expression**, not a gameplay advantage.

The creative requirement is choice. The player decides *which* abilities deserve a flourish, *which* emotes may accompany them, *how often* the response is allowed, and whether the system is active on this character at all. The addon must not force an unsolicited global roleplay persona onto other characters or every spell in the spellbook.

The October 22 creator discussion described the idea in terms of **automatic random emotes for selected abilities**. The current code supplies the implementation: a master switch, a curated spell list, and per-ability chance, cooldown and allowed-emote set. The portfolio record credits Babuni's human direction without retroactively assigning its conception to an assistant.

## Variation without noise

An emote on every cast may become repetitive or irritating. The design therefore gives each ability its own **0–100% probability** and **0–120-second interval** between played emotes. The chance and rate are not global; a rare dramatic cooldown can feel different from a frequently used utility ability.

Once a configured cast passes those checks, the program chooses uniformly from the enabled emote tokens. The player can select a single reliable signature gesture or a larger pool for surprise. **ROAR** is the default *allowed emote* when a spell is first added; it is not a hardcoded requirement, and the default ability list is empty.

The checkboxes do not create a custom written sentence, a sound library or an animation replacement. They select from the existing game's `DoEmote` vocabulary and whatever sound/character animation the client itself associates with it.

## Honor the boundaries of player agency

The gameplay trigger is the player's **reported successful spellcast event**, not actual damage, a hit landing, or a game command automatically cast by Flourish Forever. The addon never chooses or triggers a combat spell. It can send an emote after an eligible spellcast; this can have the ordinary visibility/social consequences of a normal in-game emote.

Character settings are isolated by **character GUID**, consistent with the realmless Forever naming environment. The existing source contains migration logic for previously name-keyed profiles, but the full historical ROARitFOREVER design conversation isn't present in the inspected Git repository. That conditional migration path isn't evidence a separate realm model applies.

## Why this small concept makes a useful portfolio piece

The interaction is an example of **emergent personality made from a few small systems**: a cast event, a probability decision, a time limit, a curated list and a user interface. The computer contributes variation; the player contributes taste and character identity.

The difference from an always-on automated announcer is essential. The player can curate or remove any configured spell, leave some abilities entirely untouched, disable the system without deleting settings, or uncheck every emote to make one configuration silent.

The next creative choices—more nuanced animation cues, previewing an emote, safety controls for rapid actions or visual redesign—are not implied approvals simply because they are recorded in a roadmap. They remain choices for Babuni after real in-game testing.

## Related development history

Flourish Forever is the October 2026 WoW Forever expression of the action-emote idea. Unlike the earlier action-slot hooks, it responds to the player’s **reported successful spellcast** event and lets the player select spellbook abilities and existing client-native emotes in a GUI. Each new ability initially has ROAR selected, but the player may choose other available emote tokens. This is client-token selection rather than creation of arbitrary new emotes, and cast success does not prove a landed hit. See the [source-grounded expressive-addon timeline](docs/EMOTE_FAMILY_HISTORY.md) for related projects and historical boundaries.
