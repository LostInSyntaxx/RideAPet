--[[
    LuxuryXHUB — Pull An Egg
    UI.lua — AAA Dark Dashboard  •  Ribbon Tabs  •  Nested Cards
    Redesigned: #0e0e0e / #171717 / #1F1F1F palette
]]

local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")
local Players           = game:GetService("Players")
local LocalPlayer       = Players.LocalPlayer

-- ── Palette ──────────────────────────────────────────────────────────
local C = {
    base        = Color3.fromHex("#0e0e0e"),   -- deepest background
    surface     = Color3.fromHex("#171717"),   -- outer card
    elevated    = Color3.fromHex("#1F1F1F"),   -- inner card
    overlay     = Color3.fromHex("#252525"),   -- hovered / active pill
    border      = Color3.fromHex("#2C2C2C"),   -- subtle card border
    borderInner = Color3.fromHex("#333333"),

    accent      = Color3.fromRGB(255, 170,  0),  -- amber brand
    accentDim   = Color3.fromRGB(180, 110,  0),
    accentGlow  = Color3.fromRGB(255, 200, 80),
    green       = Color3.fromRGB( 46, 204, 113),
    blue        = Color3.fromRGB( 52, 152, 219),
    red         = Color3.fromRGB(231,  76,  60),
    muted       = Color3.fromRGB(110, 110, 110),

    textPrimary = Color3.fromRGB(240, 242, 245),
    textSecond  = Color3.fromRGB(163, 163, 163),
    textMuted   = Color3.fromRGB( 90,  90,  90),
    white       = Color3.fromRGB(255, 255, 255),
}

-- ── Tween helpers ────────────────────────────────────────────────────
local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.14, Enum.EasingStyle.Quad), props):Play()
end

local function hover(btn, normalBg, hoverBg)
    btn.MouseEnter:Connect(function()    tween(btn, {BackgroundColor3 = hoverBg},  0.10) end)
    btn.MouseLeave:Connect(function()    tween(btn, {BackgroundColor3 = normalBg}, 0.10) end)
    btn.MouseButton1Down:Connect(function() tween(btn, {BackgroundColor3 = C.accent}, 0.06) end)
    btn.MouseButton1Up:Connect(function()   tween(btn, {BackgroundColor3 = hoverBg},  0.08) end)
end

-- ── UI Module ────────────────────────────────────────────────────────
local UI = { ScreenGui = nil, ToggleGui = nil, MainFrame = nil }

local Config, Farm, ESP, Remotes

local function getGuiParent()
    local ok, hui = pcall(function() return gethui() end)
    if ok and hui then return hui end
    local ok2 = pcall(function() return CoreGui:GetChildren() end)
    if ok2 then return CoreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

function UI.init(cfg, farmRef, espRef, remsRef)
    Config  = cfg
    Farm    = farmRef
    ESP     = espRef
    Remotes = remsRef
    UI.build()
end

-- ────────────────────────────────────────────────────────────────────
--  BUILD
-- ────────────────────────────────────────────────────────────────────
function UI.build()
    local parent = getGuiParent()
    for _, n in ipairs({"LuxuryXHUB_PullAnEgg","LuxuryXHUB_FloatingBtn"}) do
        local old = parent:FindFirstChild(n)
        if old then old:Destroy() end
    end

    -- ── Root ScreenGui ──────────────────────────────────────────────
    local sg = Instance.new("ScreenGui")
    sg.Name            = "LuxuryXHUB_PullAnEgg"
    sg.ResetOnSpawn    = false
    sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling

    -- ── Window shell (outer card) ───────────────────────────────────
    local W_W, W_H = 640, 430
    local win = Instance.new("Frame")
    win.Name                = "Window"
    win.Size                = UDim2.new(0, W_W, 0, W_H)
    win.Position            = UDim2.new(0.5, -W_W/2, 0.5, -W_H/2)
    win.BackgroundColor3    = C.surface
    win.BorderSizePixel     = 0
    win.ClipsDescendants    = true
    win.Parent              = sg

    local winCorner = Instance.new("UICorner")
    winCorner.CornerRadius  = UDim.new(0, 16)
    winCorner.Parent        = win

    local winStroke = Instance.new("UIStroke")
    winStroke.Color         = C.border
    winStroke.Thickness     = 1
    winStroke.Parent        = win

    -- ── Title Bar ───────────────────────────────────────────────────
    local titleBar = Instance.new("Frame")
    titleBar.Name               = "TitleBar"
    titleBar.Size               = UDim2.new(1, 0, 0, 52)
    titleBar.BackgroundColor3   = C.base
    titleBar.BorderSizePixel    = 0
    titleBar.Parent             = win

    -- top-left rounded only
    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 16)
    tbCorner.Parent = titleBar

    -- cover bottom corners of titleBar so they don't bleed
    local tbFill = Instance.new("Frame")
    tbFill.Size                 = UDim2.new(1, 0, 0, 16)
    tbFill.Position             = UDim2.new(0, 0, 1, -16)
    tbFill.BackgroundColor3     = C.base
    tbFill.BorderSizePixel      = 0
    tbFill.Parent               = titleBar

    -- Accent left-edge bar
    local accentBar = Instance.new("Frame")
    accentBar.Size              = UDim2.new(0, 3, 1, 0)
    accentBar.BackgroundColor3  = C.accent
    accentBar.BorderSizePixel   = 0
    accentBar.Parent            = titleBar
    Instance.new("UICorner").Parent = accentBar

    -- Logo emoji
    local logo = Instance.new("TextLabel")
    logo.Position           = UDim2.new(0, 14, 0, 0)
    logo.Size               = UDim2.new(0, 32, 1, 0)
    logo.BackgroundTransparency = 1
    logo.Text               = "🐾"
    logo.TextSize           = 20
    logo.Parent             = titleBar

    -- Title text
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Position       = UDim2.new(0, 46, 0, 0)
    titleLbl.Size           = UDim2.new(0, 160, 1, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text           = "LuxuryXHUB"
    titleLbl.TextColor3     = C.accent
    titleLbl.Font           = Enum.Font.GothamBold
    titleLbl.TextSize       = 16
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent         = titleBar

    -- Sub-badge
    local subBadge = Instance.new("Frame")
    subBadge.Size               = UDim2.new(0, 92, 0, 22)
    subBadge.Position           = UDim2.new(0, 200, 0.5, -11)
    subBadge.BackgroundColor3   = C.elevated
    subBadge.Parent             = titleBar
    local sbCorner = Instance.new("UICorner")
    sbCorner.CornerRadius = UDim.new(0, 11)
    sbCorner.Parent = subBadge
    local sbStroke = Instance.new("UIStroke")
    sbStroke.Color = C.border ; sbStroke.Thickness = 1 ; sbStroke.Parent = subBadge
    local subLbl = Instance.new("TextLabel")
    subLbl.Size = UDim2.new(1,0,1,0) ; subLbl.BackgroundTransparency = 1
    subLbl.Text = "Pull An Egg" ; subLbl.TextColor3 = C.textSecond
    subLbl.Font = Enum.Font.GothamMedium ; subLbl.TextSize = 11
    subLbl.Parent = subBadge

    -- Window controls (close / minimise)
    local function makeWinBtn(xOffset, bg, symbol)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 26, 0, 26)
        b.Position = UDim2.new(1, xOffset, 0.5, -13)
        b.BackgroundColor3 = bg
        b.Text = symbol
        b.TextColor3 = C.white
        b.Font = Enum.Font.GothamBold
        b.TextSize = 12
        b.Parent = titleBar
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 8)
        bc.Parent = b
        return b
    end

    local closeBtn = makeWinBtn(-36, C.red,             "✕")
    local hideBtn  = makeWinBtn(-68, Color3.fromHex("#2a2a2a"), "─")

    -- Drag
    local dragging, dragInput, dragStart, startPos
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true ; dragStart = inp.Position ; startPos = win.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    titleBar.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            dragInput = inp
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if inp == dragInput and dragging then
            local d = inp.Position - dragStart
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    -- ── Ribbon Tab Bar ──────────────────────────────────────────────
    local RIBBON_H = 40
    local ribbon = Instance.new("Frame")
    ribbon.Name             = "Ribbon"
    ribbon.Size             = UDim2.new(1, 0, 0, RIBBON_H)
    ribbon.Position         = UDim2.new(0, 0, 0, 52)
    ribbon.BackgroundColor3 = C.base
    ribbon.BorderSizePixel  = 0
    ribbon.Parent           = win

    local ribbonFill = Instance.new("Frame")
    ribbonFill.Size               = UDim2.new(1,0,0,1)
    ribbonFill.Position           = UDim2.new(0,0,1,-1)
    ribbonFill.BackgroundColor3   = C.border
    ribbonFill.BorderSizePixel    = 0
    ribbonFill.Parent             = ribbon

    local ribbonList = Instance.new("UIListLayout")
    ribbonList.FillDirection       = Enum.FillDirection.Horizontal
    ribbonList.VerticalAlignment   = Enum.VerticalAlignment.Center
    ribbonList.Padding             = UDim.new(0, 4)
    ribbonList.Parent              = ribbon

    local ribbonPad = Instance.new("UIPadding")
    ribbonPad.PaddingLeft   = UDim.new(0, 12)
    ribbonPad.PaddingTop    = UDim.new(0, 6)
    ribbonPad.PaddingBottom = UDim.new(0, 6)
    ribbonPad.Parent        = ribbon

    -- ── Content area ────────────────────────────────────────────────
    local contentY = 52 + RIBBON_H
    local content = Instance.new("Frame")
    content.Name            = "Content"
    content.Size            = UDim2.new(1, 0, 1, -contentY)
    content.Position        = UDim2.new(0, 0, 0, contentY)
    content.BackgroundColor3 = C.surface
    content.BorderSizePixel = 0
    content.Parent          = win

    -- ── Tab system ──────────────────────────────────────────────────
    local tabDefs   = {}  -- {btn, page}
    local activeTab = nil

    local function setActiveTab(name)
        for _, td in ipairs(tabDefs) do
            local isMe = (td.name == name)
            td.page.Visible = isMe
            if isMe then
                tween(td.btn, {BackgroundColor3 = C.accent,   TextColor3 = C.base},    0.12)
            else
                tween(td.btn, {BackgroundColor3 = Color3.fromHex("#1a1a1a"), TextColor3 = C.textSecond}, 0.12)
            end
        end
        activeTab = name
    end

    local function addTab(name, icon)
        local btn = Instance.new("TextButton")
        btn.Size                = UDim2.new(0, 0, 1, 0)  -- auto-width via padding
        btn.AutomaticSize       = Enum.AutomaticSize.X
        btn.BackgroundColor3    = Color3.fromHex("#1a1a1a")
        btn.Text                = icon .. "  " .. name
        btn.TextColor3          = C.textSecond
        btn.Font                = Enum.Font.GothamBold
        btn.TextSize            = 12
        btn.Parent              = ribbon

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        local btnPad = Instance.new("UIPadding")
        btnPad.PaddingLeft  = UDim.new(0, 12)
        btnPad.PaddingRight = UDim.new(0, 12)
        btnPad.Parent = btn

        -- ── Outer card (page wrapper) ────────────────────────────────
        local outer = Instance.new("Frame")
        outer.Name              = "Page_" .. name
        outer.Size              = UDim2.new(1, -24, 1, -20)
        outer.Position          = UDim2.new(0, 12, 0, 10)
        outer.BackgroundColor3  = C.elevated
        outer.BorderSizePixel   = 0
        outer.Visible           = false
        outer.Parent            = content

        local outerCorner = Instance.new("UICorner")
        outerCorner.CornerRadius = UDim.new(0, 14)
        outerCorner.Parent = outer

        local outerStroke = Instance.new("UIStroke")
        outerStroke.Color     = C.border
        outerStroke.Thickness = 1
        outerStroke.Parent    = outer

        -- Inner scrollable content area
        local inner = Instance.new("ScrollingFrame")
        inner.Name                  = "Inner"
        inner.Size                  = UDim2.new(1, -24, 1, -24)
        inner.Position              = UDim2.new(0, 12, 0, 12)
        inner.BackgroundTransparency = 1
        inner.BorderSizePixel       = 0
        inner.ScrollBarThickness    = 3
        inner.ScrollBarImageColor3  = C.accent
        inner.CanvasSize            = UDim2.new(0, 0, 0, 0)
        inner.AutomaticCanvasSize   = Enum.AutomaticSize.Y
        inner.Parent                = outer

        local innerList = Instance.new("UIListLayout")
        innerList.Padding           = UDim.new(0, 8)
        innerList.SortOrder         = Enum.SortOrder.LayoutOrder
        innerList.Parent            = inner

        btn.MouseButton1Click:Connect(function() setActiveTab(name) end)

        local entry = { name = name, btn = btn, page = outer, scroll = inner }
        table.insert(tabDefs, entry)
        return inner  -- callers append children to the inner scroll
    end

    -- ── Component Builders ───────────────────────────────────────────

    -- Nested card row (inner card inside the outer page card)
    local function makeCard(parent, heightVal)
        local card = Instance.new("Frame")
        card.Size               = UDim2.new(1, 0, 0, heightVal or 50)
        card.BackgroundColor3   = Color3.fromHex("#242424")
        card.BorderSizePixel    = 0
        card.Parent             = parent

        local cc = Instance.new("UICorner")
        cc.CornerRadius = UDim.new(0, 10)
        cc.Parent = card

        local cs = Instance.new("UIStroke")
        cs.Color     = C.borderInner
        cs.Thickness = 1
        cs.Parent    = card

        return card
    end

    -- Section divider label
    local function makeSection(parent, text)
        local lbl = Instance.new("TextLabel")
        lbl.Size                = UDim2.new(1, 0, 0, 22)
        lbl.BackgroundTransparency = 1
        lbl.Text                = text
        lbl.TextColor3          = C.accent
        lbl.Font                = Enum.Font.GothamBold
        lbl.TextSize            = 11
        lbl.TextXAlignment      = Enum.TextXAlignment.Left
        lbl.Parent              = parent

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 4)
        pad.Parent = lbl
        return lbl
    end

    -- Toggle row (nested card with pill toggle)
    local function makeToggle(parent, label, icon, default, onChange)
        local card = makeCard(parent, 48)

        local iconLbl = Instance.new("TextLabel")
        iconLbl.Position          = UDim2.new(0, 12, 0, 0)
        iconLbl.Size              = UDim2.new(0, 24, 1, 0)
        iconLbl.BackgroundTransparency = 1
        iconLbl.Text              = icon or ""
        iconLbl.TextSize          = 16
        iconLbl.Parent            = card

        local lbl = Instance.new("TextLabel")
        lbl.Position              = UDim2.new(0, icon and 40 or 14, 0, 0)
        lbl.Size                  = UDim2.new(1, -110, 1, 0)
        lbl.BackgroundTransparency= 1
        lbl.Text                  = label
        lbl.TextColor3            = C.textPrimary
        lbl.Font                  = Enum.Font.GothamMedium
        lbl.TextSize              = 12
        lbl.TextXAlignment        = Enum.TextXAlignment.Left
        lbl.Parent                = card

        -- Status dot
        local dot = Instance.new("Frame")
        dot.Size               = UDim2.new(0, 7, 0, 7)
        dot.Position           = UDim2.new(1, -88, 0.5, -3)
        dot.BackgroundColor3   = default and C.green or C.muted
        dot.BorderSizePixel    = 0
        dot.Parent             = card
        Instance.new("UICorner").Parent = dot

        -- Pill toggle
        local pill = Instance.new("TextButton")
        pill.Position         = UDim2.new(1, -68, 0.5, -12)
        pill.Size             = UDim2.new(0, 54, 0, 24)
        pill.BackgroundColor3 = default and C.green or Color3.fromHex("#2a2a2a")
        pill.Text             = default and "ON" or "OFF"
        pill.TextColor3       = C.white
        pill.Font             = Enum.Font.GothamBold
        pill.TextSize         = 10
        pill.Parent           = card

        local pillCorner = Instance.new("UICorner")
        pillCorner.CornerRadius = UDim.new(0, 12)
        pillCorner.Parent = pill

        local state = default
        pill.MouseButton1Click:Connect(function()
            state = not state
            pill.BackgroundColor3 = state and C.green or Color3.fromHex("#2a2a2a")
            pill.Text             = state and "ON" or "OFF"
            dot.BackgroundColor3  = state and C.green or C.muted
            if onChange then onChange(state) end
        end)

        -- Hover reads current BackgroundColor3 so it never flashes a stale colour
        -- after a toggle state change.
        pill.MouseEnter:Connect(function()
            tween(pill, {BackgroundColor3 = state and Color3.fromRGB(56,220,130) or Color3.fromHex("#333333")}, 0.10)
        end)
        pill.MouseLeave:Connect(function()
            tween(pill, {BackgroundColor3 = state and C.green or Color3.fromHex("#2a2a2a")}, 0.10)
        end)

        return card
    end

    -- Action button (full-width nested card style)
    local function makeButton(parent, label, icon, accent, onClick)
        local bg = accent or C.elevated
        local btn = Instance.new("TextButton")
        btn.Size              = UDim2.new(1, 0, 0, 44)
        btn.BackgroundColor3  = bg
        btn.Text              = (icon and (icon .. "  ") or "") .. label
        btn.TextColor3        = C.textPrimary
        btn.Font              = Enum.Font.GothamSemibold
        btn.TextSize          = 12
        btn.Parent            = parent

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 10)
        bc.Parent = btn

        local bs = Instance.new("UIStroke")
        bs.Color = C.borderInner ; bs.Thickness = 1 ; bs.Parent = btn

        hover(btn, bg, Color3.fromHex("#2e2e2e"))
        btn.MouseButton1Click:Connect(function() if onClick then onClick() end end)
        return btn
    end

    -- ────────────────────────────────────────────────────────────────
    --  TAB 1 — Auto Farm
    -- ────────────────────────────────────────────────────────────────
    local farmScroll = addTab("Farm", "🌾")

    makeSection(farmScroll, "AUTOMATION")

    makeToggle(farmScroll, "Auto Train", "💪", Config.AutoTrain, function(s)
        Config.AutoTrain = s
        if s then Farm.startAutoTrain() else Farm.stopAutoTrain() end
    end)

    makeToggle(farmScroll, "Auto Sell Friends", "💰", Config.AutoSell, function(s)
        Config.AutoSell = s
        if s then Farm.startAutoSell() else Farm.stopAutoSell() end
    end)

    makeToggle(farmScroll, "Auto Rebirth", "🔄", Config.AutoRebirth, function(s)
        Config.AutoRebirth = s
        if s then Farm.startAutoRebirth() else Farm.stopAutoRebirth() end
    end)

    makeToggle(farmScroll, "Auto Buy Dumbbells", "🏋️", Config.AutoBuyDumbell, function(s)
        Config.AutoBuyDumbell = s
        if s then Farm.startAutoBuyDumbell() else Farm.stopAutoBuyDumbell() end
    end)

    makeToggle(farmScroll, "Auto Upgrade Carry Limit", "🎒", Config.AutoUpgradeCarry, function(s)
        Config.AutoUpgradeCarry = s
        if s then Farm.startAutoUpgradeCarry() else Farm.stopAutoUpgradeCarry() end
    end)

    makeToggle(farmScroll, "Auto Buy Gear", "⚙️", Config.AutoBuyGear, function(s)
        Config.AutoBuyGear = s
        if s then Farm.startAutoBuyGear() else Farm.stopAutoBuyGear() end
    end)

    makeSection(farmScroll, "EGG PULLING")

    makeToggle(farmScroll, "Auto Pull Egg (Target Tier)", "🥚", Config.AutoPullEgg, function(s)
        Config.AutoPullEgg = s
        if s then Farm.startAutoPullEgg() else Farm.stopAutoPullEgg() end
    end)

    makeToggle(farmScroll, "Safe Fly / Boss Hover", "🛡️", Config.SafeHover, function(s)
        Config.SafeHover = s
        if not s then Farm.setFloat(false) ; Farm.setNoclip(false) end
    end)

    makeSection(farmScroll, "SAFETY")

    makeToggle(farmScroll, "Auto Revive (Instant)", "💖", Config.AutoRevive, function(s)
        Config.AutoRevive = s
    end)

    -- ────────────────────────────────────────────────────────────────
    --  TAB 2 — Eggs & ESP
    -- ────────────────────────────────────────────────────────────────
    local eggScroll = addTab("ESP", "🥚")

    makeSection(eggScroll, "VISUALS")

    makeToggle(eggScroll, "Egg 3D Billboard ESP", "👁️", Config.EggESP, function(s)
        Config.EggESP = s
        ESP.setEnabled(s)
    end)

    makeSection(eggScroll, "TELEPORT TO TIER")

    for _, tier in ipairs(Config.TIERS) do
        local col = Config.TIER_COLORS[tier] or C.textSecond
        local btn = makeButton(eggScroll, tier, "📍", Color3.fromHex("#1e1e1e"), function()
            Config.TargetEggTier = tier
            Farm.teleportToTier(tier)
        end)
        -- colour the tier label differently using a child label override
        local inner = btn:FindFirstChildWhichIsA("TextLabel")
        -- Add a colour swatch dot
        local dot = Instance.new("Frame")
        dot.Size             = UDim2.new(0, 8, 0, 8)
        dot.Position         = UDim2.new(1, -20, 0.5, -4)
        dot.BackgroundColor3 = col
        dot.BorderSizePixel  = 0
        dot.Parent           = btn
        local dc = Instance.new("UICorner") ; dc.CornerRadius = UDim.new(0,4) ; dc.Parent = dot
    end

    -- ────────────────────────────────────────────────────────────────
    --  TAB 3 — Rewards & Misc
    -- ────────────────────────────────────────────────────────────────
    local miscScroll = addTab("Misc", "⚙️")

    makeSection(miscScroll, "REWARDS")

    makeButton(miscScroll, "Claim Daily & Group Rewards", "🎁", Color3.fromHex("#1b2e22"), function()
        Remotes.claimDailyReward()
        Remotes.claimGroupReward()
    end)

    makeButton(miscScroll, "Sell All Friends (Manual)", "💰", Color3.fromHex("#1a2233"), function()
        Remotes.sellAll()
    end)

    makeSection(miscScroll, "TELEPORT")

    makeButton(miscScroll, "Teleport to Spawn",         "🏠", Color3.fromHex("#1e1e1e"), function() Farm.teleportToSpawn() end)
    makeButton(miscScroll, "Teleport to Sell Shop",     "🏪", Color3.fromHex("#1e1e1e"), function() Farm.teleportToShop("Sell") end)
    makeButton(miscScroll, "Teleport to Strength Shop", "⚡", Color3.fromHex("#1e1e1e"), function() Farm.teleportToShop("ShopSpeed") end)
    makeButton(miscScroll, "Teleport to Carry Shop",    "🎒", Color3.fromHex("#1e1e1e"), function() Farm.teleportToShop("ShopCarry") end)

    -- ── Activate first tab ───────────────────────────────────────────
    if #tabDefs > 0 then
        setActiveTab(tabDefs[1].name)
    end

    -- ── Close / Hide buttons ─────────────────────────────────────────
    closeBtn.MouseButton1Click:Connect(function()
        win.Visible = false
    end)
    hideBtn.MouseButton1Click:Connect(function()
        win.Visible = false
    end)

    -- ── Floating toggle button (draggable) ───────────────────────────
    local tg = Instance.new("ScreenGui")
    tg.Name           = "LuxuryXHUB_FloatingBtn"
    tg.ResetOnSpawn   = false
    tg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local fab = Instance.new("TextButton")
    fab.Name              = "FAB"
    fab.Size              = UDim2.new(0, 48, 0, 48)
    fab.Position          = UDim2.new(0, 18, 0.5, -24)
    fab.BackgroundColor3  = C.surface
    fab.Text              = "🐾"
    fab.TextSize          = 20
    fab.Parent            = tg

    local fabCorner = Instance.new("UICorner")
    fabCorner.CornerRadius = UDim.new(0, 24)
    fabCorner.Parent = fab

    local fabStroke = Instance.new("UIStroke")
    fabStroke.Color = C.accent ; fabStroke.Thickness = 2 ; fabStroke.Parent = fab

    fab.MouseButton1Click:Connect(function()
        win.Visible = not win.Visible
        fabStroke.Color = win.Visible and C.accentGlow or C.accent
    end)

    -- FAB drag
    local fDragging, fDragInput, fStart, fPos
    fab.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            fDragging = true ; fStart = inp.Position ; fPos = fab.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then fDragging = false end
            end)
        end
    end)
    fab.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            fDragInput = inp
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if inp == fDragInput and fDragging then
            local d = inp.Position - fStart
            fab.Position = UDim2.new(fPos.X.Scale, fPos.X.Offset + d.X, fPos.Y.Scale, fPos.Y.Offset + d.Y)
        end
    end)

    -- Global keyboard shortcut (Ctrl toggles)
    UserInputService.InputBegan:Connect(function(inp, gpe)
        if not gpe and (inp.KeyCode == Enum.KeyCode.LeftControl or inp.KeyCode == Enum.KeyCode.RightControl) then
            win.Visible = not win.Visible
            fabStroke.Color = win.Visible and C.accentGlow or C.accent
        end
    end)

    -- ── Mount ────────────────────────────────────────────────────────
    sg.Parent  = parent
    tg.Parent  = parent
    UI.ScreenGui  = sg
    UI.ToggleGui  = tg
    UI.MainFrame  = win
end

function UI.destroy()
    if UI.ScreenGui  then pcall(function() UI.ScreenGui:Destroy()  end) end
    if UI.ToggleGui  then pcall(function() UI.ToggleGui:Destroy()  end) end
end

return UI
