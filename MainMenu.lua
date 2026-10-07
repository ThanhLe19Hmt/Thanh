-- =========================================================
--  NEO HUB - Main Menu (KHÔNG chứa logic game)
--  - Chỉ tạo UI, các nút bấm
--  - Khi bấm → load module từ features/ folder
-- =========================================================
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- ===== CONFIG =====
local GITHUB_BASE = "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main"
local UI_URL       = GITHUB_BASE .. "/NeoUI.lua"
local FEATURES_URL = GITHUB_BASE .. "/features"

-- ===== LOAD UI =====
local NeoUI = loadstring(game:HttpGet(UI_URL))()

local loader = NeoUI.Loader:Show({
	Title = "Neo Hub", Subtitle = "Đang khởi tạo", MinDuration = 1.5,
})

-- =========================================================
--  MODULE LOADER
-- =========================================================
local ModuleCache = {}

-- Tải module từ features/<name>.lua và trả về table/function
-- Module phải return 1 table có method .Run(NeoUI, Tab, Ctx) hoặc 1 function
local function LoadFeature(name)
	if ModuleCache[name] then
		return ModuleCache[name], nil
	end

	local url = FEATURES_URL .. "/" .. name .. ".lua"
	print("[Neo] Đang tải module:", url)

	local ok, code = pcall(function()
		return game:HttpGet(url)
	end)

	if not ok or not code or #code < 50 then
		warn("[Neo] Không tải được module:", name)
		return nil, "Không tải được file"
	end

	if code:find("<!DOCTYPE") or code:find("404: Not Found") then
		warn("[Neo] File không tồn tại:", name)
		return nil, "File không tồn tại"
	end

	local lsOk, fn = pcall(loadstring, code)
	if not lsOk or type(fn) ~= "function" then
		warn("[Neo] Lỗi compile module:", name)
		return nil, "Code không hợp lệ"
	end

	local runOk, mod = pcall(fn)
	if not runOk then
		warn("[Neo] Lỗi chạy module:", name, mod)
		return nil, "Lỗi runtime"
	end

	ModuleCache[name] = mod
	return mod, nil
end

-- Chạy 1 feature: truyền NeoUI + Tab + Context (LP, hud helpers)
local function RunFeature(name, tab)
	local mod, err = LoadFeature(name)
	if not mod then
		NeoUI.Notify:Show({
			Title = "❌ Không tải được chức năng",
			Description = err or name,
			Duration = 3,
		})
		return
	end

	-- Module là table có .Run()
	if type(mod) == "table" and type(mod.Run) == "function" then
		local ok, runErr = pcall(mod.Run, NeoUI, tab)
		if not ok then
			warn("[Neo] Lỗi khi chạy module:", name, runErr)
			NeoUI.Notify:Show({
				Title = "❌ Lỗi chức năng",
				Description = tostring(runErr):sub(1, 60),
				Duration = 3,
			})
		end
	-- Module là function trực tiếp
	elseif type(mod) == "function" then
		local ok, runErr = pcall(mod, NeoUI, tab)
		if not ok then
			warn("[Neo] Lỗi khi chạy function:", name, runErr)
		end
	else
		warn("[Neo] Module không hợp lệ:", name, type(mod))
	end
end

-- =========================================================
--  MENU
-- =========================================================
local Window = NeoUI:CreateWindow({ Title = "Neo Hub", Subtitle = "Rock Fruit" })

-- ===== TAB: CHÍNH =====
local MainTab = Window:CreateTab("Chính")

-- Section 1: Player Info
local InfoSec = MainTab:CreateSection("👤 Thông tin Player")
InfoSec:Button({
	Title = "📋 Mở thông tin Player",
	Callback = function()
		RunFeature("player_info", MainTab)
	end,
})

-- Section 2: Stats
local StatSec = MainTab:CreateSection("📊 Combat Stats")
StatSec:Button({
	Title = "➕ Mở cộng Stats",
	Callback = function()
		RunFeature("add_stats", MainTab)
	end,
})

-- Section 3: (Sau này thêm module mới ở đây)
local FutureSec = MainTab:CreateSection("🚀 Sắp có")
FutureSec:Paragraph({
	Title = "Ghi chú",
	Content = "Muốn thêm chức năng? Chỉ cần tạo file mới trong features/ rồi thêm nút gọi nó.\nKhông cần sửa file này.",
})

-- ===== TAB: SETTINGS =====
local SettingsTab = Window:CreateTab("Cài đặt")
local SetSec = SettingsTab:CreateSection("🎨 Giao diện")

SetSec:Button({
	Title = "🔄 Xoá cache Module",
	Callback = function()
		ModuleCache = {}
		NeoUI.Notify:Show({
			Title = "Đã xoá cache",
			Description = "Các module sẽ tải lại khi bấm",
			Duration = 3,
		})
	end,
})

-- ===== TAB: MÀU =====
local ColorTab = Window:CreateTab("Màu")
local ColorSec = ColorTab:CreateSection("🎨 Tùy Chỉnh")
ColorSec:ColorRow({
	Title = "Màu Menu", Value = NeoUI.Theme.Accent,
	Setter = function(c) NeoUI.SetMenuColor(c) end,
})
ColorSec:ColorRow({
	Title = "Màu Nút", Value = NeoUI.Theme.Button,
	Setter = function(c) NeoUI.SetButtonColor(c) end,
})

-- =========================================================
--  REVEAL
-- =========================================================
task.spawn(function()
	task.wait(0.8)
	loader:SetStatus("Hoàn tất!")
	loader:SetProgress(1)
	task.wait(0.3)
	loader:Close()
	Window:Reveal()
	NeoUI.Notify:Show({
		Title = "✅ Neo Hub",
		Description = "Chọn chức năng trong tab Chính",
		Duration = 3,
	})
end)
