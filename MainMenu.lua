--[[
    Auto Trade - Rock Fruit v82 (Mobile Visual Fix)
    Game ID: 119091355492870

    TÌNH HÌNH:
      - PC: Đã chạy mượt (bấm đúng).
      - Mobile: Chấm đỏ hiển thị đúng vị trí, nhưng khi bấm
        thì lại lệch sang TRÁI của chấm đỏ -> bấm hụt.

    PHÂN TÍCH:
      - Chấm đỏ visual dùng `IgnoreGuiInset = true` (toạ độ screen).
      - Wrapper/touch dùng `IgnoreGuiInset = false` (toạ độ viewport).
      - Trên mobile, inset X (trái) khác 0 (do status bar, notch,
        hoặc nav bar) -> wrapper bị lùi về bên trái so với visual.
      - Đó là lý do bạn thấy điểm bấm lệch sang trái.

    CÁCH FIX:
      1. Thêm ô "Offset X" cho Mobile.
      2. Khi bạn thấy bấm lệch sang trái -> nhập Offset X dương.
      3. Khi bạn thấy bấm lệch sang phải -> nhập Offset X âm.
      4. Cộng Offset X vào X của wrapper + VIM.
      5. Visual cũng cộng Offset X để khớp (bạn thấy chấm đỏ
         di chuyển theo).
      6. Tự động lưu Offset X.

    LÝ DO PHẢI DÙNG OFFSET X:
      - Không có cách tự động (executor mobile khác nhau).
      - Chỉ có thể tinh chỉnh tay 1 lần.
      - Lần sau auto dùng offset đã lưu.

    CÁCH DÙNG:
      1. Nhập OffsetY (đã biết: PC=50, Mobile=60).
      2. Nhập OffsetX = 0 ban đầu.
      3. Bấm TEST 5 CÁCH.
      4. Nếu bấm lệch sang trái -> tăng OffsetX (1, 2, 3, 4, 5...).
      5. Nếu bấm lệch sang phải -> giảm OffsetX (-1, -2, ...).
      6. Mỗi lần đổi -> bấm TEST lại.
      7. Khi popup đóng -> bấm AUTO ON.
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

local isTouch = UserInputService.TouchEnabled
local isMouse = UserInputService.MouseEnabled
local isKeyboard = UserInputService.KeyboardEnabled
local IS_MOBILE = (isTouch and not isKeyboard and not isMouse)
local IS_PC = (isMouse and isKeyboard and not isTouch)
local PLATFORM = IS_MOBILE and "MOBILE" or (IS_PC and "PC" or "UNKNOWN")
local DEFAULT_OFFSET_Y = IS_PC and 50 or 60
local DEFAULT_OFFSET_X = 0

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
-- VISUAL
-- ============================================================
local visualGui = nil
local visualDot = nil

local function ensureVisual()
    if visualGui and visualGui.Parent then return end
    visualGui = Instance.new("ScreenGui")
    visualGui.Name = "HoangVisualCursor"
    visualGui.ResetOnSpawn = false
    visualGui.IgnoreGuiInset = true
    visualGui.Parent = CoreGui
    visualDot = Instance.new("Frame")
    visualDot.Size = UDim2.new(0, 12, 0, 12)
    visualDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    visualDot.BackgroundTransparency = 0.3
    visualDot.BorderSizePixel = 2
    visualDot.BorderColor3 = Color3.fromRGB(255, 255, 255)
    visualDot.ZIndex = 999995
    visualDot.Visible = false
    visualDot.Parent = visualGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = visualDot
end

local function showVisual(x, y)
    ensureVisual()
    local tl = getInset()
    visualDot.Position = UDim2.new(0, x + tl.X - 6, 0, y + tl.Y - 6)
    visualDot.Visible = true
end

local function hideVisual()
    if visualDot then visualDot.Visible = false end
end

-- ============================================================
-- CÁCH 1: DIRECT TOUCH
-- ============================================================
local function method1_directTouch(x, y)
    local btn = getAcceptButton()
    if not btn or not firetouchinterest then return false end
    log(string.format("[1] direct touch (%.1f, %.1f)", x, y))
    pcall(function()
        firetouchinterest(btn, Vector2.new(x, y), 0)
        task.wait(0.1)
        firetouchinterest(btn, Vector2.new(x, y), 1)
    end)
    task.wait(0.3)
    if not isPopupOpen() then return true, "direct_touch" end
    return false
end

-- ============================================================
-- CÁCH 2: VIM
-- ============================================================
local function method2_vim(x, y)
    if not VirtualInputManager then return false end
    log(string.format("[2] VIM (%.1f, %.1f)", x, y))
    local ix, iy = math.floor(x), math.floor(y)
    pcall(function()
        VirtualInputManager:SendMouseMoveEvent(ix, iy, game)
    end)
    task.wait(0.2)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(ix, iy, 0, true, game, 0)
    end)
    task.wait(0.15)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(ix, iy, 0, false, game, 0)
    end)
    task.wait(0.3)
    if not isPopupOpen() then return true, "vim" end
    return false
end

-- ============================================================
-- CÁCH 3: CALLBACK
-- ============================================================
local function method3_callback(x, y)
    local btn = getAcceptButton()
    if not btn or not getconnections then return false end
    log("[3] callback Accept")
    local signals = {
        {"MouseButton1Click", btn.MouseButton1Click},
        {"MouseButton1Down", btn.MouseButton1Down},
        {"MouseButton1Up", btn.MouseButton1Up},
        {"Activated", btn.Activated},
    }
    for _, pair in ipairs(signals) do
        local sigName, sig = pair[1], pair[2]
        if sig then
            local ok, conns = pcall(getconnections, sig)
            if ok and conns then
                for i, c in ipairs(conns) do
                    if c.Enabled and c.Function then
                        log(string.format("  %s #%d", sigName, i))
                        pcall(c.Function)
                        task.wait(0.05)
                    end
                end
            end
        end
    end
    task.wait(0.3)
    if not isPopupOpen() then return true, "callback" end
    return false
end

-- ============================================================
-- CÁCH 4: FIRESIGNAL
-- ============================================================
local function method4_firesignal(x, y)
    local btn = getAcceptButton()
    if not btn or typeof(firesignal) ~= "function" then return false end
    log("[4] firesignal Accept")
    pcall(function()
        firesignal(btn.MouseButton1Down)
        task.wait(0.1)
        firesignal(btn.MouseButton1Up)
        task.wait(0.1)
        firesignal(btn.MouseButton1Click)
        task.wait(0.1)
        firesignal(btn.Activated)
    end)
    task.wait(0.3)
    if not isPopupOpen() then return true, "firesignal" end
    return false
end

-- ============================================================
-- CÁCH 5: WRAPPER
-- ============================================================
local function method5_wrapper(x, y)
    local wrapSg = Instance.new("ScreenGui")
    wrapSg.Name = "HoangWrap"
    wrapSg.ResetOnSpawn = false
    wrapSg.IgnoreGuiInset = false
    wrapSg.Parent = CoreGui
    local wrapper = Instance.new("TextButton")
    wrapper.Size = UDim2.new(0, 30, 0, 30)
    wrapper.Position = UDim2.new(0, x - 15, 0, y - 15)
    wrapper.BackgroundTransparency = 1
    wrapper.Text = ""
    wrapper.Active = true
    wrapper.ZIndex = 999992
    wrapper.Parent = wrapSg
    task.wait(0.1)
    local ok = false
    if firetouchinterest then
        log(string.format("[5] wrapper (%.1f, %.1f)", x, y))
        pcall(function()
            firetouchinterest(wrapper, Vector2.new(x, y), 0)
            task.wait(0.1)
            firetouchinterest(wrapper, Vector2.new(x, y), 1)
        end)
        task.wait(0.3)
        ok = not isPopupOpen()
    end
    pcall(function() wrapSg:Destroy() end)
    if ok then return true, "wrapper" end
    return false
end

-- ============================================================
-- THỬ TẤT CẢ
-- ============================================================
local function tryAll(x, y)
    showVisual(x, y)
    task.wait(0.15)
    local methods = {
        {"direct_touch", method1_directTouch},
        {"vim", method2_vim},
        {"callback", method3_callback},
        {"firesignal", method4_firesignal},
        {"wrapper", method5_wrapper},
    }
    for _, m in ipairs(methods) do
        if not isPopupOpen() then hideVisual(); return true, "already_closed" end
        local ok, r = m[2](x, y)
        if ok then hideVisual(); return true, m[1] end
        task.wait(0.1)
    end
    hideVisual()
    return false, "all_fail"
end

-- ============================================================
-- STATE
-- ============================================================
local offsetX = DEFAULT_OFFSET_X
local offsetY = DEFAULT_OFFSET_Y
local autoEnabled = false

-- ============================================================
-- UI
-- ============================================================
local function buildUI()
    local oldUI = CoreGui:FindFirstChild("HoangAutoTradeUI")
    if oldUI then oldUI:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "HoangAutoTradeUI"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 360, 0, 460)
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
    title.Text = "v82 (" .. PLATFORM .. ") X=" .. offsetX .. " Y=" .. offsetY
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
    statusLbl.Text = "Mobile: bấm lệch sang trái -> tăng OffsetX"
    statusLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 11
    statusLbl.TextWrapped = true
    statusLbl.Parent = body

    -- Offset X
    local oxLabel = Instance.new("TextLabel")
    oxLabel.Size = UDim2.new(0.2, 0, 0, 26)
    oxLabel.Position = UDim2.new(0.05, 0, 0, 36)
    oxLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    oxLabel.BorderSizePixel = 0
    oxLabel.Text = "X"
    oxLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    oxLabel.Font = Enum.Font.GothamBold
    oxLabel.TextSize = 13
    oxLabel.Parent = body

    local oxBox = Instance.new("TextBox")
    oxBox.Size = UDim2.new(0, 0, 0, 0)
    -- Sẽ set sau
    oxBox.Size = UDim2.new(0.2, 0, 0, 26)
    oxBox.Position = UDim2.new(0.26, 0, 0, 36)
    oxBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    oxBox.BorderSizePixel = 0
    oxBox.Text = tostring(offsetX)
    oxBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    oxBox.Font = Enum.Font.Gotham
    oxBox.TextSize = 12
    oxBox.Parent = body

    -- Offset Y
    local oyLabel = Instance.new("TextLabel")
    oyLabel.Size = UDim2.new(0.2, 0, 0, 26)
    oyLabel.Position = UDim2.new(0.5, 0, 0, 36)
    oyLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    oyLabel.BorderSizePixel = 0
    oyLabel.Text = "Y"
    oyLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    oyLabel.Font = Enum.Font.GothamBold
    oyLabel.TextSize = 13
    oyLabel.Parent = body

    local oyBox = Instance.new("TextBox")
    oyBox.Size = UDim2.new(0.2, 0, 0, 26)
    oyBox.Position = UDim2.new(0.71, 0, 0, 36)
    oyBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    oyBox.BorderSizePixel = 0
    oyBox.Text = tostring(offsetY)
    oyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    oyBox.Font = Enum.Font.Gotham
    oyBox.TextSize = 12
    oyBox.Parent = body

    -- Nút áp dụng
    local applyBtn = Instance.new("TextButton")
    applyBtn.Size = UDim2.new(0.9, 0, 0, 26)
    applyBtn.Position = UDim2.new(0.05, 0, 0, 68)
    applyBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    applyBtn.BorderSizePixel = 0
    applyBtn.Text = "Áp dụng Offset X, Y"
    applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyBtn.Font = Enum.Font.GothamBold
    applyBtn.TextSize = 11
    applyBtn.Parent = body

    -- Nút + X
    local xPlus1 = Instance.new("TextButton")
    xPlus1.Size = UDim2.new(0.15, 0, 0, 24)
    xPlus1.Position = UDim2.new(0.05, 0, 0, 100)
    xPlus1.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    xPlus1.BorderSizePixel = 0
    xPlus1.Text = "X+1"
    xPlus1.TextColor3 = Color3.fromRGB(255, 255, 255)
    xPlus1.Font = Enum.Font.GothamBold
    xPlus1.TextSize = 11
    xPlus1.Parent = body

    local xMinus1 = Instance.new("TextButton")
    xMinus1.Size = UDim2.new(0.15, 0, 0, 24)
    xMinus1.Position = UDim2.new(0.22, 0, 0, 100)
    xMinus1.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    xMinus1.BorderSizePixel = 0
    xMinus1.Text = "X-1"
    xMinus1.TextColor3 = Color3.fromRGB(255, 255, 255)
    xMinus1.Font = Enum.Font.GothamBold
    xMinus1.TextSize = 11
    xMinus1.Parent = body

    local xPlus5 = Instance.new("TextButton")
    xPlus5.Size = UDim2.new(0.15, 0, 0, 24)
    xPlus5.Position = UDim2.new(0.42, 0, 0, 100)
    xPlus5.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    xPlus5.BorderSizePixel = 0
    xPlus5.Text = "X+5"
    xPlus5.TextColor3 = Color3.fromRGB(255, 255, 255)
    xPlus5.Font = Enum.Font.GothamBold
    xPlus5.TextSize = 11
    xPlus5.Parent = body

    local xMinus5 = Instance.new("TextButton")
    xMinus5.Size = UDim2.new(0.15, 0, 0, 24)
    xMinus5.Position = UDim2.new(0.62, 0, 0, 100)
    xMinus5.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    xMinus5.BorderSizePixel = 0
    xMinus5.Text = "X-5"
    xMinus5.TextColor3 = Color3.fromRGB(255, 255, 255)
    xMinus5.Font = Enum.Font.GothamBold
    xMinus5.TextSize = 11
    xMinus5.Parent = body

    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(0.15, 0, 0, 24)
    resetBtn.Position = UDim2.new(0.82, 0, 0, 100)
    resetBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    resetBtn.BorderSizePixel = 0
    resetBtn.Text = "Reset"
    resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.TextSize = 11
    resetBtn.Parent = body

    -- Test button
    local testBtn = Instance.new("TextButton")
    testBtn.Size = UDim2.new(0.9, 0, 0, 40)
    testBtn.Position = UDim2.new(0.05, 0, 0, 132)
    testBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
    testBtn.BorderSizePixel = 0
    testBtn.Text = "1) TEST 5 CÁCH BẤM"
    testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testBtn.Font = Enum.Font.GothamBold
    testBtn.TextSize = 13
    testBtn.Parent = body

    -- Auto button
    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0.9, 0, 0, 36)
    autoBtn.Position = UDim2.new(0.05, 0, 0, 178)
    autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    autoBtn.BorderSizePixel = 0
    autoBtn.Text = "2) AUTO ACCEPT: OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 12
    autoBtn.Parent = body

    -- Help
    local helpLbl = Instance.new("TextLabel")
    helpLbl.Size = UDim2.new(0.9, 0, 0, 130)
    helpLbl.Position = UDim2.new(0.05, 0, 0, 220)
    helpLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    helpLbl.BorderSizePixel = 0
    helpLbl.Text = [[
MOBILE - Bấm lệch sang trái:
1. Nhập OffsetY (đã biết: Mobile=60, PC=50).
2. Test -> thấy bấm lệch sang trái của chấm đỏ.
3. Bấm "X+1" hoặc "X+5" để tăng.
4. Áp dụng -> Test lại.
5. Lặp đến khi popup đóng.
6. Khi đóng -> AUTO ON.

Lý do: wrapper dùng viewport (bỏ inset),
visual dùng screen (cộng inset).
Mobile insetX khác PC -> lệch sang trái.

PC đã mượt -> OffsetX=0 là đúng.
Mobile cần OffsetX > 0 (thường 5-20).
]]
    helpLbl.TextColor3 = Color3.fromRGB(200, 220, 200)
    helpLbl.Font = Enum.Font.Gotham
    helpLbl.TextSize = 10
    helpLbl.TextWrapped = true
    helpLbl.TextYAlignment = Enum.TextYAlignment.Top
    helpLbl.Parent = body

    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.9, 0, 0, 50)
    logLbl.Position = UDim2.new(0.05, 0, 0, 354)
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
        if #cur > 400 then cur = cur:sub(-320) end
        logLbl.Text = cur .. "\n" .. s
    end
    local function refreshTitle()
        title.Text = "v82 (" .. PLATFORM .. ") X=" .. offsetX .. " Y=" .. offsetY
    end

    closeUI.MouseButton1Click:Connect(function() sg:Destroy() end)

    applyBtn.MouseButton1Click:Connect(function()
        local nx = tonumber(oxBox.Text)
        local ny = tonumber(oyBox.Text)
        if nx then offsetX = nx end
        if ny then offsetY = ny end
        refreshTitle()
        setStatus(string.format("Đã lưu X=%d Y=%d", offsetX, offsetY),
            Color3.fromRGB(120, 220, 120))
        appendLog(string.format("X=%d Y=%d", offsetX, offsetY))
    end)

    xPlus1.MouseButton1Click:Connect(function()
        offsetX = offsetX + 1
        oxBox.Text = tostring(offsetX)
        refreshTitle()
        appendLog("X+" .. offsetX)
    end)
    xMinus1.MouseButton1Click:Connect(function()
        offsetX = offsetX - 1
        oxBox.Text = tostring(offsetX)
        refreshTitle()
        appendLog("X" .. offsetX)
    end)
    xPlus5.MouseButton1Click:Connect(function()
        offsetX = offsetX + 5
        oxBox.Text = tostring(offsetX)
        refreshTitle()
        appendLog("X+" .. offsetX)
    end)
    xMinus5.MouseButton1Click:Connect(function()
        offsetX = offsetX - 5
        oxBox.Text = tostring(offsetX)
        refreshTitle()
        appendLog("X" .. offsetX)
    end)
    resetBtn.MouseButton1Click:Connect(function()
        offsetX = 0
        oxBox.Text = "0"
        refreshTitle()
        appendLog("Reset X")
    end)

    testBtn.MouseButton1Click:Connect(function()
        local btn = getAcceptButton()
        if not btn then appendLog("Không có popup"); return end
        local ap = btn.AbsolutePosition
        local sz = btn.AbsoluteSize
        local cx = ap.X + sz.X / 2 + offsetX
        local cy = ap.Y + sz.Y / 2 + offsetY
        task.spawn(function()
            setStatus(string.format("Test (%.0f, %.0f)", cx, cy),
                Color3.fromRGB(200, 200, 120))
            appendLog(string.format("Test (%.0f, %.0f) X=%d Y=%d",
                cx, cy, offsetX, offsetY))
            local ok, r = tryAll(cx, cy)
            if ok then
                appendLog("✔ " .. r)
                setStatus("✔ " .. r .. " - AUTO ON", Color3.fromRGB(120, 220, 120))
            else
                appendLog("✘ ALL FAIL")
                setStatus("✘ Fail - tinh chỉnh X", Color3.fromRGB(255, 120, 120))
            end
        end)
    end)

    autoBtn.MouseButton1Click:Connect(function()
        autoEnabled = not autoEnabled
        if autoEnabled then
            autoBtn.Text = "2) AUTO ACCEPT: ON"
            autoBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            appendLog(string.format("AUTO ON X=%d Y=%d", offsetX, offsetY))
            setStatus("AUTO ON", Color3.fromRGB(120, 220, 120))
        else
            autoBtn.Text = "2) AUTO ACCEPT: OFF"
            autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
            appendLog("AUTO OFF")
            setStatus("AUTO OFF", Color3.fromRGB(200, 200, 120))
        end
    end)

    task.spawn(function()
        local wasOpen = false
        while sg.Parent do
            if autoEnabled then
                local nowOpen = isPopupOpen()
                if nowOpen and not wasOpen then
                    local btn = getAcceptButton()
                    if btn then
                        local ap = btn.AbsolutePosition
                        local sz = btn.AbsoluteSize
                        local cx = ap.X + sz.X / 2 + offsetX
                        local cy = ap.Y + sz.Y / 2 + offsetY
                        local ok, r = tryAll(cx, cy)
                        appendLog(ok and ("✔ Auto: " .. r) or "✘ Auto fail")
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
log("v82 sẵn sàng. PC OK. Mobile: dùng X+1/X+5 để tinh chỉnh.")
