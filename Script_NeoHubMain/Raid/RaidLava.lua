-- Raid/RaidLava.lua
local Services = require(script.Parent.Parent.Core.Services)
local Config   = require(script.Parent.Parent.Core.Config)
local ThanosHelper = require(script.RaidShared.ThanosHelper)
local BuffHelper   = require(script.RaidShared.BuffHelper)
local PortalHelper = require(script.RaidShared.PortalHelper)

local LocalPlayer = Services.LocalPlayer
local CFG = Config.Lava

_G.AutoRaidLava           = false
_G.LavaLastFireTime       = 0
_G.LavaLastAttack         = 0
_G.LavaLastEquip          = 0
_G.LavaEnterTime          = 0
_G.LavaPortalPhase        = "IDLE"
_G.LavaPortalStartTime    = 0
_G.LavaBossOriginPos      = nil
_G.LavaLastThanosTime     = 0
_G.LavaWaitingSurface     = false
_G.LavaBossSurfacedTime   = 0
_G.LavaPortalFireLock     = 0
_G.LavaPhase2Active       = false
_G.LavaThanosUsed         = false
_G.LavaThanosLockUntil    = 0
_G.LavaThanosFlyPos       = nil
_G.LavaBossDeadHandled    = false
_G.LavaThanosFSuccessCount = 0
_G.LavaThanosSpamStartTime = 0
_G.LavaBuffUsed           = false
_G.LavaBuffFinishTime     = 0
_G.LavaThanosHPPercent    = 50

local function GetMethodFarm(h)
    h = h or CFG.AIM_HEIGHT
    return CFrame.new(0, h, 0) * CFrame.Angles(math.rad(-90), 0, 0)
end

local function GetBoss()
    local bf = workspace:FindFirstChild("Boss Fight")
    if not bf then return nil, nil, nil end
    local folder = bf:FindFirstChild("LavaTitan")
    if not folder then return nil, nil, nil end
    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("Model") then
            local hum = obj:FindFirstChild("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hum and hrp then return obj, hrp, hum end
        end
    end
    return nil, nil, nil
end

local function OnAlert(text)
    if not text then return end
    local l = text:lower()
    if l:find("lava is rising", 1, true)
       or l:find("get on the center platform", 1, true) then
        _G.LavaPhase2Active = true
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

local function OpenPortal()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    if tick() < _G.LavaPortalFireLock then return false end

    local bf = workspace:FindFirstChild("Boss Fight")
    if bf and bf:FindFirstChild("LavaTitan") then
        _G.LavaPortalPhase = "IDLE"
        return true
    end

    if not _G.LavaBuffUsed then
        _G.LavaBuffUsed = true
        local tool = BuffHelper.FindBuffTool(CFG.BUFF_LIST)
        if tool then
            _G.LavaBuffFinishTime = 0
            task.spawn(function()
                BuffHelper.BuffSpamLoop(CFG.BUFF_LIST, 0.3)
                task.wait(0.3)
                _G.LavaBuffFinishTime = tick()
            end)
            return false
        else
            _G.LavaBuffFinishTime = tick()
        end
    end
    if _G.LavaBuffFinishTime == 0 then return false end
    if tick() - _G.LavaBuffFinishTime < 0.3 then return false end

    local tz = workspace:FindFirstChild("TeleportBossFightZone")
    if tz and tz:FindFirstChild("Hitbox") then
        if _G.LavaPortalPhase ~= "ENTERED" then
            hrp.CFrame = tz.Hitbox.CFrame
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            _G.LavaEnterTime = tick()
            _G.LavaPortalPhase = "ENTERED"
            _G.LavaPortalFireLock = tick() + CFG.PORTAL_FIRE_LOCK
        end
        return true
    end

    local npcPrompt = workspace:FindFirstChild("NpcPrompt")
    local openNPC = npcPrompt and npcPrompt:FindFirstChild("Open Raid")
    if openNPC and _G.LavaPortalPhase == "IDLE" then
        local npcHrp = openNPC:FindFirstChild("HumanoidRootPart")
            or openNPC:FindFirstChildWhichIsA("BasePart")
        if npcHrp then
            if (hrp.Position - npcHrp.Position).Magnitude > 10 then
                hrp.CFrame = CFrame.new(npcHrp.Position + Vector3.new(0, 3, 0))
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                task.wait(0.3)
            end
            if tick() - _G.LavaLastFireTime >= CFG.MIN_FIRE_GAP then
                local prompt = openNPC:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    _G.LavaLastFireTime = tick()
                    _G.LavaPortalPhase = "GUI_OPENING"
                    _G.LavaPortalStartTime = tick()
                    pcall(function() fireproximityprompt(prompt) end)
                    return true
                end
            end
        end
    end

    if _G.LavaPortalPhase == "GUI_OPENING" then
        local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        local main = hud and hud:FindFirstChild("Main")
        local frame = main and main:FindFirstChild("Frame_RaidBoss")
        if frame then
            local template = PortalHelper.FindTemplate(frame, "lavatitan")
            if template and PortalHelper.ClickOpenButton(template) then
                _G.LavaPortalPhase = "WAITING"
                _G.LavaPortalStartTime = tick()
                PortalHelper.CloseRaidBossFrame(3)
                return true
            end
        end
        if tick() - _G.LavaPortalStartTime > 5 then
            _G.LavaPortalPhase = "IDLE"
        end
        return true
    end

    if _G.LavaPortalPhase == "WAITING" then
        local tz2 = workspace:FindFirstChild("TeleportBossFightZone")
        if tz2 and tz2:FindFirstChild("Hitbox") then
            hrp.CFrame = tz2.Hitbox.CFrame
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            _G.LavaEnterTime = tick()
            _G.LavaPortalPhase = "ENTERED"
            _G.LavaPortalFireLock = tick() + CFG.PORTAL_FIRE_LOCK
            return true
        end
        if bf and bf:FindFirstChild("LavaTitan") then
            _G.LavaPortalPhase = "ENTERED"
            _G.LavaEnterTime = tick()
            _G.LavaPortalFireLock = tick() + CFG.PORTAL_FIRE_LOCK
            return true
        end
        if tick() - _G.LavaPortalStartTime > CFG.PORTAL_TIMEOUT then
            _G.LavaPortalPhase = "IDLE"
            _G.LavaLastFireTime = 0
        end
        return true
    end
    return false
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if not _G.AutoRaidLava then return end
    _G.LavaBuffUsed = false
    _G.LavaBuffFinishTime = 0
    _G.LavaPortalPhase = "IDLE"
    _G.LavaPortalFireLock = 0
    _G.LavaEnterTime = 0
    _G.LavaBossDeadHandled = false
    _G.LavaPhase2Active = false
    _G.LavaThanosFlyPos = nil
    _G.LavaThanosSpamStartTime = 0
    _G.LavaThanosFSuccessCount = 0
end)

HookText(LocalPlayer.PlayerGui)
LocalPlayer.PlayerGui.DescendantAdded:Connect(function(obj)
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        task.wait(0.1)
        OnAlert(obj.Text)
        obj:GetPropertyChangedSignal("Text"):Connect(function() OnAlert(obj.Text) end)
    end
end)

task.spawn(function()
    while task.wait() do
        pcall(function()
            if not _G.AutoRaidLava then
                _G.LavaPortalPhase = "IDLE"
                _G.LavaPhase2Active = false
                _G.LavaBossOriginPos = nil
                _G.LavaWaitingSurface = false
                _G.LavaThanosFlyPos = nil
                _G.LavaBossDeadHandled = false
                _G.LavaBuffUsed = false
                _G.LavaBuffFinishTime = 0
                return
            end

            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp or hum.Health <= 0 then return end

            local bossModel, bossHrp, bossHum = GetBoss()
            if not bossHrp then
                if _G.LavaPortalPhase ~= "ENTERED" then OpenPortal() end
                return
            end

            if bossHum.Health <= 0 then
                if not _G.LavaBossDeadHandled then
                    _G.LavaBossDeadHandled = true
                    _G.LavaPortalPhase = "IDLE"
                    _G.LavaPortalFireLock = tick() + CFG.PORTAL_FIRE_LOCK
                    _G.LavaPhase2Active = false
                    _G.LavaBuffUsed = false
                    _G.LavaBuffFinishTime = 0
                    PortalHelper.CloseRewardFrameOnce("Lava")
                end
                return
            end

            _G.LavaBossDeadHandled = false
            if _G.LavaEnterTime == 0 then _G.LavaEnterTime = tick() end
            bossHum.WalkSpeed = 0
            bossHum.JumpPower = 0
            local now = tick()

            if not _G.LavaBossOriginPos then
                _G.LavaBossOriginPos = bossHrp.Position
            end

            local hpPct = (bossHum.Health / bossHum.MaxHealth) * 100
            local threshold = _G.LavaThanosHPPercent or 50

            if hpPct <= threshold then
                if not ThanosHelper.EnsureThanosEquipped() then
                    local mf = GetMethodFarm(CFG.AIM_HEIGHT)
                    hrp.CFrame = bossHrp.CFrame * mf
                    hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    if now - _G.LavaLastAttack >= 0.15 then
                        _G.LavaLastAttack = now
                        _G.Attack()
                    end
                    return
                end

                if _G.LavaThanosSpamStartTime == 0 then
                    _G.LavaThanosSpamStartTime = now
                    _G.LavaThanosFSuccessCount = 0
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
                    if not _G.LavaThanosFlyPos then
                        _G.LavaThanosFlyPos = Vector3.new(
                            hrp.Position.X,
                            hrp.Position.Y + CFG.SAFE_HEIGHT,
                            hrp.Position.Z)
                    end
                    hrp.CFrame = CFrame.new(_G.LavaThanosFlyPos, bossHrp.Position)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    return
                end

                if now - _G.LavaLastThanosTime >= CFG.THANOS_COOLDOWN then
                    local bp = bossHrp.Position
                    hrp.CFrame = CFrame.new(bp + Vector3.new(0, CFG.AIM_HEIGHT, 0), bp)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    _G.LavaLastThanosTime = now
                    local r = ThanosHelper.TryUseThanosF(hrp)
                    if r == "success" then
                        _G.LavaThanosFSuccessCount = _G.LavaThanosFSuccessCount + 1
                        _G.LavaThanosUsed = true
                        _G.LavaThanosFlyPos = Vector3.new(
                            hrp.Position.X,
                            hrp.Position.Y + CFG.SAFE_HEIGHT,
                            hrp.Position.Z)
                        hrp.CFrame = CFrame.new(_G.LavaThanosFlyPos, bossHrp.Position)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end
                end
                return
            end

            -- Boss lặn
            if bossHrp.Position.Y < CFG.UNDER_LAVA_Y then
                if not _G.LavaWaitingSurface then
                    _G.LavaWaitingSurface = true
                    _G.LavaBossSurfacedTime = 0
                end
                local origin = _G.LavaBossOriginPos or bossHrp.Position
                local safe = origin + Vector3.new(0, CFG.AIM_HEIGHT, 0)
                hrp.CFrame = CFrame.new(safe, origin)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                return
            else
                if _G.LavaWaitingSurface then
                    if _G.LavaBossSurfacedTime == 0 then
                        _G.LavaBossSurfacedTime = now
                    end
                    if now - _G.LavaBossSurfacedTime < CFG.SURFACE_DELAY then
                        local origin = _G.LavaBossOriginPos or bossHrp.Position
                        local safe = origin + Vector3.new(0, CFG.AIM_HEIGHT, 0)
                        hrp.CFrame = CFrame.new(safe, origin)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        return
                    end
                    _G.LavaWaitingSurface = false
                    _G.LavaBossSurfacedTime = 0
                end
            end

            local mf = GetMethodFarm(CFG.AIM_HEIGHT)
            hrp.CFrame = bossHrp.CFrame * mf
            hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
            hrp.AssemblyAngularVelocity = Vector3.zero

            if now - _G.LavaLastEquip >= 0.5 then
                _G.LavaLastEquip = now
                _G.EquipWeapon()
            end
            if now - _G.LavaLastAttack >= 0.15 then
                _G.LavaLastAttack = now
                local hasSkill = _G.AutoSkillZ or _G.AutoSkillX
                              or _G.AutoSkillC or _G.AutoSkillV or _G.AutoSkillF
                if hasSkill then _G.AutoSkill() else _G.Attack() end
            end
        end)
    end
end)
