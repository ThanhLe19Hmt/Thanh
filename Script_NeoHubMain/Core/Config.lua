-- Core/Config.lua
-- Constants

return {
    MOON_PLACE_ID = 82878101790702,
    SEA2_PLACE_ID = 132854526011923,
    
    TypeTool         = {"Melee", "Sword", "Special", "DevilFruit"},
    RandomChestValue = {"x5", "x10", "x15"},
    
    SpawnList = {
        ["Thief"]      = "Bacon Thief",
        ["Piccolo"]    = "Piccolo",
        ["Duck"]       = "Duck Monster",
        ["Devil Boat"] = "Devil Boat",
        ["Kraken"]     = "Kraken",
    },
    
    Bacon = {
        AIM_HEIGHT      = 25,
        BOSS_HEIGHT     = 55,
        MIN_FIRE_GAP    = 3,
        PORTAL_TIMEOUT  = 15,
        THANOS_COOLDOWN = 0.3,
        PORTAL_FIRE_LOCK = 5,
        SAFE_HEIGHT     = 500,
        HOVER_DELAY     = 0.8,
        BUFF_LIST       = {"Kaioken", "SSJ", "SSJ2", "SSJ3", "SSJG", "SSJB"},
    },
    
    Dragon = {
        AIM_HEIGHT       = 25,
        MIN_FIRE_GAP     = 3,
        PORTAL_TIMEOUT   = 15,
        PORTAL_FIRE_LOCK = 5,
        SAFE_HEIGHT_FLY  = 500,
        THANOS_COOLDOWN  = 0.3,
        BUFF_COOLDOWN    = 0.3,
        BUFF_LIST        = {"Kaioken", "SSJ", "SSJ2", "SSJ3", "SSJG", "SSJB"},
    },
    
    Lava = {
        AIM_HEIGHT      = 25,
        UNDER_LAVA_Y    = -100,
        MIN_FIRE_GAP    = 3,
        PORTAL_TIMEOUT  = 15,
        THANOS_COOLDOWN = 0.3,
        SURFACE_DELAY   = 1.5,
        PORTAL_FIRE_LOCK = 5,
        SAFE_HEIGHT     = 500,
        BUFF_LIST       = {"Kaioken", "SSJ", "SSJ2", "SSJ3", "SSJG", "SSJB"},
    },
    
    Moon = {
        SETTLE_DELAY     = 0.15,
        WATCHDOG         = 2.0,
        STUCK_THRESHOLD  = 5,
        STUCK_MAX        = 5,
        STUCK_COOLDOWN   = 3,
        ROCKET_CACHE     = 15,
        CAVE_POS         = Vector3.new(-195, 14, 412),
        SAVE_FOLDER      = "MarvenRiz_Moon",
    },
}
