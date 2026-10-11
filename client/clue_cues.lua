-- Murder of 8 - audible clue cues
--
-- Two kinds of help, both only for a clue that is OPEN right now (chapter reached, prerequisites met,
-- not found yet, night):
--
--  * Clue cues (Config.ClueCues): a clue whose casebook hint says "listen" repeats its own sound from the
--    spot while you are within range - the phone in the body bag, the knocks under the dock. NUI sound,
--    panned and faded by distance.
--  * Stuck nudge (Config.StuckNudge): any clue that has stayed open for a while without being found rings
--    the bell in 3D from its spot whenever you come within range, so a player who is circling the right
--    area gets pulled the last few metres. Repeats on an interval until the clue is documented.

M8ClueCues = {}

local DEFAULT_INTERVAL = 8000
local DEFAULT_RANGE = 40.0
local DEFAULT_NEAR = 4.0
local DEFAULT_MIN_VOLUME = 0.15

-- pure: should the cue play now?
function M8ClueCues.Due(cue, lastAt, now, distance)
    if distance > (cue.range or DEFAULT_RANGE) then return false end
    if lastAt == nil then return true end
    return now - lastAt >= (cue.interval or DEFAULT_INTERVAL)
end

-- pure: NUI volume from distance - full inside `near`, the floor at the edge of `range`, linear between
function M8ClueCues.Volume(cue, distance)
    local range = cue.range or DEFAULT_RANGE
    local near = cue.near or DEFAULT_NEAR
    local floor = cue.minVolume or DEFAULT_MIN_VOLUME
    if distance <= near then return 1.0 end
    if distance >= range then return floor end
    local t = (distance - near) / (range - near)
    return 1.0 - t * (1.0 - floor)
end

-- pure: should the stuck nudge ring now? openSince = when the clue became examinable
function M8ClueCues.NudgeDue(nudge, openSince, lastAt, now, distance)
    if openSince == nil then return false end
    if now - openSince < (nudge.afterMs or 300000) then return false end
    if distance > (nudge.range or 25.0) then return false end
    if lastAt == nil then return true end
    return now - lastAt >= (nudge.interval or 45000)
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- stereo pan (-1..1) of a world point relative to the gameplay camera, like the Voss HELP calls
local function panTo(target)
    local me = GetEntityCoords(PlayerPedId())
    local dx, dy = target.x - me.x, target.y - me.y
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.001 then return 0.0 end
    dx, dy = dx / len, dy / len
    local yaw = math.rad(GetGameplayCamRot(2).z)
    local rightX, rightY = math.cos(yaw), math.sin(yaw)
    return clamp(dx * rightX + dy * rightY, -1.0, 1.0)
end

local function playNui(sound, coords, falloff, distance)
    SendNUIMessage({
        action = 'sound',
        name = sound,
        volume = M8ClueCues.Volume(falloff, distance),
        pan = panTo(coords),
        rate = 1.0,
        nativeBypass = true
    })
end

-- 3D first (Sandy Halloween bank through the native layer), NUI panned sound otherwise
local function playAt(sound, coords, falloff, distance)
    if M8NativeAudio and M8NativeAudio.Play and M8NativeAudio.Play(sound, { at = coords }) then return end
    playNui(sound, coords, falloff, distance)
end

-- one console line per cue whenever its state changes (daytime / no progress / locked / found / out of
-- range / in range), plus one per ring - cheap, and it shows in the F8 console and CitizenFX log
local lastState = {}
local function report(evidenceId, state)
    if lastState[evidenceId] == state then return end
    lastState[evidenceId] = state
    print(('[Murder of 8] clue cue %s: %s'):format(evidenceId, state))
end

CreateThread(function()
    Wait(1500)

    local lastAt = {}     -- clue cue: last play per evidence id
    local openSince = {}  -- stuck nudge: when each clue became examinable
    local nudgedAt = {}   -- stuck nudge: last ring per evidence id

    while true do
        local cues = Config.ClueCues or {}
        local nudge = Config.StuckNudge
        if nudge and nudge.enabled == false then nudge = nil end

        local me = GetEntityCoords(PlayerPedId())
        local now = GetGameTimer()
        local ready = M8_HasProgress and M8_HasProgress()
        local night = M8_IsHuntTime and M8_IsHuntTime()
        local found = ready and ((M8_GetProgress() or {}).evidence or {}) or {}

        for sceneId, scene in pairs(Config.Scenes or {}) do
            if scene.enabled and scene.evidence then
                for evidenceId, sceneCoords in pairs(scene.evidence) do
                    local cue = cues[evidenceId]
                    local open = false

                    if not ready then
                        if cue then report(evidenceId, 'waiting for progress from the server') end
                    elseif not night then
                        if cue then report(evidenceId, 'daytime, investigation closed') end
                    elseif found[evidenceId] then
                        if cue then report(evidenceId, 'found, cue off') end
                    elseif not M8_IsSceneAccessible(sceneId) or not M8_CanUseEvidence(sceneId, evidenceId) then
                        if cue then report(evidenceId, 'locked (chapter or prerequisites)') end
                    else
                        open = true
                    end

                    if not open then
                        openSince[evidenceId] = nil
                    else
                        openSince[evidenceId] = openSince[evidenceId] or now

                        local coords = M8_GetEvidenceWorldCoords
                            and M8_GetEvidenceWorldCoords(evidenceId, sceneCoords)
                            or sceneCoords
                        local distance = #(me - coords)

                        if cue then
                            if distance > (cue.range or DEFAULT_RANGE) then
                                report(evidenceId, 'open, out of range')
                            else
                                report(evidenceId, 'open, in range - ringing')
                                if M8ClueCues.Due(cue, lastAt[evidenceId], now, distance) then
                                    lastAt[evidenceId] = now
                                    print(('[Murder of 8] clue cue %s: %s at %.1f m'):format(evidenceId, cue.sound, distance))
                                    playNui(cue.sound, coords, cue, distance)
                                end
                            end
                        end

                        if nudge and M8ClueCues.NudgeDue(nudge, openSince[evidenceId], nudgedAt[evidenceId], now, distance) then
                            nudgedAt[evidenceId] = now
                            print(('[Murder of 8] stuck nudge %s: %s at %.1f m, open for %d s'):format(
                                evidenceId, nudge.sound or 'bell', distance, (now - openSince[evidenceId]) // 1000))
                            playAt(nudge.sound or 'bell', coords, nudge, distance)
                        end
                    end
                end
            end
        end

        Wait(500)
    end
end)
