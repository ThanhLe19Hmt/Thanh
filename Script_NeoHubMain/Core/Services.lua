-- Core/Services.lua
-- Tất cả services Roblox

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local HttpService         = game:GetService("HttpService")
local RunService          = game:GetService("RunService")
local VirtualUser         = game:GetService("VirtualUser")
local GuiService          = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

return {
    Players             = Players,
    ReplicatedStorage   = ReplicatedStorage,
    HttpService         = HttpService,
    RunService          = RunService,
    VirtualUser         = VirtualUser,
    GuiService          = GuiService,
    VirtualInputManager = VirtualInputManager,
    LocalPlayer         = Players.LocalPlayer,
}
