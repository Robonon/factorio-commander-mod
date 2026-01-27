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

function M.register_platoon(entity)
  game.print("Registering platoon HQ with unit number: " .. entity.unit_number)
  storage.platoons[entity.unit_number] = {
    entity = entity,
    squad_ids = squad.create_squads_for_platoon(entity.surface, entity.position, entity.force, SQUADS_PER_PLATOON),
  }
end

function M.unregister_platoon(unit_number)
  storage.platoons[unit_number] = nil
end

function M.on_ai_command_completed(event)
end

function M.update_all()
  for unit_number, _ in pairs(storage.platoons) do
  end
end

return M