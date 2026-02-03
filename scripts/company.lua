local M = {}

function M.init_storage()
  storage.companies = storage.companies or {}
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

function M.on_built(event)
  local entity = event.entity or event.created_entity
  if not entity or not entity.valid then return end
  
  if entity.name == "company-hq" then
    storage.companies[entity.unit_number] = {
      entity = entity,
    }
  end
end

function M.on_destroyed(event)
  local entity = event.entity
  if not entity then return end
  
  if entity.name == "company-hq" then
    storage.companies[entity.unit_number] = nil
  end
end

return M