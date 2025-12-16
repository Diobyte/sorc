local function is_auto_play_enabled()
    -- auto play fire spells without orbwalker
    local is_auto_play_active = auto_play.is_active();
    if is_auto_play_active then
        return true;
    end

    return false;
end

-- Skin name patterns for infernal horde objectives
local horde_objectives = {
    "BSK_HellSeeker",
    "MarkerLocation_BSK_Occupied",
    "S05_coredemon",
    "S05_fallen",
    "BSK_Structure_BonusAether",
    "BSK_Miniboss",
    "BSK_elias_boss",
    "BSK_cannibal_brute_boss",
    "BSK_skeleton_boss"
}

local spell_delays = {
    instant_cast = 0.01,
    regular_cast = 0.1
}

local plugin_label = "BASE_SORC_PLUGIN_DIRTY_"

local function is_action_allowed()
     -- evade abort
   local local_player = get_local_player();
   if not local_player then
       return false
   end

   local player_position = local_player:get_position();
   if evade.is_dangerous_position(player_position) then
       return false;
   end

   local busy_spell_id_1 = 197833
   local active_spell_id = local_player:get_active_spell_id()
   if active_spell_id == busy_spell_id_1 then
       return false
   end

    local is_mounted = false;
    local is_blood_mist = false;
    local is_shrine_conduit = false;
    local local_player_buffs = local_player:get_buffs();

    for _, buff in ipairs(local_player_buffs) do
          if buff.name_hash == 493422 then  -- Blood Mist
              is_blood_mist = true;
              break;
          elseif buff.name_hash == 1923 then  -- Mount
            is_mounted = true;
              break;
          elseif buff.name_hash == 421661 then  -- Shrine Conduit
            is_shrine_conduit = true;
              break;
          end
    end

      -- do not make any actions while in blood mist
      if is_blood_mist or is_mounted or is_shrine_conduit then
          return false;
      end

    return true
end

-- local function is_spell_owned(spell_id)

--     for i, x in ipairs(get_equipped_spell_ids()) do
--         if x == spell_id then
--             return true
--         end
--     end
-- end
local function is_spell_allowed(spell_enable_check, next_cast_allowed_time, spell_id)
    -- Default override flag if not set
    if _G.__sorc_allow_any_orb_mode__ == nil then _G.__sorc_allow_any_orb_mode__ = false end
    if _G.__sorc_debug__ == nil then _G.__sorc_debug__ = false end
    if not spell_enable_check then
        if _G.__sorc_debug__ then console.print("[ALLOW] disabled by menu for spell " .. tostring(spell_id)) end
        return false;
    end;

    local current_time = get_time_since_inject();
    if current_time < next_cast_allowed_time then
        if _G.__sorc_debug__ then console.print("[ALLOW] cooldown gate for spell " .. tostring(spell_id) .. " for " .. string.format("%.2f", next_cast_allowed_time - current_time) .. "s") end
        return false;
    end;

    if not utility.is_spell_ready(spell_id) then
        if _G.__sorc_debug__ then console.print("[ALLOW] not ready: " .. tostring(spell_id)) end
        return false;
    end

    -- evade abort
    local local_player = get_local_player();
    if local_player then
        local player_position = local_player:get_position();
        if evade.is_dangerous_position(player_position) then
            if _G.__sorc_debug__ then console.print("[ALLOW] dangerous position; skipping cast") end
            return false;
        end
    end    

    -- -- automatic
    -- if current_cast_mode == 4 then
    --     return true
    -- end

    if is_auto_play_enabled() then
        if _G.__sorc_debug__ then console.print("[ALLOW] auto play enabled; allowing cast") end
        return true;
    end

    -- local is_pvp_or_clear = current_cast_mode == 0
    -- local is_pvp_only = current_cast_mode == 1
    -- local is_clear_only = current_cast_mode == 2

    local current_orb_mode = orbwalker.get_orb_mode()

    -- Optional override: allow casting regardless of orb mode
    if _G.__sorc_allow_any_orb_mode__ == true then
        -- continue without orb-mode gating
    else
        if current_orb_mode == orb_mode.none then
            if _G.__sorc_debug__ then console.print("[ALLOW] orb mode none; blocked") end
            return false
        end
    end

    local is_current_orb_mode_pvp = current_orb_mode == orb_mode.pvp
    local is_current_orb_mode_clear = current_orb_mode == orb_mode.clear
    -- local is_current_orb_mode_flee = current_orb_mode == orb_mode.flee
    
    -- if is_pvp_only and not is_current_orb_mode_pvp then
    --     return false
    -- end

    -- if is_clear_only and not is_current_orb_mode_clear then
    --     return false
    -- end

     -- is pvp or clear (both)
    if _G.__sorc_allow_any_orb_mode__ ~= true then
        if not is_current_orb_mode_pvp and not is_current_orb_mode_clear then
            if _G.__sorc_debug__ then console.print("[ALLOW] orb mode not pvp/clear; blocked") end
            return false;
        end
    end

    -- we already checked everything that we wanted. If orb = none, we return false. 
    -- PVP only & not pvp mode, return false . PvE only and not pve mode, return false.
    -- All checks passed at this point so we can go ahead with the logics

    return true

end

local function generate_points_around_target(target_position, radius, num_points)
    local points = {};
    for i = 1, num_points do
        local angle = (i - 1) * (2 * math.pi / num_points);
        local x = target_position:x() + radius * math.cos(angle);
        local y = target_position:y() + radius * math.sin(angle);
        table.insert(points, vec3.new(x, y, target_position:z()));
    end
    return points;
end

local function get_best_point(target_position, circle_radius, current_hit_list)
    local points = generate_points_around_target(target_position, circle_radius * 0.75, 8); -- Generate 8 points around target
    local hit_table = {};

    local player_position = get_player_position();
    for _, point in ipairs(points) do
        local hit_list = utility.get_units_inside_circle_list(point, circle_radius);

        local hit_list_collision_less = {};
        for _, obj in ipairs(hit_list) do
            local is_wall_collision = target_selector.is_wall_collision(player_position, obj, 2.0);
            if not is_wall_collision then
                table.insert(hit_list_collision_less, obj);
            end
        end

        table.insert(hit_table, {
            point = point, 
            hits = #hit_list_collision_less, 
            victim_list = hit_list_collision_less
        });
    end

    -- sort by the number of hits
    table.sort(hit_table, function(a, b) return a.hits > b.hits end);

    local current_hit_list_amount = #current_hit_list;
    if hit_table[1].hits > current_hit_list_amount then
        return hit_table[1]; -- returning the point with the most hits
    end
    
    return {point = target_position, hits = current_hit_list_amount, victim_list = current_hit_list};
end

function is_target_within_angle(origin, reference, target, max_angle)
    -- Compute direction vectors using coordinates (Lua 5.1 friendly)
    local v1 = vec3.new(reference:x() - origin:x(), reference:y() - origin:y(), reference:z() - origin:z()):normalize()
    local v2 = vec3.new(target:x() - origin:x(), target:y() - origin:y(), target:z() - origin:z()):normalize()

    -- Fallback for zero-length vectors
    if not v1 or not v2 then return true end

    local dot = v1:dot_product(v2)
    -- Clamp to valid range to avoid NaNs due to precision
    if dot > 1 then dot = 1 elseif dot < -1 then dot = -1 end
    local angle = math.deg(math.acos(dot))
    return angle <= max_angle
end

local function generate_points_around_target_rec(target_position, radius, num_points)
    local points = {}
    local angles = {}
    for i = 1, num_points do
        local angle = (i - 1) * (2 * math.pi / num_points)
        local x = target_position:x() + radius * math.cos(angle)
        local y = target_position:y() + radius * math.sin(angle)
        table.insert(points, vec3.new(x, y, target_position:z()))
        table.insert(angles, angle)
    end
    return points, angles
end

local function get_best_point_rec(target_position, rectangle_radius, width, current_hit_list)
    local points, angles = generate_points_around_target_rec(target_position, rectangle_radius, 8)
    local hit_table = {}

    for i, point in ipairs(points) do
        local angle = angles[i]
        -- Calculate the destination point based on width and angle
        local destination = vec3.new(point:x() + width * math.cos(angle), point:y() + width * math.sin(angle), point:z())

        local hit_list = utility.get_units_inside_rectangle_list(point, destination, width)
        table.insert(hit_table, {point = point, hits = #hit_list, victim_list = hit_list})
    end

    table.sort(hit_table, function(a, b) return a.hits > b.hits end)

    local current_hit_list_amount = #current_hit_list
    if hit_table[1].hits > current_hit_list_amount then
        return hit_table[1] -- returning the point with the most hits
    end

    return {point = target_position, hits = current_hit_list_amount, victim_list = current_hit_list}
end

-- (kept above) horde_objectives already defined earlier in this file

local spell_delays = {
    instant_cast = 0.01,
    regular_cast = 0.1
}

local activation_filters = {
    "No Filter",
    "Only Boss",
    "Only Champion",
    "Only Elite",
    "Boss/Champion/Elite"
}

local targeting_mode_description = {
    "Closest to Player",
    "Lowest Health %",
    "Highest Health %",
    "Closest to Cursor",
    "Cursor Priority"
}

local targeting_modes = {
    "Closest to Player",
    "Lowest Health %",
    "Highest Health %",
    "Closest to Cursor",
    "Cursor Priority"
}

local targeting_modes_melee = {
    "Closest to Player",
    "Lowest Health %",
    "Highest Health %"
}

local targeting_modes_ranged = {
    "Closest to Player",
    "Lowest Health %",
    "Highest Health %",
    "Closest to Cursor",
    "Cursor Priority"
}

local evaluation_range_description = {
    "1.0 - Very Close",
    "2.0 - Close",
    "3.0 - Medium",
    "4.0 - Far",
    "5.0 - Very Far",
    "6.0 - Distant"
}

local plugin_label = "BASE_SORC_PLUGIN_DIRTY_"

local function is_auto_play_enabled()
    -- auto play fire spells without orbwalker
    local is_auto_play_active = auto_play.is_active();
    local auto_play_objective = auto_play.get_objective();
    local is_auto_play_fighting = auto_play_objective == objective.fight;
    if is_auto_play_active and is_auto_play_fighting then
        return true;
    end

    return false;
end

local mount_buff_name = "Generic_SetCannotBeAddedToAITargetList";
local mount_buff_name_hash = mount_buff_name;
local mount_buff_name_hash_c = 1923;

local shrine_conduit_buff_name = "Shine_Conduit";
local shrine_conduit_buff_name_hash = shrine_conduit_buff_name;
local shrine_conduit_buff_name_hash_c = 421661;

local function is_spell_active(spell_id)
    -- get player buffs
    local local_player = get_local_player()
    if not local_player then return false end

    local player_buffs = local_player:get_buffs()
    for _, buff in ipairs(player_buffs) do
        if buff.name_hash == spell_id then
            return true
        end
    end
    return false
end

local function is_buff_active(buff_name_hash)
    local local_player = get_local_player()
    if not local_player then return false end

    local player_buffs = local_player:get_buffs()
    for _, buff in ipairs(player_buffs) do
        if buff.name_hash == buff_name_hash then
            return true
        end
    end
    return false
end

local function buff_stack_count(buff_name_hash)
    local local_player = get_local_player()
    if not local_player then return 0 end

    local player_buffs = local_player:get_buffs()
    for _, buff in ipairs(player_buffs) do
        if buff.name_hash == buff_name_hash then
            return buff:get_stack_count()
        end
    end
    return 0
end

local function is_action_allowed()
     -- evade abort
   local local_player = get_local_player();
   if not local_player then
       return false
   end

   local player_position = local_player:get_position();
   if evade.is_dangerous_position(player_position) then
       return false;
   end

   local busy_spell_id_1 = 197833
   local active_spell_id = local_player:get_active_spell_id()
   if active_spell_id == busy_spell_id_1 then
       return false
   end

    local is_mounted = false;
    local is_blood_mist = false;
    local is_shrine_conduit = false;
    local portal_transfer_buff_detected = false;
    local local_player_buffs = local_player:get_buffs();

    for _, buff in ipairs(local_player_buffs) do
          if buff.name_hash == blood_mist_buff_name_hash_c then
              is_blood_mist = true;
              break;
          end

          if buff.name_hash == mount_buff_name_hash_c then
            is_mounted = true;
              break;
          end

          if buff.name_hash == shrine_conduit_buff_name_hash_c then
            is_shrine_conduit = true;
              break;
          end
    end

      -- do not make any actions while in blood mist
      if is_blood_mist or is_mounted or is_shrine_conduit then
          return false;
      end

    return true
end

local function is_spell_allowed(spell_enable_check, next_cast_allowed_time, spell_id)
    if not spell_enable_check then
        return false;
    end;

    local current_time = get_time_since_inject();
    if current_time < next_cast_allowed_time then
        return false;
    end;

    if not utility.is_spell_ready(spell_id) then
        return false;
    end

    -- evade abort
    local local_player = get_local_player();
    if local_player then
        local player_position = local_player:get_position();
        if evade.is_dangerous_position(player_position) then
            return false;
        end
    end

    if is_auto_play_enabled() then
        return true;
    end

    local current_orb_mode = orbwalker.get_orb_mode()

    if current_orb_mode == orb_mode.none then
        return false
    end

    local is_current_orb_mode_pvp = current_orb_mode == orb_mode.pvp
    local is_current_orb_mode_clear = current_orb_mode == orb_mode.clear

    if not is_current_orb_mode_pvp and not is_current_orb_mode_clear then
        return false;
    end

    return true
end

local function generate_points_around_target(target_position, radius, num_points)
    local points = {};
    for i = 1, num_points do
        local angle = (i - 1) * (2 * math.pi / num_points);
        local x = target_position:x() + radius * math.cos(angle);
        local y = target_position:y() + radius * math.sin(angle);
        table.insert(points, vec3.new(x, y, target_position:z()));
    end
    return points;
end

local function get_best_point(target_position, circle_radius, current_hit_list)
    local points = generate_points_around_target(target_position, circle_radius * 0.75, 8); -- Generate 8 points around target
    local hit_table = {};

    local player_position = get_player_position();
    for _, point in ipairs(points) do
        local hit_list = utility.get_units_inside_circle_list(point, circle_radius);

        local hit_list_collision_less = {};
        for _, obj in ipairs(hit_list) do
            local is_wall_collision = target_selector.is_wall_collision(player_position, obj, 2.0);
            if not is_wall_collision then
                table.insert(hit_list_collision_less, obj);
            end
        end

        table.insert(hit_table, {
            point = point,
            hits = #hit_list_collision_less,
            victim_list = hit_list_collision_less
        });
    end

    -- sort by the number of hits
    table.sort(hit_table, function(a, b) return a.hits > b.hits end);

    local current_hit_list_amount = #current_hit_list;
    if hit_table[1].hits > current_hit_list_amount then
        return hit_table[1]; -- returning the point with the most hits
    end

    return {point = target_position, hits = current_hit_list_amount, victim_list = current_hit_list};
end

function is_target_within_angle(origin, reference, target, max_angle)
    -- Compute direction vectors using coordinates (Lua 5.1 friendly)
    local v1 = vec3.new(reference:x() - origin:x(), reference:y() - origin:y(), reference:z() - origin:z()):normalize()
    local v2 = vec3.new(target:x() - origin:x(), target:y() - origin:y(), target:z() - origin:z()):normalize()

    -- Fallback for zero-length vectors
    if not v1 or not v2 then return true end

    local dot = v1:dot_product(v2)
    -- Clamp to valid range to avoid NaNs due to precision
    if dot > 1 then dot = 1 elseif dot < -1 then dot = -1 end
    local angle = math.deg(math.acos(dot))
    return angle <= max_angle
end

local function generate_points_around_target_rec(target_position, radius, num_points)
    local points = {}
    local angles = {}
    for i = 1, num_points do
        local angle = (i - 1) * (2 * math.pi / num_points)
        local x = target_position:x() + radius * math.cos(angle)
        local y = target_position:y() + radius * math.sin(angle)
        table.insert(points, vec3.new(x, y, target_position:z()))
        table.insert(angles, angle)
    end
    return points, angles
end

local function get_best_point_rec(target_position, rectangle_radius, width, current_hit_list)
    local points, angles = generate_points_around_target_rec(target_position, rectangle_radius, 8)
    local hit_table = {}

    for i, point in ipairs(points) do
        local angle = angles[i]
        -- Calculate the destination point based on width and angle
        local destination = vec3.new(point:x() + width * math.cos(angle), point:y() + width * math.sin(angle), point:z())

        local hit_list = utility.get_units_inside_rectangle_list(point, destination, width)
        table.insert(hit_table, {point = point, hits = #hit_list, victim_list = hit_list})
    end

    table.sort(hit_table, function(a, b) return a.hits > b.hits end)

    local current_hit_list_amount = #current_hit_list
    if hit_table[1].hits > current_hit_list_amount then
        return hit_table[1] -- returning the point with the most hits
    end

    return {point = target_position, hits = current_hit_list_amount, victim_list = current_hit_list}
end

local function is_in_range(target, range)
    if not target then return false end
    local player_position = get_player_position()
    local target_position = target:get_position()
    if not player_position or not target_position then return false end
    local distance_sqr = player_position:squared_dist_to_ignore_z(target_position)
    return distance_sqr <= range * range
end

local function get_melee_range()
    return 3.0 -- Standard melee range
end

local function enemy_count_in_range(position, range)
    local enemies = actors_manager.get_enemy_npcs()
    local count = 0

    for _, enemy in ipairs(enemies) do
        if enemy and enemy:is_enemy() and enemy:is_alive() then
            local enemy_pos = enemy:get_position()
            local distance = position:dist_to(enemy_pos)
            if distance <= range then
                count = count + 1
            end
        end
    end

    return count
end

local function record_spell_cast(spell_id)
    _G.last_cast_time = _G.last_cast_time or {}
    _G.last_cast_time[spell_id] = get_time_since_inject()
end

local function get_last_cast_time(spell_id)
    _G.last_cast_time = _G.last_cast_time or {}
    return _G.last_cast_time[spell_id] or 0
end

return
{
    spell_delays = spell_delays,
    activation_filters = activation_filters,
    targeting_mode_description = targeting_mode_description,
    targeting_modes = targeting_modes,
    targeting_modes_melee = targeting_modes_melee,
    targeting_modes_ranged = targeting_modes_ranged,
    evaluation_range_description = evaluation_range_description,
    plugin_label = plugin_label,
    is_spell_allowed = is_spell_allowed,
    is_action_allowed = is_action_allowed,
    is_spell_active = is_spell_active,
    is_buff_active = is_buff_active,
    buff_stack_count = buff_stack_count,

    is_in_range = is_in_range,
    get_melee_range = get_melee_range,

    record_spell_cast = record_spell_cast,
    get_last_cast_time = get_last_cast_time,

    is_auto_play_enabled = is_auto_play_enabled,

    get_best_point = get_best_point,
    generate_points_around_target = generate_points_around_target,

    is_target_within_angle = is_target_within_angle,

    get_best_point_rec = get_best_point_rec,
    enemy_count_in_range = enemy_count_in_range,

    is_auto_play_enabled = is_auto_play_enabled,

    -- decrepify & bone_prision
    get_best_point = get_best_point,
    generate_points_around_target = generate_points_around_target,

    -- blight
    is_target_within_angle = is_target_within_angle,

    -- bone spear rect
    get_best_point_rec = get_best_point_rec,
    
    -- infernal horde objectives
    horde_objectives = horde_objectives,

    spell_delays = spell_delays,

    -- get equipped spells and lookup table
    get_equipped_spells_and_lookup = function()
        local equipped_spells = get_equipped_spell_ids()
        local equipped_lookup = {}
        for _, spell_id in ipairs(equipped_spells) do
            equipped_lookup[spell_id] = true
        end
        return equipped_spells, equipped_lookup
    end
}

return
{
    plugin_label = plugin_label,
    is_spell_allowed = is_spell_allowed,
    is_action_allowed = is_action_allowed,

    is_auto_play_enabled = is_auto_play_enabled,

    -- decrepify & bone_prision
    get_best_point = get_best_point,
    generate_points_around_target = generate_points_around_target,

    -- blight
    is_target_within_angle = is_target_within_angle,

    -- bone spear rect
    get_best_point_rec = get_best_point_rec,
    
    -- infernal horde objectives
    horde_objectives = horde_objectives,

    -- get equipped spells and lookup table
    get_equipped_spells_and_lookup = function()
        local equipped_spells = get_equipped_spell_ids()
        local equipped_lookup = {}
        for _, spell_id in ipairs(equipped_spells) do
            equipped_lookup[spell_id] = true
        end
        return equipped_spells, equipped_lookup
    end
}

-- Make the function globally available
_G.get_equipped_spells_and_lookup = function()
    local equipped_spells = get_equipped_spell_ids()
    local equipped_lookup = {}
    for _, spell_id in ipairs(equipped_spells) do
        equipped_lookup[spell_id] = true
    end
    return equipped_spells, equipped_lookup
end

return
{
    plugin_label = plugin_label,
    is_spell_allowed = is_spell_allowed,
    is_action_allowed = is_action_allowed,

    is_auto_play_enabled = is_auto_play_enabled,

    -- decrepify & bone_prision
    get_best_point = get_best_point,
    generate_points_around_target = generate_points_around_target,

    -- blight
    is_target_within_angle = is_target_within_angle,

    -- bone spear rect
    get_best_point_rec = get_best_point_rec,
    
    -- infernal horde objectives
    horde_objectives = horde_objectives,

    spell_delays = spell_delays,

    -- get equipped spells and lookup table
    get_equipped_spells_and_lookup = function()
        local equipped_spells = get_equipped_spell_ids()
        local equipped_lookup = {}
        for _, spell_id in ipairs(equipped_spells) do
            equipped_lookup[spell_id] = true
        end
        return equipped_spells, equipped_lookup
    end
}