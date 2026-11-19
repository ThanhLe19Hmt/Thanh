-- ============================================
-- SURVIVE YOUR IDEAS - COMMAND BROWSER (V20)
-- + Theme: Đen - Đỏ - Xám (Đồng bộ Logo)
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

local WriterRemotes = ReplicatedStorage:FindFirstChild("WriterRemotes")
local SubmitWord = WriterRemotes and WriterRemotes:FindFirstChild("SubmitWord")
local WriterChosen = WriterRemotes and WriterRemotes:FindFirstChild("WriterChosen")

local IsMyTurn = false
local AutoEnabled = false
local AutoWord = nil
local CurrentSendKey = Enum.KeyCode.Unknown
local isListeningForKey = false

-- ⚠️ CHỈNH VỊ TRÍ DỌC BAN ĐẦU CỦA THANH DOCK (0 = trên cùng, 1 = dưới cùng)
local MINIMIZE_Y_POSITION = 0.1 

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
local MAHORAGA_IMAGE_ID = "rbxassetid://87053238076886"
local NUKE_IMAGE_ID = "rbxassetid://105196171886899"
local HUB_ICON_ID = "rbxassetid://87526284179554" 

-- ============================================
-- DATA LỆNH (Giữ nguyên)
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

-- ============================================
-- LƯU TRỮ (SAVE) - lệnh yêu thích + cài đặt
-- ============================================
local HttpService = game:GetService("HttpService")
local SAVE_FILE = "SYI_Browser_Save.json"

local Saved = {}      
local SavedSet = {}   
local TapMode = "auto" 

local CmdByWord = {}
for _, c in ipairs(CommandData) do CmdByWord[c.word] = c end

local function cmdFromWord(w)
    return CmdByWord[w] or { word = w, effect = "neutral", info = "Lệnh tùy chỉnh do bạn lưu." }
end

local function saveToDisk()
    if type(writefile) ~= "function" then return end
    pcall(function()
        writefile(SAVE_FILE, HttpService:JSONEncode({
            saved = Saved,
            mode = TapMode,
            sendKey = CurrentSendKey.Name,
        }))
    end)
end

local function loadFromDisk()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        print("[SAVE] Executor không hỗ trợ ghi file: lệnh lưu chỉ còn trong phiên này.")
        return
    end
    pcall(function()
        if not isfile(SAVE_FILE) then return end
        local d = HttpService:JSONDecode(readfile(SAVE_FILE))
        if type(d.saved) == "table" then
            for _, w in ipairs(d.saved) do
                if type(w) == "string" and w ~= "" and not SavedSet[w] then
                    table.insert(Saved, w)
                    SavedSet[w] = true
                end
            end
        end
        if d.mode == "send" or d.mode == "auto" then TapMode = d.mode end
        if type(d.sendKey) == "string" then
            local ok, kc = pcall(function() return Enum.KeyCode[d.sendKey] end)
            if ok and kc then CurrentSendKey = kc end
        end
    end)
end

-- ============================================
-- GUI: DOCK MODE (thanh mỏng, vừa chạy vừa chọn lệnh)
-- ============================================
local DOCK_W, DOCK_H = 596, 44

local PREV_KEY = Enum.KeyCode.LeftBracket   
local NEXT_KEY = Enum.KeyCode.RightBracket  
local AUTO_KEY = Enum.KeyCode.BackSlash     

local AUTO_ON_PICK = true         
local COLLAPSE_AFTER_PICK = true  

-- 👇 BẢNG MÀU MỚI: ĐEN - ĐỎ - XÁM BẠC
local WHITE = Color3.fromRGB(255, 255, 255)
local TXT = Color3.fromRGB(200, 200, 205)         -- Xám sáng cho chữ
local CARD = Color3.fromRGB(24, 24, 28)           -- Nền thẻ đen xám
local CARD_SEL = Color3.fromRGB(180, 30, 30)      -- Đỏ rực khi chọn
local DARK = Color3.fromRGB(32, 32, 38)           -- Nền nút xám tối
local ACCENT = Color3.fromRGB(200, 30, 30)        -- Đỏ chủ đạo (thay cho Tím)
local SILVER = Color3.fromRGB(190, 190, 200)      -- Bạc (viền, icon)
local GOLD = Color3.fromRGB(255, 210, 80)         -- Vàng (cho nút lưu)

local EffectColors = {
    danger = Color3.fromRGB(200, 30, 30),         -- Đỏ
    help = Color3.fromRGB(30, 180, 100),          -- Xanh lá
    neutral = Color3.fromRGB(200, 160, 50),       -- Vàng cam
}

local function hasImage(cmd)
    return cmd.image and cmd.image ~= "" and cmd.image ~= "rbxassetid://0"
end

local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end

local function newCorner(parent, radius)
    return mk("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

-- ============================================
-- HIỆU ỨNG MƯỢT
-- ============================================
local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)   
local TWEEN_PRESS = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)  
local TWEEN_PANEL = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out) 
local TWEEN_CLOSE = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)   

local function tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function attachFx(source, host, radius)
    host = host or source
    local ov = Instance.new("Frame")
    ov.Name = "FxOverlay"
    ov.Size = UDim2.new(1, 0, 1, 0)
    ov.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ov.BackgroundTransparency = 1
    ov.BorderSizePixel = 0
    ov.Active = false
    ov.Parent = host
    if radius then newCorner(ov, radius) end

    local hover = false
    source.MouseEnter:Connect(function()
        hover = true
        tween(ov, TWEEN_FAST, { BackgroundTransparency = 0.88 })
    end)
    source.MouseLeave:Connect(function()
        hover = false
        tween(ov, TWEEN_FAST, { BackgroundTransparency = 1 })
    end)
    source.MouseButton1Down:Connect(function()
        tween(ov, TWEEN_PRESS, { BackgroundTransparency = 0.72 })
    end)
    source.MouseButton1Up:Connect(function()
        tween(ov, TWEEN_FAST, { BackgroundTransparency = hover and 0.88 or 1 })
    end)
end

local function createGUI()
    local old = CoreGui:FindFirstChild("SYI_Browser")
    if old then old:Destroy() end

    local gui = mk("ScreenGui", {
        Name = "SYI_Browser",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    }, CoreGui)

    local conns = {}
    local function track(c) table.insert(conns, c) return c end
    gui.Destroying:Connect(function()
        for _, c in ipairs(conns) do c:Disconnect() end
    end)

    -- ===== THANH DOCK =====
    local bar = mk("Frame", {
        Name = "Dock",
        Size = UDim2.new(0, DOCK_W, 0, DOCK_H),
        Position = UDim2.new(0.5, -DOCK_W / 2, MINIMIZE_Y_POSITION, 0),
        BackgroundColor3 = Color3.fromRGB(12, 12, 14), -- Đen sâu
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Active = true,
    }, gui)
    newCorner(bar, 10)
    mk("UIStroke", { Color = ACCENT, Thickness = 1.5, Transparency = 0.2 }, bar) -- Viền đỏ

    local function barBtn(text, x, w, bg)
        local b = mk("TextButton", {
            Size = UDim2.new(0, w, 0, 28),
            Position = UDim2.new(0, x, 0.5, -14),
            BackgroundColor3 = bg,
            BorderSizePixel = 0,
            Text = text,
            TextColor3 = WHITE,
            Font = Enum.Font.GothamBlack, -- Font đậm ngầu hơn
            TextSize = 13,
        }, bar)
        newCorner(b, 6)
        attachFx(b, nil, 6)
        return b
    end

    -- ===== LOGO VÀ TÊN HUB =====
    local brandFrame = mk("Frame", {
        Size = UDim2.new(0, 140, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Active = true,
    }, bar)

    local grip = mk("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
    }, brandFrame)

    local hubLogo = mk("ImageLabel", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(0, 8, 0.5, -14),
        BackgroundTransparency = 1,
        Image = HUB_ICON_ID,
        ScaleType = Enum.ScaleType.Fit,
        Active = true,
    }, brandFrame)

    local hubName = mk("TextLabel", {
        Size = UDim2.new(0, 100, 1, 0),
        Position = UDim2.new(0, 38, 0, 0),
        BackgroundTransparency = 1,
        Text = "MarvenRiz Hub",
        TextColor3 = WHITE, -- Đổi sang trắng sáng
        Font = Enum.Font.GothamBlack,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, brandFrame)

    local statusDot = mk("Frame", {
        Size = UDim2.new(0, 8, 0, 8),
        Position = UDim2.new(0, 142, 0.5, -4),
        BackgroundColor3 = Color3.fromRGB(120, 120, 120),
        BorderSizePixel = 0,
    }, bar)
    newCorner(statusDot, 4)

    local prevBtn = barBtn("◀", 156, 28, DARK)

    local labelBox = mk("Frame", {
        Size = UDim2.new(0, 180, 0, 28),
        Position = UDim2.new(0, 188, 0.5, -14),
        BackgroundColor3 = DARK, -- Đổi nền thành Xám tối (thay vì Tím)
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, bar)
    newCorner(labelBox, 6)
    local labelImage = mk("ImageLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "",
        ScaleType = Enum.ScaleType.Crop,
        Visible = false,
    }, labelBox)
    local labelDim = mk("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Visible = false,
    }, labelBox)
    local effectDot = mk("Frame", {
        Size = UDim2.new(0, 8, 0, 8),
        Position = UDim2.new(0, 8, 0.5, -4),
        BackgroundColor3 = Color3.fromRGB(150, 150, 150),
        BorderSizePixel = 0,
    }, labelBox)
    newCorner(effectDot, 4)
    local labelBtn = mk("TextButton", {
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 20, 0, 0),
        BackgroundTransparency = 1,
        Text = "Chưa chọn lệnh",
        TextColor3 = WHITE,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, labelBox)

    local nextBtn = barBtn("▶", 372, 28, DARK)
    local saveStar = barBtn("☆", 404, 28, DARK)
    local savedBtn = barBtn("★ 0", 436, 46, DARK)
    savedBtn.TextSize = 12
    savedBtn.TextColor3 = GOLD
    
    local autoBtn = barBtn("AUTO OFF", 486, 70, DARK)
    autoBtn.TextSize = 12
    local expandBtn = barBtn("▼", 560, 28, DARK)
    
    local closeBtn = barBtn("×", 592, 28, ACCENT) -- Nút tắt màu đỏ
    closeBtn.Position = UDim2.new(1, -34, 0.5, -14)
    closeBtn.TextSize = 18

    -- Kéo thanh dock bằng tay nắm
    local dragging, dragStart, startPos = false, nil, nil
    track(grip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = bar.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            bar.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))

    -- ===== BẢNG CHÍNH (tất cả lệnh) =====
    local panel = mk("Frame", {
        Name = "Panel",
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        Position = UDim2.new(0, 0, 1, 6),
        BackgroundColor3 = Color3.fromRGB(12, 12, 14), -- Đen
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Visible = false,
    }, bar)
    newCorner(panel, 10)
    local panelStroke = mk("UIStroke", { Color = ACCENT, Thickness = 1.5, Transparency = 1 }, panel)

    local searchBox = mk("TextBox", {
        Size = UDim2.new(0, 232, 0, 28),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = DARK,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = "🔍 Tìm kiếm...",
        TextColor3 = WHITE,
        PlaceholderColor3 = Color3.fromRGB(120, 120, 140),
        Font = Enum.Font.Gotham,
        TextSize = 13,
        ClearTextOnFocus = false,
    }, panel)
    newCorner(searchBox, 6)

    local filterOptions = {
        { id = "all", text = "Tất cả", color = Color3.fromRGB(150, 150, 160) },
        { id = "danger", text = "Danger", color = EffectColors.danger },
        { id = "help", text = "Help", color = EffectColors.help },
        { id = "neutral", text = "Neutral", color = EffectColors.neutral },
    }
    local filterBtns = {}
    local function refreshFilter()
        for id, f in pairs(filterBtns) do
            if currentFilter == id then
                tween(f.btn, TWEEN_FAST, { BackgroundColor3 = f.color, TextColor3 = WHITE })
            else
                tween(f.btn, TWEEN_FAST, { BackgroundColor3 = DARK, TextColor3 = TXT })
            end
        end
    end

    local updateList

    for i, opt in ipairs(filterOptions) do
        local b = mk("TextButton", {
            Size = UDim2.new(0, 60, 0, 28),
            Position = UDim2.new(0, 248 + (i - 1) * 63, 0, 8),
            BackgroundColor3 = DARK,
            BorderSizePixel = 0,
            Text = opt.text,
            TextColor3 = TXT,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
        }, panel)
        newCorner(b, 6)
        attachFx(b, nil, 6)
        filterBtns[opt.id] = { btn = b, color = opt.color }
        b.MouseButton1Click:Connect(function()
            currentFilter = opt.id
            refreshFilter()
            updateList()
        end)
    end
    refreshFilter()

    local list = mk("ScrollingFrame", {
        Size = UDim2.new(1, -16, 0, 56),
        Position = UDim2.new(0, 8, 0, 42),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = ACCENT,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollingDirection = Enum.ScrollingDirection.X,
        Active = true,
    }, panel)
    local listLayout = mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    }, list)
    mk("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 2) }, list)

    -- Hàng nhập lệnh tùy chỉnh
    local inputBox = mk("TextBox", {
        Size = UDim2.new(0, 224, 0, 32),
        Position = UDim2.new(0, 8, 0, 104),
        BackgroundColor3 = DARK,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = "Nhập lệnh tùy chỉnh...",
        TextColor3 = WHITE,
        PlaceholderColor3 = Color3.fromRGB(100, 100, 120),
        Font = Enum.Font.Gotham,
        TextSize = 13,
        ClearTextOnFocus = false,
    }, panel)
    newCorner(inputBox, 6)

    local sendBtn = mk("TextButton", {
        Size = UDim2.new(0, 48, 0, 32),
        Position = UDim2.new(0, 240, 0, 104),
        BackgroundColor3 = ACCENT, -- Đỏ
        BorderSizePixel = 0,
        Text = "Gửi",
        TextColor3 = WHITE,
        Font = Enum.Font.GothamBlack,
        TextSize = 13,
    }, panel)
    newCorner(sendBtn, 6)
    attachFx(sendBtn, nil, 6)

    local saveCustomBtn = mk("TextButton", {
        Size = UDim2.new(0, 56, 0, 32),
        Position = UDim2.new(0, 296, 0, 104),
        BackgroundColor3 = Color3.fromRGB(80, 60, 20),
        BorderSizePixel = 0,
        Text = "★ Lưu",
        TextColor3 = GOLD,
        Font = Enum.Font.GothamBlack,
        TextSize = 12,
    }, panel)
    newCorner(saveCustomBtn, 6)
    attachFx(saveCustomBtn, nil, 6)

    local keybindBtn = mk("TextButton", {
        Size = UDim2.new(0, 172, 0, 32),
        Position = UDim2.new(0, 360, 0, 104),
        BackgroundColor3 = DARK,
        BorderSizePixel = 0,
        Text = (CurrentSendKey == Enum.KeyCode.Unknown) and "Phím tắt gửi: [Chưa đặt]" or ("Phím tắt gửi: [" .. CurrentSendKey.Name .. "]"),
        TextColor3 = SILVER,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
    }, panel)
    newCorner(keybindBtn, 6)
    attachFx(keybindBtn, nil, 6)

    -- ===== BẢNG LỆNH ĐÃ LƯU =====
    local savedPanel = mk("Frame", {
        Name = "SavedPanel",
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        Position = UDim2.new(0, 0, 1, 6),
        BackgroundColor3 = Color3.fromRGB(12, 12, 14),
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Visible = false,
    }, bar)
    newCorner(savedPanel, 10)
    local savedStroke = mk("UIStroke", { Color = GOLD, Thickness = 1.5, Transparency = 1 }, savedPanel)

    local modeBtn = mk("TextButton", {
        Size = UDim2.new(0, 190, 0, 28),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = Color3.fromRGB(60, 180, 100),
        BorderSizePixel = 0,
        Text = "Chạm = AUTO",
        TextColor3 = WHITE,
        Font = Enum.Font.GothamBlack,
        TextSize = 12,
    }, savedPanel)
    newCorner(modeBtn, 6)
    attachFx(modeBtn, nil, 6)

    mk("TextLabel", {
        Size = UDim2.new(0, 320, 0, 28),
        Position = UDim2.new(0, 206, 0, 8),
        BackgroundTransparency = 1,
        Text = "Bấm ☆ ở lệnh để lưu · bấm × để xoá khỏi danh sách",
        TextColor3 = SILVER,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, savedPanel)

    local savedList = mk("ScrollingFrame", {
        Size = UDim2.new(1, -16, 0, 56),
        Position = UDim2.new(0, 8, 0, 42),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = GOLD,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollingDirection = Enum.ScrollingDirection.X,
        Active = true,
    }, savedPanel)
    local savedLayout = mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    }, savedList)
    mk("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 2) }, savedList)

    local emptyLabel = mk("TextLabel", {
        Size = UDim2.new(1, -16, 0, 40),
        Position = UDim2.new(0, 8, 0, 46),
        BackgroundTransparency = 1,
        Text = "Chưa có lệnh nào được lưu.",
        TextColor3 = Color3.fromRGB(110, 110, 130),
        Font = Enum.Font.Gotham,
        TextSize = 13,
    }, savedPanel)

    -- ===== POPUP THÔNG TIN =====
    local function showInfo(cmd)
            local oldPopup = gui:FindFirstChild("InfoPopup")
            if oldPopup then oldPopup:Destroy() end

            local popup = Instance.new("Frame")
            popup.Name = "InfoPopup"
            popup.Size = UDim2.new(0, 300, 0, 380)
            popup.Position = UDim2.new(0.5, -150, 0.5, -190)
            popup.BackgroundColor3 = Color3.fromRGB(18, 18, 20) -- Đen
            popup.BorderSizePixel = 0
            popup.ZIndex = 50
            popup.Parent = gui

            local pCorner = Instance.new("UICorner")
            pCorner.CornerRadius = UDim.new(0, 10)
            pCorner.Parent = popup

            local pStroke = Instance.new("UIStroke")
            pStroke.Color = ACCENT
            pStroke.Thickness = 2
            pStroke.Parent = popup

            local closePopupBtn = Instance.new("TextButton")
            closePopupBtn.Size = UDim2.new(0, 28, 0, 28)
            closePopupBtn.Position = UDim2.new(1, -34, 0, 8)
            closePopupBtn.BackgroundColor3 = ACCENT
            closePopupBtn.BorderSizePixel = 0
            closePopupBtn.Text = "×"
            closePopupBtn.TextColor3 = WHITE
            closePopupBtn.Font = Enum.Font.GothamBlack
            closePopupBtn.TextSize = 18
            closePopupBtn.ZIndex = 51
            closePopupBtn.Parent = popup

            local cpCorner = Instance.new("UICorner")
            cpCorner.CornerRadius = UDim.new(0, 6)
            cpCorner.Parent = closePopupBtn

            closePopupBtn.MouseButton1Click:Connect(function()
                popup:Destroy()
            end)

            local pTitle = Instance.new("TextLabel")
            pTitle.Size = UDim2.new(1, -50, 0, 32)
            pTitle.Position = UDim2.new(0, 12, 0, 8)
            pTitle.BackgroundTransparency = 1
            pTitle.Text = cmd.word
            pTitle.TextColor3 = WHITE
            pTitle.Font = Enum.Font.GothamBlack
            pTitle.TextSize = 20
            pTitle.TextXAlignment = Enum.TextXAlignment.Left
            pTitle.ZIndex = 51
            pTitle.Parent = popup

            local pImageFrame = Instance.new("Frame")
            pImageFrame.Size = UDim2.new(1, -24, 0, 150)
            pImageFrame.Position = UDim2.new(0, 12, 0, 46)
            pImageFrame.BackgroundColor3 = DARK
            pImageFrame.BorderSizePixel = 0
            pImageFrame.ClipsDescendants = true
            pImageFrame.ZIndex = 51
            pImageFrame.Parent = popup

            local pifCorner = Instance.new("UICorner")
            pifCorner.CornerRadius = UDim.new(0, 6)
            pifCorner.Parent = pImageFrame

            if cmd.image and cmd.image ~= "" and cmd.image ~= "rbxassetid://0" then
                local img = Instance.new("ImageLabel")
                img.Size = UDim2.new(1, 0, 1, 0)
                img.BackgroundTransparency = 1
                img.Image = cmd.image
                img.ScaleType = Enum.ScaleType.Crop
                img.ZIndex = 51
                img.Parent = pImageFrame
            else
                local noImg = Instance.new("TextLabel")
                noImg.Size = UDim2.new(1, 0, 1, 0)
                noImg.BackgroundTransparency = 1
                noImg.Text = "Không có ảnh"
                noImg.TextColor3 = Color3.fromRGB(80, 80, 100)
                noImg.Font = Enum.Font.Gotham
                noImg.TextSize = 12
                noImg.ZIndex = 51
                noImg.Parent = pImageFrame
            end

            local pBadge = Instance.new("TextLabel")
            pBadge.Size = UDim2.new(0, 80, 0, 22)
            pBadge.Position = UDim2.new(0, 12, 0, 206)
            pBadge.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
            if cmd.effect == "danger" then pBadge.BackgroundColor3 = EffectColors.danger
            elseif cmd.effect == "help" then pBadge.BackgroundColor3 = EffectColors.help
            elseif cmd.effect == "neutral" then pBadge.BackgroundColor3 = EffectColors.neutral end
            pBadge.BorderSizePixel = 0
            pBadge.Text = cmd.effect:upper()
            pBadge.TextColor3 = WHITE
            pBadge.Font = Enum.Font.GothamBlack
            pBadge.TextSize = 11
            pBadge.ZIndex = 51
            pBadge.Parent = popup

            local pbCorner = Instance.new("UICorner")
            pbCorner.CornerRadius = UDim.new(0, 4)
            pbCorner.Parent = pBadge

            local pDescFrame = Instance.new("ScrollingFrame")
            pDescFrame.Size = UDim2.new(1, -24, 0, 110)
            pDescFrame.Position = UDim2.new(0, 12, 0, 236)
            pDescFrame.BackgroundColor3 = DARK
            pDescFrame.BorderSizePixel = 0
            pDescFrame.ScrollBarThickness = 5
            pDescFrame.ScrollBarImageColor3 = ACCENT
            pDescFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
            pDescFrame.ZIndex = 51
            pDescFrame.Parent = popup

            local pdfCorner = Instance.new("UICorner")
            pdfCorner.CornerRadius = UDim.new(0, 6)
            pdfCorner.Parent = pDescFrame

            local pDesc = Instance.new("TextLabel")
            pDesc.Size = UDim2.new(1, -12, 0, 0)
            pDesc.Position = UDim2.new(0, 6, 0, 6)
            pDesc.BackgroundTransparency = 1
            pDesc.Text = cmd.info
            pDesc.TextColor3 = TXT
            pDesc.Font = Enum.Font.Gotham
            pDesc.TextSize = 13
            pDesc.TextWrapped = true
            pDesc.TextXAlignment = Enum.TextXAlignment.Left
            pDesc.TextYAlignment = Enum.TextYAlignment.Top
            pDesc.AutomaticSize = Enum.AutomaticSize.Y
            pDesc.ZIndex = 51
            pDesc.Parent = pDescFrame

            task.defer(function()
                pDescFrame.CanvasSize = UDim2.new(0, 0, 0, pDesc.TextBounds.Y + 12)
            end)
    end

    -- ===== TRẠNG THÁI / HÀM DÙNG CHUNG =====
    local chips = {}       
    local visibleList = {}
    local rebuildSaved
    local lastAdded = nil 

    local function refreshStars()
        for word, c in pairs(chips) do
            local on = SavedSet[word] == true
            c.star.Text = on and "★" or "☆"
            c.star.TextColor3 = on and GOLD or Color3.fromRGB(150, 150, 170)
        end
        local on = SelectedCommand and SavedSet[SelectedCommand.word]
        saveStar.Text = on and "★" or "☆"
        saveStar.TextColor3 = on and GOLD or WHITE
        savedBtn.Text = "★ " .. #Saved
    end

    local function refreshSelectionVisual()
        for word, c in pairs(chips) do
            local sel = SelectedCommand and SelectedCommand.word == word
            if c.sel ~= sel then
                c.sel = sel
                tween(c.frame, TWEEN_FAST, { BackgroundColor3 = sel and CARD_SEL or CARD })
                tween(c.btn, TWEEN_FAST, { TextColor3 = sel and WHITE or TXT })
                if c.dim then 
                    tween(c.dim, TWEEN_FAST, {
                        BackgroundColor3 = sel and CARD_SEL or Color3.new(0, 0, 0),
                        BackgroundTransparency = sel and 0.35 or 0.5,
                    })
                end
            end
        end
    end

    local function refreshAutoVisual()
        if AutoEnabled then
            autoBtn.Text = "AUTO ON"
            tween(autoBtn, TWEEN_FAST, { BackgroundColor3 = Color3.fromRGB(60, 180, 100) })
        else
            autoBtn.Text = "AUTO OFF"
            tween(autoBtn, TWEEN_FAST, { BackgroundColor3 = DARK })
        end
    end

    local function refreshModeVisual()
        if TapMode == "auto" then
            modeBtn.Text = "Chạm = AUTO"
            tween(modeBtn, TWEEN_FAST, { BackgroundColor3 = Color3.fromRGB(60, 180, 100) })
        else
            modeBtn.Text = "Chạm = GỬI 1 LẦN"
            tween(modeBtn, TWEEN_FAST, { BackgroundColor3 = ACCENT })
        end
    end

    local function setAuto(on)
        if on and not SelectedCommand then return end
        AutoEnabled = on
        AutoWord = on and SelectedCommand.word or nil
        refreshAutoVisual()
        print(on and ("[AUTO] Đã bật tự động gửi: " .. AutoWord) or "[AUTO] Đã tắt")
    end

    local function selectCommand(cmd)
        SelectedCommand = cmd
        labelBtn.Text = cmd.word
        tween(effectDot, TWEEN_FAST, { BackgroundColor3 = EffectColors[cmd.effect] or Color3.fromRGB(150, 150, 150) })
        if hasImage(cmd) then
            labelImage.Image = cmd.image
            labelImage.Visible = true
            labelDim.Visible = true
            labelImage.ImageTransparency = 1
            labelDim.BackgroundTransparency = 1
            tween(labelImage, TWEEN_PANEL, { ImageTransparency = 0 })
            tween(labelDim, TWEEN_PANEL, { BackgroundTransparency = 0.5 })
            tween(labelBox, TWEEN_FAST, { BackgroundColor3 = Color3.fromRGB(0, 0, 0) })
        else
            labelImage.Visible = false
            labelDim.Visible = false
            tween(labelBox, TWEEN_FAST, { BackgroundColor3 = DARK })
        end
        if AutoEnabled then AutoWord = cmd.word end
        refreshSelectionVisual()
        refreshStars()
    end

    local function scrollToSelected()
        if not SelectedCommand then return end
        local c = chips[SelectedCommand.word]
        if not c or not c.frame.Visible then return end
        task.delay(0.05, function()
            local x = c.frame.AbsolutePosition.X - list.AbsolutePosition.X + list.CanvasPosition.X
            list.CanvasPosition = Vector2.new(math.max(0, x - 40), 0)
        end)
    end

    local currentPanel = nil
    local panelToken = {}
    local function animatePanel(frame, stroke, height, strokeT, open)
        local token = (panelToken[frame] or 0) + 1
        panelToken[frame] = token
        if open then
            frame.Visible = true
            tween(frame, TWEEN_PANEL, { Size = UDim2.new(1, 0, 0, height) })
            tween(stroke, TWEEN_PANEL, { Transparency = strokeT })
        else
            local t = tween(frame, TWEEN_CLOSE, { Size = UDim2.new(1, 0, 0, 0) })
            tween(stroke, TWEEN_CLOSE, { Transparency = 1 })
            t.Completed:Connect(function()
                if panelToken[frame] == token then frame.Visible = false end
            end)
        end
    end

    local function setPanel(which)
        if which ~= "main" and currentPanel == "main" then
            animatePanel(panel, panelStroke, 144, 0.2, false)
        end
        if which ~= "saved" and currentPanel == "saved" then
            animatePanel(savedPanel, savedStroke, 108, 0.4, false)
        end
        if which == "main" and currentPanel ~= "main" then
            animatePanel(panel, panelStroke, 144, 0.2, true)
        end
        if which == "saved" and currentPanel ~= "saved" then
            animatePanel(savedPanel, savedStroke, 108, 0.4, true)
        end
        currentPanel = which
        expandBtn.Text = (which == "main") and "▲" or "▼"
        tween(savedBtn, TWEEN_FAST, { BackgroundColor3 = (which == "saved") and Color3.fromRGB(80, 60, 20) or DARK })
        if which == "main" then scrollToSelected() end
    end
    local function togglePanel(which)
        local cur = currentPanel
        if cur == which then
            setPanel(nil)   
        else
            setPanel(which)
        end
    end

    local function cycle(dir)
        if #visibleList == 0 then return end
        local idx = 0
        for i, c in ipairs(visibleList) do
            if SelectedCommand and c.word == SelectedCommand.word then idx = i break end
        end
        local n = idx + dir
        if idx == 0 then n = (dir > 0) and 1 or #visibleList end
        if n > #visibleList then n = 1 elseif n < 1 then n = #visibleList end
        selectCommand(visibleList[n])
        if currentPanel == "main" then scrollToSelected() end
    end

    local function setSaved(word, on)
        if on and not SavedSet[word] then
            lastAdded = word
            table.insert(Saved, word)
            SavedSet[word] = true
        elseif (not on) and SavedSet[word] then
            SavedSet[word] = nil
            for i, w in ipairs(Saved) do
                if w == word then table.remove(Saved, i) break end
            end
        end
        saveToDisk()
        rebuildSaved()
        refreshStars()
    end

    local dragMoved = false
    local activeScroller, dragStartX, startCanvasX = nil, 0, 0
    local function beginDrag(scroller, input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            activeScroller = scroller
            dragMoved = false
            dragStartX = input.Position.X
            startCanvasX = scroller.CanvasPosition.X
        end
    end
    list.InputBegan:Connect(function(i) beginDrag(list, i) end)
    savedList.InputBegan:Connect(function(i) beginDrag(savedList, i) end)
    track(UserInputService.InputChanged:Connect(function(input)
        if activeScroller and input.UserInputType == Enum.UserInputType.MouseMovement then
            local dx = input.Position.X - dragStartX
            if math.abs(dx) > 5 then dragMoved = true end
            if dragMoved then
                activeScroller.CanvasPosition = Vector2.new(startCanvasX - dx, 0)
            end
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            activeScroller = nil
        end
    end))

    for i, cmd in ipairs(CommandData) do
        local textW = TextService:GetTextSize(cmd.word, 13, Enum.Font.Gotham, Vector2.new(1000, 40)).X
        local cmdFrame = mk("Frame", {
            Size = UDim2.new(0, math.max(104, textW + 72), 0, 40),
            BackgroundColor3 = CARD,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            LayoutOrder = i,
        }, list)
        newCorner(cmdFrame, 6)

        local chipDim = nil
        if hasImage(cmd) then
            mk("ImageLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Image = cmd.image,
                ScaleType = Enum.ScaleType.Crop,
            }, cmdFrame)
            chipDim = mk("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
            }, cmdFrame)
        end

        local btn = mk("TextButton", {
            Size = UDim2.new(1, -56, 1, 0),
            BackgroundTransparency = 1,
            Text = "  " .. cmd.word,
            TextColor3 = TXT,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, cmdFrame)

        attachFx(btn, cmdFrame, 6)

        local starBtn = mk("TextButton", {
            Size = UDim2.new(0, 22, 0, 22),
            Position = UDim2.new(1, -52, 0.5, -11),
            BackgroundTransparency = 1,
            Text = "☆",
            TextColor3 = Color3.fromRGB(150, 150, 170),
            Font = Enum.Font.GothamBlack,
            TextSize = 16,
        }, cmdFrame)

        local infoBtn = mk("TextButton", {
            Size = UDim2.new(0, 22, 0, 22),
            Position = UDim2.new(1, -26, 0.5, -11),
            BackgroundColor3 = DARK,
            BorderSizePixel = 0,
            Text = "?",
            TextColor3 = SILVER,
            Font = Enum.Font.GothamBlack,
            TextSize = 12,
        }, cmdFrame)
        newCorner(infoBtn, 11)

        chips[cmd.word] = { frame = cmdFrame, btn = btn, star = starBtn, dim = chipDim, sel = false }
        btn.InputBegan:Connect(function(inp) beginDrag(list, inp) end)
        starBtn.InputBegan:Connect(function(inp) beginDrag(list, inp) end)
        infoBtn.InputBegan:Connect(function(inp) beginDrag(list, inp) end)

        btn.MouseButton1Click:Connect(function()
            if dragMoved then return end
            selectCommand(cmd)
            if AUTO_ON_PICK then setAuto(true) end
            if COLLAPSE_AFTER_PICK then setPanel(nil) end
        end)

        starBtn.MouseButton1Click:Connect(function()
            if dragMoved then return end
            setSaved(cmd.word, not SavedSet[cmd.word])
        end)

        infoBtn.MouseButton1Click:Connect(function()
            if dragMoved then return end
            showInfo(cmd)
        end)
    end

    rebuildSaved = function()
        for _, ch in ipairs(savedList:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        emptyLabel.Visible = (#Saved == 0)

        for i, word in ipairs(Saved) do
            local cmd = cmdFromWord(word)
            local textW = TextService:GetTextSize(word, 13, Enum.Font.Gotham, Vector2.new(1000, 40)).X
            local fullW = math.max(90, textW + 56)
            local isNew = (word == lastAdded)
            local sFrame = mk("Frame", {
                Size = UDim2.new(0, isNew and 0 or fullW, 0, 40),
                BackgroundColor3 = CARD,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                LayoutOrder = i,
            }, savedList)
            if isNew then
                tween(sFrame, TWEEN_PANEL, { Size = UDim2.new(0, fullW, 0, 40) })
            end
            newCorner(sFrame, 6)

            local accent = mk("Frame", {
                Size = UDim2.new(0, 4, 1, -12),
                Position = UDim2.new(0, 4, 0, 6),
                BackgroundColor3 = EffectColors[cmd.effect] or Color3.fromRGB(150, 150, 150),
                BorderSizePixel = 0,
            }, sFrame)
            newCorner(accent, 2)

            local sBtn = mk("TextButton", {
                Size = UDim2.new(1, -30, 1, 0),
                BackgroundTransparency = 1,
                Text = "   " .. word,
                TextColor3 = WHITE,
                Font = Enum.Font.GothamBlack,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, sFrame)

            attachFx(sBtn, sFrame, 6)

            local delBtn = mk("TextButton", {
                Size = UDim2.new(0, 22, 0, 22),
                Position = UDim2.new(1, -26, 0.5, -11),
                BackgroundColor3 = ACCENT,
                BorderSizePixel = 0,
                Text = "×",
                TextColor3 = WHITE,
                Font = Enum.Font.GothamBlack,
                TextSize = 14,
            }, sFrame)
            newCorner(delBtn, 11)

            sBtn.InputBegan:Connect(function(inp) beginDrag(savedList, inp) end)
            delBtn.InputBegan:Connect(function(inp) beginDrag(savedList, inp) end)

            sBtn.MouseButton1Click:Connect(function()
                if dragMoved then return end
                selectCommand(cmd)
                if TapMode == "auto" then
                    setAuto(true)
                    if COLLAPSE_AFTER_PICK then setPanel(nil) end
                else
                    submitWord(word) 
                    sFrame.BackgroundColor3 = CARD_SEL
                    tween(sFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = CARD })
                end
            end)

            delBtn.MouseButton1Click:Connect(function()
                if dragMoved then return end
                local t = tween(sFrame, TWEEN_FAST, { Size = UDim2.new(0, 0, 0, 40) })
                t.Completed:Connect(function() setSaved(word, false) end)
            end)
        end

        lastAdded = nil
        task.defer(function()
            savedList.CanvasSize = UDim2.new(0, savedLayout.AbsoluteContentSize.X + 8, 0, 0)
        end)
        task.delay(0.3, function() 
            savedList.CanvasSize = UDim2.new(0, savedLayout.AbsoluteContentSize.X + 8, 0, 0)
        end)
    end

    updateList = function()
        local searchLower = currentSearch:lower()
        visibleList = {}
        local count = 0
        for _, cmd in ipairs(CommandData) do
            local frame = chips[cmd.word].frame
            local matchSearch = (searchLower == "") or (cmd.word:lower():find(searchLower, 1, true) ~= nil)
            local matchFilter = (currentFilter == "all") or (cmd.effect == currentFilter)
            if matchSearch and matchFilter then
                frame.Visible = true
                count = count + 1
                frame.LayoutOrder = count
                table.insert(visibleList, cmd)
            else
                frame.Visible = false
            end
        end
        task.defer(function()
            list.CanvasSize = UDim2.new(0, listLayout.AbsoluteContentSize.X + 8, 0, 0)
            list.CanvasPosition = Vector2.new(0, 0)
        end)
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        currentSearch = searchBox.Text
        updateList()
    end)

    updateList()
    rebuildSaved()
    refreshStars()
    refreshModeVisual()

    labelBtn.MouseButton1Click:Connect(function() togglePanel("main") end)
    expandBtn.MouseButton1Click:Connect(function() togglePanel("main") end)
    savedBtn.MouseButton1Click:Connect(function() togglePanel("saved") end)
    prevBtn.MouseButton1Click:Connect(function() cycle(-1) end)
    nextBtn.MouseButton1Click:Connect(function() cycle(1) end)
    autoBtn.MouseButton1Click:Connect(function() setAuto(not AutoEnabled) end)
    saveStar.MouseButton1Click:Connect(function()
        if not SelectedCommand then return end
        setSaved(SelectedCommand.word, not SavedSet[SelectedCommand.word])
    end)
    
    local closing = false
    closeBtn.MouseButton1Click:Connect(function()
        if closing then return end
        closing = true
        local pos = bar.Position
        local t = tween(bar, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset - 90),
        })
        t.Completed:Connect(function() gui:Destroy() end)
    end)

    modeBtn.MouseButton1Click:Connect(function()
        TapMode = (TapMode == "auto") and "send" or "auto"
        refreshModeVisual()
        saveToDisk()
    end)

    keybindBtn.MouseButton1Click:Connect(function()
        isListeningForKey = true
        keybindBtn.Text = "Phím tắt gửi: [Bấm phím...]"
        keybindBtn.TextColor3 = GOLD
    end)

    track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if isListeningForKey then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                CurrentSendKey = input.KeyCode
                keybindBtn.Text = "Phím tắt gửi: [" .. CurrentSendKey.Name .. "]"
                keybindBtn.TextColor3 = SILVER
                isListeningForKey = false
                saveToDisk()
            end
            return
        end

        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local k = input.KeyCode
        if k == PREV_KEY then
            cycle(-1)
        elseif k == NEXT_KEY then
            cycle(1)
        elseif k == AUTO_KEY then
            setAuto(not AutoEnabled)
        elseif CurrentSendKey ~= Enum.KeyCode.Unknown and k == CurrentSendKey then
            if inputBox.Text ~= "" then
                submitWord(inputBox.Text)
                inputBox.Text = ""
            elseif SelectedCommand then
                submitWord(SelectedCommand.word)
            end
        end
    end))

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

    saveCustomBtn.MouseButton1Click:Connect(function()
        local w = inputBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if w ~= "" then
            setSaved(w, true)
            inputBox.Text = ""
        elseif SelectedCommand then
            setSaved(SelectedCommand.word, true)
        end
    end)

    local finalPos = bar.Position
    bar.Position = UDim2.new(finalPos.X.Scale, finalPos.X.Offset, finalPos.Y.Scale, finalPos.Y.Offset - 80)
    tween(bar, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = finalPos })

    task.spawn(function()
        local lastState = nil
        while gui.Parent do
            if lastState ~= IsMyTurn then
                lastState = IsMyTurn
                tween(statusDot, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = IsMyTurn and Color3.fromRGB(100, 255, 120) or Color3.fromRGB(120, 120, 120),
                })
            end
            task.wait(0.2)
        end
    end)
end

loadFromDisk()
createGUI()
