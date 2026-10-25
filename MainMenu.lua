--[[
    Auto Trade - Rock Fruit v83 (Gộp v82 + v83)
    Game ID: 119091355492870

    GỘP:
      - PHẦN ACCEPT: giữ NGUYÊN v82 (5 phương thức + tryAll
        + offsetX/offsetY + visual chấm đỏ + test + auto).
        -> Đây là phần bạn xác nhận CHẠY ĐƯỢC.
      - PHẦN CHỌN USER/ITEM: từ v83 refactored.
        -> Click chọn từ danh sách, không gõ tay.
      - LOOP CHÍNH: khi auto ON, nếu có popup -> tryAll
        (accept). Nếu trading mở -> thêm item + Ready.
        Nếu không có gì -> mở Frame_Trade + invite user.

    CÁCH DÙNG:
      1. Mở bảng Trade trong game -> SelectBar hiện user.
      2. UI hiển thị danh sách user -> click chọn.
      3. Mở bảng Trading (hoặc mở Inventory trade) ->
         UI hiển thị danh sách item -> click chọn.
      4. Bấm "TEST 5 CÁCH BẤM" để kiểm tra accept.
      5. Tinh chỉnh X/Y nếu mobile bấm lệch.
      6. Bấm "AUTO TRADE: ON".
]]

local CONFIG = {
    GameID        = 119091355492870,
    Debug         = true,
    ItemDelay     = 0.4,
    ReadyDelay    = 0.5,
    LoopDelay     = 1.0,
    RefreshRate   = 2.0,
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

local isTouch = UserInputService.TouchEnabled
local isMouse = UserInputService.MouseEnabled
local isKeyboard = UserInputService.KeyboardEnabled
local IS_MOBILE = (isTouch and not isKeyboard and not isMouse)
local IS_PC = (isMouse and isKeyboard and not isTouch)
local PLATFORM = IS_MOBILE and "MOBILE" or (IS_PC and "PC" or "UNKNOWN")
local DEFAULT_OFFSET_Y = IS_PC and 50 or 60
local DEFAULT_OFFSET_X = 0

local function getInset()
    local tl = Vector2.new(0, 0)
    pcall(function() tl = GuiService.TopLeftInset end)
    return tl
end

-- ============================================================
-- ĐỐI TƯỢNG GAME (giữ nguyên)
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
-- VISUAL (v82 - giữ nguyên)
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
    local tl = getInset()
    visualDot.Position = UDim2.new(0, x + tl.X - 6, 0, y + tl.Y - 6)
    visualDot.Visible = true
end

local function hideVisual()
    if visualDot then visualDot.Visible = false end
end

-- ============================================================
-- 5 PHƯƠNG THỨC ACCEPT (v82 - GIỮ NGUYÊN 100%)
-- ============================================================
local function method1_directTouch(x, y)
    local btn = getAcceptButton()
    if not btn or not firetouchinterest then return false end
    log(string.format("[1] direct touch (%.1f, %.1f)", x, y))
    pcall(function()
        firetouchinterest(btn, Vector2.new(x, y), 0)
        task.wait(0.1)
        firetouchinterest(btn, Vector2.new(x, y), 1)
    end)
    task.wait(0.3)
    if not isPopupOpen() then return true, "direct_touch" end
    return false
end

local function method2_vim(x, y)
    if not VirtualInputManager then return false end
    log(string.format("[2] VIM (%.1f, %.1f)", x, y))
    local ix, iy = math.floor(x), math.floor(y)
    pcall(function()
        VirtualInputManager:SendMouseMoveEvent(ix, iy, game)
    end)
    task.wait(0.2)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(ix, iy, 0, true, game, 0)
    end)
    task.wait(0.15)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(ix, iy, 0, false, game, 0)
    end)
    task.wait(0.3)
    if not isPopupOpen() then return true, "vim" end
    return false
end

local function method3_callback(x, y)
    local btn = getAcceptButton()
    if not btn or not getconnections then return false end
    log("[3] callback Accept")
    local signals = {
        {"MouseButton1Click", btn.MouseButton1Click},
        {"MouseButton1Down", btn.MouseButton1Down},
        {"MouseButton1Up", btn.MouseButton1Up},
        {"Activated", btn.Activated},
    }
    for _, pair in ipairs(signals) do
        local sigName, sig = pair[1], pair[2]
        if sig then
            local ok, conns = pcall(getconnections, sig)
            if ok and conns then
                for i, c in ipairs(conns) do
                    if c.Enabled and c.Function then
                        log(string.format("  %s #%d", sigName, i))
                        pcall(c.Function)
                        task.wait(0.05)
                    end
                end
            end
        end
    end
    task.wait(0.3)
    if not isPopupOpen() then return true, "callback" end
    return false
end

local function method4_firesignal(x, y)
    local btn = getAcceptButton()
    if not btn or typeof(firesignal) ~= "function" then return false end
    log("[4] firesignal Accept")
    pcall(function()
        firesignal(btn.MouseButton1Down)
        task.wait(0.1)
        firesignal(btn.MouseButton1Up)
        task.wait(0.1)
        firesignal(btn.MouseButton1Click)
        task.wait(0.1)
        firesignal(btn.Activated)
    end)
    task.wait(0.3)
    if not isPopupOpen() then return true, "firesignal" end
    return false
end

local function method5_wrapper(x, y)
    local wrapSg = Instance.new("ScreenGui")
    wrapSg.Name = "HoangWrap"
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
        log(string.format("[5] wrapper (%.1f, %.1f)", x, y))
        pcall(function()
            firetouchinterest(wrapper, Vector2.new(x, y), 0)
            task.wait(0.1)
            firetouchinterest(wrapper, Vector2.new(x, y), 1)
        end)
        task.wait(0.3)
        ok = not isPopupOpen()
    end
    pcall(function() wrapSg:Destroy() end)
    if ok then return true, "wrapper" end
    return false
end

local function tryAll(x, y)
    showVisual(x, y)
    task.wait(0.15)
    local methods = {
        {"direct_touch", method1_directTouch},
        {"vim", method2_vim},
        {"callback", method3_callback},
        {"firesignal", method4_firesignal},
        {"wrapper", method5_wrapper},
    }
    for _, m in ipairs(methods) do
        if not isPopupOpen() then hideVisual(); return true, "already_closed" end
        local ok, r = m[2](x, y)
        if ok then hideVisual(); return true, m[1] end
        task.wait(0.1)
    end
    hideVisual()
    return false, "all_fail"
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
-- FETCH DANH SÁCH
-- ============================================================
local function fetchPlayerList()
    local list = {}
    local sb = getSelectBar()
    if not sb then return list end
    for _, entry in ipairs(sb:GetChildren()) do
        if entry:IsA("Frame") then
            local main = entry:FindFirstChild("Main")
            if main then
                local un = main:FindFirstChild("Username")
                if un and un:IsA("TextLabel") and un.Text ~= "" then
                    table.insert(list, un.Text)
                end
            end
        end
    end
    return list
end

local function fetchItemList()
    local list = {}
    local sf = getInvScrollingFrame()
    if not sf then return list end
    for _, c in ipairs(sf:GetChildren()) do
        if c:IsA("Frame") then
            local main = c:FindFirstChild("Main")
            if main then
                table.insert(list, c.Name)
            end
        end
    end
    return list
end

-- ============================================================
-- INVITE USER
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
-- THÊM ITEM
-- ============================================================
local function addItemDirect(itemName, qty)
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
-- STATE
-- ============================================================
local offsetX         = DEFAULT_OFFSET_X
local offsetY         = DEFAULT_OFFSET_Y
local autoEnabled     = false
local tradeMode       = "WithItems"   -- hoặc "ReadyOnly"
local selectedUser    = nil
local selectedItems   = {}            -- { {name=..., qty=...} }

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
    frame.Size = UDim2.new(0, 480, 0, 640)
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
    title.Text = "v83 Gộp (" .. PLATFORM .. ") X=" .. offsetX .. " Y=" .. offsetY
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
    statusLbl.Text = "Sẵn sàng. Test accept trước khi AUTO."
    statusLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 11
    statusLbl.TextWrapped = true
    statusLbl.Parent = body

    -- ===== MODE =====
    local modeBtn = Instance.new("TextButton")
    modeBtn.Size = UDim2.new(0.9, 0, 0, 26)
    modeBtn.Position = UDim2.new(0.05, 0, 0, 34)
    modeBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    modeBtn.BorderSizePixel = 0
    modeBtn.Text = "MODE: CÓ VẬT PHẨM (bấm đổi)"
    modeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    modeBtn.Font = Enum.Font.GothamBold
    modeBtn.TextSize = 11
    modeBtn.Parent = body

    -- ===== OFFSET X/Y (v82) =====
    local oxLabel = Instance.new("TextLabel")
    oxLabel.Size = UDim2.new(0.1, 0, 0, 26)
    oxLabel.Position = UDim2.new(0.05, 0, 0, 66)
    oxLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    oxLabel.BorderSizePixel = 0
    oxLabel.Text = "X"
    oxLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    oxLabel.Font = Enum.Font.GothamBold
    oxLabel.TextSize = 13
    oxLabel.Parent = body

    local oxBox = Instance.new("TextBox")
    oxBox.Size = UDim2.new(0.15, 0, 0, 26)
    oxBox.Position = UDim2.new(0.16, 0, 0, 66)
    oxBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    oxBox.BorderSizePixel = 0
    oxBox.Text = tostring(offsetX)
    oxBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    oxBox.Font = Enum.Font.Gotham
    oxBox.TextSize = 12
    oxBox.Parent = body

    local oyLabel = Instance.new("TextLabel")
    oyLabel.Size = UDim2.new(0.1, 0, 0, 26)
    oyLabel.Position = UDim2.new(0.34, 0, 0, 66)
    oyLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    oyLabel.BorderSizePixel = 0
    oyLabel.Text = "Y"
    oyLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    oyLabel.Font = Enum.Font.GothamBold
    oyLabel.TextSize = 13
    oyLabel.Parent = body

    local oyBox = Instance.new("TextBox")
    oyBox.Size = UDim2.new(0.15, 0, 0, 26)
    oyBox.Position = UDim2.new(0.45, 0, 0, 66)
    oyBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    oyBox.BorderSizePixel = 0
    oyBox.Text = tostring(offsetY)
    oyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    oyBox.Font = Enum.Font.Gotham
    oyBox.TextSize = 12
    oyBox.Parent = body

    local applyBtn = Instance.new("TextButton")
    applyBtn.Size = UDim2.new(0.25, 0, 0, 26)
    applyBtn.Position = UDim2.new(0.7, 0, 0, 66)
    applyBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    applyBtn.BorderSizePixel = 0
    applyBtn.Text = "Áp dụng XY"
    applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyBtn.Font = Enum.Font.GothamBold
    applyBtn.TextSize = 11
    applyBtn.Parent = body

    -- Hàng nút X
    local xPlus1 = Instance.new("TextButton")
    xPlus1.Size = UDim2.new(0.15, 0, 0, 22)
    xPlus1.Position = UDim2.new(0.05, 0, 0, 96)
    xPlus1.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    xPlus1.BorderSizePixel = 0
    xPlus1.Text = "X+1"
    xPlus1.TextColor3 = Color3.fromRGB(255, 255, 255)
    xPlus1.Font = Enum.Font.GothamBold
    xPlus1.TextSize = 10
    xPlus1.Parent = body

    local xMinus1 = Instance.new("TextButton")
    xMinus1.Size = UDim2.new(0.15, 0, 0, 22)
    xMinus1.Position = UDim2.new(0.22, 0, 0, 96)
    xMinus1.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    xMinus1.BorderSizePixel = 0
    xMinus1.Text = "X-1"
    xMinus1.TextColor3 = Color3.fromRGB(255, 255, 255)
    xMinus1.Font = Enum.Font.GothamBold
    xMinus1.TextSize = 10
    xMinus1.Parent = body

    local xPlus5 = Instance.new("TextButton")
    xPlus5.Size = UDim2.new(0.15, 0, 0, 22)
    xPlus5.Position = UDim2.new(0.42, 0, 0, 96)
    xPlus5.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    xPlus5.BorderSizePixel = 0
    xPlus5.Text = "X+5"
    xPlus5.TextColor3 = Color3.fromRGB(255, 255, 255)
    xPlus5.Font = Enum.Font.GothamBold
    xPlus5.TextSize = 10
    xPlus5.Parent = body

    local xMinus5 = Instance.new("TextButton")
    xMinus5.Size = UDim2.new(0.15, 0, 0, 22)
    xMinus5.Position = UDim2.new(0.62, 0, 0, 96)
    xMinus5.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    xMinus5.BorderSizePixel = 0
    xMinus5.Text = "X-5"
    xMinus5.TextColor3 = Color3.fromRGB(255, 255, 255)
    xMinus5.Font = Enum.Font.GothamBold
    xMinus5.TextSize = 10
    xMinus5.Parent = body

    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(0.15, 0, 0, 22)
    resetBtn.Position = UDim2.new(0.82, 0, 0, 96)
    resetBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    resetBtn.BorderSizePixel = 0
    resetBtn.Text = "Reset"
    resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.TextSize = 10
    resetBtn.Parent = body

    -- ===== TEST ACCEPT (v82) =====
    local testBtn = Instance.new("TextButton")
    testBtn.Size = UDim2.new(0.9, 0, 0, 34)
    testBtn.Position = UDim2.new(0.05, 0, 0, 124)
    testBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
    testBtn.BorderSizePixel = 0
    testBtn.Text = "TEST 5 CÁCH BẤM ACCEPT"
    testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testBtn.Font = Enum.Font.GothamBold
    testBtn.TextSize = 12
    testBtn.Parent = body

    -- ===== DANH SÁCH NGƯỜI CHƠI =====
    local playerHeader = Instance.new("TextLabel")
    playerHeader.Size = UDim2.new(0.9, 0, 0, 18)
    playerHeader.Position = UDim2.new(0.05, 0, 0, 162)
    playerHeader.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    playerHeader.BorderSizePixel = 0
    playerHeader.Text = "NGƯỜI CHƠI (click để chọn)"
    playerHeader.TextColor3 = Color3.fromRGB(220, 220, 220)
    playerHeader.Font = Enum.Font.GothamBold
    playerHeader.TextSize = 10
    playerHeader.TextXAlignment = Enum.TextXAlignment.Left
    playerHeader.Parent = body

    local playerScroll = Instance.new("ScrollingFrame")
    playerScroll.Size = UDim2.new(0.9, 0, 0, 70)
    playerScroll.Position = UDim2.new(0.05, 0, 0, 182)
    playerScroll.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    playerScroll.BorderSizePixel = 0
    playerScroll.ScrollBarThickness = 4
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerScroll.Parent = body

    local playerListLayout = Instance.new("UIListLayout")
    playerListLayout.Padding = UDim.new(0, 2)
    playerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    playerListLayout.Parent = playerScroll

    local selectedUserLbl = Instance.new("TextLabel")
    selectedUserLbl.Size = UDim2.new(0.9, 0, 0, 18)
    selectedUserLbl.Position = UDim2.new(0.05, 0, 0, 254)
    selectedUserLbl.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    selectedUserLbl.BorderSizePixel = 0
    selectedUserLbl.Text = "User: (chưa chọn)"
    selectedUserLbl.TextColor3 = Color3.fromRGB(255, 220, 120)
    selectedUserLbl.Font = Enum.Font.Gotham
    selectedUserLbl.TextSize = 10
    selectedUserLbl.TextXAlignment = Enum.TextXAlignment.Left
    selectedUserLbl.Parent = body

    -- ===== DANH SÁCH VẬT PHẨM =====
    local itemHeader = Instance.new("TextLabel")
    itemHeader.Size = UDim2.new(0.9, 0, 0, 18)
    itemHeader.Position = UDim2.new(0.05, 0, 0, 276)
    itemHeader.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    itemHeader.BorderSizePixel = 0
    itemHeader.Text = "VẬT PHẨM (click chọn/bỏ)"
    itemHeader.TextColor3 = Color3.fromRGB(220, 220, 220)
    itemHeader.Font = Enum.Font.GothamBold
    itemHeader.TextSize = 10
    itemHeader.TextXAlignment = Enum.TextXAlignment.Left
    itemHeader.Parent = body

    local itemScroll = Instance.new("ScrollingFrame")
    itemScroll.Size = UDim2.new(0.9, 0, 0, 90)
    itemScroll.Position = UDim2.new(0.05, 0, 0, 296)
    itemScroll.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    itemScroll.BorderSizePixel = 0
    itemScroll.ScrollBarThickness = 4
    itemScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    itemScroll.Parent = body

    local itemListLayout = Instance.new("UIListLayout")
    itemListLayout.Padding = UDim.new(0, 2)
    itemListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    itemListLayout.Parent = itemScroll

    local selectedItemsLbl = Instance.new("TextLabel")
    selectedItemsLbl.Size = UDim2.new(0.9, 0, 0, 36)
    selectedItemsLbl.Position = UDim2.new(0.05, 0, 0, 388)
    selectedItemsLbl.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    selectedItemsLbl.BorderSizePixel = 0
    selectedItemsLbl.Text = "Items: (chưa chọn)"
    selectedItemsLbl.TextColor3 = Color3.fromRGB(255, 220, 120)
    selectedItemsLbl.Font = Enum.Font.Gotham
    selectedItemsLbl.TextSize = 10
    selectedItemsLbl.TextXAlignment = Enum.TextXAlignment.Left
    selectedItemsLbl.TextYAlignment = Enum.TextYAlignment.Top
    selectedItemsLbl.TextWrapped = true
    selectedItemsLbl.Parent = body

    -- ===== START (v83) =====
    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(0.9, 0, 0, 36)
    startBtn.Position = UDim2.new(0.05, 0, 0, 428)
    startBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
    startBtn.BorderSizePixel = 0
    startBtn.Text = "AUTO TRADE: OFF"
    startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    startBtn.Font = Enum.Font.GothamBold
    startBtn.TextSize = 13
    startBtn.Parent = body

    local logLbl = Instance.new("TextLabel")
    logLbl.Size = UDim2.new(0.9, 0, 0, 140)
    logLbl.Position = UDim2.new(0.05, 0, 0, 468)
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
        if #cur > 1200 then cur = cur:sub(-1000) end
        logLbl.Text = cur .. "\n" .. s
    end
    local function refreshTitle()
        title.Text = "v83 Gộp (" .. PLATFORM .. ") X=" .. offsetX .. " Y=" .. offsetY
    end

    closeUI.MouseButton1Click:Connect(function() sg:Destroy() end)

    modeBtn.MouseButton1Click:Connect(function()
        if tradeMode == "WithItems" then
            tradeMode = "ReadyOnly"
            modeBtn.Text = "MODE: CHỈ READY + AUTO ACCEPT"
            modeBtn.BackgroundColor3 = Color3.fromRGB(200, 130, 40)
        else
            tradeMode = "WithItems"
            modeBtn.Text = "MODE: CÓ VẬT PHẨM (bấm đổi)"
            modeBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
        end
        appendLog("Mode: " .. tradeMode)
    end)

    applyBtn.MouseButton1Click:Connect(function()
        local nx = tonumber(oxBox.Text)
        local ny = tonumber(oyBox.Text)
        if nx then offsetX = nx end
        if ny then offsetY = ny end
        refreshTitle()
        setStatus(string.format("Đã lưu X=%d Y=%d", offsetX, offsetY),
            Color3.fromRGB(120, 220, 120))
        appendLog(string.format("X=%d Y=%d", offsetX, offsetY))
    end)

    xPlus1.MouseButton1Click:Connect(function()
        offsetX = offsetX + 1
        oxBox.Text = tostring(offsetX)
        refreshTitle()
    end)
    xMinus1.MouseButton1Click:Connect(function()
        offsetX = offsetX - 1
        oxBox.Text = tostring(offsetX)
        refreshTitle()
    end)
    xPlus5.MouseButton1Click:Connect(function()
        offsetX = offsetX + 5
        oxBox.Text = tostring(offsetX)
        refreshTitle()
    end)
    xMinus5.MouseButton1Click:Connect(function()
        offsetX = offsetX - 5
        oxBox.Text = tostring(offsetX)
        refreshTitle()
    end)
    resetBtn.MouseButton1Click:Connect(function()
        offsetX = 0
        oxBox.Text = "0"
        refreshTitle()
    end)

    testBtn.MouseButton1Click:Connect(function()
        local btn = getAcceptButton()
        if not btn then appendLog("Không có popup"); return end
        local ap = btn.AbsolutePosition
        local sz = btn.AbsoluteSize
        local cx = ap.X + sz.X / 2 + offsetX
        local cy = ap.Y + sz.Y / 2 + offsetY
        task.spawn(function()
            setStatus(string.format("Test (%.0f, %.0f)", cx, cy),
                Color3.fromRGB(200, 200, 120))
            appendLog(string.format("Test (%.0f, %.0f) X=%d Y=%d",
                cx, cy, offsetX, offsetY))
            local ok, r = tryAll(cx, cy)
            if ok then
                appendLog("✔ " .. r)
                setStatus("✔ " .. r, Color3.fromRGB(120, 220, 120))
            else
                appendLog("✘ ALL FAIL")
                setStatus("✘ Fail - tinh chỉnh X", Color3.fromRGB(255, 120, 120))
            end
        end)
    end)

    -- ===== REFRESH PLAYER/ITEM LIST =====
    local function refreshPlayerList()
        for _, c in ipairs(playerScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local list = fetchPlayerList()
        if #list == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, 0, 0, 22)
            empty.BackgroundTransparency = 1
            empty.Text = "(Mở Frame_Trade để load)"
            empty.TextColor3 = Color3.fromRGB(180, 180, 180)
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 10
            empty.Parent = playerScroll
            playerScroll.CanvasSize = UDim2.new(0, 0, 0, 24)
            return
        end
        for i, uname in ipairs(list) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 22)
            btn.BackgroundColor3 = (selectedUser == uname)
                and Color3.fromRGB(80, 160, 80)
                or Color3.fromRGB(60, 60, 60)
            btn.BorderSizePixel = 0
            btn.Text = uname
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 10
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.LayoutOrder = i
            btn.Parent = playerScroll
            btn.MouseButton1Click:Connect(function()
                selectedUser = uname
                selectedUserLbl.Text = "User: " .. uname
                appendLog("Chọn user: " .. uname)
                refreshPlayerList()
            end)
        end
        playerScroll.CanvasSize = UDim2.new(0, 0, 0, #list * 24)
    end

    local function updateSelectedItemsLbl()
        if #selectedItems == 0 then
            selectedItemsLbl.Text = "Items: (chưa chọn)"
            return
        end
        local parts = {}
        for _, it in ipairs(selectedItems) do
            table.insert(parts, string.format("%s x%d", it.name, it.qty))
        end
        selectedItemsLbl.Text = "Items: " .. table.concat(parts, ", ")
    end

    local function refreshItemList()
        for _, c in ipairs(itemScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local list = fetchItemList()
        if #list == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, 0, 0, 22)
            empty.BackgroundTransparency = 1
            empty.Text = "(Mở bảng Trading để load item)"
            empty.TextColor3 = Color3.fromRGB(180, 180, 180)
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 10
            empty.Parent = itemScroll
            itemScroll.CanvasSize = UDim2.new(0, 0, 0, 24)
            return
        end
        for i, iname in ipairs(list) do
            local isSelected = false
            for _, it in ipairs(selectedItems) do
                if it.name:lower() == iname:lower() then isSelected = true; break end
            end
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 22)
            btn.BackgroundColor3 = isSelected
                and Color3.fromRGB(80, 160, 80)
                or Color3.fromRGB(60, 60, 60)
            btn.BorderSizePixel = 0
            btn.Text = iname
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 10
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.LayoutOrder = i
            btn.Parent = itemScroll
            btn.MouseButton1Click:Connect(function()
                local found = nil
                for idx, it in ipairs(selectedItems) do
                    if it.name:lower() == iname:lower() then found = idx; break end
                end
                if found then
                    table.remove(selectedItems, found)
                    appendLog("Bỏ: " .. iname)
                else
                    table.insert(selectedItems, {name = iname, qty = 1})
                    appendLog("Chọn: " .. iname .. " x1")
                end
                updateSelectedItemsLbl()
                refreshItemList()
            end)
        end
        itemScroll.CanvasSize = UDim2.new(0, 0, 0, #list * 24)
    end

    task.spawn(function()
        while sg.Parent do
            pcall(refreshPlayerList)
            pcall(refreshItemList)
            task.wait(CONFIG.RefreshRate)
        end
    end)

    -- ============================================================
    -- LUỒNG TRADING
    -- ============================================================
    local function doFullFlow()
        local tui = getTradeFrameUI()
        if tui and not tui.Visible then
            pcall(function() tui.Visible = true end)
            task.wait(0.3)
        end
        if selectedUser and selectedUser ~= "" then
            local ok, reason = inviteUserInSelectBar(selectedUser)
            if ok then
                appendLog("Đã invite: " .. selectedUser)
                return true
            else
                appendLog("Invite fail: " .. tostring(reason))
            end
        end
        return false
    end

    local function doTradingFlow()
        if tradeMode == "WithItems" then
            for _, it in ipairs(selectedItems) do
                if it.name and it.name ~= "" and it.qty and it.qty > 0 then
                    local ok, reason = addItemDirect(it.name, it.qty)
                    if ok then
                        appendLog(string.format("✔ %s x%d", it.name, it.qty))
                    else
                        appendLog(string.format("✘ %s: %s", it.name, tostring(reason)))
                    end
                    task.wait(CONFIG.ItemDelay)
                end
            end
            local ti = getTradeInventory()
            if ti then
                local close = ti:FindFirstChild("Close_")
                if close then safeClick(close, "close inv") end
                task.wait(0.2)
                if ti.Visible then pcall(function() ti.Visible = false end) end
            end
        end

        task.wait(CONFIG.ReadyDelay)
        local ready = getReadyButton()
        if ready then
            safeClick(ready, "Ready")
            appendLog("✔ Đã bấm Ready")
        end
    end

    -- ============================================================
    -- LOOP CHÍNH (gộp v82 accept + v83 trade)
    -- ============================================================
    task.spawn(function()
        local wasPopupOpen = false
        while sg.Parent do
            if autoEnabled then
                -- Ưu tiên 1: POPUP ACCEPT (dùng tryAll của v82)
                if isPopupOpen() then
                    if not wasPopupOpen then
                        setStatus("Có popup -> accept", Color3.fromRGB(200,200,120))
                        appendLog("Phát hiện popup, accept")
                        local btn = getAcceptButton()
                        if btn then
                            local ap = btn.AbsolutePosition
                            local sz = btn.AbsoluteSize
                            local cx = ap.X + sz.X / 2 + offsetX
                            local cy = ap.Y + sz.Y / 2 + offsetY
                            local ok, r = tryAll(cx, cy)
                            appendLog(ok and ("✔ Auto accept: " .. r) or "✘ Auto accept fail")
                            if ok then
                                setStatus("✔ Accept OK", Color3.fromRGB(120,220,120))
                            else
                                setStatus("✘ Accept fail - tinh chỉnh X", Color3.fromRGB(255,120,120))
                            end
                        end
                    end
                    wasPopupOpen = true
                else
                    wasPopupOpen = false
                    if isTradingOpen() then
                        setStatus("Trading mở, xử lý...", Color3.fromRGB(200,200,120))
                        appendLog("Bảng Trading mở (mode=" .. tradeMode .. ")")
                        doTradingFlow()
                        setStatus("Đã Ready, chờ đối phương", Color3.fromRGB(120,220,120))
                        local t0 = os.clock()
                        while isTradingOpen() and os.clock() - t0 < 60 do
                            task.wait(0.5)
                            if isPopupOpen() then
                                local btn = getAcceptButton()
                                if btn then
                                    local ap = btn.AbsolutePosition
                                    local sz = btn.AbsoluteSize
                                    tryAll(ap.X + sz.X / 2 + offsetX, ap.Y + sz.Y / 2 + offsetY)
                                end
                            end
                        end
                        appendLog("Trade xong")
                        task.wait(1)
                    else
                        setStatus("Đang mời " .. (selectedUser or "..."), Color3.fromRGB(200,200,120))
                        doFullFlow()
                        task.wait(CONFIG.LoopDelay)
                    end
                end
            end
            task.wait(0.3)
        end
    end)

    startBtn.MouseButton1Click:Connect(function()
        autoEnabled = not autoEnabled
        if autoEnabled then
            startBtn.Text = "AUTO TRADE: ON"
            startBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            setStatus("AUTO ON", Color3.fromRGB(120,220,120))
            appendLog(string.format("AUTO ON X=%d Y=%d user=%s mode=%s",
                offsetX, offsetY, tostring(selectedUser), tradeMode))
        else
            startBtn.Text = "AUTO TRADE: OFF"
            startBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
            setStatus("AUTO OFF", Color3.fromRGB(200,200,120))
            appendLog("AUTO OFF")
        end
    end)
end

if game.PlaceId ~= CONFIG.GameID then
    warn("[AutoTrade] PlaceId không khớp:", game.PlaceId)
end

buildUI()
log("v83 Gộp sẵn sàng. Accept giữ nguyên v82, chọn user/item bằng click.")
