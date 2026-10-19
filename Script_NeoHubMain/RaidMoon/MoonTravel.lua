-- RaidMoon/MoonTravel.lua
-- (Logic button đã ở MoonUI — file này export helper cho ai cần)
local Services = require(script.Parent.Parent.Core.Services)
local LocalPlayer = Services.LocalPlayer

local M = {}

function M.BackToEarth()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local npcPrompt = workspace:FindFirstChild("NpcPrompt")
    local backEarth = npcPrompt and npcPrompt:FindFirstChild("BackEarth")
    if not backEarth then return end
    local npcHrp = backEarth:FindFirstChild("HumanoidRootPart")
    if not npcHrp then return end
    hrp.CFrame = CFrame.new(npcHrp.Position + Vector3.new(0, 2, 0))
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.4)
    local prompt = npcHrp:FindFirstChildWhichIsA("ProximityPrompt", true)
        or backEarth:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        pcall(function() fireproximityprompt(prompt, prompt.HoldDuration + 0.1) end)
    end
end

return M
