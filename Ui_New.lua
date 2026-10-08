local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local Library = {
    WhitelistedUsers = {}
}

-- File IO fallbacks
local _isfolder = isfolder or function() return true end
local _makefolder = makefolder or function() end
local _writefile = writefile or function(path, data) warn("File saving not supported on this executor.") end
local _readfile = readfile or function() return "{}" end
local _listfiles = listfiles or function() return {} end
local _delfile = delfile or function() warn("File deletion not supported.") end

-- ============================================================
--  PALETTE
-- ============================================================
local AccentColor     = Color3.fromRGB(99, 102, 241)     -- indigo
local AccentSecondary = Color3.fromRGB(168, 85, 247)     -- purple
local BackgroundColor = Color3.fromRGB(13, 13, 18)
local CardColor       = Color3.fromRGB(22, 22, 30)
local CardElevated    = Color3.fromRGB(28, 28, 38)
local HoverColor      = Color3.fromRGB(38, 38, 52)
local TextColor       = Color3.fromRGB(245, 245, 250)
local SubTextColor    = Color3.fromRGB(150, 150, 168)
local StrokeColor     = Color3.fromRGB(45, 45, 60)

-- ============================================================
--  HELPERS
-- ============================================================
local function SafeCopyToClipboard(text)
    if setclipboard then
        setclipboard(text)
    elseif toclipboard then
        toclipboard(text)
    else
        warn("Clipboard copying is not supported on your current executor.")
    end
end

local function Create(className, properties)
    local instance = Instance.new(className)
    if className == "TextBox" then instance.Text = "" end
    for k, v in pairs(properties or {}) do
        instance[k] = v
    end
    if (className == "TextLabel" or className == "TextButton" or className == "TextBox") then
        if properties and properties.TextSize and properties.RichText ~= true then
            instance.TextScaled = true
            local constraint = Instance.new("UITextSizeConstraint")
            constraint.MaxTextSize = properties.TextSize
            constraint.MinTextSize = 6
            constraint.Parent = instance
        end
    end
    return instance
end

local function IsAutoloadFile(filepath)
    if type(filepath) ~= "string" then return false end
    local lower = filepath:lower()
    return lower:sub(-13) == "autoload.json"
end

local function BuildSearchIndex(card)
    local parts = {}
    for _, desc in ipairs(card:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
            if desc.Text and desc.Text ~= "" then
                table.insert(parts, desc.Text:lower())
            end
        end
    end
    return table.concat(parts, " ")
end

-- Smooth tween helper with style options
local function Tween(instance, properties, duration, style, direction)
    duration = duration or 0.25
    style = style or Enum.EasingStyle.Quint
    direction = direction or Enum.EasingDirection.Out
    local tweenInfo = TweenInfo.new(duration, style, direction)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Spring-ish tween for bouncy feedback
local function SpringTween(instance, properties, duration)
    duration = duration or 0.35
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Ripple effect on click
local function AddRipple(button, rippleColor)
    rippleColor = rippleColor or Color3.fromRGB(255, 255, 255)
    button.ClipsDescendants = true
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local absPos = button.AbsolutePosition
            local absSize = button.AbsoluteSize
            local ripple = Create("Frame", {
                Parent = button,
                BackgroundColor3 = rippleColor,
                BackgroundTransparency = 0.65,
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y),
                AnchorPoint = Vector2.new(0.5, 0.5),
                ZIndex = 10,
                BorderSizePixel = 0
            })
            Create("UICorner", {Parent = ripple, CornerRadius = UDim.new(1, 0)})
            local maxSize = math.max(absSize.X, absSize.Y) * 2.2
            local t = TweenService:Create(ripple, TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, maxSize, 0, maxSize),
                BackgroundTransparency = 1
            })
            t:Play()
            t.Completed:Connect(function() ripple:Destroy() end)
        end
    end)
end

-- Hover glow on a stroke
local function BindHoverStroke(stroke, baseColor, hoverColor, baseTrans, hoverTrans)
    baseTrans = baseTrans or 0.5
    hoverTrans = hoverTrans or 0
    return function(isHovering)
        Tween(stroke, {
            Color = isHovering and hoverColor or baseColor,
            Transparency = isHovering and hoverTrans or baseTrans
        }, 0.25)
    end
end

-- Bounce scale + hover scale + ripple
local function AddBounce(button, scaleFactor, enableRipple)
    scaleFactor = scaleFactor or 0.96
    local scaleObj = button:FindFirstChild("UIScale") or Create("UIScale", {Parent = button, Scale = 1})
    local hoverTarget = 1.02

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Tween(scaleObj, {Scale = scaleFactor}, 0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Tween(scaleObj, {Scale = 1}, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end
    end)
    button.MouseEnter:Connect(function()
        Tween(scaleObj, {Scale = hoverTarget}, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    end)
    button.MouseLeave:Connect(function()
        Tween(scaleObj, {Scale = 1}, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    end)

    if enableRipple then AddRipple(button) end
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
            object.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ============================================================
--  SAVE MANAGER
-- ============================================================
local GlobalNotifContainer

function Library:Notify(options)
    if not GlobalNotifContainer then return end
    local title    = options.Title or "Notification"
    local desc     = options.Description or "Information updated."
    local duration = options.Duration or 3
    local type     = options.Type or "info" -- info | success | warn | error

    local accentMap = {
        info    = AccentColor,
        success = Color3.fromRGB(52, 199, 89),
        warn    = Color3.fromRGB(255, 179, 64),
        error   = Color3.fromRGB(255, 69, 58),
    }
    local accent = accentMap[type] or AccentColor

    local Notif = Create("Frame", {
        Parent = GlobalNotifContainer,
        BackgroundColor3 = Color3.fromRGB(20, 20, 26),
        Size = UDim2.new(1, 0, 0, 68),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, 40, 0, 0),
        ZIndex = 201,
        ClipsDescendants = false
    })
    Create("UICorner", {Parent = Notif, CornerRadius = UDim.new(0, 10)})
    local Stroke = Create("UIStroke", {Parent = Notif, Color = accent, Thickness = 1.2, Transparency = 1})
    Create("UIGradient", {Parent = Stroke, Color = ColorSequence.new(accent, AccentSecondary), Rotation = 45})

    -- Left accent bar
    local AccentBar = Create("Frame", {
        Parent = Notif,
        BackgroundColor3 = accent,
        Size = UDim2.new(0, 3, 1, -16),
        Position = UDim2.new(0, 6, 0, 8),
        ZIndex = 202
    })
    Create("UICorner", {Parent = AccentBar, CornerRadius = UDim.new(1, 0)})

    local TitleText = Create("TextLabel", {
        Parent = Notif, Text = title, Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = TextColor, BackgroundTransparency = 1,
        Position = UDim2.new(0, 18, 0, 15), Size = UDim2.new(1, -30, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, ZIndex = 202
    })
    local DescText = Create("TextLabel", {
        Parent = Notif, Text = desc, Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = SubTextColor, BackgroundTransparency = 1,
        Position = UDim2.new(0, 18, 0, 34), Size = UDim2.new(1, -30, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, ZIndex = 202
    })

    local NotifScale = Create("UIScale", {Parent = Notif, Scale = 0.85})
    Tween(NotifScale, {Scale = 1}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Tween(Notif, {BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    Tween(Stroke, {Transparency = 0.15}, 0.4)
    Tween(TitleText, {TextTransparency = 0}, 0.3)
    Tween(DescText, {TextTransparency = 0}, 0.35)

    task.delay(duration, function()
        if not Notif.Parent then return end
        Tween(Notif, {BackgroundTransparency = 1, Position = UDim2.new(1, 40, 0, 0)}, 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        Tween(Stroke, {Transparency = 1}, 0.4)
        Tween(TitleText, {TextTransparency = 1}, 0.3)
        Tween(DescText, {TextTransparency = 1}, 0.3)
        Tween(NotifScale, {Scale = 0.85}, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.wait(0.45)
        if Notif.Parent then Notif:Destroy() end
    end)
end

Library.SaveManager = {
    Folder = "MarvenRizSave",
    BaseFolder = "MarvenRizSave",
    Window = nil
}
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

function SaveManager:GetConfigs()
    if not _isfolder(self.Folder) then _makefolder(self.Folder) end
    local list = {}
    for _, filepath in ipairs(_listfiles(self.Folder)) do
        local rawName = filepath:match("([^/\\]+)%.json$")
        if rawName and not IsAutoloadFile(filepath) then table.insert(list, rawName) end
    end
    table.sort(list)
    return list
end

function SaveManager:Save(name)
    if not self.Window or name == nil or name == "" then return false end
    if not _isfolder(self.Folder) then _makefolder(self.Folder) end
    local payload = {}
    for k, el in pairs(self.Window.ConfigElements) do
        if el.Get then payload[k] = el.Get() end
    end
    local ok, encoded = pcall(function() return HttpService:JSONEncode(payload) end)
    if not ok then return false end
    _writefile(self.Folder .. "/" .. name .. ".json", encoded)
    Library:Notify({Title = "Config Saved", Description = "Saved [" .. name .. "] successfully.", Duration = 3, Type = "success"})
    return true
end

function SaveManager:Load(name)
    if not self.Window or name == nil or name == "" then return false end
    local path = self.Folder .. "/" .. name .. ".json"
    local ok, data = pcall(function() return HttpService:JSONDecode(_readfile(path)) end)
    if ok and type(data) == "table" then
        for k, v in pairs(data) do
            if self.Window.ConfigElements[k] and self.Window.ConfigElements[k].Set then
                local setOk, setErr = pcall(function() self.Window.ConfigElements[k].Set(v) end)
                if not setOk then
                    warn("[SaveManager:Load] Skipped key '" .. tostring(k) .. "': " .. tostring(setErr))
                end
            end
        end
        Library:Notify({Title = "Config Loaded", Description = "Loaded [" .. name .. "] successfully.", Duration = 3, Type = "success"})
        return true
    end
    return false
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

function SaveManager:Delete(name)
    if name == nil or name == "" then return end
    pcall(function() _delfile(self.Folder .. "/" .. name .. ".json") end)
    local data = self:GetAutoloadData()
    if data.Path == (self.Folder .. "/" .. name .. ".json") then
        data.Path = nil
        data.Enabled = false
        self:SetAutoloadData(data)
    end
end

function SaveManager:GetAutoloadPath() return self:GetAutoloadData().Path end
function SaveManager:IsAutoloadEnabled() return self:GetAutoloadData().Enabled == true end

function SaveManager:SetAutoloadConfig(name)
    local data = self:GetAutoloadData()
    data.Path = (name and name ~= "") and (self.Folder .. "/" .. name .. ".json") or nil
    self:SetAutoloadData(data)
end

function SaveManager:SetAutoloadEnabled(enabled)
    local data = self:GetAutoloadData()
    data.Enabled = enabled and true or false
    self:SetAutoloadData(data)
end

function SaveManager:LoadAutoloadConfig()
    if not self.Window then return false end
    local data = self:GetAutoloadData()
    if not data.Enabled or not data.Path then return false end
    local ok, fdata = pcall(function() return HttpService:JSONDecode(_readfile(data.Path)) end)
    if ok and type(fdata) == "table" then
        for k, v in pairs(fdata) do
            if self.Window.ConfigElements[k] and self.Window.ConfigElements[k].Set then
                local setOk, setErr = pcall(function() self.Window.ConfigElements[k].Set(v) end)
                if not setOk then
                    warn("[SaveManager:LoadAutoloadConfig] Skipped key '" .. tostring(k) .. "': " .. tostring(setErr))
                end
            end
        end
        Library:Notify({Title = "Autoload", Description = "Configuration loaded automatically.", Duration = 3, Type = "info"})
        return true
    end
    return false
end

function SaveManager:BuildConfigTab(tab, folderName)
    self:SetFolder(folderName or self.Folder)
    if not tab or not tab.CreatePage then
        warn("SaveManager:BuildConfigTab expects a Tab object returned by Window:CreateTab(...)")
        return
    end
    local Page = tab:CreatePage("Config")
    local UISection = Page:CreateSection("UI Settings")
    if self.Window then
        UISection:Toggle({
            Title = "Transparency",
            Desc = "Overrides main window background for a sleek 0.2 transparency visual.",
            Value = false,
            Callback = function(state)
                self.Window:SetTransparency(state and 0.2 or 0)
            end
        })
    end
    local SaveSection = Page:CreateSection("Save Manager")
    SaveSection:AddConfigManager(self.Folder)
    return Page, UISection, SaveSection
end

-- ============================================================
--  WINDOW
-- ============================================================
function Library:CreateWindow(options)
    local hubName = "MarvenRiz Ui Lib"
    local subText = "Made By Zens"
    local subColor = AccentColor
    local sphTextToggle = false
    local sphWords = "ZX"
    local sphImage = nil
    local topbarLogo = nil
    local logoSize = 32
    local sphIconSize = 26
    local windowSize = UDim2.fromOffset(580, 460)
    local sideBarWidth = 160

    if type(options) == "table" then
        hubName = options.Title or hubName
        subText = options.Subtitle or subText
        if options.AccentColor ~= nil then
            if typeof(options.AccentColor) == "Color3" then
                AccentColor = options.AccentColor
            elseif type(options.AccentColor) == "string" then
                local okHex, cHex = pcall(function() return Color3.fromHex(options.AccentColor) end)
                if okHex then AccentColor = cHex end
            end
        end
        subColor = options.SubtitleColor or AccentColor
        if options.SphereText ~= nil then sphTextToggle = options.SphereText end
        if options.SphereWords ~= nil then
            local wordList = string.split(tostring(options.SphereWords), " ")
            if #wordList > 2 then
                sphWords = wordList[1] .. " " .. wordList[2]
            else
                sphWords = tostring(options.SphereWords)
            end
        end
        sphImage = options.SphereImage
        topbarLogo = options.Logo
        logoSize = options.LogoSize or 32
        sphIconSize = options.SphereIconSize or 26
        windowSize = options.Size or windowSize
        sideBarWidth = options.SideBarWidth or sideBarWidth
        if options.Map ~= nil or options.MapId ~= nil then
            Library.SaveManager:SetMap(options.Map or options.MapId, options.SaveFolder)
        end
    elseif type(options) == "string" then
        hubName = options
    end

    local uniqueID = HttpService:GenerateGUID(false)
    local isStudio = RunService:IsStudio()
    local parentGui = isStudio and Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui

    local ScreenGui = Create("ScreenGui", {
        Name = "MarvenRiz_UI_" .. uniqueID,
        Parent = parentGui,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    -- Notification container
    local NotifContainer = Create("Frame", {
        Parent = ScreenGui,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 320, 1, -20),
        Position = UDim2.new(1, -340, 0, 10),
        ZIndex = 200,
        Active = false
    })
    Create("UIListLayout", {
        Parent = NotifContainer,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 12)
    })
    GlobalNotifContainer = NotifContainer

    local function SendPremiumNotification()
        local Notif = Create("Frame", {
            Parent = NotifContainer,
            BackgroundColor3 = Color3.fromRGB(20, 20, 26),
            Size = UDim2.new(1, 0, 0, 65),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 40, 0, 0),
            ZIndex = 201,
            ClipsDescendants = true
        })
        Create("UICorner", {Parent = Notif, CornerRadius = UDim.new(0, 10)})
        local Stroke = Create("UIStroke", {Parent = Notif, Thickness = 1.5, Transparency = 1})
        Create("UIGradient", {
            Parent = Stroke,
            Color = ColorSequence.new(Color3.fromRGB(255, 215, 0), Color3.fromRGB(180, 130, 20)),
            Rotation = 45
        })

        local LockIcon = Create("ImageLabel", {
            Parent = Notif, BackgroundTransparency = 1,
            Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(0, 15, 0.5, -12),
            Image = "rbxassetid://6031082533",
            ImageColor3 = Color3.fromRGB(255, 215, 0),
            ImageTransparency = 1, ZIndex = 202
        })
        local TitleText = Create("TextLabel", {
            Parent = Notif, Text = "ACCESS DENIED", Font = Enum.Font.GothamBlack, TextSize = 12,
            TextColor3 = SubTextColor, BackgroundTransparency = 1,
            Position = UDim2.new(0, 50, 0, 15), Size = UDim2.new(1, -60, 0, 15),
            TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, ZIndex = 202
        })
        local DescText = Create("TextLabel", {
            Parent = Notif,
            Text = 'This Is For <font color="#FFD700"><b>Whitelisted Users</b></font>',
            RichText = true, Font = Enum.Font.Gotham, TextSize = 14,
            TextColor3 = TextColor, BackgroundTransparency = 1,
            Position = UDim2.new(0, 50, 0, 32), Size = UDim2.new(1, -60, 0, 15),
            TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, ZIndex = 202
        })

        local Shine = Create("Frame", {
            Parent = Notif,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.8, BorderSizePixel = 0,
            Size = UDim2.new(0, 20, 2, 0),
            Position = UDim2.new(-0.2, 0, -0.5, 0),
            Rotation = 25, ZIndex = 203
        })

        local NotifScale = Create("UIScale", {Parent = Notif, Scale = 0.85})
        Tween(NotifScale, {Scale = 1}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        Tween(Notif, {BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        Tween(Stroke, {Transparency = 0.15}, 0.3)
        Tween(LockIcon, {ImageTransparency = 0}, 0.3)
        Tween(TitleText, {TextTransparency = 0}, 0.3)
        Tween(DescText, {TextTransparency = 0}, 0.3)

        local shineTween = TweenService:Create(Shine, TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.new(1.2, 0, -0.5, 0)})
        task.delay(0.2, function() shineTween:Play() end)

        task.delay(4, function()
            if not Notif.Parent then return end
            Tween(Notif, {BackgroundTransparency = 1, Position = UDim2.new(1, 40, 0, 0)}, 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            Tween(Stroke, {Transparency = 1}, 0.4)
            Tween(LockIcon, {ImageTransparency = 1}, 0.4)
            Tween(TitleText, {TextTransparency = 1}, 0.4)
            Tween(DescText, {TextTransparency = 1}, 0.4)
            task.wait(0.45)
            if Notif.Parent then Notif:Destroy() end
        end)
    end

    -- Info overlay
    local InfoOverlay = Create("Frame", {
        Parent = ScreenGui, BackgroundColor3 = Color3.fromRGB(5, 5, 8),
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 150, Visible = false, Active = true
    })
    local InfoCard = Create("Frame", {
        Parent = InfoOverlay, BackgroundColor3 = Color3.fromRGB(16, 16, 22),
        Size = UDim2.new(0, 360, 0, 280), Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 151,
        BackgroundTransparency = 1, ClipsDescendants = true
    })
    Create("UICorner", {Parent = InfoCard, CornerRadius = UDim.new(0, 12)})
    Create("UIStroke", {Parent = InfoCard, Color = AccentColor, Thickness = 1.5, Transparency = 1})
    local InfoScale = Create("UIScale", {Parent = InfoCard, Scale = 0})

    local InfoHeader = Create("Frame", {Parent = InfoCard, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), ZIndex = 152})
    local InfoTitle = Create("TextLabel", {
        Parent = InfoHeader, Text = "Feature Info", Font = Enum.Font.GothamBold, TextSize = 16,
        TextColor3 = TextColor, BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(1, -60, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, ZIndex = 152
    })
    local InfoCloseBtn = Create("TextButton", {
        Parent = InfoHeader, Text = "X", Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = SubTextColor, BackgroundTransparency = 1,
        Size = UDim2.new(0, 40, 1, 0), Position = UDim2.new(1, -40, 0, 0),
        ZIndex = 152, TextTransparency = 1, AutoButtonColor = false
    })
    AddBounce(InfoCloseBtn)

    local InfoScroll = Create("ScrollingFrame", {
        Parent = InfoCard, BackgroundTransparency = 1,
        Size = UDim2.new(1, -40, 1, -60), Position = UDim2.new(0, 20, 0, 50),
        CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 2,
        ScrollBarImageColor3 = AccentColor, BorderSizePixel = 0, ZIndex = 152
    })
    local InfoLayout = Create("UIListLayout", {Parent = InfoScroll, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})
    local InfoDesc = Create("TextLabel", {
        Parent = InfoScroll, Text = "", Font = Enum.Font.Gotham, TextSize = 13,
        TextColor3 = SubTextColor, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 152, TextTransparency = 1
    })
    local InfoExampleBox = Create("Frame", {
        Parent = InfoScroll, BackgroundColor3 = Color3.fromRGB(10, 10, 14),
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false, ZIndex = 152
    })
    Create("UICorner", {Parent = InfoExampleBox, CornerRadius = UDim.new(0, 6)})
    Create("UIStroke", {Parent = InfoExampleBox, Color = Color3.fromRGB(45, 45, 55), Thickness = 1})
    local InfoExampleText = Create("TextLabel", {
        Parent = InfoExampleBox, Text = "", Font = Enum.Font.Code, TextSize = 12,
        TextColor3 = AccentColor, BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 0), Position = UDim2.new(0, 10, 0, 10),
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 152, TextTransparency = 1
    })
    Create("UIPadding", {Parent = InfoExampleBox, PaddingBottom = UDim.new(0, 10)})
    InfoLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        InfoScroll.CanvasSize = UDim2.new(0, 0, 0, InfoLayout.AbsoluteContentSize.Y + 10)
    end)

    local function OpenInfoWindow(data)
        InfoTitle.Text = data.Title or "Information"
        InfoDesc.Text = data.Description or "No description provided."
        if data.Example then
            InfoExampleText.Text = data.Example
            InfoExampleBox.Visible = true
        else
            InfoExampleBox.Visible = false
        end
        InfoOverlay.Visible = true
        Tween(InfoOverlay, {BackgroundTransparency = 0.4}, 0.3)
        Tween(InfoCard, {BackgroundTransparency = 0}, 0.3)
        Tween(InfoCard:FindFirstChild("UIStroke"), {Transparency = 0.3}, 0.3)
        Tween(InfoScale, {Scale = 1}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        Tween(InfoTitle, {TextTransparency = 0}, 0.3)
        Tween(InfoCloseBtn, {TextTransparency = 0}, 0.3)
        Tween(InfoDesc, {TextTransparency = 0}, 0.3)
        if data.Example then Tween(InfoExampleText, {TextTransparency = 0}, 0.3) end
    end

    InfoCloseBtn.MouseButton1Click:Connect(function()
        Tween(InfoOverlay, {BackgroundTransparency = 1}, 0.3)
        Tween(InfoCard, {BackgroundTransparency = 1}, 0.3)
        Tween(InfoCard:FindFirstChild("UIStroke"), {Transparency = 1}, 0.3)
        Tween(InfoScale, {Scale = 0}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        Tween(InfoTitle, {TextTransparency = 1}, 0.3)
        Tween(InfoCloseBtn, {TextTransparency = 1}, 0.3)
        Tween(InfoDesc, {TextTransparency = 1}, 0.3)
        if InfoExampleBox.Visible then Tween(InfoExampleText, {TextTransparency = 1}, 0.3) end
        task.wait(0.3)
        InfoOverlay.Visible = false
    end)

    local function AddInfoIcon(parent, pos, data)
        if not data then return end
        local Btn = Create("TextButton", {
            Parent = parent, Text = "?", Font = Enum.Font.GothamBold, TextSize = 10,
            TextColor3 = SubTextColor, BackgroundColor3 = Color3.fromRGB(38, 38, 48),
            Size = UDim2.new(0, 16, 0, 16), Position = pos, AutoButtonColor = false, ZIndex = 5
        })
        Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(1, 0)})
        AddBounce(Btn)
        Btn.MouseEnter:Connect(function()
            Tween(Btn, {TextColor3 = TextColor, BackgroundColor3 = AccentColor}, 0.2)
        end)
        Btn.MouseLeave:Connect(function()
            Tween(Btn, {TextColor3 = SubTextColor, BackgroundColor3 = Color3.fromRGB(38, 38, 48)}, 0.2)
        end)
        Btn.MouseButton1Click:Connect(function() OpenInfoWindow(data) end)
    end

    -- Main window frame
    local MainFrame = Create("Frame", {
        Parent = ScreenGui, BackgroundColor3 = BackgroundColor,
        Size = windowSize, Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5), ClipsDescendants = true,
        BackgroundTransparency = 1, Active = true
    })
    local MainScale = Create("UIScale", {Parent = MainFrame, Scale = 0.85})
    Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 12)})
    local MainStroke = Create("UIStroke", {Parent = MainFrame, Color = StrokeColor, Thickness = 1, Transparency = 1})
    Create("UIGradient", {
        Parent = MainStroke,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, AccentColor),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 60, 80)),
            ColorSequenceKeypoint.new(1, AccentSecondary),
        }),
        Rotation = 45
    })

    -- Background glow/accent blob at top
    local TopGlow = Create("Frame", {
        Parent = MainFrame,
        BackgroundColor3 = AccentColor,
        BackgroundTransparency = 0.92,
        Size = UDim2.new(1, 0, 0, 120),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex = 0,
        BorderSizePixel = 0
    })
    Create("UICorner", {Parent = TopGlow, CornerRadius = UDim.new(0, 12)})
    Create("UIGradient", {
        Parent = TopGlow,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1)
        }),
        Rotation = 90
    })

    Tween(MainScale, {Scale = 1}, 0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Tween(MainFrame, {BackgroundTransparency = 0}, 0.4)
    Tween(MainStroke, {Transparency = 0.35}, 0.5)

    -- Bottom floating drag bar
    local BottomDragHitbox = Create("Frame", {
        Parent = ScreenGui, BackgroundTransparency = 1,
        Size = UDim2.new(0, 350, 0, 30),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 145, Active = true
    })
    local FloatingBottomBar = Create("Frame", {
        Parent = BottomDragHitbox, BackgroundColor3 = CardColor,
        BackgroundTransparency = 0, Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0.5, -3), ZIndex = 146
    })
    Create("UICorner", {Parent = FloatingBottomBar, CornerRadius = UDim.new(1, 0)})
    local BottomBarStroke = Create("UIStroke", {
        Parent = FloatingBottomBar, Color = Color3.fromRGB(60, 60, 75),
        Thickness = 1.2, Transparency = 0
    })
    MakeDraggable(BottomDragHitbox, MainFrame)

    RunService.RenderStepped:Connect(function()
        if MainFrame and MainFrame.Visible then
            BottomDragHitbox.Visible = true
            local currentScale = MainScale.Scale
            local frameHeight = windowSize.Y.Offset * currentScale
            local frameWidth = windowSize.X.Offset * currentScale

            BottomDragHitbox.Position = UDim2.new(
                MainFrame.Position.X.Scale, MainFrame.Position.X.Offset,
                MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset + (frameHeight / 2) + 20
            )
            BottomDragHitbox.Size = UDim2.new(0, frameWidth * 0.6, 0, 30 * currentScale)
            FloatingBottomBar.Size = UDim2.new(1, 0, 0, 6 * currentScale)
            FloatingBottomBar.Position = UDim2.new(0, 0, 0.5, -(3 * currentScale))
        else
            BottomDragHitbox.Visible = false
        end
    end)

    -- Topbar
    local TopBar = Create("Frame", {
        Parent = MainFrame, BackgroundColor3 = BackgroundColor,
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44),
        Position = UDim2.new(0, 0, 0, 0), Active = true, ZIndex = 5
    })
    MakeDraggable(TopBar, MainFrame)

    local titleOffsetX = 15
    if topbarLogo then
        local TopbarIcon = Create("ImageLabel", {
            Parent = TopBar, BackgroundTransparency = 1,
            Size = UDim2.new(0, logoSize, 0, logoSize),
            Position = UDim2.new(0, 12, 0.5, -(logoSize / 2)),
            Image = topbarLogo, ScaleType = Enum.ScaleType.Fit
        })
        titleOffsetX = 12 + logoSize + 10
    end

    local TitleContainer = Create("Frame", {Parent = TopBar, BackgroundTransparency = 1, Size = UDim2.new(0, 200, 1, 0), Position = UDim2.new(0, titleOffsetX, 0, 0)})
    local Title = Create("TextLabel", {
        Parent = TitleContainer, Text = hubName, Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = TextColor, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 7), Size = UDim2.new(1, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local Subtitle = Create("TextLabel", {
        Parent = TitleContainer, Text = subText, Font = Enum.Font.Gotham, TextSize = 10,
        TextColor3 = subColor, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 0, 12),
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Search
    local SearchBar = Create("Frame", {
        Parent = TopBar, BackgroundColor3 = CardColor,
        Size = UDim2.new(0, 220, 0, 28),
        Position = UDim2.new(0, titleOffsetX + 210, 0.5, -14)
    })
    Create("UICorner", {Parent = SearchBar, CornerRadius = UDim.new(0, 8)})
    local SearchStroke = Create("UIStroke", {Parent = SearchBar, Color = StrokeColor, Thickness = 1})
    local SearchIcon = Create("ImageLabel", {
        Parent = SearchBar, BackgroundTransparency = 1,
        Image = "rbxassetid://6031154871", ImageColor3 = SubTextColor,
        Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 9, 0.5, -7)
    })
    local SearchInput = Create("TextBox", {
        Parent = SearchBar, BackgroundTransparency = 1,
        Size = UDim2.new(1, -32, 1, 0), Position = UDim2.new(0, 30, 0, 0),
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor,
        PlaceholderText = "Search..", TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })
    local searchFocusConn = BindHoverStroke(SearchStroke, StrokeColor, AccentColor, 0, 0)
    SearchInput.Focused:Connect(function() searchFocusConn(true) end)
    SearchInput.FocusLost:Connect(function() searchFocusConn(false) end)

    -- Window buttons
    local CloseBtn = Create("TextButton", {
        Parent = TopBar, Text = "X", Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = SubTextColor, BackgroundTransparency = 1,
        Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(1, -35, 0, 0), AutoButtonColor = false
    })
    local MinBtn = Create("TextButton", {
        Parent = TopBar, Text = "—", Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = SubTextColor, BackgroundTransparency = 1,
        Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(1, -65, 0, 0), AutoButtonColor = false
    })
    CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, {TextColor3 = Color3.fromRGB(255, 80, 80)}, 0.2) end)
    CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, {TextColor3 = SubTextColor}, 0.2) end)
    MinBtn.MouseEnter:Connect(function() Tween(MinBtn, {TextColor3 = AccentColor}, 0.2) end)
    MinBtn.MouseLeave:Connect(function() Tween(MinBtn, {TextColor3 = SubTextColor}, 0.2) end)

    -- Sidebar
    local Sidebar = Create("Frame", {
        Parent = MainFrame, BackgroundColor3 = BackgroundColor,
        BackgroundTransparency = 1, Size = UDim2.new(0, sideBarWidth, 1, -44),
        Position = UDim2.new(0, 0, 0, 44), Active = true, ZIndex = 4
    })
    local TabSearchBox = Create("TextBox", {
        Parent = Sidebar, BackgroundColor3 = CardColor,
        Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 5),
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor,
        PlaceholderText = "Search tabs...", TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })
    Create("UIPadding", {Parent = TabSearchBox, PaddingLeft = UDim.new(0, 8)})
    Create("UICorner", {Parent = TabSearchBox, CornerRadius = UDim.new(0, 6)})
    local TabSearchStroke = Create("UIStroke", {Parent = TabSearchBox, Color = StrokeColor, Thickness = 1})

    local TabContainer = Create("ScrollingFrame", {
        Parent = Sidebar, BackgroundTransparency = 1,
        Size = UDim2.new(1, -15, 1, -40), Position = UDim2.new(0, 10, 0, 40),
        ScrollBarThickness = 0, BorderSizePixel = 0
    })
    Create("UIListLayout", {Parent = TabContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})

    local Divider = Create("Frame", {
        Parent = MainFrame, BackgroundColor3 = StrokeColor,
        BorderSizePixel = 0, Size = UDim2.new(0, 1, 1, -44),
        Position = UDim2.new(0, sideBarWidth, 0, 44), ZIndex = 3,
        BackgroundTransparency = 0.5
    })

    local ContentArea = Create("Frame", {
        Parent = MainFrame, BackgroundTransparency = 1,
        Size = UDim2.new(1, -(sideBarWidth + 5), 1, -44),
        Position = UDim2.new(0, sideBarWidth + 5, 0, 44), Active = true, ZIndex = 4
    })

    -- Minimize sphere
    local Sphere = Create("ImageButton", {
        Parent = ScreenGui, BackgroundColor3 = BackgroundColor,
        BackgroundTransparency = 0.15, Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
        Visible = false, AutoButtonColor = false, ImageTransparency = 1,
        ClipsDescendants = true, ZIndex = 100
    })
    Create("UICorner", {Parent = Sphere, CornerRadius = UDim.new(1, 0)})
    local SphereStroke = Create("UIStroke", {Parent = Sphere, Color = AccentColor, Thickness = 2})
    Create("UIGradient", {
        Parent = SphereStroke,
        Color = ColorSequence.new(AccentColor, AccentSecondary),
        Rotation = 45
    })
    local SphereImageLabel = Create("ImageLabel", {
        Parent = Sphere, BackgroundTransparency = 1,
        Size = UDim2.new(0, sphIconSize, 0, sphIconSize),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = sphImage or "", ImageTransparency = 1,
        Visible = (not sphTextToggle and sphImage ~= nil)
    })
    local SphereTextLabel = Create("TextLabel", {
        Parent = Sphere, Text = sphWords, Font = Enum.Font.GothamBold, TextSize = 16,
        TextColor3 = AccentColor, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), TextTransparency = 1, Visible = sphTextToggle
    })
    MakeDraggable(Sphere, Sphere)
    AddBounce(Sphere, 0.94)

    local Window = {
        CurrentTab = nil, Tabs = {}, Title = Title, AllCards = {},
        MainFrame = MainFrame, CurrentTransparency = 0,
        ConfigElements = {},
        MapId = options and (type(options) == "table") and (options.Map or options.MapId) or nil
    }

    function Window:SetTransparency(val)
        Window.CurrentTransparency = val
        if MainFrame.Visible then
            Tween(MainFrame, {BackgroundTransparency = val}, 0.3)
            Tween(FloatingBottomBar, {BackgroundTransparency = val > 0 and 0.2 or 0}, 0.3)
        end
    end

    function Window:SetMap(mapOption)
        Window.MapId = mapOption
        SaveManager:SetMap(mapOption)
    end

    MinBtn.MouseButton1Click:Connect(function()
        Tween(MainScale, {Scale = 0.4}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        Tween(MainFrame, {BackgroundTransparency = 1}, 0.35)
        Tween(MainStroke, {Transparency = 1}, 0.35)
        Tween(FloatingBottomBar, {BackgroundTransparency = 1}, 0.35)
        Tween(BottomBarStroke, {Transparency = 1}, 0.35)
        task.wait(0.3)
        MainFrame.Visible = false
        BottomDragHitbox.Visible = false
        Sphere.Visible = true
        Sphere.Size = UDim2.new(0, 0, 0, 0)
        Tween(Sphere, {Size = UDim2.new(0, 50, 0, 50)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        if not sphTextToggle and sphImage then
            Tween(SphereImageLabel, {ImageTransparency = 0}, 0.4)
        elseif sphTextToggle then
            Tween(SphereTextLabel, {TextTransparency = 0}, 0.4)
        end
    end)

    Sphere.MouseButton1Click:Connect(function()
        Tween(Sphere, {Size = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        if not sphTextToggle and sphImage then Tween(SphereImageLabel, {ImageTransparency = 1}, 0.3) end
        if sphTextToggle then Tween(SphereTextLabel, {TextTransparency = 1}, 0.3) end
        task.wait(0.2)
        Sphere.Visible = false
        MainFrame.Visible = true
        BottomDragHitbox.Visible = true
        MainScale.Scale = 0.85
        Tween(MainScale, {Scale = 1}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        Tween(MainFrame, {BackgroundTransparency = Window.CurrentTransparency}, 0.4)
        Tween(MainStroke, {Transparency = 0.35}, 0.4)
        Tween(FloatingBottomBar, {BackgroundTransparency = Window.CurrentTransparency > 0 and 0.2 or 0}, 0.4)
        Tween(BottomBarStroke, {Transparency = 0}, 0.4)
    end)

    -- Exit popup
    local Popup = Create("Frame", {
        Parent = ScreenGui, BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 100, Visible = false, Active = true
    })
    local PopupCard = Create("Frame", {
        Parent = Popup, BackgroundColor3 = Color3.fromRGB(20, 20, 26),
        Size = UDim2.new(0, 340, 0, 170),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 101, BackgroundTransparency = 1
    })
    Create("UICorner", {Parent = PopupCard, CornerRadius = UDim.new(0, 14)})
    local PopupScale = Create("UIScale", {Parent = PopupCard, Scale = 0.8})
    local PopupStroke = Create("UIStroke", {Parent = PopupCard, Color = AccentColor, Thickness = 1, Transparency = 1})
    Create("UIGradient", {Parent = PopupStroke, Color = ColorSequence.new(AccentColor, AccentSecondary), Rotation = 45})
    local PopupTitle = Create("TextLabel", {
        Parent = PopupCard, Text = "Exit Application", Font = Enum.Font.GothamBold, TextSize = 18,
        TextColor3 = TextColor, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 25),
        ZIndex = 102, TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center
    })
    local PopupText = Create("TextLabel", {
        Parent = PopupCard,
        Text = "Are you sure you want to close MarvenRiz Hub? Unsaved configurations might be lost.",
        Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = SubTextColor,
        BackgroundTransparency = 1, Size = UDim2.new(1, -40, 0, 40),
        Position = UDim2.new(0, 20, 0, 60), ZIndex = 102, TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true
    })
    local YesBtn = Create("TextButton", {
        Parent = PopupCard, Text = "Confirm", Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = AccentColor,
        Size = UDim2.new(0, 130, 0, 38), Position = UDim2.new(0.5, 10, 0, 110),
        ZIndex = 102, BackgroundTransparency = 1, TextTransparency = 1, AutoButtonColor = false
    })
    Create("UICorner", {Parent = YesBtn, CornerRadius = UDim.new(0, 8)})
    AddBounce(YesBtn, 0.96, true)
    local NoBtn = Create("TextButton", {
        Parent = PopupCard, Text = "Cancel", Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = TextColor, BackgroundColor3 = Color3.fromRGB(45, 45, 58),
        Size = UDim2.new(0, 130, 0, 38), Position = UDim2.new(0.5, -140, 0, 110),
        ZIndex = 102, BackgroundTransparency = 1, TextTransparency = 1, AutoButtonColor = false
    })
    Create("UICorner", {Parent = NoBtn, CornerRadius = UDim.new(0, 8)})
    AddBounce(NoBtn, 0.96, true)

    CloseBtn.MouseButton1Click:Connect(function()
        Popup.Visible = true
        Tween(Popup, {BackgroundTransparency = 0.5}, 0.3)
        Tween(PopupCard, {BackgroundTransparency = 0}, 0.3)
        Tween(PopupScale, {Scale = 1}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        Tween(PopupStroke, {Transparency = 0.2}, 0.3)
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
        Tween(MainScale, {Scale = 0.8}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
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
        Tween(PopupScale, {Scale = 0.8}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        Tween(PopupStroke, {Transparency = 1}, 0.3)
        Tween(PopupTitle, {TextTransparency = 1}, 0.3)
        Tween(PopupText, {TextTransparency = 1}, 0.3)
        Tween(YesBtn, {BackgroundTransparency = 1, TextTransparency = 1}, 0.3)
        Tween(NoBtn, {BackgroundTransparency = 1, TextTransparency = 1}, 0.3)
        task.wait(0.3)
        Popup.Visible = false
    end)

    -- Tab search filtering
    TabSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = TabSearchBox.Text:lower()
        for _, tabInfo in ipairs(Window.Tabs) do
            tabInfo.Button.Visible = (query == "" or string.find(tabInfo.Txt.Text:lower(), query, 1, true) ~= nil)
        end
    end)

    -- Global search filtering
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
                    else
                        card.Visible = false
                    end
                else
                    card.Parent = data.OrigParent
                    card.Visible = true
                end
            end
        end
    end)

    -- ============================================================
    --  TAB
    -- ============================================================
    function Window:CreateTab(tabName, isDefault, isLocked)
        local isWhitelisted = false
        local player = Players.LocalPlayer
        if player then
            for _, allowedUser in ipairs(Library.WhitelistedUsers) do
                if player.Name == allowedUser or player.DisplayName == allowedUser then
                    isWhitelisted = true
                    break
                end
            end
        end

        local TabBtn = Create("TextButton", {
            Parent = TabContainer, Text = "", BackgroundColor3 = HoverColor,
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36),
            AutoButtonColor = false
        })
        Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0, 8)})
        local TabHoverStroke = Create("UIStroke", {Parent = TabBtn, Color = AccentColor, Thickness = 1, Transparency = 1})

        local Indicator = Create("Frame", {
            Name = "Indicator", Parent = TabBtn,
            BackgroundColor3 = isLocked and Color3.fromRGB(255, 215, 0) or AccentColor,
            Size = UDim2.new(0, 3, 0, 0),
            Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5)
        })
        Create("UICorner", {Parent = Indicator, CornerRadius = UDim.new(1, 0)})
        Create("UIGradient", {
            Parent = Indicator,
            Color = ColorSequence.new(
                isLocked and Color3.fromRGB(255, 215, 0) or AccentColor,
                isLocked and Color3.fromRGB(180, 130, 20) or AccentSecondary
            ),
            Rotation = 90
        })

        local Txt = Create("TextLabel", {
            Parent = TabBtn, Text = tabName, Font = Enum.Font.GothamBold, TextSize = 13,
            TextColor3 = SubTextColor, BackgroundTransparency = 1,
            Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 18, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Left
        })

        if isLocked then
            Create("ImageLabel", {
                Parent = TabBtn, Image = "rbxassetid://6031082533",
                ImageColor3 = Color3.fromRGB(255, 215, 0),
                BackgroundTransparency = 1, Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(1, -22, 0.5, -7)
            })
        end

        local TabContent = Create("Frame", {
            Parent = ContentArea, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0), Visible = false
        })
        local PageNav = Create("Frame", {
            Parent = TabContent, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 35), Position = UDim2.new(0, 5, 0, 0)
        })
        Create("UIListLayout", {
            Parent = PageNav,
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 15),
            VerticalAlignment = Enum.VerticalAlignment.Center
        })
        local PageContainer = Create("Frame", {
            Parent = TabContent, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, -35), Position = UDim2.new(0, 0, 0, 35)
        })

        local TabConfig = {
            Button = TabBtn, Content = TabContent, Indicator = Indicator,
            Txt = Txt, Pages = {}, CurrentPage = nil
        }
        table.insert(Window.Tabs, TabConfig)

        TabBtn.MouseEnter:Connect(function()
            if Window.CurrentTab ~= TabConfig then
                Tween(TabBtn, {BackgroundTransparency = 0.6}, 0.2)
                Tween(TabHoverStroke, {Transparency = 0.85}, 0.2)
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if Window.CurrentTab ~= TabConfig then
                Tween(TabBtn, {BackgroundTransparency = 1}, 0.2)
                Tween(TabHoverStroke, {Transparency = 1}, 0.2)
            end
        end)

        TabBtn.MouseButton1Click:Connect(function()
            if isLocked and not isWhitelisted then
                SendPremiumNotification()
                return
            end
            if Window.CurrentTab == TabConfig then return end

            if Window.CurrentTab then
                Tween(Window.CurrentTab.Button, {BackgroundTransparency = 1}, 0.25)
                Tween(Window.CurrentTab.Indicator, {Size = UDim2.new(0, 3, 0, 0)}, 0.25)
                Tween(Window.CurrentTab.Txt, {TextColor3 = SubTextColor}, 0.25)
                Window.CurrentTab.Content.Visible = false
            end

            Window.CurrentTab = TabConfig
            TabConfig.Content.Visible = true
            TabConfig.Content.Position = UDim2.new(0, 12, 0, 0)
            Tween(TabConfig.Content, {Position = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

            Tween(TabBtn, {BackgroundTransparency = 0.4}, 0.25)
            SpringTween(Indicator, {Size = UDim2.new(0, 3, 0, 20)}, 0.4)
            Tween(Txt, {TextColor3 = TextColor}, 0.25)

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
                    Tween(firstPage.Scroll, {Position = UDim2.new(0, 5, 0, 5)}, 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                    Tween(firstPage.Btn, {TextColor3 = TextColor}, 0)
                    Tween(firstPage.Highlight, {Size = UDim2.new(1, 0, 0, 2), BackgroundTransparency = 0}, 0)
                end
            end
        end)

        function TabConfig:CreatePage(pageName)
            local PageBtn = Create("TextButton", {
                Parent = PageNav, Text = pageName, Font = Enum.Font.GothamBold, TextSize = 13,
                TextColor3 = SubTextColor, BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
                AutoButtonColor = false
            })
            Create("UIPadding", {Parent = PageBtn, PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4)})
            local PageHighlight = Create("Frame", {
                Parent = PageBtn, BackgroundColor3 = AccentColor,
                Size = UDim2.new(0, 0, 0, 2),
                Position = UDim2.new(0.5, 0, 1, -6),
                AnchorPoint = Vector2.new(0.5, 0),
                BackgroundTransparency = 1
            })
            Create("UICorner", {Parent = PageHighlight, CornerRadius = UDim.new(1, 0)})
            Create("UIGradient", {
                Parent = PageHighlight,
                Color = ColorSequence.new(AccentColor, AccentSecondary),
                Rotation = 0
            })

            local PageScroll = Create("ScrollingFrame", {
                Parent = PageContainer, BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5),
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = AccentColor,
                Visible = false, BorderSizePixel = 0
            })
            local LeftColumn = Create("Frame", {Parent = PageScroll, BackgroundTransparency = 1, Size = UDim2.new(0.5, -6, 1, 0)})
            local RightColumn = Create("Frame", {
                Parent = PageScroll, BackgroundTransparency = 1,
                Size = UDim2.new(0.5, -6, 1, 0), Position = UDim2.new(0.5, 6, 0, 0)
            })
            local L_Layout = Create("UIListLayout", {Parent = LeftColumn, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12)})
            local R_Layout = Create("UIListLayout", {Parent = RightColumn, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12)})
            L_Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                PageScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(L_Layout.AbsoluteContentSize.Y, R_Layout.AbsoluteContentSize.Y) + 20)
            end)
            R_Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                PageScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(L_Layout.AbsoluteContentSize.Y, R_Layout.AbsoluteContentSize.Y) + 20)
            end)

            local PageObj = {
                Scroll = PageScroll, Btn = PageBtn, Highlight = PageHighlight,
                Left = true, LeftCol = LeftColumn, RightCol = RightColumn
            }
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
                PageObj.Scroll.Position = UDim2.new(0, 5, 0, 18)
                Tween(PageObj.Scroll, {Position = UDim2.new(0, 5, 0, 5)}, 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
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

            -- ============================================================
            --  SECTION / ELEMENTS
            -- ============================================================
            function PageObj:CreateSection(sectionName, side)
                local targetColumn
                if side == "Left" or side == "left" then
                    targetColumn = LeftColumn
                elseif side == "Right" or side == "right" then
                    targetColumn = RightColumn
                else
                    targetColumn = PageObj.Left and LeftColumn or RightColumn
                    PageObj.Left = not PageObj.Left
                end

                local SectionContainer = Create("Frame", {
                    Parent = targetColumn, BackgroundColor3 = CardColor,
                    Size = UDim2.new(1, 0, 0, 34),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ClipsDescendants = true
                })
                Create("UICorner", {Parent = SectionContainer, CornerRadius = UDim.new(0, 10)})
                local SectionStroke = Create("UIStroke", {Parent = SectionContainer, Color = StrokeColor, Thickness = 1, Transparency = 0.4})
                -- Gradient accent line at top of section
                local SectionAccent = Create("Frame", {
                    Parent = SectionContainer, BackgroundColor3 = AccentColor,
                    Size = UDim2.new(1, -40, 0, 2),
                    Position = UDim2.new(0, 20, 0, 0),
                    BorderSizePixel = 0
                })
                Create("UICorner", {Parent = SectionAccent, CornerRadius = UDim.new(1, 0)})
                Create("UIGradient", {
                    Parent = SectionAccent,
                    Color = ColorSequence.new(AccentColor, AccentSecondary),
                    Rotation = 0
                })

                table.insert(Window.AllCards, {
                    Card = SectionContainer,
                    OrigParent = targetColumn,
                    Tab = TabConfig,
                    Page = PageObj,
                    SearchIndex = nil
                })

                local Title = Create("TextLabel", {
                    Parent = SectionContainer, Text = sectionName, Font = Enum.Font.GothamBold,
                    TextSize = 13, TextColor3 = TextColor, BackgroundTransparency = 1,
                    Size = UDim2.new(1, -20, 0, 34), Position = UDim2.new(0, 12, 0, 4),
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local ItemContainer = Create("Frame", {
                    Parent = SectionContainer, BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 34),
                    AutomaticSize = Enum.AutomaticSize.Y
                })
                Create("UIPadding", {Parent = ItemContainer, PaddingBottom = UDim.new(0, 12), PaddingTop = UDim.new(0, 4)})
                Create("UIListLayout", {Parent = ItemContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})

                local Elements = {}

                function Elements:AddCopyButton(name, copyText, infoData)
                    local BtnFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34)})
                    local Btn = Create("TextButton", {
                        Parent = BtnFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12,
                        TextColor3 = TextColor, BackgroundColor3 = CardElevated,
                        Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0),
                        AutoButtonColor = false
                    })
                    Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)})
                    local St = Create("UIStroke", {Parent = Btn, Color = StrokeColor, Thickness = 1, Transparency = 0.3})

                    AddBounce(Btn, 0.97, true)
                    Btn.MouseEnter:Connect(function()
                        Tween(Btn, {BackgroundColor3 = HoverColor}, 0.2)
                        Tween(St, {Color = AccentColor, Transparency = 0}, 0.2)
                    end)
                    Btn.MouseLeave:Connect(function()
                        Tween(Btn, {BackgroundColor3 = CardElevated}, 0.2)
                        Tween(St, {Color = StrokeColor, Transparency = 0.3}, 0.2)
                    end)
                    Btn.MouseButton1Click:Connect(function()
                        SafeCopyToClipboard(copyText)
                        local oldText = Btn.Text
                        Btn.Text = "Copied to Clipboard!"
                        Tween(Btn, {TextColor3 = AccentColor, BackgroundColor3 = HoverColor}, 0.2)
                        task.wait(1.5)
                        if Btn.Parent then
                            Btn.Text = oldText
                            Tween(Btn, {TextColor3 = TextColor, BackgroundColor3 = CardElevated}, 0.2)
                        end
                    end)
                    AddInfoIcon(BtnFrame, UDim2.new(1, -40, 0.5, -8), infoData)
                end

                function Elements:AddButton(name, callback, infoData)
                    local BtnFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34)})
                    local Btn = Create("TextButton", {
                        Parent = BtnFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12,
                        TextColor3 = TextColor, BackgroundColor3 = CardElevated,
                        Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0),
                        AutoButtonColor = false
                    })
                    Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)})
                    local St = Create("UIStroke", {Parent = Btn, Color = StrokeColor, Thickness = 1, Transparency = 0.3})

                    AddBounce(Btn, 0.97, true)
                    Btn.MouseEnter:Connect(function()
                        Tween(Btn, {BackgroundColor3 = HoverColor}, 0.2)
                        Tween(St, {Color = AccentColor, Transparency = 0}, 0.2)
                    end)
                    Btn.MouseLeave:Connect(function()
                        Tween(Btn, {BackgroundColor3 = CardElevated}, 0.2)
                        Tween(St, {Color = StrokeColor, Transparency = 0.3}, 0.2)
                    end)
                    Btn.MouseButton1Click:Connect(function() if callback then callback() end end)
                    AddInfoIcon(BtnFrame, UDim2.new(1, -40, 0.5, -8), infoData)
                end

                function Elements:AddParagraph(title, content, infoData)
                    local hasTitle = title ~= nil and title ~= ""
                    local ParaWrap = Create("Frame", {
                        Parent = ItemContainer, BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y
                    })
                    local ParaFrame = Create("Frame", {
                        Parent = ParaWrap, BackgroundColor3 = CardElevated,
                        Position = UDim2.new(0, 10, 0, 0),
                        Size = UDim2.new(1, -20, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y
                    })
                    Create("UICorner", {Parent = ParaFrame, CornerRadius = UDim.new(0, 8)})
                    Create("UIStroke", {Parent = ParaFrame, Color = StrokeColor, Thickness = 1, Transparency = 0.4})
                    Create("UIPadding", {
                        Parent = ParaFrame,
                        PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 32),
                        PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)
                    })

                    local TitleLbl = Create("TextLabel", {
                        Parent = ParaFrame, Text = title or "", Font = Enum.Font.GothamBold,
                        TextSize = 14, TextColor3 = TextColor, BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, hasTitle and 16 or 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
                        Visible = hasTitle, ClipsDescendants = true
                    })
                    local ContentLbl = Create("TextLabel", {
                        Parent = ParaFrame, Text = content or "", Font = Enum.Font.Gotham,
                        TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 0),
                        Position = hasTitle and UDim2.new(0, 0, 0, 22) or UDim2.new(0, 0, 0, 0),
                        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
                        TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, LineHeight = 1.2
                    })
                    AddInfoIcon(ParaFrame, UDim2.new(1, -24, 0, 8), infoData)

                    local function SetTitle(_self, t)
                        if t == nil and _self ~= nil and type(_self) ~= "table" then t = _self end
                        local show = t ~= nil and t ~= ""
                        TitleLbl.Text = t or ""
                        TitleLbl.Visible = show
                        Tween(TitleLbl, {Size = UDim2.new(1, 0, 0, show and 16 or 0)}, 0.2)
                        Tween(ContentLbl, {Position = show and UDim2.new(0, 0, 0, 22) or UDim2.new(0, 0, 0, 0)}, 0.2)
                    end
                    local function SetContent(_self, c)
                        if c == nil and _self ~= nil and type(_self) ~= "table" then c = _self end
                        ContentLbl.Text = c or ""
                    end

                    return {SetTitle = SetTitle, SetContent = SetContent}
                end

                function Elements:AddToggle(name, default, callback, infoData)
                    local state = default or false
                    local TogFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26)})

                    Create("TextLabel", {
                        Parent = TogFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12,
                        TextColor3 = SubTextColor, BackgroundTransparency = 1,
                        Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 10, 0, 0),
                        TextXAlignment = Enum.TextXAlignment.Left
                    })

                    local Lever = Create("TextButton", {
                        Parent = TogFrame, Text = "",
                        BackgroundColor3 = state and AccentColor or Color3.fromRGB(45, 45, 58),
                        Size = UDim2.new(0, 36, 0, 18),
                        Position = UDim2.new(1, -46, 0.5, -9),
                        AutoButtonColor = false
                    })
                    Create("UICorner", {Parent = Lever, CornerRadius = UDim.new(1, 0)})
                    AddBounce(Lever, 0.94, true)

                    local Knob = Create("Frame", {
                        Parent = Lever, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Size = UDim2.new(0, 14, 0, 14),
                        Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
                    })
                    Create("UICorner", {Parent = Knob, CornerRadius = UDim.new(1, 0)})

                    local function internalSet(val)
                        state = val
                        Tween(Lever, {BackgroundColor3 = state and AccentColor or Color3.fromRGB(45, 45, 58)}, 0.3)
                        Tween(Knob, {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                        if callback then callback(state) end
                    end

                    Lever.MouseButton1Click:Connect(function() internalSet(not state) end)
                    AddInfoIcon(TogFrame, UDim2.new(1, -70, 0.5, -8), infoData)

                    if callback then callback(state) end
                    Window.ConfigElements[name] = { Set = internalSet, Get = function() return state end }
                end

                function Elements:AddSlider(name, min, max, default, callback, infoData)
                    local val = default or min
                    local SliFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48)})

                    Create("TextLabel", {
                        Parent = SliFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12,
                        TextColor3 = SubTextColor, BackgroundTransparency = 1,
                        Size = UDim2.new(1, -20, 0, 15), Position = UDim2.new(0, 10, 0, 0),
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    local ValTxt = Create("TextLabel", {
                        Parent = SliFrame, Text = tostring(val), Font = Enum.Font.GothamBold,
                        TextSize = 12, TextColor3 = AccentColor, BackgroundTransparency = 1,
                        Size = UDim2.new(0, 40, 0, 15), Position = UDim2.new(1, -50, 0, 0),
                        TextXAlignment = Enum.TextXAlignment.Right
                    })

                    local TrackBase = Create("Frame", {
                        Parent = SliFrame, BackgroundColor3 = Color3.fromRGB(30, 30, 40),
                        Size = UDim2.new(1, -20, 0, 6), Position = UDim2.new(0, 10, 0, 28)
                    })
                    Create("UICorner", {Parent = TrackBase, CornerRadius = UDim.new(1, 0)})

                    local Fill = Create("Frame", {
                        Parent = TrackBase, BackgroundColor3 = AccentColor,
                        Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
                    })
                    Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})
                    Create("UIGradient", {
                        Parent = Fill,
                        Color = ColorSequence.new(AccentColor, AccentSecondary),
                        Rotation = 0
                    })

                    local Knob = Create("Frame", {
                        Parent = Fill, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Size = UDim2.new(0, 14, 0, 14),
                        Position = UDim2.new(1, -7, 0.5, -7),
                        ZIndex = 2
                    })
                    Create("UICorner", {Parent = Knob, CornerRadius = UDim.new(1, 0)})
                    local KnobStroke = Create("UIStroke", {Parent = Knob, Color = AccentColor, Thickness = 2})

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

                    Knob.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = true
                            Tween(Knob, {Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -9, 0.5, -9)}, 0.2)
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = false
                            Tween(Knob, {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -7, 0.5, -7)}, 0.2)
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                            Update(input)
                        end
                    end)
                    AddInfoIcon(SliFrame, UDim2.new(1, -72, 0, 0), infoData)

                    if callback then callback(val) end
                    Window.ConfigElements[name] = { Set = internalSet, Get = function() return val end }
                end

                function Elements:AddDropdown(name, options, isMulti, default, callback, infoData)
                    local selected
                    if isMulti then
                        selected = (type(default) == "table") and default or {}
                    else
                        selected = (default ~= nil) and default or (options[1] or nil)
                    end
                    local dropped = false
                    local optionButtons = {}
                    local optionValues = {}
                    local maxVisible = math.min(#options, 6)
                    local listHeight = math.max(maxVisible, 1) * 25

                    local DropFrame = Create("Frame", {
                        Parent = ItemContainer, BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 52), ClipsDescendants = true
                    })
                    Create("TextLabel", {
                        Parent = DropFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12,
                        TextColor3 = SubTextColor, BackgroundTransparency = 1,
                        Size = UDim2.new(1, -20, 0, 15), Position = UDim2.new(0, 10, 0, 0),
                        TextXAlignment = Enum.TextXAlignment.Left
                    })

                    local MainBtn = Create("TextButton", {
                        Parent = DropFrame, Text = isMulti and "Select Options..." or "Select...",
                        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor,
                        BackgroundColor3 = CardElevated,
                        Size = UDim2.new(1, -20, 0, 28), Position = UDim2.new(0, 10, 0, 20),
                        AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left
                    })
                    Create("UIPadding", {Parent = MainBtn, PaddingLeft = UDim.new(0, 10)})
                    Create("UICorner", {Parent = MainBtn, CornerRadius = UDim.new(0, 6)})
                    local MainBtnStroke = Create("UIStroke", {Parent = MainBtn, Color = StrokeColor, Thickness = 1, Transparency = 0.3})
                    AddBounce(MainBtn, 0.98, true)

                    local Arrow = Create("TextLabel", {
                        Parent = MainBtn, Text = "▼", Font = Enum.Font.Gotham, TextSize = 10,
                        TextColor3 = SubTextColor, BackgroundTransparency = 1,
                        Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -30, 0, 0)
                    })

                    local SearchBox = Create("TextBox", {
                        Parent = DropFrame, PlaceholderText = "Search...", Font = Enum.Font.Gotham,
                        TextSize = 12, TextColor3 = TextColor,
                        BackgroundColor3 = Color3.fromRGB(15, 15, 20),
                        Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 52),
                        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Visible = false
                    })
                    Create("UIPadding", {Parent = SearchBox, PaddingLeft = UDim.new(0, 8)})
                    Create("UICorner", {Parent = SearchBox, CornerRadius = UDim.new(0, 6)})
                    Create("UIStroke", {Parent = SearchBox, Color = StrokeColor, Thickness = 1})

                    local ListFrame = Create("ScrollingFrame", {
                        Parent = DropFrame, BackgroundColor3 = Color3.fromRGB(15, 15, 20),
                        Size = UDim2.new(1, -20, 0, listHeight),
                        Position = UDim2.new(0, 10, 0, 82),
                        CanvasSize = UDim2.new(0, 0, 0, #options * 25),
                        ScrollBarThickness = 3, ScrollBarImageColor3 = AccentColor,
                        BorderSizePixel = 0, ScrollingDirection = Enum.ScrollingDirection.Y,
                        ElasticBehavior = Enum.ElasticBehavior.Always
                    })
                    Create("UICorner", {Parent = ListFrame, CornerRadius = UDim.new(0, 6)})
                    local DList = Create("UIListLayout", {Parent = ListFrame, SortOrder = Enum.SortOrder.LayoutOrder})
                    Create("UIPadding", {Parent = ListFrame, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4)})

                    local function ToDisplay(v) return v == nil and "" or tostring(v) end
                    local function ValuesEqual(a, b) return a == b end

                    local function UpdateText()
                        if isMulti then
                            local txt = ""
                            for _, v in pairs(selected) do txt = txt .. ToDisplay(v) .. ", " end
                            MainBtn.Text = txt == "" and "Select Options..." or txt:sub(1, -3)
                        else
                            MainBtn.Text = (selected ~= nil) and ToDisplay(selected) or "Select..."
                        end
                    end

                    local function internalSet(v)
                        selected = v
                        UpdateText()
                        for _, btn in ipairs(optionButtons) do
                            local optVal = optionValues[btn]
                            local isSel = false
                            if isMulti then
                                isSel = type(selected) == "table" and table.find(selected, optVal) ~= nil
                            else
                                isSel = ValuesEqual(selected, optVal)
                            end
                            Tween(btn, {TextColor3 = isSel and TextColor or SubTextColor, BackgroundTransparency = isSel and 0.85 or 1}, 0.2)
                        end
                        if callback then callback(selected) end
                    end

                    local function RenderOptions(newOptions)
                        options = newOptions or options
                        for _, btn in ipairs(optionButtons) do btn:Destroy() end
                        optionButtons = {}
                        optionValues = {}

                        for _, opt in pairs(options) do
                            local isInitialSelected = (not isMulti and ValuesEqual(selected, opt))
                                or (isMulti and type(selected) == "table" and table.find(selected, opt) ~= nil)

                            local OptBtn = Create("TextButton", {
                                Parent = ListFrame, Text = ToDisplay(opt), Font = Enum.Font.Gotham,
                                TextSize = 12, TextColor3 = isInitialSelected and TextColor or SubTextColor,
                                BackgroundColor3 = AccentColor,
                                BackgroundTransparency = isInitialSelected and 0.85 or 1,
                                Size = UDim2.new(1, 0, 0, 26), AutoButtonColor = false
                            })
                            Create("UIPadding", {Parent = OptBtn, PaddingLeft = UDim.new(0, 8)})
                            table.insert(optionButtons, OptBtn)
                            optionValues[OptBtn] = opt

                            OptBtn.MouseEnter:Connect(function()
                                if optionValues[OptBtn] ~= selected then
                                    Tween(OptBtn, {BackgroundTransparency = 0.92}, 0.15)
                                end
                            end)
                            OptBtn.MouseLeave:Connect(function()
                                if optionValues[OptBtn] ~= selected then
                                    Tween(OptBtn, {BackgroundTransparency = 1}, 0.15)
                                end
                            end)

                            OptBtn.MouseButton1Click:Connect(function()
                                if isMulti then
                                    local idx = table.find(selected, opt)
                                    if idx then table.remove(selected, idx) else table.insert(selected, opt) end
                                    internalSet(selected)
                                else
                                    internalSet(opt)
                                    dropped = false
                                    Tween(Arrow, {Rotation = 0}, 0.3)
                                    Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 52)}, 0.3)
                                    SearchBox.Visible = false
                                end
                            end)
                        end

                        maxVisible = math.min(#options, 6)
                        listHeight = math.max(maxVisible, 1) * 25
                        ListFrame.CanvasSize = UDim2.new(0, 0, 0, DList.AbsoluteContentSize.Y)

                        if dropped then
                            local dynamicHeight = math.min(DList.AbsoluteContentSize.Y, listHeight)
                            ListFrame.Size = UDim2.new(1, -20, 0, dynamicHeight)
                            Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 52 + 32 + dynamicHeight)}, 0.1)
                        end
                    end

                    local function RefreshOptions(newOptions, preserveSelection)
                        newOptions = newOptions or options
                        preserveSelection = (preserveSelection == nil) and true or preserveSelection
                        if isMulti then
                            if preserveSelection and type(selected) == "table" then
                                local kept = {}
                                for _, v in ipairs(selected) do
                                    if table.find(newOptions, v) then table.insert(kept, v) end
                                end
                                selected = kept
                            else
                                selected = {}
                            end
                        else
                            if not (preserveSelection and table.find(newOptions, selected)) then
                                selected = newOptions[1]
                            end
                        end
                        RenderOptions(newOptions)
                        UpdateText()
                        if callback then callback(selected) end
                    end

                    RenderOptions(options)
                    UpdateText()

                    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        local q = SearchBox.Text:lower()
                        for _, btn in ipairs(optionButtons) do
                            btn.Visible = (q == "" or string.find(btn.Text:lower(), q, 1, true) ~= nil)
                        end
                    end)

                    DList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                        ListFrame.CanvasSize = UDim2.new(0, 0, 0, DList.AbsoluteContentSize.Y)
                        if dropped then
                            local dynamicHeight = math.min(DList.AbsoluteContentSize.Y, listHeight)
                            ListFrame.Size = UDim2.new(1, -20, 0, dynamicHeight)
                            Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 52 + 32 + dynamicHeight)}, 0.1)
                        end
                    end)

                    MainBtn.MouseButton1Click:Connect(function()
                        dropped = not dropped
                        if dropped then
                            SearchBox.Visible = true
                            SearchBox.Text = ""
                            Tween(Arrow, {Rotation = 180}, 0.3)
                            local dynamicHeight = math.min(DList.AbsoluteContentSize.Y, listHeight)
                            ListFrame.Size = UDim2.new(1, -20, 0, dynamicHeight)
                            Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 52 + 32 + dynamicHeight)}, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                        else
                            SearchBox.Visible = false
                            Tween(Arrow, {Rotation = 0}, 0.3)
                            Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 52)}, 0.3)
                        end
                    end)
                    AddInfoIcon(DropFrame, UDim2.new(1, -25, 0, 0), infoData)

                    if callback then callback(selected) end
                    Window.ConfigElements[name] = { Set = internalSet, Get = function() return selected end }

                    local DropdownHandle = {}
                    DropdownHandle.Refresh = function(_self, newOptions, preserveSelection) RefreshOptions(newOptions, preserveSelection) end
                    DropdownHandle.RefreshOptions = DropdownHandle.Refresh
                    DropdownHandle.SetOptions = DropdownHandle.Refresh
                    DropdownHandle.Set = internalSet
                    DropdownHandle.Get = function() return selected end
                    return DropdownHandle
                end

                function Elements:AddTextbox(name, placeholder, default, callback, infoData)
                    local TxtFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 52)})
                    Create("TextLabel", {
                        Parent = TxtFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12,
                        TextColor3 = SubTextColor, BackgroundTransparency = 1,
                        Size = UDim2.new(1, -20, 0, 15), Position = UDim2.new(0, 10, 0, 0),
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    local Input = Create("TextBox", {
                        Parent = TxtFrame,
                        PlaceholderText = placeholder or "Type here...",
                        Text = default ~= nil and tostring(default) or "",
                        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor,
                        BackgroundColor3 = CardElevated,
                        Size = UDim2.new(1, -20, 0, 28), Position = UDim2.new(0, 10, 0, 20),
                        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false
                    })
                    Create("UIPadding", {Parent = Input, PaddingLeft = UDim.new(0, 10)})
                    Create("UICorner", {Parent = Input, CornerRadius = UDim.new(0, 6)})
                    local St = Create("UIStroke", {Parent = Input, Color = StrokeColor, Thickness = 1, Transparency = 0.3})
                    Input.Focused:Connect(function() Tween(St, {Color = AccentColor, Transparency = 0}, 0.2) end)
                    Input.FocusLost:Connect(function() Tween(St, {Color = StrokeColor, Transparency = 0.3}, 0.2) end)

                    local function internalSet(v)
                        Input.Text = tostring(v)
                        if callback then callback(v) end
                    end
                    Input.FocusLost:Connect(function(enterPressed) internalSet(Input.Text) end)
                    AddInfoIcon(TxtFrame, UDim2.new(1, -25, 0, 0), infoData)
                    if callback then callback(Input.Text) end
                    Window.ConfigElements[name] = { Set = internalSet, Get = function() return Input.Text end }
                end

                function Elements:AddColorPicker(name, defaultColor, callback, infoData)
                    local color = Color3.fromRGB(255, 255, 255)
                    if typeof(defaultColor) == "Color3" then
                        color = defaultColor
                    elseif type(defaultColor) == "string" then
                        local okHex, cHex = pcall(function() return Color3.fromHex(defaultColor) end)
                        if okHex then color = cHex end
                    end
                    local h, s, v_hsv = color:ToHSV()
                    local dropped = false

                    local CFrame = Create("Frame", {
                        Parent = ItemContainer, BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 34), ClipsDescendants = true
                    })
                    Create("TextLabel", {
                        Parent = CFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12,
                        TextColor3 = SubTextColor, BackgroundTransparency = 1,
                        Size = UDim2.new(1, -60, 0, 34), Position = UDim2.new(0, 10, 0, 0),
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    local DisplayBtn = Create("TextButton", {
                        Parent = CFrame, Text = "", BackgroundColor3 = color,
                        Size = UDim2.new(0, 34, 0, 18),
                        Position = UDim2.new(1, -44, 0.5, -9),
                        AutoButtonColor = false
                    })
                    Create("UICorner", {Parent = DisplayBtn, CornerRadius = UDim.new(0, 6)})
                    Create("UIStroke", {Parent = DisplayBtn, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.8, Thickness = 1})
                    AddBounce(DisplayBtn, 0.94, true)

                    local PickerArea = Create("Frame", {
                        Parent = CFrame, BackgroundColor3 = CardElevated,
                        Size = UDim2.new(1, -20, 0, 150), Position = UDim2.new(0, 10, 0, 40)
                    })
                    Create("UICorner", {Parent = PickerArea, CornerRadius = UDim.new(0, 8)})

                    local PickerClose = Create("TextButton", {
                        Parent = PickerArea, Text = "X", Font = Enum.Font.GothamBold, TextSize = 11,
                        TextColor3 = SubTextColor, BackgroundColor3 = Color3.fromRGB(30, 20, 20),
                        Size = UDim2.new(0, 18, 0, 18),
                        Position = UDim2.new(1, -22, 0, 6), ZIndex = 50, AutoButtonColor = false
                    })
                    Create("UICorner", {Parent = PickerClose, CornerRadius = UDim.new(0, 4)})
                    AddBounce(PickerClose)
                    PickerClose.MouseEnter:Connect(function() Tween(PickerClose, {TextColor3 = Color3.fromRGB(255, 60, 60)}, 0.2) end)
                    PickerClose.MouseLeave:Connect(function() Tween(PickerClose, {TextColor3 = SubTextColor}, 0.2) end)
                    PickerClose.MouseButton1Click:Connect(function()
                        dropped = false
                        Tween(CFrame, {Size = UDim2.new(1, 0, 0, 34)}, 0.3)
                    end)

                    local SVMap = Create("TextButton", {
                        Parent = PickerArea, Text = "", BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                        Size = UDim2.new(1, -45, 0, 90), Position = UDim2.new(0, 10, 0, 30),
                        AutoButtonColor = false, Active = true
                    })
                    Create("UICorner", {Parent = SVMap, CornerRadius = UDim.new(0, 6)})
                    local WhiteGrad = Create("Frame", {Parent = SVMap, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2})
                    Create("UIGradient", {Parent = WhiteGrad, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}), Rotation = 0})
                    Create("UICorner", {Parent = WhiteGrad, CornerRadius = UDim.new(0, 6)})
                    local BlackGrad = Create("Frame", {Parent = SVMap, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 3})
                    Create("UIGradient", {Parent = BlackGrad, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}), Rotation = 90})
                    Create("UICorner", {Parent = BlackGrad, CornerRadius = UDim.new(0, 6)})

                    local SVRing = Create("Frame", {
                        Parent = BlackGrad, Size = UDim2.new(0, 12, 0, 12),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(s, 0, 1 - v_hsv, 0),
                        BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 4
                    })
                    Create("UICorner", {Parent = SVRing, CornerRadius = UDim.new(1, 0)})
                    Create("UIStroke", {Parent = SVRing, Color = Color3.new(0, 0, 0), Thickness = 2})

                    local HueSlider = Create("TextButton", {
                        Parent = PickerArea, Text = "",
                        Size = UDim2.new(1, -20, 0, 15), Position = UDim2.new(0, 10, 0, 125),
                        AutoButtonColor = false, BackgroundColor3 = Color3.new(1, 1, 1), Active = true
                    })
                    Create("UICorner", {Parent = HueSlider, CornerRadius = UDim.new(1, 0)})
                    Create("UIGradient", {
                        Parent = HueSlider,
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                            ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                            ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                            ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
                            ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                        })
                    })
                    local HueRing = Create("Frame", {
                        Parent = HueSlider, Size = UDim2.new(0, 8, 0, 19),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(h, 0, 0.5, 0),
                        BackgroundColor3 = Color3.new(1, 1, 1)
                    })
                    Create("UICorner", {Parent = HueRing, CornerRadius = UDim.new(1, 0)})
                    Create("UIStroke", {Parent = HueRing, Color = Color3.new(0, 0, 0), Thickness = 2})

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

                    local draggingSV = false
                    local draggingHue = false
                    SVMap.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            draggingSV = true
                            if PageObj and PageObj.Scroll then PageObj.Scroll.ScrollingEnabled = false end
                        end
                    end)
                    HueSlider.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            draggingHue = true
                            if PageObj and PageObj.Scroll then PageObj.Scroll.ScrollingEnabled = false end
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            draggingSV = false
                            draggingHue = false
                            if PageObj and PageObj.Scroll then PageObj.Scroll.ScrollingEnabled = true end
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                            if draggingSV then
                                local relX = math.clamp((input.Position.X - SVMap.AbsolutePosition.X) / SVMap.AbsoluteSize.X, 0, 1)
                                local relY = math.clamp((input.Position.Y - SVMap.AbsolutePosition.Y) / SVMap.AbsoluteSize.Y, 0, 1)
                                s = relX
                                v_hsv = 1 - relY
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

                    DisplayBtn.MouseButton1Click:Connect(function()
                        dropped = not dropped
                        Tween(CFrame, {Size = UDim2.new(1, 0, 0, dropped and 200 or 34)}, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                    end)
                    AddInfoIcon(CFrame, UDim2.new(1, -70, 0, 8), infoData)

                    if callback then callback(color) end
                    Window.ConfigElements[name] = { Set = internalSet, Get = function() return color:ToHex() end }
                end

                function Elements:AddConfigManager(folderName)
                    folderName = folderName or "MarvenRizSave"
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

                    local ManagerFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 300)})

                    local ManagerSearch = Create("TextBox", {
                        Parent = ManagerFrame, PlaceholderText = "Search Saves Loader...",
                        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor,
                        BackgroundColor3 = CardElevated,
                        Size = UDim2.new(1, -20, 0, 28), Position = UDim2.new(0, 10, 0, 0),
                        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false
                    })
                    Create("UIPadding", {Parent = ManagerSearch, PaddingLeft = UDim.new(0, 10)})
                    Create("UICorner", {Parent = ManagerSearch, CornerRadius = UDim.new(0, 6)})
                    Create("UIStroke", {Parent = ManagerSearch, Color = StrokeColor, Thickness = 1, Transparency = 0.3})

                    local Monitor = Create("ScrollingFrame", {
                        Parent = ManagerFrame, BackgroundColor3 = Color3.fromRGB(15, 15, 20),
                        Size = UDim2.new(1, -20, 0, 110), Position = UDim2.new(0, 10, 0, 38),
                        ScrollBarThickness = 3, BorderSizePixel = 0,
                        ScrollBarImageColor3 = AccentColor,
                        CanvasSize = UDim2.new(0, 0, 0, 0)
                    })
                    Create("UICorner", {Parent = Monitor, CornerRadius = UDim.new(0, 6)})
                    Create("UIStroke", {Parent = Monitor, Color = StrokeColor, Thickness = 1, Transparency = 0.3})
                    local MonitorLayout = Create("UIListLayout", {Parent = Monitor, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
                    Create("UIPadding", {
                        Parent = Monitor, PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5),
                        PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)
                    })
                    MonitorLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                        Monitor.CanvasSize = UDim2.new(0, 0, 0, MonitorLayout.AbsoluteContentSize.Y + 10)
                    end)

                    local deleteMode = false
                    local editMode = false
                    local selectedForDelete = {}
                    local editTargetFile = ""

                    local AutoloadRow = Create("Frame", {
                        Parent = ManagerFrame, BackgroundTransparency = 1,
                        Size = UDim2.new(1, -20, 0, 28), Position = UDim2.new(0, 10, 0, 158)
                    })
                    Create("TextLabel", {
                        Parent = AutoloadRow, Text = "Auto Load", Font = Enum.Font.Gotham,
                        TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1,
                        Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 0, 0, 0),
                        TextXAlignment = Enum.TextXAlignment.Left
                    })

                    local autoloadState = ReadAutoloadData().Enabled == true
                    local AutoloadLever = Create("TextButton", {
                        Parent = AutoloadRow, Text = "",
                        BackgroundColor3 = autoloadState and AccentColor or Color3.fromRGB(45, 45, 58),
                        Size = UDim2.new(0, 36, 0, 18),
                        Position = UDim2.new(1, -36, 0.5, -9), AutoButtonColor = false
                    })
                    Create("UICorner", {Parent = AutoloadLever, CornerRadius = UDim.new(1, 0)})
                    AddBounce(AutoloadLever, 0.94, true)
                    local AutoloadKnob = Create("Frame", {
                        Parent = AutoloadLever, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Size = UDim2.new(0, 14, 0, 14),
                        Position = autoloadState and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
                    })
                    Create("UICorner", {Parent = AutoloadKnob, CornerRadius = UDim.new(1, 0)})

                    AutoloadLever.MouseButton1Click:Connect(function()
                        local data = ReadAutoloadData()
                        if not autoloadState and not data.Path then
                            Library:Notify({Title = "Auto Load", Description = "Pick a saved config with the star (☆) first, then enable Auto Load.", Duration = 3, Type = "warn"})
                            return
                        end
                        autoloadState = not autoloadState
                        data.Enabled = autoloadState
                        WriteAutoloadData(data)
                        Tween(AutoloadLever, {BackgroundColor3 = autoloadState and AccentColor or Color3.fromRGB(45, 45, 58)}, 0.3)
                        Tween(AutoloadKnob, {Position = autoloadState and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                        Library:Notify({
                            Title = "Auto Load " .. (autoloadState and "Enabled" or "Disabled"),
                            Description = autoloadState and "Your remembered config will now load automatically on startup." or "Auto Load turned off. Your remembered config is still saved.",
                            Duration = 3,
                            Type = autoloadState and "success" or "info"
                        })
                    end)

                    local Controls = Create("Frame", {
                        Parent = ManagerFrame, BackgroundTransparency = 1,
                        Size = UDim2.new(1, -20, 0, 90), Position = UDim2.new(0, 10, 0, 195)
                    })
                    local NameBox = Create("TextBox", {
                        Parent = Controls, PlaceholderText = "Enter save name...",
                        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor,
                        BackgroundColor3 = CardElevated,
                        Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 0),
                        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false
                    })
                    Create("UIPadding", {Parent = NameBox, PaddingLeft = UDim.new(0, 10)})
                    Create("UICorner", {Parent = NameBox, CornerRadius = UDim.new(0, 6)})
                    Create("UIStroke", {Parent = NameBox, Color = StrokeColor, Thickness = 1, Transparency = 0.3})

                    local CreateBtn = Create("TextButton", {
                        Parent = Controls, Text = "Create Save",
                        Font = Enum.Font.GothamBold, TextSize = 12,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundColor3 = AccentColor,
                        Size = UDim2.new(0.5, -5, 0, 28), Position = UDim2.new(0, 0, 0, 38),
                        AutoButtonColor = false
                    })
                    Create("UICorner", {Parent = CreateBtn, CornerRadius = UDim.new(0, 6)})
                    AddBounce(CreateBtn, 0.96, true)

                    local DeleteTogBtn = Create("TextButton", {
                        Parent = Controls, Text = "Delete Mode: OFF",
                        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TextColor,
                        BackgroundColor3 = Color3.fromRGB(45, 45, 58),
                        Size = UDim2.new(0.5, -5, 0, 28), Position = UDim2.new(0.5, 5, 0, 38),
                        AutoButtonColor = false
                    })
                    Create("UICorner", {Parent = DeleteTogBtn, CornerRadius = UDim.new(0, 6)})
                    AddBounce(DeleteTogBtn, 0.96, true)

                    local ActionArea = Create("Frame", {
                        Parent = Controls, BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 38),
                        Visible = false
                    })

                    local ConfirmActionBtn = Create("TextButton", {
                        Parent = ActionArea, Text = "Confirm",
                        Font = Enum.Font.GothamBold, TextSize = 12,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                        Size = UDim2.new(0.5, -5, 0, 28), Position = UDim2.new(0, 0, 0, 0),
                        AutoButtonColor = false
                    })
                    Create("UICorner", {Parent = ConfirmActionBtn, CornerRadius = UDim.new(0, 6)})
                    AddBounce(ConfirmActionBtn, 0.96, true)

                    local CancelActionBtn = Create("TextButton", {
                        Parent = ActionArea, Text = "Cancel",
                        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TextColor,
                        BackgroundColor3 = Color3.fromRGB(60, 60, 75),
                        Size = UDim2.new(0.5, -5, 0, 28), Position = UDim2.new(0.5, 5, 0, 0),
                        AutoButtonColor = false
                    })
                    Create("UICorner", {Parent = CancelActionBtn, CornerRadius = UDim.new(0, 6)})
                    AddBounce(CancelActionBtn, 0.96, true)

                    AddInfoIcon(ManagerFrame, UDim2.new(1, -20, 0, -24), {
                        Title = "Saves Loader Config Protocol",
                        Description = "Welcome to the Saves System. Instructions:\n\n" ..
                        "1. Create a Save: Type a name and click 'Create Save'.\n" ..
                        "2. Duplicate names are allowed; each save gets its own timestamped file.\n" ..
                        "3. Delete: Toggle 'Delete Mode', click files to select (turns red), then confirm.\n" ..
                        "4. Load: Pull all saved values back into the UI.\n" ..
                        "5. Edit: Rename an existing save via 'Save Edit'.\n" ..
                        "6. Cancel: Back out of any mode without applying changes."
                    })

                    local InternalConfirmPopup = Create("Frame", {
                        Parent = ManagerFrame, BackgroundColor3 = Color3.fromRGB(20, 20, 26),
                        Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0, 10, 0, 10),
                        ZIndex = 60, BackgroundTransparency = 1, Visible = false
                    })
                    Create("UICorner", {Parent = InternalConfirmPopup, CornerRadius = UDim.new(0, 10)})
                    local ICPStroke = Create("UIStroke", {Parent = InternalConfirmPopup, Color = Color3.fromRGB(180, 50, 50), Thickness = 1, Transparency = 1})

                    local P_Title = Create("TextLabel", {
                        Parent = InternalConfirmPopup, Text = "Confirm Deletion?",
                        Font = Enum.Font.GothamBold, TextSize = 14,
                        TextColor3 = Color3.fromRGB(255, 60, 60), BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 40),
                        TextTransparency = 1, ZIndex = 61
                    })
                    local P_Desc = Create("TextLabel", {
                        Parent = InternalConfirmPopup,
                        Text = "You are about to delete these specific saves loaders permanently.",
                        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor,
                        BackgroundTransparency = 1, Size = UDim2.new(1, -40, 0, 40),
                        Position = UDim2.new(0, 20, 0, 70), TextWrapped = true,
                        TextTransparency = 1, ZIndex = 61
                    })
                    local P_Yes = Create("TextButton", {
                        Parent = InternalConfirmPopup, Text = "Yes",
                        Font = Enum.Font.GothamBold, TextSize = 13,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundColor3 = Color3.fromRGB(180, 50, 50),
                        Size = UDim2.new(0.5, -30, 0, 32), Position = UDim2.new(0, 20, 0, 130),
                        AutoButtonColor = false, BackgroundTransparency = 1, TextTransparency = 1, ZIndex = 61
                    })
                    Create("UICorner", {Parent = P_Yes, CornerRadius = UDim.new(0, 6)})
                    AddBounce(P_Yes, 0.96, true)
                    local P_No = Create("TextButton", {
                        Parent = InternalConfirmPopup, Text = "No",
                        Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TextColor,
                        BackgroundColor3 = Color3.fromRGB(45, 45, 58),
                        Size = UDim2.new(0.5, -30, 0, 32), Position = UDim2.new(0.5, 10, 0, 130),
                        AutoButtonColor = false, BackgroundTransparency = 1, TextTransparency = 1, ZIndex = 61
                    })
                    Create("UICorner", {Parent = P_No, CornerRadius = UDim.new(0, 6)})
                    AddBounce(P_No, 0.96, true)

                    local function HideInternalPopup()
                        Tween(InternalConfirmPopup, {BackgroundTransparency = 1}, 0.3)
                        Tween(ICPStroke, {Transparency = 1}, 0.3)
                        Tween(P_Title, {TextTransparency = 1}, 0.3)
                        Tween(P_Desc, {TextTransparency = 1}, 0.3)
                        Tween(P_Yes, {BackgroundTransparency = 1, TextTransparency = 1}, 0.3)
                        Tween(P_No, {BackgroundTransparency = 1, TextTransparency = 1}, 0.3)
                        task.wait(0.3)
                        InternalConfirmPopup.Visible = false
                    end

                    local function RefreshMonitor()
                        for _, v in ipairs(Monitor:GetChildren()) do
                            if v:IsA("Frame") then v:Destroy() end
                        end
                        selectedForDelete = {}
                        local currentAutoload = ReadAutoloadData().Path
                        local files = _listfiles(folderName)
                        for _, filepath in ipairs(files) do
                            local rawName = filepath:match("([^/\\]+)%.json$")
                            if rawName and not IsAutoloadFile(filepath) then
                                local displayFName = rawName:gsub("_%d+%.%d+$", ""):gsub("_%d+$", "")
                                local isAutoload = (currentAutoload == filepath)

                                local Row = Create("Frame", {Parent = Monitor, BackgroundColor3 = CardElevated, Size = UDim2.new(1, 0, 0, 32)})
                                Create("UICorner", {Parent = Row, CornerRadius = UDim.new(0, 6)})
                                local RowStroke = Create("UIStroke", {Parent = Row, Color = StrokeColor, Thickness = 1, Transparency = 0.5})

                                Create("TextLabel", {
                                    Parent = Row, Text = displayFName, Font = Enum.Font.Gotham,
                                    TextSize = 12, TextColor3 = TextColor, BackgroundTransparency = 1,
                                    Size = UDim2.new(1, -110, 1, 0), Position = UDim2.new(0, 10, 0, 0),
                                    TextXAlignment = Enum.TextXAlignment.Left
                                })

                                local StarBtn = Create("TextButton", {
                                    Parent = Row, Text = isAutoload and "★" or "☆",
                                    Font = Enum.Font.GothamBold, TextSize = 14,
                                    TextColor3 = isAutoload and Color3.fromRGB(255, 215, 0) or SubTextColor,
                                    BackgroundColor3 = Color3.fromRGB(45, 45, 58),
                                    Size = UDim2.new(0, 22, 0, 22),
                                    Position = UDim2.new(1, -103, 0.5, -11), AutoButtonColor = false
                                })
                                Create("UICorner", {Parent = StarBtn, CornerRadius = UDim.new(0, 5)})
                                AddBounce(StarBtn, 0.9, true)

                                local LoadBtn = Create("TextButton", {
                                    Parent = Row, Text = "Load",
                                    Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = TextColor,
                                    BackgroundColor3 = Color3.fromRGB(45, 130, 70),
                                    Size = UDim2.new(0, 34, 0, 22),
                                    Position = UDim2.new(1, -77, 0.5, -11), AutoButtonColor = false
                                })
                                Create("UICorner", {Parent = LoadBtn, CornerRadius = UDim.new(0, 5)})
                                AddBounce(LoadBtn, 0.94, true)

                                local EditBtn = Create("TextButton", {
                                    Parent = Row, Text = "Edit",
                                    Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = TextColor,
                                    BackgroundColor3 = Color3.fromRGB(155, 105, 45),
                                    Size = UDim2.new(0, 32, 0, 22),
                                    Position = UDim2.new(1, -40, 0.5, -11), AutoButtonColor = false
                                })
                                Create("UICorner", {Parent = EditBtn, CornerRadius = UDim.new(0, 5)})
                                AddBounce(EditBtn, 0.94, true)

                                local SelectionMask = Create("TextButton", {
                                    Parent = Row, Text = "", BackgroundTransparency = 1,
                                    Size = UDim2.new(1, -110, 1, 0), ZIndex = 2
                                })
                                SelectionMask.MouseButton1Click:Connect(function()
                                    if deleteMode then
                                        if selectedForDelete[filepath] then
                                            selectedForDelete[filepath] = nil
                                            Tween(Row, {BackgroundColor3 = CardElevated}, 0.2)
                                            Tween(RowStroke, {Color = StrokeColor, Transparency = 0.5}, 0.2)
                                        else
                                            selectedForDelete[filepath] = true
                                            Tween(Row, {BackgroundColor3 = Color3.fromRGB(180, 50, 50)}, 0.2)
                                            Tween(RowStroke, {Color = Color3.fromRGB(255, 80, 80), Transparency = 0}, 0.2)
                                        end
                                    end
                                end)

                                StarBtn.MouseButton1Click:Connect(function()
                                    if deleteMode or editMode then return end
                                    local data = ReadAutoloadData()
                                    if isAutoload then
                                        data.Path = nil
                                        WriteAutoloadData(data)
                                        Library:Notify({Title = "Autoload Target Cleared", Description = displayFName .. " is no longer the remembered Auto Load config.", Type = "info"})
                                    else
                                        data.Path = filepath
                                        WriteAutoloadData(data)
                                        Library:Notify({Title = "Autoload Target Set", Description = displayFName .. " will be used when Auto Load is enabled.", Type = "success"})
                                    end
                                    RefreshMonitor()
                                end)

                                LoadBtn.MouseButton1Click:Connect(function()
                                    if deleteMode or editMode then return end
                                    local s, data = pcall(function() return HttpService:JSONDecode(_readfile(filepath)) end)
                                    if s and type(data) == "table" then
                                        for k, v in pairs(data) do
                                            if Window.ConfigElements[k] and Window.ConfigElements[k].Set then
                                                local setOk, setErr = pcall(function() Window.ConfigElements[k].Set(v) end)
                                                if not setOk then
                                                    warn("[Saves Loader] Skipped key '" .. tostring(k) .. "': " .. tostring(setErr))
                                                end
                                            end
                                        end
                                        Library:Notify({Title = "Saves Loader", Description = "Successfully loaded " .. displayFName, Type = "success"})
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
                        end
                    end

                    local function ExecuteSave(saveName)
                        local payload = {}
                        for k, el in pairs(Window.ConfigElements) do
                            if el.Get then payload[k] = el.Get() end
                        end
                        local encoded = HttpService:JSONEncode(payload)
                        local uniqueKey = tostring(math.floor(tick()))
                        local finalPath = folderName .. "/" .. saveName .. "_" .. uniqueKey .. ".json"
                        _writefile(finalPath, encoded)
                        RefreshMonitor()
                        Library:Notify({Title = "Saved Successfully", Description = "Config [" .. saveName .. "] secured.", Type = "success"})
                    end

                    CreateBtn.MouseButton1Click:Connect(function()
                        if NameBox.Text ~= "" then ExecuteSave(NameBox.Text) end
                    end)

                    DeleteTogBtn.MouseButton1Click:Connect(function()
                        if editMode then return end
                        deleteMode = not deleteMode
                        DeleteTogBtn.Text = deleteMode and "Delete Mode: ON" or "Delete Mode: OFF"
                        Tween(DeleteTogBtn, {BackgroundColor3 = deleteMode and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(45, 45, 58)}, 0.2)
                        ActionArea.Visible = deleteMode
                        CreateBtn.Visible = not deleteMode
                        if deleteMode then
                            ConfirmActionBtn.Text = "Delete Selected"
                            ConfirmActionBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                        else
                            RefreshMonitor()
                        end
                    end)

                    ConfirmActionBtn.MouseButton1Click:Connect(function()
                        if deleteMode then
                            InternalConfirmPopup.Visible = true
                            Tween(InternalConfirmPopup, {BackgroundTransparency = 0.1}, 0.3)
                            Tween(ICPStroke, {Transparency = 0.5}, 0.3)
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
                        for file, _ in pairs(selectedForDelete) do
                            pcall(function() _delfile(file) end)
                            if autoData.Path == file then
                                autoData.Path = nil
                                autoData.Enabled = false
                                autoCleared = true
                            end
                        end
                        if autoCleared then
                            WriteAutoloadData(autoData)
                            autoloadState = false
                            Tween(AutoloadLever, {BackgroundColor3 = Color3.fromRGB(45, 45, 58)}, 0.3)
                            Tween(AutoloadKnob, {Position = UDim2.new(0, 2, 0.5, -7)}, 0.3)
                        end
                        deleteMode = false
                        DeleteTogBtn.Text = "Delete Mode: OFF"
                        DeleteTogBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
                        ActionArea.Visible = false
                        CreateBtn.Visible = true
                        RefreshMonitor()
                        Library:Notify({Title = "Deletions Complete", Description = "Selected saves erased from system.", Type = "success"})
                        HideInternalPopup()
                    end)

                    P_No.MouseButton1Click:Connect(function() HideInternalPopup() end)

                    CancelActionBtn.MouseButton1Click:Connect(function()
                        editMode = false
                        deleteMode = false
                        DeleteTogBtn.Text = "Delete Mode: OFF"
                        DeleteTogBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
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

                -- ===== CamelCase API wrappers =====
                local function BuildInfo(config)
                    if config.Desc then
                        return {Title = config.Title, Description = config.Desc, Example = config.Example}
                    end
                    return nil
                end

                function Elements:Button(config)
                    config = config or {}
                    return self:AddButton(config.Title, config.Callback, BuildInfo(config))
                end
                function Elements:CopyButton(config)
                    config = config or {}
                    return self:AddCopyButton(config.Title, config.Text or config.Content, BuildInfo(config))
                end
                function Elements:Paragraph(config)
                    config = config or {}
                    return self:AddParagraph(config.Title, config.Content, BuildInfo(config))
                end
                function Elements:Toggle(config)
                    config = config or {}
                    return self:AddToggle(config.Title, config.Value, config.Callback, BuildInfo(config))
                end
                function Elements:Slider(config)
                    config = config or {}
                    return self:AddSlider(config.Title, config.Min, config.Max, config.Value, config.Callback, BuildInfo(config))
                end
                function Elements:Dropdown(config)
                    config = config or {}
                    return self:AddDropdown(config.Title, config.Options, config.Multi, config.Value, config.Callback, BuildInfo(config))
                end
                function Elements:Textbox(config)
                    config = config or {}
                    return self:AddTextbox(config.Title, config.Placeholder, config.Value, config.Callback, BuildInfo(config))
                end
                function Elements:ColorPicker(config)
                    config = config or {}
                    return self:AddColorPicker(config.Title, config.Value, config.Callback, BuildInfo(config))
                end
                function Elements:ConfigManager(config)
                    config = config or {}
                    return self:AddConfigManager(config.Folder)
                end

                return Elements
            end
            return PageObj
        end

        if isDefault then
            TabBtn.BackgroundTransparency = 0.4
            Indicator.Size = UDim2.new(0, 3, 0, 20)
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
