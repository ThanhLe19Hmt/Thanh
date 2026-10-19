-- UI chung
local Window            = ...
local Tab2              = Window:CreateTab("Main", false, false)   -- 🆕 giữ ở main

-- Hàm dùng chung
GetInventory, GetItemAmount, GetQuest_Level, GetQuestFrame
EquipWeapon, AutoSkill, Attack, Teleport
GetMethodFarm = function() return MethodFarm end
NoVFX (nếu có)

-- Dữ liệu
ItemDrop, ItemAll, Quest_List, Bosses, WeaponAll, UseItems
CraftingTable, PointItemM, PointItemMoon, Economy
X2List, SpawnList, X2List

-- _G shared
