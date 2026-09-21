--[[
    LuxuryXHUB — Webhook.lua
    Discord webhook integration with embed formatting.
    Rewritten:
      • getHttpRequest() result is cached after first successful find
      • Send() is always non-blocking (rate-limit wait moved to a queue task)
      • Removed triple NS.StateStore/NS.State/StateStore inconsistency
      • User-Agent spoofing retained for Cloudflare/Discord 403 prevention
]]

local NS         = getgenv().EggsESP or {}
getgenv().EggsESP    = NS
getgenv().LuxuryXHUB = NS

local AppConfig  = NS.Config       or {Version = "1.0.0"}
local S          = NS.Services     or {}
local StateStore = NS.StateStore   or NS.State or {}
local Utils      = NS.Utils        or {}

local Webhook = {}

Webhook.Config = {
    Enabled            = false,
    Url                = "",
    Username           = "LuxuryXHUB",
    AvatarUrl          = "",
    NotifyRareOnly     = false,
    IncludeStats       = true,
    MinIntervalSeconds = 2,
}

local _stats       = {sent = 0, errors = 0}
local _lastSentAt  = 0
local _httpRequest = nil   -- cached after first successful detection

-- ── HTTP request function resolver (cached) ──────────────────────────
local function getHttpRequest()
    if _httpRequest then return _httpRequest end

    local candidates = {
        function() return syn and type(syn.request)     == "function" and syn.request         end,
        function() return http and type(http.request)   == "function" and http.request         end,
        function() return fluxus and type(fluxus.request) == "function" and fluxus.request     end,
        function() local g = getgenv and getgenv() or _G
                   return g and type(g.request)         == "function" and g.request            end,
        function() local g = getgenv and getgenv() or _G
                   return g and type(g.http_request)    == "function" and g.http_request       end,
        function() local ok, r = pcall(function() return request end)
                   return ok and type(r) == "function" and r                                   end,
        function() local ok, r = pcall(function() return http_request end)
                   return ok and type(r) == "function" and r                                   end,
    }

    for _, fn in ipairs(candidates) do
        local ok, result = pcall(fn)
        if ok and result then
            _httpRequest = result
            return _httpRequest
        end
    end
    return nil
end

-- ── Helpers ───────────────────────────────────────────────────────────
local function sanitizeUrl(url)
    if type(url) ~= "string" then return "" end
    return url:match("^%s*(.-)%s*$") or ""
end

local function getTimeString()
    return os.date("%H:%M:%S")
end

local function getPlayerInfo()
    local lp = (S and S.LocalPlayer) or game:GetService("Players").LocalPlayer
    if not lp then return "Unknown" end
    return string.format("%s (@%s)\nID: `%s`",
        lp.DisplayName or "?", lp.Name or "?", tostring(lp.UserId or 0))
end

-- ── Core send (runs inside task.spawn — never blocks caller) ─────────
local function sendNow(payload)
    local url = sanitizeUrl(Webhook.Config.Url)
    if url == "" then return false, "No URL" end
    if not url:match("^https?://") then return false, "Invalid URL" end

    local httpRequest = getHttpRequest()
    if not httpRequest then return false, "No HTTP executor support" end

    payload.username  = payload.username  or Webhook.Config.Username
    if Webhook.Config.AvatarUrl ~= "" and not payload.avatar_url then
        payload.avatar_url = Webhook.Config.AvatarUrl
    end

    local hs   = S.HttpService or game:GetService("HttpService")
    local body = hs:JSONEncode(payload)
    local headers = {
        ["Content-Type"] = "application/json",
        ["User-Agent"]   = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                        .. "AppleWebKit/537.36 (KHTML, like Gecko) "
                        .. "Chrome/120.0.0.0 Safari/537.36",
        ["Accept"]       = "application/json",
    }
    local req = {
        Url = url, url = url, Method = "POST", method = "POST",
        Headers = headers, headers = headers, Body = body, body = body,
    }

    local ok, err = pcall(function()
        local resp = httpRequest(req)
        if not resp then error("No response") end

        local code = nil
        if type(resp) == "table" then
            code = resp.StatusCode or resp.status_code or resp.statusCode or resp.Status
        end
        if type(code) == "string" then
            code = tonumber(code:match("^(%d+)")) or code
        end
        if type(code) == "number" and (code < 200 or code >= 300) then
            local rbody = tostring((resp and (resp.Body or resp.body)) or "")
            error("HTTP " .. tostring(code) .. (rbody ~= "" and (": " .. rbody) or ""))
        end
    end)

    if ok then
        _stats.sent += 1
        return true
    else
        _stats.errors += 1
        warn("[Webhook] " .. tostring(err))
        return false, tostring(err)
    end
end

-- ── Public Send — always fire-and-forget (non-blocking) ─────────────
function Webhook.Send(payload, _legacy_isDirect)
    if not Webhook.Config.Enabled then return false, "Disabled" end

    local url = sanitizeUrl(Webhook.Config.Url)
    if url == "" then return false, "No URL" end

    -- Enqueue with rate-limit delay inside a spawned thread
    task.spawn(function()
        local now     = os.clock()
        local elapsed = now - _lastSentAt
        if elapsed < Webhook.Config.MinIntervalSeconds then
            task.wait(Webhook.Config.MinIntervalSeconds - elapsed)
        end
        _lastSentAt = os.clock()
        sendNow(payload)
    end)

    return true  -- fire-and-forget; result is async
end

-- ── Egg collected notification ────────────────────────────────────────
function Webhook.NotifyEggCollected(eggName, isRare)
    if not Webhook.Config.Enabled then return false, "Disabled" end
    if Webhook.Config.NotifyRareOnly and not isRare then return false, "Not rare" end

    local name  = (eggName and tostring(eggName) ~= "") and tostring(eggName) or "Egg"
    local color = isRare and 0xFFD700 or 0x00E676
    local title = isRare and "🌟 Rare Egg Collected!" or "🥚 Egg Collected!"

    local fields = {
        {name = "🥚 Egg",    value = "**" .. name .. "**", inline = true},
        {name = "⏰ Time",   value = getTimeString(),       inline = true},
        {name = "👤 Player", value = getPlayerInfo(),       inline = false},
    }

    if Webhook.Config.IncludeStats then
        local st         = NS.StateStore or StateStore
        local start      = (st and st.sessionStartTime) or os.time()
        local total      = (st and st.totalEggsCollected) or 0
        local elapsed    = math.max(0, os.time() - start)
        table.insert(fields, {name = "📊 Total", value = tostring(total) .. " eggs",
            inline = true})
        table.insert(fields, {name = "⏱️ Runtime",
            value = string.format("%02d:%02d", math.floor(elapsed/60), elapsed%60),
            inline = true})
    end

    local version = (NS.Config and NS.Config.Version) or AppConfig.Version or "1.0.0"

    return Webhook.Send({
        embeds = {{
            title     = title,
            color     = color,
            fields    = fields,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            footer    = {text = "LuxuryXHUB v" .. tostring(version)},
        }}
    })
end

-- ── Test ping ─────────────────────────────────────────────────────────
function Webhook.Test()
    local saved = Webhook.Config.Enabled
    Webhook.Config.Enabled = true
    _lastSentAt = 0

    local version = (NS.Config and NS.Config.Version) or AppConfig.Version or "1.0.0"
    local ok, err = sendNow({
        embeds = {{
            title       = "✅ Webhook Connected",
            description = "Notifications are active.",
            color       = 0x00E676,
            fields      = {
                {name = "👤 Player", value = getPlayerInfo(), inline = false},
                {name = "⏰ Time",   value = getTimeString(), inline = true},
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            footer    = {text = "LuxuryXHUB v" .. tostring(version)},
        }},
        username = Webhook.Config.Username,
    })

    Webhook.Config.Enabled = saved
    return ok, err
end

-- ── Stats ─────────────────────────────────────────────────────────────
function Webhook.GetStats()
    return {sent = _stats.sent, errors = _stats.errors}
end

NS.Webhook = Webhook
return Webhook
