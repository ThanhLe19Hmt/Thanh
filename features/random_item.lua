-- =========================================================
--  FEATURE: Random & Shop v38
--  - Dùng SetDisplayText mới của NeoUI
--  - Enter → gán text trực tiếp, không bug
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
		local PointItemMoon = SafeRequire({ "Modules.GuaranteeEventMoon", "Modules.GuaranteeEventMoon" })

		local diamondList, moonList = {}, {}
		local diamondOptions, moonOptions = {}, {}

		if PointItemM then
			for n, p in pairs(PointItemM) do
				table.insert(diamondList, { name = n, price = p, optStr = n .. " (" .. p .. "P)" })
			end
			table.sort(diamondList, function(a, b) return a.price < b.price end)
			for _, d in ipairs(diamondList) do
				table.insert(diamondOptions, d.optStr)
			end
		end

		if PointItemMoon then
			for n, p in pairs(PointItemMoon) do
				table.insert(moonList, { name = n, price = p, optStr = n .. " (" .. p .. "P)" })
			end
			table.sort(moonList, function(a, b) return a.price < b.price end)
			for _, m in ipairs(moonList) do
				table.insert(moonOptions, m.optStr)
			end
		end

		if #diamondOptions == 0 then
			diamondOptions = {
				"Bacon (5P)", "Wood (10P)", "Duck (5P)", "Iron (5P)",
				"Fish (5P)", "Old Wood (10P)", "Cheese (10P)", "Spatula (50P)",
			}
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
			local price = PointItemM and PointItemM[itemName] or 0
			if price > 0 and point < price then
				NeoUI.Notify:Show({ Title = "❌ Thiếu Point", Description = itemName .. " (" .. price .. ")", Duration = 2 })
				return
			end
			NetworkEvent:FireServer("fire", nil, "BuyGaranteeRandomItem", itemName)
			State.selectedItem = itemName
			NeoUI.Notify:Show({ Title = "✅ Mua: " .. itemName, Description = "-" .. price, Duration = 2 })
		end

		local function BuyMoonItem(itemName)
			if not itemName or type(itemName) ~= "string" then return end
			local point = tonumber(LP:GetAttribute("MoonPoint")) or 0
			local price = PointItemMoon and PointItemMoon[itemName] or 0
			if price > 0 and point < price then
				NeoUI.Notify:Show({ Title = "❌ Thiếu Moon", Description = itemName .. " (" .. price .. ")", Duration = 2 })
				return
			end
			NetworkEvent:FireServer("fire", nil, "BuyGaranteeEventMoon", itemName)
			State.selectedMoonItem = itemName
			NeoUI.Notify:Show({ Title = "✅ Mua Moon: " .. itemName, Description = "-" .. price, Duration = 2 })
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

		-- =======================================================
		--  DIAMOND SHOP
		-- =======================================================
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

		-- ⭐ Lưu display label reference
		local diamondDisplayLabel = nil
		task.spawn(function()
			task.wait(1)
			if diamondDrop and diamondDrop.GetDisplayLabel then
				diamondDisplayLabel = diamondDrop:GetDisplayLabel()
				print("[v38] Diamond display label:", diamondDisplayLabel ~= nil)
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
								
								-- ⭐⭐⭐ CÁCH CHÍNH: Gán text trực tiếp vào display label
								if diamondDisplayLabel and diamondDisplayLabel.Parent then
									diamondDisplayLabel.Text = found.optStr
									print("[v38] Set display:", found.optStr)
								elseif diamondDrop and diamondDrop.SetDisplayText then
									diamondDrop:SetDisplayText(found.optStr)
								else
									-- Fallback: dùng Set (có thể bị bug)
									if diamondDrop and diamondDrop.Set then
										pcall(function() diamondDrop:Set(found.optStr) end)
									end
								end
								
								-- Đợi 0.1s, force lại lần nữa (đề phòng NeoUI ghi đè)
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

		-- =======================================================
		--  MOON SHOP
		-- =======================================================
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
					print("[v38] Moon display label:", moonDisplayLabel ~= nil)
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
									else
										if moonDrop and moonDrop.Set then
											pcall(function() moonDrop:Set(found.optStr) end)
										end
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

		-- =======================================================
		--  ⭐ WATCHDOG — Fix table:0x về tên đã chọn
		-- =======================================================
		task.spawn(function()
			while true do
				task.wait(0.2)
				pcall(function()
					-- Diamond display
					if diamondDisplayLabel and diamondDisplayLabel.Parent then
						local t = diamondDisplayLabel.Text
						if type(t) == "string" and t:find("table:") then
							-- Bị table → đổi về tên item đã chọn
							if State.selectedItem and PointItemM and PointItemM[State.selectedItem] then
								diamondDisplayLabel.Text = State.selectedItem .. " (" .. PointItemM[State.selectedItem] .. "P)"
							else
								diamondDisplayLabel.Text = "Chọn..."
							end
						end
					end
					
					-- Moon display
					if moonDisplayLabel and moonDisplayLabel.Parent then
						local t = moonDisplayLabel.Text
						if type(t) == "string" and t:find("table:") then
							if State.selectedMoonItem and PointItemMoon and PointItemMoon[State.selectedMoonItem] then
								moonDisplayLabel.Text = State.selectedMoonItem .. " (" .. PointItemMoon[State.selectedMoonItem] .. "P)"
							else
								moonDisplayLabel.Text = "Chọn..."
							end
						end
					end
				end)
			end
		end)

		-- =======================================================
		--  AUTO MUA
		-- =======================================================
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
			Title = "✅ v38 Loaded",
			Description = "Direct display text",
			Duration = 5,
		})
	end,
}
