local M = {}

local SOLDIERS_PER_SQUAD = 8
local OPERATIONAL_THRESHOLD = 3  -- Minimum soldiers to remain operational
local RETREAT_THRESHOLD = 2      -- Retreat when at or below this
local SQUAD_OPERATIONAL_RADIUS = 500
local COMMAND_TIMEOUT_TICKS = 60 * 30  -- 30 seconds before considering command stuck
local STATUS = {
  IDLE = "idle",
  MOVING = "moving",
  RETREATING = "retreating",
}

local ORDERS = {
  NONE = "none",
  MOVE_TO_POSITION = "move_to_position",
  RETURN_TO_BASE = "return_to_base",
  RETREAT_TO_BASE = "retreat_to_base",
  SQUAD_EXPLORE = "squad_explore",
  SQUAD_PATROL = "squad_patrol",
}

-- ============================================
-- STORAGE INITIALIZATION
-- ============================================

function M.init_storage()
  storage.squads = storage.squads or {}
  storage.chunks = storage.chunks or game.surfaces[1].get_chunks()
end

-- ============================================
-- SQUAD MANAGEMENT
-- ============================================

function M.create_squads_for_platoon(surface, position, force, num_squads)
  local squad_ids = {}
  for i = 1, num_squads do
    table.insert(squad_ids, M.create_squad(surface, position, force))
  end
  return squad_ids
end

function M.create_squad(surface, position, force)
  -- Find spawn position
  local spawn_pos = surface.find_non_colliding_position("soldier-unit", position, 10, 0.5)
  if not spawn_pos then
    game.print("Could not find spawn position for squad!")
    spawn_pos = position  -- fallback to exact position
  end
  
  -- Create unit group first
  local unit_group = surface.create_unit_group({
    position = spawn_pos,
    force = force,
  })

  if not unit_group or not unit_group.valid then
    game.print("Failed to create unit group!")
    return nil
  end
  
  -- Use unit_group's unique_id as our squad_id (matches event.unit_number)
  local squad_id = unit_group.unique_id
  
  -- Create soldiers and add to group in a circle around spawn point
  local soldiers = {}
  local angle_step = (2 * math.pi) / SOLDIERS_PER_SQUAD
  for j = 1, SOLDIERS_PER_SQUAD do
    -- Offset search position in a circle (2 tile radius)
    local angle = angle_step * (j - 1)
    local search_pos = {
      x = spawn_pos.x + math.cos(angle) * 2,
      y = spawn_pos.y + math.sin(angle) * 2,
    }
    local soldier_pos = surface.find_non_colliding_position("soldier-unit", search_pos, 5, 0.5)
    if soldier_pos then
      local soldier = surface.create_entity({
        name = "soldier-unit",
        position = soldier_pos,
        force = force,
      })
      if soldier and soldier.valid then
        table.insert(soldiers, soldier)
        unit_group.add_member(soldier)
      end
    end
  end
  storage.squads[squad_id] = {
    unit_group = unit_group,
    soldiers = soldiers,
    command = "none",
    hq_position = position,
    status = STATUS.IDLE,
  }
  return squad_id
end

-- ============================================
-- ORDER STATE MANAGEMENT
-- ============================================

function M.cleanup()
  -- Collect squad IDs first to avoid modifying table during iteration
  local to_remove = {}
  for squad_id, squad_data in pairs(storage.squads) do
    if not squad_data then
      table.insert(to_remove, {id = squad_id, reason = "no squad_data"})
    else
      -- Count alive soldiers and clean up dead ones
      local alive_soldiers = {}
      if squad_data.soldiers then
        for _, soldier in pairs(squad_data.soldiers) do
          if soldier and soldier.valid then
            table.insert(alive_soldiers, soldier)
          end
        end
      end
      squad_data.soldiers = alive_soldiers
      
      -- Check if unit_group is valid
      local group_valid = squad_data.unit_group and squad_data.unit_group.valid
      
      if #alive_soldiers == 0 then
        -- No soldiers left, mark for removal
        if group_valid then
          squad_data.unit_group.destroy()
        end
        table.insert(to_remove, {id = squad_id, reason = "all soldiers dead"})
      end
    end
  end
end

function M.update_all()
    if not storage.squads then return end

    for squad_id, squad_data in pairs(storage.squads) do
        if not squad_data then goto continue end
        
        -- Chart area around valid squads (reveal fog of war)
        if squad_data.unit_group and squad_data.unit_group.valid then
            local pos = squad_data.unit_group.position
            local surface = squad_data.unit_group.surface
            local force = squad_data.unit_group.force
            -- Reveal 32 tiles (1 chunk) around the squad
            force.chart(surface, {
                {pos.x - 32, pos.y - 32},
                {pos.x + 32, pos.y + 32}
            })
        end
        
        -- Check for stuck squads (command running too long)
        if squad_data.status ~= STATUS.IDLE and squad_data.command_started_tick then
            local elapsed = game.tick - squad_data.command_started_tick
            if elapsed > COMMAND_TIMEOUT_TICKS then
                game.print("[Squad " .. squad_id .. "] Command timed out after " .. math.floor(elapsed/60) .. "s, resetting")
                squad_data.status = STATUS.IDLE
                squad_data.command_started_tick = nil
            end
        end

        if M.is_squad_operational(squad_id) and squad_data.status == STATUS.IDLE then
            M.next_order(squad_id)
        end
        ::continue::
    end
end

function M.next_order(squad_id)
    local squad_data = M.get_valid_squad(squad_id)
    if not squad_data then return end
    
    local area = M.get_explorable_area(squad_data.unit_group.surface, squad_data.unit_group.force, squad_data.hq_position, SQUAD_OPERATIONAL_RADIUS)
    if area.unexplored and #area.unexplored > 0 then
        -- Prioritize unexplored chunks
        table.sort(area.unexplored, function(a, b) return a.distance < b.distance end)     
    end

    -- Decide next order
    if M.is_squad_operational(squad_id) and squad_data.status == STATUS.IDLE then
        if false then return -- if battalion order - execute it
        elseif false then return -- elseif platoon order - execute it
        elseif (#area.unexplored > 0) then M.squad_explore(squad_id, area.unexplored[1].world) return -- elseif explore order - continue exploring
        else M.squad_patrol(squad_id) end -- else patrole around HQ
    else
        -- Not operational, return to base
        M.return_to_base(squad_id)
    end
end

-- ============================================
-- SQUAD ORDERS
-- ============================================

function M.move_squad_to_position(squad_id, position)
    local squad_data = M.get_valid_squad(squad_id)
    if not squad_data then return end

    squad_data.status = STATUS.MOVING
    squad_data.command = ORDERS.MOVE_TO_POSITION
    squad_data.command_started_tick = game.tick
    squad_data.unit_group.set_command({
      type = defines.command.go_to_location,
      destination = position,
      radius = 2,
      distraction = defines.distraction.by_enemy,
    })
end

function M.return_to_base(squad_id)
  local squad_data = M.get_valid_squad(squad_id)
  if not squad_data then return end
  
  squad_data.status = STATUS.RETREATING
  squad_data.command = ORDERS.RETURN_TO_BASE
  squad_data.command_started_tick = game.tick
  squad_data.unit_group.set_command({
      type = defines.command.go_to_location,
      destination = squad_data.hq_position,
      radius = 5,
      distraction = defines.distraction.by_enemy,
    })
end

function M.retreat_squad(squad_id)
    local squad_data = M.get_valid_squad(squad_id)
    if not squad_data then return end
    
    squad_data.status = STATUS.RETREATING
    squad_data.command = ORDERS.RETREAT_TO_BASE
    squad_data.command_started_tick = game.tick
    squad_data.unit_group.set_command({
      type = defines.command.go_to_location,
      destination = squad_data.hq_position,
      radius = 5,
      distraction = defines.distraction.none,
    })
end

function M.squad_explore(squad_id, target)
  local squad_data = M.get_valid_squad(squad_id)
  if not squad_data then return end

  squad_data.status = STATUS.MOVING
  squad_data.command = ORDERS.SQUAD_EXPLORE
  squad_data.command_started_tick = game.tick
  squad_data.unit_group.set_command({
    type = defines.command.go_to_location,
    destination = target,
    radius = 2,
    distraction = defines.distraction.by_enemy,
  })
  return true
end

function M.squad_patrol(squad_id)
  local squad_data = M.get_valid_squad(squad_id)
  if not squad_data then return false end
  
  -- Pick a random point within operational radius of HQ
  local angle = math.random() * 2 * math.pi
  local dist = math.random() * SQUAD_OPERATIONAL_RADIUS * 0.5
  local target = {
    x = squad_data.hq_position.x + math.cos(angle) * dist,
    y = squad_data.hq_position.y + math.sin(angle) * dist,
  }
  
  squad_data.status = STATUS.MOVING
  squad_data.command = ORDERS.SQUAD_PATROL
  squad_data.command_started_tick = game.tick
  squad_data.unit_group.set_command({
    type = defines.command.go_to_location,
    destination = target,
    radius = 5,
    distraction = defines.distraction.by_enemy,
  })
  return true
end

-- ===========================================
-- EVENT HANDLERS
-- ============================================

function M.on_ai_command_completed(event)
  local squad_data = M.get_valid_squad(event.unit_number)
  if not squad_data then return end
  
  game.print("Squad: " .. tostring(event.unit_number) .. " completed command: " .. tostring(squad_data.command))
  squad_data.status = STATUS.IDLE
  squad_data.command_started_tick = nil
  M.next_order(event.unit_number)
end

function M.on_squad_retreat(event)
    if not M.is_squad_operational(event.unit_number) then
        M.retreat_squad(event.unit_number)
    end
end

function M.on_squad_abort_mission(event)
    M.return_to_base(event.unit_number)
end

function M.on_squad_created(event)
    local unit_group = event.group
    if not unit_group or not unit_group.valid then return end
    
    local squad_id = unit_group.unique_id
    storage.squads[squad_id] = {
      unit_group = unit_group,
      soldiers = {},
      command = ORDERS.NONE,
      hq_position = unit_group.position,
      status = STATUS.IDLE,
    } 
end

-- ===========================================
-- EVENTS REGISTRATION
-- ===========================================

function M.register_events()
    script.on_event(defines.events.on_ai_command_completed, M.on_ai_command_completed)
    script.on_event(defines.events.on_unit_group_created, M.on_squad_created)
end

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

function M.is_squad_operational(squad_id)
  local squad_data = M.get_valid_squad(squad_id)
  if not squad_data then return false end
  
  local count = 0
  for _, soldier in pairs(squad_data.soldiers) do
    if soldier and soldier.valid then
      count = count + 1
    end
  end
  if count >= OPERATIONAL_THRESHOLD then
    return true
  else
    return false
  end
end

function M.is_squad_retreatable(squad_id)
  local squad_data = M.get_valid_squad(squad_id)
  if not squad_data then return false end
  
  local count = 0
  for _, soldier in pairs(squad_data.soldiers) do
    if soldier and soldier.valid then
      count = count + 1
    end
  end
  if count <= RETREAT_THRESHOLD then
    return true
  else
    return false
  end
end

function M.get_explorable_area(surface, force, center_pos, radius)
  local chunk_radius = math.ceil(radius / 32)
  local center_chunk_x = math.floor(center_pos.x / 32)
  local center_chunk_y = math.floor(center_pos.y / 32)
  
  local result = {
    unexplored = {},      -- Not charted, can explore
    explored = {},        -- Already charted
    not_generated = {},   -- Chunk doesn't exist yet
  }
  
  for dx = -chunk_radius, chunk_radius do
    for dy = -chunk_radius, chunk_radius do
      local chunk_pos = {x = center_chunk_x + dx, y = center_chunk_y + dy}
      local world_pos = {
        x = (chunk_pos.x + 0.5) * 32,
        y = (chunk_pos.y + 0.5) * 32,
      }
      
      -- Check if within circular radius (not just square)
      local dist = math.sqrt((dx * 32)^2 + (dy * 32)^2)
      if dist <= radius then
        local entry = {
          chunk = chunk_pos,
          world = world_pos,
          distance = dist,
        }
        
        if not surface.is_chunk_generated(chunk_pos) then
          table.insert(result.not_generated, entry)
        elseif not force.is_chunk_charted(surface, chunk_pos) then
          table.insert(result.unexplored, entry)
        else
          table.insert(result.explored, entry)
        end
      end
    end
  end
  return result
end

function M.get_valid_squad(squad_id)
    local squad_data = storage.squads[squad_id]
    if not squad_data then return nil end
    if not squad_data.unit_group or not squad_data.unit_group.valid then 
        game.print("Invalid squad ID: " .. tostring(squad_id))
        storage.squads[squad_id] = nil
        return nil end
    -- delete invalid squads

    return squad_data
end

return M