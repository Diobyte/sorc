local my_utility = require("my_utility/my_utility");

local menu_elements_meteor = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_meteor")),
    debug_mode            = checkbox:new(false, get_hash(my_utility.plugin_label .. "meteor_debug_mode")),
}

local function menu()
    
    if menu_elements_meteor.tree_tab:push("Meteor")then
        menu_elements_meteor.main_boolean:render("Enable Spell", "")
        menu_elements_meteor.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
 
        menu_elements_meteor.tree_tab:pop()
    end
end

local spell_id_meteor = 296998
local next_time_allowed_cast = 0.0;

local function logics(best_target, target_selector_data)
    
    local menu_boolean = menu_elements_meteor.main_boolean:get();
    local debug_enabled = menu_elements_meteor.debug_mode:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_meteor);

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[METEOR DEBUG] Logic not allowed - spell conditions not met")
        end
        return false;
    end;
    
    if not best_target then
        if debug_enabled then
            console.print("[METEOR DEBUG] No target provided")
        end
        return false;
    end;

    local target_position = best_target:get_position();

    if debug_enabled then
        console.print("[METEOR DEBUG] Attempting cast at target position")
    end

    if cast_spell.position(spell_id_meteor, target_position, 0.35) then
        local current_time = get_time_since_inject();
        local cooldown = 1.0;
        next_time_allowed_cast = current_time + cooldown;
        
        if debug_enabled then
            console.print("[METEOR DEBUG] Cast successful")
        end
        return true, cooldown;
    end

    if debug_enabled then
        console.print("[METEOR DEBUG] Cast failed")
    end
    return false;

end

return 
{
    menu = menu,
    logics = logics,   
}