local my_utility = require("my_utility/my_utility");

local menu_elements_sorc_base = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_flame_shield")),
    hp_usage_shield       = slider_float:new(0.0, 1.0, 0.30, get_hash(my_utility.plugin_label .. "%_in_which_flame_shield_will_cast")),
    cast_when_ice_armor_down = checkbox:new(true, get_hash(my_utility.plugin_label .. "cast_when_ice_armor_down")),
    belial_mode           = checkbox:new(false, get_hash(my_utility.plugin_label .. "flame_shield_belial_mode")),
    belial_breath_delay   = slider_float:new(0.5, 3.0, 1.0, get_hash(my_utility.plugin_label .. "flame_shield_belial_breath_delay")),
    belial_eye_beam_delay = slider_float:new(2.0, 4.0, 2.0, get_hash(my_utility.plugin_label .. "flame_shield_belial_eye_beam_delay")),
    debug_mode            = checkbox:new(false, get_hash(my_utility.plugin_label .. "flame_shield_debug_mode")),
}

local function menu()
    if menu_elements_sorc_base.tree_tab:push("Flame Shield") then
        menu_elements_sorc_base.main_boolean:render("Enable Spell", "")
        menu_elements_sorc_base.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")

        if menu_elements_sorc_base.main_boolean:get() then
            menu_elements_sorc_base.hp_usage_shield:render("Min cast HP Percent", "", 2)
            menu_elements_sorc_base.cast_when_ice_armor_down:render("Cast when Ice Armor is down", "")
        end

        menu_elements_sorc_base.belial_mode:render("Belial Mode", "Override: Cast when enemy spell/buff 2140755 or 2147837 is detected")
        if menu_elements_sorc_base.belial_mode:get() then
            menu_elements_sorc_base.belial_breath_delay:render("Breath Delay", "Delay for ID 2140755 detection", 2)
            menu_elements_sorc_base.belial_eye_beam_delay:render("Eye Beam Delay", "Delay for ID 2147837 detection", 2)
        end
        
        menu_elements_sorc_base.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0.0;
local spell_id_flame_shield = 167341

local function is_ice_armor_active()
    local local_player = get_local_player()
    local buff_name_check = "Sorcerer_IceArmor"

    if not local_player then return false, 0 end

    local buffs = local_player:get_buffs()
    if not buffs then return false, 0 end

    for _, buff in ipairs(buffs) do
        if buff:name() == buff_name_check then
            return true, 0  -- Ice armor buff detected, no cooldown needed
        end
    end
    return false, 0
end

local belial_flame_shield_detect_time_2140755 = nil
local belial_flame_shield_detect_time_2147837 = nil

local function belial_logic()
    local menu_boolean = menu_elements_sorc_base.main_boolean:get();
    local debug_enabled = menu_elements_sorc_base.debug_mode:get();
    
    if not menu_boolean then 
        belial_flame_shield_detect_time_2140755 = nil;
        belial_flame_shield_detect_time_2147837 = nil;
        return false, 0 
    end
    
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_id_flame_shield);
    if not is_logic_allowed then
        belial_flame_shield_detect_time_2140755 = nil;
        belial_flame_shield_detect_time_2147837 = nil;
        return false, 0;
    end

    -- Detection flags for both IDs
    local detected_2140755 = false
    local detected_2147837 = false
    
    -- Check all enemy actors (broader search than just NPCs)
    if actors_manager and actors_manager.get_enemy_actors then
        local enemies = actors_manager.get_enemy_actors()
        if enemies then
            for _, enemy in pairs(enemies) do
                if enemy then
                    -- Check active spell ID
                    if enemy.get_active_spell_id then
                        local active_spell_id = enemy:get_active_spell_id()
                        if active_spell_id == 2140755 then
                            detected_2140755 = true
                            if debug_enabled then
                                console.print("[FLAME SHIELD DEBUG] Detected spell ID 2140755 on enemy")
                            end
                        elseif active_spell_id == 2147837 then
                            detected_2147837 = true
                            if debug_enabled then
                                console.print("[FLAME SHIELD DEBUG] Detected spell ID 2147837 on enemy")
                            end
                        end
                    end
                    
                    -- Check buffs
                    if enemy.get_buffs then
                        local buffs = enemy:get_buffs()
                        if buffs then
                            for _, buff in ipairs(buffs) do
                                if buff.name_hash == 2140755 then
                                    detected_2140755 = true
                                    if debug_enabled then
                                        console.print("[FLAME SHIELD DEBUG] Detected buff ID 2140755 on enemy")
                                    end
                                elseif buff.name_hash == 2147837 then
                                    detected_2147837 = true
                                    if debug_enabled then
                                        console.print("[FLAME SHIELD DEBUG] Detected buff ID 2147837 on enemy")
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    local now = get_time_since_inject()
    local cast_attempted = false
    
    -- Handle 2140755 (Breath) logic
    if detected_2140755 then
        if not belial_flame_shield_detect_time_2140755 then
            belial_flame_shield_detect_time_2140755 = now
            if debug_enabled then
                console.print("[FLAME SHIELD DEBUG] Started Breath timer for ID 2140755")
            end
        elseif (now - belial_flame_shield_detect_time_2140755) >= menu_elements_sorc_base.belial_breath_delay:get() then
            belial_flame_shield_detect_time_2140755 = nil
            if cast_spell.self(spell_id_flame_shield, 0.0) then
                local current_time = get_time_since_inject();
                local cooldown = 0.1;
                next_time_allowed_cast = current_time + cooldown;
                if debug_enabled then
                    console.print("[FLAME SHIELD DEBUG] Cast due to Breath ID 2140755 after delay")
                end
                return true, cooldown
            end
        end
    else
        if belial_flame_shield_detect_time_2140755 and debug_enabled then
            console.print("[FLAME SHIELD DEBUG] Breath ID 2140755 no longer detected, resetting timer")
        end
        belial_flame_shield_detect_time_2140755 = nil
    end
    
    -- Handle 2147837 (Eye Beam) logic
    if detected_2147837 then
        if not belial_flame_shield_detect_time_2147837 then
            belial_flame_shield_detect_time_2147837 = now
            if debug_enabled then
                console.print("[FLAME SHIELD DEBUG] Started Eye Beam timer for ID 2147837")
            end
        elseif (now - belial_flame_shield_detect_time_2147837) >= menu_elements_sorc_base.belial_eye_beam_delay:get() then
            belial_flame_shield_detect_time_2147837 = nil
            if not cast_attempted and cast_spell.self(spell_id_flame_shield, 0.0) then
                local current_time = get_time_since_inject();
                local cooldown = 0.1;
                next_time_allowed_cast = current_time + cooldown;
                if debug_enabled then
                    console.print("[FLAME SHIELD DEBUG] Cast due to Eye Beam ID 2147837 after delay")
                end
                return true, cooldown
            end
        end
    else
        if belial_flame_shield_detect_time_2147837 and debug_enabled then
            console.print("[FLAME SHIELD DEBUG] Eye Beam ID 2147837 no longer detected, resetting timer")
        end
        belial_flame_shield_detect_time_2147837 = nil
    end
    
    return false, 0;
end

local function logics()
    if menu_elements_sorc_base.belial_mode:get() then
        return belial_logic()
    end
    local menu_boolean = menu_elements_sorc_base.main_boolean:get();
    local debug_enabled = menu_elements_sorc_base.debug_mode:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean,
                next_time_allowed_cast,
                spell_id_flame_shield);

    if not is_logic_allowed then
        return false, 0;
    end;

    local local_player = get_local_player();
    local player_current_health = local_player:get_current_health();
    local player_max_health = local_player:get_max_health();
    local health_percentage = player_current_health / player_max_health;
    local menu_min_percentage = menu_elements_sorc_base.hp_usage_shield:get();

    local should_cast_flame_shield = health_percentage <= menu_min_percentage or menu_elements_sorc_base.hp_usage_shield:get() >= 1.0

    if menu_elements_sorc_base.cast_when_ice_armor_down:get() then
        should_cast_flame_shield = should_cast_flame_shield or not is_ice_armor_active()
    end

    if should_cast_flame_shield then
        if cast_spell.self(spell_id_flame_shield, 0.0) then
            local current_time = get_time_since_inject();
            local cooldown = 0.1;
            next_time_allowed_cast = current_time + cooldown;
            if debug_enabled then
                console.print("[FLAME SHIELD DEBUG] Cast due to health/ice armor condition")
            end
            return true, cooldown
        end;
    end;

    return false, 0;
end

return 
{
    menu = menu,
    logics = logics,   
}