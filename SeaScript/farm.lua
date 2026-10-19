-- ============================================================
-- FARM MODULE - v1
-- Chứa: Auto Level Farm + Auto Farm Material
-- Usage: loadstring(...)(ctx)
-- ============================================================
return function(ctx)
    -- ===== DEPENDENCIES TỪ MAIN =====
    local Window            = ctx.Window
    local LocalPlayer       = ctx.LocalPlayer
    local ReplicatedStorage = ctx.ReplicatedStorage
    local HttpService       = ctx.HttpService

    -- Hàm & biến dùng chung từ main
    local GetInventory      = ctx.GetInventory
    local GetItemAmount     = ctx.GetItemAmount
    local GetQuest_Level    = ctx.GetQuest_Level
    local GetQuestFrame     = ctx.GetQuestFrame
    local EquipWeapon       = ctx.EquipWeapon
    local AutoSkill         = ctx.AutoSkill
    local Attack            = ctx.Attack
    local Teleport          = ctx.Teleport
    local MethodFarm        = ctx.MethodFarm     -- ⚠️ là CFrame, cần getter
    local GetMethodFarm     = ctx.GetMethodFarm  -- 🆕 hàm trả về MethodFarm hiện tại

    -- Dữ liệu
    local ItemDrop          = ctx.ItemDrop or {}
    local ItemAll           = ctx.ItemAll or {}
    local Quest_List        = ctx.Quest_List or {}

    -- _G shared
    local _G = ctx._G or _G

    -- ===== TẠO UI =====
    local Tab2         = Window:CreateTab("Main", false, false)
    local Farm         = Tab2:CreatePage("Farm")
    local AutoFarmCard = Farm:CreateSection("🌾 Auto Farm", "Left")
    local MaterialCard = Farm:CreateSection("⛏️ Auto Farm Material", "Right")

    -- ===== UI: AUTO LEVEL FARM =====
    AutoFarmCard:Toggle({
        Title = "Auto Level Farm",
        Value = false,
        Callback = function(v)
            _G.Auto_Farm_Level = v
            if v then
                pcall(function()
                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
                        :FireServer("fire", nil, "Quest", "Cancel")
                end)
            end
        end
    })

    -- ===== UI: AUTO FARM MATERIAL =====
    MaterialCard:Dropdown({
        Title = "Select Farm Material",
        Options = ItemAll,
        Multi = true,
        Callback = function(v)
            local list = {}
            if type(v) == "table" then
                for _, item in pairs(v) do
                    if type(item) == "string" then
                        table.insert(list, item)
                    end
                end
            elseif type(v) == "string" then
                table.insert(list, v)
            end
            _G.Select_Material = list
        end
    })

    MaterialCard:Toggle({
        Title = "Auto Farm Material",
        Value = false,
        Callback = function(v) _G.Auto_Farm_Material = v end
    })

    -- ============================================================
    -- LOOP 1: AUTO FARM LEVEL
    -- ============================================================
    task.spawn(function()
        while task.wait() do
            xpcall(function()
                if not _G.Auto_Farm_Level then return end

                local quest = GetQuest_Level(tonumber(LocalPlayer:GetAttribute("Level")))
                if not quest then return end

                local Frame = GetQuestFrame()
                local Text  = Frame.Title.Text or ""

                if LocalPlayer.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
                        :FireServer("fire", nil, "Quest", "Cancel")
                end

                if Frame.Visible and not string.find(Text, quest.Monster) then
                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
                        :FireServer("fire", nil, "Quest", "Cancel")
                    repeat task.wait() until not Frame.Visible
                end

                if not Frame.Visible then
                    _G.CanAutoSkill = false

                    local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
                    if npc then
                        local char = LocalPlayer.Character
                        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.CFrame = CFrame.new(npc.Position + Vector3.new(0, 3, 0))
                            hrp.AssemblyLinearVelocity  = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end

                        task.wait(0.4)

                        local prompt = npc:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            pcall(function()
                                fireproximityprompt(prompt, prompt.HoldDuration + 0.1)
                            end)
                            task.wait(0.2)
                            pcall(function()
                                fireproximityprompt(prompt, prompt.HoldDuration + 0.1)
                            end)
                        end
                    end
                else
                    for _, v in pairs(workspace.Mob:GetChildren()) do
                        if v:IsA("Model")
                           and v.Name == quest.Monster
                           and v:FindFirstChild("Humanoid")
                           and v.Humanoid.Health > 0 then
                            local hrp = v:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                v.Humanoid.WalkSpeed = 0
                                v.Humanoid.JumpPower = 0

                                _G.CanAutoSkill = true

                                repeat task.wait()
                                    EquipWeapon()
                                    AutoSkill()
                                    Attack()
                                    Teleport(hrp.CFrame * GetMethodFarm())
                                until not _G.Auto_Farm_Level or v.Humanoid.Health <= 0

                                _G.CanAutoSkill = false
                            end
                            break
                        end
                    end
                end
            end, print)
        end
    end)

    -- ============================================================
    -- LOOP 2: AUTO FARM MATERIAL
    -- ============================================================
    task.spawn(function()
        local lastMaterialLog   = 0
        local lastTargetLog     = 0
        local lastSpawnTPTime   = 0
        local SPAWN_TP_COOLDOWN = 2
        local lastSpawnTPName   = nil

        while task.wait() do
            xpcall(function()
                if not _G.Auto_Farm_Material then
                    _G.CanAutoSkill = false
                    return
                end

                if type(_G.Select_Material) ~= "table" or #_G.Select_Material == 0 then
                    if tick() - lastMaterialLog > 5 then
                        lastMaterialLog = tick()
                    end
                    return
                end

                local char = LocalPlayer.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                local hum  = char and char:FindFirstChild("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then return end

                local mobFolder = workspace:FindFirstChild("Mob") or workspace:FindFirstChild("Mobs")
                if not mobFolder then
                    if tick() - lastTargetLog > 5 then
                        lastTargetLog = tick()
                    end
                    return
                end

                local Target, TargetName, minDist = nil, nil, math.huge

                for _, Material in ipairs(_G.Select_Material) do
                    local MobNames = ItemDrop[Material]
                    if MobNames then
                        for _, MobName in ipairs(MobNames) do
                            for _, Mob in ipairs(mobFolder:GetChildren()) do
                                if Mob:IsA("Model")
                                   and Mob.Name == MobName
                                   and Mob:FindFirstChild("Humanoid")
                                   and Mob:FindFirstChild("HumanoidRootPart")
                                   and Mob.Humanoid.Health > 0 then
                                    local dist = (hrp.Position - Mob.HumanoidRootPart.Position).Magnitude
                                    if dist < minDist then
                                        minDist    = dist
                                        Target     = Mob
                                        TargetName = MobName
                                    end
                                end
                            end
                        end
                    end
                end

                if not Target then
                    _G.CanAutoSkill = false

                    if tick() - lastSpawnTPTime >= SPAWN_TP_COOLDOWN then
                        local firstMaterial = _G.Select_Material[1]
                        local MobNames = ItemDrop[firstMaterial]

                        if MobNames and #MobNames > 0 then
                            local spawnName = MobNames[1]
                            local itemdrops = workspace:FindFirstChild("Itemdrops")
                            local spawnPart = itemdrops and itemdrops:FindFirstChild(spawnName)

                            if spawnPart then
                                local spawnPos = spawnPart:GetPivot().Position
                                hrp.CFrame = CFrame.new(spawnPos + Vector3.new(0, 10, 0))
                                hrp.AssemblyLinearVelocity  = Vector3.zero
                                hrp.AssemblyAngularVelocity = Vector3.zero
                                lastSpawnTPTime = tick()
                                lastSpawnTPName = spawnName
                                task.wait(0.5)
                            end
                        end
                    end

                    if tick() - lastTargetLog > 5 then
                        lastTargetLog = tick()
                    end

                    hrp.AssemblyLinearVelocity  = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    return
                end

                local tHrp = Target.HumanoidRootPart
                if not tHrp then return end

                lastSpawnTPName = nil

                Target.Humanoid.WalkSpeed = 0
                Target.Humanoid.JumpPower = 0

                _G.CanAutoSkill = true

                EquipWeapon()
                AutoSkill()
                Attack()
                Teleport(tHrp.CFrame * GetMethodFarm())
            end, function(err)
                warn("[AutoFarmMaterial] Error:", err)
            end)
        end
    end)

    print("[Farm] ✅ Module loaded")
end
