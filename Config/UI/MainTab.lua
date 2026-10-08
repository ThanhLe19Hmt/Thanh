--[[
    UI/MainTab.lua
]]

local Globals = _G.__Globals
assert(Globals, "[MainTab] _G.__Globals chưa được set!")

local Utils     = Globals.Utils
local Inventory = Globals.Inventory

local MainTab = {}

-- ===== Build item lists =====
local WeaponAll, ItemAll, Bosses = {}, {}, {}
local ItemDrop, ItemToMob = {}, {}

local function BuildLists()
    for w in pairs(Globals.UseItems) do
        table.insert(WeaponAll, w)
    end
    table.sort(WeaponAll)

    for _, mob in ipairs(Globals.Itemdrops:GetChildren()) do
        local sf = mob:FindFirstChild("ScrollingFrame", true)
        if sf then
            for _, v in ipairs(sf:GetDescendants()) do
                if v:IsA("TextLabel") and not v.Text:find("%%") then
                    ItemDrop[v.Text] = ItemDrop[v.Text] or {}
                    table.insert(ItemDrop[v.Text], mob.Name)
                    ItemToMob[v.Text] = mob.Name
                end
            end
        end
    end

    for name in pairs(ItemToMob) do
        local data = Globals.ItemList[name]
        if not (data and data.Type == "Accessory") then
            table.insert(ItemAll, name)
        end
    end
    table.sort(ItemAll)

    for name in pairs(Globals.SpawnBossList) do
        table.insert(Bosses, name)
    end
    table.sort(Bosses)

    MainTab.WeaponAll = WeaponAll
    MainTab.ItemAll   = ItemAll
    MainTab.Bosses    = Bosses
    MainTab.ItemDrop  = ItemDrop
    MainTab.ItemToMob = ItemToMob
end

-- ===== GetNeed / GetNeedMonster (dùng cho Weapon Info) =====
local LastCraft = 0
local CraftDelay = 1
local NotifyCraft = false

local function CraftNotify(title, content)
    if NotifyCraft then return end
    NotifyCraft = true
    Utils.Notify(title, content, 5)
    task.delay(5, function() NotifyCraft = false end)
end

local function GetNeed(itemName)
    local inv = Inventory.Get()
    local data = Globals.UseItems[itemName]
    if not data then return itemName end
    for item, need in pairs(data.Inventory) do
        local have = inv[item] and inv[item].amount or 0
        if have < need then
            if Globals.UseItems[item] then
                return GetNeed(item)
            end
            return item
        end
    end
    local has = inv[itemName] and (inv[itemName].amount or 0) > 0
    if not has then return itemName end
    return nil
end

local function GetNeedMonster()
    if not _G.Select_Item then return nil end
    local need = GetNeed(_G.Select_Item)
    if not need then
        NotifyCraft = false
        return nil
    end
    if Globals.UseItems[need] then
        local inv = Inventory.Get()
        if not (inv[need] and (inv[need].amount or 0) > 0) then
            local data = Globals.UseItems[need]
            if not data then
                CraftNotify("Craft Failed ❌", "Không thể craft " .. need)
                return false
            end
            local canCraft = true
            for item, amount in pairs(data.Inventory) do
                local have = inv[item] and inv[item].amount or 0
                if have < amount then canCraft = false; break end
            end
            if canCraft and tick() - LastCraft >= CraftDelay then
                LastCraft = tick()
                Globals.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
                    :FireServer("fire", nil, "Craft", need, data.Type)
                task.wait(0.5)
            end
        end
        return GetNeedMonster()
    end
    local mobs = ItemDrop[need]
    if mobs then return mobs[1] end
    CraftNotify("Craft Failed ❌", "Không tìm thấy Monster drop " .. need)
    return false
end

-- Export cho feature khác dùng
MainTab.GetNeedMonster = GetNeedMonster
MainTab.GetNeed        = GetNeed

-- ============================================================
-- INIT
-- ============================================================
function MainTab:Init(Window)
    BuildLists()

    local Tab2       = Window:CreateTab("Main", false, false)
    local Farm       = Tab2:CreatePage("Farm")
    local AllBoss    = Tab2:CreatePage("Boss")
    local RaidBossPg = Tab2:CreatePage("Raid Boss & Shop!!")
    local RaidDun    = Tab2:CreatePage("Dungeon, Shop / Weapon")

    -- ========================================================
    -- FARM
    -- ========================================================
    local AutoFarmCard = Farm:CreateSection("🌾 Auto Farm", "Left")
    local MaterialCard = Farm:CreateSection("⛏️ Auto Farm Material", "Right")

    AutoFarmCard:Toggle({
        Title = "Auto Level Farm", Value = false,
        Callback = function(v)
            _G.Auto_Farm_Level = v
            if v then
                Globals.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
                    :FireServer("fire", nil, "Quest", "Cancel")
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
        Title = "Auto Farm Material", Value = false,
        Callback = function(v) _G.Auto_Farm_Material = v end
    })

    -- ========================================================
    -- BOSS
    -- ========================================================
    local Boss      = AllBoss:CreateSection("👹 Boss", "Left")
    local Thief     = AllBoss:CreateSection("💸 Thief", "Left")
    local Piccolo   = AllBoss:CreateSection("🐉 Piccolo", "Left")
    local SpawnedT  = AllBoss:CreateSection("🔍 Spawned Check", "Right")
    local Duck      = AllBoss:CreateSection("🦆 Duck", "Right")
    local DevilBoat = AllBoss:CreateSection("⛵ Devil Boat", "Right")

    Boss:Dropdown({
        Title = "Select Boss", Options = Bosses, Multi = false,
        Callback = function(v) _G.Select_Boss = v end
    })
    Boss:Toggle({
        Title = "Auto Farm All Boss", Value = false,
        Callback = function(v) _G.Auto_FarmBoss = v end
    })
    Boss:Toggle({
        Title = "Auto Farm Boss (Full)", Value = false,
        Callback = function(v)
            _G.Auto_FarmBoss_Automatically = v
            if v then
                Globals.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
                    :FireServer("fire", nil, "Quest", "Cancel")
            end
        end
    })

    Thief:Toggle({
        Title = "Auto Farm Thief Chest", Value = false,
        Callback = function(v) _G.Auto_BaconThief = v end
    })
    Piccolo:Toggle({
        Title = "Auto Farm Piccolo", Value = false,
        Callback = function(v) _G.Auto_Piccolo = v end
    })
    Duck:Toggle({
        Title = "Auto Farm Duck", Value = false,
        Callback = function(v) _G.Auto_Duck = v end
    })
    Duck:Toggle({
        Title = "Auto Farm Duck (Full)", Value = false,
        Callback = function(v)
            _G.Auto_DuckAutomatically = v
            if v then
                Globals.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
                    :FireServer("fire", nil, "Quest", "Cancel")
            end
        end
    })
    DevilBoat:Toggle({
        Title = "Auto Farm Devil Boat", Value = false,
        Callback = function(v) _G.Auto_DevilBoat = v end
    })

    local Spawn_Status = SpawnedT:Paragraph({
        Title = "Spawn Status", Content = "N/A"
    })

    task.spawn(function()
        while task.wait() do
            pcall(function()
                local text = {}
                for display, mobName in pairs(Globals.SpawnList) do
                    local spawned = false
                    local names = {mobName}
                    if mobName == "Devil Boat" then table.insert(names, "DevilBoat") end
                    for _, n in ipairs(names) do
                        if workspace.Mob:FindFirstChild(n) then
                            spawned = true
                            break
                        end
                    end
                    table.insert(text, display .. ": " .. (spawned and "Spawned (✅)" or "Not Spawned (❌)"))
                end
                Spawn_Status:SetContent(table.concat(text, "\n"))
            end)
        end
    end)

    -- ========================================================
    -- RAID DUNGEON PAGE
    -- ========================================================
    local DungeonCard         = RaidDun:CreateSection("🏰 Auto Dungeon", "Left")
    local ShopDunCard         = RaidDun:CreateSection("🏪 Shop Dungeon", "Left")
    local WeaponCraft         = RaidDun:CreateSection("🔨 Weapon", "Left")
    local DungeonSettingsCard = RaidDun:CreateSection("⚙️ Dungeon Settings", "Right")
    local ShopDunInfoCard     = RaidDun:CreateSection("📊 Shop Dungeon Info", "Right")
    local RaidCard            = RaidDun:CreateSection("🌋 Auto Raid Moon", "Right")

    DungeonCard:Textbox({
        Title = "Dungeon Orb to Use",
        Placeholder = "...",
        Callback = function(v) _G.Dungeon_UseValue = tonumber(v) or 1 end
    })

    DungeonSettingsCard:Slider({
        Title = "Health Return %",
        Min = 1, Max = 100, Value = 30,
        Callback = function(v) _G.HealthPercent = v end
    })
    DungeonSettingsCard:Slider({
        Title = "Dungeon Height Setting",
        Min = 0, Max = 100, Value = 25,
        Callback = function(v)
            _G.DungeonHeight = v
            print("[DungeonSettings] Height =", v)
        end
    })

    DungeonCard:Toggle({
        Title = "Auto Dungeon (Full)", Value = false,
        Callback = function(v)
            _G.Auto_Dungeon = v
            if v then
                Globals.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
                    :FireServer("fire", nil, "Quest", "Cancel")
            end
        end
    })

    -- ===== Weapon =====
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
            local data = Globals.UseItems[_G.Select_Item]
            if data then
                Globals.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
                    :FireServer("fire", nil, "Craft", _G.Select_Item, data.Type)
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

    -- ✅ LOOP UPDATE WEAPON INFO (quan trọng — bị thiếu ở bản trước)
    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                if not _G.Select_Item then return end
                local data = Globals.UseItems[_G.Select_Item]
                if not data then return end
                local inv = Inventory.Get()
                local haveWeapon = inv[_G.Select_Item] and (inv[_G.Select_Item].amount or 0) > 0

                local text = {}
                table.insert(text, "Need Class : " .. (data.NeedClass or "None"))
                table.insert(text, "Need Beli : " .. tostring((data.PlayerData and data.PlayerData.Beli) or 0))

                local lowestSet = math.huge
                for item, need in pairs(data.Inventory) do
                    local have = inv[item] and inv[item].amount or 0
                    local set = math.floor(have / need)
                    if set < lowestSet then lowestSet = set end
                end
                if lowestSet == math.huge then lowestSet = 0 end
                table.insert(text, "Have Set : " .. lowestSet)
                table.insert(text, "")

                for item, need in pairs(data.Inventory) do
                    local have = inv[item] and inv[item].amount or 0
                    local set = math.floor(have / need)
                    table.insert(text, string.format("%s : %d/%d %s (Set : %d)",
                        item, have, need, have >= need and "✅" or "❌", set))
                end

                Item_Auto:SetTitle("Item Requirements \n( " ..
                    (haveWeapon and _G.Select_Item .. " ✅" or _G.Select_Item .. " ❌") .. " )")
                Item_Auto:SetContent(table.concat(text, "\n"))
            end)
        end
    end)

    -- ========================================================
    -- RAID MOON
    -- ========================================================
    RaidCard:Toggle({
        Title = "Auto Raid Moon (Full)", Value = false,
        Callback = function(v)
            _G.Auto_Raid = v
            if v then
                Globals.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
                    :FireServer("fire", nil, "Quest", "Cancel")
            end
        end
    })

    -- ========================================================
    -- ✅ RAID BOSS PAGE (bị thiếu nút vì không gọi Init)
    -- ========================================================
    local RaidBossCard     = RaidBossPg:CreateSection("⚔️ Auto Raid Boss", "Left")
    local RaidBossInfoCard = RaidBossPg:CreateSection("📋 Raid Info", "Right")
    local ShopRaidCard     = RaidBossPg:CreateSection("🏪 Shop Raid", "Left")
    local ShopRaidInfoCard = RaidBossPg:CreateSection("📊 Shop Info", "Right")
    local RaidSettingsCard = RaidBossPg:CreateSection("⚙️ Raid Settings", "Right")

    MainTab:InitRaidBoss(RaidBossCard, RaidBossInfoCard, RaidSettingsCard, ShopRaidCard, ShopRaidInfoCard)

    -- ========================================================
    -- ✅ SHOP DUNGEON (bị trống vì không gọi Init)
    -- ========================================================
    MainTab:InitShopDungeon(ShopDunCard, ShopDunInfoCard)
end

-- ============================================================
-- RAID BOSS INIT
-- ============================================================
function MainTab:InitRaidBoss(RaidBossCard, RaidBossInfoCard, RaidSettingsCard, ShopRaidCard, ShopRaidInfoCard)
    -- Raid data
    _G.RaidBossData = _G.RaidBossData or {
        ["Bacon of Grudge"] = {
            Name = "Bacon of Grudge",
            Reward = "Time Mystery Box x5, 7500 Diamond, Beli 50M, x3 Potion, Roll Class + Raid Potion x1",
            PortalCost = 1,
            Valid = true
        },
        ["??? (Raid 2)"] = {Name = "???", Reward = "SOON!!", PortalCost = 0, Valid = false},
        ["??? (Raid 3)"] = {Name = "???", Reward = "SOON!!", PortalCost = 0, Valid = false}
    }
    _G.AutoRaidRunning = false

    local RaidBossInfoPara = RaidBossInfoCard:Paragraph({
        Title = "Name: ( chưa chọn )",
        Content = "Please choose a Boss Raid!!"
    })

    RaidBossCard:Dropdown({
        Title = "Choose a boss to raid",
        Options = {"Bacon of Grudge", "??? (Raid 2)", "??? (Raid 3)"},
        Multi = false,
        Callback = function(v)
            _G.AutoRaidWho = v
            local data = _G.RaidBossData[v]
            if data then
                RaidBossInfoPara:SetTitle("Name: " .. data.Name)
                RaidBossInfoPara:SetContent(
                    "Reward: " .. data.Reward .. "\n- " .. data.PortalCost .. " Portal Gun"
                )
            end
        end
    })

    RaidBossCard:Button({
        Title = "Start Raid Now!!",
        Callback = function()
            local data = _G.RaidBossData[_G.AutoRaidWho]
            if not data then
                Utils.Notify("❌ Raid not selected", "Please choose a Boss Raid!!", 3)
                return
            end
            if not data.Valid then
                Utils.Notify("❌ Raid không hợp lệ", "NO RAID!!!", 3)
                return
            end
            _G.AutoRaidRunning = not _G.AutoRaidRunning
            Utils.Notify(_G.AutoRaidRunning and "▶️ Start Raid" or "⏹️ Stop Raid",
                data.Name, 3)
        end
    })

    RaidSettingsCard:Slider({
        Title = "Bacon of Grudge Height",
        Min = 0, Max = 150, Value = 55,
        Callback = function(v) _G.RaidBossOffsetY = v end
    })
    RaidSettingsCard:Slider({
        Title = "Golden Ball Height",
        Min = 0, Max = 150, Value = 25,
        Callback = function(v) _G.RaidBallOffsetY = v end
    })

    -- ===== SHOP RAID =====
    local ShopInfoPara = ShopRaidInfoCard:Paragraph({
        Title = "RaidPoint: ( đang load... )",
        Content = "Restock In: ( đang load... )"
    })
    local ShopItemInfo = ShopRaidInfoCard:Paragraph({
        Title = "Item: ( chưa chọn )",
        Content = "Chọn item từ dropdown"
    })

    local SelectedShopItem, ShopItemDropdown, LastShopItemsStr = nil, nil, ""

    local function RefreshShopDropdown(items)
        local str = table.concat(items, ",")
        if str == LastShopItemsStr and ShopItemDropdown then return end
        LastShopItemsStr = str
        if ShopItemDropdown then pcall(function() ShopItemDropdown:Destroy() end) end
        ShopItemDropdown = ShopRaidCard:Dropdown({
            Title = "Select Items to Purchase",
            Options = items,
            Multi = false,
            Callback = function(v) SelectedShopItem = v end
        })
    end

    ShopRaidCard:Button({
        Title = "BUY!!",
        Callback = function()
            if not SelectedShopItem then
                Utils.Notify("❌ Chưa chọn item", "Vui lòng chọn item trước!", 3)
                return
            end
            Globals.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
                :FireServer("fire", nil, "buy_raidshop", SelectedShopItem)
            Utils.Notify("✅ Đã mua", SelectedShopItem, 3)
        end
    })

    local LastRaidPoint, LastRestock, LastShopItemInfo = "", "", ""
    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                local hud = Globals.LocalPlayer.PlayerGui:FindFirstChild("HUD")
                if not hud or not hud:FindFirstChild("Main") then return end
                local shop = hud.Main:FindFirstChild("Frame_ShopRaid")
                if not shop then return end

                local rpLbl = shop:FindFirstChild("RaidPoint")
                local rsLbl = shop:FindFirstChild("Reset")
                if rpLbl and rsLbl then
                    if rpLbl.Text ~= LastRaidPoint or rsLbl.Text ~= LastRestock then
                        LastRaidPoint, LastRestock = rpLbl.Text, rsLbl.Text
                        ShopInfoPara:SetTitle(rpLbl.Text)
                        ShopInfoPara:SetContent(rsLbl.Text)
                    end
                end

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
                        RefreshShopDropdown(items)
                    end
                    if SelectedShopItem then
                        for _, item in pairs(sf:GetChildren()) do
                            if item:IsA("Frame") then
                                local label = item:FindFirstChild("Label")
                                if label and label.Text == SelectedShopItem then
                                    local price = item:FindFirstChild("Price")
                                    local amount = item:FindFirstChild("Amount")
                                    local pTxt = price and price.Text or "?"
                                    local aTxt = amount and amount.Text or "?"
                                    if LastShopItemInfo ~= (pTxt .. "|" .. aTxt) then
                                        LastShopItemInfo = pTxt .. "|" .. aTxt
                                        ShopItemInfo:SetTitle("Item: " .. SelectedShopItem)
                                        ShopItemInfo:SetContent("Price: " .. pTxt .. "\nPurchase limit: " .. aTxt)
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)
end

-- ============================================================
-- SHOP DUNGEON INIT
-- ============================================================
function MainTab:InitShopDungeon(ShopDunCard, ShopDunInfoCard)
    local ShopDunInfoPara = ShopDunInfoCard:Paragraph({
        Title = "DungeonPoint: ( đang load... )",
        Content = "Chọn item Auto Buy ở cột trái"
    })
    local ShopDunItemInfo = ShopDunInfoCard:Paragraph({
        Title = "Item: ( chưa chọn )",
        Content = "Chọn item từ dropdown Auto Buy"
    })

    local AutoBuyDunItem = nil
    _G.AutoBuyDunRunning = false
    _G.AutoBuyDunLoaded = false
    local Dropdown, LastStr = nil, ""

    local function GetAllShopDunItems()
        local items, seen = {}, {}
        local hud = Globals.LocalPlayer.PlayerGui:FindFirstChild("HUD")
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
        local defaults = {
            "Plastic", "Rope", "Glue Elephant", "Cow leather", "Stopwatch",
            "Banana Leaf", "Scarf Old", "Snake leather", "Crocodile leather",
            "Microphone", "Trainer Notes"
        }
        for _, name in ipairs(defaults) do
            if not seen[name] then
                seen[name] = true
                table.insert(items, name)
            end
        end
        table.sort(items)
        return items
    end

    local function RefreshDropdown(items)
        local str = table.concat(items, ",")
        if str == LastStr and Dropdown then return end
        LastStr = str
        if Dropdown then pcall(function() Dropdown:Destroy() end) end
        Dropdown = ShopDunCard:Dropdown({
            Title = "Auto Buy Items",
            Options = items,
            Multi = false,
            Callback = function(v)
                AutoBuyDunItem = v
                print("[AutoBuyDun] Chọn:", v)
            end
        })
    end

    ShopDunCard:Toggle({
        Title = "Auto Buy", Value = false,
        Callback = function(v)
            if not _G.AutoBuyDunLoaded then
                _G.AutoBuyDunLoaded = true
                _G.AutoBuyDunRunning = v
                return
            end
            if v and not AutoBuyDunItem then
                Utils.Notify("❌ Chưa chọn item", "Chọn item Auto Buy trước!", 3)
                _G.AutoBuyDunRunning = false
                return
            end
            _G.AutoBuyDunRunning = v
            Utils.Notify(v and "▶️ Bật Auto Buy" or "⏹️ Tắt Auto Buy",
                AutoBuyDunItem or "N/A", 3)
        end
    })

    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                local hud = Globals.LocalPlayer.PlayerGui:FindFirstChild("HUD")
                if not hud or not hud:FindFirstChild("Main") then return end
                local shop = hud.Main:FindFirstChild("Frame_ShopDungeon")
                if not shop then return end

                local pt = Globals.LocalPlayer:GetAttribute("DungeonPoint")
                    or Globals.LocalPlayer:GetAttribute("PointDungeon")
                    or Globals.LocalPlayer:GetAttribute("DungeonOrb")
                    or 0
                ShopDunInfoPara:SetTitle("DungeonPoint: " .. tostring(pt))

                RefreshDropdown(GetAllShopDunItems())

                if AutoBuyDunItem then
                    local sf = shop:FindFirstChild("ShopScrollingFrame")
                    if sf then
                        for _, item in pairs(sf:GetChildren()) do
                            if item:IsA("Frame") then
                                local main = item:FindFirstChild("Main")
                                if main then
                                    local titleLbl = main:FindFirstChild("TitleLabel")
                                    if titleLbl and titleLbl.Text == AutoBuyDunItem then
                                        local btn = main:FindFirstChild("TextButton")
                                        local priceLbl = btn and btn:FindFirstChild("TextLabel")
                                        ShopDunItemInfo:SetTitle("Item: " .. AutoBuyDunItem)
                                        ShopDunItemInfo:SetContent("Price: " .. (priceLbl and priceLbl.Text or "?"))
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)

    task.spawn(function()
        while task.wait(0.5) do
            if _G.AutoBuyDunRunning and AutoBuyDunItem then
                pcall(function()
                    local hud = Globals.LocalPlayer.PlayerGui:FindFirstChild("HUD")
                    if not hud or not hud:FindFirstChild("Main") then return end
                    local shop = hud.Main:FindFirstChild("Frame_ShopDungeon")
                    if not shop then return end
                    local sf = shop:FindFirstChild("ShopScrollingFrame")
                    if not sf then return end
                    for _, item in pairs(sf:GetChildren()) do
                        if item:IsA("Frame") then
                            local main = item:FindFirstChild("Main")
                            if main then
                                local titleLbl = main:FindFirstChild("TitleLabel")
                                if titleLbl and titleLbl.Text == AutoBuyDunItem then
                                    Globals.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
                                        :FireServer("fire", nil, "BuyDungeonShop", AutoBuyDunItem)
                                    print("[AutoBuyDun] Mua:", AutoBuyDunItem)
                                    task.wait(0.3)
                                    break
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)
end

return MainTab
