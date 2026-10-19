-- Bosses/FarmBossFull.lua
local Services = require(script.Parent.Parent.Core.Services)
local Helpers  = require(script.Parent.Parent.Core.Helpers)

local LocalPlayer = Services.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage
local Data = _G.Data
local Teleport = Helpers.Teleport
local GetItemAmount = Helpers.GetItemAmount

local MethodFarm = CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-90), 0, 0)

task.spawn(function()
    local lastSummonTime = 0
    local summonCooldown = 1.5

    while task.wait() do
        xpcall(function()
            MethodFarm = CFrame.new(0, _G.Distance_Farm or 5, 0)
                * CFrame.Angles(math.rad(-90), 0, 0)
            if not _G.Auto_FarmBoss then return end
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then
                _G.CanAutoSkill = false
                return
            end
            local bossFolder = workspace:FindFirstChild("Boss")
            if not bossFolder then return end
            local Boss
            for _, v in pairs(bossFolder:GetChildren()) do
                if table.find(Data.Bosses, v.Name)
                   and v:FindFirstChild("Humanoid")
                   and v:FindFirstChild("HumanoidRootPart")
                   and v.Humanoid.Health > 0 then
                    Boss = v
                    break
                end
            end
            if Boss then
                _G.CanAutoSkill = true
                lastSummonTime = 0
                Boss.Humanoid.WalkSpeed = 0
                Boss.Humanoid.JumpPower = 0
                local tHrp = Boss.HumanoidRootPart
                _G.EquipWeapon(); _G.AutoSkill(); _G.Attack()
                Teleport(tHrp.CFrame * MethodFarm)
                return
            end
            _G.CanAutoSkill = false
            local now = tick()
            if now - lastSummonTime < summonCooldown then return end
            if GetItemAmount("Orb Boss") >= 1 and _G.Select_Boss then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                    "fire", nil, "SummonBoss", _G.Select_Boss)
                lastSummonTime = now
                return
            end
            _G.Auto_FarmBoss = false
            _G.SeaNotify("❌ Out of Orb Boss", "Auto Farm Boss disabled", 5)
        end, function(err) warn("[FarmBossFull]", err) end)
    end
end)
