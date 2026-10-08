--[[
    UI/MainTab.lua
    Tab "Main" - Farm, Boss, Raid, Dungeon
]]

local MainTab = {}
local Globals = _G.__Globals or Globals

-- Pre-build item lists
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
end

function MainTab:Init(Window)
    BuildLists()

    local Tab2 = Window:CreateTab("Main", false, false)
    local Farm        = Tab2:CreatePage("Farm")
    local AllBoss     = Tab2:CreatePage("Boss")
    local RaidBossPg  = Tab2:CreatePage("Raid Boss & Shop!!")
    local RaidDun     = Tab2:CreatePage("Dungeon, Shop / Weapon")

    -- ===== Farm Page =====
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

    -- ===== Boss Page =====
    local Boss     = AllBoss:CreateSection("👹 Boss", "Left")
    local Thief    = AllBoss:CreateSection("💸 Thief", "Left")
    local Piccolo  = AllBoss:CreateSection("🐉 Piccolo", "Left")
    local SpawnedT = AllBoss:CreateSection("🔍 Spawned Check", "Right")
    local Duck     = AllBoss:CreateSection("🦆 Duck", "Right")
    local DevilBoat= AllBoss:CreateSection("⛵ Devil Boat", "Right")

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

    -- Loop update spawn status
    task.spawn(function()
        while task.wait() do
            pcall(function()
                local text = {}
                for display, mobName in pairs(Globals.SpawnList) do
                    local spawned = false
                    local names = {mobName}
                    if mobName == "Devil Boat" then
                        table.insert(names, "DevilBoat")
                    end
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

    -- ===== Raid Dungeon Page =====
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
                Globals.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
                    :FireServer("fire", nil, "Quest", "Cancel")
            end
        end
    })

    -- Lưu refs để module khác dùng
    MainTab.Item_Auto   = Item_Auto
    MainTab.NotifyClass = function() return NotifyClass end
    MainTab.SetNotifyClass = function(v) NotifyClass = v end
end

return MainTab
