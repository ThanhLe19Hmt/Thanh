--[[
    Auto Trade - Rock Fruit v63.1 (Syntax Fix)
    Game ID: 119091355492870

    SỬA LỖI:
      - Dòng 275 có lỗi: `log("Có", #targets, "targets:", )`
      - Lua không cho phép dấu phẩy trước ngoặc đóng.
      - Fix: đổi thành `log("Có", #targets, "targets")`
      - Các chỗ khác cũng có thể lỗi tương tự -> tôi đã rà toàn bộ.

    NẾU CÒN LỖI KHÁC -> GỬI DÒNG LỖI (có số dòng) cho tôi.
]]

local CONFIG = {
    GameID          = 119091355492870,
    Debug           = true,
    SafeMarginTop   = 80,
    SafeMarginRight = 80,
    PCOffsetY       = 50,
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

local function getAcceptFolder()
    local tr = getTradeRequestFrame()
    if not tr then return nil end
    local sub = tr:FindFirstChild("Sub")
    if not sub then return nil end
    local m = sub:FindFirstChild("Main")
    if not m then return nil end
    return m:FindFirstChild("Accept")
end

local function getAcceptButton()
    local acc = getAcceptFolder()
    if not acc then return nil end
    return acc:FindFirstChild("Accept")
end

local function getAllAcceptTargets()
    local targets = {}
    local btn = getAcceptButton()
    if btn then
        table.insert(targets, btn)
        for _, d in ipairs(btn:GetDescendants()) do
            if d:IsA("GuiButton") or d:IsA("ImageLabel") then
                table.insert(targets, d)
            end
        end
    end
    local folder = getAcceptFolder()
    if folder then
        for _, d in ipairs(folder:GetDescendants()) do
            if d:IsA("ImageLabel") or d:IsA("GuiButton") then
                local inTargets = false
                for _, t in ipairs(targets) do
                    if t == d then inTargets = true; break end
                end
                if not inTargets then
                    table.insert(targets, d)
                end
            end
        end
    end
    return targets
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
-- CLICK PC
-- ============================================================
local function clickAcceptPC(btn)
    if not mousemoverel or not mouse1click then return false, "no_api" end
    local c = getCenter(btn)
    if not c then return false, "no_center" end
    for i = 1, 40 do
        local cur = UserInputService:GetMouseLocation()
        local tgtY = c.Y + CONFIG.PCOffsetY
        local dx = c.X - cur.X
        local dy = tgtY - cur.Y
        if math.sqrt(dx*dx + dy*dy) < 3 then break end
        pcall(function()
            mousemoverel(math.clamp(dx, -25, 25), math.clamp(dy, -25, 25))
        end)
        task.wait(0.03)
    end
    pcall(function() mouse1click() end)
    task.wait(0.3)
    if not isPopupOpen() then return true, "pc_click" end
    return false, "still_open"
end

-- ============================================================
-- CLICK MOBILE
-- ============================================================
local function tryTouchTarget(target, pos, label)
    if not firetouchinterest then return false end
    log("    Thử firetouchinterest ->", label)
    pcall(function()
        firetouchinterest(target, pos, 0)
        task.wait(0.2)
        firetouchinterest(target, pos, 1)
    end)
    task.wait(0.4)
    if not isPopupOpen() then
        return true
    end
    return false
end

local function tryVirtualInput(target, pos)
    if not VirtualInputManager then return false end
    log("    Thử VirtualInputManager")
    pcall(function()
        VirtualInputManager:SendMouseMoveEvent(math.floor(pos.X), math.floor(pos.Y), game)
    end)
    task.wait(0.3)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(math.floor(pos.X), math.floor(pos.Y), 0, true, game, 0)
    end)
    task.wait(0.2)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(math.floor(pos.X), math.floor(pos.Y), 0, false, game, 0)
    end)
    task.wait(0.4)
    if not isPopupOpen() then return true end
    return false
end

local function tryFiresignal(btn)
    if typeof(firesignal) ~= "function" then return false end
    log("    Thử firesignal Down/Up/Click")
    pcall(function()
        firesignal(btn.MouseButton1Down)
        task.wait(0.1)
        firesignal(btn.MouseButton1Up)
        task.wait(0.1)
        firesignal(btn.MouseButton1Click)
    end)
    task.wait(0.4)
    if not isPopupOpen() then return true end
    return false
end

local function tryActivate(btn)
    pcall(function() btn:Activate() end)
    task.wait(0.3)
    if not isPopupOpen() then return true end
    return false
end

local function tryGuiWrapper(btn, pos)
    log("    Thử GUI Wrapper (TextButton vô hình)")
    local sg = Instance.new("ScreenGui")
    sg.Name = "HoangTouchWrapper"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.Parent = CoreGui
    local wrapper = Instance.new("TextButton")
    wrapper.Size = UDim2.new(0, btn.AbsoluteSize.X + 10, 0, btn.AbsoluteSize.Y + 10)
    wrapper.Position = UDim2.new(0, btn.AbsolutePosition.X - 5, 0, btn.AbsolutePosition.Y - 5)
    wrapper.BackgroundTransparency = 1
    wrapper.Text = ""
    wrapper.ZIndex = 99999
    wrapper.Parent = sg
    local child = Instance.new("TextLabel")
    child.Size = UDim2.new(1, 0, 1, 0)
    child.BackgroundTransparency = 1
    child.Text = ""
    child.Parent = wrapper
    task.wait(0.1)
    if firetouchinterest then
        pcall(function()
            firetouchinterest(wrapper, pos, 0)
            task.wait(0.15)
            firetouchinterest(wrapper, pos, 1)
        end)
        task.wait(0.4)
        local closed = not isPopupOpen()
        sg:Destroy()
        if closed then return true end
    else
        sg:Destroy()
    end
    return false
end

local function clickAcceptMobile(btn)
    if not btn then return false, "no_btn" end
    local c = getCenter(btn)
    if not c then return false, "no_center" end
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1366, 705)
    if c.Y < CONFIG.SafeMarginTop or c.X > vp.X - CONFIG.SafeMarginRight then
        return false, "unsafe"
    end

    log(string.format("Mobile target: (%.0f, %.0f)", c.X, c.Y))

    local targets = getAllAcceptTargets()
    -- FIX: dòng 275 cũ có lỗi dấu phẩy thừa, sửa thành:
    log("Có", #targets, "targets")
    for i, t in ipairs(targets) do
        log("  #" .. i, t.ClassName, t.Name)
    end

    for i, target in ipairs(targets) do
        log("--- Target #" .. i .. " (" .. target.ClassName .. ") ---")
        local targetCenter = getCenter(target) or c
        if tryTouchTarget(target, targetCenter, "#" .. i .. " " .. target.Name) then
            return true, "touch_target_" .. i
        end
        if tryVirtualInput(target, targetCenter) then
            return true, "vim_target_" .. i
        end
    end

    if tryFiresignal(btn) then return true, "firesignal" end
    if tryActivate(btn) then return true, "activate" end
    if tryGuiWrapper(btn, c) then return true, "gui_wrapper" end

    return false, "all_fail"
end

-- ============================================================
-- ACCEPT
-- ============================================================
local function acceptTrade()
    local btn = getAcceptButton()
    if not btn then return false, "no_popup" end
    if IS_PC then
        return clickAcceptPC(btn)
    else
        return clickAcceptMobile(btn)
    end
end

-- ============================================================
-- NHẬP SL + THÊM ITEM
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

local function getTradeInventory()
    local main = getHUDMain()
    if not main then return nil end
    local ft = main:FindFirstChild("Frame_Trading")
    if not ft then return nil end
    return ft:FindFirstChild("Frame_TradeInventory")
end

local function getTradeInvHandler()
    local ti = getTradeInventory()
    if not ti then return nil end
    return ti:FindFirstChild("Handler")
end

local function getAddButton()
    local main = getHUDMain()
    if not main then return nil end
    local ft = main:FindFirstChild("Frame_Trading")
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
    local main = getHUDMain()
    if not main then return nil end
    local ft = main:FindFirstChild("Frame_Trading")
    if not ft then return nil end
    return ft:FindFirstChild("Ready")
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
    frame.Size = UDim2.new(0, 460, 0, 460)
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
    title.Text = "Auto Trade v63.1 (" .. PLATFORM .. ")"
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
    autoBtn.Text = "AUTO TRADE: OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 11
    autoBtn.Parent = body

    local nameBox = Instance.new("TextBox")
    nameBox.Size = UDim2.new(0.55, 0, 0, 26)
    nameBox.Position = UDim2.new(0.05, 0, 0, 62)
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
    qtyBox.Position = UDim2.new(0.65, 0, 0, 62)
    qtyBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    qtyBox.BorderSizePixel = 0
    qtyBox.Text = "10"
    qtyBox.PlaceholderText = "SL"
    qtyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    qtyBox.Font = Enum.Font.Gotham
    qtyBox.TextSize = 11
    qtyBox.Parent = body

    local testBtn = Instance.new("TextButton")
    testBtn.Size = UDim2.new(0.9, 0, 0, 26)
    testBtn.Position = UDim2.new(0.05, 0, 0, 94)
    testBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
    testBtn.BorderSizePixel = 0
    testBtn.Text = "Test Accept (" .. PLATFORM .. ")"
    testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testBtn.Font = Enum.Font.GothamBold
    testBtn.TextSize = 11
    testBtn.Parent = body

    local infoBtn = Instance.new("TextButton")
    infoBtn.Size = UDim2.new(0.9, 0, 0, 24)
    infoBtn.Position = UDim2.new(0.05, 0, 0, 126)
    infoBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    infoBtn.BorderSizePixel = 0
    infoBtn.Text = "In info + log targets"
    infoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    infoBtn.Font = Enum.Font.GothamBold
    infoBtn.TextSize = 11
    infoBtn.Parent = body

    local helpLbl = Instance.new("TextLabel")
    helpLbl.Size = UDim2.new(0.9, 0, 0, 110)
    helpLbl.Position = UDim2.new(0.05, 0, 0, 156)
    helpLbl.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    helpLbl.BorderSizePixel = 0
    helpLbl.Text = [[
v63.1 sửa lỗi cú pháp:
- Dòng 275: bỏ dấu phẩy thừa.
- Toàn bộ logic v63 giữ nguyên.

Mobile sẽ thử:
- firetouchinterest trên từng GuiButton.
- VirtualInputManager.
- firesignal.
- Activate.
- GUI wrapper.
]]
    helpLbl.TextColor3 = Color3.fromRGB(200, 220, 200)
    helpLbl.Font = Enum.Font.Gotham
    helpLbl.TextSize = 10
    helpLbl.TextWrapped = true
    helpLbl.TextYAlignment = Enum.TextYAlignment.Top
    helpLbl.Parent = body

    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.9, 0, 0, 140)
    logLbl.Position = UDim2.new(0.05, 0, 0, 270)
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
        if #cur > 1100 then cur = cur:sub(-900) end
        logLbl.Text = cur .. "\n" .. s
    end

    closeUI.MouseButton1Click:Connect(function() sg:Destroy() end)

    local enabled = false
    autoBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            autoBtn.Text = "AUTO TRADE (" .. PLATFORM .. "): ON"
            autoBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            setStatus("chờ popup", Color3.fromRGB(120,220,120))
        else
            autoBtn.Text = "AUTO TRADE (" .. PLATFORM .. "): OFF"
            autoBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
            setStatus("đã tắt", Color3.fromRGB(200,200,120))
        end
    end)

    testBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            local ok, r = acceptTrade()
            appendLog(ok and ("✔ Accept: " .. r) or ("✘ fail: " .. tostring(r)))
            setStatus(ok and "Accept OK" or "fail",
                ok and Color3.fromRGB(120,220,120) or Color3.fromRGB(255,120,120))
        end)
    end)

    infoBtn.MouseButton1Click:Connect(function()
        print("========== INFO v63.1 ==========")
        print("Platform:", PLATFORM)
        print("TouchEnabled:", tostring(isTouch))
        print("MouseEnabled:", tostring(isMouse))
        print("KeyboardEnabled:", tostring(isKeyboard))
        print("mousemoverel:", typeof(mousemoverel))
        print("mouse1click:", typeof(mouse1click))
        print("firetouchinterest:", typeof(firetouchinterest))
        print("VirtualInputManager:", typeof(VirtualInputManager))
        print("firesignal:", typeof(firesignal))
        local targets = getAllAcceptTargets()
        print("--- Targets in Accept ---")
        for i, t in ipairs(targets) do
            print("  #" .. i, t.ClassName, t.Name)
        end
        print("=============================")
        appendLog("info ở F9")
    end)

    task.spawn(function()
        local phase = "IDLE"
        while sg.Parent do
            if enabled then
                local tr = getTradeRequestFrame()
                local ft = getHUDMain() and getHUDMain():FindFirstChild("Frame_Trading")
                local popupOpen = tr ~= nil and tr.Visible == true
                local tradeOpen = ft ~= nil and ft.Visible == true
                local itemName = nameBox.Text
                local qty = tonumber(qtyBox.Text) or 1

                if popupOpen and phase ~= "ACCEPTING" then
                    phase = "ACCEPTING"
                    setStatus("popup - accept", Color3.fromRGB(200,200,120))
                    appendLog("popup hiện")
                    task.wait(0.2)
                    local ok, r = acceptTrade()
                    appendLog(ok and ("✔ " .. r) or ("✘ " .. tostring(r)))
                    phase = "IDLE"
                elseif tradeOpen and phase ~= "TRADING" then
                    phase = "TRADING"
                    setStatus("trading", Color3.fromRGB(200,200,120))
                    task.wait(0.5)
                    local ok, r = addItemToTrade(itemName, qty)
                    appendLog(ok and ("✔ " .. itemName .. " x" .. qty) or ("✘ " .. tostring(r)))
                    setStatus(ok and "HOÀN TẤT" or "fail",
                        ok and Color3.fromRGB(120,220,120) or Color3.fromRGB(255,120,120))
                    phase = "IDLE"
                elseif not popupOpen and not tradeOpen and phase ~= "IDLE" then
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
log("v63.1 sẵn sàng. Mobile: thử nhiều target + GUI wrapper.")
