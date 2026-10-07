-- =========================================================
--  FEATURE: Random & Shop (gộp)
--  ItemScrollingFrame (trái) = chọn item
--  DisplayFrame (phải)       = x5/x10/x15
-- =========================================================
return {
	Run = function(NeoUI, Tab)
		local Players = game:GetService("Players")
		local LP = Players.LocalPlayer
		local VIM = game:GetService("VirtualInputManager")

		local function GetHUD() return LP.PlayerGui:FindFirstChild("HUD") end

		local function FindPath(path)
			local hud = GetHUD()
			if not hud then return nil end
			local ok, r = pcall(function()
				local cur = hud
				for seg in path:gmatch("[^%.]+") do
					cur = cur[seg]
					if not cur then return nil end
				end
				return cur
			end)
			return ok and r or nil
		end

		local function ClickButton(btn)
			if not btn then return false end
			if firesignal then
				local ok = pcall(function() firesignal(btn.Activated) end)
				if ok then
					pcall(function() firesignal(btn.MouseButton1Click) end)
					return true
				end
			end
			local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
			VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
			task.wait(0.05)
			VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
			return true
		end

		local function ReadPoints()
			local hud = GetHUD()
			if not hud then return "N/A" end
			local lbl = hud.Main
				and hud.Main.Frame_RandomItem
				and hud.Main.Frame_RandomItem.DisplayFrame
				and hud.Main.Frame_RandomItem.DisplayFrame:FindFirstChild("PointLabel")
			return lbl and lbl.Text or "N/A"
		end

		-- ===== STATE =====
		local State = {
			-- Random
			running = false,
			mode = "x15",
			count = 0,
			delay = 0.5,
			-- Shop
			selectedItem = nil,
			autoShop = false,
			itemList = {},
		}

		-- ===== RANDOM =====
		local function StopRandom()
			State.running = false
		end

		local function StartRandom()
			if State.running then return end
			State.running = true
			State.count = 0
			NeoUI.Notify:Show({
				Title = "▶️ Auto " .. State.mode,
				Description = "Delay " .. State.delay .. "s",
				Duration = 2,
			})
			task.spawn(function()
				while State.running do
					local btn = FindPath("Main.Frame_RandomItem.DisplayFrame." .. State.mode)
					if btn then
						ClickButton(btn)
						State.count = State.count + 1
					end
					task.wait(State.delay)
				end
			end)
		end

		-- ===== QUÉT ITEM TRONG ItemScrollingFrame =====
		local function ScanItems()
			State.itemList = {}
			local hud = GetHUD()
			if not hud then return 0 end

			local scroll = hud.Main
				and hud.Main.Frame_RandomItem
				and hud.Main.Frame_RandomItem:FindFirstChild("ItemScrollingFrame")
			if not scroll then return 0 end

			for _, child in ipairs(scroll:GetChildren()) do
				if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("ImageButton") then
					-- Tìm nút Main bên trong
					local mainBtn = child:FindFirstChild("Main")
					if not mainBtn then
						-- Fallback: tìm button đầu tiên
						mainBtn = child:FindFirstChildWhichIsA("TextButton")
							or child:FindFirstChildWhichIsA("ImageButton")
					end

					if mainBtn then
						table.insert(State.itemList, {
							name = child.Name,
							button = mainBtn,
							frame = child,
						})
					end
				end
			end
			return #State.itemList
		end

		-- ===== CHỌN ITEM =====
		local function SelectItem(name)
			for _, item in ipairs(State.itemList) do
				if item.name:lower() == name:lower() then
					State.selectedItem = item.name
					ClickButton(item.button)
					NeoUI.Notify:Show({
						Title = "✅ Chọn: " .. item.name,
						Duration = 2,
					})
					return true
				end
			end
			return false
		end

		-- ===== UI =====
		local Sec = Tab:CreateSection("🎰 Random & Shop")

		Sec:Paragraph({
			Title = "Cách dùng",
			Content = "Bên trái: chọn mốc quay (5/10/15) → BẮT ĐẦU.\nBên phải: chọn item + BẬT Auto đổi.\n\nMở panel Random Item trong game trước.",
		})

		local MainRow = Sec:TwoColumn()

		-- ⭐ CỘT TRÁI: RANDOM
		local RandomInfo = MainRow.Left:ListRow({
			Title = "🎰 Random",
			Items = {
				{ key = "Trạng thái", value = "❌ Dừng" },
				{ key = "Mốc", value = "x15" },
				{ key = "Đã quay", value = "0" },
				{ key = "Points", value = "N/A" },
			},
		})

		local modeBox = MainRow.Left:Textbox({
			Title = "Mốc (5/10/15)",
			Placeholder = "15",
			Value = "15",
		})

		MainRow.Left:Button({
			Title = "▶️ BẮT ĐẦU",
			Callback = function()
				local v = tonumber(modeBox:Get()) or 15
				if v == 5 then State.mode = "x5"
				elseif v == 10 then State.mode = "x10"
				else State.mode = "x15" end
				StartRandom()
			end,
		})
		MainRow.Left:Button({
			Title = "⏹️ DỪNG",
			Callback = function()
				StopRandom()
				NeoUI.Notify:Show({ Title = "⏹️ Đã dừng Random", Duration = 2 })
			end,
		})

		local delayBox = MainRow.Left:Textbox({
			Title = "Delay (s)",
			Placeholder = "0.5",
			Value = "0.5",
			Callback = function(v)
				local n = tonumber(v) or 0.5
				State.delay = math.clamp(n, 0.1, 5)
			end,
		})

		-- ⭐ CỘT PHẢI: SHOP
		local ShopInfo = MainRow.Right:ListRow({
			Title = "🛒 Shop Item",
			Items = {
				{ key = "Đang chọn", value = "-" },
				{ key = "Auto đổi", value = "❌ Tắt" },
				{ key = "Số item", value = "0" },
			},
		})

		local shopInput = MainRow.Right:Textbox({
			Title = "Tên item (VD: Wood)",
			Placeholder = "Wood",
			Value = "",
		})

		MainRow.Right:Button({
			Title = "✅ Chọn item",
			Callback = function()
				local name = shopInput:Get()
				if name == "" then
					NeoUI.Notify:Show({ Title = "❌ Nhập tên item", Duration = 2 })
					return
				end
				if #State.itemList == 0 then
					ScanItems()
				end
				if not SelectItem(name) then
					NeoUI.Notify:Show({
						Title = "❌ Không tìm thấy",
						Description = "Item: " .. name,
						Duration = 2,
					})
				end
			end,
		})

		local autoShopState = false
		MainRow.Right:Toggle({
			Title = "Auto đổi Shop",
			Value = false,
			Callback = function(v)
				autoShopState = v
				State.autoShop = v
				if v then
					NeoUI.Notify:Show({
						Title = "✅ Auto Shop ON",
						Description = "Tự đổi item mỗi 3s",
						Duration = 2,
					})
				else
					NeoUI.Notify:Show({ Title = "❌ Auto Shop OFF", Duration = 2 })
				end
			end,
		})

		MainRow.Right:Button({
			Title = "🔄 Quét lại",
			Callback = function()
				local n = ScanItems()
				NeoUI.Notify:Show({
					Title = "Đã quét",
					Description = "Tìm thấy " .. n .. " item",
					Duration = 2,
				})
			end,
		})

		-- ===== AUTO SHOP LOOP =====
		task.spawn(function()
			while true do
				task.wait(3)
				if State.autoShop and State.selectedItem then
					SelectItem(State.selectedItem)
				end
			end
		end)

		-- ===== AUTO REFRESH STATUS =====
		task.spawn(function()
			while true do
				task.wait(1)
				pcall(function()
					RandomInfo:UpdateItem("Trạng thái", State.running and "✅ Đang chạy" or "❌ Dừng")
					RandomInfo:UpdateItem("Mốc", State.mode)
					RandomInfo:UpdateItem("Đã quay", tostring(State.count))
					RandomInfo:UpdateItem("Points", ReadPoints())

					ShopInfo:UpdateItem("Đang chọn", State.selectedItem or "-")
					ShopInfo:UpdateItem("Auto đổi", State.autoShop and "✅ Bật" or "❌ Tắt")
					ShopInfo:UpdateItem("Số item", tostring(#State.itemList))
				end)
			end
		end)

		-- Quét item lần đầu
		task.spawn(function()
			task.wait(0.8)
			ScanItems()
		end)

		NeoUI.Notify:Show({
			Title = "✅ Random & Shop",
			Description = "Mở panel Random game để quét item",
			Duration = 3,
		})
	end,
}
