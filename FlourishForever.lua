SLASH_FLOURISHFOREVER1 = "/flourish"
SLASH_FLOURISHFOREVER2 = "/flourishforever"
SLASH_FLOURISHFOREVER3 = "/rit"
SLASH_FLOURISHFOREVER4 = "/ffsh"

SlashCmdList.FLOURISHFOREVER = function(msg)
    msg = string.lower((msg or ""):match("^%s*(.-)%s*$"))

    if msg == "" or msg == "config" or msg == "ui" then
        if FlourishForever_OpenConfig then
            FlourishForever_OpenConfig()
        else
            print("Flourish Forever: configuration UI is unavailable.")
        end
        return
    end

    if msg == "debug" then
        if FlourishForever_EmoteDiagnostics then
            print("Flourish Forever: " .. FlourishForever_EmoteDiagnostics())
        end
        return
    end

    local command, ability = msg:match("^(cooldowns)%s*(.-)%s*$")
    if command == "cooldowns" then
        if FlourishForever_CooldownDiagnostics then
            for _, line in ipairs(FlourishForever_CooldownDiagnostics(ability)) do
                print("Flourish Forever: " .. line)
            end
        end
        return
    end

    if msg == "status" then
        if FlourishForever_StorageStatus then
            print("Flourish Forever: " .. FlourishForever_StorageStatus())
        end

        if FlourishForever_ActionStatus then
            local enabled, count = FlourishForever_ActionStatus()
            print("Flourish Forever: ability emotes " .. (enabled and "enabled" or "disabled") .. ", " .. tostring(count) .. " configured abilities")
        end
        return
    end

    print("Flourish Forever: /flourish | /ffsh | /flourish status | /flourish debug | /flourish cooldowns [ability] | /flourish config")
end
