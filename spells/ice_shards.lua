local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = spell_data.ice_shards.data.range
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "ice_shards_main_boolean")),
    targeting_mode      = combo_box:new(0, get_hash(my_utility.plugin_label .. "ice_shards_targeting_mode")),
    min_target_range    = slider_float:new(1.0, 20.0, 5.0, get_hash(my_utility.plugin_label .. "ice_shards_min_target_range"))
}

local function menu()
    
    if menu_elements.tree_tab:push("Ice Shards")then
        menu_elements.main_boolean:render("Enable Spell", "")
        menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes, "")
        menu_elements.min_target_range:render("Min Target Range", "", 1)
 
        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0.0;
local function logics(target)
    
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_data.ice_shards.spell_id);

    if not is_logic_allowed then
        return false;
    end;
    
    if not target then
        return false;
    end;

    if cast_spell.target(target, spell_data.ice_shards.spell_id, false) then

        local current_time = get_time_since_inject();
        local cooldown = 0.1;
        next_time_allowed_cast = current_time + cooldown;

        return true;
    end;

    return false;
end


return 
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    targeting_type = "ranged"
}
