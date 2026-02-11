local M = {}

M.select_unit = {
    name = "select-unit",
    type = "custom-input",
    key_sequence = "SHIFT + mouse-button-1",
    action = "lua",
    consuming = "none",
    include_selected_prototype = true
}

M.command_unit = {
    name = "command-unit",
    type = "custom-input",
    key_sequence = "SHIFT + mouse-button-2",
    action = "lua",
    consuming = "none",
    include_selected_prototype = true
}

return M