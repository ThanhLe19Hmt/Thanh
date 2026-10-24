--[[
    Auto Trade - Rock Fruit v70 (Custom Touch Object)
    Game ID: 119091355492870

    CHẨN ĐOÁN CUỐI CÙNG:
      - Bạn kéo ô đen đúng vị trí.
      - Tool lưu toạ độ đúng (screen hoặc viewport).
      - Nhưng vẫn bấm lệch -> dù thử screen hay viewport.
      - NGUYÊN NHÂN: `firetouchinterest(btn, pos, ...)` trên
        executor mobile có thể:
        1. Bỏ qua `pos` và dùng tâm của `btn`.
        2. Chỉ nhận touch khi `pos` nằm trong `btn.AbsoluteSize`.
        3. Hoặc `pos` bị hiểu là toạ độ tương đối so với btn.

    GIẢI PHÁP v70:
      - KHÔNG dùng `firetouchinterest(Accept, pos)` nữa.
      - Tạo 1 TextButton VÔ HÌNH có:
        + Kích thước 40x40
        + Vị trí: đặt sao cho TÂM = toạ độ ô đen
          (tức là Position = (targetX - 20, targetY - 20))
        + BackgroundTransparency = 1
        + Active = true, Selectable = true
      - Sau đó `firetouchinterest(wrapper, center, 0)` +
        `firetouchinterest(wrapper, center, 1)`.
      - Vì tâm wrapper = vị trí bạn muốn bấm, nếu executor
        bỏ qua `pos` thì nó vẫn dùng tâm wrapper -> đúng vị trí.
      - Một số game/executor còn kích hoạt GuiButton khi touch
        vào nó -> wrapper được click -> không làm gì (trong suốt)
        -> nhưng touch event vẫn fire vào vị trí đó -> game
        nhận click tại toạ độ đó (nếu game xử lý UIS InputBegan).

    BONUS:
      - Nếu wrapper không ăn, thử thêm:
        + firesignal(wrapper.MouseButton1Click)
        + Activate wrapper
      - Không dùng `firesignal(Accept.MouseButton1Down)` vì
        firesignal không truyền toạ độ.
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

-- ============================================================
-- ĐỐI TƯỢNG GAME
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

local function isPopupOpen()
    local tr = getTradeRequestFrame()
    return tr ~= nil and tr.Visible == true
end

-- ============================================================
-- BẤM QUA WRAPPER TEXTBUTTON TẠI ĐÚNG TOẠ ĐỘ
-- ============================================================
local function touchViaWrapper(x, y)
    -- Tạo wrapper tại đúng toạ độ (tâm wrapper = (x,y))
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

    -- Cho GUI kịp render
    task.wait(0.1)

    local function cleanup()
        pcall(function() wrapSg:Destroy() end)
    end

    -- Cách 1: firetouchinterest tâm wrapper
    if firetouchinterest then
        local center = Vector2.new(x, y)
        log(string.format("  firetouchinterest wrapper @ (%.1f, %.1f)", x, y))
        pcall(function()
            firetouchinterest(wrapper, center, 0)
            task.wait(0.15)
            firetouchinterest(wrapper, center, 1)
        end)
        task.wait(0.3)
        if not isPopupOpen() then cleanup(); return true, "touch_wrapper" end
    end

    -- Cách 2: firesignal trên wrapper
    if typeof(firesignal) == "function" then
        log("  firesignal wrapper")
        pcall(function()
            firesignal(wrapper.MouseButton1Down)
            task.wait(0.05)
            firesignal(wrapper.MouseButton1Up)
            task.wait(0.05)
            firesignal(wrapper.MouseButton1Click)
        end)
        task.wait(0.3)
        if not isPopupOpen() then cleanup(); return true, "firesignal_wrapper" end
    end

    -- Cách 3: Activate wrapper
    pcall(function() wrapper:Activate() end)
    task.wait(0.3)
    if not isPopupOpen() then cleanup(); return true, "activate_wrapper" end

    cleanup()
    return false, "wrapper_fail"
end

-- ============================================================
-- BẤM QUA VIRTUAL INPUT MANAGER TẠI (x,y)
-- ============================================================
local function touchViaVIM(x, y)
    if not VirtualInputManager then return false, "no_vim" end
    log(string.format("  VIM @ (%.1f, %.1f)", x, y))
    local ix, iy = math.floor(x), math.floor(y)
    pcall(function()
        VirtualInputManager:SendMouseMoveEvent(ix, iy, game)
    end)
    task.wait(0.25)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(ix, iy, 0, true, game, 0)
    end)
    task.wait(0.15)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(ix, iy, 0, false, game, 0)
    end)
    task.wait(0.35)
    if not isPopupOpen() then return true, "vim" end
    return false, "vim_fail"
end

-- ============================================================
-- THỬ TẤT CẢ CÁCH
-- ============================================================
local function tryClickAt(x, y)
    local ok, r
    ok, r = touchViaWrapper(x, y)
    if ok then return true, r end
    task.wait(0.1)
    ok, r = touchViaVIM(x, y)
    if ok then return true, r end
    return false, "all_fail"
end

-- ============================================================
-- STATE
-- ============================================================
local savedX = nil
local savedY = nil
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
    frame.Size = UDim2.new(0, 380, 0, 420)
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
    title.Text = "Auto Trade v70 (Wrapper Touch)"
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
    statusLbl.Text = "Kéo ô đen tới nút Accept, bấm LƯU."
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
    infoLbl.Text = "Screen: ?\nViewport: ?"
    infoLbl.TextColor3 = Color3.fromRGB(180, 220, 255)
    infoLbl.Font = Enum.Font.Code
    infoLbl.TextSize = 11
    infoLbl.TextWrapped = true
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left
    infoLbl.TextYAlignment = Enum.TextYAlignment.Top
    infoLbl.Parent = body

    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.95, 0, 0, 32)
    saveBtn.Position = UDim2.new(0.025, 0, 0, 86)
    saveBtn.BackgroundColor3 = Color3.fromRGB(200, 130, 40)
    saveBtn.BorderSizePixel = 0
    saveBtn.Text = "1) LƯU VỊ TRÍ ô đen"
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 12
    saveBtn.Parent = body

    local testBtn = Instance.new("TextButton")
    testBtn.Size = UDim2.new(0.95, 0, 0, 32)
    testBtn.Position = UDim2.new(0.025, 0, 0, 124)
    testBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
    testBtn.BorderSizePixel = 0
    testBtn.Text = "2) TEST bấm tại vị trí đã lưu"
    testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testBtn.Font = Enum.Font.GothamBold
    testBtn.TextSize = 12
    testBtn.Parent = body

    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0.95, 0, 0, 32)
    autoBtn.Position = UDim2.new(0.025, 0, 0, 162)
    autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    autoBtn.BorderSizePixel = 0
    autoBtn.Text = "3) AUTO ACCEPT: OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 12
    autoBtn.Parent = body

    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(0.95, 0, 0, 24)
    resetBtn.Position = UDim2.new(0.025, 0, 0, 200)
    resetBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    resetBtn.BorderSizePixel = 0
    resetBtn.Text = "Reset ô đen về giữa"
    resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.TextSize = 11
    resetBtn.Parent = body

    local helpLbl = Instance.new("TextLabel")
    helpLbl.Size = UDim2.new(0.95, 0, 0, 100)
    helpLbl.Position = UDim2.new(0.025, 0, 0, 230)
    helpLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    helpLbl.BorderSizePixel = 0
    helpLbl.Text = [[
FIX v70:
firetouchinterest(btn, pos) có thể bị executor bỏ qua pos
và dùng TÂM btn -> lệch.

v70 tạo TextButton vô hình tại đúng toạ độ ô đen,
rồi firetouchinterest vào TextButton đó.
=> Tâm TextButton = vị trí bạn muốn -> đúng.

Quy trình:
1. Kéo ô đen vào nút Accept.
2. LƯU VỊ TRÍ.
3. TEST -> nếu fail, kéo ô đen chỉnh vài px, lưu lại.
4. AUTO khi đã đúng.
]]
    helpLbl.TextColor3 = Color3.fromRGB(200, 220, 200)
    helpLbl.Font = Enum.Font.Gotham
    helpLbl.TextSize = 10
    helpLbl.TextWrapped = true
    helpLbl.TextYAlignment = Enum.TextYAlignment.Top
    helpLbl.Parent = body

    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.95, 0, 0, 60)
    logLbl.Position = UDim2.new(0.025, 0, 0, 336)
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
        if #cur > 300 then cur = cur:sub(-240) end
        logLbl.Text = cur .. "\n" .. s
    end

    closeUI.MouseButton1Click:Connect(function() sg:Destroy() end)

    -- ============================================================
    -- DRAG TARGET
    -- ============================================================
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

    -- Cập nhật info
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
        -- Lưu viewport vì firetouchinterest dùng viewport
        savedX = vx
        savedY = vy
        log(string.format("Lưu: Screen (%.0f,%.0f) Viewport (%.0f,%.0f)", sx, sy, vx, vy))
        setStatus(string.format("Đã lưu VP (%.0f, %.0f). Test thử.", vx, vy),
            Color3.fromRGB(120, 220, 120))
        appendLog(string.format("Lưu VP (%.0f,%.0f)", vx, vy))
    end)

    testBtn.MouseButton1Click:Connect(function()
        if not savedX then appendLog("Chưa lưu"); return end
        task.spawn(function()
            appendLog(string.format("Test tại (%.0f,%.0f)", savedX, savedY))
            local ok, r = tryClickAt(savedX, savedY)
            if ok then
                appendLog("✔ OK: " .. r)
                setStatus("✔ Test OK: " .. r, Color3.fromRGB(120, 220, 120))
            else
                appendLog("✘ Fail: " .. r)
                setStatus("✘ Fail - kéo ô đen chỉnh rồi lưu lại", Color3.fromRGB(255, 120, 120))
            end
        end)
    end)

    autoBtn.MouseButton1Click:Connect(function()
        if not savedX then appendLog("Chưa lưu"); return end
        autoEnabled = not autoEnabled
        if autoEnabled then
            autoBtn.Text = "3) AUTO ACCEPT: ON"
            autoBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            setStatus("Auto ON", Color3.fromRGB(120, 220, 120))
            appendLog("Auto ON")
        else
            autoBtn.Text = "3) AUTO ACCEPT: OFF"
            autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
            setStatus("Auto OFF", Color3.fromRGB(200, 200, 120))
            appendLog("Auto OFF")
        end
    end)

    resetBtn.MouseButton1Click:Connect(function()
        dragFrame.Position = UDim2.new(0.5, -30, 0.5, -30)
    end)

    -- Auto loop
    task.spawn(function()
        local wasOpen = false
        while sg.Parent do
            if autoEnabled and savedX then
                local nowOpen = isPopupOpen()
                if nowOpen and not wasOpen then
                    appendLog("Auto: popup hiện")
                    task.wait(0.2)
                    local ok, r = tryClickAt(savedX, savedY)
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
log("v70 sẵn sàng. Wrapper TextButton tại đúng toạ độ.")
