-- ============================================================
-- SEA 1 SCRIPT - FULL FEATURES (v47 FINAL + AutoSkill Fix + Multi-Language TH)
-- MarvenRiz Hub - Rock Fruit (Sea 1 + Moon)
-- ============================================================
print("[Sea 1] ▶️ Bắt đầu load...")

-- ============================================================
-- LANGUAGE SELECTION MENU (HIỆN TRƯỚC KHI LOAD UI)
-- ============================================================
_G.SavedLanguage = nil
_G.Language = nil

local function ShowLanguageMenu()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MarvenRizLangMenu"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local dim = Instance.new("Frame")
    dim.Size = UDim2.new(1, 0, 1, 0)
    dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dim.BackgroundTransparency = 0.4
    dim.BorderSizePixel = 0
    dim.Parent = screenGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 420, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -210, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(50, 150, 255)
    stroke.Thickness = 2
    stroke.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 60)
    title.BackgroundTransparency = 1
    title.Text = "🌐 Chọn Ngôn Ngữ / Select Language / เลือกภาษา"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextWrapped = true
    title.Parent = mainFrame

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 30)
    sub.Position = UDim2.new(0, 0, 0, 55)
    sub.BackgroundTransparency = 1
    sub.Text = "Vui lòng chọn / Please choose / กรุณาเลือก"
    sub.TextColor3 = Color3.fromRGB(180, 180, 200)
    sub.TextSize = 13
    sub.Font = Enum.Font.Gotham
    sub.Parent = mainFrame

    local function createLangButton(text, yPos, accentColor, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.8, 0, 0, 60)
        btn.Position = UDim2.new(0.1, 0, 0, yPos)
        btn.BackgroundColor3 = accentColor
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 20
        btn.Font = Enum.Font.GothamBold
        btn.AutoButtonColor = true
        btn.Parent = mainFrame

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 10)
        c.Parent = btn

        btn.MouseButton1Click:Connect(function()
            screenGui:Destroy()
            callback()
        end)
        return btn
    end

    createLangButton("🇻🇳  Tiếng Việt", 100, Color3.fromRGB(220, 60, 60), function()
    _G.Language = "vi"
    _G.SavedLanguage = "vi"
end)

    createLangButton("🇬🇧  English", 175, Color3.fromRGB(50, 150, 255), function()
    _G.Language = "en"
    _G.SavedLanguage = "en"
end)

    createLangButton("🇹🇭  ภาษาไทย", 250, Color3.fromRGB(180, 100, 220), function()
    _G.Language = "th"
    _G.SavedLanguage = "th"
end)

    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, 0, 0, 25)
    footer.Position = UDim2.new(0, 0, 1, -30)
    footer.BackgroundTransparency = 1
    footer.Text = "MarvenRiz Hub © 2025"
    footer.TextColor3 = Color3.fromRGB(120, 120, 140)
    footer.TextSize = 12
    footer.Font = Enum.Font.Gotham
    footer.Parent = mainFrame

    repeat task.wait(0.1) until _G.Language ~= nil
end

-- 🆕 Hàm đọc ngôn ngữ từ Auto Load config
local function TryAutoLoadLanguage()
    local SAVE_FOLDER = "MarvenRizSave/RockFruit"
    local autoloadPath = SAVE_FOLDER .. "/autoload.json"

    if not isfile(autoloadPath) then return false end

    local ok, raw = pcall(function() return readfile(autoloadPath) end)
    if not ok or not raw or raw == "" then return false end

    local okDecode, data = pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
    if not okDecode or type(data) ~= "table" then return false end
    if not data.Enabled or not data.Path then return false end

    if not isfile(data.Path) then return false end

    local okFile, fileRaw = pcall(function() return readfile(data.Path) end)
    if not okFile or not fileRaw then return false end

    local okFileData, fileData = pcall(function() return game:GetService("HttpService"):JSONDecode(fileRaw) end)
    if not okFileData or type(fileData) ~= "table" then return false end

    local savedLang = fileData["SavedLanguage"]
    if type(savedLang) == "string" and (savedLang == "vi" or savedLang == "en" or savedLang == "th") then
        _G.Language = savedLang
        _G.SavedLanguage = savedLang
        return true
    end

    return false
end

local autoLoaded = TryAutoLoadLanguage()
if not autoLoaded then
    ShowLanguageMenu()
end

print("[Sea 1] 🌐 Ngôn ngữ:", _G.Language, autoLoaded and "(Auto Load)" or "(Chọn tay)")

-- ============================================================
-- TRANSLATION SYSTEM (VI / EN / TH)
-- ============================================================
local TRANSLATIONS = {
    vi = {
        -- Window
        ["Auto Raid Moon Only"]              = "Chỉ Auto Raid Moon",
        ["Sea 1 — Rock Fruit"]               = "Sea 1 — Rock Fruit",

        -- Moon Tab
        ["Auto Raid Moon"]                   = "Auto Raid Moon",
        ["Moon Raid"]                        = "Moon Raid",
        ["🌙 Auto Farm Moon"]                = "🌙 Tự Động Cày Moon",
        ["⚔️ Attack / Skill"]                = "⚔️ Tấn Công / Kỹ Năng",
        ["🗡️ Weapons"]                       = "🗡️ Vũ Khí",
        ["📊 Status"]                        = "📊 Trạng Thái",
        ["🌍 Travel"]                        = "🌍 Di Chuyển",
        ["Trạng thái: Chờ bật"]              = "Trạng thái: Chờ bật",
        ["Bật toggle bên trái để farm Moon"] = "Bật toggle bên trái để farm Moon",
        ["🌙 Auto Farm Moon Mob"]            = "🌙 Tự Động Cày Moon",
        ["🎯 Vị trí đánh"]                   = "🎯 Vị trí đánh",
        ["Upper (Trên đầu)"]                 = "Upper (Trên đầu)",
        ["Below (Dưới chân)"]                = "Below (Dưới chân)",
        ["Behind (Phía sau)"]                = "Behind (Phía sau)",
        ["Front (Phía trước)"]               = "Front (Phía trước)",
        ["📏 Khoảng cách đánh"]              = "📏 Khoảng cách đánh",
        ["🗡️ Main Weapon"]                   = "🗡️ Vũ Khí Chính",
        ["🗡️ Support Weapons"]               = "🗡️ Vũ Khí Hỗ Trợ",
        ["⚔️ Auto Attack + Skill (Ưu tiên Skill)"] = "⚔️ Tự Động Đánh + Kỹ Năng (Ưu tiên Skill)",
        ["Auto Skill Z"]                     = "Tự Động Kỹ Năng Z",
        ["Auto Skill X"]                     = "Tự Động Kỹ Năng X",
        ["Auto Skill C"]                     = "Tự Động Kỹ Năng C",
        ["Auto Skill V"]                     = "Tự Động Kỹ Năng V",
        ["Auto Skill F"]                     = "Tự Động Kỹ Năng F",
        ["🌍 Quay Về Trái Đất (Back Earth)"] = "🌍 Quay Về Trái Đất",

        -- Setting Moon
        ["⚙️ Setting"]                       = "⚙️ Cài Đặt",
        ["Save / Load"]                      = "Lưu / Tải",
        ["💾 Quản Lý Save"]                  = "💾 Quản Lý Save",
        ["📋 Thông Tin"]                     = "📋 Thông Tin",
        ["📖 Hướng dẫn"]                     = "📖 Hướng dẫn",
        ["1. Nhập tên Save → SAVE\n2. Chọn Save từ dropdown → LOAD\n3. Xóa bằng nút 🗑️"] =
            "1. Nhập tên Save → SAVE\n2. Chọn Save từ dropdown → LOAD\n3. Xóa bằng nút 🗑️",
        ["📁 Save hiện có:"]                 = "📁 Save hiện có:",
        ["(chưa có save)"]                   = "(chưa có save)",
        ["✏️ Tên Save mới"]                  = "✏️ Tên Save mới",
        ["📁 Chọn Save"]                     = "📁 Chọn Save",
        ["💾 SAVE"]                          = "💾 LƯU",
        ["📂 LOAD"]                          = "📂 TẢI",
        ["🗑️ Xóa Save"]                      = "🗑️ Xóa Save",
        ["🔄 Làm mới danh sách"]             = "🔄 Làm mới danh sách",

        -- Settings Tab
        ["Settings"]                         = "Cài Đặt",
        ["Main Settings"]                    = "Cài Đặt Chính",
        ["🗡️ Select Weapon"]                 = "🗡️ Chọn Vũ Khí",
        ["⚔️ Auto Skills"]                   = "⚔️ Kỹ Năng Tự Động",
        ["🎯 Select Method Farm"]            = "🎯 Chọn Cách Cày",
        ["👁️ Haki"]                          = "👁️ Haki",
        ["✨ VFX"]                            = "✨ Hiệu Ứng",
        ["Other Settings"]                   = "Cài Đặt Khác",
        ["🎒 Accessory & Rebirth"]           = "🎒 Phụ Kiện & Hồi Sinh",
        ["🧪 Auto Use X2 Potion"]            = "🧪 Tự Dùng Bùa X2",
        ["Main Weapon (Attack)"]             = "Vũ Khí Chính (Tấn Công)",
        ["Select Support Weapon"]            = "Chọn Vũ Khí Hỗ Trợ",
        ["ℹ️ Cơ chế"]                         = "ℹ️ Cơ chế",
        ["• Ưu tiên dùng Skill (Z/X/C/V/F đã bật)\n• Hết skill → tự động đánh thường\n• Chỉ cần bật 1 nút"] =
            "• Ưu tiên dùng Skill (Z/X/C/V/F đã bật)\n• Hết skill → tự động đánh thường\n• Chỉ cần bật 1 nút",
        ["Auto Enabled Haki"]                = "Tự Bật Haki",
        ["Select Method Farm"]               = "Chọn Cách Cày",
        ["Behind"]                           = "Behind (Sau)",
        ["Below"]                            = "Below (Dưới)",
        ["Upper"]                            = "Upper (Trên)",
        ["Front"]                            = "Front (Trước)",
        ["Distance Farm"]                    = "Khoảng Cách Cày",
        ["Disable VFX"]                      = "Tắt Hiệu Ứng",
        ["Auto Equip Best Accessory"]        = "Tự Trang Bị Phụ Kiện Tốt Nhất",
        ["Auto Rebirth (Max Level)"]         = "Tự Hồi Sinh (Max Cấp)",
        ["Select X2 Potion"]                 = "Chọn Bùa X2",
        ["Số lượng dùng (1-100)"]            = "Số lượng dùng (1-100)",
        ["🧪 USE X2 POTION (1 lần)"]         = "🧪 DÙNG BÙA X2 (1 lần)",

        -- Main Tab
        ["Main"]                             = "Chính",
        ["Farm"]                             = "Cày",
        ["Boss"]                             = "Trùm",
        ["Raid Boss & Shop"]                 = "Raid Trùm & Cửa Hàng",
        ["Dungeon, Shop / Weapon"]           = "Hầm Ngục, Cửa Hàng / Vũ Khí",
        ["🌾 Auto Farm"]                     = "🌾 Tự Động Cày",
        ["⛏️ Auto Farm Material"]            = "⛏️ Tự Cày Nguyên Liệu",
        ["👹 Boss"]                          = "👹 Trùm",
        ["💸 Thief"]                         = "💸 Kẻ Trộm",
        ["🐉 Piccolo"]                       = "🐉 Piccolo",
        ["🔍 Spawned Check"]                 = "🔍 Kiểm Tra Xuất Hiện",
        ["🦆 Duck"]                          = "🦆 Vịt",
        ["⛵ Devil Boat"]                    = "⛵ Thuyền Quỷ",
        ["🏰 Auto Dungeon"]                  = "🏰 Tự Động Hầm Ngục",
        ["🏪 Shop Dungeon"]                  = "🏪 Cửa Hàng Hầm Ngục",
        ["🔨 Weapon"]                        = "🔨 Vũ Khí",
        ["⚙️ Dungeon Settings"]              = "⚙️ Cài Đặt Hầm Ngục",
        ["📊 Shop Dungeon Info"]             = "📊 Thông Tin Shop Hầm Ngục",
        ["🌋 Auto Raid Moon"]                = "🌋 Tự Động Raid Moon",
        ["⚔️ Auto Raid Boss"]                = "⚔️ Tự Động Raid Trùm",
        ["📋 Raid Info"]                     = "📋 Thông Tin Raid",
        ["🏪 Shop Raid"]                     = "🏪 Cửa Hàng Raid",
        ["📊 Shop Info"]                     = "📊 Thông Tin Shop",
        ["⚙️ Raid Settings"]                 = "⚙️ Cài Đặt Raid",
        ["🎁 Time Mystery Box"]              = "🎁 Hộp Bí Ẩn Thời Gian",
        ["Auto Level Farm"]                  = "Tự Động Cày Cấp Độ",
        ["Select Farm Material"]             = "Chọn Nguyên Liệu Cày",
        ["Auto Farm Material"]               = "Tự Cày Nguyên Liệu",
        ["Select Boss"]                      = "Chọn Trùm",
        ["Auto Farm All Boss (Full)"]        = "Tự Cày Tất Cả Trùm (Full)",
        ["Auto Farm Thief Chest"]            = "Tự Cày Rương Kẻ Trộm",
        ["Auto Farm Piccolo"]                = "Tự Cày Piccolo",
        ["Auto Farm Duck (Full)"]            = "Tự Cày Vịt (Full)",
        ["Auto Farm Devil Boat"]             = "Tự Cày Thuyền Quỷ",
        ["Auto Farm Kraken"]                 = "Tự Cày Kraken",
        ["Spawn Status"]                     = "Trạng Thái Xuất Hiện",
        ["Item Requirements ( None )"]       = "Nguyên Liệu Cần ( Trống )",
        ["Select Weapon Craft"]              = "Chọn Vũ Khí Chế Tạo",
        ["Craft Weapon"]                     = "Chế Tạo Vũ Khí",
        ["Auto Craft Weapon (Full)"]         = "Tự Chế Vũ Khí (Full)",
        ["Auto Farm Set Weapon"]             = "Tự Cày Bộ Vũ Khí",
        ["Auto Raid Moon (Full)"]            = "Tự Raid Moon (Full)",
        ["Dungeon Orb to Use"]               = "Ngọc Hầm Ngục Dùng",
        ["Health Return %"]                  = "Hồi Máu %",
        ["Dungeon Height"]                   = "Độ Cao Hầm Ngục",
        ["🏰 Auto Dungeon (Full)"]           = "🏰 Tự Động Hầm Ngục (Full)",
        ["Choose a boss to raid"]            = "Chọn trùm để raid",
        ["Bacon of Grudge"]                  = "Bacon of Grudge",
        ["??? (Raid 2)"]                     = "??? (Raid 2)",
        ["??? (Raid 3)"]                     = "??? (Raid 3)",
        ["Start Raid Now!!"]                 = "Bắt Đầu Raid Ngay!!",
        ["Bacon of Grudge Height"]           = "Độ Cao Bacon of Grudge",
        ["Golden Ball Height"]               = "Độ Cao Quả Cầu Vàng",
        ["RaidPoint: ( đang load... )"]      = "Điểm Raid: ( đang tải... )",
        ["Restock In: ( đang load... )"]     = "Hồi Hàng Trong: ( đang tải... )",
        ["Select Items to Purchase"]         = "Chọn Vật Phẩm Mua",
        ["BUY!!"]                            = "MUA!!",
        ["🎁 Time Mystery Box: ---"]         = "🎁 Hộp Bí Ẩn Thời Gian: ---",
        ["Nhập số lượng và bấm nút để mở"]   = "Nhập số lượng và bấm nút để mở",
        ["Số lượng mở (1-100)"]              = "Số lượng mở (1-100)",
        ["🎁 MỞ TIME MYSTERY BOX (1 lần)"]  = "🎁 MỞ HỘP BÍ ẨN (1 lần)",
        ["DungeonPoint: ( đang load... )"]   = "Điểm Hầm Ngục: ( đang tải... )",
        ["Chọn item Auto Buy ở cột trái"]    = "Chọn item Auto Buy ở cột trái",
        ["Auto Buy Items"]                   = "Vật Phẩm Tự Mua",
        ["Auto Buy"]                         = "Tự Động Mua",

        -- Other Tab
        ["Other"]                            = "Khác",
        ["Sell Item / Status"]               = "Bán Vật / Trạng Thái",
        ["Random Chest"]                     = "Rương Ngẫu Nhiên",
        ["Craft Table"]                      = "Bàn Chế Tạo",
        ["Npc Goku Gods"]                    = "NPC Goku Gods",
        ["💰 Auto Sell"]                     = "💰 Tự Bán",
        ["💎 Diamond Chest"]                 = "💎 Rương Kim Cương",
        ["🌙 Moon Chest"]                    = "🌙 Rương Moon",
        ["🎖️ Guarantee Gem Point"]          = "🎖️ Điểm Đảm Bảo Kim Cương",
        ["☄️ Guarantee Moon Point"]          = "☄️ Điểm Đảm Bảo Moon",
        ["🔨 Craft Table"]                   = "🔨 Bàn Chế Tạo",
        ["📊 Trạng Thái"]                    = "📊 Trạng Thái",
        ["📋 Craft Info"]                    = "📋 Thông Tin Chế Tạo",
        ["📍 NPC Đang Có"]                   = "📍 NPC Đang Có",
        ["⚙️ Actions"]                       = "⚙️ Hành Động",
        ["Select Sell Item"]                 = "Chọn Vật Bán",
        ["Auto Sell"]                        = "Tự Động Bán",
        ["Status Amount"]                    = "Số Lượng Trạng Thái",
        ["Auto Up Melee"]                    = "Tự Nâng Melee",
        ["Auto Up Defense"]                  = "Tự Nâng Phòng Thủ",
        ["Auto Up Sword"]                    = "Tự Nâng Kiếm",
        ["Auto Up Power"]                    = "Tự Nâng Sức Mạnh",
        ["Select Random Diamond Chest"]      = "Chọn Rương Kim Cương Ngẫu Nhiên",
        ["🎲 Mở 1 lần (Random Item)"]        = "🎲 Mở 1 lần (Vật Ngẫu Nhiên)",
        ["Auto Random Diamond Chest"]        = "Tự Mở Rương Kim Cương",
        ["Select Random Moon Chest"]         = "Chọn Rương Moon Ngẫu Nhiên",
        ["🌙 Mở 1 lần (Event Moon)"]         = "🌙 Mở 1 lần (Sự Kiện Moon)",
        ["Auto Random Moon Chest"]           = "Tự Mở Rương Moon",
        ["Select Guarantee Diamond Point"]   = "Chọn Điểm Đảm Bảo Kim Cương",
        ["💎 MUA 1 lần"]                     = "💎 MUA 1 lần",
        ["Auto Buy Guarantee Diamond"]       = "Tự Mua Đảm Bảo Kim Cương",
        ["Select Guarantee Moon Point"]      = "Chọn Điểm Đảm Bảo Moon",
        ["🌙 MUA 1 lần"]                     = "🌙 MUA 1 lần",
        ["Auto Buy Guarantee Moon"]          = "Tự Mua Đảm Bảo Moon",
        ["Chọn Items để chế tạo"]            = "Chọn Vật Phẩm Để Chế Tạo",
        ["🔨 Auto Chế Tạo"]                  = "🔨 Tự Động Chế Tạo",
        ["✅ Auto Claim Guarantee (Ưu tiên cao)"] = "✅ Tự Nhận Đảm Bảo (Ưu tiên cao)",
        ["⏱️ Tốc độ hiện tại: 2.00s/lần"]   = "⏱️ Tốc độ hiện tại: 2.00s/lần",
        ["🟢 Rất an toàn"]                   = "🟢 Rất an toàn",
        ["🟢 An toàn (0.5s)"]                = "🟢 An toàn (0.5s)",
        ["🟢 Rất an toàn (1.0s)"]            = "🟢 Rất an toàn (1.0s)",
        ["🟢 Cực an toàn (2.0s)"]            = "🟢 Cực an toàn (2.0s)",
        ["🔵 Siêu chậm (5.0s)"]              = "🔵 Siêu chậm (5.0s)",
        ["📖 Hướng dẫn tốc độ"]              = "📖 Hướng dẫn tốc độ",
        ["🟢 0.5-1.0s: An toàn (khuyến nghị)\n🟢 1.0-2.0s: Rất an toàn\n🟢 2.0-5.0s: Cực an toàn\n🔵 5.0s+: Chỉ dùng khi ping cao\n\n💡 Nếu vẫn phí → chọn mức 2.0s hoặc 5.0s"] =
            "🟢 0.5-1.0s: An toàn (khuyến nghị)\n🟢 1.0-2.0s: Rất an toàn\n🟢 2.0-5.0s: Cực an toàn\n🔵 5.0s+: Chỉ dùng khi ping cao\n\n💡 Nếu vẫn phí → chọn mức 2.0s hoặc 5.0s",
        ["🎯 Auto Find & Click NPC"]         = "🎯 Tự Tìm & Click NPC",
        ["✈️ Auto TP Nearest NPC"]           = "✈️ Tự Dịch Chuyển NPC Gần Nhất",
        ["Npc Count: 0 / 5"]                 = "Số NPC: 0 / 5",
        ["Đang tìm NPC..."]                  = "Đang tìm NPC...",

        -- Teleport Tab
        ["Teleport"]                         = "Dịch Chuyển",
        ["Teleport Sea 1"]                   = "Dịch Chuyển Sea 1",
        ["🏝️ Đảo Sea 1"]                     = "🏝️ Đảo Sea 1",
        ["🌊 Sea Travel"]                    = "🌊 Đi Biển",
        ["📊 Thông Tin"]                     = "📊 Thông Tin",
        ["🏝️ Chọn Đảo Sea 1"]                = "🏝️ Chọn Đảo Sea 1",
        ["✈️ Dịch Chuyển Tới Đảo"]           = "✈️ Dịch Chuyển Tới Đảo",
        ["🌊 Đi Tới Sea 2 (2SeaSoon)"]       = "🌊 Đi Tới Sea 2 (2SeaSoon)",
        ["Đang load..."]                     = "Đang tải...",
        ["Sea"]                              = "Biển",

        -- Config Tab
        ["Config"]                           = "Cấu Hình",

        -- ===== NOTIFY / DYNAMIC MESSAGES =====
        ["Chưa chọn đảo"]                    = "Chưa chọn đảo",
        ["Chọn 1 đảo trước!"]                = "Chọn 1 đảo trước!",
        ["Không có nhân vật"]                = "Không có nhân vật",
        ["Character chưa load"]              = "Character chưa load",
        ["Không tìm thấy NPC"]               = "Không tìm thấy NPC",
        ["BackEarth không tồn tại"]          = "BackEarth không tồn tại",
        ["Không có prompt"]                  = "Không có prompt",
        ["Đã kích hoạt"]                     = "Đã kích hoạt",
        ["Đang chờ chuyển map..."]           = "Đang chờ chuyển map...",
        ["Đã lưu"]                           = "Đã lưu",
        ["Lỗi lưu"]                          = "Lỗi lưu",
        ["Tên save trống"]                   = "Tên save trống",
        ["Nhập tên trước!"]                  = "Nhập tên trước!",
        ["Không tìm thấy"]                   = "Không tìm thấy",
        ["Lỗi đọc file"]                     = "Lỗi đọc file",
        ["Đã load"]                          = "Đã load",
        ["Chọn save trước!"]                 = "Chọn save trước!",
        ["Chưa nhập tên"]                    = "Chưa nhập tên",
        ["Nhập tên save!"]                   = "Nhập tên save!",
        ["Chưa có save"]                     = "Chưa có save",
        ["Chưa có file save nào!"]           = "Chưa có file save nào!",
        ["Nhắc nhở"]                         = "Nhắc nhở",
        ["Tắt/Bật Auto Farm để áp dụng"]     = "Tắt/Bật Auto Farm để áp dụng",
        ["Chưa chọn Save"]                   = "Chưa chọn Save",
        ["Chưa có save để xóa!"]             = "Chưa có save để xóa!",
        ["Đã xóa"]                           = "Đã xóa",
        ["Không có"]                         = "Không có",
        ["Đã làm mới"]                       = "Đã làm mới",
        ["Danh sách save"]                   = "Danh sách save",
        ["Chưa chọn Potion"]                 = "Chưa chọn Potion",
        ["Chọn 1 loại X2 Potion trước!"]     = "Chọn 1 loại X2 Potion trước!",
        ["Không có Potion"]                  = "Không có Potion",
        ["Không tìm thấy Remote"]            = "Không tìm thấy Remote",
        ["Remotes.Inventory"]                = "Remotes.Inventory",
        ["Đang dùng Potion"]                 = "Đang dùng Potion",
        ["có"]                               = "có",
        ["Raid not selected"]                = "Chưa chọn Raid",
        ["Please choose a Boss Raid!"]       = "Vui lòng chọn Boss Raid!",
        ["Raid không hợp lệ"]                = "Raid không hợp lệ",
        ["NO RAID!!!"]                       = "KHÔNG RAID!!!",
        ["Start Raid"]                       = "Bắt Đầu Raid",
        ["Stop Raid"]                        = "Dừng Raid",
        ["Chưa chọn item"]                   = "Chưa chọn item",
        ["Vui lòng chọn item trước!"]        = "Vui lòng chọn item trước!",
        ["Đã mua"]                           = "Đã mua",
        ["Không có Box"]                     = "Không có Box",
        ["Time Mystery Box (0)"]             = "Hộp Bí Ẩn Thời Gian (0)",
        ["NetworkEvent không tồn tại"]       = "NetworkEvent không tồn tại",
        ["Đang mở Box"]                      = "Đang mở Box",
        ["Mở"]                               = "Mở",
        ["box"]                              = "hộp",
        ["Còn lại"]                          = "Còn lại",
        ["Lỗi fire"]                         = "Lỗi fire",
        ["Không mở được box"]                = "Không mở được box",
        ["Chọn item Auto Buy trước!"]        = "Chọn item Auto Buy trước!",
        ["Bật Auto Buy"]                     = "Bật Auto Buy",
        ["Tắt Auto Buy"]                     = "Tắt Auto Buy",
        ["Đổi tốc độ"]                       = "Đổi tốc độ",
        ["An toàn"]                          = "An toàn",
        ["Rất an toàn"]                      = "Rất an toàn",
        ["Cực an toàn"]                      = "Cực an toàn",
        ["Siêu chậm"]                        = "Siêu chậm",
        ["Anti-cheat"]                       = "Chống gian lận",
        ["Đã tắt Auto Farm. Đợi 30s!"]       = "Đã tắt Auto Farm. Đợi 30s!",
        ["Thiếu Class"]                      = "Thiếu Class",
        ["Bạn cần class này để craft"]       = "Bạn cần class này để craft",
        ["Thiếu Beli"]                       = "Thiếu Beli",
        ["Cần"]                              = "Cần",
        ["Thiếu Materials"]                  = "Thiếu Nguyên Liệu",
        ["Chưa chọn Weapon"]                 = "Chưa chọn Weapon",
        ["Chọn weapon trong dropdown trước!"]= "Chọn weapon trong dropdown trước!",
        ["Hết Orb Boss"]                     = "Hết Orb Boss",
        ["Đã tắt Auto Farm Boss (Full)!"]    = "Đã tắt Auto Farm Boss (Full)!",
        ["Thiếu Duck Items"]                 = "Thiếu Duck Items",
        ["Không đủ Portal Gun"]              = "Không đủ Portal Gun",
        ["Portal Gun!"]                      = "Portal Gun!",
        ["Không đủ MoonStone"]               = "Không đủ MoonStone",
        ["Đã mở"]                            = "Đã mở",
        ["Không đủ PointItem"]               = "Không đủ PointItem",
        ["Không đủ MoonPoint"]               = "Không đủ MoonPoint",
        ["Không tìm thấy NPC Sea 2"]         = "Không tìm thấy NPC Sea 2",
        ["workspace.2SeaSoon không có"]      = "workspace.2SeaSoon không có",
        ["Đã tới NPC Sea 2"]                 = "Đã tới NPC Sea 2",
        ["Chờ game chuyển Sea..."]           = "Chờ game chuyển Sea...",
        ["Bật Auto Goku"]                    = "Bật Auto Goku",
        ["Tắt Auto Goku"]                    = "Tắt Auto Goku",
        ["Tự động tìm + click"]              = "Tự động tìm + click",
        ["Bật Auto TP"]                      = "Bật Auto TP",
        ["Tắt Auto TP"]                      = "Tắt Auto TP",
        ["TP tới NPC gần nhất"]              = "TP tới NPC gần nhất",
        ["Reset phiên NPC"]                  = "Reset phiên NPC",
        ["Đã đủ 5 NPC"]                      = "Đã đủ 5 NPC",
        ["Đủ 5 NPC — reset phiên"]           = "Đủ 5 NPC — reset phiên",
        ["NPC Spawn!"]                       = "NPC Xuất Hiện!",
        ["NPC Respawn!"]                     = "NPC Hồi Sinh!",
        ["quay lại!"]                        = "quay lại!",

        -- Dynamic notify parts
        ["Đã chọn"]                          = "Đã chọn",
        ["bấm BUY để mua"]                   = "bấm BUY để mua",
        ["bật Toggle Auto Buy"]              = "bật Toggle Auto Buy",
        ["Đợi chọn item"]                    = "Đợi chọn item",
        ["Chọn item để bắt đầu"]             = "Chọn item để bắt đầu",
        ["Chưa chọn Item"]                   = "Chưa chọn Item",
        ["Không tìm thấy Item"]              = "Không tìm thấy Item",
        ["Không có công thức"]               = "Không có công thức",
        ["Công thức:"]                       = "Công thức:",
        ["Có thể chế:"]                      = "Có thể chế:",
        ["lần"]                              = "lần",
        ["Số lần có thể chế: ---"]           = "Số lần có thể chế: ---",
        ["Guarantee: ---/---"]               = "Đảm Bảo: ---/---",
        ["ĐANG CHẾ TẠO"]                     = "ĐANG CHẾ TẠO",
        ["Đợi:"]                             = "Đợi:",
        ["CHỜ CLAIM GUARANTEE"]              = "CHỜ NHẬN ĐẢM BẢO",
        ["Đợi server..."]                    = "Đợi server...",
        ["Đang chờ"]                         = "Đang chờ",
        ["ĐÃ ĐẦY — Đang claim..."]           = "ĐÃ ĐẦY — Đang nhận...",
        ["Còn"]                              = "Còn",
        ["slot trống"]                       = "slot trống",
        ["Chưa có item nào"]                 = "Chưa có item nào",
        ["Guarantee:"]                       = "Đảm Bảo:",

        -- Info / Paragraph dynamic
        ["Trạng thái: ĐANG FARM"]            = "Trạng thái: ĐANG FARM",
        ["Trạng thái: Đã tắt"]               = "Trạng thái: Đã tắt",
        ["Đang tìm mob..."]                  = "Đang tìm mob...",
        ["Bật lại để tiếp tục"]              = "Bật lại để tiếp tục",
        ["Chờ mob..."]                       = "Chờ mob...",
        ["Đứng tại cửa hang đợi mob"]        = "Đứng tại cửa hang đợi mob",
        ["ĐANG ĐÁNH"]                        = "ĐANG ĐÁNH",
        ["BẢO VỆ ROCKETTOWER"]               = "BẢO VỆ ROCKETTOWER",
        ["Đảo:"]                             = "Đảo:",
        ["Name:"]                            = "Tên:",
        ["( chưa chọn )"]                    = "( chưa chọn )",
        ["Please choose a Boss Raid!!"]      = "Vui lòng chọn Boss Raid!!",
        ["Reward:"]                          = "Phần thưởng:",
        ["Giá:"]                             = "Giá:",
        ["Đủ mua"]                           = "Đủ mua",
        ["Thiếu"]                            = "Thiếu",
        ["Item: (chưa chọn)"]                = "Vật phẩm: (chưa chọn)",
        ["Số lượng mở:"]                     = "Số lượng mở:",
        ["Có thể mở:"]                       = "Có thể mở:",
        ["Phiên:"]                           = "Phiên:",
        ["Đang có mặt:"]                     = "Đang có mặt:",
        ["Không có NPC nào"]                 = "Không có NPC nào",
        ["Npc Count:"]                       = "Số NPC:",
        ["studs"]                            = "studs",
        ["đã"]                               = "đã",
		["Time Mystery Box x5, 7500 Diamond, Beli 50M, x3 Potion"] = "Hộp Bí Ẩn Thời Gian x5, 7500 Kim Cương, Beli 50M, Bùa x3",
    },
	
	    en = {
        -- Window
        ["Auto Raid Moon Only"]              = "Auto Raid Moon Only",
        ["Sea 1 — Rock Fruit"]               = "Sea 1 — Rock Fruit",

        -- Moon Tab
        ["Auto Raid Moon"]                   = "Auto Raid Moon",
        ["Moon Raid"]                        = "Moon Raid",
        ["🌙 Auto Farm Moon"]                = "🌙 Auto Farm Moon",
        ["⚔️ Attack / Skill"]                = "⚔️ Attack / Skill",
        ["🗡️ Weapons"]                       = "🗡️ Weapons",
        ["📊 Status"]                        = "📊 Status",
        ["🌍 Travel"]                        = "🌍 Travel",
        ["Trạng thái: Chờ bật"]              = "Status: Waiting",
        ["Bật toggle bên trái để farm Moon"] = "Enable left toggle to farm Moon",
        ["🌙 Auto Farm Moon Mob"]            = "🌙 Auto Farm Moon Mob",
        ["🎯 Vị trí đánh"]                   = "🎯 Hit Position",
        ["Upper (Trên đầu)"]                 = "Upper",
        ["Below (Dưới chân)"]                = "Below",
        ["Behind (Phía sau)"]                = "Behind",
        ["Front (Phía trước)"]               = "Front",
        ["📏 Khoảng cách đánh"]              = "📏 Hit Distance",
        ["🗡️ Main Weapon"]                   = "🗡️ Main Weapon",
        ["🗡️ Support Weapons"]               = "🗡️ Support Weapons",
        ["⚔️ Auto Attack + Skill (Ưu tiên Skill)"] = "⚔️ Auto Attack + Skill (Skill First)",
        ["Auto Skill Z"]                     = "Auto Skill Z",
        ["Auto Skill X"]                     = "Auto Skill X",
        ["Auto Skill C"]                     = "Auto Skill C",
        ["Auto Skill V"]                     = "Auto Skill V",
        ["Auto Skill F"]                     = "Auto Skill F",
        ["🌍 Quay Về Trái Đất (Back Earth)"] = "🌍 Back To Earth",

        -- Setting Moon
        ["⚙️ Setting"]                       = "⚙️ Setting",
        ["Save / Load"]                      = "Save / Load",
        ["💾 Quản Lý Save"]                  = "💾 Save Manager",
        ["📋 Thông Tin"]                     = "📋 Information",
        ["📖 Hướng dẫn"]                     = "📖 Guide",
        ["1. Nhập tên Save → SAVE\n2. Chọn Save từ dropdown → LOAD\n3. Xóa bằng nút 🗑️"] =
            "1. Enter Save name → SAVE\n2. Pick Save from dropdown → LOAD\n3. Delete with 🗑️ button",
        ["📁 Save hiện có:"]                 = "📁 Existing saves:",
        ["(chưa có save)"]                   = "(no save yet)",
        ["✏️ Tên Save mới"]                  = "✏️ New Save Name",
        ["📁 Chọn Save"]                     = "📁 Choose Save",
        ["💾 SAVE"]                          = "💾 SAVE",
        ["📂 LOAD"]                          = "📂 LOAD",
        ["🗑️ Xóa Save"]                      = "🗑️ Delete Save",
        ["🔄 Làm mới danh sách"]             = "🔄 Refresh List",

        -- Settings Tab
        ["Settings"]                         = "Settings",
        ["Main Settings"]                    = "Main Settings",
        ["🗡️ Select Weapon"]                 = "🗡️ Select Weapon",
        ["⚔️ Auto Skills"]                   = "⚔️ Auto Skills",
        ["🎯 Select Method Farm"]            = "🎯 Select Farm Method",
        ["👁️ Haki"]                          = "👁️ Haki",
        ["✨ VFX"]                            = "✨ VFX",
        ["Other Settings"]                   = "Other Settings",
        ["🎒 Accessory & Rebirth"]           = "🎒 Accessory & Rebirth",
        ["🧪 Auto Use X2 Potion"]            = "🧪 Auto Use X2 Potion",
        ["Main Weapon (Attack)"]             = "Main Weapon (Attack)",
        ["Select Support Weapon"]            = "Select Support Weapon",
        ["ℹ️ Cơ chế"]                         = "ℹ️ Mechanism",
        ["• Ưu tiên dùng Skill (Z/X/C/V/F đã bật)\n• Hết skill → tự động đánh thường\n• Chỉ cần bật 1 nút"] =
            "• Prioritize Skill (Z/X/C/V/F enabled)\n• Skill out → auto normal attack\n• Only need 1 toggle",
        ["Auto Enabled Haki"]                = "Auto Enable Haki",
        ["Select Method Farm"]               = "Select Farm Method",
        ["Behind"]                           = "Behind",
        ["Below"]                            = "Below",
        ["Upper"]                            = "Upper",
        ["Front"]                            = "Front",
        ["Distance Farm"]                    = "Farm Distance",
        ["Disable VFX"]                      = "Disable VFX",
        ["Auto Equip Best Accessory"]        = "Auto Equip Best Accessory",
        ["Auto Rebirth (Max Level)"]         = "Auto Rebirth (Max Level)",
        ["Select X2 Potion"]                 = "Select X2 Potion",
        ["Số lượng dùng (1-100)"]            = "Amount (1-100)",
        ["🧪 USE X2 POTION (1 lần)"]         = "🧪 USE X2 POTION (once)",

        -- Main Tab
        ["Main"]                             = "Main",
        ["Farm"]                             = "Farm",
        ["Boss"]                             = "Boss",
        ["Raid Boss & Shop"]                 = "Raid Boss & Shop",
        ["Dungeon, Shop / Weapon"]           = "Dungeon, Shop / Weapon",
        ["🌾 Auto Farm"]                     = "🌾 Auto Farm",
        ["⛏️ Auto Farm Material"]            = "⛏️ Auto Farm Material",
        ["👹 Boss"]                          = "👹 Boss",
        ["💸 Thief"]                         = "💸 Thief",
        ["🐉 Piccolo"]                       = "🐉 Piccolo",
        ["🔍 Spawned Check"]                 = "🔍 Spawned Check",
        ["🦆 Duck"]                          = "🦆 Duck",
        ["⛵ Devil Boat"]                    = "⛵ Devil Boat",
        ["🏰 Auto Dungeon"]                  = "🏰 Auto Dungeon",
        ["🏪 Shop Dungeon"]                  = "🏪 Shop Dungeon",
        ["🔨 Weapon"]                        = "🔨 Weapon",
        ["⚙️ Dungeon Settings"]              = "⚙️ Dungeon Settings",
        ["📊 Shop Dungeon Info"]             = "📊 Shop Dungeon Info",
        ["🌋 Auto Raid Moon"]                = "🌋 Auto Raid Moon",
        ["⚔️ Auto Raid Boss"]                = "⚔️ Auto Raid Boss",
        ["📋 Raid Info"]                     = "📋 Raid Info",
        ["🏪 Shop Raid"]                     = "🏪 Shop Raid",
        ["📊 Shop Info"]                     = "📊 Shop Info",
        ["⚙️ Raid Settings"]                 = "⚙️ Raid Settings",
        ["🎁 Time Mystery Box"]              = "🎁 Time Mystery Box",
        ["Auto Level Farm"]                  = "Auto Level Farm",
        ["Select Farm Material"]             = "Select Farm Material",
        ["Auto Farm Material"]               = "Auto Farm Material",
        ["Select Boss"]                      = "Select Boss",
        ["Auto Farm All Boss (Full)"]        = "Auto Farm All Boss (Full)",
        ["Auto Farm Thief Chest"]            = "Auto Farm Thief Chest",
        ["Auto Farm Piccolo"]                = "Auto Farm Piccolo",
        ["Auto Farm Duck (Full)"]            = "Auto Farm Duck (Full)",
        ["Auto Farm Devil Boat"]             = "Auto Farm Devil Boat",
        ["Auto Farm Kraken"]                 = "Auto Farm Kraken",
        ["Spawn Status"]                     = "Spawn Status",
        ["Item Requirements ( None )"]       = "Item Requirements ( None )",
        ["Select Weapon Craft"]              = "Select Weapon Craft",
        ["Craft Weapon"]                     = "Craft Weapon",
        ["Auto Craft Weapon (Full)"]         = "Auto Craft Weapon (Full)",
        ["Auto Farm Set Weapon"]             = "Auto Farm Set Weapon",
        ["Auto Raid Moon (Full)"]            = "Auto Raid Moon (Full)",
        ["Dungeon Orb to Use"]               = "Dungeon Orb to Use",
        ["Health Return %"]                  = "Health Return %",
        ["Dungeon Height"]                   = "Dungeon Height",
        ["🏰 Auto Dungeon (Full)"]           = "🏰 Auto Dungeon (Full)",
        ["Choose a boss to raid"]            = "Choose a boss to raid",
        ["Bacon of Grudge"]                  = "Bacon of Grudge",
        ["??? (Raid 2)"]                     = "??? (Raid 2)",
        ["??? (Raid 3)"]                     = "??? (Raid 3)",
        ["Start Raid Now!!"]                 = "Start Raid Now!!",
        ["Bacon of Grudge Height"]           = "Bacon of Grudge Height",
        ["Golden Ball Height"]               = "Golden Ball Height",
        ["RaidPoint: ( đang load... )"]      = "RaidPoint: ( loading... )",
        ["Restock In: ( đang load... )"]     = "Restock In: ( loading... )",
        ["Select Items to Purchase"]         = "Select Items to Purchase",
        ["BUY!!"]                            = "BUY!!",
        ["🎁 Time Mystery Box: ---"]         = "🎁 Time Mystery Box: ---",
        ["Nhập số lượng và bấm nút để mở"]   = "Enter amount and press button to open",
        ["Số lượng mở (1-100)"]              = "Open Amount (1-100)",
        ["🎁 MỞ TIME MYSTERY BOX (1 lần)"]  = "🎁 OPEN TIME MYSTERY BOX (once)",
        ["DungeonPoint: ( đang load... )"]   = "DungeonPoint: ( loading... )",
        ["Chọn item Auto Buy ở cột trái"]    = "Select Auto Buy item on the left",
        ["Auto Buy Items"]                   = "Auto Buy Items",
        ["Auto Buy"]                         = "Auto Buy",

        -- Other Tab
        ["Other"]                            = "Other",
        ["Sell Item / Status"]               = "Sell Item / Status",
        ["Random Chest"]                     = "Random Chest",
        ["Craft Table"]                      = "Craft Table",
        ["Npc Goku Gods"]                    = "Npc Goku Gods",
        ["💰 Auto Sell"]                     = "💰 Auto Sell",
        ["💎 Diamond Chest"]                 = "💎 Diamond Chest",
        ["🌙 Moon Chest"]                    = "🌙 Moon Chest",
        ["🎖️ Guarantee Gem Point"]          = "🎖️ Guarantee Gem Point",
        ["☄️ Guarantee Moon Point"]          = "☄️ Guarantee Moon Point",
        ["🔨 Craft Table"]                   = "🔨 Craft Table",
        ["📊 Trạng Thái"]                    = "📊 Status",
        ["📋 Craft Info"]                    = "📋 Craft Info",
        ["📍 NPC Đang Có"]                   = "📍 Available NPCs",
        ["⚙️ Actions"]                       = "⚙️ Actions",
        ["Select Sell Item"]                 = "Select Sell Item",
        ["Auto Sell"]                        = "Auto Sell",
        ["Status Amount"]                    = "Status Amount",
        ["Auto Up Melee"]                    = "Auto Up Melee",
        ["Auto Up Defense"]                  = "Auto Up Defense",
        ["Auto Up Sword"]                    = "Auto Up Sword",
        ["Auto Up Power"]                    = "Auto Up Power",
        ["Select Random Diamond Chest"]      = "Select Random Diamond Chest",
        ["🎲 Mở 1 lần (Random Item)"]        = "🎲 Open once (Random Item)",
        ["Auto Random Diamond Chest"]        = "Auto Random Diamond Chest",
        ["Select Random Moon Chest"]         = "Select Random Moon Chest",
        ["🌙 Mở 1 lần (Event Moon)"]         = "🌙 Open once (Event Moon)",
        ["Auto Random Moon Chest"]           = "Auto Random Moon Chest",
        ["Select Guarantee Diamond Point"]   = "Select Guarantee Diamond Point",
        ["💎 MUA 1 lần"]                     = "💎 BUY once",
        ["Auto Buy Guarantee Diamond"]       = "Auto Buy Guarantee Diamond",
        ["Select Guarantee Moon Point"]      = "Select Guarantee Moon Point",
        ["🌙 MUA 1 lần"]                     = "🌙 BUY once",
        ["Auto Buy Guarantee Moon"]          = "Auto Buy Guarantee Moon",
        ["Chọn Items để chế tạo"]            = "Select Items to Craft",
        ["🔨 Auto Chế Tạo"]                  = "🔨 Auto Craft",
        ["✅ Auto Claim Guarantee (Ưu tiên cao)"] = "✅ Auto Claim Guarantee (High Priority)",
        ["⏱️ Tốc độ hiện tại: 2.00s/lần"]   = "⏱️ Current Speed: 2.00s/time",
        ["🟢 Rất an toàn"]                   = "🟢 Very Safe",
        ["🟢 An toàn (0.5s)"]                = "🟢 Safe (0.5s)",
        ["🟢 Rất an toàn (1.0s)"]            = "🟢 Very Safe (1.0s)",
        ["🟢 Cực an toàn (2.0s)"]            = "🟢 Extremely Safe (2.0s)",
        ["🔵 Siêu chậm (5.0s)"]              = "🔵 Ultra Slow (5.0s)",
        ["📖 Hướng dẫn tốc độ"]              = "📖 Speed Guide",
        ["🟢 0.5-1.0s: An toàn (khuyến nghị)\n🟢 1.0-2.0s: Rất an toàn\n🟢 2.0-5.0s: Cực an toàn\n🔵 5.0s+: Chỉ dùng khi ping cao\n\n💡 Nếu vẫn phí → chọn mức 2.0s hoặc 5.0s"] =
            "🟢 0.5-1.0s: Safe (recommended)\n🟢 1.0-2.0s: Very Safe\n🟢 2.0-5.0s: Extremely Safe\n🔵 5.0s+: Only when high ping\n\n💡 If still wasted → choose 2.0s or 5.0s",
        ["🎯 Auto Find & Click NPC"]         = "🎯 Auto Find & Click NPC",
        ["✈️ Auto TP Nearest NPC"]           = "✈️ Auto TP Nearest NPC",
        ["Npc Count: 0 / 5"]                 = "Npc Count: 0 / 5",
        ["Đang tìm NPC..."]                  = "Searching NPC...",

        -- Teleport Tab
        ["Teleport"]                         = "Teleport",
        ["Teleport Sea 1"]                   = "Teleport Sea 1",
        ["🏝️ Đảo Sea 1"]                     = "🏝️ Sea 1 Islands",
        ["🌊 Sea Travel"]                    = "🌊 Sea Travel",
        ["📊 Thông Tin"]                     = "📊 Information",
        ["🏝️ Chọn Đảo Sea 1"]                = "🏝️ Select Sea 1 Island",
        ["✈️ Dịch Chuyển Tới Đảo"]           = "✈️ Teleport To Island",
        ["🌊 Đi Tới Sea 2 (2SeaSoon)"]       = "🌊 Go To Sea 2 (2SeaSoon)",
        ["Đang load..."]                     = "Loading...",
        ["Sea"]                              = "Sea",

        -- Config Tab
        ["Config"]                           = "Config",

        -- NOTIFY / DYNAMIC MESSAGES
        ["Chưa chọn đảo"]                    = "No island selected",
        ["Chọn 1 đảo trước!"]                = "Choose an island first!",
        ["Không có nhân vật"]                = "No character",
        ["Character chưa load"]              = "Character not loaded",
        ["Không tìm thấy NPC"]               = "NPC not found",
        ["BackEarth không tồn tại"]          = "BackEarth doesn't exist",
        ["Không có prompt"]                  = "No prompt",
        ["Đã kích hoạt"]                     = "Activated",
        ["Đang chờ chuyển map..."]           = "Waiting for map change...",
        ["Đã lưu"]                           = "Saved",
        ["Lỗi lưu"]                          = "Save error",
        ["Tên save trống"]                   = "Save name empty",
        ["Nhập tên trước!"]                  = "Enter name first!",
        ["Không tìm thấy"]                   = "Not found",
        ["Lỗi đọc file"]                     = "File read error",
        ["Đã load"]                          = "Loaded",
        ["Chọn save trước!"]                 = "Choose save first!",
        ["Chưa nhập tên"]                    = "Name not entered",
        ["Nhập tên save!"]                   = "Enter save name!",
        ["Chưa có save"]                     = "No save yet",
        ["Chưa có file save nào!"]           = "No save file!",
        ["Nhắc nhở"]                         = "Reminder",
        ["Tắt/Bật Auto Farm để áp dụng"]     = "Toggle Auto Farm to apply",
        ["Chưa chọn Save"]                   = "No Save selected",
        ["Chưa có save để xóa!"]             = "No save to delete!",
        ["Đã xóa"]                           = "Deleted",
        ["Không có"]                         = "None",
        ["Đã làm mới"]                       = "Refreshed",
        ["Danh sách save"]                   = "Save list",
        ["Chưa chọn Potion"]                 = "No Potion selected",
        ["Chọn 1 loại X2 Potion trước!"]     = "Choose an X2 Potion first!",
        ["Không có Potion"]                  = "No Potion",
        ["Không tìm thấy Remote"]            = "Remote not found",
        ["Remotes.Inventory"]                = "Remotes.Inventory",
        ["Đang dùng Potion"]                 = "Using Potion",
        ["có"]                               = "have",
        ["Raid not selected"]                = "Raid not selected",
        ["Please choose a Boss Raid!"]       = "Please choose a Boss Raid!",
        ["Raid không hợp lệ"]                = "Invalid Raid",
        ["NO RAID!!!"]                       = "NO RAID!!!",
        ["Start Raid"]                       = "Start Raid",
        ["Stop Raid"]                        = "Stop Raid",
        ["Chưa chọn item"]                   = "No item selected",
        ["Vui lòng chọn item trước!"]        = "Please choose an item first!",
        ["Đã mua"]                           = "Purchased",
        ["Không có Box"]                     = "No Box",
        ["Time Mystery Box (0)"]             = "Time Mystery Box (0)",
        ["NetworkEvent không tồn tại"]       = "NetworkEvent doesn't exist",
        ["Đang mở Box"]                      = "Opening Box",
        ["Mở"]                               = "Open",
        ["box"]                              = "box",
        ["Còn lại"]                          = "Remaining",
        ["Lỗi fire"]                         = "Fire error",
        ["Không mở được box"]                = "Cannot open box",
        ["Chọn item Auto Buy trước!"]        = "Choose Auto Buy item first!",
        ["Bật Auto Buy"]                     = "Enable Auto Buy",
        ["Tắt Auto Buy"]                     = "Disable Auto Buy",
        ["Đổi tốc độ"]                       = "Change Speed",
        ["An toàn"]                          = "Safe",
        ["Rất an toàn"]                      = "Very Safe",
        ["Cực an toàn"]                      = "Extremely Safe",
        ["Siêu chậm"]                        = "Ultra Slow",
        ["Anti-cheat"]                       = "Anti-cheat",
        ["Đã tắt Auto Farm. Đợi 30s!"]       = "Auto Farm disabled. Wait 30s!",
        ["Thiếu Class"]                      = "Missing Class",
        ["Bạn cần class này để craft"]       = "You need this class to craft",
        ["Thiếu Beli"]                       = "Missing Beli",
        ["Cần"]                              = "Need",
        ["Thiếu Materials"]                  = "Missing Materials",
        ["Chưa chọn Weapon"]                 = "No Weapon selected",
        ["Chọn weapon trong dropdown trước!"]= "Choose weapon in dropdown first!",
        ["Hết Orb Boss"]                     = "Out of Orb Boss",
        ["Đã tắt Auto Farm Boss (Full)!"]    = "Auto Farm Boss (Full) disabled!",
        ["Thiếu Duck Items"]                 = "Missing Duck Items",
        ["Không đủ Portal Gun"]              = "Not enough Portal Gun",
        ["Portal Gun!"]                      = "Portal Gun!",
        ["Không đủ MoonStone"]               = "Not enough MoonStone",
        ["Đã mở"]                            = "Opened",
        ["Không đủ PointItem"]               = "Not enough PointItem",
        ["Không đủ MoonPoint"]               = "Not enough MoonPoint",
        ["Không tìm thấy NPC Sea 2"]         = "NPC Sea 2 not found",
        ["workspace.2SeaSoon không có"]      = "workspace.2SeaSoon missing",
        ["Đã tới NPC Sea 2"]                 = "Arrived at NPC Sea 2",
        ["Chờ game chuyển Sea..."]           = "Waiting for Sea change...",
        ["Bật Auto Goku"]                    = "Enable Auto Goku",
        ["Tắt Auto Goku"]                    = "Disable Auto Goku",
        ["Tự động tìm + click"]              = "Auto find + click",
        ["Bật Auto TP"]                      = "Enable Auto TP",
        ["Tắt Auto TP"]                      = "Disable Auto TP",
        ["TP tới NPC gần nhất"]              = "TP to nearest NPC",
        ["Reset phiên NPC"]                  = "Reset NPC session",
        ["Đã đủ 5 NPC"]                      = "5 NPCs reached",
        ["Đủ 5 NPC — reset phiên"]           = "5 NPCs reached — reset session",
        ["NPC Spawn!"]                       = "NPC Spawn!",
        ["NPC Respawn!"]                     = "NPC Respawn!",
        ["quay lại!"]                        = "returned!",

        -- Dynamic notify parts
        ["Đã chọn"]                          = "Selected",
        ["bấm BUY để mua"]                   = "press BUY to purchase",
        ["bật Toggle Auto Buy"]              = "enable Auto Buy Toggle",
        ["Đợi chọn item"]                    = "Waiting for item",
        ["Chọn item để bắt đầu"]             = "Choose item to start",
        ["Chưa chọn Item"]                   = "No Item selected",
        ["Không tìm thấy Item"]              = "Item not found",
        ["Không có công thức"]               = "No recipe",
        ["Công thức:"]                       = "Recipe:",
        ["Có thể chế:"]                      = "Can craft:",
        ["lần"]                              = "times",
        ["Số lần có thể chế: ---"]           = "Craftable count: ---",
        ["Guarantee: ---/---"]               = "Guarantee: ---/---",
        ["ĐANG CHẾ TẠO"]                     = "CRAFTING",
        ["Đợi:"]                             = "Wait:",
        ["CHỜ CLAIM GUARANTEE"]              = "WAITING FOR CLAIM GUARANTEE",
        ["Đợi server..."]                    = "Waiting for server...",
        ["Đang chờ"]                         = "Waiting",
        ["ĐÃ ĐẦY — Đang claim..."]           = "FULL — Claiming...",
        ["Còn"]                              = "Remaining",
        ["slot trống"]                       = "empty slots",
        ["Chưa có item nào"]                 = "No item yet",
        ["Guarantee:"]                       = "Guarantee:",

        -- Info / Paragraph dynamic
        ["Trạng thái: ĐANG FARM"]            = "Status: FARMING",
        ["Trạng thái: Đã tắt"]               = "Status: Disabled",
        ["Đang tìm mob..."]                  = "Searching mob...",
        ["Bật lại để tiếp tục"]              = "Re-enable to continue",
        ["Chờ mob..."]                       = "Waiting for mob...",
        ["Đứng tại cửa hang đợi mob"]        = "Standing at cave waiting for mob",
        ["ĐANG ĐÁNH"]                        = "ATTACKING",
        ["BẢO VỆ ROCKETTOWER"]               = "DEFEND ROCKETTOWER",
        ["Đảo:"]                             = "Island:",
        ["Name:"]                            = "Name:",
        ["( chưa chọn )"]                    = "( not selected )",
        ["Please choose a Boss Raid!!"]      = "Please choose a Boss Raid!!",
        ["Reward:"]                          = "Reward:",
        ["Giá:"]                             = "Price:",
        ["Đủ mua"]                           = "Can buy",
        ["Thiếu"]                            = "Missing",
        ["Item: (chưa chọn)"]                = "Item: (not selected)",
        ["Số lượng mở:"]                     = "Open amount:",
        ["Có thể mở:"]                       = "Can open:",
        ["Phiên:"]                           = "Session:",
        ["Đang có mặt:"]                     = "Present:",
        ["Không có NPC nào"]                 = "No NPCs",
        ["Npc Count:"]                       = "Npc Count:",
        ["studs"]                            = "studs",
        ["đã"]                               = "for",
		["Time Mystery Box x5, 7500 Diamond, Beli 50M, x3 Potion"] = "Time Mystery Box x5, 7500 Diamond, Beli 50M, x3 Potion",
    },

    th = {
        -- Window
        ["Auto Raid Moon Only"]              = "โหมด Raid Moon เท่านั้น",
        ["Sea 1 — Rock Fruit"]               = "Sea 1 — Rock Fruit",

        -- Moon Tab
        ["Auto Raid Moon"]                   = "Auto Raid Moon",
        ["Moon Raid"]                        = "Moon Raid",
        ["🌙 Auto Farm Moon"]                = "🌙 ฟาร์ม Moon อัตโนมัติ",
        ["⚔️ Attack / Skill"]                = "⚔️ โจมตี / สกิล",
        ["🗡️ Weapons"]                       = "🗡️ อาวุธ",
        ["📊 Status"]                        = "📊 สถานะ",
        ["🌍 Travel"]                        = "🌍 เดินทาง",
        ["Trạng thái: Chờ bật"]              = "สถานะ: รอเปิด",
        ["Bật toggle bên trái để farm Moon"] = "เปิดสวิตช์ด้านซ้ายเพื่อฟาร์ม Moon",
        ["🌙 Auto Farm Moon Mob"]            = "🌙 ฟาร์ม Moon อัตโนมัติ",
        ["🎯 Vị trí đánh"]                   = "🎯 ตำแหน่งโจมตี",
        ["Upper (Trên đầu)"]                 = "ด้านบน (เหนือหัว)",
        ["Below (Dưới chân)"]                = "ด้านล่าง (ใต้เท้า)",
        ["Behind (Phía sau)"]                = "ด้านหลัง",
        ["Front (Phía trước)"]               = "ด้านหน้า",
        ["📏 Khoảng cách đánh"]              = "📏 ระยะโจมตี",
        ["🗡️ Main Weapon"]                   = "🗡️ อาวุธหลัก",
        ["🗡️ Support Weapons"]               = "🗡️ อาวุธเสริม",
        ["⚔️ Auto Attack + Skill (Ưu tiên Skill)"] = "⚔️ โจมตี + สกิล อัตโนมัติ (เน้นสกิล)",
        ["Auto Skill Z"]                     = "สกิล Z อัตโนมัติ",
        ["Auto Skill X"]                     = "สกิล X อัตโนมัติ",
        ["Auto Skill C"]                     = "สกิล C อัตโนมัติ",
        ["Auto Skill V"]                     = "สกิล V อัตโนมัติ",
        ["Auto Skill F"]                     = "สกิล F อัตโนมัติ",
        ["🌍 Quay Về Trái Đất (Back Earth)"] = "🌍 กลับสู่โลก",

        -- Setting Moon
        ["⚙️ Setting"]                       = "⚙️ ตั้งค่า",
        ["Save / Load"]                      = "บันทึก / โหลด",
        ["💾 Quản Lý Save"]                  = "💾 จัดการเซฟ",
        ["📋 Thông Tin"]                     = "📋 ข้อมูล",
        ["📖 Hướng dẫn"]                     = "📖 คำแนะนำ",
        ["1. Nhập tên Save → SAVE\n2. Chọn Save từ dropdown → LOAD\n3. Xóa bằng nút 🗑️"] =
            "1. ใส่ชื่อเซฟ → บันทึก\n2. เลือกเซฟจาก dropdown → โหลด\n3. ลบด้วยปุ่ม 🗑️",
        ["📁 Save hiện có:"]                 = "📁 เซฟที่มี:",
        ["(chưa có save)"]                   = "(ยังไม่มีเซฟ)",
        ["✏️ Tên Save mới"]                  = "✏️ ชื่อเซฟใหม่",
        ["📁 Chọn Save"]                     = "📁 เลือกเซฟ",
        ["💾 SAVE"]                          = "💾 บันทึก",
        ["📂 LOAD"]                          = "📂 โหลด",
        ["🗑️ Xóa Save"]                      = "🗑️ ลบเซฟ",
        ["🔄 Làm mới danh sách"]             = "🔄 รีเฟรชรายการ",

        -- Settings Tab
        ["Settings"]                         = "ตั้งค่า",
        ["Main Settings"]                    = "ตั้งค่าหลัก",
        ["🗡️ Select Weapon"]                 = "🗡️ เลือกอาวุธ",
        ["⚔️ Auto Skills"]                   = "⚔️ สกิลอัตโนมัติ",
        ["🎯 Select Method Farm"]            = "🎯 เลือกวิธีฟาร์ม",
        ["👁️ Haki"]                          = "👁️ ฮาคิ",
        ["✨ VFX"]                            = "✨ เอฟเฟกต์",
        ["Other Settings"]                   = "ตั้งค่าอื่นๆ",
        ["🎒 Accessory & Rebirth"]           = "🎒 เครื่องประดับ & รีเบิร์ธ",
        ["🧪 Auto Use X2 Potion"]            = "🧪 ใช้ยา X2 อัตโนมัติ",
        ["Main Weapon (Attack)"]             = "อาวุธหลัก (โจมตี)",
        ["Select Support Weapon"]            = "เลือกอาวุธเสริม",
        ["ℹ️ Cơ chế"]                         = "ℹ️ กลไก",
        ["• Ưu tiên dùng Skill (Z/X/C/V/F đã bật)\n• Hết skill → tự động đánh thường\n• Chỉ cần bật 1 nút"] =
            "• ใช้สกิลก่อน (Z/X/C/V/F ที่เปิด)\n• สกิลหมด → โจมตีปกติอัตโนมัติ\n• เปิดแค่ปุ่มเดียว",
        ["Auto Enabled Haki"]                = "เปิดฮาคิอัตโนมัติ",
        ["Select Method Farm"]               = "เลือกวิธีฟาร์ม",
        ["Behind"]                           = "ด้านหลัง",
        ["Below"]                            = "ด้านล่าง",
        ["Upper"]                            = "ด้านบน",
        ["Front"]                            = "ด้านหน้า",
        ["Distance Farm"]                    = "ระยะฟาร์ม",
        ["Disable VFX"]                      = "ปิดเอฟเฟกต์",
        ["Auto Equip Best Accessory"]        = "ใส่เครื่องประดับที่ดีที่สุดอัตโนมัติ",
        ["Auto Rebirth (Max Level)"]         = "รีเบิร์ธอัตโนมัติ (เลเวลสูงสุด)",
        ["Select X2 Potion"]                 = "เลือกยา X2",
        ["Số lượng dùng (1-100)"]            = "จำนวนที่ใช้ (1-100)",
        ["🧪 USE X2 POTION (1 lần)"]         = "🧪 ใช้ยา X2 (1 ครั้ง)",

        -- Main Tab
        ["Main"]                             = "หลัก",
        ["Farm"]                             = "ฟาร์ม",
        ["Boss"]                             = "บอส",
        ["Raid Boss & Shop"]                 = "Raid บอส & ร้านค้า",
        ["Dungeon, Shop / Weapon"]           = "ดันเจี้ยน, ร้านค้า / อาวุธ",
        ["🌾 Auto Farm"]                     = "🌾 ฟาร์มอัตโนมัติ",
        ["⛏️ Auto Farm Material"]            = "⛏️ ฟาร์มวัสดุอัตโนมัติ",
        ["👹 Boss"]                          = "👹 บอส",
        ["💸 Thief"]                         = "💸 โจร",
        ["🐉 Piccolo"]                       = "🐉 Piccolo",
        ["🔍 Spawned Check"]                 = "🔍 ตรวจสอบการเกิด",
        ["🦆 Duck"]                          = "🦆 เป็ด",
        ["⛵ Devil Boat"]                    = "⛵ เรือปีศาจ",
        ["🏰 Auto Dungeon"]                  = "🏰 ดันเจี้ยนอัตโนมัติ",
        ["🏪 Shop Dungeon"]                  = "🏪 ร้านค้าดันเจี้ยน",
        ["🔨 Weapon"]                        = "🔨 อาวุธ",
        ["⚙️ Dungeon Settings"]              = "⚙️ ตั้งค่าดันเจี้ยน",
        ["📊 Shop Dungeon Info"]             = "📊 ข้อมูลร้านดันเจี้ยน",
        ["🌋 Auto Raid Moon"]                = "🌋 Raid Moon อัตโนมัติ",
        ["⚔️ Auto Raid Boss"]                = "⚔️ Raid บอสอัตโนมัติ",
        ["📋 Raid Info"]                     = "📋 ข้อมูล Raid",
        ["🏪 Shop Raid"]                     = "🏪 ร้านค้า Raid",
        ["📊 Shop Info"]                     = "📊 ข้อมูลร้านค้า",
        ["⚙️ Raid Settings"]                 = "⚙️ ตั้งค่า Raid",
        ["🎁 Time Mystery Box"]              = "🎁 กล่องปริศนาเวลา",
        ["Auto Level Farm"]                  = "ฟาร์มเลเวลอัตโนมัติ",
        ["Select Farm Material"]             = "เลือกวัสดุฟาร์ม",
        ["Auto Farm Material"]               = "ฟาร์มวัสดุอัตโนมัติ",
        ["Select Boss"]                      = "เลือกบอส",
        ["Auto Farm All Boss (Full)"]        = "ฟาร์มบอสทั้งหมด (Full)",
        ["Auto Farm Thief Chest"]            = "ฟาร์มหีบโจร",
        ["Auto Farm Piccolo"]                = "ฟาร์ม Piccolo",
        ["Auto Farm Duck (Full)"]            = "ฟาร์มเป็ด (Full)",
        ["Auto Farm Devil Boat"]             = "ฟาร์มเรือปีศาจ",
        ["Auto Farm Kraken"]                 = "ฟาร์ม Kraken",
        ["Spawn Status"]                     = "สถานะการเกิด",
        ["Item Requirements ( None )"]       = "วัสดุที่ต้องใช้ ( ว่าง )",
        ["Select Weapon Craft"]              = "เลือกอาวุธคราฟ",
        ["Craft Weapon"]                     = "คราฟอาวุธ",
        ["Auto Craft Weapon (Full)"]         = "คราฟอาวุธอัตโนมัติ (Full)",
        ["Auto Farm Set Weapon"]             = "ฟาร์มชุดอาวุธ",
        ["Auto Raid Moon (Full)"]            = "Raid Moon อัตโนมัติ (Full)",
        ["Dungeon Orb to Use"]               = "ลูกแก้วดันเจี้ยนที่ใช้",
        ["Health Return %"]                  = "เปอร์เซ็นต์ฟื้นเลือด",
        ["Dungeon Height"]                   = "ความสูงดันเจี้ยน",
        ["🏰 Auto Dungeon (Full)"]           = "🏰 ดันเจี้ยนอัตโนมัติ (Full)",
        ["Choose a boss to raid"]            = "เลือกบอสที่จะ Raid",
        ["Bacon of Grudge"]                  = "Bacon of Grudge",
        ["??? (Raid 2)"]                     = "??? (Raid 2)",
        ["??? (Raid 3)"]                     = "??? (Raid 3)",
        ["Start Raid Now!!"]                 = "เริ่ม Raid ทันที!!",
        ["Bacon of Grudge Height"]           = "ความสูง Bacon of Grudge",
        ["Golden Ball Height"]               = "ความสูงลูกบอลทอง",
        ["RaidPoint: ( đang load... )"]      = "แต้ม Raid: ( กำลังโหลด... )",
        ["Restock In: ( đang load... )"]     = "เติมสินค้าใน: ( กำลังโหลด... )",
        ["Select Items to Purchase"]         = "เลือกไอเทมที่จะซื้อ",
        ["BUY!!"]                            = "ซื้อ!!",
        ["🎁 Time Mystery Box: ---"]         = "🎁 กล่องปริศนาเวลา: ---",
        ["Nhập số lượng và bấm nút để mở"]   = "ใส่จำนวนแล้วกดปุ่มเพื่อเปิด",
        ["Số lượng mở (1-100)"]              = "จำนวนเปิด (1-100)",
        ["🎁 MỞ TIME MYSTERY BOX (1 lần)"]  = "🎁 เปิดกล่องปริศนา (1 ครั้ง)",
        ["DungeonPoint: ( đang load... )"]   = "แต้มดันเจี้ยน: ( กำลังโหลด... )",
        ["Chọn item Auto Buy ở cột trái"]    = "เลือกไอเทมซื้ออัตโนมัติที่คอลัมน์ซ้าย",
        ["Auto Buy Items"]                   = "ไอเทมซื้ออัตโนมัติ",
        ["Auto Buy"]                         = "ซื้ออัตโนมัติ",

        -- Other Tab
        ["Other"]                            = "อื่นๆ",
        ["Sell Item / Status"]               = "ขายไอเทม / สถานะ",
        ["Random Chest"]                     = "หีบสุ่ม",
        ["Craft Table"]                      = "โต๊ะคราฟ",
        ["Npc Goku Gods"]                    = "NPC Goku Gods",
        ["💰 Auto Sell"]                     = "💰 ขายอัตโนมัติ",
        ["💎 Diamond Chest"]                 = "💎 หีบเพชร",
        ["🌙 Moon Chest"]                    = "🌙 หีบ Moon",
        ["🎖️ Guarantee Gem Point"]          = "🎖️ แต้มรับประกันเพชร",
        ["☄️ Guarantee Moon Point"]          = "☄️ แต้มรับประกัน Moon",
        ["🔨 Craft Table"]                   = "🔨 โต๊ะคราฟ",
        ["📊 Trạng Thái"]                    = "📊 สถานะ",
        ["📋 Craft Info"]                    = "📋 ข้อมูลคราฟ",
        ["📍 NPC Đang Có"]                   = "📍 NPC ที่มี",
        ["⚙️ Actions"]                       = "⚙️ การกระทำ",
        ["Select Sell Item"]                 = "เลือกไอเทมขาย",
        ["Auto Sell"]                        = "ขายอัตโนมัติ",
        ["Status Amount"]                    = "จำนวนสถานะ",
        ["Auto Up Melee"]                    = "อัป Melee อัตโนมัติ",
        ["Auto Up Defense"]                  = "อัป Defense อัตโนมัติ",
        ["Auto Up Sword"]                    = "อัป Sword อัตโนมัติ",
        ["Auto Up Power"]                    = "อัป Power อัตโนมัติ",
        ["Select Random Diamond Chest"]      = "เลือกหีบเพชรสุ่ม",
        ["🎲 Mở 1 lần (Random Item)"]        = "🎲 เปิด 1 ครั้ง (ไอเทมสุ่ม)",
        ["Auto Random Diamond Chest"]        = "เปิดหีบเพชรอัตโนมัติ",
        ["Select Random Moon Chest"]         = "เลือกหีบ Moon สุ่ม",
        ["🌙 Mở 1 lần (Event Moon)"]         = "🌙 เปิด 1 ครั้ง (อีเวนต์ Moon)",
        ["Auto Random Moon Chest"]           = "เปิดหีบ Moon อัตโนมัติ",
        ["Select Guarantee Diamond Point"]   = "เลือกแต้มรับประกันเพชร",
        ["💎 MUA 1 lần"]                     = "💎 ซื้อ 1 ครั้ง",
        ["Auto Buy Guarantee Diamond"]       = "ซื้อรับประกันเพชรอัตโนมัติ",
        ["Select Guarantee Moon Point"]      = "เลือกแต้มรับประกัน Moon",
        ["🌙 MUA 1 lần"]                     = "🌙 ซื้อ 1 ครั้ง",
        ["Auto Buy Guarantee Moon"]          = "ซื้อรับประกัน Moon อัตโนมัติ",
        ["Chọn Items để chế tạo"]            = "เลือกไอเทมที่จะคราฟ",
        ["🔨 Auto Chế Tạo"]                  = "🔨 คราฟอัตโนมัติ",
        ["✅ Auto Claim Guarantee (Ưu tiên cao)"] = "✅ รับประกันอัตโนมัติ (สำคัญสูง)",
        ["⏱️ Tốc độ hiện tại: 2.00s/lần"]   = "⏱️ ความเร็วปัจจุบัน: 2.00s/ครั้ง",
        ["🟢 Rất an toàn"]                   = "🟢 ปลอดภัยมาก",
        ["🟢 An toàn (0.5s)"]                = "🟢 ปลอดภัย (0.5s)",
        ["🟢 Rất an toàn (1.0s)"]            = "🟢 ปลอดภัยมาก (1.0s)",
        ["🟢 Cực an toàn (2.0s)"]            = "🟢 ปลอดภัยสุดๆ (2.0s)",
        ["🔵 Siêu chậm (5.0s)"]              = "🔵 ช้ามาก (5.0s)",
        ["📖 Hướng dẫn tốc độ"]              = "📖 คำแนะนำความเร็ว",
        ["🟢 0.5-1.0s: An toàn (khuyến nghị)\n🟢 1.0-2.0s: Rất an toàn\n🟢 2.0-5.0s: Cực an toàn\n🔵 5.0s+: Chỉ dùng khi ping cao\n\n💡 Nếu vẫn phí → chọn mức 2.0s hoặc 5.0s"] =
            "🟢 0.5-1.0s: ปลอดภัย (แนะนำ)\n🟢 1.0-2.0s: ปลอดภัยมาก\n🟢 2.0-5.0s: ปลอดภัยสุดๆ\n🔵 5.0s+: ใช้เมื่อ ping สูงเท่านั้น\n\n💡 ถ้ายังเสียเปล่า → เลือก 2.0s หรือ 5.0s",
        ["🎯 Auto Find & Click NPC"]         = "🎯 หา & คลิก NPC อัตโนมัติ",
        ["✈️ Auto TP Nearest NPC"]           = "✈️ TP ไป NPC ใกล้สุดอัตโนมัติ",
        ["Npc Count: 0 / 5"]                 = "จำนวน NPC: 0 / 5",
        ["Đang tìm NPC..."]                  = "กำลังหา NPC...",

        -- Teleport Tab
        ["Teleport"]                         = "วาร์ป",
        ["Teleport Sea 1"]                   = "วาร์ป Sea 1",
        ["🏝️ Đảo Sea 1"]                     = "🏝️ เกาะ Sea 1",
        ["🌊 Sea Travel"]                    = "🌊 เดินทางทะเล",
        ["📊 Thông Tin"]                     = "📊 ข้อมูล",
        ["🏝️ Chọn Đảo Sea 1"]                = "🏝️ เลือกเกาะ Sea 1",
        ["✈️ Dịch Chuyển Tới Đảo"]           = "✈️ วาร์ปไปเกาะ",
        ["🌊 Đi Tới Sea 2 (2SeaSoon)"]       = "🌊 ไป Sea 2 (2SeaSoon)",
        ["Đang load..."]                     = "กำลังโหลด...",
        ["Sea"]                              = "ทะเล",

        -- Config Tab
        ["Config"]                           = "ตั้งค่า",

        -- ===== NOTIFY / DYNAMIC MESSAGES =====
        ["Chưa chọn đảo"]                    = "ยังไม่เลือกเกาะ",
        ["Chọn 1 đảo trước!"]                = "เลือกเกาะก่อน!",
        ["Không có nhân vật"]                = "ไม่มีตัวละคร",
        ["Character chưa load"]              = "ตัวละครยังไม่โหลด",
        ["Không tìm thấy NPC"]               = "ไม่พบ NPC",
        ["BackEarth không tồn tại"]          = "BackEarth ไม่มีอยู่",
        ["Không có prompt"]                  = "ไม่มี prompt",
        ["Đã kích hoạt"]                     = "เปิดใช้งานแล้ว",
        ["Đang chờ chuyển map..."]           = "กำลังรอเปลี่ยนแมพ...",
        ["Đã lưu"]                           = "บันทึกแล้ว",
        ["Lỗi lưu"]                          = "บันทึกผิดพลาด",
        ["Tên save trống"]                   = "ชื่อเซฟว่าง",
        ["Nhập tên trước!"]                  = "ใส่ชื่อก่อน!",
        ["Không tìm thấy"]                   = "ไม่พบ",
        ["Lỗi đọc file"]                     = "อ่านไฟล์ผิดพลาด",
        ["Đã load"]                          = "โหลดแล้ว",
        ["Chọn save trước!"]                 = "เลือกเซฟก่อน!",
        ["Chưa nhập tên"]                    = "ยังไม่ใส่ชื่อ",
        ["Nhập tên save!"]                   = "ใส่ชื่อเซฟ!",
        ["Chưa có save"]                     = "ยังไม่มีเซฟ",
        ["Chưa có file save nào!"]           = "ยังไม่มีไฟล์เซฟ!",
        ["Nhắc nhở"]                         = "เตือน",
        ["Tắt/Bật Auto Farm để áp dụng"]     = "ปิด/เปิด Auto Farm เพื่อใช้งาน",
        ["Chưa chọn Save"]                   = "ยังไม่เลือกเซฟ",
        ["Chưa có save để xóa!"]             = "ไม่มีเซฟที่จะลบ!",
        ["Đã xóa"]                           = "ลบแล้ว",
        ["Không có"]                         = "ไม่มี",
        ["Đã làm mới"]                       = "รีเฟรชแล้ว",
        ["Danh sách save"]                   = "รายการเซฟ",
        ["Chưa chọn Potion"]                 = "ยังไม่เลือกยา",
        ["Chọn 1 loại X2 Potion trước!"]     = "เลือกยา X2 ก่อน!",
        ["Không có Potion"]                  = "ไม่มียา",
        ["Không tìm thấy Remote"]            = "ไม่พบ Remote",
        ["Remotes.Inventory"]                = "Remotes.Inventory",
        ["Đang dùng Potion"]                 = "กำลังใช้ยา",
        ["có"]                               = "มี",
        ["Raid not selected"]                = "ยังไม่เลือก Raid",
        ["Please choose a Boss Raid!"]       = "กรุณาเลือก Boss Raid!",
        ["Raid không hợp lệ"]                = "Raid ไม่ถูกต้อง",
        ["NO RAID!!!"]                       = "ไม่ RAID!!!",
        ["Start Raid"]                       = "เริ่ม Raid",
        ["Stop Raid"]                        = "หยุด Raid",
        ["Chưa chọn item"]                   = "ยังไม่เลือกไอเทม",
        ["Vui lòng chọn item trước!"]        = "กรุณาเลือกไอเทมก่อน!",
        ["Đã mua"]                           = "ซื้อแล้ว",
        ["Không có Box"]                     = "ไม่มีกล่อง",
        ["Time Mystery Box (0)"]             = "กล่องปริศนาเวลา (0)",
        ["NetworkEvent không tồn tại"]       = "NetworkEvent ไม่มีอยู่",
        ["Đang mở Box"]                      = "กำลังเปิดกล่อง",
        ["Mở"]                               = "เปิด",
        ["box"]                              = "กล่อง",
        ["Còn lại"]                          = "เหลือ",
        ["Lỗi fire"]                         = "Fire ผิดพลาด",
        ["Không mở được box"]                = "เปิดกล่องไม่ได้",
        ["Chọn item Auto Buy trước!"]        = "เลือกไอเทมซื้ออัตโนมัติก่อน!",
        ["Bật Auto Buy"]                     = "เปิดซื้ออัตโนมัติ",
        ["Tắt Auto Buy"]                     = "ปิดซื้ออัตโนมัติ",
        ["Đổi tốc độ"]                       = "เปลี่ยนความเร็ว",
        ["An toàn"]                          = "ปลอดภัย",
        ["Rất an toàn"]                      = "ปลอดภัยมาก",
        ["Cực an toàn"]                      = "ปลอดภัยสุดๆ",
        ["Siêu chậm"]                        = "ช้ามาก",
        ["Anti-cheat"]                       = "แอนตี้ชีท",
        ["Đã tắt Auto Farm. Đợi 30s!"]       = "ปิด Auto Farm แล้ว รอ 30 วินาที!",
        ["Thiếu Class"]                      = "ขาด Class",
        ["Bạn cần class này để craft"]       = "คุณต้องมี class นี้เพื่อคราฟ",
        ["Thiếu Beli"]                       = "ขาด Beli",
        ["Cần"]                              = "ต้องการ",
        ["Thiếu Materials"]                  = "ขาดวัสดุ",
        ["Chưa chọn Weapon"]                 = "ยังไม่เลือกอาวุธ",
        ["Chọn weapon trong dropdown trước!"]= "เลือกอาวุธใน dropdown ก่อน!",
        ["Hết Orb Boss"]                     = "Orb Boss หมด",
        ["Đã tắt Auto Farm Boss (Full)!"]    = "ปิด Auto Farm Boss (Full) แล้ว!",
        ["Thiếu Duck Items"]                 = "ขาดไอเทมเป็ด",
        ["Không đủ Portal Gun"]              = "Portal Gun ไม่พอ",
        ["Portal Gun!"]                      = "Portal Gun!",
        ["Không đủ MoonStone"]               = "MoonStone ไม่พอ",
        ["Đã mở"]                            = "เปิดแล้ว",
        ["Không đủ PointItem"]               = "PointItem ไม่พอ",
        ["Không đủ MoonPoint"]               = "MoonPoint ไม่พอ",
        ["Không tìm thấy NPC Sea 2"]         = "ไม่พบ NPC Sea 2",
        ["workspace.2SeaSoon không có"]      = "workspace.2SeaSoon ไม่มี",
        ["Đã tới NPC Sea 2"]                 = "ถึง NPC Sea 2 แล้ว",
        ["Chờ game chuyển Sea..."]           = "รอเกมเปลี่ยน Sea...",
        ["Bật Auto Goku"]                    = "เปิด Auto Goku",
        ["Tắt Auto Goku"]                    = "ปิด Auto Goku",
        ["Tự động tìm + click"]              = "หา + คลิกอัตโนมัติ",
        ["Bật Auto TP"]                      = "เปิด Auto TP",
        ["Tắt Auto TP"]                      = "ปิด Auto TP",
        ["TP tới NPC gần nhất"]              = "TP ไป NPC ใกล้สุด",
        ["Reset phiên NPC"]                  = "รีเซ็ตเซสชัน NPC",
        ["Đã đủ 5 NPC"]                      = "NPC ครบ 5 แล้ว",
        ["Đủ 5 NPC — reset phiên"]           = "NPC ครบ 5 — รีเซ็ตเซสชัน",
        ["NPC Spawn!"]                       = "NPC เกิด!",
        ["NPC Respawn!"]                     = "NPC เกิดใหม่!",
        ["quay lại!"]                        = "กลับมา!",

        -- Dynamic notify parts
        ["Đã chọn"]                          = "เลือกแล้ว",
        ["bấm BUY để mua"]                   = "กดซื้อเพื่อซื้อ",
        ["bật Toggle Auto Buy"]              = "เปิด Toggle Auto Buy",
        ["Đợi chọn item"]                    = "รอเลือกไอเทม",
        ["Chọn item để bắt đầu"]             = "เลือกไอเทมเพื่อเริ่ม",
        ["Chưa chọn Item"]                   = "ยังไม่เลือกไอเทม",
        ["Không tìm thấy Item"]              = "ไม่พบไอเทม",
        ["Không có công thức"]               = "ไม่มีสูตร",
        ["Công thức:"]                       = "สูตร:",
        ["Có thể chế:"]                      = "คราฟได้:",
        ["lần"]                              = "ครั้ง",
        ["Số lần có thể chế: ---"]           = "จำนวนที่คราฟได้: ---",
        ["Guarantee: ---/---"]               = "รับประกัน: ---/---",
        ["ĐANG CHẾ TẠO"]                     = "กำลังคราฟ",
        ["Đợi:"]                             = "รอ:",
        ["CHỜ CLAIM GUARANTEE"]              = "รอรับประกัน",
        ["Đợi server..."]                    = "รอเซิร์ฟเวอร์...",
        ["Đang chờ"]                         = "กำลังรอ",
        ["ĐÃ ĐẦY — Đang claim..."]           = "เต็มแล้ว — กำลังรับ...",
        ["Còn"]                              = "เหลือ",
        ["slot trống"]                       = "ช่องว่าง",
        ["Chưa có item nào"]                 = "ยังไม่มีไอเทม",
        ["Guarantee:"]                       = "รับประกัน:",

        -- Info / Paragraph dynamic
        ["Trạng thái: ĐANG FARM"]            = "สถานะ: กำลังฟาร์ม",
        ["Trạng thái: Đã tắt"]               = "สถานะ: ปิดแล้ว",
        ["Đang tìm mob..."]                  = "กำลังหามอน...",
        ["Bật lại để tiếp tục"]              = "เปิดอีกครั้งเพื่อดำเนินต่อ",
        ["Chờ mob..."]                       = "รอมอน...",
        ["Đứng tại cửa hang đợi mob"]        = "ยืนที่ปากถ้ำรอมอน",
        ["ĐANG ĐÁNH"]                        = "กำลังโจมตี",
        ["BẢO VỆ ROCKETTOWER"]               = "ปกป้อง ROCKETTOWER",
        ["Đảo:"]                             = "เกาะ:",
        ["Name:"]                            = "ชื่อ:",
        ["( chưa chọn )"]                    = "( ยังไม่เลือก )",
        ["Please choose a Boss Raid!!"]      = "กรุณาเลือก Boss Raid!!",
        ["Reward:"]                          = "รางวัล:",
        ["Giá:"]                             = "ราคา:",
        ["Đủ mua"]                           = "ซื้อได้",
        ["Thiếu"]                            = "ขาด",
        ["Item: (chưa chọn)"]                = "ไอเทม: (ยังไม่เลือก)",
        ["Số lượng mở:"]                     = "จำนวนเปิด:",
        ["Có thể mở:"]                       = "เปิดได้:",
        ["Phiên:"]                           = "เซสชัน:",
        ["Đang có mặt:"]                     = "มีอยู่:",
        ["Không có NPC nào"]                 = "ไม่มี NPC",
        ["Npc Count:"]                       = "จำนวน NPC:",
        ["studs"]                            = "studs",
        ["đã"]                               = "แล้ว",
		["Time Mystery Box x5, 7500 Diamond, Beli 50M, x3 Potion"] = "กล่องปริศนาเวลา x5, เพชร 7500, Beli 50M, ยา x3",
    }
}

local function T(key)
    if type(key) ~= "string" then return key end
    if _G.Language == "vi" and TRANSLATIONS.vi and TRANSLATIONS.vi[key] then
        return TRANSLATIONS.vi[key]
    end
    if _G.Language == "th" and TRANSLATIONS.th and TRANSLATIONS.th[key] then
        return TRANSLATIONS.th[key]
    end
    if _G.Language == "en" and TRANSLATIONS.en and TRANSLATIONS.en[key] then
        return TRANSLATIONS.en[key]
    end
    return key
end

-- ============================================================
-- SERVICES & MODULES (SAFE LOAD)
-- ============================================================
local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local HttpService         = game:GetService("HttpService")
local RunService          = game:GetService("RunService")
local VirtualUser         = game:GetService("VirtualUser")
local GuiService          = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer         = Players.LocalPlayer

local function SafeWait(parent, name, timeout)
    local ok, result = pcall(function()
        return parent:WaitForChild(name, timeout or 3)
    end)
    if ok and result then return result end
    return parent:FindFirstChild(name)
end

local function SafeRequire(module)
    if not module then return nil end
    local ok, result = pcall(function() return require(module) end)
    if ok and result then return result end
    return nil
end

local Npc_Quest = SafeWait(workspace, "NpcQuest", 3)
local Itemdrops = SafeWait(workspace, "Itemdrops", 3)

local ModulesFolder = SafeWait(ReplicatedStorage, "Modules", 3)

local UseItems        = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("UseItems"))
local CraftingTable   = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("CraftingTable"))
local Quest_Module    = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("QuestModule"))
local ItemList        = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("Itemlist"))
local SpawnBossList   = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("SpawnBossList"))
local Blacklist       = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("BlacklistItemTrade"))
local AccessoryModule = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("AccessoryModule"))
local PointItemM      = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("GaranteeRandomItem"))
local PointItemMoon   = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("GaranteeEventMoon"))
local Economy         = SafeRequire(ModulesFolder and ModulesFolder:FindFirstChild("Economy"))

local missingModules = {}
for name, mod in pairs({
    UseItems = UseItems, CraftingTable = CraftingTable, Quest_Module = Quest_Module,
    ItemList = ItemList, SpawnBossList = SpawnBossList, Blacklist = Blacklist,
    AccessoryModule = AccessoryModule, PointItemM = PointItemM,
    PointItemMoon = PointItemMoon, Economy = Economy
}) do
    if not mod then table.insert(missingModules, name) end
end
if #missingModules > 0 then
    warn("[Sea 1] ⚠️ Module thiếu: " .. table.concat(missingModules, ", "))
end

-- ============================================================
-- CONFIG & GLOBALS
-- ============================================================
local TypeTool         = {"Melee", "Sword", "Special", "DevilFruit"}
local RandomChestValue = {"x5", "x10", "x15"}

local Quest_List, WeaponAll, MonsterDrop = {}, {}, {}
local ItemDrop, ItemToMob, ItemAll        = {}, {}, {}
local X2List, Poitem, PoiteMoon, SellItems, Bosses = {}, {}, {}, {}, {}
local CachedInventory = {}
local LastCraft, CraftDelay, LastInventory = 0, 1, 0
local NotifyCraft     = false
local MethodFarm      = CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-90), 0, 0)

local SpawnList = {
    ["Thief"]      = "Bacon Thief",
    ["Piccolo"]    = "Piccolo",
    ["Duck"]       = "Duck Monster",
    ["Devil Boat"] = "Devil Boat",
    ["Kraken"]     = "Kraken"
}

_G.SmoothUpperBelow              = true
_G.AutoCombat                    = false
_G.CanAutoSkill                  = false
_G.MainWeapon                    = "Melee"
_G.Select_EquipWeapon            = {}
_G.Select_Method                 = "Upper"
_G.Distance_Farm                 = 5
_G.AutoSkillZ, _G.AutoSkillX     = false, false
_G.AutoSkillC, _G.AutoSkillV     = false, false
_G.AutoSkillF, _G.Auto_Haki      = false, false
_G.Auto_Equip_Accessory          = false
_G.Auto_Rebirth                  = false
_G.Select_Potion                 = ""
_G.PotionAmount                  = 1
_G.Auto_Use_Potion               = false
_G.Auto_Farm_Level               = false
_G.Select_Material               = {}
_G.Auto_Farm_Material            = false
_G.Select_Boss                   = nil
_G.Auto_FarmBoss                 = false
_G.Auto_FarmBoss_Automatically   = false
_G.Auto_BaconThief               = false
_G.Auto_Piccolo                  = false
_G.Auto_Duck                     = false
_G.Auto_DevilBoat                = false
_G.Auto_DuckAutomatically        = false
_G.Select_Item                   = nil
_G.Auto_CraftWeapon              = false
_G.Auto_Farm_Set                 = false
_G.Auto_Raid                     = false
_G.Dungeon_UseValue              = 1
_G.HealthPercent                 = 30
_G.Auto_Dungeon                  = false
_G.Select_SellItem               = {}
_G.Auto_SellItem                 = false
_G.Amount                        = 1000
_G.AutoMelee, _G.AutoDefense     = false, false
_G.AutoSword, _G.AutoPower       = false, false
_G.Select_Random                 = "x5"
_G.Auto_RandomChest              = false
_G.Select_Random_Moon            = "x5"
_G.Auto_RandomChest_Moon         = false
_G.Select_Guarantee              = nil
_G.Auto_Guarantee                = false
_G.Select_Guarantee_Moon         = nil
_G.Auto_Guarantee_Moon           = false
_G.RaidBossOffsetY               = 55
_G.RaidBallOffsetY               = 25
_G.DungeonHeight                 = 25
_G.VFXDisabled                   = false
_G.RaidAutoAttack                = false
_G.RaidAutoSkill                 = false
_G.Auto_Kraken                   = false
_G.TimeMysteryAmount             = 1

-- ============================================================
-- BUILD DANH SÁCH
-- ============================================================
if Economy then
    for ItemName in pairs(Economy) do table.insert(SellItems, ItemName) end
    table.sort(SellItems)
end

if PointItemM then
    for Item, Price in pairs(PointItemM) do
        table.insert(Poitem, {Name = Item, Price = Price})
    end
    table.sort(Poitem, function(a, b) return a.Price < b.Price end)
    for i, Data in ipairs(Poitem) do Poitem[i] = Data.Name .. " / " .. Data.Price .. " Point" end
end

if PointItemMoon then
    for Item, Price in pairs(PointItemMoon) do
        table.insert(PoiteMoon, {Name = Item, Price = Price})
    end
    table.sort(PoiteMoon, function(a, b) return a.Price < b.Price end)
    for i, Data in ipairs(PoiteMoon) do PoiteMoon[i] = Data.Name .. " / " .. Data.Price .. " Point" end
end

if Quest_Module and Npc_Quest then
    pcall(function()
        table.sort(Quest_Module, function(a, b) return a.Level < b.Level end)
        for i, data in ipairs(Quest_Module) do
            local NPC = Npc_Quest:WaitForChild("NPC_Quest" .. i, 2)
            if NPC then
                Quest_List[i] = {Level = data.Level, Monster = NPC:GetAttribute("Name"), Quest = NPC}
            end
        end
    end)
end

if UseItems then
    for Weapon in pairs(UseItems) do table.insert(WeaponAll, Weapon) end
    table.sort(WeaponAll)
end

if Blacklist then
    for ItemName in pairs(Blacklist) do
        if ItemName:find("X2") then table.insert(X2List, ItemName) end
    end
end

if Itemdrops then
    pcall(function()
        for _, Mob in ipairs(Itemdrops:GetChildren()) do
            local ScrollingFrame = Mob:FindFirstChild("ScrollingFrame", true)
            if ScrollingFrame then
                MonsterDrop[Mob.Name] = {}
                for _, v in ipairs(ScrollingFrame:GetDescendants()) do
                    if v:IsA("TextLabel") and v.Text and v.Text ~= "" then
                        if not v.Text:find("%%") then
                            MonsterDrop[Mob.Name][v.Text] = true
                            ItemDrop[v.Text] = ItemDrop[v.Text] or {}
                            table.insert(ItemDrop[v.Text], Mob.Name)
                            ItemToMob[v.Text] = Mob.Name
                        end
                    end
                end
            end
        end
    end)

    local dropCount = 0
    for _ in pairs(ItemDrop) do dropCount = dropCount + 1 end
end

if ItemList then
    for ItemName in pairs(ItemToMob) do
        local Data = ItemList[ItemName]
        if not (Data and Data.Type == "Accessory") then table.insert(ItemAll, ItemName) end
    end
    table.sort(ItemAll)
end

if SpawnBossList then
    for BossName in pairs(SpawnBossList) do table.insert(Bosses, BossName) end
    table.sort(Bosses)
end

if #Bosses == 0 then
    Bosses = {"Bacon Thief", "Piccolo", "Duck Monster", "Devil Boat"}
end

if #WeaponAll == 0 then
    WeaponAll = {"Melee", "Sword", "Special", "DevilFruit"}
end

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================
local function GetQuest_Level(My_level)
    local Quest
    for _, v in ipairs(Quest_List) do
        if My_level >= v.Level then Quest = v else break end
    end
    return Quest
end

local function GetQuestFrame()
    return LocalPlayer.PlayerGui.HUD.Main.Frame_Quest
end

local function GetInventory()
    if tick() - LastInventory < 0.2 then return CachedInventory end
    LastInventory = tick()
    local Success, Inv = pcall(function()
        return HttpService:JSONDecode(LocalPlayer:GetAttribute("Inventory") or "{}")
    end)
    CachedInventory = Success and Inv or {}
    return CachedInventory
end

local function GetItemAmount(ItemName)
    local Inv = GetInventory()
    return (Inv[ItemName] and Inv[ItemName].amount) or 0
end

local function Teleport(Pos)
    local char = LocalPlayer.Character
    if char then char:PivotTo(Pos) end
end

-- ============================================================
-- LOAD UI
-- ============================================================
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Ui_New.lua"
))()
local MySaveManager = Library.SaveManager

local MOON_PLACE_ID = 82878101790702
local IS_MOON_MAP   = (game.PlaceId == MOON_PLACE_ID)

local Window = Library:CreateWindow({
    Title = "MarvenRiz Hub" .. (IS_MOON_MAP and " (Moon)" or ""),
    Subtitle = IS_MOON_MAP and T("Auto Raid Moon Only") or T("Sea 1 — Rock Fruit"),
    Size = UDim2.fromOffset(500, 370),
    AccentColor = Color3.fromRGB(50, 150, 255),
    SideBarWidth = 120,
    Logo = "rbxassetid://87526284179554",
    LogoSize = 32,
    SphereText = false,
    SphereImage = "rbxassetid://87526284179554",
    SphereIconSize = 38,
    Map = "RockFruit"
})

-- 🆕 Đăng ký SavedLanguage vào ConfigElements để lưu ngôn ngữ
task.spawn(function()
    task.wait(0.5)
    if Window and Window.ConfigElements then
        Window.ConfigElements["SavedLanguage"] = {
            Set = function(v)
                if type(v) == "string" and (v == "vi" or v == "en" or v == "th") then
                    _G.SavedLanguage = v
                end
            end,
            Get = function()
                return _G.SavedLanguage or _G.Language or "en"
            end
        }
    end
end)

function _G.SeaNotify(title, desc, duration)
    pcall(function()
        if Library and Library.Notify then
            Library:Notify({Title = title or "", Description = desc or "", Duration = duration or 4})
        end
    end)
end

-- ============================================================
-- 🌙 MOON MAP UI — v86
-- ============================================================
if IS_MOON_MAP then

    local MoonTab    = Window:CreateTab(T("Auto Raid Moon"), true, false)
    local MoonPage   = MoonTab:CreatePage(T("Moon Raid"))
    local MoonFarm   = MoonPage:CreateSection(T("🌙 Auto Farm Moon"), "Left")
    local MoonSkills = MoonPage:CreateSection(T("⚔️ Attack / Skill"), "Right")
    local MoonWeapon = MoonPage:CreateSection(T("🗡️ Weapons"), "Left")
    local MoonInfo   = MoonPage:CreateSection(T("📊 Status"), "Right")
    local MoonTravel = MoonPage:CreateSection(T("🌍 Travel"), "Left")

    local MoonStatusPara = MoonInfo:Paragraph({
        Title = T("Trạng thái: Chờ bật"),
        Content = T("Bật toggle bên trái để farm Moon")
    })

    local MoonRunning       = false
    local MoonLastRunning   = false
    local MoonLastAttack    = 0
    local MoonLastSkill     = 0
    local MoonLastEquip     = 0
    local MoonCurrentTarget = nil
    local MoonSettleTime    = 0
    local MoonLastAction    = 0
    local MoonAtCave        = false
    local MoonJitterSeed    = 0

    local MoonLastMobHealth    = 0
    local MoonDamageCheckTime  = 0
    local MoonStuckCount       = 0
    local MoonLastStuckTime    = 0
    local MOON_STUCK_THRESHOLD = 5
    local MOON_STUCK_MAX       = 5
    local MOON_STUCK_COOLDOWN  = 3

    local MOON_SETTLE_DELAY = 0.15
    local MOON_WATCHDOG     = 2.0

    _G.MoonHitPosition = "Upper"
    _G.MoonHitDistance = 12

    local MoonRocketTower     = nil
    local MoonRocketPos       = nil
    local MoonRocketLastCheck = 0
    local MOON_ROCKET_CACHE   = 15

    local CAVE_POS = Vector3.new(-195, 14, 412)
    local MOON_SAVE_FOLDER = "MarvenRiz_Moon"

    local function EnsureFolder()
        if not isfolder(MOON_SAVE_FOLDER) then
            pcall(function() makefolder(MOON_SAVE_FOLDER) end)
        end
    end

    local function GetSavePath(name)
        return MOON_SAVE_FOLDER .. "/" .. name .. ".json"
    end

    local function GetSaveList()
        local list = {}
        if not isfolder(MOON_SAVE_FOLDER) then return list end

        local ok, files = pcall(function() return listfiles(MOON_SAVE_FOLDER) end)
        if not ok or type(files) ~= "table" then return list end

        for _, file in ipairs(files) do
            local name = tostring(file):match("([^/\\]+)%.json$")
            if name and not name:find("^_") then
                table.insert(list, name)
            end
        end
        table.sort(list)
        return list
    end

    local function AsString(v)
        if type(v) == "string" then return v end
        if type(v) == "table" then
            for _, item in pairs(v) do
                if type(item) == "string" then return item end
            end
        end
        return nil
    end

    local function AsStringList(v)
        local list = {}
        if type(v) == "string" then
            table.insert(list, v)
        elseif type(v) == "table" then
            for _, item in pairs(v) do
                if type(item) == "string" then
                    table.insert(list, item)
                end
            end
        end
        return list
    end

    local SaveMoonSetting, LoadMoonSetting

    SaveMoonSetting = function(name)
        if not name or name == "" then
            _G.SeaNotify("❌ " .. T("Tên save trống"), T("Nhập tên trước!"), 3)
            return
        end

        EnsureFolder()

        local mainWeapon  = AsString(_G.MainWeapon) or "Melee"
        local supportList = AsStringList(_G.Select_EquipWeapon)

        local cleanSupport = {}
        local seen = {}
        for _, v in ipairs(supportList) do
            if v ~= mainWeapon and not seen[v] then
                seen[v] = true
                table.insert(cleanSupport, v)
            end
        end

        local data = {
            HitPosition    = AsString(_G.MoonHitPosition) or "Upper",
            HitDistance    = tonumber(_G.MoonHitDistance) or 12,
            MainWeapon     = mainWeapon,
            SupportWeapons = cleanSupport,
            RaidAutoAttack = _G.RaidAutoAttack and true or false,
            RaidAutoSkill  = _G.RaidAutoSkill and true or false,
            AutoSkillZ     = _G.AutoSkillZ and true or false,
            AutoSkillX     = _G.AutoSkillX and true or false,
            AutoSkillC     = _G.AutoSkillC and true or false,
            AutoSkillV     = _G.AutoSkillV and true or false,
            AutoSkillF     = _G.AutoSkillF and true or false,
        }

        local ok, err = pcall(function()
            writefile(GetSavePath(name), HttpService:JSONEncode(data))
        end)

        if ok then
            _G.SeaNotify("✅ " .. T("Đã lưu"), "Save: " .. name, 3)
        else
            _G.SeaNotify("❌ " .. T("Lỗi lưu"), tostring(err), 4)
        end
    end

    LoadMoonSetting = function(name)
        if not name or name == "" then
            _G.SeaNotify("❌ " .. T("Tên save trống"), T("Chọn save trước!"), 3)
            return false
        end

        if not isfile(GetSavePath(name)) then
            _G.SeaNotify("❌ " .. T("Không tìm thấy"), "Save: " .. name, 3)
            return false
        end

        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(GetSavePath(name)))
        end)

        if not ok or type(data) ~= "table" then
            _G.SeaNotify("❌ " .. T("Lỗi đọc file"), name, 3)
            return false
        end

        _G.MoonHitPosition    = AsString(data.HitPosition) or "Upper"
        _G.MoonHitDistance    = tonumber(data.HitDistance) or 12
        _G.MainWeapon         = AsString(data.MainWeapon) or "Melee"
        _G.Select_EquipWeapon = AsStringList(data.SupportWeapons)
        _G.RaidAutoAttack     = data.RaidAutoAttack and true or false
        _G.RaidAutoSkill      = data.RaidAutoSkill and true or false
        _G.AutoSkillZ         = data.AutoSkillZ and true or false
        _G.AutoSkillX         = data.AutoSkillX and true or false
        _G.AutoSkillC         = data.AutoSkillC and true or false
        _G.AutoSkillV         = data.AutoSkillV and true or false
        _G.AutoSkillF         = data.AutoSkillF and true or false

        _G.SeaNotify("✅ " .. T("Đã load"), "Save: " .. name, 3)
        return true
    end

    local function FindRocketTower()
        if MoonRocketTower and MoonRocketTower.Parent and MoonRocketPos then
            if tick() - MoonRocketLastCheck < MOON_ROCKET_CACHE then
                return MoonRocketPos
            end
        end

        local rocket = workspace:FindFirstChild("island")
        if rocket then rocket = rocket:FindFirstChild("Moon") end
        if rocket then rocket = rocket:FindFirstChild("RocketTower") end

        if not rocket then return nil end

        local pos
        if rocket:IsA("Model") then
            local part = rocket:FindFirstChild("HumanoidRootPart")
                or rocket.PrimaryPart
                or rocket:FindFirstChildWhichIsA("BasePart")
            if part then pos = part.Position end
        elseif rocket:IsA("BasePart") then
            pos = rocket.Position
        end

        if pos then
            MoonRocketTower     = rocket
            MoonRocketPos       = pos
            MoonRocketLastCheck = tick()
            return pos
        end
        return nil
    end

    local function GetMobFolder()
        return workspace:FindFirstChild("Mob") or workspace:FindFirstChild("Mobs")
    end

    local function IsMobValid(mob)
        if not mob or not mob.Parent then return false end
        if not mob:IsA("Model") then return false end
        local hum = mob:FindFirstChild("Humanoid")
        local hrp = mob:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return false end
        if hum.Health <= 0 or hum.MaxHealth <= 0 then return false end
        return true
    end

    local function GetMoonTarget()
        local char = LocalPlayer.Character
        local myHrp = char and char:FindFirstChild("HumanoidRootPart")
        if not myHrp then return nil end

        local mobFolder = GetMobFolder()
        if not mobFolder then return nil end

        if MoonCurrentTarget and MoonCurrentTarget.Parent then
            local h = MoonCurrentTarget:FindFirstChild("Humanoid")
            if h and h.Health > 0 and h.MaxHealth > 0 then
                return MoonCurrentTarget, "🎯 " .. T("ĐANG ĐÁNH")
            end
            MoonCurrentTarget = nil
        end

        local basePos = FindRocketTower()
        local bestTarget, bestDist = nil, math.huge

        for _, mob in ipairs(mobFolder:GetChildren()) do
            if IsMobValid(mob) then
                local mPos = mob.HumanoidRootPart.Position
                if basePos then
                    local d = (basePos - mPos).Magnitude
                    if d < bestDist then
                        bestDist   = d
                        bestTarget = mob
                    end
                end
            end
        end

        if not bestTarget then
            local minPDist = math.huge
            for _, mob in ipairs(mobFolder:GetChildren()) do
                if IsMobValid(mob) then
                    local dp = (myHrp.Position - mob.HumanoidRootPart.Position).Magnitude
                    if dp < minPDist then
                        minPDist   = dp
                        bestTarget = mob
                    end
                end
            end
        end

        return bestTarget, bestTarget and ("🎯 " .. T("BẢO VỆ ROCKETTOWER")) or nil
    end

    local function GetHitOffset(mobHrp, myHrp)
        local dist = _G.MoonHitDistance or 12
        local mode = _G.MoonHitPosition or "Upper"

        if mode == "Upper" then
            return Vector3.new(dist * 0.1, dist, 0)
        elseif mode == "Below" then
            return Vector3.new(dist * 0.1, -dist, 0)
        elseif mode == "Behind" then
            local look = mobHrp.CFrame.LookVector
            if look.Magnitude > 0.01 then
                return -look * dist
            end
            if myHrp then
                local dir = (mobHrp.Position - myHrp.Position).Unit
                return dir * dist
            end
            return Vector3.new(0, 0, dist)
        elseif mode == "Front" then
            local look = mobHrp.CFrame.LookVector
            if look.Magnitude > 0.01 then
                return look * dist
            end
            if myHrp then
                local dir = (myHrp.Position - mobHrp.Position).Unit
                return dir * dist
            end
            return Vector3.new(0, 0, -dist)
        end
        return Vector3.new(0, dist, 0)
    end

    local function ClearConstraints(hrp)
        if not hrp then return end
        for _, child in ipairs(hrp:GetChildren()) do
            if child:IsA("BodyPosition")
               or child:IsA("BodyGyro")
               or child:IsA("AlignPosition")
               or child:IsA("AlignOrientation")
               or child:IsA("BodyVelocity") then
                child:Destroy()
            end
        end
    end

    local function AttachToMob(hrp, mobHrp)
        if not hrp or not hrp.Parent or not mobHrp or not mobHrp.Parent then return end

        ClearConstraints(hrp)

        hrp.Anchored = false
        local char = hrp.Parent
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = false end

        local offset = GetHitOffset(mobHrp, hrp)
        local mobPos = mobHrp.Position + offset
        local lookAt = mobHrp.Position

        MoonJitterSeed = MoonJitterSeed + 1
        local jX = math.sin(MoonJitterSeed * 0.7) * 0.05
        local jY = math.cos(MoonJitterSeed * 0.9) * 0.03
        local jZ = math.sin(MoonJitterSeed * 1.1) * 0.05

        local finalPos = mobPos + Vector3.new(jX, jY, jZ)

        hrp.CFrame = CFrame.new(finalPos, lookAt)
        hrp.AssemblyLinearVelocity  = hrp.AssemblyLinearVelocity * 0.3
        hrp.AssemblyAngularVelocity = Vector3.zero
    end

    local function StopAttach(hrp)
        if not hrp then
            hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        end
        if hrp then
            hrp.Anchored = false
            local char = hrp.Parent
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then hum.PlatformStand = false end
            ClearConstraints(hrp)
        end
    end

    local MoonAttackJitter = 0
    local function MoonAttack()
        local char = LocalPlayer.Character
        if not char then return end
        local action = ReplicatedStorage:FindFirstChild("Remotes")
        if action then action = action:FindFirstChild("Action") end
        if not action then return end

        MoonAttackJitter = MoonAttackJitter + 1
        if MoonAttackJitter % 3 == 0 then
            task.wait(math.random(1, 3) * 0.01)
        end

        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") then
                pcall(function() action:FireServer(v.Name, "hit") end)
            end
        end
    end

    local DASH_SKILLS = {z = true, x = true, c = true, v = true}

    local function ForceResetPosition(hrp, mobHrp)
        if not hrp or not hrp.Parent then return end
        if not mobHrp or not mobHrp.Parent then return end

        local offset = GetHitOffset(mobHrp, hrp)
        local mobPos = mobHrp.Position + offset
        local lookAt = mobHrp.Position

        hrp.CFrame = CFrame.new(mobPos, lookAt)
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end

    local function FireMoonSkill(hrp, mobHrp)
        local char = LocalPlayer.Character
        if not char then return end
        local Skills = {}
        if _G.AutoSkillZ then table.insert(Skills, "z") end
        if _G.AutoSkillX then table.insert(Skills, "x") end
        if _G.AutoSkillC then table.insert(Skills, "c") end
        if _G.AutoSkillV then table.insert(Skills, "v") end
        if _G.AutoSkillF then table.insert(Skills, "f") end
        if #Skills == 0 then return end

        local Skill = Skills[math.random(#Skills)]
        local action = ReplicatedStorage:FindFirstChild("Remotes")
        if action then action = action:FindFirstChild("Action") end
        if not action then return end

        for _, Tool in ipairs(char:GetChildren()) do
            if Tool:IsA("Tool") then
                pcall(function() action:FireServer(Tool.Name, Skill) end)
            end
        end

        if DASH_SKILLS[Skill] and hrp and mobHrp then
            task.spawn(function()
                task.wait(0.05)
                ForceResetPosition(hrp, mobHrp)
                task.wait(0.05)
                ForceResetPosition(hrp, mobHrp)
            end)
        end
    end

    function MoonEquipWeapon()
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end

            local mainWeapon = AsString(_G.MainWeapon) or "Melee"
            local supportWeapons = AsStringList(_G.Select_EquipWeapon)

            local wantedTypes = {}
            wantedTypes[mainWeapon] = true
            for _, w in ipairs(supportWeapons) do
                if type(w) == "string" then
                    wantedTypes[w] = true
                end
            end

            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("Tool") then
                    local toolType = v:GetAttribute("Type")
                    if not wantedTypes[toolType] then
                        v.Parent = LocalPlayer.Backpack
                    end
                end
            end

            local backpack = LocalPlayer:FindFirstChild("Backpack")
            if backpack then
                for _, v in ipairs(backpack:GetChildren()) do
                    if v:IsA("Tool") then
                        local toolType = v:GetAttribute("Type")
                        if wantedTypes[toolType] then
                            v.Parent = char
                        end
                    end
                end
            end
        end)
    end

    task.spawn(function()
        while task.wait(0.03) do
            if not MoonRunning then
                if MoonLastRunning then
                    MoonLastRunning = false
                    MoonCurrentTarget = nil
                    MoonLastAction = 0
                    MoonAtCave = false
                    MoonLastMobHealth = 0
                    MoonStuckCount = 0

                    local char = LocalPlayer.Character
                    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.Anchored = false end
                    local hum = char and char:FindFirstChild("Humanoid")
                    if hum then hum.PlatformStand = false end
                end
                continue
            end

            if not MoonLastRunning then
                MoonLastRunning = true
                MoonCurrentTarget = nil
                MoonLastAction = tick()
                MoonAtCave = false
                MoonLastMobHealth = 0
                MoonStuckCount = 0
            end

            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")

            if not hum or not hrp or hum.Health <= 0 then
                if hrp then hrp.Anchored = false end
                if hum then hum.PlatformStand = false end
                continue
            end

            if MoonLastAction > 0 and tick() - MoonLastAction > MOON_WATCHDOG then
                MoonCurrentTarget = nil
                MoonLastAction = tick()
            end

            local target, priorityText = GetMoonTarget()

            if not target then
                _G.CanAutoSkill = false

                if not MoonAtCave then
                    MoonStatusPara:SetTitle("⏳ " .. T("Chờ mob..."))
                    MoonStatusPara:SetContent(T("Đứng tại cửa hang đợi mob"))
                    MoonCurrentTarget = nil

                    hrp.CFrame = CFrame.new(CAVE_POS)
                    hrp.AssemblyLinearVelocity  = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero

                    StopAttach(hrp)
                    MoonAtCave = true
                else
                    local breathe = math.sin(tick() * 2) * 0.15
                    hrp.CFrame = hrp.CFrame + Vector3.new(0, breathe * 0.1, 0)
                end

                task.wait(0.3)
                continue
            end

            _G.CanAutoSkill = true

            if target ~= MoonCurrentTarget then
                MoonCurrentTarget = target
                MoonSettleTime = tick()
                MoonLastAction = tick()
                MoonAtCave = false
                MoonLastMobHealth = 0
                MoonStuckCount = 0

                StopAttach(hrp)

                local tHrp = target.HumanoidRootPart
                if tHrp and hrp then
                    local offset = GetHitOffset(tHrp, hrp)
                    local mobPos = tHrp.Position + offset
                    local lookAt = tHrp.Position

                    hrp.CFrame = CFrame.new(mobPos, lookAt)
                    hrp.AssemblyLinearVelocity  = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end

            local tHrp = target.HumanoidRootPart
            if not tHrp then
                task.wait(0.05)
                continue
            end

            target.Humanoid.WalkSpeed = 0
            target.Humanoid.JumpPower = 0

            AttachToMob(hrp, tHrp)

            MoonLastAction = tick()

            local nowHealth = target.Humanoid.Health
            if MoonLastMobHealth == 0 then
                MoonLastMobHealth = nowHealth
                MoonDamageCheckTime = tick()
            else
                local elapsed = tick() - MoonDamageCheckTime
                if elapsed >= MOON_STUCK_THRESHOLD then
                    local hpDelta = MoonLastMobHealth - nowHealth

                    if hpDelta < 1 then
                        if tick() - MoonLastStuckTime >= MOON_STUCK_COOLDOWN then
                            MoonStuckCount = MoonStuckCount + 1
                            MoonLastStuckTime = tick()

                            if hrp then
                                hrp.CFrame = hrp.CFrame + Vector3.new(
                                    (math.random() - 0.5) * 1,
                                    math.random() * 0.5,
                                    (math.random() - 0.5) * 1
                                )
                            end

                            if MoonStuckCount >= MOON_STUCK_MAX then
                                _G.SeaNotify("🛑 " .. T("Anti-cheat"), T("Đã tắt Auto Farm. Đợi 30s!"), 8)
                                MoonRunning = false
                                break
                            end
                        end
                    else
                        MoonStuckCount = 0
                    end

                    MoonLastMobHealth = nowHealth
                    MoonDamageCheckTime = tick()
                end
            end

            MoonStatusPara:SetTitle(priorityText .. ": " .. target.Name)
            MoonStatusPara:SetContent(string.format("HP: %d / %d | Dist: %d | Stuck: %d/%d",
                math.floor(target.Humanoid.Health),
                math.floor(target.Humanoid.MaxHealth),
                math.floor((hrp.Position - tHrp.Position).Magnitude),
                MoonStuckCount, MOON_STUCK_MAX))

            local now = tick()

            if now - MoonLastEquip >= 0.5 then
                MoonLastEquip = now
                MoonEquipWeapon()
            end

            if _G.AutoCombat then
                if MoonRunning and MoonCurrentTarget then
                    local hasSkill = _G.AutoSkillZ or _G.AutoSkillX
                                  or _G.AutoSkillC or _G.AutoSkillV or _G.AutoSkillF
                    if hasSkill then
                        -- Skill loop đã fire riêng
                    else
                        if now - MoonLastAttack >= 0.15 then
                            MoonLastAttack = now
                            MoonAttack()
                        end
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while task.wait(0.05) do
            if not MoonRunning then continue end
            if not _G.RaidAutoSkill then continue end
            if not _G.CanAutoSkill then continue end

            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp or hum.Health <= 0 then continue end

            if not MoonCurrentTarget or not MoonCurrentTarget.Parent then continue end
            local tHrp = MoonCurrentTarget:FindFirstChild("HumanoidRootPart")
            if not tHrp then continue end

            local dist = (hrp.Position - tHrp.Position).Magnitude
            if dist > 40 then continue end

            if tick() - MoonSettleTime < MOON_SETTLE_DELAY then continue end

            FireMoonSkill(hrp, tHrp)
            task.wait(0.1 + math.random() * 0.1)
        end
    end)

    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                if not MoonRunning then return end
                local char = LocalPlayer.Character
                if not char then return end
                if not char:FindFirstChild("HakiFolder") then
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                    local action = remotes and remotes:FindFirstChild("Action")
                    if action then action:FireServer("Misc", "buso") end
                end
            end)
        end
    end)

    task.spawn(function()
        task.wait(2)
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            if not char:FindFirstChild("HakiFolder") then
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                local action = remotes and remotes:FindFirstChild("Action")
                if action then
                    action:FireServer("Misc", "buso")
                end
            end
        end)
    end)

    -- UI MOON
    MoonFarm:Toggle({
        Title = T("🌙 Auto Farm Moon Mob"),
        Value = false,
        Callback = function(v)
            if v == MoonRunning then return end
            MoonRunning = v
            MoonStatusPara:SetTitle(v and T("Trạng thái: ĐANG FARM") or T("Trạng thái: Đã tắt"))
            MoonStatusPara:SetContent(v and T("Đang tìm mob...") or T("Bật lại để tiếp tục"))
        end
    })

    MoonFarm:Dropdown({
        Title = T("🎯 Vị trí đánh"),
        Options = {
            T("Upper (Trên đầu)"),
            T("Below (Dưới chân)"),
            T("Behind (Phía sau)"),
            T("Front (Phía trước)")
        },
        Multi = false,
        Value = T("Upper (Trên đầu)"),
        Callback = function(v)
            local val = AsString(v)
            if not val then return end
            if val == T("Upper (Trên đầu)") then _G.MoonHitPosition = "Upper"
            elseif val == T("Below (Dưới chân)") then _G.MoonHitPosition = "Below"
            elseif val == T("Behind (Phía sau)") then _G.MoonHitPosition = "Behind"
            elseif val == T("Front (Phía trước)") then _G.MoonHitPosition = "Front" end
        end
    })

    MoonFarm:Slider({
        Title = T("📏 Khoảng cách đánh"),
        Min = 5, Max = 40, Value = 12,
        Callback = function(v)
            if type(v) == "number" then
                _G.MoonHitDistance = v
            end
        end
    })

    MoonWeapon:Dropdown({
        Title = T("🗡️ Main Weapon"),
        Options = {"Melee", "Sword", "Special", "DevilFruit"},
		Id = "MAINWEAPON",
        Multi = false,
        Value = "Melee",
        Callback = function(v)
            local val = AsString(v)
            if not val then return end
            _G.MainWeapon = val
        end
    })

    MoonWeapon:Dropdown({
        Title = T("🗡️ Support Weapons"),
        Options = {"Melee", "Sword", "Special", "DevilFruit"},
		Id = "SUPWEAPON",
        Multi = true,
        Callback = function(v)
            local list = AsStringList(v)
            _G.Select_EquipWeapon = list
            local t = #list > 0 and table.concat(list, ", ") or "(không có)"
        end
    })

    MoonSkills:Toggle({
        Title = T("⚔️ Auto Attack + Skill (Ưu tiên Skill)"),
		Id = "AutoAttackSkill",
        Value = false,
        Callback = function(v)
            _G.AutoCombat     = v
            _G.RaidAutoAttack = v
            _G.RaidAutoSkill  = v
        end
    })
    MoonSkills:Toggle({Title = T("Auto Skill Z"), Id = "SkillsZ", Value = false, Callback = function(v) _G.AutoSkillZ = v end})
    MoonSkills:Toggle({Title = T("Auto Skill X"), Id = "SkillsX", Value = false, Callback = function(v) _G.AutoSkillX = v end})
    MoonSkills:Toggle({Title = T("Auto Skill C"), Id = "SkillsC", Value = false, Callback = function(v) _G.AutoSkillC = v end})
    MoonSkills:Toggle({Title = T("Auto Skill V"), Id = "SkillsV", Value = false, Callback = function(v) _G.AutoSkillV = v end})
    MoonSkills:Toggle({Title = T("Auto Skill F"), Id = "SkillsF", Value = false, Callback = function(v) _G.AutoSkillF = v end})

    MoonTravel:Button({
        Title = T("🌍 Quay Về Trái Đất (Back Earth)"),
        Callback = function()
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then
                _G.SeaNotify("❌ " .. T("Không có nhân vật"), T("Character chưa load"), 3)
                return
            end

            local npcPrompt = workspace:FindFirstChild("NpcPrompt")
            local backEarth = npcPrompt and npcPrompt:FindFirstChild("BackEarth")
            if not backEarth then
                _G.SeaNotify("❌ " .. T("Không tìm thấy NPC"), T("BackEarth không tồn tại"), 3)
                return
            end

            local npcHrp = backEarth:FindFirstChild("HumanoidRootPart")
            if not npcHrp then return end

            hrp.CFrame = CFrame.new(npcHrp.Position + Vector3.new(0, 2, 0))
            hrp.AssemblyLinearVelocity  = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero

            task.wait(0.4)

            local prompt = npcHrp:FindFirstChildWhichIsA("ProximityPrompt", true)
            if not prompt then
                prompt = backEarth:FindFirstChildWhichIsA("ProximityPrompt", true)
            end
            if not prompt then
                _G.SeaNotify("❌ " .. T("Không có prompt"), "", 4)
                return
            end

            pcall(function() fireproximityprompt(prompt, prompt.HoldDuration + 0.1) end)
            task.wait(0.3)
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration + 0.15)
                prompt:InputHoldEnd()
            end)
            task.wait(0.3)
            pcall(function()
                if prompt.Triggered then prompt.Triggered:Fire(LocalPlayer) end
            end)

            _G.SeaNotify("✅ " .. T("Đã kích hoạt"), T("Đang chờ chuyển map..."), 5)
        end
    })

    local MoonSettingTab  = Window:CreateTab(T("⚙️ Setting"), false, false)
    local MoonSettingPage = MoonSettingTab:CreatePage(T("Save / Load"))

    local SaveLoadCard = MoonSettingPage:CreateSection(T("💾 Quản Lý Save"), "Left")
    local InfoCard     = MoonSettingPage:CreateSection(T("📋 Thông Tin"), "Right")


    InfoCard:Paragraph({
        Title = T("📖 Hướng dẫn"),
        Content = T("1. Nhập tên Save → SAVE\n2. Chọn Save từ dropdown → LOAD\n3. Xóa bằng nút 🗑️")
    })

    local SaveListPara = InfoCard:Paragraph({
        Title = T("📁 Save hiện có:"),
        Content = T("(chưa có save)")
    })

    local SelectedSave = ""

    local RefreshSaveDropdown
    RefreshSaveDropdown = function()
        local list = GetSaveList()

        if #list == 0 then
            SaveListPara:SetContent(T("(chưa có save)"))
        else
            local text = ""
            for i, name in ipairs(list) do
                text = text .. "\n  " .. i .. ". " .. name
            end
            SaveListPara:SetContent(text)
        end

        if SaveDropdown and SaveDropdown.Set then
            pcall(function()
                if #list > 0 then
                    SaveDropdown:Set(list)
                else
                    SaveDropdown:Set({})
                end
            end)
        end
    end

    local NewSaveName = ""
    SaveLoadCard:Textbox({
        Title = T("✏️ Tên Save mới"),
        Placeholder = "VD: Save1",
        Value = "",
        Callback = function(v)
            if type(v) == "string" then
                NewSaveName = v
            end
        end
    })

    local SaveDropdown = SaveLoadCard:Dropdown({
        Title = T("📁 Chọn Save"),
        Options = GetSaveList(),
        Multi = false,
        Value = "",
        Callback = function(v)
            local val = AsString(v)
            if not val or val == "" then return end
            if val == T("(chưa có save)") then return end
            SelectedSave = val
        end
    })

    RefreshSaveDropdown()

    SaveLoadCard:Button({
        Title = T("💾 SAVE"),
        Callback = function()
            if NewSaveName == "" then
                _G.SeaNotify("❌ " .. T("Chưa nhập tên"), T("Nhập tên save!"), 3)
                return
            end

            SaveMoonSetting(NewSaveName)
            SelectedSave = NewSaveName
            RefreshSaveDropdown()

            task.delay(0.3, function()
                SelectedSave = NewSaveName
            end)
        end
    })

    SaveLoadCard:Button({
        Title = T("📂 LOAD"),
        Callback = function()
            local saveToLoad = SelectedSave

            if saveToLoad == "" then
                local list = GetSaveList()
                if #list > 0 then
                    saveToLoad = list[1]
                end
            end

            if saveToLoad == "" then
                _G.SeaNotify("❌ " .. T("Chưa có save"), T("Chưa có file save nào!"), 3)
                return
            end

            if LoadMoonSetting(saveToLoad) then
                _G.SeaNotify("💡 " .. T("Nhắc nhở"), T("Tắt/Bật Auto Farm để áp dụng"), 4)
            end
        end
    })

    SaveLoadCard:Button({
        Title = T("🗑️ Xóa Save"),
        Callback = function()
            local saveToDelete = SelectedSave

            if saveToDelete == "" then
                local list = GetSaveList()
                if #list > 0 then
                    saveToDelete = list[1]
                end
            end

            if saveToDelete == "" then
                _G.SeaNotify("❌ " .. T("Chưa chọn Save"), T("Chưa có save để xóa!"), 3)
                return
            end

            local path = GetSavePath(saveToDelete)
            if isfile(path) then
                delfile(path)
                _G.SeaNotify("✅ " .. T("Đã xóa"), saveToDelete, 3)
                SelectedSave = ""
                RefreshSaveDropdown()
            else
                _G.SeaNotify("❌ " .. T("Không có"), saveToDelete, 3)
            end
        end
    })

    SaveLoadCard:Button({
        Title = T("🔄 Làm mới danh sách"),
        Callback = function()
            RefreshSaveDropdown()
            _G.SeaNotify("✅ " .. T("Đã làm mới"), T("Danh sách save"), 2)
        end
    })

end

-- ============================================================
-- NẾU KHÔNG PHẢI MAP MOON → LOAD ĐẦY ĐỦ UI
-- ============================================================
if not IS_MOON_MAP then

-- ============================================================
-- TRACK SKILL LƯỚT
-- ============================================================
_G.LastSkillTime = 0
_G.LastSkillKey  = ""
_G.DASH_SKILLS   = {x = true}
_G.DASH_NEGATE_TIME = 0.35

-- ============================================================
-- 🆕 AUTO SKILL v132 — XÓA BODYMOVER + KHÔNG BLOCK CFrame
-- ============================================================
local function AutoSkill()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local Skills = {}
        if _G.AutoSkillZ then table.insert(Skills, "z") end
        if _G.AutoSkillX then table.insert(Skills, "x") end
        if _G.AutoSkillC then table.insert(Skills, "c") end
        if _G.AutoSkillV then table.insert(Skills, "v") end
        if _G.AutoSkillF then table.insert(Skills, "f") end
        if #Skills == 0 then return end

        local Skill = Skills[math.random(#Skills)]

        _G.LastSkillTime = tick()
        _G.LastSkillKey  = Skill

        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local action = remotes and remotes:FindFirstChild("Action")
        if not action then return end

        for _, Tool in ipairs(char:GetChildren()) do
            if Tool:IsA("Tool") then
                action:FireServer(Tool.Name, Skill)
            end
        end

        if _G.ClearDashBodyMovers and hrp then
            _G.ClearDashBodyMovers(hrp, 0.8)
        end
    end)
end

function _G.ClearDashBodyMovers(hrp, duration)
    if not hrp or not hrp.Parent then return end
    duration = duration or 0.8

    task.spawn(function()
        local startTime = tick()

        while tick() - startTime < duration do
            task.wait(0.03)
            if not hrp or not hrp.Parent then break end

            for _, child in ipairs(hrp:GetChildren()) do
                if child:IsA("BodyVelocity") then
                    if child.Name == "Fly"
                       or child.Name == "BodyVelocity"
                       or child.Name == "DashVelocity"
                       or child.Name == "AntiDashBV" then
                        pcall(function() child:Destroy() end)
                    end
                elseif child:IsA("BodyGyro") then
                    if child.Name == "BodyGyro"
                       or child.Name == "DashGyro" then
                        pcall(function() child:Destroy() end)
                    end
                elseif child:IsA("AlignPosition") then
                    if child.Name == "AlignPosition"
                       or child.Name == "DashAlign" then
                        pcall(function() child:Destroy() end)
                    end
                end
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

local function EquipWeapon()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") and v:GetAttribute("Type") ~= _G.MainWeapon then
                v.Parent = LocalPlayer.Backpack
            end
        end
        for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if v:IsA("Tool") and v:GetAttribute("Type") == _G.MainWeapon then
                char.Humanoid:EquipTool(v)
                break
            end
        end
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") and v:GetAttribute("Type") ~= _G.MainWeapon
               and not table.find(_G.Select_EquipWeapon or {}, v:GetAttribute("Type")) then
                v.Parent = LocalPlayer.Backpack
            end
        end
        for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if v:IsA("Tool") and v:GetAttribute("Type") ~= _G.MainWeapon
               and table.find(_G.Select_EquipWeapon or {}, v:GetAttribute("Type")) then
                v.Parent = char
            end
        end
    end)
end

local function Attack()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local action = remotes and remotes:FindFirstChild("Action")
        if not action then return end
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") then
                action:FireServer(v.Name, "hit")
            end
        end
    end)
end

-- ============================================================
-- 🆕 NO VFX v3 — EVENT-DRIVEN, KHÔNG LAG
-- Tắt VFX trong workspace, Camera, Character, PlayerGui
-- ============================================================
local VFX_CONNECTIONS = {}
local VFX_KILL_CLASSES = {
    ["ParticleEmitter"] = true,
    ["Beam"] = true,
    ["Trail"] = true,
    ["Sparkles"] = true,
    ["Fire"] = true,
    ["Smoke"] = true,
    ["Highlight"] = true,
    ["PointLight"] = true,
    ["SpotLight"] = true,
    ["SurfaceLight"] = true,
}

-- Hàm tắt 1 object VFX nếu thuộc class cần kill
local function TryKillVFX(obj)
    if not obj or not obj.Parent then return end
    local cls = obj.ClassName
    if not VFX_KILL_CLASSES[cls] then return end

    pcall(function()
        if cls == "ParticleEmitter" or cls == "Beam" or cls == "Trail"
           or cls == "Sparkles" or cls == "Fire" or cls == "Smoke" then
            if obj.Enabled then obj.Enabled = false end
        elseif cls == "Highlight" then
            if obj.Enabled then obj.Enabled = false end
        elseif cls == "PointLight" or cls == "SpotLight" or cls == "SurfaceLight" then
            if obj.Enabled then obj.Enabled = false end
        end
    end)
end

-- Quét đệ quy 1 container (chạy 1 lần)
local function KillVFXIn(container)
    if not container then return end
    pcall(function()
        for _, v in ipairs(container:GetDescendants()) do
            TryKillVFX(v)
        end
    end)
end

-- Gắn connection cho 1 container để bắt VFX mới
local function HookContainer(container)
    if not container then return end
    local conn = container.DescendantAdded:Connect(function(obj)
        if _G.VFXDisabled then
            TryKillVFX(obj)
        end
    end)
    table.insert(VFX_CONNECTIONS, conn)
end

local function NoVFX(State)
    _G.VFXDisabled = State

    -- Ngắt tất cả connection cũ
    for _, conn in ipairs(VFX_CONNECTIONS) do
        pcall(function() conn:Disconnect() end)
    end
    VFX_CONNECTIONS = {}

    if not State then return end

    -- 1. Quét workspace 1 lần
    KillVFXIn(workspace)

    -- 2. Quét Camera (VFX skill thường nằm ở đây!)
    local cam = workspace.CurrentCamera
    if cam then KillVFXIn(cam) end

    -- 3. Quét Character
    local char = LocalPlayer.Character
    if char then KillVFXIn(char) end

    -- 4. Quét PlayerGui (VFX UI)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then KillVFXIn(pg) end

    -- 5. Fix Humanoid + xóa Stun
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            if hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
            if hum.JumpPower < 50 then hum.JumpPower = 50 end
        end
        for _, folderName in ipairs({"Stun", "StunS"}) do
            local folder = char:FindFirstChild(folderName)
            if folder and #folder:GetChildren() > 0 then
                pcall(function() folder:ClearAllChildren() end)
            end
        end
    end

    -- 6. Hook DescendantAdded cho các container chính
    HookContainer(workspace)
    if cam then HookContainer(cam) end
    if char then HookContainer(char) end
    if pg then HookContainer(pg) end

    -- 7. Khi respawn → hook lại Character mới
    local respawnConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
        if not _G.VFXDisabled then return end
        task.wait(0.5)
        KillVFXIn(newChar)
        HookContainer(newChar)
    end)
    table.insert(VFX_CONNECTIONS, respawnConn)
end

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ============================================================
-- TAB 1: SETTINGS
-- ============================================================
local Tab1       = Window:CreateTab(T("Settings"), true, false)
local Tab_Page1  = Tab1:CreatePage(T("Main Settings"))
local Weapon     = Tab_Page1:CreateSection(T("🗡️ Select Weapon"), "Left")
local AutoSkills = Tab_Page1:CreateSection(T("⚔️ Auto Skills"), "Left")
local Method     = Tab_Page1:CreateSection(T("🎯 Select Method Farm"), "Right")
local Haki       = Tab_Page1:CreateSection(T("👁️ Haki"), "Right")
local VFX        = Tab_Page1:CreateSection(T("✨ VFX"), "Right")
local Tab_Page2  = Tab1:CreatePage(T("Other Settings"))
local Accessory  = Tab_Page2:CreateSection(T("🎒 Accessory & Rebirth"), "Right")
local Potion     = Tab_Page2:CreateSection(T("🧪 Auto Use X2 Potion"), "Left")

Weapon:Dropdown({
    Title = T("Main Weapon (Attack)"), Options = TypeTool, Multi = false, Value = "Melee",
    Callback = function(Value) _G.MainWeapon = Value end
})
Weapon:Dropdown({
    Title = T("Select Support Weapon"), Options = TypeTool, Multi = true,
    Callback = function(Value) _G.Select_EquipWeapon = Value end
})

AutoSkills:Toggle({
    Title = T("⚔️ Auto Attack + Skill (Ưu tiên Skill)"),
	Id = "AATACKSKILLAOTU",
    Value = false,
    Callback = function(v)
        _G.AutoCombat     = v
        _G.RaidAutoAttack = v
        _G.RaidAutoSkill  = v
    end
})
AutoSkills:Paragraph({
    Title = T("ℹ️ Cơ chế"),
    Content = T("• Ưu tiên dùng Skill (Z/X/C/V/F đã bật)\n• Hết skill → tự động đánh thường\n• Chỉ cần bật 1 nút")
})

AutoSkills:Toggle({Title = T("Auto Skill Z"), Id = "SKILLZ", Value = false, Callback = function(v) _G.AutoSkillZ = v end})
AutoSkills:Toggle({Title = T("Auto Skill X"), Id = "SKILLX", Value = false, Callback = function(v) _G.AutoSkillX = v end})
AutoSkills:Toggle({Title = T("Auto Skill C"), Id = "SKILLC", Value = false, Callback = function(v) _G.AutoSkillC = v end})
AutoSkills:Toggle({Title = T("Auto Skill V"), Id = "SKILLV", Value = false, Callback = function(v) _G.AutoSkillV = v end})
AutoSkills:Toggle({Title = T("Auto Skill F"), Id = "SKILLF", Value = false, Callback = function(v) _G.AutoSkillF = v end})
Haki:Toggle({Title = T("Auto Enabled Haki"), Id = "AENHAKI", Value = false, Callback = function(v) _G.Auto_Haki = v end})

Method:Dropdown({
    Title = T("Select Method Farm"),
    Options = {T("Behind"), T("Below"), T("Upper"), T("Front")},
	Id = "SELEMETHODFARM",
    Multi = false, Value = T("Upper"),
    Callback = function(v) _G.Select_Method = v end
})
Method:Slider({
    Title = T("Distance Farm"), Min = 0, Max = 30, Value = 5,
    Callback = function(v) _G.Distance_Farm = v end
})
VFX:Toggle({Title = T("Disable VFX"), Value = false, Callback = function(v) NoVFX(v) end})

Accessory:Toggle({
    Title = T("Auto Equip Best Accessory"), Value = false,
    Callback = function(v) _G.Auto_Equip_Accessory = v end
})
Accessory:Toggle({
    Title = T("Auto Rebirth (Max Level)"), Value = false,
    Callback = function(v) _G.Auto_Rebirth = v end
})

Potion:Dropdown({
    Title = T("Select X2 Potion"),
    Options = X2List,
    Multi = false,
    Callback = function(v)
        local val = v
        if type(val) == "table" then
            local real = nil
            for _, item in pairs(val) do
                if type(item) == "string" and item ~= "" then
                    real = item
                    break
                end
            end
            val = real
        end
        if type(val) ~= "string" or val == "" then
            _G.Select_Potion = nil
            return
        end
        _G.Select_Potion = val
    end
})

Potion:Textbox({
    Title = T("Số lượng dùng (1-100)"),
    Placeholder = "1",
    Value = "1",
    Callback = function(v)
        local n = tonumber(v) or 1
        if n < 1 then n = 1 end
        if n > 100 then n = 100 end
        _G.PotionAmount = n
    end
})

Potion:Button({
    Title = T("🧪 USE X2 POTION (1 lần)"),
    Callback = function()
        local potionName = _G.Select_Potion
        local amount = tonumber(_G.PotionAmount) or 1

        if amount < 1 then amount = 1 end
        if amount > 100 then amount = 100 end
        _G.PotionAmount = amount

        if type(potionName) == "table" then
            local real = nil
            for _, v in pairs(potionName) do
                if type(v) == "string" and v ~= "" then
                    real = v
                    break
                end
            end
            potionName = real
        end

        if type(potionName) ~= "string" or potionName == "" then
            _G.SeaNotify("❌ " .. T("Chưa chọn Potion"), T("Chọn 1 loại X2 Potion trước!"), 3)
            return
        end

        local Inv = GetInventory()
        local have = (Inv[potionName] and Inv[potionName].amount) or 0

        if have <= 0 then
            _G.SeaNotify("❌ " .. T("Không có Potion"), potionName .. " (0)", 3)
            return
        end

        local useCount = math.min(amount, have)
        local remote = ReplicatedStorage:FindFirstChild("Remotes")
        remote = remote and remote:FindFirstChild("Inventory")
        if not remote then
            _G.SeaNotify("❌ " .. T("Không tìm thấy Remote"), T("Remotes.Inventory"), 3)
            return
        end

        task.spawn(function()
            for i = 1, useCount do
                pcall(function()
                    remote:FireServer(potionName)
                end)
                task.wait(0.15)
            end
        end)

        _G.SeaNotify("🧪 " .. T("Đang dùng Potion"),
            potionName .. " x" .. useCount .. " (" .. T("có") .. " " .. have .. ")", 4)
    end
})

-- ============================================================
-- TAB 2: MAIN
-- ============================================================
local Tab2            = Window:CreateTab(T("Main"), false, false)
local Farm            = Tab2:CreatePage(T("Farm"))
local AllBoss         = Tab2:CreatePage(T("Boss"))
local RaidBossPage    = Tab2:CreatePage(T("Raid Boss & Shop"))
local RaidDun         = Tab2:CreatePage(T("Dungeon, Shop / Weapon"))

local AutoFarmCard    = Farm:CreateSection(T("🌾 Auto Farm"), "Left")
local MaterialCard    = Farm:CreateSection(T("⛏️ Auto Farm Material"), "Right")
local Boss            = AllBoss:CreateSection(T("👹 Boss"), "Left")
local Thief           = AllBoss:CreateSection(T("💸 Thief"), "Left")
local Piccolo         = AllBoss:CreateSection(T("🐉 Piccolo"), "Left")
local SpawnedT        = AllBoss:CreateSection(T("🔍 Spawned Check"), "Right")
local Duck            = AllBoss:CreateSection(T("🦆 Duck"), "Right")
local DevilBoat       = AllBoss:CreateSection(T("⛵ Devil Boat"), "Right")
local DungeonCard     = RaidDun:CreateSection(T("🏰 Auto Dungeon"), "Left")
local ShopDunCard     = RaidDun:CreateSection(T("🏪 Shop Dungeon"), "Left")
local WeaponCraft     = RaidDun:CreateSection(T("🔨 Weapon"), "Left")
local DungeonSettingsCard = RaidDun:CreateSection(T("⚙️ Dungeon Settings"), "Right")
local ShopDunInfoCard = RaidDun:CreateSection(T("📊 Shop Dungeon Info"), "Right")
local RaidCard        = RaidDun:CreateSection(T("🌋 Auto Raid Moon"), "Right")
local RaidBossCard    = RaidBossPage:CreateSection(T("⚔️ Auto Raid Boss"), "Left")
local RaidBossInfoCard= RaidBossPage:CreateSection(T("📋 Raid Info"), "Right")
local ShopRaidCard    = RaidBossPage:CreateSection(T("🏪 Shop Raid"), "Left")
local ShopRaidInfoCard= RaidBossPage:CreateSection(T("📊 Shop Info"), "Right")
local RaidSettingsCard= RaidBossPage:CreateSection(T("⚙️ Raid Settings"), "Right")
local TimeMysteryCard = RaidBossPage:CreateSection(T("🎁 Time Mystery Box"), "Left")

AutoFarmCard:Toggle({
    Title = T("Auto Level Farm"),
	Value = false,
    Callback = function(v)
        _G.Auto_Farm_Level = v
        if v then
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
        end
    end
})
MaterialCard:Dropdown({
    Title = T("Select Farm Material"),
    Options = ItemAll,
    Multi = true,
    Callback = function(v)
        local list = {}
        if type(v) == "table" then
            for _, item in pairs(v) do
                if type(item) == "string" then
                    table.insert(list, item)
                end
            end
        elseif type(v) == "string" then
            table.insert(list, v)
        end
        _G.Select_Material = list
    end
})
MaterialCard:Toggle({
    Title = T("Auto Farm Material"), Value = false,
    Callback = function(v) _G.Auto_Farm_Material = v end})
Boss:Dropdown({
    Title = T("Select Boss"), Options = Bosses, Multi = false,
    Callback = function(v) _G.Select_Boss = v end
})
Boss:Toggle({Title = T("Auto Farm All Boss (Full)"), Value = false, Callback = function(v) _G.Auto_FarmBoss = v end})
Thief:Toggle({Title = T("Auto Farm Thief Chest"), Value = false, Callback = function(v) _G.Auto_BaconThief = v end})
Piccolo:Toggle({Title = T("Auto Farm Piccolo"), Value = false, Callback = function(v) _G.Auto_Piccolo = v end})
Duck:Toggle({Title = T("Auto Farm Duck (Full)"), Value = false, Callback = function(v) _G.Auto_DuckAutomatically = v if v then ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel") end end
})
DevilBoat:Toggle({Title = T("Auto Farm Devil Boat"), Value = false, Callback = function(v) _G.Auto_DevilBoat = v end})
DevilBoat:Toggle({Title = T("Auto Farm Kraken"), Value = false, Callback = function(v) _G.Auto_Kraken = v end
})

local Spawn_Status = SpawnedT:Paragraph({Title = T("Spawn Status"), Content = "N/A"})
local Item_Auto    = WeaponCraft:Paragraph({Title = T("Item Requirements ( None )"), Content = "N/A"})

WeaponCraft:Dropdown({
    Title = T("Select Weapon Craft"), Options = WeaponAll, Multi = false,
    Callback = function(v) _G.Select_Item = v end
})
WeaponCraft:Button({
    Title = T("Craft Weapon"),
    Callback = function()
        local Data = UseItems and UseItems[_G.Select_Item]
        if Data then
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Craft", _G.Select_Item, Data.Type)
        end
    end
})
local NotifyClass = false
WeaponCraft:Toggle({
    Title = T("Auto Craft Weapon (Full)"), Value = false,
    Callback = function(v)
        _G.Auto_CraftWeapon = v
        if not v then NotifyClass = false end
    end
})
WeaponCraft:Toggle({
    Title = T("Auto Farm Set Weapon"), Value = false,
    Callback = function(v) _G.Auto_Farm_Set = v end
})

RaidCard:Toggle({
    Title = T("Auto Raid Moon (Full)"), Value = false,
    Callback = function(v)
        _G.Auto_Raid = v
        if v then
            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
        end
    end
})

DungeonCard:Textbox({
    Title = T("Dungeon Orb to Use"), Id = "DUNOTOUSE", Placeholder = "...",
    Callback = function(v) _G.Dungeon_UseValue = tonumber(v) or 1 end
})
DungeonSettingsCard:Slider({
    Title = T("Health Return %"),
    Min = 1, Max = 100, Value = 30,
    Callback = function(v) _G.HealthPercent = v end
})
DungeonSettingsCard:Slider({
    Title = T("Dungeon Height"),
    Min = 0, Max = 100, Value = 25,
    Callback = function(v) _G.DungeonHeight = v end
})
DungeonCard:Toggle({
    Title = T("🏰 Auto Dungeon (Full)"),
    Value = false,
    Callback = function(v)
        _G.Auto_Dungeon = v

        if v then
            pcall(function()
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
            end)
        end
    end
})

-- ============================================================
-- RAID BOSS UI
-- ============================================================
local RaidBossData = {
    ["Bacon of Grudge"] = {
        Name = "Bacon of Grudge",
        Reward = T("Time Mystery Box x5, 7500 Diamond, Beli 50M, x3 Potion"),
        PortalCost = 1, Valid = true
    },
    ["??? (Raid 2)"] = {Name = "???", Reward = "SOON", PortalCost = 0, Valid = false},
    ["??? (Raid 3)"] = {Name = "???", Reward = "SOON", PortalCost = 0, Valid = false}
}

local RaidBossInfoPara = RaidBossInfoCard:Paragraph({
    Title = T("Name:") .. " ( chưa chọn )",
    Content = T("Please choose a Boss Raid!!")
})

RaidBossCard:Dropdown({
    Title = T("Choose a boss to raid"),
    Options = {T("Bacon of Grudge"), T("??? (Raid 2)"), T("??? (Raid 3)")},
    Multi = false,
    Callback = function(Value)
        _G.AutoRaidWho = Value
        local Data = RaidBossData[Value]
        if Data then
            RaidBossInfoPara:SetTitle(T("Name:") .. " " .. Data.Name)
            RaidBossInfoPara:SetContent(T("Reward:") .. " " .. Data.Reward .. "\n- " .. Data.PortalCost .. " Portal Gun")
        end
    end
})
RaidBossCard:Button({
    Title = T("Start Raid Now!!"),
    Callback = function()
        local Data = RaidBossData[_G.AutoRaidWho]
        if not Data then
            _G.SeaNotify("❌ " .. T("Raid not selected"), T("Please choose a Boss Raid!"), 3); return
        end
        if not Data.Valid then
            _G.SeaNotify("❌ " .. T("Raid không hợp lệ"), T("NO RAID!!!"), 3); return
        end
        _G.AutoRaidRunning = not _G.AutoRaidRunning
        _G.SeaNotify(_G.AutoRaidRunning and ("▶️ " .. T("Start Raid")) or ("⏹️ " .. T("Stop Raid")), Data.Name, 3)
    end
})
RaidSettingsCard:Slider({
    Title = T("Bacon of Grudge Height"), Min = 0, Max = 150, Value = 55,
    Callback = function(v) _G.RaidBossOffsetY = v end
})
RaidSettingsCard:Slider({
    Title = T("Golden Ball Height"), Min = 0, Max = 150, Value = 25,
    Callback = function(v) _G.RaidBallOffsetY = v end
})

-- ============================================================
-- SHOP RAID UI
-- ============================================================
local ShopInfoPara = ShopRaidInfoCard:Paragraph({
    Title = T("RaidPoint: ( đang load... )"),
    Content = T("Restock In: ( đang load... )")
})
local ShopItemInfo = ShopRaidInfoCard:Paragraph({
    Title = "Item: ( chưa chọn )",
    Content = "Chọn item từ dropdown"
})

_G.SelectedShopItem = nil
local ShopItemDropdown = nil
local LastShopItemsStr = ""
local ShopDropdownInitialized = false

local function UpdateShopDropdown(items)
    if #items == 0 then return end
    local itemsStr = table.concat(items, ",")
    if itemsStr == LastShopItemsStr and ShopItemDropdown then return end
    LastShopItemsStr = itemsStr

    if not ShopItemDropdown then
        ShopItemDropdown = ShopRaidCard:Dropdown({
            Title = T("Select Items to Purchase"), Options = items, Multi = false,
            Callback = function(Value)
                _G.SelectedShopItem = Value
                ShopItemInfo:SetTitle("Item: " .. Value)
                ShopItemInfo:SetContent(T("Đã chọn") .. " — " .. T("bấm BUY để mua"))
            end
        })
        ShopDropdownInitialized = true
    else
        local updated = false
        pcall(function()
            if ShopItemDropdown.Set then ShopItemDropdown:Set(items); updated = true
            elseif ShopItemDropdown.UpdateOptions then ShopItemDropdown:UpdateOptions(items); updated = true end
        end)
        if not updated then
            pcall(function() ShopItemDropdown:Destroy() end)
            ShopItemDropdown = ShopRaidCard:Dropdown({
                Title = T("Select Items to Purchase"), Options = items, Multi = false,
                Callback = function(Value)
                    _G.SelectedShopItem = Value
                    ShopItemInfo:SetTitle("Item: " .. Value)
                    ShopItemInfo:SetContent(T("Đã chọn") .. " — " .. T("bấm BUY để mua"))
                end
            })
        end
    end
end

ShopRaidCard:Button({
    Title = T("BUY!!"),
    Callback = function()
        if not _G.SelectedShopItem then
            _G.SeaNotify("❌ " .. T("Chưa chọn item"), T("Vui lòng chọn item trước!"), 3); return
        end
        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "buy_raidshop", _G.SelectedShopItem)
        _G.SeaNotify("✅ " .. T("Đã mua"), _G.SelectedShopItem, 3)
    end
})

-- ============================================================
-- 🎁 TIME MYSTERY BOX
-- ============================================================
local TimeMysteryInfo = TimeMysteryCard:Paragraph({
    Title = T("🎁 Time Mystery Box: ---"),
    Content = T("Nhập số lượng và bấm nút để mở")
})

TimeMysteryCard:Textbox({
    Title = T("Số lượng mở (1-100)"),
    Placeholder = "1",
    Value = "1",
    Callback = function(v)
        local n = tonumber(v) or 1
        if n < 1 then n = 1 end
        if n > 100 then n = 100 end
        _G.TimeMysteryAmount = n
        print("[TimeBox] " .. T("Số lượng mở:") .. " ", n)
    end
})

TimeMysteryCard:Button({
    Title = T("🎁 MỞ TIME MYSTERY BOX (1 lần)"),
    Callback = function()
        local amount = tonumber(_G.TimeMysteryAmount) or 1

        if amount < 1 then amount = 1 end
        if amount > 100 then amount = 100 end
        _G.TimeMysteryAmount = amount

        local Inv = GetInventory()
        local have = (Inv["Time Mystery Box"] and Inv["Time Mystery Box"].amount) or 0

        if have <= 0 then
            _G.SeaNotify("❌ " .. T("Không có Box"), T("Time Mystery Box (0)"), 3)
            return
        end

        local useCount = math.min(amount, have)

        local NetworkEvent = ReplicatedStorage
            :FindFirstChild("Modules")
            and ReplicatedStorage.Modules
            :FindFirstChild("NetworkFramework")
            and ReplicatedStorage.Modules.NetworkFramework
            :FindFirstChild("NetworkEvent")

        if not NetworkEvent then
            _G.SeaNotify("❌ " .. T("Không tìm thấy Remote"), T("NetworkEvent không tồn tại"), 3)
            return
        end

        local ok = pcall(function()
            NetworkEvent:FireServer("fire", nil, "Time Mystery Box", useCount)
        end)

        if ok then
            _G.SeaNotify("🎁 " .. T("Đang mở Box"),
                T("Mở") .. " " .. useCount .. " " .. T("box") .. " (" .. T("có") .. " " .. have .. ")", 4)
            print("[TimeBox] 🎁 " .. T("Mở"), useCount, T("box") .. " | " .. T("Còn lại") .. ":", have - useCount)
        else
            _G.SeaNotify("❌ " .. T("Lỗi fire"), T("Không mở được box"), 3)
        end
    end
})

-- ============================================================
-- SHOP DUNGEON UI
-- ============================================================
local ShopDunInfoPara = ShopDunInfoCard:Paragraph({
    Title = T("DungeonPoint: ( đang load... )"),
    Content = T("Chọn item Auto Buy ở cột trái")
})
local ShopDunItemInfo = ShopDunInfoCard:Paragraph({
    Title = "Item: ( chưa chọn )",
    Content = "Chọn item từ dropdown"
})

_G.AutoBuyDunItem    = nil
_G.AutoBuyDunRunning = false
local AutoBuyDunDropdown = nil
local LastAutoBuyDunStr  = ""

local function GetAllShopDunItems()
    local items, seen = {}, {}
    local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
    if hud and hud:FindFirstChild("Main") then
        local shop = hud.Main:FindFirstChild("Frame_ShopDungeon")
        if shop then
            local sf = shop:FindFirstChild("ShopScrollingFrame")
            if sf then
                for _, item in pairs(sf:GetChildren()) do
                    if item:IsA("Frame") then
                        local main = item:FindFirstChild("Main")
                        if main then
                            local titleLbl = main:FindFirstChild("TitleLabel")
                            if titleLbl and titleLbl.Text and titleLbl.Text ~= "" then
                                if not seen[titleLbl.Text] then
                                    seen[titleLbl.Text] = true
                                    table.insert(items, titleLbl.Text)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(items)
    return items
end

local function UpdateDunDropdown(items)
    if #items == 0 then return end
    local itemsStr = table.concat(items, ",")
    if itemsStr == LastAutoBuyDunStr and AutoBuyDunDropdown then return end
    LastAutoBuyDunStr = itemsStr

    if not AutoBuyDunDropdown then
        AutoBuyDunDropdown = ShopDunCard:Dropdown({
            Title = T("Auto Buy Items"), Options = items, Multi = false,
            Callback = function(Value)
                _G.AutoBuyDunItem = Value
                ShopDunItemInfo:SetTitle("Item: " .. Value)
                ShopDunItemInfo:SetContent(T("Đã chọn") .. " — " .. T("bật Toggle Auto Buy"))
            end
        })
    else
        local updated = false
        pcall(function()
            if AutoBuyDunDropdown.Set then AutoBuyDunDropdown:Set(items); updated = true
            elseif AutoBuyDunDropdown.UpdateOptions then AutoBuyDunDropdown:UpdateOptions(items); updated = true end
        end)
        if not updated then
            pcall(function() AutoBuyDunDropdown:Destroy() end)
            AutoBuyDunDropdown = ShopDunCard:Dropdown({
                Title = T("Auto Buy Items"), Options = items, Multi = false,
                Callback = function(Value)
                    _G.AutoBuyDunItem = Value
                    ShopDunItemInfo:SetTitle("Item: " .. Value)
                    ShopDunItemInfo:SetContent(T("Đã chọn") .. " — " .. T("bật Toggle Auto Buy"))
                end
            })
        end
    end
end

ShopDunCard:Toggle({
    Title = T("Auto Buy"), Value = false,
    Callback = function(Value)
        if Value and not _G.AutoBuyDunItem then
            _G.SeaNotify("❌ " .. T("Chưa chọn item"), T("Chọn item Auto Buy trước!"), 3)
            _G.AutoBuyDunRunning = false
            return
        end
        _G.AutoBuyDunRunning = Value
        _G.SeaNotify(Value and ("▶️ " .. T("Bật Auto Buy")) or ("⏹️ " .. T("Tắt Auto Buy")), _G.AutoBuyDunItem or "N/A", 3)
    end
})

-- ============================================================
-- TAB 3: OTHER
-- ============================================================
local Tab3            = Window:CreateTab(T("Other"), false, false)
local SItem           = Tab3:CreatePage(T("Sell Item / Status"))
local RandomM         = Tab3:CreatePage(T("Random Chest"))
local CraftTablePage  = Tab3:CreatePage(T("Craft Table"))
local GokuPage        = Tab3:CreatePage(T("Npc Goku Gods"))

local SellCard        = SItem:CreateSection(T("💰 Auto Sell"), "Left")
local StatusCard      = SItem:CreateSection(T("📊 Status"), "Right")

SellCard:Dropdown({
    Title = T("Select Sell Item"), Options = SellItems, Multi = true,
    Callback = function(v) _G.Select_SellItem = v end
})
SellCard:Toggle({Title = T("Auto Sell"), Value = false, Callback = function(v) _G.Auto_SellItem = v end})

StatusCard:Textbox({
    Title = T("Status Amount"), Placeholder = "1000", Value = "1000",
    Callback = function(v) _G.Amount = tonumber(v) or 1000 end
})
StatusCard:Toggle({Title = T("Auto Up Melee"), Value = false, Callback = function(v) _G.AutoMelee = v end})
StatusCard:Toggle({Title = T("Auto Up Defense"), Value = false, Callback = function(v) _G.AutoDefense = v end})
StatusCard:Toggle({Title = T("Auto Up Sword"), Value = false, Callback = function(v) _G.AutoSword = v end})
StatusCard:Toggle({Title = T("Auto Up Power"), Value = false, Callback = function(v) _G.AutoPower = v end})

local function FormatNumber(n)
    n = tonumber(n) or 0
    if n < 1000 then
        return tostring(math.floor(n))
    elseif n < 1000000 then
        return string.format("%.1fK", n / 1000)
    elseif n < 1000000000 then
        return string.format("%.1fM", n / 1000000)
    else
        return string.format("%.1fB", n / 1000000000)
    end
end

-- ============================================================
-- RANDOM CHEST
-- ============================================================
local DiamondChest     = RandomM:CreateSection(T("💎 Diamond Chest"), "Right")
local MoonChest        = RandomM:CreateSection(T("🌙 Moon Chest"), "Left")
local GuaranteeDiamond = RandomM:CreateSection(T("🎖️ Guarantee Gem Point"), "Right")
local GuaranteeMoon    = RandomM:CreateSection(T("☄️ Guarantee Moon Point"), "Left")

local DiamondChestInfo = DiamondChest:Paragraph({
    Title = "💎 Diamond: ---",
    Content = "📊 PointItem: ---"
})

DiamondChest:Dropdown({
    Title = T("Select Random Diamond Chest"),
    Options = RandomChestValue,
    Multi = false,
    Value = "x5",
    Callback = function(v)
        local val = type(v) == "table" and (next(v) or "x5") or v
        if type(val) ~= "string" then val = "x5" end
        _G.Select_Random = val
    end
})

DiamondChest:Button({
    Title = T("🎲 Mở 1 lần (Random Item)"),
    Callback = function()
        local val = _G.Select_Random or "x5"
        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "RandomItem", val)
        _G.SeaNotify("🎲 " .. T("Đã mở"), "RandomItem: " .. val, 2)
    end
})

DiamondChest:Toggle({
    Title = T("Auto Random Diamond Chest"),
    Value = false,
    Callback = function(v) _G.Auto_RandomChest = v end
})

local MoonChestInfo = MoonChest:Paragraph({
    Title = "🌙 MoonStone: ---",
    Content = "📊 MoonPoint: ---"
})

MoonChest:Dropdown({
    Title = T("Select Random Moon Chest"),
    Options = RandomChestValue,
    Multi = false,
    Value = "x5",
    Callback = function(v)
        local val = type(v) == "table" and (next(v) or "x5") or v
        if type(val) ~= "string" then val = "x5" end
        _G.Select_Random_Moon = val
    end
})

MoonChest:Button({
    Title = T("🌙 Mở 1 lần (Event Moon)"),
    Callback = function()
        local val = _G.Select_Random_Moon or "x5"
        local moonStone = tonumber(LocalPlayer:GetAttribute("MoonStone")) or 0

        local costMap = {["x5"] = 25, ["x10"] = 50, ["x15"] = 75}
        local cost = costMap[val] or 25

        if moonStone < cost then
            _G.SeaNotify("❌ " .. T("Không đủ MoonStone"), T("Cần") .. " " .. cost .. ", " .. T("có") .. " " .. FormatNumber(moonStone), 3)
            return
        end

        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "EventMoon", val)
        _G.SeaNotify("🌙 " .. T("Đã mở"), "EventMoon: " .. val .. " (-" .. cost .. " MoonStone)", 2)
    end
})

MoonChest:Toggle({
    Title = T("Auto Random Moon Chest"),
    Value = false,
    Callback = function(v) _G.Auto_RandomChest_Moon = v end
})

local GuaranteeDiamondInfo = GuaranteeDiamond:Paragraph({
    Title = "💎 Diamond: ---",
    Content = "📊 PointItem: ---"
})

local GuaranteeDiamondSelectInfo = GuaranteeDiamond:Paragraph({
    Title = T("Item: (chưa chọn)"),
    Content = T("Giá:") .. " ---"
})

GuaranteeDiamond:Dropdown({
    Title = T("Select Guarantee Diamond Point"),
    Options = Poitem,
    Multi = false,
    Callback = function(v)
        local val = type(v) == "table" and (next(v) or "") or v
        if type(val) ~= "string" then val = "" end
        _G.Select_Guarantee = val:match("^(.-) /") or val
    end
})

GuaranteeDiamond:Button({
    Title = T("💎 MUA 1 lần"),
    Callback = function()
        local itemName = _G.Select_Guarantee
        if not itemName or itemName == "" then
            _G.SeaNotify("❌ " .. T("Chưa chọn item"), T("Vui lòng chọn item trước!"), 3)
            return
        end

        if type(itemName) == "table" then
            for _, v in pairs(itemName) do
                if type(v) == "string" then itemName = v; break end
            end
        end
        itemName = tostring(itemName):match("^(.-) /") or tostring(itemName)
        itemName = itemName:gsub("^%s+", ""):gsub("%s+$", "")

        local pointItem = tonumber(LocalPlayer:GetAttribute("PointItem")) or 0
        local price = (PointItemM and PointItemM[itemName]) or 0

        if price <= 0 then
            _G.SeaNotify("❌ " .. T("Không tìm thấy"), "Item: " .. itemName, 3)
            return
        end

        if pointItem < price then
            _G.SeaNotify("❌ " .. T("Không đủ PointItem"), T("Cần") .. " " .. FormatNumber(price) .. ", " .. T("có") .. " " .. FormatNumber(pointItem), 3)
            return
        end

        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "BuyGaranteeRandomItem", itemName)
        _G.SeaNotify("✅ " .. T("Đã mua"), itemName .. " (-" .. FormatNumber(price) .. " Point)", 3)
    end
})

GuaranteeDiamond:Toggle({
    Title = T("Auto Buy Guarantee Diamond"),
    Value = false,
    Callback = function(v) _G.Auto_Guarantee = v end
})

local GuaranteeMoonInfo = GuaranteeMoon:Paragraph({
    Title = "🌙 MoonPoint: ---",
    Content = "💠 MoonStone: ---"
})

local GuaranteeMoonSelectInfo = GuaranteeMoon:Paragraph({
    Title = "🌙 " .. T("Item: (chưa chọn)"),
    Content = T("Giá:") .. " ---"
})

GuaranteeMoon:Dropdown({
    Title = T("Select Guarantee Moon Point"),
    Options = PoiteMoon,
    Multi = false,
    Callback = function(v)
        local val = type(v) == "table" and (next(v) or "") or v
        if type(val) ~= "string" then val = "" end
        _G.Select_Guarantee_Moon = val:match("^(.-) /") or val
    end
})

GuaranteeMoon:Button({
    Title = T("🌙 MUA 1 lần"),
    Callback = function()
        local itemName = _G.Select_Guarantee_Moon
        if not itemName or itemName == "" then
            _G.SeaNotify("❌ " .. T("Chưa chọn item"), T("Vui lòng chọn item trước!"), 3)
            return
        end

        if type(itemName) == "table" then
            for _, v in pairs(itemName) do
                if type(v) == "string" then itemName = v; break end
            end
        end
        itemName = tostring(itemName):match("^(.-) /") or tostring(itemName)
        itemName = itemName:gsub("^%s+", ""):gsub("%s+$", "")

        local moonPoint = tonumber(LocalPlayer:GetAttribute("MoonPoint")) or 0
        local price = (PointItemMoon and PointItemMoon[itemName]) or 0

        if price <= 0 then
            _G.SeaNotify("❌ " .. T("Không tìm thấy"), "Item: " .. itemName, 3)
            return
        end

        if moonPoint < price then
            _G.SeaNotify("❌ " .. T("Không đủ MoonPoint"), T("Cần") .. " " .. FormatNumber(price) .. ", " .. T("có") .. " " .. FormatNumber(moonPoint), 3)
            return
        end

        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "BuyGaranteeEventMoon", itemName)
        _G.SeaNotify("✅ " .. T("Đã mua"), itemName .. " (-" .. FormatNumber(price) .. " MoonPoint)", 3)
    end
})

GuaranteeMoon:Toggle({
    Title = T("Auto Buy Guarantee Moon"),
    Value = false,
    Callback = function(v) _G.Auto_Guarantee_Moon = v end
})

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local diamond   = tonumber(LocalPlayer:GetAttribute("Diamond")) or 0
            local pointItem = tonumber(LocalPlayer:GetAttribute("PointItem")) or 0
            local moonStone = tonumber(LocalPlayer:GetAttribute("MoonStone")) or 0
            local moonPoint = tonumber(LocalPlayer:GetAttribute("MoonPoint")) or 0

            DiamondChestInfo:SetTitle("💎 Diamond: " .. FormatNumber(diamond))
            DiamondChestInfo:SetContent("📊 PointItem: " .. FormatNumber(pointItem))

            MoonChestInfo:SetTitle("🌙 MoonStone: " .. FormatNumber(moonStone))
            MoonChestInfo:SetContent("📊 MoonPoint: " .. FormatNumber(moonPoint))

            GuaranteeDiamondInfo:SetTitle("💎 Diamond: " .. FormatNumber(diamond))
            GuaranteeDiamondInfo:SetContent("📊 PointItem: " .. FormatNumber(pointItem))

            GuaranteeMoonInfo:SetTitle("🌙 MoonPoint: " .. FormatNumber(moonPoint))
            GuaranteeMoonInfo:SetContent("💠 MoonStone: " .. FormatNumber(moonStone))

            if _G.Select_Guarantee and _G.Select_Guarantee ~= "" then
                local itemName = tostring(_G.Select_Guarantee):match("^(.-) /") or tostring(_G.Select_Guarantee)
                itemName = itemName:gsub("^%s+", ""):gsub("%s+$", "")
                local price = (PointItemM and PointItemM[itemName]) or 0
                local status = pointItem >= price and ("✅ " .. T("Đủ mua")) or ("❌ " .. T("Thiếu") .. " " .. FormatNumber(price - pointItem))
                GuaranteeDiamondSelectInfo:SetTitle("🎯 " .. itemName)
                GuaranteeDiamondSelectInfo:SetContent(T("Giá:") .. " " .. FormatNumber(price) .. " | " .. status)
            end

            if _G.Select_Guarantee_Moon and _G.Select_Guarantee_Moon ~= "" then
                local itemName = tostring(_G.Select_Guarantee_Moon):match("^(.-) /") or tostring(_G.Select_Guarantee_Moon)
                itemName = itemName:gsub("^%s+", ""):gsub("%s+$", "")
                local price = (PointItemMoon and PointItemMoon[itemName]) or 0
                local status = moonPoint >= price and ("✅ " .. T("Đủ mua")) or ("❌ " .. T("Thiếu") .. " " .. FormatNumber(price - moonPoint))
                GuaranteeMoonSelectInfo:SetTitle("🌙 " .. itemName)
                GuaranteeMoonSelectInfo:SetContent(T("Giá:") .. " " .. FormatNumber(price) .. " | " .. status)
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local Inv = GetInventory()
            local have = (Inv["Time Mystery Box"] and Inv["Time Mystery Box"].amount) or 0

            local function Fmt(n)
                n = tonumber(n) or 0
                if n < 1000 then return tostring(math.floor(n)) end
                if n < 1000000 then return string.format("%.1fK", n / 1000) end
                return string.format("%.1fM", n / 1000000)
            end

            if TimeMysteryInfo then
                TimeMysteryInfo:SetTitle("🎁 Time Mystery Box: " .. Fmt(have))
                TimeMysteryInfo:SetContent(
                    T("Số lượng mở:") .. " " .. tostring(_G.TimeMysteryAmount or 1) ..
                    " | " .. T("Có thể mở:") .. " " .. Fmt(have)
                )
            end
        end)
    end
end)

-- CRAFT TABLE
local CraftCard       = CraftTablePage:CreateSection(T("🔨 Craft Table"), "Left")
local CraftStatusCard = CraftTablePage:CreateSection(T("📊 Trạng Thái"), "Right")
local CraftInfoCard   = CraftTablePage:CreateSection(T("📋 Craft Info"), "Right")

local CraftMainPara = CraftInfoCard:Paragraph({
    Title = "🔨 " .. T("Chưa chọn Item"),
    Content = T("Chọn item để bắt đầu")
})

local CraftCanMakePara = CraftStatusCard:Paragraph({
    Title = "📊 " .. T("Số lần có thể chế: ---"),
    Content = T("Đợi chọn item")
})

local CraftGuaranteePara = CraftStatusCard:Paragraph({
    Title = "🎁 " .. T("Guarantee: ---/---"),
    Content = T("Đợi chọn item")
})

_G.SelectedCraftItem = nil
_G.CraftDelay = 2.0

local CraftCountSinceClaim = 0
local LastCraftTimeSync = 0

local function GetAllCraftItems()
    local items = {}
    if not CraftingTable then return items end
    pcall(function()
        for name, data in pairs(CraftingTable) do
            if data.need then table.insert(items, name) end
        end
    end)
    table.sort(items)
    return items
end

local function GetMaxCraftTimes(itemName)
    if not itemName or itemName == "" then return 0 end
    if not CraftingTable then return 0 end

    local Data = CraftingTable[itemName]
    if not Data or not Data.need then return 0 end

    local minCraft = math.huge
    for Item, Need in pairs(Data.need) do
        if Need > 0 then
            local have = GetItemAmount(Item)
            local can = math.floor(have / Need)
            if can < minCraft then minCraft = can end
        end
    end

    if minCraft == math.huge then return 0 end
    return minCraft
end

local function GetGuaranteeCount(itemName)
    if not itemName or itemName == "" then return 0, 0 end

    local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
    if not hud or not hud:FindFirstChild("Main") then return 0, 0 end

    local guar = hud.Main:FindFirstChild("Frame_Guarantee")
    if not guar then return 0, 0 end

    local sf = guar:FindFirstChild("ScrollingFrame")
    if not sf then return 0, 0 end

    local itemFrame = sf:FindFirstChild(itemName)
    if not itemFrame then return 0, 0 end

    local main = itemFrame:FindFirstChild("Main")
    if not main then return 0, 0 end

    local amtLbl = main:FindFirstChild("AmountLabel")
    if not amtLbl then return 0, 0 end

    local txt = amtLbl.Text or ""
    local cur = tonumber(txt:match("^(%d+)")) or 0
    local max = tonumber(txt:match("/(%d+)")) or 0

    return cur, max
end

local function HasGuaranteeItemReady(itemName)
    local cur, max = GetGuaranteeCount(itemName)
    if max > 0 and cur >= max then return true end
    return false
end

local function ClaimGuaranteeItem(itemName)
    if not itemName or itemName == "" then return false end
    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "CraftTable", itemName, "Guarantee")
    return true
end

local function BuildCraftInfo(itemName)
    if not itemName or itemName == "" then
        return "🔨 " .. T("Chưa chọn Item"), T("Chọn item để bắt đầu")
    end

    if not CraftingTable or not CraftingTable[itemName] then
        return "❌ " .. T("Không tìm thấy Item"), itemName
    end

    local Data = CraftingTable[itemName]
    if not Data or not Data.need then
        return "❌ " .. T("Không có công thức"), itemName
    end

    local text = "📋 " .. T("Công thức:") .. "\n"
    local maxCraft = math.huge

    for Item, Need in pairs(Data.need) do
        local have = GetItemAmount(Item)
        local can = Need > 0 and math.floor(have / Need) or 0
        if Need > 0 and can < maxCraft then maxCraft = can end

        local status = have >= Need and "✅" or "❌"
        text = text .. string.format("  %s %s: %d/%d\n", status, Item, have, Need)
    end

    if maxCraft == math.huge then maxCraft = 0 end

    text = text .. "\n🔨 " .. T("Có thể chế:") .. " " .. maxCraft .. " " .. T("lần")

    return "🔨 " .. itemName, text
end

CraftCard:Dropdown({
    Title = T("Chọn Items để chế tạo"),
    Options = GetAllCraftItems(),
    Multi = false,
    Callback = function(Value)
        _G.SelectedCraftItem = Value
    end
})

CraftCard:Toggle({
    Title = T("🔨 Auto Chế Tạo"),
    Value = false,
    Callback = function(v)
        _G.AutoCraftRunning = v
    end
})

CraftInfoCard:Toggle({
    Title = T("✅ Auto Claim Guarantee (Ưu tiên cao)"),
    Value = true,
    Callback = function(v)
        _G.AutoClaimGuarantee = v
    end
})

local CraftSpeedPara = CraftCard:Paragraph({
    Title = T("⏱️ Tốc độ hiện tại: 2.00s/lần"),
    Content = T("🟢 Rất an toàn")
})

local function UpdateSpeedDisplay()
    local speed = _G.CraftDelay or 1.0

    local status
    if speed <= 0.3 then
        status = "🔴 CỰC NHANH — Rất dễ phí"
    elseif speed <= 0.5 then
        status = "🟡 Nhanh — Có thể phí"
    elseif speed <= 1.0 then
        status = "🟢 An toàn (khuyến nghị)"
    elseif speed <= 2.0 then
        status = "🟢 Rất an toàn"
    elseif speed <= 5.0 then
        status = "🟢 Cực kỳ an toàn (chậm)"
    else
        status = "🔵 Siêu chậm — Chỉ dùng khi ping cao"
    end

    CraftSpeedPara:SetTitle("⏱️ " .. T("Tốc độ hiện tại: 2.00s/lần"):gsub("2%.00", string.format("%.2f", speed)))
    CraftSpeedPara:SetContent(status)
end

UpdateSpeedDisplay()

CraftCard:Button({
    Title = T("🟢 An toàn (0.5s)"),
    Callback = function()
        _G.CraftDelay = 0.5
        UpdateSpeedDisplay()
        _G.SeaNotify("⏱️ " .. T("Đổi tốc độ"), "0.5s — " .. T("An toàn"), 2)
    end
})

CraftCard:Button({
    Title = T("🟢 Rất an toàn (1.0s)"),
    Callback = function()
        _G.CraftDelay = 1.0
        UpdateSpeedDisplay()
        _G.SeaNotify("⏱️ " .. T("Đổi tốc độ"), "1.0s — " .. T("Rất an toàn"), 2)
    end
})

CraftCard:Button({
    Title = T("🟢 Cực an toàn (2.0s)"),
    Callback = function()
        _G.CraftDelay = 2.0
        UpdateSpeedDisplay()
        _G.SeaNotify("⏱️ " .. T("Đổi tốc độ"), "2.0s — " .. T("Cực an toàn"), 2)
    end
})

CraftCard:Button({
    Title = T("🔵 Siêu chậm (5.0s)"),
    Callback = function()
        _G.CraftDelay = 5.0
        UpdateSpeedDisplay()
        _G.SeaNotify("⏱️ " .. T("Đổi tốc độ"), "5.0s — " .. T("Siêu chậm"), 2)
    end
})

CraftCard:Paragraph({
    Title = T("📖 Hướng dẫn tốc độ"),
    Content = T("🟢 0.5-1.0s: An toàn (khuyến nghị)\n🟢 1.0-2.0s: Rất an toàn\n🟢 2.0-5.0s: Cực an toàn\n🔵 5.0s+: Chỉ dùng khi ping cao\n\n💡 Nếu vẫn phí → chọn mức 2.0s hoặc 5.0s")
})

task.spawn(function()
    local lastGuaranteeFire = 0
    local GUARANTEE_FIRE_DELAY = 0.3

    while task.wait(0.05) do
        if not _G.AutoClaimGuarantee then continue end
        if not _G.AutoCraftRunning then continue end
        if not _G.SelectedCraftItem or _G.SelectedCraftItem == "" then continue end

        local now = tick()
        local cur, max = GetGuaranteeCount(_G.SelectedCraftItem)

        if max > 0 and cur >= max then
            if now - lastGuaranteeFire >= GUARANTEE_FIRE_DELAY then
                lastGuaranteeFire = now
                ClaimGuaranteeItem(_G.SelectedCraftItem)
            end
        end
    end
end)

task.spawn(function()
    local lastCraftTime = 0
    local lastUICheck = 0
    local phase = "waiting"
    local UI_UPDATE_DELAY = 0.3
    local GUARANTEE_CLEAR_WAIT = 0.5

    while task.wait(0.05) do
        local now = tick()

        if now - lastUICheck >= UI_UPDATE_DELAY then
            lastUICheck = now

            if _G.SelectedCraftItem and _G.SelectedCraftItem ~= "" then
                local title, content = BuildCraftInfo(_G.SelectedCraftItem)
                CraftMainPara:SetTitle(title)
                CraftMainPara:SetContent(content)

                local canMake = GetMaxCraftTimes(_G.SelectedCraftItem)
                local cur, max = GetGuaranteeCount(_G.SelectedCraftItem)

                local statusIcon = "⏸️"
                if phase == "crafting" then statusIcon = "🔨"
                elseif phase == "waiting_guarantee" then statusIcon = "🛑"
                elseif phase == "syncing" then statusIcon = "🔄"
                elseif phase == "waiting" then statusIcon = "⏸️" end

                CraftCanMakePara:SetTitle(statusIcon .. " " .. T("Có thể chế:") .. " " .. canMake .. " " .. T("lần"))

                if phase == "crafting" then
                    local timeLeft = math.max(0, (_G.CraftDelay or 1.0) - (now - lastCraftTime))
                    CraftCanMakePara:SetContent("▶️ " .. T("ĐANG CHẾ TẠO") .. " — " .. T("lần") .. " " .. CraftCountSinceClaim ..
                        " | " .. T("Đợi:") .. " " .. string.format("%.1fs", timeLeft))
                elseif phase == "waiting_guarantee" then
                    CraftCanMakePara:SetContent("🛑 " .. T("CHỜ CLAIM GUARANTEE"))
                elseif phase == "syncing" then
                    CraftCanMakePara:SetContent("🔄 " .. T("Đợi server..."))
                elseif phase == "waiting" then
                    CraftCanMakePara:SetContent("⏸️ " .. T("Đang chờ"))
                end

                if max > 0 then
                    local gIcon = cur >= max and "🛑" or "🎁"
                    CraftGuaranteePara:SetTitle(gIcon .. " " .. T("Guarantee:") .. " " .. cur .. "/" .. max)
                    if cur >= max then
                        CraftGuaranteePara:SetContent("⛔ " .. T("ĐÃ ĐẦY — Đang claim..."))
                    else
                        CraftGuaranteePara:SetContent("✅ " .. T("Còn") .. " " .. (max - cur) .. " " .. T("slot trống"))
                    end
                else
                    CraftGuaranteePara:SetTitle("🎁 " .. T("Guarantee: ---/---"))
                    CraftGuaranteePara:SetContent(T("Chưa có item nào"))
                end
            else
                CraftMainPara:SetTitle("🔨 " .. T("Chưa chọn Item"))
                CraftMainPara:SetContent(T("Chọn item để bắt đầu"))
                CraftCanMakePara:SetTitle("📊 " .. T("Số lần có thể chế: ---"))
                CraftCanMakePara:SetContent(T("Đợi chọn item"))
                CraftGuaranteePara:SetTitle("🎁 " .. T("Guarantee: ---/---"))
                CraftGuaranteePara:SetContent(T("Đợi chọn item"))
            end
        end

        if not _G.AutoCraftRunning then
            if phase ~= "waiting" then
                phase = "waiting"
                CraftCountSinceClaim = 0
            end
            continue
        end

        if not _G.SelectedCraftItem or _G.SelectedCraftItem == "" then
            continue
        end

        local Data = CraftingTable and CraftingTable[_G.SelectedCraftItem]
        if not Data or not Data.need then
            continue
        end

        local cur, max = GetGuaranteeCount(_G.SelectedCraftItem)

        if max > 0 and cur >= max then
            if phase ~= "waiting_guarantee" then
                phase = "waiting_guarantee"
            end
            continue
        end

        if phase == "waiting_guarantee" and (max == 0 or cur < max) then
            phase = "syncing"
            _G.LastSyncTime = now
            CraftCountSinceClaim = 0
            lastCraftTime = now
            continue
        end

        if phase == "syncing" then
            if now - (_G.LastSyncTime or 0) >= GUARANTEE_CLEAR_WAIT then
                phase = "waiting"
                lastCraftTime = now
            end
            continue
        end

        local CanCraft = true
        for Item, Need in pairs(Data.need) do
            if GetItemAmount(Item) < Need then
                CanCraft = false
                break
            end
        end

        if not CanCraft then
            if phase ~= "waiting" then
                phase = "waiting"
            end
            task.wait(0.5)
            continue
        end

        local craftDelay = tonumber(_G.CraftDelay) or 1.0
        if craftDelay < 0.1 then craftDelay = 0.1 end

        local timeSinceLastCraft = now - lastCraftTime

        if timeSinceLastCraft >= craftDelay then
            lastCraftTime = now
            phase = "crafting"
            CraftCountSinceClaim = CraftCountSinceClaim + 1

            ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "CraftTable", _G.SelectedCraftItem, "Craft")
        end
    end
end)

-- ============================================================
-- GOKU NPC
-- ============================================================
local GokuCurrentCard = GokuPage:CreateSection(T("📍 NPC Đang Có"), "Left")
local GokuActionCard  = GokuPage:CreateSection(T("⚙️ Actions"), "Right")

local GokuCurrentPara = GokuCurrentCard:Paragraph({
    Title = T("Npc Count: 0 / 5"),
    Content = T("Đang tìm NPC...")
})

local GOKU_NPC_KEYWORDS   = {"goku", "vegeta", "gohan", "goten", "trunk", "bardock"}
local MAX_NPC_PER_SESSION = 5
local MISS_THRESHOLD      = 5

_G.AutoGokuFind = false
_G.AutoGokuTP   = false

local GokuSpawnData       = {}
local SessionSpawnedCount = 0
local SessionNPCSpawned   = {}
local IgnoreNPCSpawned    = {}

local function FormatDuration(sec)
    sec = math.max(0, math.floor(sec))
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then return string.format("%02d:%02d:%02d", h, m, s) end
    return string.format("%02d:%02d", m, s)
end

local function FormatClock(t)
    local d = os.date("*t", t)
    return string.format("%02d:%02d:%02d", d.hour, d.min, d.sec)
end

local function ResetGokuSession(reason)
    for npcName in pairs(SessionNPCSpawned) do
        IgnoreNPCSpawned[npcName] = true
    end
    GokuSpawnData       = {}
    SessionSpawnedCount = 0
    SessionNPCSpawned   = {}
    _G.SeaNotify("🔄 " .. T("Reset phiên NPC"), reason or T("Đã đủ 5 NPC"), 5)
end

local function ScanGokuNPCs()
    local results = {}
    local powerGod = workspace:FindFirstChild("Power God")
    if not powerGod then return results end

    local char   = LocalPlayer.Character
    local myHrp  = char and char:FindFirstChild("HumanoidRootPart")
    local now    = tick()

    if SessionSpawnedCount >= MAX_NPC_PER_SESSION then
        ResetGokuSession(T("Đủ 5 NPC — reset phiên"))
        return results
    end

    for _, obj in ipairs(powerGod:GetChildren()) do
        if obj:IsA("Model") then
            local lower   = obj.Name:lower()
            local matched = false
            for _, kw in ipairs(GOKU_NPC_KEYWORDS) do
                if lower:find(kw) then matched = true; break end
            end
            if matched then
                local hrp    = obj:FindFirstChild("HumanoidRootPart")
                local hum    = obj:FindFirstChild("Humanoid")
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                local dist   = (myHrp and hrp) and (myHrp.Position - hrp.Position).Magnitude or -1

                local data = GokuSpawnData[obj.Name]
                if not data then
                    local isNewNPC = not IgnoreNPCSpawned[obj.Name] and not SessionNPCSpawned[obj.Name]
                    data = {firstSeenAt = now, spawnClock = os.time(), lastSeen = now, isAlive = true}
                    GokuSpawnData[obj.Name] = data

                    if isNewNPC then
                        SessionNPCSpawned[obj.Name] = true
                        SessionSpawnedCount = SessionSpawnedCount + 1
                        _G.SeaNotify("🎯 " .. T("NPC Spawn!"), obj.Name .. " (" .. SessionSpawnedCount .. "/" .. MAX_NPC_PER_SESSION .. ")", 5)
                    end
                else
                    data.lastSeen = now
                    if not data.isAlive then
                        data.isAlive    = true
                        data.firstSeenAt = now
                        data.spawnClock  = os.time()
                        if IgnoreNPCSpawned[obj.Name] then
                            IgnoreNPCSpawned[obj.Name] = nil
                        end
                        if not SessionNPCSpawned[obj.Name] and SessionSpawnedCount < MAX_NPC_PER_SESSION then
                            SessionNPCSpawned[obj.Name] = true
                            SessionSpawnedCount = SessionSpawnedCount + 1
                            _G.SeaNotify("🎯 " .. T("NPC Respawn!"), obj.Name .. " (" .. SessionSpawnedCount .. "/" .. MAX_NPC_PER_SESSION .. ")", 5)
                        else
                            _G.SeaNotify("🎯 " .. T("NPC Respawn!"), obj.Name .. " " .. T("quay lại!"), 5)
                        end
                    end
                end

                table.insert(results, {
                    Name = obj.Name, Model = obj,
                    Position = hrp and hrp.Position or Vector3.zero,
                    Health = hum and hum.Health or 0,
                    HasPrompt = prompt ~= nil,
                    PromptText = prompt and prompt.ActionText or "N/A",
                    Distance = dist, Prompt = prompt,
                    SpawnClock = data.spawnClock, Elapsed = now - data.firstSeenAt
                })
            end
        end
    end

    for name, data in pairs(GokuSpawnData) do
        if now - data.lastSeen > MISS_THRESHOLD and data.isAlive then
            data.isAlive = false
        end
    end

    table.sort(results, function(a, b)
        if a.Distance < 0 then return false end
        if b.Distance < 0 then return true end
        return a.Distance < b.Distance
    end)
    return results
end

local function RenderGokuCurrent(npcs)
    local text = {}
    table.insert(text, T("Phiên:") .. " " .. SessionSpawnedCount .. "/" .. MAX_NPC_PER_SESSION)
    table.insert(text, T("Đang có mặt:") .. " " .. #npcs)
    table.insert(text, "─────────────────")
    if #npcs == 0 then
        table.insert(text, "❌ " .. T("Không có NPC nào"))
    else
        for i, npc in ipairs(npcs) do
            local distText = npc.Distance >= 0 and string.format("%.0f studs", npc.Distance) or "?"
            table.insert(text, string.format(
                "%d. %s\n   ⏰ %s (" .. T("đã") .. " %s)\n   📏 %s | ❤️ %d\n   🖱️ %s (%s)",
                i, npc.Name, FormatClock(npc.SpawnClock), FormatDuration(npc.Elapsed),
                distText, npc.Health, npc.HasPrompt and "✅" or "❌", npc.PromptText
            ))
        end
    end
    GokuCurrentPara:SetTitle(T("Npc Count:") .. " " .. SessionSpawnedCount .. " / " .. MAX_NPC_PER_SESSION)
    GokuCurrentPara:SetContent(table.concat(text, "\n"))
end

local function ClickGokuNPC(npcData)
    if not npcData or not npcData.Model or not npcData.Model.Parent then return false end
    local prompt = npcData.Prompt
    if not prompt or not prompt.Parent then return false end
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    hrp.CFrame = CFrame.new(npcData.Position + Vector3.new(0, 5, 0))
    task.wait(0.2)
    pcall(function() fireproximityprompt(prompt) end)
    return true
end

GokuActionCard:Toggle({
    Title = T("🎯 Auto Find & Click NPC"), Value = false,
    Callback = function(Value)
        _G.AutoGokuFind = Value
        _G.SeaNotify(Value and ("▶️ " .. T("Bật Auto Goku")) or ("⏹️ " .. T("Tắt Auto Goku")), T("Tự động tìm + click"), 3)
    end
})
GokuActionCard:Toggle({
    Title = T("✈️ Auto TP Nearest NPC"), Value = false,
    Callback = function(Value)
        _G.AutoGokuTP = Value
        _G.SeaNotify(Value and ("▶️ " .. T("Bật Auto TP")) or ("⏹️ " .. T("Tắt Auto TP")), T("TP tới NPC gần nhất"), 3)
    end
})

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local npcs = ScanGokuNPCs()
            RenderGokuCurrent(npcs)

            if _G.AutoGokuTP and #npcs > 0 then
                local npc = npcs[1]
                if npc.Model and npc.Model.Parent then
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.CFrame = CFrame.new(npc.Position + Vector3.new(0, 5, 0)) end
                end
            end

            if _G.AutoGokuFind and #npcs > 0 then
                for _, npc in ipairs(npcs) do
                    if npc.HasPrompt then
                        ClickGokuNPC(npc)
                        task.wait(1)
                        break
                    end
                end
            end
        end)
    end
end)

-- ============================================================
-- TAB 4: TELEPORT
-- ============================================================
local TabTP    = Window:CreateTab(T("Teleport"), false, false)
local TPPage   = TabTP:CreatePage(T("Teleport Sea 1"))
local IslandCard = TPPage:CreateSection(T("🏝️ Đảo Sea 1"), "Left")
local SeaCard    = TPPage:CreateSection(T("🌊 Sea Travel"), "Right")
local TPInfoCard = TPPage:CreateSection(T("📊 Thông Tin"), "Right")

local IslandCache    = {}
local IslandList     = {}
local SelectedIsland = nil

local TPInfoPara = TPInfoCard:Paragraph({Title = "Sea 1", Content = T("Đang load...")})
local SeaInfoPara = SeaCard:Paragraph({Title = T("Sea"), Content = T("Đang load...")})

local function ScanIslands()
    IslandCache = {}
    IslandList  = {}
    local islandFolder = workspace:FindFirstChild("island")
    if not islandFolder then return end

    local orderMap = {}
    local gates    = workspace:FindFirstChild("Gates")
    local tpPart   = gates and gates:FindFirstChild("TeleportPart")
    if tpPart then
        for i, part in ipairs(tpPart:GetChildren()) do
            if part:IsA("BasePart") then orderMap[part.Name] = i end
        end
    end

    local tempList = {}
    for _, obj in ipairs(islandFolder:GetChildren()) do
        if obj:IsA("Model") then
            local hrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            IslandCache[obj.Name] = {model = obj, pos = hrp and hrp.Position or Vector3.zero}
            table.insert(tempList, obj.Name)
        end
    end

    table.sort(tempList, function(a, b)
        local ia, ib = orderMap[a], orderMap[b]
        if ia and ib then return ia < ib end
        if ia and not ib then return true end
        if not ia and ib then return false end
        return a < b
    end)
    IslandList = tempList
end

ScanIslands()

IslandCard:Dropdown({
    Title = T("🏝️ Chọn Đảo Sea 1"), Options = IslandList, Multi = false,
    Callback = function(Value)
        SelectedIsland = Value
        local data = IslandCache[Value]
        if data then
            local char  = LocalPlayer.Character
            local myHrp = char and char:FindFirstChild("HumanoidRootPart")
            local dist  = myHrp and string.format("%.0f studs", (myHrp.Position - data.pos).Magnitude) or "?"
            TPInfoPara:SetTitle(T("Đảo:") .. " " .. Value)
            TPInfoPara:SetContent(string.format("📌 %.0f, %.0f, %.0f\n📏 %s", data.pos.X, data.pos.Y, data.pos.Z, dist))
        end
    end
})
IslandCard:Button({
    Title = T("✈️ Dịch Chuyển Tới Đảo"),
    Callback = function()
        if not SelectedIsland then
            _G.SeaNotify("❌ " .. T("Chưa chọn đảo"), T("Chọn 1 đảo trước!"), 3); return
        end
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then _G.SeaNotify("❌ " .. T("Không có nhân vật"), T("Character chưa load"), 3); return end

        local gates  = workspace:FindFirstChild("Gates")
        local tpPart = gates and gates:FindFirstChild("TeleportPart")
        local target = tpPart and tpPart:FindFirstChild(SelectedIsland)
        if target then
            hrp.CFrame = CFrame.new(target.Position + Vector3.new(0, 5, 0))
            _G.SeaNotify("✈️ " .. T("Đã kích hoạt"), SelectedIsland .. " (TeleportPart)", 3)
        else
            local data = IslandCache[SelectedIsland]
            if data and data.pos then
                hrp.CFrame = CFrame.new(data.pos + Vector3.new(0, 5, 0))
                _G.SeaNotify("✈️ " .. T("Đã kích hoạt"), SelectedIsland .. " (Model pos)", 3)
            else
                _G.SeaNotify("❌ " .. T("Không tìm thấy"), SelectedIsland, 3)
            end
        end
    end
})
SeaCard:Button({
    Title = T("🌊 Đi Tới Sea 2 (2SeaSoon)"),
    Callback = function()
        local seaNPC = workspace:FindFirstChild("2SeaSoon")
        if not seaNPC then
            _G.SeaNotify("❌ " .. T("Không tìm thấy NPC Sea 2"), T("workspace.2SeaSoon không có"), 3); return
        end
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local npcHrp = seaNPC:FindFirstChild("HumanoidRootPart") or seaNPC:FindFirstChildWhichIsA("BasePart")
        if npcHrp then
            hrp.CFrame = CFrame.new(npcHrp.Position + Vector3.new(0, 5, 0))
            _G.SeaNotify("🌊 " .. T("Đã tới NPC Sea 2"), T("Chờ game chuyển Sea..."), 5)
            task.wait(0.5)
            local prompt = seaNPC:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then pcall(function() fireproximityprompt(prompt) end) end
        end
    end
})

-- ============================================================
-- TAB 5: CONFIG
-- ============================================================
local ConfigTab = Window:CreateTab(T("Config"), false, false)
MySaveManager:BuildConfigTab(ConfigTab)
task.spawn(function()
    task.wait(1)
    MySaveManager:LoadAutoloadConfig()
end)

-- ============================================================
-- BACKGROUND LOOPS
-- ============================================================
task.spawn(function()
    while task.wait(0.1) do
        if _G.AutoMelee then
            ReplicatedStorage.Remotes.System:FireServer("UpStats", "Melee", _G.Amount)
        end
        if _G.AutoDefense then
            ReplicatedStorage.Remotes.System:FireServer("UpStats", "Defense", _G.Amount)
        end
        if _G.AutoSword then
            ReplicatedStorage.Remotes.System:FireServer("UpStats", "Sword", _G.Amount)
        end
        if _G.AutoPower then
            ReplicatedStorage.Remotes.System:FireServer("UpStats", "Power", _G.Amount)
        end
    end
end)

task.spawn(function()
    while task.wait() do
        pcall(function()
            local Text = {}
            for Name, MobName in pairs(SpawnList) do
                local Spawned = false
                local Names = {MobName}
                if MobName == "Devil Boat" then table.insert(Names, "DevilBoat") end
                for _, n in ipairs(Names) do
                    if workspace.Mob and workspace.Mob:FindFirstChild(n) then Spawned = true; break end
                end
                table.insert(Text, Name .. ": " .. (Spawned and "✅" or "❌"))
            end
            Spawn_Status:SetContent(table.concat(Text, "\n"))
        end)
    end
end)

task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Select_Method == "Behind" then
                MethodFarm = CFrame.new(0, 0, _G.Distance_Farm)
            elseif _G.Select_Method == "Front" then
                MethodFarm = CFrame.new(0, 0, -_G.Distance_Farm) * CFrame.Angles(0, math.rad(180), 0)
            elseif _G.Select_Method == "Below" then
                MethodFarm = CFrame.new(0, -_G.Distance_Farm, 0) * CFrame.Angles(math.rad(90), 0, 0)
            else
                MethodFarm = CFrame.new(0, _G.Distance_Farm, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if not _G.Auto_RandomChest_Moon then return end

            local moonStone = tonumber(LocalPlayer:GetAttribute("MoonStone")) or 0
            local selectVal = _G.Select_Random_Moon or "x5"

            local costMap = {["x5"] = 25, ["x10"] = 50, ["x15"] = 75}
            local cost = costMap[selectVal] or 25

            if moonStone >= cost then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "EventMoon", selectVal)
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if not _G.Auto_RandomChest then return end

            local selectVal = _G.Select_Random or "x5"
            local event = ReplicatedStorage.Modules.NetworkFramework.NetworkEvent

            event:FireServer("fire", nil, "RandomItem", selectVal)
        end)
    end
end)

task.spawn(function()
    while task.wait() do
        xpcall(function()
            if _G.Auto_SellItem and type(_G.Select_SellItem) == "table" then
                for ItemName, Selected in pairs(_G.Select_SellItem) do
                    local Data = Economy and Economy[ItemName]
                    if Selected and Data and GetItemAmount(ItemName) >= Data.amount then
                        ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Economy", ItemName)
                    end
                end
            end
        end, print)
    end
end)

task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_Haki then
                if LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("HakiFolder") then
                    ReplicatedStorage.Remotes.Action:FireServer("Misc", "buso")
                end
            end
        end)
    end
end)

-- ============================================================
-- 🆕 AUTO SKILL LOOP v123 — CHỈ SPAM KHI ĐANG ĐÁNH
-- ============================================================
task.spawn(function()
    while task.wait(0.1) do
        local hasAuto = _G.Auto_Farm_Level or _G.Auto_Farm_Material or _G.Auto_FarmBoss
                     or _G.Auto_FarmBoss_Automatically or _G.Auto_Duck or _G.Auto_DuckAutomatically
                     or _G.Auto_Piccolo or _G.Auto_DevilBoat or _G.Auto_CraftWeapon
                     or _G.Auto_Farm_Set or _G.Auto_Raid or _G.Auto_BaconThief or _G.Auto_Dungeon
                     or _G.AutoRaidRunning or _G.Auto_Kraken

        if hasAuto and _G.CanAutoSkill == true then
            pcall(function() AutoSkill() end)
        end
    end
end)

-- AUTO POTION
task.spawn(function()
    while task.wait(0.3) do
        if _G.Auto_Use_Potion then
            pcall(function()
                local Inv    = ReplicatedStorage.Remotes.Inventory
                local Select = _G.Select_Potion
                if not Select then return end
                if Select["X2 EXP 15min."]     and tonumber(LocalPlayer:GetAttribute("x2ExpTime")) == 0     then Inv:FireServer("X2 EXP 15min.") end
                if Select["X2 Diamond 15min."] and tonumber(LocalPlayer:GetAttribute("x2DiamondTime")) == 0 then Inv:FireServer("X2 Diamond 15min.") end
                if Select["X2 Lucky 15min."]   and tonumber(LocalPlayer:GetAttribute("x2LuckTime")) == 0    then Inv:FireServer("X2 Lucky 15min.") end
                if Select["X2 Rebirth 15min."] and tonumber(LocalPlayer:GetAttribute("x2RebirthTime")) == 0 then Inv:FireServer("X2 Rebirth 15min.") end
                if Select["X2 Item 15min."]    and tonumber(LocalPlayer:GetAttribute("x2ItemTime")) == 0    then Inv:FireServer("X2 Item 15min.") end
            end)
        end
    end
end)

-- AUTO EQUIP ACCESSORY
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if not _G.Auto_Equip_Accessory or not AccessoryModule then return end
            local Inventory = HttpService:JSONDecode(LocalPlayer:GetAttribute("Inventory") or "{}")
            local Equipped  = HttpService:JSONDecode(LocalPlayer:GetAttribute("UseAccessory") or "{}")
            local Best = {}
            for Name in pairs(Inventory) do
                local Info = AccessoryModule[Name]
                if Info then
                    local Score = 0
                    for _, Value in pairs(Info) do
                        if type(Value) == "number" then Score = Score + Value end
                    end
                    if not Best[Info.Type] or Score > Best[Info.Type].Score then
                        Best[Info.Type] = {Name = Name, Score = Score}
                    end
                end
            end
            for Type, Data in pairs(Best) do
                local EquippedName
                for Name, Info in pairs(Equipped) do
                    if Info.Type == Type then EquippedName = Name; break end
                end
                if EquippedName ~= Data.Name then
                    ReplicatedStorage.Remotes.Inventory:FireServer(Data.Name)
                    task.wait(0.5)
                end
            end
        end)
    end
end)

-- AUTO REBIRTH
task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_Rebirth then
                if LocalPlayer.PlayerGui.HUD.Main.Frame_Display.LevelText.Text:lower():find("max") then
                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Rebirth")
                end
            end
        end)
    end
end)

-- GUARANTEE AUTO BUY
task.spawn(function()
    while task.wait() do
        if _G.Auto_Guarantee_Moon and PointItemMoon then
            local Point = tonumber(LocalPlayer:GetAttribute("MoonPoint")) or 0
            local Price = PointItemMoon[_G.Select_Guarantee_Moon] or 0
            if _G.Select_Guarantee_Moon and Point >= Price then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "BuyGaranteeEventMoon", _G.Select_Guarantee_Moon)
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if not _G.Auto_Guarantee then return end
            if not _G.Select_Guarantee or _G.Select_Guarantee == "" then return end

            local pointItem = tonumber(LocalPlayer:GetAttribute("PointItem")) or 0

            local itemName = _G.Select_Guarantee
            if type(itemName) == "table" then
                for _, v in pairs(itemName) do
                    if type(v) == "string" then
                        itemName = v
                        break
                    end
                end
            end
            if type(itemName) ~= "string" then return end

            itemName = itemName:match("^(.-) /") or itemName
            itemName = itemName:gsub("^%s+", ""):gsub("%s+$", "")

            local price = PointItemM[itemName] or 0

            if price > 0 and pointItem >= price then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "BuyGaranteeRandomItem", itemName)
            end
        end)
    end
end)

-- SHOP DUNGEON LOOPS
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local ptAttr = LocalPlayer:GetAttribute("DungeonPoint") or 0
            ShopDunInfoPara:SetTitle("DungeonPoint: " .. tostring(ptAttr))
            local items = GetAllShopDunItems()
            if #items > 0 then UpdateDunDropdown(items) end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if _G.AutoBuyDunRunning and _G.AutoBuyDunItem then
            pcall(function()
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "BuyDungeonShop", _G.AutoBuyDunItem)
                task.wait(0.2)
            end)
        end
    end
end)

-- SHOP RAID LOOP
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            if not hud or not hud:FindFirstChild("Main") then return end
            local shop = hud.Main:FindFirstChild("Frame_ShopRaid")
            if not shop then return end

            local rpLbl    = shop:FindFirstChild("RaidPoint")
            local resetLbl = shop:FindFirstChild("Reset")
            if rpLbl and resetLbl then
                ShopInfoPara:SetTitle(rpLbl.Text)
                ShopInfoPara:SetContent(resetLbl.Text)
            end

            local sf = shop:FindFirstChild("ScrollingFrame")
            if sf then
                local items = {}
                for _, item in pairs(sf:GetChildren()) do
                    if item:IsA("Frame") then
                        local label = item:FindFirstChild("Label")
                        if label and label.Text and label.Text ~= "" and label.Text ~= "Item" then
                            table.insert(items, label.Text)
                        end
                    end
                end
                if #items > 0 then
                    table.sort(items)
                    UpdateShopDropdown(items)
                end
            end
        end)
    end
end)

-- AUTO FARM LEVEL
task.spawn(function()
    while wait() do
        xpcall(function()
            if not _G.Auto_Farm_Level then return end
            local quest = GetQuest_Level(tonumber(LocalPlayer:GetAttribute("Level")))
            if not quest then return end
            local Frame = GetQuestFrame()
            local Text  = Frame.Title.Text or ""
            if LocalPlayer.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
            end
            if Frame.Visible and not string.find(Text, quest.Monster) then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                repeat task.wait() until not Frame.Visible
            end
            if not Frame.Visible then
                _G.CanAutoSkill = false

                local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
                if npc then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = CFrame.new(npc.Position + Vector3.new(0, 3, 0))
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end

                    task.wait(0.4)

                    local prompt = npc:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then
                        pcall(function()
                            fireproximityprompt(prompt, prompt.HoldDuration + 0.1)
                        end)
                        task.wait(0.2)
                        pcall(function()
                            fireproximityprompt(prompt, prompt.HoldDuration + 0.1)
                        end)
                    end
                end
            else
                for _, v in pairs(workspace.Mob:GetChildren()) do
                    if v:IsA("Model") and v.Name == quest.Monster and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        local hrp = v:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0

                            _G.CanAutoSkill = true

                            repeat task.wait(0.03)
                                EquipWeapon()
                                AutoSkill()
                                Attack()
                                Teleport(hrp.CFrame * MethodFarm)
                            until not _G.Auto_Farm_Level or v.Humanoid.Health <= 0

                            _G.CanAutoSkill = false
                        end
                        break
                    end
                end
            end
        end, print)
    end
end)

-- ============================================================
-- 🆕 AUTO FARM MATERIAL v106
-- ============================================================
task.spawn(function()
    local lastMaterialLog = 0
    local lastTargetLog = 0
    local lastTargetKey = nil
    local jitterSeed = 0
    local lastSpawnTPTime = 0
    local SPAWN_TP_COOLDOWN = 2
    local lastSpawnTPName = nil

    while task.wait(0.03) do
        xpcall(function()
            if not _G.Auto_Farm_Material then
                lastTargetKey = nil
                _G.CanAutoSkill = false
                return
            end

            if type(_G.Select_Material) ~= "table" or #_G.Select_Material == 0 then
                if tick() - lastMaterialLog > 5 then
                    lastMaterialLog = tick()
                end
                return
            end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then return end

            local mobFolder = workspace:FindFirstChild("Mob") or workspace:FindFirstChild("Mobs")
            if not mobFolder then
                if tick() - lastTargetLog > 5 then
                    lastTargetLog = tick()
                end
                return
            end

            local Target = nil
            local TargetName = nil
            local minDist = math.huge

            for _, Material in ipairs(_G.Select_Material) do
                local MobNames = ItemDrop[Material]
                if MobNames then
                    for _, MobName in ipairs(MobNames) do
                        for _, Mob in ipairs(mobFolder:GetChildren()) do
                            if Mob:IsA("Model")
                               and Mob.Name == MobName
                               and Mob:FindFirstChild("Humanoid")
                               and Mob:FindFirstChild("HumanoidRootPart")
                               and Mob.Humanoid.Health > 0 then
                                local dist = (hrp.Position - Mob.HumanoidRootPart.Position).Magnitude
                                if dist < minDist then
                                    minDist = dist
                                    Target = Mob
                                    TargetName = MobName
                                end
                            end
                        end
                    end
                end
            end

            if not Target then
                _G.CanAutoSkill = false

                if tick() - lastSpawnTPTime >= SPAWN_TP_COOLDOWN then
                    local firstMaterial = _G.Select_Material[1]
                    local MobNames = ItemDrop[firstMaterial]

                    if MobNames and #MobNames > 0 then
                        local spawnName = MobNames[1]
                        local itemdrops = workspace:FindFirstChild("Itemdrops")
                        local spawnPart = itemdrops and itemdrops:FindFirstChild(spawnName)

                        if spawnPart then
                            local spawnPos = spawnPart:GetPivot().Position
                            hrp.CFrame = CFrame.new(spawnPos + Vector3.new(0, 10, 0))
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero

                            lastSpawnTPTime = tick()

                            if lastSpawnTPName ~= spawnName then
                                lastSpawnTPName = spawnName
                            end

                            task.wait(0.5)
                        end
                    end
                end

                if tick() - lastTargetLog > 5 then
                    lastTargetLog = tick()
                end

                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                return
            end

            local tHrp = Target.HumanoidRootPart
            if not tHrp then return end

            lastSpawnTPName = nil

            local newKey = TargetName .. "|" .. tostring(Target)
            if newKey ~= lastTargetKey then
                lastTargetKey = newKey

                local targetCF = tHrp.CFrame * MethodFarm
                hrp.CFrame = CFrame.new(targetCF.Position, tHrp.Position)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end

            Target.Humanoid.WalkSpeed = 0
            Target.Humanoid.JumpPower = 0

            _G.CanAutoSkill = true

            EquipWeapon()
            AutoSkill()
            Attack()

            local timeSinceSkill = tick() - (_G.LastSkillTime or 0)
            local isDashing = _G.DASH_SKILLS and _G.DASH_SKILLS[_G.LastSkillKey or ""]
                          and timeSinceSkill < (_G.DASH_NEGATE_TIME or 0.35)

            local hitMode = _G.MoonHitPosition or "Upper"
            local jitterMult = 1.0
            if hitMode == "Upper" or hitMode == "Below" then
                jitterMult = 0.0
            end

            jitterSeed = jitterSeed + 1
            local jX = math.sin(jitterSeed * 0.7) * 0.05 * jitterMult
            local jY = math.cos(jitterSeed * 0.9) * 0.03 * jitterMult
            local jZ = math.sin(jitterSeed * 1.1) * 0.05 * jitterMult

            local targetCF = tHrp.CFrame * MethodFarm
            local finalPos = targetCF.Position + Vector3.new(jX, jY, jZ)

            if hitMode == "Upper" or hitMode == "Below" then
                hrp.CFrame = CFrame.new(finalPos) * (hrp.CFrame - hrp.CFrame.Position)

                local gyro = hrp:FindFirstChild("RaidStableGyro")
                if not gyro then
                    gyro = Instance.new("BodyGyro")
                    gyro.Name = "RaidStableGyro"
                    gyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
                    gyro.P = 10000
                    gyro.D = 500
                    gyro.Parent = hrp
                end
                local look = hrp.CFrame.LookVector
                local flatLook = Vector3.new(look.X, 0, look.Z)
                if flatLook.Magnitude < 0.1 then
                    flatLook = Vector3.new(0, 0, -1)
                end
                gyro.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flatLook.Unit)
            else
                local gyro = hrp:FindFirstChild("RaidStableGyro")
                if gyro then gyro:Destroy() end
                hrp.CFrame = CFrame.new(finalPos, tHrp.Position)
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero

            if isDashing then
                local bv = hrp:FindFirstChild("AntiDashBV")
                if not bv then
                    bv = Instance.new("BodyVelocity")
                    bv.Name = "AntiDashBV"
                    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                    bv.Velocity = Vector3.zero
                    bv.Parent = hrp
                end
                bv.Velocity = Vector3.zero
            else
                local bv = hrp:FindFirstChild("AntiDashBV")
                if bv then bv:Destroy() end
            end
        end, function(err)
            warn("[AutoFarm] Error:", err)
        end)
    end
end)

-- ============================================================
-- AUTO FARM BOSS (Full) — v6 BÁM 24/7 SAU RESPAWN
-- ============================================================
task.spawn(function()
    local lastSummonTime = 0
    local summonCooldown = 1.5
    local lastBossKey = nil
    local jitterSeed = 0

    while task.wait(0.03) do
        xpcall(function()
            if not _G.Auto_FarmBoss then return end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then
                _G.CanAutoSkill = false
                return
            end

            local Boss = nil
            for _, v in pairs(workspace.Boss:GetChildren()) do
                if table.find(Bosses, v.Name)
                   and v:FindFirstChild("Humanoid")
                   and v:FindFirstChild("HumanoidRootPart")
                   and v.Humanoid.Health > 0 then
                    Boss = v
                    break
                end
            end

            if Boss then
                _G.CanAutoSkill = true
                lastSummonTime = 0

                Boss.Humanoid.WalkSpeed = 0
                Boss.Humanoid.JumpPower = 0

                local tHrp = Boss.HumanoidRootPart
                local bossKey = Boss.Name .. tostring(Boss)

                if bossKey ~= lastBossKey then
                    lastBossKey = bossKey

                    hrp.CFrame = CFrame.new(tHrp.Position + Vector3.new(0, 25, 0), tHrp.Position)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end

                jitterSeed = jitterSeed + 1
                local jX = math.sin(jitterSeed * 0.7) * 0.02
                local jY = math.cos(jitterSeed * 0.9) * 0.02
                local jZ = math.sin(jitterSeed * 1.1) * 0.03

                local targetPos = tHrp.Position + Vector3.new(jX, 25 + jY, jZ)

                hrp.CFrame = CFrame.new(targetPos, tHrp.Position)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero

                EquipWeapon()
                AutoSkill()
                Attack()
                return
            end

            _G.CanAutoSkill = false
            lastBossKey = nil

            local now = tick()
            if now - lastSummonTime < summonCooldown then return end

            local orbBoss = GetItemAmount("Orb Boss")
            if orbBoss >= 1 and _G.Select_Boss then
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "SummonBoss", _G.Select_Boss)
                lastSummonTime = now
                return
            end

            _G.Auto_FarmBoss = false
            _G.SeaNotify("❌ " .. T("Hết Orb Boss"), T("Đã tắt Auto Farm Boss (Full)!"), 5)
        end, function(err) warn("[AutoFarmBoss] Error:", err) end)
    end
end)

-- AUTO PICCOLO
task.spawn(function()
    while task.wait() do
        if _G.Auto_Piccolo then
            pcall(function()
                if workspace.Mob:FindFirstChild("Piccolo") then
                    for _, v in pairs(workspace.Mob:GetChildren()) do
                        if v:IsA("Model") and v.Name == "Piccolo" and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0

                            _G.CanAutoSkill = true

                            repeat task.wait(0.03)
                                EquipWeapon()
                                AutoSkill()
                                Attack()
                                Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
                            until not _G.Auto_Piccolo or not v.Parent or v.Humanoid.Health <= 0

                            _G.CanAutoSkill = false
                        end
                    end
                else
                    _G.CanAutoSkill = false
                end
            end)
        end
    end
end)

-- ============================================================
-- AUTO DUCK (Full) — v6 BÁM 24/7 SAU RESPAWN
-- ============================================================
task.spawn(function()
    local lastSummonTime = 0
    local summonCooldown = 2.5
    local lastDuckKey = nil
    local jitterSeed = 0

    while task.wait(0.03) do
        xpcall(function()
            if not _G.Auto_DuckAutomatically then return end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then
                _G.CanAutoSkill = false
                return
            end

            local Duck = nil
            for _, v in pairs(workspace.Mob:GetChildren()) do
                if v:IsA("Model")
                   and v.Name == "Duck Monster"
                   and v:FindFirstChild("Humanoid")
                   and v:FindFirstChild("HumanoidRootPart")
                   and v.Humanoid.Health > 0 then
                    Duck = v
                    break
                end
            end

            if Duck then
                _G.CanAutoSkill = true
                lastSummonTime = 0

                Duck.Humanoid.WalkSpeed = 0
                Duck.Humanoid.JumpPower = 0

                local tHrp = Duck.HumanoidRootPart
                local duckKey = Duck.Name .. tostring(Duck)

                if duckKey ~= lastDuckKey then
                    lastDuckKey = duckKey

                    hrp.CFrame = CFrame.new(tHrp.Position + Vector3.new(0, 25, 0), tHrp.Position)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end

                jitterSeed = jitterSeed + 1
                local jX = math.sin(jitterSeed * 0.7) * 0.02
                local jY = math.cos(jitterSeed * 0.9) * 0.02
                local jZ = math.sin(jitterSeed * 1.1) * 0.03

                local targetPos = tHrp.Position + Vector3.new(jX, 25 + jY, jZ)

                hrp.CFrame = CFrame.new(targetPos, tHrp.Position)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero

                EquipWeapon()
                AutoSkill()
                Attack()
                return
            end

            _G.CanAutoSkill = false
            lastDuckKey = nil

            local now = tick()
            if now - lastSummonTime < summonCooldown then return end

            local DuckItems = {"Duck","Duck2","Duck3","Duck4","Duck5","Duck6","Duck7"}
            local missingItems = {}
            local HaveAll = true
            for _, Item in ipairs(DuckItems) do
                if GetItemAmount(Item) <= 0 then
                    HaveAll = false
                    table.insert(missingItems, Item)
                end
            end

            if HaveAll then
                local npcPrompt = workspace:FindFirstChild("NpcPrompt")
                local duckNPC = npcPrompt and npcPrompt:FindFirstChild("DuckMonster")

                if duckNPC then
                    local npcHrp = duckNPC:FindFirstChild("HumanoidRootPart")
                        or duckNPC:FindFirstChildWhichIsA("BasePart")

                    if npcHrp then
                        hrp.CFrame = npcHrp.CFrame * CFrame.new(0, 5, 0)
                        task.wait(0.3)

                        local prompt = npcHrp:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            pcall(function() fireproximityprompt(prompt) end)
                            lastSummonTime = now
                        end
                    end
                end
                return
            end

            _G.Auto_DuckAutomatically = false
            _G.SeaNotify("❌ " .. T("Thiếu Duck Items"), table.concat(missingItems, ", "), 6)
        end, function(err) warn("[AutoDuckFull] Error:", err) end)
    end
end)

-- AUTO DEVIL BOAT
task.spawn(function()
    while task.wait() do
        if _G.Auto_DevilBoat then
            pcall(function()
                _G.CanAutoSkill = false

                for _, v in pairs(workspace.Mob:GetChildren()) do
                    if v:IsA("Model") and (v.Name == "Devil Boat" or v.Name == "DevilBoat") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        v.Humanoid.WalkSpeed = 0
                        v.Humanoid.JumpPower = 0

                        _G.CanAutoSkill = true

                        repeat task.wait(0.03)
                            EquipWeapon()
                            AutoSkill()
                            Attack()
                            Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
                        until not _G.Auto_DevilBoat or not v.Parent or v.Humanoid.Health <= 0

                        _G.CanAutoSkill = false
                        break
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- 🐙 AUTO FARM KRAKEN — v1
-- ============================================================
task.spawn(function()
    local lastTargetKey = nil
    local jitterSeed = 0
    local KRAKEN_HEIGHT = 25

    while task.wait(0.03) do
        xpcall(function()
            if not _G.Auto_Kraken then
                _G.CanAutoSkill = false
                lastTargetKey = nil
                return
            end

            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChild("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then
                _G.CanAutoSkill = false
                return
            end

            local Kraken = nil
            local mobFolder = workspace:FindFirstChild("Mob")
            if mobFolder then
                for _, v in ipairs(mobFolder:GetChildren()) do
                    if v:IsA("Model")
                       and v.Name == "Kraken"
                       and v:FindFirstChild("Humanoid")
                       and v:FindFirstChild("HumanoidRootPart")
                       and v.Humanoid.Health > 0 then
                        Kraken = v
                        break
                    end
                end
            end

            if not Kraken then
                _G.CanAutoSkill = false
                lastTargetKey = nil
                return
            end

            _G.CanAutoSkill = true

            Kraken.Humanoid.WalkSpeed  = 0
            Kraken.Humanoid.JumpPower  = 0

            local tHrp = Kraken.HumanoidRootPart
            local krakenKey = Kraken.Name .. tostring(Kraken)

            if krakenKey ~= lastTargetKey then
                lastTargetKey = krakenKey

                hrp.CFrame = CFrame.new(
                    tHrp.Position + Vector3.new(0, KRAKEN_HEIGHT, 0),
                    tHrp.Position
                )
                hrp.AssemblyLinearVelocity  = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end

            jitterSeed = jitterSeed + 1
            local jX = math.sin(jitterSeed * 0.7) * 0.02
            local jY = math.cos(jitterSeed * 0.9) * 0.02
            local jZ = math.sin(jitterSeed * 1.1) * 0.03

            local targetPos = tHrp.Position + Vector3.new(jX, KRAKEN_HEIGHT + jY, jZ)

            hrp.CFrame = CFrame.new(targetPos, tHrp.Position)
            hrp.AssemblyLinearVelocity  = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero

            EquipWeapon()
            AutoSkill()
            Attack()
        end, function(err)
            warn("[AutoKraken] Error:", err)
        end)
    end
end)

-- ============================================================
-- 🆕 AUTO CRAFT WEAPON v133 — FIX SPAM + THÔNG MINH
-- ============================================================
task.spawn(function()
    local lastNotifyTime = 0
    local lastCraftTime = 0
    local CRAFT_INTERVAL = 0.5
    local NOTIFY_INTERVAL = 5
    local lastMissingKey = nil
    local lastMissingNotify = 0

    while task.wait(0.1) do
        xpcall(function()
            if not _G.Auto_CraftWeapon then return end

            if not _G.Select_Item or _G.Select_Item == "" then
                if tick() - lastNotifyTime > NOTIFY_INTERVAL then
                    lastNotifyTime = tick()
                    _G.SeaNotify("❌ " .. T("Chưa chọn Weapon"), T("Chọn weapon trong dropdown trước!"), 3)
                end
                return
            end

            local Data = UseItems and UseItems[_G.Select_Item]
            if not Data then return end

            if Data.NeedClass then
                local PlayerClass = LocalPlayer:GetAttribute("UseClass")
                if PlayerClass ~= Data.NeedClass then
                    if tick() - lastNotifyTime > NOTIFY_INTERVAL then
                        lastNotifyTime = tick()
                        _G.SeaNotify("⚠️ " .. T("Thiếu Class") .. ": " .. Data.NeedClass, T("Bạn cần class này để craft"), 4)
                    end
                    return
                end
            end

            local needBeli = (Data.PlayerData and Data.PlayerData.Beli) or 0
            local currentBeli = LocalPlayer:GetAttribute("Beli") or 0
            if needBeli > 0 and currentBeli < needBeli then
                if tick() - lastNotifyTime > NOTIFY_INTERVAL then
                    lastNotifyTime = tick()
                    _G.SeaNotify("❌ " .. T("Thiếu Beli"), T("Cần") .. " " .. needBeli .. ", " .. T("có") .. " " .. currentBeli, 4)
                end
                return
            end

            local Inv = GetInventory()
            local missingItems = {}
            local haveAll = true

            for Item, Need in pairs(Data.Inventory) do
                local Have = Inv[Item] and Inv[Item].amount or 0
                if Have < Need then
                    haveAll = false
                    table.insert(missingItems, Item .. " (" .. Have .. "/" .. Need .. ")")
                end
            end

            if not haveAll then
                local missingKey = table.concat(missingItems, ",")
                if missingKey ~= lastMissingKey or tick() - lastMissingNotify > NOTIFY_INTERVAL then
                    lastMissingKey = missingKey
                    lastMissingNotify = tick()
                    _G.SeaNotify("❌ " .. T("Thiếu Materials"), table.concat(missingItems, ", "), 4)
                end
                return
            end

            lastMissingKey = nil

            if tick() - lastCraftTime >= CRAFT_INTERVAL then
                lastCraftTime = tick()
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Craft", _G.Select_Item, Data.Type)
            end
        end, print)
    end
end)

-- ============================================================
-- 🆕 UPDATE ITEM REQUIREMENTS v133 — FIX (None) N/A
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if not UseItems then return end

            if not _G.Select_Item or _G.Select_Item == "" then
                Item_Auto:SetTitle("Item Requirements ( Chưa chọn )")
                Item_Auto:SetContent("📖 Hướng dẫn:\n  1. Chọn Weapon từ dropdown\n  2. Bấm TP đến NPC Material\n  3. Bật Auto Craft")
                return
            end

            local Data = UseItems[_G.Select_Item]
            if not Data then
                Item_Auto:SetTitle("Item Requirements ( Không có data )")
                Item_Auto:SetContent("❌ Weapon: " .. _G.Select_Item .. "\n  Không tìm thấy trong UseItems")
                return
            end

            local Inv = GetInventory()
            local HaveWeapon = Inv[_G.Select_Item] and (Inv[_G.Select_Item].amount or 0) > 0

            local Text = {}
            table.insert(Text, "📦 Weapon: " .. _G.Select_Item)
            table.insert(Text, "━━━━━━━━━━━━━━━━━━━━")
            table.insert(Text, "🎓 Need Class: " .. (Data.NeedClass or "None"))
            table.insert(Text, "💰 Need Beli: " .. tostring((Data.PlayerData and Data.PlayerData.Beli) or 0))

            local LowestSet = math.huge
            local MaterialsText = {}
            local missingCount = 0

            for Item, Need in pairs(Data.Inventory) do
                local Have = Inv[Item] and Inv[Item].amount or 0
                local Set  = math.floor(Have / Need)
                if Set < LowestSet then LowestSet = Set end
                if Have < Need then missingCount = missingCount + 1 end
            end

            if LowestSet == math.huge then LowestSet = 0 end
            table.insert(Text, "🎯 Have Set: " .. LowestSet)
            table.insert(Text, "━━━━━━━━━━━━━━━━━━━━")
            table.insert(Text, "📋 Materials:")

            for Item, Need in pairs(Data.Inventory) do
                local Have = Inv[Item] and Inv[Item].amount or 0
                local Set  = math.floor(Have / Need)
                local status = Have >= Need and "✅" or "❌"
                table.insert(Text, string.format("  %s %s: %d/%d (Set: %d)",
                    status, Item, Have, Need, Set))
            end

            local statusIcon = "❌"
            if HaveWeapon then statusIcon = "✅ (Đã có)"
            elseif missingCount == 0 then statusIcon = "✅ (Đủ đồ)" end

            Item_Auto:SetTitle("Item Requirements \n( " .. _G.Select_Item .. " " .. statusIcon .. " )")
            Item_Auto:SetContent(table.concat(Text, "\n"))
        end)
    end
end)

-- AUTO FARM SET
task.spawn(function()
    while task.wait() do
        if _G.Auto_Farm_Set then
            pcall(function()
                local Data = UseItems and UseItems[_G.Select_Item]
                if not Data then return end
                local Inv = GetInventory()
                local NeedFarmItem = nil
                local LowestSet    = math.huge
                for Item, Need in pairs(Data.Inventory) do
                    if not (UseItems[Item]) then
                        local Have = Inv[Item] and Inv[Item].amount or 0
                        local Set  = math.floor(Have / Need)
                        if Set < LowestSet then
                            LowestSet    = Set
                            NeedFarmItem = Item
                        end
                    end
                end
                if not NeedFarmItem then return end
                local NeedAmount = Data.Inventory[NeedFarmItem]
                local Have       = Inv[NeedFarmItem] and Inv[NeedFarmItem].amount or 0
                if Have >= (LowestSet + 1) * NeedAmount then return end
                local MobNames = ItemDrop[NeedFarmItem]
                if not MobNames then return end
                for _, MobName in ipairs(MobNames) do
                    local Target
                    for _, Mob in ipairs(workspace.Mob:GetChildren()) do
                        if Mob:IsA("Model") and Mob.Name == MobName and Mob:FindFirstChild("Humanoid") and Mob.Humanoid.Health > 0 then
                            Target = Mob; break
                        end
                    end
                    if Target then
                        local HRP = Target.HumanoidRootPart
                        Target.Humanoid.WalkSpeed = 0
                        Target.Humanoid.JumpPower = 0

                        _G.CanAutoSkill = true

                        repeat task.wait()
                            EquipWeapon(); AutoSkill(); Attack()
                            Teleport(HRP.CFrame * MethodFarm)
                            Inv  = GetInventory()
                            Have = Inv[NeedFarmItem] and Inv[NeedFarmItem].amount or 0
                        until not _G.Auto_Farm_Set or not Target.Parent or Target.Humanoid.Health <= 0 or Have >= ((LowestSet + 1) * NeedAmount)

                        _G.CanAutoSkill = false
                        break
                    else
                        local Spawn = workspace.Itemdrops:FindFirstChild(MobName)
                        if Spawn then Teleport(Spawn:GetPivot()); task.wait(1.5); break end
                    end
                end
            end)
        end
    end
end)

-- AUTO RAID BOSS v40
_G.RaidPhase            = "IDLE"
_G.RaidPortalRef        = nil
_G.RaidFireTimestamp    = 0
_G.RaidFired            = false
_G.RaidForceFirePending = false
_G.RaidPrevRunning      = false
_G.RaidBP               = nil
_G.RaidWaitOldPortal    = nil
_G.RaidWaitPortalStart  = nil
_G.RaidClearStart       = nil
_G.RaidLastFireTime     = 0
_G.RaidToolWaitStart    = nil
_G.RaidAttacking        = false
_G.RaidRespawnTime      = 0
_G.RaidSkipBossFight    = 0
_G.RaidLastAttack       = 0
_G.RaidLastSkill        = 0
_G.RaidLastEquip        = 0
_G.RaidCurrentTarget    = nil
_G.RaidCurrentOffset    = nil

local RAID_PORTAL_CD      = 8
local RAID_FIRE_VALID_WIN = 20
local HOVER_HEIGHT        = 100
local RAID_MIN_FIRE_GAP   = 3
local RESPAWN_SKIP_TIME   = 15

local function CreateRaidBP(hrp, position, force)
    if not hrp or not hrp.Parent then return end
    if hrp:FindFirstChild("RaidBP") then hrp.RaidBP:Destroy() end

    local bp = Instance.new("BodyPosition")
    bp.Name     = "RaidBP"
    bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bp.P        = force or 30000
    bp.D        = 5000
    bp.Position = position
    bp.Parent   = hrp
    _G.RaidBP = bp
    return bp
end

local function StartRaidHover(hrp, height)
    if not hrp or not hrp.Parent then return end
    height = height or HOVER_HEIGHT
    local targetPos = hrp.Position + Vector3.new(0, height, 0)
    CreateRaidBP(hrp, targetPos, 30000)
end

local function StopRaidHover(hrp, silent)
    if not hrp then
        hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    end
    if hrp then
        for _, name in ipairs({"RaidBP", "RaidHoverBP", "RaidHoverGyro", "RaidAnchorBP"}) do
            if hrp:FindFirstChild(name) then hrp[name]:Destroy() end
        end
    end
    _G.RaidBP = nil
    if not silent then end
end

local function HasToolEquipped()
    local char = LocalPlayer.Character
    if not char then return false end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then return true end
    end
    return false
end

local function HasToolInBackpack()
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if not bp then return false end
    for _, v in ipairs(bp:GetChildren()) do
        if v:IsA("Tool") then return true end
    end
    return false
end

local function HasAnyTool()
    return HasToolEquipped() or HasToolInBackpack()
end

local RaidHeartbeatConn = nil

local function StartRaidFollow()
    if RaidHeartbeatConn then return end
    RaidHeartbeatConn = RunService.Heartbeat:Connect(function()
        if not _G.AutoRaidRunning then return end
        local target = _G.RaidCurrentTarget
        if not target or not target.Parent then return end

        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end

        local offset = _G.RaidCurrentOffset or Vector3.new(0, 25, 0)
        local name = target.Parent and target.Parent.Name or ""
        if name == "ArmorBall1" or name == "ArmorBall2" then
            offset = Vector3.new(0, _G.RaidBallOffsetY or 25, 0)
        elseif name == "Boss Bacon Sad" then
            offset = Vector3.new(0, _G.RaidBossOffsetY or 55, 5)
        end

        local targetPos = target.Position + offset
        hrp.CFrame = CFrame.new(targetPos, target.Position)
        hrp.AssemblyLinearVelocity   = Vector3.zero
        hrp.AssemblyAngularVelocity  = Vector3.zero
    end)
end

local function StopRaidFollow()
    if RaidHeartbeatConn then
        RaidHeartbeatConn:Disconnect()
        RaidHeartbeatConn = nil
    end
    _G.RaidCurrentTarget = nil
    _G.RaidCurrentOffset = nil
end

local function CleanupRaidTags()
    StopRaidFollow()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, name in ipairs({"AutoRaidBP", "AutoRaidAP", "AutoRaidAO", "AutoRaidAtt", "RaidSmoothBP", "BodyClip"}) do
        if hrp:FindFirstChild(name) then hrp[name]:Destroy() end
    end
end

local function AttackTarget(targetPart, targetModel, offsetY, offsetX)
    if not targetPart or not targetModel then return end
    if not targetModel:FindFirstChild("Humanoid") then return end
    if targetModel.Humanoid.Health <= 0 then return end
    if _G.RaidAttacking then return end
    if tick() < _G.RaidSkipBossFight then
        return
    end

    _G.RaidAttacking = true
    _G.CanAutoSkill = true

    targetModel.Humanoid.WalkSpeed = 0
    targetModel.Humanoid.JumpPower = 0

    _G.RaidCurrentTarget = targetPart
    _G.RaidCurrentOffset = Vector3.new(offsetX or 0, offsetY or 25, 0)

    local attackStart    = tick()
    local lastHealth     = targetModel.Humanoid.Health
    local stuckStart     = tick()
    local toolWaitStart  = tick()

    task.spawn(function()
        while _G.RaidAttacking do
            task.wait(0.05)

            if not _G.AutoRaidRunning then break end
            if not targetModel or not targetModel.Parent then break end
            if not targetModel:FindFirstChild("Humanoid") then break end
            if targetModel.Humanoid.Health <= 0 then break end
            if tick() < _G.RaidSkipBossFight then break end

            if _G.RaidCurrentTarget == targetPart then
                local newOffsetY
                local name = targetModel.Name
                if name == "ArmorBall1" or name == "ArmorBall2" then
                    newOffsetY = _G.RaidBallOffsetY or 25
                elseif name == "Boss Bacon Sad" then
                    newOffsetY = _G.RaidBossOffsetY or 55
                else
                    newOffsetY = offsetY or 25
                end
                _G.RaidCurrentOffset = Vector3.new(offsetX or 0, newOffsetY, 0)
            end

            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            if not hum or hum.Health <= 0 then break end
            if not targetPart or not targetPart.Parent then break end

            local now = tick()

            if now - attackStart > 60 then
                break
            end

            local hasTool = HasAnyTool()
            if not hasTool then
                if now - attackStart > 8 then
                    break
                end
                if now - toolWaitStart > 1 then
                    toolWaitStart = now
                end
            else
                if now - _G.RaidLastEquip >= 0.5 then
                    _G.RaidLastEquip = now
                    EquipWeapon()
                end

                local autoAtk = _G.RaidAutoAttack
                local autoSkl = _G.RaidAutoSkill

                if autoAtk and autoSkl then
                    if now - _G.RaidLastSkill >= 0.1 then
                        _G.RaidLastSkill = now
                        AutoSkill()
                    end
                    if now - _G.RaidLastAttack >= 0.15 then
                        _G.RaidLastAttack = now
                        Attack()
                    end
                elseif autoSkl then
                    if now - _G.RaidLastSkill >= 0.1 then
                        _G.RaidLastSkill = now
                        AutoSkill()
                    end
                else
                    if now - _G.RaidLastAttack >= 0.08 then
                        _G.RaidLastAttack = now
                        Attack()
                    end
                end
            end

            if targetModel.Humanoid.Health < lastHealth then
                lastHealth = targetModel.Humanoid.Health
                stuckStart = now
            elseif now - stuckStart > 15 and hasTool then
                break
            end
        end

        _G.RaidAttacking    = false
        _G.RaidCurrentTarget = nil
        _G.RaidCurrentOffset = nil
        _G.CanAutoSkill      = false
    end)
end

local function EnterRaidPortal(hrp, timeout)
    if _G.RaidPhase == "ENTERING" then return end
    _G.RaidPhase = "ENTERING"
    _G.CanAutoSkill = false

    timeout = timeout or 10
    local startTime = tick()
    local fireTime  = _G.RaidFireTimestamp

    local TPZone, Hitbox
    repeat task.wait(0.03)
        if not _G.AutoRaidRunning then
            StopRaidHover(hrp, true)
            _G.RaidPhase = "IDLE"
            _G.RaidFired = false
            return
        end

        local zone = workspace:FindFirstChild("TeleportBossFightZone")
        if zone and zone:FindFirstChild("Hitbox") then
            local isDifferent = (_G.RaidPortalRef == nil) or (zone ~= _G.RaidPortalRef)
            local isValidTime = true
            if fireTime > 0 and tick() - fireTime > RAID_FIRE_VALID_WIN then
                isValidTime = false
            end
            if isDifferent and isValidTime then
                TPZone = zone
                Hitbox = zone.Hitbox
                break
            end
        end
    until tick() - startTime >= timeout

    if not Hitbox then
        StopRaidHover(hrp, true)
        _G.RaidPhase = "IDLE"
        _G.RaidFired = false
        return
    end

    _G.RaidPortalRef = TPZone

    hrp.CFrame = CFrame.new(Hitbox.Position + Vector3.new(0, 8, 0))
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    CreateRaidBP(hrp, Hitbox.Position + Vector3.new(0, 8, 0), 8000)

    local enterStart = tick()
    local LastPrint  = 0

    repeat task.wait(0.05)
        if not _G.AutoRaidRunning then break end
        if tick() - enterStart > 10 then
            break
        end

        if not TPZone.Parent or not TPZone:FindFirstChild("Hitbox") then
            break
        end

        if hrp.Parent and Hitbox.Parent then
            local dist = (hrp.Position - Hitbox.Position).Magnitude
            if dist > 200 then
                break
            end

            local targetPos = Hitbox.Position + Vector3.new(0, 8, 0)
            if _G.RaidBP and _G.RaidBP.Parent then
                if (_G.RaidBP.Position - targetPos).Magnitude > 5 then
                    _G.RaidBP.Position = targetPos
                end
            else
                hrp.CFrame = CFrame.new(targetPos)
                CreateRaidBP(hrp, targetPos, 8000)
            end
        end

        if tick() - LastPrint > 3 then
            LastPrint = tick()
            local dist = (hrp.Parent and Hitbox.Parent) and math.floor((hrp.Position - Hitbox.Position).Magnitude) or -1
        end
    until false

    StopRaidHover(hrp, true)
    _G.RaidPhase = "WAIT_PORTAL"
    _G.RaidWaitPortalStart = tick()
    _G.RaidFired = false
end

task.spawn(function()
    while task.wait(0.15) do
        if _G.RaidPrevRunning and not _G.AutoRaidRunning then
            StopRaidHover(nil, true)
            _G.RaidPhase            = "IDLE"
            _G.RaidPortalRef        = nil
            _G.RaidFireTimestamp    = 0
            _G.RaidFired            = false
            _G.RaidForceFirePending = false
            _G.RaidRespawnTime      = 0
            _G.RaidAttacking        = false
            _G.RaidSkipBossFight    = 0
            _G.CanAutoSkill         = false
        end
        _G.RaidPrevRunning = _G.AutoRaidRunning

        if not _G.AutoRaidRunning then continue end

        local Data = RaidBossData and RaidBossData[_G.AutoRaidWho]
        if not (Data and Data.Valid) then continue end

        pcall(function()
            local char = LocalPlayer.Character

            if _G.RaidPhase == "DEAD" then
                local newHum = char and char:FindFirstChild("Humanoid")
                local newHrp = char and char:FindFirstChild("HumanoidRootPart")

                if newHum and newHrp and newHum.Health > 0 then
                    _G.RaidPhase            = "IDLE"
                    _G.RaidFired            = false
                    _G.RaidPortalRef        = nil
                    _G.RaidFireTimestamp    = 0
                    _G.RaidWaitOldPortal    = nil
                    _G.RaidWaitPortalStart  = nil
                    _G.RaidClearStart       = nil
                    _G.RaidForceFirePending = true
                    _G.RaidLastFireTime     = 0
                    _G.RaidLastAttack       = 0
                    _G.RaidLastSkill        = 0
                    _G.RaidLastEquip        = 0
                    _G.RaidToolWaitStart    = nil
                    _G.RaidRespawnTime      = tick()
                    _G.RaidAttacking        = false
                    _G.RaidSkipBossFight    = tick() + RESPAWN_SKIP_TIME
                    _G.CanAutoSkill         = false
                    StopRaidHover(newHrp, true)
                    CleanupRaidTags()

                    task.wait(2)
                    return
                else
                    task.wait(0.2)
                    return
                end
            end

            local hum = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end

            if hum.Health <= 0 then
                if _G.RaidPhase ~= "DEAD" then
                    _G.RaidPhase = "DEAD"
                    _G.RaidAttacking = false
                    _G.CanAutoSkill = false
                    StopRaidHover(hrp, true)
                    CleanupRaidTags()
                end
                return
            end

            if _G.RaidRespawnTime > 0 and tick() - _G.RaidRespawnTime < 2 then
                if not hrp:FindFirstChild("RaidBP") then
                    StartRaidHover(hrp, HOVER_HEIGHT)
                end
                task.wait(0.3)
                return
            end

            if tick() < _G.RaidSkipBossFight then
                _G.CanAutoSkill = false

                local bfCheck = workspace:FindFirstChild("Boss Fight")
                local baconCheck = bfCheck and bfCheck:FindFirstChild("Bacon of Grudge")

                if not bfCheck or not baconCheck then
                    _G.RaidSkipBossFight    = 0
                    _G.RaidPhase            = "IDLE"
                    _G.RaidPortalRef        = nil
                    _G.RaidFired            = false
                    _G.RaidForceFirePending = true
                    _G.RaidLastFireTime     = 0
                    task.wait(0.3)
                    return
                end

                if not hrp:FindFirstChild("RaidBP") then
                    StartRaidHover(hrp, HOVER_HEIGHT)
                end

                local skipElapsed = tick() - (_G.RaidRespawnTime or tick())
                if skipElapsed > RESPAWN_SKIP_TIME then
                    _G.RaidSkipBossFight    = 0
                    _G.RaidPhase            = "IDLE"
                    _G.RaidPortalRef        = nil
                    _G.RaidFired            = false
                    _G.RaidForceFirePending = true
                    _G.RaidLastFireTime     = 0
                    task.wait(0.3)
                    return
                end

                task.wait(0.3)
                return
            end

            local bf          = workspace:FindFirstChild("Boss Fight")
            local baconFolder = bf and bf:FindFirstChild("Bacon of Grudge")

            if _G.RaidPhase == "CLEARING" then
                _G.CanAutoSkill = false

                if not hrp:FindFirstChild("RaidBP") then
                    StartRaidHover(hrp, HOVER_HEIGHT)
                end

                _G.RaidClearStart = _G.RaidClearStart or tick()
                local elapsed = tick() - _G.RaidClearStart

                if elapsed > 3 or not workspace:FindFirstChild("Boss Fight") then
                    _G.RaidPhase            = "IDLE"
                    _G.RaidPortalRef        = nil
                    _G.RaidFired            = false
                    _G.RaidForceFirePending = true
                    _G.RaidClearStart       = nil
                    _G.RaidLastFireTime     = 0
                    _G.RaidLastAttack       = 0
                    _G.RaidLastSkill        = 0
                end
                task.wait(0.2)
                return
            end

            if baconFolder then
                local A1 = baconFolder:FindFirstChild("ArmorBall1")
                local A2 = baconFolder:FindFirstChild("ArmorBall2")
                local BossBacon = baconFolder:FindFirstChild("Boss Bacon Sad")

                local a1Alive   = A1 and A1:FindFirstChild("Humanoid") and A1.Humanoid.Health > 0
                local a2Alive   = A2 and A2:FindFirstChild("Humanoid") and A2.Humanoid.Health > 0
                local bossAlive = BossBacon and BossBacon:FindFirstChild("Humanoid") and BossBacon.Humanoid.Health > 0

                if not (a1Alive or a2Alive or bossAlive) then
                    _G.CanAutoSkill = false

                    if _G.RaidPhase ~= "CLEARING" then
                        _G.RaidPhase      = "CLEARING"
                        _G.RaidFired      = false
                        _G.RaidClearStart = tick()
                        _G.RaidAttacking  = false
                        StopRaidHover(hrp, true)
                        StartRaidHover(hrp, HOVER_HEIGHT)
                    end
                    return
                end

                if not HasAnyTool() then
                    _G.CanAutoSkill = false

                    _G.RaidToolWaitStart = _G.RaidToolWaitStart or tick()
                    if tick() - _G.RaidToolWaitStart < 5 then
                        if not hrp:FindFirstChild("RaidBP") then
                            StartRaidHover(hrp, HOVER_HEIGHT)
                        end
                        task.wait(0.3)
                        return
                    end
                    _G.RaidToolWaitStart = nil
                    _G.RaidPhase = "CLEARING"
                    _G.RaidClearStart = tick()
                    _G.RaidAttacking = false
                    return
                end
                _G.RaidToolWaitStart = nil

                if _G.RaidPhase ~= "FIGHTING" then
                    _G.RaidPhase = "FIGHTING"
                    _G.RaidFired = false
                end
                StopRaidHover(hrp, true)
                StartRaidFollow()

                if not _G.RaidAttacking then
                    if a1Alive then
                        AttackTarget(A1:FindFirstChild("HumanoidRootPart"), A1, _G.RaidBallOffsetY or 25, 0)
                    elseif a2Alive then
                        AttackTarget(A2:FindFirstChild("HumanoidRootPart"), A2, _G.RaidBallOffsetY or 25, 0)
                    elseif bossAlive then
                        local bossHrp = BossBacon:FindFirstChild("HumanoidRootPart")
                        if bossHrp then
                            AttackTarget(bossHrp, BossBacon, _G.RaidBossOffsetY or 55, 5)
                        end
                    end
                end
                task.wait(0.5)
                return
            end

            if _G.RaidPhase == "ENTERING" then
                task.wait(0.2)
                return
            end

            if _G.RaidPhase == "WAIT_PORTAL" then
                _G.CanAutoSkill = false

                local elapsed = tick() - (_G.RaidWaitPortalStart or tick())

                local bfCheck = workspace:FindFirstChild("Boss Fight")
                local baconCheck = bfCheck and bfCheck:FindFirstChild("Bacon of Grudge")
                local bossAlive = false
                if baconCheck and baconCheck:FindFirstChild("Humanoid") then
                    bossAlive = baconCheck.Humanoid.Health > 0
                end

                if bossAlive then
                    if tick() < _G.RaidSkipBossFight then
                        _G.RaidWaitPortalStart = nil
                        _G.RaidPhase = "CLEARING"
                        _G.RaidClearStart = tick()
                        return
                    end
                    _G.RaidWaitPortalStart = nil
                    _G.RaidPhase = "FIGHTING"
                    return
                end

                if elapsed > 4 then
                    _G.RaidWaitPortalStart = nil
                    _G.RaidPhase = "IDLE"
                    _G.RaidPortalRef = nil
                    _G.RaidFired = false
                    _G.RaidForceFirePending = true
                end

                task.wait(0.1)
                return
            end

            if _G.RaidPhase == "IDLE" then
                _G.CanAutoSkill = false

                if _G.RaidForceFirePending then
                    _G.RaidForceFirePending = false
                    _G.RaidPortalRef        = nil
                    _G.RaidFireTimestamp    = 0
                    _G.RaidFired            = false
                    _G.RaidWaitOldPortal    = nil
                    _G.RaidLastFireTime     = 0
                    _G.RaidLastAttack       = 0
                    _G.RaidLastSkill        = 0
                end

                if _G.RaidFired then
                    task.wait(0.3)
                    return
                end

                if tick() - _G.RaidLastFireTime < RAID_MIN_FIRE_GAP then
                    task.wait(0.2)
                    return
                end

                local bfCheck = workspace:FindFirstChild("Boss Fight")
                local baconCheck = bfCheck and bfCheck:FindFirstChild("Bacon of Grudge")
                local bossAlive = false
                if baconCheck and baconCheck:FindFirstChild("Humanoid") then
                    bossAlive = baconCheck.Humanoid.Health > 0
                end

                if bossAlive then
                    _G.RaidPhase = "FIGHTING"
                    task.wait(0.2)
                    return
                end

                local oldPortal = _G.RaidPortalRef
                if oldPortal ~= nil and oldPortal.Parent then
                    _G.RaidWaitOldPortal = _G.RaidWaitOldPortal or tick()
                    if tick() - _G.RaidWaitOldPortal > 3 then
                        _G.RaidPortalRef = nil
                        _G.RaidWaitOldPortal = nil
                    else
                        if not hrp:FindFirstChild("RaidBP") then
                            StartRaidHover(hrp, HOVER_HEIGHT)
                        end
                        task.wait(0.2)
                        return
                    end
                else
                    _G.RaidWaitOldPortal = nil
                end
                _G.RaidPortalRef = nil

                if not hrp:FindFirstChild("RaidBP") then
                    StartRaidHover(hrp, HOVER_HEIGHT)
                end

                if GetItemAmount("Portal Gun") < Data.PortalCost then
                    _G.SeaNotify("❌ " .. T("Không đủ Portal Gun"), T("Cần") .. " " .. Data.PortalCost .. " " .. T("Portal Gun!"), 4)
                    StopRaidHover(hrp, true)
                    _G.AutoRaidRunning = false
                    return
                end

                _G.RaidFireTimestamp = tick()
                _G.RaidLastFireTime  = tick()
                _G.RaidFired         = true
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "SpawnBossFight", Data.Name)

                EnterRaidPortal(hrp, 10)
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if not _G.AutoRaidRunning then
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Anchored and not workspace:FindFirstChild("Boss Fight") then
                hrp.Anchored = false
            end
            if _G.RaidBP and _G.RaidBP.Parent then
                StopRaidHover(hrp, true)
            end
            _G.RaidPhase = "IDLE"
        end
    end
end)

-- AUTO BACON THIEF
local CurrentSpawn = 1
task.spawn(function()
    while task.wait() do
        pcall(function()
            if not _G.Auto_BaconThief then return end
            local Spawns = workspace.MobSpawnGroup:GetChildren()
            local Spawn  = Spawns[CurrentSpawn]
            if not Spawn then CurrentSpawn = 1; return end
            local ChestRef = Spawn:FindFirstChild("ChestRef", true)
            if ChestRef then
                local Target
                local Distance = 30
                for _, Mob in ipairs(workspace.Mob:GetChildren()) do
                    if Mob:IsA("Model") and Mob.Name == "Bacon Thief" and Mob:FindFirstChild("HumanoidRootPart") and Mob:FindFirstChild("Humanoid") and Mob.Humanoid.Health > 0 then
                        local Mag = (Mob.HumanoidRootPart.Position - ChestRef.Position).Magnitude
                        if Mag < Distance then Distance = Mag; Target = Mob end
                    end
                end
                if Target then
                    Target.Humanoid.WalkSpeed = 0
                    Target.Humanoid.JumpPower = 0

                    _G.CanAutoSkill = true

                    EquipWeapon()
                    AutoSkill()
                    Attack()

                    Teleport(Target.HumanoidRootPart.CFrame * MethodFarm)
                else
                    _G.CanAutoSkill = false

                    local Prompt = ChestRef:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if Prompt and Prompt.Parent and Prompt.ActionText == "Open" then
                        Teleport(ChestRef.CFrame * CFrame.new(0, 3, 0))
                        fireproximityprompt(Prompt)
                    else
                        CurrentSpawn = CurrentSpawn + 1
                    end
                end
            else
                CurrentSpawn = CurrentSpawn + 1
            end
        end)
    end
end)

-- AUTO RAID MOON
task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Auto_Raid then
                if game.PlaceId == MOON_PLACE_ID then
                    for _, v in pairs(workspace.Mob:GetChildren()) do
                        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0

                            _G.CanAutoSkill = true

                            repeat task.wait()
                                EquipWeapon(); AutoSkill(); Attack()
                                Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
                            until not _G.Auto_Raid or not v.Parent or v.Humanoid.Health <= 0

                            _G.CanAutoSkill = false
                        end
                    end
                else
                    _G.CanAutoSkill = false

                    if workspace:FindFirstChild("TeleportMoonZone") then
                        Teleport(workspace:FindFirstChild("TeleportMoonZone").Hitbox:GetPivot() * CFrame.new(0, -8, 0))
                    else
                        if GetItemAmount("Space Ticket") >= 1 then
                            Teleport(workspace.NpcPrompt.GoMoon.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0))
                            fireproximityprompt(workspace.NpcPrompt.GoMoon.HumanoidRootPart:FindFirstChildOfClass("ProximityPrompt"))
                        else
                            local Diamond = LocalPlayer:GetAttribute("Diamond") or 0
                            if Diamond >= 150 then
                                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "RandomItem", "x15")
                            else
                                local quest = GetQuest_Level(tonumber(LocalPlayer:GetAttribute("Level")))
                                if not quest then return end
                                local Frame = GetQuestFrame()
                                local Text  = Frame.Title.Text or ""
                                if LocalPlayer.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
                                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                                end
                                if Frame.Visible and not string.find(Text, quest.Monster) then
                                    ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                                    repeat task.wait() until not Frame.Visible
                                end
                                if not Frame.Visible then
                                    local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
                                    if npc then
                                        Teleport(npc.CFrame * MethodFarm)
                                        task.wait(0.3)
                                        local pro_xim = npc:FindFirstChildOfClass("ProximityPrompt")
                                        if pro_xim then fireproximityprompt(pro_xim) end
                                    end
                                else
                                    for _, v in pairs(workspace.Mob:GetChildren()) do
                                        if v:IsA("Model") and v.Name == quest.Monster and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                                            local hrp = v:FindFirstChild("HumanoidRootPart")
                                            if hrp then
                                                v.Humanoid.WalkSpeed = 0
                                                v.Humanoid.JumpPower = 0

                                                _G.CanAutoSkill = true

                                                repeat task.wait()
                                                    EquipWeapon(); AutoSkill(); Attack()
                                                    Teleport(hrp.CFrame * MethodFarm)
                                                until not _G.Auto_Raid or v.Humanoid.Health <= 0

                                                _G.CanAutoSkill = false
                                            end
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- ============================================================
-- AUTO DUNGEON
-- ============================================================
task.spawn(function()
    while task.wait() do
        xpcall(function()
            if not _G.Auto_Dungeon then return end

            local Player = game.Players.LocalPlayer
            local Character = Player.Character
            if not Character then return end

            local hum = Character:FindFirstChild("Humanoid")
            local hrp = Character:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end

            local HpPercent = (hum.Health / hum.MaxHealth) * 100
            if HpPercent < _G.HealthPercent then
                hrp.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y + 200, hrp.Position.Z)
                task.wait(0.5)
                return
            end

            local Dungeon
            local DungeonId = Character:GetAttribute("Dungeon")
            local GuiService = game:GetService("GuiService")
            local VirtualInputManager = game:GetService("VirtualInputManager")

            if Player.PlayerGui:FindFirstChild("WaveUI")
               and Player.PlayerGui.WaveUI.AutoSkip.BackgroundColor3 == Color3.fromRGB(255, 69, 69) then
                GuiService.SelectedObject = Player.PlayerGui.WaveUI.AutoSkip
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                task.wait(0.1)
                GuiService.SelectedObject = nil
            end

            if DungeonId then
                Dungeon = workspace.DungeonMap:FindFirstChild("Dungeon_" .. DungeonId)
            end

            if Dungeon then
                local Target, MinDist = nil, math.huge
                for _, Mob in ipairs(workspace.Mob:GetChildren()) do
                    if Mob:IsA("Model")
                       and Mob:FindFirstChild("Humanoid")
                       and Mob:FindFirstChild("HumanoidRootPart")
                       and Mob.Humanoid.Health > 0 then
                        local dist = (Mob.HumanoidRootPart.Position - Dungeon:GetPivot().Position).Magnitude
                        if dist <= 250 and dist < MinDist then
                            MinDist = dist
                            Target = Mob
                        end
                    end
                end

                if Target then
                    _G.CanAutoSkill = true

                    local tHrp = Target.HumanoidRootPart
                    Target.Humanoid.WalkSpeed = 0
                    Target.Humanoid.JumpPower = 0

                    local bp = hrp:FindFirstChild("DungeonBP")
                    if not bp then
                        bp = Instance.new("BodyPosition")
                        bp.Name = "DungeonBP"
                        bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bp.P = 100000
                        bp.D = 3000
                        bp.Parent = hrp
                    end

                    local targetPos = tHrp.Position + Vector3.new(0, _G.DungeonHeight or 25, 0)
                    bp.Position = targetPos
                    hrp.CFrame = CFrame.new(targetPos, tHrp.Position)

                    EquipWeapon()
                    AutoSkill()
                    Attack()
                else
                    _G.CanAutoSkill = false

                    if hrp:FindFirstChild("DungeonBP") then
                        hrp.DungeonBP:Destroy()
                    end
                end
            else
                _G.CanAutoSkill = false

                local TeleportZone = workspace:FindFirstChild("TeleportDungeonZone")
                if TeleportZone and TeleportZone:FindFirstChild("Hitbox") then
                    hrp.CFrame = TeleportZone.Hitbox.CFrame
                else
                    if GetItemAmount("Orb Dungeon") >= _G.Dungeon_UseValue then
                        local NPC = workspace.NpcPrompt["Open Dungeon"].HumanoidRootPart
                        hrp.CFrame = NPC.CFrame * CFrame.new(0, 5, 0)
                        game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer(
                            "fire", nil, "SpawnDungeon", _G.Dungeon_UseValue
                        )
                    else
                        local Diamond = Player:GetAttribute("Diamond") or 0
                        if Diamond >= 150 then
                            game.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                                "fire", nil, "RandomItem", "x15"
                            )
                        else
                            local quest = GetQuest_Level(tonumber(Player:GetAttribute("Level")))
                            if not quest then return end

                            local Frame = GetQuestFrame()
                            local Text = Frame.Title.Text or ""

                            if Player.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
                                game.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                                    "fire", nil, "Quest", "Cancel"
                                )
                            end

                            if Frame.Visible and not string.find(Text, quest.Monster) then
                                game.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                                    "fire", nil, "Quest", "Cancel"
                                )
                                repeat task.wait() until not Frame.Visible
                            end

                            if not Frame.Visible then
                                local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
                                if npc then
                                    hrp.CFrame = npc.CFrame * MethodFarm
                                    task.wait(0.3)
                                    local pro = npc:FindFirstChildOfClass("ProximityPrompt")
                                    if pro then fireproximityprompt(pro) end
                                end
                            else
                                for _, v in ipairs(workspace.Mob:GetChildren()) do
                                    if v:IsA("Model")
                                       and v.Name == quest.Monster
                                       and v:FindFirstChild("Humanoid")
                                       and v:FindFirstChild("HumanoidRootPart")
                                       and v.Humanoid.Health > 0 then
                                        v.Humanoid.WalkSpeed = 0
                                        v.Humanoid.JumpPower = 0
                                        hrp.CFrame = v.HumanoidRootPart.CFrame * MethodFarm
                                        EquipWeapon()
                                        AutoSkill()
                                        Attack()
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end, print)
    end
end)

-- AUTO CLOSE REWARD GUI
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            if not hud or not hud:FindFirstChild("Main") then return end

            local closeList = {
                {_G.Auto_Dungeon,   "Frame_DungeonItem"},
                {_G.AutoRaidRunning, "Frame_RaidbossItem"}
            }

            for _, entry in ipairs(closeList) do
                if entry[1] then
                    local fd = hud.Main:FindFirstChild(entry[2])
                    if fd and fd.Visible then
                        task.wait(2)
                        local closeBtn = fd:FindFirstChild("Close_")
                            or fd:FindFirstChild("Close")
                            or fd:FindFirstChild("CloseButton")
                            or fd:FindFirstChild("Exit")
                        if closeBtn then
                            pcall(function()
                                if firesignal then firesignal(closeBtn.MouseButton1Click)
                                else closeBtn:Activate() end
                            end)
                        else
                            fd.Visible = false
                        end
                    end
                end
            end
        end)
    end
end)

-- NOCLIP + ANTI-GRAVITY
task.spawn(function()
    while task.wait() do
        if _G.Auto_Farm_Level or _G.Auto_CraftWeapon or _G.Auto_Farm_Material
           or _G.Auto_FarmBoss_Automatically or _G.Auto_FarmBoss
           or _G.Auto_DuckAutomatically or _G.Auto_Duck or _G.Auto_Farm_Set
           or _G.Auto_Raid or _G.Auto_BaconThief or _G.Auto_Dungeon
           or _G.Auto_Piccolo or _G.Auto_DevilBoat or _G.Auto_Kraken then
            pcall(function()
                local char = LocalPlayer.Character
                local HRP  = char and char:FindFirstChild("HumanoidRootPart")
                if HRP then
                    HRP.AssemblyAngularVelocity = Vector3.zero
                    local Vel = HRP.AssemblyLinearVelocity
                    HRP.AssemblyLinearVelocity = Vector3.new(0, Vel.Y, 0)
                end
            end)
        end
    end
end)

task.spawn(function()
    pcall(function()
        RunService.Stepped:Connect(function()
    if _G.Auto_Farm_Level or _G.Auto_CraftWeapon or _G.Auto_Farm_Material
       or _G.Auto_FarmBoss_Automatically or _G.Auto_FarmBoss
       or _G.Auto_DuckAutomatically or _G.Auto_Duck or _G.Auto_Farm_Set
       or _G.Auto_Raid or _G.Auto_BaconThief or _G.Auto_Dungeon
       or _G.Auto_Piccolo or _G.Auto_DevilBoat or _G.Auto_Kraken then
                local char = LocalPlayer.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if not hrp:FindFirstChild("BodyClip") then
                        local Noclip   = Instance.new("BodyVelocity")
                        Noclip.Name     = "BodyClip"
                        Noclip.Parent   = hrp
                        Noclip.MaxForce = Vector3.new(100000, 100000, 100000)
                        Noclip.Velocity = Vector3.new(0, 0, 0)
                    end
                end
            else
                local char = LocalPlayer.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and hrp:FindFirstChild("BodyClip") then hrp.BodyClip:Destroy() end
            end
        end)
    end)
end)

end   -- 🆕 End if not IS_MOON_MAP

print("[Sea 1] ✅ Load thành công!")
