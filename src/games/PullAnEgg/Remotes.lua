--[[
    LuxuryXHUB - Pull An Egg
    Remotes.lua - Centralized Remote Dispatcher
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}
local remotesFolder = nil

local function getRemotesFolder()
    if remotesFolder then return remotesFolder end
    local shared = ReplicatedStorage:FindFirstChild("SharedModules")
    if shared then
        local network = shared:FindFirstChild("Network")
        if network then
            remotesFolder = network:FindFirstChild("Remotes")
        end
    end
    return remotesFolder
end

-- ── Safe Remote Caller Helpers ─────────────────────────────────────
function Remotes.fireEvent(name, ...)
    local folder = getRemotesFolder()
    if not folder then return false end
    local remote = folder:FindFirstChild(name)
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer(...)
        return true
    end
    return false
end

function Remotes.invokeFunction(name, ...)
    local folder = getRemotesFolder()
    if not folder then return nil end
    local remote = folder:FindFirstChild(name)
    if remote and remote:IsA("RemoteFunction") then
        return remote:InvokeServer(...)
    end
    return nil
end

-- ── Game Specific Actions ──────────────────────────────────────────

-- 1. Auto Train: Train strength using Dumbbell
function Remotes.train()
    return Remotes.fireEvent("Activate Dumbell")
end

-- 2. Auto Sell: Instantly sell all animals in inventory
function Remotes.sellAll()
    return Remotes.fireEvent("Sell All Friends")
end

-- 3. Auto Rebirth
function Remotes.rebirth()
    return Remotes.fireEvent("Rebirth")
end

-- 4. Claim Egg
function Remotes.claimEgg(eggNameOrId)
    if eggNameOrId then
        return Remotes.invokeFunction("Strange: Claim Egg", eggNameOrId)
    else
        return Remotes.invokeFunction("Strange: Claim Egg")
    end
end

-- 5. Claim Daily Reward
function Remotes.claimDailyReward()
    return Remotes.fireEvent("Claim Daily Reward")
end

-- 6. Claim Group Reward
function Remotes.claimGroupReward()
    return Remotes.fireEvent("Claim Group Reward")
end

-- 7. Reset AFK
function Remotes.resetAFK()
    return Remotes.fireEvent("AFK Idle Reset Request")
end

-- 8. Upgrade Carry
function Remotes.upgradeCarry()
    return Remotes.fireEvent("Upgrade Carry Limit")
end

-- 9. Buy Dumbbell
function Remotes.buyDumbell(nameOrIndex)
    local dumbellId = typeof(nameOrIndex) == "number" and ("Dumbell_" .. nameOrIndex) or tostring(nameOrIndex)
    return Remotes.fireEvent("Buy Dumbell", dumbellId)
end

return Remotes
