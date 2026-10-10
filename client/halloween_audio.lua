-- Murder of 8 - 3D sounds through the Sandy Halloween bank (prompt_sandy_halloween)
--
-- When the Halloween map pack is running, the literal scare sounds (footsteps, whispers, chains,
-- a creak, the distant scream, the coffin and dock knocks) play from the world through its sound
-- bank instead of the 2D NUI files: from the Bellman ped when there is one (so a running figure's
-- footsteps follow it), from the coffin / the dock for the knocks, otherwise from a point behind the
-- player (pan -> side). Only this client hears them.
-- The story's own sounds live in that bank too (2026-10-08): the Bellman's hand bell, breaths, a
-- door creak, the body thud and the cell door slam.
-- The synthetic stingers are replaced too: a hit (jump_sting) is a scream from the figure's face,
-- a vanish (reverse_sting) a whisper from where it stood; the 2D 'impact' hit is removed (silent).
-- static, heartbeat, sub_rumble, ambience, the phone and the train horn stay in the NUI.
-- Switch: Config.NativeHorrorAudio.useSandyHalloween.

M8HalloweenAudio = M8HalloweenAudio or {}

local RESOURCE = 'prompt_sandy_halloween'
local SIDE_METRES = 2.5 -- pan 1.0 = this far to the right

-- their name -> bank sound (or sounds: one picked at random); back/up = metres behind the player
-- (negative = in front) and height when no figure/spot is given; hold = ms the hidden speaker
-- lives; pattern = knock timings (ms gaps); fromSpot = use the evidence position when the caller
-- knows it
M8HalloweenAudio.Map = {
    footsteps      = { sound = 'promptsh_footsteps',       back = 3.0,  up = -0.9, hold = 8000 },
    footsteps_run  = { sound = 'promptsh_footsteps',       back = 6.0,  up = -0.9, hold = 8000 },
    whisper        = { sound = 'promptsh_ghost_whisper',   back = 1.4,  up = 0.6,  hold = 6000 },
    breath         = { sounds = { 'promptsh_m8_breath_01', 'promptsh_m8_breath_02' },
                       back = 1.4, up = 0.6, hold = 5000 },
    chain_drag     = { sound = 'promptsh_chains',          back = 3.5,  up = 0.0,  hold = 6000 },
    door_creak     = { sound = 'promptsh_m8_door_creak',   back = 2.8,  up = 0.6,  hold = 6000 },
    distant_scream = { sound = 'promptsh_amb_scream',      back = 40.0, up = 1.0,  hold = 9000 },
    bell           = { sound = 'promptsh_m8_bell',         back = 2.5,  up = 0.5,  hold = 5000, fromSpot = true },
    archive_bell   = { sound = 'promptsh_m8_bell',         back = 2.5,  up = 0.5,  hold = 5000, fromSpot = true },
    body_drop      = { sound = 'promptsh_m8_body_thud',    back = -2.2, up = 0.0,  hold = 4000 },
    jump_sting     = { sounds = { 'promptsh_scream_el', 'promptsh_scream_gta' },
                       back = -1.0, up = 0.5, hold = 4000 },
    reverse_sting  = { sound = 'promptsh_ghost_whisper',   back = 1.4,  up = 0.6,  hold = 6000 },
    impact         = { silent = true },                   -- the scream is the hit; no 2D clang on top
    metal_clang    = { sound = 'promptsh_m8_cell_slam',    back = 3.0,  up = 0.5,  hold = 6000, fromSpot = true },
    cell_slam      = { sound = 'promptsh_m8_cell_slam',    back = 3.0,  up = 0.5,  hold = 6000, fromSpot = true },
    coffin_knocks  = { sounds = { 'promptsh_knock_01', 'promptsh_knock_02', 'promptsh_knock_03' },
                       pattern = { 0, 520, 610 }, back = 2.0, up = 0.15, hold = 3000, fromSpot = true },
    dock_knocks    = { sounds = { 'promptsh_knock_under' },                          -- 3 / 3 / 2 = 8
                       pattern = { 0, 320, 320, 780, 320, 320, 780, 320 }, back = 2.0, up = -1.5, hold = 3000,
                       fromSpot = true },
}

-- pure helpers (no natives) - tested by tests/halloween_audio_spec.lua
function M8HalloweenAudio.Resolve(name)
    local c = Config.NativeHorrorAudio
    if not (c and c.useSandyHalloween) then return nil end
    return M8HalloweenAudio.Map[name]
end

-- metres: behind, to the right (from the pan, clamped to -1..1), up
function M8HalloweenAudio.Offset(entry, pan)
    pan = math.max(-1.0, math.min(1.0, tonumber(pan) or 0.0))
    return entry.back, pan * SIDE_METRES, entry.up
end

-- the bank sound for an entry (variants: one at random)
function M8HalloweenAudio.Pick(entry)
    return entry.sound or entry.sounds[math.random(#entry.sounds)]
end

-- runtime ---------------------------------------------------------------------------------------

-- the gameplay camera's yaw, like the rest of the scares (a figure "behind" is behind the camera)
local function pointBehind(back, side, up)
    local yaw = math.rad(GetGameplayCamRot(2).z)
    local forward = vector3(-math.sin(yaw), math.cos(yaw), 0.0)
    local right = vector3(forward.y, -forward.x, 0.0)
    return GetEntityCoords(PlayerPedId()) - forward * back + right * side + vector3(0.0, 0.0, up)
end

-- opts = { pan, entity, at }. true = taken (the bank plays it), false = not ours, let the NUI play it
function M8HalloweenAudio.Play(name, opts)
    local entry = M8HalloweenAudio.Resolve(name)
    if not entry or GetResourceState(RESOURCE) ~= 'started' then return false end
    if entry.silent then return true end -- taken, and nothing plays
    opts = opts or {}

    local ok, accepted = pcall(function()
        local hw = exports[RESOURCE]
        local at
        if opts.at and entry.fromSpot then
            at = opts.at + vector3(0.0, 0.0, entry.up)
        else
            at = pointBehind(M8HalloweenAudio.Offset(entry, opts.pan))
        end

        if entry.pattern then
            local t = 0
            for i, gap in ipairs(entry.pattern) do
                t = t + gap
                local sound = entry.sounds[((i - 1) % #entry.sounds) + 1]
                SetTimeout(t, function() hw:PlayAt(sound, at.x, at.y, at.z, entry.hold) end)
            end
            return true
        end

        local sound = M8HalloweenAudio.Pick(entry)
        local fromFigure = opts.entity and DoesEntityExist(opts.entity)
        if Config.NativeHorrorAudio.debug then
            print(('^5[Murder of 8 3D]^0 %s -> %s %s'):format(name, sound,
                fromFigure and 'from the figure' or ('at %.1f %.1f %.1f'):format(at.x, at.y, at.z)))
        end
        if fromFigure then
            return hw:PlayFromEntity(sound, opts.entity, entry.hold)
        end
        return hw:PlayAt(sound, at.x, at.y, at.z, entry.hold)
    end)

    if not ok then
        print(('[Murder of 8] Sandy Halloween audio failed for %s: %s'):format(name, tostring(accepted)))
        return false
    end
    return accepted == true
end
