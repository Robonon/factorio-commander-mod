-- prototypes/entities.lua
-- Military buildings and units

local entities = {}

local character = data.raw["character"]["character"]

-- ============================================
-- UNITS
-- ============================================

entities.soldier = {
  type = "unit",
  name = "soldier-unit",
  icon = "__base__/graphics/icons/pistol.png",
  flags = {"placeable-player", "placeable-off-grid", "breaths-air", "get-by-unit-number"},
  max_health = 150,
  healing_per_tick = 0.01,
  collision_box = {{-0.1, -0.1}, {0.1, 0.1}},
  selection_box = {{-0.4, -0.7}, {0.4, 0.4}},
  movement_speed = 0.15,
  distance_per_frame = 0.13,
  run_animation = character.animations[1].running,
  idle_animation = character.animations[1].idle_with_gun_in_air,
  vision_distance = 30,
  has_belt_immunity = true,
  can_open_gates = true,  -- Allows soldiers to trigger gates
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
      { filename = "__base__/sound/fight/light-gunshot-3.ogg", volume = 0.4 },
      { filename = "__base__/sound/fight/light-gunshot-4.ogg", volume = 0.4 },
      { filename = "__base__/sound/fight/light-gunshot-5.ogg", volume = 0.4 },
      { filename = "__base__/sound/fight/light-gunshot-6.ogg", volume = 0.4 },
      { filename = "__base__/sound/fight/light-gunshot-7.ogg", volume = 0.4 },
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
    animation = character.animations[1].idle_with_gun,
  },
  distraction_cooldown = 0,
  dying_explosion = "blood-explosion-small",
  corpse = "character-corpse"
}

entities.soldier_smg = table.deepcopy(entities.soldier)
entities.soldier_smg.name = "soldier-smg-unit"
entities.soldier_smg.icon = "__base__/graphics/icons/submachine-gun.png"
entities.soldier_smg.attack_parameters = {
    type = "projectile",
    ammo_category = "bullet",
    range = 20,
    cooldown = 10,
    sound = {
      { filename = "__base__/sound/fight/submachine-gunshot-1.ogg", volume = 0.4 },
      { filename = "__base__/sound/fight/submachine-gunshot-2.ogg", volume = 0.4 },
      { filename = "__base__/sound/fight/submachine-gunshot-3.ogg", volume = 0.4 },
    },
    ammo_type = {
      category = "bullet",
      action = {
        type = "direct",
        action_delivery = {
          type = "instant",
          target_effects = {{type = "damage", entity_name = "explosion-hit", damage = {amount = 3, type = "physical"}}},
          source_effects = {{ type = "create-explosion", entity_name = "explosion-gunshot", offset_deviation = {{0.5, 0.5}, {0.5, 0.5}} },
          }
        }
      }
    },
    run_animation = character.animations[2].running,
    idle_animation = character.animations[2].idle_with_gun_in_air,
    animation = character.animations[2].idle_with_gun,
}

entities.soldier_hmg = table.deepcopy(entities.soldier)
entities.soldier_hmg.name = "soldier-hmg-unit"
entities.soldier_hmg.icon = "__base__/graphics/icons/submachine-gun.png"
entities.soldier_hmg.max_health = 300
entities.soldier_hmg.run_animation = character.animations[3].running
entities.soldier_hmg.idle_animation = character.animations[3].idle_with_gun_in_air
entities.soldier_hmg.attack_parameters = {
    type = "projectile",
    ammo_category = "bullet",
    range = 25,
    cooldown = 10,
    sound = {
      { filename = "__commander__/assets/machine-gun-50-cal.ogg", volume = 0.4 },
    },
    ammo_type = {
      range_modifier = 1.2,
      category = "bullet",
      action = {
        type = "direct",
        action_delivery = {
          type = "instant",
          target_effects = {{type = "damage", entity_name = "explosion-hit", damage = {amount = 50, type = "physical"}}},
        }
      }
    },
    animation = character.animations[3].idle_with_gun,
}

-- local tank = data.raw["entity"]["car"]
entities.tank = {
  type = "unit",
  name = "tank-unit",
  icon = "__base__/graphics/icons/tank.png",
  flags = {"placeable-player", "placeable-off-grid", "breaths-air", "get-by-unit-number"},
  max_health = 150,
  healing_per_tick = 0.01,
  collision_box = {{-0.1, -0.1}, {0.1, 0.1}},
  selection_box = {{-0.4, -0.7}, {0.4, 0.4}},
  movement_speed = 0.15,
  distance_per_frame = 0.13,
  run_animation = character.animations[1].running,
  idle_animation = character.animations[1].idle_with_gun_in_air,
  vision_distance = 30,
  has_belt_immunity = true,
  can_open_gates = true,  -- Allows soldiers to trigger gates
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
      { filename = "__base__/sound/fight/tank-cannon.ogg", volume = 0.4 },
      { filename = "__base__/sound/fight/tank-cannon-1.ogg", volume = 0.4 },
      { filename = "__base__/sound/fight/tank-cannon-2.ogg", volume = 0.4 },
      { filename = "__base__/sound/fight/tank-cannon-3.ogg", volume = 0.4 },
      { filename = "__base__/sound/fight/tank-cannon-4.ogg", volume = 0.4 },
      { filename = "__base__/sound/fight/tank-cannon-5.ogg", volume = 0.4 },
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
    animation = character.animations[1].idle_with_gun,
  },
  distraction_cooldown = 0,
  dying_explosion = "blood-explosion-small",
  corpse = "tank-remnants"
}

-- ============================================
-- BUILDINGS
-- ============================================

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

entities.company_hq = {
  type = "container",
  name = "company-hq",
  icon = "__base__/graphics/icons/radar.png",
  icon_size = 64,
  flags = {"placeable-neutral", "player-creation"},
  minable = {mining_time = 0.5, result = "company-hq"},
  max_health = 400,
  corpse = "big-remnants",
  collision_box = {{-1.6, -1.6}, {1.6, 1.6}},
  selection_box = {{-1.7, -1.7}, {1.7, 1.7}},
  inventory_size = 20,
  picture = {
    layers = {{
      filename = "__base__/graphics/entity/radar/radar.png",
      width = 196,
      height = 254,
      shift = {0.7, -0.75},
      scale = 0.6
    }}
  },
}

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

return entities
