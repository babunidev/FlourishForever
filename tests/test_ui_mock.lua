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
ui.search:SetText("roar")
local tokenRows = {}
for _, row in ipairs(ui.emoteRows) do
    if row.check and row.check.token then
        tokenRows[row.check.token] = row
    end
end
assert(tokenRows.ROAR and tokenRows.ROAR:IsShown(),
    "ROAR token found even though displayed command is /rawr")
assert(tokenRows.CHEER and not tokenRows.CHEER:IsShown(),
    "search hides unrelated /hurrah command")
ui.search:SetText("hurrah")
assert(tokenRows.CHEER:IsShown() and not tokenRows.ROAR:IsShown(),
    "search still matches localized command label")
ui.search:SetText("")
assert(tokenRows.ROAR:IsShown() and tokenRows.CHEER:IsShown(),
    "clearing search restores choices")
ui:ShowPage("custom")
assert(ui.customEdit and ui.customSave, "custom emote editor")
ui.customEdit:SetText("shakes her head")
ui:SaveCustomEmotes()
assert(#FlourishForeverDB.customEmotes==1,"custom save")
ui:ShowPage("home")
assert(ui.homeRows[1]:IsShown(),"home restored")
print("PASS: UI trigger selector, ROAR/token and localized alias search, picker, custom text")
