-- RaidMoon/MoonRocket.lua
local Config = require(script.Parent.Parent.Core.Config)

local M = {}
local RocketTower, RocketPos, RocketLastCheck = nil, nil, 0
local CACHE = Config.Moon.ROCKET_CACHE

function M.FindRocketTower()
    if RocketTower and RocketTower.Parent and RocketPos then
        if tick() - RocketLastCheck < CACHE then return RocketPos end
    end
    local rocket = workspace:FindFirstChild("island")
    if rocket then rocket = rocket:FindFirstChild("Moon") end
    if rocket then rocket = rocket:FindFirstChild("RocketTower") end
    if not rocket then return nil end

    local pos
    if rocket:IsA("Model") then
        local part = rocket:FindFirstChild("HumanoidRootPart")
            or rocket.PrimaryPart
            or rocket:FindFirstChildWhichIsA("BasePart")
        if part then pos = part.Position end
    elseif rocket:IsA("BasePart") then
        pos = rocket.Position
    end

    if pos then
        RocketTower = rocket
        RocketPos = pos
        RocketLastCheck = tick()
        return pos
    end
    return nil
end

return M
