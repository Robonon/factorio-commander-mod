-- prototypes/items.lua
-- Items

local items = {}

items.soldier_token = {
  type = "item",
  name = "soldier-token",
  icon = "__base__/graphics/icons/light-armor.png",
  icon_size = 64,
  subgroup = "military-equipment",
  order = "a[military]-a[token]",
  stack_size = 100
}

items.soldier_token_smg = {
  type = "item",
  name = "soldier-token-smg",
  icon = "__base__/graphics/icons/heavy-armor.png",
  icon_size = 64,
  subgroup = "military-equipment",
  order = "a[military]-b[token-smg]",
  stack_size = 100
}

items.soldier_token_hmg = {
  type = "item",
  name = "soldier-token-hmg",
  icon = "__base__/graphics/icons/power-armor.png",
  icon_size = 64,
  subgroup = "military-equipment",
  order = "a[military]-c[token-hmg]",
  stack_size = 100
}

items.tank = {
  type = "item",
  name = "tank-unit",
  icon = "__base__/graphics/icons/tank.png",
  icon_size = 64,
  subgroup = "military-equipment",
  order = "b[military]-a[tank]",
  place_result = "tank-unit",
  stack_size = 5
}

-- Brigade HQ building item (top-level)
items.brigade_hq = {
  type = "item",
  name = "brigade-hq",
  icon = "__base__/graphics/icons/radar.png",
  icon_size = 64,
  subgroup = "military-equipment",
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
  subgroup = "military-equipment",
  order = "b[battalion-hq]",
  place_result = "battalion-hq",
  stack_size = 10
}

items.company_hq = {
  type = "item",
  name = "company-hq",
  icon = "__base__/graphics/icons/radar.png",
  icon_size = 64,
  subgroup = "military-equipment",
  order = "c[company-hq]",
  place_result = "company-hq",
  stack_size = 20
}

items.platoon_hq = {
  type = "item",
  name = "platoon-hq",
  icon = "__base__/graphics/icons/radar.png",
  icon_size = 64,
  subgroup = "military-equipment",
  order = "c[platoon-hq]",
  place_result = "platoon-hq",
  stack_size = 20
}

return items
