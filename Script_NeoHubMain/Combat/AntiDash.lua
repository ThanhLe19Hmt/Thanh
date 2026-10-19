-- Combat/AntiDash.lua
-- Anti-dash global

local Services = require(script.Parent.Parent.Core.Services)
local LocalPlayer = Services.LocalPlayer
local RunService = Services.RunService

local function IsAnyActive()
    return _G.AutoFarm or _G.AutoFarmLevel
        or _G.AutoFarmMaterial or _G.AutoBossFull
        or _G.AutoPiccolo or _G.AutoDevilBoat
        or _G.AutoKraken or _G.AutoDuckFull or _G.AutoThiefChest
        or _G.AutoRaidMoon or _G.AutoDungeon
        or _G.AutoRaidRunning or _G.AutoRaidDragon or _G.AutoRaidLava
        or _G.CraftAutoRunning or _G.AutoCraftWeaponRunning
        or _G.AutoFarmCraftItems or _G.PortalAutoRunning
        or _G.AutoFarm_Set
        or _G.Auto_CraftWeapon or _G.Auto_Farm_Level
        or _G.Auto_Farm_Material or _G.Auto_FarmBoss
        or _G.Auto_Piccolo or _G.Auto_DevilBoat
        or _G.Auto_Kraken or _G.Auto_DuckAutomatically
        or _G.Auto_BaconThief or _G.Auto_Dungeon
        or _G.Auto_Raid
end

-- Loop 1: mỗi frame
task.spawn(function()
    while task.wait() do
        pcall(function()
            if not IsAnyActive() then return end
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            hrp.AssemblyLinearVelocity  = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero

            for _, child in ipairs(hrp:GetChildren()) do
                if child:IsA("BodyVelocity")
                   or child:IsA("BodyGyro")
                   or child:IsA("AlignPosition")
                   or child:IsA("AlignOrientation")
                   or child:IsA("BodyThrust")
                   or child:IsA("BodyForce") then
                    pcall(function() child:Destroy() end)
                end
            end
        end)
    end
end)

-- Loop 2: Stepped
RunService.Stepped:Connect(function()
    if not IsAnyActive() then return end
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end)
