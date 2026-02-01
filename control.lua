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

  for _, player in pairs(game.players) do
    if not player.get_main_inventory().find_item_stack("command-order-tool") then
      player.insert{name = "command-order-tool", count = 1}
    end
  end
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

squad.register_events()

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

  gui.update_tags()
  for index, player in ipairs(game.connected_players) do
    gui.update_commander_panel(player)
  end
end)

-- GUI events
script.on_event(defines.events.on_gui_click, gui.on_click)
script.on_event(defines.events.on_unit_group_created, gui.on_unit_group_created)
script.on_event(defines.events.on_player_joined_game, function(event)
  gui.init_player(game.get_player(event.player_index))
end)
script.on_event(defines.events.on_player_selected_area, function(event)
  if event.item == "command-order-tool" then
    local player = game.get_player(event.player_index)
    if not player then return end
   
    local platoon_id = gui.get_selected_platoon(player.index)
    if platoon_id then
       local pos = {
        x = (event.area.left_top.x + event.area.right_bottom.x) / 2,
        y = (event.area.left_top.y + event.area.right_bottom.y) / 2
      }
      platoon.issue_platoon_command(platoon_id, pos)
    end
  end
  local player = game.get_player(event.player_index)
  if not player then return end
  local cursor_stack = player.cursor_stack
  if cursor_stack and cursor_stack.valid and cursor_stack.valid_for_read and cursor_stack.name == "command-order-tool" then
    cursor_stack.clear()
  end
end)
