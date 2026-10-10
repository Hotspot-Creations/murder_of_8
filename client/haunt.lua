-- Murder of 8 - v1.4 Advanced Scare Director
--
-- This is intentionally stateful. The goal is not "random BOO every minute".
-- It builds tension, avoids repetitions, reacts to player context, uses fake-outs,
-- and mixes visible Bellman events with audio-only events.

local wasHuntTime = nil
local nextDayScareAt = 0
local nextMicroAt = 0
local nextMajorEligibleAt = 0

local activeScare = nil
local activeFigure = nil
local activeBody = nil
local delayedAmbushAt = 0
local delayedAmbushType = nil

local tension = 12.0
local triggerThreshold = 68.0
local lastScareAt = 0
local lastScares = {}
local runtimeEnabled = true
local dawnWarningShown = false

local guaranteedNightScares = {
    burned_photo = 'watcher',
    nova_bible = 'turn',
    venn_body = 'watcher',
    cell_eight = 'false',
    transfer_records = 'peripheral',
    false_identities = 'face',
    nova_body_bag = 'false',
    eight_suitcases = 'rush',
    weighted_cache = 'body',
    university_file = 'blink',
    archive_wall = 'watcher',
    nova_last_recording = 'turn',
    surveillance_wall = 'blink',
    nova_body = 'false'
}

local function randomDelay(minMs, maxMs)
    minMs = tonumber(minMs) or 60000
    maxMs = tonumber(maxMs) or minMs
    if maxMs < minMs then maxMs = minMs end
    return math.random(minMs, maxMs)
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function cfg()
    Config.ScareDirector = Config.ScareDirector or {}
    return Config.ScareDirector
end

local function currentNightPhase()
    local hour = GetClockHours()
    if hour == 21 or hour == 22 then return 'early' end
    if hour == 23 or hour == 0 then return 'late' end
    if hour == 1 or hour == 2 then return 'peak' end
    return 'predawn'
end

local function investigationStarted()
    local progress = M8_GetProgress and M8_GetProgress() or nil
    if not progress or not progress.evidence then return false end
    return next(progress.evidence) ~= nil
end

local function investigationComplete()
    local progress = M8_GetProgress and M8_GetProgress() or nil
    return progress and progress.completed and progress.completed[8] == true
end

local function currentChapter()
    local progress = M8_GetProgress and M8_GetProgress() or nil
    return tonumber(progress and progress.chapter) or 1
end

-- prompt_sandy_halloween asks this once a second: while this director is live for the player, its
-- own ambient director steps back (its prop sounds, knocks, Loch Ness and bell carry on).
exports('IsInvestigating', function()
    return runtimeEnabled
        and cfg().enabled ~= false
        and not investigationComplete()
        and M8_IsActivelyInvestigating()
end)

-- within sceneRadius of any evidence point of an open (unlocked, hunt-time) scene
local function nearOpenScene(coords)
    local D = cfg()
    if D.onlyNearScenes == false then return true end
    local r = D.sceneRadius or 60.0
    for sceneId, scene in pairs(Config.Scenes or {}) do
        if scene.enabled and M8_IsSceneAccessible(sceneId) then
            for evidenceId, sceneCoords in pairs(scene.evidence or {}) do
                local c = M8_GetEvidenceWorldCoords
                    and M8_GetEvidenceWorldCoords(evidenceId, sceneCoords)
                    or sceneCoords

                if c and (c.x ~= 0.0 or c.y ~= 0.0) and #(coords - c) <= r then
                    return true
                end
            end
        end
    end
    return false
end

local function canBaseHaunt(ignoreTime)
    if not runtimeEnabled then return false end

    local D = cfg()
    if D.enabled == false then return false end
    if investigationComplete() then return false end

    if D.onlyAfterInvestigationStarts ~= false and not M8_IsActivelyInvestigating() then
        return false
    end

    if not M8_IsInSandy() then
        return false
    end

    if not ignoreTime and not M8_IsHuntTime() then
        return false
    end

    local ped = PlayerPedId()
    if not DoesEntityExist(ped) or IsEntityDead(ped) then return false end

    -- Automatic scares live around the clues. This remains true even for
    -- time-ignoring authored/transition calls so unrelated Sandy RP is untouched.
    if not nearOpenScene(GetEntityCoords(ped)) then return false end
    if IsPauseMenuActive() then return false end
    if M8_IsCasebookOpen and M8_IsCasebookOpen() then return false end

    return true
end

local function playerContext()
    local ped = PlayerPedId()
    local speed = GetEntitySpeed(ped)
    local inVehicle = IsPedInAnyVehicle(ped, false)
    local interior = GetInteriorFromEntity(ped)

    return {
        ped = ped,
        coords = GetEntityCoords(ped),
        heading = GetEntityHeading(ped),
        speed = speed,
        inVehicle = inVehicle,
        interior = interior ~= 0,
        aiming = IsPlayerFreeAiming(PlayerId())
    }
end

-- entity: the figure the sound belongs to, so a positional layer plays it from there
local function sendSound(name, pan, volume, rate, entity)
    if M8NativeAudio and M8NativeAudio.Play then
        local nativePlayed = M8NativeAudio.Play(name, {
            pan = pan,
            volume = volume,
            rate = rate,
            entity = entity
        })

        if nativePlayed then
            return
        end
    end

    -- Abstract sounds and old-build fallbacks still use the NUI layer.
    SendNUIMessage({
        action = 'sound',
        name = name,
        pan = pan,
        volume = volume,
        rate = rate,
        nativeBypass = true
    })
end

local function randomPan(minAbs)
    minAbs = minAbs or 0.42
    local dir = math.random(0, 1) == 0 and -1 or 1
    return dir * (minAbs + math.random() * (0.96 - minAbs))
end

local function effect(mode, duration, intensity)
    SendNUIMessage({
        action = 'directorEffect',
        mode = mode,
        duration = duration or 350,
        intensity = intensity or 1.0
    })
end

local function hauntMessage(text, duration)
    SendNUIMessage({
        action = 'hauntMessage',
        text = text,
        duration = duration or 1700
    })
end

local function randomMessage()
    local messages = cfg().messages or {}
    if #messages < 1 then return end
    hauntMessage(messages[math.random(1, #messages)], math.random(1200, 2100))
end

local function rotationToDirection(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

local function cameraHorizontalVectors()
    local dir = rotationToDirection(GetGameplayCamRot(2))
    dir = vector3(dir.x, dir.y, 0.0)

    local mag = math.sqrt((dir.x * dir.x) + (dir.y * dir.y))
    if mag < 0.01 then
        local f = GetEntityForwardVector(PlayerPedId())
        dir = vector3(f.x, f.y, 0.0)
        mag = math.sqrt((dir.x * dir.x) + (dir.y * dir.y))
    end

    dir = vector3(dir.x / mag, dir.y / mag, 0.0)
    local right = vector3(-dir.y, dir.x, 0.0)
    return dir, right
end

local function cameraRelativePoint(forwardDistance, sideDistance, zOffset)
    local p = GetEntityCoords(PlayerPedId())
    local forward, right = cameraHorizontalVectors()
    return p
        + (forward * (forwardDistance or 0.0))
        + (right * (sideDistance or 0.0))
        + vector3(0.0, 0.0, zOffset or 0.0)
end

local function entityScreenData(entity, zOffset)
    if not entity or not DoesEntityExist(entity) then
        return false, 0.5, 0.5
    end

    local c = GetEntityCoords(entity)
    return World3dToScreen2d(c.x, c.y, c.z + (zOffset or 0.65))
end

local function headingDiff(a, b)
    local diff = math.abs((a - b) % 360.0)
    if diff > 180.0 then diff = 360.0 - diff end
    return diff
end

local function loadModel(modelName)
    if not modelName then return nil end
    local hash = joaat(modelName)

    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return nil
    end

    RequestModel(hash)

    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        Wait(15)
        if GetGameTimer() >= timeout then
            return nil
        end
    end

    return hash
end

local function deleteEntitySafe(entity)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

local function cleanupFigure()
    if activeFigure and DoesEntityExist(activeFigure)
        and M8NativeAudio and M8NativeAudio.Play
    then
        M8NativeAudio.Play('slasher_despawn', { entity = activeFigure })
    end

    deleteEntitySafe(activeFigure)
    activeFigure = nil
end

local function cleanupBody()
    deleteEntitySafe(activeBody)
    activeBody = nil
end

local function cleanupScareEntities()
    cleanupFigure()
    cleanupBody()
end

local function facePlayer(entity)
    if not entity or not DoesEntityExist(entity) then return end

    local p = GetEntityCoords(PlayerPedId())
    local e = GetEntityCoords(entity)

    SetEntityHeading(
        entity,
        GetHeadingFromVector_2d(p.x - e.x, p.y - e.y)
    )
end

local function spawnFigureAt(pos, alpha, freeze, collision)
    cleanupFigure()

    local model = cfg().figureModel
        or ((Config.Haunting and Config.Haunting.night and Config.Haunting.night.figureModel) or 'a_m_m_skidrow_01')

    local hash = loadModel(model)
    if not hash then return nil end

    activeFigure = CreatePed(
        4,
        hash,
        pos.x,
        pos.y,
        pos.z,
        0.0,
        false,
        false
    )

    if DoesEntityExist(activeFigure) then
        SetEntityInvincible(activeFigure, true)
        SetBlockingOfNonTemporaryEvents(activeFigure, true)
        SetPedCanRagdoll(activeFigure, false)
        SetEntityCollision(activeFigure, collision == true, collision == true)
        FreezeEntityPosition(activeFigure, freeze ~= false)
        SetEntityAlpha(activeFigure, alpha or cfg().figureAlpha or 235, false)
        SetPedRelationshipGroupHash(activeFigure, joaat('PLAYER'))
        facePlayer(activeFigure)
    end

    SetModelAsNoLongerNeeded(hash)
    return activeFigure
end

local function getGroundPoint(pos)
    local handle = StartShapeTestRay(
        pos.x,
        pos.y,
        pos.z + 4.0,
        pos.x,
        pos.y,
        pos.z - 6.0,
        1 + 16,
        PlayerPedId(),
        0
    )

    local _, hit, endCoords = GetShapeTestResult(handle)

    if hit == 1 then
        return vector3(endCoords.x, endCoords.y, endCoords.z)
    end

    return vector3(pos.x, pos.y, GetEntityCoords(PlayerPedId()).z)
end

local function canUseScare(name, ignoreCooldown)
    if ignoreCooldown then return true end

    local now = GetGameTimer()
    local D = cfg()

    if now - lastScareAt < (D.globalRecoveryMs or 26000) then
        return false
    end

    local last = lastScares[name]
    local cooldowns = D.cooldowns or {}
    local cooldown = cooldowns[name] or D.repeatCooldownMs or 180000

    return not last or (now - last) >= cooldown
end

local function markScare(name)
    local now = GetGameTimer()
    lastScares[name] = now
    lastScareAt = now
end

local function setScare(name)
    if activeScare then return false end
    activeScare = name
    markScare(name)
    return true
end

local function endScare()
    activeScare = nil
end

local function microBlink(ms)
    effect('blink', ms or 100, 1.0)
end

local function scareFace(force)
    if not canBaseHaunt(force) then return end
    if not canUseScare('face', force) then return end
    if activeScare then return end

    local ctx = playerContext()
    if ctx.inVehicle and not force then return end
    if ctx.speed > (cfg().maxWalkScareSpeed or 6.5) and not force then return end

    if not setScare('face') then return end

    CreateThread(function()
        effect('blink', 115, 1.0)
        Wait(85)

        local pos = cameraRelativePoint(1.05, (math.random() - 0.5) * 0.18, -0.05)
        local figure = spawnFigureAt(pos, 255, true, false)

        if figure then
            facePlayer(figure)

            if M8NativeAudio and M8NativeAudio.Play then
                M8NativeAudio.Play('slasher_spawn', { entity = figure })
                M8NativeAudio.Play('slasher_loop', { entity = figure, duration = 650 })
            end
        end

        sendSound('jump_sting', 0.0, 1.0, 1.0, figure)
        SetTimeout(45, function()
            sendSound('impact', 0.0, 0.75, 0.96)
        end)

        effect('glitch', 360, 1.0)
        ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.70)

        Wait(math.random(290, 430))

        cleanupFigure()
        effect('blink', 90, 1.0)
        StopGameplayCamShaking(true)
        endScare()
    end)
end

local function scareTurn(force)
    if not canBaseHaunt(force) then return end
    if not canUseScare('turn', force) then return end
    if activeScare then return end

    local ctx = playerContext()
    if ctx.inVehicle and not force then return end
    if not setScare('turn') then return end

    CreateThread(function()
        local startYaw = GetGameplayCamRot(2).z
        local pan = randomPan(0.68)

        -- the figure exists first so its whisper and footsteps come from where it stands
        local behind = cameraRelativePoint(-1.45, pan > 0 and -0.25 or 0.25, -0.08)
        local figure = spawnFigureAt(behind, 245, true, false)

        sendSound('whisper', pan, 0.62, 0.90, figure)
        Wait(650)
        sendSound('footsteps', -pan, 0.68, 0.94, figure)

        local expires = GetGameTimer() + 11500
        local hit = false

        while figure and DoesEntityExist(figure) and GetGameTimer() < expires do
            local yaw = GetGameplayCamRot(2).z
            local turned = headingDiff(startYaw, yaw)
            local onScreen, sx = entityScreenData(figure, 0.72)

            if onScreen and sx > 0.22 and sx < 0.78 then
                hit = true
                break
            end

            if turned > 95.0 then
                Wait(90)
            end

            Wait(0)
        end

        if hit then
            sendSound('jump_sting', 0.0, 0.95, 1.0, figure)
            effect('glitch', 330, 0.9)
            ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.58)
            Wait(350)
            StopGameplayCamShaking(true)
        else
            -- The player refused to turn. Reward that with a delayed ambush.
            delayedAmbushAt = GetGameTimer() + math.random(4500, 9500)
            delayedAmbushType = 'face'
        end

        cleanupFigure()
        endScare()
    end)
end

local function scareWatcher(force)
    if not canBaseHaunt(force) then return end
    if not canUseScare('watcher', force) then return end
    if activeScare then return end

    local ctx = playerContext()
    if ctx.inVehicle and not force then return end

    if not setScare('watcher') then return end

    CreateThread(function()
        local D = cfg()
        local distance = math.random(
            math.floor(D.watcherMinDistance or 10),
            math.floor(D.watcherMaxDistance or 16)
        )

        local side = (math.random(0, 1) == 0 and -1 or 1) * math.random(3, 7)
        local raw = cameraRelativePoint(distance, side, 0.0)
        local pos = getGroundPoint(raw)

        local figure = spawnFigureAt(pos, 145, true, false)

        if not figure then
            endScare()
            return
        end

        sendSound('sub_rumble', 0.0, 0.32, 0.92)
        sendSound('bell', 0.0, 0.30, 0.90, figure) -- the Bellman's bell, from where he stands

        local expires = GetGameTimer() + math.random(4500, 7200)
        local lookedAt = 0

        while activeFigure == figure and DoesEntityExist(figure) and GetGameTimer() < expires do
            facePlayer(figure)

            local onScreen, sx, sy = entityScreenData(figure, 0.72)

            if onScreen and sx > 0.35 and sx < 0.65 and sy > 0.20 and sy < 0.82 then
                if lookedAt == 0 then lookedAt = GetGameTimer() end

                if GetGameTimer() - lookedAt > 520 then
                    sendSound('reverse_sting', 0.0, 0.46, 1.0, figure)
                    effect('static', 210, 0.55)
                    break
                end
            else
                lookedAt = 0
            end

            Wait(50)
        end

        cleanupFigure()
        endScare()
    end)
end

local function scarePeripheral(force)
    if not canBaseHaunt(force) then return end
    if not canUseScare('peripheral', force) then return end
    if activeScare then return end

    local ctx = playerContext()
    if ctx.inVehicle and not force then return end
    if not setScare('peripheral') then return end

    CreateThread(function()
        local sideDir = math.random(0, 1) == 0 and -1 or 1
        local raw = cameraRelativePoint(4.5, sideDir * 7.5, 0.0)
        local pos = getGroundPoint(raw)
        local figure = spawnFigureAt(pos, 118, true, false)

        if not figure then
            endScare()
            return
        end

        sendSound('chain_drag', sideDir * 0.85, 0.42, 0.93, figure)

        local expires = GetGameTimer() + 5500
        local centeredAt = 0

        while activeFigure == figure and DoesEntityExist(figure) and GetGameTimer() < expires do
            facePlayer(figure)

            local onScreen, sx, sy = entityScreenData(figure, 0.7)

            if onScreen and sx > 0.26 and sx < 0.74 and sy > 0.16 and sy < 0.86 then
                if centeredAt == 0 then centeredAt = GetGameTimer() end

                if GetGameTimer() - centeredAt > 180 then
                    effect('blink', 90, 0.8)
                    sendSound('reverse_sting', -sideDir * 0.4, 0.48, 1.02, figure)
                    break
                end
            else
                centeredAt = 0
            end

            Wait(40)
        end

        cleanupFigure()
        endScare()
    end)
end

local function scareBlink(force)
    if not canBaseHaunt(force) then return end
    if not canUseScare('blink', force) then return end
    if activeScare then return end

    local ctx = playerContext()
    if ctx.inVehicle and not force then return end
    if not setScare('blink') then return end

    CreateThread(function()
        sendSound('sub_rumble', 0.0, 0.36, 0.88)

        local stages = {
            { dist = 7.5, side = 1.2, alpha = 145, wait = 1150 },
            { dist = 4.1, side = -0.55, alpha = 190, wait = 900 },
            { dist = 2.1, side = 0.18, alpha = 225, wait = 620 }
        }

        for i, stage in ipairs(stages) do
            local raw = cameraRelativePoint(stage.dist, stage.side, 0.0)
            local pos = getGroundPoint(raw)

            effect('blink', 95, 1.0)
            Wait(75)

            local figure = spawnFigureAt(pos, stage.alpha, true, false)
            if figure then facePlayer(figure) end

            if i == 1 then
                sendSound('door_creak', randomPan(0.5), 0.35, 0.92, figure)
            elseif i == 2 then
                sendSound('breath', randomPan(0.7), 0.55, 0.88, figure)
            end

            Wait(stage.wait)
            cleanupFigure()
        end

        effect('blink', 105, 1.0)
        Wait(70)

        local finalPos = cameraRelativePoint(1.02, 0.0, -0.05)
        local finalFigure = spawnFigureAt(finalPos, 255, true, false)
        if finalFigure then facePlayer(finalFigure) end

        sendSound('jump_sting', 0.0, 1.0, 1.0, finalFigure)
        sendSound('impact', 0.0, 0.70, 0.94)
        effect('glitch', 420, 1.0)
        ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.76)

        Wait(360)
        cleanupFigure()
        StopGameplayCamShaking(true)
        endScare()
    end)
end

local function scareRush(force)
    if not canBaseHaunt(force) then return end
    if not canUseScare('rush', force) then return end
    if activeScare then return end

    local ctx = playerContext()
    if ctx.inVehicle and not force then return end
    if ctx.speed > (cfg().maxWalkScareSpeed or 6.5) and not force then return end
    if not setScare('rush') then return end

    CreateThread(function()
        local sideDir = math.random(0, 1) == 0 and -1 or 1
        local raw = cameraRelativePoint(-(cfg().rushDistance or 12.0), sideDir * 2.5, 0.0)
        local pos = getGroundPoint(raw)

        -- collision on: a moving ped without it has nothing to stand on and falls through the map
        local figure = spawnFigureAt(pos, 240, false, true)

        sendSound('footsteps_run', sideDir * 0.82, 0.90, 1.04, figure) -- the steps run with it
        sendSound('sub_rumble', 0.0, 0.30, 1.0)

        if not figure then
            endScare()
            return
        end

        SetPedMoveRateOverride(figure, 1.35)
        SetPedCanRagdoll(figure, false)

        local expires = GetGameTimer() + 6500
        local hit = false

        while activeFigure == figure and DoesEntityExist(figure) and GetGameTimer() < expires do
            local p = GetEntityCoords(PlayerPedId())
            local f = GetEntityCoords(figure)
            local distance = #(p - f)

            if distance < 1.55 then
                hit = true
                break
            end

            TaskGoStraightToCoord(
                figure,
                p.x,
                p.y,
                p.z,
                5.8,
                700,
                GetEntityHeading(figure),
                0.0
            )

            Wait(180)
        end

        if hit then
            effect('blink', 130, 1.0)
            sendSound('jump_sting', 0.0, 1.0, 1.04, figure)
            sendSound('impact', 0.0, 0.85, 0.94)
            ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.80)
            Wait(220)
            StopGameplayCamShaking(true)
        else
            sendSound('reverse_sting', sideDir * 0.45, 0.38, 0.90, figure)
        end

        cleanupFigure()
        endScare()
    end)
end

local function scareBodyDrop(force)
    if not canBaseHaunt(force) then return end
    if not canUseScare('body', force) then return end
    if activeScare then return end

    local ctx = playerContext()
    if ctx.inVehicle and not force then return end
    if ctx.speed > (cfg().bodyDropMaxSpeed or 1.8) and not force then return end
    if not setScare('body') then return end

    CreateThread(function()
        cleanupBody()

        local raw = cameraRelativePoint(2.25, (math.random() - 0.5) * 0.8, 0.0)
        local ground = getGroundPoint(raw)

        local model = cfg().bodyModel or 'a_m_m_skidrow_01'
        local hash = loadModel(model)

        if not hash then
            sendSound('body_drop', 0.0, 0.95, 1.0)
            effect('glitch', 300, 0.8)
            endScare()
            return
        end

        activeBody = CreatePed(
            4,
            hash,
            ground.x,
            ground.y,
            ground.z + 3.0,
            math.random() * 360.0,
            false,
            false
        )

        SetModelAsNoLongerNeeded(hash)

        if DoesEntityExist(activeBody) then
            SetEntityInvincible(activeBody, true)
            SetBlockingOfNonTemporaryEvents(activeBody, true)
            SetEntityCollision(activeBody, true, true)
            SetPedToRagdoll(activeBody, 7000, 7000, 0, false, false, false)
            SetEntityVelocity(activeBody, 0.0, 0.0, -3.5)
        end

        sendSound('reverse_sting', randomPan(0.4), 0.36, 0.86)
        Wait(520)
        sendSound('body_drop', 0.0, 1.0, 0.95, activeBody) -- the thud from the body itself
        effect('pulse', 320, 0.75)
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.56)

        Wait(850)
        StopGameplayCamShaking(true)

        -- Leave it just long enough for the player to process what happened.
        SetTimeout(8500, function()
            cleanupBody()
        end)

        endScare()
    end)
end

local function scareFalseBuild(force)
    if not canBaseHaunt(force) then return end
    if not canUseScare('false', force) then return end
    if activeScare then return end
    if not setScare('false') then return end

    CreateThread(function()
        local pan = randomPan(0.65)

        sendSound('footsteps', pan, 0.55, 0.86)
        Wait(900)

        sendSound('breath', -pan, 0.48, 0.84)
        Wait(700)

        sendSound('heartbeat', 0.0, 0.52, 0.92)
        sendSound('sub_rumble', 0.0, 0.26, 0.82)

        if math.random(1, 2) == 1 then
            randomMessage()
        end

        Wait(math.random(1900, 3300))

        -- Hard cut. Nothing happens.
        effect('blink', 65, 0.35)

        delayedAmbushAt = GetGameTimer() + math.random(8500, 19000)
        delayedAmbushType = ({ 'face', 'turn', 'peripheral' })[math.random(1, 3)]

        endScare()
    end)
end

local function scareRoadside(force)
    if not canBaseHaunt(force) then return end
    if not canUseScare('roadside', force) then return end
    if activeScare then return end

    local ctx = playerContext()
    if not ctx.inVehicle and not force then return end
    if not setScare('roadside') then return end

    CreateThread(function()
        local sideDir = math.random(0, 1) == 0 and -1 or 1
        local raw = cameraRelativePoint(15.0, sideDir * 5.5, 0.0)
        local pos = getGroundPoint(raw)

        local figure = spawnFigureAt(pos, 155, true, false)

        if not figure then
            sendSound('distant_scream', sideDir * 0.82, 0.32, 0.88)
            endScare()
            return
        end

        sendSound('bell', sideDir * 0.55, 0.36, 0.90, figure)

        local expires = GetGameTimer() + 5000

        while activeFigure == figure and DoesEntityExist(figure) and GetGameTimer() < expires do
            local p = GetEntityCoords(PlayerPedId())
            local f = GetEntityCoords(figure)

            if #(p - f) < 8.0 then
                effect('static', 240, 0.65)
                sendSound('reverse_sting', sideDir * 0.65, 0.44, 1.05, figure)
                break
            end

            Wait(80)
        end

        cleanupFigure()
        endScare()
    end)
end

local function scareImpact(force)
    if not canBaseHaunt(force) then return end
    if activeScare then return end

    if not setScare('impact') then return end

    SendNUIMessage({ action = 'jumpscare', variant = 'impact', duration = 430 })
    sendSound('impact', 0.0, 0.95, 0.96)
    effect('glitch', 300, 0.8)
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.52)

    SetTimeout(520, function()
        StopGameplayCamShaking(true)
        endScare()
    end)
end

local function runNamedScare(name, force)
    if name == 'face' then
        scareFace(force)
    elseif name == 'turn' then
        scareTurn(force)
    elseif name == 'rush' then
        scareRush(force)
    elseif name == 'blink' then
        scareBlink(force)
    elseif name == 'watcher' then
        scareWatcher(force)
    elseif name == 'peripheral' then
        scarePeripheral(force)
    elseif name == 'false' then
        scareFalseBuild(force)
    elseif name == 'body' then
        scareBodyDrop(force)
    elseif name == 'roadside' then
        scareRoadside(force)
    elseif name == 'impact' then
        scareImpact(force)
    end
end

local function weightedChoice(entries)
    local total = 0
    for _, entry in ipairs(entries) do
        total = total + entry[2]
    end

    if total <= 0 then return nil end

    local roll = math.random() * total
    local sum = 0

    for _, entry in ipairs(entries) do
        sum = sum + entry[2]
        if roll <= sum then
            return entry[1]
        end
    end

    return entries[#entries][1]
end

local function chooseMajorScare()
    local ctx = playerContext()
    local phase = currentNightPhase()
    local pool = {}

    if ctx.inVehicle then
        pool = {
            { 'roadside', 6 },
            { 'false', 2 },
            { 'impact', 2 }
        }
    elseif phase == 'early' then
        pool = {
            { 'watcher', 6 },
            { 'peripheral', 5 },
            { 'turn', 3 },
            { 'false', 5 },
            { 'face', 1 }
        }
    elseif phase == 'late' then
        pool = {
            { 'watcher', 3 },
            { 'peripheral', 4 },
            { 'turn', 5 },
            { 'false', 4 },
            { 'face', 3 },
            { 'rush', 2 },
            { 'body', ctx.interior and 3 or 1 }
        }
    elseif phase == 'peak' then
        pool = {
            { 'turn', 5 },
            { 'face', 5 },
            { 'rush', 5 },
            { 'blink', 4 },
            { 'body', ctx.interior and 4 or 2 },
            { 'false', 3 },
            { 'peripheral', 2 }
        }
    else
        pool = {
            { 'turn', 4 },
            { 'false', 6 },
            { 'watcher', 3 },
            { 'peripheral', 4 },
            { 'blink', 2 },
            { 'rush', 2 },
            { 'face', 2 }
        }
    end

    -- Try several weighted picks until we find one off cooldown.
    for _ = 1, 8 do
        local name = weightedChoice(pool)
        if name and canUseScare(name, false) then
            if name ~= 'body' or ctx.speed <= (cfg().bodyDropMaxSpeed or 1.8) then
                return name
            end
        end
    end

    return nil
end

local function runMicroHaunt()
    if not canBaseHaunt(false) or activeScare then return end

    local ctx = playerContext()
    local phase = currentNightPhase()
    local choices

    if ctx.inVehicle then
        choices = { 'bell', 'static', 'scream', 'whisper' }
    elseif phase == 'early' then
        choices = { 'footsteps', 'whisper', 'chain', 'bell', 'message' }
    elseif phase == 'peak' then
        choices = { 'footsteps_run', 'breath', 'chain', 'static', 'scream', 'message' }
    else
        choices = { 'footsteps', 'breath', 'whisper', 'bell', 'chain', 'message' }
    end

    local event = choices[math.random(1, #choices)]

    if event == 'footsteps' then
        sendSound('footsteps', randomPan(0.7), 0.48, 0.88 + math.random() * 0.12)
    elseif event == 'footsteps_run' then
        sendSound('footsteps_run', randomPan(0.7), 0.60, 0.95 + math.random() * 0.10)
    elseif event == 'breath' then
        sendSound('breath', randomPan(0.78), 0.44, 0.82 + math.random() * 0.12)
    elseif event == 'whisper' then
        sendSound('whisper', randomPan(0.75), 0.50, 0.84 + math.random() * 0.16)
    elseif event == 'bell' then
        sendSound('bell', randomPan(0.35), 0.28, 0.88)
    elseif event == 'chain' then
        sendSound('chain_drag', randomPan(0.62), 0.34, 0.88)
    elseif event == 'scream' then
        sendSound('distant_scream', randomPan(0.75), 0.24, 0.82)
    elseif event == 'message' then
        if canUseScare('message', false) then
            markScare('message')
            randomMessage()
        else
            sendSound('whisper', randomPan(0.75), 0.42, 0.90)
        end
    else
        sendSound('static', 0.0, 0.38, 1.0)
        effect('static', 170, 0.35)
    end

    tension = clamp(tension + math.random(3, 8), 0, 100)
end

local function runDayScare(forceType)
    if not canBaseHaunt(true) then return end
    if M8_IsHuntTime() then return end

    local eventType = forceType or ({ 'watcher', 'whisper', 'bell', 'message' })[math.random(1, 4)]

    if eventType == 'watcher' then
        -- Day watcher is distant and never lunges.
        local old = cfg().watcherMinDistance
        cfg().watcherMinDistance = 15
        scareWatcher(true)
        cfg().watcherMinDistance = old
    elseif eventType == 'message' then
        randomMessage()
    elseif eventType == 'bell' then
        sendSound('bell', randomPan(0.35), 0.20, 0.82)
    else
        sendSound('whisper', randomPan(0.8), 0.28, 0.82)
    end
end

local function updateTension()
    if not canBaseHaunt(false) then
        tension = clamp(tension - 0.30, 0, 100)
        return
    end

    local D = cfg()
    local T = D.tension or {}
    local phase = currentNightPhase()
    local growth = T.earlyGrowth or 0.40

    if phase == 'late' then
        growth = T.lateGrowth or 0.62
    elseif phase == 'peak' then
        growth = T.peakGrowth or 0.92
    elseif phase == 'predawn' then
        growth = T.predawnGrowth or 0.70
    end

    local ctx = playerContext()

    if ctx.interior then
        growth = growth + (T.interiorBonus or 0.16)
    end

    if ctx.speed < 0.35 then
        growth = growth + (T.stationaryBonus or 0.14)
    end

    growth = growth + ((currentChapter() - 1) * (T.chapterBonus or 0.025))

    tension = clamp(tension + growth, 0, 100)
end

local function resetTriggerThreshold()
    local T = cfg().tension or {}
    triggerThreshold = math.random(
        math.floor(T.minTrigger or 54),
        math.floor(T.maxTrigger or 86)
    )
end

-- Evidence-triggered scares wait until the casebook closes instead of getting lost.
AddEventHandler('m8:client:evidenceFound', function(evidenceId)
    -- v1.6 authored chapter choreography takes priority over the generic
    -- evidence scare table. Ambient/random haunting still remains active.
    if M8ScriptedScares and M8ScriptedScares.HandlesEvidence
        and M8ScriptedScares.HandlesEvidence(evidenceId)
    then
        return
    end

    local scareType = guaranteedNightScares[evidenceId]
    if not scareType then return end

    CreateThread(function()
        Wait(math.random(1800, 3500))

        local expires = GetGameTimer() + 18000

        while GetGameTimer() < expires do
            if M8_IsHuntTime() and canBaseHaunt(false) and not activeScare then
                runNamedScare(scareType, true)
                return
            end

            Wait(350)
        end
    end)
end)

-- Director loop.
CreateThread(function()
    math.randomseed(GetGameTimer() + (PlayerId() * 7919) + 1408)

    resetTriggerThreshold()

    local D = cfg()
    local dayCfg = (Config.Haunting and Config.Haunting.day) or {}

    nextDayScareAt = GetGameTimer() + randomDelay(dayCfg.minDelayMs or 240000, dayCfg.maxDelayMs or 480000)
    nextMicroAt = GetGameTimer() + randomDelay(D.microMinDelayMs or 22000, D.microMaxDelayMs or 62000)
    nextMajorEligibleAt = GetGameTimer() + randomDelay(D.majorMinDelayMs or 50000, D.majorMaxDelayMs or 135000)

    while true do
        local now = GetGameTimer()
        local huntTime = M8_IsHuntTime()

        if wasHuntTime == nil then
            wasHuntTime = huntTime
        elseif wasHuntTime and not huntTime then
            -- No popup at 05:00. The warning is handled explicitly at 04:59.
            nextDayScareAt = now + randomDelay(dayCfg.minDelayMs or 240000, dayCfg.maxDelayMs or 480000)
        elseif not wasHuntTime and huntTime then
            tension = 18.0
            resetTriggerThreshold()
            nextMicroAt = now + randomDelay(D.microMinDelayMs or 22000, D.microMaxDelayMs or 62000)
            nextMajorEligibleAt = now + randomDelay(D.majorMinDelayMs or 50000, D.majorMaxDelayMs or 135000)
        end

        wasHuntTime = huntTime

        -- ONE-TIME DAWN WARNING:
        -- Only at 04:59, only for a player actively working the Murder of 8
        -- investigation, only in Sandy, and only while near an active clue.
        local clockHour = GetClockHours()
        local clockMinute = GetClockMinutes()
        local warningHour = (Config.Hunt and Config.Hunt.dawnWarningHour) or 4
        local warningMinute = (Config.Hunt and Config.Hunt.dawnWarningMinute) or 59

        if huntTime
            and not dawnWarningShown
            and clockHour == warningHour
            and clockMinute >= warningMinute
            and Config.Hunt
            and Config.Hunt.showDawnWarning
            and not investigationComplete()
            and M8_IsActivelyInvestigating()
            and M8_IsInSandy()
            and nearOpenScene(GetEntityCoords(PlayerPedId()))
        then
            dawnWarningShown = true

            M8_ShowWarning(
                'THE DAY IS APPROACHING',
                Config.Messages.dawnApproaching,
                Config.Hunt.warningDurationMs
            )

            sendSound('bell', 0.0, 0.32, 0.84)
        end

        -- Reset the latch during daylight so the next night's 04:59 can warn.
        if not huntTime and clockHour >= 5 and clockHour < 21 then
            dawnWarningShown = false
        end

        if huntTime then
            updateTension()

            if delayedAmbushAt > 0
                and now >= delayedAmbushAt
                and not activeScare
                and canBaseHaunt(false)
            then
                local ambush = delayedAmbushType or 'face'
                delayedAmbushAt = 0
                delayedAmbushType = nil
                runNamedScare(ambush, true)
                tension = math.random(8, 20)
                resetTriggerThreshold()
            end

            if now >= nextMicroAt and canBaseHaunt(false) and not activeScare then
                runMicroHaunt()
                nextMicroAt = now + randomDelay(D.microMinDelayMs or 22000, D.microMaxDelayMs or 62000)
            end

            if now >= nextMajorEligibleAt
                and tension >= triggerThreshold
                and canBaseHaunt(false)
                and not activeScare
            then
                local scare = chooseMajorScare()

                if scare then
                    runNamedScare(scare, false)
                    tension = math.random(7, 24)
                    resetTriggerThreshold()
                    nextMajorEligibleAt = now + randomDelay(D.majorMinDelayMs or 50000, D.majorMaxDelayMs or 135000)
                end
            end
        else
            tension = clamp(tension - 0.22, 0, 100)

            if dayCfg.enabled
                and M8_IsActivelyInvestigating()
                and M8_IsInSandy()
                and nearOpenScene(GetEntityCoords(PlayerPedId()))
                and not investigationComplete()
                and now >= nextDayScareAt
            then
                runDayScare()
                nextDayScareAt = now + randomDelay(dayCfg.minDelayMs or 240000, dayCfg.maxDelayMs or 480000)
            end
        end

        Wait(1000)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    cleanupScareEntities()
    StopGameplayCamShaking(true)
end)
