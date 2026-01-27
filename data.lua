-- data.lua

local entities = require("prototypes.entities")
local items = require("prototypes.items")
local recipes = require("prototypes.recipes")
local tools = require("prototypes.tools")
local platoon = require("scripts.platoon")
local squad = require("scripts.squad")

-- Register entities: units and buildings
data:extend{
  entities.soldier,
  entities.hq_squad,
  entities.brigade_hq,
  entities.battalion_hq,
  entities.platoon_hq,
}

-- Register items
data:extend{
  items.soldier_token,
  items.brigade_hq,
  items.battalion_hq,
  items.platoon_hq,
}

-- Register recipes
data:extend{
  recipes.soldier_token,
}

-- Register custom inputs (keybinds)
for _, input in ipairs(tools.inputs) do
  data:extend{input}
end

-- Register selection tools
for _, tool in ipairs(tools.selection_tools) do
  data:extend{tool}
end
