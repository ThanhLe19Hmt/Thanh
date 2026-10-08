-- =========================================================
--  NEO UI - Lightweight Roblox Menu Framework v11
--  Pure UI - No game functionality
--  Made by Marven
-- =========================================================

local Services = {
	Players = game:GetService("Players"),
	RunService = game:GetService("RunService"),
	UserInputService = game:GetService("UserInputService"),
	TweenService = game:GetService("TweenService"),
	CoreGui = game:GetService("CoreGui"),
	HttpService = game:GetService("HttpService"),
}
local LocalPlayer = Services.Players.LocalPlayer

-- =========================================================
--  THEME
-- =========================================================
local THEME = {
	Background   = Color3.fromRGB(14, 14, 16),
	Surface      = Color3.fromRGB(22, 22, 26),
	SurfaceHover = Color3.fromRGB(32, 32, 38),
	Border       = Color3.fromRGB(48, 48, 54),
	Accent       = Color3.fromRGB(230, 55, 55),
	AccentDark   = Color3.fromRGB(170, 30, 30),
	Slider       = Color3.fromRGB(230, 55, 55),
	Button       = Color3.fromRGB(230, 55, 55),
	ButtonHover  = Color3.fromRGB(255, 80, 80),
	Text         = Color3.fromRGB(245, 245, 248),
	TextDim      = Color3.fromRGB(150, 150, 158),
	Danger       = Color3.fromRGB(230, 90, 90),
}

local TINT_BACKGROUND = true

local Registry = {
	Menu = {}, Slider = {}, Button = {},
	Background = {}, Surface = {}, SurfaceHover = {}, Border = {},
}

local function Reg(list, inst, prop) table.insert(list, { inst = inst, prop = prop }) end

local function DeriveDark(c, f)
	f = f or 0.72
	local h, s, v = c:ToHSV()
	return Color3.fromHSV(h, math.min(1, s * 1.1), v * f)
end

local function ApplyList(list, color)
	for i = #list, 1, -1 do
		local e = list[i]
		if not e.inst or not e.inst.Parent then table.remove(list, i)
		else e.inst[e.prop] = color end
	end
end

local function DeriveBackgroundFromAccent(a)
	return Color3.fromHSV(a:ToHSV(), 0.35, 0.07)
end
local function DeriveSurfaceFromAccent(a)
	return Color3.fromHSV(a:ToHSV(), 0.30, 0.11)
end
local function DeriveSurfaceHoverFromAccent(a)
	return Color3.fromHSV(a:ToHSV(), 0.28, 0.16)
end
local function DeriveBorderFromAccent(a)
	return Color3.fromHSV(a:ToHSV(), 0.25, 0.22)
end

function _G.NeoSetMenuColor(color)
	if typeof(color) ~= "Color3" then return end
	THEME.Accent = color
	THEME.AccentDark = DeriveDark(color)
	ApplyList(Registry.Menu, color)
	if TINT_BACKGROUND then
		local bg = DeriveBackgroundFromAccent(color)
		local sf = DeriveSurfaceFromAccent(color)
		local sfH = DeriveSurfaceHoverFromAccent(color)
		local bd = DeriveBorderFromAccent(color)
		THEME.Background   = bg
		THEME.Surface      = sf
		THEME.SurfaceHover = sfH
		THEME.Border       = bd
		ApplyList(Registry.Background, bg)
		ApplyList(Registry.Surface, sf)
		ApplyList(Registry.SurfaceHover, sfH)
		ApplyList(Registry.Border, bd)
	end
end

function _G.NeoSetSliderColor(color)
	if typeof(color) ~= "Color3" then return end
	THEME.Slider = color
	ApplyList(Registry.Slider, color)
end

function _G.NeoSetButtonColor(color)
	if typeof(color) ~= "Color3" then return end
	THEME.Button = color
	THEME.ButtonHover = Color3.new(
		math.min(1, color.R * 1.15 + 0.05),
		math.min(1, color.G * 1.15 + 0.05),
		math.min(1, color.B * 1.15 + 0.05)
	)
	ApplyList(Registry.Button, color)
end

function _G.NeoSetTintBackground(enabled)
	TINT_BACKGROUND = enabled and true or false
	if TINT_BACKGROUND then _G.NeoSetMenuColor(THEME.Accent) end
end

-- =========================================================
--  HELPERS
-- =========================================================
local function Create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do inst[k] = v end
	for _, c in ipairs(children or {}) do c.Parent = inst end
	return inst
end

local function Tween(inst, props, dur, style, dir)
	local tw = Services.TweenService:Create(
		inst, TweenInfo.new(dur or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play(); return tw
end

local function Corner(r) return Create("UICorner", { CornerRadius = UDim.new(0, r or 8) }) end
local function Stroke(color, thick, transp)
	return Create("UIStroke", {
		Color = color or THEME.Border, Thickness = thick or 1,
		Transparency = transp or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end
local function Pad(l, r, t, b)
	return Create("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0),
		PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0),
	})
end

local function AddPress(btn, scale)
	scale = scale or 0.94
	local us = btn:FindFirstChildOfClass("UIScale") or Create("UIScale", { Parent = btn, Scale = 1 })
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			Tween(us, { Scale = scale }, 0.12)
		end
	end)
	local function release() Tween(us, { Scale = 1 }, 0.15) end
	btn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then release() end
	end)
	btn.MouseLeave:Connect(release)
end

local FONT   = Enum.Font.Gotham
local FONT_B = Enum.Font.GothamBold
local FONT_M = Enum.Font.GothamMedium
local IS_MOBILE = Services.UserInputService.TouchEnabled
	and not Services.UserInputService.KeyboardEnabled

local SIZE = {
	WindowW = IS_MOBILE and 380 or 520,
	WindowH = IS_MOBILE and 320 or 400,
	Sidebar = IS_MOBILE and 90  or 120,
	RowH    = IS_MOBILE and 36  or 32,
}

local parent = Services.RunService:IsStudio()
	and LocalPlayer:WaitForChild("PlayerGui") or Services.CoreGui

local gui = Create("ScreenGui", {
	Name = "NeoUI_" .. Services.HttpService:GenerateGUID(false),
	ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true, Parent = parent,
})

-- =========================================================
--  PALETTE
-- =========================================================
local PALETTES = {
	{ name = "Đỏ + Đen",       menu = Color3.fromRGB(230, 55, 55),  slider = Color3.fromRGB(255, 90, 90),  button = Color3.fromRGB(230, 55, 55) },
	{ name = "Xanh Dương",     menu = Color3.fromRGB(90, 150, 255), slider = Color3.fromRGB(120, 200, 255),button = Color3.fromRGB(90, 150, 255) },
	{ name = "Tím + Hồng",     menu = Color3.fromRGB(170, 100, 230),slider = Color3.fromRGB(230, 130, 255),button = Color3.fromRGB(200, 110, 240) },
	{ name = "Xanh Lá",        menu = Color3.fromRGB(80, 200, 120), slider = Color3.fromRGB(150, 230, 100),button = Color3.fromRGB(80, 200, 120) },
	{ name = "Cam + Vàng",     menu = Color3.fromRGB(240, 140, 60), slider = Color3.fromRGB(255, 200, 80), button = Color3.fromRGB(255, 130, 60) },
	{ name = "Hồng + Tím",     menu = Color3.fromRGB(255, 100, 180),slider = Color3.fromRGB(230, 130, 220),button = Color3.fromRGB(255, 100, 180) },
	{ name = "Cyan + Biển",    menu = Color3.fromRGB(60, 200, 220), slider = Color3.fromRGB(80, 230, 240), button = Color3.fromRGB(60, 200, 220) },
	{ name = "Vàng + Cam",     menu = Color3.fromRGB(240, 200, 80), slider = Color3.fromRGB(255, 170, 80), button = Color3.fromRGB(230, 170, 60) },
	{ name = "Đỏ đô + San hô", menu = Color3.fromRGB(200, 40, 90),  slider = Color3.fromRGB(255, 120, 160),button = Color3.fromRGB(220, 70, 120) },
	{ name = "Rêu + Ngọc",     menu = Color3.fromRGB(70, 180, 160), slider = Color3.fromRGB(120, 220, 200),button = Color3.fromRGB(90, 200, 180) },
	{ name = "Tím than",       menu = Color3.fromRGB(130, 80, 200), slider = Color3.fromRGB(180, 140, 240),button = Color3.fromRGB(150, 100, 220) },
	{ name = "Cam cháy",       menu = Color3.fromRGB(230, 100, 50), slider = Color3.fromRGB(255, 160, 80), button = Color3.fromRGB(210, 80, 60) },
}

local function randomPaletteDiffFrom(c1, c2, c3)
	local tries, pick = 0, nil
	repeat
		pick = PALETTES[math.random(1, #PALETTES)]
		tries = tries + 1
	until tries >= 8 or (pick.menu ~= c1 or pick.slider ~= c2 or pick.button ~= c3)
	return pick
end

-- =========================================================
--  PRESET POPUP
-- =========================================================
local PresetPopup = {}
local activePreset = nil

function PresetPopup:Close()
	if activePreset then
		local ap = activePreset
		activePreset = nil
		if ap.catcher then ap.catcher:Destroy() end
		Tween(ap.scale, { Scale = 0.9 }, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		Tween(ap.frame, { BackgroundTransparency = 1 }, 0.15)
		task.wait(0.16)
		ap.frame:Destroy()
	end
end

function PresetPopup:Open(anchorBtn, title, presets, onPick)
	PresetPopup:Close()

	local absPos = anchorBtn.AbsolutePosition
	local absSize = anchorBtn.AbsoluteSize
	local viewportY = workspace.CurrentCamera.ViewportSize.Y

	local cardW = 170
	local cardH = math.min(#presets * 26 + 40, 340)

	local openUp = (absPos.Y + absSize.Y + cardH + 10 > viewportY)
	local posY = openUp and (absPos.Y - cardH - 6) or (absPos.Y + absSize.Y + 6)
	local posX = math.max(8, absPos.X + absSize.X - cardW)

	local frame = Create("Frame", {
		Parent = gui, BackgroundColor3 = THEME.Surface,
		Size = UDim2.fromOffset(cardW, cardH),
		Position = UDim2.fromOffset(posX, posY),
		ZIndex = 950, ClipsDescendants = true,
	}, { Corner(10), Stroke(THEME.Border, 1, 0.35) })
	Reg(Registry.Surface, frame, "BackgroundColor3")

	local uiScale = Create("UIScale", { Parent = frame, Scale = 0.9 })
	Tween(uiScale, { Scale = 1 }, 0.2, Enum.EasingStyle.Back)

	Create("TextLabel", {
		Parent = frame, BackgroundTransparency = 1,
		Text = title or "Chọn preset", Font = FONT_B, TextSize = 11, TextColor3 = THEME.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 14),
	})

	local listScroll = Create("ScrollingFrame", {
		Parent = frame, BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 1, -30), Position = UDim2.new(0, 4, 0, 26),
		ScrollBarThickness = 2, ScrollBarImageColor3 = THEME.Border,
		CanvasSize = UDim2.new(0, 0, 0, 0), BorderSizePixel = 0,
	}, {
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }),
	})
	listScroll.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		listScroll.CanvasSize = UDim2.new(0, 0, 0, listScroll.UIListLayout.AbsoluteContentSize.Y + 4)
	end)

	for i, p in ipairs(presets) do
		local row = Create("TextButton", {
			Parent = listScroll, BackgroundColor3 = THEME.Background,
			Text = "", Size = UDim2.new(1, 0, 0, 24),
			AutoButtonColor = false, LayoutOrder = i,
		}, { Corner(5) })
		Reg(Registry.Background, row, "BackgroundColor3")

		Create("Frame", {
			Parent = row, BackgroundColor3 = p.color,
			Size = UDim2.fromOffset(14, 14),
			Position = UDim2.new(0, 6, 0.5, -7),
		}, { Corner(4), Stroke(Color3.fromRGB(255,255,255), 1, 0.7) })

		Create("TextLabel", {
			Parent = row, BackgroundTransparency = 1,
			Text = p.name, Font = FONT, TextSize = 11, TextColor3 = THEME.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 28, 0, 0), Size = UDim2.new(1, -32, 1, 0),
		})

		row.MouseEnter:Connect(function()
			Tween(row, { BackgroundColor3 = THEME.SurfaceHover }, 0.12)
		end)
		row.MouseLeave:Connect(function()
			Tween(row, { BackgroundColor3 = THEME.Background }, 0.12)
		end)
		row.MouseButton1Click:Connect(function()
			if onPick then task.spawn(onPick, p) end
			PresetPopup:Close()
		end)
	end

	local catcher = Create("TextButton", {
		Parent = gui, BackgroundTransparency = 1, Text = "",
		Size = UDim2.new(1, 0, 1, 0), ZIndex = 949,
	})
	catcher.MouseButton1Click:Connect(function() PresetPopup:Close() end)

	activePreset = { frame = frame, scale = uiScale, catcher = catcher }
	return activePreset
end

-- =========================================================
--  COLOR POPUP
-- =========================================================
local ColorPopup = {}
local activePopup = nil

function ColorPopup:Close()
	if activePopup then
		local ap = activePopup
		activePopup = nil
		Tween(ap.scale, { Scale = 0.85 }, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		Tween(ap.frame, { BackgroundTransparency = 1 }, 0.15)
		task.wait(0.18)
		ap.frame:Destroy()
	end
end

function ColorPopup:Open(initialColor, title, onLive, onConfirm)
	ColorPopup:Close()
	local h, s, v = initialColor:ToHSV()
	local color = initialColor

	local frame = Create("Frame", {
		Parent = gui, BackgroundColor3 = THEME.Surface,
		Size = UDim2.fromOffset(260, 250),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 999,
	}, { Corner(14), Stroke(THEME.Border, 1.2, 0.3) })
	Reg(Registry.Surface, frame, "BackgroundColor3")
	Reg(Registry.Menu, frame:FindFirstChildOfClass("UIStroke"), "Color")

	local uiScale = Create("UIScale", { Parent = frame, Scale = 0.85 })
	Tween(uiScale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)

	local header = Create("Frame", {
		Parent = frame, BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 38), ZIndex = 1000,
	})
	Create("TextLabel", {
		Parent = header, BackgroundTransparency = 1,
		Text = title or "Chọn màu", Font = FONT_B, TextSize = 13, TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -80, 1, 0), ZIndex = 1000,
	})
	local preview = Create("Frame", {
		Parent = header, BackgroundColor3 = color,
		Size = UDim2.fromOffset(26, 20),
		Position = UDim2.new(1, -66, 0.5, -10), ZIndex = 1000,
	}, { Corner(6), Stroke(Color3.fromRGB(255,255,255), 1, 0.6) })
	local closeBtn = Create("TextButton", {
		Parent = header, BackgroundColor3 = THEME.Background,
		Text = "✕", Font = FONT_B, TextSize = 11, TextColor3 = THEME.TextDim,
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(1, -34, 0.5, -12),
		AutoButtonColor = false, ZIndex = 1001,
	}, { Corner(6), Stroke(THEME.Border, 1, 0.5) })
	AddPress(closeBtn)

	local svMap = Create("TextButton", {
		Parent = frame, BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		Text = "", Size = UDim2.new(1, -28, 0, 120),
		Position = UDim2.new(0, 14, 0, 46),
		AutoButtonColor = false, Active = true, ZIndex = 1000,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	local whiteGrad = Create("Frame", {
		Parent = svMap, Size = UDim2.new(1,0,1,0),
		BackgroundColor3 = Color3.new(1,1,1), ZIndex = 2,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	Create("UIGradient", {
		Parent = whiteGrad,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
	})
	local blackGrad = Create("Frame", {
		Parent = svMap, Size = UDim2.new(1,0,1,0),
		BackgroundColor3 = Color3.new(0,0,0), ZIndex = 3,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	Create("UIGradient", {
		Parent = blackGrad,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Rotation = 90,
	})
	local svRing = Create("Frame", {
		Parent = blackGrad,
		Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(s, 0, 1 - v, 0),
		BackgroundColor3 = Color3.new(1,1,1), ZIndex = 4,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Stroke(Color3.new(0,0,0), 1.5, 0) })

	local hueSlider = Create("TextButton", {
		Parent = frame, Text = "",
		Size = UDim2.new(1, -28, 0, 16),
		Position = UDim2.new(0, 14, 0, 178),
		AutoButtonColor = false, BackgroundColor3 = Color3.new(1,1,1), Active = true, ZIndex = 1000,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	Create("UIGradient", {
		Parent = hueSlider,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		}),
	})
	local hueRing = Create("Frame", {
		Parent = hueSlider,
		Size = UDim2.new(0, 6, 1.6, 0), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(h, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1,1,1), ZIndex = 1001,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
		Stroke(Color3.new(0,0,0), 1.5, 0) })

	local hexBox = Create("TextBox", {
		Parent = frame, BackgroundColor3 = THEME.Background,
		Text = "#" .. color:ToHex(), PlaceholderText = "#FFFFFF",
		Font = FONT, TextSize = 11, TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false,
		Size = UDim2.new(0, 100, 0, 26),
		Position = UDim2.new(0, 14, 0, 210), ZIndex = 1000,
	}, { Corner(6), Stroke(THEME.Border, 1, 0.5) })
	Reg(Registry.Background, hexBox, "BackgroundColor3")

	local confirmBtn = Create("TextButton", {
		Parent = frame, BackgroundColor3 = THEME.Button,
		Text = "Xong", Font = FONT_B, TextSize = 12, TextColor3 = THEME.Text,
		Size = UDim2.new(0, 100, 0, 26),
		Position = UDim2.new(1, -114, 0, 210),
		AutoButtonColor = false, ZIndex = 1000,
	}, { Corner(6) })
	Reg(Registry.Button, confirmBtn, "BackgroundColor3")
	AddPress(confirmBtn)

	local function updateLive()
		color = Color3.fromHSV(h, s, v)
		preview.BackgroundColor3 = color
		svMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		hexBox.Text = "#" .. color:ToHex()
		if onLive then task.spawn(onLive, color) end
	end

	local draggingSV, draggingHue = false, false
	svMap.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then draggingSV = true end
	end)
	hueSlider.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then draggingHue = true end
	end)
	Services.UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			draggingSV = false; draggingHue = false
		end
	end)
	Services.UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			if draggingSV then
				local rx = math.clamp((input.Position.X - svMap.AbsolutePosition.X) / svMap.AbsoluteSize.X, 0, 1)
				local ry = math.clamp((input.Position.Y - svMap.AbsolutePosition.Y) / svMap.AbsoluteSize.Y, 0, 1)
				s = rx; v = 1 - ry
				svRing.Position = UDim2.new(s, 0, 1 - v, 0)
				updateLive()
			elseif draggingHue then
				local rx = math.clamp((input.Position.X - hueSlider.AbsolutePosition.X) / hueSlider.AbsoluteSize.X, 0, 1)
				h = rx
				hueRing.Position = UDim2.new(h, 0, 0.5, 0)
				updateLive()
			end
		end
	end)

	hexBox.FocusLost:Connect(function()
		local txt = hexBox.Text:gsub("#", "")
		local ok, c = pcall(function() return Color3.fromHex(txt) end)
		if ok and c then
			color = c
			h, s, v = c:ToHSV()
			preview.BackgroundColor3 = c
			svMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			svRing.Position = UDim2.new(s, 0, 1 - v, 0)
			hueRing.Position = UDim2.new(h, 0, 0.5, 0)
			if onLive then task.spawn(onLive, c) end
		else hexBox.Text = "#" .. color:ToHex() end
	end)

	local function close(confirm)
		if confirm and onConfirm then task.spawn(onConfirm, color) end
		ColorPopup:Close()
	end
	closeBtn.MouseButton1Click:Connect(function() close(false) end)
	confirmBtn.MouseButton1Click:Connect(function() close(true) end)

	activePopup = { frame = frame, scale = uiScale }
	updateLive()
	return activePopup
end

-- =========================================================
--  NOTIFY
-- =========================================================
local notifHolder = Create("Frame", {
	Parent = gui, BackgroundTransparency = 1,
	Size = UDim2.new(0, IS_MOBILE and 260 or 300, 0, 200),
	Position = UDim2.new(1, IS_MOBILE and -270 or -320, 1, -210), ZIndex = 100,
})
Create("UIListLayout", {
	Parent = notifHolder, SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Padding = UDim.new(0, 8),
})

local Notify = {}
function Notify:Show(opts)
	opts = opts or {}
	local title = opts.Title or "Thông báo"
	local desc  = opts.Desc or opts.Description or ""
	local dur   = opts.Duration or 3

	local frame = Create("Frame", {
		Parent = notifHolder, BackgroundColor3 = THEME.Surface,
		Size = UDim2.new(1, 0, 0, 60), ClipsDescendants = true, ZIndex = 101,
	}, { Corner(10), Stroke(THEME.Border, 1, 0.3), Pad(12, 12, 0, 0) })
	Reg(Registry.Surface, frame, "BackgroundColor3")

	local accent = Create("Frame", {
		Parent = frame, BackgroundColor3 = THEME.Accent,
		Size = UDim2.new(0, 3, 0, 30), Position = UDim2.new(0, 0, 0.5, -15),
		BorderSizePixel = 0, ZIndex = 101,
	}, { Corner(2) })
	Reg(Registry.Menu, accent, "BackgroundColor3")

	Create("TextLabel", {
		Parent = frame, BackgroundTransparency = 1,
		Text = title, Font = FONT_B, TextSize = 13, TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 12, 0, 10), Size = UDim2.new(1, -12, 0, 16), ZIndex = 101,
	})
	Create("TextLabel", {
		Parent = frame, BackgroundTransparency = 1,
		Text = desc, Font = FONT, TextSize = 11, TextColor3 = THEME.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
		Position = UDim2.new(0, 12, 0, 28), Size = UDim2.new(1, -12, 0, 24), ZIndex = 101,
	})

	frame.Position = UDim2.new(1, 40, 0, 0)
	Tween(frame, { Position = UDim2.new(0, 0, 0, 0) }, 0.3, Enum.EasingStyle.Quart)
	task.delay(dur, function()
		if not frame.Parent then return end
		Tween(frame, { Position = UDim2.new(1, 60, 0, 0), BackgroundTransparency = 1 }, 0.3)
		Tween(accent, { BackgroundTransparency = 1 }, 0.3)
		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("TextLabel") then Tween(d, { TextTransparency = 1 }, 0.3) end
		end
		task.wait(0.35)
		frame:Destroy()
	end)
end

-- =========================================================
--  LOADER
-- =========================================================
local Loader = {}
function Loader:Show(opts)
	opts = opts or {}
	local minDuration = opts.MinDuration or 2.2
	local startTime = tick()

	local overlay = Create("Frame", {
		Parent = gui, BackgroundColor3 = THEME.Background,
		Size = UDim2.new(1, 0, 1, 0), ZIndex = 500, BorderSizePixel = 0,
	})
	Reg(Registry.Background, overlay, "BackgroundColor3")
	local gradFrame = Create("Frame", {
		Parent = overlay, BackgroundColor3 = Color3.fromRGB(10, 10, 12),
		Size = UDim2.new(1, 0, 1, 0), ZIndex = 501, BorderSizePixel = 0,
	})
	Create("UIGradient", {
		Parent = gradFrame,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 10, 12)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(22, 14, 16)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 12)),
		}), Rotation = 45,
	})

	local center = Create("Frame", {
		Parent = overlay, BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(IS_MOBILE and 300 or 340, 180), ZIndex = 502,
	})
	local logoWrap = Create("Frame", {
		Parent = center, BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(80, 80), ZIndex = 502,
	})
	local ring = Create("Frame", {
		Parent = logoWrap, BackgroundTransparency = 1,
		Size = UDim2.fromOffset(80, 80), Position = UDim2.new(0.5, -40, 0.5, -40), ZIndex = 503,
	})
	local ringStroke = Create("UIStroke", {
		Parent = ring, Color = THEME.Accent, Thickness = 2.5, Transparency = 0.2,
	})
	Reg(Registry.Menu, ringStroke, "Color")
	local ringGrad = Create("UIGradient", {
		Parent = ringStroke,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.Accent),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 130, 130)),
			ColorSequenceKeypoint.new(1, THEME.Accent),
		}),
	})
	local innerCircle = Create("Frame", {
		Parent = logoWrap, BackgroundColor3 = THEME.Accent,
		Size = UDim2.fromOffset(58, 58), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0), ZIndex = 504,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	Reg(Registry.Menu, innerCircle, "BackgroundColor3")
	Create("TextLabel", {
		Parent = innerCircle, BackgroundTransparency = 1,
		Text = "N", Font = FONT_B, TextSize = 26, TextColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 1, 0), ZIndex = 505,
	})

	local titleLbl = Create("TextLabel", {
		Parent = center, BackgroundTransparency = 1,
		Text = opts.Title or "Neo Hub", Font = FONT_B, TextSize = 22, TextColor3 = THEME.Text,
		Position = UDim2.new(0, 0, 0, 100), Size = UDim2.new(1, 0, 0, 28),
		TextTransparency = 1, ZIndex = 502,
	})
	local subLbl = Create("TextLabel", {
		Parent = center, BackgroundTransparency = 1,
		Text = opts.Subtitle or "Đang tải...", Font = FONT_M, TextSize = 12, TextColor3 = THEME.TextDim,
		Position = UDim2.new(0, 0, 0, 128), Size = UDim2.new(1, 0, 0, 16),
		TextTransparency = 1, ZIndex = 502,
	})
	local progressBg = Create("Frame", {
		Parent = center, BackgroundColor3 = THEME.Border,
		Size = UDim2.new(1, -40, 0, 4), Position = UDim2.new(0, 20, 0, 158), ZIndex = 502,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local progressFill = Create("Frame", {
		Parent = progressBg, BackgroundColor3 = THEME.Accent,
		Size = UDim2.new(0, 0, 1, 0), ZIndex = 503,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	Reg(Registry.Menu, progressFill, "BackgroundColor3")

	Tween(titleLbl, { TextTransparency = 0 }, 0.5)
	Tween(subLbl, { TextTransparency = 0 }, 0.5)

	local running = true
	task.spawn(function()
		while running do
			for i = 0, 360, 4 do
				if not running then break end
				ringGrad.Rotation = i
				task.wait(0.016)
			end
		end
	end)
	task.spawn(function()
		while running do
			Tween(innerCircle, { Size = UDim2.fromOffset(64, 64) }, 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.wait(0.6)
			if not running then break end
			Tween(innerCircle, { Size = UDim2.fromOffset(58, 58) }, 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.wait(0.6)
		end
	end)
	task.spawn(function()
		local base = opts.Subtitle or "Đang tải..."
		local dots = 0
		while running do
			dots = (dots % 3) + 1
			subLbl.Text = base .. string.rep(".", dots)
			task.wait(0.4)
		end
	end)
	task.spawn(function()
		local target = 0
		while running and target < 0.9 do
			target = math.min(0.9, target + math.random(3, 8) / 100)
			Tween(progressFill, { Size = UDim2.new(target, 0, 1, 0) }, 0.35)
			task.wait(0.25)
		end
	end)

	local api = {}
	function api:SetStatus(text) subLbl.Text = text end
	function api:SetProgress(p)
		Tween(progressFill, { Size = UDim2.new(math.clamp(p,0,1), 0, 1, 0) }, 0.3)
	end
	function api:Close()
		if not running then return end
		running = false
		local remain = minDuration - (tick() - startTime)
		if remain > 0 then task.wait(remain) end
		Tween(progressFill, { Size = UDim2.new(1, 0, 1, 0) }, 0.25, Enum.EasingStyle.Quart)
		task.wait(0.3)
		Tween(overlay, { BackgroundTransparency = 1 }, 0.4)
		Tween(gradFrame, { BackgroundTransparency = 1 }, 0.4)
		Tween(center, { BackgroundTransparency = 1 }, 0.4)
		Tween(titleLbl, { TextTransparency = 1 }, 0.3)
		Tween(subLbl, { TextTransparency = 1 }, 0.3)
		Tween(ringStroke, { Transparency = 1 }, 0.3)
		Tween(innerCircle, { BackgroundTransparency = 1 }, 0.3)
		Tween(progressBg, { BackgroundTransparency = 1 }, 0.3)
		Tween(progressFill, { BackgroundTransparency = 1 }, 0.3)
		local sc = Create("UIScale", { Parent = center, Scale = 1 })
		Tween(sc, { Scale = 0.85 }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.wait(0.45)
		overlay:Destroy()
	end
	return api
end

-- =========================================================
--  WINDOW
-- =========================================================
local NeoUI = {}
NeoUI.Notify = Notify
NeoUI.Loader = Loader
NeoUI.ColorPopup = ColorPopup
NeoUI.PresetPopup = PresetPopup
NeoUI.Theme = THEME
NeoUI.Palettes = PALETTES
NeoUI.RandomPalette = randomPaletteDiffFrom
NeoUI.SetMenuColor = _G.NeoSetMenuColor
NeoUI.SetSliderColor = _G.NeoSetSliderColor
NeoUI.SetButtonColor = _G.NeoSetButtonColor
NeoUI.SetTintBackground = _G.NeoSetTintBackground

function NeoUI:CreateWindow(opts)
	opts = opts or {}
	local title = opts.Title or "Neo Hub"
	local sub = opts.Subtitle or "v1.0"

	local main = Create("Frame", {
		Name = "Main", Parent = gui, BackgroundColor3 = THEME.Background,
		Size = UDim2.fromOffset(SIZE.WindowW, SIZE.WindowH),
		Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
		Active = true, BackgroundTransparency = 1, Visible = false,
	}, { Corner(14), Stroke(THEME.Border, 1.2, 0.2) })
	Reg(Registry.Background, main, "BackgroundColor3")
	Reg(Registry.Border, main:FindFirstChildOfClass("UIStroke"), "Color")

	local uiScale = Create("UIScale", { Parent = main, Scale = 0.85 })

	local topBar = Create("Frame", {
		Parent = main, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48), Active = true,
	})
	local accentBar = Create("Frame", {
		Parent = topBar, BackgroundColor3 = THEME.Accent,
		Size = UDim2.new(1, -24, 0, 2), Position = UDim2.new(0, 12, 1, -1), BorderSizePixel = 0,
	}, { Corner(1) })
	Reg(Registry.Menu, accentBar, "BackgroundColor3")

	Create("TextLabel", {
		Parent = topBar, BackgroundTransparency = 1,
		Text = title, Font = FONT_B, TextSize = 16, TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 16, 0, 9), Size = UDim2.new(0.7, 0, 0, 20),
	})
	Create("TextLabel", {
		Parent = topBar, BackgroundTransparency = 1,
		Text = sub, Font = FONT, TextSize = 10, TextColor3 = THEME.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 16, 0, 28), Size = UDim2.new(0.7, 0, 0, 12),
	})

	local closeBtn = Create("TextButton", {
		Parent = topBar, BackgroundColor3 = THEME.Surface,
		Text = "✕", Font = FONT_B, TextSize = 13, TextColor3 = THEME.TextDim,
		Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -38, 0, 10), AutoButtonColor = false,
	}, { Corner(6), Stroke(THEME.Border, 1, 0.4) })
	Reg(Registry.Surface, closeBtn, "BackgroundColor3")
	AddPress(closeBtn)

	local minBtn = Create("TextButton", {
		Parent = topBar, BackgroundColor3 = THEME.Surface,
		Text = "—", Font = FONT_B, TextSize = 13, TextColor3 = THEME.TextDim,
		Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -72, 0, 10), AutoButtonColor = false,
	}, { Corner(6), Stroke(THEME.Border, 1, 0.4) })
	Reg(Registry.Surface, minBtn, "BackgroundColor3")
	AddPress(minBtn)

	local sidebar = Create("Frame", {
		Parent = main, BackgroundColor3 = THEME.Surface,
		Size = UDim2.new(0, SIZE.Sidebar, 1, -60), Position = UDim2.new(0, 8, 0, 52),
	}, { Corner(8) })
	Reg(Registry.Surface, sidebar, "BackgroundColor3")

	local sideList = Create("ScrollingFrame", {
		Parent = sidebar, BackgroundTransparency = 1,
		Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5),
		ScrollBarThickness = 2, ScrollBarImageColor3 = THEME.Border,
		CanvasSize = UDim2.new(0, 0, 0, 0), BorderSizePixel = 0,
	}, {
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
		Create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }),
	})

	local content = Create("Frame", {
		Parent = main, BackgroundColor3 = THEME.Surface,
		Size = UDim2.new(1, -SIZE.Sidebar - 24, 1, -60),
		Position = UDim2.new(0, SIZE.Sidebar + 16, 0, 52),
	}, { Corner(8) })
	Reg(Registry.Surface, content, "BackgroundColor3")

	local dragging, dragStart, startPos
	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	Services.UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)

	local sphere = Create("TextButton", {
		Parent = gui, BackgroundColor3 = THEME.Accent,
		Text = "N", Font = FONT_B, TextSize = 18, TextColor3 = THEME.Text,
		Size = UDim2.fromOffset(48, 48), Position = UDim2.new(0, 20, 0.5, -24),
		AutoButtonColor = false, Visible = false,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Stroke(THEME.AccentDark, 2, 0), Create("UIScale", { Scale = 0 }) })
	Reg(Registry.Menu, sphere, "BackgroundColor3")
	AddPress(sphere, 0.9)

	local minimized = false
	minBtn.MouseButton1Click:Connect(function()
		if minimized then return end
		minimized = true
		Tween(uiScale, { Scale = 0.7 }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		Tween(main, { BackgroundTransparency = 1 }, 0.25)
		task.wait(0.2)
		main.Visible = false; sphere.Visible = true
		Tween(sphere:FindFirstChildOfClass("UIScale"), { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
	end)
	sphere.MouseButton1Click:Connect(function()
		Tween(sphere:FindFirstChildOfClass("UIScale"), { Scale = 0 }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.wait(0.18)
		sphere.Visible = false; main.Visible = true; minimized = false
		Tween(uiScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
		Tween(main, { BackgroundTransparency = 0 }, 0.25)
	end)

	closeBtn.MouseButton1Click:Connect(function()
		Tween(uiScale, { Scale = 0.7 }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		Tween(main, { BackgroundTransparency = 1 }, 0.2)
		sphere:Destroy()
		task.wait(0.22)
		gui:Destroy()
	end)

	local Window = { Tabs = {}, CurrentTab = nil, GUI = gui, Main = main }
	function Window:Reveal()
		main.Visible = true
		Tween(uiScale, { Scale = 1 }, 0.45, Enum.EasingStyle.Back)
		Tween(main, { BackgroundTransparency = 0 }, 0.35)
	end

	function Window:CreateTab(name)
		local btn = Create("TextButton", {
			Parent = sideList, BackgroundColor3 = THEME.Surface, BackgroundTransparency = 1,
			Text = name, Font = FONT_M, TextSize = 12, TextColor3 = THEME.TextDim,
			Size = UDim2.new(1, 0, 0, SIZE.RowH),
			AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left,
		}, { Corner(6), Pad(10, 0, 0, 0) })
		AddPress(btn, 0.97)

		local ind = Create("Frame", {
			Parent = btn, BackgroundColor3 = THEME.Accent,
			Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5), BorderSizePixel = 0,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		Reg(Registry.Menu, ind, "BackgroundColor3")

		local tabContent = Create("ScrollingFrame", {
			Parent = content, BackgroundTransparency = 1,
			Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5),
			ScrollBarThickness = 2, ScrollBarImageColor3 = THEME.Border,
			CanvasSize = UDim2.new(0, 0, 0, 0), BorderSizePixel = 0, Visible = false,
		}, {
			Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
			Create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }),
		})
		tabContent.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			tabContent.CanvasSize = UDim2.new(0, 0, 0, tabContent.UIListLayout.AbsoluteContentSize.Y + 10)
		end)

		local tabObj = { Button = btn, Indicator = ind, Content = tabContent }
		table.insert(self.Tabs, tabObj)

		btn.MouseButton1Click:Connect(function()
			if self.CurrentTab then
				local old = self.CurrentTab
				old.Content.Visible = false
				Tween(old.Button, { BackgroundTransparency = 1, TextColor3 = THEME.TextDim }, 0.15)
				Tween(old.Indicator, { Size = UDim2.new(0, 3, 0, 0) }, 0.2)
			end
			self.CurrentTab = tabObj
			tabContent.Visible = true
			Tween(btn, { BackgroundTransparency = 0, TextColor3 = THEME.Text }, 0.15)
			Tween(ind, { Size = UDim2.new(0, 3, 0, 18) }, 0.25, Enum.EasingStyle.Quart)
		end)

		local Tab = {}
		function Tab:CreateSection(sectionTitle)
			local section = Create("Frame", {
				Parent = tabContent, BackgroundColor3 = THEME.Background,
				Size = UDim2.new(1, 0, 0, 40), AutomaticSize = Enum.AutomaticSize.Y,
				ClipsDescendants = true,
			}, { Corner(8), Stroke(THEME.Border, 1, 0.5), Pad(10, 10, 10, 10) })
			Reg(Registry.Background, section, "BackgroundColor3")
			Reg(Registry.Border, section:FindFirstChildOfClass("UIStroke"), "Color")

			Create("TextLabel", {
				Parent = section, BackgroundTransparency = 1,
				Text = sectionTitle, Font = FONT_B, TextSize = 12, TextColor3 = THEME.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, 0, 0, 18),
			})

			local itemHolder = Create("Frame", {
				Parent = section, BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
			}, {
				Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
			})

			local Section = {}

			function Section:Toggle(cfg)
				cfg = cfg or {}
				local state = cfg.Value == true
				local row = Create("Frame", {
					Parent = itemHolder, BackgroundColor3 = THEME.Surface,
					Size = UDim2.new(1, 0, 0, SIZE.RowH),
				}, { Corner(6) })
				Reg(Registry.Surface, row, "BackgroundColor3")

				Create("TextLabel", {
					Parent = row, BackgroundTransparency = 1,
					Text = cfg.Title or "Toggle", Font = FONT_M, TextSize = 12, TextColor3 = THEME.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -70, 1, 0),
				})
				local track = Create("Frame", {
					Parent = row, BackgroundColor3 = state and THEME.Button or THEME.Border,
					Size = UDim2.fromOffset(38, 20), Position = UDim2.new(1, -48, 0.5, -10),
				}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
				Reg(Registry.Button, track, "BackgroundColor3")

				local knob = Create("Frame", {
					Parent = track, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					Size = UDim2.fromOffset(14, 14),
					Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
				}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

				local clicker = Create("TextButton", {
					Parent = row, BackgroundTransparency = 1, Text = "",
					Size = UDim2.new(1, 0, 1, 0),
				})
				local function set(v)
					state = v
					track.BackgroundColor3 = state and THEME.Button or THEME.Border
					Tween(knob, { Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7) }, 0.2, Enum.EasingStyle.Quart)
					if cfg.Callback then task.spawn(cfg.Callback, state) end
				end
				clicker.MouseButton1Click:Connect(function() set(not state) end)
				return { Set = set, Get = function() return state end }
			end

			function Section:Button(cfg)
				cfg = cfg or {}
				local btn = Create("TextButton", {
					Parent = itemHolder, BackgroundColor3 = THEME.Button,
					Text = cfg.Title or "Button", Font = FONT_M, TextSize = 12, TextColor3 = THEME.Text,
					Size = UDim2.new(1, 0, 0, SIZE.RowH), AutoButtonColor = false,
				}, { Corner(6), Stroke(THEME.Border, 1, 0.6) })
				Reg(Registry.Button, btn, "BackgroundColor3")
				AddPress(btn)
				btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = THEME.ButtonHover }, 0.15) end)
				btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = THEME.Button }, 0.15) end)
				btn.MouseButton1Click:Connect(function() if cfg.Callback then task.spawn(cfg.Callback) end end)
				return { Instance = btn }
			end

			function Section:Slider(cfg)
				cfg = cfg or {}
				local minV, maxV, val = cfg.Min or 0, cfg.Max or 100, cfg.Value or (cfg.Min or 0)
				local wrap = Create("Frame", {
					Parent = itemHolder, BackgroundColor3 = THEME.Surface,
					Size = UDim2.new(1, 0, 0, 52),
				}, { Corner(6) })
				Reg(Registry.Surface, wrap, "BackgroundColor3")

				Create("TextLabel", {
					Parent = wrap, BackgroundTransparency = 1,
					Text = cfg.Title or "Slider", Font = FONT_M, TextSize = 12, TextColor3 = THEME.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(0.6, 0, 0, 16),
				})
				local valueLbl = Create("TextLabel", {
					Parent = wrap, BackgroundTransparency = 1,
					Text = tostring(val), Font = FONT_B, TextSize = 12, TextColor3 = THEME.Slider,
					TextXAlignment = Enum.TextXAlignment.Right,
					Position = UDim2.new(1, -60, 0, 6), Size = UDim2.new(0, 50, 0, 16),
				})
				Reg(Registry.Slider, valueLbl, "TextColor3")

				local track = Create("Frame", {
					Parent = wrap, BackgroundColor3 = THEME.Border,
					Size = UDim2.new(1, -20, 0, 6), Position = UDim2.new(0, 10, 0, 32),
				}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
				Reg(Registry.Border, track, "BackgroundColor3")
				local fill = Create("Frame", {
					Parent = track, BackgroundColor3 = THEME.Slider,
					Size = UDim2.new((val - minV) / (maxV - minV), 0, 1, 0),
				}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
				Reg(Registry.Slider, fill, "BackgroundColor3")

				Create("Frame", {
					Parent = fill, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
				}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

				local hit = Create("TextButton", {
					Parent = wrap, BackgroundTransparency = 1, Text = "",
					Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 20),
				})
				local function set(v, fire)
					v = math.clamp(v, minV, maxV)
					val = v
					valueLbl.Text = tostring(math.floor(v * 100) / 100)
					Tween(fill, { Size = UDim2.new((v - minV) / (maxV - minV), 0, 1, 0) }, 0.08)
					if fire and cfg.Callback then task.spawn(cfg.Callback, v) end
				end
				local dragging = false
				hit.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
				end)
				Services.UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
				end)
				Services.UserInputService.InputChanged:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
						or input.UserInputType == Enum.UserInputType.Touch) then
						local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
						set(minV + (maxV - minV) * rel, true)
					end
				end)
				if cfg.Callback then task.spawn(cfg.Callback, val) end
				return { Set = set, Get = function() return val end }
			end

			function Section:Textbox(cfg)
				cfg = cfg or {}
				local wrap = Create("Frame", {
					Parent = itemHolder, BackgroundColor3 = THEME.Surface,
					Size = UDim2.new(1, 0, 0, 54),
				}, { Corner(6) })
				Reg(Registry.Surface, wrap, "BackgroundColor3")

				Create("TextLabel", {
					Parent = wrap, BackgroundTransparency = 1,
					Text = cfg.Title or "Textbox", Font = FONT_M, TextSize = 12, TextColor3 = THEME.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 16),
				})
				local box = Create("TextBox", {
					Parent = wrap, BackgroundColor3 = THEME.Background,
					Text = cfg.Value or "", PlaceholderText = cfg.Placeholder or "Nhập...",
					PlaceholderColor3 = THEME.TextDim,
					Font = FONT, TextSize = 12, TextColor3 = THEME.Text,
					TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
					Position = UDim2.new(0, 10, 0, 26), Size = UDim2.new(1, -20, 0, 22),
				}, { Corner(6), Stroke(THEME.Border, 1, 0.5), Pad(8, 0, 0, 0) })
				Reg(Registry.Background, box, "BackgroundColor3")

				box.Focused:Connect(function()
					Tween(box, { BackgroundColor3 = THEME.SurfaceHover }, 0.15)
					Tween(box:FindFirstChildOfClass("UIStroke"), { Color = THEME.Accent }, 0.15)
				end)
				box.FocusLost:Connect(function()
					Tween(box, { BackgroundColor3 = THEME.Background }, 0.15)
					Tween(box:FindFirstChildOfClass("UIStroke"), { Color = THEME.Border }, 0.15)
					if cfg.Callback then task.spawn(cfg.Callback, box.Text) end
				end)
				return { Set = function(v) box.Text = tostring(v) end, Get = function() return box.Text end }
			end

			function Section:Dropdown(cfg)
				cfg = cfg or {}
				local options = cfg.Options or {}
				local isMulti = cfg.Multi == true
				local selected = isMulti and (type(cfg.Value) == "table" and cfg.Value or {}) or (cfg.Value or options[1])
				local opened = false

				local wrap = Create("Frame", {
					Parent = itemHolder, BackgroundColor3 = THEME.Surface,
					Size = UDim2.new(1, 0, 0, 56), ClipsDescendants = true,
				}, { Corner(6) })
				Reg(Registry.Surface, wrap, "BackgroundColor3")

				Create("TextLabel", {
					Parent = wrap, BackgroundTransparency = 1,
					Text = cfg.Title or "Dropdown", Font = FONT_M, TextSize = 12, TextColor3 = THEME.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 16),
				})
				local mainBtn = Create("TextButton", {
					Parent = wrap, BackgroundColor3 = THEME.Background,
					Text = "", Size = UDim2.new(1, -20, 0, 24),
					Position = UDim2.new(0, 10, 0, 26), AutoButtonColor = false,
				}, { Corner(6), Stroke(THEME.Border, 1, 0.5) })
				Reg(Registry.Background, mainBtn, "BackgroundColor3")

				local display = Create("TextLabel", {
					Parent = mainBtn, BackgroundTransparency = 1,
					Text = "Chọn...", Font = FONT, TextSize = 11, TextColor3 = THEME.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -30, 1, 0),
				})
				local arrow = Create("TextLabel", {
					Parent = mainBtn, BackgroundTransparency = 1,
					Text = "▾", Font = FONT_B, TextSize = 12, TextColor3 = THEME.TextDim,
					Position = UDim2.new(1, -22, 0, 0), Size = UDim2.new(0, 20, 1, 0),
				})
				local listHolder = Create("Frame", {
					Parent = wrap, BackgroundTransparency = 1,
					Size = UDim2.new(1, -20, 0, 0), Position = UDim2.new(0, 10, 0, 54),
					AutomaticSize = Enum.AutomaticSize.Y,
				}, {
					Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }),
				})

				local optBtns = {}
				local function render()
					for _, b in ipairs(optBtns) do b:Destroy() end
					optBtns = {}
					for _, opt in ipairs(options) do
						local isSel = isMulti and table.find(selected, opt) or (not isMulti and selected == opt)
						local ob = Create("TextButton", {
							Parent = listHolder,
							BackgroundColor3 = isSel and THEME.AccentDark or THEME.Background,
							BackgroundTransparency = isSel and 0 or 0.5,
							Text = tostring(opt), Font = FONT, TextSize = 11, TextColor3 = THEME.Text,
							TextXAlignment = Enum.TextXAlignment.Left,
							Size = UDim2.new(1, 0, 0, 24), AutoButtonColor = false,
						}, { Corner(4), Pad(8, 0, 0, 0) })
						Reg(Registry.Background, ob, "BackgroundColor3")
						AddPress(ob, 0.97)
						table.insert(optBtns, ob)
						ob.MouseButton1Click:Connect(function()
							if isMulti then
								local idx = table.find(selected, opt)
								if idx then table.remove(selected, idx) else table.insert(selected, opt) end
							else
								selected = opt; opened = false
							end
							render()
							if isMulti then
								local t = {}
								for _, v in ipairs(selected) do table.insert(t, tostring(v)) end
								display.Text = #t > 0 and table.concat(t, ", ") or "Chọn..."
							else
								display.Text = tostring(selected)
							end
							if cfg.Callback then task.spawn(cfg.Callback, selected) end
							if not isMulti then
								Tween(arrow, { Rotation = 0 }, 0.2)
								Tween(wrap, { Size = UDim2.new(1, 0, 0, 56) }, 0.25, Enum.EasingStyle.Quart)
							end
						end)
					end
				end
				render()
				if isMulti then
					local t = {}
					for _, v in ipairs(selected) do table.insert(t, tostring(v)) end
					display.Text = #t > 0 and table.concat(t, ", ") or "Chọn..."
				else
					display.Text = tostring(selected)
				end

				mainBtn.MouseButton1Click:Connect(function()
					opened = not opened
					if opened then
						Tween(wrap, { Size = UDim2.new(1, 0, 0, 56 + #options * 26 + 6) }, 0.25, Enum.EasingStyle.Quart)
						Tween(arrow, { Rotation = 180 }, 0.25)
					else
						Tween(wrap, { Size = UDim2.new(1, 0, 0, 56) }, 0.25, Enum.EasingStyle.Quart)
						Tween(arrow, { Rotation = 0 }, 0.25)
					end
				end)
				
				AddPress(mainBtn, 0.98)
				if cfg.Callback then task.spawn(cfg.Callback, selected) end

				-- ⭐ Handle với Refresh method
				local handle = {}
				handle.Get = function() return selected end
				handle.Set = function(v) selected = v; render() end

				-- ⭐ Refresh Options runtime
				handle.Refresh = function(newOptions, keepSelection)
					options = newOptions or options
					keepSelection = keepSelection ~= false

					-- Xử lý selection khi options đổi
					if isMulti then
						if keepSelection and type(selected) == "table" then
							local kept = {}
							for _, v in ipairs(selected) do
								if table.find(options, v) then
									table.insert(kept, v)
								end
							end
							selected = kept
						else
							selected = {}
						end
					else
						if not (keepSelection and table.find(options, selected)) then
							selected = options[1]
						end
					end

					-- Rebuild lại list
					for _, b in ipairs(optBtns) do b:Destroy() end
					optBtns = {}
					render()

					-- Update display text
					if isMulti then
						local t = {}
						for _, v in ipairs(selected) do table.insert(t, tostring(v)) end
						display.Text = #t > 0 and table.concat(t, ", ") or "Chọn..."
					else
						display.Text = (selected ~= nil) and tostring(selected) or "Chọn..."
					end

					-- Nếu đang mở thì tween lại size
					if opened then
						local newH = 56 + #options * 26 + 6
						Tween(wrap, { Size = UDim2.new(1, 0, 0, newH) }, 0.2, Enum.EasingStyle.Quart)
					end

					if cfg.Callback then task.spawn(cfg.Callback, selected) end
				end

				return handle
			end

			function Section:Paragraph(cfg)
				cfg = cfg or {}
				local wrap = Create("Frame", {
					Parent = itemHolder, BackgroundColor3 = THEME.Surface, BackgroundTransparency = 0.3,
					Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
				}, { Corner(6), Stroke(THEME.Border, 1, 0.7), Pad(10, 10, 10, 10) })
				Reg(Registry.Surface, wrap, "BackgroundColor3")
				Reg(Registry.Border, wrap:FindFirstChildOfClass("UIStroke"), "Color")

				if cfg.Title then
					Create("TextLabel", {
						Parent = wrap, BackgroundTransparency = 1,
						Text = cfg.Title, Font = FONT_B, TextSize = 12, TextColor3 = THEME.Text,
						TextXAlignment = Enum.TextXAlignment.Left,
						Size = UDim2.new(1, 0, 0, 16),
					})
				end
				local contentLbl = Create("TextLabel", {
					Parent = wrap, BackgroundTransparency = 1,
					Text = cfg.Content or "", Font = FONT, TextSize = 11, TextColor3 = THEME.TextDim,
					TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
					TextWrapped = true,
					Position = cfg.Title and UDim2.new(0, 0, 0, 20) or UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LineHeight = 1.2,
				})
				return {
					SetContent = function(t) contentLbl.Text = tostring(t) end,
					SetTitle = function(t)
						contentLbl.Position = (t and t ~= "") and UDim2.new(0, 0, 0, 20) or UDim2.new(0, 0, 0, 0)
					end,
				}
			end

			function Section:ColorRow(cfg)
				cfg = cfg or {}
				local color = cfg.Value or THEME.Accent

				local row = Create("Frame", {
					Parent = itemHolder, BackgroundColor3 = THEME.Surface,
					Size = UDim2.new(1, 0, 0, SIZE.RowH),
				}, { Corner(6) })
				Reg(Registry.Surface, row, "BackgroundColor3")

				Create("TextLabel", {
					Parent = row, BackgroundTransparency = 1,
					Text = cfg.Title or "Color", Font = FONT_M, TextSize = 12, TextColor3 = THEME.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0.5, 0, 1, 0),
				})

				local rightHolder = Create("Frame", {
					Parent = row, BackgroundTransparency = 1,
					Position = UDim2.new(1, -110, 0.5, -10),
					Size = UDim2.fromOffset(100, 20),
				})
				Create("UIListLayout", {
					Parent = rightHolder,
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
				})

				if cfg.Presets and #cfg.Presets > 0 then
					local presetBtn = Create("TextButton", {
						Parent = rightHolder, BackgroundColor3 = THEME.Background,
						Text = "▾", Font = FONT_B, TextSize = 12, TextColor3 = THEME.TextDim,
						Size = UDim2.fromOffset(28, 20), AutoButtonColor = false,
						LayoutOrder = 1,
					}, { Corner(5), Stroke(THEME.Border, 1, 0.6) })
					Reg(Registry.Background, presetBtn, "BackgroundColor3")
					AddPress(presetBtn)
					presetBtn.MouseButton1Click:Connect(function()
						PresetPopup:Open(presetBtn, cfg.PresetTitle or "Chọn preset", cfg.Presets, function(p)
							color = p.color
							if cfg.Setter then task.spawn(cfg.Setter, p.color) end
							if cfg.OnConfirm then task.spawn(cfg.OnConfirm, p.color) end
						end)
					end)
				end

				if cfg.RandomFn then
					local rndBtn = Create("TextButton", {
						Parent = rightHolder, BackgroundColor3 = THEME.Background,
						Text = "🎲", Font = FONT, TextSize = 13, TextColor3 = THEME.Text,
						Size = UDim2.fromOffset(28, 20), AutoButtonColor = false,
						LayoutOrder = 2,
					}, { Corner(5), Stroke(THEME.Border, 1, 0.6) })
					Reg(Registry.Background, rndBtn, "BackgroundColor3")
					AddPress(rndBtn)
					rndBtn.MouseEnter:Connect(function() Tween(rndBtn, { BackgroundColor3 = THEME.SurfaceHover }, 0.12) end)
					rndBtn.MouseLeave:Connect(function() Tween(rndBtn, { BackgroundColor3 = THEME.Background }, 0.12) end)
					rndBtn.MouseButton1Click:Connect(function()
						local nc = cfg.RandomFn()
						if typeof(nc) == "Color3" then color = nc end
					end)
				end

				local preview = Create("TextButton", {
					Parent = rightHolder, BackgroundColor3 = color,
					Text = "", Size = UDim2.fromOffset(36, 20),
					AutoButtonColor = false, LayoutOrder = 3,
				}, { Corner(5), Stroke(Color3.fromRGB(255,255,255), 1, 0.75) })
				AddPress(preview)

				preview.MouseButton1Click:Connect(function()
					ColorPopup:Open(color, cfg.Title or "Chọn màu",
						function(liveColor)
							preview.BackgroundColor3 = liveColor
							color = liveColor
							if cfg.Setter then task.spawn(cfg.Setter, liveColor) end
						end,
						function(finalColor)
							color = finalColor
							if cfg.OnConfirm then task.spawn(cfg.OnConfirm, finalColor) end
						end
					)
				end)

				return {
					Set = function(c)
						if typeof(c) == "Color3" then
							color = c
							preview.BackgroundColor3 = c
							if cfg.Setter then task.spawn(cfg.Setter, c) end
						end
					end,
					Get = function() return color end,
				}
			end

									-- ⭐ ListRow — hiện danh sách item dạng key: value
			function Section:ListRow(cfg)
				cfg = cfg or {}
				local wrap = Create("Frame", {
					Parent = itemHolder, BackgroundColor3 = THEME.Surface,
					Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
				}, { Corner(6), Pad(8, 8, 8, 8) })
				Reg(Registry.Surface, wrap, "BackgroundColor3")

				local titleLbl = Create("TextLabel", {
					Parent = wrap, BackgroundTransparency = 1,
					Text = cfg.Title or "Info", Font = FONT_B, TextSize = 12, TextColor3 = THEME.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Size = UDim2.new(1, 0, 0, 16),
				})

				local list = Create("Frame", {
					Parent = wrap, BackgroundTransparency = 1,
					Position = UDim2.new(0, 0, 0, 20), Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
				}, {
					Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
				})

				local valueLabels = {}

				local function createRow(key, value, order)
					local row = Create("Frame", {
						Parent = list, BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 20), LayoutOrder = order,
					})

					-- Key label — bên trái, cho 45% bề rộng
					local keyLbl = Create("TextLabel", {
						Parent = row, BackgroundTransparency = 1,
						Text = tostring(key) .. ":",
						Font = FONT_M, TextSize = 11, TextColor3 = THEME.TextDim,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Size = UDim2.new(0.45, -4, 1, 0),
						Position = UDim2.new(0, 0, 0, 0),
					})

					-- Value label — bên phải, 55%
					local valLbl = Create("TextLabel", {
						Parent = row, BackgroundTransparency = 1,
						Text = tostring(value),
						Font = FONT_B, TextSize = 11, TextColor3 = THEME.Text,
						TextXAlignment = Enum.TextXAlignment.Right,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextScaled = false,
						Size = UDim2.new(0.55, -4, 1, 0),
						Position = UDim2.new(0.45, 4, 0, 0),
					})
					valueLabels[key] = valLbl
					return row
				end

				if cfg.Items then
					for i, item in ipairs(cfg.Items) do
						createRow(item.key, item.value, i)
					end
				end

				local handle = {}
				handle.Instance = wrap

				function handle:SetItems(items)
					for _, c in ipairs(list:GetChildren()) do
						if c:IsA("Frame") then c:Destroy() end
					end
					valueLabels = {}
					for i, item in ipairs(items or {}) do
						createRow(item.key, item.value, i)
					end
				end

				function handle:UpdateItem(key, value)
					local lbl = valueLabels[key]
					if lbl and lbl.Parent then
						local newText = tostring(value)
						if lbl.Text ~= newText then
							lbl.Text = newText
						end
						return true
					end
					return false
				end

				function handle:UpdateItems(map)
					for key, value in pairs(map or {}) do
						local lbl = valueLabels[key]
						if lbl and lbl.Parent then
							lbl.Text = tostring(value)
						end
					end
				end

				function handle:SetTitle(t) titleLbl.Text = tostring(t) end

				print("[NeoUI] ListRow created with", #(cfg.Items or {}), "items")

				return handle  -- ⭐ QUAN TRỌNG — phải có return
			end

						-- ⭐ 2 CỘT — chia section thành trái/phải
			function Section:TwoColumn()
				local twoColWrap = Create("Frame", {
					Parent = itemHolder, BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
				})

				local leftCol = Create("Frame", {
					Parent = twoColWrap, BackgroundTransparency = 1,
					Size = UDim2.new(0.5, -3, 0, 0),
					Position = UDim2.new(0, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
				}, {
					Create("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 6),
					}),
				})

				local rightCol = Create("Frame", {
					Parent = twoColWrap, BackgroundTransparency = 1,
					Size = UDim2.new(0.5, -3, 0, 0),
					Position = UDim2.new(0.5, 3, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
				}, {
					Create("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 6),
					}),
				})

				-- Section ảo dùng chung toàn bộ logic gốc
				-- Cách làm: tạo closure mới có cùng methods nhưng itemHolder = colFrame

				local function buildVirtual(colFrame, colName)
					local V = {}

					local function makeHolder(parentFrame)
						return Create("Frame", {
							Parent = parentFrame, BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 0),
							AutomaticSize = Enum.AutomaticSize.Y,
						})
					end

					-- Tạo holder ẩn bên trong colFrame để các method gốc có thể parent vào
					local vHolder = Create("Frame", {
						Parent = colFrame, BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
					}, {
						Create("UIListLayout", {
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, 6),
						}),
					})

					-- ⭐ Ghi đè biến itemHolder bằng cách REBIND closure
					-- Kỹ thuật: dùng lại toàn bộ Section gốc nhưng
					-- với itemHolder = vHolder bằng cách patch tạm
					local originalHolder = itemHolder
					itemHolder = vHolder

					-- Clone các method
					for k, fn in pairs(Section) do
						V[k] = fn
					end

					-- Khôi phục
					itemHolder = originalHolder

					-- ⚠️ Vấn đề: các method gốc capture itemHolder lúc định nghĩa.
					-- Nên cách này KHÔNG hoạt động.
					-- Cần phải viết lại từ đầu — xem phương án B bên dưới.

					return V
				end

				-- Phương án B: Section ảo tự implement
				local function makeRealVirtual(colFrame)
					local V = {}

					-- Button
					function V:Button(cfg)
						cfg = cfg or {}
						local btn = Create("TextButton", {
							Parent = colFrame, BackgroundColor3 = THEME.Button,
							Text = cfg.Title or "Button", Font = FONT_M, TextSize = 12,
							TextColor3 = THEME.Text,
							Size = UDim2.new(1, 0, 0, SIZE.RowH),
							AutoButtonColor = false,
						}, { Corner(6), Stroke(THEME.Border, 1, 0.6) })
						Reg(Registry.Button, btn, "BackgroundColor3")
						AddPress(btn)
						btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = THEME.ButtonHover }, 0.15) end)
						btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = THEME.Button }, 0.15) end)
						btn.MouseButton1Click:Connect(function()
							if cfg.Callback then task.spawn(cfg.Callback) end
						end)
						return { Instance = btn }
					end

					-- Toggle
					function V:Toggle(cfg)
						cfg = cfg or {}
						local state = cfg.Value == true
						local row = Create("Frame", {
							Parent = colFrame, BackgroundColor3 = THEME.Surface,
							Size = UDim2.new(1, 0, 0, SIZE.RowH),
						}, { Corner(6) })
						Reg(Registry.Surface, row, "BackgroundColor3")

						Create("TextLabel", {
							Parent = row, BackgroundTransparency = 1,
							Text = cfg.Title or "Toggle", Font = FONT_M, TextSize = 12,
							TextColor3 = THEME.Text,
							TextXAlignment = Enum.TextXAlignment.Left,
							Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -70, 1, 0),
						})

						local track = Create("Frame", {
							Parent = row,
							BackgroundColor3 = state and THEME.Button or THEME.Border,
							Size = UDim2.fromOffset(38, 20),
							Position = UDim2.new(1, -48, 0.5, -10),
						}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
						Reg(Registry.Button, track, "BackgroundColor3")

						local knob = Create("Frame", {
							Parent = track, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							Size = UDim2.fromOffset(14, 14),
							Position = state and UDim2.new(1, -17, 0.5, -7)
								or UDim2.new(0, 3, 0.5, -7),
						}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

						local clicker = Create("TextButton", {
							Parent = row, BackgroundTransparency = 1, Text = "",
							Size = UDim2.new(1, 0, 1, 0),
						})

						local function set(v)
							state = v
							track.BackgroundColor3 = state and THEME.Button or THEME.Border
							Tween(knob, {
								Position = state and UDim2.new(1, -17, 0.5, -7)
									or UDim2.new(0, 3, 0.5, -7),
							}, 0.2, Enum.EasingStyle.Quart)
							if cfg.Callback then task.spawn(cfg.Callback, state) end
						end

						clicker.MouseButton1Click:Connect(function() set(not state) end)
						return { Set = set, Get = function() return state end }
					end

					-- Textbox
					function V:Textbox(cfg)
						cfg = cfg or {}
						local wrap = Create("Frame", {
							Parent = colFrame, BackgroundColor3 = THEME.Surface,
							Size = UDim2.new(1, 0, 0, 50),
						}, { Corner(6) })
						Reg(Registry.Surface, wrap, "BackgroundColor3")

						Create("TextLabel", {
							Parent = wrap, BackgroundTransparency = 1,
							Text = cfg.Title or "Textbox", Font = FONT_M, TextSize = 12,
							TextColor3 = THEME.Text,
							TextXAlignment = Enum.TextXAlignment.Left,
							Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(1, -20, 0, 14),
						})
						local box = Create("TextBox", {
							Parent = wrap, BackgroundColor3 = THEME.Background,
							Text = cfg.Value or "",
							PlaceholderText = cfg.Placeholder or "Nhập...",
							PlaceholderColor3 = THEME.TextDim,
							Font = FONT, TextSize = 12, TextColor3 = THEME.Text,
							TextXAlignment = Enum.TextXAlignment.Left,
							ClearTextOnFocus = false,
							Position = UDim2.new(0, 10, 0, 22),
							Size = UDim2.new(1, -20, 0, 22),
						}, { Corner(6), Stroke(THEME.Border, 1, 0.5), Pad(8, 0, 0, 0) })
						Reg(Registry.Background, box, "BackgroundColor3")

						box.Focused:Connect(function()
							Tween(box, { BackgroundColor3 = THEME.SurfaceHover }, 0.15)
							Tween(box:FindFirstChildOfClass("UIStroke"), { Color = THEME.Accent }, 0.15)
						end)
						box.FocusLost:Connect(function()
							Tween(box, { BackgroundColor3 = THEME.Background }, 0.15)
							Tween(box:FindFirstChildOfClass("UIStroke"), { Color = THEME.Border }, 0.15)
							if cfg.Callback then task.spawn(cfg.Callback, box.Text) end
						end)
						return {
							Set = function(v) box.Text = tostring(v) end,
							Get = function() return box.Text end,
						}
					end

					-- ListRow (key: value)
					function V:ListRow(cfg)
						cfg = cfg or {}
						local wrap = Create("Frame", {
							Parent = colFrame, BackgroundColor3 = THEME.Surface,
							Size = UDim2.new(1, 0, 0, 0),
							AutomaticSize = Enum.AutomaticSize.Y,
						}, { Corner(6), Pad(8, 8, 8, 8) })
						Reg(Registry.Surface, wrap, "BackgroundColor3")

						local titleLbl = Create("TextLabel", {
							Parent = wrap, BackgroundTransparency = 1,
							Text = cfg.Title or "Info", Font = FONT_B, TextSize = 12,
							TextColor3 = THEME.Text,
							TextXAlignment = Enum.TextXAlignment.Left,
							Size = UDim2.new(1, 0, 0, 16),
						})

						local list = Create("Frame", {
							Parent = wrap, BackgroundTransparency = 1,
							Position = UDim2.new(0, 0, 0, 20),
							Size = UDim2.new(1, 0, 0, 0),
							AutomaticSize = Enum.AutomaticSize.Y,
						}, {
							Create("UIListLayout", {
								SortOrder = Enum.SortOrder.LayoutOrder,
								Padding = UDim.new(0, 4),
							}),
						})

						local valueLabels = {}

						local function createRow(key, value, order)
					local row = Create("Frame", {
						Parent = list, BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 20), LayoutOrder = order,
					})

					-- Key label — bên trái, cho 45% bề rộng
					local keyLbl = Create("TextLabel", {
						Parent = row, BackgroundTransparency = 1,
						Text = tostring(key) .. ":",
						Font = FONT_M, TextSize = 11, TextColor3 = THEME.TextDim,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Size = UDim2.new(0.45, -4, 1, 0),
						Position = UDim2.new(0, 0, 0, 0),
					})

					-- Value label — bên phải, 55%
					local valLbl = Create("TextLabel", {
						Parent = row, BackgroundTransparency = 1,
						Text = tostring(value),
						Font = FONT_B, TextSize = 11, TextColor3 = THEME.Text,
						TextXAlignment = Enum.TextXAlignment.Right,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextScaled = false,
						Size = UDim2.new(0.55, -4, 1, 0),
						Position = UDim2.new(0.45, 4, 0, 0),
					})
					valueLabels[key] = valLbl
					return row
				end

						if cfg.Items then
							for i, item in ipairs(cfg.Items) do
								createRow(item.key, item.value, i)
							end
						end

						local handle = {}
						handle.Instance = wrap

						function handle:SetItems(items)
							for _, c in ipairs(list:GetChildren()) do
								if c:IsA("Frame") then c:Destroy() end
							end
							valueLabels = {}
							for i, item in ipairs(items or {}) do
								createRow(item.key, item.value, i)
							end
						end
						function handle:UpdateItem(key, value)
							local lbl = valueLabels[key]
							if lbl and lbl.Parent then
								local t = tostring(value)
								if lbl.Text ~= t then lbl.Text = t end
								return true
							end
							return false
						end
						function handle:UpdateItems(map)
							for k, v in pairs(map or {}) do
								local lbl = valueLabels[k]
								if lbl and lbl.Parent then lbl.Text = tostring(v) end
							end
						end
						function handle:SetTitle(t) titleLbl.Text = tostring(t) end
						return handle
					end

					-- ⭐ StatRow — hàng có key | value | nút +
					function V:StatRow(cfg)
						cfg = cfg or {}
						local row = Create("Frame", {
							Parent = colFrame, BackgroundColor3 = THEME.Surface,
							Size = UDim2.new(1, 0, 0, SIZE.RowH),
						}, { Corner(6) })
						Reg(Registry.Surface, row, "BackgroundColor3")

						local keyLbl = Create("TextLabel", {
							Parent = row, BackgroundTransparency = 1,
							Text = cfg.Key or "Stat",
							Font = FONT_M, TextSize = 11, TextColor3 = THEME.Text,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextTruncate = Enum.TextTruncate.AtEnd,
							Position = UDim2.new(0, 10, 0, 0),
							Size = UDim2.new(0.35, -10, 1, 0),
						})

						local valLbl = Create("TextLabel", {
							Parent = row, BackgroundTransparency = 1,
							Text = tostring(cfg.Value or "..."),
							Font = FONT_B, TextSize = 11, TextColor3 = THEME.Accent,
							TextXAlignment = Enum.TextXAlignment.Right,
							TextTruncate = Enum.TextTruncate.AtEnd,
							Position = UDim2.new(0.35, 0, 0, 0),
							Size = UDim2.new(0.65, -46, 1, 0),
						})
						Reg(Registry.Menu, valLbl, "TextColor3")

						local plusBtn = Create("TextButton", {
							Parent = row, BackgroundColor3 = THEME.Button,
							Text = "+", Font = FONT_B, TextSize = 14, TextColor3 = THEME.Text,
							Size = UDim2.fromOffset(28, 22),
							Position = UDim2.new(1, -38, 0.5, -11),
							AutoButtonColor = false,
						}, { Corner(5), Stroke(THEME.Border, 1, 0.6) })
						Reg(Registry.Button, plusBtn, "BackgroundColor3")
						AddPress(plusBtn, 0.88)
						plusBtn.MouseEnter:Connect(function()
							Tween(plusBtn, { BackgroundColor3 = THEME.ButtonHover }, 0.12)
						end)
						plusBtn.MouseLeave:Connect(function()
							Tween(plusBtn, { BackgroundColor3 = THEME.Button }, 0.12)
						end)
						plusBtn.MouseButton1Click:Connect(function()
							if cfg.OnAdd then task.spawn(cfg.OnAdd) end
						end)

						local handle = {}
						handle.Instance = row
						handle.SetValue = function(_self, v)
							-- hỗ trợ cả statMelee:SetValue(x) và statMelee.SetValue(x)
							local value = v
							if value == nil then value = _self end
							local t = tostring(value)
							if valLbl.Text ~= t then valLbl.Text = t end
						end
						handle.GetValue = function() return valLbl.Text end
						return handle
					end
					-- ⭐ Dropdown (cho TwoColumn) — FIXED
					function V:Dropdown(cfg)
						cfg = cfg or {}
						local options = cfg.Options or {}
						local isMulti = cfg.Multi == true
						local selected = isMulti and (type(cfg.Value) == "table" and cfg.Value or {}) or (cfg.Value or options[1])
						local opened = false

						local wrap = Create("Frame", {
							Parent = colFrame, BackgroundColor3 = THEME.Surface,
							Size = UDim2.new(1, 0, 0, 56), ClipsDescendants = true,
						}, { Corner(6) })
						Reg(Registry.Surface, wrap, "BackgroundColor3")

						Create("TextLabel", {
							Parent = wrap, BackgroundTransparency = 1,
							Text = cfg.Title or "Dropdown", Font = FONT_M, TextSize = 12, TextColor3 = THEME.Text,
							TextXAlignment = Enum.TextXAlignment.Left,
							Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 16),
						})
						local mainBtn = Create("TextButton", {
							Parent = wrap, BackgroundColor3 = THEME.Background,
							Text = "", Size = UDim2.new(1, -20, 0, 24),
							Position = UDim2.new(0, 10, 0, 26), AutoButtonColor = false,
						}, { Corner(6), Stroke(THEME.Border, 1, 0.5) })
						Reg(Registry.Background, mainBtn, "BackgroundColor3")

						local display = Create("TextLabel", {
							Parent = mainBtn, BackgroundTransparency = 1,
							Text = "Chọn...", Font = FONT, TextSize = 11, TextColor3 = THEME.Text,
							TextXAlignment = Enum.TextXAlignment.Left,
							Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -30, 1, 0),
						})
						local arrow = Create("TextLabel", {
							Parent = mainBtn, BackgroundTransparency = 1,
							Text = "▾", Font = FONT_B, TextSize = 12, TextColor3 = THEME.TextDim,
							Position = UDim2.new(1, -22, 0, 0), Size = UDim2.new(0, 20, 1, 0),
						})
						local listHolder = Create("Frame", {
							Parent = wrap, BackgroundTransparency = 1,
							Size = UDim2.new(1, -20, 0, 0), Position = UDim2.new(0, 10, 0, 54),
							AutomaticSize = Enum.AutomaticSize.Y,
						}, {
							Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }),
						})

						local optBtns = {}
						local function render()
							for _, b in ipairs(optBtns) do b:Destroy() end
							optBtns = {}
							for _, opt in ipairs(options) do
								local isSel = isMulti and table.find(selected, opt) or (not isMulti and selected == opt)
								local ob = Create("TextButton", {
									Parent = listHolder,
									BackgroundColor3 = isSel and THEME.AccentDark or THEME.Background,
									BackgroundTransparency = isSel and 0 or 0.5,
									Text = tostring(opt), Font = FONT, TextSize = 11, TextColor3 = THEME.Text,
									TextXAlignment = Enum.TextXAlignment.Left,
									Size = UDim2.new(1, 0, 0, 24), AutoButtonColor = false,
								}, { Corner(4), Pad(8, 0, 0, 0) })
								Reg(Registry.Background, ob, "BackgroundColor3")
								AddPress(ob, 0.97)
								table.insert(optBtns, ob)
								ob.MouseButton1Click:Connect(function()
									local chosenOption = opt
									if isMulti then
										local idx = table.find(selected, chosenOption)
										if idx then table.remove(selected, idx) else table.insert(selected, chosenOption) end
									else
										selected = chosenOption
										opened = false
									end
									render()
									if isMulti then
										local t = {}
										for _, v in ipairs(selected) do table.insert(t, tostring(v)) end
										display.Text = #t > 0 and table.concat(t, ", ") or "Chọn..."
									else
										display.Text = tostring(selected)
									end
									if cfg.Callback then task.spawn(cfg.Callback, chosenOption) end
									if not isMulti then
										Tween(arrow, { Rotation = 0 }, 0.2)
										Tween(wrap, { Size = UDim2.new(1, 0, 0, 56) }, 0.25, Enum.EasingStyle.Quart)
									end
								end)
							end
						end
						render()
						if isMulti then
							local t = {}
							for _, v in ipairs(selected) do table.insert(t, tostring(v)) end
							display.Text = #t > 0 and table.concat(t, ", ") or "Chọn..."
						else
							display.Text = tostring(selected)
						end

						mainBtn.MouseButton1Click:Connect(function()
							opened = not opened
							if opened then
								Tween(wrap, { Size = UDim2.new(1, 0, 0, 56 + #options * 26 + 6) }, 0.25, Enum.EasingStyle.Quart)
								Tween(arrow, { Rotation = 180 }, 0.25)
							else
								Tween(wrap, { Size = UDim2.new(1, 0, 0, 56) }, 0.25, Enum.EasingStyle.Quart)
								Tween(arrow, { Rotation = 0 }, 0.25)
							end
						end)
						AddPress(mainBtn, 0.98)

						-- ⭐ Handle với Refresh — KHÔNG auto-fire callback
						local handle = {}
						handle.Get = function() return selected end
						handle.GetSelected = function() return selected end
						handle.Set = function(v) selected = v; render() end

						handle.Refresh = function(newOptions, keepSelection)
							options = newOptions or options
							keepSelection = keepSelection ~= false

							if isMulti then
								if keepSelection and type(selected) == "table" then
									local kept = {}
									for _, v in ipairs(selected) do
										if table.find(options, v) then table.insert(kept, v) end
									end
									selected = kept
								else
									selected = {}
								end
							else
								if not (keepSelection and table.find(options, selected)) then
									selected = options[1]
								end
							end

							for _, b in ipairs(optBtns) do b:Destroy() end
							optBtns = {}
							render()

							if isMulti then
								local t = {}
								for _, v in ipairs(selected) do table.insert(t, tostring(v)) end
								display.Text = #t > 0 and table.concat(t, ", ") or "Chọn..."
							else
								display.Text = (selected ~= nil) and tostring(selected) or "Chọn..."
							end

							if opened then
								local newH = 56 + #options * 26 + 6
								Tween(wrap, { Size = UDim2.new(1, 0, 0, newH) }, 0.2, Enum.EasingStyle.Quart)
							end
						end

						return handle
					end
					
					-- ⭐ Paragraph (cho TwoColumn)
					function V:Paragraph(cfg)
						cfg = cfg or {}
						local wrap = Create("Frame", {
							Parent = colFrame, BackgroundColor3 = THEME.Surface, BackgroundTransparency = 0.3,
							Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
						}, { Corner(6), Stroke(THEME.Border, 1, 0.7), Pad(10, 10, 10, 10) })
						Reg(Registry.Surface, wrap, "BackgroundColor3")
						Reg(Registry.Border, wrap:FindFirstChildOfClass("UIStroke"), "Color")

						if cfg.Title then
							Create("TextLabel", {
								Parent = wrap, BackgroundTransparency = 1,
								Text = cfg.Title, Font = FONT_B, TextSize = 12, TextColor3 = THEME.Text,
								TextXAlignment = Enum.TextXAlignment.Left,
								Size = UDim2.new(1, 0, 0, 16),
							})
						end
						local contentLbl = Create("TextLabel", {
							Parent = wrap, BackgroundTransparency = 1,
							Text = cfg.Content or "", Font = FONT, TextSize = 11, TextColor3 = THEME.TextDim,
							TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
							TextWrapped = true,
							Position = cfg.Title and UDim2.new(0, 0, 0, 20) or UDim2.new(0, 0, 0, 0),
							Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LineHeight = 1.2,
						})
						return {
							SetContent = function(t) contentLbl.Text = tostring(t) end,
							SetTitle = function(t)
								contentLbl.Position = (t and t ~= "") and UDim2.new(0, 0, 0, 20) or UDim2.new(0, 0, 0, 0)
							end,
						}
					end

					return V
				end

				local Left = makeRealVirtual(leftCol)
				local Right = makeRealVirtual(rightCol)

				return { Left = Left, Right = Right, LeftFrame = leftCol, RightFrame = rightCol }
			end

			return Section
		end
		return Tab
	end
	return Window
end

return NeoUI
