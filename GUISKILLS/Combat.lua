--[[
    Combat Module: Skills, Attack, Equip, Farm helpers
]]

local Core = loadstring(game:HttpGet("URL_CORE"))()  -- thay URL
local ReplicatedStorage = Core.Services.ReplicatedStorage
local LocalPlayer = Core.Services.LocalPlayer

local Combat = {}

-- Config (dùng _G để share với UI)
_G.MainWeapon = "Melee"
_G.Select_EquipWeapon = {}
_G.Select_Method = "Upper"
_G.Distance_Farm = 5
_G.AutoSkillZ = false
_G.AutoSkillX = false
_G.AutoSkillC = false
_G.AutoSkillV = false
_G.AutoSkillF = false
_G.Auto_Haki = false

-- Cache MethodFarm CFrame (không cần loop update mỗi frame)
local MethodFarm = CFrame.new(0,5,0) * CFrame.Angles(math.rad(-90),0,0)

local function RecalcMethodFarm()
    local dist = _G.Distance_Farm
    local m = _G.Select_Method
    if m == "Behind" then
        MethodFarm = CFrame.new(0, 0, dist)
    elseif m == "Front" then
        MethodFarm = CFrame.new(0, 0, -dist) * CFrame.Angles(0, math.rad(180), 0)
    elseif m == "Below" then
        MethodFarm = CFrame.new(0, -dist, 0) * CFrame.Angles(math.rad(90), 0, 0)
    elseif m == "Upper" then
        MethodFarm = CFrame.new(0, dist, 0) * CFrame.Angles(math.rad(-90), 0, 0)
    else
        MethodFarm = CFrame.new(0, dist, 0) * CFrame.Angles(math.rad(-90), 0, 0)
    end
end

-- Đăng ký task cập nhật MethodFarm (thay vì loop riêng)
Core.TaskManager:Register("MethodFarmUpdater", function()
    RecalcMethodFarm()
    task.wait(0.5)
end)
Core.TaskManager:Start("MethodFarmUpdater")

function Combat.GetMethodFarm() return MethodFarm end

-- ============================================================
-- EQUIP WEAPON (tối ưu)
-- ============================================================
function Combat.EquipWeapon()
    local char = LocalPlayer.Character
    if not char then return end
    local backpack = LocalPlayer.Backpack

    local mainType = _G.MainWeapon
    local supportTypes = _G.Select_EquipWeapon or {}

    local wantedTypes = { [mainType] = true }
    for _, t in ipairs(supportTypes) do wantedTypes[t] = true end

    -- Bỏ tool không cần
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then
            local t = v:GetAttribute("Type")
            if not wantedTypes[t] then
                v.Parent = backpack
            end
        end
    end

    -- Trang bị tool cần
    for _, v in ipairs(backpack:GetChildren()) do
        if v:IsA("Tool") then
            local t = v:GetAttribute("Type")
            if wantedTypes[t] then
                v.Parent = char
            end
        end
    end
end

-- ============================================================
-- AUTO SKILL (chỉ fire skill có bật)
-- ============================================================
local SkillKeys = { "z", "x", "c", "v", "f" }
local SkillToggles = {
    z = "_G.AutoSkillZ",
    x = "_G.AutoSkillX",
    c = "_G.AutoSkillC",
    v = "_G.AutoSkillV",
    f = "_G.AutoSkillF",
}

function Combat.AutoSkill()
    local char = LocalPlayer.Character
    if not char then return end

    local activeSkills = {}
    if _G.AutoSkillZ then table.insert(activeSkills, "z") end
    if _G.AutoSkillX then table.insert(activeSkills, "x") end
    if _G.AutoSkillC then table.insert(activeSkills, "c") end
    if _G.AutoSkillV then table.insert(activeSkills, "v") end
    if _G.AutoSkillF then table.insert(activeSkills, "f") end
    if #activeSkills == 0 then return end

    local skill = activeSkills[math.random(#activeSkills)]
    local action = Core.GetAction()
    if not action then return end

    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            action:FireServer(tool.Name, skill)
        end
    end
end

-- ============================================================
-- ATTACK
-- ============================================================
function Combat.Attack()
    local char = LocalPlayer.Character
    if not char then return end
    local action = Core.GetAction()
    if not action then return end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then
            action:FireServer(v.Name, "hit")
        end
    end
end

-- ============================================================
-- AUTO HAKI
-- ============================================================
Core.TaskManager:Register("AutoHaki", function()
    if _G.Auto_Haki then
        local char = LocalPlayer.Character
        if char and not char:FindFirstChild("HakiFolder") then
            local action = Core.GetAction()
            if action then
                action:FireServer("Misc", "buso")
            end
        end
    end
    task.wait(0.5)
end)
Core.TaskManager:Start("AutoHaki")

-- ============================================================
-- FARM LOOP HELPER (dùng chung cho nhiều tính năng)
-- ============================================================
--[[
    Combat.FarmTarget(targetModel, shouldStop)
    - targetModel: Model có Humanoid + HumanoidRootPart
    - shouldStop: function trả về true nếu cần dừng
]]
function Combat.FarmTarget(targetModel, shouldStop)
    if not targetModel or not targetModel.Parent then return end
    local hum = targetModel:FindFirstChildOfClass("Humanoid")
    local hrp = targetModel:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then return end

    hum.WalkSpeed = 0
    hum.JumpPower = 0

    repeat
        task.wait(0.03)
        if shouldStop and shouldStop() then break end
        if not targetModel.Parent then break end
        if hum.Health <= 0 then break end

        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then break end
        if char:FindFirstChildOfClass("Humanoid").Health <= 0 then break end

        Combat.EquipWeapon()
        Combat.AutoSkill()
        Combat.Attack()
        Core.Teleport(hrp.CFrame * MethodFarm)
    until false
end

-- ============================================================
-- ANTI-NOCLIP VELOCITY RESET
-- ============================================================
Core.TaskManager:Register("VelocityReset", function()
    local char, _, hrp = Core.GetCharacter()
    if hrp then
        hrp.AssemblyAngularVelocity = Vector3.zero
        local v = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
    end
    task.wait(0.1)
end)

-- ============================================================
-- BODY CLIP (anti push)
-- ============================================================
Core.TaskManager:Register("BodyClipManager", function()
    local char, _, hrp = Core.GetCharacter()
    if hrp then
        local isFarming = _G.Auto_Farm_Level or _G.Auto_CraftWeapon or _G.Auto_Farm_Material
            or _G.Auto_FarmBoss or _G.Auto_FarmBoss_Automatically
            or _G.Auto_Duck or _G.Auto_DuckAutomatically or _G.Auto_Farm_Set
            or _G.Auto_Raid or _G.Auto_BaconThief or _G.Auto_Dungeon
            or _G.Auto_Piccolo or _G.Auto_DevilBoat

        if isFarming then
            if not hrp:FindFirstChild("BodyClip") then
                local bv = Instance.new("BodyVelocity")
                bv.Name = "BodyClip"
                bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                bv.Velocity = Vector3.zero
                bv.Parent = hrp
            end
        else
            local bc = hrp:FindFirstChild("BodyClip")
            if bc then bc:Destroy() end
        end
    end
    task.wait(0.1)
end)
Core.TaskManager:Start("BodyClipManager")

return Combat
