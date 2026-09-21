repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer and game.Players.LocalPlayer.Character
if game.PlaceId == 119091355492870 then
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character
local Npc_Quest = workspace:WaitForChild("NpcQuest")
local Itemdrops = workspace:WaitForChild("Itemdrops")
local UseItems = require(ReplicatedStorage.Modules.UseItems)
local Quest_Module = require(ReplicatedStorage.Modules.QuestModule)
local ItemList = require(ReplicatedStorage.Modules.Itemlist)
local SpawnBossList =require(ReplicatedStorage.Modules.SpawnBossList)
local Blacklist = require(ReplicatedStorage.Modules.BlacklistItemTrade)
local AccessoryModule = require(ReplicatedStorage.Modules.AccessoryModule)
local PointItemM = require(ReplicatedStorage.Modules.GaranteeRandomItem)
local PointItemMoon = require(ReplicatedStorage.Modules.GaranteeEventMoon)
local Economy = require(ReplicatedStorage.Modules.Economy)
local Codes = {"Mambo","MiniUpdate2","OmniMan","UPDATE1","SorryForDelay1","Lucy","Luck"}
local TypeTool = {"Melee","Sword","Special","DevilFruit"}
local RandomChestValue = {"x5","x10","x15"}
local Quest_List = {}
local WeaponAll = {}
local MonsterDrop = {}
local ItemDrop = {}
local ItemToMob = {}
local ItemAll = {}
local X2List = {}
local Poitem = {}
local PoiteMoon = {}
local SellItems = {}
local Bosses = {}
local CachedInventory = {}
local LastCraft = 0
local CraftDelay = 1
local LastInventory = 0
local NotifyCraft = false
local Connection
local MethodFarm
local SpawnList = {
	["Thief"] = "Bacon Thief",
	["Piccolo"] = "Piccolo",
	["Duck"] = "Duck Monster",
	["Devil Boat"] = "Devil Boat"
}


-- Default Global Settings
_G.MainWeapon = "Melee"
_G.Select_EquipWeapon = {}
_G.Select_Method = "Upper"
_G.Distance_Farm = 5
_G.AutoSkillZ = false
_G.AutoSkillX = false
_G.AutoSkillC = false
_G.AutoSkillV = false
_G.AutoSkillF = false
_G.Auto_Haki = false
_G.Auto_Equip_Accessory = false
_G.Auto_Rebirth = false
_G.Select_Potion = {}
_G.Auto_Use_Potion = false
_G.Auto_Farm_Level = false
_G.Select_Material = {}
_G.Auto_Farm_Material = false
_G.Select_Boss = nil
_G.Auto_FarmBoss = false
_G.Auto_FarmBoss_Automatically = false
_G.Auto_BaconThief = false
_G.Auto_Piccolo = false
_G.Auto_Duck = false
_G.Auto_DevilBoat = false
_G.Auto_DuckAutomatically = false
_G.Select_Item = nil
_G.Auto_CraftWeapon = false
_G.Auto_Farm_Set = false
_G.Auto_Raid = false
_G.Dungeon_UseValue = 1
_G.HealthPercent = 30
_G.Auto_Dungeon = false
_G.Select_SellItem = {}
_G.Auto_SellItem = false
_G.Amount = 1000
_G.AutoMelee = false
_G.AutoDefense = false
_G.AutoSword = false
_G.AutoPower = false
_G.Select_Random = "x5"
_G.Auto_RandomChest = false
_G.Select_Random_Moon = "x5"
_G.Auto_RandomChest_Moon = false
_G.Select_Guarantee = nil
_G.Auto_Guarantee = false
_G.Select_Guarantee_Moon = nil
_G.Auto_Guarantee_Moon = false

for ItemName in pairs(Economy) do
	table.insert(SellItems,ItemName)
end
table.sort(SellItems)

local AutoSkill = function()
	local Character = LocalPlayer.Character
	if not Character then return end
	local Skills = {}
	if _G.AutoSkillZ then table.insert(Skills,"z") end
	if _G.AutoSkillX then table.insert(Skills,"x") end
	if _G.AutoSkillC then table.insert(Skills,"c") end
	if _G.AutoSkillV then table.insert(Skills,"v") end
	if _G.AutoSkillF then table.insert(Skills,"f") end
	if #Skills == 0 then return end
	local Skill = Skills[math.random(#Skills)]
	for _,Tool in ipairs(Character:GetChildren()) do
		if Tool:IsA("Tool") then
			ReplicatedStorage.Remotes.Action:FireServer(Tool.Name,Skill)
		end
	end
end

local NoVFX = function(State)
	if State then
		workspace:WaitForChild("VFX"):ClearAllChildren()
		Connection = workspace:WaitForChild("VFX").DescendantAdded:Connect(function(v)
			pcall(function()
				v:Destroy()
			end)
		end)
	else
		if Connection then
			Connection:Disconnect()
			Connection = nil
		end
	end
end

for Item,Price in pairs(PointItemM) do
	table.insert(Poitem,{Name = Item,Price = Price})
end
table.sort(Poitem,function(a,b)
	return a.Price < b.Price
end)
for i,Data in ipairs(Poitem) do
	Poitem[i] = Data.Name.." / "..Data.Price.." Point"
end

for Item,Price in pairs(PointItemMoon) do
	table.insert(PoiteMoon,{Name = Item,Price = Price})
end
table.sort(PoiteMoon,function(a,b)
	return a.Price < b.Price
end)
for i,Data in ipairs(PoiteMoon) do
	PoiteMoon[i] = Data.Name.." / "..Data.Price.." Point"
end

table.sort(Quest_Module,function(a,b)
	return a.Level < b.Level
end)
for i,data in ipairs(Quest_Module) do
	local NPC = Npc_Quest:WaitForChild("NPC_Quest"..i)
	Quest_List[i] = {
		Level = data.Level,
		Monster = NPC:GetAttribute("Name"),
		Quest = NPC
	}
end
local GetQuest_Level = function(My_level)
	local Quest
	for _,v in ipairs(Quest_List) do
		if My_level >= v.Level then
			Quest = v
		else
			break
		end
	end
	return Quest
end

local GetQuestFrame = function()
	return LocalPlayer.PlayerGui.HUD.Main.Frame_Quest
end

local GetInventory = function()
	if tick() - LastInventory < 0.2 then
		return CachedInventory
	end
	LastInventory = tick()
	local Success,Inv = pcall(function()
		return HttpService:JSONDecode(LocalPlayer:GetAttribute("Inventory") or "{}")
	end)
	CachedInventory = Success and Inv or {}
	return CachedInventory
end

local GetItemAmount = function(ItemName)
	local Inv = GetInventory()
	return (Inv[ItemName] and Inv[ItemName].amount) or 0
end

local Teleport = function(Pos)
	local Character = LocalPlayer.Character
	if Character then
		Character:PivotTo(Pos)
	end
end

for Weapon in pairs(UseItems) do
	table.insert(WeaponAll,Weapon)
end
table.sort(WeaponAll)

for ItemName in pairs(Blacklist) do
	if ItemName:find("X2") then
		table.insert(X2List,ItemName)
	end
end

for _,Mob in ipairs(Itemdrops:GetChildren()) do
	local ScrollingFrame = Mob:FindFirstChild("ScrollingFrame",true)
	if ScrollingFrame then
		MonsterDrop[Mob.Name] = {}
		for _,v in ipairs(ScrollingFrame:GetDescendants()) do
			if v:IsA("TextLabel") and not v.Text:find("%%") then
				MonsterDrop[Mob.Name][v.Text] = true
				ItemDrop[v.Text] = ItemDrop[v.Text] or {}
				table.insert(ItemDrop[v.Text],Mob.Name)
				ItemToMob[v.Text] = Mob.Name
			end
		end
	end
end

for ItemName in pairs(ItemToMob) do
	local Data = ItemList[ItemName]
	if not (Data and Data.Type == "Accessory") then
		table.insert(ItemAll,ItemName)
	end
end
table.sort(ItemAll)

local GetNeed = function(ItemName)
	local Inv = GetInventory()
	local Data = UseItems[ItemName]
	if not Data then
		return ItemName
	end
	for Item,Need in pairs(Data.Inventory) do
		local Have = Inv[Item] and Inv[Item].amount or 0
		if Have < Need then
			if UseItems[Item] then
				return GetNeed(Item)
			end
			return Item
		end
	end
	local HaveWeapon = Inv[ItemName] and (Inv[ItemName].amount or 0) > 0
	if not HaveWeapon then
		return ItemName
	end
	return nil
end

local CraftNotify = function(Title,Content)
	if NotifyCraft then return end
	NotifyCraft = true
	Library:Notify({
		Title = Title,
		Description = Content,
		Duration = 5
	})
	task.delay(5,function()
		NotifyCraft = false
	end)
end

for BossName in pairs(SpawnBossList) do
	table.insert(Bosses,BossName)
end
table.sort(Bosses)

local GetNeedMonster = function()
	local Need = GetNeed(_G.Select_Item)
	if not Need then
		NotifyCraft = false
		return nil
	end
	if UseItems[Need] then
		local Inv = GetInventory()
		if not (Inv[Need] and (Inv[Need].amount or 0) > 0) then
			local Data = UseItems[Need]
			if not Data then
				CraftNotify("Craft Failed ❌","ไม่สามารถคราฟ "..Need.." ได้")
				return false
			end
			local CanCraft = true
			for Item,Amount in pairs(Data.Inventory) do
				local Have = Inv[Item] and Inv[Item].amount or 0
				if Have < Amount then
					CanCraft = false
					break
				end
			end
			if CanCraft and tick() - LastCraft >= CraftDelay then
				LastCraft = tick()
				ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"Craft",Need,Data.Type)
				task.wait(0.5)
			end
		end
		return GetNeedMonster()
	end
	for Monster,Drops in pairs(MonsterDrop) do
		if Drops[Need] then
			return Monster
		end
	end
	CraftNotify("Craft Failed ❌","ไม่พบ Monster ที่ดรอป "..Need)
	return false
end

local EquipWeapon = function()
	for _,v in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
		if v:IsA("Tool") and v:GetAttribute("Type") ~= _G.MainWeapon then
			v.Parent = game.Players.LocalPlayer.Backpack
		end
	end
	for _,v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
		if v:IsA("Tool") and v:GetAttribute("Type") == _G.MainWeapon then
			game.Players.LocalPlayer.Character.Humanoid:EquipTool(v)
			break
		end
	end
	for _,v in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
		if v:IsA("Tool") and v:GetAttribute("Type") ~= _G.MainWeapon and not table.find(_G.Select_EquipWeapon or {},v:GetAttribute("Type")) then
			v.Parent = game.Players.LocalPlayer.Backpack
		end
	end
	for _,v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
		if v:IsA("Tool") and v:GetAttribute("Type") ~= _G.MainWeapon and table.find(_G.Select_EquipWeapon or {},v:GetAttribute("Type")) then
			v.Parent = game.Players.LocalPlayer.Character
		end
	end
end
local Attack = function()
	local Character = LocalPlayer.Character
	if not Character then return end
	for _,v in pairs(Character:GetChildren()) do
		if v:IsA("Tool") then
			ReplicatedStorage.Remotes.Action:FireServer(v.Name,"hit")
		end
	end
end



LocalPlayer.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/znesr99/gui/refs/heads/main/MarvenRizLib.lua"))()
local MySaveManager = Library.SaveManager
-- ===== DEBUG START =====
task.spawn(function()
	local dem = 0
	while task.wait(2) do
		dem = dem + 1
		print("[DEBUG #" .. dem .. "] AutoRaidRunning =", _G.AutoRaidRunning, "| AutoRaidWho =", _G.AutoRaidWho)
	end
end)
-- ===== DEBUG END =====
local Window = Library:CreateWindow({
    Title = "MarvenRiz Hub",
    Subtitle = "Map : Rock Fruit",
    Size = UDim2.fromOffset(500, 370),
    AccentColor = Color3.fromRGB(50, 150, 255),
    SideBarWidth = 120,
    Logo = "rbxassetid://87526284179554",
    LogoSize = 32,
    SphereText = false,
    SphereImage = "rbxassetid://87526284179554",
    SphereIconSize = 38,
    Map = "RockFruit"
})

local Tab1 = Window:CreateTab("Settings", true, false)
local Tab_Page1 = Tab1:CreatePage("Main Settings")
local Weapon = Tab_Page1:CreateSection("🗡️ Select Weapon","Left")
local AutoSkills = Tab_Page1:CreateSection("⚔️ Auto Skills","Left")
local Method = Tab_Page1:CreateSection("🎯 Select Method Farm","Right")
local Haki = Tab_Page1:CreateSection("👁️ Haki","Right")
local VFX = Tab_Page1:CreateSection("✨ VFX","Right")
local Tab_Page2 = Tab1:CreatePage("Other Settings")
local Accessory = Tab_Page2:CreateSection("🎒 Accessory & Rebirth","Right")
local Potion = Tab_Page2:CreateSection("🧪 Auto Use X2 Potion","Left")

local Tab2 = Window:CreateTab("Main", false, false)
local Farm = Tab2:CreatePage("Farm")
local AllBoss = Tab2:CreatePage("Boss")
local RaidBossPage = Tab2:CreatePage("Raid Boss & Shop!!")
local RaidDun = Tab2:CreatePage("Dungeon, Shop / Weapon")
local ShopDunCard = RaidDun:CreateSection("🏪 Shop Dungeon","Left")
local ShopDunInfoCard = RaidDun:CreateSection("📊 Shop Dungeon Info","Right")
local AutoFarmCard = Farm:CreateSection("🌾 Auto Farm","Left")
local MaterialCard = Farm:CreateSection("⛏️ Auto Farm Material","Right")
local Boss = AllBoss:CreateSection("👹 Boss","Left")
local Thief = AllBoss:CreateSection("💸 Thief","Left")
local Piccolo = AllBoss:CreateSection("🐉 Piccolo","Left")
local SpawnedT = AllBoss:CreateSection("🔍 Spawned Check","Right")
local Duck = AllBoss:CreateSection("🦆 Duck","Right")
local DevilBoat = AllBoss:CreateSection("⛵ Devil Boat","Right")
local WeaponCraft = RaidDun:CreateSection("🔨 Weapon","Right")
local RaidCard = RaidDun:CreateSection("🌋 Raid","Left")
local DungeonCard = RaidDun:CreateSection("🏰 Dungeon","Left")
local RaidBossCard = RaidBossPage:CreateSection("⚔️ Auto Raid Boss","Left")
local RaidBossInfoCard = RaidBossPage:CreateSection("📋 Raid Info","Right")
local ShopRaidCard = RaidBossPage:CreateSection("🏪 Shop Raid","Left")
local ShopRaidInfoCard = RaidBossPage:CreateSection("📊 Shop Info","Right")

local Tab3 = Window:CreateTab("Other", false, false)
local SItem = Tab3:CreatePage("Sell Item / Status")
local RandomM = Tab3:CreatePage("Random Chest")
local SellCard = SItem:CreateSection("💰 Auto Sell","Left")
local StatusCard = SItem:CreateSection("📊 Status","Right")
local DiamondChest =RandomM:CreateSection("💎 Diamond Chest","Right")
local GuaranteeDiamond = RandomM:CreateSection("🎖️ Guarantee Gem Point","Right")
local MoonChest = RandomM:CreateSection("🌙 Moon Chest","Left")
local GuaranteeMoon = RandomM:CreateSection("☄️ Guarantee Moon Point","Left")

local ConfigTab = Window:CreateTab("Config", false, false)
-- ===== AUTO RAID BOSS UI =====
local RaidBossData = {
	["Bacon of Grudge"] = {
		Name = "Bacon of Grudge",
		Reward = "Time Mystery Box x5, 7500 Diamond, Beli 50M, x3 Potion, Rroll Class + Raid Poiton x1",
		PortalCost = 1,
		Valid = true,
	},
	["??? (Raid 2)"] = {
		Name = "???",
		Reward = "SOON!! AND Just wait.",
		PortalCost = 0,
		Valid = false,
	},
	["??? (Raid 3)"] = {
		Name = "???",
		Reward = "SOON!! AND Just wait.",
		PortalCost = 0,
		Valid = false,
	},
}

_G.AutoRaidWho = nil
_G.AutoRaidRunning = false

-- Info Paragraph
local RaidBossInfo = RaidBossInfoCard:Paragraph({
	Title = "Name: ( chưa chọn )",
	Content = "Please choose a Boss Raid!!"
})

-- Dropdown chọn Raid
RaidBossCard:Dropdown({
	Title = "Auto Raid Who??",
	Options = {"Bacon of Grudge", "??? (Raid 2)", "??? (Raid 3)"},
	Multi = false,
	Callback = function(Value)
		_G.AutoRaidWho = Value
		local Data = RaidBossData[Value]
		if Data then
			RaidBossInfo:SetTitle("Name: " .. Data.Name)
			RaidBossInfo:SetContent(
				"Reward: " .. Data.Reward ..
				"\n- " .. Data.PortalCost .. " Portal Gun"
			)
		end
	end
})

-- Button Start Raid
RaidBossCard:Button({
	Title = "Please choose a Boss Raid!! Which one do you want to do?",
	Callback = function()
		local Data = RaidBossData[_G.AutoRaidWho]
		if not Data then
			Library:Notify({
				Title = "❌ Chưa chọn Raid",
				Description = "Please choose a Boss Raid!! Which one do you want to do?",
				Duration = 3
			})
			return
		end
		if not Data.Valid then
			Library:Notify({
				Title = "❌ Raid không hợp lệ",
				Description = "NO RAID!!! Please select a valid cluster.",
				Duration = 3
			})
			return
		end
		_G.AutoRaidRunning = not _G.AutoRaidRunning
		Library:Notify({
			Title = _G.AutoRaidRunning and "▶️ Bắt đầu Raid" or "⏹️ Dừng Raid",
			Description = Data.Name,
			Duration = 3
		})
	end
})
-- ===== SHOP RAID UI =====
local ShopInfoPara = ShopRaidInfoCard:Paragraph({
	Title = "RaidPoint: ( đang load... )",
	Content = "Restock In: ( đang load... )"
})

local ShopItemInfo = ShopRaidInfoCard:Paragraph({
	Title = "Item: ( chưa chọn )",
	Content = "Chọn item từ dropdown để xem thông tin"
})

local SelectedShopItem = nil
local ShopItemDropdown = nil
local LastShopItemsStr = ""

local function RefreshShopDropdown(items)
	local itemsStr = table.concat(items, ",")
	if itemsStr == LastShopItemsStr and ShopItemDropdown then
		return
	end
	LastShopItemsStr = itemsStr

	if ShopItemDropdown then
		pcall(function()
			ShopItemDropdown:Destroy()
		end)
	end

	ShopItemDropdown = ShopRaidCard:Dropdown({
		Title = "Chọn item để mua",
		Options = items,
		Multi = false,
		Callback = function(Value)
			SelectedShopItem = Value
			
			local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
			if hud and hud:FindFirstChild("Main") then
				local shop = hud.Main:FindFirstChild("Frame_ShopRaid")
				if shop then
					local sf = shop:FindFirstChild("ScrollingFrame")
					if sf then
						for _, item in pairs(sf:GetChildren()) do
							if item:IsA("Frame") then
								local label = item:FindFirstChild("Label")
								if label and label.Text == Value then
									local priceLbl = item:FindFirstChild("Price")
									local amountLbl = item:FindFirstChild("Amount")
									local price = priceLbl and priceLbl.Text or "?"
									local amount = amountLbl and amountLbl.Text or "?"
									ShopItemInfo:SetTitle("Item: " .. Value)
									ShopItemInfo:SetContent(
										"Price: " .. price ..
										"\nPurchase limit: " .. amount
									)
									return
								end
							end
						end
					end
				end
			end
		end
	})
end

ShopRaidCard:Button({
	Title = "BUY!!",
	Callback = function()
		if not SelectedShopItem then
			Library:Notify({
				Title = "❌ Chưa chọn item",
				Description = "Vui lòng chọn item trước!",
				Duration = 3
			})
			return
		end

		local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
		if hud and hud:FindFirstChild("Main") then
			local shop = hud.Main:FindFirstChild("Frame_ShopRaid")
			if shop then
				local sf = shop:FindFirstChild("ScrollingFrame")
				if sf then
					for _, item in pairs(sf:GetChildren()) do
						if item:IsA("Frame") then
							local label = item:FindFirstChild("Label")
							if label and label.Text == SelectedShopItem then
								local outstock = item:FindFirstChild("Outstock")
								if outstock and outstock.Visible then
									Library:Notify({
										Title = "❌ Hết hàng",
										Description = SelectedShopItem .. " đã hết hàng!",
										Duration = 3
									})
									return
								end
								break
							end
						end
					end
				end
			end
		end

		local NetworkEvent = ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
		NetworkEvent:FireServer("fire", nil, "buy_raidshop", SelectedShopItem)
		print("[ShopRaid] BUY:", SelectedShopItem)

		Library:Notify({
			Title = "✅ Đã mua",
			Description = SelectedShopItem,
			Duration = 3
		})
	end
})

task.spawn(function()
	local LastRaidPoint = ""
	local LastRestock = ""

	while task.wait(0.5) do
		pcall(function()
			local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
			if not hud or not hud:FindFirstChild("Main") then return end
			local shop = hud.Main:FindFirstChild("Frame_ShopRaid")
			if not shop then return end

			local rpLbl = shop:FindFirstChild("RaidPoint")
			local resetLbl = shop:FindFirstChild("Reset")
			if rpLbl and resetLbl then
				local rp = rpLbl.Text
				local rs = resetLbl.Text
				if rp ~= LastRaidPoint or rs ~= LastRestock then
					LastRaidPoint = rp
					LastRestock = rs
					ShopInfoPara:SetTitle(rp)
					ShopInfoPara:SetContent(rs)
				end
			end

			local sf = shop:FindFirstChild("ScrollingFrame")
			if sf then
				local items = {}
				for _, item in pairs(sf:GetChildren()) do
					if item:IsA("Frame") then
						local label = item:FindFirstChild("Label")
						if label and label.Text and label.Text ~= "" and label.Text ~= "Item" then
							table.insert(items, label.Text)
						end
					end
				end

				if #items > 0 then
					table.sort(items)
					RefreshShopDropdown(items)
				end
			end
		end)
	end
end)
Weapon:Dropdown({
	Title = "Main Weapon (Attack)",
	Options = TypeTool,
	Multi = false,
	Value = "Melee",
	Callback = function(Value)
		_G.MainWeapon = Value
	end
})
Weapon:Dropdown({
	Title = "Select Support Weapon",
	Options = TypeTool,
	Multi = true,
	Callback = function(Value)
		_G.Select_EquipWeapon = Value
	end
})

AutoSkills:Toggle({
	Title = "Auto Skill Z",
	Value = false,
	Callback = function(Value)
		_G.AutoSkillZ = Value
	end
})
AutoSkills:Toggle({
	Title = "Auto Skill X",
	Value = false,
	Callback = function(Value)
		_G.AutoSkillX = Value
	end
})
AutoSkills:Toggle({
	Title = "Auto Skill C",
	Value = false,
	Callback = function(Value)
		_G.AutoSkillC = Value
	end
})
AutoSkills:Toggle({
	Title = "Auto Skill V",
	Value = false,
	Callback = function(Value)
		_G.AutoSkillV = Value
	end
})
AutoSkills:Toggle({
	Title = "Auto Skill F",
	Value = false,
	Callback = function(Value)
		_G.AutoSkillF = Value
	end
})
Haki:Toggle({
	Title = "Auto Enabled Haki",
	Value = false,
	Callback = function(Value)
		_G.Auto_Haki = Value
	end
})
Method:Dropdown({
	Title = "Select Method Farm",
	Options = {"Behind","Below","Upper","Front"},
	Multi = false,
	Value = "Upper",
	Callback = function(Value)
		_G.Select_Method = Value
	end
})
Method:Slider({
	Title = "Distance Farm",
	Min = 0,
	Max = 30,
	Value = 5,
	Callback = function(Value)
		_G.Distance_Farm = Value
	end
})


VFX:Toggle({
	Title = "Disable VFX",
	Value = false,
	Callback = function(Value)
		NoVFX(Value)
	end
})
Accessory:Toggle({
	Title = "Auto Equip The Best Accessory",
	Value = false,
	Callback = function(Value)
		_G.Auto_Equip_Accessory = Value
	end
})
Accessory:Toggle({
	Title = "Auto Rebirth (Max Level)",
	Value = false,
	Callback = function(Value)
		_G.Auto_Rebirth = Value
	end
})

Potion:Dropdown({
	Title = "Select X2 Potion",
	Options = X2List,
	Multi = true,
	Callback = function(Value)
		_G.Select_Potion = Value
	end
})
Potion:Toggle({
	Title = "Auto Use X2 Potion",
	Value = false,
	Callback = function(Value)
		_G.Auto_Use_Potion = Value
	end
})

AutoFarmCard:Toggle({
	Title = "Auto Level Farm",
	Value = false,
	Callback = function(v1)
		_G.Auto_Farm_Level = v1
		if _G.Auto_Farm_Level then
		game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
		end
	end
})
MaterialCard:Dropdown({
	Title = "Select Farm Material",
	Options = ItemAll,
	Multi = true,
	Callback = function(v7383)
		_G.Select_Material = v7383
	end
})

MaterialCard:Toggle({
	Title = "Auto Farm Material",
	Value = false,
	Callback = function(v99823)
		_G.Auto_Farm_Material = v99823
	end
})

Boss:Dropdown({
	Title = "Select Boss",
	Options = Bosses,
	Multi = false,
	Callback = function(v389247288)
		_G.Select_Boss = v389247288
	end
})

Boss:Toggle({
	Title = "Auto Farm All Boss",
	Value = false,
	Callback = function(v3728369)
		_G.Auto_FarmBoss = v3728369
	end
})
Boss:Toggle({
	Title = "Auto Farm Boss (Full)",
	Value = false,
	Callback = function(v268373)
		_G.Auto_FarmBoss_Automatically = v268373
				if _G.Auto_FarmBoss_Automatically then
			game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
		end
	end
})

Thief:Toggle({
	Title = "Auto Farm Thief Chest",
	Value = false,
	Callback = function(vhi)
		_G.Auto_BaconThief = vhi
	end
})

Piccolo:Toggle({
	Title = "Auto Farm Piccolo",
	Value = false,
	Callback = function(Value)
		_G.Auto_Piccolo = Value
	end
})

Duck:Toggle({
	Title = "Auto Farm Duck",
	Value = false,
	Callback = function(Value)
		_G.Auto_Duck = Value
	end
})
Duck:Toggle({
	Title = "Auto Farm Duck (Full)",
	Value = false,
	Callback = function(Value)
		_G.Auto_DuckAutomatically = Value
		if Value then
			game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"Quest","Cancel")
		end
	end
})
DevilBoat:Toggle({
	Title = "Auto Farm Devil Boat",
	Value = false,
	Callback = function(Value)
		_G.Auto_DevilBoat = Value
	end
})
local Spawn_Status = SpawnedT:Paragraph({
	Title = "Spawn Status",
	Content = "N/A"
})

local Item_Auto = WeaponCraft:Paragraph({
    Title = "Item Requirements ( None )",
    Content = "N/A"
})
WeaponCraft:Dropdown({
	Title = "Select Weapon Craft",
	Options = WeaponAll,
	Multi = false,
	Callback = function(Value)
		_G.Select_Item = Value
	end
})
WeaponCraft:Button({
	Title = "Craft Weapon",
	Callback = function()
		local Data = UseItems[_G.Select_Item]
		if Data then
			game.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Craft", _G.Select_Item, Data.Type)
		end
	end
})
local NotifyClass = false
WeaponCraft:Toggle({
	Title = "Auto Craft Weapon (Full)",
	Value = false,
	Callback = function(v)
		_G.Auto_CraftWeapon = v
		if not v then
			NotifyClass = false
		end
	end
})
WeaponCraft:Toggle({
	Title = "Auto Farm Set Weapon",
	Value = false,
	Callback = function(v)
		_G.Auto_Farm_Set = v
	end
})

RaidCard:Toggle({
	Title = "Auto Raid Moon (Full)",
	Value = false,
	Callback = function(v891)
		_G.Auto_Raid = v891
		if _G.Auto_Raid then
			game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
		end
	end
})
DungeonCard:Textbox({
	Title = "Dungeon Orb to Use",
	Placeholder = "...",
	Callback = function(hin)
		_G.Dungeon_UseValue = tonumber(hin) or 1
	end
})
DungeonCard:Slider({
	Title = "Health Return %",
	Min = 1,
	Max = 100,
	Value = 30,
	Callback = function(vh)
		_G.HealthPercent = vh
	end
})
DungeonCard:Toggle({
	Title = "Auto Dungeon (Full)",
	Value = false,
	Callback = function(vhiv)
		_G.Auto_Dungeon = vhiv
		if _G.Auto_Dungeon then
			game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
		end
	end
})

SellCard:Dropdown({
	Title = "Select Sell Item",
	Options = SellItems,
	Multi = true,
	Callback = function(Value)
		_G.Select_SellItem = Value
	end
})

SellCard:Toggle({
	Title = "Auto Sell",
	Value = false,
	Callback = function(Value)
		_G.Auto_SellItem = Value
	end
})
StatusCard:Textbox({
	Title = "Status Amount",
	Placeholder = "1000",
	Value = "1000",
	Callback = function(Value)
		_G.Amount = tonumber(Value) or 1000
	end
})

StatusCard:Toggle({
	Title = "Auto Up Melee",
	Value = false,
	Callback = function(Value)
		_G.AutoMelee = Value
	end
})

StatusCard:Toggle({
	Title = "Auto Up Defense",
	Value = false,
	Callback = function(Value)
		_G.AutoDefense = Value
	end
})

StatusCard:Toggle({
	Title = "Auto Up Sword",
	Value = false,
	Callback = function(Value)
		_G.AutoSword = Value
	end
})

StatusCard:Toggle({
	Title = "Auto Up Power",
	Value = false,
	Callback = function(Value)
		_G.AutoPower = Value
	end
})
DiamondChest:Dropdown({
	Title = "Select Random Diamond Chest",
	Options = RandomChestValue,
	Multi = false,
	Callback = function(Value)
		_G.Select_Random = Value
	end
})
DiamondChest:Toggle({
	Title = "Auto Random Diamond Chest",
	Value = false,
	Callback = function(Value)
		_G.Auto_RandomChest = Value
	end
})
MoonChest:Dropdown({
	Title = "Select Random Moon Chest",
	Options = RandomChestValue,
	Multi = false,
	Callback = function(Value)
		_G.Select_Random_Moon = Value
	end
})

MoonChest:Toggle({
	Title = "Auto Random Moon Chest",
	Value = false,
	Callback = function(Value)
		_G.Auto_RandomChest_Moon = Value
	end
})
GuaranteeDiamond:Dropdown({
	Title = "Select Guarantee Diamond Point",
	Options = Poitem,
	Multi = false,
	Callback = function(Value)
		_G.Select_Guarantee = Value:match("^(.-) /")
	end
})
GuaranteeDiamond:Button({
	Title = "Buy Guarantee Diamond Point",
	Callback = function()
		local Point = tonumber(LocalPlayer:GetAttribute("PointItem")) or 0
		local Price = PointItemM[_G.Select_Guarantee] or 0
		if _G.Select_Guarantee and Point >= Price then
			ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"BuyGaranteeRandomItem",_G.Select_Guarantee)
		end
	end
})
GuaranteeDiamond:Toggle({
	Title = "Auto Buy Guarantee Diamond Point",
	Value = false,
	Callback = function(Value)
		_G.Auto_Guarantee = Value
	end
})
GuaranteeMoon:Dropdown({
	Title = "Select Guarantee Moon Point",
	Options = PoiteMoon,
	Multi = false,
	Callback = function(Value)
		_G.Select_Guarantee_Moon = Value:match("^(.-) /")
	end
})
GuaranteeMoon:Button({
	Title = "Buy Guarantee Moon Point",
	Callback = function()
		local Point = tonumber(LocalPlayer:GetAttribute("MoonPoint")) or 0
		local Price = PointItemMoon[_G.Select_Guarantee_Moon] or 0
		if _G.Select_Guarantee_Moon and Point >= Price then
			ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"BuyGaranteeEventMoon",_G.Select_Guarantee_Moon)
		end
	end
})
GuaranteeMoon:Toggle({
	Title = "Auto Buy Guarantee Moon Point",
	Value = false,
	Callback = function(Value)
		_G.Auto_Guarantee_Moon = Value
	end
})
task.spawn(function()
   while task.wait(0.1) do
    if _G.AutoMelee then
      game:GetService("ReplicatedStorage").Remotes.System:FireServer("UpStats", "Melee", _G.Amount)
    end
    if _G.AutoDefense then
      game:GetService("ReplicatedStorage").Remotes.System:FireServer("UpStats", "Defense", _G.Amount)
    end
    if _G.AutoSword then
      game:GetService("ReplicatedStorage").Remotes.System:FireServer("UpStats", "Sword", _G.Amount)
    end
    if _G.AutoPower then
      game:GetService("ReplicatedStorage").Remotes.System:FireServer("UpStats", "Power", _G.Amount)
    end
  end
end)

task.spawn(function()
	while task.wait() do
		pcall(function()
			local Text = {}
			for Name, MobName in pairs(SpawnList) do
				local Spawned = false
				-- Check nhiều biến thể tên
				local Names = {MobName}
				if MobName == "Devil Boat" then
					table.insert(Names, "DevilBoat")
				end
				for _, n in ipairs(Names) do
					if workspace.Mob:FindFirstChild(n) then
						Spawned = true
						break
					end
				end
				table.insert(Text, Name .. ": " .. (Spawned and "Spawned (✅)" or "Not Spawned (❌)"))
			end
			Spawn_Status:SetContent(table.concat(Text, "\n"))
		end)
	end
end)
task.spawn(function()
	while task.wait() do
		pcall(function()
			if _G.Select_Method == "Behind" then
				MethodFarm = CFrame.new(0,0,_G.Distance_Farm)
			elseif _G.Select_Method == "Front" then
				MethodFarm = CFrame.new(0,0,-_G.Distance_Farm) * CFrame.Angles(0,math.rad(180),0)
			elseif _G.Select_Method == "Below" then
				MethodFarm = CFrame.new(0,-_G.Distance_Farm,0) * CFrame.Angles(math.rad(90),0,0)
			elseif _G.Select_Method == "Upper" then
				MethodFarm = CFrame.new(0,_G.Distance_Farm,0) * CFrame.Angles(math.rad(-90),0,0)
			elseif _G.Select_Method == "None" then
				MethodFarm = CFrame.new(0,_G.Distance_Farm,0) * CFrame.Angles(math.rad(-90),0,0)
			else
				MethodFarm = CFrame.new(0,_G.Distance_Farm,0) * CFrame.Angles(math.rad(-90),0,0)
			end
		end)
	end
end)
task.spawn(function()
	while wait() do 
		pcall(function()
			if _G.Auto_RandomChest_Moon then
			game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"EventMoon",_G.Select_Random_Moon)
			end
		end)
	end
end)
task.spawn(function()
	while wait() do 
		pcall(function()
			if _G.Auto_RandomChest then
			game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"RandomItem",_G.Select_Random)
			end
		end)
	end
end)
task.spawn(function()
	while task.wait() do
		xpcall(function()
		if _G.Auto_SellItem and type(_G.Select_SellItem) == "table" then
	    for ItemName, Selected in pairs(_G.Select_SellItem) do
        local Data = Economy[ItemName]
        if Selected and Data then
            if GetItemAmount(ItemName) >= Data.amount then
            game.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"Economy",ItemName)
						end
					end
				end
			end
		end,print)
	end
end)
task.spawn(function()
	while task.wait() do
		pcall(function()
			if _G.Auto_Raid then
				if game.PlaceId == 82878101790702 then
					for _, v in pairs(workspace.Mob:GetChildren()) do
						if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart")and v.Humanoid.Health > 0 then
							v.Humanoid.WalkSpeed = 0
							v.Humanoid.JumpPower = 0
							repeat task.wait()
								EquipWeapon()
								AutoSkill()
								Attack()
								Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
							until not _G.Auto_Raid or not v.Parent or v.Humanoid.Health <= 0
						end
					end
				else
				if workspace:FindFirstChild("TeleportMoonZone") then
					Teleport(workspace:FindFirstChild("TeleportMoonZone").Hitbox:GetPivot()*CFrame.new(0,-8,0))
				else
					if GetItemAmount("Space Ticket") >= 1 then
					Teleport(workspace.NpcPrompt.GoMoon.HumanoidRootPart.CFrame*CFrame.new(0,5,0))
					fireproximityprompt(workspace.NpcPrompt.GoMoon.HumanoidRootPart:FindFirstChildOfClass("ProximityPrompt"))
					else
						local Diamond = game.Players.LocalPlayer:GetAttribute("Diamond") or 0
						if Diamond >= 150 then
							game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"RandomItem","x15")
						else
								local quest = GetQuest_Level(tonumber(game:GetService("Players").LocalPlayer:GetAttribute("Level")))
								if not quest then return end
								local Frame = GetQuestFrame()
								local Text = Frame.Title.Text or ""
								if game:GetService("Players").LocalPlayer.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
								game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"Quest","Cancel")
								end
								if Frame.Visible and not string.find(Text, quest.Monster) then
									game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"Quest","Cancel")
									repeat task.wait() until not Frame.Visible
								end
								if not Frame.Visible then
									local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
									if npc then
										Teleport(npc.CFrame * MethodFarm)
										task.wait(0.3)
										local pro_xim = npc:FindFirstChildOfClass("ProximityPrompt")
										if pro_xim then fireproximityprompt(pro_xim) end
									end
								else
									for _, v in pairs(workspace.Mob:GetChildren()) do
										if v:IsA("Model") and v.Name == quest.Monster and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
											local hrp = v:FindFirstChild("HumanoidRootPart")
											if hrp then
												v.Humanoid.WalkSpeed = 0
												v.Humanoid.JumpPower = 0
												repeat task.wait()
													EquipWeapon()
													AutoSkill()
													Attack()
													Teleport(hrp.CFrame * MethodFarm)
												until not _G.Auto_Raid or v.Humanoid.Health <= 0
											end
											break
										end
									end
								end
							end
						end
					end
				end
			end
		end)
	end
end)
task.spawn(function()
	while task.wait(1) do
		pcall(function()
			if not _G.Auto_Equip_Accessory then
				return
			end
			local Inventory = HttpService:JSONDecode(game.Players.LocalPlayer:GetAttribute("Inventory") or "{}")
			local Equipped = HttpService:JSONDecode(game.Players.LocalPlayer:GetAttribute("UseAccessory") or "{}")
			local Best = {}
			for Name in pairs(Inventory) do
				local Info = AccessoryModule[Name]
				if Info then
					local Score = 0
					for _, Value in pairs(Info) do
						if type(Value) == "number" then
							Score = Score + Value
						end
					end
					if not Best[Info.Type] or Score > Best[Info.Type].Score then
						Best[Info.Type] = {
							Name = Name,
							Score = Score
						}
					end
				end
			end
			for Type, Data in pairs(Best) do
				local EquippedName
				for Name, Info in pairs(Equipped) do
					if Info.Type == Type then
						EquippedName = Name
						break
					end
				end
				if EquippedName ~= Data.Name then
					game.ReplicatedStorage.Remotes.Inventory:FireServer(Data.Name)
					task.wait(0.5)
				end
			end
		end)
	end
end)
task.spawn(function()
	while task.wait() do
		if _G.Auto_Farm_Set then
			pcall(function()
				local Data = UseItems[_G.Select_Item]
				if not Data then return end
				local Inv = GetInventory()
				local NeedFarmItem = nil
				local LowestSet = math.huge
				for Item, Need in pairs(Data.Inventory) do
					if not UseItems[Item] then
						local Have = Inv[Item] and Inv[Item].amount or 0
						local Set = math.floor(Have / Need)
						if Set < LowestSet then
							LowestSet = Set
							NeedFarmItem = Item
						end
					end
				end
				if not NeedFarmItem then return end
				local NeedAmount = Data.Inventory[NeedFarmItem]
				local Have = Inv[NeedFarmItem] and Inv[NeedFarmItem].amount or 0
				if Have >= (LowestSet + 1) * NeedAmount then
					return
				end
				local MobNames = ItemDrop[NeedFarmItem]
				if not MobNames then
					print("Skip : "..NeedFarmItem.." (No Drop)")
					return
				end
				for _, MobName in ipairs(MobNames) do
					local Target
					for _, Mob in ipairs(workspace.Mob:GetChildren()) do
						if Mob:IsA("Model") and Mob.Name == MobName and Mob:FindFirstChild("Humanoid") and Mob:FindFirstChild("HumanoidRootPart") and Mob.Humanoid.Health > 0 then
							Target = Mob
							break
						end
					end
					if Target then
						local HRP = Target.HumanoidRootPart
						Target.Humanoid.WalkSpeed = 0
						Target.Humanoid.JumpPower = 0
						repeat task.wait()
							EquipWeapon()
							AutoSkill()
							Attack()
							Teleport(HRP.CFrame * MethodFarm)
							Inv = GetInventory()
							Have = Inv[NeedFarmItem] and Inv[NeedFarmItem].amount or 0
						until not _G.Auto_Farm_Set or not Target.Parent or Target.Humanoid.Health <= 0 or Have >= ((LowestSet + 1) * NeedAmount)
						break
					else
						local Spawn = workspace.Itemdrops:FindFirstChild(MobName)
						if Spawn then
							Teleport(Spawn:GetPivot())
							task.wait(1.5)
							break
						end
					end
				end
			end)
		end
	end
end)
task.spawn(function()
	while task.wait() do
		if _G.Auto_Guarantee_Moon then
			local Point = tonumber(game:GetService("Players").LocalPlayer:GetAttribute("MoonPoint")) or 0
			local Price = PointItemMoon[_G.Select_Guarantee_Moon] or 0
			if _G.Select_Guarantee_Moon and Point >= Price then
				game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"BuyGaranteeEventMoon",_G.Select_Guarantee_Moon)
			end
		end
	end
end)
task.spawn(function()
	while task.wait() do
		if _G.Auto_Guarantee then
			local Point = tonumber(game:GetService("Players").LocalPlayer:GetAttribute("PointItem")) or 0
			local Price = PointItemM[_G.Select_Guarantee] or 0
			if _G.Select_Guarantee and Point >= Price then
				game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"BuyGaranteeRandomItem",_G.Select_Guarantee)
			end
		end
	end
end)
task.spawn(function()
	while task.wait() do
		pcall(function()
			if _G.Auto_Haki then
				if not game.Players.LocalPlayer.Character:FindFirstChild("HakiFolder") then
				game.ReplicatedStorage.Remotes.Action:FireServer("Misc", "buso")
				end
			end
		end)
	end
end)



task.spawn(function()
	while task.wait() do
		if _G.Auto_Piccolo then
			pcall(function()
				if workspace.Mob:FindFirstChild("Piccolo") then
					for _, v in pairs(workspace.Mob:GetChildren()) do
						if v:IsA("Model") and v.Name == "Piccolo" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart")and v.Humanoid.Health > 0 then
							v.Humanoid.WalkSpeed = 0
							v.Humanoid.JumpPower = 0
							repeat task.wait()
								EquipWeapon()
								AutoSkill()
								Attack()
								Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
							until not _G.Auto_Piccolo or not v.Parent or v.Humanoid.Health <= 0
						end
					end
				end
			end)
		end
	end
end)
task.spawn(function()
	while task.wait() do
		if _G.Auto_Duck then
			pcall(function()
				if workspace.Mob:FindFirstChild("Duck Monster") then
					for _, v in pairs(workspace.Mob:GetChildren()) do
						if v:IsA("Model") and v.Name == "Duck Monster" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart")and v.Humanoid.Health > 0 then
							v.Humanoid.WalkSpeed = 0
							v.Humanoid.JumpPower = 0
							repeat task.wait()
								EquipWeapon()
								AutoSkill()
								Attack()
								Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
							until not _G.Auto_Duck or not v.Parent or v.Humanoid.Health <= 0
						end
					end
				else
					if workspace.Itemdrops:FindFirstChild("Duck Monster") then
						Teleport(workspace.Itemdrops["Duck Monster"].CFrame)
					end
				end
			end)
		end
	end
end)
task.spawn(function()
	while task.wait() do
		if _G.Auto_DevilBoat then
			pcall(function()
				if workspace.Mob:FindFirstChild("Devil Boat") then
					for _, v in pairs(workspace.Mob:GetChildren()) do
						if v:IsA("Model") and v.Name == "Devil Boat" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
							v.Humanoid.WalkSpeed = 0
							v.Humanoid.JumpPower = 0
							repeat task.wait()
								EquipWeapon()
								AutoSkill()
								Attack()
								Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
							until not _G.Auto_DevilBoat or not v.Parent or v.Humanoid.Health <= 0
						end
					end
				else
					if workspace.Itemdrops:FindFirstChild("Devil Boat") then
						Teleport(workspace.Itemdrops["Devil Boat"].CFrame)
					end
				end
			end)
		end
	end
end)
task.spawn(function()
	while task.wait() do
		xpcall(function()
			if not _G.Auto_CraftWeapon then
				return
			end
			NotifyClass = false
			local Monster = GetNeedMonster()
			if not Monster then
				local Data = UseItems[_G.Select_Item]
				if Data then
					if Data.NeedClass then
						local PlayerClass = game.Players.LocalPlayer:GetAttribute("UseClass")
						if PlayerClass ~= Data.NeedClass then
							if not NotifyClass then
								NotifyClass = true
								Library:Notify({
									Title = "You don't have the ( "..Data.NeedClass.." ) class.",
									Description = "คุณ ไม่มี ( "..Data.NeedClass.." ) คลาส",
									Duration = 5
								})
							end
							return
						end
					end
					NotifyClass = false
					if tick() - LastCraft >= CraftDelay then
						LastCraft = tick()
						game.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"Craft",_G.Select_Item,Data.Type)
					end
				end
				return
			end
			local TargetMob
			for _, Mob in ipairs(workspace.Mob:GetChildren()) do
				if Mob:IsA("Model") and Mob.Name == Monster and Mob:FindFirstChild("Humanoid") and Mob.Humanoid.Health > 0 then
					TargetMob = Mob
					break
				end
			end
			if not TargetMob then
				local Spawn = workspace.Itemdrops:FindFirstChild(Monster)
				if Spawn then
					Teleport(Spawn:GetPivot())
				end
				return
			end
			local HRP = TargetMob:FindFirstChild("HumanoidRootPart")
			if HRP then
				TargetMob.Humanoid.WalkSpeed = 0
				TargetMob.Humanoid.JumpPower = 0
				repeat task.wait()
					EquipWeapon()
					AutoSkill()
					Attack()
					Teleport(HRP.CFrame * MethodFarm)
				until not _G.Auto_CraftWeapon or TargetMob.Humanoid.Health <= 0 or GetNeedMonster() ~= Monster
			end
		end,print)
	end
end)
task.spawn(function()
	while task.wait() do
		pcall(function()
			if _G.Auto_Rebirth then
				if game.Players.LocalPlayer.PlayerGui.HUD.Main.Frame_Display.LevelText.Text:lower():find("max") then
					game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"Rebirth")
				end
			end
		end)
	end
end)
task.spawn(function()
	while task.wait() do
		xpcall(function()
			if not _G.Auto_Farm_Material then
				return
			end
			if type(_G.Select_Material) ~= "table" then
				return
			end
			for Material in pairs(_G.Select_Material) do
				local MobNames = ItemDrop[Material]
				if MobNames then
					for _, MobName in ipairs(MobNames) do
						local Target
						for _, Mob in ipairs(workspace.Mob:GetChildren()) do
							if Mob:IsA("Model") and Mob.Name == MobName and Mob:FindFirstChild("Humanoid") and Mob:FindFirstChild("HumanoidRootPart") and Mob.Humanoid.Health > 0 then
									Target = Mob
								break
							end
						end
						if not Target then
							local Spawn = workspace.Itemdrops:FindFirstChild(MobName)
							if Spawn then
								Teleport(Spawn:GetPivot())
								task.wait(1.5)
							end
						else
							local HRP = Target.HumanoidRootPart
							Target.Humanoid.WalkSpeed = 0
							Target.Humanoid.JumpPower = 0
							local Start = tick()
						repeat task.wait()
							EquipWeapon()
							AutoSkill()
							Attack()
							Teleport(HRP.CFrame * MethodFarm)
						until not _G.Auto_Farm_Material or Target.Parent == nil or Target.Humanoid.Health <= 0 or tick() - Start >= 10
						end
					end
				end
			end
		end, warn)
	end
end)
task.spawn(function()
	while task.wait() do
		if _G.Auto_DuckAutomatically then
			pcall(function()
				if workspace.Mob:FindFirstChild("Duck Monster") then
					for _, v in pairs(workspace.Mob:GetChildren()) do
						if v:IsA("Model") and v.Name == "Duck Monster" and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
							v.Humanoid.WalkSpeed = 0
							v.Humanoid.JumpPower = 0
							repeat task.wait()
								EquipWeapon()
								AutoSkill()
								Attack()
								Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
							until not _G.Auto_DuckAutomatically or not v.Parent or v.Humanoid.Health <= 0
							game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"Quest","Cancel")
						end
					end
				else
					if workspace.Itemdrops:FindFirstChild("Duck Monster") then
						Teleport(workspace.Itemdrops:FindFirstChild("Duck Monster").CFrame)
					else
					local DuckItems = {"Duck","Duck2","Duck3","Duck4","Duck5","Duck6","Duck7"}
					local HaveAll = true
					for _, Item in ipairs(DuckItems) do
						if GetItemAmount(Item) <= 0 then
							HaveAll = false
							break
						end
					end
					if HaveAll then
						local Point = tonumber(game:GetService("Players").LocalPlayer:GetAttribute("PointItem")) or 0
						if Point > 750 and GetItemAmount("Duck6") <= 0 then
							game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "BuyGaranteeRandomItem", "Duck6")
						elseif Point > 850 and GetItemAmount("Duck7") <= 0 then
							game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "BuyGaranteeRandomItem", "Duck7")
						else
							Teleport(workspace.NpcPrompt.DuckMonster.HumanoidRootPart.CFrame*CFrame.new(0,5,0))
							fireproximityprompt(workspace.NpcPrompt.DuckMonster.HumanoidRootPart:FindFirstChildOfClass("ProximityPrompt"))
						end
					else
						local Diamond = game.Players.LocalPlayer:GetAttribute("Diamond") or 0
						if Diamond >= 150 then
							game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"RandomItem","x15")
						else
						local quest = GetQuest_Level(tonumber(game:GetService("Players").LocalPlayer:GetAttribute("Level")))
						if not quest then return end
						local Frame = GetQuestFrame()
						local Text = Frame.Title.Text or ""
						if game:GetService("Players").LocalPlayer.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
						game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"Quest","Cancel")
						end
						if Frame.Visible and not string.find(Text, quest.Monster) then
							game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"Quest","Cancel")
							repeat task.wait() until not Frame.Visible
						end
						if not Frame.Visible then
							local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
							if npc then
								Teleport(npc.CFrame * CFrame.new(0,5,0))
								task.wait(0.3)
								local pro_xim = npc:FindFirstChildOfClass("ProximityPrompt")
								if pro_xim then fireproximityprompt(pro_xim) end
							end
						else
							for _, v in pairs(workspace.Mob:GetChildren()) do
								if v:IsA("Model") and v.Name == quest.Monster and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
									local hrp = v:FindFirstChild("HumanoidRootPart")
									if hrp then
										v.Humanoid.WalkSpeed = 0
										v.Humanoid.JumpPower = 0
										repeat task.wait()
											EquipWeapon()
											AutoSkill()
											Attack()
											Teleport(hrp.CFrame * MethodFarm)
										until not _G.Auto_DuckAutomatically or v.Humanoid.Health <= 0
											end
											break
										end
									end
								end
							end
						end
					end
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait() do
		if _G.Auto_FarmBoss_Automatically then
			pcall(function()
					if workspace.Boss:FindFirstChildOfClass("Model") then
					for _, v in pairs(workspace.Boss:GetChildren()) do
						if table.find(Bosses, v.Name) and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
							v.Humanoid.WalkSpeed = 0
							v.Humanoid.JumpPower = 0
							repeat
								task.wait()
								EquipWeapon()
								AutoSkill()
								Attack()
								Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
							until not _G.Auto_FarmBoss_Automatically or not v.Parent or v.Humanoid.Health <= 0
							game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"Quest","Cancel")
						end
					end
				else
					if GetItemAmount("Orb Boss") >= 1 then
						game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"SummonBoss",_G.Select_Boss)
					else
					local Diamond = game.Players.LocalPlayer:GetAttribute("Diamond") or 0
					if Diamond >= 150 then
						game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"RandomItem","x15")
					else
							local quest = GetQuest_Level(tonumber(game:GetService("Players").LocalPlayer:GetAttribute("Level")))
							if not quest then return end
							local Frame = GetQuestFrame()
							local Text = Frame.Title.Text or ""
							if game:GetService("Players").LocalPlayer.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
							game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"Quest","Cancel")
							end
							if Frame.Visible and not string.find(Text, quest.Monster) then
								game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"Quest","Cancel")
								repeat task.wait() until not Frame.Visible
							end
							if not Frame.Visible then
								local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
								if npc then
									Teleport(npc.CFrame * MethodFarm)
									task.wait(0.3)
									local pro_xim = npc:FindFirstChildOfClass("ProximityPrompt")
									if pro_xim then fireproximityprompt(pro_xim) end
								end
							else
								for _, v in pairs(workspace.Mob:GetChildren()) do
									if v:IsA("Model") and v.Name == quest.Monster and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
										local hrp = v:FindFirstChild("HumanoidRootPart")
										if hrp then
											v.Humanoid.WalkSpeed = 0
											v.Humanoid.JumpPower = 0
											repeat task.wait()
												EquipWeapon()
												AutoSkill()
												Attack()
												Teleport(hrp.CFrame * MethodFarm)
											until not _G.Auto_FarmBoss_Automatically or v.Humanoid.Health <= 0
										end
										break
									end
								end
							end
						end
					end
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(0.3) do
		if _G.Auto_Use_Potion then
			pcall(function()
				local Player = game.Players.LocalPlayer
				local Inventory = game:GetService("ReplicatedStorage").Remotes.Inventory
				local Select = _G.Select_Potion
				if not Select then return end
				if Select["X2 EXP 15min."] and tonumber(Player:GetAttribute("x2ExpTime")) == 0 then
					Inventory:FireServer("X2 EXP 15min.")
				end
				if Select["X2 Diamond 15min."] and tonumber(Player:GetAttribute("x2DiamondTime")) == 0 then
					Inventory:FireServer("X2 Diamond 15min.")
				end
				if Select["X2 Lucky 15min."] and tonumber(Player:GetAttribute("x2LuckTime")) == 0 then
					Inventory:FireServer("X2 Lucky 15min.")
				end
				if Select["X2 Rebirth 15min."] and tonumber(Player:GetAttribute("x2RebirthTime")) == 0 then
					Inventory:FireServer("X2 Rebirth 15min.")
				end
				if Select["X2 Item 15min."] and tonumber(Player:GetAttribute("x2ItemTime")) == 0 then
					Inventory:FireServer("X2 Item 15min.")
				end
			end)
		end
	end
end)

local CurrentSpawn = 1
task.spawn(function()
	while task.wait() do
		pcall(function()
			if not _G.Auto_BaconThief then return end
			local Spawns = workspace.MobSpawnGroup:GetChildren()
			local Spawn = Spawns[CurrentSpawn]
			if not Spawn then
				CurrentSpawn = 1
				return
			end
			local ChestRef = Spawn:FindFirstChild("ChestRef", true)
			if ChestRef then
				local Target
				local Distance = 30
				for _, Mob in ipairs(workspace.Mob:GetChildren()) do
					if Mob:IsA("Model") and Mob.Name == "Bacon Thief" and Mob:FindFirstChild("HumanoidRootPart") and Mob:FindFirstChild("Humanoid") and Mob.Humanoid.Health > 0 then
						local Mag = (Mob.HumanoidRootPart.Position - ChestRef.Position).Magnitude
						if Mag < Distance then
							Distance = Mag
							Target = Mob
						end
					end
				end
				if Target then
					Target.Humanoid.WalkSpeed = 0
					Target.Humanoid.JumpPower = 0
					EquipWeapon()
					AutoSkill()
					Attack()
					Teleport(Target.HumanoidRootPart.CFrame * MethodFarm)
				else
					local Prompt = ChestRef:FindFirstChildWhichIsA("ProximityPrompt", true)
					if Prompt and Prompt.Parent and Prompt.ActionText == "Open" then
						Teleport(ChestRef.CFrame * CFrame.new(0,3,0))
						fireproximityprompt(Prompt)
					else
						CurrentSpawn = CurrentSpawn + 1
					end
				end
			else
				CurrentSpawn = CurrentSpawn + 1
			end
		end)
	end
end)
task.spawn(function()
	while task.wait() do
		xpcall(function()
			if _G.Auto_Dungeon then
				local Player = game.Players.LocalPlayer
				local Character = Player.Character
				if not Character then return end
				
				local hum = Character:FindFirstChild("Humanoid")
				local hrp = Character:FindFirstChild("HumanoidRootPart")
				if not hum or not hrp then return end

				-- Check HP thấp → ngừng đánh, đợi hồi máu
				local HpPercent = (hum.Health / hum.MaxHealth) * 100
				if HpPercent < _G.HealthPercent then
					-- Bay lên trời an toàn (cao hơn 200 studs)
					hrp.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y + 200, hrp.Position.Z)
					task.wait(0.5)
					return
				end

				local Dungeon
				local DungeonId = Character:GetAttribute("Dungeon")
				local GuiService = game:GetService("GuiService")
				local VirtualInputManager = game:GetService("VirtualInputManager")

				-- Auto skip wave
				if Player.PlayerGui:FindFirstChild("WaveUI") and Player.PlayerGui.WaveUI.AutoSkip.BackgroundColor3 == Color3.fromRGB(255,69,69) then
					GuiService.SelectedObject = Player.PlayerGui.WaveUI.AutoSkip
					task.wait(0.1)
					VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
					VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
					task.wait(0.1)
					GuiService.SelectedObject = nil
				end

				if DungeonId then
					Dungeon = workspace.DungeonMap:FindFirstChild("Dungeon_" .. DungeonId)
				end

				if Dungeon then
					-- Tìm mob gần nhất
					local Target, MinDist = nil, math.huge
					for _, Mob in ipairs(workspace.Mob:GetChildren()) do
						if Mob:IsA("Model") 
							and Mob:FindFirstChild("Humanoid") 
							and Mob:FindFirstChild("HumanoidRootPart") 
							and Mob.Humanoid.Health > 0 then
							local dist = (Mob.HumanoidRootPart.Position - Dungeon:GetPivot().Position).Magnitude
							if dist <= 250 and dist < MinDist then
								MinDist = dist
								Target = Mob
							end
						end
					end

					if Target then
						local tHrp = Target.HumanoidRootPart
						Target.Humanoid.WalkSpeed = 0
						Target.Humanoid.JumpPower = 0

						-- Đánh mượt bằng CFrame trực tiếp
						local bp = hrp:FindFirstChild("DungeonBP")
						if not bp then
							bp = Instance.new("BodyPosition")
							bp.Name = "DungeonBP"
							bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
							bp.P = 100000
							bp.D = 3000
							bp.Parent = hrp
						end

						local targetPos = tHrp.Position + Vector3.new(0, 25, 0)
						bp.Position = targetPos
						hrp.CFrame = CFrame.new(targetPos, tHrp.Position)

						EquipWeapon()
						AutoSkill()
						Attack()
					else
						-- Không có mob → xóa BP
						if hrp:FindFirstChild("DungeonBP") then
							hrp.DungeonBP:Destroy()
						end
					end
				else
					-- Chưa vào dungeon
					local TeleportZone = workspace:FindFirstChild("TeleportDungeonZone")
					if TeleportZone and TeleportZone:FindFirstChild("Hitbox") then
						hrp.CFrame = TeleportZone.Hitbox.CFrame
					else
						if GetItemAmount("Orb Dungeon") >= _G.Dungeon_UseValue then
							local NPC = workspace.NpcPrompt["Open Dungeon"].HumanoidRootPart
							hrp.CFrame = NPC.CFrame * CFrame.new(0,5,0)
							game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"SpawnDungeon",_G.Dungeon_UseValue)
						else
							local Diamond = Player:GetAttribute("Diamond") or 0
							if Diamond >= 150 then
								game.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "RandomItem", "x15")
							else
								local quest = GetQuest_Level(tonumber(Player:GetAttribute("Level")))
								if not quest then return end
								local Frame = GetQuestFrame()
								local Text = Frame.Title.Text or ""
								if Player.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
									game.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
								end
								if Frame.Visible and not string.find(Text, quest.Monster) then
									game.ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
									repeat task.wait() until not Frame.Visible
								end
								if not Frame.Visible then
									local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
									if npc then
										hrp.CFrame = npc.CFrame * MethodFarm
										task.wait(0.3)
										local pro = npc:FindFirstChildOfClass("ProximityPrompt")
										if pro then fireproximityprompt(pro) end
									end
								else
									for _, v in ipairs(workspace.Mob:GetChildren()) do
										if v:IsA("Model") and v.Name == quest.Monster and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
											v.Humanoid.WalkSpeed = 0
											v.Humanoid.JumpPower = 0
											hrp.CFrame = v.HumanoidRootPart.CFrame * MethodFarm
											EquipWeapon()
											AutoSkill()
											Attack()
											break
										end
									end
								end
							end
						end
					end
				end
			end
		end, print)
	end
end)

-- ===== SHOP DUNGEON UI (CHỈ AUTO BUY) =====
local ShopDunInfoPara = ShopDunInfoCard:Paragraph({
	Title = "DungeonPoint: ( đang load... )",
	Content = "Chọn item Auto Buy ở cột trái"
})

local ShopDunItemInfo = ShopDunInfoCard:Paragraph({
	Title = "Item: ( chưa chọn )",
	Content = "Chọn item từ dropdown Auto Buy"
})

-- Auto Buy
local AutoBuyDunItem = nil
_G.AutoBuyDunRunning = false
_G.AutoBuyDunLoaded = false
local AutoBuyDunDropdown = nil
local LastAutoBuyDunStr = ""

-- Hàm lấy tất cả item Shop Dungeon
local function GetAllShopDunItems()
	local items = {}
	local seen = {}
	local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
	if hud and hud:FindFirstChild("Main") then
		local shop = hud.Main:FindFirstChild("Frame_ShopDungeon")
		if shop then
			local sf = shop:FindFirstChild("ShopScrollingFrame")
			if sf then
				for _, item in pairs(sf:GetChildren()) do
					if item:IsA("Frame") then
						local main = item:FindFirstChild("Main")
						if main then
							local titleLbl = main:FindFirstChild("TitleLabel")
							if titleLbl and titleLbl.Text and titleLbl.Text ~= "" then
								if not seen[titleLbl.Text] then
									seen[titleLbl.Text] = true
									table.insert(items, titleLbl.Text)
								end
							end
						end
					end
				end
			end
		end
	end

	-- Item mặc định
	local DefaultItems = {
		"Plastic", "Rope", "Glue Elephant", "Cow leather", "Stopwatch",
		"Banana Leaf", "Scarf Old", "Snake leather", "Crocodile leather",
		"Microphone", "Trainer Notes"
	}
	for _, name in ipairs(DefaultItems) do
		if not seen[name] then
			seen[name] = true
			table.insert(items, name)
		end
	end

	table.sort(items)
	return items
end

-- Dropdown Auto Buy Items
local function RefreshAutoBuyDunDropdown(items)
	local itemsStr = table.concat(items, ",")
	if itemsStr == LastAutoBuyDunStr and AutoBuyDunDropdown then return end
	LastAutoBuyDunStr = itemsStr

	if AutoBuyDunDropdown then
		pcall(function() AutoBuyDunDropdown:Destroy() end)
	end

	AutoBuyDunDropdown = ShopDunCard:Dropdown({
		Title = "Auto Buy Items",
		Options = items,
		Multi = false,
		Callback = function(Value)
			AutoBuyDunItem = Value
			print("[AutoBuyDun] Chọn:", Value)

			-- Update item info
			local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
			if hud and hud:FindFirstChild("Main") then
				local shop = hud.Main:FindFirstChild("Frame_ShopDungeon")
				if shop then
					local sf = shop:FindFirstChild("ShopScrollingFrame")
					if sf then
						for _, item in pairs(sf:GetChildren()) do
							if item:IsA("Frame") then
								local main = item:FindFirstChild("Main")
								if main then
									local titleLbl = main:FindFirstChild("TitleLabel")
									if titleLbl and titleLbl.Text == Value then
										local btn = main:FindFirstChild("TextButton")
										local priceLbl = btn and btn:FindFirstChild("TextLabel")
										local price = priceLbl and priceLbl.Text or "?"
										ShopDunItemInfo:SetTitle("Item: " .. Value)
										ShopDunItemInfo:SetContent("Price: " .. price)
										return
									end
								end
							end
						end
					end
				end
			end
		end
	})
end

RefreshAutoBuyDunDropdown({"( đang load... )"})

-- Toggle Auto Buy
ShopDunCard:Toggle({
	Title = "Auto Buy",
	Value = false,
	Callback = function(Value)
		if not _G.AutoBuyDunLoaded then
			_G.AutoBuyDunLoaded = true
			_G.AutoBuyDunRunning = Value
			return
		end

		if Value and not AutoBuyDunItem then
			Library:Notify({Title = "❌ Chưa chọn item", Description = "Chọn item Auto Buy trước!", Duration = 3})
			_G.AutoBuyDunRunning = false
			return
		end
		_G.AutoBuyDunRunning = Value
		print("[AutoBuyDun] Running:", Value)
		Library:Notify({
			Title = Value and "▶️ Bật Auto Buy" or "⏹️ Tắt Auto Buy",
			Description = AutoBuyDunItem or "N/A",
			Duration = 3
		})
	end
})

-- Loop update Shop Dungeon
task.spawn(function()
	while task.wait(0.5) do
		pcall(function()
			local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
			if not hud or not hud:FindFirstChild("Main") then return end
			local shop = hud.Main:FindFirstChild("Frame_ShopDungeon")
			if not shop then return end

			-- Update point
			local ptAttr = LocalPlayer:GetAttribute("DungeonPoint") 
				or LocalPlayer:GetAttribute("PointDungeon") 
				or LocalPlayer:GetAttribute("DungeonOrb")
				or 0
			ShopDunInfoPara:SetTitle("DungeonPoint: " .. tostring(ptAttr))

			-- Update item list
			local allItems = GetAllShopDunItems()
			RefreshAutoBuyDunDropdown(allItems)

			-- Update item info nếu đã chọn
			if AutoBuyDunItem then
				local sf = shop:FindFirstChild("ShopScrollingFrame")
				if sf then
					for _, item in pairs(sf:GetChildren()) do
						if item:IsA("Frame") then
							local main = item:FindFirstChild("Main")
							if main then
								local titleLbl = main:FindFirstChild("TitleLabel")
								if titleLbl and titleLbl.Text == AutoBuyDunItem then
									local btn = main:FindFirstChild("TextButton")
									local priceLbl = btn and btn:FindFirstChild("TextLabel")
									local price = priceLbl and priceLbl.Text or "?"
									ShopDunItemInfo:SetTitle("Item: " .. AutoBuyDunItem)
									ShopDunItemInfo:SetContent("Price: " .. price)
									break
								end
							end
						end
					end
				end
			end
		end)
	end
end)

-- Loop Auto Buy Dungeon
task.spawn(function()
	while task.wait(0.5) do
		if _G.AutoBuyDunRunning and AutoBuyDunItem then
			pcall(function()
				local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
				if not hud or not hud:FindFirstChild("Main") then return end
				local shop = hud.Main:FindFirstChild("Frame_ShopDungeon")
				if not shop then return end
				local sf = shop:FindFirstChild("ShopScrollingFrame")
				if not sf then return end

				for _, item in pairs(sf:GetChildren()) do
					if item:IsA("Frame") then
						local main = item:FindFirstChild("Main")
						if main then
							local titleLbl = main:FindFirstChild("TitleLabel")
							if titleLbl and titleLbl.Text == AutoBuyDunItem then
								local NetworkEvent = ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
								NetworkEvent:FireServer("fire", nil, "BuyDungeonShop", AutoBuyDunItem)
								print("[AutoBuyDun] Mua:", AutoBuyDunItem)
								task.wait(0.3)
								break
							end
						end
					end
				end
			end)
		end
	end
end)
task.spawn(function()
	while task.wait() do
		if _G.Auto_FarmBoss then
			pcall(function()
				for _, v in pairs(workspace.Boss:GetChildren()) do
					if table.find(Bosses, v.Name) and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
						v.Humanoid.WalkSpeed = 0
						v.Humanoid.JumpPower = 0
						repeat task.wait()
							EquipWeapon()
							AutoSkill()
							Attack()
							Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
						until not _G.Auto_FarmBoss or not v.Parent or v.Humanoid.Health <= 0
					end
				end
			end)
		end
	end
end)
task.spawn(function()
	while wait() do
		xpcall(function()
			if not _G.Auto_Farm_Level then return end
			local quest = GetQuest_Level(tonumber(game:GetService("Players").LocalPlayer:GetAttribute("Level")))
			if not quest then return end
			local Frame = GetQuestFrame()
			local Text = Frame.Title.Text or ""
			if game:GetService("Players").LocalPlayer.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
			game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"Quest","Cancel")
			end
			if Frame.Visible and not string.find(Text, quest.Monster) then
				game:GetService("ReplicatedStorage").Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"Quest","Cancel")
				repeat task.wait() until not Frame.Visible
			end
			if not Frame.Visible then
				local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
				if npc then
					Teleport(npc.CFrame * MethodFarm)
					task.wait(0.3)
					local pro_xim = npc:FindFirstChildOfClass("ProximityPrompt")
					if pro_xim then fireproximityprompt(pro_xim) end
				end
			else
				for _, v in pairs(workspace.Mob:GetChildren()) do
					if v:IsA("Model") and v.Name == quest.Monster and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
						local hrp = v:FindFirstChild("HumanoidRootPart")
						if hrp then
							v.Humanoid.WalkSpeed = 0
							v.Humanoid.JumpPower = 0
							repeat task.wait()
								EquipWeapon()
								AutoSkill()
								Attack()
								Teleport(hrp.CFrame * MethodFarm)
							until not _G.Auto_Farm_Level or v.Humanoid.Health <= 0
						end
						break
					end
				end
			end
		end, print)
	end
end)
task.spawn(function()
	while task.wait(0.1) do
		local Data = UseItems[_G.Select_Item]
		if Data then
			local Success, Inv = pcall(function()
				return HttpService:JSONDecode(game.Players.LocalPlayer:GetAttribute("Inventory") or "{}")
			end)
			Inv = Success and Inv or {}
			local HaveWeapon = Inv[_G.Select_Item] and (Inv[_G.Select_Item].amount or 0) > 0
			local Text = {}
			table.insert(Text, "Need Class : "..(Data.NeedClass or "None"))
			table.insert(Text, "Need Beli : "..tostring((Data.PlayerData and Data.PlayerData.Beli) or 0))
			local LowestSet = math.huge
			for Item, Need in pairs(Data.Inventory) do
				local Have = Inv[Item] and Inv[Item].amount or 0
				local Set = math.floor(Have / Need)
				if Set < LowestSet then
					LowestSet = Set
				end
			end
			if LowestSet == math.huge then
				LowestSet = 0
			end
			table.insert(Text, "Have Set : "..LowestSet)
			table.insert(Text, "")
			for Item, Need in pairs(Data.Inventory) do
				local Have = Inv[Item] and Inv[Item].amount or 0
				local Set = math.floor(Have / Need)
				table.insert(Text, string.format(
					"%s : %d/%d %s (Set : %d)",
					Item,
					Have,
					Need,
					Have >= Need and "✅" or "❌",
					Set
				))
			end
			Item_Auto:SetTitle(
				"Item Requirements \n( " ..
				(HaveWeapon and _G.Select_Item.." ✅" or _G.Select_Item.." ❌") ..
				" )"
			)
			Item_Auto:SetContent(table.concat(Text, "\n"))
		end
	end
end)

task.spawn(function()
	while task.wait() do
		if _G.Auto_Farm_Level or _G.Auto_CraftWeapon or _G.Auto_Farm_Material or _G.Auto_FarmBoss_Automatically or _G.Auto_FarmBoss or _G.Auto_DuckAutomatically or _G.Auto_Duck  or _G.Auto_Farm_Set or _G.Auto_Raid or _G.Auto_BaconThief or _G.Auto_Dungeon or _G.Auto_Piccolo then
			pcall(function()
				local Character = game.Players.LocalPlayer.Character
				local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
				if HRP then
						HRP.AssemblyAngularVelocity = Vector3.zero
					local Vel = HRP.AssemblyLinearVelocity
					HRP.AssemblyLinearVelocity = Vector3.new(0, Vel.Y, 0)
				end
			end)
		end
	end
end)
task.spawn(function()
	pcall(function()
		game:GetService("RunService").Stepped:Connect(function()
			if _G.Auto_Farm_Level or _G.Auto_CraftWeapon or _G.Auto_Farm_Material or _G.Auto_FarmBoss_Automatically or _G.Auto_FarmBoss or _G.Auto_DuckAutomatically or _G.Auto_Duck or _G.Auto_Farm_Set or _G.Auto_Raid or _G.Auto_BaconThief or _G.Auto_Dungeon or _G.Auto_Piccolo or _G.Auto_DevilBoat then
				if not game.Players.LocalPlayer.Character.HumanoidRootPart:FindFirstChild("BodyClip") then
				local Noclip = Instance.new("BodyVelocity")
					Noclip.Name = "BodyClip"
					Noclip.Parent = game.Players.LocalPlayer.Character.HumanoidRootPart
					Noclip.MaxForce = Vector3.new(100000, 100000, 100000)
					Noclip.Velocity = Vector3.new(0, 0, 0)
					end
				else    
					if game.Players.LocalPlayer.Character.HumanoidRootPart:FindFirstChild("BodyClip") then
					game.Players.LocalPlayer.Character.HumanoidRootPart:FindFirstChild("BodyClip"):Destroy()
				end
			end
		end)
	end)
end)  
-- ===== Devil Boat =====
task.spawn(function()
	while task.wait() do
		if _G.Auto_DevilBoat then
			pcall(function()
				local Target
				for _, v in pairs(workspace.Mob:GetChildren()) do
					if v:IsA("Model") 
						and (v.Name == "Devil Boat" or v.Name == "DevilBoat")
						and v:FindFirstChild("Humanoid") 
						and v:FindFirstChild("HumanoidRootPart") 
						and v.Humanoid.Health > 0 then
						Target = v
						break
					end
				end
				if Target then
					Target.Humanoid.WalkSpeed = 0
					Target.Humanoid.JumpPower = 0
					repeat task.wait()
						EquipWeapon()
						AutoSkill()
						Attack()
						Teleport(Target.HumanoidRootPart.CFrame * MethodFarm)
					until not _G.Auto_DevilBoat or not Target.Parent or Target.Humanoid.Health <= 0
				end
			end)
		end
	end
end)
-- ===== AUTO RAID BOSS v17 - FIX BOSS MOVE AND FINA =====
_G.RaidWaitingClear = false
_G.RaidDying = false

task.spawn(function()
	print("[AutoRaid] ✅ task.spawn v17 đã khởi động!")
	while task.wait(0.3) do
		if _G.AutoRaidRunning then
			local Data = RaidBossData and RaidBossData[_G.AutoRaidWho]
			if Data and Data.Valid then
				pcall(function()
					local char = LocalPlayer.Character
					local hum = char and char:FindFirstChild("Humanoid")
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					if not hum or not hrp then return end

					if hum.Health <= 0 then
						if not _G.RaidDying then
							_G.RaidDying = true
							_G.RaidWaitingClear = true
							print("[AutoRaid] Nhân vật chết → đợi boss biến mất...")
							if hrp:FindFirstChild("AutoRaidBP") then hrp.AutoRaidBP:Destroy() end
							if hrp:FindFirstChild("AutoRaidAP") then hrp.AutoRaidAP:Destroy() end
							if hrp:FindFirstChild("AutoRaidAO") then hrp.AutoRaidAO:Destroy() end
							if hrp:FindFirstChild("AutoRaidAtt") then hrp.AutoRaidAtt:Destroy() end
						end
						return
					else
						_G.RaidDying = false
					end

					local bf = workspace:FindFirstChild("Boss Fight")
					local baconFolder = bf and bf:FindFirstChild("Bacon of Grudge")

					if _G.RaidWaitingClear then
						if baconFolder then
							print("[AutoRaid] Đợi boss biến mất...")
							task.wait(1)
							return
						else
							print("[AutoRaid] Boss biến mất, mở raid mới!")
							_G.RaidWaitingClear = false
							task.wait(1)
						end
					end

					if baconFolder then
						local function TeleportTo(targetPart, offsetY, offsetX)
							if not hrp or not hrp.Parent or not targetPart then return end
							if hrp:FindFirstChild("AutoRaidBP") then hrp.AutoRaidBP:Destroy() end
							if hrp:FindFirstChild("AutoRaidAP") then hrp.AutoRaidAP:Destroy() end
							local targetPos = targetPart.Position + Vector3.new(offsetX or 0, offsetY or 25, 0)
							local targetCF = CFrame.new(targetPos, targetPart.Position)
							hrp.CFrame = targetCF
							hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
							hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
						end

						local function CleanupBP()
							if hrp:FindFirstChild("AutoRaidBP") then hrp.AutoRaidBP:Destroy() end
							if hrp:FindFirstChild("AutoRaidAP") then hrp.AutoRaidAP:Destroy() end
							if hrp:FindFirstChild("AutoRaidAO") then hrp.AutoRaidAO:Destroy() end
							if hrp:FindFirstChild("AutoRaidAtt") then hrp.AutoRaidAtt:Destroy() end
						end

						local function AttackTarget(targetPart, targetModel, offsetY, offsetX)
							if not targetPart or not targetModel then return end
							if not targetModel:FindFirstChild("Humanoid") then return end
							if targetModel.Humanoid.Health <= 0 then return end

							targetModel.Humanoid.WalkSpeed = 0
							targetModel.Humanoid.JumpPower = 0

							repeat task.wait(0.03)
								if not _G.AutoRaidRunning then break end
								if not targetModel.Parent then break end
								if targetModel.Humanoid.Health <= 0 then break end
								if hum.Health <= 0 then break end
								if not targetPart.Parent then break end
								TeleportTo(targetPart, offsetY, offsetX)
								EquipWeapon()
								AutoSkill()
								Attack()
							until false
							CleanupBP()
						end

						-- ===== Ball 1 =====
						local A1 = baconFolder:FindFirstChild("ArmorBall1")
						if A1 and A1:FindFirstChild("Humanoid") and A1.Humanoid.Health > 0 then
							print("[AutoRaid] Đánh ArmorBall1")
							AttackTarget(A1:FindFirstChild("HumanoidRootPart"), A1, 25, 0)
						end

						-- ===== Ball 2 =====
						local A2 = baconFolder:FindFirstChild("ArmorBall2")
						if _G.AutoRaidRunning and A2 and A2:FindFirstChild("Humanoid") and A2.Humanoid.Health > 0 then
							print("[AutoRaid] Đánh ArmorBall2")
							AttackTarget(A2:FindFirstChild("HumanoidRootPart"), A2, 25, 0)
						end

						-- ===== BOSS BACON OF GRULD =====
						local BossBacon = baconFolder:FindFirstChild("Boss Bacon Sad")
						if _G.AutoRaidRunning and BossBacon and BossBacon:FindFirstChild("Humanoid") and BossBacon.Humanoid.Health > 0 then
							local bossHrp = BossBacon:FindFirstChild("HumanoidRootPart")
							if bossHrp then
								print("[AutoRaid] Đánh Boss Bacon Sad")
								AttackTarget(bossHrp, BossBacon, 55, 5)
							end
						end

						if _G.AutoRaidRunning then
							task.wait(2)
						end
					else

	print("[AutoRaid] Chưa vào map")

	if hrp:FindFirstChild("AutoRaidBP") then hrp.AutoRaidBP:Destroy() end
	if hrp:FindFirstChild("AutoRaidAP") then hrp.AutoRaidAP:Destroy() end
	if hrp:FindFirstChild("AutoRaidAO") then hrp.AutoRaidAO:Destroy() end
	if hrp:FindFirstChild("AutoRaidAtt") then hrp.AutoRaidAtt:Destroy() end

	local TPZone = workspace:FindFirstChild("TeleportBossFightZone")

	if TPZone and TPZone:FindFirstChild("Hitbox") then
		print("[AutoRaid] Vào portal (đợi vô hạn)")
		local Hitbox = TPZone.Hitbox
		hrp.Anchored = true

		local LastPrint = 0
		repeat task.wait(0.1)
			if not _G.AutoRaidRunning then break end
			if hrp.Parent then
				hrp.CFrame = Hitbox.CFrame
				hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			end
			if tick() - LastPrint > 3 then
				LastPrint = tick()
				print("[AutoRaid] Đang đợi portal teleport...")
			end
			if not TPZone.Parent then
				print("[AutoRaid] Cổng biến mất, thoát loop")
				break
			end
			if workspace:FindFirstChild("Boss Fight") then
				print("[AutoRaid] Đã vào map!")
				break
			end
		until false

		hrp.Anchored = false

		if workspace:FindFirstChild("Boss Fight") then
			print("[AutoRaid] Đã vào map, đợi 3s...")
			task.wait(3)
		else
			task.wait(1)
		end
	else
		if GetItemAmount("Portal Gun") < Data.PortalCost then
			Library:Notify({
				Title = "❌ Không đủ Portal Gun",
				Description = "Cần " .. Data.PortalCost .. " Portal Gun!",
				Duration = 4
			})
			_G.AutoRaidRunning = false
			return
		end

		print("[AutoRaid] Fire SpawnBossFight: " .. Data.Name)
		local NetworkEvent = ReplicatedStorage.Modules.NetworkFramework.NetworkEvent
		NetworkEvent:FireServer("fire", nil, "SpawnBossFight", Data.Name)
		task.wait(2)

		local TPZone2 = workspace:FindFirstChild("TeleportBossFightZone")
		if TPZone2 and TPZone2:FindFirstChild("Hitbox") then
			print("[AutoRaid] Portal xuất hiện, vào Hitbox!")
			local Hitbox2 = TPZone2.Hitbox
			hrp.Anchored = true

			local LastPrint2 = 0
			repeat task.wait(0.1)
				if not _G.AutoRaidRunning then break end
				if hrp.Parent then
					hrp.CFrame = Hitbox2.CFrame
					hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				end
				if tick() - LastPrint2 > 3 then
					LastPrint2 = tick()
					print("[AutoRaid] Đang đợi portal teleport...")
				end
				if not TPZone2.Parent then
					print("[AutoRaid] Cổng biến mất, thoát loop")
					break
				end
				if workspace:FindFirstChild("Boss Fight") then
					print("[AutoRaid] Đã vào map!")
					break
				end
			until false

			hrp.Anchored = false

			if workspace:FindFirstChild("Boss Fight") then
				print("[AutoRaid] Đã vào map, đợi 3s...")
				task.wait(3)
			else
				task.wait(1)
			end
		else
			task.wait(2)
		end
	end
end
				end)
			end
		end
	end
end)

-- Cleanup khi tắt AutoRaid
task.spawn(function()
	while task.wait(0.5) do
		if not _G.AutoRaidRunning then
			local char = LocalPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				if hrp:FindFirstChild("AutoRaidBP") then hrp.AutoRaidBP:Destroy() end
				if hrp:FindFirstChild("AutoRaidAP") then hrp.AutoRaidAP:Destroy() end
				if hrp:FindFirstChild("AutoRaidAO") then hrp.AutoRaidAO:Destroy() end
				if hrp:FindFirstChild("AutoRaidAtt") then hrp.AutoRaidAtt:Destroy() end
				if hrp.Anchored and not workspace:FindFirstChild("Boss Fight") then
					hrp.Anchored = false
				end
			end
		end
	end
end)
task.spawn(function()
	while _G.AutoRaidRunning do
		pcall(function()
			local char = LocalPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				-- Cancel dash: giữ velocity chỉ theo trục Y
				local v = hrp.AssemblyLinearVelocity
				hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
			end
		end)
		task.wait()
	end
end)
task.spawn(function()
	while task.wait(0.5) do
		if _G.Auto_Dungeon then
			pcall(function()
				local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
				if hud and hud:FindFirstChild("Main") then
					local fd = hud.Main:FindFirstChild("Frame_DungeonItem")
					if fd and fd.Visible then
						-- Đợi 2s cho user xem thưởng
						task.wait(2)
						-- Đóng GUI
						local closeBtn = fd:FindFirstChild("Close_")
						if closeBtn then
							if firesignal then
								firesignal(closeBtn.MouseButton1Click)
							else
								closeBtn:Activate()
							end
						else
							fd.Visible = false
						end
						print("[AutoDungeon] Đã đóng GUI nhận thưởng")
					end
				end
			end)
		end
	end
end)
-- ===== AUTO CLOSE RAID REWARD GUI =====
task.spawn(function()
	while task.wait(0.5) do
		if _G.AutoRaidRunning then
			pcall(function()
				local playerGui = LocalPlayer.PlayerGui
				
				-- Tìm GUI nhận thưởng Raid
				local rewardGui = playerGui:FindFirstChild("RaidReward")
					or playerGui:FindFirstChild("BossReward")
				
				-- Trong HUD.Main
				local hud = playerGui:FindFirstChild("HUD")
				if hud and hud:FindFirstChild("Main") then
					local main = hud.Main
					for _, guiName in ipairs({"Frame_RaidReward", "Frame_BossReward", "Frame_Reward"}) do
						local gui = main:FindFirstChild(guiName)
						if gui and gui.Visible then
							for _, child in pairs(gui:GetDescendants()) do
								if child:IsA("TextButton") or child:IsA("ImageButton") then
									local txt = ""
									pcall(function() txt = child.Text or "" end)
									if txt:lower():find("claim") or txt:lower():find("receive") or txt:lower():find("ok") then
										pcall(function()
											if firesignal then
												firesignal(child.MouseButton1Click)
											else
												child:Activate()
											end
										end)
										task.wait(0.5)
										gui.Visible = false
										break
									end
								end
							end
						end
					end
				end
			end)
		end
	end
end)
MySaveManager:BuildConfigTab(ConfigTab)
task.spawn(function()
    task.wait(1)
    MySaveManager:LoadAutoloadConfig()
end)
else
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer and game.Players.LocalPlayer.Character

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Connection
local TypeTool = {"Melee","Sword","Special","DevilFruit"}
local MethodList = {"Behind","Below","Upper","Front"}

_G.MainWeapon = "Melee"
_G.Select_EquipWeapon = {}
_G.Select_Method = "Upper"
_G.Distance_Farm = 5

local MethodFarm = CFrame.new(0,5,0) * CFrame.Angles(math.rad(-90),0,0)

local Teleport = function(Pos)
	local Character = LocalPlayer.Character
	if Character then
		Character:PivotTo(Pos)
	end
end
local NoVFX = function(State)
	if State then
		workspace:WaitForChild("VFX"):ClearAllChildren()
		Connection = workspace:WaitForChild("VFX").DescendantAdded:Connect(function(v)
			pcall(function()
				v:Destroy()
			end)
		end)
	else
		if Connection then
			Connection:Disconnect()
			Connection = nil
		end
	end
end
local AutoSkill = function()
	local Character = LocalPlayer.Character
	if not Character then return end
	local Skills = {}
	if _G.AutoSkillZ then table.insert(Skills,"z") end
	if _G.AutoSkillX then table.insert(Skills,"x") end
	if _G.AutoSkillC then table.insert(Skills,"c") end
	if _G.AutoSkillV then table.insert(Skills,"v") end
	if _G.AutoSkillF then table.insert(Skills,"f") end
	if #Skills == 0 then return end
	local Skill = Skills[math.random(#Skills)]
	for _,Tool in ipairs(Character:GetChildren()) do
		if Tool:IsA("Tool") then
			ReplicatedStorage.Remotes.Action:FireServer(Tool.Name,Skill)
		end
	end
end

local EquipWeapon = function()
	local Character = LocalPlayer.Character
	if not Character then return end
	local Backpack = LocalPlayer.Backpack
	local MainTool

	for _,v in ipairs(Character:GetChildren()) do
		if v:IsA("Tool") and v:GetAttribute("Type") == _G.MainWeapon then
			MainTool = v
			break
		end
	end

	if not MainTool then
		for _,v in ipairs(Backpack:GetChildren()) do
			if v:IsA("Tool") and v:GetAttribute("Type") == _G.MainWeapon then
				MainTool = v
				break
			end
		end
	end

	for _,v in ipairs(Character:GetChildren()) do
		if v:IsA("Tool") and v ~= MainTool then
			v.Parent = Backpack
		end
	end

	if MainTool and MainTool.Parent ~= Character then
		MainTool.Parent = Character
	end

	if type(_G.Select_EquipWeapon) == "table" then
		for _,Type in ipairs(_G.Select_EquipWeapon) do
			if Type ~= _G.MainWeapon then
				for _,v in ipairs(Backpack:GetChildren()) do
					if v:IsA("Tool") and v:GetAttribute("Type") == Type and v ~= MainTool then
						v.Parent = Character
					end
				end
			end
		end
	end
end

local Attack = function()
	local Character = LocalPlayer.Character
	if not Character then return end
	for _,v in ipairs(Character:GetChildren()) do
		if v:IsA("Tool") then
			ReplicatedStorage.Remotes.Action:FireServer(v.Name,"hit")
		end
	end
end

local GetItemAmount = function(ItemName)
	local Success,Inventory = pcall(function()
		return HttpService:JSONDecode(
			LocalPlayer:GetAttribute("Inventory") or "{}"
		)
	end)
	if not Success then return 0 end
	return Inventory[ItemName] and Inventory[ItemName].amount or 0
end

LocalPlayer.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

local Library = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/znesr99/gui/refs/heads/main/MarvenRizLib.lua"
))()

local Window = Library:CreateWindow({
	Title = "MarvenRiz Hub",
	Subtitle = "Map : Rock Fruit",
	Size = UDim2.fromOffset(500,370),
	AccentColor = Color3.fromRGB(50,150,255),
	SideBarWidth = 120,
	Logo = "rbxassetid://87526284179554",
	LogoSize = 32,
	SphereText = false,
	SphereImage = "rbxassetid://87526284179554",
	SphereIconSize = 38,
	Map = "RockFruit"
})

local MySaveManager = Library.SaveManager

local Tab1 = Window:CreateTab("Settings",true,false)
local Settings = Tab1:CreatePage("Main Settings")

local Weapon = Settings:CreateSection("🗡️ Select Weapon","Left")
local AutoSkills = Settings:CreateSection("⚔️ Auto Skills","Left")
local Method = Settings:CreateSection("🎯 Select Method Farm","Right")
local Haki = Settings:CreateSection("👁️ Haki","Right")
local VFX = Settings:CreateSection("✨ VFX","Right")
local Tab2 = Window:CreateTab("Main",false,false)
local RaidPage = Tab2:CreatePage("Raid")
local RaidCard = RaidPage:CreateSection("🌋 Raid","Left")

local ConfigTab = Window:CreateTab("Config",false,false)

Weapon:Dropdown({
	Title = "Main Weapon (Attack)",
	Options = TypeTool,
	Multi = false,
	Value = "Melee",
	Callback = function(Value)
		_G.MainWeapon = Value
	end
})

Weapon:Dropdown({
	Title = "Select Support Weapon",
	Options = TypeTool,
	Multi = true,
	Callback = function(Value)
		_G.Select_EquipWeapon = Value
	end
})

AutoSkills:Toggle({
	Title = "Auto Skill Z",
	Value = false,
	Callback = function(Value)
		_G.AutoSkillZ = Value
	end
})

AutoSkills:Toggle({
	Title = "Auto Skill X",
	Value = false,
	Callback = function(Value)
		_G.AutoSkillX = Value
	end
})

AutoSkills:Toggle({
	Title = "Auto Skill C",
	Value = false,
	Callback = function(Value)
		_G.AutoSkillC = Value
	end
})

AutoSkills:Toggle({
	Title = "Auto Skill V",
	Value = false,
	Callback = function(Value)
		_G.AutoSkillV = Value
	end
})

AutoSkills:Toggle({
	Title = "Auto Skill F",
	Value = false,
	Callback = function(Value)
		_G.AutoSkillF = Value
	end
})

Method:Dropdown({
	Title = "Select Method Farm",
	Options = MethodList,
	Multi = false,
	Value = "Upper",
	Callback = function(Value)
		_G.Select_Method = Value
	end
})

Method:Slider({
	Title = "Distance Farm",
	Min = 0,
	Max = 30,
	Value = 5,
	Callback = function(Value)
		_G.Distance_Farm = Value
	end
})

Haki:Toggle({
	Title = "Auto Enabled Haki",
	Value = false,
	Callback = function(Value)
		_G.Auto_Haki = Value
	end
})
VFX:Toggle({
	Title = "Disable VFX",
	Value = false,
	Callback = function(Value)
		NoVFX(Value)
	end
})
RaidCard:Toggle({
	Title = "Auto Raid Moon (Full)",
	Value = false,
	Callback = function(Value)
		_G.Auto_Raid = Value
		if Value then
			ReplicatedStorage.Modules.NetworkFramework.NetworkEvent:FireServer("fire",nil,"Quest","Cancel")
		end
	end
})

task.spawn(function()
	while task.wait() do
		pcall(function()
			if _G.Select_Method == "Behind" then
				MethodFarm = CFrame.new(0,0,_G.Distance_Farm)
			elseif _G.Select_Method == "Front" then
				MethodFarm = CFrame.new(0,0,-_G.Distance_Farm) * CFrame.Angles(0,math.rad(180),0)
			elseif _G.Select_Method == "Below" then
				MethodFarm = CFrame.new(0,-_G.Distance_Farm,0) * CFrame.Angles(math.rad(90),0,0)
			elseif _G.Select_Method == "Upper" then
				MethodFarm = CFrame.new(0,_G.Distance_Farm,0) * CFrame.Angles(math.rad(-90),0,0)
			elseif _G.Select_Method == "None" then
				MethodFarm = CFrame.new(0,_G.Distance_Farm,0) * CFrame.Angles(math.rad(-90),0,0)
			else
				MethodFarm = CFrame.new(0,_G.Distance_Farm,0) * CFrame.Angles(math.rad(-90),0,0)
			end
		end)
	end
end)
task.spawn(function()
	while task.wait() do
		pcall(function()
			if _G.Auto_Haki then
				if not game.Players.LocalPlayer.Character:FindFirstChild("HakiFolder") then
				game.ReplicatedStorage.Remotes.Action:FireServer("Misc", "buso")
				end
			end
		end)
	end
end)

task.spawn(function()
	while task.wait() do
		pcall(function()
			if _G.Auto_Raid then
				if game.PlaceId == 82878101790702 then
					for _, v in pairs(workspace.Mob:GetChildren()) do
						if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart")and v.Humanoid.Health > 0 then
							v.Humanoid.WalkSpeed = 0
							v.Humanoid.JumpPower = 0
							repeat task.wait()
								EquipWeapon()
								AutoSkill()
								Attack()
								Teleport(v.HumanoidRootPart.CFrame * MethodFarm)
							until not _G.Auto_Raid or not v.Parent or v.Humanoid.Health <= 0
							break
						end
					end
				end
			end
		end)
	end
end)
task.spawn(function()
	while task.wait() do
		if _G.Auto_Farm_Level or _G.Auto_CraftWeapon or _G.Auto_Farm_Material or _G.Auto_FarmBoss_Automatically or _G.Auto_FarmBoss or _G.Auto_DuckAutomatically or _G.Auto_Duck  or _G.Auto_Farm_Set or _G.Auto_Raid or _G.Auto_BaconThief or _G.Auto_Dungeon or _G.Auto_Piccolo then
			pcall(function()
				local Character = game.Players.LocalPlayer.Character
				local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
				if HRP then
						HRP.AssemblyAngularVelocity = Vector3.zero
					local Vel = HRP.AssemblyLinearVelocity
					HRP.AssemblyLinearVelocity = Vector3.new(0, Vel.Y, 0)
				end
			end)
		end
	end
end)
task.spawn(function()
	pcall(function()
		game:GetService("RunService").Stepped:Connect(function()
			if _G.Auto_Farm_Level or _G.Auto_CraftWeapon or _G.Auto_Farm_Material or _G.Auto_FarmBoss_Automatically or _G.Auto_FarmBoss or _G.Auto_DuckAutomatically or _G.Auto_Duck or _G.Auto_Farm_Set or _G.Auto_Raid or _G.Auto_BaconThief or _G.Auto_Dungeon or _G.Auto_Piccolo or _G.Auto_DevilBoat then
				if not game.Players.LocalPlayer.Character.HumanoidRootPart:FindFirstChild("BodyClip") then
				local Noclip = Instance.new("BodyVelocity")
					Noclip.Name = "BodyClip"
					Noclip.Parent = game.Players.LocalPlayer.Character.HumanoidRootPart
					Noclip.MaxForce = Vector3.new(100000, 100000, 100000)
					Noclip.Velocity = Vector3.new(0, 0, 0)
					end
				else    
					if game.Players.LocalPlayer.Character.HumanoidRootPart:FindFirstChild("BodyClip") then
					game.Players.LocalPlayer.Character.HumanoidRootPart:FindFirstChild("BodyClip"):Destroy()
				end
			end
		end)
	end)
end)  
MySaveManager:BuildConfigTab(ConfigTab)
task.spawn(function()
	task.wait(1)
	MySaveManager:LoadAutoloadConfig()
end)
end
