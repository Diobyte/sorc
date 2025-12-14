local my_utility = require("my_utility/my_utility");

local menu_elements_familiars = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_familiars")),
    debug_mode            = checkbox:new(false, get_hash(my_utility.plugin_label .. "familiars_debug_mode")),
    use_custom_cooldown   = checkbox:new(true, get_hash(my_utility.plugin_label .. "familiars_use_custom_cooldown")),
    custom_cooldown_sec   = slider_float:new(1.0, 10.0, 3.0, get_hash(my_utility.plugin_label .. "familiars_custom_cooldown_sec")),
}

local function menu()
    
    if menu_elements_familiars.tree_tab:push("Familiars")then
        menu_elements_familiars.main_boolean:render("Enable Spell", "")
        menu_elements_familiars.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        menu_elements_familiars.use_custom_cooldown:render("Use Custom Cooldown", "Only cast every X seconds to prevent charge spam")
        if menu_elements_familiars.use_custom_cooldown:get() then
            menu_elements_familiars.custom_cooldown_sec:render("Cooldown (seconds)", "Time to wait between casts", 1)
        end
 
        menu_elements_familiars.tree_tab:pop()
    end
end

local spell_id_familiars = 1627075
local next_time_allowed_cast = 0.0;
local last_cast_time = 0.0;

local function logics(best_target, target_selector_data)
    local current_time = get_time_since_inject();
    local menu_boolean = menu_elements_familiars.main_boolean:get();
    local debug_enabled = menu_elements_familiars.debug_mode:get();
    
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_familiars);

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[FAMILIARS DEBUG] Logic not allowed - spell conditions not met")
        end
        return false, 0;
    end;

    -- Check custom cooldown to prevent charge spam
    if menu_elements_familiars.use_custom_cooldown:get() then
        local cooldown_time = menu_elements_familiars.custom_cooldown_sec:get();
        if current_time - last_cast_time < cooldown_time then
            if debug_enabled then
                console.print("[FAMILIARS DEBUG] Custom cooldown active - " .. string.format("%.1f", cooldown_time - (current_time - last_cast_time)) .. "s remaining");
            end
            return false, 0;
        end
    end;

    if not best_target then
        if debug_enabled then
            console.print("[FAMILIARS DEBUG] No target provided")
        end
        return false, 0;
    end;

    local target_position = best_target:get_position();

    if debug_enabled then
        console.print("[FAMILIARS DEBUG] Attempting cast at target position")
    end

    if cast_spell.position(spell_id_familiars, target_position, 0.1) then
        local cooldown = 0.1;
        next_time_allowed_cast = current_time + cooldown;
        last_cast_time = current_time;
        
        if debug_enabled then
            console.print("[FAMILIARS DEBUG] Cast successful")
        end
        return false, cooldown;
    end

    if debug_enabled then
        console.print("[FAMILIARS DEBUG] Cast failed")
    end
    return false, 0;

end

return 
{
    menu = menu,
    logics = logics,   
}