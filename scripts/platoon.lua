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

function M.issue_platoon_attack(platoon_id, position)
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

function M.issue_platoon_abort(platoon_id)
    local platoon = storage.platoons[platoon_id]
    if not platoon then return false end
    for _, squad_id in pairs(platoon.squad_ids) do
        squad.return_to_base(squad_id)
    end
  
end

function M.update_platoons()
    if not storage.platoons then return false end
    for platoon_id, platoon in pairs(storage.platoons) do
        if not platoon.entity or not platoon.entity.valid then
            M.unregister_platoon(platoon_id)
        elseif #platoon.squad_ids < SQUADS_PER_PLATOON then
            local hq_inventory = platoon.entity.get_inventory(defines.inventory.chest)
            if not hq_inventory or not hq_inventory.valid then return end
            if hq_inventory.get_item_count("soldier-token") < (SQUADS_PER_PLATOON * 8) - (#platoon.squad_ids * 8) then return end
            platoon.squad_ids = squad.create_squads_for_platoon(
                platoon.entity.surface,
                platoon.entity.position,
                platoon.entity.force,
                platoon_id,
                SQUADS_PER_PLATOON - #platoon.squad_ids
            )
        end
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
  for _, squad_id in pairs(storage.platoons[unit_number].squad_ids) do
      local squad_data = squad.get_valid_squad(squad_id)
      if squad_data then
          for _, entity in pairs(squad_data.unit_group.members) do
              entity.destroy{raise_destroy=true}
          end
      end
  end
  storage.platoons[unit_number] = nil
end

--- ===========================================
--- EVENTS
--- ===========================================

function M.on_chart_tag_added(event)
    if not event.tag or not event.tag.valid then return end
    for platoon_id, platoon in pairs(storage.platoons) do
        if not platoon.entity or not platoon.entity.valid then
          return
        end
        if event.tag.text == tostring(platoon_id) then
            M.issue_platoon_attack(platoon_id, event.tag.position)
        end
    end
end

function M.on_chart_tag_destroyed(event)
  if not event.tag or not event.tag.valid then return end
    for platoon_id, platoon in pairs(storage.platoons) do
        if not platoon.entity or not platoon.entity.valid then
          return
        end
        if event.tag.text == tostring(platoon_id) then
            M.issue_platoon_abort(platoon_id)
        end
    end
end

-- function M.register_events()
--     script.on_event(defines.events.on_item, M.try_recover_soldier)
-- end




return M