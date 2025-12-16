local my_utility = require("my_utility/my_utility");
local spell_data = require("my_utility/spell_data");

local max_spell_range = spell_data.spear.data.range
local targeting_type = "ranged"
local menu_elements = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_lightning_spear")),
    targeting_mode        = combo_box:new(0, get_hash(my_utility.plugin_label .. "lightning_spear_targeting_mode")),
    min_target_range      = slider_float:new(1.0, 20.0, 5.0, get_hash(my_utility.plugin_label .. "lightning_spear_min_target_range")),
    priority_target       = checkbox:new(false, get_hash(my_utility.plugin_label .. "spear_priority_target")),
    crackling_energy_snapshot = checkbox:new(false, get_hash(my_utility.plugin_label .. "crackling_energy_snapshot_spear")),
    debug_mode            = checkbox:new(false, get_hash(my_utility.plugin_label .. "spear_debug_mode"))
}

local function menu()
    
    if menu_elements.tree_tab:push("Lightning Spear") then
        menu_elements.main_boolean:render("Enable Lightning Spear", "Powerful lightning projectile")
        menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes, "")
        menu_elements.min_target_range:render("Min Target Range", "", 1)
        if menu_elements.main_boolean:get() then
            menu_elements.priority_target:render("Priority Targeting", "Targets Boss > Champion > Elite > Any")
            menu_elements.crackling_energy_snapshot:render("Crackling Energy Snapshot", "Enables special casting logic for Crackling Energy optimization")
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
                spell_data.spear.spell_id);

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[SPEAR DEBUG] Logic not allowed - spell conditions not met")
        end
        return false;
    end;

    if not target then
        if debug_enabled then
            console.print("[SPEAR DEBUG] No target found")
        end
        return false;
    end

    local target_position = target:get_position();

    -- Crackling Energy Snapshot: Only cast after enough Ball casts
    if menu_elements.crackling_energy_snapshot:get() then
        if not my_utility.has_enough_ball_casts(3) then  -- Require 3 Ball casts
            if debug_enabled then
                console.print("[SPEAR DEBUG] Crackling Energy: Not enough Ball casts (" .. my_utility.get_ball_cast_count() .. "/3)")
            end
            return false, 0
        end
        -- Reset after casting Spear
        my_utility.end_crackling_energy_loop()
    end

    if cast_spell.position(spell_data.spear.spell_id, target_position, 0.1) then
        local current_time = get_time_since_inject();
        local cooldown = 0.1;
        next_time_allowed_cast = current_time + cooldown;
        
        if debug_enabled then
            console.print("Cast Lightning Spear - Target: " .. my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1]);
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
