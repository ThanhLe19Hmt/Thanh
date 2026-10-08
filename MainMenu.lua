-- ============================================================
-- LOADER — Tự động chọn script theo Sea (từ GitHub)
-- ============================================================
repeat task.wait() until game:IsLoaded() 
    and game.Players.LocalPlayer 
    and game.Players.LocalPlayer.Character

local LocalPlayer = game.Players.LocalPlayer
local CurrentSea = LocalPlayer:GetAttribute("CurrentSea") or "First"

print("[Loader] Sea hiện tại:", CurrentSea)

-- ===== URL GITHUB =====
local BASE_URL = "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/"
-- Thay USERNAME/REPO bằng GitHub của bạn

-- ===== CHỌN FILE =====
local scriptFile
if CurrentSea == "First" then
    scriptFile = "SeaScript/script_sea1.lua"
elseif CurrentSea == "Second" then
    scriptFile = "SeaScript/script_sea2.lua"
else
    warn("[Loader] ❌ Sea không xác định:", CurrentSea)
    return
end

-- ===== LOAD =====
local url = BASE_URL .. scriptFile
print("[Loader] Fetching:", url)

local ok, source = pcall(function()
    return game:HttpGet(url)
end)

if not ok or not source then
    warn("[Loader] ❌ Không tải được:", url)
    return
end

print("[Loader] ✅ Đã tải", #source, "bytes")

local func, err = loadstring(source)
if not func then
    warn("[Loader] ❌ Lỗi compile:", err)
    return
end

local runOk, runErr = pcall(func)
if not runOk then
    warn("[Loader] ❌ Lỗi runtime:", runErr)
else
    print("[Loader] ✅ Load thành công", scriptFile)
end
