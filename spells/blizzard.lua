local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 15.0
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "blizzard_main_bool_base")),
    targeting_mode      = combo_box:new(0, get_hash(my_utility.plugin_label .. "blizzard_targeting_mode")),
    min_target_range    = slider_float:new(1, max_spell_range - 1, 3,
        get_hash(my_utility.plugin_label .. "blizzard_min_target_range")),
    min_enemies         = slider_int:new(1, 10, 3, get_hash(my_utility.plugin_label .. "blizzard_min_enemies")),
}

local function menu()
    if menu_elements.tree_tab:push("Blizzard") then
        menu_elements.main_boolean:render("Enable Blizzard", "Ground-targeted AoE ultimate that damages and slows enemies")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_ranged,
                my_utility.targeting_mode_description)
            menu_elements.min_target_range:render("Min Target Distance",
                "\n     Must be lower than Max Targeting Range     \n\n", 1)
            menu_elements.min_enemies:render("Minimum Enemies", "Minimum number of enemies in AoE to cast")
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target)
    if not target then return false end;
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.blizzard.spell_id);

    if not is_logic_allowed then return false end;

    if not my_utility.is_in_range(target, max_spell_range) or my_utility.is_in_range(target, menu_elements.min_target_range:get()) then
        return false
    end

    -- Check for minimum enemies in AoE radius
    local target_pos = target:get_position()
    local player_pos = get_player_position()
    local enemies = actors_manager.get_enemy_actors()
    local enemies_in_aoe = 0
    for _, enemy in ipairs(enemies) do
        if enemy and enemy:is_enemy() then
            local enemy_pos = enemy:get_position()
            local distance = target_pos:dist_to(enemy_pos)
            if distance <= 3.0 then -- Blizzard AoE radius
                enemies_in_aoe = enemies_in_aoe + 1
            end
        end
    end
    if enemies_in_aoe < menu_elements.min_enemies:get() then
        return false;
    end

    if cast_spell.position(spell_data.blizzard.spell_id, target_pos, 0) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;
        if _G.__sorc_debug__ then
            console.print("Cast Blizzard - Target: " ..
                my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] ..
                ", Enemies: " .. enemies_in_aoe);
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
