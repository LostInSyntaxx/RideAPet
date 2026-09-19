local NS = getgenv().EggsESP
local AppConfig = NS.Config
local S = NS.Services

local Utils = {}

function Utils.getCharacter() return S.LocalPlayer.Character end
function Utils.getRootPart()
    local char = Utils.getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end
function Utils.getHumanoid()
    local char = Utils.getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function Utils.tween(object, properties, duration, style, direction)
    if not object or not object.Parent then return end
    local info = TweenInfo.new(
        duration or AppConfig.AnimationTime,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    local tw = S.TweenService:Create(object, info, properties)
    tw:Play()
    return tw
end

function Utils.getTargetCFrame(target)
    if not target or not target.Parent then return nil end
    if target:IsA("Model") then
        if target.PrimaryPart then return target.PrimaryPart.CFrame end
        local base = target:FindFirstChildWhichIsA("BasePart")
        if base then return base.CFrame end
        return target:GetPivot()
    elseif target:IsA("BasePart") then
        return target.CFrame
    end
    return nil
end

function Utils.getTargetPosition(target)
    local cf = Utils.getTargetCFrame(target)
    return cf and cf.Position or nil
end

function Utils.getDistanceToTarget(target)
    local root = Utils.getRootPart()
    local targetPos = Utils.getTargetPosition(target)
    if not root or not targetPos then return math.huge end
    return (root.Position - targetPos).Magnitude
end

function Utils.isValidEgg(egg)
    return egg
        and egg.Parent == S.RenderedEggsFolder
        and (egg:IsA("Model") or egg:IsA("BasePart"))
end

function Utils.isRareEgg(eggName)
    local lower = eggName:lower()
    for _, kw in ipairs(AppConfig.RareKeywords) do
        if string.find(lower, kw, 1, true) then return true end
    end
    return false
end

function Utils.getEggImage(eggName)
    local playerGui = S.LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return "" end
    local main = playerGui:FindFirstChild("Main")
    local index = main and main:FindFirstChild("Index")
    local holders = index and index:FindFirstChild("Holders")
    local eggsHolder = holders and holders:FindFirstChild("EggsHolder")
    if not eggsHolder then return "" end
    local eggFrame = eggsHolder:FindFirstChild(eggName)
    if not eggFrame then return "" end
    local imageLabel = eggFrame:FindFirstChild("ImageLabel")
    if imageLabel and imageLabel:IsA("ImageLabel") then return imageLabel.Image or "" end
    return ""
end

function Utils.isKnownEggName(name)
    if not name or type(name) ~= "string" or #name < 2 then return false end
    local lower = name:lower()
    if string.find(lower, "egg", 1, true) then return true end
    local playerGui = S.LocalPlayer:FindFirstChild("PlayerGui")
    local main = playerGui and playerGui:FindFirstChild("Main")
    local index = main and main:FindFirstChild("Index")
    local holders = index and index:FindFirstChild("Holders")
    local eggsHolder = holders and holders:FindFirstChild("EggsHolder")
    if eggsHolder and eggsHolder:FindFirstChild(name) then return true end
    local folder = S.RenderedEggsFolder
    if folder and folder:FindFirstChild(name) then return true end
    return false
end

function Utils.resetVelocity(root)
    if not root then return end
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.Velocity = Vector3.zero
        root.RotVelocity = Vector3.zero
    end)
end

NS.Utils = Utils