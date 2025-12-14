local my_utility = require("my_utility/my_utility");

local menu_elements_spear_base = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_lightning_spear")),
    debug_mode            = checkbox:new(false, get_hash(my_utility.plugin_label .. "spear_debug_mode")),
}

local function menu()
    
    if menu_elements_spear_base.tree_tab:push("Lightning Spear") then
        menu_elements_spear_base.main_boolean:render("Enable Spell", "")
        menu_elements_spear_base.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
 
        menu_elements_spear_base.tree_tab:pop()
    end
end

local spell_id_spear = 292074
local next_time_allowed_cast = 0.0;
local function logics(target)

    local menu_boolean = menu_elements_spear_base.main_boolean:get();
    local debug_enabled = menu_elements_spear_base.debug_mode:get();
    
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_spear);

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[SPEAR DEBUG] Logic not allowed - spell conditions not met")
        end
        return false, 0;
    end;

    if not target then
        if debug_enabled then
            console.print("[SPEAR DEBUG] No target provided")
        end
        return false, 0;
    end

    local target_position = target:get_position();

    if cast_spell.position(spell_id_spear, target_position, 0.1) then
        local current_time = get_time_since_inject();
        local cooldown = 0.1;
        next_time_allowed_cast = current_time + cooldown;
        
        if debug_enabled then
            console.print("[SPEAR DEBUG] Cast successful")
        end
        
        return true, cooldown;
    end

    if debug_enabled then
        console.print("[SPEAR DEBUG] Cast failed")
    end
    return false, 0;

end

return 
{
    menu = menu,
    logics = logics,
}