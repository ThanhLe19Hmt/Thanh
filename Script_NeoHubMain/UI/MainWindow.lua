-- UI/MainWindow.lua
-- Tạo cửa sổ chính + Notify

local Services = require(script.Parent.Parent.Core.Services)
local Config   = require(script.Parent.Parent.Core.Config)

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Ui_New.lua"
))()

local IS_MOON_MAP = (game.PlaceId == Config.MOON_PLACE_ID)

local Window = Library:CreateWindow({
    Title = "MarvenRiz Hub" .. (IS_MOON_MAP and " (Moon)" or ""),
    Subtitle = IS_MOON_MAP and "Auto Raid Moon Only" or "Sea 1 — Rock Fruit",
    Size = UDim2.fromOffset(500, 370),
    AccentColor = Color3.fromRGB(50, 150, 255),
    SideBarWidth = 120,
    Logo = "rbxassetid://87526284179554",
    LogoSize = 32,
    SphereText = false,
    SphereImage = "rbxassetid://87526284179554",
    SphereIconSize = 38,
    Map = "RockFruit"
})

function _G.SeaNotify(title, desc, duration)
    pcall(function()
        if Library and Library.Notify then
            Library:Notify({
                Title = title or "",
                Description = desc or "",
                Duration = duration or 4
            })
        end
    end)
end

return {
    Library = Library,
    Window  = Window,
    SaveManager = Library.SaveManager,
}
