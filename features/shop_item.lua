-- =========================================================
--  FEATURE: Shop Item — Đổi item trong Random
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

		-- Quét các button "shop item" trong game
		-- VD: MMM, Evil Morty, Frieza, GooGooGaaGaa, Perfect Cell, ...
		local function ScanShopItems()
			local hud = GetHUD()
			if not hud then return {} end
			local list = {}

			-- Tìm trong Frame_Shop hoặc các Frame liên quan
			local shop = hud.Main and hud.Main:FindFirstChild("Frame_Shop")
			if shop then
				for _, c in ipairs(shop:GetDescendants()) do
					if c:IsA("TextButton") or c:IsA("ImageButton") then
						local label = c:FindFirstChildOfClass("TextLabel")
						local txt = label and label.Text or c.Text or c.Name
						if txt and txt ~= "" then
							table.insert(list, { name = txt, button = c })
						end
					end
				end
			end

			return list
		end

		-- UI
		local Sec = Tab:CreateSection("🛒 Shop Item")

		Sec:Paragraph({
			Title = "Cách dùng",
			Content = "Chọn category để đổi item trong Random Item.\nSẽ quét tất cả item trong Shop Item game.",
		})

		local statusRow = Sec:ListRow({
			Title = "Đang chọn",
			Items = {
				{ key = "Item", value = "-" },
			},
		})

		local listHolder = Sec:TwoColumn()

		local items = ScanShopItems()
		local itemButtons = {}

		local function SelectItem(name)
			for _, item in ipairs(items) do
				if item.name == name then
					ClickButton(item.button)
					statusRow:UpdateItem("Item", name)
					NeoUI.Notify:Show({
						Title = "✅ Đã chọn",
						Description = name,
						Duration = 2,
					})
					return
				end
			end
		end

		-- Chia items vào 2 cột
		for i, item in ipairs(items) do
			local col = (i % 2 == 1) and listHolder.Left or listHolder.Right
			col:Button({
				Title = item.name,
				Callback = function() SelectItem(item.name) end,
			})
		end

		if #items == 0 then
			Sec:Paragraph({
				Title = "Không tìm thấy Shop Item",
				Content = "Mở Shop Item trong game trước, rồi chạy lại script.",
			})
		end

		-- Nút refresh
		Sec:Button({
			Title = "🔄 Quét lại Shop Item",
			Callback = function()
				items = ScanShopItems()
				NeoUI.Notify:Show({
					Title = "Đã quét",
					Description = "Tìm thấy " .. #items .. " item",
					Duration = 2,
				})
			end,
		})

		NeoUI.Notify:Show({
			Title = "✅ Shop Item",
			Description = "Tìm thấy " .. #items .. " item",
			Duration = 3,
		})
	end,
}
