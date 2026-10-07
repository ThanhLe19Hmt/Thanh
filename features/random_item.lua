-- =========================================================
--  FEATURE: Random & Shop (gộp) v3
--  - Dropdown item động (quét từ game)
--  - Toggle BẮT ĐẦU/DỪNG
--  - Delay cố định 0.5s
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
			running = false,
			mode = "x15",
			count = 0,
			selectedItem = nil,
			autoShop = false,
			itemList = {},
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
					Description = "Delay " .. DELAY .. "s",
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
				if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("ImageButton") then
					local mainBtn = child:FindFirstChild("Main")
					if not mainBtn then
						mainBtn = child:FindFirstChildWhichIsA("TextButton")
							or child:FindFirstChildWhichIsA("ImageButton")
					end
					if mainBtn then
						table.insert(State.itemList, {
							name = child.Name,
							button = mainBtn,
							frame = child,
						})
						table.insert(names, child.Name)
					end
				end
			end

			table.sort(names)
			return names
		end

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
			Content = "Bên trái: chọn mốc + BẬT quay.\nBên phải: chọn item + Auto đổi.\nMở panel Random Item trong game trước.",
		})

		local MainRow = Sec:TwoColumn()

		-- ===== CỘT TRÁI: RANDOM =====
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

		-- ===== CỘT PHẢI: SHOP =====
		local ShopInfo = MainRow.Right:ListRow({
			Title = "🛒 Shop Item",
			Items = {
				{ key = "Đang chọn", value = "-" },
				{ key = "Auto đổi", value = "❌ Tắt" },
				{ key = "Số item", value = "0" },
			},
		})

		-- ⭐ DROPDOWN item động
		local itemDropdown = MainRow.Right:Dropdown({
			Title = "Chọn Item",
			Options = { "Đang quét..." },
			Value = nil,
			Callback = function(v)
				if v and v ~= "Đang quét..." then
					SelectItem(v)
				end
			end,
		})

		-- Auto quét lại mỗi 5s
		task.spawn(function()
			task.wait(1)
			while true do
				local names = ScanItems()
				if #names > 0 and itemDropdown and itemDropdown.Refresh then
					itemDropdown:Refresh(names, true)
				end
				task.wait(5)
			end
		end)

		-- Auto đổi toggle
		MainRow.Right:Toggle({
			Title = "Auto đổi Shop",
			Value = false,
			Callback = function(v)
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

		NeoUI.Notify:Show({
			Title = "✅ Random & Shop",
			Description = "Đang quét item từ game...",
			Duration = 3,
		})
	end,
}
