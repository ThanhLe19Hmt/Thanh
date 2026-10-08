--[[
    Features/AutoSell.lua
    Auto Sell items
]]

local Globals = _G.__Globals or Globals
local Inventory = Globals.Inventory
local RS = Globals.ReplicatedStorage

task.spawn(function()
    while task.wait() do
        xpcall(function()
            if not _G.Auto_SellItem then return end
            if type(_G.Select_SellItem) ~= "table" then return end
            for itemName, selected in pairs(_G.Select_SellItem) do
                local data = Globals.Economy[itemName]
                if selected and data then
                    if Inventory.GetAmount(itemName) >= data.amount then
                        RS.Modules.NetworkFramework.NetworkEvent
                            :FireServer("fire", nil, "Economy", itemName)
                    end
                end
            end
        end, print)
    end
end)
