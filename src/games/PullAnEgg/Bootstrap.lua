--[[
    LuxuryXHUB - Pull An Egg
    Bootstrap.lua - Application Lifecycle & Initialization
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Bootstrap = {}

function Bootstrap.start(modules)
    print("[LuxuryXHUB] Initializing Pull An Egg Module...")

    local Config  = modules.Config
    local Remotes = modules.Remotes
    local Farm    = modules.Farm
    local ESP     = modules.ESP
    local UI      = modules.UI

    -- 1. Initialize core logic
    if Farm then Farm.init(Config, Remotes) end
    if ESP then ESP.init(Config) end
    if UI then UI.init(Config, Farm, ESP, Remotes) end

    -- 2. Anti-AFK Protection
    LocalPlayer.Idled:Connect(function()
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        if Remotes and Remotes.resetAFK then
            Remotes.resetAFK()
        end
    end)

    -- 3. Auto Claim Initial Rewards
    task.spawn(function()
        task.wait(2)
        if Remotes then
            Remotes.claimDailyReward()
            Remotes.claimGroupReward()
        end
    end)

    -- Clear any previous instance
    if getgenv().LuxuryXHUB_PullAnEgg and typeof(getgenv().LuxuryXHUB_PullAnEgg.Unload) == "function" then
        pcall(function() getgenv().LuxuryXHUB_PullAnEgg.Unload() end)
    end

    local Runtime = {
        Unload = function()
            if Farm then
                Farm.stopAutoTrain()
                Farm.stopAutoSell()
                Farm.stopAutoRebirth()
                Farm.stopAutoPullEgg()
            end
            if ESP and ESP.destroy then ESP.destroy() end
            if UI and UI.destroy then UI.destroy() end
            getgenv().LuxuryXHUB_PullAnEgg = nil
            print("[LuxuryXHUB] ♻️ Cleared previous Pull An Egg instance.")
        end
    }
    getgenv().LuxuryXHUB_PullAnEgg = Runtime

    print("[LuxuryXHUB] ✓ Pull An Egg Automation Suite Loaded Successfully!")
end

return Bootstrap
