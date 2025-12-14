local my_utility = require("my_utility/my_utility");

local menu_elements_base_blade = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_ice_blade")),
    debug_mode            = checkbox:new(false, get_hash(my_utility.plugin_label .. "ice_blade_debug_mode")),
    use_custom_cooldown   = checkbox:new(false, get_hash(my_utility.plugin_label .. "ice_blade_use_custom_cooldown")),
    custom_cooldown_sec   = slider_float:new(1.0, 10.0, 3.0, get_hash(my_utility.plugin_label .. "ice_blade_custom_cooldown_sec")),
}

local function menu()
    if menu_elements_base_blade.tree_tab:push("Ice Blade")then
        menu_elements_base_blade.main_boolean:render("Enable Spell", "")
        menu_elements_base_blade.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        menu_elements_base_blade.use_custom_cooldown:render("Use Custom Cooldown", "Only cast every X seconds")
        if menu_elements_base_blade.use_custom_cooldown:get() then
            menu_elements_base_blade.custom_cooldown_sec:render("Cooldown (seconds)", "", 2)
        end
        menu_elements_base_blade.tree_tab:pop()
    end
end

local spell_id_blade = 291492
local next_time_allowed_cast = 0.0
local last_cast_time = 0.0

local function logics(target)
    local current_time = get_time_since_inject()
    local debug_enabled = menu_elements_base_blade.debug_mode:get()

    local menu_boolean = menu_elements_base_blade.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean, 
        next_time_allowed_cast, 
        spell_id_blade
    )

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[ICE BLADE DEBUG] Logic not allowed - spell conditions not met")
        end
        return false, 0
    end

    if not target then
        if debug_enabled then
            console.print("[ICE BLADE DEBUG] No target provided")
        end
        return false, 0
    end

    -- Check custom cooldown
    if menu_elements_base_blade.use_custom_cooldown:get() then
        local cooldown_time = menu_elements_base_blade.custom_cooldown_sec:get()
        if current_time - last_cast_time < cooldown_time then
            if debug_enabled then
                console.print("[ICE BLADE DEBUG] Custom cooldown active - " .. string.format("%.1f", cooldown_time - (current_time - last_cast_time)) .. "s remaining")
            end
            return false, 0
        end
    end

    local target_position = target:get_position()
    if cast_spell.position(spell_id_blade, target_position, 0.1) then
        local cooldown = 0.1
        next_time_allowed_cast = current_time + cooldown
        last_cast_time = current_time
        if debug_enabled then
            console.print("[ICE BLADE DEBUG] Cast successful at target position")
        end
        return true, cooldown
    end

    if debug_enabled then
        console.print("[ICE BLADE DEBUG] Cast failed")
    end
    return false, 0
end

return 
{
    menu = menu,
    logics = logics,   
}