-- ============================================================
-- SEA 1 SCRIPT - FULL FEATURES
-- MarvenRiz Hub - Rock Fruit (Sea 1)
-- ============================================================
print("[Sea 1] ▶️ Bắt đầu load...")

-- ===== SERVICES =====
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character

-- ===== MODULES =====
local Npc_Quest = workspace:WaitForChild("NpcQuest")
local Itemdrops = workspace:WaitForChild("Itemdrops")
local UseItems = require(ReplicatedStorage.Modules.UseItems)
local CraftingTable = require(ReplicatedStorage.Modules.CraftingTable)
local Quest_Module = require(ReplicatedStorage.Modules.QuestModule)
local ItemList = require(ReplicatedStorage.Modules.Itemlist)
local SpawnBossList = require(ReplicatedStorage.Modules.SpawnBossList)
local Blacklist = require(ReplicatedStorage.Modules.BlacklistItemTrade)
local AccessoryModule = require(ReplicatedStorage.Modules.AccessoryModule)
local PointItemM = require(ReplicatedStorage.Modules.GaranteeRandomItem)
local PointItemMoon = require(ReplicatedStorage.Modules.GaranteeEventMoon)
local Economy = require(ReplicatedStorage.Modules.Economy)

-- ===== CẤU HÌNH =====
local TypeTool = {"Melee", "Sword", "Special", "DevilFruit"}
local RandomChestValue = {"x5", "x10", "x15"}
local Quest_List = {}
local WeaponAll = {}
local MonsterDrop = {}
local ItemDrop = {}
local ItemToMob = {}
local ItemAll = {}
local X2List = {}
local Poitem = {}
local PoiteMoon = {}
local SellItems = {}
local Bosses = {}
local CachedInventory = {}
local LastCraft = 0
local CraftDelay = 1
local LastInventory = 0
local NotifyCraft = false
local MethodFarm = CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-90), 0, 0)

local SpawnList = {
    ["Thief"] = "Bacon Thief",
    ["Piccolo"] = "Piccolo",
    ["Duck"] = "Duck Monster",
    ["Devil Boat"] = "Devil Boat"
}

-- ===== GLOBAL SETTINGS =====
_G.MainWeapon = "Melee"
_G.Select_EquipWeapon = {}
_G.Select_Method = "Upper"
_G.Distance_Farm = 5
_G.AutoSkillZ = false
_G.AutoSkillX = false
_G.AutoSkillC = false
_G.AutoSkillV = false
_G.AutoSkillF = false
_G.Auto_Haki = false
_G.Auto_Equip_Accessory = false
_G.Auto_Rebirth = false
_G.Select_Potion = {}
_G.Auto_Use_Potion = false
_G.Auto_Farm_Level = false
_G.Select_Material = {}
_G.Auto_Farm_Material = false
_G.Select_Boss = nil
_G.Auto_FarmBoss = false
_G.Auto_FarmBoss_Automatically = false
_G.Auto_BaconThief = false
_G.Auto_Piccolo = false
_G.Auto_Duck = false
_G.Auto_DevilBoat = false
_G.Auto_DuckAutomatically = false
_G.Select_Item = nil
_G.Auto_CraftWeapon = false
_G.Auto_Farm_Set = false
_G.Auto_Raid = false
_G.Dungeon_UseValue = 1
_G.HealthPercent = 30
_G.Auto_Dungeon = false
_G.Select_SellItem = {}
_G.Auto_SellItem = false
_G.Amount = 1000
_G.AutoMelee = false
_G.AutoDefense = false
_G.AutoSword = false
_G.AutoPower = false
_G.Select_Random = "x5"
_G.Auto_RandomChest = false
_G.Select_Random_Moon = "x5"
_G.Auto_RandomChest_Moon = false
_G.Select_Guarantee = nil
_G.Auto_Guarantee = false
_G.Select_Guarantee_Moon = nil
_G.Auto_Guarantee_Moon = false
_G.RaidBossOffsetY = 55
_G.RaidBallOffsetY = 25
_G.DungeonHeight = 25
_G.VFXDisabled = false

-- ===== BUILD DANH SÁCH =====
for ItemName in pairs(Economy) do
    table.insert(SellItems, ItemName)
end
table.sort(SellItems)

for Item, Price in pairs(PointItemM) do
    table.insert(Poitem, {Name = Item, Price = Price})
end
table.sort(Poitem, function(a, b) return a.Price < b.Price end)
for i, Data in ipairs(Poitem) do
    Poitem[i] = Data.Name .. " / " .. Data.Price .. " Point"
end

for Item, Price in pairs(PointItemMoon) do
    table.insert(PoiteMoon, {Name = Item, Price = Price})
end
table.sort(PoiteMoon, function(a, b) return a.Price < b.Price end)
for i, Data in ipairs(PoiteMoon) do
    PoiteMoon[i] = Data.Name .. " / " .. Data.Price .. " Point"
end

table.sort(Quest_Module, function(a, b) return a.Level < b.Level end)
for i, data in ipairs(Quest_Module) do
    local NPC = Npc_Quest:WaitForChild("NPC_Quest" .. i)
    Quest_List[i] = {
        Level = data.Level,
        Monster = NPC:GetAttribute("Name"),
        Quest = NPC
    }
end

for Weapon in pairs(UseItems) do
    table.insert(WeaponAll, Weapon)
end
table.sort(WeaponAll)

for ItemName in pairs(Blacklist) do
    if ItemName:find("X2") then
        table.insert(X2List, ItemName)
    end
end

for _, Mob in ipairs(Itemdrops:GetChildren()) do
    local ScrollingFrame = Mob:FindFirstChild("ScrollingFrame", true)
    if ScrollingFrame then
        MonsterDrop[Mob.Name] = {}
        for _, v in ipairs(ScrollingFrame:GetDescendants()) do
            if v:IsA("TextLabel") and not v.Text:find("%%") then
                MonsterDrop[Mob.Name][v.Text] = true
                ItemDrop[v.Text] = ItemDrop[v.Text] or {}
                table.insert(ItemDrop[v.Text], Mob.Name)
                ItemToMob[v.Text] = Mob.Name
            end
        end
    end
end

for ItemName in pairs(ItemToMob) do
    local Data = ItemList[ItemName]
    if not (Data and Data.Type == "Accessory") then
        table.insert(ItemAll, ItemName)
    end
end
table.sort(ItemAll)

for BossName in pairs(SpawnBossList) do
    table.insert(Bosses, BossName)
end
table.sort(Bosses)

-- ===== HELPER FUNCTIONS =====
local GetQuest_Level = function(My_level)
    local Quest
    for _, v in ipairs(Quest_List) do
        if My_level >= v.Level then
            Quest = v
        else
            break
        end
    end
    return Quest
end

local GetQuestFrame = function()
    return LocalPlayer.PlayerGui.HUD.Main.Frame_Quest
end

local GetInventory = function()
    if tick() - LastInventory < 0.2 then
        return CachedInventory
    end
    LastInventory = tick()
    local Success, Inv = pcall(function()
        return HttpService:JSONDecode(LocalPlayer:GetAttribute("Inventory") or "{}")
    end)
    CachedInventory = Success and Inv or {}
    return CachedInventory
end

local GetItemAmount = function(ItemName)
    local Inv = GetInventory()
    return (Inv[ItemName] and Inv[ItemName].amount) or 0
end

local Teleport = function(Pos)
    local char = LocalPlayer.Character
    if char then
        char:PivotTo(Pos)
    end
end

-- ===== LOAD UI LIBRARY =====
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Ui_New.lua"
))()
local MySaveManager = Library.SaveManager

local Window = Library:CreateWindow({
    Title = "MarvenRiz Hub",
    Subtitle = "Sea 1 — Rock Fruit",
    Size = UDim2.fromOffset(500, 370),
    AccentColor = Color3.fromRGB(50, 150, 255),
    SideBarWidth = 120,
    Logo = "rbxassetid://87526284179554",
    LogoSize = 32,
    SphereText = false,
    SphereImage = "rbxassetid://87526284179554",
    SphereIconSize = 38,
    Map = "RockFruit"
})

-- ===== GLOBAL SAFE NOTIFY (fix lỗi nil cho mọi callback) =====
function _G.SeaNotify(title, desc, duration)
    pcall(function()
        if Library and Library.Notify then
            Library:Notify({
                Title = title or "",
                Description = desc or "",
                Duration = duration or 4
            })
        end
    end)
end

-- ===== AUTO SKILL / EQUIP / ATTACK =====
local AutoSkill = function()
    local char = LocalPlayer.Character
    if not char then return end
    local Skills = {}
    if _G.AutoSkillZ then table.insert(Skills, "z") end
    if _G.AutoSkillX then table.insert(Skills, "x") end
    if _G.AutoSkillC then table.insert(Skills, "c") end
    if _G.AutoSkillV then table.insert(Skills, "v") end
    if _G.AutoSkillF then table.insert(Skills, "f") end
    if #Skills == 0 then return end
    local Skill = Skills[math.random(#Skills)]
    for _, Tool in ipairs(char:GetChildren()) do
        if Tool:IsA("Tool") then
            ReplicatedStorage.Remotes.Action:FireServer(Tool.Name, Skill)
        end
    end
end

local EquipWeapon = function()
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") and v:GetAttribute("Type") ~= _G.MainWeapon then
            v.Parent = LocalPlayer.Backpack
        end
    end
    for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if v:IsA("Tool") and v:GetAttribute("Type") == _G.MainWeapon then
            char.Humanoid:EquipTool(v)
            break
        end
    end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") and v:GetAttribute("Type") ~= _G.MainWeapon and not table.find(_G.Select_EquipWeapon or {}, v:GetAttribute("Type")) then
            v.Parent = LocalPlayer.Backpack
        end
    end
    for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if v:IsA("Tool") and v:GetAttribute("Type") ~= _G.MainWeapon and table.find(_G.Select_EquipWeapon or {}, v:GetAttribute("Type")) then
            v.Parent = char
        end
    end
end

local Attack = function()
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then
            ReplicatedStorage.Remotes.Action:FireServer(v.Name, "hit")
        end
    end
end

-- ===== NO VFX =====
local VFXLoop = nil
local NoVFX = function(State)
    _G.VFXDisabled = State
    if State then
        if VFXLoop then VFXLoop:Disconnect() end
        VFXLoop = RunService.Heartbeat:Connect(function()
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail") then
                        if v.Enabled then v.Enabled = false end
                    end
                end
                local boss = workspace:FindFirstChild("Boss")
                if boss then
                    for _, v in pairs(boss:GetDescendants()) do
                        if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail") then
                            if v.Enabled then v.Enabled = false end
                        end
                    end
                end
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    if hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
                    if hum.JumpPower < 50 then hum.JumpPower = 50 end
                end
                for _, folderName in ipairs({"Stun", "StunS"}) do
                    local folder = char:FindFirstChild(folderName)
                    if folder and #folder:GetChildren() > 0 then
                        folder:ClearAllChildren()
                    end
                end
            end)
        end)
    else
        if VFXLoop then VFXLoop:Disconnect(); VFXLoop = nil end
    end
end

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ============================================================
-- TAB 1: SETTINGS
-- ============================================================
local Tab1 = Window:CreateTab("Settings", true, false)
local Tab_Page1 = Tab1:CreatePage("Main Settings")
local Weapon = Tab_Page1:CreateSection("🗡️ Select Weapon", "Left")
local AutoSkills = Tab_Page1:CreateSection("⚔️ Auto Skills", "Left")
local Method = Tab_Page1:CreateSection("🎯 Select Method Farm", "Right")
local Haki = Tab_Page1:CreateSection("👁️ Haki", "Right")
local VFX = Tab_Page1:CreateSection("✨ VFX", "Right")
local Tab_Page2 = Tab1:CreatePage("Other Settings")
local Accessory = Tab_Page2:CreateSection("🎒 Accessory & Rebirth", "Right")
local Potion = Tab_Page2:CreateSection("🧪 Auto Use X2 Potion", "Left")

Weapon:Dropdown({
    Title = "Main Weapon (Attack)",
    Options = TypeTool,
    Multi = false,
    Value = "Melee",
    Callback = function(Value) _G.MainWeapon = Value end
})

Weapon:Dropdown({
    Title = "Select Support Weapon",
    Options = TypeTool,
    Multi = true,
    Callback = function(Value) _G.Select_EquipWeapon = Value end
})

AutoSkills:Toggle({Title = "Auto Skill Z", Value = false, Callback = function(v) _G.AutoSkillZ = v end})
AutoSkills:Toggle({Title = "Auto Skill X", Value = false, Callback = function(v) _G.AutoSkillX = v end})
AutoSkills:Toggle({Title = "Auto Skill C", Value = false, Callback = function(v) _G.AutoSkillC = v end})
AutoSkills:Toggle({Title = "Auto Skill V", Value = false, Callback = function(v) _G.AutoSkillV = v end})
AutoSkills:Toggle({Title = "Auto Skill F", Value = false, Callback = function(v) _G.AutoSkillF = v end})

Haki:Toggle({Title = "Auto Enabled Haki", Value = false, Callback = function(v) _G.Auto_Haki = v end})

Method:Dropdown({
    Title = "Select Method Farm",
    Options = {"Behind", "Below", "Upper", "Front"},
    Multi = false,
    Value = "Upper",
    Callback = function(v) _G.Select_Method = v end
})

Method:Slider({
    Title = "Distance Farm",
    Min = 0,
    Max = 30,
    Value = 5,
    Callback = function(v) _G.Distance_Farm = v end
})

VFX:Toggle({
    Title = "Disable VFX",
    Value = false,
    Callback = function(v) NoVFX(v) end
})

Accessory:Toggle({
    Title = "Auto Equip Best Accessory",
    Value = false,
    Callback = function(v) _G.Auto_Equip_Accessory = v end
})

Accessory:Toggle({
    Title = "Auto Rebirth (Max Level)",
    Value = false,
    Callback = function(v) _G.Auto_Rebirth = v end
})

Potion:Dropdown({
    Title = "Select X2 Potion",
    Options = X2List,
    Multi = true,
    Callback = function(v) _G.Select_Potion = v end
})

Potion:Toggle({
    Title = "Auto Use X2 Potion",
    Value = false,
    Callback = function(v) _G.Auto_Use_Potion = v end
})

-- ============================================================
-- TAB 2: MAIN (Farm, Boss, Raid, Dungeon)
-- ============================================================
local Tab2 = Window:CreateTab("Main", false, false)
local Farm = Tab2:CreatePage("Farm")
local AllBoss = Tab2:CreatePage("Boss")
local RaidBossPage = Tab2:CreatePage("Raid Boss & Shop")
local RaidDun = Tab2:CreatePage("Dungeon, Shop / Weapon")

local AutoFarmCard = Farm:CreateSection("🌾 Auto Farm", "Left")
local MaterialCard = Farm:CreateSection("⛏️ Auto Farm Material", "Right")
local Boss = AllBoss:CreateSection("👹 Boss", "Left")
local Thief = AllBoss:CreateSection("💸 Thief", "Left")
local Piccolo = AllBoss:CreateSection("🐉 Piccolo", "Left")
local SpawnedT = AllBoss:CreateSection("🔍 Spawned Check", "Right")
local Duck = AllBoss:CreateSection("🦆 Duck", "Right")
local DevilBoat = AllBoss:CreateSection("⛵ Devil Boat", "Right")
local DungeonCard = RaidDun:CreateSection("🏰 Auto Dungeon", "Left")
local ShopDunCard = RaidDun:CreateSection("🏪 Shop Dungeon", "Left")
local WeaponCraft = RaidDun:CreateSection("🔨 Weapon", "Left")
local DungeonSettingsCard = RaidDun:CreateSection("⚙️ Dungeon Settings", "Right")
local ShopDunInfoCard = RaidDun:CreateSection("📊 Shop Dungeon Info", "Right")
local RaidCard = RaidDun:CreateSection("🌋 Auto Raid Moon", "Right")
local RaidBossCard = RaidBossPage:CreateSection("⚔️ Auto Raid Boss", "Left")
local RaidBossInfoCard = RaidBossPage:CreateSection("📋 Raid Info", "Right")
local ShopRaidCard = RaidBossPage:CreateSection("🏪 Shop Raid", "Left")
local ShopRaidInfoCard = RaidBossPage:CreateSection("📊 Shop Info", "Right")
local RaidSettingsCard = RaidBossPage:CreateSection("⚙️ Raid Settings", "Right")

AutoFarmCard:Toggle({
    Title = "Auto Level Farm",
    Value = false,
    Callback = function(v)
        _G.Auto_Farm_Level = v
        if v then
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
        end
    end
})

MaterialCard:Dropdown({
    Title = "Select Farm Material",
    Options = ItemAll,
    Multi = true,
    Callback = function(v) _G.Select_Material = v end
})

MaterialCard:Toggle({
    Title = "Auto Farm Material",
    Value = false,
    Callback = function(v) _G.Auto_Farm_Material = v end
})

Boss:Dropdown({
    Title = "Select Boss",
    Options = Bosses,
    Multi = false,
    Callback = function(v) _G.Select_Boss = v end
})

Boss:Toggle({Title = "Auto Farm All Boss", Value = false, Callback = function(v) _G.Auto_FarmBoss = v end})

Boss:Toggle({
    Title = "Auto Farm Boss (Full)",
    Value = false,
    Callback = function(v)
        _G.Auto_FarmBoss_Automatically = v
        if v then
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
        end
    end
})

Thief:Toggle({Title = "Auto Farm Thief Chest", Value = false, Callback = function(v) _G.Auto_BaconThief = v end})
Piccolo:Toggle({Title = "Auto Farm Piccolo", Value = false, Callback = function(v) _G.Auto_Piccolo = v end})
Duck:Toggle({Title = "Auto Farm Duck", Value = false, Callback = function(v) _G.Auto_Duck = v end})
Duck:Toggle({Title = "Auto Farm Duck (Full)", Value = false, Callback = function(v)
    _G.Auto_DuckAutomatically = v
    if v then ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel") end
end})
DevilBoat:Toggle({Title = "Auto Farm Devil Boat", Value = false, Callback = function(v) _G.Auto_DevilBoat = v end})

local Spawn_Status = SpawnedT:Paragraph({
    Title = "Spawn Status",
    Content = "N/A"
})

local Item_Auto = WeaponCraft:Paragraph({
    Title = "Item Requirements ( None )",
    Content = "N/A"
})

WeaponCraft:Dropdown({
    Title = "Select Weapon Craft",
    Options = WeaponAll,
    Multi = false,
    Callback = function(v) _G.Select_Item = v end
})

WeaponCraft:Button({
    Title = "Craft Weapon",
    Callback = function()
        local Data = UseItems[_G.Select_Item]
        if Data then
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Craft", _G.Select_Item, Data.Type)
        end
    end
})

local NotifyClass = false
WeaponCraft:Toggle({
    Title = "Auto Craft Weapon (Full)",
    Value = false,
    Callback = function(v)
        _G.Auto_CraftWeapon = v
        if not v then NotifyClass = false end
    end
})

WeaponCraft:Toggle({
    Title = "Auto Farm Set Weapon",
    Value = false,
    Callback = function(v) _G.Auto_Farm_Set = v end
})

RaidCard:Toggle({
    Title = "Auto Raid Moon (Full)",
    Value = false,
    Callback = function(v)
        _G.Auto_Raid = v
        if v then
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
        end
    end
})

DungeonCard:Textbox({
    Title = "Dungeon Orb to Use",
    Placeholder = "...",
    Callback = function(v) _G.Dungeon_UseValue = tonumber(v) or 1 end
})

DungeonSettingsCard:Slider({
    Title = "Health Return %",
    Min = 1,
    Max = 100,
    Value = 30,
    Callback = function(v) _G.HealthPercent = v end
})

DungeonSettingsCard:Slider({
    Title = "Dungeon Height",
    Min = 0,
    Max = 100,
    Value = 25,
    Callback = function(v) _G.DungeonHeight = v end
})

DungeonCard:Toggle({
    Title = "Auto Dungeon (Full)",
    Value = false,
    Callback = function(v)
        _G.Auto_Dungeon = v
        if v then
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
        end
    end
})

-- ===== RAID BOSS UI =====
local RaidBossData = {
    ["Bacon of Grudge"] = {
        Name = "Bacon of Grudge",
        Reward = "Time Mystery Box x5, 7500 Diamond, Beli 50M, x3 Potion",
        PortalCost = 1,
        Valid = true
    },
    ["??? (Raid 2)"] = {Name = "???", Reward = "SOON", PortalCost = 0, Valid = false},
    ["??? (Raid 3)"] = {Name = "???", Reward = "SOON", PortalCost = 0, Valid = false}
}

local RaidBossInfoPara = RaidBossInfoCard:Paragraph({
    Title = "Name: ( chưa chọn )",
    Content = "Please choose a Boss Raid!!"
})

RaidBossCard:Dropdown({
    Title = "Choose a boss to raid",
    Options = {"Bacon of Grudge", "??? (Raid 2)", "??? (Raid 3)"},
    Multi = false,
    Callback = function(Value)
        _G.AutoRaidWho = Value
        local Data = RaidBossData[Value]
        if Data then
            RaidBossInfoPara:SetTitle("Name: " .. Data.Name)
            RaidBossInfoPara:SetContent("Reward: " .. Data.Reward .. "\n- " .. Data.PortalCost .. " Portal Gun")
        end
    end
})

RaidBossCard:Button({
    Title = "Start Raid Now!!",
    Callback = function()
        local Data = RaidBossData[_G.AutoRaidWho]
        if not Data then
            _G.SeaNotify("❌ Raid not selected", "Please choose a Boss Raid!", 3)
            return
        end
        if not Data.Valid then
            _G.SeaNotify("❌ Raid không hợp lệ", "NO RAID!!!", 3)
            return
        end
        _G.AutoRaidRunning = not _G.AutoRaidRunning
        _G.SeaNotify(
            _G.AutoRaidRunning and "▶️ Start Raid" or "⏹️ Stop Raid",
            Data.Name,
            3
        )
    end
})

RaidSettingsCard:Slider({
    Title = "Bacon of Grudge Height",
    Min = 0,
    Max = 150,
    Value = 55,
    Callback = function(v) _G.RaidBossOffsetY = v end
})

RaidSettingsCard:Slider({
    Title = "Golden Ball Height",
    Min = 0,
    Max = 150,
    Value = 25,
    Callback = function(v) _G.RaidBallOffsetY = v end
})

-- ===== SHOP RAID UI =====
local ShopInfoPara = ShopRaidInfoCard:Paragraph({
    Title = "RaidPoint: ( đang load... )",
    Content = "Restock In: ( đang load... )"
})

local ShopItemInfo = ShopRaidInfoCard:Paragraph({
    Title = "Item: ( chưa chọn )",
    Content = "Chọn item từ dropdown"
})

-- Lưu selection vào _G
_G.SelectedShopItem = nil
local ShopItemDropdown = nil
local LastShopItemsStr = ""
local ShopDropdownInitialized = false

-- Hàm tạo/cập nhật dropdown
local function UpdateShopDropdown(items)
    if #items == 0 then return end
    local itemsStr = table.concat(items, ",")
    if itemsStr == LastShopItemsStr and ShopItemDropdown then return end
    LastShopItemsStr = itemsStr

    -- Nếu chưa có dropdown → tạo mới
    if not ShopItemDropdown then
        ShopItemDropdown = ShopRaidCard:Dropdown({
            Title = "Select Items to Purchase",
            Options = items,
            Multi = false,
            Callback = function(Value)
                _G.SelectedShopItem = Value
                ShopItemInfo:SetTitle("Item: " .. Value)
                ShopItemInfo:SetContent("Đã chọn — bấm BUY để mua")
                print("[ShopRaid] Đã chọn:", Value)
            end
        })
        ShopDropdownInitialized = true
    else
        -- Đã có dropdown → thử update Options
        local updated = false
        pcall(function()
            if ShopItemDropdown.Set then
                ShopItemDropdown:Set(items)
                updated = true
            elseif ShopItemDropdown.UpdateOptions then
                ShopItemDropdown:UpdateOptions(items)
                updated = true
            end
        end)
        -- Nếu không update được → Destroy + tạo mới
        if not updated then
            pcall(function() ShopItemDropdown:Destroy() end)
            ShopItemDropdown = ShopRaidCard:Dropdown({
                Title = "Select Items to Purchase",
                Options = items,
                Multi = false,
                Callback = function(Value)
                    _G.SelectedShopItem = Value
                    ShopItemInfo:SetTitle("Item: " .. Value)
                    ShopItemInfo:SetContent("Đã chọn — bấm BUY để mua")
                    print("[ShopRaid] Đã chọn:", Value)
                end
            })
        end
    end
end

ShopRaidCard:Button({
    Title = "BUY!!",
    Callback = function()
        if not _G.SelectedShopItem then
            _G.SeaNotify("❌ Chưa chọn item", "Vui lòng chọn item trước!", 3)
            return
        end
        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "buy_raidshop", _G.SelectedShopItem)
        _G.SeaNotify("✅ Đã mua", _G.SelectedShopItem, 3)
    end
})

-- ===== SHOP DUNGEON UI =====
local ShopDunInfoPara = ShopDunInfoCard:Paragraph({
    Title = "DungeonPoint: ( đang load... )",
    Content = "Chọn item Auto Buy ở cột trái"
})

local ShopDunItemInfo = ShopDunInfoCard:Paragraph({
    Title = "Item: ( chưa chọn )",
    Content = "Chọn item từ dropdown"
})

-- Lưu selection vào _G
_G.AutoBuyDunItem = nil
_G.AutoBuyDunRunning = false
local AutoBuyDunDropdown = nil
local LastAutoBuyDunStr = ""

-- Hàm lấy tất cả item Shop Dungeon (quét thật)
local function GetAllShopDunItems()
    local items = {}
    local seen = {}
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

-- Hàm update dropdown
local function UpdateDunDropdown(items)
    if #items == 0 then return end
    local itemsStr = table.concat(items, ",")
    if itemsStr == LastAutoBuyDunStr and AutoBuyDunDropdown then return end
    LastAutoBuyDunStr = itemsStr

    if not AutoBuyDunDropdown then
        AutoBuyDunDropdown = ShopDunCard:Dropdown({
            Title = "Auto Buy Items",
            Options = items,
            Multi = false,
            Callback = function(Value)
                _G.AutoBuyDunItem = Value
                ShopDunItemInfo:SetTitle("Item: " .. Value)
                ShopDunItemInfo:SetContent("Đã chọn — bật Toggle Auto Buy")
                print("[ShopDun] Đã chọn:", Value)
            end
        })
    else
        -- Thử update Options
        local updated = false
        pcall(function()
            if AutoBuyDunDropdown.Set then
                AutoBuyDunDropdown:Set(items)
                updated = true
            elseif AutoBuyDunDropdown.UpdateOptions then
                AutoBuyDunDropdown:UpdateOptions(items)
                updated = true
            end
        end)
        if not updated then
            pcall(function() AutoBuyDunDropdown:Destroy() end)
            AutoBuyDunDropdown = ShopDunCard:Dropdown({
                Title = "Auto Buy Items",
                Options = items,
                Multi = false,
                Callback = function(Value)
                    _G.AutoBuyDunItem = Value
                    ShopDunItemInfo:SetTitle("Item: " .. Value)
                    ShopDunItemInfo:SetContent("Đã chọn — bật Toggle Auto Buy")
                    print("[ShopDun] Đã chọn:", Value)
                end
            })
        end
    end
end

ShopDunCard:Toggle({
    Title = "Auto Buy",
    Value = false,
    Callback = function(Value)
        if Value and not _G.AutoBuyDunItem then
            _G.SeaNotify("❌ Chưa chọn item", "Chọn item Auto Buy trước!", 3)
            _G.AutoBuyDunRunning = false
            return
        end
        _G.AutoBuyDunRunning = Value
        _G.SeaNotify(Value and "▶️ Bật Auto Buy" or "⏹️ Tắt Auto Buy", _G.AutoBuyDunItem or "N/A", 3)
    end
})

-- ============================================================
-- TAB 3: OTHER (Sell, Status, Random Chest, Craft Table)
-- ============================================================
local Tab3 = Window:CreateTab("Other", false, false)
local SItem = Tab3:CreatePage("Sell Item / Status")
local RandomM = Tab3:CreatePage("Random Chest")
local CraftTablePage = Tab3:CreatePage("Craft Table")
local SellCard = SItem:CreateSection("💰 Auto Sell", "Left")
local StatusCard = SItem:CreateSection("📊 Status", "Right")
local DiamondChest = RandomM:CreateSection("💎 Diamond Chest", "Right")
local GuaranteeDiamond = RandomM:CreateSection("🎖️ Guarantee Gem Point", "Right")
local MoonChest = RandomM:CreateSection("🌙 Moon Chest", "Left")
local GuaranteeMoon = RandomM:CreateSection("☄️ Guarantee Moon Point", "Left")

SellCard:Dropdown({
    Title = "Select Sell Item",
    Options = SellItems,
    Multi = true,
    Callback = function(v) _G.Select_SellItem = v end
})

SellCard:Toggle({Title = "Auto Sell", Value = false, Callback = function(v) _G.Auto_SellItem = v end})

StatusCard:Textbox({
    Title = "Status Amount",
    Placeholder = "1000",
    Value = "1000",
    Callback = function(v) _G.Amount = tonumber(v) or 1000 end
})

StatusCard:Toggle({Title = "Auto Up Melee", Value = false, Callback = function(v) _G.AutoMelee = v end})
StatusCard:Toggle({Title = "Auto Up Defense", Value = false, Callback = function(v) _G.AutoDefense = v end})
StatusCard:Toggle({Title = "Auto Up Sword", Value = false, Callback = function(v) _G.AutoSword = v end})
StatusCard:Toggle({Title = "Auto Up Power", Value = false, Callback = function(v) _G.AutoPower = v end})

DiamondChest:Dropdown({
    Title = "Select Random Diamond Chest",
    Options = RandomChestValue,
    Multi = false,
    Callback = function(v) _G.Select_Random = v end
})

DiamondChest:Toggle({Title = "Auto Random Diamond Chest", Value = false, Callback = function(v) _G.Auto_RandomChest = v end})

MoonChest:Dropdown({
    Title = "Select Random Moon Chest",
    Options = RandomChestValue,
    Multi = false,
    Callback = function(v) _G.Select_Random_Moon = v end
})

MoonChest:Toggle({Title = "Auto Random Moon Chest", Value = false, Callback = function(v) _G.Auto_RandomChest_Moon = v end})

GuaranteeDiamond:Dropdown({
    Title = "Select Guarantee Diamond Point",
    Options = Poitem,
    Multi = false,
    Callback = function(v) _G.Select_Guarantee = v:match("^(.-) /") end
})

GuaranteeDiamond:Button({
    Title = "Buy Guarantee Diamond Point",
    Callback = function()
        local Point = tonumber(LocalPlayer:GetAttribute("PointItem")) or 0
        local Price = PointItemM[_G.Select_Guarantee] or 0
        if _G.Select_Guarantee and Point >= Price then
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "BuyGaranteeRandomItem", _G.Select_Guarantee)
        end
    end
})

GuaranteeDiamond:Toggle({
    Title = "Auto Buy Guarantee Diamond",
    Value = false,
    Callback = function(v) _G.Auto_Guarantee = v end
})

GuaranteeMoon:Dropdown({
    Title = "Select Guarantee Moon Point",
    Options = PoiteMoon,
    Multi = false,
    Callback = function(v) _G.Select_Guarantee_Moon = v:match("^(.-) /") end
})

GuaranteeMoon:Button({
    Title = "Buy Guarantee Moon Point",
    Callback = function()
        local Point = tonumber(LocalPlayer:GetAttribute("MoonPoint")) or 0
        local Price = PointItemMoon[_G.Select_Guarantee_Moon] or 0
        if _G.Select_Guarantee_Moon and Point >= Price then
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "BuyGaranteeEventMoon", _G.Select_Guarantee_Moon)
        end
    end
})

GuaranteeMoon:Toggle({
    Title = "Auto Buy Guarantee Moon",
    Value = false,
    Callback = function(v) _G.Auto_Guarantee_Moon = v end
})

-- ===== CRAFT TABLE =====
local CraftCard = CraftTablePage:CreateSection("🔨 Craft Table", "Left")
local CraftInfoCard = CraftTablePage:CreateSection("📋 Craft Info", "Right")

local CraftInfoPara = CraftInfoCard:Paragraph({
    Title = "Items: ( chưa chọn )",
    Content = "Consumables: ---"
})

_G.SelectedCraftItem = nil
local CraftDropdown = nil

local function GetAllCraftItems()
    local items = {}
    for name, data in pairs(CraftingTable) do
        if data.need then table.insert(items, name) end
    end
    table.sort(items)
    return items
end

CraftCard:Dropdown({
    Title = "Chọn Items để chế tạo",
    Options = GetAllCraftItems(),
    Multi = false,
    Callback = function(Value) _G.SelectedCraftItem = Value end
})

CraftCard:Toggle({
    Title = "Auto Chế Tạo",
    Value = false,
    Callback = function(v) _G.AutoCraftRunning = v end
})

CraftInfoCard:Toggle({
    Title = "Auto Claim Guarantee",
    Value = false,
    Callback = function(v) _G.AutoClaimGuarantee = v end
})

-- ============================================================
-- TAB 4: GOKU NPC
-- ============================================================
local TabGoku = Window:CreateTab("Goku", false, false)
local GokuPage = TabGoku:CreatePage("Npc Goku Gods")
local GokuCurrentCard = GokuPage:CreateSection("📍 NPC Đang Có", "Left")
local GokuActionCard = GokuPage:CreateSection("⚙️ Actions", "Right")

local GokuCurrentPara = GokuCurrentCard:Paragraph({
    Title = "Npc Count: 0 / 5",
    Content = "Đang tìm NPC..."
})

local GOKU_NPC_KEYWORDS = {"goku", "vegeta", "gohan", "goten", "trunk", "bardock"}
local MAX_NPC_PER_SESSION = 5
local MISS_THRESHOLD = 5

_G.AutoGokuFind = false
_G.AutoGokuTP = false
local GokuSpawnData = {}
local SessionSpawnedCount = 0
local SessionNPCSpawned = {}

local function FormatDuration(sec)
    sec = math.max(0, math.floor(sec))
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then return string.format("%02d:%02d:%02d", h, m, s) end
    return string.format("%02d:%02d", m, s)
end

local function FormatClock(t)
    local d = os.date("*t", t)
    return string.format("%02d:%02d:%02d", d.hour, d.min, d.sec)
end

local function ResetGokuSession(reason)
    GokuSpawnData = {}
    SessionSpawnedCount = 0
    SessionNPCSpawned = {}
    _G.SeaNotify("🔄 Reset phiên NPC", reason or "Đã đủ 5 NPC", 5)
end

local function ScanGokuNPCs()
    local results = {}
    local powerGod = workspace:FindFirstChild("Power God")
    if not powerGod then return results end
    local char = LocalPlayer.Character
    local myHrp = char and char:FindFirstChild("HumanoidRootPart")
    local now = tick()

    if SessionSpawnedCount >= MAX_NPC_PER_SESSION then
        ResetGokuSession("Đủ 5 NPC — reset phiên")
        return results
    end

    for _, obj in ipairs(powerGod:GetChildren()) do
        if obj:IsA("Model") then
            local lower = obj.Name:lower()
            local matched = false
            for _, kw in ipairs(GOKU_NPC_KEYWORDS) do
                if lower:find(kw) then matched = true; break end
            end
            if matched then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                local hum = obj:FindFirstChild("Humanoid")
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                local dist = (myHrp and hrp) and (myHrp.Position - hrp.Position).Magnitude or -1

                local data = GokuSpawnData[obj.Name]
                if not data then
                    data = {firstSeenAt = now, spawnClock = os.time(), lastSeen = now, isAlive = true}
                    GokuSpawnData[obj.Name] = data
                    if not SessionNPCSpawned[obj.Name] then
                        SessionNPCSpawned[obj.Name] = true
                        SessionSpawnedCount = SessionSpawnedCount + 1
                    end
                    _G.SeaNotify("🎯 NPC Spawn!", obj.Name .. " (" .. SessionSpawnedCount .. "/" .. MAX_NPC_PER_SESSION .. ")", 5)
                else
                    data.lastSeen = now
                    if not data.isAlive then
                        data.isAlive = true
                        data.firstSeenAt = now
                        data.spawnClock = os.time()
                        _G.SeaNotify("🎯 NPC Respawn!", obj.Name .. " quay lại!", 5)
                    end
                end

                table.insert(results, {
                    Name = obj.Name, Model = obj, Position = hrp and hrp.Position or Vector3.zero,
                    Health = hum and hum.Health or 0, HasPrompt = prompt ~= nil,
                    PromptText = prompt and prompt.ActionText or "N/A",
                    Distance = dist, Prompt = prompt,
                    SpawnClock = data.spawnClock, Elapsed = now - data.firstSeenAt
                })
            end
        end
    end

    for name, data in pairs(GokuSpawnData) do
        if now - data.lastSeen > MISS_THRESHOLD and data.isAlive then
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

local function RenderGokuCurrent(npcs)
    local text = {}
    table.insert(text, "Phiên: " .. SessionSpawnedCount .. "/" .. MAX_NPC_PER_SESSION)
    table.insert(text, "Đang có mặt: " .. #npcs)
    table.insert(text, "─────────────────")
    if #npcs == 0 then
        table.insert(text, "❌ Không có NPC nào")
    else
        for i, npc in ipairs(npcs) do
            local distText = npc.Distance >= 0 and string.format("%.0f studs", npc.Distance) or "?"
            table.insert(text, string.format(
                "%d. %s\n   ⏰ %s (đã %s)\n   📏 %s | ❤️ %d\n   🖱️ %s (%s)",
                i, npc.Name, FormatClock(npc.SpawnClock), FormatDuration(npc.Elapsed),
                distText, npc.Health, npc.HasPrompt and "✅" or "❌", npc.PromptText
            ))
        end
    end
    GokuCurrentPara:SetTitle("Npc Count: " .. SessionSpawnedCount .. " / " .. MAX_NPC_PER_SESSION)
    GokuCurrentPara:SetContent(table.concat(text, "\n"))
end

local function ClickGokuNPC(npcData)
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

GokuActionCard:Toggle({
    Title = "🎯 Auto Find & Click NPC",
    Value = false,
    Callback = function(Value)
        _G.AutoGokuFind = Value
        _G.SeaNotify(Value and "▶️ Bật Auto Goku" or "⏹️ Tắt Auto Goku", "Tự động tìm + click", 3)
    end
})

GokuActionCard:Toggle({
    Title = "✈️ Auto TP Nearest NPC",
    Value = false,
    Callback = function(Value)
        _G.AutoGokuTP = Value
        _G.SeaNotify(Value and "▶️ Bật Auto TP" or "⏹️ Tắt Auto TP", "TP tới NPC gần nhất", 3)
    end
})

-- ============================================================
-- TAB 5: TELEPORT (23 đảo Sea 1)
-- ============================================================
local TabTP = Window:CreateTab("Teleport", false, false)
local TPPage = TabTP:CreatePage("Teleport Sea 1")

local IslandCard = TPPage:CreateSection("🏝️ Đảo Sea 1", "Left")
local SeaCard = TPPage:CreateSection("🌊 Sea Travel", "Right")
local TPInfoCard = TPPage:CreateSection("📊 Thông Tin", "Right")

local IslandCache = {}
local IslandList = {}
local SelectedIsland = nil

local TPInfoPara = TPInfoCard:Paragraph({Title = "Sea 1", Content = "Đang load..."})
local SeaInfoPara = SeaCard:Paragraph({Title = "Sea", Content = "Đang load..."})

local function ScanIslands()
    IslandCache = {}
    IslandList = {}
    local islandFolder = workspace:FindFirstChild("island")
    if not islandFolder then return end

    local orderMap = {}
    local gates = workspace:FindFirstChild("Gates")
    local tpPart = gates and gates:FindFirstChild("TeleportPart")
    if tpPart then
        for i, part in ipairs(tpPart:GetChildren()) do
            if part:IsA("BasePart") then orderMap[part.Name] = i end
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

IslandCard:Dropdown({
    Title = "🏝️ Chọn Đảo Sea 1",
    Options = IslandList,
    Multi = false,
    Callback = function(Value)
        SelectedIsland = Value
        local data = IslandCache[Value]
        if data then
            local char = LocalPlayer.Character
            local myHrp = char and char:FindFirstChild("HumanoidRootPart")
            local dist = myHrp and string.format("%.0f studs", (myHrp.Position - data.pos).Magnitude) or "?"
            TPInfoPara:SetTitle("Đảo: " .. Value)
            TPInfoPara:SetContent(string.format("📌 %.0f, %.0f, %.0f\n📏 %s", data.pos.X, data.pos.Y, data.pos.Z, dist))
        end
    end
})

IslandCard:Button({
    Title = "✈️ Dịch Chuyển Tới Đảo",
    Callback = function()
        if not SelectedIsland then
            _G.SeaNotify("❌ Chưa chọn đảo", "Chọn 1 đảo trước!", 3)
            return
        end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            _G.SeaNotify("❌ Không có nhân vật", "Character chưa load", 3)
            return
        end
        local gates = workspace:FindFirstChild("Gates")
        local tpPart = gates and gates:FindFirstChild("TeleportPart")
        local target = tpPart and tpPart:FindFirstChild(SelectedIsland)
        if target then
            hrp.CFrame = CFrame.new(target.Position + Vector3.new(0, 5, 0))
            _G.SeaNotify("✈️ Đã dịch chuyển", SelectedIsland .. " (TeleportPart)", 3)
        else
            local data = IslandCache[SelectedIsland]
            if data and data.pos then
                hrp.CFrame = CFrame.new(data.pos + Vector3.new(0, 5, 0))
                _G.SeaNotify("✈️ Đã dịch chuyển", SelectedIsland .. " (Model pos)", 3)
            else
                _G.SeaNotify("❌ Không tìm thấy đảo", SelectedIsland, 3)
            end
        end
    end
})

SeaCard:Button({
    Title = "🌊 Đi Tới Sea 2 (2SeaSoon)",
    Callback = function()
        local seaNPC = workspace:FindFirstChild("2SeaSoon")
        if not seaNPC then
            _G.SeaNotify("❌ Không tìm thấy NPC Sea 2", "workspace.2SeaSoon không có", 3)
            return
        end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local npcHrp = seaNPC:FindFirstChild("HumanoidRootPart") or seaNPC:FindFirstChildWhichIsA("BasePart")
        if npcHrp then
            hrp.CFrame = CFrame.new(npcHrp.Position + Vector3.new(0, 5, 0))
            _G.SeaNotify("🌊 Đã tới NPC Sea 2", "Chờ game chuyển Sea...", 5)
            task.wait(0.5)
            local prompt = seaNPC:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then pcall(function() fireproximityprompt(prompt) end) end
        end
    end
})

task.spawn(function()
    while task.wait(2) do
        pcall(function()
            local seaAttr = LocalPlayer:GetAttribute("CurrentSea") or "First"
            local seaOpened = LocalPlayer:GetAttribute("Sea")
            local text = "Sea hiện tại: " .. tostring(seaAttr)
            if type(seaOpened) == "table" then
                local list = {}
                for k, v in pairs(seaOpened) do
                    if v then table.insert(list, k) end
                end
                if #list > 0 then text = text .. "\nĐã mở: " .. table.concat(list, ", ") end
            end
            text = text .. "\nNPC Sea 2: " .. (workspace:FindFirstChild("2SeaSoon") and "✅" or "❌")
            text = text .. "\nSố đảo: " .. #IslandList
            SeaInfoPara:SetTitle("🌊 " .. tostring(seaAttr))
            SeaInfoPara:SetContent(text)
        end)
    end
end)

-- ============================================================
-- TAB 6: CONFIG
-- ============================================================
local ConfigTab = Window:CreateTab("Config", false, false)
MySaveManager:BuildConfigTab(ConfigTab)
task.spawn(function()
    task.wait(1)
    MySaveManager:LoadAutoloadConfig()
end)

-- ============================================================
-- BACKGROUND LOOPS
-- ============================================================
task.spawn(function()
    while task.wait(0.1) do
        if _G.AutoMelee then
            ReplicatedStorage.Remotes.System:FireServer("UpStats", "Melee", _G.Amount)
        end
        if _G.AutoDefense then
            ReplicatedStorage.Remotes.System:FireServer("UpStats", "Defense", _G.Amount)
        end
        if _G.AutoSword then
            ReplicatedStorage.Remotes.System:FireServer("UpStats", "Sword", _G.Amount)
        end
        if _G.AutoPower then
            ReplicatedStorage.Remotes.System:FireServer("UpStats", "Power", _G.Amount)
        end
    end
end)

task.spawn(function()
    while task.wait() do
        pcall(function()
            local Text = {}
            for Name, MobName in pairs(SpawnList) do
                local Spawned = false
                local Names = {MobName}
                if MobName == "Devil Boat" then table.insert(Names, "DevilBoat") end
                for _, n in ipairs(Names) do
                    if workspace.Mob:FindFirstChild(n) then Spawned = true; break end
                end
                table.insert(Text, Name .. ": " .. (Spawned and "✅" or "❌"))
            end
            Spawn_Status:SetContent(table.concat(Text, "\n"))
        end)
    end
end)

task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Select_Method == "Behind" then
                MethodFarm = CFrame.new(0, 0, _G.Distance_Farm)
            elseif _G.Select_Method == "Front" then
                MethodFarm = CFrame.new(0, 0, -_G.Distance_Farm) * CFrame.Angles(0, math.rad(180), 0)
            elseif _G.Select_Method == "Below" then
                MethodFarm = CFrame.new(0, -_G.Distance_Farm, 0) * CFrame.Angles(math.rad(90), 0, 0)
            else
                MethodFarm = CFrame.new(0, _G.Distance_Farm, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            end
        end)
    end
end)

task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_RandomChest_Moon then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "EventMoon", _G.Select_Random_Moon)
            end
        end)
    end
end)

task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_RandomChest then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "RandomItem", _G.Select_Random)
            end
        end)
    end
end)

task.spawn(function()
    while task.wait() do
        xpcall(function()
            if _G.Auto_SellItem and type(_G.Select_SellItem) == "table" then
                for ItemName, Selected in pairs(_G.Select_SellItem) do
                    local Data = Economy[ItemName]
                    if Selected and Data and GetItemAmount(ItemName) >= Data.amount then
                        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Economy", ItemName)
                    end
                end
            end
        end, print)
    end
end)

task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_Haki then
                if not LocalPlayer.Character:FindFirstChild("HakiFolder") then
                    ReplicatedStorage.Remotes.Action:FireServer("Misc", "buso")
                end
            end
        end)
    end
end)

-- ===== AUTO SKILL LOOP =====
task.spawn(function()
    while task.wait(0.1) do
        if _G.Auto_Farm_Level or _G.Auto_Farm_Material or _G.Auto_FarmBoss 
           or _G.Auto_FarmBoss_Automatically or _G.Auto_Duck or _G.Auto_DuckAutomatically
           or _G.Auto_Piccolo or _G.Auto_DevilBoat or _G.Auto_CraftWeapon
           or _G.Auto_Farm_Set or _G.Auto_Raid or _G.Auto_BaconThief or _G.Auto_Dungeon then
            pcall(function()
                AutoSkill()
            end)
        end
    end
end)

-- ===== AUTO POTION =====
task.spawn(function()
    while task.wait(0.3) do
        if _G.Auto_Use_Potion then
            pcall(function()
                local Inv = ReplicatedStorage.Remotes.Inventory
                local Select = _G.Select_Potion
                if not Select then return end
                if Select["X2 EXP 15min."] and tonumber(LocalPlayer:GetAttribute("x2ExpTime")) == 0 then
                    Inv:FireServer("X2 EXP 15min.")
                end
                if Select["X2 Diamond 15min."] and tonumber(LocalPlayer:GetAttribute("x2DiamondTime")) == 0 then
                    Inv:FireServer("X2 Diamond 15min.")
                end
                if Select["X2 Lucky 15min."] and tonumber(LocalPlayer:GetAttribute("x2LuckTime")) == 0 then
                    Inv:FireServer("X2 Lucky 15min.")
                end
                if Select["X2 Rebirth 15min."] and tonumber(LocalPlayer:GetAttribute("x2RebirthTime")) == 0 then
                    Inv:FireServer("X2 Rebirth 15min.")
                end
                if Select["X2 Item 15min."] and tonumber(LocalPlayer:GetAttribute("x2ItemTime")) == 0 then
                    Inv:FireServer("X2 Item 15min.")
                end
            end)
        end
    end
end)

-- ===== AUTO EQUIP ACCESSORY =====
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if not _G.Auto_Equip_Accessory then return end
            local Inventory = HttpService:JSONDecode(LocalPlayer:GetAttribute("Inventory") or "{}")
            local Equipped = HttpService:JSONDecode(LocalPlayer:GetAttribute("UseAccessory") or "{}")
            local Best = {}
            for Name in pairs(Inventory) do
                local Info = AccessoryModule[Name]
                if Info then
                    local Score = 0
                    for _, Value in pairs(Info) do
                        if type(Value) == "number" then Score = Score + Value end
                    end
                    if not Best[Info.Type] or Score > Best[Info.Type].Score then
                        Best[Info.Type] = {Name = Name, Score = Score}
                    end
                end
            end
            for Type, Data in pairs(Best) do
                local EquippedName
                for Name, Info in pairs(Equipped) do
                    if Info.Type == Type then EquippedName = Name; break end
                end
                if EquippedName ~= Data.Name then
                    ReplicatedStorage.Remotes.Inventory:FireServer(Data.Name)
                    task.wait(0.5)
                end
            end
        end)
    end
end)

-- ===== AUTO REBIRTH =====
task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_Rebirth then
                if LocalPlayer.PlayerGui.HUD.Main.Frame_Display.LevelText.Text:lower():find("max") then
                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Rebirth")
                end
            end
        end)
    end
end)

-- ===== GUARANTEE AUTO BUY =====
task.spawn(function()
    while task.wait() do
        if _G.Auto_Guarantee_Moon then
            local Point = tonumber(LocalPlayer:GetAttribute("MoonPoint")) or 0
            local Price = PointItemMoon[_G.Select_Guarantee_Moon] or 0
            if _G.Select_Guarantee_Moon and Point >= Price then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "BuyGaranteeEventMoon", _G.Select_Guarantee_Moon)
            end
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if _G.Auto_Guarantee then
            local Point = tonumber(LocalPlayer:GetAttribute("PointItem")) or 0
            local Price = PointItemM[_G.Select_Guarantee] or 0
            if _G.Select_Guarantee and Point >= Price then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "BuyGaranteeRandomItem", _G.Select_Guarantee)
            end
        end
    end
end)

-- ===== GOKU LOOP =====
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local npcs = ScanGokuNPCs()
            RenderGokuCurrent(npcs)
            if _G.AutoGokuTP and #npcs > 0 then
                local npc = npcs[1]
                if npc.Model and npc.Model.Parent then
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.CFrame = CFrame.new(npc.Position + Vector3.new(0, 5, 0)) end
                end
            end
            if _G.AutoGokuFind and #npcs > 0 then
                for _, npc in ipairs(npcs) do
                    if npc.HasPrompt then
                        ClickGokuNPC(npc)
                        task.wait(1)
                        break
                    end
                end
            end
        end)
    end
end)

-- ===== SHOP DUNGEON LOOPS =====
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local ptAttr = LocalPlayer:GetAttribute("DungeonPoint") or 0
            ShopDunInfoPara:SetTitle("DungeonPoint: " .. tostring(ptAttr))

            -- Quét item thật + update dropdown
            local items = GetAllShopDunItems()
            if #items > 0 then
                UpdateDunDropdown(items)
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if _G.AutoBuyDunRunning and _G.AutoBuyDunItem then
            pcall(function()
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "BuyDungeonShop", _G.AutoBuyDunItem)
                task.wait(0.3)
            end)
        end
    end
end)

-- ===== SHOP RAID LOOP (quét item thật + update info) =====
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            if not hud or not hud:FindFirstChild("Main") then return end
            local shop = hud.Main:FindFirstChild("Frame_ShopRaid")
            if not shop then return end

            -- Update RaidPoint
            local rpLbl = shop:FindFirstChild("RaidPoint")
            local resetLbl = shop:FindFirstChild("Reset")
            if rpLbl and resetLbl then
                ShopInfoPara:SetTitle(rpLbl.Text)
                ShopInfoPara:SetContent(resetLbl.Text)
            end

            -- Quét item thật từ shop
            local sf = shop:FindFirstChild("ScrollingFrame")
            if sf then
                local items = {}
                for _, item in pairs(sf:GetChildren()) do
                    if item:IsA("Frame") then
                        local label = item:FindFirstChild("Label")
                        if label and label.Text and label.Text ~= "" and label.Text ~= "Item" then
                            table.insert(items, label.Text)
                        end
                    end
                end
                if #items > 0 then
                    table.sort(items)
                    UpdateShopDropdown(items)
                end
            end
        end)
    end
end)

-- ===== AUTO FARM LOOPS =====
task.spawn(function()
    while wait() do
        xpcall(function()
            if not _G.Auto_Farm_Level then return end
            local quest = GetQuest_Level(tonumber(LocalPlayer:GetAttribute("Level")))
            if not quest then return end
            local Frame = GetQuestFrame()
            local Text = Frame.Title.Text or ""
            if LocalPlayer.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
            end
            if Frame.Visible and not string.find(Text, quest.Monster) then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                repeat task.wait() until not Frame.Visible
            end
            if not Frame.Visible then
                local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
                if npc then
                    Teleport(npc.CFrame * MethodFarm)
                    task.wait(0.3)
                    local prompt = npc:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then fireproximityprompt(prompt) end
                end
            else
                for _, v in pairs(workspace.Mob:GetChildren()) do
                    if v:IsA("Model") and v.Name == quest.Monster and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        local hrp = v:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0
                            repeat task.wait()
                                EquipWeapon()
                                AutoSkill()
                                Attack()
                                Teleport(hrp.CFrame * MethodFarm)
                            until not _G.Auto_Farm_Level or v.Humanoid.Health <= 0
                        end
                        break
                    end
                end
            end
        end, print)
    end
end)

-- ===== AUTO FARM MATERIAL =====
task.spawn(function()
    while task.wait() do
        xpcall(function()
            if not _G.Auto_Farm_Material then return end
            if type(_G.Select_Material) ~= "table" then return end
            for Material in pairs(_G.Select_Material) do
                local MobNames = ItemDrop[Material]
                if MobNames then
                    for _, MobName in ipairs(MobNames) do
                        local Target
                        for _, Mob in ipairs(workspace.Mob:GetChildren()) do
                            if Mob:IsA("Model") and Mob.Name == MobName and Mob:FindFirstChild("Humanoid") and Mob.Humanoid.Health > 0 then
                                Target = Mob
                                break
                            end
                        end
                        if not Target then
                            local Spawn = workspace.Itemdrops:FindFirstChild(MobName)
                            if Spawn then
                                Teleport(Spawn:GetPivot())
                                task.wait(1.5)
                            end
                        else
                            local HRP = Target.HumanoidRootPart
                            Target.Humanoid.WalkSpeed = 0
                            Target.Humanoid.JumpPower = 0
                            local Start = tick()
                            repeat task.wait()
                                EquipWeapon()
                                AutoSkill()
                                Attack()
                                Teleport(HRP.CFrame * MethodFarm)
                            until not _G.Auto_Farm_Material or Target.Parent == nil or Target.Humanoid.Health <= 0 or tick() - Start >= 10
                        end
                    end
                end
            end
        end, warn)
    end
end)

-- ===== AUTO FARM BOSS =====
task.spawn(function()
    while task.wait() do
        if _G.Auto_FarmBoss then
            pcall(function()
                for _, v in pairs(workspace.Boss:GetChildren()) do
                    if table.find(Bosses, v.Name) and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        v.Humanoid.WalkSpeed = 0
                        v.Humanoid.JumpPower = 0
                        repeat task.wait()
                            EquipWeapon()
                            AutoSkill()
                            Attack()
                            Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
                        until not _G.Auto_FarmBoss or not v.Parent or v.Humanoid.Health <= 0
                    end
                end
            end)
        end
    end
end)

-- ===== AUTO PICCOLO =====
task.spawn(function()
    while task.wait() do
        if _G.Auto_Piccolo then
            pcall(function()
                if workspace.Mob:FindFirstChild("Piccolo") then
                    for _, v in pairs(workspace.Mob:GetChildren()) do
                        if v:IsA("Model") and v.Name == "Piccolo" and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0
                            repeat task.wait()
                                EquipWeapon()
                                AutoSkill()
                                Attack()
                                Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
                            until not _G.Auto_Piccolo or not v.Parent or v.Humanoid.Health <= 0
                        end
                    end
                end
            end)
        end
    end
end)

-- ===== AUTO DUCK =====
task.spawn(function()
    while task.wait() do
        if _G.Auto_Duck then
            pcall(function()
                if workspace.Mob:FindFirstChild("Duck Monster") then
                    for _, v in pairs(workspace.Mob:GetChildren()) do
                        if v:IsA("Model") and v.Name == "Duck Monster" and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0
                            repeat task.wait()
                                EquipWeapon()
                                AutoSkill()
                                Attack()
                                Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
                            until not _G.Auto_Duck or not v.Parent or v.Humanoid.Health <= 0
                        end
                    end
                end
            end)
        end
    end
end)

-- ===== AUTO DEVIL BOAT =====
task.spawn(function()
    while task.wait() do
        if _G.Auto_DevilBoat then
            pcall(function()
                for _, v in pairs(workspace.Mob:GetChildren()) do
                    if v:IsA("Model") and (v.Name == "Devil Boat" or v.Name == "DevilBoat") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        v.Humanoid.WalkSpeed = 0
                        v.Humanoid.JumpPower = 0
                        repeat task.wait()
                            EquipWeapon()
                            AutoSkill()
                            Attack()
                            Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
                        until not _G.Auto_DevilBoat or not v.Parent or v.Humanoid.Health <= 0
                        break
                    end
                end
            end)
        end
    end
end)

-- ===== AUTO CRAFT WEAPON =====
task.spawn(function()
    while task.wait() do
        xpcall(function()
            if not _G.Auto_CraftWeapon then return end
            NotifyClass = false
            local Monster = GetNeedMonster()
            if not Monster then
                local Data = UseItems[_G.Select_Item]
                if Data then
                    if Data.NeedClass then
                        local PlayerClass = LocalPlayer:GetAttribute("UseClass")
                        if PlayerClass ~= Data.NeedClass then
                            if not NotifyClass then
                                NotifyClass = true
                                _G.SeaNotify("Thiếu class: " .. Data.NeedClass, "Bạn không có class này", 5)
                            end
                            return
                        end
                    end
                    NotifyClass = false
                    if tick() - LastCraft >= CraftDelay then
                        LastCraft = tick()
                        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Craft", _G.Select_Item, Data.Type)
                    end
                end
                return
            end
            local TargetMob
            for _, Mob in ipairs(workspace.Mob:GetChildren()) do
                if Mob:IsA("Model") and Mob.Name == Monster and Mob:FindFirstChild("Humanoid") and Mob.Humanoid.Health > 0 then
                    TargetMob = Mob
                    break
                end
            end
            if not TargetMob then
                local Spawn = workspace.Itemdrops:FindFirstChild(Monster)
                if Spawn then Teleport(Spawn:GetPivot()) end
                return
            end
            local HRP = TargetMob:FindFirstChild("HumanoidRootPart")
            if HRP then
                TargetMob.Humanoid.WalkSpeed = 0
                TargetMob.Humanoid.JumpPower = 0
                repeat task.wait()
                    EquipWeapon()
                    AutoSkill()
                    Attack()
                    Teleport(HRP.CFrame * MethodFarm)
                until not _G.Auto_CraftWeapon or TargetMob.Humanoid.Health <= 0 or GetNeedMonster() ~= Monster
            end
        end, print)
    end
end)

-- ===== AUTO FARM SET =====
task.spawn(function()
    while task.wait() do
        if _G.Auto_Farm_Set then
            pcall(function()
                local Data = UseItems[_G.Select_Item]
                if not Data then return end
                local Inv = GetInventory()
                local NeedFarmItem = nil
                local LowestSet = math.huge
                for Item, Need in pairs(Data.Inventory) do
                    if not UseItems[Item] then
                        local Have = Inv[Item] and Inv[Item].amount or 0
                        local Set = math.floor(Have / Need)
                        if Set < LowestSet then
                            LowestSet = Set
                            NeedFarmItem = Item
                        end
                    end
                end
                if not NeedFarmItem then return end
                local NeedAmount = Data.Inventory[NeedFarmItem]
                local Have = Inv[NeedFarmItem] and Inv[NeedFarmItem].amount or 0
                if Have >= (LowestSet + 1) * NeedAmount then return end
                local MobNames = ItemDrop[NeedFarmItem]
                if not MobNames then return end
                for _, MobName in ipairs(MobNames) do
                    local Target
                    for _, Mob in ipairs(workspace.Mob:GetChildren()) do
                        if Mob:IsA("Model") and Mob.Name == MobName and Mob:FindFirstChild("Humanoid") and Mob.Humanoid.Health > 0 then
                            Target = Mob
                            break
                        end
                    end
                    if Target then
                        local HRP = Target.HumanoidRootPart
                        Target.Humanoid.WalkSpeed = 0
                        Target.Humanoid.JumpPower = 0
                        repeat task.wait()
                            EquipWeapon()
                            AutoSkill()
                            Attack()
                            Teleport(HRP.CFrame * MethodFarm)
                            Inv = GetInventory()
                            Have = Inv[NeedFarmItem] and Inv[NeedFarmItem].amount or 0
                        until not _G.Auto_Farm_Set or not Target.Parent or Target.Humanoid.Health <= 0 or Have >= ((LowestSet + 1) * NeedAmount)
                        break
                    else
                        local Spawn = workspace.Itemdrops:FindFirstChild(MobName)
                        if Spawn then
                            Teleport(Spawn:GetPivot())
                            task.wait(1.5)
                            break
                        end
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- BỔ SUNG: AUTO RAID BOSS v17
-- ============================================================
_G.RaidWaitingClear = false
_G.RaidDying = false

task.spawn(function()
    print("[AutoRaid] ✅ task.spawn v17 đã khởi động!")
    while task.wait(0.3) do
        if _G.AutoRaidRunning then
            local Data = RaidBossData and RaidBossData[_G.AutoRaidWho]
            if Data and Data.Valid then
                pcall(function()
                    local char = LocalPlayer.Character
                    local hum = char and char:FindFirstChild("Humanoid")
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hum or not hrp then return end

                    if hum.Health <= 0 then
                        if not _G.RaidDying then
                            _G.RaidDying = true
                            _G.RaidWaitingClear = true
                            print("[AutoRaid] Nhân vật chết → đợi boss biến mất...")
                            for _, name in ipairs({"AutoRaidBP", "AutoRaidAP", "AutoRaidAO", "AutoRaidAtt"}) do
                                if hrp:FindFirstChild(name) then hrp[name]:Destroy() end
                            end
                        end
                        return
                    else
                        _G.RaidDying = false
                    end

                    local bf = workspace:FindFirstChild("Boss Fight")
                    local baconFolder = bf and bf:FindFirstChild("Bacon of Grudge")

                    if _G.RaidWaitingClear then
                        if baconFolder then
                            print("[AutoRaid] Đợi boss biến mất...")
                            task.wait(1)
                            return
                        else
                            print("[AutoRaid] Boss biến mất, mở raid mới!")
                            _G.RaidWaitingClear = false
                            task.wait(1)
                        end
                    end

                    if baconFolder then
                        local function TeleportTo(targetPart, offsetY, offsetX)
                            if not hrp or not hrp.Parent or not targetPart then return end
                            if hrp:FindFirstChild("AutoRaidBP") then hrp.AutoRaidBP:Destroy() end
                            if hrp:FindFirstChild("AutoRaidAP") then hrp.AutoRaidAP:Destroy() end
                            local targetPos = targetPart.Position + Vector3.new(offsetX or 0, offsetY or 25, 0)
                            local targetCF = CFrame.new(targetPos, targetPart.Position)
                            hrp.CFrame = targetCF
                            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                        end

                        local function CleanupBP()
                            for _, name in ipairs({"AutoRaidBP", "AutoRaidAP", "AutoRaidAO", "AutoRaidAtt"}) do
                                if hrp:FindFirstChild(name) then hrp[name]:Destroy() end
                            end
                        end

                        local function AttackTarget(targetPart, targetModel, offsetY, offsetX)
                            if not targetPart or not targetModel then return end
                            if not targetModel:FindFirstChild("Humanoid") then return end
                            if targetModel.Humanoid.Health <= 0 then return end

                            targetModel.Humanoid.WalkSpeed = 0
                            targetModel.Humanoid.JumpPower = 0

                            repeat task.wait(0.03)
                                if not _G.AutoRaidRunning then break end
                                if not targetModel.Parent then break end
                                if targetModel.Humanoid.Health <= 0 then break end
                                if hum.Health <= 0 then break end
                                if not targetPart.Parent then break end
                                TeleportTo(targetPart, offsetY, offsetX)
                                EquipWeapon()
                                AutoSkill()
                                Attack()
                            until false
                            CleanupBP()
                        end

                        -- Ball 1
                        local A1 = baconFolder:FindFirstChild("ArmorBall1")
                        if A1 and A1:FindFirstChild("Humanoid") and A1.Humanoid.Health > 0 then
                            print("[AutoRaid] Đánh ArmorBall1")
                            AttackTarget(A1:FindFirstChild("HumanoidRootPart"), A1, _G.RaidBallOffsetY or 25, 0)
                        end

                        -- Ball 2
                        local A2 = baconFolder:FindFirstChild("ArmorBall2")
                        if _G.AutoRaidRunning and A2 and A2:FindFirstChild("Humanoid") and A2.Humanoid.Health > 0 then
                            print("[AutoRaid] Đánh ArmorBall2")
                            AttackTarget(A2:FindFirstChild("HumanoidRootPart"), A2, _G.RaidBallOffsetY or 25, 0)
                        end

                        -- Boss
                        local BossBacon = baconFolder:FindFirstChild("Boss Bacon Sad")
                        if _G.AutoRaidRunning and BossBacon and BossBacon:FindFirstChild("Humanoid") and BossBacon.Humanoid.Health > 0 then
                            local bossHrp = BossBacon:FindFirstChild("HumanoidRootPart")
                            if bossHrp then
                                print("[AutoRaid] Đánh Boss Bacon Sad")
                                AttackTarget(bossHrp, BossBacon, _G.RaidBossOffsetY or 55, 5)
                            end
                        end

                        if _G.AutoRaidRunning then task.wait(2) end
                    else
                        print("[AutoRaid] Chưa vào map")
                        for _, name in ipairs({"AutoRaidBP", "AutoRaidAP", "AutoRaidAO", "AutoRaidAtt"}) do
                            if hrp:FindFirstChild(name) then hrp[name]:Destroy() end
                        end

                        local TPZone = workspace:FindFirstChild("TeleportBossFightZone")
                        if TPZone and TPZone:FindFirstChild("Hitbox") then
                            print("[AutoRaid] Vào portal (đợi vô hạn)")
                            local Hitbox = TPZone.Hitbox
                            hrp.Anchored = true
                            local LastPrint = 0
                            repeat task.wait(0.1)
                                if not _G.AutoRaidRunning then break end
                                if hrp.Parent then
                                    hrp.CFrame = Hitbox.CFrame
                                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                end
                                if tick() - LastPrint > 3 then
                                    LastPrint = tick()
                                    print("[AutoRaid] Đang đợi portal teleport...")
                                end
                                if not TPZone.Parent then
                                    print("[AutoRaid] Cổng biến mất, thoát loop")
                                    break
                                end
                                if workspace:FindFirstChild("Boss Fight") then
                                    print("[AutoRaid] Đã vào map!")
                                    break
                                end
                            until false
                            hrp.Anchored = false
                            if workspace:FindFirstChild("Boss Fight") then
                                print("[AutoRaid] Đã vào map, đợi 3s...")
                                task.wait(3)
                            else
                                task.wait(1)
                            end
                        else
                            if GetItemAmount("Portal Gun") < Data.PortalCost then
                                _G.SeaNotify("❌ Không đủ Portal Gun", "Cần " .. Data.PortalCost .. " Portal Gun!", 4)
                                _G.AutoRaidRunning = false
                                return
                            end

                            print("[AutoRaid] Fire SpawnBossFight: " .. Data.Name)
                            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "SpawnBossFight", Data.Name)
                            task.wait(2)

                            local TPZone2 = workspace:FindFirstChild("TeleportBossFightZone")
                            if TPZone2 and TPZone2:FindFirstChild("Hitbox") then
                                print("[AutoRaid] Portal xuất hiện, vào Hitbox!")
                                local Hitbox2 = TPZone2.Hitbox
                                hrp.Anchored = true
                                local LastPrint2 = 0
                                repeat task.wait(0.1)
                                    if not _G.AutoRaidRunning then break end
                                    if hrp.Parent then
                                        hrp.CFrame = Hitbox2.CFrame
                                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                    end
                                    if tick() - LastPrint2 > 3 then
                                        LastPrint2 = tick()
                                        print("[AutoRaid] Đang đợi portal teleport...")
                                    end
                                    if not TPZone2.Parent then
                                        print("[AutoRaid] Cổng biến mất, thoát loop")
                                        break
                                    end
                                    if workspace:FindFirstChild("Boss Fight") then
                                        print("[AutoRaid] Đã vào map!")
                                        break
                                    end
                                until false
                                hrp.Anchored = false
                                if workspace:FindFirstChild("Boss Fight") then
                                    print("[AutoRaid] Đã vào map, đợi 3s...")
                                    task.wait(3)
                                else
                                    task.wait(1)
                                end
                            else
                                task.wait(2)
                            end
                        end
                    end
                end)
            end
        end
    end
end)

-- Cleanup khi tắt raid
task.spawn(function()
    while task.wait(0.5) do
        if not _G.AutoRaidRunning then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, name in ipairs({"AutoRaidBP", "AutoRaidAP", "AutoRaidAO", "AutoRaidAtt"}) do
                    if hrp:FindFirstChild(name) then hrp[name]:Destroy() end
                end
                if hrp.Anchored and not workspace:FindFirstChild("Boss Fight") then
                    hrp.Anchored = false
                end
            end
        end
    end
end)

-- ============================================================
-- BỔ SUNG: AUTO DUNGEON (full logic)
-- ============================================================
task.spawn(function()
    while task.wait() do
        xpcall(function()
            if not _G.Auto_Dungeon then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChild("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end

            -- Check HP thấp → bay lên trời
            local HpPercent = (hum.Health / hum.MaxHealth) * 100
            if HpPercent < _G.HealthPercent then
                hrp.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y + 200, hrp.Position.Z)
                task.wait(0.5)
                return
            end

            local Dungeon
            local DungeonId = char:GetAttribute("Dungeon")
            local GuiService = game:GetService("GuiService")
            local VirtualInputManager = game:GetService("VirtualInputManager")

            -- Auto skip wave
            if LocalPlayer.PlayerGui:FindFirstChild("WaveUI") and LocalPlayer.PlayerGui.WaveUI.AutoSkip.BackgroundColor3 == Color3.fromRGB(255, 69, 69) then
                GuiService.SelectedObject = LocalPlayer.PlayerGui.WaveUI.AutoSkip
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                task.wait(0.1)
                GuiService.SelectedObject = nil
            end

            if DungeonId then
                Dungeon = workspace.DungeonMap:FindFirstChild("Dungeon_" .. DungeonId)
            end

            if Dungeon then
                -- Tìm mob gần nhất
                local Target, MinDist = nil, math.huge
                for _, Mob in ipairs(workspace.Mob:GetChildren()) do
                    if Mob:IsA("Model") and Mob:FindFirstChild("Humanoid") and Mob:FindFirstChild("HumanoidRootPart") and Mob.Humanoid.Health > 0 then
                        local dist = (Mob.HumanoidRootPart.Position - Dungeon:GetPivot().Position).Magnitude
                        if dist <= 250 and dist < MinDist then
                            MinDist = dist
                            Target = Mob
                        end
                    end
                end

                if Target then
                    local tHrp = Target.HumanoidRootPart
                    Target.Humanoid.WalkSpeed = 0
                    Target.Humanoid.JumpPower = 0

                    local bp = hrp:FindFirstChild("DungeonBP")
                    if not bp then
                        bp = Instance.new("BodyPosition")
                        bp.Name = "DungeonBP"
                        bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bp.P = 100000
                        bp.D = 3000
                        bp.Parent = hrp
                    end

                    local targetPos = tHrp.Position + Vector3.new(0, _G.DungeonHeight or 25, 0)
                    bp.Position = targetPos
                    hrp.CFrame = CFrame.new(targetPos, tHrp.Position)

                    EquipWeapon()
                    AutoSkill()
                    Attack()
                else
                    if hrp:FindFirstChild("DungeonBP") then
                        hrp.DungeonBP:Destroy()
                    end
                end
            else
                -- Chưa vào dungeon
                local TeleportZone = workspace:FindFirstChild("TeleportDungeonZone")
                if TeleportZone and TeleportZone:FindFirstChild("Hitbox") then
                    hrp.CFrame = TeleportZone.Hitbox.CFrame
                else
                    if GetItemAmount("Orb Dungeon") >= _G.Dungeon_UseValue then
                        local NPC = workspace.NpcPrompt["Open Dungeon"].HumanoidRootPart
                        hrp.CFrame = NPC.CFrame * CFrame.new(0, 5, 0)
                        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "SpawnDungeon", _G.Dungeon_UseValue)
                    else
                        local Diamond = LocalPlayer:GetAttribute("Diamond") or 0
                        if Diamond >= 150 then
                            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "RandomItem", "x15")
                        else
                            local quest = GetQuest_Level(tonumber(LocalPlayer:GetAttribute("Level")))
                            if not quest then return end
                            local Frame = GetQuestFrame()
                            local Text = Frame.Title.Text or ""
                            if LocalPlayer.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
                                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                            end
                            if Frame.Visible and not string.find(Text, quest.Monster) then
                                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                                repeat task.wait() until not Frame.Visible
                            end
                            if not Frame.Visible then
                                local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
                                if npc then
                                    hrp.CFrame = npc.CFrame * MethodFarm
                                    task.wait(0.3)
                                    local pro = npc:FindFirstChildOfClass("ProximityPrompt")
                                    if pro then fireproximityprompt(pro) end
                                end
                            else
                                for _, v in ipairs(workspace.Mob:GetChildren()) do
                                    if v:IsA("Model") and v.Name == quest.Monster and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                                        v.Humanoid.WalkSpeed = 0
                                        v.Humanoid.JumpPower = 0
                                        hrp.CFrame = v.HumanoidRootPart.CFrame * MethodFarm
                                        EquipWeapon()
                                        AutoSkill()
                                        Attack()
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end, print)
    end
end)

-- ============================================================
-- BỔ SUNG: AUTO DUCK FULL
-- ============================================================
task.spawn(function()
    while task.wait() do
        if _G.Auto_DuckAutomatically then
            pcall(function()
                if workspace.Mob:FindFirstChild("Duck Monster") then
                    for _, v in pairs(workspace.Mob:GetChildren()) do
                        if v:IsA("Model") and v.Name == "Duck Monster" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0
                            repeat task.wait()
                                EquipWeapon()
                                AutoSkill()
                                Attack()
                                Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
                            until not _G.Auto_DuckAutomatically or not v.Parent or v.Humanoid.Health <= 0
                            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                        end
                    end
                else
                    if workspace.Itemdrops:FindFirstChild("Duck Monster") then
                        Teleport(workspace.Itemdrops:FindFirstChild("Duck Monster").CFrame)
                    else
                        local DuckItems = {"Duck", "Duck2", "Duck3", "Duck4", "Duck5", "Duck6", "Duck7"}
                        local HaveAll = true
                        for _, Item in ipairs(DuckItems) do
                            if GetItemAmount(Item) <= 0 then
                                HaveAll = false
                                break
                            end
                        end
                        if HaveAll then
                            local Point = tonumber(LocalPlayer:GetAttribute("PointItem")) or 0
                            if Point > 750 and GetItemAmount("Duck6") <= 0 then
                                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "BuyGaranteeRandomItem", "Duck6")
                            elseif Point > 850 and GetItemAmount("Duck7") <= 0 then
                                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "BuyGaranteeRandomItem", "Duck7")
                            else
                                Teleport(workspace.NpcPrompt.DuckMonster.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0))
                                fireproximityprompt(workspace.NpcPrompt.DuckMonster.HumanoidRootPart:FindFirstChildOfClass("ProximityPrompt"))
                            end
                        else
                            local Diamond = LocalPlayer:GetAttribute("Diamond") or 0
                            if Diamond >= 150 then
                                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "RandomItem", "x15")
                            else
                                local quest = GetQuest_Level(tonumber(LocalPlayer:GetAttribute("Level")))
                                if not quest then return end
                                local Frame = GetQuestFrame()
                                local Text = Frame.Title.Text or ""
                                if LocalPlayer.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
                                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                                end
                                if Frame.Visible and not string.find(Text, quest.Monster) then
                                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                                    repeat task.wait() until not Frame.Visible
                                end
                                if not Frame.Visible then
                                    local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
                                    if npc then
                                        Teleport(npc.CFrame * CFrame.new(0, 5, 0))
                                        task.wait(0.3)
                                        local pro_xim = npc:FindFirstChildOfClass("ProximityPrompt")
                                        if pro_xim then fireproximityprompt(pro_xim) end
                                    end
                                else
                                    for _, v in pairs(workspace.Mob:GetChildren()) do
                                        if v:IsA("Model") and v.Name == quest.Monster and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                                            local hrp = v:FindFirstChild("HumanoidRootPart")
                                            if hrp then
                                                v.Humanoid.WalkSpeed = 0
                                                v.Humanoid.JumpPower = 0
                                                repeat task.wait()
                                                    EquipWeapon()
                                                    AutoSkill()
                                                    Attack()
                                                    Teleport(hrp.CFrame * MethodFarm)
                                                until not _G.Auto_DuckAutomatically or v.Humanoid.Health <= 0
                                            end
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- BỔ SUNG: AUTO FARM BOSS FULL
-- ============================================================
task.spawn(function()
    while task.wait() do
        if _G.Auto_FarmBoss_Automatically then
            pcall(function()
                if workspace.Boss:FindFirstChildOfClass("Model") then
                    for _, v in pairs(workspace.Boss:GetChildren()) do
                        if table.find(Bosses, v.Name) and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0
                            repeat
                                task.wait()
                                EquipWeapon()
                                AutoSkill()
                                Attack()
                                Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
                            until not _G.Auto_FarmBoss_Automatically or not v.Parent or v.Humanoid.Health <= 0
                            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                        end
                    end
                else
                    if GetItemAmount("Orb Boss") >= 1 then
                        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "SummonBoss", _G.Select_Boss)
                    else
                        local Diamond = LocalPlayer:GetAttribute("Diamond") or 0
                        if Diamond >= 150 then
                            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "RandomItem", "x15")
                        else
                            local quest = GetQuest_Level(tonumber(LocalPlayer:GetAttribute("Level")))
                            if not quest then return end
                            local Frame = GetQuestFrame()
                            local Text = Frame.Title.Text or ""
                            if LocalPlayer.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
                                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                            end
                            if Frame.Visible and not string.find(Text, quest.Monster) then
                                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                                repeat task.wait() until not Frame.Visible
                            end
                            if not Frame.Visible then
                                local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
                                if npc then
                                    Teleport(npc.CFrame * MethodFarm)
                                    task.wait(0.3)
                                    local pro_xim = npc:FindFirstChildOfClass("ProximityPrompt")
                                    if pro_xim then fireproximityprompt(pro_xim) end
                                end
                            else
                                for _, v in pairs(workspace.Mob:GetChildren()) do
                                    if v:IsA("Model") and v.Name == quest.Monster and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                                        local hrp = v:FindFirstChild("HumanoidRootPart")
                                        if hrp then
                                            v.Humanoid.WalkSpeed = 0
                                            v.Humanoid.JumpPower = 0
                                            repeat task.wait()
                                                EquipWeapon()
                                                AutoSkill()
                                                Attack()
                                                Teleport(hrp.CFrame * MethodFarm)
                                            until not _G.Auto_FarmBoss_Automatically or v.Humanoid.Health <= 0
                                        end
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- BỔ SUNG: AUTO BACON THIEF
-- ============================================================
local CurrentSpawn = 1
task.spawn(function()
    while task.wait() do
        pcall(function()
            if not _G.Auto_BaconThief then return end
            local Spawns = workspace.MobSpawnGroup:GetChildren()
            local Spawn = Spawns[CurrentSpawn]
            if not Spawn then
                CurrentSpawn = 1
                return
            end
            local ChestRef = Spawn:FindFirstChild("ChestRef", true)
            if ChestRef then
                local Target
                local Distance = 30
                for _, Mob in ipairs(workspace.Mob:GetChildren()) do
                    if Mob:IsA("Model") and Mob.Name == "Bacon Thief" and Mob:FindFirstChild("HumanoidRootPart") and Mob:FindFirstChild("Humanoid") and Mob.Humanoid.Health > 0 then
                        local Mag = (Mob.HumanoidRootPart.Position - ChestRef.Position).Magnitude
                        if Mag < Distance then
                            Distance = Mag
                            Target = Mob
                        end
                    end
                end
                if Target then
                    Target.Humanoid.WalkSpeed = 0
                    Target.Humanoid.JumpPower = 0
                    EquipWeapon()
                    AutoSkill()
                    Attack()
                    Teleport(Target.HumanoidRootPart.CFrame * MethodFarm)
                else
                    local Prompt = ChestRef:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if Prompt and Prompt.Parent and Prompt.ActionText == "Open" then
                        Teleport(ChestRef.CFrame * CFrame.new(0, 3, 0))
                        fireproximityprompt(Prompt)
                    else
                        CurrentSpawn = CurrentSpawn + 1
                    end
                end
            else
                CurrentSpawn = CurrentSpawn + 1
            end
        end)
    end
end)

-- ============================================================
-- BỔ SUNG: AUTO RAID MOON (Sea 1)
-- ============================================================
task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_Raid then
                if game.PlaceId == 82878101790702 then
                    for _, v in pairs(workspace.Mob:GetChildren()) do
                        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0
                            repeat task.wait()
                                EquipWeapon()
                                AutoSkill()
                                Attack()
                                Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
                            until not _G.Auto_Raid or not v.Parent or v.Humanoid.Health <= 0
                        end
                    end
                else
                    if workspace:FindFirstChild("TeleportMoonZone") then
                        Teleport(workspace:FindFirstChild("TeleportMoonZone").Hitbox:GetPivot() * CFrame.new(0, -8, 0))
                    else
                        if GetItemAmount("Space Ticket") >= 1 then
                            Teleport(workspace.NpcPrompt.GoMoon.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0))
                            fireproximityprompt(workspace.NpcPrompt.GoMoon.HumanoidRootPart:FindFirstChildOfClass("ProximityPrompt"))
                        else
                            local Diamond = LocalPlayer:GetAttribute("Diamond") or 0
                            if Diamond >= 150 then
                                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "RandomItem", "x15")
                            else
                                local quest = GetQuest_Level(tonumber(LocalPlayer:GetAttribute("Level")))
                                if not quest then return end
                                local Frame = GetQuestFrame()
                                local Text = Frame.Title.Text or ""
                                if LocalPlayer.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
                                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                                end
                                if Frame.Visible and not string.find(Text, quest.Monster) then
                                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                                    repeat task.wait() until not Frame.Visible
                                end
                                if not Frame.Visible then
                                    local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
                                    if npc then
                                        Teleport(npc.CFrame * MethodFarm)
                                        task.wait(0.3)
                                        local pro_xim = npc:FindFirstChildOfClass("ProximityPrompt")
                                        if pro_xim then fireproximityprompt(pro_xim) end
                                    end
                                else
                                    for _, v in pairs(workspace.Mob:GetChildren()) do
                                        if v:IsA("Model") and v.Name == quest.Monster and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                                            local hrp = v:FindFirstChild("HumanoidRootPart")
                                            if hrp then
                                                v.Humanoid.WalkSpeed = 0
                                                v.Humanoid.JumpPower = 0
                                                repeat task.wait()
                                                    EquipWeapon()
                                                    AutoSkill()
                                                    Attack()
                                                    Teleport(hrp.CFrame * MethodFarm)
                                                until not _G.Auto_Raid or v.Humanoid.Health <= 0
                                            end
                                            break
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
-- BỔ SUNG: AUTO CLOSE REWARD GUI
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            if not hud or not hud:FindFirstChild("Main") then return end

            local closeList = {
                {_G.Auto_Dungeon, "Frame_DungeonItem"},
                {_G.AutoRaidRunning, "Frame_RaidbossItem"}
            }

            for _, entry in ipairs(closeList) do
                if entry[1] then
                    local fd = hud.Main:FindFirstChild(entry[2])
                    if fd and fd.Visible then
                        task.wait(2)
                        local closeBtn = fd:FindFirstChild("Close_")
                            or fd:FindFirstChild("Close")
                            or fd:FindFirstChild("CloseButton")
                            or fd:FindFirstChild("Exit")
                        if closeBtn then
                            pcall(function()
                                if firesignal then
                                    firesignal(closeBtn.MouseButton1Click)
                                else
                                    closeBtn:Activate()
                                end
                            end)
                            print("[AutoClose] Đã đóng:", entry[2])
                        else
                            fd.Visible = false
                            print("[AutoClose] Đã ẩn:", entry[2])
                        end
                    end
                end
            end
        end)
    end
end)

-- ============================================================
-- BỔ SUNG: CRAFT TABLE LOOP + AUTO CLAIM
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        if _G.AutoCraftRunning and _G.SelectedCraftItem then
            pcall(function()
                local Data = CraftingTable[_G.SelectedCraftItem]
                if not Data or not Data.need then return end
                local CanCraft = true
                for Item, Need in pairs(Data.need) do
                    if GetItemAmount(Item) < Need then
                        CanCraft = false
                        break
                    end
                end
                if CanCraft then
                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "CraftTable", _G.SelectedCraftItem, "Craft")
                    print("[AutoCraft] Craft:", _G.SelectedCraftItem)
                    task.wait(0.5)
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if _G.AutoClaimGuarantee and _G.SelectedCraftItem then
            pcall(function()
                local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                if not hud or not hud:FindFirstChild("Main") then return end
                local guar = hud.Main:FindFirstChild("Frame_Guarantee")
                if not guar then return end
                local sf = guar:FindFirstChild("ScrollingFrame")
                if not sf then return end
                local itemFrame = sf:FindFirstChild(_G.SelectedCraftItem)
                if itemFrame then
                    local main = itemFrame:FindFirstChild("Main")
                    if main then
                        local amtLbl = main:FindFirstChild("AmountLabel")
                        if amtLbl then
                            local txt = amtLbl.Text or ""
                            local cur = tonumber(txt:match("^(%d+)"))
                            local max = tonumber(txt:match("/(%d+)"))
                            if cur and max and cur >= max then
                                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "CraftTable", _G.SelectedCraftItem, "Guarantee")
                                print("[AutoClaim] Claim:", _G.SelectedCraftItem, txt)
                                task.wait(1)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- BỔ SUNG: UPDATE CRAFT INFO
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if not _G.SelectedCraftItem then return end
            local Data = CraftingTable[_G.SelectedCraftItem]
            if not Data or not Data.need then return end

            local ConsumText = ""
            local AvailText = ""
            for Item, Need in pairs(Data.need) do
                local Have = GetItemAmount(Item)
                ConsumText = ConsumText .. "\n  " .. Item .. " x" .. Need
                AvailText = AvailText .. "\n  " .. Item .. " " .. Have
            end

            local CraftedText = "0/2"
            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            if hud and hud:FindFirstChild("Main") then
                local guar = hud.Main:FindFirstChild("Frame_Guarantee")
                if guar then
                    local sf = guar:FindFirstChild("ScrollingFrame")
                    if sf then
                        local itemFrame = sf:FindFirstChild(_G.SelectedCraftItem)
                        if itemFrame then
                            local main = itemFrame:FindFirstChild("Main")
                            if main then
                                local amtLbl = main:FindFirstChild("AmountLabel")
                                if amtLbl then CraftedText = amtLbl.Text end
                            end
                        end
                    end
                end
            end

            CraftInfoPara:SetTitle("Items: " .. _G.SelectedCraftItem)
            CraftInfoPara:SetContent(
                "Consumables: " .. (ConsumText ~= "" and ConsumText or " ---") ..
                "\nCurrently Available: " .. (AvailText ~= "" and AvailText or " ---") ..
                "\nCrafted Item: " .. CraftedText
            )
        end)
    end
end)

-- ============================================================
-- BỔ SUNG: UPDATE ITEM REQUIREMENTS (Weapon Craft Info)
-- ============================================================
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            local Data = UseItems[_G.Select_Item]
            if not Data then return end
            local Inv = GetInventory()
            local HaveWeapon = Inv[_G.Select_Item] and (Inv[_G.Select_Item].amount or 0) > 0
            local Text = {}
            table.insert(Text, "Need Class : " .. (Data.NeedClass or "None"))
            table.insert(Text, "Need Beli : " .. tostring((Data.PlayerData and Data.PlayerData.Beli) or 0))
            local LowestSet = math.huge
            for Item, Need in pairs(Data.Inventory) do
                local Have = Inv[Item] and Inv[Item].amount or 0
                local Set = math.floor(Have / Need)
                if Set < LowestSet then LowestSet = Set end
            end
            if LowestSet == math.huge then LowestSet = 0 end
            table.insert(Text, "Have Set : " .. LowestSet)
            table.insert(Text, "")
            for Item, Need in pairs(Data.Inventory) do
                local Have = Inv[Item] and Inv[Item].amount or 0
                local Set = math.floor(Have / Need)
                table.insert(Text, string.format("%s : %d/%d %s (Set : %d)",
                    Item, Have, Need, Have >= Need and "✅" or "❌", Set))
            end
            Item_Auto:SetTitle("Item Requirements \n( " .. (HaveWeapon and _G.Select_Item .. " ✅" or _G.Select_Item .. " ❌") .. " )")
            Item_Auto:SetContent(table.concat(Text, "\n"))
        end)
    end
end)

-- ============================================================
-- BỔ SUNG: NOCLIP + ANTI-GRAVITY
-- ============================================================
task.spawn(function()
    while task.wait() do
        if _G.Auto_Farm_Level or _G.Auto_CraftWeapon or _G.Auto_Farm_Material 
           or _G.Auto_FarmBoss_Automatically or _G.Auto_FarmBoss 
           or _G.Auto_DuckAutomatically or _G.Auto_Duck or _G.Auto_Farm_Set 
           or _G.Auto_Raid or _G.Auto_BaconThief or _G.Auto_Dungeon 
           or _G.Auto_Piccolo or _G.Auto_DevilBoat then
            pcall(function()
                local char = LocalPlayer.Character
                local HRP = char and char:FindFirstChild("HumanoidRootPart")
                if HRP then
                    HRP.AssemblyAngularVelocity = Vector3.zero
                    local Vel = HRP.AssemblyLinearVelocity
                    HRP.AssemblyLinearVelocity = Vector3.new(0, Vel.Y, 0)
                end
            end)
        end
    end
end)

task.spawn(function()
    pcall(function()
        RunService.Stepped:Connect(function()
            if _G.Auto_Farm_Level or _G.Auto_CraftWeapon or _G.Auto_Farm_Material 
               or _G.Auto_FarmBoss_Automatically or _G.Auto_FarmBoss 
               or _G.Auto_DuckAutomatically or _G.Auto_Duck or _G.Auto_Farm_Set 
               or _G.Auto_Raid or _G.Auto_BaconThief or _G.Auto_Dungeon 
               or _G.Auto_Piccolo or _G.Auto_DevilBoat then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if not hrp:FindFirstChild("BodyClip") then
                        local Noclip = Instance.new("BodyVelocity")
                        Noclip.Name = "BodyClip"
                        Noclip.Parent = hrp
                        Noclip.MaxForce = Vector3.new(100000, 100000, 100000)
                        Noclip.Velocity = Vector3.new(0, 0, 0)
                    end
                end
            else
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and hrp:FindFirstChild("BodyClip") then
                    hrp.BodyClip:Destroy()
                end
            end
        end)
    end)
end)

print("[Sea 1] ✅ Load thành công!")
