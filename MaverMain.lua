local PLACEID_SEA1 = 119091355492870
local PLACEID_SEA2 = 132854526011923

local URL_SEA1 = "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/MaverSEA1ROCKFRULT.lua"
local URL_SEA2 = "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/MaverSEA2ROCKFRULT.lua"
local placeId = game.PlaceId

local function LoadScript(url, mapName)

    local success, source = pcall(function()
        return game:HttpGet(url)
    end)

    if not success or not source or source == "" then
        return false
    end

    local execSuccess, execErr = pcall(function()
        local func, compileErr = loadstring(source)
        if not func then
            error("Compile error: " .. tostring(compileErr))
        end
        func()
    end)

    if not execSuccess then
        return false
    end
    return true
end

if placeId == PLACEID_SEA1 then
    LoadScript(URL_SEA1, "Sea 1")
elseif placeId == PLACEID_SEA2 then
    LoadScript(URL_SEA2, "Sea 2")
else
    return
end
