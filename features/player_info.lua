-- =========================================================
--  FEATURE: Player Info
--  Hiển thị thông tin player lên tab được truyền vào
-- =========================================================
return {
	Run = function(NeoUI, Tab)
		local Players = game:GetService("Players")
		local LP = Players.LocalPlayer

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

		local function ShortNumber(str)
			if not str or str == "N/A" then return "N/A" end
			local cur, max = str:match("^(%d+)/(%d+)$")
			if cur and max then
				local function fmt(n)
					n = tonumber(n)
					if n >= 1e9 then return string.format("%.2fB", n / 1e9) end
					if n >= 1e6 then return string.format("%.2fM", n / 1e6) end
					if n >= 1e3 then return string.format("%.1fK", n / 1e3) end
					return tostring(n)
				end
				return fmt(cur) .. " / " .. fmt(max)
			end
			return str
		end

		local function SafeUpdate(target, method, ...)
			if not target then return false end
			local fn = target[method]
			if typeof(fn) ~= "function" then return false end
			return (pcall(fn, target, ...))
		end

		local function ReadPlayerInfo()
			local info = { Level="N/A", Class="N/A", Beli="N/A", Diamond="N/A", EventStone="N/A", Bounty="N/A", Health="N/A" }
			local hud = GetHUD()
			if not hud then return info end
			info.Level = SafeRead(hud, "Main.Frame_Display.LevelText", "N/A")
			info.Class = SafeRead(hud, "Main.Frame_Display.ClassText", "N/A"):gsub("Class: ", "")
			info.Beli = SafeRead(hud, "Main.Frame_Display.Currency.Beli.BeliText", "N/A")
			info.Diamond = SafeRead(hud, "Main.Frame_Display.Currency.Diamond.DiamondText", "N/A")
			info.EventStone = SafeRead(hud, "Main.Frame_Display.Currency.Event Stone.TextLabel", "N/A")
			info.Health = ShortNumber(SafeRead(hud, "Main.Frame_Display.Healthbar.HealthText", "N/A"))
			local ls = LP:FindFirstChild("leaderstats")
			if ls then
				local b = ls:FindFirstChild("Bounty")
				if b then info.Bounty = tostring(b.Value) end
			end
			return info
		end

		local function ReadEquippedItems()
			local info = { Melee="N/A", Sword="N/A", Special="N/A", Fruit="N/A" }
			local hud = GetHUD()
			if not hud then return info end
			info.Melee   = SafeRead(hud, "Main.Frame_Stats.Stats.ScrollingFrame.Melee.Used", "N/A")
			info.Sword   = SafeRead(hud, "Main.Frame_Stats.Stats.ScrollingFrame.Sword.Used", "N/A")
			info.Special = SafeRead(hud, "Main.Frame_Stats.Stats.ScrollingFrame.Special.Used", "N/A")
			info.Fruit   = SafeRead(hud, "Main.Frame_Stats.Stats.ScrollingFrame.Fruit.Used", "N/A")
			return info
		end

		local function ReadEquipmentBonus()
			local info = { Defense="N/A", Melee="N/A", Sword="N/A", Power="N/A", Exp="N/A", Luck="N/A", Beli="N/A", Diamond="N/A" }
			local hud = GetHUD()
			if not hud then return info end
			local base = "Main.Frame_Stats.Equipment.Total.ScrollingFrame."
			info.Defense = SafeRead(hud, base .. "BoostDefense.Amount", "N/A")
			info.Melee   = SafeRead(hud, base .. "BoostMelee.Amount", "N/A")
			info.Sword   = SafeRead(hud, base .. "BoostSword.Amount", "N/A")
			info.Power   = SafeRead(hud, base .. "BoostPower.Amount", "N/A")
			info.Exp     = SafeRead(hud, base .. "BoostExp.Amount", "N/A")
			info.Luck    = SafeRead(hud, base .. "BoostLuck.Amount", "N/A")
			info.Beli    = SafeRead(hud, base .. "BoostBeli.Amount", "N/A")
			info.Diamond = SafeRead(hud, base .. "BoostDiamond.Amount", "N/A")
			return info
		end

		-- ===== UI =====
		local InfoSec = Tab:CreateSection("👤 Nhân vật")
		local charCols = InfoSec:TwoColumn()

		local charLeft = charCols.Left:ListRow({
			Title = "Tài khoản",
			Items = {
				{ key = "Name", value = LP.Name },
				{ key = "Level", value = "..." },
				{ key = "Class", value = "..." },
				{ key = "Bounty", value = "..." },
			},
		})
		local charRight = charCols.Right:ListRow({
			Title = "Tài sản",
			Items = {
				{ key = "Health", value = "..." },
				{ key = "Beli", value = "..." },
				{ key = "Diamond", value = "..." },
				{ key = "Event", value = "..." },
			},
		})

		local EquipSec = Tab:CreateSection("⚔️ Trang bị")
		local equipCols = EquipSec:TwoColumn()
		local equipLeft = equipCols.Left:ListRow({
			Title = "Vũ khí",
			Items = {
				{ key = "Melee", value = "..." },
				{ key = "Sword", value = "..." },
			},
		})
		local equipRight = equipCols.Right:ListRow({
			Title = "Other",
			Items = {
				{ key = "Special", value = "..." },
				{ key = "Fruit", value = "..." },
			},
		})

		local BonusSec = Tab:CreateSection("🎁 Equipment Bonus")
		local bonusCols = BonusSec:TwoColumn()
		local bonusLeft = bonusCols.Left:ListRow({
			Title = "Combat",
			Items = {
				{ key = "+ Defense", value = "..." },
				{ key = "+ Melee", value = "..." },
				{ key = "+ Sword", value = "..." },
				{ key = "+ Power", value = "..." },
			},
		})
		local bonusRight = bonusCols.Right:ListRow({
			Title = "Other",
			Items = {
				{ key = "+ Exp", value = "..." },
				{ key = "+ Luck", value = "..." },
				{ key = "+ Beli", value = "..." },
				{ key = "+ Diamond", value = "..." },
			},
		})

		-- Auto refresh
		local function Refresh()
			local p = ReadPlayerInfo()
			local e = ReadEquippedItems()
			local b = ReadEquipmentBonus()

			SafeUpdate(charLeft, "UpdateItem", "Name", LP.Name)
			SafeUpdate(charLeft, "UpdateItem", "Level", p.Level)
			SafeUpdate(charLeft, "UpdateItem", "Class", p.Class)
			SafeUpdate(charLeft, "UpdateItem", "Bounty", p.Bounty)

			SafeUpdate(charRight, "UpdateItem", "Health", p.Health)
			SafeUpdate(charRight, "UpdateItem", "Beli", p.Beli)
			SafeUpdate(charRight, "UpdateItem", "Diamond", p.Diamond)
			SafeUpdate(charRight, "UpdateItem", "Event", p.EventStone)

			SafeUpdate(equipLeft, "UpdateItem", "Melee", e.Melee)
			SafeUpdate(equipLeft, "UpdateItem", "Sword", e.Sword)
			SafeUpdate(equipRight, "UpdateItem", "Special", e.Special)
			SafeUpdate(equipRight, "UpdateItem", "Fruit", e.Fruit)

			SafeUpdate(bonusLeft, "UpdateItem", "+ Defense", b.Defense)
			SafeUpdate(bonusLeft, "UpdateItem", "+ Melee", b.Melee)
			SafeUpdate(bonusLeft, "UpdateItem", "+ Sword", b.Sword)
			SafeUpdate(bonusLeft, "UpdateItem", "+ Power", b.Power)

			SafeUpdate(bonusRight, "UpdateItem", "+ Exp", b.Exp)
			SafeUpdate(bonusRight, "UpdateItem", "+ Luck", b.Luck)
			SafeUpdate(bonusRight, "UpdateItem", "+ Beli", b.Beli)
			SafeUpdate(bonusRight, "UpdateItem", "+ Diamond", b.Diamond)
		end

		Refresh()
		task.spawn(function()
			while true do
				task.wait(2)
				pcall(Refresh)
			end
		end)

		NeoUI.Notify:Show({
			Title = "✅ Player Info",
			Description = "Đã mở, tự cập nhật mỗi 2s",
			Duration = 3,
		})
	end,
}
