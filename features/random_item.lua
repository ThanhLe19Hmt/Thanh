-- =========================================================
--  FEATURE: Random & Shop v12 FINAL
--  ✅ Remote chuẩn: BuyGaranteeRandomItem / BuyGaranteeEventMoon
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
			selectedItem = nil,
			selectedMoonItem = nil,
			autoBuy = false,
		}

		-- ===== HELPERS =====
		local function GetInventory()
			local ok, data = pcall(function()
				return HttpService:JSONDecode(LP:GetAttribute("Inventory") or "{}")
			end)
			return ok and data or {}
		end

		local function GetItemAmount(name)
			local inv = GetInventory()
			return (inv[name] and inv[name].amount) or 0
		end

		-- ===== RANDOM =====
		local function ToggleRandom()
			if State.running then
				State.running = false
				NeoUI.Notify:Show({ Title = "⏹️ Dừng quay", Duration = 2 })
				return
			end
			State.running = true
			State.count = 0
			NeoUI.Notify:Show({
				Title = "▶️ Bắt đầu " .. State.mode,
				Duration = 2,
			})
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

		-- ===== MUA ITEM =====
		local function BuyDiamondItem(itemName)
			local point = tonumber(LP:GetAttribute("PointItem")) or 0
			local price = (PointItemM and PointItemM[itemName]) or 0
			
			if price == 0 then
				NeoUI.Notify:Show({
					Title = "❌ Item không có giá",
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
			NeoUI.Notify:Show({
				Title = "✅ Mua: " .. itemName,
				Description = "-" .. price .. " Point",
				Duration = 2,
			})
			print("[Shop] Mua:", itemName, "| Giá:", price, "| Còn:", point - price)
			return true
		end

		local function BuyMoonItem(itemName)
			local point = tonumber(LP:GetAttribute("MoonPoint")) or 0
			local price = (PointItemMoon and PointItemMoon[itemName]) or 0
			
			if price == 0 then
				NeoUI.Notify:Show({
					Title = "❌ Item không có giá",
					Duration = 2,
				})
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
			NeoUI.Notify:Show({
				Title = "✅ Mua Moon: " .. itemName,
				Description = "-" .. price .. " Point",
				Duration = 2,
			})
			return true
		end

		-- ===== BUILD DROPDOWN OPTIONS =====
		local diamondOptions = {}
		local diamondPriceMap = {}  -- { "Tên - Giá Point": "Tên gốc" }
		if PointItemM then
			local list = {}
			for name, price in pairs(PointItemM) do
				table.insert(list, { name = name, price = price })
			end
			table.sort(list, function(a, b) return a.price < b.price end)
			for _, d in ipairs(list) do
				local optStr = d.name .. " - " .. d.price .. " Point"
				table.insert(diamondOptions, optStr)
				diamondPriceMap[optStr] = d.name
			end
		end

		local moonOptions = {}
		local moonPriceMap = {}
		if PointItemMoon then
			local list = {}
			for name, price in pairs(PointItemMoon) do
				table.insert(list, { name = name, price = price })
			end
			table.sort(list, function(a, b) return a.price < b.price end)
			for _, m in ipairs(list) do
				local optStr = m.name .. " - " .. m.price .. " Point"
				table.insert(moonOptions, optStr)
				moonPriceMap[optStr] = m.name
			end
		end

		-- ===== UI =====
		local Sec = Tab:CreateSection("🎰 Random & Shop")

		Sec:Paragraph({
			Title = "Hướng dẫn",
			Content = "Bên trái: bật quay chest.\nBên phải: chọn item + MUA bằng Point.",
		})

		local MainRow = Sec:TwoColumn()

		-- ===== CỘT TRÁI: RANDOM =====
		local RandomInfo = MainRow.Left:ListRow({
			Title = "🎰 Random",
			Items = {
				{ key = "Trạng thái", value = "❌ Dừng" },
				{ key = "Mốc", value = "x15" },
				{ key = "Đã quay", value = "0" },
				{ key = "Diamond", value = "N/A" },
			},
		})

		local modeBox = MainRow.Left:Textbox({
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

		MainRow.Left:Button({
			Title = "▶️ BẬT / ⏹️ DỪNG",
			Callback = function()
				local v = tonumber(modeBox:Get()) or 15
				if v == 5 then State.mode = "x5"
				elseif v == 10 then State.mode = "x10"
				else State.mode = "x15" end
				ToggleRandom()
			end,
		})

		-- ===== CỘT PHẢI: SHOP =====
		local ShopInfo = MainRow.Right:ListRow({
			Title = "🛒 Shop",
			Items = {
				{ key = "Đang chọn", value = "-" },
				{ key = "PointItem", value = "N/A" },
				{ key = "MoonPoint", value = "N/A" },
				{ key = "Đã mua", value = "0" },
			},
		})

		-- ⭐ Dropdown Diamond Point
		MainRow.Right:Dropdown({
			Title = "💎 Chọn Item (Diamond Point)",
			Options = diamondOptions,
			Value = nil,
			Callback = function(v)
				if v then
					local itemName = diamondPriceMap[v]
					if itemName then
						State.selectedItem = itemName
						BuyDiamondItem(itemName)
					end
				end
			end,
		})

		-- ⭐ Dropdown Moon Point
		if #moonOptions > 0 then
			MainRow.Right:Dropdown({
				Title = "🌙 Chọn Item (Moon Point)",
				Options = moonOptions,
				Value = nil,
				Callback = function(v)
					if v then
						local itemName = moonPriceMap[v]
						if itemName then
							State.selectedMoonItem = itemName
							BuyMoonItem(itemName)
						end
					end
				end,
			})
		end

		-- Nút mua lại
		MainRow.Right:Button({
			Title = "🔄 Mua lại item đã chọn",
			Callback = function()
				if State.selectedItem then
					BuyDiamondItem(State.selectedItem)
				else
					NeoUI.Notify:Show({ Title = "❌ Chưa chọn item", Duration = 2 })
				end
			end,
		})

		-- Toggle auto buy
		MainRow.Right:Toggle({
			Title = "Auto mua lại mỗi 3s",
			Value = false,
			Callback = function(v)
				State.autoBuy = v
			end,
		})

		-- ===== AUTO BUY LOOP =====
		task.spawn(function()
			while true do
				task.wait(3)
				if State.autoBuy and State.selectedItem then
					BuyDiamondItem(State.selectedItem)
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

					RandomInfo:UpdateItem("Trạng thái", State.running and "✅ Đang chạy" or "❌ Dừng")
					RandomInfo:UpdateItem("Mốc", State.mode)
					RandomInfo:UpdateItem("Đã quay", tostring(State.count))
					RandomInfo:UpdateItem("Diamond", tostring(math.floor(diamond)))

					ShopInfo:UpdateItem("Đang chọn", State.selectedItem or "-")
					ShopInfo:UpdateItem("PointItem", tostring(pointItem))
					ShopInfo:UpdateItem("MoonPoint", tostring(moonPoint))
				end)
			end
		end)

		NeoUI.Notify:Show({
			Title = "✅ Random & Shop",
			Description = "Chọn item từ dropdown để mua",
			Duration = 3,
		})
	end,
}
