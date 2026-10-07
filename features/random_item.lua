-- =========================================================
--  FEATURE: Random Item — Auto Open x5/x10/x15
--  Cấu trúc game:
--    HUD.Main.Frame_RandomItem.DisplayFrame.x5 / x10 / x15
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

		local function OpenRandomPanel()
			-- Tìm nút mở panel Random (thường nằm đâu đó trong HUD)
			-- Nếu panel đã mở sẵn thì thôi
			local hud = GetHUD()
			if not hud then return false end
			local panel = hud.Main and hud.Main:FindFirstChild("Frame_RandomItem")
			if panel and panel.Visible then return true end

			-- Tìm button có tên liên quan
			for _, c in ipairs(hud:GetDescendants()) do
				if c:IsA("TextButton") or c:IsA("ImageButton") then
					local n = c.Name:lower()
					if n:find("randomitem") or n:find("random_item") or n:find("openrandom") then
						ClickButton(c)
						task.wait(0.3)
						return true
					end
				end
			end
			return false
		end

		local OpenState = {
			running = false,
			mode = nil,     -- "x5" / "x10" / "x15"
			loopThread = nil,
			count = 0,
		}

		local function StopLoop()
			OpenState.running = false
			OpenState.mode = nil
			OpenState.count = 0
		end

		local function StartLoop(mode)
			if OpenState.running then
				StopLoop()
				task.wait(0.3)
			end

			-- Đảm bảo panel mở
			if not OpenRandomPanel() then
				NeoUI.Notify:Show({
					Title = "❌ Không tìm thấy panel",
					Description = "Mở Random Item trong game thủ công",
					Duration = 3,
				})
				return
			end

			OpenState.running = true
			OpenState.mode = mode
			OpenState.count = 0

			NeoUI.Notify:Show({
				Title = "▶️ Bắt đầu Auto " .. mode,
				Description = "Đang quay...",
				Duration = 2,
			})

			OpenState.loopThread = task.spawn(function()
				while OpenState.running do
					local btn = FindPath("Main.Frame_RandomItem.DisplayFrame." .. mode)
					if not btn then
						warn("[RandomItem] Không tìm thấy nút", mode)
						task.wait(0.5)
					else
						ClickButton(btn)
						OpenState.count = OpenState.count + 1
					end
					task.wait(0.5)  -- Delay giữa các lần quay
				end
			end)
		end

		-- ===== UI =====
		local Sec = Tab:CreateSection("🎰 Random Item")

		Sec:Paragraph({
			Title = "Cách dùng",
			Content = "Bấm x5/x10/x15 để bắt đầu quay liên tục.\nBấm lại để dừng.\nPanel Random Item sẽ tự mở nếu chưa mở.",
		})

		local statusRow = Sec:ListRow({
			Title = "Trạng thái",
			Items = {
				{ key = "Đang chạy", value = "Không" },
				{ key = "Chế độ", value = "-" },
				{ key = "Số lần quay", value = "0" },
				{ key = "Points", value = "N/A" },
			},
		})

		-- Nút x5 / x10 / x15
		local btnRow = Sec:TwoColumn()

		local function makeToggle(mode, label)
			return function()
				if OpenState.running and OpenState.mode == mode then
					-- Đang chạy mode này → dừng
					StopLoop()
					NeoUI.Notify:Show({
						Title = "⏸️ Đã dừng",
						Description = "Dừng quay " .. mode,
						Duration = 2,
					})
				else
					-- Chạy mode mới (dừng mode cũ nếu có)
					StartLoop(mode)
				end
			end
		end

		btnRow.Left:Button({ Title = "🎰 Open x5", Callback = makeToggle("x5") })
		btnRow.Right:Button({ Title = "🎰 Open x10", Callback = makeToggle("x10") })

		Sec:Button({ Title = "🎰 Open x15", Callback = makeToggle("x15") })
		Sec:Button({
			Title = "⏹️ Dừng quay",
			Callback = function()
				if OpenState.running then
					StopLoop()
					NeoUI.Notify:Show({ Title = "⏹️ Đã dừng", Duration = 2 })
				end
			end,
		})

		-- Auto refresh status
		task.spawn(function()
			while true do
				task.wait(1)
				local pcallOK = pcall(function()
					local runningText = OpenState.running and "✅ Có" or "❌ Không"
					local modeText = OpenState.mode or "-"
					statusRow:UpdateItem("Đang chạy", runningText)
					statusRow:UpdateItem("Chế độ", modeText)
					statusRow:UpdateItem("Số lần quay", tostring(OpenState.count))
					statusRow:UpdateItem("Points", ReadPoints())
				end)
			end
		end)

		NeoUI.Notify:Show({
			Title = "✅ Random Item",
			Description = "Chọn x5/x10/x15 để bắt đầu",
			Duration = 3,
		})
	end,
}
