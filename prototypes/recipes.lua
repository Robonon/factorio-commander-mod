-- prototypes/recipes.lua
-- Crafting recipes

local recipes = {}

-- Soldier token recipe (craft at player)
recipes.soldier_token = {
  type = "recipe",
  name = "soldier-token",
  enabled = true,
  energy_required = 5,
  ingredients = {
    {type = "item", name = "submachine-gun", amount = 1},
    {type = "item", name = "firearm-magazine", amount = 10},
    {type = "item", name = "light-armor", amount = 1}
  },
  results = {{type = "item", name = "soldier-token", amount = 1}}
}

return recipes
