local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 0.0  -- Self-cast AoE
local targeting_type = "self"
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "deep_freeze_main_bool_base")),
    min_enemies         = slider_int:new(1, 10, 3, get_hash(my_utility.plugin_label .. "deep_freeze_min_enemies")),
    debug_mode          = checkbox:new(false, get_hash(my_utility.plugin_label .. "deep_freeze_debug_mode"))
}

local function menu()
    if menu_elements.tree_tab:push("Deep Freeze") then
        menu_elements.main_boolean:render("Enable Deep Freeze", "AoE stun that freezes enemies in place")
        menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        if menu_elements.main_boolean:get() then
            menu_elements.min_enemies:render("Minimum Enemies", "Minimum number of enemies in range to cast")
        end
        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target)
    -- Deep Freeze is a self-cast AoE stun - doesn't need a target
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_data.deep_freeze.spell_id);
    if not is_logic_allowed then return false end;

    -- Check for minimum enemies in range
    local player_position = get_player_position();
    local enemies_in_range = my_utility.enemy_count_in_range(player_position, spell_data.deep_freeze.data.radius); -- Deep Freeze radius
    if enemies_in_range < menu_elements.min_enemies:get() then
        return false;
    end

    local debug_enabled = menu_elements.debug_mode:get();
    if debug_enabled then
        console.print("[SPELL DEBUG] Deep Freeze - Casting on " .. enemies_in_range .. " enemies");
    end

    if cast_spell.self(spell_data.deep_freeze.spell_id, 0) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;
        if debug_enabled then
            console.print("[SPELL DEBUG] Deep Freeze - Cast successful");
        end
        return true;
    end;

    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    targeting_type = targeting_type
}
