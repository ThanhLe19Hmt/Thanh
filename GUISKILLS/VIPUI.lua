--[[
    VIP UI Module: Status HUD, Keybind System, Notification nâng cao
]]

local Core = loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/GUISKILLS/Core.lua"))()
local UserInputService = Core.Services.UserInputService
local LocalPlayer = Core.Services.LocalPlayer
local RunService = Core.Services.RunService

local VIPUI = {}

-- ============================================================
-- NOTIFICATION SYSTEM (có queue + priority)
-- ============================================================
local NotifGui
local NotifContainer
local NotifQueue = {}
local MAX_VISIBLE = 5

local TYPE_STYLE = {
    info    = { color = Color3.fromRGB(88, 101, 242),  icon = "ℹ" },
    success = { color = Color3.fromRGB(76, 175, 80),   icon = "✓" },
    warning = { color = Color3.fromRGB(255, 180, 50),  icon = "⚠" },
    error   = { color = Color3.fromRGB(220, 60, 60),   icon = "✕" },
    vip     = { color = Color3.fromRGB(255, 215, 0),   icon = "★" },
}

local function Create(className, props)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do inst[k] = v end
    return inst
end

local function Tween(inst, props, dur)
    local t = Core.Services.RunService
    local tw = game:GetService("TweenService"):Create(
        inst,
        TweenInfo.new(dur or 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

function VIPUI.InitNotifications(parentGui)
    NotifGui = parentGui
    NotifContainer = Create("Frame", {
        Parent = parentGui,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 340, 1, -20),
        Position = UDim2.new(1, -360, 0, 10),
        ZIndex = 500,
    })
    Create("UIListLayout", {
        Parent = NotifContainer,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
    })
end

local function PlaySound(kind)
    local sound = Instance.new("Sound")
    sound.Parent = NotifGui
    if kind == "vip" then
        sound.SoundId = "rbxassetid://9046355469"
        sound.Volume = 0.6
    elseif kind == "error" then
        sound.SoundId = "rbxassetid://9114385651"
        sound.Volume = 0.4
    else
        sound.SoundId = "rbxassetid://9114385651"
        sound.Volume = 0.25
    end
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 3)
end

local function BuildNotif(opts)
    local kind = opts.Type or "info"
    local style = TYPE_STYLE[kind] or TYPE_STYLE.info

    local Notif = Create("Frame", {
        Parent = NotifContainer,
        BackgroundColor3 = Color3.fromRGB(20, 20, 24),
        Size = UDim2.new(1, 0, 0, 68),
        BackgroundTransparency = 1,
        ZIndex = 501,
        ClipsDescendants = false,
    })
    Create("UICorner", { Parent = Notif, CornerRadius = UDim.new(0, 10) })
    local Stroke = Create("UIStroke", {
        Parent = Notif,
        Color = style.color,
        Thickness = 1.4,
        Transparency = 1,
    })

    local AccentBar = Create("Frame", {
        Parent = Notif,
        BackgroundColor3 = style.color,
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 502,
    })
    Create("UICorner", { Parent = AccentBar, CornerRadius = UDim.new(0, 10) })

    local Icon = Create("TextLabel", {
        Parent = Notif,
        Text = style.icon,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = style.color,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 14, 0.5, -12),
        TextTransparency = 1,
        ZIndex = 502,
    })

    local Title = Create("TextLabel", {
        Parent = Notif,
        Text = opts.Title or "Thông báo",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(240, 240, 240),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 46, 0, 14),
        Size = UDim2.new(1, -58, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
        ZIndex = 502,
    })

    local Desc = Create("TextLabel", {
        Parent = Notif,
        Text = opts.Description or "",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(150, 150, 150),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 46, 0, 33),
        Size = UDim2.new(1, -58, 0, 26),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        TextTransparency = 1,
        ZIndex = 502,
    })

    -- Shine cho VIP
    if kind == "vip" then
        local Shine = Create("Frame", {
            Parent = Notif,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.85,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 30, 2, 0),
            Position = UDim2.new(-0.2, 0, -0.5, 0),
            Rotation = 20,
            ZIndex = 503,
        })
        task.delay(0.15, function()
            Tween(Shine, { Position = UDim2.new(1.2, 0, -0.5, 0) }, 0.7)
        end)
    end

    Tween(Notif, { BackgroundTransparency = 0 }, 0.25)
    Tween(Stroke, { Transparency = 0.4 }, 0.25)
    Tween(AccentBar, { BackgroundTransparency = 0 }, 0.25)
    Tween(Icon, { TextTransparency = 0 }, 0.25)
    Tween(Title, { TextTransparency = 0 }, 0.25)
    Tween(Desc, { TextTransparency = 0 }, 0.25)

    PlaySound(kind)

    return Notif
end

function VIPUI.Notify(opts)
    if not NotifContainer then return end
    table.insert(NotifQueue, opts)
end

local function ProcessQueue()
    while task.wait(0.2) do
        if not NotifContainer then continue end
        local count = #NotifContainer:GetChildren() - 1  -- trừ UIListLayout
        if #NotifQueue > 0 and count < MAX_VISIBLE then
            local opts = table.remove(NotifQueue, 1)
            local n = BuildNotif(opts)
            task.delay(opts.Duration or 3.5, function()
                if not n.Parent then return end
                Tween(n, { BackgroundTransparency = 1 }, 0.35)
                for _, c in ipairs(n:GetDescendants()) do
                    if c:IsA("TextLabel") then Tween(c, { TextTransparency = 1 }, 0.35)
                    elseif c:IsA("UIStroke") then Tween(c, { Transparency = 1 }, 0.35)
                    elseif c:IsA("Frame") and c.Name ~= "Shine" then
                        if c.BackgroundTransparency < 1 then Tween(c, { BackgroundTransparency = 1 }, 0.35) end
                    end
                end
                task.wait(0.4)
                if n.Parent then n:Destroy() end
            end)
        end
    end
end
task.spawn(ProcessQueue)

-- ============================================================
-- VIP STATUS HUD
-- ============================================================
local StatusHUD
local HUDLabels = {}
local HUDVisible = true

function VIPUI.InitStatusHUD(parentGui)
    StatusHUD = Create("Frame", {
        Parent = parentGui,
        BackgroundColor3 = Color3.fromRGB(15, 15, 20),
        BackgroundTransparency = 0.15,
        Size = UDim2.new(0, 240, 0, 130),
        Position = UDim2.new(0, 20, 0, 20),
        ZIndex = 400,
        ClipsDescendants = true,
    })
    Create("UICorner", { Parent = StatusHUD, CornerRadius = UDim.new(0, 10) })
    local stroke = Create("UIStroke", {
        Parent = StatusHUD,
        Color = Color3.fromRGB(60, 60, 80),
        Thickness = 1.2,
        Transparency = 0.3,
    })

    -- Gradient header
    local Header = Create("Frame", {
        Parent = StatusHUD,
        BackgroundColor3 = Color3.fromRGB(25, 25, 35),
        Size = UDim2.new(1, 0, 0, 28),
        ZIndex = 401,
    })
    Create("UICorner", { Parent = Header, CornerRadius = UDim.new(0, 10) })
    local HeaderGrad = Create("UIGradient", {
        Parent = Header,
        Color = ColorSequence.new(Color3.fromRGB(88, 101, 242), Color3.fromRGB(150, 90, 220)),
        Rotation = 45,
    })

    local HeaderTitle = Create("TextLabel", {
        Parent = Header,
        Text = "★ MarvenRiz VIP Status",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 402,
    })

    -- Content area
    local Content = Create("Frame", {
        Parent = StatusHUD,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -28),
        Position = UDim2.new(0, 0, 0, 28),
        ZIndex = 401,
    })
    Create("UIPadding", { Parent = Content, PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) })
    Create("UIListLayout", { Parent = Content, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })

    local fields = {
        { key = "hp",      label = "❤️ HP" },
        { key = "level",   label = "📊 Level" },
        { key = "beli",    label = "💵 Beli" },
        { key = "diamond", label = "💎 Diamond" },
        { key = "status",  label = "🎯 Status" },
    }
    for _, f in ipairs(fields) do
        local row = Create("Frame", { Parent = Content, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15) })
        Create("TextLabel", {
            Parent = row, Text = f.label,
            Font = Enum.Font.Gotham, TextSize = 11,
            TextColor3 = Color3.fromRGB(150, 150, 160),
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        local val = Create("TextLabel", {
            Parent = row, Text = "...",
            Font = Enum.Font.GothamBold, TextSize = 11,
            TextColor3 = Color3.fromRGB(240, 240, 240),
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Right,
        })
        HUDLabels[f.key] = val
    end

    -- Make draggable
    local dragging, dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = StatusHUD.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            StatusHUD.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

local function GetStatusText()
    local parts = {}
    if _G.Auto_Farm_Level then table.insert(parts, "Farm Level") end
    if _G.Auto_FarmBoss_Automatically then table.insert(parts, "Farm Boss") end
    if _G.Auto_Raid then table.insert(parts, "Raid") end
    if _G.Auto_Dungeon then table.insert(parts, "Dungeon") end
    if _G.Auto_Farm_Material then table.insert(parts, "Material") end
    if _G.Auto_CraftWeapon then table.insert(parts, "Craft") end
    if _G.Auto_BaconThief then table.insert(parts, "Thief") end
    if _G.Auto_Piccolo then table.insert(parts, "Piccolo") end
    if _G.Auto_Duck then table.insert(parts, "Duck") end
    if _G.Auto_DevilBoat then table.insert(parts, "Devil Boat") end
    if _G.Auto_SellItem then table.insert(parts, "Sell") end
    if #parts == 0 then return "Idle" end
    return table.concat(parts, ", ")
end

Core.TaskManager:Register("HUDUpdater", function()
    if not StatusHUD or not HUDVisible then task.wait(0.5) return end
    local char, hum = Core.GetCharacter()
    if HUDLabels.hp then
        if hum then
            local hp = math.floor(hum.Health)
            local maxhp = math.floor(hum.MaxHealth)
            local pct = math.floor((hum.Health / hum.MaxHealth) * 100)
            HUDLabels.hp.Text = string.format("%d/%d (%d%%)", hp, maxhp, pct)
            -- Color theo HP
            local c = pct > 60 and Color3.fromRGB(80, 220, 120)
                or pct > 30 and Color3.fromRGB(255, 200, 60)
                or Color3.fromRGB(240, 80, 80)
            HUDLabels.hp.TextColor3 = c
        else
            HUDLabels.hp.Text = "..."
        end
    end
    HUDLabels.level.Text = tostring(Core.GetAttribute("Level", 0))
    HUDLabels.beli.Text = Core.FormatNumber(Core.GetAttribute("Beli", 0))
    HUDLabels.diamond.Text = Core.FormatNumber(Core.GetAttribute("Diamond", 0))
    HUDLabels.status.Text = GetStatusText()
    task.wait(0.5)
end)
Core.TaskManager:Start("HUDUpdater")

function VIPUI.ToggleHUD()
    HUDVisible = not HUDVisible
    if StatusHUD then StatusHUD.Visible = HUDVisible end
    VIPUI.Notify({
        Title = HUDVisible and "HUD: Bật" or "HUD: Tắt",
        Type = "info",
        Duration = 1.5,
    })
end

-- ============================================================
-- KEYBIND SYSTEM
-- ============================================================
local Keybinds = {}

function VIPUI.RegisterKeybind(key, callback, description)
    table.insert(Keybinds, { key = key, cb = callback, desc = description })
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    for _, kb in ipairs(Keybinds) do
        if input.KeyCode == kb.key then
            pcall(kb.cb)
        end
    end
end)

-- ============================================================
-- EMERGENCY STOP
-- ============================================================
function VIPUI.EmergencyStop()
    local flags = {
        "_G.Auto_Farm_Level", "_G.Auto_CraftWeapon", "_G.Auto_Farm_Material",
        "_G.Auto_FarmBoss", "_G.Auto_FarmBoss_Automatically",
        "_G.Auto_Duck", "_G.Auto_DuckAutomatically", "_G.Auto_Farm_Set",
        "_G.Auto_Raid", "_G.Auto_BaconThief", "_G.Auto_Dungeon",
        "_G.Auto_Piccolo", "_G.Auto_DevilBoat", "_G.Auto_SellItem",
        "_G.Auto_Haki", "_G.Auto_RandomChest", "_G.Auto_RandomChest_Moon",
        "_G.Auto_Guarantee", "_G.Auto_Guarantee_Moon", "_G.Auto_Rebirth",
        "_G.Auto_Equip_Accessory", "_G.Auto_Use_Potion",
        "_G.AutoRaidRunning", "_G.AutoBuyDunRunning", "_G.AutoCraftRunning",
        "_G.AutoClaimGuarantee",
        "_G.AutoMelee", "_G.AutoDefense", "_G.AutoSword", "_G.AutoPower",
    }
    for _, f in ipairs(flags) do
        _G[f] = false
    end
    VIPUI.Notify({
        Title = "🛑 EMERGENCY STOP",
        Description = "Tất cả tính năng đã tắt!",
        Type = "error",
        Duration = 4,
    })
end

return VIPUI
