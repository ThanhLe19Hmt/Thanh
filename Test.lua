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
    local root = getMobsRoot()
    if not root then return nil end
    local myRoot = getMyRoot()
    if not myRoot then return nil end
    local best, bestDist = nil, math.huge
    -- search every depth under Workspace.Mobs (not only Mobs/<Island>/<Mob>)
    for _, mob in ipairs(root:GetDescendants()) do
        if (targetName == "*" or mob.Name == targetName) and mob:IsA("Model") and isMobModel(mob) then
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

local function autoFarmStep()
    farmEngaged = false
    if not CONFIG.AutoFarm and not CONFIG.AutoBoss then return end

    local targetName = CONFIG.TargetMobName
    local selectionChanged = false
    if CONFIG.AutoBoss then
        if #CONFIG.BossNames == 0 then
            farmStatus("No boss selected.")
            currentTarget = nil
            return
        end
        local selectionKey = getBossSelectionKey()
        if selectionKey ~= lastBossSelection then
            lastBossSelection = selectionKey
            currentTarget = nil
            lastFarmTargetName = nil
            lastBossName = nil
            selectionChanged = true
        end
    end

    local char = LP.Character
    local myRoot = getMyRoot()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not myRoot or not hum or hum.Health <= 0 then return end

    if CONFIG.AutoBoss then
        if currentTarget then
            local h = currentTarget:FindFirstChildOfClass("Humanoid")
            if not currentTarget.Parent or not h or h.Health <= 0 then
                currentTarget = nil
            end
        end
        if not currentTarget then
            targetName, currentTarget = pickRandomAliveBoss()
        else
            targetName = lastBossName
        end
        if not currentTarget then
            farmStatus("No selected boss is alive - waiting.")
            return
        end
    else
        if targetName ~= lastFarmTargetName then
            currentTarget = nil
            lastFarmTargetName = targetName
        end
        if currentTarget then
            local h = currentTarget:FindFirstChildOfClass("Humanoid")
            if not currentTarget.Parent or not h or h.Health <= 0 then
                currentTarget = nil
            end
        end
        if not currentTarget and targetName then currentTarget = findTarget(targetName) end
    end

    if not targetName or not currentTarget then
        farmStatus('No alive "' .. tostring(targetName) .. '" found - waiting. Skills paused.')
        return
    end

    local mobPart = getMobPart(currentTarget)
    if not mobPart then currentTarget = nil; return end

    farmEngaged = true
    syncWeapons()
    farmStatus((CONFIG.AutoBoss and "Random Boss: " or "Farming: ") .. tostring(targetName))
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
    return (CONFIG.AutoFarm or CONFIG.AutoBoss) and farmEngaged
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
        local ok, res = pcall(function() return remote:InvokeServer("Add", nm, amount) end)
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
-- ================= AUTO CASTLE RAID =================
local CASTLE = {
    enabled = false,
    MAIN_PLACE = 117676969731858,
    RAID_PLACE = 135193584835072,
    HUB_FILE = "Sakura_Hub.lua", -- save THIS script in the executor workspace under this name
}
local castlePara
local lastCastleOpen, queuedHub = 0, false
local lastStartTry, startAttempt = 0, 0

local function castleStatus(msg)
    if castlePara then pcall(function() castlePara:SetContent(msg) end) end
end

-- the teleport kills this script: queue it again so it also runs in the next map.
-- queue_on_teleport needs a STRING of code (the old call executed the hub immediately
-- and queued its return value), and no local file is required.
local HUB_URL = "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Test"
local function queueHubForRaid()
    if queuedHub then return end
    local q = queue_on_teleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)
    if not q then
        castleStatus("Your executor has no queue_on_teleport - the script cannot auto-load in the next map")
        return
    end
    local code = 'if not game:IsLoaded() then game.Loaded:Wait() end\n'
        .. 'getgenv().SakuraCastleResume = true\n'
        .. 'loadstring(game:HttpGet("' .. HUB_URL .. '"))()'
    if pcall(q, code) then queuedHub = true end
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
        queueHubForRaid()
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

    -- no gate yet: open one (clicking while a gate exists does not cost a ticket, but never spam)
    if tick() - lastCastleOpen < 15 then return end
    if not ensureCastleTicket() then castleStatus("No Castle Ticket (Backpack or storage)"); return end
    local npcs = Workspace:FindFirstChild("NPC")
    local npc = npcs and npcs:FindFirstChild("TowerRaidSummon") -- overhead text "INF Castle" (NOT CastleShop)
    local cd = npc and npc:FindFirstChildOfClass("ClickDetector")
    if not cd then castleStatus("INF Castle NPC not found"); return end
    lastCastleOpen = tick()
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
    if on and CONFIG.AutoBoss then return end
    if on then CONFIG.TargetMobName = "*" -- "*" = nearest alive mob of any name
    elseif CONFIG.TargetMobName == "*" then CONFIG.TargetMobName = nil end
    if CONFIG.AutoFarm ~= on then
        local el = Window.ConfigElements["Auto Farm"]
        if el then pcall(el.Set, on) else CONFIG.AutoFarm = on end
    end
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
    queueHubForRaid() -- so the script also reloads when the raid sends us back
    local raid = Workspace:FindFirstChild("Raid")
    local started = raid and raid:GetAttribute("Started") == true
    local ended = raid and raid:GetAttribute("End") == true
    if ended then
        setRaidFarm(false)
        castleStatus("Raid ended")
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
        if CASTLE.enabled then
            local inRaidMap = game.PlaceId == CASTLE.RAID_PLACE or Workspace:FindFirstChild("Raid") ~= nil
            if inRaidMap then
                local ok, err = pcall(raidStep)
                if not ok then castleStatus("Raid error: " .. tostring(err)) end
            elseif CONFIG.AutoFarm or CONFIG.AutoBoss then
                castleStatus("Turn off Auto Farm / Auto Boss first")
            else
                local ok, err = pcall(castleStep)
                if not ok then castleStatus("Castle error: " .. tostring(err)) end
            end
        end
    end
end)

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

do
    local page = tabMain:CreatePage("Farm")
    local s1 = page:CreateSection("🌾 Auto Farm", "Left")
    local s2 = page:CreateSection("🎯 Select Mob", "Right")

    s1:Toggle({Title = "Auto Farm", Id = "FARM_ENABLED", Value = false, Callback = function(v)
        if v and CONFIG.AutoBoss then
            CONFIG.AutoFarm = false
            Library:Notify({Title = "Cannot enable Auto Farm", Description = "Turn off Auto Boss first.", Duration = 3})
            task.defer(function()
                local el = Window.ConfigElements["Auto Farm"]
                if el then pcall(el.Set, false) end -- dot call: Set takes the value directly
            end)
            return
        end
        CONFIG.AutoFarm = v
        if not v then currentTarget = nil; farmEngaged = false end
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

-- Page: Boss (ordered multi-selection + Auto Boss)
do
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
        if v and CONFIG.AutoFarm then
            CONFIG.AutoBoss = false
            Library:Notify({Title = "Cannot enable Auto Boss", Description = "Turn off Auto Farm first.", Duration = 3})
            task.defer(function()
                local el = Window.ConfigElements["Auto Boss"]
                if el then pcall(el.Set, false) end
            end)
            return
        end
        CONFIG.AutoBoss = v
        currentTarget = nil
        if v then
            lastBossSelection = ""
            lastBossName = nil
        else
            farmEngaged = false
        end
    end})
    s2:Paragraph({Title = "Random Auto Boss", Content = "A random living boss from your selected list is chosen. After it is defeated, another living selected boss is chosen automatically. Bosses that are not currently spawned are skipped."})
end

-- Page: Raid (Castle)
do
    local page = tabMain:CreatePage("Raid")
    local s1 = page:CreateSection("🏰 INF Castle", "Left")
    local s2 = page:CreateSection("📊 Status", "Right")
    s1:Toggle({Title = "Auto Castle Raid", Id = "CASTLE_ENABLED", Value = false, Callback = function(v)
        CASTLE.enabled = v
        castleStatus(v and ("ON - PlaceId " .. tostring(game.PlaceId)) or "OFF")
        -- never let Auto Store put the ticket back into storage
        if v then STORE.skip["Castle Ticket"] = true end
    end})
    castlePara = s2:Paragraph({Title = "Auto Castle Raid", Content = "OFF"})
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
    local sIsland = page:CreateSection("🏝️ Island", "Left")
    local sStore  = page:CreateSection("📦 Auto Store", "Right")

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

    sStore:Toggle({Title = "Auto Store Items", Id = "AUTO_STORE", Value = false, Callback = function(v)
        STORE.enabled = v
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

-- Move the current first tool out and back in (different frames, so the server sees it)
local function rotateTo(target, char, bp)
    for _ = 1, 5 do
        local f = firstHeldTool()
        if not f or f == target then return true end
        f.Parent = bp
        task.wait(0.2)
        f.Parent = char
        task.wait(0.2)
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
        if not anyEnabled then dbg("Waiting: no Auto Skills toggle is ON"); continue end

        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local bp = getBackpack()
        if not (char and hum and hrp and bp) or hum.Health <= 0 then dbg("Waiting: character not ready"); continue end

        -- only cast once we are standing on the target (otherwise the skill whiffs)
        local tp = currentTarget and currentTarget.Parent and getMobPart(currentTarget)
        if not tp or (tp.Position - hrp.Position).Magnitude > (tonumber(CONFIG.FarmDistance) or 6) + 15 then
            dbg("Waiting: not on the target yet")
            continue
        end

        local tools = heldSkillTools()
        if #tools == 0 then dbg("Waiting: no weapon is held"); continue end

        -- find a ready skill (not on cooldown)
        local pickTool, pickKey
        local now = tick()
        for _, tool in ipairs(tools) do
            for _, n in ipairs(SKILL_ORDER) do
                if CONFIG.Skills[n].enabled and toolHasKey(tool, n) and tool:GetAttribute(n) ~= true then
                    local id = tool.Name .. "|" .. n
                    if not lastTry[id] or now - lastTry[id] >= 0.6 then
                        pickTool, pickKey = tool, n
                        break
                    end
                end
            end
            if pickTool then break end
        end

        if not pickTool then dbg("Waiting: all enabled skills are on cooldown"); continue end

        -- a skill is ready: pause basic attacks so it can start (the server rejects skills
        -- while the character is still "Skilling")
        skillWindowUntil = tick() + 0.4
        if char:GetAttribute("Skilling") == true then dbg("Waiting: a skill is playing"); continue end

        lastTry[pickTool.Name .. "|" .. pickKey] = now
        dbg(string.format("Casting: %s [%s]", pickTool.Name, pickKey))
        local res = castSkill(pickTool, pickKey, char, bp)
        lastCast = string.format("%s [%s] -> %s", pickTool.Name, pickKey, res)
    end
end)

task.delay(2.5, function()
    if getgenv and getgenv().SakuraCastleResume then
        getgenv().SakuraCastleResume = nil
        local el = Window.ConfigElements["Auto Castle Raid"]
        if el then pcall(el.Set, true) end
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
