# Flourish Forever — concept and creative direction

**Creative direction:** Babuni · **Portfolio:** babuni.dev.  
**Platform:** World of Warcraft: Forever, TOC interface 16001 (expanded build tested in-game on November 5, 2026; specific edge cases remain open).  
**Latest confirmed Git tag:** v0.4.3-beta · **New approved direction:** per-ability trigger timing, development only.

## A flourish of personality at the moment of action

Combat abilities can be mechanically identical every time they are used, while the character using them may have a very different personality. **Flourish Forever** links ordinary, player-chosen ability casts to an expressive action: an in-game emote. A Warrior's moment of aggression might produce a roar; another chosen spell might draw from entirely different gestures. The goal is **atmosphere and character expression**, not a gameplay advantage.

The creative requirement is choice. The player decides *which* abilities deserve a flourish, *which* emotes may accompany them, *how often* the response is allowed, and whether the system is active on this character at all. The addon must not force an unsolicited global roleplay persona onto other characters or every spell in the spellbook.

The October 22 creative discussion described the idea in terms of **automatic random emotes for selected abilities**. The updated implementation extends that principle with a searchable, categorized spellbook interface, a master switch, a curated spell list, per-ability chance, and independent cooldowns for each selected emote. The portfolio record credits Babuni's human direction without retroactively assigning its conception to an assistant.

## Timing belongs to the player

The original desired behavior remains the default: a flourish follows a **successful cast**, not merely a button press. Babuni also approved Button press and Failure as explicit per-ability timing choices beside the Chance control. This lets a Warrior's shout feel different from a spell that fizzles or an impatient gesture that comes before the action.

Success uses the player's own cast-success report; Failure uses failed or interrupted cast events; Button press uses the player-action hook. A battleground/arena temporarily switches the default Success mode to Button press to avoid the previously observed protected native-emote callback, provided chat is not locked down. It never changes the saved preference.

Forever's restrictions differ for native emotes and custom chat. Player-authored `/e` text requires direct input and cannot be promised on a later success/failure event. The implementation must say so in the editor rather than silently breaking protected-chat rules. The chosen emote pool, chance, cooldown, character identity and user agency remain unchanged.
## Variation without noise

An emote on every cast may become repetitive or irritating. The design gives each ability its own **0–100% probability** while each selected emote has its own **0–120-second cooldown**. A dramatic gesture can remain rare even when another gesture is eligible for that same ability.

Once a configured cast passes those checks, the program chooses uniformly from the enabled emote tokens. The player can select a single reliable signature gesture or a larger pool for surprise. **ROAR** is the default *allowed emote* when a spell is first added; it is not a hardcoded requirement, and the default ability list is empty.

The expanded editor offers both the game's native emote-token vocabulary and player-written `/e` lines. The latter are ordinary chat emotes, not custom animations or new sound files. In the public version, native emotes are attempted after cast-success and custom text during the player's button press. The experimental security fix instead triggers both on a real action press, with the possibility of emotes on failed casts. Babuni reported the revised behavior working as before and requested the patch; the failed-cast timing trade-off is documented.

## Honor the boundaries of player agency

Originally the native-emote trigger was the player's **reported successful spellcast event**, not an actual hit. Custom text is generated at the button press. The experimental 0.4.1-beta-dev implementation attempts both emote types on user action instead, never automatically casts a spell, and remains subject to Forever's security restrictions. The timing change is prepared for release following the positive general in-game report; the original cast-success version remains part of the recorded history.

Character settings are isolated by **character GUID**, consistent with the realmless Forever naming environment. The existing source contains migration logic for previously name-keyed profiles, but the full historical ROARitFOREVER design conversation isn't present in the inspected Git repository. That conditional migration path isn't evidence a separate realm model applies.

## Why this small concept makes a useful portfolio piece

The interaction is an example of **emergent personality made from a few small systems**: a player-chosen ability action, a probability decision, a time limit, a curated list and a user interface. The computer contributes variation; the player contributes taste and character identity.

The difference from an always-on automated announcer is essential. The player can curate or remove any configured spell, leave some abilities entirely untouched, disable the system without deleting settings, or uncheck every emote to make one configuration silent.

The expanded searchable interface and custom text were recovered from Babuni's earlier development archive and approved for integration. Other ideas, such as emote previews or global spam control, remain proposals rather than implemented features. They remain choices for Babuni after real in-game testing.

## Related development history

Flourish Forever is the October 2026 WoW Forever expression of the action-emote idea. Unlike the earlier action-slot hooks, it responds to the player’s **reported successful spellcast** event and lets the player select spellbook abilities and existing client-native emotes in a GUI. Each new ability initially has ROAR selected, but the player may choose other available emote tokens. This is client-token selection rather than creation of arbitrary new emotes, and cast success does not prove a landed hit. See the [source-grounded expressive-addon timeline](docs/EMOTE_FAMILY_HISTORY.md) for related projects and historical boundaries.
