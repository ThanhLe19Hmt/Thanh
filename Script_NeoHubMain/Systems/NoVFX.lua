-- Systems/NoVFX.lua
-- Disable VFX event-driven

local Services = require(script.Parent.Parent.Core.Services)
local LocalPlayer = Services.LocalPlayer

local VFX_CONNECTIONS = {}
local VFX_KILL_CLASSES = {
    ["ParticleEmitter"] = true, ["Beam"] = true, ["Trail"] = true,
    ["Sparkles"] = true, ["Fire"] = true, ["Smoke"] = true,
    ["Highlight"] = true, ["PointLight"] = true, ["SpotLight"] = true,
    ["SurfaceLight"] = true,
}

local function TryKillVFX(obj)
    if not obj or not obj.Parent then return end
    local cls = obj.ClassName
    if not VFX_KILL_CLASSES[cls] then return end
    pcall(function()
        if cls == "Highlight" or cls == "PointLight"
           or cls == "SpotLight" or cls == "SurfaceLight"
           or cls == "ParticleEmitter" or cls == "Beam"
           or cls == "Trail" or cls == "Sparkles"
           or cls == "Fire" or cls == "Smoke" then
            if obj.Enabled then obj.Enabled = false end
        end
    end)
end

local function KillVFXIn(container)
    if not container then return end
    pcall(function()
        for _, v in ipairs(container:GetDescendants()) do
            TryKillVFX(v)
        end
    end)
end

local function HookContainer(container)
    if not container then return end
    local conn = container.DescendantAdded:Connect(function(obj)
        if _G.VFXDisabled then TryKillVFX(obj) end
    end)
    table.insert(VFX_CONNECTIONS, conn)
end

function NoVFX(State)
    _G.VFXDisabled = State

    for _, conn in ipairs(VFX_CONNECTIONS) do
        pcall(function() conn:Disconnect() end)
    end
    VFX_CONNECTIONS = {}

    if not State then return end

    KillVFXIn(workspace)
    local cam = workspace.CurrentCamera
    if cam then KillVFXIn(cam) end
    local char = LocalPlayer.Character
    if char then KillVFXIn(char) end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then KillVFXIn(pg) end

    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            if hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
            if hum.JumpPower < 50 then hum.JumpPower = 50 end
        end
        for _, folderName in ipairs({"Stun", "StunS"}) do
            local folder = char:FindFirstChild(folderName)
            if folder and #folder:GetChildren() > 0 then
                pcall(function() folder:ClearAllChildren() end)
            end
        end
    end

    HookContainer(workspace)
    if cam then HookContainer(cam) end
    if char then HookContainer(char) end
    if pg then HookContainer(pg) end

    local respawnConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
        if not _G.VFXDisabled then return end
        task.wait(0.5)
        KillVFXIn(newChar)
        HookContainer(newChar)
    end)
    table.insert(VFX_CONNECTIONS, respawnConn)
end

_G.NoVFX = NoVFX
return NoVFX
