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
            coords = vector3(1782.529785, 3900.409424, 34.040485),
            label = 'Investigate the Church'
        },
        motel = {
            coords = vector3(1577.881226, 3748.834961, 34.035957),
            label = 'Investigate the Motel'
        },
        hospital = {
            coords = vector3(1762.927002, 3621.061035, 33.626545),
            label = 'Investigate the Hospital'
        },
        marina = {
            coords = vector3(1537.700317, 3771.182617, 33.050037),
            label = 'Investigate the Marina'
        },
        university = {
            coords = vector3(1516.604492, 3698.793213, 34.211338),
            label = 'Investigate the University'
        },
        compound = {
            coords = vector3(2011.241577, 3788.030273, 31.180798),
            label = 'Investigate the Compound'
        }
    }
}
