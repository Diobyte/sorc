local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 0.0  -- Self-cast
local targeting_type = "self"
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "ice_armor_main_bool_base")),
    min_enemies         = slider_int:new(1, 20, 1, get_hash(my_utility.plugin_label .. "ice_armor_min_enemies")),
}

local function menu()
    if menu_elements.tree_tab:push("Ice Armor") then
        menu_elements.main_boolean:render("Enable Ice Armor", "Defensive armor that provides cold damage reduction")
        if menu_elements.main_boolean:get() then
            menu_elements.min_enemies:render("Minimum Enemies", "Minimum number of enemies in range to cast")
        end
        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target)
    -- Ice Armor is a self-cast defensive spell - doesn't need a target
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_data.ice_armor.spell_id);
    if not is_logic_allowed then return false end;

    local player_position = get_player_position();
    local enemies_in_range = my_utility.enemy_count_in_range(player_position, 10.0);
    if enemies_in_range < menu_elements.min_enemies:get() then
        return false;
    end

    if cast_spell.self(spell_data.ice_armor.spell_id, 0) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;
        if _G.__sorc_debug__ then
            console.print("Cast Ice Armor");
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
