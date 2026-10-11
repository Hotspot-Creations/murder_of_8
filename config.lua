Config = {}

Config.Interaction = 'native' -- auto | ox_target | native  (native = press E at the spot, no target zones)
Config.OpenCasebookCommand = 'casebook'
Config.OpenCasebookKey = 'J'
Config.InteractKey = 38
Config.InteractionDistance = 2.55 -- was 1.7 (+50%)
Config.DrawDistance = 15.0

-- soft pulsing light on every piece of evidence still to find in an open chapter (night only)
Config.EvidenceGlow = {
    enabled = true,
    colour = { 80, 140, 255 }, -- cold blue
    range = 2.2,               -- metres
    intensity = 4.0,           -- bright enough to read inside lit interiors (the hospital)
    pulse = 0.25               -- 0 = steady, 1 = fades all the way out and back
}

-- audible clue cues: a clue the casebook tells you to listen for repeats its sound from the spot (NUI sound,
-- panned and faded by distance) while it is examinable and not yet found. interval ms, range/near metres.
Config.ClueCues = {
    nova_body_bag = { sound = 'phone_ring', interval = 9000, range = 45.0, near = 4.0, minVolume = 0.15 },
    dock_message = { sound = 'dock_knocks', interval = 12000, range = 45.0, near = 4.0, minVolume = 0.15 }
}

-- stuck nudge: a clue that has been open (examinable, not found) for afterMs rings the bell in 3D from its
-- spot whenever the player is within range metres, every interval ms, until it is documented.
Config.StuckNudge = {
    enabled = true,
    sound = 'bell',        -- promptsh_m8_bell through the Sandy Halloween bank, NUI bell otherwise
    afterMs = 300000,      -- 5 minutes
    range = 25.0,
    interval = 45000,
    near = 4.0, minVolume = 0.2
}

Config.Messages = {
    sceneInactive = "Whatever happened here isn't happening now.",
    sceneDisabled = 'This chapter has not been configured yet.',
    chapterLocked = "You don't know enough to understand this scene yet.",
    evidenceLocked = "Something about this doesn't make sense yet. Keep looking.",
    alreadyFound = "You've already documented this evidence.",
    progressSaved = 'Evidence added to your casebook.'
}


-- Custom Sandy interior detection.
--
-- DO NOT TOUCH THIS UNLESS YOU KNOW WHAT YOU'RE DOING.
--
-- The detector only checks a location once the player is close enough for
-- the map to be streamed. An "exterior" result is periodically re-checked,
-- so a late-streaming MLO can still be detected afterward.
Config.InteriorDetection = {
    enabled = true,

    -- How close the player must be to the test point before we ask GTA/FiveM
    -- whether an interior exists there.
    checkDistance = 60.0, -- inside every interior's own streaming range (the motel loads its rooms at 40-70 m)

    -- Time between re-checks for a location currently considered exterior.
    exteriorRecheckMs = 10000,

    -- Number of checks before we initially classify a streamed location as exterior.
    zeroConfirmations = 6,
    confirmationIntervalMs = 500,

    points = {
        church = vec3(1803.11, 3908.12, 34.65),
        motel = vec3(1586.54, 3744.38, 35.04),      -- motel reception (Venn); was the bottom edge of room 14
        hospital = vec3(1758.72, 3629.29, 34.58),
        marina = vec3(1522.79, 3784.71, 34.56),
        university = vec3(1535.62, 3689.92, 34.38),
        compound = vec3(1997.83, 3788.43, 29.31)
    }
}

Config.FinaleFallback = {
    enabled = true,
    coords = vec4(907.56, 3610.14, 31.82, 273.11),

    -- The apartment is remote from Sandy, so finale.lua briefly focuses that
    -- area while the screen is black before deciding whether the MLO exists.
    interiorCheckTimeoutMs = 5000,
    interiorCheckIntervalMs = 100,

    -- Fallback presentation timing.
    streamWaitMs = 900,
    endingTextDurationMs = 3500
}