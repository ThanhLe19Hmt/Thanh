-- ============================================================
-- Sea 2 Hub — PlaceId 132854526011923
-- Full Script: Menu + Potion + Setting + Auto Farm Level (Stable)
-- ============================================================

local SEA2_PLACE_ID = 132854526011923

if game.PlaceId ~= SEA2_PLACE_ID then
    warn("[Sea 2] ❌ Sai map! PlaceId: " .. tostring(game.PlaceId))
    return
end

print("[Sea 2] ▶️ Loading...")

-- ============================================================
-- Services
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- Helpers
-- ============================================================
local function FormatNumber(n)
    n = tonumber(n) or 0
    if n < 0 then return tostring(n) end
    if n < 1000 then return tostring(math.floor(n)) end
    if n < 1000000 then
        local k = math.floor(n / 100) / 10
        if k == math.floor(k) then return tostring(math.floor(k)) .. "K" end
        return string.format("%.1fK", k)
    end
    if n < 1000000000 then
        local m = math.floor(n / 100000) / 10
        if m == math.floor(m) then return tostring(math.floor(m)) .. "M" end
        return string.format("%.1fM", m)
    end
    local b = math.floor(n / 100000000) / 10
    if b == math.floor(b) then return tostring(math.floor(b)) .. "B" end
    return string.format("%.1fB", b)
end

local function SafeWait(parent, name, timeout)
    local ok, result = pcall(function() return parent:WaitForChild(name, timeout or 3) end)
    if ok and result then return result end
    return parent:FindFirstChild(name)
end

local function SafeRequire(module)
    if not module then return nil end
    local ok, result = pcall(function() return require(module) end)
    if ok and result then return result end
    return nil
end

local CachedInventory = {}
local LastInventory = 0

local function GetInventory()
    if tick() - LastInventory < 0.2 then return CachedInventory end
    LastInventory = tick()
    local ok, inv = pcall(function()
        return HttpService:JSONDecode(LocalPlayer:GetAttribute("Inventory") or "{}")
    end)
    CachedInventory = ok and inv or {}
    return CachedInventory
end

local function GetItemAmount(itemName)
    local inv = GetInventory()
    return (inv[itemName] and inv[itemName].amount) or 0
end

local function Teleport(pos)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = pos
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

-- ============================================================
-- _G defaults
-- ============================================================
_G.AutoSkillZ = false
_G.AutoSkillX = false
_G.AutoSkillC = false
_G.AutoSkillV = false
_G.AutoSkillF = false
_G.Auto_Haki = false
_G.MainWeapon = "Melee"
_G.Select_EquipWeapon = {}
_G.Select_Method = "Upper"
_G.Distance_Farm = 5
_G.VFXDisabled = false
_G.CanAutoSkill = false
_G.Auto_Farm_Level = false
_G.Auto_Use_Potion = false
_G.Select_Potion = {}

local TypeTool = {"Melee", "Sword", "Special", "DevilFruit"}

-- ============================================================
-- Modules
-- ============================================================
local ModulesFolder = SafeWait(ReplicatedStorage, "Modules", 3)
local Blacklist = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("BlacklistItemTrade"))
local Quest_Module = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("QuestModule"))
local Npc_Quest = SafeWait(workspace, "NpcQuest", 3)

local X2List = {}
if Blacklist then
    for itemName in pairs(Blacklist) do
        if itemName:find("X2") then table.insert(X2List, itemName) end
    end
    table.sort(X2List)
end
print("[Sea 2] X2 Potions found: " .. #X2List)
for _, name in ipairs(X2List) do print(" - " .. name) end

local POTION_TIME_MAP = {
    ["X2 EXP 15min."]     = "x2ExpTime",
    ["X2 Diamond 15min."] = "x2DiamondTime",
    ["X2 Lucky 15min."]   = "x2LuckTime",
    ["X2 Rebirth 15min."] = "x2RebirthTime",
    ["X2 Item 15min."]    = "x2ItemTime",
}

local Quest_List = {}
if Quest_Module and Npc_Quest then
    pcall(function()
        table.sort(Quest_Module, function(a, b) return a.Level < b.Level end)
        for i, data in ipairs(Quest_Module) do
            local NPC = Npc_Quest:WaitForChild("NPC_Quest" .. i, 2)
            if NPC then
                Quest_List[i] = {
                    Level = data.Level,
                    Monster = NPC:GetAttribute("Name"),
                    Quest = NPC
                }
            end
        end
    end)
end

local function GetQuest_Level(myLevel)
    local quest
    for _, v in ipairs(Quest_List) do
        if myLevel >= v.Level then quest = v else break end
    end
    return quest
end

local function GetQuestFrame()
    local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
    local main = hud and hud:FindFirstChild("Main")
    return main and main:FindFirstChild("Frame_Quest")
end

-- ============================================================
-- Action remote
-- ============================================================
local function GetAction()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("Action")
end

-- ============================================================
-- Core functions
-- ============================================================
function _G.ClearDashBodyMovers(hrp, duration)
    if not hrp or not hrp.Parent then return end
    duration = duration or 0.8
    task.spawn(function()
        local startTime = tick()
        while tick() - startTime < duration do
            task.wait(0.03)
            if not hrp or not hrp.Parent then break end
            for _, child in ipairs(hrp:GetChildren()) do
                if child:IsA("BodyVelocity") then
                    if child.Name == "Fly" or child.Name == "BodyVelocity"
                        or child.Name == "DashVelocity" or child.Name == "AntiDashBV" then
                        pcall(function() child:Destroy() end)
                    end
                elseif child:IsA("BodyGyro") then
                    if child.Name == "BodyGyro" or child.Name == "DashGyro" then
                        pcall(function() child:Destroy() end)
                    end
                elseif child:IsA("AlignPosition") then
                    if child.Name == "AlignPosition" or child.Name == "DashAlign" then
                        pcall(function() child:Destroy() end)
                    end
                end
            end
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

local function AutoSkill()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local Skills = {}
        if _G.AutoSkillZ then table.insert(Skills, "z") end
        if _G.AutoSkillX then table.insert(Skills, "x") end
        if _G.AutoSkillC then table.insert(Skills, "c") end
        if _G.AutoSkillV then table.insert(Skills, "v") end
        if _G.AutoSkillF then table.insert(Skills, "f") end
        if #Skills == 0 then return end
        local skill = Skills[math.random(#Skills)]
        local action = GetAction()
        if not action then return end
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then action:FireServer(tool.Name, skill) end
        end
        if _G.ClearDashBodyMovers then _G.ClearDashBodyMovers(hrp, 0.8) end
    end)
end

local function EquipWeapon()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") and v:GetAttribute("Type") ~= _G.MainWeapon then
                v.Parent = LocalPlayer.Backpack
            end
        end
        for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if v:IsA("Tool") and v:GetAttribute("Type") == _G.MainWeapon then
                char.Humanoid:EquipTool(v)
                break
            end
        end
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") and v:GetAttribute("Type") ~= _G.MainWeapon
                and not table.find(_G.Select_EquipWeapon or {}, v:GetAttribute("Type")) then
                v.Parent = LocalPlayer.Backpack
            end
        end
        for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if v:IsA("Tool") and v:GetAttribute("Type") ~= _G.MainWeapon
                and table.find(_G.Select_EquipWeapon or {}, v:GetAttribute("Type")) then
                v.Parent = char
            end
        end
    end)
end

local function Attack()
    local char = LocalPlayer.Character
    if not char then return end
    local action = GetAction()
    if not action then return end
    local fired = false
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then
            local ok, err = pcall(function()
                action:FireServer(v.Name, "hit")
            end)
            if not ok then
                warn("[Attack] Fire fail tool " .. v.Name .. ": " .. tostring(err))
            end
            fired = true
        end
    end
    if not fired then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
                if v:IsA("Tool") and v:GetAttribute("Type") == _G.MainWeapon then
                    pcall(function() hum:EquipTool(v) end)
                    break
                end
            end
        end
    end
end

-- ============================================================
-- VFX
-- ============================================================
local VFX_CONNECTIONS = {}
local VFX_KILL_CLASSES = {
    ["ParticleEmitter"] = true, ["Beam"] = true, ["Trail"] = true,
    ["Sparkles"] = true, ["Fire"] = true, ["Smoke"] = true,
    ["Highlight"] = true, ["PointLight"] = true,
    ["SpotLight"] = true, ["SurfaceLight"] = true,
}

local function TryKillVFX(obj)
    if not obj or not obj.Parent then return end
    if not VFX_KILL_CLASSES[obj.ClassName] then return end
    pcall(function()
        if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail")
            or obj:IsA("Sparkles") or obj:IsA("Fire") or obj:IsA("Smoke")
            or obj:IsA("Highlight") or obj:IsA("PointLight")
            or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            if obj.Enabled then obj.Enabled = false end
        end
    end)
end

local function KillVFXIn(container)
    if not container then return end
    pcall(function()
        for _, v in ipairs(container:GetDescendants()) do TryKillVFX(v) end
    end)
end

local function HookContainer(container)
    if not container then return end
    local conn = container.DescendantAdded:Connect(function(obj)
        if _G.VFXDisabled then TryKillVFX(obj) end
    end)
    table.insert(VFX_CONNECTIONS, conn)
end

local function NoVFX(state)
    _G.VFXDisabled = state
    for _, conn in ipairs(VFX_CONNECTIONS) do
        pcall(function() conn:Disconnect() end)
    end
    VFX_CONNECTIONS = {}
    if not state then return end
    KillVFXIn(workspace)
    local cam = workspace.CurrentCamera
    if cam then KillVFXIn(cam) end
    local char = LocalPlayer.Character
    if char then KillVFXIn(char) end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then KillVFXIn(pg) end
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            if hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
            if hum.JumpPower < 50 then hum.JumpPower = 50 end
        end
        for _, folderName in ipairs({"Stun", "StunS"}) do
            local folder = char:FindFirstChild(folderName)
            if folder and #folder:GetChildren() > 0 then
                pcall(function() folder:ClearAllChildren() end)
            end
        end
    end
    HookContainer(workspace)
    if cam then HookContainer(cam) end
    if char then HookContainer(char) end
    if pg then HookContainer(pg) end
    local respawnConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
        if not _G.VFXDisabled then return end
        task.wait(0.5)
        KillVFXIn(newChar)
        HookContainer(newChar)
    end)
    table.insert(VFX_CONNECTIONS, respawnConn)
end

-- ============================================================
-- FARM HELPERS
-- ============================================================
local FLY_SPEED = 250
local ARRIVE_DISTANCE = 15
local PARK_HEIGHT = 25
local ANTI_LAUNCH_Y_THRESHOLD = 500
local LastKnownGoodPos = nil
local DeadMobTracker = setmetatable({}, {__mode = "k"})

local FlyActive = false
local FlyAlign = nil
local FlyAttach = nil
local ParkY = nil

local function DestroyAllMovers(hrp)
    if not hrp then return end
    for _, c in ipairs(hrp:GetChildren()) do
        if c:IsA("AlignPosition") or c:IsA("AlignOrientation")
            or c:IsA("BodyPosition") or c:IsA("BodyVelocity")
            or c:IsA("BodyGyro") or c:IsA("BodyForce") or c:IsA("BodyThrust") then
            pcall(function() c:Destroy() end)
        end
    end
end

local function ResetHumanoidAnim(hum)
    if not hum then return end
    hum.PlatformStand = false
end

local function StopFly()
    FlyActive = false
    if FlyAlign and FlyAlign.Parent then FlyAlign:Destroy() end
    if FlyAttach and FlyAttach.Parent then FlyAttach:Destroy() end
    FlyAlign = nil
    FlyAttach = nil
end

local function StopHold()
    -- Không dùng Align hold, để trống cho tương thích
end

-- ============================================================
-- Anchor: HRP.Anchored + giữ equip/skill hoạt động
-- ============================================================
local function AnchorAt(cf)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    StopFly()

    for _, c in ipairs(hrp:GetChildren()) do
        if c:IsA("BodyPosition") or c:IsA("BodyVelocity") or c:IsA("BodyGyro")
            or c:IsA("BodyForce") or c:IsA("BodyThrust") or c:IsA("AlignPosition") then
            pcall(function() c:Destroy() end)
        end
    end

    local hum = char:FindFirstChild("Humanoid")
    if hum then
        hum.PlatformStand = false
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        end)
    end

    hrp.Anchored = true
    hrp.CFrame = cf
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

local function ReleaseAnchor()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        if hrp.Anchored then hrp.Anchored = false end
    end
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then
        hum.PlatformStand = false
        if hum.WalkSpeed == 0 then hum.WalkSpeed = 16 end
        if hum.JumpPower == 0 then hum.JumpPower = 50 end
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end)
    end
end

local function Unanchor()
    ReleaseAnchor()
end

-- ============================================================
-- Fly tới vị trí
-- ============================================================
local function StartFlyTo(cf)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    ReleaseAnchor()
    StopFly()
    DestroyAllMovers(hrp)
    FlyActive = true

    FlyAttach = Instance.new("Attachment")
    FlyAttach.Name = "Sea2FlyAttach"
    FlyAttach.Parent = hrp

    FlyAlign = Instance.new("AlignPosition")
    FlyAlign.Name = "Sea2FlyAlign"
    FlyAlign.Attachment0 = FlyAttach
    FlyAlign.Mode = Enum.PositionAlignmentMode.OneAttachment
    FlyAlign.Position = cf.Position
    FlyAlign.MaxForce = 100000
    FlyAlign.MaxVelocity = FLY_SPEED
    FlyAlign.Responsiveness = 50
    FlyAlign.Parent = hrp

    local ao = Instance.new("AlignOrientation")
    ao.Name = "Sea2FlyOrient"
    ao.Attachment0 = FlyAttach
    ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
    ao.CFrame = cf
    ao.MaxTorque = 100000
    ao.Responsiveness = 50
    ao.Parent = hrp
end

local function EnableNoclip(hrp)
    if not hrp then return end
    local char = LocalPlayer.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                p.CanCollide = false
            end
        end
    end
end

local function GetFarmPosition(targetHrp)
    if not targetHrp then return nil end
    local dist = _G.Distance_Farm or 5
    local method = _G.Select_Method or "Upper"
    local tCF = targetHrp.CFrame
    if method == "Behind" then
        return tCF * CFrame.new(0, 0, dist)
    elseif method == "Front" then
        return tCF * CFrame.new(0, 0, -dist) * CFrame.Angles(0, math.rad(180), 0)
    elseif method == "Below" then
        return tCF * CFrame.new(0, -dist, 0) * CFrame.Angles(math.rad(90), 0, 0)
    else
        return tCF * CFrame.new(0, dist, 0) * CFrame.Angles(math.rad(-90), 0, 0)
    end
end

-- ============================================================
-- Anti-launch watchdog
-- ============================================================
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            if not _G.Auto_Farm_Level then return end
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            if hrp.Position.Y < ANTI_LAUNCH_Y_THRESHOLD then
                LastKnownGoodPos = hrp.Position
                return
            end
            warn("[Sea2] ⚠️ Bị launch! Y = " .. math.floor(hrp.Position.Y))
            DestroyAllMovers(hrp)
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            if LastKnownGoodPos then
                hrp.CFrame = CFrame.new(LastKnownGoodPos)
            end
            FlyActive = false
        end)
    end
end)

-- ============================================================
-- Load UI Library
-- ============================================================
local okLib, Library = pcall(function()
    return loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/UI_Test.lua"
    ))()
end)

if not okLib or not Library then
    warn("[Sea 2] ❌ Không load được UI Library")
    return
end

local MySaveManager = Library.SaveManager

local Window = Library:CreateWindow({
    Title = "MarvenRiz Hub — Sea 2",
    Subtitle = "Sea 2 — Under Development",
    Size = UDim2.fromOffset(500, 370),
    AccentColor = Color3.fromRGB(50, 150, 255),
    SideBarWidth = 120,
    Logo = "rbxassetid://73243738744141",
    LogoSize = 32,
    SphereText = false,
    SphereImage = "rbxassetid://73243738744141",
    SphereIconSize = 38,
    Map = "Sea2",
    BackgroundImage = "rbxassetid://104569104995749"
})

function _G.SeaNotify(title, desc, duration)
    pcall(function()
        if Library and Library.Notify then
            Library:Notify({
                Title = title or "",
                Description = desc or "",
                Duration = duration or 4
            })
        end
    end)
end

-- ============================================================
-- Tab Farm
-- ============================================================
local FarmTab = Window:CreateTab("Farm", false, false)
local FarmPage = FarmTab:CreatePage("Auto Farm")
local LevelFarmCard = FarmPage:CreateSection("🌾 Auto Farm Level", "Left")
local LevelInfoCard = FarmPage:CreateSection("📊 Status", "Right")

local LevelStatusPara = LevelInfoCard:Paragraph({
    Title = "Status: Idle",
    Content = "Bật toggle để bắt đầu"
})

LevelFarmCard:Toggle({
    Title = "Auto Level Farm",
    Value = false,
    Callback = function(v)
        _G.Auto_Farm_Level = v
        if v then
            pcall(function()
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                    "fire", nil, "Quest", "Cancel"
                )
            end)
            _G.SeaNotify("▶️ Auto Farm Level ON", "Đang tìm quest...", 3)
        else
            StopFly()
            StopHold()
            Unanchor()
            ParkY = nil
            _G.CanAutoSkill = false
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then ResetHumanoidAnim(hum) end
            _G.SeaNotify("⏹️ Auto Farm Level OFF", "", 3)
        end
    end
})

-- ============================================================
-- Tab Potion
-- ============================================================
local OtherTab = Window:CreateTab("Other", false, false)
local PotionPage = OtherTab:CreatePage("Auto X2 Potion")
local PotionSelectCard = PotionPage:CreateSection("🧪 Select Potion", "Left")
local PotionActionCard = PotionPage:CreateSection("⚙️ Actions", "Right")
local PotionInfoCard = PotionPage:CreateSection("📊 Info", "Right")

local PotionInfoPara = PotionInfoCard:Paragraph({
    Title = "🍦 X2 Potions",
    Content = "Select potion to view"
})

PotionSelectCard:Dropdown({
    Title = "🧪 Select X2 Potion",
    Options = X2List,
    Multi = true,
    Callback = function(v)
        local list, seen = {}, {}
        local function addItem(item)
            if type(item) == "string" and item ~= "" and not seen[item] then
                seen[item] = true
                table.insert(list, item)
            end
        end
        if type(v) == "table" then
            for _, item in ipairs(v) do addItem(item) end
            for key, val in pairs(v) do if val == true then addItem(key) end end
        elseif type(v) == "string" and v ~= "" then
            addItem(v)
        end
        _G.Select_Potion = list
        print("[Potion] Đã chọn " .. #list .. " potion:")
        for _, p in ipairs(list) do print(" - " .. p) end
    end
})

PotionActionCard:Toggle({
    Title = "🤖 Auto Use Potion",
    Value = false,
    Callback = function(v)
        _G.Auto_Use_Potion = v
        print("[Potion] Auto:", v and "ON" or "OFF")
        _G.SeaNotify(v and "▶️ Auto Potion ON" or "⏹️ Auto Potion OFF",
            v and "Sẽ tự uống khi hết" or "Đã tắt", 3)
    end
})

task.spawn(function()
    local lastUseTime = {}
    local lastInfoUpdate = 0
    while task.wait(0.3) do
        pcall(function()
            local now = tick()
            if now - lastInfoUpdate >= 0.5 then
                lastInfoUpdate = now
                local Inv = GetInventory()
                local lines = {}
                for _, potionName in ipairs(X2List) do
                    local have = (Inv[potionName] and Inv[potionName].amount) or 0
                    local attrName = POTION_TIME_MAP[potionName]
                    local timeLeft = 0
                    if attrName then
                        timeLeft = tonumber(LocalPlayer:GetAttribute(attrName)) or 0
                    end
                    local statusText = ""
                    if timeLeft > 0 then
                        local m = math.floor(timeLeft / 60)
                        local s = timeLeft % 60
                        statusText = string.format(" [%02d:%02d]", m, s)
                    else
                        statusText = " [Hết]"
                    end
                    local icon = have > 0 and "✅" or "❌"
                    local selectedMark = ""
                    if _G.Select_Potion and table.find(_G.Select_Potion, potionName) then
                        selectedMark = " ⭐"
                    end
                    table.insert(lines, string.format("%s %s: %d%s%s",
                        icon, potionName, have, statusText, selectedMark))
                end
                if PotionInfoPara then
                    PotionInfoPara:SetTitle("🍦 X2 Potions (⭐ = selected)")
                    PotionInfoPara:SetContent(table.concat(lines, "\n"))
                end
            end

            if not _G.Auto_Use_Potion then return end
            if type(_G.Select_Potion) ~= "table" or #_G.Select_Potion == 0 then return end

            local remote = ReplicatedStorage:FindFirstChild("Remotes")
            remote = remote and remote:FindFirstChild("Inventory")
            if not remote then return end

            local Inv = GetInventory()
            for _, potionName in ipairs(_G.Select_Potion) do
                local attrName = POTION_TIME_MAP[potionName]
                if attrName then
                    local timeLeft = tonumber(LocalPlayer:GetAttribute(attrName)) or 0
                    if timeLeft <= 0 then
                        local last = lastUseTime[potionName] or 0
                        if tick() - last >= 2 then
                            local have = (Inv[potionName] and Inv[potionName].amount) or 0
                            if have > 0 then
                                lastUseTime[potionName] = tick()
                                pcall(function() remote:FireServer(potionName) end)
                                print("[Potion] 🍦 Uống: " .. potionName .. " (còn " .. have .. ")")
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- ============================================================
-- Tab Setting
-- ============================================================
local SettingTab = Window:CreateTab("Setting", false, false)
local SettingPage = SettingTab:CreatePage("Main Settings")
local WeaponCard = SettingPage:CreateSection("🗡️ Select Weapon", "Left")
local SkillCard = SettingPage:CreateSection("⚔️ Auto Skills", "Left")
local MethodCard = SettingPage:CreateSection("🎯 Method Farm", "Right")
local HakiCard = SettingPage:CreateSection("👁️ Haki", "Right")
local VFXCard = SettingPage:CreateSection("✨ VFX", "Right")

WeaponCard:Dropdown({
    Title = "Main Weapon (Attack)",
    Options = TypeTool, Multi = false, Value = "Melee",
    Callback = function(v) _G.MainWeapon = v end
})

WeaponCard:Dropdown({
    Title = "Select Support Weapon",
    Options = TypeTool, Multi = true,
    Callback = function(v) _G.Select_EquipWeapon = v end
})

SkillCard:Toggle({Title = "Auto Skill Z", Id = "S2_SKILLZ", Value = false, Callback = function(v) _G.AutoSkillZ = v end})
SkillCard:Toggle({Title = "Auto Skill X", Id = "S2_SKILLX", Value = false, Callback = function(v) _G.AutoSkillX = v end})
SkillCard:Toggle({Title = "Auto Skill C", Id = "S2_SKILLC", Value = false, Callback = function(v) _G.AutoSkillC = v end})
SkillCard:Toggle({Title = "Auto Skill V", Id = "S2_SKILLV", Value = false, Callback = function(v) _G.AutoSkillV = v end})
SkillCard:Toggle({Title = "Auto Skill F", Id = "S2_SKILLF", Value = false, Callback = function(v) _G.AutoSkillF = v end})

HakiCard:Toggle({
    Title = "Auto Enable Haki",
    Id = "S2_AENHAKI",
    Value = false,
    Callback = function(v) _G.Auto_Haki = v end
})

MethodCard:Dropdown({
    Title = "Select Farm Method",
    Options = {"Behind", "Below", "Upper", "Front"},
    Id = "S2_METHODFARM", Multi = false, Value = "Upper",
    Callback = function(v) _G.Select_Method = v end
})

MethodCard:Slider({
    Title = "Farm Distance / Height",
    Min = 0, Max = 30, Value = 5,
    Callback = function(v) _G.Distance_Farm = v end
})

VFXCard:Toggle({
    Title = "Disable VFX",
    Id = "S2_NOVFX",
    Value = false,
    Callback = function(v) NoVFX(v) end
})

-- ============================================================
-- Auto Haki loop
-- ============================================================
task.spawn(function()
    while task.wait() do
        pcall(function()
            if not _G.Auto_Haki then return end
            local char = LocalPlayer.Character
            if not char then return end
            if char:FindFirstChild("HakiFolder") then return end
            local action = GetAction()
            if action then action:FireServer("Misc", "buso") end
        end)
    end
end)

-- ============================================================
-- AUTO FARM LEVEL LOOP
-- ============================================================
task.spawn(function()
    local QuestClaimCooldown = 0
    local currentTarget = nil

    while task.wait(0.05) do
        xpcall(function()
            if not _G.Auto_Farm_Level then
                QuestClaimCooldown = 0
                currentTarget = nil
                ParkY = nil
                return
            end

            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp or not hum or hum.Health <= 0 then
                StopFly(); Unanchor()
                _G.CanAutoSkill = false
                return
            end

            if hrp.Position.Y > ANTI_LAUNCH_Y_THRESHOLD then
                StopFly(); Unanchor()
                _G.CanAutoSkill = false
                return
            end

            EnableNoclip(hrp)

            local level = tonumber(LocalPlayer:GetAttribute("Level")) or 1
            local quest = GetQuest_Level(level)
            if not quest then
                LevelStatusPara:SetTitle("⏳ Không có quest")
                LevelStatusPara:SetContent("Level: " .. level)
                return
            end

            local questFrame = GetQuestFrame()
            local questText = questFrame and questFrame.Title and questFrame.Title.Text or ""
            local frameVisible = questFrame and questFrame.Visible or false

            -- ============ BƯỚC 1: NHẬN QUEST ============
            if not frameVisible or not string.find(questText, quest.Monster) then
                _G.CanAutoSkill = false
                currentTarget = nil
                ParkY = nil

                if QuestClaimCooldown > 0 and tick() < QuestClaimCooldown then
                    LevelStatusPara:SetTitle("⏳ Chờ nhận quest...")
                    LevelStatusPara:SetContent(string.format("Còn %.1fs", QuestClaimCooldown - tick()))
                    return
                end

                local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
                if npc then
                    local npcCF = npc.CFrame * CFrame.new(0, 5, 0)
                    local distToNpc = (hrp.Position - npcCF.Position).Magnitude
                    if distToNpc > ARRIVE_DISTANCE then
                        StartFlyTo(npcCF)
                        LevelStatusPara:SetTitle("✈️ Bay tới NPC")
                        LevelStatusPara:SetContent(string.format("NPC: %s | Dist: %.0f",
                            quest.Monster, distToNpc))
                        return
                    end
                    StopFly()
                    Unanchor()
                    hrp.CFrame = npcCF
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    if hum then ResetHumanoidAnim(hum) end
                    local prompt = npc:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then
                        pcall(function() fireproximityprompt(prompt, prompt.HoldDuration + 0.1) end)
                        task.wait(0.3)
                        pcall(function() fireproximityprompt(prompt, prompt.HoldDuration + 0.1) end)
                        QuestClaimCooldown = tick() + 3
                    end
                end
                return
            end

            QuestClaimCooldown = 0

            -- ============ BƯỚC 2: TÌM MOB ============
            local mobFolder = workspace:FindFirstChild("Mob") or workspace:FindFirstChild("Mobs")
            if not mobFolder then return end

            local now = tick()
            local target = nil
            local minDist = math.huge
            for _, mob in ipairs(mobFolder:GetChildren()) do
                if mob:IsA("Model") and mob.Name == quest.Monster
                    and mob:FindFirstChild("Humanoid")
                    and mob:FindFirstChild("HumanoidRootPart") then
                    local deathAt = DeadMobTracker[mob]
                    local isRecentlyDead = deathAt and (now - deathAt < 3)
                    if mob.Humanoid.Health > 0 and not isRecentlyDead then
                        local d = (hrp.Position - mob.HumanoidRootPart.Position).Magnitude
                        if d < minDist then
                            minDist = d
                            target = mob
                        end
                    elseif mob.Humanoid.Health <= 0 and not deathAt then
                        DeadMobTracker[mob] = now
                    end
                end
            end

            -- ============ KHÔNG CÓ MOB → PARK ============
            if not target then
                currentTarget = nil
                _G.CanAutoSkill = false

                if not ParkY then
                    ParkY = hrp.Position.Y + PARK_HEIGHT
                end

                local parkCF = CFrame.new(hrp.Position.X, ParkY, hrp.Position.Z)
                    * CFrame.Angles(0, select(2, hrp.CFrame:ToEulerAnglesYXZ()), 0)

                if (hrp.Position - parkCF.Position).Magnitude > 3 then
                    StartFlyTo(parkCF)
                    LevelStatusPara:SetTitle("✈️ Bay lên park")
                else
                    AnchorAt(parkCF)
                    LevelStatusPara:SetTitle("⏳ Đợi mob: " .. quest.Monster)
                end

                LevelStatusPara:SetContent(string.format("Park Y: %.0f", ParkY))
                return
            end

            ParkY = nil

            -- ============ BƯỚC 3: XỬ LÝ TARGET ============
            target.Humanoid.WalkSpeed = 0
            target.Humanoid.JumpPower = 0

            local farmCF = GetFarmPosition(target.HumanoidRootPart)
            if not farmCF then return end

            if currentTarget ~= target then
                currentTarget = target
            end

            if target.Humanoid.Health <= 0 then
                DeadMobTracker[target] = tick()
                currentTarget = nil
                Unanchor()
                _G.CanAutoSkill = false
                return
            end

            local distToFarm = (hrp.Position - farmCF.Position).Magnitude

            -- Chưa tới gần → bay tới
            if distToFarm > 6 then
                StartFlyTo(farmCF)
                _G.CanAutoSkill = false
                LevelStatusPara:SetTitle("✈️ Bay tới mob")
                LevelStatusPara:SetContent(string.format("Mob: %s | Dist: %.0f",
                    target.Name, distToFarm))
                return
            end

            -- Đã ở gần → anchor
            AnchorAt(farmCF)
            _G.CanAutoSkill = true

            -- Chờ 1 frame Humanoid sync
            task.wait(0.03)

            EquipWeapon()
            if _G.AutoSkillZ or _G.AutoSkillX or _G.AutoSkillC or _G.AutoSkillV or _G.AutoSkillF then
                AutoSkill()
            end
            Attack()

            LevelStatusPara:SetTitle("⚔️ Đánh: " .. target.Name)
            LevelStatusPara:SetContent(string.format(
                "HP: %d/%d | Dist: %.0f | Lv: %d",
                math.floor(target.Humanoid.Health),
                math.floor(target.Humanoid.MaxHealth),
                distToFarm,
                level
            ))
        end, function(err)
            warn("[Sea2 Farm Level] Error:", err)
        end)
    end
end)

-- ============================================================
-- SaveManager config tab
-- ============================================================
if MySaveManager then
    pcall(function() MySaveManager:SetFolder("MarvenRiz_Sea2") end)
    local okBuild, errBuild = pcall(function()
        local ConfigTab = Window:CreateTab("Config", false, false)
        MySaveManager:BuildConfigTab(ConfigTab)
    end)
    if not okBuild then
        warn("[Sea 2] BuildConfigTab failed:", errBuild)
        pcall(function() Window:CreateTab("Config", false, false) end)
    end
    task.spawn(function()
        task.wait(1.5)
        pcall(function() MySaveManager:LoadAutoloadConfig() end)
    end)
else
    warn("[Sea 2] MySaveManager nil — skip Config tab")
end

-- ============================================================
-- Anti-AFK
-- ============================================================
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

print("[Sea 2] ✅ Load successful!")
