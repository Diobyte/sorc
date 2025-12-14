local my_utility = require("my_utility/my_utility");

local menu_elements_sorc_lash_base = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_arc_lash")),
    debug_mode            = checkbox:new(false, get_hash(my_utility.plugin_label .. "arc_lash_debug_mode")),
}

local function menu()
    
    if menu_elements_sorc_lash_base.tree_tab:push("Arc Lash") then
        menu_elements_sorc_lash_base.main_boolean:render("Enable Spell", "")
        menu_elements_sorc_lash_base.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
 
        menu_elements_sorc_lash_base.tree_tab:pop()
    end
end

local local_player = get_local_player();
if local_player == nil then
    return
end

local spell_id_arc_lash = 297902
local arc_lash_data = spell_data:new(
    2.0,                              -- radius
    3.0,                            -- range
    0.8,                            -- cast_delay
    1.2,                            -- projectile_speed
    true,                          -- has_collision
    spell_id_arc_lash,              -- spell_id
    spell_geometry.circular,        -- geometry_type
    targeting_type.skillshot        --targeting_type
)
local next_time_allowed_cast = 0.0;
local function logics(best_target, target_selector_data)
    
    local menu_boolean = menu_elements_sorc_lash_base.main_boolean:get();
    local debug_enabled = menu_elements_sorc_lash_base.debug_mode:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast,
                spell_id_arc_lash);

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[ARC LASH DEBUG] Logic not allowed - spell conditions not met")
        end
        return false, 0;
    end;
    
    if not best_target then
        if debug_enabled then
            console.print("[ARC LASH DEBUG] No target provided")
        end
        return false, 0;
    end;

    if debug_enabled then
        console.print("[ARC LASH DEBUG] Attempting cast on target")
    end

    if cast_spell.target(best_target, arc_lash_data, false) then
        local current_time = get_time_since_inject();
        local cooldown = 0.4;
        next_time_allowed_cast = current_time + cooldown;

        if debug_enabled then
            console.print("[ARC LASH DEBUG] Cast successful")
        end
        return true, cooldown;
    end;

    if debug_enabled then
        console.print("[ARC LASH DEBUG] Cast failed")
    end
    return false, 0;
end

return
{
    menu = menu,
    logics = logics,
}