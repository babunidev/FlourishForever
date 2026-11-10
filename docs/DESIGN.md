# Flourish Forever — visual and interaction design

**Creative direction:** Babuni · **Portfolio:** babuni.dev · **Target:** Forever interface 16001.  
**Latest Git tag:** v0.5.0-beta (per-ability Triggered by selector) · **Development:** 0.6.0-beta-dev adds a custom-only trigger warning beside the emote heading and PvP-pause help text. The earlier 0.3.2-beta used a smaller 620×520 layout.


## Cooldown slider behavior — 7 November development

Each selected emote keeps its individual 0–120-second slider. The editor now explains that the *chosen* emote's duration locks its entire ability until the timer expires; no alternate selected emote can play during that lock. A subsequent random emote may have a different cooldown duration. The Chance and Triggered by controls are unchanged, and the cooldown is never shared across different configured abilities.

The existing `/flourish cooldowns` readout shows the active ability lock and the duration each selected token would impose if chosen. The interface and diagnostics have mocked coverage; game-client visuals and actual live timing remain to be verified.

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

## Ability trigger control — development

Beside the Chance slider on each ability's editor page is a compact **Triggered by** dropdown with three choices: Success, Button press, Failure. Its selected value persists for this character's selected ability and defaults to Success for existing as well as newly added abilities. The dropdown has no effect on the saved chance or cooldown choices. In battlegrounds/arenas, a saved Success choice temporarily uses Button press when chat is permitted; the selector still displays the saved Success value.

A short inline description states that **custom /e requires button press** and that outcome-based triggers are native-only. This avoids suggesting an impossible automatic custom-chat action under Forever's hardware input rule. The option list is built inside the editor and does not add external UI dependencies.

The new control has mocked UI checks but has not been visually or behaviorally verified in the game client.
## Verification and accessibility

Babuni confirmed the installed expanded development build works well in-game on November 5, 2026. Automated UI mocks passed, but this does not establish thorough testing of every button, UI scale, screen-reader/keyboard behavior, macro or protected custom chat condition. Those remain explicit release follow-ups.

## History

The original 0.3.0–0.3.2 implementation used a roughly 620×520 editor with a simpler spell dropdown and a single shared cooldown per ability. The expanded interface was recovered from an earlier local source ZIP and integrated into the current Forever codebase, preserving compatible stored data and current safety fixes.
