local M = {}
local SOLDIERS_PER_SQUAD = 8
local OPERATIONAL_THRESHOLD = 3  -- Minimum soldiers to remain operational
local RETREAT_THRESHOLD = 2      -- Retreat when at or below this
local SQUAD_OPERATIONAL_RADIUS = 300
local HQ_REINFORCEMENT_RADIUS = 30
local STATUS = {
  OPERATIONAL = "operational",
  RETREATING = "retreating",
  REINFORCING = "reinforcing",
}
local INTEGRITY = {
  FULL_STRENGTH = "full_strength",
  NEEDS_REINFORCEMENTS = "needs_reinforcements",
}

local PATHFINDER_FLAGS = {
    allow_destroy_friendly_entities = false,
    allow_paths_through_own_entities = true,
    cache = false,
    prefer_straight_paths = true,
    low_priority = false,
    no_break = true,
}
-- ============================================
-- STORAGE INITIALIZATION
-- ============================================

function M.init_storage()
  storage.squads = storage.squads or {}
  storage.cleanup_queue = storage.cleanup_queue or {}
end

-- ============================================
-- SQUAD MANAGEMENT
-- ============================================

function M.create_squads_for_platoon(surface, position, force, platoon_id, num_squads)
  local squad_ids = {}
  for i = 1, num_squads do
    table.insert(squad_ids, M.create_squad(surface, position, force, platoon_id))
  end
  return squad_ids
end

function M.create_squad(surface, position, force, platoon_id)

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
    platoon_id = platoon_id,
    unit_group = unit_group,
    soldiers = soldiers,
    hq_position = position,
    status = STATUS.OPERATIONAL,
    integrity = INTEGRITY.FULL_STRENGTH,
  }
  M.update_integrity(squad_id)
  M.update_status(squad_id)
  return squad_id
end

function M.reinforce_squad(squad_id)
  local squad_data = M.get_valid_squad(squad_id)
  if not squad_data then return end
  
  local surface = squad_data.unit_group.surface
  local force = squad_data.unit_group.force
  local hq = surface.find_entity("platoon-hq", squad_data.hq_position)
  if not hq or not hq.valid then return end
  
  local hq_inventory = hq.get_inventory(defines.inventory.chest)
  if not hq_inventory then return end
  
  for i = #squad_data.unit_group.members, SOLDIERS_PER_SQUAD - 1 do
    if hq_inventory.get_item_count("soldier-token") <= 0 then
        return
    end
    hq_inventory.remove({name = "soldier-token", count = 1})

    local spawn_pos = surface.find_non_colliding_position("soldier-unit", squad_data.hq_position, HQ_REINFORCEMENT_RADIUS, 0.5)
    if not spawn_pos then
      game.print("Could not find spawn position for reinforcement!")
      return false
    end
    
    local soldier = surface.create_entity({
      name = "soldier-unit",
      position = spawn_pos,
      force = force,
    })
    if soldier and soldier.valid then
      table.insert(squad_data.soldiers, soldier)
      squad_data.unit_group.add_member(soldier)
    end
  end
  M.update_integrity(squad_id)
  M.update_status(squad_id)
end

-- ============================================
-- ORDER STATE MANAGEMENT
-- ============================================

function M.cleanup(squad_id)
    local squad_data = storage.squads[squad_id]
    if not squad_data then return end
    
    -- Unit group is still valid - nothing to clean up
    if squad_data.unit_group and squad_data.unit_group.valid then
        return
    end
    
    -- Unit group invalid - try to recover with surviving soldiers
    local surviving_soldiers = {}
    if squad_data.soldiers then
        for _, soldier in pairs(squad_data.soldiers) do
            if soldier and soldier.valid then
                -- Only take soldiers not already in a valid group
                if not soldier.unit_group or not soldier.unit_group.valid then
                    table.insert(surviving_soldiers, soldier)
                end
            end
        end
    end
    
    if #surviving_soldiers > 0 then
        -- Create new unit group from survivors
        local first = surviving_soldiers[1]
        local new_group = first.surface.create_unit_group({
            position = first.position,
            force = first.force,
        })
        
        if new_group and new_group.valid then
            for _, soldier in pairs(surviving_soldiers) do
                new_group.add_member(soldier)
            end
            
            -- Migrate to new squad entry (new unique_id)
            local new_squad_id = new_group.unique_id
            storage.squads[new_squad_id] = {
                unit_group = new_group,
                soldiers = surviving_soldiers,
                command = squad_data.command or "none",
                hq_position = squad_data.hq_position,
                status = squad_data.status,
                integrity = squad_data.integrity,
            }
            storage.squads[squad_id] = nil  -- Remove old entry
            return
        end
    end
    
    -- No survivors or failed to create group - remove squad
    game.print("[Squad " .. squad_id .. "] Lost - no survivors")
    storage.squads[squad_id] = nil
end


function M.update_all()
    if not storage.squads then return end

    for squad_id, squad_data in pairs(storage.squads) do
        if not squad_data then goto continue end
        
        -- Skip invalid squads (will be cleaned up by cleanup())
        if not squad_data.unit_group or not squad_data.unit_group.valid then
            goto continue
        end
        
        -- Chart area around valid squads (reveal fog of war)
        local pos = squad_data.unit_group.position
        local surface = squad_data.unit_group.surface
        local force = squad_data.unit_group.force
        force.chart(surface, {
            {pos.x - 32, pos.y - 32},
            {pos.x + 32, pos.y + 32}
        })
        
        -- -- Check for stuck squads (command running too long)
        -- if squad_data.status ~= STATUS.IDLE and squad_data.command_started_tick then
        --     local elapsed = game.tick - squad_data.command_started_tick
        --     if elapsed > COMMAND_TIMEOUT_TICKS then
        --         game.print("[Squad " .. squad_id .. "] Command timed out after " .. math.floor(elapsed/60) .. "s, resetting")
        --         squad_data.status = STATUS.IDLE
        --         squad_data.command_started_tick = nil
        --     end
        -- end

        -- M.update_status(squad_id)
        -- M.update_integrity(squad_id)
        
        -- if not squad_data.unit_group.has_command then
        --     M.next_order(squad_id)
        -- end
        ::continue::
    end
end

function M.update_status(squad_id)
    squad_data = M.get_valid_squad(squad_id)
    if not squad_data then return end

    if M.is_squad_operational(squad_id) and squad_data.status ~= STATUS.OPERATIONAL then
        squad_data.status = STATUS.OPERATIONAL
    end

    if M.is_squad_retreatable(squad_id) and squad_data.status ~= STATUS.RETREATING then
        squad_data.status = STATUS.RETREATING
    end

    if M.needs_reinforcements(squad_id) and M.can_reinforce(squad_id) and M.reinforcements_available(squad_id) and squad_data.status ~= STATUS.REINFORCING then
        squad_data.status = STATUS.REINFORCING
    end
end

function M.update_integrity(squad_id)
    squad_data = M.get_valid_squad(squad_id)
    if not squad_data then return end

    if M.needs_reinforcements(squad_id) then
        squad_data.integrity = INTEGRITY.NEEDS_REINFORCEMENTS
    else
        squad_data.integrity = INTEGRITY.FULL_STRENGTH
    end
end
function M.next_order(squad_id, order)
    local squad_data = M.get_valid_squad(squad_id)
    if not squad_data then return end

    -- local area = M.get_explorable_area(squad_data.unit_group.surface, squad_data.unit_group.force, squad_data.hq_position, SQUAD_OPERATIONAL_RADIUS)
    -- if area.unexplored and #area.unexplored > 0 then
    --     -- Prioritize unexplored chunks
    --     table.sort(area.unexplored, function(a, b) return a.distance < b.distance end)     
    -- end

    -- Decide next order
    if squad_data.status == STATUS.OPERATIONAL and order then
        squad_data.unit_group.set_command(order)
        return -- if command order - execute it
        -- elseif (#area.unexplored > 0) then M.squad_explore(squad_id, area.unexplored[math.random(1, #area.unexplored)].world) return -- elseif explore order - continue exploring
        -- else M.squad_patrol(squad_id) end -- else patrole around HQ
    elseif squad_data.status == STATUS.REINFORCING then
        M.reinforce_squad(squad_id)
        return
    else
      squad_data.unit_group.set_command({
          type = defines.command.wander,
          radius = 10,
          distraction = defines.distraction.by_enemy,
        })
        return
    end

end

-- ============================================
-- SQUAD ORDERS
-- ============================================

function M.move_squad_to_position(squad_id, position)
    local squad_data = M.get_valid_squad(squad_id)
    if not squad_data then return end
    squad_data.unit_group.set_command({
      type = defines.command.go_to_location,
      destination = position,
      radius = 2,
      distraction = defines.distraction.by_enemy,
        pathfind_flags = PATHFINDER_FLAGS,
    })
end

function M.return_to_base(squad_id)
  local squad_data = M.get_valid_squad(squad_id)
  if not squad_data then return end
  squad_data.unit_group.set_command({
      type = defines.command.go_to_location,
      destination = squad_data.hq_position,
      radius = 5,
      distraction = defines.distraction.by_enemy,
      pathfind_flags = PATHFINDER_FLAGS,
    })
end

function M.retreat_squad(squad_id)
    local squad_data = M.get_valid_squad(squad_id)
    if not squad_data then return end
    squad_data.unit_group.set_command({
      type = defines.command.go_to_location,
      destination = squad_data.hq_position,
      radius = 5,
      distraction = defines.distraction.none,
      pathfind_flags = PATHFINDER_FLAGS,
    })
end

function M.squad_explore(squad_id, target)
  local squad_data = M.get_valid_squad(squad_id)
  if not squad_data then return end
  squad_data.unit_group.set_command({
    type = defines.command.go_to_location,
    destination = target,
    radius = 5,
    distraction = defines.distraction.by_enemy,
    pathfind_flags = PATHFINDER_FLAGS,
  })
end

function M.squad_patrol(squad_id)
  local squad_data = M.get_valid_squad(squad_id)
  if not squad_data then return end
  
  -- Pick a random point within operational radius of HQ
  local angle = math.random() * 2 * math.pi
  local dist = math.random() * SQUAD_OPERATIONAL_RADIUS * 0.5
  local target = {
    x = squad_data.hq_position.x + math.cos(angle) * dist,
    y = squad_data.hq_position.y + math.sin(angle) * dist,
  }

  squad_data.unit_group.set_command({
    type = defines.command.go_to_location,
    destination = target,
    radius = 5,
    distraction = defines.distraction.by_enemy,
    pathfind_flags = PATHFINDER_FLAGS,
  })
end

-- ===========================================
-- EVENT HANDLERS
-- ============================================

function M.on_ai_command_completed(event)
  local squad_data = M.get_valid_squad(event.unit_number)
  if not squad_data then return end
  M.update_integrity(event.unit_number)
  M.update_status(event.unit_number)
  if not M.is_squad_within_radius(squad_data, HQ_REINFORCEMENT_RADIUS) then
      M.return_to_base(event.unit_number)
  else 
      M.next_order(event.unit_number)
  end

end

function M.on_squad_retreat(event)
    if M.is_squad_retreatable(event.unit_number) then
        M.retreat_squad(event.unit_number)
    end
end

function M.on_entity_died(event)
    local squad_data = M.get_valid_squad(event.unit_number)
    if not squad_data then return end
    
    M.update_integrity(event.unit_number)
    M.update_status(event.unit_number)

    if M.is_squad_retreatable(event.unit_number) and squad_data.status ~= STATUS.RETREATING then
        M.retreat_squad(event.unit_number)
    end
end

function M.try_recover_soldier(event)
    local soldier = event.unit
    if soldier and soldier.valid and soldier.name == "soldier-unit" then
        event.group.add_member(soldier)
    end
end 

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get live soldier count directly from unit_group (most reliable)
function M.get_soldier_count(squad_id)
  local squad_data = M.get_valid_squad(squad_id)
  if not squad_data then return 0 end
  
  -- unit_group.members is the authoritative list
  if squad_data.unit_group and squad_data.unit_group.valid then
    return #squad_data.unit_group.members
  end
  return 0
end

function M.is_squad_operational(squad_id)
    return M.get_soldier_count(squad_id) >= OPERATIONAL_THRESHOLD
end

function M.is_squad_retreatable(squad_id)
  return M.get_soldier_count(squad_id) <= RETREAT_THRESHOLD
end

function M.needs_reinforcements(squad_id)
    squad_data = M.get_valid_squad(squad_id)
    if not squad_data then return false end
    if M.get_soldier_count(squad_id) < SOLDIERS_PER_SQUAD then
        return true
    end
    return false
end

function M.can_reinforce(squad_id)
    local squad_data = M.get_valid_squad(squad_id)
    if not squad_data then return false end

    if squad_data.unit_group and squad_data.unit_group.valid then
          if M.is_squad_within_radius(squad_data, HQ_REINFORCEMENT_RADIUS) then
              return true
        end
    else
        return false
    end
end

function M.is_squad_within_radius(squad_data, radius)
    if not squad_data or not squad_data.unit_group or not squad_data.unit_group.valid then return false end
  local pos = squad_data.unit_group.position
  local hq = squad_data.hq_position
  local dx = pos.x - hq.x
  local dy = pos.y - hq.y
  return (dx * dx + dy * dy) <= (radius * radius)
end

function M.get_reinforcements_available(squad_id)
    local squad_data = M.get_valid_squad(squad_id)
    if not squad_data then return 0 end

    local hq = squad_data.unit_group.surface.find_entity("platoon-hq", squad_data.hq_position)
    if not hq or not hq.valid then
        return 0
    end
    local hq_inventory = hq.get_inventory(defines.inventory.chest)
    if not hq_inventory then
        return 0
    end

    local item_count = hq_inventory.get_item_count("soldier-token")
    if not item_count then
        return 0
    end
    return item_count
end

function M.reinforcements_available(squad_id)
    local squad_data = M.get_valid_squad(squad_id)
    if not squad_data then return false end
    
    local hq = squad_data.unit_group.surface.find_entity("platoon-hq", squad_data.hq_position)
    if not hq or not hq.valid then
        return false
    end
    local hq_inventory = hq.get_inventory(defines.inventory.chest)
    if not hq_inventory then
        return false
    end

    local item_count = hq_inventory.get_item_count("soldier-token")
    if not item_count then
        return false
    end

    if item_count <= 0 then
        return false
    end
    return true
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
    if not squad_data then return end
    if not squad_data.unit_group or not squad_data.unit_group.valid then 
        game.print("Invalid squad ID: " .. tostring(squad_id)) 
        M.cleanup(squad_id)
        return nil 
    end
    return squad_data
end

return M