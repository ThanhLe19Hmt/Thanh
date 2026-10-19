-- Main.lua
-- Entry point — load tất cả modules theo thứ tự

print("[Sea 1] ▶️ Loading...")

-- ============================================================
-- CORE (load trước tiên)
-- ============================================================
local Services   = require(script.Core.Services)
local Helpers    = require(script.Core.Helpers)
local Globals    = require(script.Core.Globals)
local Config     = require(script.Core.Config)
local DataBuilder = require(script.Core.DataBuilder)

-- ============================================================
-- BUILD DATA
-- ============================================================
local Data = DataBuilder.Build()
_G.Data = Data  -- expose cho các module khác dùng

-- ============================================================
-- MAP DETECTION
-- ============================================================
local IS_MOON_MAP = (game.PlaceId == Config.MOON_PLACE_ID)
local IS_SEA2_MAP = (game.PlaceId == Config.SEA2_PLACE_ID)

print("[Map] " .. (IS_MOON_MAP and "🌙 Moon" or IS_SEA2_MAP and "🌊 Sea 2" or "🌊 Sea 1") .. " detected")

-- ============================================================
-- UI MAIN WINDOW (load trước UI khác)
-- ============================================================
local MainWindow = require(script.UI.MainWindow)
_G.Library   = MainWindow.Library
_G.Window    = MainWindow.Window
_G.SaveManager = MainWindow.SaveManager

-- ============================================================
-- MOON MAP
-- ============================================================
if IS_MOON_MAP then
    require(script.RaidMoon.MoonRocket)
    require(script.RaidMoon.MoonTarget)
    require(script.UI.MoonUI)
    require(script.RaidMoon.MoonTravel)

-- ============================================================
-- SEA 1 MAP
-- ============================================================
elseif not IS_SEA2_MAP then
    
    -- Combat
    _G.AutoSkill = require(script.Combat.AutoSkill)
    _G.EquipWeapon = require(script.Combat.Attack).EquipWeapon
    _G.Attack = require(script.Combat.Attack).Attack
    require(script.Combat.AntiDash)
    
    -- Systems
    require(script.Systems.NoVFX)
    require(script.Systems.AutoPotion)
    require(script.Systems.AutoAccessory)
    require(script.Systems.AutoRebirth)
    require(script.Systems.AutoHaki)
    require(script.Systems.AntiIdle)
    
    -- Farm
    require(script.Farm.FarmLevel)
    require(script.Farm.FarmMaterial)
    require(script.Farm.FarmSet)
    require(script.Farm.FarmCraft)
    
    -- Bosses
    require(script.Bosses.FarmBossFull)
    require(script.Bosses.FarmBossAll)
    require(script.Bosses.FarmPiccolo)
    require(script.Bosses.FarmDuck)
    require(script.Bosses.FarmDevilBoat)
    require(script.Bosses.FarmKraken)
    require(script.Bosses.FarmThief)
    
    -- Raid
    require(script.Raid.RaidBacon)
    require(script.Raid.RaidDragon)
    require(script.Raid.RaidLava)
    
    -- Dungeon
    require(script.Dungeon.AutoDungeon)
    
    -- Shop
    require(script.Shop.ShopRaid)
    require(script.Shop.ShopDungeon)
    require(script.Shop.GuaranteeDiamond)
    require(script.Shop.GuaranteeMoon)
    require(script.Shop.MysteryBox)
    
    -- Items
    require(script.Items.RandomChest)
    require(script.Items.CraftTable)
    require(script.Items.GokuNPC)
    
    -- Teleport
    require(script.Teleport.IslandTeleport)
    require(script.Teleport.SeaTravel)
    
    -- UI Sea 1 (load sau cùng vì dùng tất cả refs)
    require(script.UI.Sea1UI)
end

print("[Sea 1] ✅ Load successful!")
