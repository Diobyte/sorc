local my_utility = require("my_utility/my_utility")

local frozen_orb_menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "spark_main_boolean")),
    debug_mode          = checkbox:new(false, get_hash(my_utility.plugin_label .. "frozen_orb_debug_mode")),
}

local function menu()
    
    if frozen_orb_menu_elements.tree_tab:push("Frozen Orb")then
        frozen_orb_menu_elements.main_boolean:render("Enable Spell", "")
        frozen_orb_menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
 
        frozen_orb_menu_elements.tree_tab:pop()
    end
end

local spell_id_fozen_orb = 291347;

local frozen_orb_data = spell_data:new(
    1.5,                        -- radius
    2.0,                        -- range
    1.0,                        -- cast_delay
    2.5,                        -- projectile_speed
    false,                      -- has_collision
    spell_id_fozen_orb,             -- spell_id
    spell_geometry.circular, -- geometry_type
    targeting_type.skillshot    --targeting_type
)
local next_time_allowed_cast = 0.0;
local function logics(best_target, target_selector_data)

    local debug_enabled = frozen_orb_menu_elements.debug_mode:get();

    if  utility.is_spell_ready(292074) then
        if debug_enabled then
            console.print("[FROZEN ORB DEBUG] Spell 292074 is ready - not casting")
        end
        return false, 0;
    end;
	
    local menu_boolean = frozen_orb_menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_fozen_orb);

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[FROZEN ORB DEBUG] Logic not allowed - spell conditions not met")
        end
        return false, 0;
    end;

    if not best_target then
        if debug_enabled then
            console.print("[FROZEN ORB DEBUG] No target provided")
        end
        return false, 0;
    end;

    local player_local = get_local_player();
    
    local player_position = get_player_position();
    local target_position = best_target:get_position();

    if debug_enabled then
        console.print("[FROZEN ORB DEBUG] Attempting cast on target")
    end

    if cast_spell.target(best_target, frozen_orb_data, false) then

        local current_time = get_time_since_inject();
        local cooldown = 0.8;
        next_time_allowed_cast = current_time + cooldown;

        if debug_enabled then
            console.print("[FROZEN ORB DEBUG] Cast successful")
        end
        return true, cooldown;
    end;

    if debug_enabled then
        console.print("[FROZEN ORB DEBUG] Cast failed")
    end
    return false, 0;
end


return 
{
    menu = menu,
    logics = logics,   
}