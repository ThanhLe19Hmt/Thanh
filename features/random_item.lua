-- =========================================================
--  FEATURE: Random & Shop v6
--  - Quét item SAU KHI quay
--  - Click vào Frame item để đổi
-- =========================================================
return {
	Run = function(NeoUI, Tab)
		local Players = game:GetService("Players")
		local LP = Players.LocalPlayer
		local VIM = game:GetService("VirtualInputManager")

		local DELAY = 0.5

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

		-- ⭐ Click mạnh — thử nhiều cách
		local function ClickButton(btn)
			if not btn then return false end
			-- Cách 1: firesignal event
			if firesignal then
				pcall(function() firesignal(btn.Activated) end)
				pcall(function() firesignal(btn.MouseButton1Click) end)
				pcall(function() firesignal(btn.MouseButton1Down) end)
				pcall(function() firesignal(btn.MouseButton1Up) end)
			end
			-- Cách 2: VIM click vào tâm
			task.wait(0.05)
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

		-- ⭐ Kiểm tra panel có item không
		local function HasItems()
			local hud = GetHUD()
			if not hud then return false end
			local scroll = hud.Main
				and hud.Main.Frame_RandomItem
				and hud.Main.Frame_RandomItem:FindFirstChild("ItemScrollingFrame")
			if not scroll then return false end
			for _, c in ipairs(scroll:GetChildren()) do
				if c:IsA("Frame") then return true end
			end
			return false
		end

		-- ===== STATE =====
		local State = {
			running = false,
			mode = "x15",
			count = 0,
			selectedItem = nil,
			autoShop = false,
			itemList = {},
			lastItemNames = "",
		}

		-- ===== RANDOM =====
		local function ToggleRandom()
			if State.running then
				State.running = false
				NeoUI.Notify:Show({ Title = "⏹️ Dừng quay", Duration = 2 })
			else
				State.running = true
				State.count = 0
				NeoUI.Notify:Show({
					Title = "▶️ Bắt đầu " .. State.mode,
					Duration = 2,
				})
				task.spawn(function()
					while State.running do
						local btn = FindPath("Main.Frame_RandomItem.DisplayFrame." .. State.mode)
						if btn then
							ClickButton(btn)
							State.count = State.count + 1
						end
						task.wait(DELAY)
					end
				end)
			end
		end

		-- ===== QUÉT ITEM =====
		local function ScanItems()
			State.itemList = {}
			local hud = GetHUD()
			if not hud then return {} end

			local scroll = hud.Main
				and hud.Main.Frame_RandomItem
				and hud.Main.Frame_RandomItem:FindFirstChild("ItemScrollingFrame")
			if not scroll then return {} end

			local names = {}
			for _, child in ipairs(scroll:GetChildren()) do
				if child:IsA("Frame") then
					-- Tìm button để click — thường là "Main" hoặc chính frame
					local mainBtn = child:FindFirstChild("Main")
						or child:FindFirstChildWhichIsA("TextButton")
						or child:FindFirstChildWhichIsA("ImageButton")

					table.insert(State.itemList, {
						name = child.Name,
						button = mainBtn or child,  -- nếu không có button con, click frame
						frame = child,
					})
					table.insert(names, child.Name)
				end
			end

			table.sort(names)
			return names
		end

		-- ⭐ CHỌN ITEM — click thẳng vào frame item (vì đó là cách đổi)
		local function SelectItem(name)
			for _, item in ipairs(State.itemList) do
				if item.name:lower() == name:lower() then
					State.selectedItem = item.name

					-- Thử click button "Main" trước
					if item.button and item.button ~= item.frame then
						ClickButton(item.button)
						task.wait(0.1)
					end

					-- Nếu là frame trực tiếp, click vào tâm frame
					if item.frame then
						local pos = item.frame.AbsolutePosition + item.frame.AbsoluteSize / 2
						VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
						task.wait(0.05)
						VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
					end

					NeoUI.Notify:Show({
						Title = "✅ Đổi sang: " .. item.name,
						Description = "Đã bấm, kiểm tra game",
						Duration = 3,
					})
					print("[Random] Đã click item:", item.name)
					return true
				end
			end
			return false
		end

		-- ===== UI =====
		local Sec = Tab:CreateSection("🎰 Random & Shop")

		Sec:Paragraph({
			Title = "⚠️ Hướng dẫn",
			Content = "1. Mở panel Random Item\n2. Quay 1 lần để có list item\n3. Dropdown mới hiện item để đổi\n4. Chọn item → tự click đổi",
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

		-- ⭐ CỘT PHẢI: SHOP
		local ShopInfo = MainRow.Right:ListRow({
			Title = "🛒 Shop Item",
			Items = {
				{ key = "Đang chọn", value = "-" },
				{ key = "Auto đổi", value = "❌ Tắt" },
				{ key = "Số item", value = "0" },
			},
		})

		local itemDropdown = MainRow.Right:Dropdown({
			Title = "Đổi Item",
			Options = { "⚠️ Quay trước để có item" },
			Value = nil,
			Callback = function(v)
				if v and v ~= "⚠️ Quay trước để có item" 
					and v ~= "Đang quét..."
					and v ~= "⏳ Chưa có item" then
					SelectItem(v)
				end
			end,
		})

		-- ⭐ Auto scan mỗi 2s
		task.spawn(function()
			task.wait(1)
			while true do
				local names = ScanItems()
				local key = table.concat(names, ",")
				if key ~= State.lastItemNames then
					State.lastItemNames = key
					if #names > 0 then
						if itemDropdown and itemDropdown.Refresh then
							itemDropdown:Refresh(names, true)
						end
					else
						if itemDropdown and itemDropdown.Refresh then
							itemDropdown:Refresh({ "⏳ Chưa có item" }, false)
						end
					end
				end
				task.wait(2)
			end
		end)

		MainRow.Right:Toggle({
			Title = "Auto đổi Shop",
			Value = false,
			Callback = function(v)
				State.autoShop = v
				NeoUI.Notify:Show({
					Title = v and "✅ Auto Shop ON" or "❌ Auto Shop OFF",
					Description = v and "Tự đổi mỗi 3s" or "",
					Duration = 2,
				})
			end,
		})

		-- AUTO SHOP LOOP
		task.spawn(function()
			while true do
				task.wait(3)
				if State.autoShop and State.selectedItem then
					SelectItem(State.selectedItem)
				end
			end
		end)

		-- AUTO REFRESH STATUS
		task.spawn(function()
			task.wait(1)
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

		NeoUI.Notify:Show({
			Title = "✅ Random & Shop",
			Description = "Quay 1 lần để có item",
			Duration = 3,
		})
	end,
}
