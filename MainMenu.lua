--[[
    Auto Trade - Rock Fruit v76 (Mobile Virtual Cursor TP & Click)
    Game ID: 119091355492870

    LOGIC:
      - Mobile không có mousemoverel (Windows API).
      - Nhưng có VirtualInputManager:SendMouseMoveEvent.
      - Trên một số executor (Delta, Fluxus), hàm này map sang
        touch event thật -> Roblox hiểu là touch tại toạ độ đó.
      - Ta sẽ:
        1. Lấy tâm nút Accept.
        2. Vẽ chấm đỏ 20x20 nhảy tới đó (visual).
        3. Gọi SendMouseMoveEvent(X, Y) -> di chuột ảo.
        4. Chờ 0.2s.
        5. Gọi SendMouseButtonEvent(X, Y, 0, true/false).
        6. Nếu không đóng popup -> firetouchinterest qua wrapper
           tại đúng toạ độ đó.

    LƯU Ý:
      - v76 KHÔNG dùng offset, KHÔNG dùng kéo thả.
      - Toạ độ lấy trực tiếp từ nút Accept -> chính xác.
      - Chỉ cần bấm nút AUTO.
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
-- CON TRỎ ẢO (VISUAL)
-- ============================================================
local visualGui = nil
local visualDot = nil

local function ensureVisual()
    if visualGui and visualGui.Parent then return end
    visualGui = Instance.new("ScreenGui")
    visualGui.Name = "HoangVirtualCursor"
    visualGui.ResetOnSpawn = false
    visualGui.IgnoreGuiInset = true  -- dùng toạ độ screen
    visualGui.Parent = CoreGui
    visualDot = Instance.new("Frame")
    visualDot.Size = UDim2.new(0, 20, 0, 20)
    visualDot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    visualDot.BackgroundTransparency = 0.3
    visualDot.BorderSizePixel = 2
    visualDot.BorderColor3 = Color3.fromRGB(255, 255, 255)
    visualDot.ZIndex = 999995
    visualDot.Visible = false
    visualDot.Parent = visualGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = visualDot
    local inner = Instance.new("Frame")
    inner.Size = UDim2.new(0, 4, 0, 4)
    inner.Position = UDim2.new(0.5, -2, 0.5, -2)
    inner.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
    inner.BorderSizePixel = 0
    inner.ZIndex = 999996
    inner.Parent = visualDot
    local c2 = Instance.new("UICorner")
    c2.CornerRadius = UDim.new(1, 0)
    c2.Parent = inner
end

local function showVisual(x, y)
    ensureVisual()
    local tl = Vector2.new(0, 0)
    pcall(function() tl = GuiService.TopLeftInset end)
    visualDot.Position = UDim2.new(0, x + tl.X - 10, 0, y + tl.Y - 10)
    visualDot.Visible = true
end

local function hideVisual()
    if visualDot then visualDot.Visible = false end
end

-- ============================================================
-- BẤM QUA VIRTUAL INPUT (di chuyển chuột ảo + click)
-- ============================================================
local function clickViaVIM(x, y)
    if not VirtualInputManager then return false, "no_vim" end
    log(string.format("[VIM] Move (%d, %d) + Click", math.floor(x), math.floor(y)))
    local ix, iy = math.floor(x), math.floor(y)
    pcall(function()
        VirtualInputManager:SendMouseMoveEvent(ix, iy, game)
    end)
    task.wait(0.3)
    local loc = UserInputService:GetMouseLocation()
    log(string.format("  Sau move: (%.0f, %.0f)", loc.X, loc.Y))
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
-- BẤM QUA WRAPPER (fallback)
-- ============================================================
local function clickViaWrapper(x, y)
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
    wrapper.ZIndex = 999992
    wrapper.Parent = wrapSg
    task.wait(0.1)
    local ok = false
    if firetouchinterest then
        log(string.format("[WRAPPER] firetouchinterest (%.0f, %.0f)", x, y))
        pcall(function()
            firetouchinterest(wrapper, Vector2.new(x, y), 0)
            task.wait(0.15)
            firetouchinterest(wrapper, Vector2.new(x, y), 1)
        end)
        task.wait(0.3)
        ok = not isPopupOpen()
    end
    if not ok and typeof(firesignal) == "function" then
        pcall(function()
            firesignal(wrapper.MouseButton1Down)
            task.wait(0.05)
            firesignal(wrapper.MouseButton1Up)
            task.wait(0.05)
            firesignal(wrapper.MouseButton1Click)
        end)
        task.wait(0.3)
        ok = not isPopupOpen()
    end
    pcall(function() wrapSg:Destroy() end)
    if ok then return true, "wrapper" end
    return false, "wrapper_fail"
end

-- ============================================================
-- ACCEPT TỔNG HỢP
-- ============================================================
local function acceptTrade()
    local btn = getAcceptButton()
    if not btn then return false, "no_popup" end
    local c = getCenter(btn)
    if not c then return false, "no_center" end

    log(string.format("Target Accept center: (%.1f, %.1f)", c.X, c.Y))
    showVisual(c.X, c.Y)
    task.wait(0.3)  -- Cho bạn thấy chấm đỏ nhảy tới nút

    -- Cách 1: VIM
    local ok, r = clickViaVIM(c.X, c.Y)
    if ok then hideVisual(); return true, r end

    -- Cách 2: Wrapper
    task.wait(0.1)
    ok, r = clickViaWrapper(c.X, c.Y)
    hideVisual()
    if ok then return true, r end

    return false, "all_fail"
end

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
    frame.Size = UDim2.new(0, 340, 0, 260)
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
    title.Text = "Auto Trade v76 (TP & Click)"
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
    statusLbl.Text = "Tự tìm nút Accept + TP + Click. Bấm AUTO."
    statusLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 11
    statusLbl.TextWrapped = true
    statusLbl.Parent = body

    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0.9, 0, 0, 36)
    autoBtn.Position = UDim2.new(0.05, 0, 0, 36)
    autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    autoBtn.BorderSizePixel = 0
    autoBtn.Text = "AUTO ACCEPT: OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 13
    autoBtn.Parent = body

    local testBtn = Instance.new("TextButton")
    testBtn.Size = UDim2.new(0.9, 0, 0, 30)
    testBtn.Position = UDim2.new(0.05, 0, 0, 76)
    testBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
    testBtn.BorderSizePixel = 0
    testBtn.Text = "TEST ngay (khi popup hiện)"
    testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testBtn.Font = Enum.Font.GothamBold
    testBtn.TextSize = 12
    testBtn.Parent = body

    local helpLbl = Instance.new("TextLabel")
    helpLbl.Size = UDim2.new(0.9, 0, 0, 80)
    helpLbl.Position = UDim2.new(0.05, 0, 0, 110)
    helpLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    helpLbl.BorderSizePixel = 0
    helpLbl.Text = [[
1. Bấm AUTO ACCEPT (hoặc TEST khi popup hiện).
2. Tool tự:
   - Tìm tâm nút Accept.
   - Chấm đỏ nhảy tới đó.
   - VIM move + click.
   - Fallback wrapper.
3. Quan sát chấm đỏ. Nếu bấm đúng -> popup đóng.
]]
    helpLbl.TextColor3 = Color3.fromRGB(200, 220, 200)
    helpLbl.Font = Enum.Font.Gotham
    helpLbl.TextSize = 10
    helpLbl.TextWrapped = true
    helpLbl.TextYAlignment = Enum.TextYAlignment.Top
    helpLbl.Parent = body

    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.9, 0, 0, 34)
    logLbl.Position = UDim2.new(0.05, 0, 0, 194)
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
        if #cur > 280 then cur = cur:sub(-200) end
        logLbl.Text = cur .. "\n" .. s
    end

    closeUI.MouseButton1Click:Connect(function() sg:Destroy() end)

    local enabled = false
    autoBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            autoBtn.Text = "AUTO ACCEPT: ON"
            autoBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            setStatus("Đang chờ popup...", Color3.fromRGB(120, 220, 120))
            appendLog("AUTO ON")
        else
            autoBtn.Text = "AUTO ACCEPT: OFF"
            autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
            setStatus("Đã tắt", Color3.fromRGB(200, 200, 120))
            appendLog("AUTO OFF")
        end
    end)

    testBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            if not isPopupOpen() then
                appendLog("Không có popup")
                return
            end
            local ok, r = acceptTrade()
            appendLog(ok and ("✔ OK: " .. r) or ("✘ Fail: " .. tostring(r)))
            setStatus(ok and ("✔ " .. r) or "✘ Fail",
                ok and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(255, 120, 120))
        end)
    end)

    task.spawn(function()
        local wasOpen = false
        while sg.Parent do
            if enabled then
                local nowOpen = isPopupOpen()
                if nowOpen and not wasOpen then
                    appendLog("Popup hiện, accept...")
                    task.wait(0.2)
                    local ok, r = acceptTrade()
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
log("v76 sẵn sàng. Tự TP chuột ảo tới nút Accept + click.")
