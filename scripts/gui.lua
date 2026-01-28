
local squad = require("scripts.squad")
local gui = {}

-- ============================================
-- CREATE GUI
-- ============================================

function gui.create_buttons(player)
  if player.gui.top.commander_flow then return end
  
  local flow = player.gui.top.add{
    type = "flow",
    name = "commander_flow",
    direction = "horizontal",
  }
  
  flow.add{
    type = "button",
    name = "toggle_squad_table_button",
    caption = "Squads"
  }
end

-- ============================================
-- SQUAD TABLE GUI
-- ============================================

function gui.create_squad_table(player)
  if player.gui.left.squad_frame then
    player.gui.left.squad_frame.destroy()
    return  -- Toggle off
  end
  
  local frame = player.gui.left.add{
    type = "frame",
    name = "squad_frame",
    caption = "Squad Overview",
    direction = "vertical",
  }
  
  -- Add close button flow
  local title_flow = frame.add{
    type = "flow",
    name = "title_flow",
    direction = "horizontal",
  }
  title_flow.add{
    type = "button",
    name = "refresh_squad_table_button",
    caption = "Refresh",
    style = "mini_button",
  }
  title_flow.add{
    type = "button", 
    name = "close_squad_table_button",
    caption = "X",
    style = "mini_button",
  }
  
  -- Scrollable pane for the table
  local scroll = frame.add{
    type = "scroll-pane",
    name = "squad_scroll",
    horizontal_scroll_policy = "never",
    vertical_scroll_policy = "auto-and-reserve-space",
  }
  scroll.style.maximal_height = 400
  
  -- Create table
  local table = scroll.add{
    type = "table",
    name = "squad_table",
    column_count = 8,
  }
  
  -- Header row
  table.add{type = "label", caption = "[color=yellow]ID[/color]"}
  table.add{type = "label", caption = "[color=yellow]Soldiers[/color]"}
  table.add{type = "label", caption = "[color=yellow]Integrity[/color]"}
  table.add{type = "label", caption = "[color=yellow]Status[/color]"}
  table.add{type = "label", caption = "[color=yellow]Position[/color]"}
  table.add{type = "label", caption = "[color=yellow]Valid[/color]"}
  table.add{type = "label", caption = "[color=yellow]Can Reinforce[/color]"}
  table.add{type = "label", caption = "[color=yellow]HQ Reinforcements[/color]"}
  
  gui.update_squad_table(player)
end

function gui.update_squad_table(player)
  local frame = player.gui.left.squad_frame
  if not frame then return end
  
  local scroll = frame.squad_scroll
  if not scroll then return end
  
  local tbl = scroll.squad_table
  if not tbl then return end
  
  -- Clear existing rows (keep header - first 5 elements)
  while #tbl.children > 8 do
    tbl.children[9].destroy()
  end
  
  -- Populate with squad data
  if not storage.squads then 
    player.print("No storage.squads found")
    return 
  end
  
  local count = 0
  for squad_id, squad_data in pairs(storage.squads) do
    count = count + 1
    
    -- Get position from unit_group if valid
    local pos_str = "N/A"
    local valid_str = "[color=red]No[/color]"
    local member_count = 0
    if squad_data.unit_group and squad_data.unit_group.valid then
      local pos = squad_data.unit_group.position
      pos_str = string.format("%.0f, %.0f", pos.x, pos.y)
      valid_str = "[color=green]Yes[/color]"
      member_count = #squad_data.unit_group.members
    end
    
    -- Status color
    local status = squad_data.status or "unknown"
    local status_str = status
    if status == "operational" then
      status_str = "[color=green]operational[/color]"
    elseif status == "retreating" then
      status_str = "[color=red]retreating[/color]"
    end

    -- Integrity color
    local integrity = squad_data.integrity or "unknown"
    local integrity_str = integrity
    if integrity == "full_strength" then
      integrity_str = "[color=green]full_strength[/color]"
    elseif integrity == "needs_reinforcements" then
      integrity_str = "[color=yellow]needs_reinforcements[/color]"
    end
    
    -- Can reinforce
    local can_reinforce = "N/A"
    if squad.can_reinforce(squad_id) then
      can_reinforce = "[color=green](can reinforce)[/color]"
    else
      can_reinforce = "[color=red](cannot reinforce)[/color]"
    end

    -- HQ has reinforcements
    local reinforcements_available = "N/A"
    if squad.reinforcements_available(squad_id) then
      reinforcements_available = "[color=green](HQ has reinforcements)[/color]"
    else
      reinforcements_available = "[color=red](HQ no reinforcements)[/color]"
    end

    -- Add row
    tbl.add{type = "label", caption = tostring(squad_id)}
    tbl.add{type = "label", caption = member_count .. "/8"}
    tbl.add{type = "label", caption = integrity_str}
    tbl.add{type = "label", caption = status_str}
    tbl.add{type = "label", caption = pos_str}
    tbl.add{type = "label", caption = valid_str}
    tbl.add{type = "label", caption = can_reinforce}
    tbl.add{type = "label", caption = reinforcements_available}
  end  
end

-- ============================================
-- HANDLE BUTTON CLICK
-- ============================================

function gui.on_click(event)
  local element = event.element
  if not element or not element.valid then return end
  
  local player = game.get_player(event.player_index)
  
  if element.name == "toggle_squad_table_button" then
    gui.create_squad_table(player)
  elseif element.name == "refresh_squad_table_button" then
    gui.update_squad_table(player)
  elseif element.name == "close_squad_table_button" then
    if player.gui.left.squad_frame then
      player.gui.left.squad_frame.destroy()
    end
elseif element.name == "platoon_command_button" then
  end
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

function gui.update_all()
  for _, player in pairs(game.connected_players) do
    gui.update_squad_table(player)
  end
end

-- ============================================
-- INIT
-- ============================================

function gui.init_player(player)
  gui.create_buttons(player)
  gui.create_squad_table(player)
end

return gui
