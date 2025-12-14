local my_utility = require("my_utility/my_utility")

local fireball_menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "fire_ball_main_boolean")),
    debug_mode          = checkbox:new(false, get_hash(my_utility.plugin_label .. "fireball_debug_mode")),
    -- Priority Targeting feature
    priority_target     = checkbox:new(false, get_hash(my_utility.plugin_label .. "fireball_priority_target_bool"))
}

local function menu()
    if fireball_menu_elements.tree_tab:push("Fireball") then
        fireball_menu_elements.main_boolean:render("Enable Spell", "")
        fireball_menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        
        if fireball_menu_elements.main_boolean:get() then
            -- Render priority targeting checkbox
            fireball_menu_elements.priority_target:render("Priority Targeting (Ignore weighted targeting)", "Targets Boss > Champion > Elite > Any")
        end
        
        fireball_menu_elements.tree_tab:pop()
    end
end

local spell_id_fireball = 165023;

local fireball_spell_data = spell_data:new(
    0.7,                        -- radius
    12.0,                        -- range
    1.6,                        -- cast_delay
    2.0,                        -- projectile_speed
    true,                      -- has_collision
    spell_id_fireball,           -- spell_id
    spell_geometry.rectangular, -- geometry_type
    targeting_type.skillshot    --targeting_type
)
local next_time_allowed_cast = 0.0;

-- Function to get the best target based on priority (Boss > Champion > Elite > Any)
local function get_priority_target(target_selector_data)
    local best_target = nil
    local target_type = "none"
    
    -- Check for boss targets first (highest priority)
    if target_selector_data and target_selector_data.has_boss then
        best_target = target_selector_data.closest_boss
        target_type = "Boss"
        return best_target, target_type
    end
    
    -- Then check for champion targets
    if target_selector_data and target_selector_data.has_champion then
        best_target = target_selector_data.closest_champion
        target_type = "Champion"
        return best_target, target_type
    end
    
    -- Then check for elite targets
    if target_selector_data and target_selector_data.has_elite then
        best_target = target_selector_data.closest_elite
        target_type = "Elite"
        return best_target, target_type
    end
    
    -- Finally, use any available target
    if target_selector_data and target_selector_data.closest_unit then
        best_target = target_selector_data.closest_unit
        target_type = "Regular"
        return best_target, target_type
    end
    
    return nil, "none"
end

local function logics(best_target, target_selector_data)
    local menu_boolean = fireball_menu_elements.main_boolean:get();
    local debug_enabled = fireball_menu_elements.debug_mode:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_fireball);
    if not is_logic_allowed then
        if debug_enabled then
            console.print("[FIREBALL DEBUG] Logic not allowed - spell conditions not met")
        end
        return false, 0;
    end;
    
    local current_time = get_time_since_inject();
    local player_local = get_local_player();
    local player_position = get_player_position();
    local cast_success = false;
    local target = nil;
    local target_type = "none";
    
    -- Check if spell is ready
    if not player_local:is_spell_ready(spell_id_fireball) then
        if debug_enabled then
            console.print("[FIREBALL DEBUG] Spell not ready")
        end
        return false, 0;
    end
    
    -- Check mana
    local current_mana = player_local:get_primary_resource_current()
    local max_mana = player_local:get_primary_resource_max()
    local mana_percentage = current_mana / max_mana
    
    if debug_enabled then
        console.print("[FIREBALL DEBUG] Mana: " .. string.format("%.1f", mana_percentage * 100) .. "% | Required: 80%")
    end
    
    if mana_percentage < 0.8 then
        if debug_enabled then
            console.print("[FIREBALL DEBUG] Insufficient mana - not casting")
        end
        return false, 0
    end
    
    -- Priority Targeting Mode: prioritize targets by type
    if fireball_menu_elements.priority_target:get() and target_selector_data then
        local priority_best_target, target_type = get_priority_target(target_selector_data)
        
        if debug_enabled then
            console.print("[FIREBALL DEBUG] Priority targeting mode - Target type: " .. target_type)
        end
        
        if priority_best_target then
            if cast_spell.target(priority_best_target, fireball_spell_data, false) then
                local current_time = get_time_since_inject()
                local cooldown = 0.1
                next_time_allowed_cast = current_time + cooldown
                if debug_enabled then
                    console.print("[FIREBALL DEBUG] Priority cast successful: " .. target_type)
                end
                return true, cooldown
            end
        else
            if debug_enabled then
                console.print("[FIREBALL DEBUG] No valid priority target found")
            end
        end
        
        return false, 0
    end
    
    -- Standard casting logic (if neither Execute nor Force Cast is active)
    if not best_target then
        if debug_enabled then
            console.print("[FIREBALL DEBUG] No target provided for standard casting")
        end
        return false;
    end
    
    local target = best_target;
    local target_position = target:get_position();
    local target_buffs = target:get_buffs()
    
    -- Check if target has FireBolt (153249: Sorcerer_FireBolt)
    local has_firebolt = false
    for _, buff in ipairs(target_buffs or {}) do
        if buff.name_hash == 153249 then
            has_firebolt = true
            break
        end
    end
    
    if debug_enabled then
        console.print("[FIREBALL DEBUG] Target has FireBolt buff: " .. (has_firebolt and "Yes" or "No"))
    end
    
    if has_firebolt and cast_spell.target(target, fireball_spell_data, false) then
        local cooldown = 0.1
        next_time_allowed_cast = current_time + cooldown;
        if debug_enabled then
            console.print("[FIREBALL DEBUG] Standard cast successful on target with FireBolt")
        end
        -- Don't return true for standard casting, allow rotation to continue
        -- This ensures standard fireball doesn't interrupt the casting flow
        return false, 0;
    end;
    
    if debug_enabled then
        console.print("[FIREBALL DEBUG] No casting conditions met")
    end
    return false, 0;
end


return 
{
    menu = menu,
    logics = logics,   
}