--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║  RideAPet — Modular Loader                                   ║
    ║  Auto-cache + Auto-refresh + Retry + Health check            ║
    ╚══════════════════════════════════════════════════════════════╝
]]

local CONFIG = {
    BASE_URL    = "https://raw.githubusercontent.com/LostInSyntaxx/RideAPet/main/src/",
    VERSION_URL = "https://raw.githubusercontent.com/LostInSyntaxx/RideAPet/main/version.txt",
    CACHE_DIR   = "RideAPet_cache",
    USE_DISK_CACHE = true,
    FORCE_REFRESH = false,
    MAX_RETRIES = 3,

    MODULES = {
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
    REQUIRED = {
        "Config", "Services", "State", "Utils",
        "ESP", "Farm", "Rebirth", "Movement", "Plot", "UI",
    },
    NAMESPACE = "EggsESP",
}

local CAP = {
    readfile  = (typeof(readfile)  == "function"),
    writefile = (typeof(writefile) == "function"),
    isfile    = (typeof(isfile)    == "function"),
    isfolder  = (typeof(isfolder)  == "function"),
    makefolder= (typeof(makefolder)== "function"),
    delfile   = (typeof(delfile)   == "function"),
    httpget   = (typeof(game.HttpGet) == "function"),
    loadstring= (typeof(loadstring) == "function"),
}

local DISK_CACHE_OK = CONFIG.USE_DISK_CACHE
    and CAP.readfile and CAP.writefile and CAP.isfile and CAP.isfolder and CAP.makefolder

local Log = {}
local PREFIX = "[RideAPet]"
function Log.info(m) print(PREFIX .. " " .. tostring(m)) end
function Log.ok(m)   print(PREFIX .. " ✓ " .. tostring(m)) end
function Log.warn(m) warn(PREFIX .. " ⚠ " .. tostring(m)) end
function Log.err(m)  warn(PREFIX .. " ✗ " .. tostring(m)) end
function Log.debug(m) if CONFIG.FORCE_REFRESH then print(PREFIX .. " [dbg] " .. tostring(m)) end end

local function httpGet(url)
    local lastErr
    for attempt = 1, CONFIG.MAX_RETRIES do
        local ok, result = pcall(function() return game:HttpGet(url, true) end)
        if ok and result and #result > 0 then return result end
        lastErr = result
        if attempt < CONFIG.MAX_RETRIES then task.wait(0.4 * attempt) end
    end
    Log.err("HTTP failed: " .. url)
    return nil
end

local Cache = { memory = {} }

function Cache.init()
    if not DISK_CACHE_OK then
        Log.warn("Disk cache unavailable — in-memory only")
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
        Log.info("Version: local=" .. tostring(localVer) .. " remote=" .. remoteVer)
        return remoteVer, true
    end
    return remoteVer, false
end

local function saveVersion(ver)
    if not ver then return end
    if DISK_CACHE_OK then
        local path = CONFIG.CACHE_DIR .. "/_version.txt"
        pcall(function() writefile(path, ver) end)
    end
    Cache.memory._version = ver
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
        if cached then return cached, "stale-cache" end
        return nil, "failed"
    end
    Cache.write(name, src)
    return src, "http"
end

local function compileAndRun(name, src)
    if not src or #src < 20 then
        Log.err("Source too small: " .. name)
        return false
    end
    local chunk, err = loadstring(src, "@RideAPet/" .. name)
    if not chunk then
        Log.err("Compile error in " .. name .. ": " .. tostring(err))
        return false
    end
    local ok, runtimeErr = pcall(chunk)
    if not ok then
        Log.err("Runtime error in " .. name .. ": " .. tostring(runtimeErr))
        return false
    end
    return true
end

local function healthCheck(NS)
    local missing = {}
    for _, key in ipairs(CONFIG.REQUIRED) do
        if not NS[key] then table.insert(missing, key) end
    end
    if #missing > 0 then
        Log.err("Missing modules: " .. table.concat(missing, ", "))
        return false
    end
    Log.ok("Health check passed — all modules loaded")
    return true
end

local function main()
    local t0 = os.clock()

    print("")
    print("╔══════════════════════════════════════════════════════╗")
    print("║           RideAPet — Modular Loader                  ║")
    print("╚══════════════════════════════════════════════════════╝")
    print("")

    if not CAP.loadstring then
        Log.err("Executor doesn't support loadstring")
        return
    end

    Cache.init()

    local newVer, needsRefresh = checkVersion()
    if needsRefresh then
        Log.info("Pulling fresh modules...")
        Cache.clear()
    end

    getgenv()[CONFIG.NAMESPACE] = getgenv()[CONFIG.NAMESPACE] or {}
    local NS = getgenv()[CONFIG.NAMESPACE]
    NS.Modules = NS.Modules or {}

    local stats = { cache = 0, http = 0, stale = 0, failed = 0 }

    for i, name in ipairs(CONFIG.MODULES) do
        local src, source = fetchModule(name, needsRefresh)
        if not src then
            Log.err(string.format("[%d/%d] %s — FAILED", i, #CONFIG.MODULES, name))
            stats.failed = stats.failed + 1
        else
            local ok = compileAndRun(name, src)
            if ok then
                local icon = (source == "cache") and "💾" or (source == "http") and "🌐" or "♻️"
                Log.ok(string.format("[%d/%d] %s %s (%s, %d bytes)", i, #CONFIG.MODULES, icon, name, source, #src))
                stats[source == "stale-cache" and "stale" or source] = (stats[source == "stale-cache" and "stale" or source] or 0) + 1
            else
                stats.failed = stats.failed + 1
            end
        end
    end

    if newVer and stats.failed == 0 then saveVersion(newVer) end

    print("")
    healthCheck(NS)

    local dt = os.clock() - t0
    print("")
    Log.info(string.format("Done in %.2fs | cache:%d http:%d stale:%d failed:%d",
        dt, stats.cache, stats.http, stats.stale, stats.failed))
    print("")
end

local ok, err = pcall(main)
if not ok then
    Log.err("Fatal: " .. tostring(err))
end