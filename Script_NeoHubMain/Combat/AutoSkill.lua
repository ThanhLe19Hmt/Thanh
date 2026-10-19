-- Combat/AutoSkill.lua
-- Auto skill + clear dash body movers

local Services = require(script.Parent.Parent.Core.Services)
local LocalPlayer = Services.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage

_G.LastSkillTime = 0
_G.LastSkillKey  = ""
_G.DASH_SKILLS   = {x = true}
_G.DASH_NEGATE_TIME = 0.35

local function AutoSkill()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local Skills = {}
        if _G.AutoSkillZ then table.insert(Skills, "z") end
        if _G.AutoSkillX then table.insert(Skills, "x") end
        if _G.AutoSkillC then table.insert(Skills, "c") end
        if _G.AutoSkillV then table.insert(Skills, "v") end
        if _G.AutoSkillF then table.insert(Skills, "f") end
        if #Skills == 0 then return end

        local Skill = Skills[math.random(#Skills)]
        _G.LastSkillTime = tick()
        _G.LastSkillKey  = Skill

        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local action = remotes and remotes:FindFirstChild("Action")
        if not action then return end

        for _, Tool in ipairs(char:GetChildren()) do
            if Tool:IsA("Tool") then
                action:FireServer(Tool.Name, Skill)
            end
        end

        if _G.ClearDashBodyMovers and hrp then
            _G.ClearDashBodyMovers(hrp, 0.8)
        end
    end)
end

function _G.ClearDashBodyMovers(hrp, duration)
    if not hrp or not hrp.Parent then return end
    duration = duration or 0.8

    task.spawn(function()
        local startTime = tick()
        while tick() - startTime < duration do
            task.wait(0.03)
            if not hrp or not hrp.Parent then break end
            for _, child in ipairs(hrp:GetChildren()) do
                if child:IsA("BodyVelocity")
                   or child:IsA("BodyGyro")
                   or child:IsA("AlignPosition") then
                    pcall(function() child:Destroy() end)
                end
            end
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

return AutoSkill
