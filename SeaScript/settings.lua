-- ============================================================
-- SETTINGS MODULE - v1
-- Chứa toàn bộ tính năng Tab Settings
-- Usage: loadstring(readfile("settings.lua"))() hoặc require
-- ============================================================
return function(ctx)
    -- ctx = { Window, LocalPlayer, ReplicatedStorage, TypeTool, X2List,
    --         NoVFX, EquipWeapon, AutoSkill, Attack, _G, ... }
    
    local Window         = ctx.Window
    local LocalPlayer    = ctx.LocalPlayer
    local ReplicatedStorage = ctx.ReplicatedStorage
    local TypeTool       = ctx.TypeTool or {"Melee", "Sword", "Special", "DevilFruit"}
    local X2List         = ctx.X2List or {}
    local NoVFX          = ctx.NoVFX
    local _G             = ctx._G or _G

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

    -- Weapon
    Weapon:Dropdown({
        Title = "Main Weapon (Attack)",
        Options = TypeTool,
        Multi = false,
        Value = "Melee",
        Callback = function(Value) _G.MainWeapon = Value end
    })
    Weapon:Dropdown({
        Title = "Select Support Weapon",
        Options = TypeTool,
        Multi = true,
        Callback = function(Value) _G.Select_EquipWeapon = Value end
    })

    -- Auto Skills
    AutoSkills:Toggle({Title = "Auto Skill Z", Id = "SKILLZ", Value = false, Callback = function(v) _G.AutoSkillZ = v end})
    AutoSkills:Toggle({Title = "Auto Skill X", Id = "SKILLX", Value = false, Callback = function(v) _G.AutoSkillX = v end})
    AutoSkills:Toggle({Title = "Auto Skill C", Id = "SKILLC", Value = false, Callback = function(v) _G.AutoSkillC = v end})
    AutoSkills:Toggle({Title = "Auto Skill V", Id = "SKILLV", Value = false, Callback = function(v) _G.AutoSkillV = v end})
    AutoSkills:Toggle({Title = "Auto Skill F", Id = "SKILLF", Value = false, Callback = function(v) _G.AutoSkillF = v end})

    -- Haki
    Haki:Toggle({Title = "Auto Enable Haki", Id = "AENHAKI", Value = false, Callback = function(v) _G.Auto_Haki = v end})

    -- Method
    Method:Dropdown({
        Title = "Select Farm Method",
        Options = {"Behind", "Below", "Upper", "Front"},
        Id = "SELEMETHODFARM",
        Multi = false,
        Value = "Upper",
        Callback = function(v) _G.Select_Method = v end
    })
    Method:Slider({
        Title = "Farm Distance",
        Min = 0, Max = 30, Value = 5,
        Callback = function(v) _G.Distance_Farm = v end
    })

    -- VFX
    VFX:Toggle({
        Title = "Disable VFX",
        Value = false,
        Callback = function(v)
            if NoVFX then NoVFX(v) end
        end
    })

    -- Accessory / Rebirth
    Accessory:Toggle({
        Title = "Auto Equip Best Accessory",
        Value = false,
        Callback = function(v) _G.Auto_Equip_Accessory = v end
    })
    Accessory:Toggle({
        Title = "Auto Rebirth (Max Level)",
        Value = false,
        Callback = function(v) _G.Auto_Rebirth = v end
    })

    -- X2 Potion
    Potion:Dropdown({
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
        end
    })

    Potion:Toggle({
        Title = "🤖 Auto Use Potion",
        Value = false,
        Callback = function(v) _G.Auto_Use_Potion = v end
    })

    local PotionInfoPara = Potion:Paragraph({
        Title = "🍦 X2 Potions: ---",
        Content = "Chọn Potion để xem"
    })

    -- Trả về API cho script chính cập nhật UI
    return {
        PotionInfoPara = PotionInfoPara,
        Tab = Tab1
    }
end
