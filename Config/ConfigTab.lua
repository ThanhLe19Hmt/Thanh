local ConfigTab = {}

function ConfigTab:Init(Window, Library)
    local Tab = Window:CreateTab("Config", false, false)
    Library.SaveManager:BuildConfigTab(Tab)
end

return ConfigTab
