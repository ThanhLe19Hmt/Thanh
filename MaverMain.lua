-- ============================================
-- AUTO LOADER (MULTI-MAP)
-- ============================================

-- ⚠️ KHAI BÁO PLACE ID
local PLACEID_SEA1 = 119091355492870
local PLACEID_SEA2 = 132854526011923
local PLACEID_MOON = 82878101790702
local PLACEID_SYI  = 77900175935766 -- 👈 CẬU ĐIỀN PLACE ID CỦA MAP "SURVIVE YOUR IDEAS" VÀO ĐÂY

-- ⚠️ KHAI BÁO URL
local URL_SEA1 = "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/MaverSEA1ROCKFRULT.lua"
local URL_SEA2 = "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/MaverSEA2ROCKFRULT.lua"
local URL_SYI  = "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/ScriptALL/Survive%20Your%20Ideas.lua"

local placeId = game.PlaceId

-- Hàm tải và chạy script
local function LoadScript(url)
    local success, source = pcall(function()
        return game:HttpGet(url)
    end)

    if not success or not source or source == "" then
        warn("[LOADER] Không thể tải script từ: " .. url)
        return false
    end

    local execSuccess, execErr = pcall(function()
        local func, compileErr = loadstring(source)
        if not func then
            error("Compile error: " .. tostring(compileErr))
        end
        func()
    end)

    if not execSuccess then
        warn("[LOADER] Lỗi khi chạy script: " .. tostring(execErr))
        return false
    end
    return true
end

-- Kiểm tra Place ID và tải script tương ứng
if placeId == PLACEID_SEA1 then
    print("[LOADER] Đang tải: Sea 1...")
    LoadScript(URL_SEA1)
    
elseif placeId == PLACEID_SEA2 then
    print("[LOADER] Đang tải: Sea 2...")
    LoadScript(URL_SEA2)
    
elseif placeId == PLACEID_MOON then
    print("[LOADER] Đang tải: Moon...")
    LoadScript(URL_SEA1) -- Cậu đang dùng URL của Sea 1 cho Moon, nếu muốn đổi thì sửa lại URL_MOON nhé
    
elseif placeId == PLACEID_SYI then
    print("[LOADER] Đang tải: Survive Your Ideas...")
    LoadScript(URL_SYI)
    
else
    print("[LOADER] Game này không nằm trong danh sách hỗ trợ.")
end
