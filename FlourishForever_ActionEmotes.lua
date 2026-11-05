local eventFrame = CreateFrame("Frame")

local DEFAULT_CHANCE = 100
local DEFAULT_COOLDOWN = 6
local WINDOW_W, WINDOW_H = 810, 676
local PAGE_W, PAGE_H = 786, 632
local HOME_ROW_H = 56
local HOME_ROW_W = 748
local ABILITY_ICON = 48

local lastFireByAbility = {}

local db
local ui
local selectedKey
local knownEmotes = {}

local function Trim(s)
    return (s or ""):match("^%s*(.-)%s*$")
end

local function AbilityKey(name)
    return string.lower(Trim(name))
end

-- Normalize potentially corrupted older saves without arithmetic on nil or NaN.
local function BoundedWholeNumber(value, default, low, high)
    local number = tonumber(value)
    if not number or number ~= number then
        return default
    end
    number = math.max(low, math.min(high, number))
    return math.floor(number + 0.5)
end

local function NormalizeEmotes(cfg)
    -- Older versions used a single per-ability cooldown and boolean emotes.
    -- Newer settings store a separate cooldown per selected token. Preserve
    -- an intentional empty pool, but recover a corrupted missing pool as ROAR.
    local legacy = BoundedWholeNumber(cfg.cooldown, DEFAULT_COOLDOWN, 0, 120)
    cfg.cooldown = legacy -- preserve legacy value for future safe migration
    -- Normalize in place: EnsureDB also runs on spell casts, and rebuilding
    -- every emote table each time would allocate on the gameplay hot path.
    if type(cfg.emotes) ~= "table" then
        cfg.emotes = { ROAR = { cooldown = legacy } }
        return
    end
    for token, value in pairs(cfg.emotes) do
        if type(token) ~= "string" or token == "" then
            cfg.emotes[token] = nil
        elseif value == true then
            cfg.emotes[token] = { cooldown = legacy }
        elseif type(value) == "number" then
            cfg.emotes[token] = { cooldown = BoundedWholeNumber(value, legacy, 0, 120) }
        elseif type(value) == "table" then
            value.cooldown = BoundedWholeNumber(value.cooldown, legacy, 0, 120)
        else
            cfg.emotes[token] = nil
        end
    end
end

local function EnsureDB()
    if FlourishForever_BindCharacterDB then
        FlourishForever_BindCharacterDB()
    end
    if type(FlourishForeverDB) ~= "table" then
        FlourishForeverDB = {}
    end

    if FlourishForeverDB.actionEmotesEnabled == nil then
        FlourishForeverDB.actionEmotesEnabled = true
    elseif type(FlourishForeverDB.actionEmotesEnabled) ~= "boolean" then
        FlourishForeverDB.actionEmotesEnabled = false
    end

    if type(FlourishForeverDB.instances) ~= "table" then
        FlourishForeverDB.instances = {}
    end

    for key, cfg in pairs(FlourishForeverDB.instances) do
        if type(key) == "string" and key ~= "" and type(cfg) == "table" then
            if type(cfg.name) ~= "string" or cfg.name == "" then
                cfg.name = key
            end
            cfg.chance = BoundedWholeNumber(cfg.chance, DEFAULT_CHANCE, 0, 100)
            if cfg.enabled == nil then
                cfg.enabled = true
            elseif type(cfg.enabled) ~= "boolean" then
                cfg.enabled = false
            end
            NormalizeEmotes(cfg)
        end
        -- Malformed records are preserved for manual recovery but never run.
    end

    if type(FlourishForeverDB.customEmotes) ~= "table" then
        FlourishForeverDB.customEmotes = {}
    end

    local custom = {}
    local seenCustom = {}
    for _, entry in ipairs(FlourishForeverDB.customEmotes) do
        if type(entry) == "table" and type(entry.text) == "string" then
            local text = Trim(entry.text)
            local id = tostring(entry.id or "")
            if text ~= "" and id ~= "" and not seenCustom[id] then
                seenCustom[id] = true
                custom[#custom + 1] = { id = id, text = text }
            end
        end
    end
    FlourishForeverDB.customEmotes = custom

    local validCustom = {}
    for _, entry in ipairs(custom) do
        validCustom["c:" .. entry.id] = true
    end
    for _, cfg in pairs(FlourishForeverDB.instances) do
        if type(cfg) == "table" and type(cfg.emotes) == "table" then
            for token in pairs(cfg.emotes) do
                if type(token) == "string" and string.sub(token, 1, 2) == "c:" and not validCustom[token] then
                    cfg.emotes[token] = nil
                end
            end
        end
    end

    db = FlourishForeverDB
    return db
end

local function GetSpellNameByID(spellID)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellID)
    end

    if GetSpellInfo then
        return GetSpellInfo(spellID)
    end

    return nil
end

local function SpellIcon(spellID)
    if not spellID then
        return nil
    end

    if C_Spell and C_Spell.GetSpellTexture then
        local icon = C_Spell.GetSpellTexture(spellID)
        if icon then
            return icon
        end
    end

    if GetSpellTexture then
        local icon = GetSpellTexture(spellID)
        if icon then
            return icon
        end
    end

    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if type(info) == "table" then
            return info.iconID or info.originalIconID
        end
    end
end

local function IsPassive(spellID)
    if C_Spell and C_Spell.IsSpellPassive then
        return C_Spell.IsSpellPassive(spellID)
    end

    if IsPassiveSpell then
        return IsPassiveSpell(spellID)
    end

    return false
end

local function IsGeneralTab(name)
    if type(name) ~= "string" then
        return false
    end

    local lower = string.lower(name)
    return lower == "general" or lower == "allgemein" or lower == "général" or lower == "generale" or lower == "общие"
end

local function AddColumnAbility(column, seenNames, name, spellID, icon)
    if type(name) ~= "string" or name == "" or
        type(spellID) ~= "number" or spellID <= 0 or
        spellID ~= math.floor(spellID) or IsPassive(spellID) then
        return
    end

    local key = AbilityKey(name)
    if key == "" or seenNames[key] then
        return
    end

    seenNames[key] = true
    column.abilities[#column.abilities + 1] = {
        name = name,
        spellID = spellID,
        icon = icon or SpellIcon(spellID),
    }
end

local function SelectSpecColumns(columns)
    local general = {}
    local specs = {}
    local others = {}

    for _, column in ipairs(columns) do
        if #column.abilities > 0 then
            if IsGeneralTab(column.name) then
                general[#general + 1] = column
            elseif column.specID and column.specID > 0 then
                specs[#specs + 1] = column
            else
                others[#others + 1] = column
            end
        end
    end

    local selected = {}
    for _, column in ipairs(general) do
        selected[#selected + 1] = column
    end
    for _, column in ipairs(specs) do
        selected[#selected + 1] = column
    end
    for _, column in ipairs(others) do
        selected[#selected + 1] = column
    end

    if #selected == 0 then
        return columns
    end

    return selected
end

local function CollectSpellColumns()
    local columns = {}

    local function NewColumn(name, icon, specID)
        local column = {
            name = name or "Abilities",
            icon = icon,
            specID = specID,
            abilities = {},
        }
        columns[#columns + 1] = column
        return column
    end

    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookSkillLineInfo and C_SpellBook.GetSpellBookItemInfo then
        local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
        local spellItemType = (Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell) or 1
        local numTabs = C_SpellBook.GetNumSpellBookSkillLines() or 0

        for tab = 1, numTabs do
            local tabInfo = C_SpellBook.GetSpellBookSkillLineInfo(tab)
            if tabInfo and not tabInfo.shouldHide and not tabInfo.isGuild then
                local column = NewColumn(tabInfo.name, tabInfo.iconID, tabInfo.specID)
                local seenNames = {}
                local offset = tabInfo.itemIndexOffset or 0
                local count = tabInfo.numSpellBookItems or 0
                for index = offset + 1, offset + count do
                    local info = C_SpellBook.GetSpellBookItemInfo(index, bank)
                    -- Exclude hidden, passive, future, flyout, off-spec and pet actions.
                    if info and info.itemType == spellItemType
                        and not info.isPassive and not info.isOffSpec then
                        local spellID = info.spellID or info.actionID
                        local name = info.name or GetSpellNameByID(spellID)
                        AddColumnAbility(column, seenNames, name, spellID, info.iconID)
                    end
                end
            end
        end
    elseif GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemInfo then
        local bookType = BOOKTYPE_SPELL or "spell"
        local numTabs = GetNumSpellTabs() or 0

        for tab = 1, numTabs do
            local name, texture, offset, count, isGuild = GetSpellTabInfo(tab)
            if not isGuild then
            local column = NewColumn(name, texture, nil)
            local seenNames = {}
            offset = offset or 0
            count = count or 0

            for index = offset + 1, offset + count do
                local skillType, spellID = GetSpellBookItemInfo(index, bookType)
                if skillType == "SPELL" and spellID then
                    local spellName
                    if GetSpellBookItemName then
                        spellName = GetSpellBookItemName(index, bookType)
                    end
                    spellName = spellName or GetSpellNameByID(spellID)

                    local icon
                    if GetSpellBookItemTexture then
                        icon = GetSpellBookItemTexture(index, bookType)
                    end
                    AddColumnAbility(column, seenNames, spellName, spellID, icon)
                end
            end
            end
        end
    end

    return SelectSpecColumns(columns)
end

local function RefreshKnownEmotes()
    local list = {}
    local seen = {}

    for globalName, token in pairs(_G) do
        if type(globalName) == "string" and type(token) == "string" and string.match(globalName, "^EMOTE%d+_TOKEN$") then
            token = string.upper(token)
            if token ~= "" and not seen[token] then
                seen[token] = true
                list[#list + 1] = token
            end
        end
    end

    if not seen.ROAR then
        list[#list + 1] = "ROAR"
    end

    table.sort(list)
    knownEmotes = list
end

local function CustomEmoteById(id)
    -- Callers have already bound the profile; never re-normalize all records
    -- during a hot-path emote iteration or tooltip construction.
    for _, entry in ipairs((db and db.customEmotes) or {}) do
        if entry.id == id then
            return entry
        end
    end
end

local function EmoteLabel(token)
    if type(token) == "string" and string.sub(token, 1, 2) == "c:" then
        local entry = CustomEmoteById(string.sub(token, 3))
        if entry then
            return "/e " .. entry.text
        end
        return "/e"
    end

    if GetEmoteSlashCmd then
        local ok, command = pcall(GetEmoteSlashCmd, token)
        if ok and type(command) == "string" and command ~= "" then
            return command
        end
    end

    return "/" .. string.lower(token)
end

local function SortedEnabledEmotes(cfg)
    local list = {}

    for token, info in pairs(cfg.emotes or {}) do
        if type(info) == "table" then
            list[#list + 1] = {
                token = token,
                label = EmoteLabel(token),
                cooldown = tonumber(info.cooldown) or DEFAULT_COOLDOWN,
            }
        end
    end

    table.sort(list, function(a, b)
        if a.label == b.label then
            return a.token < b.token
        end
        return a.label < b.label
    end)

    return list
end

local function EmoteSummary(entries)
    if #entries == 0 then
        return "No emotes"
    end

    local shown = math.min(3, #entries)
    local parts = {}
    for i = 1, shown do
        parts[i] = entries[i].label
    end

    local text = table.concat(parts, ", ")
    local extra = #entries - shown
    if extra > 0 then
        text = text .. " +" .. extra
    end

    return text
end

local function SortedInstanceKeys()
    EnsureDB()
    local keys = {}

    for key, cfg in pairs(db.instances) do
        if type(key) == "string" and key ~= "" and type(cfg) == "table" then
            keys[#keys + 1] = key
        end
    end

    table.sort(keys, function(a, b)
        return (db.instances[a].name or a) < (db.instances[b].name or b)
    end)

    return keys
end

local function ReadyEmotes(cfg, now, fired)
    local ready = {}

    for token, info in pairs(cfg.emotes or {}) do
        if type(token) == "string" and token ~= "" and type(info) == "table" then
            local cooldown = BoundedWholeNumber(info.cooldown, DEFAULT_COOLDOWN, 0, 120)
            local last = fired[token]
            -- A token has no cooldown until it has actually fired once.
            if not last or now - last >= cooldown then
                ready[#ready + 1] = token
            end
        end
    end

    return ready
end

-- Forever allows an addon /e only while the player's button press or slash
-- command is still running. UNIT_SPELLCAST_SUCCEEDED is later, so sending
-- there shows "Interface action failed because of an AddOn". DoEmote is a
-- different call and is still allowed from that event.
local pressStamp = {}
local pendingStandard = {}

local function IsCustomToken(token)
    return type(token) == "string" and string.sub(token, 1, 2) == "c:"
end

local function SpellPressCanFire(spellID)
    if C_Spell and C_Spell.IsSpellUsable then
        local usable = C_Spell.IsSpellUsable(spellID)
        if usable == false then
            return false
        end
    elseif IsUsableSpell then
        local usable = IsUsableSpell(spellID)
        if usable == false then
            return false
        end
    end

    return true
end

local function ResolveAbility(spellID)
    EnsureDB()

    if not db.actionEmotesEnabled then
        return
    end

    local spellName = GetSpellNameByID(spellID)
    if type(spellName) ~= "string" or spellName == "" then
        return
    end

    local key = AbilityKey(spellName)
    local cfg = db.instances[key]
    if type(cfg) ~= "table" or cfg.enabled == false then
        return
    end

    cfg.spellID = spellID
    cfg.name = spellName

    if type(lastFireByAbility[key]) ~= "table" then
        lastFireByAbility[key] = {}
    end

    return key, cfg
end

local function SendCustomEmote(token)
    local entry = CustomEmoteById(string.sub(token, 3))
    if not entry or entry.text == "" then
        return false
    end

    if C_ChatInfo and C_ChatInfo.SendChatMessage then
        C_ChatInfo.SendChatMessage(entry.text, "EMOTE")
        return true
    end

    if SendChatMessage then
        SendChatMessage(entry.text, "EMOTE")
        return true
    end

    return false
end

local function TryAbilityEmoteFromPress(spellID)
    if type(spellID) ~= "number" or not SpellPressCanFire(spellID) then
        return
    end

    local key, cfg = ResolveAbility(spellID)
    if not key then
        return
    end

    local now = GetTime()
    if pressStamp[key] and (now - pressStamp[key]) < 0.2 then
        return
    end

    pressStamp[key] = now
    pendingStandard[key] = nil

    local ready = ReadyEmotes(cfg, now, lastFireByAbility[key])
    if #ready == 0 then
        return
    end

    local chance = tonumber(cfg.chance) or DEFAULT_CHANCE
    if math.random(1, 100) > chance then
        return
    end

    local token = ready[math.random(1, #ready)]
    if IsCustomToken(token) then
        if SendCustomEmote(token) then
            lastFireByAbility[key][token] = now
        end
        return
    end

    pendingStandard[key] = {
        token = token,
        spellID = spellID,
        expires = now + 2,
    }
end

local function TryAbilityEmote(spellID)
    local key, cfg = ResolveAbility(spellID)
    if not key then
        return
    end

    local now = GetTime()
    if pressStamp[key] and (now - pressStamp[key]) < 2 then
        local pending = pendingStandard[key]
        pendingStandard[key] = nil
        if pending and pending.spellID == spellID and now <= pending.expires then
            lastFireByAbility[key][pending.token] = now
            DoEmote(pending.token)
        end
        return
    end

    local ready = {}
    for _, token in ipairs(ReadyEmotes(cfg, now, lastFireByAbility[key])) do
        if not IsCustomToken(token) then
            ready[#ready + 1] = token
        end
    end

    if #ready == 0 then
        return
    end

    local chance = tonumber(cfg.chance) or DEFAULT_CHANCE
    if math.random(1, 100) > chance then
        return
    end

    local token = ready[math.random(1, #ready)]
    lastFireByAbility[key][token] = now
    DoEmote(token)
end

local function SpellIDFromActionSlot(slot)
    if C_ActionBar and C_ActionBar.GetSpell then
        local spellID = C_ActionBar.GetSpell(slot)
        if type(spellID) == "number" then
            return spellID
        end
    end

    if not GetActionInfo then
        return
    end

    local actionType, id = GetActionInfo(slot)
    if actionType == "spell" and type(id) == "number" then
        return id
    end

    if actionType == "macro" and GetMacroSpell then
        local spellID = GetMacroSpell(id)
        if type(spellID) == "number" then
            return spellID
        end
    end
end

local hardwareLock = false

local function OnAbilityPress(spellID)
    if hardwareLock or type(spellID) ~= "number" then
        return
    end
    hardwareLock = true
    local ok, err = pcall(TryAbilityEmoteFromPress, spellID)
    hardwareLock = false
    if not ok then
        error(err)
    end
end

if hooksecurefunc then
    if UseAction then
        hooksecurefunc("UseAction", function(slot)
            OnAbilityPress(SpellIDFromActionSlot(slot))
        end)
    end

    if CastSpellByID then
        hooksecurefunc("CastSpellByID", function(spellID)
            OnAbilityPress(spellID)
        end)
    end

    if C_Spell and C_Spell.CastSpell then
        hooksecurefunc(C_Spell, "CastSpell", function(spellID)
            OnAbilityPress(spellID)
        end)
    end
end

local function AddOrSelectAbility(ability)
    EnsureDB()

    local key = AbilityKey(ability.name)
    local cfg = db.instances[key]

    if type(cfg) ~= "table" then
        cfg = {
            name = ability.name,
            spellID = ability.spellID,
            chance = DEFAULT_CHANCE,
            enabled = true,
            emotes = { ROAR = { cooldown = DEFAULT_COOLDOWN } },
        }
        db.instances[key] = cfg
    else
        cfg.name = ability.name
        cfg.spellID = ability.spellID
        NormalizeEmotes(cfg)
    end

    selectedKey = key
    return key
end

local function CreateQuietScroll(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local step = 36 * delta
        local nextScroll = self:GetVerticalScroll() - step
        local maxScroll = self:GetVerticalScrollRange() or 0
        if nextScroll < 0 then
            nextScroll = 0
        elseif nextScroll > maxScroll then
            nextScroll = maxScroll
        end
        self:SetVerticalScroll(nextScroll)
    end)
    return scroll
end

local function StretchHighlight(button)
    button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    local highlight = button:GetHighlightTexture()
    if highlight then
        highlight:SetAllPoints(button)
    end
end

local function ApplyIcon(texture, icon)
    texture:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    if texture.ffMasked then
        texture:SetTexCoord(0, 1, 0, 1)
    else
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
end

local function PaintAtlas(texture, atlas)
    if texture.SetAtlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
        texture:SetAtlas(atlas, false)
        return true
    end
    texture:Hide()
    return false
end

local function DressAbilityButton(button)
    if button.icon then
        return
    end

    local scale = ABILITY_ICON / 36
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(ABILITY_ICON, ABILITY_ICON)
    button.icon:SetPoint("LEFT", button, "LEFT", 16, 0)

    button.iconShadow = button:CreateTexture(nil, "BACKGROUND")
    button.iconShadow:SetPoint("TOPLEFT", button.icon, "TOPLEFT", -14 * scale, 5 * scale)
    button.iconShadow:SetPoint("BOTTOMRIGHT", button.icon, "BOTTOMRIGHT", 4 * scale, -10 * scale)
    PaintAtlas(button.iconShadow, "spellbook-item-iconframe-shadow")

    button.iconFrame = button:CreateTexture(nil, "OVERLAY")
    button.iconFrame:SetPoint("TOPLEFT", button.icon, "TOPLEFT", -13 * scale, 3 * scale)
    button.iconFrame:SetPoint("BOTTOMRIGHT", button.icon, "BOTTOMRIGHT", 3 * scale, -9 * scale)
    PaintAtlas(button.iconFrame, "spellbook-item-iconframe")

    if button.CreateMaskTexture and button.icon.AddMaskTexture and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("spellbook-item-spellicon-mask") then
        local mask = button:CreateMaskTexture()
        mask:SetAllPoints(button.icon)
        mask:SetAtlas("spellbook-item-spellicon-mask", false)
        button.icon:AddMaskTexture(mask)
        button.icon.ffMasked = true
    end
end

local function ShowAbilityTooltip(owner, cfg)
    local entries = SortedEnabledEmotes(cfg)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(cfg.name or "Ability", 1, 0.82, 0)
    GameTooltip:AddLine("Chance: " .. (tonumber(cfg.chance) or DEFAULT_CHANCE) .. "%", 1, 1, 1)

    if #entries == 0 then
        GameTooltip:AddLine("No emotes", 0.7, 0.7, 0.7)
    else
        for _, entry in ipairs(entries) do
            GameTooltip:AddLine(entry.label .. ": " .. entry.cooldown .. " sec", 0.9, 0.9, 0.9)
        end
    end

    GameTooltip:Show()
end

local function HideAbilityTooltip()
    GameTooltip:Hide()
end

local function CreateCheckbox(parent)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetPoint("LEFT", parent, "LEFT", 0, 0)
    local text = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", check, "RIGHT", 2, 1)
    text:SetJustifyH("LEFT")
    text:SetWidth(180)
    check.label = text
    return check
end

local function CreateUI()
    if ui then
        return ui
    end

    ui = CreateFrame("Frame", "FlourishForeverConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    ui:SetSize(WINDOW_W, WINDOW_H)
    ui:SetPoint("CENTER")
    ui:SetFrameStrata("DIALOG")
    ui:SetMovable(true)
    ui:EnableMouse(true)
    ui:SetClampedToScreen(true)
    ui:RegisterForDrag("LeftButton")
    ui:SetScript("OnDragStart", function(self) self:StartMoving() end)
    ui:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    ui:Hide()
    table.insert(UISpecialFrames, "FlourishForeverConfigFrame")
    ui.TitleText:SetText("Flourish Forever")
    ui.page = "home"

    local function NewPage()
        local page = CreateFrame("Frame", nil, ui)
        page:SetPoint("TOPLEFT", ui, "TOPLEFT", 12, -32)
        page:SetSize(PAGE_W, PAGE_H)
        page:Hide()
        return page
    end

    ui.home = NewPage()
    ui.picker = NewPage()
    ui.editor = NewPage()
    ui.custom = NewPage()

    ui.enabled = CreateCheckbox(ui.home)
    ui.enabled:ClearAllPoints()
    ui.enabled:SetPoint("TOPLEFT", ui.home, "TOPLEFT", 8, -6)
    ui.enabled.label:SetWidth(210)
    ui.enabled.label:SetText("Enable Flourish Forever")
    ui.enabled:SetScript("OnClick", function(self)
        EnsureDB()
        db.actionEmotesEnabled = self:GetChecked() and true or false
    end)

    ui.addButton = CreateFrame("Button", nil, ui.home)
    ui.addButton:SetSize(180, 72)
    ui.addButton:SetPoint("TOP", ui.home, "TOP", 0, -8)
    ui.addButton.plus = ui.addButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ui.addButton.plus:SetPoint("CENTER", ui.addButton, "CENTER", 0, 12)
    ui.addButton.plus:SetText("+")
    ui.addButton.plus:SetTextColor(1, 0.82, 0)
    ui.addButton.label = ui.addButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ui.addButton.label:SetPoint("TOP", ui.addButton.plus, "BOTTOM", 0, -1)
    ui.addButton.label:SetText("Add ability")
    ui.addButton.label:SetTextColor(1, 1, 1)
    ui.addButton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    ui.addButton:SetScript("OnClick", function()
        ui:ShowPage("picker")
    end)

    ui.customButton = CreateFrame("Button", nil, ui.home, "UIPanelButtonTemplate")
    ui.customButton:SetSize(170, 24)
    ui.customButton:SetPoint("LEFT", ui.addButton, "RIGHT", 18, 0)
    ui.customButton:SetText("Add custom emotes")
    ui.customButton:SetScript("OnClick", function()
        ui:ShowPage("custom")
    end)

    ui.homeEmpty = ui.home:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ui.homeEmpty:SetPoint("CENTER", ui.home, "CENTER", 0, -20)
    ui.homeEmpty:SetText("No abilities yet.")
    ui.homeEmpty:Hide()

    -- Search the configured ability overview independently of the picker.
    ui.homeSearchLabel = ui.home:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.homeSearchLabel:SetPoint("TOPRIGHT", ui.home, "TOPRIGHT", -194, -66)
    ui.homeSearchLabel:SetText("Find ability")
    ui.homeSearch = CreateFrame("EditBox", "FlourishForeverHomeSearch", ui.home, "InputBoxTemplate")
    ui.homeSearch:SetSize(160, 20)
    ui.homeSearch:SetPoint("LEFT", ui.homeSearchLabel, "RIGHT", 10, 0)
    ui.homeSearch:SetAutoFocus(false)
    ui.homeSearch:SetMaxLetters(60)
    ui.homeSearch:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    ui.homeSearch:SetScript("OnTextChanged", function()
        if not ui.updating then ui:RefreshHome() end
    end)

    ui.homeScroll = CreateQuietScroll(ui.home)
    ui.homeScroll:SetPoint("TOPLEFT", ui.home, "TOPLEFT", 8, -88)
    ui.homeScroll:SetPoint("BOTTOMRIGHT", ui.home, "BOTTOMRIGHT", -8, 4)
    ui.homeChild = CreateFrame("Frame", nil, ui.homeScroll)
    ui.homeChild:SetSize(HOME_ROW_W, 1)
    ui.homeScroll:SetScrollChild(ui.homeChild)
    ui.homeRows = {}

    local function PaintBook(page)
        local bg = page:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()

        local atlas = "spellbook-Page-Right-C60"
        local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
        if info and bg.SetAtlas then
            bg:SetAtlas(atlas, false)
            if info.leftTexCoord and info.rightTexCoord and info.topTexCoord and info.bottomTexCoord then
                local span = info.bottomTexCoord - info.topTexCoord
                bg:SetTexCoord(info.leftTexCoord, info.rightTexCoord, info.topTexCoord + span * 0.07, info.bottomTexCoord)
            end
        else
            bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            bg:SetVertexColor(0.78, 0.68, 0.48, 1)
        end

        local divider = page:CreateTexture(nil, "ARTWORK")
        divider:SetPoint("TOP", page, "TOP", 0, -34)
        divider:SetSize(PAGE_W - 140, 12)
        if divider.SetAtlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("spellbook-divider") then
            divider:SetAtlas("spellbook-divider", false)
            divider:SetSize(PAGE_W - 140, 12)
        else
            divider:Hide()
        end
    end

    PaintBook(ui.picker)

    ui.pickerBack = CreateFrame("Button", nil, ui.picker, "UIPanelButtonTemplate")
    ui.pickerBack:SetSize(80, 24)
    ui.pickerBack:SetPoint("TOPLEFT", ui.picker, "TOPLEFT", 8, -8)
    ui.pickerBack:SetText("Back")
    ui.pickerBack:SetScript("OnClick", function()
        ui:ShowPage("home")
    end)

    ui.pickerTitle = ui.picker:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ui.pickerTitle:SetPoint("TOP", ui.picker, "TOP", 0, -10)
    ui.pickerTitle:SetText("Add ability")
    ui.pickerTitle:SetTextColor(1, 1, 1)
    ui.pickerTitle:SetShadowColor(0, 0, 0, 1)
    ui.pickerTitle:SetShadowOffset(1, -1)

    ui.pickerSearchLabel = ui.picker:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.pickerSearchLabel:SetPoint("TOPRIGHT", ui.picker, "TOPRIGHT", -194, -16)
    ui.pickerSearchLabel:SetText("Find ability")
    ui.pickerSearch = CreateFrame("EditBox", "FlourishForeverAbilitySearch", ui.picker, "InputBoxTemplate")
    ui.pickerSearch:SetSize(155, 20)
    ui.pickerSearch:SetPoint("LEFT", ui.pickerSearchLabel, "RIGHT", 10, 0)
    ui.pickerSearch:SetAutoFocus(false)
    ui.pickerSearch:SetMaxLetters(60)
    ui.pickerSearch:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    ui.pickerSearch:SetScript("OnTextChanged", function()
        if not ui.updating then ui:RefreshPicker() end
    end)

    ui.pickerEmpty = ui.picker:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.pickerEmpty:SetPoint("CENTER", ui.picker, "CENTER", 0, 0)
    ui.pickerEmpty:SetText("No learned abilities found.")
    ui.pickerEmpty:SetTextColor(0.28, 0.14, 0.05)
    ui.pickerEmpty:Hide()
    ui.pickerColumns = {}
    ui.generalHeader = ui.picker:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ui.generalHeader:SetText("General")
    ui.generalHeader:SetTextColor(0.28, 0.14, 0.05)
    ui.generalHeader:Hide()
    ui.generalScroll = CreateQuietScroll(ui.picker)
    ui.generalScroll:Hide()
    ui.generalChild = CreateFrame("Frame", nil, ui.generalScroll)
    ui.generalChild:SetSize(PAGE_W - 24, 1)
    ui.generalScroll:SetScrollChild(ui.generalChild)
    ui.generalButtons = {}

    ui.editorBack = CreateFrame("Button", nil, ui.editor, "UIPanelButtonTemplate")
    ui.editorBack:SetSize(80, 24)
    ui.editorBack:SetPoint("TOPLEFT", ui.editor, "TOPLEFT", 8, -8)
    ui.editorBack:SetText("Back")
    ui.editorBack:SetScript("OnClick", function()
        ui:ShowPage("home")
    end)

    ui.editorIcon = ui.editor:CreateTexture(nil, "ARTWORK")
    ui.editorIcon:SetSize(36, 36)
    ui.editorIcon:SetPoint("LEFT", ui.editorBack, "RIGHT", 16, 0)

    ui.editorTitle = ui.editor:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ui.editorTitle:SetPoint("LEFT", ui.editorIcon, "RIGHT", 10, 0)
    ui.editorTitle:SetJustifyH("LEFT")
    ui.editorTitle:SetWidth(280)

    ui.searchLabel = ui.editor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.searchLabel:SetPoint("TOPRIGHT", ui.editor, "TOPRIGHT", -188, -12)
    ui.searchLabel:SetText("Search")
    ui.search = CreateFrame("EditBox", "FlourishForeverEmoteSearch", ui.editor, "InputBoxTemplate")
    ui.search:SetSize(160, 20)
    ui.search:SetPoint("LEFT", ui.searchLabel, "RIGHT", 10, 0)
    ui.search:SetAutoFocus(false)
    ui.search:SetMaxLetters(40)
    ui.search:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    ui.search:SetScript("OnTextChanged", function()
        if not ui.updating then
            ui:LayoutEmoteRows()
        end
    end)

    ui.chance = CreateFrame("Slider", "FlourishForeverChanceSlider", ui.editor, "OptionsSliderTemplate")
    ui.chance:SetPoint("TOPLEFT", ui.editor, "TOPLEFT", 24, -58)
    ui.chance:SetSize(460, 18)
    ui.chance:SetMinMaxValues(0, 100)
    ui.chance:SetValueStep(1)
    ui.chance:SetObeyStepOnDrag(true)
    _G[ui.chance:GetName() .. "Low"]:SetText("0%")
    _G[ui.chance:GetName() .. "High"]:SetText("100%")
    ui.chance:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        _G[self:GetName() .. "Text"]:SetText("Chance: " .. value .. "%")
        if not ui.updating and selectedKey then
            EnsureDB()
            local cfg = db.instances[selectedKey]
            if cfg then
                cfg.chance = value
            end
        end
    end)

    ui.emoteHint = ui.editor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.emoteHint:SetPoint("TOPLEFT", ui.editor, "TOPLEFT", 16, -108)
    ui.emoteHint:SetText("Emotes. One ready emote is chosen at random.")

    ui.emoteScroll = CreateQuietScroll(ui.editor)
    ui.emoteScroll:SetPoint("TOPLEFT", ui.editor, "TOPLEFT", 12, -132)
    ui.emoteScroll:SetPoint("BOTTOMRIGHT", ui.editor, "BOTTOMRIGHT", -12, 40)
    ui.emoteChild = CreateFrame("Frame", nil, ui.emoteScroll)
    ui.emoteChild:SetSize(750, 1)
    ui.emoteScroll:SetScrollChild(ui.emoteChild)
    ui.emoteRows = {}

    ui.remove = CreateFrame("Button", nil, ui.editor, "UIPanelButtonTemplate")
    ui.remove:SetSize(110, 24)
    ui.remove:SetPoint("BOTTOMLEFT", ui.editor, "BOTTOMLEFT", 8, 8)
    ui.remove:SetText("Remove")
    ui.remove:SetScript("OnClick", function()
        if not selectedKey then
            return
        end
        EnsureDB()
        db.instances[selectedKey] = nil
        lastFireByAbility[selectedKey] = nil
        selectedKey = nil
        ui:ShowPage("home")
    end)

    ui.customBack = CreateFrame("Button", nil, ui.custom, "UIPanelButtonTemplate")
    ui.customBack:SetSize(80, 24)
    ui.customBack:SetPoint("TOPLEFT", ui.custom, "TOPLEFT", 8, -8)
    ui.customBack:SetText("Back")
    ui.customBack:SetScript("OnClick", function()
        ui:SaveCustomEmotes()
        ui:ShowPage("home")
    end)

    ui.customTitle = ui.custom:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ui.customTitle:SetPoint("LEFT", ui.customBack, "RIGHT", 16, 0)
    ui.customTitle:SetText("Custom emotes")

    ui.customHint = ui.custom:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ui.customHint:SetPoint("TOPLEFT", ui.custom, "TOPLEFT", 12, -44)
    ui.customHint:SetWidth(PAGE_W - 40)
    ui.customHint:SetJustifyH("LEFT")
    ui.customHint:SetText("One emote per line. Each line is sent as /e when you press the ability, so your name appears and then the text.")

    ui.customScroll = CreateQuietScroll(ui.custom)
    ui.customScroll:SetPoint("TOPLEFT", ui.custom, "TOPLEFT", 12, -84)
    ui.customScroll:SetPoint("BOTTOMRIGHT", ui.custom, "BOTTOMRIGHT", -12, 44)
    ui.customEdit = CreateFrame("EditBox", "FlourishForeverCustomEdit", ui.customScroll)
    ui.customEdit:SetMultiLine(true)
    ui.customEdit:SetAutoFocus(false)
    ui.customEdit:SetFontObject(GameFontHighlight)
    ui.customEdit:SetWidth(700)
    ui.customEdit:SetHeight(400)
    ui.customEdit:SetMaxLetters(4000)
    ui.customScroll:SetScrollChild(ui.customEdit)
    ui.customEdit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    ui.customEdit:SetScript("OnTextChanged", function(self)
        local lines = 1
        for _ in string.gmatch(self:GetText() or "", "\n") do
            lines = lines + 1
        end
        self:SetHeight(math.max(400, lines * 18))
    end)

    ui.customSave = CreateFrame("Button", nil, ui.custom, "UIPanelButtonTemplate")
    ui.customSave:SetSize(80, 24)
    ui.customSave:SetPoint("BOTTOMLEFT", ui.custom, "BOTTOMLEFT", 8, 8)
    ui.customSave:SetText("Save")
    ui.customSave:SetScript("OnClick", function()
        ui:SaveCustomEmotes()
        ui.customEdit:ClearFocus()
    end)

    local function EnsureHomeRow(index)
        local row = ui.homeRows[index]
        if row then
            return row
        end

        row = CreateFrame("Frame", nil, ui.homeChild)
        row:SetSize(HOME_ROW_W, HOME_ROW_H)
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        row.bg:SetVertexColor(0.11, 0.08, 0.05, 0.92)

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(40, 40)
        row.icon:SetPoint("LEFT", row, "LEFT", 8, 0)

        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 10, -4)
        row.name:SetJustifyH("LEFT")
        row.name:SetWidth(HOME_ROW_W - 120)
        row.name:SetWordWrap(false)

        row.emotes = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.emotes:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 10, 4)
        row.emotes:SetJustifyH("LEFT")
        row.emotes:SetWidth(HOME_ROW_W - 120)
        row.emotes:SetWordWrap(false)

        row.enable = CreateFrame("CheckButton", nil, ui.homeChild, "UICheckButtonTemplate")
        row.enable:SetScript("OnClick", function(self)
            if ui.updating then
                return
            end
            EnsureDB()
            local cfg = db.instances[row.abilityKey]
            if not cfg then
                return
            end
            cfg.enabled = self:GetChecked() and true or false
            row:SetAlpha(cfg.enabled and 1 or 0.55)
        end)

        row.hit = CreateFrame("Button", nil, row)
        row.hit:SetAllPoints(row)
        StretchHighlight(row.hit)
        row.hit:SetScript("OnClick", function()
            selectedKey = row.abilityKey
            ui:ShowPage("editor")
        end)
        row.hit:SetScript("OnEnter", function()
            EnsureDB()
            local cfg = db.instances[row.abilityKey]
            if cfg then
                ShowAbilityTooltip(row.hit, cfg)
            end
        end)
        row.hit:SetScript("OnLeave", HideAbilityTooltip)

        ui.homeRows[index] = row
        return row
    end

    local function EnsurePickerColumn(index)
        local column = ui.pickerColumns[index]
        if column then
            return column
        end

        column = CreateFrame("Frame", nil, ui.picker)
        column.icon = column:CreateTexture(nil, "ARTWORK")
        column.icon:SetSize(22, 22)
        column.icon:SetPoint("TOPLEFT", column, "TOPLEFT", 4, 0)
        column.header = column:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        column.header:SetPoint("LEFT", column.icon, "RIGHT", 6, 0)
        column.header:SetJustifyH("LEFT")
        column.header:SetTextColor(0.28, 0.14, 0.05)

        column.scroll = CreateQuietScroll(column)
        column.scroll:SetPoint("TOPLEFT", column, "TOPLEFT", 0, -28)
        column.scroll:SetPoint("BOTTOMRIGHT", column, "BOTTOMRIGHT", 0, 0)
        column.child = CreateFrame("Frame", nil, column.scroll)
        column.child:SetSize(180, 1)
        column.scroll:SetScrollChild(column.child)
        column.buttons = {}
        ui.pickerColumns[index] = column
        return column
    end

    local function EnsurePickerButton(column, index)
        local button = column.buttons[index]
        if button then
            return button
        end

        button = CreateFrame("Button", nil, column.child)
        button:SetHeight(64)
        DressAbilityButton(button)
        button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        button.label:SetPoint("LEFT", button.icon, "RIGHT", 14, 0)
        button.label:SetJustifyH("LEFT")
        button.label:SetTextColor(0.25, 0.13, 0.05)
        button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        StretchHighlight(button)
        button:SetScript("OnClick", function(self)
            AddOrSelectAbility(self.ability)
            ui:ShowPage("editor")
        end)
        column.buttons[index] = button
        return button
    end

    local function EnsureEmoteRow(index)
        local row = ui.emoteRows[index]
        if row then
            return row
        end

        row = CreateFrame("Frame", nil, ui.emoteChild)
        row:SetSize(680, 32)
        row.plate = row:CreateTexture(nil, "BACKGROUND")
        row.plate:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        row.plate:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -4, 0)
        row.plate:SetTexture("Interface\\Buttons\\WHITE8X8")
        row.plate:SetVertexColor(1, 0.92, 0.75, 0.16)
        row.plate:Hide()
        row.check = CreateCheckbox(row)
        row.check:ClearAllPoints()
        row.check:SetPoint("TOPLEFT", row, "TOPLEFT", 2, 2)
        row.check:SetScript("OnClick", function(self)
            if not selectedKey then
                return
            end
            EnsureDB()
            local cfg = db.instances[selectedKey]
            if not cfg then
                return
            end

            if self:GetChecked() then
                cfg.emotes[self.token] = { cooldown = DEFAULT_COOLDOWN }
                ui.updating = true
                row.slider:SetValue(DEFAULT_COOLDOWN)
                ui.updating = false
                row.slider:Show()
                row.plate:Show()
            else
                cfg.emotes[self.token] = nil
                row.slider:Hide()
                row.plate:Hide()
            end

            ui:LayoutEmoteRows()
        end)

        row.slider = CreateFrame("Slider", "FlourishForeverEmoteCD" .. index, row, "OptionsSliderTemplate")
        row.slider:ClearAllPoints()
        row.slider:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 10, 8)
        row.slider:SetSize(110, 16)
        row.slider:SetMinMaxValues(0, 120)
        row.slider:SetValueStep(1)
        row.slider:SetObeyStepOnDrag(true)
        _G[row.slider:GetName() .. "Low"]:Hide()
        _G[row.slider:GetName() .. "High"]:Hide()
        local sliderText = _G[row.slider:GetName() .. "Text"]
        sliderText:ClearAllPoints()
        sliderText:SetPoint("LEFT", row.slider, "RIGHT", 6, 0)
        row.slider:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value + 0.5)
            _G[self:GetName() .. "Text"]:SetText(value .. " sec")
            if ui.updating or not selectedKey then
                return
            end
            EnsureDB()
            local cfg = db.instances[selectedKey]
            local entry = cfg and cfg.emotes[row.check.token]
            if type(entry) == "table" then
                entry.cooldown = value
            end
        end)
        row.slider:Hide()

        row.header = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.header:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.header:SetJustifyH("LEFT")
        row.header:Hide()

        ui.emoteRows[index] = row
        return row
    end

    function ui:ShowPage(name)
        HideAbilityTooltip()
        self.page = name
        self.home:SetShown(name == "home")
        self.picker:SetShown(name == "picker")
        self.editor:SetShown(name == "editor")
        self.custom:SetShown(name == "custom")

        if name == "picker" then
            self.pickerTitle:SetTextColor(1, 1, 1)
            self.spellColumns = nil
            self.updating = true
            self.pickerSearch:SetText("")
            self.updating = false
            self:RefreshPicker()
        elseif name == "editor" then
            self.updating = true
            self.search:SetText("")
            self.updating = false
            self:RefreshEditor()
        elseif name == "custom" then
            self:LoadCustomEmotes()
        else
            self:RefreshHome()
        end
    end

    function ui:LoadCustomEmotes()
        EnsureDB()
        local lines = {}
        for _, entry in ipairs(db.customEmotes) do
            lines[#lines + 1] = entry.text
        end
        self.updating = true
        self.customEdit:SetText(table.concat(lines, "\n"))
        self.updating = false
    end

    function ui:SaveCustomEmotes()
        EnsureDB()
        local previous = db.customEmotes
        local oldByText = {}
        for _, entry in ipairs(previous) do
            if not oldByText[entry.text] then
                oldByText[entry.text] = entry.id
            end
        end

        local lines, seen = {}, {}
        for line in string.gmatch((self.customEdit:GetText() or "") .. "\n", "(.-)\n") do
            line = Trim(line)
            if line ~= "" and not seen[line] then
                seen[line] = true
                lines[#lines + 1] = line
            end
        end

        -- Retain IDs by exact text first; when only the text was edited,
        -- reuse the old ID in that position. Existing ability selections
        -- then follow the edited emote instead of being silently detached.
        local list, usedIDs = {}, {}
        for index, line in ipairs(lines) do
            local id = oldByText[line]
            if id then
                usedIDs[id] = true
            end
            list[index] = { id = id, text = line }
        end
        local seq = BoundedWholeNumber(db.customEmoteSeq, 0, 0, 2147483647)
        for index, entry in ipairs(list) do
            if not entry.id then
                local old = previous[index]
                if old and old.id and not usedIDs[old.id] then
                    entry.id = old.id
                    usedIDs[entry.id] = true
                else
                    repeat
                        seq = seq + 1
                    until not usedIDs[tostring(seq)]
                    entry.id = tostring(seq)
                    usedIDs[entry.id] = true
                end
            end
        end

        db.customEmoteSeq = seq
        db.customEmotes = list
        EnsureDB()
    end

    function ui:RefreshHome()
        EnsureDB()
        self.enabled:SetChecked(db.actionEmotesEnabled)

        local listW = self.homeScroll:GetWidth()
        if not listW or listW < 200 then
            listW = 760
        end
        local widgetW = listW - 44
        self.homeChild:SetWidth(listW)

        local keys = SortedInstanceKeys()
        local query = string.lower(Trim(self.homeSearch:GetText() or ""))
        if query ~= "" then
            local filtered = {}
            for _, key in ipairs(keys) do
                local cfg = db.instances[key]
                if string.find(string.lower(cfg.name or key), query, 1, true) then
                    filtered[#filtered + 1] = key
                end
            end
            keys = filtered
        end
        for i, key in ipairs(keys) do
            local cfg = db.instances[key]
            local row = EnsureHomeRow(i)
            local entries = SortedEnabledEmotes(cfg)
            row.abilityKey = key
            row:SetSize(widgetW, HOME_ROW_H)
            row:SetPoint("TOPLEFT", self.homeChild, "TOPLEFT", 0, -((i - 1) * (HOME_ROW_H + 6)))
            row.name:SetWidth(math.max(40, widgetW - 70))
            row.emotes:SetWidth(math.max(40, widgetW - 70))
            ApplyIcon(row.icon, SpellIcon(cfg.spellID))
            row.name:SetText(cfg.name or key)
            row.emotes:SetText(EmoteSummary(entries))
            row.enable:ClearAllPoints()
            row.enable:SetPoint("LEFT", row, "RIGHT", 10, 0)
            self.updating = true
            row.enable:SetChecked(cfg.enabled ~= false)
            self.updating = false
            row:SetAlpha(cfg.enabled ~= false and 1 or 0.55)
            row.enable:Show()
            row:Show()
        end

        for i = #keys + 1, #self.homeRows do
            self.homeRows[i]:Hide()
            self.homeRows[i].enable:Hide()
        end

        self.homeChild:SetHeight(math.max(1, #keys * (HOME_ROW_H + 6)))
        self.homeEmpty:SetText(query == "" and "No abilities yet." or "No matching abilities.")
        self.homeEmpty:SetShown(#keys == 0)
    end

    function ui:RefreshPicker()
        -- Spellbook enumeration is cached while typing, but refreshed on entry
        -- or SPELLS_CHANGED. No polling or per-keystroke API walks.
        if not self.spellColumns then
            self.spellColumns = CollectSpellColumns()
        end
        local query = string.lower(Trim(self.pickerSearch:GetText() or ""))
        local columns = {}
        for _, original in ipairs(self.spellColumns) do
            local result = {
                name = original.name,
                icon = original.icon,
                specID = original.specID,
                abilities = {},
            }
            for _, ability in ipairs(original.abilities) do
                if query == "" or string.find(string.lower(ability.name), query, 1, true) then
                    result.abilities[#result.abilities + 1] = ability
                end
            end
            if #result.abilities > 0 then
                columns[#columns + 1] = result
            end
        end
        local general = nil
        local specs = {}
        for _, column in ipairs(columns) do
            if IsGeneralTab(column.name) then
                general = column
            else
                specs[#specs + 1] = column
            end
        end

        self.pickerEmpty:SetText(query == "" and "No learned abilities found." or "No matching abilities.")
        self.pickerEmpty:SetShown(not general and #specs == 0)

        local generalHeight = 0
        if general and #general.abilities > 0 then
            local buttonW = 248
            local pitch = 70
            local perRow = math.max(1, math.floor((PAGE_W - 24) / buttonW))
            local rows = math.ceil(#general.abilities / perRow)
            local contentH = rows * pitch
            local viewH = math.min(contentH, pitch * 2)
            generalHeight = 28 + viewH

            self.generalHeader:ClearAllPoints()
            self.generalHeader:SetPoint("TOP", self.picker, "TOP", 0, -46)
            self.generalHeader:SetJustifyH("CENTER")
            self.generalHeader:Show()
            self.generalScroll:ClearAllPoints()
            self.generalScroll:SetPoint("TOPLEFT", self.picker, "TOPLEFT", 8, -70)
            self.generalScroll:SetSize(PAGE_W - 20, viewH)
            self.generalScroll:Show()
            self.generalChild:SetSize(PAGE_W - 24, math.max(1, contentH))

            for index, ability in ipairs(general.abilities) do
                local button = self.generalButtons[index]
                if not button then
                    button = CreateFrame("Button", nil, self.generalChild)
                    button:SetHeight(64)
                    DressAbilityButton(button)
                    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    button.label:SetPoint("LEFT", button.icon, "RIGHT", 14, 0)
                    button.label:SetJustifyH("LEFT")
                    button.label:SetTextColor(0.25, 0.13, 0.05)
                    StretchHighlight(button)
                    button:SetScript("OnClick", function(self)
                        AddOrSelectAbility(self.ability)
                        ui:ShowPage("editor")
                    end)
                    self.generalButtons[index] = button
                end
                local col = (index - 1) % perRow
                local rowIndex = math.floor((index - 1) / perRow)
                local rowCount = math.min(perRow, #general.abilities - rowIndex * perRow)
                local origin = math.floor((PAGE_W - 24 - rowCount * buttonW) / 2)
                button:SetPoint("TOPLEFT", self.generalChild, "TOPLEFT", origin + col * buttonW, -(rowIndex * pitch))
                button:SetWidth(buttonW - 8)
                button.label:SetWidth(buttonW - 96)
                button.ability = ability
                ApplyIcon(button.icon, ability.icon or SpellIcon(ability.spellID))
                button.label:SetText(ability.name)
                button:Show()
            end

            for index = #general.abilities + 1, #self.generalButtons do
                self.generalButtons[index]:Hide()
            end
        else
            self.generalHeader:Hide()
            self.generalScroll:Hide()
            for _, button in ipairs(self.generalButtons) do
                button:Hide()
            end
        end

        local gap = 16
        local count = #specs
        local width = count > 0 and ((PAGE_W - 16 - gap * (count - 1)) / count) or PAGE_W
        local specTop = -50 - generalHeight
        local specHeight = PAGE_H - 62 - generalHeight

        for i, columnInfo in ipairs(specs) do
            local column = EnsurePickerColumn(i)
            column:ClearAllPoints()
            column:SetPoint("TOPLEFT", self.picker, "TOPLEFT", 8 + (i - 1) * (width + gap), specTop)
            column:SetSize(width, math.max(80, specHeight))
            column.header:SetText(columnInfo.name or "Abilities")
            column.header:SetWidth(math.max(40, width - 36))
            column.header:ClearAllPoints()
            if columnInfo.icon then
                ApplyIcon(column.icon, columnInfo.icon)
                column.icon:Show()
                column.header:SetPoint("LEFT", column.icon, "RIGHT", 6, 0)
            else
                column.icon:Hide()
                column.header:SetPoint("TOPLEFT", column, "TOPLEFT", 4, -2)
            end
            column:Show()

            local buttonWidth = math.max(80, width - 8)
            column.child:SetWidth(buttonWidth)
            for index, ability in ipairs(columnInfo.abilities) do
                local button = EnsurePickerButton(column, index)
                button:SetPoint("TOPLEFT", column.child, "TOPLEFT", 0, -((index - 1) * 70))
                button:SetWidth(buttonWidth)
                button.label:SetWidth(math.max(40, buttonWidth - 96))
                button.ability = ability
                ApplyIcon(button.icon, ability.icon or SpellIcon(ability.spellID))
                button.label:SetText(ability.name)
                button:Show()
            end

            for index = #columnInfo.abilities + 1, #column.buttons do
                column.buttons[index]:Hide()
            end

            column.child:SetHeight(math.max(1, #columnInfo.abilities * 70))
        end

        for i = count + 1, #self.pickerColumns do
            self.pickerColumns[i]:Hide()
        end
    end

    function ui:LayoutEmoteRows()
        local filter = string.lower(Trim(self.search and self.search:GetText() or ""))
        local cols = 4
        local gap = 10
        local areaW = self.emoteScroll:GetWidth()
        if not areaW or areaW < 200 then
            areaW = 750
        end
        self.emoteChild:SetWidth(areaW)
        local colW = math.floor((areaW - gap * (cols - 1)) / cols)

        local function Matches(item)
            return filter == "" or (item.search and string.find(item.search, filter, 1, true))
        end

        local function Place(rows, startY)
            if #rows == 0 then
                return startY
            end
            local per = math.max(1, math.ceil(#rows / cols))
            local bottoms = {}
            for _ = 1, cols do
                bottoms[#bottoms + 1] = startY
            end
            for index, row in ipairs(rows) do
                local col = math.min(cols, math.floor((index - 1) / per) + 1)
                local height = row.slider:IsShown() and 64 or 32
                row:SetWidth(colW)
                row.check.label:SetWidth(math.max(36, colW - 40))
                row.slider:SetWidth(math.max(64, colW - 78))
                row:SetHeight(height)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", self.emoteChild, "TOPLEFT", (col - 1) * (colW + gap), -bottoms[col])
                row:Show()
                bottoms[col] = bottoms[col] + height + 6
            end
            local bottom = startY
            for _, value in ipairs(bottoms) do
                if value > bottom then
                    bottom = value
                end
            end
            return bottom
        end

        local standard = {}
        local custom = {}
        local header = nil
        local customSection = false
        for i, item in ipairs(self.emoteItems or {}) do
            local row = self.emoteRows[i]
            if row then
                if item.header then
                    customSection = true
                    header = row
                    row:Hide()
                elseif Matches(item) then
                    if customSection then
                        custom[#custom + 1] = row
                    else
                        standard[#standard + 1] = row
                    end
                else
                    row:Hide()
                end
            end
        end

        local y = Place(standard, 0)
        if header and #custom > 0 then
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", self.emoteChild, "TOPLEFT", 0, -y)
            header:SetWidth(areaW)
            header:SetHeight(22)
            header:Show()
            y = y + 28
        end
        y = Place(custom, y)
        self.emoteChild:SetHeight(math.max(1, y))
    end

    function ui:RefreshEditor()
        EnsureDB()
        RefreshKnownEmotes()

        local cfg = selectedKey and db.instances[selectedKey]
        if not cfg then
            self:ShowPage("home")
            return
        end

        ApplyIcon(self.editorIcon, SpellIcon(cfg.spellID))
        self.editorTitle:SetText(cfg.name or selectedKey)

        self.updating = true
        self.chance:SetValue(tonumber(cfg.chance) or DEFAULT_CHANCE)
        self.updating = false

        local items = {}
        for _, token in ipairs(knownEmotes) do
            local label = EmoteLabel(token)
            items[#items + 1] = { token = token, label = label, search = string.lower(label) }
        end
        if #(db.customEmotes or {}) > 0 then
            items[#items + 1] = { header = "Custom emotes" }
            for _, entry in ipairs(db.customEmotes) do
                local label = "/e " .. entry.text
                items[#items + 1] = {
                    token = "c:" .. entry.id,
                    label = label,
                    search = string.lower(entry.text .. " " .. label),
                }
            end
        end
        self.emoteItems = items

        for i, item in ipairs(items) do
            local row = EnsureEmoteRow(i)
            if item.header then
                row.check:Hide()
                row.slider:Hide()
                row.plate:Hide()
                row.header:SetText(item.header)
                row.header:Show()
            else
                local entry = cfg.emotes[item.token]
                local checked = type(entry) == "table"
                row.header:Hide()
                row.check:Show()
                row.check.token = item.token
                row.check.label:SetText(item.label)
                row.check.label:SetWordWrap(false)
                row.check:SetChecked(checked)
                row.slider:SetShown(checked)
                row.plate:SetShown(checked)
                if checked then
                    self.updating = true
                    row.slider:SetValue(tonumber(entry.cooldown) or DEFAULT_COOLDOWN)
                    self.updating = false
                end
            end
        end

        for i = #items + 1, #self.emoteRows do
            self.emoteRows[i]:Hide()
        end

        self:LayoutEmoteRows()
    end

    ui:SetScript("OnShow", function(self)
        EnsureDB()
        RefreshKnownEmotes()
        self:ShowPage(self.page or "home")
    end)

    return ui
end

function FlourishForever_OpenConfig()
    local frame = CreateUI()
    if frame:IsShown() then
        frame:Hide()
    else
        frame.page = "home"
        frame:Show()
    end
end

function FlourishForever_ActionStatus()
    EnsureDB()
    local count = 0
    for key, cfg in pairs(db.instances) do
        if type(key) == "string" and key ~= "" and type(cfg) == "table" then
            count = count + 1
        end
    end
    return db.actionEmotesEnabled, count
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit == "player" and spellID then
            TryAbilityEmote(spellID)
        end
    elseif event == "SPELLS_CHANGED" then
        if ui then
            ui.spellColumns = nil
            if ui:IsShown() and ui.page == "picker" then
                ui:RefreshPicker()
            end
        end
    end
end)

eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("SPELLS_CHANGED")
