local my_utility = require("my_utility/my_utility");

local menu_elements_sorc_base = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_teleport_base")),
    debug_mode            = checkbox:new(false, get_hash(my_utility.plugin_label .. "teleport_debug_mode")),
   
    enable_teleport       = checkbox:new(false, get_hash(my_utility.plugin_label .. "enable_teleport_base")),
    keybind_ignore_hits   = checkbox:new(true, get_hash(my_utility.plugin_label .. "keybind_ignore_min_hits_base_tp")),
    
    min_hits              = slider_int:new(1, 20, 6, get_hash(my_utility.plugin_label .. "min_hits_to_cast_base_tp")),
    
    soft_score            = slider_float:new(2.0, 15.0, 6.0, get_hash(my_utility.plugin_label .. "min_percentage_hits_soft_core_tp")),
    
    teleport_on_self      = checkbox:new(false, get_hash(my_utility.plugin_label .. "teleport_on_self_base")),
    priority_target       = checkbox:new(false, get_hash(my_utility.plugin_label .. "teleport_priority_target_bool")),
    cast_at_cursor        = checkbox:new(false, get_hash(my_utility.plugin_label .. "teleport_cast_at_cursor")),
    
    short_range_tele      = checkbox:new(false, get_hash(my_utility.plugin_label .. "short_range_tele_base")),
    
    tele_gtfo             = checkbox:new(false, get_hash(my_utility.plugin_label .. "gtfo")),
    
    use_custom_cooldown   = checkbox:new(false, get_hash(my_utility.plugin_label .. "teleport_use_custom_cooldown")),
    internal_cooldown     = slider_float:new(0.1, 1.0, 0.5, get_hash(my_utility.plugin_label .. "teleport_internal_cooldown")),
}

local function menu()
    if menu_elements_sorc_base.tree_tab:push("Teleport") then
        menu_elements_sorc_base.main_boolean:render("Enable Spell", "");
        menu_elements_sorc_base.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        
        if menu_elements_sorc_base.main_boolean:get() then
            -- Track previous states before rendering
            local prev_self = menu_elements_sorc_base.teleport_on_self:get()
            local prev_priority = menu_elements_sorc_base.priority_target:get()
            local prev_cursor = menu_elements_sorc_base.cast_at_cursor:get()
            
            -- Render the checkboxes
            local self_clicked = menu_elements_sorc_base.teleport_on_self:render("Cast on Self", "Casts Teleport at where you stand")
            local priority_clicked = menu_elements_sorc_base.priority_target:render("Cast on Priority Target (Ignore weighted targeting)", "Targets Boss > Champion > Elite > Any")
            -- local cursor_clicked = menu_elements_sorc_base.cast_at_cursor:render("Cast at Cursor Position", "Casts Teleport at cursor position for fast dungeon navigation")
            local cursor_clicked = false
            
            -- Get current states after rendering
            local curr_self = menu_elements_sorc_base.teleport_on_self:get()
            local curr_priority = menu_elements_sorc_base.priority_target:get()
            local curr_cursor = menu_elements_sorc_base.cast_at_cursor:get()
            
            -- Check if any option was just enabled
            local self_just_enabled = not prev_self and curr_self
            local priority_just_enabled = not prev_priority and curr_priority
            local cursor_just_enabled = not prev_cursor and curr_cursor
            
            -- Handle mutual exclusivity between all three options
            if self_just_enabled then
                -- Cast on Self was just enabled, disable others
                menu_elements_sorc_base.priority_target:set(false)
                menu_elements_sorc_base.cast_at_cursor:set(false)
            elseif priority_just_enabled then
                -- Priority Target was just enabled, disable others
                menu_elements_sorc_base.teleport_on_self:set(false)
                menu_elements_sorc_base.cast_at_cursor:set(false)
            elseif cursor_just_enabled then
                -- Cast at Cursor was just enabled, disable others
                menu_elements_sorc_base.teleport_on_self:set(false)
                menu_elements_sorc_base.priority_target:set(false)
            end
            
            -- Additional check for when clicking directly on an already disabled option
            if self_clicked and not prev_self then
                menu_elements_sorc_base.teleport_on_self:set(true)
                menu_elements_sorc_base.priority_target:set(false)
                menu_elements_sorc_base.cast_at_cursor:set(false)
            elseif priority_clicked and not prev_priority then
                menu_elements_sorc_base.priority_target:set(true)
                menu_elements_sorc_base.teleport_on_self:set(false)
                menu_elements_sorc_base.cast_at_cursor:set(false)
            elseif cursor_clicked and not prev_cursor then
                menu_elements_sorc_base.cast_at_cursor:set(true)
                menu_elements_sorc_base.teleport_on_self:set(false)
                menu_elements_sorc_base.priority_target:set(false)
            end
            
            -- Final safety check to ensure only one option is enabled
            local active_count = 0
            if menu_elements_sorc_base.teleport_on_self:get() then active_count = active_count + 1 end
            if menu_elements_sorc_base.priority_target:get() then active_count = active_count + 1 end
            if menu_elements_sorc_base.cast_at_cursor:get() then active_count = active_count + 1 end
            
            if active_count > 1 then
                -- Multiple options enabled, keep only the most recently clicked
                if cursor_clicked then
                    menu_elements_sorc_base.teleport_on_self:set(false)
                    menu_elements_sorc_base.priority_target:set(false)
                elseif priority_clicked then
                    menu_elements_sorc_base.teleport_on_self:set(false)
                    menu_elements_sorc_base.cast_at_cursor:set(false)
                elseif self_clicked then
                    menu_elements_sorc_base.priority_target:set(false)
                    menu_elements_sorc_base.cast_at_cursor:set(false)
                end
            end
            
            menu_elements_sorc_base.short_range_tele:render("Short Range Tele", "Stop teleport to random hill ufak");
            menu_elements_sorc_base.tele_gtfo:render("Tele Gtfo", "Gtfo at <90hp");
            
            -- Custom Cooldown section
            menu_elements_sorc_base.use_custom_cooldown:render("Use Custom Cooldown", "Enable custom internal cooldown to control casting frequency")
            if menu_elements_sorc_base.use_custom_cooldown:get() then
                menu_elements_sorc_base.internal_cooldown:render("Internal Cooldown (seconds)", "Time to wait between teleport casts", 1)
            end
        end
        
        menu_elements_sorc_base.tree_tab:pop();
    end
end

local my_target_selector = require("my_utility/my_target_selector");

local spell_id_tp = 288106;

local spell_radius = 2.5;
local spell_max_range = 10.0;

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

local function logics(entity_list, target_selector_data, best_target)
    -- Make sure local_player is defined
    local local_player = get_local_player()
    if not local_player then
        return false
    end
    
    local menu_boolean = menu_elements_sorc_base.main_boolean:get();
    local debug_enabled = menu_elements_sorc_base.debug_mode:get();
    local priority_target = menu_elements_sorc_base.priority_target:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_tp);
                
    if not is_logic_allowed then
        if debug_enabled then
            console.print("[TELEPORT DEBUG] Logic not allowed - spell conditions not met")
        end
        return false;
    end

    if not local_player:is_spell_ready(spell_id_tp) then
        if debug_enabled then
            console.print("[TELEPORT DEBUG] Spell not ready")
        end
        return false;
    end

    local player_position = get_player_position();
    -- Default enable_teleport to true if no special modes are active
    local enable_teleport = menu_elements_sorc_base.enable_teleport:get() or 
                           (not menu_elements_sorc_base.teleport_on_self:get() and 
                            not menu_elements_sorc_base.priority_target:get() and
                            not menu_elements_sorc_base.cast_at_cursor:get() and
                            not menu_elements_sorc_base.tele_gtfo:get());
    
    -- Cast at Cursor Position (HIGHEST PRIORITY - checked first)
    if menu_elements_sorc_base.cast_at_cursor:get() then
        local cursor_position = get_cursor_position()
        
        if debug_enabled then
            console.print("[TELEPORT DEBUG] Casting at cursor position")
        end
        
        if cursor_position then
            -- Apply short range teleport setting if enabled
            if menu_elements_sorc_base.short_range_tele:get() then
                local cursor_distance = player_position:dist_to(cursor_position)
                if cursor_distance > 5.0 then
                    -- Calculate position 5 units towards cursor
                    local direction = (cursor_position - player_position):normalize()
                    cursor_position = player_position + direction * 5.0
                    if debug_enabled then
                        console.print("[TELEPORT DEBUG] Short range mode - limiting distance to 5.0")
                    end
                end
            end
            
            if cast_spell.position(spell_id_tp, cursor_position, 0.3) then
                local current_time = get_time_since_inject()
                
                -- Use custom cooldown if enabled, otherwise use default
                local internal_cooldown_time = 0.1
                if menu_elements_sorc_base.use_custom_cooldown:get() then
                    internal_cooldown_time = menu_elements_sorc_base.internal_cooldown:get()
                end
                
                next_time_allowed_cast = current_time + internal_cooldown_time;
                
                if debug_enabled then
                    console.print("[TELEPORT DEBUG] Cast at cursor successful")
                end
                return true, 0.1;
            end
        else
            if debug_enabled then
                console.print("[TELEPORT DEBUG] No cursor position available")
            end
        end
    -- Tele Gtfo Logic (SECOND PRIORITY)
    elseif menu_elements_sorc_base.tele_gtfo:get() then
        local current_health = local_player:get_current_health();
        local max_health = local_player:get_max_health();
        local health_percentage = current_health / max_health;

        if debug_enabled then
            console.print("[TELEPORT DEBUG] GTFO mode - Health: " .. string.format("%.1f", health_percentage * 100) .. "%")
        end

        if health_percentage < 0.90 then
            local safe_direction = vec3:new(1, 0, 0); -- Default safe direction
            local safe_distance = 10.0;  -- Distance Adjustments
            local safe_position = player_position + safe_direction * safe_distance;

            -- No utility module available, use the position as is
            -- We could potentially add a small height adjustment here if needed

            if cast_spell.position(spell_id_tp, safe_position, 0.3) then
                local current_time = get_time_since_inject()
                
                -- Use custom cooldown if enabled, otherwise use default
                local internal_cooldown_time = 0.1
                if menu_elements_sorc_base.use_custom_cooldown:get() then
                    internal_cooldown_time = menu_elements_sorc_base.internal_cooldown:get()
                end
                
                next_time_allowed_cast = current_time + internal_cooldown_time;
                
                if debug_enabled then
                    console.print("[TELEPORT DEBUG] GTFO cast successful")
                end
                return true, 0.1;
            end
        end
    -- Cast on Self (THIRD PRIORITY)
    elseif menu_elements_sorc_base.teleport_on_self:get() then
        if debug_enabled then
            console.print("[TELEPORT DEBUG] Casting on self")
        end
        if cast_spell.self(spell_id_tp, 0.3) then
            local current_time = get_time_since_inject()
            
            -- Use custom cooldown if enabled, otherwise use default
            local internal_cooldown_time = 0.1
            if menu_elements_sorc_base.use_custom_cooldown:get() then
                internal_cooldown_time = menu_elements_sorc_base.internal_cooldown:get()
            end
            
            next_time_allowed_cast = current_time + internal_cooldown_time;
            
            if debug_enabled then
                console.print("[TELEPORT DEBUG] Cast on self successful")
            end
            return true, 0.1;
        end
    -- Priority target mode (FOURTH PRIORITY)
    elseif menu_elements_sorc_base.priority_target:get() and target_selector_data then
        local best_target, target_type = get_priority_target(target_selector_data)
        
        if debug_enabled then
            console.print("[TELEPORT DEBUG] Priority target mode - Target type: " .. target_type)
        end
        
        if best_target then
            local target_position = best_target:get_position()
            if cast_spell.position(spell_id_tp, target_position, 0.3) then
                local current_time = get_time_since_inject()
                
                -- Use custom cooldown if enabled, otherwise use default
                local internal_cooldown_time = 0.1
                if menu_elements_sorc_base.use_custom_cooldown:get() then
                    internal_cooldown_time = menu_elements_sorc_base.internal_cooldown:get()
                end
                
                next_time_allowed_cast = current_time + internal_cooldown_time

                if debug_enabled then
                    console.print("[TELEPORT DEBUG] Priority target cast successful: " .. target_type)
                end
                return true, 0.1
            end
        else
            if debug_enabled then
                console.print("[TELEPORT DEBUG] No valid priority target found")
            end
        end
    -- Default targeting logic (LOWEST PRIORITY)
    else
        local keybind_ignore_hits = menu_elements_sorc_base.keybind_ignore_hits:get();
        local keybind_can_skip = keybind_ignore_hits and enable_teleport;

        local min_hits_menu = menu_elements_sorc_base.min_hits:get();

        -- Use my_target_selector for targeting instead of target_selector
        -- First check if we have a valid target from the passed parameters
        if not best_target then
            if debug_enabled then
                console.print("[TELEPORT DEBUG] No best target provided")
            end
            return false;
        end

        -- Use the best_target parameter that was passed to the function
        if not best_target:is_enemy() then
            if debug_enabled then
                console.print("[TELEPORT DEBUG] Target is not an enemy")
            end
            return false;
        end
        
        -- Check if target is relevant (elite, champion, or boss)
        local is_relevant_target = best_target:is_elite() or best_target:is_champion() or best_target:is_boss();
        
        if debug_enabled then
            console.print("[TELEPORT DEBUG] Target relevance: " .. (is_relevant_target and "Relevant" or "Not relevant") .. " | Can skip: " .. (keybind_can_skip and "Yes" or "No"))
        end
        
        -- Only proceed if target is relevant or keybind_can_skip is true
        if not is_relevant_target and not keybind_can_skip then
            if debug_enabled then
                console.print("[TELEPORT DEBUG] Target not relevant and cannot skip - not casting")
            end
            return false;
        end
        
        local cast_position = best_target:get_position();
        local cast_position_distance_sqr = cast_position:squared_dist_to_ignore_z(player_position);
        if cast_position_distance_sqr < 2.0 and not keybind_can_skip  then
            if debug_enabled then
                console.print("[TELEPORT DEBUG] Target too close - not casting")
            end
            return false;
        end

        if cast_spell.position(spell_id_tp, cast_position, 0.3) then
            local current_time = get_time_since_inject();
            
            -- Use custom cooldown if enabled, otherwise use default
            local internal_cooldown_time = 0.1
            if menu_elements_sorc_base.use_custom_cooldown:get() then
                internal_cooldown_time = menu_elements_sorc_base.internal_cooldown:get()
            end
            
            next_time_allowed_cast = current_time + internal_cooldown_time;

            if debug_enabled then
                console.print("[TELEPORT DEBUG] Cast successful on weighted target")
            end
            return true, 0.1;
        end

        if debug_enabled then
            console.print("[TELEPORT DEBUG] Cast failed")
        end
    end

    return false;

end

return 
{
    menu = menu,
    logics = logics,
    menu_elements_sorc_base = menu_elements_sorc_base,
}

