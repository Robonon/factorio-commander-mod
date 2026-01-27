-- prototypes/items.lua
-- Items

local items = {}

items.soldier_token = {
  type = "item",
  name = "soldier-token",
  icon = "__base__/graphics/icons/light-armor.png",
  icon_size = 64,
  subgroup = "intermediate-product",
  order = "a[military]-a[token]",
  stack_size = 100
}

-- Brigade HQ building item (top-level)
items.brigade_hq = {
  type = "item",
  name = "brigade-hq",
  icon = "__base__/graphics/icons/radar.png",
  icon_size = 64,
  subgroup = "defensive-structure",
  order = "a[brigade-hq]",
  place_result = "brigade-hq",
  stack_size = 5
}

-- Battalion HQ building item (mid-level)
items.battalion_hq = {
  type = "item",
  name = "battalion-hq",
  icon = "__base__/graphics/icons/radar.png",
  icon_size = 64,
  subgroup = "defensive-structure",
  order = "b[battalion-hq]",
  place_result = "battalion-hq",
  stack_size = 10
}

items.platoon_hq = {
  type = "item",
  name = "platoon-hq",
  icon = "__base__/graphics/icons/radar.png",
  icon_size = 64,
  subgroup = "defensive-structure",
  order = "c[platoon-hq]",
  place_result = "platoon-hq",
  stack_size = 20
}

return items
