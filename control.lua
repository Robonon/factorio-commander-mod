-- control.lua

local battalion = require("scripts.battalion")
local company = require("scripts.company")
local platoon = require("scripts.platoon")
local squad = require("scripts.squad")
local gui = require("scripts.gui")

-- ============================================
-- INITIALIZATION
-- ============================================

script.on_init(function()
  battalion.init_storage()
  company.init_storage()
  platoon.init_storage()
  squad.init_storage()
end)

script.on_configuration_changed(function()
  battalion.init_storage()
  company.init_storage()
  platoon.init_storage()
  squad.init_storage()
end)

-- ============================================
-- EVENT REGISTRATION
-- ============================================

local UPDATE_INTERVAL = 60

-- Building events
local build_filter = {
  { filter = "name", name = "brigade-hq" },
  { filter = "name", name = "battalion-hq" },
  { filter = "name", name = "company-hq" },
  { filter = "name", name = "platoon-hq" },
}

local function on_built(event)
  battalion.on_built(event)
  company.on_built(event)
  platoon.on_built(event)
end

local function on_destroyed(event)
  battalion.on_destroyed(event)
  company.on_destroyed(event)
  platoon.on_destroyed(event)
end

script.on_event(defines.events.on_built_entity, on_built, build_filter)
script.on_event(defines.events.on_robot_built_entity, on_built, build_filter)
script.on_event(defines.events.script_raised_built, on_built, build_filter)
script.on_event(defines.events.script_raised_revive, on_built, build_filter)

script.on_event(defines.events.on_entity_died, on_destroyed, build_filter)
script.on_event(defines.events.on_player_mined_entity, on_destroyed, build_filter)
script.on_event(defines.events.on_robot_mined_entity, on_destroyed, build_filter)
script.on_event(defines.events.script_raised_destroy, on_destroyed, build_filter)

-- Periodic updates
script.on_nth_tick(UPDATE_INTERVAL, function()
  squad.update_all()
  squad.cleanup()
  gui.update_all()
end)

-- GUI events
script.on_event(defines.events.on_gui_click, gui.on_click)
script.on_event(defines.events.on_unit_group_created, gui.on_unit_group_created)
script.on_event(defines.events.on_player_joined_game, function(event)
  gui.init_player(game.get_player(event.player_index))
end)