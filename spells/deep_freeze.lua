local my_utility = require("my_utility/my_utility")

local menu_elements_deep_freeze = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_deep_freeze")),
    debug_mode            = checkbox:new(false, get_hash(my_utility.plugin_label .. "deep_freeze_debug_mode")),
    min_max_targets       = slider_int:new(0, 30, 5, get_hash(my_utility.plugin_label .. "min_max_number_of_targets_for_cast"))
}

local function menu()
    
    if menu_elements_deep_freeze.tree_tab:push("Deep Freeze") then
        menu_elements_deep_freeze.main_boolean:render("Enable Spell", "")
        menu_elements_deep_freeze.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")

        if menu_elements_deep_freeze.main_boolean:get() then
            menu_elements_deep_freeze.min_max_targets:render("Min Enemies Around", "Amount of targets to cast the spell")
        end

        menu_elements_deep_freeze.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0.0;
local spell_id_deep_freeze = 291827;
local function logics()

    local menu_boolean = menu_elements_deep_freeze.main_boolean:get();
    local debug_enabled = menu_elements_deep_freeze.debug_mode:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_deep_freeze);

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[DEEP FREEZE DEBUG] Logic not allowed - spell conditions not met")
        end
        return false;
    end;

    local area_data = target_selector.get_most_hits_target_circular_area_light(get_player_position(), 5.5, 5.5, false)
    local units = area_data.n_hits

    if debug_enabled then
        console.print("[DEEP FREEZE DEBUG] Enemies in area: " .. units .. " | Required: " .. menu_elements_deep_freeze.min_max_targets:get())
    end

    if units < menu_elements_deep_freeze.min_max_targets:get() then
        if debug_enabled then
            console.print("[DEEP FREEZE DEBUG] Not enough enemies - not casting")
        end
        return false;
    end;

    if debug_enabled then
        console.print("[DEEP FREEZE DEBUG] Attempting cast")
    end

    if cast_spell.self(spell_id_deep_freeze, 0.0) then
        
        local current_time = get_time_since_inject();
        local cooldown = 4.0;
        next_time_allowed_cast = current_time + cooldown;
        
        if debug_enabled then
            console.print("[DEEP FREEZE DEBUG] Cast successful")
        end
        return true, cooldown;
    end;

    if debug_enabled then
        console.print("[DEEP FREEZE DEBUG] Cast failed")
    end
    return false;
end

return 
{
    menu = menu,
    logics = logics,   
}