-- ============================================================
--  MarvenRiz Hub — Main Script
--  Chỉ hoạt động trong MapId: 132854526011923
-- ============================================================

local TARGET_PLACE_ID = 132854526011923

if game.PlaceId ~= TARGET_PLACE_ID then
    warn(("[MarvenRiz] Sai map. PlaceId hiện tại: %d — cần %d"):format(game.PlaceId, TARGET_PLACE_ID))
    return
end

-- ✅ Load lib: dùng readfile nếu có, fallback HttpGet
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Ui_New.lua"))()

-- ============================================================
--  TRẠNG THÁI MÀU
-- ============================================================
local START_ACCENT     = Color3.fromRGB(120, 80, 255)
local START_BACKGROUND = Color3.fromRGB(18, 18, 20)

local currentAccent     = START_ACCENT
local currentBackground = START_BACKGROUND

local function closeEnough(a, b, eps)
    eps = eps or 0.02
    return math.abs(a.R - b.R) < eps and math.abs(a.G - b.G) < eps and math.abs(a.B - b.B) < eps
end

local function findScreenGui()
    for _, root in ipairs({game:GetService("CoreGui"), game.Players.LocalPlayer.PlayerGui}) do
        for _, gui in ipairs(root:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name:find("MarvenRiz_UI_") then return gui end
        end
    end
    return nil
end

local function hueDistance(c1, c2)
    local h1, s1, v1 = c1:ToHSV()
    local h2, s2, v2 = c2:ToHSV()
    local dh = math.abs(h1 - h2)
    if dh > 0.5 then dh = 1 - dh end
    return dh + math.abs(s1 - s2) * 0.3 + math.abs(v1 - v2) * 0.3
end

local function ApplyAccent(newColor)
    local oldColor = currentAccent
    currentAccent = newColor
    local gui = findScreenGui()
    if not gui then return end
    for _, desc in ipairs(gui:GetDescendants()) do
        if desc:IsA("GuiObject") and desc.BackgroundColor3 and closeEnough(desc.BackgroundColor3, oldColor) then
            desc.BackgroundColor3 = newColor
        end
        if (desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox")) and closeEnough(desc.TextColor3, oldColor) then
            desc.TextColor3 = newColor
        end
        if desc:IsA("UIStroke") and closeEnough(desc.Color, oldColor) then desc.Color = newColor end
        if desc:IsA("UIGradient") then
            local newKeys, changed = {}, false
            for _, kp in ipairs(desc.Color.Keypoints) do
                if closeEnough(kp.Value, oldColor) then
                    table.insert(newKeys, ColorSequenceKeypoint.new(kp.Time, newColor))
                    changed = true
                else table.insert(newKeys, kp) end
            end
            if changed then desc.Color = ColorSequence.new(newKeys) end
        end
    end
end

local function ApplyBackground(newColor)
    local oldColor = currentBackground
    currentBackground = newColor
    local gui = findScreenGui()
    if not gui then return end
    for _, desc in ipairs(gui:GetDescendants()) do
        if desc:IsA("GuiObject") and desc.BackgroundColor3 and closeEnough(desc.BackgroundColor3, oldColor) then
            desc.BackgroundColor3 = newColor
        end
        if desc:IsA("UIStroke") and closeEnough(desc.Color, oldColor) then desc.Color = newColor end
    end
end

local function ApplyMenuScale(scale)
    local gui = findScreenGui()
    if not gui then return end
    for _, d in ipairs(gui:GetDescendants()) do
        if d:IsA("UIScale") and d.Parent and d.Parent.Name == "Frame" and d.Parent.Parent == gui then
            d.Scale = scale
            return
        end
    end
end

-- ============================================================
--  TẠO WINDOW
-- ============================================================
local Window = Library:CreateWindow({
    Title        = "MarvenRiz Hub",
    Subtitle     = "Test Build • Map 132854526011923",
    AccentColor  = START_ACCENT,
    Size         = UDim2.fromOffset(620, 480),
    SideBarWidth = 170,
    Map          = "TestMap_132854526011923",
    SaveFolder   = "MarvenRizSave",
})

-- ============================================================
--  TAB MAIN
-- ============================================================
local MainTab  = Window:CreateTab("Main", true)
local MainPage = MainTab:CreatePage("General")

local PlayerSection = MainPage:CreateSection("Player", "Left")
PlayerSection:Toggle({Title = "Infinite Jump", Desc = "Nhảy vô hạn khi giữ Space.", Value = false, Callback = function(state)
    getgenv().InfiniteJump = state
    if state then
        local UIS = game:GetService("UserInputService")
        getgenv().InfJumpConn = UIS.JumpRequest:Connect(function()
            if getgenv().InfiniteJump then
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChildOfClass("Humanoid") then char:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping") end
            end
        end)
    elseif getgenv().InfJumpConn then
        getgenv().InfJumpConn:Disconnect()
        getgenv().InfJumpConn = nil
    end
end})
PlayerSection:Toggle({Title = "Walk Speed Boost", Desc = "Bật/tắt test toggle.", Value = false, Callback = function(state)
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then char:FindFirstChildOfClass("Humanoid").WalkSpeed = state and 32 or 16 end
end})
PlayerSection:Slider({Title = "WalkSpeed Value", Desc = "Tốc độ đi bộ (16 – 200).", Min = 16, Max = 200, Value = 16, Callback = function(val) getgenv().CustomWalkSpeed = val end})
PlayerSection:Button({Title = "Reset Character", Desc = "Hồi sinh nhân vật.", Callback = function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then char:FindFirstChildOfClass("Humanoid").Health = 0 end
    Library:Notify({Title = "Player", Description = "Đã reset."})
end})

local TPSection = MainPage:CreateSection("Teleport", "Right")
TPSection:Dropdown({Title = "Chọn địa điểm", Desc = "Chọn vị trí dịch chuyển.", Options = {"Spawn", "Center", "Boss Room", "Shop"}, Value = "Spawn", Callback = function(sel) getgenv().SelectedTP = sel end})
TPSection:Button({Title = "Teleport Now", Desc = "Dịch chuyển tới địa điểm đã chọn.", Callback = function()
    local char = game.Players.LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = hrp.CFrame + Vector3.new(0, 50, 0) end
    Library:Notify({Title = "Teleport", Description = "Đã dịch chuyển."})
end})

local VisualSection = MainPage:CreateSection("Visual", "Left")
VisualSection:ColorPicker({Title = "ESP Color", Desc = "Màu cho ESP.", Value = "#FF3B3B", Callback = function(c) getgenv().ESPColor = c end})
VisualSection:Textbox({Title = "Player Name", Desc = "Nhập tên người chơi.", Placeholder = "Nhập tên...", Value = "", Callback = function(t) getgenv().TargetPlayerName = t end})
VisualSection:Paragraph({Title = "Hướng dẫn nhanh", Content = "Paragraph test — hiển thị thông tin mô tả."})

AppearanceSection:ColorPicker({
    Title = "Menu Background",
    Desc  = "Màu nền chính. Áp dụng ngay.",
    Value = "#121214",
    Callback = function(color) ApplyBackground(color) end,
})

-- ✅ THÊM: chọn mode icon
AppearanceSection:Dropdown({
    Title = "Menu Icon Mode",
    Desc  = "Tự do: icon nổi, kéo được. Tool: icon thành Tool trong Backpack, equip để mở.",
    Options = { "Tự do", "Tool" },
    Value = "Tự do",
    Callback = function(selected)
        Library:SetMenuIconMode(selected == "Tool" and "tool" or "free")
    end,
})

-- ============================================================
--  TAB CONFIG
-- ============================================================
local ConfigTab  = Window:CreateTab("Config", false)
local ConfigPage = ConfigTab:CreatePage("Config")

local AppearanceSection = ConfigPage:CreateSection("Menu Appearance", "Left")
AppearanceSection:ColorPicker({Title = "Menu Accent", Desc = "Màu chủ đạo. Áp dụng ngay.", Value = "#7850FF", Callback = function(color) ApplyAccent(color) end})
AppearanceSection:ColorPicker({Title = "Menu Background", Desc = "Màu nền chính. Áp dụng ngay.", Value = "#121214", Callback = function(color) ApplyBackground(color) end})
AppearanceSection:Button({Title = "🎲 Random Accent + Background", Desc = "Random cả accent và background, đảm bảo khác màu.", Callback = function()
    local newAccent, newBg
    for _ = 1, 20 do
        newAccent = Color3.fromHSV(math.random(), 0.6 + math.random() * 0.4, 0.8 + math.random() * 0.2)
        newBg     = Color3.fromHSV(math.random(), 0.05 + math.random() * 0.25, 0.05 + math.random() * 0.18)
        if hueDistance(newAccent, newBg) >= 0.35 then break end
    end
    ApplyAccent(newAccent)
    ApplyBackground(newBg)
    local elA = Window.ConfigElements["Menu Accent"];     if elA and elA.Set then elA.Set(newAccent:ToHex()) end
    local elB = Window.ConfigElements["Menu Background"]; if elB and elB.Set then elB.Set(newBg:ToHex()) end
    Library:Notify({Title = "Random Colors", Description = ("Accent: %s • BG: %s"):format(newAccent:ToHex(), newBg:ToHex()), Duration = 3})
end})

local SizeSection = ConfigPage:CreateSection("Menu Size", "Left")
SizeSection:Slider({Title = "Menu Scale", Desc = "Độ to menu (60% – 140%).", Min = 60, Max = 140, Value = 100, Callback = function(percent) ApplyMenuScale(percent / 100) end})
SizeSection:Toggle({Title = "Transparency", Desc = "Giảm độ mờ nền menu (0.2).", Value = false, Callback = function(state) Window:SetTransparency(state and 0.2 or 0) end})

local SaveSection = ConfigPage:CreateSection("Save Manager", "Right")
SaveSection:AddConfigManager(Library.SaveManager.Folder)

-- ============================================================
--  AUTO LOAD
-- ============================================================
task.wait(0.5)
local loaded = Library.SaveManager:LoadAutoloadConfig()
if loaded then
    print("[MarvenRiz] Auto Load thành công.")
else
    print("[MarvenRiz] Không có Auto Load config.")
end

task.delay(0.6, function()
    Library:Notify({Title = "MarvenRiz Hub", Description = "Đã load trên map " .. tostring(TARGET_PLACE_ID), Duration = 3})
end)

print("[MarvenRiz] UI đã khởi tạo — PlaceId:", game.PlaceId)
