local local_player = get_local_player();
if local_player == nil then
    return
end

local character_id = local_player:get_character_class_id();
local is_sorc = character_id == 0;
if not is_sorc then
    return
end;

-- Get character level for leveling priorities
local function get_character_level()
    return local_player:get_level() or 50;  -- Default to 50 if level not available
end

-- orbwalker settings
orbwalker.set_block_movement(true);
orbwalker.set_clear_toggle(true);

local my_target_selector = require("my_utility/my_target_selector");
local my_utility = require("my_utility/my_utility");
local spell_data = require("my_utility/spell_data");
local buff_cache = require("my_utility/buff_cache");
local get_spell_priority = require("spell_priority");
local logger = require("my_utility/logger");

local current_spell_priority = get_spell_priority(0, get_character_level());  -- Include level for leveling priorities

local menu_elements =
{
    main_boolean                   = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean")),
    build_selection                = combo_box:new(0, get_hash(my_utility.plugin_label .. "build_selection")),
    -- first parameter is the default state, second one the menu element's ID. The ID must be unique,
    -- not only from within the plugin but also it needs to be unique between demo menu elements and
    -- other scripts menu elements. This is why we concatenate the plugin name ("LUA_EXAMPLE_NECROMANCER")
    -- with the menu element name itself.

    main_tree                      = tree_node:new(0),

    -- trees are the menu tabs. The parameter that we pass is the depth of the node. (0 for main menu (bright red rectangle),
    -- 1 for sub-menu of depth 1 (circular red rectangle with white background) and so on)
    settings_tree                  = tree_node:new(1),
    enemy_count_threshold          = slider_int:new(1, 10, 1,
        get_hash(my_utility.plugin_label .. "enemy_count_threshold")),
    max_targeting_range            = slider_int:new(1, 30, 12, get_hash(my_utility.plugin_label .. "max_targeting_range")),
    cursor_targeting_radius        = slider_float:new(0.1, 6, 3,
        get_hash(my_utility.plugin_label .. "cursor_targeting_radius")),
    cursor_targeting_angle         = slider_int:new(20, 50, 30,
        get_hash(my_utility.plugin_label .. "cursor_targeting_angle")),
    best_target_evaluation_radius  = slider_float:new(0.1, 6, 1.5,
        get_hash(my_utility.plugin_label .. "best_target_evaluation_radius")),
    targeting_refresh_interval     = slider_float:new(0.1, 1.0, 0.2,
        get_hash(my_utility.plugin_label .. "targeting_refresh_interval")),

    enemy_weights_tree             = tree_node:new(1),
    custom_enemy_weights_tree      = tree_node:new(2),
    enemy_weight_normal            = slider_int:new(1, 100, 2,
        get_hash(my_utility.plugin_label .. "enemy_weight_normal")),
    enemy_weight_elite             = slider_int:new(1, 100, 10,
        get_hash(my_utility.plugin_label .. "enemy_weight_elite")),
    enemy_weight_champion          = slider_int:new(1, 100, 15,
        get_hash(my_utility.plugin_label .. "enemy_weight_champion")),
    enemy_weight_boss              = slider_int:new(1, 100, 50,
        get_hash(my_utility.plugin_label .. "enemy_weight_boss")),
    enemy_weight_damage_resistance = slider_int:new(1, 100, 25,
        get_hash(my_utility.plugin_label .. "enemy_weight_damage_resistance")),
    enemy_weight_vulnerable_debuff = slider_int:new(1, 100, 10,
        get_hash(my_utility.plugin_label .. "enemy_weight_vulnerable_debuff")),
    enemy_weight_horde_objective   = slider_int:new(1, 100, 5,
        get_hash(my_utility.plugin_label .. "enemy_weight_horde_objective")),

    debug_tree                     = tree_node:new(1),
    enable_debug                   = checkbox:new(false, get_hash(my_utility.plugin_label .. "enable_debug")),
    file_logging_enabled           = checkbox:new(false, get_hash(my_utility.plugin_label .. "file_logging_enabled")),
    draw_targets                   = checkbox:new(false, get_hash(my_utility.plugin_label .. "draw_targets")),
    draw_max_range                 = checkbox:new(false, get_hash(my_utility.plugin_label .. "draw_max_range")),
    draw_melee_range               = checkbox:new(false, get_hash(my_utility.plugin_label .. "draw_melee_range")),
    draw_cursor_target             = checkbox:new(false, get_hash(my_utility.plugin_label .. "draw_cursor_target")),
    draw_enemy_circles             = checkbox:new(false, get_hash(my_utility.plugin_label .. "draw_enemy_circles")),
    draw_weighted_scores           = checkbox:new(false, get_hash(my_utility.plugin_label .. "draw_weighted_scores")),

    weighted_targeting_tree             = tree_node:new(1),
    weighted_targeting_enabled          = checkbox:new(false, get_hash(my_utility.plugin_label .. "weighted_targeting_enabled")),
    weighted_targeting_debug            = checkbox:new(false, get_hash(my_utility.plugin_label .. "weighted_targeting_debug")),
    scan_radius                         = slider_float:new(1.0, 30.0, 12.0, get_hash(my_utility.plugin_label .. "scan_radius")),
    scan_refresh_rate                   = slider_float:new(0.1, 1.0, 0.2, get_hash(my_utility.plugin_label .. "scan_refresh_rate")),
    min_targets                         = slider_int:new(1, 10, 1, get_hash(my_utility.plugin_label .. "min_targets")),
    comparison_radius                   = slider_float:new(0.1, 6.0, 1.5, get_hash(my_utility.plugin_label .. "comparison_radius")),

    spells_tree                    = tree_node:new(1),
    disabled_spells_tree           = tree_node:new(1),
}

local draw_targets_description =
    "\n     Targets in sight:\n" ..
    "     Ranged Target - RED circle with line     \n" ..
    "     Melee Target - GREEN circle with line     \n" ..
    "     Closest Target - CYAN circle with line     \n\n" ..
    "     Targets out of sight (only if they are not the same as targets in sight):\n" ..
    "     Ranged Target - faded RED circle     \n" ..
    "     Melee Target - faded GREEN circle     \n" ..
    "     Closest Target - faded CYAN circle     \n\n" ..
    "     Best Target Evaluation Radius:\n" ..
    "     faded WHITE circle       \n\n"

local cursor_target_description =
    "\n     Best Cursor Target - ORANGE pentagon     \n" ..
    "     Closest Cursor Target - GREEN pentagon     \n\n"

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
    spark                   = require("spells/spark"),
    spear                   = require("spells/spear"),
    teleport                = require("spells/teleport"),
    teleport_ench           = require("spells/teleport_ench"),
    unstable_current        = require("spells/unstable_current")
}

on_render_menu(function()
    if not menu_elements.main_tree:push("Sorcerer [Dirty] v1.0.4") then
        return;
    end;

    menu_elements.main_boolean:render("Enable Plugin", "");

    menu_elements.build_selection:render("Build Selection",
        "Select your preferred build specialization (Season 11 Meta)",
        {"Default", "Ball Lightning (META)", "Fire Build", "Frost Build", "Chain Lightning"});

    -- Update spell priority based on selected build and character level
    current_spell_priority = get_spell_priority(menu_elements.build_selection:get(), get_character_level());

    if not menu_elements.main_boolean:get() then
        -- plugin not enabled, stop rendering menu elements
        menu_elements.main_tree:pop();
        return;
    end;

    if menu_elements.settings_tree:push("Settings") then
        menu_elements.enemy_count_threshold:render("Minimum Enemy Count",
            "       Minimum number of enemies in Enemy Evaluation Radius to consider them for targeting")
        menu_elements.targeting_refresh_interval:render("Targeting Refresh Interval",
            "       Time between target checks in seconds       ", 1)
        menu_elements.max_targeting_range:render("Max Targeting Range",
            "       Maximum range for targeting       ")
        menu_elements.cursor_targeting_radius:render("Cursor Targeting Radius",
            "       Area size for selecting target around the cursor       ", 1)
        menu_elements.cursor_targeting_angle:render("Cursor Targeting Angle",
            "       Maximum angle between cursor and target to cast targetted spells       ")
        menu_elements.best_target_evaluation_radius:render("Enemy Evaluation Radius",
            "       Area size around an enemy to evaluate if it's the best target       \n" ..
            "       If you use huge aoe spells, you should increase this value       \n" ..
            "       Size is displayed with debug/display targets with faded white circles       ", 1)

        if menu_elements.enemy_weights_tree:push("Enemy Weights") then
            menu_elements.enemy_weight_normal:render("Normal Enemy Weight",
                "Weighing score for normal enemies - default is 2")
            menu_elements.enemy_weight_elite:render("Elite Enemy Weight",
                "Weighing score for elite enemies - default is 10")
            menu_elements.enemy_weight_champion:render("Champion Enemy Weight",
                "Weighing score for champion enemies - default is 15")
            menu_elements.enemy_weight_boss:render("Boss Enemy Weight",
                "Weighing score for boss enemies - default is 50")
            menu_elements.enemy_weight_damage_resistance:render("Damage Resistance Aura Enemy Weight",
                "Weighing score for enemies with damage resistance aura - default is 25")
            menu_elements.enemy_weight_vulnerable_debuff:render("Vulnerable Debuff Enemy Weight",
                "Weighing score for enemies with vulnerable debuff - default is 10")
            menu_elements.enemy_weight_horde_objective:render("Horde Objective Enemy Weight",
                "Weighing score for horde objective enemies - default is 5")
            menu_elements.enemy_weights_tree:pop()
        end

        menu_elements.enable_debug:render("Enable Debug", "")
        menu_elements.file_logging_enabled:render("Enable File Logging", 
            "Log debug information to a file on disk")
        if menu_elements.enable_debug:get() then
            if menu_elements.debug_tree:push("Debug") then
                menu_elements.draw_targets:render("Display Targets", draw_targets_description)
                menu_elements.draw_max_range:render("Display Max Range",
                    "Draw max range circle")
                menu_elements.draw_melee_range:render("Display Melee Range",
                    "Draw melee range circle")
                menu_elements.draw_cursor_target:render("Display Cursor Target", cursor_target_description)
                menu_elements.draw_enemy_circles:render("Display Enemy Circles",
                    "Draw enemy circles")
                menu_elements.draw_weighted_scores:render("Display Weighted Scores",
                    "Draw target scores when weighted targeting is enabled")
                menu_elements.debug_tree:pop()
            end
        end

        menu_elements.settings_tree:pop()
    end

    local equipped_spells = get_equipped_spell_ids()

    -- Check for teleport_ench buff (buff_id 516547)
    local has_teleport_ench_buff = false
    local player_buffs = local_player:get_buffs()
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
        -- Check each spell in spell_data to find matching spell_id
        for spell_name, data in pairs(spell_data) do
            if data.spell_id == spell_id then
                equipped_lookup[spell_name] = true
                break
            end
        end
    end

    if menu_elements.spells_tree:push("Equipped Spells") then
        -- Display spells in priority order, but only if they're equipped
        for _, spell_name in ipairs(current_spell_priority) do
            if equipped_lookup[spell_name] then
                local spell = spells[spell_name]
                if spell then
                    spell.menu()
                end
            end
        end
        menu_elements.spells_tree:pop()
    end

    if menu_elements.disabled_spells_tree:push("Inactive Spells") then
        for _, spell_name in ipairs(current_spell_priority) do
            local spell = spells[spell_name]
            if spell and (not equipped_lookup[spell_name] or not spell.menu_elements.main_boolean:get()) then
                spell.menu()
            end
        end
        menu_elements.disabled_spells_tree:pop()
    end

    menu_elements.main_tree:pop();
end)

-- Initialize logger if file logging is enabled
if menu_elements.file_logging_enabled:get() and not logger.is_ready() then
    logger.init()
elseif not menu_elements.file_logging_enabled:get() and logger.is_ready() then
    logger.close()
end

-- Set global debug flag based on menu setting
_G.__sorc_debug__ = menu_elements.enable_debug:get()

-- Targets
local best_ranged_target = nil
local best_ranged_target_visible = nil
local best_melee_target = nil
local best_melee_target_visible = nil
local closest_target = nil
local closest_target_visible = nil
local best_cursor_target = nil
local closest_cursor_target = nil
local closest_cursor_target_angle = 0
-- Targetting scores
local ranged_max_score = 0
local ranged_max_score_visible = 0
local melee_max_score = 0
local melee_max_score_visible = 0
local cursor_max_score = 0

-- Targetting settings
local max_targeting_range = menu_elements.max_targeting_range:get()
local collision_table = { true, 1 } -- collision width
local floor_table = { true, 5.0 }   -- floor height
local angle_table = { false, 90.0 } -- max angle

-- Cache for heavy function results
local next_target_update_time = 0.0 -- Time of next target evaluation
local cast_end_time = 0.0          -- Time when casting is allowed again
local targeting_refresh_interval = menu_elements.targeting_refresh_interval:get()

-- Default enemy weights for different enemy types
local normal_monster_value = 2
local elite_value = 10
local champion_value = 15
local boss_value = 50
local damage_resistance_value = 25

local target_selector_data_all = nil

local function evaluate_targets(target_list, melee_range)
    local best_ranged_target = nil
    local best_melee_target = nil
    local best_cursor_target = nil
    local closest_cursor_target = nil
    local closest_cursor_target_angle = 0
    local ranged_max_score = 0
    local ranged_max_score_visible = 0
    local melee_max_score = 0
    local melee_max_score_visible = 0
    local cursor_max_score = 0

    for _, target in ipairs(target_list) do
        if target:is_enemy() and target:is_alive() then
            local target_position = target:get_position()
            local player_position = get_player_position()
            local distance_sqr = player_position:squared_dist_to_ignore_z(target_position)
            local distance = math.sqrt(distance_sqr)

            -- Skip if out of max range
            if distance > max_targeting_range then
                goto continue
            end

            -- Calculate score based on enemy type and distance
            local enemy_score = 0
            if target:is_boss() then
                enemy_score = menu_elements.enemy_weight_boss:get()
            elseif target:is_champion() then
                enemy_score = menu_elements.enemy_weight_champion:get()
            elseif target:is_elite() then
                enemy_score = menu_elements.enemy_weight_elite:get()
            else
                enemy_score = menu_elements.enemy_weight_normal:get()
            end

            -- Check for damage resistance aura
            local buffs = buff_cache.get_buffs(target)
            for _, buff in ipairs(buffs or {}) do
                if buff.name_hash == spell_data.enemies.damage_resistance.spell_id then
                    if buff.type == spell_data.enemies.damage_resistance.buff_ids.receiver then
                        enemy_score = enemy_score + menu_elements.enemy_weight_damage_resistance:get()
                        break
                    end
                end
            end

            -- Distance factor (closer = higher score)
            local distance_factor = 1.0 / (1.0 + distance * 0.1)
            enemy_score = enemy_score * distance_factor

            -- Enemy count in evaluation radius
            local enemy_count_in_radius = my_utility.enemy_count_in_range(target_position,
                menu_elements.best_target_evaluation_radius:get(), target_list)
            enemy_score = enemy_score * (1.0 + enemy_count_in_radius * 0.1)

            -- Proximity bonus (nearby enemies in comparison radius)
            local nearby_enemies = my_utility.enemy_count_in_range(target_position,
                menu_elements.comparison_radius:get() or 1.5, target_list)
            enemy_score = enemy_score * (1.0 + nearby_enemies * 0.1)

            -- Visibility
            local is_visible = target:is_visible()
            local is_in_line_of_sight = utility.is_in_line_of_sight(player_position, target_position, collision_table,
                floor_table, angle_table)

            -- Ranged targeting
            if distance <= max_targeting_range then
                if is_visible and is_in_line_of_sight then
                    if enemy_score > ranged_max_score_visible then
                        ranged_max_score_visible = enemy_score
                        best_ranged_target_visible = target
                    end
                end
                if enemy_score > ranged_max_score then
                    ranged_max_score = enemy_score
                    best_ranged_target = target
                end
            end

            -- Melee targeting
            if distance <= melee_range then
                if is_visible and is_in_line_of_sight then
                    if enemy_score > melee_max_score_visible then
                        melee_max_score_visible = enemy_score
                        best_melee_target_visible = target
                    end
                end
                if enemy_score > melee_max_score then
                    melee_max_score = enemy_score
                    best_melee_target = target
                end
            end

            -- Cursor targeting
            local cursor_position = graphics.get_cursor_world_position()
            local cursor_distance_sqr = cursor_position:squared_dist_to_ignore_z(target_position)
            local cursor_distance = math.sqrt(cursor_distance_sqr)
            if cursor_distance <= menu_elements.cursor_targeting_radius:get() then
                local cursor_angle = math.abs(math.atan2(cursor_position:y() - player_position:y(),
                    cursor_position:x() - player_position:x()) -
                    math.atan2(target_position:y() - player_position:y(),
                        target_position:x() - player_position:x()))
                cursor_angle = math.min(cursor_angle, 2 * math.pi - cursor_angle)
                cursor_angle = cursor_angle * 180 / math.pi -- Convert to degrees

                if cursor_angle <= menu_elements.cursor_targeting_angle:get() then
                    if enemy_score > cursor_max_score then
                        cursor_max_score = enemy_score
                        best_cursor_target = target
                    end
                end

                -- Closest cursor target
                if closest_cursor_target == nil or cursor_distance < closest_cursor_target_distance then
                    closest_cursor_target = target
                    closest_cursor_target_distance = cursor_distance
                    closest_cursor_target_angle = cursor_angle
                end
            end

            ::continue::
        end
    end

    return best_ranged_target, best_ranged_target_visible, best_melee_target, best_melee_target_visible,
        best_cursor_target, closest_cursor_target, closest_cursor_target_angle,
        ranged_max_score, ranged_max_score_visible, melee_max_score, melee_max_score_visible, cursor_max_score
end

on_update(function()
    -- Live logger toggle (menu driven)
    if menu_elements.file_logging_enabled:get() then
        if not logger.is_ready() then logger.init() end
    elseif logger.is_ready() then
        logger.close()
    end

    if not menu_elements.main_boolean:get() then
        return
    end

    if not my_utility.is_action_allowed() then
        return
    end

    local current_time = get_time_since_inject()
    if current_time < cast_end_time then
        return
    end

    -- Update targeting if needed
    if current_time >= next_target_update_time then
        local player_position = get_player_position()
        max_targeting_range = menu_elements.max_targeting_range:get()

        local entity_list_visible, entity_list = my_target_selector.get_target_list(
            player_position,
            max_targeting_range,
            collision_table,
            floor_table,
            angle_table)

        target_selector_data_all = my_target_selector.get_target_selector_data(
            player_position,
            entity_list)

        local target_selector_data_visible = my_target_selector.get_target_selector_data(
            player_position,
            entity_list_visible)

        if target_selector_data_all and target_selector_data_all.is_valid then
            local melee_range = my_utility.get_melee_range()

            -- Update enemy weights
            if menu_elements.custom_enemy_weights:get() then
                normal_monster_value = menu_elements.enemy_weight_normal:get()
                elite_value = menu_elements.enemy_weight_elite:get()
                champion_value = menu_elements.enemy_weight_champion:get()
                boss_value = menu_elements.enemy_weight_boss:get()
                damage_resistance_value = menu_elements.enemy_weight_damage_resistance:get()
            else
                normal_monster_value = 2
                elite_value = 10
                champion_value = 15
                boss_value = 50
                damage_resistance_value = 25
            end

            -- Check all targets within max range
            best_ranged_target, best_melee_target, best_cursor_target, closest_cursor_target, ranged_max_score, melee_max_score, cursor_max_score, closest_cursor_target_angle = evaluate_targets(target_selector_data_all.list, melee_range)

            -- Weighted targeting optional override (aligned with paladin pattern)
            if menu_elements.weighted_targeting_enabled:get() then
                local weighted_target = my_target_selector.get_weighted_target(
                    player_position,
                    menu_elements.scan_radius:get(),
                    menu_elements.min_targets:get(),
                    menu_elements.comparison_radius:get(),
                    menu_elements.enemy_weight_boss:get(),
                    menu_elements.enemy_weight_elite:get(),
                    menu_elements.enemy_weight_champion:get(),
                    menu_elements.enemy_weight_normal:get(),
                    menu_elements.scan_refresh_rate:get(),
                    menu_elements.enemy_weight_damage_resistance:get(),
                    5,    -- damage_resistance_receiver_penalty (modest default)
                    50,   -- horde_objective_weight default
                    1,    -- vulnerable_debuff_weight default
                    menu_elements.min_targets:get(), -- cluster_min_target_count
                    1, 5, 5, 5, -- normal/champ/elite/boss target counts
                    menu_elements.weighted_targeting_debug:get())

                if weighted_target then
                    best_ranged_target = weighted_target
                    best_melee_target = weighted_target
                    best_cursor_target = weighted_target
                    closest_cursor_target = weighted_target
                    closest_target = weighted_target
                end
            end

            -- Check visible targets within max range
            best_ranged_target_visible, best_melee_target_visible, _, _, ranged_max_score_visible, melee_max_score_visible, _ = evaluate_targets(target_selector_data_visible.list, melee_range)

            closest_target = closest_target or target_selector_data_all.closest_unit
            closest_target_visible = closest_target_visible or target_selector_data_visible.closest_unit
        end

        next_target_update_time = current_time + targeting_refresh_interval
    end

    -- Helper to select target per spell using paladin-aligned maps
    local function select_target(spell)
        local target_unit = nil
        if spell.menu_elements.priority_target and spell.menu_elements.priority_target:get() then
            -- Priority targeting: prefer boss > champion > elite > any
            if best_ranged_target and (best_ranged_target:is_boss() or best_ranged_target:is_champion() or best_ranged_target:is_elite()) then
                return best_ranged_target
            end
        end
        if spell.menu_elements.targeting_mode then
            local targeting_mode = spell.menu_elements.targeting_mode:get()

            if spell.targeting_type == "melee" then
                local map = {
                    [0] = 3, -- best melee target
                    [1] = 4, -- best melee visible
                    [2] = 5, -- closest
                    [3] = 6, -- closest visible
                    [4] = 7, -- best cursor
                    [5] = 8  -- closest cursor
                }
                targeting_mode = map[targeting_mode] or 3
            else -- default ranged
                local map = {
                    [0] = 1, -- best ranged
                    [1] = 2, -- best ranged visible
                    [2] = 5, -- closest
                    [3] = 6, -- closest visible
                    [4] = 7, -- best cursor
                    [5] = 8  -- closest cursor
                }
                targeting_mode = map[targeting_mode] or 1
            end

            target_unit = ({
                [1] = best_ranged_target,
                [2] = best_ranged_target_visible,
                [3] = best_melee_target,
                [4] = best_melee_target_visible,
                [5] = closest_target,
                [6] = closest_target_visible,
                [7] = best_cursor_target,
                [8] = closest_cursor_target
            })[targeting_mode]
        else
            target_unit = best_ranged_target
        end
        return target_unit
    end

    -- Spell parameters for flexible argument passing
    local spell_params = {
        fireball = { args = {nil} },  -- Will be set to target_unit
        blizzard = { args = {nil, nil} },  -- target, target_selector_data
        inferno = { args = {nil, nil} },  -- target, target_selector_data
        firewall = { args = {nil, nil} },  -- target, target_selector_data
        meteor = { args = {nil} },
        -- Default for others: { args = {nil} }
    }

    local function use_ability(spell_name)
        local spell = spells[spell_name]
        if not spell or not spell.menu_elements.main_boolean:get() then
            return false
        end

        local target_unit = select_target(spell)
        local params = spell_params[spell_name] or { args = {target_unit} }
        params.args[1] = target_unit  -- Set target
        if #params.args > 1 then
            params.args[2] = target_selector_data_all  -- For spells needing data
        end
        local ok, cast_result, cooldown = pcall(spell.logics, unpack(params.args))
        if not ok then
            if _G.__sorc_debug__ then
                console.print("[ERROR] Spell logic failed for " .. spell_name .. ": " .. tostring(cast_result))
            end
            return false
        end

        if cast_result then
            local cd = cooldown or my_utility.spell_delays.regular_cast
            cast_end_time = current_time + cd
            return true
        end
        return false
    end

    -- Cast spells in priority order
    for _, spell_name in ipairs(current_spell_priority) do
        if use_ability(spell_name) then
            return
        end
    end
end)

on_render(function()
    if not menu_elements.main_boolean:get() or not menu_elements.enable_debug:get() then
        return
    end

    local player_position = get_player_position()
    local player_screen_position = graphics.w2s(player_position)

    -- Draw max range
    max_targeting_range = menu_elements.max_targeting_range:get()
    if menu_elements.draw_max_range:get() then
        graphics.circle_3d(player_position, max_targeting_range, color_white(85), 2.5, 144)
    end

    -- Draw melee range
    if menu_elements.draw_melee_range:get() then
        local melee_range = my_utility.get_melee_range()
        graphics.circle_3d(player_position, melee_range, color_white(85), 2.5, 144)
    end

    -- Draw enemy circles
    if menu_elements.draw_enemy_circles:get() then
        local success, enemies = pcall(actors_manager.get_enemy_npcs)
        if success and enemies then
            for i, obj in ipairs(enemies) do
                local position = obj:get_position()
                if position then
                    graphics.circle_3d(position, 1, color_white(100))

                    local future_position = prediction.get_future_unit_position(obj, 0.4)
                    if future_position then
                        graphics.circle_3d(future_position, 0.25, color_yellow(100))
                    end
                end
            end
        end
    end

    -- Draw targets
    if menu_elements.draw_targets:get() then
        -- Draw ranged target
        if best_ranged_target and best_ranged_target:is_enemy() then
            local best_ranged_target_position = best_ranged_target:get_position();
            local best_ranged_target_position_2d = graphics.w2s(best_ranged_target_position);
            local target_evaluation_radius_alpha = 50
            if best_ranged_target_visible then
                graphics.line(best_ranged_target_position_2d, player_screen_position, color_red(255), 2.5)
                graphics.circle_3d(best_ranged_target_position, 0.70, color_red(255), 2.0);
                graphics.circle_3d(best_ranged_target_position, menu_elements.best_target_evaluation_radius:get(),
                    color_white(target_evaluation_radius_alpha), 1);
                local text_position = vec2:new(best_ranged_target_position_2d.x,
                    best_ranged_target_position_2d.y - 20)
                graphics.text_2d("RANGED - Score:" .. ranged_max_score, text_position, 12, color_red_pale(255))
            else
                graphics.line(best_ranged_target_position_2d, player_screen_position, color_red(100), 2.5)
                graphics.circle_3d(best_ranged_target_position, 0.70, color_red(100), 2.0);
                graphics.circle_3d(best_ranged_target_position, menu_elements.best_target_evaluation_radius:get(),
                    color_white(target_evaluation_radius_alpha), 1);
                local text_position = vec2:new(best_ranged_target_position_2d.x,
                    best_ranged_target_position_2d.y - 20)
                graphics.text_2d("RANGED - Score:" .. ranged_max_score, text_position, 12, color_red_pale(100))
            end
        end

        -- Draw visible melee target
        if best_melee_target_visible and best_melee_target_visible:is_enemy() then
            local best_melee_target_visible_position = best_melee_target_visible:get_position();
            local best_melee_target_visible_position_2d = graphics.w2s(best_melee_target_visible_position);
            graphics.line(best_melee_target_visible_position_2d, player_screen_position, color_green(255), 2.5)
            graphics.circle_3d(best_melee_target_visible_position, 0.70, color_green(255), 2.0);
            graphics.circle_3d(best_melee_target_visible_position, menu_elements.best_target_evaluation_radius:get(),
                color_white(50), 1);
            local text_position = vec2:new(best_melee_target_visible_position_2d.x,
                best_melee_target_visible_position_2d.y - 40)
            graphics.text_2d("MELEE - Score:" .. melee_max_score_visible, text_position, 12, color_green(255))
        end

        -- Draw closest target
        if closest_target and closest_target:is_enemy() then
            local closest_target_position = closest_target:get_position();
            local closest_target_position_2d = graphics.w2s(closest_target_position);
            if closest_target_visible then
                graphics.line(closest_target_position_2d, player_screen_position, color_cyan(255), 2.5)
                graphics.circle_3d(closest_target_position, 0.70, color_cyan(255), 2.0);
                local text_position = vec2:new(closest_target_position_2d.x,
                    closest_target_position_2d.y - 60)
                graphics.text_2d("CLOSEST", text_position, 12, color_cyan(255))
            else
                graphics.line(closest_target_position_2d, player_screen_position, color_cyan(100), 2.5)
                graphics.circle_3d(closest_target_position, 0.70, color_cyan(100), 2.0);
                local text_position = vec2:new(closest_target_position_2d.x,
                    closest_target_position_2d.y - 60)
                graphics.text_2d("CLOSEST", text_position, 12, color_cyan(100))
            end
        end
    end

    -- Draw cursor targets
    if menu_elements.draw_cursor_target:get() then
        -- Draw best cursor target
        if best_cursor_target and best_cursor_target:is_enemy() then
            local best_cursor_target_position = best_cursor_target:get_position();
            local best_cursor_target_position_2d = graphics.w2s(best_cursor_target_position);
            graphics.pentagon_3d(best_cursor_target_position, 0.70, color_orange(255), 2.0);
            local text_position = vec2:new(best_cursor_target_position_2d.x,
                best_cursor_target_position_2d.y - 80)
            graphics.text_2d("BEST_CURSOR_TARGET - Score:" .. cursor_max_score, text_position, 12, color_orange(255))
        end

        -- Draw closest cursor target
        if closest_cursor_target and closest_cursor_target:is_enemy() then
            local closest_cursor_target_position = closest_cursor_target:get_position();
            local closest_cursor_target_position_2d = graphics.w2s(closest_cursor_target_position);
            graphics.pentagon_3d(closest_cursor_target_position, 0.70, color_green_pastel(255), 2.0);
            local text_position = vec2:new(closest_cursor_target_position_2d.x,
                closest_cursor_target_position_2d.y - 100)
            graphics.text_2d("CLOSEST_CURSOR_TARGET - Angle:" .. string.format("%.1f", closest_cursor_target_angle),
                text_position, 12, color_green_pastel(255))
        end
    end
end);

-- Additional debug: Draw weighted scores if enabled
if menu_elements.enable_debug:get() and menu_elements.draw_weighted_scores:get() and menu_elements.weighted_targeting_enabled:get() then
    -- This would require storing scores per target, for now just note it's enabled
    -- In a full implementation, modify evaluate_targets to return a map of targets to scores
end

console.print("Lua Plugin - Sorcerer Dirty - Version 1.0.4")