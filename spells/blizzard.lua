local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = spell_data.blizzard.data.range
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "blizzard_main_bool_base")),
    targeting_mode      = combo_box:new(0, get_hash(my_utility.plugin_label .. "blizzard_targeting_mode")),
    min_target_range    = slider_float:new(1, max_spell_range - 1, 3,
        get_hash(my_utility.plugin_label .. "blizzard_min_target_range")),
    min_max_targets     = slider_int:new(1, 10, 3, get_hash(my_utility.plugin_label .. "blizzard_min_max_targets")),
    min_mana_percent    = slider_float:new(0.1, 1.0, 0.2, get_hash(my_utility.plugin_label .. "blizzard_min_mana")),
    debug_mode          = checkbox:new(false, get_hash(my_utility.plugin_label .. "blizzard_debug_mode"))
}

local function menu()
    if menu_elements.tree_tab:push("Blizzard") then
        menu_elements.main_boolean:render("Enable Blizzard", "Ground-targeted AoE ultimate that damages and slows enemies")
        menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_ranged,
                my_utility.targeting_mode_description)
            menu_elements.min_target_range:render("Min Target Distance",
                "\n     Must be lower than Max Targeting Range     \n\n", 1)
            menu_elements.min_max_targets:render("Minimum Targets", "Minimum number of enemies in AoE to cast")
            menu_elements.min_mana_percent:render("Min Mana Percent", "Minimum mana percentage to cast", 1)
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target, target_selector_data)
    if not target then return false end;
    local menu_boolean = menu_elements.main_boolean:get();
    local debug_enabled = menu_elements.debug_mode:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.blizzard.spell_id);

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[BLIZZARD DEBUG] Logic not allowed - spell conditions not met")
        end
        return false
    end;

    -- Mana check
    local local_player = get_local_player()
    local mana_pct = local_player:get_primary_resource_current() / local_player:get_primary_resource_max()
    if mana_pct < menu_elements.min_mana_percent:get() then
        if debug_enabled then
            console.print("[BLIZZARD DEBUG] Insufficient mana: " .. string.format("%.1f", mana_pct * 100) .. "% < " .. string.format("%.1f", menu_elements.min_mana_percent:get() * 100) .. "%")
        end
        return false
    end

    -- Use optimal AoE positioning
    local area_data = target_selector.get_most_hits_target_circular_area_light(get_player_position(), max_spell_range, spell_data.blizzard.data.radius)
    local best_target = area_data.main_target
    local enemies_in_aoe = area_data.n_hits
    if not best_target or enemies_in_aoe < menu_elements.min_max_targets:get() then
        if debug_enabled then
            console.print("[BLIZZARD DEBUG] Not enough targets in AOE: " .. enemies_in_aoe .. " < " .. menu_elements.min_max_targets:get())
        end
        return false
    end

    local cast_pos = my_utility.get_best_point(best_target:get_position(), spell_data.blizzard.data.radius, area_data.victim_list)

    if cast_spell.position(spell_data.blizzard.spell_id, cast_pos, 0) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;
        if debug_enabled then
            console.print("Cast Blizzard - Target: " ..
                my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] ..
                ", Enemies: " .. enemies_in_aoe);
        end
        return true, my_utility.spell_delays.regular_cast;
    end;

    return false, 0;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    targeting_type = targeting_type
}
