local my_utility = require("my_utility/my_utility");

local menu_elements_sorc_base = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_ice_armor")),
    debug_mode            = checkbox:new(false, get_hash(my_utility.plugin_label .. "ice_armor_debug_mode")),
    hp_usage_shield       = slider_float:new(0.0, 1.0, 0.30, get_hash(my_utility.plugin_label .. "%_in_which_shield_will_cast"))
}

local function menu()
    if menu_elements_sorc_base.tree_tab:push("Ice Armor") then
        menu_elements_sorc_base.main_boolean:render("Enable Spell", "")
        menu_elements_sorc_base.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")

       if menu_elements_sorc_base.main_boolean:get() then
        menu_elements_sorc_base.hp_usage_shield:render("Min cast HP Percent", "", 2)
       end

       menu_elements_sorc_base.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0.0;
local spell_id_ice_armor = 297039

local function is_flame_shield_active()
    local local_player = get_local_player()
    local buff_name_check = "Sorcerer_FlameShield"

    if not local_player then return false, 0 end

    local buffs = local_player:get_buffs()
    if not buffs then return false, 0 end

    for _, buff in ipairs(buffs) do
        if buff:name() == buff_name_check then
            return true, 0  -- Flame shield buff detected, no cooldown needed
        end
    end
    return false, 0
end

local function logics()
    local menu_boolean = menu_elements_sorc_base.main_boolean:get();
    local debug_enabled = menu_elements_sorc_base.debug_mode:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean,
                next_time_allowed_cast,
                spell_id_ice_armor);

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[ICE ARMOR DEBUG] Logic not allowed - spell conditions not met")
        end
        return false, 0;
    end;

    -- Check if Flame Shield is active
    if is_flame_shield_active() then
        if debug_enabled then
            console.print("[ICE ARMOR DEBUG] Flame Shield is active - skipping Ice Armor cast")
        end
        return false, 0;
    end

    local local_player = get_local_player();
    local player_current_health = local_player:get_current_health();
    local player_max_health = local_player:get_max_health();
    local health_percentabe = player_current_health / player_max_health;
    local menu_min_percentage = menu_elements_sorc_base.hp_usage_shield:get();

    if debug_enabled then
        console.print("[ICE ARMOR DEBUG] Health: " .. string.format("%.1f", health_percentabe * 100) .. "% | Threshold: " .. string.format("%.1f", menu_min_percentage * 100) .. "%")
    end

    if health_percentabe > menu_min_percentage and menu_elements_sorc_base.hp_usage_shield:get() < 1.0 then
        if debug_enabled then
            console.print("[ICE ARMOR DEBUG] Health above threshold - not casting")
        end
        return false, 0;
    end;

    if cast_spell.self(spell_id_ice_armor, 0.0) then
        local current_time = get_time_since_inject();
        local cooldown = 0.1;
        next_time_allowed_cast = current_time + cooldown;
        if debug_enabled then
            console.print("[ICE ARMOR DEBUG] Cast successful")
        end
        return true, cooldown;
    end;

    if debug_enabled then
        console.print("[ICE ARMOR DEBUG] Cast failed")
    end
    return false, 0;
end

return
{
    menu = menu,
    logics = logics,
}