-- State.lua — StateStore
local NS = getgenv().EggsESP
local AppConfig = NS.Config
local S = NS.Services

local StateStore = {
    mainESPActive = false,
    autoBestEggActive = false, autoBestEggThread = nil,
    autoFarmActive = false, autoFarmThread = nil,
    autoRebirthActive = false, autoRebirthThread = nil,
    missingRebirthEggs = {},
    antiAFKActive = true,
    movementActive = false,
    isMobileMode = false,
    isMinimized = false,
    listeningForKey = false,

    movementMode = "AutoFarm",
    currentSearchQuery = "",
    sortMode = "Name",
    tpKeybind = Enum.KeyCode.T,

    autoFarmEggs = {},
    autoFarmProcessed = setmetatable({}, { __mode = "k" }),
    eggCooldowns = setmetatable({}, { __mode = "k" }),
    eggData = setmetatable({}, { __mode = "k" }),

    farmHistory = {},
    onHistoryUpdated = nil,

    sessionStartTime = os.time(),
    totalEggsCollected = 0,
    onTimeUpdated = nil,

    movementHumanoid = nil,
    noclipConnection = nil,
    antiAFKConnection = nil,

    recentAlerts = {},
    _connections = {},
    _sliderCounter = 0,
    windowMode = "PC",
    screenGui = nil,
}

function StateStore.track(conn)
    if not conn then return conn end
    table.insert(StateStore._connections, conn)
    return conn
end

function StateStore.addHistoryRecord(eggName)
    local isRare = false
    local lower = eggName:lower()
    for _, kw in ipairs(AppConfig.RareKeywords) do
        if string.find(lower, kw, 1, true) then isRare = true; break end
    end

    table.insert(StateStore.farmHistory, 1, {
        name = eggName, time = os.date("%H:%M:%S"), isRare = isRare
    })
    if #StateStore.farmHistory > AppConfig.MaxHistoryLogs then
        table.remove(StateStore.farmHistory)
    end

    StateStore.totalEggsCollected = StateStore.totalEggsCollected + 1
    if StateStore.onHistoryUpdated then StateStore.onHistoryUpdated() end

    -- ⭐ Webhook notification
    if NS.Webhook then
        task.spawn(function()
            pcall(function()
                NS.Webhook.NotifyEggCollected(eggName, isRare)
            end)
        end)
    end
end

function StateStore.shouldAlert(eggName)
    local now = os.clock()
    local last = StateStore.recentAlerts[eggName]
    if last and (now - last) < AppConfig.AlertDedupeSeconds then return false end
    StateStore.recentAlerts[eggName] = now
    return true
end

function StateStore.reset()
    StateStore.mainESPActive = false
    StateStore.autoBestEggActive = false
    StateStore.autoFarmActive = false
    StateStore.autoRebirthActive = false
    StateStore.movementActive = false
    StateStore.isMinimized = false
    StateStore.listeningForKey = false
    StateStore.autoBestEggThread = nil
    StateStore.autoFarmThread = nil
    StateStore.autoRebirthThread = nil
    StateStore.movementHumanoid = nil
    StateStore.onHistoryUpdated = nil
    StateStore.onTimeUpdated = nil
    StateStore.screenGui = nil
    table.clear(StateStore.autoFarmEggs)
    table.clear(StateStore.farmHistory)
    table.clear(StateStore.recentAlerts)
    table.clear(StateStore.missingRebirthEggs)
end

NS.StateStore = StateStore
NS.State = StateStore  -- ⭐ alias สำหรับ loader REQUIRED check