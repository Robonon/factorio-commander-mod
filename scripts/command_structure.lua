local squad_module = require("scripts.squad")
local M = {}

M.TOTAL_BRIGADES = 1
M.BATTALIONS_PER_BRIGADE = 3
M.COMPANIES_PER_BATTALION = 3
M.PLATOONS_PER_COMPANY = 3
M.SQUADS_PER_PLATOON = 3
M.SOLDIERS_PER_SQUAD = 8

HQ = {}

function HQ:new(entity)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.entity = entity
    o.parent_hq_id = find_nearest_parent_hq_id(entity) or nil
    o.children_hq_ids = find_nearest_children(entity) or {}
    o.tag_id = create_tag_id(entity)
    o.maneuver_squad_ids = {}
    o.defense_squad_ids = {}
    o.root_entity = nil
    o.is_root = false
    o.is_leaf = false
    o.is_full = false
    return o
end

HQ_TYPES = {
    BRIGADE = "brigade-hq",
    BATTALION = "battalion-hq",
    COMPANY = "company-hq",
    PLATOON = "platoon-hq"
}
COMPANY_IDS = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}
UNIT_IDS = {1, 2, 3, 4, 5, 6, 7, 8, 9}

function M.init_storage()
    storage.HQ = storage.HQ or {}
    storage.HQ_counts = storage.HQ_counts or {
        [HQ_TYPES.BRIGADE] = 0,
        [HQ_TYPES.BATTALION] = 0,
        [HQ_TYPES.COMPANY] = 0,
        [HQ_TYPES.PLATOON] = 0,
    }
    storage.selected = storage.selected or {}
end

-- UNIT COMMANDS

function M.issue_unit_attack(hq_id, position)
    local hq = storage.HQ[hq_id]
    if not hq or not hq.entity or not hq.entity.valid then return false end
    if hq.children_hq_ids and #hq.children_hq_ids > 0 then
        for _, child_id in pairs(hq.children_hq_ids) do
            if child_id then
                M.issue_unit_attack(child_id, position)
            end
        end
    end

    if not hq.maneuver_squad_ids then return false end
    for _, squad_id in pairs(hq.maneuver_squad_ids) do
        squad_module.next_order(squad_id, {
            type = defines.command.attack_area,
            destination = position,
            radius = 10,
            distraction = defines.distraction.by_enemy,
        })
    end
end

function M.issue_unit_abort(hq)
    if not hq or not hq.entity or not hq.entity.valid then return false end
    if hq.children_hq_ids and #hq.children_hq_ids > 0 then
        for _, child_id in pairs(hq.children_hq_ids) do
            if child_id and storage.HQ[child_id] and storage.HQ[child_id].entity and storage.HQ[child_id].entity.valid then
                M.issue_unit_abort(storage.HQ[child_id])
            end
        end
    end

    if not hq.maneuver_squad_ids then return false end
    for _, squad_id in pairs(hq.maneuver_squad_ids) do
        squad_module.return_to_base(squad_id)
    end
end

function M.update_squads()
    if not storage.HQ then 
        return false
    end
    for id, hq in pairs(storage.HQ) do
        if not hq or not hq.entity or not hq.entity.valid then 
            goto continue
        end
        
        if hq.entity.name == HQ_TYPES.PLATOON then
            if not hq.maneuver_squad_ids then
                hq.maneuver_squad_ids = hq.maneuver_squad_ids or {}
            end
            for i = #hq.maneuver_squad_ids, 1, -1 do 
                if not hq.maneuver_squad_ids[i] then
                    table.remove(hq.maneuver_squad_ids, i)
                end
            end
            for index, squad_id in pairs(hq.maneuver_squad_ids) do
                local squad_data = squad_module.get_valid_squad(squad_id)
                if not squad_data or not squad_data.unit_group or not squad_data.unit_group.valid or squad_data.unit_group.members == 0 then
                    table.remove(hq.maneuver_squad_ids, index)
                end
            end
            if #hq.maneuver_squad_ids < M.SQUADS_PER_PLATOON then
                local hq_inventory = hq.entity.get_inventory(defines.inventory.chest)
                if not hq_inventory or not hq_inventory.valid then goto continue end
                for i = 1, M.SQUADS_PER_PLATOON - #hq.maneuver_squad_ids do
                    if hq_inventory.get_item_count("soldier-token") >= M.SOLDIERS_PER_SQUAD then
                        hq_inventory.remove{name="soldier-token", count=M.SOLDIERS_PER_SQUAD}
                        local new_squad_id = squad_module.create_squad(
                            hq.entity.surface,
                            hq.entity.position,
                            hq.entity.force,
                            hq.entity.unit_number
                        )
                        table.insert(hq.maneuver_squad_ids, new_squad_id)
                    end
                end
            end
        end
        storage.HQ[id] = hq
        ::continue::
    end
end

--- EVENTS

function M.on_built(event)
    local entity = event.entity or event.created_entity
    if not entity or not entity.valid then return end
    if not (entity.name == HQ_TYPES.BRIGADE or entity.name == HQ_TYPES.BATTALION or entity.name == HQ_TYPES.COMPANY or entity.name == HQ_TYPES.PLATOON) then return end

    if storage.HQ_counts[entity.name] and storage.HQ_counts[entity.name] >= M.hq_limit()[entity.name] then
        game.print("HQ limit reached for " .. entity.name)
        player = event.player_index and game.get_player(event.player_index)
        player.get_main_inventory().insert{name=entity.name, count=1}
        entity.destroy()
        return
    end

    local hq = HQ:new(entity)

    if hq.parent_hq_id then
        local parent_hq = storage.HQ[hq.parent_hq_id]
        if parent_hq then
            table.insert(parent_hq.children_hq_ids, entity.unit_number)
            storage.HQ[hq.parent_hq_id] = parent_hq
        end
    end
    
    storage.HQ[entity.unit_number] = hq
    storage.HQ_counts[entity.name] = storage.HQ_counts[entity.name] + 1
    update_tag_ids()
end

function M.on_destroyed(event)
    local entity = event.entity
    if not entity then return end
    if not (entity.name == HQ_TYPES.BRIGADE or entity.name == HQ_TYPES.BATTALION or entity.name == HQ_TYPES.COMPANY or entity.name == HQ_TYPES.PLATOON) then return end

    if entity.name == HQ_TYPES.PLATOON and storage.HQ[entity.unit_number]  and storage.HQ[entity.unit_number].maneuver_squad_ids then
        for _, squad_id in pairs(storage.HQ[entity.unit_number].maneuver_squad_ids) do
            local squad_data = squad_module.get_valid_squad(squad_id)
            if squad_data and squad_data.unit_group and squad_data.unit_group.members then
                for _, squad in pairs(squad_data.unit_group.members) do
                    if squad and squad.destroy then
                        squad.destroy{raise_destroy=true}
                    end
                end
            end
        end
    end
    
    -- Remove from parent's child list
    hq = storage.HQ[entity.unit_number]
    if hq and hq.parent_hq_id then
        local parent_hq = storage.HQ[hq.parent_hq_id]
        if parent_hq and parent_hq.children_hq_ids then
            for i, child_id in pairs(parent_hq.children_hq_ids) do
                if child_id == entity.unit_number then
                    table.remove(parent_hq.children_hq_ids, i)
                    break
                end
            end
            storage.HQ[hq.parent_hq_id] = parent_hq
        end
    end

    -- Remove childrens parent references
    if hq.children_hq_ids and #hq.children_hq_ids > 0 then
        for _, child_id in pairs(hq.children_hq_ids) do
            if child_id and storage.HQ[child_id] and storage.HQ[child_id].entity and storage.HQ[child_id].entity.valid then
                storage.HQ[child_id].parent_hq_id = nil
            end
        end
    end
    storage.HQ[entity.unit_number] = nil
    storage.HQ_counts[entity.name] = storage.HQ_counts[entity.name] - 1 or 0

    update_tag_ids()
end

function M.on_chart_tag_added(event)
    if not event.tag or not event.tag.valid then return end
    local hq = storage.HQ[tonumber(event.tag.text)]
    if not hq or not hq.entity or not hq.entity.valid or not hq.entity.unit_number then return end
    game.print("Received command for HQ " .. hq.entity.name .. " [" .. hq.entity.unit_number .. "] to attack position (" .. event.tag.position.x .. ", " .. event.tag.position.y .. ")")
    M.issue_unit_attack(hq.entity.unit_number, event.tag.position)
end

function M.on_chart_tag_changed(event)
    -- Not implemented yet
end

function M.on_chart_tag_destroyed(event)
    if not event.tag or not event.tag.valid then return end
    if not event.entity or not event.entity.valid then return end
    if not (event.entity.name == HQ_TYPES.BRIGADE or event.entity.name == HQ_TYPES.BATTALION or event.entity.name == HQ_TYPES.COMPANY or event.entity.name == HQ_TYPES.PLATOON) then return end
    local unit_number = event.entity.unit_number
    local hq = storage.HQ[unit_number]
    if hq and event.tag.text == tostring(unit_number) then
        M.issue_unit_abort(hq)
    end
end

function M.select_unit(event)
  if not event.player_index or not event.cursor_position then return end
  local player = game.get_player(event.player_index)
  if not player or not player.valid then return end
  local hqs = player.surface.find_entities_filtered{
    position = event.cursor_position,
    radius = 5,
    limit = 1,
    name = {"platoon-hq", "company-hq", "battalion-hq", "brigade-hq"},
  }
    if hqs and #hqs > 0 then
        local hq = storage.HQ[hqs[1].unit_number]
        if not storage.selected[player.index] or not storage.selected[player.index].valid then
            storage.selected[player.index] = storage.selected[player.index] or {}
        end
        if hq and hq.entity and hq.entity.valid and hq.tag_id then
            storage.selected[player.index] = hq
            player.print("Selected: " .. hq.tag_id)
        end
    end
end

function M.command_unit(event)
    if not event.cursor_position then return end
    if not event.player_index then return end
    local player = game.get_player(event.player_index)
    if not player or not player.valid then return end
    local hq = storage.selected[event.player_index]
    game.print(serpent.block(hq))
    if not hq or not hq.entity or not hq.entity.valid then return end
    M.issue_unit_attack(hq.entity.unit_number, event.cursor_position)
    player.print("Issuing command " .. hq.entity.name .. " [" .. hq.tag_id .. "] to attack position (" .. event.cursor_position.x .. ", " .. event.cursor_position.y .. ")")
    storage.selected[event.player_index] = nil
end
-- Utility functions

function M.hq_limit()
    local limits = {
        [HQ_TYPES.BRIGADE] = M.TOTAL_BRIGADES,
        [HQ_TYPES.BATTALION] = M.BATTALIONS_PER_BRIGADE * storage.HQ_counts[HQ_TYPES.BRIGADE],
        [HQ_TYPES.COMPANY] = M.COMPANIES_PER_BATTALION * storage.HQ_counts[HQ_TYPES.BATTALION],
        [HQ_TYPES.PLATOON] = M.PLATOONS_PER_COMPANY * storage.HQ_counts[HQ_TYPES.COMPANY],
    }
    for k, v in pairs(limits) do
        if v == 0 then limits[k] = 1 end
    end
    return limits
end

function euclidean_distance(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    return math.sqrt(dx * dx + dy * dy)
end

function manhattan_distance(pos1, pos2)
    return math.abs(pos1.x - pos2.x) + math.abs(pos1.y - pos2.y)
end

function find_nearest_parent_hq_id(entity)
    if not entity or not entity.valid or not entity.surface then return nil end
    local hq_to_find = nil
    if entity.name == HQ_TYPES.PLATOON then
        hq_to_find = HQ_TYPES.COMPANY
    elseif entity.name == HQ_TYPES.COMPANY then
        hq_to_find = HQ_TYPES.BATTALION
    elseif entity.name == HQ_TYPES.BATTALION then
        hq_to_find = HQ_TYPES.BRIGADE
    end
    if not hq_to_find then return nil end
    local hq_entities = entity.surface.find_entities_filtered{
        position = entity.position,
        radius = 1000,
        name = hq_to_find,
    }
    if hq_entities and #hq_entities > 0 then
        local nearest_hq_entity = nil
        local nearest_distance = math.huge
        for _, candidate in pairs(hq_entities) do
            local distance = euclidean_distance(entity.position, candidate.position)
            if distance < nearest_distance then
                nearest_hq_entity = candidate
                nearest_distance = distance
            end
        end
        if nearest_hq_entity and nearest_hq_entity.unit_number then
            return nearest_hq_entity.unit_number
        end
    end
    return nil
end

function find_nearest_children(entity)
    if not entity or not entity.valid or not entity.surface then return {} end
    local hq_to_find = nil
    local limit = 0
    if entity.name == HQ_TYPES.BRIGADE then
        hq_to_find = HQ_TYPES.BATTALION
        limit = M.BATTALIONS_PER_BRIGADE
    elseif entity.name == HQ_TYPES.BATTALION then
        hq_to_find = HQ_TYPES.COMPANY
        limit = M.COMPANIES_PER_BATTALION
    elseif entity.name == HQ_TYPES.COMPANY then
        hq_to_find = HQ_TYPES.PLATOON
        limit = M.PLATOONS_PER_COMPANY
    end
    if not hq_to_find then return {} end

    local child_entities = entity.surface.find_entities_filtered{
        position = entity.position,
        radius = 1000,
        name = hq_to_find,
    }
    table.sort(child_entities, function(a, b)
        local hq_a = storage.HQ[a]
        local hq_b = storage.HQ[b]
        if not hq_a or not hq_a.entity or not hq_a.entity.valid then return false end
        if not hq_b or not hq_b.entity or not hq_b.entity.valid then return true end
        local dist_a = euclidean_distance(entity.position, hq_a.entity.position)
        local dist_b = euclidean_distance(entity.position, hq_b.entity.position)
        return dist_a < dist_b
    end)

    local valid_children = {}
    if not child_entities then return {} end

    for _, child in pairs(child_entities) do
        if #valid_children >= limit then break end
        if child.unit_number and storage.HQ[child.unit_number] and storage.HQ[child.unit_number].parent_hq_id == nil then
            storage.HQ[child.unit_number].parent_hq_id = entity.unit_number
            table.insert(valid_children, child.unit_number)
        end
    end
    return valid_children or {}
end

function create_tag_id(entity)
    local id = storage.HQ_counts[entity.unit_number] or 1
    return tostring(id .. " " .. entity.name)
end

function update_tag_ids()
    if not storage.HQ then 
        return false
    end
    for i, hq in pairs(storage.HQ) do
        if not hq or not hq.entity or not hq.entity.valid or not hq.children_hq_ids then
            goto continue
        end
        for j, id in ipairs(hq.children_hq_ids) do
            local child_hq = storage.HQ[id]
            if not child_hq or not child_hq.entity or not child_hq.entity.valid then
                goto continue
            end
            child_hq.tag_id = (child_hq.entity.name == HQ_TYPES.COMPANY) and COMPANY_IDS[j] or UNIT_IDS[j]
            storage.HQ[id] = child_hq
        end
        ::continue::
    end
end

return M