local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 0.0  -- Self-cast AoE
local targeting_type = "self"
local menu_elements = 
{
    tree_tab           = tree_node:new(1),
    main_boolean       = checkbox:new(true, get_hash(my_utility.plugin_label .. "frost_nova_main_bool_base")),
    min_max_targets    = slider_int:new(1, 10, 3, get_hash(my_utility.plugin_label .. "frost_nova_min_max_targets")),
    debug_mode         = checkbox:new(false, get_hash(my_utility.plugin_label .. "frost_nova_debug_mode"))
}

local function menu()

    if menu_elements.tree_tab:push("Frost Nova") then
        menu_elements.main_boolean:render("Enable Frost Nova", "AoE frost spell that freezes enemies")
        menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        if menu_elements.main_boolean:get() then
            menu_elements.min_max_targets:render("Min Targets", "", 1)
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0.0;
local function logics(target)

    local menu_boolean = menu_elements.main_boolean:get();
    local debug_enabled = menu_elements.debug_mode:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_data.frost_nova.spell_id);

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[SPELL DEBUG] Frost Nova - Logic not allowed");
        end
        return false;
    end;

    local player_position = get_player_position();
    local enemies_in_range = my_utility.enemy_count_in_range(player_position, spell_data.frost_nova.data.radius)
    if enemies_in_range < menu_elements.min_max_targets:get() then
        if debug_enabled then
            console.print("[SPELL DEBUG] Frost Nova - Not enough enemies: " .. enemies_in_range .. " < " .. menu_elements.min_max_targets:get());
        end
        return false;
    end;

    if debug_enabled then
        console.print("[SPELL DEBUG] Frost Nova - Casting on " .. enemies_in_range .. " enemies");
    end

    if cast_spell.self(spell_data.frost_nova.spell_id, 0) then
        local current_time = get_time_since_inject();
        local cooldown = my_utility.spell_delays.regular_cast
        next_time_allowed_cast = current_time + cooldown
        if debug_enabled then
            console.print("[SPELL DEBUG] Frost Nova - Cast successful");
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
    targeting_type = "self"
}
