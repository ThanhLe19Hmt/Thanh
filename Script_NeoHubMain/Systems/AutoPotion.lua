-- Systems/AutoPotion.lua
local Services = require(script.Parent.Parent.Core.Services)
local Helpers  = require(script.Parent.Parent.Core.Helpers)

local LocalPlayer = Services.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage

local POTION_TIME_MAP = {
    ["X2 EXP 15min."]     = "x2ExpTime",
    ["X2 Diamond 15min."] = "x2DiamondTime",
    ["X2 Lucky 15min."]   = "x2LuckTime",
    ["X2 Rebirth 15min."] = "x2RebirthTime",
    ["X2 Item 15min."]    = "x2ItemTime",
}

task.spawn(function()
    local lastUseTime = {}
    while task.wait(0.3) do
        pcall(function()
            -- Auto use (chỉ khi time = 0)
            if not _G.Auto_Use_Potion then return end
            if type(_G.Select_Potion) ~= "table" or #_G.Select_Potion == 0 then return end

            local remote = ReplicatedStorage:FindFirstChild("Remotes")
            remote = remote and remote:FindFirstChild("Inventory")
            if not remote then return end

            local Inv = Helpers.GetInventory()

            for _, potionName in ipairs(_G.Select_Potion) do
                local attrName = POTION_TIME_MAP[potionName]
                if attrName then
                    local timeLeft = tonumber(LocalPlayer:GetAttribute(attrName)) or 0
                    if timeLeft <= 0 then
                        local last = lastUseTime[potionName] or 0
                        if tick() - last >= 2 then
                            local have = (Inv[potionName] and Inv[potionName].amount) or 0
                            if have > 0 then
                                lastUseTime[potionName] = tick()
                                pcall(function() remote:FireServer(potionName) end)
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- Export helper cho UI dùng
return {
    POTION_TIME_MAP = POTION_TIME_MAP,
}
