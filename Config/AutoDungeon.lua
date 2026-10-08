--[[
    Features/AutoDungeon.lua
    Auto Dungeon Full
]]

local Globals = _G.__Globals or Globals
local Utils   = Globals.Utils
local Combat  = Globals.Combat
local Inventory = Globals.Inventory
local RS      = Globals.ReplicatedStorage
local LP      = Globals.LocalPlayer
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- ===== Quest helpers (dùng chung) =====
local Quest_List = {}
table.sort(Globals.Quest_Module, function(a, b) return a.Level < b.Level end)
for i, data in ipairs(Globals.Quest_Module) do
    local npc = Globals.Npc_Quest:WaitForChild("NPC_Quest" .. i)
    Quest_List[i] = {Level = data.Level, Monster = npc:GetAttribute("Name"), Quest = npc}
end
local function GetQuest_Level(myLevel)
    local quest
    for _, v in ipairs(Quest_List) do
        if myLevel >= v.Level then quest = v else break end
    end
    return quest
end
local function GetQuestFrame()
    return LP.PlayerGui.HUD.Main.Frame_Quest
end

task.spawn(function()
    while task.wait() do
        xpcall(function()
            if not _G.Auto_Dungeon then return end

            local char = LP.Character
            if not char then return end
            local hum = char:FindFirstChild("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end

            -- Check HP
            local hpPct = (hum.Health / hum.MaxHealth) * 100
            if hpPct < _G.HealthPercent then
                hrp.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y + 200, hrp.Position.Z)
                task.wait(0.5)
                return
            end

            local dungeonId = char:GetAttribute("Dungeon")
            local dungeon
            if dungeonId then
                dungeon = workspace.DungeonMap:FindFirstChild("Dungeon_" .. dungeonId)
            end

            -- Auto skip wave
            if LP.PlayerGui:FindFirstChild("WaveUI")
                and LP.PlayerGui.WaveUI.AutoSkip.BackgroundColor3 == Color3.fromRGB(255, 69, 69) then
                GuiService.SelectedObject = LP.PlayerGui.WaveUI.AutoSkip
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                task.wait(0.1)
                GuiService.SelectedObject = nil
            end

            if dungeon then
                local target, minDist = nil, math.huge
                for _, mob in ipairs(workspace.Mob:GetChildren()) do
                    if mob:IsA("Model") and mob:FindFirstChild("Humanoid")
                        and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
                        local d = (mob.HumanoidRootPart.Position - dungeon:GetPivot().Position).Magnitude
                        if d <= 250 and d < minDist then
                            minDist = d
                            target = mob
                        end
                    end
                end

                if target then
                    local tHrp = target.HumanoidRootPart
                    target.Humanoid.WalkSpeed = 0
                    target.Humanoid.JumpPower = 0

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

                    Combat.DoAttack()
                else
                    if hrp:FindFirstChild("DungeonBP") then
                        hrp.DungeonBP:Destroy()
                    end
                end
            else
                local zone = workspace:FindFirstChild("TeleportDungeonZone")
                if zone and zone:FindFirstChild("Hitbox") then
                    hrp.CFrame = zone.Hitbox.CFrame
                else
                    if Inventory.GetAmount("Orb Dungeon") >= _G.Dungeon_UseValue then
                        local npc = workspace.NpcPrompt["Open Dungeon"].HumanoidRootPart
                        hrp.CFrame = npc.CFrame * CFrame.new(0, 5, 0)
                        RS.Modules.NetworkFramework.NetworkEvent
                            :FireServer("fire", nil, "SpawnDungeon", _G.Dungeon_UseValue)
                    else
                        local diamond = LP:GetAttribute("Diamond") or 0
                        if diamond >= 150 then
                            RS.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "RandomItem", "x15")
                        else
                            -- fallback: đi làm quest
                            local quest = GetQuest_Level(tonumber(LP:GetAttribute("Level")))
                            if not quest then return end
                            local frame = GetQuestFrame()
                            local text = frame.Title.Text or ""
                            if LP.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
                                RS.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                            end
                            if frame.Visible and not string.find(text, quest.Monster) then
                                RS.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                                repeat task.wait() until not frame.Visible
                            end
                            if not frame.Visible then
                                local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
                                if npc then
                                    hrp.CFrame = npc.CFrame * Utils.MethodFarm
                                    task.wait(0.3)
                                    local pro = npc:FindFirstChildOfClass("ProximityPrompt")
                                    if pro then fireproximityprompt(pro) end
                                end
                            else
                                for _, v in ipairs(workspace.Mob:GetChildren()) do
                                    if v:IsA("Model") and v.Name == quest.Monster
                                        and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                                        v.Humanoid.WalkSpeed = 0
                                        v.Humanoid.JumpPower = 0
                                        hrp.CFrame = v.HumanoidRootPart.CFrame * Utils.MethodFarm
                                        Combat.DoAttack()
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end, print)
    end
end)
