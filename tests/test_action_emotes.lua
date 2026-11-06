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
local chatLockdown = false
local restrictionStates = {}
local nativeAllowed = true
C_ChatInfo = {
    PerformEmote = function(token)
        if nativeAllowed then
            played[#played + 1] = token
            return true
        end
        return false
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
press(1, 200)
assert(#played == 4, "button-press mode fires immediately")
cast(100, 200.1, "cast-press")
assert(#played == 4, "button-press mode ignores cast success")
press(1, 200.05)
assert(#played == 4, "duplicate hook press suppressed")
press(1, 201)
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

-- Failed native API send does not consume cooldown, and chance zero is silent.
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
cast(100, 502, "allowed-native")
assert(#played == 9, "failed API response did not consume cooldown")

cfg.emotes = {}
cast(100, 550, "empty-pool")
assert(#played == 9, "intentionally empty pool silent")
cfg.cooldown = 0
cfg.emotes = "corrupt"
cast(100, 551, "restored-pool")
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
cast(100, 1050, "mixed-native")
assert(#played == nativeBefore + 1 and #sent == sentBefore,
    "success mode selects native token only")

-- Battleground Success is resolved to Button press only at runtime; it does not
-- modify SavedVariables. A PvP match restriction alone is not a chat lockdown.
cfg.emotes = { ROAR = { cooldown = 0 } }
currentInstanceType = "pvp"
restrictionStates[Enum.AddOnRestrictionType.PvPMatch] = 2
nativeBefore = #played
press(1, 1100)
assert(#played == nativeBefore + 1, "PvP success fallback uses hardware press")
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
    groupMode = case.group
    currentInstanceType = case.instance
    restrictionStates[Enum.AddOnRestrictionType.Map] = 2
    restrictionStates[Enum.AddOnRestrictionType.Encounter] = 2
    restrictionStates[Enum.AddOnRestrictionType.ChallengeMode] = 2
    cfg.trigger = "success"
    local before = #played
    cast(100, 1300 + i, "party-" .. i)
    assert(#played == before + 1, "success in group " .. case.group .. "/" .. case.instance)
    cfg.trigger = "press"
    before = #played
    press(1, 1340 + i)
    assert(#played == before + 1, "button press in group " .. case.group .. "/" .. case.instance)
    cfg.trigger = "failure"
    before = #played
    fire("UNIT_SPELLCAST_FAILED", 100, 1380 + i, "party-fail-" .. i)
    assert(#played == before + 1, "failure in group " .. case.group .. "/" .. case.instance)
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
cfg.trigger = "unknown"
cfg.chance = 0 / 0
cfg.emotes = { ROAR = { cooldown = math.huge } }
cast(100, 1500, "invalid-config")
assert(FlourishForeverDB.actionEmotesEnabled == false, "invalid master disables safely")
assert(cfg.trigger == "success", "bad trigger resets to success")
assert(cfg.chance == 100 and cfg.emotes.ROAR.cooldown == 120, "malformed values clamped")
assert(FlourishForeverDB.instances.corrupt == "invalid" and FlourishForeverDB.instances[5],
    "unknown save records preserved")
assert(select(2, FlourishForever_ActionStatus()) == 2, "status excludes malformed keys")

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
