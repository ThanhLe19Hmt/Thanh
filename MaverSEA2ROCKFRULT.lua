-- ============================================================
--  MarvenRiz Hub — Sea2 Full (Final)
--  Rock Fruit • MapId: 132854526011923
-- ============================================================

if game.PlaceId ~= 132854526011923 then
    warn(("[MarvenRiz] Sai map: %d — script chỉ chạy trên Sea2"):format(game.PlaceId))
    return
end

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer and game.Players.LocalPlayer.Character

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local RunService        = game:GetService("RunService")
local VirtualUser       = game:GetService("VirtualUser")
local LocalPlayer       = Players.LocalPlayer

-- ============================================================
--  LOAD LIB (Config ổn định)
-- ============================================================
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Sea2UI.lua"
))()

local START_ACCENT     = Color3.fromRGB(120, 80, 255)
local START_BACKGROUND = Color3.fromRGB(18, 18, 20)
local currentAccent     = START_ACCENT
local currentBackground = START_BACKGROUND

local function closeEnough(a, b, eps)
    eps = eps or 0.02
    return math.abs(a.R - b.R) < eps and math.abs(a.G - b.G) < eps and math.abs(a.B - b.B) < eps
end

local function findScreenGui()
    for _, root in ipairs({game:GetService("CoreGui"), LocalPlayer.PlayerGui}) do
        for _, gui in ipairs(root:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name:find("MarvenRiz_UI_") then return gui end
        end
    end
    return nil
end

local function hueDistance(c1, c2)
    local h1, s1, v1 = c1:ToHSV()
    local h2, s2, v2 = c2:ToHSV()
    local dh = math.abs(h1 - h2)
    if dh > 0.5 then dh = 1 - dh end
    return dh + math.abs(s1 - s2) * 0.3 + math.abs(v1 - v2) * 0.3
end

local function ApplyAccent(newColor)
    local oldColor = currentAccent
    currentAccent = newColor
    local gui = findScreenGui()
    if not gui then return end
    for _, desc in ipairs(gui:GetDescendants()) do
        if desc:IsA("GuiObject") and desc.BackgroundColor3 and closeEnough(desc.BackgroundColor3, oldColor) then desc.BackgroundColor3 = newColor end
        if (desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox")) and closeEnough(desc.TextColor3, oldColor) then desc.TextColor3 = newColor end
        if desc:IsA("UIStroke") and closeEnough(desc.Color, oldColor) then desc.Color = newColor end
        if desc:IsA("UIGradient") then
            local newKeys, changed = {}, false
            for _, kp in ipairs(desc.Color.Keypoints) do
                if closeEnough(kp.Value, oldColor) then
                    table.insert(newKeys, ColorSequenceKeypoint.new(kp.Time, newColor))
                    changed = true
                else table.insert(newKeys, kp) end
            end
            if changed then desc.Color = ColorSequence.new(newKeys) end
        end
    end
end

local function ApplyBackground(newColor)
    local oldColor = currentBackground
    currentBackground = newColor
    local gui = findScreenGui()
    if not gui then return end
    for _, desc in ipairs(gui:GetDescendants()) do
        if desc:IsA("GuiObject") and desc.BackgroundColor3 and closeEnough(desc.BackgroundColor3, oldColor) then desc.BackgroundColor3 = newColor end
        if desc:IsA("UIStroke") and closeEnough(desc.Color, oldColor) then desc.Color = newColor end
    end
end

local function ApplyMenuScale(scale)
    local gui = findScreenGui()
    if not gui then return end
    for _, d in ipairs(gui:GetDescendants()) do
        if d:IsA("UIScale") and d.Parent and d.Parent.Name == "Frame" and d.Parent.Parent == gui then
            d.Scale = scale
            return
        end
    end
end

-- ============================================================
--  LOAD MODULES
-- ============================================================
local Npc_Quest = workspace:WaitForChild("NpcQuest", 5)
local Itemdrops = workspace:WaitForChild("Itemdrops", 5)

local ModulesFolder = ReplicatedStorage:WaitForChild("Modules", 5)
local Quest_Module  = ModulesFolder and ModulesFolder:FindFirstChild("QuestModule")
local ItemList      = ModulesFolder and ModulesFolder:FindFirstChild("Itemlist")
local PointItemM    = ModulesFolder and ModulesFolder:FindFirstChild("GaranteeRandomItem")

local Quest_ModuleData, ItemListData, PointItemMData
pcall(function() Quest_ModuleData = require(Quest_Module) end)
pcall(function() ItemListData = require(ItemList) end)
pcall(function() PointItemMData = require(PointItemM) end)

-- ============================================================
--  BUILD DATA
-- ============================================================
local TypeTool = {"Melee", "Sword", "Special", "DevilFruit"}
local RandomChestValue = {"x5", "x10", "x15"}

local Quest_List = {}
local ItemDrop = {}
local ItemToMob = {}
local ItemAll = {}
local Poitem = {}
local CachedInventory = {}
local LastInventory = 0
local MethodFarm = CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-90), 0, 0)

local SpawnList = {
    ["Thief"]      = "Bacon Thief",
    ["Piccolo"]    = "Piccolo",
    ["Duck"]       = "Duck Monster",
    ["Devil Boat"] = "DevilBoat",
    ["Kraken"]     = "Kraken",
}

-- ============================================================
--  GLOBAL STATE
-- ============================================================
_G.MainWeapon = "Melee"
_G.WeaponList = {}
_G.Select_EquipWeapon = {}
_G.Select_Method = "Upper"
_G.Distance_Farm = 5
_G.AutoSkillZ = false
_G.AutoSkillX = false
_G.AutoSkillC = false
_G.AutoSkillV = false
_G.AutoSkillF = false
_G.Auto_Haki = false
_G.Auto_Farm_Level = false
_G.Select_Material = {}
_G.Auto_Farm_Material = false
_G.Auto_BaconThief = false
_G.Select_Random = "x5"
_G.Auto_RandomChest = false
_G.Select_Guarantee = nil
_G.Auto_Guarantee = false
_G.VFXDisabled = false

-- State
_G._lastMaterialSpawn     = nil
_G._lastMaterialSpawnTime = 0
_G._lastThiefSpawn        = nil
_G._lastThiefSpawnTime    = 0
_G._lastNPCTPTime         = 0
_G._lastNPCTarget         = nil
_G._questPromptTime       = 0
_G._farmLevelWaitPos      = nil
_G._npcBayStart           = nil

-- ============================================================
--  BUILD QUEST LIST
-- ============================================================
if Quest_ModuleData and Npc_Quest then
    pcall(function()
        table.sort(Quest_ModuleData, function(a, b) return a.Level < b.Level end)
        for i, data in ipairs(Quest_ModuleData) do
            local NPC = Npc_Quest:WaitForChild("NPC_Quest" .. i, 3)
            if NPC then
                Quest_List[i] = {Level = data.Level, Monster = NPC:GetAttribute("Name"), Quest = NPC}
            end
        end
    end)
end

-- ============================================================
--  BUILD ITEM DROP
-- ============================================================
if Itemdrops then
    pcall(function()
        for _, Mob in ipairs(Itemdrops:GetChildren()) do
            local ScrollingFrame = Mob:FindFirstChild("ScrollingFrame", true)
            if ScrollingFrame then
                for _, v in ipairs(ScrollingFrame:GetDescendants()) do
                    if v:IsA("TextLabel") and v.Text and v.Text ~= "" then
                        if not v.Text:find("%%") then
                            ItemDrop[v.Text] = ItemDrop[v.Text] or {}
                            table.insert(ItemDrop[v.Text], Mob.Name)
                            ItemToMob[v.Text] = Mob.Name
                        end
                    end
                end
            end
        end
    end)
end

if ItemListData then
    for ItemName in pairs(ItemToMob) do
        local Data = ItemListData[ItemName]
        if not (Data and Data.Type == "Accessory") then
            table.insert(ItemAll, ItemName)
        end
    end
    table.sort(ItemAll)
end

-- ============================================================
--  BUILD GUARANTEE LIST
-- ============================================================
if PointItemMData then
    for Item, Price in pairs(PointItemMData) do
        table.insert(Poitem, {Name = Item, Price = Price})
    end
    table.sort(Poitem, function(a, b) return a.Price < b.Price end)
    for i, Data in ipairs(Poitem) do
        Poitem[i] = Data.Name .. " / " .. Data.Price .. " Point"
    end
end

-- ============================================================
--  HELPERS
-- ============================================================
local function GetQuest_Level(My_level)
    My_level = tonumber(My_level) or 0
    local Quest
    for _, v in ipairs(Quest_List) do
        local Level = tonumber(v.Level) or 0
        if My_level >= Level then Quest = v else break end
    end
    return Quest
end

local function GetQuestFrame()
    return LocalPlayer.PlayerGui.HUD.Main.Frame_Quest
end

local function GetInventory()
    if tick() - LastInventory < 0.2 then return CachedInventory end
    LastInventory = tick()
    local Success, Inv = pcall(function()
        return HttpService:JSONDecode(LocalPlayer:GetAttribute("Inventory") or "{}")
    end)
    CachedInventory = Success and Inv or {}
    return CachedInventory
end

local function GetItemAmount(ItemName)
    local Inv = GetInventory()
    return (Inv[ItemName] and Inv[ItemName].amount) or 0
end

-- ============================================================
--  AUTO SKILL
-- ============================================================
local function AutoSkill()
    local Character = LocalPlayer.Character
    if not Character then return end

    local Skills = {}
    if _G.AutoSkillZ then table.insert(Skills, "z") end
    if _G.AutoSkillX then table.insert(Skills, "x") end
    if _G.AutoSkillC then table.insert(Skills, "c") end
    if _G.AutoSkillV then table.insert(Skills, "v") end
    if _G.AutoSkillF then table.insert(Skills, "f") end
    if #Skills == 0 then return end

    local Skill = Skills[math.random(#Skills)]

    -- Fire skill cho tool đang cầm
    for _, Tool in ipairs(Character:GetChildren()) do
        if Tool:IsA("Tool") then
            pcall(function() ReplicatedStorage.Remotes.Action:FireServer(Tool.Name, Skill) end)
        end
    end

    -- Fire skill cho tool trong Backpack thuộc _G.WeaponList
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        local wanted = {}
        for _, w in ipairs(_G.WeaponList or {}) do wanted[w] = true end
        for _, Tool in ipairs(bp:GetChildren()) do
            if Tool:IsA("Tool") then
                local wt = Tool:GetAttribute("Type")
                if wt and wanted[wt] then
                    pcall(function() ReplicatedStorage.Remotes.Action:FireServer(Tool.Name, Skill) end)
                end
            end
        end
    end
end

-- ============================================================
--  EQUIP WEAPON (Multi)
-- ============================================================
local function EquipWeapon()
    local char = LocalPlayer.Character
    if not char then return end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if not bp then return end

    local wanted = {}
    for _, w in ipairs(_G.WeaponList or {}) do wanted[w] = true end
    if not next(wanted) and _G.MainWeapon then
        wanted[_G.MainWeapon] = true
    end
    if not next(wanted) then return end

    local mainWeapon = _G.WeaponList[1] or _G.MainWeapon

    -- Bỏ tool không cần
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Tool") then
            local wt = v:GetAttribute("Type")
            if not wanted[wt] then v.Parent = bp end
        end
    end

    -- Equip main
    if mainWeapon then
        for _, v in pairs(bp:GetChildren()) do
            if v:IsA("Tool") and v:GetAttribute("Type") == mainWeapon then
                char.Humanoid:EquipTool(v)
                break
            end
        end
    end

    -- Support vào char (không equip)
    for _, v in pairs(bp:GetChildren()) do
        if v:IsA("Tool") then
            local wt = v:GetAttribute("Type")
            if wanted[wt] and wt ~= mainWeapon then
                v.Parent = char
            end
        end
    end
end

-- ============================================================
--  ATTACK
-- ============================================================
local function Attack()
    local Character = LocalPlayer.Character
    if not Character then return end
    local bp = LocalPlayer:FindFirstChild("Backpack")

    for _, v in pairs(Character:GetChildren()) do
        if v:IsA("Tool") then
            pcall(function() ReplicatedStorage.Remotes.Action:FireServer(v.Name, "hit") end)
        end
    end

    if bp then
        local wanted = {}
        for _, w in ipairs(_G.WeaponList or {}) do wanted[w] = true end
        for _, v in pairs(bp:GetChildren()) do
            if v:IsA("Tool") then
                local wt = v:GetAttribute("Type")
                if wt and wanted[wt] then
                    pcall(function() ReplicatedStorage.Remotes.Action:FireServer(v.Name, "hit") end)
                end
            end
        end
    end
end

-- ============================================================
--  ✅ ATTACH SYSTEM
-- ============================================================
local _attachAlign = nil
local _attachGyro  = nil

local function ClearAttach(hrp)
    if _attachAlign then pcall(function() _attachAlign:Destroy() end); _attachAlign = nil end
    if _attachGyro  then pcall(function() _attachGyro:Destroy()  end); _attachGyro  = nil end
    if hrp then
        for _, c in ipairs(hrp:GetChildren()) do
            if c:IsA("AlignPosition") or c:IsA("AlignOrientation") then
                pcall(function() c:Destroy() end)
            end
        end
    end
end

local function EnsureAlign(myHrp)
    if not myHrp or not myHrp.Parent then return nil, nil end

    if not _attachAlign or not _attachAlign.Parent then
        _attachAlign = Instance.new("AlignPosition")
        _attachAlign.Name = "MobAttachPos"
        _attachAlign.Mode = Enum.PositionAlignmentMode.OneAttachment
        _attachAlign.MaxForce = 1000000
        _attachAlign.MaxVelocity = 5000
        _attachAlign.Responsiveness = 800
        _attachAlign.ApplyAtCenterOfMass = true
        _attachAlign.Parent = myHrp

        local att = Instance.new("Attachment")
        att.Name = "MobAttachAtt"
        att.Parent = myHrp
        _attachAlign.Attachment0 = att
    end

    if not _attachGyro or not _attachGyro.Parent then
        _attachGyro = Instance.new("AlignOrientation")
        _attachGyro.Name = "MobAttachGyro"
        _attachGyro.Mode = Enum.OrientationAlignmentMode.OneAttachment
        _attachGyro.MaxTorque = 1000000
        _attachGyro.Responsiveness = 800
        _attachGyro.Parent = myHrp

        local att2 = Instance.new("Attachment")
        att2.Name = "MobAttachGyroAtt"
        att2.Parent = myHrp
        _attachGyro.Attachment0 = att2
    end

    return _attachAlign, _attachGyro
end

local function AttachToPosition(myHrp, targetPos, lookAt, responsiveness)
    if not myHrp or not myHrp.Parent or not targetPos then
        ClearAttach(myHrp)
        return
    end
    lookAt = lookAt or (targetPos + Vector3.new(0, 0, -1))

    local align, gyro = EnsureAlign(myHrp)
    if not align then return end

    if responsiveness then
        align.Responsiveness = responsiveness
        if gyro then gyro.Responsiveness = responsiveness end
    else
        align.Responsiveness = 800
        if gyro then gyro.Responsiveness = 800 end
    end

    align.Position = targetPos
    gyro.CFrame = CFrame.lookAt(targetPos, lookAt)
end

local function AttachToMob(myHrp, tHrp)
    if not myHrp or not myHrp.Parent or not tHrp or not tHrp.Parent then
        ClearAttach(myHrp)
        return
    end

    local mode = _G.Select_Method or "Upper"
    local dist = _G.Distance_Farm or 5
    local offset
    if mode == "Behind" then
        local look = tHrp.CFrame.LookVector
        if look.Magnitude < 0.01 then look = Vector3.new(0, 0, -1) end
        offset = look * dist
    elseif mode == "Front" then
        local look = tHrp.CFrame.LookVector
        if look.Magnitude < 0.01 then look = Vector3.new(0, 0, -1) end
        offset = -look * dist
    elseif mode == "Below" then
        offset = Vector3.new(0, -dist, 0)
    else
        offset = Vector3.new(0, dist, 0)
    end

    local targetPos = tHrp.Position + offset

    local align, gyro = EnsureAlign(myHrp)
    if not align then return end

    align.Responsiveness = 800
    if gyro then gyro.Responsiveness = 800 end

    align.Position = targetPos
    gyro.CFrame = CFrame.lookAt(targetPos, tHrp.Position)
end

-- ============================================================
--  NOCLIP
-- ============================================================
local _savedCollide = {}

local function SetNoclip(enabled)
    local char = LocalPlayer.Character
    if not char then return end

    if enabled then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if _savedCollide[part] == nil then
                    _savedCollide[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    else
        for part, saved in pairs(_savedCollide) do
            if part and part.Parent then
                pcall(function() part.CanCollide = saved end)
            end
        end
        _savedCollide = {}
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    _savedCollide = {}
end)

task.spawn(function()
    while task.wait(0.05) do
        local active = _G.Auto_Farm_Level or _G.Auto_Farm_Material or _G.Auto_BaconThief
        if active then
            SetNoclip(true)
        elseif next(_savedCollide) then
            SetNoclip(false)
        end
    end
end)

-- ============================================================
--  IDLE
-- ============================================================
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ============================================================
--  CREATE WINDOW
-- ============================================================
local Window = Library:CreateWindow({
    Title        = "MarvenRiz Hub",
    Subtitle     = "Rock Fruit • Sea 2",
    AccentColor  = START_ACCENT,
    Size         = UDim2.fromOffset(620, 480),
    SideBarWidth = 170,
    Logo         = "rbxassetid://87526284179554",
    LogoSize     = 32,
    SphereImage  = "rbxassetid://87526284179554",
    SphereIconSize = 38,
    Map          = "Sea2_RockFruit",
    SaveFolder   = "MarvenRizSave_Sea2",
})

-- ============================================================
--  TAB SETTINGS
-- ============================================================
local Tab1     = Window:CreateTab("Settings", true)
local Page1    = Tab1:CreatePage("Settings")

local WeaponSec = Page1:CreateSection("🗡️ Weapons", "Left")
local SkillSec  = Page1:CreateSection("⚔️ Skills", "Left")
local MethodSec = Page1:CreateSection("🎯 Method Farm", "Right")
local HakiSec   = Page1:CreateSection("👁️ Haki", "Right")
local VFXSec    = Page1:CreateSection("✨ VFX", "Right")

WeaponSec:Dropdown({
    Title = "Select Weapons (First = Main)",
    Desc  = "Vũ khí đầu tiên = vũ khí chính (tấn công). Các vũ khí sau là phụ (vẫn tấn công).",
    Options = TypeTool,
    Multi = true,
    Callback = function(v)
        local list = {}
        if type(v) == "table" then
            for k, val in pairs(v) do
                if type(k) == "number" and type(val) == "string" then
                    table.insert(list, val)
                elseif type(k) == "string" and val == true then
                    table.insert(list, k)
                end
            end
        elseif type(v) == "string" then
            table.insert(list, v)
        end
        _G.WeaponList = list
        _G.MainWeapon = list[1]
        _G.Select_EquipWeapon = {}
        for i = 2, #list do
            table.insert(_G.Select_EquipWeapon, list[i])
        end
        print("[Weapons] Main:", _G.MainWeapon or "None", "| Support:", #_G.Select_EquipWeapon)
    end,
})

SkillSec:Dropdown({
    Title = "Select Skills (Z/X/C/V/F)",
    Desc  = "Chọn skill sẽ tự động dùng khi farm.",
    Options = {"Z", "X", "C", "V", "F"},
    Multi = true,
    Callback = function(v)
        _G.AutoSkillZ = false
        _G.AutoSkillX = false
        _G.AutoSkillC = false
        _G.AutoSkillV = false
        _G.AutoSkillF = false

        local function enable(key)
            key = tostring(key):upper()
            if key == "Z" then _G.AutoSkillZ = true
            elseif key == "X" then _G.AutoSkillX = true
            elseif key == "C" then _G.AutoSkillC = true
            elseif key == "V" then _G.AutoSkillV = true
            elseif key == "F" then _G.AutoSkillF = true
            end
        end

        if type(v) == "table" then
            for k, val in pairs(v) do
                if type(k) == "number" and type(val) == "string" then enable(val)
                elseif type(k) == "string" and val == true then enable(k) end
            end
        elseif type(v) == "string" then
            enable(v)
        end

        local active = {}
        if _G.AutoSkillZ then table.insert(active, "Z") end
        if _G.AutoSkillX then table.insert(active, "X") end
        if _G.AutoSkillC then table.insert(active, "C") end
        if _G.AutoSkillV then table.insert(active, "V") end
        if _G.AutoSkillF then table.insert(active, "F") end
        print("[Skills] Active:", #active > 0 and table.concat(active, ",") or "(none)")
    end,
})

MethodSec:Dropdown({
    Title = "Method Farm",
    Options = {"Behind", "Below", "Upper", "Front"},
    Multi = false,
    Value = "Upper",
    Callback = function(v) _G.Select_Method = v end,
})
MethodSec:Slider({
    Title = "Distance Farm",
    Min = 0, Max = 30, Value = 5,
    Callback = function(v) _G.Distance_Farm = v end,
})

HakiSec:Toggle({
    Title = "Auto Haki",
    Value = false,
    Callback = function(v) _G.Auto_Haki = v end,
})

VFXSec:Toggle({
    Title = "Disable VFX",
    Value = false,
    Callback = function(v) _G.VFXDisabled = v end,
})

-- ============================================================
--  TAB FARM
-- ============================================================
local Tab2     = Window:CreateTab("Farm", false)
local FarmPage = Tab2:CreatePage("Farm")

local AutoFarmSec = FarmPage:CreateSection("🌾 Auto Farm", "Left")
local MaterialSec = FarmPage:CreateSection("⛏️ Material", "Left")
local StatusSec   = FarmPage:CreateSection("📊 Status", "Right")

local Spawn_Status = StatusSec:Paragraph({Title = "Spawn Status", Content = "N/A"})

AutoFarmSec:Toggle({
    Title = "Auto Level Farm",
    Value = false,
    Callback = function(v)
        _G.Auto_Farm_Level = v
        if v then
            pcall(function()
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
            end)
        else
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            ClearAttach(hrp)
            _G._lastNPCTarget = nil
            _G._lastNPCTPTime = 0
            _G._questPromptTime = 0
            _G._farmLevelWaitPos = nil
            _G._npcBayStart = nil
        end
    end,
})

AutoFarmSec:Toggle({
    Title = "💸 Auto Farm Bacon Thief",
    Value = false,
    Callback = function(v)
        _G.Auto_BaconThief = v
        if not v then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            ClearAttach(hrp)
        end
    end,
})

MaterialSec:Dropdown({
    Title = "Select Farm Material",
    Desc  = "Chọn nguyên liệu cần farm.",
    Options = ItemAll,
    Multi = true,
    Callback = function(v)
        local list = {}
        if type(v) == "table" then
            for k, val in pairs(v) do
                if type(k) == "number" and type(val) == "string" then
                    table.insert(list, val)
                elseif type(k) == "string" and val == true then
                    table.insert(list, k)
                end
            end
        elseif type(v) == "string" then
            table.insert(list, v)
        end
        _G.Select_Material = list
        print("[Material] Selected:", #list, "items")
    end,
})
MaterialSec:Toggle({
    Title = "⛏️ Auto Farm Material",
    Value = false,
    Callback = function(v)
        _G.Auto_Farm_Material = v
        if not v then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            ClearAttach(hrp)
        end
    end,
})

-- ============================================================
--  TAB OTHER (Random Item + Shop Item + Auto Train)
-- ============================================================
local Tab3      = Window:CreateTab("Other", false)
local RandPage  = Tab3:CreatePage("Random / Shop")
local TrainPage = Tab3:CreatePage("Auto Train")

local DiamondChest     = RandPage:CreateSection("💎 Random Diamond", "Left")
local GuaranteeDiamond = RandPage:CreateSection("🎖️ Shop Item", "Right")

DiamondChest:Paragraph({Title = "📖 Info", Content = "Mở chest random item (tốn Diamond)."})

DiamondChest:Dropdown({
    Title = "Select Random Diamond Chest",
    Options = RandomChestValue,
    Multi = false,
    Value = "x5",
    Callback = function(v) if type(v) == "string" then _G.Select_Random = v end end,
})
DiamondChest:Button({
    Title = "🎲 Open once",
    Callback = function()
        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
            "fire", nil, "RandomItem", _G.Select_Random or "x5"
        )
    end,
})
DiamondChest:Toggle({
    Title = "Auto Random Diamond Chest",
    Value = false,
    Callback = function(v) _G.Auto_RandomChest = v end,
})

local ShopPointInfo = GuaranteeDiamond:Paragraph({
    Title = "💎 PointItem: ---",
    Content = "📊 Đang tải..."
})
local ShopSelectedInfo = GuaranteeDiamond:Paragraph({
    Title = "🎯 Selected: ---",
    Content = "Giá: --- | Trạng thái: ---"
})

GuaranteeDiamond:Dropdown({
    Title = "Select Guarantee Item",
    Options = Poitem,
    Multi = false,
    Callback = function(v)
        if type(v) ~= "string" then _G.Select_Guarantee = nil return end
        _G.Select_Guarantee = v:match("^(.-) /") or v
    end,
})
GuaranteeDiamond:Button({
    Title = "💎 BUY once",
    Callback = function()
        local Point = tonumber(LocalPlayer:GetAttribute("PointItem")) or 0
        local Price = PointItemMData and PointItemMData[_G.Select_Guarantee] or 0
        if not _G.Select_Guarantee then
            Library:Notify({Title = "❌ No item", Description = "Chọn item trước!", Duration = 3}); return
        end
        if Price <= 0 then
            Library:Notify({Title = "❌ Not found", Description = _G.Select_Guarantee, Duration = 3}); return
        end
        if Point < Price then
            Library:Notify({Title = "❌ Không đủ PointItem", Description = ("Cần %d — có %d"):format(Price, Point), Duration = 3}); return
        end
        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
            "fire", nil, "BuyGaranteeRandomItem", _G.Select_Guarantee
        )
        Library:Notify({Title = "✅ Đã mua", Description = _G.Select_Guarantee .. " (-" .. Price .. ")", Duration = 3})
    end,
})
GuaranteeDiamond:Toggle({
    Title = "Auto Buy Guarantee Item",
    Value = false,
    Callback = function(v) _G.Auto_Guarantee = v end,
})

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local pointItem = tonumber(LocalPlayer:GetAttribute("PointItem")) or 0
            ShopPointInfo:SetTitle("💎 PointItem: " .. string.format("%d", pointItem))
            ShopPointInfo:SetContent("📊 Dùng để đổi item trong shop")

            if _G.Select_Guarantee and _G.Select_Guarantee ~= "" then
                local price = (PointItemMData and PointItemMData[_G.Select_Guarantee]) or 0
                local canBuy = pointItem >= price and price > 0
                local status = canBuy and "✅ Có thể mua" or ("❌ Cần thêm " .. math.max(0, price - pointItem))
                ShopSelectedInfo:SetTitle("🎯 " .. _G.Select_Guarantee)
                ShopSelectedInfo:SetContent(("Giá: %d | PointItem: %d | %s"):format(price, pointItem, status))
            else
                ShopSelectedInfo:SetTitle("🎯 Selected: ---")
                ShopSelectedInfo:SetContent("Chọn item trong dropdown")
            end
        end)
    end
end)

-- ============================================================
--  TAB CONFIG (ổn định)
-- ============================================================
local ConfigTab  = Window:CreateTab("Config", false)
local ConfigPage = ConfigTab:CreatePage("Config")

local AppearanceSection = ConfigPage:CreateSection("Menu Appearance", "Left")
AppearanceSection:ColorPicker({
    Title = "Menu Accent", Desc = "Màu chủ đạo.",
    Value = "#7850FF",
    Callback = function(color) ApplyAccent(color) end,
})
AppearanceSection:ColorPicker({
    Title = "Menu Background", Desc = "Màu nền.",
    Value = "#121214",
    Callback = function(color) ApplyBackground(color) end,
})
AppearanceSection:Dropdown({
    Title = "Menu Icon Mode",
    Desc  = "Điện thoại: icon nổi. PC: ẩn.",
    Options = { "Điện thoại", "PC" },
    Value = "Điện thoại",
    Callback = function(selected)
        Library:SetMenuIconMode(selected == "PC" and "pc" or "phone")
    end,
})
AppearanceSection:Button({
    Title = "🎲 Random Accent + Background",
    Desc  = "Random 2 màu khác nhau.",
    Callback = function()
        local newAccent, newBg
        for _ = 1, 20 do
            newAccent = Color3.fromHSV(math.random(), 0.6 + math.random() * 0.4, 0.8 + math.random() * 0.2)
            newBg     = Color3.fromHSV(math.random(), 0.05 + math.random() * 0.25, 0.05 + math.random() * 0.18)
            if hueDistance(newAccent, newBg) >= 0.35 then break end
        end
        ApplyAccent(newAccent)
        ApplyBackground(newBg)
        local elA = Window.ConfigElements["Menu Accent"];     if elA and elA.Set then elA:Set(newAccent:ToHex()) end
        local elB = Window.ConfigElements["Menu Background"]; if elB and elB.Set then elB:Set(newBg:ToHex()) end
        Library:Notify({Title = "Random Colors", Description = ("Accent: %s • BG: %s"):format(newAccent:ToHex(), newBg:ToHex()), Duration = 3})
    end,
})

local SizeSection = ConfigPage:CreateSection("Menu Size", "Left")
SizeSection:Slider({
    Title = "Menu Scale", Desc = "Độ to menu (60-140%).",
    Min = 60, Max = 140, Value = 100,
    Callback = function(percent)
        local scale = percent / 100
        if Window.SetScale then Window:SetScale(scale) end
        ApplyMenuScale(scale)
    end,
})
SizeSection:Toggle({
    Title = "Transparency", Desc = "Độ mờ 0.2.",
    Value = false,
    Callback = function(state) Window:SetTransparency(state and 0.2 or 0) end,
})
SizeSection:Keybind({
    Title = "Menu Keybind",
    Desc  = "Nhấn phím này để ẩn/mở menu.",
    Value = Enum.KeyCode.T,
    Callback = function(newKey)
        if newKey and newKey.Name then Window:SetMenuKeybind(newKey) end
    end,
})

local SaveSection = ConfigPage:CreateSection("Save Manager", "Right")
SaveSection:AddConfigManager(Library.SaveManager.Folder)

-- ============================================================
--  AUTO LOAD
-- ============================================================
task.wait(0.5)
local loaded = Library.SaveManager:LoadAutoloadConfig()
print(loaded and "[MarvenRiz] Auto Load OK." or "[MarvenRiz] No Auto Load config.")

task.defer(function()
    local savedScale = Window.ConfigElements["Menu Scale"]
    if savedScale and savedScale.Get then
        local val = savedScale.Get()
        if type(val) == "number" then Window:SetScale(val / 100) end
    end
end)

task.delay(0.6, function()
    Library:Notify({Title = "MarvenRiz Hub", Description = "Loaded on map " .. tostring(game.PlaceId), Duration = 3})
end)
print("[MarvenRiz] UI ready — PlaceId:", game.PlaceId)

-- ============================================================
--  METHOD UPDATE LOOP
-- ============================================================
task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Select_Method == "Behind" then
                MethodFarm = CFrame.new(0, 0, _G.Distance_Farm)
            elseif _G.Select_Method == "Front" then
                MethodFarm = CFrame.new(0, 0, -_G.Distance_Farm) * CFrame.Angles(0, math.rad(180), 0)
            elseif _G.Select_Method == "Below" then
                MethodFarm = CFrame.new(0, -_G.Distance_Farm, 0) * CFrame.Angles(math.rad(90), 0, 0)
            else
                MethodFarm = CFrame.new(0, _G.Distance_Farm, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            end
        end)
    end
end)

-- ============================================================
--  SPAWN STATUS LOOP
-- ============================================================
task.spawn(function()
    while task.wait() do
        pcall(function()
            local Text = {}
            for Name, MobName in pairs(SpawnList) do
                local Spawned = workspace.Mob and workspace.Mob:FindFirstChild(MobName) ~= nil
                table.insert(Text, Name .. ": " .. (Spawned and "✅" or "❌"))
            end
            Spawn_Status:SetContent(table.concat(Text, "\n"))
        end)
    end
end)

-- ============================================================
--  AUTO HAKI LOOP
-- ============================================================
task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_Haki then
                if not LocalPlayer.Character:FindFirstChild("HakiFolder") then
                    ReplicatedStorage.Remotes.Action:FireServer("Misc", "buso")
                end
            end
        end)
    end
end)

-- ============================================================
--  NO VFX LOOP
-- ============================================================
local VFX_CONNECTIONS = {}
local VFX_KILL_CLASSES = {
    ["ParticleEmitter"] = true, ["Beam"] = true, ["Trail"] = true,
    ["Sparkles"] = true, ["Fire"] = true, ["Smoke"] = true,
    ["Highlight"] = true, ["PointLight"] = true, ["SpotLight"] = true, ["SurfaceLight"] = true,
}

local function TryKillVFX(obj)
    if not obj or not obj.Parent then return end
    if not VFX_KILL_CLASSES[obj.ClassName] then return end
    pcall(function() if obj.Enabled then obj.Enabled = false end end)
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

local _lastVFXState = false

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local state = _G.VFXDisabled
            if state and not _lastVFXState then
                KillVFXIn(workspace)
                local cam = workspace.CurrentCamera
                if cam then KillVFXIn(cam) end
                local char = LocalPlayer.Character
                if char then KillVFXIn(char) end
                HookContainer(workspace)
                if cam then HookContainer(cam) end
                if char then HookContainer(char) end
            elseif not state and _lastVFXState then
                for _, conn in ipairs(VFX_CONNECTIONS) do pcall(function() conn:Disconnect() end) end
                VFX_CONNECTIONS = {}
            end
            _lastVFXState = state
            if state then
                KillVFXIn(workspace)
                local cam = workspace.CurrentCamera
                if cam then KillVFXIn(cam) end
                local char = LocalPlayer.Character
                if char then KillVFXIn(char) end
            end
        end)
    end
end)

-- ============================================================
--  RANDOM CHEST LOOP
-- ============================================================
task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_RandomChest then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                    "fire", nil, "RandomItem", _G.Select_Random or "x5"
                )
            end
        end)
    end
end)

-- ============================================================
--  GUARANTEE LOOP
-- ============================================================
task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_Guarantee and PointItemMData then
                local Point = tonumber(LocalPlayer:GetAttribute("PointItem")) or 0
                local Price = PointItemMData[_G.Select_Guarantee] or 0
                if _G.Select_Guarantee and Point >= Price and Price > 0 then
                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                        "fire", nil, "BuyGaranteeRandomItem", _G.Select_Guarantee
                    )
                end
            end
        end)
    end
end)

-- ============================================================
--  AUTO FARM LEVEL LOOP
-- ============================================================
task.spawn(function()
    while task.wait() do
        xpcall(function()
            if not _G.Auto_Farm_Level then return end

            local char = LocalPlayer.Character
            local myHrp = char and char:FindFirstChild("HumanoidRootPart")
            if not myHrp then return end

            local quest = GetQuest_Level(tonumber(LocalPlayer:GetAttribute("Level")))
            if not quest then return end

            local Frame = GetQuestFrame()
            if not Frame then return end

            local Text = Frame.Title.Text or ""

            if LocalPlayer.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
            end
            if Frame.Visible and not string.find(Text, quest.Monster) then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                repeat task.wait() until not Frame.Visible
            end

            if not Frame.Visible then
                -- ✅ LUÔN BAY tới NPC quest (Responsiveness 250 + Noclip)
                local npc = quest.Quest
                if npc then
                    local npcHrp = npc:FindFirstChild("HumanoidRootPart")
                        or npc:FindFirstChildWhichIsA("BasePart", true)

                    if npcHrp then
                        local npcPos = npcHrp.Position + Vector3.new(0, 8, 0)

                        SetNoclip(true)

                        AttachToPosition(myHrp, npcPos, npcHrp.Position, 250)

                        local realDist = (myHrp.Position - npcPos).Magnitude
                        if realDist > 30 then
                            if not _G._npcBayStart then
                                _G._npcBayStart = tick()
                            elseif tick() - _G._npcBayStart > 10 then
                                ClearAttach(myHrp)
                                myHrp.CFrame = CFrame.new(npcPos, npcHrp.Position)
                                myHrp.AssemblyLinearVelocity = Vector3.zero
                                myHrp.AssemblyAngularVelocity = Vector3.zero
                                _G._npcBayStart = nil
                            end
                        else
                            _G._npcBayStart = nil
                        end

                        local pro_xim = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                        local now = tick()
                        if pro_xim and now - _G._questPromptTime > 0.3 then
                            _G._questPromptTime = now
                            pcall(function()
                                local orig = pro_xim.MaxActivationDistance
                                pro_xim.MaxActivationDistance = 9999
                                fireproximityprompt(pro_xim)
                                task.defer(function()
                                    pcall(function()
                                        if pro_xim and pro_xim.Parent then
                                            pro_xim.MaxActivationDistance = orig
                                        end
                                    end)
                                end)
                            end)
                        end
                    end
                end
            else
                _G._lastNPCTarget = nil
                _G._lastNPCTPTime = 0
                _G._questPromptTime = 0
                _G._npcBayStart = nil

                -- ✅ Farm mob
                local target, tHrp
                local mobFolder = workspace:FindFirstChild("Mob") or workspace:FindFirstChild("Mobs")
                if mobFolder then
                    for _, v in pairs(mobFolder:GetChildren()) do
                        if v:IsA("Model") and v.Name == quest.Monster
                           and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                            local r = v:FindFirstChild("HumanoidRootPart")
                            if r then target = v; tHrp = r end
                            break
                        end
                    end
                end

                if target and tHrp then
                    target.Humanoid.WalkSpeed = 0
                    target.Humanoid.JumpPower = 0

                    EquipWeapon()
                    AutoSkill()
                    Attack()

                    local targetPos = tHrp.Position + Vector3.new(0, _G.Distance_Farm or 5, 0)
                    local realDist = (myHrp.Position - targetPos).Magnitude

                    if realDist > 100 then
                        ClearAttach(myHrp)
                        myHrp.CFrame = CFrame.new(targetPos, tHrp.Position)
                        myHrp.AssemblyLinearVelocity = Vector3.zero
                        myHrp.AssemblyAngularVelocity = Vector3.zero
                    else
                        AttachToMob(myHrp, tHrp)
                    end

                    _G._farmLevelWaitPos = nil
                else
                    local waitPos = nil
                    local itemdrops = workspace:FindFirstChild("Itemdrops")
                    local spawnPart = itemdrops and itemdrops:FindFirstChild(quest.Monster)
                    if spawnPart then
                        waitPos = spawnPart:GetPivot().Position + Vector3.new(0, 15, 0)
                    else
                        waitPos = myHrp.Position + Vector3.new(0, 15, 0)
                    end
                    AttachToPosition(myHrp, waitPos, waitPos + Vector3.new(0, 0, -1), 800)
                end
            end
        end, print)
    end
end)

-- ============================================================
--  AUTO BACON THIEF LOOP
-- ============================================================
local CurrentSpawn = 1

task.spawn(function()
    while task.wait() do
        pcall(function()
            if not _G.Auto_BaconThief then return end

            local char = LocalPlayer.Character
            local myHrp = char and char:FindFirstChild("HumanoidRootPart")
            if not myHrp then return end

            local mobSpawnGroup = workspace:FindFirstChild("MobSpawnGroup")
            if not mobSpawnGroup then return end

            local Spawns = mobSpawnGroup:GetChildren()
            local Spawn = Spawns[CurrentSpawn]
            if not Spawn then
                CurrentSpawn = 1
                return
            end

            local ChestRef = Spawn:FindFirstChild("ChestRef", true)
            if not ChestRef then
                CurrentSpawn = CurrentSpawn + 1
                if CurrentSpawn > #Spawns then CurrentSpawn = 1 end
                return
            end

            local Target, TargetHrp
            local Distance = 30
            for _, Mob in ipairs(workspace.Mob:GetChildren()) do
                if Mob:IsA("Model") and Mob.Name == "Bacon Thief"
                   and Mob:FindFirstChild("HumanoidRootPart")
                   and Mob:FindFirstChild("Humanoid")
                   and Mob.Humanoid.Health > 0 then
                    local Mag = (Mob.HumanoidRootPart.Position - ChestRef.Position).Magnitude
                    if Mag < Distance then
                        Distance = Mag
                        Target = Mob
                        TargetHrp = Mob.HumanoidRootPart
                    end
                end
            end

            if Target and TargetHrp then
                Target.Humanoid.WalkSpeed = 0
                Target.Humanoid.JumpPower = 0
                EquipWeapon()
                AutoSkill()
                Attack()

                local targetPos = TargetHrp.Position + Vector3.new(0, _G.Distance_Farm or 5, 0)
                local realDist = (myHrp.Position - targetPos).Magnitude

                if realDist > 100 then
                    ClearAttach(myHrp)
                    myHrp.CFrame = CFrame.new(targetPos, TargetHrp.Position)
                    myHrp.AssemblyLinearVelocity = Vector3.zero
                    myHrp.AssemblyAngularVelocity = Vector3.zero
                else
                    AttachToMob(myHrp, TargetHrp)
                end
            else
                local chestPos = ChestRef.Position
                local hoverPos = chestPos + Vector3.new(0, 3, 0)
                local Prompt = ChestRef:FindFirstChildWhichIsA("ProximityPrompt", true)
                if Prompt and Prompt.Parent and Prompt.ActionText == "Open" then
                    AttachToPosition(myHrp, hoverPos, chestPos)
                    if (myHrp.Position - chestPos).Magnitude <= 8 then
                        fireproximityprompt(Prompt)
                    end
                else
                    AttachToPosition(myHrp, hoverPos, chestPos)
                    if tick() - (_G._lastThiefSpawnTime or 0) > 1.5 then
                        CurrentSpawn = CurrentSpawn + 1
                        if CurrentSpawn > #Spawns then CurrentSpawn = 1 end
                        _G._lastThiefSpawnTime = tick()
                    end
                end
            end
        end)
    end
end)

-- ============================================================
--  AUTO FARM MATERIAL LOOP
-- ============================================================
task.spawn(function()
    while task.wait(0.05) do
        xpcall(function()
            if not _G.Auto_Farm_Material then return end

            local materials = {}
            if type(_G.Select_Material) == "table" then
                for k, v in pairs(_G.Select_Material) do
                    if type(k) == "number" and type(v) == "string" then
                        table.insert(materials, v)
                    elseif type(k) == "string" and v == true then
                        table.insert(materials, k)
                    end
                end
            end
            if #materials == 0 then return end

            local char = LocalPlayer.Character
            local myHrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if not myHrp or not hum or hum.Health <= 0 then return end

            local mobFolder = workspace:FindFirstChild("Mob") or workspace:FindFirstChild("Mobs")
            if not mobFolder then return end

            local Target, TargetHrp
            local minDist = math.huge

            for _, Material in ipairs(materials) do
                local MobNames = ItemDrop[Material]
                if MobNames then
                    for _, MobName in ipairs(MobNames) do
                        for _, Mob in ipairs(mobFolder:GetChildren()) do
                            if Mob:IsA("Model") and Mob.Name == MobName
                               and Mob:FindFirstChild("Humanoid")
                               and Mob:FindFirstChild("HumanoidRootPart")
                               and Mob.Humanoid.Health > 0 then
                                local dist = (myHrp.Position - Mob.HumanoidRootPart.Position).Magnitude
                                if dist < minDist then
                                    minDist = dist
                                    Target = Mob
                                    TargetHrp = Mob.HumanoidRootPart
                                end
                            end
                        end
                    end
                end
            end

            if not Target then
                local firstMaterial = materials[1]
                local MobNames = firstMaterial and ItemDrop[firstMaterial]
                if MobNames and #MobNames > 0 then
                    local spawnName = MobNames[1]
                    local itemdrops = workspace:FindFirstChild("Itemdrops")
                    local spawnPart = itemdrops and itemdrops:FindFirstChild(spawnName)
                    if spawnPart then
                        local spawnPos = spawnPart:GetPivot().Position
                        local hoverPos = spawnPos + Vector3.new(0, 15, 0)
                        AttachToPosition(myHrp, hoverPos, spawnPos)
                    end
                end
                return
            end

            Target.Humanoid.WalkSpeed = 0
            Target.Humanoid.JumpPower = 0

            EquipWeapon()
            AutoSkill()
            Attack()

            local targetPos = TargetHrp.Position + Vector3.new(0, _G.Distance_Farm or 5, 0)
            local realDist = (myHrp.Position - targetPos).Magnitude

            if realDist > 100 then
                ClearAttach(myHrp)
                myHrp.CFrame = CFrame.new(targetPos, TargetHrp.Position)
                myHrp.AssemblyLinearVelocity = Vector3.zero
                myHrp.AssemblyAngularVelocity = Vector3.zero
            else
                AttachToMob(myHrp, TargetHrp)
            end
        end, function(err)
            warn("[AutoFarmMaterial] Error:", err)
        end)
    end
end)

-- ============================================================
--  AUTO TRAIN (Sparring + Meditation) — gộp từ script riêng
-- ============================================================
_G.Auto_Sparring   = false
_G.Auto_Meditation = false

local SparSec  = TrainPage:CreateSection("⚔️ Sparring", "Left")
local MedSec   = TrainPage:CreateSection("🧘 Meditation", "Right")

-- ✅ SPARRING TOGGLE
SparSec:Toggle({
    Title = "Auto Sparring",
    Value = false,
    Callback = function(Value)
        _G.Auto_Sparring = Value
        print("[S40] Sparring:", Value and "ON" or "OFF")
    end
})

-- ✅ MEDITATION TOGGLE
MedSec:Toggle({
    Title = "Auto Meditation",
    Value = false,
    Callback = function(Value)
        _G.Auto_Meditation = Value
        print("[M48] Meditation:", Value and "ON" or "OFF")
    end
})

-- ============================================================
--  SPARRING LOOP (từ script gốc, không có UI riêng)
-- ============================================================
task.spawn(function()
    local LocalPlayer = game.Players.LocalPlayer

    local function GetGameFrame()
        local BT = LocalPlayer.PlayerGui:FindFirstChild("BeerusTraining")
        if not BT then return nil end
        return BT:FindFirstChild("Game")
    end

    local function GetActiveKey()
        local Game = GetGameFrame()
        if not Game then return nil, 0 end
        local Pads = Game:FindFirstChild("Pads")
        if not Pads then return nil, 0 end

        local bestKey = nil
        local bestSize = 0
        for _, pad in ipairs(Pads:GetChildren()) do
            local ring = pad:FindFirstChild("Ring")
            if ring then
                local size = ring.AbsoluteSize.X
                if size > 68 and size > bestSize then
                    bestSize = size
                    bestKey = pad.Name
                end
            end
        end
        return bestKey, bestSize
    end

    local function GetScore()
        local Game = GetGameFrame()
        if not Game then return "0/50" end
        local Top = Game:FindFirstChild("Top")
        if not Top then return "0/50" end
        local Score = Top:FindFirstChild("Score")
        if not Score then return "0/50" end
        return Score.Text
    end

    local function IsGameOpen()
        local Game = GetGameFrame()
        if not Game then return false end
        return Game.Visible
    end

    local function FirePadButton(keyChar)
        local Game = GetGameFrame()
        if not Game then return false end
        local Pads = Game:FindFirstChild("Pads")
        if not Pads then return false end
        local btn = Pads:FindFirstChild(keyChar)
        if not btn then return false end

        if getconnections then
            local ok, conns = pcall(getconnections, btn.Activated)
            if ok and #conns > 0 then
                local fired = false
                for _, conn in ipairs(conns) do
                    if conn.Fire then
                        pcall(function() conn:Fire() end)
                        fired = true
                    end
                end
                if fired then return true end
            end
        end
        pcall(function() btn:Activate() end)
        return true
    end

    local hasFiredForKey = false
    local lastFireTime = 0
    local lastActiveKey = ""
    local ringIdleStartTime = 0
    local isRingIdle = true

    local FIRE_THRESHOLD = 75
    local MIN_RING_TO_FIRE = 70
    local FIRE_COOLDOWN = 0.5
    local RING_IDLE = 68
    local ringIdleResetTime = 0.3

    while task.wait(0.01) do
        pcall(function()
            if not _G.Auto_Sparring then return end
            if not IsGameOpen() then return end

            local now = tick()
            local padKey, ringSize = GetActiveKey()

            if ringSize <= RING_IDLE or not padKey then
                if not isRingIdle then
                    isRingIdle = true
                    ringIdleStartTime = now
                else
                    if hasFiredForKey and (now - ringIdleStartTime >= ringIdleResetTime) then
                        hasFiredForKey = false
                    end
                end
                return
            else
                isRingIdle = false
                ringIdleStartTime = 0
            end

            if padKey ~= lastActiveKey then
                lastActiveKey = padKey
                hasFiredForKey = false
            end

            if hasFiredForKey then return end
            if now - lastFireTime < FIRE_COOLDOWN then return end

            if ringSize >= MIN_RING_TO_FIRE and ringSize <= FIRE_THRESHOLD then
                local fired = FirePadButton(padKey)
                if fired then
                    hasFiredForKey = true
                    lastFireTime = now
                end
            end
        end)
    end
end)

-- ============================================================
--  MEDITATION LOOP (từ script gốc, không có UI riêng)
-- ============================================================
task.spawn(function()
    local LocalPlayer = game.Players.LocalPlayer

    local function GetBT()
        return LocalPlayer.PlayerGui:FindFirstChild("BeerusTraining")
    end

    local function GetGame()
        local BT = GetBT()
        if not BT then return nil end
        return BT:FindFirstChild("Game")
    end

    local function GetResult()
        local BT = GetBT()
        if not BT then return nil end
        return BT:FindFirstChild("Result")
    end

    local function GetLitKey()
        local Game = GetGame()
        if not Game then return nil end
        local Pads = Game:FindFirstChild("Pads")
        if not Pads then return nil end

        for _, pad in ipairs(Pads:GetChildren()) do
            if pad:IsA("TextButton") then
                local bg = pad.BackgroundColor3
                if bg.B > 0.3 then
                    return pad.Name
                end
            end
        end
        return nil
    end

    local function GetScore()
        local Game = GetGame()
        if not Game then return "0/100" end
        local Top = Game:FindFirstChild("Top")
        if not Top then return "0/100" end
        local Score = Top:FindFirstChild("Score")
        if not Score then return "0/100" end
        return Score.Text
    end

    local function GetFeedback()
        local Game = GetGame()
        if not Game then return "" end
        local FB = Game:FindFirstChild("Feedback")
        if not FB then return "" end
        return FB.Text
    end

    local function IsGameOpen()
        local Game = GetGame()
        if not Game then return false end
        return Game.Visible
    end

    local function IsResultOpen()
        local Result = GetResult()
        if not Result then return false end
        return Result.Visible
    end

    local function FirePadButton(keyChar)
        local Game = GetGame()
        if not Game then return false end
        local Pads = Game:FindFirstChild("Pads")
        if not Pads then return false end
        local btn = Pads:FindFirstChild(keyChar)
        if not btn then return false end

        if getconnections then
            local ok, conns = pcall(getconnections, btn.Activated)
            if ok and #conns > 0 then
                local fired = false
                for _, conn in ipairs(conns) do
                    if conn.Fire then
                        pcall(function() conn:Fire() end)
                        fired = true
                    end
                end
                if fired then return true end
            end
        end
        pcall(function() btn:Activate() end)
        return true
    end

    local function DoRetry()
        local Result = GetResult()
        if not Result or not Result.Visible then return false end
        local retryBtn = Result:FindFirstChild("Retry")
        if not retryBtn then return false end

        local fired = false
        if getconnections then
            local ok, conns = pcall(getconnections, retryBtn.Activated)
            if ok and #conns > 0 then
                for _, conn in ipairs(conns) do
                    if conn.Fire then
                        pcall(function() conn:Fire() end)
                        fired = true
                    end
                end
            end
        end
        if not fired then
            pcall(function()
                retryBtn:Activate()
                fired = true
            end)
        end
        return fired
    end

    local lastFireTime = 0
    local FIRE_COOLDOWN = 1.0
    local BROKEN_COOLDOWN = 1.5
    local lastFiredKey = ""
    local lastFiredScore = ""
    local lastRetryTime = 0
    local RETRY_COOLDOWN = 3.0
    local Med_Retries = 0

    while task.wait(0.02) do
        pcall(function()
            local now = tick()

            -- Retry khi fail
            if IsResultOpen() then
                if now - lastRetryTime >= RETRY_COOLDOWN then
                    local success = DoRetry()
                    if success then
                        lastRetryTime = now
                        Med_Retries = Med_Retries + 1
                        lastFiredKey = ""
                        lastFiredScore = ""
                        lastFireTime = 0
                    end
                end
                return
            end

            if not _G.Auto_Meditation then return end
            if not IsGameOpen() then return end

            local fb = GetFeedback()
            local score = GetScore()

            local cooldown = (fb == "FOCUS BROKEN") and BROKEN_COOLDOWN or FIRE_COOLDOWN
            if now - lastFireTime < cooldown then return end

            local litKey = GetLitKey()
            if not litKey then return end
            if litKey == lastFiredKey and score == lastFiredScore then return end

            local fired = FirePadButton(litKey)
            if fired then
                lastFireTime = now
                lastFiredKey = litKey
                lastFiredScore = score
            end
        end)
    end
end)

print("[MarvenRiz] Sea2 script loaded — PlaceId:", game.PlaceId)
