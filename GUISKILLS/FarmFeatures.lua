--[[
    FarmFeatures Module: Tất cả tính năng farm
]]

local Core = loadstring(game:HttpGet("URL_CORE"))()
local Combat = loadstring(game:HttpGet("URL_COMBAT"))()

local ReplicatedStorage = Core.Services.ReplicatedStorage
local LocalPlayer = Core.Services.LocalPlayer
local HttpService = Core.Services.HttpService

local Farm = {}

-- Helper: tìm mob theo tên
function Farm.FindMob(name, parent)
    parent = parent or workspace:FindFirstChild("Mob")
    if not parent then return nil end
    for _, v in ipairs(parent:GetChildren()) do
        if v:IsA("Model") and v.Name == name then
            local hum = v:FindFirstChildOfClass("Humanoid")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                return v
            end
        end
    end
    return nil
end

-- ============================================================
-- GENERIC FARM LOOP (dùng cho mọi feature)
-- ============================================================
--[[
    Farm.Run(name, getTargetFn, isEnabledFn)
    - name: tên task
    - getTargetFn: function trả về { model, hrp } hoặc nil
    - isEnabledFn: function trả về true/false (đọc _G flag)
]]
function Farm.RegisterSimple(name, getTargetFn, isEnabledFn, extraFn)
    Core.TaskManager:Register(name, function()
        if not isEnabledFn() then task.wait(0.3) return end
        local target = getTargetFn()
        if target and target.model then
            Combat.FarmTarget(target.model, function() return not isEnabledFn() end)
            if extraFn then extraFn() end
        else
            task.wait(0.3)
        end
    end)
    Core.TaskManager:Start(name)
end

-- ============================================================
-- AUTO FARM LEVEL
-- ============================================================
Core.TaskManager:Register("AutoFarmLevel", function()
    if not _G.Auto_Farm_Level then task.wait(0.3) return end

    local level = tonumber(Core.GetAttribute("Level", 1))
    local QuestList = _G.QuestList or {}
    if #QuestList == 0 then task.wait(1) return end

    -- Tìm quest phù hợp
    local quest
    for _, q in ipairs(QuestList) do
        if level >= q.Level then quest = q else break end
    end
    if not quest then task.wait(0.5) return end

    local Frame = LocalPlayer.PlayerGui.HUD.Main.Frame_Quest
    local TitleText = Frame.Title.Text or ""

    if Frame.Title.Text ~= quest.Monster then
        Core.FireNetwork("Quest", "Cancel")
    end
    if Frame.Visible and not string.find(TitleText, quest.Monster) then
        Core.FireNetwork("Quest", "Cancel")
        repeat task.wait() until not Frame.Visible
    end

    if not Frame.Visible then
        local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
        if npc then
            Core.Teleport(npc.CFrame * Combat.GetMethodFarm())
            task.wait(0.3)
            local prompt = npc:FindFirstChildOfClass("ProximityPrompt")
            Core.FireProximityPrompt(prompt)
        end
    else
        local mob = Farm.FindMob(quest.Monster)
        if mob then
            Combat.FarmTarget(mob, function() return not _G.Auto_Farm_Level end)
        end
    end
end)
Core.TaskManager:Start("AutoFarmLevel")

-- ============================================================
-- AUTO FARM BOSS (đăng ký tương tự)
-- ============================================================
Farm.RegisterSimple("AutoFarmBoss",
    function()
        local boss = workspace:FindFirstChild("Boss")
        if not boss then return nil end
        local bosses = _G.BossList or {}
        for _, v in ipairs(boss:GetChildren()) do
            if table.find(bosses, v.Name) then
                local hum = v:FindFirstChildOfClass("Humanoid")
                local hrp = v:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    return { model = v, hrp = hrp }
                end
            end
        end
        return nil
    end,
    function() return _G.Auto_FarmBoss end
)

-- ============================================================
-- AUTO FARM MATERIAL
-- ============================================================
Core.TaskManager:Register("AutoFarmMaterial", function()
    if not _G.Auto_Farm_Material then task.wait(0.3) return end
    if type(_G.Select_Material) ~= "table" then task.wait(0.5) return end

    local ItemDrop = _G.ItemDrop or {}
    for material in pairs(_G.Select_Material) do
        local mobNames = ItemDrop[material]
        if mobNames then
            for _, mobName in ipairs(mobNames) do
                local mob = Farm.FindMob(mobName)
                if mob then
                    Combat.FarmTarget(mob, function() return not _G.Auto_Farm_Material end)
                    break
                else
                    local spawn = workspace.Itemdrops:FindFirstChild(mobName)
                    if spawn then
                        Core.Teleport(spawn:GetPivot())
                        task.wait(1)
                    end
                end
            end
        end
    end
end)
Core.TaskManager:Start("AutoFarmMaterial")

-- (Các feature khác: Auto Piccolo, Duck, DevilBoat, Thief, Raid, Dungeon
--  áp dụng pattern tương tự - Register + Start, dùng Combat.FarmTarget)

return Farm
