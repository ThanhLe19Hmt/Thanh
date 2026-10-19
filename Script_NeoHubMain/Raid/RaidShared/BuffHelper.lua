-- Raid/RaidShared/BuffHelper.lua
-- Tìm/spam F buff (Kaioken, SSJ...)

local Services = require(script.Parent.Parent.Parent.Core.Services)
local Config   = require(script.Parent.Parent.Parent.Core.Config)

local LocalPlayer = Services.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage

local M = {}

function M.FindBuffTool(buffList)
    buffList = buffList or Config.Bacon.BUFF_LIST
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    for _, buffName in ipairs(buffList) do
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower() == buffName:lower() then
                return tool, buffName
            end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, buffName in ipairs(buffList) do
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") and tool.Name:lower() == buffName:lower() then
                    return tool, buffName
                end
            end
        end
    end
    return nil, nil
end

function M.BuffSpamLoop(buffList, cooldown)
    buffList = buffList or Config.Bacon.BUFF_LIST
    cooldown = cooldown or 0.3
    local tool, buffName = M.FindBuffTool(buffList)
    if not tool then return false end

    local startTime = tick()
    local lastFTime = 0

    while tick() - startTime < 15 do
        local now = tick()
        if now - lastFTime >= cooldown then
            lastFTime = now
            local char = LocalPlayer.Character
            if not char then break end

            local currentTool = nil
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") and t.Name:lower() == buffName:lower() then
                    currentTool = t
                    break
                end
            end
            if not currentTool then
                local bp = LocalPlayer:FindFirstChild("Backpack")
                if bp then
                    for _, t in ipairs(bp:GetChildren()) do
                        if t:IsA("Tool") and t.Name:lower() == buffName:lower() then
                            char.Humanoid:EquipTool(t)
                            task.wait(0.3)
                            currentTool = t
                            break
                        end
                    end
                end
            end
            if not currentTool then break end

            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            local main = hud and hud:FindFirstChild("Main")
            local skillList = main and main:FindFirstChild("Frame_SkillList_" .. buffName)
            local fOnCooldown = false
            if skillList then
                local border = skillList:FindFirstChild("Border")
                local mainFrame = border and border:FindFirstChild("Main")
                local fFrame = mainFrame and mainFrame:FindFirstChild("F")
                if fFrame then
                    local readyLabel = fFrame:FindFirstChild("Ready")
                    local cdFrame = fFrame:FindFirstChild("CooldownFrame")
                    if (readyLabel and readyLabel.Text == "UnReady")
                       or (cdFrame and cdFrame.Visible) then
                        fOnCooldown = true
                    end
                end
            end
            if fOnCooldown then break end

            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            local action = remotes and remotes:FindFirstChild("Action")
            if action then
                pcall(function() action:FireServer(currentTool.Name, "f") end)
            end
        end
        task.wait(0.1)
    end
    return true
end

return M
