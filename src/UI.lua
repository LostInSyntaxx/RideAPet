-- src/UI.lua
local NS = getgenv().EggsESP
local AppConfig  = NS.Config
local S          = NS.Services
local StateStore = NS.StateStore
local Utils      = NS.Utils
local ESP        = NS.ESP
local Farm       = NS.Farm
local Rebirth    = NS.Rebirth
local Movement   = NS.Movement
local Plot       = NS.Plot

local UI = {}

function UI.getStroke(frame)
    return frame and frame:FindFirstChildWhichIsA("UIStroke")
end

function UI.applyCard(frame, cornerRadius, bgColor, strokeColor, strokeTransparency)
    frame.BackgroundColor3 = bgColor or AppConfig.OuterCardBg
    frame.BackgroundTransparency = AppConfig.OuterCardTransparency
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, cornerRadius or AppConfig.Radius2XL)
    corner.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Color = strokeColor or AppConfig.CardBorder
    stroke.Transparency = strokeTransparency or AppConfig.BorderTransparency
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = frame
    return corner, stroke
end

function UI.styleButton(button, customRadius, normalBg, hoverBg)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, customRadius or AppConfig.RadiusLG)
    corner.Parent = button
    local stroke = Instance.new("UIStroke")
    stroke.Color = AppConfig.BorderInner
    stroke.Transparency = 0.55
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = button
    button.AutoButtonColor = false
    button:SetAttribute("DefaultBg", normalBg or button.BackgroundColor3)
    local targetHoverBg = hoverBg or Color3.fromRGB(44, 44, 44)
    button.MouseEnter:Connect(function()
        Utils.tween(button, { BackgroundColor3 = targetHoverBg }, 0.12)
        Utils.tween(stroke, { Transparency = 0.25, Color = Color3.fromRGB(75, 75, 75) }, 0.12)
    end)
    button.MouseLeave:Connect(function()
        local bg = button:GetAttribute("DefaultBg") or AppConfig.NestedCardBg
        Utils.tween(button, { BackgroundColor3 = bg }, 0.12)
        Utils.tween(stroke, { Transparency = 0.55, Color = AppConfig.BorderInner }, 0.12)
    end)
end

function UI.setButtonDefault(button, color)
    if not button then return end
    button:SetAttribute("DefaultBg", color)
    button.BackgroundColor3 = color
end

function UI.styleInput(textBox, customRadius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, customRadius or AppConfig.RadiusLG)
    corner.Parent = textBox
    local stroke = Instance.new("UIStroke")
    stroke.Color = AppConfig.BorderInner
    stroke.Transparency = 0.55
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = textBox
    textBox.Focused:Connect(function()
        Utils.tween(stroke, { Color = AppConfig.AccentGreen, Transparency = 0.2 }, 0.15)
    end)
    textBox.FocusLost:Connect(function()
        Utils.tween(stroke, { Color = AppConfig.BorderInner, Transparency = 0.55 }, 0.15)
    end)
end

local activeSliders = {}
S.UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        for _, cb in pairs(activeSliders) do cb(input) end
    end
end)
S.UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        table.clear(activeSliders)
    end
end)

function UI.createToggle(parent, titleText, descText, initialValue, onToggle)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -4, 0, 52)
    frame.BackgroundColor3 = AppConfig.NestedCardBg
    frame.Parent = parent
    UI.applyCard(frame, AppConfig.RadiusXL, AppConfig.NestedCardBg, AppConfig.BorderInner)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 0, 20)
    title.Position = UDim2.new(0, 14, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = AppConfig.TextPrimary
    title.TextSize = AppConfig.TextBody
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -80, 0, 16)
    desc.Position = UDim2.new(0, 14, 0, 28)
    desc.BackgroundTransparency = 1
    desc.Text = descText or ""
    desc.TextColor3 = AppConfig.TextMuted
    desc.TextSize = AppConfig.TextMicro
    desc.Font = Enum.Font.GothamMedium
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = frame

    local toggleTrack = Instance.new("TextButton")
    toggleTrack.Size = UDim2.new(0, 44, 0, 24)
    toggleTrack.Position = UDim2.new(1, -58, 0.5, -12)
    toggleTrack.BackgroundColor3 = initialValue and AppConfig.AccentGreen or Color3.fromRGB(40, 40, 40)
    toggleTrack.Text = ""
    toggleTrack.AutoButtonColor = false
    toggleTrack.Parent = frame

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = toggleTrack

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = initialValue and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = toggleTrack

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local state = initialValue
    toggleTrack.MouseButton1Click:Connect(function()
        state = not state
        local targetTrackColor = state and AppConfig.AccentGreen or Color3.fromRGB(40, 40, 40)
        local targetKnobPos = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        Utils.tween(toggleTrack, { BackgroundColor3 = targetTrackColor }, 0.15)
        Utils.tween(knob, { Position = targetKnobPos }, 0.15)
        if onToggle then onToggle(state) end
    end)
    return frame
end

function UI.createSlider(parent, titleText, minVal, maxVal, defaultVal, unitStr, onChange)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -4, 0, 60)
    frame.BackgroundColor3 = AppConfig.NestedCardBg
    frame.Parent = parent
    UI.applyCard(frame, AppConfig.RadiusXL, AppConfig.NestedCardBg, AppConfig.BorderInner)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.6, 0, 0, 20)
    title.Position = UDim2.new(0, 14, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = AppConfig.TextPrimary
    title.TextSize = AppConfig.TextBody
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0.35, -14, 0, 20)
    valLabel.Position = UDim2.new(0.65, 0, 0, 8)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = string.format("%s %s", tostring(defaultVal), unitStr or "")
    valLabel.TextColor3 = AppConfig.AccentBlue
    valLabel.TextSize = AppConfig.TextCaption
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = frame

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(1, -28, 0, 6)
    track.Position = UDim2.new(0, 14, 0, 38)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = frame

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local pct = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = AppConfig.AccentBlue
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 14, 0, 14)
    thumb.Position = UDim2.new(1, -7, 0.5, -7)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.Parent = fill

    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(1, 0)
    thumbCorner.Parent = thumb

    StateStore._sliderCounter = StateStore._sliderCounter + 1
    local sliderId = "slider_" .. tostring(StateStore._sliderCounter)

    local function updateFromInput(input)
        local inputPos = input.Position.X
        local trackPos = track.AbsolutePosition.X
        local trackWidth = track.AbsoluteSize.X
        if trackWidth <= 0 then return end
        local relX = math.clamp((inputPos - trackPos) / trackWidth, 0, 1)
        local val = math.floor(minVal + (maxVal - minVal) * relX + 0.5)
        fill.Size = UDim2.new(relX, 0, 1, 0)
        valLabel.Text = string.format("%s %s", tostring(val), unitStr or "")
        if onChange then onChange(val) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            activeSliders[sliderId] = updateFromInput
            updateFromInput(input)
        end
    end)
    S.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            activeSliders[sliderId] = nil
        end
    end)

    return frame
end

-- ═══════════════════════════════════════════════════════════════════
-- ⚠️ UI.mount() — ก๊อปจาก UIComponent.mount() ใน Main.lua ต้นฉบับ
-- ═══════════════════════════════════════════════════════════════════
-- วิธี:
--   1. เปิด Main.lua ต้นฉบับ
--   2. ค้นหา "function UIComponent.mount()"
--   3. ก๊อปทั้งหมดตั้งแต่บรรทัดนั้นจนถึง "end" ปิดท้ายสุดของ mount
--   4. แปะในฟังก์ชันนี้
--   5. ค้นหา-แทนที่ (Find & Replace):
--        "ESPComponent"       → "ESP"
--        "FarmComponent"      → "Farm"
--        "RebirthComponent"   → "Rebirth"
--        "MovementComponent"  → "Movement"
--        "PlotComponent"      → "Plot"
--        "UIComponent"        → "UI"
--        "ServiceManager"     → "S"
--        "AppConfig"          → (คงไว้ — เป็น local อยู่แล้ว)
--        "StateStore"         → (คงไว้ — เป็น local อยู่แล้ว)
--
-- function UI.mount()
--     -- ... โค้ดจาก UIComponent.mount() ที่ผ่านการแทนชื่อแล้ว ...
-- end

NS.UI = UI