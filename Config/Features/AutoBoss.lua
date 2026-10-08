--[[
    Features/AutoBoss.lua
    Auto Boss, Thief, Piccolo, Duck, DevilBoat
]]

local Globals = _G.__Globals
assert(Globals, "[Module] _G.__Globals chưa được set! Load Main.lua trước.")
local Utils   = Globals.Utils
local Combat  = Globals.Combat
local RS      = Globals.ReplicatedStorage
local LP      = Globals.LocalPlayer

local function FarmTarget(predicate, flagName)
    for _, v in ipairs(workspace.Mob:GetChildren()) do
        if predicate(v) then
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hrp then
                v.Humanoid.WalkSpeed = 0
                v.Humanoid.JumpPower = 0
                repeat task.wait()
                    Combat.DoAttack()
                    Utils.Teleport(hrp.CFrame * Utils.MethodFarm)
                until not _G[flagName] or not v.Parent or v.Humanoid.Health <= 0
            end
        end
    end
end

-- ===== All Boss =====
task.spawn(function()
    while task.wait() do
        if _G.Auto_FarmBoss then
            pcall(function()
                for _, v in ipairs(workspace.Boss:GetChildren()) do
                    if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        local hrp = v:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0
                            repeat task.wait()
                                Combat.DoAttack()
                                Utils.Teleport(hrp.CFrame * Utils.MethodFarm)
                            until not _G.Auto_FarmBoss or not v.Parent or v.Humanoid.Health <= 0
                        end
                    end
                end
            end)
        end
    end
end)

-- ===== Piccolo =====
task.spawn(function()
    while task.wait() do
        if _G.Auto_Piccolo then
            pcall(function()
                FarmTarget(function(v)
                    return v:IsA("Model") and v.Name == "Piccolo"
                        and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0
                end, "Auto_Piccolo")
            end)
        end
    end
end)

-- ===== Duck =====
task.spawn(function()
    while task.wait() do
        if _G.Auto_Duck then
            pcall(function()
                if workspace.Mob:FindFirstChild("Duck Monster") then
                    FarmTarget(function(v)
                        return v:IsA("Model") and v.Name == "Duck Monster"
                            and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0
                    end, "Auto_Duck")
                else
                    local spawn = workspace.Itemdrops:FindFirstChild("Duck Monster")
                    if spawn then Utils.Teleport(spawn.CFrame) end
                end
            end)
        end
    end
end)

-- ===== Devil Boat =====
task.spawn(function()
    while task.wait() do
        if _G.Auto_DevilBoat then
            pcall(function()
                local target
                for _, v in ipairs(workspace.Mob:GetChildren()) do
                    if v:IsA("Model")
                        and (v.Name == "Devil Boat" or v.Name == "DevilBoat")
                        and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        target = v
                        break
                    end
                end
                if target then
                    target.Humanoid.WalkSpeed = 0
                    target.Humanoid.JumpPower = 0
                    local hrp = target.HumanoidRootPart
                    repeat task.wait()
                        Combat.DoAttack()
                        Utils.Teleport(hrp.CFrame * Utils.MethodFarm)
                    until not _G.Auto_DevilBoat or not target.Parent or target.Humanoid.Health <= 0
                end
            end)
        end
    end
end)

-- ===== Bacon Thief =====
local CurrentSpawn = 1
task.spawn(function()
    while task.wait() do
        pcall(function()
            if not _G.Auto_BaconThief then return end
            local spawns = workspace.MobSpawnGroup:GetChildren()
            local spawn = spawns[CurrentSpawn]
            if not spawn then
                CurrentSpawn = 1
                return
            end
            local chestRef = spawn:FindFirstChild("ChestRef", true)
            if chestRef then
                local target, dist = nil, 30
                for _, mob in ipairs(workspace.Mob:GetChildren()) do
                    if mob:IsA("Model") and mob.Name == "Bacon Thief"
                        and mob:FindFirstChild("HumanoidRootPart")
                        and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                        local mag = (mob.HumanoidRootPart.Position - chestRef.Position).Magnitude
                        if mag < dist then
                            dist = mag
                            target = mob
                        end
                    end
                end
                if target then
                    target.Humanoid.WalkSpeed = 0
                    target.Humanoid.JumpPower = 0
                    Combat.DoAttack()
                    Utils.Teleport(target.HumanoidRootPart.CFrame * Utils.MethodFarm)
                else
                    local prompt = chestRef:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.Parent and prompt.ActionText == "Open" then
                        Utils.Teleport(chestRef.CFrame * CFrame.new(0, 3, 0))
                        fireproximityprompt(prompt)
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
