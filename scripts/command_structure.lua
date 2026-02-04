local squad_module = require("scripts.squad")
local M = {}

local TOTAL_BRIGADES = 1
local BATTALIONS_PER_BRIGADE = 3
local COMPANIES_PER_BATTALION = 3
local PLATOONS_PER_COMPANY = 3
local SQUADS_PER_PLATOON = 3
local SOLDIERS_PER_SQUAD = 8


function M.init_storage()
    storage.brigades = storage.brigades or {}
    storage.brigade_count = storage.brigade_count or 0
    
    storage.battalions = storage.battalions or {}
    storage.battalion_count = storage.battalion_count or 0
    
    storage.companies = storage.companies or {}
    storage.company_count = storage.company_count or 0

    storage.platoons = storage.platoons or {}
    storage.platoon_count = storage.platoon_count or 1
end


-- UNIT COMMANDS

function M.issue_unit_attack(entity)
    if not entity or not entity.valid then return end

    -- create HQ and store in storage
    if entity.name == "brigade-hq" then
        
    elseif entity.name == "battalion-hq" then

    elseif entity.name == "company-hq" then

    elseif entity.name == "platoon-hq" then
        M.issue_platoon_attack(entity.unit_number, entity.position)
    end
end

function M.issue_platoon_attack(platoon_id, position)
    local platoon = storage.platoons[platoon_id]
    if not platoon then return false end
    for _, squad_id in pairs(platoon.squad_ids) do
        squad_module.next_order(squad_id,
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
        squad_module.return_to_base(squad_id)
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
            if hq_inventory.get_item_count("soldier-token") < (SQUADS_PER_PLATOON * SOLDIERS_PER_SQUAD) - (#platoon.squad_ids * SOLDIERS_PER_SQUAD) then return end
            platoon.squad_ids = squad_module.create_squads_for_platoon(
                platoon.entity.surface,
                platoon.entity.position,
                platoon.entity.force,
                platoon_id,
                SQUADS_PER_PLATOON - #platoon.squad_ids
            )
        end
    end
end

--- EVENTS

function M.on_built(event)
    local entity = event.entity or event.created_entity
    if not entity or not entity.valid then return end

    -- create HQ and store in storage
    if entity.name == "brigade-hq" then
        storage.brigades[entity.unit_number] = {entity = entity}
        storage.brigade_count = storage.brigade_count + 1
    elseif entity.name == "battalion-hq" then
        storage.battalions[entity.unit_number] = {entity = entity}
        storage.battalion_count = storage.battalion_count + 1
    elseif entity.name == "company-hq" then
        storage.companies[entity.unit_number] = {entity = entity}
        storage.company_count = storage.company_count + 1
    elseif entity.name == "platoon-hq" then
        storage.platoons[entity.unit_number] = {
            entity = entity,
            squad_ids = squad_module.create_squads_for_platoon(entity.surface, entity.position, entity.force, entity.unit_number, SQUADS_PER_PLATOON),
        }
        storage.platoon_count = storage.platoon_count + 1
    end
end

function M.on_destroyed(event)
    local entity = event.entity
    if not entity then return end
    
    -- remove HQ from storage
    if entity.name == "brigade-hq" then
        storage.brigades[entity.unit_number] = nil
        storage.brigade_count = storage.brigade_count - 1
    elseif entity.name == "battalion-hq" then
        storage.battalions[entity.unit_number] = nil
        storage.battalion_count = storage.battalion_count - 1
    elseif entity.name == "company-hq" then
        storage.companies[entity.unit_number] = nil
        storage.company_count = storage.company_count - 1
    elseif entity.name == "platoon-hq" then
        for _, squad_id in pairs(storage.platoons[entity.unit_number].squad_ids) do
            local squad_data = squad_module.get_valid_squad(squad_id)
            if squad_data then
                for _, squad in pairs(squad_data.unit_group.members) do
                    squad.destroy{raise_destroy=true}
                end
            end
        end
        storage.platoons[entity.unit_number] = nil
        storage.platoon_count = storage.platoon_count - 1
    end
end

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

function M.on_chart_tag_changed(event)
    -- Not implemented yet
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

return M