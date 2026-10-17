-- ============================================================
-- SEA 1 SCRIPT - FULL FEATURES (v47 FINAL + AutoSkill Fix) — English
-- MarvenRiz Hub - Rock Fruit (Sea 1 + Moon)
-- ============================================================
print("[Sea 1] ▶️ Loading...")

-- ============================================================
-- SERVICES & MODULES (SAFE LOAD)
-- ============================================================
local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local HttpService         = game:GetService("HttpService")
local RunService          = game:GetService("RunService")
local VirtualUser         = game:GetService("VirtualUser")
local GuiService          = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer         = Players.LocalPlayer

local function SafeWait(parent, name, timeout)
    local ok, result = pcall(function()
        return parent:WaitForChild(name, timeout or 3)
    end)
    if ok and result then return result end
    return parent:FindFirstChild(name)
end

local function SafeRequire(module)
    if not module then return nil end
    local ok, result = pcall(function() return require(module) end)
    if ok and result then return result end
    return nil
end

local Npc_Quest = SafeWait(workspace, "NpcQuest", 3)
local Itemdrops = SafeWait(workspace, "Itemdrops", 3)

local ModulesFolder = SafeWait(ReplicatedStorage, "Modules", 3)

local UseItems        = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("UseItems"))
local CraftingTable   = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("CraftingTable"))
local Quest_Module    = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("QuestModule"))
local ItemList        = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("Itemlist"))
local SpawnBossList   = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("SpawnBossList"))
local Blacklist       = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("BlacklistItemTrade"))
local AccessoryModule = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("AccessoryModule"))
local PointItemM      = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("GaranteeRandomItem"))
local PointItemMoon   = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("GaranteeEventMoon"))
local Economy         = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("Economy"))
local Action = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Action")

local missingModules = {}
for name, mod in pairs({
    UseItems = UseItems, CraftingTable = CraftingTable, Quest_Module = Quest_Module,
    ItemList = ItemList, SpawnBossList = SpawnBossList, Blacklist = Blacklist,
    AccessoryModule = AccessoryModule, PointItemM = PointItemM,
    PointItemMoon = PointItemMoon, Economy = Economy
}) do
    if not mod then table.insert(missingModules, name) end
end
if #missingModules > 0 then
    warn("[Sea 1] ⚠️ Missing modules: " .. table.concat(missingModules, ", "))
end

-- ============================================================
-- CONFIG & GLOBALS
-- ============================================================
local TypeTool         = {"Melee", "Sword", "Special", "DevilFruit"}
local RandomChestValue = {"x5", "x10", "x15"}

local Quest_List, WeaponAll, MonsterDrop = {}, {}, {}
local ItemDrop, ItemToMob, ItemAll        = {}, {}, {}
local X2List, Poitem, PoiteMoon, SellItems, Bosses = {}, {}, {}, {}, {}
local CachedInventory = {}
local LastCraft, CraftDelay, LastInventory = 0, 1, 0
local NotifyCraft     = false
local MethodFarm      = CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-90), 0, 0)

local SpawnList = {
    ["Thief"]      = "Bacon Thief",
    ["Piccolo"]    = "Piccolo",
    ["Duck"]       = "Duck Monster",
    ["Devil Boat"] = "Devil Boat",
    ["Kraken"]     = "Kraken"
}

_G.SmoothUpperBelow              = true
_G.AutoCombat                    = false
_G.CanAutoSkill                  = false
_G.MainWeapon                    = "Melee"
_G.Select_EquipWeapon            = {}
_G.Select_Method                 = "Upper"
_G.Distance_Farm                 = 5
_G.AutoSkillZ, _G.AutoSkillX     = false, false
_G.AutoSkillC, _G.AutoSkillV     = false, false
_G.AutoSkillF, _G.Auto_Haki      = false, false
_G.Auto_Equip_Accessory          = false
_G.Auto_Rebirth                  = false
_G.Select_Potion                 = ""
_G.PotionAmount                  = 1
_G.Auto_Use_Potion               = false
_G.Auto_Farm_Level               = false
_G.Select_Material               = {}
_G.Auto_Farm_Material            = false
_G.Select_Boss                   = nil
_G.Auto_FarmBoss                 = false
_G.Auto_FarmBoss_Automatically   = false
_G.Auto_BaconThief               = false
_G.Auto_Piccolo                  = false
_G.Auto_Duck                     = false
_G.Auto_DevilBoat                = false
_G.Auto_DuckAutomatically        = false
_G.Select_Item                   = nil
_G.Auto_CraftWeapon              = false
_G.Auto_Farm_Set                 = false
_G.Auto_Raid                     = false
_G.Dungeon_UseValue              = 1
_G.HealthPercent                 = 30
_G.Auto_Dungeon                  = false
_G.AutoMelee, _G.AutoDefense     = false, false
_G.AutoSword, _G.AutoPower       = false, false
_G.Select_Random                 = "x5"
_G.Auto_RandomChest              = false
_G.Select_Random_Moon            = "x5"
_G.Auto_RandomChest_Moon         = false
_G.Select_Guarantee              = nil
_G.Auto_Guarantee                = false
_G.Select_Guarantee_Moon         = nil
_G.Auto_Guarantee_Moon           = false
_G.RaidBossOffsetY               = 55
_G.RaidBallOffsetY               = 25
_G.DungeonHeight                 = 25
_G.VFXDisabled                   = false
_G.RaidAutoAttack                = false
_G.RaidAutoSkill                 = false
_G.Auto_Kraken                   = false
_G.TimeMysteryAmount             = 1

-- ============================================================
-- BUILD LISTS
-- ============================================================

if PointItemM then
    for Item, Price in pairs(PointItemM) do
        table.insert(Poitem, {Name = Item, Price = Price})
    end
    table.sort(Poitem, function(a, b) return a.Price < b.Price end)
    for i, Data in ipairs(Poitem) do Poitem[i] = Data.Name .. " / " .. Data.Price .. " Point" end
end

if PointItemMoon then
    for Item, Price in pairs(PointItemMoon) do
        table.insert(PoiteMoon, {Name = Item, Price = Price})
    end
    table.sort(PoiteMoon, function(a, b) return a.Price < b.Price end)
    for i, Data in ipairs(PoiteMoon) do PoiteMoon[i] = Data.Name .. " / " .. Data.Price .. " Point" end
end

if Quest_Module and Npc_Quest then
    pcall(function()
        table.sort(Quest_Module, function(a, b) return a.Level < b.Level end)
        for i, data in ipairs(Quest_Module) do
            local NPC = Npc_Quest:WaitForChild("NPC_Quest" .. i, 2)
            if NPC then
                Quest_List[i] = {Level = data.Level, Monster = NPC:GetAttribute("Name"), Quest = NPC}
            end
        end
    end)
end

if UseItems then
    for Weapon in pairs(UseItems) do table.insert(WeaponAll, Weapon) end
    table.sort(WeaponAll)
end

if Blacklist then
    for ItemName in pairs(Blacklist) do
        if ItemName:find("X2") then table.insert(X2List, ItemName) end
    end
end

if Itemdrops then
    pcall(function()
        for _, Mob in ipairs(Itemdrops:GetChildren()) do
            local ScrollingFrame = Mob:FindFirstChild("ScrollingFrame", true)
            if ScrollingFrame then
                MonsterDrop[Mob.Name] = {}
                for _, v in ipairs(ScrollingFrame:GetDescendants()) do
                    if v:IsA("TextLabel") and v.Text and v.Text ~= "" then
                        if not v.Text:find("%%") then
                            MonsterDrop[Mob.Name][v.Text] = true
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

if ItemList then
    for ItemName in pairs(ItemToMob) do
        local Data = ItemList[ItemName]
        if not (Data and Data.Type == "Accessory") then table.insert(ItemAll, ItemName) end
    end
    table.sort(ItemAll)
end

if SpawnBossList then
    for BossName in pairs(SpawnBossList) do table.insert(Bosses, BossName) end
    table.sort(Bosses)
end

if #Bosses == 0 then
    Bosses = {"Bacon Thief", "Piccolo", "Duck Monster", "Devil Boat"}
end

if #WeaponAll == 0 then
    WeaponAll = {"Melee", "Sword", "Special", "DevilFruit"}
end

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================
local function GetQuest_Level(My_level)
    local Quest
    for _, v in ipairs(Quest_List) do
        if My_level >= v.Level then Quest = v else break end
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

local function Teleport(Pos)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = Pos  -- ← GHI ĐÈ CFrame trực tiếp
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

-- ============================================================
-- LOAD UI
-- ============================================================
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Ui_New.lua"
))()
local MySaveManager = Library.SaveManager

local MOON_PLACE_ID = 82878101790702
local IS_MOON_MAP   = (game.PlaceId == MOON_PLACE_ID)

local Window = Library:CreateWindow({
    Title = "MarvenRiz Hub" .. (IS_MOON_MAP and " (Moon)" or ""),
    Subtitle = IS_MOON_MAP and "Auto Raid Moon Only" or "Sea 1 — Rock Fruit",
    Size = UDim2.fromOffset(500, 370),
    AccentColor = Color3.fromRGB(50, 150, 255),
    SideBarWidth = 120,
    Logo = "rbxassetid://87526284179554",
    LogoSize = 32,
    SphereText = false,
    SphereImage = "rbxassetid://87526284179554",
    SphereIconSize = 38,
    Map = "RockFruit"
})

function _G.SeaNotify(title, desc, duration)
    pcall(function()
        if Library and Library.Notify then
            Library:Notify({Title = title or "", Description = desc or "", Duration = duration or 4})
        end
    end)
end

-- ============================================================
-- 🌙 MOON MAP UI
-- ============================================================
if IS_MOON_MAP then

    local MoonTab    = Window:CreateTab("Auto Raid Moon", true, false)
    local MoonPage   = MoonTab:CreatePage("Moon Raid")
    local MoonFarm   = MoonPage:CreateSection("🌙 Auto Farm Moon", "Left")
    local MoonSkills = MoonPage:CreateSection("⚔️ Attack / Skill", "Right")
    local MoonWeapon = MoonPage:CreateSection("🗡️ Weapons", "Left")
    local MoonInfo   = MoonPage:CreateSection("📊 Status", "Right")
    local MoonTravel = MoonPage:CreateSection("🌍 Travel", "Left")

    local MoonStatusPara = MoonInfo:Paragraph({
        Title = "Status: Waiting",
        Content = "Enable left toggle to farm Moon"
    })

    local MoonRunning       = false
    local MoonLastRunning   = false
    local MoonLastAttack    = 0
    local MoonLastSkill     = 0
    local MoonLastEquip     = 0
    local MoonCurrentTarget = nil
    local MoonSettleTime    = 0
    local MoonLastAction    = 0
    local MoonAtCave        = false
    local MoonJitterSeed    = 0

    local MoonLastMobHealth    = 0
    local MoonDamageCheckTime  = 0
    local MoonStuckCount       = 0
    local MoonLastStuckTime    = 0
    local MOON_STUCK_THRESHOLD = 5
    local MOON_STUCK_MAX       = 5
    local MOON_STUCK_COOLDOWN  = 3

    local MOON_SETTLE_DELAY = 0.15
    local MOON_WATCHDOG     = 2.0

    _G.MoonHitPosition = "Upper"
    _G.MoonHitDistance = 12

    local MoonRocketTower     = nil
    local MoonRocketPos       = nil
    local MoonRocketLastCheck = 0
    local MOON_ROCKET_CACHE   = 15

    local CAVE_POS = Vector3.new(-195, 14, 412)
    local MOON_SAVE_FOLDER = "MarvenRiz_Moon"

    local function EnsureFolder()
        if not isfolder(MOON_SAVE_FOLDER) then
            pcall(function() makefolder(MOON_SAVE_FOLDER) end)
        end
    end

    local function GetSavePath(name)
        return MOON_SAVE_FOLDER .. "/" .. name .. ".json"
    end

    local function GetSaveList()
        local list = {}
        if not isfolder(MOON_SAVE_FOLDER) then return list end

        local ok, files = pcall(function() return listfiles(MOON_SAVE_FOLDER) end)
        if not ok or type(files) ~= "table" then return list end

        for _, file in ipairs(files) do
            local name = tostring(file):match("([^/\\]+)%.json$")
            if name and not name:find("^_") then
                table.insert(list, name)
            end
        end
        table.sort(list)
        return list
    end

    local function AsString(v)
        if type(v) == "string" then return v end
        if type(v) == "table" then
            for _, item in pairs(v) do
                if type(item) == "string" then return item end
            end
        end
        return nil
    end

    local function AsStringList(v)
        local list = {}
        if type(v) == "string" then
            table.insert(list, v)
        elseif type(v) == "table" then
            for _, item in pairs(v) do
                if type(item) == "string" then
                    table.insert(list, item)
                end
            end
        end
        return list
    end

    local SaveMoonSetting, LoadMoonSetting

    SaveMoonSetting = function(name)
        if not name or name == "" then
            _G.SeaNotify("❌ Empty save name", "Enter a name first!", 3)
            return
        end

        EnsureFolder()

        local mainWeapon  = AsString(_G.MainWeapon) or "Melee"
        local supportList = AsStringList(_G.Select_EquipWeapon)

        local cleanSupport = {}
        local seen = {}
        for _, v in ipairs(supportList) do
            if v ~= mainWeapon and not seen[v] then
                seen[v] = true
                table.insert(cleanSupport, v)
            end
        end

        local data = {
            HitPosition    = AsString(_G.MoonHitPosition) or "Upper",
            HitDistance    = tonumber(_G.MoonHitDistance) or 12,
            MainWeapon     = mainWeapon,
            SupportWeapons = cleanSupport,
            RaidAutoAttack = _G.RaidAutoAttack and true or false,
            RaidAutoSkill  = _G.RaidAutoSkill and true or false,
            AutoSkillZ     = _G.AutoSkillZ and true or false,
            AutoSkillX     = _G.AutoSkillX and true or false,
            AutoSkillC     = _G.AutoSkillC and true or false,
            AutoSkillV     = _G.AutoSkillV and true or false,
            AutoSkillF     = _G.AutoSkillF and true or false,
        }

        local ok, err = pcall(function()
            writefile(GetSavePath(name), HttpService:JSONEncode(data))
        end)

        if ok then
            _G.SeaNotify("✅ Saved", "Save: " .. name, 3)
        else
            _G.SeaNotify("❌ Save error", tostring(err), 4)
        end
    end

    LoadMoonSetting = function(name)
        if not name or name == "" then
            _G.SeaNotify("❌ Empty save name", "Choose a save first!", 3)
            return false
        end

        if not isfile(GetSavePath(name)) then
            _G.SeaNotify("❌ Not found", "Save: " .. name, 3)
            return false
        end

        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(GetSavePath(name)))
        end)

        if not ok or type(data) ~= "table" then
            _G.SeaNotify("❌ File read error", name, 3)
            return false
        end

        _G.MoonHitPosition    = AsString(data.HitPosition) or "Upper"
        _G.MoonHitDistance    = tonumber(data.HitDistance) or 12
        _G.MainWeapon         = AsString(data.MainWeapon) or "Melee"
        _G.Select_EquipWeapon = AsStringList(data.SupportWeapons)
        _G.RaidAutoAttack     = data.RaidAutoAttack and true or false
        _G.RaidAutoSkill      = data.RaidAutoSkill and true or false
        _G.AutoSkillZ         = data.AutoSkillZ and true or false
        _G.AutoSkillX         = data.AutoSkillX and true or false
        _G.AutoSkillC         = data.AutoSkillC and true or false
        _G.AutoSkillV         = data.AutoSkillV and true or false
        _G.AutoSkillF         = data.AutoSkillF and true or false

        _G.SeaNotify("✅ Loaded", "Save: " .. name, 3)
        return true
    end

    local function FindRocketTower()
        if MoonRocketTower and MoonRocketTower.Parent and MoonRocketPos then
            if tick() - MoonRocketLastCheck < MOON_ROCKET_CACHE then
                return MoonRocketPos
            end
        end

        local rocket = workspace:FindFirstChild("island")
        if rocket then rocket = rocket:FindFirstChild("Moon") end
        if rocket then rocket = rocket:FindFirstChild("RocketTower") end

        if not rocket then return nil end

        local pos
        if rocket:IsA("Model") then
            local part = rocket:FindFirstChild("HumanoidRootPart")
                or rocket.PrimaryPart
                or rocket:FindFirstChildWhichIsA("BasePart")
            if part then pos = part.Position end
        elseif rocket:IsA("BasePart") then
            pos = rocket.Position
        end

        if pos then
            MoonRocketTower     = rocket
            MoonRocketPos       = pos
            MoonRocketLastCheck = tick()
            return pos
        end
        return nil
    end

    local function GetMobFolder()
        return workspace:FindFirstChild("Mob") or workspace:FindFirstChild("Mobs")
    end

    local function IsMobValid(mob)
        if not mob or not mob.Parent then return false end
        if not mob:IsA("Model") then return false end
        local hum = mob:FindFirstChild("Humanoid")
        local hrp = mob:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return false end
        if hum.Health <= 0 or hum.MaxHealth <= 0 then return false end
        return true
    end

    local function GetMoonTarget()
        local char = LocalPlayer.Character
        local myHrp = char and char:FindFirstChild("HumanoidRootPart")
        if not myHrp then return nil end

        local mobFolder = GetMobFolder()
        if not mobFolder then return nil end

        if MoonCurrentTarget and MoonCurrentTarget.Parent then
            local h = MoonCurrentTarget:FindFirstChild("Humanoid")
            if h and h.Health > 0 and h.MaxHealth > 0 then
                return MoonCurrentTarget, "🎯 ATTACKING"
            end
            MoonCurrentTarget = nil
        end

        local basePos = FindRocketTower()
        local bestTarget, bestDist = nil, math.huge

        for _, mob in ipairs(mobFolder:GetChildren()) do
            if IsMobValid(mob) then
                local mPos = mob.HumanoidRootPart.Position
                if basePos then
                    local d = (basePos - mPos).Magnitude
                    if d < bestDist then
                        bestDist   = d
                        bestTarget = mob
                    end
                end
            end
        end

        if not bestTarget then
            local minPDist = math.huge
            for _, mob in ipairs(mobFolder:GetChildren()) do
                if IsMobValid(mob) then
                    local dp = (myHrp.Position - mob.HumanoidRootPart.Position).Magnitude
                    if dp < minPDist then
                        minPDist   = dp
                        bestTarget = mob
                    end
                end
            end
        end

        return bestTarget, bestTarget and "🎯 DEFEND ROCKETTOWER" or nil
    end

    local function GetHitOffset(mobHrp, myHrp)
        local dist = _G.MoonHitDistance or 12
        local mode = _G.MoonHitPosition or "Upper"

        if mode == "Upper" then
            return Vector3.new(dist * 0.1, dist, 0)
        elseif mode == "Below" then
            return Vector3.new(dist * 0.1, -dist, 0)
        elseif mode == "Behind" then
            local look = mobHrp.CFrame.LookVector
            if look.Magnitude > 0.01 then
                return -look * dist
            end
            if myHrp then
                local dir = (mobHrp.Position - myHrp.Position).Unit
                return dir * dist
            end
            return Vector3.new(0, 0, dist)
        elseif mode == "Front" then
            local look = mobHrp.CFrame.LookVector
            if look.Magnitude > 0.01 then
                return look * dist
            end
            if myHrp then
                local dir = (myHrp.Position - mobHrp.Position).Unit
                return dir * dist
            end
            return Vector3.new(0, 0, -dist)
        end
        return Vector3.new(0, dist, 0)
    end

    local function ClearConstraints(hrp)
        if not hrp then return end
        for _, child in ipairs(hrp:GetChildren()) do
            if child:IsA("BodyPosition")
               or child:IsA("BodyGyro")
               or child:IsA("AlignPosition")
               or child:IsA("AlignOrientation")
               or child:IsA("BodyVelocity") then
                child:Destroy()
            end
        end
    end

    local function AttachToMob(hrp, mobHrp)
        if not hrp or not hrp.Parent or not mobHrp or not mobHrp.Parent then return end

        ClearConstraints(hrp)

        hrp.Anchored = false
        local char = hrp.Parent
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = false end

        local offset = GetHitOffset(mobHrp, hrp)
        local mobPos = mobHrp.Position + offset
        local lookAt = mobHrp.Position

        MoonJitterSeed = MoonJitterSeed + 1
        local jX = math.sin(MoonJitterSeed * 0.7) * 0.05
        local jY = math.cos(MoonJitterSeed * 0.9) * 0.03
        local jZ = math.sin(MoonJitterSeed * 1.1) * 0.05

        local finalPos = mobPos + Vector3.new(jX, jY, jZ)

        hrp.CFrame = CFrame.new(finalPos, lookAt)
        hrp.AssemblyLinearVelocity  = hrp.AssemblyLinearVelocity * 0.3
        hrp.AssemblyAngularVelocity = Vector3.zero
    end

    local function StopAttach(hrp)
        if not hrp then
            hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        end
        if hrp then
            hrp.Anchored = false
            local char = hrp.Parent
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then hum.PlatformStand = false end
            ClearConstraints(hrp)
        end
    end

    local MoonAttackJitter = 0
    local function MoonAttack()
        local char = LocalPlayer.Character
        if not char then return end
        local action = ReplicatedStorage:FindFirstChild("Remotes")
        if action then action = action:FindFirstChild("Action") end
        if not action then return end

        MoonAttackJitter = MoonAttackJitter + 1
        if MoonAttackJitter % 3 == 0 then
            task.wait(math.random(1, 3) * 0.01)
        end

        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") then
                pcall(function() action:FireServer(v.Name, "hit") end)
            end
        end
    end

    local DASH_SKILLS = {z = true, x = true, c = true, v = true}

    local function ForceResetPosition(hrp, mobHrp)
        if not hrp or not hrp.Parent then return end
        if not mobHrp or not mobHrp.Parent then return end

        local offset = GetHitOffset(mobHrp, hrp)
        local mobPos = mobHrp.Position + offset
        local lookAt = mobHrp.Position

        hrp.CFrame = CFrame.new(mobPos, lookAt)
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end

    local function FireMoonSkill(hrp, mobHrp)
        local char = LocalPlayer.Character
        if not char then return end
        local Skills = {}
        if _G.AutoSkillZ then table.insert(Skills, "z") end
        if _G.AutoSkillX then table.insert(Skills, "x") end
        if _G.AutoSkillC then table.insert(Skills, "c") end
        if _G.AutoSkillV then table.insert(Skills, "v") end
        if _G.AutoSkillF then table.insert(Skills, "f") end
        if #Skills == 0 then return end

        local Skill = Skills[math.random(#Skills)]
        local action = ReplicatedStorage:FindFirstChild("Remotes")
        if action then action = action:FindFirstChild("Action") end
        if not action then return end

        for _, Tool in ipairs(char:GetChildren()) do
            if Tool:IsA("Tool") then
                pcall(function() action:FireServer(Tool.Name, Skill) end)
            end
        end

        if DASH_SKILLS[Skill] and hrp and mobHrp then
            task.spawn(function()
                task.wait(0.05)
                ForceResetPosition(hrp, mobHrp)
                task.wait(0.05)
                ForceResetPosition(hrp, mobHrp)
            end)
        end
    end

    function MoonEquipWeapon()
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end

            local mainWeapon = AsString(_G.MainWeapon) or "Melee"
            local supportWeapons = AsStringList(_G.Select_EquipWeapon)

            local wantedTypes = {}
            wantedTypes[mainWeapon] = true
            for _, w in ipairs(supportWeapons) do
                if type(w) == "string" then
                    wantedTypes[w] = true
                end
            end

            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("Tool") then
                    local toolType = v:GetAttribute("Type")
                    if not wantedTypes[toolType] then
                        v.Parent = LocalPlayer.Backpack
                    end
                end
            end

            local backpack = LocalPlayer:FindFirstChild("Backpack")
            if backpack then
                for _, v in ipairs(backpack:GetChildren()) do
                    if v:IsA("Tool") then
                        local toolType = v:GetAttribute("Type")
                        if wantedTypes[toolType] then
                            v.Parent = char
                        end
                    end
                end
            end
        end)
    end

    task.spawn(function()
        while task.wait(0.03) do
            if not MoonRunning then
                if MoonLastRunning then
                    MoonLastRunning = false
                    MoonCurrentTarget = nil
                    MoonLastAction = 0
                    MoonAtCave = false
                    MoonLastMobHealth = 0
                    MoonStuckCount = 0

                    local char = LocalPlayer.Character
                    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.Anchored = false end
                    local hum = char and char:FindFirstChild("Humanoid")
                    if hum then hum.PlatformStand = false end
                end
                continue
            end

            if not MoonLastRunning then
                MoonLastRunning = true
                MoonCurrentTarget = nil
                MoonLastAction = tick()
                MoonAtCave = false
                MoonLastMobHealth = 0
                MoonStuckCount = 0
            end

            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")

            if not hum or not hrp or hum.Health <= 0 then
                if hrp then hrp.Anchored = false end
                if hum then hum.PlatformStand = false end
                continue
            end

            if MoonLastAction > 0 and tick() - MoonLastAction > MOON_WATCHDOG then
                MoonCurrentTarget = nil
                MoonLastAction = tick()
            end

            local target, priorityText = GetMoonTarget()

            if not target then
                _G.CanAutoSkill = false

                if not MoonAtCave then
                    MoonStatusPara:SetTitle("⏳ Waiting for mob...")
                    MoonStatusPara:SetContent("Standing at cave waiting for mob")
                    MoonCurrentTarget = nil

                    hrp.CFrame = CFrame.new(CAVE_POS)
                    hrp.AssemblyLinearVelocity  = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero

                    StopAttach(hrp)
                    MoonAtCave = true
                else
                    local breathe = math.sin(tick() * 2) * 0.15
                    hrp.CFrame = hrp.CFrame + Vector3.new(0, breathe * 0.1, 0)
                end

                task.wait(0.3)
                continue
            end

            _G.CanAutoSkill = true

            if target ~= MoonCurrentTarget then
                MoonCurrentTarget = target
                MoonSettleTime = tick()
                MoonLastAction = tick()
                MoonAtCave = false
                MoonLastMobHealth = 0
                MoonStuckCount = 0

                StopAttach(hrp)

                local tHrp = target.HumanoidRootPart
                if tHrp and hrp then
                    local offset = GetHitOffset(tHrp, hrp)
                    local mobPos = tHrp.Position + offset
                    local lookAt = tHrp.Position

                    hrp.CFrame = CFrame.new(mobPos, lookAt)
                    hrp.AssemblyLinearVelocity  = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end

            local tHrp = target.HumanoidRootPart
            if not tHrp then
                task.wait(0.05)
                continue
            end

            target.Humanoid.WalkSpeed = 0
            target.Humanoid.JumpPower = 0

            AttachToMob(hrp, tHrp)

            MoonLastAction = tick()

            local nowHealth = target.Humanoid.Health
            if MoonLastMobHealth == 0 then
                MoonLastMobHealth = nowHealth
                MoonDamageCheckTime = tick()
            else
                local elapsed = tick() - MoonDamageCheckTime
                if elapsed >= MOON_STUCK_THRESHOLD then
                    local hpDelta = MoonLastMobHealth - nowHealth

                    if hpDelta < 1 then
                        if tick() - MoonLastStuckTime >= MOON_STUCK_COOLDOWN then
                            MoonStuckCount = MoonStuckCount + 1
                            MoonLastStuckTime = tick()

                            if hrp then
                                hrp.CFrame = hrp.CFrame + Vector3.new(
                                    (math.random() - 0.5) * 1,
                                    math.random() * 0.5,
                                    (math.random() - 0.5) * 1
                                )
                            end

                            if MoonStuckCount >= MOON_STUCK_MAX then
                                _G.SeaNotify("🛑 Anti-cheat", "Auto Farm disabled. Wait 30s!", 8)
                                MoonRunning = false
                                break
                            end
                        end
                    else
                        MoonStuckCount = 0
                    end

                    MoonLastMobHealth = nowHealth
                    MoonDamageCheckTime = tick()
                end
            end

            MoonStatusPara:SetTitle(priorityText .. ": " .. target.Name)
            MoonStatusPara:SetContent(string.format("HP: %d / %d | Dist: %d | Stuck: %d/%d",
                math.floor(target.Humanoid.Health),
                math.floor(target.Humanoid.MaxHealth),
                math.floor((hrp.Position - tHrp.Position).Magnitude),
                MoonStuckCount, MOON_STUCK_MAX))

            local now = tick()

            if now - MoonLastEquip >= 0.5 then
                MoonLastEquip = now
                MoonEquipWeapon()
            end

            if _G.AutoCombat then
                if MoonRunning and MoonCurrentTarget then
                    local hasSkill = _G.AutoSkillZ or _G.AutoSkillX
                                  or _G.AutoSkillC or _G.AutoSkillV or _G.AutoSkillF
                    if hasSkill then
                        -- Skill loop fires separately
                    else
                        if now - MoonLastAttack >= 0.15 then
                            MoonLastAttack = now
                            MoonAttack()
                        end
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while task.wait(0.05) do
            if not MoonRunning then continue end
            if not _G.RaidAutoSkill then continue end
            if not _G.CanAutoSkill then continue end

            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp or hum.Health <= 0 then continue end

            if not MoonCurrentTarget or not MoonCurrentTarget.Parent then continue end
            local tHrp = MoonCurrentTarget:FindFirstChild("HumanoidRootPart")
            if not tHrp then continue end

            local dist = (hrp.Position - tHrp.Position).Magnitude
            if dist > 40 then continue end

            if tick() - MoonSettleTime < MOON_SETTLE_DELAY then continue end

            FireMoonSkill(hrp, tHrp)
            task.wait(0.1 + math.random() * 0.1)
        end
    end)

    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                if not MoonRunning then return end
                local char = LocalPlayer.Character
                if not char then return end
                if not char:FindFirstChild("HakiFolder") then
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                    local action = remotes and remotes:FindFirstChild("Action")
                    if action then action:FireServer("Misc", "buso") end
                end
            end)
        end
    end)

    task.spawn(function()
        task.wait(2)
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            if not char:FindFirstChild("HakiFolder") then
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                local action = remotes and remotes:FindFirstChild("Action")
                if action then
                    action:FireServer("Misc", "buso")
                end
            end
        end)
    end)

    -- MOON UI
    MoonFarm:Toggle({
        Title = "🌙 Auto Farm Moon Mob",
        Value = false,
        Callback = function(v)
            if v == MoonRunning then return end
            MoonRunning = v
            MoonStatusPara:SetTitle(v and "Status: FARMING" or "Status: Disabled")
            MoonStatusPara:SetContent(v and "Searching mob..." or "Re-enable to continue")
        end
    })

    MoonFarm:Dropdown({
        Title = "🎯 Hit Position",
        Options = {"Upper", "Below", "Behind", "Front"},
        Multi = false,
        Value = "Upper",
        Callback = function(v)
            local val = AsString(v)
            if not val then return end
            _G.MoonHitPosition = val
        end
    })

    MoonFarm:Slider({
        Title = "📏 Hit Distance",
        Min = 5, Max = 40, Value = 12,
        Callback = function(v)
            if type(v) == "number" then
                _G.MoonHitDistance = v
            end
        end
    })

    MoonWeapon:Dropdown({
        Title = "🗡️ Main Weapon",
        Options = {"Melee", "Sword", "Special", "DevilFruit"},
        Id = "MAINWEAPON",
        Multi = false,
        Value = "Melee",
        Callback = function(v)
            local val = AsString(v)
            if not val then return end
            _G.MainWeapon = val
        end
    })

    MoonWeapon:Dropdown({
        Title = "🗡️ Support Weapons",
        Options = {"Melee", "Sword", "Special", "DevilFruit"},
        Id = "SUPWEAPON",
        Multi = true,
        Callback = function(v)
            local list = AsStringList(v)
            _G.Select_EquipWeapon = list
        end
    })

    MoonSkills:Toggle({
        Title = "⚔️ Auto Attack + Skill (Skill First)",
        Id = "AutoAttackSkill",
        Value = false,
        Callback = function(v)
            _G.AutoCombat     = v
            _G.RaidAutoAttack = v
            _G.RaidAutoSkill  = v
        end
    })
    MoonSkills:Toggle({Title = "Auto Skill Z", Id = "SkillsZ", Value = false, Callback = function(v) _G.AutoSkillZ = v end})
    MoonSkills:Toggle({Title = "Auto Skill X", Id = "SkillsX", Value = false, Callback = function(v) _G.AutoSkillX = v end})
    MoonSkills:Toggle({Title = "Auto Skill C", Id = "SkillsC", Value = false, Callback = function(v) _G.AutoSkillC = v end})
    MoonSkills:Toggle({Title = "Auto Skill V", Id = "SkillsV", Value = false, Callback = function(v) _G.AutoSkillV = v end})
    MoonSkills:Toggle({Title = "Auto Skill F", Id = "SkillsF", Value = false, Callback = function(v) _G.AutoSkillF = v end})

    MoonTravel:Button({
        Title = "🌍 Back To Earth",
        Callback = function()
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then
                _G.SeaNotify("❌ No character", "Character not loaded", 3)
                return
            end

            local npcPrompt = workspace:FindFirstChild("NpcPrompt")
            local backEarth = npcPrompt and npcPrompt:FindFirstChild("BackEarth")
            if not backEarth then
                _G.SeaNotify("❌ NPC not found", "BackEarth doesn't exist", 3)
                return
            end

            local npcHrp = backEarth:FindFirstChild("HumanoidRootPart")
            if not npcHrp then return end

            hrp.CFrame = CFrame.new(npcHrp.Position + Vector3.new(0, 2, 0))
            hrp.AssemblyLinearVelocity  = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero

            task.wait(0.4)

            local prompt = npcHrp:FindFirstChildWhichIsA("ProximityPrompt", true)
            if not prompt then
                prompt = backEarth:FindFirstChildWhichIsA("ProximityPrompt", true)
            end
            if not prompt then
                _G.SeaNotify("❌ No prompt", "", 4)
                return
            end

            pcall(function() fireproximityprompt(prompt, prompt.HoldDuration + 0.1) end)
            task.wait(0.3)
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration + 0.15)
                prompt:InputHoldEnd()
            end)
            task.wait(0.3)
            pcall(function()
                if prompt.Triggered then prompt.Triggered:Fire(LocalPlayer) end
            end)

            _G.SeaNotify("✅ Activated", "Waiting for map change...", 5)
        end
    })

    local MoonSettingTab  = Window:CreateTab("⚙️ Setting", false, false)
    local MoonSettingPage = MoonSettingTab:CreatePage("Save / Load")

    local SaveLoadCard = MoonSettingPage:CreateSection("💾 Save Manager", "Left")
    local InfoCard     = MoonSettingPage:CreateSection("📋 Information", "Right")

    InfoCard:Paragraph({
        Title = "📖 Guide",
        Content = "1. Enter Save name → SAVE\n2. Pick Save from dropdown → LOAD\n3. Delete with 🗑️ button"
    })

    local SaveListPara = InfoCard:Paragraph({
        Title = "📁 Existing saves:",
        Content = "(no save yet)"
    })

    local SelectedSave = ""

    local RefreshSaveDropdown
    RefreshSaveDropdown = function()
        local list = GetSaveList()

        if #list == 0 then
            SaveListPara:SetContent("(no save yet)")
        else
            local text = ""
            for i, name in ipairs(list) do
                text = text .. "\n  " .. i .. ". " .. name
            end
            SaveListPara:SetContent(text)
        end

        if SaveDropdown and SaveDropdown.Set then
            pcall(function()
                if #list > 0 then
                    SaveDropdown:Set(list)
                else
                    SaveDropdown:Set({})
                end
            end)
        end
    end

    local NewSaveName = ""
    SaveLoadCard:Textbox({
        Title = "✏️ New Save Name",
        Placeholder = "e.g. Save1",
        Value = "",
        Callback = function(v)
            if type(v) == "string" then
                NewSaveName = v
            end
        end
    })

    local SaveDropdown = SaveLoadCard:Dropdown({
        Title = "📁 Choose Save",
        Options = GetSaveList(),
        Multi = false,
        Value = "",
        Callback = function(v)
            local val = AsString(v)
            if not val or val == "" then return end
            if val == "(no save yet)" then return end
            SelectedSave = val
        end
    })

    RefreshSaveDropdown()

    SaveLoadCard:Button({
        Title = "💾 SAVE",
        Callback = function()
            if NewSaveName == "" then
                _G.SeaNotify("❌ Name not entered", "Enter save name!", 3)
                return
            end

            SaveMoonSetting(NewSaveName)
            SelectedSave = NewSaveName
            RefreshSaveDropdown()

            task.delay(0.3, function()
                SelectedSave = NewSaveName
            end)
        end
    })

    SaveLoadCard:Button({
        Title = "📂 LOAD",
        Callback = function()
            local saveToLoad = SelectedSave

            if saveToLoad == "" then
                local list = GetSaveList()
                if #list > 0 then
                    saveToLoad = list[1]
                end
            end

            if saveToLoad == "" then
                _G.SeaNotify("❌ No save yet", "No save file!", 3)
                return
            end

            if LoadMoonSetting(saveToLoad) then
                _G.SeaNotify("💡 Reminder", "Toggle Auto Farm to apply", 4)
            end
        end
    })

    SaveLoadCard:Button({
        Title = "🗑️ Delete Save",
        Callback = function()
            local saveToDelete = SelectedSave

            if saveToDelete == "" then
                local list = GetSaveList()
                if #list > 0 then
                    saveToDelete = list[1]
                end
            end

            if saveToDelete == "" then
                _G.SeaNotify("❌ No Save selected", "No save to delete!", 3)
                return
            end

            local path = GetSavePath(saveToDelete)
            if isfile(path) then
                delfile(path)
                _G.SeaNotify("✅ Deleted", saveToDelete, 3)
                SelectedSave = ""
                RefreshSaveDropdown()
            else
                _G.SeaNotify("❌ None", saveToDelete, 3)
            end
        end
    })

    SaveLoadCard:Button({
        Title = "🔄 Refresh List",
        Callback = function()
            RefreshSaveDropdown()
            _G.SeaNotify("✅ Refreshed", "Save list", 2)
        end
    })

end

-- ============================================================
-- NON-MOON MAP → FULL UI
-- ============================================================
if not IS_MOON_MAP then

-- ============================================================
-- TRACK DASH SKILLS
-- ============================================================
_G.LastSkillTime = 0
_G.LastSkillKey  = ""
_G.DASH_SKILLS   = {x = true}
_G.DASH_NEGATE_TIME = 0.35

-- ============================================================
-- AUTO SKILL v132 — REMOVE BODYMOVER + DO NOT BLOCK CFrame
-- ============================================================
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

        local Skill = Skills[math.random(#Skills)]

        _G.LastSkillTime = tick()
        _G.LastSkillKey  = Skill

        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local action = remotes and remotes:FindFirstChild("Action")
        if not action then return end

        for _, Tool in ipairs(char:GetChildren()) do
            if Tool:IsA("Tool") then
                action:FireServer(Tool.Name, Skill)
            end
        end

        if _G.ClearDashBodyMovers and hrp then
            _G.ClearDashBodyMovers(hrp, 0.8)
        end
    end)
end

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
                    if child.Name == "Fly"
                       or child.Name == "BodyVelocity"
                       or child.Name == "DashVelocity"
                       or child.Name == "AntiDashBV" then
                        pcall(function() child:Destroy() end)
                    end
                elseif child:IsA("BodyGyro") then
                    if child.Name == "BodyGyro"
                       or child.Name == "DashGyro" then
                        pcall(function() child:Destroy() end)
                    end
                elseif child:IsA("AlignPosition") then
                    if child.Name == "AlignPosition"
                       or child.Name == "DashAlign" then
                        pcall(function() child:Destroy() end)
                    end
                end
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
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
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local action = remotes and remotes:FindFirstChild("Action")
        if not action then return end
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") then
                action:FireServer(v.Name, "hit")
            end
        end
    end)
end

-- ============================================================
-- NO VFX v3 — EVENT-DRIVEN, NO LAG
-- ============================================================
local VFX_CONNECTIONS = {}
local VFX_KILL_CLASSES = {
    ["ParticleEmitter"] = true,
    ["Beam"] = true,
    ["Trail"] = true,
    ["Sparkles"] = true,
    ["Fire"] = true,
    ["Smoke"] = true,
    ["Highlight"] = true,
    ["PointLight"] = true,
    ["SpotLight"] = true,
    ["SurfaceLight"] = true,
}

local function TryKillVFX(obj)
    if not obj or not obj.Parent then return end
    local cls = obj.ClassName
    if not VFX_KILL_CLASSES[cls] then return end

    pcall(function()
        if cls == "ParticleEmitter" or cls == "Beam" or cls == "Trail"
           or cls == "Sparkles" or cls == "Fire" or cls == "Smoke" then
            if obj.Enabled then obj.Enabled = false end
        elseif cls == "Highlight" then
            if obj.Enabled then obj.Enabled = false end
        elseif cls == "PointLight" or cls == "SpotLight" or cls == "SurfaceLight" then
            if obj.Enabled then obj.Enabled = false end
        end
    end)
end

local function KillVFXIn(container)
    if not container then return end
    pcall(function()
        for _, v in ipairs(container:GetDescendants()) do
            TryKillVFX(v)
        end
    end)
end

local function HookContainer(container)
    if not container then return end
    local conn = container.DescendantAdded:Connect(function(obj)
        if _G.VFXDisabled then
            TryKillVFX(obj)
        end
    end)
    table.insert(VFX_CONNECTIONS, conn)
end

local function NoVFX(State)
    _G.VFXDisabled = State

    for _, conn in ipairs(VFX_CONNECTIONS) do
        pcall(function() conn:Disconnect() end)
    end
    VFX_CONNECTIONS = {}

    if not State then return end

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

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ============================================================
-- TAB 1: SETTINGS
-- ============================================================
local Tab1       = Window:CreateTab("Settings", true, false)
local Tab_Page1  = Tab1:CreatePage("Main Settings")
local Weapon     = Tab_Page1:CreateSection("🗡️ Select Weapon", "Left")
local AutoSkills = Tab_Page1:CreateSection("⚔️ Auto Skills", "Left")
local Method     = Tab_Page1:CreateSection("🎯 Select Method Farm", "Right")
local Haki       = Tab_Page1:CreateSection("👁️ Haki", "Right")
local VFX        = Tab_Page1:CreateSection("✨ VFX", "Right")
local Tab_Page2  = Tab1:CreatePage("Other Settings")
local Accessory  = Tab_Page2:CreateSection("🎒 Accessory & Rebirth", "Right")
local Potion     = Tab_Page2:CreateSection("🧪 Auto Use X2 Potion", "Left")

Weapon:Dropdown({
    Title = "Main Weapon (Attack)", Options = TypeTool, Multi = false, Value = "Melee",
    Callback = function(Value) _G.MainWeapon = Value end
})
Weapon:Dropdown({
    Title = "Select Support Weapon", Options = TypeTool, Multi = true,
    Callback = function(Value) _G.Select_EquipWeapon = Value end
})
AutoSkills:Toggle({
    Title = "⚔️ Auto Attack + Skill (Skill First)",
    Id = "AATACKSKILLAOTU",
    Value = false,
    Callback = function(v)
        _G.AutoCombat     = v
        _G.RaidAutoAttack = v
        _G.RaidAutoSkill  = v
    end
})
AutoSkills:Paragraph({
    Title = "ℹ️ Mechanism",
    Content = "• Prioritize Skill (Z/X/C/V/F enabled)\n• Skill out → auto normal attack\n• Only need 1 toggle"
})
AutoSkills:Toggle({Title = "Auto Skill Z", Id = "SKILLZ", Value = false, Callback = function(v) _G.AutoSkillZ = v end})
AutoSkills:Toggle({Title = "Auto Skill X", Id = "SKILLX", Value = false, Callback = function(v) _G.AutoSkillX = v end})
AutoSkills:Toggle({Title = "Auto Skill C", Id = "SKILLC", Value = false, Callback = function(v) _G.AutoSkillC = v end})
AutoSkills:Toggle({Title = "Auto Skill V", Id = "SKILLV", Value = false, Callback = function(v) _G.AutoSkillV = v end})
AutoSkills:Toggle({Title = "Auto Skill F", Id = "SKILLF", Value = false, Callback = function(v) _G.AutoSkillF = v end})
Haki:Toggle({Title = "Auto Enable Haki", Id = "AENHAKI", Value = false, Callback = function(v) _G.Auto_Haki = v end})

Method:Dropdown({
    Title = "Select Farm Method",
    Options = {"Behind", "Below", "Upper", "Front"},
    Id = "SELEMETHODFARM",
    Multi = false, Value = "Upper",
    Callback = function(v) _G.Select_Method = v end
})
Method:Slider({
    Title = "Farm Distance", Min = 0, Max = 30, Value = 5,
    Callback = function(v) _G.Distance_Farm = v end
})
VFX:Toggle({Title = "Disable VFX", Value = false, Callback = function(v) NoVFX(v) end})

Accessory:Toggle({
    Title = "Auto Equip Best Accessory", Value = false,
    Callback = function(v) _G.Auto_Equip_Accessory = v end
})
Accessory:Toggle({
    Title = "Auto Rebirth (Max Level)", Value = false,
    Callback = function(v) _G.Auto_Rebirth = v end
})

Potion:Dropdown({
    Title = "Select X2 Potion",
    Options = X2List,
    Multi = false,
    Callback = function(v)
        local val = v
        if type(val) == "table" then
            local real = nil
            for _, item in pairs(val) do
                if type(item) == "string" and item ~= "" then
                    real = item
                    break
                end
            end
            val = real
        end
        if type(val) ~= "string" or val == "" then
            _G.Select_Potion = nil
            return
        end
        _G.Select_Potion = val
    end
})

Potion:Textbox({
    Title = "Amount (1-100)",
    Placeholder = "1",
    Value = "1",
    Callback = function(v)
        local n = tonumber(v) or 1
        if n < 1 then n = 1 end
        if n > 100 then n = 100 end
        _G.PotionAmount = n
    end
})

Potion:Button({
    Title = "🧪 USE X2 POTION (once)",
    Callback = function()
        local potionName = _G.Select_Potion
        local amount = tonumber(_G.PotionAmount) or 1

        if amount < 1 then amount = 1 end
        if amount > 100 then amount = 100 end
        _G.PotionAmount = amount

        if type(potionName) == "table" then
            local real = nil
            for _, v in pairs(potionName) do
                if type(v) == "string" and v ~= "" then
                    real = v
                    break
                end
            end
            potionName = real
        end

        if type(potionName) ~= "string" or potionName == "" then
            _G.SeaNotify("❌ No Potion selected", "Choose an X2 Potion first!", 3)
            return
        end

        local Inv = GetInventory()
        local have = (Inv[potionName] and Inv[potionName].amount) or 0

        if have <= 0 then
            _G.SeaNotify("❌ No Potion", potionName .. " (0)", 3)
            return
        end

        local useCount = math.min(amount, have)
        local remote = ReplicatedStorage:FindFirstChild("Remotes")
        remote = remote and remote:FindFirstChild("Inventory")
        if not remote then
            _G.SeaNotify("❌ Remote not found", "Remotes.Inventory", 3)
            return
        end

        task.spawn(function()
            for i = 1, useCount do
                pcall(function()
                    remote:FireServer(potionName)
                end)
                task.wait(0.15)
            end
        end)

        _G.SeaNotify("🧪 Using Potion",
            potionName .. " x" .. useCount .. " (have " .. have .. ")", 4)
    end
})

-- ============================================================
-- TAB 2: MAIN
-- ============================================================
local Tab2            = Window:CreateTab("Main", false, false)
local Farm            = Tab2:CreatePage("Farm")
local AllBoss         = Tab2:CreatePage("Boss")
local RaidBossPage    = Tab2:CreatePage("Raid Boss & Shop")
local RaidDun         = Tab2:CreatePage("Dungeon, Shop / Weapon")

local AutoFarmCard    = Farm:CreateSection("🌾 Auto Farm", "Left")
local MaterialCard    = Farm:CreateSection("⛏️ Auto Farm Material", "Right")
local Boss            = AllBoss:CreateSection("👹 Boss", "Left")
local Thief           = AllBoss:CreateSection("💸 Thief", "Left")
local Piccolo         = AllBoss:CreateSection("🐉 Piccolo", "Left")
local SpawnedT        = AllBoss:CreateSection("🔍 Spawned Check", "Right")
local Duck            = AllBoss:CreateSection("🦆 Duck", "Right")
local DevilBoat       = AllBoss:CreateSection("⛵ Devil Boat", "Right")
local DungeonCard     = RaidDun:CreateSection("🏰 Auto Dungeon", "Left")
local ShopDunCard     = RaidDun:CreateSection("🏪 Shop Dungeon", "Left")
local WeaponCraft     = RaidDun:CreateSection("🔨 Weapon", "Left")
local DungeonSettingsCard = RaidDun:CreateSection("⚙️ Dungeon Settings", "Right")
local ShopDunInfoCard = RaidDun:CreateSection("📊 Shop Dungeon Info", "Right")
local RaidCard        = RaidDun:CreateSection("🌋 Auto Raid Moon", "Right")
local RaidBossCard    = RaidBossPage:CreateSection("⚔️ Auto Raid Boss", "Left")
local RaidBossInfoCard= RaidBossPage:CreateSection("📋 Raid Info", "Right")
local ShopRaidCard    = RaidBossPage:CreateSection("🏪 Shop Raid", "Left")
local ShopRaidInfoCard= RaidBossPage:CreateSection("📊 Shop Info", "Right")
local RaidSettingsCard= RaidBossPage:CreateSection("⚙️ Raid Settings", "Right")
local TimeMysteryCard = RaidBossPage:CreateSection("🎁 Time Mystery Box", "Left")

AutoFarmCard:Toggle({
    Title = "Auto Level Farm",
    Value = false,
    Callback = function(v)
        _G.Auto_Farm_Level = v
        if v then
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
        end
    end
})
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
    Title = "Auto Farm Material", Value = false,
    Callback = function(v) _G.Auto_Farm_Material = v end})
Boss:Dropdown({
    Title = "Select Boss", Options = Bosses, Multi = false,
    Callback = function(v) _G.Select_Boss = v end
})
Boss:Toggle({Title = "Auto Farm All Boss (Full)", Value = false, Callback = function(v) _G.Auto_FarmBoss = v end})
Thief:Toggle({Title = "Auto Farm Thief Chest", Value = false, Callback = function(v) _G.Auto_BaconThief = v end})
Piccolo:Toggle({Title = "Auto Farm Piccolo", Value = false, Callback = function(v) _G.Auto_Piccolo = v end})
Duck:Toggle({Title = "Auto Farm Duck (Full)", Value = false, Callback = function(v) _G.Auto_DuckAutomatically = v if v then ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel") end end
})
DevilBoat:Toggle({Title = "Auto Farm Devil Boat", Value = false, Callback = function(v) _G.Auto_DevilBoat = v end})
DevilBoat:Toggle({Title = "Auto Farm Kraken", Value = false, Callback = function(v) _G.Auto_Kraken = v end
})

local Spawn_Status = SpawnedT:Paragraph({Title = "Spawn Status", Content = "N/A"})
local Item_Auto    = WeaponCraft:Paragraph({Title = "Item Requirements ( None )", Content = "N/A"})

WeaponCraft:Dropdown({
    Title = "Select Weapon Craft", Options = WeaponAll, Multi = false,
    Callback = function(v) _G.Select_Item = v end
})
WeaponCraft:Button({
    Title = "Craft Weapon",
    Callback = function()
        local Data = UseItems and UseItems[_G.Select_Item]
        if Data then
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Craft", _G.Select_Item, Data.Type)
        end
    end
})
local NotifyClass = false
WeaponCraft:Toggle({
    Title = "Auto Craft Weapon (Full)", Value = false,
    Callback = function(v)
        _G.Auto_CraftWeapon = v
        if not v then NotifyClass = false end
    end
})
WeaponCraft:Toggle({
    Title = "Auto Farm Set Weapon", Value = false,
    Callback = function(v) _G.Auto_Farm_Set = v end
})

RaidCard:Toggle({
    Title = "Auto Raid Moon (Full)", Value = false,
    Callback = function(v)
        _G.Auto_Raid = v
        if v then
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
        end
    end
})

DungeonCard:Textbox({
    Title = "Dungeon Orb to Use", Id = "DUNOTOUSE", Placeholder = "...",
    Callback = function(v) _G.Dungeon_UseValue = tonumber(v) or 1 end
})
DungeonSettingsCard:Slider({
    Title = "Health Return %",
    Min = 1, Max = 100, Value = 30,
    Callback = function(v) _G.HealthPercent = v end
})
DungeonSettingsCard:Slider({
    Title = "Dungeon Height",
    Min = 0, Max = 100, Value = 25,
    Callback = function(v) _G.DungeonHeight = v end
})
DungeonCard:Toggle({
    Title = "🏰 Auto Dungeon (Full)",
    Value = false,
    Callback = function(v)
        _G.Auto_Dungeon = v

        if v then
            pcall(function()
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
            end)
        end
    end
})

-- ============================================================
-- RAID BOSS UI
-- ============================================================
local RaidBossData = {
    ["Bacon of Grudge"] = {
        Name = "Bacon of Grudge",
        Reward = "Time Mystery Box x5, 7500 Diamond, Beli 50M, x3 Potion",
        PortalCost = 1, Valid = true
    },
    ["Dragon"] = {
        Name = "Dragon",
        Reward = "Thunder Mystery Box x5, 15k Diamond, Beli 100M, x3 Potion",
        PortalCost = 0, Valid = true
    },
    ["Lava Titan"] = {
    Name = "Lava Titan",
    Reward = "Lava Mystery Box x5, 20k Diamond, Beli 200M, x3 Potion",
    PortalCost = 1,
    Valid = true,
    OffsetY = 25,
    },
	["??? (Raid 4)"] = {Name = "???", Reward = "SOON", PortalCost = 0, Valid = false}
}

local RaidBossInfoPara = RaidBossInfoCard:Paragraph({
    Title = "Name: ( not selected )",
    Content = "Please choose a Boss Raid!!",
    TitleSize = 18,
    ContentSize = 16,
    TextSize = 16,
})

RaidBossCard:Dropdown({
    Title = "Choose a boss to raid",
    Options = {"Bacon of Grudge", "Dragon", "Lava Titan", "??? (Raid4)"},
    Multi = false,
    Callback = function(Value)
        _G.AutoRaidWho = Value
        local Data = RaidBossData[Value]
        if Data then
            RaidBossInfoPara:SetTitle("Name: " .. Data.Name)
            RaidBossInfoPara:SetContent("Reward: " .. Data.Reward .. "\n- " .. Data.PortalCost .. " Portal Gun")
        end
    end
})
RaidBossCard:Button({
    Title = "Start Raid Now!!",
    Callback = function()
        local Data = RaidBossData[_G.AutoRaidWho]
        if not Data then
            _G.SeaNotify("❌ Raid not selected", "Please choose a Boss Raid!", 3); return
        end
        if not Data.Valid then
            _G.SeaNotify("❌ Invalid Raid", "NO RAID!!!", 3); return
        end

        -- ===== PHÂN NHÁNH THEO BOSS =====
        if _G.AutoRaidWho == "Dragon" then
            if _G.AutoRaidRunning then _G.AutoRaidRunning = false end
            if _G.AutoRaidLava then _G.AutoRaidLava = false end
            _G.AutoRaidDragon = not _G.AutoRaidDragon
            _G.SeaNotify(
                _G.AutoRaidDragon and "▶️ Start Dragon Raid" or "⏹️ Stop Dragon Raid",
                "Dragon", 3
            )
            return
        end

        if _G.AutoRaidWho == "Lava Titan" then
            if _G.AutoRaidRunning then _G.AutoRaidRunning = false end
            if _G.AutoRaidDragon then _G.AutoRaidDragon = false end
            _G.AutoRaidLava = not _G.AutoRaidLava
            _G.SeaNotify(
                _G.AutoRaidLava and "▶️ Start Lava Raid" or "⏹️ Stop Lava Raid",
                "Lava Titan", 3
            )
            return
        end

        -- Mặc định: Bacon of Grudge
        if _G.AutoRaidDragon then _G.AutoRaidDragon = false end
        if _G.AutoRaidLava then _G.AutoRaidLava = false end
        _G.AutoRaidRunning = not _G.AutoRaidRunning
        _G.SeaNotify(_G.AutoRaidRunning and "▶️ Start Raid" or "⏹️ Stop Raid", Data.Name, 3)
    end
})
RaidSettingsCard:Slider({
    Title = "Bacon of Grudge Height", Min = 0, Max = 150, Value = 55,
    Callback = function(v) _G.RaidBossOffsetY = v end
})
RaidSettingsCard:Slider({
    Title = "Golden Ball Height", Min = 0, Max = 150, Value = 25,
    Callback = function(v) _G.RaidBallOffsetY = v end
})

-- ============================================================
-- SHOP RAID UI
-- ============================================================
local ShopInfoPara = ShopRaidInfoCard:Paragraph({
    Title = "RaidPoint: ( loading... )",
    Content = "Restock In: ( loading... )"
})
local ShopItemInfo = ShopRaidInfoCard:Paragraph({
    Title = "Item: ( not selected )",
    Content = "Select item from dropdown"
})

_G.SelectedShopItem = nil
local ShopItemDropdown = nil
local LastShopItemsStr = ""
local ShopDropdownInitialized = false

local function UpdateShopDropdown(items)
    if #items == 0 then return end
    local itemsStr = table.concat(items, ",")
    if itemsStr == LastShopItemsStr and ShopItemDropdown then return end
    LastShopItemsStr = itemsStr

    if not ShopItemDropdown then
        ShopItemDropdown = ShopRaidCard:Dropdown({
            Title = "Select Items to Purchase", Options = items, Multi = false,
            Callback = function(Value)
                _G.SelectedShopItem = Value
                ShopItemInfo:SetTitle("Item: " .. Value)
                ShopItemInfo:SetContent("Selected — press BUY to purchase")
            end
        })
        ShopDropdownInitialized = true
    else
        local updated = false
        pcall(function()
            if ShopItemDropdown.Set then ShopItemDropdown:Set(items); updated = true
            elseif ShopItemDropdown.UpdateOptions then ShopItemDropdown:UpdateOptions(items); updated = true end
        end)
        if not updated then
            pcall(function() ShopItemDropdown:Destroy() end)
            ShopItemDropdown = ShopRaidCard:Dropdown({
                Title = "Select Items to Purchase", Options = items, Multi = false,
                Callback = function(Value)
                    _G.SelectedShopItem = Value
                    ShopItemInfo:SetTitle("Item: " .. Value)
                    ShopItemInfo:SetContent("Selected — press BUY to purchase")
                end
            })
        end
    end
end

ShopRaidCard:Button({
    Title = "BUY!!",
    Callback = function()
        if not _G.SelectedShopItem then
            _G.SeaNotify("❌ No item selected", "Please choose an item first!", 3); return
        end
        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "buy_raidshop", _G.SelectedShopItem)
        _G.SeaNotify("✅ Purchased", _G.SelectedShopItem, 3)
    end
})

-- ============================================================
-- 🎁 TIME MYSTERY BOX
-- ============================================================
local TimeMysteryInfo = TimeMysteryCard:Paragraph({
    Title = "🎁 Time Mystery Box: ---",
    Content = "Enter amount and press button to open"
})

TimeMysteryCard:Textbox({
    Title = "Open Amount (1-100)",
    Placeholder = "1",
    Value = "1",
    Callback = function(v)
        local n = tonumber(v) or 1
        if n < 1 then n = 1 end
        if n > 100 then n = 100 end
        _G.TimeMysteryAmount = n
        print("[TimeBox] Open Amount:", n)
    end
})

TimeMysteryCard:Button({
    Title = "🎁 OPEN TIME MYSTERY BOX (once)",
    Callback = function()
        local amount = tonumber(_G.TimeMysteryAmount) or 1

        if amount < 1 then amount = 1 end
        if amount > 100 then amount = 100 end
        _G.TimeMysteryAmount = amount

        local Inv = GetInventory()
        local have = (Inv["Time Mystery Box"] and Inv["Time Mystery Box"].amount) or 0

        if have <= 0 then
            _G.SeaNotify("❌ No Box", "Time Mystery Box (0)", 3)
            return
        end

        local useCount = math.min(amount, have)

        local NetworkEvent = ReplicatedStorage
            :FindFirstChild("Modules")
            and ReplicatedStorage.Modules
            :FindFirstChild("NetworkFramework")
            and ReplicatedStorage.Modules.NetworkFramework
            :FindFirstChild("NetworkEvent")

        if not NetworkEvent then
            _G.SeaNotify("❌ Remote not found", "NetworkEvent doesn't exist", 3)
            return
        end

        local ok = pcall(function()
            NetworkEvent:FireServer("fire", nil, "Time Mystery Box", useCount)
        end)

        if ok then
            _G.SeaNotify("🎁 Opening Box",
                "Open " .. useCount .. " box (have " .. have .. ")", 4)
            print("[TimeBox] 🎁 Open", useCount, "box | Remaining:", have - useCount)
        else
            _G.SeaNotify("❌ Fire error", "Cannot open box", 3)
        end
    end
})

-- ============================================================
-- SHOP DUNGEON UI
-- ============================================================
local ShopDunInfoPara = ShopDunInfoCard:Paragraph({
    Title = "DungeonPoint: ( loading... )",
    Content = "Select Auto Buy item on the left"
})
local ShopDunItemInfo = ShopDunInfoCard:Paragraph({
    Title = "Item: ( not selected )",
    Content = "Select item from dropdown"
})

_G.AutoBuyDunItem    = nil
_G.AutoBuyDunRunning = false
local AutoBuyDunDropdown = nil
local LastAutoBuyDunStr  = ""

local function GetAllShopDunItems()
    local items, seen = {}, {}
    local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
    if hud and hud:FindFirstChild("Main") then
        local shop = hud.Main:FindFirstChild("Frame_ShopDungeon")
        if shop then
            local sf = shop:FindFirstChild("ShopScrollingFrame")
            if sf then
                for _, item in pairs(sf:GetChildren()) do
                    if item:IsA("Frame") then
                        local main = item:FindFirstChild("Main")
                        if main then
                            local titleLbl = main:FindFirstChild("TitleLabel")
                            if titleLbl and titleLbl.Text and titleLbl.Text ~= "" then
                                if not seen[titleLbl.Text] then
                                    seen[titleLbl.Text] = true
                                    table.insert(items, titleLbl.Text)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(items)
    return items
end

local function UpdateDunDropdown(items)
    if #items == 0 then return end
    local itemsStr = table.concat(items, ",")
    if itemsStr == LastAutoBuyDunStr and AutoBuyDunDropdown then return end
    LastAutoBuyDunStr = itemsStr

    if not AutoBuyDunDropdown then
        AutoBuyDunDropdown = ShopDunCard:Dropdown({
            Title = "Auto Buy Items", Options = items, Multi = false,
            Callback = function(Value)
                _G.AutoBuyDunItem = Value
                ShopDunItemInfo:SetTitle("Item: " .. Value)
                ShopDunItemInfo:SetContent("Selected — enable Auto Buy Toggle")
            end
        })
    else
        local updated = false
        pcall(function()
            if AutoBuyDunDropdown.Set then AutoBuyDunDropdown:Set(items); updated = true
            elseif AutoBuyDunDropdown.UpdateOptions then AutoBuyDunDropdown:UpdateOptions(items); updated = true end
        end)
        if not updated then
            pcall(function() AutoBuyDunDropdown:Destroy() end)
            AutoBuyDunDropdown = ShopDunCard:Dropdown({
                Title = "Auto Buy Items", Options = items, Multi = false,
                Callback = function(Value)
                    _G.AutoBuyDunItem = Value
                    ShopDunItemInfo:SetTitle("Item: " .. Value)
                    ShopDunItemInfo:SetContent("Selected — enable Auto Buy Toggle")
                end
            })
        end
    end
end

ShopDunCard:Toggle({
    Title = "Auto Buy", Value = false,
    Callback = function(Value)
        if Value and not _G.AutoBuyDunItem then
            _G.SeaNotify("❌ No item selected", "Choose Auto Buy item first!", 3)
            _G.AutoBuyDunRunning = false
            return
        end
        _G.AutoBuyDunRunning = Value
        _G.SeaNotify(Value and "▶️ Enable Auto Buy" or "⏹️ Disable Auto Buy", _G.AutoBuyDunItem or "N/A", 3)
    end
})

-- ============================================================
-- TAB 3: OTHER
-- ============================================================
local Tab3            = Window:CreateTab("Other", false, false)
local RandomM         = Tab3:CreatePage("Random Chest")
local CraftTablePage  = Tab3:CreatePage("Craft Table")
local GokuPage        = Tab3:CreatePage("Npc Goku Gods")

-- ============================================================
-- RANDOM CHEST
-- ============================================================
local DiamondChest     = RandomM:CreateSection("💎 Diamond Chest", "Right")
local MoonChest        = RandomM:CreateSection("🌙 Moon Chest", "Left")
local GuaranteeDiamond = RandomM:CreateSection("🎖️ Guarantee Gem Point", "Right")
local GuaranteeMoon    = RandomM:CreateSection("☄️ Guarantee Moon Point", "Left")

local DiamondChestInfo = DiamondChest:Paragraph({
    Title = "💎 Diamond: ---",
    Content = "📊 PointItem: ---"
})

DiamondChest:Dropdown({
    Title = "Select Random Diamond Chest",
    Options = RandomChestValue,
    Multi = false,
    Value = "x5",
    Callback = function(v)
        local val = type(v) == "table" and (next(v) or "x5") or v
        if type(val) ~= "string" then val = "x5" end
        _G.Select_Random = val
    end
})

DiamondChest:Button({
    Title = "🎲 Open once (Random Item)",
    Callback = function()
        local val = _G.Select_Random or "x5"
        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "RandomItem", val)
        _G.SeaNotify("🎲 Opened", "RandomItem: " .. val, 2)
    end
})

DiamondChest:Toggle({
    Title = "Auto Random Diamond Chest",
    Value = false,
    Callback = function(v) _G.Auto_RandomChest = v end
})

local MoonChestInfo = MoonChest:Paragraph({
    Title = "🌙 MoonStone: ---",
    Content = "📊 MoonPoint: ---"
})

MoonChest:Dropdown({
    Title = "Select Random Moon Chest",
    Options = RandomChestValue,
    Multi = false,
    Value = "x5",
    Callback = function(v)
        local val = type(v) == "table" and (next(v) or "x5") or v
        if type(val) ~= "string" then val = "x5" end
        _G.Select_Random_Moon = val
    end
})

MoonChest:Button({
    Title = "🌙 Open once (Event Moon)",
    Callback = function()
        local val = _G.Select_Random_Moon or "x5"
        local moonStone = tonumber(LocalPlayer:GetAttribute("MoonStone")) or 0

        local costMap = {["x5"] = 25, ["x10"] = 50, ["x15"] = 75}
        local cost = costMap[val] or 25

        if moonStone < cost then
            _G.SeaNotify("❌ Not enough MoonStone", "Need " .. cost .. ", have " .. FormatNumber(moonStone), 3)
            return
        end

        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "EventMoon", val)
        _G.SeaNotify("🌙 Opened", "EventMoon: " .. val .. " (-" .. cost .. " MoonStone)", 2)
    end
})

MoonChest:Toggle({
    Title = "Auto Random Moon Chest",
    Value = false,
    Callback = function(v) _G.Auto_RandomChest_Moon = v end
})

local GuaranteeDiamondInfo = GuaranteeDiamond:Paragraph({
    Title = "💎 Diamond: ---",
    Content = "📊 PointItem: ---"
})

local GuaranteeDiamondSelectInfo = GuaranteeDiamond:Paragraph({
    Title = "Item: (not selected)",
    Content = "Price: ---"
})

GuaranteeDiamond:Dropdown({
    Title = "Select Guarantee Diamond Point",
    Options = Poitem,
    Multi = false,
    Callback = function(v)
        local val = type(v) == "table" and (next(v) or "") or v
        if type(val) ~= "string" then val = "" end
        _G.Select_Guarantee = val:match("^(.-) /") or val
    end
})

GuaranteeDiamond:Button({
    Title = "💎 BUY once",
    Callback = function()
        local itemName = _G.Select_Guarantee
        if not itemName or itemName == "" then
            _G.SeaNotify("❌ No item selected", "Please choose an item first!", 3)
            return
        end

        if type(itemName) == "table" then
            for _, v in pairs(itemName) do
                if type(v) == "string" then itemName = v; break end
            end
        end
        itemName = tostring(itemName):match("^(.-) /") or tostring(itemName)
        itemName = itemName:gsub("^%s+", ""):gsub("%s+$", "")

        local pointItem = tonumber(LocalPlayer:GetAttribute("PointItem")) or 0
        local price = (PointItemM and PointItemM[itemName]) or 0

        if price <= 0 then
            _G.SeaNotify("❌ Not found", "Item: " .. itemName, 3)
            return
        end

        if pointItem < price then
            _G.SeaNotify("❌ Not enough PointItem", "Need " .. FormatNumber(price) .. ", have " .. FormatNumber(pointItem), 3)
            return
        end

        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "BuyGaranteeRandomItem", itemName)
        _G.SeaNotify("✅ Purchased", itemName .. " (-" .. FormatNumber(price) .. " Point)", 3)
    end
})

GuaranteeDiamond:Toggle({
    Title = "Auto Buy Guarantee Diamond",
    Value = false,
    Callback = function(v) _G.Auto_Guarantee = v end
})

local GuaranteeMoonInfo = GuaranteeMoon:Paragraph({
    Title = "🌙 MoonPoint: ---",
    Content = "💠 MoonStone: ---"
})

local GuaranteeMoonSelectInfo = GuaranteeMoon:Paragraph({
    Title = "🌙 Item: (not selected)",
    Content = "Price: ---"
})

GuaranteeMoon:Dropdown({
    Title = "Select Guarantee Moon Point",
    Options = PoiteMoon,
    Multi = false,
    Callback = function(v)
        local val = type(v) == "table" and (next(v) or "") or v
        if type(val) ~= "string" then val = "" end
        _G.Select_Guarantee_Moon = val:match("^(.-) /") or val
    end
})

GuaranteeMoon:Button({
    Title = "🌙 BUY once",
    Callback = function()
        local itemName = _G.Select_Guarantee_Moon
        if not itemName or itemName == "" then
            _G.SeaNotify("❌ No item selected", "Please choose an item first!", 3)
            return
        end

        if type(itemName) == "table" then
            for _, v in pairs(itemName) do
                if type(v) == "string" then itemName = v; break end
            end
        end
        itemName = tostring(itemName):match("^(.-) /") or tostring(itemName)
        itemName = itemName:gsub("^%s+", ""):gsub("%s+$", "")

        local moonPoint = tonumber(LocalPlayer:GetAttribute("MoonPoint")) or 0
        local price = (PointItemMoon and PointItemMoon[itemName]) or 0

        if price <= 0 then
            _G.SeaNotify("❌ Not found", "Item: " .. itemName, 3)
            return
        end

        if moonPoint < price then
            _G.SeaNotify("❌ Not enough MoonPoint", "Need " .. FormatNumber(price) .. ", have " .. FormatNumber(moonPoint), 3)
            return
        end

        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "BuyGaranteeEventMoon", itemName)
        _G.SeaNotify("✅ Purchased", itemName .. " (-" .. FormatNumber(price) .. " MoonPoint)", 3)
    end
})

GuaranteeMoon:Toggle({
    Title = "Auto Buy Guarantee Moon",
    Value = false,
    Callback = function(v) _G.Auto_Guarantee_Moon = v end
})

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local diamond   = tonumber(LocalPlayer:GetAttribute("Diamond")) or 0
            local pointItem = tonumber(LocalPlayer:GetAttribute("PointItem")) or 0
            local moonStone = tonumber(LocalPlayer:GetAttribute("MoonStone")) or 0
            local moonPoint = tonumber(LocalPlayer:GetAttribute("MoonPoint")) or 0

            DiamondChestInfo:SetTitle("💎 Diamond: " .. FormatNumber(diamond))
            DiamondChestInfo:SetContent("📊 PointItem: " .. FormatNumber(pointItem))

            MoonChestInfo:SetTitle("🌙 MoonStone: " .. FormatNumber(moonStone))
            MoonChestInfo:SetContent("📊 MoonPoint: " .. FormatNumber(moonPoint))

            GuaranteeDiamondInfo:SetTitle("💎 Diamond: " .. FormatNumber(diamond))
            GuaranteeDiamondInfo:SetContent("📊 PointItem: " .. FormatNumber(pointItem))

            GuaranteeMoonInfo:SetTitle("🌙 MoonPoint: " .. FormatNumber(moonPoint))
            GuaranteeMoonInfo:SetContent("💠 MoonStone: " .. FormatNumber(moonStone))

            if _G.Select_Guarantee and _G.Select_Guarantee ~= "" then
                local itemName = tostring(_G.Select_Guarantee):match("^(.-) /") or tostring(_G.Select_Guarantee)
                itemName = itemName:gsub("^%s+", ""):gsub("%s+$", "")
                local price = (PointItemM and PointItemM[itemName]) or 0
                local status = pointItem >= price and "✅ Can buy" or ("❌ Missing " .. FormatNumber(price - pointItem))
                GuaranteeDiamondSelectInfo:SetTitle("🎯 " .. itemName)
                GuaranteeDiamondSelectInfo:SetContent("Price: " .. FormatNumber(price) .. " | " .. status)
            end

            if _G.Select_Guarantee_Moon and _G.Select_Guarantee_Moon ~= "" then
                local itemName = tostring(_G.Select_Guarantee_Moon):match("^(.-) /") or tostring(_G.Select_Guarantee_Moon)
                itemName = itemName:gsub("^%s+", ""):gsub("%s+$", "")
                local price = (PointItemMoon and PointItemMoon[itemName]) or 0
                local status = moonPoint >= price and "✅ Can buy" or ("❌ Missing " .. FormatNumber(price - moonPoint))
                GuaranteeMoonSelectInfo:SetTitle("🌙 " .. itemName)
                GuaranteeMoonSelectInfo:SetContent("Price: " .. FormatNumber(price) .. " | " .. status)
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local Inv = GetInventory()
            local have = (Inv["Time Mystery Box"] and Inv["Time Mystery Box"].amount) or 0

            local function Fmt(n)
                n = tonumber(n) or 0
                if n < 1000 then return tostring(math.floor(n)) end
                if n < 1000000 then return string.format("%.1fK", n / 1000) end
                return string.format("%.1fM", n / 1000000)
            end

            if TimeMysteryInfo then
                TimeMysteryInfo:SetTitle("🎁 Time Mystery Box: " .. Fmt(have))
                TimeMysteryInfo:SetContent(
                    "Open Amount: " .. tostring(_G.TimeMysteryAmount or 1) ..
                    " | Can open: " .. Fmt(have)
                )
            end
        end)
    end
end)

-- CRAFT TABLE
local CraftCard       = CraftTablePage:CreateSection("🔨 Craft Table", "Left")
local CraftStatusCard = CraftTablePage:CreateSection("📊 Status", "Right")
local CraftInfoCard   = CraftTablePage:CreateSection("📋 Craft Info", "Right")

local CraftMainPara = CraftInfoCard:Paragraph({
    Title = "🔨 No Item selected",
    Content = "Choose item to start"
})

local CraftCanMakePara = CraftStatusCard:Paragraph({
    Title = "📊 Craftable count: ---",
    Content = "Waiting for item"
})

local CraftGuaranteePara = CraftStatusCard:Paragraph({
    Title = "🎁 Guarantee: ---/---",
    Content = "Waiting for item"
})

_G.SelectedCraftItem = nil
_G.CraftDelay = 2.0

local CraftCountSinceClaim = 0
local LastCraftTimeSync = 0

local function GetAllCraftItems()
    local items = {}
    if not CraftingTable then return items end
    pcall(function()
        for name, data in pairs(CraftingTable) do
            if data.need then table.insert(items, name) end
        end
    end)
    table.sort(items)
    return items
end

local function GetMaxCraftTimes(itemName)
    if not itemName or itemName == "" then return 0 end
    if not CraftingTable then return 0 end

    local Data = CraftingTable[itemName]
    if not Data or not Data.need then return 0 end

    local minCraft = math.huge
    for Item, Need in pairs(Data.need) do
        if Need > 0 then
            local have = GetItemAmount(Item)
            local can = math.floor(have / Need)
            if can < minCraft then minCraft = can end
        end
    end

    if minCraft == math.huge then return 0 end
    return minCraft
end

local function GetGuaranteeCount(itemName)
    if not itemName or itemName == "" then return 0, 0 end

    local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
    if not hud or not hud:FindFirstChild("Main") then return 0, 0 end

    local guar = hud.Main:FindFirstChild("Frame_Guarantee")
    if not guar then return 0, 0 end

    local sf = guar:FindFirstChild("ScrollingFrame")
    if not sf then return 0, 0 end

    local itemFrame = sf:FindFirstChild(itemName)
    if not itemFrame then return 0, 0 end

    local main = itemFrame:FindFirstChild("Main")
    if not main then return 0, 0 end

    local amtLbl = main:FindFirstChild("AmountLabel")
    if not amtLbl then return 0, 0 end

    local txt = amtLbl.Text or ""
    local cur = tonumber(txt:match("^(%d+)")) or 0
    local max = tonumber(txt:match("/(%d+)")) or 0

    return cur, max
end

local function HasGuaranteeItemReady(itemName)
    local cur, max = GetGuaranteeCount(itemName)
    if max > 0 and cur >= max then return true end
    return false
end

local function ClaimGuaranteeItem(itemName)
    if not itemName or itemName == "" then return false end
    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "CraftTable", itemName, "Guarantee")
    return true
end

local function BuildCraftInfo(itemName)
    if not itemName or itemName == "" then
        return "🔨 No Item selected", "Choose item to start"
    end

    if not CraftingTable or not CraftingTable[itemName] then
        return "❌ Item not found", itemName
    end

    local Data = CraftingTable[itemName]
    if not Data or not Data.need then
        return "❌ No recipe", itemName
    end

    local text = "📋 Recipe:\n"
    local maxCraft = math.huge

    for Item, Need in pairs(Data.need) do
        local have = GetItemAmount(Item)
        local can = Need > 0 and math.floor(have / Need) or 0
        if Need > 0 and can < maxCraft then maxCraft = can end

        local status = have >= Need and "✅" or "❌"
        text = text .. string.format("  %s %s: %d/%d\n", status, Item, have, Need)
    end

    if maxCraft == math.huge then maxCraft = 0 end

    text = text .. "\n🔨 Can craft: " .. maxCraft .. " times"

    return "🔨 " .. itemName, text
end

CraftCard:Dropdown({
    Title = "Select Items to Craft",
    Options = GetAllCraftItems(),
    Multi = false,
    Callback = function(Value)
        _G.SelectedCraftItem = Value
    end
})

CraftCard:Toggle({
    Title = "🔨 Auto Craft",
    Value = false,
    Callback = function(v)
        _G.AutoCraftRunning = v
    end
})

CraftInfoCard:Toggle({
    Title = "✅ Auto Claim Guarantee (High Priority)",
    Value = true,
    Callback = function(v)
        _G.AutoClaimGuarantee = v
    end
})

local CraftSpeedPara = CraftCard:Paragraph({
    Title = "⏱️ Current Speed: 2.00s/time",
    Content = "🟢 Very Safe"
})

local function UpdateSpeedDisplay()
    local speed = _G.CraftDelay or 1.0

    local status
    if speed <= 0.3 then
        status = "🔴 ULTRA FAST — High risk"
    elseif speed <= 0.5 then
        status = "🟡 Fast — May waste"
    elseif speed <= 1.0 then
        status = "🟢 Safe (recommended)"
    elseif speed <= 2.0 then
        status = "🟢 Very Safe"
    elseif speed <= 5.0 then
        status = "🟢 Extremely Safe (slow)"
    else
        status = "🔵 Ultra Slow — Only for high ping"
    end

    CraftSpeedPara:SetTitle("⏱️ Current Speed: " .. string.format("%.2fs/time", speed))
    CraftSpeedPara:SetContent(status)
end

UpdateSpeedDisplay()

CraftCard:Button({
    Title = "🟢 Safe (0.5s)",
    Callback = function()
        _G.CraftDelay = 0.5
        UpdateSpeedDisplay()
        _G.SeaNotify("⏱️ Speed changed", "0.5s — Safe", 2)
    end
})

CraftCard:Button({
    Title = "🟢 Very Safe (1.0s)",
    Callback = function()
        _G.CraftDelay = 1.0
        UpdateSpeedDisplay()
        _G.SeaNotify("⏱️ Speed changed", "1.0s — Very Safe", 2)
    end
})

CraftCard:Button({
    Title = "🟢 Extremely Safe (2.0s)",
    Callback = function()
        _G.CraftDelay = 2.0
        UpdateSpeedDisplay()
        _G.SeaNotify("⏱️ Speed changed", "2.0s — Extremely Safe", 2)
    end
})

CraftCard:Button({
    Title = "🔵 Ultra Slow (5.0s)",
    Callback = function()
        _G.CraftDelay = 5.0
        UpdateSpeedDisplay()
        _G.SeaNotify("⏱️ Speed changed", "5.0s — Ultra Slow", 2)
    end
})

CraftCard:Paragraph({
    Title = "📖 Speed Guide",
    Content = "🟢 0.5-1.0s: Safe (recommended)\n🟢 1.0-2.0s: Very Safe\n🟢 2.0-5.0s: Extremely Safe\n🔵 5.0s+: Only when high ping\n\n💡 If still wasted → choose 2.0s or 5.0s"
})

task.spawn(function()
    local lastGuaranteeFire = 0
    local GUARANTEE_FIRE_DELAY = 0.3

    while task.wait(0.05) do
        if not _G.AutoClaimGuarantee then continue end
        if not _G.AutoCraftRunning then continue end
        if not _G.SelectedCraftItem or _G.SelectedCraftItem == "" then continue end

        local now = tick()
        local cur, max = GetGuaranteeCount(_G.SelectedCraftItem)

        if max > 0 and cur >= max then
            if now - lastGuaranteeFire >= GUARANTEE_FIRE_DELAY then
                lastGuaranteeFire = now
                ClaimGuaranteeItem(_G.SelectedCraftItem)
            end
        end
    end
end)

task.spawn(function()
    local lastCraftTime = 0
    local lastUICheck = 0
    local phase = "waiting"
    local UI_UPDATE_DELAY = 0.3
    local GUARANTEE_CLEAR_WAIT = 0.5

    while task.wait(0.05) do
        local now = tick()

        if now - lastUICheck >= UI_UPDATE_DELAY then
            lastUICheck = now

            if _G.SelectedCraftItem and _G.SelectedCraftItem ~= "" then
                local title, content = BuildCraftInfo(_G.SelectedCraftItem)
                CraftMainPara:SetTitle(title)
                CraftMainPara:SetContent(content)

                local canMake = GetMaxCraftTimes(_G.SelectedCraftItem)
                local cur, max = GetGuaranteeCount(_G.SelectedCraftItem)

                local statusIcon = "⏸️"
                if phase == "crafting" then statusIcon = "🔨"
                elseif phase == "waiting_guarantee" then statusIcon = "🛑"
                elseif phase == "syncing" then statusIcon = "🔄"
                elseif phase == "waiting" then statusIcon = "⏸️" end

                CraftCanMakePara:SetTitle(statusIcon .. " Can craft: " .. canMake .. " times")

                if phase == "crafting" then
                    local timeLeft = math.max(0, (_G.CraftDelay or 1.0) - (now - lastCraftTime))
                    CraftCanMakePara:SetContent("▶️ CRAFTING — " .. CraftCountSinceClaim ..
                        " | Wait: " .. string.format("%.1fs", timeLeft))
                elseif phase == "waiting_guarantee" then
                    CraftCanMakePara:SetContent("🛑 WAITING FOR CLAIM GUARANTEE")
                elseif phase == "syncing" then
                    CraftCanMakePara:SetContent("🔄 Waiting for server...")
                elseif phase == "waiting" then
                    CraftCanMakePara:SetContent("⏸️ Waiting")
                end

                if max > 0 then
                    local gIcon = cur >= max and "🛑" or "🎁"
                    CraftGuaranteePara:SetTitle(gIcon .. " Guarantee: " .. cur .. "/" .. max)
                    if cur >= max then
                        CraftGuaranteePara:SetContent("⛔ FULL — Claiming...")
                    else
                        CraftGuaranteePara:SetContent("✅ Remaining " .. (max - cur) .. " empty slots")
                    end
                else
                    CraftGuaranteePara:SetTitle("🎁 Guarantee: ---/---")
                    CraftGuaranteePara:SetContent("No item yet")
                end
            else
                CraftMainPara:SetTitle("🔨 No Item selected")
                CraftMainPara:SetContent("Choose item to start")
                CraftCanMakePara:SetTitle("📊 Craftable count: ---")
                CraftCanMakePara:SetContent("Waiting for item")
                CraftGuaranteePara:SetTitle("🎁 Guarantee: ---/---")
                CraftGuaranteePara:SetContent("Waiting for item")
            end
        end

        if not _G.AutoCraftRunning then
            if phase ~= "waiting" then
                phase = "waiting"
                CraftCountSinceClaim = 0
            end
            continue
        end

        if not _G.SelectedCraftItem or _G.SelectedCraftItem == "" then
            continue
        end

        local Data = CraftingTable and CraftingTable[_G.SelectedCraftItem]
        if not Data or not Data.need then
            continue
        end

        local cur, max = GetGuaranteeCount(_G.SelectedCraftItem)

        if max > 0 and cur >= max then
            if phase ~= "waiting_guarantee" then
                phase = "waiting_guarantee"
            end
            continue
        end

        if phase == "waiting_guarantee" and (max == 0 or cur < max) then
            phase = "syncing"
            _G.LastSyncTime = now
            CraftCountSinceClaim = 0
            lastCraftTime = now
            continue
        end

        if phase == "syncing" then
            if now - (_G.LastSyncTime or 0) >= GUARANTEE_CLEAR_WAIT then
                phase = "waiting"
                lastCraftTime = now
            end
            continue
        end

        local CanCraft = true
        for Item, Need in pairs(Data.need) do
            if GetItemAmount(Item) < Need then
                CanCraft = false
                break
            end
        end

        if not CanCraft then
            if phase ~= "waiting" then
                phase = "waiting"
            end
            task.wait(0.5)
            continue
        end

        local craftDelay = tonumber(_G.CraftDelay) or 1.0
        if craftDelay < 0.1 then craftDelay = 0.1 end

        local timeSinceLastCraft = now - lastCraftTime

        if timeSinceLastCraft >= craftDelay then
            lastCraftTime = now
            phase = "crafting"
            CraftCountSinceClaim = CraftCountSinceClaim + 1

            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "CraftTable", _G.SelectedCraftItem, "Craft")
        end
    end
end)

-- ============================================================
-- GOKU NPC
-- ============================================================
local GokuCurrentCard = GokuPage:CreateSection("📍 Available NPCs", "Left")
local GokuActionCard  = GokuPage:CreateSection("⚙️ Actions", "Right")

local GokuCurrentPara = GokuCurrentCard:Paragraph({
    Title = "Npc Count: 0 / 5",
    Content = "Searching NPC..."
})

local GOKU_NPC_KEYWORDS   = {"goku", "vegeta", "gohan", "goten", "trunk", "bardock"}
local MAX_NPC_PER_SESSION = 5
local MISS_THRESHOLD      = 5

_G.AutoGokuFind = false
_G.AutoGokuTP   = false

local GokuSpawnData       = {}
local SessionSpawnedCount = 0
local SessionNPCSpawned   = {}
local IgnoreNPCSpawned    = {}

local function FormatDuration(sec)
    sec = math.max(0, math.floor(sec))
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then return string.format("%02d:%02d:%02d", h, m, s) end
    return string.format("%02d:%02d", m, s)
end

local function FormatClock(t)
    local d = os.date("*t", t)
    return string.format("%02d:%02d:%02d", d.hour, d.min, d.sec)
end

local function ResetGokuSession(reason)
    for npcName in pairs(SessionNPCSpawned) do
        IgnoreNPCSpawned[npcName] = true
    end
    GokuSpawnData       = {}
    SessionSpawnedCount = 0
    SessionNPCSpawned   = {}
    _G.SeaNotify("🔄 Reset NPC session", reason or "5 NPCs reached", 5)
end

local function ScanGokuNPCs()
    local results = {}
    local powerGod = workspace:FindFirstChild("Power God")
    if not powerGod then return results end

    local char   = LocalPlayer.Character
    local myHrp  = char and char:FindFirstChild("HumanoidRootPart")
    local now    = tick()

    if SessionSpawnedCount >= MAX_NPC_PER_SESSION then
        ResetGokuSession("5 NPCs reached — reset session")
        return results
    end

    for _, obj in ipairs(powerGod:GetChildren()) do
        if obj:IsA("Model") then
            local lower   = obj.Name:lower()
            local matched = false
            for _, kw in ipairs(GOKU_NPC_KEYWORDS) do
                if lower:find(kw) then matched = true; break end
            end
            if matched then
                local hrp    = obj:FindFirstChild("HumanoidRootPart")
                local hum    = obj:FindFirstChild("Humanoid")
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                local dist   = (myHrp and hrp) and (myHrp.Position - hrp.Position).Magnitude or -1

                local data = GokuSpawnData[obj.Name]
                if not data then
                    local isNewNPC = not IgnoreNPCSpawned[obj.Name] and not SessionNPCSpawned[obj.Name]
                    data = {firstSeenAt = now, spawnClock = os.time(), lastSeen = now, isAlive = true}
                    GokuSpawnData[obj.Name] = data

                    if isNewNPC then
                        SessionNPCSpawned[obj.Name] = true
                        SessionSpawnedCount = SessionSpawnedCount + 1
                        _G.SeaNotify("🎯 NPC Spawn!", obj.Name .. " (" .. SessionSpawnedCount .. "/" .. MAX_NPC_PER_SESSION .. ")", 5)
                    end
                else
                    data.lastSeen = now
                    if not data.isAlive then
                        data.isAlive    = true
                        data.firstSeenAt = now
                        data.spawnClock  = os.time()
                        if IgnoreNPCSpawned[obj.Name] then
                            IgnoreNPCSpawned[obj.Name] = nil
                        end
                        if not SessionNPCSpawned[obj.Name] and SessionSpawnedCount < MAX_NPC_PER_SESSION then
                            SessionNPCSpawned[obj.Name] = true
                            SessionSpawnedCount = SessionSpawnedCount + 1
                            _G.SeaNotify("🎯 NPC Respawn!", obj.Name .. " (" .. SessionSpawnedCount .. "/" .. MAX_NPC_PER_SESSION .. ")", 5)
                        else
                            _G.SeaNotify("🎯 NPC Respawn!", obj.Name .. " returned!", 5)
                        end
                    end
                end

                table.insert(results, {
                    Name = obj.Name, Model = obj,
                    Position = hrp and hrp.Position or Vector3.zero,
                    Health = hum and hum.Health or 0,
                    HasPrompt = prompt ~= nil,
                    PromptText = prompt and prompt.ActionText or "N/A",
                    Distance = dist, Prompt = prompt,
                    SpawnClock = data.spawnClock, Elapsed = now - data.firstSeenAt
                })
            end
        end
    end

    for name, data in pairs(GokuSpawnData) do
        if now - data.lastSeen > MISS_THRESHOLD and data.isAlive then
            data.isAlive = false
        end
    end

    table.sort(results, function(a, b)
        if a.Distance < 0 then return false end
        if b.Distance < 0 then return true end
        return a.Distance < b.Distance
    end)
    return results
end

local function RenderGokuCurrent(npcs)
    local text = {}
    table.insert(text, "Session: " .. SessionSpawnedCount .. "/" .. MAX_NPC_PER_SESSION)
    table.insert(text, "Present: " .. #npcs)
    table.insert(text, "─────────────────")
    if #npcs == 0 then
        table.insert(text, "❌ No NPCs")
    else
        for i, npc in ipairs(npcs) do
            local distText = npc.Distance >= 0 and string.format("%.0f studs", npc.Distance) or "?"
            table.insert(text, string.format(
                "%d. %s\n   ⏰ %s (for %s)\n   📏 %s | ❤️ %d\n   🖱️ %s (%s)",
                i, npc.Name, FormatClock(npc.SpawnClock), FormatDuration(npc.Elapsed),
                distText, npc.Health, npc.HasPrompt and "✅" or "❌", npc.PromptText
            ))
        end
    end
    GokuCurrentPara:SetTitle("Npc Count: " .. SessionSpawnedCount .. " / " .. MAX_NPC_PER_SESSION)
    GokuCurrentPara:SetContent(table.concat(text, "\n"))
end

local function ClickGokuNPC(npcData)
    if not npcData or not npcData.Model or not npcData.Model.Parent then return false end
    local prompt = npcData.Prompt
    if not prompt or not prompt.Parent then return false end
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    hrp.CFrame = CFrame.new(npcData.Position + Vector3.new(0, 5, 0))
    task.wait(0.2)
    pcall(function() fireproximityprompt(prompt) end)
    return true
end

GokuActionCard:Toggle({
    Title = "🎯 Auto Find & Click NPC", Value = false,
    Callback = function(Value)
        _G.AutoGokuFind = Value
        _G.SeaNotify(Value and "▶️ Enable Auto Goku" or "⏹️ Disable Auto Goku", "Auto find + click", 3)
    end
})
GokuActionCard:Toggle({
    Title = "✈️ Auto TP Nearest NPC", Value = false,
    Callback = function(Value)
        _G.AutoGokuTP = Value
        _G.SeaNotify(Value and "▶️ Enable Auto TP" or "⏹️ Disable Auto TP", "TP to nearest NPC", 3)
    end
})

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local npcs = ScanGokuNPCs()
            RenderGokuCurrent(npcs)

            if _G.AutoGokuTP and #npcs > 0 then
                local npc = npcs[1]
                if npc.Model and npc.Model.Parent then
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.CFrame = CFrame.new(npc.Position + Vector3.new(0, 5, 0)) end
                end
            end

            if _G.AutoGokuFind and #npcs > 0 then
                for _, npc in ipairs(npcs) do
                    if npc.HasPrompt then
                        ClickGokuNPC(npc)
                        task.wait(1)
                        break
                    end
                end
            end
        end)
    end
end)

-- ============================================================
-- TAB 4: TELEPORT
-- ============================================================
local TabTP    = Window:CreateTab("Teleport", false, false)
local TPPage   = TabTP:CreatePage("Teleport Sea 1")
local IslandCard = TPPage:CreateSection("🏝️ Sea 1 Islands", "Left")
local SeaCard    = TPPage:CreateSection("🌊 Sea Travel", "Right")
local TPInfoCard = TPPage:CreateSection("📊 Information", "Right")

local IslandCache    = {}
local IslandList     = {}
local SelectedIsland = nil

local TPInfoPara = TPInfoCard:Paragraph({Title = "Sea 1", Content = "Loading..."})
local SeaInfoPara = SeaCard:Paragraph({Title = "Sea", Content = "Loading..."})

local function ScanIslands()
    IslandCache = {}
    IslandList  = {}
    local islandFolder = workspace:FindFirstChild("island")
    if not islandFolder then return end

    local orderMap = {}
    local gates    = workspace:FindFirstChild("Gates")
    local tpPart   = gates and gates:FindFirstChild("TeleportPart")
    if tpPart then
        for i, part in ipairs(tpPart:GetChildren()) do
            if part:IsA("BasePart") then orderMap[part.Name] = i end
        end
    end

    local tempList = {}
    for _, obj in ipairs(islandFolder:GetChildren()) do
        if obj:IsA("Model") then
            local hrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            IslandCache[obj.Name] = {model = obj, pos = hrp and hrp.Position or Vector3.zero}
            table.insert(tempList, obj.Name)
        end
    end

    table.sort(tempList, function(a, b)
        local ia, ib = orderMap[a], orderMap[b]
        if ia and ib then return ia < ib end
        if ia and not ib then return true end
        if not ia and ib then return false end
        return a < b
    end)
    IslandList = tempList
end

ScanIslands()

IslandCard:Dropdown({
    Title = "🏝️ Select Sea 1 Island", Options = IslandList, Multi = false,
    Callback = function(Value)
        SelectedIsland = Value
        local data = IslandCache[Value]
        if data then
            local char  = LocalPlayer.Character
            local myHrp = char and char:FindFirstChild("HumanoidRootPart")
            local dist  = myHrp and string.format("%.0f studs", (myHrp.Position - data.pos).Magnitude) or "?"
            TPInfoPara:SetTitle("Island: " .. Value)
            TPInfoPara:SetContent(string.format("📌 %.0f, %.0f, %.0f\n📏 %s", data.pos.X, data.pos.Y, data.pos.Z, dist))
        end
    end
})
IslandCard:Button({
    Title = "✈️ Teleport To Island",
    Callback = function()
        if not SelectedIsland then
            _G.SeaNotify("❌ No island selected", "Choose an island first!", 3); return
        end
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then _G.SeaNotify("❌ No character", "Character not loaded", 3); return end

        local gates  = workspace:FindFirstChild("Gates")
        local tpPart = gates and gates:FindFirstChild("TeleportPart")
        local target = tpPart and tpPart:FindFirstChild(SelectedIsland)
        if target then
            hrp.CFrame = CFrame.new(target.Position + Vector3.new(0, 5, 0))
            _G.SeaNotify("✈️ Activated", SelectedIsland .. " (TeleportPart)", 3)
        else
            local data = IslandCache[SelectedIsland]
            if data and data.pos then
                hrp.CFrame = CFrame.new(data.pos + Vector3.new(0, 5, 0))
                _G.SeaNotify("✈️ Activated", SelectedIsland .. " (Model pos)", 3)
            else
                _G.SeaNotify("❌ Not found", SelectedIsland, 3)
            end
        end
    end
})
SeaCard:Button({
    Title = "🌊 Go To Sea 2 (2SeaSoon)",
    Callback = function()
        local seaNPC = workspace:FindFirstChild("2SeaSoon")
        if not seaNPC then
            _G.SeaNotify("❌ NPC Sea 2 not found", "workspace.2SeaSoon missing", 3); return
        end
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local npcHrp = seaNPC:FindFirstChild("HumanoidRootPart") or seaNPC:FindFirstChildWhichIsA("BasePart")
        if npcHrp then
            hrp.CFrame = CFrame.new(npcHrp.Position + Vector3.new(0, 5, 0))
            _G.SeaNotify("🌊 Arrived at NPC Sea 2", "Waiting for Sea change...", 5)
            task.wait(0.5)
            local prompt = seaNPC:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then pcall(function() fireproximityprompt(prompt) end) end
        end
    end
})

-- ============================================================
-- TAB 5: CONFIG
-- ============================================================
local ConfigTab = Window:CreateTab("Config", false, false)
MySaveManager:BuildConfigTab(ConfigTab)
task.spawn(function()
    task.wait(1)
    MySaveManager:LoadAutoloadConfig()
end)

-- ============================================================
-- BACKGROUND LOOPS
-- ============================================================

task.spawn(function()
    while task.wait() do
        pcall(function()
            local Text = {}
            for Name, MobName in pairs(SpawnList) do
                local Spawned = false
                local Names = {MobName}
                if MobName == "Devil Boat" then table.insert(Names, "DevilBoat") end
                for _, n in ipairs(Names) do
                    if workspace.Mob and workspace.Mob:FindFirstChild(n) then Spawned = true; break end
                end
                table.insert(Text, Name .. ": " .. (Spawned and "✅" or "❌"))
            end
            Spawn_Status:SetContent(table.concat(Text, "\n"))
        end)
    end
end)

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

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if not _G.Auto_RandomChest_Moon then return end

            local moonStone = tonumber(LocalPlayer:GetAttribute("MoonStone")) or 0
            local selectVal = _G.Select_Random_Moon or "x5"

            local costMap = {["x5"] = 25, ["x10"] = 50, ["x15"] = 75}
            local cost = costMap[selectVal] or 25

            if moonStone >= cost then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "EventMoon", selectVal)
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if not _G.Auto_RandomChest then return end

            local selectVal = _G.Select_Random or "x5"
            local event = ReplicatedStorage.Modules.NetworkFramework.NetworkEvent

            event:FireServer("fire", nil, "RandomItem", selectVal)
        end)
    end
end)

task.spawn(function()
    while task.wait() do
        xpcall(function()
            if _G.Auto_SellItem and type(_G.Select_SellItem) == "table" then
                for ItemName, Selected in pairs(_G.Select_SellItem) do
                    local Data = Economy and Economy[ItemName]
                    if Selected and Data and GetItemAmount(ItemName) >= Data.amount then
                        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Economy", ItemName)
                    end
                end
            end
        end, print)
    end
end)

task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_Haki then
                if LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("HakiFolder") then
                    ReplicatedStorage.Remotes.Action:FireServer("Misc", "buso")
                end
            end
        end)
    end
end)

-- ============================================================
-- AUTO SKILL LOOP v123 — ONLY SPAM WHEN ATTACKING
-- ============================================================
task.spawn(function()
    while task.wait(0.1) do
        local hasAuto = _G.Auto_Farm_Level or _G.Auto_Farm_Material or _G.Auto_FarmBoss
                     or _G.Auto_FarmBoss_Automatically or _G.Auto_Duck or _G.Auto_DuckAutomatically
                     or _G.Auto_Piccolo or _G.Auto_DevilBoat or _G.Auto_CraftWeapon
                     or _G.Auto_Farm_Set or _G.Auto_Raid or _G.Auto_BaconThief or _G.Auto_Dungeon
                     or _G.AutoRaidRunning or _G.Auto_Kraken

        if hasAuto and _G.CanAutoSkill == true then
            pcall(function() AutoSkill() end)
        end
    end
end)

-- AUTO POTION
task.spawn(function()
    while task.wait(0.3) do
        if _G.Auto_Use_Potion then
            pcall(function()
                local Inv    = ReplicatedStorage.Remotes.Inventory
                local Select = _G.Select_Potion
                if not Select then return end
                if Select["X2 EXP 15min."]     and tonumber(LocalPlayer:GetAttribute("x2ExpTime")) == 0     then Inv:FireServer("X2 EXP 15min.") end
                if Select["X2 Diamond 15min."] and tonumber(LocalPlayer:GetAttribute("x2DiamondTime")) == 0 then Inv:FireServer("X2 Diamond 15min.") end
                if Select["X2 Lucky 15min."]   and tonumber(LocalPlayer:GetAttribute("x2LuckTime")) == 0    then Inv:FireServer("X2 Lucky 15min.") end
                if Select["X2 Rebirth 15min."] and tonumber(LocalPlayer:GetAttribute("x2RebirthTime")) == 0 then Inv:FireServer("X2 Rebirth 15min.") end
                if Select["X2 Item 15min."]    and tonumber(LocalPlayer:GetAttribute("x2ItemTime")) == 0    then Inv:FireServer("X2 Item 15min.") end
            end)
        end
    end
end)

-- AUTO EQUIP ACCESSORY
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if not _G.Auto_Equip_Accessory or not AccessoryModule then return end
            local Inventory = HttpService:JSONDecode(LocalPlayer:GetAttribute("Inventory") or "{}")
            local Equipped  = HttpService:JSONDecode(LocalPlayer:GetAttribute("UseAccessory") or "{}")
            local Best = {}
            for Name in pairs(Inventory) do
                local Info = AccessoryModule[Name]
                if Info then
                    local Score = 0
                    for _, Value in pairs(Info) do
                        if type(Value) == "number" then Score = Score + Value end
                    end
                    if not Best[Info.Type] or Score > Best[Info.Type].Score then
                        Best[Info.Type] = {Name = Name, Score = Score}
                    end
                end
            end
            for Type, Data in pairs(Best) do
                local EquippedName
                for Name, Info in pairs(Equipped) do
                    if Info.Type == Type then EquippedName = Name; break end
                end
                if EquippedName ~= Data.Name then
                    ReplicatedStorage.Remotes.Inventory:FireServer(Data.Name)
                    task.wait(0.5)
                end
            end
        end)
    end
end)

-- AUTO REBIRTH
task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_Rebirth then
                if LocalPlayer.PlayerGui.HUD.Main.Frame_Display.LevelText.Text:lower():find("max") then
                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Rebirth")
                end
            end
        end)
    end
end)

-- GUARANTEE AUTO BUY
task.spawn(function()
    while task.wait() do
        if _G.Auto_Guarantee_Moon and PointItemMoon then
            local Point = tonumber(LocalPlayer:GetAttribute("MoonPoint")) or 0
            local Price = PointItemMoon[_G.Select_Guarantee_Moon] or 0
            if _G.Select_Guarantee_Moon and Point >= Price then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "BuyGaranteeEventMoon", _G.Select_Guarantee_Moon)
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if not _G.Auto_Guarantee then return end
            if not _G.Select_Guarantee or _G.Select_Guarantee == "" then return end

            local pointItem = tonumber(LocalPlayer:GetAttribute("PointItem")) or 0

            local itemName = _G.Select_Guarantee
            if type(itemName) == "table" then
                for _, v in pairs(itemName) do
                    if type(v) == "string" then
                        itemName = v
                        break
                    end
                end
            end
            if type(itemName) ~= "string" then return end

            itemName = itemName:match("^(.-) /") or itemName
            itemName = itemName:gsub("^%s+", ""):gsub("%s+$", "")

            local price = PointItemM[itemName] or 0

            if price > 0 and pointItem >= price then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "BuyGaranteeRandomItem", itemName)
            end
        end)
    end
end)

-- SHOP DUNGEON LOOPS
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local ptAttr = LocalPlayer:GetAttribute("DungeonPoint") or 0
            ShopDunInfoPara:SetTitle("DungeonPoint: " .. tostring(ptAttr))
            local items = GetAllShopDunItems()
            if #items > 0 then UpdateDunDropdown(items) end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if _G.AutoBuyDunRunning and _G.AutoBuyDunItem then
            pcall(function()
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "BuyDungeonShop", _G.AutoBuyDunItem)
                task.wait(0.2)
            end)
        end
    end
end)

-- SHOP RAID LOOP
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            if not hud or not hud:FindFirstChild("Main") then return end
            local shop = hud.Main:FindFirstChild("Frame_ShopRaid")
            if not shop then return end

            local rpLbl    = shop:FindFirstChild("RaidPoint")
            local resetLbl = shop:FindFirstChild("Reset")
            if rpLbl and resetLbl then
                ShopInfoPara:SetTitle(rpLbl.Text)
                ShopInfoPara:SetContent(resetLbl.Text)
            end

            local sf = shop:FindFirstChild("ScrollingFrame")
            if sf then
                local items = {}
                for _, item in pairs(sf:GetChildren()) do
                    if item:IsA("Frame") then
                        local label = item:FindFirstChild("Label")
                        if label and label.Text and label.Text ~= "" and label.Text ~= "Item" then
                            table.insert(items, label.Text)
                        end
                    end
                end
                if #items > 0 then
                    table.sort(items)
                    UpdateShopDropdown(items)
                end
            end
        end)
    end
end)

-- AUTO FARM LEVEL
task.spawn(function()
    while wait() do
        xpcall(function()
            if not _G.Auto_Farm_Level then return end
            local quest = GetQuest_Level(tonumber(LocalPlayer:GetAttribute("Level")))
            if not quest then return end
            local Frame = GetQuestFrame()
            local Text  = Frame.Title.Text or ""
            if LocalPlayer.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
            end
            if Frame.Visible and not string.find(Text, quest.Monster) then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                repeat task.wait() until not Frame.Visible
            end
            if not Frame.Visible then
                _G.CanAutoSkill = false

                local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
                if npc then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = CFrame.new(npc.Position + Vector3.new(0, 3, 0))
                        hrp.AssemblyLinearVelocity = Vector3.zero
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
                    if v:IsA("Model") and v.Name == quest.Monster and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        local hrp = v:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0

                            _G.CanAutoSkill = true

                            repeat task.wait()
                                EquipWeapon()
                                AutoSkill()
                                Attack()
                                Teleport(hrp.CFrame * MethodFarm)
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
-- AUTO FARM MATERIAL v106
-- ============================================================
task.spawn(function()
    local lastMaterialLog = 0
    local lastTargetLog = 0
    local lastSpawnTPTime = 0
    local SPAWN_TP_COOLDOWN = 2
    local lastSpawnTPName = nil

    while task.wait() do
        xpcall(function()
            if not _G.Auto_Farm_Material then
                lastTargetKey = nil
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
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then return end

            local mobFolder = workspace:FindFirstChild("Mob") or workspace:FindFirstChild("Mobs")
            if not mobFolder then
                if tick() - lastTargetLog > 5 then
                    lastTargetLog = tick()
                end
                return
            end

            local Target = nil
            local TargetName = nil
            local minDist = math.huge

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
                                    minDist = dist
                                    Target = Mob
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
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero

                            lastSpawnTPTime = tick()

                            if lastSpawnTPName ~= spawnName then
                                lastSpawnTPName = spawnName
                            end

                            task.wait(0.5)
                        end
                    end
                end

                if tick() - lastTargetLog > 5 then
                    lastTargetLog = tick()
                end

                hrp.AssemblyLinearVelocity = Vector3.zero
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

            -- 🆕 Dùng Teleport đơn giản như bản gốc — không rung
            Teleport(tHrp.CFrame * MethodFarm)
        end, function(err)
            warn("[AutoFarm] Error:", err)
        end)
    end
end)

-- ============================================================
-- AUTO FARM BOSS (Full) — v6 FOLLOW 24/7 AFTER RESPAWN
-- ============================================================
task.spawn(function()
    local lastSummonTime = 0
    local summonCooldown = 1.5

    while task.wait() do
        xpcall(function()
            if not _G.Auto_FarmBoss then return end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then
                _G.CanAutoSkill = false
                return
            end

            local Boss = nil
            for _, v in pairs(workspace.Boss:GetChildren()) do
                if table.find(Bosses, v.Name)
                   and v:FindFirstChild("Humanoid")
                   and v:FindFirstChild("HumanoidRootPart")
                   and v.Humanoid.Health > 0 then
                    Boss = v
                    break
                end
            end

            if Boss then
                _G.CanAutoSkill = true
                lastSummonTime = 0

                Boss.Humanoid.WalkSpeed = 0
                Boss.Humanoid.JumpPower = 0

                local tHrp = Boss.HumanoidRootPart

                EquipWeapon()
                AutoSkill()
                Attack()

                -- 🆕 Dùng Teleport đơn giản như bản gốc — không rung
                Teleport(tHrp.CFrame * MethodFarm)
                return
            end

            _G.CanAutoSkill = false
            lastBossKey = nil

            local now = tick()
            if now - lastSummonTime < summonCooldown then return end

            local orbBoss = GetItemAmount("Orb Boss")
            if orbBoss >= 1 and _G.Select_Boss then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "SummonBoss", _G.Select_Boss)
                lastSummonTime = now
                return
            end

            _G.Auto_FarmBoss = false
            _G.SeaNotify("❌ Out of Orb Boss", "Auto Farm Boss (Full) disabled!", 5)
        end, function(err) warn("[AutoFarmBoss] Error:", err) end)
    end
end)

-- AUTO PICCOLO
task.spawn(function()
    while task.wait() do
        if _G.Auto_Piccolo then
            pcall(function()
                if workspace.Mob:FindFirstChild("Piccolo") then
                    for _, v in pairs(workspace.Mob:GetChildren()) do
                        if v:IsA("Model") and v.Name == "Piccolo" and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0

                            _G.CanAutoSkill = true

                            repeat task.wait()
                                EquipWeapon()
                                AutoSkill()
                                Attack()
                                Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
                            until not _G.Auto_Piccolo or not v.Parent or v.Humanoid.Health <= 0

                            _G.CanAutoSkill = false
                        end
                    end
                else
                    _G.CanAutoSkill = false
                end
            end)
        end
    end
end)

-- ============================================================
-- AUTO DUCK (Full) — v6 FOLLOW 24/7 AFTER RESPAWN
-- ============================================================
task.spawn(function()
    local lastSummonTime = 0
    local summonCooldown = 2.5

    while task.wait() do
        xpcall(function()
            if not _G.Auto_DuckAutomatically then return end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then
                _G.CanAutoSkill = false
                return
            end

            local Duck = nil
            for _, v in pairs(workspace.Mob:GetChildren()) do
                if v:IsA("Model")
                   and v.Name == "Duck Monster"
                   and v:FindFirstChild("Humanoid")
                   and v:FindFirstChild("HumanoidRootPart")
                   and v.Humanoid.Health > 0 then
                    Duck = v
                    break
                end
            end

            if Duck then
                _G.CanAutoSkill = true
                lastSummonTime = 0

                Duck.Humanoid.WalkSpeed = 0
                Duck.Humanoid.JumpPower = 0

                local tHrp = Duck.HumanoidRootPart

                EquipWeapon()
                AutoSkill()
                Attack()

                -- 🆕 Dùng Teleport đơn giản như bản gốc — không rung
                Teleport(tHrp.CFrame * MethodFarm)
                return
            end

            _G.CanAutoSkill = false
            lastDuckKey = nil

            local now = tick()
            if now - lastSummonTime < summonCooldown then return end

            local DuckItems = {"Duck","Duck2","Duck3","Duck4","Duck5","Duck6","Duck7"}
            local missingItems = {}
            local HaveAll = true
            for _, Item in ipairs(DuckItems) do
                if GetItemAmount(Item) <= 0 then
                    HaveAll = false
                    table.insert(missingItems, Item)
                end
            end

            if HaveAll then
                local npcPrompt = workspace:FindFirstChild("NpcPrompt")
                local duckNPC = npcPrompt and npcPrompt:FindFirstChild("DuckMonster")

                if duckNPC then
                    local npcHrp = duckNPC:FindFirstChild("HumanoidRootPart")
                        or duckNPC:FindFirstChildWhichIsA("BasePart")

                    if npcHrp then
                        hrp.CFrame = npcHrp.CFrame * CFrame.new(0, 5, 0)
                        task.wait(0.3)

                        local prompt = npcHrp:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            pcall(function() fireproximityprompt(prompt) end)
                            lastSummonTime = now
                        end
                    end
                end
                return
            end

            _G.Auto_DuckAutomatically = false
            _G.SeaNotify("❌ Missing Duck Items", table.concat(missingItems, ", "), 6)
        end, function(err) warn("[AutoDuckFull] Error:", err) end)
    end
end)

-- AUTO DEVIL BOAT
task.spawn(function()
    while task.wait() do
        if _G.Auto_DevilBoat then
            pcall(function()
                _G.CanAutoSkill = false

                for _, v in pairs(workspace.Mob:GetChildren()) do
                    if v:IsA("Model") and (v.Name == "Devil Boat" or v.Name == "DevilBoat") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        v.Humanoid.WalkSpeed = 0
                        v.Humanoid.JumpPower = 0

                        _G.CanAutoSkill = true

                        repeat task.wait()
                            EquipWeapon()
                            AutoSkill()
                            Attack()
                            Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
                        until not _G.Auto_DevilBoat or not v.Parent or v.Humanoid.Health <= 0

                        _G.CanAutoSkill = false
                        break
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- 🐙 AUTO FARM KRAKEN — v1
-- ============================================================
task.spawn(function()
    local lastTargetKey = nil
    local jitterSeed = 0
    local KRAKEN_HEIGHT = 25

    while task.wait() do
        xpcall(function()
            if not _G.Auto_Kraken then
                _G.CanAutoSkill = false
                lastTargetKey = nil
                return
            end

            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChild("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then
                _G.CanAutoSkill = false
                return
            end

            local Kraken = nil
            local mobFolder = workspace:FindFirstChild("Mob")
            if mobFolder then
                for _, v in ipairs(mobFolder:GetChildren()) do
                    if v:IsA("Model")
                       and v.Name == "Kraken"
                       and v:FindFirstChild("Humanoid")
                       and v:FindFirstChild("HumanoidRootPart")
                       and v.Humanoid.Health > 0 then
                        Kraken = v
                        break
                    end
                end
            end

            if not Kraken then
                _G.CanAutoSkill = false
                lastTargetKey = nil
                return
            end

            _G.CanAutoSkill = true

            Kraken.Humanoid.WalkSpeed  = 0
            Kraken.Humanoid.JumpPower  = 0

            local tHrp = Kraken.HumanoidRootPart

            EquipWeapon()
            AutoSkill()
            Attack()

            Teleport(tHrp.CFrame * MethodFarm)
        end, function(err)
            warn("[AutoKraken] Error:", err)
        end)
    end
end)

-- ============================================================
-- AUTO CRAFT WEAPON v133 — FIX SPAM + SMART
-- ============================================================
task.spawn(function()
    local lastNotifyTime = 0
    local lastCraftTime = 0
    local CRAFT_INTERVAL = 0.5
    local NOTIFY_INTERVAL = 5
    local lastMissingKey = nil
    local lastMissingNotify = 0

    while task.wait(0.1) do
        xpcall(function()
            if not _G.Auto_CraftWeapon then return end

            if not _G.Select_Item or _G.Select_Item == "" then
                if tick() - lastNotifyTime > NOTIFY_INTERVAL then
                    lastNotifyTime = tick()
                    _G.SeaNotify("❌ No Weapon selected", "Choose weapon in dropdown first!", 3)
                end
                return
            end

            local Data = UseItems and UseItems[_G.Select_Item]
            if not Data then return end

            if Data.NeedClass then
                local PlayerClass = LocalPlayer:GetAttribute("UseClass")
                if PlayerClass ~= Data.NeedClass then
                    if tick() - lastNotifyTime > NOTIFY_INTERVAL then
                        lastNotifyTime = tick()
                        _G.SeaNotify("⚠️ Missing Class: " .. Data.NeedClass, "You need this class to craft", 4)
                    end
                    return
                end
            end

            local needBeli = (Data.PlayerData and Data.PlayerData.Beli) or 0
            local currentBeli = LocalPlayer:GetAttribute("Beli") or 0
            if needBeli > 0 and currentBeli < needBeli then
                if tick() - lastNotifyTime > NOTIFY_INTERVAL then
                    lastNotifyTime = tick()
                    _G.SeaNotify("❌ Missing Beli", "Need " .. needBeli .. ", have " .. currentBeli, 4)
                end
                return
            end

            local Inv = GetInventory()
            local missingItems = {}
            local haveAll = true

            for Item, Need in pairs(Data.Inventory) do
                local Have = Inv[Item] and Inv[Item].amount or 0
                if Have < Need then
                    haveAll = false
                    table.insert(missingItems, Item .. " (" .. Have .. "/" .. Need .. ")")
                end
            end

            if not haveAll then
                local missingKey = table.concat(missingItems, ",")
                if missingKey ~= lastMissingKey or tick() - lastMissingNotify > NOTIFY_INTERVAL then
                    lastMissingKey = missingKey
                    lastMissingNotify = tick()
                    _G.SeaNotify("❌ Missing Materials", table.concat(missingItems, ", "), 4)
                end
                return
            end

            lastMissingKey = nil

            if tick() - lastCraftTime >= CRAFT_INTERVAL then
                lastCraftTime = tick()
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Craft", _G.Select_Item, Data.Type)
            end
        end, print)
    end
end)

-- ============================================================
-- UPDATE ITEM REQUIREMENTS v133 — FIX (None) N/A
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if not UseItems then return end

            if not _G.Select_Item or _G.Select_Item == "" then
                Item_Auto:SetTitle("Item Requirements ( Not selected )")
                Item_Auto:SetContent("📖 Guide:\n  1. Select Weapon from dropdown\n  2. TP to Material NPC\n  3. Enable Auto Craft")
                return
            end

            local Data = UseItems[_G.Select_Item]
            if not Data then
                Item_Auto:SetTitle("Item Requirements ( No data )")
                Item_Auto:SetContent("❌ Weapon: " .. _G.Select_Item .. "\n  Not found in UseItems")
                return
            end

            local Inv = GetInventory()
            local HaveWeapon = Inv[_G.Select_Item] and (Inv[_G.Select_Item].amount or 0) > 0

            local Text = {}
            table.insert(Text, "📦 Weapon: " .. _G.Select_Item)
            table.insert(Text, "━━━━━━━━━━━━━━━━━━━━")
            table.insert(Text, "🎓 Need Class: " .. (Data.NeedClass or "None"))
            table.insert(Text, "💰 Need Beli: " .. tostring((Data.PlayerData and Data.PlayerData.Beli) or 0))

            local LowestSet = math.huge
            local MaterialsText = {}
            local missingCount = 0

            for Item, Need in pairs(Data.Inventory) do
                local Have = Inv[Item] and Inv[Item].amount or 0
                local Set  = math.floor(Have / Need)
                if Set < LowestSet then LowestSet = Set end
                if Have < Need then missingCount = missingCount + 1 end
            end

            if LowestSet == math.huge then LowestSet = 0 end
            table.insert(Text, "🎯 Have Set: " .. LowestSet)
            table.insert(Text, "━━━━━━━━━━━━━━━━━━━━")
            table.insert(Text, "📋 Materials:")

            for Item, Need in pairs(Data.Inventory) do
                local Have = Inv[Item] and Inv[Item].amount or 0
                local Set  = math.floor(Have / Need)
                local status = Have >= Need and "✅" or "❌"
                table.insert(Text, string.format("  %s %s: %d/%d (Set: %d)",
                    status, Item, Have, Need, Set))
            end

            local statusIcon = "❌"
            if HaveWeapon then statusIcon = "✅ (Already have)"
            elseif missingCount == 0 then statusIcon = "✅ (Enough)" end

            Item_Auto:SetTitle("Item Requirements \n( " .. _G.Select_Item .. " " .. statusIcon .. " )")
            Item_Auto:SetContent(table.concat(Text, "\n"))
        end)
    end
end)

-- AUTO FARM SET
task.spawn(function()
    while task.wait() do
        if _G.Auto_Farm_Set then
            pcall(function()
                local Data = UseItems and UseItems[_G.Select_Item]
                if not Data then return end
                local Inv = GetInventory()
                local NeedFarmItem = nil
                local LowestSet    = math.huge
                for Item, Need in pairs(Data.Inventory) do
                    if not (UseItems[Item]) then
                        local Have = Inv[Item] and Inv[Item].amount or 0
                        local Set  = math.floor(Have / Need)
                        if Set < LowestSet then
                            LowestSet    = Set
                            NeedFarmItem = Item
                        end
                    end
                end
                if not NeedFarmItem then return end
                local NeedAmount = Data.Inventory[NeedFarmItem]
                local Have       = Inv[NeedFarmItem] and Inv[NeedFarmItem].amount or 0
                if Have >= (LowestSet + 1) * NeedAmount then return end
                local MobNames = ItemDrop[NeedFarmItem]
                if not MobNames then return end
                for _, MobName in ipairs(MobNames) do
                    local Target
                    for _, Mob in ipairs(workspace.Mob:GetChildren()) do
                        if Mob:IsA("Model") and Mob.Name == MobName and Mob:FindFirstChild("Humanoid") and Mob.Humanoid.Health > 0 then
                            Target = Mob; break
                        end
                    end
                    if Target then
                        local HRP = Target.HumanoidRootPart
                        Target.Humanoid.WalkSpeed = 0
                        Target.Humanoid.JumpPower = 0

                        _G.CanAutoSkill = true

                        repeat task.wait()
                            EquipWeapon(); AutoSkill(); Attack()
                            Teleport(HRP.CFrame * MethodFarm)
                            Inv  = GetInventory()
                            Have = Inv[NeedFarmItem] and Inv[NeedFarmItem].amount or 0
                        until not _G.Auto_Farm_Set or not Target.Parent or Target.Humanoid.Health <= 0 or Have >= ((LowestSet + 1) * NeedAmount)

                        _G.CanAutoSkill = false
                        break
                    else
                        local Spawn = workspace.Itemdrops:FindFirstChild(MobName)
                        if Spawn then Teleport(Spawn:GetPivot()); task.wait(1.5); break end
                    end
                end
            end)
        end
    end
end)

-- AUTO RAID BOSS v40
_G.RaidPhase            = "IDLE"
_G.RaidPortalRef        = nil
_G.RaidFireTimestamp    = 0
_G.RaidFired            = false
_G.RaidForceFirePending = false
_G.RaidPrevRunning      = false
_G.RaidBP               = nil
_G.RaidWaitOldPortal    = nil
_G.RaidWaitPortalStart  = nil
_G.RaidClearStart       = nil
_G.RaidLastFireTime     = 0
_G.RaidToolWaitStart    = nil
_G.RaidAttacking        = false
_G.RaidRespawnTime      = 0
_G.RaidSkipBossFight    = 0
_G.RaidLastAttack       = 0
_G.RaidLastSkill        = 0
_G.RaidLastEquip        = 0
_G.RaidCurrentTarget    = nil
_G.RaidCurrentOffset    = nil

local RAID_PORTAL_CD      = 8
local RAID_FIRE_VALID_WIN = 20
local HOVER_HEIGHT        = 100
local RAID_MIN_FIRE_GAP   = 3
local RESPAWN_SKIP_TIME   = 15

local function CreateRaidBP(hrp, position, force)
    if not hrp or not hrp.Parent then return end
    if hrp:FindFirstChild("RaidBP") then hrp.RaidBP:Destroy() end

    local bp = Instance.new("BodyPosition")
    bp.Name     = "RaidBP"
    bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bp.P        = force or 30000
    bp.D        = 5000
    bp.Position = position
    bp.Parent   = hrp
    _G.RaidBP = bp
    return bp
end

local function StartRaidHover(hrp, height)
    if not hrp or not hrp.Parent then return end
    height = height or HOVER_HEIGHT
    local targetPos = hrp.Position + Vector3.new(0, height, 0)
    CreateRaidBP(hrp, targetPos, 30000)
end

local function StopRaidHover(hrp, silent)
    if not hrp then
        hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    end
    if hrp then
        for _, name in ipairs({"RaidBP", "RaidHoverBP", "RaidHoverGyro", "RaidAnchorBP"}) do
            if hrp:FindFirstChild(name) then hrp[name]:Destroy() end
        end
    end
    _G.RaidBP = nil
    if not silent then end
end

local function HasToolEquipped()
    local char = LocalPlayer.Character
    if not char then return false end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then return true end
    end
    return false
end

local function HasToolInBackpack()
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if not bp then return false end
    for _, v in ipairs(bp:GetChildren()) do
        if v:IsA("Tool") then return true end
    end
    return false
end

local function HasAnyTool()
    return HasToolEquipped() or HasToolInBackpack()
end

local RaidHeartbeatConn = nil

local function StartRaidFollow()
    if RaidHeartbeatConn then return end
    RaidHeartbeatConn = RunService.Heartbeat:Connect(function()
        if not _G.AutoRaidRunning then return end
        local target = _G.RaidCurrentTarget
        if not target or not target.Parent then return end

        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end

        local offset = _G.RaidCurrentOffset or Vector3.new(0, 25, 0)
        local name = target.Parent and target.Parent.Name or ""
        if name == "ArmorBall1" or name == "ArmorBall2" then
            offset = Vector3.new(0, _G.RaidBallOffsetY or 25, 0)
        elseif name == "Boss Bacon Sad" then
            offset = Vector3.new(0, _G.RaidBossOffsetY or 55, 5)
        end

        local targetPos = target.Position + offset
        hrp.CFrame = CFrame.new(targetPos, target.Position)
        hrp.AssemblyLinearVelocity   = Vector3.zero
        hrp.AssemblyAngularVelocity  = Vector3.zero
    end)
end

local function StopRaidFollow()
    if RaidHeartbeatConn then
        RaidHeartbeatConn:Disconnect()
        RaidHeartbeatConn = nil
    end
    _G.RaidCurrentTarget = nil
    _G.RaidCurrentOffset = nil
end

local function CleanupRaidTags()
    StopRaidFollow()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, name in ipairs({"AutoRaidBP", "AutoRaidAP", "AutoRaidAO", "AutoRaidAtt", "RaidSmoothBP", "BodyClip"}) do
        if hrp:FindFirstChild(name) then hrp[name]:Destroy() end
    end
end

local function AttackTarget(targetPart, targetModel, offsetY, offsetX)
    if not targetPart or not targetModel then return end
    if not targetModel:FindFirstChild("Humanoid") then return end
    if targetModel.Humanoid.Health <= 0 then return end
    if _G.RaidAttacking then return end
    if tick() < _G.RaidSkipBossFight then
        return
    end

    _G.RaidAttacking = true
    _G.CanAutoSkill = true

    targetModel.Humanoid.WalkSpeed = 0
    targetModel.Humanoid.JumpPower = 0

    _G.RaidCurrentTarget = targetPart
    _G.RaidCurrentOffset = Vector3.new(offsetX or 0, offsetY or 25, 0)

    local attackStart    = tick()
    local lastHealth     = targetModel.Humanoid.Health
    local stuckStart     = tick()
    local toolWaitStart  = tick()

    task.spawn(function()
        while _G.RaidAttacking do
            task.wait(0.05)

            if not _G.AutoRaidRunning then break end
            if not targetModel or not targetModel.Parent then break end
            if not targetModel:FindFirstChild("Humanoid") then break end
            if targetModel.Humanoid.Health <= 0 then break end
            if tick() < _G.RaidSkipBossFight then break end

            if _G.RaidCurrentTarget == targetPart then
                local newOffsetY
                local name = targetModel.Name
                if name == "ArmorBall1" or name == "ArmorBall2" then
                    newOffsetY = _G.RaidBallOffsetY or 25
                elseif name == "Boss Bacon Sad" then
                    newOffsetY = _G.RaidBossOffsetY or 55
                else
                    newOffsetY = offsetY or 25
                end
                _G.RaidCurrentOffset = Vector3.new(offsetX or 0, newOffsetY, 0)
            end

            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            if not hum or hum.Health <= 0 then break end
            if not targetPart or not targetPart.Parent then break end

            local now = tick()

            if now - attackStart > 60 then
                break
            end

            local hasTool = HasAnyTool()
            if not hasTool then
                if now - attackStart > 8 then
                    break
                end
                if now - toolWaitStart > 1 then
                    toolWaitStart = now
                end
            else
                if now - _G.RaidLastEquip >= 0.5 then
                    _G.RaidLastEquip = now
                    EquipWeapon()
                end

                local autoAtk = _G.RaidAutoAttack
                local autoSkl = _G.RaidAutoSkill

                if autoAtk and autoSkl then
                    if now - _G.RaidLastSkill >= 0.1 then
                        _G.RaidLastSkill = now
                        AutoSkill()
                    end
                    if now - _G.RaidLastAttack >= 0.15 then
                        _G.RaidLastAttack = now
                        Attack()
                    end
                elseif autoSkl then
                    if now - _G.RaidLastSkill >= 0.1 then
                        _G.RaidLastSkill = now
                        AutoSkill()
                    end
                else
                    if now - _G.RaidLastAttack >= 0.08 then
                        _G.RaidLastAttack = now
                        Attack()
                    end
                end
            end

            if targetModel.Humanoid.Health < lastHealth then
                lastHealth = targetModel.Humanoid.Health
                stuckStart = now
            elseif now - stuckStart > 15 and hasTool then
                break
            end
        end

        _G.RaidAttacking    = false
        _G.RaidCurrentTarget = nil
        _G.RaidCurrentOffset = nil
        _G.CanAutoSkill      = false
    end)
end

local function EnterRaidPortal(hrp, timeout)
    if _G.RaidPhase == "ENTERING" then return end
    _G.RaidPhase = "ENTERING"
    _G.CanAutoSkill = false

    timeout = timeout or 10
    local startTime = tick()
    local fireTime  = _G.RaidFireTimestamp

    local TPZone, Hitbox
    repeat task.wait(0.03)
        if not _G.AutoRaidRunning then
            StopRaidHover(hrp, true)
            _G.RaidPhase = "IDLE"
            _G.RaidFired = false
            return
        end

        local zone = workspace:FindFirstChild("TeleportBossFightZone")
        if zone and zone:FindFirstChild("Hitbox") then
            local isDifferent = (_G.RaidPortalRef == nil) or (zone ~= _G.RaidPortalRef)
            local isValidTime = true
            if fireTime > 0 and tick() - fireTime > RAID_FIRE_VALID_WIN then
                isValidTime = false
            end
            if isDifferent and isValidTime then
                TPZone = zone
                Hitbox = zone.Hitbox
                break
            end
        end
    until tick() - startTime >= timeout

    if not Hitbox then
        StopRaidHover(hrp, true)
        _G.RaidPhase = "IDLE"
        _G.RaidFired = false
        return
    end

    _G.RaidPortalRef = TPZone

    hrp.CFrame = CFrame.new(Hitbox.Position + Vector3.new(0, 8, 0))
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    CreateRaidBP(hrp, Hitbox.Position + Vector3.new(0, 8, 0), 8000)

    local enterStart = tick()
    local LastPrint  = 0

    repeat task.wait(0.05)
        if not _G.AutoRaidRunning then break end
        if tick() - enterStart > 10 then
            break
        end

        if not TPZone.Parent or not TPZone:FindFirstChild("Hitbox") then
            break
        end

        if hrp.Parent and Hitbox.Parent then
            local dist = (hrp.Position - Hitbox.Position).Magnitude
            if dist > 200 then
                break
            end

            local targetPos = Hitbox.Position + Vector3.new(0, 8, 0)
            if _G.RaidBP and _G.RaidBP.Parent then
                if (_G.RaidBP.Position - targetPos).Magnitude > 5 then
                    _G.RaidBP.Position = targetPos
                end
            else
                hrp.CFrame = CFrame.new(targetPos)
                CreateRaidBP(hrp, targetPos, 8000)
            end
        end

        if tick() - LastPrint > 3 then
            LastPrint = tick()
            local dist = (hrp.Parent and Hitbox.Parent) and math.floor((hrp.Position - Hitbox.Position).Magnitude) or -1
        end
    until false

    StopRaidHover(hrp, true)
    _G.RaidPhase = "WAIT_PORTAL"
    _G.RaidWaitPortalStart = tick()
    _G.RaidFired = false
end

task.spawn(function()
    while task.wait(0.15) do
        if _G.RaidPrevRunning and not _G.AutoRaidRunning then
            StopRaidHover(nil, true)
            _G.RaidPhase            = "IDLE"
            _G.RaidPortalRef        = nil
            _G.RaidFireTimestamp    = 0
            _G.RaidFired            = false
            _G.RaidForceFirePending = false
            _G.RaidRespawnTime      = 0
            _G.RaidAttacking        = false
            _G.RaidSkipBossFight    = 0
            _G.CanAutoSkill         = false
        end
        _G.RaidPrevRunning = _G.AutoRaidRunning

        if not _G.AutoRaidRunning then continue end

        local Data = RaidBossData and RaidBossData[_G.AutoRaidWho]
        if not (Data and Data.Valid) then continue end

        pcall(function()
            local char = LocalPlayer.Character

            if _G.RaidPhase == "DEAD" then
                local newHum = char and char:FindFirstChild("Humanoid")
                local newHrp = char and char:FindFirstChild("HumanoidRootPart")

                if newHum and newHrp and newHum.Health > 0 then
                    _G.RaidPhase            = "IDLE"
                    _G.RaidFired            = false
                    _G.RaidPortalRef        = nil
                    _G.RaidFireTimestamp    = 0
                    _G.RaidWaitOldPortal    = nil
                    _G.RaidWaitPortalStart  = nil
                    _G.RaidClearStart       = nil
                    _G.RaidForceFirePending = true
                    _G.RaidLastFireTime     = 0
                    _G.RaidLastAttack       = 0
                    _G.RaidLastSkill        = 0
                    _G.RaidLastEquip        = 0
                    _G.RaidToolWaitStart    = nil
                    _G.RaidRespawnTime      = tick()
                    _G.RaidAttacking        = false
                    _G.RaidSkipBossFight    = tick() + RESPAWN_SKIP_TIME
                    _G.CanAutoSkill         = false
                    StopRaidHover(newHrp, true)
                    CleanupRaidTags()

                    task.wait(2)
                    return
                else
                    task.wait(0.2)
                    return
                end
            end

            local hum = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end

            if hum.Health <= 0 then
                if _G.RaidPhase ~= "DEAD" then
                    _G.RaidPhase = "DEAD"
                    _G.RaidAttacking = false
                    _G.CanAutoSkill = false
                    StopRaidHover(hrp, true)
                    CleanupRaidTags()
                end
                return
            end

            if _G.RaidRespawnTime > 0 and tick() - _G.RaidRespawnTime < 2 then
                if not hrp:FindFirstChild("RaidBP") then
                    StartRaidHover(hrp, HOVER_HEIGHT)
                end
                task.wait(0.3)
                return
            end

            if tick() < _G.RaidSkipBossFight then
                _G.CanAutoSkill = false

                local bfCheck = workspace:FindFirstChild("Boss Fight")
                local baconCheck = bfCheck and bfCheck:FindFirstChild("Bacon of Grudge")

                if not bfCheck or not baconCheck then
                    _G.RaidSkipBossFight    = 0
                    _G.RaidPhase            = "IDLE"
                    _G.RaidPortalRef        = nil
                    _G.RaidFired            = false
                    _G.RaidForceFirePending = true
                    _G.RaidLastFireTime     = 0
                    task.wait(0.3)
                    return
                end

                if not hrp:FindFirstChild("RaidBP") then
                    StartRaidHover(hrp, HOVER_HEIGHT)
                end

                local skipElapsed = tick() - (_G.RaidRespawnTime or tick())
                if skipElapsed > RESPAWN_SKIP_TIME then
                    _G.RaidSkipBossFight    = 0
                    _G.RaidPhase            = "IDLE"
                    _G.RaidPortalRef        = nil
                    _G.RaidFired            = false
                    _G.RaidForceFirePending = true
                    _G.RaidLastFireTime     = 0
                    task.wait(0.3)
                    return
                end

                task.wait(0.3)
                return
            end

            local bf          = workspace:FindFirstChild("Boss Fight")
            local baconFolder = bf and bf:FindFirstChild("Bacon of Grudge")

            if _G.RaidPhase == "CLEARING" then
                _G.CanAutoSkill = false

                if not hrp:FindFirstChild("RaidBP") then
                    StartRaidHover(hrp, HOVER_HEIGHT)
                end

                _G.RaidClearStart = _G.RaidClearStart or tick()
                local elapsed = tick() - _G.RaidClearStart

                if elapsed > 3 or not workspace:FindFirstChild("Boss Fight") then
                    _G.RaidPhase            = "IDLE"
                    _G.RaidPortalRef        = nil
                    _G.RaidFired            = false
                    _G.RaidForceFirePending = true
                    _G.RaidClearStart       = nil
                    _G.RaidLastFireTime     = 0
                    _G.RaidLastAttack       = 0
                    _G.RaidLastSkill        = 0
                end
                task.wait(0.2)
                return
            end

            if baconFolder then
                local A1 = baconFolder:FindFirstChild("ArmorBall1")
                local A2 = baconFolder:FindFirstChild("ArmorBall2")
                local BossBacon = baconFolder:FindFirstChild("Boss Bacon Sad")

                local a1Alive   = A1 and A1:FindFirstChild("Humanoid") and A1.Humanoid.Health > 0
                local a2Alive   = A2 and A2:FindFirstChild("Humanoid") and A2.Humanoid.Health > 0
                local bossAlive = BossBacon and BossBacon:FindFirstChild("Humanoid") and BossBacon.Humanoid.Health > 0

                if not (a1Alive or a2Alive or bossAlive) then
                    _G.CanAutoSkill = false

                    if _G.RaidPhase ~= "CLEARING" then
                        _G.RaidPhase      = "CLEARING"
                        _G.RaidFired      = false
                        _G.RaidClearStart = tick()
                        _G.RaidAttacking  = false
                        StopRaidHover(hrp, true)
                        StartRaidHover(hrp, HOVER_HEIGHT)
                    end
                    return
                end

                if not HasAnyTool() then
                    _G.CanAutoSkill = false

                    _G.RaidToolWaitStart = _G.RaidToolWaitStart or tick()
                    if tick() - _G.RaidToolWaitStart < 5 then
                        if not hrp:FindFirstChild("RaidBP") then
                            StartRaidHover(hrp, HOVER_HEIGHT)
                        end
                        task.wait(0.3)
                        return
                    end
                    _G.RaidToolWaitStart = nil
                    _G.RaidPhase = "CLEARING"
                    _G.RaidClearStart = tick()
                    _G.RaidAttacking = false
                    return
                end
                _G.RaidToolWaitStart = nil

                if _G.RaidPhase ~= "FIGHTING" then
                    _G.RaidPhase = "FIGHTING"
                    _G.RaidFired = false
                end
                StopRaidHover(hrp, true)
                StartRaidFollow()

                if not _G.RaidAttacking then
                    if a1Alive then
                        AttackTarget(A1:FindFirstChild("HumanoidRootPart"), A1, _G.RaidBallOffsetY or 25, 0)
                    elseif a2Alive then
                        AttackTarget(A2:FindFirstChild("HumanoidRootPart"), A2, _G.RaidBallOffsetY or 25, 0)
                    elseif bossAlive then
                        local bossHrp = BossBacon:FindFirstChild("HumanoidRootPart")
                        if bossHrp then
                            AttackTarget(bossHrp, BossBacon, _G.RaidBossOffsetY or 55, 5)
                        end
                    end
                end
                task.wait(0.5)
                return
            end

            if _G.RaidPhase == "ENTERING" then
                task.wait(0.2)
                return
            end

            if _G.RaidPhase == "WAIT_PORTAL" then
                _G.CanAutoSkill = false

                local elapsed = tick() - (_G.RaidWaitPortalStart or tick())

                local bfCheck = workspace:FindFirstChild("Boss Fight")
                local baconCheck = bfCheck and bfCheck:FindFirstChild("Bacon of Grudge")
                local bossAlive = false
                if baconCheck and baconCheck:FindFirstChild("Humanoid") then
                    bossAlive = baconCheck.Humanoid.Health > 0
                end

                if bossAlive then
                    if tick() < _G.RaidSkipBossFight then
                        _G.RaidWaitPortalStart = nil
                        _G.RaidPhase = "CLEARING"
                        _G.RaidClearStart = tick()
                        return
                    end
                    _G.RaidWaitPortalStart = nil
                    _G.RaidPhase = "FIGHTING"
                    return
                end

                if elapsed > 4 then
                    _G.RaidWaitPortalStart = nil
                    _G.RaidPhase = "IDLE"
                    _G.RaidPortalRef = nil
                    _G.RaidFired = false
                    _G.RaidForceFirePending = true
                end

                task.wait(0.1)
                return
            end

            if _G.RaidPhase == "IDLE" then
                _G.CanAutoSkill = false

                if _G.RaidForceFirePending then
                    _G.RaidForceFirePending = false
                    _G.RaidPortalRef        = nil
                    _G.RaidFireTimestamp    = 0
                    _G.RaidFired            = false
                    _G.RaidWaitOldPortal    = nil
                    _G.RaidLastFireTime     = 0
                    _G.RaidLastAttack       = 0
                    _G.RaidLastSkill        = 0
                end

                if _G.RaidFired then
                    task.wait(0.3)
                    return
                end

                if tick() - _G.RaidLastFireTime < RAID_MIN_FIRE_GAP then
                    task.wait(0.2)
                    return
                end

                local bfCheck = workspace:FindFirstChild("Boss Fight")
                local baconCheck = bfCheck and bfCheck:FindFirstChild("Bacon of Grudge")
                local bossAlive = false
                if baconCheck and baconCheck:FindFirstChild("Humanoid") then
                    bossAlive = baconCheck.Humanoid.Health > 0
                end

                if bossAlive then
                    _G.RaidPhase = "FIGHTING"
                    task.wait(0.2)
                    return
                end

                local oldPortal = _G.RaidPortalRef
                if oldPortal ~= nil and oldPortal.Parent then
                    _G.RaidWaitOldPortal = _G.RaidWaitOldPortal or tick()
                    if tick() - _G.RaidWaitOldPortal > 3 then
                        _G.RaidPortalRef = nil
                        _G.RaidWaitOldPortal = nil
                    else
                        if not hrp:FindFirstChild("RaidBP") then
                            StartRaidHover(hrp, HOVER_HEIGHT)
                        end
                        task.wait(0.2)
                        return
                    end
                else
                    _G.RaidWaitOldPortal = nil
                end
                _G.RaidPortalRef = nil

                if not hrp:FindFirstChild("RaidBP") then
                    StartRaidHover(hrp, HOVER_HEIGHT)
                end

                if GetItemAmount("Portal Gun") < Data.PortalCost then
                    _G.SeaNotify("❌ Not enough Portal Gun", "Need " .. Data.PortalCost .. " Portal Gun!", 4)
                    StopRaidHover(hrp, true)
                    _G.AutoRaidRunning = false
                    return
                end

                _G.RaidFireTimestamp = tick()
                _G.RaidLastFireTime  = tick()
                _G.RaidFired         = true
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "SpawnBossFight", Data.Name)

                EnterRaidPortal(hrp, 10)
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if not _G.AutoRaidRunning then
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Anchored and not workspace:FindFirstChild("Boss Fight") then
                hrp.Anchored = false
            end
            if _G.RaidBP and _G.RaidBP.Parent then
                StopRaidHover(hrp, true)
            end
            _G.RaidPhase = "IDLE"
        end
    end
end)

-- AUTO BACON THIEF
local CurrentSpawn = 1
task.spawn(function()
    while task.wait() do
        pcall(function()
            if not _G.Auto_BaconThief then return end
            local Spawns = workspace.MobSpawnGroup:GetChildren()
            local Spawn  = Spawns[CurrentSpawn]
            if not Spawn then CurrentSpawn = 1; return end
            local ChestRef = Spawn:FindFirstChild("ChestRef", true)
            if ChestRef then
                local Target
                local Distance = 30
                for _, Mob in ipairs(workspace.Mob:GetChildren()) do
                    if Mob:IsA("Model") and Mob.Name == "Bacon Thief" and Mob:FindFirstChild("HumanoidRootPart") and Mob:FindFirstChild("Humanoid") and Mob.Humanoid.Health > 0 then
                        local Mag = (Mob.HumanoidRootPart.Position - ChestRef.Position).Magnitude
                        if Mag < Distance then Distance = Mag; Target = Mob end
                    end
                end
                if Target then
                    Target.Humanoid.WalkSpeed = 0
                    Target.Humanoid.JumpPower = 0

                    _G.CanAutoSkill = true

                    EquipWeapon()
                    AutoSkill()
                    Attack()

                    Teleport(Target.HumanoidRootPart.CFrame * MethodFarm)
                else
                    _G.CanAutoSkill = false

                    local Prompt = ChestRef:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if Prompt and Prompt.Parent and Prompt.ActionText == "Open" then
                        Teleport(ChestRef.CFrame * CFrame.new(0, 3, 0))
                        fireproximityprompt(Prompt)
                    else
                        CurrentSpawn = CurrentSpawn + 1
                    end
                end
            else
                CurrentSpawn = CurrentSpawn + 1
            end
        end)
    end
end)

-- AUTO RAID MOON
task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_Raid then
                if game.PlaceId == MOON_PLACE_ID then
                    for _, v in pairs(workspace.Mob:GetChildren()) do
                        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0

                            _G.CanAutoSkill = true

                            repeat task.wait()
                                EquipWeapon(); AutoSkill(); Attack()
                                Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
                            until not _G.Auto_Raid or not v.Parent or v.Humanoid.Health <= 0

                            _G.CanAutoSkill = false
                        end
                    end
                else
                    _G.CanAutoSkill = false

                    if workspace:FindFirstChild("TeleportMoonZone") then
                        Teleport(workspace:FindFirstChild("TeleportMoonZone").Hitbox:GetPivot() * CFrame.new(0, -8, 0))
                    else
                        if GetItemAmount("Space Ticket") >= 1 then
                            Teleport(workspace.NpcPrompt.GoMoon.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0))
                            fireproximityprompt(workspace.NpcPrompt.GoMoon.HumanoidRootPart:FindFirstChildOfClass("ProximityPrompt"))
                        else
                            local Diamond = LocalPlayer:GetAttribute("Diamond") or 0
                            if Diamond >= 150 then
                                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "RandomItem", "x15")
                            else
                                local quest = GetQuest_Level(tonumber(LocalPlayer:GetAttribute("Level")))
                                if not quest then return end
                                local Frame = GetQuestFrame()
                                local Text  = Frame.Title.Text or ""
                                if LocalPlayer.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
                                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                                end
                                if Frame.Visible and not string.find(Text, quest.Monster) then
                                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                                    repeat task.wait() until not Frame.Visible
                                end
                                if not Frame.Visible then
                                    local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
                                    if npc then
                                        Teleport(npc.CFrame * MethodFarm)
                                        task.wait(0.3)
                                        local pro_xim = npc:FindFirstChildOfClass("ProximityPrompt")
                                        if pro_xim then fireproximityprompt(pro_xim) end
                                    end
                                else
                                    for _, v in pairs(workspace.Mob:GetChildren()) do
                                        if v:IsA("Model") and v.Name == quest.Monster and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                                            local hrp = v:FindFirstChild("HumanoidRootPart")
                                            if hrp then
                                                v.Humanoid.WalkSpeed = 0
                                                v.Humanoid.JumpPower = 0

                                                _G.CanAutoSkill = true

                                                repeat task.wait()
                                                    EquipWeapon(); AutoSkill(); Attack()
                                                    Teleport(hrp.CFrame * MethodFarm)
                                                until not _G.Auto_Raid or v.Humanoid.Health <= 0

                                                _G.CanAutoSkill = false
                                            end
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- ============================================================
-- AUTO DUNGEON
-- ============================================================
task.spawn(function()
    while task.wait() do
        xpcall(function()
            if not _G.Auto_Dungeon then return end

            local Player = game.Players.LocalPlayer
            local Character = Player.Character
            if not Character then return end

            local hum = Character:FindFirstChild("Humanoid")
            local hrp = Character:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end

            local HpPercent = (hum.Health / hum.MaxHealth) * 100
            if HpPercent < _G.HealthPercent then
                hrp.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y + 200, hrp.Position.Z)
                task.wait(0.5)
                return
            end

            local Dungeon
            local DungeonId = Character:GetAttribute("Dungeon")
            local GuiService = game:GetService("GuiService")
            local VirtualInputManager = game:GetService("VirtualInputManager")

            if Player.PlayerGui:FindFirstChild("WaveUI")
               and Player.PlayerGui.WaveUI.AutoSkip.BackgroundColor3 == Color3.fromRGB(255, 69, 69) then
                GuiService.SelectedObject = Player.PlayerGui.WaveUI.AutoSkip
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                task.wait(0.1)
                GuiService.SelectedObject = nil
            end

            if DungeonId then
                Dungeon = workspace.DungeonMap:FindFirstChild("Dungeon_" .. DungeonId)
            end

            if Dungeon then
                local Target, MinDist = nil, math.huge
                for _, Mob in ipairs(workspace.Mob:GetChildren()) do
                    if Mob:IsA("Model")
                       and Mob:FindFirstChild("Humanoid")
                       and Mob:FindFirstChild("HumanoidRootPart")
                       and Mob.Humanoid.Health > 0 then
                        local dist = (Mob.HumanoidRootPart.Position - Dungeon:GetPivot().Position).Magnitude
                        if dist <= 250 and dist < MinDist then
                            MinDist = dist
                            Target = Mob
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

                    EquipWeapon()
                    AutoSkill()
                    Attack()
                else
                    _G.CanAutoSkill = false

                    if hrp:FindFirstChild("DungeonBP") then
                        hrp.DungeonBP:Destroy()
                    end
                end
            else
                _G.CanAutoSkill = false

                local TeleportZone = workspace:FindFirstChild("TeleportDungeonZone")
                if TeleportZone and TeleportZone:FindFirstChild("Hitbox") then
                    hrp.CFrame = TeleportZone.Hitbox.CFrame
                else
                    if GetItemAmount("Orb Dungeon") >= _G.Dungeon_UseValue then
                        local NPC = workspace.NpcPrompt["Open Dungeon"].HumanoidRootPart
                        hrp.CFrame = NPC.CFrame * CFrame.new(0, 5, 0)
                        game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer(
                            "fire", nil, "SpawnDungeon", _G.Dungeon_UseValue
                        )
                    else
                        local Diamond = Player:GetAttribute("Diamond") or 0
                        if Diamond >= 150 then
                            game.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                                "fire", nil, "RandomItem", "x15"
                            )
                        else
                            local quest = GetQuest_Level(tonumber(Player:GetAttribute("Level")))
                            if not quest then return end

                            local Frame = GetQuestFrame()
                            local Text = Frame.Title.Text or ""

                            if Player.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
                                game.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                                    "fire", nil, "Quest", "Cancel"
                                )
                            end

                            if Frame.Visible and not string.find(Text, quest.Monster) then
                                game.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                                    "fire", nil, "Quest", "Cancel"
                                )
                                repeat task.wait() until not Frame.Visible
                            end

                            if not Frame.Visible then
                                local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
                                if npc then
                                    hrp.CFrame = npc.CFrame * MethodFarm
                                    task.wait(0.3)
                                    local pro = npc:FindFirstChildOfClass("ProximityPrompt")
                                    if pro then fireproximityprompt(pro) end
                                end
                            else
                                for _, v in ipairs(workspace.Mob:GetChildren()) do
                                    if v:IsA("Model")
                                       and v.Name == quest.Monster
                                       and v:FindFirstChild("Humanoid")
                                       and v:FindFirstChild("HumanoidRootPart")
                                       and v.Humanoid.Health > 0 then
                                        v.Humanoid.WalkSpeed = 0
                                        v.Humanoid.JumpPower = 0
                                        hrp.CFrame = v.HumanoidRootPart.CFrame * MethodFarm
                                        EquipWeapon()
                                        AutoSkill()
                                        Attack()
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

-- AUTO CLOSE REWARD GUI
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            if not hud or not hud:FindFirstChild("Main") then return end

            local closeList = {
                {_G.Auto_Dungeon,   "Frame_DungeonItem"},
                {_G.AutoRaidRunning, "Frame_RaidbossItem"}
            }

            for _, entry in ipairs(closeList) do
                if entry[1] then
                    local fd = hud.Main:FindFirstChild(entry[2])
                    if fd and fd.Visible then
                        task.wait(2)
                        local closeBtn = fd:FindFirstChild("Close_")
                            or fd:FindFirstChild("Close")
                            or fd:FindFirstChild("CloseButton")
                            or fd:FindFirstChild("Exit")
                        if closeBtn then
                            pcall(function()
                                if firesignal then firesignal(closeBtn.MouseButton1Click)
                                else closeBtn:Activate() end
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

-- NOCLIP + ANTI-GRAVITY
task.spawn(function()
    while task.wait() do
        if _G.Auto_Farm_Level or _G.Auto_CraftWeapon or _G.Auto_Farm_Material
           or _G.Auto_FarmBoss_Automatically or _G.Auto_FarmBoss
           or _G.Auto_DuckAutomatically or _G.Auto_Duck or _G.Auto_Farm_Set
           or _G.Auto_Raid or _G.Auto_BaconThief or _G.Auto_Dungeon
           or _G.Auto_Piccolo or _G.Auto_DevilBoat or _G.Auto_Kraken then
            pcall(function()
                local char = LocalPlayer.Character
                local HRP  = char and char:FindFirstChild("HumanoidRootPart")
                if HRP then
                    HRP.AssemblyAngularVelocity = Vector3.zero
                    local Vel = HRP.AssemblyLinearVelocity
                    HRP.AssemblyLinearVelocity = Vector3.new(0, Vel.Y, 0)
                end
            end)
        end
    end
end)

task.spawn(function()
    pcall(function()
        RunService.Stepped:Connect(function()
    if _G.Auto_Farm_Level or _G.Auto_CraftWeapon or _G.Auto_Farm_Material
       or _G.Auto_FarmBoss_Automatically or _G.Auto_FarmBoss
       or _G.Auto_DuckAutomatically or _G.Auto_Duck or _G.Auto_Farm_Set
       or _G.Auto_Raid or _G.Auto_BaconThief or _G.Auto_Dungeon
       or _G.Auto_Piccolo or _G.Auto_DevilBoat or _G.Auto_Kraken then
                local char = LocalPlayer.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if not hrp:FindFirstChild("BodyClip") then
                        local Noclip   = Instance.new("BodyVelocity")
                        Noclip.Name     = "BodyClip"
                        Noclip.Parent   = hrp
                        Noclip.MaxForce = Vector3.new(100000, 100000, 100000)
                        Noclip.Velocity = Vector3.new(0, 0, 0)
                    end
                end
            else
                local char = LocalPlayer.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and hrp:FindFirstChild("BodyClip") then hrp.BodyClip:Destroy() end
            end
        end)
    end)
end)

if not IS_MOON_MAP then
-- ============================================================
-- 🆕 AUTO RAID BOSS DRAGON — v11 FINAL (integrated)
-- ============================================================
_G.AutoRaidDragon             = false
_G.DragonLastFireTime         = 0
_G.DragonLastAttack           = 0
_G.DragonLastEquip            = 0
_G.DragonEnterTime            = 0
_G.DragonPortalPhase          = "IDLE"
_G.DragonPortalStartTime      = 0
_G.DragonPortalFireLock       = 0
_G.DragonAlertTriggered       = false
_G.DragonSafeZoneActive       = false
_G.DragonLastSafeTP           = 0
_G.DragonSafeZonePart         = nil
_G.DragonBossDeadHandled      = false
_G.DragonThanosFSuccessCount  = 0
_G.DragonThanosSpamStartTime  = 0
_G.DragonThanosFlyPos         = nil
_G.DragonLastThanosTime       = 0
_G.DragonBuffUsed             = false
_G.DragonBuffFinishTime       = 0
_G.DragonHasThanosEquipped    = false
_G.DragonBuffSpamActive       = false
_G.DragonBuffSpamStartTime    = 0
_G.DragonBuffSpamFinishTime   = 0

local DRAGON_AIM_HEIGHT        = 25
local DRAGON_MIN_FIRE_GAP      = 3
local DRAGON_PORTAL_TIMEOUT    = 15
local DRAGON_PORTAL_FIRE_LOCK  = 5
local DRAGON_SAFE_HEIGHT_FLY   = 500
local DRAGON_THANOS_COOLDOWN   = 0.3
local DRAGON_BUFF_COOLDOWN     = 0.3
local DRAGON_BUFF_LIST         = {"Kaioken", "SSJ", "SSJ2", "SSJ3", "SSJG"}

-- 🆕 Lấy Action global cho scope Dragon
local DragonAction = ReplicatedStorage:FindFirstChild("Remotes")
DragonAction = DragonAction and DragonAction:FindFirstChild("Action")

local function GetDragonMethodFarm(height)
    height = height or DRAGON_AIM_HEIGHT
    return CFrame.new(0, height, 0) * CFrame.Angles(math.rad(-90), 0, 0)
end

-- =====================================================
-- Tìm tool Thanos
-- =====================================================
local function FindThanosTool()
    local char = LocalPlayer.Character
    if not char then return nil, "character" end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            if name == "thanos" or name:find("thanos") then
                return tool, "character"
            end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name == "thanos" or name:find("thanos") then
                    return tool, "backpack"
                end
            end
        end
    end
    return nil, "none"
end

-- =====================================================
-- Tìm tool buff
-- =====================================================
local function FindBuffTool()
    local char = LocalPlayer.Character
    if not char then return nil, nil end

    for _, buffName in ipairs(DRAGON_BUFF_LIST) do
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower() == buffName:lower() then
                return tool, buffName
            end
        end
    end

    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, buffName in ipairs(DRAGON_BUFF_LIST) do
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") and tool.Name:lower() == buffName:lower() then
                    return tool, buffName
                end
            end
        end
    end
    return nil, nil
end

local function EnsureThanosEquipped()
    local char = LocalPlayer.Character
    if not char then return false end
    local tool, location = FindThanosTool()
    if not tool then return false end
    if location == "character" then
        _G.DragonHasThanosEquipped = true
        return true
    end
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        pcall(function() hum:EquipTool(tool) end)
        task.wait(0.5)
        _G.DragonHasThanosEquipped = true
        print("[Dragon] 🗡️ Đã trang bị Thanos: " .. tool.Name)
        return true
    end
    return false
end

local function TryUseThanosF(hrp)
    if not hrp then return "no_tool" end
    local char = LocalPlayer.Character
    if not char then return "no_tool" end

    local thanosTool = nil
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            if name == "thanos" or name:find("thanos") then
                thanosTool = tool
                break
            end
        end
    end
    if not thanosTool then return "no_tool" end

    local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
    local main = hud and hud:FindFirstChild("Main")
    local skillList = main and main:FindFirstChild("Frame_SkillList_Thanos")

    if skillList then
        local border = skillList:FindFirstChild("Border")
        local mainFrame = border and border:FindFirstChild("Main")
        local fFrame = mainFrame and mainFrame:FindFirstChild("F")
        if fFrame then
            local readyLabel = fFrame:FindFirstChild("Ready")
            local cooldownFrame = fFrame:FindFirstChild("CooldownFrame")
            local isUnready = readyLabel and readyLabel.Text == "UnReady"
            local isCooldownVisible = cooldownFrame and cooldownFrame.Visible
            if isUnready or isCooldownVisible then
                return "cooldown"
            end
        end
    end

    task.wait(0.2)
    if DragonAction then
        pcall(function()
            DragonAction:FireServer(thanosTool.Name, "f")
        end)
        task.wait(0.6)  -- 🆕 tăng lên 0.6s để hitbox F register xong
        return "success"
    end
    return "no_tool"
end

-- Hook alert
local function OnDragonAlert(text)
    if not text then return end
    local lower = text:lower()
    if lower:find("gathering power", 1, true) then
        print("[Dragon] ⚠️ GATHERING POWER")
    end
    if lower:find("hide in the green zone", 1, true)
       or lower:find("green zone", 1, true) then
        if not _G.DragonAlertTriggered then
            _G.DragonAlertTriggered = true
            print("[Dragon] 🚨 PHASE 2: HIDE IN THE GREEN ZONE!")
        end
    end
end

local function HookDragonText(container)
    for _, obj in ipairs(container:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            OnDragonAlert(obj.Text)
            obj:GetPropertyChangedSignal("Text"):Connect(function()
                OnDragonAlert(obj.Text)
            end)
        end
    end
end
HookDragonText(LocalPlayer.PlayerGui)
LocalPlayer.PlayerGui.DescendantAdded:Connect(function(obj)
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        task.wait(0.1)
        OnDragonAlert(obj.Text)
        obj:GetPropertyChangedSignal("Text"):Connect(function()
            OnDragonAlert(obj.Text)
        end)
    end
end)

local function GetDragonBoss()
    local bf = workspace:FindFirstChild("Boss Fight")
    if not bf then return nil, nil, nil end
    local dragonFolder = bf:FindFirstChild("Dragon")
    if not dragonFolder then return nil, nil, nil end
    local bossModel = dragonFolder:FindFirstChild("Dragon Boss")
    if not bossModel then return nil, nil, nil end
    local bossHrp = bossModel:FindFirstChild("HumanoidRootPart")
    local bossHum = bossModel:FindFirstChild("Humanoid")
    if bossHrp and bossHum then
        return bossModel, bossHrp, bossHum
    end
    return nil, nil, nil
end

local function IsSafeZoneColor(c)
    return math.abs(c.R - 0.27) < 0.05
       and math.abs(c.G - 1.00) < 0.05
       and math.abs(c.B - 0.55) < 0.05
end

local function FindDragonSafeZone()
    if _G.DragonSafeZonePart and _G.DragonSafeZonePart.Parent then
        return _G.DragonSafeZonePart
    end
    local vfx = workspace:FindFirstChild("VFX")
    if not vfx then return nil end
    local bestPart, bestY = nil, math.huge
    for _, obj in ipairs(vfx:GetChildren()) do
        if obj:IsA("BasePart") and obj.Name == "Part" then
            if IsSafeZoneColor(obj.Color) then
                if obj.Position.Y < bestY then
                    bestY = obj.Position.Y
                    bestPart = obj
                end
            end
        end
    end
    if bestPart then
        print("[Dragon] 🎯 Vùng an toàn: Y=" .. string.format("%.1f", bestPart.Position.Y))
        _G.DragonSafeZonePart = bestPart
        return bestPart
    end
    return nil
end

local function CloseFrame(frame)
    if not frame then return false end
    local closeBtn = frame:FindFirstChild("Close_")
    if not closeBtn then
        closeBtn = frame:FindFirstChild("Close")
            or frame:FindFirstChild("CloseButton")
            or frame:FindFirstChild("Exit")
            or frame:FindFirstChildWhichIsA("ImageButton", true)
            or frame:FindFirstChildWhichIsA("TextButton", true)
    end
    if closeBtn then
        pcall(function()
            if firesignal then firesignal(closeBtn.MouseButton1Click) end
        end)
        pcall(function()
            if fireclickdetector then fireclickdetector(closeBtn) end
        end)
        pcall(function()
            local VIM = game:GetService("VirtualInputManager")
            local pos = closeBtn.AbsolutePosition + closeBtn.AbsoluteSize / 2
            VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait(0.05)
            VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end)
        return true
    end
    pcall(function() frame.Visible = false end)
    return true
end

-- =====================================================
-- DragonOpenPortal
-- =====================================================
local function DragonOpenPortal()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    if tick() < _G.DragonPortalFireLock then return false end

    local bf = workspace:FindFirstChild("Boss Fight")
    if bf and bf:FindFirstChild("Dragon") then
        _G.DragonPortalPhase = "IDLE"
        return true
    end

    -- BƯỚC 0: BUFF TRƯỚC KHI MỞ CỔNG
    if not _G.DragonBuffUsed then
        _G.DragonBuffUsed = true

        local tool, buffName = FindBuffTool()
        if tool then
            print("[Dragon] ⚡ Có buff " .. buffName .. ", bắt đầu spam F trước cổng")
            _G.DragonBuffSpamActive = true
            _G.DragonBuffSpamStartTime = tick()
            _G.DragonBuffFinishTime = 0

            task.spawn(function()
                local startTime = tick()
                local lastFTime = 0

                while _G.DragonBuffSpamActive and tick() - startTime < 15 do
                    local now = tick()
                    if now - lastFTime >= DRAGON_BUFF_COOLDOWN then
                        lastFTime = now

                        local c = LocalPlayer.Character
                        if not c then break end

                        local currentTool = nil
                        for _, t in ipairs(c:GetChildren()) do
                            if t:IsA("Tool") and t.Name:lower() == buffName:lower() then
                                currentTool = t
                                break
                            end
                        end

                        if not currentTool then
                            local bp = LocalPlayer:FindFirstChild("Backpack")
                            if bp then
                                for _, t in ipairs(bp:GetChildren()) do
                                    if t:IsA("Tool") and t.Name:lower() == buffName:lower() then
                                        c.Humanoid:EquipTool(t)
                                        task.wait(0.3)
                                        currentTool = t
                                        break
                                    end
                                end
                            end
                        end

                        if not currentTool then break end

                        local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                        local main = hud and hud:FindFirstChild("Main")
                        local skillList = main and main:FindFirstChild("Frame_SkillList_" .. buffName)

                        local fOnCooldown = false
                        if skillList then
                            local border = skillList:FindFirstChild("Border")
                            local mainFrame = border and border:FindFirstChild("Main")
                            local fFrame = mainFrame and mainFrame:FindFirstChild("F")
                            if fFrame then
                                local readyLabel = fFrame:FindFirstChild("Ready")
                                local cooldownFrame = fFrame:FindFirstChild("CooldownFrame")
                                local isUnready = readyLabel and readyLabel.Text == "UnReady"
                                local isCooldownVisible = cooldownFrame and cooldownFrame.Visible
                                if isUnready or isCooldownVisible then
                                    fOnCooldown = true
                                end
                            end
                        end

                        if fOnCooldown then
                            print("[Dragon] ⏹️ Buff F cooldown → dừng spam")
                            break
                        end

                        if DragonAction then
                            pcall(function()
                                DragonAction:FireServer(currentTool.Name, "f")
                            end)
                            print("[Dragon] ⚡ Buff F: " .. buffName)
                        end
                    end
                    task.wait(0.1)
                end

                _G.DragonBuffSpamActive = false
                print("[Dragon] ✅ Buff spam xong, đợi 1s rồi mở cổng")
                task.wait(1)
                _G.DragonBuffFinishTime = tick()
                print("[Dragon] ✅ Buff xong, bắt đầu mở cổng")
            end)

            return false
        else
            print("[Dragon] ⚠️ Không có buff tool, bỏ qua")
            _G.DragonBuffFinishTime = tick()
        end
    end

    if _G.DragonBuffFinishTime == 0 then
        return false
    end
    if tick() - _G.DragonBuffFinishTime < 1 then
        return false
    end

    -- BƯỚC 1: Portal
    local tz = workspace:FindFirstChild("TeleportBossFightZone")
    if tz and tz:FindFirstChild("Hitbox") then
        if _G.DragonPortalPhase ~= "ENTERED" then
            hrp.CFrame = tz.Hitbox.CFrame
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            print("[Dragon] 🌀 TP vào portal")
            _G.DragonEnterTime = tick()
            _G.DragonPortalPhase = "ENTERED"
            _G.DragonPortalFireLock = tick() + DRAGON_PORTAL_FIRE_LOCK
        end
        return true
    end

    -- BƯỚC 2: NPC
    local npcPrompt = workspace:FindFirstChild("NpcPrompt")
    local openRaidNPC = npcPrompt and npcPrompt:FindFirstChild("Open Raid")

    if openRaidNPC and _G.DragonPortalPhase == "IDLE" then
        local npcHrp = openRaidNPC:FindFirstChild("HumanoidRootPart")
            or openRaidNPC:FindFirstChildWhichIsA("BasePart")
        if npcHrp then
            local dist = (hrp.Position - npcHrp.Position).Magnitude
            if dist > 10 then
                hrp.CFrame = CFrame.new(npcHrp.Position + Vector3.new(0, 3, 0))
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                task.wait(0.3)
            end

            if tick() - _G.DragonLastFireTime >= DRAGON_MIN_FIRE_GAP then
                local prompt = openRaidNPC:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    _G.DragonLastFireTime = tick()
                    _G.DragonPortalPhase = "GUI_OPENING"
                    _G.DragonPortalStartTime = tick()
                    pcall(function() fireproximityprompt(prompt) end)
                    print("[Dragon] 👆 Fire NPC Open Raid")
                    return true
                end
            end
        end
    end

    -- BƯỚC 3: Click button
    if _G.DragonPortalPhase == "GUI_OPENING" then
        local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        local main = hud and hud:FindFirstChild("Main")
        local raidBossFrame = main and main:FindFirstChild("Frame_RaidBoss")

        if raidBossFrame then
            local dragonTemplate = raidBossFrame:FindFirstChild("Template_Dragon")
            if not dragonTemplate then
                local sf = raidBossFrame:FindFirstChild("ScrollingFrame")
                if sf then
                    for _, child in ipairs(sf:GetChildren()) do
                        if child.Name:lower():find("dragon") then
                            dragonTemplate = child
                            break
                        end
                    end
                end
            end

            if dragonTemplate then
                local openButton = nil
                for _, obj in ipairs(dragonTemplate:GetDescendants()) do
                    if obj:IsA("TextLabel") and obj.Text == "Open" then
                        local parent = obj.Parent
                        while parent and parent ~= dragonTemplate do
                            if parent:IsA("TextButton") or parent:IsA("ImageButton") then
                                openButton = parent
                                break
                            end
                            parent = parent.Parent
                        end
                        if openButton then break end
                    end
                end
                if not openButton then
                    local mainBtn = dragonTemplate:FindFirstChild("Main")
                    if mainBtn and (mainBtn:IsA("TextButton") or mainBtn:IsA("ImageButton")) then
                        openButton = mainBtn
                    end
                end

                if openButton then
                    print("[Dragon] 🖱️ Click button Open")
                    pcall(function()
                        if firesignal then
                            firesignal(openButton.MouseButton1Click)
                        else
                            openButton:Activate()
                        end
                    end)
                    _G.DragonPortalPhase = "WAITING"
                    _G.DragonPortalStartTime = tick()

                    task.spawn(function()
                        task.wait(0.3)
                        pcall(function()
                            local hud2 = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                            local main2 = hud2 and hud2:FindFirstChild("Main")
                            local raidBossFrame2 = main2 and main2:FindFirstChild("Frame_RaidBoss")
                            if raidBossFrame2 then
                                CloseFrame(raidBossFrame2)
                                print("[Dragon] 🚪 Đóng GUI mở cổng")
                            end
                        end)
                    end)
                    return true
                end
            end
        end

        if tick() - _G.DragonPortalStartTime > 5 then
            print("[Dragon] ⚠️ Timeout GUI → reset")
            _G.DragonPortalPhase = "IDLE"
        end
        return true
    end

    -- BƯỚC 4: Đợi portal
    if _G.DragonPortalPhase == "WAITING" then
        local elapsed = tick() - _G.DragonPortalStartTime
        local tz2 = workspace:FindFirstChild("TeleportBossFightZone")
        if tz2 and tz2:FindFirstChild("Hitbox") then
            hrp.CFrame = tz2.Hitbox.CFrame
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            print("[Dragon] 🌀 TP vào portal (sau click)")
            _G.DragonEnterTime = tick()
            _G.DragonPortalPhase = "ENTERED"
            _G.DragonPortalFireLock = tick() + DRAGON_PORTAL_FIRE_LOCK
            return true
        end
        if bf and bf:FindFirstChild("Dragon") then
            _G.DragonPortalPhase = "ENTERED"
            _G.DragonEnterTime = tick()
            _G.DragonPortalFireLock = tick() + DRAGON_PORTAL_FIRE_LOCK
            return true
        end
        if elapsed > DRAGON_PORTAL_TIMEOUT then
            print("[Dragon] ⚠️ Portal timeout → retry")
            _G.DragonPortalPhase = "IDLE"
            _G.DragonLastFireTime = 0
        end
        return true
    end

    return false
end

-- =====================================================
-- Listener respawn
-- =====================================================
LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(1)
    if not _G.AutoRaidDragon then return end
    _G.DragonBuffUsed = false
    _G.DragonBuffFinishTime = 0
    _G.DragonPortalPhase = "IDLE"
    _G.DragonPortalFireLock = 0
    _G.DragonEnterTime = 0
    _G.DragonBossDeadHandled = false
    _G.DragonAlertTriggered = false
    _G.DragonSafeZoneActive = false
    _G.DragonSafeZonePart = nil
    _G.DragonThanosFlyPos = nil
    _G.DragonThanosSpamStartTime = 0
    _G.DragonThanosFSuccessCount = 0
    print("[Dragon] 💀 Respawn → reset, buff lại + mở cổng")
end)

-- =====================================================
-- MAIN LOOP
-- =====================================================
task.spawn(function()
    while task.wait() do
        pcall(function()
            if not _G.AutoRaidDragon then
                _G.DragonPortalPhase = "IDLE"
                _G.DragonAlertTriggered = false
                _G.DragonSafeZoneActive = false
                _G.DragonSafeZonePart = nil
                _G.DragonBossDeadHandled = false
                _G.DragonThanosFSuccessCount = 0
                _G.DragonThanosSpamStartTime = 0
                _G.DragonThanosFlyPos = nil
                _G.DragonBuffUsed = false
                _G.DragonBuffFinishTime = 0
                _G.DragonHasThanosEquipped = false
                return
            end

            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp or hum.Health <= 0 then return end

            local bossModel, bossHrp, bossHum = GetDragonBoss()
            if not bossModel or not bossHrp or not bossHum then
                if _G.DragonPortalPhase ~= "ENTERED" then
                    DragonOpenPortal()
                end
                return
            end

            -- BOSS CHẾT
            if bossHum.Health <= 0 then
                if not _G.DragonBossDeadHandled then
                    _G.DragonBossDeadHandled = true
                    _G.DragonPortalPhase = "IDLE"
                    _G.DragonPortalFireLock = tick() + DRAGON_PORTAL_FIRE_LOCK
                    _G.DragonAlertTriggered = false
                    _G.DragonSafeZoneActive = false
                    _G.DragonSafeZonePart = nil
                    _G.DragonThanosFlyPos = nil
                    _G.DragonThanosSpamStartTime = 0
                    _G.DragonThanosFSuccessCount = 0
                    _G.DragonBuffUsed = false
                    _G.DragonBuffFinishTime = 0

                    task.spawn(function()
                        local startTime = tick()
                        local clicked = false

                        while tick() - startTime < 5 do
                            task.wait(0.3)
                            pcall(function()
                                local hud3 = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                                local main3 = hud3 and hud3:FindFirstChild("Main")
                                if not main3 then return end

                                local rewardFrame = main3:FindFirstChild("Frame_RaidbossItem")
                                if not rewardFrame then return end
                                if not rewardFrame.Visible then return end

                                local titleLabel = rewardFrame:FindFirstChild("TitleLabel")
                                local isVictory = titleLabel and titleLabel.Text == "Victory"

                                if isVictory and not clicked then
                                    clicked = true
                                    local closeBtn = rewardFrame:FindFirstChild("Close_")
                                    if closeBtn then
                                        for i = 1, 3 do
                                            pcall(function()
                                                if firesignal then
                                                    firesignal(closeBtn.MouseButton1Click)
                                                end
                                            end)
                                            task.wait(0.1)
                                        end
                                        pcall(function()
                                            local VIM = game:GetService("VirtualInputManager")
                                            local pos = closeBtn.AbsolutePosition + closeBtn.AbsoluteSize / 2
                                            VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                                            task.wait(0.05)
                                            VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                                        end)
                                        print("[Dragon] 🎁 Đã click Close_")
                                    else
                                        pcall(function() rewardFrame.Visible = false end)
                                    end
                                    task.wait(0.5)
                                    if rewardFrame.Visible then
                                        pcall(function() rewardFrame.Visible = false end)
                                        print("[Dragon] ⚠️ Vẫn visible → ẩn trực tiếp")
                                    end
                                end
                            end)
                        end
                    end)
                end
                return
            end

            _G.DragonBossDeadHandled = false

            if _G.DragonEnterTime == 0 then
                _G.DragonEnterTime = tick()
            end

            bossHum.WalkSpeed = 0
            bossHum.JumpPower = 0

            local now = tick()

            -- SAFE ZONE
            local safePart = FindDragonSafeZone()
            if safePart then
                if not _G.DragonSafeZoneActive then
                    _G.DragonSafeZoneActive = true
                    print("[Dragon] 🛡️ VÀO VÙNG AN TOÀN")
                end
                local safePos = safePart.Position + Vector3.new(0, DRAGON_SAFE_HEIGHT_FLY, 0)
                hrp.CFrame = CFrame.new(safePos, bossHrp.Position)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                if hrp.AssemblyLinearVelocity.Y < 0 then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
                return
            else
                if _G.DragonSafeZoneActive then
                    _G.DragonSafeZoneActive = false
                    _G.DragonSafeZonePart = nil
                end
            end

            -- HP < 50% → AUTO SPAM F THANOS
            local hpPercent = (bossHum.Health / bossHum.MaxHealth) * 100
            local isThanosPriority = hpPercent <= 50

            if isThanosPriority then
                local thanosEquipped = EnsureThanosEquipped()

                if not thanosEquipped then
                    local methodFarm = GetDragonMethodFarm(DRAGON_AIM_HEIGHT)
                    hrp.CFrame = bossHrp.CFrame * methodFarm
                    hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    if now - _G.DragonLastAttack >= 0.15 then
                        _G.DragonLastAttack = now
                        local hasSkill = _G.AutoSkillZ or _G.AutoSkillX
                                      or _G.AutoSkillC or _G.AutoSkillV or _G.AutoSkillF
                        if hasSkill then AutoSkill() else Attack() end
                    end
                    return
                end

                if _G.DragonThanosSpamStartTime == 0 then
                    _G.DragonThanosSpamStartTime = now
                    _G.DragonThanosFSuccessCount = 0
                    print("[Dragon] ⚡ Bắt đầu Auto spam F Thanos")
                end

                local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                local main = hud and hud:FindFirstChild("Main")
                local skillList = main and main:FindFirstChild("Frame_SkillList_Thanos")
                local fOnCooldown = false
                if skillList then
                    local border = skillList:FindFirstChild("Border")
                    local mainFrame = border and border:FindFirstChild("Main")
                    local fFrame = mainFrame and mainFrame:FindFirstChild("F")
                    if fFrame then
                        local readyLabel = fFrame:FindFirstChild("Ready")
                        local cooldownFrame = fFrame:FindFirstChild("CooldownFrame")
                        local isUnready = readyLabel and readyLabel.Text == "UnReady"
                        local isCooldownVisible = cooldownFrame and cooldownFrame.Visible
                        if isUnready or isCooldownVisible then
                            fOnCooldown = true
                        end
                    end
                end

                if fOnCooldown then
                    if not _G.DragonThanosFlyPos then
                        _G.DragonThanosFlyPos = Vector3.new(
                            hrp.Position.X,
                            hrp.Position.Y + DRAGON_SAFE_HEIGHT_FLY,
                            hrp.Position.Z
                        )
                    end
                    hrp.CFrame = CFrame.new(_G.DragonThanosFlyPos, bossHrp.Position)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    return
                end

                if now - _G.DragonLastThanosTime >= DRAGON_THANOS_COOLDOWN then
    _G.DragonLastThanosTime = now

    -- 🆕 Ở GẦN BOSS trước khi fire F (đảm bảo hitbox chạm)
    local closePos = bossHrp.Position + Vector3.new(0, DRAGON_AIM_HEIGHT, 0)
    hrp.CFrame = CFrame.new(closePos, bossHrp.Position)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    task.wait(0.05)  -- 🆕 Đợi 1 frame để CFrame register

    local result = TryUseThanosF(hrp)

    if result == "success" then
        _G.DragonThanosFSuccessCount = _G.DragonThanosFSuccessCount + 1
        _G.DragonThanosFlyPos = nil

        -- 🆕 KHÔNG bay lên sau khi fire — ở gần boss để F trúng
        -- Chỉ log tiến độ
        if _G.DragonThanosFSuccessCount <= 5 or _G.DragonThanosFSuccessCount % 5 == 0 then
            print(string.format("[Dragon] ⚡ F Thanos #%d (HP: %.1f%%)",
                _G.DragonThanosFSuccessCount, hpPercent))
        end
        return
    elseif result == "cooldown" then
        -- 🆕 CHỈ bay lên 500 khi F đang cooldown (chờ hồi)
        if not _G.DragonThanosFlyPos then
            _G.DragonThanosFlyPos = Vector3.new(
                hrp.Position.X,
                hrp.Position.Y + DRAGON_SAFE_HEIGHT_FLY,
                hrp.Position.Z
            )
        end
        hrp.CFrame = CFrame.new(_G.DragonThanosFlyPos, bossHrp.Position)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

                local methodFarm = GetDragonMethodFarm(DRAGON_AIM_HEIGHT)
                hrp.CFrame = bossHrp.CFrame * methodFarm
                hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
                hrp.AssemblyAngularVelocity = Vector3.zero

                if now - _G.DragonLastAttack >= 0.1 then
                    _G.DragonLastAttack = now
                    Attack()
                end
                return
            else
                if _G.DragonThanosFlyPos then _G.DragonThanosFlyPos = nil end
                _G.DragonThanosSpamStartTime = 0
                _G.DragonThanosFSuccessCount = 0
            end

            -- BÁM BOSS BÌNH THƯỜNG
            local methodFarm = GetDragonMethodFarm(DRAGON_AIM_HEIGHT)
            hrp.CFrame = bossHrp.CFrame * methodFarm
            hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
            hrp.AssemblyAngularVelocity = Vector3.zero

            if now - _G.DragonLastEquip >= 0.5 then
                _G.DragonLastEquip = now
                EquipWeapon()
            end

            if now - _G.DragonLastAttack >= 0.15 then
                _G.DragonLastAttack = now
                local hasSkill = _G.AutoSkillZ or _G.AutoSkillX
                              or _G.AutoSkillC or _G.AutoSkillV or _G.AutoSkillF
                if hasSkill then AutoSkill() else Attack() end
            end
        end)
    end
end) end

-- ============================================================
-- 🆕 AUTO RAID BOSS LAVA TITAN — v10 FINAL (integrated)
-- ============================================================
_G.AutoRaidLava           = false
_G.LavaLastFireTime       = 0
_G.LavaLastAttack         = 0
_G.LavaLastEquip          = 0
_G.LavaEnterTime          = 0
_G.LavaPortalPhase        = "IDLE"
_G.LavaPortalStartTime    = 0
_G.LavaBossOriginPos      = nil
_G.LavaLastThanosTime     = 0
_G.LavaLastDebug          = 0
_G.LavaWaitingSurface     = false
_G.LavaBossSurfacedTime   = 0
_G.LavaPortalFireLock     = 0
_G.LavaPhase2Active       = false
_G.LavaThanosUsed         = false
_G.LavaThanosUsedTime     = 0
_G.LavaThanosLockUntil    = 0
_G.LavaThanosFlyPos       = nil
_G.LavaSafePos            = nil
_G.LavaBossDeadHandled    = false
_G.LavaThanosFSuccessCount = 0
_G.LavaThanosLastSuccessTime = 0
_G.LavaThanosSpamStartTime = 0
_G.LavaBuffUsed             = false
_G.LavaBuffFinishTime       = 0
_G.LavaBuffSpamStartTime    = 0
_G.LavaThanosHPPercent      = 50

local LAVA_AIM_HEIGHT        = 25
local LAVA_UNDER_LAVA_Y      = -100
local LAVA_MIN_FIRE_GAP      = 3
local LAVA_PORTAL_TIMEOUT    = 15
local LAVA_THANOS_COOLDOWN   = 0.3
local LAVA_SURFACE_DELAY     = 1.5
local LAVA_PORTAL_FIRE_LOCK  = 5
local LAVA_SAFE_HEIGHT       = 500
local LAVA_THANOS_LOCK_TIME  = 1.5

local function GetLavaMethodFarm(height)
    height = height or LAVA_AIM_HEIGHT
    return CFrame.new(0, height, 0) * CFrame.Angles(math.rad(-90), 0, 0)
end

local function FindLavaThanosTool()
    local char = LocalPlayer.Character
    if not char then return nil, "character" end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            if name == "thanos" or name:find("thanos") then
                return tool, "character"
            end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name == "thanos" or name:find("thanos") then
                    return tool, "backpack"
                end
            end
        end
    end
    return nil, "none"
end

local function EnsureLavaThanosEquipped()
    local char = LocalPlayer.Character
    if not char then return false end
    local tool, location = FindLavaThanosTool()
    if not tool then return false end
    if location == "character" then return true end
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        pcall(function() hum:EquipTool(tool) end)
        task.wait(0.2)
        print("[LavaTitan] 🗡️ Đã trang bị Thanos")
        return true
    end
    return false
end

local LAVA_BUFF_LIST = {"Kaioken", "SSJ", "SSJ2", "SSJ3", "SSJG"}

local function FindLavaBuffTool()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    for _, buffName in ipairs(LAVA_BUFF_LIST) do
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower() == buffName:lower() then
                return tool, buffName
            end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, buffName in ipairs(LAVA_BUFF_LIST) do
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") and tool.Name:lower() == buffName:lower() then
                    return tool, buffName
                end
            end
        end
    end
    return nil, nil
end

local function LavaBuffSpamLoop()
    local tool, buffName = FindLavaBuffTool()
    if not tool then
        print("[LavaTitan] ⚠️ Không có buff tool, bỏ qua")
        return false
    end

    print("[LavaTitan] ⚡ Bắt đầu spam F buff: " .. buffName)
    local startTime = tick()
    local lastFTime = 0

    while tick() - startTime < 15 do
        local now = tick()
        if now - lastFTime >= 0.3 then
            lastFTime = now

            local char = LocalPlayer.Character
            if not char then break end

            local currentTool = nil
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") and t.Name:lower() == buffName:lower() then
                    currentTool = t
                    break
                end
            end
            if not currentTool then
                local bp = LocalPlayer:FindFirstChild("Backpack")
                if bp then
                    for _, t in ipairs(bp:GetChildren()) do
                        if t:IsA("Tool") and t.Name:lower() == buffName:lower() then
                            char.Humanoid:EquipTool(t)
                            task.wait(0.3)
                            currentTool = t
                            break
                        end
                    end
                end
            end
            if not currentTool then break end

            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            local main = hud and hud:FindFirstChild("Main")
            local skillList = main and main:FindFirstChild("Frame_SkillList_" .. buffName)
            local fOnCooldown = false
            if skillList then
                local border = skillList:FindFirstChild("Border")
                local mainFrame = border and border:FindFirstChild("Main")
                local fFrame = mainFrame and mainFrame:FindFirstChild("F")
                if fFrame then
                    local readyLabel = fFrame:FindFirstChild("Ready")
                    local cooldownFrame = fFrame:FindFirstChild("CooldownFrame")
                    local isUnready = readyLabel and readyLabel.Text == "UnReady"
                    local isCooldownVisible = cooldownFrame and cooldownFrame.Visible
                    if isUnready or isCooldownVisible then
                        fOnCooldown = true
                    end
                end
            end

            if fOnCooldown then
                print("[LavaTitan] ⏹️ Buff F cooldown → dừng spam")
                break
            end

            if Action then
                pcall(function()
                    Action:FireServer(currentTool.Name, "f")
                end)
                print("[LavaTitan] ⚡ Buff F: " .. buffName)
            end
        end
        task.wait(0.1)
    end

    print("[LavaTitan] ✅ Buff spam xong, đợi 2s rồi mở cổng")
    return true
end

local function TryUseLavaThanosF(hrp)
    if not hrp then return "no_tool" end
    local char = LocalPlayer.Character
    if not char then return "no_tool" end

    if not EnsureLavaThanosEquipped() then
        return "no_tool"
    end

    local thanosTool = nil
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            if name == "thanos" or name:find("thanos") then
                thanosTool = tool
                break
            end
        end
    end

    if not thanosTool then return "no_tool" end

    local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
    local main = hud and hud:FindFirstChild("Main")
    local skillList = main and main:FindFirstChild("Frame_SkillList_Thanos")

    if skillList then
        local border = skillList:FindFirstChild("Border")
        local mainFrame = border and border:FindFirstChild("Main")
        local fFrame = mainFrame and mainFrame:FindFirstChild("F")

        if fFrame then
            local readyLabel = fFrame:FindFirstChild("Ready")
            local cooldownFrame = fFrame:FindFirstChild("CooldownFrame")
            local isUnready = readyLabel and readyLabel.Text == "UnReady"
            local isCooldownVisible = cooldownFrame and cooldownFrame.Visible
            if isUnready or isCooldownVisible then
                return "cooldown"
            end
        end
    end

    task.wait(0.3)

    if Action then
        pcall(function()
            Action:FireServer(thanosTool.Name, "f")
        end)
        task.wait(0.3)
        return "success"
    end
    return "no_tool"
end

local function OnLavaAlert(text)
    if not text then return end
    local lower = text:lower()
    if lower:find("lava is rising", 1, true)
       or lower:find("get on the center platform", 1, true) then
        if not _G.LavaPhase2Active then
            _G.LavaPhase2Active = true
            print("[LavaTitan] 🚨 PHASE 2: LAVA IS RISING!")
        end
    end
end

local function HookLavaText(container)
    for _, obj in ipairs(container:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            OnLavaAlert(obj.Text)
            obj:GetPropertyChangedSignal("Text"):Connect(function()
                OnLavaAlert(obj.Text)
            end)
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(1)
    if not _G.AutoRaidLava then return end
    _G.LavaBuffUsed = false
    _G.LavaBuffFinishTime = 0
    _G.LavaPortalPhase = "IDLE"
    _G.LavaPortalFireLock = 0
    _G.LavaEnterTime = 0
    _G.LavaBossDeadHandled = false
    _G.LavaPhase2Active = false
    _G.LavaThanosFlyPos = nil
    _G.LavaThanosSpamStartTime = 0
    _G.LavaThanosFSuccessCount = 0
    print("[LavaTitan] 💀 Respawn → reset, buff lại + mở cổng")
end)

HookLavaText(LocalPlayer.PlayerGui)
LocalPlayer.PlayerGui.DescendantAdded:Connect(function(obj)
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        task.wait(0.1)
        OnLavaAlert(obj.Text)
        obj:GetPropertyChangedSignal("Text"):Connect(function()
            OnLavaAlert(obj.Text)
        end)
    end
end)

local function IsBossUnderLava(bossHrp)
    if not bossHrp then return false end
    return bossHrp.Position.Y < LAVA_UNDER_LAVA_Y
end

local function GetLavaBoss()
    local bf = workspace:FindFirstChild("Boss Fight")
    if not bf then return nil, nil, nil end
    local lavaFolder = bf:FindFirstChild("LavaTitan")
    if not lavaFolder then return nil, nil, nil end
    for _, obj in ipairs(lavaFolder:GetChildren()) do
        if obj:IsA("Model") then
            local hum = obj:FindFirstChild("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hum and hrp then
                return obj, hrp, hum
            end
        end
    end
    return nil, nil, nil
end

local function CloseLavaFrame(frame)
    if not frame then return false end
    local closeBtn = frame:FindFirstChild("Close_")
        or frame:FindFirstChild("Close")
        or frame:FindFirstChild("CloseButton")
        or frame:FindFirstChild("Exit")
        or frame:FindFirstChildWhichIsA("ImageButton", true)
        or frame:FindFirstChildWhichIsA("TextButton", true)
    if closeBtn then
        pcall(function()
            if firesignal then
                firesignal(closeBtn.MouseButton1Click)
            elseif fireclickdetector then
                fireclickdetector(closeBtn)
            else
                closeBtn:Activate()
            end
        end)
        return true
    end
    pcall(function() frame.Visible = false end)
    return true
end

local function LavaOpenPortal()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    if tick() < _G.LavaPortalFireLock then return false end

    local bf = workspace:FindFirstChild("Boss Fight")
    if bf and bf:FindFirstChild("LavaTitan") then
        _G.LavaPortalPhase = "IDLE"
        return true
    end

    if not _G.LavaBuffUsed then
        _G.LavaBuffUsed = true

        local tool, buffName = FindLavaBuffTool()
        if tool then
            print("[LavaTitan] ⚡ Có buff " .. buffName .. ", bắt đầu spam F trước cổng")
            _G.LavaBuffSpamStartTime = tick()
            _G.LavaBuffFinishTime = 0

            task.spawn(function()
                LavaBuffSpamLoop()
                print("[LavaTitan] ✅ Buff spam xong, đợi 2s...")
                task.wait(2)
                _G.LavaBuffFinishTime = tick()
                print("[LavaTitan] ✅ Buff xong, bắt đầu mở cổng")
                _G.LavaPortalPhase = "IDLE"
                _G.LavaLastFireTime = 0
            end)
            return false
        else
            print("[LavaTitan] ⚠️ Không có buff tool, bỏ qua")
            _G.LavaBuffFinishTime = tick()
        end
    end

    if _G.LavaBuffFinishTime == 0 then
        return false
    end
    if tick() - _G.LavaBuffFinishTime < 2 then
        return false
    end

    local tz = workspace:FindFirstChild("TeleportBossFightZone")
    if tz and tz:FindFirstChild("Hitbox") then
        if _G.LavaPortalPhase ~= "ENTERED" then
            hrp.CFrame = tz.Hitbox.CFrame
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            print("[LavaTitan] 🌀 TP vào portal")
            _G.LavaEnterTime = tick()
            _G.LavaPortalPhase = "ENTERED"
            _G.LavaPortalFireLock = tick() + LAVA_PORTAL_FIRE_LOCK
        end
        return true
    end

    local npcPrompt = workspace:FindFirstChild("NpcPrompt")
    local openRaidNPC = npcPrompt and npcPrompt:FindFirstChild("Open Raid")

    if openRaidNPC and _G.LavaPortalPhase == "IDLE" then
        local npcHrp = openRaidNPC:FindFirstChild("HumanoidRootPart")
            or openRaidNPC:FindFirstChildWhichIsA("BasePart")
        if npcHrp then
            local dist = (hrp.Position - npcHrp.Position).Magnitude
            if dist > 10 then
                hrp.CFrame = CFrame.new(npcHrp.Position + Vector3.new(0, 3, 0))
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                task.wait(0.3)
            end

            if tick() - _G.LavaLastFireTime >= LAVA_MIN_FIRE_GAP then
                local prompt = openRaidNPC:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    _G.LavaLastFireTime = tick()
                    _G.LavaPortalPhase = "GUI_OPENING"
                    _G.LavaPortalStartTime = tick()
                    pcall(function() fireproximityprompt(prompt) end)
                    print("[LavaTitan] 👆 Fire NPC Open Raid")
                    return true
                end
            end
        end
    end

    if _G.LavaPortalPhase == "GUI_OPENING" then
        local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        local main = hud and hud:FindFirstChild("Main")
        local raidBossFrame = main and main:FindFirstChild("Frame_RaidBoss")

        if raidBossFrame then
            local lavaTemplate = raidBossFrame:FindFirstChild("Template_LavaTitan")
            if not lavaTemplate then
                local sf = raidBossFrame:FindFirstChild("ScrollingFrame")
                if sf then
                    for _, child in ipairs(sf:GetChildren()) do
                        if child.Name:lower():find("lavatitan") then
                            lavaTemplate = child
                            break
                        end
                    end
                end
            end

            if lavaTemplate then
                local openButton = nil
                for _, obj in ipairs(lavaTemplate:GetDescendants()) do
                    if obj:IsA("TextLabel") and obj.Text == "Open" then
                        local parent = obj.Parent
                        while parent and parent ~= lavaTemplate do
                            if parent:IsA("TextButton") or parent:IsA("ImageButton") then
                                openButton = parent
                                break
                            end
                            parent = parent.Parent
                        end
                        if openButton then break end
                    end
                end
                if not openButton then
                    local mainBtn = lavaTemplate:FindFirstChild("Main")
                    if mainBtn and (mainBtn:IsA("TextButton") or mainBtn:IsA("ImageButton")) then
                        openButton = mainBtn
                    end
                end

                if openButton then
                    print("[LavaTitan] 🖱️ Click button Open")
                    pcall(function()
                        if firesignal then
                            firesignal(openButton.MouseButton1Click)
                        else
                            openButton:Activate()
                        end
                    end)
                    _G.LavaPortalPhase = "WAITING"
                    _G.LavaPortalStartTime = tick()

                    task.spawn(function()
                        task.wait(0.3)
                        pcall(function()
                            local hud2 = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                            local main2 = hud2 and hud2:FindFirstChild("Main")
                            local raidBossFrame2 = main2 and main2:FindFirstChild("Frame_RaidBoss")
                            if raidBossFrame2 then
                                CloseLavaFrame(raidBossFrame2)
                                print("[LavaTitan] 🚪 Đóng GUI mở cổng")
                            end
                        end)
                    end)
                    return true
                end
            end
        end

        if tick() - _G.LavaPortalStartTime > 5 then
            print("[LavaTitan] ⚠️ Timeout GUI → reset")
            _G.LavaPortalPhase = "IDLE"
        end
        return true
    end

    if _G.LavaPortalPhase == "WAITING" then
        local elapsed = tick() - _G.LavaPortalStartTime
        local tz2 = workspace:FindFirstChild("TeleportBossFightZone")
        if tz2 and tz2:FindFirstChild("Hitbox") then
            hrp.CFrame = tz2.Hitbox.CFrame
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            print("[LavaTitan] 🌀 TP vào portal (sau click)")
            _G.LavaEnterTime = tick()
            _G.LavaPortalPhase = "ENTERED"
            _G.LavaPortalFireLock = tick() + LAVA_PORTAL_FIRE_LOCK
            return true
        end
        if bf and bf:FindFirstChild("LavaTitan") then
            _G.LavaPortalPhase = "ENTERED"
            _G.LavaEnterTime = tick()
            _G.LavaPortalFireLock = tick() + LAVA_PORTAL_FIRE_LOCK
            return true
        end
        if elapsed > LAVA_PORTAL_TIMEOUT then
            print("[LavaTitan] ⚠️ Portal timeout → retry")
            _G.LavaPortalPhase = "IDLE"
            _G.LavaLastFireTime = 0
        end
        return true
    end

    return false
end

task.spawn(function()
    while task.wait() do
        pcall(function()
            if not _G.AutoRaidLava then
                _G.LavaPhase2Active = false
                _G.LavaPortalPhase = "IDLE"
                _G.LavaBossOriginPos = nil
                _G.LavaWaitingSurface = false
                _G.LavaBossSurfacedTime = 0
                _G.LavaThanosUsed = false
                _G.LavaThanosLockUntil = 0
                _G.LavaThanosFlyPos = nil
                _G.LavaSafePos = nil
                _G.LavaBossDeadHandled = false
                _G.LavaThanosSpamStartTime = 0
                _G.LavaThanosFSuccessCount = 0
                _G.LavaBuffUsed = false
                _G.LavaBuffFinishTime = 0
                return
            end

            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp or hum.Health <= 0 then return end

            local bossModel, bossHrp, bossHum = GetLavaBoss()
            if not bossModel or not bossHrp or not bossHum then
                if _G.LavaPortalPhase ~= "ENTERED" then
                    LavaOpenPortal()
                end
                return
            end

            if bossHum.Health <= 0 then
                if not _G.LavaBossDeadHandled then
                    _G.LavaBossDeadHandled = true
                    _G.LavaPortalPhase = "IDLE"
                    _G.LavaPortalFireLock = tick() + LAVA_PORTAL_FIRE_LOCK
                    _G.LavaThanosUsed = false
                    _G.LavaThanosLockUntil = 0
                    _G.LavaThanosFlyPos = nil
                    _G.LavaSafePos = nil
                    _G.LavaPhase2Active = false
                    _G.LavaThanosSpamStartTime = 0
                    _G.LavaThanosFSuccessCount = 0
                    _G.LavaThanosLastSuccessTime = 0
                    _G.LavaBuffUsed = false
                    _G.LavaBuffFinishTime = 0

                    task.spawn(function()
                        local startTime = tick()
                        while tick() - startTime < 5 do
                            task.wait(0.2)
                            pcall(function()
                                local hud3 = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                                local main3 = hud3 and hud3:FindFirstChild("Main")
                                if not main3 then return end
                                local rewardFrame = main3:FindFirstChild("Frame_RaidbossItem")
                                    or main3:FindFirstChild("Frame_RaidBossItem")
                                    or main3:FindFirstChild("Frame_RaidBoss")
                                    or main3:FindFirstChild("Frame_Raidboss")
                                if rewardFrame then
                                    local titleLabel = rewardFrame:FindFirstChild("TitleLabel")
                                    local isVictory = titleLabel and titleLabel.Text == "Victory"
                                    local closeBtn = rewardFrame:FindFirstChild("Close_")
                                    local closeVisible = closeBtn and closeBtn.Visible
                                    if isVictory or closeVisible then
                                        CloseLavaFrame(rewardFrame)
                                        print("[LavaTitan] 🎁 Đóng GUI nhận thưởng (Victory="
                                            .. tostring(isVictory) .. ")")
                                        task.wait(1)
                                    end
                                end
                            end)
                        end
                    end)
                end
                return
            end

            _G.LavaBossDeadHandled = false

            if _G.LavaEnterTime == 0 then
                _G.LavaEnterTime = tick()
            end

            bossHum.WalkSpeed = 0
            bossHum.JumpPower = 0

            local now = tick()

            if not _G.LavaBossOriginPos then
                _G.LavaBossOriginPos = bossHrp.Position
            end

            local hpPercent = (bossHum.Health / bossHum.MaxHealth) * 100
            local threshold = _G.LavaThanosHPPercent or 50
            local isThanosPriority = hpPercent <= threshold

            if isThanosPriority then
                local thanosEquipped = EnsureLavaThanosEquipped()

                if not thanosEquipped then
                    local methodFarm = GetLavaMethodFarm(LAVA_AIM_HEIGHT)
                    hrp.CFrame = bossHrp.CFrame * methodFarm
                    hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    if now - _G.LavaLastAttack >= 0.15 then
                        _G.LavaLastAttack = now
                        Attack()
                    end
                    return
                end

                if _G.LavaThanosSpamStartTime == 0 then
                    _G.LavaThanosSpamStartTime = now
                    _G.LavaThanosFSuccessCount = 0
                    print("[LavaTitan] ⚡ Bắt đầu Auto spam F Thanos")
                end

                local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                local main = hud and hud:FindFirstChild("Main")
                local skillList = main and main:FindFirstChild("Frame_SkillList_Thanos")
                local fOnCooldown = false
                if skillList then
                    local border = skillList:FindFirstChild("Border")
                    local mainFrame = border and border:FindFirstChild("Main")
                    local fFrame = mainFrame and mainFrame:FindFirstChild("F")
                    if fFrame then
                        local readyLabel = fFrame:FindFirstChild("Ready")
                        local cooldownFrame = fFrame:FindFirstChild("CooldownFrame")
                        local isUnready = readyLabel and readyLabel.Text == "UnReady"
                        local isCooldownVisible = cooldownFrame and cooldownFrame.Visible
                        if isUnready or isCooldownVisible then
                            fOnCooldown = true
                        end
                    end
                end

                if fOnCooldown then
                    if not _G.LavaThanosFlyPos then
                        _G.LavaThanosFlyPos = Vector3.new(
                            hrp.Position.X,
                            hrp.Position.Y + LAVA_SAFE_HEIGHT,
                            hrp.Position.Z
                        )
                    end
                    hrp.CFrame = CFrame.new(_G.LavaThanosFlyPos, bossHrp.Position)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    return
                end

                if now - _G.LavaLastThanosTime >= LAVA_THANOS_COOLDOWN then
                    local bossPos = bossHrp.Position
                    local targetPos = bossPos + Vector3.new(0, LAVA_AIM_HEIGHT, 0)
                    hrp.CFrame = CFrame.new(targetPos, bossPos)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero

                    _G.LavaLastThanosTime = now
                    local result = TryUseLavaThanosF(hrp)
                    if result == "success" then
                        _G.LavaThanosFSuccessCount = _G.LavaThanosFSuccessCount + 1
                        _G.LavaThanosLastSuccessTime = now
                        _G.LavaThanosUsed = true
                        _G.LavaThanosFlyPos = Vector3.new(
                            hrp.Position.X,
                            hrp.Position.Y + LAVA_SAFE_HEIGHT,
                            hrp.Position.Z
                        )
                        hrp.CFrame = CFrame.new(_G.LavaThanosFlyPos, bossHrp.Position)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        if _G.LavaThanosFSuccessCount <= 5 or _G.LavaThanosFSuccessCount % 5 == 0 then
                            print(string.format("[LavaTitan] ⚡ F Thanos #%d (HP: %.1f%%) — bay lên 500",
                                _G.LavaThanosFSuccessCount, hpPercent))
                        end
                    end
                end
                return
            else
                if _G.LavaThanosUsed then _G.LavaThanosUsed = false end
                if _G.LavaThanosLockUntil > 0 then _G.LavaThanosLockUntil = 0 end
                _G.LavaThanosFlyPos = nil
                _G.LavaSafePos = nil
                _G.LavaThanosSpamStartTime = 0
                _G.LavaThanosFSuccessCount = 0
            end

            local bossUnderLava = IsBossUnderLava(bossHrp)

            if bossUnderLava then
                if not _G.LavaWaitingSurface then
                    _G.LavaWaitingSurface = true
                    _G.LavaBossSurfacedTime = 0
                    print("[LavaTitan] 🌊 Boss lặn → bay lên không chờ")
                end
                local originPos = _G.LavaBossOriginPos or bossHrp.Position
                local safePos = originPos + Vector3.new(0, LAVA_AIM_HEIGHT, 0)
                hrp.CFrame = CFrame.new(safePos, originPos)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                return
            else
                if _G.LavaWaitingSurface then
                    if _G.LavaBossSurfacedTime == 0 then
                        _G.LavaBossSurfacedTime = now
                        print("[LavaTitan] ⬆️ Boss trồi → đợi " .. LAVA_SURFACE_DELAY .. "s")
                    end
                    if now - _G.LavaBossSurfacedTime < LAVA_SURFACE_DELAY then
                        local originPos = _G.LavaBossOriginPos or bossHrp.Position
                        local safePos = originPos + Vector3.new(0, LAVA_AIM_HEIGHT, 0)
                        hrp.CFrame = CFrame.new(safePos, originPos)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        return
                    end
                    _G.LavaWaitingSurface = false
                    _G.LavaBossSurfacedTime = 0
                    print("[LavaTitan] ⚡ Boss đã trồi hẳn → bám đánh")
                end
            end

            local methodFarm = GetLavaMethodFarm(LAVA_AIM_HEIGHT)
            hrp.CFrame = bossHrp.CFrame * methodFarm
            hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
            hrp.AssemblyAngularVelocity = Vector3.zero

            if now - _G.LavaLastEquip >= 0.5 then
                _G.LavaLastEquip = now
                EquipWeapon()
            end

            if now - _G.LavaLastAttack >= 0.15 then
                _G.LavaLastAttack = now
                local hasSkill = _G.AutoSkillZ or _G.AutoSkillX
                              or _G.AutoSkillC or _G.AutoSkillV or _G.AutoSkillF
                if hasSkill then
                    AutoSkill()
                else
                    Attack()
                end
            end
        end)
    end
end)
-- ============================================================
-- 🆕 ANTI-DASH GLOBAL — Ngắt lướt mọi chiêu khi bật hack
-- Copy cơ chế từ v72: set CFrame + zero velocity mỗi frame
-- ============================================================
task.spawn(function()
    while task.wait() do
        pcall(function()
            -- Check hack nào đang bật
            local anyActive = _G.AutoFarm or _G.AutoFarmLevel
                or _G.AutoFarmMaterial or _G.AutoBossFull
                or _G.AutoPiccolo or _G.AutoDevilBoat
                or _G.AutoKraken or _G.AutoDuckFull or _G.AutoThiefChest
                or _G.AutoRaidMoon or _G.AutoDungeon
                or _G.AutoRaidRunning or _G.AutoRaidDragon or _G.AutoRaidLava
                or _G.CraftAutoRunning or _G.AutoCraftWeaponRunning
                or _G.AutoFarmCraftItems or _G.PortalAutoRunning
                or _G.AutoFarm_Set  -- v47 có biến này
                or _G.Auto_CraftWeapon or _G.Auto_Farm_Level
                or _G.Auto_Farm_Material or _G.Auto_FarmBoss
                or _G.Auto_Piccolo or _G.Auto_DevilBoat
                or _G.Auto_Kraken or _G.Auto_DuckAutomatically
                or _G.Auto_BaconThief or _G.Auto_Dungeon
                or _G.Auto_Raid

            if not anyActive then return end

            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            -- 🆕 ZERO VELOCITY — cơ chế chính ngắt lướt
            hrp.AssemblyLinearVelocity  = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero

            -- 🆕 XÓA mọi constraint dash
            for _, child in ipairs(hrp:GetChildren()) do
                if child:IsA("BodyVelocity")
                   or child:IsA("BodyGyro")
                   or child:IsA("AlignPosition")
                   or child:IsA("AlignOrientation")
                   or child:IsA("BodyThrust")
                   or child:IsA("BodyForce") then
                    pcall(function() child:Destroy() end)
                end
            end
        end)
    end
end)

task.spawn(function()
    pcall(function()
        RunService.Stepped:Connect(function()
            local anyActive = _G.AutoFarm or _G.AutoFarmLevel
                or _G.AutoFarmMaterial or _G.AutoBossFull
                or _G.AutoPiccolo or _G.AutoDevilBoat
                or _G.AutoKraken or _G.AutoDuckFull or _G.AutoThiefChest
                or _G.AutoRaidMoon or _G.AutoDungeon
                or _G.AutoRaidRunning or _G.AutoRaidDragon or _G.AutoRaidLava
                or _G.CraftAutoRunning or _G.AutoCraftWeaponRunning
                or _G.AutoFarmCraftItems or _G.PortalAutoRunning
                or _G.AutoFarm_Set or _G.Auto_CraftWeapon
                or _G.Auto_Farm_Level or _G.Auto_Farm_Material
                or _G.Auto_FarmBoss or _G.Auto_Piccolo
                or _G.Auto_DevilBoat or _G.Auto_Kraken
                or _G.Auto_DuckAutomatically or _G.Auto_BaconThief
                or _G.Auto_Dungeon or _G.Auto_Raid

            if not anyActive then return end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            -- 🆕 ZERO VELOCITY ngay khi physics step
            hrp.AssemblyLinearVelocity  = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end)
end)

end   -- End if not IS_MOON_MAP

print("[Sea 1] ✅ Load successful!")
