--[[
    LuxuryXHUB - Pull An Egg
    Bootstrap.lua - Application Lifecycle & Initialization
]]

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Bootstrap = {}

function Bootstrap.start(modules)
    print("[LuxuryXHUB] Initializing Pull An Egg Module...")

    local Config  = modules.Config
    local Remotes = modules.Remotes
    local Farm    = modules.Farm
    local ESP     = modules.ESP
    local UI      = modules.UI

    -- 1. Tear down any previous instance first
    if getgenv().LuxuryXHUB_PullAnEgg
    and typeof(getgenv().LuxuryXHUB_PullAnEgg.Unload) == "function"
    then
        pcall(function() getgenv().LuxuryXHUB_PullAnEgg.Unload() end)
    end

    -- 2. Initialize core logic
    if Farm    then Farm.init(Config, Remotes) end
    if ESP     then ESP.init(Config)           end
    if UI      then UI.init(Config, Farm, ESP, Remotes) end

    -- 3. Auto-claim rewards on load
    task.spawn(function()
        task.wait(2)
        if Remotes then
            pcall(function() Remotes.claimDailyReward() end)
            pcall(function() Remotes.claimGroupReward() end)
        end
    end)

    -- 4. Expose Unload handle
    local Runtime = {
        Unload = function()
            if Farm  then pcall(function() Farm.destroy()  end) end
            if ESP   then pcall(function() ESP.destroy()   end) end
            if UI    then pcall(function() UI.destroy()    end) end
            getgenv().LuxuryXHUB_PullAnEgg = nil
            print("[LuxuryXHUB] ♻️  Pull An Egg unloaded.")
        end
    }
    getgenv().LuxuryXHUB_PullAnEgg = Runtime

    print("[LuxuryXHUB] ✓ Pull An Egg Automation Suite Loaded Successfully!")
end

return Bootstrap
