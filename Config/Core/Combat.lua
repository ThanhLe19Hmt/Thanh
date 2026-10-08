--[[
    Core/Combat.lua
    EquipWeapon, Attack, AutoSkill
]]

local Combat = {}

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer

-- ===== AutoSkill =====
function Combat.AutoSkill()
    local char = LocalPlayer.Character
    if not char then return end

    local skills = {}
    if _G.AutoSkillZ then table.insert(skills, "z") end
    if _G.AutoSkillX then table.insert(skills, "x") end
    if _G.AutoSkillC then table.insert(skills, "c") end
    if _G.AutoSkillV then table.insert(skills, "v") end
    if _G.AutoSkillF then table.insert(skills, "f") end
    if #skills == 0 then return end

    local skill = skills[math.random(#skills)]
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            ReplicatedStorage.Remotes.Action:FireServer(tool.Name, skill)
        end
    end
end

-- ===== Equip Weapon =====
function Combat.EquipWeapon()
    local char = LocalPlayer.Character
    if not char then return end
    local backpack = LocalPlayer.Backpack
    local mainType = _G.MainWeapon
    local MainTool

    -- Tìm MainTool đang cầm
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") and v:GetAttribute("Type") == mainType then
            MainTool = v
            break
        end
    end

    -- Nếu chưa cầm, tìm trong Backpack
    if not MainTool then
        for _, v in ipairs(backpack:GetChildren()) do
            if v:IsA("Tool") and v:GetAttribute("Type") == mainType then
                MainTool = v
                break
            end
        end
    end

    -- Cất hết tool không phải MainTool
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") and v ~= MainTool then
            v.Parent = backpack
        end
    end

    if MainTool and MainTool.Parent ~= char then
        MainTool.Parent = char
    end

    -- Equip support weapons
    if type(_G.Select_EquipWeapon) == "table" then
        for _, t in ipairs(_G.Select_EquipWeapon) do
            if t ~= mainType then
                for _, v in ipairs(backpack:GetChildren()) do
                    if v:IsA("Tool") and v:GetAttribute("Type") == t and v ~= MainTool then
                        v.Parent = char
                    end
                end
            end
        end
    end
end

-- ===== Attack =====
function Combat.Attack()
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then
            ReplicatedStorage.Remotes.Action:FireServer(v.Name, "hit")
        end
    end
end

-- ===== Full attack cycle =====
function Combat.DoAttack()
    Combat.EquipWeapon()
    Combat.AutoSkill()
    Combat.Attack()
end

return Combat
