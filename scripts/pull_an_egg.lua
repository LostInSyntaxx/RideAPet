--[[
    LuxuryXHUB - Pull An Egg (Standalone Monolithic Bundle)
    File: scripts/pull_an_egg.lua
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ===================================================================
-- 1. CONFIG MODULE
-- ===================================================================
local Config = {
    GameName = "Pull An Egg",
    PlaceId  = 70640255604878,
    GameId   = 10649255304,

    AutoTrain       = false,
    TrainInterval   = 0.1,

    AutoSell        = false,
    SellInterval    = 2,

    AutoRebirth     = false,
    RebirthInterval = 1,

    AutoBuyDumbell  = false,
    AutoUpgradeCarry= false,
    AutoRevive      = true,

    AutoPullEgg     = false,
    TargetEggTier   = "Celestial",
    FlyHeight       = 16,
    SafeHover       = true,

    EggESP          = true,

    TIERS = {
        "Celestial",
        "Transcendent",
        "Divine",
        "OG",
        "Brainrot God",
        "Secret",
        "Mythic",
        "Legendary",
        "Epic",
        "Rare",
        "Common",
    },

    TIER_COLORS = {
        ["Celestial"]    = Color3.fromRGB(0, 240, 255),
        ["Transcendent"] = Color3.fromRGB(255, 0, 128),
        ["Divine"]       = Color3.fromRGB(255, 215, 0),
        ["OG"]           = Color3.fromRGB(138, 43, 226),
        ["Brainrot God"] = Color3.fromRGB(255, 69, 0),
        ["Secret"]       = Color3.fromRGB(75, 0, 130),
        ["Mythic"]       = Color3.fromRGB(255, 50, 50),
        ["Legendary"]    = Color3.fromRGB(255, 165, 0),
        ["Epic"]         = Color3.fromRGB(186, 85, 211),
        ["Rare"]         = Color3.fromRGB(30, 144, 255),
        ["Common"]       = Color3.fromRGB(180, 180, 180),
    }
}

-- ===================================================================
-- 2. REMOTES MODULE
-- ===================================================================
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

function Remotes.train() return Remotes.fireEvent("Activate Dumbell") end
function Remotes.sellAll() return Remotes.fireEvent("Sell All Friends") end
function Remotes.rebirth() return Remotes.fireEvent("Rebirth") end
function Remotes.claimEgg(eggNameOrId)
    if eggNameOrId then
        return Remotes.invokeFunction("Strange: Claim Egg", eggNameOrId)
    else
        return Remotes.invokeFunction("Strange: Claim Egg")
    end
end
function Remotes.claimDailyReward() return Remotes.fireEvent("Claim Daily Reward") end
function Remotes.claimGroupReward() return Remotes.fireEvent("Claim Group Reward") end
function Remotes.resetAFK() return Remotes.fireEvent("AFK Idle Reset Request") end
function Remotes.upgradeCarry() return Remotes.fireEvent("Upgrade Carry Limit") end
function Remotes.buyDumbell(nameOrIndex)
    local dumbellId = typeof(nameOrIndex) == "number" and ("Dumbell_" .. nameOrIndex) or tostring(nameOrIndex)
    return Remotes.fireEvent("Buy Dumbell", dumbellId)
end

-- ===================================================================
-- 3. FARM MODULE
-- ===================================================================
local Farm = {
    Running = false,
    Threads = {}
}

local floatVelocity = nil
local noclipConnection = nil

function Farm.init(cfg, rems)
    Config = cfg
    Remotes = rems
    Farm.hookAutoRevive()
end

function Farm.hookAutoRevive()
    task.spawn(function()
        while true do
            if Config and Config.AutoRevive then
                local pgui = LocalPlayer:FindFirstChild("PlayerGui")
                local reviveGui = pgui and pgui:FindFirstChild("Revive")
                if reviveGui and reviveGui.Enabled then
                    local main = reviveGui:FindFirstChild("Main")
                    local yes = main and main:FindFirstChild("Yes")
                    if yes then
                        if firesignal then
                            firesignal(yes.MouseButton1Click)
                        else
                            pcall(function()
                                local vim = game:GetService("VirtualInputManager")
                                local pos = yes.AbsolutePosition + (yes.AbsoluteSize / 2)
                                vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                                vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
                            end)
                        end
                    end
                end
            end
            task.wait(0.3)
        end
    end)
end

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
        if floatVelocity then floatVelocity:Destroy() floatVelocity = nil end
        local old = root:FindFirstChild("LuxuryXHUB_Float")
        if old then old:Destroy() end
    end
end

function Farm.setNoclip(enabled)
    if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
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
            if part:IsA("BasePart") then return part end
        end
    end
    return nil
end

function Farm.teleportToTier(tierName)
    local part = Farm.getPartForTier(tierName)
    if part then
        local h = (Config and Config.FlyHeight) or 16
        Farm.teleportTo(part.CFrame, h)
        if Config and Config.SafeHover then Farm.setFloat(true) end
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
            if root then Farm.teleportTo(root.CFrame) return true end
        end
    end
    return false
end

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

function Farm.startAutoSell()
    if Farm.Threads["AutoSell"] then return end
    Farm.Threads["AutoSell"] = task.spawn(function()
        while Config.AutoSell do
            Remotes.sellAll()
            task.wait(Config.SellInterval or 2)
        end
        Farm.Threads["AutoSell"] = nil
    end)
end

function Farm.stopAutoSell()
    Config.AutoSell = false
    Farm.Threads["AutoSell"] = nil
end

function Farm.startAutoRebirth()
    if Farm.Threads["AutoRebirth"] then return end
    Farm.Threads["AutoRebirth"] = task.spawn(function()
        while Config.AutoRebirth do
            Remotes.rebirth()
            task.wait(Config.RebirthInterval or 1)
        end
        Farm.Threads["AutoRebirth"] = nil
    end)
end

function Farm.stopAutoRebirth()
    Config.AutoRebirth = false
    Farm.Threads["AutoRebirth"] = nil
end

function Farm.startAutoBuyDumbell()
    if Farm.Threads["AutoBuyDumbell"] then return end
    Farm.Threads["AutoBuyDumbell"] = task.spawn(function()
        while Config.AutoBuyDumbell do
            for i = 1, 30 do
                if not Config.AutoBuyDumbell then break end
                Remotes.buyDumbell(i)
                task.wait(0.05)
            end
            task.wait(1)
        end
        Farm.Threads["AutoBuyDumbell"] = nil
    end)
end

function Farm.stopAutoBuyDumbell()
    Config.AutoBuyDumbell = false
    Farm.Threads["AutoBuyDumbell"] = nil
end

function Farm.startAutoUpgradeCarry()
    if Farm.Threads["AutoUpgradeCarry"] then return end
    Farm.Threads["AutoUpgradeCarry"] = task.spawn(function()
        while Config.AutoUpgradeCarry do
            Remotes.upgradeCarry()
            task.wait(1)
        end
        Farm.Threads["AutoUpgradeCarry"] = nil
    end)
end

function Farm.stopAutoUpgradeCarry()
    Config.AutoUpgradeCarry = false
    Farm.Threads["AutoUpgradeCarry"] = nil
end

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

-- ===================================================================
-- 4. ESP MODULE
-- ===================================================================
local ESP = {
    Enabled = true,
    Billboards = {},
    Connection = nil
}

function ESP.init(cfg)
    Config = cfg
    ESP.setupVisuals()
end

function ESP.createBillboard(part, tierName, color)
    if part:FindFirstChild("LuxuryXHUB_ESP") then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "LuxuryXHUB_ESP"
    billboard.Adornee = part
    billboard.Size = UDim2.new(0, 180, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.55, 0)
    title.BackgroundTransparency = 1
    title.Text = "🥚 " .. string.upper(tierName)
    title.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.Parent = frame

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.Position = UDim2.new(0, 0, 0.55, 0)
    distLabel.Size = UDim2.new(1, 0, 0.45, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "... studs"
    distLabel.TextColor3 = Color3.fromRGB(200, 205, 220)
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 11
    distLabel.Parent = frame

    billboard.Parent = part
    table.insert(ESP.Billboards, {
        Part = part,
        DistLabel = distLabel,
        Billboard = billboard
    })
end

function ESP.setupVisuals()
    local spawnParts = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("SpawnParts")
    if not spawnParts then return end

    for _, tierFolder in ipairs(spawnParts:GetChildren()) do
        local tierName = tierFolder.Name
        local color = (Config and Config.TIER_COLORS[tierName]) or Color3.fromRGB(255, 255, 255)

        for _, part in ipairs(tierFolder:GetChildren()) do
            if part:IsA("BasePart") then
                ESP.createBillboard(part, tierName, color)
            end
        end
    end

    if not ESP.Connection then
        ESP.Connection = RunService.RenderStepped:Connect(function()
            if not ESP.Enabled then return end
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local rootPos = root.Position
            for _, item in ipairs(ESP.Billboards) do
                if item.Part and item.Part.Parent and item.DistLabel then
                    local dist = math.floor((item.Part.Position - rootPos).Magnitude)
                    item.DistLabel.Text = dist .. " studs"
                end
            end
        end)
    end
end

function ESP.setEnabled(state)
    ESP.Enabled = state
    for _, item in ipairs(ESP.Billboards) do
        if item.Billboard then
            item.Billboard.Enabled = state
        end
    end
end

function ESP.destroy()
    if ESP.Connection then
        ESP.Connection:Disconnect()
        ESP.Connection = nil
    end
    for _, item in ipairs(ESP.Billboards) do
        if item.Billboard then
            item.Billboard:Destroy()
        end
    end
    ESP.Billboards = {}
end

-- ===================================================================
-- 5. UI MODULE
-- ===================================================================
local UI = {
    ScreenGui = nil,
    ToggleGui = nil,
    MainFrame = nil
}

local function getGuiParent()
    local success, hui = pcall(function() return gethui() end)
    if success and hui then return hui end
    local success2, _ = pcall(function() return CoreGui:GetChildren() end)
    if success2 then return CoreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

function UI.init(cfg, farmRef, espRef, remsRef)
    Config = cfg
    Farm = farmRef
    ESP = espRef
    Remotes = remsRef
    UI.build()
end

function UI.build()
    local parent = getGuiParent()
    local old = parent:FindFirstChild("LuxuryXHUB_PullAnEgg")
    if old then old:Destroy() end
    local oldToggle = parent:FindFirstChild("LuxuryXHUB_FloatingBtn")
    if oldToggle then oldToggle:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LuxuryXHUB_PullAnEgg"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 680, 0, 460)
    main.Position = UDim2.new(0.5, -340, 0.5, -230)
    main.BackgroundColor3 = Color3.fromRGB(23, 23, 23)
    main.BackgroundTransparency = 0.15
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 16)
    mainCorner.Parent = main

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(45, 45, 45)
    mainStroke.Transparency = 0.5
    mainStroke.Thickness = 1
    mainStroke.Parent = main

    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name = "LuxuryXHUB_FloatingBtn"
    toggleGui.ResetOnSpawn = false
    toggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local floatBtn = Instance.new("TextButton")
    floatBtn.Name = "OpenButton"
    floatBtn.Size = UDim2.new(0, 52, 0, 52)
    floatBtn.Position = UDim2.new(0, 24, 0.5, -26)
    floatBtn.BackgroundColor3 = Color3.fromRGB(23, 23, 23)
    floatBtn.Text = "🐾"
    floatBtn.TextSize = 22
    floatBtn.Parent = toggleGui

    local floatCorner = Instance.new("UICorner")
    floatCorner.CornerRadius = UDim.new(0, 26)
    floatCorner.Parent = floatBtn

    local floatStroke = Instance.new("UIStroke")
    floatStroke.Color = Color3.fromRGB(255, 180, 0)
    floatStroke.Thickness = 1.5
    floatStroke.Parent = floatBtn

    local function toggleUI()
        main.Visible = not main.Visible
        if main.Visible then
            floatBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
            floatBtn.TextColor3 = Color3.fromRGB(14, 14, 14)
        else
            floatBtn.BackgroundColor3 = Color3.fromRGB(23, 23, 23)
            floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    floatBtn.MouseButton1Click:Connect(toggleUI)

    local floatDragging, floatDragInput, floatStart, floatPos
    floatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            floatDragging = true
            floatStart = input.Position
            floatPos = floatBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then floatDragging = false end
            end)
        end
    end)

    floatBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            floatDragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == floatDragInput and floatDragging then
            local delta = input.Position - floatStart
            floatBtn.Position = UDim2.new(floatPos.X.Scale, floatPos.X.Offset + delta.X, floatPos.Y.Scale, floatPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and (input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl) then
            toggleUI()
        end
    end)

    local topHeader = Instance.new("Frame")
    topHeader.Name = "TopHeader"
    topHeader.Size = UDim2.new(1, 0, 0, 48)
    topHeader.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    topHeader.BorderSizePixel = 0
    topHeader.Parent = main

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Position = UDim2.new(0, 16, 0, 0)
    titleLabel.Size = UDim2.new(0, 180, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "LUXURY<font color=\"#FFB400\">HUB</font>"
    titleLabel.RichText = true
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = topHeader

    local badgeLabel = Instance.new("TextLabel")
    badgeLabel.Position = UDim2.new(0, 140, 0.5, -10)
    badgeLabel.Size = UDim2.new(0, 88, 0, 20)
    badgeLabel.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
    badgeLabel.Text = "PULL AN EGG"
    badgeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    badgeLabel.Font = Enum.Font.GothamBold
    badgeLabel.TextSize = 9
    badgeLabel.Parent = topHeader

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 6)
    badgeCorner.Parent = badgeLabel

    local closeBtn = Instance.new("TextButton")
    closeBtn.Position = UDim2.new(1, -38, 0.5, -13)
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.Parent = topHeader

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
        floatBtn.BackgroundColor3 = Color3.fromRGB(23, 23, 23)
        floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    local dragging, dragInput, dragStart, startPos
    topHeader.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    topHeader.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local ribbonFrame = Instance.new("Frame")
    ribbonFrame.Name = "RibbonBar"
    ribbonFrame.Position = UDim2.new(0, 0, 0, 48)
    ribbonFrame.Size = UDim2.new(1, 0, 0, 42)
    ribbonFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    ribbonFrame.BorderSizePixel = 0
    ribbonFrame.Parent = main

    local ribbonLayout = Instance.new("UIListLayout")
    ribbonLayout.FillDirection = Enum.FillDirection.Horizontal
    ribbonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    ribbonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ribbonLayout.Padding = UDim.new(0, 6)
    ribbonLayout.Parent = ribbonFrame

    local ribbonPadding = Instance.new("UIPadding")
    ribbonPadding.PaddingLeft = UDim.new(0, 12)
    ribbonPadding.PaddingTop = UDim.new(0, 6)
    ribbonPadding.Parent = ribbonFrame

    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Position = UDim2.new(0, 0, 0, 90)
    contentFrame.Size = UDim2.new(1, 0, 1, -90)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = main

    local tabs = {}
    local tabButtons = {}

    local function createTab(name, icon)
        local isFirst = (#tabButtons == 0)

        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0, 130, 0, 30)
        tabBtn.BackgroundColor3 = isFirst and Color3.fromRGB(255, 180, 0) or Color3.fromRGB(31, 31, 31)
        tabBtn.Text = icon .. " " .. name
        tabBtn.TextColor3 = isFirst and Color3.fromRGB(14, 14, 14) or Color3.fromRGB(180, 180, 180)
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.TextSize = 12
        tabBtn.Parent = ribbonFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = tabBtn

        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, -28, 1, -20)
        page.Position = UDim2.new(0, 14, 0, 10)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = Color3.fromRGB(255, 180, 0)
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        page.Visible = isFirst
        page.Parent = contentFrame

        local pageList = Instance.new("UIListLayout")
        pageList.Padding = UDim.new(0, 12)
        pageList.SortOrder = Enum.SortOrder.LayoutOrder
        pageList.Parent = page

        tabs[name] = page
        table.insert(tabButtons, { Button = tabBtn, Page = page, Name = name })

        tabBtn.MouseButton1Click:Connect(function()
            for _, tb in ipairs(tabButtons) do
                local active = (tb.Name == name)
                tb.Page.Visible = active
                tb.Button.BackgroundColor3 = active and Color3.fromRGB(255, 180, 0) or Color3.fromRGB(31, 31, 31)
                tb.Button.TextColor3 = active and Color3.fromRGB(14, 14, 14) or Color3.fromRGB(180, 180, 180)
            end
        end)

        return page
    end

    local function createPanelSection(page, sectionTitle)
        local outerCard = Instance.new("Frame")
        outerCard.Size = UDim2.new(1, 0, 0, 0)
        outerCard.AutomaticSize = Enum.AutomaticSize.Y
        outerCard.BackgroundColor3 = Color3.fromRGB(23, 23, 23)
        outerCard.BorderSizePixel = 0
        outerCard.Parent = page

        local outerCorner = Instance.new("UICorner")
        outerCorner.CornerRadius = UDim.new(0, 16)
        outerCorner.Parent = outerCard

        local outerStroke = Instance.new("UIStroke")
        outerStroke.Color = Color3.fromRGB(40, 40, 40)
        outerStroke.Thickness = 1
        outerStroke.Parent = outerCard

        local outerLayout = Instance.new("UIListLayout")
        outerLayout.Padding = UDim.new(0, 8)
        outerLayout.SortOrder = Enum.SortOrder.LayoutOrder
        outerLayout.Parent = outerCard

        local outerPadding = Instance.new("UIPadding")
        outerPadding.PaddingTop = UDim.new(0, 12)
        outerPadding.PaddingBottom = UDim.new(0, 12)
        outerPadding.PaddingLeft = UDim.new(0, 12)
        outerPadding.PaddingRight = UDim.new(0, 12)
        outerPadding.Parent = outerCard

        local headerLabel = Instance.new("TextLabel")
        headerLabel.Size = UDim2.new(1, 0, 0, 20)
        headerLabel.BackgroundTransparency = 1
        headerLabel.Text = sectionTitle:upper()
        headerLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
        headerLabel.Font = Enum.Font.GothamBold
        headerLabel.TextSize = 11
        headerLabel.TextXAlignment = Enum.TextXAlignment.Left
        headerLabel.Parent = outerCard

        return outerCard
    end

    local function createToggleCard(outerSection, labelText, defaultState, onToggle)
        local innerCard = Instance.new("Frame")
        innerCard.Size = UDim2.new(1, 0, 0, 42)
        innerCard.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
        innerCard.BorderSizePixel = 0
        innerCard.Parent = outerSection

        local innerCorner = Instance.new("UICorner")
        innerCorner.CornerRadius = UDim.new(0, 10)
        innerCorner.Parent = innerCard

        local innerStroke = Instance.new("UIStroke")
        innerStroke.Color = Color3.fromRGB(45, 45, 45)
        innerStroke.Thickness = 1
        innerStroke.Parent = innerCard

        local label = Instance.new("TextLabel")
        label.Position = UDim2.new(0, 12, 0, 0)
        label.Size = UDim2.new(1, -70, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(230, 230, 230)
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = innerCard

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Position = UDim2.new(1, -52, 0.5, -11)
        toggleBtn.Size = UDim2.new(0, 42, 0, 22)
        toggleBtn.BackgroundColor3 = defaultState and Color3.fromRGB(255, 180, 0) or Color3.fromRGB(45, 45, 45)
        toggleBtn.Text = defaultState and "ON" or "OFF"
        toggleBtn.TextColor3 = defaultState and Color3.fromRGB(14, 14, 14) or Color3.fromRGB(160, 160, 160)
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.TextSize = 10
        toggleBtn.Parent = innerCard

        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 11)
        toggleCorner.Parent = toggleBtn

        local state = defaultState
        toggleBtn.MouseButton1Click:Connect(function()
            state = not state
            toggleBtn.BackgroundColor3 = state and Color3.fromRGB(255, 180, 0) or Color3.fromRGB(45, 45, 45)
            toggleBtn.TextColor3 = state and Color3.fromRGB(14, 14, 14) or Color3.fromRGB(160, 160, 160)
            toggleBtn.Text = state and "ON" or "OFF"
            if onToggle then onToggle(state) end
        end)

        return innerCard
    end

    local function createButtonCard(outerSection, labelText, btnColor, onClick)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 38)
        btn.BackgroundColor3 = btnColor or Color3.fromRGB(31, 31, 31)
        btn.Text = labelText
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.Parent = outerSection

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = btn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(50, 50, 50)
        btnStroke.Thickness = 1
        btnStroke.Parent = btn

        btn.MouseButton1Click:Connect(function()
            if onClick then onClick() end
        end)
        return btn
    end

    -- Tab 1: Auto Farm
    local farmPage = createTab("Auto Farm", "🌾")

    local mainFarmSec = createPanelSection(farmPage, "Core Automation")
    createToggleCard(mainFarmSec, "Auto Train (Activate Dumbbell)", Config.AutoTrain, function(s)
        Config.AutoTrain = s
        if s then Farm.startAutoTrain() else Farm.stopAutoTrain() end
    end)
    createToggleCard(mainFarmSec, "Auto Sell (Sell All Friends)", Config.AutoSell, function(s)
        Config.AutoSell = s
        if s then Farm.startAutoSell() else Farm.stopAutoSell() end
    end)
    createToggleCard(mainFarmSec, "Auto Rebirth", Config.AutoRebirth, function(s)
        Config.AutoRebirth = s
        if s then Farm.startAutoRebirth() else Farm.stopAutoRebirth() end
    end)

    local upgradeSec = createPanelSection(farmPage, "Upgrades & Progression")
    createToggleCard(upgradeSec, "Auto Buy Dumbbells", Config.AutoBuyDumbell, function(s)
        Config.AutoBuyDumbell = s
        if s then Farm.startAutoBuyDumbell() else Farm.stopAutoBuyDumbell() end
    end)
    createToggleCard(upgradeSec, "Auto Upgrade Carry Limit", Config.AutoUpgradeCarry, function(s)
        Config.AutoUpgradeCarry = s
        if s then Farm.startAutoUpgradeCarry() else Farm.stopAutoUpgradeCarry() end
    end)
    createToggleCard(upgradeSec, "Auto Pull Egg (Target Tier)", Config.AutoPullEgg, function(s)
        Config.AutoPullEgg = s
        if s then Farm.startAutoPullEgg() else Farm.stopAutoPullEgg() end
    end)

    local safetySec = createPanelSection(farmPage, "Safety & Combat")
    createToggleCard(safetySec, "Safe Fly / Hover (Dodge Boss)", Config.SafeHover, function(s)
        Config.SafeHover = s
        if not s then
            Farm.setFloat(false)
            Farm.setNoclip(false)
        end
    end)
    createToggleCard(safetySec, "Auto Revive (Instant Respawn)", Config.AutoRevive, function(s)
        Config.AutoRevive = s
    end)

    -- Tab 2: Eggs & ESP
    local eggPage = createTab("Eggs & ESP", "🥚")

    local espSec = createPanelSection(eggPage, "Visual Tracking")
    createToggleCard(espSec, "Egg 3D Billboard ESP", Config.EggESP, function(s)
        Config.EggESP = s
        ESP.setEnabled(s)
    end)

    local tpSec = createPanelSection(eggPage, "Teleport to Egg Tier")
    for _, tier in ipairs(Config.TIERS) do
        createButtonCard(tpSec, "📍 Teleport to Tier: " .. tier, Color3.fromRGB(31, 31, 31), function()
            Config.TargetEggTier = tier
            Farm.teleportToTier(tier)
        end)
    end

    -- Tab 3: Misc & Rewards
    local miscPage = createTab("Misc", "⚙️")

    local rewardSec = createPanelSection(miscPage, "Automated Rewards")
    createButtonCard(rewardSec, "🎁 Claim Daily & Group Rewards", Color3.fromRGB(31, 31, 31), function()
        Remotes.claimDailyReward()
        Remotes.claimGroupReward()
    end)
    createButtonCard(rewardSec, "💰 Sell All Friends Once (Manual)", Color3.fromRGB(31, 31, 31), function()
        Remotes.sellAll()
    end)

    local navSec = createPanelSection(miscPage, "Quick Teleports")
    createButtonCard(navSec, "🏠 Teleport to Spawn Point", Color3.fromRGB(31, 31, 31), function()
        Farm.teleportToSpawn()
    end)
    createButtonCard(navSec, "🛒 Teleport to Sell Shop", Color3.fromRGB(31, 31, 31), function()
        Farm.teleportToShop("Sell")
    end)
    createButtonCard(navSec, "⚡ Teleport to Strength Shop", Color3.fromRGB(31, 31, 31), function()
        Farm.teleportToShop("ShopSpeed")
    end)
    createButtonCard(navSec, "🎒 Teleport to Carry Shop", Color3.fromRGB(31, 31, 31), function()
        Farm.teleportToShop("ShopCarry")
    end)

    screenGui.Parent = parent
    toggleGui.Parent = parent
    UI.ScreenGui = screenGui
    UI.ToggleGui = toggleGui
    UI.MainFrame = main
end

function UI.destroy()
    if UI.ScreenGui then UI.ScreenGui:Destroy() end
    if UI.ToggleGui then UI.ToggleGui:Destroy() end
end

-- ===================================================================
-- 6. APPLICATION INITIALIZATION (BOOTSTRAP)
-- ===================================================================
local function startSuite()
    print("[LuxuryXHUB] Initializing Pull An Egg Module...")

    -- Initialize core logic
    Farm.init(Config, Remotes)
    ESP.init(Config)
    UI.init(Config, Farm, ESP, Remotes)

    -- Anti-AFK Protection
    LocalPlayer.Idled:Connect(function()
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        Remotes.resetAFK()
    end)

    -- Auto Claim Initial Rewards
    task.spawn(function()
        task.wait(2)
        Remotes.claimDailyReward()
        Remotes.claimGroupReward()
    end)

    -- Clear previous instance
    if getgenv().LuxuryXHUB_PullAnEgg and typeof(getgenv().LuxuryXHUB_PullAnEgg.Unload) == "function" then
        pcall(function() getgenv().LuxuryXHUB_PullAnEgg.Unload() end)
    end

    local Runtime = {
        Unload = function()
            Farm.stopAutoTrain()
            Farm.stopAutoSell()
            Farm.stopAutoRebirth()
            Farm.stopAutoPullEgg()
            ESP.destroy()
            UI.destroy()
            getgenv().LuxuryXHUB_PullAnEgg = nil
            print("[LuxuryXHUB] ♻️ Cleared previous Pull An Egg instance.")
        end
    }
    getgenv().LuxuryXHUB_PullAnEgg = Runtime

    print("[LuxuryXHUB] ✓ Pull An Egg Automation Suite Loaded Successfully!")
end

startSuite()