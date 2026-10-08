--[[
    Features/Init.lua
    Gọi tất cả feature modules
]]

local Globals = _G.__Globals
assert(Globals, "[Module] _G.__Globals chưa được set! Load Main.lua trước.")
local Utils   = Globals.Utils

-- Core loops
Utils.SetupAntiAFK()
Utils.StartMethodFarmLoop()
Utils.StartNoclipLoop()
Utils.StartAntiGravityLoop()
Utils.StartAutoCloseGUI()

-- Feature loops (đã có task.spawn bên trong)
loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Features/AutoFarm.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Features/AutoBoss.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Features/AutoDungeon.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Features/AutoRaid.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Features/AutoSell.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Features/AutoChest.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Features/AutoStats.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/ThanhLe19Hmt/Thanh/refs/heads/main/Config/Features/AutoPotion.lua"))()
