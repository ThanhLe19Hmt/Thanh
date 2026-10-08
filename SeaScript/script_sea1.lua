-- ============================================================
-- SEA 1 SCRIPT (TEST)
-- ============================================================
print("[Sea 1] ▶️ Bắt đầu load script Sea 1...")

-- ===== LOAD UI LIBRARY =====
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Ui_New.lua"
))()

local Window = Library:CreateWindow({
    Title = "MarvenRiz Hub",
    Subtitle = "🌊 SEA 1 — Test Mode",
    Size = UDim2.fromOffset(500, 370),
    AccentColor = Color3.fromRGB(50, 150, 255),
    SideBarWidth = 120,
    Logo = "rbxassetid://87526284179554",
    LogoSize = 32,
    SphereText = false,
    SphereImage = "rbxassetid://87526284179554",
    SphereIconSize = 38,
    Map = "RockFruit"
})

-- ===== NOTIFY GLOBAL =====
function _G.SeaNotify(title, desc, duration)
    pcall(function()
        if Library and Library.Notify then
            Library:Notify({
                Title = title or "",
                Description = desc or "",
                Duration = duration or 4
            })
        end
    end)
end

-- ===== TAB TEST =====
local Tab1 = Window:CreateTab("Sea 1 Test", true, false)
local Page1 = Tab1:CreatePage("Test")

local Card1 = Page1:CreateSection("🌊 Sea 1 Info", "Left")

local Para1 = Card1:Paragraph({
    Title = "Sea hiện tại: First",
    Content = "Script này chạy khi ở Sea 1\n\nNếu bạn thấy thông báo này → LOADER HOẠT ĐỘNG ✅"
})

Card1:Button({
    Title = "🧪 Test Notify Sea 1",
    Callback = function()
        _G.SeaNotify("✅ Sea 1 Test OK", "Bạn đang ở Sea 1, script Sea 1 đang chạy!", 5)
    end
})

-- ===== TAB TELEPORT (test đơn giản) =====
local Tab2 = Window:CreateTab("Teleport", false, false)
local TPPage = Tab2:CreatePage("Teleport Sea 1")

local IslandCard = TPPage:CreateSection("🏝️ Đảo Sea 1", "Left")
local InfoCard = TPPage:CreateSection("📊 Info", "Right")

local InfoPara = InfoCard:Paragraph({
    Title = "Sea 1 Info",
    Content = "Đang load..."
})

-- Quét đảo Sea 1
local IslandCache = {}
local IslandList = {}
local SelectedIsland = nil

local islandFolder = workspace:FindFirstChild("island")
if islandFolder then
    for _, obj in ipairs(islandFolder:GetChildren()) do
        if obj:IsA("Model") then
            local hrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
            IslandCache[obj.Name] = hrp and hrp.Position or Vector3.zero
            table.insert(IslandList, obj.Name)
        end
    end
end
table.sort(IslandList)

InfoPara:SetTitle("Đảo Sea 1: " .. #IslandList)
InfoPara:SetContent("Danh sách đảo đã load OK ✅")

IslandCard:Dropdown({
    Title = "🏝️ Chọn Đảo Sea 1",
    Options = IslandList,
    Multi = false,
    Callback = function(Value)
        SelectedIsland = Value
        local pos = IslandCache[Value]
        if pos then
            InfoPara:SetTitle("Đã chọn: " .. Value)
            InfoPara:SetContent(string.format("📌 %.0f, %.0f, %.0f", pos.X, pos.Y, pos.Z))
        end
    end
})

IslandCard:Button({
    Title = "✈️ Dịch Chuyển",
    Callback = function()
        if not SelectedIsland then
            _G.SeaNotify("❌ Chưa chọn đảo", "Chọn đảo trước!", 3)
            return
        end
        local pos = IslandCache[SelectedIsland]
        local char = game.Players.LocalPlayer.Character
        if pos and char then
            char:PivotTo(CFrame.new(pos + Vector3.new(0, 5, 0)))
            _G.SeaNotify("✈️ Đã TP", SelectedIsland, 3)
        end
    end
})

print("[Sea 1] ✅ Load thành công!")
