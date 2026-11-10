-- Offline UI smoke test only; the synthetic frames cannot establish game compatibility.
UISpecialFrames = {}
UIParent = {}
local created = {}
local M = {}
local methods = {}
function methods:SetScript(k, v) self.scripts[k] = v end
function methods:RegisterEvent(k) self.events[k] = true end
function methods:GetName() return self.name end
function methods:IsShown() return self.visible end
function methods:Show()
    self.visible = true
    if self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide() self.visible = false end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:SetText(x)
    self.text = x
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
end
function methods:GetText() return rawget(self,"text") or "" end
function methods:SetChecked(x) self.checked = x end
function methods:GetChecked() return rawget(self,"checked") end
function methods:SetValue(x)
    self.value = x
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,x) end
end
function methods:GetValue() return rawget(self,"value") or 0 end
function methods:SetSize(w,h) self.width=w; self.height=h end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:GetWidth() return rawget(self,"width") or 760 end
function methods:GetHeight() return rawget(self,"height") or 600 end
function methods:GetVerticalScroll() return 0 end
function methods:GetVerticalScrollRange() return 0 end
function methods:SetHighlightTexture()
    self.highlight = rawget(self,"highlight") or setmetatable({ scripts={},events={} }, M)
end
function methods:GetHighlightTexture() return rawget(self,"highlight") end
function methods:CreateTexture()
    return setmetatable({ scripts={},events={} },M)
end
function methods:CreateFontString()
    return setmetatable({ scripts={},events={} },M)
end
function methods:CreateMaskTexture()
    return setmetatable({ scripts={},events={} },M)
end
M.__index = function(self,key)
    if methods[key] then return methods[key] end
    if string.match(key, "^[A-Z]") then return function() end end -- graphical method no-op
    return nil
end
CreateFrame = function(_,name,parent,template)
    local frame=setmetatable({name=name,parent=parent,template=template,scripts={},events={},visible=false},M)
    if name then
        _G[name]=frame
        if template == "OptionsSliderTemplate" then
            for _,suffix in ipairs({"Low","High","Text"}) do
                _G[name..suffix]=setmetatable({scripts={},events={}},M)
            end
        end
    end
    frame.TitleText=setmetatable({scripts={},events={}},M)
    created[#created+1]=frame
    return frame
end
GameTooltip=setmetatable({scripts={},events={}},M)
GetTime=function()return 1 end
DoEmote=function() end
C_Spell={GetSpellName=function(id)return ({[100]="Strike",[200]="Second"})[id] end,IsSpellPassive=function()return false end,GetSpellTexture=function()return "Icon" end}
Enum={SpellBookSpellBank={Player=0}, SpellBookItemType={Spell=1}}
local entries={{itemType=1,spellID=100,name="Strike",iconID=111},{itemType=1,spellID=200,name="Second",iconID=222}}
C_SpellBook={GetNumSpellBookSkillLines=function()return 1 end,GetSpellBookSkillLineInfo=function()return {name="General",itemIndexOffset=0,numSpellBookItems=2} end,GetSpellBookItemInfo=function(i)return entries[i] end}
FlourishForeverDB={actionEmotesEnabled=true,instances={strike={name="Strike",spellID=100,chance=100,cooldown=6,emotes={ROAR=true}},second={name="Second",spellID=200,chance=100,cooldown=6,emotes={ROAR=true}}}}
_G.EMOTE1_TOKEN="ROAR"
_G.EMOTE2_TOKEN="CHEER"
GetEmoteSlashCmd=function(token)
    if token == "ROAR" then return "/rawr" end
    if token == "CHEER" then return "/hurrah" end
end
assert(loadfile("FlourishForever_ActionEmotes.lua"))()
local ok, err = xpcall(FlourishForever_OpenConfig, debug.traceback); if not ok then print("TRACE:",err); os.exit(1) end
local ui=_G.FlourishForeverConfigFrame
assert(ui and ui:IsShown() and ui.page=="home", "opens home")
assert(ui.homeRows[1] and ui.homeRows[2],"renders saved abilities")
ui.homeSearch:SetText("str")
assert(ui.homeRows[1]:IsShown() and not ui.homeRows[2]:IsShown(),"searches configured abilities")
ui.homeSearch:SetText("")
ui:ShowPage("picker")
assert(ui.pickerColumns or ui.generalButtons, "picker constructed")
ui.pickerSearch:SetText("str")
assert(ui.generalButtons[1] and ui.generalButtons[1]:IsShown(),"searches spellbook")
assert(not ui.generalButtons[2]:IsShown(),"filters unrelated spell")
-- Clicking filtered entry should bring up emote editor without crashing.
ui.generalButtons[1].scripts.OnClick(ui.generalButtons[1])
assert(ui.page=="editor" and ui.editorTitle:GetText()=="Strike", "editor for chosen spell")
assert(ui.triggerButton and ui.triggerButton:GetText():find("Success", 1, true),
    "new and migrated abilities default to Success")
assert(ui.triggerLabel:GetText() == "Triggered by", "trigger control labeled")
ui.triggerButton.scripts.OnClick(ui.triggerButton)
assert(ui.triggerMenu:IsShown(), "trigger dropdown opens")
ui.triggerOptions.failure.scripts.OnClick(ui.triggerOptions.failure)
assert(FlourishForeverDB.instances.strike.trigger == "failure", "menu persists Failure per ability")
assert(not ui.triggerMenu:IsShown(), "menu closes after selection")
ui:ShowPage("home")
ui:ShowPage("editor")
assert(ui.triggerButton:GetText():find("Failure", 1, true), "dropdown remembers selected mode")
ui.triggerOptions.press.scripts.OnClick(ui.triggerOptions.press)
assert(FlourishForeverDB.instances.strike.trigger == "press", "Button press option persists")
assert(ui.triggerHelp:GetText():find("pause in battlegrounds and arenas", 1, true)
    and not ui.triggerHelp:GetText():find("PvP Success uses Button press", 1, true),
    "editor help describes the PvP pause, not the removed fallback")
assert(not ui.customOnlyWarning:IsShown(), "no custom-only warning for native ROAR")
ui.search:SetText("roar")
local tokenRows = {}
for _, row in ipairs(ui.emoteRows) do
    if row.check and row.check.token then
        tokenRows[row.check.token] = row
    end
end
assert(tokenRows.ROAR and tokenRows.ROAR:IsShown(),
    "ROAR token found even though displayed command is /rawr")
local slider = tokenRows.ROAR.slider
assert(slider:IsShown(), "selected emote exposes its cooldown slider")
slider:SetValue(47)
assert(FlourishForeverDB.instances.strike.emotes.ROAR.cooldown == 47,
    "emote slider writes its own SavedVariables value")
ui:ShowPage("home")
ui:ShowPage("editor")
local reopenedRoar
for _, row in ipairs(ui.emoteRows) do
    if row.check and row.check.token == "ROAR" then reopenedRoar = row end
end
assert(FlourishForeverDB.instances.strike.emotes.ROAR.cooldown == 47
    and reopenedRoar and reopenedRoar.slider:GetValue() == 47,
    "edited ROAR cooldown survives reopening without assuming row order")
ui.search:SetText("roar") -- reopening the editor intentionally resets the search
assert(tokenRows.CHEER and not tokenRows.CHEER:IsShown(),
    "search hides unrelated /hurrah command")
ui.search:SetText("hurrah")
assert(tokenRows.CHEER:IsShown() and not tokenRows.ROAR:IsShown(),
    "search still matches localized command label")
ui.search:SetText("")
assert(tokenRows.ROAR:IsShown() and tokenRows.CHEER:IsShown(),
    "clearing search restores choices")

-- Newly selected emotes start at the ability's own base cooldown.
local baseCooldowns = { [100] = 12000, [200] = 0, [300] = 300000 }
GetSpellBaseCooldown = function(id) return baseCooldowns[id], 1500 end
tokenRows.CHEER.check:SetChecked(true)
tokenRows.CHEER.check.scripts.OnClick(tokenRows.CHEER.check)
assert(FlourishForeverDB.instances.strike.emotes.CHEER.cooldown == 12
    and tokenRows.CHEER.slider:GetValue() == 12,
    "new emote defaults to Strike's 12s cooldown")
assert(FlourishForeverDB.instances.strike.emotes.ROAR.cooldown == 47,
    "existing emote durations are not changed")
tokenRows.CHEER.check:SetChecked(false)
tokenRows.CHEER.check.scripts.OnClick(tokenRows.CHEER.check)
FlourishForeverDB.instances.second = nil
ui:ShowPage("picker")
ui.generalButtons[2].scripts.OnClick(ui.generalButtons[2])
assert(FlourishForeverDB.instances.second.emotes.ROAR.cooldown == 6,
    "ability without a cooldown falls back to 6s")
local function NewAbilityCooldown(spellID)
    FlourishForeverDB.instances.second = nil
    entries[2].spellID = spellID
    ui:ShowPage("picker")
    ui.generalButtons[2].scripts.OnClick(ui.generalButtons[2])
    return FlourishForeverDB.instances.second.emotes.ROAR.cooldown
end
assert(NewAbilityCooldown(300) == 120, "long ability cooldowns clamp to the 120s slider")
entries[2].spellID = 200
GetSpellBaseCooldown = nil
assert(NewAbilityCooldown(200) == 6, "missing cooldown API falls back to 6s")
ui:ShowPage("picker")
ui.generalButtons[1].scripts.OnClick(ui.generalButtons[1]) -- back to Strike
ui:ShowPage("custom")
assert(ui.customEdit and ui.customSave, "custom emote editor")
ui.customEdit:SetText("shakes her head")
ui:SaveCustomEmotes()
assert(#FlourishForeverDB.customEmotes==1,"custom save")

-- A custom-only pool cannot play from Success/Failure; the editor says so.
local strike = FlourishForeverDB.instances.strike
strike.emotes = { ["c:" .. FlourishForeverDB.customEmotes[1].id] = { cooldown = 6 } }
strike.trigger = "success"
ui:ShowPage("editor")
assert(ui.customOnlyWarning:IsShown(), "warn when Success has only custom /e emotes")
ui.triggerOptions.press.scripts.OnClick(ui.triggerOptions.press)
assert(not ui.customOnlyWarning:IsShown(), "warning clears for Button press")
ui.triggerOptions.failure.scripts.OnClick(ui.triggerOptions.failure)
assert(ui.customOnlyWarning:IsShown(), "warning returns for Failure")
local roarRow
for _, row in ipairs(ui.emoteRows) do
    if row.check and row.check.token == "ROAR" then roarRow = row end
end
roarRow.check:SetChecked(true)
roarRow.check.scripts.OnClick(roarRow.check)
assert(not ui.customOnlyWarning:IsShown(), "adding a native emote clears the warning")

-- Opening the editor repeatedly scans the emote globals once per window open.
local scans = 0
local realPairs = pairs
pairs = function(t, ...)
    if t == _G then scans = scans + 1 end
    return realPairs(t, ...)
end
ui:ShowPage("home")
ui:ShowPage("editor")
ui:ShowPage("home")
ui:ShowPage("editor")
assert(scans == 0, "emote list reused within one window open")
ui:Hide()
ui:Show()
ui:ShowPage("editor")
assert(scans == 1, "emote list rescanned after reopening the window")
pairs = realPairs
ui:ShowPage("custom")
ui:ShowPage("home")
assert(ui.homeRows[1]:IsShown(),"home restored")
print("PASS: UI trigger selection, PvP help, custom-only warning, search, per-emote cooldown slider persistence, picker and custom text")
