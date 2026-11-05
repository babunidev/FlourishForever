# Flourish Forever — visual and interaction design

**Creative direction:** Babuni · **Portfolio:** babuni.dev · **Target:** Forever interface 16001.  
**Current public tag:** v0.4.1-beta · **Prepared patch:** 0.4.2-beta. The earlier 0.3.2-beta used a smaller 620×520 layout.

## Expanded configuration window

The player opens a movable Blizzard-style **810×676** window using `/flourish` or an alias. The four UI pages guide a player from a general overview to selecting an ability, assigning emotes and managing custom text:

1. **Ability overview:** scrollable rows with spell icons, ability names, emote summaries and per-ability enable switches. A search field filters configured abilities.
2. **Spellbook picker:** categorized spellbook-style columns for available abilities, with search across spell names. Non-spell/passive/off-spec entries are filtered from the available set.
3. **Ability editor:** selected spell icon and title, 0–100% chance slider, searchable list of native and custom emotes with selection checkboxes and independent 0–120-second cooldown sliders.
4. **Custom emotes:** a multiline editor for player-authored `/e` text. Saving retains identifiers where possible so existing assignments survive edits.

The character-wide switch can silence all configured flourishes; each ability can also be individually disabled without removing its preferences. A new character starts with an empty ability list.

## Experience and design principles

- The interface is built with game-native frames, icons, sliders, scroll surfaces, fonts and checkboxes; portfolio artwork is not loaded by the addon.
- Displayed spells originate in the player's spellbook, not from a hand-maintained class roster.
- **ROAR** remains the initial native selection for a newly configured ability; other native emotes and custom lines are optional.
- Each selected emote has its own cooldown, rather than forcing one shared delay on an entire ability.
- Public 0.4.1-beta native emotes use cast-success, while custom `/e` text runs on a player action. The 0.4.2-beta candidate attempts both on the press to avoid protected delayed calls; this may emote on failed casts. Babuni reported no noticeable difference during general in-game use.

## Verification and accessibility

Babuni confirmed the installed expanded development build works well in-game on November 5, 2026. Automated UI mocks passed, but this does not establish thorough testing of every button, UI scale, screen-reader/keyboard behavior, macro or protected custom chat condition. Those remain explicit release follow-ups.

## History

The original 0.3.0–0.3.2 implementation used a roughly 620×520 editor with a simpler spell dropdown and a single shared cooldown per ability. The expanded interface was recovered from an earlier local source ZIP and integrated into the current Forever codebase, preserving compatible stored data and current safety fixes.
