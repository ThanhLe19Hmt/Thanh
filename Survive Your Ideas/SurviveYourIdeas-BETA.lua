-- ============================================
-- SURVIVE YOUR IDEAS - COMMAND BROWSER (MODERN UI)
-- + Fix triệt để lỗi xuống dòng & đè chữ Dropdown
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
local AutoEnabled = false
local AutoWord = nil

if WriterChosen then
    WriterChosen.OnClientEvent:Connect(function(name)
        IsMyTurn = (name == LocalPlayer.Name)
        if IsMyTurn and AutoEnabled and AutoWord then
            task.wait(0.5)
            if IsMyTurn and AutoEnabled and SubmitWord then
                pcall(function() SubmitWord:FireServer(AutoWord) end)
                IsMyTurn = false
            end
        end
    end)
end

-- ⚠️ THAY ID ẢNH VÀO ĐÂY
local MAHORAGA_IMAGE_ID = "rbxassetid://106783163967957"
local NUKE_IMAGE_ID = "rbxassetid://105196171886899"

-- ============================================
-- DATA LỆNH
-- ============================================
local CommandData = {
    -- Vũ Khí
    { word = "Minigun", effect = "danger", info = "Một khẩu minigun quay lên và bắn." },
    { word = "Airstrike", effect = "danger", info = "Một chiếc máy bay thả bom xuống đảo." },
    { word = "Tank", effect = "danger", info = "Một chiếc xe tăng quân đội bắn vào người chơi." },
    { word = "Laser", effect = "danger", info = "Các tia laser quét ngang sàn nhà." },
    { word = "Gun", effect = "help", info = "Thả một khẩu súng ngẫu nhiên, với khói đỏ đánh dấu vị trí của nó." },
    { word = "Bomb", effect = "danger", info = "Một quả bom theo dõi bám theo người chơi trước khi phát nổ." },
    { word = "Knife", effect = "help", info = "Cung cấp một vũ khí cận chiến để tấn công người chơi khác." },
    { word = "Baseball Bat", effect = "help", info = "Tạo ra những cây gậy bóng chày có thể sử dụng với âm thanh 'bonk'." },
    -- Quái vật
    { word = "Robot", effect = "neutral", info = "Bắt đầu một cuộc chạm trán đèn đỏ, đèn xanh." },
    { word = "Mahoraga", effect = "danger", image = MAHORAGA_IMAGE_ID, info = "Triệu hồi Mahoraga - nó thích nghi với mọi đòn đánh." },
    { word = "Wizard", effect = "neutral", info = "Ban cho phép thuật thu nhỏ trong 30 giây." },
    { word = "Mummy", effect = "danger", info = "Tạo ra những xác ướp có thể quấn người chơi lại." },
    { word = "godzilla", effect = "danger", info = "Một sinh vật khổng lồ trồi lên từ biển và bắn một tia sáng xanh." },
    { word = "Angel", effect = "danger", info = "Triệu hồi một thiên thần khổng lồ tấn công những người chơi còn sống." },
    { word = "Giant", effect = "danger", info = "Một người khổng lồ noob đi quanh đảo và có thể giẫm lên người chơi." },
    { word = "zombie", effect = "danger", info = "Một đám zombie liên tục săn lùng người chơi." },
    { word = "Slenderman", effect = "danger", info = "Tránh nhìn vào Slenderman." },
    { word = "Skeleton", effect = "danger", info = "Những bộ xương ném xương vào người chơi." },
    { word = "Pirate", effect = "danger", info = "Một con tàu cướp biển bắn đại bác vào đảo." },
    { word = "Invisible", effect = "danger", info = "Một sự hiện diện vô hình ám ảnh người chơi." },
    { word = "Aliens", effect = "danger", info = "Người ngoài hành tinh bắt cóc người chơi bằng ánh sáng." },
    { word = "Slime", effect = "danger", info = "Những con slime bật nhảy có thể nghiền nát người chơi." },
    { word = "Vampire", effect = "danger", info = "Một ma cà rồng xuất hiện từ quan tài." },
    { word = "Monster", effect = "danger", info = "Một sinh vật lang thang nghe thấy tiếng động và tấn công." },
    { word = "Dragon", effect = "danger", info = "Một con rồng bay lơ lửng phía trên trước khi phun lửa." },
    -- Động vật
    { word = "KingKong", effect = "danger", info = "Một con khỉ đột khổng lồ tìm kiếm người chơi để ném." },
    { word = "Bees", effect = "danger", info = "Một đàn ong tấn công người chơi đi qua nó." },
    { word = "Dinosaur", effect = "danger", info = "Một con T-Rex khổng lồ săn lùng người chơi trên mặt đất." },
    { word = "Elephant", effect = "danger", info = "Phun nước xung quanh." },
    { word = "Octopus", effect = "danger", info = "Một con bạch tuộc khổng lồ tóm lấy người chơi." },
    { word = "Monkey", effect = "danger", info = "Những con khỉ ném vỏ chuối xung quanh." },
    { word = "Crab", effect = "danger", info = "Tạo ra một nhóm cua." },
    { word = "Spider", effect = "danger", info = "Tạo ra một con nhện khổng lồ và những con nhện nhỏ hơn." },
    -- Thiên nhiên
    { word = "Swamp", effect = "neutral", info = "Thêm những vũng nước đục làm chậm người chơi khi đi qua." },
    { word = "Desert", effect = "neutral", info = "Biến đổi hòn đảo thành sa mạc." },
    { word = "Mud", effect = "neutral", info = "Thêm những vũng bùn làm chậm di chuyển." },
    -- Thời tiết
    { word = "Rain", effect = "neutral", info = "Mưa liên tục làm bản đồ trơn trượt." },
    { word = "Ice", effect = "neutral", info = "Làm cho bề mặt trơn trượt." },
    { word = "Snow", effect = "danger", info = "Tạo ra một cơn bão tuyết; trú ẩn dưới mái nhà hoặc gần lửa." },
    { word = "Night", effect = "neutral", info = "Biến đổi hòn đảo thành ban đêm." },
    { word = "Day", effect = "neutral", info = "Mang mặt trời lên." },
    { word = "Storm", effect = "danger", info = "Thêm mưa, gió giật, sấm và sét nguy hiểm." },
    { word = "Fog", effect = "neutral", info = "Giảm tầm nhìn trên bản đồ." },
    -- Thảm họa
    { word = "Acid", effect = "danger", info = "Mưa axit độc hại rơi xuống đảo." },
    { word = "supernova", effect = "danger", info = "Mặt trời phát nổ, tìm bóng râm." },
    { word = "Flash Flood", effect = "danger", info = "Một dòng sông bùn di chuyển có thể cuốn trôi người chơi." },
    { word = "Lava", effect = "danger", info = "Sàn nhà liên tục trở nên nóng chảy rồi nguội đi." },
    { word = "Tornado", effect = "danger", info = "Một cơn lốc xoáy đi lang thang trên đảo săn lùng người chơi." },
    { word = "BlackHole", effect = "danger", info = "Hút người chơi vào trong, đến được trung tâm là tử vong." },
    { word = "Tsunami", effect = "danger", info = "Lũ lụt trên đảo, lên vùng đất cao để tránh mất máu." },
    { word = "Flood", effect = "danger", info = "Phủ nước trên mặt đất và tạo ra nguy cơ chết đuối." },
    { word = "Satellite", effect = "danger", info = "Một vệ tinh rơi xuống." },
    { word = "Volcano", effect = "danger", info = "Phun đá dung nham." },
    { word = "Nuke", effect = "danger", image = NUKE_IMAGE_ID, info = "Kích hoạt một ý tưởng thảm họa hạt nhân." },
    { word = "Meteor", effect = "danger", info = "Một gợi ý tấn công để gây sát thương." },
    -- Địa điểm
    { word = "Hell", effect = "danger", info = "Mở ra những miệng núi lửa rực lửa khổng lồ." },
    { word = "Heaven", effect = "help", info = "Cung cấp một cầu thang mây dẫn đến vầng hào quang." },
    { word = "Maze", effect = "neutral", info = "Mọc lên một mê cung cây bụi." },
    { word = "Farm", effect = "neutral", info = "Tạo ra một trang trại động vật." },
    { word = "Space", effect = "neutral", info = "Di chuyển hòn đảo vào không gian với trọng lực thấp." },
    { word = "Town", effect = "neutral", info = "Thêm các cửa hàng để cướp bóc và các tòa nhà." },
    { word = "School", effect = "neutral", info = "Tạo ra một trường học chứa bàn ghế." },
    { word = "Roblox HQ", effect = "neutral", info = "Thêm các tòa nhà Roblox HQ ban đầu." },
    { word = "Pyramid", effect = "neutral", info = "Tạo ra một kim tự tháp có thể leo lên." },
    { word = "Church", effect = "neutral", info = "Thêm một nhà thờ với các băng ghế." },
    { word = "Safe House", effect = "help", info = "Cung cấp sự bảo vệ ngắn hạn khỏi nguy hiểm." },
    { word = "Museum", effect = "neutral", info = "Tạo ra một bảo tàng chứa khủng long." },
    -- Thực phẩm
    { word = "Taco", effect = "help", info = "Triệu hồi Taco." },
    { word = "Cheese", effect = "help", info = "Triệu hồi Cheese." },
    { word = "Burger", effect = "help", info = "Triệu hồi Burger." },
    -- Vật thể
    { word = "Launchpad", effect = "neutral", info = "Thêm các bệ phóng đẩy người chơi lên không trung." },
    { word = "Medkit", effect = "help", info = "Một chiếc máy bay thả một bộ dụng cụ y tế." },
    { word = "Car", effect = "danger", info = "Cung cấp một chiếc xe có thể lái, gây sát thương." },
    { word = "Lucky Block", effect = "neutral", info = "Tạo ra một khối may mắn có thể phá vỡ." },
    { word = "Scarecrow", effect = "danger", info = "Thêm những người rơm canh gác người chơi." },
    { word = "Lego", effect = "danger", info = "Rải các viên gạch đồ chơi gây đau." },
    { word = "Helicopter", effect = "help", info = "Một chiếc trực thăng cứu hộ đón và chữa lành." },
    { word = "Oil", effect = "neutral", info = "Thêm các vết dầu trơn trượt." },
    { word = "Fireworks", effect = "neutral", info = "Bắn pháo hoa quanh bản đồ." },
    { word = "Stairs", effect = "neutral", info = "Cung cấp cầu thang để leo lên." },
    -- Meme & tổng hợp
    { word = "Jesus", effect = "help", info = "Chữa lành tất cả mọi người, hồi sinh và tạo thức ăn." },
    { word = "Superman", effect = "help", info = "Cho phép bạn bay và túm người chơi để ném." },
    { word = "Hunger", effect = "danger", info = "Làm cho mọi người đói." },
    { word = "67", effect = "neutral", info = "Tạo ra cậu bé 67." },
    { word = "Hero", effect = "help", info = "Ban cho khả năng bay, đấm và hạ cánh." },
    { word = "Dance", effect = "neutral", info = "Khiến những người chơi đứng yên nhảy múa." },
    { word = "Mrbeast", effect = "danger", info = "Thử thách người chơi cuối cùng trong vòng tròn." },
    { word = "Santa", effect = "help", info = "Ông già Noel bay quanh thả quà." },
    { word = "Naruto", effect = "danger", info = "Tạo ra các bản sao bóng tối lao về phía người chơi." },
    { word = "Kill", effect = "help", info = "Tặng cho người viết một con dao." },
    { word = "Gojo", effect = "help", info = "Ban cho Infinity trong 30 giây." },
    { word = "Luffy", effect = "help", info = "Ban cho cánh tay cao su để kéo bản thân." },
    { word = "Love", effect = "help", info = "Tạo ra những trái tim chữa lành." },
    { word = "Goku", effect = "help", info = "Biến đổi Saiyan và đòn tấn công tầm xa." },
    { word = "Upside Down", effect = "neutral", info = "Lật ngược màn hình." },
    { word = "Domain", effect = "danger", info = "Đòn tấn công khu vực chết người 15 giây." },
    { word = "Spiderman", effect = "help", info = "Ban cho dây tơ nhện để di chuyển." },
    { word = "Sleep", effect = "neutral", info = "Khiến người chơi ngủ gật khi họ ngừng di chuyển." },
    { word = "Push", effect = "neutral", info = "Giải phóng một làn sóng xung kích đẩy mọi người." },
    { word = "Fly", effect = "help", info = "Ban cho mọi người đôi cánh trong 20 giây." },
    { word = "Fart", effect = "neutral", info = "Triệu hồi một đám mây phân khổng lồ." },
    { word = "Pikachu", effect = "danger", info = "Thunderbolt tấn công người chơi đông đúc." },
    { word = "Tung Tung Sahur", effect = "danger", info = "Kẻ truy đuổi săn lùng người chơi khắp bản đồ." },
    { word = "Please", effect = "help", info = "Tặng tiền thông qua việc xin xỏ." },
    { word = "Person", effect = "neutral", info = "Thêm một người liên tục nói tên." },
    { word = "Gravity", effect = "neutral", info = "Tạo ra trọng lực thấp và những cú nhảy lớn." },
    { word = "Falling Blocks", effect = "danger", info = "Thả những khối khổng lồ từ trên trời xuống." },
    { word = "Sneeze", effect = "neutral", info = "Hắt hơi thổi bay người chơi." },
    { word = "Tralalero", effect = "neutral", info = "Tăng tốc trên bản đồ trong suốt vòng đấu." },
    { word = "Walk", effect = "neutral", info = "Hạn chế mọi người chỉ được đi bộ." },
    { word = "Teleport", effect = "neutral", info = "Khiến mọi người bị giật cục trên bản đồ." },
    { word = "Skibidi", effect = "danger", info = "Tạo ra những chiếc bồn cầu nhảy theo người chơi." },
    { word = "Cry", effect = "neutral", info = "Khiến người chơi khóc ra những vũng nước." },
    { word = "Troll", effect = "neutral", info = "Đảo ngược điều khiển của mọi người." },
    { word = "Doge", effect = "danger", info = "Một chú chó con Doge khổng lồ đuổi theo người chơi." },
    { word = "Aura", effect = "help", info = "Thêm +1000 Aura và hào quang." },
    { word = "Moon", effect = "neutral", info = "Mặt trăng sẽ xuất hiện." },
}

local SelectedCommand = nil
local currentFilter = "all"
local currentSearch = ""

local function submitWord(word)
    if not SubmitWord then return end
    pcall(function() SubmitWord:FireServer(word) end)
end

local function createGUI()
    local old = CoreGui:FindFirstChild("SYI_Browser")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYI_Browser"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.Parent = CoreGui

    -- ===== FLOATING ICON =====
    local floatingIcon = Instance.new("TextButton")
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
    main.Size = UDim2.new(0, 620, 0, 460)
    main.Position = UDim2.new(0.5, -310, 0.5, -230)
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

    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.new(0, 10, 0, 10)
    statusDot.Position = UDim2.new(1, -140, 0.5, -5)
    statusDot.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
    statusDot.BorderSizePixel = 0
    statusDot.Parent = titleBar

    local sdCorner = Instance.new("UICorner")
    sdCorner.CornerRadius = UDim.new(1, 0)
    sdCorner.Parent = statusDot

    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(0, 60, 1, 0)
    statusText.Position = UDim2.new(1, -126, 0, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "Chờ lượt"
    statusText.TextColor3 = Color3.fromRGB(180, 180, 200)
    statusText.Font = Enum.Font.Gotham
    statusText.TextSize = 11
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Parent = titleBar

    local minBtn = Instance.new("TextButton")
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

    -- ===== BODY =====
    local body = Instance.new("Frame")
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

    -- 👇 THANH TÌM KIẾM VÀ DROPDOWN (GỘP CHUNG 1 HÀNG)
    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -80, 0, 28)
    searchBox.Position = UDim2.new(0, 8, 0, 32)
    searchBox.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    searchBox.BorderSizePixel = 0
    searchBox.Text = ""
    searchBox.PlaceholderText = "🔍 Tìm kiếm..."
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 13
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = left

    local sbCorner = Instance.new("UICorner")
    sbCorner.CornerRadius = UDim.new(0, 6)
    sbCorner.Parent = searchBox

    -- Dropdown Menu (Đã Fix đè chữ)
    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(0, 60, 0, 28)
    dropBtn.Position = UDim2.new(1, -68, 0, 32)
    dropBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 58)
    dropBtn.BorderSizePixel = 0
    dropBtn.Text = "Tất cả ▼"
    dropBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
    dropBtn.Font = Enum.Font.GothamBold
    dropBtn.TextSize = 11
    dropBtn.TextXAlignment = Enum.TextXAlignment.Center -- Căn giữa chữ
    dropBtn.Parent = left

    local dbCorner = Instance.new("UICorner")
    dbCorner.CornerRadius = UDim.new(0, 6)
    dbCorner.Parent = dropBtn

    -- Chấm màu của Dropdown (Nằm bên trái, không đè chữ)
    local dropDot = Instance.new("Frame")
    dropDot.Size = UDim2.new(0, 6, 0, 6)
    dropDot.Position = UDim2.new(0, 6, 0.5, -3)
    dropDot.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    dropDot.BorderSizePixel = 0
    dropDot.Parent = dropBtn

    local ddCorner = Instance.new("UICorner")
    ddCorner.CornerRadius = UDim.new(1, 0)
    ddCorner.Parent = dropDot

    local dropdown = Instance.new("Frame")
    dropdown.Size = UDim2.new(0, 60, 0, 110)
    dropdown.Position = UDim2.new(1, -68, 0, 62)
    dropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
    dropdown.BorderSizePixel = 0
    dropdown.Visible = false
    dropdown.ZIndex = 10
    dropdown.Parent = left

    local dropCorner = Instance.new("UICorner")
    dropCorner.CornerRadius = UDim.new(0, 6)
    dropCorner.Parent = dropdown

    local dropLayout = Instance.new("UIListLayout")
    dropLayout.Padding = UDim.new(0, 2)
    dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
    dropLayout.Parent = dropdown

    local dropPad = Instance.new("UIPadding")
    dropPad.PaddingTop = UDim.new(0, 4)
    dropPad.PaddingLeft = UDim.new(0, 4)
    dropPad.PaddingRight = UDim.new(0, 4)
    dropPad.Parent = dropdown

    local filterOptions = {
        { id = "all", text = "Tất cả", color = Color3.fromRGB(150, 150, 150) },
        { id = "danger", text = "Danger", color = Color3.fromRGB(200, 60, 60) },
        { id = "help", text = "Help", color = Color3.fromRGB(60, 180, 100) },
        { id = "neutral", text = "Neutral", color = Color3.fromRGB(180, 160, 60) }
    }

    for _, opt in ipairs(filterOptions) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 22)
        optBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
        optBtn.BorderSizePixel = 0
        optBtn.Text = ""
        optBtn.Parent = dropdown

        local optCorner = Instance.new("UICorner")
        optCorner.CornerRadius = UDim.new(0, 4)
        optCorner.Parent = optBtn

        -- Chấm tròn màu
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 6, 0, 6)
        dot.Position = UDim2.new(0, 6, 0.5, -3)
        dot.BackgroundColor3 = opt.color
        dot.BorderSizePixel = 0
        dot.Parent = optBtn

        local dCorner = Instance.new("UICorner")
        dCorner.CornerRadius = UDim.new(1, 0)
        dCorner.Parent = dot

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -16, 1, 0)
        label.Position = UDim2.new(0, 16, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = opt.text
        label.TextColor3 = Color3.fromRGB(200, 200, 220)
        label.Font = Enum.Font.Gotham
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = optBtn

        optBtn.MouseButton1Click:Connect(function()
            currentFilter = opt.id
            dropBtn.Text = opt.text .. " ▼"
            dropDot.BackgroundColor3 = opt.color
            dropdown.Visible = false
            if updateList then updateList() end
        end)
    end

    dropBtn.MouseButton1Click:Connect(function()
        dropdown.Visible = not dropdown.Visible
    end)

    -- Ẩn dropdown khi bấm ra ngoài (tùy chọn)
    searchBox.Focused:Connect(function()
        dropdown.Visible = false
    end)

    -- List
    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(1, -8, 1, -125)
    list.Position = UDim2.new(0, 4, 0, 68)
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
    imageFrame.Size = UDim2.new(1, -16, 0, 170)
    imageFrame.Position = UDim2.new(0, 8, 0, 36)
    imageFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    imageFrame.BorderSizePixel = 0
    imageFrame.ClipsDescendants = true
    imageFrame.Parent = right

    local ifCorner = Instance.new("UICorner")
    ifCorner.CornerRadius = UDim.new(0, 6)
    ifCorner.Parent = imageFrame

    local commandImage = Instance.new("ImageLabel")
    commandImage.Size = UDim2.new(1, 0, 1, 0)
    commandImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    commandImage.AnchorPoint = Vector2.new(0.5, 0.5)
    commandImage.BackgroundTransparency = 1
    commandImage.Image = ""
    commandImage.ScaleType = Enum.ScaleType.Crop
    commandImage.Parent = imageFrame

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
    wordTitle.Position = UDim2.new(0, 8, 0, 212)
    wordTitle.BackgroundTransparency = 1
    wordTitle.Text = "Chọn một lệnh"
    wordTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    wordTitle.Font = Enum.Font.GothamBold
    wordTitle.TextSize = 20
    wordTitle.TextXAlignment = Enum.TextXAlignment.Left
    wordTitle.Parent = right

    local effectBadge = Instance.new("TextLabel")
    effectBadge.Size = UDim2.new(0, 80, 0, 22)
    effectBadge.Position = UDim2.new(0, 8, 0, 246)
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

    -- 👇 FIX TRIỆT ĐỂ LỖI XUỐNG DÒNG (Dùng AutomaticSize)
    local descScroll = Instance.new("ScrollingFrame")
    descScroll.Size = UDim2.new(1, -16, 0, 80)
    descScroll.Position = UDim2.new(0, 8, 0, 276)
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
    descLabel.Size = UDim2.new(1, 0, 0, 0) -- Kích thước X giãn 100%, Y = 0 (để AutoSize lo)
    descLabel.Position = UDim2.new(0, 6, 0, 6)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = "Thông tin chi tiết của lệnh sẽ hiển thị ở đây khi bạn chọn một lệnh bên trái."
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 13
    descLabel.TextWrapped = true -- Xuống dòng
    descLabel.TextTruncate = Enum.TextTruncate.None
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    descLabel.AutomaticSize = Enum.AutomaticSize.Y -- Tự động giãn chiều cao theo chữ
    descLabel.Parent = descScroll

    local submitSelectedBtn = Instance.new("TextButton")
    submitSelectedBtn.Size = UDim2.new(0.5, -12, 0, 40)
    submitSelectedBtn.Position = UDim2.new(0.5, 4, 1, -48)
    submitSelectedBtn.BackgroundColor3 = Color3.fromRGB(100, 70, 200)
    submitSelectedBtn.BorderSizePixel = 0
    submitSelectedBtn.Text = "GỬI LỆNH NÀY"
    submitSelectedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitSelectedBtn.Font = Enum.Font.GothamBold
    submitSelectedBtn.TextSize = 13
    submitSelectedBtn.Parent = right

    local ssCorner = Instance.new("UICorner")
    ssCorner.CornerRadius = UDim.new(0, 8)
    ssCorner.Parent = submitSelectedBtn

    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0.5, -12, 0, 40)
    autoBtn.Position = UDim2.new(0, 8, 1, -48)
    autoBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    autoBtn.BorderSizePixel = 0
    autoBtn.Text = "BẬT AUTO"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.TextSize = 13
    autoBtn.Parent = right

    local abCorner = Instance.new("UICorner")
    abCorner.CornerRadius = UDim.new(0, 8)
    abCorner.Parent = autoBtn

    -- ===== LOGIC LỌC VÀ TÌM KIẾM =====
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
        btn.Visible = true
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

            if cmd.image and cmd.image ~= "" and cmd.image ~= "rbxassetid://0" then
                commandImage.Image = cmd.image
                commandImage.Visible = true
                imagePlaceholder.Visible = false
            else
                commandImage.Image = ""
                commandImage.Visible = false
                imagePlaceholder.Visible = true
            end

            -- Cập nhật CanvasSize cho ScrollingFrame dựa trên AutoSize của Label
            task.defer(function()
                descScroll.CanvasSize = UDim2.new(0, 0, 0, descLabel.TextBounds.Y + 12)
            end)
        end)
    end

    -- Hàm cập nhật danh sách
    function updateList()
        local searchLower = currentSearch:lower()
        local visibleCount = 0
        
        for _, cmd in ipairs(CommandData) do
            local btn = buttons[cmd.word]
            local matchSearch = (searchLower == "") or (cmd.word:lower():find(searchLower, 1, true) ~= nil)
            local matchFilter = (currentFilter == "all") or (cmd.effect == currentFilter)
            
            if matchSearch and matchFilter then
                btn.Visible = true
                visibleCount = visibleCount + 1
                btn.LayoutOrder = visibleCount
            else
                btn.Visible = false
            end
        end
        
        task.defer(function()
            list.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
        end)
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        currentSearch = searchBox.Text
        updateList()
    end)

    updateList()

    -- ===== MINIMIZE / RESTORE =====
    local isMinimized = false
    local minimizeTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local function minimizeMenu()
        if isMinimized then return end
        isMinimized = true
        dropdown.Visible = false
        TweenService:Create(main, minimizeTweenInfo, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1,
        }):Play()
        TweenService:Create(mainStroke, minimizeTweenInfo, { Transparency = 1 }):Play()

        floatingIcon.Visible = true
        floatingIcon.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(floatingIcon, minimizeTweenInfo, {
            Size = UDim2.new(0, 52, 0, 52),
        }):Play()

        task.delay(0.25, function()
            if isMinimized then main.Visible = false end
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
            Size = UDim2.new(0, 620, 0, 460),
            Position = UDim2.new(0.5, -310, 0.5, -230),
        }):Play()

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
    closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

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

    autoBtn.MouseButton1Click:Connect(function()
        if not SelectedCommand then return end
        
        AutoEnabled = not AutoEnabled
        if AutoEnabled then
            AutoWord = SelectedCommand.word
            autoBtn.Text = "TẮT AUTO"
            autoBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
            print("[AUTO] Đã bật tự động gửi: " .. AutoWord)
        else
            AutoWord = nil
            autoBtn.Text = "BẬT AUTO"
            autoBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
            print("[AUTO] Đã tắt")
        end
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
end

createGUI()
