-- Shop/MysteryBox.lua
local Services = require(script.Parent.Parent.Core.Services)
local Helpers  = require(script.Parent.Parent.Core.Helpers)
local LocalPlayer = Services.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage
local GetInventory = Helpers.GetInventory

_G.MysteryBoxSelected  = _G.MysteryBoxSelected or "Time Mystery Box"
_G.MysteryBoxAmount    = _G.MysteryBoxAmount or 1
_G.MysteryBoxAuto      = _G.MysteryBoxAuto or false
_G.MysteryBoxAutoDelay = _G.MysteryBoxAutoDelay or 0.5
_G.MysteryBoxLastOpen  = 0
_G.MysteryBoxOutNotified = false

local MYSTERY_REWARD_FRAMES = {"Frame_CompactRandom", "Frame_RandomItem"}
_G.MysteryBoxCloseAt = _G.MysteryBoxCloseAt or {}
_G.MysteryBoxHookedFrames = _G.MysteryBoxHookedFrames or {}
_G.MysteryBoxFrameConns = _G.MysteryBoxFrameConns or {}

local function CloseFrame(frame)
    if not frame or not frame.Parent then return false end
    local btn = frame:FindFirstChild("Close_")
        or frame:FindFirstChild("Close")
        or frame:FindFirstChild("CloseButton")
        or frame:FindFirstChild("Exit")
    if btn then
        pcall(function()
            if firesignal then firesignal(btn.MouseButton1Click)
            else btn:Activate() end
        end)
    end
    task.wait(0.15)
    if frame.Parent and frame.Visible then pcall(function() frame.Visible = false end) end
    return true
end

local function AttachHooks()
    local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
    local main = hud and hud:FindFirstChild("Main")
    if not main then return end
    for _, name in ipairs(MYSTERY_REWARD_FRAMES) do
        local frame = main:FindFirstChild(name)
        if frame and not _G.MysteryBoxHookedFrames[frame] then
            _G.MysteryBoxHookedFrames[frame] = true
            local conn = frame:GetPropertyChangedSignal("Visible"):Connect(function()
                if frame.Visible then
                    _G.MysteryBoxCloseAt[frame] = tick() + 5
                else
                    _G.MysteryBoxCloseAt[frame] = 0
                end
            end)
            table.insert(_G.MysteryBoxFrameConns, conn)
        end
    end
end

task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            local now = tick()
            AttachHooks()
            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            local main = hud and hud:FindFirstChild("Main")
            if main then
                for _, name in ipairs(MYSTERY_REWARD_FRAMES) do
                    local frame = main:FindFirstChild(name)
                    if frame and frame.Visible then
                        if not _G.MysteryBoxCloseAt[frame] or _G.MysteryBoxCloseAt[frame] == 0 then
                            _G.MysteryBoxCloseAt[frame] = now + 5
                        end
                        if now >= _G.MysteryBoxCloseAt[frame] then
                            CloseFrame(frame)
                            _G.MysteryBoxCloseAt[frame] = 0
                        end
                    end
                end
            end
            if not _G.MysteryBoxAuto then return end
            local box = _G.MysteryBoxSelected or "Time Mystery Box"
            local amt = tonumber(_G.MysteryBoxAmount) or 1
            if amt < 1 then amt = 1 end
            if amt > 100 then amt = 100 end
            local delay = tonumber(_G.MysteryBoxAutoDelay) or 0.5
            if delay < 0.1 then delay = 0.1 end
            if now - (_G.MysteryBoxLastOpen or 0) < delay then return end
            local inv = GetInventory()
            local have = (inv[box] and inv[box].amount) or 0
            if have <= 0 then
                if not _G.MysteryBoxOutNotified then
                    _G.MysteryBoxOutNotified = true
                    _G.SeaNotify("⏸️ Auto paused", box .. " out of stock", 4)
                end
                return
            end
            _G.MysteryBoxOutNotified = false
            _G.MysteryBoxLastOpen = now
            pcall(function()
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                    "fire", nil, box, math.min(amt, have))
            end)
        end)
    end
end)
