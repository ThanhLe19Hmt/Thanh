-- =========================================================
--  FEATURE: Random & Shop v13
--  - Fix nil khi chọn item
--  - Fix title bị cắt
--  - Gộp Random Chest + Event Moon
-- =========================================================
return {
	Run = function(NeoUI, Tab)
		local Players = game:GetService("Players")
		local LP = Players.LocalPlayer
		local RS = game:GetService("ReplicatedStorage")
		local NetworkEvent = RS.Modules.NetworkFramework.NetworkEvent
		local HttpService = game:GetService("HttpService")

		-- Load module giá
		local PointItemM = nil
		local PointItemMoon = nil
		pcall(function() PointItemM = require(RS.Modules.GuaranteeRandomItem) end)
		pcall(function() PointItemMoon = require(RS.Modules.GuaranteeEventMoon) end)

		-- ===== STATE =====
		local State = {
			running = false,
			mode = "x15",
			count = 0,
			-- Moon
			runningMoon = false,
			modeMoon = "x15",
			countMoon = 0,
			-- Shop
			selectedItem = nil,
			selectedMoonItem = nil,
			autoBuy = false,
			boughtCount = 0,
		}

		-- ===== HELPERS =====
		local function GetInventory()
			local ok, data = pcall(function()
				return HttpService:JSONDecode(LP:GetAttribute("Inventory") or "{}")
			end)
			return ok and data or {}
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
			if not itemName or itemName == "" then
				NeoUI.Notify:Show({ Title = "❌ Item không hợp lệ", Duration = 2 })
				return false
			end

			local point = tonumber(LP:GetAttribute("PointItem")) or 0
			local price = (PointItemM and PointItemM[itemName]) or 0

			if price == 0 then
				NeoUI.Notify:Show({
					Title = "❌ Không có giá",
					Description = itemName,
					Duration = 2,
				})
				return false
			end

			if point < price then
				NeoUI.Notify:Show({
					Title = "❌ Không đủ Point",
					Description = "Cần " .. price .. ", có " .. point,
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
			print("[Shop] Mua:", itemName, "| Giá:", price, "| Còn:", point - price)
			return true
		end

		local function BuyMoonItem(itemName)
			if not itemName or itemName == "" then
				NeoUI.Notify:Show({ Title = "❌ Item không hợp lệ", Duration = 2 })
				return false
			end

			local point = tonumber(LP:GetAttribute("MoonPoint")) or 0
			local price = (PointItemMoon and PointItemMoon[itemName]) or 0

			if price == 0 then
				NeoUI.Notify:Show({ Title = "❌ Không có giá", Duration = 2 })
				return false
			end

			if point < price then
				NeoUI.Notify:Show({
					Title = "❌ Không đủ Moon Point",
					Description = "Cần " .. price .. ", có " .. point,
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

		-- ===== BUILD DROPDOWN =====
		-- Dùng map: option string → item name
		-- Format: "Tên (X Point)" để không có ký tự lạ
		local diamondOptions = {}
		local diamondMap = {}
		if PointItemM then
			local list = {}
			for name, price in pairs(PointItemM) do
				table.insert(list, { name = name, price = price })
			end
			table.sort(list, function(a, b) return a.price < b.price end)
			for _, d in ipairs(list) do
				local optStr = d.name .. " (" .. d.price .. "P)"
				table.insert(diamondOptions, optStr)
				diamondMap[optStr] = d.name
			end
		end

		local moonOptions = {}
		local moonMap = {}
		if PointItemMoon then
			local list = {}
			for name, price in pairs(PointItemMoon) do
				table.insert(list, { name = name, price = price })
			end
			table.sort(list, function(a, b) return a.price < b.price end)
			for _, m in ipairs(list) do
				local optStr = m.name .. " (" .. m.price .. "P)"
				table.insert(moonOptions, optStr)
				moonMap[optStr] = m.name
			end
		end

		-- ===== UI =====
		local Sec = Tab:CreateSection("🎰 Auto Quay")

		Sec:Paragraph({
			Title = "Hướng dẫn",
			Content = "Bên trái: Random Chest.\nBên phải: Event Moon Chest.",
		})

		-- ⭐ HÀNG 1: 2 cột quay
		local QuayRow = Sec:TwoColumn()

		-- ===== TRÁI: RANDOM CHEST =====
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
			Callback = function()
				ToggleRandom()
			end,
		})

		-- ===== PHẢI: EVENT MOON =====
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
			Callback = function()
				ToggleMoon()
			end,
		})

		-- ===== SECTION 2: SHOP =====
		local ShopSec = Tab:CreateSection("🛒 Shop Item")

		ShopSec:Paragraph({
			Title = "Mua item bằng Point",
			Content = "Chọn item từ dropdown → tự mua ngay.",
		})

		local ShopRow = ShopSec:TwoColumn()

		-- ===== TRÁI: DIAMOND SHOP =====
		local DiamondInfo = ShopRow.Left:ListRow({
			Title = "💎 Diamond Shop",
			Items = {
				{ key = "Đang chọn", value = "-" },
				{ key = "PointItem", value = "N/A" },
				{ key = "Đã mua", value = "0" },
			},
		})

		if #diamondOptions > 0 then
			ShopRow.Left:Dropdown({
				Title = "Chọn Item",
				Options = diamondOptions,
				Value = nil,
				Callback = function(v)
					if v and type(v) == "string" then
						local itemName = diamondMap[v]
						if itemName then
							State.selectedItem = itemName
							BuyDiamondItem(itemName)
						else
							print("[Shop] Không tìm thấy item:", v)
						end
					end
				end,
			})
		else
			ShopRow.Left:Paragraph({
				Title = "❌ Không load được",
				Content = "Không tìm thấy GuaranteeRandomItem module",
			})
		end

		ShopRow.Left:Button({
			Title = "🔄 Mua lại item đã chọn",
			Callback = function()
				if State.selectedItem then
					BuyDiamondItem(State.selectedItem)
				else
					NeoUI.Notify:Show({ Title = "❌ Chưa chọn item", Duration = 2 })
				end
			end,
		})

		-- ===== PHẢI: MOON SHOP =====
		local MoonShopInfo = ShopRow.Right:ListRow({
			Title = "🌙 Moon Shop",
			Items = {
				{ key = "Đang chọn", value = "-" },
				{ key = "MoonPoint", value = "N/A" },
			},
		})

		if #moonOptions > 0 then
			ShopRow.Right:Dropdown({
				Title = "Chọn Item",
				Options = moonOptions,
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
			Title = "🔄 Mua lại item Moon",
			Callback = function()
				if State.selectedMoonItem then
					BuyMoonItem(State.selectedMoonItem)
				else
					NeoUI.Notify:Show({ Title = "❌ Chưa chọn item", Duration = 2 })
				end
			end,
		})

		-- ===== AUTO BUY =====
		local AutoSec = Tab:CreateSection("🔁 Auto Mua")

		AutoSec:Toggle({
			Title = "Auto mua lại mỗi 3s",
			Value = false,
			Callback = function(v)
				State.autoBuy = v
				NeoUI.Notify:Show({
					Title = v and "✅ Auto Buy ON" or "❌ Auto Buy OFF",
					Duration = 2,
				})
			end,
		})

		AutoSec:Paragraph({
			Title = "Lưu ý",
			Content = "Chọn item trước khi bật Auto Buy.\nScript sẽ tự mua lại mỗi 3 giây.",
		})

		-- ===== AUTO BUY LOOP =====
		task.spawn(function()
			while true do
				task.wait(3)
				if State.autoBuy then
					if State.selectedItem then
						BuyDiamondItem(State.selectedItem)
					end
					if State.selectedMoonItem then
						BuyMoonItem(State.selectedMoonItem)
					end
				end
			end
		end)

		-- ===== REFRESH =====
		task.spawn(function()
			task.wait(0.5)
			while true do
				task.wait(1)
				pcall(function()
					local diamond = LP:GetAttribute("Diamond") or 0
					local pointItem = LP:GetAttribute("PointItem") or 0
					local moonPoint = LP:GetAttribute("MoonPoint") or 0

					-- Random
					RandomInfo:UpdateItem("Trạng thái", State.running and "✅ Đang chạy" or "❌ Dừng")
					RandomInfo:UpdateItem("Mốc", State.mode)
					RandomInfo:UpdateItem("Đã quay", tostring(State.count))
					RandomInfo:UpdateItem("Diamond", tostring(math.floor(diamond)))

					-- Moon
					MoonInfo:UpdateItem("Trạng thái", State.runningMoon and "✅ Đang chạy" or "❌ Dừng")
					MoonInfo:UpdateItem("Mốc", State.modeMoon)
					MoonInfo:UpdateItem("Đã quay", tostring(State.countMoon))
					MoonInfo:UpdateItem("MoonPoint", tostring(moonPoint))

					-- Shop
					DiamondInfo:UpdateItem("Đang chọn", State.selectedItem or "-")
					DiamondInfo:UpdateItem("PointItem", tostring(pointItem))
					DiamondInfo:UpdateItem("Đã mua", tostring(State.boughtCount))

					MoonShopInfo:UpdateItem("Đang chọn", State.selectedMoonItem or "-")
					MoonShopInfo:UpdateItem("MoonPoint", tostring(moonPoint))
				end)
			end
		end)

		NeoUI.Notify:Show({
			Title = "✅ Random & Shop v13",
			Description = "Chọn item để mua",
			Duration = 3,
		})
	end,
}
