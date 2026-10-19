-- Bosses/FarmPiccolo.lua
local Services = require(script.Parent.Parent.Core.Services)
local Helpers  = require(script.Parent.Parent.Core.Helpers)
local LocalPlayer = Services.LocalPlayer
local Teleport = Helpers.Teleport
local MethodFarm = CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-90), 0, 0)

task.spawn(function()
    while task.wait() do
        if _G.Auto_Piccolo then
            pcall(function()
                MethodFarm = CFrame.new(0, _G.Distance_Farm or 5, 0)
                    * CFrame.Angles(math.rad(-90), 0, 0)
                local mobFolder = workspace:FindFirstChild("Mob")
                if not mobFolder then return end
                for _, v in ipairs(mobFolder:GetChildren()) do
                    if v:IsA("Model") and v.Name == "Piccolo"
                       and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        v.Humanoid.WalkSpeed = 0
                        v.Humanoid.JumpPower = 0
                        _G.CanAutoSkill = true
                        repeat task.wait()
                            _G.EquipWeapon(); _G.AutoSkill(); _G.Attack()
                            Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
                        until not _G.Auto_Piccolo or not v.Parent or v.Humanoid.Health <= 0
                        _G.CanAutoSkill = false
                    end
                end
            end)
        end
    end
end)
