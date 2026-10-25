--[[
    Auto Trade - Rock Fruit v78 (Height Scan)
    Game ID: 119091355492870

    LOGIC:
      - Vấn đề bạn mô tả: tool bấm CAO QUÁ -> hụt nút Accept.
      - Nghĩa là toạ độ Y bị lệch xuống. Bạn phải kéo ô đen
        xuống thấp hơn một chút mới bấm đúng.
      - Ta sẽ quét tự động: bắt đầu từ trên nút Accept (Y - 20px)
        rồi tăng dần Y từng 2px cho đến khi popup đóng.
      - Mỗi bước: chấm đỏ nhảy tới điểm đó, bấm, kiểm tra.
      - Khi popup đóng -> lưu toạ độ Y chính xác.

    TẠI SAO CHỈ QUÉT CHIỀU CAO:
      - Bạn nói lệch "cao quá" -> lỗi chỉ ở trục Y.
      - Trục X (ngang) có vẻ đúng (bạn không phàn nàn).
      - Do đó chỉ cần quét Y từ -30 đến +30 quanh tâm nút.

    CÁCH DÙNG:
      1. Nhờ acc phụ mời trade.
      2. Khi popup hiện, bấm "SCAN HEIGHT".
      3. Tool sẽ thử Y từ tâm-30 đến tâm+30 bước 2px.
      4. Điểm nào đóng popup -> lưu Y đó.
      5. Từ giờ AUTO sẽ dùng X tâm + Y đã tìm.
]]

local CONFIG = {
    GameID = 119091355492870,
    Debug  = true,
    ScanRange = 30,    -- ±30px quanh tâm
    ScanStep = 2,      -- bước nhảy 2px
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
-- VISUAL
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
    
    visualLine = Instance.new("Frame")
    visualLine.Size = UDim2.new(0, 60, 0, 1)
    visualLine.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
    visualLine.BorderSizePixel = 0
    visualLine.ZIndex = 999993
    visualLine.Visible = false
    visualLine.Parent = visualGui
    
    visualDot = Instance.new("Frame")
    visualDot.Size = UDim2.new(0, 14, 0, 14)
    visualDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    visualDot.BackgroundTransparency = 0.2
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
    local tl = Vector2.new(0, 0)
    pcall(function() tl = GuiService.TopLeftInset end)
    visualDot.Position = UDim2.new(0, x + tl.X - 7, 0, y + tl.Y - 7)
    visualLine.Position = UDim2.new(0, x + tl.X - 30, 0, y + tl.Y)
    visualDot.Visible = true
    visualLine.Visible = true
end

local function hideVisual()
    if visualDot then visualDot.Visible = false end
    if visualLine then visualLine.Visible = false end
end

-- ============================================================
-- CLICK
-- ============================================================
local function tryClickAt(x, y)
    local wrapSg = Instance.new("ScreenGui")
    wrapSg.Name = "HoangTouchWrapper"
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
        pcall(function()
            firetouchinterest(wrapper, Vector2.new(x, y), 0)
            task.wait(0.1)
            firetouchinterest(wrapper, Vector2.new(x, y), 1)
        end)
        task.wait(0.2)
        ok = not isPopupOpen()
    end
    if not ok and VirtualInputManager then
        local ix, iy = math.floor(x), math.floor(y)
        pcall(function()
            VirtualInputManager:SendMouseMoveEvent(ix, iy, game)
        end)
        task.wait(0.1)
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(ix, iy, 0, true, game, 0)
        end)
        task.wait(0.1)
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(ix, iy, 0, false, game, 0)
        end)
        task.wait(0.2)
        ok = not isPopupOpen()
    end
    pcall(function() wrapSg:Destroy() end)
    return ok
end

-- ============================================================
-- HEIGHT SCAN (quét chiều cao)
-- ============================================================
local function scanHeight()
    local btn = getAcceptButton()
    if not btn then return false, nil end
    local ap = btn.AbsolutePosition
    local sz = btn.AbsoluteSize
    local centerX = ap.X + sz.X / 2
    local centerY = ap.Y + sz.Y / 2
    
    log(string.format("Nút: X=%.0f Y=%.0f Size=%.0fx%.0f", ap.X, ap.Y, sz.X, sz.Y))
    log(string.format("Tâm: (%.0f, %.0f) - quét Y từ %.0f đến %.0f",
        centerX, centerY, centerY - CONFIG.ScanRange, centerY + CONFIG.ScanRange))
    
    -- Quét từ trên xuống (Y - range) đến dưới (Y + range)
    for offset = -CONFIG.ScanRange, CONFIG.ScanRange, CONFIG.ScanStep do
        local testY = centerY + offset
        showVisual(centerX, testY)
        task.wait(0.15)
        
        log(string.format("  Thử Y offset %d -> (%.0f, %.0f)", offset, centerX, testY))
        local ok = tryClickAt(centerX, testY)
        if ok then
            hideVisual()
            log(string.format("✔ Tìm được Y offset %d -> Y=%.0f", offset, testY))
            return true, {x = centerX, y = testY, offsetY = offset}
        end
        task.wait(0.1)
    end
    hideVisual()
    return false, nil
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
    title.Text = "Accept Tester v78 (Scan Height)"
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
    statusLbl.Text = "Nút Accept cao quá -> bấm hụt. Quét Y."
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
    scanBtn.Size = UDim2.new(0.9, 0, 0, 40)
    scanBtn.Position = UDim2.new(0.05, 0, 0, 68)
    scanBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
    scanBtn.BorderSizePixel = 0
    scanBtn.Text = "1) SCAN HEIGHT (±30px, bước 2px)"
    scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    scanBtn.Font = Enum.Font.GothamBold
    scanBtn.TextSize = 13
    scanBtn.Parent = body

    local scanWideBtn = Instance.new("TextButton")
    scanWideBtn.Size = UDim2.new(0.9, 0, 0, 32)
    scanWideBtn.Position = UDim2.new(0.05, 0, 0, 112)
    scanWideBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    scanWideBtn.BorderSizePixel = 0
    scanWideBtn.Text = "1b) SCAN WIDE (±60px, bước 3px)"
    scanWideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    scanWideBtn.Font = Enum.Font.GothamBold
    scanWideBtn.TextSize = 11
    scanWideBtn.Parent = body

    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0.9, 0, 0, 36)
    autoBtn.Position = UDim2.new(0.05, 0, 0, 150)
    autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    autoBtn.BorderSizePixel = 0
    autoBtn.Text = "2) AUTO ACCEPT (cần tìm Y trước): OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 11
    autoBtn.Parent = body

    local helpLbl = Instance.new("TextLabel")
    helpLbl.Size = UDim2.new(0.9, 0, 0, 120)
    helpLbl.Position = UDim2.new(0.05, 0, 0, 196)
    helpLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    helpLbl.BorderSizePixel = 0
    helpLbl.Text = [[
QUY TRÌNH:
1. Nhờ acc phụ mời trade -> popup hiện.
2. Bấm "SCAN HEIGHT".
3. Tool sẽ thử Y từ (tâm - 30) đến (tâm + 30) bước 2px:
   - Chấm đỏ nhảy theo chiều dọc, có đường kẻ vàng
     để bạn thấy chiều cao hiện tại.
   - Bấm từng điểm.
4. Khi popup đóng -> Y đúng đã được tìm.
5. Nếu SCAN HEIGHT fail, thử SCAN WIDE (±60px).
6. Bấm AUTO ON.

Chấm đỏ đi từ TRÊN xuống DƯỚI. Bạn sẽ thấy nó dừng
ở điểm đúng.
]]
    helpLbl.TextColor3 = Color3.fromRGB(200, 220, 200)
    helpLbl.Font = Enum.Font.Gotham
    helpLbl.TextSize = 10
    helpLbl.TextWrapped = true
    helpLbl.TextYAlignment = Enum.TextYAlignment.Top
    helpLbl.Parent = body

    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.9, 0, 0, 50)
    logLbl.Position = UDim2.new(0.05, 0, 0, 322)
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
        if #cur > 380 then cur = cur:sub(-300) end
        logLbl.Text = cur .. "\n" .. s
    end

    closeUI.MouseButton1Click:Connect(function() sg:Destroy() end)

    scanBtn.MouseButton1Click:Connect(function()
        CONFIG.ScanRange = 30
        CONFIG.ScanStep = 2
        task.spawn(function()
            setStatus("Đang quét Y ±30...", Color3.fromRGB(200, 200, 120))
            appendLog("Scan Y ±30px step 2px")
            local ok, result = scanHeight()
            if ok then
                foundX = result.x
                foundY = result.y
                infoLbl.Text = string.format("X=%.0f Y=%.0f (offset %d)",
                    result.x, result.y, result.offsetY)
                appendLog(string.format("✔ Y offset %d -> (%.0f,%.0f)",
                    result.offsetY, result.x, result.y))
                setStatus(string.format("✔ Tìm được Y offset %d", result.offsetY),
                    Color3.fromRGB(120, 220, 120))
            else
                appendLog("✘ Scan ±30 fail - thử WIDE")
                setStatus("✘ ±30 fail - thử SCAN WIDE", Color3.fromRGB(255, 120, 120))
            end
        end)
    end)

    scanWideBtn.MouseButton1Click:Connect(function()
        CONFIG.ScanRange = 60
        CONFIG.ScanStep = 3
        task.spawn(function()
            setStatus("Đang quét Y ±60...", Color3.fromRGB(200, 200, 120))
            appendLog("Scan Y ±60 step 3px")
            local ok, result = scanHeight()
            if ok then
                foundX = result.x
                foundY = result.y
                infoLbl.Text = string.format("X=%.0f Y=%.0f (offset %d)",
                    result.x, result.y, result.offsetY)
                appendLog(string.format("✔ Y offset %d -> (%.0f,%.0f)",
                    result.offsetY, result.x, result.y))
                setStatus(string.format("✔ Tìm được Y offset %d", result.offsetY),
                    Color3.fromRGB(120, 220, 120))
            else
                appendLog("✘ ±60 fail - executor sandbox?")
                setStatus("✘ ±60 fail", Color3.fromRGB(255, 120, 120))
            end
        end)
    end)

    autoBtn.MouseButton1Click:Connect(function()
        if not foundY then
            appendLog("Chưa tìm được Y. Bấm SCAN HEIGHT trước.")
            return
        end
        autoEnabled = not autoEnabled
        if autoEnabled then
            autoBtn.Text = "2) AUTO ACCEPT: ON"
            autoBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            appendLog(string.format("AUTO ON tại (%.0f,%.0f)", foundX, foundY))
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
            if autoEnabled and foundY then
                local nowOpen = isPopupOpen()
                if nowOpen and not wasOpen then
                    appendLog("Auto: popup hiện")
                    showVisual(foundX, foundY)
                    task.wait(0.2)
                    local ok = tryClickAt(foundX, foundY)
                    hideVisual()
                    appendLog(ok and "✔ Auto OK" or "✘ Auto fail")
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
log("v78 sẵn sàng. SCAN HEIGHT để quét chiều cao Y.")
