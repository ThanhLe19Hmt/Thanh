-- Shop/ShopRaid.lua
local Services = require(script.Parent.Parent.Core.Services)
local Helpers  = require(script.Parent.Parent.Core.Helpers)
local LocalPlayer = Services.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage

-- UI placeholder — refs sẽ được Sea1UI đẩy vào _G
-- File này chỉ cung cấp logic loop nếu cần; UI đã có ở Sea1UI

local ShopInfoPara = _G.ShopInfoPara  -- Sea1UI gán
local LastShopItemsStr = ""
local ShopDropdownInitialized = false

local function UpdateShopDropdown(items)
    if #items == 0 then return end
    local s = table.concat(items, ",")
    if s == LastShopItemsStr then return end
    LastShopItemsStr = s
    -- Nếu bạn muốn dropdown logic phức tạp, thêm ở đây
end

_G.SelectedShopItem = nil

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            if not hud or not hud:FindFirstChild("Main") then return end
            local shop = hud.Main:FindFirstChild("Frame_ShopRaid")
            if not shop then return end
            local rpLbl = shop:FindFirstChild("RaidPoint")
            local resetLbl = shop:FindFirstChild("Reset")
            if rpLbl and resetLbl and ShopInfoPara then
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
