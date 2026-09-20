--[[
╭────────────────────────────────────────────────────────────────────────────────────╮
│                        Modular Script Loader (Multi-Game Ready)                    │
│              Auto-cache  ·  Auto-refresh  ·  Health check                         │
╰────────────────────────────────────────────────────────────────────────────────────╯
]]

-- ┌─────────────────────────────────────────────────────────────────┐
-- │  CONFIGURATION                                                  │
-- └─────────────────────────────────────────────────────────────────┘

local CONFIG = {
    BASE_URL    = "https://raw.githubusercontent.com/LostInSyntaxx/RideAPet/main/src/",
    VERSION_URL = "https://raw.githubusercontent.com/LostInSyntaxx/RideAPet/main/version.txt",
    CACHE_DIR   = "LuxuryXHUB",

    USE_DISK_CACHE = true,
    FORCE_REFRESH  = false,
    MAX_RETRIES    = 3,

    -- โมดูลสำหรับ Main System
    MODULES = {
        "LoadingScreen","Config","Services","State","Utils","Webhook",
        "Stability","Interaction","Movement","Plot","ESP","Farm","Rebirth","UI","Bootstrap",
    },

    REQUIRED = {
        "Config","Services","StateStore","Utils","Webhook",
        "ESP","Farm","Rebirth","Movement","Plot","UI",
    },

    NAMESPACE = "EggsESP",

    -- ── Multi-Game Routes ─────────────────────────────────────────
    GAME_ROUTES = {
        {
            name     = "Pull An Egg",
            url      = "https://raw.githubusercontent.com/LostInSyntaxx/RideAPet/main/scripts/pull_an_egg.lua",
            placeIds = { 70640255604878 },
            gameIds  = { 10649255304 },
        },
        {
            name      = "Ride A Pet",
            isDefault = true, -- หากไม่ตรงกับเกมอื่น ให้ใช้ระบบโมดูลของเกมนี้เป็นหลัก
            modules   = true,
        },
        -- {
        --     name     = "My Other Game",
        --     url      = "https://raw.githubusercontent.com/.../scripts/other_game.lua",
        --     placeIds = { 12345678 },
        --     gameIds  = { 87654321 },
        -- },
    },
}

-- ┌─────────────────────────────────────────────────────────────────┐
-- │  CAPABILITY DETECTION                                           │
-- └─────────────────────────────────────────────────────────────────┘

local CAP = {
    readfile   = (typeof(readfile)    == "function"),
    writefile  = (typeof(writefile)   == "function"),
    isfile     = (typeof(isfile)      == "function"),
    isfolder   = (typeof(isfolder)    == "function"),
    makefolder = (typeof(makefolder)  == "function"),
    delfile    = (typeof(delfile)     == "function"),
    httpget    = (typeof(game.HttpGet)== "function"),
    loadstring = (typeof(loadstring)  == "function"),
}

local DISK_CACHE_OK = CONFIG.USE_DISK_CACHE
    and CAP.readfile and CAP.writefile
    and CAP.isfile   and CAP.isfolder
    and CAP.makefolder

-- ┌─────────────────────────────────────────────────────────────────┐
-- │  LOGGER                                                         │
-- └─────────────────────────────────────────────────────────────────┘

local LOG_PREFIX = "[LuxuryXHUB]"
local Log = {}
function Log.info (msg) print(LOG_PREFIX .. "  " .. tostring(msg)) end
function Log.ok   (msg) print(LOG_PREFIX .. " ✓  " .. tostring(msg)) end
function Log.warn (msg) warn (LOG_PREFIX .. " ⚠  " .. tostring(msg)) end
function Log.err  (msg) warn (LOG_PREFIX .. " ✗  " .. tostring(msg)) end

-- ┌─────────────────────────────────────────────────────────────────┐
-- │  HELPERS & UTILS                                                │
-- └─────────────────────────────────────────────────────────────────┘

-- รอจนกว่า GameId และ PlaceId จะโหลดสมบูรณ์
local function waitForGameLoaded()
    local t0 = os.clock()
    while (game.PlaceId == 0 or game.GameId == 0) and (os.clock() - t0 < 5) do
        task.wait(0.1)
    end
end

local function httpGet(url)
    local lastErr
    for attempt = 1, CONFIG.MAX_RETRIES do
        local ok, result = pcall(function() return game:HttpGet(url, true) end)
        if ok and result and #result > 0 then return result end
        lastErr = result
        if attempt < CONFIG.MAX_RETRIES then task.wait(0.4 * attempt) end
    end
    Log.err("HTTP failed after " .. CONFIG.MAX_RETRIES .. " attempts -> " .. url)
    return nil
end

-- ตัดลบ UTF-8 BOM กันภาษา Lua อ่านสคริปต์แล้วเกิด Syntax Error
local function stripBOM(src)
    if src and src:sub(1, 3) == "\239\187\191" then
        return src:sub(4)
    end
    return src
end

-- ┌─────────────────────────────────────────────────────────────────┐
-- │  CACHE SYSTEM (Dynamic Sub-folder per Game)                     │
-- └─────────────────────────────────────────────────────────────────┘

local Cache = { memory = {}, dir = CONFIG.CACHE_DIR }

function Cache.init(subDir)
    if subDir then
        Cache.dir = CONFIG.CACHE_DIR .. "/" .. subDir:gsub("[%s%c%p]", "_")
    end
    if not DISK_CACHE_OK then return end
    if not isfolder(CONFIG.CACHE_DIR) then
        pcall(function() makefolder(CONFIG.CACHE_DIR) end)
    end
    if not isfolder(Cache.dir) then
        pcall(function() makefolder(Cache.dir) end)
    end
end

function Cache.read(name)
    if Cache.memory[name] then return Cache.memory[name] end
    if DISK_CACHE_OK then
        local path = Cache.dir .. "/" .. name .. ".lua"
        if isfile(path) then
            local ok, data = pcall(function() return readfile(path) end)
            if ok and data and #data > 0 then
                Cache.memory[name] = data
                return data
            end
        end
    end
    return nil
end

function Cache.write(name, data)
    if not data or #data == 0 then return end
    Cache.memory[name] = data
    if DISK_CACHE_OK then
        local path = Cache.dir .. "/" .. name .. ".lua"
        pcall(function() writefile(path, data) end)
    end
end

function Cache.clear()
    Cache.memory = {}
    if DISK_CACHE_OK and isfolder(Cache.dir) then
        for _, file in ipairs(CONFIG.MODULES) do
            local path = Cache.dir .. "/" .. file .. ".lua"
            if isfile(path) and CAP.delfile then
                pcall(function() delfile(path) end)
            end
        end
    end
end

-- ┌─────────────────────────────────────────────────────────────────┐
-- │  VERSION CHECK                                                  │
-- └─────────────────────────────────────────────────────────────────┘

local function checkVersion()
    if not CONFIG.VERSION_URL then return nil, false end
    local remoteVer = httpGet(CONFIG.VERSION_URL)
    if not remoteVer then return nil, false end
    remoteVer = remoteVer:match("^%s*(.-)%s*$")

    local localVer = nil
    if DISK_CACHE_OK then
        local path = Cache.dir .. "/_version.txt"
        if isfile(path) then
            local ok, data = pcall(function() return readfile(path) end)
            if ok then localVer = data:match("^%s*(.-)%s*$") end
        end
    else
        localVer = Cache.memory._version
    end

    if localVer ~= remoteVer then
        Log.info(("Version updated: %s -> %s"):format(tostring(localVer or "none"), remoteVer))
        return remoteVer, true
    end
    return remoteVer, false
end

local function saveVersion(ver)
    if not ver then return end
    if DISK_CACHE_OK then
        pcall(function() writefile(Cache.dir .. "/_version.txt", ver) end)
    end
    Cache.memory._version = ver
end

-- ┌─────────────────────────────────────────────────────────────────┐
-- │  ROUTER & EXECUTION                                             │
-- └─────────────────────────────────────────────────────────────────┘

local function matchRoute(route)
    local pid = game.PlaceId
    local gid = game.GameId

    for _, id in ipairs(route.placeIds or {}) do
        if pid == tonumber(id) then return true, "PlaceId" end
    end
    for _, id in ipairs(route.gameIds or {}) do
        if gid == tonumber(id) then return true, "GameId" end
    end
    return false, nil
end

local function fetchModule(name, forceRefresh)
    if not forceRefresh and not CONFIG.FORCE_REFRESH then
        local cached = Cache.read(name)
        if cached then return cached, "cache" end
    end
    local url = CONFIG.BASE_URL .. name .. ".lua"
    local src = httpGet(url)
    if not src then
        local cached = Cache.read(name)
        if cached then return cached, "stale" end
        return nil, "failed"
    end
    Cache.write(name, src)
    return src, "http"
end

local function compileAndRun(name, src)
    if not src or #src < 20 then
        Log.err("Source code invalid/empty: " .. name)
        return false
    end
    local safeChunkName = "@LuxuryXHUB/" .. name:gsub("[%s%c%p]", "_")
    local chunk, compileErr = loadstring(src, safeChunkName)
    if not chunk then
        Log.err("Compile Error [" .. name .. "]: " .. tostring(compileErr))
        return false
    end
    local ok, runtimeErr = pcall(chunk)
    if not ok then
        Log.err("Runtime Error [" .. name .. "]: " .. tostring(runtimeErr))
        return false
    end
    return true
end

local function runSingleScriptRoute(route, matchedBy)
    Log.info("🎮 Routing -> " .. route.name .. " (Matched: " .. tostring(matchedBy) .. ")")

    local src = httpGet(route.url)
    if not src then
        Log.err("Failed to download script for: " .. route.name)
        return false
    end

    src = stripBOM(src)

    -- แปลงชื่อเป็น safeChunkName ป้องกันช่องว่างและอักขระพิเศษทำพิษตอน loadstring
    local safeChunkName = "@" .. route.name:gsub("[%s%c%p]", "_")
    local fn, loadErr = loadstring(src, safeChunkName)
    if not fn then
        Log.err("Compile error in " .. route.name .. ": " .. tostring(loadErr))
        return false
    end

    local ok, runtimeErr = pcall(fn)
    if not ok then
        Log.err("Runtime error in " .. route.name .. ": " .. tostring(runtimeErr))
        return false
    end

    Log.ok(route.name .. " loaded successfully!")
    return true
end

-- ┌─────────────────────────────────────────────────────────────────┐
-- │  MAIN ENTRY POINT                                               │
-- └─────────────────────────────────────────────────────────────────┘

local function main()
    local t0 = os.clock()
    
    if not CAP.loadstring then
        Log.err("Executor does not support loadstring — process aborted")
        return
    end

    -- รอให้ ID ของเกมถูกโหลดเสร็จสิ้น
    waitForGameLoaded()

    Log.info("🔍 Checking Game... PlaceId: " .. tostring(game.PlaceId) .. " | GameId: " .. tostring(game.GameId))

    local selectedRoute = nil
    local matchedBy = nil

    -- 1. ค้นหา Route ที่ตรงกับ PlaceId / GameId
    for _, route in ipairs(CONFIG.GAME_ROUTES) do
        local matched, by = matchRoute(route)
        if matched then
            selectedRoute = route
            matchedBy = by
            break
        end
    end

    -- 2. ถ้าไม่เจอ ให้ใข้ Default Route (ถ้ามี)
    if not selectedRoute then
        for _, route in ipairs(CONFIG.GAME_ROUTES) do
            if route.isDefault then
                selectedRoute = route
                matchedBy = "Default Fallback"
                break
            end
        end
    end

    -- 3. เริ่มรันตามประเภทของ Route
    if selectedRoute then
        -- แบบ Script เดี่ยว (URL ตรง)
        if selectedRoute.url then
            local success = runSingleScriptRoute(selectedRoute, matchedBy)
            if success then return end
            Log.warn("Single script execution failed for " .. selectedRoute.name)
        
        -- แบบ Modular System
        elseif selectedRoute.modules then
            Log.info("🐾 Routing -> " .. selectedRoute.name .. " (Modular System)")
            
            Cache.init(selectedRoute.name)
            local newVer, needsRefresh = checkVersion()
            if needsRefresh then Cache.clear() end

            getgenv()[CONFIG.NAMESPACE] = getgenv()[CONFIG.NAMESPACE] or {}
            local NS = getgenv()[CONFIG.NAMESPACE]
            NS.Modules = NS.Modules or {}

            local total = #CONFIG.MODULES
            local stats = { cache = 0, http = 0, stale = 0, failed = 0 }

            for i, name in ipairs(CONFIG.MODULES) do
                local src, source = fetchModule(name, needsRefresh)
                if src then
                    local ok = compileAndRun(name, src)
                    if ok then
                        stats[source] = (stats[source] or 0) + 1
                    else
                        stats.failed = stats.failed + 1
                    end
                else
                    stats.failed = stats.failed + 1
                end
            end

            if newVer and stats.failed == 0 then saveVersion(newVer) end
            Log.ok(("Done in %.2fs | Cache: %d | Http: %d | Failed: %d"):format(os.clock() - t0, stats.cache, stats.http, stats.failed))
            return
        end
    end

    Log.err("No supported route or script found for PlaceId: " .. tostring(game.PlaceId))
end

-- รันโปรแกรมหลัก
local ok, err = pcall(main)
if not ok then
    warn("[LuxuryXHUB] ✗ Fatal Error: " .. tostring(err))
end