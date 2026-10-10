-- Murder of 8 - v1.6 Scripted Chapter Jumpscares
--
-- These are authored scares tied to investigation progress. The random Scare
-- Director still handles ambient haunting between objectives.

Config = Config or {}
Config.ScriptedScares = Config.ScriptedScares or {}

local S = Config.ScriptedScares

S.enabled = S.enabled ~= false
-- Local-only figure used for Bellman appearances. This falls back to the
-- existing Scare Director model so you only need to change one model later.
S.figureModel = S.figureModel
    or (Config.ScareDirector and Config.ScareDirector.figureModel)
    or 'a_m_m_skidrow_01'

S.bodyModel = S.bodyModel
    or (Config.ScareDirector and Config.ScareDirector.bodyModel)
    or 'a_m_m_skidrow_01'

-- Safety/context rules.
S.maxPlayerSpeed = S.maxPlayerSpeed or 5.5
S.casebookCloseTimeoutMs = S.casebookCloseTimeoutMs or 18000
S.sequenceTimeoutMs = S.sequenceTimeoutMs or 16000
S.cleanupMs = S.cleanupMs or 9000

-- How close the most aggressive scares can place a figure.
S.faceDistance = S.faceDistance or 1.05
S.turnDistance = S.turnDistance or 1.35
S.passageDistance = S.passageDistance or 4.25
S.watcherDistance = S.watcherDistance or 8.5

-- One-shot evidence choreography. Setting an entry to false disables that
-- specific authored scare without changing the story/evidence.
S.evidence = S.evidence or {
    -- Chapter 1 - Burning House
    burned_photo = 'peripheral_peek',
    bell = 'exit_face',

    -- Chapter 2 - Church
    fresh_coffin = 'coffin_turn',
    nova_bible = 'aisle_watcher',
    motel_key = 'exit_pass',

    -- Chapter 3 - Motel
    room_scratches = 'hall_pass',
    cell_eight = 'cell_turn',
    motel_recorder = 'false_exit',

    -- Chapter 4 - Hospital
    false_identities = 'morgue_blink',
    nova_body_bag = 'body_drop_combo',
    train_manifest = 'hospital_exit',

    -- Chapter 5 - Train Station
    eight_suitcases = 'platform_rush',
    fake_departure = 'track_watcher',
    marina_key = 'station_exit',

    -- Chapter 6 - Marina
    weighted_cache = 'wet_body',
    dock_message = 'dock_turn',
    university_file = 'dock_exit',

    -- Chapter 7 - University
    archive_wall = 'archive_watcher',
    nova_last_recording = 'archive_turn',
    fresh_message = 'blackout_behind',

    -- Chapter 8 - Compound
    surveillance_wall = 'compound_blink',
    nova_body = 'compound_false',
    voss_confession = 'compound_turn'
}
