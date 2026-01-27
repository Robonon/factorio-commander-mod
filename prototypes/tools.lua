-- prototypes/tools.lua
-- Custom keyboard inputs and tools for the commander mod

local tools = {}

tools.inputs = {
  {
    type = "custom-input",
    name = "commander-toggle-overlay",
    key_sequence = "M",
    order = "a"
  },
  {
    type = "custom-input",
    name = "commander-toggle-overlay",
    key_sequence = "TAB",
    order = "a"
  },
}

-- Selection tool for deploying battalions (ephemeral - cursor only)
tools.selection_tools = {
  {
    type = "selection-tool",
    name = "commander-deploy-tool",
    icon = "__base__/graphics/icons/signal/signal_blue.png",
    icon_size = 64,
    subgroup = "tool",
    order = "c[automated-construction]-d[commander]",
    stack_size = 1,
    hidden = true,
    hidden_in_factoriopedia = true,
    flags = {"only-in-cursor", "spawnable", "not-stackable"},
    select = {
      border_color = {r = 0, g = 0.8, b = 1},
      cursor_box_type = "copy",
      mode = "any-tile",
    },
    alt_select = {
      border_color = {r = 1, g = 0.3, b = 0.3},
      cursor_box_type = "not-allowed",
      mode = "any-tile",
    },
  },
}

return tools
