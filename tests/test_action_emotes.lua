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
DoEmote = function(token) played[#played + 1] = token end
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
Enum = { SpellBookSpellBank = { Player = 0 }, SpellBookItemType = { Spell = 1, FutureSpell = 2, Flyout = 3, PetAction = 4 } }
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
assert(frame.events.UNIT_SPELLCAST_SUCCEEDED and frame.events.SPELLS_CHANGED)
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

-- First emote is never throttled by a fake zero timestamp, even at t=1.
cast(100,1)
assert(#played==1 and played[1]=="ROAR","first emote at one second")
assert(type(FlourishForeverDB.instances.strike.emotes.ROAR)=="table","boolean emote migration")
assert(FlourishForeverDB.instances.strike.emotes.ROAR.cooldown==120,"legacy 120s migrated")
local savedEmoteTable = FlourishForeverDB.instances.strike.emotes
local savedEntry = savedEmoteTable.ROAR
cast(100,2)
assert(FlourishForeverDB.instances.strike.emotes == savedEmoteTable and
       savedEmoteTable.ROAR == savedEntry,
       "routine casts must not reconstruct emote settings")
assert(#played==1,"per-emote cooldown")
cast(200,2)
assert(#played==2 and played[2]=="CHEER","independent ability")
cast(100,120)
assert(#played==2,"cooldown not expired")
cast(100,121)
assert(#played==3,"cooldown expired")
cast(100,122,"target")
assert(#played==3,"foreign unit ignored")

-- Invalid config is safe and malformed records aren't silently deleted.
FlourishForeverDB.instances[5] = { emotes = {} }
FlourishForeverDB.instances.corrupt = "invalid"
FlourishForeverDB.actionEmotesEnabled="not-a-boolean"
FlourishForeverDB.instances.strike.chance=0/0
FlourishForeverDB.instances.strike.emotes.ROAR.cooldown=math.huge
cast(100,500)
assert(FlourishForeverDB.actionEmotesEnabled==false,"malformed master switch disabled")
assert(FlourishForeverDB.instances.strike.chance==100,"NaN chance default")
assert(FlourishForeverDB.instances.strike.emotes.ROAR.cooldown==120,"infinite cooldown clamp")
assert(FlourishForeverDB.instances.corrupt=="invalid" and FlourishForeverDB.instances[5],"bad records preserved")
assert(select(2,FlourishForever_ActionStatus())==2,"status excludes malformed keys")

-- A genuine action-button hook sends custom text from its press, not a delayed cast.
FlourishForeverDB.actionEmotesEnabled=true
FlourishForeverDB.customEmotes={{id="1",text="shakes her head"}}
FlourishForeverDB.customEmoteSeq=1
FlourishForeverDB.instances.strike.emotes={ ["c:1"]={cooldown=30} }
FlourishForeverDB.instances.strike.chance=100
assert(type(hooks.UseAction)=="function","press hook registered")
now=1000
hooks.UseAction(1)
assert(#sent==1 and sent[1]=="shakes her head","custom /e on press")
cast(100,1000.1)
assert(#played==3,"custom must not trigger DoEmote after cast")
now=1001
hooks.UseAction(1)
assert(#sent==1,"custom per-token cooldown")
now=1031
hooks.UseAction(1)
assert(#sent==2,"custom cooldown expiry")

-- After a press hook selects a standard emote it plays on confirmed cast success.
FlourishForeverDB.instances.strike.emotes={ ROAR={cooldown=0} }
now=1100
hooks.UseAction(1)
assert(#played==3,"native emote waits for succeeded event")
cast(100,1100.1)
assert(#played==4 and played[4]=="ROAR","native press->success")
cast(100,1100.2)
assert(#played==4,"duplicate success event suppressed")
-- Chance zero stays silent without consuming the cooldown.
FlourishForeverDB.instances.strike.emotes = { ROAR = {cooldown=0} }
FlourishForeverDB.instances.strike.chance = 0
cast(100,1200)
assert(#played==4,"chance zero remains silent")
FlourishForeverDB.instances.strike.chance = 100
cast(100,1200)
assert(#played==5,"chance failure does not consume cooldown")

-- Empty emote pool is intentionally silent; corrupted pool restores ROAR.
FlourishForeverDB.instances.strike.emotes = {}
cast(100,1300)
assert(#played==5,"intentional empty pool")
FlourishForeverDB.instances.strike.emotes = "malformed"
cast(100,1400)
assert(#played==6 and played[6]=="ROAR","malformed pool recovers")

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

print("PASS: merged storage migration, spellbook filtering, first-cast, per-emote cooldowns, native/custom triggers")
