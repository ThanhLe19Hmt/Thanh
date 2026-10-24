--[[
    Auto Trade - Rock Fruit v67 (Manual Calibrate)
    Game ID: 119091355492870

    VẤN ĐỀ TỪ v66:
      - Vùng đỏ hiển thị sai vị trí.
      - Không biết offsetX, offsetY chính xác.
      - Không có nút test từng vị trí để tìm.

    GIẢI PHÁP v67:
      1. Hiển thị nút Accept thật (màu xanh lá) để bạn thấy nó đâu.
      2. Vẽ 1 Frame đỏ (vùng touch) - bạn có thể điều chỉnh.
      3. Thêm 4 nút mũi tên (Trái/Phải/Lên/Xuống) + nút bước nhảy (1px, 5px, 10px).
      4. Khi di chuyển, toạ độ hiển thị rõ.
      5. Nút "TEST TOẠ ĐỘ NÀY" để firetouchinterest vào vị trí hiện tại.
      6. Nếu popup đóng -> "LƯU TOẠ ĐỘ" -> auto dùng từ giờ.
]]

local CONFIG = {
    GameID          = 119091355492870,
    Debug           = true,
    SafeMarginTop   = 50,
    SafeMarginRight = 50,
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

-- ============================================================
-- INSET
-- ============================================================
local function getInset()
    local tl = Vector2.new(0, 0)
    pcall(function() tl = GuiService.TopLeftInset end)
    return tl
end

-- ============================================================
-- ĐỐI TƯỢNG
-- ============================================================
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

local function getCenter(btn)
    if not btn then return nil end
    local ap = btn.AbsolutePosition
    local sz = btn.AbsoluteSize
    return Vector2.new(ap.X + sz.X / 2, ap.Y + sz.Y / 2)
end

local function isPopupOpen()
    local tr = getTradeRequestFrame()
    return tr ~= nil and tr.Visible == true
end

-- ============================================================
-- BIẾN OFFSET - SẼ CHỈNH TAY
-- ============================================================
local offsetX = 0
local offsetY = 0
local currentPos = Vector2.new(0, 0)  -- toạ độ viewport sau điều chỉnh

-- ============================================================
-- VISUAL (CURSOR + TOUCH MARKER)
-- ============================================================
local cursorGui = nil
local cursorFrame = nil
local touchMarker = nil
local acceptMarker = nil

local function ensureCursorGui()
    if cursorGui and cursorGui.Parent then return end
    cursorGui = Instance.new("ScreenGui")
    cursorGui.Name = "HoangVirtualMouse"
    cursorGui.ResetOnSpawn = false
    cursorGui.IgnoreGuiInset = false
    cursorGui.Parent = CoreGui

    -- Frame đỏ = touch area
    cursorFrame = Instance.new("Frame")
    cursorFrame.Size = UDim2.new(0, 30, 0, 30)
    cursorFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    cursorFrame.BackgroundTransparency = 0.6
    cursorFrame.BorderSizePixel = 2
    cursorFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    cursorFrame.ZIndex = 999999
    cursorFrame.Visible = false
    cursorFrame.Parent = cursorGui

    -- Chấm trắng ở giữa = điểm chính xác
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(0.5, -3, 0.5, -3)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel = 0
    dot.ZIndex = 1000000
    dot.Parent = cursorFrame

    -- Touch marker xanh lá = firetouchinterest point
    touchMarker = Instance.new("Frame")
    touchMarker.Size = UDim2.new(0, 10, 0, 10)
    touchMarker.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    touchMarker.BorderSizePixel = 0
    touchMarker.ZIndex = 999998
    touchMarker.Visible = false
    touchMarker.Parent = cursorGui

    -- Accept marker vàng = tâm nút Accept thật
    acceptMarker = Instance.new("Frame")
    acceptMarker.Size = UDim2.new(0, 14, 0, 14)
    acceptMarker.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
    acceptMarker.BackgroundTransparency = 0.3
    acceptMarker.BorderSizePixel = 2
    acceptMarker.BorderColor3 = Color3.fromRGB(255, 255, 0)
    acceptMarker.ZIndex = 999997
    acceptMarker.Visible = false
    acceptMarker.Parent = cursorGui
end

local function updateVisuals()
    ensureCursorGui()
    local btn = getAcceptButton()
    if not btn then
        cursorFrame.Visible = false
        touchMarker.Visible = false
        acceptMarker.Visible = false
        return
    end
    local c = getCenter(btn)
    if not c then return end
    
    -- Accept center thật
    acceptMarker.Position = UDim2.new(0, c.X - 7, 0, c.Y - 7)
    acceptMarker.Visible = true

    -- Vị trí touch hiện tại (viewport + offset)
    currentPos = Vector2.new(c.X + offsetX, c.Y + offsetY)
    cursorFrame.Position = UDim2.new(0, currentPos.X - 15, 0, currentPos.Y - 15)
    cursorFrame.Visible = true
    touchMarker.Position = UDim2.new(0, currentPos.X - 5, 0, currentPos.Y - 5)
    touchMarker.Visible = true
end

local function hideVisuals()
    if cursorFrame then cursorFrame.Visible = false end
    if touchMarker then touchMarker.Visible = false end
    if acceptMarker then acceptMarker.Visible = false end
end

-- ============================================================
-- TEST TOUCH TẠI VỊ TRÍ HIỆN TẠI
-- ============================================================
local function testTouchAtCurrentPos()
    local btn = getAcceptButton()
    if not btn then return false, "no_popup" end
    if not firetouchinterest then return false, "no_firetouch" end
    local pos = currentPos
    log(string.format("Test firetouchinterest tại (%.0f, %.0f)", pos.X, pos.Y))
    pcall(function()
        firetouchinterest(btn, pos, 0)
        task.wait(0.15)
        firetouchinterest(btn, pos, 1)
    end)
    task.wait(0.35)
    if not isPopupOpen() then
        return true, "touch_success"
    end
    -- Thử VIM
    if VirtualInputManager then
        log(string.format("Test VirtualInputManager tại (%.0f, %.0f)", pos.X, pos.Y))
        pcall(function()
            VirtualInputManager:SendMouseMoveEvent(math.floor(pos.X), math.floor(pos.Y), game)
        end)
        task.wait(0.2)
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(math.floor(pos.X), math.floor(pos.Y), 0, true, game, 0)
        end)
        task.wait(0.15)
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(math.floor(pos.X), math.floor(pos.Y), 0, false, game, 0)
        end)
        task.wait(0.35)
        if not isPopupOpen() then
            return true, "vim_success"
        end
    end
    return false, "fail"
end

-- ============================================================
-- UI
-- ============================================================
local function buildUI()
    local old = CoreGui:FindFirstChild("HoangAutoTradeUI")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "HoangAutoTradeUI"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 480, 0, 560)
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
    title.Text = "Accept Tester v67 (Manual Calibrate)"
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

    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, 0, 1, -36)
    body.Position = UDim2.new(0, 0, 0, 36)
    body.BackgroundTransparency = 1
    body.Parent = frame

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(0.95, 0, 0, 22)
    statusLbl.Position = UDim2.new(0.025, 0, 0, 0)
    statusLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    statusLbl.BorderSizePixel = 0
    statusLbl.Text = "Offset: X=0 Y=0 | chưa có popup"
    statusLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 11
    statusLbl.Parent = body

    local infoLbl = Instance.new("TextLabel")
    infoLbl.Size = UDim2.new(0.95, 0, 0, 60)
    infoLbl.Position = UDim2.new(0.025, 0, 0, 26)
    infoLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    infoLbl.BorderSizePixel = 0
    infoLbl.Text = "Accept center: ?\nTouch pos: ?"
    infoLbl.TextColor3 = Color3.fromRGB(180, 220, 255)
    infoLbl.Font = Enum.Font.Code
    infoLbl.TextSize = 11
    infoLbl.TextWrapped = true
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left
    infoLbl.TextYAlignment = Enum.TextYAlignment.Top
    infoLbl.Parent = body

    -- Điều chỉnh step
    local stepLabel = Instance.new("TextLabel")
    stepLabel.Size = UDim2.new(0.3, 0, 0, 20)
    stepLabel.Position = UDim2.new(0.025, 0, 0, 92)
    stepLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    stepLabel.BorderSizePixel = 0
    stepLabel.Text = "Bước (px)"
    stepLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    stepLabel.Font = Enum.Font.Gotham
    stepLabel.TextSize = 11
    stepLabel.Parent = body

    local stepBox = Instance.new("TextBox")
    stepBox.Size = UDim2.new(0.2, 0, 0, 20)
    stepBox.Position = UDim2.new(0.35, 0, 0, 92)
    stepBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    stepBox.BorderSizePixel = 0
    stepBox.Text = "5"
    stepBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    stepBox.Font = Enum.Font.Gotham
    stepBox.TextSize = 11
    stepBox.Parent = body

    -- Nút mũi tên
    local function makeArrowBtn(text, x, y, dx, dy)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.15, 0, 0, 40)
        b.Position = UDim2.new(x, 0, 0, y)
        b.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
        b.BorderSizePixel = 0
        b.Text = text
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 18
        b.Parent = body
        b.MouseButton1Click:Connect(function()
            local step = tonumber(stepBox.Text) or 5
            offsetX = offsetX + dx * step
            offsetY = offsetY + dy * step
            updateVisuals()
            local btn = getAcceptButton()
            if btn then
                local c = getCenter(btn)
                infoLbl.Text = string.format(
                    "Accept center: (%.0f, %.0f)\nTouch pos: (%.0f, %.0f)\noffsetX=%d offsetY=%d",
                    c.X, c.Y, c.X + offsetX, c.Y + offsetY, offsetX, offsetY)
            end
            statusLbl.Text = string.format("Offset: X=%d Y=%d", offsetX, offsetY)
        end)
        return b
    end

    makeArrowBtn("↑", 0.025, 116, 0, -1)
    makeArrowBtn("↓", 0.025, 200, 0, 1)
    makeArrowBtn("←", 0.20, 158, -1, 0)
    makeArrowBtn("→", 0.65, 158, 1, 0)

    -- Nút reset về tâm
    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(0.4, 0, 0, 26)
    resetBtn.Position = UDim2.new(0.025, 0, 0, 246)
    resetBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    resetBtn.BorderSizePixel = 0
    resetBtn.Text = "Reset về tâm Accept"
    resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.TextSize = 11
    resetBtn.Parent = body
    resetBtn.MouseButton1Click:Connect(function()
        offsetX = 0
        offsetY = 0
        updateVisuals()
        statusLbl.Text = "Offset: X=0 Y=0"
    end)

    -- Nút test
    local testBtn = Instance.new("TextButton")
    testBtn.Size = UDim2.new(0.5, 0, 0, 30)
    testBtn.Position = UDim2.new(0.025, 0, 0, 280)
    testBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
    testBtn.BorderSizePixel = 0
    testBtn.Text = "TEST TOẠ ĐỘ NÀY"
    testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testBtn.Font = Enum.Font.GothamBold
    testBtn.TextSize = 12
    testBtn.Parent = body

    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.4, 0, 0, 30)
    saveBtn.Position = UDim2.new(0.55, 0, 0, 280)
    saveBtn.BackgroundColor3 = Color3.fromRGB(200, 130, 40)
    saveBtn.BorderSizePixel = 0
    saveBtn.Text = "LƯU + AUTO"
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 11
    saveBtn.Parent = body

    local helpLbl = Instance.new("TextLabel")
    helpLbl.Size = UDim2.new(0.95, 0, 0, 100)
    helpLbl.Position = UDim2.new(0.025, 0, 0, 316)
    helpLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    helpLbl.BorderSizePixel = 0
    helpLbl.Text = [[
QUY TRÌNH:
1. Nhờ acc phụ mời trade -> popup hiện.
2. Bạn sẽ thấy trên màn hình:
   - Ô vuông vàng = tâm nút Accept thật.
   - Ô vuông đỏ + chấm trắng = vị trí touch sẽ bấm.
   - Chấm xanh lá = điểm firetouchinterest chạm.
3. Dùng 4 nút mũi tên để di chuyển ô đỏ tới khớp ô vàng.
4. Bấm "TEST TOẠ ĐỘ NÀY" để thử.
5. Nếu popup đóng -> bấm "LƯU + AUTO" -> auto dùng từ giờ.
6. Nếu chưa đúng -> bấm nút mũi tên chỉnh thêm, test lại.

Bước mặc định = 5px. Đặt 1px để chỉnh tinh.
]]
    helpLbl.TextColor3 = Color3.fromRGB(200, 220, 200)
    helpLbl.Font = Enum.Font.Gotham
    helpLbl.TextSize = 10
    helpLbl.TextWrapped = true
    helpLbl.TextYAlignment = Enum.TextYAlignment.Top
    helpLbl.Parent = body

    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.95, 0, 0, 80)
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

    local function appendLog(s)
        local cur = logLbl.Text
        if #cur > 600 then cur = cur:Sub(-400) end
        logLbl.Text = cur .. "\n" .. s
    end

    closeUI.MouseButton1Click:Connect(function() sg:Destroy() end)

    local autoEnabled = false
    local savedOffsetX = 0
    local savedOffsetY = 0

    testBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            local ok, r = testTouchAtCurrentPos()
            if ok then
                appendLog("✔ Test OK: " .. r)
                statusLbl.Text = "✔ Test OK: " .. r
                statusLbl.TextColor3 = Color3.fromRGB(120, 220, 120)
            else
                appendLog("✘ Test fail: " .. tostring(r))
                statusLbl.Text = "✘ Test fail"
                statusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
            end
        end)
    end)

    saveBtn.MouseButton1Click:Connect(function()
        savedOffsetX = offsetX
        savedOffsetY = offsetY
        autoEnabled = true
        appendLog(string.format("Đã lưu offsetX=%d offsetY=%d, bật auto", savedOffsetX, savedOffsetY))
        statusLbl.Text = string.format("AUTO ON: offset X=%d Y=%d", savedOffsetX, savedOffsetY)
        statusLbl.TextColor3 = Color3.fromRGB(120, 220, 120)
    end)

    -- Loop update visuals khi có popup
    task.spawn(function()
        while sg.Parent do
            local tr = getTradeRequestFrame()
            local open = tr ~= nil and tr.Visible == true
            if open then
                updateVisuals()
                local btn = getAcceptButton()
                if btn then
                    local c = getCenter(btn)
                    infoLbl.Text = string.format(
                        "Accept center: (%.0f, %.0f)\nTouch pos: (%.0f, %.0f)\noffsetX=%d offsetY=%d",
                        c.X, c.Y, c.X + offsetX, c.Y + offsetY, offsetX, offsetY)
                end
            else
                hideVisuals()
            end
            task.wait(0.15)
        end
    end)

    -- Auto loop
    task.spawn(function()
        local wasOpen = false
        while sg.Parent do
            if autoEnabled then
                local tr = getTradeRequestFrame()
                local nowOpen = tr ~= nil and tr.Visible == true
                if nowOpen and not wasOpen then
                    appendLog("Auto: popup hiện, click với offset đã lưu")
                    local btn = getAcceptButton()
                    if btn then
                        local c = getCenter(btn)
                        local pos = Vector2.new(c.X + savedOffsetX, c.Y + savedOffsetY)
                        log(string.format("Auto click tại (%.0f, %.0f)", pos.X, pos.Y))
                        if firetouchinterest then
                            pcall(function()
                                firetouchinterest(btn, pos, 0)
                                task.wait(0.15)
                                firetouchinterest(btn, pos, 1)
                            end)
                            task.wait(0.35)
                            if not isPopupOpen() then
                                appendLog("✔ Auto touch OK")
                            else
                                -- fallback VIM
                                if VirtualInputManager then
                                    pcall(function()
                                        VirtualInputManager:SendMouseMoveEvent(math.floor(pos.X), math.floor(pos.Y), game)
                                    end)
                                    task.wait(0.2)
                                    pcall(function()
                                        VirtualInputManager:SendMouseButtonEvent(math.floor(pos.X), math.floor(pos.Y), 0, true, game, 0)
                                    end)
                                    task.wait(0.15)
                                    pcall(function()
                                        VirtualInputManager:SendMouseButtonEvent(math.floor(pos.X), math.floor(pos.Y), 0, false, game, 0)
                                    end)
                                    task.wait(0.35)
                                    if not isPopupOpen() then
                                        appendLog("✔ Auto VIM OK")
                                    else
                                        appendLog("✘ Auto fail")
                                    end
                                end
                            end
                        end
                    end
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
log("v67 sẵn sàng. Dùng 4 nút mũi tên để căn vị trí touch.")
