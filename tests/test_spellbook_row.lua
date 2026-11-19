-- Offline check that the spellbook button uses the shipped Flourish logo.
assert(loadfile("FlourishForever_SpellBook.lua"))()
local path = FlourishForeverSpellBook.LogoTexture()
assert(path == "Interface\\AddOns\\FlourishForever\\Textures\\FlourishForeverLogo.tga",
    "portrait button points at the addon logo")
local handle = io.open("Textures/FlourishForeverLogo.tga", "rb")
assert(handle, "logo texture is present for the game install")
local header = handle:read(18)
handle:close()
assert(header and #header == 18, "logo texture has a TGA header")
print("PASS: spellbook portrait uses the shipped Flourish logo")
