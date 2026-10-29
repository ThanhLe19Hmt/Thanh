local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Library = { WhitelistedUsers = {} }

local _isfolder = isfolder or function() return true end
local _makefolder = makefolder or function() end
local _writefile = writefile or function(path, data) warn("File saving not supported.") end
local _readfile = readfile or function() return "{}" end
local _listfiles = listfiles or function() return {} end
local _delfile = delfile or function() warn("File deletion not supported.") end

local function SafeCopyToClipboard(text)
    if setclipboard then setclipboard(text)
    elseif toclipboard then toclipboard(text) end
end

-- ============================================================
-- THEME — modern dark, soft gradients
-- ============================================================
local Theme = {
    Background      = Color3.fromRGB(14, 14, 18),
    BackgroundGrad  = Color3.fromRGB(20, 20, 26),
    Sidebar         = Color3.fromRGB(11, 11, 15),
    TopBar          = Color3.fromRGB(17, 17, 22),
    Card            = Color3.fromRGB(23, 23, 29),
    CardHeader      = Color3.fromRGB(28, 28, 35),
    CardHover       = Color3.fromRGB(33, 33, 41),
    ElementBg       = Color3.fromRGB(19, 19, 25),
    ElementStroke   = Color3.fromRGB(42, 42, 52),
    Text            = Color3.fromRGB(242, 242, 248),
    SubText         = Color3.fromRGB(155, 155, 168),
    Muted           = Color3.fromRGB(110, 110, 122),
    Accent          = Color3.fromRGB(88, 140, 255),
    AccentDim       = Color3.fromRGB(56, 92, 180),
    Success         = Color3.fromRGB(72, 190, 120),
    Danger          = Color3.fromRGB(230, 80, 90),
    Warning         = Color3.fromRGB(235, 175, 70),
}

local AccentColor = Theme.Accent
local BackgroundColor = Theme.Background
local CardColor = Theme.Card
local HoverColor = Theme.CardHover
local TextColor = Theme.Text
local SubTextColor = Theme.SubText

-- ============================================================
-- HELPERS
-- ============================================================
local function Create(className, properties)
    local inst = Instance.new(className)
    if className == "TextBox" then inst.Text = "" end
    for k, v in pairs(properties or {}) do inst[k] = v end
    if (className == "TextLabel" or className == "TextButton" or className == "TextBox")
        and properties and properties.TextSize and not properties.RichText then
        inst.TextScaled = true
        local c = Instance.new("UITextSizeConstraint")
        c.MaxTextSize = properties.TextSize
        c.MinTextSize = 6
        c.Parent = inst
    end
    return inst
end

local function Tween(inst, props, dur)
    dur = dur or 0.22
    local t = TweenService:Create(inst, TweenInfo.new(dur, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function AddBounce(btn, scale)
    scale = scale or 0.97
    local s = btn:FindFirstChild("UIScale") or Create("UIScale", {Parent = btn, Scale = 1})
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            Tween(s, {Scale = scale}, 0.12)
        end
    end)
    btn.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            Tween(s, {Scale = 1}, 0.12)
        end
    end)
    btn.MouseLeave:Connect(function() Tween(s, {Scale = 1}, 0.12) end)
end

local function MakeDraggable(handle, target)
    handle.Active = true
    target.Active = true
    local dragging, dragStart, startPos, dragInput
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = i.Position
            startPos = target.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            dragInput = i
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i == dragInput and dragging then
            local d = i.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local function IsAutoloadFile(path)
    return type(path) == "string" and path:lower():sub(-13) == "autoload.json"
end

local function BuildSearchIndex(card)
    local parts = {}
    for _, d in ipairs(card:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) and d.Text and d.Text ~= "" then
            table.insert(parts, d.Text:lower())
        end
    end
    return table.concat(parts, " ")
end

-- Tạo drop shadow (ảnh mờ dưới frame)
local function AddShadow(parent, transparency)
    local s = Create("ImageLabel", {
        Parent = parent,
        BackgroundTransparency = 1,
        Image = "rbxassetid://1316045217",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = transparency or 0.6,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10, 10, 118, 118),
        Size = UDim2.new(1, 40, 1, 40),
        Position = UDim2.new(0, -20, 0, -20),
        ZIndex = -1,
    })
    return s
end

-- ============================================================
-- NOTIFY
-- ============================================================
local NotifContainer
function Library:Notify(opt)
    if not NotifContainer then return end
    opt = opt or {}
    local title = opt.Title or "Notification"
    local desc = opt.Description or ""
    local duration = opt.Duration or 3

    local n = Create("Frame", {Parent = NotifContainer, BackgroundColor3 = Color3.fromRGB(24, 24, 30), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ClipsDescendants = false})
    Create("UICorner", {Parent = n, CornerRadius = UDim.new(0, 10)})
    local stroke = Create("UIStroke", {Parent = n, Color = Color3.fromRGB(55, 55, 68), Thickness = 1, Transparency = 1})
    Create("UIPadding", {Parent = n, PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 14)})
    Create("UIListLayout", {Parent = n, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})

    local accentBar = Create("Frame", {Parent = n, BackgroundColor3 = AccentColor, Size = UDim2.new(0, 3, 1, -16), Position = UDim2.new(0, -12, 0.5, -((n.AbsoluteSize.Y - 16)/2)), ZIndex = 2})
    Create("UICorner", {Parent = accentBar, CornerRadius = UDim.new(1, 0)})

    local t = Create("TextLabel", {Parent = n, Text = title, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, ZIndex = 2})
    local d = Create("TextLabel", {Parent = n, Text = desc, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, TextTransparency = 1, ZIndex = 2, LineHeight = 1.2})

    Tween(n, {BackgroundTransparency = 0}, 0.25)
    Tween(stroke, {Transparency = 0}, 0.25)
    Tween(t, {TextTransparency = 0}, 0.25)
    Tween(d, {TextTransparency = 0}, 0.25)

    task.defer(function()
        task.wait(0.1)
        accentBar.Size = UDim2.new(0, 3, 1, -16)
        accentBar.Position = UDim2.new(0, -12, 0.5, -((n.AbsoluteSize.Y - 16)/2))
    end)

    task.delay(duration, function()
        if not n.Parent then return end
        Tween(n, {BackgroundTransparency = 1}, 0.3)
        Tween(stroke, {Transparency = 1}, 0.3)
        Tween(t, {TextTransparency = 1}, 0.3)
        Tween(d, {TextTransparency = 1}, 0.3)
        task.wait(0.35)
        n:Destroy()
    end)
end

-- ============================================================
-- SAVE MANAGER
-- ============================================================
Library.SaveManager = { Folder = "MarvenRizSave", BaseFolder = "MarvenRizSave", Window = nil }
local SM = Library.SaveManager

local function ResolveMapKey(m)
    if m == nil then return nil end
    local names = {}
    if type(m) == "table" then for _, v in ipairs(m) do table.insert(names, tostring(v)) end
    else table.insert(names, tostring(m)) end
    if #names == 0 then return nil end
    table.sort(names)
    return table.concat(names, "_")
end

function SM:SetFolder(f)
    if f and f ~= "" then self.Folder = f end
    local built = ""
    for seg in self.Folder:gmatch("[^/\\]+") do
        built = (built == "") and seg or (built .. "/" .. seg)
        if not _isfolder(built) then _makefolder(built) end
    end
end

function SM:SetMap(m, base)
    if base and base ~= "" then self.BaseFolder = base end
    local key = ResolveMapKey(m)
    self:SetFolder(key and (self.BaseFolder .. "/" .. key) or self.BaseFolder)
end

function SM:GetConfigs()
    if not _isfolder(self.Folder) then _makefolder(self.Folder) end
    local list = {}
    for _, p in ipairs(_listfiles(self.Folder)) do
        local raw = p:match("([^/\\]+)%.json$")
        if raw and not IsAutoloadFile(p) then table.insert(list, raw) end
    end
    table.sort(list)
    return list
end

function SM:GetAutoloadData()
    local ok, raw = pcall(function() return _readfile(self.Folder .. "/autoload.json") end)
    if ok and raw and raw ~= "" then
        local ok2, d = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok2 and type(d) == "table" then return d end
    end
    return {Enabled = false, Path = nil}
end

function SM:SetAutoloadData(d)
    if not _isfolder(self.Folder) then _makefolder(self.Folder) end
    local ok, e = pcall(function() return HttpService:JSONEncode(d) end)
    if ok then _writefile(self.Folder .. "/autoload.json", e) end
end

function SM:LoadAutoloadConfig()
    if not self.Window then return false end
    local d = self:GetAutoloadData()
    if not d.Enabled or not d.Path then return false end
    local ok, fd = pcall(function() return HttpService:JSONDecode(_readfile(d.Path)) end)
    if ok and type(fd) == "table" then
        for k, v in pairs(fd) do
            if self.Window.ConfigElements[k] and self.Window.ConfigElements[k].Set then
                pcall(function() self.Window.ConfigElements[k].Set(v) end)
            end
        end
        Library:Notify({Title = "Autoload", Description = "Configuration loaded.", Duration = 3})
        return true
    end
    return false
end

function SM:BuildConfigTab(tab, folder)
    self:SetFolder(folder or self.Folder)
    if not tab or not tab.CreatePage then return end
    local Page = tab:CreatePage("Config")
    local UISection = Page:CreateSection("UI Settings")
    if self.Window then
        UISection:Toggle({
            Title = "Transparency",
            Desc = "Main window transparency 0.2",
            Value = false,
            Callback = function(s) self.Window:SetTransparency(s and 0.2 or 0) end
        })
    end
    local SaveSection = Page:CreateSection("Save Manager")
    SaveSection:AddConfigManager(self.Folder)
    return Page, UISection, SaveSection
end

-- ============================================================
-- WINDOW
-- ============================================================
function Library:CreateWindow(options)
    local cfg = {
        Title = "MarvenRiz UI",
        Subtitle = "Made By Zens",
        Size = UDim2.fromOffset(640, 500),
        SidebarWidth = 180,
        Accent = AccentColor,
        Logo = nil,
        LogoSize = 32,
        SphereText = false,
        SphereWords = "ZX",
        SphereImage = nil,
        SphereIconSize = 26,
    }

    if type(options) == "table" then
        cfg.Title = options.Title or cfg.Title
        cfg.Subtitle = options.Subtitle or cfg.Subtitle
        cfg.Size = options.Size or cfg.Size
        cfg.SidebarWidth = options.SideBarWidth or cfg.SidebarWidth
        cfg.Logo = options.Logo
        cfg.LogoSize = options.LogoSize or cfg.LogoSize
        cfg.SphereText = options.SphereText ~= nil and options.SphereText or cfg.SphereText
        cfg.SphereWords = options.SphereWords or cfg.SphereWords
        cfg.SphereImage = options.SphereImage
        cfg.SphereIconSize = options.SphereIconSize or cfg.SphereIconSize
        if options.AccentColor then
            if typeof(options.AccentColor) == "Color3" then
                cfg.Accent = options.AccentColor
            elseif type(options.AccentColor) == "string" then
                local ok, c = pcall(Color3.fromHex, options.AccentColor)
                if ok then cfg.Accent = c end
            end
        end
        if options.Map or options.MapId then
            SM:SetMap(options.Map or options.MapId, options.SaveFolder)
        end
    elseif type(options) == "string" then
        cfg.Title = options
    end

    AccentColor = cfg.Accent
    Theme.Accent = AccentColor

    local ScreenGui = Create("ScreenGui", {
        Name = "MarvenRiz_" .. HttpService:GenerateGUID(false),
        Parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    NotifContainer = Create("Frame", {
        Parent = ScreenGui,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 340, 1, -24),
        Position = UDim2.new(1, -356, 0, 12),
        ZIndex = 500,
    })
    Create("UIListLayout", {Parent = NotifContainer, VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})

    -- ============ INFO OVERLAY (FIXED LAYOUT) ============
    local InfoOverlay = Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Color3.fromRGB(5, 5, 8), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 400, Visible = false, Active = true})
    local InfoCard = Create("Frame", {Parent = InfoOverlay, BackgroundColor3 = Theme.Card, Size = UDim2.new(0, 440, 0, 360), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 401, BackgroundTransparency = 1, ClipsDescendants = false})
    Create("UICorner", {Parent = InfoCard, CornerRadius = UDim.new(0, 12)})
    Create("UIStroke", {Parent = InfoCard, Color = AccentColor, Thickness = 1.5, Transparency = 1})
    AddShadow(InfoCard, 0.7)
    local InfoScale = Create("UIScale", {Parent = InfoCard, Scale = 0.9})

    -- Padding tổng thể Info (rộng rãi để chữ không sát viền)
    local InfoPad = Create("UIPadding", {Parent = InfoCard, PaddingTop = UDim.new(0, 20), PaddingBottom = UDim.new(0, 20), PaddingLeft = UDim.new(0, 24), PaddingRight = UDim.new(0, 24)})

    -- Layout dọc: header → scroll
    local InfoLayout = Create("UIListLayout", {Parent = InfoCard, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 14)})

    local InfoHeader = Create("Frame", {Parent = InfoCard, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 1})
    local InfoTitle = Create("TextLabel", {Parent = InfoHeader, Text = "Feature Info", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd})
    local InfoClose = Create("TextButton", {Parent = InfoHeader, Text = "✕", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 32, 0, 32), Position = UDim2.new(1, -32, 0.5, -16), TextTransparency = 1, AutoButtonColor = false})
    AddBounce(InfoClose)
    InfoClose.MouseEnter:Connect(function() Tween(InfoClose, {TextColor3 = Theme.Danger}, 0.15) end)
    InfoClose.MouseLeave:Connect(function() Tween(InfoClose, {TextColor3 = SubTextColor}, 0.15) end)

    -- Scroll body — chiếm toàn bộ phần còn lại
    local InfoScroll = Create("ScrollingFrame", {
        Parent = InfoCard,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -44),
        LayoutOrder = 2,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = AccentColor,
        ScrollBarImageTransparency = 0.3,
        BorderSizePixel = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    })
    Create("UIPadding", {Parent = InfoScroll, PaddingRight = UDim.new(0, 8)})
    local InfoList = Create("UIListLayout", {Parent = InfoScroll, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12)})

    -- Description label — co giãn tự động, wrap đúng
    local InfoDesc = Create("TextLabel", {
        Parent = InfoScroll,
        Text = "",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = SubTextColor,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        TextTransparency = 1,
        LineHeight = 1.3,
        LayoutOrder = 1,
    })

    -- Example box — padding đúng, không đè chữ
    local InfoExample = Create("Frame", {
        Parent = InfoScroll,
        BackgroundColor3 = Color3.fromRGB(12, 12, 16),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        LayoutOrder = 2,
    })
    Create("UICorner", {Parent = InfoExample, CornerRadius = UDim.new(0, 8)})
    Create("UIStroke", {Parent = InfoExample, Color = Color3.fromRGB(48, 48, 60), Thickness = 1})
    Create("UIPadding", {Parent = InfoExample, PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)})
    local InfoExampleLabel = Create("TextLabel", {
        Parent = InfoExample,
        Text = "EXAMPLE",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = AccentColor,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
    })
    local InfoExampleText = Create("TextLabel", {
        Parent = InfoExample,
        Text = "",
        Font = Enum.Font.Code,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(220, 220, 230),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 20),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        TextTransparency = 1,
        LineHeight = 1.2,
    })

    local function OpenInfo(d)
        InfoTitle.Text = d.Title or "Information"
        InfoDesc.Text = d.Description or ""
        if d.Example and d.Example ~= "" then
            InfoExampleText.Text = d.Example
            InfoExample.Visible = true
            InfoExampleText.TextTransparency = 0
            InfoExampleLabel.TextTransparency = 0
        else
            InfoExample.Visible = false
        end
        InfoOverlay.Visible = true
        Tween(InfoOverlay, {BackgroundTransparency = 0.5}, 0.3)
        Tween(InfoCard, {BackgroundTransparency = 0}, 0.3)
        Tween(InfoCard:FindFirstChild("UIStroke"), {Transparency = 0.3}, 0.3)
        Tween(InfoScale, {Scale = 1}, 0.3)
        Tween(InfoTitle, {TextTransparency = 0}, 0.3)
        Tween(InfoClose, {TextTransparency = 0}, 0.3)
        Tween(InfoDesc, {TextTransparency = 0}, 0.3)
        if InfoExample.Visible then
            Tween(InfoExampleLabel, {TextTransparency = 0}, 0.3)
            Tween(InfoExampleText, {TextTransparency = 0}, 0.3)
        end
    end

    InfoClose.MouseButton1Click:Connect(function()
        Tween(InfoOverlay, {BackgroundTransparency = 1}, 0.25)
        Tween(InfoCard, {BackgroundTransparency = 1}, 0.25)
        Tween(InfoCard:FindFirstChild("UIStroke"), {Transparency = 1}, 0.25)
        Tween(InfoScale, {Scale = 0.9}, 0.25)
        Tween(InfoTitle, {TextTransparency = 1}, 0.25)
        Tween(InfoClose, {TextTransparency = 1}, 0.25)
        Tween(InfoDesc, {TextTransparency = 1}, 0.25)
        Tween(InfoExampleLabel, {TextTransparency = 1}, 0.25)
        Tween(InfoExampleText, {TextTransparency = 1}, 0.25)
        task.wait(0.25)
        InfoOverlay.Visible = false
    end)

    local function AddInfoIcon(parent, pos, data)
        if not data then return end
        local b = Create("TextButton", {Parent = parent, Text = "?", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = SubTextColor, BackgroundColor3 = Color3.fromRGB(40, 40, 48), Size = UDim2.new(0, 18, 0, 18), Position = pos, AutoButtonColor = false, ZIndex = 5})
        Create("UICorner", {Parent = b, CornerRadius = UDim.new(1, 0)})
        AddBounce(b)
        b.MouseEnter:Connect(function() Tween(b, {TextColor3 = Color3.fromRGB(255,255,255), BackgroundColor3 = AccentColor}, 0.15) end)
        b.MouseLeave:Connect(function() Tween(b, {TextColor3 = SubTextColor, BackgroundColor3 = Color3.fromRGB(40, 40, 48)}, 0.15) end)
        b.MouseButton1Click:Connect(function() OpenInfo(data) end)
    end

    -- ============ MAIN WINDOW ============
    local Main = Create("Frame", {Parent = ScreenGui, BackgroundColor3 = BackgroundColor, Size = cfg.Size, Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ClipsDescendants = false})
    local MainScale = Create("UIScale", {Parent = Main, Scale = 0.85})
    Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 12)})
    Create("UIStroke", {Parent = Main, Color = Color3.fromRGB(45, 45, 58), Thickness = 1})
    AddShadow(Main, 0.55)
    Tween(MainScale, {Scale = 1}, 0.4)
    Tween(Main, {BackgroundTransparency = 0}, 0.4)

    -- Background gradient nhẹ cho main
    local MainBgGrad = Create("Frame", {Parent = Main, BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 0})
    Create("UIGradient", {Parent = MainBgGrad, Color = ColorSequence.new(Theme.Background, Theme.BackgroundGrad), Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 1)})})
    Create("UICorner", {Parent = MainBgGrad, CornerRadius = UDim.new(0, 12)})

    -- Top bar
    local TopBar = Create("Frame", {Parent = Main, BackgroundColor3 = Theme.TopBar, Size = UDim2.new(1, 0, 0, 56), Active = true, ZIndex = 2})
    Create("UICorner", {Parent = TopBar, CornerRadius = UDim.new(0, 12)})
    local TopBarFill = Create("Frame", {Parent = TopBar, BackgroundColor3 = Theme.TopBar, Size = UDim2.new(1, 0, 1, 12), Position = UDim2.new(0, 0, 0, 0), ZIndex = 2})
    local TopBorder = Create("Frame", {Parent = TopBar, BackgroundColor3 = Color3.fromRGB(35, 35, 45), Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), ZIndex = 3})
    MakeDraggable(TopBar, Main)

    local titleOffset = 20
    if cfg.Logo then
        Create("ImageLabel", {Parent = TopBar, BackgroundTransparency = 1, Size = UDim2.new(0, cfg.LogoSize, 0, cfg.LogoSize), Position = UDim2.new(0, 18, 0.5, -cfg.LogoSize/2), Image = cfg.Logo, ScaleType = Enum.ScaleType.Fit, ZIndex = 3})
        titleOffset = 18 + cfg.LogoSize + 12
    end

    local titleBox = Create("Frame", {Parent = TopBar, BackgroundTransparency = 1, Size = UDim2.new(0, 240, 1, 0), Position = UDim2.new(0, titleOffset, 0, 0), ZIndex = 3})
    Create("TextLabel", {Parent = titleBox, Text = cfg.Title, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 10), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
    Create("TextLabel", {Parent = titleBox, Text = cfg.Subtitle, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = AccentColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})

    -- Global search
    local searchBox = Create("Frame", {Parent = TopBar, BackgroundColor3 = Theme.ElementBg, Size = UDim2.new(0, 250, 0, 34), Position = UDim2.new(1, -340, 0.5, -17), ZIndex = 3})
    Create("UICorner", {Parent = searchBox, CornerRadius = UDim.new(0, 8)})
    Create("UIStroke", {Parent = searchBox, Color = Color3.fromRGB(45, 45, 58), Thickness = 1})
    Create("ImageLabel", {Parent = searchBox, BackgroundTransparency = 1, Image = "rbxassetid://6031154871", ImageColor3 = SubTextColor, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 10, 0.5, -7), ZIndex = 3})
    local searchInput = Create("TextBox", {Parent = searchBox, BackgroundTransparency = 1, Size = UDim2.new(1, -36, 1, 0), Position = UDim2.new(0, 32, 0, 0), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, PlaceholderText = "Search features...", PlaceholderColor3 = SubTextColor, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 3})

    local closeBtn = Create("TextButton", {Parent = TopBar, Text = "✕", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 44, 1, 0), Position = UDim2.new(1, -48, 0, 0), AutoButtonColor = false, ZIndex = 3})
    local minBtn = Create("TextButton", {Parent = TopBar, Text = "—", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 44, 1, 0), Position = UDim2.new(1, -92, 0, 0), AutoButtonColor = false, ZIndex = 3})
    closeBtn.MouseEnter:Connect(function() Tween(closeBtn, {TextColor3 = Theme.Danger}, 0.15) end)
    closeBtn.MouseLeave:Connect(function() Tween(closeBtn, {TextColor3 = SubTextColor}, 0.15) end)
    minBtn.MouseEnter:Connect(function() Tween(minBtn, {TextColor3 = TextColor}, 0.15) end)
    minBtn.MouseLeave:Connect(function() Tween(minBtn, {TextColor3 = SubTextColor}, 0.15) end)

    -- Sidebar
    local Sidebar = Create("Frame", {Parent = Main, BackgroundColor3 = Theme.Sidebar, Size = UDim2.new(0, cfg.SidebarWidth, 1, -56), Position = UDim2.new(0, 0, 0, 56), ZIndex = 2})
    Create("UICorner", {Parent = Sidebar, CornerRadius = UDim.new(0, 12)})
    local SidebarFill = Create("Frame", {Parent = Sidebar, BackgroundColor3 = Theme.Sidebar, Size = UDim2.new(1, 12, 1, 0), Position = UDim2.new(0, 0, 0, 0), ZIndex = 2})

    local tabSearch = Create("TextBox", {Parent = Sidebar, BackgroundColor3 = Theme.ElementBg, Size = UDim2.new(1, -24, 0, 32), Position = UDim2.new(0, 12, 0, 12), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, PlaceholderText = "Search tabs...", PlaceholderColor3 = SubTextColor, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 3})
    Create("UIPadding", {Parent = tabSearch, PaddingLeft = UDim.new(0, 10)})
    Create("UICorner", {Parent = tabSearch, CornerRadius = UDim.new(0, 8)})
    Create("UIStroke", {Parent = tabSearch, Color = Color3.fromRGB(45, 45, 58), Thickness = 1})

    local TabList = Create("ScrollingFrame", {Parent = Sidebar, BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, -56), Position = UDim2.new(0, 8, 0, 56), ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 3})
    Create("UIListLayout", {Parent = TabList, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})

    -- Content
    local Content = Create("Frame", {Parent = Main, BackgroundColor3 = BackgroundColor, BackgroundTransparency = 1, Size = UDim2.new(1, -cfg.SidebarWidth, 1, -56), Position = UDim2.new(0, cfg.SidebarWidth, 0, 56), ZIndex = 2})

    -- Sphere (minimize)
    local Sphere = Create("ImageButton", {Parent = ScreenGui, BackgroundColor3 = Theme.Sidebar, BackgroundTransparency = 0.1, Size = UDim2.new(0, 56, 0, 56), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, AutoButtonColor = false, ClipsDescendants = true, ZIndex = 300})
    Create("UICorner", {Parent = Sphere, CornerRadius = UDim.new(1, 0)})
    Create("UIStroke", {Parent = Sphere, Color = AccentColor, Thickness = 2})
    AddShadow(Sphere, 0.5)
    local SphereImg = Create("ImageLabel", {Parent = Sphere, BackgroundTransparency = 1, Size = UDim2.new(0, cfg.SphereIconSize, 0, cfg.SphereIconSize), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), Image = cfg.SphereImage or "", ImageTransparency = 1, Visible = (not cfg.SphereText and cfg.SphereImage ~= nil)})
    local SphereTxt = Create("TextLabel", {Parent = Sphere, Text = cfg.SphereWords, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = AccentColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), TextTransparency = 1, Visible = cfg.SphereText})
    MakeDraggable(Sphere, Sphere)

    -- Close popup
    local Popup = Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 300, Visible = false, Active = true})
    local PopupCard = Create("Frame", {Parent = Popup, BackgroundColor3 = Theme.Card, Size = UDim2.new(0, 380, 0, 200), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 301, BackgroundTransparency = 1})
    Create("UICorner", {Parent = PopupCard, CornerRadius = UDim.new(0, 14)})
    Create("UIStroke", {Parent = PopupCard, Color = Color3.fromRGB(55, 55, 68), Thickness = 1, Transparency = 1})
    AddShadow(PopupCard, 0.5)
    local PopupScale = Create("UIScale", {Parent = PopupCard, Scale = 0.85})
    Create("UIPadding", {Parent = PopupCard, PaddingTop = UDim.new(0, 24), PaddingBottom = UDim.new(0, 24), PaddingLeft = UDim.new(0, 28), PaddingRight = UDim.new(0, 28)})

    local PopupTitle = Create("TextLabel", {Parent = PopupCard, Text = "Exit Application", Font = Enum.Font.GothamBold, TextSize = 19, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
    local PopupDesc = Create("TextLabel", {Parent = PopupCard, Text = "Are you sure you want to close? Unsaved configurations may be lost.", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 60), Position = UDim2.new(0, 0, 0, 42), TextTransparency = 1, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, LineHeight = 1.25})
    local PopupYes = Create("TextButton", {Parent = PopupCard, Text = "Confirm", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Theme.Danger, Size = UDim2.new(0.5, -8, 0, 40), Position = UDim2.new(0, 0, 1, -40), BackgroundTransparency = 1, TextTransparency = 1, AutoButtonColor = false})
    Create("UICorner", {Parent = PopupYes, CornerRadius = UDim.new(0, 8)})
    AddBounce(PopupYes)
    local PopupNo = Create("TextButton", {Parent = PopupCard, Text = "Cancel", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TextColor, BackgroundColor3 = Color3.fromRGB(45, 45, 58), Size = UDim2.new(0.5, -8, 0, 40), Position = UDim2.new(0.5, 8, 1, -40), BackgroundTransparency = 1, TextTransparency = 1, AutoButtonColor = false})
    Create("UICorner", {Parent = PopupNo, CornerRadius = UDim.new(0, 8)})
    AddBounce(PopupNo)

    local Window = {
        CurrentTab = nil,
        Tabs = {},
        AllCards = {},
        MainFrame = Main,
        CurrentTransparency = 0,
        ConfigElements = {},
    }

    function Window:SetTransparency(v)
        Window.CurrentTransparency = v
        if Main.Visible then Tween(Main, {BackgroundTransparency = v}, 0.3) end
    end

    function Window:SetMap(m)
        SM:SetMap(m)
    end

    closeBtn.MouseButton1Click:Connect(function()
        Popup.Visible = true
        Tween(Popup, {BackgroundTransparency = 0.5}, 0.25)
        Tween(PopupCard, {BackgroundTransparency = 0}, 0.25)
        Tween(PopupCard:FindFirstChild("UIStroke"), {Transparency = 0}, 0.25)
        Tween(PopupScale, {Scale = 1}, 0.25)
        Tween(PopupTitle, {TextTransparency = 0}, 0.25)
        Tween(PopupDesc, {TextTransparency = 0}, 0.25)
        Tween(PopupYes, {BackgroundTransparency = 0, TextTransparency = 0}, 0.25)
        Tween(PopupNo, {BackgroundTransparency = 0, TextTransparency = 0}, 0.25)
    end)

    PopupYes.MouseButton1Click:Connect(function()
        Tween(MainScale, {Scale = 0.85}, 0.25)
        Tween(Main, {BackgroundTransparency = 1}, 0.25)
        task.wait(0.28)
        ScreenGui:Destroy()
    end)

    PopupNo.MouseButton1Click:Connect(function()
        Tween(Popup, {BackgroundTransparency = 1}, 0.25)
        Tween(PopupCard, {BackgroundTransparency = 1}, 0.25)
        Tween(PopupCard:FindFirstChild("UIStroke"), {Transparency = 1}, 0.25)
        Tween(PopupScale, {Scale = 0.85}, 0.25)
        Tween(PopupTitle, {TextTransparency = 1}, 0.25)
        Tween(PopupDesc, {TextTransparency = 1}, 0.25)
        Tween(PopupYes, {BackgroundTransparency = 1, TextTransparency = 1}, 0.25)
        Tween(PopupNo, {BackgroundTransparency = 1, TextTransparency = 1}, 0.25)
        task.wait(0.25)
        Popup.Visible = false
    end)

    minBtn.MouseButton1Click:Connect(function()
        Tween(MainScale, {Scale = 0}, 0.3)
        Tween(Main, {BackgroundTransparency = 1}, 0.3)
        task.wait(0.25)
        Main.Visible = false
        Sphere.Visible = true
        Tween(Sphere, {Size = UDim2.new(0, 56, 0, 56)}, 0.3)
        if not cfg.SphereText and cfg.SphereImage then Tween(SphereImg, {ImageTransparency = 0}, 0.3) end
        if cfg.SphereText then Tween(SphereTxt, {TextTransparency = 0}, 0.3) end
    end)

    Sphere.MouseButton1Click:Connect(function()
        Tween(Sphere, {Size = UDim2.new(0, 0, 0, 0)}, 0.25)
        if not cfg.SphereText and cfg.SphereImage then Tween(SphereImg, {ImageTransparency = 1}, 0.25) end
        if cfg.SphereText then Tween(SphereTxt, {TextTransparency = 1}, 0.25) end
        task.wait(0.15)
        Sphere.Visible = false
        Main.Visible = true
        Tween(MainScale, {Scale = 1}, 0.3)
        Tween(Main, {BackgroundTransparency = Window.CurrentTransparency}, 0.3)
    end)

    tabSearch:GetPropertyChangedSignal("Text"):Connect(function()
        local q = tabSearch.Text:lower()
        for _, tab in ipairs(Window.Tabs) do
            tab.Button.Visible = (q == "" or string.find(tab.Txt.Text:lower(), q, 1, true) ~= nil)
        end
    end)

    local searchPending = false
    searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        if searchPending then return end
        searchPending = true
        task.defer(function()
            local q = searchInput.Text:lower()
            if not Window.CurrentTab or not Window.CurrentTab.CurrentPage then
                searchPending = false
                return
            end
            local page = Window.CurrentTab.CurrentPage

            if q == "" then
                for _, data in ipairs(Window.AllCards) do
                    if data.Tab == Window.CurrentTab and data.Mounted then
                        data.Card.Parent = data.OrigParent
                        data.Card.Visible = true
                    end
                end
            else
                local placeLeft = true
                for _, data in ipairs(Window.AllCards) do
                    if data.Tab == Window.CurrentTab then
                        if not data.Mounted then
                            data.Card.Visible = false
                        else
                            if not data.SearchIndex then
                                data.SearchIndex = BuildSearchIndex(data.Card)
                            end
                            if string.find(data.SearchIndex, q, 1, true) then
                                data.Card.Parent = placeLeft and page.LeftCol or page.RightCol
                                placeLeft = not placeLeft
                                data.Card.Visible = true
                            else
                                data.Card.Visible = false
                            end
                        end
                    end
                end
            end
            searchPending = false
        end)
    end)

    -- ============ CREATE TAB ============
    function Window:CreateTab(name, isDefault, isLocked)
        local isWhitelisted = false
        local lp = game:GetService("Players").LocalPlayer
        if lp then
            for _, u in ipairs(Library.WhitelistedUsers) do
                if lp.Name == u or lp.DisplayName == u then isWhitelisted = true break end
            end
        end

        local TabBtn = Create("TextButton", {Parent = TabList, Text = "", BackgroundColor3 = Color3.fromRGB(22, 22, 28), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 42), AutoButtonColor = false})
        Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0, 8)})
        AddBounce(TabBtn, 0.98)
        local Indicator = Create("Frame", {Parent = TabBtn, BackgroundColor3 = isLocked and Theme.Warning or AccentColor, Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5)})
        Create("UICorner", {Parent = Indicator, CornerRadius = UDim.new(1, 0)})
        local Txt = Create("TextLabel", {Parent = TabBtn, Text = name, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 18, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})

        if isLocked then
            Create("ImageLabel", {Parent = TabBtn, Image = "rbxassetid://6031082533", ImageColor3 = Theme.Warning, BackgroundTransparency = 1, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -26, 0.5, -7)})
        end

        local TabContent = Create("Frame", {Parent = Content, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false})

        local PageNav = Create("ScrollingFrame", {
            Parent = TabContent,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 46),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 0,
            BorderSizePixel = 0,
            ScrollingDirection = Enum.ScrollingDirection.X,
            ScrollingEnabled = true,
            ClipsDescendants = true,
            AutomaticCanvasSize = Enum.AutomaticSize.X,
        })
        Create("UIPadding", {Parent = PageNav, PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)})

        local PageNavInner = Create("Frame", {Parent = PageNav, BackgroundTransparency = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X})
        Create("UIListLayout", {Parent = PageNavInner, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder})

        local PageContainer = Create("Frame", {Parent = TabContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -46), Position = UDim2.new(0, 0, 0, 46)})

        PageNav.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseWheel then
                local maxX = math.max(0, PageNavInner.AbsoluteSize.X - PageNav.AbsoluteSize.X + 28)
                PageNav.CanvasPosition = Vector2.new(math.clamp(PageNav.CanvasPosition.X - i.Position.Z * 40, 0, maxX), 0)
            end
        end)

        local TabConfig = {Button = TabBtn, Content = TabContent, Indicator = Indicator, Txt = Txt, Pages = {}, CurrentPage = nil}
        table.insert(Window.Tabs, TabConfig)

        local switching = false
        TabBtn.MouseButton1Click:Connect(function()
            if isLocked and not isWhitelisted then
                Library:Notify({Title = "Locked", Description = "This tab is whitelist-only.", Duration = 3})
                return
            end
            if switching or Window.CurrentTab == TabConfig then return end
            switching = true
            task.delay(0.35, function() switching = false end)

            if Window.CurrentTab then
                Tween(Window.CurrentTab.Button, {BackgroundTransparency = 1}, 0.15)
                Tween(Window.CurrentTab.Indicator, {Size = UDim2.new(0, 3, 0, 0)}, 0.15)
                Tween(Window.CurrentTab.Txt, {TextColor3 = SubTextColor}, 0.15)
                Window.CurrentTab.Content.Visible = false
                for _, data in ipairs(Window.AllCards) do
                    if data.Tab == Window.CurrentTab and data.Mounted then
                        data.Card.Visible = false
                    end
                end
            end

            Window.CurrentTab = TabConfig
            TabConfig.Content.Visible = true
            Tween(TabBtn, {BackgroundTransparency = 0}, 0.15)
            Tween(Indicator, {Size = UDim2.new(0, 3, 0, 22)}, 0.25)
            Tween(Txt, {TextColor3 = TextColor}, 0.15)

            if #TabConfig.Pages > 0 then
                local first = TabConfig.Pages[1]
                for _, data in ipairs(Window.AllCards) do
                    if data.Page == first and not data.Mounted then
                        data.Mounted = true
                        data.Card.Parent = data.OrigParent
                        data.Card.Visible = true
                        data.SearchIndex = nil
                    end
                end
                if TabConfig.CurrentPage == nil then
                    TabConfig.CurrentPage = first
                    first.Scroll.Visible = true
                    first.Btn.TextColor3 = TextColor
                    first.Btn.BackgroundTransparency = 0
                    first.Highlight.Size = UDim2.new(1, 0, 0, 3)
                    first.Highlight.BackgroundTransparency = 0
                end
            end

            if TabConfig.CurrentPage then
                for _, data in ipairs(Window.AllCards) do
                    if data.Page == TabConfig.CurrentPage and data.Mounted then
                        data.Card.Visible = true
                    end
                end
            end
        end)

        function TabConfig:CreatePage(pageName)
            local PageBtn = Create("TextButton", {
                Parent = PageNavInner,
                Text = pageName,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = SubTextColor,
                BackgroundColor3 = Color3.fromRGB(22, 22, 28),
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 0, 32),
                AutomaticSize = Enum.AutomaticSize.X,
                AutoButtonColor = false,
            })
            Create("UIPadding", {Parent = PageBtn, PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)})
            Create("UICorner", {Parent = PageBtn, CornerRadius = UDim.new(0, 8)})
            local PageHighlight = Create("Frame", {Parent = PageBtn, BackgroundColor3 = AccentColor, Size = UDim2.new(0, 0, 0, 3), Position = UDim2.new(0.5, 0, 1, -4), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1})
            Create("UICorner", {Parent = PageHighlight, CornerRadius = UDim.new(1, 0)})

            local PageScroll = Create("ScrollingFrame", {
                Parent = PageContainer,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -24, 1, -20),
                Position = UDim2.new(0, 12, 0, 10),
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = Color3.fromRGB(70, 70, 85),
                ScrollBarImageTransparency = 0.4,
                Visible = false,
                BorderSizePixel = 0,
            })
            Create("UIPadding", {Parent = PageScroll, PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4)})

            local LeftCol = Create("Frame", {Parent = PageScroll, BackgroundTransparency = 1, Size = UDim2.new(0.5, -7, 1, 0)})
            local RightCol = Create("Frame", {Parent = PageScroll, BackgroundTransparency = 1, Size = UDim2.new(0.5, -7, 1, 0), Position = UDim2.new(0.5, 7, 0, 0)})

            local L_Layout = Create("UIListLayout", {Parent = LeftCol, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 14)})
            local R_Layout = Create("UIListLayout", {Parent = RightCol, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 14)})

            local function updateCanvas()
                PageScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(L_Layout.AbsoluteContentSize.Y, R_Layout.AbsoluteContentSize.Y) + 28)
            end
            L_Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
            R_Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

            local PageObj = {Scroll = PageScroll, Btn = PageBtn, Highlight = PageHighlight, Left = true, LeftCol = LeftCol, RightCol = RightCol}
            table.insert(TabConfig.Pages, PageObj)

            local pageSwitching = false
            PageBtn.MouseButton1Click:Connect(function()
                if pageSwitching or TabConfig.CurrentPage == PageObj then return end
                pageSwitching = true

                for _, data in ipairs(Window.AllCards) do
                    if data.Page == PageObj and not data.Mounted then
                        data.Mounted = true
                        data.Card.Parent = data.OrigParent
                        data.Card.Visible = true
                        data.SearchIndex = nil
                    end
                end

                if TabConfig.CurrentPage then
                    Tween(TabConfig.CurrentPage.Btn, {TextColor3 = SubTextColor, BackgroundTransparency = 1}, 0.15)
                    Tween(TabConfig.CurrentPage.Highlight, {Size = UDim2.new(0, 0, 0, 3), BackgroundTransparency = 1}, 0.15)
                    TabConfig.CurrentPage.Scroll.Visible = false
                    for _, data in ipairs(Window.AllCards) do
                        if data.Page == TabConfig.CurrentPage and data.Mounted then
                            data.Card.Visible = false
                        end
                    end
                end

                TabConfig.CurrentPage = PageObj
                PageObj.Scroll.Visible = true
                Tween(PageBtn, {TextColor3 = TextColor, BackgroundTransparency = 0}, 0.15)
                Tween(PageHighlight, {Size = UDim2.new(1, 0, 0, 3), BackgroundTransparency = 0}, 0.25)

                for _, data in ipairs(Window.AllCards) do
                    if data.Page == PageObj and data.Mounted then
                        data.Card.Visible = true
                    end
                end

                task.defer(function()
                    local btnPos = PageBtn.AbsolutePosition.X - PageNav.AbsolutePosition.X
                    local btnW = PageBtn.AbsoluteSize.X
                    local viewW = PageNav.AbsoluteSize.X
                    local maxX = math.max(0, PageNavInner.AbsoluteSize.X - viewW + 28)
                    local targetX = math.clamp(btnPos - (viewW - btnW) / 2, 0, maxX)
                    TweenService:Create(PageNav, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {CanvasPosition = Vector2.new(targetX, 0)}):Play()
                end)

                task.delay(0.3, function() pageSwitching = false end)
            end)

            if #TabConfig.Pages == 1 and not isLocked then
                TabConfig.CurrentPage = PageObj
                PageObj.Scroll.Visible = true
                PageBtn.TextColor3 = TextColor
                PageBtn.BackgroundTransparency = 0
                PageHighlight.Size = UDim2.new(1, 0, 0, 3)
                PageHighlight.BackgroundTransparency = 0
            end

            function PageObj:CreateSection(name, side)
                local targetCol
                if side == "Left" or side == "left" then targetCol = LeftCol
                elseif side == "Right" or side == "right" then targetCol = RightCol
                else targetCol = PageObj.Left and LeftCol or RightCol; PageObj.Left = not PageObj.Left end

                -- Card với header gradient
                local CardFrame = Create("Frame", {
                    Parent = nil,
                    BackgroundColor3 = CardColor,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ClipsDescendants = true,
                    Visible = false,
                })
                Create("UICorner", {Parent = CardFrame, CornerRadius = UDim.new(0, 10)})
                Create("UIStroke", {Parent = CardFrame, Color = Color3.fromRGB(42, 42, 54), Thickness = 1})

                table.insert(Window.AllCards, {
                    Card = CardFrame, OrigParent = targetCol, Tab = TabConfig,
                    Page = PageObj, Mounted = false, SearchIndex = nil
                })

                -- Header có accent bar
                local Header = Create("Frame", {Parent = CardFrame, BackgroundColor3 = Theme.CardHeader, Size = UDim2.new(1, 0, 0, 40)})
                Create("UICorner", {Parent = Header, CornerRadius = UDim.new(0, 10)})
                local HeaderFill = Create("Frame", {Parent = Header, BackgroundColor3 = Theme.CardHeader, Size = UDim2.new(1, 0, 1, 10), Position = UDim2.new(0, 0, 0, 0)})
                local HeaderBottomLine = Create("Frame", {Parent = Header, BackgroundColor3 = Color3.fromRGB(35, 35, 46), Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1)})
                local AccentBar = Create("Frame", {Parent = Header, BackgroundColor3 = AccentColor, Size = UDim2.new(0, 3, 0, 20), Position = UDim2.new(0, 14, 0.5, -10)})
                Create("UICorner", {Parent = AccentBar, CornerRadius = UDim.new(1, 0)})
                Create("TextLabel", {Parent = Header, Text = name, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 26, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})

                local Items = Create("Frame", {Parent = CardFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 40), AutomaticSize = Enum.AutomaticSize.Y})
                Create("UIPadding", {Parent = Items, PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)})
                Create("UIListLayout", {Parent = Items, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12)})

                local Elements = {}

                -- ===== BUTTON =====
                function Elements:AddButton(title, cb, info)
                    local wrap = Create("Frame", {Parent = Items, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36)})
                    local btn = Create("TextButton", {Parent = wrap, Text = title, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = Theme.ElementBg, Size = UDim2.new(1, -28, 1, 0), AutoButtonColor = false})
                    Create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})
                    Create("UIStroke", {Parent = btn, Color = Theme.ElementStroke, Thickness = 1})
                    AddBounce(btn)
                    btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = HoverColor}, 0.15) end)
                    btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = Theme.ElementBg}, 0.15) end)
                    btn.MouseButton1Click:Connect(function() if cb then cb() end end)
                    AddInfoIcon(wrap, UDim2.new(1, -24, 0.5, -9), info)
                end

                function Elements:AddCopyButton(title, text, info)
                    local wrap = Create("Frame", {Parent = Items, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36)})
                    local btn = Create("TextButton", {Parent = wrap, Text = title, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = Theme.ElementBg, Size = UDim2.new(1, -28, 1, 0), AutoButtonColor = false})
                    Create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})
                    Create("UIStroke", {Parent = btn, Color = Theme.ElementStroke, Thickness = 1})
                    AddBounce(btn)
                    btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = HoverColor}, 0.15) end)
                    btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = Theme.ElementBg}, 0.15) end)
                    btn.MouseButton1Click:Connect(function()
                        SafeCopyToClipboard(text)
                        local old = btn.Text
                        btn.Text = "✓ Copied!"
                        Tween(btn, {TextColor3 = Theme.Success}, 0.15)
                        task.wait(1.3)
                        if btn.Parent then btn.Text = old; Tween(btn, {TextColor3 = TextColor}, 0.15) end
                    end)
                    AddInfoIcon(wrap, UDim2.new(1, -24, 0.5, -9), info)
                end

                -- ===== PARAGRAPH (fix layout) =====
                function Elements:AddParagraph(title, content, info)
                    local has = title ~= nil and title ~= ""
                    local wrap = Create("Frame", {Parent = Items, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y})
                    local box = Create("Frame", {Parent = wrap, BackgroundColor3 = Theme.ElementBg, Size = UDim2.new(1, -28, 0, 0), AutomaticSize = Enum.AutomaticSize.Y})
                    Create("UICorner", {Parent = box, CornerRadius = UDim.new(0, 8)})
                    Create("UIStroke", {Parent = box, Color = Theme.ElementStroke, Thickness = 1})
                    Create("UIPadding", {Parent = box, PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 36)})
                    Create("UIListLayout", {Parent = box, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})

                    local titleLbl = Create("TextLabel", {Parent = box, Text = title or "", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Visible = has, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, LineHeight = 1.25, LayoutOrder = 1})
                    local contentLbl = Create("TextLabel", {Parent = box, Text = content or "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, LineHeight = 1.3, LayoutOrder = 2})
                    AddInfoIcon(box, UDim2.new(1, -30, 0, 12), info)

                    local h = {}
                    h.SetTitle = function(_, t)
                        if type(_) ~= "table" then t = _ end
                        local show = t ~= nil and t ~= ""
                        titleLbl.Text = t or ""
                        titleLbl.Visible = show
                    end
                    h.SetContent = function(_, c)
                        if type(_) ~= "table" then c = _ end
                        contentLbl.Text = c or ""
                    end
                    return h
                end

                -- ===== TOGGLE =====
                function Elements:AddToggle(title, default, cb, info)
                    local state = default or false
                    local wrap = Create("Frame", {Parent = Items, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32)})
                    Create("TextLabel", {Parent = wrap, Text = title, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -90, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
                    local lever = Create("TextButton", {Parent = wrap, Text = "", BackgroundColor3 = state and AccentColor or Color3.fromRGB(48, 48, 60), Size = UDim2.new(0, 42, 0, 22), Position = UDim2.new(1, -52, 0.5, -11), AutoButtonColor = false})
                    Create("UICorner", {Parent = lever, CornerRadius = UDim.new(1, 0)})
                    AddBounce(lever, 0.94)
                    local knob = Create("Frame", {Parent = lever, BackgroundColor3 = Color3.fromRGB(255, 255, 255), Size = UDim2.new(0, 18, 0, 18), Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)})
                    Create("UICorner", {Parent = knob, CornerRadius = UDim.new(1, 0)})
                    local function set(v)
                        state = v
                        Tween(lever, {BackgroundColor3 = state and AccentColor or Color3.fromRGB(48, 48, 60)}, 0.25)
                        Tween(knob, {Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}, 0.25)
                        if cb then cb(state) end
                    end
                    lever.MouseButton1Click:Connect(function() set(not state) end)
                    AddInfoIcon(wrap, UDim2.new(1, -78, 0.5, -9), info)
                    if cb then cb(state) end
                    Window.ConfigElements[title] = {Set = set, Get = function() return state end}
                end

                -- ===== SLIDER =====
                function Elements:AddSlider(title, min, max, default, cb, info)
                    local val = default or min
                    local wrap = Create("Frame", {Parent = Items, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 54)})
                    Create("TextLabel", {Parent = wrap, Text = title, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -70, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
                    local valTxt = Create("TextLabel", {Parent = wrap, Text = tostring(val), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = AccentColor, BackgroundTransparency = 1, Size = UDim2.new(0, 50, 0, 18), Position = UDim2.new(1, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Right})
                    local track = Create("Frame", {Parent = wrap, BackgroundColor3 = Theme.ElementBg, Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 32)})
                    Create("UICorner", {Parent = track, CornerRadius = UDim.new(1, 0)})
                    Create("UIStroke", {Parent = track, Color = Theme.ElementStroke, Thickness = 1})
                    local fill = Create("Frame", {Parent = track, BackgroundColor3 = AccentColor, Size = UDim2.new((val-min)/(max-min), 0, 1, 0)})
                    Create("UICorner", {Parent = fill, CornerRadius = UDim.new(1, 0)})
                    local knob = Create("Frame", {Parent = fill, BackgroundColor3 = Color3.fromRGB(255, 255, 255), Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -8, 0.5, -8)})
                    Create("UICorner", {Parent = knob, CornerRadius = UDim.new(1, 0)})
                    Create("UIStroke", {Parent = knob, Color = AccentColor, Thickness = 2})

                    local function set(v)
                        val = math.clamp(v, min, max)
                        valTxt.Text = tostring(val)
                        Tween(fill, {Size = UDim2.new((val-min)/(max-min), 0, 1, 0)}, 0.1)
                        if cb then cb(val) end
                    end
                    local drag = false
                    knob.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true end end)
                    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end)
                    UserInputService.InputChanged:Connect(function(i)
                        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                            local p = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                            set(math.floor(min + (max - min) * p))
                        end
                    end)
                    AddInfoIcon(wrap, UDim2.new(1, -70, 0, 0), info)
                    if cb then cb(val) end
                    Window.ConfigElements[title] = {Set = set, Get = function() return val end}
                end

                -- ===== DROPDOWN =====
                function Elements:AddDropdown(title, options, isMulti, default, cb, info)
                    local selected
                    if isMulti then selected = (type(default) == "table") and default or {}
                    else selected = (default ~= nil) and default or (options[1]) end
                    local dropped = false
                    local btns, vals = {}, {}

                    local wrap = Create("Frame", {Parent = Items, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 58), ClipsDescendants = true})
                    Create("TextLabel", {Parent = wrap, Text = title, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -28, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})

                    local main = Create("TextButton", {Parent = wrap, Text = "Select...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = Theme.ElementBg, Size = UDim2.new(1, -28, 0, 32), Position = UDim2.new(0, 0, 0, 24), AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left})
                    Create("UIPadding", {Parent = main, PaddingLeft = UDim.new(0, 12)})
                    Create("UICorner", {Parent = main, CornerRadius = UDim.new(0, 6)})
                    Create("UIStroke", {Parent = main, Color = Theme.ElementStroke, Thickness = 1})
                    AddBounce(main, 0.98)
                    Create("TextLabel", {Parent = main, Text = "▼", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -26, 0, 0), Name = "Arrow"})

                    local search = Create("TextBox", {Parent = wrap, PlaceholderText = "Search...", PlaceholderColor3 = SubTextColor, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = Color3.fromRGB(12, 12, 16), Size = UDim2.new(1, -28, 0, 28), Position = UDim2.new(0, 0, 0, 60), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Visible = false})
                    Create("UIPadding", {Parent = search, PaddingLeft = UDim.new(0, 10)})
                    Create("UICorner", {Parent = search, CornerRadius = UDim.new(0, 6)})
                    Create("UIStroke", {Parent = search, Color = Theme.ElementStroke, Thickness = 1})

                    local list = Create("ScrollingFrame", {Parent = wrap, BackgroundColor3 = Theme.ElementBg, Size = UDim2.new(1, -28, 0, 150), Position = UDim2.new(0, 0, 0, 92), CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.fromRGB(80, 80, 95), BorderSizePixel = 0})
                    Create("UICorner", {Parent = list, CornerRadius = UDim.new(0, 6)})
                    Create("UIStroke", {Parent = list, Color = Theme.ElementStroke, Thickness = 1})
                    local ll = Create("UIListLayout", {Parent = list, SortOrder = Enum.SortOrder.LayoutOrder})
                    Create("UIPadding", {Parent = list, PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)})

                    local function updateText()
                        if isMulti then
                            local t = ""
                            for _, v in pairs(selected) do t = t .. tostring(v) .. ", " end
                            main.Text = t == "" and "Select Options..." or t:sub(1, -3)
                        else
                            main.Text = selected and tostring(selected) or "Select..."
                        end
                    end

                    local function setVal(v)
                        selected = v
                        updateText()
                        for _, b in ipairs(btns) do
                            local ov = vals[b]
                            local isSel = isMulti and (type(selected) == "table" and table.find(selected, ov) ~= nil) or (not isMulti and selected == ov)
                            Tween(b, {TextColor3 = isSel and TextColor or SubTextColor}, 0.15)
                            local bg = b:FindFirstChild("Bg")
                            if bg then Tween(bg, {BackgroundTransparency = isSel and 0.75 or 1}, 0.15) end
                        end
                        if cb then cb(selected) end
                    end

                    local function render(opts)
                        options = opts or options
                        for _, b in ipairs(btns) do b:Destroy() end
                        btns, vals = {}, {}
                        for _, o in pairs(options) do
                            local b = Create("TextButton", {Parent = list, Text = tostring(o), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = (selected == o) and TextColor or SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2})
                            Create("UIPadding", {Parent = b, PaddingLeft = UDim.new(0, 12)})
                            Create("Frame", {Parent = b, Name = "Bg", BackgroundColor3 = AccentColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 1})
                            table.insert(btns, b); vals[b] = o
                            b.MouseButton1Click:Connect(function()
                                if isMulti then
                                    local i = table.find(selected, o)
                                    if i then table.remove(selected, i) else table.insert(selected, o) end
                                    setVal(selected)
                                else
                                    setVal(o)
                                    dropped = false
                                    Tween(main:FindFirstChild("Arrow"), {Rotation = 0}, 0.2)
                                    Tween(wrap, {Size = UDim2.new(1, 0, 0, 58)}, 0.2)
                                    search.Visible = false
                                end
                            end)
                        end
                        list.CanvasSize = UDim2.new(0, 0, 0, ll.AbsoluteContentSize.Y + 12)
                    end

                    render(options); updateText()

                    search:GetPropertyChangedSignal("Text"):Connect(function()
                        local q = search.Text:lower()
                        for _, b in ipairs(btns) do b.Visible = (q == "" or string.find(b.Text:lower(), q, 1, true) ~= nil) end
                    end)

                    ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                        list.CanvasSize = UDim2.new(0, 0, 0, ll.AbsoluteContentSize.Y + 12)
                    end)

                    main.MouseButton1Click:Connect(function()
                        dropped = not dropped
                        if dropped then
                            search.Visible = true; search.Text = ""
                            Tween(main:FindFirstChild("Arrow"), {Rotation = 180}, 0.2)
                            Tween(wrap, {Size = UDim2.new(1, 0, 0, 58 + 28 + 150)}, 0.2)
                        else
                            search.Visible = false
                            Tween(main:FindFirstChild("Arrow"), {Rotation = 0}, 0.2)
                            Tween(wrap, {Size = UDim2.new(1, 0, 0, 58)}, 0.2)
                        end
                    end)
                    AddInfoIcon(wrap, UDim2.new(1, -26, 0, 0), info)
                    if cb then cb(selected) end
                    Window.ConfigElements[title] = {Set = setVal, Get = function() return selected end}

                    local h = {}
                    h.Refresh = function(_, o, p) render(o or options); updateText() end
                    h.RefreshOptions = h.Refresh
                    h.SetOptions = h.Refresh
                    h.Set = setVal
                    h.Get = function() return selected end
                    return h
                end

                -- ===== TEXTBOX =====
                function Elements:AddTextbox(title, ph, default, cb, info)
                    local wrap = Create("Frame", {Parent = Items, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 58)})
                    Create("TextLabel", {Parent = wrap, Text = title, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -28, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
                    local input = Create("TextBox", {Parent = wrap, PlaceholderText = ph or "Type...", PlaceholderColor3 = SubTextColor, Text = default and tostring(default) or "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = Theme.ElementBg, Size = UDim2.new(1, -28, 0, 32), Position = UDim2.new(0, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false})
                    Create("UIPadding", {Parent = input, PaddingLeft = UDim.new(0, 12)})
                    Create("UICorner", {Parent = input, CornerRadius = UDim.new(0, 6)})
                    Create("UIStroke", {Parent = input, Color = Theme.ElementStroke, Thickness = 1})
                    local function set(v) input.Text = tostring(v); if cb then cb(v) end end
                    input.FocusLost:Connect(function() set(input.Text) end)
                    AddInfoIcon(wrap, UDim2.new(1, -26, 0, 0), info)
                    if cb then cb(input.Text) end
                    Window.ConfigElements[title] = {Set = set, Get = function() return input.Text end}
                end

                -- ===== COLOR PICKER =====
                function Elements:AddColorPicker(title, default, cb, info)
                    local color = Color3.fromRGB(255,255,255)
                    if typeof(default) == "Color3" then color = default
                    elseif type(default) == "string" then
                        local ok, c = pcall(Color3.fromHex, default)
                        if ok then color = c end
                    end
                    local h_, s_, v_ = color:ToHSV()
                    local dropped = false

                    local wrap = Create("Frame", {Parent = Items, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), ClipsDescendants = true})
                    Create("TextLabel", {Parent = wrap, Text = title, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -70, 0, 36), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
                    local disp = Create("TextButton", {Parent = wrap, Text = "", BackgroundColor3 = color, Size = UDim2.new(0, 40, 0, 22), Position = UDim2.new(1, -32, 0.5, -11), AutoButtonColor = false})
                    Create("UICorner", {Parent = disp, CornerRadius = UDim.new(0, 5)})
                    Create("UIStroke", {Parent = disp, Color = Color3.fromRGB(255,255,255), Transparency = 0.7, Thickness = 1})
                    AddBounce(disp)

                    local picker = Create("Frame", {Parent = wrap, BackgroundColor3 = Theme.ElementBg, Size = UDim2.new(1, -28, 0, 155), Position = UDim2.new(0, 0, 0, 44)})
                    Create("UICorner", {Parent = picker, CornerRadius = UDim.new(0, 6)})
                    Create("UIStroke", {Parent = picker, Color = Theme.ElementStroke, Thickness = 1})

                    local close = Create("TextButton", {Parent = picker, Text = "✕", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -26, 0, 4), AutoButtonColor = false})
                    AddBounce(close)
                    close.MouseButton1Click:Connect(function() dropped = false; Tween(wrap, {Size = UDim2.new(1, 0, 0, 36)}, 0.25) end)

                    local sv = Create("TextButton", {Parent = picker, Text = "", BackgroundColor3 = Color3.fromHSV(h_, 1, 1), Size = UDim2.new(1, -54, 0, 100), Position = UDim2.new(0, 12, 0, 12), AutoButtonColor = false})
                    Create("UICorner", {Parent = sv, CornerRadius = UDim.new(0, 5)})
                    local wg = Create("Frame", {Parent = sv, Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.new(1,1,1), ZIndex = 2})
                    Create("UIGradient", {Parent = wg, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})})
                    Create("UICorner", {Parent = wg, CornerRadius = UDim.new(0, 5)})
                    local bg = Create("Frame", {Parent = sv, Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.new(0,0,0), ZIndex = 3})
                    Create("UIGradient", {Parent = bg, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)}), Rotation = 90})
                    Create("UICorner", {Parent = bg, CornerRadius = UDim.new(0, 5)})
                    local ring = Create("Frame", {Parent = bg, Size = UDim2.new(0, 12, 0, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(s_, 0, 1-v_, 0), BackgroundColor3 = Color3.new(1,1,1), ZIndex = 4})
                    Create("UICorner", {Parent = ring, CornerRadius = UDim.new(1, 0)})
                    Create("UIStroke", {Parent = ring, Color = Color3.new(0,0,0), Thickness = 1.5})

                    local hue = Create("TextButton", {Parent = picker, Text = "", Size = UDim2.new(1, -24, 0, 20), Position = UDim2.new(0, 12, 0, 120), AutoButtonColor = false, BackgroundColor3 = Color3.new(1,1,1)})
                    Create("UICorner", {Parent = hue, CornerRadius = UDim.new(0, 5)})
                    Create("UIGradient", {Parent = hue, Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
                        ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255,255,0)),
                        ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0,255,0)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
                        ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0,0,255)),
                        ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255,0,255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0)),
                    })})
                    local hRing = Create("Frame", {Parent = hue, Size = UDim2.new(0, 6, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(h_, 0, 0.5, 0), BackgroundColor3 = Color3.new(1,1,1)})
                    Create("UICorner", {Parent = hRing, CornerRadius = UDim.new(0, 2)})
                    Create("UIStroke", {Parent = hRing, Color = Color3.new(0,0,0), Thickness = 1})

                    local function upd()
                        color = Color3.fromHSV(h_, s_, v_)
                        disp.BackgroundColor3 = color
                        sv.BackgroundColor3 = Color3.fromHSV(h_, 1, 1)
                        if cb then cb(color) end
                    end

                    local dragSV, dragH = false, false
                    sv.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragSV = true; if PageObj and PageObj.Scroll then PageObj.Scroll.ScrollingEnabled = false end end end)
                    hue.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragH = true; if PageObj and PageObj.Scroll then PageObj.Scroll.ScrollingEnabled = false end end end)
                    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragSV = false; dragH = false; if PageObj and PageObj.Scroll then PageObj.Scroll.ScrollingEnabled = true end end end)
                    UserInputService.InputChanged:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
                            if dragSV then
                                s_ = math.clamp((i.Position.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
                                v_ = 1 - math.clamp((i.Position.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
                                ring.Position = UDim2.new(s_, 0, 1-v_, 0)
                                upd()
                            elseif dragH then
                                h_ = math.clamp((i.Position.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 1)
                                hRing.Position = UDim2.new(h_, 0, 0.5, 0)
                                upd()
                            end
                        end
                    end)

                    disp.MouseButton1Click:Connect(function()
                        dropped = not dropped
                        Tween(wrap, {Size = UDim2.new(1, 0, 0, dropped and 36 + 44 + 155 or 36)}, 0.25)
                    end)
                    AddInfoIcon(wrap, UDim2.new(1, -60, 0, 8), info)
                    if cb then cb(color) end
                    Window.ConfigElements[title] = {
                        Set = function(hex)
                            local ok, c = pcall(Color3.fromHex, hex)
                            if ok then color = c; h_, s_, v_ = c:ToHSV(); disp.BackgroundColor3 = c; sv.BackgroundColor3 = Color3.fromHSV(h_, 1, 1); ring.Position = UDim2.new(s_, 0, 1-v_, 0); hRing.Position = UDim2.new(h_, 0, 0.5, 0); if cb then cb(c) end end
                        end,
                        Get = function() return color:ToHex() end,
                    }
                end

                -- ===== CONFIG MANAGER =====
                function Elements:AddConfigManager(folder)
                    folder = folder or "MarvenRizSave"
                    if not _isfolder(folder) then _makefolder(folder) end

                    local function readAuto()
                        local ok, raw = pcall(function() return _readfile(folder .. "/autoload.json") end)
                        if ok and raw and raw ~= "" then
                            local ok2, d = pcall(function() return HttpService:JSONDecode(raw) end)
                            if ok2 and type(d) == "table" then return d end
                        end
                        return {Enabled = false, Path = nil}
                    end
                    local function writeAuto(d)
                        if not _isfolder(folder) then _makefolder(folder) end
                        local ok, e = pcall(function() return HttpService:JSONEncode(d) end)
                        if ok then _writefile(folder .. "/autoload.json", e) end
                    end

                    local Manager = Create("Frame", {Parent = Items, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 320)})

                    local search = Create("TextBox", {Parent = Manager, PlaceholderText = "Search saves...", PlaceholderColor3 = SubTextColor, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = Theme.ElementBg, Size = UDim2.new(1, -28, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false})
                    Create("UIPadding", {Parent = search, PaddingLeft = UDim.new(0, 10)})
                    Create("UICorner", {Parent = search, CornerRadius = UDim.new(0, 6)})
                    Create("UIStroke", {Parent = search, Color = Theme.ElementStroke, Thickness = 1})

                    local monitor = Create("ScrollingFrame", {Parent = Manager, BackgroundColor3 = Color3.fromRGB(12, 12, 16), Size = UDim2.new(1, -28, 0, 120), Position = UDim2.new(0, 0, 0, 38), ScrollBarThickness = 3, BorderSizePixel = 0, CanvasSize = UDim2.new(0, 0, 0, 0)})
                    Create("UICorner", {Parent = monitor, CornerRadius = UDim.new(0, 6)})
                    Create("UIStroke", {Parent = monitor, Color = Theme.ElementStroke, Thickness = 1})
                    local ml = Create("UIListLayout", {Parent = monitor, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})
                    Create("UIPadding", {Parent = monitor, PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)})
                    ml:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() monitor.CanvasSize = UDim2.new(0, 0, 0, ml.AbsoluteContentSize.Y + 12) end)

                    local deleteMode, editMode = false, false
                    local selForDel = {}
                    local editTarget = ""

                    local autoRow = Create("Frame", {Parent = Manager, BackgroundTransparency = 1, Size = UDim2.new(1, -28, 0, 30), Position = UDim2.new(0, 0, 0, 166)})
                    Create("TextLabel", {Parent = autoRow, Text = "Auto Load", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -60, 1, 0), TextXAlignment = Enum.TextXAlignment.Left})
                    local autoOn = readAuto().Enabled == true
                    local aLever = Create("TextButton", {Parent = autoRow, Text = "", BackgroundColor3 = autoOn and AccentColor or Color3.fromRGB(48, 48, 60), Size = UDim2.new(0, 42, 0, 22), Position = UDim2.new(1, -42, 0.5, -11), AutoButtonColor = false})
                    Create("UICorner", {Parent = aLever, CornerRadius = UDim.new(1, 0)})
                    AddBounce(aLever, 0.94)
                    local aKnob = Create("Frame", {Parent = aLever, BackgroundColor3 = Color3.fromRGB(255,255,255), Size = UDim2.new(0, 18, 0, 18), Position = autoOn and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)})
                    Create("UICorner", {Parent = aKnob, CornerRadius = UDim.new(1, 0)})
                    aLever.MouseButton1Click:Connect(function()
                        local d = readAuto()
                        if not autoOn and not d.Path then
                            Library:Notify({Title = "Auto Load", Description = "Pick a config with ☆ first.", Duration = 3}); return
                        end
                        autoOn = not autoOn; d.Enabled = autoOn; writeAuto(d)
                        Tween(aLever, {BackgroundColor3 = autoOn and AccentColor or Color3.fromRGB(48, 48, 60)}, 0.25)
                        Tween(aKnob, {Position = autoOn and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}, 0.25)
                    end)

                    local controls = Create("Frame", {Parent = Manager, BackgroundTransparency = 1, Size = UDim2.new(1, -28, 0, 78), Position = UDim2.new(0, 0, 0, 204)})
                    local nameBox = Create("TextBox", {Parent = controls, PlaceholderText = "Enter save name...", PlaceholderColor3 = SubTextColor, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = Theme.ElementBg, Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false})
                    Create("UIPadding", {Parent = nameBox, PaddingLeft = UDim.new(0, 10)})
                    Create("UICorner", {Parent = nameBox, CornerRadius = UDim.new(0, 6)})
                    Create("UIStroke", {Parent = nameBox, Color = Theme.ElementStroke, Thickness = 1})

                    local createBtn = Create("TextButton", {Parent = controls, Text = "Create Save", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(255,255,255), BackgroundColor3 = AccentColor, Size = UDim2.new(0.5, -5, 0, 30), Position = UDim2.new(0, 0, 0, 40), AutoButtonColor = false})
                    Create("UICorner", {Parent = createBtn, CornerRadius = UDim.new(0, 6)})
                    AddBounce(createBtn)

                    local delTog = Create("TextButton", {Parent = controls, Text = "Delete Mode: OFF", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = Color3.fromRGB(48, 48, 60), Size = UDim2.new(0.5, -5, 0, 30), Position = UDim2.new(0.5, 5, 0, 40), AutoButtonColor = false})
                    Create("UICorner", {Parent = delTog, CornerRadius = UDim.new(0, 6)})
                    AddBounce(delTog)

                    local actionArea = Create("Frame", {Parent = controls, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 40), Visible = false})
                    local confirmBtn = Create("TextButton", {Parent = actionArea, Text = "Confirm", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(255,255,255), BackgroundColor3 = Theme.Danger, Size = UDim2.new(0.5, -5, 0, 30), AutoButtonColor = false})
                    Create("UICorner", {Parent = confirmBtn, CornerRadius = UDim.new(0, 6)})
                    AddBounce(confirmBtn)
                    local cancelBtn = Create("TextButton", {Parent = actionArea, Text = "Cancel", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = Color3.fromRGB(60, 60, 70), Size = UDim2.new(0.5, -5, 0, 30), Position = UDim2.new(0.5, 5, 0, 0), AutoButtonColor = false})
                    Create("UICorner", {Parent = cancelBtn, CornerRadius = UDim.new(0, 6)})
                    AddBounce(cancelBtn)

                    local confirmPopup = Create("Frame", {Parent = Manager, BackgroundColor3 = Theme.Card, Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0, 10, 0, 10), ZIndex = 60, BackgroundTransparency = 1, Visible = false})
                    Create("UICorner", {Parent = confirmPopup, CornerRadius = UDim.new(0, 8)})
                    Create("UIStroke", {Parent = confirmPopup, Color = Theme.Danger, Thickness = 1, Transparency = 1})
                    local cpTitle = Create("TextLabel", {Parent = confirmPopup, Text = "Confirm Deletion?", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Danger, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 40), TextTransparency = 1, ZIndex = 61})
                    local cpDesc = Create("TextLabel", {Parent = confirmPopup, Text = "This will permanently delete selected saves.", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 0, 40), Position = UDim2.new(0, 20, 0, 70), TextWrapped = true, TextTransparency = 1, ZIndex = 61})
                    local cpYes = Create("TextButton", {Parent = confirmPopup, Text = "Yes", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.fromRGB(255,255,255), BackgroundColor3 = Theme.Danger, Size = UDim2.new(0.5, -30, 0, 34), Position = UDim2.new(0, 20, 1, -54), AutoButtonColor = false, BackgroundTransparency = 1, TextTransparency = 1, ZIndex = 61})
                    Create("UICorner", {Parent = cpYes, CornerRadius = UDim.new(0, 6)})
                    AddBounce(cpYes)
                    local cpNo = Create("TextButton", {Parent = confirmPopup, Text = "No", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TextColor, BackgroundColor3 = Color3.fromRGB(48, 48, 60), Size = UDim2.new(0.5, -30, 0, 34), Position = UDim2.new(0.5, 10, 1, -54), AutoButtonColor = false, BackgroundTransparency = 1, TextTransparency = 1, ZIndex = 61})
                    Create("UICorner", {Parent = cpNo, CornerRadius = UDim.new(0, 6)})
                    AddBounce(cpNo)

                    local function hidePopup()
                        Tween(confirmPopup, {BackgroundTransparency = 1}, 0.25)
                        Tween(confirmPopup:FindFirstChild("UIStroke"), {Transparency = 1}, 0.25)
                        Tween(cpTitle, {TextTransparency = 1}, 0.25)
                        Tween(cpDesc, {TextTransparency = 1}, 0.25)
                        Tween(cpYes, {BackgroundTransparency = 1, TextTransparency = 1}, 0.25)
                        Tween(cpNo, {BackgroundTransparency = 1, TextTransparency = 1}, 0.25)
                        task.wait(0.25)
                        confirmPopup.Visible = false
                    end

                    local function refresh()
                        for _, c in ipairs(monitor:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
                        selForDel = {}
                        local current = readAuto().Path
                        for _, fp in ipairs(_listfiles(folder)) do
                            local raw = fp:match("([^/\\]+)%.json$")
                            if raw and not IsAutoloadFile(fp) then
                                local disp = raw:gsub("_%d+%.%d+$", ""):gsub("_%d+$", "")
                                local isAuto = (current == fp)
                                local row = Create("Frame", {Parent = monitor, BackgroundColor3 = Theme.ElementBg, Size = UDim2.new(1, 0, 0, 34)})
                                Create("UICorner", {Parent = row, CornerRadius = UDim.new(0, 6)})
                                Create("TextLabel", {Parent = row, Text = disp, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -110, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
                                local star = Create("TextButton", {Parent = row, Text = isAuto and "★" or "☆", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = isAuto and Theme.Warning or SubTextColor, BackgroundColor3 = Color3.fromRGB(48, 48, 60), Size = UDim2.new(0, 26, 0, 24), Position = UDim2.new(1, -128, 0.5, -12), AutoButtonColor = false})
                                Create("UICorner", {Parent = star, CornerRadius = UDim.new(0, 5)})
                                AddBounce(star)
                                local ld = Create("TextButton", {Parent = row, Text = "Load", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.fromRGB(255,255,255), BackgroundColor3 = Theme.Success, Size = UDim2.new(0, 42, 0, 24), Position = UDim2.new(1, -98, 0.5, -12), AutoButtonColor = false})
                                Create("UICorner", {Parent = ld, CornerRadius = UDim.new(0, 5)})
                                AddBounce(ld)
                                local ed = Create("TextButton", {Parent = row, Text = "Edit", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.fromRGB(255,255,255), BackgroundColor3 = Theme.Warning, Size = UDim2.new(0, 42, 0, 24), Position = UDim2.new(1, -52, 0.5, -12), AutoButtonColor = false})
                                Create("UICorner", {Parent = ed, CornerRadius = UDim.new(0, 5)})
                                AddBounce(ed)
                                local mask = Create("TextButton", {Parent = row, Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, -130, 1, 0), ZIndex = 2})
                                mask.MouseButton1Click:Connect(function()
                                    if deleteMode then
                                        if selForDel[fp] then
                                            selForDel[fp] = nil
                                            Tween(row, {BackgroundColor3 = Theme.ElementBg}, 0.15)
                                        else
                                            selForDel[fp] = true
                                            Tween(row, {BackgroundColor3 = Theme.Danger}, 0.15)
                                        end
                                    end
                                end)
                                star.MouseButton1Click:Connect(function()
                                    if deleteMode or editMode then return end
                                    local d = readAuto()
                                    if isAuto then d.Path = nil; writeAuto(d)
                                    else d.Path = fp; writeAuto(d) end
                                    refresh()
                                end)
                                ld.MouseButton1Click:Connect(function()
                                    if deleteMode or editMode then return end
                                    local ok, data = pcall(function() return HttpService:JSONDecode(_readfile(fp)) end)
                                    if ok and type(data) == "table" then
                                        for k, v in pairs(data) do
                                            if Window.ConfigElements[k] and Window.ConfigElements[k].Set then
                                                pcall(function() Window.ConfigElements[k].Set(v) end)
                                            end
                                        end
                                        Library:Notify({Title = "Loaded", Description = disp, Duration = 2})
                                    end
                                end)
                                ed.MouseButton1Click:Connect(function()
                                    if deleteMode then return end
                                    editMode = true; editTarget = fp; nameBox.Text = disp
                                    createBtn.Visible = false; delTog.Visible = false; actionArea.Visible = true
                                    confirmBtn.Text = "Save Edit"; confirmBtn.BackgroundColor3 = AccentColor
                                end)
                            end
                        end
                    end

                    local function execSave(n)
                        local payload = {}
                        for k, el in pairs(Window.ConfigElements) do if el.Get then payload[k] = el.Get() end end
                        local enc = HttpService:JSONEncode(payload)
                        local key = tostring(math.floor(tick()))
                        _writefile(folder .. "/" .. n .. "_" .. key .. ".json", enc)
                        refresh()
                        Library:Notify({Title = "Saved", Description = n, Duration = 2})
                    end

                    createBtn.MouseButton1Click:Connect(function() if nameBox.Text ~= "" then execSave(nameBox.Text) end end)

                    delTog.MouseButton1Click:Connect(function()
                        if editMode then return end
                        deleteMode = not deleteMode
                        delTog.Text = deleteMode and "Delete Mode: ON" or "Delete Mode: OFF"
                        Tween(delTog, {BackgroundColor3 = deleteMode and Theme.Danger or Color3.fromRGB(48, 48, 60)}, 0.15)
                        actionArea.Visible = deleteMode
                        createBtn.Visible = not deleteMode
                        if deleteMode then
                            confirmBtn.Text = "Delete Selected"; confirmBtn.BackgroundColor3 = Theme.Danger
                        else refresh() end
                    end)

                    confirmBtn.MouseButton1Click:Connect(function()
                        if deleteMode then
                            confirmPopup.Visible = true
                            Tween(confirmPopup, {BackgroundTransparency = 0.1}, 0.25)
                            Tween(confirmPopup:FindFirstChild("UIStroke"), {Transparency = 0.5}, 0.25)
                            Tween(cpTitle, {TextTransparency = 0}, 0.25); Tween(cpDesc, {TextTransparency = 0}, 0.25)
                            Tween(cpYes, {BackgroundTransparency = 0, TextTransparency = 0}, 0.25)
                            Tween(cpNo, {BackgroundTransparency = 0, TextTransparency = 0}, 0.25)
                        elseif editMode then
                            local n = nameBox.Text
                            if n ~= "" then pcall(function() _delfile(editTarget) end); execSave(n) end
                            editMode = false; actionArea.Visible = false; createBtn.Visible = true; delTog.Visible = true; refresh()
                        end
                    end)

                    cpYes.MouseButton1Click:Connect(function()
                        local ad = readAuto()
                        local cleared = false
                        for f in pairs(selForDel) do
                            pcall(function() _delfile(f) end)
                            if ad.Path == f then ad.Path = nil; ad.Enabled = false; cleared = true end
                        end
                        if cleared then writeAuto(ad); autoOn = false
                            Tween(aLever, {BackgroundColor3 = Color3.fromRGB(48,48,60)}, 0.25)
                            Tween(aKnob, {Position = UDim2.new(0, 2, 0.5, -9)}, 0.25)
                        end
                        deleteMode = false; delTog.Text = "Delete Mode: OFF"; delTog.BackgroundColor3 = Color3.fromRGB(48,48,60)
                        actionArea.Visible = false; createBtn.Visible = true; refresh(); hidePopup()
                    end)

                    cpNo.MouseButton1Click:Connect(hidePopup)

                    cancelBtn.MouseButton1Click:Connect(function()
                        editMode = false; deleteMode = false
                        delTog.Text = "Delete Mode: OFF"; delTog.BackgroundColor3 = Color3.fromRGB(48,48,60)
                        actionArea.Visible = false; createBtn.Visible = true; delTog.Visible = true
                        nameBox.Text = ""; refresh()
                    end)

                    search:GetPropertyChangedSignal("Text"):Connect(function()
                        local q = search.Text:lower()
                        for _, c in ipairs(monitor:GetChildren()) do
                            if c:IsA("Frame") then
                                local lbl = c:FindFirstChildOfClass("TextLabel")
                                if lbl then c.Visible = (q == "" or string.find(lbl.Text:lower(), q, 1, true) ~= nil) end
                            end
                        end
                    end)

                    refresh()
                end

                local function info(c)
                    if c.Desc then return {Title = c.Title, Description = c.Desc, Example = c.Example} end
                    return nil
                end

                function Elements:Button(c) c = c or {}; return self:AddButton(c.Title, c.Callback, info(c)) end
                function Elements:CopyButton(c) c = c or {}; return self:AddCopyButton(c.Title, c.Text or c.Content, info(c)) end
                function Elements:Paragraph(c) c = c or {}; return self:AddParagraph(c.Title, c.Content, info(c)) end
                function Elements:Toggle(c) c = c or {}; return self:AddToggle(c.Title, c.Value, c.Callback, info(c)) end
                function Elements:Slider(c) c = c or {}; return self:AddSlider(c.Title, c.Min, c.Max, c.Value, c.Callback, info(c)) end
                function Elements:Dropdown(c) c = c or {}; return self:AddDropdown(c.Title, c.Options, c.Multi, c.Value, c.Callback, info(c)) end
                function Elements:Textbox(c) c = c or {}; return self:AddTextbox(c.Title, c.Placeholder, c.Value, c.Callback, info(c)) end
                function Elements:ColorPicker(c) c = c or {}; return self:AddColorPicker(c.Title, c.Value, c.Callback, info(c)) end
                function Elements:ConfigManager(c) c = c or {}; return self:AddConfigManager(c.Folder) end

                return Elements
            end
            return PageObj
        end

        if isDefault then
            TabBtn.BackgroundTransparency = 0
            Indicator.Size = UDim2.new(0, 3, 0, 22)
            Txt.TextColor3 = TextColor
            TabContent.Visible = true
            Window.CurrentTab = TabConfig
        end
        return TabConfig
    end

    Library.SaveManager.Window = Window
    return Window
end

return Library
