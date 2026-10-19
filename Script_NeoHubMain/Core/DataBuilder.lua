-- Core/DataBuilder.lua
-- Build tất cả data lists từ game modules

local Services = require(script.Parent.Services)
local Helpers  = require(script.Parent.Helpers)

local ReplicatedStorage = Services.ReplicatedStorage
local workspace = game:GetService("Workspace")

local DataBuilder = {}

DataBuilder.Quest_List  = {}
DataBuilder.WeaponAll   = {}
DataBuilder.MonsterDrop = {}
DataBuilder.ItemDrop    = {}
DataBuilder.ItemToMob   = {}
DataBuilder.ItemAll     = {}
DataBuilder.X2List      = {}
DataBuilder.Poitem      = {}
DataBuilder.PoiteMoon   = {}
DataBuilder.SellItems   = {}
DataBuilder.Bosses      = {}

function DataBuilder.Build()
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

    -- ... (logic build giống bản gốc)
    -- Copy toàn bộ logic build Quest_List, WeaponAll, ItemDrop, v.v.
    
    return {
        UseItems        = UseItems,
        CraftingTable   = CraftingTable,
        Quest_Module    = Quest_Module,
        ItemList        = ItemList,
        SpawnBossList   = SpawnBossList,
        Blacklist       = Blacklist,
        AccessoryModule = AccessoryModule,
        PointItemM      = PointItemM,
        PointItemMoon   = PointItemMoon,
        Economy         = Economy,
    }
end

return DataBuilder
