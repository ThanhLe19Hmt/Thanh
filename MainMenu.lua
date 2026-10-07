-- =========================================================
--  NEO HUB - Main Menu
--  Modules tự chạy khi load, KHÔNG cần bấm nút
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

local function RunFeature(name, tab)
	local mod, err = LoadFeature(name)
	if not mod then
		warn("[Neo] Không chạy được feature:", name, err)
		return false
	end

	if type(mod) == "table" and type(mod.Run) == "function" then
		local ok, runErr = pcall(mod.Run, NeoUI, tab)
		if not ok then
			warn("[Neo] Lỗi khi chạy module:", name, runErr)
			return false
		end
		return true
	elseif type(mod) == "function" then
		local ok, runErr = pcall(mod, NeoUI, tab)
		if not ok then
			warn("[Neo] Lỗi khi chạy function:", name, runErr)
			return false
		end
		return true
	end
	warn("[Neo] Module không hợp lệ:", name, type(mod))
	return false
end

-- =========================================================
--  MENU
-- =========================================================
local Window = NeoUI:CreateWindow({ Title = "Neo Hub", Subtitle = "Rock Fruit" })

-- ⭐ TAB 1: THÔNG TIN — tự load player_info
local InfoTab = Window:CreateTab("Thông tin")
task.spawn(function()
	task.wait(0.5)
	RunFeature("player_info", InfoTab)
end)

-- ⭐ TAB 2: STATS — tự load add_stats
local StatsTab = Window:CreateTab("Stats")
task.spawn(function()
	task.wait(0.6)
	RunFeature("add_stats", StatsTab)
end)

-- ⭐ TAB RANDOM ITEM
local RandTab = Window:CreateTab("Random Item")
task.spawn(function()
	task.wait(0.7)
	RunFeature("random_item", RandTab)
end)

-- ⭐ TAB SHOP ITEM
local ShopTab = Window:CreateTab("Shop Item")
task.spawn(function()
	task.wait(0.8)
	RunFeature("shop_item", ShopTab)
end)

-- ⭐ TAB 3: CÀI ĐẶT
local SettingsTab = Window:CreateTab("Cài đặt")
local SetSec = SettingsTab:CreateSection("🎨 Giao diện")

SetSec:Button({
	Title = "🔄 Xoá cache Module",
	Callback = function()
		ModuleCache = {}
		NeoUI.Notify:Show({
			Title = "Đã xoá cache",
			Description = "Chạy lại script để load mới",
			Duration = 3,
		})
	end,
})

SetSec:Paragraph({
	Title = "Hướng dẫn",
	Content = "Các chức năng tự chạy khi vào tab.\nKhông cần bấm nút.\n\nMuốn thêm chức năng? Tạo file mới trong features/ rồi thêm RunFeature vào MainMenu.",
})

-- ⭐ TAB 4: MÀU — tự load module theme
local ColorTab = Window:CreateTab("Color")
task.spawn(function()
	task.wait(0.7)
	RunFeature("theme", ColorTab)
end)

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
		Description = "Đã sẵn sàng!",
		Duration = 3,
	})
end)
