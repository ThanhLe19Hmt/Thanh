-- Dungeon/AutoDungeon.lua
local Services = require(script.Parent.Parent.Core.Services)
local Helpers  = require(script.Parent.Parent.Core.Helpers)

local LocalPlayer = Services.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage
local GuiService = Services.GuiService
local VirtualInputManager = Services.VirtualInputManager
local Teleport = Helpers.Teleport
local GetItemAmount = Helpers.GetItemAmount
local MethodFarm = CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-90), 0, 0)

task.spawn(function()
    while task.wait() do
        xpcall(function()
            MethodFarm = CFrame.new(0, _G.Distance_Farm or 5, 0)
                * CFrame.Angles(math.rad(-90), 0, 0)
            if not _G.Auto_Dungeon then return end
            local Character = LocalPlayer.Character
            if not Character then return end
            local hum = Character:FindFirstChild("Humanoid")
            local hrp = Character:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end
            local hpPct = (hum.Health / hum.MaxHealth) * 100
            if hpPct < (_G.HealthPercent or 30) then
                hrp.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y + 200, hrp.Position.Z)
                task.wait(0.5)
                return
            end

            local waveUI = LocalPlayer.PlayerGui:FindFirstChild("WaveUI")
            if waveUI then
                local autoSkip = waveUI:FindFirstChild("AutoSkip")
                if autoSkip and autoSkip.BackgroundColor3 == Color3.fromRGB(255, 69, 69) then
                    GuiService.SelectedObject = autoSkip
                    task.wait(0.1)
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                    task.wait(0.1)
                    GuiService.SelectedObject = nil
                end
            end

            local DungeonId = Character:GetAttribute("Dungeon")
            local Dungeon
            if DungeonId and workspace:FindFirstChild("DungeonMap") then
                Dungeon = workspace.DungeonMap:FindFirstChild("Dungeon_" .. DungeonId)
            end

            if Dungeon then
                local Target, minDist = nil, math.huge
                local mobFolder = workspace:FindFirstChild("Mob")
                if mobFolder then
                    for _, Mob in ipairs(mobFolder:GetChildren()) do
                        if Mob:IsA("Model") and Mob:FindFirstChild("Humanoid")
                           and Mob:FindFirstChild("HumanoidRootPart")
                           and Mob.Humanoid.Health > 0 then
                            local d = (Mob.HumanoidRootPart.Position - Dungeon:GetPivot().Position).Magnitude
                            if d <= 250 and d < minDist then
                                minDist = d; Target = Mob
                            end
                        end
                    end
                end
                if Target then
                    _G.CanAutoSkill = true
                    local tHrp = Target.HumanoidRootPart
                    Target.Humanoid.WalkSpeed = 0
                    Target.Humanoid.JumpPower = 0
                    local bp = hrp:FindFirstChild("DungeonBP")
                    if not bp then
                        bp = Instance.new("BodyPosition")
                        bp.Name = "DungeonBP"
                        bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bp.P = 100000
                        bp.D = 3000
                        bp.Parent = hrp
                    end
                    local targetPos = tHrp.Position + Vector3.new(0, _G.DungeonHeight or 25, 0)
                    bp.Position = targetPos
                    hrp.CFrame = CFrame.new(targetPos, tHrp.Position)
                    _G.EquipWeapon(); _G.AutoSkill(); _G.Attack()
                else
                    _G.CanAutoSkill = false
                    if hrp:FindFirstChild("DungeonBP") then
                        hrp.DungeonBP:Destroy()
                    end
                end
            else
                _G.CanAutoSkill = false
                local tz = workspace:FindFirstChild("TeleportDungeonZone")
                if tz and tz:FindFirstChild("Hitbox") then
                    hrp.CFrame = tz.Hitbox.CFrame
                else
                    if GetItemAmount("Orb Dungeon") >= (_G.Dungeon_UseValue or 1) then
                        local npcPrompt = workspace:FindFirstChild("NpcPrompt")
                        local npc = npcPrompt and npcPrompt:FindFirstChild("Open Dungeon")
                        local npcHrp = npc and npc:FindFirstChild("HumanoidRootPart")
                        if npcHrp then
                            hrp.CFrame = npcHrp.CFrame * CFrame.new(0, 5, 0)
                        end
                        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                            "fire", nil, "SpawnDungeon", _G.Dungeon_UseValue or 1)
                    else
                        local diamond = LocalPlayer:GetAttribute("Diamond") or 0
                        if diamond >= 150 then
                            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                                "fire", nil, "RandomItem", "x15")
                        end
                    end
                end
            end
        end, print)
    end
end)

-- Auto close reward
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            if not hud or not hud:FindFirstChild("Main") then return end
            local closeList = {
                {_G.Auto_Dungeon,    "Frame_DungeonItem"},
                {_G.AutoRaidRunning, "Frame_RaidbossItem"},
            }
            for _, entry in ipairs(closeList) do
                if entry[1] then
                    local fd = hud.Main:FindFirstChild(entry[2])
                    if fd and fd.Visible then
                        task.wait(2)
                        local btn = fd:FindFirstChild("Close_")
                            or fd:FindFirstChild("Close")
                            or fd:FindFirstChild("CloseButton")
                            or fd:FindFirstChild("Exit")
                        if btn then
                            pcall(function()
                                if firesignal then firesignal(btn.MouseButton1Click)
                                else btn:Activate() end
                            end)
                        else
                            fd.Visible = false
                        end
                    end
                end
            end
        end)
    end
end)
