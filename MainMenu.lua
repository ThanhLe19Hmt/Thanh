--[[
    Auto Trade - Rock Fruit v69 (Absolute Position Fix)
    Game ID: 119091355492870

    PHÂN TÍCH LỖI v68:
      - Bạn kéo ô đen tới nút Accept -> hiển thị đúng.
      - Nhưng khi bấm -> lệch đi.
      - Nguyên nhân: `dragFrame.AbsolutePosition` trả về toạ độ
        SCREEN (đã bao gồm inset) do ScreenGui.IgnoreGuiInset=false,
        nhưng firetouchinterest lại nhận toạ độ VIEWPORT.
      - Kết quả: lưu screen -> touch tại screen -> lệch đúng
        bằng inset.Y.

    GIẢI PHÁP v69:
      1. Lưu cả 2 toạ độ:
         - `screenPos` = dragFrame.AbsolutePosition + size/2
         - `viewportPos` = screenPos - GuiService.TopLeftInset
      2. Thêm checkbox "Compensate Inset" - khi bật, tool dùng
         viewportPos thay vì screenPos khi firetouchinterest.
      3. Hiển thị rõ 2 toạ độ để bạn thấy chênh lệch bao nhiêu.
      4. Test sẽ thử lần lượt cả 2 toạ độ.
      5. Lưu chế độ hoạt động (screen hay viewport) khi tìm được.
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
-- STATE
-- ============================================================
local savedScreenX = nil
local savedScreenY = nil
local savedViewportX = nil
local savedViewportY = nil
local useViewport = false   -- sẽ set sau khi test
local autoEnabled = false

-- ============================================================
-- BẤM TẠI TOẠ ĐỘ
-- ============================================================
local function fireTouchAt(x, y)
    local btn = getAcceptButton()
    local wrapSg = nil
    local targetBtn = btn
    if not targetBtn then
        wrapSg = Instance.new("ScreenGui")
        wrapSg.Name = "HoangWrapTouch"
        wrapSg.ResetOnSpawn = false
        wrapSg.IgnoreGuiInset = false
        wrapSg.Parent = CoreGui
        targetBtn = Instance.new("TextButton")
        targetBtn.Size = UDim2.new(0, 40, 0, 40)
        targetBtn.Position = UDim2.new(0, x - 20, 0, y - 20)
        targetBtn.BackgroundTransparency = 1
        targetBtn.Text = ""
        targetBtn.ZIndex = 999992
        targetBtn.Parent = wrapSg
    end
    if firetouchinterest then
        log(string.format("  firetouchinterest (%.1f, %.1f)", x, y))
        pcall(function()
            firetouchinterest(targetBtn, Vector2.new(x, y), 0)
            task.wait(0.15)
            firetouchinterest(targetBtn, Vector2.new(x, y), 1)
        end)
        task.wait(0.3)
        local ok = not isPopupOpen()
        if wrapSg then task.wait(0.1); wrapSg:Destroy() end
        if ok then return true, "touch" end
    elseif wrapSg then
        wrapSg:Destroy()
    end
    if VirtualInputManager then
        log(string.format("  VIM (%.1f, %.1f)", x, y))
        pcall(function()
            VirtualInputManager:SendMouseMoveEvent(math.floor(x), math.floor(y), game)
        end)
        task.wait(0.2)
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(math.floor(x), math.floor(y), 0, true, game, 0)
        end)
        task.wait(0.15)
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(math.floor(x), math.floor(y), 0, false, game, 0)
        end)
        task.wait(0.3)
        if not isPopupOpen() then return true, "vim" end
    end
    return false, "fail"
end

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
    title.Text = "Auto Trade v69 (Inset Fix)"
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
    infoLbl.Size = UDim2.new(0.95, 0, 0, 60)
    infoLbl.Position = UDim2.new(0.025, 0, 0, 36)
    infoLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    infoLbl.BorderSizePixel = 0
    infoLbl.Text = "Screen: ?\nViewport: ?\nInset: ?"
    infoLbl.TextColor3 = Color3.fromRGB(180, 220, 255)
    infoLbl.Font = Enum.Font.Code
    infoLbl.TextSize = 11
    infoLbl.TextWrapped = true
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left
    infoLbl.TextYAlignment = Enum.TextYAlignment.Top
    infoLbl.Parent = body

    -- Nút lưu
    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.95, 0, 0, 32)
    saveBtn.Position = UDim2.new(0.025, 0, 0, 100)
    saveBtn.BackgroundColor3 = Color3.fromRGB(200, 130, 40)
    saveBtn.BorderSizePixel = 0
    saveBtn.Text = "1) LƯU VỊ TRÍ ô đen"
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 12
    saveBtn.Parent = body

    -- Nút test screen
    local testScreenBtn = Instance.new("TextButton")
    testScreenBtn.Size = UDim2.new(0.47, 0, 0, 30)
    testScreenBtn.Position = UDim2.new(0.025, 0, 0, 138)
    testScreenBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
    testScreenBtn.BorderSizePixel = 0
    testScreenBtn.Text = "2a) TEST Screen"
    testScreenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testScreenBtn.Font = Enum.Font.GothamBold
    testScreenBtn.TextSize = 11
    testScreenBtn.Parent = body

    -- Nút test viewport
    local testVpBtn = Instance.new("TextButton")
    testVpBtn.Size = UDim2.new(0.47, 0, 0, 30)
    testVpBtn.Position = UDim2.new(0.505, 0, 0, 138)
    testVpBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 60)
    testVpBtn.BorderSizePixel = 0
    testVpBtn.Text = "2b) TEST Viewport"
    testVpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testVpBtn.Font = Enum.Font.GothamBold
    testVpBtn.TextSize = 11
    testVpBtn.Parent = body

    -- Nút auto
    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0.95, 0, 0, 32)
    autoBtn.Position = UDim2.new(0.025, 0, 0, 174)
    autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    autoBtn.BorderSizePixel = 0
    autoBtn.Text = "3) AUTO ACCEPT: OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 12
    autoBtn.Parent = body

    -- Nút reset
    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(0.95, 0, 0, 24)
    resetBtn.Position = UDim2.new(0.025, 0, 0, 212)
    resetBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    resetBtn.BorderSizePixel = 0
    resetBtn.Text = "Reset ô đen về giữa"
    resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.TextSize = 11
    resetBtn.Parent = body

    local helpLbl = Instance.new("TextLabel")
    helpLbl.Size = UDim2.new(0.95, 0, 0, 100)
    helpLbl.Position = UDim2.new(0.025, 0, 0, 242)
    helpLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    helpLbl.BorderSizePixel = 0
    helpLbl.Text = [[
QUY TRÌNH:
1. Kéo ô đen tới nút Accept (chấm đỏ = tâm).
2. Bấm "LƯU VỊ TRÍ" - tool lưu CẢ screen + viewport.
3. Khi popup hiện, bấm "TEST Screen" hoặc "TEST Viewport"
   - cái nào đóng được popup thì dùng cái đó.
4. Bấm "AUTO" - tool dùng chế độ đã test thành công.

Nếu cả 2 fail -> kéo ô đen chỉnh vài px, lưu lại.
]]
    helpLbl.TextColor3 = Color3.fromRGB(200, 220, 200)
    helpLbl.Font = Enum.Font.Gotham
    helpLbl.TextSize = 10
    helpLbl.TextWrapped = true
    helpLbl.TextYAlignment = Enum.TextYAlignment.Top
    helpLbl.Parent = body

    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.95, 0, 0, 60)
    logLbl.Position = UDim2.new(0.025, 0, 0, 348)
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

    -- ============================================================
    -- UPDATE INFO
    -- ============================================================
    local function refreshInfo()
        local ap = dragFrame.AbsolutePosition
        local as = dragFrame.AbsoluteSize
        local centerScreenX = ap.X + as.X / 2
        local centerScreenY = ap.Y + as.Y / 2
        local tl = getInset()
        local vpX = centerScreenX - tl.X
        local vpY = centerScreenY - tl.Y
        infoLbl.Text = string.format(
            "Screen: (%.1f, %.1f)\nViewport: (%.1f, %.1f)\nInset: (%.1f, %.1f)",
            centerScreenX, centerScreenY, vpX, vpY, tl.X, tl.Y)
        return centerScreenX, centerScreenY, vpX, vpY
    end

    task.spawn(function()
        while sg.Parent do
            refreshInfo()
            task.wait(0.15)
        end
    end)

    -- ============================================================
    -- EVENTS
    -- ============================================================
    saveBtn.MouseButton1Click:Connect(function()
        local sx, sy, vx, vy = refreshInfo()
        savedScreenX = sx
        savedScreenY = sy
        savedViewportX = vx
        savedViewportY = vy
        log(string.format("Lưu Screen (%.1f, %.1f), Viewport (%.1f, %.1f)",
            sx, sy, vx, vy))
        setStatus(string.format("Đã lưu. Test 2a (screen) hoặc 2b (viewport)."),
            Color3.fromRGB(120, 220, 120))
        appendLog(string.format("Lưu S(%.0f,%.0f) V(%.0f,%.0f)", sx, sy, vx, vy))
    end)

    testScreenBtn.MouseButton1Click:Connect(function()
        if not savedScreenX then appendLog("Chưa lưu"); return end
        task.spawn(function()
            appendLog(string.format("Test Screen (%.0f,%.0f)", savedScreenX, savedScreenY))
            local ok, r = fireTouchAt(savedScreenX, savedScreenY)
            if ok then
                useViewport = false
                appendLog("✔ Screen OK -> dùng Screen cho AUTO")
                setStatus("✔ Screen OK - bật AUTO được rồi", Color3.fromRGB(120, 220, 120))
            else
                appendLog("✘ Screen fail")
                setStatus("✘ Screen fail - thử Viewport", Color3.fromRGB(255, 120, 120))
            end
        end)
    end)

    testVpBtn.MouseButton1Click:Connect(function()
        if not savedViewportX then appendLog("Chưa lưu"); return end
        task.spawn(function()
            appendLog(string.format("Test Viewport (%.0f,%.0f)", savedViewportX, savedViewportY))
            local ok, r = fireTouchAt(savedViewportX, savedViewportY)
            if ok then
                useViewport = true
                appendLog("✔ Viewport OK -> dùng Viewport cho AUTO")
                setStatus("✔ Viewport OK - bật AUTO được rồi", Color3.fromRGB(120, 220, 120))
            else
                appendLog("✘ Viewport fail")
                setStatus("✘ Viewport fail - thử Screen", Color3.fromRGB(255, 120, 120))
            end
        end)
    end)

    autoBtn.MouseButton1Click:Connect(function()
        if not savedScreenX then appendLog("Chưa lưu"); return end
        autoEnabled = not autoEnabled
        if autoEnabled then
            autoBtn.Text = "3) AUTO ACCEPT: ON (" .. (useViewport and "VP" or "S") .. ")"
            autoBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            setStatus("AUTO ON: " .. (useViewport and "viewport" or "screen"),
                Color3.fromRGB(120, 220, 120))
            appendLog("Auto ON: " .. (useViewport and "VP" or "S"))
        else
            autoBtn.Text = "3) AUTO ACCEPT: OFF"
            autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
            setStatus("Auto OFF", Color3.fromRGB(200, 200, 120))
        end
    end)

    resetBtn.MouseButton1Click:Connect(function()
        dragFrame.Position = UDim2.new(0.5, -30, 0.5, -30)
    end)

    -- Auto loop
    task.spawn(function()
        local wasOpen = false
        while sg.Parent do
            if autoEnabled and savedScreenX then
                local nowOpen = isPopupOpen()
                if nowOpen and not wasOpen then
                    appendLog("Auto: popup hiện")
                    task.wait(0.2)
                    local x = useViewport and savedViewportX or savedScreenX
                    local y = useViewport and savedViewportY or savedScreenY
                    local ok, r = fireTouchAt(x, y)
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
log("v69 sẵn sàng. Lưu vị trí, test Screen hoặc Viewport, chọn cái ăn.")
