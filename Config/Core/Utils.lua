--[[
    Core/Utils.lua
]]

local Utils = {}

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer

-- ===== Teleport =====
function Utils.Teleport(pos)
    local char = LocalPlayer.Character
    if char then char:PivotTo(pos) end
end

-- ===== Anti AFK =====
function Utils.SetupAntiAFK()
    local VirtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

-- ===== Method Farm CFrame =====
function Utils.GetMethodFarm()
    local d = _G.Distance_Farm or 5
    local m = _G.Select_Method or "Upper"
    if m == "Behind" then
        return CFrame.new(0, 0, d)
    elseif m == "Front" then
        return CFrame.new(0, 0, -d) * CFrame.Angles(0, math.rad(180), 0)
    elseif m == "Below" then
        return CFrame.new(0, -d, 0) * CFrame.Angles(math.rad(90), 0, 0)
    else
        return CFrame.new(0, d, 0) * CFrame.Angles(math.rad(-90), 0, 0)
    end
end

-- ===== Start Method Farm loop =====
function Utils.StartMethodFarmLoop()
    task.spawn(function()
        while task.wait() do
            pcall(function()
                Utils.MethodFarm = Utils.GetMethodFarm()
            end)
        end
    end)
end

-- ===== Auto close reward GUI =====
function Utils.StartAutoCloseGUI()
    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                if not hud or not hud:FindFirstChild("Main") then return end
                local closeList = {
                    {_G.Auto_Dungeon,    "Frame_DungeonItem"},
                    {_G.AutoRaidRunning, "Frame_RaidbossItem"}
                }
                for _, entry in ipairs(closeList) do
                    if entry[1] then
                        local fd = hud.Main:FindFirstChild(entry[2])
                        if fd and fd.Visible then
                            task.wait(2)
                            local closeBtn = fd:FindFirstChild("Close_")
                                or fd:FindFirstChild("Close")
                                or fd:FindFirstChild("CloseButton")
                                or fd:FindFirstChild("Exit")
                            if closeBtn then
                                pcall(function()
                                    if firesignal then
                                        firesignal(closeBtn.MouseButton1Click)
                                    else
                                        closeBtn:Activate()
                                    end
                                end)
                            else
                                fd.Visible = false
                            end
                        end
                    end
                end
            end)
        end
    end)
end

-- ===== Noclip =====
function Utils.StartNoclipLoop()
    task.spawn(function()
        pcall(function()
            game:GetService("RunService").Stepped:Connect(function()
                if _G.Auto_Farm_Level or _G.Auto_CraftWeapon or _G.Auto_Farm_Material
                    or _G.Auto_FarmBoss_Automatically or _G.Auto_FarmBoss
                    or _G.Auto_DuckAutomatically or _G.Auto_Duck or _G.Auto_Farm_Set
                    or _G.Auto_Raid or _G.Auto_BaconThief or _G.Auto_Dungeon
                    or _G.Auto_Piccolo or _G.Auto_DevilBoat then

                    local char = LocalPlayer.Character
                    if not char then return end
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end

                    if not hrp:FindFirstChild("BodyClip") then
                        local bp = Instance.new("BodyVelocity")
                        bp.Name = "BodyClip"
                        bp.Parent = hrp
                        bp.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                        bp.Velocity = Vector3.new(0, 0, 0)
                    end
                else
                    local char = LocalPlayer.Character
                    if char then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp and hrp:FindFirstChild("BodyClip") then
                            hrp.BodyClip:Destroy()
                        end
                    end
                end
            end)
        end)
    end)
end

-- ===== Anti-gravity =====
function Utils.StartAntiGravityLoop()
    task.spawn(function()
        while task.wait() do
            if _G.Auto_Farm_Level or _G.Auto_CraftWeapon or _G.Auto_Farm_Material
                or _G.Auto_FarmBoss_Automatically or _G.Auto_FarmBoss
                or _G.Auto_DuckAutomatically or _G.Auto_Duck or _G.Auto_Farm_Set
                or _G.Auto_Raid or _G.Auto_BaconThief or _G.Auto_Dungeon
                or _G.Auto_Piccolo then
                pcall(function()
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        local v = hrp.AssemblyLinearVelocity
                        hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
                    end
                end)
            end
        end
    end)
end

-- ===== Notify (an toàn, dùng _G.__Globals) =====
function Utils.Notify(title, desc, duration)
    local G = _G.__Globals
    if not G then
        print("[Notify]", title, "-", desc)
        return
    end
    if not G.Library then
        print("[Notify - no Library]", title, "-", desc)
        return
    end
    pcall(function()
        G.Library:Notify({
            Title = title,
            Description = desc,
            Duration = duration or 3
        })
    end)
end

return Utils
