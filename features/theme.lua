-- =========================================================
--  FEATURE: Theme — Đổi màu Menu / Slider / Button
--  Bao gồm: chọn màu, random, preset
-- =========================================================
return {
	Run = function(NeoUI, Tab)
		-- ===== PALETTES (giống bản cũ) =====
		local PALETTES = NeoUI.Palettes

		local function randomPaletteDiffFrom(c1, c2, c3)
			if NeoUI.RandomPalette then
				return NeoUI.RandomPalette(c1, c2, c3)
			end
			-- fallback nếu lib cũ không có
			local tries, pick = 0, nil
			repeat
				pick = PALETTES[math.random(1, #PALETTES)]
				tries = tries + 1
			until tries >= 8 or (pick.menu ~= c1 or pick.slider ~= c2 or pick.button ~= c3)
			return pick
		end

		-- ===== SECTION 1: Màu tùy chỉnh =====
		local Sec = Tab:CreateSection("🎨 Tùy Chỉnh Màu")

		Sec:Paragraph({
			Title = "Hướng dẫn",
			Content = "Chọn màu, random, hoặc dùng preset có sẵn.\nMenu: indicator, tab, loading\nSlider: thanh kéo\nButton: nút bấm.",
		})

		-- ⭐ Màu Menu (có random + preset)
		Sec:ColorRow({
			Title = "Màu Menu",
			Value = NeoUI.Theme.Accent,
			Setter = function(c) NeoUI.SetMenuColor(c) end,
			RandomFn = function()
				local p = randomPaletteDiffFrom(NeoUI.Theme.Accent, NeoUI.Theme.Slider, NeoUI.Theme.Button)
				NeoUI.SetMenuColor(p.menu)
				NeoUI.Notify:Show({ Title = "🎲 Random Menu", Description = p.name, Duration = 2 })
				return p.menu
			end,
			Presets = (function()
				local t = {}
				for _, p in ipairs(PALETTES) do
					table.insert(t, { name = p.name, color = p.menu })
				end
				return t
			end)(),
			PresetTitle = "Preset Màu Menu",
		})

		-- ⭐ Màu Slider
		Sec:ColorRow({
			Title = "Màu Thanh Kéo",
			Value = NeoUI.Theme.Slider,
			Setter = function(c) NeoUI.SetSliderColor(c) end,
			RandomFn = function()
				local p = randomPaletteDiffFrom(NeoUI.Theme.Accent, NeoUI.Theme.Slider, NeoUI.Theme.Button)
				NeoUI.SetSliderColor(p.slider)
				NeoUI.Notify:Show({ Title = "🎲 Random Slider", Description = p.name, Duration = 2 })
				return p.slider
			end,
			Presets = (function()
				local t = {}
				for _, p in ipairs(PALETTES) do
					table.insert(t, { name = p.name, color = p.slider })
				end
				return t
			end)(),
			PresetTitle = "Preset Màu Slider",
		})

		-- ⭐ Màu Button
		Sec:ColorRow({
			Title = "Màu Nút Bấm",
			Value = NeoUI.Theme.Button,
			Setter = function(c) NeoUI.SetButtonColor(c) end,
			RandomFn = function()
				local p = randomPaletteDiffFrom(NeoUI.Theme.Accent, NeoUI.Theme.Slider, NeoUI.Theme.Button)
				NeoUI.SetButtonColor(p.button)
				NeoUI.Notify:Show({ Title = "🎲 Random Button", Description = p.name, Duration = 2 })
				return p.button
			end,
			Presets = (function()
				local t = {}
				for _, p in ipairs(PALETTES) do
					table.insert(t, { name = p.name, color = p.button })
				end
				return t
			end)(),
			PresetTitle = "Preset Màu Button",
		})

		-- ===== SECTION 2: Random toàn bộ =====
		local RandSec = Tab:CreateSection("🎲 Random")

		RandSec:Button({
			Title = "🎲 Random Toàn Bộ (Menu + Slider + Button)",
			Callback = function()
				local p = randomPaletteDiffFrom(NeoUI.Theme.Accent, NeoUI.Theme.Slider, NeoUI.Theme.Button)
				NeoUI.SetMenuColor(p.menu)
				NeoUI.SetSliderColor(p.slider)
				NeoUI.SetButtonColor(p.button)
				NeoUI.Notify:Show({
					Title = "🎲 Random",
					Description = "Đã đổi sang: " .. p.name,
					Duration = 3,
				})
			end,
		})

		-- ===== SECTION 3: Preset có sẵn =====
		local PresetSec = Tab:CreateSection("🎯 Màu Có Sẵn")

		PresetSec:Paragraph({
			Title = "Bấm để đổi cả 3 nhóm cùng lúc",
			Content = "Mỗi preset sẽ đổi Menu + Slider + Button theo tông hài hòa.",
		})

		for _, p in ipairs(PALETTES) do
			PresetSec:Button({
				Title = p.name,
				Callback = function()
					NeoUI.SetMenuColor(p.menu)
					NeoUI.SetSliderColor(p.slider)
					NeoUI.SetButtonColor(p.button)
					NeoUI.Notify:Show({
						Title = "Preset",
						Description = p.name,
						Duration = 2,
					})
				end,
			})
		end

		NeoUI.Notify:Show({
			Title = "✅ Theme",
			Description = "Đã load chức năng đổi màu",
			Duration = 2,
		})
	end,
}
