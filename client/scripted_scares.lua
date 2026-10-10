-- Murder of 8 - v1.6 Scripted Chapter Jumpscares
--
-- Authored chapter scares that trigger from specific evidence. These are
-- deliberately separate from the random Scare Director so the story gets
-- memorable set pieces without turning every interaction into RNG.

M8ScriptedScares = M8ScriptedScares or {}

local active = false
local activeFigure = nil
local activeBody = nil
local sequenceToken = 0
local firedEvidence = {}
local runtimeEnabled = true

local function cfg()
    Config.ScriptedScares = Config.ScriptedScares or {}
    return Config.ScriptedScares
end

-- entity: the figure the sound belongs to; at: a world position (the cell, the coffin). A positional
-- layer (Sandy Halloween bank from the figure itself, or GTA native audio) takes literal sounds
-- first; otherwise the NUI OGG plays. Sound designer can replace the OGG assets without touching this.
local function sendSound(name, pan, volume, rate, entity, at)
    if M8NativeAudio and M8NativeAudio.Play
        and M8NativeAudio.Play(name, { pan = pan, volume = volume, rate = rate, entity = entity, at = at })
    then
        return
    end

    SendNUIMessage({
        action = 'sound',
        name = name,
        pan = pan,
        volume = volume,
        rate = rate,
        nativeBypass = true
    })
end

local function effect(mode, duration, intensity)
    SendNUIMessage({
        action = 'directorEffect',
        mode = mode,
        duration = duration or 300,
        intensity = intensity or 1.0
    })
end

local function message(text, duration)
    SendNUIMessage({
        action = 'hauntMessage',
        text = text,
        duration = duration or 1500
    })
end

local function randomPan(minAbs)
    minAbs = minAbs or 0.55
    local direction = math.random(0, 1) == 0 and -1 or 1
    return direction * (minAbs + math.random() * (0.95 - minAbs))
end

local function rotationToDirection(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

local function cameraVectors()
    local dir = rotationToDirection(GetGameplayCamRot(2))
    dir = vector3(dir.x, dir.y, 0.0)

    local magnitude = math.sqrt((dir.x * dir.x) + (dir.y * dir.y))
    if magnitude < 0.01 then
        local f = GetEntityForwardVector(PlayerPedId())
        dir = vector3(f.x, f.y, 0.0)
        magnitude = math.sqrt((dir.x * dir.x) + (dir.y * dir.y))
    end

    dir = vector3(dir.x / magnitude, dir.y / magnitude, 0.0)
    local right = vector3(-dir.y, dir.x, 0.0)
    return dir, right
end

local function relativePoint(forwardDistance, sideDistance, zOffset)
    local p = GetEntityCoords(PlayerPedId())
    local forward, right = cameraVectors()

    return p
        + (forward * (forwardDistance or 0.0))
        + (right * (sideDistance or 0.0))
        + vector3(0.0, 0.0, zOffset or 0.0)
end

local function headingDifference(a, b)
    local diff = math.abs((a - b) % 360.0)
    if diff > 180.0 then diff = 360.0 - diff end
    return diff
end

-- the ground under a point (so a moving figure starts on the floor, not in the air or inside it)
local function groundPoint(pos)
    local handle = StartShapeTestRay(pos.x, pos.y, pos.z + 4.0, pos.x, pos.y, pos.z - 6.0, 1 + 16, PlayerPedId(), 0)
    local _, hit, endCoords = GetShapeTestResult(handle)
    if hit == 1 then return vector3(endCoords.x, endCoords.y, endCoords.z) end
    return pos
end

local function entityOnScreen(entity, zOffset)
    if not entity or not DoesEntityExist(entity) then
        return false, 0.5, 0.5
    end

    local c = GetEntityCoords(entity)
    return World3dToScreen2d(c.x, c.y, c.z + (zOffset or 0.7))
end

local function deleteEntitySafe(entity)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

local function cleanupFigure()
    deleteEntitySafe(activeFigure)
    activeFigure = nil
end

local function cleanupBody()
    deleteEntitySafe(activeBody)
    activeBody = nil
end

local function cleanupAll()
    cleanupFigure()
    cleanupBody()
    StopGameplayCamShaking(true)
end

local function loadModel(modelName)
    local hash = joaat(modelName)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end

    RequestModel(hash)
    local timeout = GetGameTimer() + 5000

    while not HasModelLoaded(hash) do
        Wait(15)
        if GetGameTimer() >= timeout then return nil end
    end

    return hash
end

local function facePlayer(entity)
    if not entity or not DoesEntityExist(entity) then return end

    local p = GetEntityCoords(PlayerPedId())
    local e = GetEntityCoords(entity)
    SetEntityHeading(entity, GetHeadingFromVector_2d(p.x - e.x, p.y - e.y))
end

local function spawnFigure(pos, alpha, freeze, collision)
    cleanupFigure()

    local hash = loadModel(cfg().figureModel or 'a_m_m_skidrow_01')
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

    SetModelAsNoLongerNeeded(hash)

    if activeFigure and DoesEntityExist(activeFigure) then
        SetEntityInvincible(activeFigure, true)
        SetBlockingOfNonTemporaryEvents(activeFigure, true)
        SetPedCanRagdoll(activeFigure, false)
        SetEntityCollision(activeFigure, collision == true, collision == true)
        FreezeEntityPosition(activeFigure, freeze ~= false)
        SetEntityAlpha(activeFigure, alpha or 235, false)
        facePlayer(activeFigure)
    end

    return activeFigure
end

local function spawnBodyAbove(pos)
    cleanupBody()

    local hash = loadModel(cfg().bodyModel or 'a_m_m_skidrow_01')
    if not hash then return nil end

    activeBody = CreatePed(
        4,
        hash,
        pos.x,
        pos.y,
        pos.z + 2.8,
        math.random() * 360.0,
        false,
        false
    )

    SetModelAsNoLongerNeeded(hash)

    if activeBody and DoesEntityExist(activeBody) then
        SetEntityInvincible(activeBody, true)
        SetBlockingOfNonTemporaryEvents(activeBody, true)
        SetEntityCollision(activeBody, true, true)
        SetPedToRagdoll(activeBody, 6500, 6500, 0, false, false, false)
        SetEntityVelocity(activeBody, 0.0, 0.0, -3.3)
    end

    return activeBody
end

local function canRun(force)
    if not runtimeEnabled or cfg().enabled == false then return false end
    if active then return false end

    local ped = PlayerPedId()
    if not DoesEntityExist(ped) or IsEntityDead(ped) then return false end
    if IsPauseMenuActive() then return false end

    if not force then
        if not M8_IsHuntTime() then return false end
        if IsPedInAnyVehicle(ped, false) then return false end
        if GetEntitySpeed(ped) > (cfg().maxPlayerSpeed or 5.5) then return false end
    end

    return true
end

local function beginSequence(name, force)
    if not canRun(force) then return nil end

    active = true
    sequenceToken = sequenceToken + 1
    local token = sequenceToken
    return token
end

local function tokenAlive(token)
    return active and token == sequenceToken
end

local function finishSequence(token)
    if token ~= sequenceToken then return end
    active = false
end

local function waitForCasebookClose(token)
    local timeout = GetGameTimer() + (cfg().casebookCloseTimeoutMs or 18000)

    while tokenAlive(token) and M8_IsCasebookOpen and M8_IsCasebookOpen() do
        if GetGameTimer() >= timeout then return false end
        Wait(100)
    end

    return tokenAlive(token)
end

local function waitForMovement(token, distance, timeoutMs)
    local start = GetEntityCoords(PlayerPedId())
    local timeout = GetGameTimer() + (timeoutMs or cfg().sequenceTimeoutMs or 16000)

    while tokenAlive(token) and GetGameTimer() < timeout do
        local current = GetEntityCoords(PlayerPedId())
        if #(current - start) >= (distance or 0.8) then return true end
        Wait(50)
    end

    return false
end

local function waitForTurn(token, degrees, timeoutMs)
    local start = GetGameplayCamRot(2).z
    local timeout = GetGameTimer() + (timeoutMs or cfg().sequenceTimeoutMs or 16000)

    while tokenAlive(token) and GetGameTimer() < timeout do
        if headingDifference(start, GetGameplayCamRot(2).z) >= (degrees or 90.0) then
            return true
        end
        Wait(0)
    end

    return false
end

local function faceHit()
    local pos = relativePoint(cfg().faceDistance or 1.05, 0.0, -0.08)
    local figure = spawnFigure(pos, 255, true, false)
    if figure then facePlayer(figure) end

    sendSound('jump_sting', 0.0, 1.0, 1.0, figure)
    SetTimeout(45, function()
        sendSound('impact', 0.0, 0.78, 0.98)
    end)

    effect('glitch', 370, 1.0)
    ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.72)

    Wait(330)
    cleanupFigure()
    StopGameplayCamShaking(true)
end

local function peripheralPeek(token)
    local sideDir = math.random(0, 1) == 0 and -1 or 1
    local pos = relativePoint(4.4, sideDir * 6.4, 0.0)
    local figure = spawnFigure(pos, 135, true, false)
    if not figure then return end

    sendSound('whisper', sideDir * 0.85, 0.46, 0.90, figure)

    local timeout = GetGameTimer() + 5000
    while tokenAlive(token) and DoesEntityExist(figure) and GetGameTimer() < timeout do
        facePlayer(figure)
        local onScreen, sx, sy = entityOnScreen(figure, 0.72)

        if onScreen and sx > 0.27 and sx < 0.73 and sy > 0.16 and sy < 0.88 then
            effect('blink', 90, 0.75)
            sendSound('reverse_sting', -sideDir * 0.45, 0.52, 1.0, figure)
            break
        end

        Wait(40)
    end

    cleanupFigure()
end

local function turnHit(token, promptText)
    local pan = randomPan(0.72)

    if promptText then
        message(promptText, 1200)
    end

    -- the figure exists first so its breath and footsteps come from where it stands
    local behind = relativePoint(-(cfg().turnDistance or 1.35), pan > 0 and -0.28 or 0.28, -0.08)
    local figure = spawnFigure(behind, 245, true, false)

    sendSound('breath', pan, 0.46, 0.90, figure)
    Wait(650)
    sendSound('footsteps', -pan, 0.58, 0.95, figure)
    if not figure then return end

    local timeout = GetGameTimer() + 10500
    local hit = false

    while tokenAlive(token) and DoesEntityExist(figure) and GetGameTimer() < timeout do
        facePlayer(figure)
        local onScreen, sx, sy = entityOnScreen(figure, 0.72)

        if onScreen and sx > 0.22 and sx < 0.78 and sy > 0.12 and sy < 0.90 then
            hit = true
            break
        end

        Wait(0)
    end

    if hit then
        sendSound('jump_sting', 0.0, 0.96, 1.0, figure)
        effect('glitch', 310, 0.92)
        ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.58)
        Wait(310)
        StopGameplayCamShaking(true)
    else
        -- Refusing to turn gets punished later.
        cleanupFigure()
        Wait(math.random(2200, 4800))
        if tokenAlive(token) then faceHit() end
    end

    cleanupFigure()
end

local function aisleWatcher(token, distance)
    local side = (math.random() - 0.5) * 1.6
    local pos = relativePoint(distance or (cfg().watcherDistance or 8.5), side, 0.0)
    local figure = spawnFigure(pos, 155, true, false)
    if not figure then return end

    sendSound('sub_rumble', 0.0, 0.26, 0.90)
    sendSound('bell', 0.0, 0.30, 0.90, figure) -- the Bellman's bell, from where he stands

    local timeout = GetGameTimer() + 6500
    local centeredSince = 0

    while tokenAlive(token) and DoesEntityExist(figure) and GetGameTimer() < timeout do
        facePlayer(figure)
        local onScreen, sx, sy = entityOnScreen(figure, 0.72)

        if onScreen and sx > 0.36 and sx < 0.64 and sy > 0.18 and sy < 0.84 then
            if centeredSince == 0 then centeredSince = GetGameTimer() end

            if GetGameTimer() - centeredSince > 450 then
                effect('static', 200, 0.5)
                sendSound('reverse_sting', 0.0, 0.42, 0.94, figure)
                break
            end
        else
            centeredSince = 0
        end

        Wait(50)
    end

    cleanupFigure()
end

local function passAcrossView(token, running)
    local sideDir = math.random(0, 1) == 0 and -1 or 1
    local forwardDistance = cfg().passageDistance or 4.25
    local start = groundPoint(relativePoint(forwardDistance, sideDir * 4.2, -0.05))
    local finish = groundPoint(relativePoint(forwardDistance, -sideDir * 4.2, -0.05))

    -- collision on: a moving ped without it has nothing to stand on and falls through the map
    local figure = spawnFigure(start, 238, false, true)
    if not figure then return end

    sendSound(running and 'footsteps_run' or 'footsteps', sideDir * 0.84, running and 0.74 or 0.52, running and 1.06 or 0.92, figure)

    TaskGoStraightToCoord(
        figure,
        finish.x,
        finish.y,
        finish.z,
        running and 5.2 or 2.1,
        running and 2200 or 4200,
        GetEntityHeading(figure),
        0.0
    )

    local timeout = GetGameTimer() + (running and 2200 or 3900)
    while tokenAlive(token) and DoesEntityExist(figure) and GetGameTimer() < timeout do
        Wait(40)
    end

    cleanupFigure()
end

local function blinkApproach(token)
    local stages = {
        { 7.0, 1.1, 145, 750 },
        { 4.2, -0.55, 188, 620 },
        { 2.15, 0.20, 230, 470 }
    }

    sendSound('sub_rumble', 0.0, 0.28, 0.88)

    for i, stage in ipairs(stages) do
        if not tokenAlive(token) then return end

        effect('blink', 95, 1.0)
        Wait(80)

        local pos = relativePoint(stage[1], stage[2], -0.05)
        local figure = spawnFigure(pos, stage[3], true, false)
        if figure then facePlayer(figure) end

        if i == 1 then
            sendSound('door_creak', randomPan(0.55), 0.34, 0.90, figure)
        elseif i == 2 then
            sendSound('breath', randomPan(0.72), 0.48, 0.88, figure)
        end

        Wait(stage[4])
        cleanupFigure()
    end

    if tokenAlive(token) then
        effect('blink', 105, 1.0)
        Wait(70)
        faceHit()
    end
end

local function rushAtPlayer(token, distance)
    local sideDir = math.random(0, 1) == 0 and -1 or 1
    local start = groundPoint(relativePoint(-(distance or 10.5), sideDir * 1.8, -0.05))
    -- collision on: a moving ped without it has nothing to stand on and falls through the map
    local figure = spawnFigure(start, 245, false, true)
    if not figure then return end

    sendSound('footsteps_run', sideDir * 0.82, 0.84, 1.06, figure) -- the steps run with it
    sendSound('sub_rumble', 0.0, 0.24, 0.95)

    local timeout = GetGameTimer() + 6000

    while tokenAlive(token) and DoesEntityExist(figure) and GetGameTimer() < timeout do
        local p = GetEntityCoords(PlayerPedId())
        local f = GetEntityCoords(figure)

        if #(p - f) < 1.45 then
            effect('blink', 130, 1.0)
            sendSound('jump_sting', 0.0, 1.0, 1.04, figure)
            sendSound('impact', 0.0, 0.82, 0.96)
            ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.78)
            Wait(230)
            StopGameplayCamShaking(true)
            break
        end

        TaskGoStraightToCoord(
            figure,
            p.x,
            p.y,
            p.z,
            5.8,
            650,
            GetEntityHeading(figure),
            0.0
        )

        Wait(150)
    end

    cleanupFigure()
end

local function bodyDropCombo(token)
    sendSound('reverse_sting', randomPan(0.42), 0.34, 0.88)
    Wait(420)

    local dropPos = relativePoint(2.2, (math.random() - 0.5) * 0.7, -0.05)
    local body = spawnBodyAbove(dropPos)

    Wait(480)
    sendSound('body_drop', 0.0, 1.0, 0.98, body) -- the thud from the body itself
    effect('pulse', 320, 0.78)
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.58)

    Wait(620)
    StopGameplayCamShaking(true)

    if tokenAlive(token) then
        sendSound('whisper', randomPan(0.78), 0.48, 0.88)
    end

    if body then
        SetTimeout(cfg().cleanupMs or 9000, function()
            if activeBody == body then cleanupBody() end
        end)
    end
end

local function falseExit(token)
    local pan = randomPan(0.68)

    sendSound('footsteps', pan, 0.50, 0.88)
    Wait(850)
    sendSound('breath', -pan, 0.44, 0.84)
    Wait(700)
    sendSound('heartbeat', 0.0, 0.52, 0.92)

    message('DON\'T TURN AROUND.', 1050)
    Wait(1900)

    -- Nothing. Let the player start believing the scare is over.
    effect('blink', 60, 0.3)
    Wait(math.random(3500, 6500))

    if tokenAlive(token) then
        if math.random(1, 2) == 1 then
            faceHit()
        else
            turnHit(token, nil)
        end
    end
end

local function blackoutBehind(token)
    sendSound('bell', 0.0, 0.48, 0.90)
    Wait(350)

    DoScreenFadeOut(350)
    local timeout = GetGameTimer() + 1800
    while not IsScreenFadedOut() and GetGameTimer() < timeout do Wait(0) end

    local behind = relativePoint(-1.55, 0.0, -0.08)
    local figure = spawnFigure(behind, 255, true, false)
    if figure then facePlayer(figure) end

    Wait(650)
    DoScreenFadeIn(550)

    -- Figure stays behind the player. It only hits when they turn and actually see it.
    local expires = GetGameTimer() + 9500
    local hit = false

    while tokenAlive(token) and figure and DoesEntityExist(figure) and GetGameTimer() < expires do
        local onScreen, sx, sy = entityOnScreen(figure, 0.72)
        if onScreen and sx > 0.24 and sx < 0.76 and sy > 0.12 and sy < 0.90 then
            hit = true
            break
        end
        Wait(0)
    end

    if hit then
        sendSound('jump_sting', 0.0, 1.0, 1.0, figure)
        effect('glitch', 420, 1.0)
        ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.68)
        Wait(330)
        StopGameplayCamShaking(true)
    end

    cleanupFigure()
end

local function runSequence(sequenceName, force)
    local token = beginSequence(sequenceName, force)
    if not token then return false end

    CreateThread(function()
        cleanupAll()

        if not waitForCasebookClose(token) then
            finishSequence(token)
            return
        end

        Wait(math.random(350, 850))
        if not tokenAlive(token) then return end

        -- Named choreography -------------------------------------------------
        if sequenceName == 'peripheral_peek' then
            peripheralPeek(token)

        elseif sequenceName == 'exit_face' then
            if waitForMovement(token, 0.8, 12000) then
                faceHit()
            end

        elseif sequenceName == 'coffin_turn' then
            -- Existing coffin knock sound can play first; the figure comes later.
            Wait(2200)
            turnHit(token, nil)

        elseif sequenceName == 'aisle_watcher' then
            aisleWatcher(token, 8.0)

        elseif sequenceName == 'exit_pass' then
            if waitForMovement(token, 0.75, 11000) then
                passAcrossView(token, true)
            end

        elseif sequenceName == 'hall_pass' then
            Wait(450)
            passAcrossView(token, true)

        elseif sequenceName == 'cell_turn' then
            -- a cell door slams down the corridor first: that is what you both heard
            sendSound('cell_slam', 0.0, 0.9, 1.0, nil, M8_EvidenceCoords and M8_EvidenceCoords('cell_eight'))
            Wait(1400)
            if not tokenAlive(token) then return end
            turnHit(token, 'YOU HEARD THAT TOO.')

        elseif sequenceName == 'false_exit' then
            falseExit(token)

        elseif sequenceName == 'morgue_blink' then
            blinkApproach(token)

        elseif sequenceName == 'body_drop_combo' then
            bodyDropCombo(token)

        elseif sequenceName == 'hospital_exit' then
            if waitForMovement(token, 1.0, 12000) then
                aisleWatcher(token, 6.8)
            end

        elseif sequenceName == 'platform_rush' then
            rushAtPlayer(token, 11.5)

        elseif sequenceName == 'track_watcher' then
            aisleWatcher(token, 11.0)

        elseif sequenceName == 'station_exit' then
            if waitForMovement(token, 1.2, 12000) then
                peripheralPeek(token)
            end

        elseif sequenceName == 'wet_body' then
            bodyDropCombo(token)

        elseif sequenceName == 'dock_turn' then
            Wait(1200)
            turnHit(token, nil)

        elseif sequenceName == 'dock_exit' then
            if waitForMovement(token, 1.1, 12000) then
                aisleWatcher(token, 9.5)
            end

        elseif sequenceName == 'archive_watcher' then
            aisleWatcher(token, 7.2)

        elseif sequenceName == 'archive_turn' then
            turnHit(token, 'NOVA WAS NOT ALONE.')

        elseif sequenceName == 'blackout_behind' then
            blackoutBehind(token)

        elseif sequenceName == 'compound_blink' then
            blinkApproach(token)

        elseif sequenceName == 'compound_false' then
            falseExit(token)

        elseif sequenceName == 'compound_turn' then
            turnHit(token, 'DON\'T LOOK BEHIND HIM.')

        else
        end

        cleanupFigure()
        finishSequence(token)
    end)

    return true
end

function M8ScriptedScares.HandlesEvidence(evidenceId)
    local map = cfg().evidence or {}
    return map[evidenceId] ~= nil and map[evidenceId] ~= false
end

function M8ScriptedScares.Run(name, force)
    return runSequence(name, force == true)
end

function M8ScriptedScares.Stop()
    sequenceToken = sequenceToken + 1
    active = false
    cleanupAll()
end

AddEventHandler('m8:client:evidenceFound', function(evidenceId)
    if cfg().enabled == false then return end

    local sequenceName = (cfg().evidence or {})[evidenceId]
    if not sequenceName or sequenceName == false then return end
    if firedEvidence[evidenceId] then return end

    firedEvidence[evidenceId] = true

    CreateThread(function()
        -- Short grace period so evidence/casebook state finishes updating.
        Wait(math.random(500, 1100))

        local expires = GetGameTimer() + 22000
        while GetGameTimer() < expires do
            if not active and M8_IsHuntTime() then
                if runSequence(sequenceName, false) then return end
            end
            Wait(300)
        end
    end)
end)

RegisterNetEvent('m8:client:progress', function(progress)
    -- Fresh progress should allow authored scares to fire again.
    if not progress or not progress.evidence or next(progress.evidence) == nil then
        firedEvidence = {}
        M8ScriptedScares.Stop()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    M8ScriptedScares.Stop()
end)

