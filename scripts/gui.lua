command_structure_module = require("scripts.command_structure")
squad_module = require("scripts.squad")

local gui = {}
local state = {
  collapsed = {}, selected_platoon = {}, highlight_renders = {}, map_markers = {}, marker_to_platoon = {}
}

-- Utility
local function get_health_bar(cur, max)
  local bar = ""; for i = 1, max do bar = bar .. (i <= cur and "[color=green]█[/color]" or "[color=gray]░[/color]") end; return bar
end

local function draw_hierarchy_lines(player, parent_entity, child_entity)
    local color = {r=0, g=0, b=1, a=0.2}
    local width = 2
  local line = rendering.draw_line{
    color = color,
    width = width,
    from = parent_entity,
    to = child_entity,
    surface = parent_entity.surface,
    players = {player.index},
    render_mode = "game",
    only_in_alt_mode = true,
    draw_on_ground = true
  }
  local chart_line = rendering.draw_line{
    color = color,
    width = width,
    from = parent_entity,
    to = child_entity,
    surface = parent_entity.surface,
    players = {player.index},
    render_mode = "chart",
    only_in_alt_mode = true,
  }

end

-- ============================================
-- GUI CREATION
-- ============================================

function gui.create_buttons(player)
  if player.gui.top.commander_flow then return end
  local flow = player.gui.top.add{type = "flow", name = "commander_flow", direction = "horizontal"}
  flow.add{type = "sprite-button", name = "toggle_commander_panel", caption = "⚔", tooltip = "Commander Panel", style = "slot_button"}
end

function gui.create_commander_panel(player)
  if player.gui.left.commander_frame then player.gui.left.commander_frame.destroy(); return end

  rendering.clear("commander")

  state.collapsed[player.index] = state.collapsed[player.index] or {}
  local frame = player.gui.left.add{type = "frame", name = "commander_frame", caption = "⚔ Military Command", direction = "vertical"}
  frame.style.minimal_width = 350

  local limits = command_structure_module.hq_limit()
  local brigade_limit_label = frame.add{type = "label", name = "brigade_limit_label", caption = string.format("X: Brigades: %d/%d", storage.HQ_counts[HQ_TYPES.BRIGADE] or 0, limits[HQ_TYPES.BRIGADE] or 0)}
  brigade_limit_label.style.font = "default-bold"

  local battalion_limit_label = frame.add{type = "label", name = "battalion_limit_label", caption = string.format("II: Battalions: %d/%d", storage.HQ_counts[HQ_TYPES.BATTALION] or 0, limits[HQ_TYPES.BATTALION] or 0)}
  battalion_limit_label.style.font = "default-bold"

  local company_limit_label = frame.add{type = "label", name = "company_limit_label", caption = string.format("I: Companies: %d/%d", storage.HQ_counts[HQ_TYPES.COMPANY] or 0, limits[HQ_TYPES.COMPANY] or 0)}
  company_limit_label.style.font = "default-bold"

  local platoon_limit_label = frame.add{type = "label", name = "platoon_limit_label", caption = string.format("•••: Platoons: %d/%d", storage.HQ_counts[HQ_TYPES.PLATOON] or 0, limits[HQ_TYPES.PLATOON] or 0)}
  platoon_limit_label.style.font = "default-bold"

  local header = frame.add{type = "flow", name = "header_flow", direction = "horizontal"}
  header.add{type = "empty-widget"}.style.horizontally_stretchable = true
  
  local summary = frame.add{type = "label", name = "summary_label"}; summary.style.font = "default-bold"
  
  local scroll = frame.add{type = "scroll-pane", name = "content_scroll", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto-and-reserve-space"}
  scroll.style.maximal_height = 500; scroll.style.minimal_width = 330
  scroll.add{type = "flow", name = "content_flow", direction = "vertical"}
  
  gui.update_commander_panel(player)
end

-- ============================================
-- GUI UPDATE
-- ============================================

function gui.update_commander_panel(player)
  local frame = player.gui.left.commander_frame; if not frame then return end
  local content = frame.content_scroll and frame.content_scroll.content_flow; if not content then return end
  content.clear()

  local limits = command_structure_module.hq_limit()
  if frame.platoon_limit_label then
    frame.platoon_limit_label.caption = string.format("•••: Platoons: %d/%d", storage.HQ_counts[HQ_TYPES.PLATOON] or 0, limits[HQ_TYPES.PLATOON] or 0)
  end

  if frame.company_limit_label then
    frame.company_limit_label.caption = string.format("I: Companies: %d/%d", storage.HQ_counts[HQ_TYPES.COMPANY] or 0, limits[HQ_TYPES.COMPANY] or 0)
  end

  if frame.battalion_limit_label then
    frame.battalion_limit_label.caption = string.format("II: Battalions: %d/%d", storage.HQ_counts[HQ_TYPES.BATTALION] or 0, limits[HQ_TYPES.BATTALION] or 0)
  end

  if frame.brigade_limit_label then
    frame.brigade_limit_label.caption = string.format("X: Brigades: %d/%d", storage.HQ_counts[HQ_TYPES.BRIGADE] or 0, limits[HQ_TYPES.BRIGADE] or 0)
  end

  local pc = state.collapsed[player.index] or {}
  local HQs = storage.HQ
  if not HQs then return end

  -- Build a set of all child HQ ids
  local child_hq_ids = {}
  for _, hq in pairs(HQs) do
    if hq.children_hq_ids then
      for _, child_id in pairs(hq.children_hq_ids) do
        child_hq_ids[child_id] = true
      end
    end
  end

  -- Only show HQs as roots if they are not a child of any other HQ
  for id, hq in pairs(HQs) do
    if not child_hq_ids[id] then
      add_hq_row(content, hq, pc, 0, player)
    end
  end

  if not next(storage.HQ) then
    content.add{type = "label", caption = "[color=gray]No military units deployed[/color]"}
  end
end

function gui.update_tags()
  local HQs = storage.HQ
  if not HQs then return end
  -- HQ tags
  for _, hq in pairs(HQs) do
    if not hq or not hq.entity or not hq.entity.valid then return end 

    local tag = storage.tags[hq.entity.unit_number]
    if tag then tag.destroy() end


    local hq_tag_text = ""
      if hq.entity.name == HQ_TYPES.BRIGADE then hq_tag_text = string.format("[color=blue]X %s[/color] [%d Battalions]", hq.tag_id, hq.children_hq_ids and #hq.children_hq_ids or 0)
      elseif hq.entity.name == HQ_TYPES.BATTALION then hq_tag_text = string.format("[color=blue]II %s[/color] [%d Companies]", hq.tag_id, hq.children_hq_ids and #hq.children_hq_ids or 0)
      elseif hq.entity.name == HQ_TYPES.COMPANY then hq_tag_text = string.format("[color=blue]I %s[/color] [%d Platoons]", hq.tag_id, hq.children_hq_ids and #hq.children_hq_ids or 0)
      elseif hq.entity.name == HQ_TYPES.PLATOON then hq_tag_text = string.format("[color=blue]••• %s[/color] [%d Squads]", hq.tag_id, hq.maneuver_squad_ids and #hq.maneuver_squad_ids or 0)
      end

    tag = {
      text = hq_tag_text,
      icon = {type = "virtual", name = "signal-dot"},-- TODO: custom icons for different HQ types
      position = hq.entity.position,
      last_user = nil,
    }
    
    storage.tags[hq.entity.unit_number] = hq.entity.force.add_chart_tag(hq.entity.surface, tag)

    local squad_ids = hq.maneuver_squad_ids
    if not squad_ids then goto continue end
    
    -- squad tags
    for i, squad_id in pairs(squad_ids or {}) do
      local squad_data = storage.squads and storage.squads[squad_id]
      if squad_data and squad_data.unit_group and squad_data.unit_group.valid then
        local squad_tag = {
          text = string.format("[color=yellow]• %d[/color] [%d/%d]", squad_id, squad_data.unit_group.members and #squad_data.unit_group.members or 0, command_structure_module.SOLDIERS_PER_SQUAD),
          position = squad_data.unit_group.position,
          last_user = nil,
        }
        local existing_tag = storage.tags[squad_id]
        if existing_tag then existing_tag.destroy() end
        storage.tags[squad_id] = squad_data.unit_group.force.add_chart_tag(squad_data.unit_group.surface, squad_tag)
      end 
    end
      ::continue::
  end
end

-- ============================================
-- HIERARCHY ROW BUILDERS
-- ============================================

function add_row(parent, label, indent)
  row = parent.add{type = "flow", direction = "vertical"}
  row.add{type = "label", caption = (string.rep("        ", indent) .. label)}
  return row
end

function add_hq_row(parent, hq, pc, indent, player)
  if not hq then return end
  if not hq.entity or not hq.entity.valid then return end
  local key = hq.tag_id

  local label = ""
  if hq.entity.name == HQ_TYPES.BRIGADE then label = string.format("[color=blue]X %s[/color] [%d Battalions]", hq.tag_id, hq.children_hq_ids and #hq.children_hq_ids or 0)
  elseif hq.entity.name == HQ_TYPES.BATTALION then label = string.format("[color=blue]II %s[/color] [%d Companies]", hq.tag_id, hq.children_hq_ids and #hq.children_hq_ids or 0)
  elseif hq.entity.name == HQ_TYPES.COMPANY then label = string.format("[color=blue]I %s[/color] [%d Platoons]", hq.tag_id, hq.children_hq_ids and #hq.children_hq_ids or 0)
  elseif hq.entity.name == HQ_TYPES.PLATOON then label = string.format("[color=white]••• %s[/color] [%d Squads]", hq.tag_id, hq.maneuver_squad_ids and #hq.maneuver_squad_ids or 0)
  end
  
  local hq_row = add_row(parent, label, indent + 1)
  if hq.children_hq_ids and #hq.children_hq_ids > 0 then
    for _, child_id in pairs(hq.children_hq_ids) do
      draw_hierarchy_lines(player, hq.entity, storage.HQ[child_id] and storage.HQ[child_id].entity)
      add_hq_row(hq_row, storage.HQ[child_id], pc, indent + 1, player)
    end
  end
  if hq.maneuver_squad_ids and #hq.maneuver_squad_ids > 0 then
    for _, squad_id in pairs(hq.maneuver_squad_ids) do
      add_squad_row(hq_row, squad_id, indent + 2)
    end
  end
end

function add_squad_row(hq_row, squad_id, indent)
  if not squad_id then return end
  local squad_data = squad_module.get_valid_squad(squad_id)
  if squad_data and squad_data.unit_group and squad_data.unit_group.valid then
    local label = string.format("[color=yellow]• Squad %d[/color] [%d soldiers]", squad_id, squad_data.unit_group.members and #squad_data.unit_group.members or 0)
    local row = hq_row.add{type = "label", caption = (string.rep("        ", indent) .. label)}
    return row
  end
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

function gui.on_destroyed(event)
  local tag = storage.tags[event.entity.unit_number]
  if tag then tag.destroy() end
  storage.tags[event.entity.unit_number] = nil
  if event.entity and event.entity.name == "platoon-hq" then
    for squad_id, squad_data in pairs(storage.squads or {}) do
      if squad_data and squad_data.platoon_id == event.entity.unit_number then
        local tag = storage.tags[squad_id]
        if tag then tag.destroy() end
        storage.tags[squad_id] = nil
      end
    end
  end
end

function gui.on_click(event)
  local el = event.element; if not el or not el.valid then return end
  local player = game.get_player(event.player_index); if not player then return end
  local name, pi = el.name, player.index
  if name == "toggle_commander_panel" then 
    gui.create_commander_panel(player); 
    return 
  end
  if name:sub(1, 7) == "toggle_" then 
    local key = name:sub(8); 
    state.collapsed[pi] = state.collapsed[pi] or {}; state.collapsed[pi][key] = not state.collapsed[pi][key]; 
    gui.update_commander_panel(player); 
    return
  end
end

function gui.on_ai_command_completed(event)
  if not event or not event.unit_number then return end
  local tag = storage.tags[event.unit_number]
  if tag then
    tag.destroy()
    storage.tags[event.unit_number] = nil
  end
end

-- ============================================
-- INITIALIZATION
-- ============================================


function gui.init_player(player)
  storage.tags = storage.tags or {}
  state.collapsed[player.index], state.selected_platoon[player.index], state.highlight_renders[player.index] = {}, nil, {}
  gui.create_buttons(player)
end

return gui
