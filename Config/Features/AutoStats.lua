--[[
    Features/AutoStats.lua
    Auto Up Stats, Auto Rebirth, Auto Haki, Auto Equip Accessory
]]

local Globals = _G.__Globals
assert(Globals, "[Module] _G.__Globals chưa được set! Load Main.lua trước.")
local RS = Globals.ReplicatedStorage
local HttpService = Globals.HttpService
local LP = Globals.LocalPlayer

-- ===== Auto Up Stats =====
task.spawn(function()
    while task.wait(0.1) do
        if _G.AutoMelee then
            RS.Remotes.System:FireServer("UpStats", "Melee", _G.Amount)
        end
        if _G.AutoDefense then
            RS.Remotes.System:FireServer("UpStats", "Defense", _G.Amount)
        end
        if _G.AutoSword then
            RS.Remotes.System:FireServer("UpStats", "Sword", _G.Amount)
        end
        if _G.AutoPower then
            RS.Remotes.System:FireServer("UpStats", "Power", _G.Amount)
        end
    end
end)

-- ===== Auto Rebirth =====
task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_Rebirth then
                local lvlText = LP.PlayerGui.HUD.Main.Frame_Display.LevelText.Text:lower()
                if lvlText:find("max") then
                    RS.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Rebirth")
                end
            end
        end)
    end
end)

-- ===== Auto Haki =====
task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_Haki then
                local char = LP.Character
                if char and not char:FindFirstChild("HakiFolder") then
                    RS.Remotes.Action:FireServer("Misc", "buso")
                end
            end
        end)
    end
end)

-- ===== Auto Equip Best Accessory =====
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if not _G.Auto_Equip_Accessory then return end
            local inventory = HttpService:JSONDecode(LP:GetAttribute("Inventory") or "{}")
            local equipped = HttpService:JSONDecode(LP:GetAttribute("UseAccessory") or "{}")
            local best = {}
            for name in pairs(inventory) do
                local info = Globals.AccessoryModule[name]
                if info then
                    local score = 0
                    for _, value in pairs(info) do
                        if type(value) == "number" then score = score + value end
                    end
                    if not best[info.Type] or score > best[info.Type].Score then
                        best[info.Type] = {Name = name, Score = score}
                    end
                end
            end
            for _, data in pairs(best) do
                local equippedName
                for name, info in pairs(equipped) do
                    if info.Type == data.Type then
                        equippedName = name
                        break
                    end
                end
                if equippedName ~= data.Name then
                    RS.Remotes.Inventory:FireServer(data.Name)
                    task.wait(0.5)
                end
            end
        end)
    end
end)
