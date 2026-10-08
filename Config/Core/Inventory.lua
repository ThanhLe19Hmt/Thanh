--[[
    Core/Inventory.lua
    Inventory + Item helpers
]]

local Inventory = {}

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local LocalPlayer       = Players.LocalPlayer

local CachedInventory = {}
local LastInventory   = 0

-- ===== Get Inventory =====
function Inventory.Get()
    if tick() - LastInventory < 0.2 then
        return CachedInventory
    end
    LastInventory = tick()
    local ok, inv = pcall(function()
        return HttpService:JSONDecode(LocalPlayer:GetAttribute("Inventory") or "{}")
    end)
    CachedInventory = ok and inv or {}
    return CachedInventory
end

-- ===== Get Item Amount =====
function Inventory.GetAmount(itemName)
    local inv = Inventory.Get()
    return (inv[itemName] and inv[itemName].amount) or 0
end

-- ===== Force refresh =====
function Inventory.Refresh()
    LastInventory = 0
    return Inventory.Get()
end

return Inventory
