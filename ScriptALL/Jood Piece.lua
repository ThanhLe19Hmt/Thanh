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
    WeaponNames    = {},      -- selected weapons (Tool names); empty = default behavior

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
local MAX_WEAPONS     = 2    -- weapon lock: at most this many weapons can be used
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

-- ================= WEAPONS (multi-equip) =================
-- Verified by scan: several Tools can stay in the Character at the same time
-- (EquipTool on the first one, then Tool.Parent = Character for the rest).
local function getBackpack()
    return LP:FindFirstChildOfClass("Backpack") or LP:FindFirstChild("Backpack")
end

local function listWeaponNames()
    local names, seen = {}, {}
    local function add(container)
        if not container then return end
        for _, t in ipairs(container:GetChildren()) do
            if t:IsA("Tool") and not seen[t.Name] then
                seen[t.Name] = true
                table.insert(names, t.Name)
            end
        end
    end
    add(LP.Character)
    add(getBackpack())
    table.sort(names)
    return names
end

local function selectedSet()
    local set = {}
    for _, n in ipairs(CONFIG.WeaponNames) do set[n] = true end
    return set
end

local lastEquipSync = 0
local skillLock = false -- true while Auto Skills is swapping weapons (pauses syncWeapons)
local function syncWeapons()
    if skillLock then return end
    if #CONFIG.WeaponNames == 0 then return end
    local now = tick()
    if now - lastEquipSync < 0.4 then return end
    lastEquipSync = now
    pcall(function()
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local bp = getBackpack()
        if not (char and hum and bp) then return end
        local want = selectedSet()
        -- put away tools that are not selected
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and not want[t.Name] then t.Parent = bp end
        end
        -- hold every selected tool
        local holding = false
        for _, c in ipairs(char:GetChildren()) do
            if c:IsA("Tool") then holding = true; break end
        end
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and want[t.Name] then
                if holding then
                    t.Parent = char
                else
                    hum:EquipTool(t)
                    holding = true
                end
            end
        end
    end)
end

local function tryAttack()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- Selected weapons: activate every selected tool currently held
    if #CONFIG.WeaponNames > 0 then
        local want = selectedSet()
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and want[t.Name] then
                pcall(function() t:Activate() end)
            end
        end
        return
    end

    -- No selection: default behavior (first available tool)
    local tool = char:FindFirstChildWhichIsA("Tool")
    if tool then pcall(function() tool:Activate() end); return end
    local bp = getBackpack()
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
    syncWeapons()
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
local skillDbg -- Auto Skills status paragraph
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
local targetPara, mobPara, mobDropdown, weaponDropdown
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
    local page = tabMain:CreatePage("Roll")
    local s1 = page:CreateSection("🎰 Auto Roll", "Left")
    local s2 = page:CreateSection("📊 Status", "Right")
    s1:Toggle({Title = "Auto Roll", Id = "ROLL_ENABLED", Value = false, Callback = function(v)
        CONFIG.AutoRoll = v
    end})
    s1:Dropdown({Title = "Amount per roll", Options = {"x5", "x1"}, Multi = false, Value = "x5", Callback = function(v)
        CONFIG.RollAmount = (v == "x1") and 1 or 5
    end})
    rollPara = s2:Paragraph({Title = "Auto Roll", Content = "No rolls yet."})
end

-- ===================== SETTING =====================
-- Single page with every setting: ESP, Skills, Farm
do
    local page = tabSetting:CreatePage("Setting")
    local sESP   = page:CreateSection("👁️ ESP", "Left")
    local sWeapon = page:CreateSection("🗡️ Weapons (max " .. MAX_WEAPONS .. ")", "Left")
    local sSkill = page:CreateSection("⚔️ Auto Skills (every selected weapon)", "Right")
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

    -- Weapons (weapon lock: only MAX_WEAPONS can be selected)
    weaponDropdown = sWeapon:Dropdown({Title = "Weapons (select up to " .. MAX_WEAPONS .. ")", Options = listWeaponNames(), Multi = true, Value = {}, Callback = function(sel)
        -- the library passes the same table every time, so copy it
        if type(sel) ~= "table" then return end
        if #sel > MAX_WEAPONS then
            -- Weapon lock: reject the newest pick. The library hands us its own selection
            -- table, so remove the extra entries in place, then re-sync the dropdown UI.
            while #sel > MAX_WEAPONS do table.remove(sel) end
            Library:Notify({
                Title = "Weapon lock",
                Description = "Only " .. MAX_WEAPONS .. " weapons allowed. Deselect one to pick another.",
                Duration = 3,
            })
            task.defer(function()
                -- NOTE: call with a dot, Set takes the selection directly (no self argument)
                if weaponDropdown then pcall(weaponDropdown.Set, sel) end
            end)
            return
        end
        -- copy it, the library reuses the same table every time
        local copy = {}
        for _, n in ipairs(sel) do table.insert(copy, n) end
        CONFIG.WeaponNames = copy
    end})

    -- Skills (only cast while Auto Farm is running)
    for _, name in ipairs({"Z", "X", "C", "V"}) do
        local sk = CONFIG.Skills[name]
        sSkill:Toggle({Title = "Auto Skills " .. name, Id = "SKILL" .. name, Value = false, Callback = function(v)
            sk.enabled = v
        end})
    end

    skillDbg = sSkill:Paragraph({Title = "Skill status", Content = "Waiting: Auto Farm is OFF"})

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

-- ================= WEAPON LIST REFRESH =================
local lastWeaponList = {}
task.spawn(function()
    while alive and task.wait(2) do
        local names = listWeaponNames()
        local changed = (#names ~= #lastWeaponList)
        if not changed then
            for i = 1, #names do
                if names[i] ~= lastWeaponList[i] then changed = true; break end
            end
        end
        if changed and weaponDropdown then
            lastWeaponList = names
            pcall(function() weaponDropdown:Refresh(names) end) -- keeps the selection
        end
    end
end)

-- ================= AUTO SKILLS (all selected weapons) =================
-- What the scan logs + decompiled client code showed:
--  * The game's own key handler (GUIHandle) only works for the LAST tool added to the
--    character and is reset whenever any Tool leaves the character, so pressing keys
--    after swapping weapons does nothing. => we do NOT press keys; we send the skill
--    packet ourselves through the game's SkillBridge: {"Skill", key, CFrame}.
--  * The packet has no weapon name. The SERVER casts the skill of the first Tool it
--    sees in the character (re-ordering Tools only on the client changes nothing).
--  * Tool attribute Z/X/C/V == true means that skill is on cooldown.
--    Character attribute Skilling == true while a skill animation is playing.
-- So: cast every ready skill of the weapon that is currently first; when it has nothing
-- ready, move ONLY that first weapon out and back in (it goes to the back of the line)
-- until the next weapon is first. No weapon is ever swapped for a single cast.
local SKILL_ORDER = { "Z", "X", "C", "V" }
local lastTry = {}
local lastDbg, lastCast = "", "-"

local SkillBridge
pcall(function()
    local mod = ReplicatedStorage:FindFirstChild("Modules")
    mod = mod and mod:FindFirstChild("BridgeNet2")
    if mod then SkillBridge = require(mod).ReferenceBridge("SkillBridge") end
end)
local SkillFolder = ReplicatedStorage:FindFirstChild("Skill")

local function dbg(msg)
    msg = msg .. "\nLast cast: " .. lastCast
    if msg == lastDbg then return end
    lastDbg = msg
    if skillDbg then pcall(function() skillDbg:SetContent(msg) end) end
end

local function sendSkill(key)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local packet = { "Skill", key, hrp.CFrame }
    if SkillBridge then
        if pcall(function() SkillBridge:Fire(packet) end) then return true end
    end
    -- fallback: raw BridgeNet2 packet (identifier "\2" was seen in the log)
    local bn = ReplicatedStorage:FindFirstChild("BridgeNet2")
    local remote = bn and bn:FindFirstChild("dataRemoteEvent")
    if remote then
        return pcall(function() remote:FireServer({ packet, "\2" }) end)
    end
    return false
end

local function toolHasKey(tool, key)
    if not SkillFolder then return true end
    local f = SkillFolder:FindFirstChild(tool.Name)
    return f ~= nil and f:FindFirstChild(key) ~= nil
end

local function firstHeldTool()
    local char = LP.Character
    if not char then return nil end
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Tool") then return c end
    end
    return nil
end

local function heldSkillTools()
    local char = LP.Character
    local list = {}
    if not char then return list end
    local want = (#CONFIG.WeaponNames > 0) and selectedSet() or nil
    local first = firstHeldTool()
    if first and (not want or want[first.Name]) then table.insert(list, first) end
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") and t ~= first and (not want or want[t.Name]) then
            table.insert(list, t)
        end
    end
    return list
end

-- Move the current first tool out and back in (different frames, so the server sees it)
local function rotateTo(target, char, bp)
    for _ = 1, 5 do
        local f = firstHeldTool()
        if not f or f == target then return true end
        f.Parent = bp
        task.wait(0.15)
        f.Parent = char
        task.wait(0.15)
    end
    return firstHeldTool() == target
end

local function castSkill(tool, key, char, bp)
    skillLock = true
    local result = "no response"
    pcall(function()
        if firstHeldTool() ~= tool and not rotateTo(tool, char, bp) then
            result = "could not reorder"
            return
        end
        sendSkill(key)
        local t0 = tick()
        repeat task.wait(0.05)
        until tool:GetAttribute(key) == true or char:GetAttribute("Skilling") == true or tick() - t0 > 0.6
        if tool:GetAttribute(key) == true or char:GetAttribute("Skilling") == true then result = "OK" end
    end)
    skillLock = false
    return result
end

task.spawn(function()
    while alive do
        task.wait(0.05)
        if not isHackRunning() then dbg("Waiting: Auto Farm is OFF"); continue end

        local anyEnabled = false
        for _, n in ipairs(SKILL_ORDER) do
            if CONFIG.Skills[n].enabled then anyEnabled = true; break end
        end
        if not anyEnabled then dbg("Waiting: no Auto Skills toggle is ON"); continue end

        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local bp = getBackpack()
        if not (char and hum and bp) or hum.Health <= 0 then dbg("Waiting: character not ready"); continue end
        if char:GetAttribute("Skilling") == true then dbg("Waiting: a skill is playing"); continue end

        local tools = heldSkillTools()
        if #tools == 0 then dbg("Waiting: no weapon is held"); continue end

        local pickTool, pickKey
        local now = tick()
        for _, tool in ipairs(tools) do
            for _, n in ipairs(SKILL_ORDER) do
                if CONFIG.Skills[n].enabled and toolHasKey(tool, n) and tool:GetAttribute(n) ~= true then
                    local id = tool.Name .. "|" .. n
                    if not lastTry[id] or now - lastTry[id] >= 1.0 then
                        pickTool, pickKey = tool, n
                        break
                    end
                end
            end
            if pickTool then break end
        end

        if pickTool then
            lastTry[pickTool.Name .. "|" .. pickKey] = now
            dbg(string.format("Casting: %s [%s]", pickTool.Name, pickKey))
            local res = castSkill(pickTool, pickKey, char, bp)
            lastCast = string.format("%s [%s] -> %s", pickTool.Name, pickKey, res)
            task.wait(0.1)
        else
            dbg("Waiting: all enabled skills are on cooldown")
        end
    end
end)

-- ================= MAIN LOOPS =================
table.insert(conns, RunService.RenderStepped:Connect(function()
    scanAndApply()
    updateBillboards()
    autoFarmStep()
end))

table.insert(conns, RunService.Heartbeat:Connect(function()
    autoRollStep()
end))
