--[[
    Auto Trade - Rock Fruit v64 (Mobile Virtual Mouse)
    Game ID: 119091355492870

    LÝ DO LỖI Ở v63.1:
      - Lỗi cú pháp đã được fix, nhưng log bị ĐỨT ở dòng
        "Targets in Accept ---".
      - Nguyên nhân: Hàm getAllAcceptTargets() gọi
        `folder:GetDescendants()` - nếu folder Accept có
        chứa nhiều item (hàng trăm), vòng lặp sẽ bị treo
        (yield) hoặc tràn bộ nhớ tạm.
      - Hoặc `btn` bị nil do logic tìm button sai.

    GIẢI PHÁP v64:
      1. Không dùng GetDescendants() bừa bãi.
      2. Chỉ lấy trực tiếp: btn = Accept.Accept
      3. Nếu btn = nil -> báo lỗi rõ ràng.
      4. Tạo CHUỘT ẢO (một Frame màu đỏ) hiển thị trên
         màn hình để bạn thấy nó đang nhắm vào đâu.
      5. Thử click bằng 3 cách: firetouchinterest,
         VirtualInputManager, firesignal.
      6. Bọc toàn bộ trong pcall để không bị crash.
]]

local CONFIG = {
    GameID          = 119091355492870,
    Debug           = true,
    SafeMarginTop   = 80,
    SafeMarginRight = 80,
}

local Players               = game:GetService("Players")
local CoreGui               = game:GetService("CoreGui")
local UserInputService      = game:GetService("UserInputService")
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
log("Platform:", PLATFORM)

-- ============================================================
-- TÌM NÚT ACCEPT (CHUẨN XÁC, KHÔNG QUÉT BỪA)
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
    if not tr or not tr.Visible then return nil end
    local sub = tr:FindFirstChild("Sub")
    if not sub then return nil end
    local m = sub:FindFirstChild("Main")
    if not m then return nil end
    local acc = m:FindFirstChild("Accept")
    if not acc then return nil end
    return acc:FindFirstChild("Accept") -- Đây là ImageButton
end

local function getCenter(btn)
    if not btn then return nil end
    local ok, ap = pcall(function() return btn.AbsolutePosition end)
    local ok2, sz = pcall(function() return btn.AbsoluteSize end)
    if ok and ok2 and ap and sz then
        return Vector2.new(ap.X + sz.X / 2, ap.Y + sz.Y / 2)
    end
    return nil
end

-- ============================================================
-- TẠO CHUỘT ẢO (VISUAL CURSOR)
-- ============================================================
local virtualCursor = nil

local function showVirtualMouse(x, y)
    if not virtualCursor or not virtualCursor.Parent then
        local sg = Instance.new("ScreenGui")
        sg.Name = "HoangVirtualMouse"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        sg.Parent = CoreGui
        
        local frame = Instance.new("Frame")
        frame.Name = "Cursor"
        frame.Size = UDim2.new(0, 30, 0, 30)
        frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        frame.BackgroundTransparency = 0.5
        frame.BorderSizePixel = 2
        frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
        frame.ZIndex = 999999
        frame.Parent = sg
        
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 6, 0, 6)
        dot.Position = UDim2.new(0.5, -3, 0.5, -3)
        dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        dot.BorderSizePixel = 0
        dot.ZIndex = 1000000
        dot.Parent = frame
        
        virtualCursor = frame
    end
    virtualCursor.Position = UDim2.new(0, x - 15, 0, y - 15)
    virtualCursor.Visible = true
end

local function hideVirtualMouse()
    if virtualCursor then
        virtualCursor.Visible = false
    end
end

-- ============================================================
-- CLICK (MOBILE + PC)
-- ============================================================
local function isPopupOpen()
    local tr = getTradeRequestFrame()
    return tr ~= nil and tr.Visible == true
end

local function clickMobile(btn)
    local c = getCenter(btn)
    if not c then return false, "no_center" end
    
    showVirtualMouse(c.X, c.Y)
    task.wait(0.3) -- Cho bạn thấy chuột ảo ở đó
    
    -- Cách 1: FireTouchInterest
    if firetouchinterest then
        log("  [1] firetouchinterest")
        pcall(function()
            firetouchinterest(btn, c, 0)
            task.wait(0.15)
            firetouchinterest(btn, c, 1)
        end)
        task.wait(0.3)
        if not isPopupOpen() then hideVirtualMouse(); return true, "touch" end
    end

    -- Cách 2: VirtualInputManager
    if VirtualInputManager then
        log("  [2] VirtualInputManager")
        pcall(function()
            VirtualInputManager:SendMouseMoveEvent(math.floor(c.X), math.floor(c.Y), game)
        end)
        task.wait(0.2)
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(math.floor(c.X), math.floor(c.Y), 0, true, game, 0)
        end)
        task.wait(0.15)
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(math.floor(c.X), math.floor(c.Y), 0, false, game, 0)
        end)
        task.wait(0.3)
        if not isPopupOpen() then hideVirtualMouse(); return true, "vim" end
    end

    -- Cách 3: FireSignal
    if typeof(firesignal) == "function" then
        log("  [3] firesignal")
        pcall(function()
            firesignal(btn.MouseButton1Down)
            task.wait(0.1)
            firesignal(btn.MouseButton1Up)
            task.wait(0.1)
            firesignal(btn.MouseButton1Click)
        end)
        task.wait(0.3)
        if not isPopupOpen() then hideVirtualMouse(); return true, "firesignal" end
    end

    hideVirtualMouse()
    return false, "all_fail"
end

local function clickPC(btn)
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
    if IS_PC then return clickPC(btn) else return clickMobile(btn) end
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
    title.Text = "Auto Trade v64 (" .. PLATFORM .. ")"
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
    statusLbl.Text = "Platform: " .. PLATFORM
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
    testBtn.Text = "Test Accept (hiển thị chuột ảo)"
    testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testBtn.Font = Enum.Font.GothamBold
    testBtn.TextSize = 11
    testBtn.Parent = body

    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.9, 0, 0, 240)
    logLbl.Position = UDim2.new(0.05, 0, 0, 94)
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
        statusLbl.Text = "Platform: " .. PLATFORM .. " | " .. s
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

    task.spawn(function()
        local wasOpen = false
        while sg.Parent do
            if enabled then
                local tr = getTradeRequestFrame()
                local nowOpen = tr ~= nil and tr.Visible == true
                if nowOpen and not wasOpen then
                    setStatus("popup - đang accept", Color3.fromRGB(200,200,120))
                    appendLog("Phát hiện popup...")
                    task.wait(0.2)
                    local ok, r = acceptTrade()
                    appendLog(ok and ("✔ Accept: " .. r) or ("✘ Fail: " .. tostring(r)))
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
log("v64 sẵn sàng. Mobile: hiển thị chuột ảo, thử 3 cách.")
