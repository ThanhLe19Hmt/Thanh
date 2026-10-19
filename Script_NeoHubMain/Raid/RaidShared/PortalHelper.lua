-- Raid/RaidShared/PortalHelper.lua
-- Tìm template + click Open + đóng GUI

local Services = require(script.Parent.Parent.Parent.Core.Services)
local LocalPlayer = Services.LocalPlayer

local M = {}

function M.CloseFrame(frame)
    if not frame then return false end
    local closeBtn = frame:FindFirstChild("Close_")
        or frame:FindFirstChild("Close")
        or frame:FindFirstChild("CloseButton")
        or frame:FindFirstChild("Exit")
        or frame:FindFirstChildWhichIsA("ImageButton", true)
        or frame:FindFirstChildWhichIsA("TextButton", true)
    if closeBtn then
        pcall(function()
            if firesignal then
                firesignal(closeBtn.MouseButton1Click)
            elseif fireclickdetector then
                fireclickdetector(closeBtn)
            else
                closeBtn:Activate()
            end
        end)
        return true
    end
    pcall(function() frame.Visible = false end)
    return true
end

-- Tìm template theo keyword (tên frame hoặc TitleLabel đệ quy)
function M.FindTemplate(raidBossFrame, keyword)
    if not raidBossFrame then return nil end
    local sf = raidBossFrame:FindFirstChild("ScrollingFrame")
    if sf then
        for _, child in ipairs(sf:GetChildren()) do
            if child:IsA("Frame") then
                local titleLabel = child:FindFirstChild("TitleLabel", true)
                if titleLabel and titleLabel.Text then
                    if titleLabel.Text:lower():find(keyword) then
                        return child
                    end
                end
                if child.Name:lower():find(keyword) then
                    return child
                end
            end
        end
    end
    return nil
end

-- Click Open button trong template
function M.ClickOpenButton(template)
    if not template then return false end
    local openButton = nil

    for _, obj in ipairs(template:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Text then
            if obj.Text:lower() == "open" then
                local parent = obj.Parent
                while parent and parent ~= template do
                    if parent:IsA("TextButton") or parent:IsA("ImageButton") then
                        openButton = parent
                        break
                    end
                    parent = parent.Parent
                end
                if openButton then break end
            end
        end
    end

    if not openButton then
        local mainBtn = template:FindFirstChild("Main", true)
        if mainBtn and (mainBtn:IsA("TextButton") or mainBtn:IsA("ImageButton")) then
            openButton = mainBtn
        end
    end

    if openButton then
        pcall(function()
            if firesignal then
                firesignal(openButton.MouseButton1Click)
            else
                openButton:Activate()
            end
        end)
        return true
    end
    return false
end

-- Đóng GUI Frame_RaidBoss với retry loop
function M.CloseRaidBossFrame(timeout)
    timeout = timeout or 3
    task.spawn(function()
        local startTime = tick()
        while tick() - startTime < timeout do
            task.wait(0.15)
            pcall(function()
                local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                local main = hud and hud:FindFirstChild("Main")
                local frame = main and main:FindFirstChild("Frame_RaidBoss")
                if frame and frame.Visible then
                    local closeBtn = frame:FindFirstChild("Close_")
                        or frame:FindFirstChild("Close")
                        or frame:FindFirstChild("CloseButton")
                    if closeBtn then
                        pcall(function()
                            if firesignal then
                                firesignal(closeBtn.MouseButton1Click)
                            else
                                closeBtn:Activate()
                            end
                        end)
                    end
                    task.wait(0.1)
                    if frame.Visible then
                        pcall(function() frame.Visible = false end)
                    end
                    break
                end
            end)
        end
    end)
end

-- Đóng GUI nhận thưởng (Victory) — chỉ 1 lần
function M.CloseRewardFrameOnce(tag)
    task.spawn(function()
        local startTime = tick()
        local clicked = false
        while tick() - startTime < 5 do
            task.wait(0.2)
            if clicked then break end
            pcall(function()
                local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                local main = hud and hud:FindFirstChild("Main")
                if not main then return end
                local rewardFrame = main:FindFirstChild("Frame_RaidbossItem")
                    or main:FindFirstChild("Frame_RaidBossItem")
                    or main:FindFirstChild("Frame_RaidBoss")
                    or main:FindFirstChild("Frame_Raidboss")
                if not rewardFrame or not rewardFrame.Visible then return end

                local closeBtn = rewardFrame:FindFirstChild("Close_")
                    or rewardFrame:FindFirstChild("Close")
                    or rewardFrame:FindFirstChild("CloseButton")
                if closeBtn then
                    pcall(function()
                        if firesignal then
                            firesignal(closeBtn.MouseButton1Click)
                        else
                            closeBtn:Activate()
                        end
                    end)
                end
                task.wait(0.2)
                if rewardFrame.Visible then
                    pcall(function() rewardFrame.Visible = false end)
                end
                clicked = true
                if tag then print("[" .. tag .. "] 🎁 Đã đóng GUI nhận thưởng") end
            end)
        end
    end)
end

return M
