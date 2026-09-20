--[[
    LuxuryXHUB - Pull An Egg
    UI.lua - AAA Game Dashboard Redesign (Dark Theme, Ribbon Header, Nested Cards)
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
    local oldToggle = parent:FindFirstChild("LuxuryXHUB_FloatingBtn")
    if oldToggle then oldToggle:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LuxuryXHUB_PullAnEgg"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- ── Main Frame ───────────────────────────────────────────────────
    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 680, 0, 460)
    main.Position = UDim2.new(0.5, -340, 0.5, -230)
    main.BackgroundColor3 = Color3.fromRGB(23, 23, 23) -- #171717
    main.BackgroundTransparency = 0.15
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 16) -- rounded-2xl style
    mainCorner.Parent = main

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(45, 45, 45)
    mainStroke.Transparency = 0.5
    mainStroke.Thickness = 1
    mainStroke.Parent = main

    -- ── Floating Open/Close Toggle Button ────────────────────────────
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

    -- Draggable Floating Button
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

    -- Keyboard shortcut (Ctrl)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and (input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl) then
            toggleUI()
        end
    end)

    -- ── Top Header / Branding ─────────────────────────────────────────
    local topHeader = Instance.new("Frame")
    topHeader.Name = "TopHeader"
    topHeader.Size = UDim2.new(1, 0, 0, 48)
    topHeader.BackgroundColor3 = Color3.fromRGB(14, 14, 14) -- #0e0e0e
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

    -- Make Header Draggable
    local dragging, dragInput, dragStart, startPos
    topHeader.InputBegan:Connect(function(input)
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

    -- ── Ribbon Tab Header ─────────────────────────────────────────────
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

    -- ── Content Container ─────────────────────────────────────────────
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

    -- ── Helper Components: Outer Card & Nested Sub-Cards ──────────────
    local function createPanelSection(page, sectionTitle)
        local outerCard = Instance.new("Frame")
        outerCard.Size = UDim2.new(1, 0, 0, 0) -- Auto layout updated via AutomaticSize
        outerCard.AutomaticSize = Enum.AutomaticSize.Y
        outerCard.BackgroundColor3 = Color3.fromRGB(23, 23, 23) -- #171717
        outerCard.BorderSizePixel = 0
        outerCard.Parent = page

        local outerCorner = Instance.new("UICorner")
        outerCorner.CornerRadius = UDim.new(0, 16) -- rounded-2xl
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
        outerPadding.PaddingBottom = UDim2.new(0, 12)
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
        innerCard.BackgroundColor3 = Color3.fromRGB(31, 31, 31) -- #1F1F1F nested card
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

    -- ── Tab 1: Auto Farm ─────────────────────────────────────────────
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

    -- ── Tab 2: Eggs & ESP ────────────────────────────────────────────
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

    -- ── Tab 3: Misc & Rewards ────────────────────────────────────────
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

return UI