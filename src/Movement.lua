local NS = getgenv().EggsESP
local AppConfig = NS.Config
local S = NS.Services
local StateStore = NS.StateStore
local Utils = NS.Utils

local Movement = {}

function Movement.setNoclip(enabled)
    if StateStore.noclipConnection then
        pcall(function() StateStore.noclipConnection:Disconnect() end)
        StateStore.noclipConnection = nil
    end
    local character = Utils.getCharacter()
    if not character then return end
    if enabled then
        StateStore.noclipConnection = S.RunService.Stepped:Connect(function()
            local char = Utils.getCharacter()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart"
                and not part:IsA("Accessory") and not part.Parent:IsA("Accessory") then
                part.CanCollide = true
            end
        end
    end
end

function Movement.stop()
    StateStore.movementActive = false
    if StateStore.movementHumanoid and StateStore.movementHumanoid.Parent then
        StateStore.movementHumanoid.AutoRotate = true
    end
    StateStore.movementHumanoid = nil
    Movement.setNoclip(false)
    Utils.resetVelocity(Utils.getRootPart())
end

function Movement.teleportTo(target)
    local root = Utils.getRootPart()
    if not root then return false end
    local targetCFrame = Utils.getTargetCFrame(target)
    if not targetCFrame then return false end
    Utils.resetVelocity(root)
    root.CFrame = targetCFrame * CFrame.new(0, AppConfig.TPHeight, 0)
    Utils.resetVelocity(root)
    return true
end

function Movement.moveTo(target)
    if StateStore.movementMode == "Teleport" then
        return Movement.teleportTo(target)
    end
    if StateStore.movementActive then return false end

    local root = Utils.getRootPart()
    local humanoid = Utils.getHumanoid()
    local targetCFrame = Utils.getTargetCFrame(target)
    if not root or not humanoid or not targetCFrame or humanoid.Health <= 0 then return false end

    local destination = targetCFrame.Position + Vector3.new(0, AppConfig.TPHeight, 0)
    local startDistance = (root.Position - destination).Magnitude

    if startDistance <= 2.8 then
        Utils.resetVelocity(root)
        root.CFrame = targetCFrame * CFrame.new(0, AppConfig.TPHeight, 0)
        return true
    end

    StateStore.movementActive = true
    StateStore.movementHumanoid = humanoid
    local oldAutoRotate = humanoid.AutoRotate
    local success = false
    local startTime = os.clock()
    -- Add a generous fixed buffer (5s) on top of the travel estimate so
    -- server-lag frames or a single respawn don't prematurely time out movement.
    local maxTime = math.max(4.0, (startDistance / AppConfig.MovementSpeed) + (AppConfig.MovementTimeBuffer or 5.0))
    local lastCheckPos = root.Position
    local lastCheckTime = os.clock()

    Movement.setNoclip(true)
    humanoid.AutoRotate = false

    while StateStore.movementActive and (os.clock() - startTime <= maxTime) do
        if not target or not target.Parent or humanoid.Health <= 0 then break end
        if Utils.getRootPart() ~= root then break end

        local curTargetCF = Utils.getTargetCFrame(target)
        if curTargetCF then
            destination = curTargetCF.Position + Vector3.new(0, AppConfig.TPHeight, 0)
        end

        local offset = destination - root.Position
        local distance = offset.Magnitude

        if distance <= 2.8 then
            Utils.resetVelocity(root)
            root.CFrame = (curTargetCF or targetCFrame) * CFrame.new(0, AppConfig.TPHeight, 0)
            success = true
            break
        end

        if os.clock() - lastCheckTime >= AppConfig.AntiStuckThreshold then
            if (root.Position - lastCheckPos).Magnitude < 1.2 then
                root.CFrame = root.CFrame * CFrame.new(0, 4, 0)
                Movement.setNoclip(true)
                Utils.resetVelocity(root)
            end
            lastCheckPos = root.Position
            lastCheckTime = os.clock()
        end

        local dt = S.RunService.Heartbeat:Wait()
        local step = math.min(distance, AppConfig.MovementSpeed * dt)
        Utils.resetVelocity(root)
        local newPos = root.Position + (offset.Unit * step)
        if (destination - newPos).Magnitude > 0.08 then
            root.CFrame = CFrame.lookAt(newPos, destination)
        else
            root.CFrame = (curTargetCF or targetCFrame) * CFrame.new(0, AppConfig.TPHeight, 0)
            success = true
            break
        end
    end

    StateStore.movementActive = false
    if humanoid and humanoid.Parent then humanoid.AutoRotate = oldAutoRotate end
    StateStore.movementHumanoid = nil
    Movement.setNoclip(false)
    Utils.resetVelocity(root)
    return success
end

NS.Movement = Movement