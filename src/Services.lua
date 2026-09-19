local NS = getgenv().EggsESP

local S = {}
S.Players            = game:GetService("Players")
S.TweenService       = game:GetService("TweenService")
S.RunService         = game:GetService("RunService")
S.UserInputService   = game:GetService("UserInputService")
S.TeleportService    = game:GetService("TeleportService")
S.GuiService         = game:GetService("GuiService")
S.CoreGui            = game:GetService("CoreGui")
S.Workspace          = game:GetService("Workspace")
S.ReplicatedStorage  = game:GetService("ReplicatedStorage")
S.LocalPlayer        = S.Players.LocalPlayer

S.VirtualInputManager = nil
pcall(function() S.VirtualInputManager = game:GetService("VirtualInputManager") end)
S.VirtualUser = nil
pcall(function() S.VirtualUser = game:GetService("VirtualUser") end)

local function getTargetParent()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return S.LocalPlayer:WaitForChild("PlayerGui")
end
S.TargetParent = getTargetParent()

S.QueueOnTeleport = (syn and syn.queue_on_teleport)
    or (queue_on_teleport)
    or (Fluxus and Fluxus.queue_on_teleport)

S.RenderedEggsFolder = S.Workspace:WaitForChild("RenderedEggs", 8)

NS.Services = S