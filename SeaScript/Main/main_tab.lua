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
    -- ============================================================
    -- 🆕 B1: MYSTERY BOX HELPERS
    -- ============================================================
    local function MysteryBox_CloseFrame(frame)
        if not frame or not frame.Parent then return false end
        local closeBtn = frame:FindFirstChild("Close_")
            or frame:FindFirstChild("Close")
            or frame:FindFirstChild("CloseButton")
            or frame:FindFirstChild("Exit")

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
        end

        task.wait(0.15)
        if frame.Parent and frame.Visible then
            pcall(function() frame.Visible = false end)
        end
        return true
    end

    local function MysteryBox_AttachAllHooks()
        local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        local main = hud and hud:FindFirstChild("Main")
        if not main then return end

        for _, name in ipairs(MYSTERY_REWARD_FRAMES) do
            local frame = main:FindFirstChild(name)
            if frame and not _G.MysteryBoxHookedFrames[frame] then
                _G.MysteryBoxHookedFrames[frame] = true

                local conn = frame:GetPropertyChangedSignal("Visible"):Connect(function()
                    if frame.Visible then
                        _G.MysteryBoxCloseAt[frame] = tick() + 5
                    else
                        _G.MysteryBoxCloseAt[frame] = 0
                    end
                end)

                table.insert(_G.MysteryBoxFrameConns, conn)

                if frame.Visible then
                    _G.MysteryBoxCloseAt[frame] = tick() + 5
                end
            end
        end
    end

    MysteryBox_AttachAllHooks()
	    -- ============================================================
    -- 🆕 B2: MYSTERY BOX LOOP
    -- ============================================================
    task.spawn(function()
        while task.wait(0.1) do
            pcall(function()
                local now = tick()
                MysteryBox_AttachAllHooks()
                local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                local main = hud and hud:FindFirstChild("Main")

                if main then
                    for _, name in ipairs(MYSTERY_REWARD_FRAMES) do
                        local frame = main:FindFirstChild(name)
                        if frame and frame.Visible then
                            if not _G.MysteryBoxCloseAt[frame] or _G.MysteryBoxCloseAt[frame] == 0 then
                                _G.MysteryBoxCloseAt[frame] = now + 5
                            end
                            if now >= _G.MysteryBoxCloseAt[frame] then
                                MysteryBox_CloseFrame(frame)
                                _G.MysteryBoxCloseAt[frame] = 0
                            end
                        else
                            if _G.MysteryBoxCloseAt[frame] and _G.MysteryBoxCloseAt[frame] > 0 then
                                _G.MysteryBoxCloseAt[frame] = 0
                            end
                        end
                    end
                end

                -- Cập nhật info
                if now - _G.MysteryBoxLastInfo >= 0.5 then
                    _G.MysteryBoxLastInfo = now
                    local boxName = _G.MysteryBoxSelected or "Time Mystery Box"
                    local Inv = GetInventory()
                    local have = (Inv[boxName] and Inv[boxName].amount) or 0

                    local function Fmt(n)
                        n = tonumber(n) or 0
                        if n < 1000 then return tostring(math.floor(n)) end
                        if n < 1000000 then return string.format("%.1fK", n / 1000) end
                        return string.format("%.1fM", n / 1000000)
                    end

                    if MysteryBoxInfo then
                        local status = "OFF"
                        if _G.MysteryBoxAuto then
                            if have <= 0 then
                                status = "ON (⏸️ out of stock)"
                            else
                                status = "ON (▶️ running)"
                            end
                        end
                        MysteryBoxInfo:SetTitle("🎁 " .. boxName .. ": " .. Fmt(have))
                        MysteryBoxInfo:SetContent(
                            "Selected: " .. boxName
                            .. "\nAmount: " .. tostring(_G.MysteryBoxAmount or 1)
                            .. " | Auto: " .. status
                        )
                    end
                end

                if not _G.MysteryBoxAuto then return end

                local boxName = _G.MysteryBoxSelected or "Time Mystery Box"
                local amount  = tonumber(_G.MysteryBoxAmount) or 1
                if amount < 1 then amount = 1 end
                if amount > 100 then amount = 100 end

                local delay = tonumber(_G.MysteryBoxAutoDelay) or 0.5
                if delay < 0.1 then delay = 0.1 end
                if now - (_G.MysteryBoxLastOpen or 0) < delay then return end

                local Inv = GetInventory()
                local have = (Inv[boxName] and Inv[boxName].amount) or 0

                if have <= 0 then
                    if not _G.MysteryBoxOutNotified then
                        _G.MysteryBoxOutNotified = true
                        _G.SeaNotify("⏸️ Auto paused",
                            boxName .. " Out of stock", 4)
                    end
                    return
                end

                if _G.MysteryBoxOutNotified then
                    _G.MysteryBoxOutNotified = false
                end

                local useCount = math.min(amount, have)
                local NetworkEvent = ReplicatedStorage
                    :FindFirstChild("Modules")
                    and ReplicatedStorage.Modules
                    :FindFirstChild("NetworkFramework")
                    and ReplicatedStorage.Modules.NetworkFramework
                    :FindFirstChild("NetworkEvent")
                if not NetworkEvent then return end

                _G.MysteryBoxLastOpen = now
                pcall(function()
                    NetworkEvent:FireServer("fire", nil, boxName, useCount)
                end)
            end)
        end
    end)
	    -- ============================================================
    -- 🆕 B3: SHOP RAID LOOP
    -- ============================================================
    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                if not hud or not hud:FindFirstChild("Main") then return end
                local shop = hud.Main:FindFirstChild("Frame_ShopRaid")
                if not shop then return end

                local rpLbl    = shop:FindFirstChild("RaidPoint")
                local resetLbl = shop:FindFirstChild("Reset")
                if rpLbl and resetLbl then
                    ShopInfoPara:SetTitle(rpLbl.Text)
                    ShopInfoPara:SetContent(resetLbl.Text)
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
                        UpdateShopDropdown(items)
                    end
                end
            end)
        end
    end)

    -- ============================================================
    -- 🆕 B3b: SHOP DUNGEON LOOP
    -- ============================================================
    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                local ptAttr = LocalPlayer:GetAttribute("DungeonPoint") or 0
                ShopDunInfoPara:SetTitle("DungeonPoint: " .. tostring(ptAttr))
                local items = GetAllShopDunItems()
                if #items > 0 then UpdateDunDropdown(items) end
            end)
        end
    end)

    task.spawn(function()
        while task.wait(0.3) do
            if _G.AutoBuyDunRunning and _G.AutoBuyDunItem then
                pcall(function()
                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
                        :FireServer("fire", nil, "BuyDungeonShop", _G.AutoBuyDunItem)
                    task.wait(0.2)
                end)
            end
        end
    end)
	    -- ============================================================
    -- 🆕 B4: SPAWN STATUS
    -- ============================================================
    task.spawn(function()
        while task.wait() do
            pcall(function()
                local Text = {}
                for Name, MobName in pairs(SpawnList) do
                    local Spawned = false
                    local Names = {MobName}
                    if MobName == "Devil Boat" then table.insert(Names, "DevilBoat") end
                    for _, n in ipairs(Names) do
                        if workspace.Mob and workspace.Mob:FindFirstChild(n) then
                            Spawned = true; break
                        end
                    end
                    table.insert(Text, Name .. ": " .. (Spawned and "✅" or "❌"))
                end
                Spawn_Status:SetContent(table.concat(Text, "\n"))
            end)
        end
    end)

    -- ============================================================
    -- 🆕 B4b: AUTO FARM LEVEL
    -- ============================================================
    task.spawn(function()
        while wait() do
            xpcall(function()
                if not _G.Auto_Farm_Level then return end
                local quest = GetQuest_Level(tonumber(LocalPlayer:GetAttribute("Level")))
                if not quest then return end
                local Frame = GetQuestFrame()
                local Text  = Frame.Title.Text or ""

                if LocalPlayer.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                end
                if Frame.Visible and not string.find(Text, quest.Monster) then
                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                    repeat task.wait() until not Frame.Visible
                end
                if not Frame.Visible then
                    _G.CanAutoSkill = false
                    local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
                    if npc then
                        local char = LocalPlayer.Character
                        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.CFrame = CFrame.new(npc.Position + Vector3.new(0, 3, 0))
                            hrp.AssemblyLinearVelocity  = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end
                        task.wait(0.4)
                        local prompt = npc:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            pcall(function() fireproximityprompt(prompt, prompt.HoldDuration + 0.1) end)
                            task.wait(0.2)
                            pcall(function() fireproximityprompt(prompt, prompt.HoldDuration + 0.1) end)
                        end
                    end
                else
                    for _, v in pairs(workspace.Mob:GetChildren()) do
                        if v:IsA("Model") and v.Name == quest.Monster
                           and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                            local hrp = v:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                v.Humanoid.WalkSpeed = 0
                                v.Humanoid.JumpPower = 0
                                _G.CanAutoSkill = true
                                repeat task.wait()
                                    EquipWeapon(); AutoSkill(); Attack()
                                    Teleport(hrp.CFrame * GetMethodFarm())
                                until not _G.Auto_Farm_Level or v.Humanoid.Health <= 0
                                _G.CanAutoSkill = false
                            end
                            break
                        end
                    end
                end
            end, print)
        end
    end)

    -- ============================================================
    -- 🆕 B4c: AUTO FARM MATERIAL
    -- ============================================================
    task.spawn(function()
        local lastSpawnTPTime = 0
        local SPAWN_TP_COOLDOWN = 2
        local lastSpawnTPName = nil

        while task.wait() do
            xpcall(function()
                if not _G.Auto_Farm_Material then
                    _G.CanAutoSkill = false
                    return
                end
                if type(_G.Select_Material) ~= "table" or #_G.Select_Material == 0 then return end

                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChild("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then return end

                local mobFolder = workspace:FindFirstChild("Mob") or workspace:FindFirstChild("Mobs")
                if not mobFolder then return end

                local Target, TargetName, minDist = nil, nil, math.huge
                for _, Material in ipairs(_G.Select_Material) do
                    local MobNames = ItemDrop[Material]
                    if MobNames then
                        for _, MobName in ipairs(MobNames) do
                            for _, Mob in ipairs(mobFolder:GetChildren()) do
                                if Mob:IsA("Model") and Mob.Name == MobName
                                   and Mob:FindFirstChild("Humanoid")
                                   and Mob:FindFirstChild("HumanoidRootPart")
                                   and Mob.Humanoid.Health > 0 then
                                    local dist = (hrp.Position - Mob.HumanoidRootPart.Position).Magnitude
                                    if dist < minDist then
                                        minDist    = dist
                                        Target     = Mob
                                        TargetName = MobName
                                    end
                                end
                            end
                        end
                    end
                end

                if not Target then
                    _G.CanAutoSkill = false
                    if tick() - lastSpawnTPTime >= SPAWN_TP_COOLDOWN then
                        local firstMaterial = _G.Select_Material[1]
                        local MobNames = ItemDrop[firstMaterial]
                        if MobNames and #MobNames > 0 then
                            local spawnName = MobNames[1]
                            local itemdrops = workspace:FindFirstChild("Itemdrops")
                            local spawnPart = itemdrops and itemdrops:FindFirstChild(spawnName)
                            if spawnPart then
                                local spawnPos = spawnPart:GetPivot().Position
                                hrp.CFrame = CFrame.new(spawnPos + Vector3.new(0, 10, 0))
                                hrp.AssemblyLinearVelocity  = Vector3.zero
                                hrp.AssemblyAngularVelocity = Vector3.zero
                                lastSpawnTPTime = tick()
                                lastSpawnTPName = spawnName
                                task.wait(0.5)
                            end
                        end
                    end
                    return
                end

                lastSpawnTPName = nil
                Target.Humanoid.WalkSpeed = 0
                Target.Humanoid.JumpPower = 0
                _G.CanAutoSkill = true
                EquipWeapon(); AutoSkill(); Attack()
                Teleport(Target.HumanoidRootPart.CFrame * GetMethodFarm())
            end, function(err) warn("[AutoFarmMaterial]", err) end)
        end
    end)
	    -- ============================================================
    -- 🆕 B5a: AUTO FARM BOSS (FULL)
    -- ============================================================
    task.spawn(function()
        local lastSummonTime = 0
        local summonCooldown = 1.5
        while task.wait() do
            xpcall(function()
                if not _G.Auto_FarmBoss then return end
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChild("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then
                    _G.CanAutoSkill = false; return
                end
                local BossT = nil
                for _, v in pairs(workspace.Boss:GetChildren()) do
                    if table.find(Bosses, v.Name)
                       and v:FindFirstChild("Humanoid")
                       and v:FindFirstChild("HumanoidRootPart")
                       and v.Humanoid.Health > 0 then
                        BossT = v; break
                    end
                end
                if BossT then
                    _G.CanAutoSkill = true
                    lastSummonTime = 0
                    BossT.Humanoid.WalkSpeed = 0
                    BossT.Humanoid.JumpPower = 0
                    EquipWeapon(); AutoSkill(); Attack()
                    Teleport(BossT.HumanoidRootPart.CFrame * GetMethodFarm())
                    return
                end
                _G.CanAutoSkill = false
                local now = tick()
                if now - lastSummonTime < summonCooldown then return end
                local orbBoss = GetItemAmount("Orb Boss")
                if orbBoss >= 1 and _G.Select_Boss then
                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
                        :FireServer("fire", nil, "SummonBoss", _G.Select_Boss)
                    lastSummonTime = now
                    return
                end
                _G.Auto_FarmBoss = false
                _G.SeaNotify("❌ Out of Orb Boss", "Auto Farm Boss disabled!", 5)
            end, function(err) warn("[AutoFarmBoss]", err) end)
        end
    end)

    -- ============================================================
    -- 🆕 B5b: AUTO BOSS ALL
    -- ============================================================
    task.spawn(function()
        local lastTargetKey = nil
        while task.wait() do
            xpcall(function()
                if not _G.AutoBossAll then
                    _G.CanAutoSkill = false; lastTargetKey = nil; return
                end
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChild("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then
                    _G.CanAutoSkill = false; return
                end
                local mobFolder = workspace:FindFirstChild("Mob") or workspace:FindFirstChild("Mobs")
                if not mobFolder then return end

                local BossNames = {"Piccolo", "Kraken", "Devil Boat", "DevilBoat", "Bacon Thief"}
                local Target, TargetName = nil, nil
                for _, bossName in ipairs(BossNames) do
                    for _, mob in ipairs(mobFolder:GetChildren()) do
                        if mob:IsA("Model") and mob.Name == bossName
                           and mob:FindFirstChild("Humanoid")
                           and mob:FindFirstChild("HumanoidRootPart")
                           and mob.Humanoid.Health > 0 then
                            Target = mob; TargetName = bossName; break
                        end
                    end
                    if Target then break end
                end
                if not Target then
                    _G.CanAutoSkill = false; lastTargetKey = nil; return
                end
                local tHrp = Target:FindFirstChild("HumanoidRootPart")
                if not tHrp then return end
                local targetKey = TargetName .. "|" .. tostring(Target)
                if targetKey ~= lastTargetKey then
                    lastTargetKey = targetKey
                    print("[BossAll] ⚔️ " .. TargetName)
                end
                Target.Humanoid.WalkSpeed = 0
                Target.Humanoid.JumpPower = 0
                _G.CanAutoSkill = true
                EquipWeapon(); AutoSkill(); Attack()
                Teleport(tHrp.CFrame * GetMethodFarm())
            end, function(err) warn("[BossAll]", err) end)
        end
    end)

    -- ============================================================
    -- 🆕 B5c: AUTO PICCOLO
    -- ============================================================
    task.spawn(function()
        while task.wait() do
            if _G.Auto_Piccolo then
                pcall(function()
                    if workspace.Mob:FindFirstChild("Piccolo") then
                        for _, v in pairs(workspace.Mob:GetChildren()) do
                            if v:IsA("Model") and v.Name == "Piccolo"
                               and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                                v.Humanoid.WalkSpeed = 0
                                v.Humanoid.JumpPower = 0
                                _G.CanAutoSkill = true
                                repeat task.wait()
                                    EquipWeapon(); AutoSkill(); Attack()
                                    Teleport(v.HumanoidRootPart.CFrame * GetMethodFarm())
                                until not _G.Auto_Piccolo or not v.Parent or v.Humanoid.Health <= 0
                                _G.CanAutoSkill = false
                            end
                        end
                    else
                        _G.CanAutoSkill = false
                    end
                end)
            end
        end
    end)

    -- ============================================================
    -- 🆕 B5d: AUTO DUCK
    -- ============================================================
    task.spawn(function()
        local lastSummonTime = 0
        local summonCooldown = 2.5
        while task.wait() do
            xpcall(function()
                if not _G.Auto_DuckAutomatically then return end
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChild("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then
                    _G.CanAutoSkill = false; return
                end
                local DuckT = nil
                for _, v in pairs(workspace.Mob:GetChildren()) do
                    if v:IsA("Model") and v.Name == "Duck Monster"
                       and v:FindFirstChild("Humanoid")
                       and v:FindFirstChild("HumanoidRootPart")
                       and v.Humanoid.Health > 0 then
                        DuckT = v; break
                    end
                end
                if DuckT then
                    _G.CanAutoSkill = true
                    lastSummonTime = 0
                    DuckT.Humanoid.WalkSpeed = 0
                    DuckT.Humanoid.JumpPower = 0
                    EquipWeapon(); AutoSkill(); Attack()
                    Teleport(DuckT.HumanoidRootPart.CFrame * GetMethodFarm())
                    return
                end
                _G.CanAutoSkill = false
                local now = tick()
                if now - lastSummonTime < summonCooldown then return end
                local DuckItems = {"Duck","Duck2","Duck3","Duck4","Duck5","Duck6","Duck7"}
                local missingItems = {}
                local HaveAll = true
                for _, Item in ipairs(DuckItems) do
                    if GetItemAmount(Item) <= 0 then
                        HaveAll = false
                        table.insert(missingItems, Item)
                    end
                end
                if HaveAll then
                    local npcPrompt = workspace:FindFirstChild("NpcPrompt")
                    local duckNPC = npcPrompt and npcPrompt:FindFirstChild("DuckMonster")
                    if duckNPC then
                        local npcHrp = duckNPC:FindFirstChild("HumanoidRootPart")
                            or duckNPC:FindFirstChildWhichIsA("BasePart")
                        if npcHrp then
                            hrp.CFrame = npcHrp.CFrame * CFrame.new(0, 5, 0)
                            task.wait(0.3)
                            local prompt = npcHrp:FindFirstChildOfClass("ProximityPrompt")
                            if prompt then
                                pcall(function() fireproximityprompt(prompt) end)
                                lastSummonTime = now
                            end
                        end
                    end
                    return
                end
                _G.Auto_DuckAutomatically = false
                _G.SeaNotify("❌ Missing Duck Items", table.concat(missingItems, ", "), 6)
            end, function(err) warn("[AutoDuck]", err) end)
        end
    end)

    -- ============================================================
    -- 🆕 B5e: AUTO DEVIL BOAT
    -- ============================================================
    task.spawn(function()
        while task.wait() do
            if _G.Auto_DevilBoat then
                pcall(function()
                    _G.CanAutoSkill = false
                    for _, v in pairs(workspace.Mob:GetChildren()) do
                        if v:IsA("Model")
                           and (v.Name == "Devil Boat" or v.Name == "DevilBoat")
                           and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0
                            _G.CanAutoSkill = true
                            repeat task.wait()
                                EquipWeapon(); AutoSkill(); Attack()
                                Teleport(v.HumanoidRootPart.CFrame * GetMethodFarm())
                            until not _G.Auto_DevilBoat or not v.Parent or v.Humanoid.Health <= 0
                            _G.CanAutoSkill = false
                            break
                        end
                    end
                end)
            end
        end
    end)

    -- ============================================================
    -- 🆕 B5f: AUTO KRAKEN
    -- ============================================================
    task.spawn(function()
        while task.wait() do
            xpcall(function()
                if not _G.Auto_Kraken then
                    _G.CanAutoSkill = false; return
                end
                local char = LocalPlayer.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                local hum  = char and char:FindFirstChild("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then
                    _G.CanAutoSkill = false; return
                end
                local KrakenT = nil
                local mobFolder = workspace:FindFirstChild("Mob")
                if mobFolder then
                    for _, v in ipairs(mobFolder:GetChildren()) do
                        if v:IsA("Model") and v.Name == "Kraken"
                           and v:FindFirstChild("Humanoid")
                           and v:FindFirstChild("HumanoidRootPart")
                           and v.Humanoid.Health > 0 then
                            KrakenT = v; break
                        end
                    end
                end
                if not KrakenT then
                    _G.CanAutoSkill = false; return
                end
                _G.CanAutoSkill = true
                KrakenT.Humanoid.WalkSpeed = 0
                KrakenT.Humanoid.JumpPower = 0
                EquipWeapon(); AutoSkill(); Attack()
                Teleport(KrakenT.HumanoidRootPart.CFrame * GetMethodFarm())
            end, function(err) warn("[AutoKraken]", err) end)
        end
    end)
	    -- ============================================================
    -- 🆕 B6a: AUTO RAID MOON
    -- ============================================================
    task.spawn(function()
        while task.wait() do
            pcall(function()
                if not _G.Auto_Raid then return end

                local MOON_PLACE_ID = 82878101790702
                if game.PlaceId == MOON_PLACE_ID then
                    for _, v in pairs(workspace.Mob:GetChildren()) do
                        if v:IsA("Model") and v:FindFirstChild("Humanoid")
                           and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0
                            _G.CanAutoSkill = true
                            repeat task.wait()
                                EquipWeapon(); AutoSkill(); Attack()
                                Teleport(v.HumanoidRootPart.CFrame * GetMethodFarm())
                            until not _G.Auto_Raid or not v.Parent or v.Humanoid.Health <= 0
                            _G.CanAutoSkill = false
                        end
                    end
                else
                    _G.CanAutoSkill = false
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
                            end
                        end
                    end
                end
            end)
        end
    end)

    -- ============================================================
    -- 🆕 B6b: AUTO DUNGEON
    -- ============================================================
    task.spawn(function()
        while task.wait() do
            xpcall(function()
                if not _G.Auto_Dungeon then return end
                local Player = game.Players.LocalPlayer
                local Character = Player.Character
                if not Character then return end
                local hum = Character:FindFirstChild("Humanoid")
                local hrp = Character:FindFirstChild("HumanoidRootPart")
                if not hum or not hrp then return end

                local HpPercent = (hum.Health / hum.MaxHealth) * 100
                if HpPercent < _G.HealthPercent then
                    hrp.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y + 200, hrp.Position.Z)
                    task.wait(0.5); return
                end

                local Dungeon
                local DungeonId = Character:GetAttribute("Dungeon")
                local GuiService = game:GetService("GuiService")
                local VirtualInputManager = game:GetService("VirtualInputManager")

                if Player.PlayerGui:FindFirstChild("WaveUI")
                   and Player.PlayerGui.WaveUI.AutoSkip.BackgroundColor3 == Color3.fromRGB(255, 69, 69) then
                    GuiService.SelectedObject = Player.PlayerGui.WaveUI.AutoSkip
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
                    local Target, MinDist = nil, math.huge
                    for _, Mob in ipairs(workspace.Mob:GetChildren()) do
                        if Mob:IsA("Model")
                           and Mob:FindFirstChild("Humanoid")
                           and Mob:FindFirstChild("HumanoidRootPart")
                           and Mob.Humanoid.Health > 0 then
                            local dist = (Mob.HumanoidRootPart.Position - Dungeon:GetPivot().Position).Magnitude
                            if dist <= 250 and dist < MinDist then
                                MinDist = dist; Target = Mob
                            end
                        end
                    end
                    if Target then
                        _G.CanAutoSkill = true
                        local tHrp = Target.HumanoidRootPart
                        Target.Humanoid.WalkSpeed = 0
                        Target.Humanoid.JumpPower = 0
                        local bp = hrp:FindFirstChild("DungeonBP")
                        if not bp then
                            bp = Instance.new("BodyPosition")
                            bp.Name = "DungeonBP"
                            bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                            bp.P = 100000; bp.D = 3000
                            bp.Parent = hrp
                        end
                        local targetPos = tHrp.Position + Vector3.new(0, _G.DungeonHeight or 25, 0)
                        bp.Position = targetPos
                        hrp.CFrame = CFrame.new(targetPos, tHrp.Position)
                        EquipWeapon(); AutoSkill(); Attack()
                    else
                        _G.CanAutoSkill = false
                        if hrp:FindFirstChild("DungeonBP") then hrp.DungeonBP:Destroy() end
                    end
                else
                    _G.CanAutoSkill = false
                    local TeleportZone = workspace:FindFirstChild("TeleportDungeonZone")
                    if TeleportZone and TeleportZone:FindFirstChild("Hitbox") then
                        hrp.CFrame = TeleportZone.Hitbox.CFrame
                    else
                        if GetItemAmount("Orb Dungeon") >= _G.Dungeon_UseValue then
                            local NPC = workspace.NpcPrompt["Open Dungeon"].HumanoidRootPart
                            hrp.CFrame = NPC.CFrame * CFrame.new(0, 5, 0)
                            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                                "fire", nil, "SpawnDungeon", _G.Dungeon_UseValue
                            )
                        end
                    end
                end
            end, print)
        end
    end)

    -- ============================================================
    -- 🆕 B6c: AUTO CRAFT WEAPON
    -- ============================================================
    task.spawn(function()
        local lastNotifyTime = 0
        local lastCraftTime = 0
        local CRAFT_INTERVAL = 0.5
        local NOTIFY_INTERVAL = 5
        local lastMissingKey = nil
        local lastMissingNotify = 0

        while task.wait(0.1) do
            xpcall(function()
                if not _G.Auto_CraftWeapon then return end
                if not _G.Select_Item or _G.Select_Item == "" then return end
                local Data = UseItems and UseItems[_G.Select_Item]
                if not Data then return end
                if Data.NeedClass then
                    local PlayerClass = LocalPlayer:GetAttribute("UseClass")
                    if PlayerClass ~= Data.NeedClass then return end
                end
                local needBeli = (Data.PlayerData and Data.PlayerData.Beli) or 0
                local currentBeli = LocalPlayer:GetAttribute("Beli") or 0
                if needBeli > 0 and currentBeli < needBeli then return end

                local Inv = GetInventory()
                local missingItems = {}
                local haveAll = true
                for Item, Need in pairs(Data.Inventory) do
                    local Have = Inv[Item] and Inv[Item].amount or 0
                    if Have < Need then
                        haveAll = false
                        table.insert(missingItems, Item)
                    end
                end
                if not haveAll then return end

                if tick() - lastCraftTime >= CRAFT_INTERVAL then
                    lastCraftTime = tick()
                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
                        :FireServer("fire", nil, "Craft", _G.Select_Item, Data.Type)
                end
            end, print)
        end
    end)

    -- ============================================================
    -- 🆕 B6d: UPDATE ITEM REQUIREMENTS INFO
    -- ============================================================
    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                if not UseItems then return end
                if not _G.Select_Item or _G.Select_Item == "" then
                    Item_Auto:SetTitle("Item Requirements ( Not selected )")
                    Item_Auto:SetContent("📖 Select Weapon from dropdown")
                    return
                end
                local Data = UseItems[_G.Select_Item]
                if not Data then return end
                local Inv = GetInventory()
                local Text = {}
                table.insert(Text, "📦 Weapon: " .. _G.Select_Item)
                table.insert(Text, "🎓 Class: " .. (Data.NeedClass or "None"))
                table.insert(Text, "💰 Beli: " .. tostring((Data.PlayerData and Data.PlayerData.Beli) or 0))
                for Item, Need in pairs(Data.Inventory) do
                    local Have = Inv[Item] and Inv[Item].amount or 0
                    local status = Have >= Need and "✅" or "❌"
                    table.insert(Text, string.format("%s %s: %d/%d", status, Item, Have, Need))
                end
                Item_Auto:SetTitle("Item Requirements (" .. _G.Select_Item .. ")")
                Item_Auto:SetContent(table.concat(Text, "\n"))
            end)
        end
    end)

    -- ============================================================
    -- 🆕 B6e: AUTO FARM SET
    -- ============================================================
    task.spawn(function()
        while task.wait() do
            if _G.Auto_Farm_Set then
                pcall(function()
                    local Data = UseItems and UseItems[_G.Select_Item]
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
                        for _, Mob in ipairs(workspace.Mob:GetChildren()) do
                            if Mob:IsA("Model") and Mob.Name == MobName
                               and Mob:FindFirstChild("Humanoid") and Mob.Humanoid.Health > 0 then
                                local HRP = Mob.HumanoidRootPart
                                Mob.Humanoid.WalkSpeed = 0
                                Mob.Humanoid.JumpPower = 0
                                _G.CanAutoSkill = true
                                repeat task.wait()
                                    EquipWeapon(); AutoSkill(); Attack()
                                    Teleport(HRP.CFrame * GetMethodFarm())
                                    Inv = GetInventory()
                                    Have = Inv[NeedFarmItem] and Inv[NeedFarmItem].amount or 0
                                until not _G.Auto_Farm_Set or not Mob.Parent or Mob.Humanoid.Health <= 0
                                       or Have >= ((LowestSet + 1) * NeedAmount)
                                _G.CanAutoSkill = false
                                return
                            end
                        end
                        local Spawn = workspace.Itemdrops:FindFirstChild(MobName)
                        if Spawn then Teleport(Spawn:GetPivot()); task.wait(1.5) end
                    end
                end)
            end
        end
    end)

    print("[MainTab] ✅ Loaded")
end
