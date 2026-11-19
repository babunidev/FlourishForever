-- Top-left spellbook button for Forever's PlayerSpellsFrame.
-- Clicking it opens the Flourish window. This file does not cast spells.

local LOGO = "Interface\\AddOns\\FlourishForever\\Textures\\FlourishForeverLogo.tga"
local PORTRAIT_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

FlourishForeverSpellBook = FlourishForeverSpellBook or {}

local book, button, attached

function FlourishForeverSpellBook.LogoTexture()
    return LOGO
end

local function hideTooltip()
    if GameTooltip then GameTooltip:Hide() end
end

local function showTooltip(owner)
    if not GameTooltip then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText("Flourish Forever")
    GameTooltip:Show()
end

local function openMenu()
    if FlourishForever_OpenConfig then
        FlourishForever_OpenConfig()
    end
end

local function placeButton()
    if not button or not PlayerSpellsFrame then return end
    local gamepad = InputUtil and InputUtil.IsGamepadUIEnabled and InputUtil.IsGamepadUIEnabled()
    local container = PlayerSpellsFrame.PortraitContainer
    local native = container and (container.portrait or container.Portrait or container)
    if gamepad or not book or not book:IsVisible() or not container or not native then
        button:Hide()
        return
    end

    button:SetParent(container)
    button:ClearAllPoints()
    button:SetAllPoints(native)
    button.icon:ClearAllPoints()
    button.icon:SetAllPoints(button)
    if not button.masked and button.icon.AddMaskTexture and button.CreateMaskTexture then
        local mask = button:CreateMaskTexture()
        local circle = container.CircleMask
        if circle then
            mask:SetAllPoints(circle)
        else
            mask:SetAllPoints(button.icon)
        end
        mask:SetTexture(PORTRAIT_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        button.icon:AddMaskTexture(mask)
        button.masked = true
    end

    local level = container.GetFrameLevel and container:GetFrameLevel() or 1
    if container.GetChildren then
        for _, child in ipairs({ container:GetChildren() }) do
            if child and child ~= button and child.GetFrameLevel and child:GetFrameLevel() > level then
                level = child:GetFrameLevel()
            end
        end
    end
    button:SetFrameStrata(container.GetFrameStrata and container:GetFrameStrata() or "HIGH")
    button:SetFrameLevel(level + 5)
    button:Show()
end

local queued
local function request()
    if queued or not book then return end
    queued = true
    local function run()
        queued = false
        placeButton()
    end
    if RunNextFrame then
        RunNextFrame(run)
    else
        run()
    end
end

local function createButton()
    button = CreateFrame("Button", "FlourishForeverSpellBookButton", PlayerSpellsFrame)
    button:Hide()
    button:RegisterForClicks("AnyUp")
    button:EnableMouse(true)
    button.icon = button:CreateTexture(nil, "OVERLAY")
    button.icon:SetAllPoints()
    button.icon:SetTexture(LOGO)
    button:SetScript("OnClick", openMenu)
    button:SetScript("OnEnter", showTooltip)
    button:SetScript("OnLeave", hideTooltip)
end

function FlourishForeverSpellBook.TryAttach()
    if attached or not PlayerSpellsFrame or not PlayerSpellsFrame.SpellBookFrame or not CreateFrame then
        return false
    end
    book = PlayerSpellsFrame.SpellBookFrame
    createButton()
    attached = true

    local function bind(event)
        if EventRegistry and EventRegistry.RegisterCallback then
            EventRegistry:RegisterCallback(event, request, button)
        end
    end
    bind("PlayerSpellsFrame.SpellBookFrame.Show")
    bind("PlayerSpellsFrame.SpellBookFrame.Hide")

    if book.HookScript then
        book:HookScript("OnShow", request)
        book:HookScript("OnHide", request)
        book:HookScript("OnSizeChanged", request)
    end
    if PlayerSpellsFrame.HookScript then
        PlayerSpellsFrame:HookScript("OnShow", request)
    end
    request()
    if C_Timer and C_Timer.After then
        C_Timer.After(0.2, request)
    end
    return true
end

if EventUtil and EventUtil.ContinueOnAddOnLoaded then
    EventUtil.ContinueOnAddOnLoaded("Blizzard_PlayerSpells", FlourishForeverSpellBook.TryAttach)
else
    FlourishForeverSpellBook.TryAttach()
end
