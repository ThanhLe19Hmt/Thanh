--[[
    Features/AutoChest.lua
    Random Diamond Chest, Moon Chest, Guarantee Points
]]

local Globals = _G.__Globals
assert(Globals, "[Module] _G.__Globals chưa được set! Load Main.lua trước.")
local RS = Globals.ReplicatedStorage
local LP = Globals.LocalPlayer

-- ===== Random Chest =====
task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_RandomChest then
                RS.Modules.NetworkFramework.NetworkEvent
                    :FireServer("fire", nil, "RandomItem", _G.Select_Random)
            end
        end)
    end
end)

-- ===== Moon Chest =====
task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_RandomChest_Moon then
                RS.Modules.NetworkFramework.NetworkEvent
                    :FireServer("fire", nil, "EventMoon", _G.Select_Random_Moon)
            end
        end)
    end
end)

-- ===== Guarantee Diamond =====
task.spawn(function()
    while task.wait() do
        if _G.Auto_Guarantee then
            local point = tonumber(LP:GetAttribute("PointItem")) or 0
            local price = Globals.PointItemM[_G.Select_Guarantee] or 0
            if _G.Select_Guarantee and point >= price then
                RS.Modules.NetworkFramework.NetworkEvent
                    :FireServer("fire", nil, "BuyGaranteeRandomItem", _G.Select_Guarantee)
            end
        end
    end
end)

-- ===== Guarantee Moon =====
task.spawn(function()
    while task.wait() do
        if _G.Auto_Guarantee_Moon then
            local point = tonumber(LP:GetAttribute("MoonPoint")) or 0
            local price = Globals.PointItemMoon[_G.Select_Guarantee_Moon] or 0
            if _G.Select_Guarantee_Moon and point >= price then
                RS.Modules.NetworkFramework.NetworkEvent
                    :FireServer("fire", nil, "BuyGaranteeEventMoon", _G.Select_Guarantee_Moon)
            end
        end
    end
end)
