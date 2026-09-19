local NS = getgenv().EggsESP
local AppConfig = NS.Config
local S = NS.Services
local Utils = NS.Utils
local Movement = NS.Movement
local Interaction = NS.Interaction

local Plot = {}

function Plot.isOwner(plot)
    if not plot then return false end
    local lp = S.LocalPlayer
    local dataFolder = plot:FindFirstChild("Data")
    if dataFolder then
        local ownerVal = dataFolder:FindFirstChild("Owner") or dataFolder:FindFirstChild("Player")
        if ownerVal then
            if ownerVal:IsA("StringValue") and (ownerVal.Value == lp.Name or ownerVal.Value == lp.DisplayName) then return true
            elseif ownerVal:IsA("ObjectValue") and ownerVal.Value == lp then return true
            elseif ownerVal:IsA("IntValue") and ownerVal.Value == lp.UserId then return true
            elseif tostring(ownerVal.Value) == lp.Name or tostring(ownerVal.Value) == tostring(lp.UserId) then return true end
        end
    end
    local direct = plot:FindFirstChild("Owner") or plot:FindFirstChild("Player")
    if direct then
        if direct:IsA("StringValue") and (direct.Value == lp.Name or direct.Value == lp.DisplayName) then return true
        elseif direct:IsA("ObjectValue") and direct.Value == lp then return true
        elseif direct:IsA("IntValue") and direct.Value == lp.UserId then return true
        elseif tostring(direct.Value) == lp.Name then return true end
    end
    local attr = plot:GetAttribute("Owner") or plot:GetAttribute("Player")
    if attr and (attr == lp.Name or attr == lp.DisplayName) then return true end
    local attrId = plot:GetAttribute("OwnerId") or plot:GetAttribute("UserId")
    if attrId and (attrId == lp.UserId or tostring(attrId) == tostring(lp.UserId)) then return true end
    if plot.Name == lp.Name or plot.Name == tostring(lp.UserId) then return true end
    local sign = plot:FindFirstChild("Sign", true) or plot:FindFirstChild("PlotSign", true)
    if sign then
        for _, obj in ipairs(sign:GetDescendants()) do
            if obj:IsA("TextLabel") and (obj.Text:find(lp.Name) or obj.Text:find(lp.DisplayName)) then return true end
        end
    end
    return false
end

function Plot.findHomePlot()
    local ws = S.Workspace
    local folders = {
        ws:FindFirstChild("Plots"), ws:FindFirstChild("PlayerPlots"),
        ws:FindFirstChild("Bases"), ws:FindFirstChild("Islands"),
        ws:FindFirstChild("Tycoons")
    }
    for _, folder in ipairs(folders) do
        if folder then
            for _, plot in ipairs(folder:GetChildren()) do
                if Plot.isOwner(plot) then return plot end
            end
        end
    end
    for _, child in ipairs(ws:GetChildren()) do
        if child:IsA("Model") and (child.Name:find("Plot") or child.Name:find("Base")) then
            if Plot.isOwner(child) then return child end
        end
    end
    return nil
end

function Plot.teleportAndDeposit()
    local plot = Plot.findHomePlot()
    if not plot then return false end
    Movement.stop()
    Utils.resetVelocity(Utils.getRootPart())
    local depositPoint = plot:FindFirstChild("Deposit", true)
        or plot:FindFirstChild("EggDeposit", true)
        or plot:FindFirstChild("Clear", true)
        or plot:FindFirstChild("Spawn", true)
        or plot:FindFirstChild("Base", true)
        or plot:FindFirstChild("Center", true)
        or plot.PrimaryPart
        or plot:FindFirstChildWhichIsA("BasePart")
        or plot
    local arrived = Movement.moveTo(depositPoint)
    Utils.resetVelocity(Utils.getRootPart())
    if arrived then
        task.wait(0.25)
        Interaction.trigger(depositPoint, AppConfig.HomeDepositWait)
    end
    return arrived
end

NS.Plot = Plot