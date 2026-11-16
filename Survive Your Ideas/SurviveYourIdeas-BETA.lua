-- ============================================
-- SURVIVE YOUR IDEAS - COMMAND BROWSER UI
-- + Minimize to floating icon / restore
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local WriterRemotes = ReplicatedStorage:FindFirstChild("WriterRemotes")
local SubmitWord = WriterRemotes and WriterRemotes:FindFirstChild("SubmitWord")
local WriterChosen = WriterRemotes and WriterRemotes:FindFirstChild("WriterChosen")

local IsMyTurn = false
if WriterChosen then
    WriterChosen.OnClientEvent:Connect(function(name)
        IsMyTurn = (name == LocalPlayer.Name)
    end)
end

-- ============================================
-- DATA LỆNH
-- ============================================
local CommandData = {
    { word = "Atomic",      effect = "danger",  info = "Thả bom hạt nhân. Toàn bộ người chơi phải vào bunker để sống sót. Sát thương cực lớn ngoài trời." },
    { word = "Mahoraga",    effect = "danger",  info = "Triệu hồi Mahoraga - nó thích nghi với mọi đòn đánh. Mỗi lần bị hit bởi chiêu mới, nó kháng lại chiêu đó." },
    { word = "godzilla",    effect = "danger",  info = "Kaiju khổng lồ nổi lên từ biển. Né chân nó và tia laze xanh. Sát thương diện rộng." },
    { word = "supernova",   effect = "danger",  info = "Mặt trời phát nổ! Tìm bóng râm ngay lập tức nếu không muốn chết cháy." },
    { word = "tornado",     effect = "danger",  info = "Lốc xoáy lang thang khắp map. Tránh xa hoặc trốn trong shelter." },
    { word = "zombie",      effect = "danger",  info = "Zombie săn đuổi không ngừng. Leo lên chỗ cao và di chuyển liên tục." },
    { word = "storm",       effect = "danger",  info = "Bão lớn: mưa, sét, gió. Trốn sau vật thể rắn." },
    { word = "frog",        effect = "danger",  info = "Ếch khổng lồ! Tránh xa tầm lưỡi của chúng." },
    { word = "Zombiedan",   effect = "danger",  info = "Đại dịch apocalypse! Chạy ra khỏi bóng của thiên thạch khổng lồ." },
    { word = "safety",      effect = "help",    info = "Safe house mở ra! Chạy vào trong - nó không tồn tại mãi đâu." },
    { word = "heal",        effect = "help",    info = "Medkit rơi xuống! Theo tín hiệu pháo đỏ - ai đến trước được trước." },
    { word = "honoredone",  effect = "help",    info = "INFINITY! Không ai đến được writer trong 30 giây... càng gần càng chậm." },
    { word = "time",        effect = "neutral", info = "Thời gian ngừng trôi với mọi người khác! 5 giây... hy vọng họ thân thiện." },
    { word = "jesus",       effect = "neutral", info = "JESUS xuất hiện ở trận chung kết!" },
    { word = "immortality", effect = "neutral", info = "FORCEFIELD bị tắt trong trận chung kết!" },
    { word = "jumps",       effect = "neutral", info = "Mọi người nhảy không ngừng! Gõ 'idle' để dừng lại." },
}

local SelectedCommand = nil
local SubmitLog = {}

local function submitWord(word)
    if not SubmitWord then return end
    if not IsMyTurn then
        table.insert(SubmitLog, { text = "Chưa đến lượt: " .. word, ok = false })
        return
    end
    local ok = pcall(function() SubmitWord:FireServer(word) end)
    table.insert(SubmitLog, { text = (ok and "Đã gửi: " or "Lỗi: ") .. word, ok = ok })
    if #SubmitLog > 50 then table.remove(SubmitLog, 1) end
end

-- ============================================
-- TẠO GUI
-- ============================================
local function createGUI()
    local old = CoreGui:FindFirstChild("SYI_Browser")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYI_Browser"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.Parent = CoreGui

    -- ===== FLOATING ICON (ẩn mặc định) =====
    local floatingIcon = Instance.new("TextButton")
    floatingIcon.Name = "FloatingIcon"
    floatingIcon.Size = UDim2.new(0, 52, 0, 52)
    floatingIcon.Position = UDim2.new(0, 20, 0.5, -26)
    floatingIcon.BackgroundColor3 = Color3.fromRGB(120, 80, 220)
    floatingIcon.BorderSizePixel = 0
    floatingIcon.Text = "SYI"
    floatingIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    floatingIcon.Font = Enum.Font.GothamBold
    floatingIcon.TextSize = 14
    floatingIcon.Visible = false
    floatingIcon.Active = true
    floatingIcon.Draggable = true
    floatingIcon.Parent = gui

    local fiCorner = Instance.new("UICorner")
    fiCorner.CornerRadius = UDim.new(1, 0)
    fiCorner.Parent = floatingIcon

    local fiStroke = Instance.new("UIStroke")
    fiStroke.Color = Color3.fromRGB(180, 140, 255)
    fiStroke.Thickness = 2
    fiStroke.Transparency = 0.3
    fiStroke.Parent = floatingIcon

    -- ===== MAIN FRAME =====
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 620, 0, 420)
    main.Position = UDim2.new(0.5, -310, 0.5, -210)
    main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = gui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = main

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(120, 80, 220)
    mainStroke.Thickness = 1.5
    mainStroke.Transparency = 0.2
    mainStroke.Parent = main

    -- ===== TITLE BAR =====
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 42)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 28, 55)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main

    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 12)
    tbCorner.Parent = titleBar

    local tbFix = Instance.new("Frame")
    tbFix.Size = UDim2.new(1, 0, 0, 12)
    tbFix.Position = UDim2.new(0, 0, 1, -12)
    tbFix.BackgroundColor3 = Color3.fromRGB(35, 28, 55)
    tbFix.BorderSizePixel = 0
    tbFix.Parent = titleBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -160, 1, 0)
    title.Position = UDim2.new(0, 16, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "SYI Command Browser"
    title.TextColor3 = Color3.fromRGB(220, 200, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    -- Status dot
    local statusDot = Instance.new("Frame")
    statusDot.Name = "StatusDot"
    statusDot.Size = UDim2.new(0, 10, 0, 10)
    statusDot.Position = UDim2.new(1, -140, 0.5, -5)
    statusDot.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
    statusDot.BorderSizePixel = 0
    statusDot.Parent = titleBar

    local sdCorner = Instance.new("UICorner")
    sdCorner.CornerRadius = UDim.new(1, 0)
    sdCorner.Parent = statusDot

    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(0, 60, 1, 0)
    statusText.Position = UDim2.new(1, -126, 0, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "Chờ lượt"
    statusText.TextColor3 = Color3.fromRGB(180, 180, 200)
    statusText.Font = Enum.Font.Gotham
    statusText.TextSize = 11
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Parent = titleBar

    -- Nút MINIMIZE (dấu —)
    local minBtn = Instance.new("TextButton")
    minBtn.Name = "MinimizeBtn"
    minBtn.Size = UDim2.new(0, 28, 0, 28)
    minBtn.Position = UDim2.new(1, -72, 0.5, -14)
    minBtn.BackgroundColor3 = Color3.fromRGB(80, 70, 120)
    minBtn.BorderSizePixel = 0
    minBtn.Text = "—"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 18
    minBtn.Parent = titleBar

    local mbCorner = Instance.new("UICorner")
    mbCorner.CornerRadius = UDim.new(0, 6)
    mbCorner.Parent = minBtn

    -- Nút CLOSE (×)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -36, 0.5, -14)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 80)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.Parent = titleBar

    local cbCorner = Instance.new("UICorner")
    cbCorner.CornerRadius = UDim.new(0, 6)
    cbCorner.Parent = closeBtn

    -- ===== BODY 2 CỘT =====
    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Size = UDim2.new(1, -16, 1, -58)
    body.Position = UDim2.new(0, 8, 0, 50)
    body.BackgroundTransparency = 1
    body.Parent = main

    -- ----- CỘT TRÁI -----
    local left = Instance.new("Frame")
    left.Size = UDim2.new(0.42, -4, 1, 0)
    left.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
    left.BorderSizePixel = 0
    left.Parent = body

    local lc = Instance.new("UICorner")
    lc.CornerRadius = UDim.new(0, 8)
    lc.Parent = left

    local leftHeader = Instance.new("TextLabel")
    leftHeader.Size = UDim2.new(1, 0, 0, 28)
    leftHeader.BackgroundColor3 = Color3.fromRGB(40, 40, 58)
    leftHeader.BorderSizePixel = 0
    leftHeader.Text = "DANH SÁCH LỆNH"
    leftHeader.TextColor3 = Color3.fromRGB(180, 160, 240)
    leftHeader.Font = Enum.Font.GothamBold
    leftHeader.TextSize = 12
    leftHeader.Parent = left

    local lhCorner = Instance.new("UICorner")
    lhCorner.CornerRadius = UDim.new(0, 8)
    lhCorner.Parent = leftHeader

    local lhFix = Instance.new("Frame")
    lhFix.Size = UDim2.new(1, 0, 0, 8)
    lhFix.Position = UDim2.new(0, 0, 1, -8)
    lhFix.BackgroundColor3 = Color3.fromRGB(40, 40, 58)
    lhFix.BorderSizePixel = 0
    lhFix.Parent = leftHeader

    local list = Instance.new("ScrollingFrame")
    list.Name = "List"
    list.Size = UDim2.new(1, -8, 1, -90)
    list.Position = UDim2.new(0, 4, 0, 32)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 5
    list.ScrollBarImageColor3 = Color3.fromRGB(120, 100, 200)
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.Parent = left

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 4)
    listLayout.Parent = list

    local listPad = Instance.new("UIPadding")
    listPad.PaddingLeft = UDim.new(0, 2)
    listPad.PaddingRight = UDim.new(0, 2)
    listPad.PaddingTop = UDim.new(0, 4)
    listPad.Parent = list

    local inputArea = Instance.new("Frame")
    inputArea.Size = UDim2.new(1, -8, 0, 52)
    inputArea.Position = UDim2.new(0, 4, 1, -56)
    inputArea.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
    inputArea.BorderSizePixel = 0
    inputArea.Parent = left

    local iaCorner = Instance.new("UICorner")
    iaCorner.CornerRadius = UDim.new(0, 6)
    iaCorner.Parent = inputArea

    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -60, 0, 32)
    inputBox.Position = UDim2.new(0, 6, 0, 10)
    inputBox.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    inputBox.BorderSizePixel = 0
    inputBox.Text = ""
    inputBox.PlaceholderText = "Nhập lệnh tùy chỉnh..."
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 13
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = inputArea

    local ibCorner = Instance.new("UICorner")
    ibCorner.CornerRadius = UDim.new(0, 4)
    ibCorner.Parent = inputBox

    local sendBtn = Instance.new("TextButton")
    sendBtn.Size = UDim2.new(0, 48, 0, 32)
    sendBtn.Position = UDim2.new(1, -54, 0, 10)
    sendBtn.BackgroundColor3 = Color3.fromRGB(100, 70, 200)
    sendBtn.BorderSizePixel = 0
    sendBtn.Text = "Gửi"
    sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    sendBtn.Font = Enum.Font.GothamBold
    sendBtn.TextSize = 13
    sendBtn.Parent = inputArea

    local sbCorner = Instance.new("UICorner")
    sbCorner.CornerRadius = UDim.new(0, 4)
    sbCorner.Parent = sendBtn

    -- ----- CỘT PHẢI -----
    local right = Instance.new("Frame")
    right.Size = UDim2.new(0.58, -4, 1, 0)
    right.Position = UDim2.new(0.42, 4, 0, 0)
    right.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
    right.BorderSizePixel = 0
    right.Parent = body

    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 8)
    rc.Parent = right

    local rightHeader = Instance.new("TextLabel")
    rightHeader.Size = UDim2.new(1, 0, 0, 28)
    rightHeader.BackgroundColor3 = Color3.fromRGB(40, 40, 58)
    rightHeader.BorderSizePixel = 0
    rightHeader.Text = "THÔNG TIN LỆNH"
    rightHeader.TextColor3 = Color3.fromRGB(180, 160, 240)
    rightHeader.Font = Enum.Font.GothamBold
    rightHeader.TextSize = 12
    rightHeader.Parent = right

    local rhCorner = Instance.new("UICorner")
    rhCorner.CornerRadius = UDim.new(0, 8)
    rhCorner.Parent = rightHeader

    local rhFix = Instance.new("Frame")
    rhFix.Size = UDim2.new(1, 0, 0, 8)
    rhFix.Position = UDim2.new(0, 0, 1, -8)
    rhFix.BackgroundColor3 = Color3.fromRGB(40, 40, 58)
    rhFix.BorderSizePixel = 0
    rhFix.Parent = rightHeader

    local imageFrame = Instance.new("Frame")
    imageFrame.Name = "ImageFrame"
    imageFrame.Size = UDim2.new(1, -16, 0, 120)
    imageFrame.Position = UDim2.new(0, 8, 0, 36)
    imageFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    imageFrame.BorderSizePixel = 0
    imageFrame.ClipsDescendants = true
    imageFrame.Parent = right

    local ifCorner = Instance.new("UICorner")
    ifCorner.CornerRadius = UDim.new(0, 6)
    ifCorner.Parent = imageFrame

    local imagePlaceholder = Instance.new("TextLabel")
    imagePlaceholder.Size = UDim2.new(1, 0, 1, 0)
    imagePlaceholder.BackgroundTransparency = 1
    imagePlaceholder.Text = "Ảnh sẽ được thêm sau"
    imagePlaceholder.TextColor3 = Color3.fromRGB(80, 80, 100)
    imagePlaceholder.Font = Enum.Font.Gotham
    imagePlaceholder.TextSize = 12
    imagePlaceholder.Parent = imageFrame

    local wordTitle = Instance.new("TextLabel")
    wordTitle.Size = UDim2.new(1, -16, 0, 32)
    wordTitle.Position = UDim2.new(0, 8, 0, 162)
    wordTitle.BackgroundTransparency = 1
    wordTitle.Text = "Chọn một lệnh"
    wordTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    wordTitle.Font = Enum.Font.GothamBold
    wordTitle.TextSize = 20
    wordTitle.TextXAlignment = Enum.TextXAlignment.Left
    wordTitle.Parent = right

    local effectBadge = Instance.new("TextLabel")
    effectBadge.Size = UDim2.new(0, 80, 0, 22)
    effectBadge.Position = UDim2.new(0, 8, 0, 196)
    effectBadge.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    effectBadge.BorderSizePixel = 0
    effectBadge.Text = "-"
    effectBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
    effectBadge.Font = Enum.Font.GothamBold
    effectBadge.TextSize = 11
    effectBadge.Parent = right

    local ebCorner = Instance.new("UICorner")
    ebCorner.CornerRadius = UDim.new(0, 4)
    ebCorner.Parent = effectBadge

    local descScroll = Instance.new("ScrollingFrame")
    descScroll.Size = UDim2.new(1, -16, 0, 100)
    descScroll.Position = UDim2.new(0, 8, 0, 226)
    descScroll.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    descScroll.BorderSizePixel = 0
    descScroll.ScrollBarThickness = 5
    descScroll.ScrollBarImageColor3 = Color3.fromRGB(120, 100, 200)
    descScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    descScroll.Parent = right

    local dsCorner = Instance.new("UICorner")
    dsCorner.CornerRadius = UDim.new(0, 6)
    dsCorner.Parent = descScroll

    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -12, 0, 0)
    descLabel.Position = UDim2.new(0, 6, 0, 6)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = "Thông tin chi tiết của lệnh sẽ hiển thị ở đây khi bạn chọn một lệnh bên trái."
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 13
    descLabel.TextWrapped = true
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    descLabel.Parent = descScroll

    local submitSelectedBtn = Instance.new("TextButton")
    submitSelectedBtn.Size = UDim2.new(1, -16, 0, 40)
    submitSelectedBtn.Position = UDim2.new(0, 8, 1, -48)
    submitSelectedBtn.BackgroundColor3 = Color3.fromRGB(100, 70, 200)
    submitSelectedBtn.BorderSizePixel = 0
    submitSelectedBtn.Text = "GỬI LỆNH NÀY"
    submitSelectedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitSelectedBtn.Font = Enum.Font.GothamBold
    submitSelectedBtn.TextSize = 14
    submitSelectedBtn.Parent = right

    local ssCorner = Instance.new("UICorner")
    ssCorner.CornerRadius = UDim.new(0, 8)
    ssCorner.Parent = submitSelectedBtn

    -- ===== TẠO BUTTON LIST =====
    local buttons = {}
    for i, cmd in ipairs(CommandData) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -6, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(34, 34, 48)
        btn.BorderSizePixel = 0
        btn.Text = "  " .. cmd.word
        btn.TextColor3 = Color3.fromRGB(200, 200, 220)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.LayoutOrder = i
        btn.Parent = list

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 4)
        bCorner.Parent = btn

        buttons[cmd.word] = btn

        btn.MouseButton1Click:Connect(function()
            for _, b in pairs(buttons) do
                b.BackgroundColor3 = Color3.fromRGB(34, 34, 48)
                b.TextColor3 = Color3.fromRGB(200, 200, 220)
            end
            btn.BackgroundColor3 = Color3.fromRGB(100, 70, 200)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)

            SelectedCommand = cmd
            wordTitle.Text = cmd.word
            effectBadge.Text = cmd.effect:upper()
            local color = Color3.fromRGB(80, 80, 100)
            if cmd.effect == "danger" then color = Color3.fromRGB(200, 60, 60)
            elseif cmd.effect == "help" then color = Color3.fromRGB(60, 180, 100)
            elseif cmd.effect == "neutral" then color = Color3.fromRGB(180, 160, 60) end
            effectBadge.BackgroundColor3 = color
            descLabel.Text = cmd.info
            task.defer(function()
                descScroll.CanvasSize = UDim2.new(0, 0, 0, descLabel.TextBounds.Y + 12)
            end)
        end)
    end

    task.defer(function()
        list.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
    end)

    -- ===== MINIMIZE / RESTORE =====
    local isMinimized = false
    local minimizeTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local function minimizeMenu()
        if isMinimized then return end
        isMinimized = true

        -- Lưu vị trí hiện tại của floating icon để không bị nhảy
        -- Thu nhỏ main về tâm
        local shrinkTween = TweenService:Create(main, minimizeTweenInfo, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1,
        })
        shrinkTween:Play()

        -- Ẩn stroke
        TweenService:Create(mainStroke, minimizeTweenInfo, { Transparency = 1 }):Play()

        -- Hiện floating icon (fade in + scale)
        floatingIcon.Visible = true
        floatingIcon.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(floatingIcon, minimizeTweenInfo, {
            Size = UDim2.new(0, 52, 0, 52),
        }):Play()

        shrinkTween.Completed:Connect(function()
            main.Visible = false
        end)
    end

    local function restoreMenu()
        if not isMinimized then return end
        isMinimized = false

        main.Visible = true
        main.BackgroundTransparency = 0
        main.Size = UDim2.new(0, 0, 0, 0)
        main.Position = UDim2.new(0.5, 0, 0.5, 0)
        mainStroke.Transparency = 0.2

        TweenService:Create(main, minimizeTweenInfo, {
            Size = UDim2.new(0, 620, 0, 420),
            Position = UDim2.new(0.5, -310, 0.5, -210),
        }):Play()

        -- Ẩn floating icon
        local tween = TweenService:Create(floatingIcon, minimizeTweenInfo, {
            Size = UDim2.new(0, 0, 0, 0),
        })
        tween:Play()
        tween.Completed:Connect(function()
            floatingIcon.Visible = false
            floatingIcon.Size = UDim2.new(0, 52, 0, 52)
        end)
    end

    minBtn.MouseButton1Click:Connect(minimizeMenu)
    floatingIcon.MouseButton1Click:Connect(restoreMenu)

    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    -- ===== EVENTS =====
    local function sendCustom()
        local w = inputBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if w ~= "" then
            submitWord(w)
            inputBox.Text = ""
        end
    end
    sendBtn.MouseButton1Click:Connect(sendCustom)
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then sendCustom() end
    end)

    submitSelectedBtn.MouseButton1Click:Connect(function()
        if SelectedCommand then submitWord(SelectedCommand.word) end
    end)

    -- ===== STATUS LOOP =====
    task.spawn(function()
        while gui.Parent do
            if IsMyTurn then
                statusDot.BackgroundColor3 = Color3.fromRGB(100, 255, 120)
                statusText.Text = "LƯỢT BẠN"
                statusText.TextColor3 = Color3.fromRGB(100, 255, 120)
            else
                statusDot.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
                statusText.Text = "Chờ lượt"
                statusText.TextColor3 = Color3.fromRGB(180, 180, 200)
            end
            task.wait(0.4)
        end
    end)

    print("[UI] GUI load xong. Nút '—' để ẩn, icon 'SYI' để mở lại.")
end

createGUI()
