-- Webhook.lua — Discord notification (Legacy Embed)
local NS = getgenv().EggsESP or getgenv().LuxuryXHUB or {}
getgenv().EggsESP = NS
getgenv().LuxuryXHUB = NS

local AppConfig  = NS.Config or { Version = "1.0.0" }
local S          = NS.Services or {}
local StateStore = NS.StateStore or NS.State or {}
local Utils      = NS.Utils or {}

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

local lastSentAt = 0
local sentCount = 0
local errorCount = 0

local function getPlayerInfo()
    local lp = (S and S.LocalPlayer) or (game:GetService("Players") and game:GetService("Players").LocalPlayer)
    if not lp then return "Unknown" end
    local displayName = lp.DisplayName or "Unknown"
    local name = lp.Name or "Unknown"
    local userId = tostring(lp.UserId or 0)
    return string.format("%s (@%s)\nID: `%s`", displayName, name, userId)
end

local function getTimeString()
    return os.date("%H:%M:%S")
end

local function getHttpRequest()
    if syn and type(syn.request) == "function" then return syn.request end
    if http and type(http.request) == "function" then return http.request end
    if fluxus and type(fluxus.request) == "function" then return fluxus.request end

    local genv = (getgenv and getgenv()) or _G
    if genv then
        if type(genv.request) == "function" then return genv.request end
        if type(genv.http_request) == "function" then return genv.http_request end
        if genv.syn and type(genv.syn.request) == "function" then return genv.syn.request end
        if genv.http and type(genv.http.request) == "function" then return genv.http.request end
        if genv.fluxus and type(genv.fluxus.request) == "function" then return genv.fluxus.request end
    end

    if typeof and typeof(request) == "function" then return request end
    if typeof and typeof(http_request) == "function" then return http_request end

    local ok1, r1 = pcall(function() return request end)
    if ok1 and type(r1) == "function" then return r1 end

    local ok2, r2 = pcall(function() return http_request end)
    if ok2 and type(r2) == "function" then return r2 end

    return nil
end

local function sanitizeUrl(url)
    if not url or type(url) ~= "string" then return "" end
    return url:match("^%s*(.-)%s*$") or ""
end

function Webhook.Send(payload, isDirect)
    if not Webhook.Config.Enabled then
        return false, "Disabled"
    end

    local url = sanitizeUrl(Webhook.Config.Url)
    if url == "" then
        return false, "No URL"
    end
    if not (url:find("^https?://") or url:find("^http://")) then
        return false, "Invalid URL (must start with http:// or https://)"
    end

    -- Rate limiting: wait remaining interval if called rapidly, unless isDirect is true
    local now = os.clock()
    local elapsed = now - lastSentAt
    if elapsed < Webhook.Config.MinIntervalSeconds then
        if not isDirect then
            task.wait(Webhook.Config.MinIntervalSeconds - elapsed)
        end
    end
    lastSentAt = os.clock()

    payload = payload or {}
    payload.username = payload.username or Webhook.Config.Username
    if Webhook.Config.AvatarUrl ~= "" and not payload.avatar_url then
        payload.avatar_url = Webhook.Config.AvatarUrl
    end

    local httpRequest = getHttpRequest()
    if not httpRequest then
        errorCount = errorCount + 1
        return false, "Executor does not support HTTP requests"
    end

    local ok, err = pcall(function()
        local httpService = game:GetService("HttpService")
        local body = httpService:JSONEncode(payload)

        local headers = {
            ["Content-Type"] = "application/json",
            ["User-Agent"]   = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            ["Accept"]       = "application/json",
        }

        local req = {
            Url     = url,
            url     = url,
            Method  = "POST",
            method  = "POST",
            Headers = headers,
            headers = headers,
            Body    = body,
            body    = body,
        }

        local resp = httpRequest(req)
        if not resp then
            error("No response from HTTP request")
        end

        local statusCode = nil
        local respBody = ""
        if type(resp) == "table" then
            statusCode = resp.StatusCode or resp.status_code or resp.statusCode or resp.Status
            respBody = tostring(resp.Body or resp.body or "")
        end

        if type(statusCode) == "string" then
            statusCode = tonumber(statusCode:match("^(%d+)")) or statusCode
        end

        if type(statusCode) == "number" and (statusCode < 200 or statusCode >= 300) then
            error("HTTP " .. tostring(statusCode) .. (respBody ~= "" and (": " .. respBody) or ""))
        end
    end)

    if ok then
        sentCount = sentCount + 1
        return true
    else
        errorCount = errorCount + 1
        warn("[Webhook] Send failed: " .. tostring(err))
        return false, tostring(err)
    end
end

-- ⭐ MAIN — แจ้งเตือนตอนเก็บไข่ได้ (Legacy Embed)
function Webhook.NotifyEggCollected(eggName, isRare)
    if not Webhook.Config.Enabled then return false, "Disabled" end
    if Webhook.Config.NotifyRareOnly and not isRare then
        return false, "Skipped (not rare)"
    end

    local safeEggName = (eggName and tostring(eggName) ~= "") and tostring(eggName) or "Egg"
    local color = isRare and 0xFFD700 or 0x00E676
    local title = isRare and "🌟 Rare Egg Collected!" or "🥚 Egg Collected!"

    local fields = {
        { name = "🥚 Egg", value = "**" .. safeEggName .. "**", inline = true },
        { name = "⏰ Time", value = getTimeString(), inline = true },
        { name = "👤 Player", value = getPlayerInfo(), inline = false },
    }

    if Webhook.Config.IncludeStats then
        local st = NS.StateStore or NS.State or StateStore
        local startTime = (st and st.sessionStartTime) or os.time()
        local totalEggs = (st and st.totalEggsCollected) or 0
        local elapsed = math.max(0, os.time() - startTime)
        local mins = math.floor(elapsed / 60)
        local secs = elapsed % 60
        table.insert(fields, {
            name = "📊 Session Total",
            value = tostring(totalEggs) .. " eggs",
            inline = true
        })
        table.insert(fields, {
            name = "⏱️ Session Time",
            value = string.format("%02d:%02d", mins, secs),
            inline = true
        })
    end

    local version = (NS.Config and NS.Config.Version) or (AppConfig and AppConfig.Version) or "1.0.0"

    return Webhook.Send({
        embeds = {
            {
                title = title,
                color = color,
                fields = fields,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                footer = { text = "LuxuryXHUB v" .. tostring(version) }
            }
        }
    })
end

function Webhook.Test()
    local savedEnabled = Webhook.Config.Enabled
    Webhook.Config.Enabled = true
    lastSentAt = 0

    local version = (NS.Config and NS.Config.Version) or (AppConfig and AppConfig.Version) or "1.0.0"

    local ok, err = Webhook.Send({
        embeds = {
            {
                title = "✅ Webhook Connected",
                description = "You will now receive notifications when eggs are collected.",
                color = 0x00E676,
                fields = {
                    { name = "👤 Player", value = getPlayerInfo(), inline = false },
                    { name = "⏰ Time", value = getTimeString(), inline = true },
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                footer = { text = "LuxuryXHUB v" .. tostring(version) },
            }
        }
    }, true)

    Webhook.Config.Enabled = savedEnabled
    return ok, err
end

function Webhook.GetStats()
    return { sent = sentCount, errors = errorCount }
end

NS.Webhook = Webhook
return Webhook