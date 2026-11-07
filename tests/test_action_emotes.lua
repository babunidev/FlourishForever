-- Offline Lua 5.3/5.4 regression tests. WoW API mocks, NOT in-game verification.
local frames, hooks, played, sent = {}, {}, {}, {}
CreateFrame = function()
    local frame = { scripts = {}, events = {} }
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:SetScript(event, fn) self.scripts[event] = fn end
    frames[#frames + 1] = frame
    return frame
end
hooksecurefunc = function(a, b, c)
    if type(a) == "string" then hooks[a] = b
    elseif type(a) == "table" then hooks[b] = c end
end
UseAction = function() end
CastSpellByID = function() end
local now = 1
GetTime = function() return now end
-- Epoch time is stable across UI reloads; GetTime is only process-local.
GetServerTime = function() return 1730000000 + math.floor(now) end
local chatLockdown = false
local restrictionStates = {}
local nativeAllowed = true
local nativeVisibleDespiteFalse = false
C_ChatInfo = {
    PerformEmote = function(token)
        if nativeAllowed or nativeVisibleDespiteFalse then
            played[#played + 1] = token
        end
        return nativeAllowed
    end,
    InChatMessagingLockdown = function() return chatLockdown end,
}
C_RestrictedActions = {
    GetAddOnRestrictionState = function(kind) return restrictionStates[kind] or 0 end,
}
local currentInstanceType = "none"
local groupMode = "solo"
IsInGroup = function() return groupMode ~= "solo" end
IsInRaid = function() return groupMode == "raid" end
IsInInstance = function()
    return currentInstanceType ~= "none", currentInstanceType
end
DoEmote = function() error("deprecated DoEmote path must never run") end
SendChatMessage = function(message, channel)
    assert(channel == "EMOTE")
    sent[#sent + 1] = message
end
GetActionInfo = function(slot)
    if slot == 1 then return "spell", 100 end
    if slot == 2 then return "spell", 200 end
end
local names = { [100] = "Strike", [101] = "Passive", [102] = "Future", [103] = "Flyout", [104] = "Offspec", [105] = "Extra", [200] = "Second" }
C_Spell = {
    GetSpellName = function(id) return names[id] end,
    IsSpellPassive = function(id) return id == 101 end,
    IsSpellUsable = function(id) return true end,
}
Enum = {
    SpellBookSpellBank = { Player = 0 },
    SpellBookItemType = { Spell = 1, FutureSpell = 2, Flyout = 3, PetAction = 4 },
    AddOnRestrictionType = { Combat = 0, Encounter = 1, ChallengeMode = 2, PvPMatch = 3, Map = 4, Chat = 5 },
}
local items = {
    { itemType = 1, spellID = 100, name = "Strike" },
    { itemType = 1, spellID = 100, name = "Strike" },
    { itemType = 1, spellID = 101, name = "Passive", isPassive = true },
    { itemType = 2, spellID = 102, name = "Future" },
    { itemType = 3, spellID = 103, name = "Flyout" },
    { itemType = 1, spellID = 104, name = "Offspec", isOffSpec = true },
    { itemType = 1, spellID = 105, name = "Extra" },
    { itemType = 4, spellID = 200, name = "Pet action" },
}
C_SpellBook = {
    GetNumSpellBookSkillLines = function() return 1 end,
    GetSpellBookSkillLineInfo = function() return { name = "General", itemIndexOffset = 0, numSpellBookItems = #items } end,
    GetSpellBookItemInfo = function(index) return items[index] end,
}
FlourishForeverDB = {
    actionEmotesEnabled = true,
    instances = {
        strike = { name = "Strike", spellID = 100, chance = 100, cooldown = 120, emotes = { ROAR = true } },
        second = { name = "Second", spellID = 200, chance = 100, cooldown = 0, emotes = { CHEER = true } },
    },
}
_G.EMOTE1_TOKEN = "ROAR"
_G.EMOTE2_TOKEN = "CHEER"
assert(loadfile("FlourishForever_ActionEmotes.lua"))()
assert(#frames == 1)
local frame=frames[1]
for _, name in ipairs({
    "SPELLS_CHANGED", "UNIT_SPELLCAST_SUCCEEDED",
    "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_FAILED_QUIET",
    "UNIT_SPELLCAST_INTERRUPTED",
}) do
    assert(frame.events[name], "register " .. name)
end
local event=frame.scripts.OnEvent
local function fire(name, id, t, guid, unit)
    now = t
    event(frame, name, unit or "player", guid or ("cast-" .. tostring(t)), id)
end
local function cast(id, t, guid, unit)
    fire("UNIT_SPELLCAST_SUCCEEDED", id, t, guid, unit)
end
local function upvalue(fn, wanted)
    for i=1,100 do
        local name,value=debug.getupvalue(fn,i)
        if name==wanted then return value end
        if not name then break end
    end
    error("missing upvalue "..wanted)
end
local createUI=upvalue(FlourishForever_OpenConfig,"CreateUI")
local collect=upvalue(createUI,"CollectSpellColumns")
local columns=collect()
assert(#columns==1 and #columns[1].abilities==2, "modern learned-spell filtering")
assert(columns[1].abilities[1].spellID==100 and columns[1].abilities[2].spellID==105, "modern order and dedup")

-- Legacy spellbook only SPELL entries.
C_SpellBook=nil
GetNumSpellTabs=function()return 1 end
GetSpellTabInfo=function()return "General",nil,0,3,false end
GetSpellBookItemInfo=function(i)
    local kinds={"SPELL","FUTURESPELL","FLYOUT"}
    local ids={100,102,103}
    return kinds[i],ids[i]
end
GetSpellBookItemName=function(i)
    return ({"Strike","Future","Flyout"})[i]
end
columns=collect()
assert(#columns==1 and #columns[1].abilities==1 and columns[1].abilities[1].spellID==100,"legacy selection")

-- Each ability's default is success, including old SavedVariables records.
local function press(slot, t)
    now = t
    hooks.UseAction(slot)
end
assert(type(hooks.UseAction) == "function", "hardware press hook registered")
press(1, 1)
assert(#played == 0, "default success must not fire on press")
cast(100, 1.1, "cast-success-a")
assert(#played == 1 and played[1] == "ROAR", "first successful cast emotes")
assert(FlourishForeverDB.instances.strike.trigger == "success", "old saved ability defaults to success")
assert(type(FlourishForeverDB.instances.strike.emotes.ROAR) == "table", "boolean emote migration")
assert(FlourishForeverDB.instances.strike.emotes.ROAR.cooldown == 120, "old 120s cooldown migrated")

local savedEmotes = FlourishForeverDB.instances.strike.emotes
local savedEntry = savedEmotes.ROAR
cast(100, 1.2, "cast-success-a")
cast(100, 2, "cast-success-b")
assert(#played == 1, "duplicate event and per-token cooldown")
assert(savedEmotes == FlourishForeverDB.instances.strike.emotes and savedEntry == savedEmotes.ROAR,
    "normal casts preserve emote tables")
cast(200, 2, "second")
assert(#played == 2 and played[2] == "CHEER", "independent configured ability")
cast(100, 120, "cast-success-c")
assert(#played == 2, "cooldown not expired")
cast(100, 121.1, "cast-success-d")
assert(#played == 3, "native emote after cooldown")
fire("UNIT_SPELLCAST_FAILED", 100, 122, "failed-a")
assert(#played == 3, "success mode ignores failed casts")
cast(100, 123, "foreign", "target")
assert(#played == 3, "other units ignored")

-- Button-press mode is selectable independently for each ability.
local cfg = FlourishForeverDB.instances.strike
cfg.emotes = { ROAR = { cooldown = 0 } }
cfg.trigger = "press"
press(1, 250)
assert(#played == 4, "button-press mode fires immediately")
cast(100, 250.1, "cast-press")
assert(#played == 4, "button-press mode ignores cast success")
press(1, 250.05)
assert(#played == 4, "duplicate hook press suppressed")
press(1, 251)
assert(#played == 5, "next genuine button press fires")

-- Failure handles normal/quiet failures and interrupts, not success or presses.
cfg.trigger = "failure"
press(1, 300)
cast(100, 300.1, "success-while-failure")
assert(#played == 5, "failure mode ignores press and success")
fire("UNIT_SPELLCAST_FAILED", 100, 301, "fail-one")
assert(#played == 6, "failed cast triggers native emote")
fire("UNIT_SPELLCAST_INTERRUPTED", 100, 301.01, "fail-one")
assert(#played == 6, "same cast GUID cannot fire twice")
fire("UNIT_SPELLCAST_FAILED_QUIET", 100, 302, "fail-two")
assert(#played == 7, "quiet failed cast triggers")
fire("UNIT_SPELLCAST_INTERRUPTED", 100, 303, "fail-three")
assert(#played == 8, "interrupted cast triggers")
fire("UNIT_SPELLCAST_FAILED", 100, 303.1, "fail-three")
assert(#played == 8, "duplicate event ignored")
fire("UNIT_SPELLCAST_FAILED", 100, 304, "other-unit", "target")
assert(#played == 8, "foreign failures ignored")

-- A false native return does not claim success, but its attempted token
-- must not be called again until the configured retry delay has elapsed.
cfg.trigger = "success"
cfg.chance = 0
cast(100, 500, "chance-zero")
assert(#played == 8, "zero chance blocks success")
cfg.chance = 100
cfg.emotes.ROAR.cooldown = 120
nativeAllowed = false
cast(100, 501, "blocked-native")
assert(#played == 8, "failed native API response silent")
nativeAllowed = true
cast(100, 502, "suppressed-native-retry")
assert(#played == 8, "failed native attempt is rate-limited for 120 seconds")
cast(100, 621, "allowed-native-after-retry")
assert(#played == 9, "native retry resumes at the configured cooldown boundary")

cfg.emotes = {}
cast(100, 650, "empty-pool")
assert(#played == 9, "intentionally empty pool silent")
cfg.cooldown = 0
cfg.emotes = "corrupt"
cast(100, 750, "restored-pool")
assert(#played == 10, "corrupt pool recovered")

-- Custom /e requires hardware input. Do not send it asynchronously on success or failure.
FlourishForeverDB.customEmotes = { { id = "1", text = "shakes her head" } }
FlourishForeverDB.customEmoteSeq = 1
cfg.emotes = { ["c:1"] = { cooldown = 30 } }
cfg.trigger = "success"
press(1, 1000)
cast(100, 1000.1, "custom-success")
assert(#sent == 0, "custom chat never sent from success event")
cfg.trigger = "failure"
fire("UNIT_SPELLCAST_FAILED", 100, 1001, "custom-failure")
assert(#sent == 0, "custom chat never sent from failed event")
cfg.trigger = "press"
press(1, 1002)
assert(#sent == 1 and sent[1] == "shakes her head", "custom /e on press")
press(1, 1003)
assert(#sent == 1, "custom per-token cooldown")
press(1, 1032)
assert(#sent == 2, "custom cooldown expires")

-- Success mode filters custom tokens rather than randomly selecting silence.
cfg.trigger = "success"
cfg.emotes = { ROAR = { cooldown = 0 }, ["c:1"] = { cooldown = 0 } }
local sentBefore, nativeBefore = #sent, #played
cast(100, 1070, "mixed-native")
assert(#played == nativeBefore + 1 and #sent == sentBefore,
    "success mode selects native token only")

-- Battleground Success is resolved to Button press only at runtime; it does not
-- modify SavedVariables. A PvP match restriction alone is not a chat lockdown.
cfg.emotes = { ROAR = { cooldown = 0 } }
currentInstanceType = "pvp"
restrictionStates[Enum.AddOnRestrictionType.PvPMatch] = 2
nativeBefore = #played
C_Spell.IsSpellUsable = function() return false end
press(1, 1100)
assert(#played == nativeBefore + 1, "PvP fallback works despite false spell usability")
C_Spell.IsSpellUsable = function() return true end
cast(100, 1100.1, "pvp-success")
assert(#played == nativeBefore + 1, "PvP success never runs delayed emote")
assert(cfg.trigger == "success", "PvP fallback must not overwrite saved mode")
cfg.trigger = "failure"
press(1, 1101)
fire("UNIT_SPELLCAST_FAILED", 100, 1101.1, "pvp-failure")
assert(#played == nativeBefore + 1, "explicit failure remains distinct and safely suppressed")
cfg.trigger = "success"
currentInstanceType = "none"
restrictionStates[Enum.AddOnRestrictionType.PvPMatch] = 0
press(1, 1110)
assert(#played == nativeBefore + 1, "world success mode no press emote")
cast(100, 1110.1, "back-world")
assert(#played == nativeBefore + 2, "world success behavior restored")
currentInstanceType = "arena"
press(1, 1112)
assert(#played == nativeBefore + 3, "arena also uses PvP press fallback")
nativeAllowed = false
press(1, 1114)
cast(100, 1114.1, "arena-later-event")
local pvpDiagnostic = FlourishForever_EmoteDiagnostics()
assert(pvpDiagnostic:find("lastDispatch=native emote API returned false; attempt throttled for ROAR", 1, true),
    "later PvP cast event must not erase the native send refusal")
nativeAllowed = true
chatLockdown = true
press(1, 1113)
assert(#played == nativeBefore + 3, "PvP press fallback respects true chat lockdown")
chatLockdown = false
currentInstanceType = "none"

-- Any true chat restriction overrides both native and custom press dispatch.
chatLockdown = true
cfg.trigger = "press"
nativeBefore = #played
press(1, 1200)
assert(#played == nativeBefore, "hardware press blocked under actual chat lockdown")
chatLockdown = false
restrictionStates[Enum.AddOnRestrictionType.Chat] = 1
press(1, 1201)
assert(#played == nativeBefore, "activating chat restriction blocks press")
cast(100, 1201.1, "chat-event")
assert(#played == nativeBefore, "chat restriction blocks event")
restrictionStates[Enum.AddOnRestrictionType.Chat] = 0

-- Ordinary parties, dungeons and raids remain supported with addon DATA lockdown.
for i, case in ipairs({
    { group = "party", instance = "none" },
    { group = "party", instance = "party" },
    { group = "raid", instance = "raid" },
}) do
    local timeBase = 1300 + (i - 1) * 100 -- event order must remain monotonic
    groupMode = case.group
    currentInstanceType = case.instance
    restrictionStates[Enum.AddOnRestrictionType.Map] = 2
    restrictionStates[Enum.AddOnRestrictionType.Encounter] = 2
    restrictionStates[Enum.AddOnRestrictionType.ChallengeMode] = 2
    cfg.trigger = "success"
    local before = #played
    cast(100, timeBase + 1, "party-" .. i)
    assert(#played == before + 1, "success in group " .. case.group .. "/" .. case.instance)
    cfg.trigger = "press"
    before = #played
    press(1, timeBase + 2)
    assert(#played == before + 1, "button press in group " .. case.group .. "/" .. case.instance)
    cfg.trigger = "failure"
    before = #played
    fire("UNIT_SPELLCAST_FAILED", 100, timeBase + 3, "party-fail-" .. i)
    assert(#played == before + 1, "failure in group " .. case.group .. "/" .. case.instance)

    cfg.trigger = "press"
    cfg.emotes = { ["c:1"] = { cooldown = 0 } }
    local beforeCustom = #sent
    press(1, timeBase + 4)
    assert(#sent == beforeCustom + 1, "custom /e press in " .. case.group .. "/" .. case.instance)
    cfg.emotes = { ROAR = { cooldown = 0 } }
end
for _, kind in ipairs({
    Enum.AddOnRestrictionType.Map, Enum.AddOnRestrictionType.Encounter,
    Enum.AddOnRestrictionType.ChallengeMode,
}) do
    restrictionStates[kind] = 0
end
currentInstanceType = "none"
groupMode = "solo"

-- Invalid values normalize to Success without altering unrelated saved records.
FlourishForeverDB.instances[5] = { emotes = {} }
FlourishForeverDB.instances.corrupt = "invalid"
FlourishForeverDB.actionEmotesEnabled = "invalid"
cfg.trigger = 0 / 0 -- corrupt SavedVariables should never index a table with NaN
cfg.chance = 0 / 0
cfg.emotes = { ROAR = { cooldown = math.huge } }
cast(100, 1700, "invalid-config")
assert(FlourishForeverDB.actionEmotesEnabled == false, "invalid master disables safely")
assert(cfg.trigger == "success", "bad trigger resets to success")
assert(cfg.chance == 100 and cfg.emotes.ROAR.cooldown == 120, "malformed values clamped")
assert(FlourishForeverDB.instances.corrupt == "invalid" and FlourishForeverDB.instances[5],
    "unknown save records preserved")
assert(select(2, FlourishForever_ActionStatus()) == 2, "status excludes malformed keys")
local diag = FlourishForever_EmoteDiagnostics()
assert(diag:find("instance=none", 1, true)
    and diag:find("presses=", 1, true)
    and diag:find("attempts=", 1, true)
    and diag:find("ChatState=", 1, true)
    and diag:find("lastSpell=", 1, true)
    and diag:find("lastDispatch=", 1, true),
    "read-only diagnostics expose relevant client states without player identifiers")

-- New behavior: each emote has a selectable cooldown duration, but once
-- selected that duration locks the ENTIRE ability, including other tokens.
FlourishForeverDB.actionEmotesEnabled = true
cfg.enabled, cfg.chance, cfg.trigger = true, 100, "press"
cfg.emotes = { ROAR = { cooldown = 3 } }
local first = #played
press(1, 2000)
assert(#played == first + 1 and played[#played] == "ROAR", "first 3s emote fires")
assert(cfg.abilityLock.token == "ROAR" and cfg.abilityLock.duration == 3,
    "3s token starts an ability-wide 3s lock")
cfg.emotes = { CHEER = { cooldown = 20 } }
press(1, 2001)
assert(#played == first + 1, "another token cannot bypass the running ability lock")
press(1, 2003)
assert(#played == first + 2 and played[#played] == "CHEER", "20s emote follows 3s lock")
assert(cfg.abilityLock.token == "CHEER" and cfg.abilityLock.duration == 20,
    "20s token starts a 20s lock for the whole ability")
cfg.emotes = { ROAR = { cooldown = 3 }, CHEER = { cooldown = 20 } }
press(1, 2004)
press(1, 2022.7)
assert(#played == first + 2, "3s emote cannot bypass a 20s CHEER lock")
press(1, 2023)
assert(#played == first + 3, "next random selected emote allowed when ability unlocks")
local chosen = played[#played]
assert(cfg.abilityLock.token == chosen
    and cfg.abilityLock.duration == cfg.emotes[chosen].cooldown,
    "new lock uses chosen token's configured duration")

-- Reload preserves the *ability* lock rather than reinstating old per-token
-- histories; the selected cooldown duration is snapshotted at trigger time.
cfg.emotes = { ROAR = { cooldown = 60 } }
press(1, 2100)
assert(#played == first + 4 and cfg.abilityLock.duration == 60,
    "60s lock starts when long-cooldown emote selected")
now = 2101
assert(loadfile("FlourishForever_ActionEmotes.lua"))()
press(1, 2101)
assert(#played == first + 4, "ability lock survives /reload")
cfg.emotes.ROAR.cooldown = 15
press(1, 2115)
assert(#played == first + 4, "editing slider does not shorten a running 60s lock")
press(1, 2160)
assert(#played == first + 5 and cfg.abilityLock.duration == 15,
    "next selected ROAR uses its newly configured 15s duration")
press(1, 2174)
assert(#played == first + 5, "new 15s lock enforced")
press(1, 2175)
assert(#played == first + 6, "15s lock expires on schedule")

-- Independent abilities must never share a lock, even when they use the same
-- emote token or have otherwise identical settings.
local secondCfg = FlourishForeverDB.instances.second
secondCfg.trigger, secondCfg.chance, secondCfg.enabled = "press", 100, true
secondCfg.emotes = { ROAR = { cooldown = 120 } }
press(2, 2176)
assert(#played == first + 7 and played[#played] == "ROAR",
    "second ability can fire while Strike is locked")
press(2, 2177)
assert(#played == first + 7 and secondCfg.abilityLock.duration == 120,
    "second ability honors its own long lock")

-- Zero is a genuine no-cooldown choice; duplicate-hook dedupe still applies.
cfg.emotes = { ROAR = { cooldown = 0 } }
press(1, 2200)
press(1, 2200.3)
assert(#played == first + 9 and cfg.abilityLock.duration == 0,
    "zero-second selection allows separate button presses")

-- Native false is not a confirmed success; nevertheless it can appear
-- visibly in Forever, so the attempt itself locks the entire ability.
cfg.emotes = { FAINT = { cooldown = 6 }, ROAR = { cooldown = 3 } }
-- Select FAINT alone first to unambiguously start a 6s lock.
cfg.emotes = { FAINT = { cooldown = 6 } }
nativeAllowed = false
nativeVisibleDespiteFalse = true
local beforeFalse = #played
press(1, 2300)
assert(#played == beforeFalse + 1 and cfg.abilityLock.token == "FAINT"
    and cfg.abilityLock.duration == 6,
    "false native FAINT starts the configured ability-wide 6s retry lock")
assert(cfg.emotes.FAINT.lastFiredAt == nil
    and type(cfg.emotes.FAINT.lastAttemptAt) == "number",
    "native false preserves distinct attempt/success evidence")
cfg.emotes.ROAR = { cooldown = 3 }
press(1, 2301)
press(1, 2305.7)
assert(#played == beforeFalse + 1, "ROAR cannot fire during rejected FAINT's lock")
local report = FlourishForever_CooldownDiagnostics("strike")
assert(report[1]:find("selected=2 emotes", 1, true)
    and report[2]:find("Ability lock", 1, true)
    and report[2]:find("FAINT", 1, true), "diagnostics describe ability lock and chosen token")
now = 2305.8
assert(loadfile("FlourishForever_ActionEmotes.lua"))()
press(1, 2305.7)
assert(#played == beforeFalse + 1, "native false ability lock persists through reload")
nativeAllowed = true
nativeVisibleDespiteFalse = false
-- Choose only ROAR for a deterministic next selection.
cfg.emotes = { ROAR = { cooldown = 3 } }
press(1, 2306.2)
assert(#played == beforeFalse + 2 and cfg.abilityLock.duration == 3,
    "new selected emote can fire once false-result lock expires")

-- Custom /e selects its own ability-wide duration and persists across reload.
cfg.emotes = { ["c:1"] = { cooldown = 30 } }
local beforeCustom = #sent
press(1, 2350)
assert(#sent == beforeCustom + 1 and cfg.abilityLock.duration == 30,
    "custom /e starts full-ability lock")
now = 2351
assert(loadfile("FlourishForever_ActionEmotes.lua"))()
press(1, 2351)
assert(#sent == beforeCustom + 1, "custom ability lock persists through reload")
cfg.emotes = { ROAR = { cooldown = 3 }, ["c:1"] = { cooldown = 30 } }
press(1, 2379)
assert(#sent == beforeCustom + 1 and #played == beforeFalse + 2,
    "other native token cannot bypass custom's 30s lock")
cfg.emotes = { ["c:1"] = { cooldown = 30 } }
press(1, 2380)
assert(#sent == beforeCustom + 2, "custom lock expires at 30 seconds")

-- Chance rejection and client chat restriction must not start a new lock.
cfg.emotes = { ROAR = { cooldown = 3 } }
cfg.chance = 0
press(1, 2450)
assert(cfg.abilityLock.duration == 30, "chance rejection retains last lock without resetting it")
cfg.chance = 100
chatLockdown = true
press(1, 2451)
assert(cfg.abilityLock.duration == 30, "chat lockdown never starts a new ability lock")
chatLockdown = false
press(1, 2452)
assert(cfg.abilityLock.duration == 3, "ability can fire after lockdown ends")

-- Malformed saved locks cannot indefinitely silence an ability.
cfg.abilityLock = { token = "ROAR", duration = math.huge, startedAt = math.huge }
now = 2500
assert(loadfile("FlourishForever_ActionEmotes.lua"))()
press(1, 2500)
assert(cfg.abilityLock.duration == 3 and #played == beforeFalse + 4,
    "corrupt lock discarded and normal emote starts")

-- The no-argument report still uses the most recently matched ability.
local final = FlourishForever_CooldownDiagnostics("strike")
assert(final[2]:find("Ability lock", 1, true)
    and final[2]:find("3.0s remaining", 1, true)
    and final[3]:find("3s ability lock if chosen", 1, true),
    "manual cooldown report shares runtime ability-lock calculation")
assert(FlourishForever_CooldownDiagnostics("nonexistent")[1]
    :find("No configured ability", 1, true), "unknown ability lookup is safe")
assert(FlourishForever_EmoteDiagnostics():find("lastTokenCooldown=3", 1, true),
    "debug reflects actual chosen emote duration")

-- Current storage module still migrates an existing name-keyed profile.
local oldProfile = { actionEmotesEnabled = false, instances = {} }
ROARitFOREVERStorage = nil
FlourishForeverStorage = { profiles = { Tester = oldProfile } }
UnitGUID = function() return "Player-TEST" end
UnitName = function() return "Tester" end
GetRealmName = function() return "" end
assert(loadfile("FlourishForever_Storage.lua"))()
local migrated, guid = FlourishForever_BindCharacterDB()
assert(guid == "Player-TEST" and migrated == oldProfile,"old profile migrated")
assert(FlourishForeverStorage.profiles.Tester == nil,"legacy profile removed after migration")
assert(FlourishForeverStorage.profiles[guid] == oldProfile,"GUID profile retained")

print("PASS: success/press/failure trigger modes, PvP fallback, groups, chat guards, custom safety and migration")
