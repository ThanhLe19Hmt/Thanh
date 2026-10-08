-- =========================================================
--  FEATURE: Random & Shop v16
--  + Thanh tìm kiếm cho cả 2 shop
--  + Auto Buy thông minh (chọn shop)
-- =========================================================
return {
	Run = function(NeoUI, Tab)
		local Players = game:GetService("Players")
		local LP = Players.LocalPlayer
		local RS = game:GetService("ReplicatedStorage")
		local NetworkEvent = RS.Modules.NetworkFramework.NetworkEvent

		-- ⭐ Load module an toàn
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

		local PointItemM = SafeRequire({
			"Modules.GaranteeRandomItem",
			"Modules.GuaranteeRandomItem",
		})
		local PointItemMoon = SafeRequire({
			"Modules.GuaranteeEventMoon",
			"Modules.GaranteeEventMoon",
		})

		-- ===== STATE =====
		local State = {
			running = false, mode = "x15", count = 0,
			runningMoon = false, modeMoon = "x15", countMoon = 0,
			selectedItem = nil, selectedMoonItem = nil,
			autoBuy = false, boughtCount = 0,
			autoShopMode = "Diamond",  -- "Diamond" / "Moon" / "Both"
			searchDiamond = "",
			searchMoon = "",
		}

		-- ===== BUILD DATA =====
		local allDiamondOptions = {}
		local diamondMap = {}
		if PointItemM then
			local list = {}
			for name, price in pairs(PointItemM) do
				table.insert(list, { name = name, price = price })
			end
			table.sort(list, function(a, b) return a.price < b.price end)
			for _, d in ipairs(list) do
				local optStr = d.name .. " (" .. d.price .. "P)"
				table.insert(allDiamondOptions, optStr)
				diamondMap[optStr] = d.name
			end
		end

		local allMoonOptions = {}
		local moonMap = {}
		if PointItemMoon then
			local list = {}
			for name, price in pairs(PointItemMoon) do
				table.insert(list, { name = name, price = price })
			end
			table.sort(list, function(a, b) return a.price < b.price end)
			for _, m in ipairs(list) do
				local optStr = m.name .. " (" .. m.price .. "P)"
				table.insert(allMoonOptions, optStr)
				moonMap[optStr] = m.name
			end
		end

		-- ⭐ Filter theo search
		local function FilterOptions(allOptions, query)
			if not query or query == "" then return allOptions end
			local q = query:lower()
			local result = {}
			for _, opt in ipairs(allOptions) do
				if opt:lower():find(q, 1, true) then
					table.insert(result, opt)
				end
			end
			return result
		end

		-- ===== RANDOM CHEST =====
		local function ToggleRandom()
			if State.running then
				State.running = false
				NeoUI.Notify:Show({ Title = "⏹️ Dừng Random", Duration = 2 })
				return
			end
			State.running = true
			State.count = 0
			NeoUI.Notify:Show({ Title = "▶️ Random " .. State.mode, Duration = 2 })
			task.spawn(function()
				while State.running do
					pcall(function()
						NetworkEvent:FireServer("fire", nil, "RandomItem", State.mode)
						State.count = State.count + 1
					end)
					task.wait(0.1)
				end
			end)
		end

		-- ===== EVENT MOON =====
		local function ToggleMoon()
			if State.runningMoon then
				State.runningMoon = false
				NeoUI.Notify:Show({ Title = "⏹️ Dừng Moon", Duration = 2 })
				return
			end
			State.runningMoon = true
			State.countMoon = 0
			NeoUI.Notify:Show({ Title = "▶️ Moon " .. State.modeMoon, Duration = 2 })
			task.spawn(function()
				while State.runningMoon do
					pcall(function()
						NetworkEvent:FireServer("fire", nil, "EventMoon", State.modeMoon)
						State.countMoon = State.countMoon + 1
					end)
					task.wait(0.1)
				end
			end)
		end

		-- ===== MUA ITEM =====
		local function BuyDiamondItem(itemName)
			if not itemName then return false end
			local point = tonumber(LP:GetAttribute("PointItem")) or 0
			local price = (PointItemM and PointItemM[itemName]) or 0
			if price == 0 then
				NeoUI.Notify:Show({ Title = "❌ Không có giá: " .. itemName, Duration = 2 })
				return false
			end
			if point < price then
				NeoUI.Notify:Show({
					Title = "❌ Thiếu Point",
					Description = "Cần " .. price .. " / Có " .. point,
					Duration = 3,
				})
				return false
			end
			NetworkEvent:FireServer("fire", nil, "BuyGaranteeRandomItem", itemName)
			State.boughtCount = State.boughtCount + 1
			NeoUI.Notify:Show({
				Title = "✅ Mua: " .. itemName,
				Description = "-" .. price .. " Point",
				Duration = 2,
			})
			return true
		end

		local function BuyMoonItem(itemName)
			if not itemName then return false end
			local point = tonumber(LP:GetAttribute("MoonPoint")) or 0
			local price = (PointItemMoon and PointItemMoon[itemName]) or 0
			if price == 0 then
				NeoUI.Notify:Show({ Title = "❌ Không có giá: " .. itemName, Duration = 2 })
				return false
			end
			if point < price then
				NeoUI.Notify:Show({
					Title = "❌ Thiếu Moon Point",
					Description = "Cần " .. price .. " / Có " .. point,
					Duration = 3,
				})
				return false
			end
			NetworkEvent:FireServer("fire", nil, "BuyGaranteeEventMoon", itemName)
			State.boughtCount = State.boughtCount + 1
			NeoUI.Notify:Show({
				Title = "✅ Mua Moon: " .. itemName,
				Description = "-" .. price .. " Point",
				Duration = 2,
			})
			return true
		end

		-- ===== SECTION 1: QUAY =====
		local QuaySec = Tab:CreateSection("🎰 Auto Quay")
		local QuayRow = QuaySec:TwoColumn()

		-- TRÁI: RANDOM
		local RandomInfo = QuayRow.Left:ListRow({
			Title = "🎰 Random",
			Items = {
				{ key = "Trạng thái", value = "❌ Dừng" },
				{ key = "Mốc", value = "x15" },
				{ key = "Đã quay", value = "0" },
				{ key = "Diamond", value = "N/A" },
			},
		})

		QuayRow.Left:Textbox({
			Title = "Mốc (5/10/15)",
			Placeholder = "15",
			Value = "15",
			Callback = function(v)
				local n = tonumber(v) or 15
				if n == 5 then State.mode = "x5"
				elseif n == 10 then State.mode = "x10"
				else State.mode = "x15" end
			end,
		})

		QuayRow.Left:Button({
			Title = "▶️ Bật / ⏹️ Dừng",
			Callback = ToggleRandom,
		})

		-- PHẢI: MOON
		local MoonInfo = QuayRow.Right:ListRow({
			Title = "🌙 Event Moon",
			Items = {
				{ key = "Trạng thái", value = "❌ Dừng" },
				{ key = "Mốc", value = "x15" },
				{ key = "Đã quay", value = "0" },
				{ key = "MoonPoint", value = "N/A" },
			},
		})

		QuayRow.Right:Textbox({
			Title = "Mốc (5/10/15)",
			Placeholder = "15",
			Value = "15",
			Callback = function(v)
				local n = tonumber(v) or 15
				if n == 5 then State.modeMoon = "x5"
				elseif n == 10 then State.modeMoon = "x10"
				else State.modeMoon = "x15" end
			end,
		})

		QuayRow.Right:Button({
			Title = "▶️ Bật / ⏹️ Dừng",
			Callback = ToggleMoon,
		})

		-- ===== SECTION 2: SHOP =====
		local ShopSec = Tab:CreateSection("🛒 Shop Item")
		local ShopRow = ShopSec:TwoColumn()

		-- ⭐ TRÁI: DIAMOND
		local DiamondInfo = ShopRow.Left:ListRow({
			Title = "💎 Diamond",
			Items = {
				{ key = "Đang chọn", value = "-" },
				{ key = "PointItem", value = "N/A" },
				{ key = "Đã mua", value = "0" },
			},
		})

		-- ⭐ Ô tìm kiếm Diamond
		local searchDiamondBox = ShopRow.Left:Textbox({
			Title = "🔍 Tìm item",
			Placeholder = "VD: Duck, Bacon...",
			Value = "",
			Callback = function(v)
				State.searchDiamond = v
			end,
		})

		-- Dropdown Diamond
		local diamondDropdown = nil
		if #allDiamondOptions > 0 then
			diamondDropdown = ShopRow.Left:Dropdown({
				Title = "Chọn Item",
				Options = allDiamondOptions,
				Value = nil,
				Callback = function(v)
					if v and type(v) == "string" then
						local itemName = diamondMap[v]
						if itemName then
							State.selectedItem = itemName
							BuyDiamondItem(itemName)
						end
					end
				end,
			})
		end

		ShopRow.Left:Button({
			Title = "🔄 Mua lại Diamond",
			Callback = function()
				if State.selectedItem then
					BuyDiamondItem(State.selectedItem)
				else
					NeoUI.Notify:Show({ Title = "❌ Chưa chọn", Duration = 2 })
				end
			end,
		})

		-- PHẢI: MOON
		local MoonShopInfo = ShopRow.Right:ListRow({
			Title = "🌙 Moon",
			Items = {
				{ key = "Đang chọn", value = "-" },
				{ key = "MoonPoint", value = "N/A" },
				{ key = "Số item", value = tostring(#allMoonOptions) },
			},
		})

		-- ⭐ Ô tìm kiếm Moon
		local searchMoonBox = ShopRow.Right:Textbox({
			Title = "🔍 Tìm item",
			Placeholder = "VD: Aura, Nuke...",
			Value = "",
			Callback = function(v)
				State.searchMoon = v
			end,
		})

		local moonDropdown = nil
		if #allMoonOptions > 0 then
			moonDropdown = ShopRow.Right:Dropdown({
				Title = "Chọn Item",
				Options = allMoonOptions,
				Value = nil,
				Callback = function(v)
					if v and type(v) == "string" then
						local itemName = moonMap[v]
						if itemName then
							State.selectedMoonItem = itemName
							BuyMoonItem(itemName)
						end
					end
				end,
			})
		end

		ShopRow.Right:Button({
			Title = "🔄 Mua lại Moon",
			Callback = function()
				if State.selectedMoonItem then
					BuyMoonItem(State.selectedMoonItem)
				else
					NeoUI.Notify:Show({ Title = "❌ Chưa chọn", Duration = 2 })
				end
			end,
		})

		-- ===== LOOP FILTER SEARCH =====
		task.spawn(function()
			local lastDiamondFilter = ""
			local lastMoonFilter = ""
			while true do
				task.wait(0.5)
				-- Filter Diamond
				if diamondDropdown and diamondDropdown.Refresh then
					local filtered = FilterOptions(allDiamondOptions, State.searchDiamond)
					local key = table.concat(filtered, "|")
					if key ~= lastDiamondFilter then
						lastDiamondFilter = key
						if #filtered > 0 then
							diamondDropdown:Refresh(filtered, false)
						end
					end
				end
				-- Filter Moon
				if moonDropdown and moonDropdown.Refresh then
					local filtered = FilterOptions(allMoonOptions, State.searchMoon)
					local key = table.concat(filtered, "|")
					if key ~= lastMoonFilter then
						lastMoonFilter = key
						if #filtered > 0 then
							moonDropdown:Refresh(filtered, false)
						end
					end
				end
			end
		end)

		-- ===== SECTION 3: AUTO BUY =====
		local AutoSec = Tab:CreateSection("🔁 Auto Mua")

		AutoSec:Dropdown({
			Title = "Chọn shop auto",
			Options = { "Chỉ Diamond", "Chỉ Moon", "Cả hai" },
			Value = "Chỉ Diamond",
			Callback = function(v)
				if v == "Chỉ Diamond" then
					State.autoShopMode = "Diamond"
				elseif v == "Chỉ Moon" then
					State.autoShopMode = "Moon"
				else
					State.autoShopMode = "Both"
				end
			end,
		})

		AutoSec:Toggle({
			Title = "Auto mua mỗi 3s",
			Value = false,
			Callback = function(v)
				State.autoBuy = v
				NeoUI.Notify:Show({
					Title = v and "✅ Auto Buy ON" or "❌ Auto Buy OFF",
					Description = v and ("Shop: " .. State.autoShopMode) or "",
					Duration = 2,
				})
			end,
		})

		-- ⭐ AUTO BUY THÔNG MINH
		task.spawn(function()
			while true do
				task.wait(3)
				if State.autoBuy then
					local mode = State.autoShopMode
					if (mode == "Diamond" or mode == "Both") and State.selectedItem then
						BuyDiamondItem(State.selectedItem)
					end
					if (mode == "Moon" or mode == "Both") and State.selectedMoonItem then
						BuyMoonItem(State.selectedMoonItem)
					end
				end
			end
		end)

		-- ===== REFRESH =====
		task.spawn(function()
			task.wait(1)
			while true do
				task.wait(1)
				pcall(function()
					local diamond = LP:GetAttribute("Diamond") or 0
					local pointItem = LP:GetAttribute("PointItem") or 0
					local moonPoint = LP:GetAttribute("MoonPoint") or 0

					RandomInfo:UpdateItem("Trạng thái", State.running and "✅ Chạy" or "❌ Dừng")
					RandomInfo:UpdateItem("Mốc", State.mode)
					RandomInfo:UpdateItem("Đã quay", tostring(State.count))
					RandomInfo:UpdateItem("Diamond", tostring(math.floor(diamond)))

					MoonInfo:UpdateItem("Trạng thái", State.runningMoon and "✅ Chạy" or "❌ Dừng")
					MoonInfo:UpdateItem("Mốc", State.modeMoon)
					MoonInfo:UpdateItem("Đã quay", tostring(State.countMoon))
					MoonInfo:UpdateItem("MoonPoint", tostring(moonPoint))

					DiamondInfo:UpdateItem("Đang chọn", State.selectedItem or "-")
					DiamondInfo:UpdateItem("PointItem", tostring(pointItem))
					DiamondInfo:UpdateItem("Đã mua", tostring(State.boughtCount))

					MoonShopInfo:UpdateItem("Đang chọn", State.selectedMoonItem or "-")
					MoonShopInfo:UpdateItem("MoonPoint", tostring(moonPoint))
				end)
			end
		end)

		NeoUI.Notify:Show({
			Title = "✅ Random & Shop v16",
			Description = "Có search + auto chọn shop",
			Duration = 3,
		})
	end,
}
