-- Systems/AutoHaki.lua
local Services = require(script.Parent.Parent.Core.Services)
local LocalPlayer = Services.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage

task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_Haki then
                if LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("HakiFolder") then
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                    local action = remotes and remotes:FindFirstChild("Action")
                    if action then action:FireServer("Misc", "buso") end
                end
            end
        end)
    end
end)
