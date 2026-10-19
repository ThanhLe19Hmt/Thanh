-- Systems/AutoRebirth.lua
local Services = require(script.Parent.Parent.Core.Services)
local LocalPlayer = Services.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage

task.spawn(function()
    while task.wait() do
        pcall(function()
            if not _G.Auto_Rebirth then return end
            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            local main = hud and hud:FindFirstChild("Main")
            local display = main and main:FindFirstChild("Frame_Display")
            local levelText = display and display:FindFirstChild("LevelText")
            if levelText and levelText.Text:lower():find("max") then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Rebirth")
            end
        end)
    end
end)
