local NS = getgenv().EggsESP
local S = NS.Services

local Interaction = {}

function Interaction.holdEKey(duration)
    duration = duration or 1.5
    local vim = S.VirtualInputManager
    local vu = S.VirtualUser
    if vim then pcall(function() vim:SendKeyEvent(true, Enum.KeyCode.E, false, game) end)
    elseif vu then pcall(function() vu:SetKeyDown("e") end) end
    task.wait(duration)
    if vim then pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.E, false, game) end) end
    if vu then pcall(function() vu:SetKeyUp("e") end) end
end

function Interaction.trigger(targetObject, fallbackDuration)
    if not targetObject then return false end
    local prompt = targetObject:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.Enabled and fireproximityprompt then
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.2)
        return true
    end
    Interaction.holdEKey(fallbackDuration)
    return true
end

NS.Interaction = Interaction