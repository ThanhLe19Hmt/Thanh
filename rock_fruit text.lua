--[[
============================================================
  MARVENRIZ HUB - ROCK FRUIT (SEA 1 + MOON MAP) - v72
  Sea 1 Tabs:  Main, Boss, Random, Shop, Raid, Craft, Skills, Settings, Config
  Moon Tabs:   Raid Moon, Skills, Settings, Config
============================================================
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local RunService          = game:GetService("RunService")
local GuiService          = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser         = game:GetService("VirtualUser")
local HttpService         = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Action      = ReplicatedStorage:WaitForChild("Remotes", 5)
                    and ReplicatedStorage.Remotes:FindFirstChild("Action")
local NetworkEvent = ReplicatedStorage:FindFirstChild("Modules")
                     and ReplicatedStorage.Modules:FindFirstChild("NetworkFramework")
                     and ReplicatedStorage.Modules.NetworkFramework:FindFirstChild("NetworkEvent")

-- 🆕 Moon Map detection
local MOON_PLACE_ID = 82878101790702
local IsMoonMap     = (game.PlaceId == MOON_PLACE_ID)
print("[Map] " .. (IsMoonMap and "🌙 Moon Map" or "🌊 Sea 1") .. " detected")

-- ============================================================
-- MODULES
-- ============================================================
local function SafeRequire(mod)
    if not mod then return nil end
    local ok, result = pcall(require, mod)
    if ok then return result end
    return nil
end

local ModulesFolder = ReplicatedStorage:FindFirstChild("Modules")
local Quest_Module  = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("QuestModule"))
local Npc_Quest     = workspace:FindFirstChild("NpcQuest")
local SpawnBossList = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("SpawnBossList"))
local UseItems      = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("UseItems"))
local CraftingTable = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("CraftingTable"))
local ItemList      = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("Itemlist"))
local Itemdrops     = workspace:FindFirstChild("Itemdrops")
local PointItemM    = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("GaranteeRandomItem"))
local PointItemMoon = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("GaranteeEventMoon"))
local PowerGodFolder = workspace:FindFirstChild("Power God")

-- ============================================================
-- 🆕 CORE HELPERS — ĐẶT ĐẦU TIÊN
-- ============================================================
local function GetInventory()
    local ok, inv = pcall(function()
        return HttpService:JSONDecode(LocalPlayer:GetAttribute("Inventory") or "{}")
    end)
    return ok and inv or {}
end

local function GetItemAmount(itemName)
    local inv = GetInventory()
    return (inv[itemName] and inv[itemName].amount) or 0
end

local function GetGuaranteeCount(itemName)
    if not itemName or itemName == "" then return 0, 0 end
    local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
    if not hud or not hud:FindFirstChild("Main") then return 0, 0 end
    local guar = hud.Main:FindFirstChild("Frame_Guarantee")
    if not guar then return 0, 0 end
    local sf = guar:FindFirstChild("ScrollingFrame")
    if not sf then return 0, 0 end
    local itemFrame = sf:FindFirstChild(itemName)
    if not itemFrame then return 0, 0 end
    local main = itemFrame:FindFirstChild("Main")
    if not main then return 0, 0 end
    local amtLbl = main:FindFirstChild("AmountLabel")
    if not amtLbl then return 0, 0 end
    local txt = amtLbl.Text or ""
    local cur = tonumber(txt:match("^(%d+)")) or 0
    local max = tonumber(txt:match("/(%d+)")) or 0
    return cur, max
end

local function ClaimGuaranteeItem(itemName)
    if not itemName or itemName == "" then return false end
    if NetworkEvent then
        NetworkEvent:FireServer("fire", nil, "CraftTable", itemName, "Guarantee")
        return true
    end
    return false
end

local function GetMaxCraftTimes(itemName)
    if not itemName or itemName == "" then return 0 end
    if not CraftingTable then return 0 end
    local Data = CraftingTable[itemName]
    if not Data or not Data.need then return 0 end
    local minCraft = math.huge
    for Item, Need in pairs(Data.need) do
        if Need > 0 then
            local have = GetItemAmount(Item)
            local can = math.floor(have / Need)
            if can < minCraft then minCraft = can end
        end
    end
    if minCraft == math.huge then return 0 end
    return minCraft
end

-- ============================================================
-- BUILD QUEST LIST
-- ============================================================
local Quest_List = {}
if Quest_Module and Npc_Quest then
    pcall(function()
        local sorted = {}
        for i, data in ipairs(Quest_Module) do
            table.insert(sorted, {Level = data.Level, Index = i})
        end
        table.sort(sorted, function(a, b) return a.Level < b.Level end)
        for _, entry in ipairs(sorted) do
            local npc = Npc_Quest:FindFirstChild("NPC_Quest" .. entry.Index)
            if npc then
                table.insert(Quest_List, {
                    Level   = entry.Level,
                    Monster = npc:GetAttribute("Name"),
                    Quest   = npc
                })
            end
        end
    end)
end
print("[Quest] Loaded " .. #Quest_List .. " quests")

-- ============================================================
-- BUILD BOSS LIST
-- ============================================================
local Bosses = {}
if SpawnBossList then
    for name in pairs(SpawnBossList) do
        table.insert(Bosses, name)
    end
end
if #Bosses == 0 then
    Bosses = {"Bacon Thief", "Piccolo", "Duck Monster", "Devil Boat"}
end
table.sort(Bosses)
print("[Boss] Loaded " .. #Bosses .. " bosses")

-- ============================================================
-- BUILD MATERIAL LIST — v83 FIX
-- ============================================================
local ItemDrop      = {}
local ItemToMob     = {}
local MaterialList  = {}

if Itemdrops then
    pcall(function()
        for _, Mob in ipairs(Itemdrops:GetChildren()) do
            local ScrollingFrame = Mob:FindFirstChild("ScrollingFrame", true)
            if ScrollingFrame then
                for _, v in ipairs(ScrollingFrame:GetDescendants()) do
                    if v:IsA("TextLabel") and v.Text and v.Text ~= "" then
                        if not v.Text:find("%%") then
                            -- 🆕 Clean tên item (bỏ khoảng trắng đầu/cuối)
                            local cleanName = v.Text:gsub("^%s+", ""):gsub("%s+$", "")
                            if cleanName ~= "" then
                                ItemDrop[cleanName] = ItemDrop[cleanName] or {}
                                table.insert(ItemDrop[cleanName], Mob.Name)
                                ItemToMob[cleanName] = Mob.Name
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- 🆕 Export để debug từ executor
_G.ItemDropDebug = ItemDrop

local dropCount = 0
for _ in pairs(ItemDrop) do dropCount = dropCount + 1 end
print("[ItemDrop] Built " .. dropCount .. " item entries")

if ItemList then
    for itemName in pairs(ItemToMob) do
        local Data = ItemList[itemName]
        if not (Data and Data.Type == "Accessory") then
            table.insert(MaterialList, itemName)
        end
    end
end
table.sort(MaterialList)
print("[Material] Loaded " .. #MaterialList .. " items")

-- ============================================================
-- 🆕 BUILD X2 POTION LIST
-- ============================================================
local X2PotionList = {}
local Blacklist = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("BlacklistItemTrade"))

if Blacklist then
    for itemName in pairs(Blacklist) do
        if itemName:find("X2") then
            table.insert(X2PotionList, itemName)
        end
    end
end
table.sort(X2PotionList)
print("[Potion] Loaded " .. #X2PotionList .. " X2 potions")

-- ============================================================
-- BUILD CRAFT LIST — TỪ NPC GUI
-- ============================================================
local CraftItemList = {}

local function GetCraftTableItems()
    local items, seen = {}, {}
    local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
    if not hud or not hud:FindFirstChild("Main") then return items end

    local craftFrame = hud.Main:FindFirstChild("Frame_CraftTable")
        or hud.Main:FindFirstChild("Frame_Craft")
        or hud.Main:FindFirstChild("Frame_Crafttable")
    if not craftFrame then return items end

    local sf = craftFrame:FindFirstChild("ScrollingFrame")
        or craftFrame:FindFirstChild("ScrollFrame")
        or craftFrame:FindFirstChildWhichIsA("ScrollingFrame", true)
    if not sf then return items end

    for _, item in ipairs(sf:GetChildren()) do
        if item:IsA("Frame") or item:IsA("ImageButton") or item:IsA("TextButton") then
            local nameLbl = item:FindFirstChild("TitleLabel")
                or item:FindFirstChild("NameLabel")
                or item:FindFirstChild("Label")
                or item:FindFirstChild("TextLabel")
            local name = nameLbl and nameLbl.Text or item.Name
            if name and name ~= "" and not seen[name] and name ~= "Item" then
                seen[name] = true
                table.insert(items, name)
            end
        end
    end
    table.sort(items)
    return items
end

-- Fallback: dùng CraftingTable module
if CraftingTable then
    for name, data in pairs(CraftingTable) do
        if data.need then
            table.insert(CraftItemList, name)
        end
    end
    table.sort(CraftItemList)
end

local initialItems = GetCraftTableItems()
if #initialItems > 0 then
    CraftItemList = initialItems
end
print("[Craft] Loaded " .. #CraftItemList .. " items")

-- ============================================================
-- 🆕 BUILD WEAPON LIST — TỪ UseItems
-- ============================================================
local WeaponCraftList = {}

if UseItems then
    for weaponName, data in pairs(UseItems) do
        if data and data.Inventory then
            table.insert(WeaponCraftList, weaponName)
        end
    end
end
table.sort(WeaponCraftList)
print("[CraftWeapon] Loaded " .. #WeaponCraftList .. " weapons")

-- ============================================================
-- BUILD SHOP LISTS
-- ============================================================
local RandomShopList = {}
local MoonShopList   = {}

if PointItemM then
    local temp = {}
    for name, price in pairs(PointItemM) do
        table.insert(temp, {Name = name, Price = price})
    end
    table.sort(temp, function(a, b) return a.Price < b.Price end)
    for _, data in ipairs(temp) do
        table.insert(RandomShopList, data.Name .. " / " .. data.Price .. " Point")
    end
end
print("[Shop] Random Chest: " .. #RandomShopList .. " items")

if PointItemMoon then
    local temp = {}
    for name, price in pairs(PointItemMoon) do
        table.insert(temp, {Name = name, Price = price})
    end
    table.sort(temp, function(a, b) return a.Price < b.Price end)
    for _, data in ipairs(temp) do
        table.insert(MoonShopList, data.Name .. " / " .. data.Price .. " Point")
    end
end
print("[Shop] Moon Chest: " .. #MoonShopList .. " items")

-- ============================================================
-- CONFIG GLOBALS
-- ============================================================
_G.AutoFarm          = false
_G.AutoFarmLevel     = false
_G.AutoFarmMaterial  = false
_G.SelectMaterials   = {}

_G.AutoSkillZ        = false
_G.AutoSkillX        = false
_G.AutoSkillC        = false
_G.AutoSkillV        = false
_G.AutoSkillF        = false

_G.WeaponOrder       = {}
_G.MainWeapon        = nil
_G.SupportWeapons    = {}

_G.Select_Method     = "Upper"
_G.Distance_Farm     = 5
_G.EnableEquipWeapon = false

_G.LastAttackTime    = 0
_G.AttackDelay       = 0.3
_G.LastSkillTime     = 0
_G.SkillDelay        = 0.25

_G.MethodFarm        = CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-90), 0, 0)

_G.FarmLevelState    = "IDLE"
_G.LastPromptTime    = 0
_G.PromptCooldown    = 2.0
_G.LastDebugTime     = 0
_G.QuestCompletedTime = 0
_G.QuestCompleteCooldown = 3.0
_G.LastQuestMonster  = nil
_G.QuestAccepted     = false
_G.QuestAcceptedTime = 0

_G.AutoHaki          = false
_G.DisableVFX        = false
_G.VFXConnection     = nil

_G.MenuToggleKey     = Enum.KeyCode.RightControl
_G.MenuVisible       = true
_G.MenuToggleConn    = nil

_G.AutoRandomEnabled = false
_G.AutoRandomValue   = "x15"
_G.AutoMoonEnabled   = false
_G.AutoMoonValue     = "x15"

_G.RandomShopItem    = nil
_G.RandomShopAuto    = false
_G.MoonShopItem      = nil

_G.AutoBossFull      = false
_G.AutoPiccolo       = false
_G.AutoDevilBoat     = false
_G.AutoThiefChest    = false
_G.AutoKraken        = false
_G.AutoDuckFull      = false
_G.SelectBoss        = nil
_G.DuckSummonCooldown = 0

_G.AutoDungeon       = false
_G.DungeonAmount     = 1
_G.HealthPercent     = 30
_G.DungeonHeight     = 25
_G.LastOrbNotify     = 0

_G.CraftAutoRunning      = false
_G.CraftSelectedItem     = nil
_G.AutoClaimGuarantee    = true
_G.CraftDelay            = 1.0
_G.CraftPhase            = "waiting"
_G.CraftLastTime         = 0
_G.CraftLastSync         = 0
_G.CraftCountSinceClaim  = 0
_G.CraftDropdown         = nil
_G.LastCraftListStr      = ""
_G.LastShopRaidStr       = ""
_G.LastShopDungeonStr    = ""

_G.AutoCraftWeaponRunning = false
_G.AutoCraftWeaponCurrent = nil
_G.CraftWeaponSelectedItem = nil

_G.AutoFarmCraftItems     = false
_G.CraftFarmTargetItem    = nil

_G.ShopRaidItem         = nil
_G.ShopRaidAuto         = false
_G.ShopDungeonItem      = nil
_G.ShopDungeonAuto      = false
_G.ShopRaidItemsList    = {}
_G.ShopDungeonItemsList = {}
_G.ShopRaidDropdown     = nil
_G.ShopDungeonDropdown  = nil

_G.RaidAttackHeight      = 25
_G.RaidBallHeight        = 25
_G.RaidBaconHeight       = 55

_G.AutoRaidRunning       = false
_G.AutoRaidWho           = nil
_G.RaidPhase             = "IDLE"
_G.RaidPortalRef         = nil
_G.RaidFireTimestamp     = 0
_G.RaidFired             = false
_G.RaidForceFirePending  = false
_G.RaidPrevRunning       = false
_G.RaidBP                = nil
_G.RaidWaitOldPortal     = nil
_G.RaidWaitPortalStart   = nil
_G.RaidClearStart        = nil
_G.RaidLastFireTime      = 0
_G.RaidToolWaitStart     = nil
_G.RaidAttacking         = false
_G.RaidRespawnTime       = 0
_G.RaidSkipBossFight     = 0
_G.RaidLastAttack        = 0
_G.RaidLastSkill         = 0
_G.RaidLastEquip         = 0
_G.RaidCurrentTarget     = nil
_G.RaidCurrentOffset     = nil

_G.AutoRaidMoon = false
_G.MoonTargetMob = nil

_G.LastCraftSpawnTP = 0
_G.LastCharacter = nil  -- 🆕 Tracking character để phát hiện respawn

_G.X2PotionSelected = nil
_G.X2PotionAmount   = 1

_G.AutoRaidDragon = false
_G.DragonPhase = "IDLE"
_G.DragonBossModel = nil
_G.DragonLastDodge = 0
_G.DragonLastAttack = 0
_G.DragonCurrentSkill = "none"

local DRAGON_ANIM = {
    Attack1 = "122242573493195",
    Stomp   = "113231453412945",
}

_G.LastAntiFallTime = 0
_G.AntiFallDisabled = 0

-- ============================================================
-- CRAFT HELPERS
-- ============================================================
local function GetCraftItemAmount(itemName)
    local inv = GetInventory()
    return (inv[itemName] and inv[itemName].amount) or 0
end

-- ============================================================
-- UPDATE METHOD FARM
-- ============================================================
local function UpdateMethodFarm()
    local m = _G.Select_Method
    local d = _G.Distance_Farm

    if m == "Behind" then
        _G.MethodFarm = CFrame.new(0, 0, d)
    elseif m == "Front" then
        _G.MethodFarm = CFrame.new(0, 0, -d) * CFrame.Angles(0, math.rad(180), 0)
    elseif m == "Below" then
        _G.MethodFarm = CFrame.new(0, -d, 0) * CFrame.Angles(math.rad(90), 0, 0)
    else
        _G.MethodFarm = CFrame.new(0, d, 0) * CFrame.Angles(math.rad(-90), 0, 0)
    end
end
UpdateMethodFarm()

-- ============================================================
-- SHOP HELPERS
-- ============================================================
local function GetShopRaidItems()
    if IsMoonMap then return {} end
    local items, seen = {}, {}
    local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
    if hud and hud:FindFirstChild("Main") then
        local shop = hud.Main:FindFirstChild("Frame_ShopRaid")
        if shop then
            local sf = shop:FindFirstChild("ScrollingFrame")
            if sf then
                for _, item in pairs(sf:GetChildren()) do
                    if item:IsA("Frame") then
                        local label = item:FindFirstChild("Label")
                        if label and label.Text and label.Text ~= "" and label.Text ~= "Item" then
                            if not seen[label.Text] then
                                seen[label.Text] = true
                                table.insert(items, label.Text)
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(items)
    return items
end

local function GetShopDungeonItems()
    if IsMoonMap then return {} end
    local items, seen = {}, {}
    local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
    if hud and hud:FindFirstChild("Main") then
        local shop = hud.Main:FindFirstChild("Frame_ShopDungeon")
        if shop then
            local sf = shop:FindFirstChild("ShopScrollingFrame")
            if sf then
                for _, item in pairs(sf:GetChildren()) do
                    if item:IsA("Frame") then
                        local main = item:FindFirstChild("Main")
                        if main then
                            local titleLbl = main:FindFirstChild("TitleLabel")
                            if titleLbl and titleLbl.Text and titleLbl.Text ~= "" then
                                if not seen[titleLbl.Text] then
                                    seen[titleLbl.Text] = true
                                    table.insert(items, titleLbl.Text)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(items)
    return items
end

local function GetRaidPoint()
    local point = 0
    pcall(function()
        point = tonumber(LocalPlayer:GetAttribute("RaidPoint")) or 0
    end)
    if point == 0 then
        pcall(function()
            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            if hud and hud:FindFirstChild("Main") then
                local shop = hud.Main:FindFirstChild("Frame_ShopRaid")
                if shop then
                    local rpLbl = shop:FindFirstChild("RaidPoint")
                    if rpLbl and rpLbl.Text then
                        point = tonumber(rpLbl.Text:match("(%d+)")) or 0
                    end
                end
            end
        end)
    end
    return point
end

local function GetDungeonPoint()
    local point = 0
    pcall(function()
        point = tonumber(LocalPlayer:GetAttribute("DungeonPoint")) or 0
    end)
    return point
end

-- ============================================================
-- CLEAR DASH BODY MOVERS
-- ============================================================
local function ClearDashBodyMovers()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, child in ipairs(hrp:GetChildren()) do
        if child:IsA("BodyVelocity") or child:IsA("BodyGyro")
           or child:IsA("AlignPosition") or child:IsA("AlignOrientation")
           or child:IsA("BodyThrust") or child:IsA("BodyForce") then
            pcall(function() child:Destroy() end)
        end
    end

    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    task.spawn(function()
        local startTime = tick()
        local hum = char:FindFirstChild("Humanoid")
        while tick() - startTime < 0.3 do
            task.wait(0.01)
            if not hrp.Parent then break end

            for _, child in ipairs(hrp:GetChildren()) do
                if child:IsA("BodyVelocity") or child:IsA("BodyGyro")
                   or child:IsA("AlignPosition") or child:IsA("AlignOrientation")
                   or child:IsA("BodyThrust") or child:IsA("BodyForce") then
                    pcall(function() child:Destroy() end)
                end
            end

            hrp.AssemblyLinearVelocity  = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero

            if hum then
                pcall(function() hum:Move(Vector3.zero, false) end)
            end
        end
    end)
end

local RaidBossData = {
    ["Bacon of Grudge"] = {
        Name = "Bacon of Grudge",
        Reward = "Time Mystery Box x5, 7500 Diamond, Beli 50M, x3 Potion",
        PortalCost = 1,
        Valid = true,
        OffsetY = 55,
        BallOffsetY = 25,
    },
    ["Dragon"] = {
        Name = "Dragon",
        Reward = "Thunder Mystery Box x5, 15k Diamond, Beli 100M, x3 Potion",
        PortalCost = 1,
        Valid = true,
        OffsetY = 25,
    },
    ["Lava Titan"] = {
    Name = "Lava Titan",
    Reward = "Lava Titan Reward - TODO Update",
    PortalCost = 1,
    Valid = true,
    OffsetY = 25,
    },
}

local function GetPortalGunCount()
    local count = 0
    pcall(function()
        local inv = HttpService:JSONDecode(LocalPlayer:GetAttribute("Inventory") or "{}")
        count = (inv["Portal Gun"] and inv["Portal Gun"].amount) or 0
    end)
    return count
end

local function GetBossRewardText(bossKey)
    local Data = RaidBossData[bossKey]
    if not Data then return "N/A" end
    local portalCount = GetPortalGunCount()
    return Data.Reward .. "\n\nYour Portal Gun: " .. tostring(portalCount)
end

_G.LavaThanosHPPercent = 50

-- ============================================================
-- FLUENT UI
-- ============================================================
local Fluent = loadstring(game:HttpGet(
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()

local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"
))()

local Window = Fluent:CreateWindow({
    Title = "MarvenRiz Hub",
    SubTitle = IsMoonMap and "🌙 Moon Map" or "Rock Fruit — Sea 1",
    TabWidth = 160,
    Size = UDim2.fromOffset(600, 480),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local function ChangeMenuKey(newKey)
    if not newKey then return end
    if _G.MenuToggleConn then
        pcall(function() _G.MenuToggleConn:Disconnect() end)
        _G.MenuToggleConn = nil
    end

    _G.MenuToggleKey = newKey
    _G.MenuToggleConn = game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == _G.MenuToggleKey then
            _G.MenuVisible = not _G.MenuVisible
            pcall(function()
                if _G.MenuVisible then
                    Fluent:Open()
                else
                    Fluent:Close()
                end
            end)
        end
    end)
end

-- ============================================================
-- 🆕 TABS — Khác nhau giữa Sea 1 và Moon Map
-- ============================================================
local Tabs = {}

if IsMoonMap then
    -- 🆕 Moon Map: chỉ hiện tab cần thiết
    Tabs.Raid     = Window:AddTab({ Title = "Raid Moon",  Icon = "moon" })
    Tabs.Skills   = Window:AddTab({ Title = "Skills",     Icon = "sword" })
    Tabs.Settings = Window:AddTab({ Title = "Settings",   Icon = "settings" })
    Tabs.Config   = Window:AddTab({ Title = "Config",     Icon = "save" })
    print("[Tabs] 🌙 Moon Map tabs loaded")
else
    -- Sea 1: full tabs
    Tabs.Main     = Window:AddTab({ Title = "Main",       Icon = "home" })
    Tabs.Boss     = Window:AddTab({ Title = "Boss",       Icon = "skull" })
    Tabs.Random   = Window:AddTab({ Title = "Random",     Icon = "dice-5" })
    Tabs.Shop     = Window:AddTab({ Title = "Shop",       Icon = "shopping-cart" })
    Tabs.Raid     = Window:AddTab({ Title = "Raid",       Icon = "castle" })
	Tabs.Goku     = Window:AddTab({ Title = "Goku",       Icon = "zap" })
    Tabs.Teleport = Window:AddTab({ Title = "Teleport",   Icon = "map" })
    Tabs.Potion   = Window:AddTab({ Title = "X2 Potion",  Icon = "flask" })
    Tabs.Craft    = Window:AddTab({ Title = "Craft",      Icon = "hammer" })
    Tabs.Skills   = Window:AddTab({ Title = "Skills",     Icon = "sword" })
    Tabs.Settings = Window:AddTab({ Title = "Settings",   Icon = "settings" })
    Tabs.Config   = Window:AddTab({ Title = "Config",     Icon = "save" })
    print("[Tabs] 🌊 Sea 1 tabs loaded")
end

-- ============================================================
-- CORE FUNCTIONS
-- ============================================================
local function Teleport(pos)
    local char = LocalPlayer.Character
    if char then char:PivotTo(pos) end
end

local function EquipWeapon()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if not bp then return end

        local order = _G.WeaponOrder or {}
        if #order == 0 then return end

        local mainWeapon = order[1]
        local supportList = {}
        for i = 2, #order do
            table.insert(supportList, order[i])
        end

        _G.MainWeapon = mainWeapon
        _G.SupportWeapons = supportList

        local wanted = { [mainWeapon] = true }
        for _, w in ipairs(supportList) do wanted[w] = true end

        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") then
                local t = v:GetAttribute("Type")
                if t and not wanted[t] then v.Parent = bp end
            end
        end

        local hasMain = false
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") and v:GetAttribute("Type") == mainWeapon then
                hasMain = true; break
            end
        end

        if not hasMain then
            for _, v in ipairs(bp:GetChildren()) do
                if v:IsA("Tool") and v:GetAttribute("Type") == mainWeapon then
                    char.Humanoid:EquipTool(v); break
                end
            end
        end

        for _, supportType in ipairs(supportList) do
            local hasSupport = false
            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("Tool") and v:GetAttribute("Type") == supportType then
                    hasSupport = true; break
                end
            end
            if not hasSupport then
                for _, v in ipairs(bp:GetChildren()) do
                    if v:IsA("Tool") and v:GetAttribute("Type") == supportType then
                        v.Parent = char; break
                    end
                end
            end
        end
    end)
end

local function Attack()
    local now = tick()
    if now - _G.LastAttackTime < _G.AttackDelay then return end
    _G.LastAttackTime = now

    pcall(function()
        local char = LocalPlayer.Character
        if not char or not Action then return end
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                Action:FireServer(tool.Name, "hit")
            end
        end
    end)
end

local function TryFireSkill()
    local fired = false
    pcall(function()
        local char = LocalPlayer.Character
        if not char or not Action then return end

        local enabled = {}
        if _G.AutoSkillZ then table.insert(enabled, "z") end
        if _G.AutoSkillX then table.insert(enabled, "x") end
        if _G.AutoSkillC then table.insert(enabled, "c") end
        if _G.AutoSkillV then table.insert(enabled, "v") end
        if _G.AutoSkillF then table.insert(enabled, "f") end
        if #enabled == 0 then return end

        for _, key in ipairs(enabled) do
            for _, tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") then
                    Action:FireServer(tool.Name, key)
                    fired = true
                end
            end
        end
    end)
    return fired
end

local function AutoSkill()
    return TryFireSkill()
end

local function AttackMob(mob)
    if not mob or not mob.Parent then return false end
    local mHrp = mob:FindFirstChild("HumanoidRootPart")
    local mHum = mob:FindFirstChild("Humanoid")
    if not mHrp or not mHum then return false end
    if mHum.Health <= 0 then return false end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    mHum.WalkSpeed = 0
    mHum.JumpPower = 0

    local oldBP = hrp:FindFirstChild("MobAnchorBP")
    if oldBP then oldBP:Destroy() end

    hrp.CFrame = mHrp.CFrame * _G.MethodFarm
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    if _G.EnableEquipWeapon then
        EquipWeapon()
    end

    local skillFired = TryFireSkill()
    if not skillFired then
        Attack()
    end

    return true
end

local function CleanupMobAnchor()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local bp = hrp:FindFirstChild("MobAnchorBP")
        if bp then bp:Destroy() end
    end
end

-- ============================================================
-- FIND MOB HELPERS
-- ============================================================
local function GetMobFolder()
    return workspace:FindFirstChild("Mob") or workspace:FindFirstChild("Mobs")
end

local function GetNearestMob()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local mobFolder = GetMobFolder()
    if not mobFolder then return nil end

    local nearest, minDist = nil, math.huge
    for _, mob in ipairs(mobFolder:GetChildren()) do
        if mob:IsA("Model") then
            local hum = mob:FindFirstChild("Humanoid")
            local mHrp = mob:FindFirstChild("HumanoidRootPart")
            if hum and mHrp and hum.Health > 0 then
                local d = (hrp.Position - mHrp.Position).Magnitude
                if d < minDist then minDist = d; nearest = mob end
            end
        end
    end
    return nearest
end

local function GetMobByName(mobName)
    local mobFolder = GetMobFolder()
    if not mobFolder then return nil end
    for _, mob in ipairs(mobFolder:GetChildren()) do
        if mob:IsA("Model") and mob.Name == mobName then
            local hum = mob:FindFirstChild("Humanoid")
            local mHrp = mob:FindFirstChild("HumanoidRootPart")
            if hum and mHrp and hum.Health > 0 then
                return mob
            end
        end
    end
    return nil
end

local function GetBossFolder()
    return workspace:FindFirstChild("Boss")
end

local function GetQuestByLevel(lvl)
    local bestQuest = nil
    local bestLevel = -1

    for _, q in ipairs(Quest_List) do
        if lvl >= q.Level and q.Level > bestLevel then
            bestLevel = q.Level
            bestQuest = q
        end
    end

    return bestQuest
end

local function GetQuestFrame()
    local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
    if not hud then return nil end
    local main = hud:FindFirstChild("Main")
    if not main then return nil end
    return main:FindFirstChild("Frame_Quest")
end

-- ============================================================
-- 🆕 GOKU NPC — Power God
-- ============================================================
local GOKU_KEYWORDS = {"goku", "vegeta", "gohan", "goten", "trunk", "bardock"}

_G.AutoGokuFind = false
_G.AutoGokuTP   = false
_G.GokuData     = {}
_G.GokuSessionNPCSpawned = {}
_G.GokuSessionSpawnedCount = 0
_G.GokuIgnoreSpawned = {}
_G.GokuMaxNPCPerSession = 5
_G.GokuMissThreshold = 5

local function GokuResetSession()
    for npcName in pairs(_G.GokuSessionNPCSpawned) do
        _G.GokuIgnoreSpawned[npcName] = true
    end
    _G.GokuData = {}
    _G.GokuSessionNPCSpawned = {}
    _G.GokuSessionSpawnedCount = 0
    print("[Goku] 🔄 Reset session")
end

-- 🆕 Lấy TẤT CẢ NPC (kể cả chưa spawn)
local function GokuGetAllNPCs()
    local allNPCs = {}
    local powerGod = workspace:FindFirstChild("Power God")
    if not powerGod then return allNPCs end

    for _, obj in ipairs(powerGod:GetChildren()) do
        if obj:IsA("Model") then
            local lower = obj.Name:lower()
            local matched = false
            for _, kw in ipairs(GOKU_KEYWORDS) do
                if lower:find(kw) then matched = true; break end
            end
            if matched then
                table.insert(allNPCs, obj.Name)
            end
        end
    end

    table.sort(allNPCs)
    return allNPCs
end

local function GokuScanNPCs()
    local results = {}
    local powerGod = workspace:FindFirstChild("Power God")
    if not powerGod then return results end

    local char = LocalPlayer.Character
    local myHrp = char and char:FindFirstChild("HumanoidRootPart")
    local now = tick()

    if _G.GokuSessionSpawnedCount >= _G.GokuMaxNPCPerSession then
        GokuResetSession()
        return results
    end

    for _, obj in ipairs(powerGod:GetChildren()) do
        if obj:IsA("Model") then
            local lower = obj.Name:lower()
            local matched = false
            for _, kw in ipairs(GOKU_KEYWORDS) do
                if lower:find(kw) then matched = true; break end
            end

            if matched then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                local hum = obj:FindFirstChild("Humanoid")
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                local dist = (myHrp and hrp) and (myHrp.Position - hrp.Position).Magnitude or -1

                local data = _G.GokuData[obj.Name]
                if not data then
                    local isNew = not _G.GokuIgnoreSpawned[obj.Name] and not _G.GokuSessionNPCSpawned[obj.Name]
                    data = {firstSeenAt = now, spawnClock = os.time(), lastSeen = now, isAlive = true}
                    _G.GokuData[obj.Name] = data

                    if isNew then
                        _G.GokuSessionNPCSpawned[obj.Name] = true
                        _G.GokuSessionSpawnedCount = _G.GokuSessionSpawnedCount + 1
                        print("[Goku] 🎯 Spawn: " .. obj.Name .. " (" .. _G.GokuSessionSpawnedCount .. "/5)")
                    end
                else
                    data.lastSeen = now
                    if not data.isAlive then
                        data.isAlive = true
                        data.firstSeenAt = now
                        data.spawnClock = os.time()
                        if _G.GokuIgnoreSpawned[obj.Name] then
                            _G.GokuIgnoreSpawned[obj.Name] = nil
                        end
                        if not _G.GokuSessionNPCSpawned[obj.Name] and _G.GokuSessionSpawnedCount < _G.GokuMaxNPCPerSession then
                            _G.GokuSessionNPCSpawned[obj.Name] = true
                            _G.GokuSessionSpawnedCount = _G.GokuSessionSpawnedCount + 1
                            print("[Goku] 🎯 Respawn: " .. obj.Name .. " (" .. _G.GokuSessionSpawnedCount .. "/5)")
                        end
                    end
                end

                table.insert(results, {
                    Name = obj.Name,
                    Model = obj,
                    Position = hrp and hrp.Position or Vector3.zero,
                    Health = hum and hum.Health or 0,
                    HasPrompt = prompt ~= nil,
                    Distance = dist,
                    Prompt = prompt,
                })
            end
        end
    end

    for name, data in pairs(_G.GokuData) do
        if now - data.lastSeen > _G.GokuMissThreshold and data.isAlive then
            data.isAlive = false
        end
    end

    table.sort(results, function(a, b)
        if a.Distance < 0 then return false end
        if b.Distance < 0 then return true end
        return a.Distance < b.Distance
    end)

    return results
end

local function GokuClickNPC(npcData)
    if not npcData or not npcData.Model or not npcData.Model.Parent then return false end
    local prompt = npcData.Prompt
    if not prompt or not prompt.Parent then return false end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    hrp.CFrame = CFrame.new(npcData.Position + Vector3.new(0, 5, 0))
    task.wait(0.2)
    pcall(function() fireproximityprompt(prompt) end)
    return true
end

-- Goku loop
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local npcs = GokuScanNPCs()

            if _G.AutoGokuTP and #npcs > 0 then
                local npc = npcs[1]
                if npc.Model and npc.Model.Parent then
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = CFrame.new(npc.Position + Vector3.new(0, 5, 0))
                    end
                end
            end

            if _G.AutoGokuFind and #npcs > 0 then
                for _, npc in ipairs(npcs) do
                    if npc.HasPrompt then
                        GokuClickNPC(npc)
                        task.wait(1)
                        break
                    end
                end
            end
        end)
    end
end)

-- ============================================================
-- 🆕 TELEPORT — Sea 1 Islands
-- ============================================================
local IslandCache = {}
local IslandList  = {}

local function ScanIslands()
    IslandCache = {}
    IslandList  = {}
    local islandFolder = workspace:FindFirstChild("island")
    if not islandFolder then return end

    local orderMap = {}
    local gates = workspace:FindFirstChild("Gates")
    local tpPart = gates and gates:FindFirstChild("TeleportPart")
    if tpPart then
        for i, part in ipairs(tpPart:GetChildren()) do
            if part:IsA("BasePart") then
                orderMap[part.Name] = i
            end
        end
    end

    local tempList = {}
    for _, obj in ipairs(islandFolder:GetChildren()) do
        if obj:IsA("Model") then
            local hrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            IslandCache[obj.Name] = {model = obj, pos = hrp and hrp.Position or Vector3.zero}
            table.insert(tempList, obj.Name)
        end
    end

    table.sort(tempList, function(a, b)
        local ia, ib = orderMap[a], orderMap[b]
        if ia and ib then return ia < ib end
        if ia and not ib then return true end
        if not ia and ib then return false end
        return a < b
    end)
    IslandList = tempList
end

ScanIslands()
print("[TP] Loaded " .. #IslandList .. " islands")

_G.TPSelectedIsland = nil

-- ============================================================
-- 🆕 AUTO RAID MOON
-- ============================================================
task.spawn(function()
    while task.wait() do
        pcall(function()
            if not _G.AutoRaidMoon then return end

            -- Đang ở Moon Map
            if game.PlaceId == MOON_PLACE_ID then
                local mobFolder = GetMobFolder()
                if mobFolder then
                    for _, v in ipairs(mobFolder:GetChildren()) do
                        if v:IsA("Model")
                           and v:FindFirstChild("Humanoid")
                           and v:FindFirstChild("HumanoidRootPart")
                           and v.Humanoid.Health > 0 then

                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0

                            repeat task.wait()
                                if not _G.AutoRaidMoon then break end
                                if not v.Parent then break end
                                if not v:FindFirstChild("Humanoid") then break end
                                if v.Humanoid.Health <= 0 then break end

                                if _G.EnableEquipWeapon then EquipWeapon() end

                                local skillFired = TryFireSkill()
                                if not skillFired then Attack() end

                                local char = LocalPlayer.Character
                                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    hrp.CFrame = v.HumanoidRootPart.CFrame * _G.MethodFarm
                                    hrp.AssemblyLinearVelocity = Vector3.zero
                                    hrp.AssemblyAngularVelocity = Vector3.zero
                                end
                            until false
                        end
                    end
                end
            else
                -- Sea 1: cần lên Moon
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                -- Check portal Moon Zone
                local moonZone = workspace:FindFirstChild("TeleportMoonZone")
                if moonZone and moonZone:FindFirstChild("Hitbox") then
                    hrp.CFrame = moonZone.Hitbox:GetPivot() * CFrame.new(0, -8, 0)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    return
                end

                -- Có Space Ticket → TP tới NPC GoMoon
                if GetItemAmount("Space Ticket") >= 1 then
                    local npcPrompt = workspace:FindFirstChild("NpcPrompt")
                    local goMoon = npcPrompt and npcPrompt:FindFirstChild("GoMoon")
                    if goMoon then
                        local npcHrp = goMoon:FindFirstChild("HumanoidRootPart")
                        if npcHrp then
                            hrp.CFrame = npcHrp.CFrame * CFrame.new(0, 5, 0)
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero

                            task.wait(0.3)

                            local prompt = npcHrp:FindFirstChildOfClass("ProximityPrompt")
                            if prompt then
                                pcall(function() fireproximityprompt(prompt) end)
                            end
                        end
                    end
                else
                    -- Không có Space Ticket → random chest / farm quest
                    local Diamond = LocalPlayer:GetAttribute("Diamond") or 0
                    if Diamond >= 150 then
                        if NetworkEvent then
                            NetworkEvent:FireServer("fire", nil, "RandomItem", "x15")
                        end
                    else
                        local myLevel = tonumber(LocalPlayer:GetAttribute("Level")) or 1
                        local quest = GetQuestByLevel(myLevel)
                        if quest and quest.Quest then
                            local Frame = GetQuestFrame()
                            if Frame then
                                local Text = Frame.Title.Text or ""

                                if LocalPlayer.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
                                    NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                                end

                                if Frame.Visible and not string.find(Text, quest.Monster) then
                                    NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                                    repeat task.wait() until not Frame.Visible
                                end

                                if not Frame.Visible then
                                    local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
                                    if npc then
                                        hrp.CFrame = CFrame.new(npc.Position + Vector3.new(0, 3, 0))
                                        hrp.AssemblyLinearVelocity = Vector3.zero
                                        hrp.AssemblyAngularVelocity = Vector3.zero
                                        task.wait(0.3)
                                        local pro = npc:FindFirstChildOfClass("ProximityPrompt")
                                        if pro then fireproximityprompt(pro) end
                                    end
                                else
                                    local mobFolder = GetMobFolder()
                                    if mobFolder then
                                        for _, v in ipairs(mobFolder:GetChildren()) do
                                            if v:IsA("Model")
                                               and v.Name == quest.Monster
                                               and v:FindFirstChild("Humanoid")
                                               and v:FindFirstChild("HumanoidRootPart")
                                               and v.Humanoid.Health > 0 then
                                                local mHrp = v:FindFirstChild("HumanoidRootPart")
                                                v.Humanoid.WalkSpeed = 0
                                                v.Humanoid.JumpPower = 0

                                                repeat task.wait()
                                                    if not _G.AutoRaidMoon then break end
                                                    if not v.Parent then break end
                                                    if not v:FindFirstChild("Humanoid") then break end
                                                    if v.Humanoid.Health <= 0 then break end

                                                    if _G.EnableEquipWeapon then EquipWeapon() end

                                                    hrp.CFrame = mHrp.CFrame * _G.MethodFarm
                                                    hrp.AssemblyLinearVelocity = Vector3.zero
                                                    hrp.AssemblyAngularVelocity = Vector3.zero

                                                    local skillFired = TryFireSkill()
                                                    if not skillFired then Attack() end
                                                until false
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- ============================================================
-- AUTO CLAIM GUARANTEE
-- ============================================================
task.spawn(function()
    local lastGuaranteeFire = 0
    local GUARANTEE_FIRE_DELAY = 0.3

    while task.wait(0.05) do
        pcall(function()
            if not _G.AutoClaimGuarantee then return end
            if not _G.CraftAutoRunning then return end
            if not _G.CraftSelectedItem or _G.CraftSelectedItem == "" then return end

            local now = tick()
            local cur, max = GetGuaranteeCount(_G.CraftSelectedItem)

            if max > 0 and cur >= max then
                if now - lastGuaranteeFire >= GUARANTEE_FIRE_DELAY then
                    lastGuaranteeFire = now
                    if NetworkEvent then
                        NetworkEvent:FireServer("fire", nil, "CraftTable", _G.CraftSelectedItem, "Guarantee")
                    end
                    print("[Craft] 🎁 Claimed Guarantee: " .. _G.CraftSelectedItem .. " (" .. cur .. "/" .. max .. ")")
                end
            end
        end)
    end
end)

-- ============================================================
-- AUTO CRAFT LOOP
-- ============================================================
task.spawn(function()
    local lastCraftTime = 0
    local GUARANTEE_CLEAR_WAIT = 0.5

    while task.wait(0.05) do
        pcall(function()
            local now = tick()

            if not _G.CraftAutoRunning then
                if _G.CraftPhase ~= "waiting" then
                    _G.CraftPhase = "waiting"
                    _G.CraftCountSinceClaim = 0
                end
                return
            end

            if not _G.CraftSelectedItem or _G.CraftSelectedItem == "" then return end

            local Data = CraftingTable and CraftingTable[_G.CraftSelectedItem]
            if not Data or not Data.need then
                if now - (_G.LastCraftWarn or 0) > 5 then
                    _G.LastCraftWarn = now
                    print("[Craft] ❌ Không tìm thấy công thức: " .. _G.CraftSelectedItem)
                end
                return
            end

            local cur, max = GetGuaranteeCount(_G.CraftSelectedItem)

            if max > 0 and cur >= max then
                if _G.CraftPhase ~= "waiting_guarantee" then
                    _G.CraftPhase = "waiting_guarantee"
                    print("[Craft] ⏸️ Guarantee đầy (" .. cur .. "/" .. max .. ") — chờ claim")
                end
                return
            end

            if _G.CraftPhase == "waiting_guarantee" and (max == 0 or cur < max) then
                _G.CraftPhase = "syncing"
                _G.CraftLastSync = now
                _G.CraftCountSinceClaim = 0
                lastCraftTime = now
                return
            end

            if _G.CraftPhase == "syncing" then
                if now - (_G.CraftLastSync or 0) >= GUARANTEE_CLEAR_WAIT then
                    _G.CraftPhase = "waiting"
                    lastCraftTime = now
                end
                return
            end

            if Data.NeedClass then
                local playerClass = LocalPlayer:GetAttribute("UseClass")
                if playerClass ~= Data.NeedClass then
                    if now - (_G.LastCraftWarn or 0) > 5 then
                        _G.LastCraftWarn = now
                        print("[Craft] ⚠️ Thiếu Class: " .. Data.NeedClass)
                    end
                    return
                end
            end

            local needBeli = (Data.PlayerData and Data.PlayerData.Beli) or Data.Beli or 0
            local currentBeli = tonumber(LocalPlayer:GetAttribute("Beli")) or 0
            if needBeli > 0 and currentBeli < needBeli then
                if now - (_G.LastCraftWarn or 0) > 5 then
                    _G.LastCraftWarn = now
                    print("[Craft] ⚠️ Thiếu Beli. Cần: " .. needBeli)
                end
                return
            end

            local CanCraft = true
            local missing = {}
            for Item, Need in pairs(Data.need) do
                local have = GetItemAmount(Item)
                if have < Need then
                    CanCraft = false
                    table.insert(missing, Item .. " (" .. have .. "/" .. Need .. ")")
                end
            end

            if not CanCraft then
                if _G.CraftPhase ~= "waiting" then
                    _G.CraftPhase = "waiting"
                end
                if now - (_G.LastCraftWarn or 0) > 5 then
                    _G.LastCraftWarn = now
                    print("[Craft] ❌ Thiếu Materials: " .. table.concat(missing, ", "))
                end
                return
            end

            local craftDelay = tonumber(_G.CraftDelay) or 1.0
            if craftDelay < 0.1 then craftDelay = 0.1 end

            if now - lastCraftTime >= craftDelay then
                lastCraftTime = now
                _G.CraftPhase = "crafting"
                _G.CraftCountSinceClaim = _G.CraftCountSinceClaim + 1

                if NetworkEvent then
                    NetworkEvent:FireServer("fire", nil, "CraftTable", _G.CraftSelectedItem, "Craft")
                    print("[Craft] 🔨 Crafting: " .. _G.CraftSelectedItem .. " (" .. _G.CraftCountSinceClaim .. " lần)")
                end
            end
        end)
    end
end)

-- ============================================================
-- AUTO CRAFT WEAPON
-- ============================================================
task.spawn(function()
    local lastCraftTime = 0
    local CRAFT_INTERVAL = 1.0

    while task.wait(0.1) do
        pcall(function()
            if not _G.AutoCraftWeaponRunning then
                _G.AutoCraftWeaponCurrent = nil
                return
            end

            local targetWeapon = _G.CraftWeaponSelectedItem

            local cur, max = GetGuaranteeCount(targetWeapon or _G.AutoCraftWeaponCurrent or "")
            if max > 0 and cur >= max then
                return
            end

            local now = tick()
            if now - lastCraftTime < CRAFT_INTERVAL then return end

            local itemsToCheck = {}
            if targetWeapon and targetWeapon ~= "" then
                itemsToCheck = {targetWeapon}
            else
                for itemName in pairs(UseItems or {}) do
                    table.insert(itemsToCheck, itemName)
                end
            end

            for _, itemName in ipairs(itemsToCheck) do
                local Data = UseItems and UseItems[itemName]
                if Data and Data.Inventory then
                    local classOK = true
                    if Data.NeedClass then
                        local playerClass = LocalPlayer:GetAttribute("UseClass")
                        if playerClass ~= Data.NeedClass then
                            classOK = false
                        end
                    end

                    local beliOK = true
                    local needBeli = (Data.PlayerData and Data.PlayerData.Beli) or 0
                    local currentBeli = tonumber(LocalPlayer:GetAttribute("Beli")) or 0
                    if needBeli > 0 and currentBeli < needBeli then
                        beliOK = false
                    end

                    local materialsOK = true
                    if classOK and beliOK then
                        local inv = GetInventory()
                        for Item, Need in pairs(Data.Inventory) do
                            local Have = (inv[Item] and inv[Item].amount) or 0
                            if Have < Need then
                                materialsOK = false
                                break
                            end
                        end
                    else
                        materialsOK = false
                    end

                    if classOK and beliOK and materialsOK then
                        _G.AutoCraftWeaponCurrent = itemName
                        lastCraftTime = now

                        if NetworkEvent then
                            local itemType = Data.Type or "Craft"
                            NetworkEvent:FireServer("fire", nil, "Craft", itemName, itemType)
                            print("[CraftWeapon] ✅ Chế thành công: " .. itemName)
                        end
                        return
                    end
                end
            end

            if now - (_G.LastCraftWeaponWarn or 0) > 10 then
                _G.LastCraftWeaponWarn = now
                if targetWeapon and targetWeapon ~= "" then
                    print("[CraftWeapon] ⏳ Không đủ nguyên liệu chế: " .. targetWeapon)
                else
                    print("[CraftWeapon] ⏳ Không đủ vật phẩm để chế weapon nào")
                end
            end
        end)
    end
end)

-- ============================================================
-- 🆕 AUTO FARM CRAFT ITEMS v85 — Fix respawn
-- ============================================================
_G.LastCharacter = nil
_G.CraftFarmTargetMob = nil

local function CheckRespawn()
    local char = LocalPlayer.Character
    if not char then return false end
    if _G.LastCharacter ~= char then
        _G.LastCharacter = char
        return true
    end
    return false
end

-- 🆕 Listener respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.3)
    if not _G.AutoFarmCraftItems then return end

    _G.CraftFarmTargetItem = nil
    _G.LastCraftSpawnTP = 0
    _G.LastCharacter = newChar

    local target = _G.CraftFarmTargetMob
    if target and target.Parent then
        local mHrp = target:FindFirstChild("HumanoidRootPart")
        local newHrp = newChar:FindFirstChild("HumanoidRootPart")
        if mHrp and newHrp then
            newHrp.CFrame = mHrp.CFrame * _G.MethodFarm
            newHrp.AssemblyLinearVelocity = Vector3.zero
            newHrp.AssemblyAngularVelocity = Vector3.zero
            print("[FarmCraft] 💀→🚀 Respawn: TP ngay tới mob")
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if not _G.AutoFarmCraftItems then
                _G.CraftFarmTargetItem = nil
                return
            end

            local weapon = _G.CraftWeaponSelectedItem
            if not weapon or weapon == "" then return end

            local Data = UseItems and UseItems[weapon]
            if not Data or not Data.Inventory then return end

            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp or hum.Health <= 0 then return end

            -- 🆕 Respawn detection
            if CheckRespawn() then
                _G.CraftFarmTargetItem = nil
                _G.LastCraftSpawnTP = 0
                task.wait(0.5)
                return
            end

            local inv = GetInventory()

            -- Tìm item còn thiếu
            local targetItem = nil
            local minHave = math.huge

            for Item, Need in pairs(Data.Inventory) do
                local Have = (inv[Item] and inv[Item].amount) or 0
                if Have < Need then
                    local ratio = Have / Need
                    if ratio < minHave then
                        minHave = ratio
                        targetItem = Item
                    end
                end
            end

            if not targetItem then
                print("[FarmCraft] ✅ Đã đủ vật phẩm cho " .. weapon)
                _G.AutoFarmCraftItems = false
                return
            end

            -- Clean tên + match 4 lớp
            local cleanTarget = targetItem:gsub("^%s+", ""):gsub("%s+$", "")
            local mobNames = nil
            local matchLog = ""

            if ItemDrop[cleanTarget] then
                mobNames = ItemDrop[cleanTarget]
                matchLog = "exact"
            end

            if not mobNames then
                local lowerTarget = cleanTarget:lower()
                for itemName, mobs in pairs(ItemDrop) do
                    if itemName:lower() == lowerTarget then
                        mobNames = mobs
                        matchLog = "case-insensitive"
                        break
                    end
                end
            end

            if not mobNames then
                local lowerTarget = cleanTarget:lower():gsub("%s+", "")
                for itemName, mobs in pairs(ItemDrop) do
                    local lowerItem = itemName:lower():gsub("%s+", "")
                    if lowerItem == lowerTarget
                       or lowerItem:find(lowerTarget, 1, true)
                       or lowerTarget:find(lowerItem, 1, true) then
                        mobNames = mobs
                        matchLog = "fuzzy"
                        break
                    end
                end
            end

            if not mobNames then
                local mobFolder = GetMobFolder()
                if mobFolder then
                    local lowerTarget = cleanTarget:lower():gsub("%s+", "")
                    for _, mob in ipairs(mobFolder:GetChildren()) do
                        if mob:IsA("Model") then
                            local mobLower = mob.Name:lower():gsub("%s+", "")
                            if mobLower == lowerTarget or mobLower:find(lowerTarget, 1, true) then
                                mobNames = {mob.Name}
                                matchLog = "mob match"
                                break
                            end
                        end
                    end
                end
            end

            if not mobNames or #mobNames == 0 then
                if tick() - (_G.LastFarmCraftWarn or 0) > 5 then
                    _G.LastFarmCraftWarn = tick()
                    print("[FarmCraft] ❌ Không tìm thấy mob drop: '" .. targetItem .. "'")
                end
                return
            end

            _G.CraftFarmTargetItem = targetItem

            -- Tìm mob trong workspace
            local Target
            local mobFolder = GetMobFolder()
            if mobFolder then
                for _, Mob in ipairs(mobFolder:GetChildren()) do
                    if Mob:IsA("Model")
                       and table.find(mobNames, Mob.Name)
                       and Mob:FindFirstChild("Humanoid")
                       and Mob:FindFirstChild("HumanoidRootPart")
                       and Mob.Humanoid.Health > 0 then
                        Target = Mob
                        break
                    end
                end
            end

            if not Target then
                -- Cooldown TP
                if tick() - (_G.LastCraftSpawnTP or 0) < 3 then
                    return
                end
                _G.LastCraftSpawnTP = tick()

                -- TP tới spawn point (4 lớp)
                local mobName = mobNames[1]
                local spawnPos = nil
                local spawnFound = false

                if Itemdrops then
                    local Spawn = Itemdrops:FindFirstChild(mobName)
                    if Spawn and Spawn:IsA("Model") then
                        spawnPos = Spawn:GetPivot().Position
                        spawnFound = true
                        print("[FarmCraft] 🎯 TP tới spawn (Itemdrops): " .. mobName)
                    elseif Spawn and Spawn:IsA("BasePart") then
                        spawnPos = Spawn.Position
                        spawnFound = true
                        print("[FarmCraft] 🎯 TP tới spawn (Itemdrops part): " .. mobName)
                    end
                end

                if not spawnFound and Itemdrops then
                    local mobLower = mobName:lower():gsub("%s+", "")
                    for _, entry in ipairs(Itemdrops:GetChildren()) do
                        local entryLower = entry.Name:lower():gsub("%s+", "")
                        if entryLower == mobLower
                           or entryLower:find(mobLower, 1, true)
                           or mobLower:find(entryLower, 1, true) then
                            local part = entry:IsA("Model") and (entry.PrimaryPart or entry:FindFirstChildWhichIsA("BasePart"))
                                          or (entry:IsA("BasePart") and entry)
                            if part then
                                spawnPos = part.Position
                                spawnFound = true
                                print("[FarmCraft] 🎯 TP tới spawn (fuzzy): " .. entry.Name)
                                break
                            end
                        end
                    end
                end

                if not spawnFound then
                    local msg = workspace:FindFirstChild("MobSpawnGroup")
                    if msg then
                        for _, group in ipairs(msg:GetChildren()) do
                            local gLower = group.Name:lower():gsub("%s+", "")
                            local mLower = mobName:lower():gsub("%s+", "")
                            if gLower:find(mLower, 1, true) or mLower:find(gLower, 1, true) then
                                local part = group:FindFirstChildWhichIsA("BasePart", true)
                                if part then
                                    spawnPos = part.Position
                                    spawnFound = true
                                    print("[FarmCraft] 🎯 TP tới spawn (MobSpawnGroup): " .. group.Name)
                                    break
                                end
                            end
                        end
                    end
                end

                if spawnFound and spawnPos then
                    hrp.CFrame = CFrame.new(spawnPos + Vector3.new(0, 10, 0))
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                else
                    if tick() - (_G.LastFarmCraftWarn or 0) > 5 then
                        _G.LastFarmCraftWarn = tick()
                        print("[FarmCraft] ⏳ Mob chưa spawn, không tìm thấy spawn: " .. mobName)
                    end
                end
                return
            end

            -- 🆕 Lưu target mob để respawn có thể dùng
            _G.CraftFarmTargetMob = Target

            -- Farm mob
            local mHrp = Target:FindFirstChild("HumanoidRootPart")
            local mHum = Target:FindFirstChild("Humanoid")
            if mHrp and mHum then
                mHum.WalkSpeed = 0
                mHum.JumpPower = 0

                repeat task.wait()
                    if not _G.AutoFarmCraftItems then break end
                    if not Target.Parent then break end
                    if not Target:FindFirstChild("Humanoid") then break end
                    if Target.Humanoid.Health <= 0 then break end
                    if not mHrp or not mHrp.Parent then break end

                    -- 🆕 Respawn check (nhanh)
                    local currentChar = LocalPlayer.Character
                    if _G.LastCharacter and currentChar ~= _G.LastCharacter then
                        _G.LastCharacter = currentChar
                        _G.LastCraftSpawnTP = 0
                        print("[FarmCraft] 💀 Phát hiện respawn → TP lại")
                        break
                    end

                    local curHum = currentChar and currentChar:FindFirstChild("Humanoid")
                    if not curHum or curHum.Health <= 0 then break end

                    -- Check còn cần không
                    local inv2 = GetInventory()
                    local stillNeed = false
                    if Data.Inventory[targetItem] then
                        local need = Data.Inventory[targetItem]
                        local have = (inv2[targetItem] and inv2[targetItem].amount) or 0
                        if have < need then
                            stillNeed = true
                        end
                    end
                    if not stillNeed then break end

                    if _G.EnableEquipWeapon then
                        EquipWeapon()
                    end

                    hrp.CFrame = mHrp.CFrame * _G.MethodFarm
                    hrp.AssemblyLinearVelocity  = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero

                    local skillFired = TryFireSkill()
                    if not skillFired then
                        Attack()
                    end
                until false
            end
        end)
    end
end)

-- ============================================================
-- AUTO BUY SHOP RAID
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if IsMoonMap then return end
            if not _G.ShopRaidAuto then return end
            if not _G.ShopRaidItem or _G.ShopRaidItem == "" then return end

            if NetworkEvent then
                NetworkEvent:FireServer("fire", nil, "buy_raidshop", _G.ShopRaidItem)
            end
        end)
    end
end)

-- ============================================================
-- AUTO BUY SHOP DUNGEON
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if IsMoonMap then return end
            if not _G.ShopDungeonAuto then return end
            if not _G.ShopDungeonItem or _G.ShopDungeonItem == "" then return end

            if NetworkEvent then
                NetworkEvent:FireServer("fire", nil, "BuyDungeonShop", _G.ShopDungeonItem)
            end
        end)
    end
end)

-- ============================================================
-- AUTO REFRESH CRAFT LIST
-- ============================================================
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if IsMoonMap then return end
            local items = GetCraftTableItems()
            if #items == 0 then return end

            local str = table.concat(items, ",")
            if str ~= _G.LastCraftListStr then
                _G.LastCraftListStr = str
                CraftItemList = items

                if _G.CraftDropdown then
                    pcall(function()
                        if _G.CraftDropdown.SetValues then
                            _G.CraftDropdown:SetValues(items)
                        elseif _G.CraftDropdown.Set then
                            _G.CraftDropdown:Set(items)
                        elseif _G.CraftDropdown.Refresh then
                            _G.CraftDropdown:Refresh(items)
                        end
                    end)
                end
                print("[Craft] 🔄 Refreshed: " .. #items .. " items")
            end
        end)
    end
end)

-- ============================================================
-- AUTO REFRESH SHOP ITEMS
-- ============================================================
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if IsMoonMap then return end

            local raidItems = GetShopRaidItems()
            if #raidItems > 0 then
                local str = table.concat(raidItems, ",")
                if str ~= _G.LastShopRaidStr then
                    _G.LastShopRaidStr = str
                    _G.ShopRaidItemsList = raidItems
                    if _G.ShopRaidDropdown then
                        pcall(function()
                            if _G.ShopRaidDropdown.SetValues then
                                _G.ShopRaidDropdown:SetValues(raidItems)
                            elseif _G.ShopRaidDropdown.Set then
                                _G.ShopRaidDropdown:Set(raidItems)
                            end
                        end)
                    end
                end
            end

            local dunItems = GetShopDungeonItems()
            if #dunItems > 0 then
                local str = table.concat(dunItems, ",")
                if str ~= _G.LastShopDungeonStr then
                    _G.LastShopDungeonStr = str
                    _G.ShopDungeonItemsList = dunItems
                    if _G.ShopDungeonDropdown then
                        pcall(function()
                            if _G.ShopDungeonDropdown.SetValues then
                                _G.ShopDungeonDropdown:SetValues(dunItems)
                            elseif _G.ShopDungeonDropdown.Set then
                                _G.ShopDungeonDropdown:Set(dunItems)
                            end
                        end)
                    end
                end
            end
        end)
    end
end)

-- ============================================================
-- AUTO BUY RANDOM SHOP
-- ============================================================
task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            if IsMoonMap then return end
            if not _G.RandomShopAuto then return end
            if not _G.RandomShopItem then return end

            local itemName = tostring(_G.RandomShopItem):match("^(.-) /") or _G.RandomShopItem
            itemName = itemName:gsub("^%s+", ""):gsub("%s+$", "")

            if itemName == "" then return end
            if NetworkEvent then
                NetworkEvent:FireServer("fire", nil, "BuyGaranteeRandomItem", itemName)
            end
        end)
    end
end)

-- ============================================================
-- AUTO RANDOM CHEST
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if IsMoonMap then return end
            if not _G.AutoRandomEnabled then return end
            if NetworkEvent then
                NetworkEvent:FireServer("fire", nil, "RandomItem", _G.AutoRandomValue or "x5")
            end
        end)
    end
end)

-- ============================================================
-- AUTO MOON CHEST
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if IsMoonMap then return end
            if not _G.AutoMoonEnabled then return end
            if NetworkEvent then
                NetworkEvent:FireServer("fire", nil, "EventMoon", _G.AutoMoonValue or "x5")
            end
        end)
    end
end)

-- ============================================================
-- CLEANUP ON LOAD
-- ============================================================
task.spawn(function()
    task.wait(0.5)
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, child in ipairs(hrp:GetChildren()) do
                if child.Name == "MobAnchorBP"
                   or child.Name == "QuestNPCHover"
                   or child.Name == "BossLockBP" then
                    pcall(function() child:Destroy() end)
                end
            end
            hrp.Anchored = false
        end
    end)
    print("[Cleanup] 🧹 Đã xóa body movers cũ")
end)

-- ============================================================
-- AUTO HAKI
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if not _G.AutoHaki then return end
            local char = LocalPlayer.Character
            if not char then return end
            if not char:FindFirstChild("HakiFolder") then
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                local act = remotes and remotes:FindFirstChild("Action")
                if act then
                    act:FireServer("Misc", "buso")
                end
            end
        end)
    end
end)

-- ============================================================
-- VFX
-- ============================================================
local VFX_Class = {
    ["ParticleEmitter"] = true,
    ["Beam"] = true,
    ["Trail"] = true,
    ["Sparkles"] = true,
    ["Fire"] = true,
    ["Smoke"] = true,
    ["Highlight"] = true,
    ["PointLight"] = true,
    ["SpotLight"] = true,
    ["SurfaceLight"] = true,
}

local function KillVFXIn(container)
    if not container then return end
    pcall(function()
        for _, v in ipairs(container:GetDescendants()) do
            if VFX_Class[v.ClassName] then
                pcall(function()
                    if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail")
                       or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles")
                       or v:IsA("Highlight") or v:IsA("PointLight")
                       or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
                        if v.Enabled then v.Enabled = false end
                    end
                end)
            end
        end
    end)
end

local VFX_Conn = nil
local function ApplyVFX(state)
    if VFX_Conn then
        pcall(function() VFX_Conn:Disconnect() end)
        VFX_Conn = nil
    end

    if not state then return end

    pcall(function()
        KillVFXIn(workspace)
        if workspace.CurrentCamera then KillVFXIn(workspace.CurrentCamera) end
        local char = LocalPlayer.Character
        if char then KillVFXIn(char) end
    end)

    VFX_Conn = workspace.DescendantAdded:Connect(function(obj)
        if not _G.DisableVFX then return end
        if VFX_Class[obj.ClassName] then
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail")
                   or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles")
                   or obj:IsA("Highlight") or obj:IsA("PointLight")
                   or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                    if obj.Enabled then obj.Enabled = false end
                end
            end)
        end
    end)
end

-- ============================================================
-- MAIN FARM LOOP (Sea 1 only)
-- ============================================================
if not IsMoonMap then
    task.spawn(function()
        while task.wait() do
            pcall(function()
                if not _G.AutoFarm then return end
                local mob = GetNearestMob()
                if mob then AttackMob(mob) end
            end)
        end
    end)
end

-- ============================================================
-- FARM LEVEL LOOP (Sea 1 only)
-- ============================================================
_G.QuestNPCHoverBP = nil

local function ClearQuestHover()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local bp = hrp:FindFirstChild("QuestNPCHover")
        if bp then bp:Destroy() end
    end
    _G.QuestNPCHoverBP = nil
end

if not IsMoonMap then
    task.spawn(function()
        while task.wait() do
            xpcall(function()
                if not _G.AutoFarmLevel then return end
                local char = LocalPlayer.Character
                local hum  = char and char:FindFirstChild("Humanoid")
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if not hum or not hrp or hum.Health <= 0 then return end
                local myLevel = tonumber(LocalPlayer:GetAttribute("Level")) or 1
                local quest = GetQuestByLevel(myLevel)
                if not quest or not quest.Quest then return end
                local Frame = GetQuestFrame()
                if not Frame then return end
                local Text = Frame.Title.Text or ""
                if LocalPlayer.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
                    NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                end

                if Frame.Visible and not string.find(Text, quest.Monster) then
                    NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                    repeat task.wait() until not Frame.Visible
                end

                if not Frame.Visible then
                    local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
                    if npc then
                        hrp.CFrame = CFrame.new(npc.Position + Vector3.new(0, 3, 0))
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        task.wait(0.3)
                        local pro = npc:FindFirstChildOfClass("ProximityPrompt")
                        if pro then fireproximityprompt(pro) end
                    end
                else
                    local mobFolder = GetMobFolder()
                    if not mobFolder then return end
                    for _, v in ipairs(mobFolder:GetChildren()) do
                        if v:IsA("Model") and v.Name == quest.Monster
                           and v:FindFirstChild("Humanoid")
                           and v:FindFirstChild("HumanoidRootPart")
                           and v.Humanoid.Health > 0 then
                            local mHrp = v:FindFirstChild("HumanoidRootPart")
                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0
                            repeat task.wait()
                                if not _G.AutoFarmLevel then break end
                                if not v.Parent then break end
                                if not v:FindFirstChild("Humanoid") then break end
                                if v.Humanoid.Health <= 0 then break end
                                if not mHrp or not mHrp.Parent then break end
                                if _G.EnableEquipWeapon then EquipWeapon() end
                                hrp.CFrame = mHrp.CFrame * _G.MethodFarm
                                hrp.AssemblyLinearVelocity  = Vector3.zero
                                hrp.AssemblyAngularVelocity = Vector3.zero

                                local skillFired = TryFireSkill()
                                if not skillFired then Attack() end
                            until false
                            return
                        end
                    end
                end
            end, print)
        end
    end)
end

-- ============================================================
-- FARM MATERIAL LOOP (Sea 1 only)
-- ============================================================
if not IsMoonMap then
    task.spawn(function()
        while task.wait() do
            xpcall(function()
                if not _G.AutoFarmMaterial then return end
                if type(_G.SelectMaterials) ~= "table" or #_G.SelectMaterials == 0 then return end

                local char = LocalPlayer.Character
                local hum  = char and char:FindFirstChild("Humanoid")
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if not hum or not hrp or hum.Health <= 0 then return end

                local mobFolder = GetMobFolder()
                if not mobFolder then return end

                for _, Material in ipairs(_G.SelectMaterials) do
                    local MobNames = ItemDrop[Material]
                    if MobNames then
                        for _, MobName in ipairs(MobNames) do
                            local Target
                            for _, Mob in ipairs(mobFolder:GetChildren()) do
                                if Mob:IsA("Model")
                                   and Mob.Name == MobName
                                   and Mob:FindFirstChild("Humanoid")
                                   and Mob:FindFirstChild("HumanoidRootPart")
                                   and Mob.Humanoid.Health > 0 then
                                    Target = Mob
                                    break
                                end
                            end

                            if not Target then
                                local Spawn = Itemdrops and Itemdrops:FindFirstChild(MobName)
                                if Spawn and Spawn:IsA("Model") then
                                    pcall(function()
                                        hrp.CFrame = Spawn:GetPivot() + Vector3.new(0, 5, 0)
                                        hrp.AssemblyLinearVelocity = Vector3.zero
                                        hrp.AssemblyAngularVelocity = Vector3.zero
                                    end)
                                    task.wait(1.5)
                                end
                            else
                                local mHrp = Target:FindFirstChild("HumanoidRootPart")
                                if mHrp then
                                    Target.Humanoid.WalkSpeed = 0
                                    Target.Humanoid.JumpPower = 0
                                    local startTime = tick()

                                    repeat task.wait()
                                        if not _G.AutoFarmMaterial then break end
                                        if not Target.Parent then break end
                                        if not Target:FindFirstChild("Humanoid") then break end
                                        if Target.Humanoid.Health <= 0 then break end
                                        if not mHrp or not mHrp.Parent then break end
                                        if tick() - startTime >= 10 then break end

                                        if _G.EnableEquipWeapon then EquipWeapon() end

                                        hrp.CFrame = mHrp.CFrame * _G.MethodFarm
                                        hrp.AssemblyLinearVelocity  = Vector3.zero
                                        hrp.AssemblyAngularVelocity = Vector3.zero

                                        local skillFired = TryFireSkill()
                                        if not skillFired then Attack() end
                                    until false
                                    return
                                end
                            end
                        end
                    end
                end
            end, print)
        end
    end)
end

-- ============================================================
-- AUTO BOSS FULL (Sea 1 only)
-- ============================================================
if not IsMoonMap then
    task.spawn(function()
        while task.wait() do
            xpcall(function()
                if not _G.AutoBossFull then return end

                local bf = GetBossFolder()
                if bf then
                    for _, mob in ipairs(bf:GetChildren()) do
                        if mob:IsA("Model")
                           and table.find(Bosses, mob.Name)
                           and mob:FindFirstChild("Humanoid")
                           and mob:FindFirstChild("HumanoidRootPart")
                           and mob.Humanoid.Health > 0 then
                            AttackMob(mob)
                            return
                        end
                    end
                end

                if _G.SelectBoss then
                    local orb = GetItemAmount("Orb Boss")
                    if orb >= 1 then
                        NetworkEvent:FireServer("fire", nil, "SummonBoss", _G.SelectBoss)
                    end
                end
            end, print)
        end
    end)
end

-- ---- AUTO PICCOLO ----
if not IsMoonMap then
    task.spawn(function()
        while task.wait() do
            pcall(function()
                if not _G.AutoPiccolo then return end
                local mob = GetMobByName("Piccolo")
                if mob then AttackMob(mob) end
            end)
        end
    end)
end

-- ---- AUTO DEVIL BOAT ----
if not IsMoonMap then    task.spawn(function()
        local wasActive = false
        while task.wait() do
            pcall(function()
                if not _G.AutoDevilBoat then
                    if wasActive then
                        wasActive = false
                        CleanupMobAnchor()
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        local hum = char and char:FindFirstChild("Humanoid")

                        if hrp then
                            hrp.Anchored = false
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end

                        if hum then
                            hum.PlatformStand = false
                            hum.WalkSpeed = 16
                            hum.JumpPower = 50
                            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                        end
                        _G.AntiFallDisabled = tick() + 2
                    end
                    return
                end

                wasActive = true

                local mob = GetMobByName("Devil Boat") or GetMobByName("DevilBoat")
                if mob then
                    AttackMob(mob)
                end
            end)
        end
    end)
end

-- ---- AUTO KRAKEN ----
if not IsMoonMap then
    task.spawn(function()
        while task.wait() do
            pcall(function()
                if not _G.AutoKraken then return end
                local mob = GetMobByName("Kraken")
                if mob then AttackMob(mob) end
            end)
        end
    end)
end

-- ============================================================
-- AUTO DUCK FULL (Sea 1 only)
-- ============================================================
if not IsMoonMap then
    task.spawn(function()
        while task.wait(0.15) do
            pcall(function()
                if not _G.AutoDuckFull then
                    _G.DuckSummonCooldown = 0
                    return
                end

                local char = LocalPlayer.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local mob = GetMobByName("Duck Monster")

                if mob then
                    local mHrp = mob:FindFirstChild("HumanoidRootPart")
                    local mHum = mob:FindFirstChild("Humanoid")

                    if mHrp and mHum and mHum.Health > 0 then
                        mHum.WalkSpeed = 0
                        mHum.JumpPower = 0

                        repeat
                            task.wait()
                            if not _G.AutoDuckFull then break end
                            if not mob.Parent then break end
                            if not mHum or mHum.Health <= 0 then break end
                            if not mHrp or not mHrp.Parent then break end
                            AttackMob(mob)
                        until false
                        ClearDashBodyMovers()
                    end
                    return
                end

                if tick() < _G.DuckSummonCooldown then return end

                local DuckItems = {"Duck", "Duck2", "Duck3", "Duck4", "Duck5", "Duck6", "Duck7"}
                local haveAll = true
                for _, item in ipairs(DuckItems) do
                    if GetItemAmount(item) <= 0 then
                        haveAll = false
                        break
                    end
                end

                if not haveAll then return end

                local npcPrompt = workspace:FindFirstChild("NpcPrompt")
                local duckNPC = npcPrompt and npcPrompt:FindFirstChild("DuckMonster")
                if not duckNPC then duckNPC = workspace:FindFirstChild("DuckMonster") end

                if duckNPC then
                    local npcHrp = duckNPC:FindFirstChild("HumanoidRootPart")
                        or duckNPC:FindFirstChildWhichIsA("BasePart")

                    if npcHrp then
                        ClearDashBodyMovers()
                        hrp.CFrame = CFrame.new(npcHrp.Position + Vector3.new(0, 3, 0))
                        hrp.AssemblyLinearVelocity  = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero

                        task.wait(0.3)

                        local prompt = npcHrp:FindFirstChildWhichIsA("ProximityPrompt")
                            or duckNPC:FindFirstChildWhichIsA("ProximityPrompt", true)

                        if prompt then
                            pcall(function() fireproximityprompt(prompt) end)
                            _G.DuckSummonCooldown = tick() + 1
                            print("[AutoDuck] 🦆 Summoned Duck Monster!")
                        end
                    end
                end
            end)
        end
    end)
end

-- ============================================================
-- AUTO THIEF CHEST (Sea 1 only)
-- ============================================================
if not IsMoonMap then
    task.spawn(function()
        local CurrentSpawn = 1
        while task.wait() do
            pcall(function()
                if not _G.AutoThiefChest then return end

                local msg = workspace:FindFirstChild("MobSpawnGroup")
                if not msg then return end
                local spawns = msg:GetChildren()
                local spawn = spawns[CurrentSpawn]
                if not spawn then CurrentSpawn = 1; return end

                local chestRef = spawn:FindFirstChild("ChestRef", true)
                if not chestRef then
                    CurrentSpawn = CurrentSpawn + 1
                    if CurrentSpawn > #spawns then CurrentSpawn = 1 end
                    return
                end

                local target
                local minDist = 30
                local mobFolder = GetMobFolder()
                if mobFolder then
                    for _, mob in ipairs(mobFolder:GetChildren()) do
                        if mob:IsA("Model") and mob.Name == "Bacon Thief"
                           and mob:FindFirstChild("HumanoidRootPart")
                           and mob:FindFirstChild("Humanoid")
                           and mob.Humanoid.Health > 0 then
                            local d = (mob.HumanoidRootPart.Position - chestRef.Position).Magnitude
                            if d < minDist then minDist = d; target = mob end
                        end
                    end
                end

                if target then
                    AttackMob(target)
                else
                    local prompt = chestRef:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.ActionText == "Open" then
                        Teleport(chestRef.CFrame * CFrame.new(0, 3, 0))
                        pcall(function() fireproximityprompt(prompt) end)
                    else
                        CurrentSpawn = CurrentSpawn + 1
                        if CurrentSpawn > #spawns then CurrentSpawn = 1 end
                    end
                end
            end)
        end
    end)
end

-- ============================================================
-- AUTO DUNGEON (Sea 1 only)
-- ============================================================
if not IsMoonMap then
    task.spawn(function()
        while task.wait() do
            xpcall(function()
                if not _G.AutoDungeon then
                    _G.DungeonState = "IDLE"
                    return
                end

                local Player    = LocalPlayer
                local Character = Player.Character
                if not Character then return end

                local Dungeon
                local DungeonId = Character:GetAttribute("Dungeon")
                local hrp = Character:FindFirstChild("HumanoidRootPart")
                local hum = Character:FindFirstChild("Humanoid")
                if not hrp or not hum then return end

                local pg = Player.PlayerGui
                if pg:FindFirstChild("WaveUI") and pg.WaveUI:FindFirstChild("AutoSkip") then
                    local autoSkip = pg.WaveUI.AutoSkip
                    if autoSkip.BackgroundColor3 == Color3.fromRGB(255, 69, 69) then
                        GuiService.SelectedObject = autoSkip
                        task.wait(0.1)
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                        task.wait(0.1)
                        GuiService.SelectedObject = nil
                    end
                end

                if DungeonId then
                    local dungeonMap = workspace:FindFirstChild("DungeonMap")
                    if dungeonMap then
                        Dungeon = dungeonMap:FindFirstChild("Dungeon_" .. DungeonId)
                    end
                end

                if Dungeon then
                    _G.DungeonState = "IN_DUNGEON"
                    local mobFolder = GetMobFolder()
                    if not mobFolder then return end

                    for _, Mob in ipairs(mobFolder:GetChildren()) do
                        if Mob:IsA("Model")
                           and Mob:FindFirstChild("Humanoid")
                           and Mob:FindFirstChild("HumanoidRootPart")
                           and Mob.Humanoid.Health > 0 then

                            local Distance = (Mob.HumanoidRootPart.Position - Dungeon:GetPivot().Position).Magnitude

                            if Distance <= 250 then
                                Mob.Humanoid.WalkSpeed = 0
                                Mob.Humanoid.JumpPower = 0

                                repeat
                                    task.wait()
                                    if not _G.AutoDungeon then break end
                                    if not Mob.Parent then break end
                                    if not Mob:FindFirstChild("Humanoid") then break end
                                    if Mob.Humanoid.Health <= 0 then break end

                                    local curHum = Character:FindFirstChild("Humanoid")
                                    if curHum and curHum.Health <= curHum.MaxHealth * ((_G.HealthPercent or 30) / 100) then
                                        local healHeight = 300
                                        repeat
                                            task.wait(0.1)
                                            if not _G.AutoDungeon then break end
                                            if not Dungeon or not Dungeon.Parent then break end
                                            local dungeonPivot = Dungeon:GetPivot()
                                            hrp.CFrame = CFrame.new(
                                                dungeonPivot.X,
                                                dungeonPivot.Y + healHeight,
                                                dungeonPivot.Z
                                            )
                                            hrp.AssemblyLinearVelocity = Vector3.zero
                                            hrp.AssemblyAngularVelocity = Vector3.zero
                                        until not _G.AutoDungeon or curHum.Health >= curHum.MaxHealth
                                    end

                                    if _G.EnableEquipWeapon then EquipWeapon() end

                                    hrp.CFrame = Mob.HumanoidRootPart.CFrame * _G.MethodFarm
                                    hrp.AssemblyLinearVelocity = Vector3.zero
                                    hrp.AssemblyAngularVelocity = Vector3.zero

                                    local skillFired = TryFireSkill()
                                    if not skillFired then Attack() end
                                until false
                            end
                        end
                    end
                    return
                end

                local TeleportZone = workspace:FindFirstChild("TeleportDungeonZone")
                if TeleportZone and TeleportZone:FindFirstChild("Hitbox") then
                    hrp.CFrame = TeleportZone.Hitbox.CFrame
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    _G.DungeonState = "ENTERING"
                    return
                end

                if _G.DungeonState == "WAITING_PORTAL" then
                    local npcPrompt = workspace:FindFirstChild("NpcPrompt")
                    local openDungeonNPC = npcPrompt and npcPrompt:FindFirstChild("Open Dungeon")
                    if openDungeonNPC then
                        local npcHrp = openDungeonNPC:FindFirstChild("HumanoidRootPart")
                            or openDungeonNPC:FindFirstChildWhichIsA("BasePart")
                        if npcHrp then
                            hrp.CFrame = CFrame.new(npcHrp.Position + Vector3.new(0, 2, 0))
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end
                    end
                    return
                end

                local amount = tonumber(_G.DungeonAmount) or 1
                if amount < 1 then amount = 1 end
                local orbAmount = GetItemAmount("Orb Dungeon")

                if orbAmount >= amount then
                    local npcPrompt = workspace:FindFirstChild("NpcPrompt")
                    local openDungeonNPC = npcPrompt and npcPrompt:FindFirstChild("Open Dungeon")
                    if openDungeonNPC then
                        local npcHrp = openDungeonNPC:FindFirstChild("HumanoidRootPart")
                            or openDungeonNPC:FindFirstChildWhichIsA("BasePart")
                        if npcHrp then
                            hrp.CFrame = npcHrp.CFrame * CFrame.new(0, 5, 0)
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                            task.wait(0.3)

                            if NetworkEvent then
                                NetworkEvent:FireServer("fire", nil, "SpawnDungeon", amount)
                                print("[Dungeon] 🏰 Opened portal with " .. amount .. " Orb Dungeon")
                                _G.DungeonState = "WAITING_PORTAL"

                                if tick() - _G.LastOrbNotify > 3 then
                                    _G.LastOrbNotify = tick()
                                    task.wait(0.3)
                                    local newOrbAmount = GetItemAmount("Orb Dungeon")
                                    Fluent:Notify({
                                        Title = "🏰 Auto Dungeon",
                                        Content = "Remaining Orb Dungeons: " .. tostring(newOrbAmount),
                                        Duration = 3
                                    })
                                end
                            end
                        end
                    end
                else
                    if tick() - (_G.LastDungeonWarn or 0) > 5 then
                        _G.LastDungeonWarn = tick()
                        print("[Dungeon] ⚠️ Not enough Orb. Need: " .. amount .. ", Have: " .. orbAmount)
                    end
                end
            end, function(err)
                warn("[Dungeon] Error: " .. tostring(err))
            end)
        end
    end)
end

-- ============================================================
-- 🆕 AUTO RAID BOSS BACON — v5 FINAL
-- - Buff SSJ trước khi mở cổng (nhanh như Dragon/Lava)
-- - 2 quả cầu vàng → đánh thường
-- - Boss Bacon HP < 50% → bám boss + spam F Thanos tại chỗ
-- - KHÔNG TP lên cao, KHÔNG giật vị trí
-- ============================================================
if not IsMoonMap then
    local RAID_PORTAL_CD        = 1
    local RAID_FIRE_VALID_WIN   = 20
    local HOVER_HEIGHT          = 100
    local RAID_MIN_FIRE_GAP     = 0.5
    local RESPAWN_SKIP_TIME     = 5
    local RAID_PORTAL_FIRE_LOCK = 5

    local RAID_BUFF_DELAY          = 1.0
    local RAID_BUFF_LIST           = {"Kaioken", "SSJ", "SSJ2", "SSJ3", "SSJG"}
    local RAID_BUFF_COOLDOWN       = 0.3
    local RAID_THANOS_HP_THRESHOLD = 50
    local RAID_THANOS_COOLDOWN     = 0.3

    _G.RaidBuffUsed              = false
    _G.RaidBuffFinishTime        = 0
    _G.RaidBuffSpamStartTime     = 0
    _G.RaidBuffSpamActive        = false
    _G.RaidLastThanosTime        = 0
    _G.RaidThanosFSuccessCount   = 0
    _G.RaidThanosSpamStartTime   = 0
    _G.RaidPortalFireLock        = 0

    -- =====================================================
    -- BodyPosition helpers
    -- =====================================================
    local function CreateRaidBP(hrp, position, force)
        if not hrp or not hrp.Parent then return end
        if hrp:FindFirstChild("RaidBP") then hrp.RaidBP:Destroy() end

        local bp = Instance.new("BodyPosition")
        bp.Name     = "RaidBP"
        bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bp.P        = force or 30000
        bp.D        = 5000
        bp.Position = position
        bp.Parent   = hrp
        _G.RaidBP = bp
        return bp
    end

    local function StartRaidHover(hrp, height)
        if not hrp or not hrp.Parent then return end
        height = height or HOVER_HEIGHT
        local targetPos = hrp.Position + Vector3.new(0, height, 0)
        CreateRaidBP(hrp, targetPos, 30000)
    end

    local function StopRaidHover(hrp, silent)
        if not hrp then
            hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        end
        if hrp then
            for _, name in ipairs({"RaidBP", "RaidHoverBP", "RaidHoverGyro", "RaidAnchorBP"}) do
                if hrp:FindFirstChild(name) then hrp[name]:Destroy() end
            end
        end
        _G.RaidBP = nil
    end

    local function HasAnyTool()
        local char = LocalPlayer.Character
        if char then
            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("Tool") then return true end
            end
        end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, v in ipairs(bp:GetChildren()) do
                if v:IsA("Tool") then return true end
            end
        end
        return false
    end

    -- =====================================================
    -- Tìm tool Thanos
    -- =====================================================
    local function FindRaidThanosTool()
        local char = LocalPlayer.Character
        if not char then return nil, "character" end
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name == "thanos" or name:find("thanos") then
                    return tool, "character"
                end
            end
        end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") then
                    local name = tool.Name:lower()
                    if name == "thanos" or name:find("thanos") then
                        return tool, "backpack"
                    end
                end
            end
        end
        return nil, "none"
    end

    -- =====================================================
    -- Tìm tool buff
    -- =====================================================
    local function FindRaidBuffTool()
        local char = LocalPlayer.Character
        if not char then return nil, nil end
        for _, buffName in ipairs(RAID_BUFF_LIST) do
            for _, tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") and tool.Name:lower() == buffName:lower() then
                    return tool, buffName
                end
            end
        end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, buffName in ipairs(RAID_BUFF_LIST) do
                for _, tool in ipairs(bp:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name:lower() == buffName:lower() then
                        return tool, buffName
                    end
                end
            end
        end
        return nil, nil
    end

    -- =====================================================
    -- Ensure Thanos equipped
    -- =====================================================
    local function EnsureRaidThanosEquipped()
        local char = LocalPlayer.Character
        if not char then return false end
        local tool, location = FindRaidThanosTool()
        if not tool then return false end
        if location == "character" then return true end
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            pcall(function() hum:EquipTool(tool) end)
            task.wait(0.2)
            print("[Raid] 🗡️ Đã trang bị Thanos")
            return true
        end
        return false
    end

    -- =====================================================
    -- Spam F buff đến cooldown
    -- =====================================================
    local function RaidBuffSpamLoop()
        _G.RaidBuffSpamActive = true
        _G.RaidBuffSpamStartTime = tick()

        local tool, buffName = FindRaidBuffTool()
        if not tool then
            _G.RaidBuffSpamActive = false
            _G.RaidBuffFinishTime = tick()
            print("[Raid] ⚠️ Không có buff tool, bỏ qua")
            return false
        end

        print("[Raid] ⚡ Bắt đầu spam F buff: " .. buffName)
        local startTime = tick()
        local lastFTime = 0

        while _G.RaidBuffSpamActive and tick() - startTime < 15 do
            local now = tick()
            if now - lastFTime >= RAID_BUFF_COOLDOWN then
                lastFTime = now
                local char = LocalPlayer.Character
                if not char then break end

                local currentTool = nil
                for _, t in ipairs(char:GetChildren()) do
                    if t:IsA("Tool") and t.Name:lower() == buffName:lower() then
                        currentTool = t
                        break
                    end
                end
                if not currentTool then
                    local bp = LocalPlayer:FindFirstChild("Backpack")
                    if bp then
                        for _, t in ipairs(bp:GetChildren()) do
                            if t:IsA("Tool") and t.Name:lower() == buffName:lower() then
                                char.Humanoid:EquipTool(t)
                                task.wait(0.3)
                                currentTool = t
                                break
                            end
                        end
                    end
                end
                if not currentTool then break end

                local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                local main = hud and hud:FindFirstChild("Main")
                local skillList = main and main:FindFirstChild("Frame_SkillList_" .. buffName)
                local fOnCooldown = false
                if skillList then
                    local border = skillList:FindFirstChild("Border")
                    local mainFrame = border and border:FindFirstChild("Main")
                    local fFrame = mainFrame and mainFrame:FindFirstChild("F")
                    if fFrame then
                        local readyLabel = fFrame:FindFirstChild("Ready")
                        local cooldownFrame = fFrame:FindFirstChild("CooldownFrame")
                        local isUnready = readyLabel and readyLabel.Text == "UnReady"
                        local isCooldownVisible = cooldownFrame and cooldownFrame.Visible
                        if isUnready or isCooldownVisible then
                            fOnCooldown = true
                        end
                    end
                end

                if fOnCooldown then
                    print("[Raid] ⏹️ Buff F cooldown → dừng spam")
                    break
                end

                if Action then
                    pcall(function()
                        Action:FireServer(currentTool.Name, "f")
                    end)
                    print("[Raid] ⚡ Buff F: " .. buffName)
                end
            end
            task.wait(0.1)
        end

        _G.RaidBuffSpamActive = false
        _G.RaidBuffFinishTime = tick()
        print("[Raid] ✅ Buff spam xong, đợi " .. RAID_BUFF_DELAY .. "s")
        return true
    end

    -- =====================================================
    -- TryUseRaidThanosF
    -- =====================================================
    local function TryUseRaidThanosF(hrp)
        if not hrp then return "no_tool" end
        if not EnsureRaidThanosEquipped() then return "no_tool" end

        local char = LocalPlayer.Character
        if not char then return "no_tool" end

        local thanosTool = nil
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name == "thanos" or name:find("thanos") then
                    thanosTool = tool
                    break
                end
            end
        end
        if not thanosTool then return "no_tool" end

        local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        local main = hud and hud:FindFirstChild("Main")
        local skillList = main and main:FindFirstChild("Frame_SkillList_Thanos")
        if skillList then
            local border = skillList:FindFirstChild("Border")
            local mainFrame = border and border:FindFirstChild("Main")
            local fFrame = mainFrame and mainFrame:FindFirstChild("F")
            if fFrame then
                local readyLabel = fFrame:FindFirstChild("Ready")
                local cooldownFrame = fFrame:FindFirstChild("CooldownFrame")
                local isUnready = readyLabel and readyLabel.Text == "UnReady"
                local isCooldownVisible = cooldownFrame and cooldownFrame.Visible
                if isUnready or isCooldownVisible then
                    return "cooldown"
                end
            end
        end

        task.wait(0.3)
        if Action then
            pcall(function()
                Action:FireServer(thanosTool.Name, "f")
            end)
            task.wait(0.3)
            return "success"
        end
        return "no_tool"
    end

    -- =====================================================
    -- Raid Follow (Heartbeat)
    -- =====================================================
    local RaidHeartbeatConn = nil

    local function StartRaidFollow()
        if RaidHeartbeatConn then return end
        RaidHeartbeatConn = RunService.Heartbeat:Connect(function()
            if not _G.AutoRaidRunning then return end

            local target = _G.RaidCurrentTarget
            if not target or not target.Parent then return end

            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChild("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then return end

            local offset = _G.RaidCurrentOffset or Vector3.new(0, _G.RaidAttackHeight or 25, 0)
            local name = target.Parent and target.Parent.Name or ""
            if name == "ArmorBall1" or name == "ArmorBall2" then
                offset = Vector3.new(0, _G.RaidBallHeight or 25, 0)
            elseif name == "Boss Bacon Sad" then
                offset = Vector3.new(0, _G.RaidBaconHeight or 55, 5)
            end

            local targetPos = target.Position + offset
            hrp.CFrame = CFrame.new(targetPos, target.Position)
            hrp.AssemblyLinearVelocity   = Vector3.zero
            hrp.AssemblyAngularVelocity  = Vector3.zero
        end)
    end

    local function StopRaidFollow()
        if RaidHeartbeatConn then
            RaidHeartbeatConn:Disconnect()
            RaidHeartbeatConn = nil
        end
        _G.RaidCurrentTarget = nil
        _G.RaidCurrentOffset = nil
    end

    local function CleanupRaidTags()
        StopRaidFollow()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        for _, name in ipairs({"AutoRaidBP", "AutoRaidAP", "AutoRaidAO", "AutoRaidAtt", "RaidSmoothBP", "BodyClip"}) do
            if hrp:FindFirstChild(name) then hrp[name]:Destroy() end
        end
    end

    -- =====================================================
    -- AttackTarget — v5: KHÔNG TP lên cao, bám boss + spam F
    -- =====================================================
    local function AttackTarget(targetPart, targetModel, offsetY, offsetX)
        if not targetPart or not targetModel then return end
        if not targetModel:FindFirstChild("Humanoid") then return end
        if targetModel.Humanoid.Health <= 0 then return end
        if _G.RaidAttacking then return end
        if tick() < _G.RaidSkipBossFight then return end

        _G.RaidAttacking = true

        targetModel.Humanoid.WalkSpeed = 0
        targetModel.Humanoid.JumpPower = 0

        _G.RaidCurrentTarget = targetPart
        _G.RaidCurrentOffset = Vector3.new(offsetX or 0, offsetY or 25, 0)

        local attackStart    = tick()
        local lastHealth     = targetModel.Humanoid.Health
        local stuckStart     = tick()

        task.spawn(function()
            while _G.RaidAttacking do
                task.wait(0.05)

                if not _G.AutoRaidRunning then break end
                if not targetModel or not targetModel.Parent then break end
                if not targetModel:FindFirstChild("Humanoid") then break end
                if targetModel.Humanoid.Health <= 0 then break end
                if tick() < _G.RaidSkipBossFight then break end

                local char = LocalPlayer.Character
                local hum  = char and char:FindFirstChild("Humanoid")
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if not hum or hum.Health <= 0 then break end
                if not targetPart or not targetPart.Parent then break end
                if not hrp then break end

                local now = tick()
                if now - attackStart > 60 then break end

                local isBaconBoss = (targetModel.Name == "Boss Bacon Sad")

                -- 🆕 Luôn bám boss tại chỗ (kể cả khi spam F)
                local bossPos = targetPart.Position
                local bamPos = bossPos + Vector3.new(offsetX or 0, offsetY or 25, 0)
                hrp.CFrame = CFrame.new(bamPos, bossPos)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero

                if isBaconBoss then
                    local hpPercent = (targetModel.Humanoid.Health / targetModel.Humanoid.MaxHealth) * 100

                    if hpPercent <= RAID_THANOS_HP_THRESHOLD then
                        -- ============ THANOS PRIORITY (tại chỗ) ============
                        local thanosEquipped = EnsureRaidThanosEquipped()

                        if thanosEquipped then
                            if _G.RaidThanosSpamStartTime == 0 then
                                _G.RaidThanosSpamStartTime = now
                                _G.RaidThanosFSuccessCount = 0
                                print("[Raid] ⚡ Bắt đầu Auto spam F Thanos (tại chỗ)")
                            end

                            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                            local main = hud and hud:FindFirstChild("Main")
                            local skillList = main and main:FindFirstChild("Frame_SkillList_Thanos")
                            local fOnCooldown = false
                            if skillList then
                                local border = skillList:FindFirstChild("Border")
                                local mainFrame = border and border:FindFirstChild("Main")
                                local fFrame = mainFrame and mainFrame:FindFirstChild("F")
                                if fFrame then
                                    local readyLabel = fFrame:FindFirstChild("Ready")
                                    local cooldownFrame = fFrame:FindFirstChild("CooldownFrame")
                                    local isUnready = readyLabel and readyLabel.Text == "UnReady"
                                    local isCooldownVisible = cooldownFrame and cooldownFrame.Visible
                                    if isUnready or isCooldownVisible then
                                        fOnCooldown = true
                                    end
                                end
                            end

                            if not fOnCooldown and now - _G.RaidLastThanosTime >= RAID_THANOS_COOLDOWN then
                                _G.RaidLastThanosTime = now
                                local result = TryUseRaidThanosF(hrp)
                                if result == "success" then
                                    _G.RaidThanosFSuccessCount = _G.RaidThanosFSuccessCount + 1
                                    if _G.RaidThanosFSuccessCount <= 5 or _G.RaidThanosFSuccessCount % 5 == 0 then
                                        print(string.format("[Raid] ⚡ F Thanos #%d (HP: %.1f%%)",
                                            _G.RaidThanosFSuccessCount, hpPercent))
                                    end
                                end
                            end
                            task.wait(0.05)
                        else
                            -- Không có Thanos → attack thường
                            if HasAnyTool() then
                                if now - _G.RaidLastEquip >= 0.5 then
                                    _G.RaidLastEquip = now
                                    if _G.EnableEquipWeapon then EquipWeapon() end
                                end
                                if now - _G.RaidLastSkill >= 0.1 then
                                    _G.RaidLastSkill = now
                                    TryFireSkill()
                                end
                                if now - _G.RaidLastAttack >= 0.15 then
                                    _G.RaidLastAttack = now
                                    Attack()
                                end
                            end
                        end
                    else
                        -- HP >= 50% → attack thường
                        if _G.RaidThanosSpamStartTime ~= 0 then
                            _G.RaidThanosSpamStartTime = 0
                            _G.RaidThanosFSuccessCount = 0
                        end

                        if HasAnyTool() then
                            if now - _G.RaidLastEquip >= 0.5 then
                                _G.RaidLastEquip = now
                                if _G.EnableEquipWeapon then EquipWeapon() end
                            end
                            if now - _G.RaidLastSkill >= 0.1 then
                                _G.RaidLastSkill = now
                                TryFireSkill()
                            end
                            if now - _G.RaidLastAttack >= 0.15 then
                                _G.RaidLastAttack = now
                                Attack()
                            end
                        end
                    end
                else
                    -- 2 quả cầu vàng → đánh thường
                    if HasAnyTool() then
                        if now - _G.RaidLastEquip >= 0.5 then
                            _G.RaidLastEquip = now
                            if _G.EnableEquipWeapon then EquipWeapon() end
                        end
                        if now - _G.RaidLastSkill >= 0.1 then
                            _G.RaidLastSkill = now
                            TryFireSkill()
                        end
                        if now - _G.RaidLastAttack >= 0.15 then
                            _G.RaidLastAttack = now
                            Attack()
                        end
                    end
                end

                if targetModel.Humanoid.Health < lastHealth then
                    lastHealth = targetModel.Humanoid.Health
                    stuckStart = now
                elseif now - stuckStart > 15 and HasAnyTool() then
                    break
                end
            end

            _G.RaidAttacking     = false
            _G.RaidCurrentTarget = nil
            _G.RaidCurrentOffset = nil
            _G.RaidThanosSpamStartTime = 0
            _G.RaidThanosFSuccessCount = 0
        end)
    end

    -- =====================================================
    -- EnterRaidPortal
    -- =====================================================
    local function EnterRaidPortal(hrp, timeout)
        if _G.RaidPhase == "ENTERING" then return end
        _G.RaidPhase = "ENTERING"

        timeout = timeout or 10
        local startTime = tick()
        local fireTime  = _G.RaidFireTimestamp

        local TPZone, Hitbox
        repeat task.wait(0.03)
            if not _G.AutoRaidRunning then
                StopRaidHover(hrp, true)
                _G.RaidPhase = "IDLE"
                _G.RaidFired = false
                return
            end

            local zone = workspace:FindFirstChild("TeleportBossFightZone")
            if zone and zone:FindFirstChild("Hitbox") then
                local isDifferent = (_G.RaidPortalRef == nil) or (zone ~= _G.RaidPortalRef)
                local isValidTime = true
                if fireTime > 0 and tick() - fireTime > RAID_FIRE_VALID_WIN then
                    isValidTime = false
                end
                if isDifferent and isValidTime then
                    TPZone = zone
                    Hitbox = zone.Hitbox
                    break
                end
            end
        until tick() - startTime >= timeout

        if not Hitbox then
            StopRaidHover(hrp, true)
            _G.RaidPhase = "IDLE"
            _G.RaidFired = false
            return
        end

        _G.RaidPortalRef = TPZone
        _G.RaidPortalFireLock = tick() + RAID_PORTAL_FIRE_LOCK

        hrp.CFrame = CFrame.new(Hitbox.Position + Vector3.new(0, 8, 0))
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        CreateRaidBP(hrp, Hitbox.Position + Vector3.new(0, 8, 0), 8000)

        local enterStart = tick()

        repeat task.wait(0.05)
            if not _G.AutoRaidRunning then break end
            if tick() - enterStart > 10 then break end
            if not TPZone.Parent or not TPZone:FindFirstChild("Hitbox") then break end

            if hrp.Parent and Hitbox.Parent then
                local dist = (hrp.Position - Hitbox.Position).Magnitude
                if dist > 200 then break end

                local targetPos = Hitbox.Position + Vector3.new(0, 8, 0)
                if _G.RaidBP and _G.RaidBP.Parent then
                    if (_G.RaidBP.Position - targetPos).Magnitude > 5 then
                        _G.RaidBP.Position = targetPos
                    end
                else
                    hrp.CFrame = CFrame.new(targetPos)
                    CreateRaidBP(hrp, targetPos, 8000)
                end
            end
        until false

        StopRaidHover(hrp, true)
        _G.RaidPhase = "WAIT_PORTAL"
        _G.RaidWaitPortalStart = tick()
        _G.RaidFired = false
    end

    -- =====================================================
    -- Auto Raid Boss Loop
    -- =====================================================
    task.spawn(function()
        while task.wait(0.15) do
            if _G.RaidPrevRunning and not _G.AutoRaidRunning then
                StopRaidHover(nil, true)
                _G.RaidPhase            = "IDLE"
                _G.RaidPortalRef        = nil
                _G.RaidFireTimestamp    = 0
                _G.RaidFired            = false
                _G.RaidForceFirePending = false
                _G.RaidRespawnTime      = 0
                _G.RaidAttacking        = false
                _G.RaidSkipBossFight    = 0
                _G.RaidBuffUsed         = false
                _G.RaidBuffFinishTime   = 0
                _G.RaidBuffSpamActive   = false
                _G.RaidThanosFSuccessCount = 0
                _G.RaidThanosSpamStartTime = 0
                _G.RaidPortalFireLock   = 0
            end
            _G.RaidPrevRunning = _G.AutoRaidRunning

            if _G.AutoRaidRunning then
                local Data = RaidBossData and RaidBossData[_G.AutoRaidWho]
                if Data and Data.Valid then
                    pcall(function()
                        local char = LocalPlayer.Character

                        if _G.RaidPhase == "DEAD" then
                            local newHum = char and char:FindFirstChild("Humanoid")
                            local newHrp = char and char:FindFirstChild("HumanoidRootPart")
                            if newHum and newHrp and newHum.Health > 0 then
                                _G.RaidPhase            = "IDLE"
                                _G.RaidFired            = false
                                _G.RaidPortalRef        = nil
                                _G.RaidFireTimestamp    = 0
                                _G.RaidForceFirePending = true
                                _G.RaidRespawnTime      = tick()
                                _G.RaidAttacking        = false
                                _G.RaidSkipBossFight    = tick() + RESPAWN_SKIP_TIME
                                _G.RaidBuffUsed         = false
                                _G.RaidBuffFinishTime   = 0
                                _G.RaidPortalFireLock   = 0
                                _G.RaidThanosFSuccessCount = 0
                                _G.RaidThanosSpamStartTime = 0
                                StopRaidHover(newHrp, true)
                                CleanupRaidTags()
                                task.wait(2)
                                return
                            else
                                task.wait(0.2)
                                return
                            end
                        end

                        local hum = char and char:FindFirstChild("Humanoid")
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if not hum or not hrp then return end

                        if hum.Health <= 0 then
                            if _G.RaidPhase ~= "DEAD" then
                                _G.RaidPhase = "DEAD"
                                _G.RaidAttacking = false
                                StopRaidHover(hrp, true)
                                CleanupRaidTags()
                            end
                            return
                        end

                        if _G.RaidRespawnTime > 0 and tick() - _G.RaidRespawnTime < 2 then
                            if not hrp:FindFirstChild("RaidBP") then
                                StartRaidHover(hrp, HOVER_HEIGHT)
                            end
                            task.wait(0.3)
                            return
                        end

                        if tick() < _G.RaidSkipBossFight then
                            if not hrp:FindFirstChild("RaidBP") then
                                StartRaidHover(hrp, HOVER_HEIGHT)
                            end
                            task.wait(0.3)
                            return
                        end

                        local bf          = workspace:FindFirstChild("Boss Fight")
                        local baconFolder = bf and bf:FindFirstChild("Bacon of Grudge")

                        if _G.RaidPhase == "CLEARING" then
                            if not hrp:FindFirstChild("RaidBP") then
                                StartRaidHover(hrp, HOVER_HEIGHT)
                            end
                            _G.RaidClearStart = _G.RaidClearStart or tick()
                            if tick() - _G.RaidClearStart > 3 or not workspace:FindFirstChild("Boss Fight") then
                                _G.RaidPhase            = "IDLE"
                                _G.RaidPortalRef        = nil
                                _G.RaidFired            = false
                                _G.RaidForceFirePending = true
                                _G.RaidClearStart       = nil
                                _G.RaidLastFireTime     = 0
                                _G.RaidBuffUsed         = false
                                _G.RaidBuffFinishTime   = 0
                                _G.RaidThanosFSuccessCount = 0
                                _G.RaidThanosSpamStartTime = 0
                            end
                            task.wait(0.2)
                            return
                        end

                        if baconFolder then
                            local A1 = baconFolder:FindFirstChild("ArmorBall1")
                            local A2 = baconFolder:FindFirstChild("ArmorBall2")
                            local BossBacon = baconFolder:FindFirstChild("Boss Bacon Sad")

                            local a1Alive   = A1 and A1:FindFirstChild("Humanoid") and A1.Humanoid.Health > 0
                            local a2Alive   = A2 and A2:FindFirstChild("Humanoid") and A2.Humanoid.Health > 0
                            local bossAlive = BossBacon and BossBacon:FindFirstChild("Humanoid") and BossBacon.Humanoid.Health > 0

                            if not (a1Alive or a2Alive or bossAlive) then
                                if _G.RaidPhase ~= "CLEARING" then
                                    _G.RaidPhase      = "CLEARING"
                                    _G.RaidFired      = false
                                    _G.RaidClearStart = tick()
                                    _G.RaidAttacking  = false
                                    _G.RaidThanosFSuccessCount = 0
                                    _G.RaidThanosSpamStartTime = 0
                                    StopRaidHover(hrp, true)
                                    StartRaidHover(hrp, HOVER_HEIGHT)
                                end
                                return
                            end

                            if not HasAnyTool() then
                                _G.RaidToolWaitStart = _G.RaidToolWaitStart or tick()
                                if tick() - _G.RaidToolWaitStart < 5 then
                                    if not hrp:FindFirstChild("RaidBP") then
                                        StartRaidHover(hrp, HOVER_HEIGHT)
                                    end
                                    task.wait(0.3)
                                    return
                                end
                                _G.RaidToolWaitStart = nil
                                _G.RaidPhase = "CLEARING"
                                _G.RaidClearStart = tick()
                                _G.RaidAttacking = false
                                return
                            end
                            _G.RaidToolWaitStart = nil

                            if _G.RaidPhase ~= "FIGHTING" then
                                _G.RaidPhase = "FIGHTING"
                                _G.RaidFired = false
                            end
                            StopRaidHover(hrp, true)
                            StartRaidFollow()

                            if not _G.RaidAttacking then
                                if a1Alive then
                                    AttackTarget(A1:FindFirstChild("HumanoidRootPart"), A1, _G.RaidBallHeight or 25, 0)
                                elseif a2Alive then
                                    AttackTarget(A2:FindFirstChild("HumanoidRootPart"), A2, _G.RaidBallHeight or 25, 0)
                                elseif bossAlive then
                                    local bossHrp = BossBacon:FindFirstChild("HumanoidRootPart")
                                    if bossHrp then
                                        AttackTarget(bossHrp, BossBacon, _G.RaidBaconHeight or 55, 5)
                                    end
                                end
                            end
                            task.wait(0.5)
                            return
                        end

                        if _G.RaidPhase == "ENTERING" then
                            task.wait(0.2)
                            return
                        end

                        if _G.RaidPhase == "WAIT_PORTAL" then
                            local elapsed = tick() - (_G.RaidWaitPortalStart or tick())
                            local bfCheck = workspace:FindFirstChild("Boss Fight")
                            local baconCheck = bfCheck and bfCheck:FindFirstChild("Bacon of Grudge")
                            local bossAlive2 = false
                            if baconCheck and baconCheck:FindFirstChild("Humanoid") then
                                bossAlive2 = baconCheck.Humanoid.Health > 0
                            end

                            if bossAlive2 then
                                _G.RaidWaitPortalStart = nil
                                _G.RaidPhase = "FIGHTING"
                                return
                            end

                            if elapsed > 4 then
                                _G.RaidWaitPortalStart = nil
                                _G.RaidPhase = "IDLE"
                                _G.RaidPortalRef = nil
                                _G.RaidFired = false
                                _G.RaidForceFirePending = true
                            end
                            task.wait(0.1)
                            return
                        end

                        if _G.RaidPhase == "IDLE" then
                            if tick() < (_G.RaidPortalFireLock or 0) then
                                if not hrp:FindFirstChild("RaidBP") then
                                    StartRaidHover(hrp, HOVER_HEIGHT)
                                end
                                task.wait(0.1)
                                return
                            end

                            if _G.RaidForceFirePending then
                                _G.RaidForceFirePending = false
                                _G.RaidPortalRef        = nil
                                _G.RaidFireTimestamp    = 0
                                _G.RaidFired            = false
                                _G.RaidWaitOldPortal    = nil
                                _G.RaidLastFireTime     = 0
                            end

                            if not _G.RaidBuffUsed then
                                _G.RaidBuffUsed = true
                                local tool, buffName = FindRaidBuffTool()
                                if tool then
                                    print("[Raid] ⚡ Có buff " .. buffName .. ", bắt đầu spam F trước cổng")
                                    _G.RaidBuffSpamStartTime = tick()
                                    _G.RaidBuffFinishTime = 0
                                    task.spawn(function()
                                        RaidBuffSpamLoop()
                                        print("[Raid] ⏳ Đợi " .. RAID_BUFF_DELAY .. "s rồi mở cổng...")
                                        task.wait(RAID_BUFF_DELAY)
                                        _G.RaidBuffFinishTime = tick()
                                        print("[Raid] ✅ Buff xong, bắt đầu mở cổng")
                                        _G.RaidLastFireTime = 0
                                    end)
                                    task.wait(0.3)
                                    return
                                else
                                    print("[Raid] ⚠️ Không có buff tool, bỏ qua")
                                    _G.RaidBuffFinishTime = tick()
                                end
                            end

                            if _G.RaidBuffFinishTime == 0 then
                                task.wait(0.1); return
                            end
                            if tick() - _G.RaidBuffFinishTime < 1 then
                                task.wait(0.1); return
                            end

                            if _G.RaidFired then task.wait(0.3); return end
                            if tick() - _G.RaidLastFireTime < RAID_MIN_FIRE_GAP then task.wait(0.1); return end

                            local bfCheck = workspace:FindFirstChild("Boss Fight")
                            local baconCheck = bfCheck and bfCheck:FindFirstChild("Bacon of Grudge")
                            local bossAlive3 = false
                            if baconCheck and baconCheck:FindFirstChild("Humanoid") then
                                bossAlive3 = baconCheck.Humanoid.Health > 0
                            end

                            if bossAlive3 then
                                _G.RaidPhase = "FIGHTING"
                                task.wait(0.2)
                                return
                            end

                            local oldPortal = _G.RaidPortalRef
                            if oldPortal ~= nil and oldPortal.Parent then
                                _G.RaidWaitOldPortal = _G.RaidWaitOldPortal or tick()
                                if tick() - _G.RaidWaitOldPortal > 3 then
                                    _G.RaidPortalRef = nil
                                    _G.RaidWaitOldPortal = nil
                                else
                                    if not hrp:FindFirstChild("RaidBP") then
                                        StartRaidHover(hrp, HOVER_HEIGHT)
                                    end
                                    task.wait(0.2)
                                    return
                                end
                            else
                                _G.RaidWaitOldPortal = nil
                            end
                            _G.RaidPortalRef = nil

                            if not hrp:FindFirstChild("RaidBP") then
                                StartRaidHover(hrp, HOVER_HEIGHT)
                            end

                            local portalCount = GetPortalGunCount()
                            if portalCount < Data.PortalCost then
                                Fluent:Notify({
                                    Title = "❌ Auto Raid Boss",
                                    Content = "Không đủ Portal Gun! Cần: " .. Data.PortalCost .. ", Có: " .. portalCount,
                                    Duration = 4
                                })
                                StopRaidHover(hrp, true)
                                _G.AutoRaidRunning = false
                                return
                            end

                            _G.RaidFireTimestamp = tick()
                            _G.RaidLastFireTime  = tick()
                            _G.RaidFired         = true
                            if NetworkEvent then
                                NetworkEvent:FireServer("fire", nil, "SpawnBossFight", Data.Name)
                            end
                            print("[Raid] 🏰 Opened portal → " .. Data.Name)

                            task.spawn(function()
                                task.wait(0.3)
                                local newCount = GetPortalGunCount()
                                Fluent:Notify({
                                    Title = "🔫 Auto Raid Boss",
                                    Content = "Remaining Portal Guns: " .. tostring(newCount),
                                    Duration = 3
                                })
                            end)

                            EnterRaidPortal(hrp, 10)
                        end
                    end)
                end
            end
        end
    end)
end

-- ============================================================
-- 🆕 AUTO RAID BOSS DRAGON — v11 FINAL
-- - Buff SSJ... TRƯỚC KHI MỞ CỔNG (spam F đến cooldown)
-- - Buff trước cổng + sau respawn
-- - Đợi 1s sau buff → mở cổng
-- - HP < 50% → spam F Thanos (mặc định bật, tự equip)
-- - Safe zone lơ lửng 500 studs (ưu tiên cao nhất)
-- ============================================================
if not IsMoonMap then
    _G.AutoRaidDragon             = false
    _G.DragonLastFireTime         = 0
    _G.DragonLastAttack           = 0
    _G.DragonLastEquip            = 0
    _G.DragonEnterTime            = 0
    _G.DragonPortalPhase          = "IDLE"
    _G.DragonPortalStartTime      = 0
    _G.DragonPortalFireLock       = 0
    _G.DragonAlertTriggered       = false
    _G.DragonSafeZoneActive       = false
    _G.DragonLastSafeTP           = 0
    _G.DragonSafeZonePart         = nil
    _G.DragonBossDeadHandled      = false
    _G.DragonThanosFSuccessCount  = 0
    _G.DragonThanosSpamStartTime  = 0
    _G.DragonThanosFlyPos         = nil
    _G.DragonLastThanosTime       = 0
    _G.DragonBuffUsed             = false
    _G.DragonBuffFinishTime       = 0
    _G.DragonHasThanosEquipped    = false
    _G.DragonBuffSpamActive       = false
    _G.DragonBuffSpamStartTime    = 0
    _G.DragonBuffSpamFinishTime   = 0

    local DRAGON_AIM_HEIGHT        = 25
    local DRAGON_MIN_FIRE_GAP      = 3
    local DRAGON_PORTAL_TIMEOUT    = 15
    local DRAGON_PORTAL_FIRE_LOCK  = 5
    local DRAGON_SAFE_HEIGHT_FLY   = 500
    local DRAGON_THANOS_COOLDOWN   = 0.3
    local DRAGON_BUFF_COOLDOWN     = 0.3
    local DRAGON_BUFF_DELAY        = 2.0
    local DRAGON_BUFF_LIST         = {"Kaioken", "SSJ", "SSJ2", "SSJ3", "SSJG"}

    local function GetDragonMethodFarm(height)
        height = height or DRAGON_AIM_HEIGHT
        return CFrame.new(0, height, 0) * CFrame.Angles(math.rad(-90), 0, 0)
    end

    -- =====================================================
    -- Tìm tool Thanos
    -- =====================================================
    local function FindThanosTool()
        local char = LocalPlayer.Character
        if not char then return nil, "character" end
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name == "thanos" or name:find("thanos") then
                    return tool, "character"
                end
            end
        end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") then
                    local name = tool.Name:lower()
                    if name == "thanos" or name:find("thanos") then
                        return tool, "backpack"
                    end
                end
            end
        end
        return nil, "none"
    end

    -- =====================================================
    -- Tìm tool buff (SSJ/Kaioken/...)
    -- =====================================================
    local function FindBuffTool()
        local char = LocalPlayer.Character
        if not char then return nil, nil end

        -- Ưu tiên Character
        for _, buffName in ipairs(DRAGON_BUFF_LIST) do
            for _, tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") and tool.Name:lower() == buffName:lower() then
                    return tool, buffName
                end
            end
        end

        -- Tìm trong Backpack
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, buffName in ipairs(DRAGON_BUFF_LIST) do
                for _, tool in ipairs(bp:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name:lower() == buffName:lower() then
                        return tool, buffName
                    end
                end
            end
        end
        return nil, nil
    end
	
	    -- =====================================================
    -- 🆕 Ensure Buff equipped
    -- =====================================================
    local function EnsureBuffEquipped()
        local char = LocalPlayer.Character
        if not char then return nil, nil end
        local tool, buffName = FindBuffTool()
        if not tool then return nil, nil end
        if tool.Parent == char then
            return tool, buffName
        end
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            pcall(function() hum:EquipTool(tool) end)
            task.wait(0.2)
            return tool, buffName
        end
        return nil, nil
    end

    -- =====================================================
    -- Ensure Thanos equipped
    -- =====================================================
    local function EnsureThanosEquipped()
        local char = LocalPlayer.Character
        if not char then return false end
        local tool, location = FindThanosTool()
        if not tool then return false end
        if location == "character" then
            _G.DragonHasThanosEquipped = true
            return true
        end
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            pcall(function() hum:EquipTool(tool) end)
            task.wait(0.5)
            _G.DragonHasThanosEquipped = true
            print("[Dragon] 🗡️ Đã trang bị Thanos: " .. tool.Name)
            return true
        end
        return false
    end

    -- =====================================================
    -- TryUseThanosF
    -- =====================================================
    local function TryUseThanosF(hrp)
        if not hrp then return "no_tool" end

        local char = LocalPlayer.Character
        if not char then return "no_tool" end

        local thanosTool = nil
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name == "thanos" or name:find("thanos") then
                    thanosTool = tool
                    break
                end
            end
        end
        if not thanosTool then return "no_tool" end

        -- Check cooldown
        local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        local main = hud and hud:FindFirstChild("Main")
        local skillList = main and main:FindFirstChild("Frame_SkillList_Thanos")

        if skillList then
            local border = skillList:FindFirstChild("Border")
            local mainFrame = border and border:FindFirstChild("Main")
            local fFrame = mainFrame and mainFrame:FindFirstChild("F")
            if fFrame then
                local readyLabel = fFrame:FindFirstChild("Ready")
                local cooldownFrame = fFrame:FindFirstChild("CooldownFrame")
                local isUnready = readyLabel and readyLabel.Text == "UnReady"
                local isCooldownVisible = cooldownFrame and cooldownFrame.Visible
                if isUnready or isCooldownVisible then
                    return "cooldown"
                end
            end
        end

        task.wait(0.3)
        if Action then
            pcall(function()
                Action:FireServer(thanosTool.Name, "f")
            end)
            task.wait(0.3)
            return "success"
        end
        return "no_tool"
    end

    -- Hook alert
    local function OnDragonAlert(text)
        if not text then return end
        local lower = text:lower()
        if lower:find("gathering power", 1, true) then
            print("[Dragon] ⚠️ GATHERING POWER")
        end
        if lower:find("hide in the green zone", 1, true)
           or lower:find("green zone", 1, true) then
            if not _G.DragonAlertTriggered then
                _G.DragonAlertTriggered = true
                print("[Dragon] 🚨 PHASE 2: HIDE IN THE GREEN ZONE!")
            end
        end
    end

    local function HookDragonText(container)
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                OnDragonAlert(obj.Text)
                obj:GetPropertyChangedSignal("Text"):Connect(function()
                    OnDragonAlert(obj.Text)
                end)
            end
        end
    end
    HookDragonText(LocalPlayer.PlayerGui)
    LocalPlayer.PlayerGui.DescendantAdded:Connect(function(obj)
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            task.wait(0.1)
            OnDragonAlert(obj.Text)
            obj:GetPropertyChangedSignal("Text"):Connect(function()
                OnDragonAlert(obj.Text)
            end)
        end
    end)

    local function GetDragonBoss()
        local bf = workspace:FindFirstChild("Boss Fight")
        if not bf then return nil, nil, nil end
        local dragonFolder = bf:FindFirstChild("Dragon")
        if not dragonFolder then return nil, nil, nil end
        local bossModel = dragonFolder:FindFirstChild("Dragon Boss")
        if not bossModel then return nil, nil, nil end
        local bossHrp = bossModel:FindFirstChild("HumanoidRootPart")
        local bossHum = bossModel:FindFirstChild("Humanoid")
        if bossHrp and bossHum then
            return bossModel, bossHrp, bossHum
        end
        return nil, nil, nil
    end

    local function IsSafeZoneColor(c)
        return math.abs(c.R - 0.27) < 0.05
           and math.abs(c.G - 1.00) < 0.05
           and math.abs(c.B - 0.55) < 0.05
    end

    local function FindDragonSafeZone()
        if _G.DragonSafeZonePart and _G.DragonSafeZonePart.Parent then
            return _G.DragonSafeZonePart
        end
        local vfx = workspace:FindFirstChild("VFX")
        if not vfx then return nil end
        local bestPart, bestY = nil, math.huge
        for _, obj in ipairs(vfx:GetChildren()) do
            if obj:IsA("BasePart") and obj.Name == "Part" then
                if IsSafeZoneColor(obj.Color) then
                    if obj.Position.Y < bestY then
                        bestY = obj.Position.Y
                        bestPart = obj
                    end
                end
            end
        end
        if bestPart then
            print("[Dragon] 🎯 Vùng an toàn: Y=" .. string.format("%.1f", bestPart.Position.Y))
            _G.DragonSafeZonePart = bestPart
            return bestPart
        end
        return nil
    end

    -- Đóng GUI
    local function CloseFrame(frame)
        if not frame then return false end
        local closeBtn = frame:FindFirstChild("Close_")
        if not closeBtn then
            closeBtn = frame:FindFirstChild("Close")
                or frame:FindFirstChild("CloseButton")
                or frame:FindFirstChild("Exit")
                or frame:FindFirstChildWhichIsA("ImageButton", true)
                or frame:FindFirstChildWhichIsA("TextButton", true)
        end
        if closeBtn then
            pcall(function()
                if firesignal then firesignal(closeBtn.MouseButton1Click) end
            end)
            pcall(function()
                if fireclickdetector then fireclickdetector(closeBtn) end
            end)
            pcall(function()
                local VIM = game:GetService("VirtualInputManager")
                local pos = closeBtn.AbsolutePosition + closeBtn.AbsoluteSize / 2
                VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                task.wait(0.05)
                VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
            end)
            return true
        end
        pcall(function() frame.Visible = false end)
        return true
    end

    -- =====================================================
    -- DragonOpenPortal — Buff TRƯỚC khi mở cổng
    -- =====================================================
    local function DragonOpenPortal()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end

        if tick() < _G.DragonPortalFireLock then return false end

        local bf = workspace:FindFirstChild("Boss Fight")
        if bf and bf:FindFirstChild("Dragon") then
            _G.DragonPortalPhase = "IDLE"
            return true
        end

        -- 🆕 BƯỚC 0: BUFF TRƯỚC KHI MỞ CỔNG (chỉ 1 lần)
        if not _G.DragonBuffUsed then
            _G.DragonBuffUsed = true
            
            local tool, buffName = FindBuffTool()
            if tool then
                print("[Dragon] ⚡ Có buff " .. buffName .. ", bắt đầu spam F trước cổng")
                _G.DragonBuffSpamActive = true
                _G.DragonBuffSpamStartTime = tick()
                _G.DragonBuffFinishTime = 0  -- 🆕 CHƯA xong
                
                task.spawn(function()
                    local startTime = tick()
                    local lastFTime = 0
                    
                    while _G.DragonBuffSpamActive and tick() - startTime < 15 do
                        local now = tick()
                        if now - lastFTime >= DRAGON_BUFF_COOLDOWN then
                            lastFTime = now
                            
                            local c = LocalPlayer.Character
                            if not c then break end
                            
                            -- Ensure equipped
                            local currentTool = nil
                            for _, t in ipairs(c:GetChildren()) do
                                if t:IsA("Tool") and t.Name:lower() == buffName:lower() then
                                    currentTool = t
                                    break
                                end
                            end
                            
                            if not currentTool then
                                local bp = LocalPlayer:FindFirstChild("Backpack")
                                if bp then
                                    for _, t in ipairs(bp:GetChildren()) do
                                        if t:IsA("Tool") and t.Name:lower() == buffName:lower() then
                                            c.Humanoid:EquipTool(t)
                                            task.wait(0.3)
                                            currentTool = t
                                            break
                                        end
                                    end
                                end
                            end
                            
                            if not currentTool then break end
                            
                            -- Check cooldown qua GUI
                            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                            local main = hud and hud:FindFirstChild("Main")
                            local skillList = main and main:FindFirstChild("Frame_SkillList_" .. buffName)
                            
                            local fOnCooldown = false
                            if skillList then
                                local border = skillList:FindFirstChild("Border")
                                local mainFrame = border and border:FindFirstChild("Main")
                                local fFrame = mainFrame and mainFrame:FindFirstChild("F")
                                if fFrame then
                                    local readyLabel = fFrame:FindFirstChild("Ready")
                                    local cooldownFrame = fFrame:FindFirstChild("CooldownFrame")
                                    local isUnready = readyLabel and readyLabel.Text == "UnReady"
                                    local isCooldownVisible = cooldownFrame and cooldownFrame.Visible
                                    if isUnready or isCooldownVisible then
                                        fOnCooldown = true
                                    end
                                end
                            end
                            
                            if fOnCooldown then
                                print("[Dragon] ⏹️ Buff F cooldown → dừng spam")
                                break
                            end
                            
                            if Action then
                                pcall(function()
                                    Action:FireServer(currentTool.Name, "f")
                                end)
                                print("[Dragon] ⚡ Buff F: " .. buffName)
                            end
                        end
                        task.wait(0.1)
                    end
                    
                    _G.DragonBuffSpamActive = false
                    print("[Dragon] ✅ Buff spam xong, đợi 1s rồi mở cổng")
                    task.wait(1)
                    _G.DragonBuffFinishTime = tick()
                    print("[Dragon] ✅ Buff xong, bắt đầu mở cổng")
                end)
                
                -- 🆕 RETURN FALSE (không phải true) — để main loop chờ
                return false
            else
                print("[Dragon] ⚠️ Không có buff tool, bỏ qua")
                _G.DragonBuffFinishTime = tick()
            end
        end

        -- 🆕 Đợi buff spam xong (1s sau khi finish)
        if _G.DragonBuffFinishTime == 0 then
            return false  -- Buff chưa xong → không mở cổng
        end
        if tick() - _G.DragonBuffFinishTime < 1 then
            return false  -- Đợi thêm 1s
        end

        -- BƯỚC 1: Portal
        local tz = workspace:FindFirstChild("TeleportBossFightZone")
        if tz and tz:FindFirstChild("Hitbox") then
            if _G.DragonPortalPhase ~= "ENTERED" then
                hrp.CFrame = tz.Hitbox.CFrame
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                print("[Dragon] 🌀 TP vào portal")
                _G.DragonEnterTime = tick()
                _G.DragonPortalPhase = "ENTERED"
                _G.DragonPortalFireLock = tick() + DRAGON_PORTAL_FIRE_LOCK
            end
            return true
        end

        -- BƯỚC 2: NPC
        local npcPrompt = workspace:FindFirstChild("NpcPrompt")
        local openRaidNPC = npcPrompt and npcPrompt:FindFirstChild("Open Raid")

        if openRaidNPC and _G.DragonPortalPhase == "IDLE" then
            local npcHrp = openRaidNPC:FindFirstChild("HumanoidRootPart")
                or openRaidNPC:FindFirstChildWhichIsA("BasePart")
            if npcHrp then
                local dist = (hrp.Position - npcHrp.Position).Magnitude
                if dist > 10 then
                    hrp.CFrame = CFrame.new(npcHrp.Position + Vector3.new(0, 3, 0))
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    task.wait(0.3)
                end

                if tick() - _G.DragonLastFireTime >= DRAGON_MIN_FIRE_GAP then
                    local prompt = openRaidNPC:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        _G.DragonLastFireTime = tick()
                        _G.DragonPortalPhase = "GUI_OPENING"
                        _G.DragonPortalStartTime = tick()
                        pcall(function() fireproximityprompt(prompt) end)
                        print("[Dragon] 👆 Fire NPC Open Raid")
                        return true
                    end
                end
            end
        end

        -- BƯỚC 3: Click button
        if _G.DragonPortalPhase == "GUI_OPENING" then
            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            local main = hud and hud:FindFirstChild("Main")
            local raidBossFrame = main and main:FindFirstChild("Frame_RaidBoss")

            if raidBossFrame then
                local dragonTemplate = raidBossFrame:FindFirstChild("Template_Dragon")
                if not dragonTemplate then
                    local sf = raidBossFrame:FindFirstChild("ScrollingFrame")
                    if sf then
                        for _, child in ipairs(sf:GetChildren()) do
                            if child.Name:lower():find("dragon") then
                                dragonTemplate = child
                                break
                            end
                        end
                    end
                end

                if dragonTemplate then
                    local openButton = nil
                    for _, obj in ipairs(dragonTemplate:GetDescendants()) do
                        if obj:IsA("TextLabel") and obj.Text == "Open" then
                            local parent = obj.Parent
                            while parent and parent ~= dragonTemplate do
                                if parent:IsA("TextButton") or parent:IsA("ImageButton") then
                                    openButton = parent
                                    break
                                end
                                parent = parent.Parent
                            end
                            if openButton then break end
                        end
                    end
                    if not openButton then
                        local mainBtn = dragonTemplate:FindFirstChild("Main")
                        if mainBtn and (mainBtn:IsA("TextButton") or mainBtn:IsA("ImageButton")) then
                            openButton = mainBtn
                        end
                    end

                    if openButton then
                        print("[Dragon] 🖱️ Click button Open")
                        pcall(function()
                            if firesignal then
                                firesignal(openButton.MouseButton1Click)
                            else
                                openButton:Activate()
                            end
                        end)
                        _G.DragonPortalPhase = "WAITING"
                        _G.DragonPortalStartTime = tick()

                        task.spawn(function()
                            task.wait(0.3)
                            pcall(function()
                                local hud2 = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                                local main2 = hud2 and hud2:FindFirstChild("Main")
                                local raidBossFrame2 = main2 and main2:FindFirstChild("Frame_RaidBoss")
                                if raidBossFrame2 then
                                    CloseFrame(raidBossFrame2)
                                    print("[Dragon] 🚪 Đóng GUI mở cổng")
                                end
                            end)
                        end)
                        return true
                    end
                end
            end

            if tick() - _G.DragonPortalStartTime > 5 then
                print("[Dragon] ⚠️ Timeout GUI → reset")
                _G.DragonPortalPhase = "IDLE"
            end
            return true
        end

        -- BƯỚC 4: Đợi portal
        if _G.DragonPortalPhase == "WAITING" then
            local elapsed = tick() - _G.DragonPortalStartTime
            local tz2 = workspace:FindFirstChild("TeleportBossFightZone")
            if tz2 and tz2:FindFirstChild("Hitbox") then
                hrp.CFrame = tz2.Hitbox.CFrame
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                print("[Dragon] 🌀 TP vào portal (sau click)")
                _G.DragonEnterTime = tick()
                _G.DragonPortalPhase = "ENTERED"
                _G.DragonPortalFireLock = tick() + DRAGON_PORTAL_FIRE_LOCK
                return true
            end
            if bf and bf:FindFirstChild("Dragon") then
                _G.DragonPortalPhase = "ENTERED"
                _G.DragonEnterTime = tick()
                _G.DragonPortalFireLock = tick() + DRAGON_PORTAL_FIRE_LOCK
                return true
            end
            if elapsed > DRAGON_PORTAL_TIMEOUT then
                print("[Dragon] ⚠️ Portal timeout → retry")
                _G.DragonPortalPhase = "IDLE"
                _G.DragonLastFireTime = 0
            end
            return true
        end

        return false
    end

    -- =====================================================
    -- Listener respawn — Buff lại sau khi die
    -- =====================================================
    LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(1)
        if not _G.AutoRaidDragon then return end
        _G.DragonBuffUsed = false
        _G.DragonBuffFinishTime = 0
        _G.DragonPortalPhase = "IDLE"
        _G.DragonPortalFireLock = 0
        _G.DragonEnterTime = 0
        _G.DragonBossDeadHandled = false
        _G.DragonAlertTriggered = false
        _G.DragonSafeZoneActive = false
        _G.DragonSafeZonePart = nil
        _G.DragonThanosFlyPos = nil
        _G.DragonThanosSpamStartTime = 0
        _G.DragonThanosFSuccessCount = 0
        print("[Dragon] 💀 Respawn → reset, buff lại + mở cổng")
    end)

    -- =====================================================
    -- MAIN LOOP
    -- =====================================================
    task.spawn(function()
        while task.wait() do
            pcall(function()
                if not _G.AutoRaidDragon then
                    _G.DragonPortalPhase = "IDLE"
                    _G.DragonAlertTriggered = false
                    _G.DragonSafeZoneActive = false
                    _G.DragonSafeZonePart = nil
                    _G.DragonBossDeadHandled = false
                    _G.DragonThanosFSuccessCount = 0
                    _G.DragonThanosSpamStartTime = 0
                    _G.DragonThanosFlyPos = nil
                    _G.DragonBuffUsed = false
                    _G.DragonBuffFinishTime = 0
                    _G.DragonHasThanosEquipped = false
                    return
                end

                local char = LocalPlayer.Character
                local hum  = char and char:FindFirstChild("Humanoid")
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if not hum or not hrp or hum.Health <= 0 then return end

                local bossModel, bossHrp, bossHum = GetDragonBoss()
                if not bossModel or not bossHrp or not bossHum then
                    if _G.DragonPortalPhase ~= "ENTERED" then
                        DragonOpenPortal()
                    end
                    return
                end

                -- =================================================
                -- BOSS CHẾT
                -- =================================================
                if bossHum.Health <= 0 then
                    if not _G.DragonBossDeadHandled then
                        _G.DragonBossDeadHandled = true
                        _G.DragonPortalPhase = "IDLE"
                        _G.DragonPortalFireLock = tick() + DRAGON_PORTAL_FIRE_LOCK
                        _G.DragonAlertTriggered = false
                        _G.DragonSafeZoneActive = false
                        _G.DragonSafeZonePart = nil
                        _G.DragonThanosFlyPos = nil
                        _G.DragonThanosSpamStartTime = 0
                        _G.DragonThanosFSuccessCount = 0
                        _G.DragonBuffUsed = false
                        _G.DragonBuffFinishTime = 0

                        task.spawn(function()
                            local startTime = tick()
                            local clicked = false

                            while tick() - startTime < 5 do
                                task.wait(0.3)
                                pcall(function()
                                    local hud3 = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                                    local main3 = hud3 and hud3:FindFirstChild("Main")
                                    if not main3 then return end

                                    local rewardFrame = main3:FindFirstChild("Frame_RaidbossItem")
                                    if not rewardFrame then return end
                                    if not rewardFrame.Visible then return end

                                    local titleLabel = rewardFrame:FindFirstChild("TitleLabel")
                                    local isVictory = titleLabel and titleLabel.Text == "Victory"

                                    if isVictory and not clicked then
                                        clicked = true
                                        local closeBtn = rewardFrame:FindFirstChild("Close_")
                                        if closeBtn then
                                            for i = 1, 3 do
                                                pcall(function()
                                                    if firesignal then
                                                        firesignal(closeBtn.MouseButton1Click)
                                                    end
                                                end)
                                                task.wait(0.1)
                                            end
                                            pcall(function()
                                                local VIM = game:GetService("VirtualInputManager")
                                                local pos = closeBtn.AbsolutePosition + closeBtn.AbsoluteSize / 2
                                                VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                                                task.wait(0.05)
                                                VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                                            end)
                                            print("[Dragon] 🎁 Đã click Close_")
                                        else
                                            pcall(function() rewardFrame.Visible = false end)
                                        end
                                        task.wait(0.5)
                                        if rewardFrame.Visible then
                                            pcall(function() rewardFrame.Visible = false end)
                                            print("[Dragon] ⚠️ Vẫn visible → ẩn trực tiếp")
                                        end
                                    end
                                end)
                            end
                        end)
                    end
                    return
                end

                _G.DragonBossDeadHandled = false

                if _G.DragonEnterTime == 0 then
                    _G.DragonEnterTime = tick()
                end

                bossHum.WalkSpeed = 0
                bossHum.JumpPower = 0

                local now = tick()

                -- =================================================
                -- SAFE ZONE — ƯU TIÊN CAO NHẤT
                -- =================================================
                local safePart = FindDragonSafeZone()
                if safePart then
                    if not _G.DragonSafeZoneActive then
                        _G.DragonSafeZoneActive = true
                        print("[Dragon] 🛡️ VÀO VÙNG AN TOÀN")
                    end
                    local safePos = safePart.Position + Vector3.new(0, DRAGON_SAFE_HEIGHT_FLY, 0)
                    hrp.CFrame = CFrame.new(safePos, bossHrp.Position)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    if hrp.AssemblyLinearVelocity.Y < 0 then
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end
                    return
                else
                    if _G.DragonSafeZoneActive then
                        _G.DragonSafeZoneActive = false
                        _G.DragonSafeZonePart = nil
                    end
                end

                -- =================================================
                -- HP < 50% → AUTO SPAM F THANOS (mặc định bật)
                -- =================================================
                local hpPercent = (bossHum.Health / bossHum.MaxHealth) * 100
                local isThanosPriority = hpPercent <= 50

                if isThanosPriority then
                    local thanosEquipped = EnsureThanosEquipped()

                    if not thanosEquipped then
                        local methodFarm = GetDragonMethodFarm(DRAGON_AIM_HEIGHT)
                        hrp.CFrame = bossHrp.CFrame * methodFarm
                        hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        if now - _G.DragonLastAttack >= 0.15 then
                            _G.DragonLastAttack = now
                            local skillFired = TryFireSkill()
                            if not skillFired then Attack() end
                        end
                        return
                    end

                    if _G.DragonThanosSpamStartTime == 0 then
                        _G.DragonThanosSpamStartTime = now
                        _G.DragonThanosFSuccessCount = 0
                        print("[Dragon] ⚡ Bắt đầu Auto spam F Thanos")
                    end

                    local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                    local main = hud and hud:FindFirstChild("Main")
                    local skillList = main and main:FindFirstChild("Frame_SkillList_Thanos")
                    local fOnCooldown = false
                    if skillList then
                        local border = skillList:FindFirstChild("Border")
                        local mainFrame = border and border:FindFirstChild("Main")
                        local fFrame = mainFrame and mainFrame:FindFirstChild("F")
                        if fFrame then
                            local readyLabel = fFrame:FindFirstChild("Ready")
                            local cooldownFrame = fFrame:FindFirstChild("CooldownFrame")
                            local isUnready = readyLabel and readyLabel.Text == "UnReady"
                            local isCooldownVisible = cooldownFrame and cooldownFrame.Visible
                            if isUnready or isCooldownVisible then
                                fOnCooldown = true
                            end
                        end
                    end

                    -- 🆕 F cooldown → bay lên 500 (cao)
                    if fOnCooldown then
                        if not _G.DragonThanosFlyPos then
                            _G.DragonThanosFlyPos = Vector3.new(
                                hrp.Position.X,
                                hrp.Position.Y + DRAGON_SAFE_HEIGHT_FLY,
                                hrp.Position.Z
                            )
                        end
                        hrp.CFrame = CFrame.new(_G.DragonThanosFlyPos, bossHrp.Position)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        return
                    end

                    -- 🆕 F sẵn sàng → chuẩn bị spam
                    if now - _G.DragonLastThanosTime >= DRAGON_THANOS_COOLDOWN then
                        _G.DragonLastThanosTime = now
                        local result = TryUseThanosF(hrp)
                        if result == "success" then
                            _G.DragonThanosFSuccessCount = _G.DragonThanosFSuccessCount + 1
                            _G.DragonThanosFlyPos = nil
                            
                            -- 🆕 Bay lên 100 studs sau mỗi lần F thành công
                            local boostPos = Vector3.new(
                                hrp.Position.X,
                                hrp.Position.Y + 100,  -- 🆕 Bay lên 100 studs
                                hrp.Position.Z
                            )
                            hrp.CFrame = CFrame.new(boostPos, bossHrp.Position)
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                            
                            if _G.DragonThanosFSuccessCount <= 5 or _G.DragonThanosFSuccessCount % 5 == 0 then
                                print(string.format("[Dragon] ⚡ F Thanos #%d (HP: %.1f%%) — bay lên 100",
                                    _G.DragonThanosFSuccessCount, hpPercent))
                            end
                            return  -- 🆕 Return để frame sau xử lý tiếp
                        elseif result == "cooldown" then
                            if not _G.DragonThanosFlyPos then
                                _G.DragonThanosFlyPos = Vector3.new(
                                    hrp.Position.X,
                                    hrp.Position.Y + DRAGON_SAFE_HEIGHT_FLY,
                                    hrp.Position.Z
                                )
                            end
                            hrp.CFrame = CFrame.new(_G.DragonThanosFlyPos, bossHrp.Position)
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end
                    end

                    -- 🆕 Bám boss + từ từ rơi xuống (không set velocity Y = 0)
                    local methodFarm = GetDragonMethodFarm(DRAGON_AIM_HEIGHT)
                    hrp.CFrame = bossHrp.CFrame * methodFarm
                    -- 🆕 Chỉ zero X, Z — giữ Y để rơi tự nhiên
                    hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    
                    if now - _G.DragonLastAttack >= 0.1 then
                        _G.DragonLastAttack = now
                        Attack()
                    end
                    return
                else
                    if _G.DragonThanosFlyPos then _G.DragonThanosFlyPos = nil end
                    _G.DragonThanosSpamStartTime = 0
                    _G.DragonThanosFSuccessCount = 0
                end

                -- =================================================
                -- BÁM BOSS BÌNH THƯỜNG
                -- =================================================
                local methodFarm = GetDragonMethodFarm(DRAGON_AIM_HEIGHT)
                hrp.CFrame = bossHrp.CFrame * methodFarm
                hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
                hrp.AssemblyAngularVelocity = Vector3.zero

                if now - _G.DragonLastEquip >= 0.5 then
                    _G.DragonLastEquip = now
                    if _G.EnableEquipWeapon then EquipWeapon() end
                end

                if now - _G.DragonLastAttack >= 0.15 then
                    _G.DragonLastAttack = now
                    local skillFired = TryFireSkill()
                    if not skillFired then Attack() end
                end
            end)
        end
    end)
end

-- ============================================================
-- 🆕 AUTO RAID BOSS LAVA TITAN — v10 FINAL
-- - HP < X% → Thanos priority CAO NHẤT (trước boss lặn/trồi)
-- - Ensure Thanos equipped NGAY LẬP TỨC
-- - Bám boss suốt quá trình spam F (kể cả lặn/trồi)
-- - HP >= X% → boss lặn → bay lên không
-- - HP >= X% → boss trồi → đợi 1.5s → bám đánh
-- - Đóng GUI mở cổng + GUI nhận thưởng
-- ============================================================
if not IsMoonMap then
    _G.AutoRaidLava           = false
    _G.LavaLastFireTime       = 0
    _G.LavaLastAttack         = 0
    _G.LavaLastEquip          = 0
    _G.LavaEnterTime          = 0
    _G.LavaPortalPhase        = "IDLE"
    _G.LavaPortalStartTime    = 0
    _G.LavaBossOriginPos      = nil
    _G.LavaLastThanosTime     = 0
    _G.LavaLastDebug          = 0
    _G.LavaWaitingSurface     = false
    _G.LavaBossSurfacedTime   = 0
    _G.LavaPortalFireLock     = 0
    _G.LavaPhase2Active       = false
    _G.LavaThanosUsed         = false
    _G.LavaThanosUsedTime     = 0
    _G.LavaThanosLockUntil    = 0
    _G.LavaThanosFlyPos       = nil
    _G.LavaSafePos            = nil
    _G.LavaBossDeadHandled    = false
    _G.LavaThanosFSuccessCount = 0
    _G.LavaThanosLastSuccessTime = 0
    _G.LavaThanosSpamStartTime = 0
	_G.LavaBuffUsed             = false
    _G.LavaBuffFinishTime       = 0
    _G.LavaBuffSpamStartTime    = 0

    local LAVA_AIM_HEIGHT        = 25
    local LAVA_UNDER_LAVA_Y      = -100
    local LAVA_MIN_FIRE_GAP      = 3
    local LAVA_PORTAL_TIMEOUT    = 15
    local LAVA_THANOS_COOLDOWN   = 0.3
    local LAVA_SURFACE_DELAY     = 1.5
    local LAVA_PORTAL_FIRE_LOCK  = 5
    local LAVA_SAFE_HEIGHT       = 500
    local LAVA_THANOS_LOCK_TIME  = 1.5

    local function GetLavaMethodFarm(height)
        height = height or LAVA_AIM_HEIGHT
        return CFrame.new(0, height, 0) * CFrame.Angles(math.rad(-90), 0, 0)
    end

    -- =====================================================
    -- 🆕 Tìm tool Thanos
    -- =====================================================
    local function FindLavaThanosTool()
        local char = LocalPlayer.Character
        if not char then return nil, "character" end
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name == "thanos" or name:find("thanos") then
                    return tool, "character"
                end
            end
        end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") then
                    local name = tool.Name:lower()
                    if name == "thanos" or name:find("thanos") then
                        return tool, "backpack"
                    end
                end
            end
        end
        return nil, "none"
    end

    -- =====================================================
    -- 🆕 Ensure Thanos equipped NGAY LẬP TỨC
    -- =====================================================
    local function EnsureLavaThanosEquipped()
        local char = LocalPlayer.Character
        if not char then return false end
        local tool, location = FindLavaThanosTool()
        if not tool then return false end
        if location == "character" then return true end
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            pcall(function() hum:EquipTool(tool) end)
            task.wait(0.2)
            print("[LavaTitan] 🗡️ Đã trang bị Thanos")
            return true
        end
        return false
    end
	
	    -- =====================================================
    -- 🆕 Tìm tool buff (SSJ/Kaioken/...)
    -- =====================================================
    local LAVA_BUFF_LIST = {"Kaioken", "SSJ", "SSJ2", "SSJ3", "SSJG"}

    local function FindLavaBuffTool()
        local char = LocalPlayer.Character
        if not char then return nil, nil end
        for _, buffName in ipairs(LAVA_BUFF_LIST) do
            for _, tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") and tool.Name:lower() == buffName:lower() then
                    return tool, buffName
                end
            end
        end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, buffName in ipairs(LAVA_BUFF_LIST) do
                for _, tool in ipairs(bp:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name:lower() == buffName:lower() then
                        return tool, buffName
                    end
                end
            end
        end
        return nil, nil
    end

    -- =====================================================
    -- 🆕 Spam F buff đến khi cooldown
    -- =====================================================
    local function LavaBuffSpamLoop()
        local tool, buffName = FindLavaBuffTool()
        if not tool then
            print("[LavaTitan] ⚠️ Không có buff tool, bỏ qua")
            return false
        end

        print("[LavaTitan] ⚡ Bắt đầu spam F buff: " .. buffName)
        local startTime = tick()
        local lastFTime = 0

        while tick() - startTime < 15 do
            local now = tick()
            if now - lastFTime >= 0.3 then
                lastFTime = now

                local char = LocalPlayer.Character
                if not char then break end

                -- Ensure equipped
                local currentTool = nil
                for _, t in ipairs(char:GetChildren()) do
                    if t:IsA("Tool") and t.Name:lower() == buffName:lower() then
                        currentTool = t
                        break
                    end
                end
                if not currentTool then
                    local bp = LocalPlayer:FindFirstChild("Backpack")
                    if bp then
                        for _, t in ipairs(bp:GetChildren()) do
                            if t:IsA("Tool") and t.Name:lower() == buffName:lower() then
                                char.Humanoid:EquipTool(t)
                                task.wait(0.3)
                                currentTool = t
                                break
                            end
                        end
                    end
                end
                if not currentTool then break end

                -- Check cooldown qua GUI
                local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                local main = hud and hud:FindFirstChild("Main")
                local skillList = main and main:FindFirstChild("Frame_SkillList_" .. buffName)
                local fOnCooldown = false
                if skillList then
                    local border = skillList:FindFirstChild("Border")
                    local mainFrame = border and border:FindFirstChild("Main")
                    local fFrame = mainFrame and mainFrame:FindFirstChild("F")
                    if fFrame then
                        local readyLabel = fFrame:FindFirstChild("Ready")
                        local cooldownFrame = fFrame:FindFirstChild("CooldownFrame")
                        local isUnready = readyLabel and readyLabel.Text == "UnReady"
                        local isCooldownVisible = cooldownFrame and cooldownFrame.Visible
                        if isUnready or isCooldownVisible then
                            fOnCooldown = true
                        end
                    end
                end

                if fOnCooldown then
                    print("[LavaTitan] ⏹️ Buff F cooldown → dừng spam")
                    break
                end

                if Action then
                    pcall(function()
                        Action:FireServer(currentTool.Name, "f")
                    end)
                    print("[LavaTitan] ⚡ Buff F: " .. buffName)
                end
            end
            task.wait(0.1)
        end

        print("[LavaTitan] ✅ Buff spam xong, đợi 2s rồi mở cổng")
        return true
    end

    -- =====================================================
    -- TryUseThanosF — Check cooldown qua GUI
    -- Return: "success" | "cooldown" | "no_tool"
    -- =====================================================
    local function TryUseThanosF(hrp)
        if not hrp then return "no_tool" end
        local char = LocalPlayer.Character
        if not char then return "no_tool" end

        -- 🆕 Ensure equipped NGAY
        if not EnsureLavaThanosEquipped() then
            return "no_tool"
        end

        -- Tìm tool Thanos đã equip
        local thanosTool = nil
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name == "thanos" or name:find("thanos") then
                    thanosTool = tool
                    break
                end
            end
        end

        if not thanosTool then return "no_tool" end

        -- Check cooldown qua GUI
        local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        local main = hud and hud:FindFirstChild("Main")
        local skillList = main and main:FindFirstChild("Frame_SkillList_Thanos")

        if skillList then
            local border = skillList:FindFirstChild("Border")
            local mainFrame = border and border:FindFirstChild("Main")
            local fFrame = mainFrame and mainFrame:FindFirstChild("F")

            if fFrame then
                local readyLabel = fFrame:FindFirstChild("Ready")
                local cooldownFrame = fFrame:FindFirstChild("CooldownFrame")
                local isUnready = readyLabel and readyLabel.Text == "UnReady"
                local isCooldownVisible = cooldownFrame and cooldownFrame.Visible
                if isUnready or isCooldownVisible then
                    return "cooldown"
                end
            end
        end

        task.wait(0.3)

        if Action then
            pcall(function()
                Action:FireServer(thanosTool.Name, "f")
            end)
            task.wait(0.3)
            return "success"
        end
        return "no_tool"
    end

    -- Hook alert Phase 2
    local function OnLavaAlert(text)
        if not text then return end
        local lower = text:lower()
        if lower:find("lava is rising", 1, true)
           or lower:find("get on the center platform", 1, true) then
            if not _G.LavaPhase2Active then
                _G.LavaPhase2Active = true
                print("[LavaTitan] 🚨 PHASE 2: LAVA IS RISING!")
            end
        end
    end

    local function HookLavaText(container)
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                OnLavaAlert(obj.Text)
                obj:GetPropertyChangedSignal("Text"):Connect(function()
                    OnLavaAlert(obj.Text)
                end)
            end
        end
    end
	
	-- 🆕 Listener respawn — Buff lại sau khi die
    LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(1)
        if not _G.AutoRaidLava then return end
        _G.LavaBuffUsed = false
        _G.LavaBuffFinishTime = 0
        _G.LavaPortalPhase = "IDLE"
        _G.LavaPortalFireLock = 0
        _G.LavaEnterTime = 0
        _G.LavaBossDeadHandled = false
        _G.LavaPhase2Active = false
        _G.LavaThanosFlyPos = nil
        _G.LavaThanosSpamStartTime = 0
        _G.LavaThanosFSuccessCount = 0
        print("[LavaTitan] 💀 Respawn → reset, buff lại + mở cổng")
    end)
	
    HookLavaText(LocalPlayer.PlayerGui)
    LocalPlayer.PlayerGui.DescendantAdded:Connect(function(obj)
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            task.wait(0.1)
            OnLavaAlert(obj.Text)
            obj:GetPropertyChangedSignal("Text"):Connect(function()
                OnLavaAlert(obj.Text)
            end)
        end
    end)

    local function IsBossUnderLava(bossHrp)
        if not bossHrp then return false end
        return bossHrp.Position.Y < LAVA_UNDER_LAVA_Y
    end

    local function GetLavaBoss()
        local bf = workspace:FindFirstChild("Boss Fight")
        if not bf then return nil, nil, nil end
        local lavaFolder = bf:FindFirstChild("LavaTitan")
        if not lavaFolder then return nil, nil, nil end
        for _, obj in ipairs(lavaFolder:GetChildren()) do
            if obj:IsA("Model") then
                local hum = obj:FindFirstChild("Humanoid")
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if hum and hrp then
                    return obj, hrp, hum
                end
            end
        end
        return nil, nil, nil
    end

    -- 🆕 Đóng GUI helper
    local function CloseFrame(frame)
        if not frame then return false end
        local closeBtn = frame:FindFirstChild("Close_")
            or frame:FindFirstChild("Close")
            or frame:FindFirstChild("CloseButton")
            or frame:FindFirstChild("Exit")
            or frame:FindFirstChildWhichIsA("ImageButton", true)
            or frame:FindFirstChildWhichIsA("TextButton", true)
        if closeBtn then
            pcall(function()
                if firesignal then
                    firesignal(closeBtn.MouseButton1Click)
                elseif fireclickdetector then
                    fireclickdetector(closeBtn)
                else
                    closeBtn:Activate()
                end
            end)
            return true
        end
        pcall(function() frame.Visible = false end)
        return true
    end

    -- =====================================================
    -- LavaOpenPortal — Buff SSJ trước khi mở cổng
    -- =====================================================
    local function LavaOpenPortal()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end

        if tick() < _G.LavaPortalFireLock then return false end

        local bf = workspace:FindFirstChild("Boss Fight")
        if bf and bf:FindFirstChild("LavaTitan") then
            _G.LavaPortalPhase = "IDLE"
            return true
        end

        -- 🆕 BƯỚC 0: BUFF SSJ TRƯỚC KHI MỞ CỔNG (chỉ 1 lần)
        if not _G.LavaBuffUsed then
            _G.LavaBuffUsed = true

            local tool, buffName = FindLavaBuffTool()
            if tool then
                print("[LavaTitan] ⚡ Có buff " .. buffName .. ", bắt đầu spam F trước cổng")
                _G.LavaBuffSpamStartTime = tick()
                _G.LavaBuffFinishTime = 0

                task.spawn(function()
                    LavaBuffSpamLoop()
                    print("[LavaTitan] ✅ Buff spam xong, đợi 2s...")
                    task.wait(2)
                    _G.LavaBuffFinishTime = tick()
                    print("[LavaTitan] ✅ Buff xong, bắt đầu mở cổng")
                    _G.LavaPortalPhase = "IDLE"
                    _G.LavaLastFireTime = 0
                end)
                return false  -- Chưa mở cổng, đang buff
            else
                print("[LavaTitan] ⚠️ Không có buff tool, bỏ qua")
                _G.LavaBuffFinishTime = tick()
            end
        end

        -- 🆕 Đợi buff xong (2s sau khi finish)
        if _G.LavaBuffFinishTime == 0 then
            return false
        end
        if tick() - _G.LavaBuffFinishTime < 2 then
            return false
        end

        -- BƯỚC 1: Portal đã có → TP vào
        local tz = workspace:FindFirstChild("TeleportBossFightZone")
        if tz and tz:FindFirstChild("Hitbox") then
            if _G.LavaPortalPhase ~= "ENTERED" then
                hrp.CFrame = tz.Hitbox.CFrame
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                print("[LavaTitan] 🌀 TP vào portal")
                _G.LavaEnterTime = tick()
                _G.LavaPortalPhase = "ENTERED"
                _G.LavaPortalFireLock = tick() + LAVA_PORTAL_FIRE_LOCK
            end
            return true
        end

        -- BƯỚC 2: TP tới NPC + Fire prompt
        local npcPrompt = workspace:FindFirstChild("NpcPrompt")
        local openRaidNPC = npcPrompt and npcPrompt:FindFirstChild("Open Raid")

        if openRaidNPC and _G.LavaPortalPhase == "IDLE" then
            local npcHrp = openRaidNPC:FindFirstChild("HumanoidRootPart")
                or openRaidNPC:FindFirstChildWhichIsA("BasePart")
            if npcHrp then
                local dist = (hrp.Position - npcHrp.Position).Magnitude
                if dist > 10 then
                    hrp.CFrame = CFrame.new(npcHrp.Position + Vector3.new(0, 3, 0))
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    task.wait(0.3)
                end

                if tick() - _G.LavaLastFireTime >= LAVA_MIN_FIRE_GAP then
                    local prompt = openRaidNPC:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        _G.LavaLastFireTime = tick()
                        _G.LavaPortalPhase = "GUI_OPENING"
                        _G.LavaPortalStartTime = tick()
                        pcall(function() fireproximityprompt(prompt) end)
                        print("[LavaTitan] 👆 Fire NPC Open Raid")
                        return true
                    end
                end
            end
        end

        -- BƯỚC 3: Click button Lava Titan
        if _G.LavaPortalPhase == "GUI_OPENING" then
            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            local main = hud and hud:FindFirstChild("Main")
            local raidBossFrame = main and main:FindFirstChild("Frame_RaidBoss")

            if raidBossFrame then
                local lavaTemplate = raidBossFrame:FindFirstChild("Template_LavaTitan")
                if not lavaTemplate then
                    local sf = raidBossFrame:FindFirstChild("ScrollingFrame")
                    if sf then
                        for _, child in ipairs(sf:GetChildren()) do
                            if child.Name:lower():find("lavatitan") then
                                lavaTemplate = child
                                break
                            end
                        end
                    end
                end

                if lavaTemplate then
                    local openButton = nil
                    for _, obj in ipairs(lavaTemplate:GetDescendants()) do
                        if obj:IsA("TextLabel") and obj.Text == "Open" then
                            local parent = obj.Parent
                            while parent and parent ~= lavaTemplate do
                                if parent:IsA("TextButton") or parent:IsA("ImageButton") then
                                    openButton = parent
                                    break
                                end
                                parent = parent.Parent
                            end
                            if openButton then break end
                        end
                    end
                    if not openButton then
                        local mainBtn = lavaTemplate:FindFirstChild("Main")
                        if mainBtn and (mainBtn:IsA("TextButton") or mainBtn:IsA("ImageButton")) then
                            openButton = mainBtn
                        end
                    end

                    if openButton then
                        print("[LavaTitan] 🖱️ Click button Open")
                        pcall(function()
                            if firesignal then
                                firesignal(openButton.MouseButton1Click)
                            else
                                openButton:Activate()
                            end
                        end)
                        _G.LavaPortalPhase = "WAITING"
                        _G.LavaPortalStartTime = tick()

                        task.spawn(function()
                            task.wait(0.3)
                            pcall(function()
                                local hud2 = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                                local main2 = hud2 and hud2:FindFirstChild("Main")
                                local raidBossFrame2 = main2 and main2:FindFirstChild("Frame_RaidBoss")
                                if raidBossFrame2 then
                                    CloseFrame(raidBossFrame2)
                                    print("[LavaTitan] 🚪 Đóng GUI mở cổng")
                                end
                            end)
                        end)
                        return true
                    end
                end
            end

            if tick() - _G.LavaPortalStartTime > 5 then
                print("[LavaTitan] ⚠️ Timeout GUI → reset")
                _G.LavaPortalPhase = "IDLE"
            end
            return true
        end

        -- BƯỚC 4: Đợi portal
        if _G.LavaPortalPhase == "WAITING" then
            local elapsed = tick() - _G.LavaPortalStartTime
            local tz2 = workspace:FindFirstChild("TeleportBossFightZone")
            if tz2 and tz2:FindFirstChild("Hitbox") then
                hrp.CFrame = tz2.Hitbox.CFrame
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                print("[LavaTitan] 🌀 TP vào portal (sau click)")
                _G.LavaEnterTime = tick()
                _G.LavaPortalPhase = "ENTERED"
                _G.LavaPortalFireLock = tick() + LAVA_PORTAL_FIRE_LOCK
                return true
            end
            if bf and bf:FindFirstChild("LavaTitan") then
                _G.LavaPortalPhase = "ENTERED"
                _G.LavaEnterTime = tick()
                _G.LavaPortalFireLock = tick() + LAVA_PORTAL_FIRE_LOCK
                return true
            end
            if elapsed > LAVA_PORTAL_TIMEOUT then
                print("[LavaTitan] ⚠️ Portal timeout → retry")
                _G.LavaPortalPhase = "IDLE"
                _G.LavaLastFireTime = 0
            end
            return true
        end

        return false
    end

    -- =====================================================
    -- MAIN LOOP
    -- =====================================================
    task.spawn(function()
        while task.wait() do
            pcall(function()
                if not _G.AutoRaidLava then
                    _G.LavaPhase2Active = false
                    _G.LavaPortalPhase = "IDLE"
                    _G.LavaBossOriginPos = nil
                    _G.LavaWaitingSurface = false
                    _G.LavaBossSurfacedTime = 0
                    _G.LavaThanosUsed = false
                    _G.LavaThanosLockUntil = 0
                    _G.LavaThanosFlyPos = nil
                    _G.LavaSafePos = nil
                    _G.LavaBossDeadHandled = false
                    _G.LavaThanosSpamStartTime = 0
                    _G.LavaThanosFSuccessCount = 0
					_G.LavaBuffUsed = false
                    _G.LavaBuffFinishTime = 0
                    return
                end

                local char = LocalPlayer.Character
                local hum  = char and char:FindFirstChild("Humanoid")
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if not hum or not hrp or hum.Health <= 0 then return end

                local bossModel, bossHrp, bossHum = GetLavaBoss()
                if not bossModel or not bossHrp or not bossHum then
                    if _G.LavaPortalPhase ~= "ENTERED" then
                        LavaOpenPortal()
                    end
                    return
                end

                -- =================================================
                -- BOSS CHẾT → ĐÓNG GUI + RESET
                -- =================================================
                if bossHum.Health <= 0 then
                    if not _G.LavaBossDeadHandled then
                        _G.LavaBossDeadHandled = true
                        _G.LavaPortalPhase = "IDLE"
                        _G.LavaPortalFireLock = tick() + LAVA_PORTAL_FIRE_LOCK
                        _G.LavaThanosUsed = false
                        _G.LavaThanosLockUntil = 0
                        _G.LavaThanosFlyPos = nil
                        _G.LavaSafePos = nil
                        _G.LavaPhase2Active = false
                        _G.LavaThanosSpamStartTime = 0
                        _G.LavaThanosFSuccessCount = 0
                        _G.LavaThanosLastSuccessTime = 0
						_G.LavaBuffUsed = false
                        _G.LavaBuffFinishTime = 0

                        -- Đóng GUI nhận thưởng — loop 5s
                        task.spawn(function()
                            local startTime = tick()
                            while tick() - startTime < 5 do
                                task.wait(0.2)
                                pcall(function()
                                    local hud3 = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                                    local main3 = hud3 and hud3:FindFirstChild("Main")
                                    if not main3 then return end
                                    local rewardFrame = main3:FindFirstChild("Frame_RaidbossItem")
                                        or main3:FindFirstChild("Frame_RaidBossItem")
                                        or main3:FindFirstChild("Frame_RaidBoss")
                                        or main3:FindFirstChild("Frame_Raidboss")
                                    if rewardFrame then
                                        local titleLabel = rewardFrame:FindFirstChild("TitleLabel")
                                        local isVictory = titleLabel and titleLabel.Text == "Victory"
                                        local closeBtn = rewardFrame:FindFirstChild("Close_")
                                        local closeVisible = closeBtn and closeBtn.Visible
                                        if isVictory or closeVisible then
                                            CloseFrame(rewardFrame)
                                            print("[LavaTitan] 🎁 Đóng GUI nhận thưởng (Victory=" 
                                                .. tostring(isVictory) .. ")")
                                            task.wait(1)
                                        end
                                    end
                                end)
                            end
                        end)
                    end
                    return
                end

                _G.LavaBossDeadHandled = false

                if _G.LavaEnterTime == 0 then
                    _G.LavaEnterTime = tick()
                end

                bossHum.WalkSpeed = 0
                bossHum.JumpPower = 0

                local now = tick()

                if not _G.LavaBossOriginPos then
                    _G.LavaBossOriginPos = bossHrp.Position
                end

                -- =================================================
                -- 🆕 HP < X% → THANOS PRIORITY (TRƯỚC boss lặn/trồi)
                -- =================================================
                local hpPercent = (bossHum.Health / bossHum.MaxHealth) * 100
                local threshold = _G.LavaThanosHPPercent or 50
                local isThanosPriority = hpPercent <= threshold

                if isThanosPriority then
                    -- 🆕 Ensure Thanos equipped NGAY
                    local thanosEquipped = EnsureLavaThanosEquipped()

                    if not thanosEquipped then
                        -- Không có Thanos → đánh thường
                        local methodFarm = GetLavaMethodFarm(LAVA_AIM_HEIGHT)
                        hrp.CFrame = bossHrp.CFrame * methodFarm
                        hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        if now - _G.LavaLastAttack >= 0.15 then
                            _G.LavaLastAttack = now
                            Attack()
                        end
                        return
                    end

                    -- Khởi tạo spam
                    if _G.LavaThanosSpamStartTime == 0 then
                        _G.LavaThanosSpamStartTime = now
                        _G.LavaThanosFSuccessCount = 0
                        print("[LavaTitan] ⚡ Bắt đầu Auto spam F Thanos")
                    end

                    -- Khởi tạo spam
                    if _G.LavaThanosSpamStartTime == 0 then
                        _G.LavaThanosSpamStartTime = now
                        _G.LavaThanosFSuccessCount = 0
                        print("[LavaTitan] ⚡ Bắt đầu Auto spam F Thanos")
                    end

                    -- Check cooldown F
                    local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                    local main = hud and hud:FindFirstChild("Main")
                    local skillList = main and main:FindFirstChild("Frame_SkillList_Thanos")
                    local fOnCooldown = false
                    if skillList then
                        local border = skillList:FindFirstChild("Border")
                        local mainFrame = border and border:FindFirstChild("Main")
                        local fFrame = mainFrame and mainFrame:FindFirstChild("F")
                        if fFrame then
                            local readyLabel = fFrame:FindFirstChild("Ready")
                            local cooldownFrame = fFrame:FindFirstChild("CooldownFrame")
                            local isUnready = readyLabel and readyLabel.Text == "UnReady"
                            local isCooldownVisible = cooldownFrame and cooldownFrame.Visible
                            if isUnready or isCooldownVisible then
                                fOnCooldown = true
                            end
                        end
                    end

                    -- 🆕 F cooldown → bay lên cao chờ
                    if fOnCooldown then
                        if not _G.LavaThanosFlyPos then
                            _G.LavaThanosFlyPos = Vector3.new(
                                hrp.Position.X,
                                hrp.Position.Y + LAVA_SAFE_HEIGHT,
                                hrp.Position.Z
                            )
                        end
                        hrp.CFrame = CFrame.new(_G.LavaThanosFlyPos, bossHrp.Position)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        return
                    end

                    -- 🆕 F sẵn sàng → bám boss + spam F
                    if now - _G.LavaLastThanosTime >= LAVA_THANOS_COOLDOWN then
                        -- Bám boss 1 frame để F chắc chắn trúng
                        local bossPos = bossHrp.Position
                        local targetPos = bossPos + Vector3.new(0, LAVA_AIM_HEIGHT, 0)
                        hrp.CFrame = CFrame.new(targetPos, bossPos)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero

                        _G.LavaLastThanosTime = now
                        local result = TryUseThanosF(hrp)
                        if result == "success" then
                            _G.LavaThanosFSuccessCount = _G.LavaThanosFSuccessCount + 1
                            _G.LavaThanosLastSuccessTime = now
                            _G.LavaThanosUsed = true
                            -- 🆕 Spam F thành công → bay lên ngay 500 studs
                            _G.LavaThanosFlyPos = Vector3.new(
                                hrp.Position.X,
                                hrp.Position.Y + LAVA_SAFE_HEIGHT,
                                hrp.Position.Z
                            )
                            hrp.CFrame = CFrame.new(_G.LavaThanosFlyPos, bossHrp.Position)
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                            if _G.LavaThanosFSuccessCount <= 5 or _G.LavaThanosFSuccessCount % 5 == 0 then
                                print(string.format("[LavaTitan] ⚡ F Thanos #%d (HP: %.1f%%) — bay lên 500",
                                    _G.LavaThanosFSuccessCount, hpPercent))
                            end
                        end
                    end
                    return
                else
                    -- HP >= ngưỡng → reset
                    if _G.LavaThanosUsed then _G.LavaThanosUsed = false end
                    if _G.LavaThanosLockUntil > 0 then _G.LavaThanosLockUntil = 0 end
                    _G.LavaThanosFlyPos = nil
                    _G.LavaSafePos = nil
                    _G.LavaThanosSpamStartTime = 0
                    _G.LavaThanosFSuccessCount = 0
                end

                -- =================================================
                -- BOSS LẶN → BAY LÊN KHÔNG (chỉ khi HP >= ngưỡng)
                -- =================================================
                local bossUnderLava = IsBossUnderLava(bossHrp)

                if bossUnderLava then
                    if not _G.LavaWaitingSurface then
                        _G.LavaWaitingSurface = true
                        _G.LavaBossSurfacedTime = 0
                        print("[LavaTitan] 🌊 Boss lặn → bay lên không chờ")
                    end
                    local originPos = _G.LavaBossOriginPos or bossHrp.Position
                    local safePos = originPos + Vector3.new(0, LAVA_AIM_HEIGHT, 0)
                    hrp.CFrame = CFrame.new(safePos, originPos)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    return
                else
                    if _G.LavaWaitingSurface then
                        if _G.LavaBossSurfacedTime == 0 then
                            _G.LavaBossSurfacedTime = now
                            print("[LavaTitan] ⬆️ Boss trồi → đợi " .. LAVA_SURFACE_DELAY .. "s")
                        end
                        if now - _G.LavaBossSurfacedTime < LAVA_SURFACE_DELAY then
                            local originPos = _G.LavaBossOriginPos or bossHrp.Position
                            local safePos = originPos + Vector3.new(0, LAVA_AIM_HEIGHT, 0)
                            hrp.CFrame = CFrame.new(safePos, originPos)
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                            return
                        end
                        _G.LavaWaitingSurface = false
                        _G.LavaBossSurfacedTime = 0
                        print("[LavaTitan] ⚡ Boss đã trồi hẳn → bám đánh")
                    end
                end

                -- =================================================
                -- BÁM BOSS BÌNH THƯỜNG (HP >= ngưỡng)
                -- =================================================
                local methodFarm = GetLavaMethodFarm(LAVA_AIM_HEIGHT)
                hrp.CFrame = bossHrp.CFrame * methodFarm
                hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
                hrp.AssemblyAngularVelocity = Vector3.zero

                if now - _G.LavaLastEquip >= 0.5 then
                    _G.LavaLastEquip = now
                    if _G.EnableEquipWeapon then EquipWeapon() end
                end

                if now - _G.LavaLastAttack >= 0.15 then
                    _G.LavaLastAttack = now
                    local skillFired = TryFireSkill()
                    if not skillFired then Attack() end
                end
            end)
        end
    end)
end

-- ============================================================
-- AUTO CLOSE REWARD GUI
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            if not hud or not hud:FindFirstChild("Main") then return end

            local closeList = {
                {_G.AutoDungeon,     "Frame_DungeonItem",   "Dungeon"},
                {_G.AutoRaidRunning, "Frame_RaidbossItem",  "Raid Boss"},
                {_G.AutoRaidRunning, "Frame_RaidBossItem",  "Raid Boss"},
            }

            for _, entry in ipairs(closeList) do
                if entry[1] then
                    local fd = hud.Main:FindFirstChild(entry[2])
                    if fd and fd.Visible then
                        task.wait(2)  -- đợi xem reward
                        if not fd.Visible then continue end

                        local closeBtn = fd:FindFirstChild("Close_")
                            or fd:FindFirstChild("Close")
                            or fd:FindFirstChild("CloseButton")
                            or fd:FindFirstChild("Exit")
                            or fd:FindFirstChildWhichIsA("TextButton", true)

                        if closeBtn then
                            pcall(function()
                                if firesignal then
                                    firesignal(closeBtn.MouseButton1Click)
                                else
                                    closeBtn:Activate()
                                end
                            end)
                        else
                            -- Fallback: ẩn trực tiếp
                            pcall(function() fd.Visible = false end)
                        end
                    end
                end
            end
        end)
    end
end)

-- ============================================================
-- BOSS SPAWN CHECK HELPERS
-- ============================================================
local BossCheckList = {
    ["Thief"]      = {"Bacon Thief"},
    ["Piccolo"]    = {"Piccolo"},
    ["Duck"]       = {"Duck Monster"},
    ["Devil Boat"] = {"Devil Boat", "DevilBoat"},
    ["Kraken"]     = {"Kraken"},
}

local function IsMobAlive(mobNames)
    if type(mobNames) == "string" then mobNames = {mobNames} end
    local searchFolders = {
        workspace:FindFirstChild("Mob"),
        workspace:FindFirstChild("Mobs"),
        workspace:FindFirstChild("Boss"),
        workspace:FindFirstChild("MobSpawnGroup"),
    }
    for _, folder in ipairs(searchFolders) do
        if folder then
            for _, obj in ipairs(folder:GetChildren()) do
                if obj:IsA("Model") then
                    for _, targetName in ipairs(mobNames) do
                        if obj.Name == targetName then
                            local hum = obj:FindFirstChild("Humanoid")
                            local hrp = obj:FindFirstChild("HumanoidRootPart")
                            if hum and hrp and hum.Health > 0 then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

local function GetBossSpawnStatus()
    local lines = {}
    for displayName, mobNames in pairs(BossCheckList) do
        local alive = IsMobAlive(mobNames)
        if alive then
            lines[#lines+1] = "✅ " .. displayName .. " : Spawned"
        else
            lines[#lines+1] = "❌ " .. displayName .. " : Not Spawned"
        end
    end

    local bf = workspace:FindFirstChild("Boss")
    if bf then
        local bossNames = {}
        for _, mob in ipairs(bf:GetChildren()) do
            if mob:IsA("Model") then
                local hum = mob:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    table.insert(bossNames, mob.Name)
                end
            end
        end
        if #bossNames > 0 then
            lines[#lines+1] = ""
            lines[#lines+1] = "🔥 Summoned:"
            for _, name in ipairs(bossNames) do
                lines[#lines+1] = "  • " .. name
            end
        end
    end
    return table.concat(lines, "\n")
end

-- ============================================================
-- 🌊 SEA 1 TABS UI
-- ============================================================
if Tabs.Main then
    Tabs.Main:AddToggle("AutoFarm", {
        Title = "🌾 Auto Farm (All Mobs)",
        Default = false,
        Callback = function(v)
            _G.AutoFarm = v
            if v then _G.AutoFarmLevel = false end
        end
    })

    Tabs.Main:AddToggle("AutoFarmLevel", {
        Title = "📈 Auto Farm Level",
        Default = false,
        Callback = function(v)
            _G.AutoFarmLevel = v
            if v then _G.AutoFarm = false end
            _G.FarmLevelState = "IDLE"
            _G.LastPromptTime = 0
            _G.QuestCompletedTime = 0
            _G.LastQuestMonster = nil
            _G.QuestAccepted = false
        end
    })

    Tabs.Main:AddDropdown("SelectMaterials", {
        Title = "⛏️ Select Materials",
        Description = "Chọn material cần farm",
        Values = MaterialList,
        Default = {},
        Multi = true,
        Callback = function(v)
            local list = {}
            if type(v) == "table" then
                for _, item in ipairs(v) do
                    if type(item) == "string" then table.insert(list, item) end
                end
                if #list == 0 then
                    for key, val in pairs(v) do
                        if val == true and type(key) == "string" then
                            table.insert(list, key)
                        end
                    end
                end
            elseif type(v) == "string" and v ~= "" then
                table.insert(list, v)
            end
            _G.SelectMaterials = list
        end
    })

    Tabs.Main:AddToggle("AutoFarmMaterial", {
        Title = "⛏️ Auto Farm Material",
        Default = false,
        Callback = function(v)
            _G.AutoFarmMaterial = v
            if v and #(_G.SelectMaterials or {}) == 0 then
                Fluent:Notify({ Title = "Cảnh báo", Content = "Chưa chọn Material!", Duration = 3 })
            end
        end
    })
end

if Tabs.Boss then
    Tabs.Boss:AddToggle("AutoBossFull", {
        Title = "👹 Auto Boss (Full)",
        Default = false,
        Callback = function(v) _G.AutoBossFull = v end
    })

    Tabs.Boss:AddDropdown("SelectBoss", {
        Title = "Select Boss (to summon)",
        Values = Bosses,
        Default = false,
        Multi = false,
        Callback = function(v) _G.SelectBoss = v end
    })

    Tabs.Boss:AddToggle("AutoPiccolo", {
        Title = "🐉 Auto Piccolo",
        Default = false,
        Callback = function(v) _G.AutoPiccolo = v end
    })

    Tabs.Boss:AddToggle("AutoDevilBoat", {
        Title = "⛵ Auto Devil Boat",
        Default = false,
        Callback = function(v)
            _G.AutoDevilBoat = v
            if not v then
                CleanupMobAnchor()
                _G.AntiFallDisabled = tick() + 2
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChild("Humanoid")
                if hrp then
                    hrp.Anchored = false
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
                if hum then
                    hum.PlatformStand = false
                    hum.WalkSpeed = 16
                    hum.JumpPower = 50
                end
            end
        end
    })

    Tabs.Boss:AddToggle("AutoKraken", {
        Title = "🐙 Auto Kraken",
        Default = false,
        Callback = function(v) _G.AutoKraken = v end
    })

    Tabs.Boss:AddToggle("AutoThiefChest", {
        Title = "💸 Auto Thief Chest",
        Default = false,
        Callback = function(v) _G.AutoThiefChest = v end
    })

    Tabs.Boss:AddToggle("AutoDuckFull", {
        Title = "🦆 Auto Duck (Full)",
        Default = false,
        Callback = function(v)
            _G.AutoDuckFull = v
            if v then _G.DuckSummonCooldown = 0 end
        end
    })

    Tabs.Boss:AddButton({
        Title = "🔍 Check Boss Spawn",
        Callback = function()
            Fluent:Notify({
                Title = "Boss Spawn Status",
                Content = GetBossSpawnStatus(),
                Duration = 3
            })
        end
    })
end

if Tabs.Random then
    Tabs.Random:AddToggle("AutoRandomEnabled", {
        Title = "💎 Auto Random Chest",
        Default = false,
        Callback = function(v) _G.AutoRandomEnabled = v end
    })
    Tabs.Random:AddDropdown("AutoRandomValue", {
        Title = "🎯 Random Chest Value",
        Values = {"x5", "x10", "x15"},
        Default = "x5",
        Multi = false,
        Callback = function(v) _G.AutoRandomValue = v end
    })
    Tabs.Random:AddToggle("AutoMoonEnabled", {
        Title = "🌙 Auto Moon Chest",
        Default = false,
        Callback = function(v) _G.AutoMoonEnabled = v end
    })
    Tabs.Random:AddDropdown("AutoMoonValue", {
        Title = "🎯 Moon Chest Value",
        Values = {"x5", "x10", "x15"},
        Default = "x5",
        Multi = false,
        Callback = function(v) _G.AutoMoonValue = v end
    })
end

if Tabs.Shop then
    Tabs.Shop:AddSection("💎 Random Chest Shop")

    Tabs.Shop:AddButton({
        Title = "📊 Check PointItem",
        Callback = function()
            local pointItem = tonumber(LocalPlayer:GetAttribute("PointItem")) or 0
            local formatted = tostring(math.floor(pointItem))
            formatted = formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
            Fluent:Notify({ Title = "💎 Random Chest Shop", Content = "PointItem: " .. formatted, Duration = 5 })
        end
    })

    local randomShopDropdown = Tabs.Shop:AddDropdown("RandomShopDropdown", {
        Title = "🎯 Select Item",
        Values = RandomShopList,
        Default = nil,
        Multi = false,
        Callback = function(v) _G.RandomShopItem = v end
    })

    Tabs.Shop:AddToggle("RandomShopAuto", {
        Title = "🤖 Auto Buy (Random Shop)",
        Default = false,
        Callback = function(v)
            if v and not _G.RandomShopItem then
                Fluent:Notify({ Title = "Error", Content = "Please select an item!", Duration = 3 })
                return
            end
            _G.RandomShopAuto = v
        end
    })

    Tabs.Shop:AddSection("🌙 Moon Shop")

    Tabs.Shop:AddButton({
        Title = "📊 Check MoonPoint",
        Callback = function()
            local moonPoint = tonumber(LocalPlayer:GetAttribute("MoonPoint")) or 0
            local formatted = tostring(math.floor(moonPoint))
            formatted = formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
            Fluent:Notify({ Title = "🌙 Moon Shop", Content = "MoonPoint: " .. formatted, Duration = 5 })
        end
    })

    local moonShopDropdown = Tabs.Shop:AddDropdown("MoonShopDropdown", {
        Title = "🎯 Select Item",
        Values = MoonShopList,
        Default = nil,
        Multi = false,
        Callback = function(v) _G.MoonShopItem = v end
    })

    Tabs.Shop:AddButton({
        Title = "🛒 Buy 1 lần (Moon Shop)",
        Callback = function()
            if not _G.MoonShopItem then
                Fluent:Notify({ Title = "Error", Content = "Please select an item!", Duration = 3 })
                return
            end
            local itemName = tostring(_G.MoonShopItem):match("^(.-) /") or _G.MoonShopItem
            itemName = itemName:gsub("^%s+", ""):gsub("%s+$", "")
            if NetworkEvent then
                NetworkEvent:FireServer("fire", nil, "BuyGaranteeEventMoon", itemName)
            end
            Fluent:Notify({ Title = "🛒 Moon Shop", Content = "Purchased: " .. itemName, Duration = 3 })
        end
    })

    Tabs.Shop:AddSection("🏪 Shop Raid")

    Tabs.Shop:AddButton({
        Title = "📊 Check RaidPoint",
        Callback = function()
            local point = GetRaidPoint()
            local formatted = tostring(math.floor(point))
            formatted = formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
            Fluent:Notify({ Title = "🏪 Shop Raid", Content = "RaidPoint: " .. formatted, Duration = 5 })
        end
    })

    local shopRaidDropdown = Tabs.Shop:AddDropdown("ShopRaidDropdown", {
        Title = "🎯 Select Item",
        Values = _G.ShopRaidItemsList or {},
        Default = nil,
        Multi = false,
        Callback = function(v) _G.ShopRaidItem = v end
    })
    _G.ShopRaidDropdown = shopRaidDropdown

    Tabs.Shop:AddToggle("ShopRaidAuto", {
        Title = "🤖 Auto Buy (Shop Raid)",
        Default = false,
        Callback = function(v)
            if v and not _G.ShopRaidItem then
                Fluent:Notify({ Title = "Error", Content = "Please select an item!", Duration = 3 })
                return
            end
            _G.ShopRaidAuto = v
        end
    })

    Tabs.Shop:AddSection("🏪 Shop Dungeon")

    Tabs.Shop:AddButton({
        Title = "📊 Check DungeonPoint",
        Callback = function()
            local point = GetDungeonPoint()
            local formatted = tostring(math.floor(point))
            formatted = formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
            Fluent:Notify({ Title = "🏪 Shop Dungeon", Content = "DungeonPoint: " .. formatted, Duration = 5 })
        end
    })

    local shopDungeonDropdown = Tabs.Shop:AddDropdown("ShopDungeonDropdown", {
        Title = "🎯 Select Item",
        Values = _G.ShopDungeonItemsList or {},
        Default = nil,
        Multi = false,
        Callback = function(v) _G.ShopDungeonItem = v end
    })
    _G.ShopDungeonDropdown = shopDungeonDropdown

    Tabs.Shop:AddToggle("ShopDungeonAuto", {
        Title = "🤖 Auto Buy (Shop Dungeon)",
        Default = false,
        Callback = function(v)
            if v and not _G.ShopDungeonItem then
                Fluent:Notify({ Title = "Error", Content = "Please select an item!", Duration = 3 })
                return
            end
            _G.ShopDungeonAuto = v
        end
    })
end

-- ============================================================
-- 🌙 RAID TAB (cả Sea 1 + Moon)
-- ============================================================
if Tabs.Raid then
    -- 🆕 Auto Raid Moon — LUÔN hiện
    Tabs.Raid:AddSection("🌙 Auto Raid Moon")

    Tabs.Raid:AddParagraph({
        Title = "🌙 Auto Raid Moon",
        Content = "Sea 1: TP tới NPC GoMoon (cần Space Ticket) → vào Moon Map\nMoon Map: farm mob tự động\n\nKhông có Space Ticket → random chest/farm quest"
    })

    Tabs.Raid:AddToggle("AutoRaidMoon", {
        Title = "🌙 Auto Raid Moon",
        Description = "Tự động vào Moon + farm mob",
        Default = false,
        Callback = function(v)
            _G.AutoRaidMoon = v
            print("[Raid Moon]", v and "▶️ ON" or "⏹️ OFF")
        end
    })

    -- 🆕 Chỉ hiện ở Sea 1
    if not IsMoonMap then
        Tabs.Raid:AddSection("🏰 Auto Dungeon")

        Tabs.Raid:AddInput("DungeonAmount", {
            Title = "🔢 Orb Dungeon Count",
            Placeholder = "1",
            Default = "25",
            Numeric = true,
            Finished = false,
            Callback = function(v)
                local n = tonumber(v) or 1
                if n < 1 then n = 1 end
                if n > 999 then n = 999 end
                _G.DungeonAmount = n
            end
        })

        Tabs.Raid:AddToggle("AutoDungeon", {
            Title = "🏰 Auto Raid Dungeon",
            Default = false,
            Callback = function(v)
                _G.AutoDungeon = v
                if v then
                    _G.DungeonState = "IDLE"
                    _G.LastDungeonOpen = 0
                    pcall(function()
                        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                            "fire", nil, "Quest", "Cancel"
                        )
                    end)
                else
                    _G.DungeonState = "IDLE"
                end
            end
        })

        Tabs.Raid:AddSlider("HealthPercent", {
            Title = "❤️ Health Heal %",
            Min = 5, Max = 90, Default = 30, Rounding = 0,
            Callback = function(v) _G.HealthPercent = v end
        })

        Tabs.Raid:AddSlider("DungeonHeight", {
            Title = "📏 Dungeon Height",
            Min = 5, Max = 100, Default = 25, Rounding = 0,
            Callback = function(v) _G.DungeonHeight = v end
        })

        Tabs.Raid:AddSection("⚔️ Auto Raid Boss")

Tabs.Raid:AddDropdown("SelectRaidBoss", {
    Title = "🎯 Chọn Boss Raid",
    Values = {"Bacon of Grudge", "Dragon", "Lava Titan", "??? (Raid 3)"},
    Default = false,
    Multi = false,
    Callback = function(v)
        _G.AutoRaidWho = v
        local Data = RaidBossData and RaidBossData[v]
        if Data then
            Fluent:Notify({
                Title = "⚔️ Raid Boss: " .. Data.Name,
                Content = "Reward: " .. GetBossRewardText(v),
                Duration = 8
            })
        end
    end
})

Tabs.Raid:AddToggle("AutoRaidBoss", {
    Title = "⚔️ Auto Raid Boss",
    Default = false,
    Callback = function(v)
        if v and not _G.AutoRaidWho then
            Fluent:Notify({
                Title = "❌ Lỗi",
                Content = "Chọn Boss trước!",
                Duration = 3
            })
            return
        end

        if _G.AutoRaidWho == "Dragon" then
            _G.AutoRaidDragon = v
            _G.AutoRaidRunning = false
            _G.AutoRaidLava = false
            if v then
                print("[Dragon] 🐉 Auto Raid Dragon ON")
            else
                _G.DragonAlertTriggered = false
                _G.DragonSafeZoneActive = false
                _G.DragonSafeZonePart = nil
                print("[Dragon] 🐉 Auto Raid Dragon OFF")
            end
        elseif _G.AutoRaidWho == "Lava Titan" then
            _G.AutoRaidLava = v
            _G.AutoRaidRunning = false
            _G.AutoRaidDragon = false
            if v then
                pcall(function()
                    NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                end)
                task.wait(0.5)
                print("[LavaTitan] 🌋 Auto Raid Lava Titan ON")
            else
                _G.LavaPortalPhase = "IDLE"
                _G.LavaAlertTriggered = false
                _G.LavaBossOriginPos = nil
                print("[LavaTitan] 🌋 Auto Raid Lava Titan OFF")
            end
        else
            _G.AutoRaidRunning = v
            _G.AutoRaidDragon = false
            _G.AutoRaidLava = false
            if v then
                pcall(function()
                    NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                end)
                print("[Raid] ⚔️ Auto Raid Boss ON: " .. tostring(_G.AutoRaidWho))
            else
                print("[Raid] ⚔️ Auto Raid Boss OFF")
            end
        end
    end
})

-- 🆕 Slider cho Bacon (chỉ ảnh hưởng Bacon)
Tabs.Raid:AddSlider("RaidBallHeight", {
    Title = "🔮 Golden Ball Height",
    Min = 5, Max = 150, Default = 25, Rounding = 0,
    Callback = function(v) _G.RaidBallHeight = v end
})

Tabs.Raid:AddSlider("RaidBaconHeight", {
    Title = "🐷 Bacon Boss Height",
    Min = 5, Max = 200, Default = 55, Rounding = 0,
    Callback = function(v) _G.RaidBaconHeight = v end
})
    end
end

-- ============================================================
-- ⚔️ CRAFT TAB (Sea 1 only)
-- ============================================================
if Tabs.Craft then
    Tabs.Craft:AddSection("🔨 Auto Craft (Items)")

    Tabs.Craft:AddParagraph({
        Title = "🔨 Auto Craft Items",
        Content = "Chế item từ NPC Craft Table (Portal Gun, KFC, ...)\nMở NPC Craft Table để load list."
    })

    local craftDropdown = Tabs.Craft:AddDropdown("CraftSelectItem", {
        Title = "🔨 Chọn Item",
        Description = "Item từ NPC Craft Table",
        Values = CraftItemList,
        Default = nil,
        Multi = false,
        Callback = function(v)
            _G.CraftSelectedItem = v
            if v then print("[Craft] Đã chọn Item: " .. v) end
        end
    })
    _G.CraftDropdown = craftDropdown

    Tabs.Craft:AddToggle("CraftAutoToggle", {
        Title = "🔨 Auto Chế Tạo",
        Default = false,
        Callback = function(v)
            if v and not _G.CraftSelectedItem then
                Fluent:Notify({ Title = "Lỗi", Content = "Chọn vật phẩm trước!", Duration = 3 })
                return
            end
            _G.CraftAutoRunning = v
            _G.CraftLastTime = 0
            _G.CraftPhase = "waiting"
            _G.CraftCountSinceClaim = 0
        end
    })

    Tabs.Craft:AddToggle("AutoClaimGuarantee", {
        Title = "✅ Auto Claim Guarantee",
        Default = true,
        Callback = function(v) _G.AutoClaimGuarantee = v end
    })

    Tabs.Craft:AddButton({
        Title = "📋 Check Chế Được Bao Nhiêu Lần",
        Callback = function()
            if not _G.CraftSelectedItem or _G.CraftSelectedItem == "" then
                Fluent:Notify({ Title = "Lỗi", Content = "Chọn vật phẩm trước!", Duration = 3 })
                return
            end
            if not CraftingTable then
                Fluent:Notify({ Title = "Lỗi", Content = "CraftingTable không load được!", Duration = 3 })
                return
            end
            local Data = CraftingTable[_G.CraftSelectedItem]
            if not Data or not Data.need then
                Fluent:Notify({ Title = "Lỗi", Content = "Không có công thức!", Duration = 3 })
                return
            end

            local inv = GetInventory()
            local maxCraft = math.huge
            local lines = {}
            table.insert(lines, "🔨 Item: " .. _G.CraftSelectedItem)
            table.insert(lines, "━━━━━━━━━━━━━━━")

            for Item, Need in pairs(Data.need) do
                local Have = (inv[Item] and inv[Item].amount) or 0
                local canCraft = (Need > 0) and math.floor(Have / Need) or 0
                if canCraft < maxCraft then maxCraft = canCraft end
                local status = Have >= Need and "✅" or "❌"
                table.insert(lines, string.format("  %s %s: %d/%d", status, Item, Have, Need))
            end

            if maxCraft == math.huge then maxCraft = 0 end
            table.insert(lines, "━━━━━━━━━━━━━━━")
            table.insert(lines, "🎯 Có thể chế: " .. maxCraft .. " lần")

            Fluent:Notify({
                Title = "📋 Recipe: " .. _G.CraftSelectedItem,
                Content = table.concat(lines, "\n"),
                Duration = 10
            })
        end
    })

    Tabs.Craft:AddSection("⚔️ Auto Craft Weapon")

    Tabs.Craft:AddParagraph({
        Title = "⚔️ Auto Craft Weapon",
        Content = "Chế vũ khí (Cid, CidBeta, Sword, Melee, ...)\nChọn vũ khí → Bật Auto → Script tự chế."
    })

    local craftWeaponDropdown = Tabs.Craft:AddDropdown("CraftWeaponSelectItem", {
        Title = "⚔️ Chọn Vũ Khí",
        Description = "Chọn vũ khí cần chế",
        Values = WeaponCraftList,
        Default = nil,
        Multi = false,
        Callback = function(v)
            _G.CraftWeaponSelectedItem = v
            if v then print("[CraftWeapon] Đã chọn: " .. v) end
        end
    })
    _G.CraftWeaponDropdown = craftWeaponDropdown

    Tabs.Craft:AddToggle("AutoCraftWeaponRunning", {
        Title = "⚔️ Auto Craft Weapon (Selected)",
        Default = false,
        Callback = function(v)
            _G.AutoCraftWeaponRunning = v
            _G.AutoCraftWeaponCurrent = nil
            print("[CraftWeapon]", v and "▶️ ON" or "⏹️ OFF")
        end
    })

    Tabs.Craft:AddSection("🌾 Auto Farm Craft Items")

    Tabs.Craft:AddToggle("AutoFarmCraftItems", {
        Title = "🌾 Auto Farm Craft Items",
        Description = "Farm mob drop item cần để chế vũ khí đã chọn",
        Default = false,
        Callback = function(v)
            if v and (not _G.CraftWeaponSelectedItem or _G.CraftWeaponSelectedItem == "") then
                Fluent:Notify({ Title = "Lỗi", Content = "Chọn vũ khí trước!", Duration = 3 })
                return
            end
            _G.AutoFarmCraftItems = v
        end
    })

    Tabs.Craft:AddSection("📋 Check Weapon Recipe")

    Tabs.Craft:AddButton({
        Title = "📋 Check Weapon Recipe",
        Callback = function()
            local weapon = _G.CraftWeaponSelectedItem
            if not weapon or weapon == "" then
                Fluent:Notify({ Title = "Lỗi", Content = "Chọn vũ khí ở dropdown!", Duration = 3 })
                return
            end

            local Data = UseItems and UseItems[weapon]
            if not Data or not Data.Inventory then
                Fluent:Notify({ Title = "Lỗi", Content = "Không có công thức!", Duration = 3 })
                return
            end

            local inv = GetInventory()
            local lines = {}
            local canCraft = true
            local maxCraft = math.huge

            table.insert(lines, "⚔️ Weapon: " .. weapon)
            table.insert(lines, "━━━━━━━━━━━━━━━")

            if Data.NeedClass then
                local playerClass = LocalPlayer:GetAttribute("UseClass")
                local classOK = playerClass == Data.NeedClass
                table.insert(lines, string.format("%s Class: %s",
                    classOK and "✅" or "❌", Data.NeedClass))
                if not classOK then canCraft = false end
            end

            local needBeli = (Data.PlayerData and Data.PlayerData.Beli) or 0
            if needBeli > 0 then
                local haveBeli = tonumber(LocalPlayer:GetAttribute("Beli")) or 0
                local beliOK = haveBeli >= needBeli
                table.insert(lines, string.format("%s Beli: %d/%d",
                    beliOK and "✅" or "❌", haveBeli, needBeli))
                if not beliOK then canCraft = false end
            end

            table.insert(lines, "━━━━━━━━━━━━━━━")
            table.insert(lines, "📋 Nguyên liệu:")

            for Item, Need in pairs(Data.Inventory) do
                local Have = (inv[Item] and inv[Item].amount) or 0
                local itemOK = Have >= Need
                local canCraftItem = math.floor(Have / Need)
                if canCraftItem < maxCraft then maxCraft = canCraftItem end
                table.insert(lines, string.format("  %s %s: %d/%d",
                    itemOK and "✅" or "❌", Item, Have, Need))
                if not itemOK then canCraft = false end
            end

            if maxCraft == math.huge then maxCraft = 0 end
            table.insert(lines, "━━━━━━━━━━━━━━━")
            table.insert(lines, canCraft and "🎯 Có thể chế ngay!" or "🚫 Chưa đủ nguyên liệu")
            table.insert(lines, "📊 Số lần có thể chế: " .. maxCraft)

            Fluent:Notify({
                Title = "📋 Recipe: " .. weapon,
                Content = table.concat(lines, "\n"),
                Duration = 10
            })
        end
    })
    if Tabs.Goku then
    Tabs.Goku:AddSection("🎯 Goku NPC Finder")

    Tabs.Goku:AddParagraph({
        Title = "🎯 Goku NPC (Power God)",
        Content = "Tìm và click NPC Goku/Vegeta/Gohan...\nCần bật Auto → Script tự tìm và click."
    })

    Tabs.Goku:AddToggle("AutoGokuFind", {
        Title = "🎯 Auto Find & Click NPC",
        Description = "Tự động tìm + click NPC",
        Default = false,
        Callback = function(v)
            _G.AutoGokuFind = v
            print("[Goku]", v and "▶️ Find ON" or "⏹️ Find OFF")
        end
    })

    Tabs.Goku:AddToggle("AutoGokuTP", {
        Title = "✈️ Auto TP Nearest NPC",
        Description = "TP tới NPC gần nhất",
        Default = false,
        Callback = function(v)
            _G.AutoGokuTP = v
            print("[Goku]", v and "▶️ TP ON" or "⏹️ TP OFF")
        end
    })

    Tabs.Goku:AddSection("📊 Thông Tin Goku")

Tabs.Goku:AddButton({
    Title = "📊 Check NPC Status",
    Description = "Hiện trạng thái TẤT CẢ NPC (Spawned / Not Spawned)",
    Callback = function()
        -- 🆕 Lấy TẤT CẢ NPC có tên hợp lệ (kể cả chưa spawn)
        local allNPCNames = GokuGetAllNPCs()

        -- 🆕 Lấy NPC đã spawn
        local spawnedNPCs = GokuScanNPCs()
        local spawnedSet = {}
        for _, npc in ipairs(spawnedNPCs) do
            spawnedSet[npc.Name] = true
        end

        local lines = {}
        table.insert(lines, "📊 NPC STATUS")
        table.insert(lines, "━━━━━━━━━━━━━━━")

        if #allNPCNames == 0 then
            -- Không có NPC nào trong workspace
            for i = 1, 5 do
                table.insert(lines, "NPC " .. i .. ": ❌")
            end
        else
            -- 🆕 Hiện TẤT CẢ tên NPC (kể cả chưa spawn)
            for _, name in ipairs(allNPCNames) do
                if spawnedSet[name] then
                    table.insert(lines, name .. ": ✅")
                else
                    table.insert(lines, name .. ": ❌")
                end
            end
        end

        table.insert(lines, "━━━━━━━━━━━━━━━")
        table.insert(lines, "🎯 Session: " .. _G.GokuSessionSpawnedCount .. "/" .. _G.GokuMaxNPCPerSession)

        local content = table.concat(lines, "\n")

        Fluent:Notify({
            Title = "📊 Goku NPC Status",
            Content = content,
            Duration = 10
        })

        print("[Goku] ═══════════════════")
        print(content)
        print("[Goku] ═══════════════════")
    end
})
    end
    -- ============================================================
-- 🆕 TELEPORT TAB
-- ============================================================
if Tabs.Teleport then
    Tabs.Teleport:AddSection("🏝️ Chọn Đảo Sea 1")

    Tabs.Teleport:AddDropdown("TPSelectIsland", {
        Title = "🏝️ Chọn Đảo",
        Description = "Chọn đảo để TP",
        Values = IslandList,
        Default = nil,
        Multi = false,
        Callback = function(v)
            _G.TPSelectedIsland = v
            if v then print("[TP] Đã chọn: " .. v) end
        end
    })

    Tabs.Teleport:AddButton({
        Title = "✈️ Dịch Chuyển Tới Đảo",
        Callback = function()
            if not _G.TPSelectedIsland then
                Fluent:Notify({ Title = "Lỗi", Content = "Chưa chọn đảo!", Duration = 3 })
                return
            end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then
                Fluent:Notify({ Title = "Lỗi", Content = "Character chưa load", Duration = 3 })
                return
            end

            -- Thử TeleportPart trước
            local gates = workspace:FindFirstChild("Gates")
            local tpPart = gates and gates:FindFirstChild("TeleportPart")
            local target = tpPart and tpPart:FindFirstChild(_G.TPSelectedIsland)

            if target then
                hrp.CFrame = CFrame.new(target.Position + Vector3.new(0, 5, 0))
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                Fluent:Notify({ Title = "✈️ TP", Content = "Đã tới: " .. _G.TPSelectedIsland, Duration = 3 })
            else
                local data = IslandCache[_G.TPSelectedIsland]
                if data and data.pos then
                    hrp.CFrame = CFrame.new(data.pos + Vector3.new(0, 5, 0))
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    Fluent:Notify({ Title = "✈️ TP", Content = "Đã tới: " .. _G.TPSelectedIsland, Duration = 3 })
                else
                    Fluent:Notify({ Title = "Lỗi", Content = "Không tìm thấy đảo", Duration = 3 })
                end
            end
        end
    })

    Tabs.Teleport:AddSection("🌊 Sea Travel")

    Tabs.Teleport:AddButton({
        Title = "🌊 Đi Tới Sea 2 (2SeaSoon)",
        Callback = function()
            local seaNPC = workspace:FindFirstChild("2SeaSoon")
            if not seaNPC then
                Fluent:Notify({ Title = "Lỗi", Content = "workspace.2SeaSoon không có", Duration = 3 })
                return
            end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local npcHrp = seaNPC:FindFirstChild("HumanoidRootPart") or seaNPC:FindFirstChildWhichIsA("BasePart")
            if npcHrp then
                hrp.CFrame = CFrame.new(npcHrp.Position + Vector3.new(0, 5, 0))
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                task.wait(0.5)

                local prompt = seaNPC:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then pcall(function() fireproximityprompt(prompt) end) end

                Fluent:Notify({ Title = "🌊 Sea Travel", Content = "Đã tới NPC Sea 2", Duration = 5 })
            end
        end
    })

    Tabs.Teleport:AddButton({
        Title = "🔄 Refresh Island List",
        Callback = function()
            ScanIslands()
            Fluent:Notify({ Title = "TP", Content = "Đã làm mới: " .. #IslandList .. " đảo", Duration = 3 })
        end
    })
        end
	-- ============================================================
-- 🆕 X2 POTION TAB
-- ============================================================
if Tabs.Potion then
    Tabs.Potion:AddSection("🧪 Sử Dụng X2 Potion")

    Tabs.Potion:AddParagraph({
        Title = "🧪 X2 Potion",
        Content = "Chọn loại Potion → Nhập số lượng → Bấm USE\nPotion sẽ được sử dụng ngay lập tức."
    })

    Tabs.Potion:AddDropdown("X2PotionSelect", {
        Title = "🧪 Chọn X2 Potion",
        Description = "Chọn loại Potion",
        Values = X2PotionList,
        Default = nil,
        Multi = false,
        Callback = function(v)
            _G.X2PotionSelected = v
            if v then print("[Potion] Đã chọn: " .. v) end
        end
    })

    Tabs.Potion:AddInput("X2PotionAmount", {
        Title = "🔢 Số lượng (1-100)",
        Description = "Số Potion dùng mỗi lần",
        Placeholder = "1",
        Default = "1",
        Numeric = true,
        Finished = false,
        Callback = function(v)
            local n = tonumber(v) or 1
            if n < 1 then n = 1 end
            if n > 100 then n = 100 end
            _G.X2PotionAmount = n
        end
    })

    Tabs.Potion:AddButton({
        Title = "🧪 USE X2 POTION (1 lần)",
        Description = "Sử dụng Potion đã chọn với số lượng",
        Callback = function()
            local potionName = _G.X2PotionSelected
            local amount = tonumber(_G.X2PotionAmount) or 1

            if amount < 1 then amount = 1 end
            if amount > 100 then amount = 100 end

            if not potionName or potionName == "" then
                Fluent:Notify({
                    Title = "Lỗi",
                    Content = "Chưa chọn Potion!",
                    Duration = 3
                })
                return
            end

            -- Check inventory
            local inv = GetInventory()
            local have = (inv[potionName] and inv[potionName].amount) or 0

            if have <= 0 then
                Fluent:Notify({
                    Title = "Lỗi",
                    Content = "Không có " .. potionName,
                    Duration = 3
                })
                return
            end

            local useCount = math.min(amount, have)

            -- Fire remote
            local remote = ReplicatedStorage:FindFirstChild("Remotes")
            remote = remote and remote:FindFirstChild("Inventory")

            if not remote then
                Fluent:Notify({
                    Title = "Lỗi",
                    Content = "Không tìm thấy Remotes.Inventory",
                    Duration = 3
                })
                return
            end

            task.spawn(function()
                for i = 1, useCount do
                    pcall(function()
                        remote:FireServer(potionName)
                    end)
                    task.wait(0.15)
                end
            end)

            Fluent:Notify({
                Title = "🧪 Đang dùng Potion",
                Content = potionName .. " x" .. useCount .. " (có " .. have .. ")",
                Duration = 4
            })

            print("[Potion] 🧪 Used " .. potionName .. " x" .. useCount)
        end
    })

    Tabs.Potion:AddButton({
        Title = "📊 Check Inventory",
        Callback = function()
            local inv = GetInventory()
            local lines = {}
            table.insert(lines, "🧪 X2 Potions trong Inventory:")

            local found = 0
            for _, name in ipairs(X2PotionList) do
                local have = (inv[name] and inv[name].amount) or 0
                if have > 0 then
                    table.insert(lines, string.format("  • %s: %d", name, have))
                    found = found + 1
                end
            end

            if found == 0 then
                table.insert(lines, "  (không có Potion nào)")
            end

            Fluent:Notify({
                Title = "📊 X2 Potion Inventory",
                Content = table.concat(lines, "\n"),
                Duration = 8
            })
        end
    })
        end
end

-- ============================================================
-- ⚔️ SKILLS TAB
-- ============================================================
if Tabs.Skills then
    Tabs.Skills:AddToggle("SkillZ", { Title = "Auto Skill Z", Default = false,
        Callback = function(v) _G.AutoSkillZ = v end })
    Tabs.Skills:AddToggle("SkillX", { Title = "Auto Skill X", Default = false,
        Callback = function(v) _G.AutoSkillX = v end })
    Tabs.Skills:AddToggle("SkillC", { Title = "Auto Skill C", Default = false,
        Callback = function(v) _G.AutoSkillC = v end })
    Tabs.Skills:AddToggle("SkillV", { Title = "Auto Skill V", Default = false,
        Callback = function(v) _G.AutoSkillV = v end })
    Tabs.Skills:AddToggle("SkillF", { Title = "Auto Skill F", Default = false,
        Callback = function(v) _G.AutoSkillF = v end })
end

-- ============================================================
-- ⚙️ SETTINGS TAB
-- ============================================================
if Tabs.Settings then
    local weaponTypes = {"Melee", "Sword", "Special", "DevilFruit"}
    local weaponSelectedOrder = {}

    Tabs.Settings:AddDropdown("WeaponsCombined", {
        Title = "🗡️ Select Weapons (First = Main)",
        Values = weaponTypes,
        Default = {},
        Multi = true,
        Callback = function(v)
            local selected = {}
            if type(v) == "table" then
                for _, item in ipairs(v) do
                    if type(item) == "string" then selected[item] = true end
                end
                if next(selected) == nil then
                    for key, val in pairs(v) do
                        if val == true and type(key) == "string" then
                            selected[key] = true
                        end
                    end
                end
            elseif type(v) == "string" and v ~= "" then
                selected[v] = true
            end

            local newOrder = {}
            for _, w in ipairs(weaponSelectedOrder) do
                if selected[w] then
                    table.insert(newOrder, w)
                    selected[w] = nil
                end
            end
            for _, w in ipairs(weaponTypes) do
                if selected[w] then
                    table.insert(newOrder, w)
                end
            end

            weaponSelectedOrder = newOrder
            _G.WeaponOrder = newOrder

            if #newOrder > 0 then
                _G.MainWeapon = newOrder[1]
                local supports = {}
                for i = 2, #newOrder do
                    table.insert(supports, newOrder[i])
                end
                _G.SupportWeapons = supports
            else
                _G.MainWeapon = nil
                _G.SupportWeapons = {}
            end
        end
    })

    Tabs.Settings:AddDropdown("Method", {
        Title = "🎯 Farm Position",
        Values = {"Upper", "Below", "Behind", "Front"},
        Default = "Upper",
        Multi = false,
        Callback = function(v)
            _G.Select_Method = v
            UpdateMethodFarm()
        end
    })

    Tabs.Settings:AddSlider("Distance", {
        Title = "Distance",
        Min = 0, Max = 30, Default = 5, Rounding = 0,
        Callback = function(v)
            _G.Distance_Farm = v
            UpdateMethodFarm()
        end
    })
	
	Tabs.Settings:AddSection("🗡️ Weapon & Tools")

    Tabs.Settings:AddToggle("EnableEquipWeapon", {
    Title = "🗡️ Auto Equip Weapon",
    Description = "Tự động trang bị vũ khí đã chọn",
    Default = false,
    Callback = function(v)
        _G.EnableEquipWeapon = v
        if not v then
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end
                for _, tool in ipairs(char:GetChildren()) do
                    if tool:IsA("Tool") then
                        tool.Parent = LocalPlayer.Backpack
                    end
                end
            end)
        end
        print("[Settings] Auto Equip Weapon:", v and "ON" or "OFF")
    end
})

    Tabs.Settings:AddSection("👁️ Haki & VFX")

    Tabs.Settings:AddToggle("AutoHaki", {
        Title = "👁️ Auto Haki",
        Default = false,
        Callback = function(v) _G.AutoHaki = v end
    })

    Tabs.Settings:AddToggle("DisableVFX", {
        Title = "✨ Disable VFX",
        Default = false,
        Callback = function(v)
            _G.DisableVFX = v
            ApplyVFX(v)
        end
    })

    Tabs.Settings:AddDropdown("MenuToggleKey", {
        Title = "⌨️ Menu Toggle Key",
        Values = {
            "RightControl", "LeftControl", "RightShift", "LeftShift",
            "RightAlt", "LeftAlt", "Tab", "CapsLock",
            "F1", "F2", "F3", "F4", "F5",
            "Insert", "Delete", "Home", "End", "PageUp", "PageDown",
        },
        Default = "RightControl",
        Multi = false,
        Callback = function(v)
            local keyMap = {
                ["RightControl"] = Enum.KeyCode.RightControl,
                ["LeftControl"]  = Enum.KeyCode.LeftControl,
                ["RightShift"]   = Enum.KeyCode.RightShift,
                ["LeftShift"]    = Enum.KeyCode.LeftShift,
                ["RightAlt"]     = Enum.KeyCode.RightAlt,
                ["LeftAlt"]      = Enum.KeyCode.LeftAlt,
                ["Tab"]          = Enum.KeyCode.Tab,
                ["CapsLock"]     = Enum.KeyCode.CapsLock,
                ["F1"]           = Enum.KeyCode.F1,
                ["F2"]           = Enum.KeyCode.F2,
                ["F3"]           = Enum.KeyCode.F3,
                ["F4"]           = Enum.KeyCode.F4,
                ["F5"]           = Enum.KeyCode.F5,
                ["Insert"]       = Enum.KeyCode.Insert,
                ["Delete"]       = Enum.KeyCode.Delete,
                ["Home"]         = Enum.KeyCode.Home,
                ["End"]          = Enum.KeyCode.End,
                ["PageUp"]       = Enum.KeyCode.PageUp,
                ["PageDown"]     = Enum.KeyCode.PageDown,
            }
            local keyCode = keyMap[v]
            if keyCode then
                ChangeMenuKey(keyCode)
                Fluent:Notify({
                    Title = "⌨️ Menu Key",
                    Content = "Đã đổi thành: " .. v,
                    Duration = 3
                })
            end
        end
    })
end

-- ============================================================
-- CONFIG TAB
-- ============================================================
if Tabs.Config then
    SaveManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})
    SaveManager:SetFolder("MarvenRizHub/RockFruit")
    SaveManager:BuildConfigSection(Tabs.Config)
    SaveManager:LoadAutoloadConfig()
end

-- ============================================================
-- CLEANUP LOOPS
-- ============================================================
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            local anyActive = _G.AutoFarm or _G.AutoFarmLevel
                or _G.AutoBossFull or _G.AutoPiccolo or _G.AutoDevilBoat
                or _G.AutoKraken or _G.AutoDuckFull or _G.AutoThiefChest
                or _G.AutoRaidMoon
            if not anyActive then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, child in ipairs(hrp:GetChildren()) do
                        if child.Name == "MobAnchorBP"
                           or child.Name == "QuestNPCHover" then
                            pcall(function() child:Destroy() end)
                        end
                    end
                end
            end
        end)
    end
end)

_G.WasAutoActive = false

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local anyActive = _G.AutoFarm or _G.AutoFarmLevel
                or _G.AutoBossFull or _G.AutoPiccolo or _G.AutoDevilBoat
                or _G.AutoKraken or _G.AutoDuckFull or _G.AutoThiefChest
                or _G.AutoRaidMoon
            if _G.WasAutoActive and not anyActive then
                _G.WasAutoActive = false
                CleanupMobAnchor()
                ClearQuestHover()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
                print("[Cleanup] ✅ Đã cleanup (auto OFF)")
            end
            if anyActive then _G.WasAutoActive = true end
        end)
    end
end)

task.spawn(function()
    while task.wait(3) do
        pcall(function()
            local anyActive = _G.AutoFarm or _G.AutoFarmLevel
                or _G.AutoBossFull or _G.AutoPiccolo or _G.AutoDevilBoat
                or _G.AutoKraken or _G.AutoDuckFull or _G.AutoThiefChest
                or _G.AutoRaidMoon
            if anyActive then return end
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if not hum then return end
            local state = hum:GetState()
            if state == Enum.HumanoidStateType.PlatformStanding
               or state == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                hum.PlatformStand = false
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(1.0) do
        pcall(function()
            if tick() < _G.AntiFallDisabled then return end
            local anyActive = _G.AutoFarm or _G.AutoFarmLevel
                or _G.AutoBossFull or _G.AutoPiccolo or _G.AutoDevilBoat
                or _G.AutoKraken or _G.AutoDuckFull or _G.AutoThiefChest
                or _G.AutoRaidMoon
            if not anyActive then return end
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                local state = hum:GetState()
                if state == Enum.HumanoidStateType.Jumping
                   or state == Enum.HumanoidStateType.Freefall
                   or state == Enum.HumanoidStateType.FallingDown then
                    return
                end
            end
            if hrp.Position.Y < -100 then
                if tick() - _G.LastAntiFallTime > 3 then
                    _G.LastAntiFallTime = tick()
                    hrp.CFrame = CFrame.new(hrp.Position.X, 50, hrp.Position.Z)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end)
    end
end)

-- ============================================================
-- ANTI IDLE
-- ============================================================
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

task.spawn(function()
    task.wait(1)
    ChangeMenuKey(_G.MenuToggleKey or Enum.KeyCode.LeftControl)
end)

Fluent:Notify({
    Title = "MarvenRiz Hub",
    Content = "✅ v72 loaded! " .. (IsMoonMap and "🌙 Moon" or "🌊 Sea 1") .. " — " .. #Quest_List .. " quests",
    Duration = 5
})

print("[MarvenRiz] ✅ v72 loaded! Map: " .. (IsMoonMap and "Moon" or "Sea 1"))
