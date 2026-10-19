-- Main.lua
-- Entry point - Load tất cả modules theo thứ tự

local Core = script.Parent.Core
local UI = script.Parent.UI
local Combat = script.Parent.Combat
local Systems = script.Parent.Systems
local Farm = script.Parent.Farm
local Bosses = script.Parent.Bosses
local Raid = script.Parent.Raid
local Dungeon = script.Parent.Dungeon
local RaidMoon = script.Parent.RaidMoon
local Shop = script.Parent.Shop
local Items = script.Parent.Items
local Teleport = script.Parent.Teleport

print("[Sea 1] ▶️ Loading...")

-- 1. Load Core TRƯỚC (services, helpers, globals)
local Services  = require(Core.Services)
local Helpers   = require(Core.Helpers)
local Globals   = require(Core.Globals)
local Config    = require(Core.Config)
local DataBuilder = require(Core.DataBuilder)

-- 2. Load UI
local MainWindow = require(UI.MainWindow)

-- 3. Load Map Detection
local IS_MOON_MAP = (game.PlaceId == Config.MOON_PLACE_ID)
local IS_SEA2_MAP = (game.PlaceId == Config.SEA2_PLACE_ID)

if IS_MOON_MAP then
    require(UI.MoonUI)
    require(RaidMoon.MoonFarm)
    require(RaidMoon.MoonRocket)
    require(RaidMoon.MoonTarget)
    require(RaidMoon.MoonTravel)
elseif not IS_SEA2_MAP then
    -- Sea 1: Load tất cả
    require(Combat.AutoSkill)
    require(Combat.Attack)
    require(Combat.AntiDash)
    
    require(Systems.NoVFX)
    require(Systems.AutoPotion)
    require(Systems.AutoAccessory)
    require(Systems.AutoRebirth)
    require(Systems.AutoHaki)
    require(Systems.AntiIdle)
    
    require(Farm.FarmLevel)
    require(Farm.FarmMaterial)
    require(Farm.FarmSet)
    require(Farm.FarmCraft)
    
    require(Bosses.FarmBossFull)
    require(Bosses.FarmBossAll)
    require(Bosses.FarmPiccolo)
    require(Bosses.FarmDuck)
    require(Bosses.FarmDevilBoat)
    require(Bosses.FarmKraken)
    require(Bosses.FarmThief)
    
    require(Raid.RaidBacon)
    require(Raid.RaidDragon)
    require(Raid.RaidLava)
    
    require(Dungeon.AutoDungeon)
    
    require(Shop.ShopRaid)
    require(Shop.ShopDungeon)
    require(Shop.GuaranteeDiamond)
    require(Shop.GuaranteeMoon)
    require(Shop.MysteryBox)
    
    require(Items.RandomChest)
    require(Items.CraftTable)
    require(Items.GokuNPC)
    
    require(Teleport.IslandTeleport)
    require(Teleport.SeaTravel)
end

print("[Sea 1] ✅ Load successful!")
