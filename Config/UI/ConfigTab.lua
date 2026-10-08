local Globals = _G.__Globals
assert(Globals, "[ConfigTab] _G.__Globals chưa được set!")

local ConfigTab = {}

function ConfigTab:Init(Window, Library)
    local Tab = Window:CreateTab("Config", false, false)
    Library.SaveManager:BuildConfigTab(Tab)
end

return ConfigTab
