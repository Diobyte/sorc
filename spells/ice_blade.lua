local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 0.0  -- Self-cast
local targeting_type = "self"
local menu_elements = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "ice_blade_main_boolean")),
    min_enemies           = slider_int:new(1, 20, 1, get_hash(my_utility.plugin_label .. "ice_blade_min_enemies")),
    use_custom_cooldown   = checkbox:new(false, get_hash(my_utility.plugin_label .. "ice_blade_use_custom_cooldown")),
    custom_cooldown_sec   = slider_float:new(1.0, 10.0, 3.0, get_hash(my_utility.plugin_label .. "ice_blade_custom_cooldown_sec")),
    debug_mode            = checkbox:new(false, get_hash(my_utility.plugin_label .. "ice_blade_debug_mode"))
}

local function menu()
    if menu_elements.tree_tab:push("Ice Blade")then
        menu_elements.main_boolean:render("Enable Ice Blade", "Enhances weapon with ice damage")
        menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        if menu_elements.main_boolean:get() then
            menu_elements.min_enemies:render("Minimum Enemies", "Minimum number of enemies in range to cast")
            menu_elements.use_custom_cooldown:render("Use Custom Cooldown", "Override default cooldown")
            if menu_elements.use_custom_cooldown:get() then
                menu_elements.custom_cooldown_sec:render("Custom Cooldown (sec)", "", 1)
            end
        end
        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0.0

local function logics(target)
    local menu_boolean = menu_elements.main_boolean:get();
    local debug_enabled = menu_elements.debug_mode:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_data.ice_blade.spell_id);

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[ICE BLADE DEBUG] Logic not allowed - spell conditions not met")
        end
        return false;
    end;

    local player_position = get_player_position();
    local enemies_in_range = my_utility.enemy_count_in_range(player_position, 15.0);
    if enemies_in_range < menu_elements.min_enemies:get() then
        if debug_enabled then
            console.print("[ICE BLADE DEBUG] Not enough enemies: " .. enemies_in_range .. " < " .. menu_elements.min_enemies:get())
        end
        return false;
    end

    if cast_spell.self(spell_data.ice_blade.spell_id, 0.0) then
        local current_time = get_time_since_inject();
        local cooldown = menu_elements.use_custom_cooldown:get() and menu_elements.custom_cooldown_sec:get() or my_utility.spell_delays.regular_cast;
        next_time_allowed_cast = current_time + cooldown;
        if debug_enabled then
            console.print("Cast Ice Blade - Cooldown: " .. cooldown .. "s");
        end
        return true, cooldown;
    end;

    return false, 0;
end

return 
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    targeting_type = "self"
}
