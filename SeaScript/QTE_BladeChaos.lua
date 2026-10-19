-- ============================================================
-- QTE BLADE OF CHAOS — standalone, load qua loadstring
-- Không chiếm locals của script chính
-- ============================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local KEY_MAP = {
    A=Enum.KeyCode.A, B=Enum.KeyCode.B, C=Enum.KeyCode.C, D=Enum.KeyCode.D,
    E=Enum.KeyCode.E, F=Enum.KeyCode.F, G=Enum.KeyCode.G, H=Enum.KeyCode.H,
    I=Enum.KeyCode.I, J=Enum.KeyCode.J, K=Enum.KeyCode.K, L=Enum.KeyCode.L,
    M=Enum.KeyCode.M, N=Enum.KeyCode.N, O=Enum.KeyCode.O, P=Enum.KeyCode.P,
    Q=Enum.KeyCode.Q, R=Enum.KeyCode.R, S=Enum.KeyCode.S, T=Enum.KeyCode.T,
    U=Enum.KeyCode.U, V=Enum.KeyCode.V, W=Enum.KeyCode.W, X=Enum.KeyCode.X,
    Y=Enum.KeyCode.Y, Z=Enum.KeyCode.Z,
    ["1"]=Enum.KeyCode.One, ["2"]=Enum.KeyCode.Two, ["3"]=Enum.KeyCode.Three,
    ["4"]=Enum.KeyCode.Four, ["5"]=Enum.KeyCode.Five,
    Space=Enum.KeyCode.Space,
}

local STUCK_TIMEOUT = 0.55
local running = false

local function getBattle()
    return PlayerGui:FindFirstChild("Battle")
end

local function getCurrentKey(battle)
    local btn = battle:FindFirstChild("Button")
    if not btn then return nil end
    local tl = btn:FindFirstChild("TextLabel")
    if not tl then return nil end
    local txt = tl.Text
    if not txt or txt == "" then return nil end
    return txt
end

local function pressKey(kc)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, kc, false, game)
        task.wait(0.02)
        VirtualInputManager:SendKeyEvent(false, kc, false, game)
    end)
end

local function fireClickButton(battle)
    local cb = battle:FindFirstChild("ClickButton")
    if not cb or not cb:IsA("TextButton") then return end
    local ok, conns = pcall(function() return getconnections(cb.MouseButton1Click) end)
    if ok and conns and #conns > 0 then
        for _, c in ipairs(conns) do
            pcall(function() if c.Enabled then c:Fire() end end)
        end
    else
        pcall(function() cb:Activate() end)
    end
end

-- Vòng lặp QTE
task.spawn(function()
    local lastKey, lastKeyTime, battleWasOpen = nil, 0, false
    while true do
        task.wait(0.02)
        if not running then
            battleWasOpen = false
            lastKey = nil
            continue
        end
        local battle = getBattle()
        local isOpen = battle and battle:IsA("ScreenGui") and battle.Enabled
        if isOpen then
            if not battleWasOpen then battleWasOpen = true; lastKey = nil end
            local txt = getCurrentKey(battle)
            if txt then
                local kc = KEY_MAP[txt] or KEY_MAP[txt:upper()]
                if kc then
                    local now = os.clock()
                    if txt ~= lastKey then
                        print(("[QTE] Phím: %s"):format(txt))
                        pressKey(kc); fireClickButton(battle)
                        lastKey = txt; lastKeyTime = now
                    elseif now - lastKeyTime >= STUCK_TIMEOUT then
                        pressKey(kc); fireClickButton(battle)
                        lastKeyTime = now
                    end
                end
            else
                lastKey = nil
            end
        else
            battleWasOpen = false; lastKey = nil
        end
    end
end)

-- Toggle bằng phím RightShift (đổi nếu cần)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        running = not running
        print(("[QTE] %s"):format(running and "BẬT" or "TẮT"))
        if _G.SeaNotify then
            pcall(function() _G.SeaNotify(running and "QTE ON" or "QTE OFF", "Auto QTE Blade of Chaos", 2) end)
        end
    end
end)

print("[QTE] Standalone đã load. Nhấn RightShift để bật/tắt.")
