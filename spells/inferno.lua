local my_utility = require("my_utility/my_utility");

local menu_elements_inferno = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_inferno_base")),
    debug_mode            = checkbox:new(false, get_hash(my_utility.plugin_label .. "inferno_debug_mode")),
   
    inferno_mode         = combo_box:new(0, get_hash(my_utility.plugin_label .. "inferno_mode")),
    keybind               = keybind:new(0x01, false, get_hash(my_utility.plugin_label .. "inferno_keybind")),
    keybind_ignore_hits   = checkbox:new(true, get_hash(my_utility.plugin_label .. "keybind_ignore_min_hits_inferno_base")),

    min_targets           = slider_int:new(1, 20, 5, get_hash(my_utility.plugin_label .. "min_targets_to_cast_inferno_base")),
    
    require_priority_target = checkbox:new(false, get_hash(my_utility.plugin_label .. "require_priority_target_inferno_base")),    
    always_cast_on_priority = checkbox:new(false, get_hash(my_utility.plugin_label .. "always_cast_on_priority_inferno_base")),
    ignore_target_count_spam = checkbox:new(false, get_hash(my_utility.plugin_label .. "ignore_target_count_spam_inferno_base")),
}

local function menu()
    
    if menu_elements_inferno.tree_tab:push("Inferno") then
        menu_elements_inferno.main_boolean:render("Enable Spell", "");
        menu_elements_inferno.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")

        -- Track previous states before rendering for three-way mutual exclusivity
        local prev_always_cast = menu_elements_inferno.always_cast_on_priority:get()
        local prev_require_priority = menu_elements_inferno.require_priority_target:get()
        local prev_ignore_count_spam = menu_elements_inferno.ignore_target_count_spam:get()
        
        -- Render the mutually exclusive checkboxes (with Ignore Target Count and Spam first)
        local ignore_count_spam_clicked = menu_elements_inferno.ignore_target_count_spam:render("Ignore Target Count and Spam", "Casts on any single target using weighted targeting, ignoring target count requirements")
        local require_priority_clicked = menu_elements_inferno.require_priority_target:render("Require Priority Target", "Only casts if a priority target is present AND the minimum target count is met")
        local always_cast_clicked = menu_elements_inferno.always_cast_on_priority:render("Always Cast On Priority", "Instantly casts on a priority target, ignoring the minimum target count")

        -- Only show Min Targets slider if Ignore Target Count and Spam is disabled
        if not menu_elements_inferno.ignore_target_count_spam:get() then
            menu_elements_inferno.min_targets:render("Min Targets", "The minimum number of enemies required for a cast");
        end
        
        -- Get current states after rendering
        local curr_always_cast = menu_elements_inferno.always_cast_on_priority:get()
        local curr_require_priority = menu_elements_inferno.require_priority_target:get()
        local curr_ignore_count_spam = menu_elements_inferno.ignore_target_count_spam:get()
        
        -- Check if any option was just enabled
        local always_cast_just_enabled = not prev_always_cast and curr_always_cast
        local require_priority_just_enabled = not prev_require_priority and curr_require_priority
        local ignore_count_spam_just_enabled = not prev_ignore_count_spam and curr_ignore_count_spam
        
        -- Handle three-way mutual exclusivity
        if always_cast_just_enabled then
            -- Always Cast on Priority was just enabled, disable the other two
            menu_elements_inferno.require_priority_target:set(false)
            menu_elements_inferno.ignore_target_count_spam:set(false)
        elseif require_priority_just_enabled then
            -- Require Priority Target was just enabled, disable the other two
            menu_elements_inferno.always_cast_on_priority:set(false)
            menu_elements_inferno.ignore_target_count_spam:set(false)
        elseif ignore_count_spam_just_enabled then
            -- Ignore Target Count and Spam was just enabled, disable the other two
            menu_elements_inferno.always_cast_on_priority:set(false)
            menu_elements_inferno.require_priority_target:set(false)
        end
        
        -- Additional check for when clicking directly on an already disabled option
        if always_cast_clicked and not prev_always_cast then
            menu_elements_inferno.always_cast_on_priority:set(true)
            menu_elements_inferno.require_priority_target:set(false)
            menu_elements_inferno.ignore_target_count_spam:set(false)
        elseif require_priority_clicked and not prev_require_priority then
            menu_elements_inferno.require_priority_target:set(true)
            menu_elements_inferno.always_cast_on_priority:set(false)
            menu_elements_inferno.ignore_target_count_spam:set(false)
        elseif ignore_count_spam_clicked and not prev_ignore_count_spam then
            menu_elements_inferno.ignore_target_count_spam:set(true)
            menu_elements_inferno.always_cast_on_priority:set(false)
            menu_elements_inferno.require_priority_target:set(false)
        end
        
        -- Final safety check to ensure only one option is enabled
        local active_count = 0
        if menu_elements_inferno.always_cast_on_priority:get() then active_count = active_count + 1 end
        if menu_elements_inferno.require_priority_target:get() then active_count = active_count + 1 end
        if menu_elements_inferno.ignore_target_count_spam:get() then active_count = active_count + 1 end
        
        if active_count > 1 then
            -- Multiple options enabled, keep only the most recently clicked
            if ignore_count_spam_clicked then
                menu_elements_inferno.always_cast_on_priority:set(false)
                menu_elements_inferno.require_priority_target:set(false)
            elseif require_priority_clicked then
                menu_elements_inferno.always_cast_on_priority:set(false)
                menu_elements_inferno.ignore_target_count_spam:set(false)
            elseif always_cast_clicked then
                menu_elements_inferno.require_priority_target:set(false)
                menu_elements_inferno.ignore_target_count_spam:set(false)
            end
        end

        local options =  {"Auto", "Keybind"};
        menu_elements_inferno.inferno_mode:render("Mode", options, "");

        menu_elements_inferno.keybind:render("Keybind", "");
        menu_elements_inferno.keybind_ignore_hits:render("Keybind Ignores Min Targets", "");

        menu_elements_inferno.tree_tab:pop();
    end
end

local my_target_selector = require("my_utility/my_target_selector");

local spell_id_inferno = 294198;
local spell_radius = 2.0
local spell_max_range = 6.0

local next_time_allowed_cast = 0.0;
local function logics(entity_list, target_selector_data, best_target)

    local menu_boolean = menu_elements_inferno.main_boolean:get();
    local debug_enabled = menu_elements_inferno.debug_mode:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_inferno);
                
    if not is_logic_allowed then
        if debug_enabled then
            console.print("[INFERNO DEBUG] Logic not allowed - spell conditions not met")
        end
        return false;
    end;

    local player_position = get_player_position()
    local keybind_used = menu_elements_inferno.keybind:get_state();
    local inferno_mode = menu_elements_inferno.inferno_mode:get();
    
    if debug_enabled then
        console.print("[INFERNO DEBUG] Mode: " .. (inferno_mode == 0 and "Auto" or "Keybind"))
        console.print("[INFERNO DEBUG] Keybind state: " .. keybind_used)
    end
    
    if inferno_mode == 1 then
        if  keybind_used == 0 then   
            if debug_enabled then
                console.print("[INFERNO DEBUG] Keybind mode active but keybind not pressed")
            end
            return false;
        end;
    end;

    local keybind_ignore_hits = menu_elements_inferno.keybind_ignore_hits:get();
    local keybind_can_skip = keybind_ignore_hits == true and keybind_used > 0;
    
    -- Get configuration values for fast path check
    local min_targets_setting = menu_elements_inferno.min_targets:get()
    local always_cast_on_priority = menu_elements_inferno.always_cast_on_priority:get()
    local require_priority_target = menu_elements_inferno.require_priority_target:get()
    local ignore_target_count_spam = menu_elements_inferno.ignore_target_count_spam:get()
    
    -- FAST PATH: Use weighted targeting when "Ignore Target Count and Spam" is enabled
    if ignore_target_count_spam and best_target then
        if debug_enabled then
            console.print("[INFERNO DEBUG] Fast path activated - Ignore Target Count and Spam mode")
        end
        
        -- Validate the target
        if not best_target:is_enemy() then
            if debug_enabled then
                console.print("[INFERNO DEBUG] Fast path - target is not an enemy")
            end
            return false;
        end
        
        local cast_position = best_target:get_position();
        local cast_distance_sqr = cast_position:squared_dist_to_ignore_z(player_position);
        
        -- Check if target is within range (6.0 units)
        if cast_distance_sqr > (6.0 * 6.0) then
            if debug_enabled then
                console.print("[INFERNO DEBUG] Fast path - target out of range")
            end
            return false;
        end
        
        -- Cast directly on the weighted target
        if cast_spell.position(spell_id_inferno, cast_position, 0.3) then
            local current_time = get_time_since_inject();
            local cooldown = 0.1;
            next_time_allowed_cast = current_time + cooldown;
            if debug_enabled then
                console.print("[INFERNO DEBUG] Fast path cast successful - Ignore Target Count and Spam")
            end
            return true, cooldown;
        else
            if debug_enabled then
                console.print("[INFERNO DEBUG] Fast path cast failed")
            end
            return false;
        end
    end
    
    -- STANDARD PATH: Use area scanning for complex scenarios
    local spell_range = 6.0
    local spell_radius = 2.0
    local area_data = my_target_selector.get_most_hits_circular(player_position, spell_range, spell_radius)
    if not area_data.main_target then
        if debug_enabled then
            console.print("[INFERNO DEBUG] No main target found in area")
        end
        return false;
    end

    -- New intelligent casting logic
    local total_hits = area_data.hits_amount or 0
    -- Configuration variables already declared above for fast path
    
    -- Check if any priority targets are in the victim list
    local has_priority = false;
    for _, victim in ipairs(area_data.victim_list) do
        if victim:is_elite() or victim:is_champion() or victim:is_boss() then
            has_priority = true;
            break;
        end
    end

    if debug_enabled then
        console.print("[INFERNO DEBUG] Total hits: " .. total_hits .. " | Has priority: " .. (has_priority and "Yes" or "No"))
        console.print("[INFERNO DEBUG] Always cast on priority: " .. (always_cast_on_priority and "Yes" or "No") .. " | Require priority: " .. (require_priority_target and "Yes" or "No"))
    end

    -- The new decision engine
    local can_cast = false
    
    if always_cast_on_priority then
        -- Scenario 1: Always cast on priority targets, ignoring min targets
        if has_priority then
            can_cast = true
            if debug_enabled then
                console.print("[INFERNO DEBUG] Always cast mode - Priority target found, casting immediately")
            end
        else
            -- No priority target, fall back to normal min targets check for trash
            if total_hits >= min_targets_setting then
                can_cast = true
                if debug_enabled then
                    console.print("[INFERNO DEBUG] Always cast mode - No priority, but enough trash targets (" .. total_hits .. " >= " .. min_targets_setting .. ")")
                end
            else
                if debug_enabled then
                    console.print("[INFERNO DEBUG] Always cast mode - No priority and insufficient trash targets (" .. total_hits .. " < " .. min_targets_setting .. ")")
                end
            end
        end
    elseif require_priority_target then
        -- Scenario 2: Only cast if priority target is present AND min targets is met
        if has_priority and total_hits >= min_targets_setting then
            can_cast = true
            if debug_enabled then
                console.print("[INFERNO DEBUG] Require priority mode - Priority found and min targets met (" .. total_hits .. " >= " .. min_targets_setting .. ")")
            end
        else
            if debug_enabled then
                if not has_priority then
                    console.print("[INFERNO DEBUG] Require priority mode - No priority target found")
                else
                    console.print("[INFERNO DEBUG] Require priority mode - Priority found but insufficient targets (" .. total_hits .. " < " .. min_targets_setting .. ")")
                end
            end
        end
    else
        -- Scenario 3: Normal mode - cast if min targets is met (works for both trash and mixed groups)
        if total_hits >= min_targets_setting then
            can_cast = true
            if debug_enabled then
                console.print("[INFERNO DEBUG] Normal mode - Min targets met (" .. total_hits .. " >= " .. min_targets_setting .. ")")
            end
        else
            if debug_enabled then
                console.print("[INFERNO DEBUG] Normal mode - Insufficient targets (" .. total_hits .. " < " .. min_targets_setting .. ")")
            end
        end
    end

    -- Keybind can skip all the above logic
    if not can_cast and keybind_can_skip then
        can_cast = true
        if debug_enabled then
            console.print("[INFERNO DEBUG] Keybind override - forcing cast despite conditions not being met")
        end
    end

    if not can_cast then
        if debug_enabled then
            console.print("[INFERNO DEBUG] Casting conditions not met - not casting")
        end
        return false;
    end

    if not area_data.main_target:is_enemy() then
        if debug_enabled then
            console.print("[INFERNO DEBUG] Main target is not an enemy")
        end
        return false;
    end

    local cast_position = area_data.main_target:get_position();

    if cast_spell.position(spell_id_inferno, cast_position, 0.3) then
        local current_time = get_time_since_inject();
        local cooldown = 0.1;
        next_time_allowed_cast = current_time + cooldown;
        if debug_enabled then
            console.print("[INFERNO DEBUG] Cast successful with " .. total_hits .. " hits")
        end
        return true, cooldown;
    end

    if debug_enabled then
        console.print("[INFERNO DEBUG] Cast failed")
    end
    return false;

end


    
    

return 
{
    menu = menu,
    logics = logics,   
}