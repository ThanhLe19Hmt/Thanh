--[[
    MarvenRiz Hub - Rock Fruit
    Refactored & Modular Version
    Author: (original) MarvenRiz
    Refactor: gọn - mượt - dễ quản lý
]]

repeat task.wait() until game:IsLoaded()
    and game.Players.LocalPlayer
    and game.Players.LocalPlayer.Character

local PlaceId = game.PlaceId
local SUPPORTED_PLACE = 119091355492870

-- Load globals trước
local Globals = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Globals.lua"
))()

-- Load core modules
local Utils     = loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Core/Utils.lua"))()
local Inventory = loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Core/Inventory.lua"))()
local Combat    = loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Core/Combat.lua"))()
local NoVFX     = loadstring(game:HttpGet(".../Core/NoVFX.lua"))()

-- Khởi tạo Library UI
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/znesr99/gui/refs/heads/main/MarvenRizLib.lua"
))()

-- Tạo Window
local Window = Library:CreateWindow({
    Title         = "MarvenRiz Hub",
    Subtitle      = "Map : Rock Fruit",
    Size          = UDim2.fromOffset(500, 370),
    AccentColor   = Color3.fromRGB(50, 150, 255),
    SideBarWidth  = 120,
    Logo          = "rbxassetid://87526284179554",
    LogoSize      = 32,
    SphereText    = false,
    SphereImage   = "rbxassetid://87526284179554",
    SphereIconSize = 38,
    Map           = "RockFruit"
})

Globals.Library = Library
Globals.Window  = Window
Globals.Utils   = Utils
Globals.Inventory = Inventory
Globals.Combat  = Combat
Globals.NoVFX   = NoVFX

-- Load modules chính
if PlaceId == SUPPORTED_PLACE then
    local SettingsTab = loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/UI/SettingsTab.lua"))()
    local MainTab     = loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/UI/MainTab.lua"))()
    local OtherTab    = loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/UI/OtherTab.lua"))()
    local ConfigTab   = loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/UI/ConfigTab.lua"))()

    SettingsTab:Init(Window)
    MainTab:Init(Window)
    OtherTab:Init(Window)
    ConfigTab:Init(Window, Library)

    -- Khởi động các feature loops
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Features/AutoFarm.lua"))()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Features/AutoBoss.lua"))()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Features/AutoDungeon.lua"))()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Features/AutoRaid.lua"))()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Features/AutoShop.lua"))()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Features/AutoSell.lua"))()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Features/AutoChest.lua"))()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Features/AutoStats.lua"))()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Features/AutoPotion.lua"))()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Features/AutoCraftTable.lua"))()

    task.spawn(function()
        task.wait(1)
        Library.SaveManager:LoadAutoloadConfig()
    end)
else
    -- Fallback: chỉ settings cơ bản
    local SettingsTab = loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/UI/SettingsTab.lua"))()
    SettingsTab:Init(Window)
end
