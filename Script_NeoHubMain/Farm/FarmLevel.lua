-- Farm/FarmSet.lua
local Services = require(script.Parent.Parent.Core.Services)
local Helpers  = require(script.Parent.Parent.Core.Helpers)

local LocalPlayer = Services.LocalPlayer
local Data = _G.Data
local Teleport = Helpers.Teleport
local GetInventory = Helpers.GetInventory

local MethodFarm = CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-90), 0, 0)

task.spawn(function()
    while task.wait() do
        pcall(function()
            MethodFarm = CFrame.new(0, _G.Distance_Farm or 5, 0)
                * CFrame.Angles(math.rad(-90), 0, 0)
            if not _G.Auto_Farm_Set then return end
            local itemData = Data.UseItems and Data.UseItems[_G.Select_Item]
            if not itemData then return end
            local inv = GetInventory()
            local needItem, lowestSet = nil, math.huge
            for Item, Need in pairs(itemData.Inventory) do
                if not (Data.UseItems[Item]) then
                    local have = (inv[Item] and inv[Item].amount) or 0
                    local set = math.floor(have / Need)
                    if set < lowestSet then
                        lowestSet = set
                        needItem = Item
                    end
                end
            end
            if not needItem then return end
            local needAmt = itemData.Inventory[needItem]
            local have = (inv[needItem] and inv[needItem].amount) or 0
            if have >= (lowestSet + 1) * needAmt then return end
            local mobNames = Data.ItemDrop[needItem]
            if not mobNames then return end
            for _, mobName in ipairs(mobNames) do
                local Target
                local mobFolder = workspace:FindFirstChild("Mob")
                if mobFolder then
                    for _, mob in ipairs(mobFolder:GetChildren()) do
                        if mob:IsA("Model") and mob.Name == mobName
                           and mob:FindFirstChild("Humanoid")
                           and mob.Humanoid.Health > 0 then
                            Target = mob
                            break
                        end
                    end
                end
                if Target then
                    local hrp = Target.HumanoidRootPart
                    Target.Humanoid.WalkSpeed = 0
                    Target.Humanoid.JumpPower = 0
                    _G.CanAutoSkill = true
                    repeat task.wait()
                        _G.EquipWeapon(); _G.AutoSkill(); _G.Attack()
                        Teleport(hrp.CFrame * MethodFarm)
                        inv = GetInventory()
                        have = (inv[needItem] and inv[needItem].amount) or 0
                    until not _G.Auto_Farm_Set or not Target.Parent
                       or Target.Humanoid.Health <= 0
                       or have >= ((lowestSet + 1) * needAmt)
                    _G.CanAutoSkill = false
                    break
                else
                    local spawn = workspace.Itemdrops and workspace.Itemdrops:FindFirstChild(mobName)
                    if spawn then
                        Teleport(CFrame.new(spawn:GetPivot().Position))
                        task.wait(1.5)
                        break
                    end
                end
            end
        end)
    end
end)
