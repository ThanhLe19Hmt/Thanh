-- =========================================================
--  FEATURE: Random & Shop v44
--  + Gợi ý kiểu Google — popup nổi khi gõ
--  + Layout ngang: Diamond trái, Moon phải
--  + Mỗi bên có dropdown Chọn Item
-- =========================================================
return {
	Run = function(NeoUI, Tab)
		local Players = game:GetService("Players")
		local LP = Players.LocalPlayer
		local RS = game:GetService("ReplicatedStorage")
		local CoreGui = game:GetService("CoreGui")
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
		local PointItemMoon = SafeRequire({
			"Modules.GuaranteeEventMoon", "Modules.GaranteeEventMoon",
			"Modules.EventMoonGuarantee", "Modules.MoonGuarantee",
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

		local FALLBACK_MOON = {}

		local diamondList, moonList = {}, {}
		local diamondOptions, moonOptions = {}, {}

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

		print("[v44] Diamond: " .. #diamondOptions .. " | Moon: " .. #moonOptions)

		local function NormalizeName(s)
			return tostring(s):lower():gsub("[%s_%-]", "")
		end

		local function FilterList(list, query)
			if not query or query == "" then return {} end
			local qNorm = NormalizeName(query)
			local filt = {}
			for _, d in ipairs(list) do
				if NormalizeName(d.name):find(qNorm, 1, true) then
					table.insert(filt, d)
				end
			end
			return filt
		end

		-- ⭐⭐⭐ HÀM TẠO POPUP GỢI Ý KIỂU GOOGLE
		local function CreateSuggestPopup(anchorTextBox, getListFn, onSelect)
			-- Tạo frame popup nổi
			local popup = Instance.new("Frame")
			popup.Name = "SuggestPopup_" .. tostring(math.random(1000, 9999))
			popup.Parent = CoreGui:FindFirstChildOfClass("ScreenGui") or CoreGui
			-- Dùng chính ScreenGui của NeoUI
			for _, g in ipairs(CoreGui:GetChildren()) do
				if g.Name:find("NeoUI_") then
					popup.Parent = g
					break
				end
			end
			popup.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
			popup.BorderSizePixel = 0
			popup.Visible = false
			popup.ZIndex = 5000
			popup.ClipsDescendants = true
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = popup
			
			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(60, 60, 68)
			stroke.Thickness = 1.5
			stroke.Parent = popup
			
			local scroll = Instance.new("ScrollingFrame")
			scroll.Parent = popup
			scroll.BackgroundTransparency = 1
			scroll.Size = UDim2.new(1, -8, 1, -8)
			scroll.Position = UDim2.new(0, 4, 0, 4)
			scroll.ScrollBarThickness = 3
			scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 88)
			scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
			scroll.BorderSizePixel = 0
			
			local layout = Instance.new("UIListLayout")
			layout.Parent = scroll
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Padding = UDim.new(0, 2)
			
			local buttons = {}
			
			local function ClearButtons()
				for _, b in ipairs(buttons) do
					if b and b.Parent then b:Destroy() end
				end
				buttons = {}
			end
			
			local function ShowSuggestions(query)
				ClearButtons()
				
				if not query or query == "" then
					popup.Visible = false
					return
				end
				
				local matches = getListFn(query)
				if #matches == 0 then
					popup.Visible = false
					return
				end
				
				-- Hiện tối đa 8 gợi ý (kiểu Google)
				local limit = math.min(#matches, 8)
				
				for i = 1, limit do
					local item = matches[i]
					local btn = Instance.new("TextButton")
					btn.Parent = scroll
					btn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
					btn.BorderSizePixel = 0
					btn.Text = ""
					btn.Size = UDim2.new(1, -6, 0, 32)
					btn.AutoButtonColor = false
					btn.LayoutOrder = i
					
					local btnCorner = Instance.new("UICorner")
					btnCorner.CornerRadius = UDim.new(0, 5)
					btnCorner.Parent = btn
					
					-- Tên item (trái)
					local nameLbl = Instance.new("TextLabel")
					nameLbl.Parent = btn
					nameLbl.BackgroundTransparency = 1
					nameLbl.Text = item.name
					nameLbl.Font = Enum.Font.GothamMedium
					nameLbl.TextSize = 12
					nameLbl.TextColor3 = Color3.fromRGB(240, 240, 245)
					nameLbl.TextXAlignment = Enum.TextXAlignment.Left
					nameLbl.Position = UDim2.new(0, 10, 0, 0)
					nameLbl.Size = UDim2.new(0.65, -10, 1, 0)
					nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
					
					-- Giá (phải)
					local priceLbl = Instance.new("TextLabel")
					priceLbl.Parent = btn
					priceLbl.BackgroundTransparency = 1
					priceLbl.Text = item.price .. "P"
					priceLbl.Font = Enum.Font.GothamBold
					priceLbl.TextSize = 11
					priceLbl.TextColor3 = Color3.fromRGB(230, 55, 55)
					priceLbl.TextXAlignment = Enum.TextXAlignment.Right
					priceLbl.Position = UDim2.new(0.65, 0, 0, 0)
					priceLbl.Size = UDim2.new(0.35, -10, 1, 0)
					
					-- Hover effect
					btn.MouseEnter:Connect(function()
						btn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
					end)
					btn.MouseLeave:Connect(function()
						btn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
					end)
					
					-- Click → chọn
					btn.MouseButton1Click:Connect(function()
						onSelect(item)
						popup.Visible = false
					end)
					
					table.insert(buttons, btn)
				end
				
				-- Cập nhật canvas size
				layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 4)
				end)
				scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 4)
				
				-- Định vị popup dưới textbox
				local absPos = anchorTextBox.AbsolutePosition
				local absSize = anchorTextBox.AbsoluteSize
				local popupH = math.min(#matches * 34 + 10, 280)
				
				popup.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 4)
				popup.Size = UDim2.fromOffset(math.max(absSize.X, 200), popupH)
				popup.Visible = true
			end
			
			-- Theo dõi thay đổi text
			local lastText = ""
			anchorTextBox:GetPropertyChangedSignal("Text"):Connect(function()
				local newText = anchorTextBox.Text
				if newText ~= lastText then
					lastText = newText
					ShowSuggestions(newText)
				end
			end)
			
			-- Ẩn khi mất focus (nhưng delay để kịp click)
			anchorTextBox.FocusLost:Connect(function()
				task.wait(0.2)
				popup.Visible = false
			end)
			
			return {
				Hide = function() popup.Visible = false end,
				Show = ShowSuggestions,
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

		-- ===== QUAY =====
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
		--  SHOP — 2 cột: Diamond trái, Moon phải
		-- =======================================================
		local ShopSec = Tab:CreateSection("Shop")
		local ShopRow = ShopSec:TwoColumn()

		-- ===== DIAMOND (TRÁI) =====
		local diamondInfo = ShopRow.Left:ListRow({
			Title = "Diamond",
			Items = {
				{ key = "Đang chọn", value = "-" },
			},
		})

		-- ⭐ Dropdown chọn item
		ShopRow.Left:Dropdown({
			Title = "Chọn Item",
			Options = diamondOptions,
			Value = nil,
			Callback = function(v)
				if v and type(v) == "string" then
					local name = v:match("^(.-) %(")
					if name then
						State.selectedItem = name
						diamondInfo:UpdateItem("Đang chọn", name)
					end
				end
			end,
		})

		-- ⭐ Ô tìm kiếm — có autocomplete
		local searchD = ShopRow.Left:Textbox({
			Title = "Tìm",
			Placeholder = "Gõ: orb, duck...",
			Value = "",
		})

		-- ⭐ Nút mua
		ShopRow.Left:Button({
			Title = "MUA DIAMOND",
			Callback = function()
				if State.selectedItem then
					BuyDiamondItem(State.selectedItem)
				else
					NeoUI.Notify:Show({ Title = "Chưa chọn item", Duration = 2 })
				end
			end,
		})

		-- ⭐ Kích hoạt autocomplete cho Diamond
		task.spawn(function()
			task.wait(1.5)
			if searchD and searchD.Instance then
				CreateSuggestPopup(
					searchD.Instance,
					function(q) return FilterList(diamondList, q) end,
					function(item)
						State.selectedItem = item.name
						diamondInfo:UpdateItem("Đang chọn", item.name)
						-- Gán text vào textbox
						searchD.Instance.Text = item.name
						print("[v44] Diamond chọn: " .. item.name)
						NeoUI.Notify:Show({
							Title = "Đã chọn: " .. item.name,
							Description = item.price .. " Point",
							Duration = 2,
						})
					end
				)
			end
		end)

		-- ===== MOON (PHẢI) =====
		if #moonOptions > 0 then
			local moonInfo = ShopRow.Right:ListRow({
				Title = "Moon",
				Items = {
					{ key = "Đang chọn", value = "-" },
				},
			})

			ShopRow.Right:Dropdown({
				Title = "Chọn Item",
				Options = moonOptions,
				Value = nil,
				Callback = function(v)
					if v and type(v) == "string" then
						local name = v:match("^(.-) %(")
						if name then
							State.selectedMoonItem = name
							moonInfo:UpdateItem("Đang chọn", name)
						end
					end
				end,
			})

			local searchM = ShopRow.Right:Textbox({
				Title = "Tìm",
				Placeholder = "Gõ: aura...",
				Value = "",
			})

			ShopRow.Right:Button({
				Title = "MUA MOON",
				Callback = function()
					if State.selectedMoonItem then
						BuyMoonItem(State.selectedMoonItem)
					else
						NeoUI.Notify:Show({ Title = "Chưa chọn item", Duration = 2 })
					end
				end,
			})

			task.spawn(function()
				task.wait(1.5)
				if searchM and searchM.Instance then
					CreateSuggestPopup(
						searchM.Instance,
						function(q) return FilterList(moonList, q) end,
						function(item)
							State.selectedMoonItem = item.name
							moonInfo:UpdateItem("Đang chọn", item.name)
							searchM.Instance.Text = item.name
							print("[v44] Moon chọn: " .. item.name)
							NeoUI.Notify:Show({
								Title = "Đã chọn Moon: " .. item.name,
								Description = item.price .. " Point",
								Duration = 2,
							})
						end
					)
				end
			end)
		else
			ShopRow.Right:ListRow({
				Title = "Moon",
				Items = { { key = "Trạng thái", value = "Chưa load module" } },
			})
		end

		-- ===== AUTO MUA =====
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
			Title = "v44 Loaded",
			Description = "Gõ vào ô Tìm để xem gợi ý",
			Duration = 5,
		})
	end,
}
