-- Farm/FarmCraft.lua
local Services = require(script.Parent.Parent.Core.Services)
local Helpers  = require(script.Parent.Parent.Core.Helpers)

local LocalPlayer = Services.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage
local Data = _G.Data
local GetInventory = Helpers.GetInventory

local lastNotifyTime = 0
local lastCraftTime = 0
local CRAFT_INTERVAL = 0.5
local NOTIFY_INTERVAL = 5
local lastMissingKey = nil
local lastMissingNotify = 0

task.spawn(function()
    while task.wait(0.1) do
        xpcall(function()
            if not _G.Auto_CraftWeapon then return end
            if not _G.Select_Item or _G.Select_Item == "" then
                if tick() - lastNotifyTime > NOTIFY_INTERVAL then
                    lastNotifyTime = tick()
                    _G.SeaNotify("❌ No Weapon", "Choose first!", 3)
                end
                return
            end
            local itemData = Data.UseItems and Data.UseItems[_G.Select_Item]
            if not itemData then return end

            if itemData.NeedClass then
                if LocalPlayer:GetAttribute("UseClass") ~= itemData.NeedClass then
                    return
                end
            end

            local needBeli = (itemData.PlayerData and itemData.PlayerData.Beli) or 0
            local curBeli = LocalPlayer:GetAttribute("Beli") or 0
            if needBeli > 0 and curBeli < needBeli then return end

            local inv = GetInventory()
            local missing = {}
            local haveAll = true
            for Item, Need in pairs(itemData.Inventory) do
                local have = (inv[Item] and inv[Item].amount) or 0
                if have < Need then
                    haveAll = false
                    table.insert(missing, Item .. " (" .. have .. "/" .. Need .. ")")
                end
            end
            if not haveAll then
                local key = table.concat(missing, ",")
                if key ~= lastMissingKey or tick() - lastMissingNotify > NOTIFY_INTERVAL then
                    lastMissingKey = key
                    lastMissingNotify = tick()
                    _G.SeaNotify("❌ Missing", table.concat(missing, ", "), 4)
                end
                return
            end
            lastMissingKey = nil
            if tick() - lastCraftTime >= CRAFT_INTERVAL then
                lastCraftTime = tick()
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                    "fire", nil, "Craft", _G.Select_Item, itemData.Type)
            end
        end, print)
    end
end)
