--[[
    Auto Trade - Rock Fruit v79 (Fast Scan)
    Game ID: 119091355492870

    PHÂN TÍCH LỖI v78:
      - v78 quét Y từ -30 đến +30 bước 2px = 31 điểm.
      - Mỗi điểm chờ 0.15s -> tổng 31 * 0.15 = 4.65s.
      - Popup trade chỉ tồn tại 3s -> hết thời gian.
      - Kết quả: chưa quét xong popup đã biến mất.

    FIX v79:
      1. Giảm delay: chỉ chờ 0.04s giữa các lần bấm.
      2. Grid 3x3 = 9 điểm, mỗi điểm ~0.15s (bao gồm click).
      3. Tổng ~1.4s -> kịp trong 3s.
      4. Nếu vẫn fail, quét lại với grid 5x5 nếu popup còn.
      5. Có nút "TEST NHANH" - bấm 9 điểm liên tiếp trong 1.5s.

    CHIẾN LƯỢC:
      - Bấm nhanh, không chờ lâu.
      - Nếu popup đóng -> dừng ngay.
      - Delay giữa các điểm = 0.04s (chỉ đủ để game nhận).
      - Sau khi popup đóng, ghi lại toạ độ.

    LƯU Ý:
      - Popup trade có timeout ~3s.
      - Grid 3x3 trong 1.5s -> OK.
      - Grid 5x5 trong 3s -> sát nút.
      - Nếu cần thiết, chia 2 lần scan.
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
    visualDot.Visible = true
end

local function hideVisual()
    if visualDot then visualDot.Visible = false end
end

-- ============================================================
-- CLICK NHANH (không chờ lâu)
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
    task.wait(0.02)  -- chỉ đủ để render
    
    if firetouchinterest then
        pcall(function()
            firetouchinterest(wrapper, Vector2.new(x, y), 0)
            task.wait(0.02)
            firetouchinterest(wrapper, Vector2.new(x, y), 1)
        end)
    end
    
    task.wait(0.04)  -- chờ popup đóng
    local closed = not isPopupOpen()
    pcall(function() wrapSg:Destroy() end)
    return closed
end

-- ============================================================
-- GRID SCAN NHANH
-- ============================================================
local function fastGridScan(gridSize)
    gridSize = gridSize or 3
    local btn = getAcceptButton()
    if not btn then return false, nil end
    local ap = btn.AbsolutePosition
    local sz = btn.AbsoluteSize
    local stepX = sz.X / gridSize
    local stepY = sz.Y / gridSize
    
    -- Quét X và Y cùng lúc, từ trên-trái xuống dưới-phải
    -- Ưu tiên trung tâm trước (khả năng cao nhất)
    local points = {}
    for i = 1, gridSize do
        for j = 1, gridSize do
            local px = ap.X + (i - 0.5) * stepX
            local py = ap.Y + (j - 0.5) * stepY
            table.insert(points, {x = px, y = py, i = i, j = j})
        end
    end
    -- Sắp xếp lại: ưu tiên điểm gần tâm
    local centerI = (gridSize + 1) / 2
    local centerJ = (gridSize + 1) / 2
    table.sort(points, function(a, b)
        local da = (a.i - centerI)^2 + (a.j - centerJ)^2
        local db = (b.i - centerI)^2 + (b.j - centerJ)^2
        return da < db
    end)
    
    log(string.format("Grid %dx%d: %d điểm, bắt đầu quét", gridSize, gridSize, #points))
    
    for idx, p in ipairs(points) do
        if not isPopupOpen() then
            log("Popup đã đóng, dừng scan")
            break
        end
        showVisual(p.x, p.y)
        task.wait(0.05)  -- chỉ chờ để render chấm đỏ
        
        log(string.format("  #%d (%d,%d) = (%.0f,%.0f)", idx, p.i, p.j, p.x, p.y))
        local ok = fastClickAt(p.x, p.y)
        if ok then
            hideVisual()
            log(string.format("✔ Found at #%d (%d,%d) = (%.1f, %.1f)", idx, p.i, p.j, p.x, p.y))
            return true, p
        end
        task.wait(0.04)  -- giữa các điểm
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
    frame.Size = UDim2.new(0, 360, 0, 380)
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
    title.Text = "Accept Tester v79 (Fast Scan)"
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
    statusLbl.Text = "Quét NHANH để kịp timeout 3s."
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
    infoLbl.Text = "Chưa tìm điểm."
    infoLbl.TextColor3 = Color3.fromRGB(180, 220, 255)
    infoLbl.Font = Enum.Font.Code
    infoLbl.TextSize = 11
    infoLbl.Parent = body

    local fastBtn = Instance.new("TextButton")
    fastBtn.Size = UDim2.new(0.9, 0, 0, 44)
    fastBtn.Position = UDim2.new(0.05, 0, 0, 68)
    fastBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
    fastBtn.BorderSizePixel = 0
    fastBtn.Text = "1) FAST SCAN 3x3 (~1.5s)"
    fastBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    fastBtn.Font = Enum.Font.GothamBold
    fastBtn.TextSize = 14
    fastBtn.Parent = body

    local fast5Btn = Instance.new("TextButton")
    fast5Btn.Size = UDim2.new(0.9, 0, 0, 32)
    fast5Btn.Position = UDim2.new(0.05, 0, 0, 116)
    fast5Btn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    fast5Btn.BorderSizePixel = 0
    fast5Btn.Text = "1b) FAST SCAN 5x5 (~3s, sát nút)"
    fast5Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    fast5Btn.Font = Enum.Font.GothamBold
    fast5Btn.TextSize = 11
    fast5Btn.Parent = body

    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0.9, 0, 0, 36)
    autoBtn.Position = UDim2.new(0.05, 0, 0, 152)
    autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    autoBtn.BorderSizePixel = 0
    autoBtn.Text = "2) AUTO ACCEPT (cần tìm trước): OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 11
    autoBtn.Parent = body

    local helpLbl = Instance.new("TextLabel")
    helpLbl.Size = UDim2.new(0.9, 0, 0, 140)
    helpLbl.Position = UDim2.new(0.05, 0, 0, 196)
    helpLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    helpLbl.BorderSizePixel = 0
    helpLbl.Text = [[
QUY TRÌNH:
1. Nhờ acc phụ mời trade -> popup hiện (3s).
2. NGAY LẬP TỨC bấm "FAST SCAN 3x3".
3. Tool bấm 9 điểm trong ~1.5s.
   - Điểm nào đóng popup -> dừng, lưu.
4. Nếu 3x3 fail (popup vẫn còn), thử 5x5.
5. Bấm AUTO ON sau khi tìm được.

Delay mỗi điểm chỉ 0.05s -> kịp trong 3s.
Chấm đỏ nhảy rất nhanh -> bạn chỉ thấy
nhấp nháy tại điểm đúng.

TỐC ĐỘ:
- 3x3: 9 điểm * 0.15s = 1.35s -> an toàn.
- 5x5: 25 điểm * 0.12s = 3s -> sát giới hạn.
]]
    helpLbl.TextColor3 = Color3.fromRGB(200, 220, 200)
    helpLbl.Font = Enum.Font.Gotham
    helpLbl.TextSize = 10
    helpLbl.TextWrapped = true
    helpLbl.TextYAlignment = Enum.TextYAlignment.Top
    helpLbl.Parent = body

    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.9, 0, 0, 34)
    logLbl.Position = UDim2.new(0.05, 0, 0, 340)
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
        if #cur > 260 then cur = cur:sub(-200) end
        logLbl.Text = cur .. "\n" .. s
    end

    closeUI.MouseButton1Click:Connect(function() sg:Destroy() end)

    fastBtn.MouseButton1Click:Connect(function()
        if not isPopupOpen() then
            appendLog("Không có popup. Nhờ mời trước.")
            return
        end
        task.spawn(function()
            setStatus("Đang quét 3x3 nhanh...", Color3.fromRGB(200, 200, 120))
            appendLog("Scan 3x3 start")
            local ok, result = fastGridScan(3)
            if ok then
                foundX = result.x
                foundY = result.y
                infoLbl.Text = string.format("X=%.0f Y=%.0f ô(%d,%d)",
                    result.x, result.y, result.i, result.j)
                appendLog(string.format("✔ (%.0f,%.0f) ô(%d,%d)",
                    result.x, result.y, result.i, result.j))
                setStatus(string.format("✔ Tìm được (%.0f,%.0f)", result.x, result.y),
                    Color3.fromRGB(120, 220, 120))
            else
                appendLog("✘ 3x3 fail - thử 5x5")
                setStatus("✘ 3x3 fail - thử 5x5", Color3.fromRGB(255, 120, 120))
            end
        end)
    end)

    fast5Btn.MouseButton1Click:Connect(function()
        if not isPopupOpen() then
            appendLog("Không có popup.")
            return
        end
        task.spawn(function()
            setStatus("Đang quét 5x5...", Color3.fromRGB(200, 200, 120))
            appendLog("Scan 5x5 start")
            local ok, result = fastGridScan(5)
            if ok then
                foundX = result.x
                foundY = result.y
                infoLbl.Text = string.format("X=%.0f Y=%.0f ô(%d,%d)",
                    result.x, result.y, result.i, result.j)
                appendLog(string.format("✔ (%.0f,%.0f) ô(%d,%d)",
                    result.x, result.y, result.i, result.j))
                setStatus(string.format("✔ Tìm được (%.0f,%.0f)", result.x, result.y),
                    Color3.fromRGB(120, 220, 120))
            else
                appendLog("✘ 5x5 fail - thử 3x3 hoặc executor khác")
                setStatus("✘ 5x5 fail", Color3.fromRGB(255, 120, 120))
            end
        end)
    end)

    autoBtn.MouseButton1Click:Connect(function()
        if not foundX then
            appendLog("Chưa tìm được điểm.")
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
log("v79 sẵn sàng. FAST SCAN 3x3 trong ~1.5s.")
