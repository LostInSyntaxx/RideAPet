local NS = getgenv().EggsESP
local S = NS.Services
local StateStore = NS.StateStore

local Stability = {}

function Stability.setupAntiAFK(enable)
    StateStore.antiAFKActive = enable
    if StateStore.antiAFKConnection then
        pcall(function() StateStore.antiAFKConnection:Disconnect() end)
        StateStore.antiAFKConnection = nil
    end
    if enable then
        StateStore.antiAFKConnection = S.LocalPlayer.Idled:Connect(function()
            if not StateStore.antiAFKActive then return end
            pcall(function()
                if S.VirtualUser then
                    S.VirtualUser:CaptureController()
                    S.VirtualUser:ClickButton2(Vector2.zero)
                elseif S.VirtualInputManager then
                    S.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Unknown, false, game)
                    task.wait(0.05)
                    S.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Unknown, false, game)
                end
            end)
        end)
    end
end

function Stability.setupAutoRejoin()
    local function queueScript()
        if S.QueueOnTeleport then
            pcall(function()
                S.QueueOnTeleport([[
                    task.wait(3)
                    pcall(function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/LostInSynntaxx/RideAPet/main/loader.lua"))()
                    end)
                ]])
            end)
        end
    end

    pcall(function()
        StateStore.track(S.GuiService.ErrorMessageChanged:Connect(function(msg)
            if msg and #msg > 0 then
                queueScript()
                task.wait(2.5)
                pcall(function()
                    if #S.Players:GetPlayers() <= 1 then
                        S.TeleportService:Teleport(game.PlaceId, S.LocalPlayer)
                    else
                        S.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, S.LocalPlayer)
                    end
                end)
            end
        end))
    end)

    task.spawn(function()
        pcall(function()
            local promptOverlay = S.CoreGui:WaitForChild("RobloxPromptGui", 8)
                and S.CoreGui.RobloxPromptGui:WaitForChild("promptOverlay", 8)
            if promptOverlay then
                StateStore.track(promptOverlay.ChildAdded:Connect(function(child)
                    if child.Name == "ErrorPrompt" then
                        queueScript()
                        task.wait(2)
                        pcall(function()
                            S.TeleportService:Teleport(game.PlaceId, S.LocalPlayer)
                        end)
                    end
                end))
            end
        end)
    end)
end

NS.Stability = Stability