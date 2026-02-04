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

recipes.brigade_hq = {
  type = "recipe",
  name = "brigade-hq",
  enabled = true,
  energy_required = 20,
  ingredients = {
    {type = "item", name = "steel-plate", amount = 20},
    {type = "item", name = "stone-brick", amount = 10},
    {type = "item", name = "electronic-circuit", amount = 5},
    {type = "item", name = "soldier-token", amount = 12}
  },
  results = {{type = "item", name = "brigade-hq", amount = 1}}
}

recipes.battalion_hq = {
  type = "recipe",
  name = "battalion-hq",
  enabled = true,
  energy_required = 20,
  ingredients = {
    {type = "item", name = "steel-plate", amount = 20},
    {type = "item", name = "stone-brick", amount = 10},
    {type = "item", name = "electronic-circuit", amount = 5},
    {type = "item", name = "soldier-token", amount = 12}
  },
  results = {{type = "item", name = "battalion-hq", amount = 1}}
}

recipes.company_hq = {
  type = "recipe",
  name = "company-hq",
  enabled = true,
  energy_required = 20,
  ingredients = {
    {type = "item", name = "steel-plate", amount = 20},
    {type = "item", name = "stone-brick", amount = 10},
    {type = "item", name = "electronic-circuit", amount = 5},
    {type = "item", name = "soldier-token", amount = 12}
  },
  results = {{type = "item", name = "company-hq", amount = 1}}
}

recipes.platoon_hq = {
  type = "recipe",
  name = "platoon-hq",
  enabled = true,
  energy_required = 20,
  ingredients = {
    {type = "item", name = "steel-plate", amount = 20},
    {type = "item", name = "stone-brick", amount = 10},
    {type = "item", name = "electronic-circuit", amount = 5},
    {type = "item", name = "soldier-token", amount = 32}
  },
  results = {{type = "item", name = "platoon-hq", amount = 1}}
}



return recipes
