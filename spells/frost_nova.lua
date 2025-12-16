local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 0.0  -- Self-cast AoE
local targeting_type = "self"
local menu_elements = 
{
    tree_tab           = tree_node:new(1),
    main_boolean       = checkbox:new(true, get_hash(my_utility.plugin_label .. "frost_nova_main_boolean")),
    min_max_targets    = slider_int:new(1, 10, 3, get_hash(my_utility.plugin_label .. "frost_nova_min_max_targets"))
}

local function menu()

    if menu_elements.tree_tab:push("Frost Nova") then
        menu_elements.main_boolean:render("Enable Spell", "")
        menu_elements.min_max_targets:render("Min Targets", "", 1)

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0.0;
local function logics(target)

    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_data.frost_nova.spell_id);

    if not is_logic_allowed then
        return false;
    end;

    local time = get_time_since_inject()
    if  time - next_time_allowed_cast < 0.2 then
        return false
    end

    local area_data = target_selector.get_most_hits_target_circular_area_heavy(get_player_position(), 3.66, 3.66)
    local amount_hits = area_data.n_hits

    if amount_hits < menu_elements.min_max_targets:get() then
        return false;
    end;

    if cast_spell.self(spell_data.frost_nova.spell_id, 0.15) then
        local cooldown = my_utility.spell_delays.regular_cast
        next_time_allowed_cast = time + cooldown
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
