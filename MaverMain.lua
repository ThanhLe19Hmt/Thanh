-- ============================================
-- AUTO LOADER (MULTI-MAP)
-- ============================================

-- ⚠️ KHAI BÁO PLACE ID
local PLACEID_SEA1 = 119091355492870
local PLACEID_SEA2 = 132854526011923
local PLACEID_MOON = 82878101790702

local PLACEID_SYI_1 = 77900175935766
local PLACEID_SYI_2 = 109001332046330

-- ⚠️ KHAI BÁO URL
local URL_SEA1 = "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/MaverSEA1ROCKFRULT.lua"
local URL_SEA2 = "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/MaverSEA2ROCKFRULT.lua"
local URL_SYI  = "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/ScriptALL/Survive%20Your%20Ideas.lua"

local placeId = game.PlaceId

-- Hàm tải và chạy script
local function LoadScript(url, mapName)
    print("[LOADER] Đang tải script cho: " .. mapName .. "...")
    
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
    
    print("[LOADER] Tải thành công: " .. mapName)
    return true
end

-- Kiểm tra Place ID và tải script tương ứng
if placeId == PLACEID_SEA1 then
    LoadScript(URL_SEA1, "Sea 1")
    
elseif placeId == PLACEID_SEA2 then
    LoadScript(URL_SEA2, "Sea 2")
    
elseif placeId == PLACEID_MOON then
    LoadScript(URL_SEA1, "Moon")
    
elseif placeId == PLACEID_SYI_1 or placeId == PLACEID_SYI_2 then
    LoadScript(URL_SYI, "Survive Your Ideas")
    
else
    print("[LOADER] Game này không nằm trong danh sách hỗ trợ. (Place ID: " .. placeId .. ")")
end
