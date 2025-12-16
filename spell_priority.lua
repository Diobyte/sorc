-- Diablo 4 Season 11 Sorcerer Spell Priorities
-- Updated for current meta builds and leveling progression
--
-- BUILD GUIDE:
-- 1. Ball Lightning (META): Season 11 top meta - Ball Lightning + Chain Lightning
-- 2. Fire Build: Traditional fireball/inferno build
-- 3. Frost Build: Crowd control focused with Frozen Orb
-- 4. Chain Lightning: Mobility and chain damage focused
-- 0. Default: Balanced mix of all spells
--
-- LEVELING PROGRESSION:
-- Levels 1-15: Fire Bolt spam
-- Levels 15-25: Fireball transition
-- Levels 25-35: Add Inferno for AoE
-- Levels 35-45: Build specialization
-- Level 45+: End-game build priorities

-- Function to get base spell priority (without item adjustments)
local function get_base_spell_priority(build_index)
    if build_index == 1 then  -- Ball Lightning Build (Season 11 META)
        return {
            -- Core defensive spells (HIGH PRIORITY)
            "flame_shield",  -- Defensive shield
            "ice_armor",     -- Defensive armor

            -- Main damage spells (Ball Lightning Meta)
            "ball",          -- PRIMARY: Ball Lightning - Season 11 meta nuke
            "chain_lightning", -- Chain damage amplifier
            "charged_bolts", -- AoE damage and crit generation
            "unstable_current", -- Ultimate chain damage

            -- Supporting damage
            "spark",         -- Mana generator and basic damage
            "fire_bolt",     -- Fallback spam damage

            -- Utility and mobility
            "teleport",      -- Mobility
            "teleport_ench", -- Enhanced teleport

            -- Additional spells
            "hydra",         -- Summon damage
            "familiars",     -- Summon support
            "frost_nova",    -- Emergency crowd control
        }
    elseif build_index == 2 then  -- Fire Build (Strong Secondary)
        return {
            -- Core defensive spells
            "flame_shield",  -- Defensive shield (HIGH PRIORITY)
            "ice_armor",     -- Defensive armor (HIGH PRIORITY)

            -- Main damage spells
            "fireball",      -- Primary nuke
            "inferno",       -- High damage AoE
            "meteor",        -- Ultimate AoE
            "firewall",      -- Ground AoE
            "incinerate",    -- Single target burst

            -- Supporting spells
            "spark",         -- Generator
            "charged_bolts", -- AoE damage
            "fire_bolt",     -- Basic spam

            -- Utility and mobility
            "teleport",      -- Mobility
            "teleport_ench", -- Enhanced teleport

            -- Melee option
            "arc_lash",      -- Melee option
        }
    elseif build_index == 3 then  -- Frost Build (Crowd Control)
        return {
            -- Core defensive spells
            "flame_shield",  -- Defensive shield (HIGH PRIORITY)
            "ice_armor",     -- Defensive armor (HIGH PRIORITY)

            -- Main damage spells
            "frozen_orb",    -- Primary AoE
            "blizzard",      -- Ultimate AoE
            "ice_shards",    -- Multi-projectile
            "frost_bolt",    -- Single target

            -- Crowd control and finishers
            "deep_freeze",   -- Stun finisher
            "frost_nova",    -- AoE control

            -- Utility and mobility
            "teleport",      -- Mobility
            "teleport_ench", -- Enhanced teleport

            -- Supporting spells
            "ice_blade",     -- Melee option
            "spark",         -- Generator
        }
    elseif build_index == 4 then  -- Chain Lightning Build (Mobility)
        return {
            -- Core defensive spells
            "flame_shield",  -- Defensive shield (HIGH PRIORITY)
            "ice_armor",     -- Defensive armor (HIGH PRIORITY)

            -- Main damage spells
            "chain_lightning", -- PRIMARY: Chain damage
            "unstable_current", -- Ultimate chain
            "charged_bolts",   -- AoE bolts and crit gen
            "ball",           -- Bouncing projectile

            -- Supporting spells
            "spark",         -- Generator
            "hydra",         -- Summon damage
            "familiars",     -- Summon support

            -- Utility and mobility
            "teleport",      -- Mobility
            "teleport_ench", -- Enhanced teleport

            -- Emergency spells
            "frost_nova",    -- AoE control
        }
    else  -- Default build (build_index == 0 or any other value) - Balanced
        return {
            -- Core defensive spells
            "flame_shield",  -- Defensive shield (HIGH PRIORITY)
            "ice_armor",     -- Defensive armor (HIGH PRIORITY)

            -- Main damage spells (Season 11 Meta Mix)
            "ball",          -- Ball Lightning meta
            "fireball",      -- Versatile nuke
            "frozen_orb",    -- AoE damage
            "chain_lightning", -- Chain damage
            "inferno",       -- High damage AoE
            "blizzard",      -- Ultimate AoE
            "meteor",        -- Ultimate AoE

            -- Utility and mobility
            "teleport",      -- Mobility
            "teleport_ench", -- Enhanced teleport

            -- Supporting spells
            "ice_shards",    -- Multi-projectile
            "firewall",      -- Ground AoE
            "charged_bolts", -- AoE bolts
            "spark",         -- Generator
            "hydra",         -- Summon damage
            "familiars",     -- Summon support
            "frost_nova",    -- AoE control
            "deep_freeze",   -- Stun finisher
            "incinerate",    -- Single target
            "fire_bolt",     -- Basic spam
            "frost_bolt",    -- Single target
            "arc_lash",      -- Melee option
            "ice_blade",     -- Melee option
            "spear",         -- Melee option
        }
    end
end

-- Function to adjust priorities for equipped items (placeholder for future expansion)
local function adjust_priorities_for_items(base_priorities)
    -- For now, just return the base priorities
    -- In the future, this could adjust priorities based on equipped items
    return base_priorities
end

-- Season 11 Leveling Guide: Returns spell priorities based on character level
local function get_leveling_priorities(character_level)
    if character_level <= 15 then
        -- Levels 1-15: Fire Bolt spam for fast leveling
        return {
            "flame_shield",  -- Defense first
            "ice_armor",     -- Defense second
            "fire_bolt",     -- PRIMARY: Fast spam damage
            "spark",         -- Mana generator
            "teleport",      -- Basic mobility
        }
    elseif character_level <= 25 then
        -- Levels 15-25: Transition to Fireball
        return {
            "flame_shield",  -- Defense
            "ice_armor",     -- Defense
            "fireball",      -- PRIMARY: Main damage spell
            "fire_bolt",     -- Backup spam
            "spark",         -- Mana generator
            "teleport",      -- Mobility
            "frost_nova",    -- Basic crowd control
        }
    elseif character_level <= 35 then
        -- Levels 25-35: Add Inferno for AoE
        return {
            "flame_shield",  -- Defense
            "ice_armor",     -- Defense
            "fireball",      -- Main damage
            "inferno",       -- PRIMARY AoE addition
            "fire_bolt",     -- Backup
            "spark",         -- Mana
            "teleport",      -- Mobility
            "frost_nova",    -- Crowd control
            "charged_bolts", -- AoE damage
        }
    elseif character_level <= 45 then
        -- Levels 35-45: Build specialization begins
        return {
            "flame_shield",  -- Defense
            "ice_armor",     -- Defense
            "ball",          -- Season 11 META: Ball Lightning
            "fireball",      -- Versatile nuke
            "inferno",       -- High AoE
            "chain_lightning", -- Chain damage
            "charged_bolts", -- AoE bolts
            "spark",         -- Mana
            "teleport",      -- Mobility
            "teleport_ench", -- Enhanced teleport
        }
    else  -- Level 45+: End-game priorities
        -- Use build-specific priorities (this will be handled by get_spell_priority)
        return get_spell_priority(1)  -- Default to Ball Lightning meta
    end
end

-- Main function that applies item adjustments
local function get_spell_priority(build_index, character_level)
    local base_priorities

    -- If character level is provided and below 45, use leveling priorities
    if character_level and character_level < 45 then
        base_priorities = get_leveling_priorities(character_level)
    else
        -- Use build-specific priorities for end-game
        base_priorities = get_base_spell_priority(build_index)
    end

    return adjust_priorities_for_items(base_priorities)
end

return get_spell_priority 