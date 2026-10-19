-- Bosses/FarmThief.lua
local Services = require(script.Parent.Parent.Core.Services)
local Helpers  = require(script.Parent.Parent.Core.Helpers)
local LocalPlayer = Services.LocalPlayer
local Teleport = Helpers.Teleport
local MethodFarm = CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-90), 0, 0)

local CurrentSpawn = 1

task.spawn(function()
    while task.wait() do
        pcall(function()
            MethodFarm = CFrame.new(0, _G.Distance_Farm or 5, 0)
                * CFrame.Angles(math.rad(-90), 0, 0)
            if not _G.Auto_BaconThief then return end
            local mobSpawnGroup = workspace:FindFirstChild("MobSpawnGroup")
            if not mobSpawnGroup then return end
            local Spawns = mobSpawnGroup:GetChildren()
            local Spawn = Spawns[CurrentSpawn]
            if not Spawn then CurrentSpawn = 1; return end
            local ChestRef = Spawn:FindFirstChild("ChestRef", true)
            if ChestRef then
                local Target
                local minDist = 30
                local mobFolder = workspace:FindFirstChild("Mob")
                if mobFolder then
                    for _, Mob in ipairs(mobFolder:GetChildren()) do
                        if Mob:IsA("Model") and Mob.Name == "Bacon Thief"
                           and Mob:FindFirstChild("HumanoidRootPart")
                           and Mob:FindFirstChild("Humanoid")
                           and Mob.Humanoid.Health > 0 then
                            local d = (Mob.HumanoidRootPart.Position - ChestRef.Position).Magnitude
                            if d < minDist then minDist = d; Target = Mob end
                        end
                    end
                end
                if Target then
                    Target.Humanoid.WalkSpeed = 0
                    Target.Humanoid.JumpPower = 0
                    _G.CanAutoSkill = true
                    _G.EquipWeapon(); _G.AutoSkill(); _G.Attack()
                    Teleport(Target.HumanoidRootPart.CFrame * MethodFarm)
                else
                    _G.CanAutoSkill = false
                    local Prompt = ChestRef:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if Prompt and Prompt.Parent and Prompt.ActionText == "Open" then
                        Teleport(ChestRef.CFrame * CFrame.new(0, 3, 0))
                        pcall(function() fireproximityprompt(Prompt) end)
                    else
                        CurrentSpawn = CurrentSpawn + 1
                    end
                end
            else
                CurrentSpawn = CurrentSpawn + 1
            end
        end)
    end
end)
