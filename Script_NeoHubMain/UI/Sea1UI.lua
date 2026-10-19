-- UI/Sea1UI.lua
-- Toàn bộ UI Sea 1 — tách gọn, reference _G flags + Data

local Services = require(script.Parent.Parent.Core.Services)
local Helpers  = require(script.Parent.Parent.Core.Helpers)
local Config   = require(script.Parent.Parent.Core.Config)

local LocalPlayer = Services.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage
local HttpService = Services.HttpService

local Window = _G.Window
local Data   = _G.Data

local GetInventory = Helpers.GetInventory
local GetItemAmount = Helpers.GetItemAmount
local FormatNumber = Helpers.FormatNumber

-- ============================================================
-- TAB 1: SETTINGS
-- ============================================================
local Tab1       = Window:CreateTab("Settings", true, false)
local Tab_Page1  = Tab1:CreatePage("Main Settings")
local Weapon     = Tab_Page1:CreateSection("🗡️ Select Weapon", "Left")
local AutoSkills = Tab_Page1:CreateSection("⚔️ Auto Skills", "Left")
local Method     = Tab_Page1:CreateSection("🎯 Select Method Farm", "Right")
local HakiSect   = Tab_Page1:CreateSection("👁️ Haki", "Right")
local VFX        = Tab_Page1:CreateSection("✨ VFX", "Right")
local Tab_Page2  = Tab1:CreatePage("Other Settings")
local Accessory  = Tab_Page2:CreateSection("🎒 Accessory & Rebirth", "Right")
local Potion     = Tab_Page2:CreateSection("🧪 Auto Use X2 Potion", "Left")

Weapon:Dropdown({
    Title = "Main Weapon (Attack)", Options = Config.TypeTool,
    Multi = false, Value = "Melee",
    Callback = function(v) _G.MainWeapon = v end
})
Weapon:Dropdown({
    Title = "Select Support Weapon", Options = Config.TypeTool,
    Multi = true,
    Callback = function(v) _G.Select_EquipWeapon = v end
})

AutoSkills:Toggle({Title = "Auto Skill Z", Id = "SKILLZ", Value = false, Callback = function(v) _G.AutoSkillZ = v end})
AutoSkills:Toggle({Title = "Auto Skill X", Id = "SKILLX", Value = false, Callback = function(v) _G.AutoSkillX = v end})
AutoSkills:Toggle({Title = "Auto Skill C", Id = "SKILLC", Value = false, Callback = function(v) _G.AutoSkillC = v end})
AutoSkills:Toggle({Title = "Auto Skill V", Id = "SKILLV", Value = false, Callback = function(v) _G.AutoSkillV = v end})
AutoSkills:Toggle({Title = "Auto Skill F", Id = "SKILLF", Value = false, Callback = function(v) _G.AutoSkillF = v end})
HakiSect:Toggle({Title = "Auto Enable Haki", Id = "AENHAKI", Value = false, Callback = function(v) _G.Auto_Haki = v end})

Method:Dropdown({
    Title = "Select Farm Method",
    Options = {"Behind", "Below", "Upper", "Front"},
    Id = "SELEMETHODFARM",
    Multi = false, Value = "Upper",
    Callback = function(v) _G.Select_Method = v end
})
Method:Slider({
    Title = "Farm Distance", Min = 0, Max = 30, Value = 5,
    Callback = function(v) _G.Distance_Farm = v end
})
VFX:Toggle({Title = "Disable VFX", Value = false, Callback = function(v) _G.NoVFX(v) end})

Accessory:Toggle({
    Title = "Auto Equip Best Accessory", Value = false,
    Callback = function(v) _G.Auto_Equip_Accessory = v end
})
Accessory:Toggle({
    Title = "Auto Rebirth (Max Level)", Value = false,
    Callback = function(v) _G.Auto_Rebirth = v end
})

-- Potion
Potion:Dropdown({
    Title = "🧪 Select X2 Potion",
    Options = Data.X2List,
    Multi = true,
    Callback = function(v)
        local list = {}
        if type(v) == "table" then
            for k, val in pairs(v) do
                if val == true and type(k) == "string" then table.insert(list, k)
                elseif type(val) == "string" then table.insert(list, val) end
            end
        elseif type(v) == "string" then
            table.insert(list, v)
        end
        _G.Select_Potion = list
    end
})
Potion:Toggle({
    Title = "🤖 Auto Use Potion", Value = false,
    Callback = function(v) _G.Auto_Use_Potion = v end
})

-- ============================================================
-- TAB 2: MAIN
-- ============================================================
local Tab2            = Window:CreateTab("Main", false, false)
local Farm            = Tab2:CreatePage("Farm")
local AllBoss         = Tab2:CreatePage("Boss")
local RaidBossPage    = Tab2:CreatePage("Raid Boss & Shop")
local RaidDun         = Tab2:CreatePage("Dungeon, Shop / Weapon")

local AutoFarmCard    = Farm:CreateSection("🌾 Auto Farm", "Left")
local MaterialCard    = Farm:CreateSection("⛏️ Auto Farm Material", "Right")
local Boss            = AllBoss:CreateSection("👹 Boss", "Left")
local Thief           = AllBoss:CreateSection("💸 Thief", "Left")
local Piccolo         = AllBoss:CreateSection("🐉 Piccolo", "Left")
local SpawnedT        = AllBoss:CreateSection("🔍 Spawned Check", "Right")
local Duck            = AllBoss:CreateSection("🦆 Duck", "Right")
local DevilBoat       = AllBoss:CreateSection("⛵ Devil Boat", "Right")
local Kraken          = AllBoss:CreateSection("🐙 Kraken","Left")
local ALLBOSS         = AllBoss:CreateSection("🔴 All Boss","Right")

local DungeonCard     = RaidDun:CreateSection("🏰 Auto Dungeon", "Left")
local ShopDunCard     = RaidDun:CreateSection("🏪 Shop Dungeon", "Left")
local WeaponCraft     = RaidDun:CreateSection("🔨 Weapon", "Left")
local DungeonSettingsCard = RaidDun:CreateSection("⚙️ Dungeon Settings", "Right")
local ShopDunInfoCard = RaidDun:CreateSection("📊 Shop Dungeon Info", "Right")
local RaidCard        = RaidDun:CreateSection("🌋 Auto Raid Moon", "Right")

local RaidBossCard    = RaidBossPage:CreateSection("⚔️ Auto Raid Boss", "Left")
local RaidBossInfoCard= RaidBossPage:CreateSection("📋 Raid Info", "Right")
local ShopRaidCard    = RaidBossPage:CreateSection("🏪 Shop Raid", "Left")
local ShopRaidInfoCard= RaidBossPage:CreateSection("📊 Shop Info", "Right")
local RaidSettingsCard= RaidBossPage:CreateSection("⚙️ Raid Settings", "Right")
local TimeMysteryCard = RaidBossPage:CreateSection("🎁 Mystery Box", "Left")

-- Auto Farm Level
AutoFarmCard:Toggle({
    Title = "Auto Level Farm", Value = false,
    Callback = function(v)
        _G.Auto_Farm_Level = v
        if v then
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
        end
    end
})

-- Material
MaterialCard:Dropdown({
    Title = "Select Farm Material",
    Options = Data.ItemAll,
    Multi = true,
    Callback = function(v)
        local list = {}
        if type(v) == "table" then
            for _, item in pairs(v) do
                if type(item) == "string" then table.insert(list, item) end
            end
        elseif type(v) == "string" then table.insert(list, v) end
        _G.Select_Material = list
    end
})
MaterialCard:Toggle({
    Title = "Auto Farm Material", Value = false,
    Callback = function(v) _G.Auto_Farm_Material = v end
})

-- Boss
Boss:Dropdown({
    Title = "Select Boss", Options = Data.Bosses, Multi = false,
    Callback = function(v) _G.Select_Boss = v end
})
Boss:Toggle({Title = "Auto Farm All Boss (Full)", Value = false, Callback = function(v) _G.Auto_FarmBoss = v end})
Thief:Toggle({Title = "Auto Farm Thief Chest", Value = false, Callback = function(v) _G.Auto_BaconThief = v end})
Piccolo:Toggle({Title = "Auto Farm Piccolo", Value = false, Callback = function(v) _G.Auto_Piccolo = v end})
Duck:Toggle({
    Title = "Auto Farm Duck (Full)", Value = false,
    Callback = function(v)
        _G.Auto_DuckAutomatically = v
        if v then ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel") end
    end
})
DevilBoat:Toggle({Title = "Auto Farm Devil Boat", Value = false, Callback = function(v) _G.Auto_DevilBoat = v end})
Kraken:Toggle({Title = "Auto Farm Kraken", Value = false, Callback = function(v) _G.Auto_Kraken = v end})
ALLBOSS:Toggle({
    Title = "👹 Auto Boss All",
    Desc = "Auto: Piccolo, Devil Boat, Thief, Kraken",
    Value = false,
    Callback = function(v)
        _G.AutoBossAll = v
        if v then ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel") end
    end
})

local Spawn_Status = SpawnedT:Paragraph({Title = "Spawn Status", Content = "N/A"})
local Item_Auto    = WeaponCraft:Paragraph({Title = "Item Requirements ( None )", Content = "N/A"})

WeaponCraft:Dropdown({
    Title = "Select Weapon Craft", Options = Data.WeaponAll, Multi = false,
    Callback = function(v) _G.Select_Item = v end
})
WeaponCraft:Button({
    Title = "Craft Weapon",
    Callback = function()
        local d = Data.UseItems and Data.UseItems[_G.Select_Item]
        if d then
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                "fire", nil, "Craft", _G.Select_Item, d.Type)
        end
    end
})
WeaponCraft:Toggle({
    Title = "Auto Craft Weapon (Full)", Value = false,
    Callback = function(v) _G.Auto_CraftWeapon = v end
})
WeaponCraft:Toggle({
    Title = "Auto Farm Set Weapon", Value = false,
    Callback = function(v) _G.Auto_Farm_Set = v end
})

RaidCard:Toggle({
    Title = "Auto Raid Moon (Full)", Value = false,
    Callback = function(v)
        _G.Auto_Raid = v
        if v then ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel") end
    end
})

DungeonCard:Textbox({
    Title = "Dungeon Orb to Use", Id = "DUNOTOUSE", Placeholder = "...",
    Callback = function(v) _G.Dungeon_UseValue = tonumber(v) or 1 end
})
DungeonSettingsCard:Slider({
    Title = "Health Return %", Min = 1, Max = 100, Value = 30,
    Callback = function(v) _G.HealthPercent = v end
})
DungeonSettingsCard:Slider({
    Title = "Dungeon Height", Min = 0, Max = 100, Value = 25,
    Callback = function(v) _G.DungeonHeight = v end
})
DungeonCard:Toggle({
    Title = "🏰 Auto Dungeon (Full)", Value = false,
    Callback = function(v)
        _G.Auto_Dungeon = v
        if v then
            pcall(function()
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
            end)
        end
    end
})

-- ============================================================
-- RAID BOSS UI
-- ============================================================
local RaidBossData = {
    ["Bacon of Grudge"] = {Name = "Bacon of Grudge", Reward = "Time Mystery Box x5, 7500 Diamond, Beli 50M, x3 Potion", PortalCost = 1, Valid = true},
    ["Dragon"]          = {Name = "Dragon", Reward = "Thunder Mystery Box x5, 15k Diamond, Beli 100M, x3 Potion", PortalCost = 0, Valid = true},
    ["Lava Titan"]      = {Name = "Lava Titan", Reward = "Lava Mystery Box x5, 20k Diamond, Beli 200M, x3 Potion", PortalCost = 1, Valid = true, OffsetY = 25},
}

local RaidBossInfoPara = RaidBossInfoCard:Paragraph({
    Title = "Name: ( not selected )",
    Content = "Please choose a Boss Raid!!",
    TitleSize = 18, ContentSize = 16, TextSize = 16,
})

RaidBossCard:Dropdown({
    Title = "Choose a boss to raid",
    Options = {"Bacon of Grudge", "Dragon", "Lava Titan", "??? (Raid4)"},
    Multi = false,
    Callback = function(v)
        _G.AutoRaidWho = v
        local d = RaidBossData[v]
        if d then
            RaidBossInfoPara:SetTitle("Name: " .. d.Name)
            RaidBossInfoPara:SetContent("Reward: " .. d.Reward .. "\n- " .. d.PortalCost .. " Portal Gun")
        end
    end
})
RaidBossCard:Button({
    Title = "Start Raid Now!!",
    Callback = function()
        local d = RaidBossData[_G.AutoRaidWho]
        if not d then
            _G.SeaNotify("❌ Raid not selected", "Please choose a Boss Raid!", 3); return
        end
        if not d.Valid then
            _G.SeaNotify("❌ Invalid Raid", "NO RAID!!!", 3); return
        end

        if _G.AutoRaidWho == "Dragon" then
            if _G.AutoRaidRunning then _G.AutoRaidRunning = false end
            if _G.AutoRaidLava then _G.AutoRaidLava = false end
            _G.AutoRaidDragon = not _G.AutoRaidDragon
            _G.SeaNotify(_G.AutoRaidDragon and "▶️ Start Dragon Raid" or "⏹️ Stop Dragon Raid", "Dragon", 3)
            return
        end
        if _G.AutoRaidWho == "Lava Titan" then
            if _G.AutoRaidRunning then _G.AutoRaidRunning = false end
            if _G.AutoRaidDragon then _G.AutoRaidDragon = false end
            _G.AutoRaidLava = not _G.AutoRaidLava
            _G.SeaNotify(_G.AutoRaidLava and "▶️ Start Lava Raid" or "⏹️ Stop Lava Raid", "Lava Titan", 3)
            return
        end
        if _G.AutoRaidDragon then _G.AutoRaidDragon = false end
        if _G.AutoRaidLava then _G.AutoRaidLava = false end
        _G.AutoRaidRunning = not _G.AutoRaidRunning
        _G.SeaNotify(_G.AutoRaidRunning and "▶️ Start Raid" or "⏹️ Stop Raid", d.Name, 3)
    end
})
RaidSettingsCard:Slider({
    Title = "Bacon of Grudge Height", Min = 0, Max = 150, Value = 55,
    Callback = function(v) _G.RaidBossOffsetY = v end
})
RaidSettingsCard:Slider({
    Title = "Golden Ball Height", Min = 0, Max = 150, Value = 25,
    Callback = function(v) _G.RaidBallOffsetY = v end
})

-- ============================================================
-- TAB 3: OTHER
-- ============================================================
local Tab3            = Window:CreateTab("Other", false, false)
local RandomM         = Tab3:CreatePage("Random Chest")
local CraftTablePage  = Tab3:CreatePage("Craft Table")
local GokuPage        = Tab3:CreatePage("Npc Goku Gods")

-- Random Chest
local DiamondChest     = RandomM:CreateSection("💎 Diamond Chest", "Right")
local MoonChest        = RandomM:CreateSection("🌙 Moon Chest", "Left")
local GuaranteeDiamond = RandomM:CreateSection("🎖️ Guarantee Gem Point", "Right")
local GuaranteeMoon    = RandomM:CreateSection("☄️ Guarantee Moon Point", "Left")

local DiamondChestInfo = DiamondChest:Paragraph({Title = "💎 Diamond: ---", Content = "📊 PointItem: ---"})
DiamondChest:Dropdown({
    Title = "Select Random Diamond Chest", Options = Config.RandomChestValue,
    Multi = false, Value = "x5",
    Callback = function(v) _G.Select_Random = type(v) == "table" and (next(v) or "x5") or v end
})
DiamondChest:Button({
    Title = "🎲 Open once (Random Item)",
    Callback = function()
        local v = _G.Select_Random or "x5"
        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "RandomItem", v)
        _G.SeaNotify("🎲 Opened", "RandomItem: " .. v, 2)
    end
})
DiamondChest:Toggle({
    Title = "Auto Random Diamond Chest", Value = false,
    Callback = function(v) _G.Auto_RandomChest = v end
})

local MoonChestInfo = MoonChest:Paragraph({Title = "🌙 MoonStone: ---", Content = "📊 MoonPoint: ---"})
MoonChest:Dropdown({
    Title = "Select Random Moon Chest", Options = Config.RandomChestValue,
    Multi = false, Value = "x5",
    Callback = function(v) _G.Select_Random_Moon = type(v) == "table" and (next(v) or "x5") or v end
})
MoonChest:Button({
    Title = "🌙 Open once (Event Moon)",
    Callback = function()
        local v = _G.Select_Random_Moon or "x5"
        local costMap = {["x5"] = 25, ["x10"] = 50, ["x15"] = 75}
        local cost = costMap[v] or 25
        local moonStone = tonumber(LocalPlayer:GetAttribute("MoonStone")) or 0
        if moonStone < cost then
            _G.SeaNotify("❌ Not enough", "Need " .. cost .. ", have " .. FormatNumber(moonStone), 3); return
        end
        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "EventMoon", v)
        _G.SeaNotify("🌙 Opened", "EventMoon: " .. v, 2)
    end
})
MoonChest:Toggle({
    Title = "Auto Random Moon Chest", Value = false,
    Callback = function(v) _G.Auto_RandomChest_Moon = v end
})

local GuaranteeDiamondInfo = GuaranteeDiamond:Paragraph({Title = "💎 Diamond: ---", Content = "📊 PointItem: ---"})
local GuaranteeDiamondSelectInfo = GuaranteeDiamond:Paragraph({Title = "Item: (not selected)", Content = "Price: ---"})

GuaranteeDiamond:Dropdown({
    Title = "Select Guarantee Diamond Point", Options = Data.Poitem,
    Multi = false,
    Callback = function(v)
        local val = type(v) == "table" and (next(v) or "") or v
        if type(val) ~= "string" then val = "" end
        _G.Select_Guarantee = val:match("^(.-) /") or val
    end
})
GuaranteeDiamond:Button({
    Title = "💎 BUY once",
    Callback = function()
        local item = _G.Select_Guarantee
        if not item or item == "" then _G.SeaNotify("❌ No item selected", "", 3); return end
        item = item:match("^(.-) /") or item
        item = item:gsub("^%s+", ""):gsub("%s+$", "")
        local pointItem = tonumber(LocalPlayer:GetAttribute("PointItem")) or 0
        local price = (Data.PointItemM and Data.PointItemM[item]) or 0
        if price <= 0 then _G.SeaNotify("❌ Not found", item, 3); return end
        if pointItem < price then
            _G.SeaNotify("❌ Not enough", "Need " .. FormatNumber(price), 3); return
        end
        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
            "fire", nil, "BuyGaranteeRandomItem", item)
        _G.SeaNotify("✅ Purchased", item, 3)
    end
})
GuaranteeDiamond:Toggle({
    Title = "Auto Buy Guarantee Diamond", Value = false,
    Callback = function(v) _G.Auto_Guarantee = v end
})

local GuaranteeMoonInfo = GuaranteeMoon:Paragraph({Title = "🌙 MoonPoint: ---", Content = "💠 MoonStone: ---"})
local GuaranteeMoonSelectInfo = GuaranteeMoon:Paragraph({Title = "🌙 Item: (not selected)", Content = "Price: ---"})

GuaranteeMoon:Dropdown({
    Title = "Select Guarantee Moon Point", Options = Data.PoiteMoon,
    Multi = false,
    Callback = function(v)
        local val = type(v) == "table" and (next(v) or "") or v
        if type(val) ~= "string" then val = "" end
        _G.Select_Guarantee_Moon = val:match("^(.-) /") or val
    end
})
GuaranteeMoon:Button({
    Title = "🌙 BUY once",
    Callback = function()
        local item = _G.Select_Guarantee_Moon
        if not item or item == "" then _G.SeaNotify("❌ No item selected", "", 3); return end
        item = item:match("^(.-) /") or item
        item = item:gsub("^%s+", ""):gsub("%s+$", "")
        local moonPoint = tonumber(LocalPlayer:GetAttribute("MoonPoint")) or 0
        local price = (Data.PointItemMoon and Data.PointItemMoon[item]) or 0
        if price <= 0 then _G.SeaNotify("❌ Not found", item, 3); return end
        if moonPoint < price then _G.SeaNotify("❌ Not enough", "Need " .. FormatNumber(price), 3); return end
        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
            "fire", nil, "BuyGaranteeEventMoon", item)
        _G.SeaNotify("✅ Purchased", item, 3)
    end
})
GuaranteeMoon:Toggle({
    Title = "Auto Buy Guarantee Moon", Value = false,
    Callback = function(v) _G.Auto_Guarantee_Moon = v end
})

-- Update info loop
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local diamond   = tonumber(LocalPlayer:GetAttribute("Diamond")) or 0
            local pointItem = tonumber(LocalPlayer:GetAttribute("PointItem")) or 0
            local moonStone = tonumber(LocalPlayer:GetAttribute("MoonStone")) or 0
            local moonPoint = tonumber(LocalPlayer:GetAttribute("MoonPoint")) or 0

            DiamondChestInfo:SetTitle("💎 Diamond: " .. FormatNumber(diamond))
            DiamondChestInfo:SetContent("📊 PointItem: " .. FormatNumber(pointItem))
            MoonChestInfo:SetTitle("🌙 MoonStone: " .. FormatNumber(moonStone))
            MoonChestInfo:SetContent("📊 MoonPoint: " .. FormatNumber(moonPoint))
            GuaranteeDiamondInfo:SetTitle("💎 Diamond: " .. FormatNumber(diamond))
            GuaranteeDiamondInfo:SetContent("📊 PointItem: " .. FormatNumber(pointItem))
            GuaranteeMoonInfo:SetTitle("🌙 MoonPoint: " .. FormatNumber(moonPoint))
            GuaranteeMoonInfo:SetContent("💠 MoonStone: " .. FormatNumber(moonStone))

            if _G.Select_Guarantee and _G.Select_Guarantee ~= "" then
                local n = _G.Select_Guarantee:match("^(.-) /") or _G.Select_Guarantee
                n = n:gsub("^%s+", ""):gsub("%s+$", "")
                local p = (Data.PointItemM and Data.PointItemM[n]) or 0
                GuaranteeDiamondSelectInfo:SetTitle("🎯 " .. n)
                GuaranteeDiamondSelectInfo:SetContent("Price: " .. FormatNumber(p))
            end
            if _G.Select_Guarantee_Moon and _G.Select_Guarantee_Moon ~= "" then
                local n = _G.Select_Guarantee_Moon:match("^(.-) /") or _G.Select_Guarantee_Moon
                n = n:gsub("^%s+", ""):gsub("%s+$", "")
                local p = (Data.PointItemMoon and Data.PointItemMoon[n]) or 0
                GuaranteeMoonSelectInfo:SetTitle("🌙 " .. n)
                GuaranteeMoonSelectInfo:SetContent("Price: " .. FormatNumber(p))
            end
        end)
    end
end)

-- Mystery box (chỉ UI, logic ở Items/CraftTable.lua hoặc riêng)
-- Lưu ý: UI này đã có logic trong Shop/MysteryBox.lua, ở đây chỉ reference
local MysteryBoxInfo = TimeMysteryCard:Paragraph({Title = "🎁 Mystery Box: ---", Content = "Select the box below"})
local MysteryBoxList = {"Time Mystery Box", "Thunder Mystery Box", "Lava Mystery Box"}
_G.MysteryBoxSelected  = "Time Mystery Box"
_G.MysteryBoxAmount    = 1
_G.MysteryBoxAuto      = false
_G.MysteryBoxAutoDelay = 0.5

TimeMysteryCard:Dropdown({
    Title = "🎁 Select Mystery Box", Options = MysteryBoxList,
    Multi = false, Value = "Time Mystery Box",
    Callback = function(v)
        local val = type(v) == "table" and (next(v) or "Time Mystery Box") or v
        if not table.find(MysteryBoxList, val) then val = "Time Mystery Box" end
        _G.MysteryBoxSelected = val
    end
})
TimeMysteryCard:Textbox({
    Title = "Open Amount (1-100)", Placeholder = "1", Value = "1",
    Callback = function(v)
        local n = tonumber(v) or 1
        if n < 1 then n = 1 end
        if n > 100 then n = 100 end
        _G.MysteryBoxAmount = n
    end
})
TimeMysteryCard:Button({
    Title = "🎁 OPEN (once)",
    Callback = function()
        local box = _G.MysteryBoxSelected or "Time Mystery Box"
        local amt = tonumber(_G.MysteryBoxAmount) or 1
        if amt < 1 then amt = 1 end
        if amt > 100 then amt = 100 end
        local have = GetItemAmount(box)
        if have <= 0 then _G.SeaNotify("❌ No Box", box, 3); return end
        local useCount = math.min(amt, have)
        pcall(function()
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, box, useCount)
        end)
        _G.SeaNotify("🎁 Opening", box .. " x" .. useCount, 3)
    end
})
TimeMysteryCard:Toggle({
    Title = "🤖 Auto Open Box", Value = false,
    Callback = function(v) _G.MysteryBoxAuto = v end
})

-- ============================================================
-- TAB 4: TELEPORT
-- ============================================================
local TabTP    = Window:CreateTab("Teleport", false, false)
local TPPage   = TabTP:CreatePage("Teleport Sea 1")
local IslandCard = TPPage:CreateSection("🏝️ Sea 1 Islands", "Left")
local SeaCard    = TPPage:CreateSection("🌊 Sea Travel", "Right")
local TPInfoCard = TPPage:CreateSection("📊 Information", "Right")

local IslandCache    = {}
local IslandList     = {}
local SelectedIsland = nil

local TPInfoPara = TPInfoCard:Paragraph({Title = "Sea 1", Content = "Loading..."})

local function ScanIslands()
    IslandCache = {}
    IslandList  = {}
    local folder = workspace:FindFirstChild("island")
    if not folder then return end
    local orderMap = {}
    local gates = workspace:FindFirstChild("Gates")
    local tpPart = gates and gates:FindFirstChild("TeleportPart")
    if tpPart then
        for i, part in ipairs(tpPart:GetChildren()) do
            if part:IsA("BasePart") then orderMap[part.Name] = i end
        end
    end
    local temp = {}
    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("Model") then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
                or obj.PrimaryPart
                or obj:FindFirstChildWhichIsA("BasePart")
            IslandCache[obj.Name] = {model = obj, pos = hrp and hrp.Position or Vector3.zero}
            table.insert(temp, obj.Name)
        end
    end
    table.sort(temp, function(a, b)
        local ia, ib = orderMap[a], orderMap[b]
        if ia and ib then return ia < ib end
        if ia then return true end
        if ib then return false end
        return a < b
    end)
    IslandList = temp
end

ScanIslands()

IslandCard:Dropdown({
    Title = "🏝️ Select Sea 1 Island", Options = IslandList, Multi = false,
    Callback = function(v)
        SelectedIsland = v
        local d = IslandCache[v]
        if d then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local dist = hrp and string.format("%.0f studs", (hrp.Position - d.pos).Magnitude) or "?"
            TPInfoPara:SetTitle("Island: " .. v)
            TPInfoPara:SetContent(string.format("📌 %.0f, %.0f, %.0f\n📏 %s",
                d.pos.X, d.pos.Y, d.pos.Z, dist))
        end
    end
})
IslandCard:Button({
    Title = "✈️ Teleport To Island",
    Callback = function()
        if not SelectedIsland then _G.SeaNotify("❌ No island", "", 3); return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local gates = workspace:FindFirstChild("Gates")
        local tpPart = gates and gates:FindFirstChild("TeleportPart")
        local target = tpPart and tpPart:FindFirstChild(SelectedIsland)
        if target then
            hrp.CFrame = CFrame.new(target.Position + Vector3.new(0, 5, 0))
            _G.SeaNotify("✈️ Activated", SelectedIsland, 3)
        else
            local d = IslandCache[SelectedIsland]
            if d and d.pos then
                hrp.CFrame = CFrame.new(d.pos + Vector3.new(0, 5, 0))
                _G.SeaNotify("✈️ Activated", SelectedIsland, 3)
            end
        end
    end
})

SeaCard:Button({
    Title = "🌊 Go To Sea 2 (2SeaSoon)",
    Callback = function()
        local seaNPC = workspace:FindFirstChild("2SeaSoon")
        if not seaNPC then _G.SeaNotify("❌ NPC Sea 2 not found", "", 3); return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local npcHrp = seaNPC:FindFirstChild("HumanoidRootPart")
            or seaNPC:FindFirstChildWhichIsA("BasePart")
        if npcHrp then
            hrp.CFrame = CFrame.new(npcHrp.Position + Vector3.new(0, 5, 0))
            _G.SeaNotify("🌊 Arrived at NPC Sea 2", "", 5)
            task.wait(0.5)
            local prompt = seaNPC:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then pcall(function() fireproximityprompt(prompt) end) end
        end
    end
})

-- ============================================================
-- TAB 5: CONFIG
-- ============================================================
local ConfigTab = Window:CreateTab("Config", false, false)
_G.SaveManager:BuildConfigTab(ConfigTab)
task.spawn(function()
    task.wait(1)
    _G.SaveManager:LoadAutoloadConfig()
end)

-- ============================================================
-- BACKGROUND LOOPS cho UI
-- ============================================================
task.spawn(function()
    while task.wait() do
        pcall(function()
            local Text = {}
            for Name, MobName in pairs(Config.SpawnList) do
                local Spawned = false
                local Names = {MobName}
                if MobName == "Devil Boat" then table.insert(Names, "DevilBoat") end
                for _, n in ipairs(Names) do
                    if workspace.Mob and workspace.Mob:FindFirstChild(n) then Spawned = true; break end
                end
                table.insert(Text, Name .. ": " .. (Spawned and "✅" or "❌"))
            end
            Spawn_Status:SetContent(table.concat(Text, "\n"))
        end)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if not _G.Auto_RandomChest_Moon then return end
            local moonStone = tonumber(LocalPlayer:GetAttribute("MoonStone")) or 0
            local v = _G.Select_Random_Moon or "x5"
            local costMap = {["x5"] = 25, ["x10"] = 50, ["x15"] = 75}
            local cost = costMap[v] or 25
            if moonStone >= cost then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "EventMoon", v)
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if not _G.Auto_RandomChest then return end
            local v = _G.Select_Random or "x5"
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "RandomItem", v)
        end)
    end
end)

task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_Guarantee_Moon and Data.PointItemMoon then
                local point = tonumber(LocalPlayer:GetAttribute("MoonPoint")) or 0
                local price = Data.PointItemMoon[_G.Select_Guarantee_Moon] or 0
                if _G.Select_Guarantee_Moon and point >= price then
                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                        "fire", nil, "BuyGaranteeEventMoon", _G.Select_Guarantee_Moon)
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if not _G.Auto_Guarantee then return end
            if not _G.Select_Guarantee or _G.Select_Guarantee == "" then return end
            local pointItem = tonumber(LocalPlayer:GetAttribute("PointItem")) or 0
            local item = _G.Select_Guarantee:match("^(.-) /") or _G.Select_Guarantee
            item = item:gsub("^%s+", ""):gsub("%s+$", "")
            local price = (Data.PointItemM and Data.PointItemM[item]) or 0
            if price > 0 and pointItem >= price then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                    "fire", nil, "BuyGaranteeRandomItem", item)
            end
        end)
    end
end)

-- Auto skill loop (spam khi đang farm)
task.spawn(function()
    while task.wait(0.1) do
        local hasAuto = _G.Auto_Farm_Level or _G.Auto_Farm_Material or _G.Auto_FarmBoss
                     or _G.Auto_DuckAutomatically or _G.Auto_Piccolo
                     or _G.Auto_DevilBoat or _G.Auto_CraftWeapon
                     or _G.Auto_Farm_Set or _G.Auto_Raid or _G.Auto_BaconThief
                     or _G.Auto_Dungeon or _G.AutoRaidRunning or _G.Auto_Kraken
        if hasAuto and _G.CanAutoSkill == true and _G.AutoSkill then
            pcall(function() _G.AutoSkill() end)
        end
    end
end)

print("[Sea1UI] ✅ Loaded")
