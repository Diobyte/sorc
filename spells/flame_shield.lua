local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 0.0  -- Self-cast
local targeting_type = "self"
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "flame_shield_main_bool_base")),
    min_enemies         = slider_int:new(1, 20, 1, get_hash(my_utility.plugin_label .. "flame_shield_min_enemies")),
    belial_mode         = checkbox:new(false, get_hash(my_utility.plugin_label .. "flame_shield_belial_mode")),
    belial_breath_delay = slider_float:new(0.5, 4.0, 2.0, get_hash(my_utility.plugin_label .. "flame_shield_belial_breath_delay")),
    debug_mode          = checkbox:new(false, get_hash(my_utility.plugin_label .. "flame_shield_debug_mode"))
}

local function menu()
    if menu_elements.tree_tab:push("Flame Shield") then
        menu_elements.main_boolean:render("Enable Flame Shield", "Defensive shield that provides fire damage reduction")
        menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        if menu_elements.main_boolean:get() then
            menu_elements.min_enemies:render("Minimum Enemies", "Minimum number of enemies in range to cast")
            menu_elements.belial_mode:render("Belial Mode", "Override: Cast when enemy spell/buff 2140755 or 2147837 is detected")
            if menu_elements.belial_mode:get() then
                menu_elements.belial_breath_delay:render("Belial Breath Delay", "Delay before casting after detection", 1)
            end
        end
        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target)
    -- Flame Shield is a self-cast defensive shield - doesn't need a target
    local menu_boolean = menu_elements.main_boolean:get();
    local debug_enabled = menu_elements.debug_mode:get();
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_data.flame_shield.spell_id);
    if not is_logic_allowed then 
        if debug_enabled then
            console.print("[FLAME SHIELD DEBUG] Logic not allowed - spell conditions not met")
        end
        return false 
    end;

    local player_position = get_player_position();
    local enemies_in_range = my_utility.enemy_count_in_range(player_position, 10.0);
    if enemies_in_range < menu_elements.min_enemies:get() then
        if debug_enabled then
            console.print("[FLAME SHIELD DEBUG] Not enough enemies: " .. enemies_in_range .. " < " .. menu_elements.min_enemies:get())
        end
        return false;
    end

    -- Belial Mode: Check for specific buffs
    if menu_elements.belial_mode:get() then
        local belial_detected = false
        local actors = actors_manager.get_all_actors()
        for _, actor in ipairs(actors) do
            if actor and actor:is_enemy() then
                local buffs = buff_cache.get_buffs(actor)
                for _, buff in ipairs(buffs or {}) do
                    if buff.name_hash == 2140755 or buff.name_hash == 2147837 then
                        belial_detected = true
                        if debug_enabled then
                            console.print("[FLAME SHIELD DEBUG] Belial buff detected: " .. buff.name_hash)
                        end
                        break
                    end
                end
                if belial_detected then break end
            end
        end
        if not belial_detected then
            if debug_enabled then
                console.print("[FLAME SHIELD DEBUG] Belial mode enabled but no buffs detected")
            end
            return false, 0
        end
        -- Delay cast if Belial detected
        local current_time = get_time_since_inject()
        if current_time < (next_time_allowed_cast + menu_elements.belial_breath_delay:get()) then
            if debug_enabled then
                console.print("[FLAME SHIELD DEBUG] Delaying cast for Belial breath")
            end
            return false, 0
        end
    end

    if cast_spell.self(spell_data.flame_shield.spell_id, 0) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;
        if debug_enabled then
            console.print("Cast Flame Shield");
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
