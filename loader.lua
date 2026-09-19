--[[
╭────────────────────────────────────────────────────────────────────────────────────╮
│                                                                                    │
│  ##       ##     ## ##     ## ##     ## ########  ##    ##                         │
│  ##       ##     ##  ##   ##  ##     ## ##     ##  ##  ##                          │
│  ##       ##     ##   ## ##   ##     ## ##     ##   ####                           │
│  ##       ##     ##    ###    ##     ## ########     ##                            │
│  ##       ##     ##   ## ##   ##     ## ##   ##      ##                            │
│  ##       ##     ##  ##   ##  ##     ## ##    ##     ##                            │
│  ########  #######  ##     ##  #######  ##     ##    ##                            │
│                                                                                    │
│  ##     ## ##     ## ##     ## ########                                            │
│   ##   ##  ##     ## ##     ## ##     ##                                           │
│    ## ##   ##     ## ##     ## ##     ##                                           │
│     ###    ######### ##     ## ########                                            │
│    ## ##   ##     ## ##     ## ##     ##                                           │
│   ##   ##  ##     ## ##     ## ##     ##                                           │
│  ##     ## ##     ##  #######  ########                                            │
│                                                                                    │
│                        Modular Script Loader                                       │
│              Auto-cache  ·  Auto-refresh  ·  Health check                         │
│                                                                                    │
╰────────────────────────────────────────────────────────────────────────────────────╯
]]

-- ┌─────────────────────────────────────────────────────────────────┐
-- │  CONFIGURATION                                                  │
-- └─────────────────────────────────────────────────────────────────┘

local CONFIG = {
    BASE_URL    = "https://raw.githubusercontent.com/LostInSyntaxx/RideAPet/v1.0.8/src/",
    VERSION_URL = "https://raw.githubusercontent.com/LostInSyntaxx/RideAPet/v1.0.8/version.txt",
    CACHE_DIR   = "LuxuryXHUB_cache",

    USE_DISK_CACHE = true,
    FORCE_REFRESH  = false,
    MAX_RETRIES    = 3,

    -- ── Modules (load order matters) ──────────────────────────────
    MODULES = {
        "LoadingScreen",
        "Config",
        "Services",
        "State",
        "Utils",
        "Webhook",
        "Stability",
        "Interaction",
        "Movement",
        "Plot",
        "ESP",
        "Farm",
        "Rebirth",
        "UI",
        "Bootstrap",
    },

    -- ── Required for a healthy run ─────────────────────────────────
    REQUIRED = {
        "Config", "Services", "StateStore", "Utils",
        "ESP", "Farm", "Rebirth", "Movement", "Plot", "UI",
    },

    -- ⭐ สำคัญ! ต้องเป็น "EggsESP" (ไม่ใช่ "LuxuryXHUB")
    NAMESPACE = "EggsESP",
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
function Log.debug(msg)
    if CONFIG.FORCE_REFRESH then
        print(LOG_PREFIX .. " [dbg]  " .. tostring(msg))
    end
end

-- ┌─────────────────────────────────────────────────────────────────┐
-- │  HTTP HELPER  (retry + back-off)                                │
-- └─────────────────────────────────────────────────────────────────┘

local function httpGet(url)
    local lastErr
    for attempt = 1, CONFIG.MAX_RETRIES do
        local ok, result = pcall(function() return game:HttpGet(url, true) end)
        if ok and result and #result > 0 then return result end
        lastErr = result
        if attempt < CONFIG.MAX_RETRIES then task.wait(0.4 * attempt) end
    end
    Log.err("HTTP failed after " .. CONFIG.MAX_RETRIES .. " attempts → " .. url)
    return nil
end

-- ┌─────────────────────────────────────────────────────────────────┐
-- │  CACHE  (memory + optional disk)                                │
-- └─────────────────────────────────────────────────────────────────┘

local Cache = { memory = {} }

function Cache.init()
    if not DISK_CACHE_OK then
        Log.warn("Disk cache unavailable — running in-memory only")
        return
    end
    if not isfolder(CONFIG.CACHE_DIR) then
        pcall(function() makefolder(CONFIG.CACHE_DIR) end)
    end
end

function Cache.read(name)
    if Cache.memory[name] then return Cache.memory[name] end
    if DISK_CACHE_OK then
        local path = CONFIG.CACHE_DIR .. "/" .. name .. ".lua"
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
        local path = CONFIG.CACHE_DIR .. "/" .. name .. ".lua"
        pcall(function() writefile(path, data) end)
    end
end

function Cache.clear()
    Cache.memory = {}
    if DISK_CACHE_OK and isfolder(CONFIG.CACHE_DIR) then
        for _, file in ipairs(CONFIG.MODULES) do
            local path = CONFIG.CACHE_DIR .. "/" .. file .. ".lua"
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
        local path = CONFIG.CACHE_DIR .. "/_version.txt"
        if isfile(path) then
            local ok, data = pcall(function() return readfile(path) end)
            if ok then localVer = data:match("^%s*(.-)%s*$") end
        end
    else
        localVer = Cache.memory._version
    end

    if localVer ~= remoteVer then
        Log.info(("Version changed  %s  →  %s"):format(
            tostring(localVer) == "nil" and "none" or tostring(localVer),
            remoteVer
        ))
        return remoteVer, true
    end

    return remoteVer, false
end

local function saveVersion(ver)
    if not ver then return end
    if DISK_CACHE_OK then
        pcall(function()
            writefile(CONFIG.CACHE_DIR .. "/_version.txt", ver)
        end)
    end
    Cache.memory._version = ver
end

-- ┌─────────────────────────────────────────────────────────────────┐
-- │  MODULE FETCH                                                   │
-- └─────────────────────────────────────────────────────────────────┘

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

-- ┌─────────────────────────────────────────────────────────────────┐
-- │  COMPILE & EXECUTE                                              │
-- └─────────────────────────────────────────────────────────────────┘

local function compileAndRun(name, src)
    if not src or #src < 20 then
        Log.err("Source too small to be valid: " .. name)
        return false
    end

    local chunk, compileErr = loadstring(src, "@LuxuryXHUB/" .. name)
    if not chunk then
        Log.err("Compile error in " .. name .. ": " .. tostring(compileErr))
        return false
    end

    local ok, runtimeErr = pcall(chunk)
    if not ok then
        Log.err("Runtime error in " .. name .. ": " .. tostring(runtimeErr))
        return false
    end

    return true
end

-- ┌─────────────────────────────────────────────────────────────────┐
-- │  HEALTH CHECK                                                   │
-- └─────────────────────────────────────────────────────────────────┘

local function healthCheck(NS)
    local missing = {}
    for _, key in ipairs(CONFIG.REQUIRED) do
        if not NS[key] then
            table.insert(missing, key)
        end
    end

    if #missing > 0 then
        Log.err("Health check FAILED — missing: " .. table.concat(missing, ", "))
        return false
    end

    Log.ok("Health check passed — all required modules present")
    return true
end

-- ┌─────────────────────────────────────────────────────────────────┐
-- │  MAIN                                                           │
-- └─────────────────────────────────────────────────────────────────┘

local function main()
    local t0 = os.clock()

    print("")
    print("╭────────────────────────────────────────────────────────────────────────────────────╮")
    print("│                                                                                    │")
    print("│  ##       ##     ## ##     ## ##     ## ########  ##    ##                         │")
    print("│  ##       ##     ##  ##   ##  ##     ## ##     ##  ##  ##                          │")
    print("│  ##       ##     ##   ## ##   ##     ## ##     ##   ####                           │")
    print("│  ##       ##     ##    ###    ##     ## ########     ##                            │")
    print("│  ##       ##     ##   ## ##   ##     ## ##   ##      ##                            │")
    print("│  ##       ##     ##  ##   ##  ##     ## ##    ##     ##                            │")
    print("│  ########  #######  ##     ##  #######  ##     ##    ##                            │")
    print("│                                                                                    │")
    print("│  ##     ## ##     ## ##     ## ########                                            │")
    print("│   ##   ##  ##     ## ##     ## ##     ##                                           │")
    print("│    ## ##   ##     ## ##     ## ##     ##                                           │")
    print("│     ###    ######### ##     ## ########                                            │")
    print("│    ## ##   ##     ## ##     ## ##     ##                                           │")
    print("│   ##   ##  ##     ## ##     ## ##     ##                                           │")
    print("│  ##     ## ##     ##  #######  ########                                            │")
    print("│                                                                                    │")
    print("│                        Modular Script Loader                                       │")
    print("│              Auto-cache  ·  Auto-refresh  ·  Health check                         │")
    print("│                                                                                    │")
    print("╰────────────────────────────────────────────────────────────────────────────────────╯")
    print("")

    -- ── Pre-flight ────────────────────────────────────────────────
    if not CAP.loadstring then
        Log.err("Executor does not support loadstring — aborting")
        return
    end

    -- ── Cache init ────────────────────────────────────────────────
    Cache.init()

    -- ── Version check ─────────────────────────────────────────────
    local newVer, needsRefresh = checkVersion()
    if needsRefresh then
        Log.info("New version detected — clearing cache and pulling fresh modules")
        Cache.clear()
    else
        Log.info("Version up-to-date — using cache where available")
    end

    -- ── Namespace ─────────────────────────────────────────────────
    getgenv()[CONFIG.NAMESPACE] = getgenv()[CONFIG.NAMESPACE] or {}
    local NS = getgenv()[CONFIG.NAMESPACE]
    NS.Modules = NS.Modules or {}

    -- ⭐ โหลด LoadingScreen.lua ก่อน (เป็น module แรก)
    local firstSrc = httpGet(CONFIG.BASE_URL .. "LoadingScreen.lua")
    if firstSrc and #firstSrc > 20 then
        local chunk = loadstring(firstSrc, "@LuxuryXHUB/LoadingScreen")
        if chunk then
            local ok, err = pcall(chunk)
            if ok then
                Cache.write("LoadingScreen", firstSrc)
            else
                Log.warn("LoadingScreen error: " .. tostring(err))
            end
        end
    end

    -- ⭐ แสดง Loading Screen
    local loadingScreen = NS.LoadingScreen
    if loadingScreen and loadingScreen.Show then
        loadingScreen.Show()
    end

    -- ── Module loading ────────────────────────────────────────────
    local total  = #CONFIG.MODULES
    local stats  = { cache = 0, http = 0, stale = 0, failed = 0 }
    local SOURCE_ICON = { cache = "💾", http = "🌐", stale = "♻️", failed = "✗" }

    print("")
    Log.info(("Loading %d modules…"):format(total))
    print("")

    for i, name in ipairs(CONFIG.MODULES) do
        local progress = ("[%02d/%02d]"):format(i, total)

        -- ⭐ ข้าม LoadingScreen เพราะโหลดไปแล้ว
        if name == "LoadingScreen" then
            stats.cache = stats.cache + 1
            Log.ok(progress .. "  💾  LoadingScreen  (pre-loaded)")

            if loadingScreen and loadingScreen.Update then
                loadingScreen.Update(
                    (i / total) * 100,
                    "📦 Loading modules...",
                    "(" .. name .. ")"
                )
            end
        else
            local src, source = fetchModule(name, needsRefresh)
            local icon = SOURCE_ICON[source] or "?"

            if not src then
                Log.err(progress .. "  " .. name .. "  — FAILED")
                stats.failed = stats.failed + 1

                if loadingScreen and loadingScreen.Update then
                    loadingScreen.Update(
                        (i / total) * 100,
                        "⚠️ Error loading " .. name,
                        "(" .. name .. ")"
                    )
                end
            else
                local ok = compileAndRun(name, src)
                if ok then
                    local key = (source == "stale") and "stale" or source
                    stats[key] = (stats[key] or 0) + 1
                    Log.ok(("%s  %s  %s  (%s · %d B)"):format(
                        progress, icon, name, source, #src
                    ))

                    -- ⭐ อัปเดต Loading Screen
                    if loadingScreen and loadingScreen.Update then
                        loadingScreen.Update(
                            (i / total) * 100,
                            "📦 Loading modules...",
                            "(" .. name .. ")"
                        )
                    end
                else
                    stats.failed = stats.failed + 1
                end
            end
        end
    end

    -- ⭐ ปิด Loading Screen (Complete)
    if loadingScreen and loadingScreen.Complete then
        task.wait(0.3)
        loadingScreen.Complete()
    end

    -- ── Persist version only if everything succeeded ───────────────
    if newVer and stats.failed == 0 then
        saveVersion(newVer)
    end

    -- ── Health check ──────────────────────────────────────────────
    print("")
    healthCheck(NS)

    -- ── Summary ───────────────────────────────────────────────────
    local dt = os.clock() - t0
    print("")
    print("╭────────────────────────────────────────────────────────────────────────────────────╮")
    print(("│  Done in %.2fs   💾 cache %-3d  🌐 http %-3d  ♻️  stale %-3d  ✗ failed %-3d │")
        :format(dt, stats.cache, stats.http, stats.stale, stats.failed))
    print("╰────────────────────────────────────────────────────────────────────────────────────╯")
    print("")
end

-- ┌─────────────────────────────────────────────────────────────────┐
-- │  ENTRY POINT  (guarded)                                         │
-- └─────────────────────────────────────────────────────────────────┘

local ok, err = pcall(main)
if not ok then
    warn("[LuxuryXHUB] ✗  Fatal error: " .. tostring(err))
end