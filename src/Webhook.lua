-- Webhook.lua — Discord notification (Legacy Embed)
local NS = getgenv().EggsESP
local AppConfig  = NS.Config
local S          = NS.Services
local StateStore = NS.StateStore
local Utils      = NS.Utils

local Webhook = {}

Webhook.Config = {
    Enabled   = false,
    Url       = "",
    Username  = "LuxuryXHUB",
    AvatarUrl = "",
    NotifyRareOnly = false,
    IncludeStats   = true,
    MinIntervalSeconds = 2,
}

local lastSentAt = 0
local sentCount = 0
local errorCount = 0

local function getPlayerInfo()
    local lp = S.LocalPlayer
    if not lp then return "Unknown" end
    return string.format("%s (@%s)\nID: `%d`", lp.DisplayName, lp.Name, lp.UserId)
end

local function getTimeString()
    return os.date("%H:%M:%S")
end

local function getHttpRequest()
    return (syn and syn.request)
        or (http and http.request)
        or (fluxus and fluxus.request)
        or (request)
        or http_request
end

function Webhook.Send(payload)
    if not Webhook.Config.Enabled then return false, "Disabled" end
    if Webhook.Config.Url == "" then return false, "No URL" end

    local now = os.clock()
    if (now - lastSentAt) < Webhook.Config.MinIntervalSeconds then
        return false, "Rate limited"
    end
    lastSentAt = now

    payload.username = payload.username or Webhook.Config.Username
    if Webhook.Config.AvatarUrl ~= "" and not payload.avatar_url then
        payload.avatar_url = Webhook.Config.AvatarUrl
    end

    local httpRequest = getHttpRequest()
    if not httpRequest then
        errorCount = errorCount + 1
        return false, "No HTTP function"
    end

    local ok, err = pcall(function()
        local body = game:GetService("HttpService"):JSONEncode(payload)
        local resp = httpRequest({
            Url = Webhook.Config.Url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
        if resp and resp.StatusCode and resp.StatusCode >= 400 then
            error("HTTP " .. tostring(resp.StatusCode) .. ": " .. tostring(resp.Body))
        end
    end)

    if ok then
        sentCount = sentCount + 1
        return true
    else
        errorCount = errorCount + 1
        warn("[Webhook] Send failed: " .. tostring(err))
        return false, err
    end
end

-- ⭐ MAIN — แจ้งเตือนตอนเก็บไข่ได้ (Legacy Embed)
function Webhook.NotifyEggCollected(eggName, isRare)
    if not Webhook.Config.Enabled then return false end
    if Webhook.Config.NotifyRareOnly and not isRare then
        return false, "Skipped (not rare)"
    end

    local color = isRare and 0xFFD700 or 0x00E676
    local title = isRare and "🌟 Rare Egg Collected!" or "🥚 Egg Collected!"

    local fields = {
        { name = "🥚 Egg", value = "**" .. eggName .. "**", inline = true },
        { name = "⏰ Time", value = getTimeString(), inline = true },
        { name = "👤 Player", value = getPlayerInfo(), inline = false },
    }

    if Webhook.Config.IncludeStats then
        local elapsed = os.time() - StateStore.sessionStartTime
        local mins = math.floor(elapsed / 60)
        local secs = elapsed % 60
        table.insert(fields, {
            name = "📊 Session Total",
            value = tostring(StateStore.totalEggsCollected) .. " eggs",
            inline = true
        })
        table.insert(fields, {
            name = "⏱️ Session Time",
            value = string.format("%02d:%02d", mins, secs),
            inline = true
        })
    end

    return Webhook.Send({
        embeds = {
            {
                title = title,
                color = color,
                fields = fields,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                footer = { text = "LuxuryXHUB v" .. AppConfig.Version }
            }
        }
    })
end

function Webhook.Test()
    local savedEnabled = Webhook.Config.Enabled
    Webhook.Config.Enabled = true
    lastSentAt = 0

    local ok = Webhook.Send({
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
                footer = { text = "LuxuryXHUB v" .. AppConfig.Version },
            }
        }
    })

    Webhook.Config.Enabled = savedEnabled
    return ok
end

function Webhook.GetStats()
    return { sent = sentCount, errors = errorCount }
end

NS.Webhook = Webhook