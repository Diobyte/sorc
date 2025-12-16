local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")
local my_target_selector = require("my_utility/my_target_selector")

local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "teleport_main_bool_base")),
    debug_mode          = checkbox:new(false, get_hash(my_utility.plugin_label .. "teleport_debug_mode")),
    
    teleport_on_self    = checkbox:new(false, get_hash(my_utility.plugin_label .. "teleport_on_self_base")),
    priority_target     = checkbox:new(false, get_hash(my_utility.plugin_label .. "teleport_priority_target_bool")),
    cast_at_cursor      = checkbox:new(false, get_hash(my_utility.plugin_label .. "teleport_cast_at_cursor")),
    
    min_hits            = slider_int:new(1, 20, 6, get_hash(my_utility.plugin_label .. "min_hits_to_cast_base_tp")),
}

local function menu()
    if menu_elements.tree_tab:push("Teleport") then
        menu_elements.main_boolean:render("Enable Teleport", "Teleport to target location")
        menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")

        if menu_elements.main_boolean:get() then
            -- Mutual exclusivity logic
            local prev_self = menu_elements.teleport_on_self:get()
            local prev_priority = menu_elements.priority_target:get()
            local prev_cursor = menu_elements.cast_at_cursor:get()

            local self_clicked = menu_elements.teleport_on_self:render("Cast on Self", "Casts Teleport at where you stand")
            local priority_clicked = menu_elements.priority_target:render("Cast on Priority Target", "Targets Boss > Champion > Elite > Any")
            local cursor_clicked = menu_elements.cast_at_cursor:render("Cast at Cursor Position", "Casts Teleport at cursor position")

            local curr_self = menu_elements.teleport_on_self:get()
            local curr_priority = menu_elements.priority_target:get()
            local curr_cursor = menu_elements.cast_at_cursor:get()

            if (not prev_self and curr_self) or (self_clicked and not prev_self) then
                menu_elements.priority_target:set(false)
                menu_elements.cast_at_cursor:set(false)
            elseif (not prev_priority and curr_priority) or (priority_clicked and not prev_priority) then
                menu_elements.teleport_on_self:set(false)
                menu_elements.cast_at_cursor:set(false)
            elseif (not prev_cursor and curr_cursor) or (cursor_clicked and not prev_cursor) then
                menu_elements.teleport_on_self:set(false)
                menu_elements.priority_target:set(false)
            end
            
            menu_elements.min_hits:render("Min Hits", "Minimum enemies to cast (Default logic only)")
        end

        menu_elements.tree_tab:pop()
    end
end

local spell_id_tp = spell_data.teleport.spell_id
local next_time_allowed_cast = 0.0

local function get_priority_target(target_selector_data)
    if not target_selector_data then return nil, "none" end
    if target_selector_data.has_boss then return target_selector_data.closest_boss, "Boss" end
    if target_selector_data.has_champion then return target_selector_data.closest_champion, "Champion" end
    if target_selector_data.has_elite then return target_selector_data.closest_elite, "Elite" end
    if target_selector_data.closest_unit then return target_selector_data.closest_unit, "Regular" end
    return nil, "none"
end

local function logics(target)
    local menu_boolean = menu_elements.main_boolean:get()
    local debug_enabled = menu_elements.debug_mode:get()
    
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_id_tp
    )

    if not is_logic_allowed then return false end

    local local_player = get_local_player()
    if not local_player then return false end

    -- Cast at Cursor
    if menu_elements.cast_at_cursor:get() then
        local cursor_position = get_cursor_position()
        if cast_spell.position(spell_id_tp, cursor_position, 0.3) then
            next_time_allowed_cast = get_time_since_inject() + 0.5
            if debug_enabled then console.print("Teleport: Cursor Cast") end
            return true, 0.5
        end
        return false, 0
    end

    -- Cast on Self
    if menu_elements.teleport_on_self:get() then
        if cast_spell.self(spell_id_tp, 0.0) then
            next_time_allowed_cast = get_time_since_inject() + 0.5
            if debug_enabled then console.print("Teleport: Self Cast") end
            return true, 0.5
        end
        return false, 0
    end

    -- Priority Target
    if menu_elements.priority_target:get() then
        local target_selector_data = my_target_selector.get_target_selector_data(get_player_position(), my_utility.get_enemies_in_range(20))
        local best_target, type = get_priority_target(target_selector_data)
        if best_target then
            if cast_spell.position(spell_id_tp, best_target:get_position(), 0.3) then
                next_time_allowed_cast = get_time_since_inject() + 0.5
                if debug_enabled then console.print("Teleport: Priority Cast (" .. type .. ")") end
                return true, 0.5
            end
        end
        return false, 0
    end

    -- Default Logic (Min Hits)
    if target then
        local player_pos = get_player_position()
        local count = my_utility.enemy_count_in_range(target:get_position(), 4.0) -- Teleport impact radius approx
        if count >= menu_elements.min_hits:get() then
             if cast_spell.position(spell_id_tp, target:get_position(), 0.3) then
                next_time_allowed_cast = get_time_since_inject() + 0.5
                if debug_enabled then console.print("Teleport: Default Cast (Hits: " .. count .. ")") end
                return true, 0.5
            end
        end
    end

    return false, 0
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    targeting_type = "ranged"
}

