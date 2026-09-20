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

local RunService = game:GetService("RunService")
local floatVelocity = nil
local noclipConnection = nil

function Farm.setFloat(enabled)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if enabled then
        if not floatVelocity or floatVelocity.Parent ~= root then
            floatVelocity = Instance.new("BodyVelocity")
            floatVelocity.Name = "LuxuryXHUB_Float"
            floatVelocity.Velocity = Vector3.new(0, 0, 0)
            floatVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            floatVelocity.Parent = root
        end
    else
        if floatVelocity then
            floatVelocity:Destroy()
            floatVelocity = nil
        end
        local old = root:FindFirstChild("LuxuryXHUB_Float")
        if old then old:Destroy() end
    end
end

function Farm.setNoclip(enabled)
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    if enabled then
        noclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- ── Teleport Helper ────────────────────────────────────────────────
function Farm.teleportTo(cf, heightOffset)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local h = heightOffset or 3
    if root and cf then
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        root.CFrame = cf + Vector3.new(0, h, 0)
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
        local h = (Config and Config.FlyHeight) or 16
        Farm.teleportTo(part.CFrame, h)
        if Config and Config.SafeHover then
            Farm.setFloat(true)
        end
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

-- 4. Auto Buy Dumbbell Loop
function Farm.startAutoBuyDumbell()
    if Farm.Threads["AutoBuyDumbell"] then return end
    Farm.Threads["AutoBuyDumbell"] = task.spawn(function()
        while Config.AutoBuyDumbell do
            for i = 1, 30 do
                if not Config.AutoBuyDumbell then break end
                Remotes.buyDumbell(i)
                task.wait(0.15)
            end
            task.wait(2)
        end
        Farm.Threads["AutoBuyDumbell"] = nil
    end)
end

function Farm.stopAutoBuyDumbell()
    Config.AutoBuyDumbell = false
    Farm.Threads["AutoBuyDumbell"] = nil
end

-- 5. Auto Upgrade Carry Loop
function Farm.startAutoUpgradeCarry()
    if Farm.Threads["AutoUpgradeCarry"] then return end
    Farm.Threads["AutoUpgradeCarry"] = task.spawn(function()
        while Config.AutoUpgradeCarry do
            Remotes.upgradeCarry()
            task.wait(2)
        end
        Farm.Threads["AutoUpgradeCarry"] = nil
    end)
end

function Farm.stopAutoUpgradeCarry()
    Config.AutoUpgradeCarry = false
    Farm.Threads["AutoUpgradeCarry"] = nil
end

-- 6. Auto Pull Egg Loop (With Boss-Safe Hover/Fly)
function Farm.startAutoPullEgg()
    if Farm.Threads["AutoPullEgg"] then return end
    Farm.Threads["AutoPullEgg"] = task.spawn(function()
        if Config.SafeHover then
            Farm.setFloat(true)
            Farm.setNoclip(true)
        end

        while Config.AutoPullEgg do
            local targetTier = Config.TargetEggTier or "Celestial"
            local part = Farm.getPartForTier(targetTier)

            if part then
                local flyHeight = Config.FlyHeight or 16
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local targetPos = part.Position + Vector3.new(0, flyHeight, 0)
                    local dist = (root.Position - targetPos).Magnitude
                    if dist > 8 then
                        Farm.teleportTo(part.CFrame, flyHeight)
                        task.wait(0.2)
                    end
                end

                -- Attempt claim and pull
                Remotes.claimEgg(targetTier)
                Remotes.train()
            end
            task.wait(0.2)
        end

        Farm.setFloat(false)
        Farm.setNoclip(false)
        Farm.Threads["AutoPullEgg"] = nil
    end)
end

function Farm.stopAutoPullEgg()
    Config.AutoPullEgg = false
    Farm.setFloat(false)
    Farm.setNoclip(false)
    Farm.Threads["AutoPullEgg"] = nil
end

return Farm
