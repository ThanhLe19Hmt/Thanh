--[[
    Auto Trade - Rock Fruit v71 (Offset Compensate)
    Game ID: 119091355492870

    TRẠNG THÁI:
      - firetouchinterest(wrapper) đã hoạt động (popup đóng).
      - Nhưng có SAI SỐ CỐ ĐỊNH: bạn kéo ô đen vào nút Accept
        thì tool bấm lệch một chút. Phải kéo ô đen lệch sang
        PHẢI và XUỐNG thì mới trúng.

    NGUYÊN NHÂN:
      - Wrapper TextButton được đặt tại (x-20, y-20) với size
        40x40 -> tâm wrapper = (x, y) -> đúng lý thuyết.
      - Nhưng executor mobile có thể cộng thêm offset ẩn khi
        firetouchinterest (ví dụ +insetX, +insetY).
      - Hoặc SafeArea trên mobile (status bar, notch) làm
        wrapper.Position bị dịch so với toạ độ tuyệt đối.

    FIX v71:
      1. Thêm 2 ô nhập "Offset X" và "Offset Y".
      2. Khi bấm, tool dùng (savedX + offsetX, savedY + offsetY).
      3. Bạn tinh chỉnh Offset X (dương = sang phải, âm = sang
         trái), Offset Y (dương = xuống, âm = lên) cho đến khi
         bấm đúng.
      4. Lưu offset -> auto dùng offset đó mỗi lần.
      5. Không cần kéo ô đen lệch nữa -> kéo đúng vị trí hiển
         thị, dùng offset để bù sai số.

    CÁCH DÙNG:
      1. Kéo ô đen đúng vào tâm nút Accept (chấm đỏ = tâm).
      2. Bấm "LƯU VỊ TRÍ".
      3. Nhập Offset X = 5, Offset Y = 5 (gợi ý ban đầu).
      4. Bấm "TEST" -> nếu chưa đúng, tăng/giảm offset.
      5. Khi đúng -> bấm "AUTO" -> tool dùng offset đã lưu.
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

local function isPopupOpen()
    local tr = getTradeRequestFrame()
    return tr ~= nil and tr.Visible == true
end

-- ============================================================
-- BẤM QUA WRAPPER TẠI TOẠ ĐỘ (x, y)
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
        pcall(function() wrapSg:Destroy() end)
    end

    if firetouchinterest then
        log(string.format("  firetouchinterest wrapper @ (%.1f, %.1f)", x, y))
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
local baseX = nil
local baseY = nil
local offsetX = 0
local offsetY = 0
local autoEnabled = false

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
    frame.Size = UDim2.new(0, 380, 0, 480)
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
    title.Text = "Auto Trade v71 (Offset Compensate)"
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
    statusLbl.Size = UDim2.new(0.95, 0, 0, 32)
    statusLbl.Position = UDim2.new(0.025, 0, 0, 0)
    statusLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    statusLbl.BorderSizePixel = 0
    statusLbl.Text = "Kéo ô đen đúng vị trí, lưu, tinh chỉnh offset."
    statusLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 11
    statusLbl.TextWrapped = true
    statusLbl.Parent = body

    local infoLbl = Instance.new("TextLabel")
    infoLbl.Size = UDim2.new(0.95, 0, 0, 46)
    infoLbl.Position = UDim2.new(0.025, 0, 0, 36)
    infoLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    infoLbl.BorderSizePixel = 0
    infoLbl.Text = "Chưa lưu vị trí."
    infoLbl.TextColor3 = Color3.fromRGB(180, 220, 255)
    infoLbl.Font = Enum.Font.Code
    infoLbl.TextSize = 11
    infoLbl.TextWrapped = true
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left
    infoLbl.TextYAlignment = Enum.TextYAlignment.Top
    infoLbl.Parent = body

    -- Offset input
    local offsetXLabel = Instance.new("TextLabel")
    offsetXLabel.Size = UDim2.new(0.3, 0, 0, 26)
    offsetXLabel.Position = UDim2.new(0.025, 0, 0, 86)
    offsetXLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    offsetXLabel.BorderSizePixel = 0
    offsetXLabel.Text = "Offset X"
    offsetXLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    offsetXLabel.Font = Enum.Font.Gotham
    offsetXLabel.TextSize = 11
    offsetXLabel.Parent = body

    local offsetXBox = Instance.new("TextBox")
    offsetXBox.Size = UDim2.new(0.15, 0, 0, 26)
    offsetXBox.Position = UDim2.new(0.34, 0, 0, 86)
    offsetXBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    offsetXBox.BorderSizePixel = 0
    offsetXBox.Text = "0"
    offsetXBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    offsetXBox.Font = Enum.Font.Gotham
    offsetXBox.TextSize = 12
    offsetXBox.Parent = body

    local offsetYLabel = Instance.new("TextLabel")
    offsetYLabel.Size = UDim2.new(0.3, 0, 0, 26)
    offsetYLabel.Position = UDim2.new(0.51, 0, 0, 86)
    offsetYLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    offsetYLabel.BorderSizePixel = 0
    offsetYLabel.Text = "Offset Y"
    offsetYLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    offsetYLabel.Font = Enum.Font.Gotham
    offsetYLabel.TextSize = 11
    offsetYLabel.Parent = body

    local offsetYBox = Instance.new("TextBox")
    offsetYBox.Size = UDim2.new(0.15, 0, 0, 26)
    offsetYBox.Position = UDim2.new(0.825, 0, 0, 86)
    offsetYBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    offsetYBox.BorderSizePixel = 0
    offsetYBox.Text = "0"
    offsetYBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    offsetYBox.Font = Enum.Font.Gotham
    offsetYBox.TextSize = 12
    offsetYBox.Parent = body

    local applyOffsetBtn = Instance.new("TextButton")
    applyOffsetBtn.Size = UDim2.new(0.95, 0, 0, 26)
    applyOffsetBtn.Position = UDim2.new(0.025, 0, 0, 116)
    applyOffsetBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    applyOffsetBtn.BorderSizePixel = 0
    applyOffsetBtn.Text = "Áp dụng offset (lưu)"
    applyOffsetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyOffsetBtn.Font = Enum.Font.GothamBold
    applyOffsetBtn.TextSize = 11
    applyOffsetBtn.Parent = body

    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.95, 0, 0, 32)
    saveBtn.Position = UDim2.new(0.025, 0, 0, 148)
    saveBtn.BackgroundColor3 = Color3.fromRGB(200, 130, 40)
    saveBtn.BorderSizePixel = 0
    saveBtn.Text = "1) LƯU VỊ TRÍ ô đen (chưa offset)"
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 12
    saveBtn.Parent = body

    local testBtn = Instance.new("TextButton")
    testBtn.Size = UDim2.new(0.95, 0, 0, 32)
    testBtn.Position = UDim2.new(0.025, 0, 0, 186)
    testBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
    testBtn.BorderSizePixel = 0
    testBtn.Text = "2) TEST (dùng offset hiện tại)"
    testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testBtn.Font = Enum.Font.GothamBold
    testBtn.TextSize = 12
    testBtn.Parent = body

    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0.95, 0, 0, 32)
    autoBtn.Position = UDim2.new(0.025, 0, 0, 224)
    autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    autoBtn.BorderSizePixel = 0
    autoBtn.Text = "3) AUTO ACCEPT: OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 12
    autoBtn.Parent = body

    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(0.95, 0, 0, 24)
    resetBtn.Position = UDim2.new(0.025, 0, 0, 262)
    resetBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    resetBtn.BorderSizePixel = 0
    resetBtn.Text = "Reset ô đen về giữa"
    resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.TextSize = 11
    resetBtn.Parent = body

    local helpLbl = Instance.new("TextLabel")
    helpLbl.Size = UDim2.new(0.95, 0, 0, 120)
    helpLbl.Position = UDim2.new(0.025, 0, 0, 290)
    helpLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    helpLbl.BorderSizePixel = 0
    helpLbl.Text = [[
QUY TRÌNH:
1. Kéo ô đen ĐÚNG tâm nút Accept (chấm đỏ = tâm).
2. LƯU VỊ TRÍ.
3. Nhập Offset X, Y nếu bấm lệch:
   - Lệch phải -> Offset X tăng (5, 10...)
   - Lệch trái -> Offset X giảm (-5, -10...)
   - Lệch xuống -> Offset Y tăng (5, 10...)
   - Lệch lên -> Offset Y giảm (-5, -10...)
4. Bấm "Áp dụng offset (lưu)".
5. Bấm TEST.
6. Nếu chưa đúng -> đổi offset, lưu, test lại.
7. Khi đúng -> bấm AUTO.

MẸO: lệch khoảng bao nhiêu thì nhập bấy nhiêu.
Ví dụ lệch sang phải ~10px, xuống ~5px -> X=10, Y=5.
]]
    helpLbl.TextColor3 = Color3.fromRGB(200, 220, 200)
    helpLbl.Font = Enum.Font.Gotham
    helpLbl.TextSize = 10
    helpLbl.TextWrapped = true
    helpLbl.TextYAlignment = Enum.TextYAlignment.Top
    helpLbl.Parent = body

    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.95, 0, 0, 44)
    logLbl.Position = UDim2.new(0.025, 0, 0, 420)
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
        if #cur > 260 then cur = cur:sub(-200) end
        logLbl.Text = cur .. "\n" .. s
    end

    closeUI.MouseButton1Click:Connect(function() sg:Destroy() end)

    -- Drag target
    local dragSg = Instance.new("ScreenGui")
    dragSg.Name = "HoangDragTarget"
    dragSg.ResetOnSpawn = false
    dragSg.IgnoreGuiInset = false
    dragSg.Parent = CoreGui

    local dragFrame = Instance.new("Frame")
    dragFrame.Size = UDim2.new(0, 60, 0, 60)
    dragFrame.Position = UDim2.new(0.5, -30, 0.5, -30)
    dragFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dragFrame.BackgroundTransparency = 0.2
    dragFrame.BorderSizePixel = 3
    dragFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    dragFrame.Active = true
    dragFrame.ZIndex = 999990
    dragFrame.Parent = dragSg

    local centerDot = Instance.new("Frame")
    centerDot.Size = UDim2.new(0, 8, 0, 8)
    centerDot.Position = UDim2.new(0.5, -4, 0.5, -4)
    centerDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    centerDot.BorderSizePixel = 0
    centerDot.ZIndex = 999991
    centerDot.Parent = dragFrame

    local dragLabel = Instance.new("TextLabel")
    dragLabel.Size = UDim2.new(1, 0, 0, 14)
    dragLabel.Position = UDim2.new(0, 0, 1, 2)
    dragLabel.BackgroundTransparency = 1
    dragLabel.Text = "KÉO"
    dragLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    dragLabel.Font = Enum.Font.GothamBold
    dragLabel.TextSize = 10
    dragLabel.Parent = dragFrame

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

    -- Refresh info
    local function refreshInfo()
        local ap = dragFrame.AbsolutePosition
        local as = dragFrame.AbsoluteSize
        local sx = ap.X + as.X / 2
        local sy = ap.Y + as.Y / 2
        local tl = getInset()
        local vx = sx - tl.X
        local vy = sy - tl.Y
        infoLbl.Text = string.format(
            "Screen: (%.1f, %.1f)\nViewport: (%.1f, %.1f)",
            sx, sy, vx, vy)
        return sx, sy, vx, vy
    end

    task.spawn(function()
        while sg.Parent do
            refreshInfo()
            task.wait(0.15)
        end
    end)

    -- Events
    saveBtn.MouseButton1Click:Connect(function()
        local sx, sy, vx, vy = refreshInfo()
        baseX = vx
        baseY = vy
        appendLog(string.format("Lưu base VP (%.0f,%.0f)", vx, vy))
        setStatus(string.format("Đã lưu. Nhập offset, áp dụng, test."),
            Color3.fromRGB(120, 220, 120))
    end)

    applyOffsetBtn.MouseButton1Click:Connect(function()
        offsetX = tonumber(offsetXBox.Text) or 0
        offsetY = tonumber(offsetYBox.Text) or 0
        appendLog(string.format("Offset lưu: X=%d Y=%d", offsetX, offsetY))
        setStatus(string.format("Offset: X=%d Y=%d", offsetX, offsetY),
            Color3.fromRGB(120, 220, 120))
    end)

    testBtn.MouseButton1Click:Connect(function()
        if not baseX then appendLog("Chưa lưu"); return end
        task.spawn(function()
            local tx = baseX + offsetX
            local ty = baseY + offsetY
            appendLog(string.format("Test (%.0f,%.0f) offset(%d,%d)", tx, ty, offsetX, offsetY))
            local ok, r = touchViaWrapper(tx, ty)
            if ok then
                appendLog("✔ OK: " .. r)
                setStatus("✔ Test OK - bật AUTO", Color3.fromRGB(120, 220, 120))
            else
                appendLog("✘ Fail - tăng offset")
                setStatus("✘ Fail - tinh chỉnh offset X/Y", Color3.fromRGB(255, 120, 120))
            end
        end)
    end)

    autoBtn.MouseButton1Click:Connect(function()
        if not baseX then appendLog("Chưa lưu"); return end
        autoEnabled = not autoEnabled
        if autoEnabled then
            autoBtn.Text = "3) AUTO ACCEPT: ON"
            autoBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            appendLog(string.format("Auto ON offset(%d,%d)", offsetX, offsetY))
            setStatus("Auto ON", Color3.fromRGB(120, 220, 120))
        else
            autoBtn.Text = "3) AUTO ACCEPT: OFF"
            autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
            appendLog("Auto OFF")
            setStatus("Auto OFF", Color3.fromRGB(200, 200, 120))
        end
    end)

    resetBtn.MouseButton1Click:Connect(function()
        dragFrame.Position = UDim2.new(0.5, -30, 0.5, -30)
    end)

    task.spawn(function()
        local wasOpen = false
        while sg.Parent do
            if autoEnabled and baseX then
                local nowOpen = isPopupOpen()
                if nowOpen and not wasOpen then
                    appendLog("Auto: popup hiện")
                    task.wait(0.2)
                    local tx = baseX + offsetX
                    local ty = baseY + offsetY
                    local ok, r = touchViaWrapper(tx, ty)
                    appendLog(ok and ("✔ Auto OK: " .. r) or "✘ Auto fail")
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
log("v71 sẵn sàng. Nhập offset X/Y để bù sai số.")
