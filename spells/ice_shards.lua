local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = spell_data.ice_shards.data.range
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "ice_shards_main_boolean")),
    targeting_mode      = combo_box:new(0, get_hash(my_utility.plugin_label .. "ice_shards_targeting_mode")),
    min_target_range    = slider_float:new(1.0, 20.0, 5.0, get_hash(my_utility.plugin_label .. "ice_shards_min_target_range")),
    priority_target     = checkbox:new(false, get_hash(my_utility.plugin_label .. "ice_shards_priority_target")),
    min_mana_percent    = slider_float:new(0.0, 1.0, 0.1,
        get_hash(my_utility.plugin_label .. "ice_shards_min_mana_percent")),
    debug_mode          = checkbox:new(false, get_hash(my_utility.plugin_label .. "ice_shards_debug_mode"))
}

local function menu()
    
    if menu_elements.tree_tab:push("Ice Shards")then
        menu_elements.main_boolean:render("Enable Ice Shards", "Fast casting ice projectile")
        menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes, "")
            menu_elements.min_target_range:render("Min Target Range", "", 1)
            menu_elements.priority_target:render("Priority Target", "Prioritize this spell when target is marked")
            menu_elements.min_mana_percent:render("Min Mana %", "Minimum mana percentage required to cast", 1)
        end
 
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
    
    local debug_enabled = menu_elements.debug_mode:get();
    
    -- Mana check
    local local_player = get_local_player()
    local mana_pct = local_player:get_primary_resource_current() / local_player:get_primary_resource_max()
    if mana_pct < menu_elements.min_mana_percent:get() then
        if debug_enabled then
            console.print("[ICE SHARDS DEBUG] Insufficient mana: " .. string.format("%.1f", mana_pct * 100) .. "%")
        end
        return false, 0
    end
    
    if not target then
        return false;
    end;

    if debug_enabled then
        console.print("[SPELL DEBUG] Ice Shards - Casting on target");
    end

    if cast_spell.target(target, spell_data.ice_shards.spell_id, false) then

        local current_time = get_time_since_inject();
        local cooldown = 0.1;
        next_time_allowed_cast = current_time + cooldown;
        if debug_enabled then
            console.print("[SPELL DEBUG] Ice Shards - Cast successful");
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
    targeting_type = "ranged"
}
