-- RaidMoon/MoonFarm.lua
-- Auto Farm Moon Mob

local Services = require(script.Parent.Parent.Core.Services)
local Helpers  = require(script.Parent.Parent.Core.Helpers)
local Config   = require(script.Parent.Parent.Core.Config)
local MoonRocket = require(script.MoonRocket)
local MoonTarget = require(script.MoonTarget)

local LocalPlayer = Services.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage
local CFG = Config.Moon

_G.MoonRunning = false

local MoonCurrentTarget = nil
local MoonLastAttack    = 0
local MoonLastSkill     = 0
local MoonLastEquip     = 0
local MoonSettleTime    = 0
local MoonLastAction    = 0
local MoonAtCave        = false
local MoonJitterSeed    = 0
local MoonLastMobHealth = 0
local MoonDamageCheckTime = 0
local MoonStuckCount    = 0
local MoonLastStuckTime = 0

local CAVE_POS = CFG.CAVE_POS

local function GetHitOffset(mobHrp, myHrp)
    local dist = _G.MoonHitDistance or 12
    local mode = _G.MoonHitPosition or "Upper"
    if mode == "Upper" then return Vector3.new(dist * 0.1, dist, 0)
    elseif mode == "Below" then return Vector3.new(dist * 0.1, -dist, 0)
    elseif mode == "Behind" then
        local look = mobHrp.CFrame.LookVector
        if look.Magnitude > 0.01 then return -look * dist end
        if myHrp then return (mobHrp.Position - myHrp.Position).Unit * dist end
        return Vector3.new(0, 0, dist)
    elseif mode == "Front" then
        local look = mobHrp.CFrame.LookVector
        if look.Magnitude > 0.01 then return look * dist end
        if myHrp then return (myHrp.Position - mobHrp.Position).Unit * dist end
        return Vector3.new(0, 0, -dist)
    end
    return Vector3.new(0, dist, 0)
end

local function ClearConstraints(hrp)
    if not hrp then return end
    for _, child in ipairs(hrp:GetChildren()) do
        if child:IsA("BodyPosition") or child:IsA("BodyGyro")
           or child:IsA("AlignPosition") or child:IsA("AlignOrientation")
           or child:IsA("BodyVelocity") then
            child:Destroy()
        end
    end
end

local function AttachToMob(hrp, mobHrp)
    if not hrp or not hrp.Parent or not mobHrp or not mobHrp.Parent then return end
    ClearConstraints(hrp)
    hrp.Anchored = false
    local char = hrp.Parent
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false end
    local offset = GetHitOffset(mobHrp, hrp)
    local mobPos = mobHrp.Position + offset
    local lookAt = mobHrp.Position
    MoonJitterSeed = MoonJitterSeed + 1
    local j = Vector3.new(
        math.sin(MoonJitterSeed * 0.7) * 0.05,
        math.cos(MoonJitterSeed * 0.9) * 0.03,
        math.sin(MoonJitterSeed * 1.1) * 0.05)
    hrp.CFrame = CFrame.new(mobPos + j, lookAt)
    hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity * 0.3
    hrp.AssemblyAngularVelocity = Vector3.zero
end

local function StopAttach(hrp)
    if not hrp then
        hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    end
    if hrp then
        hrp.Anchored = false
        local hum = hrp.Parent and hrp.Parent:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = false end
        ClearConstraints(hrp)
    end
end

local DASH_SKILLS = {z = true, x = true, c = true, v = true}

local function ForceResetPosition(hrp, mobHrp)
    if not hrp or not hrp.Parent or not mobHrp or not mobHrp.Parent then return end
    local offset = GetHitOffset(mobHrp, hrp)
    hrp.CFrame = CFrame.new(mobHrp.Position + offset, mobHrp.Position)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

local function FireMoonSkill(hrp, mobHrp)
    local char = LocalPlayer.Character
    if not char then return end
    local Skills = {}
    if _G.AutoSkillZ then table.insert(Skills, "z") end
    if _G.AutoSkillX then table.insert(Skills, "x") end
    if _G.AutoSkillC then table.insert(Skills, "c") end
    if _G.AutoSkillV then table.insert(Skills, "v") end
    if _G.AutoSkillF then table.insert(Skills, "f") end
    if #Skills == 0 then return end
    local skill = Skills[math.random(#Skills)]
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local action = remotes and remotes:FindFirstChild("Action")
    if not action then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            pcall(function() action:FireServer(tool.Name, skill) end)
        end
    end
    if DASH_SKILLS[skill] and hrp and mobHrp then
        task.spawn(function()
            task.wait(0.05)
            ForceResetPosition(hrp, mobHrp)
            task.wait(0.05)
            ForceResetPosition(hrp, mobHrp)
        end)
    end
end

local function MoonEquipWeapon()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local main = _G.MainWeapon or "Melee"
        local support = _G.Select_EquipWeapon or {}
        local wanted = {[main] = true}
        for _, w in ipairs(support) do
            if type(w) == "string" then wanted[w] = true end
        end
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") and not wanted[v:GetAttribute("Type")] then
                v.Parent = LocalPlayer.Backpack
            end
        end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, v in ipairs(bp:GetChildren()) do
                if v:IsA("Tool") and wanted[v:GetAttribute("Type")] then
                    v.Parent = char
                end
            end
        end
    end)
end

local function MoonAttack()
    local char = LocalPlayer.Character
    if not char then return end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local action = remotes and remotes:FindFirstChild("Action")
    if not action then return end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then
            pcall(function() action:FireServer(v.Name, "hit") end)
        end
    end
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
task.spawn(function()
    while task.wait(0.03) do
        if not _G.MoonRunning then
            if MoonAtCave then
                MoonAtCave = false
                MoonCurrentTarget = nil
                MoonStuckCount = 0
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Anchored = false end
                local hum = char and char:FindFirstChild("Humanoid")
                if hum then hum.PlatformStand = false end
            end
            continue
        end

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then
            if hrp then hrp.Anchored = false end
            if hum then hum.PlatformStand = false end
            continue
        end

        if MoonLastAction > 0 and tick() - MoonLastAction > CFG.WATCHDOG then
            MoonCurrentTarget = nil
            MoonLastAction = tick()
        end

        local target, priorityText = MoonTarget.GetMoonTarget()
        if not target then
            _G.CanAutoSkill = false
            if not MoonAtCave then
                hrp.CFrame = CFrame.new(CAVE_POS)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                StopAttach(hrp)
                MoonAtCave = true
            end
            task.wait(0.3)
            continue
        end

        _G.CanAutoSkill = true

        if target ~= MoonCurrentTarget then
            MoonCurrentTarget = target
            MoonSettleTime = tick()
            MoonLastAction = tick()
            MoonAtCave = false
            MoonLastMobHealth = 0
            MoonStuckCount = 0
            StopAttach(hrp)
            local tHrp = target:FindFirstChild("HumanoidRootPart")
            if tHrp and hrp then
                local offset = GetHitOffset(tHrp, hrp)
                hrp.CFrame = CFrame.new(tHrp.Position + offset, tHrp.Position)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end

        local tHrp = target:FindFirstChild("HumanoidRootPart")
        if not tHrp then task.wait(0.05); continue end

        target.Humanoid.WalkSpeed = 0
        target.Humanoid.JumpPower = 0
        AttachToMob(hrp, tHrp)
        MoonLastAction = tick()

        -- Anti-stuck
        local nowHealth = target.Humanoid.Health
        if MoonLastMobHealth == 0 then
            MoonLastMobHealth = nowHealth
            MoonDamageCheckTime = tick()
        else
            if tick() - MoonDamageCheckTime >= CFG.STUCK_THRESHOLD then
                if (MoonLastMobHealth - nowHealth) < 1 then
                    if tick() - MoonLastStuckTime >= CFG.STUCK_COOLDOWN then
                        MoonStuckCount = MoonStuckCount + 1
                        MoonLastStuckTime = tick()
                        if MoonStuckCount >= CFG.STUCK_MAX then
                            _G.SeaNotify("🛑 Anti-cheat", "Auto Farm disabled", 8)
                            _G.MoonRunning = false
                            break
                        end
                    end
                else
                    MoonStuckCount = 0
                end
                MoonLastMobHealth = nowHealth
                MoonDamageCheckTime = tick()
            end
        end

        local now = tick()
        if now - MoonLastEquip >= 0.5 then
            MoonLastEquip = now
            MoonEquipWeapon()
        end

        if _G.AutoCombat and _G.MoonRunning and MoonCurrentTarget then
            local hasSkill = _G.AutoSkillZ or _G.AutoSkillX
                          or _G.AutoSkillC or _G.AutoSkillV or _G.AutoSkillF
            if not hasSkill and now - MoonLastAttack >= 0.15 then
                MoonLastAttack = now
                MoonAttack()
            end
        end
    end
end)

-- Skill loop riêng
task.spawn(function()
    while task.wait(0.05) do
        if not _G.MoonRunning or not _G.RaidAutoSkill then continue end
        if not _G.CanAutoSkill then continue end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        if not MoonCurrentTarget or not MoonCurrentTarget.Parent then continue end
        local tHrp = MoonCurrentTarget:FindFirstChild("HumanoidRootPart")
        if not tHrp then continue end
        if (hrp.Position - tHrp.Position).Magnitude > 40 then continue end
        if tick() - MoonSettleTime < CFG.SETTLE_DELAY then continue end
        FireMoonSkill(hrp, tHrp)
        task.wait(0.1 + math.random() * 0.1)
    end
end)

-- Auto Haki loop moon
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if not _G.MoonRunning then return end
            local char = LocalPlayer.Character
            if not char then return end
            if not char:FindFirstChild("HakiFolder") then
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                local action = remotes and remotes:FindFirstChild("Action")
                if action then action:FireServer("Misc", "buso") end
            end
        end)
    end
end)
