local NS = getgenv().EggsESP
local AppConfig = NS.Config
local S = NS.Services
local StateStore = NS.StateStore
local Utils = NS.Utils
local Movement = NS.Movement
local Interaction = NS.Interaction
local Plot = NS.Plot

local Farm = {}

function Farm.getReadyEggs()
    local found = {}
    local folder = S.RenderedEggsFolder
    if not folder then return found end
    local now = os.clock()
    for _, egg in ipairs(folder:GetChildren()) do
        if Utils.isValidEgg(egg) and StateStore.autoFarmEggs[egg.Name] then
            local cd = StateStore.eggCooldowns[egg]
            local onCooldown = (cd and now <= cd)
            if not onCooldown and not StateStore.autoFarmProcessed[egg] then
                table.insert(found, egg)
            end
        end
    end
    table.sort(found, function(a, b) return a.Name:lower() < b.Name:lower() end)
    return found
end

function Farm.findBestEgg()
    local folder = S.RenderedEggsFolder
    if not folder then return nil end
    local now = os.clock()
    local query = AppConfig.BestEggName:lower()
    for _, egg in ipairs(folder:GetChildren()) do
        local cd = StateStore.eggCooldowns[egg]
        local onCooldown = (cd and now <= cd)
        if not onCooldown and Utils.isValidEgg(egg) and string.find(egg.Name:lower(), query, 1, true) then
            return egg
        end
    end
    return nil
end

function Farm.stopAutoFarm()
    StateStore.autoFarmActive = false
    Movement.stop()
    if StateStore.autoFarmThread then
        pcall(function() task.cancel(StateStore.autoFarmThread) end)
        StateStore.autoFarmThread = nil
    end
    pcall(function()
        if S.VirtualInputManager then
            S.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end
    end)
end

function Farm.startAutoFarm(statusUpdater, stopButtonUpdater)
    Farm.stopAutoFarm()
    StateStore.autoFarmActive = true
    if stopButtonUpdater then stopButtonUpdater(true) end

    StateStore.autoFarmThread = task.spawn(function()
        while StateStore.autoFarmActive do
            local hasAny = false
            for _, v in pairs(StateStore.autoFarmEggs) do if v then hasAny = true; break end end
            if not hasAny then
                if statusUpdater then statusUpdater("No eggs selected", AppConfig.TextSecondary) end
                break
            end

            local readyEggs = Farm.getReadyEggs()
            if #readyEggs == 0 then
                if statusUpdater then statusUpdater("Waiting for eggs...", AppConfig.TextSecondary) end
                task.wait(1.0)
            else
                for _, egg in ipairs(readyEggs) do
                    if not StateStore.autoFarmActive then break end
                    -- getReadyEggs() already filters cooldowns and processed flags;
                    -- only re-validate the egg is still live in the workspace.
                    if Utils.isValidEgg(egg) then
                        local currentEggName = egg.Name
                        if statusUpdater then statusUpdater("Farming: " .. currentEggName, AppConfig.AccentGreen) end

                        local arrived = Movement.moveTo(egg)
                        if arrived and StateStore.autoFarmActive then
                            task.wait(0.2)
                            if StateStore.autoFarmActive and Utils.isValidEgg(egg) then
                                if statusUpdater then statusUpdater("Collecting " .. currentEggName .. "...", AppConfig.AccentGold) end
                                Interaction.trigger(egg, AppConfig.AutoFarmHoldTime)
                            end
                            StateStore.eggCooldowns[egg] = os.clock() + AppConfig.EggCooldownSeconds
                            task.wait(0.3)
                            if StateStore.autoFarmActive then
                                if statusUpdater then statusUpdater("Returning Home...", AppConfig.AccentBlue) end
                                Movement.stop()
                                local homeSuccess = Plot.teleportAndDeposit()
                                if homeSuccess then
                                    StateStore.autoFarmProcessed[egg] = true
                                    StateStore.addHistoryRecord(currentEggName)
                                    if statusUpdater then statusUpdater("Egg Deposited!", AppConfig.AccentGreen) end
                                else
                                    if statusUpdater then statusUpdater("Home Unreachable", AppConfig.AccentRed) end
                                end
                            end
                            task.wait(AppConfig.AutoEggDelay)
                        end
                    end
                end
            end
            task.wait(0.25)
        end
        StateStore.autoFarmThread = nil
        StateStore.autoFarmActive = false
        if stopButtonUpdater then stopButtonUpdater(false) end
        if statusUpdater then statusUpdater("AutoFarm Idle", AppConfig.TextSecondary) end
    end)
end

function Farm.stopAutoBestEgg()
    StateStore.autoBestEggActive = false
    Movement.stop()
    if StateStore.autoBestEggThread then
        pcall(function() task.cancel(StateStore.autoBestEggThread) end)
        StateStore.autoBestEggThread = nil
    end
    pcall(function()
        if S.VirtualInputManager then
            S.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end
    end)
end

function Farm.startAutoBestEgg(statusUpdater)
    Farm.stopAutoBestEgg()
    StateStore.autoBestEggActive = true
    StateStore.autoBestEggThread = task.spawn(function()
        while StateStore.autoBestEggActive do
            local egg = Farm.findBestEgg()
            if egg and egg.Parent then
                local currentEggName = egg.Name
                if statusUpdater then statusUpdater("Moving to " .. currentEggName, AppConfig.AccentGreen) end
                local arrived = Movement.moveTo(egg)
                if arrived and StateStore.autoBestEggActive then
                    task.wait(0.2)
                    if StateStore.autoBestEggActive and egg.Parent then
                        if statusUpdater then statusUpdater("Collecting...", AppConfig.AccentGold) end
                        Interaction.trigger(egg, AppConfig.AutoEggHoldTime)
                    end
                    StateStore.eggCooldowns[egg] = os.clock() + AppConfig.EggCooldownSeconds
                    task.wait(0.3)
                    if StateStore.autoBestEggActive then
                        if statusUpdater then statusUpdater("Returning Home...", AppConfig.AccentBlue) end
                        Movement.stop()
                        local ok = Plot.teleportAndDeposit()
                        if ok then
                            StateStore.addHistoryRecord(currentEggName)
                            if statusUpdater then statusUpdater("Best Egg Deposited!", AppConfig.AccentGreen) end
                        end
                    end
                    task.wait(AppConfig.AutoEggDelay)
                else
                    task.wait(0.5)
                end
            else
                if statusUpdater then statusUpdater("Searching: [" .. AppConfig.BestEggName .. "]...", AppConfig.TextSecondary) end
                task.wait(1.0)
            end
        end
        StateStore.autoBestEggThread = nil
        StateStore.autoBestEggActive = false
    end)
end

NS.Farm = Farm