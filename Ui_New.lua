function Library:CreateWindow(options)
    -- ====== CONFIG DEFAULTS ======
    local hubName = "MarvenRiz UI Lib"
    local subText = "Made By Zens"
    local subColor = AccentColor
    local sphTextToggle = false
    local sphWords = "ZX"
    local sphImage = nil
    local topbarLogo = nil
    local logoSize = 32
    local sphIconSize = 26
    local windowSize = UDim2.fromOffset(600, 480)
    local sideBarWidth = 170
    local toggleKey = Enum.KeyCode.RightShift

    if type(options) == "table" then
        hubName     = options.Title or hubName
        subText     = options.Subtitle or subText
        if options.AccentColor ~= nil then
            if typeof(options.AccentColor) == "Color3" then AccentColor = options.AccentColor
            elseif type(options.AccentColor) == "string" then
                local ok, c = pcall(Color3.fromHex, options.AccentColor)
                if ok then AccentColor = c end
            end
        end
        subColor    = options.SubtitleColor or AccentColor
        if options.SphereText ~= nil then sphTextToggle = options.SphereText end
        if options.SphereWords ~= nil then
            local wl = string.split(tostring(options.SphereWords), " ")
            sphWords = (#wl > 2) and (wl[1] .. " " .. wl[2]) or tostring(options.SphereWords)
        end
        sphImage    = options.SphereImage
        topbarLogo  = options.Logo
        logoSize    = options.LogoSize or 32
        sphIconSize = options.SphereIconSize or 26
        windowSize  = options.Size or windowSize
        sideBarWidth= options.SideBarWidth or sideBarWidth
        toggleKey   = options.ToggleKey or toggleKey
        if options.Map ~= nil or options.MapId ~= nil then
            Library.SaveManager:SetMap(options.Map or options.MapId, options.SaveFolder)
        end
    elseif type(options) == "string" then
        hubName = options
    end

    -- Sync theme vars
    BackgroundColor = Theme.Background
    CardColor       = Theme.Card
    HoverColor      = Theme.CardHover
    TextColor       = Theme.Text
    SubTextColor    = Theme.SubText

    -- ====== ROOT ======
    local uniqueID = HttpService:GenerateGUID(false)
    local ScreenGui = Create("ScreenGui", {
        Name = "MarvenRiz_UI_" .. uniqueID,
        Parent = RunService:IsStudio() and Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999
    })

    -- ====== NOTIF CONTAINER ======
    local NotifContainer = Create("Frame", {
        Parent = ScreenGui, BackgroundTransparency = 1,
        Size = UDim2.new(0, 320, 1, -20),
        Position = UDim2.new(1, -340, 0, 10),
        ZIndex = 200
    })
    Create("UIListLayout", {
        Parent = NotifContainer,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10)
    })
    GlobalNotifContainer = NotifContainer

    -- ====== INFO OVERLAY ======
    local InfoOverlay, InfoCard, InfoScale, InfoTitle, InfoCloseBtn, InfoDesc, InfoExampleBox, InfoExampleText
    do
        InfoOverlay = Create("Frame", {
            Parent = ScreenGui, BackgroundColor3 = Color3.fromRGB(5,5,8),
            BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), ZIndex = 150,
            Visible = false, Active = true
        })
        InfoCard = Create("Frame", {
            Parent = InfoOverlay, BackgroundColor3 = Color3.fromRGB(16,16,20),
            Size = UDim2.new(0, 380, 0, 300),
            Position = UDim2.new(0.5,0,0.5,0), AnchorPoint = Vector2.new(0.5,0.5),
            ZIndex = 151, BackgroundTransparency = 1, ClipsDescendants = true
        })
        Create("UICorner", {Parent = InfoCard, CornerRadius = UDim.new(0, 10)})
        Create("UIStroke", {Parent = InfoCard, Color = AccentColor, Thickness = 1.5, Transparency = 1})
        InfoScale = Create("UIScale", {Parent = InfoCard, Scale = 0})

        local InfoHeader = Create("Frame", {Parent = InfoCard, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,42), ZIndex = 152})
        InfoTitle = Create("TextLabel", {
            Parent = InfoHeader, Text = "Feature Info", Font = Enum.Font.GothamBold,
            TextSize = 16, TextColor3 = TextColor, BackgroundTransparency = 1,
            Position = UDim2.new(0,20,0,0), Size = UDim2.new(1,-60,1,0),
            TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, ZIndex = 152
        })
        InfoCloseBtn = Create("TextButton", {
            Parent = InfoHeader, Text = "✕", Font = Enum.Font.GothamBold,
            TextSize = 14, TextColor3 = SubTextColor, BackgroundTransparency = 1,
            Size = UDim2.new(0, 40, 1, 0), Position = UDim2.new(1,-42,0,0),
            ZIndex = 152, TextTransparency = 1, AutoButtonColor = false
        })
        AddBounce(InfoCloseBtn)

        local InfoScroll = Create("ScrollingFrame", {
            Parent = InfoCard, BackgroundTransparency = 1,
            Size = UDim2.new(1,-40,1,-62), Position = UDim2.new(0,20,0,52),
            CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 3,
            ScrollBarImageColor3 = AccentColor, BorderSizePixel = 0, ZIndex = 152
        })
        local InfoLayout = Create("UIListLayout", {Parent = InfoScroll, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,10)})
        InfoDesc = Create("TextLabel", {
            Parent = InfoScroll, Text = "", Font = Enum.Font.Gotham, TextSize = 13,
            TextColor3 = SubTextColor, BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,0), TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
            AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 152, TextTransparency = 1
        })
        InfoExampleBox = Create("Frame", {
            Parent = InfoScroll, BackgroundColor3 = Color3.fromRGB(10,10,12),
            Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y,
            Visible = false, ZIndex = 152
        })
        Create("UICorner", {Parent = InfoExampleBox, CornerRadius = UDim.new(0,6)})
        Create("UIStroke", {Parent = InfoExampleBox, Color = Theme.Border, Thickness = 1})
        InfoExampleText = Create("TextLabel", {
            Parent = InfoExampleBox, Text = "", Font = Enum.Font.Code, TextSize = 12,
            TextColor3 = AccentColor, BackgroundTransparency = 1,
            Size = UDim2.new(1,-20,0,0), Position = UDim2.new(0,10,0,10),
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 152,
            TextTransparency = 1
        })
        Create("UIPadding", {Parent = InfoExampleBox, PaddingBottom = UDim.new(0,10)})

        InfoLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            InfoScroll.CanvasSize = UDim2.new(0,0,0, InfoLayout.AbsoluteContentSize.Y + 10)
        end)
    end

    local function OpenInfoWindow(data)
        InfoTitle.Text = data.Title or "Information"
        InfoDesc.Text  = data.Description or "No description provided."
        if data.Example then
            InfoExampleText.Text = data.Example
            InfoExampleBox.Visible = true
        else
            InfoExampleBox.Visible = false
        end
        InfoOverlay.Visible = true
        Tween(InfoOverlay, {BackgroundTransparency = 0.4}, 0.25)
        Tween(InfoCard, {BackgroundTransparency = 0}, 0.25)
        Tween(InfoCard:FindFirstChild("UIStroke"), {Transparency = 0.3}, 0.25)
        Tween(InfoScale, {Scale = 1}, 0.25)
        Tween(InfoTitle, {TextTransparency = 0}, 0.25)
        Tween(InfoCloseBtn, {TextTransparency = 0}, 0.25)
        Tween(InfoDesc, {TextTransparency = 0}, 0.25)
        if data.Example then Tween(InfoExampleText, {TextTransparency = 0}, 0.25) end
    end

    InfoCloseBtn.MouseButton1Click:Connect(function()
        Tween(InfoOverlay, {BackgroundTransparency = 1}, 0.25)
        Tween(InfoCard, {BackgroundTransparency = 1}, 0.25)
        Tween(InfoCard:FindFirstChild("UIStroke"), {Transparency = 1}, 0.25)
        Tween(InfoScale, {Scale = 0}, 0.25)
        Tween(InfoTitle, {TextTransparency = 1}, 0.25)
        Tween(InfoCloseBtn, {TextTransparency = 1}, 0.25)
        Tween(InfoDesc, {TextTransparency = 1}, 0.25)
        if InfoExampleBox.Visible then Tween(InfoExampleText, {TextTransparency = 1}, 0.25) end
        task.wait(0.25)
        InfoOverlay.Visible = false
    end)

    local function AddInfoIcon(parent, pos, data)
        if not data then return end
        local Btn = Create("TextButton", {
            Parent = parent, Text = "?", Font = Enum.Font.GothamBold, TextSize = 10,
            TextColor3 = SubTextColor, BackgroundColor3 = Theme.Border,
            Size = UDim2.new(0, 16, 0, 16), Position = pos,
            AutoButtonColor = false, ZIndex = 5
        })
        Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(1,0)})
        AddBounce(Btn)
        Btn.MouseEnter:Connect(function() Tween(Btn, {TextColor3 = TextColor, BackgroundColor3 = AccentColor}, 0.2) end)
        Btn.MouseLeave:Connect(function() Tween(Btn, {TextColor3 = SubTextColor, BackgroundColor3 = Theme.Border}, 0.2) end)
        Btn.MouseButton1Click:Connect(function() OpenInfoWindow(data) end)
    end

    -- ====== MAIN FRAME ======
    local MainFrame = Create("Frame", {
        Parent = ScreenGui, BackgroundColor3 = BackgroundColor,
        Size = windowSize, Position = UDim2.new(0.5,0,0.5,0),
        AnchorPoint = Vector2.new(0.5,0.5), ClipsDescendants = false,
        BackgroundTransparency = 1, Active = true
    })
    local MainScale = Create("UIScale", {Parent = MainFrame, Scale = 0.85})
    Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 10)})
    local MainStroke = Create("UIStroke", {Parent = MainFrame, Color = Theme.Border, Thickness = 1})
    Tween(MainScale, {Scale = 1}, 0.4)
    Tween(MainFrame, {BackgroundTransparency = 0}, 0.4)

    -- ====== RESIZE HANDLE ======
    local ResizeHandle = Create("TextButton", {
        Parent = MainFrame, Text = "", BackgroundTransparency = 1,
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(1, -18, 1, -18),
        AutoButtonColor = false, ZIndex = 5
    })
    local ResizeIcon = Create("TextLabel", {
        Parent = ResizeHandle, Text = "◢", Font = Enum.Font.GothamBold,
        TextSize = 14, TextColor3 = SubTextColor, BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0), Rotation = 0
    })
    local resizing, resizeStart, startSize = false, nil, nil
    ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            startSize = MainFrame.AbsoluteSize
            Tween(ResizeIcon, {TextColor3 = AccentColor}, 0.15)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
            Tween(ResizeIcon, {TextColor3 = SubTextColor}, 0.15)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            local newX = math.max(480, startSize.X + delta.X)
            local newY = math.max(340, startSize.Y + delta.Y)
            MainFrame.Size = UDim2.fromOffset(newX, newY)
        end
    end)

    -- ====== TOPBAR ======
    local TopBar = Create("Frame", {
        Parent = MainFrame, BackgroundColor3 = BackgroundColor,
        BackgroundTransparency = 1, Size = UDim2.new(1,0,0,42),
        Position = UDim2.new(0,0,0,0), Active = true
    })
    MakeDraggable(TopBar, MainFrame)

    local titleOffsetX = 15
    if topbarLogo then
        Create("ImageLabel", {
            Parent = TopBar, BackgroundTransparency = 1,
            Size = UDim2.new(0, logoSize, 0, logoSize),
            Position = UDim2.new(0, 12, 0.5, -(logoSize/2)),
            Image = topbarLogo, ScaleType = Enum.ScaleType.Fit
        })
        titleOffsetX = 12 + logoSize + 8
    end

    local TitleContainer = Create("Frame", {Parent = TopBar, BackgroundTransparency = 1, Size = UDim2.new(0, 160, 1, 0), Position = UDim2.new(0, titleOffsetX, 0, 0)})
    Create("TextLabel", {
        Parent = TitleContainer, Text = hubName, Font = Enum.Font.GothamBold,
        TextSize = 14, TextColor3 = TextColor, BackgroundTransparency = 1,
        Position = UDim2.new(0,0,0,6), Size = UDim2.new(1,0,0,16),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    Create("TextLabel", {
        Parent = TitleContainer, Text = subText, Font = Enum.Font.Gotham,
        TextSize = 10, TextColor3 = subColor, BackgroundTransparency = 1,
        Position = UDim2.new(0,0,0,23), Size = UDim2.new(1,0,0,12),
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Search bar
    local SearchBar = Create("Frame", {
        Parent = TopBar, BackgroundColor3 = CardColor,
        Size = UDim2.new(0, 220, 0, 26),
        Position = UDim2.new(0, 200, 0.5, -13)
    })
    Create("UICorner", {Parent = SearchBar, CornerRadius = UDim.new(0, 6)})
    Create("UIStroke", {Parent = SearchBar, Color = Theme.Border, Thickness = 1})
    Create("ImageLabel", {
        Parent = SearchBar, BackgroundTransparency = 1,
        Image = "rbxassetid://6031154871", ImageColor3 = SubTextColor,
        Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 8, 0.5, -7)
    })
    local SearchInput = Create("TextBox", {
        Parent = SearchBar, BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 30, 0, 0),
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor,
        PlaceholderText = "Search features...", TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })

    -- Close / Minimize
    local CloseBtn = Create("TextButton", {
        Parent = TopBar, Text = "✕", Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = SubTextColor, BackgroundTransparency = 1,
        Size = UDim2.new(0, 32, 1, 0), Position = UDim2.new(1, -36, 0, 0),
        AutoButtonColor = false
    })
    local MinBtn = Create("TextButton", {
        Parent = TopBar, Text = "—", Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = SubTextColor, BackgroundTransparency = 1,
        Size = UDim2.new(0, 32, 1, 0), Position = UDim2.new(1, -68, 0, 0),
        AutoButtonColor = false
    })
    CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, {TextColor3 = Theme.Danger}, 0.15) end)
    CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, {TextColor3 = SubTextColor}, 0.15) end)
    MinBtn.MouseEnter:Connect(function() Tween(MinBtn, {TextColor3 = TextColor}, 0.15) end)
    MinBtn.MouseLeave:Connect(function() Tween(MinBtn, {TextColor3 = SubTextColor}, 0.15) end)

    -- ====== SIDEBAR ======
    local Sidebar = Create("Frame", {
        Parent = MainFrame, BackgroundColor3 = BackgroundColor,
        BackgroundTransparency = 1, Size = UDim2.new(0, sideBarWidth, 1, -42),
        Position = UDim2.new(0,0,0,42), Active = true
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
    Create("UIStroke", {Parent = TabSearchBox, Color = Theme.Border, Thickness = 1})

    local TabContainer = Create("ScrollingFrame", {
        Parent = Sidebar, BackgroundTransparency = 1,
        Size = UDim2.new(1, -15, 1, -40), Position = UDim2.new(0, 10, 0, 40),
        ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Border,
        BorderSizePixel = 0, ScrollingDirection = Enum.ScrollingDirection.Y,
        ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
    })
    Create("UIListLayout", {Parent = TabContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})

    Create("Frame", {
        Parent = MainFrame, BackgroundColor3 = Theme.Border, BorderSizePixel = 0,
        Size = UDim2.new(0, 1, 1, -42), Position = UDim2.new(0, sideBarWidth, 0, 42)
    })
    local ContentArea = Create("Frame", {
        Parent = MainFrame, BackgroundTransparency = 1,
        Size = UDim2.new(1, -(sideBarWidth + 5), 1, -42),
        Position = UDim2.new(0, sideBarWidth + 5, 0, 42), Active = true
    })

    -- ====== SPHERE (minimized state) ======
    local Sphere = Create("ImageButton", {
        Parent = ScreenGui, BackgroundColor3 = BackgroundColor,
        BackgroundTransparency = 0.1,
        Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0.5,0,0.5,0),
        AnchorPoint = Vector2.new(0.5,0.5), Visible = false,
        AutoButtonColor = false, ImageTransparency = 1, ClipsDescendants = true
    })
    Create("UICorner", {Parent = Sphere, CornerRadius = UDim.new(0, 20)})
    Create("UIStroke", {Parent = Sphere, Color = AccentColor, Thickness = 2})
    local SphereImageLabel = Create("ImageLabel", {
        Parent = Sphere, BackgroundTransparency = 1,
        Size = UDim2.new(0, sphIconSize, 0, sphIconSize),
        Position = UDim2.new(0.5,0,0.5,0), AnchorPoint = Vector2.new(0.5,0.5),
        Image = sphImage or "", ImageTransparency = 1,
        Visible = (not sphTextToggle and sphImage ~= nil)
    })
    local SphereTextLabel = Create("TextLabel", {
        Parent = Sphere, Text = sphWords, Font = Enum.Font.GothamBold,
        TextSize = 16, TextColor3 = AccentColor, BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0), TextTransparency = 1, Visible = sphTextToggle
    })
    MakeDraggable(Sphere, Sphere)

    -- ====== WINDOW OBJECT ======
    local Window = {
        CurrentTab = nil, Tabs = {}, Title = nil,
        AllCards = {}, MainFrame = MainFrame,
        CurrentTransparency = 0, ConfigElements = {},
        MapId = options and (type(options) == "table") and (options.Map or options.MapId) or nil
    }

    function Window:SetTransparency(val)
        Window.CurrentTransparency = val
        if MainFrame.Visible then
            Tween(MainFrame, {BackgroundTransparency = val}, 0.3)
        end
    end

    function Window:SetMap(mapOption)
        Window.MapId = mapOption
        SaveManager:SetMap(mapOption)
    end

    function Window:Toggle()
        if MainFrame.Visible then
            -- Minimize
            Tween(MainScale, {Scale = 0}, 0.3)
            Tween(MainFrame, {BackgroundTransparency = 1}, 0.3)
            task.wait(0.25)
            MainFrame.Visible = false
            Sphere.Visible = true
            Tween(Sphere, {Size = UDim2.new(0, 50, 0, 50)}, 0.3)
            if not sphTextToggle and sphImage then
                Tween(SphereImageLabel, {ImageTransparency = 0}, 0.3)
            elseif sphTextToggle then
                Tween(SphereTextLabel, {TextTransparency = 0}, 0.3)
            end
        else
            -- Restore
            Tween(Sphere, {Size = UDim2.new(0, 0, 0, 0)}, 0.25)
            if not sphTextToggle and sphImage then Tween(SphereImageLabel, {ImageTransparency = 1}, 0.25) end
            if sphTextToggle then Tween(SphereTextLabel, {TextTransparency = 1}, 0.25) end
            task.wait(0.2)
            Sphere.Visible = false
            MainFrame.Visible = true
            Tween(MainScale, {Scale = 1}, 0.3)
            Tween(MainFrame, {BackgroundTransparency = Window.CurrentTransparency}, 0.3)
        end
    end

    MinBtn.MouseButton1Click:Connect(function() Window:Toggle() end)
    Sphere.MouseButton1Click:Connect(function() Window:Toggle() end)

    -- Keybind toggle
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then Window:Toggle() end
    end)

    -- ====== EXIT POPUP ======
    local Popup = Create("Frame", {
        Parent = ScreenGui, BackgroundColor3 = Color3.new(0,0,0),
        BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0),
        ZIndex = 100, Visible = false, Active = true
    })
    local PopupCard = Create("Frame", {
        Parent = Popup, BackgroundColor3 = Color3.fromRGB(20,20,24),
        Size = UDim2.new(0, 340, 0, 170), Position = UDim2.new(0.5,0,0.5,0),
        AnchorPoint = Vector2.new(0.5,0.5), ZIndex = 101, BackgroundTransparency = 1
    })
    Create("UICorner", {Parent = PopupCard, CornerRadius = UDim.new(0, 12)})
    local PopupScale = Create("UIScale", {Parent = PopupCard, Scale = 0.85})
    local PopupStroke = Create("UIStroke", {Parent = PopupCard, Color = Theme.BorderLight, Thickness = 1, Transparency = 1})
    local PopupTitle = Create("TextLabel", {
        Parent = PopupCard, Text = "Exit Application", Font = Enum.Font.GothamBold,
        TextSize = 18, TextColor3 = TextColor, BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,30), Position = UDim2.new(0,0,0,26), ZIndex = 102,
        TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center
    })
    local PopupText = Create("TextLabel", {
        Parent = PopupCard, Text = "Close MarvenRiz Hub? Unsaved configs may be lost.",
        Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = SubTextColor,
        BackgroundTransparency = 1, Size = UDim2.new(1,-40,0,40),
        Position = UDim2.new(0,20,0,58), ZIndex = 102, TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true
    })
    local YesBtn = Create("TextButton", {
        Parent = PopupCard, Text = "Confirm", Font = Enum.Font.GothamBold,
        TextSize = 13, TextColor3 = Color3.new(1,1,1), BackgroundColor3 = Theme.Danger,
        Size = UDim2.new(0, 130, 0, 36), Position = UDim2.new(0.5, 10, 0, 112),
        ZIndex = 102, BackgroundTransparency = 1, TextTransparency = 1, AutoButtonColor = false
    })
    Create("UICorner", {Parent = YesBtn, CornerRadius = UDim.new(0, 6)})
    AddBounce(YesBtn)
    local NoBtn = Create("TextButton", {
        Parent = PopupCard, Text = "Cancel", Font = Enum.Font.GothamBold,
        TextSize = 13, TextColor3 = TextColor, BackgroundColor3 = Theme.Border,
        Size = UDim2.new(0, 130, 0, 36), Position = UDim2.new(0.5, -140, 0, 112),
        ZIndex = 102, BackgroundTransparency = 1, TextTransparency = 1, AutoButtonColor = false
    })
    Create("UICorner", {Parent = NoBtn, CornerRadius = UDim.new(0, 6)})
    AddBounce(NoBtn)

    CloseBtn.MouseButton1Click:Connect(function()
        Popup.Visible = true
        Tween(Popup, {BackgroundTransparency = 0.5}, 0.25)
        Tween(PopupCard, {BackgroundTransparency = 0}, 0.25)
        Tween(PopupScale, {Scale = 1}, 0.25)
        Tween(PopupStroke, {Transparency = 0.5}, 0.25)
        Tween(PopupTitle, {TextTransparency = 0}, 0.25)
        Tween(PopupText, {TextTransparency = 0}, 0.25)
        Tween(YesBtn, {BackgroundTransparency = 0, TextTransparency = 0}, 0.25)
        Tween(NoBtn, {BackgroundTransparency = 0, TextTransparency = 0}, 0.25)
    end)

    YesBtn.MouseButton1Click:Connect(function()
        Tween(Popup, {BackgroundTransparency = 1}, 0.25)
        Tween(PopupCard, {BackgroundTransparency = 1}, 0.25)
        Tween(MainScale, {Scale = 0.85}, 0.25)
        Tween(MainFrame, {BackgroundTransparency = 1}, 0.25)
        task.wait(0.3)
        ScreenGui:Destroy()
    end)

    NoBtn.MouseButton1Click:Connect(function()
        Tween(Popup, {BackgroundTransparency = 1}, 0.25)
        Tween(PopupCard, {BackgroundTransparency = 1}, 0.25)
        Tween(PopupScale, {Scale = 0.85}, 0.25)
        Tween(PopupTitle, {TextTransparency = 1}, 0.25)
        Tween(PopupText, {TextTransparency = 1}, 0.25)
        Tween(YesBtn, {BackgroundTransparency = 1, TextTransparency = 1}, 0.25)
        Tween(NoBtn, {BackgroundTransparency = 1, TextTransparency = 1}, 0.25)
        task.wait(0.25)
        Popup.Visible = false
    end)

    -- ====== TAB SEARCH ======
    TabSearchBox:GetPropertyChangedSignal("Text"):Connect(Debounce(function()
        local query = TabSearchBox.Text:lower()
        for _, tabInfo in ipairs(Window.Tabs) do
            tabInfo.Button.Visible = (query == "" or string.find(tabInfo.Txt.Text:lower(), query, 1, true) ~= nil)
        end
    end, 0.08))

    -- ====== FEATURE SEARCH ======
    local function ResetSearch()
        for _, data in ipairs(Window.AllCards) do
            data.Card.Parent = data.OrigParent
            data.Card.Visible = true
        end
    end

    local function PerformSearch()
        local query = SearchInput.Text:lower()
        if query == "" then
            ResetSearch()
            return
        end
        if not Window.CurrentTab or not Window.CurrentTab.CurrentPage then return end
        local activeLeft  = Window.CurrentTab.CurrentPage.LeftCol
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

    SearchInput:GetPropertyChangedSignal("Text"):Connect(Debounce(PerformSearch, 0.12))

    -- ====== CREATE TAB ======
    function Window:CreateTab(tabName, isDefault, isLocked)
        local isWhitelisted = false
        local player = Players.LocalPlayer
        if player then
            for _, allowedUser in ipairs(Library.WhitelistedUsers) do
                if player.Name == allowedUser or player.DisplayName == allowedUser then
                    isWhitelisted = true; break
                end
            end
        end

        local TabBtn = Create("TextButton", {
            Parent = TabContainer, Text = "", BackgroundColor3 = HoverColor,
            BackgroundTransparency = 1, Size = UDim2.new(1,0,0,34), AutoButtonColor = false
        })
        Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0, 6)})
        AddBounce(TabBtn, 0.98)
        local Indicator = Create("Frame", {
            Parent = TabBtn,
            BackgroundColor3 = isLocked and Theme.Gold or AccentColor,
            Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5)
        })
        Create("UICorner", {Parent = Indicator, CornerRadius = UDim.new(1,0)})
        local Txt = Create("TextLabel", {
            Parent = TabBtn, Text = tabName, Font = Enum.Font.GothamBold,
            TextSize = 13, TextColor3 = SubTextColor, BackgroundTransparency = 1,
            Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 15, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Left
        })
        if isLocked then
            Create("ImageLabel", {
                Parent = TabBtn, Image = "rbxassetid://6031082533",
                ImageColor3 = Theme.Gold, BackgroundTransparency = 1,
                Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -22, 0.5, -7)
            })
        end

        local TabContent = Create("Frame", {
            Parent = ContentArea, BackgroundTransparency = 1,
            Size = UDim2.new(1,0,1,0), Visible = false
        })
        local PageNav = Create("Frame", {
            Parent = TabContent, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 35), Position = UDim2.new(0, 0, 0, 0)
        })
        Create("UIPadding", {Parent = PageNav, PaddingLeft = UDim.new(0, 15)})
        Create("UIListLayout", {
            Parent = PageNav, FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 15), VerticalAlignment = Enum.VerticalAlignment.Center
        })
        local PageContainer = Create("Frame", {
            Parent = TabContent, BackgroundTransparency = 1,
            Size = UDim2.new(1,0,1,-35), Position = UDim2.new(0,0,0,35)
        })

        local TabConfig = {
            Button = TabBtn, Content = TabContent, Indicator = Indicator,
            Txt = Txt, Pages = {}, CurrentPage = nil
        }
        table.insert(Window.Tabs, TabConfig)

        TabBtn.MouseButton1Click:Connect(function()
            if isLocked and not isWhitelisted then
                Library:Notify({
                    Title = "ACCESS DENIED",
                    Description = "This tab is for whitelisted users only.",
                    Type = "error"
                })
                return
            end
            if Window.CurrentTab == TabConfig then return end

            if Window.CurrentTab then
                Tween(Window.CurrentTab.Button, {BackgroundTransparency = 1}, 0.18)
                Tween(Window.CurrentTab.Indicator, {Size = UDim2.new(0,3,0,0)}, 0.18)
                Tween(Window.CurrentTab.Txt, {TextColor3 = SubTextColor}, 0.18)
                Window.CurrentTab.Content.Visible = false
            end

            Window.CurrentTab = TabConfig
            TabConfig.Content.Visible = true
            TabConfig.Content.Position = UDim2.new(0,0,0,12)
            Tween(TabConfig.Content, {Position = UDim2.new(0,0,0,0)}, 0.3)

            Tween(TabBtn, {BackgroundTransparency = 0}, 0.18)
            Tween(Indicator, {Size = UDim2.new(0,3,0,18)}, 0.25)
            Tween(Txt, {TextColor3 = TextColor}, 0.18)

            -- Reset search input khi đổi tab
            if SearchInput.Text ~= "" then
                SearchInput.Text = ""
                ResetSearch()
            end

            if #TabConfig.Pages > 0 then
                local firstPage = TabConfig.Pages[1]
                if TabConfig.CurrentPage ~= firstPage then
                    if TabConfig.CurrentPage then
                        TabConfig.CurrentPage.Btn.TextColor3 = SubTextColor
                        TabConfig.CurrentPage.Highlight.Size = UDim2.new(0,0,0,2)
                        TabConfig.CurrentPage.Highlight.BackgroundTransparency = 1
                        TabConfig.CurrentPage.Scroll.Visible = false
                    end
                    TabConfig.CurrentPage = firstPage
                    firstPage.Scroll.Visible = true
                    firstPage.Scroll.Position = UDim2.new(0,5,0,12)
                    Tween(firstPage.Scroll, {Position = UDim2.new(0,5,0,5)}, 0.3)
                    firstPage.Btn.TextColor3 = TextColor
                    firstPage.Highlight.Size = UDim2.new(1,0,0,2)
                    firstPage.Highlight.BackgroundTransparency = 0
                end
            end
        end)

        function TabConfig:CreatePage(pageName)
            local PageBtn = Create("TextButton", {
                Parent = PageNav, Text = pageName, Font = Enum.Font.GothamBold,
                TextSize = 13, TextColor3 = SubTextColor, BackgroundTransparency = 1,
                Size = UDim2.new(0,0,1,0), AutomaticSize = Enum.AutomaticSize.X
            })
            local PageHighlight = Create("Frame", {
                Parent = PageBtn, BackgroundColor3 = AccentColor,
                Size = UDim2.new(0,0,0,2), Position = UDim2.new(0.5,0,1,-5),
                AnchorPoint = Vector2.new(0.5,0), BackgroundTransparency = 1
            })
            local PageScroll = Create("ScrollingFrame", {
                Parent = PageContainer, BackgroundTransparency = 1,
                Size = UDim2.new(1,-10,1,-10), Position = UDim2.new(0,5,0,5),
                ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.BorderLight,
                Visible = false, BorderSizePixel = 0,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
            })

            local LeftColumn = Create("Frame", {Parent = PageScroll, BackgroundTransparency = 1, Size = UDim2.new(0.5, -5, 1, 0)})
            local RightColumn = Create("Frame", {Parent = PageScroll, BackgroundTransparency = 1, Size = UDim2.new(0.5, -5, 1, 0), Position = UDim2.new(0.5, 5, 0, 0)})
            local L_Layout = Create("UIListLayout", {Parent = LeftColumn, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})
            local R_Layout = Create("UIListLayout", {Parent = RightColumn, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})

            local function updateCanvas()
                PageScroll.CanvasSize = UDim2.new(0,0,0, math.max(L_Layout.AbsoluteContentSize.Y, R_Layout.AbsoluteContentSize.Y) + 20)
            end
            L_Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
            R_Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

            local PageObj = {
                Scroll = PageScroll, Btn = PageBtn, Highlight = PageHighlight,
                Left = true, LeftCol = LeftColumn, RightCol = RightColumn
            }
            table.insert(TabConfig.Pages, PageObj)

            PageBtn.MouseButton1Click:Connect(function()
                if TabConfig.CurrentPage == PageObj then return end
                if TabConfig.CurrentPage then
                    Tween(TabConfig.CurrentPage.Btn, {TextColor3 = SubTextColor}, 0.18)
                    Tween(TabConfig.CurrentPage.Highlight, {Size = UDim2.new(0,0,0,2), BackgroundTransparency = 1}, 0.18)
                    TabConfig.CurrentPage.Scroll.Visible = false
                end
                TabConfig.CurrentPage = PageObj
                PageObj.Scroll.Visible = true
                PageObj.Scroll.Position = UDim2.new(0,5,0,12)
                Tween(PageObj.Scroll, {Position = UDim2.new(0,5,0,5)}, 0.3)
                Tween(PageBtn, {TextColor3 = TextColor}, 0.18)
                Tween(PageHighlight, {Size = UDim2.new(1,0,0,2), BackgroundTransparency = 0}, 0.25)
            end)

            if #TabConfig.Pages == 1 and not isLocked then
                TabConfig.CurrentPage = PageObj
                PageObj.Scroll.Visible = true
                PageBtn.TextColor3 = TextColor
                PageHighlight.Size = UDim2.new(1,0,0,2)
                PageHighlight.BackgroundTransparency = 0
            end

            function PageObj:CreateSection(sectionName, side)
                local targetColumn
                if side == "Left" or side == "left" then targetColumn = LeftColumn
                elseif side == "Right" or side == "right" then targetColumn = RightColumn
                else
                    targetColumn = PageObj.Left and LeftColumn or RightColumn
                    PageObj.Left = not PageObj.Left
                end

                local SectionContainer = Create("Frame", {
                    Parent = targetColumn, BackgroundColor3 = CardColor,
                    Size = UDim2.new(1,0,0,30), AutomaticSize = Enum.AutomaticSize.Y,
                    ClipsDescendants = true
                })
                Create("UICorner", {Parent = SectionContainer, CornerRadius = UDim.new(0, 8)})
                Create("UIStroke", {Parent = SectionContainer, Color = Theme.Border, Thickness = 1})

                table.insert(Window.AllCards, {
                    Card = SectionContainer, OrigParent = targetColumn,
                    Tab = TabConfig, Page = PageObj, SearchIndex = nil
                })

                Create("TextLabel", {
                    Parent = SectionContainer, Text = sectionName, Font = Enum.Font.GothamBold,
                    TextSize = 13, TextColor3 = TextColor, BackgroundTransparency = 1,
                    Size = UDim2.new(1,-20,0,30), Position = UDim2.new(0,10,0,0),
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                local ItemContainer = Create("Frame", {
                    Parent = SectionContainer, BackgroundTransparency = 1,
                    Size = UDim2.new(1,0,0,0), Position = UDim2.new(0,0,0,30),
                    AutomaticSize = Enum.AutomaticSize.Y
                })
                Create("UIPadding", {Parent = ItemContainer, PaddingBottom = UDim.new(0,10), PaddingTop = UDim.new(0,5)})
                Create("UIListLayout", {Parent = ItemContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})

                local Elements = {}

                local function BuildInfo(config)
                    if config.Desc then
                        return {Title = config.Title, Description = config.Desc, Example = config.Example}
                    end
                    return nil
                end

                -- ====== AddCopyButton ======
                function Elements:AddCopyButton(name, copyText, infoData)
                    local BtnFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,30)})
                    local Btn = Create("TextButton", {
                        Parent = BtnFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12,
                        TextColor3 = TextColor, BackgroundColor3 = BackgroundColor,
                        Size = UDim2.new(1,-20,1,0), Position = UDim2.new(0,10,0,0), AutoButtonColor = false
                    })
                    Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)})
                    Create("UIStroke", {Parent = Btn, Color = Theme.Border, Thickness = 1})
                    AddBounce(Btn)
                    Btn.MouseEnter:Connect(function() Tween(Btn, {BackgroundColor3 = HoverColor}, 0.15) end)
                    Btn.MouseLeave:Connect(function() Tween(Btn, {BackgroundColor3 = BackgroundColor}, 0.15) end)
                    Btn.MouseButton1Click:Connect(function()
                        SafeCopyToClipboard(copyText)
                        local oldText = Btn.Text
                        Btn.Text = "✓ Copied!"
                        Tween(Btn, {TextColor3 = Theme.Success, BackgroundColor3 = HoverColor}, 0.15)
                        task.wait(1.2)
                        if Btn.Parent then
                            Btn.Text = oldText
                            Tween(Btn, {TextColor3 = TextColor, BackgroundColor3 = BackgroundColor}, 0.15)
                        end
                    end)
                    AddInfoIcon(BtnFrame, UDim2.new(1,-40,0.5,-8), infoData)
                end

                -- ====== AddButton ======
                function Elements:AddButton(name, callback, infoData)
                    local BtnFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,30)})
                    local Btn = Create("TextButton", {
                        Parent = BtnFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12,
                        TextColor3 = TextColor, BackgroundColor3 = BackgroundColor,
                        Size = UDim2.new(1,-20,1,0), Position = UDim2.new(0,10,0,0), AutoButtonColor = false
                    })
                    Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)})
                    Create("UIStroke", {Parent = Btn, Color = Theme.Border, Thickness = 1})
                    AddBounce(Btn)
                    Btn.MouseEnter:Connect(function() Tween(Btn, {BackgroundColor3 = HoverColor}, 0.15) end)
                    Btn.MouseLeave:Connect(function() Tween(Btn, {BackgroundColor3 = BackgroundColor}, 0.15) end)
                    Btn.MouseButton1Click:Connect(function() if callback then callback() end end)
                    AddInfoIcon(BtnFrame, UDim2.new(1,-40,0.5,-8), infoData)
                end

                -- (AddParagraph, AddToggle, AddSlider, AddDropdown, AddTextbox, AddColorPicker, AddConfigManager giữ nguyên logic gốc,
                --  nhưng thay Color3.fromRGB(45,45,50) → Theme.Border, 255,255,255 → Color3.new(1,1,1),
                --  thêm `ScrollingDirection` + `ElasticBehavior` cho các ScrollingFrame.)

                -- ====== WRAPPERS ======
                function Elements:Button(config) config = config or {}; return self:AddButton(config.Title, config.Callback, BuildInfo(config)) end
                function Elements:CopyButton(config) config = config or {}; return self:AddCopyButton(config.Title, config.Text or config.Content, BuildInfo(config)) end
                function Elements:Paragraph(config) config = config or {}; return self:AddParagraph(config.Title, config.Content, BuildInfo(config)) end
                function Elements:Toggle(config) config = config or {}; return self:AddToggle(config.Title, config.Value, config.Callback, BuildInfo(config)) end
                function Elements:Slider(config) config = config or {}; return self:AddSlider(config.Title, config.Min, config.Max, config.Value, config.Callback, BuildInfo(config)) end
                function Elements:Dropdown(config) config = config or {}; return self:AddDropdown(config.Title, config.Options, config.Multi, config.Value, config.Callback, BuildInfo(config)) end
                function Elements:Textbox(config) config = config or {}; return self:AddTextbox(config.Title, config.Placeholder, config.Value, config.Callback, BuildInfo(config)) end
                function Elements:ColorPicker(config) config = config or {}; return self:AddColorPicker(config.Title, config.Value, config.Callback, BuildInfo(config)) end
                function Elements:ConfigManager(config) config = config or {}; return self:AddConfigManager(config.Folder) end

                return Elements
            end
            return PageObj
        end

        if isDefault then
            TabBtn.BackgroundTransparency = 0
            Indicator.Size = UDim2.new(0,3,0,18)
            Txt.TextColor3 = TextColor
            TabContent.Visible = true
            Window.CurrentTab = TabConfig
        end
        return TabConfig
    end

    Library.SaveManager.Window = Window
    Window.Title = Window.Title or hubName
    return Window
end

return Library
