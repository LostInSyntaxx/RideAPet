-- src/Webhook.lua
-- Discord Webhook — Components V2 + Roblox User ID

local NS = getgenv().EggsESP
local AppConfig  = NS.Config
local S          = NS.Services
local StateStore = NS.StateStore
local Utils      = NS.Utils

local Webhook = {}

-- ═══════════════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════════════
Webhook.Config = {
    Enabled   = false,
    Url       = "",
    Username  = "LuxuryXHUB",
    AvatarUrl = "",

    NotifyRareOnly = false,
    IncludeStats   = true,
    ShowUserId     = true,      -- ⭐ แสดง Roblox User ID
    ShowProfile    = true,      -- ⭐ แสดงลิงก์โปรไฟล์
    ShowAccountAge = true,      -- ⭐ แสดงอายุบัญชี

    MinIntervalSeconds = 2,
}

-- ═══════════════════════════════════════════════════════════════════
-- INTERNAL
-- ═══════════════════════════════════════════════════════════════════
local lastSentAt = 0
local sentCount = 0
local errorCount = 0

local FLAG_COMPONENTS_V2 = 32768

-- ═══════════════════════════════════════════════════════════════════
-- PLAYER INFO HELPERS
-- ═══════════════════════════════════════════════════════════════════

local function getPlayer()
    return S.LocalPlayer
end

local function getUserId()
    local lp = getPlayer()
    return lp and lp.UserId or 0
end

local function getUsername()
    local lp = getPlayer()
    return lp and lp.Name or "Unknown"
end

local function getDisplayName()
    local lp = getPlayer()
    return lp and lp.DisplayName or "Unknown"
end

local function getAccountAge()
    local lp = getPlayer()
    if not lp then return 0 end
    return lp.AccountAge  -- เป็นจำนวนวัน
end

local function getAccountAgeText()
    local days = getAccountAge()
    if days < 1 then return "today" end
    if days < 30 then return days .. " days" end
    if days < 365 then return math.floor(days / 30) .. " months" end
    return string.format("%.1f years", days / 365)
end

local function getProfileUrl()
    return "https://www.roblox.com/users/" .. tostring(getUserId()) .. "/profile"
end

local function getAvatarUrl()
    -- ใช้ Roblox Thumbnail API (ไม่ต้อง auth)
    local userId = getUserId()
    if userId == 0 then return nil end
    return "https://www.roblox.com/headshot-thumbnail/image?userId="
        .. userId .. "&width=150&height=150&format=png"
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

-- ═══════════════════════════════════════════════════════════════════
-- CORE
-- ═══════════════════════════════════════════════════════════════════
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
        httpRequest({
            Url = Webhook.Config.Url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
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

-- ═══════════════════════════════════════════════════════════════════
-- COMPONENT BUILDERS (V2)
-- ═══════════════════════════════════════════════════════════════════

local function TextDisplay(content)
    return { type = 10, content = content }
end

local function Separator(divider, spacing)
    return { type = 14, divider = divider ~= false, spacing = spacing or 1 }
end

local function Thumbnail(url, description)
    return {
        type = 11,
        media = { url = url },
        description = description or "",
    }
end

local function Section(components, accessory)
    local s = { type = 9, components = components }
    if accessory then s.accessory = accessory end
    return s
end

local function Container(components, accentColor)
    local c = { type = 17, components = components }
    if accentColor then c.accent_color = accentColor end
    return c
end

-- ═══════════════════════════════════════════════════════════════════
-- ⭐ BUILD: Player info block (แสดง Roblox ID + ข้อมูล)
-- ═══════════════════════════════════════════════════════════════════
local function buildPlayerBlock()
    local lines = {}

    -- Display Name + Username
    table.insert(lines, string.format("**%s** (@%s)",
        getDisplayName(), getUsername()))

    -- Roblox User ID
    if Webhook.Config.ShowUserId then
        table.insert(lines, string.format("🆔 **User ID:** `%d`", getUserId()))
    end

    -- Profile link
    if Webhook.Config.ShowProfile then
        table.insert(lines, string.format("🔗 [View Profile](%s)", getProfileUrl()))
    end

    -- Account age
    if Webhook.Config.ShowAccountAge then
        table.insert(lines, string.format("📅 **Account Age:** %s", getAccountAgeText()))
    end

    return table.concat(lines, "\n")
end

-- ═══════════════════════════════════════════════════════════════════
-- ⭐ MAIN: Notify Egg Collected
-- ═══════════════════════════════════════════════════════════════════
function Webhook.NotifyEggCollected(eggName, isRare)
    if not Webhook.Config.Enabled then return false end
    if Webhook.Config.NotifyRareOnly and not isRare then
        return false, "Skipped (not rare)"
    end

    local accentColor = isRare and 0xFFD700 or 0x00E676
    local title = isRare and "🌟 **RARE EGG COLLECTED!**" or "🥚 **Egg Collected!**"

    local components = {}

    -- ═══ Title ═══
    table.insert(components, TextDisplay(title))
    table.insert(components, Separator(true, 1))

    -- ═══ Player Info (พร้อมรูป avatar) ═══
    local avatarUrl = getAvatarUrl()
    local playerBlock = buildPlayerBlock()

    if avatarUrl then
        -- Section พร้อม thumbnail
        table.insert(components, Section(
            { TextDisplay(playerBlock) },
            Thumbnail(avatarUrl, getUsername() .. "'s avatar")
        ))
    else
        -- ไม่มี thumbnail
        table.insert(components, TextDisplay(playerBlock))
    end

    table.insert(components, Separator(true, 1))

    -- ═══ Egg Info ═══
    table.insert(components, TextDisplay(string.format(
        "**Egg:** %s\n**Time:** %s",
        eggName, getTimeString()
    )))
    table.insert(components, Separator(true, 1))

    -- ═══ Stats ═══
    if Webhook.Config.IncludeStats then
        local elapsed = os.time() - StateStore.sessionStartTime
        local mins = math.floor(elapsed / 60)
        local secs = elapsed % 60

        table.insert(components, TextDisplay(string.format(
            "**Session Total:** %d eggs\n**Session Time:** %02d:%02d",
            StateStore.totalEggsCollected, mins, secs
        )))
        table.insert(components, Separator(true, 1))
    end

    -- ═══ Footer ═══
    table.insert(components, TextDisplay(
        "-# LuxuryXHUB v" .. AppConfig.Version
    ))

    local container = Container(components, accentColor)

    return Webhook.Send({
        flags = FLAG_COMPONENTS_V2,
        components = { container },
    })
end

-- ═══════════════════════════════════════════════════════════════════
-- TEST
-- ═══════════════════════════════════════════════════════════════════
function Webhook.Test()
    local savedEnabled = Webhook.Config.Enabled
    Webhook.Config.Enabled = true
    lastSentAt = 0

    local components = {}

    table.insert(components, TextDisplay("✅ **Webhook Connected**"))
    table.insert(components, Separator(true, 1))

    -- Player block
    local avatarUrl = getAvatarUrl()
    local playerBlock = buildPlayerBlock()

    if avatarUrl then
        table.insert(components, Section(
            { TextDisplay(playerBlock) },
            Thumbnail(avatarUrl, getUsername() .. "'s avatar")
        ))
    else
        table.insert(components, TextDisplay(playerBlock))
    end

    table.insert(components, Separator(true, 1))
    table.insert(components, TextDisplay(
        "You will receive notifications\nwhenever you collect eggs."
    ))
    table.insert(components, Separator(true, 1))
    table.insert(components, TextDisplay("-# LuxuryXHUB v" .. AppConfig.Version))

    local container = Container(components, 0x00E676)

    local ok = Webhook.Send({
        flags = FLAG_COMPONENTS_V2,
        components = { container },
    })

    Webhook.Config.Enabled = savedEnabled
    return ok
end

-- ═══════════════════════════════════════════════════════════════════
-- STATS
-- ═══════════════════════════════════════════════════════════════════
function Webhook.GetStats()
    return { sent = sentCount, errors = errorCount }
end

-- ═══════════════════════════════════════════════════════════════════
-- DEBUG — พิมพ์ข้อมูลที่จะส่ง (ไว้เช็ค)
-- ═══════════════════════════════════════════════════════════════════
function Webhook.DebugPlayerInfo()
    print("═══════════════════════════════════════")
    print("Player Info:")
    print("  User ID:      " .. tostring(getUserId()))
    print("  Username:     " .. tostring(getUsername()))
    print("  Display Name: " .. tostring(getDisplayName()))
    print("  Account Age:  " .. tostring(getAccountAge()) .. " days")
    print("  Profile:      " .. getProfileUrl())
    print("  Avatar URL:   " .. tostring(getAvatarUrl()))
    print("═══════════════════════════════════════")
end

NS.Webhook = Webhook