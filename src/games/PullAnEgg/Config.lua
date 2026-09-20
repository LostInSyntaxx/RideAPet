--[[
    LuxuryXHUB - Pull An Egg
    Config.lua - Centralized Configuration & Defaults
]]

local Config = {
    GameName = "Pull An Egg",
    PlaceId  = 70640255604878,
    GameId   = 10649255304,

    -- ── Automation Defaults ─────────────────────────────────────────
    AutoTrain       = false,
    TrainInterval   = 0.1, -- Delay between Dumbbell clicks

    AutoSell        = false,
    SellInterval    = 2,   -- Fix: synced from 5 (speed optimization)

    AutoRebirth     = false,
    RebirthInterval = 1, -- Fix: synced from 2 (speed optimization)

    AutoBuyDumbell  = false,
    AutoUpgradeCarry= false,
    AutoRevive      = true, -- Automatically click Yes to revive instantly without waiting 8s

    AutoPullEgg     = false,
    TargetEggTier   = "Celestial", -- Default target tier
    FlyHeight       = 16,          -- Safe height above egg to dodge boss attacks
    SafeHover       = true,        -- Floats in mid-air above egg to stay immune to ground bosses

    EggESP          = true,

    -- ── Tiers available in workspace.Map.SpawnParts ──────────────────
    TIERS = {
        "Celestial",
        "Transcendent",
        "Divine",
        "OG",
        "Brainrot God",
        "Secret",
        "Mythic",
        "Legendary",
        "Epic",
        "Rare",
        "Common",
    },

    -- ── Color Scheme for Tiers in ESP ────────────────────────────────
    TIER_COLORS = {
        ["Celestial"]    = Color3.fromRGB(0, 240, 255),
        ["Transcendent"] = Color3.fromRGB(255, 0, 128),
        ["Divine"]       = Color3.fromRGB(255, 215, 0),
        ["OG"]           = Color3.fromRGB(138, 43, 226),
        ["Brainrot God"] = Color3.fromRGB(255, 69, 0),
        ["Secret"]       = Color3.fromRGB(75, 0, 130),
        ["Mythic"]       = Color3.fromRGB(255, 50, 50),
        ["Legendary"]    = Color3.fromRGB(255, 165, 0),
        ["Epic"]         = Color3.fromRGB(186, 85, 211),
        ["Rare"]         = Color3.fromRGB(30, 144, 255),
        ["Common"]       = Color3.fromRGB(180, 180, 180),
    },

    -- ── UI Theme ─────────────────────────────────────────────────────
    THEME = {
        Background = Color3.fromRGB(16, 18, 26),
        Sidebar    = Color3.fromRGB(12, 14, 20),
        Card       = Color3.fromRGB(24, 27, 39),
        Accent     = Color3.fromRGB(255, 170, 0), -- Golden amber accent
        AccentDark = Color3.fromRGB(180, 120, 0),
        Text       = Color3.fromRGB(240, 242, 245),
        SubText    = Color3.fromRGB(150, 155, 170),
        Success    = Color3.fromRGB(46, 204, 113),
        Danger     = Color3.fromRGB(231, 76, 60),
    }
}

return Config
