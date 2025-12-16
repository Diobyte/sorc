local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = spell_data.charged_bolts.data.range
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "charged_bolts_main_bool_base")),
    targeting_mode      = combo_box:new(0, get_hash(my_utility.plugin_label .. "charged_bolts_targeting_mode")),
    min_target_range    = slider_float:new(1.0, 20.0, 5.0, get_hash(my_utility.plugin_label .. "charged_bolts_min_target_range")),
    debug_mode          = checkbox:new(false, get_hash(my_utility.plugin_label .. "charged_bolts_debug_mode"))
}

local function menu()
    
    if menu_elements.tree_tab:push("Charged Bolt")then
        menu_elements.main_boolean:render("Enable Charged Bolt", "Charged lightning projectile")
        menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_ranged, my_utility.targeting_mode_description)
            menu_elements.min_target_range:render("Min Target Range", "", 1)
        end
 
        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0.0;
local function logics(target)
    
    local menu_boolean = menu_elements.main_boolean:get();
    local debug_enabled = menu_elements.debug_mode:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_data.charged_bolts.spell_id);

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[CHARGED BOLTS DEBUG] Logic not allowed - spell conditions not met")
        end
        return false;
    end;
    
    if not target then
        if debug_enabled then
            console.print("[CHARGED BOLTS DEBUG] No target")
        end
        return false;
    end;

    if not my_utility.is_in_range(target, max_spell_range) or my_utility.is_in_range(target, menu_elements.min_target_range:get()) then
        if debug_enabled then
            console.print("[CHARGED BOLTS DEBUG] Target out of range")
        end
        return false
    end

    if cast_spell.target(target, spell_data.charged_bolts.spell_id, 0) then

        local current_time = get_time_since_inject();
        local cooldown = my_utility.spell_delays.regular_cast;
        next_time_allowed_cast = current_time + cooldown;

        if debug_enabled then
            console.print("Cast Charged Bolts - Target: " .. my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1]);
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
    targeting_type = "ranged"
}
