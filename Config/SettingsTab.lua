--[[
    UI/SettingsTab.lua
    Tab "Settings" - Weapon, Skills, Method, Haki, VFX, Accessory, Potion
]]

local SettingsTab = {}
local Globals = _G.__Globals or Globals
local Utils   = Globals.Utils
local NoVFX   = Globals.NoVFX

local X2List = {}
for name in pairs(Globals.Blacklist) do
    if name:find("X2") then
        table.insert(X2List, name)
    end
end

function SettingsTab:Init(Window)
    local Library = Globals.Library
    local Tab1 = Window:CreateTab("Settings", true, false)
    local Page1 = Tab1:CreatePage("Main Settings")
    local Page2 = Tab1:CreatePage("Other Settings")

    -- ===== Page 1 =====
    local Weapon     = Page1:CreateSection("🗡️ Select Weapon", "Left")
    local AutoSkills = Page1:CreateSection("⚔️ Auto Skills", "Left")
    local Method     = Page1:CreateSection("🎯 Select Method Farm", "Right")
    local Haki       = Page1:CreateSection("👁️ Haki", "Right")
    local VFX        = Page1:CreateSection("✨ VFX", "Right")

    Weapon:Dropdown({
        Title = "Main Weapon (Attack)",
        Options = Globals.TypeTool,
        Multi = false,
        Value = "Melee",
        Callback = function(v) _G.MainWeapon = v end
    })
    Weapon:Dropdown({
        Title = "Select Support Weapon",
        Options = Globals.TypeTool,
        Multi = true,
        Callback = function(v) _G.Select_EquipWeapon = v end
    })

    local skills = {"Z","X","C","V","F"}
    for _, k in ipairs(skills) do
        AutoSkills:Toggle({
            Title = "Auto Skill " .. k,
            Value = false,
            Callback = function(v) _G["AutoSkill" .. k] = v end
        })
    end

    Method:Dropdown({
        Title = "Select Method Farm",
        Options = Globals.MethodList,
        Multi = false,
        Value = "Upper",
        Callback = function(v) _G.Select_Method = v end
    })
    Method:Slider({
        Title = "Distance Farm",
        Min = 0, Max = 30, Value = 5,
        Callback = function(v) _G.Distance_Farm = v end
    })

    Haki:Toggle({
        Title = "Auto Enabled Haki",
        Value = false,
        Callback = function(v) _G.Auto_Haki = v end
    })

    VFX:Toggle({
        Title = "Disable VFX",
        Value = false,
        Callback = function(v)
            _G.VFXDisabled = v
            NoVFX.SetState(v)
        end
    })

    -- ===== Page 2 =====
    local Accessory = Page2:CreateSection("🎒 Accessory & Rebirth", "Right")
    local Potion    = Page2:CreateSection("🧪 Auto Use X2 Potion", "Left")

    Accessory:Toggle({
        Title = "Auto Equip The Best Accessory",
        Value = false,
        Callback = function(v) _G.Auto_Equip_Accessory = v end
    })
    Accessory:Toggle({
        Title = "Auto Rebirth (Max Level)",
        Value = false,
        Callback = function(v) _G.Auto_Rebirth = v end
    })

    Potion:Dropdown({
        Title = "Select X2 Potion",
        Options = X2List,
        Multi = true,
        Callback = function(v) _G.Select_Potion = v end
    })
    Potion:Toggle({
        Title = "Auto Use X2 Potion",
        Value = false,
        Callback = function(v) _G.Auto_Use_Potion = v end
    })
end

return SettingsTab
