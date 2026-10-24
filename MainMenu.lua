--[[
    Auto Trade - Rock Fruit v66 (Visual & Touch Sync)
    Game ID: 119091355492870

    PHÂN TÍCH LỖI v65:
      - Bạn calibrate được offsetY=60 -> firetouchinterest
        bấm trúng nút Accept và popup đóng.
      - NHƯNG Chuột Ảo (Frame đỏ) hiển thị lệch sang TRÁI ~20-30px.
      - Bạn phải di chuyển chuột ảo sang phải 1 chút thì mới
        khớp vị trí đỏ.

    TẠI SAO LỆCH:
      - "Vùng đỏ" bạn thấy là vị trí firetouchinterest đang
        chạm thực sự (touch event).
      - "Con chuột" là Frame GUI hiển thị trên ScreenGui
        với IgnoreGuiInset = true.
      - Nếu IgnoreGuiInset = true:
        + Toạ độ (0,0) của Frame = góc trên trái màn hình
          VẬT LÝ (bao gồm status bar, notch).
        + firetouchinterest dùng toạ độ viewport
          (0,0 = góc trên trái viewport 3D, bỏ qua inset).
      - Kết quả: Frame vẽ tại (cx, cy) nhưng touch xảy ra
        tại (cx + insetX, cy + insetY) -> lệch.
      - Cụ thể bạn thấy lệch sang TRÁI -> insetX của mobile
        đang > 0.

    FIX v66:
      1. Đặt IgnoreGuiInset = false cho ScreenGui hiển thị chuột.
      2. Hoặc: bù bằng GuiService.TopLeftInset:
         - Nếu IgnoreGuiInset = true:
           Frame.Position = (cx - insetX, cy - insetY)
         - Nếu IgnoreGuiInset = false:
           Frame.Position = (cx, cy)
      3. Tôi sẽ dùng IgnoreGuiInset = false để Roblox tự
         xử lý inset -> Frame khớp với viewport.
      4. Touch vẫn dùng (cx, cy) + offsetY.

    BONUS:
      - Thêm nút "Hiển thị vùng touch" - vẽ 1 ô vuông nhỏ
        tại đúng vị trí firetouchinterest để bạn so sánh.
]]

local CONFIG = {
    GameID          = 119091355492870,
    Debug           = true,
    SafeMarginTop   = 100,
    SafeMarginRight = 100,
    AcceptOffsetY   = 60,
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
-- PLATFORM
-- ============================================================
local isTouch = UserInputService.TouchEnabled
local isMouse = UserInputService.MouseEnabled
local isKeyboard = UserInputService.KeyboardEnabled
local IS_MOBILE = (isTouch and not isKeyboard and not isMouse)
local IS_PC = (isMouse and isKeyboard and not isTouch)
local PLATFORM = IS_MOBILE and "MOBILE" or (IS_PC and "PC" or "UNKNOWN")

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
-- CHUỘT ẢO + VÙNG TOUCH (SYNC)
-- ============================================================
local cursorGui = nil
local cursorFrame = nil
local touchMarker = nil

local function ensureCursorGui()
    if cursorGui and cursorGui.Parent then return end
    cursorGui = Instance.new("ScreenGui")
    cursorGui.Name = "HoangVirtualMouse"
    cursorGui.ResetOnSpawn = false
    -- QUAN TRỌNG: IgnoreGuiInset = false
    -- -> Frame dùng toạ độ viewport (giống firetouchinterest)
    cursorGui.IgnoreGuiInset = false
    cursorGui.Parent = CoreGui
    
    cursorFrame = Instance.new("Frame")
    cursorFrame.Name = "Cursor"
    cursorFrame.Size = UDim2.new(0, 30, 0, 30)
    cursorFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    cursorFrame.BackgroundTransparency = 0.5
    cursorFrame.BorderSizePixel = 2
    cursorFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
    cursorFrame.ZIndex = 999999
    cursorFrame.Visible = false
    cursorFrame.Parent = cursorGui
    
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(0.5, -3, 0.5, -3)
    dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    dot.BorderSizePixel = 0
    dot.ZIndex = 1000000
    dot.Parent = cursorFrame
    
    -- Vùng touch (vẽ 1 hình vuông nhỏ tại đúng vị trí firetouchinterest)
    touchMarker = Instance.new("Frame")
    touchMarker.Name = "TouchMarker"
    touchMarker.Size = UDim2.new(0, 8, 0, 8)
    touchMarker.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    touchMarker.BorderSizePixel = 0
    touchMarker.ZIndex = 999998
    touchMarker.Visible = false
    touchMarker.Parent = cursorGui
end

local function showCursor(x, y)
    ensureCursorGui()
    -- Vì IgnoreGuiInset = false -> Frame.Position dùng toạ độ viewport
    -- (cx, cy) đã là viewport -> đặt thẳng
    cursorFrame.Position = UDim2.new(0, x - 15, 0, y - 15)
    cursorFrame.Visible = true
end

local function showTouchMarker(x, y)
    ensureCursorGui()
    -- Marker này đại diện cho ĐIỂM firetouchinterest chạm thực sự
    touchMarker.Position = UDim2.new(0, x - 4, 0, y - 4)
    touchMarker.Visible = true
end

local function hideCursor()
    if cursorFrame then cursorFrame.Visible = false end
    if touchMarker then touchMarker.Visible = false end
end

-- ============================================================
-- CLICK MOBILE
-- ============================================================
local function tryTouchAt(btn, pos)
    if not firetouchinterest then return false end
    pcall(function()
        firetouchinterest(btn, pos, 0)
        task.wait(0.15)
        firetouchinterest(btn, pos, 1)
    end)
    task.wait(0.35)
    return not isPopupOpen()
end

local function tryVIMAt(btn, pos)
    if not VirtualInputManager then return false end
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
    return not isPopupOpen()
end

local function clickAcceptMobile(btn)
    local c = getCenter(btn)
    if not c then return false, "no_center" end
    
    -- Toạ độ touch = viewport + offsetY (đã calibrate = 60)
    local touchPos = Vector2.new(c.X, c.Y + CONFIG.AcceptOffsetY)
    
    -- Hiển thị:
    -- - Chuột ảo tại touchPos (vị trí sẽ chạm)
    -- - Touch marker tại touchPos (vị trí touch thực sự)
    showCursor(touchPos.X, touchPos.Y)
    showTouchMarker(touchPos.X, touchPos.Y)
    task.wait(0.3)
    
    log(string.format("Click tại (%.0f, %.0f)", touchPos.X, touchPos.Y))
    
    if tryTouchAt(btn, touchPos) then hideCursor(); return true, "touch" end
    if tryVIMAt(btn, touchPos) then hideCursor(); return true, "vim" end
    
    hideCursor()
    return false, "all_fail"
end

-- ============================================================
-- CLICK PC
-- ============================================================
local function clickAcceptPC(btn)
    if not mousemoverel or not mouse1click then return false, "no_api" end
    local c = getCenter(btn)
    if not c then return false, "no_center" end
    for i = 1, 40 do
        local cur = UserInputService:GetMouseLocation()
        local tgtY = c.Y + 50
        local dx = c.X - cur.X
        local dy = tgtY - cur.Y
        if math.sqrt(dx*dx + dy*dy) < 3 then break end
        pcall(function() mousemoverel(math.clamp(dx, -25, 25), math.clamp(dy, -25, 25)) end)
        task.wait(0.03)
    end
    pcall(function() mouse1click() end)
    task.wait(0.3)
    if not isPopupOpen() then return true, "pc_click" end
    return false, "still_open"
end

local function acceptTrade()
    local btn = getAcceptButton()
    if not btn then return false, "no_popup" end
    if IS_PC then return clickAcceptPC(btn) else return clickAcceptMobile(btn) end
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
    frame.Size = UDim2.new(0, 460, 0, 420)
    frame.Position = UDim2.new(0, 20, 0, 20)
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
    title.Text = "Auto Trade v66 (" .. PLATFORM .. ")"
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
    statusLbl.Size = UDim2.new(0.9, 0, 0, 22)
    statusLbl.Position = UDim2.new(0.05, 0, 0, 0)
    statusLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    statusLbl.BorderSizePixel = 0
    statusLbl.Text = "Platform: " .. PLATFORM .. " | offsetY=" .. CONFIG.AcceptOffsetY
    statusLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 11
    statusLbl.Parent = body

    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0.9, 0, 0, 32)
    autoBtn.Position = UDim2.new(0.05, 0, 0, 26)
    autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    autoBtn.BorderSizePixel = 0
    autoBtn.Text = "AUTO ACCEPT: OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 11
    autoBtn.Parent = body

    local testBtn = Instance.new("TextButton")
    testBtn.Size = UDim2.new(0.9, 0, 0, 26)
    testBtn.Position = UDim2.new(0.05, 0, 0, 62)
    testBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
    testBtn.BorderSizePixel = 0
    testBtn.Text = "Test Accept (offsetY=60 + hiển thị chuột)"
    testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testBtn.Font = Enum.Font.GothamBold
    testBtn.TextSize = 11
    testBtn.Parent = body

    local infoBtn = Instance.new("TextButton")
    infoBtn.Size = UDim2.new(0.9, 0, 0, 24)
    infoBtn.Position = UDim2.new(0.05, 0, 0, 94)
    infoBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    infoBtn.BorderSizePixel = 0
    infoBtn.Text = "In info (inset, accept center)"
    infoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    infoBtn.Font = Enum.Font.GothamBold
    infoBtn.TextSize = 11
    infoBtn.Parent = body

    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.9, 0, 0, 240)
    logLbl.Position = UDim2.new(0.05, 0, 0, 124)
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
        statusLbl.Text = "Platform: " .. PLATFORM .. " | offsetY=" .. CONFIG.AcceptOffsetY .. " | " .. s
        if c then statusLbl.TextColor3 = c end
    end
    local function appendLog(s)
        local cur = logLbl.Text
        if #cur > 1500 then cur = cur:sub(-1200) end
        logLbl.Text = cur .. "\n" .. s
    end

    closeUI.MouseButton1Click:Connect(function() sg:Destroy() end)

    local enabled = false
    autoBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            autoBtn.Text = "AUTO ACCEPT (" .. PLATFORM .. "): ON"
            autoBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            setStatus("chờ popup", Color3.fromRGB(120,220,120))
        else
            autoBtn.Text = "AUTO ACCEPT (" .. PLATFORM .. "): OFF"
            autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
            setStatus("đã tắt", Color3.fromRGB(200,200,120))
        end
    end)

    testBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            local ok, r = acceptTrade()
            appendLog(ok and ("✔ Accept OK: " .. r) or ("✘ Fail: " .. tostring(r)))
            setStatus(ok and "OK" or "fail",
                ok and Color3.fromRGB(120,220,120) or Color3.fromRGB(255,120,120))
        end)
    end)

    infoBtn.MouseButton1Click:Connect(function()
        local tl = getInset()
        local btn = getAcceptButton()
        local c = btn and getCenter(btn)
        print("========== INFO v66 ==========")
        print("Platform:", PLATFORM)
        print("TopLeftInset:", tl.X, tl.Y)
        if c then
            print("Accept center (viewport):", c.X, c.Y)
            print("Touch pos (với offsetY=60):", c.X, c.Y + CONFIG.AcceptOffsetY)
        end
        print("=============================")
        appendLog("info F9")
    end)

    task.spawn(function()
        local wasOpen = false
        while sg.Parent do
            if enabled then
                local tr = getTradeRequestFrame()
                local nowOpen = tr ~= nil and tr.Visible == true
                if nowOpen and not wasOpen then
                    setStatus("popup - accept", Color3.fromRGB(200,200,120))
                    appendLog("popup hiện")
                    task.wait(0.2)
                    local ok, r = acceptTrade()
                    appendLog(ok and ("✔ " .. r) or ("✘ " .. tostring(r)))
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
log("v66 sẵn sàng. Mobile offsetY=60. Chuột ảo sync với touch.")
