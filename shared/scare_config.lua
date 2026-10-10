-- Murder of 8 - Advanced Scare Director configuration
-- Loaded after haunt_config.lua. This does not replace your scene coordinates.

Config = Config or {}
Config.ScareDirector = Config.ScareDirector or {}

local D = Config.ScareDirector

D.enabled = D.enabled ~= false

-- Master behavior.
D.onlyAfterInvestigationStarts = D.onlyAfterInvestigationStarts ~= false
D.allowWhileDriving = D.allowWhileDriving ~= false
D.debug = D.debug ~= false

-- Major scare pacing. The director also runs smaller "micro-haunts" between these.
D.majorMinDelayMs = D.majorMinDelayMs or 90000
D.majorMaxDelayMs = D.majorMaxDelayMs or 240000
D.microMinDelayMs = D.microMinDelayMs or 45000
D.microMaxDelayMs = D.microMaxDelayMs or 120000

-- Scares stay around the clues: random scares and micro-haunts only within sceneRadius metres of an
-- open scene's evidence, never on the road between scenes. (Authored after-evidence scares and the
-- daytime hauntings are not affected.)
D.onlyNearScenes = D.onlyNearScenes ~= false
D.sceneRadius = D.sceneRadius or 60.0

-- Prevent the same scare from becoming predictable.
D.globalRecoveryMs = D.globalRecoveryMs or 26000
D.repeatCooldownMs = D.repeatCooldownMs or 180000

-- Bellman / figure setup.
D.figureModel = D.figureModel or ((Config.Haunting and Config.Haunting.night and Config.Haunting.night.figureModel) or 'a_m_m_skidrow_01')
D.bodyModel = D.bodyModel or 'a_m_m_skidrow_01'
D.figureAlpha = D.figureAlpha or 235

-- Tension system. Higher chapters and the 1-3 AM window build tension faster.
D.tension = D.tension or {
    minTrigger = 54,
    maxTrigger = 86,
    earlyGrowth = 0.40,
    lateGrowth = 0.62,
    peakGrowth = 0.92,
    predawnGrowth = 0.70,
    interiorBonus = 0.16,
    stationaryBonus = 0.14,
    chapterBonus = 0.025
}

-- Individual scare cooldowns.
D.cooldowns = D.cooldowns or {
    face = 105000,
    turn = 145000,
    rush = 175000,
    blink = 220000,
    watcher = 90000,
    peripheral = 115000,
    ['false'] = 180000,
    body = 240000,
    roadside = 150000,
    message = 120000
}

-- Short text flashes. These are intentionally rare.
D.messages = D.messages or {
    'DON\'T TURN AROUND.',
    'HE IS CLOSER NOW.',
    'YOU MISSED ONE.',
    'NOVA DIDN\'T WRITE THAT.',
    'STOP COUNTING.',
    'YOU WERE NEVER ALONE.',
    'THE BELL IS BEHIND YOU.'
}

-- Context restrictions.
D.maxWalkScareSpeed = D.maxWalkScareSpeed or 6.5
D.bodyDropMaxSpeed = D.bodyDropMaxSpeed or 1.8
D.rushDistance = D.rushDistance or 12.0
D.watcherMinDistance = D.watcherMinDistance or 10.0
D.watcherMaxDistance = D.watcherMaxDistance or 16.0

-- Existing daytime haunting remains intentionally lighter.
D.daytimeMajorScares = D.daytimeMajorScares == true
