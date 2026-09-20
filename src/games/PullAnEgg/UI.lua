--[[
    LuxuryXHUB - Pull An Egg
    UI.lua - Modern Glassmorphic Dark-Themed GUI
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local UI = {
    ScreenGui = nil,
    MainFrame = nil
}

local Config = nil
local Farm = nil
local ESP = nil
local Remotes = nil

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
    -- Clean previous instances
    local parent = getGuiParent()
    local old = parent:FindFirstChild("LuxuryXHUB_PullAnEgg")
    if old then old:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LuxuryXHUB_PullAnEgg"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- ── Main Frame ───────────────────────────────────────────────────
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

    -- ── Header ───────────────────────────────────────────────────────
    local header = Instance.new("Frame")
    header.Name = "Header"
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
        screenGui.Enabled = not screenGui.Enabled
    end)

    -- Make Header Draggable
    local dragging, dragInput, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
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

    -- ── Tab Container ────────────────────────────────────────────────
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

    -- ── Helper: Create Card Component ────────────────────────────────
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

    -- ── Tab 1: Auto Farm ─────────────────────────────────────────────
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

    createToggle(farmPage, "Auto Pull Egg (Target Tier)", Config.AutoPullEgg, function(s)
        Config.AutoPullEgg = s
        if s then Farm.startAutoPullEgg() else Farm.stopAutoPullEgg() end
    end)

    -- ── Tab 2: Eggs & ESP ────────────────────────────────────────────
    local eggPage = createTab("Eggs & ESP", "🥚")

    createToggle(eggPage, "Egg 3D Billboard ESP", Config.EggESP, function(s)
        Config.EggESP = s
        ESP.setEnabled(s)
    end)

    -- Quick Teleport to Tiers
    local sectionLabel = Instance.new("TextLabel")
    sectionLabel.Size = UDim2.new(1, -8, 0, 24)
    sectionLabel.BackgroundTransparency = 1
    sectionLabel.Text = "⚡ Teleport to Egg Tiers:"
    sectionLabel.TextColor3 = Color3.fromRGB(255, 170, 0)
    sectionLabel.Font = Enum.Font.GothamBold
    sectionLabel.TextSize = 13
    sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    sectionLabel.Parent = eggPage

    for _, tier in ipairs(Config.TIERS) do
        local tierColor = Config.TIER_COLORS[tier] or Color3.fromRGB(200, 200, 200)
        createButton(eggPage, "📍 TP to " .. tier .. " Egg", Color3.fromRGB(24, 27, 39), function()
            Config.TargetEggTier = tier
            Farm.teleportToTier(tier)
        end)
    end

    -- ── Tab 3: Misc & Rewards ────────────────────────────────────────
    local miscPage = createTab("Misc", "⚙️")

    createButton(miscPage, "🎁 Claim All Daily & Group Rewards", Color3.fromRGB(39, 174, 96), function()
        Remotes.claimDailyReward()
        Remotes.claimGroupReward()
    end)

    createButton(miscPage, "💰 Sell All Friends Once (Manual)", Color3.fromRGB(41, 128, 185), function()
        Remotes.sellAll()
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

    screenGui.Parent = parent
    UI.ScreenGui = screenGui
    UI.MainFrame = main
end

return UI
