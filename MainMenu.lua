--[[
    Auto Trade - Rock Fruit v83 (Full Feature)
    Game ID: 119091355492870

    TÍNH NĂNG:
      1. Auto Accept popup Trade_Request (dùng X=30, Y=60 cho Mobile).
      2. Tự động chọn user trong SelectBar (theo tên đã nhập).
      3. Tự động bấm Invite để mời trade.
      4. Tự động thêm 5 loại item + số lượng vào bảng trade.
         - KHÔNG bấm nút [+], mà gọi trực tiếp logic thêm item.
      5. Tự động bấm Ready.
      6. Auto lặp lại khi trade xong.
      7. Chế độ KHÔNG thêm item (chỉ Ready) cho trade số lượng lớn.

    LUỒNG HOẠT ĐỘNG:
      B1: Mở GUI Trade -> chọn user -> Invite.
      B2: Chờ popup Accept (nếu có) -> accept.
      B3: Bảng Trading mở -> thêm item theo cấu hình.
      B4: Bấm Ready.
      B5: Chờ đối phương Ready -> trade hoàn tất.
      B6: Quay lại B1 (auto lặp).

    CẤU HÌNH:
      - TargetUser: tên người chơi muốn trade.
      - Slot 1-5: item + số lượng.
      - Mode: "WithItems" hoặc "ReadyOnly".
]]

local CONFIG = {
    GameID         = 119091355492870,
    Debug          = true,
    AcceptOffsetX  = 30,
    AcceptOffsetY  = 60,
    AcceptTimeout  = 3,
    InvitePoll     = 0.5,
    InviteTimeout  = 60,
    ItemDelay      = 0.4,
    ReadyDelay     = 0.5,
    LoopDelay      = 1.0,
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
    local ti = getTradeInventory()
    if not ti then return nil end
    local h = ti:FindFirstChild("Handler")
    if not h then return nil end
    local amt = h:FindFirstChild("Amount")
    if not amt then return nil end
    return amt:FindFirstChild("TextBox")
end

local function getInvScrollingFrame()
    local ti = getTradeInventory()
    if not ti then return nil end
    local h = ti:FindFirstChild("Handler")
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

local function getSelectBar()
    local main = getHUDMain()
    if not main then return nil end
    local ft = main:FindFirstChild("Frame_Trade")
    if not ft then return nil end
    local sb = ft:FindFirstChild("SelectBar")
    if not sb then return nil end
    return sb:FindFirstChild("ScrollingFrame")
end

local function getTradeFrameUI()
    local main = getHUDMain()
    if not main then return nil end
    return main:FindFirstChild("Frame_Trade")
end

local function isPopupOpen()
    local tr = getTradeRequestFrame()
    return tr ~= nil and tr.Visible == true
end

local function isTradingOpen()
    local ft = getFrameTrading()
    return ft ~= nil and ft.Visible == true
end

-- ============================================================
-- CLICK CƠ BẢN
-- ============================================================
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
    task.wait(0.05)
    return true
end

-- ============================================================
-- ACCEPT POPUP (dùng X=30, Y=60)
-- ============================================================
local function acceptPopup()
    local tr = getTradeRequestFrame()
    if not tr or not tr.Visible then return false end
    local sub = tr:FindFirstChild("Sub")
    if not sub then return false end
    local m = sub:FindFirstChild("Main")
    if not m then return false end
    local accFolder = m:FindFirstChild("Accept")
    if not accFolder then return false end
    local btn = accFolder:FindFirstChild("Accept")
    if not btn then return false end

    local ap = btn.AbsolutePosition
    local sz = btn.AbsoluteSize
    local cx = ap.X + sz.X / 2 + CONFIG.AcceptOffsetX
    local cy = ap.Y + sz.Y / 2 + CONFIG.AcceptOffsetY

    log(string.format("Accept tại (%.0f, %.0f)", cx, cy))

    -- Cách 1: callback
    if getconnections then
        for _, sigName in ipairs({"MouseButton1Click", "MouseButton1Down", "MouseButton1Up", "Activated"}) do
            local sig = btn[sigName]
            if sig then
                local ok, conns = pcall(getconnections, sig)
                if ok and conns then
                    for _, c in ipairs(conns) do
                        if c.Enabled and c.Function then
                            pcall(c.Function)
                            task.wait(0.05)
                        end
                    end
                end
            end
        end
        task.wait(0.2)
        if not isPopupOpen() then return true end
    end

    -- Cách 2: wrapper touch tại (cx, cy)
    local wrapSg = Instance.new("ScreenGui")
    wrapSg.Name = "HoangAcceptWrap"
    wrapSg.ResetOnSpawn = false
    wrapSg.IgnoreGuiInset = false
    wrapSg.Parent = CoreGui
    local wrapper = Instance.new("TextButton")
    wrapper.Size = UDim2.new(0, 30, 0, 30)
    wrapper.Position = UDim2.new(0, cx - 15, 0, cy - 15)
    wrapper.BackgroundTransparency = 1
    wrapper.Text = ""
    wrapper.Active = true
    wrapper.ZIndex = 999992
    wrapper.Parent = wrapSg
    task.wait(0.1)
    if firetouchinterest then
        pcall(function()
            firetouchinterest(wrapper, Vector2.new(cx, cy), 0)
            task.wait(0.1)
            firetouchinterest(wrapper, Vector2.new(cx, cy), 1)
        end)
        task.wait(0.3)
    end
    pcall(function() wrapSg:Destroy() end)

    return not isPopupOpen()
end

-- ============================================================
-- NHẬP SỐ LƯỢNG VÀO TEXTBOX
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

-- ============================================================
-- THÊM 1 ITEM VÀO TRADE (không qua nút [+])
-- ============================================================
local function addItemDirect(itemName, qty)
    -- Mở inventory trade
    local ti = getTradeInventory()
    if not (ti and ti.Visible) then
        local add = getAddButton()
        if add then
            safeClick(add, "[+]")
            task.wait(0.4)
        end
        ti = getTradeInventory()
        if ti then pcall(function() ti.Visible = true end) end
    end

    if not setAmount(qty) then return false, "no_amount" end
    task.wait(0.5)

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
    task.wait(0.3)
    log(string.format("Đã thêm %s x%d", itemName, qty))
    return true
end

-- ============================================================
-- MỜI USER QUA NÚT INVITE
-- ============================================================
local function inviteUserInSelectBar(username)
    local sb = getSelectBar()
    if not sb then return false, "no_selectbar" end
    local target = username:lower()
    for _, entry in ipairs(sb:GetChildren()) do
        if entry:IsA("Frame") then
            local main = entry:FindFirstChild("Main")
            if main then
                local un = main:FindFirstChild("Username")
                if un and un:IsA("TextLabel") and un.Text:lower() == target then
                    local inv = main:FindFirstChild("Invite")
                    if inv then
                        safeClick(inv, "Invite " .. username)
                        return true, "invited"
                    end
                end
            end
        end
    end
    return false, "user_not_found"
end

-- ============================================================
-- UI CHÍNH
-- ============================================================
local itemSlots = {
    {name = "Wood", qty = 40},
    {name = "Pizza", qty = 1},
    {name = "Nuke", qty = 2},
    {name = "Chair", qty = 3},
    {name = "KFC", qty = 1},
}
local targetUsername = ""
local tradeMode = "WithItems"  -- hoặc "ReadyOnly"
local autoEnabled = false

local function buildUI()
    local oldUI = CoreGui:FindFirstChild("HoangAutoTradeUI")
    if oldUI then oldUI:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "HoangAutoTradeUI"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 420, 0, 560)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = sg

    -- Title bar
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
    title.Text = "Auto Trade v83 (Full)"
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
    statusLbl.Size = UDim2.new(0.9, 0, 0, 28)
    statusLbl.Position = UDim2.new(0.05, 0, 0, 0)
    statusLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    statusLbl.BorderSizePixel = 0
    statusLbl.Text = "OFF"
    statusLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 11
    statusLbl.TextWrapped = true
    statusLbl.Parent = body

    -- Mode selector
    local modeBtn = Instance.new("TextButton")
    modeBtn.Size = UDim2.new(0.9, 0, 0, 30)
    modeBtn.Position = UDim2.new(0.05, 0, 0, 32)
    modeBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    modeBtn.BorderSizePixel = 0
    modeBtn.Text = "MODE: CÓ VẬT PHẨM (bấm đổi)"
    modeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    modeBtn.Font = Enum.Font.GothamBold
    modeBtn.TextSize = 11
    modeBtn.Parent = body

    -- Target user
    local targetLbl = Instance.new("TextLabel")
    targetLbl.Size = UDim2.new(0.3, 0, 0, 26)
    targetLbl.Position = UDim2.new(0.05, 0, 0, 66)
    targetLbl.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    targetLbl.BorderSizePixel = 0
    targetLbl.Text = "User"
    targetLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    targetLbl.Font = Enum.Font.Gotham
    targetLbl.TextSize = 11
    targetLbl.Parent = body

    local targetBox = Instance.new("TextBox")
    targetBox.Size = UDim2.new(0.55, 0, 0, 26)
    targetBox.Position = UDim2.new(0.4, 0, 0, 66)
    targetBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    targetBox.BorderSizePixel = 0
    targetBox.Text = ""
    targetBox.PlaceholderText = "Username (trong SelectBar)"
    targetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetBox.Font = Enum.Font.Gotham
    targetBox.TextSize = 11
    targetBox.Parent = body

    -- 5 slots
    local slotWidgets = {}
    for i = 1, 5 do
        local y = 100 + (i - 1) * 32
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(0.1, 0, 0, 26)
        nameLbl.Position = UDim2.new(0.05, 0, 0, y)
        nameLbl.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        nameLbl.BorderSizePixel = 0
        nameLbl.Text = tostring(i)
        nameLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 12
        nameLbl.Parent = body

        local nameBox = Instance.new("TextBox")
        nameBox.Size = UDim2.new(0.5, 0, 0, 26)
        nameBox.Position = UDim2.new(0.16, 0, 0, y)
        nameBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        nameBox.BorderSizePixel = 0
        nameBox.Text = itemSlots[i].name
        nameBox.PlaceholderText = "Tên item"
        nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameBox.Font = Enum.Font.Gotham
        nameBox.TextSize = 11
        nameBox.Parent = body

        local qtyBox = Instance.new("TextBox")
        qtyBox.Size = UDim2.new(0.25, 0, 0, 26)
        qtyBox.Position = UDim2.new(0.68, 0, 0, y)
        qtyBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        qtyBox.BorderSizePixel = 0
        qtyBox.Text = tostring(itemSlots[i].qty)
        qtyBox.PlaceholderText = "SL"
        qtyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        qtyBox.Font = Enum.Font.Gotham
        qtyBox.TextSize = 11
        qtyBox.Parent = body

        nameBox:GetPropertyChangedSignal("Text"):Connect(function()
            itemSlots[i].name = nameBox.Text
        end)
        qtyBox:GetPropertyChangedSignal("Text"):Connect(function()
            itemSlots[i].qty = tonumber(qtyBox.Text) or 0
        end)

        table.insert(slotWidgets, {nameBox = nameBox, qtyBox = qtyBox})
    end

    -- Start button
    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(0.9, 0, 0, 40)
    startBtn.Position = UDim2.new(0.05, 0, 0, 264)
    startBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    startBtn.BorderSizePixel = 0
    startBtn.Text = "START AUTO TRADE"
    startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    startBtn.Font = Enum.Font.GothamBold
    startBtn.TextSize = 14
    startBtn.Parent = body

    -- Log
    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.9, 0, 0, 150)
    logLbl.Position = UDim2.new(0.05, 0, 0, 310)
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
        if #cur > 1000 then cur = cur:sub(-900) end
        logLbl.Text = cur .. "\n" .. s
    end

    closeUI.MouseButton1Click:Connect(function() sg:Destroy() end)

    modeBtn.MouseButton1Click:Connect(function()
        if tradeMode == "WithItems" then
            tradeMode = "ReadyOnly"
            modeBtn.Text = "MODE: CHỈ READY (không thêm item)"
            modeBtn.BackgroundColor3 = Color3.fromRGB(200, 130, 40)
        else
            tradeMode = "WithItems"
            modeBtn.Text = "MODE: CÓ VẬT PHẨM (bấm đổi)"
            modeBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
        end
        appendLog("Mode: " .. tradeMode)
    end)

    targetBox:GetPropertyChangedSignal("Text"):Connect(function()
        targetUsername = targetBox.Text
    end)

    -- ============================================================
    -- LOOP CHÍNH
    -- ============================================================
    local function doFullFlow()
        -- B1: Mở Frame_Trade
        local tui = getTradeFrameUI()
        if tui and not tui.Visible then
            pcall(function() tui.Visible = true end)
            task.wait(0.3)
        end

        -- B2: Mời user
        if targetUsername and targetUsername ~= "" then
            local sb = getSelectBar()
            if sb then
                for _, entry in ipairs(sb:GetChildren()) do
                    if entry:IsA("Frame") then
                        local main = entry:FindFirstChild("Main")
                        if main then
                            local un = main:FindFirstChild("Username")
                            if un and un:IsA("TextLabel") and un.Text:lower() == targetUsername:lower() then
                                local inv = main:FindFirstChild("Invite")
                                if inv then
                                    safeClick(inv, "Invite " .. targetUsername)
                                    appendLog("Đã invite: " .. targetUsername)
                                    return true
                                end
                            end
                        end
                    end
                end
                appendLog("User không có trong SelectBar: " .. targetUsername)
            end
        end
        return false
    end

    local function doTradingFlow()
        if tradeMode == "WithItems" then
            -- Thêm từng item còn trống
            for i = 1, 5 do
                local slot = itemSlots[i]
                if slot.name and slot.name ~= "" and slot.qty and slot.qty > 0 then
                    local ok, reason = addItemDirect(slot.name, slot.qty)
                    if ok then
                        appendLog(string.format("✔ %s x%d", slot.name, slot.qty))
                    else
                        appendLog(string.format("✘ %s: %s", slot.name, tostring(reason)))
                    end
                    task.wait(CONFIG.ItemDelay)
                end
            end
            -- Đóng Inventory
            local ti = getTradeInventory()
            if ti then
                local close = ti:FindFirstChild("Close_")
                if close then safeClick(close, "close inv") end
                task.wait(0.2)
                if ti.Visible then pcall(function() ti.Visible = false end) end
            end
        end

        -- Bấm Ready
        task.wait(CONFIG.ReadyDelay)
        local ready = getReadyButton()
        if ready then
            safeClick(ready, "Ready")
            appendLog("✔ Đã bấm Ready, chờ đối phương")
        end
    end

    task.spawn(function()
        while sg.Parent do
            if autoEnabled then
                -- Ưu tiên 1: accept popup nếu có
                if isPopupOpen() then
                    setStatus("Có popup, accept...", Color3.fromRGB(200,200,120))
                    appendLog("Phát hiện popup, accept")
                    local ok = acceptPopup()
                    appendLog(ok and "✔ Accept OK" or "✘ Accept fail")
                    task.wait(0.5)
                elseif isTradingOpen() then
                    setStatus("Trading mở, thêm item + Ready", Color3.fromRGB(200,200,120))
                    appendLog("Bảng Trading mở")
                    doTradingFlow()
                    setStatus("Đã Ready, chờ đối phương", Color3.fromRGB(120,220,120))
                    -- Chờ trade kết thúc
                    local t0 = os.clock()
                    while isTradingOpen() and os.clock() - t0 < 60 do
                        task.wait(0.5)
                    end
                    appendLog("Trade xong")
                    task.wait(1)
                else
                    -- Không có popup, không có trading -> thử mở + invite
                    setStatus("Đang mời " .. (targetUsername ~= "" and targetUsername or "..."), Color3.fromRGB(200,200,120))
                    doFullFlow()
                    task.wait(CONFIG.LoopDelay)
                end
            end
            task.wait(0.5)
        end
    end)

    startBtn.MouseButton1Click:Connect(function()
        autoEnabled = not autoEnabled
        if autoEnabled then
            startBtn.Text = "STOP AUTO TRADE"
            startBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            setStatus("AUTO ON", Color3.fromRGB(120,220,120))
            appendLog("Bắt đầu auto: user=" .. (targetUsername ~= "" and targetUsername or "?"))
        else
            startBtn.Text = "START AUTO TRADE"
            startBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
            setStatus("OFF", Color3.fromRGB(200,200,120))
            appendLog("Dừng auto")
        end
    end)
end

if game.PlaceId ~= CONFIG.GameID then
    warn("[AutoTrade] PlaceId không khớp:", game.PlaceId)
end

buildUI()
log("v83 sẵn sàng. Nhập user + 5 slot item, bấm START.")
