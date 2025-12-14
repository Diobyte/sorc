local my_utility = require("my_utility/my_utility");

local menu_elements_firewall = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_firwall")),
    debug_mode            = checkbox:new(false, get_hash(my_utility.plugin_label .. "firewall_debug_mode")),
}

local function menu()
    
    if menu_elements_firewall.tree_tab:push("Firewall")then
        menu_elements_firewall.main_boolean:render("Enable Spell", "")
        menu_elements_firewall.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
 
        menu_elements_firewall.tree_tab:pop()
    end
end

local spell_id_firewall = 111422
local next_time_allowed_cast = 0.0;

local function logics(target)
    
    local menu_boolean = menu_elements_firewall.main_boolean:get();
    local debug_enabled = menu_elements_firewall.debug_mode:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_firewall);

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[FIREWALL DEBUG] Logic not allowed - spell conditions not met")
        end
        return false, 0;
    end;

    if not target then
        if debug_enabled then
            console.print("[FIREWALL DEBUG] No target provided")
        end
        return false, 0;
    end;

    local target_position = target:get_position();

    if debug_enabled then
        console.print("[FIREWALL DEBUG] Attempting cast at target position")
    end

    if cast_spell.position(spell_id_firewall, target_position, 0.35) then
        local current_time = get_time_since_inject();
        local cooldown = 0.1;
        next_time_allowed_cast = current_time + cooldown;
        
        if debug_enabled then
            console.print("[FIREWALL DEBUG] Cast successful")
        end
        return true, cooldown;
    end

    if debug_enabled then
        console.print("[FIREWALL DEBUG] Cast failed")
    end
    return false, 0;

end

return 
{
    menu = menu,
    logics = logics,   
}