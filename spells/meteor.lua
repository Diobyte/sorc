local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")
local my_target_selector = require("my_utility/my_target_selector")

local max_spell_range = spell_data.meteor.data.range
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "meteor_main_bool_base")),
    targeting_mode      = combo_box:new(0, get_hash(my_utility.plugin_label .. "meteor_targeting_mode")),
    min_target_range    = slider_float:new(1, max_spell_range - 1, 3,
        get_hash(my_utility.plugin_label .. "meteor_min_target_range")),
    min_max_targets     = slider_int:new(1, 10, 3, get_hash(my_utility.plugin_label .. "meteor_min_max_targets")),
    debug_mode          = checkbox:new(false, get_hash(my_utility.plugin_label .. "meteor_debug_mode"))
}

local function menu()
    if menu_elements.tree_tab:push("Meteor") then
        menu_elements.main_boolean:render("Enable Meteor", "Ground-targeted AoE ultimate that deals massive fire damage")
        menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_ranged,
                my_utility.targeting_mode_description)
            menu_elements.min_target_range:render("Min Target Distance",
                "\n     Must be lower than Max Targeting Range     \n\n", 1)
            menu_elements.min_max_targets:render("Min Max Targets", "Minimum number of targets to hit", 1)
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target)
    if not target then return false end;
    local menu_boolean = menu_elements.main_boolean:get();
    local debug_enabled = menu_elements.debug_mode:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.meteor.spell_id);

    if not is_logic_allowed then 
        if debug_enabled then
            console.print("[SPELL DEBUG] Meteor - Logic not allowed");
        end
        return false 
    end;

    if not my_utility.is_in_range(target, max_spell_range) or my_utility.is_in_range(target, menu_elements.min_target_range:get()) then
        if debug_enabled then
            console.print("[SPELL DEBUG] Meteor - Target out of range");
        end
        return false, 0
    end

    local min_max_targets = menu_elements.min_max_targets:get();
    local target_pos = target:get_position();

    if min_max_targets > 1 then
        local area_data = my_target_selector.get_most_hits_circular(get_player_position(), max_spell_range, spell_data.meteor.data.radius);
        if area_data and area_data.score >= min_max_targets then
            target_pos = area_data.position;
            if debug_enabled then
                console.print("[SPELL DEBUG] Meteor - Using AoE position for " .. area_data.score .. " targets");
            end
        elseif debug_enabled then
            console.print("[SPELL DEBUG] Meteor - Not enough targets for AoE, using single target");
        end
    end

    if debug_enabled then
        console.print("[SPELL DEBUG] Meteor - Casting at position");
    end

    if cast_spell.position(spell_data.meteor.spell_id, target_pos, 0) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;
        if debug_enabled then
            console.print("[SPELL DEBUG] Meteor - Cast successful");
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
