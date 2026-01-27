local M = {}

local BATTALIONS_PER_BRIGADE = 3
local COMPANIES_PER_BATTALION = 3
local PLATOONS_PER_COMPANY = 3
local SQUADS_PER_PLATOON = 3
local MAX_SOLDIERS_PER_SQUAD = 8

-- ============================================
-- STORAGE INITIALIZATION
-- ============================================

function M.init_storage()
  storage.brigade_hqs = storage.brigade_hqs or {}
  storage.battalion_hqs = storage.battalion_hqs or {}
  storage.deploy_missions = storage.deploy_missions or {}
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

function M.on_built(event)
  local entity = event.entity or event.created_entity
  if not entity or not entity.valid then return end
  
  if entity.name == "brigade-hq" then
    M.register_brigade(entity)
  elseif entity.name == "battalion-hq" then
    M.register_battalion(entity.unit_number, entity)
  end
end

function M.on_destroyed(event)
  local entity = event.entity
  if not entity then return end
  
  if entity.name == "brigade-hq" then
    M.unregister_brigade(entity.unit_number)
  elseif entity.name == "battalion-hq" then
    M.unregister_battalion(entity.unit_number)
  end
end

-- ============================================
-- BRIGADE HQ MANAGEMENT
-- ============================================

function M.register_brigade(entity)
  storage.brigade_hqs[entity.unit_number] = {
    entity = entity,
  }
end

function M.unregister_brigade(unit_number)
  storage.brigade_hqs[unit_number] = nil
end

function M.get_nearest_brigade(surface, position, force)
  local nearest = nil
  local nearest_dist = math.huge
  
  for _, data in pairs(storage.brigade_hqs) do
    local entity = data.entity
    if entity and entity.valid and entity.surface == surface and entity.force == force then
      local dist = ((entity.position.x - position.x)^2 + (entity.position.y - position.y)^2)^0.5
      if dist < nearest_dist then
        nearest = data
        nearest_dist = dist
      end
    end
  end
  
  return nearest
end

-- ============================================
-- BATTALION HQ MANAGEMENT
-- ============================================

function M.register_battalion(id, entity)
  storage.battalion_hqs[id] = {
    entity = entity,
  }
end

function M.unregister_battalion(unit_number)
  storage.battalion_hqs[unit_number] = nil
end 

return M