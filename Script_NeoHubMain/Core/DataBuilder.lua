-- Core/DataBuilder.lua
-- Build tất cả data lists từ game modules

local Services = require(script.Parent.Services)
local Helpers  = require(script.Parent.Helpers)

local ReplicatedStorage = Services.ReplicatedStorage
local workspace = game:GetService("Workspace")

local DataBuilder = {}

function DataBuilder.Build()
    local Data = {
        Quest_List  = {},
        WeaponAll   = {},
        MonsterDrop = {},
        ItemDrop    = {},
        ItemToMob   = {},
        ItemAll     = {},
        X2List      = {},
        Poitem      = {},
        PoiteMoon   = {},
        SellItems   = {},
        Bosses      = {},
    }

    local Npc_Quest = Helpers.SafeWait(workspace, "NpcQuest", 3)
    local Itemdrops = Helpers.SafeWait(workspace, "Itemdrops", 3)
    local ModulesFolder = Helpers.SafeWait(ReplicatedStorage, "Modules", 3)

    local UseItems        = Helpers.SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("UseItems"))
    local CraftingTable   = Helpers.SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("CraftingTable"))
    local Quest_Module    = Helpers.SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("QuestModule"))
    local ItemList        = Helpers.SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("Itemlist"))
    local SpawnBossList   = Helpers.SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("SpawnBossList"))
    local Blacklist       = Helpers.SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("BlacklistItemTrade"))
    local AccessoryModule = Helpers.SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("AccessoryModule"))
    local PointItemM      = Helpers.SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("GaranteeRandomItem"))
    local PointItemMoon   = Helpers.SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("GaranteeEventMoon"))
    local Economy         = Helpers.SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("Economy"))

    -- === POITEM (Diamond Guarantee) ===
    if PointItemM then
        local temp = {}
        for Item, Price in pairs(PointItemM) do
            table.insert(temp, {Name = Item, Price = Price})
        end
        table.sort(temp, function(a, b) return a.Price < b.Price end)
        for i, d in ipairs(temp) do
            Data.Poitem[i] = d.Name .. " / " .. d.Price .. " Point"
        end
    end

    -- === POITEM MOON ===
    if PointItemMoon then
        local temp = {}
        for Item, Price in pairs(PointItemMoon) do
            table.insert(temp, {Name = Item, Price = Price})
        end
        table.sort(temp, function(a, b) return a.Price < b.Price end)
        for i, d in ipairs(temp) do
            Data.PoiteMoon[i] = d.Name .. " / " .. d.Price .. " Point"
        end
    end

    -- === QUEST LIST ===
    if Quest_Module and Npc_Quest then
        pcall(function()
            table.sort(Quest_Module, function(a, b) return a.Level < b.Level end)
            for i, data in ipairs(Quest_Module) do
                local NPC = Npc_Quest:WaitForChild("NPC_Quest" .. i, 2)
                if NPC then
                    Data.Quest_List[i] = {
                        Level = data.Level,
                        Monster = NPC:GetAttribute("Name"),
                        Quest = NPC,
                    }
                end
            end
        end)
    end

    -- === WEAPON ALL ===
    if UseItems then
        for Weapon in pairs(UseItems) do
            table.insert(Data.WeaponAll, Weapon)
        end
        table.sort(Data.WeaponAll)
    end

    -- === X2 LIST ===
    if Blacklist then
        for ItemName in pairs(Blacklist) do
            if ItemName:find("X2") then
                table.insert(Data.X2List, ItemName)
            end
        end
    end

    -- === MONSTER DROP ===
    if Itemdrops then
        pcall(function()
            for _, Mob in ipairs(Itemdrops:GetChildren()) do
                local ScrollingFrame = Mob:FindFirstChild("ScrollingFrame", true)
                if ScrollingFrame then
                    Data.MonsterDrop[Mob.Name] = {}
                    for _, v in ipairs(ScrollingFrame:GetDescendants()) do
                        if v:IsA("TextLabel") and v.Text and v.Text ~= "" then
                            if not v.Text:find("%%") then
                                Data.MonsterDrop[Mob.Name][v.Text] = true
                                Data.ItemDrop[v.Text] = Data.ItemDrop[v.Text] or {}
                                table.insert(Data.ItemDrop[v.Text], Mob.Name)
                                Data.ItemToMob[v.Text] = Mob.Name
                            end
                        end
                    end
                end
            end
        end)
    end

    -- === ITEM ALL (không tính Accessory) ===
    if ItemList then
        for ItemName in pairs(Data.ItemToMob) do
            local d = ItemList[ItemName]
            if not (d and d.Type == "Accessory") then
                table.insert(Data.ItemAll, ItemName)
            end
        end
        table.sort(Data.ItemAll)
    end

    -- === BOSSES ===
    if SpawnBossList then
        for BossName in pairs(SpawnBossList) do
            table.insert(Data.Bosses, BossName)
        end
        table.sort(Data.Bosses)
    end

    if #Data.Bosses == 0 then
        Data.Bosses = {"Bacon Thief", "Piccolo", "Duck Monster", "Devil Boat"}
    end
    if #Data.WeaponAll == 0 then
        Data.WeaponAll = {"Melee", "Sword", "Special", "DevilFruit"}
    end

    -- === MODULES EXPORT ===
    Data.UseItems        = UseItems
    Data.CraftingTable   = CraftingTable
    Data.Quest_Module    = Quest_Module
    Data.ItemList        = ItemList
    Data.SpawnBossList   = SpawnBossList
    Data.Blacklist       = Blacklist
    Data.AccessoryModule = AccessoryModule
    Data.PointItemM      = PointItemM
    Data.PointItemMoon   = PointItemMoon
    Data.Economy         = Economy

    return Data
end

return DataBuilder
