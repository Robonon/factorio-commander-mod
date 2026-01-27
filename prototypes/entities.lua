-- prototypes/entities.lua
-- Military buildings and units

local entities = {}

local character = data.raw["character"]["character"]

-- ============================================
-- UNITS
-- ============================================

-- Regular soldier unit
entities.soldier = {
  type = "unit",
  name = "soldier-unit",
  icon = "__base__/graphics/icons/submachine-gun.png",
  icon_size = 64,
  flags = {"placeable-player", "placeable-enemy", "placeable-off-grid", "breaths-air"},
  max_health = 150,
  healing_per_tick = 0.01,
  collision_box = {{-0.1, -0.1}, {0.1, 0.1}},
  selection_box = {{-0.4, -0.7}, {0.4, 0.4}},
  movement_speed = 0.15,
  distance_per_frame = 0.13,
  run_animation = character.animations[1].running_with_gun,
  idle_animation = character.animations[1].idle_with_gun,
  vision_distance = 30,
  has_belt_immunity = true,
  ai_settings = {
    destroy_when_commands_fail = false,
    allow_try_return_to_spawner = false,
    do_separation = true,
  },
  attack_parameters = {
    type = "projectile",
    ammo_category = "bullet",
    range = 15,
    cooldown = 20,
    sound = {
      { filename = "__base__/sound/fight/light-gunshot-1.ogg", volume = 0.4 },
      { filename = "__base__/sound/fight/light-gunshot-2.ogg", volume = 0.4 },
      { filename = "__base__/sound/fight/light-gunshot-3.ogg", volume = 0.4 }
    },
    ammo_type = {
      category = "bullet",
      action = {
        type = "direct",
        action_delivery = {
          type = "instant",
          target_effects = {{type = "damage", damage = {amount = 5, type = "physical"}}}
        }
      }
    },
    animation = character.animations[1].idle_with_gun
  },
  distraction_cooldown = 0,
  dying_explosion = "blood-explosion-small",
  corpse = "character-corpse"
}

-- HQ Squad unit (used for deploying new HQs)
entities.hq_squad = {
  type = "unit",
  name = "hq-squad-unit",
  icon = "__base__/graphics/icons/repair-pack.png",
  icon_size = 64,
  flags = {"placeable-player", "placeable-enemy", "placeable-off-grid", "breaths-air"},
  max_health = 300,
  healing_per_tick = 0.01,
  collision_box = {{-0.2, -0.2}, {0.2, 0.2}},
  selection_box = {{-0.5, -0.8}, {0.5, 0.5}},
  movement_speed = 0.12,  -- Slightly slower (carrying equipment)
  distance_per_frame = 0.10,
  run_animation = character.animations[1].running_with_gun,
  idle_animation = character.animations[1].idle_with_gun,
  vision_distance = 30,
  has_belt_immunity = true,
  ai_settings = {
    destroy_when_commands_fail = false,
    allow_try_return_to_spawner = false,
    do_separation = true,
  },
  attack_parameters = {
    type = "projectile",
    ammo_category = "bullet",
    range = 12,
    cooldown = 30,
    ammo_type = {
      category = "bullet",
      action = {
        type = "direct",
        action_delivery = {
          type = "instant",
          target_effects = {{type = "damage", damage = {amount = 3, type = "physical"}}}
        }
      }
    },
    animation = character.animations[1].idle_with_gun
  },
  distraction_cooldown = 0,
  dying_explosion = "blood-explosion-small",
  corpse = "character-corpse"
}

-- ============================================
-- BUILDINGS
-- ============================================

entities.platoon_hq = {
  type = "container",
  name = "platoon-hq",
  icon = "__base__/graphics/icons/radar.png",
  icon_size = 64,
  flags = {"placeable-neutral", "player-creation"},
  minable = {mining_time = 0.5, result = "platoon-hq"},
  max_health = 300,
  corpse = "medium-remnants",
  collision_box = {{-1.2, -1.2}, {1.2, 1.2}},
  selection_box = {{-1.3, -1.3}, {1.3, 1.3}},
  inventory_size = 10,
  idle_animation = {
    filename = "__base__/graphics/entity/radar/radar.png",
    width = 196,
    height = 254,
    shift = {0.7, -0.75},
    scale = 0.3
  },
  picture = {
    layers = {{
      filename = "__base__/graphics/entity/radar/radar.png",
      width = 196,
      height = 254,
      shift = {0.7, -0.75},
      scale = 0.4
    }}
  },
}

-- Brigade HQ (top-level, spawns HQ squads to deploy Battalion HQs)
entities.brigade_hq = {
  type = "container",
  name = "brigade-hq",
  icon = "__base__/graphics/icons/radar.png",
  icon_size = 64,
  flags = {"player-creation"},
  minable = {mining_time = 1.0, result = "brigade-hq"},
  max_health = 1000,
  corpse = "big-remnants",
  collision_box = {{-1.9, -1.9}, {1.9, 1.9}},
  selection_box = {{-2.0, -2.0}, {2.0, 2.0}},
  inventory_size = 40,
  picture = {
    layers = {{
      filename = "__base__/graphics/entity/radar/radar.png",
      width = 196,
      height = 254,
      shift = {0.7, -0.75},
      scale = 0.8
    }}
  },
}

-- Battalion HQ (mid-level, spawns squads)
entities.battalion_hq = {
  type = "container",
  name = "battalion-hq",
  icon = "__base__/graphics/icons/radar.png",
  icon_size = 64,
  flags = {"player-creation"},
  minable = {mining_time = 0.5, result = "battalion-hq"},
  max_health = 500,
  corpse = "medium-remnants",
  collision_box = {{-1.4, -1.4}, {1.4, 1.4}},
  selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
  inventory_size = 20,
  picture = {
    layers = {{
      filename = "__base__/graphics/entity/radar/radar.png",
      width = 196,
      height = 254,
      shift = {0.7, -0.75},
      scale = 0.5
    }}
  },
}

return entities
