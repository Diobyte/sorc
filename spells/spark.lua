local my_utility = require("my_utility/my_utility")

local spark_menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "spark_main_boolean")),
    debug_mode          = checkbox:new(false, get_hash(my_utility.plugin_label .. "spark_debug_mode")),
}

local function menu()
    
    if spark_menu_elements.tree_tab:push("Spark")then
        spark_menu_elements.main_boolean:render("Enable Spell", "")
        spark_menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
 
        spark_menu_elements.tree_tab:pop()
    end
end

local spell_id_spark = 143483;

local spark_spell_data = spell_data:new(
    0.7,                        -- radius
    10.0,                        -- range
    1.0,                        -- cast_delay
    3.5,                        -- projectile_speed
    false,                      -- has_collision
    spell_id_spark,             -- spell_id
    spell_geometry.rectangular, -- geometry_type
    targeting_type.skillshot    --targeting_type
)
local next_time_allowed_cast = 0.0;
local function logics(best_target, target_selector_data)
    
    local menu_boolean = spark_menu_elements.main_boolean:get();
    local debug_enabled = spark_menu_elements.debug_mode:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_spark);

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[SPARK DEBUG] Logic not allowed - spell conditions not met")
        end
        return false, 0;
    end;
    
    if not best_target then
        if debug_enabled then
            console.print("[SPARK DEBUG] No target provided")
        end
        return false, 0;
    end;

    local player_local = get_local_player();
    
    if debug_enabled then
        console.print("[SPARK DEBUG] Attempting cast on target")
    end

    if cast_spell.target(best_target, spark_spell_data, false) then

        local current_time = get_time_since_inject();
        local cooldown = 0.6;
        next_time_allowed_cast = current_time + cooldown;

        if debug_enabled then
            console.print("[SPARK DEBUG] Cast successful")
        end
        return true, cooldown;
    end;

    if debug_enabled then
        console.print("[SPARK DEBUG] Cast failed")
    end
    return false, 0;
end


return 
{
    menu = menu,
    logics = logics,   
}