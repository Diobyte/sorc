local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 0.0  -- Self-cast
local targeting_type = "self"
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "teleport_ench_main_boolean")),
    debug_mode          = checkbox:new(false, get_hash(my_utility.plugin_label .. "teleport_ench_debug_mode"))
}

local function menu()
    
    if menu_elements.tree_tab:push("Teleport Ench")then
        menu_elements.main_boolean:render("Enable Teleport Ench", "Enhanced teleport spell")
        menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
 
        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0.0;
local function logics(target)
    
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_data.teleport_ench.spell_id);

    if not is_logic_allowed then
        return false;
    end;
    
    local debug_enabled = menu_elements.debug_mode:get();
    if debug_enabled then
        console.print("[SPELL DEBUG] Teleport Ench - Casting");
    end

    if cast_spell.self(spell_data.teleport_ench.spell_id, 0.0) then

        local current_time = get_time_since_inject();
        local cooldown = my_utility.spell_delays.regular_cast;
        next_time_allowed_cast = current_time + cooldown;
        if debug_enabled then
            console.print("[SPELL DEBUG] Teleport Ench - Cast successful");
        end
        return true;
    end;

    return false;
end


return 
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    targeting_type = "self"
}
