
local gui = {}
local state = {
  collapsed = {}, selected_platoon = {}, highlight_renders = {}, map_markers = {}, marker_to_platoon = {}
}

-- Utility
local function get_toggle_icon(c) return c and "▶" or "▼" end
local function get_health_bar(cur, max)
  local bar = ""; for i = 1, max do bar = bar .. (i <= cur and "[color=green]█[/color]" or "[color=gray]░[/color]") end; return bar
end

-- ============================================
-- SELECTION HIGHLIGHTING
-- ============================================


local function clear_highlights(pi)
  for _, r in pairs(state.highlight_renders[pi] or {}) do if r and r.valid then r.destroy() end end
  state.highlight_renders[pi] = {}
end
local function highlight_platoon(pi, platoon_id)
  clear_highlights(pi); if not platoon_id then return end
  local pd = storage.platoons and storage.platoons[platoon_id]; if not pd or not pd.squad_ids then return end
  local player = game.get_player(pi); if not player then return end
  local renders = {}
  for _, sid in pairs(pd.squad_ids) do
    local sd = storage.squads and storage.squads[sid]
    if sd and sd.unit_group and sd.unit_group.valid then
      local members = sd.unit_group.members
      for _, soldier in pairs(members) do
        if soldier.valid then
          table.insert(renders, rendering.draw_circle{color = {r = 1, g = 0.6, b = 0, a = 0.8}, radius = 0.6, width = 3, target = soldier, surface = soldier.surface, players = {player}, draw_on_ground = true})
        end
      end
    end
  end
  state.highlight_renders[pi] = renders
end


local function select_platoon(player, platoon_id, notify)
  local pi = player.index
  if state.selected_platoon[pi] == platoon_id then
    state.selected_platoon[pi] = nil; highlight_platoon(pi, nil)
    if notify then player.print("Deselected platoon") end
  else
    state.selected_platoon[pi] = platoon_id; highlight_platoon(pi, platoon_id)
    if notify then
      local pd = storage.platoons and storage.platoons[platoon_id]
      player.print("Selected: " .. (pd and pd.name or ("Platoon " .. platoon_id)))
    end
  end
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
  state.collapsed[player.index] = state.collapsed[player.index] or {}
  local frame = player.gui.left.add{type = "frame", name = "commander_frame", caption = "⚔ Military Command", direction = "vertical"}
  frame.style.minimal_width = 350

  local platoon_limit_label = frame.add{type = "label", name = "platoon_limit_label", caption = string.format("Platoon Limit: %d platoon(s)", storage.platoon_limit or 0)}
  platoon_limit_label.style.font = "default-bold"

  local force_limit_label = frame.add{type = "label", name = "force_limit_label", caption = string.format("Force Limit: %d soldiers", storage.force_limit or 0)}
  force_limit_label.style.font = "default-bold"

  local header = frame.add{type = "flow", name = "header_flow", direction = "horizontal"}
  header.add{type = "button", name = "refresh_commander_button", caption = "↻ Refresh", style = "mini_button"}
  header.add{type = "button", name = "expand_all_button", caption = "Expand All", style = "mini_button"}
  header.add{type = "button", name = "collapse_all_button", caption = "Collapse All", style = "mini_button"}
  header.add{type = "empty-widget"}.style.horizontally_stretchable = true
  header.add{type = "sprite-button", name = "close_commander_button", caption = "✕", style = "mini_button"}
  local summary = frame.add{type = "label", name = "summary_label"}; summary.style.font = "default-bold"
  local scroll = frame.add{type = "scroll-pane", name = "content_scroll", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto-and-reserve-space"}
  scroll.style.maximal_height = 500; scroll.style.minimal_width = 330
  scroll.add{type = "flow", name = "content_flow", direction = "vertical"}
  gui.update_commander_panel(player)
end

-- ============================================
-- GUI UPDATE
-- ============================================


function gui.update_commander_panel(player, platoon_limit, force_limit)
  local frame = player.gui.left.commander_frame; if not frame then return end
  local content = frame.content_scroll and frame.content_scroll.content_flow; if not content then return end
  content.clear()
  -- Update force and platoon limit labels
  if frame.force_limit_label then
    frame.force_limit_label.caption = string.format("Force Limit: %d soldiers", force_limit or 0)
  end
  if frame.platoon_limit_label then
    frame.platoon_limit_label.caption = string.format("Platoon Limit: %d platoon(s)", platoon_limit or 0)
  end
  local pc = state.collapsed[player.index] or {}
  local total_platoons, total_squads, total_soldiers = 0, 0, 0
  local has = {
    brigades = storage.brigades and next(storage.brigades),
    battalions = storage.battalions and next(storage.battalions),
    companies = storage.companies and next(storage.companies),
    platoons = storage.platoons and next(storage.platoons),
    squads = storage.squads and next(storage.squads),
  }
  if has.brigades then for id, d in pairs(storage.brigades) do gui.add_brigade_row(content, id, d, pc, player.index) end
  elseif has.battalions then for id, d in pairs(storage.battalions) do gui.add_battalion_row(content, id, d, pc, 0, player.index) end
  elseif has.companies then for id, d in pairs(storage.companies) do gui.add_company_row(content, id, d, pc, 0, player.index) end
  elseif has.platoons then for id, d in pairs(storage.platoons) do total_platoons = total_platoons + 1; local sq, so = gui.add_platoon_row(content, id, d, pc, 0, player.index); total_squads, total_soldiers = total_squads + (sq or 0), total_soldiers + (so or 0) end
  elseif has.squads then for id, d in pairs(storage.squads) do total_squads = total_squads + 1; total_soldiers = total_soldiers + (gui.add_squad_row(content, id, d, 0) or 0) end
  else content.add{type = "label", caption = "[color=gray]No military units deployed[/color]"} end
  if (has.brigades or has.battalions or has.companies) and has.platoons then
    for _, pd in pairs(storage.platoons) do
      total_platoons = total_platoons + 1
      for _, sid in pairs(pd.squad_ids or {}) do
        local sd = storage.squads and storage.squads[sid]
        if sd then total_squads = total_squads + 1; if sd.unit_group and sd.unit_group.valid then total_soldiers = total_soldiers + #sd.unit_group.members end end
      end
    end
  end
  local summary = frame.summary_label
  if summary then summary.caption = string.format("[color=white]Platoons:[/color] %d  [color=white]Squads:[/color] %d  [color=white]Soldiers:[/color] %d", total_platoons, total_squads, total_soldiers) end
end

function gui.update_tags()
  local platoons = storage.platoons
  if not platoons then return end
  for platoon_id, platoon in pairs(platoons) do
    if not platoon_id or not platoon then return end 
    local marker_name = "P" .. platoon_id
    local platoon_tag = {
      text = marker_name,
      icon = {type = "item", name = "radar"},
      position = platoon.entity.position,
      last_user = nil,
    }
    local tag = storage.tags[platoon_id]
    if tag then tag.destroy() end
    storage.tags[platoon_id] = nil
    storage.tags[platoon_id] = platoon.entity.force.add_chart_tag(platoon.entity.surface, platoon_tag)
    for i, squad_id in pairs(platoon.squad_ids or {}) do
      local squad_data = storage.squads and storage.squads[squad_id]
      if squad_data and squad_data.unit_group and squad_data.unit_group.valid then
        local squad_marker_name = marker_name .. "S" .. platoon.squad_ids[i]
        local tag = {
          text = squad_marker_name,
          icon = {type = "item", name = "soldier-token"},
          position = squad_data.unit_group.position,
          last_user = nil,
        }
        local existing_tag = storage.tags[squad_id]
        if existing_tag then existing_tag.destroy() end
        storage.tags[squad_id] = squad_data.unit_group.force.add_chart_tag(squad_data.unit_group.surface, tag)
      end 
    end
  end
end

-- ============================================
-- HIERARCHY ROW BUILDERS
-- ============================================


local function add_row(parent, key, label, pc, indent)
  local row = parent.add{type = "flow", direction = "horizontal"}
  if indent and indent > 0 then row.add{type = "label", caption = string.rep("    ", indent)} end
  row.add{type = "button", name = "toggle_" .. key, caption = get_toggle_icon(pc[key]), style = "mini_button"}
  row.add{type = "label", caption = label}
  return row
end
function gui.add_brigade_row(parent, id, data, pc, pi)
  local key = "brigade_" .. id
  add_row(parent, key, string.format("[color=purple]★ Brigade %s[/color] [%d battalions]", data.name or id, data.battalion_ids and #data.battalion_ids or 0), pc)
  if not pc[key] and data.battalion_ids then for _, bid in pairs(data.battalion_ids) do local bd = storage.battalions and storage.battalions[bid]; if bd then gui.add_battalion_row(parent, bid, bd, pc, 1, pi) end end end
end
function gui.add_battalion_row(parent, id, data, pc, indent, pi)
  local key = "battalion_" .. id
  add_row(parent, key, string.format("[color=blue]◆ Battalion %s[/color] [%d companies]", data.name or id, data.company_ids and #data.company_ids or 0), pc, indent)
  if not pc[key] and data.company_ids then for _, cid in pairs(data.company_ids) do local cd = storage.companies and storage.companies[cid]; if cd then gui.add_company_row(parent, cid, cd, pc, indent + 1, pi) end end end
end
function gui.add_company_row(parent, id, data, pc, indent, pi)
  local key = "company_" .. id
  add_row(parent, key, string.format("[color=cyan]▣ Company %s[/color] [%d platoons]", data.name or id, data.platoon_ids and #data.platoon_ids or 0), pc, indent)
  if not pc[key] and data.platoon_ids then for _, pid in pairs(data.platoon_ids) do local pd = storage.platoons and storage.platoons[pid]; if pd then gui.add_platoon_row(parent, pid, pd, pc, indent + 1, pi) end end end
end


function gui.add_platoon_row(parent, id, data, pc, indent, pi)
  local key = "platoon_" .. id
  local is_selected = state.selected_platoon[pi] == id
  local squad_ids = data.squad_ids or {}
  local squad_healths, total_soldiers = {}, 0
  for _, sid in pairs(squad_ids) do
    local sd = storage.squads and storage.squads[sid]
    local count = (sd and sd.unit_group and sd.unit_group.valid) and #sd.unit_group.members or 0
    table.insert(squad_healths, count); total_soldiers = total_soldiers + count
  end
  local max_per_squad, bar = 8, ""
  for i, health in ipairs(squad_healths) do bar = bar .. get_health_bar(health, max_per_squad); if i < #squad_healths then bar = bar .. " " end end
  local row = parent.add{type = "flow", direction = "horizontal", name = "platoon_row_" .. id}
  if indent > 0 then row.add{type = "label", caption = string.rep("  ", indent)} end
  row.add{type = "button", name = "toggle_" .. key, caption = get_toggle_icon(pc[key]), style = "mini_button"}
  row.add{type = "button", name = "select_platoon_" .. id, caption = is_selected and "►" or "○", style = "mini_button", tooltip = is_selected and "Selected" or "Click to select"}
  row.add{type = "label", caption = string.format("[color=%s]◎ Platoon %s[/color] [%d squads, %d soldiers] ", is_selected and "orange" or "yellow", data.name or id, #squad_ids, total_soldiers)}
  row.add{type = "label", caption = bar}
  return #squad_ids, total_soldiers
end

function gui.add_squad_row(parent, id, data, indent)
  local count = (data.unit_group and data.unit_group.valid) and #data.unit_group.members or 0
  return count
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
  if name == "toggle_commander_panel" then gui.create_commander_panel(player); return end
  if name == "refresh_commander_button" then gui.update_commander_panel(player); return end
  if name == "close_commander_button" then if player.gui.left.commander_frame then player.gui.left.commander_frame.destroy() end; state.selected_platoon[pi] = nil; clear_highlights(pi); return end
  if name == "expand_all_button" then state.collapsed[pi] = {}; gui.update_commander_panel(player); return end
  if name == "collapse_all_button" then local pc = state.collapsed[pi] or {}; for tbl_name, tbl in pairs({brigades = storage.brigades, battalions = storage.battalions, companies = storage.companies, platoons = storage.platoons}) do if tbl then for id in pairs(tbl) do pc[tbl_name:sub(1, -2) .. "_" .. id] = true end end end; state.collapsed[pi] = pc; gui.update_commander_panel(player); return end
  if name:sub(1, 15) == "select_platoon_" then select_platoon(player, tonumber(name:sub(16)), false); gui.update_commander_panel(player); return end
  if name:sub(1, 7) == "toggle_" then local key = name:sub(8); state.collapsed[pi] = state.collapsed[pi] or {}; state.collapsed[pi][key] = not state.collapsed[pi][key]; gui.update_commander_panel(player); return end
end

-- ============================================
-- INITIALIZATION
-- ============================================


function gui.init_player(player)
  storage.tags = storage.tags or {}
  state.collapsed[player.index], state.selected_platoon[player.index], state.highlight_renders[player.index] = {}, nil, {}
  gui.create_buttons(player)
end
function gui.get_selected_platoon(player_index) return state.selected_platoon[player_index] end
function gui.set_selected_platoon(player_index, platoon_id) state.selected_platoon[player_index] = platoon_id; highlight_platoon(player_index, platoon_id) end
return gui
