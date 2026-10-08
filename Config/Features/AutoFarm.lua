--[[
    Features/AutoFarm.lua
    Auto Farm Level, Material, Craft, Set
]]

local Globals = _G.__Globals
assert(Globals, "[Module] _G.__Globals chưa được set! Load Main.lua trước.")
local Utils     = Globals.Utils
local Combat    = Globals.Combat
local Inventory = Globals.Inventory
local RS        = Globals.ReplicatedStorage
local LP        = Globals.LocalPlayer

-- ===== Quest Helpers =====
local Quest_List = {}
table.sort(Globals.Quest_Module, function(a, b) return a.Level < b.Level end)
for i, data in ipairs(Globals.Quest_Module) do
    local npc = Globals.Npc_Quest:WaitForChild("NPC_Quest" .. i)
    Quest_List[i] = {
        Level = data.Level,
        Monster = npc:GetAttribute("Name"),
        Quest = npc
    }
end

local function GetQuest_Level(myLevel)
    local quest
    for _, v in ipairs(Quest_List) do
        if myLevel >= v.Level then
            quest = v
        else
            break
        end
    end
    return quest
end

local function GetQuestFrame()
    return LP.PlayerGui.HUD.Main.Frame_Quest
end

-- ===== Monster drop maps =====
local ItemDrop = {}
for _, mob in ipairs(Globals.Itemdrops:GetChildren()) do
    local sf = mob:FindFirstChild("ScrollingFrame", true)
    if sf then
        for _, v in ipairs(sf:GetDescendants()) do
            if v:IsA("TextLabel") and not v.Text:find("%%") then
                ItemDrop[v.Text] = ItemDrop[v.Text] or {}
                table.insert(ItemDrop[v.Text], mob.Name)
            end
        end
    end
end

-- ===== GetNeed / GetNeedMonster =====
local LastCraft = 0
local CraftDelay = 1
local NotifyCraft = false

local function CraftNotify(title, content)
    if NotifyCraft then return end
    NotifyCraft = true
    Utils.Notify(title, content, 5)
    task.delay(5, function() NotifyCraft = false end)
end

local function GetNeed(itemName)
    local inv = Inventory.Get()
    local data = Globals.UseItems[itemName]
    if not data then return itemName end
    for item, need in pairs(data.Inventory) do
        local have = inv[item] and inv[item].amount or 0
        if have < need then
            if Globals.UseItems[item] then
                return GetNeed(item)
            end
            return item
        end
    end
    local has = inv[itemName] and (inv[itemName].amount or 0) > 0
    if not has then return itemName end
    return nil
end

local function GetNeedMonster()
    local need = GetNeed(_G.Select_Item)
    if not need then
        NotifyCraft = false
        return nil
    end

    if Globals.UseItems[need] then
        local inv = Inventory.Get()
        if not (inv[need] and (inv[need].amount or 0) > 0) then
            local data = Globals.UseItems[need]
            if not data then
                CraftNotify("Craft Failed ❌", "Không thể craft " .. need)
                return false
            end
            local canCraft = true
            for item, amount in pairs(data.Inventory) do
                local have = inv[item] and inv[item].amount or 0
                if have < amount then canCraft = false; break end
            end
            if canCraft and tick() - LastCraft >= CraftDelay then
                LastCraft = tick()
                RS.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Craft", need, data.Type)
                task.wait(0.5)
            end
        end
        return GetNeedMonster()
    end

    for monster, drops in pairs(ItemDrop) do
        -- ItemDrop là {ItemName -> {Mob1, Mob2}}
    end
    -- Duyệt đúng
    for item, mobs in pairs(ItemDrop) do
        if item == need then
            return mobs[1]
        end
    end
    CraftNotify("Craft Failed ❌", "Không tìm thấy Monster drop " .. need)
    return false
end

-- ===== Loop Auto Farm Level =====
task.spawn(function()
    while task.wait() do
        xpcall(function()
            if not _G.Auto_Farm_Level then return end
            local quest = GetQuest_Level(tonumber(LP:GetAttribute("Level")))
            if not quest then return end
            local frame = GetQuestFrame()
            local text = frame.Title.Text or ""

            if LP.PlayerGui.HUD.Main.Frame_Quest.Title.Text ~= quest.Monster then
                RS.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
            end
            if frame.Visible and not string.find(text, quest.Monster) then
                RS.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Quest", "Cancel")
                repeat task.wait() until not frame.Visible
            end

            if not frame.Visible then
                local npc = quest.Quest:FindFirstChild("HumanoidRootPart")
                if npc then
                    Utils.Teleport(npc.CFrame * Utils.MethodFarm)
                    task.wait(0.3)
                    local prompt = npc:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then fireproximityprompt(prompt) end
                end
            else
                for _, v in ipairs(workspace.Mob:GetChildren()) do
                    if v:IsA("Model") and v.Name == quest.Monster
                        and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        local hrp = v:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            v.Humanoid.WalkSpeed = 0
                            v.Humanoid.JumpPower = 0
                            repeat task.wait()
                                Combat.DoAttack()
                                Utils.Teleport(hrp.CFrame * Utils.MethodFarm)
                            until not _G.Auto_Farm_Level or v.Humanoid.Health <= 0
                        end
                        break
                    end
                end
            end
        end, print)
    end
end)

-- ===== Loop Auto Farm Material =====
task.spawn(function()
    while task.wait() do
        xpcall(function()
            if not _G.Auto_Farm_Material then return end
            if type(_G.Select_Material) ~= "table" then return end

            for material in pairs(_G.Select_Material) do
                local mobNames = ItemDrop[material]
                if mobNames then
                    for _, mobName in ipairs(mobNames) do
                        local target
                        for _, mob in ipairs(workspace.Mob:GetChildren()) do
                            if mob:IsA("Model") and mob.Name == mobName
                                and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                                target = mob
                                break
                            end
                        end
                        if not target then
                            local spawn = workspace.Itemdrops:FindFirstChild(mobName)
                            if spawn then
                                Utils.Teleport(spawn:GetPivot())
                                task.wait(1.5)
                            end
                        else
                            local hrp = target.HumanoidRootPart
                            target.Humanoid.WalkSpeed = 0
                            target.Humanoid.JumpPower = 0
                            local start = tick()
                            repeat task.wait()
                                Combat.DoAttack()
                                Utils.Teleport(hrp.CFrame * Utils.MethodFarm)
                            until not _G.Auto_Farm_Material
                                or target.Parent == nil
                                or target.Humanoid.Health <= 0
                                or tick() - start >= 10
                        end
                    end
                end
            end
        end, warn)
    end
end)

-- ===== Loop Auto Craft Weapon =====
task.spawn(function()
    while task.wait() do
        xpcall(function()
            if not _G.Auto_CraftWeapon then return end
            local monster = GetNeedMonster()

            if not monster then
                local data = Globals.UseItems[_G.Select_Item]
                if data then
                    if data.NeedClass then
                        local playerClass = LP:GetAttribute("UseClass")
                        if playerClass ~= data.NeedClass then
                            Utils.Notify("You don't have the ( " .. data.NeedClass .. " ) class.",
                                "Bạn không có class ( " .. data.NeedClass .. " )", 5)
                            return
                        end
                    end
                    if tick() - LastCraft >= CraftDelay then
                        LastCraft = tick()
                        RS.Modules.NetworkFramework.NetworkEvent:FireServer("fire", nil, "Craft", _G.Select_Item, data.Type)
                    end
                end
                return
            end

            local target
            for _, mob in ipairs(workspace.Mob:GetChildren()) do
                if mob:IsA("Model") and mob.Name == monster
                    and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                    target = mob
                    break
                end
            end

            if not target then
                local spawn = workspace.Itemdrops:FindFirstChild(monster)
                if spawn then Utils.Teleport(spawn:GetPivot()) end
                return
            end

            local hrp = target:FindFirstChild("HumanoidRootPart")
            if hrp then
                target.Humanoid.WalkSpeed = 0
                target.Humanoid.JumpPower = 0
                repeat task.wait()
                    Combat.DoAttack()
                    Utils.Teleport(hrp.CFrame * Utils.MethodFarm)
                until not _G.Auto_CraftWeapon
                    or target.Humanoid.Health <= 0
                    or GetNeedMonster() ~= monster
            end
        end, print)
    end
end)

-- ===== Loop Auto Farm Set =====
task.spawn(function()
    while task.wait() do
        if _G.Auto_Farm_Set then
            pcall(function()
                local data = Globals.UseItems[_G.Select_Item]
                if not data then return end
                local inv = Inventory.Get()
                local needFarmItem, lowestSet = nil, math.huge
                for item, need in pairs(data.Inventory) do
                    if not Globals.UseItems[item] then
                        local have = inv[item] and inv[item].amount or 0
                        local set = math.floor(have / need)
                        if set < lowestSet then
                            lowestSet = set
                            needFarmItem = item
                        end
                    end
                end
                if not needFarmItem then return end
                local needAmount = data.Inventory[needFarmItem]
                local have = inv[needFarmItem] and inv[needFarmItem].amount or 0
                if have >= (lowestSet + 1) * needAmount then return end
                local mobNames = ItemDrop[needFarmItem]
                if not mobNames then
                    print("Skip: " .. needFarmItem .. " (No Drop)")
                    return
                end
                for _, mobName in ipairs(mobNames) do
                    local target
                    for _, mob in ipairs(workspace.Mob:GetChildren()) do
                        if mob:IsA("Model") and mob.Name == mobName
                            and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                            target = mob
                            break
                        end
                    end
                    if target then
                        local hrp = target.HumanoidRootPart
                        target.Humanoid.WalkSpeed = 0
                        target.Humanoid.JumpPower = 0
                        repeat task.wait()
                            Combat.DoAttack()
                            Utils.Teleport(hrp.CFrame * Utils.MethodFarm)
                            inv = Inventory.Get()
                            have = inv[needFarmItem] and inv[needFarmItem].amount or 0
                        until not _G.Auto_Farm_Set
                            or not target.Parent
                            or target.Humanoid.Health <= 0
                            or have >= ((lowestSet + 1) * needAmount)
                        break
                    else
                        local spawn = workspace.Itemdrops:FindFirstChild(mobName)
                        if spawn then
                            Utils.Teleport(spawn:GetPivot())
                            task.wait(1.5)
                            break
                        end
                    end
                end
            end)
        end
    end
end)
