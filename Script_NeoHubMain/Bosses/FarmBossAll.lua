-- Bosses/FarmBossAll.lua
local Services = require(script.Parent.Parent.Core.Services)
local Helpers  = require(script.Parent.Parent.Core.Helpers)

local LocalPlayer = Services.LocalPlayer
local Teleport = Helpers.Teleport

local MethodFarm = CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-90), 0, 0)

task.spawn(function()
    local lastTargetKey = nil
    local BossNames = {"Piccolo", "Kraken", "Devil Boat", "DevilBoat", "Bacon Thief"}
    local waitingChest = false

    while task.wait() do
        xpcall(function()
            MethodFarm = CFrame.new(0, _G.Distance_Farm or 5, 0)
                * CFrame.Angles(math.rad(-90), 0, 0)
            if not _G.AutoBossAll then
                _G.CanAutoSkill = false
                lastTargetKey = nil
                return
            end
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChild("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then
                _G.CanAutoSkill = false
                return
            end
            local mobFolder = workspace:FindFirstChild("Mob") or workspace:FindFirstChild("Mobs")
            if not mobFolder then return end

            local Target, TargetName
            for _, bossName in ipairs(BossNames) do
                for _, mob in ipairs(mobFolder:GetChildren()) do
                    if mob:IsA("Model") and mob.Name == bossName
                       and mob:FindFirstChild("Humanoid")
                       and mob:FindFirstChild("HumanoidRootPart")
                       and mob.Humanoid.Health > 0 then
                        Target = mob; TargetName = bossName; break
                    end
                end
                if Target then break end
            end

            if not Target then
                _G.CanAutoSkill = false
                lastTargetKey = nil
                return
            end

            local tHrp = Target:FindFirstChild("HumanoidRootPart")
            if not tHrp then return end
            local key = TargetName .. "|" .. tostring(Target)
            if key ~= lastTargetKey then lastTargetKey = key end

            Target.Humanoid.WalkSpeed = 0
            Target.Humanoid.JumpPower = 0
            _G.CanAutoSkill = true
            _G.EquipWeapon(); _G.AutoSkill(); _G.Attack()
            Teleport(tHrp.CFrame * MethodFarm)

            -- Thief chest
            if TargetName == "Bacon Thief" and Target.Humanoid.Health <= 0 then
                task.spawn(function()
                    local startTime = tick()
                    local chestOpened = false
                    local thiefDeathPos = tHrp.Position
                    while tick() - startTime < 15 and not chestOpened do
                        task.wait(0.5)
                        local c2 = LocalPlayer.Character
                        local hrp2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                        if not hrp2 then break end
                        local msf = workspace:FindFirstChild("MobSpawnGroup")
                        if not msf then continue end
                        local chests = {}
                        for _, spawn in ipairs(msf:GetChildren()) do
                            local ref = spawn:FindFirstChild("ChestRef", true)
                            if ref then
                                local p = ref:FindFirstChildWhichIsA("ProximityPrompt", true)
                                if p and p.Enabled and (p.ActionText == "Open" or p.ActionText == "") then
                                    local d = (hrp2.Position - ref.Position).Magnitude
                                    table.insert(chests, {chest = ref, prompt = p, dist = d, pos = ref.Position})
                                end
                            end
                        end
                        if #chests > 0 then
                            table.sort(chests, function(a, b)
                                return (a.pos - thiefDeathPos).Magnitude < (b.pos - thiefDeathPos).Magnitude
                            end)
                            local t = chests[1]
                            for attempt = 1, 3 do
                                hrp2.CFrame = CFrame.new(t.pos + Vector3.new(0, 3, 0))
                                hrp2.AssemblyLinearVelocity = Vector3.zero
                                hrp2.AssemblyAngularVelocity = Vector3.zero
                                task.wait(0.3)
                                pcall(function() fireproximityprompt(t.prompt) end)
                                task.wait(0.5)
                                if not t.chest.Parent or not t.prompt.Parent or not t.prompt.Enabled then
                                    chestOpened = true
                                    break
                                end
                            end
                        end
                    end
                end)
            end
        end, function(err) warn("[FarmBossAll]", err) end)
    end
end)
