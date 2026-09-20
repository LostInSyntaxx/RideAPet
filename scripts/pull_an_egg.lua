--[[
╭────────────────────────────────────────────────────────────────────────────────────╮
│  ##       ##     ## ##     ## ##     ## ########  ##    ##                         │
│  ##       ##     ##  ##   ##  ##     ## ##     ##  ##  ##                          │
│  ##       ##     ##   ## ##   ##     ## ##     ##   ####                           │
│  ##       ##     ##    ###    ##     ## ########     ##                            │
│  ##       ##     ##   ## ##   ##     ## ##   ##      ##                            │
│  ##       ##     ##  ##   ##  ##     ## ##    ##     ##                            │
│  ########  #######  ##     ##  #######  ##     ##    ##                            │
│                                                                                    │
│                  LuxuryXHUB — Pull An Egg (Standalone Suite)                       │
│     Auto Train · Auto Sell · Auto Rebirth · Egg ESP · Teleport · Anti-AFK         │
╰────────────────────────────────────────────────────────────────────────────────────╯
]]

-- ── 0. Cleanup Previous Instance (Prevent duplicate execution) ──────
if getgenv().LuxuryXHUB_PullAnEgg and typeof(getgenv().LuxuryXHUB_PullAnEgg.Unload) == "function" then
    pcall(function()
        getgenv().LuxuryXHUB_PullAnEgg.Unload()
    end)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ── Runtime Tracker ─────────────────────────────────────────────────
local Runtime = {
    Connections = {},
    Threads = {},
    Instances = {},
    Running = true
}

function Runtime.trackConnection(conn)
    table.insert(Runtime.Connections, conn)
    return conn
end

-- ── 1. Configuration ───────────────────────────────────────────────
local Config = {
    AutoTrain       = false,
    TrainInterval   = 0.1,

    AutoSell        = false,
    SellInterval    = 5,

    AutoRebirth     = false,
    RebirthInterval = 2,

    AutoBuyDumbell  = false,
    AutoUpgradeCarry= false,

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

-- ── 2. Remotes Accessor ─────────────────────────────────────────────
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

function Remotes.fire(name, ...)
    local folder = getRemotesFolder()
    if folder then
        local r = folder:FindFirstChild(name)
        if r and r:IsA("RemoteEvent") then
            r:FireServer(...)
            return true
        end
    end
    return false
end

function Remotes.invoke(name, ...)
    local folder = getRemotesFolder()
    if folder then
        local r = folder:FindFirstChild(name)
        if r and r:IsA("RemoteFunction") then
            return r:InvokeServer(...)
        end
    end
    return nil
end

function Remotes.buyDumbell(nameOrIndex)
    local dumbellId = typeof(nameOrIndex) == "number" and ("Dumbell_" .. nameOrIndex) or tostring(nameOrIndex)
    return Remotes.fire("Buy Dumbell", dumbellId)
end

-- ── 3. Farm & Movement Engine ───────────────────────────────────────
local Farm = { Threads = {} }
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
        Runtime.trackConnection(noclipConnection)
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
        local h = Config.FlyHeight or 16
        Farm.teleportTo(part.CFrame, h)
        if Config.SafeHover then
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
    end
end

function Farm.teleportToShop(shopName)
    local shops = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("ShopStands")
    if shops then
        local target = shops:FindFirstChild(shopName)
        if target then
            local root = target:FindFirstChildWhichIsA("BasePart", true)
            if root then Farm.teleportTo(root.CFrame) end
        end
    end
end

function Farm.startAutoTrain()
    if Farm.Threads["AutoTrain"] then return end
    Farm.Threads["AutoTrain"] = task.spawn(function()
        while Runtime.Running and Config.AutoTrain do
            Remotes.fire("Activate Dumbell")
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
        while Runtime.Running and Config.AutoSell do
            Remotes.fire("Sell All Friends")
            task.wait(Config.SellInterval or 5)
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
        while Runtime.Running and Config.AutoRebirth do
            Remotes.fire("Rebirth")
            task.wait(Config.RebirthInterval or 2)
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
        while Runtime.Running and Config.AutoBuyDumbell do
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

function Farm.startAutoUpgradeCarry()
    if Farm.Threads["AutoUpgradeCarry"] then return end
    Farm.Threads["AutoUpgradeCarry"] = task.spawn(function()
        while Runtime.Running and Config.AutoUpgradeCarry do
            Remotes.fire("Upgrade Carry Limit")
            task.wait(2)
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

        while Runtime.Running and Config.AutoPullEgg do
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
                Remotes.invoke("Strange: Claim Egg", targetTier)
                Remotes.fire("Activate Dumbell")
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

-- ── 4. ESP Engine ───────────────────────────────────────────────────
local ESP = { Billboards = {}, Enabled = true, Connection = nil }

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
    distLabel.Position = UDim2.new(0, 0, 0.55, 0)
    distLabel.Size = UDim2.new(1, 0, 0.45, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "... studs"
    distLabel.TextColor3 = Color3.fromRGB(200, 205, 220)
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 11
    distLabel.Parent = frame

    billboard.Parent = part
    table.insert(ESP.Billboards, { Part = part, DistLabel = distLabel, Billboard = billboard })
end

function ESP.init()
    local spawnParts = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("SpawnParts")
    if not spawnParts then return end

    for _, tierFolder in ipairs(spawnParts:GetChildren()) do
        local tierName = tierFolder.Name
        local color = Config.TIER_COLORS[tierName] or Color3.fromRGB(255, 255, 255)
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
        Runtime.trackConnection(ESP.Connection)
    end
end

function ESP.setEnabled(state)
    ESP.Enabled = state
    for _, item in ipairs(ESP.Billboards) do
        if item.Billboard then item.Billboard.Enabled = state end
    end
end

function ESP.destroy()
    if ESP.Connection then
        ESP.Connection:Disconnect()
        ESP.Connection = nil
    end
    for _, item in ipairs(ESP.Billboards) do
        if item.Billboard then item.Billboard:Destroy() end
    end
    ESP.Billboards = {}
end

-- ── 5. User Interface (GUI) ────────────────────────────────────────
local function getGuiParent()
    local success, hui = pcall(function() return gethui() end)
    if success and hui then return hui end
    local success2, _ = pcall(function() return CoreGui:GetChildren() end)
    if success2 then return CoreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function buildUI()
    local parent = getGuiParent()
    local oldMain = parent:FindFirstChild("LuxuryXHUB_PullAnEgg")
    if oldMain then oldMain:Destroy() end
    local oldToggle = parent:FindFirstChild("LuxuryXHUB_FloatingBtn")
    if oldToggle then oldToggle:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LuxuryXHUB_PullAnEgg"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 580, 0, 390)
    main.Position = UDim2.new(0.5, -290, 0.5, -195)
    main.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = main

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(255, 170, 0)
    mainStroke.Transparency = 0.6
    mainStroke.Thickness = 1.5
    mainStroke.Parent = main

    -- ── Floating Open/Close Toggle Button ────────────────────────────
    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name = "LuxuryXHUB_FloatingBtn"
    toggleGui.ResetOnSpawn = false
    toggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local floatBtn = Instance.new("TextButton")
    floatBtn.Name = "OpenButton"
    floatBtn.Size = UDim2.new(0, 50, 0, 50)
    floatBtn.Position = UDim2.new(0, 20, 0.5, -25)
    floatBtn.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
    floatBtn.Text = "🐾"
    floatBtn.TextSize = 22
    floatBtn.Parent = toggleGui

    local floatCorner = Instance.new("UICorner")
    floatCorner.CornerRadius = UDim.new(0, 25)
    floatCorner.Parent = floatBtn

    local floatStroke = Instance.new("UIStroke")
    floatStroke.Color = Color3.fromRGB(255, 170, 0)
    floatStroke.Thickness = 2
    floatStroke.Parent = floatBtn

    -- Toggle UI visibility helper
    local function toggleUI()
        main.Visible = not main.Visible
        if main.Visible then
            floatBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
            floatBtn.TextColor3 = Color3.fromRGB(16, 18, 26)
        else
            floatBtn.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
            floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    floatBtn.MouseButton1Click:Connect(toggleUI)

    -- Floating Button Draggable
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

    -- Keyboard shortcut (LeftControl or RightControl to toggle UI)
    local keyConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and (input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl) then
            toggleUI()
        end
    end)
    Runtime.trackConnection(keyConn)

    -- ── Header ───────────────────────────────────────────────────────
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 48)
    header.BackgroundColor3 = Color3.fromRGB(22, 25, 36)
    header.BorderSizePixel = 0
    header.Parent = main

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header

    local title = Instance.new("TextLabel")
    title.Position = UDim2.new(0, 16, 0, 0)
    title.Size = UDim2.new(0, 200, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "🐾 LuxuryXHUB"
    title.TextColor3 = Color3.fromRGB(255, 180, 0)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 17
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local badge = Instance.new("TextLabel")
    badge.Position = UDim2.new(0, 175, 0.5, -10)
    badge.Size = UDim2.new(0, 95, 0, 20)
    badge.BackgroundColor3 = Color3.fromRGB(35, 40, 58)
    badge.Text = "Pull An Egg"
    badge.TextColor3 = Color3.fromRGB(200, 220, 255)
    badge.Font = Enum.Font.GothamMedium
    badge.TextSize = 11
    badge.Parent = header

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 6)
    badgeCorner.Parent = badge

    -- Minimize/Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Position = UDim2.new(1, -38, 0.5, -14)
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 13
    closeBtn.Parent = header

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
        floatBtn.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
        floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    -- Draggable MainFrame
    local dragging, dragInput, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    header.InputChanged:Connect(function(input)
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

    -- Navigation
    local nav = Instance.new("Frame")
    nav.Position = UDim2.new(0, 0, 0, 48)
    nav.Size = UDim2.new(0, 150, 1, -48)
    nav.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
    nav.BorderSizePixel = 0
    nav.Parent = main

    local content = Instance.new("Frame")
    content.Position = UDim2.new(0, 150, 0, 48)
    content.Size = UDim2.new(1, -150, 1, -48)
    content.BackgroundTransparency = 1
    content.Parent = main

    local tabs = {}
    local tabButtons = {}

    local function createTab(name, icon)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, -16, 0, 36)
        tabBtn.Position = UDim2.new(0, 8, 0, 12 + (#tabButtons * 44))
        tabBtn.BackgroundColor3 = (#tabButtons == 0) and Color3.fromRGB(255, 170, 0) or Color3.fromRGB(22, 25, 36)
        tabBtn.Text = icon .. "  " .. name
        tabBtn.TextColor3 = (#tabButtons == 0) and Color3.fromRGB(16, 18, 26) or Color3.fromRGB(220, 225, 235)
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.TextSize = 13
        tabBtn.Parent = nav

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = tabBtn

        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, -24, 1, -24)
        page.Position = UDim2.new(0, 12, 0, 12)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.Visible = (#tabButtons == 0)
        page.Parent = content

        local pageList = Instance.new("UIListLayout")
        pageList.Padding = UDim.new(0, 10)
        pageList.SortOrder = Enum.SortOrder.LayoutOrder
        pageList.Parent = page

        tabs[name] = page
        table.insert(tabButtons, { Button = tabBtn, Page = page, Name = name })

        tabBtn.MouseButton1Click:Connect(function()
            for _, tb in ipairs(tabButtons) do
                local isActive = (tb.Name == name)
                tb.Page.Visible = isActive
                tb.Button.BackgroundColor3 = isActive and Color3.fromRGB(255, 170, 0) or Color3.fromRGB(22, 25, 36)
                tb.Button.TextColor3 = isActive and Color3.fromRGB(16, 18, 26) or Color3.fromRGB(220, 225, 235)
            end
        end)
        return page
    end

    local function createToggle(page, labelText, defaultState, onToggle)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -8, 0, 46)
        card.BackgroundColor3 = Color3.fromRGB(24, 27, 39)
        card.BorderSizePixel = 0
        card.Parent = page

        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 8)
        cardCorner.Parent = card

        local label = Instance.new("TextLabel")
        label.Position = UDim2.new(0, 14, 0, 0)
        label.Size = UDim2.new(1, -80, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(240, 242, 245)
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = card

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Position = UDim2.new(1, -60, 0.5, -13)
        toggleBtn.Size = UDim2.new(0, 48, 0, 26)
        toggleBtn.BackgroundColor3 = defaultState and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(50, 55, 70)
        toggleBtn.Text = defaultState and "ON" or "OFF"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.TextSize = 11
        toggleBtn.Parent = card

        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 13)
        toggleCorner.Parent = toggleBtn

        local state = defaultState
        toggleBtn.MouseButton1Click:Connect(function()
            state = not state
            toggleBtn.BackgroundColor3 = state and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(50, 55, 70)
            toggleBtn.Text = state and "ON" or "OFF"
            if onToggle then onToggle(state) end
        end)
        return card
    end

    local function createButton(page, labelText, btnColor, onClick)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 40)
        btn.BackgroundColor3 = btnColor or Color3.fromRGB(35, 40, 58)
        btn.Text = labelText
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.Parent = page

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            if onClick then onClick() end
        end)
        return btn
    end

    -- Tab 1: Farm
    local farmPage = createTab("Auto Farm", "🌾")

    createToggle(farmPage, "Auto Train (Activate Dumbell)", Config.AutoTrain, function(s)
        Config.AutoTrain = s
        if s then Farm.startAutoTrain() else Farm.stopAutoTrain() end
    end)

    createToggle(farmPage, "Auto Sell (Sell All Friends)", Config.AutoSell, function(s)
        Config.AutoSell = s
        if s then Farm.startAutoSell() else Farm.stopAutoSell() end
    end)

    createToggle(farmPage, "Auto Rebirth", Config.AutoRebirth, function(s)
        Config.AutoRebirth = s
        if s then Farm.startAutoRebirth() else Farm.stopAutoRebirth() end
    end)

    createToggle(farmPage, "💪 Auto Buy Dumbbells (Upgrades)", Config.AutoBuyDumbell, function(s)
        Config.AutoBuyDumbell = s
        if s then Farm.startAutoBuyDumbell() else Farm.stopAutoBuyDumbell() end
    end)

    createToggle(farmPage, "🎒 Auto Upgrade Carry Limit", Config.AutoUpgradeCarry, function(s)
        Config.AutoUpgradeCarry = s
        if s then Farm.startAutoUpgradeCarry() else Farm.stopAutoUpgradeCarry() end
    end)

    createToggle(farmPage, "Auto Pull Egg (Target Tier)", Config.AutoPullEgg, function(s)
        Config.AutoPullEgg = s
        if s then Farm.startAutoPullEgg() else Farm.stopAutoPullEgg() end
    end)

    createToggle(farmPage, "🛡️ Safe Fly / Hover (Dodge Boss)", Config.SafeHover, function(s)
        Config.SafeHover = s
        if not s then
            Farm.setFloat(false)
            Farm.setNoclip(false)
        end
    end)

    -- Tab 2: Eggs & ESP
    local eggPage = createTab("Eggs & ESP", "🥚")

    createToggle(eggPage, "Egg 3D Billboard ESP", Config.EggESP, function(s)
        Config.EggESP = s
        ESP.setEnabled(s)
    end)

    local sectionLabel = Instance.new("TextLabel")
    sectionLabel.Size = UDim2.new(1, -8, 0, 24)
    sectionLabel.BackgroundTransparency = 1
    sectionLabel.Text = "⚡ Teleport to Egg Tiers (Boss-Safe):"
    sectionLabel.TextColor3 = Color3.fromRGB(255, 170, 0)
    sectionLabel.Font = Enum.Font.GothamBold
    sectionLabel.TextSize = 13
    sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    sectionLabel.Parent = eggPage

    for _, tier in ipairs(Config.TIERS) do
        createButton(eggPage, "📍 TP to " .. tier .. " Egg", Color3.fromRGB(24, 27, 39), function()
            Config.TargetEggTier = tier
            Farm.teleportToTier(tier)
        end)
    end

    -- Tab 3: Misc
    local miscPage = createTab("Misc", "⚙️")

    createButton(miscPage, "🎁 Claim All Daily & Group Rewards", Color3.fromRGB(39, 174, 96), function()
        Remotes.fire("Claim Daily Reward")
        Remotes.fire("Claim Group Reward")
    end)

    createButton(miscPage, "💰 Sell All Friends Once", Color3.fromRGB(41, 128, 185), function()
        Remotes.fire("Sell All Friends")
    end)

    createButton(miscPage, "🏠 Teleport to Spawn", Color3.fromRGB(35, 40, 58), function()
        Farm.teleportToSpawn()
    end)

    createButton(miscPage, "🛒 Teleport to Sell Shop", Color3.fromRGB(35, 40, 58), function()
        Farm.teleportToShop("Sell")
    end)

    createButton(miscPage, "⚡ Teleport to Strength Shop", Color3.fromRGB(35, 40, 58), function()
        Farm.teleportToShop("ShopSpeed")
    end)

    createButton(miscPage, "🎒 Teleport to Carry Shop", Color3.fromRGB(35, 40, 58), function()
        Farm.teleportToShop("ShopCarry")
    end)

    createButton(miscPage, "❌ Unload Script (Close All)", Color3.fromRGB(192, 57, 43), function()
        Runtime.Unload()
    end)

    screenGui.Parent = parent
    toggleGui.Parent = parent
    table.insert(Runtime.Instances, screenGui)
    table.insert(Runtime.Instances, toggleGui)
end

-- ── 6. Anti-AFK & Lifecycle ─────────────────────────────────────────
local afkConn = LocalPlayer.Idled:Connect(function()
    local VirtualUser = game:GetService("VirtualUser")
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    Remotes.fire("AFK Idle Reset Request")
end)
Runtime.trackConnection(afkConn)

-- Auto Claim on Startup
task.spawn(function()
    task.wait(2)
    if Runtime.Running then
        Remotes.fire("Claim Daily Reward")
        Remotes.fire("Claim Group Reward")
    end
end)

-- Initialize ESP & UI
ESP.init()
buildUI()

-- Register Unload handler
function Runtime.Unload()
    Runtime.Running = false
    Config.AutoTrain = false
    Config.AutoSell = false
    Config.AutoRebirth = false
    Config.AutoBuyDumbell = false
    Config.AutoUpgradeCarry = false
    Config.AutoPullEgg = false

    -- Stop all threads
    for _, th in pairs(Farm.Threads) do
        pcall(task.cancel, th)
    end
    Farm.Threads = {}

    -- Disconnect all connections
    for _, conn in ipairs(Runtime.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Runtime.Connections = {}

    -- Clean movement / float / noclip
    Farm.setFloat(false)
    Farm.setNoclip(false)

    -- Clean ESP
    ESP.destroy()

    -- Destroy UI instances
    for _, inst in ipairs(Runtime.Instances) do
        pcall(function() inst:Destroy() end)
    end
    Runtime.Instances = {}

    local parent = getGuiParent()
    local old1 = parent:FindFirstChild("LuxuryXHUB_PullAnEgg")
    if old1 then old1:Destroy() end
    local old2 = parent:FindFirstChild("LuxuryXHUB_FloatingBtn")
    if old2 then old2:Destroy() end

    getgenv().LuxuryXHUB_PullAnEgg = nil
    print("[LuxuryXHUB] ♻️ Previous script instance cleared successfully!")
end

getgenv().LuxuryXHUB_PullAnEgg = Runtime

print("[LuxuryXHUB] ✓ Pull An Egg Suite Loaded Successfully! Press [LeftControl] or click 🐾 to toggle menu.")
