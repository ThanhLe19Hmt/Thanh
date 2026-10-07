-- =========================================================
--  FEATURE: Add Stats
--  Có auto-refresh giá trị Stats mỗi 2s
-- =========================================================
return {
	Run = function(NeoUI, Tab)
		local Players = game:GetService("Players")
		local LP = Players.LocalPlayer
		local VIM = game:GetService("VirtualInputManager")

		local function SafeRead(gui, path, fallback)
			local ok, result = pcall(function()
				local cur = gui
				for segment in path:gmatch("[^%.]+") do
					cur = cur[segment]
					if not cur then return fallback end
				end
				return cur
			end)
			if ok and result then
				if typeof(result) == "Instance" then return result.Text or result.Name end
				return tostring(result)
			end
			return fallback
		end

		local function GetHUD() return LP.PlayerGui:FindFirstChild("HUD") end

		local function SafeUpdate(target, method, ...)
			if not target then return false end
			local fn = target[method]
			if typeof(fn) ~= "function" then return false end
			return (pcall(fn, target, ...))
		end

		local function ReadCombatStats()
			local info = { Melee="N/A", Defense="N/A", Sword="N/A", Power="N/A", Points="N/A" }
			local hud = GetHUD()
			if not hud then return info end
			info.Melee   = SafeRead(hud, "Main.Frame_Stats.Stats.Frame.Melee.Pt", "N/A")
			info.Defense = SafeRead(hud, "Main.Frame_Stats.Stats.Frame.Defense.Pt", "N/A")
			info.Sword   = SafeRead(hud, "Main.Frame_Stats.Stats.Frame.Sword.Pt", "N/A")
			info.Power   = SafeRead(hud, "Main.Frame_Stats.Stats.Frame.Power.Pt", "N/A")
			info.Points  = SafeRead(hud, "Main.Frame_Stats.Stats.TextLabel", "N/A"):gsub("Points: ", "")
			return info
		end

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

		-- ===== UI =====
		local Sec = Tab:CreateSection("📊 Combat Stats")

		Sec:Paragraph({
			Title = "Cách dùng",
			Content = "Bấm [+] để cộng " .. ADD_AMOUNT .. " điểm.\nMở bảng Stats trong game trước (nút STATS trên HUD).",
		})

		local cols = Sec:TwoColumn()

		local statMelee = cols.Left:StatRow({
			Key = "Melee", Value = "...",
			OnAdd = function() IncreaseStat("Melee") end,
		})
		local statDefense = cols.Left:StatRow({
			Key = "Defense", Value = "...",
			OnAdd = function() IncreaseStat("Defense") end,
		})
		local statSword = cols.Right:StatRow({
			Key = "Sword", Value = "...",
			OnAdd = function() IncreaseStat("Sword") end,
		})
		local statPower = cols.Right:StatRow({
			Key = "Power", Value = "...",
			OnAdd = function() IncreaseStat("Power") end,
		})

		local pointsSec = Tab:CreateSection("🎯 Điểm còn lại")
		local statPointsRow = pointsSec:ListRow({
			Title = "Points",
			Items = {
				{ key = "Points", value = "..." },
			},
		})

		-- ===== REFRESH (giá trị Stats) =====
		local function Refresh()
			local c = ReadCombatStats()
			SafeUpdate(statMelee, "SetValue", c.Melee)
			SafeUpdate(statDefense, "SetValue", c.Defense)
			SafeUpdate(statSword, "SetValue", c.Sword)
			SafeUpdate(statPower, "SetValue", c.Power)
			SafeUpdate(statPointsRow, "UpdateItem", "Points", c.Points)
		end

		-- Chạy refresh lần đầu (delay 0.3s cho UI render)
		task.wait(0.3)
		pcall(Refresh)

		-- Auto refresh mỗi 2s
		task.spawn(function()
			while true do
				task.wait(2)
				pcall(Refresh)
			end
		end)

		NeoUI.Notify:Show({
			Title = "✅ Stats",
			Description = "Tự cập nhật mỗi 2s",
			Duration = 2,
		})
	end,
}
