-- Raid/RaidBacon.lua
-- Auto Raid Bacon of Grudge (dùng helper chung)

local Services = require(script.Parent.Parent.Core.Services)
local Helpers  = require(script.Parent.Parent.Core.Helpers)
local Config   = require(script.Parent.Parent.Core.Config)
local ThanosHelper = require(script.RaidShared.ThanosHelper)
local BuffHelper   = require(script.RaidShared.BuffHelper)
local PortalHelper = require(script.RaidShared.PortalHelper)

local LocalPlayer = Services.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage

local CFG = Config.Bacon

-- State
_G.AutoRaidRunning          = false
_G.RaidLastFireTime         = 0
_G.RaidLastAttack           = 0
_G.RaidLastEquip            = 0
_G.RaidEnterTime            = 0
_G.RaidPortalPhase          = "IDLE"
_G.RaidPortalStartTime      = 0
_G.RaidPortalFireLock       = 0
_G.RaidBossDeadHandled      = false
_G.RaidThanosFSuccessCount  = 0
_G.RaidThanosSpamStartTime  = 0
_G.RaidThanosUsed           = false
_G.RaidLastThanosTime       = 0
_G.RaidBuffUsed             = false
_G.RaidBuffFinishTime       = 0
_G.RaidCurrentTargetType    = nil
_G.RaidThanosPhase          = "IDLE"
_G.RaidThanosHoverFixedPos  = nil
_G.RaidThanosHoverStart     = 0
_G.RaidOriginalPos          = nil
_G.RaidThanosHPPercent      = 50

local function GetMethodFarm(h)
    h = h or CFG.AIM_HEIGHT
    return CFrame.new(0, h, 0) * CFrame.Angles(math.rad(-90), 0, 0)
end

local function GetTarget()
    local bf = workspace:FindFirstChild("Boss Fight")
    if not bf then return nil, nil, nil end
    local folder = bf:FindFirstChild("Bacon of Grudge")
    if not folder then return nil, nil, nil end

    local A1 = folder:FindFirstChild("ArmorBall1")
    local A2 = folder:FindFirstChild("ArmorBall2")
    local Boss = folder:FindFirstChild("Boss Bacon Sad")

    local function alive(m)
        return m and m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0
    end

    if alive(A1) then return A1, "ArmorBall1", "ArmorBall" end
    if alive(A2) then return A2, "ArmorBall2", "ArmorBall" end
    if alive(Boss) then return Boss, "Boss Bacon Sad", "Boss" end
    return nil, nil, nil
end

local function OpenPortal()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    if tick() < _G.RaidPortalFireLock then return false end

    local bf = workspace:FindFirstChild("Boss Fight")
    if bf and bf:FindFirstChild("Bacon of Grudge") then
        _G.RaidPortalPhase = "IDLE"
        return true
    end

    -- Buff trước
    if not _G.RaidBuffUsed then
        _G.RaidBuffUsed = true
        local tool, buffName = BuffHelper.FindBuffTool(CFG.BUFF_LIST)
        if tool then
            _G.RaidBuffFinishTime = 0
            task.spawn(function()
                BuffHelper.BuffSpamLoop(CFG.BUFF_LIST, 0.3)
                task.wait(0.3)
                _G.RaidBuffFinishTime = tick()
                _G.RaidPortalPhase = "IDLE"
                _G.RaidLastFireTime = 0
            end)
            return false
        else
            _G.RaidBuffFinishTime = tick()
        end
    end

    if _G.RaidBuffFinishTime == 0 then return false end
    if tick() - _G.RaidBuffFinishTime < 0.3 then return false end

    -- Portal
    local tz = workspace:FindFirstChild("TeleportBossFightZone")
    if tz and tz:FindFirstChild("Hitbox") then
        if _G.RaidPortalPhase ~= "ENTERED" then
            hrp.CFrame = tz.Hitbox.CFrame
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            _G.RaidEnterTime = tick()
            _G.RaidPortalPhase = "ENTERED"
            _G.RaidPortalFireLock = tick() + CFG.PORTAL_FIRE_LOCK
        end
        return true
    end

    -- NPC
    local npcPrompt = workspace:FindFirstChild("NpcPrompt")
    local openNPC = npcPrompt and npcPrompt:FindFirstChild("Open Raid")
    if openNPC and _G.RaidPortalPhase == "IDLE" then
        local npcHrp = openNPC:FindFirstChild("HumanoidRootPart")
            or openNPC:FindFirstChildWhichIsA("BasePart")
        if npcHrp then
            if (hrp.Position - npcHrp.Position).Magnitude > 10 then
                hrp.CFrame = CFrame.new(npcHrp.Position + Vector3.new(0, 3, 0))
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                task.wait(0.3)
            end
            if tick() - _G.RaidLastFireTime >= CFG.MIN_FIRE_GAP then
                local prompt = openNPC:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    _G.RaidLastFireTime = tick()
                    _G.RaidPortalPhase = "GUI_OPENING"
                    _G.RaidPortalStartTime = tick()
                    pcall(function() fireproximityprompt(prompt) end)
                    return true
                end
            end
        end
    end

    -- Click GUI
    if _G.RaidPortalPhase == "GUI_OPENING" then
        local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        local main = hud and hud:FindFirstChild("Main")
        local frame = main and main:FindFirstChild("Frame_RaidBoss")
        if frame then
            local template = PortalHelper.FindTemplate(frame, "bacon")
            if template then
                if PortalHelper.ClickOpenButton(template) then
                    _G.RaidPortalPhase = "WAITING"
                    _G.RaidPortalStartTime = tick()
                    PortalHelper.CloseRaidBossFrame(3)
                    return true
                end
            end
        end
        if tick() - _G.RaidPortalStartTime > 5 then
            _G.RaidPortalPhase = "IDLE"
        end
        return true
    end

    -- Wait portal
    if _G.RaidPortalPhase == "WAITING" then
        local tz2 = workspace:FindFirstChild("TeleportBossFightZone")
        if tz2 and tz2:FindFirstChild("Hitbox") then
            hrp.CFrame = tz2.Hitbox.CFrame
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            _G.RaidEnterTime = tick()
            _G.RaidPortalPhase = "ENTERED"
            _G.RaidPortalFireLock = tick() + CFG.PORTAL_FIRE_LOCK
            return true
        end
        if bf and bf:FindFirstChild("Bacon of Grudge") then
            _G.RaidPortalPhase = "ENTERED"
            _G.RaidEnterTime = tick()
            _G.RaidPortalFireLock = tick() + CFG.PORTAL_FIRE_LOCK
            return true
        end
        if tick() - _G.RaidPortalStartTime > CFG.PORTAL_TIMEOUT then
            _G.RaidPortalPhase = "IDLE"
            _G.RaidLastFireTime = 0
        end
        return true
    end
    return false
end

-- Respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if not _G.AutoRaidRunning then return end
    _G.RaidBuffUsed = false
    _G.RaidBuffFinishTime = 0
    _G.RaidPortalPhase = "IDLE"
    _G.RaidPortalFireLock = 0
    _G.RaidEnterTime = 0
    _G.RaidBossDeadHandled = false
    _G.RaidThanosSpamStartTime = 0
    _G.RaidThanosFSuccessCount = 0
    _G.RaidCurrentTargetType = nil
    _G.RaidThanosPhase = "IDLE"
    _G.RaidThanosHoverFixedPos = nil
    _G.RaidThanosHoverStart = 0
end)

-- Main loop
task.spawn(function()
    while task.wait() do
        pcall(function()
            if not _G.AutoRaidRunning then
                _G.RaidPortalPhase = "IDLE"
                _G.RaidBossDeadHandled = false
                _G.RaidThanosFSuccessCount = 0
                _G.RaidThanosSpamStartTime = 0
                _G.RaidThanosUsed = false
                _G.RaidBuffUsed = false
                _G.RaidBuffFinishTime = 0
                _G.RaidCurrentTargetType = nil
                _G.RaidThanosPhase = "IDLE"
                _G.RaidThanosHoverFixedPos = nil
                _G.RaidThanosHoverStart = 0
                return
            end

            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp or hum.Health <= 0 then return end

            local target, _, targetType = GetTarget()
            if not target then
                if _G.RaidPortalPhase ~= "ENTERED" then OpenPortal() end
                return
            end

            local tHum = target:FindFirstChild("Humanoid")
            local tHrp = target:FindFirstChild("HumanoidRootPart")
            if not tHum or not tHrp then return end

            -- Boss chết
            if tHum.Health <= 0 then
                if targetType == "Boss" then
                    if not _G.RaidBossDeadHandled then
                        _G.RaidBossDeadHandled = true
                        _G.RaidPortalPhase = "IDLE"
                        _G.RaidPortalFireLock = tick() + CFG.PORTAL_FIRE_LOCK
                        _G.RaidBuffUsed = false
                        _G.RaidBuffFinishTime = 0
                        PortalHelper.CloseRewardFrameOnce("Bacon")
                    end
                    return
                else
                    _G.RaidCurrentTargetType = nil
                    _G.RaidThanosPhase = "IDLE"
                    return
                end
            end

            _G.RaidBossDeadHandled = false
            if _G.RaidEnterTime == 0 then _G.RaidEnterTime = tick() end
            tHum.WalkSpeed = 0
            tHum.JumpPower = 0

            local now = tick()

            -- Armor Ball
            if targetType == "ArmorBall" then
                _G.RaidCurrentTargetType = "ArmorBall"
                local mf = GetMethodFarm(CFG.AIM_HEIGHT)
                hrp.CFrame = tHrp.CFrame * mf
                hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
                hrp.AssemblyAngularVelocity = Vector3.zero

                if now - _G.RaidLastEquip >= 0.5 then
                    _G.RaidLastEquip = now
                    _G.EquipWeapon()
                end
                if now - _G.RaidLastAttack >= 0.15 then
                    _G.RaidLastAttack = now
                    local hasSkill = _G.AutoSkillZ or _G.AutoSkillX
                                  or _G.AutoSkillC or _G.AutoSkillV or _G.AutoSkillF
                    if hasSkill then _G.AutoSkill() else _G.Attack() end
                end
                return
            end

            -- Boss
            if targetType == "Boss" then
                local hpPct = (tHum.Health / tHum.MaxHealth) * 100
                local threshold = _G.RaidThanosHPPercent or 50
                local isThanos = hpPct <= threshold

                if isThanos then
                    if _G.RaidCurrentTargetType ~= "Boss_Thanos" then
                        _G.RaidCurrentTargetType = "Boss_Thanos"
                        _G.RaidThanosPhase = "HOVER"
                        _G.RaidThanosHoverStart = 0
                    end

                    if _G.RaidThanosPhase == "HOVER" then
                        if not _G.RaidThanosHoverFixedPos then
                            _G.RaidThanosHoverFixedPos = hrp.Position + Vector3.new(0, 100, 0)
                        end
                        if _G.RaidThanosHoverStart == 0 then
                            _G.RaidThanosHoverStart = tick()
                        end
                        hrp.CFrame = CFrame.new(_G.RaidThanosHoverFixedPos)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        if tick() - _G.RaidThanosHoverStart >= CFG.HOVER_DELAY then
                            _G.RaidThanosPhase = "SPAM_F"
                            _G.RaidThanosHoverStart = 0
                        end
                        return
                    end

                    if _G.RaidThanosPhase == "SPAM_F" then
                        if not ThanosHelper.EnsureThanosEquipped() then
                            _G.RaidThanosPhase = "IDLE"
                            return
                        end
                        if _G.RaidThanosSpamStartTime == 0 then
                            _G.RaidThanosSpamStartTime = now
                            _G.RaidThanosFSuccessCount = 0
                        end

                        -- Check CD
                        local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                        local main = hud and hud:FindFirstChild("Main")
                        local sk = main and main:FindFirstChild("Frame_SkillList_Thanos")
                        local cd = false
                        if sk then
                            local border = sk:FindFirstChild("Border")
                            local mf = border and border:FindFirstChild("Main")
                            local f = mf and mf:FindFirstChild("F")
                            if f then
                                local r = f:FindFirstChild("Ready")
                                local c = f:FindFirstChild("CooldownFrame")
                                if (r and r.Text == "UnReady") or (c and c.Visible) then cd = true end
                            end
                        end
                        if cd then
                            _G.RaidThanosPhase = "HOVER"
                            _G.RaidThanosHoverStart = 0
                            _G.RaidThanosSpamStartTime = 0
                            return
                        end

                        if now - _G.RaidLastThanosTime >= CFG.THANOS_COOLDOWN then
                            local bp = tHrp.Position
                            hrp.CFrame = CFrame.new(bp + Vector3.new(0, CFG.BOSS_HEIGHT, 0), bp)
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                            _G.RaidLastThanosTime = now
                            local r = ThanosHelper.TryUseThanosF(hrp)
                            if r == "success" then
                                _G.RaidThanosFSuccessCount = _G.RaidThanosFSuccessCount + 1
                                _G.RaidThanosUsed = true
                                _G.RaidThanosPhase = "HOVER"
                                _G.RaidThanosHoverStart = 0
                            end
                        end
                        return
                    end
                    _G.RaidThanosPhase = "HOVER"
                    _G.RaidThanosHoverStart = 0
                    return
                else
                    if _G.RaidCurrentTargetType ~= "Boss_Normal" then
                        _G.RaidCurrentTargetType = "Boss_Normal"
                    end
                    _G.RaidThanosUsed = false
                    _G.RaidThanosSpamStartTime = 0
                    _G.RaidThanosFSuccessCount = 0
                    _G.RaidThanosPhase = "IDLE"
                    _G.RaidThanosHoverFixedPos = nil
                    _G.RaidThanosHoverStart = 0

                    local mf = GetMethodFarm(CFG.BOSS_HEIGHT)
                    hrp.CFrame = tHrp.CFrame * mf
                    hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
                    hrp.AssemblyAngularVelocity = Vector3.zero

                    if now - _G.RaidLastEquip >= 0.5 then
                        _G.RaidLastEquip = now
                        _G.EquipWeapon()
                    end
                    if now - _G.RaidLastAttack >= 0.15 then
                        _G.RaidLastAttack = now
                        local hasSkill = _G.AutoSkillZ or _G.AutoSkillX
                                      or _G.AutoSkillC or _G.AutoSkillV or _G.AutoSkillF
                        if hasSkill then _G.AutoSkill() else _G.Attack() end
                    end
                    return
                end
            end
        end)
    end
end)
