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
    AutoBoss       = false,
    BossNames      = {}, -- selected boss order
    TargetMobName  = nil,
    FarmPosition   = "Above", -- Above | Below | Behind | Front
    FarmDistance   = 6,       -- studs from the mob
    WeaponNames    = {},      -- selected weapons (Tool names); empty = default behavior

    IslandESP      = false,
    IslandColor    = Color3.fromRGB(80, 200, 255),

    Skills = {
        Z = { enabled = false, keyCode = Enum.KeyCode.Z },
        X = { enabled = false, keyCode = Enum.KeyCode.X },
        C = { enabled = false, keyCode = Enum.KeyCode.C },
        V = { enabled = false, keyCode = Enum.KeyCode.V },
    },

    AutoTransform = false, -- cast a weapon's transform skill once when it is not transformed

    -- Auto Roll (Random Chance)
    AutoRoll   = false,
    RollAmount = 5,   -- 1 or 5 (only 5 was confirmed from the scan log)
}
local MAX_WEAPONS     = 4    -- weapon lock: at most this many weapons can be used
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
local raidFarmActive = false   -- Auto Castle Raid: farm every mob in the raid map (independent of Auto Farm)
local lastWildFind = 0
local VON = { enabled = false, busy = false, status = "OFF", farmJester = false, spawnSeq = 0, deathSeq = 0, spawnAtClick = 0, watched = setmetatable({}, { __mode = "k" }), gen = 0, runGen = 0, state = "idle", tries = 0, beat = 0 } -- Auto VON JOESTAR (own loop, see bottom)
local farmEngaged = false      -- true only while a live target mob exists and we are on it
local farmStatusCallback        -- set by the UI (updates the Target paragraph)
local lastFarmMsg
local function farmStatus(msg)
    if msg == lastFarmMsg then return end
    lastFarmMsg = msg
    if farmStatusCallback then pcall(farmStatusCallback, msg) end
end

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

local knownWeapons = {}          -- weapon name -> last time it was seen in Character/Backpack
local refreshingWeapons = false  -- true while the dropdown list is being refreshed
local WEAPON_FORGET_AFTER = 20   -- seconds a weapon must be missing (while alive) to be dropped

local function listWeaponNames()
    local now = tick()
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local bp = getBackpack()
    local present = {}
    local function add(container)
        if not container then return end
        for _, t in ipairs(container:GetChildren()) do
            if t:IsA("Tool") then
                present[t.Name] = true
                knownWeapons[t.Name] = now
            end
        end
    end
    add(char)
    add(bp)

    local alive = hum ~= nil and hum.Health > 0 and bp ~= nil
    for name, seen in pairs(knownWeapons) do
        if not present[name] then
            if alive then
                -- really gone (sold / stored / traded): forget it after a grace period
                if now - seen > WEAPON_FORGET_AFTER then knownWeapons[name] = nil end
            else
                -- dead or respawning: freeze the timer so death never removes options
                knownWeapons[name] = now
            end
        end
    end

    local names = {}
    for n in pairs(knownWeapons) do table.insert(names, n) end
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

local skillWindowUntil = 0 -- while tick() < this, basic attacks pause so a skill can start

local function tryAttack()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if tick() < skillWindowUntil then return end -- <<< new line

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

local function findTarget(targetName)
    targetName = targetName or CONFIG.TargetMobName
    if not targetName then return nil end
    local myRoot = getMyRoot()
    if not myRoot then return nil end
    local wildcard = targetName == "*"
    if wildcard then
        if tick() - lastWildFind < 0.5 then return nil end -- throttle the wide scan
        lastWildFind = tick()
    end

    -- where to look: Workspace.Mobs (+ Workspace.Raid); in a raid map with neither, the whole Workspace
    local roots = {}
    local mobsRoot = getMobsRoot()
    if mobsRoot then roots[#roots + 1] = mobsRoot end
    if wildcard then
        local raidFolder = Workspace:FindFirstChild("Raid")
        if raidFolder then roots[#roots + 1] = raidFolder end
        if #roots == 0 then roots[1] = Workspace end
    end
    if #roots == 0 then return nil end

    local npcFolder = Workspace:FindFirstChild("NPC")
    local best, bestDist = nil, math.huge
    for _, root in ipairs(roots) do
        for _, mob in ipairs(root:GetDescendants()) do
            if (wildcard or mob.Name == targetName) and mob.Name ~= "Base" and mob:IsA("Model") and isMobModel(mob)
                and not (wildcard and npcFolder and mob:IsDescendantOf(npcFolder)) then
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

local lastBossSelection = ""
local lastFarmTargetName = nil
local lastBossName = nil

local function getBossSelectionKey()
    local names = {}
    for _, name in ipairs(CONFIG.BossNames) do
        if type(name) == "string" then table.insert(names, name) end
    end
    table.sort(names)
    return table.concat(names, "|")
end

local function pickRandomAliveBoss()
    local candidates = {}
    for _, name in ipairs(CONFIG.BossNames) do
        local model = findTarget(name)
        if model then
            table.insert(candidates, {name = name, model = model})
        end
    end
    if #candidates == 0 then return nil, nil end

    -- Avoid immediately choosing the same boss again when another boss is alive.
    local alternatives = {}
    if #candidates > 1 then
        for _, candidate in ipairs(candidates) do
            if candidate.name ~= lastBossName then
                table.insert(alternatives, candidate)
            end
        end
    end
    local pool = (#alternatives > 0) and alternatives or candidates
    local chosen = pool[math.random(1, #pool)]
    lastBossName = chosen.name
    return chosen.name, chosen.model
end

local holdCFrame = nil -- last farm position: kept while there is no target so the character does not fall

local bossLocked = false -- true while a boss is the locked target (prevents ping-pong with the mob)

local function isAliveModel(m)
    local h = m and m.Parent and m:FindFirstChildOfClass("Humanoid")
    return h ~= nil and h.Health > 0
end

-- the boss is named "Von Joestar" in the game: match case-insensitively, cache the model, rescan at most every 0.5s
local vonCache, vonScanAt = nil, 0
function VON.find()
    if vonCache and isAliveModel(vonCache) then return vonCache end
    vonCache = nil
    if tick() - vonScanAt < 0.3 then return nil end -- throttle: never scan every frame
    vonScanAt = tick()
    -- the real model name is "Von Joestar" (not upper case): match case-insensitively
    local function isVon(o)
        if not o:IsA("Model") then return false end
        local n = o.Name:lower()
        if not n:find("joestar", 1, true) or n:find("summon", 1, true) then return false end
        return isAliveModel(o) and getMobPart(o) ~= nil
    end
    local mr = getMobsRoot()
    if mr then
        for _, o in ipairs(mr:GetDescendants()) do
            if isVon(o) then vonCache = o; return o end
        end
    end
    for _, o in ipairs(Workspace:GetChildren()) do
        if isVon(o) then vonCache = o; return o end
    end
    return nil
end

local function autoFarmStepInner()
    farmEngaged = false
    if VON.busy then return end -- summon sequence is moving the character
    if not CONFIG.AutoFarm and not CONFIG.AutoBoss and not raidFarmActive and not VON.enabled then bossLocked = false; return end

    local wantBoss = CONFIG.AutoBoss and not raidFarmActive and #CONFIG.BossNames > 0
    local wantMob = CONFIG.AutoFarm or raidFarmActive
    local targetName = raidFarmActive and "*" or CONFIG.TargetMobName
    if VON.enabled and VON.farmJester and not raidFarmActive then
        wantMob = true; targetName = "Jester" -- no Von Soul left: farm Jester until one drops
    end

    if CONFIG.AutoBoss and not raidFarmActive then
        local selectionKey = getBossSelectionKey()
        if selectionKey ~= lastBossSelection then
            lastBossSelection = selectionKey
            if bossLocked then currentTarget = nil; bossLocked = false end
            lastBossName = nil
        end
        if #CONFIG.BossNames == 0 and not wantMob then
            farmStatus("No boss selected.")
            currentTarget = nil
            return
        end
    end

    local char = LP.Character
    local myRoot = getMyRoot()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not myRoot or not hum or hum.Health <= 0 then return end

    -- 1) keep the locked boss until it dies (no switching back to the mob)
    if bossLocked then
        if isAliveModel(currentTarget) then
            targetName = lastBossName
        else
            bossLocked = false
            currentTarget = nil
        end
    end

    -- 2a) VON JOESTAR (own toggle) has the highest priority
    if not bossLocked and VON.enabled and not raidFarmActive then
        local vm = VON.find()
        if vm then
            bossLocked = true
            currentTarget = vm
            targetName = vm.Name
            lastBossName = vm.Name
        end
    end

    -- 2) boss has priority: pick one as soon as any selected boss is alive
    if not bossLocked and wantBoss then
        local n, m = pickRandomAliveBoss()
        if m then
            bossLocked = true
            currentTarget = m
            targetName = n
        end
    end

    -- 3) otherwise farm the mob (also the "return to mob" step after a boss dies)
    if not bossLocked then
        if not wantMob then
            farmStatus("No selected boss is alive - waiting.")
            return
        end
        if targetName ~= lastFarmTargetName then
            currentTarget = nil
            lastFarmTargetName = targetName
        end
        if currentTarget and not isAliveModel(currentTarget) then currentTarget = nil end
        if not currentTarget and targetName then currentTarget = findTarget(targetName) end
    end

    if not targetName or not currentTarget then
        -- no mob left: autoFarmStep keeps holdCFrame (last farm spot), so we stay/return there safely
        farmStatus('No alive "' .. tostring(targetName) .. '" found - waiting. Skills paused.')
        return
    end

    local mobPart = getMobPart(currentTarget)
    if not mobPart then currentTarget = nil; bossLocked = false; return end

    farmEngaged = true
    syncWeapons()
    farmStatus(bossLocked and ("Boss: " .. tostring(targetName)) or (raidFarmActive and "Raid farm: nearest mob" or "Farming: " .. tostring(targetName)))
    pcall(function()
        local cf = getFarmCFrame(mobPart)
        -- keep the mob farm spot as the "home" position; a boss only sets it if none exists yet
        if not bossLocked or not holdCFrame then holdCFrame = cf end
        myRoot.CFrame = cf
        myRoot.Velocity = Vector3.zero
    end)
    if tick() - lastAttack >= ATTACK_INTERVAL then
        lastAttack = tick()
        tryAttack()
    end
end
local function autoFarmStep()
    if VON.busy then return end
    autoFarmStepInner()
    if not (CONFIG.AutoFarm or CONFIG.AutoBoss or raidFarmActive or VON.enabled) then
        holdCFrame = nil
        return
    end
    if farmEngaged or not holdCFrame then return end
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = getMyRoot()
    if not root or not hum or hum.Health <= 0 then holdCFrame = nil; return end
    pcall(function()
        root.CFrame = holdCFrame
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
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
    return (CONFIG.AutoFarm or CONFIG.AutoBoss or raidFarmActive or VON.enabled) and farmEngaged
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

-- ================= ISLAND ESP =================
-- ReplicatedStorage.Modules.IslandInfo = { [islandName] = { Position = Vector3, Range = number } }
-- (the game itself uses it to set the character's "Island" attribute)
local IslandInfo
pcall(function()
    local mod = ReplicatedStorage:FindFirstChild("Modules")
    mod = mod and mod:FindFirstChild("IslandInfo")
    if mod then IslandInfo = require(mod) end
end)

local islandESP = {}      -- name -> { part, label, pos }
local islandFolder
local ISLAND_LABEL_HEIGHT = 40 -- studs above the island point so the label is easy to see

local function getIslandPoints()
    local list = {}
    if type(IslandInfo) == "table" then
        for name, info in pairs(IslandInfo) do
            local pos = type(info) == "table" and (info.Position or info.CFrame or info.Pos or info.Center) or info
            if typeof(pos) == "CFrame" then pos = pos.Position end
            if typeof(pos) == "Vector3" then
                table.insert(list, { name = tostring(name), pos = pos })
            end
        end
    end
    if #list == 0 then
        -- fallback: average position of the mobs of each island folder
        local root = getMobsRoot()
        if root then
            for _, island in ipairs(root:GetChildren()) do
                if island:IsA("Folder") then
                    local sum, n = Vector3.zero, 0
                    for _, mob in ipairs(island:GetChildren()) do
                        local mp = isMobModel(mob) and getMobPart(mob)
                        if mp then sum = sum + mp.Position; n = n + 1 end
                    end
                    if n > 0 then table.insert(list, { name = island.Name, pos = sum / n }) end
                end
            end
        end
    end
    return list
end

local function clearIslandESP()
    for _, d in pairs(islandESP) do
        pcall(function() d.part:Destroy() end)
    end
    islandESP = {}
end

local function buildIslandESP()
    clearIslandESP()
    if not islandFolder or not islandFolder.Parent then
        islandFolder = Instance.new("Folder")
        islandFolder.Name = "SakuraIslandESP"
        islandFolder.Parent = Workspace
    end
    for _, it in ipairs(getIslandPoints()) do
        local part = Instance.new("Part")
        part.Name = it.name
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.Transparency = 1
        part.Size = Vector3.new(1, 1, 1)
        part.Position = it.pos + Vector3.new(0, ISLAND_LABEL_HEIGHT, 0)
        part.Parent = islandFolder

        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 170, 0, 44)
        bb.AlwaysOnTop = true
        bb.MaxDistance = 1e9
        bb.ResetOnSpawn = false
        bb.Adornee = part
        bb.Parent = part

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = CONFIG.IslandColor
        label.TextStrokeTransparency = 0.2
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true
        label.Text = it.name
        label.Parent = bb

        islandESP[it.name] = { part = part, label = label, pos = it.pos }
    end
end

-- ================= ISLAND TELEPORT =================
local selectedIsland
local tpDropdown
local lastIslandNames = {}

local function getIslandNames()
    local names = {}
    for _, it in ipairs(getIslandPoints()) do table.insert(names, it.name) end
    table.sort(names)
    return names
end

local function teleportToIsland(name)
    local root = getMyRoot()
    if not root or not name then return false end
    for _, it in ipairs(getIslandPoints()) do
        if it.name == name then
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = { LP.Character, islandFolder }
            local hit = Workspace:Raycast(it.pos + Vector3.new(0, 300, 0), Vector3.new(0, -1000, 0), params)
            local target = (hit and hit.Position or it.pos) + Vector3.new(0, 6, 0)
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = CFrame.new(target)
            return true
        end
    end
    return false
end

-- ================= AUTO STORE =================
-- MainGui.INVENTORY.BackpackFrame ("TO STORE"): each item Frame has a Button whose
-- MouseButton1Click handler (Monitor script) moves the item into storage.
local STORE = {
    enabled  = false,
    interval = 1,    -- seconds between passes
    delay    = 0.15, -- seconds between items
    skip     = {},   -- item names to keep, e.g. { ["Seven"] = true }
}

local function getInventoryGui()
    local pg = LP:FindFirstChild("PlayerGui")
    local main = pg and pg:FindFirstChild("MainGui")
    local inv = main and main:FindFirstChild("INVENTORY")
    return inv, inv and inv:FindFirstChild("BackpackFrame")
end

local function getInvRemote()
    local sys = ReplicatedStorage:FindFirstChild("System")
    local inv = sys and sys:FindFirstChild("Inv")
    return inv and inv:FindFirstChild("Inventory") -- RemoteFunction
end

-- RemoteFunction:InvokeServer can yield forever if the server never answers; that froze whole loops.
local function invokeTimeout(remote, timeout, ...)
    local args = table.pack(...)
    local done, ok, res = false, false, nil
    task.spawn(function()
        ok, res = pcall(function() return remote:InvokeServer(table.unpack(args, 1, args.n)) end)
        done = true
    end)
    local t = tick()
    while not done and tick() - t < timeout do task.wait(0.05) end
    if not done then return false, nil end
    return ok, res
end

local lastStoreFail = {} -- item name -> time until we stop retrying it

local function storeOnce()
    local remote = getInvRemote()
    local bp = getBackpack()
    local items = ReplicatedStorage:FindFirstChild("Items")
    if not remote or not bp or not items then return 0 end
    local skills = ReplicatedStorage:FindFirstChild("Skill")
    local keep = selectedSet() -- never store the weapons you selected

    -- storable item = Tool in Backpack that exists in ReplicatedStorage.Items
    -- and is not a weapon (weapons live in ReplicatedStorage.Skill)
    local counts = {}
    for _, t in ipairs(bp:GetChildren()) do
        local nm = t.Name
        if t:IsA("Tool")
            and not STORE.skip[nm] and not keep[nm]
            and items:FindFirstChild(nm)
            and not (skills and skills:FindFirstChild(nm))
            and (not lastStoreFail[nm] or tick() > lastStoreFail[nm]) then
            counts[nm] = (counts[nm] or 0) + (tonumber(t:GetAttribute("Amount")) or 1)
        end
    end

    local n = 0
    for nm, amount in pairs(counts) do
        if not STORE.enabled then break end
        -- same call the game's own Store button makes
        local ok, res = invokeTimeout(remote, 3, "Add", nm, amount)
        if ok and res ~= false then
            n += 1
        else
            lastStoreFail[nm] = tick() + 30 -- back off if the server refuses
        end
        task.wait(STORE.delay)
    end
    return n
end

local alive = true -- must be declared BEFORE the loops below (otherwise they see a nil global and never run)
-- ================= AUTO ALL RAID =================
local CASTLE = {
    enabled = false,
    autoReplay = true, -- press Replay on the result board while Castle Tickets remain
    lastReplay = 0,
    replayCount = 0,
    summoned = false, -- a gate was already opened this session: never spend a second ticket automatically
    MAIN_PLACE = 117676969731858,
    RAID_PLACE = 135193584835072,
}
local castlePara
local lastCastleOpen = 0
local lastStartTry, startAttempt = 0, 0

local function castleStatus(msg)
    if castlePara then pcall(function() castlePara:SetContent(msg) end) end
end

local function castleInvRemote()
    local sys = ReplicatedStorage:FindFirstChild("System")
    local inv = sys and sys:FindFirstChild("Inv")
    return inv and inv:FindFirstChild("Inventory")
end

local function castleTicketTool()
    local bp, ch = getBackpack(), LP.Character
    return (bp and bp:FindFirstChild("Castle Ticket")) or (ch and ch:FindFirstChild("Castle Ticket"))
end

-- the NPC consumes the ticket Tool from the Backpack; take one out of storage if needed
local function ensureCastleTicket()
    if castleTicketTool() then return true end
    local data = LP:FindFirstChild("InvData")
    local stored = data and data:FindFirstChild("Castle Ticket")
    if not stored or (tonumber(stored.Value) or 0) < 1 then return false end
    local remote = castleInvRemote()
    if not remote then return false end
    pcall(function() remote:InvokeServer("Remove", "Castle Ticket", 1) end)
    local t = tick()
    repeat task.wait(0.2) until castleTicketTool() or tick() - t > 3
    return castleTicketTool() ~= nil
end

-- ---------- main map: click the NPC, stand in the gate ----------
local function castleStep()
    local root, char = getMyRoot(), LP.Character
    if not root or not char then return end

    local portal = Workspace:FindFirstChild("TowerRaidPart")
    if portal then
        -- the game flags InRaid when we are above the part's Y and within max(size)/2 horizontally
        local px, pz = portal.Position.X, portal.Position.Z
        local flat = Vector3.new(root.Position.X - px, 0, root.Position.Z - pz).Magnitude
        if flat > 20 then
            root.CFrame = CFrame.new(px - 8, math.max(portal.Position.Y + 4, root.Position.Y), pz)
        end
        root.AssemblyLinearVelocity = Vector3.zero
        castleStatus("In the gate - waiting for the ~20s teleport (InRaid=" .. tostring(char:GetAttribute("InRaid")) .. ")")
        return
    end

    -- no gate: summon at most ONE per session (an expired gate must not burn another ticket)
    if CASTLE.summoned then
        castleStatus("Gate expired / closed - no new ticket used. Toggle Auto Castle Raid OFF then ON to summon again.")
        return
    end
    if tick() - lastCastleOpen < 15 then return end
    local npcs = Workspace:FindFirstChild("NPC")
    local npc = npcs and npcs:FindFirstChild("TowerRaidSummon") -- overhead text "INF Castle" (NOT CastleShop)
    local cd = npc and npc:FindFirstChildWhichIsA("ClickDetector", true)
    if not cd then castleStatus("INF Castle NPC not found"); return end
    if not ensureCastleTicket() then castleStatus("No Castle Ticket (Backpack or storage)"); return end
    lastCastleOpen = tick()
    CASTLE.summoned = true
    root.CFrame = CFrame.new(npc:GetPivot().Position + Vector3.new(0, 3, 6))
    task.wait(0.6)
    pcall(fireclickdetector, cd)
    castleStatus("Clicked INF Castle - waiting for the gate...")
    local t = tick()
    repeat task.wait(0.25) until Workspace:FindFirstChild("TowerRaidPart") or tick() - t > 6
end

-- ---------- raid map: press Start, then farm every mob ----------
local RaidBridge
pcall(function()
    local mod = ReplicatedStorage:FindFirstChild("Modules")
    mod = mod and mod:FindFirstChild("BridgeNet2")
    if mod then RaidBridge = require(mod).ReferenceBridge("Raid") end
end)

local function setRaidFarm(on)
    if raidFarmActive == on then return end
    raidFarmActive = on
    currentTarget = nil
end

local function pressRaidStart()
    if tick() - lastStartTry < 2 then return end
    lastStartTry = tick()
    startAttempt = startAttempt + 1
    if startAttempt % 2 == 1 and RaidBridge then
        -- same packet the game sends when you click "Click To Start": {1}
        pcall(function() RaidBridge:Fire({1}) end)
    else
        -- fallback: click the GUI button itself
        local pg = LP:FindFirstChildOfClass("PlayerGui")
        local gui = pg and pg:FindFirstChild("Raid")
        local btn = gui and gui:FindFirstChild("Start")
        if btn and btn:IsA("GuiButton") and getconnections then
            for _, sig in ipairs({"MouseButton1Click", "Activated"}) do
                local ok, cs = pcall(getconnections, btn[sig])
                if ok and cs then
                    for _, c in ipairs(cs) do pcall(function() c:Fire() end) end
                end
            end
        end
    end
end

local function raidStep()
    local raid = Workspace:FindFirstChild("Raid")
    local started = raid and raid:GetAttribute("Started") == true
    local ended = raid and raid:GetAttribute("End") == true
    if ended then
        setRaidFarm(false)
        if not CASTLE.autoReplay then
            castleStatus("Raid ended (Auto Replay is OFF)")
            return
        end
        -- result board: PlayerGui.Raid.Replay, label "Requset" reads "Request : Castle Ticket (have/need)"
        local pg = LP:FindFirstChildOfClass("PlayerGui")
        local gui = pg and pg:FindFirstChild("Raid")
        local replay = gui and gui:FindFirstChild("Replay")
        if not (replay and replay:IsA("GuiButton") and replay.Visible) then
            castleStatus("Raid ended - waiting for the Replay button...")
            return
        end
        local req = replay:FindFirstChild("Requset")
        local have, need = tostring(req and req.Text or ""):match("%((%d+)/(%d+)%)")
        if have and need and tonumber(have) < tonumber(need) then
            castleStatus("Out of tickets (" .. have .. "/" .. need .. ") - Auto Replay stopped")
            return
        end
        if tick() - CASTLE.lastReplay < 12 then
            castleStatus("Replay sent - waiting for the new raid... (tickets " .. tostring(have) .. "/" .. tostring(need) .. ")")
            return
        end
        CASTLE.lastReplay = tick()
        CASTLE.replayCount = CASTLE.replayCount + 1
        local sent = false
        if RaidBridge then
            -- same packet the Replay button sends: content {4}
            sent = pcall(function() RaidBridge:Fire({4}) end)
        end
        if not sent and getconnections then
            local ok, cs = pcall(getconnections, replay.MouseButton1Click)
            if ok and cs then
                for _, c in ipairs(cs) do pcall(function() c:Fire() end) end
            end
        end
        castleStatus("Replay #" .. CASTLE.replayCount .. " sent (tickets " .. tostring(have) .. "/" .. tostring(need) .. ")")
        return
    end
    if not started then
        setRaidFarm(false)
        pressRaidStart()
        castleStatus("In the raid map - pressing Start...")
        return
    end
    setRaidFarm(true)
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    local waveLbl = pg and pg:FindFirstChild("Raid") and pg.Raid:FindFirstChild("Wave")
    castleStatus("Raiding " .. ((waveLbl and waveLbl:IsA("TextLabel")) and waveLbl.Text or ""))
end

task.spawn(function()
    while alive do
        task.wait(0.5)
        if not CASTLE.enabled and raidFarmActive then setRaidFarm(false) end
        if CASTLE.enabled then
            if game.PlaceId == CASTLE.RAID_PLACE then
                local ok, err = pcall(raidStep)
                if not ok then castleStatus("Raid error: " .. tostring(err)) end
            else
                CASTLE.enabled = false
                setRaidFarm(false)
            end
        end
    end
end)

-- ================= WEAPON CRAFT =================
-- Weapons are sold by the NPCs inside Workspace.NPC.Seller (one child per weapon). Each one shows
-- three labels: name, recipe ("50KG + 15 Shadow Essence + ...") and type. Clicking the NPC with
-- the items in your inventory/storage crafts it instantly (no GUI), so Craft = go to the NPC and click.
local CRAFT = { list = {}, byLabel = {}, selected = nil, lastKey = "" }
local craftDropdown, craftPara

local function normName(s)
    return (tostring(s):lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function trimStr(s) return (tostring(s):gsub("^%s+", ""):gsub("%s+$", "")) end

local itemNameMap -- normalized name -> real item name (ReplicatedStorage.Items)
local function getItemName(name)
    if not itemNameMap then
        itemNameMap = {}
        local items = ReplicatedStorage:FindFirstChild("Items")
        if items then
            for _, it in ipairs(items:GetChildren()) do itemNameMap[normName(it.Name)] = it.Name end
        end
    end
    return itemNameMap[normName(name)]
end

local function suffixMult(suf)
    if suf == "k" then return 1e3 elseif suf == "m" then return 1e6 elseif suf == "b" then return 1e9 end
    return 1
end

-- "50KG + 15 Shadow Essence + Kamish Dagger + \"Some\" Title"  ->  list of requirements
local function parseRecipe(recipe)
    local reqs = {}
    for token in (recipe .. "+"):gmatch("(.-)%+") do
        token = trimStr(token)
        if token ~= "" then
            local low = token:lower()
            local n, suf, tail = low:match("^([%d%.,]+)%s*([kmb]?)%s*g(e?m?s?)$")
            local n2, suf2 = low:match("^([%d%.,]+)%s*([kmb]?)%s*%$$")
            if token:find('"') or low:find("title") or low:find("race") then
                table.insert(reqs, { kind = "other", text = token })
            elseif n and (tail == "" or tail == "ems") then
                local amount = (tonumber((n:gsub(",", ""))) or 0) * suffixMult(suf)
                table.insert(reqs, { kind = "gems", need = amount, text = token })
            elseif n2 then
                local amount = (tonumber((n2:gsub(",", ""))) or 0) * suffixMult(suf2)
                table.insert(reqs, { kind = "beli", need = amount, text = token })
            else
                local count, name = token:match("^(%d+)%s*[xX]?%s*(.+)$")
                if not count then
                    local nm, c2 = token:match("^(.-)%s*[xX](%d+)$")
                    if nm and nm ~= "" then name, count = nm, c2 end
                end
                name = trimStr(name or token)
                count = tonumber(count) or 1
                local real = getItemName(name)
                if real then
                    table.insert(reqs, { kind = "item", item = real, need = count, text = token })
                else
                    table.insert(reqs, { kind = "other", text = token })
                end
            end
        end
    end
    return reqs
end

local function ownedCount(itemName)
    local total = 0
    local inv = LP:FindFirstChild("InvData")
    local v = inv and inv:FindFirstChild(itemName)
    if v and v:IsA("ValueBase") then total += tonumber(v.Value) or 0 end
    for _, c in ipairs({ getBackpack(), LP.Character }) do
        if c then
            for _, t in ipairs(c:GetChildren()) do
                if t:IsA("Tool") and t.Name == itemName then
                    total += tonumber(t:GetAttribute("Amount")) or 1
                end
            end
        end
    end
    return total
end

local function dataValue(name)
    local d = LP:FindFirstChild("Data")
    local v = d and d:FindFirstChild(name)
    return (v and v:IsA("ValueBase") and tonumber(v.Value)) or 0
end

local function fmtNum(n)
    if n >= 1e9 then return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then return string.format("%.2fM", n / 1e6)
    elseif n >= 1e4 then return string.format("%.1fK", n / 1e3) end
    return tostring(math.floor(n))
end

-- returns lines (text), canCraft
local function evaluateWeapon(w)
    local lines, can = {}, true
    for _, r in ipairs(w.reqs) do
        local have, ok
        if r.kind == "item" then
            have = ownedCount(r.item); ok = have >= r.need
            table.insert(lines, string.format("%s %d x %s  (have %s)", ok and "[OK]" or "[X]", r.need, r.item, fmtNum(have)))
        elseif r.kind == "gems" or r.kind == "beli" then
            have = dataValue(r.kind == "gems" and "Gems" or "Beli"); ok = have >= r.need
            table.insert(lines, string.format("%s %s %s  (have %s)", ok and "[OK]" or "[X]", fmtNum(r.need),
                r.kind == "gems" and "Gems" or "Beli", fmtNum(have)))
        else
            ok = true
            table.insert(lines, "[?] " .. r.text .. "  (not checked)")
        end
        if not ok then can = false end
    end
    if #w.reqs == 0 then table.insert(lines, "(recipe text not found on this NPC)") end
    return lines, can
end

local TYPE_WORDS = { melee = true, sword = true, special = true, accessory = true, ["devil fruit"] = true }

local function scanSellers()
    local npcs = Workspace:FindFirstChild("NPC")
    local root = npcs and npcs:FindFirstChild("Seller")
    local skill = ReplicatedStorage:FindFirstChild("Skill")
    local list = {}
    if not root then return list end
    local children = root:GetChildren()
    if #children == 0 then children = { root } end
    for _, npc in ipairs(children) do
        local cd = npc:FindFirstChildWhichIsA("ClickDetector", true)
        if cd then
            local texts = {}
            for _, d in ipairs(npc:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text ~= "" then table.insert(texts, d.Text) end
            end
            local name, recipe, wtype
            for _, t in ipairs(texts) do
                local low = trimStr(t):lower()
                if not name and ((skill and skill:FindFirstChild(trimStr(t))) or getItemName(t)) then name = trimStr(t) end
                if not recipe and (t:find("+", 1, true) or low:match("^[%d%.,]+%s*[kmb]?%s*[g%$]")) then recipe = t end
                if not wtype and TYPE_WORDS[low] then wtype = trimStr(t) end
            end
            name = name or npc.Name
            table.insert(list, {
                name = name, npc = npc, cd = cd, type = wtype or "?",
                recipeText = recipe or "", reqs = parseRecipe(recipe or ""),
                label = string.format("%s [%s]", name, wtype or "?"),
            })
        end
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end

local function refreshCraftList()
    local list = scanSellers()
    local labels = {}
    CRAFT.byLabel = {}
    for _, w in ipairs(list) do
        table.insert(labels, w.label)
        CRAFT.byLabel[w.label] = w
    end
    CRAFT.list = list
    local k = table.concat(labels, "|")
    if k ~= CRAFT.lastKey then
        CRAFT.lastKey = k
        if craftDropdown then
            pcall(function() craftDropdown:Refresh(#labels > 0 and labels or {"(no sellers loaded)"}) end)
        end
    end
end

local function updateCraftPara()
    if not craftPara then return end
    local w = CRAFT.selected and CRAFT.byLabel[CRAFT.selected]
    if not w then
        pcall(function()
            craftPara:SetTitle("Recipe")
            craftPara:SetContent("Pick a weapon on the left.")
        end)
        return
    end
    local lines, can = evaluateWeapon(w)
    pcall(function()
        craftPara:SetTitle(w.name .. (can and "  - ready to craft" or "  - missing items"))
        craftPara:SetContent(table.concat(lines, "\n"))
    end)
end

local function craftSelected()
    local w = CRAFT.selected and CRAFT.byLabel[CRAFT.selected]
    if not w then return false, "Pick a weapon first." end
    if not (w.cd and w.cd.Parent) then return false, "That seller NPC is not loaded here." end
    local _, can = evaluateWeapon(w)
    if not can then return false, "Missing required items." end
    local root = getMyRoot()
    if not root then return false, "Character not ready." end
    local part = w.cd.Parent
    local target = part:IsA("BasePart") and part.Position or w.npc:GetPivot().Position
    local back = root.CFrame
    root.CFrame = CFrame.new(target + Vector3.new(0, 3, 6))
    task.wait(0.6)
    pcall(fireclickdetector, w.cd) -- one click = the seller crafts it from your items
    task.wait(1)
    root.CFrame = back
    return true, "Clicked " .. w.name .. " seller."
end

-- ================= BUILD UI (MarvenRiz) =================
alive = true
local conns = {}
local skillDbg -- Auto Skills status paragraph
local islandPara -- nearest islands paragraph
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
    CONFIG.AutoBoss = false
    CONFIG.AutoRoll = false
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(clearAllESP)
    pcall(clearIslandESP)
    local sg = Window.MainFrame and Window.MainFrame:FindFirstAncestorOfClass("ScreenGui")
    if sg then pcall(function() sg:Destroy() end) end
end
do
    local sg = Window.MainFrame and Window.MainFrame:FindFirstAncestorOfClass("ScreenGui")
    if sg then table.insert(conns, sg.Destroying:Connect(unload)) end
end

local IN_RAID_MAP = game.PlaceId == CASTLE.RAID_PLACE -- raid map: only Auto Castle Raid, Setting, Config
local tabMain    = Window:CreateTab("Main", true, false)
local tabSetting = Window:CreateTab("Setting", false, false)
local tabOther   = Window:CreateTab("Other", false, false)
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

if not IN_RAID_MAP then
    local page = tabMain:CreatePage("Farm")
    local s1 = page:CreateSection("🌾 Auto Farm", "Left")
    local s2 = page:CreateSection("🎯 Select Mob", "Right")

    s1:Toggle({Title = "Auto Farm", Id = "FARM_ENABLED", Value = false, Callback = function(v)
        CONFIG.AutoFarm = v
        if not v then currentTarget = nil; bossLocked = false; farmEngaged = false end
    end})
    targetPara = s1:Paragraph({Title = "Target: (none)", Content = "Pick a mob from the list on the right."})
    farmStatusCallback = function(m) targetPara:SetContent(m) end

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
if not IN_RAID_MAP then
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

-- Page: Boss (ordered multi-selection + Auto Boss)
if not IN_RAID_MAP then
    local page = tabMain:CreatePage("Boss")
    local s1 = page:CreateSection("👑 Boss Selection", "Left")
    local s2 = page:CreateSection("📊 Status", "Right")

    s1:Dropdown({Title = "Select bosses", Options = {"Speed", "Doraemon", "Rune User1", "Rune User2", "Rune User3", "Key Man", "Beast Warriors", "Spaceship"}, Multi = true, Value = {}, Callback = function(selected)
        if type(selected) ~= "table" then return end
        local copy = {}
        for _, name in ipairs(selected) do
            if name == "Speed" or name == "Doraemon" or name == "Rune User1" or name == "Rune User2" or name == "Rune User3" or name == "Key Man" or name == "Beast Warriors" or name == "Spaceship" then table.insert(copy, name) end
        end
        CONFIG.BossNames = copy
        currentTarget = nil
        lastBossSelection = ""
        lastBossName = nil
    end})

    s1:Toggle({Title = "Auto Boss", Id = "BOSS_ENABLED", Value = false, Callback = function(v)
        CONFIG.AutoBoss = v
        currentTarget = nil
        if v then
            lastBossSelection = ""
            lastBossName = nil
        else
            bossLocked = false
            farmEngaged = false
        end
    end})
    local s3 = page:CreateSection("💀 VON JOESTAR", "Left")
    local vonPara
    s3:Toggle({Title = "Auto VON JOESTAR", Id = "VON_ENABLED", Value = false, Callback = function(v)
        VON.enabled = v
        STORE.skip["Von Soul"] = v or nil -- Auto Store must never put the Von Soul back
        -- clean reset every time it is switched (ON or OFF): no stale state survives
        VON.gen = VON.gen + 1
        VON.busy = false; VON.state = "idle"; VON.tries = 0; VON.cooldownUntil = 0; VON.farmJester = false
        bossLocked = false; currentTarget = nil; farmEngaged = false
        VON.status = v and "ON" or "OFF"
    end})
    vonPara = s3:Paragraph({Title = "VON JOESTAR status", Content = "OFF"})
    VON.setStatus = function(m) VON.status = m; pcall(function() vonPara:SetContent(m) end) end
    s2:Paragraph({Title = "Random Auto Boss", Content = "A random living boss from your selected list is chosen. After it is defeated, another living selected boss is chosen automatically. Bosses that are not currently spawned are skipped."})
end

-- Page: Auto ALL Raid (only in the raid map)
if IN_RAID_MAP then
    local page = tabMain:CreatePage("Auto ALL Raid")
    local s1 = page:CreateSection("⚔️ Auto ALL Raid", "Left")
    local s2 = page:CreateSection("📊 Status", "Right")
    s1:Toggle({Title = "Auto ALL Raid", Id = "CASTLE_ENABLED", Value = false, Callback = function(v)
        CASTLE.enabled = v
        if not v then setRaidFarm(false) end
        if v then STORE.skip["Castle Ticket"] = true end -- preserve tickets for Auto Replay
        castleStatus(v and "ON - Auto Start / Farm / Replay" or "OFF")
    end})
    s1:Toggle({Title = "Auto Replay (until out of tickets)", Id = "CASTLE_REPLAY", Value = true, Callback = function(v)
        CASTLE.autoReplay = v
    end})
    castlePara = s2:Paragraph({Title = "Auto ALL Raid", Content = "OFF"})
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
    sESP:Toggle({Title = "Island ESP", Id = "ISLAND_ESP", Value = false, Callback = function(v)
        CONFIG.IslandESP = v
        if v then buildIslandESP() else clearIslandESP() end
    end})
    sESP:ColorPicker({Title = "Island Color", Value = CONFIG.IslandColor, Callback = function(c)
        CONFIG.IslandColor = c
    end})

    -- Weapons (weapon lock: only MAX_WEAPONS can be selected)
    weaponDropdown = sWeapon:Dropdown({Title = "Weapons (select up to " .. MAX_WEAPONS .. ")", Options = listWeaponNames(), Multi = true, Value = {}, Callback = function(sel)
        if refreshingWeapons then return end
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

    -- Skills (cast while Auto Farm or Auto Boss has a live target)
    for _, name in ipairs({"Z", "X", "C", "V"}) do
        local sk = CONFIG.Skills[name]
        sSkill:Toggle({Title = "Auto Skills " .. name, Id = "SKILL" .. name, Value = false, Callback = function(v)
            sk.enabled = v
        end})
    end

    sSkill:Toggle({Title = "Auto Transform (Alucard F / Gohan Beast V)", Id = "AUTO_TRANSFORM", Value = false, Callback = function(v)
        CONFIG.AutoTransform = v
    end})

    skillDbg = sSkill:Paragraph({Title = "Skill status", Content = "Waiting: Auto Farm / Auto Boss is OFF"})

    -- Farm (attack position, applied to Auto Farm)
    sFarm:Dropdown({Title = "Attack Position", Options = {"Above", "Below", "Behind", "Front"}, Multi = false, Value = "Above", Callback = function(v)
        CONFIG.FarmPosition = v
    end})
    sFarm:Slider({Title = "Follow Distance (studs)", Min = 0, Max = 30, Value = 6, Callback = function(v)
        CONFIG.FarmDistance = v
    end})
end

-- ===================== OTHER =====================
do
    local page = tabOther:CreatePage("Island & Store")
    local sStore = page:CreateSection("📦 Auto Store", "Right")

    if not IN_RAID_MAP then
        local sIsland = page:CreateSection("🏝️ Island", "Left")
        islandPara = sIsland:Paragraph({Title = "Nearest islands", Content = "Turn on Island ESP to see them."})
        tpDropdown = sIsland:Dropdown({Title = "Teleport to Island", Options = getIslandNames(), Multi = false, Callback = function(v)
            if type(v) == "table" then v = v[1] end
            selectedIsland = v
        end})
        sIsland:Button({Title = "Teleport", Callback = function()
            local ok = teleportToIsland(selectedIsland)
            Library:Notify({
                Title = ok and "Teleported" or "Teleport failed",
                Description = ok and tostring(selectedIsland) or "Select an island first.",
                Duration = 3,
            })
        end})
    end

    sStore:Toggle({Title = "Auto Store Items", Id = "AUTO_STORE", Value = false, Callback = function(v)
        STORE.enabled = v
    end})
end

-- Page: Weapon Craft (main map only: the seller NPCs are not in the raid map)
if not IN_RAID_MAP then
    local page = tabOther:CreatePage("Weapon Craft")
    local sLeft  = page:CreateSection("🗡️ Weapons", "Left")
    local sRight = page:CreateSection("📜 Recipe", "Right")

    refreshCraftList()
    local firstOptions = {}
    for _, w in ipairs(CRAFT.list) do table.insert(firstOptions, w.label) end
    if #firstOptions == 0 then firstOptions = {"(no sellers loaded)"} end

    craftDropdown = sLeft:Dropdown({Title = "Weapon", Options = firstOptions, Multi = false, Callback = function(v)
        if type(v) == "table" then v = v[1] end
        CRAFT.selected = v
        updateCraftPara()
    end})
    sLeft:Button({Title = "Craft x1", Callback = function()
        local ok, msg = craftSelected()
        Library:Notify({Title = ok and "Craft" or "Cannot craft", Description = msg, Duration = 3})
        updateCraftPara()
    end})
    craftPara = sRight:Paragraph({Title = "Recipe", Content = "Pick a weapon on the left."})
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
        if not CONFIG.Enabled or not mobPara then continue end
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

-- ================= ISLAND ESP UPDATE =================
task.spawn(function()
    while alive and task.wait(0.25) do
        if not CONFIG.IslandESP then continue end
        if next(islandESP) == nil or not islandFolder or not islandFolder.Parent then
            pcall(buildIslandESP) -- retry until island data is available
        end
        local root = getMyRoot()
        if not root then continue end
        local here = LP.Character and LP.Character:GetAttribute("Island")
        local arr = {}
        for name, d in pairs(islandESP) do
            local dist = math.floor((d.pos - root.Position).Magnitude)
            local isHere = (name == here)
            d.label.Text = string.format("%s%s\n%dm", name, isHere and " (you are here)" or "", dist)
            d.label.TextColor3 = isHere and Color3.fromRGB(90, 255, 120) or CONFIG.IslandColor
            table.insert(arr, { name = name, dist = dist })
        end
        table.sort(arr, function(a, b) return a.dist < b.dist end)
        local lines = {}
        for i = 1, math.min(6, #arr) do
            lines[i] = string.format("%d. %s - %dm", i, arr[i].name, arr[i].dist)
        end
        if islandPara then
            pcall(function()
                islandPara:SetTitle("Current: " .. tostring(here or "?"))
                islandPara:SetContent(#lines > 0 and table.concat(lines, "\n") or "No islands found.")
            end)
        end
    end
end)

-- ================= WEAPON CRAFT REFRESH =================
task.spawn(function()
    while alive and task.wait(2) do
        if craftDropdown then
            pcall(refreshCraftList)
            pcall(updateCraftPara)
        end
    end
end)

-- ================= AUTO VON JOESTAR =================
-- State machine: idle -> (take 1 Von Soul, stand at NPC, click ONCE) -> pending -> fighting -> idle
-- Never re-summons while the boss is alive or a summon is pending; failed summons retry max 3 times.
local function vonStatus(m) if VON.setStatus and m ~= VON.lastMsg then VON.lastMsg = m; VON.setStatus(m) end end

local function vonSoulTool()
    local bp, ch = getBackpack(), LP.Character
    return (bp and bp:FindFirstChild("Von Soul")) or (ch and ch:FindFirstChild("Von Soul"))
end
local function soulAmount(t) return t and (tonumber(t:GetAttribute("Amount")) or 1) or 0 end

local function ensureVonSoul()
    if vonSoulTool() then return true end
    local data = LP:FindFirstChild("InvData")
    local stored = data and data:FindFirstChild("Von Soul")
    if not stored or (tonumber(stored.Value) or 0) < 1 then return false end
    local remote = getInvRemote()
    if not remote then return false end
    invokeTimeout(remote, 2, "Remove", "Von Soul", 1) -- exactly 1
    local t = tick()
    repeat task.wait(0.1) until vonSoulTool() or tick() - t > 2
    return vonSoulTool() ~= nil
end

local function findSummonNpc()
    local npcs = Workspace:FindFirstChild("NPC")
    if not npcs then return nil end
    local function clickable(o) return o:FindFirstChildWhichIsA("ClickDetector", true) or o:FindFirstChildWhichIsA("ProximityPrompt", true) end
    local exact = npcs:FindFirstChild("SUMMON VON JOESTAR")
    if exact and clickable(exact) then return exact end
    for _, npc in ipairs(npcs:GetChildren()) do
        if npc.Name:upper():find("VON", 1, true) and clickable(npc) then return npc end
        for _, d in ipairs(npc:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("TextBox")) and d.Text:upper():find("SUMMON VON JOESTAR", 1, true) and clickable(npc) then
                return npc
            end
        end
    end
end

-- Event-based detection: a boss that spawns and dies in under a second can never be missed by polling,
-- so every spawn / death is counted the moment Roblox reports it.
local function vonWatch(model)
    if VON.watched[model] then return end
    VON.watched[model] = true
    VON.spawnSeq = VON.spawnSeq + 1
    local h = model:FindFirstChildOfClass("Humanoid")
    if h then h.Died:Connect(function() VON.deathSeq = VON.deathSeq + 1 end) end
    model.AncestryChanged:Connect(function(_, parent)
        if not parent then VON.deathSeq = VON.deathSeq + 1 end
    end)
end
local function vonConsider(o)
    local m = o:IsA("Humanoid") and o.Parent or (o:IsA("Model") and o) or nil
    if not (m and m:IsA("Model")) then return end
    local n = m.Name:lower()
    if n:find("joestar", 1, true) and not n:find("summon", 1, true) then vonWatch(m) end
end
table.insert(conns, Workspace.DescendantAdded:Connect(function(o)
    if VON.enabled then pcall(vonConsider, o) end
end))

local function vonHasSoul()
    if vonSoulTool() then return true end
    local data = LP:FindFirstChild("InvData")
    local stored = data and data:FindFirstChild("Von Soul")
    return stored ~= nil and (tonumber(stored.Value) or 0) >= 1
end

local function vonStep(gen)
    local function cur() return VON.enabled and VON.gen == gen end
    local boss = VON.find()
    if boss then
        VON.farmJester = false
        VON.state = "fighting"; VON.tries = 0
        vonStatus("Fighting " .. boss.Name)
        return
    end
    if VON.state == "fighting" then -- boss is gone (killed)
        VON.state = "idle"; VON.cooldownUntil = tick() + 0.3
        vonStatus("Boss defeated - next round")
        return
    end
    if VON.state == "pending" then
        if VON.spawnSeq > VON.spawnAtClick then -- it spawned and is already dead (killed in <1s): go on at once
            VON.state = "idle"; VON.cooldownUntil = tick() + 0.2
            vonStatus("Boss killed instantly - next round")
            return
        end
        local left = 15 - (tick() - VON.pendingAt) -- the boss spawns right after the click: do not wait long
        if left > 0 then vonStatus(string.format("Summoned - waiting for the boss (%ds)", left)); return end
        VON.state = "idle"; VON.cooldownUntil = tick() + 0.5
        vonStatus("Boss did not appear - retrying")
        return
    end
    -- no Von Soul left: farm Jester until one drops (then stop at once and summon)
    if not vonHasSoul() then
        VON.farmJester = true
        vonStatus("No Von Soul - farming Jester")
        return
    end
    VON.farmJester = false
    if tick() < (VON.cooldownUntil or 0) then return end
    if VON.tries >= 3 then
        vonStatus("Summon failed 3 times - pausing 10s")
        VON.tries = 0; VON.cooldownUntil = tick() + 10
        return
    end
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if not getMyRoot() or not hum or hum.Health <= 0 then return end

    VON.busy = true -- pauses Auto Farm / Auto Boss so nothing pulls the character away from the NPC
    local ok, err = pcall(function()
        if not vonSoulTool() then
            vonStatus("Taking 1 Von Soul...")
            if not ensureVonSoul() then
                vonStatus("No Von Soul (Backpack or storage)"); VON.cooldownUntil = tick() + 3; return
            end
        end
        local npc = findSummonNpc()
        if not npc then vonStatus('NPC "SUMMON VON JOESTAR" not found'); VON.cooldownUntil = tick() + 3; return end
        local npcPos = npc:GetPivot().Position
        local spot = CFrame.new(npcPos + Vector3.new(0, 3, 6))
        local function hold()
            local r = getMyRoot()
            if not r then return false end
            if (r.Position - npcPos).Magnitude > 12 then
                r.CFrame = spot -- snapped back by the server/another script: put it back
            end
            r.AssemblyLinearVelocity = Vector3.zero
            return (r.Position - npcPos).Magnitude <= 12
        end

        -- 1) get to the NPC and stay there stably (0.5s in range) BEFORE clicking
        vonStatus("Going to the summon NPC...")
        local stable, t0 = 0, tick()
        while cur() and tick() - t0 < 4 and stable < 3 do
            if hold() then stable += 1 else stable = 0 end
            task.wait(0.1)
        end
        if not cur() then return end
        if stable < 3 then
            VON.tries += 1; VON.cooldownUntil = tick() + 1
            vonStatus("Could not stay at the NPC - retry " .. VON.tries .. "/3")
            return
        end

        -- 2) ONE click, then keep the position while checking that the Von Soul was consumed
        local before = soulAmount(vonSoulTool())
        VON.spawnAtClick = VON.spawnSeq
        local cd = npc:FindFirstChildWhichIsA("ClickDetector", true)
        local pp = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
        if cd then pcall(fireclickdetector, cd) elseif pp then pcall(fireproximityprompt, pp) end
        vonStatus("Clicked the NPC - checking...")
        local consumed, t1 = false, tick()
        while cur() and tick() - t1 < 3 do
            hold()
            if soulAmount(vonSoulTool()) < before or VON.spawnSeq > VON.spawnAtClick or VON.find() then consumed = true; break end
            task.wait(0.1)
        end
        if not cur() then return end
        if consumed then
            VON.state = "pending"; VON.pendingAt = tick(); VON.tries = 0
        else
            VON.tries += 1; VON.cooldownUntil = tick() + 1.5
            vonStatus("Summon not registered - retry " .. VON.tries .. "/3")
        end
    end)
    if VON.gen == gen then VON.busy = false end
    if not ok then vonStatus("Error: " .. tostring(err)); VON.cooldownUntil = tick() + 2 end
end

function VON.run(gen)
    VON.beat = tick()
    while alive and VON.enabled and VON.gen == gen do
        task.wait(0.15)
        VON.beat = tick()
        local ok, err = pcall(vonStep, gen)
        if not ok then
            if VON.gen == gen then VON.busy = false end
            vonStatus("Error: " .. tostring(err)); task.wait(1)
        end
    end
end

-- supervisor: starts one run per toggle (also when a saved config switches it on at load) and restarts a
-- run that stopped responding for 15s (e.g. an abandoned yield), so it can never stay frozen.
task.spawn(function()
    while alive do
        task.wait(0.3)
        if VON.enabled then
            if VON.runGen ~= VON.gen then
                VON.runGen = VON.gen
                task.spawn(VON.run, VON.gen)
            elseif tick() - VON.beat > 15 then
                VON.gen = VON.gen + 1; VON.busy = false; VON.state = "idle"; VON.tries = 0
                bossLocked = false; currentTarget = nil
            end
        end
    end
end)

-- ================= AUTO STORE LOOP =================
task.spawn(function()
    while alive do
        task.wait(STORE.interval)
        if STORE.enabled then pcall(storeOnce) end
    end
end)

-- ================= ISLAND TELEPORT LIST REFRESH =================
task.spawn(function()
    while alive and task.wait(3) do
        if not tpDropdown then continue end
        local names = getIslandNames()
        local changed = #names ~= #lastIslandNames
        if not changed then
            for i = 1, #names do
                if names[i] ~= lastIslandNames[i] then changed = true; break end
            end
        end
        if changed then
            lastIslandNames = names
            pcall(function() tpDropdown:Refresh(names) end)
        end
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
            -- keep only selected weapons that still exist in the new list
            local exists = {}
            for _, n in ipairs(names) do exists[n] = true end
            local saved = {}
            for _, n in ipairs(CONFIG.WeaponNames) do
                if exists[n] then table.insert(saved, n) end
            end
            CONFIG.WeaponNames = saved
            refreshingWeapons = true
            pcall(function() weaponDropdown:Refresh(names) end)
            pcall(weaponDropdown.Set, saved) -- re-apply the selection (UI only)
            refreshingWeapons = false
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
    -- aim the skill at the current farm target (the packet's CFrame is the cast origin/direction)
    local aim = hrp.CFrame
    local tp = currentTarget and currentTarget.Parent and getMobPart(currentTarget)
    if tp then
        local v = tp.Position - hrp.Position
        if v.Magnitude > 0.5 then
            local up = (math.abs(v.Unit.Y) > 0.99) and Vector3.new(0, 0, 1) or Vector3.new(0, 1, 0)
            aim = CFrame.lookAt(hrp.Position, tp.Position, up)
        end
    end
    local packet = { "Skill", key, aim }
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

-- The server uses the FIRST Tool in the Character for skills. To make `target` first, move
-- every tool that sits before it out to the Backpack and back in ONE batch (they end up after
-- the others). The old one-tool-at-a-time rotation cycled through every other weapon when 3-4
-- were held, which made weapons swap back and forth.
local function rotateTo(target, char, bp)
    for _ = 1, 3 do
        local order = {}
        for _, c in ipairs(char:GetChildren()) do
            if c:IsA("Tool") then table.insert(order, c) end
        end
        local idx = table.find(order, target)
        if not idx then return false end
        if idx == 1 then return true end
        local before = {}
        for i = 1, idx - 1 do table.insert(before, order[i]) end
        for _, t in ipairs(before) do t.Parent = bp end
        task.wait(0.15)
        for _, t in ipairs(before) do t.Parent = char end
        task.wait(0.1)
        if firstHeldTool() == target then return true end
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
        repeat
            task.wait()
            if tool:GetAttribute(key) == true or char:GetAttribute("Skilling") == true then
                result = "OK"
                return
            end
        until tick() - t0 > 0.5
    end)
    skillLock = false
    return result
end

-- ---------- Auto Transform (one cast per weapon, never spammed) ----------
-- match = lowercase substring of the Tool name. stateAttrs = optional Character/Tool attribute names
-- that are true while transformed (fill in after running the transform scanner).
local TRANSFORMS = {
    { match = "alucard", key = "F", stateAttrs = { "Alucard" } },
    { match = "gohan",   key = "V", stateAttrs = {} },
    { match = "von joestar", key = "F", stateAttrs = { "TUSK" } }, -- verified: Character attr TUSK false -> true
}
local transformDone = setmetatable({}, { __mode = "k" }) -- Tool -> true (cast OK this life)
local transformTries = setmetatable({}, { __mode = "k" }) -- Tool -> failed attempts (max 3)

-- Known weapons first (table above). Unknown weapons are auto-detected with the pattern verified on
-- Alucard: the Character has a boolean attribute named exactly like the Tool (false = not transformed).
-- Its transform key is F when the weapon has an F skill (Skill folder), otherwise it is not guessed.
local autoInfoCache = {}
local function transformInfo(tool, char)
    local n = tool.Name:lower()
    for _, t in ipairs(TRANSFORMS) do
        if n:find(t.match, 1, true) then return t end
    end
    if char and typeof(char:GetAttribute(tool.Name)) == "boolean" then
        local c = autoInfoCache[tool.Name]
        if not c then
            local f = SkillFolder and SkillFolder:FindFirstChild(tool.Name)
            local key = (not f or f:FindFirstChild("F")) and "F" or false
            c = { key = key, stateAttrs = {} }
            autoInfoCache[tool.Name] = c
        end
        if c.key then return c end
    end
end

-- Verified (Alucard scan): Character attribute "<WeaponName>" is false before the transform and
-- true after it. Other weapons are assumed to follow the same pattern (attribute = Tool name).
-- Returns isTransformed, attributeFound
local function transformState(tool, info, char)
    local names = { tool.Name }
    for _, a in ipairs(info.stateAttrs) do table.insert(names, a) end
    local found = false
    for _, a in ipairs(names) do
        local v = char:GetAttribute(a)
        if v == nil then v = tool:GetAttribute(a) end
        if v ~= nil then
            found = true
            if v == true then return true, true end
        end
    end
    if found then return false, true end
    return transformDone[tool] == true, false -- no state attribute: fall back to "cast once"
end

local rrName, rrUsed = nil, {} -- round-robin weapon turn state
task.spawn(function()
    while alive do
        task.wait()
        if not isHackRunning() then
            dbg((CONFIG.AutoFarm or CONFIG.AutoBoss) and "Waiting: no target (respawning / not found)" or "Waiting: Auto Farm / Auto Boss is OFF")
            continue
        end

        local anyEnabled = false
        for _, n in ipairs(SKILL_ORDER) do
            if CONFIG.Skills[n].enabled then anyEnabled = true; break end
        end
        if not anyEnabled and not CONFIG.AutoTransform then dbg("Waiting: no Auto Skills toggle is ON"); continue end

        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local bp = getBackpack()
        if not (char and hum and hrp and bp) or hum.Health <= 0 then
            table.clear(transformDone); table.clear(transformTries)
            dbg("Waiting: character not ready"); continue
        end

        -- only cast once we are standing on the target (otherwise the skill whiffs)
        local tp = currentTarget and currentTarget.Parent and getMobPart(currentTarget)
        if not tp or (tp.Position - hrp.Position).Magnitude > (tonumber(CONFIG.FarmDistance) or 6) + 15 then
            dbg("Waiting: not on the target yet")
            continue
        end

        local tools = heldSkillTools()
        if #tools == 0 then dbg("Waiting: no weapon is held"); continue end

        if CONFIG.AutoTransform then
            local did = false
            for _, t in ipairs(tools) do
                local info = transformInfo(t, char)
                local on, hasAttr = false, false
                if info then on, hasAttr = transformState(t, info, char) end
                if on then transformTries[t] = nil end
                if info and not on
                    and (transformTries[t] or 0) < 3 and t:GetAttribute(info.key) ~= true then
                    if char:GetAttribute("Skilling") == true then did = true; break end
                    skillWindowUntil = tick() + 0.6
                    dbg("Transforming: " .. t.Name .. " [" .. info.key .. "]")
                    local res = castSkill(t, info.key, char, bp)
                    lastCast = string.format("%s [%s] -> %s (transform)", t.Name, info.key, res)
                    if hasAttr then
                        -- wait for the game to flip the state attribute (max 1.5s) instead of re-casting
                        local t0 = tick()
                        repeat task.wait(0.1) until transformState(t, info, char) or tick() - t0 > 1.5
                        if not transformState(t, info, char) then transformTries[t] = (transformTries[t] or 0) + 1 end
                    elseif res == "OK" then
                        transformDone[t] = true
                    else
                        transformTries[t] = (transformTries[t] or 0) + 1
                    end
                    did = true
                    break
                end
            end
            if did then task.wait(0.3); continue end
        end
        if not anyEnabled then dbg("Waiting: no Auto Skills toggle is ON"); continue end

        local byName, names = {}, {}
        for _, t in ipairs(tools) do
            if not byName[t.Name] then byName[t.Name] = t; table.insert(names, t.Name) end
        end
        -- fixed turn order = the order the weapons were selected in the dropdown (up to 4)
        local order = {}
        for _, n in ipairs(CONFIG.WeaponNames) do
            if byName[n] then table.insert(order, n) end
        end
        if #order == 0 then order = names end

        local now = tick()
        local function readyKey(tool, usedSet)
            local tinfo = CONFIG.AutoTransform and transformInfo(tool, char)
            for _, k in ipairs(SKILL_ORDER) do
                if CONFIG.Skills[k].enabled and not (tinfo and tinfo.key == k) -- transform key is never spammed
                    and toolHasKey(tool, k) and tool:GetAttribute(k) ~= true
                    and not (usedSet and usedSet[k]) then
                    local id = tool.Name .. "|" .. k
                    if not lastTry[id] or now - lastTry[id] >= 0.6 then return k end
                end
            end
        end

        -- round-robin: a weapon's "turn" casts each ready skill once; then the turn passes to the
        -- next weapon in order, so weapons 3 and 4 always get their turn (no ping-pong between two)
        if not byName[rrName] then rrName, rrUsed = order[1], {} end
        local pickTool = byName[rrName]
        local pickKey = readyKey(pickTool, rrUsed)
        if not pickKey then
            local start = table.find(order, rrName) or 0
            for i = 1, #order do
                local name = order[((start + i - 1) % #order) + 1]
                local t = byName[name]
                local k = t and readyKey(t, nil)
                if k then
                    rrName, rrUsed = name, {}
                    pickTool, pickKey = t, k
                    break
                end
            end
        end
        if not pickKey then dbg("Waiting: all enabled skills are on cooldown (" .. #order .. " weapons held)"); continue end

        -- a skill is ready: pause basic attacks so it can start (the server rejects skills
        -- while the character is still "Skilling")
        skillWindowUntil = tick() + 0.4
        if char:GetAttribute("Skilling") == true then dbg("Waiting: a skill is playing"); continue end

        lastTry[pickTool.Name .. "|" .. pickKey] = now
        rrUsed[pickKey] = true
        dbg(string.format("Casting: %s [%s] (%d weapons held)", pickTool.Name, pickKey, #order))
        local res = castSkill(pickTool, pickKey, char, bp)
        lastCast = string.format("%s [%s] -> %s", pickTool.Name, pickKey, res)
    end
end)

-- ================= ANTI AFK =================
-- Roblox kicks after 20 min without input (LocalPlayer.Idled): disable the default handlers, then fake input.
do
    if getconnections then
        pcall(function()
            for _, c in ipairs(getconnections(LP.Idled)) do
                if c.Disable then c:Disable() end
            end
        end)
    end
    local VU = game:GetService("VirtualUser")
    table.insert(conns, LP.Idled:Connect(function()
        pcall(function()
            VU:CaptureController()
            VU:ClickButton2(Vector2.new(0, 0))
        end)
    end))
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
