Config = Config or {}

-- Exterior-only evidence access.
--
-- These are NOT the interior-detection coordinates.
-- Put each point OUTSIDE the inaccessible building, where a player can physically
-- stand and press E / use ox_target when that building's custom interior is absent.
--
-- Leave a point at 0,0,0 until you have chosen its exterior interaction location.
Config.ExteriorAccess = Config.ExteriorAccess or {
    enabled = true,
    drawDistance = 18.0,
    interactionDistance = 2.75,
    targetRadius = 1.35,

    -- Evidence that is completed automatically by a cinematic/finale and should
    -- never be handed out by the exterior entrance proxy.
    automaticEvidence = {
        last_message = true
    },

    locations = {
        church = {
            coords = vector3(0.0, 0.0, 0.0), -- exterior church entrance
            label = 'Investigate the Church'
        },
        motel = {
            coords = vector3(0.0, 0.0, 0.0), -- exterior motel investigation point
            label = 'Investigate the Motel'
        },
        hospital = {
            coords = vector3(0.0, 0.0, 0.0), -- exterior hospital entrance
            label = 'Investigate the Hospital'
        },
        university = {
            coords = vector3(0.0, 0.0, 0.0), -- exterior university/archive entrance
            label = 'Investigate the University'
        },
        compound = {
            coords = vector3(0.0, 0.0, 0.0), -- exterior compound investigation point
            label = 'Investigate the Compound'
        }
    }
}
