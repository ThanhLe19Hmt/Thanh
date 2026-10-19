-- Systems/AntiIdle.lua
local Services = require(script.Parent.Parent.Core.Services)
local LocalPlayer = Services.LocalPlayer
local VirtualUser = Services.VirtualUser

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)
