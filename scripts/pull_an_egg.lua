-- LuxuryXHUB — Pull An Egg (Standalone Suite)

-- ── Configuration & Constants ───────────────────────────────────────
-- ⚠️ เปลี่ยน URL ด้านล่างนี้ให้ตรงกับลิงก์ Raw Lua ของคุณเองสำหรับระบบ Rejoin/Server Hop
local SCRIPT_RAW_URL = "https://raw.githubusercontent.com/YourUsername/YourRepo/main/pull_an_egg_2.lua"

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
    SellInterval    = 2,

    AutoRebirth     = false,
    RebirthInterval = 1,

    AutoBuyDumbell  = false,
    AutoUpgradeCarry= false,

    AutoPullEgg     = false,
    TargetEggTier   = "Celestial",
    FlyHeight       = 16,
    SafeHover       = true,

    EggESP          = true,

    -- Universal
    AntiAFK         = true,
    LowGraphics     = false,
    SpeedBoost      = false,
    WalkSpeed       = 100,
    JumpPower       = 80,

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
                task.wait(0.08)
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
        while Runtime.Running and Config.AutoUpgradeCarry do
            Remotes.fire("Upgrade Carry Limit")
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
                        task.wait(0.1)
                    end
                end
                
                pcall(function()
                    Remotes.invoke("Strange: Claim Egg", targetTier)
                end)
                Remotes.fire("Activate Dumbell")
            end
            task.wait(0.1)
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

-- ── Design Tokens ──────────────────────────────────────────────────
local C = {
    BG0       = Color3.fromRGB(17,  17,  17),
    BG1       = Color3.fromRGB(31,  31,  31),
    BG2       = Color3.fromRGB(36,  36,  36),
    BG3       = Color3.fromRGB(26,  26,  26),
    Border0   = Color3.fromRGB(50,  50,  50),
    Border1   = Color3.fromRGB(45,  45,  45),
    Border2   = Color3.fromRGB(38,  38,  38),
    Gold      = Color3.fromRGB(255, 185,  50),
    GoldDim   = Color3.fromRGB(60,  42,   8),
    GoldText  = Color3.fromRGB(255, 200,  80),
    Green     = Color3.fromRGB( 52, 211, 153),
    GreenDim  = Color3.fromRGB( 15,  60,  40),
    Red       = Color3.fromRGB(239,  68,  68),
    Blue      = Color3.fromRGB( 59, 130, 246),
    Purple    = Color3.fromRGB(139,  92, 246),
    TextPri   = Color3.fromRGB(230, 230, 230),
    TextSec   = Color3.fromRGB(130, 130, 130),
    TextMuted = Color3.fromRGB( 70,  70,  70),
}

local TW = game:GetService("TweenService")
local function tw(obj, props, t)
    TW:Create(obj, TweenInfo.new(t or 0.14, Enum.EasingStyle.Quad), props):Play()
end

local function corner(p, r) local c=Instance.new("UICorner") c.CornerRadius=r or UDim.new(0,12) c.Parent=p return c end
local function stroke(p, col, th)
    local s=Instance.new("UIStroke") s.Color=col or Color3.fromRGB(45,45,45)
    s.Thickness=th or 1 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=p return s
end
local function list(p, pad, dir)
    local l=Instance.new("UIListLayout") l.Padding=UDim.new(0,pad or 8)
    l.SortOrder=Enum.SortOrder.LayoutOrder l.FillDirection=dir or Enum.FillDirection.Horizontal l.Parent=p return l
end
local function pad(p, x, y)
    local u=Instance.new("UIPadding") u.PaddingLeft=UDim.new(0,x or 12) u.PaddingRight=UDim.new(0,x or 12)
    u.PaddingTop=UDim.new(0,y or 10) u.PaddingBottom=UDim.new(0,y or 10) u.Parent=p return u
end

local function buildUI()
    local parent = getGuiParent()
    local old1 = parent:FindFirstChild("LuxuryXHUB_PullAnEgg")
    if old1 then old1:Destroy() end
    local old2 = parent:FindFirstChild("LuxuryXHUB_FloatingBtn")
    if old2 then old2:Destroy() end

    -- ── ScreenGuis ───────────────────────────────────────────────
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LuxuryXHUB_PullAnEgg"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999

    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name = "LuxuryXHUB_FloatingBtn"
    toggleGui.ResetOnSpawn = false
    toggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    toggleGui.DisplayOrder = 1000

    -- ── Floating Button ──────────────────────────────────────────
    local floatOuter = Instance.new("Frame")
    floatOuter.Size = UDim2.new(0, 52, 0, 52)
    floatOuter.Position = UDim2.new(0, 16, 0.5, -26)
    floatOuter.BackgroundColor3 = C.BG1
    floatOuter.BorderSizePixel = 0
    floatOuter.Parent = toggleGui
    corner(floatOuter, UDim.new(0, 14))
    stroke(floatOuter, C.Gold, 1.5)

    local floatBtn = Instance.new("TextButton")
    floatBtn.Name = "OpenButton"
    floatBtn.Size = UDim2.new(1, 0, 1, 0)
    floatBtn.BackgroundTransparency = 1
    floatBtn.Text = "🐾"
    floatBtn.TextSize = 24
    floatBtn.Font = Enum.Font.GothamBold
    floatBtn.Parent = floatOuter

    local floatDragging, floatDragInput, floatStart, floatPos
    floatOuter.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            floatDragging = true; floatStart = i.Position; floatPos = floatOuter.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then floatDragging = false end end)
        end
    end)
    floatOuter.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then floatDragInput = i end
    end)

    -- ── Main Window Shell ─────────────────────────────────────────
    local shell = Instance.new("Frame")
    shell.Name = "MainFrame"
    shell.Size = UDim2.new(0, 660, 0, 460)
    shell.Position = UDim2.new(0.5, -330, 0.5, -230)
    shell.BackgroundColor3 = C.BG0
    shell.BorderSizePixel = 0
    shell.ClipsDescendants = true
    shell.Parent = screenGui
    corner(shell, UDim.new(0, 16))
    stroke(shell, C.Border0, 1)

    -- Gold top accent stripe
    local stripe = Instance.new("Frame")
    stripe.Size = UDim2.new(1, 0, 0, 2)
    stripe.BackgroundColor3 = C.Gold
    stripe.BorderSizePixel = 0
    stripe.ZIndex = 3
    stripe.Parent = shell

    -- Inner surface
    local main = Instance.new("Frame")
    main.Size = UDim2.new(1, -2, 1, -2)
    main.Position = UDim2.new(0, 1, 0, 1)
    main.BackgroundColor3 = C.BG1
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = shell
    corner(main, UDim.new(0, 15))

    -- ── Title Bar ─────────────────────────────────────────────────
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 56)
    titleBar.BackgroundColor3 = C.BG0
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main

    -- Logo icon
    local logoBox = Instance.new("Frame")
    logoBox.Position = UDim2.new(0, 14, 0.5, -16)
    logoBox.Size = UDim2.new(0, 32, 0, 32)
    logoBox.BackgroundColor3 = C.GoldDim
    logoBox.BorderSizePixel = 0
    logoBox.Parent = titleBar
    corner(logoBox, UDim.new(0, 8))

    local logoTxt = Instance.new("TextLabel")
    logoTxt.Size = UDim2.new(1, 0, 1, 0)
    logoTxt.BackgroundTransparency = 1
    logoTxt.Text = "🐾"
    logoTxt.TextSize = 16
    logoTxt.Font = Enum.Font.GothamBold
    logoTxt.Parent = logoBox

    -- Title + subtitle
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Position = UDim2.new(0, 54, 0, 10)
    titleLbl.Size = UDim2.new(0, 200, 0, 20)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "LuxuryXHUB"
    titleLbl.TextColor3 = C.GoldText
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 16
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = titleBar

    local subLbl = Instance.new("TextLabel")
    subLbl.Position = UDim2.new(0, 54, 0, 32)
    subLbl.Size = UDim2.new(0, 240, 0, 14)
    subLbl.BackgroundTransparency = 1
    subLbl.Text = "Pull An Egg  ·  Automation Suite"
    subLbl.TextColor3 = C.TextMuted
    subLbl.Font = Enum.Font.Gotham
    subLbl.TextSize = 10
    subLbl.TextXAlignment = Enum.TextXAlignment.Left
    subLbl.Parent = titleBar

    -- Window control buttons
    local function winBtn(col, sym, xOff)
        local b = Instance.new("TextButton")
        b.Position = UDim2.new(1, xOff, 0.5, -13)
        b.Size = UDim2.new(0, 26, 0, 26)
        b.BackgroundColor3 = col
        b.Text = sym
        b.TextColor3 = Color3.fromRGB(255,255,255)
        b.TextSize = 11
        b.Font = Enum.Font.GothamBold
        b.AutoButtonColor = false
        b.Parent = titleBar
        corner(b, UDim.new(0, 6))
        b.MouseEnter:Connect(function() tw(b, {BackgroundTransparency=0.3}) end)
        b.MouseLeave:Connect(function() tw(b, {BackgroundTransparency=0}) end)
        return b
    end
    local closeBtn = winBtn(C.Red,                    "✕", -38)
    local minBtn   = winBtn(Color3.fromRGB(55,55,55), "─", -72)

    -- Toggle + drag
    local function toggleUI()
        shell.Visible = not shell.Visible
        tw(floatOuter, {BackgroundColor3 = shell.Visible and C.GoldDim or C.BG1})
    end
    floatBtn.MouseButton1Click:Connect(toggleUI)
    closeBtn.MouseButton1Click:Connect(function() shell.Visible = false tw(floatOuter,{BackgroundColor3=C.BG1}) end)
    minBtn.MouseButton1Click:Connect(function()   shell.Visible = false tw(floatOuter,{BackgroundColor3=C.BG1}) end)

    local kc = UserInputService.InputBegan:Connect(function(i, gpe)
        if not gpe and (i.KeyCode == Enum.KeyCode.LeftControl or i.KeyCode == Enum.KeyCode.RightControl) then toggleUI() end
    end)
    Runtime.trackConnection(kc)

    local dragging, dragInput, dragStart, startPos
    titleBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = i.Position
            startPos = shell.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    titleBar.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then dragInput=i end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i == floatDragInput and floatDragging then
            local d = i.Position - floatStart
            floatOuter.Position = UDim2.new(floatPos.X.Scale, floatPos.X.Offset+d.X, floatPos.Y.Scale, floatPos.Y.Offset+d.Y)
        end
        if i == dragInput and dragging then
            local d = i.Position - dragStart
            shell.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end)

    -- Title bar bottom rule
    local tbRule = Instance.new("Frame")
    tbRule.Position = UDim2.new(0,0,1,-1)
    tbRule.Size = UDim2.new(1,0,0,1)
    tbRule.BackgroundColor3 = C.Border0
    tbRule.BorderSizePixel = 0
    tbRule.Parent = titleBar

    -- ── Ribbon Tab Bar ────────────────────────────────────────────
    local ribbon = Instance.new("Frame")
    ribbon.Name = "Ribbon"
    ribbon.Position = UDim2.new(0, 0, 0, 56)
    ribbon.Size = UDim2.new(1, 0, 0, 46)
    ribbon.BackgroundColor3 = C.BG0
    ribbon.BorderSizePixel = 0
    ribbon.Parent = main

    local ribbonRow = Instance.new("Frame")
    ribbonRow.Position = UDim2.new(0, 14, 0, 4)
    ribbonRow.Size = UDim2.new(1, -14, 1, -4)
    ribbonRow.BackgroundTransparency = 1
    ribbonRow.Parent = ribbon
    list(ribbonRow, 4, Enum.FillDirection.Horizontal)

    local ribbonRule = Instance.new("Frame")
    ribbonRule.Position = UDim2.new(0,0,1,-1)
    ribbonRule.Size = UDim2.new(1,0,0,1)
    ribbonRule.BackgroundColor3 = C.Border0
    ribbonRule.BorderSizePixel = 0
    ribbonRule.Parent = ribbon

    -- ── Content Area ──────────────────────────────────────────────
    local contentArea = Instance.new("Frame")
    contentArea.Position = UDim2.new(0, 0, 0, 102)
    contentArea.Size = UDim2.new(1, 0, 1, -102)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = main

    -- ─────────────────────────────────────────────────────────────
    --  COMPONENT BUILDERS
    -- ─────────────────────────────────────────────────────────────

    local function outerCard(parent, h)
        local o = Instance.new("Frame")
        o.Size = UDim2.new(1, 0, 0, h or 66)
        o.BackgroundColor3 = C.BG2
        o.BorderSizePixel = 0
        o.Parent = parent
        corner(o, UDim.new(0, 12))
        stroke(o, C.Border1, 1)
        return o
    end

    local function innerCard(outer, marginX, marginY)
        local mx, my = marginX or 5, marginY or 5
        local i = Instance.new("Frame")
        i.Size = UDim2.new(1, -mx*2, 1, -my*2)
        i.Position = UDim2.new(0, mx, 0, my)
        i.BackgroundColor3 = C.BG3
        i.BorderSizePixel = 0
        i.Parent = outer
        corner(i, UDim.new(0, 8))
        stroke(i, C.Border2, 1)
        return i
    end

    local function createToggle(page, labelText, defaultState, onToggle)
        local o = outerCard(page, 62)
        local inn = innerCard(o)

        local dot = Instance.new("Frame")
        dot.Position = UDim2.new(0, 12, 0.5, -4)
        dot.Size = UDim2.new(0, 8, 0, 8)
        dot.BackgroundColor3 = defaultState and C.Green or C.TextMuted
        dot.BorderSizePixel = 0
        dot.Parent = inn
        corner(dot, UDim.new(1, 0))

        local lbl = Instance.new("TextLabel")
        lbl.Position = UDim2.new(0, 28, 0, 0)
        lbl.Size = UDim2.new(1, -96, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.TextColor3 = C.TextPri
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Parent = inn

        local track = Instance.new("Frame")
        track.Position = UDim2.new(1, -60, 0.5, -12)
        track.Size = UDim2.new(0, 48, 0, 24)
        track.BackgroundColor3 = defaultState and C.GreenDim or C.BG0
        track.BorderSizePixel = 0
        track.Parent = inn
        corner(track, UDim.new(1, 0))
        local trackS = stroke(track, defaultState and C.Green or C.Border1, 1)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = defaultState and UDim2.new(1, -20, 0.5, -8) or UDim2.new(0, 4, 0.5, -8)
        knob.BackgroundColor3 = defaultState and C.Green or C.TextMuted
        knob.BorderSizePixel = 0
        knob.Parent = track
        corner(knob, UDim.new(1, 0))

        local hit = Instance.new("TextButton")
        hit.Size = UDim2.new(1, 0, 1, 0)
        hit.BackgroundTransparency = 1
        hit.Text = ""
        hit.Parent = inn

        local state = defaultState
        hit.MouseButton1Click:Connect(function()
            state = not state
            tw(knob, {Position = state and UDim2.new(1,-20,0.5,-8) or UDim2.new(0,4,0.5,-8), BackgroundColor3 = state and C.Green or C.TextMuted})
            tw(track, {BackgroundColor3 = state and C.GreenDim or C.BG0})
            tw(trackS, {Color = state and C.Green or C.Border1})
            tw(dot,   {BackgroundColor3 = state and C.Green or C.TextMuted})
            if onToggle then onToggle(state) end
        end)
        hit.MouseEnter:Connect(function() tw(o, {BackgroundColor3 = Color3.fromRGB(42,42,42)}) end)
        hit.MouseLeave:Connect(function() tw(o, {BackgroundColor3 = C.BG2}) end)
        return o
    end

    local function createButton(page, labelText, accentCol, onClick)
        local o = outerCard(page, 52)
        local inn = Instance.new("TextButton")
        inn.Size = UDim2.new(1,-10,1,-10)
        inn.Position = UDim2.new(0,5,0,5)
        inn.BackgroundColor3 = C.BG3
        inn.Text = ""
        inn.AutoButtonColor = false
        inn.BorderSizePixel = 0
        inn.Parent = o
        corner(inn, UDim.new(0, 8))
        stroke(inn, C.Border2, 1)

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 3, 0.55, 0)
        bar.Position = UDim2.new(0, 10, 0.225, 0)
        bar.BackgroundColor3 = accentCol or C.Gold
        bar.BorderSizePixel = 0
        bar.Parent = inn
        corner(bar, UDim.new(1, 0))

        local lbl = Instance.new("TextLabel")
        lbl.Position = UDim2.new(0, 22, 0, 0)
        lbl.Size = UDim2.new(1, -40, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.TextColor3 = C.TextPri
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Parent = inn

        local arr = Instance.new("TextLabel")
        arr.Position = UDim2.new(1, -26, 0, 0)
        arr.Size = UDim2.new(0, 18, 1, 0)
        arr.BackgroundTransparency = 1
        arr.Text = "›"
        arr.TextColor3 = C.TextMuted
        arr.Font = Enum.Font.GothamBold
        arr.TextSize = 18
        arr.Parent = inn

        inn.MouseEnter:Connect(function()
            tw(inn, {BackgroundColor3 = Color3.fromRGB(38,38,38)})
            tw(lbl, {TextColor3 = accentCol or C.Gold})
            tw(arr, {TextColor3 = accentCol or C.Gold})
        end)
        inn.MouseLeave:Connect(function()
            tw(inn, {BackgroundColor3 = C.BG3})
            tw(lbl, {TextColor3 = C.TextPri})
            tw(arr, {TextColor3 = C.TextMuted})
        end)
        inn.MouseButton1Click:Connect(function() if onClick then onClick() end end)
        return o
    end

    local function sectionLabel(page, text)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 26)
        row.BackgroundTransparency = 1
        row.Parent = page

        local line = Instance.new("Frame")
        line.Position = UDim2.new(0, 0, 0.5, 0)
        line.Size = UDim2.new(1, 0, 0, 1)
        line.BackgroundColor3 = C.Border1
        line.BorderSizePixel = 0
        line.Parent = row

        local bg = Instance.new("Frame")
        bg.BackgroundColor3 = C.BG1
        bg.BorderSizePixel = 0
        bg.Position = UDim2.new(0, 0, 0, 4)
        bg.Size = UDim2.new(0, #text * 7 + 20, 0, 18)
        bg.Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "  " .. text
        lbl.TextColor3 = C.TextSec
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 9
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = bg
        return row
    end

    -- ─────────────────────────────────────────────────────────────
    --  TAB SYSTEM
    -- ─────────────────────────────────────────────────────────────
    local tabs = {}
    local tabBtns = {}

    local function createTab(name, icon, col)
        local isFirst = (#tabBtns == 0)
        local tabCol = col or C.Gold

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 0, 1, -8)
        btn.Position = UDim2.new(0, 0, 0, 4)
        btn.AutomaticSize = Enum.AutomaticSize.X
        btn.BackgroundColor3 = tabCol
        btn.BackgroundTransparency = isFirst and 0.88 or 1
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = ribbonRow
        corner(btn, UDim.new(0, 8))

        local bpad = Instance.new("UIPadding")
        bpad.PaddingLeft=UDim.new(0,12) bpad.PaddingRight=UDim.new(0,12)
        bpad.PaddingTop=UDim.new(0,4) bpad.PaddingBottom=UDim.new(0,4)
        bpad.Parent = btn

        local brow = Instance.new("Frame")
        brow.Size = UDim2.new(1,0,1,0)
        brow.BackgroundTransparency = 1
        brow.Parent = btn
        list(brow, 5, Enum.FillDirection.Horizontal)

        local ic = Instance.new("TextLabel")
        ic.Size = UDim2.new(0,16,1,0)
        ic.BackgroundTransparency=1
        ic.Text=icon ic.TextSize=13
        ic.Font=Enum.Font.GothamBold
        ic.TextColor3 = isFirst and tabCol or C.TextSec
        ic.Parent=brow

        local nm = Instance.new("TextLabel")
        nm.Size=UDim2.new(0,0,1,0) nm.AutomaticSize=Enum.AutomaticSize.X
        nm.BackgroundTransparency=1
        nm.Text=name nm.Font=Enum.Font.GothamBold nm.TextSize=12
        nm.TextColor3 = isFirst and tabCol or C.TextSec
        nm.Parent=brow

        local ind = Instance.new("Frame")
        ind.Size = UDim2.new(isFirst and 1 or 0, 0, 0, 2)
        ind.Position = UDim2.new(0,0,1,-2)
        ind.BackgroundColor3 = tabCol
        ind.BorderSizePixel=0
        ind.Parent=btn
        corner(ind, UDim.new(1,0))

        local page = Instance.new("ScrollingFrame")
        page.Size=UDim2.new(1,0,1,0)
        page.BackgroundTransparency=1
        page.BorderSizePixel=0
        page.ScrollBarThickness=3
        page.ScrollBarImageColor3=C.Border1
        page.CanvasSize=UDim2.new(0,0,0,0)
        page.AutomaticCanvasSize=Enum.AutomaticSize.Y
        page.Visible=isFirst
        page.Parent=contentArea
        pad(page, 14, 12)
        list(page, 8)

        tabs[name]=page
        table.insert(tabBtns, {Button=btn, Page=page, Name=name, Icon=ic, Label=nm, Ind=ind, Col=tabCol})

        btn.MouseButton1Click:Connect(function()
            for _, tb in ipairs(tabBtns) do
                local a = (tb.Name==name)
                tb.Page.Visible=a
                tw(tb.Ind,   {Size=UDim2.new(a and 1 or 0,0,0,2)})
                tw(tb.Icon,  {TextColor3 = a and tb.Col or C.TextSec})
                tw(tb.Label, {TextColor3 = a and tb.Col or C.TextSec})
                tw(tb.Button,{BackgroundTransparency = a and 0.88 or 1, BackgroundColor3 = a and tb.Col or Color3.new(0,0,0)})
            end
        end)
        return page
    end

    -- ─────────────────────────────────────────────────────────────
    --  TAB 1 — AUTO FARM
    -- ─────────────────────────────────────────────────────────────
    local farmPage = createTab("Auto Farm", "🌾", C.Green)
    sectionLabel(farmPage, "CORE AUTOMATION")
    createToggle(farmPage, "Auto Train  —  Activate Dumbell",    Config.AutoTrain,    function(s) Config.AutoTrain=s;    if s then Farm.startAutoTrain()    else Farm.stopAutoTrain()    end end)
    createToggle(farmPage, "Auto Sell  —  Sell All Friends",     Config.AutoSell,     function(s) Config.AutoSell=s;     if s then Farm.startAutoSell()     else Farm.stopAutoSell()     end end)
    createToggle(farmPage, "Auto Rebirth",                       Config.AutoRebirth,  function(s) Config.AutoRebirth=s;  if s then Farm.startAutoRebirth()  else Farm.stopAutoRebirth()  end end)
    sectionLabel(farmPage, "UPGRADES")
    createToggle(farmPage, "💪 Auto Buy Dumbbells",              Config.AutoBuyDumbell,  function(s) Config.AutoBuyDumbell=s;  if s then Farm.startAutoBuyDumbell()  else Farm.stopAutoBuyDumbell()  end end)
    createToggle(farmPage, "🎒 Auto Upgrade Carry Limit",        Config.AutoUpgradeCarry, function(s) Config.AutoUpgradeCarry=s; if s then Farm.startAutoUpgradeCarry() else Farm.stopAutoUpgradeCarry() end end)
    sectionLabel(farmPage, "EGG PULLING")
    createToggle(farmPage, "Auto Pull Egg  —  Target Tier",      Config.AutoPullEgg,  function(s) Config.AutoPullEgg=s;  if s then Farm.startAutoPullEgg()  else Farm.stopAutoPullEgg()  end end)
    createToggle(farmPage, "🛡️ Safe Fly / Hover  —  Dodge Boss", Config.SafeHover,    function(s) Config.SafeHover=s;    if not s then Farm.setFloat(false) Farm.setNoclip(false) end end)

    -- ─────────────────────────────────────────────────────────────
    --  TAB 2 — EGGS & ESP
    -- ─────────────────────────────────────────────────────────────
    local eggPage = createTab("Eggs & ESP", "🥚", C.Purple)
    sectionLabel(eggPage, "VISUAL")
    createToggle(eggPage, "🔮 Egg 3D Billboard ESP", Config.EggESP, function(s) Config.EggESP=s; ESP.setEnabled(s) end)
    sectionLabel(eggPage, "TELEPORT TO TIER")
    for _, tier in ipairs(Config.TIERS) do
        local col = Config.TIER_COLORS[tier] or C.TextSec
        createButton(eggPage, "📍  " .. tier .. " Egg", col, function()
            Config.TargetEggTier = tier; Farm.teleportToTier(tier)
        end)
    end

    -- ─────────────────────────────────────────────────────────────
    --  TAB 3 — MISC
    -- ─────────────────────────────────────────────────────────────
    local miscPage = createTab("Misc", "⚙️", C.Blue)
    sectionLabel(miscPage, "REWARDS")
    createButton(miscPage, "🎁  Claim Daily & Group Rewards", C.Green,    function() Remotes.fire("Claim Daily Reward") Remotes.fire("Claim Group Reward") end)
    createButton(miscPage, "💰  Sell All Friends (Manual)",   C.Blue,     function() Remotes.fire("Sell All Friends") end)
    sectionLabel(miscPage, "QUICK TELEPORT")
    createButton(miscPage, "🏠  Teleport to Spawn",           C.TextSec,  function() Farm.teleportToSpawn() end)
    createButton(miscPage, "🛒  Teleport to Sell Shop",       C.TextSec,  function() Farm.teleportToShop("Sell") end)
    createButton(miscPage, "⚡  Teleport to Strength Shop",   C.TextSec,  function() Farm.teleportToShop("ShopSpeed") end)
    createButton(miscPage, "🎒  Teleport to Carry Shop",      C.TextSec,  function() Farm.teleportToShop("ShopCarry") end)
    sectionLabel(miscPage, "SYSTEM")
    createButton(miscPage, "❌  Unload Script",               C.Red,      function() Runtime.Unload() end)

    -- ─────────────────────────────────────────────────────────────
    --  TAB 4 — UNIVERSAL
    -- ─────────────────────────────────────────────────────────────
    local uniPage = createTab("Universal", "🌐", C.Gold)
    sectionLabel(uniPage, "PROTECTION")
    createToggle(uniPage, "🔒 Anti-AFK  —  Kick Prevention",     Config.AntiAFK,     function(s) Config.AntiAFK=s;     Universal.setAntiAFK(s) end)
    sectionLabel(uniPage, "PERFORMANCE")
    createToggle(uniPage, "🎨 Low Graphics Mode  —  Better FPS", Config.LowGraphics, function(s) Config.LowGraphics=s; Universal.setLowGraphics(s) end)
    createToggle(uniPage, "⚡ Speed Boost  —  WalkSpeed " .. Config.WalkSpeed, Config.SpeedBoost, function(s) Config.SpeedBoost=s; Universal.setSpeed(s) end)
    sectionLabel(uniPage, "SERVER")
    createButton(uniPage, "🔄  Rejoin Same Server",              C.Blue,   function() Universal.rejoin() end)
    createButton(uniPage, "🌐  Server Hop  —  New Server",       C.Purple, function() Universal.serverHop() end)

    screenGui.Parent = parent
    toggleGui.Parent = parent
    table.insert(Runtime.Instances, screenGui)
    table.insert(Runtime.Instances, toggleGui)
end

-- ── 6. Universal Utilities Module ───────────────────────────────────
local Universal = {}
do
    local TeleportService = game:GetService("TeleportService")
    local HttpService     = game:GetService("HttpService")
    local _afkConn = nil

    -- Anti-AFK -----------------------------------------------------------
    function Universal.setAntiAFK(enable)
        if _afkConn then
            pcall(function() _afkConn:Disconnect() end)
            _afkConn = nil
        end
        if enable then
            _afkConn = LocalPlayer.Idled:Connect(function()
                pcall(function()
                    local vu = game:GetService("VirtualUser")
                    vu:CaptureController()
                    vu:ClickButton2(Vector2.new())
                end)
            end)
            Runtime.trackConnection(_afkConn)
        end
    end

    function Universal.stopAntiAFK()
        if _afkConn then
            pcall(function() _afkConn:Disconnect() end)
            _afkConn = nil
        end
    end

    -- Speed Boost ---------------------------------------------------------
    local _speedConn = nil
    local function applySpeed()
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            if hum then
                hum.WalkSpeed = Config.WalkSpeed
                hum.JumpPower = Config.JumpPower
            end
        end)
    end

    function Universal.setSpeed(enable)
        if _speedConn then
            pcall(function() _speedConn:Disconnect() end)
            _speedConn = nil
        end
        if enable then
            applySpeed()
            _speedConn = LocalPlayer.CharacterAdded:Connect(function(char)
                task.wait(0.5)
                applySpeed()
            end)
            Runtime.trackConnection(_speedConn)
        else
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end
                local hum = char:FindFirstChildWhichIsA("Humanoid")
                if hum then
                    hum.WalkSpeed = 16
                    hum.JumpPower = 50
                end
            end)
        end
    end

    function Universal.stopSpeed()
        Universal.setSpeed(false)
    end

    -- Low Graphics -------------------------------------------------------
    local _origQuality = nil
    function Universal.setLowGraphics(enable)
        pcall(function()
            local settings = UserSettings():GetService("UserGameSettings")
            if enable then
                _origQuality = settings.SavedQualityLevel
                settings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
                game:GetService("RunService"):Set3dRenderingEnabled(false)
            else
                game:GetService("RunService"):Set3dRenderingEnabled(true)
                if _origQuality then
                    settings.SavedQualityLevel = _origQuality
                    _origQuality = nil
                end
            end
        end)
        pcall(function()
            local lighting = game:GetService("Lighting")
            if enable then
                lighting.GlobalShadows  = false
                lighting.FogEnd         = 9e4
                lighting.FogStart       = 9e4
            else
                lighting.GlobalShadows  = true
            end
        end)
    end

    -- Rejoin -------------------------------------------------------------
    function Universal.rejoin()
        local placeId = game.PlaceId
        local jobId   = game.JobId
        pcall(function()
            local qot = (syn and syn.queue_on_teleport)
                or (typeof(queue_on_teleport) == "function" and queue_on_teleport)
                or (Fluxus and Fluxus.queue_on_teleport)
            if qot then
                qot(string.format([[
                    task.wait(3)
                    pcall(function()
                        loadstring(game:HttpGet("%s"))()
                    end)
                ]], SCRIPT_RAW_URL))
            end
        end)
        pcall(function()
            TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
        end)
    end

    -- Server Hop ---------------------------------------------------------
    function Universal.serverHop()
        local placeId = game.PlaceId
        pcall(function()
            local qot = (syn and syn.queue_on_teleport)
                or (typeof(queue_on_teleport) == "function" and queue_on_teleport)
                or (Fluxus and Fluxus.queue_on_teleport)
            if qot then
                qot(string.format([[
                    task.wait(3)
                    pcall(function()
                        loadstring(game:HttpGet("%s"))()
                    end)
                ]], SCRIPT_RAW_URL))
            end
        end)
        task.spawn(function()
            local ok, servers = pcall(function()
                local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100"):format(placeId)
                local raw = game:HttpGet(url)
                return HttpService:JSONDecode(raw)
            end)
            local currentJob = game.JobId
            if ok and servers and servers.data then
                for _, srv in ipairs(servers.data) do
                    if srv.id ~= currentJob and srv.playing and srv.maxPlayers
                        and srv.playing < srv.maxPlayers then
                        pcall(function()
                            TeleportService:TeleportToPlaceInstance(placeId, srv.id, LocalPlayer)
                        end)
                        return
                    end
                end
            end
            pcall(function()
                TeleportService:Teleport(placeId, LocalPlayer)
            end)
        end)
    end
end

-- ── 7. Startup ──────────────────────────────────────────────────────
Universal.setAntiAFK(Config.AntiAFK)

task.spawn(function()
    task.wait(2)
    if Runtime.Running then
        Remotes.fire("Claim Daily Reward")
        Remotes.fire("Claim Group Reward")
    end
end)

ESP.init()
buildUI()

function Runtime.Unload()
    Runtime.Running = false
    Config.AutoTrain = false
    Config.AutoSell = false
    Config.AutoRebirth = false
    Config.AutoBuyDumbell = false
    Config.AutoUpgradeCarry = false
    Config.AutoPullEgg = false

    Universal.stopAntiAFK()
    Universal.stopSpeed()
    if Config.LowGraphics then
        Universal.setLowGraphics(false)
    end

    for _, th in pairs(Farm.Threads) do
        pcall(task.cancel, th)
    end
    Farm.Threads = {}

    for _, conn in ipairs(Runtime.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Runtime.Connections = {}

    Farm.setFloat(false)
    Farm.setNoclip(false)

    ESP.destroy()

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