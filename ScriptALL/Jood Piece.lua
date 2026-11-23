-- ============================================================
-- SAKURA | Jood Piece | MarvenRiz UI Lib
-- ESP + Auto Farm + Auto Skills Z/X/C/V + Auto Roll
-- UI: MarvenRizLib (loaded from GitHub)
-- ============================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- =================== LOAD MARVENRIZ UI LIB ===================
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/MarvenRizLib.lua"))()

-- ================= CONFIG =================
local CONFIG = {
    Enabled        = true,
    MaxDistance    = 2000,
    ShowHighlight  = true,
    ShowBillboard  = true,
    HighlightColor = Color3.fromRGB(255, 80, 110),

    AutoFarm       = false,
    TargetMobName  = nil,
    FarmPosition   = "Above", -- Above | Below | Behind | Front
    FarmDistance   = 6,       -- studs from the mob

    Skills = {
        Z = { enabled = false, keyCode = Enum.KeyCode.Z },
        X = { enabled = false, keyCode = Enum.KeyCode.X },
        C = { enabled = false, keyCode = Enum.KeyCode.C },
        V = { enabled = false, keyCode = Enum.KeyCode.V },
    },

    -- Auto Roll (Random Chance)
    AutoRoll   = false,
    RollAmount = 5,   -- 1 or 5 (only 5 was confirmed from the scan log)
}
local ATTACK_INTERVAL = 0.05 -- fixed attack speed (seconds)
local ROLL_INTERVAL   = 1.0  -- fixed delay between rolls (seconds)

-- ================= HELPERS =================
local function getMobsRoot() return Workspace:FindFirstChild("Mobs") end

local function isMobModel(inst)
    if not inst or not inst:IsA("Model") then return false end
    if not inst:FindFirstChildOfClass("Humanoid") then return false end
    if Players:GetPlayerFromCharacter(inst) then return false end
    return true
end

local function getHP(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return 0, 0 end
    return hum.Health, hum.MaxHealth
end

local function getMobPart(model)
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("Head")
        or model:FindFirstChildWhichIsA("BasePart")
end

local function getMyRoot()
    if LP.Character then
        return LP.Character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

-- ================= ESP =================
local activeESP = {}

local function clearESP(model)
    local data = activeESP[model]
    if not data then return end
    if data.highlight then data.highlight:Destroy() end
    if data.billboard then data.billboard:Destroy() end
    activeESP[model] = nil
end

local function clearAllESP()
    for model in pairs(activeESP) do clearESP(model) end
    activeESP = {}
end

local function createESP(model)
    if CONFIG.ShowHighlight then
        local hl = Instance.new("Highlight")
        hl.FillColor = CONFIG.HighlightColor
        hl.OutlineColor = CONFIG.HighlightColor
        hl.FillTransparency = 0.75
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = model
        activeESP[model] = activeESP[model] or {}
        activeESP[model].highlight = hl
    end
    if CONFIG.ShowBillboard then
        local adornee = getMobPart(model)
        if adornee then
            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 200, 0, 60)
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.AlwaysOnTop = true
            bb.MaxDistance = CONFIG.MaxDistance
            bb.Adornee = adornee
            bb.Parent = adornee

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Name = "NameLbl"
            nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.TextColor3 = Color3.new(1,1,1)
            nameLbl.TextStrokeTransparency = 0.2
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextScaled = true
            nameLbl.Text = model.Name
            nameLbl.Parent = bb

            local infoLbl = Instance.new("TextLabel")
            infoLbl.Name = "InfoLbl"
            infoLbl.Size = UDim2.new(1, 0, 0.5, 0)
            infoLbl.Position = UDim2.new(0, 0, 0.5, 0)
            infoLbl.BackgroundTransparency = 1
            infoLbl.TextColor3 = Color3.fromRGB(255, 230, 120)
            infoLbl.TextStrokeTransparency = 0.2
            infoLbl.Font = Enum.Font.Gotham
            infoLbl.TextScaled = true
            infoLbl.Parent = bb

            activeESP[model] = activeESP[model] or {}
            activeESP[model].billboard = bb
        end
    end
end

local function updateBillboards()
    for model, data in pairs(activeESP) do
        if not model.Parent then clearESP(model); continue end
        local bb = data.billboard
        if not bb or not bb.Parent then continue end
        local info = bb:FindFirstChild("InfoLbl")
        if not info then continue end
        local hp, maxhp = getHP(model)
        local root = getMyRoot()
        local mp = getMobPart(model)
        local distStr = ""
        if root and mp then
            distStr = string.format(" | %.0fm", (root.Position - mp.Position).Magnitude)
        end
        info.Text = string.format("HP: %d/%d%s", math.floor(hp), math.floor(maxhp), distStr)
    end
end

local function scanAndApply()
    if not CONFIG.Enabled then clearAllESP(); return end
    local root = getMobsRoot()
    if not root then return end
    local seen = {}
    local myRoot = getMyRoot()
    local myPos = myRoot and myRoot.Position or Vector3.zero
    for _, island in ipairs(root:GetChildren()) do
        if island:IsA("Folder") then
            for _, mob in ipairs(island:GetChildren()) do
                if isMobModel(mob) then
                    local mp = getMobPart(mob)
                    if mp and (mp.Position - myPos).Magnitude <= CONFIG.MaxDistance then
                        seen[mob] = true
                        if not activeESP[mob] then createESP(mob) end
                    end
                end
            end
        end
    end
    for model in pairs(activeESP) do
        if not seen[model] then clearESP(model) end
    end
end

-- ================= AUTO FARM =================
local currentTarget = nil
local lastAttack = 0
local lastTargetName = nil

local function setTargetMobName(name)
    CONFIG.TargetMobName = name
    if name ~= lastTargetName then
        currentTarget = nil
        lastTargetName = name
    end
end

local function tryAttack()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local tool = char:FindFirstChildWhichIsA("Tool")
    if tool then pcall(function() tool:Activate() end); return end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        local t = bp:FindFirstChildWhichIsA("Tool")
        if t then
            pcall(function() hum:EquipTool(t) end)
            task.wait(0.05)
            pcall(function() t:Activate() end)
            return
        end
    end
end

local function findTarget()
    if not CONFIG.TargetMobName then return nil end
    local root = getMobsRoot()
    if not root then return nil end
    local myRoot = getMyRoot()
    if not myRoot then return nil end
    local best, bestDist = nil, math.huge
    for _, island in ipairs(root:GetChildren()) do
        if island:IsA("Folder") then
            for _, mob in ipairs(island:GetChildren()) do
                if isMobModel(mob) and mob.Name == CONFIG.TargetMobName then
                    local hum = mob:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local mp = getMobPart(mob)
                        if mp then
                            local d = (mp.Position - myRoot.Position).Magnitude
                            if d < bestDist then best, bestDist = mob, d end
                        end
                    end
                end
            end
        end
    end
    return best
end

-- Where to stand relative to the mob (Setting > Farm)
local function getFarmCFrame(mobPart)
    local d = tonumber(CONFIG.FarmDistance) or 6
    local mode = CONFIG.FarmPosition
    local base = mobPart.CFrame
    local target = mobPart.Position
    if mode == "Above" then
        return CFrame.lookAt(target + Vector3.new(0, d, 0), target, Vector3.new(0, 0, 1))
    elseif mode == "Below" then
        return CFrame.lookAt(target - Vector3.new(0, d, 0), target, Vector3.new(0, 0, 1))
    elseif mode == "Behind" then
        return CFrame.lookAt((base * CFrame.new(0, 0, d)).Position, target)
    else -- Front
        return CFrame.lookAt((base * CFrame.new(0, 0, -d)).Position, target)
    end
end

local function autoFarmStep()
    if not CONFIG.AutoFarm or not CONFIG.TargetMobName then return end
    local char = LP.Character
    local myRoot = getMyRoot()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not myRoot or not hum or hum.Health <= 0 then return end
    if currentTarget and (not currentTarget.Parent or currentTarget.Name ~= CONFIG.TargetMobName) then
        currentTarget = nil
    end
    if currentTarget then
        local h = currentTarget:FindFirstChildOfClass("Humanoid")
        if not h or h.Health <= 0 then currentTarget = nil end
    end
    if not currentTarget then currentTarget = findTarget() end
    if not currentTarget then return end
    local mobPart = getMobPart(currentTarget)
    if not mobPart then return end
    pcall(function()
        myRoot.CFrame = getFarmCFrame(mobPart)
        myRoot.Velocity = Vector3.zero
    end)
    if tick() - lastAttack >= ATTACK_INTERVAL then
        lastAttack = tick()
        tryAttack()
    end
end

-- ================= AUTO SKILLS =================
local VIM
pcall(function() VIM = game:GetService("VirtualInputManager") end)

local function pressKey(keyCode)
    if VIM then
        pcall(function()
            VIM:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.02)
            VIM:SendKeyEvent(false, keyCode, false, game)
        end)
        return true
    end
    if typeof(keypress) == "function" then
        pcall(function()
            keypress(keyCode.Value); task.wait(0.02); keyrelease(keyCode.Value)
        end)
        return true
    end
    if typeof(keyclick) == "function" then
        pcall(function() keyclick(keyCode.Value) end); return true
    end
    return false
end

-- Skills only fire while a hack feature (currently Auto Farm) is running
local function isHackRunning()
    return CONFIG.AutoFarm
end

-- ================= AUTO ROLL (Random Chance) =================
-- Remote: ReplicatedStorage.System.RandomItem, FireServer(5) = Open x5
local RandomItemRemote
local rollCount, lastRoll = 0, 0
local rollPara -- assigned in the UI section

local function getRandomItemRemote()
    if RandomItemRemote and RandomItemRemote.Parent then return RandomItemRemote end
    local sys = ReplicatedStorage:FindFirstChild("System")
    RandomItemRemote = sys and sys:FindFirstChild("RandomItem")
    return RandomItemRemote
end

local function autoRollStep()
    if not CONFIG.AutoRoll then return end
    local now = tick()
    if now - lastRoll < ROLL_INTERVAL then return end
    lastRoll = now
    local r = getRandomItemRemote()
    if not r then return end
    local ok = pcall(function() r:FireServer(CONFIG.RollAmount) end)
    if ok then
        rollCount = rollCount + 1
        if rollPara then
            rollPara:SetContent(string.format("Rolled %d times (x%d each)", rollCount, CONFIG.RollAmount))
        end
    end
end

-- ================= BUILD UI (MarvenRiz) =================
local alive = true
local conns = {}
local MySaveManager = Library.SaveManager

local Window = Library:CreateWindow({
    Title = "MarvenRiz Hub",
    Subtitle = "Map : Jood Piece",
    Size = UDim2.fromOffset(500, 370),
    AccentColor = Color3.fromRGB(50, 150, 255),
    SideBarWidth = 120,
    Logo = "rbxassetid://87526284179554",
    LogoSize = 32,
    SphereText = false,
    SphereImage = "rbxassetid://87526284179554",
    SphereIconSize = 38,
    Map = "JoodPiece",
})

local function unload()
    if not alive then return end
    alive = false
    CONFIG.Enabled = false
    CONFIG.AutoFarm = false
    CONFIG.AutoRoll = false
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(clearAllESP)
    local sg = Window.MainFrame and Window.MainFrame:FindFirstAncestorOfClass("ScreenGui")
    if sg then pcall(function() sg:Destroy() end) end
end
do
    local sg = Window.MainFrame and Window.MainFrame:FindFirstAncestorOfClass("ScreenGui")
    if sg then table.insert(conns, sg.Destroying:Connect(unload)) end
end

local tabMain    = Window:CreateTab("Main", true, false)
local tabSetting = Window:CreateTab("Setting", false, false)
local tabCfg     = Window:CreateTab("Config", false, false)

-- ===================== MAIN =====================
-- Page: Farm (Auto Farm + mob selection)
local targetPara, mobPara, mobDropdown
local labelToMob = {}
local refreshingDropdown = false

local function updateTargetLabel()
    targetPara:SetTitle("Target: " .. (CONFIG.TargetMobName or "(none)"))
    targetPara:SetContent(CONFIG.TargetMobName
        and "Auto Farm teleports to the nearest mob with this name."
        or "Pick a mob from the list on the right.")
end

do
    local page = tabMain:CreatePage("Farm")
    local s1 = page:CreateSection("🌾 Auto Farm", "Left")
    local s2 = page:CreateSection("🎯 Select Mob", "Right")

    s1:Toggle({Title = "Auto Farm", Id = "FARM_ENABLED", Value = false, Callback = function(v)
        CONFIG.AutoFarm = v
    end})
    targetPara = s1:Paragraph({Title = "Target: (none)", Content = "Pick a mob from the list on the right."})

    mobPara = s2:Paragraph({Title = "Scanning...", Content = "Wait 1-2 seconds."})
    mobDropdown = s2:Dropdown({Title = "Target Mob", Options = {}, Multi = false, Callback = function(selected)
        if refreshingDropdown then return end -- ignore callbacks caused by list refresh
        local realName = selected and labelToMob[selected]
        if not realName then return end
        setTargetMobName(realName)
        updateTargetLabel()
        Library:Notify({
            Title = "Target selected",
            Description = "Auto Farm will attack: " .. tostring(realName),
            Duration = 3,
        })
    end})
end

-- Page: Roll (Auto Roll)
do
    local page = tabMain:CreatePage("Random")
    local s1 = page:CreateSection("🎰 Auto Random Chance", "Left")
    local s2 = page:CreateSection("📊 Status", "Right")
    s1:Toggle({Title = "Auto Random", Id = "ROLL_ENABLED", Value = false, Callback = function(v)
        CONFIG.AutoRoll = v
    end})
    s1:Dropdown({Title = "Amount per random", Options = {"x5", "x1"}, Multi = false, Value = "x5", Callback = function(v)
        CONFIG.RollAmount = (v == "x1") and 1 or 5
    end})
    rollPara = s2:Paragraph({Title = "Auto Random", Content = "No randoms yet."})
end

-- ===================== SETTING =====================
-- Single page with every setting: ESP, Skills, Farm
do
    local page = tabSetting:CreatePage("Setting")
    local sESP   = page:CreateSection("👁️ ESP", "Left")
    local sSkill = page:CreateSection("⚔️ Auto Skills (while Auto Farm runs)", "Right")
    local sFarm  = page:CreateSection("📍 Farm", "Right")

    -- ESP
    sESP:Toggle({Title = "Enable ESP", Id = "ESP_ENABLED", Value = CONFIG.Enabled, Callback = function(v)
        CONFIG.Enabled = v
        if not v then clearAllESP() end
    end})
    sESP:Toggle({Title = "Highlight (outline)", Id = "ESP_HIGHLIGHT", Value = CONFIG.ShowHighlight, Callback = function(v)
        CONFIG.ShowHighlight = v
        clearAllESP(); scanAndApply()
    end})
    sESP:Toggle({Title = "Billboard (HP + name)", Id = "ESP_BILLBOARD", Value = CONFIG.ShowBillboard, Callback = function(v)
        CONFIG.ShowBillboard = v
        clearAllESP(); scanAndApply()
    end})
    sESP:Slider({Title = "Scan Range", Min = 50, Max = 10000, Value = 2000, Callback = function(v)
        CONFIG.MaxDistance = v
    end})
    sESP:ColorPicker({Title = "Highlight Color", Value = CONFIG.HighlightColor, Callback = function(c)
        CONFIG.HighlightColor = c
        clearAllESP(); scanAndApply()
    end})

    -- Skills (only cast while Auto Farm is running)
    for _, name in ipairs({"Z", "X", "C", "V"}) do
        local sk = CONFIG.Skills[name]
        sSkill:Toggle({Title = "Auto Skills " .. name, Id = "SKILL" .. name, Value = false, Callback = function(v)
            sk.enabled = v
        end})
    end

    -- Farm (attack position, applied to Auto Farm)
    sFarm:Dropdown({Title = "Attack Position", Options = {"Above", "Below", "Behind", "Front"}, Multi = false, Value = "Above", Callback = function(v)
        CONFIG.FarmPosition = v
    end})
    sFarm:Slider({Title = "Follow Distance (studs)", Min = 0, Max = 30, Value = 6, Callback = function(v)
        CONFIG.FarmDistance = v
    end})
end

-- ===================== CONFIG =====================
if MySaveManager then
    pcall(function()
        MySaveManager:SetFolder("MarvenRiz_JoodPiece")
        MySaveManager:BuildConfigTab(tabCfg)
    end)
    task.spawn(function()
        task.wait(1)
        pcall(function() MySaveManager:LoadAutoloadConfig() end)
    end)
end

-- ================= MOB LIST SCANNER =================
local lastDropdownList = {}
task.spawn(function()
    while alive and task.wait(1) do
        if not CONFIG.Enabled then continue end
        local root = getMobsRoot()
        if not root then continue end
        local myRoot = getMyRoot()
        local myPos = myRoot and myRoot.Position or Vector3.zero
        local groups = {}
        for _, island in ipairs(root:GetChildren()) do
            if island:IsA("Folder") then
                for _, mob in ipairs(island:GetChildren()) do
                    if isMobModel(mob) then
                        local mp = getMobPart(mob)
                        if mp then
                            local d = (mp.Position - myPos).Magnitude
                            if d <= CONFIG.MaxDistance then
                                local hum = mob:FindFirstChildOfClass("Humanoid")
                                if hum and hum.Health > 0 then
                                    local key = island.Name .. "|" .. mob.Name
                                    local g = groups[key]
                                    if not g then
                                        g = { name = mob.Name, island = island.Name, count = 0 }
                                        groups[key] = g
                                    end
                                    g.count = g.count + 1
                                end
                            end
                        end
                    end
                end
            end
        end

        local items = {}
        for _, g in pairs(groups) do table.insert(items, g) end
        table.sort(items, function(a, b)
            if a.island ~= b.island then return a.island < b.island end
            return a.name < b.name
        end)

        -- Stable labels (no distance/count) so the selection is not reset on refresh
        local values, total = {}, 0
        local newMap = {}
        for _, it in ipairs(items) do
            local label = string.format("%s [%s]", it.name, it.island)
            table.insert(values, label)
            newMap[label] = it.name
            total = total + it.count
        end
        labelToMob = newMap

        local listChanged = (#values ~= #lastDropdownList)
        if not listChanged then
            for i = 1, #values do
                if values[i] ~= lastDropdownList[i] then listChanged = true; break end
            end
        end
        if listChanged then
            lastDropdownList = values
            refreshingDropdown = true
            pcall(function() mobDropdown:Refresh(#values > 0 and values or {"(no mobs)"}) end)
            refreshingDropdown = false
        end

        mobPara:SetTitle(string.format("Showing: %d groups / %d mobs", #items, total))
    end
end)

-- ================= AUTO SKILLS LOOPS (fast spam, no cooldown) =================
for _, sk in pairs(CONFIG.Skills) do
    task.spawn(function()
        while alive do
            if sk.enabled and isHackRunning() then
                local char = LP.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then pressKey(sk.keyCode) end
            end
            task.wait(0.05)
        end
    end)
end

-- ================= MAIN LOOPS =================
table.insert(conns, RunService.RenderStepped:Connect(function()
    scanAndApply()
    updateBillboards()
    autoFarmStep()
end))

table.insert(conns, RunService.Heartbeat:Connect(function()
    autoRollStep()
end))
