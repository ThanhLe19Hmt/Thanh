--[[
    Features/AutoPotion.lua
    Auto Use X2 Potion
]]

local Globals = _G.__Globals
assert(Globals, "[Module] _G.__Globals chưa được set! Load Main.lua trước.")
local RS = Globals.ReplicatedStorage
local LP = Globals.LocalPlayer

task.spawn(function()
    while task.wait(0.3) do
        if _G.Auto_Use_Potion then
            pcall(function()
                local inv = RS.Remotes.Inventory
                local sel = _G.Select_Potion
                if not sel then return end
                if sel["X2 EXP 15min."] and tonumber(LP:GetAttribute("x2ExpTime")) == 0 then
                    inv:FireServer("X2 EXP 15min.")
                end
                if sel["X2 Diamond 15min."] and tonumber(LP:GetAttribute("x2DiamondTime")) == 0 then
                    inv:FireServer("X2 Diamond 15min.")
                end
                if sel["X2 Lucky 15min."] and tonumber(LP:GetAttribute("x2LuckTime")) == 0 then
                    inv:FireServer("X2 Lucky 15min.")
                end
                if sel["X2 Rebirth 15min."] and tonumber(LP:GetAttribute("x2RebirthTime")) == 0 then
                    inv:FireServer("X2 Rebirth 15min.")
                end
                if sel["X2 Item 15min."] and tonumber(LP:GetAttribute("x2ItemTime")) == 0 then
                    inv:FireServer("X2 Item 15min.")
                end
            end)
        end
    end
end)
