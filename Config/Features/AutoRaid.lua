--[[
    Features/AutoRaid.lua
    Auto Raid Moon + Auto Raid Boss (Bacon of Grudge)
]]

local Globals = _G.__Globals
assert(Globals, "[Module] _G.__Globals chưa được set! Load Main.lua trước.")
local Utils   = Globals.Utils
local Combat  = Globals.Combat
local Inventory = Globals.Inventory
local RS      = Globals.ReplicatedStorage
local LP      = Globals.LocalPlayer

-- ===== Raid Boss Data =====
_G.RaidBossData = {
    ["Bacon of Grudge"] = {
        Name = "Bacon of Grudge",
        Reward = "Time Mystery Box x5, 7500 Diamond, Beli 50M, x3 Potion, Roll Class + Raid Potion x1",
        PortalCost = 1,
        Valid = true
    },
    ["??? (Raid 2)"] = {
        Name = "???", Reward = "SOON!!", PortalCost = 0, Valid = false
    },
    ["??? (Raid 3)"] = {
        Name = "???", Reward = "SOON!!", PortalCost = 0, Valid = false
    }
}

_G.RaidWaitingClear = false
_G.RaidDying = false

-- ===== AUTO RAID MOON =====
task.spawn(function()
    while task.wait() do
        pcall(function()
            if not _G.Auto_Raid then return end
            if game.PlaceId == 82878101790702 then
                for _, v in ipairs(workspace.Mob:GetChildren()) do
                    if v:IsA("Model") and v:FindFirstChild("Humanoid")
                        and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                        v.Humanoid.WalkSpeed = 0
                        v.Humanoid.JumpPower = 0
                        repeat task.wait()
                            Combat.DoAttack()
                            Utils.Teleport(v.HumanoidRootPart.CFrame * Utils.MethodFarm)
                        until not _G.Auto_Raid or not v.Parent or v.Humanoid.Health <= 0
                    end
                end
                return
            end

            local zone = workspace:FindFirstChild("TeleportMoonZone")
            if zone then
                Utils.Teleport(zone.Hitbox:GetPivot() * CFrame.new(0, -8, 0))
                return
            end

            if Inventory.GetAmount("Space Ticket") >= 1 then
                local npc = workspace.NpcPrompt.GoMoon.HumanoidRootPart
                Utils.Teleport(npc.CFrame * CFrame.new(0, 5, 0))
                fireproximityprompt(npc:FindFirstChildOfClass("ProximityPrompt"))
                return
            end

            local diamond = LP:GetAttribute("Diamond") or 0
            if diamond >= 150 then
                RS.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "RandomItem", "x15")
            end
        end)
    end
end)

-- ===== AUTO RAID BOSS =====
task.spawn(function()
    print("[AutoRaid] ✅ task.spawn v17 đã khởi động!")
    while task.wait(0.3) do
        if _G.AutoRaidRunning then
            local data = _G.RaidBossData and _G.RaidBossData[_G.AutoRaidWho]
            if data and data.Valid then
                pcall(function()
                    local char = LP.Character
                    local hum = char and char:FindFirstChild("Humanoid")
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hum or not hrp then return end

                    if hum.Health <= 0 then
                        if not _G.RaidDying then
                            _G.RaidDying = true
                            _G.RaidWaitingClear = true
                            print("[AutoRaid] Nhân vật chết → đợi boss biến mất...")
                            for _, n in ipairs({"AutoRaidBP", "AutoRaidAP", "AutoRaidAO", "AutoRaidAtt"}) do
                                if hrp:FindFirstChild(n) then hrp[n]:Destroy() end
                            end
                        end
                        return
                    else
                        _G.RaidDying = false
                    end

                    local bf = workspace:FindFirstChild("Boss Fight")
                    local bacon = bf and bf:FindFirstChild("Bacon of Grudge")

                    if _G.RaidWaitingClear then
                        if bacon then
                            task.wait(1)
                            return
                        else
                            _G.RaidWaitingClear = false
                            task.wait(1)
                        end
                    end

                    if bacon then
                        local function TeleportTo(targetPart, offsetY, offsetX)
                            if not hrp or not hrp.Parent or not targetPart then return end
                            local targetPos = targetPart.Position + Vector3.new(offsetX or 0, offsetY or 25, 0)
                            hrp.CFrame = CFrame.new(targetPos, targetPart.Position)
                            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                        end

                        local function AttackTarget(targetPart, targetModel, offsetY, offsetX)
                            if not targetPart or not targetModel then return end
                            if not targetModel:FindFirstChild("Humanoid") then return end
                            if targetModel.Humanoid.Health <= 0 then return end
                            targetModel.Humanoid.WalkSpeed = 0
                            targetModel.Humanoid.JumpPower = 0
                            repeat task.wait(0.03)
                                if not _G.AutoRaidRunning then break end
                                if not targetModel.Parent then break end
                                if targetModel.Humanoid.Health <= 0 then break end
                                if hum.Health <= 0 then break end
                                if not targetPart.Parent then break end
                                TeleportTo(targetPart, offsetY, offsetX)
                                Combat.DoAttack()
                            until false
                        end

                        local a1 = bacon:FindFirstChild("ArmorBall1")
                        if a1 and a1:FindFirstChild("Humanoid") and a1.Humanoid.Health > 0 then
                            AttackTarget(a1:FindFirstChild("HumanoidRootPart"), a1, _G.RaidBallOffsetY or 25, 0)
                        end

                        local a2 = bacon:FindFirstChild("ArmorBall2")
                        if _G.AutoRaidRunning and a2 and a2:FindFirstChild("Humanoid") and a2.Humanoid.Health > 0 then
                            AttackTarget(a2:FindFirstChild("HumanoidRootPart"), a2, _G.RaidBallOffsetY or 25, 0)
                        end

                        local boss = bacon:FindFirstChild("Boss Bacon Sad")
                        if _G.AutoRaidRunning and boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
                            local bHrp = boss:FindFirstChild("HumanoidRootPart")
                            if bHrp then
                                AttackTarget(bHrp, boss, _G.RaidBossOffsetY or 55, 5)
                            end
                        end

                        if _G.AutoRaidRunning then task.wait(2) end
                    else
                        -- Chưa vào map → vào portal
                        local tpZone = workspace:FindFirstChild("TeleportBossFightZone")
                        if tpZone and tpZone:FindFirstChild("Hitbox") then
                            local hitbox = tpZone.Hitbox
                            hrp.Anchored = true
                            repeat task.wait(0.1)
                                if not _G.AutoRaidRunning then break end
                                if hrp.Parent then
                                    hrp.CFrame = hitbox.CFrame
                                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                end
                                if not tpZone.Parent then break end
                                if workspace:FindFirstChild("Boss Fight") then break end
                            until false
                            hrp.Anchored = false
                            task.wait(workspace:FindFirstChild("Boss Fight") and 3 or 1)
                        else
                            if Inventory.GetAmount("Portal Gun") < data.PortalCost then
                                Utils.Notify("❌ Không đủ Portal Gun",
                                    "Cần " .. data.PortalCost .. " Portal Gun!", 4)
                                _G.AutoRaidRunning = false
                                return
                            end
                            RS.Modules.NetworkFramework.NetworkEvent
                                :FireServer("fire", nil, "SpawnBossFight", data.Name)
                            task.wait(2)
                        end
                    end
                end)
            end
        end
    end
end)

-- ===== Cleanup khi tắt =====
task.spawn(function()
    while task.wait(0.5) do
        if not _G.AutoRaidRunning then
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, n in ipairs({"AutoRaidBP", "AutoRaidAP", "AutoRaidAO", "AutoRaidAtt"}) do
                    if hrp:FindFirstChild(n) then hrp[n]:Destroy() end
                end
                if hrp.Anchored and not workspace:FindFirstChild("Boss Fight") then
                    hrp.Anchored = false
                end
            end
        end
    end
end)

-- ===== Freeze horizontal velocity =====
task.spawn(function()
    while _G.AutoRaidRunning do
        pcall(function()
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local v = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
            end
        end)
        task.wait()
    end
end)
