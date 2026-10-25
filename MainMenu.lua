--[[
    Auto Trade - Rock Fruit v80 (Vertical Fast Scan)
    Game ID: 119091355492870

    YÊU CẦU TỪ BẠN:
      - Không quét lung tung (grid 3x3).
      - Chỉ quét DỌC: từ trên xuống dưới.
      - Từ từ từng chút một (2px).

    LOGIC:
      - Bắt đầu từ Y = tâm - 20 (phía trên nút).
      - Tăng Y từng 2px: -20, -18, -16, ..., 0, +2, ..., +20.
      - Tổng cộng 21 điểm.
      - Delay 0.04s giữa các điểm -> tổng 21 * 0.14s = ~2.94s.
      - Vẫn kịp trong 3s của popup.
      - Nếu popup timeout giữa chừng, log sẽ báo để tôi biết cần thu hẹp range.

    TẠI SAO 21 ĐIỂM:
      - Bước 2px, range ±20px -> 21 điểm.
      - Đây là mức "từ từ từng chút" bạn muốn.
      - Nếu muốn nhanh hơn: range ±10px -> 11 điểm -> 1.5s.

    CÁCH DÙNG:
      1. Nhờ acc phụ mời trade.
      2. Popup hiện -> bấm "SCAN DỌC".
      3. Chấm đỏ đi từ trên xuống.
      4. Popup đóng -> dừng, lưu Y.
      5. AUTO ON.
]]

local CONFIG = {
    GameID = 119091355492870,
    Debug  = true,
    ScanTopY = -20,   -- bắt đầu từ tâm - 20px
    ScanBotY = 20,    -- kết thúc ở tâm + 20px
    ScanStep = 2,     -- bước 2px
    ClickDelay = 0.04, -- delay giữa các điểm (siêu nhanh)
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
-- VISUAL (chấm đỏ + đường kẻ)
-- ============================================================
local visualGui = nil
local visualDot = nil
local visualLine = nil

local function ensureVisual()
    if visualGui and visualGui.Parent then return end
    visualGui = Instance.new("ScreenGui")
    visualGui.Name = "HoangVisualCursor"
    visualGui.ResetOnSpawn = false
    visualGui.IgnoreGuiInset = true
    visualGui.Parent = CoreGui
    
    -- Đường kẻ vàng ngang (để thấy Y hiện tại)
    visualLine = Instance.new("Frame")
    visualLine.Size = UDim2.new(0, 80, 0, 1)
    visualLine.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
    visualLine.BorderSizePixel = 0
    visualLine.ZIndex = 999993
    visualLine.Visible = false
    visualLine.Parent = visualGui
    
    visualDot = Instance.new("Frame")
    visualDot.Size = UDim2.new(0, 10, 0, 10)
    visualDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    visualDot.BackgroundTransparency = 0.3
    visualDot.BorderSizePixel = 1
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
    local tl = Vector2.new(0, 0)
    pcall(function() tl = GuiService.TopLeftInset end)
    visualDot.Position = UDim2.new(0, x + tl.X - 5, 0, y + tl.Y - 5)
    visualLine.Position = UDim2.new(0, x + tl.X - 40, 0, y + tl.Y)
    visualDot.Visible = true
    visualLine.Visible = true
end

local function hideVisual()
    if visualDot then visualDot.Visible = false end
    if visualLine then visualLine.Visible = false end
end

-- ============================================================
-- CLICK NHANH
-- ============================================================
local function fastClickAt(x, y)
    local wrapSg = Instance.new("ScreenGui")
    wrapSg.Name = "HoangFastWrap"
    wrapSg.ResetOnSpawn = false
    wrapSg.IgnoreGuiInset = false
    wrapSg.Parent = CoreGui
    local wrapper = Instance.new("TextButton")
    wrapper.Size = UDim2.new(0, 20, 0, 20)
    wrapper.Position = UDim2.new(0, x - 10, 0, y - 10)
    wrapper.BackgroundTransparency = 1
    wrapper.Text = ""
    wrapper.Active = true
    wrapper.ZIndex = 999992
    wrapper.Parent = wrapSg
    task.wait(0.02)
    if firetouchinterest then
        pcall(function()
            firetouchinterest(wrapper, Vector2.new(x, y), 0)
            task.wait(0.02)
            firetouchinterest(wrapper, Vector2.new(x, y), 1)
        end)
    end
    task.wait(CONFIG.ClickDelay)
    local closed = not isPopupOpen()
    pcall(function() wrapSg:Destroy() end)
    return closed
end

-- ============================================================
-- QUÉT DỌC (VERTICAL SCAN)
-- ============================================================
local function verticalScan()
    local btn = getAcceptButton()
    if not btn then return false, nil end
    local ap = btn.AbsolutePosition
    local sz = btn.AbsoluteSize
    local centerX = ap.X + sz.X / 2
    local centerY = ap.Y + sz.Y / 2
    
    log(string.format("Nút: X=%.0f Y=%.0f Size=%.0fx%.0f", ap.X, ap.Y, sz.X, sz.Y))
    log(string.format("Tâm: (%.0f, %.0f)", centerX, centerY))
    log(string.format("Quét Y từ %.0f đến %.0f, bước %d, delay %.2fs",
        centerY + CONFIG.ScanTopY, centerY + CONFIG.ScanBotY,
        CONFIG.ScanStep, CONFIG.ClickDelay))
    
    local startTime = os.clock()
    
    -- Quét từ trên xuống dưới
    for offset = CONFIG.ScanTopY, CONFIG.ScanBotY, CONFIG.ScanStep do
        if not isPopupOpen() then
            log("Popup đã đóng trước khi scan xong")
            break
        end
        
        local testY = centerY + offset
        showVisual(centerX, testY)
        task.wait(0.02)
        
        log(string.format("  Y offset %+d: (%.0f, %.0f)", offset, centerX, testY))
        local ok = fastClickAt(centerX, testY)
        if ok then
            hideVisual()
            local elapsed = os.clock() - startTime
            log(string.format("✔ POPUP ĐÓNG tại Y offset %+d -> Y=%.0f (sau %.2fs)",
                offset, testY, elapsed))
            return true, {x = centerX, y = testY, offsetY = offset, elapsed = elapsed}
        end
    end
    
    hideVisual()
    local elapsed = os.clock() - startTime
    log(string.format("✘ Scan xong sau %.2fs, popup vẫn còn hoặc đã đóng trước đó", elapsed))
    return false, {elapsed = elapsed}
end

-- ============================================================
-- STATE
-- ============================================================
local foundX = nil
local foundY = nil
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
    frame.Size = UDim2.new(0, 360, 0, 420)
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
    title.Text = "Accept Tester v80 (Vertical Scan)"
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
    statusLbl.Text = "Quét DỌC từ trên xuống dưới, từ từ."
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
    infoLbl.Text = "Chưa quét."
    infoLbl.TextColor3 = Color3.fromRGB(180, 220, 255)
    infoLbl.Font = Enum.Font.Code
    infoLbl.TextSize = 11
    infoLbl.Parent = body

    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.new(0.9, 0, 0, 44)
    scanBtn.Position = UDim2.new(0.05, 0, 0, 68)
    scanBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
    scanBtn.BorderSizePixel = 0
    scanBtn.Text = "1) QUÉT DỌC (tâm ±20, bước 2px)"
    scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    scanBtn.Font = Enum.Font.GothamBold
    scanBtn.TextSize = 13
    scanBtn.Parent = body

    local scanFastBtn = Instance.new("TextButton")
    scanFastBtn.Size = UDim2.new(0.9, 0, 0, 32)
    scanFastBtn.Position = UDim2.new(0.05, 0, 0, 116)
    scanFastBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    scanFastBtn.BorderSizePixel = 0
    scanFastBtn.Text = "1b) QUÉT DỌC NHANH (tâm ±10, bước 2px)"
    scanFastBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    scanFastBtn.Font = Enum.Font.GothamBold
    scanFastBtn.TextSize = 11
    scanFastBtn.Parent = body

    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0.9, 0, 0, 36)
    autoBtn.Position = UDim2.new(0.05, 0, 0, 152)
    autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    autoBtn.BorderSizePixel = 0
    autoBtn.Text = "2) AUTO ACCEPT: OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 11
    autoBtn.Parent = body

    local helpLbl = Instance.new("TextLabel")
    helpLbl.Size = UDim2.new(0.9, 0, 0, 130)
    helpLbl.Position = UDim2.new(0.05, 0, 0, 196)
    helpLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    helpLbl.BorderSizePixel = 0
    helpLbl.Text = [[
QUY TRÌNH:
1. Nhờ acc phụ mời trade -> popup hiện.
2. NGAY LẬP TỨC bấm "QUÉT DỌC".
3. Chấm đỏ + đường kẻ vàng đi từ:
   - Y = tâm - 20 (phía trên)
   - Xuống dần Y = tâm - 18, -16, ..., 0, ..., +20
   - Mỗi bước 2px, delay 0.04s.
4. Khi popup đóng -> dừng.
5. Nếu ±20 timeout -> thử "QUÉT DỌC NHANH" (±10).
6. Bấm AUTO ON.

TỐC ĐỘ:
- ±20 = 21 điểm * 0.14s ≈ 3s (sát nút).
- ±10 = 11 điểm * 0.14s ≈ 1.5s (an toàn).
]]
    helpLbl.TextColor3 = Color3.fromRGB(200, 220, 200)
    helpLbl.Font = Enum.Font.Gotham
    helpLbl.TextSize = 10
    helpLbl.TextWrapped = true
    helpLbl.TextYAlignment = Enum.TextYAlignment.Top
    helpLbl.Parent = body

    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.9, 0, 0, 34)
    logLbl.Position = UDim2.new(0.05, 0, 0, 330)
    logLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    logLbl.BorderSizePixel = 0
    logLbl.Text = "Log:"
    logLbl.TextColor3 = Color3.fromRGB(180, 220, 180)
    logLbl.Font = Enum.Font.Gotham
    logLbl.TextSize = 10
    logLbl.TextWrapped = true
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

    scanBtn.MouseButton1Click:Connect(function()
        if not isPopupOpen() then
            appendLog("Không có popup. Nhờ mời trước.")
            return
        end
        CONFIG.ScanTopY = -20
        CONFIG.ScanBotY = 20
        CONFIG.ScanStep = 2
        task.spawn(function()
            setStatus("Quét dọc ±20...", Color3.fromRGB(200, 200, 120))
            appendLog("Scan ±20")
            local ok, result = verticalScan()
            if ok then
                foundX = result.x
                foundY = result.y
                infoLbl.Text = string.format("X=%.0f Y=%.0f (Y offset %+d)",
                    result.x, result.y, result.offsetY)
                appendLog(string.format("✔ Y offset %+d -> Y=%.0f",
                    result.offsetY, result.y))
                setStatus(string.format("✔ Tìm được Y offset %+d", result.offsetY),
                    Color3.fromRGB(120, 220, 120))
            else
                appendLog("✘ ±20 fail")
                setStatus("✘ ±20 fail - thử NHANH", Color3.fromRGB(255, 120, 120))
            end
        end)
    end)

    scanFastBtn.MouseButton1Click:Connect(function()
        if not isPopupOpen() then
            appendLog("Không có popup.")
            return
        end
        CONFIG.ScanTopY = -10
        CONFIG.ScanBotY = 10
        CONFIG.ScanStep = 2
        task.spawn(function()
            setStatus("Quét dọc ±10...", Color3.fromRGB(200, 200, 120))
            appendLog("Scan ±10")
            local ok, result = verticalScan()
            if ok then
                foundX = result.x
                foundY = result.y
                infoLbl.Text = string.format("X=%.0f Y=%.0f (Y offset %+d)",
                    result.x, result.y, result.offsetY)
                appendLog(string.format("✔ Y offset %+d -> Y=%.0f",
                    result.offsetY, result.y))
                setStatus(string.format("✔ Tìm được Y offset %+d", result.offsetY),
                    Color3.fromRGB(120, 220, 120))
            else
                appendLog("✘ ±10 fail")
                setStatus("✘ ±10 fail", Color3.fromRGB(255, 120, 120))
            end
        end)
    end)

    autoBtn.MouseButton1Click:Connect(function()
        if not foundX then
            appendLog("Chưa tìm được. Quét trước.")
            return
        end
        autoEnabled = not autoEnabled
        if autoEnabled then
            autoBtn.Text = "2) AUTO ACCEPT: ON"
            autoBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            appendLog(string.format("AUTO ON (%.0f,%.0f)", foundX, foundY))
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
            if autoEnabled and foundX then
                local nowOpen = isPopupOpen()
                if nowOpen and not wasOpen then
                    appendLog("Auto: popup hiện")
                    showVisual(foundX, foundY)
                    task.wait(0.1)
                    local ok = fastClickAt(foundX, foundY)
                    hideVisual()
                    appendLog(ok and "✔ Auto OK" or "✘ Auto fail")
                end
                wasOpen = nowOpen
            end
            task.wait(0.2)
        end
    end)
end

if game.PlaceId ~= CONFIG.GameID then
    warn("[AutoTrade] PlaceId không khớp:", game.PlaceId)
end

buildUI()
log("v80 sẵn sàng. QUÉT DỌC từ trên xuống dưới, từ từ 2px.")
