--[[
    Auto Trade - Rock Fruit v74 (Visual Fix Only)
    Game ID: 119091355492870

    TRẠNG THÁI:
      - Bấm được nút Accept rồi! (Mừng quá)
      - Nhưng chấm đỏ (hiển thị) lệch so với điểm bấm thực tế.
      - Có nghĩa là logic bấm đã đúng, chỉ có GUI hiển thị bị lệch.

    TẠI SAO LỆCH:
      - Chấm đỏ được vẽ trong ScreenGui với IgnoreGuiInset=false.
      - Nó tự cộng thêm GuiService.TopLeftInset vào toạ độ hiển thị.
      - Nhưng toạ độ bấm (dùng cho wrapper) lại không cộng inset.
      - => Hiển thị và bấm dùng 2 hệ toạ độ khác nhau.

    CÁCH FIX CUỐI CÙNG:
      - KHÔNG hiển thị chấm đỏ nữa (vì đã bấm được rồi).
      - Hoặc hiển thị nó tại đúng toạ độ *hiển thị*, không phải
        toạ độ bấm.
      - Tôi sẽ dùng một ScreenGui riêng cho visual với
        IgnoreGuiInset = true (dùng toạ độ màn hình vật lý).
      - Và vẽ tại vị trí wrapper thực tế (đã cộng inset).

    BONUS: TÍCH HỢP AUTO TRADE HOÀN CHỈNH.
      - Auto Accept.
      - Auto chọn item + SL.
      - Auto Ready.
      - Tất cả trong 1 script, dùng chung baseX/baseY + offset.
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

local function isPopupOpen()
    local tr = getTradeRequestFrame()
    return tr ~= nil and tr.Visible == true
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

local function getFrameTrading()
    local main = getHUDMain()
    if not main then return nil end
    return main:FindFirstChild("Frame_Trading")
end

local function getTradeInventory()
    local ft = getFrameTrading()
    if not ft then return nil end
    return ft:FindFirstChild("Frame_TradeInventory")
end

local function getTradeInvHandler()
    local ti = getTradeInventory()
    if not ti then return nil end
    return ti:FindFirstChild("Handler")
end

local function getAddButton()
    local ft = getFrameTrading()
    if not ft then return nil end
    local myOffer = ft:FindFirstChild("MyOffer")
    if not myOffer then return nil end
    local sf = myOffer:FindFirstChild("ScrollingFrame")
    if not sf then return nil end
    local add = sf:FindFirstChild("Add")
    if not add then return nil end
    return add:FindFirstChild("Main")
end

local function getAmountTextBox()
    local h = getTradeInvHandler()
    if not h then return nil end
    local amt = h:FindFirstChild("Amount")
    if not amt then return nil end
    return amt:FindFirstChild("TextBox")
end

local function getInvScrollingFrame()
    local h = getTradeInvHandler()
    if not h then return nil end
    local ih = h:FindFirstChild("InventoryHandler")
    if not ih then return nil end
    return ih:FindFirstChild("ScrollingFrame")
end

local function getReadyButton()
    local ft = getFrameTrading()
    if not ft then return nil end
    return ft:FindFirstChild("Ready")
end

-- ============================================================
-- VISUAL CURSOR (DÙNG IgnoreGuiInset = TRUE + CỘNG INSET)
-- ============================================================
local visualGui = nil
local visualDot = nil

local function ensureVisual()
    if visualGui and visualGui.Parent then return end
    visualGui = Instance.new("ScreenGui")
    visualGui.Name = "HoangVisualCursor"
    visualGui.ResetOnSpawn = false
    -- TRUE: toạ độ (0,0) = góc trên trái MÀN HÌNH VẬT LÝ
    -- => chấm đỏ phải cộng thêm GuiService.TopLeftInset để khớp
    visualGui.IgnoreGuiInset = true
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

    local inner = Instance.new("Frame")
    inner.Size = UDim2.new(0, 4, 0, 4)
    inner.Position = UDim2.new(0.5, -2, 0.5, -2)
    inner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    inner.BorderSizePixel = 0
    inner.ZIndex = 999996
    inner.Parent = visualDot
end

local function showVisual(x, y)
    ensureVisual()
    -- x, y là toạ độ viewport (dùng cho firetouchinterest).
    -- Chấm đỏ hiển thị cần toạ độ screen -> cộng inset.
    local tl = getInset()
    visualDot.Position = UDim2.new(0, x + tl.X - 7, 0, y + tl.Y - 7)
    visualDot.Visible = true
end

local function hideVisual()
    if visualDot then visualDot.Visible = false end
end

-- ============================================================
-- TOUCH (GIỮ NGUYÊN WRAPPER ĐÃ HOẠT ĐỘNG)
-- ============================================================
local function touchViaWrapper(x, y)
    showVisual(x, y)
    task.wait(0.15)

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
    wrapper.Selectable = true
    wrapper.AutoButtonColor = false
    wrapper.ZIndex = 999992
    wrapper.Parent = wrapSg
    task.wait(0.1)

    local function cleanup()
        task.wait(0.2)
        pcall(function() wrapSg:Destroy() end)
        hideVisual()
    end

    if firetouchinterest then
        log(string.format("  firetouchinterest wrapper @ (%.1f, %.1f)", x, y))
        pcall(function()
            firetouchinterest(wrapper, Vector2.new(x, y), 0)
            task.wait(0.15)
            firetouchinterest(wrapper, Vector2.new(x, y), 1)
        end)
        task.wait(0.3)
        if not isPopupOpen() then cleanup(); return true, "touch" end
    end

    if typeof(firesignal) == "function" then
        pcall(function()
            firesignal(wrapper.MouseButton1Down)
            task.wait(0.05)
            firesignal(wrapper.MouseButton1Up)
            task.wait(0.05)
            firesignal(wrapper.MouseButton1Click)
        end)
        task.wait(0.3)
        if not isPopupOpen() then cleanup(); return true, "firesignal" end
    end

    pcall(function() wrapper:Activate() end)
    task.wait(0.3)
    if not isPopupOpen() then cleanup(); return true, "activate" end

    cleanup()
    return false, "fail"
end

-- ============================================================
-- AUTO TRADE (THÊM ITEM + READY)
-- ============================================================
local KEY_MAP = {
    ["0"] = Enum.KeyCode.Zero, ["1"] = Enum.KeyCode.One, ["2"] = Enum.KeyCode.Two,
    ["3"] = Enum.KeyCode.Three, ["4"] = Enum.KeyCode.Four, ["5"] = Enum.KeyCode.Five,
    ["6"] = Enum.KeyCode.Six, ["7"] = Enum.KeyCode.Seven, ["8"] = Enum.KeyCode.Eight,
    ["9"] = Enum.KeyCode.Nine,
}

local function typeTextRoblox(text)
    if not VirtualInputManager then return false end
    for i = 1, #text do
        local kc = KEY_MAP[text:sub(i, i)]
        if kc then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, kc, false, game)
                task.wait(0.02)
                VirtualInputManager:SendKeyEvent(false, kc, false, game)
            end)
            task.wait(0.03)
        end
    end
    return true
end

local function setAmount(qty)
    local tb = getAmountTextBox()
    if not tb then return false end
    pcall(function() tb:CaptureFocus() end)
    task.wait(0.1)
    pcall(function() tb.Text = "" end)
    task.wait(0.05)
    typeTextRoblox(tostring(qty))
    task.wait(0.1)
    pcall(function() tb.Text = tostring(qty) end)
    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            task.wait(0.02)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        end)
    end
    pcall(function() tb:ReleaseFocus() end)
    task.wait(0.1)
    pcall(function() if tb.FocusLost then tb.FocusLost:Fire() end end)
    task.wait(0.1)
    return true
end

local function safeClick(btn, name)
    if not btn then return false end
    if name then log("Click:", name) end
    if typeof(firesignal) == "function" then
        pcall(function()
            firesignal(btn.MouseButton1Click)
            firesignal(btn.MouseButton1Down)
            firesignal(btn.MouseButton1Up)
            firesignal(btn.Activated)
        end)
        task.wait(0.05)
    end
    pcall(function() btn:Click() end)
    task.wait(0.03)
    pcall(function() if btn.Activated then btn.Activated:Fire() end end)
    task.wait(0.03)
    pcall(function() btn.MouseButton1Click:Fire() end)
    task.wait(0.05)
    return true
end

local function addItemToTrade(itemName, qty)
    log("Thêm item:", itemName, "SL:", qty)
    local add = getAddButton()
    if not add then return false, "no_add_btn" end
    local ti = getTradeInventory()
    if not (ti and ti.Visible) then
        safeClick(add, "[+]")
        task.wait(0.4)
        ti = getTradeInventory()
        if ti then pcall(function() ti.Visible = true end) end
    end
    if not setAmount(qty) then return false, "no_amount" end
    task.wait(0.6)
    local sf = getInvScrollingFrame()
    if not sf then return false, "no_scroll" end
    local target
    for _, c in ipairs(sf:GetChildren()) do
        if c:IsA("Frame") and c.Name:lower() == itemName:lower() then
            target = c; break
        end
    end
    if not target then return false, "item_not_found" end
    local main = target:FindFirstChild("Main")
    if not main then return false, "no_main" end
    safeClick(main, "item " .. itemName)
    task.wait(0.4)
    local close = ti and ti:FindFirstChild("Close_")
    if close then safeClick(close, "close inv") end
    task.wait(0.2)
    if ti and ti.Visible then pcall(function() ti.Visible = false end) end
    local ready = getReadyButton()
    if ready then safeClick(ready, "Ready") end
    return true, "ok"
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
    frame.Size = UDim2.new(0, 380, 0, 560)
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
    title.Text = "Auto Trade v74 (FINAL)"
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
    statusLbl.Text = "v74: Chấm đỏ đã khớp với điểm bấm. Auto full flow."
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
    testBtn.Text = "2) TEST (chấm đỏ + click)"
    testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testBtn.Font = Enum.Font.GothamBold
    testBtn.TextSize = 12
    testBtn.Parent = body

    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0.95, 0, 0, 32)
    autoBtn.Position = UDim2.new(0.025, 0, 0, 224)
    autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    autoBtn.BorderSizePixel = 0
    autoBtn.Text = "3) AUTO FULL (Accept+Item+Ready): OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 11
    autoBtn.Parent = body

    local nameBox = Instance.new("TextBox")
    nameBox.Size = UDim2.new(0.55, 0, 0, 26)
    nameBox.Position = UDim2.new(0.025, 0, 0, 262)
    nameBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    nameBox.BorderSizePixel = 0
    nameBox.Text = "Wood"
    nameBox.PlaceholderText = "Tên item"
    nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameBox.Font = Enum.Font.Gotham
    nameBox.TextSize = 11
    nameBox.Parent = body

    local qtyBox = Instance.new("TextBox")
    qtyBox.Size = UDim2.new(0.3, 0, 0, 26)
    qtyBox.Position = UDim2.new(0.65, 0, 0, 262)
    qtyBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    qtyBox.BorderSizePixel = 0
    qtyBox.Text = "10"
    qtyBox.PlaceholderText = "SL"
    qtyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    qtyBox.Font = Enum.Font.Gotham
    qtyBox.TextSize = 11
    qtyBox.Parent = body

    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(0.95, 0, 0, 24)
    resetBtn.Position = UDim2.new(0.025, 0, 0, 296)
    resetBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    resetBtn.BorderSizePixel = 0
    resetBtn.Text = "Reset ô đen"
    resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.TextSize = 11
    resetBtn.Parent = body

    local helpLbl = Instance.new("TextLabel")
    helpLbl.Size = UDim2.new(0.95, 0, 0, 100)
    helpLbl.Position = UDim2.new(0.025, 0, 0, 324)
    helpLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    helpLbl.BorderSizePixel = 0
    helpLbl.Text = [[
v74:
- Chấm đỏ giờ khớp chính xác điểm bấm (đã cộng inset).
- Nếu vẫn lệch nhìn thấy, dùng Offset X/Y chỉnh thêm.
- Bật AUTO FULL -> tự accept popup + thêm item + Ready.
]]
    helpLbl.TextColor3 = Color3.fromRGB(200, 220, 200)
    helpLbl.Font = Enum.Font.Gotham
    helpLbl.TextSize = 10
    helpLbl.TextWrapped = true
    helpLbl.TextYAlignment = Enum.TextYAlignment.Top
    helpLbl.Parent = body

    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.95, 0, 0, 100)
    logLbl.Position = UDim2.new(0.025, 0, 0, 426)
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
        if #cur > 900 then cur = cur:sub(-800) end
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
        setStatus("Đã lưu. Test để thấy chấm đỏ khớp.", Color3.fromRGB(120, 220, 120))
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
            appendLog(string.format("TEST (%.0f,%.0f)", tx, ty))
            local ok, r = touchViaWrapper(tx, ty)
            if ok then
                appendLog("✔ OK: " .. r)
                setStatus("✔ OK: " .. r, Color3.fromRGB(120, 220, 120))
            else
                appendLog("✘ Fail")
                setStatus("✘ Fail - chỉnh offset", Color3.fromRGB(255, 120, 120))
            end
        end)
    end)

    autoBtn.MouseButton1Click:Connect(function()
        autoEnabled = not autoEnabled
        if autoEnabled then
            autoBtn.Text = "3) AUTO FULL: ON"
            autoBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            appendLog("AUTO FULL ON")
            setStatus("AUTO FULL ON", Color3.fromRGB(120, 220, 120))
        else
            autoBtn.Text = "3) AUTO FULL: OFF"
            autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
            appendLog("AUTO FULL OFF")
            setStatus("AUTO FULL OFF", Color3.fromRGB(200, 200, 120))
        end
    end)

    resetBtn.MouseButton1Click:Connect(function()
        dragFrame.Position = UDim2.new(0.5, -30, 0.5, -30)
        baseX = nil
        baseY = nil
    end)

    -- AUTO LOOP
    task.spawn(function()
        local phase = "IDLE"
        while sg.Parent do
            if autoEnabled then
                local popup = isPopupOpen()
                local ft = getFrameTrading()
                local tradeOpen = ft ~= nil and ft.Visible == true
                local itemName = nameBox.Text
                local qty = tonumber(qtyBox.Text) or 1

                if popup and phase ~= "ACCEPTING" then
                    phase = "ACCEPTING"
                    appendLog("popup hiện")
                    task.wait(0.2)
                    local bx, by = getCurrentBase()
                    local tx = bx + offsetX
                    local ty = by + offsetY
                    local ok, r = touchViaWrapper(tx, ty)
                    appendLog(ok and ("✔ accept: " .. r) or ("✘ accept: " .. tostring(r)))
                    phase = "IDLE"
                elseif tradeOpen and phase ~= "TRADING" then
                    phase = "TRADING"
                    appendLog("bảng trade mở, thêm item")
                    task.wait(0.5)
                    local ok, r = addItemToTrade(itemName, qty)
                    appendLog(ok and ("✔ " .. itemName .. " x" .. qty) or ("✘ " .. tostring(r)))
                    phase = "IDLE"
                elseif not popup and not tradeOpen and phase ~= "IDLE" then
                    phase = "IDLE"
                end
            end
            task.wait(0.3)
        end
    end)
end

if game.PlaceId ~= CONFIG.GameID then
    warn("[AutoTrade] PlaceId không khớp:", game.PlaceId)
end

buildUI()
log("v74 sẵn sàng. Chấm đỏ khớp điểm bấm. AUTO FULL tích hợp.")
