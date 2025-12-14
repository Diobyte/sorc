local my_utility = require("my_utility/my_utility")

local menu_elements_unstable_base = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_unstable_currents_base")),
    debug_mode            = checkbox:new(false, get_hash(my_utility.plugin_label .. "unstable_current_debug_mode")),
    min_max_targets       = slider_int:new(0, 30, 5, get_hash(my_utility.plugin_label .. "min_max_number_of_targets_for_cast_base"))
}

local function menu()
    
    if menu_elements_unstable_base.tree_tab:push("Unstable Current") then
        menu_elements_unstable_base.main_boolean:render("Enable Spell", "")
        menu_elements_unstable_base.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")

        if menu_elements_unstable_base.main_boolean:get() then
            menu_elements_unstable_base.min_max_targets:render("Min Enemies Around", "Amount of targets to cast the spell")
        end

        menu_elements_unstable_base.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0.0;
local spell_id_unstable_current = 517417
local function logics()

    local menu_boolean = menu_elements_unstable_base.main_boolean:get();
    local debug_enabled = menu_elements_unstable_base.debug_mode:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_unstable_current);

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[UNSTABLE CURRENT DEBUG] Logic not allowed - spell conditions not met")
        end
        return false, 0;
    end;
    
    local player_pos = get_player_position()
    local area_data = target_selector.get_most_hits_target_circular_area_light(player_pos, 9.0, 9.0, false)
    local units = area_data.n_hits
    local min_targets = menu_elements_unstable_base.min_max_targets:get()

    if debug_enabled then
        console.print("[UNSTABLE CURRENT DEBUG] Enemies in range: " .. units .. " | Required: " .. min_targets)
    end

    if units < min_targets then
        if debug_enabled then
            console.print("[UNSTABLE CURRENT DEBUG] Not enough enemies - skipping cast")
        end
        return false, 0;
    end;

    if cast_spell.self(spell_id_unstable_current, 0.0) then
        local current_time = get_time_since_inject();
        local cooldown = 0.2;
        next_time_allowed_cast = current_time + cooldown;
        if debug_enabled then
            console.print("[UNSTABLE CURRENT DEBUG] Cast successful with " .. units .. " enemies")
        end
        return true, cooldown;
    end;

    if debug_enabled then
        console.print("[UNSTABLE CURRENT DEBUG] Cast failed")
    end
    return false, 0;
end

return 
{
    menu = menu,
    logics = logics,   
}