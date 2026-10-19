-- Shop/ShopDungeon.lua
local Services = require(script.Parent.Parent.Core.Services)
local Helpers  = require(script.Parent.Parent.Core.Helpers)
local LocalPlayer = Services.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage

_G.AutoBuyDunItem    = nil
_G.AutoBuyDunRunning = false

local ShopDunInfoPara = _G.ShopDunInfoPara
local LastAutoBuyDunStr = ""

local function GetAllShopDunItems()
    local items, seen = {}, {}
    local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
    if hud and hud:FindFirstChild("Main") then
        local shop = hud.Main:FindFirstChild("Frame_ShopDungeon")
        if shop then
            local sf = shop:FindFirstChild("ShopScrollingFrame")
            if sf then
                for _, item in pairs(sf:GetChildren()) do
                    if item:IsA("Frame") then
                        local main = item:FindFirstChild("Main")
                        if main then
                            local titleLbl = main:FindFirstChild("TitleLabel")
                            if titleLbl and titleLbl.Text and titleLbl.Text ~= "" then
                                if not seen[titleLbl.Text] then
                                    seen[titleLbl.Text] = true
                                    table.insert(items, titleLbl.Text)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(items)
    return items
end

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local pt = LocalPlayer:GetAttribute("DungeonPoint") or 0
            if ShopDunInfoPara then ShopDunInfoPara:SetTitle("DungeonPoint: " .. tostring(pt)) end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if _G.AutoBuyDunRunning and _G.AutoBuyDunItem then
            pcall(function()
                ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer(
                    "fire", nil, "BuyDungeonShop", _G.AutoBuyDunItem)
                task.wait(0.2)
            end)
        end
    end
end)
