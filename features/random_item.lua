-- =========================================================
--  FEATURE: Random & Shop v39
--  - Fallback dùng list ĐẦY ĐỦ dump từ game
--  - Không còn hardcode 8 item
-- =========================================================
return {
	Run = function(NeoUI, Tab)
		local Players = game:GetService("Players")
		local LP = Players.LocalPlayer
		local RS = game:GetService("ReplicatedStorage")
		local NetworkEvent = RS.Modules.NetworkFramework.NetworkEvent

		local function SafeRequire(paths)
			for _, p in ipairs(paths) do
				local ok, result = pcall(function()
					local cur = RS
					for seg in p:gmatch("[^%.]+") do
						cur = cur[seg]
						if not cur then return nil end
					end
					return require(cur)
				end)
				if ok and result then return result end
			end
			return nil
		end

		-- ⭐⭐⭐ DÁN LIST DUMP VÀO ĐÂY ⭐⭐⭐
		local FALLBACK_DIAMOND = {
			-- ⭐ AUTO-DUMPED — 2026-10-08 11:49:34
	{ name = "Bacon", price = 5 },
	{ name = "Duck", price = 5 },
	{ name = "Fish", price = 5 },
	{ name = "Iron", price = 5 },
	{ name = "Bandage", price = 10 },
	{ name = "Boxing Sandbag", price = 10 },
	{ name = "Duck2", price = 10 },
	{ name = "Dumbbell 25 KG", price = 10 },
	{ name = "Old Wood", price = 10 },
	{ name = "Orb Red", price = 10 },
	{ name = "Wood", price = 10 },
	{ name = "Black Shoes", price = 25 },
	{ name = "Boxing Gloves", price = 25 },
	{ name = "Duck3", price = 25 },
	{ name = "Iron Shark Teeth", price = 25 },
	{ name = "Old Iron", price = 25 },
	{ name = "Old Rock", price = 25 },
	{ name = "Orb Blue", price = 25 },
	{ name = "Orb Spirit", price = 25 },
	{ name = "Orb Yellow", price = 25 },
	{ name = "Vegetable", price = 25 },
	{ name = "Black Belt", price = 50 },
	{ name = "Black Iron", price = 50 },
	{ name = "Chef Hat", price = 50 },
	{ name = "Cursed Iron", price = 50 },
	{ name = "Cursed Wood", price = 50 },
	{ name = "Duck4", price = 50 },
	{ name = "Orb Boss", price = 50 },
	{ name = "Orb Dungeon", price = 50 },
	{ name = "Pipe", price = 50 },
	{ name = "Rot Banana", price = 50 },
	{ name = "Space Ticket", price = 50 },
	{ name = "Spatula", price = 50 },
	{ name = "Tomato", price = 50 },
	{ name = "Aura Blue", price = 250 },
	{ name = "Aura Brown", price = 250 },
	{ name = "Aura Orange", price = 250 },
	{ name = "Aura Purple", price = 250 },
	{ name = "Aura White", price = 250 },
	{ name = "Banana", price = 250 },
	{ name = "Book of Rokuogan", price = 250 },
	{ name = "Carrot", price = 250 },
	{ name = "Cheese", price = 250 },
	{ name = "Chicken Bone", price = 250 },
	{ name = "Chicken Nugget", price = 250 },
	{ name = "Cornstarch", price = 250 },
	{ name = "Dragon Fang", price = 250 },
	{ name = "Duck5", price = 250 },
	{ name = "Egg", price = 250 },
	{ name = "Frying Pan", price = 250 },
	{ name = "Gold", price = 250 },
	{ name = "Grains of Rice", price = 250 },
	{ name = "Holy Gold", price = 250 },
	{ name = "Holy Iron", price = 250 },
	{ name = "Holy Stone", price = 250 },
	{ name = "Holy Wood", price = 250 },
	{ name = "Orb Black", price = 250 },
	{ name = "Orb Devil", price = 250 },
	{ name = "Orb Green", price = 250 },
	{ name = "Orb Purple", price = 250 },
	{ name = "Orb Sand", price = 250 },
	{ name = "Orb Water", price = 250 },
	{ name = "Pharaoh's Staff", price = 250 },
	{ name = "Scarf Old", price = 250 },
	{ name = "Shield Hoplon", price = 250 },
	{ name = "Stopwatch", price = 250 },
	{ name = "Vegetable Oil", price = 250 },
	{ name = "Wind Stone", price = 250 },
	{ name = "Wolf Fang", price = 250 },
	{ name = "Aura Black", price = 750 },
	{ name = "Aura Green", price = 750 },
	{ name = "Aura Pink", price = 750 },
	{ name = "Aura Red", price = 750 },
	{ name = "Aura Yellow", price = 750 },
	{ name = "Bee", price = 750 },
	{ name = "Book of Busoshoku Haki", price = 750 },
	{ name = "Cake Monster", price = 750 },
	{ name = "Devil Heart", price = 750 },
	{ name = "Duck6", price = 750 },
	{ name = "Heart of Envy", price = 750 },
	{ name = "Khaw Phad Kai", price = 750 },
	{ name = "Microphone", price = 750 },
	{ name = "Orb Dragon", price = 750 },
	{ name = "Orb Fire", price = 750 },
	{ name = "Orb Fried Chicken", price = 750 },
	{ name = "Orb Rainbow", price = 750 },
	{ name = "Shadow Diary", price = 750 },
	{ name = "Shadow Iron", price = 750 },
	{ name = "Spear", price = 750 },
	{ name = "Sugar Bag", price = 750 },
	{ name = "Thompson Gun", price = 750 },
	{ name = "Trainer Notes", price = 750 },
	{ name = "Duck7", price = 850 },
	{ name = "Magic Evolution", price = 850 },
	{ name = "Aura Rainbow", price = 1250 },
}

		local FALLBACK_MOON = {
			-- Dán list Moon vào đây
		}

		-- ===== BUILD LISTS =====
		local PointItemM = SafeRequire({ "Modules.GaranteeRandomItem", "Modules.GuaranteeRandomItem" })
		local PointItemMoon = SafeRequire({ "Modules.GuaranteeEventMoon", "Modules.GuaranteeEventMoon" })

		local diamondList, moonList = {}, {}
		local diamondOptions, moonOptions = {}, {}

		-- Diamond: ưu tiên load từ game
		if PointItemM then
			print("[v39] Diamond: load từ game")
			for n, p in pairs(PointItemM) do
				table.insert(diamondList, { name = n, price = p, optStr = n .. " (" .. p .. "P)" })
			end
			table.sort(diamondList, function(a, b) 
				if a.price == b.price then return a.name < b.name end
				return a.price < b.price 
			end)
			for _, d in ipairs(diamondList) do
				table.insert(diamondOptions, d.optStr)
			end
		elseif #FALLBACK_DIAMOND > 0 then
			print("[v39] Diamond: dùng FALLBACK (", #FALLBACK_DIAMOND, "item )")
			for _, d in ipairs(FALLBACK_DIAMOND) do
				table.insert(diamondList, {
					name = d.name,
					price = d.price,
					optStr = d.name .. " (" .. d.price .. "P)",
				})
			end
			for _, d in ipairs(diamondList) do
				table.insert(diamondOptions, d.optStr)
			end
		else
			print("[v39] ⚠️ Diamond: KHÔNG có data")
		end

		-- Moon: tương tự
		if PointItemMoon then
			print("[v39] Moon: load từ game")
			for n, p in pairs(PointItemMoon) do
				table.insert(moonList, { name = n, price = p, optStr = n .. " (" .. p .. "P)" })
			end
			table.sort(moonList, function(a, b) 
				if a.price == b.price then return a.name < b.name end
				return a.price < b.price 
			end)
			for _, m in ipairs(moonList) do
				table.insert(moonOptions, m.optStr)
			end
		elseif #FALLBACK_MOON > 0 then
			print("[v39] Moon: dùng FALLBACK (", #FALLBACK_MOON, "item )")
			for _, m in ipairs(FALLBACK_MOON) do
				table.insert(moonList, {
					name = m.name,
					price = m.price,
					optStr = m.name .. " (" .. m.price .. "P)",
				})
			end
			for _, m in ipairs(moonList) do
				table.insert(moonOptions, m.optStr)
			end
		else
			print("[v39] ⚠️ Moon: KHÔNG có data")
		end

		print("[v39] ✅ Diamond:", #diamondOptions, "| Moon:", #moonOptions)

		local State = {
			running = false, mode = "x15",
			runningMoon = false, modeMoon = "x15",
			selectedItem = nil, selectedMoonItem = nil,
			autoBuy = false, autoShopMode = "Diamond",
		}

		local function BuyDiamondItem(itemName)
			if not itemName or type(itemName) ~= "string" then return end
			local point = tonumber(LP:GetAttribute("PointItem")) or 0
			local price = 0
			if PointItemM and PointItemM[itemName] then
				price = PointItemM[itemName]
			else
				-- Tìm trong diamondList
				for _, d in ipairs(diamondList) do
					if d.name == itemName then price = d.price break end
				end
			end
			if price > 0 and point < price then
				NeoUI.Notify:Show({ Title = "❌ Thiếu Point", Description = itemName .. " (" .. price .. ")", Duration = 2 })
				return
			end
			NetworkEvent:FireServer("fire", nil, "BuyGaranteeRandomItem", itemName)
			State.selectedItem = itemName
			NeoUI.Notify:Show({ Title = "✅ Mua: " .. itemName, Description = "-" .. price .. " Point", Duration = 2 })
		end

		local function BuyMoonItem(itemName)
			if not itemName or type(itemName) ~= "string" then return end
			local point = tonumber(LP:GetAttribute("MoonPoint")) or 0
			local price = 0
			if PointItemMoon and PointItemMoon[itemName] then
				price = PointItemMoon[itemName]
			else
				for _, m in ipairs(moonList) do
					if m.name == itemName then price = m.price break end
				end
			end
			if price > 0 and point < price then
				NeoUI.Notify:Show({ Title = "❌ Thiếu Moon", Description = itemName .. " (" .. price .. ")", Duration = 2 })
				return
			end
			NetworkEvent:FireServer("fire", nil, "BuyGaranteeEventMoon", itemName)
			State.selectedMoonItem = itemName
			NeoUI.Notify:Show({ Title = "✅ Mua Moon: " .. itemName, Description = "-" .. price .. " Point", Duration = 2 })
		end

		local function FindDiamondByName(query)
			if not query or query == "" then return nil end
			local q = query:lower()
			for _, d in ipairs(diamondList) do
				if d.name:lower() == q then return d end
			end
			for _, d in ipairs(diamondList) do
				if d.name:lower():find(q, 1, true) then return d end
			end
			return nil
		end

		local function FindMoonByName(query)
			if not query or query == "" then return nil end
			local q = query:lower()
			for _, m in ipairs(moonList) do
				if m.name:lower() == q then return m end
			end
			for _, m in ipairs(moonList) do
				if m.name:lower():find(q, 1, true) then return m end
			end
			return nil
		end

		local function ToggleRandom()
			State.running = not State.running
			if State.running then
				task.spawn(function()
					while State.running do
						pcall(function() NetworkEvent:FireServer("fire", nil, "RandomItem", State.mode) end)
						task.wait(0.1)
					end
				end)
			end
			NeoUI.Notify:Show({ Title = State.running and "▶️ Random ON" or "⏹️ Random OFF", Duration = 2 })
		end

		local function ToggleMoon()
			State.runningMoon = not State.runningMoon
			if State.runningMoon then
				task.spawn(function()
					while State.runningMoon do
						pcall(function() NetworkEvent:FireServer("fire", nil, "EventMoon", State.modeMoon) end)
						task.wait(0.1)
					end
				end)
			end
			NeoUI.Notify:Show({ Title = State.runningMoon and "▶️ Moon ON" or "⏹️ Moon OFF", Duration = 2 })
		end

		-- ===== QUAY =====
		local QuaySec = Tab:CreateSection("🎰 Auto Quay")
		local QuayRow = QuaySec:TwoColumn()

		QuayRow.Left:Dropdown({
			Title = "Random",
			Options = { "x5", "x10", "x15" },
			Value = "x15",
			Callback = function(v) State.mode = v end,
		})
		QuayRow.Left:Button({ Title = "▶️ Bật / Dừng", Callback = ToggleRandom })

		QuayRow.Right:Dropdown({
			Title = "Moon",
			Options = { "x5", "x10", "x15" },
			Value = "x15",
			Callback = function(v) State.modeMoon = v end,
		})
		QuayRow.Right:Button({ Title = "▶️ Bật / Dừng", Callback = ToggleMoon })

		-- ===== DIAMOND SHOP =====
		local DiamondSec = Tab:CreateSection("💎 Diamond (" .. #diamondOptions .. " item)")

		local diamondDrop = DiamondSec:Dropdown({
			Title = "Chọn Item",
			Options = diamondOptions,
			Value = nil,
			Callback = function(v)
				if v and type(v) == "string" then
					local name = v:match("^(.-) %(")
					if name then
						State.selectedItem = name
						BuyDiamondItem(name)
					end
				end
			end,
		})

		local diamondDisplayLabel = nil
		task.spawn(function()
			task.wait(1)
			if diamondDrop and diamondDrop.GetDisplayLabel then
				diamondDisplayLabel = diamondDrop:GetDisplayLabel()
			end
		end)

		local searchD = DiamondSec:Textbox({
			Title = "🔍 Nhập tên + Enter",
			Placeholder = "VD: Wood, Duck",
			Value = "",
		})

		task.spawn(function()
			task.wait(1)
			if searchD and searchD.Instance then
				searchD.Instance.FocusLost:Connect(function(enterPressed)
					if enterPressed then
						local q = searchD.Instance.Text
						if q and q ~= "" then
							local found = FindDiamondByName(q)
							if found then
								State.selectedItem = found.name
								if diamondDisplayLabel and diamondDisplayLabel.Parent then
									diamondDisplayLabel.Text = found.optStr
								elseif diamondDrop and diamondDrop.SetDisplayText then
									diamondDrop:SetDisplayText(found.optStr)
								end
								task.wait(0.1)
								if diamondDisplayLabel and diamondDisplayLabel.Parent then
									diamondDisplayLabel.Text = found.optStr
								end
								BuyDiamondItem(found.name)
								NeoUI.Notify:Show({
									Title = "✅ Mua: " .. found.name,
									Description = "-" .. found.price .. " Point",
									Duration = 3,
								})
							else
								NeoUI.Notify:Show({ Title = "❌ Không tìm thấy", Description = q, Duration = 3 })
							end
						end
					end
				end)
			end
		end)

		DiamondSec:Button({
			Title = "🔄 Mua lại",
			Callback = function()
				if State.selectedItem then BuyDiamondItem(State.selectedItem)
				else NeoUI.Notify:Show({ Title = "❌ Chưa chọn", Duration = 2 }) end
			end,
		})

		-- ===== MOON SHOP =====
		local moonDrop = nil
		local moonDisplayLabel = nil
		if #moonOptions > 0 then
			local MoonSec = Tab:CreateSection("🌙 Moon (" .. #moonOptions .. " item)")

			moonDrop = MoonSec:Dropdown({
				Title = "Chọn Item",
				Options = moonOptions,
				Value = nil,
				Callback = function(v)
					if v and type(v) == "string" then
						local name = v:match("^(.-) %(")
						if name then
							State.selectedMoonItem = name
							BuyMoonItem(name)
						end
					end
				end,
			})

			task.spawn(function()
				task.wait(1)
				if moonDrop and moonDrop.GetDisplayLabel then
					moonDisplayLabel = moonDrop:GetDisplayLabel()
				end
			end)

			local searchM = MoonSec:Textbox({
				Title = "🔍 Nhập tên + Enter",
				Placeholder = "VD: Aura",
				Value = "",
			})

			task.spawn(function()
				task.wait(1)
				if searchM and searchM.Instance then
					searchM.Instance.FocusLost:Connect(function(enterPressed)
						if enterPressed then
							local q = searchM.Instance.Text
							if q and q ~= "" then
								local found = FindMoonByName(q)
								if found then
									State.selectedMoonItem = found.name
									if moonDisplayLabel and moonDisplayLabel.Parent then
										moonDisplayLabel.Text = found.optStr
									elseif moonDrop and moonDrop.SetDisplayText then
										moonDrop:SetDisplayText(found.optStr)
									end
									task.wait(0.1)
									if moonDisplayLabel and moonDisplayLabel.Parent then
										moonDisplayLabel.Text = found.optStr
									end
									BuyMoonItem(found.name)
									NeoUI.Notify:Show({
										Title = "✅ Moon: " .. found.name,
										Description = "-" .. found.price,
										Duration = 3,
									})
								else
									NeoUI.Notify:Show({ Title = "❌ Không tìm thấy", Description = q, Duration = 3 })
								end
							end
						end
					end)
				end
			end)

			MoonSec:Button({
				Title = "🔄 Mua lại",
				Callback = function()
					if State.selectedMoonItem then BuyMoonItem(State.selectedMoonItem)
					else NeoUI.Notify:Show({ Title = "❌ Chưa chọn", Duration = 2 }) end
				end,
			})
		end

		-- ===== WATCHDOG =====
		task.spawn(function()
			while true do
				task.wait(0.2)
				pcall(function()
					if diamondDisplayLabel and diamondDisplayLabel.Parent then
						local t = diamondDisplayLabel.Text
						if type(t) == "string" and t:find("table:") then
							if State.selectedItem then
								local found
								for _, d in ipairs(diamondList) do
									if d.name == State.selectedItem then found = d break end
								end
								if found then
									diamondDisplayLabel.Text = found.optStr
								else
									diamondDisplayLabel.Text = "Chọn..."
								end
							else
								diamondDisplayLabel.Text = "Chọn..."
							end
						end
					end
					if moonDisplayLabel and moonDisplayLabel.Parent then
						local t = moonDisplayLabel.Text
						if type(t) == "string" and t:find("table:") then
							if State.selectedMoonItem then
								local found
								for _, m in ipairs(moonList) do
									if m.name == State.selectedMoonItem then found = m break end
								end
								if found then
									moonDisplayLabel.Text = found.optStr
								else
									moonDisplayLabel.Text = "Chọn..."
								end
							else
								moonDisplayLabel.Text = "Chọn..."
							end
						end
					end
				end)
			end
		end)

		-- ===== AUTO MUA =====
		local AutoSec = Tab:CreateSection("🔁 Auto Mua")

		AutoSec:Dropdown({
			Title = "Shop auto",
			Options = { "Chỉ Diamond", "Chỉ Moon", "Cả hai" },
			Value = "Chỉ Diamond",
			Callback = function(v)
				if v == "Chỉ Diamond" then State.autoShopMode = "Diamond"
				elseif v == "Chỉ Moon" then State.autoShopMode = "Moon"
				else State.autoShopMode = "Both" end
			end,
		})

		AutoSec:Toggle({
			Title = "Auto mua mỗi 3s",
			Value = false,
			Callback = function(v) State.autoBuy = v end,
		})

		task.spawn(function()
			while true do
				task.wait(3)
				if State.autoBuy then
					local mode = State.autoShopMode or "Diamond"
					if (mode == "Diamond" or mode == "Both") and State.selectedItem then
						BuyDiamondItem(State.selectedItem)
					end
					if (mode == "Moon" or mode == "Both") and State.selectedMoonItem then
						BuyMoonItem(State.selectedMoonItem)
					end
				end
			end
		end)

		NeoUI.Notify:Show({
			Title = "✅ v39 Loaded",
			Description = "Diamond: " .. #diamondOptions .. " | Moon: " .. #moonOptions,
			Duration = 5,
		})
	end,
}
