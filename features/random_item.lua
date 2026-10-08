-- =========================================================
--  FEATURE: Random & Shop v19
--  - Fix hiển thị "Đang chọn"
--  - Thêm lại search
-- =========================================================
return {
	Run = function(NeoUI, Tab)
		local Players = game:GetService("Players")
		local LP = Players.LocalPlayer
		local RS = game:GetService("ReplicatedStorage")
		local NetworkEvent = RS.Modules.NetworkFramework.NetworkEvent

		-- Load module
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
			autoShopMode = "Diamond",
		}

		-- ===== BUILD DATA =====
		local diamondList = {}
		if PointItemM then
			for name, price in pairs(PointItemM) do
				table.insert(diamondList, {
					name = name, price = price,
					optStr = name .. " (" .. price .. "P)",
				})
			end
			table.sort(diamondList, function(a, b) return a.price < b.price end)
		end

		local moonList = {}
		if PointItemMoon then
			for name, price in pairs(PointItemMoon) do
				table.insert(moonList, {
					name = name, price = price,
					optStr = name .. " (" .. price .. "P)",
				})
			end
			table.sort(moonList, function(a, b) return a.price < b.price end)
		end

		local diamondMap, allDiamondOptions = {}, {}
		for _, d in ipairs(diamondList) do
			table.insert(allDiamondOptions, d.optStr)
			diamondMap[d.optStr] = d.name
		end

		local moonMap, allMoonOptions = {}, {}
		for _, m in ipairs(moonList) do
			table.insert(allMoonOptions, m.optStr)
			moonMap[m.optStr] = m.name
		end

		-- ⭐ Filter function
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

		-- ===== RANDOM =====
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

		-- ===== MUA =====
		local function BuyDiamondItem(itemName)
			if not itemName then return false end
			local point = tonumber(LP:GetAttribute("PointItem")) or 0
			local price = PointItemM and PointItemM[itemName] or 0
			if price == 0 then
				NeoUI.Notify:Show({ Title = "❌ Không có giá: " .. itemName, Duration = 2 })
				return false
			end
			if point < price then
				NeoUI.Notify:Show({ Title = "❌ Thiếu Point", Description = itemName .. " (" .. price .. ")", Duration = 3 })
				return false
			end
			NetworkEvent:FireServer("fire", nil, "BuyGaranteeRandomItem", itemName)
			State.boughtCount = State.boughtCount + 1
			NeoUI.Notify:Show({ Title = "✅ Mua: " .. itemName, Description = "-" .. price, Duration = 2 })
			return true
		end

		local function BuyMoonItem(itemName)
			if not itemName then return false end
			local point = tonumber(LP:GetAttribute("MoonPoint")) or 0
			local price = PointItemMoon and PointItemMoon[itemName] or 0
			if price == 0 then
				NeoUI.Notify:Show({ Title = "❌ Không có giá: " .. itemName, Duration = 2 })
				return false
			end
			if point < price then
				NeoUI.Notify:Show({ Title = "❌ Thiếu Moon", Description = itemName .. " (" .. price .. ")", Duration = 3 })
				return false
			end
			NetworkEvent:FireServer("fire", nil, "BuyGaranteeEventMoon", itemName)
			State.boughtCount = State.boughtCount + 1
			NeoUI.Notify:Show({ Title = "✅ Mua Moon: " .. itemName, Description = "-" .. price, Duration = 2 })
			return true
		end

		-- ===== SECTION 1: QUAY =====
		local QuaySec = Tab:CreateSection("🎰 Auto Quay")
		local QuayRow = QuaySec:TwoColumn()

		local RandomInfo = QuayRow.Left:ListRow({
			Title = "🎰 Random",
			Items = {
				{ key = "Status", value = "❌ Dừng" },
				{ key = "Mốc", value = "x15" },
				{ key = "Quay", value = "0" },
				{ key = "Diamond", value = "N/A" },
			},
		})
		QuayRow.Left:Textbox({
			Title = "Mốc (5/10/15)", Placeholder = "15", Value = "15",
			Callback = function(v)
				local n = tonumber(v) or 15
				if n == 5 then State.mode = "x5"
				elseif n == 10 then State.mode = "x10"
				else State.mode = "x15" end
			end,
		})
		QuayRow.Left:Button({ Title = "▶️ Bật / ⏹️ Dừng", Callback = ToggleRandom })

		local MoonInfo = QuayRow.Right:ListRow({
			Title = "🌙 Event Moon",
			Items = {
				{ key = "Status", value = "❌ Dừng" },
				{ key = "Mốc", value = "x15" },
				{ key = "Quay", value = "0" },
				{ key = "Moon", value = "N/A" },
			},
		})
		QuayRow.Right:Textbox({
			Title = "Mốc (5/10/15)", Placeholder = "15", Value = "15",
			Callback = function(v)
				local n = tonumber(v) or 15
				if n == 5 then State.modeMoon = "x5"
				elseif n == 10 then State.modeMoon = "x10"
				else State.modeMoon = "x15" end
			end,
		})
		QuayRow.Right:Button({ Title = "▶️ Bật / ⏹️ Dừng", Callback = ToggleMoon })

		-- ===== SECTION 2: SHOP DIAMOND =====
		local DiamondSec = Tab:CreateSection("💎 Diamond Shop")

		local DiamondInfo = DiamondSec:ListRow({
			Title = "Info",
			Items = {
				{ key = "Chọn", value = "-" },
				{ key = "Point", value = "N/A" },
				{ key = "Đã mua", value = "0" },
				{ key = "Tổng", value = tostring(#allDiamondOptions) },
			},
		})

		-- ⭐ Ô SEARCH
		local searchDiamondBox = DiamondSec:Textbox({
			Title = "🔍 Tìm kiếm",
			Placeholder = "VD: Duck, Wood...",
			Value = "",
			Callback = function(v)
				State.searchDiamond = v or ""
			end,
		})

		local diamondDropdown = nil
		if #allDiamondOptions > 0 then
			diamondDropdown = DiamondSec:Dropdown({
				Title = "Chọn Item",
				Options = allDiamondOptions,
				Value = nil,
				Callback = function(v)
					if v and type(v) == "string" then
						local itemName = diamondMap[v]
						if itemName then
							State.selectedItem = itemName
							BuyDiamondItem(itemName)
						else
							print("[Shop] Không map được:", v)
						end
					end
				end,
			})
		end

		DiamondSec:Button({
			Title = "🔄 Mua lại",
			Callback = function()
				if State.selectedItem then BuyDiamondItem(State.selectedItem)
				else NeoUI.Notify:Show({ Title = "❌ Chưa chọn", Duration = 2 }) end
			end,
		})

		-- ===== SECTION 3: SHOP MOON =====
		if #allMoonOptions > 0 then
			local MoonSec = Tab:CreateSection("🌙 Moon Shop")

			local MoonShopInfo = MoonSec:ListRow({
				Title = "Info",
				Items = {
					{ key = "Chọn", value = "-" },
					{ key = "Moon", value = "N/A" },
					{ key = "Tổng", value = tostring(#allMoonOptions) },
				},
			})

			-- ⭐ Ô SEARCH Moon
			local searchMoonBox = MoonSec:Textbox({
				Title = "🔍 Tìm kiếm",
				Placeholder = "VD: Aura, Nuke...",
				Value = "",
				Callback = function(v)
					State.searchMoon = v or ""
				end,
			})

			local moonDropdown = MoonSec:Dropdown({
				Title = "Chọn Item",
				Options = allMoonOptions,
				Value = nil,
				Callback = function(v)
					if v and type(v) == "string" then
						local itemName = moonMap[v]
						if itemName then
							State.selectedMoonItem = itemName
							BuyMoonItem(itemName)
						else
							print("[Shop] Không map được:", v)
						end
					end
				end,
			})

			MoonSec:Button({
				Title = "🔄 Mua lại",
				Callback = function()
					if State.selectedMoonItem then BuyMoonItem(State.selectedMoonItem)
					else NeoUI.Notify:Show({ Title = "❌ Chưa chọn", Duration = 2 }) end
				end,
			})

			-- ⭐ Search loop cho Moon
			task.spawn(function()
				local lastFilter = ""
				while true do
					task.wait(0.5)
					if moonDropdown and moonDropdown.Refresh then
						local filtered = FilterOptions(allMoonOptions, State.searchMoon or "")
						local key = table.concat(filtered, "|")
						if key ~= lastFilter then
							lastFilter = key
							if #filtered > 0 then
								moonDropdown:Refresh(filtered, true)
							end
						end
					end
				end
			end)
		end

		-- ⭐ Search loop cho Diamond
		task.spawn(function()
			local lastFilter = ""
			while true do
				task.wait(0.5)
				if diamondDropdown and diamondDropdown.Refresh then
					local filtered = FilterOptions(allDiamondOptions, State.searchDiamond or "")
					local key = table.concat(filtered, "|")
					if key ~= lastFilter then
						lastFilter = key
						if #filtered > 0 then
							diamondDropdown:Refresh(filtered, true)
						end
					end
				end
			end
		end)

		-- ===== SECTION 4: AUTO =====
		local AutoSec = Tab:CreateSection("🔁 Auto Mua")

		AutoSec:Dropdown({
			Title = "Chọn shop auto",
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

					RandomInfo:UpdateItem("Status", State.running and "✅ Chạy" or "❌ Dừng")
					RandomInfo:UpdateItem("Mốc", State.mode)
					RandomInfo:UpdateItem("Quay", tostring(State.count))
					RandomInfo:UpdateItem("Diamond", tostring(math.floor(diamond)))

					MoonInfo:UpdateItem("Status", State.runningMoon and "✅ Chạy" or "❌ Dừng")
					MoonInfo:UpdateItem("Mốc", State.modeMoon)
					MoonInfo:UpdateItem("Quay", tostring(State.countMoon))
					MoonInfo:UpdateItem("Moon", tostring(moonPoint))

					DiamondInfo:UpdateItem("Chọn", State.selectedItem or "-")
					DiamondInfo:UpdateItem("Point", tostring(pointItem))
					DiamondInfo:UpdateItem("Đã mua", tostring(State.boughtCount))
				end)
			end
		end)

		NeoUI.Notify:Show({
			Title = "✅ Random & Shop v19",
			Description = "Có search + fixed UI",
			Duration = 3,
		})
	end,
}
