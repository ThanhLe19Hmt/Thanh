-- RaidMoon/MoonTarget.lua
local Services = require(script.Parent.Parent.Core.Services)
local MoonRocket = require(script.MoonRocket)

local LocalPlayer = Services.LocalPlayer

local M = {}
local CurrentTarget = nil

local function IsMobValid(mob)
    if not mob or not mob.Parent or not mob:IsA("Model") then return false end
    local hum = mob:FindFirstChild("Humanoid")
    local hrp = mob:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return false end
    if hum.Health <= 0 or hum.MaxHealth <= 0 then return false end
    return true
end

function M.GetMoonTarget()
    local char = LocalPlayer.Character
    local myHrp = char and char:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    local mobFolder = workspace:FindFirstChild("Mob") or workspace:FindFirstChild("Mobs")
    if not mobFolder then return nil end

    if CurrentTarget and CurrentTarget.Parent then
        local h = CurrentTarget:FindFirstChild("Humanoid")
        if h and h.Health > 0 then return CurrentTarget, "🎯 ATTACKING" end
        CurrentTarget = nil
    end

    local basePos = MoonRocket.FindRocketTower()
    local best, bestDist = nil, math.huge
    for _, mob in ipairs(mobFolder:GetChildren()) do
        if IsMobValid(mob) and basePos then
            local d = (basePos - mob.HumanoidRootPart.Position).Magnitude
            if d < bestDist then bestDist = d; best = mob end
        end
    end
    if not best then
        local minPD = math.huge
        for _, mob in ipairs(mobFolder:GetChildren()) do
            if IsMobValid(mob) then
                local dp = (myHrp.Position - mob.HumanoidRootPart.Position).Magnitude
                if dp < minPD then minPD = dp; best = mob end
            end
        end
    end
    CurrentTarget = best
    return best, best and "🎯 DEFEND ROCKETTOWER" or nil
end

return M
