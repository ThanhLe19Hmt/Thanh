--[[
    Auto Trade - Rock Fruit v75 (Final Hardcode)
    Game ID: 119091355492870

    TRIẾT LÝ:
      - Đã mất quá nhiều thời gian cho visual.
      - Bây giờ chỉ có 1 vòng tròn. Kéo tới đâu = bấm tới đó.
      - Lưu toạ độ hiện tại của vòng tròn.
      - Khi auto: đọc toạ độ đã lưu, tạo wrapper tại đó, bấm.
      - Không có offset phức tạp. Không có hiển thị lệch.

    CÁCH LÀM:
      1. Vòng tròn đỏ 40x40 (dễ nhìn) kéo thả tự do.
      2. Bạn kéo nó tới đúng tâm nút Accept (nhìn bằng mắt).
      3. Bấm "LƯU".
      4. Bấm "TEST" - tool sẽ tạo wrapper tại toạ độ đã lưu
         và bấm. Nếu popup đóng -> đúng.
      5. Bấm "AUTO" - từ giờ mỗi popup hiện, tool bấm tại
         toạ độ đã lưu.
]]

local CONFIG = {
    GameID = 119091355492870,
    Debug  = true,
}

local Players               = game:GetService("Players")
local CoreGui               = game:GetService("CoreGui")
local UserInputService      = game:GetService("UserInputService")
local GuiService            = game:GetService("GuiService")
local VirtualInputManager   = game:GetService("VirtualInputManager")
local LocalPlayer           = Players.LocalPlayer

local function log(...)
    if CONFIG.Debug then print("[AutoTrade]", ...) end
end

local function getInset()
    local tl = Vector2.new(0, 0)
    pcall(function() tl = GuiService.TopLeftInset end)
    return tl
end

local function getHUDMain()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local hud = pg:FindFirstChild("HUD")
    if not hud then return nil end
    return hud:FindFirstChild("Main")
end

local function getTradeRequestFrame()
    local main = getHUDMain()
    if not main then return nil end
    return main:FindFirstChild("Trade_Request")
end

local function getAcceptButton()
    local tr = getTradeRequestFrame()
    if not tr then return nil end
    local sub = tr:FindFirstChild("Sub")
    if not sub then return nil end
    local m = sub:FindFirstChild("Main")
    if not m then return nil end
    local acc = m:FindFirstChild("Accept")
    if not acc then return nil end
    return acc:FindFirstChild("Accept")
end

local function isPopupOpen()
    local tr = getTradeRequestFrame()
    return tr ~= nil and tr.Visible == true
end

-- ============================================================
-- BẤM QUA WRAPPER (giữ nguyên logic đã ăn)
-- ============================================================
local function touchViaWrapper(x, y)
    local wrapSg = Instance.new("ScreenGui")
    wrapSg.Name = "HoangTouchWrapper"
    wrapSg.ResetOnSpawn = false
    wrapSg.IgnoreGuiInset = false
    wrapSg.Parent = CoreGui
    local wrapper = Instance.new("TextButton")
    wrapper.Size = UDim2.new(0, 40, 0, 40)
    wrapper.Position = UDim2.new(0, x - 20, 0, y - 20)
    wrapper.BackgroundTransparency = 1
    wrapper.Text = ""
    wrapper.Active = true
    wrapper.Selectable = true
    wrapper.AutoButtonColor = false
    wrapper.ZIndex = 999992
    wrapper.Parent = wrapSg
    task.wait(0.1)
    local function cleanup()
        task.wait(0.15)
        pcall(function() wrapSg:Destroy() end)
    end
    if firetouchinterest then
        log(string.format("  firetouchinterest (%.1f, %.1f)", x, y))
        pcall(function()
            firetouchinterest(wrapper, Vector2.new(x, y), 0)
            task.wait(0.15)
            firetouchinterest(wrapper, Vector2.new(x, y), 1)
        end)
        task.wait(0.3)
        if not isPopupOpen() then cleanup(); return true, "touch" end
    end
    if typeof(firesignal) == "function" then
        pcall(function()
            firesignal(wrapper.MouseButton1Down)
            task.wait(0.05)
            firesignal(wrapper.MouseButton1Up)
            task.wait(0.05)
            firesignal(wrapper.MouseButton1Click)
        end)
        task.wait(0.3)
        if not isPopupOpen() then cleanup(); return true, "firesignal" end
    end
    pcall(function() wrapper:Activate() end)
    task.wait(0.3)
    if not isPopupOpen() then cleanup(); return true, "activate" end
    cleanup()
    return false, "fail"
end

-- ============================================================
-- STATE
-- ============================================================
local savedX = nil
local savedY = nil
local autoEnabled = false
local dragFrame = nil

-- ============================================================
-- UI
-- ============================================================
local function buildUI()
    local oldUI = CoreGui:FindFirstChild("HoangAutoTradeUI")
    if oldUI then oldUI:Destroy() end
    local oldDrag = CoreGui:FindFirstChild("HoangDragTarget")
    if oldDrag then oldDrag:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "HoangAutoTradeUI"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 340, 0, 340)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = sg

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 32)
    titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    titleBar.BorderSizePixel = 0
    titleBar.Active = true
    titleBar.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -70, 1, 0)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Auto Trade v75 (Simple)"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    local closeUI = Instance.new("TextButton")
    closeUI.Size = UDim2.new(0, 26, 0, 26)
    closeUI.Position = UDim2.new(1, -30, 0, 3)
    closeUI.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeUI.BorderSizePixel = 0
    closeUI.Text = "X"
    closeUI.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeUI.Font = Enum.Font.GothamBold
    closeUI.TextSize = 12
    closeUI.Parent = titleBar

    local draggingUI, dragStartUI, startPosUI = false, nil, nil
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            draggingUI = true
            dragStartUI = input.Position
            startPosUI = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    draggingUI = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingUI and (input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartUI
            frame.Position = UDim2.new(
                startPosUI.X.Scale, startPosUI.X.Offset + delta.X,
                startPosUI.Y.Scale, startPosUI.Y.Offset + delta.Y
            )
        end
    end)

    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, 0, 1, -36)
    body.Position = UDim2.new(0, 0, 0, 36)
    body.BackgroundTransparency = 1
    body.Parent = frame

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(0.9, 0, 0, 30)
    statusLbl.Position = UDim2.new(0.05, 0, 0, 0)
    statusLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    statusLbl.BorderSizePixel = 0
    statusLbl.Text = "Kéo vòng tròn đỏ tới nút Accept, bấm LƯU."
    statusLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 11
    statusLbl.TextWrapped = true
    statusLbl.Parent = body

    local infoLbl = Instance.new("TextLabel")
    infoLbl.Size = UDim2.new(0.9, 0, 0, 30)
    infoLbl.Position = UDim2.new(0.05, 0, 0, 34)
    infoLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    infoLbl.BorderSizePixel = 0
    infoLbl.Text = "Chưa lưu"
    infoLbl.TextColor3 = Color3.fromRGB(180, 220, 255)
    infoLbl.Font = Enum.Font.Code
    infoLbl.TextSize = 11
    infoLbl.Parent = body

    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.9, 0, 0, 32)
    saveBtn.Position = UDim2.new(0.05, 0, 0, 68)
    saveBtn.BackgroundColor3 = Color3.fromRGB(200, 130, 40)
    saveBtn.BorderSizePixel = 0
    saveBtn.Text = "1) LƯU VỊ TRÍ"
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 12
    saveBtn.Parent = body

    local testBtn = Instance.new("TextButton")
    testBtn.Size = UDim2.new(0.9, 0, 0, 32)
    testBtn.Position = UDim2.new(0.05, 0, 0, 104)
    testBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
    testBtn.BorderSizePixel = 0
    testBtn.Text = "2) TEST BẤM"
    testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testBtn.Font = Enum.Font.GothamBold
    testBtn.TextSize = 12
    testBtn.Parent = body

    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0.9, 0, 0, 32)
    autoBtn.Position = UDim2.new(0.05, 0, 0, 140)
    autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    autoBtn.BorderSizePixel = 0
    autoBtn.Text = "3) AUTO ACCEPT: OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 12
    autoBtn.Parent = body

    local helpLbl = Instance.new("TextLabel")
    helpLbl.Size = UDim2.new(0.9, 0, 0, 80)
    helpLbl.Position = UDim2.new(0.05, 0, 0, 176)
    helpLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    helpLbl.BorderSizePixel = 0
    helpLbl.Text = [[
QUY TRÌNH (đơn giản):
1. Nhờ acc phụ mời trade.
2. Kéo vòng tròn đỏ tới đúng nút Accept.
3. LƯU -> TEST -> nếu popup đóng thì bật AUTO.
4. Nếu popup không đóng, kéo vòng tròn sang trái/phải
   ít một, lưu lại, test lại.

Không có offset, không visual phức tạp.
]]
    helpLbl.TextColor3 = Color3.fromRGB(200, 220, 200)
    helpLbl.Font = Enum.Font.Gotham
    helpLbl.TextSize = 10
    helpLbl.TextWrapped = true
    helpLbl.TextYAlignment = Enum.TextYAlignment.Top
    helpLbl.Parent = body

    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.9, 0, 0, 60)
    logLbl.Position = UDim2.new(0.05, 0, 0, 262)
    logLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    logLbl.BorderSizePixel = 0
    logLbl.Text = "Log:"
    logLbl.TextColor3 = Color3.fromRGB(180, 220, 180)
    logLbl.Font = Enum.Font.Gotham
    logLbl.TextSize = 10
    logLbl.TextWrapped = true
    logLbl.TextYAlignment = Enum.TextYAlignment.Top
    logLbl.Parent = body

    local function setStatus(s, c)
        statusLbl.Text = s
        if c then statusLbl.TextColor3 = c end
    end
    local function appendLog(s)
        local cur = logLbl.Text
        if #cur > 280 then cur = cur:sub(-200) end
        logLbl.Text = cur .. "\n" .. s
    end

    closeUI.MouseButton1Click:Connect(function() sg:Destroy() end)

    -- ============================================================
    -- DRAG TARGET (vòng tròn đỏ)
    -- ============================================================
    local dragSg = Instance.new("ScreenGui")
    dragSg.Name = "HoangDragTarget"
    dragSg.ResetOnSpawn = false
    dragSg.IgnoreGuiInset = false
    dragSg.Parent = CoreGui

    local dragFrame = Instance.new("Frame")
    dragFrame.Size = UDim2.new(0, 60, 0, 60)
    dragFrame.Position = UDim2.new(0.5, -30, 0.5, -30)
    dragFrame.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    dragFrame.BackgroundTransparency = 0.15
    dragFrame.BorderSizePixel = 0
    dragFrame.Active = true
    dragFrame.ZIndex = 999990
    dragFrame.Parent = dragSg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)  -- TRÒN HOÀN HẢO
    corner.Parent = dragFrame

    local centerDot = Instance.new("Frame")
    centerDot.Size = UDim2.new(0, 6, 0, 6)
    centerDot.Position = UDim2.new(0.5, -3, 0.5, -3)
    centerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
    centerDot.BorderSizePixel = 0
    centerDot.ZIndex = 999991
    centerDot.Parent = dragFrame

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = centerDot

    local isDragging = false
    local dragStart = nil
    local startPos = nil
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStart = input.Position
            startPos = dragFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            dragFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    local function refreshInfo()
        local ap = dragFrame.AbsolutePosition
        local as = dragFrame.AbsoluteSize
        local sx = ap.X + as.X / 2
        local sy = ap.Y + as.Y / 2
        local tl = getInset()
        local vx = sx - tl.X
        local vy = sy - tl.Y
        infoLbl.Text = string.format(
            "Screen (%.0f, %.0f) | View (%.0f, %.0f)",
            sx, sy, vx, vy)
        return sx, sy, vx, vy
    end

    task.spawn(function()
        while sg.Parent do
            refreshInfo()
            task.wait(0.1)
        end
    end)

    -- ============================================================
    -- EVENTS
    -- ============================================================
    saveBtn.MouseButton1Click:Connect(function()
        local _, _, vx, vy = refreshInfo()
        savedX = vx
        savedY = vy
        log(string.format("Lưu viewport (%.1f, %.1f)", vx, vy))
        setStatus(string.format("Đã lưu (%.0f, %.0f)", vx, vy),
            Color3.fromRGB(120, 220, 120))
        appendLog(string.format("Lưu (%.0f,%.0f)", vx, vy))
    end)

    testBtn.MouseButton1Click:Connect(function()
        if not savedX then appendLog("Chưa lưu"); return end
        task.spawn(function()
            appendLog(string.format("Test (%.0f,%.0f)", savedX, savedY))
            local ok, r = touchViaWrapper(savedX, savedY)
            if ok then
                appendLog("✔ OK: " .. r)
                setStatus("✔ Test OK - bật AUTO", Color3.fromRGB(120, 220, 120))
            else
                appendLog("✘ Fail - kéo vòng tròn chỉnh, lưu lại")
                setStatus("✘ Fail - chỉnh vị trí", Color3.fromRGB(255, 120, 120))
            end
        end)
    end)

    autoBtn.MouseButton1Click:Connect(function()
        if not savedX then appendLog("Chưa lưu"); return end
        autoEnabled = not autoEnabled
        if autoEnabled then
            autoBtn.Text = "3) AUTO ACCEPT: ON"
            autoBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            appendLog("Auto ON")
            setStatus("Auto ON", Color3.fromRGB(120, 220, 120))
        else
            autoBtn.Text = "3) AUTO ACCEPT: OFF"
            autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
            appendLog("Auto OFF")
            setStatus("Auto OFF", Color3.fromRGB(200, 200, 120))
        end
    end)

    task.spawn(function()
        local wasOpen = false
        while sg.Parent do
            if autoEnabled and savedX then
                local nowOpen = isPopupOpen()
                if nowOpen and not wasOpen then
                    appendLog("Auto: popup hiện")
                    task.wait(0.2)
                    local ok, r = touchViaWrapper(savedX, savedY)
                    appendLog(ok and ("✔ Auto: " .. r) or "✘ Auto fail")
                end
                wasOpen = nowOpen
            end
            task.wait(0.3)
        end
    end)
end

if game.PlaceId ~= CONFIG.GameID then
    warn("[AutoTrade] PlaceId không khớp:", game.PlaceId)
end

buildUI()
log("v75 sẵn sàng. Vòng tròn đỏ = điểm bấm. Kéo tới đâu bấm tới đó.")
