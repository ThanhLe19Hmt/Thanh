--[[
    Auto Trade - Rock Fruit v68 (Drag & Drop Target)
    Game ID: 119091355492870

    Ý TƯỞNG TỪ BẠN:
      - Tạo 1 mục đen (Frame) có thể kéo thả tự do trên màn hình.
      - Bạn kéo nó tới đúng nút Accept (chấm vào vị trí bấm).
      - Bật Auto, khi popup trade hiện lên, tool tự bấm vào
        vị trí mà mục đen đang nằm.
      - Không cần biết nút Accept ở đâu, không cần offset.

    VẤN ĐỀ CẦN GIẢI QUYẾT:
      1. Lưu toạ độ của mục đen như thế nào?
         - Nếu Frame.IgnoreGuiInset = false (dùng viewport):
           toạ độ Frame.Position.AbsolutePosition là viewport.
         - Touch dùng viewport -> khớp -> lưu AbsolutePosition là đủ.
      2. Khi bật auto, không cần tìm nút Accept nữa.
         - Chỉ cần kiểm tra popup Trade_Request.Visible = true.
         - Dùng firetouchinterest vào toạ độ đã lưu.
         - firetouchinterest cần đối tượng GuiButton -> ta vẫn
           cần tìm nút Accept (hoặc tạo wrapper GuiButton tại
           toạ độ đó).

    GIẢI PHÁP v68:
      1. Tạo Frame đen 60x60 (kéo thả được, active = true).
      2. Có nút "LƯU VỊ TRÍ" -> lưu tâm Frame đen (AbsolutePosition).
      3. Có nút "TEST" -> bấm thử tại toạ độ đã lưu (không cần
         popup, dùng bất kỳ lúc nào).
      4. Có nút "AUTO: ON" -> khi popup trade hiện, tìm nút Accept
         (để có đối tượng GuiButton) và firetouchinterest vào
         toạ độ đã lưu (không phải toạ độ nút Accept).
      5. Nếu firetouchinterest thất bại -> thử VIM tại toạ độ đó.

    LƯU Ý QUAN TRỌNG:
      - firetouchinterest(btn, pos, state) BẮT BUỘC cần btn là
        GuiButton thật. Nên ta vẫn phải tìm nút Accept.
      - Nhưng POS ta truyền vào là toạ độ mục đen (đã lưu),
        không phải toạ độ nút -> khớp với vị trí bạn muốn.
      - Nếu firetouchinterest không nhận pos tuỳ ý (chỉ nhận
        trong vùng btn), ta sẽ tạo 1 TextButton vô hình tại
        đúng toạ độ mục đen -> firetouchinterest vào đó.
]]

local CONFIG = {
    GameID          = 119091355492870,
    Debug           = true,
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
local savedX = nil
local savedY = nil
local savedInsetX = 0
local savedInsetY = 0
local autoEnabled = false

-- ============================================================
-- MAIN UI
-- ============================================================
local function buildUI()
    local old = CoreGui:FindFirstChild("HoangAutoTradeUI")
    if old then old:Destroy() end
    local oldDrag = CoreGui:FindFirstChild("HoangDragTarget")
    if oldDrag then oldDrag:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "HoangAutoTradeUI"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 340, 0, 300)
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
    title.Text = "Auto Trade v68 (Drag Target)"
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
    statusLbl.Size = UDim2.new(0.9, 0, 0, 26)
    statusLbl.Position = UDim2.new(0.05, 0, 0, 0)
    statusLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    statusLbl.BorderSizePixel = 0
    statusLbl.Text = "Chưa lưu vị trí. Kéo ô đen vào nút Accept."
    statusLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 11
    statusLbl.TextWrapped = true
    statusLbl.Parent = body

    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.9, 0, 0, 32)
    saveBtn.Position = UDim2.new(0.05, 0, 0, 32)
    saveBtn.BackgroundColor3 = Color3.fromRGB(200, 130, 40)
    saveBtn.BorderSizePixel = 0
    saveBtn.Text = "1) LƯU VỊ TRÍ ô đen"
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 12
    saveBtn.Parent = body

    local testBtn = Instance.new("TextButton")
    testBtn.Size = UDim2.new(0.9, 0, 0, 32)
    testBtn.Position = UDim2.new(0.05, 0, 0, 70)
    testBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
    testBtn.BorderSizePixel = 0
    testBtn.Text = "2) TEST bấm tại vị trí đã lưu"
    testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testBtn.Font = Enum.Font.GothamBold
    testBtn.TextSize = 12
    testBtn.Parent = body

    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0.9, 0, 0, 32)
    autoBtn.Position = UDim2.new(0.05, 0, 0, 108)
    autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    autoBtn.BorderSizePixel = 0
    autoBtn.Text = "3) AUTO ACCEPT: OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 12
    autoBtn.Parent = body

    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(0.9, 0, 0, 24)
    resetBtn.Position = UDim2.new(0.05, 0, 0, 146)
    resetBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    resetBtn.BorderSizePixel = 0
    resetBtn.Text = "Reset ô đen về trung tâm"
    resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.TextSize = 11
    resetBtn.Parent = body

    local helpLbl = Instance.new("TextLabel")
    helpLbl.Size = UDim2.new(0.9, 0, 0, 110)
    helpLbl.Position = UDim2.new(0.05, 0, 0, 176)
    helpLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    helpLbl.BorderSizePixel = 0
    helpLbl.Text = [[
QUY TRÌNH:
1. Trên màn hình có 1 ô đen 60x60 kéo thả được.
2. Bạn kéo ô đen tới đúng nút Accept (chấm đỏ
   giữa ô đen là tâm bấm).
3. Bấm "1) LƯU VỊ TRÍ" -> lưu toạ độ tâm.
4. Bấm "2) TEST" -> bấm thử ngay (không cần popup).
5. Bấm "3) AUTO" -> khi popup trade hiện, tool
   tự bấm vào đúng toạ độ đã lưu.

Ô đen có chấm đỏ ở giữa = tâm bấm.
Bạn có thể kéo ô đen đi bất cứ đâu.
]]
    helpLbl.TextColor3 = Color3.fromRGB(200, 220, 200)
    helpLbl.Font = Enum.Font.Gotham
    helpLbl.TextSize = 10
    helpLbl.TextWrapped = true
    helpLbl.TextYAlignment = Enum.TextYAlignment.Top
    helpLbl.Parent = body

    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.9, 0, 0, 34)
    logLbl.Position = UDim2.new(0.05, 0, 0, 292)
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
    -- DRAG TARGET (ô đen)
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
    -- BẤM THỬ TẠI VỊ TRÍ ĐÃ LƯU
    -- ============================================================
    local function getSavedPoint()
        if not savedX or not savedY then return nil end
        return Vector2.new(savedX, savedY)
    end

    local function fireTouchAtSaved()
        local pos = getSavedPoint()
        if not pos then return false, "chưa lưu vị trí" end
        local btn = getAcceptButton()
        -- Nếu không có nút Accept, tạo wrapper
        local targetBtn = btn
        local wrapSg = nil
        if not targetBtn then
            wrapSg = Instance.new("ScreenGui")
            wrapSg.Name = "HoangWrapTouch"
            wrapSg.ResetOnSpawn = false
            wrapSg.IgnoreGuiInset = false
            wrapSg.Parent = CoreGui
            targetBtn = Instance.new("TextButton")
            targetBtn.Size = UDim2.new(0, 40, 0, 40)
            targetBtn.Position = UDim2.new(0, pos.X - 20, 0, pos.Y - 20)
            targetBtn.BackgroundTransparency = 1
            targetBtn.Text = ""
            targetBtn.ZIndex = 999992
            targetBtn.Parent = wrapSg
        end
        local ok = false
        if firetouchinterest then
            log(string.format("firetouchinterest tại (%.0f, %.0f)", pos.X, pos.Y))
            pcall(function()
                firetouchinterest(targetBtn, pos, 0)
                task.wait(0.15)
                firetouchinterest(targetBtn, pos, 1)
            end)
            task.wait(0.3)
            ok = not isPopupOpen()
        end
        if wrapSg then
            task.wait(0.1)
            wrapSg:Destroy()
        end
        if ok then return true, "touch" end
        if VirtualInputManager then
            log(string.format("VIM tại (%.0f, %.0f)", pos.X, pos.Y))
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
            task.wait(0.3)
            if not isPopupOpen() then return true, "vim" end
        end
        return false, "fail"
    end

    -- ============================================================
    -- LƯU VỊ TRÍ
    -- ============================================================
    saveBtn.MouseButton1Click:Connect(function()
        local ap = dragFrame.AbsolutePosition
        local as = dragFrame.AbsoluteSize
        -- Vì IgnoreGuiInset = false -> AbsolutePosition là viewport
        -- (nhưng Roblox có thể tính cả inset nếu executor override)
        -- Để chắc chắn, lấy tâm
        savedX = ap.X + as.X / 2
        savedY = ap.Y + as.Y / 2
        local tl = getInset()
        savedInsetX = tl.X
        savedInsetY = tl.Y
        log(string.format("Lưu vị trí: viewport (%.1f, %.1f), inset (%.1f, %.1f)",
            savedX, savedY, savedInsetX, savedInsetY))
        setStatus(string.format("Đã lưu: (%.0f, %.0f) - viewport", savedX, savedY),
            Color3.fromRGB(120, 220, 120))
        appendLog(string.format("Lưu: (%.0f, %.0f)", savedX, savedY))
    end)

    testBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            local pos = getSavedPoint()
            if not pos then
                appendLog("Chưa lưu vị trí")
                return
            end
            appendLog("Test tại " .. string.format("(%.0f, %.0f)", pos.X, pos.Y))
            local ok, r = fireTouchAtSaved()
            if ok then
                appendLog("✔ OK: " .. r)
                setStatus("✔ Test OK: " .. r, Color3.fromRGB(120, 220, 120))
            else
                appendLog("✘ Fail: " .. r)
                setStatus("✘ Test fail: " .. r, Color3.fromRGB(255, 120, 120))
            end
        end)
    end)

    autoBtn.MouseButton1Click:Connect(function()
        if not savedX or not savedY then
            appendLog("Chưa lưu vị trí. Bấm 'LƯU VỊ TRÍ' trước.")
            return
        end
        autoEnabled = not autoEnabled
        if autoEnabled then
            autoBtn.Text = "3) AUTO ACCEPT: ON"
            autoBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            setStatus(string.format("Auto ON: (%.0f, %.0f)", savedX, savedY), Color3.fromRGB(120, 220, 120))
            appendLog("Auto bật")
        else
            autoBtn.Text = "3) AUTO ACCEPT: OFF"
            autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
            setStatus("Auto OFF", Color3.fromRGB(200, 200, 120))
            appendLog("Auto tắt")
        end
    end)

    resetBtn.MouseButton1Click:Connect(function()
        dragFrame.Position = UDim2.new(0.5, -30, 0.5, -30)
        appendLog("Reset ô đen về giữa")
    end)

    -- ============================================================
    -- LOOP TỰ ĐỘNG
    -- ============================================================
    task.spawn(function()
        local wasOpen = false
        while sg.Parent do
            if autoEnabled then
                local nowOpen = isPopupOpen()
                if nowOpen and not wasOpen then
                    appendLog("Auto: popup hiện, bấm tại vị trí đã lưu")
                    task.wait(0.2)
                    local ok, r = fireTouchAtSaved()
                    if ok then
                        appendLog("✔ Auto OK: " .. r)
                    else
                        appendLog("✘ Auto fail: " .. r)
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
log("v68 sẵn sàng. Kéo ô đen tới nút Accept, bấm LƯU, bật AUTO.")
