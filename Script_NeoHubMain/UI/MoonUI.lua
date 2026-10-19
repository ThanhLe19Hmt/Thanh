-- UI/MoonUI.lua
-- UI Moon map — viết lại gọn + dùng Moon modules

local Services = require(script.Parent.Parent.Core.Services)
local Helpers  = require(script.Parent.Parent.Core.Helpers)
local Config   = require(script.Parent.Parent.Core.Config)

local LocalPlayer = Services.LocalPlayer
local HttpService = Services.HttpService

local Window = _G.Window
local MoonCFG = Config.Moon

local AsString = Helpers.AsString
local AsStringList = Helpers.AsStringList

-- ============================================================
-- UI
-- ============================================================
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

_G.MoonHitPosition = "Upper"
_G.MoonHitDistance = 12

-- ============================================================
-- SAVE MANAGER
-- ============================================================
local function EnsureFolder()
    if not isfolder(MoonCFG.SAVE_FOLDER) then
        pcall(function() makefolder(MoonCFG.SAVE_FOLDER) end)
    end
end

local function GetSavePath(name)
    return MoonCFG.SAVE_FOLDER .. "/" .. name .. ".json"
end

local function GetSaveList()
    local list = {}
    if not isfolder(MoonCFG.SAVE_FOLDER) then return list end
    local ok, files = pcall(function() return listfiles(MoonCFG.SAVE_FOLDER) end)
    if not ok or type(files) ~= "table" then return list end
    for _, file in ipairs(files) do
        local name = tostring(file):match("([^/\\]+)%.json$")
        if name and not name:find("^_") then table.insert(list, name) end
    end
    table.sort(list)
    return list
end

local function SaveMoonSetting(name)
    if not name or name == "" then _G.SeaNotify("❌ Empty", "Enter name", 3); return end
    EnsureFolder()
    local main = AsString(_G.MainWeapon) or "Melee"
    local support = AsStringList(_G.Select_EquipWeapon)
    local clean, seen = {}, {}
    for _, v in ipairs(support) do
        if v ~= main and not seen[v] then seen[v] = true; table.insert(clean, v) end
    end
    local data = {
        HitPosition = AsString(_G.MoonHitPosition) or "Upper",
        HitDistance = tonumber(_G.MoonHitDistance) or 12,
        MainWeapon = main, SupportWeapons = clean,
        RaidAutoAttack = _G.RaidAutoAttack and true or false,
        RaidAutoSkill = _G.RaidAutoSkill and true or false,
        AutoSkillZ = _G.AutoSkillZ and true or false,
        AutoSkillX = _G.AutoSkillX and true or false,
        AutoSkillC = _G.AutoSkillC and true or false,
        AutoSkillV = _G.AutoSkillV and true or false,
        AutoSkillF = _G.AutoSkillF and true or false,
    }
    local ok = pcall(function()
        writefile(GetSavePath(name), HttpService:JSONEncode(data))
    end)
    _G.SeaNotify(ok and "✅ Saved" or "❌ Error", name, 3)
end

local function LoadMoonSetting(name)
    if not name or name == "" then _G.SeaNotify("❌ Empty", "", 3); return false end
    if not isfile(GetSavePath(name)) then _G.SeaNotify("❌ Not found", name, 3); return false end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(GetSavePath(name)))
    end)
    if not ok or type(data) ~= "table" then return false end
    _G.MoonHitPosition    = AsString(data.HitPosition) or "Upper"
    _G.MoonHitDistance    = tonumber(data.HitDistance) or 12
    _G.MainWeapon         = AsString(data.MainWeapon) or "Melee"
    _G.Select_EquipWeapon = AsStringList(data.SupportWeapons)
    _G.RaidAutoAttack     = data.RaidAutoAttack and true or false
    _G.RaidAutoSkill      = data.RaidAutoSkill and true or false
    _G.AutoSkillZ = data.AutoSkillZ and true or false
    _G.AutoSkillX = data.AutoSkillX and true or false
    _G.AutoSkillC = data.AutoSkillC and true or false
    _G.AutoSkillV = data.AutoSkillV and true or false
    _G.AutoSkillF = data.AutoSkillF and true or false
    _G.SeaNotify("✅ Loaded", name, 3)
    return true
end

-- ============================================================
-- Toggle / Dropdown / Slider
-- ============================================================
MoonFarm:Toggle({
    Title = "🌙 Auto Farm Moon Mob", Value = false,
    Callback = function(v)
        _G.MoonRunning = v
        MoonStatusPara:SetTitle(v and "Status: FARMING" or "Status: Disabled")
        MoonStatusPara:SetContent(v and "Searching mob..." or "Re-enable to continue")
    end
})
MoonFarm:Dropdown({
    Title = "🎯 Hit Position",
    Options = {"Upper", "Below", "Behind", "Front"},
    Multi = false, Value = "Upper",
    Callback = function(v)
        local val = AsString(v)
        if val then _G.MoonHitPosition = val end
    end
})
MoonFarm:Slider({
    Title = "📏 Hit Distance", Min = 5, Max = 40, Value = 12,
    Callback = function(v) _G.MoonHitDistance = v end
})

MoonWeapon:Dropdown({
    Title = "🗡️ Main Weapon", Options = Config.TypeTool,
    Id = "MAINWEAPON", Multi = false, Value = "Melee",
    Callback = function(v) local val = AsString(v); if val then _G.MainWeapon = val end end
})
MoonWeapon:Dropdown({
    Title = "🗡️ Support Weapons", Options = Config.TypeTool,
    Id = "SUPWEAPON", Multi = true,
    Callback = function(v) _G.Select_EquipWeapon = AsStringList(v) end
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
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local npcPrompt = workspace:FindFirstChild("NpcPrompt")
        local backEarth = npcPrompt and npcPrompt:FindFirstChild("BackEarth")
        if not backEarth then _G.SeaNotify("❌ NPC not found", "", 3); return end
        local npcHrp = backEarth:FindFirstChild("HumanoidRootPart")
        if not npcHrp then return end
        hrp.CFrame = CFrame.new(npcHrp.Position + Vector3.new(0, 2, 0))
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        task.wait(0.4)
        local prompt = npcHrp:FindFirstChildWhichIsA("ProximityPrompt", true)
            or backEarth:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            pcall(function() fireproximityprompt(prompt, prompt.HoldDuration + 0.1) end)
            task.wait(0.3)
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration + 0.15)
                prompt:InputHoldEnd()
            end)
        end
        _G.SeaNotify("✅ Activated", "Waiting for map change...", 5)
    end
})

-- ============================================================
-- SETTING TAB (save manager)
-- ============================================================
local MoonSettingTab  = Window:CreateTab("⚙️ Setting", false, false)
local MoonSettingPage = MoonSettingTab:CreatePage("Save / Load")
local SaveLoadCard    = MoonSettingPage:CreateSection("💾 Save Manager", "Left")
local InfoCard        = MoonSettingPage:CreateSection("📋 Information", "Right")

InfoCard:Paragraph({
    Title = "📖 Guide",
    Content = "1. Enter Save name → SAVE\n2. Pick from dropdown → LOAD\n3. Delete with 🗑️"
})
local SaveListPara = InfoCard:Paragraph({Title = "📁 Existing saves:", Content = "(no save yet)"})
local SelectedSave = ""
local NewSaveName = ""

local SaveDropdown
local function Refresh()
    local list = GetSaveList()
    SaveListPara:SetContent(#list == 0 and "(no save yet)" or table.concat(list, "\n"))
    if SaveDropdown and SaveDropdown.Set then
        pcall(function() SaveDropdown:Set(#list > 0 and list or {}) end)
    end
end

SaveLoadCard:Textbox({
    Title = "✏️ New Save Name", Placeholder = "e.g. Save1", Value = "",
    Callback = function(v) if type(v) == "string" then NewSaveName = v end end
})
SaveDropdown = SaveLoadCard:Dropdown({
    Title = "📁 Choose Save", Options = GetSaveList(),
    Multi = false, Value = "",
    Callback = function(v)
        local val = AsString(v)
        if val and val ~= "" and val ~= "(no save yet)" then SelectedSave = val end
    end
})
Refresh()

SaveLoadCard:Button({
    Title = "💾 SAVE",
    Callback = function()
        if NewSaveName == "" then _G.SeaNotify("❌ Name empty", "", 3); return end
        SaveMoonSetting(NewSaveName)
        SelectedSave = NewSaveName
        Refresh()
    end
})
SaveLoadCard:Button({
    Title = "📂 LOAD",
    Callback = function()
        local s = SelectedSave
        if s == "" then
            local list = GetSaveList()
            if #list > 0 then s = list[1] end
        end
        if s == "" then _G.SeaNotify("❌ No save", "", 3); return end
        LoadMoonSetting(s)
    end
})
SaveLoadCard:Button({
    Title = "🗑️ Delete Save",
    Callback = function()
        local s = SelectedSave
        if s == "" then
            local list = GetSaveList()
            if #list > 0 then s = list[1] end
        end
        if s == "" then return end
        local path = GetSavePath(s)
        if isfile(path) then
            delfile(path)
            _G.SeaNotify("✅ Deleted", s, 3)
            SelectedSave = ""
            Refresh()
        end
    end
})
SaveLoadCard:Button({
    Title = "🔄 Refresh List",
    Callback = function() Refresh(); _G.SeaNotify("✅ Refreshed", "", 2) end
})

print("[MoonUI] ✅ Loaded")
