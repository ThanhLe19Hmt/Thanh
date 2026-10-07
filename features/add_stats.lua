-- =========================================================
--  FEATURE: Add Stats
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

		local STAT_PATHS = {
			Melee = "Main.Frame_Stats.Stats.Frame.Melee.Plus",
			Defense = "Main.Frame_Stats.Stats.Frame.Defense.Plus",
			Sword = "Main.Frame_Stats.Stats.Frame.Sword.Plus",
			Power = "Main.Frame_Stats.Stats.Frame.Power.Plus",
		}

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

		local function SetStatAmount(amount)
			local hud = GetHUD()
			if not hud then return false end
			local box = hud.Main
				and hud.Main.Frame_Stats
				and hud.Main.Frame_Stats.Stats
				and hud.Main.Frame_Stats.Stats.Box
				and hud.Main.Frame_Stats.Stats.Box:FindFirstChild("TextBox")
			if not box then return false end
			box:CaptureFocus()
			task.wait(0.05)
			box.Text = tostring(amount)
			task.wait(0.05)
			box:ReleaseFocus()
			task.wait(0.05)
			return true
		end

		local ADD_AMOUNT = 1000

		local function IncreaseStat(name)
			local btn = STAT_PATHS[name] and FindPath(STAT_PATHS[name])
			if not btn then
				NeoUI.Notify:Show({
					Title = "❌ Không tìm thấy nút",
					Description = "Mở bảng Stats game trước",
					Duration = 3,
				})
				return
			end
			if not SetStatAmount(ADD_AMOUNT) then
				NeoUI.Notify:Show({ Title = "❌ Lỗi TextBox", Duration = 3 })
				return
			end
			task.wait(0.15)
			ClickButton(btn)
			NeoUI.Notify:Show({
				Title = "✅ Cộng " .. name,
				Description = "+" .. ADD_AMOUNT,
				Duration = 2,
			})
		end

		local Sec = Tab:CreateSection("📊 Cộng Stats")

		Sec:Paragraph({
			Title = "Cách dùng",
			Content = "Bấm [+] để cộng " .. ADD_AMOUNT .. " điểm.\nMở bảng Stats trong game trước.",
		})

		local cols = Sec:TwoColumn()

		cols.Left:StatRow({
			Key = "Melee", Value = "...",
			OnAdd = function() IncreaseStat("Melee") end,
		})
		cols.Left:StatRow({
			Key = "Defense", Value = "...",
			OnAdd = function() IncreaseStat("Defense") end,
		})
		cols.Right:StatRow({
			Key = "Sword", Value = "...",
			OnAdd = function() IncreaseStat("Sword") end,
		})
		cols.Right:StatRow({
			Key = "Power", Value = "...",
			OnAdd = function() IncreaseStat("Power") end,
		})

		NeoUI.Notify:Show({
			Title = "✅ Add Stats",
			Description = "Đã mở",
			Duration = 3,
		})
	end,
}
