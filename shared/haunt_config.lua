-- Murder of 8 - hunt hours + ambient haunt configuration file
-- Loaded after config.lua so existing server-specific scene coordinates stay untouched.

Config.Hunt = Config.Hunt or {}
Config.Hunt.startHour = Config.Hunt.startHour or 21 -- 9:00 PM
Config.Hunt.endHour = Config.Hunt.endHour or 5      -- 5:00 AM
Config.Hunt.showDawnWarning = Config.Hunt.showDawnWarning ~= false
Config.Hunt.warningDurationMs = Config.Hunt.warningDurationMs or 8500

-- Live-server gating.
-- The dawn warning is a one-time 04:59 event, NOT a generic daytime popup.
Config.Hunt.dawnWarningHour = Config.Hunt.dawnWarningHour or 4
Config.Hunt.dawnWarningMinute = Config.Hunt.dawnWarningMinute or 59

-- A player counts as actively investigating only for a limited time after
-- interacting with Murder of 8 evidence/casebook while at a clue.
Config.Hunt.activeSessionTimeoutMs = Config.Hunt.activeSessionTimeoutMs or (12 * 60 * 1000)

-- Extra Sandy Shores safety fence. All current Murder of 8 scenes sit well
-- inside this area; players elsewhere on the server will never receive haunts.
Config.Hunt.requireSandy = Config.Hunt.requireSandy ~= false
Config.Hunt.sandyCenter = Config.Hunt.sandyCenter or vector3(1700.0, 3750.0, 35.0)
Config.Hunt.sandyRadius = Config.Hunt.sandyRadius or 900.0

-- "Actively investigating the clue" radius. Random scares and the dawn warning
-- require the player to be near an unlocked/current Murder of 8 scene.
Config.Hunt.activeSceneRadius = Config.Hunt.activeSceneRadius or 60.0 -- keep equal to Config.ScareDirector.sceneRadius

Config.Haunting = Config.Haunting or {}
Config.Haunting.enabled = Config.Haunting.enabled ~= false
Config.Haunting.onlyAfterInvestigationStarts = Config.Haunting.onlyAfterInvestigationStarts ~= false

-- Daytime hauntings are intentionally subtle. They remind the player that the
-- case has not stopped watching them even though evidence is locked until night.
Config.Haunting.day = Config.Haunting.day or {
    enabled = false,
    minDelayMs = 240000, -- 4 minutes
    maxDelayMs = 480000, -- 8 minutes
    shadowModel = 'a_m_m_skidrow_01',
    shadowDistance = 8.0,
    shadowLifetimeMs = 2400
}

-- Public-event default: no random daytime hauntings.
Config.Haunting.day.enabled = false

-- Night scares are much more aggressive and may happen while travelling
-- between scenes after the investigation has started.
Config.Haunting.night = Config.Haunting.night or {
    enabled = true,
    minDelayMs = 90000,  -- 1.5 minutes
    maxDelayMs = 180000, -- 3 minutes
    figureModel = 'a_m_m_skidrow_01',
    figureDistance = 1.85,
    figureLifetimeMs = 650,
    cameraShake = 0.62
}

Config.Messages = Config.Messages or {}
Config.Messages.daytimeLocked = Config.Messages.daytimeLocked
    or 'The trail has gone cold in daylight. Come back after 9:00 PM.'
Config.Messages.dawnApproaching = Config.Messages.dawnApproaching
    or 'The day is approaching. Come back later tonight to finish... do not let your guard down.'
