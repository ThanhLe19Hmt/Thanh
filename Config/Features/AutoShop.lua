--[[
    Features/AutoShop.lua
    Shop Raid + Shop Dungeon (Auto Buy)
]]

local Globals = _G.__Globals or Globals
local Utils   = Globals.Utils
local Inventory = Globals.Inventory
local RS      = Globals.ReplicatedStorage
local LP      = Globals.LocalPlayer

-- ===== Helper lấy Shop Raid Items =====
local function GetAllShopItems()
    local items, seen = {}, {}
    local hud = LP.PlayerGui:FindFirstChild("HUD")
    if hud and hud:FindFirstChild("Main") then
        local shop = hud.Main:FindFirstChild("Frame_ShopRaid")
        if shop then
            local sf = shop:FindFirstChild("ScrollingFrame")
            if sf then
                for _, item in pairs(sf:GetChildren()) do
                    if item:IsA("Frame") then
                        local label = item:FindFirstChild("Label")
                        if label and label.Text and label.Text ~= "" and label.Text ~= "Item" then
                            if not seen[label.Text] then
                                seen[label.Text] = true
                                table.insert(items, label.Text)
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

-- ===== Helper lấy Shop Dungeon Items =====
local function GetAllShopDunItems()
    local items, seen = {}, {}
    local hud = LP.PlayerGui:FindFirstChild("HUD")
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

    local defaults = {
        "Plastic", "Rope", "Glue Elephant", "Cow leather", "Stopwatch",
        "Banana Leaf", "Scarf Old", "Snake leather", "Crocodile leather",
        "Microphone", "Trainer Notes"
    }
    for _, name in ipairs(defaults) do
        if not seen[name] then
            seen[name] = true
            table.insert(items, name)
        end
    end
    table.sort(items)
    return items
end

-- ===== SHOP RAID UI =====
function AutoShopInitShopRaid(ShopRaidCard, ShopRaidInfoCard)
    local ShopInfoPara = ShopRaidInfoCard:Paragraph({
        Title = "RaidPoint: ( đang load... )",
        Content = "Restock In: ( đang load... )"
    })
    local ShopItemInfo = ShopRaidInfoCard:Paragraph({
        Title = "Item: ( chưa chọn )",
        Content = "Chọn item từ dropdown"
    })

    local SelectedShopItem = nil
    local ShopItemDropdown = nil
    local LastShopItemsStr = ""

    local function RefreshShopDropdown(items)
        local str = table.concat(items, ",")
        if str == LastShopItemsStr and ShopItemDropdown then return end
        LastShopItemsStr = str
        if ShopItemDropdown then pcall(function() ShopItemDropdown:Destroy() end) end
        ShopItemDropdown = ShopRaidCard:Dropdown({
            Title = "Select Items to Purchase",
            Options = items,
            Multi = false,
            Callback = function(v) SelectedShopItem = v end
        })
    end

    ShopRaidCard:Button({
        Title = "BUY!!",
        Callback = function()
            if not SelectedShopItem then
                Utils.Notify("❌ Chưa chọn item", "Vui lòng chọn item trước!", 3)
                return
            end
            RS.Modules.NetworkFramework.NetworkEvent
                :FireServer("fire", nil, "buy_raidshop", SelectedShopItem)
            Utils.Notify("✅ Đã mua", SelectedShopItem, 3)
        end
    })

    local LastRaidPoint, LastRestock, LastShopItemInfo = "", "", ""
    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                local hud = LP.PlayerGui:FindFirstChild("HUD")
                if not hud or not hud:FindFirstChild("Main") then return end
                local shop = hud.Main:FindFirstChild("Frame_ShopRaid")
                if not shop then return end

                local rpLbl = shop:FindFirstChild("RaidPoint")
                local rsLbl = shop:FindFirstChild("Reset")
                if rpLbl and rsLbl then
                    if rpLbl.Text ~= LastRaidPoint or rsLbl.Text ~= LastRestock then
                        LastRaidPoint, LastRestock = rpLbl.Text, rsLbl.Text
                        ShopInfoPara:SetTitle(rpLbl.Text)
                        ShopInfoPara:SetContent(rsLbl.Text)
                    end
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
                        RefreshShopDropdown(items)
                    end
                    if SelectedShopItem then
                        for _, item in pairs(sf:GetChildren()) do
                            if item:IsA("Frame") then
                                local label = item:FindFirstChild("Label")
                                if label and label.Text == SelectedShopItem then
                                    local price = item:FindFirstChild("Price")
                                    local amount = item:FindFirstChild("Amount")
                                    local priceTxt = price and price.Text or "?"
                                    local amountTxt = amount and amount.Text or "?"
                                    if LastShopItemInfo ~= (priceTxt .. "|" .. amountTxt) then
                                        LastShopItemInfo = priceTxt .. "|" .. amountTxt
                                        ShopItemInfo:SetTitle("Item: " .. SelectedShopItem)
                                        ShopItemInfo:SetContent("Price: " .. priceTxt .. "\nPurchase limit: " .. amountTxt)
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)
end

-- ===== SHOP DUNGEON UI =====
function AutoShopInitShopDungeon(ShopDunCard, ShopDunInfoCard)
    local ShopDunInfoPara = ShopDunInfoCard:Paragraph({
        Title = "DungeonPoint: ( đang load... )",
        Content = "Chọn item Auto Buy ở cột trái"
    })
    local ShopDunItemInfo = ShopDunInfoCard:Paragraph({
        Title = "Item: ( chưa chọn )",
        Content = "Chọn item từ dropdown Auto Buy"
    })

    local AutoBuyDunItem = nil
    _G.AutoBuyDunRunning = false
    _G.AutoBuyDunLoaded = false
    local Dropdown, LastStr = nil, ""

    local function RefreshDropdown(items)
        local str = table.concat(items, ",")
        if str == LastStr and Dropdown then return end
        LastStr = str
        if Dropdown then pcall(function() Dropdown:Destroy() end) end
        Dropdown = ShopDunCard:Dropdown({
            Title = "Auto Buy Items",
            Options = items,
            Multi = false,
            Callback = function(v)
                AutoBuyDunItem = v
                print("[AutoBuyDun] Chọn:", v)
            end
        })
    end

    ShopDunCard:Toggle({
        Title = "Auto Buy", Value = false,
        Callback = function(v)
            if not _G.AutoBuyDunLoaded then
                _G.AutoBuyDunLoaded = true
                _G.AutoBuyDunRunning = v
                return
            end
            if v and not AutoBuyDunItem then
                Utils.Notify("❌ Chưa chọn item", "Chọn item Auto Buy trước!", 3)
                _G.AutoBuyDunRunning = false
                return
            end
            _G.AutoBuyDunRunning = v
            Utils.Notify(v and "▶️ Bật Auto Buy" or "⏹️ Tắt Auto Buy",
                AutoBuyDunItem or "N/A", 3)
        end
    })

    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                local hud = LP.PlayerGui:FindFirstChild("HUD")
                if not hud or not hud:FindFirstChild("Main") then return end
                local shop = hud.Main:FindFirstChild("Frame_ShopDungeon")
                if not shop then return end

                local pt = LP:GetAttribute("DungeonPoint")
                    or LP:GetAttribute("PointDungeon")
                    or LP:GetAttribute("DungeonOrb")
                    or 0
                ShopDunInfoPara:SetTitle("DungeonPoint: " .. tostring(pt))

                RefreshDropdown(GetAllShopDunItems())

                if AutoBuyDunItem then
                    local sf = shop:FindFirstChild("ShopScrollingFrame")
                    if sf then
                        for _, item in pairs(sf:GetChildren()) do
                            if item:IsA("Frame") then
                                local main = item:FindFirstChild("Main")
                                if main then
                                    local titleLbl = main:FindFirstChild("TitleLabel")
                                    if titleLbl and titleLbl.Text == AutoBuyDunItem then
                                        local btn = main:FindFirstChild("TextButton")
                                        local priceLbl = btn and btn:FindFirstChild("TextLabel")
                                        ShopDunItemInfo:SetTitle("Item: " .. AutoBuyDunItem)
                                        ShopDunItemInfo:SetContent("Price: " .. (priceLbl and priceLbl.Text or "?"))
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)

    -- Loop Auto Buy
    task.spawn(function()
        while task.wait(0.5) do
            if _G.AutoBuyDunRunning and AutoBuyDunItem then
                pcall(function()
                    local hud = LP.PlayerGui:FindFirstChild("HUD")
                    if not hud or not hud:FindFirstChild("Main") then return end
                    local shop = hud.Main:FindFirstChild("Frame_ShopDungeon")
                    if not shop then return end
                    local sf = shop:FindFirstChild("ShopScrollingFrame")
                    if not sf then return end
                    for _, item in pairs(sf:GetChildren()) do
                        if item:IsA("Frame") then
                            local main = item:FindFirstChild("Main")
                            if main then
                                local titleLbl = main:FindFirstChild("TitleLabel")
                                if titleLbl and titleLbl.Text == AutoBuyDunItem then
                                    RS.Modules.NetworkFramework.NetworkEvent
                                        :FireServer("fire", nil, "BuyDungeonShop", AutoBuyDunItem)
                                    print("[AutoBuyDun] Mua:", AutoBuyDunItem)
                                    task.wait(0.3)
                                    break
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)
end

return {
    InitShopRaid = AutoShopInitShopRaid,
    InitShopDungeon = AutoShopInitShopDungeon,
    GetAllShopItems = GetAllShopItems,
    GetAllShopDunItems = GetAllShopDunItems
}
