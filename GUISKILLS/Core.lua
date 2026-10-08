--[[
    MarvenRiz Hub VIP - Core Module
    Utilities, Cache, Task Manager, Logger
]]

local Core = {}

-- ============================================================
-- SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser      = game:GetService("VirtualUser")
local TweenService     = game:GetService("TweenService")
local LocalPlayer      = Players.LocalPlayer

Core.Services = {
    Players = Players,
    ReplicatedStorage = ReplicatedStorage,
    HttpService = HttpService,
    RunService = RunService,
    UserInputService = UserInputService,
    LocalPlayer = LocalPlayer,
}

-- ============================================================
-- LOGGER (có prefix + level)
-- ============================================================
local LOG_LEVELS = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }
local CurrentLogLevel = LOG_LEVELS.INFO

function Core.SetLogLevel(level) CurrentLogLevel = LOG_LEVELS[level] or LOG_LEVELS.INFO end

local function log(level, ...)
    if LOG_LEVELS[level] < CurrentLogLevel then return end
    local prefix = "[MarvenRiz:" .. level .. "]"
    local args = { ... }
    local str = ""
    for i, v in ipairs(args) do
        str = str .. tostring(v) .. (i < #args and " " or "")
    end
    print(prefix, str)
end

Core.Log = {
    Debug = function(...) log("DEBUG", ...) end,
    Info  = function(...) log("INFO", ...) end,
    Warn  = function(...) log("WARN", ...) end,
    Error = function(...) log("ERROR", ...) end,
}

-- ============================================================
-- SAFE CALL (bọc pcall + log lỗi)
-- ============================================================
function Core.Safe(fn, ...)
    local args = { ... }
    local ok, result = pcall(function()
        return fn(table.unpack(args))
    end)
    if not ok then
        Core.Log.Warn("[Safe] Error:", result)
    end
    return ok, result
end

function Core.SafeSilent(fn, ...)
    return pcall(fn, ...)
end

-- ============================================================
-- SMART CACHE (TTL-based)
-- ============================================================
local Cache = {}
Cache._store = {}

function Cache:Get(key)
    local entry = self._store[key]
    if not entry then return nil end
    if tick() - entry.time > entry.ttl then
        self._store[key] = nil
        return nil
    end
    return entry.value
end

function Cache:Set(key, value, ttl)
    self._store[key] = { value = value, time = tick(), ttl = ttl or 1 }
end

function Cache:Invalidate(key) self._store[key] = nil end
function Cache:Clear() self._store = {} end

Core.Cache = Cache

-- ============================================================
-- TASK MANAGER (tập trung, có thể start/stop)
-- ============================================================
local TaskManager = {}
TaskManager._tasks = {}   -- { name = { thread, running, fn } }

function TaskManager:Register(name, fn)
    if self._tasks[name] then
        Core.Log.Warn("[TaskManager] Task đã tồn tại:", name)
        return
    end
    self._tasks[name] = { fn = fn, running = false, thread = nil }
end

function TaskManager:Start(name)
    local task = self._tasks[name]
    if not task then Core.Log.Warn("[TaskManager] Không tìm thấy task:", name) return end
    if task.running then return end
    task.running = true
    task.thread = task.spawn(function()
        while task.running do
            local ok, err = pcall(task.fn)
            if not ok then
                Core.Log.Error("[TaskManager:" .. name .. "]", err)
                task.wait(1)
            end
        end
    end)
end

function TaskManager:Stop(name)
    local task = self._tasks[name]
    if not task then return end
    task.running = false
    if task.thread then
        pcall(task.coroutine.close, task.thread)
        task.thread = nil
    end
end

function TaskManager:StopAll()
    for name in pairs(self._tasks) do
        self:Stop(name)
    end
end

function TaskManager:IsRunning(name)
    local task = self._tasks[name]
    return task and task.running
end

Core.TaskManager = TaskManager

-- ============================================================
-- PLAYER HELPERS
-- ============================================================
function Core.GetCharacter()
    local char = LocalPlayer.Character
    if not char or not char.Parent then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return nil end
    return char, hum, hrp
end

function Core.GetHRP()
    local _, _, hrp = Core.GetCharacter()
    return hrp
end

function Core.Teleport(cf)
    local char = LocalPlayer.Character
    if char then char:PivotTo(cf) end
end

-- ============================================================
-- INVENTORY (cached)
-- ============================================================
function Core.GetInventory()
    local cached = Cache:Get("inventory")
    if cached then return cached end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(LocalPlayer:GetAttribute("Inventory") or "{}")
    end)
    local inv = (ok and type(data) == "table") and data or {}
    Cache:Set("inventory", inv, 0.5)
    return inv
end

function Core.GetItemAmount(itemName)
    local inv = Core.GetInventory()
    local item = inv[itemName]
    return item and (item.amount or 0) or 0
end

function Core.GetAttribute(name, default)
    local key = "attr_" .. name
    local cached = Cache:Get(key)
    if cached ~= nil then return cached end
    local val = LocalPlayer:GetAttribute(name)
    if val == nil then val = default end
    Cache:Set(key, val, 0.3)
    return val
end

-- ============================================================
-- NETWORK (wrapper)
-- ============================================================
local function GetNetworkEvent()
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    if not modules then return nil end
    local framework = modules:FindFirstChild("NetworkFramework")
    if not framework then return nil end
    return framework:FindFirstChild("NetworkEvent")
end

function Core.FireNetwork(...)
    local evt = GetNetworkEvent()
    if evt then
        evt:FireServer("fire", nil, ...)
        return true
    end
    return false
end

function Core.FireRemote(remotePath, ...)
    local remote = ReplicatedStorage
    for _, seg in ipairs(remotePath) do
        remote = remote:FindFirstChild(seg)
        if not remote then return false end
    end
    remote:FireServer(...)
    return true
end

function Core.GetAction()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("Action")
end

function Core.GetSystem()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("System")
end

function Core.GetInventoryRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("Inventory")
end

function Core.FireProximityPrompt(prompt)
    if not prompt then return end
    local ok, err = pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration or 0)
            prompt:InputHoldEnd()
        end
    end)
    if not ok then Core.Log.Warn("[ProximityPrompt]", err) end
end

-- ============================================================
-- ANTI-AFK
-- ============================================================
function Core.SetupAntiAFK()
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    Core.Log.Info("Anti-AFK đã bật")
end

-- ============================================================
-- MISC HELPERS
-- ============================================================
function Core.WaitForCharacter(timeout)
    timeout = timeout or 10
    local start = tick()
    repeat
        task.wait(0.1)
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then return char end
    until tick() - start > timeout
    return nil
end

function Core.Debounce(fn, delay)
    local last = 0
    return function(...)
        local now = tick()
        if now - last >= (delay or 0.1) then
            last = now
            return fn(...)
        end
    end
end

function Core.FormatNumber(n)
    if not n then return "0" end
    if n >= 1e12 then return string.format("%.1fT", n / 1e12) end
    if n >= 1e9  then return string.format("%.1fB", n / 1e9)  end
    if n >= 1e6  then return string.format("%.1fM", n / 1e6)  end
    if n >= 1e3  then return string.format("%.1fK", n / 1e3)  end
    return tostring(math.floor(n))
end

return Core
