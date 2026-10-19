-- ============================================================
-- MAIN TAB MODULE
-- Chứa: Farm + Boss + Raid + Dungeon
-- ============================================================
return function(ctx)
    -- ===== LẤY DỮ LIỆU TỪ ctx =====
    local Window            = ctx.Window
    local Tab2              = ctx.Tab2
    local LocalPlayer       = ctx.LocalPlayer
    local ReplicatedStorage = ctx.ReplicatedStorage
    local HttpService       = ctx.HttpService

    local GetInventory      = ctx.GetInventory
    local GetItemAmount     = ctx.GetItemAmount
    local GetQuest_Level    = ctx.GetQuest_Level
    local GetQuestFrame     = ctx.GetQuestFrame
    local EquipWeapon       = ctx.EquipWeapon
    local AutoSkill         = ctx.AutoSkill
    local Attack            = ctx.Attack
    local Teleport          = ctx.Teleport
    local GetMethodFarm     = ctx.GetMethodFarm

    local ItemDrop          = ctx.ItemDrop
    local ItemAll           = ctx.ItemAll
    local Quest_List        = ctx.Quest_List
    local Bosses            = ctx.Bosses
    local WeaponAll         = ctx.WeaponAll
    local UseItems          = ctx.UseItems
    local CraftingTable     = ctx.CraftingTable
    local PointItemM        = ctx.PointItemM
    local PointItemMoon     = ctx.PointItemMoon
    local Economy           = ctx.Economy
    local SpawnList         = ctx.SpawnList

    local _G = ctx._G or _G
local Farm            = Tab2:CreatePage("Farm")
local AllBoss         = Tab2:CreatePage("Boss")
local RaidBossPage    = Tab2:CreatePage("Raid Boss & Shop")
local RaidDun         = Tab2:CreatePage("Dungeon, Shop / Weapon")

local Boss            = AllBoss:CreateSection("👹 Boss", "Left")
local Thief           = AllBoss:CreateSection("💸 Thief", "Left")
local Piccolo         = AllBoss:CreateSection("🐉 Piccolo", "Left")
local SpawnedT        = AllBoss:CreateSection("🔍 Spawned Check", "Right")
local Duck            = AllBoss:CreateSection("🦆 Duck", "Right")
local DevilBoat       = AllBoss:CreateSection("⛵ Devil Boat", "Right")
local Kraken         = AllBoss:CreateSection("🐙 Kraken","Left")
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

Boss:Dropdown({
    Title = "Select Boss", Options = Bosses, Multi = false,
    Callback = function(v) _G.Select_Boss = v end
})
Boss:Toggle({Title = "Auto Farm All Boss (Full)", Value = false, Callback = function(v) _G.Auto_FarmBoss = v end})
Thief:Toggle({Title = "Auto Farm Thief Chest", Value = false, Callback = function(v) _G.Auto_BaconThief = v end})
Piccolo:Toggle({Title = "Auto Farm Piccolo", Value = false, Callback = function(v) _G.Auto_Piccolo = v end})
Duck:Toggle({Title = "Auto Farm Duck (Full)", Value = false, Callback = function(v) _G.Auto_DuckAutomatically = v if v then ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel") end end
})
DevilBoat:Toggle({Title = "Auto Farm Devil Boat", Value = false, Callback = function(v) _G.Auto_DevilBoat = v end})
Kraken:Toggle({Title = "Auto Farm Kraken", Value = false, Callback = function(v) _G.Auto_Kraken = v end
})
ALLBOSS:Toggle({
    Title = "👹 Auto Boss All",
    Desc = "Auto: Piccolo, Devil Boat, Thief, Kraken",
    Value = false,
    Callback = function(v)
        _G.AutoBossAll = v
        if v then
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
        end
    end
})

local Spawn_Status = SpawnedT:Paragraph({Title = "Spawn Status", Content = "N/A"})
local Item_Auto    = WeaponCraft:Paragraph({Title = "Item Requirements ( None )", Content = "N/A"})

WeaponCraft:Dropdown({
    Title = "Select Weapon Craft", Options = WeaponAll, Multi = false,
    Callback = function(v) _G.Select_Item = v end
})
WeaponCraft:Button({
    Title = "Craft Weapon",
    Callback = function()
        local Data = UseItems and UseItems[_G.Select_Item]
        if Data then
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Craft", _G.Select_Item, Data.Type)
        end
    end
})
local NotifyClass = false
WeaponCraft:Toggle({
    Title = "Auto Craft Weapon (Full)", Value = false,
    Callback = function(v)
        _G.Auto_CraftWeapon = v
        if not v then NotifyClass = false end
    end
})
WeaponCraft:Toggle({
    Title = "Auto Farm Set Weapon", Value = false,
    Callback = function(v) _G.Auto_Farm_Set = v end
})

RaidCard:Toggle({
    Title = "Auto Raid Moon (Full)", Value = false,
    Callback = function(v)
        _G.Auto_Raid = v
        if v then
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
        end
    end
})

DungeonCard:Textbox({
    Title = "Dungeon Orb to Use", Id = "DUNOTOUSE", Placeholder = "...",
    Callback = function(v) _G.Dungeon_UseValue = tonumber(v) or 1 end
})
DungeonSettingsCard:Slider({
    Title = "Health Return %",
    Min = 1, Max = 100, Value = 30,
    Callback = function(v) _G.HealthPercent = v end
})
DungeonSettingsCard:Slider({
    Title = "Dungeon Height",
    Min = 0, Max = 100, Value = 25,
    Callback = function(v) _G.DungeonHeight = v end
})
DungeonCard:Toggle({
    Title = "🏰 Auto Dungeon (Full)",
    Value = false,
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
    ["Bacon of Grudge"] = {
        Name = "Bacon of Grudge",
        Reward = "Time Mystery Box x5, 7500 Diamond, Beli 50M, x3 Potion",
        PortalCost = 1, Valid = true
    },
    ["Dragon"] = {
        Name = "Dragon",
        Reward = "Thunder Mystery Box x5, 15k Diamond, Beli 100M, x3 Potion",
        PortalCost = 0, Valid = true
    },
    ["Lava Titan"] = {
    Name = "Lava Titan",
    Reward = "Lava Mystery Box x5, 20k Diamond, Beli 200M, x3 Potion",
    PortalCost = 1,
    Valid = true,
    OffsetY = 25,
    },
}

local RaidBossInfoPara = RaidBossInfoCard:Paragraph({
    Title = "Name: ( not selected )",
    Content = "Please choose a Boss Raid!!",
    TitleSize = 18,
    ContentSize = 16,
    TextSize = 16,
})

RaidBossCard:Dropdown({
    Title = "Choose a boss to raid",
    Options = {"Bacon of Grudge", "Dragon", "Lava Titan", "??? (Raid4)"},
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
            _G.SeaNotify("❌ Raid not selected", "Please choose a Boss Raid!", 3); return
        end
        if not Data.Valid then
            _G.SeaNotify("❌ Invalid Raid", "NO RAID!!!", 3); return
        end

        -- ===== PHÂN NHÁNH THEO BOSS =====
        if _G.AutoRaidWho == "Dragon" then
            if _G.AutoRaidRunning then _G.AutoRaidRunning = false end
            if _G.AutoRaidLava then _G.AutoRaidLava = false end
            _G.AutoRaidDragon = not _G.AutoRaidDragon
            _G.SeaNotify(
                _G.AutoRaidDragon and "▶️ Start Dragon Raid" or "⏹️ Stop Dragon Raid",
                "Dragon", 3
            )
            return
        end

        if _G.AutoRaidWho == "Lava Titan" then
            if _G.AutoRaidRunning then _G.AutoRaidRunning = false end
            if _G.AutoRaidDragon then _G.AutoRaidDragon = false end
            _G.AutoRaidLava = not _G.AutoRaidLava
            _G.SeaNotify(
                _G.AutoRaidLava and "▶️ Start Lava Raid" or "⏹️ Stop Lava Raid",
                "Lava Titan", 3
            )
            return
        end

        -- Mặc định: Bacon of Grudge
        if _G.AutoRaidDragon then _G.AutoRaidDragon = false end
        if _G.AutoRaidLava then _G.AutoRaidLava = false end
        _G.AutoRaidRunning = not _G.AutoRaidRunning
        _G.SeaNotify(_G.AutoRaidRunning and "▶️ Start Raid" or "⏹️ Stop Raid", Data.Name, 3)
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
-- SHOP RAID UI
-- ============================================================
local ShopInfoPara = ShopRaidInfoCard:Paragraph({
    Title = "RaidPoint: ( loading... )",
    Content = "Restock In: ( loading... )"
})
local ShopItemInfo = ShopRaidInfoCard:Paragraph({
    Title = "Item: ( not selected )",
    Content = "Select item from dropdown"
})

_G.SelectedShopItem = nil
local ShopItemDropdown = nil
local LastShopItemsStr = ""
local ShopDropdownInitialized = false

local function UpdateShopDropdown(items)
    if #items == 0 then return end
    local itemsStr = table.concat(items, ",")
    if itemsStr == LastShopItemsStr and ShopItemDropdown then return end
    LastShopItemsStr = itemsStr

    if not ShopItemDropdown then
        ShopItemDropdown = ShopRaidCard:Dropdown({
            Title = "Select Items to Purchase", Options = items, Multi = false,
            Callback = function(Value)
                _G.SelectedShopItem = Value
                ShopItemInfo:SetTitle("Item: " .. Value)
                ShopItemInfo:SetContent("Selected — press BUY to purchase")
            end
        })
        ShopDropdownInitialized = true
    else
        local updated = false
        pcall(function()
            if ShopItemDropdown.Set then ShopItemDropdown:Set(items); updated = true
            elseif ShopItemDropdown.UpdateOptions then ShopItemDropdown:UpdateOptions(items); updated = true end
        end)
        if not updated then
            pcall(function() ShopItemDropdown:Destroy() end)
            ShopItemDropdown = ShopRaidCard:Dropdown({
                Title = "Select Items to Purchase", Options = items, Multi = false,
                Callback = function(Value)
                    _G.SelectedShopItem = Value
                    ShopItemInfo:SetTitle("Item: " .. Value)
                    ShopItemInfo:SetContent("Selected — press BUY to purchase")
                end
            })
        end
    end
end

ShopRaidCard:Button({
    Title = "BUY!!",
    Callback = function()
        if not _G.SelectedShopItem then
            _G.SeaNotify("❌ No item selected", "Please choose an item first!", 3); return
        end
        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "buy_raidshop", _G.SelectedShopItem)
        _G.SeaNotify("✅ Purchased", _G.SelectedShopItem, 3)
    end
})

_G.MysteryBoxSelected    = "Time Mystery Box"
_G.MysteryBoxAmount      = 1
_G.MysteryBoxAuto        = false
_G.MysteryBoxAutoDelay   = 0.5
_G.MysteryBoxLastOpen    = 0
_G.MysteryBoxLastInfo    = 0
_G.MysteryBoxOutNotified = false

local MYSTERY_REWARD_FRAMES = {
    "Frame_CompactRandom",
    "Frame_RandomItem",
}

_G.MysteryBoxCloseAt = _G.MysteryBoxCloseAt or {}
_G.MysteryBoxHookedFrames = _G.MysteryBoxHookedFrames or {}
_G.MysteryBoxFrameConns = _G.MysteryBoxFrameConns or {}

local MysteryBoxList = {"Time Mystery Box", "Thunder Mystery Box", "Lava Mystery Box"}

local MysteryBoxInfo = TimeMysteryCard:Paragraph({
    Title = "🎁 Mystery Box: ---",
    Content = "Select the box below"
})

TimeMysteryCard:Dropdown({
    Title = "🎁 Select Mystery Box",
    Options = MysteryBoxList,
    Multi = false,
    Value = "Time Mystery Box",
    Callback = function(v)
        local val = type(v) == "table" and (next(v) or "Time Mystery Box") or v
        if type(val) ~= "string" then val = "Time Mystery Box" end
        if not table.find(MysteryBoxList, val) then val = "Time Mystery Box" end
        _G.MysteryBoxSelected = val
        _G.MysteryBoxOutNotified = false
    end
})

TimeMysteryCard:Textbox({
    Title = "Open Amount (1-100)",
    Placeholder = "1",
    Value = "1",
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
        local boxName = _G.MysteryBoxSelected or "Time Mystery Box"
        local amount  = tonumber(_G.MysteryBoxAmount) or 1

        if amount < 1 then amount = 1 end
        if amount > 100 then amount = 100 end
        _G.MysteryBoxAmount = amount

        local Inv = GetInventory()
        local have = (Inv[boxName] and Inv[boxName].amount) or 0

        if have <= 0 then
            _G.SeaNotify("❌ No Box", boxName .. " (0)", 3)
            return
        end

        local useCount = math.min(amount, have)

        local NetworkEvent = ReplicatedStorage
            :FindFirstChild("Modules")
            and ReplicatedStorage.Modules
            :FindFirstChild("NetworkFramework")
            and ReplicatedStorage.Modules.NetworkFramework
            :FindFirstChild("NetworkEvent")

        if not NetworkEvent then
            _G.SeaNotify("❌ Remote not found", "NetworkEvent", 3)
            return
        end

        local ok = pcall(function()
            NetworkEvent:FireServer("fire", nil, boxName, useCount)
        end)

        if ok then
            _G.SeaNotify("🎁 Opening",
                boxName .. " x" .. useCount .. " (have " .. have .. ")", 3)
        else
            _G.SeaNotify("❌ Fire error", "Cannot open box", 3)
        end
    end
})

TimeMysteryCard:Toggle({
    Title = "🤖 Auto Open Box",
    Value = false,
    Callback = function(v)
        _G.MysteryBoxAuto = v
        _G.MysteryBoxLastOpen = 0
        _G.MysteryBoxOutNotified = false
        if v then
        else
        end
    end
})

local ShopDunInfoPara = ShopDunInfoCard:Paragraph({
    Title = "DungeonPoint: ( loading... )",
    Content = "Select Auto Buy item on the left"
})
local ShopDunItemInfo = ShopDunInfoCard:Paragraph({
    Title = "Item: ( not selected )",
    Content = "Select item from dropdown"
})

_G.AutoBuyDunItem    = nil
_G.AutoBuyDunRunning = false
local AutoBuyDunDropdown = nil
local LastAutoBuyDunStr  = ""

local function GetAllShopDunItems()
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

local function UpdateDunDropdown(items)
    if #items == 0 then return end
    local itemsStr = table.concat(items, ",")
    if itemsStr == LastAutoBuyDunStr and AutoBuyDunDropdown then return end
    LastAutoBuyDunStr = itemsStr

    if not AutoBuyDunDropdown then
        AutoBuyDunDropdown = ShopDunCard:Dropdown({
            Title = "Auto Buy Items", Options = items, Multi = false,
            Callback = function(Value)
                _G.AutoBuyDunItem = Value
                ShopDunItemInfo:SetTitle("Item: " .. Value)
                ShopDunItemInfo:SetContent("Selected — enable Auto Buy Toggle")
            end
        })
    else
        local updated = false
        pcall(function()
            if AutoBuyDunDropdown.Set then AutoBuyDunDropdown:Set(items); updated = true
            elseif AutoBuyDunDropdown.UpdateOptions then AutoBuyDunDropdown:UpdateOptions(items); updated = true end
        end)
        if not updated then
            pcall(function() AutoBuyDunDropdown:Destroy() end)
            AutoBuyDunDropdown = ShopDunCard:Dropdown({
                Title = "Auto Buy Items", Options = items, Multi = false,
                Callback = function(Value)
                    _G.AutoBuyDunItem = Value
                    ShopDunItemInfo:SetTitle("Item: " .. Value)
                    ShopDunItemInfo:SetContent("Selected — enable Auto Buy Toggle")
                end
            })
        end
    end
end

ShopDunCard:Toggle({
    Title = "Auto Buy", Value = false,
    Callback = function(Value)
        if Value and not _G.AutoBuyDunItem then
            _G.SeaNotify("❌ No item selected", "Choose Auto Buy item first!", 3)
            _G.AutoBuyDunRunning = false
            return
        end
        _G.AutoBuyDunRunning = Value
        _G.SeaNotify(Value and "▶️ Enable Auto Buy" or "⏹️ Disable Auto Buy", _G.AutoBuyDunItem or "N/A", 3)
    end
})

    print("[MainTab] ✅ Loaded")
end
