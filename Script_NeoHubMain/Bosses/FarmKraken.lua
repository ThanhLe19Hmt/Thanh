-- Bosses/FarmKraken.lua
local Services = require(script.Parent.Parent.Core.Services)
local Helpers  = require(script.Parent.Parent.Core.Helpers)
local LocalPlayer = Services.LocalPlayer
local Teleport = Helpers.Teleport
local MethodFarm = CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-90), 0, 0)

task.spawn(function()
    while task.wait() do
        xpcall(function()
            MethodFarm = CFrame.new(0, _G.Distance_Farm or 5, 0)
                * CFrame.Angles(math.rad(-90), 0, 0)
            if not _G.Auto_Kraken then
                _G.CanAutoSkill = false; return
            end
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then
                _G.CanAutoSkill = false; return
            end
            local mobFolder = workspace:FindFirstChild("Mob")
            if not mobFolder then return end
            local Kraken
            for _, v in ipairs(mobFolder:GetChildren()) do
                if v:IsA("Model") and v.Name == "Kraken"
                   and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                    Kraken = v; break
                end
            end
            if not Kraken then
                _G.CanAutoSkill = false; return
            end
            _G.CanAutoSkill = true
            Kraken.Humanoid.WalkSpeed = 0
            Kraken.Humanoid.JumpPower = 0
            _G.EquipWeapon(); _G.AutoSkill(); _G.Attack()
            Teleport(Kraken.HumanoidRootPart.CFrame * MethodFarm)
        end, function(err) warn("[FarmKraken]", err) end)
    end
end)
