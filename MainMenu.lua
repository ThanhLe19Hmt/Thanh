--[[
    MarvenRiz Hub VIP - Main Entry
]]

repeat task.wait() until game:IsLoaded()
    and game.Players.LocalPlayer
    and game.Players.LocalPlayer.Character

if game.PlaceId ~= 119091355492870 then
    return warn("[MarvenRiz] Sai Place ID!")
end

-- ============================================================
-- LOAD MODULES (thay URL khi host)
-- ============================================================
local Core = loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/GUISKILLS/Core.lua"))()
local Combat = loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/GUISKILLS/Combat.lua"))()
local VIPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/GUISKILLS/VIPUI.lua"))()
local Farm = loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/GUISKILLS/Farm.lua"))()

Core.Log.Info("Đang khởi tạo MarvenRiz Hub VIP...")

-- ============================================================
-- PRE-CACHE DATA
-- ============================================================
local ReplicatedStorage = Core.Services.ReplicatedStorage
local LocalPlayer = Core.Services.LocalPlayer

local Cache = {}
local function SafeRequire(path)
    local ok, m = pcall(function()
        local node = ReplicatedStorage
        for _, seg in ipairs(path) do
            node = node:WaitForChild(seg, 5)
        end
        return require(node)
    end)
    return ok and m or {}
end

Cache.UseItems     = SafeRequire({"Modules", "UseItems"})
Cache.CraftingTable= SafeRequire({"Modules", "CraftingTable"})
Cache.QuestModule  = SafeRequire({"Modules", "QuestModule"})
Cache.ItemList     = SafeRequire({"Modules", "Itemlist"})
Cache.SpawnBossList= SafeRequire({"Modules", "SpawnBossList"})
Cache.Blacklist    = SafeRequire({"Modules", "BlacklistItemTrade"})
Cache.AccessoryMod = SafeRequire({"Modules", "AccessoryModule"})
Cache.PointItemM   = SafeRequire({"Modules", "GaranteeRandomItem"})
Cache.PointMoon    = SafeRequire({"Modules", "GaranteeEventMoon"})
Cache.Economy      = SafeRequire({"Modules", "Economy"})

_G.UseItems = Cache.UseItems
_G.CraftingTable = Cache.CraftingTable
_G.Economy = Cache.Economy

-- Pre-build các list
local function BuildSortedList(tbl, filter)
    local list = {}
    for k in pairs(tbl or {}) do
        if not filter or filter(k) then table.insert(list, k) end
    end
    table.sort(list)
    return list
end

local WeaponAll = BuildSortedList(Cache.UseItems)
local Bosses    = BuildSortedList(Cache.SpawnBossList)
local SellItems = BuildSortedList(Cache.Economy)
local X2List    = {}
for name in pairs(Cache.Blacklist or {}) do
    if name:find("X2") then table.insert(X2List, name) end
end
table.sort(X2List)

-- Build ItemDrop map
local MonsterDrop, ItemDrop, ItemToMob = {}, {}, {}
local Itemdrops = workspace:WaitForChild("Itemdrops")
for _, mob in ipairs(Itemdrops:GetChildren()) do
    local sf = mob:FindFirstChild("ScrollingFrame", true)
    if sf then
        MonsterDrop[mob.Name] = {}
        for _, v in ipairs(sf:GetDescendants()) do
            if v:IsA("TextLabel") and not v.Text:find("%%") and v.Text ~= "" then
                MonsterDrop[mob.Name][v.Text] = true
                ItemDrop[v.Text] = ItemDrop[v.Text] or {}
                table.insert(ItemDrop[v.Text], mob.Name)
                ItemToMob[v.Text] = mob.Name
            end
        end
    end
end

local ItemAll = {}
for name in pairs(ItemToMob) do
    local data = Cache.ItemList[name]
    if not (data and data.Type == "Accessory") then
        table.insert(ItemAll, name)
    end
end
table.sort(ItemAll)

-- Export globals
_G.BossList = Bosses
_G.ItemDrop = ItemDrop
_G.MonsterDrop = MonsterDrop

-- Build Quest list
local Quest_List = {}
local NpcQuest = workspace:WaitForChild("NpcQuest")
table.sort(Cache.QuestModule, function(a, b) return a.Level < b.Level end)
for i, data in ipairs(Cache.QuestModule) do
    local npc = NpcQuest:WaitForChild("NPC_Quest" .. i, 5)
    if npc then
        Quest_List[i] = {
            Level = data.Level,
            Monster = npc:GetAttribute("Name"),
            Quest = npc,
        }
    end
end
_G.QuestList = Quest_List

-- ============================================================
-- INIT UI LIBRARY
-- ============================================================
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Ui_New.lua"
))()

local Window = Library:CreateWindow({
    Title = "MarvenRiz VIP",
    Subtitle = "Map: Rock Fruit | VIP Edition",
    Size = UDim2.fromOffset(620, 480),
    AccentColor = Color3.fromRGB(88, 101, 242),
    SideBarWidth = 150,
    Logo = "rbxassetid://87526284179554",
    LogoSize = 32,
    SphereText = false,
    SphereImage = "rbxassetid://87526284179554",
    SphereIconSize = 38,
    Map = "RockFruit",
})

-- Override Library:Notify → VIP Notifications
local OriginalNotify = Library.Notify
function Library:Notify(opts)
    VIPUI.Notify(opts)
end

-- Init VIP components
VIPUI.InitNotifications(game:GetService("CoreGui"))
VIPUI.InitStatusHUD(game:GetService("CoreGui"))

-- ============================================================
-- KEYBINDS
-- ============================================================
VIPUI.RegisterKeybind(Enum.KeyCode.RightShift, function()
    -- Toggle window (phụ thuộc vào lib của bạn)
    if Window.Toggle then Window:Toggle() end
end, "Toggle UI")

VIPUI.RegisterKeybind(Enum.KeyCode.F1, function()
    VIPUI.ToggleHUD()
end, "Toggle Status HUD")

VIPUI.RegisterKeybind(Enum.KeyCode.F2, function()
    VIPUI.EmergencyStop()
end, "Emergency Stop")

-- ============================================================
-- BUILD TABS
-- ============================================================
local TabSettings = Window:CreateTab("⚙️ Settings", true)
local TabMain     = Window:CreateTab("🎯 Main")
local TabBoss     = Window:CreateTab("👹 Boss")
local TabRaid     = Window:CreateTab("🌋 Raid")
local TabOther    = Window:CreateTab("🎁 Other")
local TabConfig   = Window:CreateTab("💾 Config")

-- ... (code build UI sections như file cũ, nhưng dùng biến đã có sẵn)

-- ============================================================
-- SETUP ANTI-AFK
-- ============================================================
Core.SetupAntiAFK()

-- ============================================================
-- AUTO-LOAD CONFIG
-- ============================================================
local MySaveManager = Library.SaveManager
MySaveManager:BuildConfigTab(TabConfig)
task.delay(1, function()
    MySaveManager:LoadAutoloadConfig()
end)

Core.Log.Info("✅ MarvenRiz VIP đã khởi động thành công!")
VIPUI.Notify({
    Title = "★ Chào mừng VIP!",
    Description = "MarvenRiz VIP đã sẵn sàng. F1: HUD | F2: Stop",
    Type = "vip",
    Duration = 5,
})
