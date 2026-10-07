-- =========================================================
--  FEATURE: Random & Shop v7 (Viết lại hoàn toàn)
--  Quét item trực tiếp từ ItemScrollingFrame
-- =========================================================
return {
	Run = function(NeoUI, Tab)
		local Players = game:GetService("Players")
		local LP = Players.LocalPlayer
		local VIM = game:GetService("VirtualInputManager")

		local DELAY = 0.5

		-- =========================================================
		--  HELPERS
		-- =========================================================
		local function GetHUD()
			return LP.PlayerGui:FindFirstChild("HUD")
		end

		-- Lấy ItemScrollingFrame trong panel Random
		local function GetScrollFrame()
			local hud = GetHUD()
			if not hud then return nil end
			local main = hud:FindFirstChild("Main")
			if not main then return nil end
			local ri = main:FindFirstChild("Frame_RandomItem")
			if not ri then return nil end
			return ri:FindFirstChild("ItemScrollingFrame")
		end

		-- Đọc Points từ panel
		local function ReadPoints()
			local hud = GetHUD()
			if not hud then return "N/A" end
			local ri = hud.Main and hud.Main:FindFirstChild("Frame_RandomItem")
			if not ri then return "N/A" end
			local df = ri:FindFirstChild("DisplayFrame")
			if not df then return "N/A" end
			local pl = df:FindFirstChild("PointLabel")
			return pl and pl.Text or "N/A"
		end

		-- Click button: firesignal + VIM
		local function ClickButton(btn)
			if not btn then return false end
			
			-- Thử firesignal
			if firesignal then
				pcall(function() firesignal(btn.Activated) end)
				pcall(function() firesignal(btn.MouseButton1Click) end)
			end
			
			-- VIM click (chắc chắn hơn)
			local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
			VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
			task.wait(0.05)
			VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
			return true
		end

		-- =========================================================
		--  SCAN ITEMS
		-- =========================================================
		local function ScanItems()
			local list = {}
			local scroll = GetScrollFrame()
			if not scroll then 
				print("[Random] Không có ItemScrollingFrame")
				return list 
			end

			for _, child in ipairs(scroll:GetChildren()) do
				if child:IsA("Frame") then
					-- Bỏ qua Template
					if child.Name ~= "Template" 
						and child.Name ~= "ItemTemplate" 
						and not child.Name:lower():find("template") then
						
						-- Tìm nút để click bên trong
						local mainBtn = child:FindFirstChild("Main")
						
						table.insert(list, {
							name = child.Name,
							frame = child,
							button = mainBtn,
						})
					end
				end
			end

			table.sort(list, function(a, b) return a.name < b.name end)
			print("[Random] Quét được", #list, "item")
			return list
		end

		-- =========================================================
		--  STATE
		-- =========================================================
		local State = {
			running = false,
			mode = "x15",
			count = 0,
			selectedItem = nil,
			autoShop = false,
			itemList = {},
			lastListKey = "",
		}

		-- =========================================================
		--  RANDOM
		-- =========================================================
		local function GetRandomButton(mode)
			local hud = GetHUD()
			if not hud then return nil end
			local df = hud.Main 
				and hud.Main.Frame_RandomItem 
				and hud.Main.Frame_RandomItem.DisplayFrame
			if not df then return nil end
			return df:FindFirstChild(mode)
		end

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
					local btn = GetRandomButton(State.mode)
					if btn then
						ClickButton(btn)
						State.count = State.count + 1
					else
						print("[Random] Không tìm thấy nút", State.mode)
					end
					task.wait(DELAY)
				end
			end)
		end

		-- =========================================================
		--  SELECT ITEM
		-- =========================================================
		local function SelectItem(name)
			-- Nếu list trống → quét lại
			if #State.itemList == 0 then
				State.itemList = ScanItems()
			end

			for _, item in ipairs(State.itemList) do
				if item.name:lower() == name:lower() then
					State.selectedItem = item.name

					-- Ưu tiên click nút "Main" nếu có
					if item.button then
						print("[Random] Click vào nút Main của", item.name)
						ClickButton(item.button)
					else
						-- Không có nút Main → click thẳng frame
						print("[Random] Click thẳng vào frame", item.name)
						ClickButton(item.frame)
					end

					NeoUI.Notify:Show({
						Title = "✅ Đổi sang: " .. item.name,
						Duration = 3,
					})
					return true
				end
			end

			NeoUI.Notify:Show({
				Title = "❌ Không tìm thấy",
				Description = name,
				Duration = 2,
			})
			return false
		end

		-- =========================================================
		--  UI
		-- =========================================================
		local Sec = Tab:CreateSection("🎰 Random & Shop")

		Sec:Paragraph({
			Title = "Hướng dẫn",
			Content = "Bên trái: Random. Bên phải: đổi item.\nMở panel Random Item game trước.",
		})

		local MainRow = Sec:TwoColumn()

		-- ===== CỘT TRÁI =====
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

		-- ===== CỘT PHẢI =====
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
			Options = { "⏳ Đang quét..." },
			Value = nil,
			Callback = function(v)
				if v and v ~= "⏳ Đang quét..." and v ~= "❌ Không có item" then
					SelectItem(v)
				end
			end,
		})

		-- Auto scan mỗi 1s
		task.spawn(function()
			task.wait(0.8)
			while true do
				local list = ScanItems()
				State.itemList = list
				
				local names = {}
				for _, it in ipairs(list) do
					table.insert(names, it.name)
				end
				local key = table.concat(names, "|")
				
				if key ~= State.lastListKey and itemDropdown and itemDropdown.Refresh then
					State.lastListKey = key
					if #names > 0 then
						itemDropdown:Refresh(names, true)
					else
						itemDropdown:Refresh({ "❌ Không có item" }, false)
					end
				end
				task.wait(1)
			end
		end)

		MainRow.Right:Toggle({
			Title = "Auto đổi Shop",
			Value = false,
			Callback = function(v)
				State.autoShop = v
				NeoUI.Notify:Show({
					Title = v and "✅ Auto ON" or "❌ Auto OFF",
					Duration = 2,
				})
			end,
		})

		-- Auto shop loop
		task.spawn(function()
			while true do
				task.wait(3)
				if State.autoShop and State.selectedItem then
					SelectItem(State.selectedItem)
				end
			end
		end)

		-- Auto refresh status
		task.spawn(function()
			task.wait(0.5)
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
			Description = "Mở panel Random Item game để quét",
			Duration = 3,
		})
	end,
}
