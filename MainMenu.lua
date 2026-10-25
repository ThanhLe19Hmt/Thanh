--[[
    Auto Trade - Rock Fruit v77 (Grid Test)
    Game ID: 119091355492870

    TRIẾT LÝ:
      - Nút Accept có kích thước ~54x29px.
      - Bấm vào tâm có thể lệch nếu executor xử lý sai.
      - Ta sẽ chia nút thành lưới 3x3 (9 điểm) hoặc 5x5 (25 điểm).
      - Bấm từng điểm cho đến khi popup đóng.
      - Lưu điểm đúng.

    CÁCH DÙNG:
      1. Nhờ acc phụ mời trade.
      2. Khi popup hiện, bấm "TEST GRID" (hoặc bật AUTO GRID).
      3. Tool sẽ bấm lần lượt từng điểm trong lưới.
      4. Điểm nào làm popup đóng -> lưu lại.
      5. Lần sau AUTO sẽ bấm đúng điểm đó.
]]

local CONFIG = {
    GameID = 119091355492870,
    Debug  = true,
    GridSize = 3, -- 3x3 hoặc 5x5
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
-- VISUAL CURSOR (dùng để hiện điểm sắp bấm)
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
    local tl = Vector2.new(0, 0)
    pcall(function() tl = GuiService.TopLeftInset end)
    visualDot.Position = UDim2.new(0, x + tl.X - 6, 0, y + tl.Y - 6)
    visualDot.Visible = true
end

local function hideVisual()
    if visualDot then visualDot.Visible = false end
end

-- ============================================================
-- CLICK (wrapper + VIM)
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
        task.wait(0.25)
        ok = not isPopupOpen()
    end
    if not ok and VirtualInputManager then
        local ix, iy = math.floor(x), math.floor(y)
        pcall(function()
            VirtualInputManager:SendMouseMoveEvent(ix, iy, game)
        end)
        task.wait(0.15)
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(ix, iy, 0, true, game, 0)
        end)
        task.wait(0.1)
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(ix, iy, 0, false, game, 0)
        end)
        task.wait(0.25)
        ok = not isPopupOpen()
    end
    pcall(function() wrapSg:Destroy() end)
    return ok
end

-- ============================================================
-- GRID SEARCH (tìm điểm bấm đúng)
-- ============================================================
local function testGrid()
    local btn = getAcceptButton()
    if not btn then return false, nil end
    local ap = btn.AbsolutePosition
    local sz = btn.AbsoluteSize
    local N = CONFIG.GridSize
    local stepX = sz.X / N
    local stepY = sz.Y / N
    
    log(string.format("Grid %dx%d - btn size %.1fx%.1f", N, N, sz.X, sz.Y))
    
    for i = 1, N do
        for j = 1, N do
            -- Điểm ở giữa mỗi ô
            local px = ap.X + (i - 0.5) * stepX
            local py = ap.Y + (j - 0.5) * stepY
            
            showVisual(px, py)
            task.wait(0.1)
            
            log(string.format("  Try (%d,%d): (%.0f, %.0f)", i, j, px, py))
            local ok = tryClickAt(px, py)
            if ok then
                hideVisual()
                log(string.format("✔ Found at (%d,%d) = (%.1f, %.1f)", i, j, px, py))
                return true, {x = px, y = py, i = i, j = j}
            end
            task.wait(0.15)
        end
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
    frame.Size = UDim2.new(0, 340, 0, 320)
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
    title.Text = "Accept Tester v77 (Grid)"
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
    statusLbl.Text = "Nhờ mời trade, popup hiện -> bấm TEST GRID"
    statusLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 11
    statusLbl.TextWrapped = true
    statusLbl.Parent = body

    local gridBtn = Instance.new("TextButton")
    gridBtn.Size = UDim2.new(0.9, 0, 0, 36)
    gridBtn.Position = UDim2.new(0.05, 0, 0, 36)
    gridBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
    gridBtn.BorderSizePixel = 0
    gridBtn.Text = "1) TEST GRID (3x3)"
    gridBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    gridBtn.Font = Enum.Font.GothamBold
    gridBtn.TextSize = 13
    gridBtn.Parent = body

    local grid5Btn = Instance.new("TextButton")
    grid5Btn.Size = UDim2.new(0.9, 0, 0, 30)
    grid5Btn.Position = UDim2.new(0.05, 0, 0, 76)
    grid5Btn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    grid5Btn.BorderSizePixel = 0
    grid5Btn.Text = "1b) TEST GRID (5x5 - chi tiết hơn)"
    grid5Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    grid5Btn.Font = Enum.Font.GothamBold
    grid5Btn.TextSize = 11
    grid5Btn.Parent = body

    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0.9, 0, 0, 36)
    autoBtn.Position = UDim2.new(0.05, 0, 0, 110)
    autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    autoBtn.BorderSizePixel = 0
    autoBtn.Text = "2) AUTO ACCEPT (cần tìm điểm trước): OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 11
    autoBtn.Parent = body

    local helpLbl = Instance.new("TextLabel")
    helpLbl.Size = UDim2.new(0.9, 0, 0, 100)
    helpLbl.Position = UDim2.new(0.05, 0, 0, 150)
    helpLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    helpLbl.BorderSizePixel = 0
    helpLbl.Text = [[
QUY TRÌNH:
1. Nhờ acc phụ mời trade -> popup hiện.
2. Bấm "TEST GRID (3x3)".
3. Tool sẽ bấm từng điểm trong lưới 3x3 (9 điểm),
   chấm đỏ nhảy tới từng điểm bạn sẽ thấy.
4. Khi popup đóng -> điểm đúng đã được tìm.
5. Nếu 3x3 không tìm được, thử "5x5".
6. Bấm "AUTO ACCEPT: ON" - tool dùng điểm đã tìm.

LƯU Ý: nếu 3x3 fail, mở 5x5 sẽ thử 25 điểm.
Có thể mất 5-10s.
]]
    helpLbl.TextColor3 = Color3.fromRGB(200, 220, 200)
    helpLbl.Font = Enum.Font.Gotham
    helpLbl.TextSize = 10
    helpLbl.TextWrapped = true
    helpLbl.TextYAlignment = Enum.TextYAlignment.Top
    helpLbl.Parent = body

    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.9, 0, 0, 34)
    logLbl.Position = UDim2.new(0.05, 0, 0, 254)
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
        if #cur > 340 then cur = cur:sub(-260) end
        logLbl.Text = cur .. "\n" .. s
    end

    closeUI.MouseButton1Click:Connect(function() sg:Destroy() end)

    gridBtn.MouseButton1Click:Connect(function()
        CONFIG.GridSize = 3
        task.spawn(function()
            setStatus("Đang test grid 3x3...", Color3.fromRGB(200, 200, 120))
            appendLog("Grid 3x3 start")
            local ok, result = testGrid()
            if ok then
                foundX = result.x
                foundY = result.y
                appendLog(string.format("✔ Found: (%.0f,%.0f) ô (%d,%d)",
                    result.x, result.y, result.i, result.j))
                setStatus(string.format("✔ Tìm được (%.0f,%.0f) - bật AUTO", result.x, result.y),
                    Color3.fromRGB(120, 220, 120))
            else
                appendLog("✘ 3x3 fail - thử 5x5")
                setStatus("✘ 3x3 fail - thử 5x5", Color3.fromRGB(255, 120, 120))
            end
        end)
    end)

    grid5Btn.MouseButton1Click:Connect(function()
        CONFIG.GridSize = 5
        task.spawn(function()
            setStatus("Đang test grid 5x5...", Color3.fromRGB(200, 200, 120))
            appendLog("Grid 5x5 start")
            local ok, result = testGrid()
            if ok then
                foundX = result.x
                foundY = result.y
                appendLog(string.format("✔ Found: (%.0f,%.0f) ô (%d,%d)",
                    result.x, result.y, result.i, result.j))
                setStatus(string.format("✔ Tìm được (%.0f,%.0f) - bật AUTO", result.x, result.y),
                    Color3.fromRGB(120, 220, 120))
            else
                appendLog("✘ 5x5 fail - executor sandbox?")
                setStatus("✘ 5x5 fail - thử executor khác", Color3.fromRGB(255, 120, 120))
            end
        end)
    end)

    autoBtn.MouseButton1Click:Connect(function()
        if not foundX then
            appendLog("Chưa tìm điểm. Bấm TEST GRID trước.")
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
            if autoEnabled and foundX then
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
log("v77 sẵn sàng. TEST GRID để tìm điểm bấm đúng.")
