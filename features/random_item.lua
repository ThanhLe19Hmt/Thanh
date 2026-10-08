-- =========================================================
--  FEATURE: Random & Shop v41
--  + Gộp Tìm + Gợi ý (gõ → dropdown filter)
--  + Fix Shop Moon (thử nhiều path)
--  + Fix dropdown vượt khung
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

		-- ⭐⭐ THỬ NHIỀU PATH MOON
		local PointItemM = SafeRequire({ "Modules.GaranteeRandomItem", "Modules.GuaranteeRandomItem" })
		local PointItemMoon = SafeRequire({
			"Modules.GuaranteeEventMoon",
			"Modules.GaranteeEventMoon",
			"Modules.EventMoonGuarantee",
			"Modules.MoonGuarantee",
			"Modules.GuaranteeItemMoon",
			"Modules.EventMoon",
			"Modules.MoonItem",
		})

		local FALLBACK_DIAMOND = {
			{ name = "Bacon", price = 5 }, { name = "Duck", price = 5 },
			{ name = "Fish", price = 5 }, { name = "Iron", price = 5 },
			{ name = "Bandage", price = 10 }, { name = "Boxing Sandbag", price = 10 },
			{ name = "Duck2", price = 10 }, { name = "Dumbbell 25 KG", price = 10 },
			{ name = "Old Wood", price = 10 }, { name = "Orb Red", price = 10 },
			{ name = "Wood", price = 10 }, { name = "Black Shoes", price = 25 },
			{ name = "Boxing Gloves", price = 25 }, { name = "Duck3", price = 25 },
			{ name = "Iron Shark Teeth", price = 25 }, { name = "Old Iron", price = 25 },
			{ name = "Old Rock", price = 25 }, { name = "Orb Blue", price = 25 },
			{ name = "Orb Spirit", price = 25 }, { name = "Orb Yellow", price = 25 },
			{ name = "Vegetable", price = 25 }, { name = "Black Belt", price = 50 },
			{ name = "Black Iron", price = 50 }, { name = "Chef Hat", price = 50 },
			{ name = "Cursed Iron", price = 50 }, { name = "Cursed Wood", price = 50 },
			{ name = "Duck4", price = 50 }, { name = "Orb Boss", price = 50 },
			{ name = "Orb Dungeon", price = 50 }, { name = "Pipe", price = 50 },
			{ name = "Rot Banana", price = 50 }, { name = "Space Ticket", price = 50 },
			{ name = "Spatula", price = 50 }, { name = "Tomato", price = 50 },
			{ name = "Aura Blue", price = 250 }, { name = "Aura Brown", price = 250 },
			{ name = "Aura Orange", price = 250 }, { name = "Aura Purple", price = 250 },
			{ name = "Aura White", price = 250 }, { name = "Banana", price = 250 },
			{ name = "Book of Rokuogan", price = 250 }, { name = "Carrot", price = 250 },
			{ name = "Cheese", price = 250 }, { name = "Chicken Bone", price = 250 },
			{ name = "Chicken Nugget", price = 250 }, { name = "Cornstarch", price = 250 },
			{ name = "Dragon Fang", price = 250 }, { name = "Duck5", price = 250 },
			{ name = "Egg", price = 250 }, { name = "Frying Pan", price = 250 },
			{ name = "Gold", price = 250 }, { name = "Grains of Rice", price = 250 },
			{ name = "Holy Gold", price = 250 }, { name = "Holy Iron", price = 250 },
			{ name = "Holy Stone", price = 250 }, { name = "Holy Wood", price = 250 },
			{ name = "Orb Black", price = 250 }, { name = "Orb Devil", price = 250 },
			{ name = "Orb Green", price = 250 }, { name = "Orb Purple", price = 250 },
			{ name = "Orb Sand", price = 250 }, { name = "Orb Water", price = 250 },
			{ name = "Pharaoh's Staff", price = 250 }, { name = "Scarf Old", price = 250 },
			{ name = "Shield Hoplon", price = 250 }, { name = "Stopwatch", price = 250 },
			{ name = "Vegetable Oil", price = 250 }, { name = "Wind Stone", price = 250 },
			{ name = "Wolf Fang", price = 250 }, { name = "Aura Black", price = 750 },
			{ name = "Aura Green", price = 750 }, { name = "Aura Pink", price = 750 },
			{ name = "Aura Red", price = 750 }, { name = "Aura Yellow", price = 750 },
			{ name = "Bee", price = 750 }, { name = "Book of Busoshoku Haki", price = 750 },
			{ name = "Cake Monster", price = 750 }, { name = "Devil Heart", price = 750 },
			{ name = "Duck6", price = 750 }, { name = "Heart of Envy", price = 750 },
			{ name = "Khaw Phad Kai", price = 750 }, { name = "Microphone", price = 750 },
			{ name = "Orb Dragon", price = 750 }, { name = "Orb Fire", price = 750 },
			{ name = "Orb Fried Chicken", price = 750 }, { name = "Orb Rainbow", price = 750 },
			{ name = "Shadow Diary", price = 750 }, { name = "Shadow Iron", price = 750 },
			{ name = "Spear", price = 750 }, { name = "Sugar Bag", price = 750 },
			{ name = "Thompson Gun", price = 750 }, { name = "Trainer Notes", price = 750 },
			{ name = "Duck7", price = 850 }, { name = "Magic Evolution", price = 850 },
			{ name = "Aura Rainbow", price = 1250 },
		}

		local FALLBACK_MOON = {
			-- Nếu có list Moon, dán vào đây
		}

		local diamondList, moonList = {}, {}
		local diamondOptions, moonOptions = {}, {}

		-- Build Diamond
		if PointItemM then
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
			for _, d in ipairs(FALLBACK_DIAMOND) do
				table.insert(diamondList, {
					name = d.name, price = d.price,
					optStr = d.name .. " (" .. d.price .. "P)",
				})
			end
			for _, d in ipairs(diamondList) do
				table.insert(diamondOptions, d.optStr)
			end
		end

		-- Build Moon
		if PointItemMoon then
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
			for _, m in ipairs(FALLBACK_MOON) do
				table.insert(moonList, {
					name = m.name, price = m.price,
					optStr = m.name .. " (" .. m.price .. "P)",
				})
			end
			for _, m in ipairs(moonList) do
				table.insert(moonOptions, m.optStr)
			end
		end

		print("[v41] Diamond: " .. #diamondOptions .. " | Moon: " .. #moonOptions)
		if #moonOptions == 0 then
			print("[v41] Moon module chưa tìm thấy — chạy test tìm module Moon")
		end

		-- ⭐ Normalize tên
		local function NormalizeName(s)
			return tostring(s):lower():gsub("[%s_%-]", "")
		end

		local function FindDiamondByName(query)
			if not query or query == "" then return nil end
			local qNorm = NormalizeName(query)
			for _, d in ipairs(diamondList) do
				if NormalizeName(d.name) == qNorm then return d end
			end
			for _, d in ipairs(diamondList) do
				if NormalizeName(d.name):find(qNorm, 1, true) then return d end
			end
			return nil
		end

		local function FindMoonByName(query)
			if not query or query == "" then return nil end
			local qNorm = NormalizeName(query)
			for _, m in ipairs(moonList) do
				if NormalizeName(m.name) == qNorm then return m end
			end
			for _, m in ipairs(moonList) do
				if NormalizeName(m.name):find(qNorm, 1, true) then return m end
			end
			return nil
		end

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
			for _, d in ipairs(diamondList) do
				if d.name == itemName then price = d.price break end
			end
			if price > 0 and point < price then
				NeoUI.Notify:Show({ Title = "Thiếu Point", Description = itemName .. " (" .. price .. ")", Duration = 2 })
				return
			end
			NetworkEvent:FireServer("fire", nil, "BuyGaranteeRandomItem", itemName)
			State.selectedItem = itemName
			NeoUI.Notify:Show({ Title = "Đã mua: " .. itemName, Description = "-" .. price .. " Point", Duration = 2 })
		end

		local function BuyMoonItem(itemName)
			if not itemName or type(itemName) ~= "string" then return end
			local point = tonumber(LP:GetAttribute("MoonPoint")) or 0
			local price = 0
			for _, m in ipairs(moonList) do
				if m.name == itemName then price = m.price break end
			end
			if price > 0 and point < price then
				NeoUI.Notify:Show({ Title = "Thiếu Moon", Description = itemName .. " (" .. price .. ")", Duration = 2 })
				return
			end
			NetworkEvent:FireServer("fire", nil, "BuyGaranteeEventMoon", itemName)
			State.selectedMoonItem = itemName
			NeoUI.Notify:Show({ Title = "Đã mua Moon: " .. itemName, Description = "-" .. price .. " Point", Duration = 2 })
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
			NeoUI.Notify:Show({ Title = State.running and "Random ON" or "Random OFF", Duration = 2 })
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
			NeoUI.Notify:Show({ Title = State.runningMoon and "Moon ON" or "Moon OFF", Duration = 2 })
		end

		-- =======================================================
		--  QUAY
		-- =======================================================
		local QuaySec = Tab:CreateSection("Auto Quay")
		local QuayRow = QuaySec:TwoColumn()

		QuayRow.Left:Dropdown({
			Title = "Random",
			Options = { "x5", "x10", "x15" },
			Value = "x15",
			Callback = function(v) State.mode = v end,
		})
		QuayRow.Left:Button({ Title = "Bật / Dừng", Callback = ToggleRandom })

		QuayRow.Right:Dropdown({
			Title = "Event Moon",
			Options = { "x5", "x10", "x15" },
			Value = "x15",
			Callback = function(v) State.modeMoon = v end,
		})
		QuayRow.Right:Button({ Title = "Bật / Dừng", Callback = ToggleMoon })

		-- =======================================================
		--  SHOP (Diamond trái + Moon phải)
		-- =======================================================
		local ShopSec = Tab:CreateSection("Shop")
		local ShopRow = ShopSec:TwoColumn()

		-- ===== DIAMOND SHOP =====
		local diamondDrop = ShopRow.Left:Dropdown({
			Title = "Diamond",
			Options = diamondOptions,
			Value = nil,
			Callback = function(v)
				if v and type(v) == "string" then
					local name = v:match("^(.-) %(")
					if name then
						State.selectedItem = name
						print("[v41] Diamond chọn:", name)
					end
				end
			end,
		})

		-- ⭐⭐ Ô TÌM GỘP — nhập xong filter dropdown luôn
		local searchD = ShopRow.Left:Textbox({
			Title = "Tìm (nhập để lọc)",
			Placeholder = "VD: orb, duck, wood",
			Value = "",
			Callback = function(v)
				local q = v or ""
				if diamondDrop and diamondDrop.Refresh then
					if q == "" then
						diamondDrop:Refresh(diamondOptions, true)
					else
						local qNorm = NormalizeName(q)
						local filt = {}
						for _, d in ipairs(diamondList) do
							if NormalizeName(d.name):find(qNorm, 1, true) then
								table.insert(filt, d.optStr)
							end
						end
						if #filt > 0 then
							diamondDrop:Refresh(filt, true)
						end
					end
				end
			end,
		})

		ShopRow.Left:Button({
			Title = "MUA 1 LẦN",
			Callback = function()
				if State.selectedItem then
					BuyDiamondItem(State.selectedItem)
				else
					NeoUI.Notify:Show({ Title = "Chưa chọn item", Duration = 2 })
				end
			end,
		})

		-- ===== MOON SHOP =====
		if #moonOptions > 0 then
			local moonDrop = ShopRow.Right:Dropdown({
				Title = "Moon",
				Options = moonOptions,
				Value = nil,
				Callback = function(v)
					if v and type(v) == "string" then
						local name = v:match("^(.-) %(")
						if name then
							State.selectedMoonItem = name
							print("[v41] Moon chọn:", name)
						end
					end
				end,
			})

			local searchM = ShopRow.Right:Textbox({
				Title = "Tìm (nhập để lọc)",
				Placeholder = "VD: aura",
				Value = "",
				Callback = function(v)
					local q = v or ""
					if moonDrop and moonDrop.Refresh then
						if q == "" then
							moonDrop:Refresh(moonOptions, true)
						else
							local qNorm = NormalizeName(q)
							local filt = {}
							for _, m in ipairs(moonList) do
								if NormalizeName(m.name):find(qNorm, 1, true) then
									table.insert(filt, m.optStr)
								end
							end
							if #filt > 0 then
								moonDrop:Refresh(filt, true)
							end
						end
					end
				end,
			})

			ShopRow.Right:Button({
				Title = "MUA 1 LẦN",
				Callback = function()
					if State.selectedMoonItem then
						BuyMoonItem(State.selectedMoonItem)
					else
						NeoUI.Notify:Show({ Title = "Chưa chọn item", Duration = 2 })
					end
				end,
			})
		else
			local MoonNotice = ShopRow.Right:ListRow({
				Title = "Moon",
				Items = { { key = "Trạng thái", value = "Chưa load module" } },
			})
		end

		-- =======================================================
		--  AUTO MUA
		-- =======================================================
		local AutoSec = Tab:CreateSection("Auto Mua")

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
			Title = "v41 Loaded",
			Description = "Diamond: " .. #diamondOptions .. " | Moon: " .. #moonOptions,
			Duration = 5,
		})
	end,
}
