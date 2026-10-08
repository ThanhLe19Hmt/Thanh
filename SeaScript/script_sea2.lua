-- ===== CHECK SEA TRƯỚC KHI CHẠY =====
local LocalPlayer = game:GetService("Players").LocalPlayer
repeat task.wait() until game:IsLoaded() and LocalPlayer and LocalPlayer.Character
local CurrentSea = LocalPlayer:GetAttribute("CurrentSea") or "First"

if CurrentSea ~= "Second" then
    warn("[Sea 2 Script] Bạn đang ở " .. CurrentSea .. " — script này chỉ chạy ở Sea 2!")
    return
end

-- ===== TỪ ĐÂY LÀ CODE SEA 2 =====
-- Chỉ những gì cần cho Sea 2: tab Teleport (6 đảo), tab Sea travel, v.v.
