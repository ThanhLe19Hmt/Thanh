local NoVFX = {}

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local VFXLoop = nil

local function ProcessVFX(instance)
    for _, v in pairs(instance:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail") then
            if v.Enabled then v.Enabled = false end
        end
    end
end

function NoVFX.SetState(State)
    print("[VFX] State:", State)
    _G.VFXDisabled = State

    if State then
        if VFXLoop then VFXLoop:Disconnect(); VFXLoop = nil end

        VFXLoop = RunService.Heartbeat:Connect(function()
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end

                ProcessVFX(char)

                local boss = workspace:FindFirstChild("Boss")
                if boss then ProcessVFX(boss) end

                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    if hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
                    if hum.JumpPower < 50 then hum.JumpPower = 50 end
                end

                for _, name in ipairs({"Stun", "StunS"}) do
                    local folder = char:FindFirstChild(name)
                    if folder and #folder:GetChildren() > 0 then
                        folder:ClearAllChildren()
                    end
                end
            end)
        end)
        print("[VFX] ✅ Loop created")
    else
        if VFXLoop then
            VFXLoop:Disconnect()
            VFXLoop = nil
            print("[VFX] ❌ Loop disconnected")
        end
    end
end

return NoVFX
