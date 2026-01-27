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
    M.register_company(entity)
  end
end

function M.on_destroyed(event)
  local entity = event.entity
  if not entity then return end
  
  if entity.name == "company-hq" then
    M.unregister_company(entity.unit_number)
  end
end

-- ============================================
-- COMPANY MANAGEMENT
-- ============================================

function M.register_company(entity)
  storage.companies[entity.unit_number] = {
    entity = entity,
  }
end

function M.unregister_company(unit_number)
  storage.companies[unit_number] = nil
end

function M.update_all()
end

function M.on_ai_command_completed(event)
end

return M