--[[
    Auto Trade - Rock Fruit v73 (Last Resort)
    Game ID: 119091355492870

    TRẠNG THÁI HIỆN TẠI:
      - v72 đã hiển thị chấm đỏ đúng vị trí.
      - Nhưng khi bấm (touchViaWrapper) -> popup KHÔNG đóng.
      - Nghĩa là wrapper TextButton không kích hoạt được nút Accept.

    TẠI SAO WRAPPER FAIL:
      - Wrapper được tạo trong ScreenGui của script.
      - Game Rock Fruit có thể kiểm tra `GuiButton.Parent` phải
        nằm trong `HUD.Main` mới nhận touch.
      - Hoặc wrapper không được kế thừa quyền nhận touch của
        nút Accept thật.

    GIẢI PHÁP v73:
      1. Thử `firetouchinterest(AcceptButton, pos)` trực tiếp
         (không qua wrapper). Nếu executor bỏ qua pos, đây
         vẫn fail, nhưng thử lại.
      2. Thử `VirtualInputManager` tại toạ độ chấm đỏ.
      3. Thử tạo wrapper là CON của nút Accept (cùng cha) -
         wrapper.Parent = AcceptButton.Parent.
      4. Thử tạo wrapper là CON của HUD.Main (cùng cha với
         Trade_Request).
      5. Thử firetouchinterest trên AcceptButton với pos
         được tính lại = pos - AcceptButton.AbsolutePosition.
      6. Thử dùng `firesignal` trên AcceptButton với
         MouseButton1Down/Up (không cần toạ độ nhưng vẫn
         trigger logic của nút nếu game dùng signal).
      7. Nếu tất cả fail -> kết luận: executor sandbox quá
         sâu, không thể auto accept từ Lua. Chỉ còn AHK hoặc
         app Auto Clicker ngoài.
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
    visualGui.IgnoreGuiInset = false
    visualGui.Parent = CoreGui
    visualDot = Instance.new("Frame")
    visualDot.Size = UDim2.new(0, 14, 0, 14)
    visualDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    visualDot.BackgroundTransparency = 0.2
    visualDot.BorderSizePixel = 2
    visualDot.BorderColor3 = Color3.fromRGB(255, 255, 255)
    visualDot.ZIndex = 999995
    visualDot.Visible = false
    visualDot.Parent = visualGui
end

local function showVisual(x, y)
    ensureVisual()
    visualDot.Position = UDim2.new(0, x - 7, 0, y - 7)
    visualDot.Visible = true
end

local function hideVisual()
    if visualDot then visualDot.Visible = false end
end

-- ============================================================
-- CÁCH 1: firetouchinterest TRỰC TIẾP vào Accept
-- ============================================================
local function methodDirectTouch(x, y)
    local btn = getAcceptButton()
    if not btn or not firetouchinterest then return false, "no_btn_or_touch" end
    log(string.format("[1] Direct firetouchinterest(Accept, %.0f, %.0f)", x, y))
    pcall(function()
        firetouchinterest(btn, Vector2.new(x, y), 0)
        task.wait(0.15)
        firetouchinterest(btn, Vector2.new(x, y), 1)
    end)
    task.wait(0.3)
    if not isPopupOpen() then return true, "direct_touch" end
    return false, "fail"
end

-- ============================================================
-- CÁCH 2: firetouchinterest với pos tương đối
-- ============================================================
local function methodRelativeTouch(x, y)
    local btn = getAcceptButton()
    if not btn or not firetouchinterest then return false, "no_btn_or_touch" end
    local ap = btn.AbsolutePosition
    local relX = x - ap.X
    local relY = y - ap.Y
    log(string.format("[2] Relative firetouchinterest(rel %.0f, %.0f)", relX, relY))
    pcall(function()
        firetouchinterest(btn, Vector2.new(relX, relY), 0)
        task.wait(0.15)
        firetouchinterest(btn, Vector2.new(relX, relY), 1)
    end)
    task.wait(0.3)
    if not isPopupOpen() then return true, "relative_touch" end
    return false, "fail"
end

-- ============================================================
-- CÁCH 3: VirtualInputManager
-- ============================================================
local function methodVIM(x, y)
    if not VirtualInputManager then return false, "no_vim" end
    log(string.format("[3] VIM(%.0f, %.0f)", x, y))
    local ix, iy = math.floor(x), math.floor(y)
    pcall(function()
        VirtualInputManager:SendMouseMoveEvent(ix, iy, game)
    end)
    task.wait(0.25)
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
-- CÁCH 4: wrapper cùng cha với Accept
-- ============================================================
local function methodWrapperSameParent(x, y)
    local btn = getAcceptButton()
    if not btn or not firetouchinterest then return false, "no_btn" end
    local parent = btn.Parent
    log(string.format("[4] Wrapper trong parent của Accept"))
    local wrap = Instance.new("TextButton")
    wrap.Size = UDim2.new(0, 60, 0, 60)
    wrap.Position = UDim2.new(0, x - 30, 0, y - 30)
    wrap.BackgroundTransparency = 1
    wrap.Text = ""
    wrap.Active = true
    wrap.ZIndex = 999992
    wrap.Parent = parent
    task.wait(0.1)
    local ok, r
    pcall(function()
        firetouchinterest(wrap, Vector2.new(x, y), 0)
        task.wait(0.15)
        firetouchinterest(wrap, Vector2.new(x, y), 1)
    end)
    task.wait(0.3)
    ok = not isPopupOpen()
    pcall(function() wrap:Destroy() end)
    if ok then return true, "wrapper_same_parent" end
    return false, "fail"
end

-- ============================================================
-- CÁCH 5: firesignal trên Accept (không cần pos)
-- ============================================================
local function methodFiresignal(x, y)
    local btn = getAcceptButton()
    if not btn or typeof(firesignal) ~= "function" then return false, "no_firesignal" end
    log("[5] firesignal Accept Down/Up/Click")
    pcall(function()
        firesignal(btn.MouseButton1Down)
        task.wait(0.1)
        firesignal(btn.MouseButton1Up)
        task.wait(0.1)
        firesignal(btn.MouseButton1Click)
        task.wait(0.1)
        firesignal(btn.Activated)
    end)
    task.wait(0.35)
    if not isPopupOpen() then return true, "firesignal" end
    return false, "fail"
end

-- ============================================================
-- TỔNG HỢP
-- ============================================================
local function tryAllMethods(x, y)
    showVisual(x, y)
    task.wait(0.15)
    
    local methods = {
        {"direct_touch", methodDirectTouch},
        {"relative_touch", methodRelativeTouch},
        {"vim", methodVIM},
        {"wrapper_same_parent", methodWrapperSameParent},
        {"firesignal", methodFiresignal},
    }
    for _, m in ipairs(methods) do
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
local baseX = nil
local baseY = nil
local offsetX = 0
local offsetY = 0
local autoEnabled = false
local dragFrame = nil

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
    frame.Size = UDim2.new(0, 380, 0, 520)
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
    title.Text = "Auto Trade v73 (All Methods)"
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
    statusLbl.Text = "Kéo ô đen, thử lần lượt 5 cách bấm."
    statusLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 11
    statusLbl.TextWrapped = true
    statusLbl.Parent = body

    local infoLbl = Instance.new("TextLabel")
    infoLbl.Size = UDim2.new(0.95, 0, 0, 46)
    infoLbl.Position = UDim2.new(0.025, 0, 0, 36)
    infoLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    infoLbl.BorderSizePixel = 0
    infoLbl.Text = "Chưa lưu vị trí."
    infoLbl.TextColor3 = Color3.fromRGB(180, 220, 255)
    infoLbl.Font = Enum.Font.Code
    infoLbl.TextSize = 11
    infoLbl.TextWrapped = true
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left
    infoLbl.TextYAlignment = Enum.TextYAlignment.Top
    infoLbl.Parent = body

    local offsetXLabel = Instance.new("TextLabel")
    offsetXLabel.Size = UDim2.new(0.3, 0, 0, 26)
    offsetXLabel.Position = UDim2.new(0.025, 0, 0, 86)
    offsetXLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    offsetXLabel.BorderSizePixel = 0
    offsetXLabel.Text = "Offset X"
    offsetXLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    offsetXLabel.Font = Enum.Font.Gotham
    offsetXLabel.TextSize = 11
    offsetXLabel.Parent = body

    local offsetXBox = Instance.new("TextBox")
    offsetXBox.Size = UDim2.new(0.15, 0, 0, 26)
    offsetXBox.Position = UDim2.new(0.34, 0, 0, 86)
    offsetXBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    offsetXBox.BorderSizePixel = 0
    offsetXBox.Text = "0"
    offsetXBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    offsetXBox.Font = Enum.Font.Gotham
    offsetXBox.TextSize = 12
    offsetXBox.Parent = body

    local offsetYLabel = Instance.new("TextLabel")
    offsetYLabel.Size = UDim2.new(0.3, 0, 0, 26)
    offsetYLabel.Position = UDim2.new(0.51, 0, 0, 86)
    offsetYLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    offsetYLabel.BorderSizePixel = 0
    offsetYLabel.Text = "Offset Y"
    offsetYLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    offsetYLabel.Font = Enum.Font.Gotham
    offsetYLabel.TextSize = 11
    offsetYLabel.Parent = body

    local offsetYBox = Instance.new("TextBox")
    offsetYBox.Size = UDim2.new(0.15, 0, 0, 26)
    offsetYBox.Position = UDim2.new(0.825, 0, 0, 86)
    offsetYBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    offsetYBox.BorderSizePixel = 0
    offsetYBox.Text = "0"
    offsetYBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    offsetYBox.Font = Enum.Font.Gotham
    offsetYBox.TextSize = 12
    offsetYBox.Parent = body

    local applyOffsetBtn = Instance.new("TextButton")
    applyOffsetBtn.Size = UDim2.new(0.95, 0, 0, 26)
    applyOffsetBtn.Position = UDim2.new(0.025, 0, 0, 116)
    applyOffsetBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    applyOffsetBtn.BorderSizePixel = 0
    applyOffsetBtn.Text = "Áp dụng offset"
    applyOffsetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyOffsetBtn.Font = Enum.Font.GothamBold
    applyOffsetBtn.TextSize = 11
    applyOffsetBtn.Parent = body

    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.95, 0, 0, 32)
    saveBtn.Position = UDim2.new(0.025, 0, 0, 148)
    saveBtn.BackgroundColor3 = Color3.fromRGB(200, 130, 40)
    saveBtn.BorderSizePixel = 0
    saveBtn.Text = "1) LƯU VỊ TRÍ ô đen"
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 12
    saveBtn.Parent = body

    local testBtn = Instance.new("TextButton")
    testBtn.Size = UDim2.new(0.95, 0, 0, 32)
    testBtn.Position = UDim2.new(0.025, 0, 0, 186)
    testBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
    testBtn.BorderSizePixel = 0
    testBtn.Text = "2) TEST (5 cách lần lượt)"
    testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testBtn.Font = Enum.Font.GothamBold
    testBtn.TextSize = 12
    testBtn.Parent = body

    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0.95, 0, 0, 32)
    autoBtn.Position = UDim2.new(0.025, 0, 0, 224)
    autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    autoBtn.BorderSizePixel = 0
    autoBtn.Text = "3) AUTO ACCEPT: OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 12
    autoBtn.Parent = body

    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(0.95, 0, 0, 24)
    resetBtn.Position = UDim2.new(0.025, 0, 0, 262)
    resetBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    resetBtn.BorderSizePixel = 0
    resetBtn.Text = "Reset ô đen"
    resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.TextSize = 11
    resetBtn.Parent = body

    local helpLbl = Instance.new("TextLabel")
    helpLbl.Size = UDim2.new(0.95, 0, 0, 140)
    helpLbl.Position = UDim2.new(0.025, 0, 0, 290)
    helpLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    helpLbl.BorderSizePixel = 0
    helpLbl.Text = [[
v73 thử 5 cách khi TEST:
1. Direct firetouchinterest vào Accept (dùng pos).
2. Relative firetouchinterest (pos - Accept.AbsolutePosition).
3. VirtualInputManager tại pos.
4. Wrapper TextButton trong parent của Accept.
5. firesignal Down/Up/Click (không cần pos).

Log F9 sẽ in rõ cách nào OK.
Nếu tất cả fail -> executor sandbox quá sâu,
không thể auto accept từ Lua.
]]
    helpLbl.TextColor3 = Color3.fromRGB(200, 220, 200)
    helpLbl.Font = Enum.Font.Gotham
    helpLbl.TextSize = 10
    helpLbl.TextWrapped = true
    helpLbl.TextYAlignment = Enum.TextYAlignment.Top
    helpLbl.Parent = body

    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.95, 0, 0, 70)
    logLbl.Position = UDim2.new(0.025, 0, 0, 438)
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
        if #cur > 460 then cur = cur:sub(-380) end
        logLbl.Text = cur .. "\n" .. s
    end

    closeUI.MouseButton1Click:Connect(function() sg:Destroy() end)

    local dragSg = Instance.new("ScreenGui")
    dragSg.Name = "HoangDragTarget"
    dragSg.ResetOnSpawn = false
    dragSg.IgnoreGuiInset = false
    dragSg.Parent = CoreGui

    dragFrame = Instance.new("Frame")
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

    local function refreshInfo()
        local ap = dragFrame.AbsolutePosition
        local as = dragFrame.AbsoluteSize
        local sx = ap.X + as.X / 2
        local sy = ap.Y + as.Y / 2
        local tl = getInset()
        local vx = sx - tl.X
        local vy = sy - tl.Y
        infoLbl.Text = string.format(
            "Screen: (%.1f, %.1f)\nViewport: (%.1f, %.1f)",
            sx, sy, vx, vy)
        return sx, sy, vx, vy
    end

    local function getCurrentBase()
        if baseX and baseY then return baseX, baseY end
        local _, _, vx, vy = refreshInfo()
        return vx, vy
    end

    task.spawn(function()
        while sg.Parent do
            refreshInfo()
            task.wait(0.15)
        end
    end)

    saveBtn.MouseButton1Click:Connect(function()
        local _, _, vx, vy = refreshInfo()
        baseX = vx
        baseY = vy
        appendLog(string.format("Lưu VP (%.0f,%.0f)", vx, vy))
        setStatus("Đã lưu. Nhập offset nếu cần. Bấm TEST.", Color3.fromRGB(120, 220, 120))
    end)

    applyOffsetBtn.MouseButton1Click:Connect(function()
        offsetX = tonumber(offsetXBox.Text) or 0
        offsetY = tonumber(offsetYBox.Text) or 0
        appendLog(string.format("Offset X=%d Y=%d", offsetX, offsetY))
        setStatus(string.format("Offset X=%d Y=%d", offsetX, offsetY), Color3.fromRGB(120, 220, 120))
    end)

    testBtn.MouseButton1Click:Connect(function()
        local bx, by = getCurrentBase()
        local tx = bx + offsetX
        local ty = by + offsetY
        task.spawn(function()
            appendLog(string.format("TEST tại (%.0f,%.0f)", tx, ty))
            local ok, r = tryAllMethods(tx, ty)
            if ok then
                appendLog("✔ OK: " .. r)
                setStatus("✔ OK: " .. r .. " - bật AUTO", Color3.fromRGB(120, 220, 120))
            else
                appendLog("✘ ALL FAIL")
                setStatus("✘ Tất cả cách fail - executor sandbox", Color3.fromRGB(255, 120, 120))
            end
        end)
    end)

    autoBtn.MouseButton1Click:Connect(function()
        autoEnabled = not autoEnabled
        if autoEnabled then
            autoBtn.Text = "3) AUTO ACCEPT: ON"
            autoBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            appendLog(string.format("Auto ON offset(%d,%d)", offsetX, offsetY))
            setStatus("Auto ON", Color3.fromRGB(120, 220, 120))
        else
            autoBtn.Text = "3) AUTO ACCEPT: OFF"
            autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
            appendLog("Auto OFF")
            setStatus("Auto OFF", Color3.fromRGB(200, 200, 120))
        end
    end)

    resetBtn.MouseButton1Click:Connect(function()
        dragFrame.Position = UDim2.new(0.5, -30, 0.5, -30)
        baseX = nil
        baseY = nil
        appendLog("Reset base=nil")
    end)

    task.spawn(function()
        local wasOpen = false
        while sg.Parent do
            if autoEnabled then
                local nowOpen = isPopupOpen()
                if nowOpen and not wasOpen then
                    appendLog("Auto: popup hiện")
                    task.wait(0.2)
                    local bx, by = getCurrentBase()
                    local tx = bx + offsetX
                    local ty = by + offsetY
                    local ok, r = tryAllMethods(tx, ty)
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
log("v73 sẵn sàng. TEST sẽ thử 5 cách, log cách nào OK.")
