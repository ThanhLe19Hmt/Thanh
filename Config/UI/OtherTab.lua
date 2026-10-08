--[[
    UI/OtherTab.lua
    Tab "Other" - Sell, Status, Random Chest, Guarantee, Craft Table
]]

local OtherTab = {}
local Globals  = _G.__Globals or Globals

function OtherTab:Init(Window)
    local Library = Globals.Library

    -- Build Sell items
    local SellItems = {}
    for name in pairs(Globals.Economy) do
        table.insert(SellItems, name)
    end
    table.sort(SellItems)

    -- Build Guarantee point lists
    local Poitem, PoiteMoon = {}, {}
    for item, price in pairs(Globals.PointItemM) do
        table.insert(Poitem, {Name = item, Price = price})
    end
    table.sort(Poitem, function(a, b) return a.Price < b.Price end)
    for i, d in ipairs(Poitem) do
        Poitem[i] = d.Name .. " / " .. d.Price .. " Point"
    end

    for item, price in pairs(Globals.PointItemMoon) do
        table.insert(PoiteMoon, {Name = item, Price = price})
    end
    table.sort(PoiteMoon, function(a, b) return a.Price < b.Price end)
    for i, d in ipairs(PoiteMoon) do
        PoiteMoon[i] = d.Name .. " / " .. d.Price .. " Point"
    end

    local Tab3 = Window:CreateTab("Other", false, false)
    local SItem    = Tab3:CreatePage("Sell Item / Status")
    local RandomM  = Tab3:CreatePage("Random Chest")
    local CraftPg  = Tab3:CreatePage("Craft Table")

    local SellCard        = SItem:CreateSection("💰 Auto Sell", "Left")
    local StatusCard      = SItem:CreateSection("📊 Status", "Right")
    local DiamondChest    = RandomM:CreateSection("💎 Diamond Chest", "Right")
    local GuaranteeDiamond= RandomM:CreateSection("🎖️ Guarantee Gem Point", "Right")
    local MoonChest       = RandomM:CreateSection("🌙 Moon Chest", "Left")
    local GuaranteeMoon   = RandomM:CreateSection("☄️ Guarantee Moon Point", "Left")

    -- ===== SELL =====
    SellCard:Dropdown({
        Title = "Select Sell Item",
        Options = SellItems,
        Multi = true,
        Callback = function(v) _G.Select_SellItem = v end
    })
    SellCard:Toggle({
        Title = "Auto Sell", Value = false,
        Callback = function(v) _G.Auto_SellItem = v end
    })

    -- ===== STATUS =====
    StatusCard:Textbox({
        Title = "Status Amount",
        Placeholder = "1000",
        Value = "1000",
        Callback = function(v) _G.Amount = tonumber(v) or 1000 end
    })
    for _, k in ipairs({"Melee", "Defense", "Sword", "Power"}) do
        StatusCard:Toggle({
            Title = "Auto Up " .. k,
            Value = false,
            Callback = function(v) _G["Auto" .. k] = v end
        })
    end

    -- ===== RANDOM CHEST =====
    DiamondChest:Dropdown({
        Title = "Select Random Diamond Chest",
        Options = Globals.RandomChestValue,
        Multi = false,
        Callback = function(v) _G.Select_Random = v end
    })
    DiamondChest:Toggle({
        Title = "Auto Random Diamond Chest", Value = false,
        Callback = function(v) _G.Auto_RandomChest = v end
    })

    MoonChest:Dropdown({
        Title = "Select Random Moon Chest",
        Options = Globals.RandomChestValue,
        Multi = false,
        Callback = function(v) _G.Select_Random_Moon = v end
    })
    MoonChest:Toggle({
        Title = "Auto Random Moon Chest", Value = false,
        Callback = function(v) _G.Auto_RandomChest_Moon = v end
    })

    -- ===== GUARANTEE =====
    GuaranteeDiamond:Dropdown({
        Title = "Select Guarantee Diamond Point",
        Options = Poitem,
        Multi = false,
        Callback = function(v) _G.Select_Guarantee = v:match("^(.-) /") end
    })
    GuaranteeDiamond:Button({
        Title = "Buy Guarantee Diamond Point",
        Callback = function()
            local point = tonumber(Globals.LocalPlayer:GetAttribute("PointItem")) or 0
            local price = Globals.PointItemM[_G.Select_Guarantee] or 0
            if _G.Select_Guarantee and point >= price then
                Globals.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
                    :FireServer("fire", nil, "BuyGaranteeRandomItem", _G.Select_Guarantee)
            end
        end
    })
    GuaranteeDiamond:Toggle({
        Title = "Auto Buy Guarantee Diamond Point", Value = false,
        Callback = function(v) _G.Auto_Guarantee = v end
    })

    GuaranteeMoon:Dropdown({
        Title = "Select Guarantee Moon Point",
        Options = PoiteMoon,
        Multi = false,
        Callback = function(v) _G.Select_Guarantee_Moon = v:match("^(.-) /") end
    })
    GuaranteeMoon:Button({
        Title = "Buy Guarantee Moon Point",
        Callback = function()
            local point = tonumber(Globals.LocalPlayer:GetAttribute("MoonPoint")) or 0
            local price = Globals.PointItemMoon[_G.Select_Guarantee_Moon] or 0
            if _G.Select_Guarantee_Moon and point >= price then
                Globals.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
                    :FireServer("fire", nil, "BuyGaranteeEventMoon", _G.Select_Guarantee_Moon)
            end
        end
    })
    GuaranteeMoon:Toggle({
        Title = "Auto Buy Guarantee Moon Point", Value = false,
        Callback = function(v) _G.Auto_Guarantee_Moon = v end
    })

    OtherTab.CraftPage = CraftPg
end

return OtherTab
