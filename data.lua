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
  recipes.platoon_hq,
}

-- Register selection tools
for _, tool in ipairs(tools.selection_tools) do
  data:extend{tool}
end

-- icons
data:extend({
  {
    type = "virtual-signal",
    name = "nato-platoon-signal",
    icon = "__commander__/assets/platoon.png",
    icon_size = 32
  },
  {
    type = "virtual-signal",
    name = "nato-squad-signal",
    icon = "__commander__/assets/squad.png",
    icon_size = 32
  },
})