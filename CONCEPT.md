# Flourish Forever — concept and creative direction

**Creative direction:** Babuni · **Portfolio:** babuni.dev.  
**Platform:** World of Warcraft: Forever, TOC interface 16001 (expanded build tested in-game on November 5, 2026; specific edge cases remain open).  
**Latest published Git tag:** v0.3.2-beta · **Next release candidate:** 0.4.0-beta (unpublished).

## A flourish of personality at the moment of action

Combat abilities can be mechanically identical every time they are used, while the character using them may have a very different personality. **Flourish Forever** links ordinary, player-chosen ability casts to an expressive action: an in-game emote. A Warrior's moment of aggression might produce a roar; another chosen spell might draw from entirely different gestures. The goal is **atmosphere and character expression**, not a gameplay advantage.

The creative requirement is choice. The player decides *which* abilities deserve a flourish, *which* emotes may accompany them, *how often* the response is allowed, and whether the system is active on this character at all. The addon must not force an unsolicited global roleplay persona onto other characters or every spell in the spellbook.

The October 22 creative discussion described the idea in terms of **automatic random emotes for selected abilities**. The updated implementation extends that principle with a searchable, categorized spellbook interface, a master switch, a curated spell list, per-ability chance, and independent cooldowns for each selected emote. The portfolio record credits Babuni's human direction without retroactively assigning its conception to an assistant.

## Variation without noise

An emote on every cast may become repetitive or irritating. The design gives each ability its own **0–100% probability** while each selected emote has its own **0–120-second cooldown**. A dramatic gesture can remain rare even when another gesture is eligible for that same ability.

Once a configured cast passes those checks, the program chooses uniformly from the enabled emote tokens. The player can select a single reliable signature gesture or a larger pool for surprise. **ROAR** is the default *allowed emote* when a spell is first added; it is not a hardcoded requirement, and the default ability list is empty.

The expanded editor offers both the game's native `DoEmote` vocabulary and player-written `/e` lines. The latter are ordinary chat emotes, not custom animations or new sound files. Native emotes follow cast-success while custom text is attempted during the player's button press; the two triggers are intentionally distinct.

## Honor the boundaries of player agency

The native-emote trigger is the player's **reported successful spellcast event**, not actual damage, a hit landing, or a game command automatically cast by Flourish Forever. Custom text emotes instead originate during the button-press hook and may occur before cast success. The addon never chooses or triggers a combat spell. It can send an emote after an eligible spellcast; this can have the ordinary visibility/social consequences of a normal in-game emote.

Character settings are isolated by **character GUID**, consistent with the realmless Forever naming environment. The existing source contains migration logic for previously name-keyed profiles, but the full historical ROARitFOREVER design conversation isn't present in the inspected Git repository. That conditional migration path isn't evidence a separate realm model applies.

## Why this small concept makes a useful portfolio piece

The interaction is an example of **emergent personality made from a few small systems**: a cast event, a probability decision, a time limit, a curated list and a user interface. The computer contributes variation; the player contributes taste and character identity.

The difference from an always-on automated announcer is essential. The player can curate or remove any configured spell, leave some abilities entirely untouched, disable the system without deleting settings, or uncheck every emote to make one configuration silent.

The expanded searchable interface and custom text were recovered from Babuni's earlier development archive and approved for integration. Other ideas, such as emote previews or global spam control, remain proposals rather than implemented features. They remain choices for Babuni after real in-game testing.

## Related development history

Flourish Forever is the October 2026 WoW Forever expression of the action-emote idea. Unlike the earlier action-slot hooks, it responds to the player’s **reported successful spellcast** event and lets the player select spellbook abilities and existing client-native emotes in a GUI. Each new ability initially has ROAR selected, but the player may choose other available emote tokens. This is client-token selection rather than creation of arbitrary new emotes, and cast success does not prove a landed hit. See the [source-grounded expressive-addon timeline](docs/EMOTE_FAMILY_HISTORY.md) for related projects and historical boundaries.
