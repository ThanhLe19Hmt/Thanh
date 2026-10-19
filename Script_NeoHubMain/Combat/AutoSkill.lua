-- Combat/Attack.lua
-- Attack + EquipWeapon

local Services = require(script.Parent.Parent.Core.Services)
local LocalPlayer = Services.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage

local Attack = {}

function Attack.EquipWeapon()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end

        -- Bỏ tool không phải main weapon
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") and v:GetAttribute("Type") ~= _G.MainWeapon then
                v.Parent = LocalPlayer.Backpack
            end
        end

        -- Equip main weapon
        for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if v:IsA("Tool") and v:GetAttribute("Type") == _G.MainWeapon then
                char.Humanoid:EquipTool(v)
                break
            end
        end

        -- Bỏ tool không thuộc support
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool")
               and v:GetAttribute("Type") ~= _G.MainWeapon
               and not table.find(_G.Select_EquipWeapon or {}, v:GetAttribute("Type")) then
                v.Parent = LocalPlayer.Backpack
            end
        end

        -- Equip support
        for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if v:IsA("Tool")
               and v:GetAttribute("Type") ~= _G.MainWeapon
               and table.find(_G.Select_EquipWeapon or {}, v:GetAttribute("Type")) then
                v.Parent = char
            end
        end
    end)
end

function Attack.Attack()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local action = remotes and remotes:FindFirstChild("Action")
        if not action then return end
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") then
                action:FireServer(v.Name, "hit")
            end
        end
    end)
end

return Attack
