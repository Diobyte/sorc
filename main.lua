local local_player = get_local_player();
if local_player == nil then
    return
end

local character_id = local_player:get_character_class_id();
local is_sorc = character_id == 0;
if not is_sorc then
 return
end;

local menu = require("menu");
local spell_priority = require("spell_priority");
local spell_data = require("my_utility/spell_data");
local logger = require("my_utility/logger");
local buff_cache = require("my_utility/buff_cache");

local spells =
{
    arc_lash                = require("spells/arc_lash"),
    ball                    = require("spells/ball"),
    blizzard                = require("spells/blizzard"),
    chain_lightning         = require("spells/chain_lightning"),
    charged_bolts           = require("spells/charged_bolts"),
    deep_freeze             = require("spells/deep_freeze"),
    familiars               = require("spells/familiars"),
    flame_shield            = require("spells/flame_shield"),
    firewall                = require("spells/firewall"),
    fire_bolt               = require("spells/fire_bolt"),
    fireball                = require("spells/fireball"),
    frost_bolt              = require("spells/frost_bolt"),
    frost_nova              = require("spells/frost_nova"),
    frozen_orb              = require("spells/frozen_orb"),
    hydra                   = require("spells/hydra"),
    ice_armor               = require("spells/ice_armor"),
    ice_blade               = require("spells/ice_blade"),
    ice_shards              = require("spells/ice_shards"),
    incinerate              = require("spells/incinerate"),
    inferno                 = require("spells/inferno"),
    meteor                  = require("spells/meteor"),
    spear                   = require("spells/spear"),
    spark                   = require("spells/spark"),
    teleport                = require("spells/teleport"),
    teleport_ench           = require("spells/teleport_ench"),
    unstable_current        = require("spells/unstable_current")
}

on_render_menu (function ()

    if not menu.main_tree:push("Sorcerer: Salad Edition") then
        return;
    end;

    menu.main_boolean:render("Enable Plugin", "");


    if menu.main_boolean:get() == false then
        menu.main_tree:pop();
        return;
    end;
    
    menu.main_debug_enabled:render("Main Debug Mode", "Enable for high-verbosity console logging from the main loop")
    _G.__sorc_debug__ = menu.main_debug_enabled:get()
    
    -- Get equipped spells
    local equipped_spells = get_equipped_spell_ids()
    table.insert(equipped_spells, spell_data.evade.spell_id) -- add evade to the list
    
    -- Check for teleport_ench buff (buff_id 516547)
    local has_teleport_ench_buff = false
    local player_buffs = buff_cache.get_buffs(local_player)
    if player_buffs then
        for _, buff in ipairs(player_buffs) do
            if buff.name_hash == 516547 then
                has_teleport_ench_buff = true
                break
            end
        end
    end
    
    -- If teleport_ench buff is detected, add it to equipped spells
    if has_teleport_ench_buff then
        table.insert(equipped_spells, spell_data.teleport_ench.spell_id)
    end
    
    -- Create a lookup table for equipped spells
    local equipped_lookup = {}
    for _, spell_id in ipairs(equipped_spells) do
        equipped_lookup[spell_id] = true
    end
    
    -- File Logging System
    menu.file_logging_enabled:render("File Logging", "Enable to log debug information to timestamped files")
    
    -- Weighted Targeting System menu
    if menu.weighted_targeting_tree:push("Weighted Targeting System") then
        menu.weighted_targeting_debug:render("Debug Mode", "Enable high-verbosity console logging for weighted targeting decisions")
        menu.weighted_targeting_enabled:render("Enable Weighted Targeting", "Enables the weighted targeting system that prioritizes targets based on type and proximity")
        
        -- Only show configuration if weighted targeting is enabled
        if menu.weighted_targeting_enabled:get() then
            -- Scan settings
            menu.scan_radius:render("Scan Radius", "Radius around character to scan for targets (1-30)")
            menu.scan_refresh_rate:render("Refresh Rate", "How often to refresh target scanning in seconds (0.1-1.0)", 1) -- Add rounding parameter for float slider
            menu.min_targets:render("Minimum Targets", "Minimum number of targets required to activate weighted targeting (1-10)")
            menu.comparison_radius:render("Comparison Radius", "Radius to check for nearby targets when calculating weights (0.1-6.0)", 1) -- Add rounding parameter for float slider
            
            -- Custom Enemy Sliders toggle
            menu.custom_enemy_sliders_enabled:render("Custom Enemy Sliders", "Enable to customize target counts and weights for different enemy types")
            
            -- Only show sliders if custom enemy sliders are enabled
            if menu.custom_enemy_sliders_enabled:get() then
                -- Normal Enemy
                menu.normal_target_count:render("Normal Target Count", "Target count value for normal enemies (1-10)")
                menu.any_weight:render("Normal Weight", "Weight assigned to normal targets (1-100)")
                
                -- Elite Enemy
                menu.elite_target_count:render("Elite Target Count", "Target count value for elite enemies (1-10)")
                menu.elite_weight:render("Elite Weight", "Weight assigned to elite targets (1-100)")
                
                -- Champion Enemy
                menu.champion_target_count:render("Champion Target Count", "Target count value for champion enemies (1-10)")
                menu.champion_weight:render("Champion Weight", "Weight assigned to champion targets (1-100)")
                
                -- Boss Enemy
                menu.boss_target_count:render("Boss Target Count", "Target count value for boss enemies (1-10)")
                menu.boss_weight:render("Boss Weight", "Weight assigned to boss targets (1-100)")
            end
            -- Custom Buff Weights section
            menu.custom_buff_weights_enabled:render("Custom Buff Weights", "Enable to customize weights for special buff-related targets")
            if menu.custom_buff_weights_enabled:get() then
                menu.damage_resistance_provider_weight:render("Damage Resistance Provider Bonus", "Weight bonus for enemies providing damage resistance aura (1-100)")
                menu.damage_resistance_receiver_penalty:render("Damage Resistance Receiver Penalty", "Weight penalty for enemies receiving damage resistance (0-20)")
                menu.horde_objective_weight:render("Horde Objective Bonus", "Weight bonus for infernal horde objective targets (1-100)")
                menu.vulnerable_debuff_weight:render("Vulnerable Debuff Bonus", "Weight bonus for targets with VulnerableDebuff (1-5)")
            end
        end
        
        menu.weighted_targeting_tree:pop()
    end;
    
    -- Populate the equipped_lookup table with equipped spell IDs
    for _, spell_id in ipairs(equipped_spells) do
        equipped_lookup[spell_id] = true
    end
    
    -- Active spells menu (spells that are currently equipped)
    if menu.active_spells_tree:push("Active Spells") then
        -- Master toggle for cursor teleport, placed within the Active Spells tree
        menu.enable_cursor_teleport:render("Enable Cursor Teleport", "Master toggle for both Teleport and Teleport Enchantment.")
        
        local cursor_teleport_enabled = menu.enable_cursor_teleport:get()
        
        -- Sync with Teleport spell
        if spells.teleport.menu_elements_sorc_base then
            spells.teleport.menu_elements_sorc_base.cast_at_cursor:set(cursor_teleport_enabled)
        end
        
        -- Sync with Teleport Enchantment spell
        if spells.teleport_ench.menu_elements_teleport_ench then
            spells.teleport_ench.menu_elements_teleport_ench.cast_at_cursor:set(cursor_teleport_enabled)
        end

        -- Iterate through spell_priority to maintain the defined order
        for _, spell_name in ipairs(spell_priority) do
            -- Check if the spell exists in spells table, spell_data, and if it's equipped
            if spells[spell_name] and spell_data[spell_name] and spell_data[spell_name].spell_id and equipped_lookup[spell_data[spell_name].spell_id] then
                spells[spell_name].menu()
            end
        end
        menu.active_spells_tree:pop()
    end
    
    -- Inactive spells menu (spells that are not currently equipped)
    if menu.inactive_spells_tree:push("Inactive Spells") then
        -- Iterate through spell_priority to maintain the defined order
        for _, spell_name in ipairs(spell_priority) do
            -- Check if the spell exists in spells table, spell_data, and if it's not equipped
            if spells[spell_name] and spell_data[spell_name] and spell_data[spell_name].spell_id and not equipped_lookup[spell_data[spell_name].spell_id] then
                spells[spell_name].menu()
            end
        end
        menu.inactive_spells_tree:pop()
    end;
    
    menu.main_tree:pop();
    
end)

local can_move = 0.0;
local cast_end_time = 0.0;

local mount_buff_name = "Generic_SetCannotBeAddedToAITargetList";
local mount_buff_name_hash = mount_buff_name;
local mount_buff_name_hash_c = 1923;

local my_utility = require("my_utility/my_utility");
local my_target_selector = require("my_utility/my_target_selector");

on_update(function ()

    local local_player = get_local_player();
    if not local_player then
        return;
    end
    
    if menu.main_boolean:get() == false then
        -- if plugin is disabled dont do any logic
        return;
    end;

    -- Allow spell casting regardless of orbwalker mode if desired
    _G.__sorc_allow_any_orb_mode__ = true

    -- File logging management
    if menu.file_logging_enabled:get() then
        if not logger.is_ready() then
            logger.init()
        end
    else
        if logger.is_ready() then
            logger.close()
        end
    end

    local current_time = get_time_since_inject()
    if current_time < cast_end_time then
        -- Optional console debug is commented; avoid referencing undefined locals
        -- local debug_msg = "[MAIN DEBUG] Skipping spell casting - cast_end_time active for " .. string.format("%.2f", cast_end_time - current_time) .. "s"
        -- if logger.is_ready() then logger.log(debug_msg) end
        return;
    end;

    if not my_utility.is_action_allowed() then
        return;
    end  

    -- Removed undefined buff checks (blood mist) that don't apply to Sorcerer

    local screen_range = 12.0;
    local player_position = get_player_position();

    local collision_table = { true, 1.0 };
    local floor_table = { true, 5.0 };
    local angle_table = { false, 90.0 };

    local entity_list = my_target_selector.get_target_list(
        player_position,
        screen_range, 
        collision_table, 
        floor_table, 
        angle_table);

    local target_selector_data = my_target_selector.get_target_selector_data(
        player_position, 
        entity_list);

    -- Keep logic simple; avoid referencing undefined variables


    if not target_selector_data.is_valid then
        return;
    end

    local is_auto_play_active = auto_play.is_active();
    local max_range = 12.0;
    if is_auto_play_active then
        max_range = 12.0;
    end

    -- Default target selection (used if weighted targeting is disabled or no weighted target found)
    local best_target = target_selector_data.closest_unit;

    -- Apply weighted targeting if enabled
    if menu.weighted_targeting_enabled:get() then
        -- Get configuration values
        local scan_radius = menu.scan_radius:get()
        local refresh_rate = menu.scan_refresh_rate:get()
        local min_targets = menu.min_targets:get()
        local comparison_radius = menu.comparison_radius:get()
        
        -- Use either custom weights or default weights based on toggle
        local boss_weight, elite_weight, champion_weight, any_weight
        local damage_resistance_provider_weight, damage_resistance_receiver_penalty, horde_objective_weight
        
        -- Custom Enemy Sliders
        local normal_target_count, champion_target_count, elite_target_count, boss_target_count
        if menu.custom_enemy_sliders_enabled:get() then
            -- Get target count values
            normal_target_count = menu.normal_target_count:get()
            champion_target_count = menu.champion_target_count:get()
            elite_target_count = menu.elite_target_count:get()
            boss_target_count = menu.boss_target_count:get()
            
            -- Get weight values
            boss_weight = menu.boss_weight:get()
            elite_weight = menu.elite_weight:get()
            champion_weight = menu.champion_weight:get()
            any_weight = menu.any_weight:get()
        else
            -- Default target count values
            normal_target_count = 1
            champion_target_count = 5
            elite_target_count = 5
            boss_target_count = 5
            
            -- Default weight values
            boss_weight = 50
            elite_weight = 10
            champion_weight = 15
            any_weight = 2
        end

        -- Custom Buff Weights
        if menu.custom_buff_weights_enabled:get() then
            damage_resistance_provider_weight = menu.damage_resistance_provider_weight:get()
            damage_resistance_receiver_penalty = menu.damage_resistance_receiver_penalty:get()
            horde_objective_weight = menu.horde_objective_weight:get()
            vulnerable_debuff_weight = menu.vulnerable_debuff_weight:get()
        else
            damage_resistance_provider_weight = 30
            damage_resistance_receiver_penalty = 5
            horde_objective_weight = 50
            vulnerable_debuff_weight = 1
        end
        
        -- Get debug setting
        local debug_enabled = menu.weighted_targeting_debug:get()
        
        -- Get weighted target
        local weighted_target = my_target_selector.get_weighted_target(
            player_position,
            scan_radius,
            min_targets,
            comparison_radius,
            boss_weight,
            elite_weight,
            champion_weight,
            any_weight,
            refresh_rate,
            damage_resistance_provider_weight,
            damage_resistance_receiver_penalty,
            horde_objective_weight,
            vulnerable_debuff_weight,
            min_targets,
            normal_target_count,
            champion_target_count,
            elite_target_count,
            boss_target_count,
            debug_enabled
        )
        
        -- Only use weighted target if found, no fallback
        if weighted_target then
            best_target = weighted_target
        else
            -- If no weighted target found, set best_target to nil to prevent casting
            -- This respects the minimum target count setting
            best_target = nil
        end
    else
        -- Traditional targeting (if weighted targeting is disabled)
        if target_selector_data.has_elite then
            local unit = target_selector_data.closest_elite;
            local unit_position = unit:get_position();
            local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
            if distance_sqr < (max_range * max_range) then
                best_target = unit;
            end        
        end

        if target_selector_data.has_boss then
            local unit = target_selector_data.closest_boss;
            local unit_position = unit:get_position();
            local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
            if distance_sqr < (max_range * max_range) then
                best_target = unit;
            end
        end

        if target_selector_data.has_champion then
            local unit = target_selector_data.closest_champion;
            local unit_position = unit:get_position();
            local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
            if distance_sqr < (max_range * max_range) then
                best_target = unit;
            end
        end
    end

    if not best_target then
        if menu.main_debug_enabled:get() then
            console.print("[MAIN DEBUG] No best_target available; skipping spell loop")
        end
        return;
    end


    local best_target_position = best_target:get_position();
    local distance_sqr = best_target_position:squared_dist_to_ignore_z(player_position);

    if distance_sqr > (max_range * max_range) then            
        best_target = target_selector_data.closest_unit;
        local closer_pos = best_target:get_position();
        local distance_sqr_2 = closer_pos:squared_dist_to_ignore_z(player_position);
        if distance_sqr_2 > (max_range * max_range) then
            return;
        end
    end

    local function should_firewall()
        local actors = actors_manager.get_all_actors()
        for _, actor in ipairs(actors) do
            local actor_name = actor:get_skin_name()
            if actor_name == "Generic_Proxy_firewall" then
                local actor_position = actor:get_position()
                local dx = math.abs(best_target_position:x() - actor_position:x())
                local dy = math.abs(best_target_position:y() - actor_position:y())    
                if dx <= 2 and dy <= 8 then  -- rectangle width is 2 and height is 8
                    return false
                end
            end
        end
        return true
    end
    -- spells logics begins:
    -- if local_player:is_spell_ready(959728) then
    --     console.print("spell is ready")
    -- end

    -- if not local_playeris_spell_ready(959728) then
    --     console.print("spell is not ready")
    -- end

    -- Normal spell casting logic begins here
    
    -- Define spell parameters for consistent argument passing based on spell type
    local spell_params = {
        flame_shield = { args = {} }, -- All spells now return cooldown
        ice_armor = { args = {} },
        unstable_current = { args = {} },
        ball = { args = {best_target} },
        spear = { args = {best_target} },
        ice_blade = { args = {best_target} },
        fireball = { args = {best_target}, custom_handler = true },
        frozen_orb = { args = {best_target} },
        chain_lightning = { args = {best_target} },
        blizzard = { args = {best_target} },
        inferno = { args = {entity_list, target_selector_data, best_target} },
        firewall = { args = {local_player, best_target}, custom_check = should_firewall },
        meteor = { args = {best_target} },
        ice_shards = { args = {best_target, target_selector_data} },
        charged_bolts = { args = {best_target} },
        hydra = { args = {best_target, target_selector_data} },
        arc_lash = { args = {best_target} },
        incinerate = { args = {best_target} },
        frost_nova = { args = {} },
        teleport_ench = { args = {best_target, target_selector_data} },
        teleport = { args = {entity_list, target_selector_data, best_target} },
        deep_freeze = { args = {} },
        fire_bolt = { args = {best_target} },
        frost_bolt = { args = {best_target} },
        spark = { args = {best_target} },
        familiars = { args = {best_target, target_selector_data} }
    }
    
    -- Special handling for fireball because it has a return value
    local fireball_cast_successful, fireball_cooldown = spells.fireball.logics(best_target, target_selector_data)
    if fireball_cast_successful then
        cast_end_time = current_time + fireball_cooldown;
        return;
    end;
    
    -- Get equipped spells for spell casting logic
    local equipped_spells = get_equipped_spell_ids()
    table.insert(equipped_spells, spell_data.evade.spell_id) -- add evade to the list
    
    -- Check for teleport_ench buff (buff_id 516547)
    local has_teleport_ench_buff = false
    local player_buffs = buff_cache.get_buffs(local_player)
    if player_buffs then
        for _, buff in ipairs(player_buffs) do
            if buff.name_hash == 516547 then
                has_teleport_ench_buff = true
                break
            end
        end
    end
    
    -- If teleport_ench buff is detected, add it to equipped spells
    if has_teleport_ench_buff then
        table.insert(equipped_spells, spell_data.teleport_ench.spell_id)
    end
    
    -- Create a lookup table for equipped spells
    local equipped_lookup = {}
    for _, spell_id in ipairs(equipped_spells) do
        equipped_lookup[spell_id] = true
    end
    
    -- Removed problematic spell loop that bypassed cast_end_time mechanism
    
    -- Loop through spells in priority order defined in spell_priority.lua
    local any_cast = false
    for _, spell_name in ipairs(spell_priority) do
        local spell = spells[spell_name]
        -- Only process spells that are equipped
        if spell and spell_data[spell_name] and spell_data[spell_name].spell_id and equipped_lookup[spell_data[spell_name].spell_id] then
            local params = spell_params[spell_name]
            
            if params then
                -- Skip spells with custom_handler flag as they're handled separately
                if not params.custom_handler then
                    -- Check any custom pre-conditions if defined
                    local should_cast = true
                    if params.custom_check ~= nil then
                        should_cast = params.custom_check()
                    end
                    
                    if should_cast then
                        -- Call spell's logics function with appropriate arguments
                        local debug_msg_attempt = "[MAIN DEBUG] Attempting " .. spell_name .. " cast"
                        if logger.is_ready() then
                            logger.log(debug_msg_attempt)
                        end
                        
                        local args = params.args or {}
                        local cast_successful, cooldown
                        if #args == 0 then
                            cast_successful, cooldown = spell.logics()
                        elseif #args == 1 then
                            cast_successful, cooldown = spell.logics(args[1])
                        elseif #args == 2 then
                            cast_successful, cooldown = spell.logics(args[1], args[2])
                        elseif #args == 3 then
                            cast_successful, cooldown = spell.logics(args[1], args[2], args[3])
                        else
                            -- Limit to first 3 to satisfy strict signatures
                            cast_successful, cooldown = spell.logics(args[1], args[2], args[3])
                        end
                        if cast_successful then
                            -- All spells now return their actual cooldown duration
                            cast_end_time = current_time + cooldown
                            local debug_msg = "[MAIN DEBUG] " .. spell_name .. " cast successful - setting cast_end_time for " .. cooldown .. "s"
                            if menu.main_debug_enabled:get() then
                                console.print(debug_msg)
                            end
                            if logger.is_ready() then
                                logger.log(debug_msg)
                            end
                            any_cast = true
                            return
                        else
                            local debug_msg_fail = "[MAIN DEBUG] " .. spell_name .. " cast failed"
                            if logger.is_ready() then
                                logger.log(debug_msg_fail)
                            end
                        end
                    else
                        local debug_msg_precond = "[MAIN DEBUG] " .. spell_name .. " pre-conditions not met"
                        if logger.is_ready() then
                            logger.log(debug_msg_precond)
                        end
                    end
                else
                    local debug_msg_custom = "[MAIN DEBUG] " .. spell_name .. " has custom_handler - skipping"
                    if logger.is_ready() then
                        logger.log(debug_msg_custom)
                    end
                end
            else
                local debug_msg_no_params = "[MAIN DEBUG] " .. spell_name .. " has no params defined"
                if logger.is_ready() then
                    logger.log(debug_msg_no_params)
                end
            end
        end
    end

    if not any_cast and menu.main_debug_enabled:get() then
        console.print("[MAIN DEBUG] Spell loop completed with no casts (check is_spell_allowed, cooldowns, equipped list)")
    end
    
    -- auto play engage far away monsters
    local move_timer = get_time_since_inject()
    if move_timer < can_move then
        return;
    end;

    -- auto play engage far away monsters
    local is_auto_play = my_utility.is_auto_play_enabled();
    if is_auto_play then
        local player_position = local_player:get_position();
        local is_dangerous_evade_position = evade.is_dangerous_position(player_position);
        if not is_dangerous_evade_position then
            local closer_target = target_selector.get_target_closer(player_position, 15.0);
            if closer_target then
                -- if is_blood_mist then
                --     local closer_target_position = closer_target:get_position();
                --     local move_pos = closer_target_position:get_extended(player_position, -5.0);
                --     if pathfinder.move_to_cpathfinder(move_pos) then
                --         cast_end_time = current_time + 0.40;
                --         can_move = move_timer + 1.5;
                --         --console.print("auto play move_to_cpathfinder - 111")
                --     end
                -- else
                    local closer_target_position = closer_target:get_position();
                    local move_pos = closer_target_position:get_extended(player_position, 4.0);
                    if pathfinder.move_to_cpathfinder(move_pos) then
                        can_move = move_timer + 1.5;
                        --console.print("auto play move_to_cpathfinder - 222")
                    end
                -- end
                
            end
        end
    end

end)

local draw_player_circle = false;
local draw_enemy_circles = false;

on_render(function ()

    if menu.main_boolean:get() == false then
        return;
    end;

    local local_player = get_local_player();
    if not local_player then
        return;
    end

    local player_position = local_player:get_position();
    local player_screen_position = graphics.w2s(player_position);
    if player_screen_position:is_zero() then
        return;
    end

    local function count_and_display_buffs()
        local local_player = get_local_player()
        local player_position = get_player_position()
        local player_position_2d = graphics.w2s(player_position)
        local text_position = vec2.new(player_position_2d.x, player_position_2d.y + 15)
        local buff_name_check = "Ring_Unique_Sorc_101"
        if not local_player then return 0 end

        local buffs = local_player:get_buffs()
        if not buffs then return 0 end

        local buff_stack_count = -1

        for _, buff in ipairs(buffs) do
            local buff_name = buff:name()
            if buff_name == buff_name_check then
                buff_stack_count = buff_stack_count + 1
            end
        end
        return buff_stack_count
    end

    local buff_stack_count = count_and_display_buffs()

    if draw_player_circle then
        graphics.circle_3d(player_position, 8, color_white(85), 3.5, 144)
        graphics.circle_3d(player_position, 6, color_white(85), 2.5, 144)
    end    

    if draw_enemy_circles then
        local enemies = actors_manager.get_enemy_npcs()

        for i,obj in ipairs(enemies) do
        local position = obj:get_position();
        local distance_sqr = position:squared_dist_to_ignore_z(player_position);
        local is_close = distance_sqr < (8.0 * 8.0);
            -- if is_close then
                graphics.circle_3d(position, 1, color_white(100));

                local future_position = prediction.get_future_unit_position(obj, 0.4);
                graphics.circle_3d(future_position, 0.5, color_yellow(100));
            -- end;
        end;
    end


    -- glow target -- quick pasted code cba about this game

    local screen_range = 12.0;
    local player_position = get_player_position();

    local collision_table = { true, 1.0 };
    local floor_table = { true, 5.0 };
    local angle_table = { false, 90.0 };

    local entity_list = my_target_selector.get_target_list(
        player_position,
        screen_range, 
        collision_table, 
        floor_table, 
        angle_table);

    local target_selector_data = my_target_selector.get_target_selector_data(
        player_position, 
        entity_list);

    if not target_selector_data.is_valid then
        return;
    end

    local is_auto_play_active = auto_play.is_active();
    local max_range = 12.0;
    if is_auto_play_active then
        max_range = 12.0;
    end

    local best_target = target_selector_data.closest_unit;

    if target_selector_data.has_elite then
        local unit = target_selector_data.closest_elite;
        local unit_position = unit:get_position();
        local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
        if distance_sqr < (max_range * max_range) then
            best_target = unit;
        end        
    end

    if target_selector_data.has_boss then
        local unit = target_selector_data.closest_boss;
        local unit_position = unit:get_position();
        local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
        if distance_sqr < (max_range * max_range) then
            best_target = unit;
        end
    end

    if target_selector_data.has_champion then
        local unit = target_selector_data.closest_champion;
        local unit_position = unit:get_position();
        local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position);
        if distance_sqr < (max_range * max_range) then
            best_target = unit;
        end
    end   

    if not best_target then
        return;
    end

    if best_target and best_target:is_enemy()  then
        local glow_target_position = best_target:get_position();
        local glow_target_position_2d = graphics.w2s(glow_target_position);
        graphics.line(glow_target_position_2d, player_screen_position, color_red(180), 2.5)
        graphics.circle_3d(glow_target_position, 0.80, color_red(200), 2.0);
    end


end);

console.print("Lua Plugin - Salad Sorcerer - Version 1.8 (Console cleanup edition)");