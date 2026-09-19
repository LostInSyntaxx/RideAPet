local NS = getgenv().EggsESP
local AppConfig = NS.Config
local S = NS.Services
local StateStore = NS.StateStore
local Utils = NS.Utils

local ESP = {}

function ESP.getColor(eggName)
    local lower = eggName:lower()
    for _, kw in ipairs(AppConfig.RareKeywords) do
        if string.find(lower, kw, 1, true) then return AppConfig.ESPRareColor end
    end
    local hash = 0
    for i = 1, #eggName do hash = hash + string.byte(eggName, i) * (i + 1) end
    local palette = AppConfig.ESPPalette
    return palette[(hash % #palette) + 1]
end

function ESP.createBillboard(egg)
    local data = StateStore.eggData[egg]
    if not data or (data.NameBillboard and data.NameBillboard.Parent) then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "EggESP_Info"
    billboard.Size = UDim2.new(0, 180, 0, 42)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 2500
    billboard.Enabled = false
    billboard.Parent = egg

    local eggColor = ESP.getColor(egg.Name)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "EggName"
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = egg.Name
    nameLabel.TextColor3 = eggColor
    nameLabel.TextStrokeTransparency = 0.2
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.TextSize = AppConfig.ESPNameSize
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "Distance"
    distLabel.Size = UDim2.new(1, 0, 0, 16)
    distLabel.Position = UDim2.new(0, 0, 0, 19)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0 studs"
    distLabel.TextColor3 = Color3.fromRGB(220, 225, 235)
    distLabel.TextStrokeTransparency = 0.4
    distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distLabel.TextSize = AppConfig.ESPDistanceSize
    distLabel.Font = Enum.Font.GothamMedium
    distLabel.Parent = billboard
    data.NameBillboard = billboard
end

function ESP.updateBillboard(egg)
    local data = StateStore.eggData[egg]
    if not data or not data.NameBillboard or not data.NameBillboard.Parent then return end
    local billboard = data.NameBillboard
    local nameLabel = billboard:FindFirstChild("EggName")
    local distLabel = billboard:FindFirstChild("Distance")
    if nameLabel then nameLabel.Text = egg.Name end
    if distLabel then
        local d = Utils.getDistanceToTarget(egg)
        distLabel.Text = (d == math.huge) and "?" or string.format("%d studs", math.floor(d + 0.5))
    end
end

function ESP.updateEgg(egg)
    if not Utils.isValidEgg(egg) then return end
    if not StateStore.eggData[egg] then
        StateStore.eggData[egg] = {
            Highlight = nil, NameBillboard = nil,
            CustomColor = ESP.getColor(egg.Name),
            CustomActive = false
        }
    end
    local data = StateStore.eggData[egg]
    local eggColor = ESP.getColor(egg.Name)
    local shouldShow = data.CustomActive or StateStore.mainESPActive
    local color = data.CustomActive and (data.CustomColor or eggColor) or eggColor

    if shouldShow then
        if not data.Highlight or not data.Highlight.Parent then
            local highlight = Instance.new("Highlight")
            highlight.Name = "EggESP_Highlight"
            highlight.Adornee = egg
            highlight.FillTransparency = AppConfig.ESPFillTransparency
            highlight.OutlineTransparency = AppConfig.ESPOutlineTransparency
            highlight.Parent = egg
            data.Highlight = highlight
        end
        data.Highlight.FillColor = color
        data.Highlight.OutlineColor = color
        data.Highlight.Enabled = true
        ESP.createBillboard(egg)
        if data.NameBillboard then
            data.NameBillboard.Enabled = true
            ESP.updateBillboard(egg)
        end
    else
        if data.Highlight then data.Highlight.Enabled = false end
        if data.NameBillboard then data.NameBillboard.Enabled = false end
    end
end

function ESP.updateAll()
    local folder = S.RenderedEggsFolder
    if not folder then return end
    for _, egg in ipairs(folder:GetChildren()) do ESP.updateEgg(egg) end
end

function ESP.removeEgg(egg)
    local data = StateStore.eggData[egg]
    if data then
        if data.Highlight then pcall(function() data.Highlight:Destroy() end) end
        if data.NameBillboard then pcall(function() data.NameBillboard:Destroy() end) end
        StateStore.eggData[egg] = nil
    end
    StateStore.autoFarmProcessed[egg] = nil
    StateStore.eggCooldowns[egg] = nil
end

function ESP.bindEggLifecycle(egg)
    if not egg or not egg.Parent then return end
    local conn
    conn = egg.Destroying:Connect(function()
        ESP.removeEgg(egg)
        if conn then pcall(function() conn:Disconnect() end) end
    end)
    StateStore.track(conn)
end

NS.ESP = ESP