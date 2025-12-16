local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 0.0  -- Self-cast AoE
local targeting_type = "self"
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "unstable_current_main_bool_base")),
    min_enemies         = slider_int:new(1, 30, 5, get_hash(my_utility.plugin_label .. "unstable_current_min_enemies")),
    min_mana_percent    = slider_float:new(0.0, 1.0, 0.3,
        get_hash(my_utility.plugin_label .. "unstable_current_min_mana_percent")),
    debug_mode          = checkbox:new(false, get_hash(my_utility.plugin_label .. "unstable_current_debug_mode"))
}

local function menu()
    if menu_elements.tree_tab:push("Unstable Current") then
        menu_elements.main_boolean:render("Enable Unstable Current", "Lightning ultimate that chains between enemies")
        menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        if menu_elements.main_boolean:get() then
            menu_elements.min_enemies:render("Minimum Enemies", "Minimum number of enemies in range to cast")
            menu_elements.min_mana_percent:render("Min Mana %", "Minimum mana percentage required to cast", 1)
        end
        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target)
    -- Unstable Current is a self-cast AoE ultimate - doesn't need a target
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_data.unstable_current.spell_id);
    if not is_logic_allowed then return false, 0 end;

    -- Mana check
    local local_player = get_local_player()
    local mana_pct = local_player:get_primary_resource_current() / local_player:get_primary_resource_max()
    if mana_pct < menu_elements.min_mana_percent:get() then
        return false, 0
    end

    -- Check for minimum enemies in range
    local player_position = get_player_position();
    local enemies_in_range = my_utility.enemy_count_in_range(player_position, spell_data.unstable_current.data.radius); -- Unstable Current range
    if enemies_in_range < menu_elements.min_enemies:get() then
        return false, 0;
    end

    local debug_enabled = menu_elements.debug_mode:get();
    if debug_enabled then
        console.print("[SPELL DEBUG] Unstable Current - Casting on " .. enemies_in_range .. " enemies");
    end

    if cast_spell.self(spell_data.unstable_current.spell_id, 0) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;
        if debug_enabled then
            console.print("[SPELL DEBUG] Unstable Current - Cast successful");
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