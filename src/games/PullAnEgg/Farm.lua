--[[
    LuxuryXHUB - Pull An Egg
    Farm.lua - Core Automation Loops (Train, Pull Egg, Sell, Rebirth)
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Farm = {
    Running = false,
    Threads = {}
}

local Config = nil
local Remotes = nil

function Farm.init(cfg, rems)
    Config = cfg
    Remotes = rems
end

-- ── Teleport Helper ────────────────────────────────────────────────
function Farm.teleportTo(cf)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root and cf then
        root.CFrame = cf + Vector3.new(0, 3, 0)
    end
end

function Farm.getPartForTier(tierName)
    local spawnParts = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("SpawnParts")
    if not spawnParts then return nil end
    local folder = spawnParts:FindFirstChild(tierName)
    if folder then
        for _, part in ipairs(folder:GetChildren()) do
            if part:IsA("BasePart") then
                return part
            end
        end
    end
    return nil
end

function Farm.teleportToTier(tierName)
    local part = Farm.getPartForTier(tierName)
    if part then
        Farm.teleportTo(part.CFrame)
        return true
    end
    return false
end

function Farm.teleportToSpawn()
    local spawnLocation = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("SpawnLocation")
    if spawnLocation and spawnLocation:IsA("BasePart") then
        Farm.teleportTo(spawnLocation.CFrame)
        return true
    end
    return false
end

function Farm.teleportToShop(shopName)
    local shops = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("ShopStands")
    if shops then
        local target = shops:FindFirstChild(shopName)
        if target then
            local root = target:FindFirstChildWhichIsA("BasePart", true)
            if root then
                Farm.teleportTo(root.CFrame)
                return true
            end
        end
    end
    return false
end

-- ── Automation Loops ───────────────────────────────────────────────

-- 1. Auto Train Loop
function Farm.startAutoTrain()
    if Farm.Threads["AutoTrain"] then return end
    Farm.Threads["AutoTrain"] = task.spawn(function()
        while Config.AutoTrain do
            Remotes.train()
            task.wait(Config.TrainInterval or 0.1)
        end
        Farm.Threads["AutoTrain"] = nil
    end)
end

function Farm.stopAutoTrain()
    Config.AutoTrain = false
    Farm.Threads["AutoTrain"] = nil
end

-- 2. Auto Sell Loop
function Farm.startAutoSell()
    if Farm.Threads["AutoSell"] then return end
    Farm.Threads["AutoSell"] = task.spawn(function()
        while Config.AutoSell do
            Remotes.sellAll()
            task.wait(Config.SellInterval or 5)
        end
        Farm.Threads["AutoSell"] = nil
    end)
end

function Farm.stopAutoSell()
    Config.AutoSell = false
    Farm.Threads["AutoSell"] = nil
end

-- 3. Auto Rebirth Loop
function Farm.startAutoRebirth()
    if Farm.Threads["AutoRebirth"] then return end
    Farm.Threads["AutoRebirth"] = task.spawn(function()
        while Config.AutoRebirth do
            Remotes.rebirth()
            task.wait(Config.RebirthInterval or 2)
        end
        Farm.Threads["AutoRebirth"] = nil
    end)
end

function Farm.stopAutoRebirth()
    Config.AutoRebirth = false
    Farm.Threads["AutoRebirth"] = nil
end

-- 4. Auto Pull Egg Loop
function Farm.startAutoPullEgg()
    if Farm.Threads["AutoPullEgg"] then return end
    Farm.Threads["AutoPullEgg"] = task.spawn(function()
        while Config.AutoPullEgg do
            local targetTier = Config.TargetEggTier or "Celestial"
            local part = Farm.getPartForTier(targetTier)

            if part then
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    -- If further than 15 studs, reposition to egg
                    if (root.Position - part.Position).Magnitude > 15 then
                        Farm.teleportTo(part.CFrame)
                        task.wait(0.3)
                    end
                end

                -- Attempt claim and pull
                Remotes.claimEgg(targetTier)
                Remotes.train()
            end
            task.wait(0.2)
        end
        Farm.Threads["AutoPullEgg"] = nil
    end)
end

function Farm.stopAutoPullEgg()
    Config.AutoPullEgg = false
    Farm.Threads["AutoPullEgg"] = nil
end

return Farm
