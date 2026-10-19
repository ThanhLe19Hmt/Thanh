-- Core/Helpers.lua
-- Các hàm tiện ích dùng chung

local Services = require(script.Parent.Services)
local LocalPlayer = Services.LocalPlayer
local HttpService = Services.HttpService

local Helpers = {}

-- Format số: 1234 → 1.2K
function Helpers.FormatNumber(n)
    n = tonumber(n) or 0
    if n < 0 then return tostring(n) end
    if n < 1000 then return tostring(math.floor(n)) end
    if n < 1000000 then
        local k = math.floor(n / 100) / 10
        return k == math.floor(k) and tostring(math.floor(k)) .. "K"
            or string.format("%.1fK", k)
    end
    if n < 1000000000 then
        local m = math.floor(n / 100000) / 10
        return m == math.floor(m) and tostring(math.floor(m)) .. "M"
            or string.format("%.1fM", m)
    end
    local b = math.floor(n / 100000000) / 10
    return b == math.floor(b) and tostring(math.floor(b)) .. "B"
        or string.format("%.1fB", b)
end

function Helpers.SafeWait(parent, name, timeout)
    local ok, result = pcall(function()
        return parent:WaitForChild(name, timeout or 3)
    end)
    if ok and result then return result end
    return parent:FindFirstChild(name)
end

function Helpers.SafeRequire(module)
    if not module then return nil end
    local ok, result = pcall(function() return require(module) end)
    return ok and result or nil
end

-- Inventory cache
local CachedInventory = {}
local LastInventory = 0

function Helpers.GetInventory()
    if tick() - LastInventory < 0.2 then return CachedInventory end
    LastInventory = tick()
    local ok, inv = pcall(function()
        return HttpService:JSONDecode(LocalPlayer:GetAttribute("Inventory") or "{}")
    end)
    CachedInventory = ok and inv or {}
    return CachedInventory
end

function Helpers.GetItemAmount(itemName)
    local inv = Helpers.GetInventory()
    return (inv[itemName] and inv[itemName].amount) or 0
end

-- Teleport (ghi đè CFrame)
function Helpers.Teleport(pos)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = pos
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

-- AsString / AsStringList cho save manager
function Helpers.AsString(v)
    if type(v) == "string" then return v end
    if type(v) == "table" then
        for _, item in pairs(v) do
            if type(item) == "string" then return item end
        end
    end
    return nil
end

function Helpers.AsStringList(v)
    local list = {}
    if type(v) == "string" then table.insert(list, v)
    elseif type(v) == "table" then
        for _, item in pairs(v) do
            if type(item) == "string" then table.insert(list, item) end
        end
    end
    return list
end

return Helpers
