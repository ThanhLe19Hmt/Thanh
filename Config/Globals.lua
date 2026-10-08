--[[
    Config/Globals.lua
    Chứa toàn bộ _G settings + constants
]]

local Globals = {}

-- ===== Services =====
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local RunService        = game:GetService("RunService")
local VirtualUser       = game:GetService("VirtualUser")

Globals.Players           = Players
Globals.ReplicatedStorage = ReplicatedStorage
Globals.HttpService       = HttpService
Globals.RunService        = RunService
Globals.VirtualUser       = VirtualUser
Globals.LocalPlayer       = Players.LocalPlayer

-- ===== Workspace refs =====
Globals.Npc_Quest  = workspace:WaitForChild("NpcQuest")
Globals.Itemdrops  = workspace:WaitForChild("Itemdrops")

-- ===== Modules =====
local RS = ReplicatedStorage
Globals.UseItems           = require(RS.Modules.UseItems)
Globals.CraftingTable      = require(RS.Modules.CraftingTable)
Globals.Quest_Module       = require(RS.Modules.QuestModule)
Globals.ItemList           = require(RS.Modules.Itemlist)
Globals.SpawnBossList      = require(RS.Modules.SpawnBossList)
Globals.Blacklist          = require(RS.Modules.BlacklistItemTrade)
Globals.AccessoryModule    = require(RS.Modules.AccessoryModule)
Globals.PointItemM         = require(RS.Modules.GaranteeRandomItem)
Globals.PointItemMoon      = require(RS.Modules.GaranteeEventMoon)
Globals.Economy            = require(RS.Modules.Economy)

-- ===== Constants =====
Globals.Codes          = {"Mambo","MiniUpdate2","OmniMan","UPDATE1","SorryForDelay1","Lucy","Luck"}
Globals.TypeTool       = {"Melee","Sword","Special","DevilFruit"}
Globals.RandomChestValue = {"x5","x10","x15"}
Globals.MethodList     = {"Behind","Below","Upper","Front","None"}
Globals.SpawnList = {
    ["Thief"]       = "Bacon Thief",
    ["Piccolo"]     = "Piccolo",
    ["Duck"]        = "Duck Monster",
    ["Devil Boat"]  = "Devil Boat"
}

-- ===== Globals settings =====
_G.MainWeapon                    = "Melee"
_G.Select_EquipWeapon            = {}
_G.Select_Method                 = "Upper"
_G.Distance_Farm                 = 5
_G.AutoSkillZ                    = false
_G.AutoSkillX                    = false
_G.AutoSkillC                    = false
_G.AutoSkillV                    = false
_G.AutoSkillF                    = false
_G.Auto_Haki                     = false
_G.Auto_Equip_Accessory          = false
_G.Auto_Rebirth                  = false
_G.Select_Potion                 = {}
_G.Auto_Use_Potion               = false
_G.Auto_Farm_Level               = false
_G.Select_Material               = {}
_G.Auto_Farm_Material            = false
_G.Select_Boss                   = nil
_G.Auto_FarmBoss                 = false
_G.Auto_FarmBoss_Automatically   = false
_G.Auto_BaconThief               = false
_G.Auto_Piccolo                  = false
_G.Auto_Duck                     = false
_G.Auto_DevilBoat                = false
_G.Auto_DuckAutomatically        = false
_G.Select_Item                   = nil
_G.Auto_CraftWeapon              = false
_G.Auto_Farm_Set                 = false
_G.Auto_Raid                     = false
_G.Dungeon_UseValue              = 1
_G.HealthPercent                 = 30
_G.Auto_Dungeon                  = false
_G.Select_SellItem               = {}
_G.Auto_SellItem                 = false
_G.Amount                        = 1000
_G.AutoMelee                     = false
_G.AutoDefense                   = false
_G.AutoSword                     = false
_G.AutoPower                     = false
_G.Select_Random                 = "x5"
_G.Auto_RandomChest              = false
_G.Select_Random_Moon            = "x5"
_G.Auto_RandomChest_Moon         = false
_G.Select_Guarantee              = nil
_G.Auto_Guarantee                = false
_G.Select_Guarantee_Moon         = nil
_G.Auto_Guarantee_Moon           = false
_G.RaidBossOffsetY               = 55
_G.RaidBallOffsetY               = 25
_G.DungeonHeight                 = 25
_G.VFXDisabled                   = false

return Globals
