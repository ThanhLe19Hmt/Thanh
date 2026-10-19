-- Systems/AutoAccessory.lua
local Services = require(script.Parent.Parent.Core.Services)
local LocalPlayer = Services.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage
local HttpService = Services.HttpService

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local Data = _G.Data
            if not _G.Auto_Equip_Accessory or not (Data and Data.AccessoryModule) then return end

            local Inventory = HttpService:JSONDecode(LocalPlayer:GetAttribute("Inventory") or "{}")
            local Equipped  = HttpService:JSONDecode(LocalPlayer:GetAttribute("UseAccessory") or "{}")
            local Best = {}

            for Name in pairs(Inventory) do
                local Info = Data.AccessoryModule[Name]
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

            for Type, Item in pairs(Best) do
                local EquippedName
                for Name, Info in pairs(Equipped) do
                    if Info.Type == Type then EquippedName = Name; break end
                end
                if EquippedName ~= Item.Name then
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                    local inv = remotes and remotes:FindFirstChild("Inventory")
                    if inv then inv:FireServer(Item.Name) end
                    task.wait(0.5)
                end
            end
        end)
    end
end)
