--[[
    Features/AutoCraftTable.lua
    Craft Table UI + Auto Craft + Auto Claim Guarantee
]]

local Globals = _G.__Globals
assert(Globals, "[Module] _G.__Globals chưa được set! Load Main.lua trước.")
local Utils   = Globals.Utils
local Inventory = Globals.Inventory
local RS = Globals.ReplicatedStorage
local LP = Globals.LocalPlayer

return function(CraftTablePage)
    local CraftCard     = CraftTablePage:CreateSection("🔨 Craft Table", "Left")
    local CraftInfoCard = CraftTablePage:CreateSection("📋 Craft Info", "Right")

    local CraftInfoPara = CraftInfoCard:Paragraph({
        Title = "Items: ( chưa chọn )",
        Content = "Consumables: ---\nCurrently Available: ---\nCrafted Item: ---"
    })

    _G.SelectedCraftItem = nil
    local CraftDropdown, LastStr = nil, ""

    local function GetAllCraftItems()
        local items = {}
        for name, data in pairs(Globals.CraftingTable) do
            if data.need then table.insert(items, name) end
        end
        table.sort(items)
        return items
    end

    local function UpdateCraftInfo(itemName)
        if not itemName then return end
        local data = Globals.CraftingTable[itemName]
        local consumText, availText = "", ""
        if data and data.need then
            for item, need in pairs(data.need) do
                local have = Inventory.GetAmount(item)
                consumText = consumText .. "\n  " .. item .. " x" .. need
                availText = availText .. "\n  " .. item .. " " .. have
            end
        end
        local crafted = "0/2"
        local hud = LP.PlayerGui:FindFirstChild("HUD")
        if hud and hud:FindFirstChild("Main") then
            local guar = hud.Main:FindFirstChild("Frame_Guarantee")
            if guar then
                local sf = guar:FindFirstChild("ScrollingFrame")
                if sf then
                    local itemFrame = sf:FindFirstChild(itemName)
                    if itemFrame then
                        local main = itemFrame:FindFirstChild("Main")
                        if main then
                            local amtLbl = main:FindFirstChild("AmountLabel")
                            if amtLbl then crafted = amtLbl.Text end
                        end
                    end
                end
            end
        end
        CraftInfoPara:SetTitle("Items: " .. itemName)
        CraftInfoPara:SetContent(
            "Consumables: " .. (consumText ~= "" and consumText or " ---") ..
            "\nCurrently Available: " .. (availText ~= "" and availText or " ---") ..
            "\nCrafted Item: " .. crafted
        )
    end

    local function RefreshDropdown(items)
        local str = table.concat(items, ",")
        if str == LastStr and CraftDropdown then return end
        LastStr = str
        if CraftDropdown then
            pcall(function() CraftDropdown:Destroy() end)
            task.wait(0.05)
        end
        CraftDropdown = CraftCard:Dropdown({
            Title = "Chọn Items để chế tạo",
            Options = items,
            Multi = false,
            Callback = function(v)
                _G.SelectedCraftItem = v
                print("[CraftTable] Đã chọn:", v)
                UpdateCraftInfo(v)
            end
        })
    end

    RefreshDropdown(GetAllCraftItems())

    _G.AutoCraftRunning = false
    _G.AutoCraftLoaded = false

    CraftCard:Toggle({
        Title = "Auto Chế Tạo", Value = false,
        Callback = function(v)
            if not _G.AutoCraftLoaded then
                _G.AutoCraftLoaded = true
                _G.AutoCraftRunning = v
                return
            end
            if v and not _G.SelectedCraftItem then
                Utils.Notify("❌ Chưa chọn item", "Chọn item trước!", 3)
                _G.AutoCraftRunning = false
                return
            end
            _G.AutoCraftRunning = v
            Utils.Notify(v and "▶️ Bật Auto Craft" or "⏹️ Tắt Auto Craft",
                _G.SelectedCraftItem or "N/A", 3)
        end
    })

    -- Loop Auto Craft
    task.spawn(function()
        while task.wait(0.5) do
            if _G.AutoCraftRunning and _G.SelectedCraftItem then
                pcall(function()
                    local data = Globals.CraftingTable[_G.SelectedCraftItem]
                    if not data or not data.need then return end
                    local canCraft = true
                    for item, need in pairs(data.need) do
                        if Inventory.GetAmount(item) < need then
                            canCraft = false
                            break
                        end
                    end
                    if canCraft then
                        RS.Modules.NetworkFramework.NetworkEvent
                            :FireServer("fire", nil, "CraftTable", _G.SelectedCraftItem, "Craft")
                        print("[AutoCraft] Craft:", _G.SelectedCraftItem)
                        task.wait(0.5)
                    end
                end)
            end
        end
    end)

    -- Auto Claim Guarantee
    _G.AutoClaimGuarantee = false
    CraftInfoCard:Toggle({
        Title = "Auto Claim Guarantee", Value = false,
        Callback = function(v)
            _G.AutoClaimGuarantee = v
            print("[AutoClaim] Running:", v)
        end
    })

    task.spawn(function()
        while task.wait(1) do
            if _G.AutoClaimGuarantee and _G.SelectedCraftItem then
                pcall(function()
                    local hud = LP.PlayerGui:FindFirstChild("HUD")
                    if not hud or not hud:FindFirstChild("Main") then return end
                    local guar = hud.Main:FindFirstChild("Frame_Guarantee")
                    if not guar then return end
                    local sf = guar:FindFirstChild("ScrollingFrame")
                    if not sf then return end
                    local itemFrame = sf:FindFirstChild(_G.SelectedCraftItem)
                    if itemFrame then
                        local main = itemFrame:FindFirstChild("Main")
                        if main then
                            local amtLbl = main:FindFirstChild("AmountLabel")
                            if amtLbl then
                                local cur = tonumber(amtLbl.Text:match("^(%d+)"))
                                local max = tonumber(amtLbl.Text:match("/(%d+)"))
                                if cur and max and cur >= max then
                                    RS.Modules.NetworkFramework.NetworkEvent
                                        :FireServer("fire", nil, "CraftTable", _G.SelectedCraftItem, "Guarantee")
                                    print("[AutoClaim] Claim:", _G.SelectedCraftItem, amtLbl.Text)
                                    task.wait(1)
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Loop update craft info
    task.spawn(function()
        local lastInfo = ""
        while task.wait(0.5) do
            pcall(function()
                if not _G.SelectedCraftItem then return end
                local data = Globals.CraftingTable[_G.SelectedCraftItem]
                if not data or not data.need then return end
                local key = _G.SelectedCraftItem
                for item in pairs(data.need) do
                    key = key .. "|" .. item .. ":" .. Inventory.GetAmount(item)
                end
                local hud = LP.PlayerGui:FindFirstChild("HUD")
                if hud and hud:FindFirstChild("Main") then
                    local guar = hud.Main:FindFirstChild("Frame_Guarantee")
                    if guar then
                        local sf = guar:FindFirstChild("ScrollingFrame")
                        if sf then
                            local itemFrame = sf:FindFirstChild(_G.SelectedCraftItem)
                            if itemFrame then
                                local main = itemFrame:FindFirstChild("Main")
                                if main then
                                    local amtLbl = main:FindFirstChild("AmountLabel")
                                    if amtLbl then key = key .. "|G:" .. amtLbl.Text end
                                end
                            end
                        end
                    end
                end
                if key ~= lastInfo then
                    lastInfo = key
                    UpdateCraftInfo(_G.SelectedCraftItem)
                end
            end)
        end
    end)
end
