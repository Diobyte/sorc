local my_utility = require("my_utility/my_utility");

local menu_elements_hydra = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_hydra")),
    max_mana_only         = checkbox:new(false, get_hash(my_utility.plugin_label .. "max_mana_only_hydra")),
    
    -- Hydra Management
    hydra_enchantment     = checkbox:new(false, get_hash(my_utility.plugin_label .. "hydra_enchantment")),
    hydra_search_distance = slider_float:new(5.0, 30.0, 15.0, get_hash(my_utility.plugin_label .. "hydra_search_distance")),
    hydra_spread_distance = slider_float:new(3.0, 8.0, 5.0, get_hash(my_utility.plugin_label .. "hydra_spread_distance")),
    
    -- Targeting
    priority_target       = checkbox:new(false, get_hash(my_utility.plugin_label .. "hydra_priority_target_bool")),
    
    -- Cast Delay
    delay_hydra_cast      = checkbox:new(false, get_hash(my_utility.plugin_label .. "delay_hydra_cast")),
    cast_delay_seconds    = slider_float:new(1.0, 5.0, 3.0, get_hash(my_utility.plugin_label .. "hydra_cast_delay_seconds")),
    
    -- Advanced Features
    coverage_optimization = checkbox:new(true, get_hash(my_utility.plugin_label .. "hydra_coverage_optimization")),
    auto_reposition      = checkbox:new(false, get_hash(my_utility.plugin_label .. "hydra_auto_reposition")),
    debug_mode           = checkbox:new(false, get_hash(my_utility.plugin_label .. "hydra_debug_mode")),
}

local function menu()
    if menu_elements_hydra.tree_tab:push("Hydra") then
        menu_elements_hydra.main_boolean:render("Enable Spell", "")
        menu_elements_hydra.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        
        if menu_elements_hydra.main_boolean:get() then
            menu_elements_hydra.max_mana_only:render("Cast on Max Mana only", "Only cast Hydra when mana is at 100%")
            
            -- Hydra Management Section
            menu_elements_hydra.hydra_enchantment:render("Hydra Enchantment", "Target 9 hydras instead of 6 (for enchantment builds)")
            menu_elements_hydra.hydra_search_distance:render("Hydra Search Distance", "Distance to search for existing hydras", 1)
            menu_elements_hydra.hydra_spread_distance:render("Hydra Spread Distance", "Minimum distance between hydras for coverage", 1)
            
            -- Targeting Section
            menu_elements_hydra.priority_target:render("Priority Targeting (Ignore weighted targeting)", "Targets Boss > Champion > Elite > Any")
            
            -- Cast Delay Section
            menu_elements_hydra.delay_hydra_cast:render("Delay Hydra Cast", "Add artificial delay between hydra casts")
            if menu_elements_hydra.delay_hydra_cast:get() then
                menu_elements_hydra.cast_delay_seconds:render("Cast Delay (s)", "Minimum seconds between hydra casts", 1)
            end
            
            -- Advanced Features
            menu_elements_hydra.coverage_optimization:render("Coverage Optimization", "Optimize hydra placement for maximum area coverage")
            menu_elements_hydra.auto_reposition:render("Auto Reposition", "Replace poorly positioned hydras automatically")
        end
        
        menu_elements_hydra.tree_tab:pop()
    end
end

local spell_id_hydra = 146743
local next_time_allowed_cast = 0.0;
local last_hydra_cast_time = 0.0;

-- Function to count existing hydras within range and their positions
local function count_existing_hydras(player_position, search_distance)
    local hydra_count = 0
    local hydra_positions = {}
    local hydra_actors = {}
    
    if actors_manager and actors_manager.get_all_actors then
        local all_actors = actors_manager.get_all_actors()
        for _, actor in ipairs(all_actors) do
            if actor and actor.get_skin_name then
                local skin_name = actor:get_skin_name()
                -- Check for hydra skin names (adjust based on actual game data)
                if skin_name:match("Hydra") or skin_name:match("Sorcerer_Hydra") then
                    local actor_position = actor:get_position()
                    local distance = player_position:dist_to(actor_position)
                    
                    if distance <= search_distance then
                        hydra_count = hydra_count + 1
                        table.insert(hydra_positions, actor_position)
                        table.insert(hydra_actors, actor)
                    end
                end
            end
        end
    end
    
    return hydra_count, hydra_positions, hydra_actors
end

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

-- Function to find optimal hydra placement position for maximum coverage
local function find_optimal_hydra_position(anchor_position, existing_hydra_positions, spread_distance, all_enemies, coverage_optimization, debug_enabled)
    
    -- If no existing hydras, place at anchor position
    if #existing_hydra_positions == 0 then
        if debug_enabled then
            console.print("[HYDRA DEBUG] No existing hydras, placing at anchor position")
        end
        return anchor_position
    end
    
    if not coverage_optimization then
        -- Direct placement: use anchor position (weighted target) with basic environmental checks
        if debug_enabled then
            console.print("[HYDRA DEBUG] Using direct target positioning (coverage optimization disabled)")
        end
        
        -- Perform basic environmental checks on the anchor position
        local player_position = get_player_position()
        
        -- Check for walls between player and target position
        if prediction.is_wall_collision(player_position, anchor_position, 0.2) then
            if debug_enabled then
                console.print("[HYDRA DEBUG] Wall collision detected: Player -> Target, using player position as fallback")
            end
            return player_position
        end
        
        -- Return the anchor position directly (this is the weighted target's position)
        return anchor_position
    end
    
    -- Advanced coverage optimization
    local best_position = anchor_position
    local best_score = 0
    
    if debug_enabled then
        console.print("[HYDRA DEBUG] Using coverage optimization with " .. #existing_hydra_positions .. " existing hydras")
    end
    
    -- Generate potential positions in a grid pattern around anchor position
    local test_positions = {}
    local angles = {0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330}
    local distances = {2, 3, 4, 5, 6}
    
    for _, angle in ipairs(angles) do
        for _, dist in ipairs(distances) do
            local rad = math.rad(angle)
            local test_x = anchor_position:x() + dist * math.cos(rad)
            local test_y = anchor_position:y() + dist * math.sin(rad)
            local test_position = vec3.new(test_x, test_y, anchor_position:z())
            table.insert(test_positions, test_position)
        end
    end
    
    -- Evaluate each position
    for _, test_position in ipairs(test_positions) do
        local score = 0
        
        -- Check distance to existing hydras (must maintain spread)
        local min_hydra_distance = math.huge
        for _, hydra_pos in ipairs(existing_hydra_positions) do
            local distance = test_position:dist_to(hydra_pos)
            if distance < min_hydra_distance then
                min_hydra_distance = distance
            end
        end
        
        -- Skip if too close to existing hydras
        if min_hydra_distance < spread_distance then
            goto continue
        end

        -- Environmental Awareness Checks
        local player_position = get_player_position()
        -- Check for walls between player and potential cast spot
        if prediction.is_wall_collision(player_position, test_position, 0.2) then
            if debug_enabled then
                -- This can be spammy, so it's commented out by default
                -- console.print("[HYDRA DEBUG] Wall collision detected: Player -> Cast Spot")
            end
            goto continue
        end
        -- Check for walls between cast spot and the target
        if prediction.is_wall_collision(test_position, anchor_position, 0.2) then
            if debug_enabled then
                -- This can be spammy, so it's commented out by default
                -- console.print("[HYDRA DEBUG] Wall collision detected: Cast Spot -> Target")
            end
            goto continue
        end
        
        -- Density-Weighted Scoring Logic
        local hydra_effective_range = 8.0
        for _, enemy in ipairs(all_enemies) do
            local enemy_position = enemy:get_position()
            local distance_to_enemy = test_position:dist_to(enemy_position)

            if distance_to_enemy <= hydra_effective_range then
                -- Determine the base score based on enemy type
                local base_score = 1
                if enemy:is_boss() then
                    base_score = 4 -- More weight for bosses
                elseif enemy:is_elite() or enemy:is_champion() then
                    base_score = 3 -- More weight for elites/champions
                end

                -- Calculate the distance factor (1.0 at center, ~0.0 at the edge)
                local distance_factor = (1.0 - (distance_to_enemy / hydra_effective_range))

                -- Add the final weighted score to the total
                score = score + (base_score * distance_factor)
            end
        end
        
        -- Bonus for maintaining spread distance
        score = score + (min_hydra_distance / spread_distance)
        
        if score > best_score then
            best_score = score
            best_position = test_position
        end
        
        ::continue::
    end
    
    if debug_enabled then
        console.print("[HYDRA DEBUG] Best position found with score: " .. best_score)
    end
    
    return best_position
end

-- Simple spread positioning fallback
local function find_simple_spread_position(target_position, existing_hydra_positions, spread_distance)
    local best_position = target_position
    local best_distance = 0
    
    local angles = {0, 45, 90, 135, 180, 225, 270, 315}
    local distances = {2, 3, 4, 5}
    
    for _, angle in ipairs(angles) do
        for _, dist in ipairs(distances) do
            local rad = math.rad(angle)
            local test_x = target_position:x() + dist * math.cos(rad)
            local test_y = target_position:y() + dist * math.sin(rad)
            local test_position = vec3.new(test_x, test_y, target_position:z())
            
            local min_distance = math.huge
            for _, hydra_pos in ipairs(existing_hydra_positions) do
                local distance = test_position:dist_to(hydra_pos)
                if distance < min_distance then
                    min_distance = distance
                end
            end
            
            if min_distance >= spread_distance and min_distance > best_distance then
                best_distance = min_distance
                best_position = test_position
            end
        end
    end
    
    return best_position
end

-- Function to check if hydras need repositioning
local function check_auto_reposition(hydra_actors, all_enemies, debug_enabled)
    if not menu_elements_hydra.auto_reposition:get() then
        return false, nil
    end
    
    -- Check if any hydra is poorly positioned (no enemies in range)
    for _, hydra_actor in ipairs(hydra_actors) do
        local hydra_position = hydra_actor:get_position()
        local enemies_in_range = 0
        
        for _, enemy in ipairs(all_enemies) do
            local distance = hydra_position:dist_to(enemy:get_position())
            if distance <= 8.0 then  -- Hydra effective range
                enemies_in_range = enemies_in_range + 1
            end
        end
        
        if enemies_in_range == 0 then
            if debug_enabled then
                console.print("[HYDRA DEBUG] Found poorly positioned hydra, marking for reposition")
            end
            return true, hydra_actor
        end
    end
    
    return false, nil
end

local function logics(best_target, target_selector_data)
    local menu_boolean = menu_elements_hydra.main_boolean:get();
    local debug_enabled = menu_elements_hydra.debug_mode:get();
    local priority_target = menu_elements_hydra.priority_target:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_hydra);

    if not is_logic_allowed then
        return false;
    end;
    
    -- Check delay hydra cast feature
    if menu_elements_hydra.delay_hydra_cast:get() then
        local current_time = get_time_since_inject();
        local delay_seconds = menu_elements_hydra.cast_delay_seconds:get();
        local time_since_last_cast = current_time - last_hydra_cast_time;
        
        if time_since_last_cast < delay_seconds then
            if debug_enabled then
                local remaining_delay = delay_seconds - time_since_last_cast;
                console.print("[HYDRA DEBUG] Cast delayed - " .. string.format("%.1f", remaining_delay) .. "s remaining");
            end
            return false;
        end
    end;
    
    -- Check if player's mana is at 100% when max_mana_only is enabled
    if menu_elements_hydra.max_mana_only:get() then
        local local_player = get_local_player();
        if not local_player then
            return false;
        end
        
        local current_mana = local_player:get_primary_resource_current();
        local max_mana = local_player:get_primary_resource_max();
        
        -- Only cast if mana is at 100%
        if current_mana < max_mana then
            if debug_enabled then
                console.print("[HYDRA DEBUG] Waiting for max mana")
            end
            return false;
        end
    end;

    local player_position = get_player_position()
    local target_hydra_count = menu_elements_hydra.hydra_enchantment:get() and 9 or 6
    local search_distance = menu_elements_hydra.hydra_search_distance:get()
    local spread_distance = menu_elements_hydra.hydra_spread_distance:get()
    local coverage_optimization = menu_elements_hydra.coverage_optimization:get()
    
    -- Count existing hydras
    local hydra_count, hydra_positions, hydra_actors = count_existing_hydras(player_position, search_distance)
    
    if debug_enabled then
        console.print("[HYDRA DEBUG] Found " .. hydra_count .. "/" .. target_hydra_count .. " hydras")
    end
    
    -- Determine the target to use
    local hydra_target = best_target
    local target_type = "Weighted"
    
    -- If priority targeting is enabled and we have target data, use that instead
    if priority_target and target_selector_data then
        local priority_best_target, priority_target_type = get_priority_target(target_selector_data)
        if priority_best_target then
            hydra_target = priority_best_target
            target_type = priority_target_type
            if debug_enabled then
                console.print("[HYDRA DEBUG] Using priority target: " .. target_type)
            end
        end
    end
    
    -- If we still don't have a target, we can't cast
    if not hydra_target then
        if debug_enabled then
            console.print("[HYDRA DEBUG] No valid target found")
        end
        return false
    end
    
    -- Get enemy list for coverage optimization and auto-reposition
    local all_enemies = {}
    if target_selector_data and target_selector_data.all_enemies then
        all_enemies = target_selector_data.all_enemies
    end
    
    -- Check for auto-reposition
    local needs_reposition, poorly_positioned_hydra = check_auto_reposition(hydra_actors, all_enemies, debug_enabled)
    
    -- Determine if we should cast
    local should_cast = false
    local cast_reason = ""
    
    -- Auto-reposition poorly placed hydras
    if needs_reposition and poorly_positioned_hydra then
        should_cast = true
        cast_reason = " (AUTO REPOSITION)"
    -- Standard hydra count check
    elseif hydra_count < target_hydra_count then
        should_cast = true
        cast_reason = " (STANDARD)"
    end
    
    if not should_cast then
        if debug_enabled then
            console.print("[HYDRA DEBUG] No cast conditions met - " .. hydra_count .. "/" .. target_hydra_count .. " hydras")
        end
        return false
    end
    
    -- Find the "Sweet Spot" for optimal Hydra placement
    local hydra_effective_range = 8.0
    local sweet_spot_position = nil
    local sweet_spot_type = "Target-Based"
    
    -- Use area analysis to find the point of maximum enemy density
    local area_data = target_selector.get_most_hits_target_circular_area_heavy(player_position, 15.0, hydra_effective_range)
    
    if area_data and area_data.n_hits > 0 and area_data.point then
        sweet_spot_position = area_data.point
        sweet_spot_type = "Sweet Spot (" .. area_data.n_hits .. " enemies)"
        
        if debug_enabled then
            console.print("[HYDRA DEBUG] Found sweet spot with " .. area_data.n_hits .. " potential targets")
        end
    elseif hydra_target then
        -- Fallback to target-based positioning if no sweet spot found but we have a target
        sweet_spot_position = hydra_target:get_position()
        
        if debug_enabled then
            console.print("[HYDRA DEBUG] No sweet spot found, using target position")
        end
    else
        -- Emergency fallback to player position if no target available
        sweet_spot_position = player_position
        sweet_spot_type = "Player Position (Emergency)"
        
        if debug_enabled then
            console.print("[HYDRA DEBUG] No target or sweet spot found, using player position")
        end
    end
    
    -- Validate that we have a valid position before proceeding
    if not sweet_spot_position then
        if debug_enabled then
            console.print("[HYDRA DEBUG] No valid position found for casting")
        end
        return false, 0
    end
    
    -- Find optimal position for hydra placement
    local cast_position = find_optimal_hydra_position(
        sweet_spot_position, 
        hydra_positions, 
        spread_distance, 
        all_enemies, 
        coverage_optimization,
        debug_enabled
    )
    
    -- Final validation before casting
    if not cast_position then
        if debug_enabled then
            console.print("[HYDRA DEBUG] find_optimal_hydra_position returned nil")
        end
        return false, 0
    end

    if cast_spell.position(spell_id_hydra, cast_position, 0.35) then
        local current_time = get_time_since_inject();
        local cooldown = 0.1;
        next_time_allowed_cast = current_time + cooldown;
        
        -- Update last cast time for delay feature
        last_hydra_cast_time = current_time;
        
        if debug_enabled then
            console.print("[HYDRA DEBUG] Cast successful" .. cast_reason .. " (" .. (hydra_count + 1) .. "/" .. target_hydra_count .. ") - " .. sweet_spot_type)
        end
        return true, cooldown;
    end

    if debug_enabled then
        console.print("[HYDRA DEBUG] Cast failed")
    end
    return false, 0;
end

return 
{
    menu = menu,
    logics = logics,   
}