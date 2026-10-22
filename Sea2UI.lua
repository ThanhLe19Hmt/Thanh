-- ============================================================
--  MarvenRiz UI Library — Final Clean Build
--  Bao gồm: Loading bar, Auto Load qua Star, Keybind toggle,
--  Menu Icon Mode (Điện thoại / PC), Scroll fix, Màu menu
-- ============================================================

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local Players          = game:GetService("Players")

local Library = { WhitelistedUsers = {} }

local _isfolder   = isfolder   or function() return true end
local _makefolder = makefolder or function() end
local _writefile  = writefile  or function() warn("writefile not supported.") end
local _readfile   = readfile   or function() return "{}" end
local _listfiles  = listfiles  or function() return {} end
local _delfile    = delfile    or function() warn("delfile not supported.") end

-- ============================================================
--  HELPERS
-- ============================================================
local function SafeCopyToClipboard(text)
    if setclipboard then setclipboard(text)
    elseif toclipboard then toclipboard(text)
    else warn("Clipboard not supported.") end
end

local function Create(className, properties)
    local instance = Instance.new(className)
    if className == "TextBox" then instance.Text = "" end
    for k, v in pairs(properties or {}) do instance[k] = v end
    if (className == "TextLabel" or className == "TextButton" or className == "TextBox") then
        if properties.TextSize and properties.RichText ~= true then
            instance.TextScaled = true
            local c = Instance.new("UITextSizeConstraint")
            c.MaxTextSize = properties.TextSize
            c.MinTextSize = 6
            c.Parent = instance
        end
    end
    return instance
end

local function IsAutoloadFile(filepath)
    if type(filepath) ~= "string" then return false end
    return filepath:lower():sub(-13) == "autoload.json"
end

local function BuildSearchIndex(card)
    local parts = {}
    for _, desc in ipairs(card:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
            if desc.Text and desc.Text ~= "" then table.insert(parts, desc.Text:lower()) end
        end
    end
    return table.concat(parts, " ")
end

local function Tween(instance, properties, duration)
    duration = duration or 0.25
    local ti = TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local t = TweenService:Create(instance, ti, properties)
    t:Play()
    return t
end

local function AddBounce(button, scaleFactor)
    scaleFactor = scaleFactor or 0.96
    local scaleObj = button:FindFirstChild("UIScale") or Create("UIScale", {Parent = button, Scale = 1})
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Tween(scaleObj, {Scale = scaleFactor}, 0.15)
        end
    end)
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Tween(scaleObj, {Scale = 1}, 0.15)
        end
    end)
    button.MouseLeave:Connect(function() Tween(scaleObj, {Scale = 1}, 0.15) end)
end

local function MakeDraggable(topbar, object)
    topbar.Active = true
    object.Active = true
    local dragging, dragInput, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = object.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Tween(object, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, 0.08)
        end
    end)
end

local AccentColor     = Color3.fromRGB(40, 40, 40)
local BackgroundColor = Color3.fromRGB(18, 18, 20)
local CardColor       = Color3.fromRGB(24, 24, 27)
local HoverColor      = Color3.fromRGB(35, 35, 40)
local TextColor       = Color3.fromRGB(240, 240, 240)
local SubTextColor    = Color3.fromRGB(150, 150, 150)

local GlobalNotifContainer

function Library:Notify(options)
    if not GlobalNotifContainer then return end
    local title    = options.Title or "Notification"
    local desc     = options.Description or "Information updated."
    local duration = options.Duration or 3

    local Notif = Create("Frame", {Parent = GlobalNotifContainer, BackgroundColor3 = Color3.fromRGB(20, 20, 22), Size = UDim2.new(1, 0, 0, 65), BackgroundTransparency = 1, ZIndex = 201, ClipsDescendants = true})
    Create("UICorner", {Parent = Notif, CornerRadius = UDim.new(0, 8)})
    local Stroke = Create("UIStroke", {Parent = Notif, Color = Color3.fromRGB(40, 40, 40), Thickness = 1.5, Transparency = 1})
    local TitleText = Create("TextLabel", {Parent = Notif, Text = title, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TextColor, BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 15), Size = UDim2.new(1, -30, 0, 15), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, ZIndex = 202})
    local DescText  = Create("TextLabel", {Parent = Notif, Text = desc, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 32), Size = UDim2.new(1, -30, 0, 15), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, ZIndex = 202})

    Tween(Notif, {BackgroundTransparency = 0}, 0.3)
    Tween(Stroke, {Transparency = 0}, 0.3)
    Tween(TitleText, {TextTransparency = 0}, 0.3)
    Tween(DescText, {TextTransparency = 0}, 0.3)

    task.delay(duration, function()
        Tween(Notif, {BackgroundTransparency = 1}, 0.4)
        Tween(Stroke, {Transparency = 1}, 0.4)
        Tween(TitleText, {TextTransparency = 1}, 0.4)
        Tween(DescText, {TextTransparency = 1}, 0.4)
        task.wait(0.4)
        Notif:Destroy()
    end)
end

-- ============================================================
--  SAVE MANAGER
-- ============================================================
Library.SaveManager = { Folder = "MarvenRizSave", BaseFolder = "MarvenRizSave", Window = nil }
local SaveManager = Library.SaveManager

local function ResolveMapKey(mapOption)
    if mapOption == nil then return nil end
    local names = {}
    if type(mapOption) == "table" then
        for _, v in ipairs(mapOption) do table.insert(names, tostring(v)) end
    else
        table.insert(names, tostring(mapOption))
    end
    if #names == 0 then return nil end
    table.sort(names)
    return table.concat(names, "_")
end

function SaveManager:SetFolder(folder)
    if folder and folder ~= "" then self.Folder = folder end
    local built = ""
    for segment in self.Folder:gmatch("[^/\\]+") do
        built = (built == "") and segment or (built .. "/" .. segment)
        if not _isfolder(built) then _makefolder(built) end
    end
end

function SaveManager:SetMap(mapOption, baseFolder)
    if baseFolder and baseFolder ~= "" then self.BaseFolder = baseFolder end
    local mapKey = ResolveMapKey(mapOption)
    self:SetFolder(mapKey and (self.BaseFolder .. "/" .. mapKey) or self.BaseFolder)
end

function SaveManager:GetAutoloadData()
    local ok, raw = pcall(function() return _readfile(self.Folder .. "/autoload.json") end)
    if ok and raw and raw ~= "" then
        local okDecode, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if okDecode and type(data) == "table" then return data end
    end
    return {Enabled = false, Path = nil}
end

function SaveManager:SetAutoloadData(data)
    if not _isfolder(self.Folder) then _makefolder(self.Folder) end
    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if ok then _writefile(self.Folder .. "/autoload.json", encoded) end
end

function SaveManager:BuildConfigTab(tab, folderName)
    if not tab or not tab.CreatePage then
        warn("SaveManager:BuildConfigTab expects a Tab object")
        return
    end
    if folderName and folderName ~= "" then
        self:SetFolder(folderName)
    end

    local ConfigPage = tab:CreatePage("Config")
    local SaveSection = ConfigPage:CreateSection("💾 Save Manager", "Right")
    SaveSection:AddConfigManager(self.Folder)
end

function SaveManager:LoadAutoloadConfig()
    if not self.Window then return false end
    local candidates = { self.Folder, self.BaseFolder }
    for _, folder in ipairs(candidates) do
        if folder and _isfolder(folder) then
            local path = folder .. "/autoload.json"
            local ok, raw = pcall(function() return _readfile(path) end)
            if ok and raw and raw ~= "" then
                local okDecode, data = pcall(function() return HttpService:JSONDecode(raw) end)
                if okDecode and type(data) == "table" and data.Enabled and data.Path then
                    local fileOk, fileRaw = pcall(function() return _readfile(data.Path) end)
                    local realPath = data.Path
                    if not fileOk or not fileRaw or fileRaw == "" then
                        local fname = data.Path:match("([^/\\]+)$")
                        local altPath = fname and (folder .. "/" .. fname) or nil
                        if altPath then
                            local altOk, altRaw = pcall(function() return _readfile(altPath) end)
                            if altOk and altRaw and altRaw ~= "" then realPath = altPath end
                        end
                    end
                    local finalOk, finalRaw = pcall(function() return _readfile(realPath) end)
                    if not finalOk or not finalRaw or finalRaw == "" then
                        data.Enabled = false
                        data.Path = nil
                        local okEnc, enc = pcall(function() return HttpService:JSONEncode(data) end)
                        if okEnc then _writefile(path, enc) end
                        continue
                    end
                    local okF, fdata = pcall(function() return HttpService:JSONDecode(finalRaw) end)
                    if okF and type(fdata) == "table" then
                        for k, v in pairs(fdata) do
                            if self.Window.ConfigElements[k] and self.Window.ConfigElements[k].Set then
                                pcall(function() self.Window.ConfigElements[k].Set(v, true) end)
                            end
                        end
                        Library:Notify({Title = "Autoload", Description = "Configuration loaded automatically.", Duration = 3})
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- ============================================================
--  CREATE WINDOW
-- ============================================================
function Library:CreateWindow(options)
    local hubName       = "MarvenRiz Ui Lib"
    local subText       = "Made By Zens"
    local subColor      = AccentColor
    local topbarLogo    = nil
    local logoSize      = 32
    local windowSize    = UDim2.fromOffset(580, 460)
    local sideBarWidth  = 160

    local SPHERE_ICON   = "rbxassetid://87526284179554"
    local SPHERE_SIZE   = 56
    local MenuIconMode  = "phone"   -- "phone" | "pc"
	local CurrentScale  = 1
    local IsAnimating   = false   -- ✅ chặn spam
    local LastToggle    = 0       -- ✅ debounce

    -- ✅ Keybind state (KHÔNG có RebindMenuKey cũ)
    local MenuKeybind      = Enum.KeyCode.T
    local MenuKeybindConn  = nil
    local KeybindListening = false
    local KeybindCaptureBtn = nil

    if type(options) == "table" then
        hubName = options.Title or hubName
        subText = options.Subtitle or subText
        if options.AccentColor ~= nil then
            if typeof(options.AccentColor) == "Color3" then AccentColor = options.AccentColor
            elseif type(options.AccentColor) == "string" then
                local okHex, cHex = pcall(function() return Color3.fromHex(options.AccentColor) end)
                if okHex then AccentColor = cHex end
            end
        end
        subColor      = options.SubtitleColor or AccentColor
        topbarLogo    = options.Logo
        logoSize      = options.LogoSize or 32
        windowSize    = options.Size or windowSize
        sideBarWidth  = options.SideBarWidth or sideBarWidth
        if options.Map ~= nil or options.MapId ~= nil then
            Library.SaveManager:SetMap(options.Map or options.MapId, options.SaveFolder)
        end
    elseif type(options) == "string" then
        hubName = options
    end

    local uniqueID = HttpService:GenerateGUID(false)
    local ScreenGui = Create("ScreenGui", {
        Name = "MarvenRiz_UI_" .. uniqueID,
        Parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui,
        ResetOnSpawn = false,
        IgnoreGuiInset = true
    })

    local NotifContainer = Create("Frame", {
        Parent = ScreenGui, BackgroundTransparency = 1,
        Size = UDim2.new(0, 320, 1, -20), Position = UDim2.new(1, -340, 0, 10),
        ZIndex = 200, Active = false
    })
    Create("UIListLayout", {Parent = NotifContainer, VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12)})
    GlobalNotifContainer = NotifContainer

    -- ============================================================
    --  INFO OVERLAY
    -- ============================================================
    local InfoOverlay = Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Color3.fromRGB(5, 5, 8), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 150, Visible = false, Active = true})
    local InfoCard = Create("Frame", {Parent = InfoOverlay, BackgroundColor3 = Color3.fromRGB(16, 16, 20), Size = UDim2.new(0, 360, 0, 280), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 151, BackgroundTransparency = 1, ClipsDescendants = true})
    Create("UICorner", {Parent = InfoCard, CornerRadius = UDim.new(0, 8)})
    Create("UIStroke", {Parent = InfoCard, Color = AccentColor, Thickness = 1.5, Transparency = 1})
    local InfoScale = Create("UIScale", {Parent = InfoCard, Scale = 0})
    local InfoHeader = Create("Frame", {Parent = InfoCard, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), ZIndex = 152})
    local InfoTitle = Create("TextLabel", {Parent = InfoHeader, Text = "Feature Info", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = TextColor, BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(1, -60, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, ZIndex = 152})
    local InfoCloseBtn = Create("TextButton", {Parent = InfoHeader, Text = "X", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 40, 1, 0), Position = UDim2.new(1, -40, 0, 0), ZIndex = 152, TextTransparency = 1})
    AddBounce(InfoCloseBtn)
    local InfoScroll = Create("ScrollingFrame", {Parent = InfoCard, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 1, -60), Position = UDim2.new(0, 20, 0, 50), CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 2, ScrollBarImageColor3 = AccentColor, BorderSizePixel = 0, ZIndex = 152, AutomaticCanvasSize = Enum.AutomaticSize.Y})
    local InfoLayout = Create("UIListLayout", {Parent = InfoScroll, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})
    local InfoDesc = Create("TextLabel", {Parent = InfoScroll, Text = "", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 152, TextTransparency = 1})
    local InfoExampleBox = Create("Frame", {Parent = InfoScroll, BackgroundColor3 = Color3.fromRGB(10, 10, 12), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 152})
    Create("UICorner", {Parent = InfoExampleBox, CornerRadius = UDim.new(0, 6)})
    Create("UIStroke", {Parent = InfoExampleBox, Color = Color3.fromRGB(40, 40, 45), Thickness = 1})
    local InfoExampleText = Create("TextLabel", {Parent = InfoExampleBox, Text = "", Font = Enum.Font.Code, TextSize = 12, TextColor3 = AccentColor, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 0), Position = UDim2.new(0, 10, 0, 10), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 152, TextTransparency = 1})
    Create("UIPadding", {Parent = InfoExampleBox, PaddingBottom = UDim.new(0, 10)})

    local function OpenInfoWindow(data)
        InfoTitle.Text = data.Title or "Information"
        InfoDesc.Text = data.Description or "No description."
        if data.Example then InfoExampleText.Text = data.Example InfoExampleBox.Visible = true
        else InfoExampleBox.Visible = false end
        InfoOverlay.Visible = true
        Tween(InfoOverlay, {BackgroundTransparency = 0.4}, 0.3)
        Tween(InfoCard, {BackgroundTransparency = 0}, 0.3)
        Tween(InfoCard:FindFirstChild("UIStroke"), {Transparency = 0.3}, 0.3)
        Tween(InfoScale, {Scale = 1}, 0.3)
        Tween(InfoTitle, {TextTransparency = 0}, 0.3)
        Tween(InfoCloseBtn, {TextTransparency = 0}, 0.3)
        Tween(InfoDesc, {TextTransparency = 0}, 0.3)
        if data.Example then Tween(InfoExampleText, {TextTransparency = 0}, 0.3) end
    end

    InfoCloseBtn.MouseButton1Click:Connect(function()
        Tween(InfoOverlay, {BackgroundTransparency = 1}, 0.3)
        Tween(InfoCard, {BackgroundTransparency = 1}, 0.3)
        Tween(InfoCard:FindFirstChild("UIStroke"), {Transparency = 1}, 0.3)
        Tween(InfoScale, {Scale = 0}, 0.3)
        Tween(InfoTitle, {TextTransparency = 1}, 0.3)
        Tween(InfoCloseBtn, {TextTransparency = 1}, 0.3)
        Tween(InfoDesc, {TextTransparency = 1}, 0.3)
        if InfoExampleBox.Visible then Tween(InfoExampleText, {TextTransparency = 1}, 0.3) end
        task.wait(0.3)
        InfoOverlay.Visible = false
    end)

    local function AddInfoIcon(parent, pos, data)
        if not data then return end
        local Btn = Create("TextButton", {Parent = parent, Text = "?", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = SubTextColor, BackgroundColor3 = Color3.fromRGB(35, 35, 40), Size = UDim2.new(0, 16, 0, 16), Position = pos, AutoButtonColor = false, ZIndex = 5})
        Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(1, 0)})
        AddBounce(Btn)
        Btn.MouseEnter:Connect(function() Tween(Btn, {TextColor3 = TextColor, BackgroundColor3 = AccentColor}, 0.2) end)
        Btn.MouseLeave:Connect(function() Tween(Btn, {TextColor3 = SubTextColor, BackgroundColor3 = Color3.fromRGB(35, 35, 40)}, 0.2) end)
        Btn.MouseButton1Click:Connect(function() OpenInfoWindow(data) end)
    end

    -- ============================================================
    --  MAIN FRAME
    -- ============================================================
    local MainFrame = Create("Frame", {Parent = ScreenGui, BackgroundColor3 = BackgroundColor, Size = windowSize, Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ClipsDescendants = true, BackgroundTransparency = 1, Active = true})
    local MainScale = Create("UIScale", {Parent = MainFrame, Scale = 0.8})
    Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 8)})
    Create("UIStroke", {Parent = MainFrame, Color = Color3.fromRGB(40, 40, 45), Thickness = 1})

    -- ============================================================
    --  LOADING BAR
    -- ============================================================
    local LoadingOverlay = Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Color3.fromRGB(5, 5, 8), BackgroundTransparency = 0, Size = UDim2.new(1, 0, 1, 0), ZIndex = 300, Visible = true, Active = true})
    local LoadingIcon = Create("ImageLabel", {Parent = LoadingOverlay, BackgroundTransparency = 1, Size = UDim2.new(0, 90, 0, 90), Position = UDim2.new(0.5, 0, 0.5, -70), AnchorPoint = Vector2.new(0.5, 0.5), Image = SPHERE_ICON, ImageTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 301})
    local LoadingBarBg = Create("Frame", {Parent = LoadingOverlay, BackgroundColor3 = Color3.fromRGB(35, 35, 40), Size = UDim2.new(0, 260, 0, 6), Position = UDim2.new(0.5, 0, 0.5, 30), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 301})
    Create("UICorner", {Parent = LoadingBarBg, CornerRadius = UDim.new(1, 0)})
    local LoadingFill = Create("Frame", {Parent = LoadingBarBg, BackgroundColor3 = AccentColor, Size = UDim2.new(0, 0, 1, 0), ZIndex = 302})
    Create("UICorner", {Parent = LoadingFill, CornerRadius = UDim.new(1, 0)})
    local LoadingText = Create("TextLabel", {Parent = LoadingOverlay, Text = "Loading...", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 260, 0, 20), Position = UDim2.new(0.5, 0, 0.5, 50), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 301, TextTransparency = 1})

    task.spawn(function()
        Tween(LoadingIcon, {ImageTransparency = 0}, 0.4)
        task.wait(0.3)
        Tween(LoadingText, {TextTransparency = 0}, 0.3)
        local bt = TweenService:Create(LoadingFill, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)})
        bt:Play()
        bt.Completed:Wait()
        LoadingText.Text = "Ready!"
        task.wait(0.25)
        Tween(LoadingFill, {Size = UDim2.new(0, 0, 1, 0)}, 0.5)
        Tween(LoadingText, {TextTransparency = 1}, 0.4)
        Tween(LoadingBarBg, {BackgroundTransparency = 1}, 0.4)
        Tween(LoadingIcon, {ImageTransparency = 1}, 0.4)
        task.wait(0.5)
        Tween(LoadingOverlay, {BackgroundTransparency = 1}, 0.5)
        task.wait(0.5)
        LoadingOverlay:Destroy()
    end)

    Tween(MainScale, {Scale = 1}, 0.5)
    Tween(MainFrame, {BackgroundTransparency = 0}, 0.5)

    -- ============================================================
    --  BOTTOM DRAG
    -- ============================================================
    local BottomDragHitbox = Create("Frame", {Parent = ScreenGui, BackgroundTransparency = 1, Size = UDim2.new(0, 350, 0, 30), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 145, Active = true})
    local FloatingBottomBar = Create("Frame", {Parent = BottomDragHitbox, BackgroundColor3 = CardColor, BackgroundTransparency = 0, Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0.5, -3), ZIndex = 146})
    Create("UICorner", {Parent = FloatingBottomBar, CornerRadius = UDim.new(1, 0)})
    local BottomBarStroke = Create("UIStroke", {Parent = FloatingBottomBar, Color = Color3.fromRGB(50, 50, 55), Thickness = 1.2, Transparency = 0})
    MakeDraggable(BottomDragHitbox, MainFrame)

    RunService.RenderStepped:Connect(function()
        if MainFrame and MainFrame.Visible then
            BottomDragHitbox.Visible = true
            local cs = MainScale.Scale
            local fh, fw = 420 * cs, 650 * cs
            BottomDragHitbox.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset + (fh / 2) + 20)
            BottomDragHitbox.Size = UDim2.new(0, fw * 0.6, 0, 30 * cs)
            FloatingBottomBar.Size = UDim2.new(1, 0, 0, 6 * cs)
            FloatingBottomBar.Position = UDim2.new(0, 0, 0.5, -(3 * cs))
        else
            BottomDragHitbox.Visible = false
        end
    end)

    -- ============================================================
    --  TOP BAR
    -- ============================================================
    local TopBar = Create("Frame", {Parent = MainFrame, BackgroundColor3 = BackgroundColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, 0), Active = true})
    MakeDraggable(TopBar, MainFrame)

    local titleOffsetX = 15
    if topbarLogo then
        Create("ImageLabel", {Parent = TopBar, BackgroundTransparency = 1, Size = UDim2.new(0, logoSize, 0, logoSize), Position = UDim2.new(0, 8, 0.5, -(logoSize / 2)), Image = topbarLogo, ScaleType = Enum.ScaleType.Fit})
        titleOffsetX = 8 + logoSize + 8
    end

    local TitleContainer = Create("Frame", {Parent = TopBar, BackgroundTransparency = 1, Size = UDim2.new(0, 160, 1, 0), Position = UDim2.new(0, titleOffsetX, 0, 0)})
    local Title = Create("TextLabel", {Parent = TitleContainer, Text = hubName, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = TextColor, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 5), Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left})
    Create("TextLabel", {Parent = TitleContainer, Text = subText, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = subColor, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 22), Size = UDim2.new(1, 0, 0, 12), TextXAlignment = Enum.TextXAlignment.Left})

    local SearchBar = Create("Frame", {Parent = TopBar, BackgroundColor3 = CardColor, Size = UDim2.new(0, 250, 0, 26), Position = UDim2.new(0, 180, 0.5, -13)})
    Create("UICorner", {Parent = SearchBar, CornerRadius = UDim.new(0, 6)})
    Create("ImageLabel", {Parent = SearchBar, BackgroundTransparency = 1, Image = "rbxassetid://6031154871", ImageColor3 = SubTextColor, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 8, 0.5, -7)})
    local SearchInput = Create("TextBox", {Parent = SearchBar, BackgroundTransparency = 1, Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 30, 0, 0), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, PlaceholderText = "Search..", TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false})

    local CloseBtn = Create("TextButton", {Parent = TopBar, Text = "X", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(1, -35, 0, 0)})
    local MinBtn   = Create("TextButton", {Parent = TopBar, Text = "—", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(1, -65, 0, 0)})

    local Sidebar = Create("Frame", {Parent = MainFrame, BackgroundColor3 = BackgroundColor, BackgroundTransparency = 1, Size = UDim2.new(0, sideBarWidth, 1, -40), Position = UDim2.new(0, 0, 0, 40), Active = true})
    local TabSearchBox = Create("TextBox", {Parent = Sidebar, BackgroundColor3 = CardColor, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 5), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, PlaceholderText = "Search tabs...", TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false})
    Create("UIPadding", {Parent = TabSearchBox, PaddingLeft = UDim.new(0, 8)})
    Create("UICorner", {Parent = TabSearchBox, CornerRadius = UDim.new(0, 4)})
    Create("UIStroke", {Parent = TabSearchBox, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})

    local TabContainer = Create("ScrollingFrame", {Parent = Sidebar, BackgroundTransparency = 1, Size = UDim2.new(1, -15, 1, -40), Position = UDim2.new(0, 10, 0, 40), ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y})
    Create("UIListLayout", {Parent = TabContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
    Create("Frame", {Parent = MainFrame, BackgroundColor3 = Color3.fromRGB(40, 40, 45), BorderSizePixel = 0, Size = UDim2.new(0, 1, 1, -40), Position = UDim2.new(0, sideBarWidth, 0, 40)})

    local ContentArea = Create("Frame", {Parent = MainFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -(sideBarWidth + 5), 1, -40), Position = UDim2.new(0, sideBarWidth + 5, 0, 40), Active = true})

    -- ============================================================
    --  SPHERE (mode phone)
    -- ============================================================
    local Sphere = Create("ImageButton", {
        Parent = ScreenGui, BackgroundTransparency = 1,
        Size = UDim2.new(0, SPHERE_SIZE, 0, SPHERE_SIZE),
        Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
        Visible = false, AutoButtonColor = false,
        Image = SPHERE_ICON, ImageTransparency = 0,
        ScaleType = Enum.ScaleType.Fit, ClipsDescendants = false,
    })
    MakeDraggable(Sphere, Sphere)

    -- ============================================================
    --  WINDOW OBJECT
    -- ============================================================
    local Window = {
        CurrentTab = nil, Tabs = {}, Title = Title, AllCards = {}, MainFrame = MainFrame,
        CurrentTransparency = 0, ConfigElements = {},
        MapId = options and (type(options) == "table") and (options.Map or options.MapId) or nil
    }

    function Window:SetTransparency(val)
        Window.CurrentTransparency = val
        if MainFrame.Visible then
            Tween(MainFrame, {BackgroundTransparency = val}, 0.3)
            Tween(FloatingBottomBar, {BackgroundTransparency = val > 0 and 0.2 or 0}, 0.3)
        end
    end
	
	function Window:SetScale(val)
        CurrentScale = val
        if MainFrame.Visible then
            Tween(MainScale, {Scale = val}, 0.2)
        end
    end
    function Window:GetScale()
        return CurrentScale
    end

    function Window:SetMap(mapOption)
        Window.MapId = mapOption
        SaveManager:SetMap(mapOption)
    end

    -- ============================================================
    --  NORMALIZE KEY
    -- ============================================================
    local function NormalizeKey(input)
        if input == nil then return Enum.KeyCode.T end
        if type(input) == "string" then
            local ok, k = pcall(function() return Enum.KeyCode[input] end)
            if ok and k then return k end
            return Enum.KeyCode.T
        end
        local okName, name = pcall(function() return input.Name end)
        if okName and type(name) == "string" and name ~= "" then
            local ok, k = pcall(function() return Enum.KeyCode[name] end)
            if ok and k then return k end
        end
        if type(input) == "table" and type(input.Name) == "string" then
            local ok, k = pcall(function() return Enum.KeyCode[input.Name] end)
            if ok and k then return k end
        end
        return Enum.KeyCode.T
    end
    Window.NormalizeKey = NormalizeKey
    Library.NormalizeKey = NormalizeKey

    -- ============================================================
    --  OPEN / CLOSE / TOGGLE
    -- ============================================================
    local function OpenMenu()
        if MainFrame.Visible or IsAnimating then return end   -- ✅ chặn khi đang animate
        IsAnimating = true
        Sphere.Visible = false
        MainFrame.Visible = true
        BottomDragHitbox.Visible = true
        Tween(MainScale, {Scale = CurrentScale}, 0.4)
        Tween(MainFrame, {BackgroundTransparency = Window.CurrentTransparency}, 0.4)
        Tween(FloatingBottomBar, {BackgroundTransparency = Window.CurrentTransparency > 0 and 0.2 or 0}, 0.4)
        Tween(BottomBarStroke, {Transparency = 0}, 0.4)
        task.delay(0.4, function() IsAnimating = false end)   -- ✅ mở khóa sau 0.4s
    end
    Window.OpenMenu = OpenMenu

    local function CloseMenu()
        if not MainFrame.Visible or IsAnimating then return end   -- ✅ chặn khi đang animate
        IsAnimating = true
        CurrentScale = MainScale.Scale
        -- ✅ clamp để tránh scale quá nhỏ nếu spam
        if CurrentScale < 0.3 then CurrentScale = 1 end
        Tween(MainScale, {Scale = 0}, 0.4)
        Tween(MainFrame, {BackgroundTransparency = 1}, 0.4)
        Tween(FloatingBottomBar, {BackgroundTransparency = 1}, 0.4)
        Tween(BottomBarStroke, {Transparency = 1}, 0.4)
        task.wait(0.3)
        MainFrame.Visible = false
        BottomDragHitbox.Visible = false
        if MenuIconMode == "phone" then
            Sphere.Visible = true
            Sphere.Size = UDim2.new(0, 0, 0, 0)
            Sphere.ImageTransparency = 1
            Tween(Sphere, {Size = UDim2.new(0, SPHERE_SIZE, 0, SPHERE_SIZE)}, 0.4)
            Tween(Sphere, {ImageTransparency = 0}, 0.4)
        else
            Sphere.Visible = false
        end
        task.delay(0.1, function() IsAnimating = false end)   -- ✅ mở khóa sau 0.1s
    end
    Window.CloseMenu = CloseMenu

    local function ToggleMenu()
        -- ✅ debounce: bỏ qua nếu bấm quá nhanh (< 0.2s)
        local now = tick()
        if now - LastToggle < 0.2 then return end
        LastToggle = now
        if MainFrame.Visible then CloseMenu() else OpenMenu() end
    end
    Window.ToggleMenu = ToggleMenu

    -- ============================================================
    --  KEYBIND SYSTEM (final — không check KeybindListening)
    -- ============================================================
    local function ApplyMenuKeybind(newKey)
        local safeKey = NormalizeKey(newKey)
        MenuKeybind = safeKey
        local targetName = safeKey.Name

        if MenuKeybindConn then
            MenuKeybindConn:Disconnect()
            MenuKeybindConn = nil
        end

        -- ✅ FIX: dùng InputBegan nhưng thêm debounce riêng cho keybind
        local lastKeyPress = 0
        MenuKeybindConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            local pressedName = input.KeyCode and input.KeyCode.Name or nil
            if pressedName and pressedName == targetName then
                -- ✅ debounce 0.25s
                local now = tick()
                if now - lastKeyPress < 0.25 then return end
                lastKeyPress = now
                ToggleMenu()
            end
        end)

        if KeybindCaptureBtn and KeybindCaptureBtn.Parent then
            if type(targetName) == "string" then KeybindCaptureBtn.Text = targetName end
        end
    end

    function Window:SetMenuKeybind(newKey) ApplyMenuKeybind(newKey) end
    function Window:GetMenuKeybind() return MenuKeybind end

    ApplyMenuKeybind(MenuKeybind)

    -- ============================================================
    --  MENU ICON MODE
    -- ============================================================
    function Library:SetMenuIconMode(mode)
        MenuIconMode = (mode == "pc") and "pc" or "phone"
        if not MainFrame.Visible then
            if MenuIconMode == "phone" then
                Sphere.Visible = true
                Sphere.ImageTransparency = 0
            else
                Sphere.Visible = false
            end
        end
    end

    -- ============================================================
    --  MIN BUTTON
    -- ============================================================
    MinBtn.MouseButton1Click:Connect(function()
        CloseMenu()
    end)

    -- ============================================================
    --  SPHERE CLICK (mode phone)
    -- ============================================================
    Sphere.MouseButton1Click:Connect(function()
        OpenMenu()
    end)

    -- ============================================================
    --  CLOSE POPUP
    -- ============================================================
    local Popup = Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 100, Visible = false, Active = true})
    local PopupCard = Create("Frame", {Parent = Popup, BackgroundColor3 = Color3.fromRGB(20, 20, 24), Size = UDim2.new(0, 320, 0, 160), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 101, BackgroundTransparency = 1})
    Create("UICorner", {Parent = PopupCard, CornerRadius = UDim.new(0, 12)})
    local PopupScale = Create("UIScale", {Parent = PopupCard, Scale = 0.8})
    local PopupStroke = Create("UIStroke", {Parent = PopupCard, Color = Color3.fromRGB(50, 50, 55), Thickness = 1, Transparency = 1})
    local PopupTitle = Create("TextLabel", {Parent = PopupCard, Text = "Exit Application", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 25), ZIndex = 102, TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center})
    local PopupText = Create("TextLabel", {Parent = PopupCard, Text = "Close MarvenRiz Hub?", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 0, 40), Position = UDim2.new(0, 20, 0, 55), ZIndex = 102, TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true})
    local YesBtn = Create("TextButton", {Parent = PopupCard, Text = "Confirm", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = AccentColor, Size = UDim2.new(0, 125, 0, 36), Position = UDim2.new(0.5, 10, 0, 105), ZIndex = 102, BackgroundTransparency = 1, TextTransparency = 1, AutoButtonColor = false})
    Create("UICorner", {Parent = YesBtn, CornerRadius = UDim.new(0, 6)})
    AddBounce(YesBtn)
    local NoBtn = Create("TextButton", {Parent = PopupCard, Text = "Cancel", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TextColor, BackgroundColor3 = Color3.fromRGB(40, 40, 45), Size = UDim2.new(0, 125, 0, 36), Position = UDim2.new(0.5, -135, 0, 105), ZIndex = 102, BackgroundTransparency = 1, TextTransparency = 1, AutoButtonColor = false})
    Create("UICorner", {Parent = NoBtn, CornerRadius = UDim.new(0, 6)})
    AddBounce(NoBtn)

    CloseBtn.MouseButton1Click:Connect(function()
        Popup.Visible = true
        Tween(Popup, {BackgroundTransparency = 0.5}, 0.3)
        Tween(PopupCard, {BackgroundTransparency = 0}, 0.3)
        Tween(PopupScale, {Scale = 1}, 0.3)
        Tween(PopupStroke, {Transparency = 0}, 0.3)
        Tween(PopupTitle, {TextTransparency = 0}, 0.3)
        Tween(PopupText, {TextTransparency = 0}, 0.3)
        Tween(YesBtn, {BackgroundTransparency = 0, TextTransparency = 0}, 0.3)
        Tween(NoBtn, {BackgroundTransparency = 0, TextTransparency = 0}, 0.3)
    end)

    YesBtn.MouseButton1Click:Connect(function()
        Tween(Popup, {BackgroundTransparency = 1}, 0.3)
        Tween(PopupCard, {BackgroundTransparency = 1}, 0.3)
        Tween(PopupStroke, {Transparency = 1}, 0.3)
        Tween(PopupTitle, {TextTransparency = 1}, 0.3)
        Tween(PopupText, {TextTransparency = 1}, 0.3)
        Tween(YesBtn, {BackgroundTransparency = 1, TextTransparency = 1}, 0.3)
        Tween(NoBtn, {BackgroundTransparency = 1, TextTransparency = 1}, 0.3)
        Tween(MainScale, {Scale = 0.8}, 0.3)
        Tween(MainFrame, {BackgroundTransparency = 1}, 0.3)
        Tween(FloatingBottomBar, {BackgroundTransparency = 1}, 0.3)
        Tween(BottomBarStroke, {Transparency = 1}, 0.3)
        for _, desc in ipairs(MainFrame:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                Tween(desc, {TextTransparency = 1}, 0.3)
                if desc.BackgroundTransparency < 1 then Tween(desc, {BackgroundTransparency = 1}, 0.3) end
            elseif desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
                Tween(desc, {ImageTransparency = 1}, 0.3)
            elseif desc:IsA("Frame") or desc:IsA("ScrollingFrame") then
                if desc.BackgroundTransparency < 1 then Tween(desc, {BackgroundTransparency = 1}, 0.3) end
            elseif desc:IsA("UIStroke") then
                Tween(desc, {Transparency = 1}, 0.3)
            end
        end
        task.wait(0.35)
        ScreenGui:Destroy()
    end)

    NoBtn.MouseButton1Click:Connect(function()
        Tween(Popup, {BackgroundTransparency = 1}, 0.3)
        Tween(PopupCard, {BackgroundTransparency = 1}, 0.3)
        Tween(PopupScale, {Scale = 0.8}, 0.3)
        Tween(PopupStroke, {Transparency = 1}, 0.3)
        Tween(PopupTitle, {TextTransparency = 1}, 0.3)
        Tween(PopupText, {TextTransparency = 1}, 0.3)
        Tween(YesBtn, {BackgroundTransparency = 1, TextTransparency = 1}, 0.3)
        Tween(NoBtn, {BackgroundTransparency = 1, TextTransparency = 1}, 0.3)
        task.wait(0.3)
        Popup.Visible = false
    end)

    -- ============================================================
    --  SEARCH FILTERS
    -- ============================================================
    TabSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = TabSearchBox.Text:lower()
        for _, tabInfo in ipairs(Window.Tabs) do
            tabInfo.Button.Visible = (query == "" or string.find(tabInfo.Txt.Text:lower(), query)) and true or false
        end
    end)

    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local query = SearchInput.Text:lower()
        if query == "" then
            for _, data in ipairs(Window.AllCards) do
                data.Card.Parent = data.OrigParent
                data.Card.Visible = true
            end
        else
            if not Window.CurrentTab or not Window.CurrentTab.CurrentPage then return end
            local activeLeft = Window.CurrentTab.CurrentPage.LeftCol
            local activeRight = Window.CurrentTab.CurrentPage.RightCol
            local placeLeft = true
            for _, data in ipairs(Window.AllCards) do
                local card = data.Card
                if data.Tab == Window.CurrentTab then
                    if not data.SearchIndex then data.SearchIndex = BuildSearchIndex(card) end
                    if string.find(data.SearchIndex, query, 1, true) then
                        card.Parent = placeLeft and activeLeft or activeRight
                        placeLeft = not placeLeft
                        card.Visible = true
                    else card.Visible = false end
                else
                    card.Parent = data.OrigParent
                    card.Visible = true
                end
            end
        end
    end)

    -- ============================================================
    --  CREATE TAB
    -- ============================================================
    function Window:CreateTab(tabName, isDefault, isLocked)
        local isWhitelisted = false
        local player = Players.LocalPlayer
        if player then
            for _, allowedUser in ipairs(Library.WhitelistedUsers) do
                if player.Name == allowedUser or player.DisplayName == allowedUser then isWhitelisted = true break end
            end
        end

        local TabBtn = Create("TextButton", {Parent = TabContainer, Text = "", BackgroundColor3 = HoverColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 35), AutoButtonColor = false})
        Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0, 6)})
        AddBounce(TabBtn, 0.98)
        local Indicator = Create("Frame", {Name = "Indicator", Parent = TabBtn, BackgroundColor3 = isLocked and Color3.fromRGB(255, 215, 0) or AccentColor, Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5)})
        Create("UICorner", {Parent = Indicator, CornerRadius = UDim.new(1, 0)})
        local Txt = Create("TextLabel", {Parent = TabBtn, Text = tabName, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 15, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
        if isLocked then
            Create("ImageLabel", {Parent = TabBtn, Image = "rbxassetid://6031082533", ImageColor3 = Color3.fromRGB(255, 215, 0), BackgroundTransparency = 1, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -22, 0.5, -7)})
        end

        local TabContent = Create("Frame", {Parent = ContentArea, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false})
        local PageNav = Create("Frame", {Parent = TabContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 35)})
        Create("UIListLayout", {Parent = PageNav, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 15), VerticalAlignment = Enum.VerticalAlignment.Center})
        local PageContainer = Create("Frame", {Parent = TabContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -35), Position = UDim2.new(0, 0, 0, 35)})

        local TabConfig = {Button = TabBtn, Content = TabContent, Indicator = Indicator, Txt = Txt, Pages = {}, CurrentPage = nil}
        table.insert(Window.Tabs, TabConfig)

        TabBtn.MouseButton1Click:Connect(function()
            if isLocked and not isWhitelisted then
                Library:Notify({Title = "Access Denied", Description = "Whitelisted users only.", Duration = 3})
                return
            end
            if Window.CurrentTab == TabConfig then return end
            if Window.CurrentTab then
                Tween(Window.CurrentTab.Button, {BackgroundTransparency = 1}, 0.2)
                Tween(Window.CurrentTab.Indicator, {Size = UDim2.new(0, 3, 0, 0)}, 0.2)
                Tween(Window.CurrentTab.Txt, {TextColor3 = SubTextColor}, 0.2)
                Window.CurrentTab.Content.Visible = false
            end
            Window.CurrentTab = TabConfig
            TabConfig.Content.Visible = true
            TabConfig.Content.Position = UDim2.new(0, 0, 0, 15)
            Tween(TabConfig.Content, {Position = UDim2.new(0, 0, 0, 0)}, 0.35)
            Tween(TabBtn, {BackgroundTransparency = 0}, 0.2)
            Tween(Indicator, {Size = UDim2.new(0, 3, 0, 18)}, 0.3)
            Tween(Txt, {TextColor3 = TextColor}, 0.2)
            if #TabConfig.Pages > 0 then
                local firstPage = TabConfig.Pages[1]
                if TabConfig.CurrentPage ~= firstPage then
                    if TabConfig.CurrentPage then
                        Tween(TabConfig.CurrentPage.Btn, {TextColor3 = SubTextColor}, 0)
                        Tween(TabConfig.CurrentPage.Highlight, {Size = UDim2.new(0, 0, 0, 2), BackgroundTransparency = 1}, 0)
                        TabConfig.CurrentPage.Scroll.Visible = false
                    end
                    TabConfig.CurrentPage = firstPage
                    firstPage.Scroll.Visible = true
                    firstPage.Scroll.Position = UDim2.new(0, 5, 0, 15)
                    Tween(firstPage.Scroll, {Position = UDim2.new(0, 5, 0, 5)}, 0.35)
                    Tween(firstPage.Btn, {TextColor3 = TextColor}, 0)
                    Tween(firstPage.Highlight, {Size = UDim2.new(1, 0, 0, 2), BackgroundTransparency = 0}, 0)
                end
            end
        end)

        function TabConfig:CreatePage(pageName)
            local PageBtn = Create("TextButton", {Parent = PageNav, Text = pageName, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X})
            local PageHighlight = Create("Frame", {Parent = PageBtn, BackgroundColor3 = AccentColor, Size = UDim2.new(0, 0, 0, 2), Position = UDim2.new(0.5, 0, 1, -5), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1})
            local PageScroll = Create("ScrollingFrame", {
                Parent = PageContainer, BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5),
                ScrollBarThickness = 2, ScrollBarImageColor3 = Color3.fromRGB(60, 60, 65),
                Visible = false, BorderSizePixel = 0,
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollingEnabled = true,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                ElasticBehavior = Enum.ElasticBehavior.Always,
                ClipsDescendants = true,
            })

            local LeftColumn = Create("Frame", {Parent = PageScroll, BackgroundTransparency = 1, Size = UDim2.new(0.5, -5, 1, 0)})
            local RightColumn = Create("Frame", {Parent = PageScroll, BackgroundTransparency = 1, Size = UDim2.new(0.5, -5, 1, 0), Position = UDim2.new(0.5, 5, 0, 0)})

            local L_Layout = Create("UIListLayout", {Parent = LeftColumn, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})
            local R_Layout = Create("UIListLayout", {Parent = RightColumn, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})

            local function UpdateCanvas()
                local maxH = math.max(L_Layout.AbsoluteContentSize.Y, R_Layout.AbsoluteContentSize.Y)
                PageScroll.CanvasSize = UDim2.new(0, 0, 0, maxH + 20)
            end
            L_Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
            R_Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
            task.defer(UpdateCanvas)

            local PageObj = {Scroll = PageScroll, Btn = PageBtn, Highlight = PageHighlight, Left = true, LeftCol = LeftColumn, RightCol = RightColumn}
            table.insert(TabConfig.Pages, PageObj)

            PageBtn.MouseButton1Click:Connect(function()
                if TabConfig.CurrentPage == PageObj then return end
                if TabConfig.CurrentPage then
                    Tween(TabConfig.CurrentPage.Btn, {TextColor3 = SubTextColor}, 0.2)
                    Tween(TabConfig.CurrentPage.Highlight, {Size = UDim2.new(0, 0, 0, 2), BackgroundTransparency = 1}, 0.2)
                    TabConfig.CurrentPage.Scroll.Visible = false
                end
                TabConfig.CurrentPage = PageObj
                PageObj.Scroll.Visible = true
                PageObj.Scroll.Position = UDim2.new(0, 5, 0, 20)
                Tween(PageObj.Scroll, {Position = UDim2.new(0, 5, 0, 5)}, 0.35)
                Tween(PageBtn, {TextColor3 = TextColor}, 0.2)
                Tween(PageHighlight, {Size = UDim2.new(1, 0, 0, 2), BackgroundTransparency = 0}, 0.3)
            end)

            if #TabConfig.Pages == 1 and not isLocked then
                TabConfig.CurrentPage = PageObj
                PageObj.Scroll.Visible = true
                PageBtn.TextColor3 = TextColor
                PageHighlight.Size = UDim2.new(1, 0, 0, 2)
                PageHighlight.BackgroundTransparency = 0
            end

            function PageObj:CreateSection(sectionName, side)
                local targetColumn
                if side == "Left" or side == "left" then targetColumn = LeftColumn
                elseif side == "Right" or side == "right" then targetColumn = RightColumn
                else targetColumn = PageObj.Left and LeftColumn or RightColumn PageObj.Left = not PageObj.Left end

                local SectionContainer = Create("Frame", {Parent = targetColumn, BackgroundColor3 = CardColor, Size = UDim2.new(1, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.Y, ClipsDescendants = true})
                Create("UICorner", {Parent = SectionContainer, CornerRadius = UDim.new(0, 6)})
                table.insert(Window.AllCards, {Card = SectionContainer, OrigParent = targetColumn, Tab = TabConfig, Page = PageObj, SearchIndex = nil})
                Create("TextLabel", {Parent = SectionContainer, Text = sectionName, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})

                local ItemContainer = Create("Frame", {Parent = SectionContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.Y})
                Create("UIPadding", {Parent = ItemContainer, PaddingBottom = UDim.new(0, 10), PaddingTop = UDim.new(0, 5)})
                Create("UIListLayout", {Parent = ItemContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})

                local Elements = {}

                function Elements:AddCopyButton(name, copyText, infoData)
                    local BtnFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30)})
                    local Btn = Create("TextButton", {Parent = BtnFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0), AutoButtonColor = false})
                    Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 4)})
                    Create("UIStroke", {Parent = Btn, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})
                    AddBounce(Btn)
                    Btn.MouseEnter:Connect(function() Tween(Btn, {BackgroundColor3 = HoverColor}, 0.2) end)
                    Btn.MouseLeave:Connect(function() Tween(Btn, {BackgroundColor3 = BackgroundColor}, 0.2) end)
                    Btn.MouseButton1Click:Connect(function()
                        SafeCopyToClipboard(copyText)
                        local old = Btn.Text
                        Btn.Text = "Copied!"
                        Tween(Btn, {TextColor3 = AccentColor, BackgroundColor3 = HoverColor}, 0.2)
                        task.wait(1.5)
                        if Btn.Parent then Btn.Text = old Tween(Btn, {TextColor3 = TextColor, BackgroundColor3 = BackgroundColor}, 0.2) end
                    end)
                    AddInfoIcon(BtnFrame, UDim2.new(1, -40, 0.5, -8), infoData)
                end

                function Elements:AddButton(name, callback, infoData)
                    local BtnFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30)})
                    local Btn = Create("TextButton", {Parent = BtnFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0), AutoButtonColor = false})
                    Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 4)})
                    Create("UIStroke", {Parent = Btn, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})
                    AddBounce(Btn)
                    Btn.MouseEnter:Connect(function() Tween(Btn, {BackgroundColor3 = HoverColor}, 0.2) end)
                    Btn.MouseLeave:Connect(function() Tween(Btn, {BackgroundColor3 = BackgroundColor}, 0.2) end)
                    Btn.MouseButton1Click:Connect(function() if callback then callback() end end)
                    AddInfoIcon(BtnFrame, UDim2.new(1, -40, 0.5, -8), infoData)
                end

                function Elements:AddParagraph(title, content, infoData)
                    local hasTitle = title ~= nil and title ~= ""
                    local ParaWrap = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y})
                    local ParaFrame = Create("Frame", {Parent = ParaWrap, BackgroundColor3 = BackgroundColor, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -20, 0, 0), AutomaticSize = Enum.AutomaticSize.Y})
                    Create("UICorner", {Parent = ParaFrame, CornerRadius = UDim.new(0, 6)})
                    Create("UIStroke", {Parent = ParaFrame, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})
                    Create("UIPadding", {Parent = ParaFrame, PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 32), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)})
                    local TitleLbl = Create("TextLabel", {Parent = ParaFrame, Text = title or "", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, hasTitle and 16 or 0), Position = UDim2.new(0, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Visible = hasTitle, ClipsDescendants = true})
                    local ContentLbl = Create("TextLabel", {Parent = ParaFrame, Text = content or "", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), Position = hasTitle and UDim2.new(0, 0, 0, 22) or UDim2.new(0, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, LineHeight = 1.15})
                    AddInfoIcon(ParaFrame, UDim2.new(1, -24, 0, 8), infoData)
                    local H = {}
                    H.SetTitle = function(_s, t) if t == nil and _s ~= nil and type(_s) ~= "table" then t = _s end local show = t ~= nil and t ~= "" TitleLbl.Text = t or "" TitleLbl.Visible = show Tween(TitleLbl, {Size = UDim2.new(1, 0, 0, show and 16 or 0)}, 0.2) Tween(ContentLbl, {Position = show and UDim2.new(0, 0, 0, 22) or UDim2.new(0, 0, 0, 0)}, 0.2) end
                    H.SetContent = function(_s, c) if c == nil and _s ~= nil and type(_s) ~= "table" then c = _s end ContentLbl.Text = c or "" end
                    return H
                end

                function Elements:AddToggle(name, default, callback, infoData)
                    local state = default or false
                    local TogFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24)})
                    Create("TextLabel", {Parent = TogFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                    local Lever = Create("TextButton", {Parent = TogFrame, Text = "", BackgroundColor3 = state and AccentColor or Color3.fromRGB(45, 45, 50), Size = UDim2.new(0, 36, 0, 18), Position = UDim2.new(1, -46, 0.5, -9), AutoButtonColor = false})
                    Create("UICorner", {Parent = Lever, CornerRadius = UDim.new(1, 0)})
                    AddBounce(Lever)
                    local Knob = Create("Frame", {Parent = Lever, BackgroundColor3 = Color3.fromRGB(255, 255, 255), Size = UDim2.new(0, 14, 0, 14), Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)})
                    Create("UICorner", {Parent = Knob, CornerRadius = UDim.new(1, 0)})
                    local function internalSet(val)
                        state = val
                        Tween(Lever, {BackgroundColor3 = state and AccentColor or Color3.fromRGB(45, 45, 50)}, 0.3)
                        Tween(Knob, {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}, 0.3)
                        if callback then callback(state) end
                    end
                    Lever.MouseButton1Click:Connect(function() internalSet(not state) end)
                    AddInfoIcon(TogFrame, UDim2.new(1, -70, 0.5, -8), infoData)
                    if callback then callback(state) end
                    Window.ConfigElements[name] = {Set = internalSet, Get = function() return state end}
                end

                function Elements:AddSlider(name, min, max, default, callback, infoData)
                    local val = default or min
                    local SliFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 45)})
                    Create("TextLabel", {Parent = SliFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 15), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                    local ValTxt = Create("TextLabel", {Parent = SliFrame, Text = tostring(val), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 40, 0, 15), Position = UDim2.new(1, -50, 0, 0), TextXAlignment = Enum.TextXAlignment.Right})
                    local TrackBase = Create("Frame", {Parent = SliFrame, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 0, 6), Position = UDim2.new(0, 10, 0, 25)})
                    Create("UICorner", {Parent = TrackBase, CornerRadius = UDim.new(1, 0)})
                    Create("UIStroke", {Parent = TrackBase, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})
                    local Fill = Create("Frame", {Parent = TrackBase, BackgroundColor3 = AccentColor, Size = UDim2.new((val - min) / (max - min), 0, 1, 0)})
                    Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})
                    local Knob = Create("Frame", {Parent = Fill, BackgroundColor3 = Color3.fromRGB(255, 255, 255), Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -6, 0.5, -6)})
                    Create("UICorner", {Parent = Knob, CornerRadius = UDim.new(1, 0)})
                    local function internalSet(v)
                        val = math.clamp(v, min, max)
                        ValTxt.Text = tostring(val)
                        Tween(Fill, {Size = UDim2.new((val - min) / (max - min), 0, 1, 0)}, 0.1)
                        if callback then callback(val) end
                    end
                    local dragging = false
                    local function Update(input)
                        local pos = math.clamp((input.Position.X - TrackBase.AbsolutePosition.X) / TrackBase.AbsoluteSize.X, 0, 1)
                        internalSet(math.floor(min + ((max - min) * pos)))
                    end
                    Knob.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end end)
                    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
                    UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then Update(input) end end)
                    AddInfoIcon(SliFrame, UDim2.new(1, -70, 0, 0), infoData)
                    if callback then callback(val) end
                    Window.ConfigElements[name] = {Set = internalSet, Get = function() return val end}
                end

                function Elements:AddDropdown(name, options, isMulti, default, callback, infoData)
                    local selected = isMulti and ((type(default) == "table") and default or {}) or ((default ~= nil) and default or (options[1] or nil))
                    local dropped = false
                    local optionButtons, optionValues = {}, {}
                    local maxVisible = math.min(#options, 6)
                    local listHeight = math.max(maxVisible, 1) * 25
                    local DropFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50), ClipsDescendants = true})
                    Create("TextLabel", {Parent = DropFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 15), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                    local MainBtn = Create("TextButton", {Parent = DropFrame, Text = isMulti and "Select Options..." or "Select...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 20), AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left})
                    Create("UIPadding", {Parent = MainBtn, PaddingLeft = UDim.new(0, 8)})
                    Create("UICorner", {Parent = MainBtn, CornerRadius = UDim.new(0, 4)})
                    Create("UIStroke", {Parent = MainBtn, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})
                    AddBounce(MainBtn, 0.98)
                    local Arrow = Create("TextLabel", {Parent = MainBtn, Text = "▼", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -28, 0, 0)})
                    local SearchBox = Create("TextBox", {Parent = DropFrame, PlaceholderText = "Search...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = Color3.fromRGB(15, 15, 18), Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 10, 0, 50), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Visible = false})
                    Create("UIPadding", {Parent = SearchBox, PaddingLeft = UDim.new(0, 8)})
                    Create("UICorner", {Parent = SearchBox, CornerRadius = UDim.new(0, 4)})
                    Create("UIStroke", {Parent = SearchBox, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})
                    local ListFrame = Create("ScrollingFrame", {Parent = DropFrame, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 0, listHeight), Position = UDim2.new(0, 10, 0, 78), CanvasSize = UDim2.new(0, 0, 0, #options * 25), ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.fromRGB(80, 80, 85), BorderSizePixel = 0, ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Always})
                    Create("UICorner", {Parent = ListFrame, CornerRadius = UDim.new(0, 4)})
                    local DList = Create("UIListLayout", {Parent = ListFrame, SortOrder = Enum.SortOrder.LayoutOrder})
                    local function ToDisplay(v) return v == nil and "" or tostring(v) end
                    local function ValuesEqual(a, b) return a == b end
                    local function UpdateText()
                        if isMulti then
                            local txt = ""
                            for _, v in pairs(selected) do txt = txt .. ToDisplay(v) .. ", " end
                            MainBtn.Text = txt == "" and "Select Options..." or txt:sub(1, -3)
                        else MainBtn.Text = (selected ~= nil) and ToDisplay(selected) or "Select..." end
                    end
                    local function internalSet(v)
                        selected = v
                        UpdateText()
                        for _, btn in ipairs(optionButtons) do
                            local optVal = optionValues[btn]
                            local isSel = isMulti and (type(selected) == "table" and table.find(selected, optVal) ~= nil) or ValuesEqual(selected, optVal)
                            Tween(btn, {TextColor3 = isSel and TextColor or SubTextColor}, 0.2)
                            Tween(btn:FindFirstChild("Frame"), {Size = isSel and UDim2.new(1, 0, 1, 0) or UDim2.new(0, 0, 1, 0)}, 0.2)
                        end
                        if callback then callback(selected) end
                    end
                    local function RenderOptions(newOptions)
                        options = newOptions or options
                        for _, btn in ipairs(optionButtons) do btn:Destroy() end
                        optionButtons, optionValues = {}, {}
                        for _, opt in pairs(options) do
                            local isInitialSelected = (not isMulti and ValuesEqual(selected, opt)) or (isMulti and type(selected) == "table" and table.find(selected, opt) ~= nil)
                            local OptBtn = Create("TextButton", {Parent = ListFrame, Text = ToDisplay(opt), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = isInitialSelected and TextColor or SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 25), AutoButtonColor = false})
                            Create("Frame", {Parent = OptBtn, BackgroundColor3 = AccentColor, Size = isInitialSelected and UDim2.new(1, 0, 1, 0) or UDim2.new(0, 0, 1, 0), BackgroundTransparency = 0.8})
                            table.insert(optionButtons, OptBtn)
                            optionValues[OptBtn] = opt
                            OptBtn.MouseButton1Click:Connect(function()
                                if isMulti then
                                    local idx = table.find(selected, opt)
                                    if idx then table.remove(selected, idx) else table.insert(selected, opt) end
                                    internalSet(selected)
                                else
                                    internalSet(opt)
                                    dropped = false
                                    Tween(Arrow, {Rotation = 0}, 0.3)
                                    Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 50)}, 0.3)
                                    SearchBox.Visible = false
                                end
                            end)
                        end
                        maxVisible = math.min(#options, 6)
                        listHeight = math.max(maxVisible, 1) * 25
                        ListFrame.CanvasSize = UDim2.new(0, 0, 0, DList.AbsoluteContentSize.Y)
                        if dropped then
                            local dh = math.min(DList.AbsoluteContentSize.Y, listHeight)
                            ListFrame.Size = UDim2.new(1, -20, 0, dh)
                            Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 50 + 32 + dh)}, 0.1)
                        end
                    end
                    RenderOptions(options)
                    UpdateText()
                    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        local q = SearchBox.Text:lower()
                        for _, btn in ipairs(optionButtons) do
                            btn.Visible = (q == "" or string.find(btn.Text:lower(), q, 1, true)) and true or false
                        end
                    end)
                    DList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                        ListFrame.CanvasSize = UDim2.new(0, 0, 0, DList.AbsoluteContentSize.Y)
                        if dropped then
                            local dh = math.min(DList.AbsoluteContentSize.Y, listHeight)
                            ListFrame.Size = UDim2.new(1, -20, 0, dh)
                            Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 50 + 32 + dh)}, 0.1)
                        end
                    end)
                    MainBtn.MouseButton1Click:Connect(function()
                        dropped = not dropped
                        if dropped then
                            SearchBox.Visible = true
                            SearchBox.Text = ""
                            Tween(Arrow, {Rotation = 180}, 0.3)
                            local dh = math.min(DList.AbsoluteContentSize.Y, listHeight)
                            ListFrame.Size = UDim2.new(1, -20, 0, dh)
                            Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 50 + 32 + dh)}, 0.3)
                        else
                            SearchBox.Visible = false
                            Tween(Arrow, {Rotation = 0}, 0.3)
                            Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 50)}, 0.3)
                        end
                    end)
                    AddInfoIcon(DropFrame, UDim2.new(1, -25, 0, 0), infoData)
                    if callback then callback(selected) end
                    Window.ConfigElements[name] = {Set = internalSet, Get = function() return selected end}
                    local H = {}
                    H.Refresh = function(_s, o) if o then RenderOptions(o) if callback then callback(selected) end end end
                    H.RefreshOptions = H.Refresh
                    H.SetOptions = H.Refresh
                    H.Set = internalSet
                    H.Get = function() return selected end
                    return H
                end

                function Elements:AddTextbox(name, placeholder, default, callback, infoData)
                    local TxtFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50)})
                    Create("TextLabel", {Parent = TxtFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 15), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                    local Input = Create("TextBox", {Parent = TxtFrame, PlaceholderText = placeholder or "Type here...", Text = default ~= nil and tostring(default) or "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false})
                    Create("UIPadding", {Parent = Input, PaddingLeft = UDim.new(0, 8)})
                    Create("UICorner", {Parent = Input, CornerRadius = UDim.new(0, 4)})
                    Create("UIStroke", {Parent = Input, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})
                    local function internalSet(v)
                        Input.Text = tostring(v)
                        if callback then callback(v) end
                    end
                    Input.FocusLost:Connect(function() internalSet(Input.Text) end)
                    AddInfoIcon(TxtFrame, UDim2.new(1, -25, 0, 0), infoData)
                    if callback then callback(Input.Text) end
                    Window.ConfigElements[name] = {Set = internalSet, Get = function() return Input.Text end}
                end

                function Elements:AddColorPicker(name, defaultColor, callback, infoData)
                    local color = Color3.fromRGB(255, 255, 255)
                    if typeof(defaultColor) == "Color3" then color = defaultColor
                    elseif type(defaultColor) == "string" then
                        local okHex, cHex = pcall(function() return Color3.fromHex(defaultColor) end)
                        if okHex then color = cHex end
                    end
                    local h, s, v_hsv = color:ToHSV()
                    local dropped = false
                    local CFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), ClipsDescendants = true})
                    Create("TextLabel", {Parent = CFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -60, 0, 30), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                    local DisplayBtn = Create("TextButton", {Parent = CFrame, Text = "", BackgroundColor3 = color, Size = UDim2.new(0, 30, 0, 16), Position = UDim2.new(1, -40, 0.5, -8), AutoButtonColor = false})
                    Create("UICorner", {Parent = DisplayBtn, CornerRadius = UDim.new(0, 4)})
                    Create("UIStroke", {Parent = DisplayBtn, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.8, Thickness = 1})
                    AddBounce(DisplayBtn)
                    local PickerArea = Create("Frame", {Parent = CFrame, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 0, 140), Position = UDim2.new(0, 10, 0, 35)})
                    Create("UICorner", {Parent = PickerArea, CornerRadius = UDim.new(0, 4)})
                    local PickerClose = Create("TextButton", {Parent = PickerArea, Text = "X", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = SubTextColor, BackgroundColor3 = Color3.fromRGB(30, 20, 20), Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -22, 0, 4), ZIndex = 50, AutoButtonColor = false})
                    Create("UICorner", {Parent = PickerClose, CornerRadius = UDim.new(0, 4)})
                    AddBounce(PickerClose)
                    PickerClose.MouseEnter:Connect(function() Tween(PickerClose, {TextColor3 = Color3.fromRGB(255, 60, 60)}, 0.2) end)
                    PickerClose.MouseLeave:Connect(function() Tween(PickerClose, {TextColor3 = SubTextColor}, 0.2) end)
                    PickerClose.MouseButton1Click:Connect(function() dropped = false Tween(CFrame, {Size = UDim2.new(1, 0, 0, 30)}, 0.3) end)
                    local SVMap = Create("TextButton", {Parent = PickerArea, Text = "", BackgroundColor3 = Color3.fromHSV(h, 1, 1), Size = UDim2.new(1, -45, 0, 90), Position = UDim2.new(0, 10, 0, 10), AutoButtonColor = false, Active = true})
                    Create("UICorner", {Parent = SVMap, CornerRadius = UDim.new(0, 4)})
                    local WhiteGrad = Create("Frame", {Parent = SVMap, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2})
                    Create("UIGradient", {Parent = WhiteGrad, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}), Rotation = 0})
                    Create("UICorner", {Parent = WhiteGrad, CornerRadius = UDim.new(0, 4)})
                    local BlackGrad = Create("Frame", {Parent = SVMap, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 3})
                    Create("UIGradient", {Parent = BlackGrad, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}), Rotation = 90})
                    Create("UICorner", {Parent = BlackGrad, CornerRadius = UDim.new(0, 4)})
                    local SVRing = Create("Frame", {Parent = BlackGrad, Size = UDim2.new(0, 10, 0, 10), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(s, 0, 1 - v_hsv, 0), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 4})
                    Create("UICorner", {Parent = SVRing, CornerRadius = UDim.new(1, 0)})
                    Create("UIStroke", {Parent = SVRing, Color = Color3.new(0, 0, 0), Thickness = 1})
                    local HueSlider = Create("TextButton", {Parent = PickerArea, Text = "", Size = UDim2.new(1, -20, 0, 15), Position = UDim2.new(0, 10, 0, 110), AutoButtonColor = false, BackgroundColor3 = Color3.new(1, 1, 1), Active = true})
                    Create("UICorner", {Parent = HueSlider, CornerRadius = UDim.new(0, 4)})
                    Create("UIGradient", {Parent = HueSlider, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)), ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))})})
                    local HueRing = Create("Frame", {Parent = HueSlider, Size = UDim2.new(0, 6, 0, 15), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(h, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1)})
                    Create("UICorner", {Parent = HueRing, CornerRadius = UDim.new(0, 2)})
                    Create("UIStroke", {Parent = HueRing, Color = Color3.new(0, 0, 0), Thickness = 1})
                    local function internalSet(hexString)
                        local s_check, c = pcall(function() return Color3.fromHex(hexString) end)
                        if s_check then
                            color = c
                            h, s, v_hsv = color:ToHSV()
                            DisplayBtn.BackgroundColor3 = color
                            SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                            SVRing.Position = UDim2.new(s, 0, 1 - v_hsv, 0)
                            HueRing.Position = UDim2.new(h, 0, 0.5, 0)
                            if callback then callback(color) end
                        end
                    end
                    local function UpdateColor()
                        color = Color3.fromHSV(h, s, v_hsv)
                        DisplayBtn.BackgroundColor3 = color
                        SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                        if callback then callback(color) end
                    end
                    local draggingSV, draggingHue = false, false
                    local function EndDrag()
                        draggingSV = false
                        draggingHue = false
                        if PageObj and PageObj.Scroll then
                            task.defer(function()
                                if PageObj.Scroll and PageObj.Scroll.Parent then PageObj.Scroll.ScrollingEnabled = true end
                            end)
                        end
                    end
                    SVMap.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSV = true if PageObj and PageObj.Scroll then PageObj.Scroll.ScrollingEnabled = false end end end)
                    HueSlider.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingHue = true if PageObj and PageObj.Scroll then PageObj.Scroll.ScrollingEnabled = false end end end)
                    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then EndDrag() end end)
                    RunService.Heartbeat:Connect(function()
                        if draggingSV or draggingHue then
                            local pressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                                or UserInputService:IsMouseButtonPressed(Enum.UserInputType.Touch)
                            if not pressed then EndDrag() end
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                            if draggingSV then
                                local relX = math.clamp((input.Position.X - SVMap.AbsolutePosition.X) / SVMap.AbsoluteSize.X, 0, 1)
                                local relY = math.clamp((input.Position.Y - SVMap.AbsolutePosition.Y) / SVMap.AbsoluteSize.Y, 0, 1)
                                s, v_hsv = relX, 1 - relY
                                SVRing.Position = UDim2.new(s, 0, 1 - v_hsv, 0)
                                UpdateColor()
                            elseif draggingHue then
                                local relX = math.clamp((input.Position.X - HueSlider.AbsolutePosition.X) / HueSlider.AbsoluteSize.X, 0, 1)
                                h = relX
                                HueRing.Position = UDim2.new(h, 0, 0.5, 0)
                                UpdateColor()
                            end
                        end
                    end)
                    DisplayBtn.MouseButton1Click:Connect(function() dropped = not dropped Tween(CFrame, {Size = UDim2.new(1, 0, 0, dropped and 185 or 30)}, 0.3) end)
                    AddInfoIcon(CFrame, UDim2.new(1, -65, 0, 7), infoData)
                    if callback then callback(color) end
                    Window.ConfigElements[name] = {Set = internalSet, Get = function() return color:ToHex() end}
                end

                -- ============================================================
                --  KEYBIND (final — có fromUser flag, auto-load không ghi đè)
                -- ============================================================
                function Elements:AddKeybind(name, defaultKey, callback, infoData)
                    local currentKey = NormalizeKey(defaultKey)
                    local isListening = false
                    local userChanged = false       -- ✅ user đã tự đổi phím
                    local autoLoadDone = false      -- ✅ auto-load đã chạy lần đầu

                    local KbFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30)})
                    Create("TextLabel", {Parent = KbFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -120, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})

                    local Btn = Create("TextButton", {Parent = KbFrame, Text = currentKey.Name or "T", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = BackgroundColor, Size = UDim2.new(0, 90, 0, 24), Position = UDim2.new(1, -100, 0.5, -12), AutoButtonColor = false})
                    Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 4)})
                    Create("UIStroke", {Parent = Btn, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})
                    AddBounce(Btn)

                    local function StopListen()
                        isListening = false
                        KeybindListening = false
                        Btn.Text = currentKey.Name or "T"
                        Tween(Btn, {BackgroundColor3 = BackgroundColor, TextColor3 = TextColor}, 0.2)
                        local st = Btn:FindFirstChildOfClass("UIStroke")
                        if st then st.Color = Color3.fromRGB(45, 45, 50) end
                    end

                    local function StartListen()
                        isListening = true
                        KeybindListening = true
                        Btn.Text = "Press a key..."
                        Tween(Btn, {BackgroundColor3 = Color3.fromRGB(60, 40, 100), TextColor3 = Color3.fromRGB(255, 215, 0)}, 0.2)
                        local st = Btn:FindFirstChildOfClass("UIStroke")
                        if st then st.Color = AccentColor end
                    end

                    local function ApplyKey(newKey, fromUser)
                        local key = NormalizeKey(newKey)
                        currentKey = key
                        Btn.Text = key.Name or "T"
                        if name == "Menu Keybind" then KeybindCaptureBtn = Btn end
                        if fromUser then userChanged = true end
                        if callback then
                            local ok, err = pcall(callback, key)
                            if not ok then warn("[AddKeybind] callback error: " .. tostring(err)) end
                        end
                    end

                    Btn.MouseButton1Click:Connect(function()
                        if isListening then StopListen() else StartListen() end
                    end)

                    UserInputService.InputBegan:Connect(function(input, gameProcessed)
                        if not isListening then return end
                        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                        local pressedKey = NormalizeKey(input.KeyCode)
                        local pName = pressedKey and pressedKey.Name or nil

                        if pName == "Escape" then StopListen() return end
                        if pName == "Backspace" then
                            StopListen()
                            ApplyKey(Enum.KeyCode.T, true)
                            return
                        end
                        StopListen()
                        ApplyKey(pressedKey, true)
                    end)

                    AddInfoIcon(KbFrame, UDim2.new(1, -120, 0.5, -8), infoData)

                    if name == "Menu Keybind" then KeybindCaptureBtn = Btn end
                    if callback then callback(currentKey) end

                    Window.ConfigElements[name] = {
                        Set = function(v)
                            -- ✅ nếu user đã tự đổi phím và auto-load chưa chạy → bỏ qua lần đầu
                            if userChanged and not autoLoadDone then
                                autoLoadDone = true
                                return
                            end
                            autoLoadDone = true
                            ApplyKey(v, false)
                        end,
                        Get = function() return currentKey and currentKey.Name or "T" end,
                    }
                end

                -- ============================================================
                --  CONFIG MANAGER
                -- ============================================================
                function Elements:AddConfigManager(folderName)
                    folderName = folderName or Library.SaveManager.Folder or "MarvenRizSave"
                    if not _isfolder(folderName) then _makefolder(folderName) end

                    local function ReadAutoloadData()
                        local ok, raw = pcall(function() return _readfile(folderName .. "/autoload.json") end)
                        if ok and raw and raw ~= "" then
                            local okDecode, data = pcall(function() return HttpService:JSONDecode(raw) end)
                            if okDecode and type(data) == "table" then return data end
                        end
                        return {Enabled = false, Path = nil}
                    end
                    local function WriteAutoloadData(data)
                        if not _isfolder(folderName) then _makefolder(folderName) end
                        local okEncode, encoded = pcall(function() return HttpService:JSONEncode(data) end)
                        if okEncode then _writefile(folderName .. "/autoload.json", encoded) end
                    end

                    local ManagerFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 250)})
                    local ManagerSearch = Create("TextBox", {Parent = ManagerFrame, PlaceholderText = "Search Saves...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false})
                    Create("UIPadding", {Parent = ManagerSearch, PaddingLeft = UDim.new(0, 8)})
                    Create("UICorner", {Parent = ManagerSearch, CornerRadius = UDim.new(0, 4)})
                    Create("UIStroke", {Parent = ManagerSearch, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})

                    local Monitor = Create("ScrollingFrame", {Parent = ManagerFrame, BackgroundColor3 = Color3.fromRGB(15, 15, 18), Size = UDim2.new(1, -20, 0, 110), Position = UDim2.new(0, 10, 0, 35), ScrollBarThickness = 2, BorderSizePixel = 0, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y})
                    Create("UICorner", {Parent = Monitor, CornerRadius = UDim.new(0, 4)})
                    Create("UIStroke", {Parent = Monitor, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})
                    local MonitorLayout = Create("UIListLayout", {Parent = Monitor, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
                    Create("UIPadding", {Parent = Monitor, PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})

                    local deleteMode = false
                    local editMode = false
                    local selectedForDelete = {}
                    local editTargetFile = ""

                    local Controls = Create("Frame", {Parent = ManagerFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 80), Position = UDim2.new(0, 10, 0, 150)})
                    local NameBox = Create("TextBox", {Parent = Controls, PlaceholderText = "Enter save name...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false})
                    Create("UIPadding", {Parent = NameBox, PaddingLeft = UDim.new(0, 8)})
                    Create("UICorner", {Parent = NameBox, CornerRadius = UDim.new(0, 4)})
                    Create("UIStroke", {Parent = NameBox, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})

                    local CreateBtn = Create("TextButton", {Parent = Controls, Text = "Create Save", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Color3.fromRGB(190, 140, 255), Size = UDim2.new(0.5, -5, 0, 26), Position = UDim2.new(0, 0, 0, 35), AutoButtonColor = false})
                    Create("UICorner", {Parent = CreateBtn, CornerRadius = UDim.new(0, 4)})
                    AddBounce(CreateBtn)
                    local DeleteTogBtn = Create("TextButton", {Parent = Controls, Text = "Delete Mode: OFF", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = Color3.fromRGB(45, 45, 50), Size = UDim2.new(0.5, -5, 0, 26), Position = UDim2.new(0.5, 5, 0, 35), AutoButtonColor = false})
                    Create("UICorner", {Parent = DeleteTogBtn, CornerRadius = UDim.new(0, 4)})
                    AddBounce(DeleteTogBtn)

                    local ActionArea = Create("Frame", {Parent = Controls, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 35), Visible = false})
                    local ConfirmActionBtn = Create("TextButton", {Parent = ActionArea, Text = "Confirm", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Color3.fromRGB(200, 50, 50), Size = UDim2.new(0.5, -5, 0, 26), Position = UDim2.new(0, 0, 0, 0), AutoButtonColor = false})
                    Create("UICorner", {Parent = ConfirmActionBtn, CornerRadius = UDim.new(0, 4)})
                    AddBounce(ConfirmActionBtn)
                    local CancelActionBtn = Create("TextButton", {Parent = ActionArea, Text = "Cancel", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = Color3.fromRGB(60, 60, 65), Size = UDim2.new(0.5, -5, 0, 26), Position = UDim2.new(0.5, 5, 0, 0), AutoButtonColor = false})
                    Create("UICorner", {Parent = CancelActionBtn, CornerRadius = UDim.new(0, 4)})
                    AddBounce(CancelActionBtn)

                    local InternalConfirmPopup = Create("Frame", {Parent = ManagerFrame, BackgroundColor3 = Color3.fromRGB(20, 20, 24), Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0, 10, 0, 10), ZIndex = 60, BackgroundTransparency = 1, Visible = false})
                    Create("UICorner", {Parent = InternalConfirmPopup, CornerRadius = UDim.new(0, 8)})
                    Create("UIStroke", {Parent = InternalConfirmPopup, Color = Color3.fromRGB(180, 50, 50), Thickness = 1, Transparency = 1})
                    local P_Title = Create("TextLabel", {Parent = InternalConfirmPopup, Text = "Confirm Deletion?", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.fromRGB(255, 60, 60), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 40), TextTransparency = 1, ZIndex = 61})
                    local P_Desc = Create("TextLabel", {Parent = InternalConfirmPopup, Text = "Delete selected saves permanently?", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 0, 40), Position = UDim2.new(0, 20, 0, 70), TextWrapped = true, TextTransparency = 1, ZIndex = 61})
                    local P_Yes = Create("TextButton", {Parent = InternalConfirmPopup, Text = "Yes", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Color3.fromRGB(180, 50, 50), Size = UDim2.new(0.5, -30, 0, 30), Position = UDim2.new(0, 20, 0, 130), AutoButtonColor = false, BackgroundTransparency = 1, TextTransparency = 1, ZIndex = 61})
                    Create("UICorner", {Parent = P_Yes, CornerRadius = UDim.new(0, 4)})
                    AddBounce(P_Yes)
                    local P_No = Create("TextButton", {Parent = InternalConfirmPopup, Text = "No", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TextColor, BackgroundColor3 = Color3.fromRGB(45, 45, 50), Size = UDim2.new(0.5, -30, 0, 30), Position = UDim2.new(0.5, 10, 0, 130), AutoButtonColor = false, BackgroundTransparency = 1, TextTransparency = 1, ZIndex = 61})
                    Create("UICorner", {Parent = P_No, CornerRadius = UDim.new(0, 4)})
                    AddBounce(P_No)

                    local function HideInternalPopup()
                        Tween(InternalConfirmPopup, {BackgroundTransparency = 1}, 0.3)
                        Tween(InternalConfirmPopup:FindFirstChild("UIStroke"), {Transparency = 1}, 0.3)
                        Tween(P_Title, {TextTransparency = 1}, 0.3)
                        Tween(P_Desc, {TextTransparency = 1}, 0.3)
                        Tween(P_Yes, {BackgroundTransparency = 1, TextTransparency = 1}, 0.3)
                        Tween(P_No, {BackgroundTransparency = 1, TextTransparency = 1}, 0.3)
                        task.wait(0.3)
                        InternalConfirmPopup.Visible = false
                    end

                    local function ListAllSaveFiles()
                        if not _isfolder(folderName) then _makefolder(folderName) end
                        local out = {}
                        for _, fp in ipairs(_listfiles(folderName)) do
                            if not IsAutoloadFile(fp) then table.insert(out, fp) end
                        end
                        return out
                    end
                    local function DisplayNameFromPath(fp)
                        local raw = fp:match("([^/\\]+)%.json$")
                        if not raw then return nil end
                        return (raw:gsub("_%d+%.%d+$", ""):gsub("_%d+$", ""))
                    end

                    local RefreshMonitor

                    local function BuildRow(filepath)
                        local displayFName = DisplayNameFromPath(filepath) or "Unnamed"
                        local currentAutoload = ReadAutoloadData().Path
                        local isAutoload = (currentAutoload == filepath)

                        local Row = Create("Frame", {Parent = Monitor, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, 0, 0, 30)})
                        Create("UICorner", {Parent = Row, CornerRadius = UDim.new(0, 4)})
                        Create("TextLabel", {Parent = Row, Text = displayFName, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -84, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})

                        local StarBtn = Create("TextButton", {Parent = Row, Text = isAutoload and "★" or "☆", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = isAutoload and Color3.fromRGB(255, 215, 0) or SubTextColor, BackgroundColor3 = Color3.fromRGB(45, 45, 50), Size = UDim2.new(0, 22, 0, 20), Position = UDim2.new(1, -103, 0.5, -10), AutoButtonColor = false})
                        Create("UICorner", {Parent = StarBtn, CornerRadius = UDim.new(0, 4)})
                        AddBounce(StarBtn)

                        local LoadBtn = Create("TextButton", {Parent = Row, Text = "Load", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = TextColor, BackgroundColor3 = Color3.fromRGB(45, 120, 60), Size = UDim2.new(0, 32, 0, 20), Position = UDim2.new(1, -77, 0.5, -10), AutoButtonColor = false})
                        Create("UICorner", {Parent = LoadBtn, CornerRadius = UDim.new(0, 4)})
                        AddBounce(LoadBtn)

                        local EditBtn = Create("TextButton", {Parent = Row, Text = "Edit", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = TextColor, BackgroundColor3 = Color3.fromRGB(150, 100, 45), Size = UDim2.new(0, 30, 0, 20), Position = UDim2.new(1, -40, 0.5, -10), AutoButtonColor = false})
                        Create("UICorner", {Parent = EditBtn, CornerRadius = UDim.new(0, 4)})
                        AddBounce(EditBtn)

                        local SelectionMask = Create("TextButton", {Parent = Row, Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, -110, 1, 0), ZIndex = 1})
                        SelectionMask.MouseButton1Click:Connect(function()
                            if not deleteMode then return end
                            if selectedForDelete[filepath] then
                                selectedForDelete[filepath] = nil
                                Tween(Row, {BackgroundColor3 = BackgroundColor}, 0.2)
                            else
                                selectedForDelete[filepath] = true
                                Tween(Row, {BackgroundColor3 = Color3.fromRGB(180, 50, 50)}, 0.2)
                            end
                        end)

                        StarBtn.MouseButton1Click:Connect(function()
                            if deleteMode or editMode then return end
                            local data = ReadAutoloadData()
                            if isAutoload then
                                data.Path = nil
                                data.Enabled = false
                                WriteAutoloadData(data)
                                Library:Notify({Title = "Auto Load Disabled", Description = displayFName .. " bỏ chọn.", Duration = 3})
                            else
                                local exists = false
                                for _, fp in ipairs(_listfiles(folderName)) do if fp == filepath then exists = true break end end
                                if not exists then
                                    Library:Notify({Title = "File không tồn tại", Description = "File save đã bị xóa.", Duration = 4})
                                    RefreshMonitor()
                                    return
                                end
                                data.Path = filepath
                                data.Enabled = true
                                WriteAutoloadData(data)

                                -- ✅ FIX: load ngay lập tức
                                local loadOk, fileData = pcall(function()
                                    return HttpService:JSONDecode(_readfile(filepath))
                                end)
                                if loadOk and type(fileData) == "table" then
                                    for k, v in pairs(fileData) do
                                        if Window.ConfigElements[k] and Window.ConfigElements[k].Set then
                                            pcall(function() Window.ConfigElements[k].Set(v) end)
                                        end
                                    end
                                    Library:Notify({
                                        Title = "Auto Load Enabled",
                                        Description = displayFName .. " đã được load ngay. Sẽ tự load khi khởi động.",
                                        Duration = 4
                                    })
                                else
                                    Library:Notify({
                                        Title = "Auto Load Enabled",
                                        Description = displayFName .. " sẽ tự load khi khởi động (file lỗi, không load ngay).",
                                        Duration = 4
                                    })
                                end
                            end
                            RefreshMonitor()
                        end)

                        LoadBtn.MouseButton1Click:Connect(function()
                            if deleteMode or editMode then return end
                            local s, data = pcall(function() return HttpService:JSONDecode(_readfile(filepath)) end)
                            if s and type(data) == "table" then
                                for k, v in pairs(data) do
                                    if Window.ConfigElements[k] and Window.ConfigElements[k].Set then
                                        pcall(function() Window.ConfigElements[k].Set(v) end)
                                    end
                                end
                                Library:Notify({Title = "Loaded", Description = displayFName .. " applied.", Duration = 3})
                            end
                        end)

                        EditBtn.MouseButton1Click:Connect(function()
                            if deleteMode then return end
                            editMode = true
                            editTargetFile = filepath
                            NameBox.Text = displayFName
                            CreateBtn.Visible = false
                            DeleteTogBtn.Visible = false
                            ActionArea.Visible = true
                            ConfirmActionBtn.Text = "Save Edit"
                            ConfirmActionBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
                        end)
                    end

                    RefreshMonitor = function()
                        for _, v in ipairs(Monitor:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
                        selectedForDelete = {}
                        for _, filepath in ipairs(ListAllSaveFiles()) do BuildRow(filepath) end
                        local autoloadData = ReadAutoloadData()
                        if autoloadData.Path then
                            local exists = false
                            for _, fp in ipairs(_listfiles(folderName)) do if fp == autoloadData.Path then exists = true break end end
                            if not exists then
                                autoloadData.Path = nil
                                autoloadData.Enabled = false
                                WriteAutoloadData(autoloadData)
                            end
                        end
                    end

                    local function ExecuteSave(saveName)
                        local payload = {}
                        for k, el in pairs(Window.ConfigElements) do if el.Get then payload[k] = el.Get() end end
                        local encoded = HttpService:JSONEncode(payload)
                        local uniqueKey = tostring(math.floor(tick()))
                        _writefile(folderName .. "/" .. saveName .. "_" .. uniqueKey .. ".json", encoded)
                        RefreshMonitor()
                        Library:Notify({Title = "Saved", Description = "Config [" .. saveName .. "] saved."})
                    end

                    CreateBtn.MouseButton1Click:Connect(function()
                        if NameBox.Text ~= "" then ExecuteSave(NameBox.Text) end
                    end)

                    DeleteTogBtn.MouseButton1Click:Connect(function()
                        if editMode then return end
                        deleteMode = not deleteMode
                        DeleteTogBtn.Text = deleteMode and "Delete Mode: ON" or "Delete Mode: OFF"
                        Tween(DeleteTogBtn, {BackgroundColor3 = deleteMode and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(45, 45, 50)}, 0.2)
                        ActionArea.Visible = deleteMode
                        CreateBtn.Visible = not deleteMode
                        if deleteMode then
                            ConfirmActionBtn.Text = "Delete Selected"
                            ConfirmActionBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                        else RefreshMonitor() end
                    end)

                    ConfirmActionBtn.MouseButton1Click:Connect(function()
                        if deleteMode then
                            InternalConfirmPopup.Visible = true
                            Tween(InternalConfirmPopup, {BackgroundTransparency = 0.1}, 0.3)
                            Tween(InternalConfirmPopup:FindFirstChild("UIStroke"), {Transparency = 0.5}, 0.3)
                            Tween(P_Title, {TextTransparency = 0}, 0.3)
                            Tween(P_Desc, {TextTransparency = 0}, 0.3)
                            Tween(P_Yes, {BackgroundTransparency = 0, TextTransparency = 0}, 0.3)
                            Tween(P_No, {BackgroundTransparency = 0, TextTransparency = 0}, 0.3)
                        elseif editMode then
                            local newName = NameBox.Text
                            if newName ~= "" then
                                pcall(function() _delfile(editTargetFile) end)
                                ExecuteSave(newName)
                            end
                            editMode = false
                            ActionArea.Visible = false
                            CreateBtn.Visible = true
                            DeleteTogBtn.Visible = true
                            RefreshMonitor()
                        end
                    end)

                    P_Yes.MouseButton1Click:Connect(function()
                        local autoData = ReadAutoloadData()
                        local autoCleared = false
                        local deletedCount = 0
                        for filepath, _ in pairs(selectedForDelete) do
                            local exists = false
                            for _, fp in ipairs(_listfiles(folderName)) do if fp == filepath then exists = true break end end
                            if exists then
                                local ok = pcall(function() _delfile(filepath) end)
                                if ok then deletedCount = deletedCount + 1 end
                                if autoData.Path == filepath then
                                    autoData.Path = nil
                                    autoData.Enabled = false
                                    autoCleared = true
                                end
                            end
                        end
                        if autoCleared then WriteAutoloadData(autoData) end
                        deleteMode = false
                        DeleteTogBtn.Text = "Delete Mode: OFF"
                        DeleteTogBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                        ActionArea.Visible = false
                        CreateBtn.Visible = true
                        RefreshMonitor()
                        Library:Notify({Title = "Deletions", Description = ("Erased %d file(s)."):format(deletedCount)})
                        HideInternalPopup()
                    end)

                    P_No.MouseButton1Click:Connect(function() HideInternalPopup() end)

                    CancelActionBtn.MouseButton1Click:Connect(function()
                        editMode = false
                        deleteMode = false
                        DeleteTogBtn.Text = "Delete Mode: OFF"
                        DeleteTogBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                        ActionArea.Visible = false
                        CreateBtn.Visible = true
                        DeleteTogBtn.Visible = true
                        NameBox.Text = ""
                        RefreshMonitor()
                    end)

                    ManagerSearch:GetPropertyChangedSignal("Text"):Connect(function()
                        local q = ManagerSearch.Text:lower()
                        for _, v in ipairs(Monitor:GetChildren()) do
                            if v:IsA("Frame") then
                                local lbl = v:FindFirstChildOfClass("TextLabel")
                                if lbl then v.Visible = (q == "" or string.find(lbl.Text:lower(), q) ~= nil) end
                            end
                        end
                    end)

                    RefreshMonitor()
                end

                local function BuildInfo(config)
                    if config.Desc then return {Title = config.Title, Description = config.Desc, Example = config.Example} end
                    return nil
                end

                function Elements:Button(config) config = config or {} return self:AddButton(config.Title, config.Callback, BuildInfo(config)) end
                function Elements:CopyButton(config) config = config or {} return self:AddCopyButton(config.Title, config.Text or config.Content, BuildInfo(config)) end
                function Elements:Paragraph(config) config = config or {} return self:AddParagraph(config.Title, config.Content, BuildInfo(config)) end
                function Elements:Toggle(config) config = config or {} return self:AddToggle(config.Title, config.Value, config.Callback, BuildInfo(config)) end
                function Elements:Slider(config) config = config or {} return self:AddSlider(config.Title, config.Min, config.Max, config.Value, config.Callback, BuildInfo(config)) end
                function Elements:Dropdown(config) config = config or {} return self:AddDropdown(config.Title, config.Options, config.Multi, config.Value, config.Callback, BuildInfo(config)) end
                function Elements:Textbox(config) config = config or {} return self:AddTextbox(config.Title, config.Placeholder, config.Value, config.Callback, BuildInfo(config)) end
                function Elements:ColorPicker(config) config = config or {} return self:AddColorPicker(config.Title, config.Value, config.Callback, BuildInfo(config)) end
                function Elements:Keybind(config) config = config or {} return self:AddKeybind(config.Title, config.Value, config.Callback, BuildInfo(config)) end
                function Elements:ConfigManager(config) config = config or {} return self:AddConfigManager(config.Folder) end

                return Elements
            end
            return PageObj
        end

        if isDefault then
            TabBtn.BackgroundTransparency = 0
            Indicator.Size = UDim2.new(0, 3, 0, 18)
            Txt.TextColor3 = TextColor
            TabContent.Visible = true
            Window.CurrentTab = TabConfig
        end
        return TabConfig
    end

    -- ============================================================
    --  SYNC MODE TỪ CONFIG ĐÃ LƯU
    -- ============================================================
    task.defer(function()
        local folder = Library.SaveManager.Folder
        local ok, raw = pcall(function() return _readfile(folder .. "/autoload.json") end)
        if ok and raw and raw ~= "" then
            local okD, data = pcall(function() return HttpService:JSONDecode(raw) end)
            if okD and type(data) == "table" and data.Enabled and data.Path then
                local okF, cfgRaw = pcall(function() return _readfile(data.Path) end)
                if okF and cfgRaw and cfgRaw ~= "" then
                    local okC, cfg = pcall(function() return HttpService:JSONDecode(cfgRaw) end)
                    if okC and type(cfg) == "table" then
                        if cfg["Menu Icon Mode"] == "PC" then
                            Library:SetMenuIconMode("pc")
                        else
                            Library:SetMenuIconMode("phone")
                        end
                    end
                end
            end
        end
    end)

    Library.SaveManager.Window = Window
    return Window
end

return Library
