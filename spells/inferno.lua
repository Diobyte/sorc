local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")
local my_target_selector = require("my_utility/my_target_selector")

local max_spell_range = 0.0  -- Self-cast AoE
local targeting_type = "ranged"  -- AoE spell, treat as ranged for targeting modes

local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "inferno_main_boolean")),
    debug_mode          = checkbox:new(false, get_hash(my_utility.plugin_label .. "inferno_debug_mode")),
    targeting_mode      = combo_box:new(0, get_hash(my_utility.plugin_label .. "inferno_targeting_mode")),
    
    min_targets         = slider_int:new(1, 20, 5, get_hash(my_utility.plugin_label .. "min_targets_to_cast_inferno_base")),
    min_mana_percent    = slider_float:new(0.1, 1.0, 0.3, get_hash(my_utility.plugin_label .. "inferno_min_mana")),
    
    always_cast_on_priority = checkbox:new(false, get_hash(my_utility.plugin_label .. "always_cast_on_priority_inferno_base")),
    require_priority_target = checkbox:new(false, get_hash(my_utility.plugin_label .. "require_priority_target_inferno_base")),
}

local function menu()
    if menu_elements.tree_tab:push("Inferno") then
        menu_elements.main_boolean:render("Enable Inferno", "AoE fire spell that damages enemies in area")
        menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_ranged, my_utility.targeting_mode_description)
            
            local prev_always = menu_elements.always_cast_on_priority:get()
            local prev_require = menu_elements.require_priority_target:get()
            
            local always_clicked = menu_elements.always_cast_on_priority:render("Always Cast On Priority", "Instantly casts on a priority target, ignoring the minimum target count")
            local require_clicked = menu_elements.require_priority_target:render("Require Priority Target", "Only casts if a priority target is present AND the minimum target count is met")
            
            local curr_always = menu_elements.always_cast_on_priority:get()
            local curr_require = menu_elements.require_priority_target:get()
            
            if (not prev_always and curr_always) or (always_clicked and not prev_always) then
                menu_elements.require_priority_target:set(false)
            elseif (not prev_require and curr_require) or (require_clicked and not prev_require) then
                menu_elements.always_cast_on_priority:set(false)
            end
            
            menu_elements.min_targets:render("Min Targets", "Minimum enemies to cast")
            menu_elements.min_mana_percent:render("Min Mana Percent", "Minimum mana percentage to cast", 1)
        end
        
        menu_elements.tree_tab:pop()
    end
end

local spell_id_inferno = spell_data.inferno.spell_id
local next_time_allowed_cast = 0.0

local function logics(target)
    local menu_boolean = menu_elements.main_boolean:get()
    local debug_enabled = menu_elements.debug_mode:get()
    
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_id_inferno
    )

    if not is_logic_allowed then return false end

    -- Mana check
    local local_player = get_local_player()
    local mana_pct = local_player:get_primary_resource_current() / local_player:get_primary_resource_max()
    if mana_pct < menu_elements.min_mana_percent:get() then
        if debug_enabled then
            console.print("[INFERNO DEBUG] Insufficient mana: " .. string.format("%.1f", mana_pct * 100) .. "%")
        end
        return false, 0
    end

    local player_position = get_player_position()
    local radius = spell_data.inferno.data.radius
    local area_data = target_selector.get_most_hits_circular_area_light(player_position, radius, radius, false)
    local total_hits = area_data.n_hits
    
    local has_priority = false
    if area_data.main_target then
        local main_target = area_data.main_target
        if main_target:is_elite() or main_target:is_champion() or main_target:is_boss() then
            has_priority = true
        end
    end
    
    local can_cast = false
    
    if menu_elements.always_cast_on_priority:get() then
        if has_priority then
            can_cast = true
            if debug_enabled then console.print("Inferno: Priority Found (Always Cast)") end
        elseif total_hits >= menu_elements.min_targets:get() then
            can_cast = true
            if debug_enabled then console.print("Inferno: Min Targets Met") end
        end
    elseif menu_elements.require_priority_target:get() then
        if has_priority and total_hits >= menu_elements.min_targets:get() then
            can_cast = true
            if debug_enabled then console.print("Inferno: Priority + Min Targets Met") end
        end
    else
        if total_hits >= menu_elements.min_targets:get() then
            can_cast = true
            if debug_enabled then console.print("Inferno: Min Targets Met") end
        end
    end

    if can_cast then
        if cast_spell.self(spell_id_inferno, 0.0) then
            next_time_allowed_cast = get_time_since_inject() + 0.5
            return true, 0.5
        end
    end

    return false, 0
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    targeting_type = targeting_type
}