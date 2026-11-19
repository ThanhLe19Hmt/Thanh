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

-- ============================================
-- TRẠNG THÁI LƯỢT (FIX ĐÈN XÁM)
-- ============================================
-- ============================================
-- TRẠNG THÁI LƯỢT (V3 - TỰ CHỮA LÀNH)
-- ============================================
local IsMyTurn = false
local AutoEnabled = false
local AutoWord = nil
local CurrentSendKey = Enum.KeyCode.Unknown
local isListeningForKey = false

-- ⚠️ CHỈNH VỊ TRÍ DỌC BAN ĐẦU CỦA THANH DOCK (0 = trên cùng, 1 = dưới cùng)
local MINIMIZE_Y_POSITION = 0.1

local TURN_ON  = Color3.fromRGB(60, 230, 100)   -- Xanh lá = TỚI LƯỢT BẠN
local TURN_OFF = Color3.fromRGB(120, 120, 120)  -- Xám = chưa tới lượt
local TURN_PULSE = true          -- chấm xanh to lên 1 chút cho dễ thấy
local TURN_DEBUG = true          -- in log [TURN]
local TURN_KEEP_GREEN = false     -- true = gửi xong vẫn giữ xanh tới khi game báo người khác
local AUTO_DETECT_TURN = true

local statusDotRef = nil
local statusGuiRef = nil
local submittedThisTurn = false
local warnedNoDot = false

-- ===== VẼ CHẤM: đổi màu TRỰC TIẾP, không cache, tự tìm lại Frame =====
local function renderDot()
    local dot = statusDotRef
    if (not dot) or (not dot.Parent) then
        statusDotRef = nil
        if statusGuiRef then
            local f = statusGuiRef:FindFirstChild("StatusDot", true)
            if f then dot = f; statusDotRef = f end
        end
    end
    if not dot then
        if TURN_DEBUG and not warnedNoDot then
            warnedNoDot = true
            warn("[TURN] statusDotRef = nil → chưa dán Patch B hoặc Frame StatusDot chưa được tạo. Đèn sẽ không đổi màu.")
        end
        return
    end

    dot.BackgroundColor3 = IsMyTurn and TURN_ON or TURN_OFF
    dot.BackgroundTransparency = 0
    if IsMyTurn then
        dot.Size = TURN_PULSE and UDim2.new(0, 12, 0, 12) or UDim2.new(0, 9, 0, 9)
        dot.Position = TURN_PULSE and UDim2.new(0, 140, 0.5, -6) or UDim2.new(0, 142, 0.5, -4.5)
    else
        dot.Size = UDim2.new(0, 9, 0, 9)
        dot.Position = UDim2.new(0, 142, 0.5, -4.5)
    end
end

local function isMe(name)
    if type(name) ~= "string" then return false end
    return name == LocalPlayer.Name or name == LocalPlayer.DisplayName
end

local function tryAutoSubmit()
    if not (IsMyTurn and AutoEnabled and AutoWord and SubmitWord) then return end
    if submittedThisTurn then return end
    task.wait(0.5)
    if not (IsMyTurn and AutoEnabled and AutoWord and SubmitWord) then return end
    if submittedThisTurn then return end
    submittedThisTurn = true
    pcall(function() SubmitWord:FireServer(AutoWord) end)
    if not TURN_KEEP_GREEN then
        IsMyTurn = false
        renderDot()
    end
end

local function setTurn(state, source)
    state = state and true or false
    local changed = (state ~= IsMyTurn)
    if changed then
        IsMyTurn = state
        submittedThisTurn = false
        if TURN_DEBUG then
            print(("[TURN] %s | nguồn: %s"):format(
                state and "TỚI LƯỢT BẠN ✔" or "chưa tới lượt", tostring(source)))
        end
    end
    renderDot()               -- luôn vẽ lại, kể cả khi state không đổi (chống trôi màu)
    if IsMyTurn then task.spawn(tryAutoSubmit) end
end

-- ===== NGUỒN 1: remote gốc =====
if WriterChosen then
    WriterChosen.OnClientEvent:Connect(function(a, b)
        local name = nil
        if typeof(a) == "Instance" then
            name = a.Name
        elseif type(a) == "string" then
            name = a
        elseif type(b) == "string" then
            name = b
        end
        if name then
            setTurn(isMe(name), "WriterChosen -> " .. name)
        else
            setTurn(true, "WriterChosen (không kèm tên)")
        end
    end)
end

-- ===== NGUỒN 2: tự dò Attribute / ValueObject =====
local ATTR_KEYS = {
    "IsWriter", "IsMyTurn", "MyTurn", "Writer", "CurrentWriter",
    "WriterName", "CurrentWriterName", "Turn", "CurrentTurn", "TurnPlayer",
}
local VALUE_KEYS = {
    "CurrentWriter", "WriterName", "CurrentWriterName", "Writer",
    "CurrentTurn", "TurnPlayer", "Turn",
}

local cachedTurnObj, nextRescan = nil, 0

local function readTurnObj(obj)
    if not obj or not obj.Parent then return nil end
    if obj:IsA("StringValue") then return obj.Value end
    if obj:IsA("ObjectValue") then
        local v = obj.Value
        return (typeof(v) == "Instance") and v.Name or nil
    end
    if obj:IsA("BoolValue") then return obj.Value and LocalPlayer.Name or "" end
    return nil
end

local function resolveTurnObj()
    if cachedTurnObj and cachedTurnObj.Parent then return cachedTurnObj end
    cachedTurnObj = nil
    if os.clock() < nextRescan then return nil end
    nextRescan = os.clock() + 5
    for _, key in ipairs(VALUE_KEYS) do
        local o = ReplicatedStorage:FindFirstChild(key, true)
        if o and (o:IsA("StringValue") or o:IsA("ObjectValue") or o:IsA("BoolValue")) then
            cachedTurnObj = o; return o
        end
    end
    for _, key in ipairs(VALUE_KEYS) do
        local o = workspace:FindFirstChild(key)
        if o and (o:IsA("StringValue") or o:IsA("ObjectValue") or o:IsA("BoolValue")) then
            cachedTurnObj = o; return o
        end
    end
    return nil
end

if AUTO_DETECT_TURN then
    task.spawn(function()
        while true do
            task.wait(0.2)
                local result, src = nil, nil
                for _, key in ipairs(ATTR_KEYS) do
                    local v = LocalPlayer:GetAttribute(key)
                    if v ~= nil then
                        if type(v) == "boolean" then
                            result, src = (v and LocalPlayer.Name or ""), "Attribute " .. key
                        elseif typeof(v) == "Instance" then
                            result, src = v.Name, "Attribute " .. key
                        elseif type(v) == "string" then
                            result, src = v, "Attribute " .. key
                        end
                        if result then break end
                    end
                end
                if result == nil then
                    local obj = resolveTurnObj()
                    if obj then result, src = readTurnObj(obj), obj:GetFullName() end
                end
                if result ~= nil then setTurn(isMe(result), src) end
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
-- ══════════════ VŨ KHÍ ══════════════
{ word = "Minigun", cat = "Vũ khí", effect = "danger", info = "Minigun rơi từ hộp tiếp tế, xả đạn vào người chơi gần đó. Ai tới hộp trước thì lấy được." },
{ word = "Airstrike", cat = "Vũ khí", effect = "danger", info = "Máy bay phản lực bay ngang đảo và dội bom theo hàng. Núp dưới mái, đừng đứng thành cụm." },
{ word = "Tank", cat = "Vũ khí", effect = "danger", info = "Xe tăng quân đội lăn vào đảo, bắn phá mọi người chơi trong tầm ngắm. Khuất sau vật cản lớn." },
{ word = "Laser", cat = "Vũ khí", effect = "danger", info = "Các tia laser quét ngang sàn nhà. Nhảy theo nhịp hoặc đứng lên chỗ cao." },
{ word = "Bomb", cat = "Vũ khí", effect = "danger", info = "Quả bom sống bám theo người chơi trước khi phát nổ. Chạy liên tục và đổi hướng để cắt đuôi. Từ cùng nghĩa: Big Bang." },
{ word = "Sniper", cat = "Vũ khí", effect = "danger", info = "Súng bắn tỉa hạng nặng (.50 cal) rơi xuống cho mọi người. Đứng yên một chỗ là ăn đạn." },
{ word = "AWP", cat = "Vũ khí", effect = "danger", info = "Súng bắn tỉa rơi trên bản đồ cho ai nhặt trước. Đừng đứng giữa trời trống." },
{ word = "Barrett", cat = "Vũ khí", effect = "danger", info = "Súng bắn tỉa hạng nặng rơi cho người chơi nhặt. Cực nguy hiểm ở khoảng cách xa." },
{ word = "Railgun", cat = "Vũ khí", effect = "danger", info = "Súng trường có ống ngắm, bắn xuyên rất mạnh. Không đứng yên giữa bản đồ." },
{ word = "G3", cat = "Vũ khí", effect = "danger", info = "Súng trường chiến đấu bắn như súng tỉa. Giữ vật cản giữa bạn và người cầm." },
{ word = "RPG", cat = "Vũ khí", effect = "danger", info = "Súng phóng tên lửa, đạn nổ tung cả mặt đất. Đừng đứng trên nền có thể bị bắn sập." },
{ word = "AT4", cat = "Vũ khí", effect = "danger", info = "Súng chống tăng một phát đạn cực lớn rơi trên bản đồ. Né khỏi hướng ngắm." },
{ word = "Sticky Launcher", cat = "Vũ khí", effect = "danger", info = "Súng bắn bom dính, bom nổ sau khi bám vào bề mặt. Chạy khỏi chỗ vừa bị dính." },
{ word = "Flamethrower", cat = "Vũ khí", effect = "danger", info = "Súng phun lửa thành luồng phía trước. Tuyệt đối không đứng trước mặt người cầm." },
{ word = "Hyperlaser", cat = "Vũ khí", effect = "danger", info = "Súng laser siêu mạnh rơi xuống và bắn liên tục vào người chơi. Né theo đường zic-zac." },
{ word = "Orbital Strike", cat = "Vũ khí", effect = "danger", info = "Người viết nhìn từ trên cao và gọi một tia laser cực lớn xuống điểm tự chọn." },
{ word = "Ban Everyone", cat = "Vũ khí", effect = "danger", info = "Một chiếc búa ban khổng lồ rơi từ trời. Nhìn bóng trên mặt đất mà chạy ra ngoài. Từ cùng nghĩa: Ban." },
{ word = "Death Note", cat = "Vũ khí", effect = "danger", info = "Người viết nhận quyển Death Note, chọn một người chơi và chọn kiểu chết cho họ." },
{ word = "Chainsaw", cat = "Vũ khí", effect = "danger", info = "Cưa máy rơi trên bản đồ, ai nhặt được thì chém rất đau. Tránh xa người cầm." },
{ word = "Fire Axe", cat = "Vũ khí", effect = "danger", info = "Rìu chữa cháy rơi trên bản đồ, dùng làm vũ khí cận chiến. Giữ khoảng cách." },
{ word = "Pickaxe", cat = "Vũ khí", effect = "danger", info = "Cúp rơi trên bản đồ, dùng như vũ khí cận chiến. Tránh tầm với." },
{ word = "Machete", cat = "Vũ khí", effect = "danger", info = "Dao rựa rơi cho người chơi nhặt. Đừng để bị áp sát." },
{ word = "Katana", cat = "Vũ khí", effect = "danger", info = "Kiếm samurai rơi trên bản đồ. Ai nhặt trước thì có lợi thế lớn." },
{ word = "Sword", cat = "Vũ khí", effect = "danger", info = "Kiếm cơ bản rơi trên bản đồ cho mọi người nhặt. Đánh cận chiến khá mạnh." },
{ word = "Great Blade", cat = "Vũ khí", effect = "danger", info = "Đại kiếm hai tay khổng lồ rơi cho người chơi nhặt. Sát thương cao." },
{ word = "Gunblade", cat = "Vũ khí", effect = "danger", info = "Vũ khí lai kiếm và súng, bắn như súng lục. Rơi trên bản đồ." },
{ word = "Frying Pan", cat = "Vũ khí", effect = "danger", info = "Chảo rán để đập người, dạng vũ khí đùa nhưng vẫn gây sát thương." },
{ word = "Baton", cat = "Vũ khí", effect = "danger", info = "Dùi cui cảnh sát rơi trên bản đồ, đánh cận chiến." },
{ word = "Book", cat = "Vũ khí", effect = "danger", info = "Cuốn sách ném được, chủ yếu là vũ khí đùa. Né nếu có ai ném tới." },
{ word = "Snowball", cat = "Vũ khí", effect = "danger", info = "Bóng tuyết cho mọi người ném nhau. Nguy hiểm nếu bị ném lúc đứng gần mép đảo." },
{ word = "MP5", cat = "Vũ khí", effect = "neutral", info = "Súng tiểu liên rơi trên bản đồ. Nhanh tay nhặt hoặc nấp đi." },
{ word = "Uzi", cat = "Vũ khí", effect = "neutral", info = "Súng tiểu liên rơi cho người chơi nhặt. Bắn rất nhanh." },
{ word = "Tommy", cat = "Vũ khí", effect = "neutral", info = "Súng Tommy (tiểu liên thời cổ) rơi trên bản đồ. Ai nhặt trước thì được." },
{ word = "Sterling", cat = "Vũ khí", effect = "neutral", info = "Súng tiểu liên rơi cho người chơi nhặt. Nhặt trước hoặc nấp." },
{ word = "AM180", cat = "Vũ khí", effect = "neutral", info = "Súng tiểu liên rơi trên bản đồ. Tốc độ bắn cao." },
{ word = "G36", cat = "Vũ khí", effect = "neutral", info = "Súng trường rơi cho người chơi nhặt. Cân bằng và dễ dùng." },
{ word = "AUG", cat = "Vũ khí", effect = "neutral", info = "Súng trường rơi trên bản đồ. Nhặt trước hoặc giữ vật cản." },
{ word = "Blaster", cat = "Vũ khí", effect = "neutral", info = "Súng trường rơi cho người chơi nhặt. Sát thương ổn." },
{ word = "Amerigun", cat = "Vũ khí", effect = "neutral", info = "Súng trường in cờ Mỹ rơi trên bản đồ. Chỉ để nhặt." },
{ word = "Musket", cat = "Vũ khí", effect = "neutral", info = "Súng hỏa mai cổ rơi cho người chơi nhặt. Bắn chậm nhưng mạnh." },
{ word = "Blunderbuss", cat = "Vũ khí", effect = "neutral", info = "Súng shotgun cổ rơi trên bản đồ. Tầm gần rất đau." },
{ word = "Double Barrel", cat = "Vũ khí", effect = "neutral", info = "Shotgun hai nòng rơi cho người chơi nhặt. Tránh tầm gần." },
{ word = "Remington", cat = "Vũ khí", effect = "neutral", info = "Shotgun bơm rơi trên bản đồ. Mạnh ở cự ly gần." },
{ word = "Striker", cat = "Vũ khí", effect = "neutral", info = "Shotgun chiến đấu rơi cho người chơi nhặt. Bắn liên tiếp." },
{ word = "Benelli", cat = "Vũ khí", effect = "neutral", info = "Shotgun rơi trên bản đồ cho mọi người nhặt." },
{ word = "M1911", cat = "Vũ khí", effect = "neutral", info = "Súng lục rơi trên bản đồ. Sát thương vừa, dễ nhặt." },
{ word = "SOCOM", cat = "Vũ khí", effect = "neutral", info = "Súng lục rơi cho người chơi nhặt. Bắn nhanh, chính xác." },
{ word = "Luger", cat = "Vũ khí", effect = "neutral", info = "Súng lục rơi trên bản đồ. Nhặt trước hoặc nấp đi." },
{ word = "Magnum", cat = "Vũ khí", effect = "neutral", info = "Súng lục hạng nặng rơi trên bản đồ. Một phát rất đau." },
{ word = "Revolver", cat = "Vũ khí", effect = "neutral", info = "Súng lục ổ xoay rơi cho người chơi nhặt. Chậm nhưng mạnh." },
{ word = "Steamgun", cat = "Vũ khí", effect = "neutral", info = "Súng lục hơi nước rơi trên bản đồ cho mọi người nhặt." },
{ word = "Spencer", cat = "Vũ khí", effect = "neutral", info = "Súng trường rơi trên mặt đất, ai cũng nhặt được." },
{ word = "Gun", cat = "Vũ khí", effect = "neutral", info = "Một khẩu súng ngẫu nhiên thả xuống, tìm theo làn khói đỏ. Từ cùng nghĩa: Weapon." },
{ word = "Guns", cat = "Vũ khí", effect = "neutral", info = "Súng cho tất cả mọi người, đạn có hạn và có thể bị cướp." },
{ word = "Melee", cat = "Vũ khí", effect = "neutral", info = "Vũ khí cận chiến ngẫu nhiên trong thùng có khói đỏ, ai tới trước thì lấy." },
{ word = "Baseball Bat", cat = "Vũ khí", effect = "neutral", info = "Nhiều gậy bóng chày xuất hiện trên bản đồ, đánh nhau kêu bonk." },
{ word = "Knife", cat = "Vũ khí", effect = "neutral", info = "Dao rơi ở vị trí ngẫu nhiên, ai cũng có thể nhặt. Khác với Kill." },
{ word = "Kill", cat = "Vũ khí", effect = "help", info = "Tặng ngay cho người viết một con dao để tấn công, không cần đi nhặt." },
{ word = "Shield", cat = "Vũ khí", effect = "help", info = "Khiên chống bạo động chặn được đòn tấn công. Rơi trên bản đồ." },
{ word = "Admin", cat = "Vũ khí", effect = "help", info = "Nhận thanh kiếm admin (bản thường, không phải meta /admin mất Robux)." },

-- ══════════════ QUÁI VẬT ══════════════
{ word = "Mahoraga", cat = "Quái vật", effect = "danger", image = MAHORAGA_IMAGE_ID, info = "Mahoraga trồi lên khỏi mặt đất và đuổi theo người chơi, có thể nhảy xa. Nhìn bóng của nó để đoán hướng." },
{ word = "Robot", cat = "Quái vật", effect = "neutral", info = "Bắt đầu trò đèn đỏ - đèn xanh. Đèn đỏ mà nhúc nhích là bị laser bắn." },
{ word = "Mummy", cat = "Quái vật", effect = "danger", info = "Từng đợt xác ướp xuất hiện, bắt được ai là quấn chặt người đó lại." },
{ word = "Angel", cat = "Quái vật", effect = "danger", info = "Một thiên thần khổng lồ hiện ra và phán xét, tấn công những người còn sống." },
{ word = "Giant", cat = "Quái vật", effect = "danger", info = "Người khổng lồ noob đi quanh đảo, giẫm lên bất kỳ ai cản đường. Lưu ý: nó không làm bạn to lên." },
{ word = "Zombie", cat = "Quái vật", effect = "danger", info = "Một đám zombie săn lùng người chơi tới hết trận. Đừng đứng yên một chỗ quá lâu. Từ cùng nghĩa: Zombies." },
{ word = "Slenderman", cat = "Quái vật", effect = "danger", info = "Slenderman xuất hiện. Tuyệt đối không nhìn thẳng vào mặt hắn." },
{ word = "Skeleton", cat = "Quái vật", effect = "danger", info = "Những bộ xương xuất hiện và ném xương vào bạn. Nấp sau vật cản." },
{ word = "Pirate", cat = "Quái vật", effect = "danger", info = "Tàu cướp biển áp vào đảo và bắn đại bác. Núp sau vật cản cứng." },
{ word = "Invisible", cat = "Quái vật", effect = "danger", info = "Một kẻ săn vô hình ám theo người chơi. Di chuyển liên tục, đừng đứng im." },
{ word = "Alien", cat = "Quái vật", effect = "danger", info = "UFO hiện ra và dùng tia sáng xanh bắt người chơi lên khỏi bản đồ. Tránh khỏi luồng sáng." },
{ word = "Slime", cat = "Quái vật", effect = "danger", info = "Những con slime nhún nhảy, ai bị đè trúng là bẹp. Quan sát hướng chúng nảy." },
{ word = "Vampire", cat = "Quái vật", effect = "danger", info = "Ma cà rồng trồi ra khỏi quan tài và tấn công. Nghe tiếng cười là chạy ngay." },
{ word = "Monster", cat = "Quái vật", effect = "danger", info = "Quái vật có sừng săn theo tiếng động, ai chạy nhanh sẽ bị khóa mục tiêu. Đi bộ sẽ an toàn hơn." },
{ word = "Dragon", cat = "Quái vật", effect = "danger", info = "Rồng bay lơ lửng trên đảo, dừng lại là sắp phun lửa. Né khỏi hướng đầu rồng." },
{ word = "Werewolf", cat = "Quái vật", effect = "danger", info = "Người sói trà trộn giữa các người chơi và tấn công khi hú. Nghe hú thì leo cao." },
{ word = "Skinwalker", cat = "Quái vật", effect = "danger", info = "Thứ gì đó bắt chước hình dáng một người chơi rồi trở mặt. Cảnh giác với người lạ. Từ cùng nghĩa: Cartman, Mr Bean." },
{ word = "Gnome", cat = "Quái vật", effect = "danger", info = "Tượng gnome trong vườn đổi vị trí mỗi khi bạn không nhìn. Vừa lùi vừa quan sát." },
{ word = "SCP-096", cat = "Quái vật", effect = "danger", info = "SCP-096 xuất hiện, nhìn vào mặt nó là chết. Quay camera đi chỗ khác. Từ cùng nghĩa: SCP." },
{ word = "Evil Clowns", cat = "Quái vật", effect = "danger", info = "Những chú hề đáng sợ chạy lung tung trên bản đồ. Đừng để bị dồn góc. Từ cùng nghĩa: Clown." },
{ word = "Arise", cat = "Quái vật", effect = "danger", info = "Triệu hồi một toán kỵ sĩ bóng tối đuổi theo người chơi. Thoát khỏi vùng bóng tối." },
{ word = "Shark", cat = "Quái vật", effect = "danger", info = "Cá mập xuất hiện dưới nước và tấn công người bơi. Đừng xuống nước, hoặc biến sàn thành Lava." },
{ word = "Ant", cat = "Quái vật", effect = "danger", info = "Tổ kiến mở ra, kiến bò khắp nơi và cắn người. Rời khỏi gần tổ và leo lên chỗ cao." },
{ word = "Horror", cat = "Quái vật", effect = "danger", info = "Màn đêm đáng sợ ập xuống và một con quái vật gia nhập bản đồ." },
{ word = "Worm", cat = "Quái vật", effect = "danger", info = "Con giun khổng lồ đâm lên khỏi mặt đất. Nhìn mặt đất và né khỏi điểm nó trồi lên." },
{ word = "Whale", cat = "Quái vật", effect = "danger", info = "Cá voi rơi bụng xuống bản đồ. Nhìn lên trời và né khỏi điểm nó sẽ đáp." },
{ word = "Snake", cat = "Quái vật", effect = "danger", info = "Rắn khổng lồ xuất hiện và lao tới tấn công. Tránh khỏi tầm với." },
{ word = "Wolf", cat = "Quái vật", effect = "danger", info = "Bầy sói hú gầm đi khắp đảo. Leo cao hoặc vào trong nhà." },
{ word = "Lion", cat = "Quái vật", effect = "danger", info = "Sư tử xuất hiện, đi lang thang khắp đảo. Tìm chỗ cao hoặc kín." },
{ word = "Frog", cat = "Quái vật", effect = "danger", info = "Ếch xuất hiện và dùng lưỡi kéo người chơi. Giữ khoảng cách." },
{ word = "Mosquito", cat = "Quái vật", effect = "danger", info = "Muỗi phủ kín không trung và đốt những người còn lại. Tìm chỗ kín để trú." },
{ word = "Cockroach", cat = "Quái vật", effect = "danger", info = "Bầy gián phủ kín mặt đất. Leo lên chỗ cao nếu thấy khó chịu." },
{ word = "Bees", cat = "Quái vật", effect = "danger", info = "Một đám ong giận dữ bay khắp bản đồ, ai đi qua là bị đốt liên tục. Trốn vào nhà." },
{ word = "Jellyfish", cat = "Quái vật", effect = "danger", info = "Sứa trôi qua và chích người chạm phải. Tránh xa đường trôi của chúng." },
{ word = "Devil", cat = "Quái vật", effect = "danger", info = "Ác quỷ xuất hiện và ném cầu lửa vào người chơi. Dùng nhà cửa chặn đòn." },
{ word = "Ninja", cat = "Quái vật", effect = "danger", info = "Ninja xuất hiện và ném phi tiêu. Luôn giữ vật cản giữa bạn và chúng." },
{ word = "Ogre", cat = "Quái vật", effect = "danger", info = "Ogre chiếm một vùng đầm lầy trên bản đồ. Tránh xa khu đầm đó." },
{ word = "Animatronic", cat = "Quái vật", effect = "danger", info = "Animatronic chỉ di chuyển khi bạn không nhìn. Giữ camera vào nó và lùi dần." },
{ word = "Nextbot", cat = "Quái vật", effect = "danger", info = "Nextbot đuổi người chơi với tốc độ tối đa. Chạy và dùng chướng ngại cắt đuôi." },
{ word = "Ghost", cat = "Quái vật", effect = "danger", info = "Hồn ma ám bản đồ, chạm vào ai là gây sát thương. Giữ khoảng cách." },
{ word = "Siren Head", cat = "Quái vật", effect = "danger", info = "Siren Head săn theo tiếng bước chân. Đi bộ thay vì chạy để ít tiếng động." },
{ word = "Reaper", cat = "Quái vật", effect = "danger", info = "Thần chết nhắm vào người có máu thấp nhất. Hồi máu sớm để không bị chọn." },
{ word = "Kaiju", cat = "Quái vật", effect = "danger", info = "Kaiju khổng lồ trồi lên từ biển và bắn tia sáng xanh. Giữ khoảng cách và né tia." },
{ word = "Doom", cat = "Quái vật", effect = "danger", info = "Doom xuất hiện và bắn tia liên tục vào người chơi. Né theo nhịp bắn." },
{ word = "Final Boss", cat = "Quái vật", effect = "danger", info = "Trùm cuối xuất hiện, người chơi có thể nhặt vũ khí của trùm để đánh lại. Né hoặc hợp sức." },
{ word = "Noob", cat = "Quái vật", effect = "danger", info = "Một đám noob vụng về xuất hiện và đấm mọi người. Leo cao hoặc né." },
{ word = "Seek", cat = "Quái vật", effect = "danger", info = "Seek trong Doors bắt đầu truy đuổi, phải chạy qua các cánh cửa để thoát. Không được dừng." },
{ word = "Verity", cat = "Quái vật", effect = "danger", info = "Verity xuất hiện dưới dạng bạn đồng hành. Nhiều người chơi nói đừng nên gõ từ này." },
{ word = "Grizzly Bear", cat = "Quái vật", effect = "danger", info = "Gấu xám xuất hiện và đuổi theo người gần nó. Chạy và leo cao. Từ cùng nghĩa: Bear." },
{ word = "Crocodile", cat = "Quái vật", effect = "danger", info = "Cá sấu xuất hiện và tấn công người gần nó. Giữ khoảng cách." },
{ word = "Cow", cat = "Quái vật", effect = "danger", info = "Bò xuất hiện và đá bất kỳ ai đứng phía sau. Đừng đi sau lưng bò." },
{ word = "Goose", cat = "Quái vật", effect = "danger", info = "Một con ngỗng giận dữ xuất hiện và rít lên với người chơi. Cho nó thật nhiều khoảng trống." },
{ word = "Rat", cat = "Quái vật", effect = "danger", info = "Một bầy chuột khổng lồ tràn khắp đảo. Leo lên vật cao để thoát." },
{ word = "Zoo", cat = "Quái vật", effect = "danger", info = "Sở thú xuất hiện và con sư tử trong đó xổng ra. Rời xa sư tử và tìm chỗ cao." },

-- ══════════════ ĐỘNG VẬT & MEME CREATURE ══════════════
{ word = "KingKong", cat = "Động vật", effect = "danger", info = "Khỉ đột khổng lồ xuất hiện tìm người chơi để ném. Thực tế khá vô hại nhưng vẫn nên tránh." },
{ word = "Doge", cat = "Động vật", effect = "danger", info = "Chú chó Doge khổng lồ đuổi theo người chơi khắp đảo. Chạy và dùng nhà cửa cắt đường." },
{ word = "Tung Tung Sahur", cat = "Động vật", effect = "danger", info = "Nhân vật meme Tung Tung Tung Sahur xuất hiện và truy đuổi người chơi. Từ cùng nghĩa: Tung." },
{ word = "Trippi Troppi", cat = "Động vật", effect = "danger", info = "Sinh vật meme Trippi Troppi lao lên khỏi mặt nước. Tránh xa mép nước. Từ cùng nghĩa: Trippi." },
{ word = "Dinosaur", cat = "Động vật", effect = "danger", info = "Khủng long T-Rex khổng lồ săn lùng người chơi trên mặt đất. Từ cùng nghĩa: T-Rex." },
{ word = "Godzilla", cat = "Động vật", effect = "danger", info = "Gõ Godzilla thì game chuyển thành khủng long T-Rex vì đó là hiệu ứng gần nhất. Sát thương thấp." },
{ word = "Elephant", cat = "Động vật", effect = "neutral", info = "Voi xuất hiện và xịt nước từ vòi ra xung quanh. Nhìn chung không nguy hiểm." },
{ word = "Monkey", cat = "Động vật", effect = "danger", info = "Những con khỉ ném vỏ chuối trên mặt đất, dễ bị trượt ngã. Nhìn trước khi bước." },
{ word = "Spider", cat = "Động vật", effect = "danger", info = "Nhện khổng lồ xuất hiện cùng đám nhện nhỏ. Đừng để bị bao vây." },
{ word = "Octopus", cat = "Động vật", effect = "danger", info = "Bạch tuộc khổng lồ dùng vòi tóm lấy người chơi ganh gần. Tránh khỏi tầm với." },
{ word = "Cat", cat = "Động vật", effect = "neutral", info = "Một chú mèo meme khổng lồ xuất hiện trên bản đồ. Nhiều người gõ là Maxwell." },
{ word = "Dog", cat = "Động vật", effect = "neutral", info = "Một NPC chó thân thiện xuất hiện. Không nguy hiểm, không cần né." },
{ word = "Pig", cat = "Động vật", effect = "neutral", info = "Những chú lợn đi quanh kêu ụt ịt. Không nguy hiểm, có thể bỏ qua." },
{ word = "Sheep", cat = "Động vật", effect = "neutral", info = "Một đàn cừu nhút nhát đi lang thang trên bản đồ. Không nguy hiểm." },
{ word = "Rabbit", cat = "Động vật", effect = "neutral", info = "Thỏ xuất hiện và sinh sản liên tục thành cả đàn. Không nguy hiểm." },
{ word = "Penguin", cat = "Động vật", effect = "neutral", info = "Chim cánh cụt trượt bụng trên bản đồ. Không nguy hiểm." },
{ word = "Unicorn", cat = "Động vật", effect = "neutral", info = "Một con kỳ lân nhút nhát đi lạc lên đảo. Không nguy hiểm." },
{ word = "Moo Deng", cat = "Động vật", effect = "neutral", info = "Những chú hà mã con đang cáu đi lang thang. Không nguy hiểm. Từ cùng nghĩa: Moodeng." },
{ word = "Herobrine", cat = "Động vật", effect = "neutral", info = "Một bóng người mắt trắng đứng nhìn từ xa. Không tấn công nhưng hãy để mắt tới nó." },
{ word = "Leprechaun", cat = "Động vật", effect = "neutral", info = "Yêu tinh lùn xuất hiện, người chơi có thể đuổi theo. Không nguy hiểm." },
{ word = "Capybara", cat = "Động vật", effect = "help", info = "Những chú capybara hiền xuất hiện và hồi máu cho người chơi đứng gần." },
{ word = "Chicken", cat = "Động vật", effect = "help", info = "Gà xuất hiện cùng trứng để nhặt và ăn hồi máu." },
{ word = "Fish", cat = "Động vật", effect = "neutral", info = "Trời mưa cá xuống khắp bản đồ. Về cơ bản chỉ là hiệu ứng vui mắt." },

-- ══════════════ THẢM HỌA ══════════════
{ word = "Nuke", effect = "danger", image = NUKE_IMAGE_ID, info = "Bom hạt nhân rơi xuống đảo. Ai ở ngoài trời lúc nổ là chết, hãy chạy vào bunker ngay. Từ cùng nghĩa: Fallout." },
{ word = "Acid", cat = "Thảm họa", effect = "danger", info = "Mưa axit đổ xuống, ai không có mái che đều mất máu, kể cả người gõ từ. Từ cùng nghĩa: Acid Rain, Limnic Eruption." },
{ word = "Meteor", cat = "Thảm họa", effect = "danger", info = "Mưa thiên thạch kéo dài tới hết trận và vẫn gây sát thương sau khi đáp, phá được cả bunker. Từ cùng nghĩa: Meteors, Meteor Shower." },
{ word = "Flash Flood", cat = "Thảm họa", effect = "danger", info = "Một dòng sông bùn cuồn cuộn chảy ngang và cuốn người chơi đi." },
{ word = "Lava", cat = "Thảm họa", effect = "danger", info = "Sàn nhà biến thành dung nham rồi nguội đi và lặp lại liên tục. Leo lên chỗ cao. Từ cùng nghĩa: The Floor Is Lava." },
{ word = "Tornado", cat = "Thảm họa", effect = "danger", info = "Lốc xoáy di chuyển khắp đảo, ai tới gần sẽ bị hút vào. Đứng về phía ngược lại." },
{ word = "Black Hole", cat = "Thảm họa", effect = "danger", info = "Hố đen mở ra và hút người chơi vào, tới tâm là chết. Đứng tản ra, đừng tụm một chỗ." },
{ word = "Tsunami", cat = "Thảm họa", effect = "danger", info = "Sóng thần quét qua đảo, có thể có sóng thứ hai. Leo lên đỉnh công trình cao nhất." },
{ word = "Flood", cat = "Thảm họa", effect = "danger", info = "Nước dâng khắp bản đồ và giữ nguyên tới khi bị xoá. Lên mái nhà, tháp hoặc thuyền." },
{ word = "Satellite", cat = "Thảm họa", effect = "danger", info = "Vệ tinh rơi khỏi quỹ đạo và đâm xuống bản đồ. Nhìn lên và rời khỏi điểm rơi." },
{ word = "Volcano", cat = "Thảm họa", effect = "danger", info = "Núi lửa xuất hiện trên đảo và phun đá dung nham ra xung quanh. Núp dưới mái." },
{ word = "Supernova", cat = "Thảm họa", effect = "danger", info = "Mặt trời phát nổ trên bản đồ, phải trốn vào trong hoặc sau vật cản rắn tới khi hết." },
{ word = "Fire", cat = "Thảm họa", effect = "danger", info = "Cháy rừng lan từng mảng trên cỏ và gỗ. Chạy ra chỗ đất trống hoặc gõ Rain để dập." },
{ word = "Earthquake", cat = "Thảm họa", effect = "danger", info = "Mặt đất rung chuyển và nứt ra, có trận còn cắt đôi bản đồ. Tránh xa vết nứt." },
{ word = "Apocalypse", cat = "Thảm họa", effect = "danger", info = "Chuỗi thảm họa: thiên thạch, rồi mặt đất vỡ và động đất. Có thể định hình lại cả bản đồ." },
{ word = "Destruction", cat = "Thảm họa", effect = "danger", info = "Mặt đất nứt ra, sau đó vùng bị nứt phát nổ. Tránh khỏi khu vực đó." },
{ word = "Boulder", cat = "Thảm họa", effect = "danger", info = "Một tảng đá khổng lồ lăn vào và nằm lại trên bản đồ. Đừng đứng trên đường lăn." },
{ word = "Quicksand", cat = "Thảm họa", effect = "danger", info = "Cát lún xuất hiện, ai bước vào là bị nuốt. Tránh các hố cát lún." },
{ word = "Antimatter", cat = "Thảm họa", effect = "danger", info = "Phản vật chất hút vật thể lên rồi thả xuống, nổ tung hoặc xoá luôn mặt đất. Tránh xa." },
{ word = "Wind", cat = "Thảm họa", effect = "danger", info = "Gió giật mạnh thổi người chơi bay khắp bản đồ. Tránh xa mép đảo, đứng sau vật cản." },
{ word = "Sandstorm", cat = "Thảm họa", effect = "danger", info = "Bức tường cát mù mịt quét qua, gần như không nhìn thấy gì. Vào chỗ trú. Từ cùng nghĩa: Duststorm." },
{ word = "Hail", cat = "Thảm họa", effect = "danger", info = "Mưa đá rơi liên tục đến hết trận. Luôn có mái che rắn ở gần." },
{ word = "Lightning", cat = "Thảm họa", effect = "danger", info = "Sét đánh liên tục xuống đảo. Di chuyển và vào chỗ có mái." },
{ word = "Heat", cat = "Thảm họa", effect = "danger", info = "Sóng nhiệt quét qua bản đồ, nhiệt độ tăng vọt. Tìm bóng râm hoặc chỗ trú." },
{ word = "Avalanche", cat = "Thảm họa", effect = "danger", info = "Một bức tường tuyết ập xuống đảo. Đứng ở chỗ đất cao." },
{ word = "Titanic", cat = "Thảm họa", effect = "danger", info = "Một con tàu biển khổng lồ tiến vào đảo rồi đâm vào băng. Tránh xa tới khi cảnh kết thúc." },
{ word = "Rumbling", cat = "Thảm họa", effect = "danger", info = "Những người khổng lồ đứng thành hàng và dậm bước từ đầu này sang đầu kia đảo. Bay lên để thoát." },
{ word = "Sharknado", cat = "Thảm họa", effect = "danger", info = "Một cơn lốc xoáy toàn cá mập di chuyển khắp bản đồ." },
{ word = "Zone", cat = "Thảm họa", effect = "danger", info = "Một vòng tròn an toàn xuất hiện và co dần vào giữa. Vào giữa sớm để không bị kẹt ngoài." },
{ word = "Backrooms", cat = "Thảm họa", effect = "danger", info = "Người chơi bị dịch vào Backrooms, mê cung phòng vàng có quái vật, nhiều cửa là cửa giả. Tìm cửa thật." },
{ word = "Hunger", cat = "Thảm họa", effect = "danger", info = "Mọi người chơi đều đói và thức ăn rơi từ trời xuống. Nhặt ngay khi có thể." },
{ word = "Snap", cat = "Thảm họa", effect = "danger", info = "Một nửa mọi thứ hoá thành tro, người chơi bị xoá ngẫu nhiên. Không có cách chống, chỉ có may mắn." },
{ word = "Time Stop", cat = "Thảm họa", effect = "danger", info = "Mọi người trừ người viết bị đóng băng tại chỗ. Hãy đứng ở chỗ an toàn trước khi bị đóng băng. Từ cùng nghĩa: Timestop, Dio Brando." },
{ word = "Plague", cat = "Thảm họa", effect = "danger", info = "Người chơi bị bệnh, da chuyển xanh và mất máu dần. Hồi máu bằng Watermelon hoặc Full Health. Từ cùng nghĩa: Common Cold, Stomach Virus, Epidemic." },
{ word = "Energy Beams", cat = "Thảm họa", effect = "danger", info = "Người viết ngắm tia năng lượng vào từng người chơi, ai cũng phải né. Nhảy và đổi hướng liên tục. Từ cùng nghĩa: Energy Blast." },
{ word = "Locust", cat = "Thảm họa", effect = "danger", info = "Đám châu chấu ăn sạch mọi cây cỏ trên bản đồ nên chỗ nấp của bạn biến mất." },
{ word = "Blackout", cat = "Thảm họa", effect = "danger", info = "Trời tối sập xuống và mất điện, cả bản đồ tối om. Nhiều người nói nó giống hệt Night." },
{ word = "Pikachu", cat = "Thảm họa", effect = "danger", info = "Pikachu gọi sét xuống, giật điện những người đứng gần nhau. Đứng tản ra." },

-- ══════════════ THỜI TIẾT & THIÊN NHIÊN ══════════════
{ word = "Rain", cat = "Thời tiết", effect = "neutral", info = "Mưa bắt đầu rơi trên đảo, làm mặt đất trơn và dập tắt mọi đám cháy." },
{ word = "Snow", cat = "Thời tiết", effect = "danger", info = "Bão tuyết lạnh buốt quét qua đảo. Vào trong nhà hoặc dưới mái tới khi hết." },
{ word = "Storm", cat = "Thời tiết", effect = "danger", info = "Mưa, sấm sét và gió mạnh cùng lúc. Núp dưới mái và tránh xa mép đảo." },
{ word = "Fog", cat = "Thời tiết", effect = "neutral", info = "Sương mù dày đặc kéo tới, giảm hẳn tầm nhìn. Tự nó không gây sát thương nhưng che mất mối nguy." },
{ word = "Night", cat = "Thời tiết", effect = "neutral", info = "Trời chuyển sang ban đêm, đảo tối om, mối nguy khó thấy hơn. Đứng ở nơi bạn thuộc đường." },
{ word = "Day", cat = "Thời tiết", effect = "neutral", info = "Mặt trời mọc trở lại, đồng thời xoá được thời tiết xấu." },
{ word = "Ice", cat = "Thời tiết", effect = "neutral", info = "Mọi bề mặt đóng băng và trơn trượt. Đi chậm, tránh xa mép đảo. Từ cùng nghĩa: Freeze." },
{ word = "Moon", cat = "Thời tiết", effect = "neutral", info = "Một mặt trăng khổng lồ xuất hiện trên đảo. Chú ý bóng của nó và di chuyển liên tục." },
{ word = "Desert", cat = "Thiên nhiên", effect = "neutral", info = "Hòn đảo biến thành sa mạc với các mesa cao, da bạn đỏ lên vì nóng. Leo mesa và ăn dưa hấu." },
{ word = "Swamp", cat = "Thiên nhiên", effect = "neutral", info = "Sàn biến thành đầm lầy với các vũng nước đục làm chậm người chơi khi đi qua." },
{ word = "Mud", cat = "Thiên nhiên", effect = "neutral", info = "Những vũng bùn xuất hiện làm chậm di chuyển, tác dụng giống vũng của Swamp." },
{ word = "Sunset", cat = "Thời tiết", effect = "neutral", info = "Mặt trời lặn dần xuống chân trời, ánh sáng trên đảo đổi màu." },
{ word = "Autumn", cat = "Thiên nhiên", effect = "neutral", info = "Hòn đảo chuyển sang màu thu, lá rụng khắp nơi. Chỉ là hiệu ứng hình ảnh." },
{ word = "Flowers", cat = "Thiên nhiên", effect = "neutral", info = "Một vườn hoa nở rộ khắp bản đồ. Không có tác dụng phụ." },
{ word = "Tree", cat = "Thiên nhiên", effect = "neutral", info = "Cây mọc khắp nơi biến bản đồ thành rừng. Có thể làm chỗ nấp nhưng sẽ cháy nếu có Fire." },
{ word = "Grass", cat = "Thiên nhiên", effect = "neutral", info = "Cỏ dài mọc lên, có thể ngồi xuống để nấp. Chạy ra ngoài nếu có cháy." },
{ word = "Bush", cat = "Thiên nhiên", effect = "neutral", info = "Những bụi cây xuất hiện, có thể chui vào để giấu mình khỏi tầm nhìn." },
{ word = "Bamboo", cat = "Thiên nhiên", effect = "neutral", info = "Những cụm tre xuất hiện, có thể dùng làm vật cản che tầm nhìn." },
{ word = "Island", cat = "Thiên nhiên", effect = "neutral", info = "Một hòn đảo nhỏ với cây cọ trồi lên khỏi mặt nước. Chỉ là thêm đất, không nguy hiểm." },
{ word = "Underwater", cat = "Thiên nhiên", effect = "neutral", info = "Hòn đảo chuyển sang diện mạo dưới đáy biển. Chỉ đổi hình ảnh." },
{ word = "Waterfall", cat = "Thiên nhiên", effect = "neutral", info = "Một vách núi có thác nước đổ xuống xuất hiện trên bản đồ." },
{ word = "Clear Skies", cat = "Thời tiết", effect = "help", info = "Thời tiết trở lại bình thường và nước lũ rút hết. Từ cùng nghĩa: No Flood, Clear." },
{ word = "Normal", cat = "Thời tiết", effect = "help", info = "Hoàn tác mọi thay đổi, bản đồ và luật chơi trở về như ban đầu. Dùng để dọn đống hiệu ứng hỗn loạn." },
{ word = "Dry", cat = "Thời tiết", effect = "help", info = "Nước lũ rút đi và bản đồ khô trở lại." },

-- ══════════════ ĐỊA ĐIỂM ══════════════
{ word = "Hell", cat = "Địa điểm", effect = "danger", info = "Mở ra Địa ngục với những miệng núi lửa rực lửa bao quanh mọi người chơi." },
{ word = "Heaven", cat = "Địa điểm", effect = "help", info = "Một cầu thang mây dẫn lên tận trời, leo lên là nhận được vòng hào quang và thoát khỏi mặt đất." },
{ word = "Maze", cat = "Địa điểm", effect = "neutral", info = "Một mê cung hàng rào cây mọc lên trên bản đồ, có thể dùng để trốn." },
{ word = "Farm", cat = "Địa điểm", effect = "neutral", info = "Một trang trại với động vật xuất hiện trên đảo." },
{ word = "Space", cat = "Địa điểm", effect = "neutral", info = "Hòn đảo bay vào không gian, trọng lực thấp, nhìn thấy các hành tinh. Nhảy rất cao." },
{ word = "Town", cat = "Địa điểm", effect = "neutral", info = "Một thị trấn xuất hiện với cửa hàng để cướp và nhà cao để leo khi có lũ." },
{ word = "School", cat = "Địa điểm", effect = "neutral", info = "Một ngôi trường xuất hiện với bàn ghế, có thể dùng làm chỗ trú." },
{ word = "Roblox HQ", cat = "Địa điểm", effect = "neutral", info = "Toà nhà Roblox HQ kiểu cổ xuất hiện, leo lên được để lên chỗ cao." },
{ word = "Pyramid", cat = "Địa điểm", effect = "neutral", info = "Kim tự tháp xuất hiện và leo được, là điểm cao an toàn khi có lũ hoặc dung nham." },
{ word = "Church", cat = "Địa điểm", effect = "neutral", info = "Một nhà thờ xuất hiện với các dãy ghế, có thể dùng làm nơi trú." },
{ word = "Safe House", cat = "Địa điểm", effect = "help", info = "Một căn nhà an toàn tạm thời có lõi pha lê xuất hiện, vào trong để tránh nguy hiểm. Từ cùng nghĩa: Safehouse." },
{ word = "Museum", cat = "Địa điểm", effect = "neutral", info = "Bảo tàng xuất hiện kèm một con khủng long bên trong." },
{ word = "Hospital", cat = "Địa điểm", effect = "neutral", info = "Bệnh viện xuất hiện nhưng game trả lời là không hồi máu miễn phí. Đừng trông cậy vào nó." },
{ word = "House", cat = "Địa điểm", effect = "help", info = "Một ngôi nhà có mái xuất hiện, có thể vào trong trú khi mưa hoặc vật thể rơi." },
{ word = "Castle", cat = "Địa điểm", effect = "neutral", info = "Một toà lâu đài xuất hiện và leo được để thoát khỏi nguy hiểm mặt đất." },
{ word = "Tower", cat = "Địa điểm", effect = "neutral", info = "Một toà tháp cao xuất hiện, leo lên để tránh mọi thứ dưới sàn." },
{ word = "Treehouse", cat = "Địa điểm", effect = "neutral", info = "Nhà trên cây xuất hiện trên một bệ cao, leo lên để rời mặt đất." },
{ word = "Building", cat = "Địa điểm", effect = "neutral", info = "Một toà nhà trồi lên khỏi mặt đất cho mọi người leo. Leo trước khi lũ hay sóng thần tới." },
{ word = "Mountain", cat = "Địa điểm", effect = "neutral", info = "Một ngọn núi có thể leo xuất hiện trên bản đồ." },
{ word = "Cave", cat = "Địa điểm", effect = "neutral", info = "Một hang động toàn pha lê xuất hiện, có thể trú được vật thể rơi từ trời." },
{ word = "Oasis", cat = "Địa điểm", effect = "help", info = "Một ốc đảo hồi máu xuất hiện trên bản đồ. Chạy tới khi máu thấp." },
{ word = "Greenhouse", cat = "Địa điểm", effect = "neutral", info = "Nhà kính đầy trái cây xuất hiện, vào để lấy đồ ăn." },
{ word = "Supermarket", cat = "Địa điểm", effect = "neutral", info = "Siêu thị đầy thức ăn xuất hiện, vừa có đồ ăn vừa có chỗ trú." },
{ word = "Igloo", cat = "Địa điểm", effect = "neutral", info = "Nhà tuyết igloo xuất hiện, vào trong để trú." },
{ word = "Kitchen", cat = "Địa điểm", effect = "neutral", info = "Một bộ bếp nhỏ xuất hiện trên bản đồ. Chỉ để trang trí." },
{ word = "Wall", cat = "Địa điểm", effect = "neutral", info = "Một bức tường gạch trồi lên khỏi mặt đất, đứng sau để chặn đòn từ một phía." },
{ word = "Sandbags", cat = "Địa điểm", effect = "help", info = "Các bao cát xuất hiện, ngồi núp sau khi có người bắt đầu nổ súng." },
{ word = "Box", cat = "Địa điểm", effect = "neutral", info = "Các thùng gỗ xuất hiện rải khắp bản đồ để làm vật cản." },
{ word = "Lamp", cat = "Địa điểm", effect = "help", info = "Cột đèn xuất hiện và thắp sáng xung quanh. Đứng gần khi bản đồ tối. Từ cùng nghĩa: Idea." },

-- ══════════════ DI CHUYỂN & THOÁT HIỂM ══════════════
{ word = "Launchpad", cat = "Di chuyển", effect = "neutral", info = "Các bệ nhún xuất hiện, ai bước lên là bị bắn lên trời. Dùng để lên chỗ cao, chú ý điểm đáp." },
{ word = "Helicopter", cat = "Di chuyển", effect = "help", info = "Trực thăng xuất hiện, bay được để thoát lũ, dung nham và quái vật. Chen chân vào trước người khác." },
{ word = "Car", cat = "Di chuyển", effect = "neutral", info = "Xe hơi xuất hiện cho người chơi lái. Cẩn thận kẻo bị tông. Từ cùng nghĩa: Cars." },
{ word = "Plane", cat = "Di chuyển", effect = "help", info = "Máy bay xuất hiện, bay được và đưa bạn ra khỏi mọi thảm họa mặt đất." },
{ word = "Boat", cat = "Di chuyển", effect = "help", info = "Một chiếc thuyền nhỏ xuất hiện cho người chơi lái. Nhảy vào khi có thảm họa nước." },
{ word = "Bus", cat = "Di chuyển", effect = "neutral", info = "Xe buýt trường học xuất hiện, lái được để đi xuyên bản đồ nhanh." },
{ word = "Bike", cat = "Di chuyển", effect = "neutral", info = "Xe đạp xuất hiện cho người chơi đi. Di chuyển nhanh hơn đi bộ." },
{ word = "Go Kart", cat = "Di chuyển", effect = "neutral", info = "Xe go-kart xuất hiện cho người chơi lái. Dùng để bỏ xa mối nguy dưới đất. Từ cùng nghĩa: Gokart." },
{ word = "Raft", cat = "Di chuyển", effect = "help", info = "Mỗi người chơi nhận một chiếc bè. Dùng khi nước đã phủ kín đảo." },
{ word = "Parachute", cat = "Di chuyển", effect = "neutral", info = "Mọi người bị bắn lên trời rồi từ từ hạ xuống bằng dù. Lái điểm đáp tới chỗ an toàn." },
{ word = "Stairs", cat = "Di chuyển", effect = "neutral", info = "Một cầu thang xoắn cao trồi lên khỏi mặt đất. Leo để thoát khỏi sàn nhà." },
{ word = "Ladder", cat = "Di chuyển", effect = "neutral", info = "Những chiếc thang xuất hiện để leo. Dùng để thoát khỏi nguy hiểm dưới sàn." },
{ word = "Zipline", cat = "Di chuyển", effect = "neutral", info = "Một đường zipline xuất hiện cho người chơi trượt qua. Đi xuyên bản đồ rất nhanh." },
{ word = "Balloons", cat = "Di chuyển", effect = "neutral", info = "Bóng bay xuất hiện và mang người chơi lên cao. Hữu ích để tránh nguy hiểm mặt đất." },
{ word = "Geyser", cat = "Di chuyển", effect = "neutral", info = "Mạch nước phun trào và bắn người chơi lên rất cao. Canh điểm đáp khi rơi xuống." },
{ word = "Beanstalk", cat = "Di chuyển", effect = "neutral", info = "Một cây đậu khổng lồ mọc lên tới tận mây. Thử leo trước khi tin vào nó." },
{ word = "Door", cat = "Di chuyển", effect = "neutral", info = "Những cánh cửa ma thuật xuất hiện, ai bước vào là bị dịch chuyển. Dùng để chạy thoát nhanh." },
{ word = "Exit", cat = "Di chuyển", effect = "help", info = "Một cánh cửa dẫn tới điểm an toàn nhất trên bản đồ. Đi qua khi tình hình xấu." },
{ word = "Sussy", cat = "Di chuyển", effect = "neutral", info = "Các lỗ thông gió xuất hiện trên sàn, người chơi có thể chui qua để lẻn đi." },
{ word = "Fly", cat = "Di chuyển", effect = "help", info = "Mọi người nhận đôi cánh bay được trong 20 giây. Khác với Plane." },
{ word = "Gravity", cat = "Di chuyển", effect = "neutral", info = "Trọng lực giảm mạnh, ai cũng nhảy cao và lơ lửng. Từ cùng nghĩa: Anti-Gravity." },
{ word = "Super Speed", cat = "Di chuyển", effect = "help", info = "Mọi người chạy nhanh hơn hẳn. Dùng để lên chỗ cao hoặc vào bunker sớm. Từ cùng nghĩa: Speed, Flash." },
{ word = "Push", cat = "Di chuyển", effect = "neutral", info = "Một làn sóng xung kích giải phóng ra, đẩy tất cả mọi người ra xa." },
{ word = "Sneeze", cat = "Di chuyển", effect = "neutral", info = "Hắt hơi tạo lực thổi bay người chơi xung quanh." },
{ word = "Teleport", cat = "Di chuyển", effect = "neutral", info = "Gây lỗi dịch chuyển toàn server, mọi người bị giật cục khắp bản đồ." },
{ word = "Walk", cat = "Di chuyển", effect = "neutral", info = "Hạn chế mọi người chỉ được đi bộ, không chạy được nữa." },
{ word = "Idle", cat = "Di chuyển", effect = "help", info = "Huỷ trạng thái bị ép đi bộ, người chơi đứng yên lại được. Dùng để xoá Walk hoặc GO." },
{ word = "Sleep", cat = "Di chuyển", effect = "neutral", info = "Người chơi ngủ gật khi ngừng di chuyển. Đừng đứng yên quá lâu." },
{ word = "Upside Down", cat = "Di chuyển", effect = "neutral", info = "Lật ngược toàn bộ màn hình của mọi người chơi." },
{ word = "Troll", cat = "Di chuyển", effect = "neutral", info = "Đảo ngược điều khiển của mọi người, tiến thành lùi, trái thành phải." },
{ word = "Cry", cat = "Di chuyển", effect = "neutral", info = "Mọi người khóc không kiểm soát, nước mắt tạo thành vũng trên mặt đất." },
{ word = "Falling Blocks", cat = "Di chuyển", effect = "danger", info = "Những khối vuông khổng lồ rơi từ trời xuống. Nhìn lên và né bóng của chúng." },

-- ══════════════ HỒI MÁU & HỖ TRỢ ══════════════
{ word = "Jesus", cat = "Hồi máu", effect = "help", info = "Chữa lành toàn bộ người chơi, hồi sinh một người, tạo cá và bánh mì. Chỉ dùng được một lần mỗi server." },
{ word = "Medkit", cat = "Hồi máu", effect = "help", info = "Một bộ cứu thương được thả từ máy bay, tìm theo làn khói đỏ. Từ được gõ nhiều nhất trong game." },
{ word = "Revive", cat = "Hồi máu", effect = "help", info = "Hồi sinh một người chơi đã bị loại quay lại trận." },
{ word = "Gift", cat = "Hồi máu", effect = "help", info = "Những hộp quà bọc giấy rơi xuống, bên trong là thứ gì đó ngẫu nhiên." },
{ word = "Chill Guy", cat = "Hồi máu", effect = "help", info = "Cả bản đồ thư giãn, kể cả quái vật cũng bình tĩnh lại. Tranh thủ di chuyển tới chỗ an toàn." },
{ word = "Watermelon", cat = "Hồi máu", effect = "help", info = "Dưa hấu cho mọi người, ăn từng miếng để hồi máu. Giữ một miếng dự phòng." },
{ word = "Full Health", cat = "Hồi máu", effect = "help", info = "Hồi đầy máu và thêm một lớp khiên cho người viết. Từ cùng nghĩa: Full HP." },
{ word = "Love", cat = "Hồi máu", effect = "help", info = "Những trái tim xuất hiện và hồi máu cho ai nhặt được. Cố lấy trước người khác." },
{ word = "Sorry", cat = "Hồi máu", effect = "help", info = "Xin lỗi hồi máu cho toàn bộ người chơi trong server." },
{ word = "Reset", cat = "Hồi máu", effect = "help", info = "Đưa bạn về điểm spawn với máu đầy." },
{ word = "Peace", cat = "Hồi máu", effect = "help", info = "Không ai có thể bị thương trong khoảng 15 giây." },
{ word = "Forcefield", cat = "Hồi máu", effect = "help", info = "Bọc người viết trong bong bóng bảo vệ một lúc, ghép với một từ thảm họa để an toàn. Từ cùng nghĩa: Force Field." },
{ word = "Star", cat = "Hồi máu", effect = "help", info = "Một ngôi sao tăng sức mạnh, ai nhặt được thành bất tử. Cố lấy hoặc tránh người đang giữ." },
{ word = "Doctor", cat = "Hồi máu", effect = "help", info = "Một bác sĩ xuất hiện và hồi máu cho người chơi." },
{ word = "Regenerate", cat = "Hồi máu", effect = "help", info = "Mọc lại tay hoặc chân đã bị mất." },
{ word = "Fairy", cat = "Hồi máu", effect = "help", info = "Các nàng tiên xuất hiện và hồi máu cho người đang bị thương. Đứng gần khi máu thấp." },
{ word = "Bathtub", cat = "Hồi máu", effect = "help", info = "Những bồn tắm xuất hiện và hồi máu cho người chơi." },
{ word = "Money", cat = "Hồi máu", effect = "neutral", info = "Trời mưa tiền khắp đảo. Nhặt những gì bạn tới được an toàn." },
{ word = "Chest", cat = "Hồi máu", effect = "neutral", info = "Rương xuất hiện chứa tiền cho ai mở. Mở khi thấy an toàn." },
{ word = "Diamond", cat = "Hồi máu", effect = "neutral", info = "Một viên kim cương xuất hiện làm phần thưởng, ai chạm trước thì được tiền." },
{ word = "Pinata", cat = "Hồi máu", effect = "neutral", info = "Một con piñata đầy kẹo xuất hiện để mọi người đập vỡ." },
{ word = "Treasure", cat = "Hồi máu", effect = "neutral", info = "Kho báu bị chôn xuất hiện để người chơi đào lên." },
{ word = "King", cat = "Hồi máu", effect = "neutral", info = "Một vị vua xuất hiện và ném tiền cho người chơi. Nhặt tiền." },
{ word = "Santa", cat = "Hồi máu", effect = "help", info = "Ông già Noel bay quanh và thả quà xuống bản đồ. Đi nhặt quà." },
{ word = "Please", cat = "Hồi máu", effect = "help", info = "Người viết xin xỏ và nhận được một ít tiền." },
{ word = "Btools", cat = "Hồi máu", effect = "help", info = "Mọi người nhận bộ công cụ xây dựng cổ điển của Roblox, tha hồ thay đổi bản đồ quanh mình." },
{ word = "Firefighter", cat = "Hồi máu", effect = "help", info = "Lính cứu hỏa tới và dập tắt mọi đám cháy. Gõ khi cháy rừng lan rộng." },
{ word = "Fire Truck", cat = "Hồi máu", effect = "help", info = "Xe cứu hỏa xuất hiện và phun nước dập lửa. Từ cùng nghĩa: Firetruck." },
{ word = "Umbrella", cat = "Hồi máu", effect = "neutral", info = "Những chiếc ô rơi xuống bản đồ dưới dạng vật phẩm nhặt được." },
{ word = "AFK", cat = "Hồi máu", effect = "help", info = "Bạn vào trạng thái AFK và không ai chạm tới được." },

-- ══════════════ ĐỒ ĂN & VẬT PHẨM ══════════════
{ word = "Taco", cat = "Đồ ăn", effect = "help", info = "Trời mưa taco xuống khắp bản đồ. Không nguy hiểm, cứ nhặt. Từ cùng nghĩa: Tacos." },
{ word = "Cheese", cat = "Đồ ăn", effect = "help", info = "Những miếng phô mai rơi xuống bản đồ cho ai nhặt." },
{ word = "Burger", cat = "Đồ ăn", effect = "help", info = "Bánh burger rơi xuống bản đồ cho người chơi nhặt ăn." },
{ word = "Food", cat = "Đồ ăn", effect = "help", info = "Thức ăn rải khắp bản đồ, nhưng không chắc hồi máu ngay lập tức." },
{ word = "Bacon", cat = "Đồ ăn", effect = "help", info = "Mọi người nhận thịt xông khói, đồ ăn miễn phí, không cần né gì." },
{ word = "Potato", cat = "Đồ ăn", effect = "help", info = "Khoai tây rơi xuống cho mọi người nhặt." },
{ word = "Barbecue", cat = "Đồ ăn", effect = "help", info = "Một bếp nướng xuất hiện với xiên thịt cho người chơi lấy." },
{ word = "Ice Cream Truck", cat = "Đồ ăn", effect = "neutral", info = "Xe bán kem xuất hiện trên bản đồ. Chỉ để trang trí." },
{ word = "Fireworks", cat = "Vật phẩm", effect = "neutral", info = "Pháo hoa bắn tung toé khắp bản đồ, thuần hiệu ứng hình ảnh." },
{ word = "Lucky Block", cat = "Vật phẩm", effect = "neutral", info = "Một khối may mắn xuất hiện, có thể đập vỡ để nhận bất ngờ." },
{ word = "Scarecrow", cat = "Vật phẩm", effect = "danger", info = "Những người rơm xuất hiện và nhìn chằm chằm vào người chơi, khá rùng rợn." },
{ word = "Lego", cat = "Vật phẩm", effect = "danger", info = "Gạch Lego rải khắp sàn, giẫm lên là mất máu." },
{ word = "Oil", cat = "Vật phẩm", effect = "neutral", info = "Các vết dầu loang ra khắp mặt đất, trơn trượt và dễ ngã." },
{ word = "Person", cat = "Vật phẩm", effect = "neutral", info = "Một nhân vật xuất hiện và liên tục lặp đi lặp lại một cái tên ngẫu nhiên." },
{ word = "Aura", cat = "Vật phẩm", effect = "help", info = "Người chơi bắt đầu phát sáng với hào quang bao quanh." },
{ word = "67", cat = "Vật phẩm", effect = "neutral", info = "Triệu hồi cậu bé 67 meme trên bản đồ." },
{ word = "Mrbeast", cat = "Vật phẩm", effect = "danger", info = "Thử thách MrBeast: người cuối cùng còn trong vòng tròn sẽ thắng." },
{ word = "Dance", cat = "Vật phẩm", effect = "neutral", info = "Khi người chơi đứng yên, họ bắt đầu nhảy múa." },
{ word = "Confetti", cat = "Vật phẩm", effect = "neutral", info = "Pháo giấy màu sắc nổ tung khắp bản đồ. Không gây sát thương." },
{ word = "Clones", cat = "Vật phẩm", effect = "neutral", info = "Bản sao của người chơi xuất hiện khiến khó phân biệt ai là thật. Từ cùng nghĩa: Dark Clone." },
{ word = "Ronaldo", cat = "Vật phẩm", effect = "neutral", info = "Cầu thủ Ronaldo xuất hiện và một trận bóng bắt đầu giữa lúc hỗn loạn. Không nguy hiểm." },
{ word = "Fart", cat = "Vật phẩm", effect = "neutral", info = "Một đám mây mùi khó chịu bốc lên trên bản đồ. Chủ yếu là trò đùa. Từ cùng nghĩa: Butt." },

-- ══════════════ SỨC MẠNH ══════════════
{ word = "Hero", cat = "Sức mạnh", effect = "help", info = "Người viết thành siêu anh hùng, bay được, đấm người và tiếp đất kiểu hero landing." },
{ word = "Superman", cat = "Sức mạnh", effect = "help", info = "Superman xuất hiện, bay khắp nơi, tóm và ném người chơi. Nếu bạn là người viết thì đây là lợi thế lớn." },
{ word = "Goku", cat = "Sức mạnh", effect = "help", info = "Bạn hoá thành Saiyan trong 30 giây, bay được và bắn đòn tầm xa vào người chơi." },
{ word = "Luffy", cat = "Sức mạnh", effect = "help", info = "Người viết nhận tay cao su, kéo giãn, tóm và ném người chơi. Giữ khoảng cách và nấp." },
{ word = "Gojo", cat = "Sức mạnh", effect = "help", info = "Bọc người viết trong Infinity khoảng 30 giây, mọi người tới gần đều bị chậm lại. Không ai chạm được." },
{ word = "Spiderman", cat = "Sức mạnh", effect = "help", info = "Cho phép đu tơ nhện để di chuyển và nhốt người chơi khác vào tơ." },
{ word = "Homelander", cat = "Sức mạnh", effect = "help", info = "Người viết lơ lửng trên không và thiêu người chơi bằng tia mắt. Luôn có tường hoặc mái chắn." },
{ word = "Iron Man", cat = "Sức mạnh", effect = "help", info = "Người viết mặc giáp Iron Man, bắn tia từ tay và tia năng lượng từ ngực." },
{ word = "Sonic", cat = "Sức mạnh", effect = "help", info = "Người viết nhận tốc độ xanh của Sonic và đòn spin dash lao tới. Nhảy ra khỏi đường lao." },
{ word = "Tanjiro", cat = "Sức mạnh", effect = "danger", info = "Cho một cú lao hơi nước xoay tròn về phía trước. Tránh khỏi đường lao." },
{ word = "Rasengan", cat = "Sức mạnh", effect = "danger", info = "Tạo quả cầu năng lượng xoáy và lao tới. Tránh khỏi đường lao." },
{ word = "Bankai", cat = "Sức mạnh", effect = "danger", info = "Một thanh đại kiếm xuất hiện và phóng ra các đợt chém. Nấp sau vật cản. Từ cùng nghĩa: Banki." },
{ word = "Enuma Elish", cat = "Sức mạnh", effect = "danger", info = "Bạn hoá thành Gilgamesh và dùng thanh Ea phá huỷ mọi thứ. Tránh xa người viết." },
{ word = "Sukuna", cat = "Sức mạnh", effect = "danger", info = "Sukuna xuất hiện và tấn công bằng chém, Cleave và mũi tên lửa. Khác với Domain." },
{ word = "Domain", cat = "Sức mạnh", effect = "danger", info = "Một vòm tối hình thành, chém đứt mọi người bên trong trong 15 giây. Ra khỏi vòm ngay. Từ cùng nghĩa: Domain Expansion." },
{ word = "Wizard", cat = "Sức mạnh", effect = "neutral", info = "Người viết hoá phù thuỷ, niệm phép thu nhỏ người chơi khác trong khoảng 30 giây." },
{ word = "Angry", cat = "Sức mạnh", effect = "danger", info = "Chế độ nổi giận cho phép nhấc và ném người chơi khác. Tránh xa, nhất là ở mép đảo." },
{ word = "Bonk", cat = "Sức mạnh", effect = "danger", info = "Cheems xuất hiện cùng cây gậy và bonk người chơi. Giữ khoảng cách ngoài tầm gậy." },
{ word = "Saitama", cat = "Sức mạnh", effect = "help", info = "Một cú đấm quét sạch mọi quái vật trên bản đồ. Không cần né gì." },
{ word = "Naruto", cat = "Sức mạnh", effect = "danger", info = "Một đám phân thân bóng tối lao qua bản đồ. Di chuyển và đừng để bị bao vây." },
{ word = "UltraInstinct", cat = "Sức mạnh", effect = "help", info = "Bản nâng cấp của Goku, cơ thể tự né đòn và phản công. Hiếm gặp nhưng cực mạnh." },
{ word = "Crab", cat = "Động vật", effect = "neutral", info = "Một nhóm cua xuất hiện bò quanh đảo. Không nguy hiểm." },
{ word = "Aliens", cat = "Quái vật", effect = "danger", info = "Người ngoài hành tinh bắt cóc người chơi bằng ánh sáng xanh." },
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

-- ============================================
-- NGÔN NGỮ (VN / EN / TH)
-- ============================================
local LANGS = { "vi", "en", "th" }
local LANG_LABEL = { vi = "VN", en = "EN", th = "TH" }
local Lang = "vi"

local UI = {
    search     = { vi = "🔍 Tìm kiếm...",              en = "🔍 Search...",             th = "🔍 ค้นหา..." },
    all        = { vi = "Tất cả",                      en = "All",                      th = "ทั้งหมด" },
    countFmt   = { vi = "%d lệnh",                     en = "%d words",                 th = "%d คำ" },
    noPick     = { vi = "Chưa chọn lệnh",              en = "No command selected",      th = "ยังไม่ได้เลือกคำสั่ง" },
    send       = { vi = "Gửi",                         en = "Send",                     th = "ส่ง" },
    saveBtn    = { vi = "★ Lưu",                       en = "★ Save",                   th = "★ บันทึก" },
    keyNone    = { vi = "Phím tắt gửi: [Chưa đặt]",    en = "Send key: [Not set]",      th = "ปุ่มส่ง: [ยังไม่ตั้ง]" },
    keyWait    = { vi = "Phím tắt gửi: [Bấm phím...]", en = "Send key: [Press...]",     th = "ปุ่มส่ง: [กดปุ่ม...]" },
    keyPrefix  = { vi = "Phím tắt gửi: [",             en = "Send key: [",              th = "ปุ่มส่ง: [" },
    savedEmpty = { vi = "Chưa có lệnh nào được lưu.",  en = "No saved commands yet.",   th = "ยังไม่มีคำสั่งที่บันทึก" },
    savedHint  = { vi = "Bấm ☆ ở lệnh để lưu · bấm × để xoá khỏi danh sách",
                   en = "Tap ☆ on a command to save · tap × to remove",
                   th = "กด ☆ เพื่อบันทึก · กด × เพื่อลบ" },
    tapAuto    = { vi = "Chạm = AUTO",                 en = "Tap = AUTO",               th = "แตะ = AUTO" },
    tapSend    = { vi = "Chạm = GỬI 1 LẦN",            en = "Tap = SEND ONCE",          th = "แตะ = ส่งครั้งเดียว" },
    customPh   = { vi = "Nhập lệnh tùy chỉnh...",      en = "Type a custom command...", th = "พิมพ์คำสั่งเอง..." },
    noImage    = { vi = "Không có ảnh",                en = "No image",                 th = "ไม่มีรูป" },
    customInfo = { vi = "Lệnh tùy chỉnh do bạn lưu.",  en = "Custom command you saved.",th = "คำสั่งที่คุณบันทึกเอง" },
}

local function T(key)
    local e = UI[key]
    if not e then return key end
    return e[Lang] or e.vi
end

-- ═══════════ NHÓM LỆNH (thay cho effect) ═══════════
local CATS = {
    { id = "weapon",   color = Color3.fromRGB(200, 40, 40),   vi = "Vũ khí",      en = "Weapons",   th = "อาวุธ" },
    { id = "monster",  color = Color3.fromRGB(165, 50, 150),  vi = "Quái vật",    en = "Monsters",  th = "สัตว์ประหลาด" },
    { id = "animal",   color = Color3.fromRGB(190, 120, 50),  vi = "Động vật",    en = "Animals",   th = "สัตว์" },
    { id = "disaster", color = Color3.fromRGB(225, 70, 45),   vi = "Thảm họa",    en = "Disasters", th = "ภัยพิบัติ" },
    { id = "weather",  color = Color3.fromRGB(80, 140, 205),  vi = "Thời tiết",   en = "Weather",   th = "สภาพอากาศ" },
    { id = "nature",   color = Color3.fromRGB(60, 160, 90),   vi = "Thiên nhiên", en = "Nature",    th = "ธรรมชาติ" },
    { id = "place",    color = Color3.fromRGB(110, 150, 190), vi = "Địa điểm",    en = "Places",    th = "สถานที่" },
    { id = "move",     color = Color3.fromRGB(70, 190, 170),  vi = "Di chuyển",   en = "Movement",  th = "การเคลื่อนที่" },
    { id = "heal",     color = Color3.fromRGB(50, 190, 110),  vi = "Hồi máu",     en = "Healing",   th = "การฟื้นฟู" },
    { id = "food",     color = Color3.fromRGB(200, 170, 60),  vi = "Đồ ăn",       en = "Food",      th = "อาหาร" },
    { id = "item",     color = Color3.fromRGB(150, 150, 170), vi = "Vật phẩm",    en = "Items",     th = "ไอเทม" },
    { id = "power",    color = Color3.fromRGB(220, 110, 50),  vi = "Sức mạnh",    en = "Powers",    th = "พลัง" },
}

local CAT_BY_VI, CAT_BY_ID = {}, {}
for _, c in ipairs(CATS) do CAT_BY_VI[c.vi] = c; CAT_BY_ID[c.id] = c end
local EFFECT_FALLBACK = { danger = "disaster", help = "heal", neutral = "item" }

local function cmdCat(cmd)
    local c = cmd.cat and CAT_BY_VI[cmd.cat]
    if c then return c.id end
    return EFFECT_FALLBACK[cmd.effect or ""] or "item"
end

local function catOf(cmd)
    return CAT_BY_ID[cmdCat(cmd)] or CAT_BY_ID.item
end

-- ═══════════ BẢN DỊCH: "Tên VN|ชื่อไทย|English desc|คำอธิบายไทย" ═══════════
local LOC_RAW = {
-- Vũ khí
["Minigun"] = "Súng máy|ปืนกล|A minigun drops from a supply crate and sprays nearby players.|ปืนกลตกจากกล่องเสบียงแล้วยิงผู้เล่นใกล้ๆ",
["Airstrike"] = "Không kích|เครื่องบินทิ้งระเบิด|A jet crosses the island dropping bombs in a line.|เครื่องบินบินผ่านเกาะและทิ้งระเบิดเป็นแนว",
["Tank"] = "Xe tăng|รถถัง|An army tank rolls in and shells players in its sight.|รถถังทหารแล่นเข้ามาและยิงผู้เล่นในสายตา",
["Laser"] = "Tia laser|เลเซอร์|Laser beams sweep across the floor. Jump or get high.|ลำแสงเลเซอร์กวาดบนพื้น กระโดดหลบหรือขึ้นที่สูง",
["Gun"] = "Súng|ปืน|A random gun drops, marked by red smoke. First come, first served.|ปืนสุ่มตกมา มีควันแดง ใครถึงก่อนได้",
["Bomb"] = "Bom|ระเบิด|A bomb chases a player before blowing up. Keep moving.|ลูกระเบิดตามผู้เล่นก่อนระเบิด วิ่งตลอดเวลา",
["Knife"] = "Dao|มีด|A knife spawns somewhere random for anyone to grab.|มีดเกิดในจุดสุ่ม ใครก็เก็บได้",
["Baseball Bat"] = "Gậy bóng chày|ไม้เบสบอล|Baseball bats spawn and players can bonk each other.|ไม้เบสบอลเกิด ผู้เล่นตีกันได้",
-- Quái vật
["Robot"] = "Robot|หุ่นยนต์|Starts red light, green light. Move on red and you get shot.|เริ่มเกมไฟแดงไฟเขียว ขยับตอนไฟแดงโดนยิง",
["Mahoraga"] = "||Mahoraga rises from the ground and hunts every player.|มาโฮรากะผุดจากพื้นและล่าผู้เล่นทุกคน",
["Wizard"] = "Phù thủy|พ่อมด|Turns the writer into a wizard who shrinks players for 30s.|ผู้เขียนเป็นพ่อมดย่อผู้เล่นคนอื่น 30 วินาที",
["Mummy"] = "Xác ướp|มัมมี่|Waves of mummies wrap up any player they catch.|มัมมี่ออกมาเป็นระลอกและพันตัวผู้เล่นที่จับได้",
["Godzilla"] = "||The game picks the closest match: a T-Rex dinosaur.|เกมเลือกสิ่งที่ใกล้ที่สุดคือไดโนเสาร์ T-Rex",
["Angel"] = "Thiên thần|เทวทูต|A giant angel appears and strikes living players.|เทวทูตยักษ์ปรากฏและโจมตีผู้เล่นที่ยังมีชีวิต",
["Giant"] = "Người khổng lồ|ยักษ์|A giant noob wanders the island and steps on players.|นูปยักษ์เดินรอบเกาะและเหยียบผู้เล่น",
["Zombie"] = "||A horde of zombies hunts players for the whole round.|ฝูงซอมบี้ล่าผู้เล่นตลอดรอบ",
["Slenderman"] = "||Slenderman appears. Never look at his face.|สเลนเดอร์แมนปรากฏ อย่ามองหน้าเขา",
["Skeleton"] = "Bộ xương|โครงกระดูก|Skeletons throw bones at players.|โครงกระดูกขว้างกระดูกใส่ผู้เล่น",
["Pirate"] = "Cướp biển|โจรสลัด|A pirate ship pulls up and fires cannons at the island.|เรือโจรสลัดเข้ามายิงปืนใหญ่ใส่เกาะ",
["Invisible"] = "Vô hình|ล่องหน|An invisible presence haunts players. Never stand still.|สิ่งล่องหนหลอกหลอน อย่ายืนนิ่ง",
["Alien"] = "Người ngoài hành tinh|เอเลี่ยน|Aliens abduct players with a light beam.|เอเลี่ยนจับผู้เล่นด้วยลำแสง",
["Aliens"] = "||Aliens abduct players with a beam of light.|เอเลี่ยนจับผู้เล่นด้วยลำแสง",
["Slime"] = "||Bouncing slimes crush anyone underneath.|สไลม์กระโดดทับคนข้างใต้",
["Vampire"] = "Ma cà rồng|แวมไพร์|A vampire rises from a coffin and attacks.|แวมไพร์ออกจากโลงและโจมตี",
["Monster"] = "Quái vật|สัตว์ประหลาด|A horned beast hunts by sound. Walk instead of running.|สัตว์มีเขาล่าตามเสียง เดินแทนวิ่ง",
["Dragon"] = "Rồng|มังกร|A dragon hovers above before breathing fire. Dodge its head.|มังกรลอยเหนือเกาะก่อนพ่นไฟ หลบหัวมัน",
-- Động vật
["KingKong"] = "||A giant gorilla looks for players to throw. Mostly harmless.|กอริลลายักษ์หาคนมาโยน ส่วนใหญ่ไม่อันตราย",
["Crab"] = "Cua|ปู|A group of crabs scuttles around the island. Harmless.|ปูฝูงหนึ่งเดินรอบเกาะ ไม่อันตราย",
["Bees"] = "Bầy ong|ผึ้ง|An angry bee swarm stings anyone walking through it.|ฝูงผึ้งโกรธต่อยคนที่เดินผ่าน",
["Dinosaur"] = "Khủng long|ไดโนเสาร์|A giant T-Rex hunts players on the ground.|T-Rex ยักษ์ล่าผู้เล่นบนพื้น",
["Elephant"] = "Voi|ช้าง|An elephant sprays water around. Harmless.|ช้างพ่นน้ำไปรอบๆ ไม่อันตราย",
["Octopus"] = "Bạch tuộc|ปลาหมึก|A giant octopus grabs players with its tentacles.|ปลาหมึกยักษ์ใช้หนวดจับผู้เล่น",
["Monkey"] = "Khỉ|ลิง|Monkeys throw banana peels that make you slip.|ลิงขว้างเปลือกกล้วยทำให้ลื่น",
["Spider"] = "Nhện|แมงมุม|A giant spider spawns with smaller spiders around it.|แมงมุมยักษ์เกิดพร้อมตัวเล็ก",
-- Thiên nhiên / thời tiết
["Swamp"] = "Đầm lầy|หนองน้ำ|Muddy puddles appear and slow anyone walking through.|แอ่งโคลนเกิดและทำให้เดินช้า",
["Desert"] = "Sa mạc|ทะเลทราย|The island turns into a desert with climbable mesas.|เกาะกลายเป็นทะเลทราย มีเขาสูงให้ปีน",
["Mud"] = "Bùn|โคลน|Mud puddles slow movement down.|แอ่งโคลนทำให้เคลื่อนที่ช้า",
["Rain"] = "Mưa|ฝน|Rain keeps falling and makes the ground slippery.|ฝนตกต่อเนื่องพื้นลื่น",
["Ice"] = "Băng|น้ำแข็ง|Every surface freezes over and becomes slippery.|ทุกพื้นกลายเป็นน้ำแข็งและลื่น",
["Snow"] = "Tuyết|หิมะ|A snowstorm hits. Hide under a roof or near fire.|พายุหิมะถล่ม หลบใต้หลังคาหรือใกล้ไฟ",
["Night"] = "Ban đêm|กลางคืน|The island turns to night and visibility drops.|เกาะกลายเป็นกลางคืน มองเห็นน้อยลง",
["Day"] = "Ban ngày|กลางวัน|The sun returns and clears the bad weather.|พระอาทิตย์กลับมาและล้างอากาศแย่",
["Storm"] = "Bão|พายุ|Rain, gusts, thunder and deadly lightning together.|ฝน ลม ฟ้าผ่า อันตรายพร้อมกัน",
["Fog"] = "Sương mù|หมอก|Thick fog cuts visibility across the map.|หมอกหนาลดการมองเห็น",
-- Thảm họa
["Acid"] = "Mưa axit|ฝนกรด|Toxic acid rain falls. Get under a roof.|ฝนกรดพิษตก หาที่กำบัง",
["Supernova"] = "Siêu tân tinh|ซูเปอร์โนวา|The sun explodes. Hide inside or behind solid cover.|ดวงอาทิตย์ระเบิด ซ่อนในที่กำบังแข็ง",
["Flash Flood"] = "Lũ quét|น้ำป่า|A wall of muddy water sweeps players away.|กำแพงน้ำโคลนพัดผู้เล่นไป",
["Lava"] = "Dung nham|ลาวา|The floor melts into lava then cools, over and over.|พื้นละลายเป็นลาวาแล้วเย็นลงสลับกัน",
["Tornado"] = "Lốc xoáy|ทอร์นาโด|A tornado roams the island hunting players.|ทอร์นาโดเดินรอบเกาะล่าผู้เล่น",
["Black Hole"] = "Hố đen|หลุมดำ|A black hole pulls players in. The center kills you.|หลุมดำดูดผู้เล่น ใจกลางคือตาย",
["Tsunami"] = "Sóng thần|สึนามิ|The island floods. Climb high or lose health.|น้ำท่วมเกาะ ขึ้นที่สูงไม่งั้นเสียเลือด",
["Flood"] = "Lũ|น้ำท่วม|Water covers the ground and players can drown.|น้ำท่วมพื้น ผู้เล่นจมน้ำได้",
["Satellite"] = "Vệ tinh|ดาวเทียม|A satellite crashes down onto the map.|ดาวเทียมตกกระแทกแมพ",
["Volcano"] = "Núi lửa|ภูเขาไฟ|A volcano spews lava rocks around the island.|ภูเขาไฟพ่นหินลาวา",
["Nuke"] = "Vũ khí hạt nhân|นิวเคลียร์|A nuclear bomb hits. Get in a bunker or die.|ระเบิดนิวเคลียร์ลงเกาะ เข้าหลุมหลบหรือตาย",
["Meteor"] = "Thiên thạch|อุกกาบาต|Meteors rain down and crack bunkers. Keep moving.|อุกกาบาตตกและทะลุหลุมหลบภัย เคลื่อนที่ตลอด",
-- Địa điểm
["Hell"] = "Địa ngục|นรก|Hell opens with giant blazing craters around players.|นรกเปิดพร้อมปล่องไฟลุกโชนรอบผู้เล่น",
["Heaven"] = "Thiên đường|สวรรค์|A cloud staircase leads up to a halo and safety.|บันไดเมฆขึ้นไปสู่รัศมีและความปลอดภัย",
["Maze"] = "Mê cung|เขาวงกต|A hedge maze grows on the map, good for hiding.|เขาวงกตพุ่มไม้เกิด ใช้ซ่อนได้",
["Farm"] = "Trang trại|ฟาร์ม|A farm with animals appears on the island.|ฟาร์มพร้อมสัตว์เกิดบนเกาะ",
["Space"] = "Không gian|อวกาศ|The island floats into space with low gravity.|เกาะลอยสู่อวกาศ แรงโน้มถ่วงต่ำ",
["Town"] = "Thị trấn|เมือง|Shops to loot and tall buildings to climb appear.|ร้านให้ปล้นและตึกสูงให้ปีน",
["School"] = "Trường học|โรงเรียน|A school with desks appears and works as shelter.|โรงเรียนพร้อมโต๊ะเกิด ใช้หลบภัยได้",
["Roblox HQ"] = "Trụ sở Roblox|สำนักงาน Roblox|The classic Roblox HQ buildings appear.|ตึก Roblox HQ แบบคลาสสิกเกิด",
["Pyramid"] = "Kim tự tháp|พีระมิด|A climbable pyramid appears as safe high ground.|พีระมิดให้ปีนเป็นที่สูงปลอดภัย",
["Church"] = "Nhà thờ|โบสถ์|A church with pews appears for shelter.|โบสถ์พร้อมม้านั่งสำหรับหลบ",
["Safe House"] = "Nhà an toàn|บ้านปลอดภัย|A temporary safe house protects you for a short time.|บ้านปลอดภัยชั่วคราวป้องกันคุณระยะสั้น",
["Museum"] = "Bảo tàng|พิพิธภัณฑ์|A museum appears with a dinosaur inside.|พิพิธภัณฑ์เกิดพร้อมไดโนเสาร์ข้างใน",
-- Đồ ăn / vật phẩm
["Taco"] = "||Tacos rain from the sky. Harmless, just grab them.|ทาโก้ตกลงมาจากฟ้า ไม่มีอันตราย เก็บได้",
["Cheese"] = "Phô mai|ชีส|Cheese falls from the sky for players to grab.|ชีสตกลงมาให้เก็บ",
["Burger"] = "Bánh burger|เบอร์เกอร์|Burgers drop onto the map for anyone to take.|เบอร์เกอร์ตกลงมาใครก็เก็บได้",
["Launchpad"] = "Bệ phóng|แท่นดีดตัว|Launch pads throw players into the air.|แท่นดีดตัวส่งผู้เล่นขึ้นฟ้า",
["Medkit"] = "Bộ sơ cứu|ชุดปฐมพยาบาล|A plane drops a medkit marked by red smoke.|เครื่องบินทิ้งชุดปฐมพยาบาลมีควันแดง",
["Car"] = "Ô tô|รถยนต์|Cars spawn, players can drive and run people over.|รถยนต์เกิด ขับและชนคนได้",
["Lucky Block"] = "Khối may mắn|บล็อกนำโชค|A lucky block can be broken for a random surprise.|บล็อกนำโชคแตกได้ของสุ่ม",
["Scarecrow"] = "Bù nhìn|หุ่นไล่กา|Scarecrows appear and stare at players.|หุ่นไล่กาเกิดและจ้องผู้เล่น",
["Lego"] = "Gạch Lego|ตัวต่อเลโก้|Toy bricks cover the floor and hurt when stepped on.|ตัวต่อเลโก้เต็มพื้น เหยียบแล้วเจ็บ",
["Helicopter"] = "Trực thăng|เฮลิคอปเตอร์|A rescue helicopter picks up and heals players.|เฮลิคอปเตอร์กู้ภัยมารับและรักษา",
["Oil"] = "Dầu|น้ำมัน|Oil spills spread and make the floor slippery.|น้ำมันหกทำให้พื้นลื่น",
["Fireworks"] = "Pháo hoa|ดอกไม้ไฟ|Fireworks launch everywhere. Visual only.|ดอกไม้ไฟยิงทั่วแมพ แค่ภาพ",
["Stairs"] = "Cầu thang|บันได|Stairs spawn so players can climb off the ground.|บันไดเกิดให้ปีนขึ้นจากพื้น",
-- Meme / sức mạnh
["Jesus"] = "||Heals everyone, revives one player and spawns food. Once per server.|รักษาทุกคน ชุบชีวิตหนึ่งคนและสร้างอาหาร ครั้งเดียวต่อเซิร์ฟเวอร์",
["Superman"] = "||Lets you fly and grab players to throw.|ให้บินและจับผู้เล่นไปโยน",
["Hunger"] = "Đói|ความหิว|Everyone gets hungry while food rains down. Grab it fast.|ทุกคนหิวพร้อมอาหารตกลงมา รีบเก็บ",
["67"] = "||Spawns the meme boy 67 on the map.|เรียกเด็กชาย 67 ออกมาบนแมพ",
["Hero"] = "Anh hùng|ฮีโร่|Grants flight, punches and a hero landing.|ให้บิน ต่อย และลงจอดแบบฮีโร่",
["Dance"] = "Nhảy múa|เต้นรำ|Players who stand still start dancing.|ผู้เล่นที่ยืนนิ่งจะเริ่มเต้น",
["Mrbeast"] = "||MrBeast challenge: last player in the circle wins.|ภารกิจ MrBeast คนสุดท้ายในวงกลมชนะ",
["Santa"] = "Ông già Noel|ซานต้า|Santa flies around dropping gifts.|ซานต้าบินรอบและทิ้งของขวัญ",
["Naruto"] = "||Shadow clones charge across the map. Don't get surrounded.|ร่างแยกเงาวิ่งทั่ว อย่าให้ถูกล้อม",
["Kill"] = "Dao giết|ฆ่า|Gives the writer a knife instantly instead of dropping one.|ให้มีดกับผู้เขียนทันที ไม่ต้องไปเก็บ",
["Gojo"] = "||Grants Infinity for 30 seconds; nothing can touch you.|ให้ Infinity 30 วินาที ไม่มีอะไรแตะได้",
["Luffy"] = "||Rubber arms let the writer grab and throw players.|แขนยางให้ผู้เขียนจับและโยนผู้เล่น",
["Love"] = "Tình yêu|ความรัก|Healing hearts spawn. Grab them before others.|หัวใจฟื้นพลังเกิด รีบเก็บก่อนคนอื่น",
["Goku"] = "||Turns you into a Saiyan for 30s with ranged blasts.|กลายเป็นไซย่า 30 วินาที ยิงพลังระยะไกล",
["Upside Down"] = "Lật ngược|พลิกคว่ำ|Flips every player's screen upside down.|พลิกหน้าจอทุกคนกลับหัว",
["Domain"] = "Lãnh địa|โดเมน|A deadly barrier slashes everyone inside for 15s.|โดเมนอันตรายฟันทุกคนข้างใน 15 วินาที",
["Spiderman"] = "||Grants web swinging to travel and trap players.|ให้ใยแมงมุมเหวี่ยงตัวและมัดผู้เล่น",
["Sleep"] = "Ngủ|นอนหลับ|Players fall asleep when they stop moving.|ผู้เล่นหลับเมื่อหยุดขยับ",
["Push"] = "Đẩy|ผลัก|Releases a shockwave that pushes everyone away.|ปล่อยคลื่นกระแทกผลักทุกคนออก",
["Fly"] = "Bay|บิน|Gives everyone wings for 20 seconds.|ให้ทุกคนมีปีกบิน 20 วินาที",
["Fart"] = "Xì hơi|ตด|Summons a giant cloud of gas. Mostly a joke.|เรียกกลุ่มแก๊สยักษ์ ส่วนใหญ่เป็นมุก",
["Pikachu"] = "||Pikachu calls lightning down on crowded players.|ปิกาจูเรียกฟ้าผ่าใส่คนที่อยู่รวมกัน",
["Tung Tung Sahur"] = "||The meme chaser hunts players across the map.|ตัวละครมีมไล่ล่าผู้เล่นทั่วแมพ",
["Please"] = "Xin xỏ|ขอร้อง|Asks nicely and receives a little money.|ขอเงินและได้มาเล็กน้อย",
["Person"] = "Người|คน|Adds a person who keeps repeating a random name.|เพิ่มคนที่พูดชื่อสุ่มซ้ำๆ",
["Gravity"] = "Trọng lực|แรงโน้มถ่วง|Low gravity with huge jumps.|แรงโน้มถ่วงต่ำ กระโดดสูงมาก",
["Falling Blocks"] = "Khối rơi|บล็อกร่วง|Giant blocks fall from the sky. Dodge the shadows.|บล็อกยักษ์ตกลงมา หลบตามเงา",
["Sneeze"] = "Hắt hơi|จาม|A sneeze blows nearby players away.|การจามพัดผู้เล่นใกล้ๆ กระเด็น",
["Tralalero"] = "||A speed boost around the map for the whole round.|เพิ่มความเร็วทั่วแมพตลอดรอบ",
["Walk"] = "Đi bộ|เดิน|Forces everyone to walk, no sprinting.|บังคับให้ทุกคนเดิน วิ่งไม่ได้",
["Teleport"] = "Dịch chuyển|วาร์ป|Glitches everyone around the map.|ทำให้ทุกคนกระตุกวาร์ปทั่วแมพ",
["Skibidi"] = "||Dancing toilets chase players around.|โถสุขภัณฑ์เต้นไล่ผู้เล่น",
["Cry"] = "Khóc|ร้องไห้|Makes players cry puddles onto the floor.|ทำให้ผู้เล่นร้องไห้เป็นแอ่งน้ำ",
["Troll"] = "||Reverses everyone's controls.|สลับการควบคุมของทุกคน",
["Doge"] = "||A giant Doge chases players across the island.|โดจยักษ์ไล่ผู้เล่นทั่วเกาะ",
["Aura"] = "Hào quang|ออร่า|Adds +1000 aura and a glowing aura.|เพิ่มออร่า +1000 พร้อมแสงออร่า",
["Moon"] = "Mặt trăng|พระจันทร์|A giant moon appears in the sky.|พระจันทร์ยักษ์ปรากฏบนฟ้า",
}

local LOC = {}
for w, s in pairs(LOC_RAW) do
    local p = string.split(s, "|")
    LOC[w] = {
        vi  = (p[1] and p[1] ~= "") and p[1] or nil,
        th  = (p[2] and p[2] ~= "") and p[2] or nil,
        en  = p[3] or "",
        thd = p[4] or "",
    }
end

local function dispName(cmd)
    if Lang == "en" then return cmd.word end
    local e = LOC[cmd.word]
    if not e then return cmd.word end
    if Lang == "vi" then return e.vi or cmd.word end
    return e.th or cmd.word
end

local function dispDesc(cmd)
    local e = LOC[cmd.word]
    if Lang == "vi" then
        if e and e.vid and e.vid ~= "" then return e.vid end
        if cmd.info and cmd.info ~= "" then return cmd.info end
        return (e and e.en) or ""
    elseif Lang == "th" then
        if e and e.thd and e.thd ~= "" then return e.thd end
        if e and e.en and e.en ~= "" then return e.en end
        return cmd.info or ""
    end
    if e and e.en and e.en ~= "" then return e.en end
    return cmd.info or ""
end

local function matchCmd(cmd, q)
    if q == "" then return true end
    if cmd.word:lower():find(q, 1, true) then return true end
    if dispName(cmd):lower():find(q, 1, true) then return true end
    if cmd.cat and cmd.cat:lower():find(q, 1, true) then return true end
    if cmd.info and cmd.info:lower():find(q, 1, true) then return true end
    local e = LOC[cmd.word]
    if e then
        if e.vi and e.vi:lower():find(q, 1, true) then return true end
        if e.th and e.th:lower():find(q, 1, true) then return true end
        if e.en ~= "" and e.en:lower():find(q, 1, true) then return true end
        if e.thd ~= "" and e.thd:lower():find(q, 1, true) then return true end
    end
    local catObj = catOf(cmd)
    if catObj then
        if catObj.vi and catObj.vi:lower():find(q, 1, true) then return true end
        if catObj.en and catObj.en:lower():find(q, 1, true) then return true end
        if catObj.th and catObj.th:lower():find(q, 1, true) then return true end
    end
    return false
end

local CmdByWord = {}
for _, c in ipairs(CommandData) do CmdByWord[c.word] = c end

local function cmdFromWord(w)
    return CmdByWord[w] or { word = w, cat = "Vật phẩm", effect = "neutral", info = T("customInfo") }
end

local function saveToDisk()
    if type(writefile) ~= "function" then return end
    pcall(function()
        writefile(SAVE_FILE, HttpService:JSONEncode({
            saved = Saved,
            mode = TapMode,
            sendKey = CurrentSendKey.Name,
			lang = Lang,
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
		if d.lang == "vi" or d.lang == "en" or d.lang == "th" then Lang = d.lang end
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
        Name = "StatusDot",                                  -- ⚠️ BẮT BUỘC: đúng tên này
        Size = UDim2.new(0, 9, 0, 9),
        Position = UDim2.new(0, 142, 0.5, -4.5),
        BackgroundColor3 = IsMyTurn and TURN_ON or TURN_OFF, -- tạo ra là đúng màu luôn
        BorderSizePixel = 0,
        ZIndex = 5,
    }, bar)
    newCorner(statusDot, 6)

    statusDotRef = statusDot
    statusGuiRef = gui
    warnedNoDot = false
    renderDot()          -- ép vẽ ngay, không chờ vòng lặp nào

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
	
	searchBox.PlaceholderText = T("search")

    local langBtn = mk("TextButton", {
        Size = UDim2.new(0, 58, 0, 28),
        Position = UDim2.new(0, 248, 0, 8),
        BackgroundColor3 = DARK,
        BorderSizePixel = 0,
        Text = LANG_LABEL[Lang],
        TextColor3 = WHITE,
        Font = Enum.Font.GothamBlack,
        TextSize = 13,
    }, panel)
    newCorner(langBtn, 6)
    attachFx(langBtn, nil, 6)

    local countLabel = mk("TextLabel", {
        Size = UDim2.new(0, 274, 0, 28),
        Position = UDim2.new(0, 314, 0, 8),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = SILVER,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, panel)

    local applyLanguage
    langBtn.MouseButton1Click:Connect(function()
        local i = table.find(LANGS, Lang) or 1
        Lang = LANGS[(i % #LANGS) + 1]
        applyLanguage()
        saveToDisk()
    end)

    local filterScroll = mk("ScrollingFrame", {
        Size = UDim2.new(1, -16, 0, 28),
        Position = UDim2.new(0, 8, 0, 42),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Active = true,
    }, panel)
    local filterLayout = mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
    }, filterScroll)

    local filterBtns = {}
    local updateList

    local function refreshFilter()
        for id, f in pairs(filterBtns) do
            local on = (currentFilter == id)
            tween(f.btn, TWEEN_FAST, {
                BackgroundColor3 = on and f.color or DARK,
                TextColor3 = on and WHITE or TXT,
            })
        end
    end

    local function makeFilterBtn(id, color, order)
        local b = mk("TextButton", {
            Size = UDim2.new(0, 0, 0, 26),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = DARK,
            BorderSizePixel = 0,
            Text = "",
            TextColor3 = TXT,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            LayoutOrder = order,
            AutoButtonColor = false,
        }, filterScroll)
        newCorner(b, 6)
        mk("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9) }, b)
        attachFx(b, nil, 6)
        filterBtns[id] = { btn = b, color = color }
        b.MouseButton1Click:Connect(function()
            currentFilter = id
            refreshFilter()
            updateList()
        end)
        return b
    end

    makeFilterBtn("all", Color3.fromRGB(150, 150, 160), 0)
    for i, c in ipairs(CATS) do
        makeFilterBtn(c.id, c.color, i)
    end

    local function relabelFilters()
        filterBtns.all.btn.Text = T("all")
        for _, c in ipairs(CATS) do
            local f = filterBtns[c.id]
            if f then f.btn.Text = c[Lang] or c.en end
        end
        task.defer(function()
            filterScroll.CanvasSize = UDim2.new(0, filterLayout.AbsoluteContentSize.X + 8, 0, 0)
        end)
    end

    relabelFilters()
    refreshFilter()

    local list = mk("ScrollingFrame", {
        Size = UDim2.new(1, -16, 0, 56),
        Position = UDim2.new(0, 8, 0, 76),
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
        Position = UDim2.new(0, 8, 0, 140),
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
        Position = UDim2.new(0, 240, 0, 140),
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
        Position = UDim2.new(0, 296, 0, 140),
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
        Position = UDim2.new(0, 360, 0, 140),
        BackgroundColor3 = DARK,
        BorderSizePixel = 0,
        Text = (CurrentSendKey == Enum.KeyCode.Unknown) and "Phím tắt gửi: [Chưa đặt]" or ("Phím tắt gửi: [" .. CurrentSendKey.Name .. "]"),
        TextColor3 = SILVER,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
    }, panel)
    newCorner(keybindBtn, 6)
    attachFx(keybindBtn, nil, 6)
	
    local function updateKeybindText()
        if isListeningForKey then
            keybindBtn.Text = T("keyWait")
            keybindBtn.TextColor3 = GOLD
        elseif CurrentSendKey == Enum.KeyCode.Unknown then
            keybindBtn.Text = T("keyNone")
            keybindBtn.TextColor3 = SILVER
        else
            keybindBtn.Text = T("keyPrefix") .. CurrentSendKey.Name .. "]"
            keybindBtn.TextColor3 = SILVER
        end
    end

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

    local savedHintLabel = mk("TextLabel", {
        Size = UDim2.new(0, 320, 0, 28),
        Position = UDim2.new(0, 206, 0, 8),
        BackgroundTransparency = 1,
        Text = T("savedHint"),
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
            pTitle.Text = dispName(cmd)
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
                noImg.Text = T("noImage")
                noImg.TextColor3 = Color3.fromRGB(80, 80, 100)
                noImg.Font = Enum.Font.Gotham
                noImg.TextSize = 12
                noImg.ZIndex = 51
                noImg.Parent = pImageFrame
            end

            local pBadge = Instance.new("TextLabel")
            local cat = catOf(cmd)
            pBadge.Size = UDim2.new(0, 118, 0, 22)
			pBadge.Position = UDim2.new(0, 12, 0, 44)
            pBadge.BackgroundColor3 = cat.color
            pBadge.Text = (cat[Lang] or cat.en):upper()
            pBadge.TextColor3 = WHITE
            pBadge.Font = Enum.Font.GothamBlack
            pBadge.TextSize = 11
            pBadge.ZIndex = 51
            pBadge.Parent = popup

            local pbCorner = Instance.new("UICorner")
            pbCorner.CornerRadius = UDim.new(0, 4)
            pbCorner.Parent = pBadge

            local pDescFrame = Instance.new("ScrollingFrame")
            pDescFrame.Size = UDim2.new(1, -24, 0, 132)
            pDescFrame.Position = UDim2.new(0, 12, 0, 206)
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
            pDesc.Text = dispDesc(cmd)
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
            modeBtn.Text = T("tapAuto")
            tween(modeBtn, TWEEN_FAST, { BackgroundColor3 = Color3.fromRGB(60, 180, 100) })
        else
            modeBtn.Text = T("tapSend")
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
        labelBtn.Text = dispName(cmd)
        tween(effectDot, TWEEN_FAST, { BackgroundColor3 = catOf(cmd).color })
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
            animatePanel(panel, panelStroke, 180, 0.2, false)
        end
        if which ~= "saved" and currentPanel == "saved" then
            animatePanel(savedPanel, savedStroke, 108, 0.4, false)
        end
        if which == "main" and currentPanel ~= "main" then
            animatePanel(panel, panelStroke, 180, 0.2, true)
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
        local nm = dispName(cmd)
        local textW = TextService:GetTextSize(nm, 13, Enum.Font.Gotham, Vector2.new(1000, 40)).X
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
            Text = "  " .. nm,
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
            local nm = dispName(cmd)
            local textW = TextService:GetTextSize(nm, 13, Enum.Font.Gotham, Vector2.new(1000, 40)).X
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
                BackgroundColor3 = catOf(cmd).color,
                BorderSizePixel = 0,
            }, sFrame)
            newCorner(accent, 2)

            local sBtn = mk("TextButton", {
                Size = UDim2.new(1, -30, 1, 0),
                BackgroundTransparency = 1,
                Text = "   " .. nm,
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
        local q = currentSearch:lower()
        visibleList = {}
        local count = 0
        for _, cmd in ipairs(CommandData) do
            local frame = chips[cmd.word].frame
            local ok = (currentFilter == "all" or cmdCat(cmd) == currentFilter) and matchCmd(cmd, q)
            frame.Visible = ok
            if ok then
                count = count + 1
                frame.LayoutOrder = count
                table.insert(visibleList, cmd)
            end
        end
        countLabel.Text = T("countFmt"):format(count)
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
        updateKeybindText()
        keybindBtn.TextColor3 = GOLD
    end)

    track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if isListeningForKey then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                CurrentSendKey = input.KeyCode
                updateKeybindText()
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
	
    applyLanguage = function()
        searchBox.PlaceholderText = T("search")
        inputBox.PlaceholderText = T("customPh")
        labelBtn.Text = SelectedCommand and dispName(SelectedCommand) or T("noPick")
        sendBtn.Text = T("send")
        saveCustomBtn.Text = T("saveBtn")
        emptyLabel.Text = T("savedEmpty")
        savedHintLabel.Text = T("savedHint")
        langBtn.Text = LANG_LABEL[Lang]
        if Lang == "vi" then
            langBtn.TextColor3 = GOLD
        elseif Lang == "en" then
            langBtn.TextColor3 = Color3.fromRGB(120, 200, 255)
        else
            langBtn.TextColor3 = Color3.fromRGB(255, 165, 110)
        end

        updateKeybindText()
        refreshModeVisual()
        refreshAutoVisual()
        relabelFilters()
        refreshFilter()

        for _, cmd in ipairs(CommandData) do
            local c = chips[cmd.word]
            if c then
                local nm = dispName(cmd)
                c.btn.Text = "  " .. nm
                local w = TextService:GetTextSize(nm, 13, Enum.Font.Gotham, Vector2.new(1000, 40)).X
                c.frame.Size = UDim2.new(0, math.max(104, w + 72), 0, 40)
            end
        end

        rebuildSaved()
        refreshStars()
        refreshSelectionVisual()
        updateList()
    end

    applyLanguage()

    local finalPos = bar.Position
    bar.Position = UDim2.new(finalPos.X.Scale, finalPos.X.Offset, finalPos.Y.Scale, finalPos.Y.Offset - 80)
    tween(bar, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = finalPos })

    task.spawn(function()
        while gui.Parent do
            renderDot()      -- 0.3s/lần: nếu màu bị lệch ở đâu đó, tự kéo về đúng
            task.wait(0.3)
        end
    end)
    gui.Destroying:Connect(function()
        statusDotRef = nil
        statusGuiRef = nil
    end)
end

loadFromDisk()
createGUI()
