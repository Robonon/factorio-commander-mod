-- data.lua

local entities = require("prototypes.entities")
local items = require("prototypes.items")
local recipes = require("prototypes.recipes")

-- Register entities: units and buildings
data:extend{
  entities.brigade_hq,
  entities.battalion_hq,
  entities.company_hq,
  entities.platoon_hq,
  entities.soldier,
}

-- Register items
data:extend{
  items.brigade_hq,
  items.battalion_hq,
  items.company_hq,
  items.platoon_hq,
  items.soldier_token,
}

-- Register recipes
data:extend{
  recipes.brigade_hq,
  recipes.battalion_hq,
  recipes.company_hq,
  recipes.platoon_hq,
  recipes.soldier_token,
}

-- icons
-- data:extend({
--   {
--     type = "virtual-signal",
--     name = "nato-platoon-signal",
--     icon = "__commander__/assets/platoon.png",
--     icon_size = 32
--   },
--   {
--     type = "virtual-signal",
--     name = "nato-squad-signal",
--     icon = "__commander__/assets/squad.png",
--     icon_size = 32
--   },
-- })