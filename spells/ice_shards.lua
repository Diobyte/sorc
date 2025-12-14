local my_utility = require("my_utility/my_utility")

local ice_shard_menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "fire_bolt_main_boolean")),
    debug_mode          = checkbox:new(false, get_hash(my_utility.plugin_label .. "ice_shards_debug_mode")),
}

local function menu()
    
    if ice_shard_menu_elements.tree_tab:push("Ice Shards")then
        ice_shard_menu_elements.main_boolean:render("Enable Spell", "")
        ice_shard_menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
 
        ice_shard_menu_elements.tree_tab:pop()
    end
end

local spell_id_ice_shards = 293195;

local ice_shards_spell_data = spell_data:new(
    0.7,                        -- radius
    8.0,                        -- range
    1.0,                        -- cast_delay
    1.0,                        -- projectile_speed
    true,                      -- has_collision
    spell_id_ice_shards,           -- spell_id
    spell_geometry.rectangular, -- geometry_type
    targeting_type.skillshot    --targeting_type
)
local next_time_allowed_cast = 0.0;
local function logics(best_target, target_selector_data)
    
    local menu_boolean = ice_shard_menu_elements.main_boolean:get();
    local debug_enabled = ice_shard_menu_elements.debug_mode:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_ice_shards);

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[ICE SHARDS DEBUG] Logic not allowed - spell conditions not met")
        end
        return false, 0;
    end;
    
    if not best_target then
        if debug_enabled then
            console.print("[ICE SHARDS DEBUG] No target provided")
        end
        return false, 0;
    end;

    local player_local = get_local_player();
    
    local player_position = get_player_position();
    local target_position = best_target:get_position();

    if debug_enabled then
        console.print("[ICE SHARDS DEBUG] Attempting cast on target")
    end

    if cast_spell.target(best_target, ice_shards_spell_data, false) then

        local current_time = get_time_since_inject();
        local cooldown = 0.1;
        next_time_allowed_cast = current_time + cooldown;

        if debug_enabled then
            console.print("[ICE SHARDS DEBUG] Cast successful")
        end
        return true, cooldown;
    end;

    if debug_enabled then
        console.print("[ICE SHARDS DEBUG] Cast failed")
    end
    return false, 0;
end


return 
{
    menu = menu,
    logics = logics,   
}