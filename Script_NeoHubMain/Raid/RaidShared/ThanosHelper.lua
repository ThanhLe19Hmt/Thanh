-- Raid/RaidShared/ThanosHelper.lua
-- Helper tìm/equip/spam F Thanos — dùng chung Bacon/Dragon/Lava

local Services = require(script.Parent.Parent.Parent.Core.Services)
local LocalPlayer = Services.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage

local M = {}

function M.FindThanosTool()
    local char = LocalPlayer.Character
    if not char then return nil, "character" end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            if name == "thanos" or name:find("thanos") then
                return tool, "character"
            end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name == "thanos" or name:find("thanos") then
                    return tool, "backpack"
                end
            end
        end
    end
    return nil, "none"
end

function M.EnsureThanosEquipped()
    local char = LocalPlayer.Character
    if not char then return false end
    local tool, loc = M.FindThanosTool()
    if not tool then return false end
    if loc == "character" then return true end
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        pcall(function() hum:EquipTool(tool) end)
        task.wait(0.2)
        return true
    end
    return false
end

function M.TryUseThanosF(hrp)
    if not hrp then return "no_tool" end
    local char = LocalPlayer.Character
    if not char then return "no_tool" end
    if not M.EnsureThanosEquipped() then return "no_tool" end

    local thanosTool = nil
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local n = tool.Name:lower()
            if n == "thanos" or n:find("thanos") then
                thanosTool = tool
                break
            end
        end
    end
    if not thanosTool then return "no_tool" end

    local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
    local main = hud and hud:FindFirstChild("Main")
    local skillList = main and main:FindFirstChild("Frame_SkillList_Thanos")

    if skillList then
        local border = skillList:FindFirstChild("Border")
        local mainFrame = border and border:FindFirstChild("Main")
        local fFrame = mainFrame and mainFrame:FindFirstChild("F")
        if fFrame then
            local readyLabel = fFrame:FindFirstChild("Ready")
            local cdFrame = fFrame:FindFirstChild("CooldownFrame")
            if (readyLabel and readyLabel.Text == "UnReady")
               or (cdFrame and cdFrame.Visible) then
                return "cooldown"
            end
        end
    end

    task.wait(0.3)

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local action = remotes and remotes:FindFirstChild("Action")
    if action then
        pcall(function() action:FireServer(thanosTool.Name, "f") end)
        task.wait(0.3)
        return "success"
    end
    return "no_tool"
end

return M
