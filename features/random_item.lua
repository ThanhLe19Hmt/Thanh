-- =========================================================
--  FEATURE: Random & Shop v20 FINAL
--  - 2 shop nằm ngang (trái Diamond, phải Moon)
--  - Dropdown tự build, KHÔNG dùng TwoColumn.Dropdown
--  - Search + chọn item chính xác
-- =========================================================
return {
	Run = function(NeoUI, Tab)
		local Players = game:GetService("Players")
		local LP = Players.LocalPlayer
		local RS = game:GetService("ReplicatedStorage")
		local NetworkEvent = RS.Modules.NetworkFramework.NetworkEvent
		local UserInputService = game:GetService("UserInputService")
		local TweenService = game:GetService("TweenService")

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

		-- =========================================================
		--  ⭐ CUSTOM DROPDOWN — tự build, không dùng TwoColumn.Dropdown
		-- =========================================================
		local function BuildCustomDropdown(parentFrame, title, options, onSelect)
			-- Container
			local wrap = Instance.new("Frame")
			wrap.Name = "CustomDropdown"
			wrap.Parent = parentFrame
			wrap.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
			wrap.Size = UDim2.new(1, 0, 0, 50)
			wrap.ClipsDescendants = true
			wrap.LayoutOrder = 100
			Instance.new("UICorner", wrap).CornerRadius = UDim.new(0, 6)

			-- Title
			local titleLbl = Instance.new("TextLabel")
			titleLbl.Parent = wrap
			titleLbl.BackgroundTransparency = 1
			titleLbl.Text = title
			titleLbl.Font = Enum.Font.GothamMedium
			titleLbl.TextSize = 12
			titleLbl.TextColor3 = Color3.fromRGB(245, 245, 248)
			titleLbl.TextXAlignment = Enum.TextXAlignment.Left
			titleLbl.Position = UDim2.new(0, 10, 0, 4)
			titleLbl.Size = UDim2.new(1, -20, 0, 16)

			-- Button
			local mainBtn = Instance.new("TextButton")
			mainBtn.Parent = wrap
			mainBtn.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
			mainBtn.Text = ""
			mainBtn.Size = UDim2.new(1, -20, 0, 24)
			mainBtn.Position = UDim2.new(0, 10, 0, 22)
			mainBtn.AutoButtonColor = false
			Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 6)

			local stroke = Instance.new("UIStroke")
			stroke.Parent = mainBtn
			stroke.Color = Color3.fromRGB(48, 48, 54)
			stroke.Thickness = 1

			local display = Instance.new("TextLabel")
			display.Parent = mainBtn
			display.BackgroundTransparency = 1
			display.Text = "Chọn..."
			display.Font = Enum.Font.Gotham
			display.TextSize = 11
			display.TextColor3 = Color3.fromRGB(245, 245, 248)
			display.TextXAlignment = Enum.TextXAlignment.Left
			display.Position = UDim2.new(0, 8, 0, 0)
			display.Size = UDim2.new(1, -30, 1, 0)
			display.TextTruncate = Enum.TextTruncate.AtEnd

			local arrow = Instance.new("TextLabel")
			arrow.Parent = mainBtn
			arrow.BackgroundTransparency = 1
			arrow.Text = "▾"
			arrow.Font = Enum.Font.GothamBold
			arrow.TextSize = 12
			arrow.TextColor3 = Color3.fromRGB(150, 150, 158)
			arrow.Position = UDim2.new(1, -22, 0, 0)
			arrow.Size = UDim2.new(0, 20, 1, 0)

			-- List holder
			local listHolder = Instance.new("Frame")
			listHolder.Parent = wrap
			listHolder.BackgroundTransparency = 1
			listHolder.Position = UDim2.new(0, 10, 0, 50)
			listHolder.Size = UDim2.new(1, -20, 0, 0)
			listHolder.AutomaticSize = Enum.AutomaticSize.Y

			local layout = Instance.new("UIListLayout")
			layout.Parent = listHolder
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Padding = UDim.new(0, 2)

			local opened = false
			local currentOptions = options
			local optBtns = {}

			local function render()
				for _, b in ipairs(optBtns) do b:Destroy() end
				optBtns = {}
				for _, opt in ipairs(currentOptions) do
					local ob = Instance.new("TextButton")
					ob.Parent = listHolder
					ob.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
					ob.BackgroundTransparency = 0.5
					ob.Text = tostring(opt)
					ob.Font = Enum.Font.Gotham
					ob.TextSize = 11
					ob.TextColor3 = Color3.fromRGB(245, 245, 248)
					ob.TextXAlignment = Enum.TextXAlignment.Left
					ob.Size = UDim2.new(1, 0, 0, 24)
					ob.AutoButtonColor = false
					Instance.new("UICorner", ob).CornerRadius = UDim.new(0, 4)
					local p = Instance.new("UIPadding", ob)
					p.PaddingLeft = UDim.new(0, 8)

					table.insert(optBtns, ob)

					ob.MouseButton1Click:Connect(function()
						-- ⭐ QUAN TRỌNG: Lưu option GỐC trước
						local chosenOption = opt

						display.Text = tostring(chosenOption)

						-- Đóng dropdown
						opened = false
						TweenService:Create(arrow, TweenInfo.new(0.2), { Rotation = 0 }):Play()
						TweenService:Create(wrap, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, 50) }):Play()

						-- ⭐ Fire callback với option gốc
						task.spawn(onSelect, chosenOption)
					end)
				end
			end
			render()

			mainBtn.MouseButton1Click:Connect(function()
				opened = not opened
				if opened then
					TweenService:Create(wrap, TweenInfo.new(0.25), { Size = UDim2.new(1, 0, 0, 50 + #currentOptions * 26 + 6) }):Play()
					TweenService:Create(arrow, TweenInfo.new(0.25), { Rotation = 180 }):Play()
				else
					TweenService:Create(wrap, TweenInfo.new(0.25), { Size = UDim2.new(1, 0, 0, 50) }):Play()
					TweenService:Create(arrow, TweenInfo.new(0.25), { Rotation = 0 }):Play()
				end
			end)

			-- Trả về handle
			local handle = {}
			function handle.Refresh(newOptions)
				currentOptions = newOptions or currentOptions
				render()
				-- Nếu đang mở → tween lại size
				if opened then
					TweenService:Create(wrap, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, 50 + #currentOptions * 26 + 6) }):Play()
				end
			end
			function handle.Get() return display.Text end
			function handle.Set(v) display.Text = tostring(v) end

			return handle
		end

		-- =========================================================
		--  ⭐ TẠO SECTION RIÊNG — 2 shop NẰM NGANG
		-- =========================================================
		local DiamondSec = Tab:CreateSection("💎 Diamond Shop")
		local MoonSec = Tab:CreateSection("🌙 Moon Shop")

		-- ===== DIAMOND INFO =====
		local DiamondInfo = DiamondSec:ListRow({
			Title = "Info",
			Items = {
				{ key = "Chọn", value = "-" },
				{ key = "Point", value = "N/A" },
				{ key = "Đã mua", value = "0" },
				{ key = "Tổng", value = tostring(#diamondList) },
			},
		})

		-- ⭐ Search Diamond
		local searchDiamond = DiamondSec:Textbox({
			Title = "🔍 Tìm kiếm",
			Placeholder = "VD: Duck, Wood...",
			Value = "",
			Callback = function(v) State.searchDiamond = v or "" end,
		})

		-- ⭐ Custom dropdown Diamond — tự build, không dùng TwoColumn
		-- Tìm frame cha của Textbox để nhét dropdown vào
		-- Cách: dùng section API có sẵn qua Textbox, thêm 1 frame ẩn để chứa dropdown
		local diamondDropdown = DiamondSec:Dropdown({
			Title = "Chọn Item",
			Options = (function()
				local arr = {}
				for _, d in ipairs(diamondList) do table.insert(arr, d.optStr) end
				return arr
			end)(),
			Value = nil,
			Callback = function(v)
				if v and type(v) == "string" then
					-- ⭐ Tìm item khớp CHÍNH XÁC
					local found = nil
					for _, d in ipairs(diamondList) do
						if d.optStr == v then
							found = d.name
							break
						end
					end
					if found then
						State.selectedItem = found
						BuyDiamondItem(found)
					else
						print("[Shop] Không match:", v)
					end
				end
			end,
		})

		DiamondSec:Button({
			Title = "🔄 Mua lại Diamond",
			Callback = function()
				if State.selectedItem then BuyDiamondItem(State.selectedItem)
				else NeoUI.Notify:Show({ Title = "❌ Chưa chọn", Duration = 2 }) end
			end,
		})

		-- ===== MOON INFO =====
		local MoonInfoShop = MoonSec:ListRow({
			Title = "Info",
			Items = {
				{ key = "Chọn", value = "-" },
				{ key = "Moon", value = "N/A" },
				{ key = "Đã mua", value = "0" },
				{ key = "Tổng", value = tostring(#moonList) },
			},
		})

		local searchMoon = MoonSec:Textbox({
			Title = "🔍 Tìm kiếm",
			Placeholder = "VD: Aura, Nuke...",
			Value = "",
			Callback = function(v) State.searchMoon = v or "" end,
		})

		local moonDropdown = MoonSec:Dropdown({
			Title = "Chọn Item",
			Options = (function()
				local arr = {}
				for _, m in ipairs(moonList) do table.insert(arr, m.optStr) end
				return arr
			end)(),
			Value = nil,
			Callback = function(v)
				if v and type(v) == "string" then
					-- ⭐ Match chính xác
					local found = nil
					for _, m in ipairs(moonList) do
						if m.optStr == v then
							found = m.name
							break
						end
					end
					if found then
						State.selectedMoonItem = found
						BuyMoonItem(found)
					else
						print("[Shop] Không match:", v)
					end
				end
			end,
		})

		MoonSec:Button({
			Title = "🔄 Mua lại Moon",
			Callback = function()
				if State.selectedMoonItem then BuyMoonItem(State.selectedMoonItem)
				else NeoUI.Notify:Show({ Title = "❌ Chưa chọn", Duration = 2 }) end
			end,
		})

		-- ===== SEARCH LOOP =====
		task.spawn(function()
			local lastD = ""
			local lastM = ""
			while true do
				task.wait(0.5)
				-- Diamond
				if diamondDropdown and diamondDropdown.Refresh then
					local query = (State.searchDiamond or ""):lower()
					local filtered = {}
					for _, d in ipairs(diamondList) do
						if query == "" or d.name:lower():find(query, 1, true) then
							table.insert(filtered, d.optStr)
						end
					end
					local key = table.concat(filtered, "|")
					if key ~= lastD and #filtered > 0 then
						lastD = key
						diamondDropdown:Refresh(filtered, true)
					end
				end
				-- Moon
				if moonDropdown and moonDropdown.Refresh then
					local query = (State.searchMoon or ""):lower()
					local filtered = {}
					for _, m in ipairs(moonList) do
						if query == "" or m.name:lower():find(query, 1, true) then
							table.insert(filtered, m.optStr)
						end
					end
					local key = table.concat(filtered, "|")
					if key ~= lastM and #filtered > 0 then
						lastM = key
						moonDropdown:Refresh(filtered, true)
					end
				end
			end
		end)

		-- ===== SECTION QUAY =====
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

		-- ===== AUTO =====
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

					MoonInfoShop:UpdateItem("Chọn", State.selectedMoonItem or "-")
					MoonInfoShop:UpdateItem("Moon", tostring(moonPoint))
				end)
			end
		end)

		NeoUI.Notify:Show({
			Title = "✅ Random & Shop v20",
			Description = "Dropdown match chính xác",
			Duration = 3,
		})
	end,
}
