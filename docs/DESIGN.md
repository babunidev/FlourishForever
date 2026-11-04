# Flourish Forever — visual and interaction design

**Creative direction:** Babuni · **Portfolio:** babuni.dev.  
**Source:** current 0.3.1-beta UI Lua. The initial audit found no artwork; Babuni-supplied portfolio artwork was added on October 27, 2026.

## A stage manager for a character's gestures

The player isn't authoring a new combat effect. They're deciding **how their character reacts to moments already happening in game**. That implies a configuration tool which stays out of combat most of the time.

Flourish Forever uses a Blizzard-style inset window rather than floating new action buttons over the battlefield. The approximately **620×520-pixel** panel can be dragged and closed; its content is plainly divided between the spell that triggers a flourish and the actions the character might perform afterward.

The player opens it with **/flourish**, while `/flourish config`, `ui`, `/flourishforever`, and `/rit` are other entry points. Because the UI is built lazily, nothing has to stay onscreen during a fight.

## Progressive choices inside the panel

At the top, one **Enable ability emotes** checkbox acts as the character's master switch. This doesn't erase the spell configurations and is initially enabled but silent when no abilities are added.

Immediately below, **Add ability** opens a dropdown populated from the character's spellbook, excluding known passive spells. The configured abilities occupy a scrollable list on the left. Choosing an item reveals its controls in the editor on the right; removing it removes both its saved settings and session cooldown entry.

The right editor answers three approachable questions:
- **How often?** Chance from 0% to 100%, in 1% increments.
- **How soon again?** Cooldown from 0 to 120 seconds, in whole seconds.
- **What can happen?** A scrollable list of native WoW emote tokens with independent checkboxes. One enabled token gets picked at random.

No random emote plays when the player leaves the pool empty. A spell added for the first time starts at 100% chance, 6-second cooldown and ROAR checked; those are starter values, not an immutable character identity.

## Visual vocabulary

The addon uses the existing game UI templates: `BasicFrameTemplateWithInset`, `UICheckButtonTemplate`, `OptionsSliderTemplate`, `UIDropDownMenuTemplate`, `UIPanelButtonTemplate`, native scroll frames and standard fonts. There are **no runtime sprites, custom fonts, emote previews or animation assets**. Promotional artwork lives separately in `assets/portfolio/`. The actual flourish comes from `DoEmote` and the client/race's built-in result.

This restraint makes the addon an expressive tool rather than an art asset mod. In-game character personality is created by **selection and timing**, not new textures.

## Interaction details worth testing

The ability selector sorts spellbook results alphabetically, with ID ordering for equal names. Its *stored* key is a lowercase name, however, so rank variants may share settings; the UI could show multiple entries that edit one configuration. The scrollable emote list can be long and inherits the client's token availability.

There is currently **no built-in preview button**, no separate custom text authoring, no emote-scene editor and no UI control for keeping cooldowns through logout. These are potential future decisions, not overlooked documentation of existing functionality.

Possible accessibility/UX questions include slider readability at small scales, a visible warning that actual emotes may appear in normal chat, filtering unavailable tokens, and avoiding too many repeated noises in group content. None has been verified through an in-game test in this documentation audit.

## Related development history

Flourish Forever is the October 2026 WoW Forever expression of the action-emote idea. Unlike the earlier action-slot hooks, it responds to the player’s **reported successful spellcast** event and lets the player select spellbook abilities and existing client-native emotes in a GUI. Each new ability initially has ROAR selected, but the player may choose other available emote tokens. This is client-token selection rather than creation of arbitrary new emotes, and cast success does not prove a landed hit. See the [source-grounded expressive-addon timeline](EMOTE_FAMILY_HISTORY.md) for related projects and historical boundaries.
