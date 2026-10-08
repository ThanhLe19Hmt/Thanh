-- =========================================================
--  FEATURE: Random & Shop v27 — SIÊU GỌN
--  1 tab, không scroll, chỉ có thiết yếu
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

		local PointItemM = SafeRequire({ "Modules.GaranteeRandomItem", "Modules.GuaranteeRandomItem" })
		local PointItemMoon = SafeRequire({ "Modules.GuaranteeEventMoon", "Modules.GaranteeEventMoon" })

		local State = {
			running = false, mode = "x15",
			runningMoon = false, modeMoon = "x15",
			selectedItem = nil, selectedMoonItem = nil,
			autoBuy = false, autoShopMode = "Diamond",
			searchDiamond = "", searchMoon = "",
		}

		-- Build data
		local diamondList, moonList = {}, {}
		if PointItemM then
			for n, p in pairs(PointItemM) do
				table.insert(diamondList, { name = n, price = p, optStr = n .. " (" .. p .. "P)" })
			end
			table.sort(diamondList, function(a, b) return a.price < b.price end)
		end
		if PointItemMoon then
			for n, p in pairs(PointItemMoon) do
				table.insert(moonList, { name = n, price = p, optStr = n .. " (" .. p .. "P)" })
			end
			table.sort(moonList, function(a, b) return a.price < b.price end)
		end

		local diamondMap, diamondOptions = {}, {}
		for _, d in ipairs(diamondList) do
			table.insert(diamondOptions, d.optStr)
			diamondMap[d.optStr] = d.name
		end
		local moonMap, moonOptions = {}, {}
		for _, m in ipairs(moonList) do
			table.insert(moonOptions, m.optStr)
			moonMap[m.optStr] = m.name
		end

		-- Mua
		local function BuyDiamondItem(itemName)
			if not itemName then return end
			local point = tonumber(LP:GetAttribute("PointItem")) or 0
			local price = PointItemM and PointItemM[itemName] or 0
			if price == 0 or point < price then
				NeoUI.Notify:Show({ Title = "❌ Không đủ Point", Description = itemName, Duration = 2 })
				return
			end
			NetworkEvent:FireServer("fire", nil, "BuyGaranteeRandomItem", itemName)
			NeoUI.Notify:Show({ Title = "✅ Mua: " .. itemName, Description = "-" .. price, Duration = 2 })
		end

		local function BuyMoonItem(itemName)
			if not itemName then return end
			local point = tonumber(LP:GetAttribute("MoonPoint")) or 0
			local price = PointItemMoon and PointItemMoon[itemName] or 0
			if price == 0 or point < price then
				NeoUI.Notify:Show({ Title = "❌ Không đủ Moon", Description = itemName, Duration = 2 })
				return
			end
			NetworkEvent:FireServer("fire", nil, "BuyGaranteeEventMoon", itemName)
			NeoUI.Notify:Show({ Title = "✅ Mua Moon: " .. itemName, Description = "-" .. price, Duration = 2 })
		end

		-- Toggle quay
		local function ToggleRandom()
			State.running = not State.running
			if State.running then
				task.spawn(function()
					while State.running do
						pcall(function()
							NetworkEvent:FireServer("fire", nil, "RandomItem", State.mode)
						end)
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
						pcall(function()
							NetworkEvent:FireServer("fire", nil, "EventMoon", State.modeMoon)
						end)
						task.wait(0.1)
					end
				end)
			end
			NeoUI.Notify:Show({ Title = State.runningMoon and "▶️ Moon ON" or "⏹️ Moon OFF", Duration = 2 })
		end

		-- =======================================================
		--  SECTION 1: QUAY (2 cột)
		-- =======================================================
		local QuaySec = Tab:CreateSection("🎰 Auto Quay")
		local QuayRow = QuaySec:TwoColumn()

		-- Random (trái)
		QuayRow.Left:Dropdown({
			Title = "Random",
			Options = { "x5", "x10", "x15" },
			Value = "x15",
			Callback = function(v) State.mode = v end,
		})
		QuayRow.Left:Button({
			Title = "▶️ Bật / ⏹️ Dừng",
			Callback = ToggleRandom,
		})

		-- Moon (phải)
		QuayRow.Right:Dropdown({
			Title = "Event Moon",
			Options = { "x5", "x10", "x15" },
			Value = "x15",
			Callback = function(v) State.modeMoon = v end,
		})
		QuayRow.Right:Button({
			Title = "▶️ Bật / ⏹️ Dừng",
			Callback = ToggleMoon,
		})

		-- =======================================================
		--  SECTION 2: SHOP (2 cột, siêu gọn)
		-- =======================================================
		local ShopSec = Tab:CreateSection("🛒 Shop")
		local ShopRow = ShopSec:TwoColumn()

		-- Diamond (trái)
		ShopRow.Left:Textbox({
			Title = "🔍 Diamond",
			Placeholder = "Tên item...",
			Value = "",
			Callback = function(v) State.searchDiamond = v or "" end,
		})
		local diamondDropdown = ShopRow.Left:Dropdown({
			Title = "Chọn",
			Options = diamondOptions,
			Value = nil,
			Callback = function(v)
				local n = diamondMap[v]
				if n then
					State.selectedItem = n
					BuyDiamondItem(n)
				end
			end,
		})

		-- Moon (phải)
		ShopRow.Right:Textbox({
			Title = "🔍 Moon",
			Placeholder = "Tên item...",
			Value = "",
			Callback = function(v) State.searchMoon = v or "" end,
		})
		local moonDropdown = ShopRow.Right:Dropdown({
			Title = "Chọn",
			Options = moonOptions,
			Value = nil,
			Callback = function(v)
				local n = moonMap[v]
				if n then
					State.selectedMoonItem = n
					BuyMoonItem(n)
				end
			end,
		})

		-- Filter search
		task.spawn(function()
			local lastD, lastM = "", ""
			while true do
				task.wait(0.5)
				if diamondDropdown and diamondDropdown.Refresh then
					local q = (State.searchDiamond or ""):lower()
					local filt = {}
					if q == "" then
						for _, d in ipairs(diamondList) do table.insert(filt, d.optStr) end
					else
						for _, d in ipairs(diamondList) do
							if d.name:lower():find(q, 1, true) then table.insert(filt, d.optStr) end
						end
					end
					local k = table.concat(filt, "|")
					if k ~= lastD and #filt > 0 then
						lastD = k
						diamondDropdown:Refresh(filt, true)
					end
				end
				if moonDropdown and moonDropdown.Refresh then
					local q = (State.searchMoon or ""):lower()
					local filt = {}
					if q == "" then
						for _, m in ipairs(moonList) do table.insert(filt, m.optStr) end
					else
						for _, m in ipairs(moonList) do
							if m.name:lower():find(q, 1, true) then table.insert(filt, m.optStr) end
						end
					end
					local k = table.concat(filt, "|")
					if k ~= lastM and #filt > 0 then
						lastM = k
						moonDropdown:Refresh(filt, true)
					end
				end
			end
		end)

		-- =======================================================
		--  SECTION 3: AUTO MUA (1 hàng ngang)
		-- =======================================================
		local AutoSec = Tab:CreateSection("🔁 Auto")
		local AutoRow = AutoSec:TwoColumn()

		AutoRow.Left:Dropdown({
			Title = "Shop auto",
			Options = { "Diamond", "Moon", "Cả hai" },
			Value = "Diamond",
			Callback = function(v)
				if v == "Diamond" then State.autoShopMode = "Diamond"
				elseif v == "Moon" then State.autoShopMode = "Moon"
				else State.autoShopMode = "Both" end
			end,
		})

		AutoRow.Right:Toggle({
			Title = "Bật Auto mua",
			Value = false,
			Callback = function(v) State.autoBuy = v end,
		})

		task.spawn(function()
			while true do
				task.wait(3)
				if State.autoBuy then
					if (State.autoShopMode == "Diamond" or State.autoShopMode == "Both") and State.selectedItem then
						BuyDiamondItem(State.selectedItem)
					end
					if (State.autoShopMode == "Moon" or State.autoShopMode == "Both") and State.selectedMoonItem then
						BuyMoonItem(State.selectedMoonItem)
					end
				end
			end
		end)

		NeoUI.Notify:Show({
			Title = "✅ Random & Shop",
			Description = "Đã sẵn sàng!",
			Duration = 3,
		})
	end,
}
