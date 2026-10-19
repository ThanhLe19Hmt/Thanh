-- Raid/RaidDragon.lua
local Services = require(script.Parent.Parent.Core.Services)
local Config   = require(script.Parent.Parent.Core.Config)
local ThanosHelper = require(script.RaidShared.ThanosHelper)
local BuffHelper   = require(script.RaidShared.BuffHelper)
local PortalHelper = require(script.RaidShared.PortalHelper)

local LocalPlayer = Services.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage
local CFG = Config.Dragon

_G.AutoRaidDragon         = false
_G.DragonLastFireTime     = 0
_G.DragonLastAttack       = 0
_G.DragonLastEquip        = 0
_G.DragonEnterTime        = 0
_G.DragonPortalPhase      = "IDLE"
_G.DragonPortalStartTime  = 0
_G.DragonPortalFireLock   = 0
_G.DragonAlertTriggered   = false
_G.DragonSafeZoneActive   = false
_G.DragonSafeZonePart     = nil
_G.DragonBossDeadHandled  = false
_G.DragonThanosFSuccessCount = 0
_G.DragonThanosSpamStartTime = 0
_G.DragonThanosFlyPos     = nil
_G.DragonLastThanosTime   = 0
_G.DragonBuffUsed         = false
_G.DragonBuffFinishTime   = 0
_G.DragonHasThanosEquipped = false
_G.DragonBuffSpamActive   = false

local function GetMethodFarm(h)
    h = h or CFG.AIM_HEIGHT
    return CFrame.new(0, h, 0) * CFrame.Angles(math.rad(-90), 0, 0)
end

local function OnAlert(text)
    if not text then return end
    local l = text:lower()
    if l:find("hide in the green zone", 1, true) or l:find("green zone", 1, true) then
        _G.DragonAlertTriggered = true
    end
end

local function HookText(container)
    for _, obj in ipairs(container:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            OnAlert(obj.Text)
            obj:GetPropertyChangedSignal("Text"):Connect(function() OnAlert(obj.Text) end)
        end
    end
end

local function IsSafeColor(c)
    return math.abs(c.R - 0.27) < 0.05
       and math.abs(c.G - 1.00) < 0.05
       and math.abs(c.B - 0.55) < 0.05
end

local function FindSafeZone()
    if _G.DragonSafeZonePart and _G.DragonSafeZonePart.Parent then
        return _G.DragonSafeZonePart
    end
    local vfx = workspace:FindFirstChild("VFX")
    if not vfx then return nil end
    local best, bestY = nil, math.huge
    for _, obj in ipairs(vfx:GetChildren()) do
        if obj:IsA("BasePart") and obj.Name == "Part" and IsSafeColor(obj.Color) then
            if obj.Position.Y < bestY then
                bestY = obj.Position.Y
                best = obj
            end
        end
    end
    if best then _G.DragonSafeZonePart = best end
    return best
end

local function GetBoss()
    local bf = workspace:FindFirstChild("Boss Fight")
    if not bf then return nil, nil, nil end
    local folder = bf:FindFirstChild("Dragon")
    if not folder then return nil, nil, nil end
    local boss = folder:FindFirstChild("Dragon Boss")
    if not boss then return nil, nil, nil end
    local h = boss:FindFirstChild("HumanoidRootPart")
    local hum = boss:FindFirstChild("Humanoid")
    if h and hum then return boss, h, hum end
    return nil, nil, nil
end

local function OpenPortal()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    if tick() < _G.DragonPortalFireLock then return false end

    local bf = workspace:FindFirstChild("Boss Fight")
    if bf and bf:FindFirstChild("Dragon") then
        _G.DragonPortalPhase = "IDLE"
        return true
    end

    if not _G.DragonBuffUsed then
        _G.DragonBuffUsed = true
        local tool, buffName = BuffHelper.FindBuffTool(CFG.BUFF_LIST)
        if tool then
            _G.DragonBuffFinishTime = 0
            task.spawn(function()
                BuffHelper.BuffSpamLoop(CFG.BUFF_LIST, 0.3)
                task.wait(0.3)
                _G.DragonBuffFinishTime = tick()
            end)
            return false
        else
            _G.DragonBuffFinishTime = tick()
        end
    end
    if _G.DragonBuffFinishTime == 0 then return false end
    if tick() - _G.DragonBuffFinishTime < 0.3 then return false end

    local tz = workspace:FindFirstChild("TeleportBossFightZone")
    if tz and tz:FindFirstChild("Hitbox") then
        if _G.DragonPortalPhase ~= "ENTERED" then
            hrp.CFrame = tz.Hitbox.CFrame
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            _G.DragonEnterTime = tick()
            _G.DragonPortalPhase = "ENTERED"
            _G.DragonPortalFireLock = tick() + CFG.PORTAL_FIRE_LOCK
        end
        return true
    end

    local npcPrompt = workspace:FindFirstChild("NpcPrompt")
    local openNPC = npcPrompt and npcPrompt:FindFirstChild("Open Raid")
    if openNPC and _G.DragonPortalPhase == "IDLE" then
        local npcHrp = openNPC:FindFirstChild("HumanoidRootPart")
            or openNPC:FindFirstChildWhichIsA("BasePart")
        if npcHrp then
            if (hrp.Position - npcHrp.Position).Magnitude > 10 then
                hrp.CFrame = CFrame.new(npcHrp.Position + Vector3.new(0, 3, 0))
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                task.wait(0.3)
            end
            if tick() - _G.DragonLastFireTime >= CFG.MIN_FIRE_GAP then
                local prompt = openNPC:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    _G.DragonLastFireTime = tick()
                    _G.DragonPortalPhase = "GUI_OPENING"
                    _G.DragonPortalStartTime = tick()
                    pcall(function() fireproximityprompt(prompt) end)
                    return true
                end
            end
        end
    end

    if _G.DragonPortalPhase == "GUI_OPENING" then
        local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        local main = hud and hud:FindFirstChild("Main")
        local frame = main and main:FindFirstChild("Frame_RaidBoss")
        if frame then
            local template = PortalHelper.FindTemplate(frame, "dragon")
            if template and PortalHelper.ClickOpenButton(template) then
                _G.DragonPortalPhase = "WAITING"
                _G.DragonPortalStartTime = tick()
                PortalHelper.CloseRaidBossFrame(3)
                return true
            end
        end
        if tick() - _G.DragonPortalStartTime > 5 then
            _G.DragonPortalPhase = "IDLE"
        end
        return true
    end

    if _G.DragonPortalPhase == "WAITING" then
        local tz2 = workspace:FindFirstChild("TeleportBossFightZone")
        if tz2 and tz2:FindFirstChild("Hitbox") then
            hrp.CFrame = tz2.Hitbox.CFrame
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            _G.DragonEnterTime = tick()
            _G.DragonPortalPhase = "ENTERED"
            _G.DragonPortalFireLock = tick() + CFG.PORTAL_FIRE_LOCK
            return true
        end
        if bf and bf:FindFirstChild("Dragon") then
            _G.DragonPortalPhase = "ENTERED"
            _G.DragonEnterTime = tick()
            _G.DragonPortalFireLock = tick() + CFG.PORTAL_FIRE_LOCK
            return true
        end
        if tick() - _G.DragonPortalStartTime > CFG.PORTAL_TIMEOUT then
            _G.DragonPortalPhase = "IDLE"
            _G.DragonLastFireTime = 0
        end
        return true
    end
    return false
end

HookText(LocalPlayer.PlayerGui)
LocalPlayer.PlayerGui.DescendantAdded:Connect(function(obj)
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        task.wait(0.1)
        OnAlert(obj.Text)
        obj:GetPropertyChangedSignal("Text"):Connect(function() OnAlert(obj.Text) end)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if not _G.AutoRaidDragon then return end
    _G.DragonBuffUsed = false
    _G.DragonBuffFinishTime = 0
    _G.DragonPortalPhase = "IDLE"
    _G.DragonPortalFireLock = 0
    _G.DragonEnterTime = 0
    _G.DragonBossDeadHandled = false
    _G.DragonAlertTriggered = false
    _G.DragonSafeZoneActive = false
    _G.DragonSafeZonePart = nil
    _G.DragonThanosFlyPos = nil
    _G.DragonThanosSpamStartTime = 0
    _G.DragonThanosFSuccessCount = 0
end)

task.spawn(function()
    while task.wait() do
        pcall(function()
            if not _G.AutoRaidDragon then
                _G.DragonPortalPhase = "IDLE"
                _G.DragonBossDeadHandled = false
                _G.DragonBuffUsed = false
                _G.DragonBuffFinishTime = 0
                return
            end

            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp or hum.Health <= 0 then return end

            local bossModel, bossHrp, bossHum = GetBoss()
            if not bossHrp then
                if _G.DragonPortalPhase ~= "ENTERED" then OpenPortal() end
                return
            end

            if bossHum.Health <= 0 then
                if not _G.DragonBossDeadHandled then
                    _G.DragonBossDeadHandled = true
                    _G.DragonPortalPhase = "IDLE"
                    _G.DragonPortalFireLock = tick() + CFG.PORTAL_FIRE_LOCK
                    _G.DragonAlertTriggered = false
                    _G.DragonSafeZoneActive = false
                    _G.DragonSafeZonePart = nil
                    _G.DragonBuffUsed = false
                    _G.DragonBuffFinishTime = 0
                    PortalHelper.CloseRewardFrameOnce("Dragon")
                end
                return
            end

            _G.DragonBossDeadHandled = false
            if _G.DragonEnterTime == 0 then _G.DragonEnterTime = tick() end
            bossHum.WalkSpeed = 0
            bossHum.JumpPower = 0

            local now = tick()

            -- Safe zone
            local safe = FindSafeZone()
            if safe then
                _G.DragonSafeZoneActive = true
                local pos = safe.Position + Vector3.new(0, CFG.SAFE_HEIGHT_FLY, 0)
                hrp.CFrame = CFrame.new(pos, bossHrp.Position)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                return
            end

            local hpPct = (bossHum.Health / bossHum.MaxHealth) * 100
            if hpPct <= 50 then
                if not ThanosHelper.EnsureThanosEquipped() then
                    local mf = GetMethodFarm(CFG.AIM_HEIGHT)
                    hrp.CFrame = bossHrp.CFrame * mf
                    hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    if now - _G.DragonLastAttack >= 0.15 then
                        _G.DragonLastAttack = now
                        _G.Attack()
                    end
                    return
                end

                if _G.DragonThanosSpamStartTime == 0 then
                    _G.DragonThanosSpamStartTime = now
                    _G.DragonThanosFSuccessCount = 0
                end

                local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                local main = hud and hud:FindFirstChild("Main")
                local sk = main and main:FindFirstChild("Frame_SkillList_Thanos")
                local cd = false
                if sk then
                    local b = sk:FindFirstChild("Border")
                    local mf = b and b:FindFirstChild("Main")
                    local f = mf and mf:FindFirstChild("F")
                    if f then
                        local r = f:FindFirstChild("Ready")
                        local c = f:FindFirstChild("CooldownFrame")
                        if (r and r.Text == "UnReady") or (c and c.Visible) then cd = true end
                    end
                end

                if cd then
                    if not _G.DragonThanosFlyPos then
                        _G.DragonThanosFlyPos = Vector3.new(
                            hrp.Position.X,
                            hrp.Position.Y + CFG.SAFE_HEIGHT_FLY,
                            hrp.Position.Z)
                    end
                    hrp.CFrame = CFrame.new(_G.DragonThanosFlyPos, bossHrp.Position)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    return
                end

                if now - _G.DragonLastThanosTime >= CFG.THANOS_COOLDOWN then
                    local bp = bossHrp.Position
                    hrp.CFrame = CFrame.new(bp + Vector3.new(0, CFG.AIM_HEIGHT, 0), bp)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    _G.DragonLastThanosTime = now
                    local r = ThanosHelper.TryUseThanosF(hrp)
                    if r == "success" then
                        _G.DragonThanosFSuccessCount = _G.DragonThanosFSuccessCount + 1
                        _G.DragonThanosFlyPos = nil
                        hrp.CFrame = CFrame.new(
                            hrp.Position + Vector3.new(0, 100, 0), bossHrp.Position)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end
                end
                return
            end

            local mf = GetMethodFarm(CFG.AIM_HEIGHT)
            hrp.CFrame = bossHrp.CFrame * mf
            hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
            hrp.AssemblyAngularVelocity = Vector3.zero

            if now - _G.DragonLastEquip >= 0.5 then
                _G.DragonLastEquip = now
                _G.EquipWeapon()
            end
            if now - _G.DragonLastAttack >= 0.15 then
                _G.DragonLastAttack = now
                local hasSkill = _G.AutoSkillZ or _G.AutoSkillX
                              or _G.AutoSkillC or _G.AutoSkillV or _G.AutoSkillF
                if hasSkill then _G.AutoSkill() else _G.Attack() end
            end
        end)
    end
end)
