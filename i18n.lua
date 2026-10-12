-- ============================================================
-- 🌐 i18n — HỆ THỐNG ĐA NGÔN NGỮ (Full)
-- Việt / Anh / Thái
-- ============================================================

local i18n = {}
i18n.CurrentLang = "vi"

i18n.Translations = {

    -- ============================================================
    -- 📌 WINDOW / TITLE
    -- ============================================================
    ["window_title"]        = { vi = "MarvenRiz Hub",         en = "MarvenRiz Hub",       th = "MarvenRiz Hub" },
    ["window_subtitle_s1"]  = { vi = "Sea 1 — Rock Fruit",    en = "Sea 1 — Rock Fruit",  th = "Sea 1 — Rock Fruit" },
    ["window_subtitle_moon"]= { vi = "Chỉ Raid Moon",         en = "Moon Raid Only",      th = "โจมตีดวงจันทร์เท่านั้น" },

    -- ============================================================
    -- 📌 LANGUAGE SELECTOR
    -- ============================================================
    ["choose_language"]     = { vi = "Chọn ngôn ngữ",         en = "Choose Language",     th = "เลือกภาษา" },
    ["choose_language_desc"]= { vi = "Vui lòng chọn ngôn ngữ hiển thị cho menu",
                                en = "Please select your display language for the menu",
                                th = "กรุณาเลือกภาษาที่แสดงสำหรับเมนู" },
    ["lang_vi"]             = { vi = "🇻🇳 Tiếng Việt",         en = "🇻🇳 Vietnamese",       th = "🇻🇳 ภาษาเวียดนาม" },
    ["lang_en"]             = { vi = "🇬🇧 Tiếng Anh",          en = "🇬🇧 English",          th = "🇬🇧 ภาษาอังกฤษ" },
    ["lang_th"]             = { vi = "🇹🇭 Tiếng Thái",         en = "🇹🇭 Thai",             th = "🇹🇭 ภาษาไทย" },
    ["confirm"]             = { vi = "Xác nhận",              en = "Confirm",             th = "ยืนยัน" },
    ["cancel"]              = { vi = "Hủy",                   en = "Cancel",              th = "ยกเลิก" },

    -- ============================================================
    -- 📌 TABS
    -- ============================================================
    ["tab_settings"]        = { vi = "Cài đặt",               en = "Settings",            th = "การตั้งค่า" },
    ["tab_main"]            = { vi = "Chính",                 en = "Main",                th = "หลัก" },
    ["tab_other"]           = { vi = "Khác",                  en = "Other",               th = "อื่นๆ" },
    ["tab_teleport"]        = { vi = "Dịch chuyển",           en = "Teleport",            th = "เทเลพอร์ต" },
    ["tab_config"]          = { vi = "Cấu hình",              en = "Config",              th = "กำหนดค่า" },
    ["tab_moon"]            = { vi = "Raid Mặt Trăng",        en = "Auto Raid Moon",      th = "โจมตีดวงจันทร์" },

    -- ============================================================
    -- 📌 PAGES
    -- ============================================================
    ["page_main_settings"]  = { vi = "Cài đặt chính",         en = "Main Settings",       th = "การตั้งค่าหลัก" },
    ["page_other_settings"] = { vi = "Cài đặt khác",          en = "Other Settings",      th = "การตั้งค่าอื่นๆ" },
    ["page_farm"]           = { vi = "Cày",                   en = "Farm",                th = "ฟาร์ม" },
    ["page_boss"]           = { vi = "Boss",                  en = "Boss",                th = "บอส" },
    ["page_raid_boss"]      = { vi = "Raid Boss & Shop",      en = "Raid Boss & Shop",    th = "บอสโจมตี & ร้านค้า" },
    ["page_dungeon"]        = { vi = "Dungeon, Shop / Weapon",en = "Dungeon, Shop / Weapon", th = "ดันเจี้ยน, ร้านค้า / อาวุธ" },
    ["page_sell_status"]    = { vi = "Bán Item / Trạng thái", en = "Sell Item / Status",  th = "ขายไอเทม / สถานะ" },
    ["page_random"]         = { vi = "Hộp Ngẫu Nhiên",        en = "Random Chest",        th = "หีบสุ่ม" },
    ["page_craft"]          = { vi = "Bàn Chế Tạo",           en = "Craft Table",         th = "โต๊ะคราฟต์" },
    ["page_goku"]           = { vi = "NPC Goku Gods",         en = "NPC Goku Gods",       th = "NPC โกคู" },
    ["page_tp_sea1"]        = { vi = "Dịch chuyển Sea 1",     en = "Teleport Sea 1",      th = "เทเลพอร์ต Sea 1" },
    ["page_moon_raid"]      = { vi = "Raid Moon",             en = "Moon Raid",           th = "โจมตีดวงจันทร์" },
    ["page_save_load"]      = { vi = "Lưu / Đọc",             en = "Save / Load",         th = "บันทึก / โหลด" },

    -- ============================================================
    -- 📌 SECTIONS
    -- ============================================================
    ["sec_select_weapon"]   = { vi = "🗡️ Chọn Vũ Khí",          en = "🗡️ Select Weapon",     th = "🗡️ เลือกอาวุธ" },
    ["sec_auto_skills"]     = { vi = "⚔️ Tự Động Skill",        en = "⚔️ Auto Skills",       th = "⚔️ สกิลอัตโนมัติ" },
    ["sec_method_farm"]     = { vi = "🎯 Phương Pháp Cày",      en = "🎯 Select Method Farm",th = "🎯 วิธีการฟาร์ม" },
    ["sec_haki"]            = { vi = "👁️ Haki",                 en = "👁️ Haki",              th = "👁️ ฮาคิ" },
    ["sec_vfx"]             = { vi = "✨ VFX",                  en = "✨ VFX",               th = "✨ VFX" },
    ["sec_accessory"]       = { vi = "🎒 Phụ Kiện & Hồi Sinh",  en = "🎒 Accessory & Rebirth", th = "🎒 เครื่องประดับ & รีเบิร์ธ" },
    ["sec_potion"]          = { vi = "🧪 Dùng X2 Potion",       en = "🧪 Auto Use X2 Potion",th = "🧪 ใช้ X2 โพชั่น" },
    ["sec_auto_farm"]       = { vi = "🌾 Tự Động Cày",          en = "🌾 Auto Farm",        th = "🌾 ฟาร์มอัตโนมัติ" },
    ["sec_farm_material"]   = { vi = "⛏️ Cày Nguyên Liệu",      en = "⛏️ Auto Farm Material",th = "⛏️ ฟาร์มวัสดุ" },
    ["sec_boss"]            = { vi = "👹 Boss",                 en = "👹 Boss",             th = "👹 บอส" },
    ["sec_thief"]           = { vi = "💸 Thief",                en = "💸 Thief",            th = "💸 โจร" },
    ["sec_piccolo"]         = { vi = "🐉 Piccolo",              en = "🐉 Piccolo",          th = "🐉 Piccolo" },
    ["sec_spawn_check"]     = { vi = "🔍 Kiểm Tra Spawn",       en = "🔍 Spawned Check",    th = "🔍 ตรวจสอบการเกิด" },
    ["sec_duck"]            = { vi = "🦆 Duck",                 en = "🦆 Duck",             th = "🦆 เป็ด" },
    ["sec_devil_boat"]      = { vi = "⛵ Devil Boat",           en = "⛵ Devil Boat",        th = "⛵ เรือปีศาจ" },
    ["sec_dungeon"]         = { vi = "🏰 Tự Động Dungeon",      en = "🏰 Auto Dungeon",     th = "🏰 ดันเจี้ยนอัตโนมัติ" },
    ["sec_shop_dungeon"]    = { vi = "🏪 Shop Dungeon",         en = "🏪 Shop Dungeon",     th = "🏪 ร้านดันเจี้ยน" },
    ["sec_weapon_craft"]    = { vi = "🔨 Vũ Khí",               en = "🔨 Weapon",           th = "🔨 อาวุธ" },
    ["sec_dungeon_settings"]= { vi = "⚙️ Cài Đặt Dungeon",     en = "⚙️ Dungeon Settings", th = "⚙️ ตั้งค่าดันเจี้ยน" },
    ["sec_shop_dungeon_info"]={ vi = "📊 Thông Tin Shop Dungeon",en = "📊 Shop Dungeon Info",th = "📊 ข้อมูลร้านดันเจี้ยน" },
    ["sec_raid_moon"]       = { vi = "🌋 Tự Động Raid Moon",    en = "🌋 Auto Raid Moon",   th = "🌋 โจมตีดวงจันทร์อัตโนมัติ" },
    ["sec_auto_raid_boss"]  = { vi = "⚔️ Tự Động Raid Boss",   en = "⚔️ Auto Raid Boss",   th = "⚔️ โจมตีบอสอัตโนมัติ" },
    ["sec_raid_info"]       = { vi = "📋 Thông Tin Raid",       en = "📋 Raid Info",        th = "📋 ข้อมูลโจมตี" },
    ["sec_shop_raid"]       = { vi = "🏪 Shop Raid",            en = "🏪 Shop Raid",        th = "🏪 ร้านโจมตี" },
    ["sec_shop_info"]       = { vi = "📊 Thông Tin Shop",       en = "📊 Shop Info",        th = "📊 ข้อมูลร้าน" },
    ["sec_raid_settings"]   = { vi = "⚙️ Cài Đặt Raid",        en = "⚙️ Raid Settings",    th = "⚙️ ตั้งค่าโจมตี" },
    ["sec_time_box"]        = { vi = "🎁 Hộp Bí Ẩn Thời Gian",  en = "🎁 Time Mystery Box", th = "🎁 กล่องปริศนาเวลา" },
    ["sec_auto_sell"]       = { vi = "💰 Tự Động Bán",          en = "💰 Auto Sell",        th = "💰 ขายอัตโนมัติ" },
    ["sec_status"]          = { vi = "📊 Trạng Thái",           en = "📊 Status",           th = "📊 สถานะ" },
    ["sec_diamond_chest"]   = { vi = "💎 Hộp Kim Cương",        en = "💎 Diamond Chest",    th = "💎 หีบเพชร" },
    ["sec_moon_chest"]      = { vi = "🌙 Hộp Mặt Trăng",        en = "🌙 Moon Chest",       th = "🌙 หีบพระจันทร์" },
    ["sec_guarantee_diamond"]={ vi = "🎖️ Điểm Đảm Bảo Kim Cương",en = "🎖️ Guarantee Gem Point",th = "🎖️ คะแนนการันตีเพชร" },
    ["sec_guarantee_moon"]  = { vi = "☄️ Điểm Đảm Bảo Moon",    en = "☄️ Guarantee Moon Point",th = "☄️ คะแนนการันตีพระจันทร์" },
    ["sec_craft_table"]     = { vi = "🔨 Bàn Chế Tạo",          en = "🔨 Craft Table",      th = "🔨 โต๊ะคราฟต์" },
    ["sec_craft_status"]    = { vi = "📊 Trạng Thái",           en = "📊 Status",           th = "📊 สถานะ" },
    ["sec_craft_info"]      = { vi = "📋 Thông Tin Craft",      en = "📋 Craft Info",       th = "📋 ข้อมูลคราฟต์" },
    ["sec_npc_current"]     = { vi = "📍 NPC Đang Có",          en = "📍 Current NPCs",     th = "📍 NPC ปัจจุบัน" },
    ["sec_npc_actions"]     = { vi = "⚙️ Hành Động",            en = "⚙️ Actions",          th = "⚙️ การกระทำ" },
    ["sec_island"]          = { vi = "🏝️ Đảo Sea 1",            en = "🏝️ Sea 1 Islands",    th = "🏝️ เกาะ Sea 1" },
    ["sec_sea_travel"]      = { vi = "🌊 Du Hành Biển",         en = "🌊 Sea Travel",       th = "🌊 เดินทางทะเล" },
    ["sec_tp_info"]         = { vi = "📊 Thông Tin",            en = "📊 Info",             th = "📊 ข้อมูล" },
    ["sec_save_load"]       = { vi = "💾 Quản Lý Save",         en = "💾 Save Manager",     th = "💾 จัดการบันทึก" },
    ["sec_save_info"]       = { vi = "📋 Thông Tin",            en = "📋 Info",             th = "📋 ข้อมูล" },
    ["sec_moon_farm"]       = { vi = "🌙 Tự Động Farm Moon",    en = "🌙 Auto Farm Moon",   th = "🌙 ฟาร์มพระจันทร์" },
    ["sec_attack_skill"]    = { vi = "⚔️ Tấn Công / Skill",     en = "⚔️ Attack / Skill",   th = "⚔️ โจมตี / สกิล" },
    ["sec_weapons"]         = { vi = "🗡️ Vũ Khí",               en = "🗡️ Weapons",          th = "🗡️ อาวุธ" },
    ["sec_travel"]          = { vi = "🌍 Du Hành",              en = "🌍 Travel",           th = "🌍 เดินทาง" },

    -- ============================================================
    -- 📌 AUTO FARM
    -- ============================================================
    ["auto_farm_level"]     = { vi = "Tự động cày cấp độ",         en = "Auto Level Farm",       th = "ฟาร์มเลเวลอัตโนมัติ" },
    ["auto_farm_material"]  = { vi = "Tự động cày nguyên liệu",    en = "Auto Farm Material",    th = "ฟาร์มวัสดุอัตโนมัติ" },
    ["auto_farm_all_boss"]  = { vi = "Tự động cày tất cả Boss",    en = "Auto Farm All Boss",    th = "ฟาร์มบอสทั้งหมด" },
    ["auto_farm_thief"]     = { vi = "Tự động cày Thief Chest",    en = "Auto Farm Thief Chest", th = "ฟาร์มหีบโจร" },
    ["auto_farm_piccolo"]   = { vi = "Tự động cày Piccolo",        en = "Auto Farm Piccolo",     th = "ฟาร์ม Piccolo" },
    ["auto_farm_duck"]      = { vi = "Tự động cày Duck (Full)",    en = "Auto Farm Duck (Full)", th = "ฟาร์มเป็ด (เต็ม)" },
    ["auto_farm_devilboat"] = { vi = "Tự động cày Devil Boat",     en = "Auto Farm Devil Boat",  th = "ฟาร์มเรือปีศาจ" },
    ["auto_farm_kraken"]    = { vi = "🐙 Tự động cày Kraken",      en = "🐙 Auto Farm Kraken",   th = "🐙 ฟาร์มคราเคน" },
    ["auto_farm_set"]       = { vi = "Tự động cày Set Weapon",     en = "Auto Farm Set Weapon",  th = "ฟาร์มเซ็ตอาวุธ" },

    -- ============================================================
    -- 📌 WEAPON / SKILL
    -- ============================================================
    ["main_weapon"]         = { vi = "Vũ khí chính (Tấn công)",    en = "Main Weapon (Attack)",  th = "อาวุธหลัก (โจมตี)" },
    ["support_weapon"]      = { vi = "Chọn vũ khí hỗ trợ",         en = "Select Support Weapon", th = "เลือกอาวุธสนับสนุน" },
    ["auto_attack_skill"]   = { vi = "⚔️ Tự động đánh + Skill (Ưu tiên Skill)", en = "⚔️ Auto Attack + Skill (Priority Skill)", th = "⚔️ โจมตี+สกิลอัตโนมัติ" },
    ["auto_attack_skill_hint"]={ vi = "• Ưu tiên dùng Skill (Z/X/C/V/F đã bật)\n• Hết skill → tự động đánh thường\n• Chỉ cần bật 1 nút",
                                 en = "• Priority Skill (enabled Z/X/C/V/F)\n• No skill → auto normal attack\n• Just enable one toggle",
                                 th = "• ลำดับความสำคัญสกิล (เปิด Z/X/C/V/F)\n• ไม่มีสกิล → โจมตีปกติอัตโนมัติ\n• เปิดสวิตช์เดียว" },
    ["auto_skill_z"]        = { vi = "Tự động Skill Z",            en = "Auto Skill Z",          th = "สกิล Z อัตโนมัติ" },
    ["auto_skill_x"]        = { vi = "Tự động Skill X",            en = "Auto Skill X",          th = "สกิล X อัตโนมัติ" },
    ["auto_skill_c"]        = { vi = "Tự động Skill C",            en = "Auto Skill C",          th = "สกิล C อัตโนมัติ" },
    ["auto_skill_v"]        = { vi = "Tự động Skill V",            en = "Auto Skill V",          th = "สกิล V อัตโนมัติ" },
    ["auto_skill_f"]        = { vi = "Tự động Skill F",            en = "Auto Skill F",          th = "สกิล F อัตโนมัติ" },
    ["auto_haki"]           = { vi = "Tự động bật Haki",           en = "Auto Enable Haki",      th = "เปิดฮาคิอัตโนมัติ" },
    ["disable_vfx"]         = { vi = "Tắt VFX",                    en = "Disable VFX",           th = "ปิด VFX" },
    ["auto_equip_accessory"]= { vi = "Tự động trang bị phụ kiện tốt nhất", en = "Auto Equip Best Accessory", th = "สวมเครื่องประดับที่ดีที่สุดอัตโนมัติ" },
    ["auto_rebirth"]        = { vi = "Tự động Hồi Sinh (Max Level)",en = "Auto Rebirth (Max Level)", th = "รีเบิร์ธอัตโนมัติ (เลเวลสูงสุด)" },

    -- ============================================================
    -- 📌 METHOD
    -- ============================================================
    ["method_farm"]         = { vi = "Chọn phương pháp cày",       en = "Select Method Farm",   th = "เลือกวิธีการฟาร์ม" },
    ["distance_farm"]       = { vi = "Khoảng cách cày",            en = "Distance Farm",        th = "ระยะฟาร์ม" },
    ["upper"]               = { vi = "Trên đầu",                   en = "Upper",                th = "ด้านบน" },
    ["below"]               = { vi = "Dưới chân",                  en = "Below",                th = "ด้านล่าง" },
    ["behind"]              = { vi = "Phía sau",                   en = "Behind",               th = "ด้านหลัง" },
    ["front"]               = { vi = "Phía trước",                 en = "Front",                th = "ด้านหน้า" },

    -- ============================================================
    -- 📌 POTION / BOX
    -- ============================================================
    ["select_potion"]       = { vi = "Chọn X2 Potion",             en = "Select X2 Potion",     th = "เลือก X2 โพชั่น" },
    ["potion_amount"]       = { vi = "Số lượng dùng (1-100)",      en = "Amount (1-100)",       th = "จำนวน (1-100)" },
    ["use_potion"]          = { vi = "🧪 DÙNG X2 POTION (1 lần)",  en = "🧪 USE X2 POTION (1x)", th = "🧪 ใช้ X2 โพชั่น (1x)" },
    ["time_box_info"]       = { vi = "🎁 Time Mystery Box: ---",   en = "🎁 Time Mystery Box: ---", th = "🎁 กล่องปริศนาเวลา: ---" },
    ["time_box_hint"]       = { vi = "Nhập số lượng và bấm nút để mở", en = "Enter amount and press button to open", th = "ป้อนจำนวนและกดปุ่มเพื่อเปิด" },
    ["box_amount"]          = { vi = "Số lượng mở (1-100)",        en = "Amount (1-100)",       th = "จำนวน (1-100)" },
    ["open_box"]            = { vi = "🎁 MỞ TIME MYSTERY BOX (1 lần)", en = "🎁 OPEN TIME MYSTERY BOX (1x)", th = "🎁 เปิดกล่องปริศนาเวลา (1x)" },

    -- ============================================================
    -- 📌 DUNGEON / RAID
    -- ============================================================
    ["auto_dungeon"]        = { vi = "🏰 Tự động Dungeon (Full)",  en = "🏰 Auto Dungeon (Full)", th = "🏰 ดันเจี้ยนอัตโนมัติ (เต็ม)" },
    ["auto_raid_moon"]      = { vi = "Tự động Raid Moon (Full)",   en = "Auto Raid Moon (Full)", th = "โจมตีดวงจันทร์อัตโนมัติ" },
    ["dungeon_orb"]         = { vi = "Dungeon Orb dùng",           en = "Dungeon Orb to Use",   th = "Dungeon Orb ที่ใช้" },
    ["health_return"]       = { vi = "Hồi máu %",                  en = "Health Return %",      th = "ฟื้นฟูเลือด %" },
    ["dungeon_height"]      = { vi = "Độ cao Dungeon",             en = "Dungeon Height",       th = "ความสูงดันเจี้ยน" },
    ["choose_raid_boss"]    = { vi = "Chọn boss để raid",          en = "Choose a boss to raid",th = "เลือกบอสที่จะโจมตี" },
    ["start_raid"]          = { vi = "Bắt đầu Raid ngay!!",        en = "Start Raid Now!!",     th = "เริ่มโจมตีทันที!!" },
    ["bacon_grudge_height"] = { vi = "Chiều cao Bacon of Grudge",  en = "Bacon of Grudge Height", th = "ความสูง Bacon of Grudge" },
    ["golden_ball_height"]  = { vi = "Chiều cao Golden Ball",      en = "Golden Ball Height",   th = "ความสูงลูกบอลทอง" },
    ["buy"]                 = { vi = "MUA!!",                      en = "BUY!!",                th = "ซื้อ!!" },
    ["auto_buy"]            = { vi = "Tự động mua",                en = "Auto Buy",             th = "ซื้ออัตโนมัติ" },

    -- ============================================================
    -- 📌 CRAFT
    -- ============================================================
    ["auto_craft"]          = { vi = "🔨 Tự động chế tạo",         en = "🔨 Auto Craft",         th = "🔨 คราฟต์อัตโนมัติ" },
    ["select_craft_item"]   = { vi = "Chọn Item để chế tạo",       en = "Select Item to Craft",  th = "เลือกไอเทมที่จะคราฟต์" },
    ["craft_weapon"]        = { vi = "Chế tạo vũ khí",             en = "Craft Weapon",          th = "คราฟต์อาวุธ" },
    ["auto_claim_guarantee"]= { vi = "✅ Tự động nhận Guarantee (Ưu tiên cao)", en = "✅ Auto Claim Guarantee (High Priority)", th = "✅ รับประกันอัตโนมัติ" },
    ["craft_speed"]         = { vi = "⏱️ Tốc độ hiện tại: ---",     en = "⏱️ Current Speed: ---",  th = "⏱️ ความเร็วปัจจุบัน: ---" },
    ["speed_safe"]          = { vi = "🟢 An toàn (0.5s)",          en = "🟢 Safe (0.5s)",        th = "🟢 ปลอดภัย (0.5s)" },
    ["speed_very_safe"]     = { vi = "🟢 Rất an toàn (1.0s)",      en = "🟢 Very Safe (1.0s)",   th = "🟢 ปลอดภัยมาก (1.0s)" },
    ["speed_ultra_safe"]    = { vi = "🟢 Cực an toàn (2.0s)",      en = "🟢 Ultra Safe (2.0s)",  th = "🟢 ปลอดภัยสูงสุด (2.0s)" },
    ["speed_slow"]          = { vi = "🔵 Siêu chậm (5.0s)",        en = "🔵 Super Slow (5.0s)",  th = "🔵 ช้ามาก (5.0s)" },
    ["craft_speed_hint"]    = { vi = "📖 Hướng dẫn tốc độ\n🟢 0.5-1.0s: An toàn (khuyến nghị)\n🟢 1.0-2.0s: Rất an toàn\n🟢 2.0-5.0s: Cực an toàn\n🔵 5.0s+: Chỉ dùng khi ping cao\n\n💡 Nếu vẫn phí → chọn mức 2.0s hoặc 5.0s",
                              en = "📖 Speed Guide\n🟢 0.5-1.0s: Safe (recommended)\n🟢 1.0-2.0s: Very safe\n🟢 2.0-5.0s: Ultra safe\n🔵 5.0s+: Only for high ping\n\n💡 If still wasted → use 2.0s or 5.0s",
                              th = "📖 คำแนะนำความเร็ว\n🟢 0.5-1.0s: ปลอดภัย (แนะนำ)\n🟢 1.0-2.0s: ปลอดภัยมาก\n🟢 2.0-5.0s: ปลอดภัยสูงสุด\n🔵 5.0s+: สำหรับ ping สูง\n\n💡 ถ้ายังเสียเปล่า → ใช้ 2.0s หรือ 5.0s" },

    -- ============================================================
    -- 📌 SELL
    -- ============================================================
    ["select_sell"]         = { vi = "Chọn Item bán",              en = "Select Sell Item",      th = "เลือกไอเทมขาย" },
    ["auto_sell"]           = { vi = "Tự động bán",                en = "Auto Sell",             th = "ขายอัตโนมัติ" },
    ["status_amount"]       = { vi = "Số lượng",                   en = "Amount",                th = "จำนวน" },
    ["auto_up_melee"]       = { vi = "Tự động nâng Melee",         en = "Auto Up Melee",         th = "เพิ่ม Melee อัตโนมัติ" },
    ["auto_up_defense"]     = { vi = "Tự động nâng Defense",       en = "Auto Up Defense",       th = "เพิ่ม Defense อัตโนมัติ" },
    ["auto_up_sword"]       = { vi = "Tự động nâng Sword",         en = "Auto Up Sword",         th = "เพิ่ม Sword อัตโนมัติ" },
    ["auto_up_power"]       = { vi = "Tự động nâng Power",         en = "Auto Up Power",         th = "เพิ่ม Power อัตโนมัติ" },

    -- ============================================================
    -- 📌 RANDOM CHEST
    -- ============================================================
    ["select_random_chest"] = { vi = "Chọn Hộp Random Kim Cương",  en = "Select Random Diamond Chest", th = "เลือกหีบสุ่มเพชร" },
    ["open_once"]           = { vi = "🎲 Mở 1 lần (Random Item)",  en = "🎲 Open Once (Random Item)", th = "🎲 เปิด 1 ครั้ง" },
    ["auto_random_chest"]   = { vi = "Tự động mở Hộp Kim Cương",   en = "Auto Random Diamond Chest", th = "เปิดหีบเพชรอัตโนมัติ" },
    ["select_random_moon"]  = { vi = "Chọn Hộp Random Moon",       en = "Select Random Moon Chest", th = "เลือกหีบสุ่มพระจันทร์" },
    ["open_moon_once"]      = { vi = "🌙 Mở 1 lần (Event Moon)",   en = "🌙 Open Once (Event Moon)", th = "🌙 เปิด 1 ครั้ง (อีเวนต์)" },
    ["auto_random_moon"]    = { vi = "Tự động mở Hộp Moon",        en = "Auto Random Moon Chest", th = "เปิดหีบพระจันทร์อัตโนมัติ" },
    ["select_guarantee_diamond"]={ vi = "Chọn Điểm Đảm Bảo Kim Cương", en = "Select Guarantee Diamond Point", th = "เลือกคะแนนการันตีเพชร" },
    ["buy_once"]            = { vi = "💎 MUA 1 lần",               en = "💎 BUY 1x",             th = "💎 ซื้อ 1 ครั้ง" },
    ["auto_buy_guarantee_diamond"]={ vi = "Tự động mua Điểm Đảm Bảo KC", en = "Auto Buy Guarantee Diamond", th = "ซื้อการันตีเพชรอัตโนมัติ" },
    ["select_guarantee_moon"]={ vi = "Chọn Điểm Đảm Bảo Moon",     en = "Select Guarantee Moon Point", th = "เลือกคะแนนการันตีพระจันทร์" },
    ["buy_moon_once"]       = { vi = "🌙 MUA 1 lần",               en = "🌙 BUY 1x",             th = "🌙 ซื้อ 1 ครั้ง" },
    ["auto_buy_guarantee_moon"]={ vi = "Tự động mua Điểm Đảm Bảo Moon", en = "Auto Buy Guarantee Moon", th = "ซื้อการันตีพระจันทร์อัตโนมัติ" },

    -- ============================================================
    -- 📌 TELEPORT
    -- ============================================================
    ["select_island"]       = { vi = "🏝️ Chọn Đảo Sea 1",          en = "🏝️ Select Island Sea 1",th = "🏝️ เลือกเกาะ Sea 1" },
    ["tp_to_island"]        = { vi = "✈️ Dịch Chuyển Tới Đảo",     en = "✈️ Teleport to Island", th = "✈️ เทเลพอร์ตไปเกาะ" },
    ["go_sea2"]             = { vi = "🌊 Đi Tới Sea 2 (2SeaSoon)", en = "🌊 Go to Sea 2",        th = "🌊 ไป Sea 2" },
    ["back_earth"]          = { vi = "🌍 Quay Về Trái Đất (Back Earth)", en = "🌍 Back to Earth", th = "🌍 กลับสู่โลก" },

    -- ============================================================
    -- 📌 SAVE / LOAD
    -- ============================================================
    ["save_name"]           = { vi = "✏️ Tên Save mới",             en = "✏️ New Save Name",     th = "✏️ ชื่อบันทึกใหม่" },
    ["save_name_ph"]        = { vi = "VD: Save1",                  en = "Ex: Save1",             th = "ตัวอย่าง: Save1" },
    ["select_save"]         = { vi = "📁 Chọn Save",                en = "📁 Select Save",       th = "📁 เลือกบันทึก" },
    ["save"]                = { vi = "💾 LƯU",                      en = "💾 SAVE",               th = "💾 บันทึก" },
    ["load"]                = { vi = "📂 ĐỌC",                      en = "📂 LOAD",               th = "📂 โหลด" },
    ["delete_save"]         = { vi = "🗑️ Xóa Save",                en = "🗑️ Delete Save",        th = "🗑️ ลบบันทึก" },
    ["refresh_list"]        = { vi = "🔄 Làm mới danh sách",        en = "🔄 Refresh List",       th = "🔄 รีเฟรชรายการ" },
    ["save_hint"]           = { vi = "📖 Hướng dẫn\n1. Nhập tên Save → SAVE\n2. Chọn Save từ dropdown → LOAD\n3. Xóa bằng nút 🗑️",
                                en = "📖 Guide\n1. Enter Save name → SAVE\n2. Choose Save from dropdown → LOAD\n3. Delete with 🗑️ button",
                                th = "📖 คำแนะนำ\n1. ป้อนชื่อ → บันทึก\n2. เลือกจาก dropdown → โหลด\n3. ลบด้วยปุ่ม 🗑️" },

    -- ============================================================
    -- 📌 NPC GOKU
    -- ============================================================
    ["auto_find_click_npc"]= { vi = "🎯 Tự động tìm & click NPC",  en = "🎯 Auto Find & Click NPC", th = "🎯 ค้นหา & คลิก NPC อัตโนมัติ" },
    ["auto_tp_npc"]         = { vi = "✈️ Tự động TP tới NPC gần nhất", en = "✈️ Auto TP Nearest NPC", th = "✈️ TP ไป NPC ใกล้สุด" },

    -- ============================================================
    -- 📌 MOON
    -- ============================================================
    ["auto_farm_moon"]      = { vi = "🌙 Tự động Farm Moon Mob",   en = "🌙 Auto Farm Moon Mob",  th = "🌙 ฟาร์มม็อบดวงจันทร์" },
    ["moon_hit_pos"]        = { vi = "🎯 Vị trí đánh",              en = "🎯 Hit Position",        th = "🎯 ตำแหน่งโจมตี" },
    ["moon_hit_pos_upper"]  = { vi = "Upper (Trên đầu)",            en = "Upper (Above)",          th = "ด้านบน (เหนือ)" },
    ["moon_hit_pos_below"]  = { vi = "Below (Dưới chân)",           en = "Below (Under)",          th = "ด้านล่าง (ใต้)" },
    ["moon_hit_pos_behind"] = { vi = "Behind (Phía sau)",           en = "Behind",                 th = "ด้านหลัง" },
    ["moon_hit_pos_front"]  = { vi = "Front (Phía trước)",          en = "Front",                  th = "ด้านหน้า" },
    ["moon_hit_dist"]       = { vi = "📏 Khoảng cách đánh",         en = "📏 Hit Distance",        th = "📏 ระยะโจมตี" },

    -- ============================================================
    -- 📌 NOTIFICATIONS
    -- ============================================================
    ["noti_success"]        = { vi = "✅ Thành công",              en = "✅ Success",             th = "✅ สำเร็จ" },
    ["noti_error"]          = { vi = "❌ Lỗi",                    en = "❌ Error",               th = "❌ ผิดพลาด" },
    ["noti_warning"]        = { vi = "⚠️ Cảnh báo",               en = "⚠️ Warning",             th = "⚠️ คำเตือน" },
    ["noti_loading"]        = { vi = "⏳ Đang tải...",             en = "⏳ Loading...",          th = "⏳ กำลังโหลด..." },
    ["noti_no_item"]        = { vi = "❌ Không có vật phẩm",       en = "❌ No item",             th = "❌ ไม่มีไอเทม" },
    ["noti_not_selected"]   = { vi = "❌ Chưa chọn",               en = "❌ Not selected",        th = "❌ ยังไม่ได้เลือก" },
    ["noti_done"]           = { vi = "🎉 Hoàn thành",              en = "🎉 Done",                th = "🎉 เสร็จสิ้น" },
    ["noti_amount_error"]   = { vi = "Số lượng phải từ 1-100",     en = "Amount must be 1-100",   th = "จำนวนต้องอยู่ 1-100" },
    ["noti_no_remote"]      = { vi = "❌ Không tìm thấy Remote",   en = "❌ Remote not found",    th = "❌ ไม่พบรีโมท" },
    ["noti_select_potion"]  = { vi = "❌ Chưa chọn Potion",        en = "❌ Potion not selected", th = "❌ ยังไม่ได้เลือกโพชั่น" },
    ["noti_select_item"]    = { vi = "❌ Chưa chọn Item",          en = "❌ Item not selected",   th = "❌ ยังไม่ได้เลือกไอเทม" },
    ["noti_used_potion"]    = { vi = "🧪 Đang dùng Potion",        en = "🧪 Using Potion",        th = "🧪 กำลังใช้โพชั่น" },
    ["noti_open_box"]       = { vi = "🎁 Đang mở Box",             en = "🎁 Opening Box",         th = "🎁 กำลังเปิดกล่อง" },
    ["noti_lang_changed"]   = { vi = "Đã đổi sang Tiếng Việt",     en = "Switched to English",    th = "เปลี่ยนเป็นภาษาไทย" },
    ["noti_save_success"]   = { vi = "💾 Đã lưu thành công",       en = "💾 Saved successfully",  th = "💾 บันทึกสำเร็จ" },
    ["noti_load_success"]   = { vi = "📂 Đã load thành công",      en = "📂 Loaded successfully", th = "📂 โหลดสำเร็จ" },
    ["noti_no_save"]        = { vi = "❌ Không có save",           en = "❌ No save found",       th = "❌ ไม่พบบันทึก" },
    ["noti_tp_success"]     = { vi = "✈️ Đã dịch chuyển",          en = "✈️ Teleported",          th = "✈️ เทเลพอร์ตแล้ว" },
    ["noti_tp_fail"]        = { vi = "❌ Không tìm thấy đảo",      en = "❌ Island not found",    th = "❌ ไม่พบเกาะ" },

    -- ============================================================
    -- 📌 PARAGRAPHS / STATUS
    -- ============================================================
    ["status_title"]        = { vi = "Trạng thái",                 en = "Status",                 th = "สถานะ" },
    ["status_waiting"]      = { vi = "Trạng thái: Chờ bật",        en = "Status: Waiting",        th = "สถานะ: รอเปิด" },
    ["status_farming"]      = { vi = "Trạng thái: ĐANG FARM",      en = "Status: FARMING",        th = "สถานะ: กำลังฟาร์ม" },
    ["status_off"]          = { vi = "Trạng thái: Đã tắt",         en = "Status: OFF",            th = "สถานะ: ปิด" },
    ["status_hint"]         = { vi = "Bật toggle bên trái để farm", en = "Enable toggle on left to farm", th = "เปิดสวิตช์ด้านซ้ายเพื่อฟาร์ม" },
    ["status_waiting_mob"]  = { vi = "Đứng tại cửa hang đợi mob",  en = "Standing at cave entrance waiting for mob", th = "ยืนที่ปากถ้ำรอม็อบ" },
    ["status_searching"]    = { vi = "Đang tìm mob...",            en = "Searching for mob...",   th = "กำลังค้นหาม็อบ..." },
    ["status_resume"]       = { vi = "Bật lại để tiếp tục",        en = "Enable again to resume", th = "เปิดอีกครั้งเพื่อดำเนินการต่อ" },

    -- ============================================================
    -- 📌 SPAWN STATUS
    -- ============================================================
    ["spawn_status"]        = { vi = "Trạng thái Spawn",           en = "Spawn Status",           th = "สถานะการเกิด" },
    ["item_requirements"]   = { vi = "Yêu cầu vật phẩm",           en = "Item Requirements",      th = "ความต้องการไอเทม" },
    ["not_selected_hint"]   = { vi = "📖 Hướng dẫn:\n  1. Chọn Weapon từ dropdown\n  2. Bấm TP đến NPC Material\n  3. Bật Auto Craft",
                                en = "📖 Guide:\n  1. Select Weapon from dropdown\n  2. Press TP to Material NPC\n  3. Enable Auto Craft",
                                th = "📖 คำแนะนำ:\n  1. เลือกอาวุธจาก dropdown\n  2. กด TP ไป NPC วัสดุ\n  3. เปิดคราฟต์อัตโนมัติ" },

    -- ============================================================
    -- 📌 BUTTONS COMMON
    -- ============================================================
    ["btn_confirm"]         = { vi = "Xác nhận",                   en = "Confirm",                th = "ยืนยัน" },
    ["btn_cancel"]          = { vi = "Hủy",                        en = "Cancel",                 th = "ยกเลิก" },
    ["btn_yes"]             = { vi = "Có",                         en = "Yes",                    th = "ใช่" },
    ["btn_no"]              = { vi = "Không",                      en = "No",                     th = "ไม่" },
    ["btn_close"]           = { vi = "Đóng",                       en = "Close",                  th = "ปิด" },
    ["btn_ok"]              = { vi = "OK",                         en = "OK",                     th = "ตกลง" },

    -- ============================================================
    -- 📌 SEARCH
    -- ============================================================
    ["search_tabs"]         = { vi = "Tìm tab...",                 en = "Search tabs...",         th = "ค้นหาแท็บ..." },
    ["search_placeholder"]  = { vi = "Tìm kiếm...",                en = "Search...",              th = "ค้นหา..." },
    ["search_saves"]        = { vi = "Tìm Save...",                en = "Search Saves...",        th = "ค้นหาบันทึก..." },

    -- ============================================================
    -- 📌 POPUP EXIT
    -- ============================================================
    ["exit_title"]          = { vi = "Thoát ứng dụng",             en = "Exit Application",       th = "ออกจากแอป" },
    ["exit_desc"]           = { vi = "Bạn có chắc muốn đóng MarvenRiz Hub? Cấu hình chưa lưu có thể bị mất.",
                                en = "Are you sure you want to close MarvenRiz Hub? Unsaved configs might be lost.",
                                th = "คุณแน่ใจหรือไม่ที่จะปิด MarvenRiz Hub? การตั้งค่าที่ไม่ได้บันทึกอาจสูญหาย" },
}

function i18n.L(key)
    local entry = i18n.Translations[key]
    if not entry then return key end
    return entry[i18n.CurrentLang] or entry.vi or key
end

L = i18n.L

function i18n.SetLang(code)
    if code == "vi" or code == "en" or code == "th" then
        i18n.CurrentLang = code
        return true
    end
    return false
end

return i18n