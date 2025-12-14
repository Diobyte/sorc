local my_utility = require("my_utility/my_utility")

local menu_elements_fire_bolt =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "test_fire_bolt_main_boolean")),
    debug_mode          = checkbox:new(false, get_hash(my_utility.plugin_label .. "fire_bolt_debug_mode")),
    jmr_logic        = checkbox:new(true, get_hash(my_utility.plugin_label .. "test_fire_bolt_jmr_logic_boolean")),
    only_elite_or_boss        = checkbox:new(true, get_hash(my_utility.plugin_label .. "test_fire_bolt_only_elite_or_boss_boolean")),
}

local function menu()
    
    if menu_elements_fire_bolt.tree_tab:push("Fire Bolt")then
        menu_elements_fire_bolt.main_boolean:render("Enable Spell", "")
        menu_elements_fire_bolt.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        menu_elements_fire_bolt.jmr_logic:render("Enable JMR Logic", "")
        menu_elements_fire_bolt.only_elite_or_boss:render("Only Elite or Boss", "")
 
        menu_elements_fire_bolt.tree_tab:pop()
    end
end

local spell_id_fire_bolt = 153249;

local fire_bolt_spell_data = spell_data:new(
    0.7,                        -- radius
    20.0,                        -- range
    0.0,                        -- cast_delay
    4.0,                        -- projectile_speed
    true,                      -- has_collision
    spell_id_fire_bolt,           -- spell_id
    spell_geometry.rectangular, -- geometry_type
    targeting_type.skillshot    --targeting_type
)
local next_time_allowed_cast = 0.0;
local function logics(best_target, target_selector_data)
    
    local menu_boolean = menu_elements_fire_bolt.main_boolean:get();
    local debug_enabled = menu_elements_fire_bolt.debug_mode:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_fire_bolt);

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[FIRE BOLT DEBUG] Logic not allowed - spell conditions not met")
        end
        return false, 0;
    end;
    
    if not best_target then
        if debug_enabled then
            console.print("[FIRE BOLT DEBUG] No target provided")
        end
        return false, 0;
    end;

    if  menu_elements_fire_bolt.only_elite_or_boss:get() then
        local is_valid_target = best_target:is_boss() or best_target:is_elite() or best_target:is_champion()
        
        if debug_enabled then
            console.print("[FIRE BOLT DEBUG] Elite/Boss only mode - Target valid: " .. (is_valid_target and "Yes" or "No"))
        end
        
        if not is_valid_target then
            return false, 0;
        end
    end
    
    local player_position = get_player_position();
    local target_position = best_target:get_position();
    local is_collision = prediction.is_wall_collision(player_position, target_position, 0.2)
    
    if debug_enabled then
        console.print("[FIRE BOLT DEBUG] Wall collision check: " .. (is_collision and "Blocked" or "Clear"))
    end
    
    if is_collision then
        return false, 0
    end

    if debug_enabled then
        console.print("[FIRE BOLT DEBUG] Attempting cast on target")
    end

    if cast_spell.target(best_target, fire_bolt_spell_data, false) then

        local current_time = get_time_since_inject();
        local cooldown = 0.0;
        next_time_allowed_cast = current_time + cooldown;

        if debug_enabled then
            console.print("[FIRE BOLT DEBUG] Cast successful")
        end
        return true, cooldown;
    end;

    if debug_enabled then
        console.print("[FIRE BOLT DEBUG] Cast failed")
    end
    return false, 0;
end


return
{
    menu = menu,
    logics = logics,
    menu_elements_fire_bolt = menu_elements_fire_bolt,
}