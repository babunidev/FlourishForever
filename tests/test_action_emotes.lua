-- Offline regression tests. Run from the repository root with Lua 5.4.
-- WoW APIs are mocked; these assertions are NOT in-game verification.
local frames = {}
CreateFrame = function()
    local frame = { scripts = {}, events = {} }
    function frame:SetScript(name, fn) self.scripts[name] = fn end
    function frame:RegisterEvent(name) self.events[name] = true end
    frames[#frames + 1] = frame
    return frame
end

local now = 1
GetTime = function() return now end
local played = {}
DoEmote = function(token) played[#played + 1] = token end

local spellNames = {
    [100] = "Strike", [101] = "Passive", [102] = "Future", [103] = "Flyout",
    [104] = "Other", [105] = "Passive API", [106] = "Extra", [200] = "Second",
}
C_Spell = {
    GetSpellName = function(id) return spellNames[id] end,
    IsSpellPassive = function(id) return id == 105 end,
}
Enum = {
    SpellBookSpellBank = { Player = 0 },
    SpellBookItemType = { Spell = 1, FutureSpell = 2, PetAction = 3, Flyout = 4 },
}
local modernItems = {
    { itemType = 1, spellID = 100, name = "Strike" },
    { itemType = 1, spellID = 100, name = "Strike" }, -- duplicate
    { itemType = 1, spellID = 101, name = "Passive", isPassive = true },
    { itemType = 2, actionID = 102, name = "Future" },
    { itemType = 4, actionID = 103, name = "Flyout" },
    { itemType = 1, spellID = 104, name = "Other", isOffSpec = true },
    { itemType = 1, spellID = 105, name = "Passive API" },
    { itemType = 1, spellID = 106, name = "Extra" },
    { itemType = 3, actionID = 201, name = "Pet Action" },
}
C_SpellBook = {
    GetNumSpellBookSkillLines = function() return 1 end,
    GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = #modernItems } end,
    GetSpellBookItemInfo = function(index) return modernItems[index] end,
}
FlourishForeverDB = {
    actionEmotesEnabled = true,
    instances = {
        strike = { name = "Strike", spellID = 100, chance = 100, cooldown = 6, emotes = { ROAR = true } },
        second = { name = "Second", spellID = 200, chance = 100, cooldown = 6, emotes = { CHEER = true } },
    },
}
assert(loadfile("FlourishForever_ActionEmotes.lua"))()

local frame = frames[1]
assert(frame.events.UNIT_SPELLCAST_SUCCEEDED and frame.events.SPELLS_CHANGED)
local onEvent = frame.scripts.OnEvent

local function findUpvalue(fn, wanted)
    for i = 1, 100 do
        local name, value = debug.getupvalue(fn, i)
        if name == wanted then return value end
        if not name then break end
    end
    error("missing upvalue: " .. wanted)
end

-- Modern spellbook: no passives, future spells, flyouts, off-spec, pet actions or duplicates.
local refreshAbilities = findUpvalue(onEvent, "RefreshKnownAbilities")
refreshAbilities()
local known = findUpvalue(refreshAbilities, "knownAbilities")
assert(#known == 2 and known[1].spellID == 106 and known[2].spellID == 100 or
       #known == 2 and known[1].spellID == 100 and known[2].spellID == 106,
       "modern learned-spell filtering")

-- Legacy path: only genuine SPELL entries, not FUTURESPELL or FLYOUT.
C_SpellBook = nil
GetNumSpellTabs = function() return 1 end
GetSpellTabInfo = function() return nil, nil, 0, 3 end
GetSpellBookItemInfo = function(i)
    local kind = { "SPELL", "FUTURESPELL", "FLYOUT" }
    local id = { 100, 102, 103 }
    return kind[i], id[i]
end
GetSpellBookItemName = function(i)
    local names = { "Strike", "Future", "Flyout" }
    return names[i]
end
refreshAbilities()
known = findUpvalue(refreshAbilities, "knownAbilities")
assert(#known == 1 and known[1].spellID == 100, "legacy learned-spell filtering")

local function cast(id, time, unit)
    now = time
    onEvent(frame, "UNIT_SPELLCAST_SUCCEEDED", unit or "player", "cast-guid", id)
end
cast(100, 1)
assert(#played == 1 and played[1] == "ROAR", "first cast must not be suppressed")
cast(100, 2)
assert(#played == 1, "ability cooldown")
cast(200, 2)
assert(#played == 2 and played[2] == "CHEER", "independent ability cooldown")
cast(100, 7)
assert(#played == 3, "cooldown expires")
cast(100, 8, "target")
assert(#played == 3, "other units ignored")

-- Zero chance never fires and must not consume the emote cooldown.
FlourishForeverDB.instances.strike.chance = 0
cast(100, 100)
assert(#played == 3, "zero chance")
FlourishForeverDB.instances.strike.chance = 100
cast(100, 100)
assert(#played == 4, "failed chance does not consume cooldown")

-- An empty pool does not fire, an invalid token key cannot cause DoEmote to error.
FlourishForeverDB.instances.second.emotes = {}
cast(200, 100)
assert(#played == 4, "empty emote pool")
FlourishForeverDB.instances.second.emotes = { [25] = true, CHEER = true }
cast(200, 100)
assert(#played == 5 and played[5] == "CHEER", "nonstring tokens ignored")

-- Malformed saves are bounded; invalid switch values become disabled.
FlourishForeverDB.instances.strike.chance = 999
FlourishForeverDB.instances.strike.cooldown = -10
FlourishForeverDB.instances.second.chance = "not a number"
FlourishForeverDB.instances.second.cooldown = 0 / 0
FlourishForeverDB.instances.second.emotes = "corrupt"
FlourishForeverDB.instances.unusable = "keep for recovery"
FlourishForeverDB.instances[8] = { emotes = {} }
FlourishForeverDB.actionEmotesEnabled = "false"
cast(100, 101)
assert(FlourishForeverDB.actionEmotesEnabled == false, "invalid master switch safely disabled")
assert(#played == 5, "malformed master switch must not trigger")
assert(FlourishForeverDB.instances.strike.chance == 100, "chance upper clamp")
assert(FlourishForeverDB.instances.strike.cooldown == 0, "cooldown lower clamp")
assert(FlourishForeverDB.instances.second.chance == 100, "invalid chance default")
assert(FlourishForeverDB.instances.second.cooldown == 6, "invalid cooldown default")
assert(FlourishForeverDB.instances.second.emotes.ROAR, "invalid pool defaults")
assert(FlourishForeverDB.instances.unusable == "keep for recovery", "unusable records preserved")
assert(type(FlourishForeverDB.instances[8]) == "table", "unsupported keys preserved")

FlourishForeverDB.actionEmotesEnabled = true
FlourishForeverDB.instances.strike.chance = -5
FlourishForeverDB.instances.strike.cooldown = math.huge
cast(100, 200)
assert(FlourishForeverDB.instances.strike.chance == 0, "chance lower clamp")
assert(FlourishForeverDB.instances.strike.cooldown == 120, "cooldown infinity clamp")
assert(#played == 5, "zero chance remains silent")
assert(FlourishForever_ActionStatus(), "status callable")

-- Storage: legacy profile adoption by GUID when existing SavedVariables are loaded.
local oldProfile = { actionEmotesEnabled = false, instances = {} }
ROARitFOREVERStorage = nil
FlourishForeverStorage = { profiles = { Tester = oldProfile } }
UnitGUID = function(unit) assert(unit == "player"); return "Player-TEST" end
UnitName = function() return "Tester" end
GetRealmName = function() return "" end
assert(loadfile("FlourishForever_Storage.lua"))()
local migrated, guid = FlourishForever_BindCharacterDB()
assert(guid == "Player-TEST" and migrated == oldProfile, "legacy profile migration")
assert(FlourishForeverStorage.profiles.Tester == nil, "legacy key removed after binding")
assert(FlourishForeverStorage.profiles["Player-TEST"] == oldProfile, "GUID key assigned")
print("PASS: spellbook filtering, cast cooldown/chance, saved settings, and migration mocks")
