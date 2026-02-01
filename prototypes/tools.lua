-- prototypes/tools.lua
-- Custom keyboard inputs and tools for the commander mod

local tools = {}

-- Selection tool for deploying battalions (ephemeral - cursor only)
tools.selection_tools = {
  {
    type = "selection-tool",
    name = "command-order-tool",
    icon = "__base__/graphics/icons/arrows/down-arrow.png",
    alt_select = { mode = "nothing", border_color = {r=0, g=1, b=0}, cursor_box_type = "entity" },
    stack_size = 1,
    flags = {},
    subgroup = "tool",
    order = "c[automated-construction]-a[blueprint]",
    select_sound = { filename = "__core__/sound/selection-tool-select.ogg" },
    select = { mode = "nothing", border_color = {r=0, g=1, b=0}, cursor_box_type = "entity" }
  }
}

return tools
