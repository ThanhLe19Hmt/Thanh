-- ============================================================
-- SEA 2 SCRIPT (TEST)
-- ============================================================
print("[Sea 2] ▶️ Bắt đầu load script Sea 2...")

-- ===== LOAD UI LIBRARY =====
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Ui_New.lua"
))()

local Window = Library:CreateWindow({
    Title = "MarvenRiz Hub",
    Subtitle = "🌊 SEA 2 — Test Mode",
    Size = UDim2.fromOffset(500, 370),
    AccentColor = Color3.fromRGB(220, 100, 50),
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
local Tab1 = Window:CreateTab("Sea 2 Test", true, false)
local Page1 = Tab1:CreatePage("Test")

local Card1 = Page1:CreateSection("🌊 Sea 2 Info", "Left")

local Para1 = Card1:Paragraph({
    Title = "Sea hiện tại: Second",
    Content = "Script này chạy khi ở Sea 2\n\nNếu bạn thấy thông báo này → LOADER HOẠT ĐỘNG ✅"
})

Card1:Button({
    Title = "🧪 Test Notify Sea 2",
    Callback = function()
        _G.SeaNotify("✅ Sea 2 Test OK", "Bạn đang ở Sea 2, script Sea 2 đang chạy!", 5)
    end
})

-- ===== TAB TELEPORT SEA 2 =====
local Tab2 = Window:CreateTab("Teleport", false, false)
local TPPage = Tab2:CreatePage("Teleport Sea 2")

local IslandCard = TPPage:CreateSection("🏝️ Đảo Sea 2", "Left")
local SeaCard = TPPage:CreateSection("🌊 Sea Travel", "Right")
local InfoCard = TPPage:CreateSection("📊 Info", "Right")

local InfoPara = InfoCard:Paragraph({
    Title = "Sea 2 Info",
    Content = "Đang load..."
})

local SeaInfoPara = SeaCard:Paragraph({
    Title = "Sea Travel",
    Content = "Đang load..."
})

-- Quét đảo Sea 2
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

InfoPara:SetTitle("Đảo Sea 2: " .. #IslandList)
InfoPara:SetContent("Danh sách đảo đã load OK ✅")

IslandCard:Dropdown({
    Title = "🏝️ Chọn Đảo Sea 2",
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

-- ===== NÚT VỀ SEA 1 =====
SeaCard:Button({
    Title = "🏠 Về Sea 1 (FirstSea)",
    Callback = function()
        local firstSea = workspace:FindFirstChild("FirstSea")
        if not firstSea then
            _G.SeaNotify("❌ Không tìm thấy FirstSea", "Có thể đang ở Sea 1 rồi", 3)
            return
        end
        local char = game.Players.LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local npcHrp = firstSea:FindFirstChild("HumanoidRootPart") or firstSea:FindFirstChildWhichIsA("BasePart")
        if hrp and npcHrp then
            hrp.CFrame = CFrame.new(npcHrp.Position + Vector3.new(0, 5, 0))
            _G.SeaNotify("🏠 Đã tới NPC về Sea 1", "Chờ prompt kích hoạt...", 5)
            task.wait(0.5)
            local prompt = firstSea:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                pcall(function()
                    fireproximityprompt(prompt)
                end)
            end
        end
    end
})

-- ===== UPDATE INFO SEA =====
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            local seaAttr = game.Players.LocalPlayer:GetAttribute("CurrentSea") or "?"
            SeaInfoPara:SetTitle("🌊 " .. tostring(seaAttr))
            SeaInfoPara:SetContent(
                "NPC Sea 2: " .. (workspace:FindFirstChild("2SeaSoon") and "✅" or "❌") ..
                "\nNPC về Sea 1: " .. (workspace:FindFirstChild("FirstSea") and "✅" or "❌") ..
                "\nSố đảo: " .. #IslandList
            )
        end)
    end
end)

print("[Sea 2] ✅ Load thành công!")
