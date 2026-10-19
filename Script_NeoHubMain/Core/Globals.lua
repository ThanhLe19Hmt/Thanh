-- Core/Globals.lua
-- Tất cả _G flags (state toàn cục)

return {
    -- Combat
    SmoothUpperBelow = true,
    AutoCombat       = false,
    CanAutoSkill     = false,
    MainWeapon       = "Melee",
    Select_EquipWeapon = {},
    Select_Method    = "Upper",
    Distance_Farm    = 5,
    AutoSkillZ = false, AutoSkillX = false,
    AutoSkillC = false, AutoSkillV = false,
    AutoSkillF = false, Auto_Haki  = false,

    -- Character
    Auto_Equip_Accessory = false,
    Auto_Rebirth         = false,

    -- Potion
    Select_Potion    = "",
    PotionAmount     = 1,
    Auto_Use_Potion  = false,

    -- Farm
    Auto_Farm_Level    = false,
    Select_Material    = {},
    Auto_Farm_Material = false,

    -- Boss
    Select_Boss    = nil,
    Auto_FarmBoss  = false,
    Auto_FarmBoss_Automatically = false,
    Auto_BaconThief = false,
    Auto_Piccolo    = false,
    Auto_Duck       = false,
    Auto_DevilBoat  = false,
    Auto_DuckAutomatically = false,
    Auto_Kraken     = false,
    AutoBossAll     = false,

    -- Craft
    Select_Item        = nil,
    Auto_CraftWeapon   = false,
    Auto_Farm_Set      = false,

    -- Dungeon / Raid
    Auto_Raid            = false,
    Dungeon_UseValue     = 1,
    HealthPercent        = 30,
    Auto_Dungeon         = false,
    RaidBossOffsetY      = 55,
    RaidBallOffsetY      = 25,
    DungeonHeight        = 25,
    RaidAutoAttack       = false,
    RaidAutoSkill        = false,

    -- Stats
    AutoMelee = false, AutoDefense = false,
    AutoSword = false, AutoPower   = false,

    -- Random Chest
    Select_Random         = "x5",
    Auto_RandomChest      = false,
    Select_Random_Moon    = "x5",
    Auto_RandomChest_Moon = false,
    Select_Guarantee      = nil,
    Auto_Guarantee        = false,
    Select_Guarantee_Moon = nil,
    Auto_Guarantee_Moon   = false,

    -- Misc
    VFXDisabled   = false,
    TimeMysteryAmount = 1,
}
