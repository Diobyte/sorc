-- Import the spell_data class from the global context
local spell_data_class = _G.spell_data

-- Create a module to hold our spell data
local spell_data_module = {}

-- Function to create spell data objects
function spell_data_module.create_spell_data(radius, range, cast_delay, projectile_speed, has_wall_collision, spell_id, geom_type, target_type)
    return spell_data_class:new(
        radius,
        range,
        cast_delay,
        projectile_speed,
        has_wall_collision,
        spell_id,
        geom_type or spell_geometry.rectangular,
        target_type or targeting_type.skillshot
    )
end

-- Define all spell data
local spell_data = {
    -- active spells
    arc_lash = {
        spell_id = 297902,
        data = spell_data_module.create_spell_data(
            1.5,           -- radius (melee range)
            3.0,           -- range
            0.8,           -- cast_delay
            2.0,           -- projectile_speed
            true,          -- has_collision
            297902,        -- spell_id
            spell_geometry.circular,
            targeting_type.skillshot
        )
    },
    ball = {
        spell_id = 514030,
        data = spell_data_module.create_spell_data(
            0.8,           -- radius (bouncing projectile)
            12.0,          -- range
            0.3,           -- cast_delay
            3.0,           -- projectile_speed
            true,          -- has_collision
            514030,        -- spell_id
            spell_geometry.rectangular,
            targeting_type.skillshot
        )
    },        
    blizzard = {
        spell_id = 291403,
        data = spell_data_module.create_spell_data(
            6.0,           -- radius (large AoE)
            15.0,          -- range
            0.0,           -- cast_delay (instant)
            0.0,           -- projectile_speed
            false,         -- has_collision
            291403,        -- spell_id
            spell_geometry.circular,
            targeting_type.skillshot
        )
    },
    chain_lightning = {
        spell_id = 292757,
        data = spell_data_module.create_spell_data(
            0.5,           -- radius (chain target)
            20.0,          -- range
            0.4,           -- cast_delay
            5.0,           -- projectile_speed
            true,          -- has_collision
            292757,        -- spell_id
            spell_geometry.rectangular,
            targeting_type.skillshot
        )
    },
    charged_bolts = {
        spell_id = 171937,
        data = spell_data_module.create_spell_data(
            3.0,           -- radius (AoE bolts)
            15.0,          -- range
            0.5,           -- cast_delay
            3.5,           -- projectile_speed
            true,          -- has_collision
            171937,        -- spell_id
            spell_geometry.circular,
            targeting_type.skillshot
        )
    },
    deep_freeze = {
        spell_id = 291827,
        data = spell_data_module.create_spell_data(
            4.0,           -- radius (freeze AoE)
            8.0,           -- range
            0.6,           -- cast_delay
            0.0,           -- projectile_speed
            false,         -- has_collision
            291827,        -- spell_id
            spell_geometry.circular,
            targeting_type.skillshot
        )
    },
    evade = {
        spell_id = 337031
    },
    familiars = {
        spell_id = 1627075,
        data = spell_data_module.create_spell_data(
            0.0,           -- radius (summon)
            0.0,           -- range (self-cast)
            0.0,           -- cast_delay (instant)
            0.0,           -- projectile_speed
            false,         -- has_collision
            1627075,       -- spell_id
            spell_geometry.circular,
            targeting_type.skillshot
        )
    },
    fire_bolt = {
        spell_id = 153249,
        data = spell_data_module.create_spell_data(
            0.5,           -- radius
            30.0,          -- range (long range spam)
            0.3,           -- cast_delay
            4.5,           -- projectile_speed
            true,          -- has_collision
            153249,        -- spell_id
            spell_geometry.rectangular,
            targeting_type.skillshot
        )
    },
    fireball = {
        spell_id = 165023,
        data = spell_data_module.create_spell_data(
            3.0,           -- radius (AoE explosion)
            25.0,          -- range
            0.6,           -- cast_delay
            3.0,           -- projectile_speed
            true,          -- has_collision
            165023,        -- spell_id
            spell_geometry.circular,
            targeting_type.skillshot
        )
    },
    firewall = {
        spell_id = 111422,
        data = spell_data_module.create_spell_data(
            1.5,           -- radius (wall width)
            15.0,          -- range
            0.4,           -- cast_delay
            0.0,           -- projectile_speed
            false,         -- has_collision
            111422,        -- spell_id
            spell_geometry.rectangular,
            targeting_type.skillshot
        )
    },
    flame_shield = {
        spell_id = 167341,
        data = spell_data_module.create_spell_data(
            0.0,           -- radius (self-buff)
            0.0,           -- range (self-cast)
            0.0,           -- cast_delay (instant)
            0.0,           -- projectile_speed
            false,         -- has_collision
            167341,        -- spell_id
            spell_geometry.circular,
            targeting_type.skillshot
        )
    },
    frost_bolt = {
        spell_id = 287256,
        data = spell_data_module.create_spell_data(
            0.5,           -- radius
            25.0,          -- range
            0.4,           -- cast_delay
            4.0,           -- projectile_speed
            true,          -- has_collision
            287256,        -- spell_id
            spell_geometry.rectangular,
            targeting_type.skillshot
        )
    },
    frost_nova = {
        spell_id = 291215,
        data = spell_data_module.create_spell_data(
            4.0,           -- radius (AoE freeze)
            0.0,           -- range (self-cast)
            0.3,           -- cast_delay
            0.0,           -- projectile_speed
            false,         -- has_collision
            291215,        -- spell_id
            spell_geometry.circular,
            targeting_type.skillshot
        )
    },
    frozen_orb = {
        spell_id = 291347,
        data = spell_data_module.create_spell_data(
            4.0,           -- radius (large AoE)
            20.0,          -- range
            1.0,           -- cast_delay
            2.5,          -- projectile_speed
            false,          -- has_collision
            291347,        -- spell_id
            spell_geometry.circular,
            targeting_type.skillshot
        )
    },
    ice_armor = {
        spell_id = 297039,
        data = spell_data_module.create_spell_data(
            0.0,           -- radius (self-buff)
            0.0,           -- range (self-cast)
            0.0,           -- cast_delay (instant)
            0.0,           -- projectile_speed
            false,         -- has_collision
            297039,        -- spell_id
            spell_geometry.circular,
            targeting_type.skillshot
        )
    },
    hydra = {
        spell_id = 146743,
        data = spell_data_module.create_spell_data(
            1.0,           -- radius (summon size)
            15.0,          -- range
            0.0,           -- cast_delay (instant summon)
            3.0,           -- projectile_speed
            true,          -- has_collision
            146743,        -- spell_id
            spell_geometry.rectangular,
            targeting_type.skillshot
        )
    },
    ice_blade = {
        spell_id = 291492,
        data = spell_data_module.create_spell_data(
            0.0,           -- radius (self-buff)
            0.0,           -- range (self-cast)
            0.0,           -- cast_delay (instant)
            0.0,           -- projectile_speed
            false,         -- has_collision
            291492,        -- spell_id
            spell_geometry.circular,
            targeting_type.skillshot
        )
    },
    ice_shards = {
        spell_id = 293195,
        data = spell_data_module.create_spell_data(
            0.5,           -- radius (per projectile)
            20.0,          -- range
            0.5,           -- cast_delay
            4.0,           -- projectile_speed
            true,          -- has_collision
            293195,        -- spell_id
            spell_geometry.rectangular,
            targeting_type.skillshot
        )
    },
    incinerate = {
        spell_id = 292737,
        data = spell_data_module.create_spell_data(
            1.0,           -- radius (beam width)
            8.0,           -- range
            0.5,           -- cast_delay
            0.0,           -- projectile_speed (beam)
            false,         -- has_collision
            292737,        -- spell_id
            spell_geometry.rectangular,
            targeting_type.skillshot
        )
    },
    inferno = {
        spell_id = 294198,
        data = spell_data_module.create_spell_data(
            6.0,           -- radius (large AoE)
            0.0,           -- range (self-cast)
            0.8,           -- cast_delay
            0.0,           -- projectile_speed
            false,         -- has_collision
            294198,        -- spell_id
            spell_geometry.circular,
            targeting_type.skillshot
        )
    },
    meteor = {
        spell_id = 296998,
        data = spell_data_module.create_spell_data(
            5.0,           -- radius (impact AoE)
            15.0,          -- range
            0.0,           -- cast_delay (instant)
            0.0,           -- projectile_speed
            false,         -- has_collision
            296998,        -- spell_id
            spell_geometry.circular,
            targeting_type.skillshot
        )
    },
    spark = {
        spell_id = 143483,
        data = spell_data_module.create_spell_data(
            0.5,           -- radius
            10.0,          -- range
            1.0,           -- cast_delay
            3.5,           -- projectile_speed
            false,         -- has_collision
            143483,        -- spell_id
            spell_geometry.rectangular,
            targeting_type.skillshot
        )
    },
    spear = {
        spell_id = 292074,
        data = spell_data_module.create_spell_data(
            1.0,           -- radius (piercing projectile)
            20.0,          -- range
            0.1,           -- cast_delay
            6.0,           -- projectile_speed
            false,         -- has_collision
            292074,        -- spell_id
            spell_geometry.rectangular,
            targeting_type.skillshot
        )
    },
    teleport = {
        spell_id = 288106,
        data = spell_data_module.create_spell_data(
            2.0,           -- radius (teleport range)
            35.0,          -- range
            0.3,           -- cast_delay
            0.0,           -- projectile_speed (instant)
            false,         -- has_collision
            288106,        -- spell_id
            spell_geometry.circular,
            targeting_type.skillshot
        )
    },
    teleport_ench = {
        spell_id = 959728,
        data = spell_data_module.create_spell_data(
            2.0,           -- radius (enhanced teleport)
            35.0,          -- range
            0.3,           -- cast_delay
            0.0,           -- projectile_speed (instant)
            false,         -- has_collision
            959728,        -- spell_id
            spell_geometry.circular,
            targeting_type.skillshot
        )
    },
    unstable_current = {
        spell_id = 517417,
        data = spell_data_module.create_spell_data(
            9.0,           -- radius (massive AoE)
            0.0,           -- range (self-cast)
            0.0,           -- cast_delay (instant)
            0.0,           -- projectile_speed
            false,         -- has_collision
            517417,        -- spell_id
            spell_geometry.circular,
            targeting_type.skillshot
        )
    },

    -- passives
    -- Would love to implement this but unable to find what the buff_id would be
    -- in_combat_area = {
    --    spell_id = 24312,
    --    buff_id = 24313
    --},
    
    -- enemies
    enemies = {
        damage_resistance = {
            spell_id = 1094180,
            buff_ids = {
                provider = 2771801864,
                receiver = 2182649012
            }
        }
    }
}

-- Merge spell_data_module functions with spell_data for easier access
for k, v in pairs(spell_data_module) do
    spell_data[k] = v
end

return spell_data