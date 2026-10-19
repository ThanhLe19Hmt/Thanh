-- Bosses/FarmDuck.lua
local Services = require(script.Parent.Parent.Core.Services)
local Helpers  = require(script.Parent.Parent.Core.Helpers)

local LocalPlayer = Services.LocalPlayer
local Teleport = Helpers.Teleport
local GetItemAmount = Helpers.GetItemAmount
local MethodFarm = CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-90), 0, 0)

task.spawn(function()
    local lastSummonTime = 0
    local summonCooldown = 2.5
    while task.wait() do
        xpcall(function()
            MethodFarm = CFrame.new(0, _G.Distance_Farm or 5, 0)
                * CFrame.Angles(math.rad(-90), 0, 0)
            if not _G.Auto_DuckAutomatically then return end
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then
                _G.CanAutoSkill = false; return
            end
            local mobFolder = workspace:FindFirstChild("Mob")
            if not mobFolder then return end
            local Duck
            for _, v in pairs(mobFolder:GetChildren()) do
                if v:IsA("Model") and v.Name == "Duck Monster"
                   and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                    Duck = v; break
                end
            end
            if Duck then
                _G.CanAutoSkill = true
                lastSummonTime = 0
                Duck.Humanoid.WalkSpeed = 0
                Duck.Humanoid.JumpPower = 0
                _G.EquipWeapon(); _G.AutoSkill(); _G.Attack()
                Teleport(Duck.HumanoidRootPart.CFrame * MethodFarm)
                return
            end
            _G.CanAutoSkill = false
            local now = tick()
            if now - lastSummonTime < summonCooldown then return end
            local items = {"Duck","Duck2","Duck3","Duck4","Duck5","Duck6","Duck7"}
            local missing = {}
            local allHave = true
            for _, it in ipairs(items) do
                if GetItemAmount(it) <= 0 then
                    allHave = false
                    table.insert(missing, it)
                end
            end
            if allHave then
                local npcPrompt = workspace:FindFirstChild("NpcPrompt")
                local duckNPC = npcPrompt and npcPrompt:FindFirstChild("DuckMonster")
                if duckNPC then
                    local npcHrp = duckNPC:FindFirstChild("HumanoidRootPart")
                        or duckNPC:FindFirstChildWhichIsA("BasePart")
                    if npcHrp then
                        hrp.CFrame = npcHrp.CFrame * CFrame.new(0, 5, 0)
                        task.wait(0.3)
                        local p = npcHrp:FindFirstChildOfClass("ProximityPrompt")
                        if p then
                            pcall(function() fireproximityprompt(p) end)
                            lastSummonTime = now
                        end
                    end
                end
                return
            end
            _G.Auto_DuckAutomatically = false
            _G.SeaNotify("❌ Missing Duck Items", table.concat(missing, ", "), 6)
        end, function(err) warn("[FarmDuck]", err) end)
    end
end)
