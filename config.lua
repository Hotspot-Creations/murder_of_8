Config = {}

Config.Debug = true
Config.Interaction = 'native' -- auto | ox_target | native  (native = press E at the spot, no target zones)
Config.OpenCasebookCommand = 'casebook'
Config.OpenCasebookKey = 'J'
Config.InteractKey = 38
Config.InteractionDistance = 1.7
Config.DrawDistance = 15.0

-- soft pulsing light on every piece of evidence still to find in an open chapter (night only)
Config.EvidenceGlow = {
    enabled = true,
    colour = { 80, 140, 255 }, -- cold blue
    range = 1.8,               -- metres
    intensity = 2.5,
    pulse = 0.25               -- 0 = steady, 1 = fades all the way out and back
}

Config.Messages = {
    sceneInactive = "Whatever happened here isn't happening now.",
    sceneDisabled = 'This chapter has not been configured yet.',
    chapterLocked = "You don't know enough to understand this scene yet.",
    evidenceLocked = "Something about this doesn't make sense yet. Keep looking.",
    alreadyFound = "You've already documented this evidence.",
    progressSaved = 'Evidence added to your casebook.'
}
