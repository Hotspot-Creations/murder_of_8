Config = Config or {}

Config.Scenes = {
    burning_house = {
        chapter = 1,
        enabled = true,
        timeRestricted = true,
        startHour = 1,
        endHour = 3,
        evidence = {
            rusk_body = vec3(1444.43, 3641.53, 34.67),
            fire_report = vector3(1451.45, 3612.79, 34.80),
            burned_photo = vector3(1450.74, 3621.19, 34.78),
            bell = vector3(1424.59, 3640.26, 34.93)
        },
        silhouette = {
            enabled = true,
            coords = vector4(1447.50, 3622.27, 35.17, 208.43),
            model = "s_m_y_westsec_01",
            startMinute = 0,
            endMinute = 12,
            visibleForMs = 5500
        }
    },
    church = {
        chapter = 2,
        enabled = true,
        timeRestricted = false,
        evidence = {
            vale_body = vector3(1821.39, 3946.89, 29.60),
            burial_ledger = vector3(1808.25, 3909.64, 35.04),
            fresh_coffin = vec3(1810.84, 3910.66, 34.05),
            nova_bible = vector3(1814.32, 3908.81, 35.04),
            -- cemetry_wall = vector3(0.0, 0.0, 0.0), -- Removed `E` Easter Egg from the church scene. It was a fun idea, but it was too unprofessional and not in line with the tone of the story.
            motel_key = vector3(1833.47, 3932.55, 32.45)
        }
    },
    motel = {
        chapter = 3,
        enabled = true,
        timeRestricted = false,
        evidence = {
            venn_body = vector3(1586.54, 3744.38, 35.04),
            room_scratches = vector3(1589.72, 3741.88, 35.04),
            underground_cells = vector3(1578.27, 3738.42, 38.65),
            cell_eight = vector3(1591.36, 3744.46, 31.41),
            motel_recorder = vector3(1587.34, 3740.44, 31.41),
            hospital_wristband = vector3(1616.71, 3790.14, 38.66)
        }
    },
    hospital = {
        chapter = 4,
        enabled = true,
        timeRestricted = false,
        evidence = {
            harrow_body = vector3(1741.51, 3633.23, 34.58),
            transfer_records = vector3(1777.38, 3643.88, 34.58),
            false_identities = vector3(1764.49, 3642.72, 34.58),
            nova_body_bag = vector3(1738.42, 3628.84, 34.58),
            train_manifest = vector3(1759.48, 3627.40, 34.58)
        }
    },
    station = {
        chapter = 5,
        enabled = true,
        timeRestricted = false,
        evidence = {
            crowe_body = vector3(1910.986, 3570.935, 38.817), -- on the platform (heading 212.585 if a body prop is added later)
            frozen_clock = vector3(1897.93, 3576.30, 38.77), -- the ticket window (position taken in game)
            eight_suitcases = vector3(1903.966, 3572.455, 38.819), -- position taken in game (heading 168.792)
            crowe_letter = vector3(1897.84, 3575.45, 38.81),
            fake_departure = vector3(1901.72, 3579.0, 38.60), -- the dropped ticket prop (was 8 m away)
            marina_key = vector3(1903.966, 3572.455, 38.819) -- in the eighth suitcase, same spot as eight_suitcases
        }
    },
    marina = {
        chapter = 6,
        enabled = true,
        timeRestricted = false,
        evidence = {
            mercer_body = vector3(1492.9507, 3923.7634, 30.1826),
            evidence_boxes = vector3(1428.28, 3818.81, 31.18), -- Slightly changed due to weird interior glitch
            weighted_cache = vector3(1522.04, 3792.75, 38.28),
            mercer_tape = vector3(1516.70, 3786.60, 38.22),
            dock_message = vector3(1480.12, 3875.05, 32.78),
            university_file = vector3(1532.31, 3782.02, 34.51)
        }
    },
    university = {
        chapter = 7,
        enabled = true,
        timeRestricted = false,
        evidence = {
            kade_body = vector3(1509.94, 3672.10, 34.82),
            archive_wall = vector3(1520.97, 3691.14, 39.51),
            nova_journal = vector3(1525.54, 3686.48, 35.18),
            nova_last_recording = vector3(1543.09, 3700.01, 35.37),
            compound_photo = vector3(1533.44, 3707.61, 35.37),
            fresh_message = vec3(1540.54, 3673.89, 34.38)
        }
    },
    compound = {
        chapter = 8,
        enabled = true,
        timeRestricted = false,
        evidence = {
            eight_chairs = vector3(1975.04, 3780.82, 27.90), -- on the chair row (chair_2); was at the pit bottom 16 m away
            surveillance_wall = vector3(1992.09, 3786.79, 35.39),
            nova_body = vector3(1998.63, 3782.87, 35.16),
            voss = vec3(1978.71, 3774.67, 27.37),
            voss_confession = vec3(1978.39, 3776.68, 27.37),
            final_bell = vector3(1990.12, 3781.93, 28.60), -- the button on the pit wall
            last_message = vec3(1637.58, 3520.47, 49.49)
        }
    }
}

Config.EvidenceProps = {
    {
        id = "fake_departure",
        model = "darkvanar_halloween_train_ticket",
        coords = vector4(1901.72, 3579.0, 37.82, 90.0)
    },
    {
        id = "burned_photo",
        model = "darkvanar_halloween_pic_01",
        coords = vector4(1450.74, 3621.19, 33.65, 200.0)
    },
    {
        id = "hospital_wristband",
        model = "v_med_bottles3",
        coords = vector4(1617.23, 3790.36, 38.21, 293.74)
    },
    {
        id = "fresh_message",
        model = "darkvanar_halloween_uni_text",
        coords = vec4(1541.43, 3671.59, 35.50, 25)
    },
    {
        id = "mercer_tape",
        model = "prop_tapeplayer_01",
        coords = vector4(1516.42, 3787.09, 37.40, 25.63)
    },
    {
        id = "nova_last_recording",
        model = "prop_tapeplayer_01",
        coords = vector4(1543.79, 3699.84, 34.99, 242.94)
    },
    {
        id = "compound_photo",
        model = "darkvanar_halloween_pic_01",
        coords = vector4(1533.8131, 3706.9414, 36.0187, 23.82)
    },
    -- Nova, hanging in the garage bathroom (chapter 8). Separate instance key so the examine point stays at
    -- the scene coords instead of jumping to the rope origin.
    {
        id = "nova_body",
        instance = "nova_hanging",
        model = "darkvanar_halloween_hanging_corpse_01",
        coords = vector4(1998.63, 3782.87, 35.10, 90.0), -- rope top at the 2.8 m ceiling, feet just off the floor
        collision = false
    },
    -- 8  chairs
    {
        id = "eight_chairs",
        instance = "chair_1",
        model = "prop_chair_03",
        coords = vec4(1973.8, 3783.16, 27.37, 115.00)
    },
    {
        id = "eight_chairs",
        instance = "chair_2",
        model = "prop_chair_03",
        coords = vec4(1975.04, 3780.82, 27.37, 115.00)
    },
    {
        id = "eight_chairs",
        instance = "chair_3",
        model = "prop_chair_03",
        coords = vec4(1976.76, 3777.78, 27.37, 115.00)
    },
    {
        id = "eight_chairs",
        instance = "chair_7",
        model = "prop_chair_03",
        coords = vec4(1987.28, 3776.32, 27.36, 295.00)
    },
    {
        id = "eight_chairs",
        instance = "chair_4",
        model = "prop_chair_03",
        coords = vec4(1980.26, 3772.09, 27.37, 115.00)
    },
    {
        id = "eight_chairs",
        instance = "chair_5",
        model = "prop_chair_03",
        coords = vec4(1981.42, 3770.2, 27.37, 115.00)
    },
    {
        id = "eight_chairs",
        instance = "chair_6",
        model = "prop_chair_03",
        coords = vec4(1988.86, 3774.3, 27.36, 295.00)
    },
    -- [Chair 8]
    {
        id = "eight_chairs",
        instance = "chair_8",
        model = "prop_chair_03",
        coords = vec4(1978.41, 3775.51, 27.37, 115.00)
    }
    -- Final
}

Config.CompoundChair8 = {
    instance = "chair_8",
    voss = {
        model = 's_m_y_prisoner_01',
        offset = vector3(0.00, -0.12, 0.47),
        headingOffset = 180.0
    }
}

Config.CompoundChairEvidence = {
    {
        chair = 'chair_1',
        id = 'chair_boot',
        model = 'v_res_fa_boot01l',

        offset = vector3(
            0.00,
            0.00,
            0.55
        ),

        rotation = vector3(
            0.0,
            0.0,
            90.0
        )
    },

    {
        chair = 'chair_2',
        id = 'chair_bible',
        model = 'm23_2_int5_m232_notebook',

        offset = vector3(
            0.00,
            0.00,
            0.46
        ),

        rotation = vector3(
            0.0,
            0.0,
            0.0
        )
    },

    {
        chair = 'chair_3',
        id = 'chair_pills',
        model = 'v_med_bottles3',

        offset = vector3(
            0.00,
            0.00,
            0.46
        ),

        rotation = vector3(
            0.0,
            0.0,
            0.0
        )
    },

    {
        chair = 'chair_4',
        id = 'chair_phone',
        model = 'prop_v_m_phone_o1s',

        offset = vector3(
            0.00,
            0.00,
            0.52
        ),

        rotation = vector3(
            0.0,
            0.0,
            0.0
        )
    },

    {
        chair = 'chair_5',
        id = 'chair_ticket',
        model = 'darkvanar_halloween_train_ticket',

        offset = vector3(
            0.00,
            0.00,
            0.46
        ),

        rotation = vector3(
            0.0,
            0.0,
            0.0
        )
    },

    {
        chair = 'chair_6',
        id = 'chair_tape',
        model = 'prop_tapeplayer_01',

        offset = vector3(
            0.00,
            0.00,
            0.55
        ),

        rotation = vector3(
            0.0,
            0.0,
            0.0
        )
    },

    {
        chair = 'chair_7',
        id = 'chair_compound',
        model = 'v_med_p_notebook',

        offset = vector3(
            0.00,
            0.00,
            0.46
        ),

        rotation = vector3(
            0.0,
            0.0,
           180.0
        )
    }
}
-- Physical evidence helpers ---------------------------------------------------
-- Config.EvidenceProps above is the ONE placement list.
-- If an evidence prop exists here, interactions/scares use its physical position.
function M8_GetEvidenceProp(evidenceId)
    for _, prop in ipairs(Config.EvidenceProps or {}) do
        if prop.id == evidenceId then
            return prop
        end
    end

    return nil
end

function M8_GetEvidenceWorldCoords(evidenceId, fallback)
    local prop = M8_GetEvidenceProp(evidenceId)

    if prop and prop.coords then
        return vector3(prop.coords.x, prop.coords.y, prop.coords.z)
    end

    return fallback
end
