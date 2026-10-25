--[[
    Auto Trade - Rock Fruit v81 (Final Lock + Wrapper Fix)
    Game ID: 119091355492870

    TÌNH HÌNH:
      - Chấm đỏ đã vào đúng nút Accept nhờ scan Y.
      - PC: offsetY = +50. Mobile: offsetY = +60.
      - NHƯNG bấm không ăn (popup không đóng).

    TẠI SAO:
      - Wrapper TextButton tạo ra nhưng firetouchinterest không
        kích hoạt được logic của nút Accept thật (vì nút Accept
        có thể yêu cầu touch trực tiếp từ game, không phải wrapper).

    GIẢI PHÁP v81:
      1. Lưu Y offset đã tìm được (PC: 50, Mobile: 60).
      2. Thay vì wrapper, dùng 3 cách bấm trực tiếp:
         a. firetouchinterest(AcceptButton, pos) - bấm vào nút thật.
         b. VirtualInputManager tại (X, Y).
         c. Gọi hàm callback của nút Accept qua getconnections.
      3. Có nút "TEST" để thử cả 3 cách.
      4. Khi tìm được cách ăn -> lưu để auto dùng.

    BẠN CẦN:
      - Nhập Y offset đúng (50 hoặc 60).
      - Bấm TEST để tool thử 3 cách.
      - Gửi log F9 - tôi cần thấy cách nào ăn.
]]

local CONFIG = {
    GameID = 119091355492870,
    Debug  = true,
    PCOffsetY = 50,
    MobileOffsetY = 60,
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

-- Phát hiện platform
local isTouch = UserInputService.TouchEnabled
local isMouse = UserInputService.MouseEnabled
local isKeyboard = UserInputService.KeyboardEnabled
local IS_MOBILE = (isTouch and not isKeyboard and not isMouse)
local IS_PC = (isMouse and isKeyboard and not isTouch)
local PLATFORM = IS_MOBILE and "MOBILE" or (IS_PC and "PC" or "UNKNOWN")
local DEFAULT_OFFSET_Y = IS_PC and CONFIG.PCOffsetY or CONFIG.MobileOffsetY

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
-- CÁCH 1: FIRE TOUCH INTEREST VÀO NÚT THẬT
-- ============================================================
local function method1_directTouch(x, y)
    local btn = getAcceptButton()
    if not btn or not firetouchinterest then return false, "no_btn_or_api" end
    log(string.format("[1] firetouchinterest(Accept, %.1f, %.1f)", x, y))
    pcall(function()
        firetouchinterest(btn, Vector2.new(x, y), 0)
        task.wait(0.1)
        firetouchinterest(btn, Vector2.new(x, y), 1)
    end)
    task.wait(0.3)
    if not isPopupOpen() then return true, "direct_touch" end
    return false, "fail"
end

-- ============================================================
-- CÁCH 2: VIRTUAL INPUT MANAGER
-- ============================================================
local function method2_vim(x, y)
    if not VirtualInputManager then return false, "no_vim" end
    log(string.format("[2] VIM(%.1f, %.1f)", x, y))
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
    return false, "fail"
end

-- ============================================================
-- CÁCH 3: GỌI CALLBACK CỦA NÚT ACCEPT QUA getconnections
-- ============================================================
local function method3_callback(x, y)
    local btn = getAcceptButton()
    if not btn or not getconnections then return false, "no_getconnections" end
    log("[3] Gọi callback MouseButton1Click của Accept")
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
                        log(string.format("  %s #%d - gọi", sigName, i))
                        pcall(c.Function)
                        task.wait(0.05)
                    end
                end
            end
        end
    end
    task.wait(0.3)
    if not isPopupOpen() then return true, "callback" end
    return false, "fail"
end

-- ============================================================
-- CÁCH 4: FIRESIGNAL TRÊN NÚT ACCEPT
-- ============================================================
local function method4_firesignal(x, y)
    local btn = getAcceptButton()
    if not btn or typeof(firesignal) ~= "function" then return false, "no_firesignal" end
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
    return false, "fail"
end

-- ============================================================
-- WRAPPER (giữ từ v70 - đã từng ăn)
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
        log(string.format("[5] wrapper touch (%.1f, %.1f)", x, y))
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
    return false, "fail"
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
        if ok then
            hideVisual()
            return true, m[1]
        end
        task.wait(0.1)
    end
    hideVisual()
    return false, "all_fail"
end

-- ============================================================
-- STATE
-- ============================================================
local offsetY = DEFAULT_OFFSET_Y
local autoEnabled = false
local savedX = nil
local savedY = nil

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
    frame.Size = UDim2.new(0, 360, 0, 400)
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
    title.Text = "v81 (" .. PLATFORM .. ") offsetY=" .. offsetY
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
    statusLbl.Text = "Y offset = " .. offsetY .. " (đã tìm được)"
    statusLbl.TextColor3 = Color3.fromRGB(120, 220, 120)
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 11
    statusLbl.TextWrapped = true
    statusLbl.Parent = body

    local offsetLabel = Instance.new("TextLabel")
    offsetLabel.Size = UDim2.new(0.3, 0, 0, 26)
    offsetLabel.Position = UDim2.new(0.05, 0, 0, 36)
    offsetLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    offsetLabel.BorderSizePixel = 0
    offsetLabel.Text = "OffsetY"
    offsetLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    offsetLabel.Font = Enum.Font.Gotham
    offsetLabel.TextSize = 11
    offsetLabel.Parent = body

    local offsetBox = Instance.new("TextBox")
    offsetBox.Size = UDim2.new(0.2, 0, 0, 26)
    offsetBox.Position = UDim2.new(0.38, 0, 0, 36)
    offsetBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    offsetBox.BorderSizePixel = 0
    offsetBox.Text = tostring(offsetY)
    offsetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    offsetBox.Font = Enum.Font.Gotham
    offsetBox.TextSize = 12
    offsetBox.Parent = body

    local applyBtn = Instance.new("TextButton")
    applyBtn.Size = UDim2.new(0.35, 0, 0, 26)
    applyBtn.Position = UDim2.new(0.6, 0, 0, 36)
    applyBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    applyBtn.BorderSizePixel = 0
    applyBtn.Text = "Áp dụng"
    applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyBtn.Font = Enum.Font.GothamBold
    applyBtn.TextSize = 11
    applyBtn.Parent = body

    local testBtn = Instance.new("TextButton")
    testBtn.Size = UDim2.new(0.9, 0, 0, 40)
    testBtn.Position = UDim2.new(0.05, 0, 0, 70)
    testBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
    testBtn.BorderSizePixel = 0
    testBtn.Text = "1) TEST 5 CÁCH BẤM"
    testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testBtn.Font = Enum.Font.GothamBold
    testBtn.TextSize = 13
    testBtn.Parent = body

    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0.9, 0, 0, 36)
    autoBtn.Position = UDim2.new(0.05, 0, 0, 116)
    autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    autoBtn.BorderSizePixel = 0
    autoBtn.Text = "2) AUTO ACCEPT: OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 12
    autoBtn.Parent = body

    local helpLbl = Instance.new("TextLabel")
    helpLbl.Size = UDim2.new(0.9, 0, 0, 120)
    helpLbl.Position = UDim2.new(0.05, 0, 0, 160)
    helpLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    helpLbl.BorderSizePixel = 0
    helpLbl.Text = [[
Đã tìm ra Y offset: PC=50, Mobile=60.
Chấm đỏ khớp nút Accept. Bấm vẫn fail.

Bấm "TEST 5 CÁCH":
1. Direct firetouchinterest(Accept, pos)
2. VIM (move + click)
3. Gọi callback của Accept qua getconnections
4. firesignal Accept
5. wrapper TextButton

Log F9 sẽ in cách nào ăn.

Nếu tất cả fail -> executor sandbox touch.
Chỉ còn app Auto Clicker ngoài.
]]
    helpLbl.TextColor3 = Color3.fromRGB(200, 220, 200)
    helpLbl.Font = Enum.Font.Gotham
    helpLbl.TextSize = 10
    helpLbl.TextWrapped = true
    helpLbl.TextYAlignment = Enum.TextYAlignment.Top
    helpLbl.Parent = body

    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.9, 0, 0, 40)
    logLbl.Position = UDim2.new(0.05, 0, 0, 290)
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
        if #cur > 320 then cur = cur:sub(-240) end
        logLbl.Text = cur .. "\n" .. s
    end

    closeUI.MouseButton1Click:Connect(function() sg:Destroy() end)

    applyBtn.MouseButton1Click:Connect(function()
        local val = tonumber(offsetBox.Text)
        if val then
            offsetY = val
            title.Text = "v81 (" .. PLATFORM .. ") offsetY=" .. offsetY
            setStatus("Y offset = " .. offsetY, Color3.fromRGB(120, 220, 120))
            appendLog("OffsetY = " .. offsetY)
        end
    end)

    testBtn.MouseButton1Click:Connect(function()
        local btn = getAcceptButton()
        if not btn then
            appendLog("Không có popup")
            return
        end
        local ap = btn.AbsolutePosition
        local sz = btn.AbsoluteSize
        local cx = ap.X + sz.X / 2
        local cy = ap.Y + sz.Y / 2 + offsetY
        savedX = cx
        savedY = cy
        task.spawn(function()
            setStatus(string.format("Test tại (%.0f, %.0f)...", cx, cy),
                Color3.fromRGB(200, 200, 120))
            appendLog(string.format("Test (%.0f, %.0f)", cx, cy))
            local ok, r = tryAll(cx, cy)
            if ok then
                appendLog("✔ OK: " .. r)
                setStatus("✔ OK: " .. r, Color3.fromRGB(120, 220, 120))
            else
                appendLog("✘ ALL FAIL")
                setStatus("✘ Tất cả 5 cách fail", Color3.fromRGB(255, 120, 120))
            end
        end)
    end)

    autoBtn.MouseButton1Click:Connect(function()
        autoEnabled = not autoEnabled
        if autoEnabled then
            autoBtn.Text = "2) AUTO ACCEPT: ON"
            autoBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            appendLog("AUTO ON")
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
                        local cx = ap.X + sz.X / 2
                        local cy = ap.Y + sz.Y / 2 + offsetY
                        showVisual(cx, cy)
                        task.wait(0.2)
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
log("v81 sẵn sàng. Y offset PC=50, Mobile=60. TEST 5 CÁCH.")
