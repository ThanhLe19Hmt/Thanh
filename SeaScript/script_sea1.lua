-- ===== CHECK SEA TRƯỚC KHI CHẠY =====
local LocalPlayer = game:GetService("Players").LocalPlayer
repeat task.wait() until game:IsLoaded() and LocalPlayer and LocalPlayer.Character
local CurrentSea = LocalPlayer:GetAttribute("CurrentSea") or "First"

if CurrentSea ~= "First" then
    warn("[Sea 1 Script] Bạn đang ở " .. CurrentSea .. " — script này chỉ chạy ở Sea 1!")
    return  -- Thoát, không chạy script
end

-- ===== TỪ ĐÂY LÀ CODE SEA 1 =====
-- Toàn bộ mã gốc của bạn (tab Settings, Farm, Boss, v.v.)
-- ...
