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
assert(not frame.events.UNIT_SPELLCAST_SUCCEEDED and frame.events.SPELLS_CHANGED,
    "do not listen for delayed cast-success emotes")
local event=frame.scripts.OnEvent
local function cast(id,t,unit)
    now=t
    event(frame,"UNIT_SPELLCAST_SUCCEEDED",unit or "player","cast-id",id)
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

-- No automatic native emotes from delayed events: the old crash path is gone.
local function press(slot, t)
    now = t
    hooks.UseAction(slot)
end
assert(type(hooks.UseAction) == "function", "player action hook registered")
cast(100, 1)
assert(#played == 0, "delayed cast event never performs a protected emote")
press(1, 1)
assert(#played == 1 and played[1] == "ROAR", "first native emote on player press")
assert(type(FlourishForeverDB.instances.strike.emotes.ROAR) == "table", "boolean migrated")
assert(FlourishForeverDB.instances.strike.emotes.ROAR.cooldown == 120, "legacy cooldown migrated")
local settings = FlourishForeverDB.instances.strike.emotes
local savedEntry = settings.ROAR
press(1, 2)
assert(settings == FlourishForeverDB.instances.strike.emotes
    and settings.ROAR == savedEntry, "normal presses do not rebuild emote selection")
assert(#played == 1, "independent native token cooldown")
press(2, 2)
assert(#played == 2 and played[2] == "CHEER", "second ability independent")
press(1, 120)
assert(#played == 2, "cooldown not expired")
press(1, 121)
assert(#played == 3, "cooldown expired")
cast(100, 122)
assert(#played == 3, "no asynchronous native fallback")

-- Chance failures and native API rejection must not consume emote cooldown.
FlourishForeverDB.instances.strike.emotes.ROAR.cooldown = 0
FlourishForeverDB.instances.strike.chance = 0
press(1, 200)
assert(#played == 3, "zero chance silent")
FlourishForeverDB.instances.strike.chance = 100
nativeAllowed = false
press(1, 201)
assert(#played == 3, "rejected native emote silent")
nativeAllowed = true
press(1, 202)
assert(#played == 4, "rejected call did not consume token cooldown")

FlourishForeverDB.instances.strike.emotes = {}
press(1, 300)
assert(#played == 4, "intentional empty pool")
FlourishForeverDB.instances.strike.cooldown = 0 -- recovery inherits the saved ability-level default
FlourishForeverDB.instances.strike.emotes = "corrupt"
press(1, 301)
assert(#played == 5 and played[5] == "ROAR", "corrupt pool restored")

-- Invalid settings are bounded, and unknown records remain recoverable.
FlourishForeverDB.instances[5] = { emotes = {} }
FlourishForeverDB.instances.corrupt = "invalid"
FlourishForeverDB.actionEmotesEnabled = "invalid"
FlourishForeverDB.instances.strike.chance = 0 / 0
FlourishForeverDB.instances.strike.emotes.ROAR.cooldown = math.huge
press(1, 400)
assert(FlourishForeverDB.actionEmotesEnabled == false, "malformed master safely disabled")
assert(FlourishForeverDB.instances.strike.chance == 100, "NaN chance reset")
assert(FlourishForeverDB.instances.strike.emotes.ROAR.cooldown == 120, "infinite cooldown clamped")
assert(FlourishForeverDB.instances.corrupt == "invalid" and FlourishForeverDB.instances[5],
    "unrecognized saved entries kept")
assert(select(2, FlourishForever_ActionStatus()) == 2, "status excludes invalid configs")
assert(#played == 5, "malformed master remains silent")

-- Custom /e is also pressed directly, never sent from delayed event.
FlourishForeverDB.actionEmotesEnabled = true
FlourishForeverDB.customEmotes = { { id = "1", text = "shakes her head" } }
FlourishForeverDB.customEmoteSeq = 1
FlourishForeverDB.instances.strike.emotes = { ["c:1"] = { cooldown = 30 } }
FlourishForeverDB.instances.strike.chance = 100
press(1, 1000)
assert(#sent == 1 and sent[1] == "shakes her head", "custom emote on press")
cast(100, 1000.1)
assert(#played == 5, "delayed event silent after custom emote")
press(1, 1001)
assert(#sent == 1, "custom token cooldown")
press(1, 1031)
assert(#sent == 2, "custom token cooldown expiry")

-- Native emote now fires on a genuine action, not the subsequent cast.
FlourishForeverDB.instances.strike.emotes = { ROAR = { cooldown = 0 } }
press(1, 1100)
assert(#played == 6, "native performed synchronously from hardware press")
cast(100, 1100.1)
assert(#played == 6, "successful cast does not duplicate emote")
press(1, 1100.05)
assert(#played == 6, "rapid duplicate hardware hook suppressed")

-- PvP silence works even when IsInInstance does not yet say pvp.
local nativeCount, customCount = #played, #sent
for _, instanceType in ipairs({ "pvp", "arena" }) do
    currentInstanceType = instanceType
    press(1, 1200)
    cast(100, 1200.1)
    assert(#played == nativeCount and #sent == customCount,
        "native and custom silent in " .. instanceType)
end
currentInstanceType = "none"
restrictionStates[Enum.AddOnRestrictionType.PvPMatch] = 1 -- Activating
press(1, 1201)
assert(#played == nativeCount, "PvP restriction blocks during transition")
restrictionStates[Enum.AddOnRestrictionType.PvPMatch] = 2 -- Active
press(1, 1202)
assert(#played == nativeCount, "PvP restriction blocks even if instance type is none")
restrictionStates[Enum.AddOnRestrictionType.PvPMatch] = 0

chatLockdown = true
press(1, 1203)
assert(#played == nativeCount, "chat lockdown blocks native emote")
FlourishForeverDB.instances.strike.emotes = { ["c:1"] = { cooldown = 0 } }
press(1, 1204)
assert(#sent == customCount, "chat lockdown blocks custom /e")
chatLockdown = false
restrictionStates[Enum.AddOnRestrictionType.Chat] = 2
press(1, 1205)
assert(#sent == customCount, "chat restriction state blocks custom /e")
restrictionStates[Enum.AddOnRestrictionType.Chat] = 0

press(1, 1210)
assert(#sent == customCount + 1, "custom /e resumes after restrictions")
FlourishForeverDB.instances.strike.emotes = { ROAR = { cooldown = 0 } }
press(1, 1211)
assert(#played == nativeCount + 1, "native emote resumes outside restrictions")
assert(FlourishForeverDB.instances.strike.enabled, "temporary restriction preserves settings")

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

print("PASS: hardware-only native/custom emotes, cooldowns, migration, PvP/chat restrictions")
