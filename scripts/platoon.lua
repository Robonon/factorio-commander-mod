local squad = require("scripts.squad")
local M = {}

local SQUADS_PER_PLATOON = 3
local PLATOON_OPERATIONAL_RADIUS = 500

function M.init_storage()
  storage.platoons = storage.platoons or {}
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

function M.on_built(event)
  local entity = event.entity or event.created_entity
  if not entity or not entity.valid then return end
  
  if entity.name == "platoon-hq" then
    M.register_platoon(entity)
  end
end

function M.on_destroyed(event)
  local entity = event.entity
  if not entity then return end
  
  if entity.name == "platoon-hq" then
    M.unregister_platoon(entity.unit_number)
  end
end

-- ============================================
-- PLATOON MANAGEMENT
-- ============================================

function M.issue_platoon_command(platoon_id, position)
    local platoon = storage.platoons[platoon_id]
    if not platoon then return false end
    for _, squad_id in pairs(platoon.squad_ids) do

        squad.next_order(squad_id,
        {
            type = defines.command.attack_area,
            destination = position,
            radius = 10,
            distraction = defines.distraction.by_enemy,
        })
    end
end

function M.register_platoon(entity)
  game.print("Registering platoon HQ with unit number: " .. entity.unit_number)
  storage.platoons[entity.unit_number] = {
    entity = entity,
    squad_ids = squad.create_squads_for_platoon(entity.surface, entity.position, entity.force, entity.unit_number, SQUADS_PER_PLATOON),
  }
end

function M.unregister_platoon(unit_number)
  storage.platoons[unit_number] = nil
end

  --- ===========================================
  --- EVENTS
  --- ===========================================
  --- 


return M