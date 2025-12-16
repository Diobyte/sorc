local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")
local my_target_selector = require("my_utility/my_target_selector")

local max_spell_range = spell_data.firewall.data.range
local targeting_type = "ranged"
local menu_elements = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "firewall_main_boolean")),
    targeting_mode        = combo_box:new(0, get_hash(my_utility.plugin_label .. "firewall_targeting_mode")),
    min_target_range      = slider_float:new(1.0, 20.0, 5.0, get_hash(my_utility.plugin_label .. "firewall_min_target_range")),
    min_max_targets       = slider_int:new(1, 10, 3, get_hash(my_utility.plugin_label .. "firewall_min_max_targets")),
    debug_mode            = checkbox:new(false, get_hash(my_utility.plugin_label .. "firewall_debug_mode"))
}

local function menu()
    
    if menu_elements.tree_tab:push("Firewall")then
        menu_elements.main_boolean:render("Enable Firewall", "Ground-targeted fire wall")
        menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes, "")
            menu_elements.min_target_range:render("Min Target Range", "", 1)
            menu_elements.min_max_targets:render("Min Max Targets", "Minimum number of targets to hit", 1)
        end
 
        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0.0;

local function logics(target, target_selector_data_all)
    
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_data.firewall.spell_id);

    if not is_logic_allowed then
        return false;
    end;
    
    if not target then
        return false;
    end;

    local debug_enabled = menu_elements.debug_mode:get();
    local min_max_targets = menu_elements.min_max_targets:get();
    local target_position = target:get_position();

    if min_max_targets > 1 then
        local area_data = my_target_selector.get_most_hits_rectangle(get_player_position(), max_spell_range, spell_data.firewall.data.radius);
        if area_data and area_data.score >= min_max_targets then
            target_position = area_data.position;
            if debug_enabled then
                console.print("[SPELL DEBUG] Firewall - Using AoE position for " .. area_data.score .. " targets");
            end
        elseif debug_enabled then
            console.print("[SPELL DEBUG] Firewall - Not enough targets for AoE, using single target");
        end
    end

    -- Check for existing firewall collision
    local should_cast_firewall = true
    if target_selector_data_all and target_selector_data_all.list then
        for _, actor in ipairs(target_selector_data_all.list) do
            if actor and actor:is_enemy() and actor:is_alive() then
                local actor_name = actor:get_skin_name()
                if actor_name == "Generic_Proxy_firewall" then
                    local actor_position = actor:get_position()
                    local dx = math.abs(target_position:x() - actor_position:x())
                    local dy = math.abs(target_position:y() - actor_position:y())    
                    if dx <= 2 and dy <= 8 then  -- rectangle width is 2 and height is 8
                        should_cast_firewall = false
                        if debug_enabled then
                            console.print("[SPELL DEBUG] Firewall - Collision detected with existing firewall")
                        end
                        break
                    end
                end
            end
        end
    end

    if not should_cast_firewall then
        return false, 0
    end

    if debug_enabled then
        console.print("[SPELL DEBUG] Firewall - Casting at position");
    end

    if cast_spell.position(spell_data.firewall.spell_id, target_position, spell_data.firewall.data.cast_delay) then
        local current_time = get_time_since_inject();
        local cooldown = my_utility.spell_delays.regular_cast;
        next_time_allowed_cast = current_time + cooldown;
        if debug_enabled then
            console.print("[SPELL DEBUG] Firewall - Cast successful");
        end
        return true, cooldown;
    end

    return false, 0;
end

return 
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    targeting_type = "ranged"
}