local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = spell_data.fireball.data.range
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "fireball_main_bool_base")),
    targeting_mode      = combo_box:new(0, get_hash(my_utility.plugin_label .. "fireball_targeting_mode")),
    min_target_range    = slider_float:new(1, max_spell_range - 1, 3,
        get_hash(my_utility.plugin_label .. "fireball_min_target_range")),
    priority_target     = checkbox:new(false, get_hash(my_utility.plugin_label .. "fireball_priority_target")),
    debug_mode          = checkbox:new(false, get_hash(my_utility.plugin_label .. "fireball_debug_mode")),
    min_mana_percent    = slider_float:new(0.1, 1.0, 0.2, get_hash(my_utility.plugin_label .. "fireball_min_mana"))
}

local function menu()
    if menu_elements.tree_tab:push("Fireball") then
        menu_elements.main_boolean:render("Enable Fireball", "")
        menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_ranged,
                my_utility.targeting_mode_description)
            menu_elements.min_target_range:render("Min Target Distance",
                "\n     Must be lower than Max Targeting Range     \n\n", 1)
            menu_elements.priority_target:render("Priority Targeting", "Targets Boss > Champion > Elite > Any")
            menu_elements.min_mana_percent:render("Min Mana Percent", "Minimum mana percentage to cast", 1)
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
        spell_data.fireball.spell_id);

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[FIREBALL DEBUG] Logic not allowed - spell conditions not met")
        end
        return false, 0
    end

    -- Mana check
    local local_player = get_local_player()
    local mana_pct = local_player:get_primary_resource_current() / local_player:get_primary_resource_max()
    if mana_pct < menu_elements.min_mana_percent:get() then
        if debug_enabled then
            console.print("[FIREBALL DEBUG] Insufficient mana: " .. string.format("%.1f", mana_pct * 100) .. "%")
        end
        return false, 0
    end;

    if not my_utility.is_in_range(target, max_spell_range) or my_utility.is_in_range(target, menu_elements.min_target_range:get()) then
        if debug_enabled then
            console.print("[FIREBALL DEBUG] Target out of range")
        end
        return false, 0
    end

    if cast_spell.target(target, spell_data.fireball.spell_id, 0) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;
        if debug_enabled then
            console.print("Cast Fireball - Target: " ..
                my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1]);
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
