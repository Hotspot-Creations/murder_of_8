-- Murder of 8 - Chapter 8 Final Sequence
--
-- Final bell:
--   blackout
--   -> wake on bed facing the wall
--   -> old wall display props are hidden
--   -> darkvanar_halloween_uni_text appears on the wall
--   -> screen: "Your mind tells you to turn around."
--   -> when the player actually turns toward the body position, corpse drops
--   -> credits
--
-- The finale saves `last_message` automatically after the body drop.

local Finale = {
    bed = vector4(1635.1184, 3519.9009, 50.5055, 312.4570),

    -- Where the hanging corpse ends its drop.
    -- Tune Z here if the custom model hangs too high/low.
    dropEnd = vector4(1633.5579, 3518.9634, 52.3500, 311.5444),
    dropHeight = 3.20,
    dropDurationMs = 720,

    bodyModels = {
        'darkvanar_halloween_hanging_corpse_01',
        'prop_cs_dead_guy',
        'prop_rub_corpse_01'
    },

    -- Wall message prop. These are local offsets from the bed position.
    -- Use /m8finalwall and /m8finalwalloffset to tune it live.
    wallText = {
        model = 'darkvanar_halloween_text_02',
        side = 0.00,
        forward = 3.80,
        height = 1.30,
        rotX = 0.0,
        rotY = 0.0,
        headingOffset = 167.65
    },

    -- Turn detection. The body will not drop just because the camera moved a
    -- little; the player must turn away from the wall and toward the body.
    minimumTurnDegrees = 70.0,
    bodyLookTolerance = 38.0,

    -- Wake-up pacing.
    fadeOutMs = 650,
    streamWaitMs = 900,
    sleepingHoldMs = 1500,

    -- Credits.
    creditsDelayMs = 1500,
    creditsDurationMs = 9500,

    -- The two wall-frame props in this room are map objects.
    -- We clear a small prop-only bubble in front of the bed so those display
    -- objects disappear for the finale without touching building geometry.
    --
    -- If this catches too much/too little, tune these three values.
    cleanup = {
        enabled = true,
        forward = 2.15,
        side = 0.0,
        height = 1.30,
        radius = 1.40
    }
}

local sequenceRunning = false
local bodyEntity = nil
local wallTextEntity = nil
local hiddenDecor = {}
local lastMessageSaved = false

local function clamp(v, low, high)
    if v < low then return low end
    if v > high then return high end
    return v
end

local function angleDifference(a, b)
    local diff = math.abs((a - b) % 360.0)

    if diff > 180.0 then
        diff = 360.0 - diff
    end

    return diff
end

local function cameraHeading()
    return GetGameplayCamRot(2).z
end

local function waitForFadeOut(timeoutMs)
    local timeout = GetGameTimer() + (timeoutMs or 2500)

    while not IsScreenFadedOut() and GetGameTimer() < timeout do
        Wait(0)
    end
end

local function waitForTurn(fromHeading, requiredDegrees)
    while sequenceRunning do
        local current = cameraHeading()

        if angleDifference(current, fromHeading) >= requiredDegrees then
            return current
        end

        Wait(20)
    end

    return cameraHeading()
end

local function loadModel(modelName)
    local hash = joaat(modelName)

    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return nil
    end

    RequestModel(hash)

    local timeout = GetGameTimer() + 5000

    while not HasModelLoaded(hash) do
        Wait(20)

        if GetGameTimer() >= timeout then
            return nil
        end
    end

    return hash
end

local function loadBodyModel()
    for _, modelName in ipairs(Finale.bodyModels) do
        local hash = loadModel(modelName)

        if hash then
            return hash, modelName
        end
    end

    return nil, nil
end

local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then
        return true
    end

    RequestAnimDict(dict)

    local timeout = GetGameTimer() + 5000

    while not HasAnimDictLoaded(dict) do
        Wait(10)

        if GetGameTimer() >= timeout then
            return false
        end
    end

    return true
end

local function deleteBody()
    if bodyEntity and DoesEntityExist(bodyEntity) then
        SetEntityAsMissionEntity(bodyEntity, true, true)
        DeleteEntity(bodyEntity)
    end

    bodyEntity = nil
end


local function deleteWallText()
    if wallTextEntity and DoesEntityExist(wallTextEntity) then
        SetEntityAsMissionEntity(wallTextEntity, true, true)
        DeleteEntity(wallTextEntity)
    end

    wallTextEntity = nil
end

local function getWallTextCoords()
    local c = Finale.wallText

    return GetOffsetFromCoordAndHeadingInWorldCoords(
        Finale.bed.x,
        Finale.bed.y,
        Finale.bed.z,
        Finale.bed.w,
        c.side or 0.0,
        c.forward or 2.15,
        c.height or 1.30
    )
end

local function spawnWallText()
    deleteWallText()

    local cfg = Finale.wallText
    local hash = loadModel(cfg.model)

    if not hash then
        print(
            ('^1[Murder of 8 Finale]^0 Could not load wall text model: %s')
                :format(tostring(cfg.model))
        )
        return false
    end

    local coords = getWallTextCoords()

    wallTextEntity = CreateObjectNoOffset(
        hash,
        coords.x,
        coords.y,
        coords.z,
        false,
        false,
        false
    )

    if not wallTextEntity or not DoesEntityExist(wallTextEntity) then
        wallTextEntity = nil
        SetModelAsNoLongerNeeded(hash)
        return false
    end

    SetEntityAsMissionEntity(wallTextEntity, true, true)
    SetEntityCollision(wallTextEntity, false, false)

    SetEntityRotation(
        wallTextEntity,
        cfg.rotX or 0.0,
        cfg.rotY or 0.0,
        Finale.bed.w + (cfg.headingOffset or 180.0),
        2,
        true
    )

    FreezeEntityPosition(wallTextEntity, true)

    SetModelAsNoLongerNeeded(hash)

    if Config.Debug then
        print(
            ('^2[Murder of 8 Finale]^0 Wall text spawned at vector3(%.4f, %.4f, %.4f) | rot %.2f %.2f %.2f')
                :format(
                    coords.x,
                    coords.y,
                    coords.z,
                    cfg.rotX or 0.0,
                    cfg.rotY or 0.0,
                    Finale.bed.w + (cfg.headingOffset or 180.0)
                )
        )
    end

    return true
end

local function headingToBodyFromPlayer()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local dx = Finale.dropEnd.x - playerCoords.x
    local dy = Finale.dropEnd.y - playerCoords.y

    return GetHeadingFromVector_2d(dx, dy)
end

local function waitForTurnTowardBody(startHeading)
    local targetHeading = headingToBodyFromPlayer()

    while sequenceRunning do
        local current = cameraHeading()
        local turned = angleDifference(current, startHeading)
        local bodyDelta = angleDifference(current, targetHeading)

        if turned >= Finale.minimumTurnDegrees
            and bodyDelta <= Finale.bodyLookTolerance
        then
            return current
        end

        Wait(20)
    end

    return cameraHeading()
end

local function restoreDecor()
    for _, item in ipairs(hiddenDecor) do
        local entity = item.entity

        if entity and DoesEntityExist(entity) then
            ResetEntityAlpha(entity)
            SetEntityVisible(entity, true, false)
            SetEntityCollision(entity, item.hadCollision, item.hadCollision)
        end
    end

    hiddenDecor = {}
end

local function getCleanupCenter()
    local c = Finale.cleanup

    return GetOffsetFromCoordAndHeadingInWorldCoords(
        Finale.bed.x,
        Finale.bed.y,
        Finale.bed.z,
        Finale.bed.w,
        c.side or 0.0,
        c.forward or 2.15,
        c.height or 1.30
    )
end

local function hideFinalRoomDecor()
    if not Finale.cleanup.enabled then
        return
    end

    restoreDecor()

    local center = getCleanupCenter()
    local radius = Finale.cleanup.radius or 1.40

    for _, object in ipairs(GetGamePool('CObject')) do
        if DoesEntityExist(object) then
            local coords = GetEntityCoords(object)
            local distance = #(coords - center)

            if distance <= radius then
                local model = GetEntityModel(object)
                local hadCollision = not GetEntityCollisionDisabled(object)

                hiddenDecor[#hiddenDecor + 1] = {
                    entity = object,
                    hadCollision = hadCollision
                }

                SetEntityVisible(object, false, false)
                SetEntityAlpha(object, 0, false)
                SetEntityCollision(object, false, false)

                if Config.Debug then
                    print(
                        ('^3[Murder of 8 Finale]^0 Hidden decor hash=%s at vector3(%.4f, %.4f, %.4f) dist=%.2f')
                            :format(
                                tostring(model),
                                coords.x,
                                coords.y,
                                coords.z,
                                distance
                            )
                    )
                end
            end
        end
    end

    if Config.Debug then
        print(
            ('^3[Murder of 8 Finale]^0 Cleanup center vector3(%.4f, %.4f, %.4f), radius %.2f, hidden=%d')
                :format(center.x, center.y, center.z, radius, #hiddenDecor)
        )
    end
end

local function showFinaleText(mode, text, duration)
    SendNUIMessage({
        action = 'finaleText',
        mode = mode or 'message',
        text = text or '',
        duration = duration or 0
    })
end

local function clearFinaleText()
    SendNUIMessage({
        action = 'finaleClear'
    })
end

local function showCredits()
    SendNUIMessage({
        action = 'finaleCredits',
        title = 'MURDER OF 8',
        subtitle = 'THE LAST WITNESS',
        credit = 'A HOTSPOT CREATIONS HALLOWEEN EVENT',
        footer = 'THE BELL HAS STOPPED. FOR NOW.',
        duration = Finale.creditsDurationMs
    })
end

local function teleportToBed()
    local ped = PlayerPedId()

    SetEntityCoordsNoOffset(
        ped,
        Finale.bed.x,
        Finale.bed.y,
        Finale.bed.z,
        false,
        false,
        false
    )

    SetEntityHeading(ped, Finale.bed.w)

    -- Make the wake-up view face the wall text instead of inheriting whatever
    -- camera angle the player had before the teleport.
    SetGameplayCamRelativeHeading(0.0)
    SetGameplayCamRelativePitch(-4.0, 1.0)
end

local function beginWakeUp()
    local ped = PlayerPedId()

    FreezeEntityPosition(ped, true)

    -- A reliable lying/sleeping pose used by GTA/FiveM.
    local dict = 'timetable@tracy@sleep@'
    local anim = 'idle_c'

    if loadAnimDict(dict) then
        TaskPlayAnim(
            ped,
            dict,
            anim,
            4.0,
            -4.0,
            -1,
            1,
            0.0,
            false,
            false,
            false
        )
    end

    DoScreenFadeIn(900)

    local untilTime = GetGameTimer() + Finale.sleepingHoldMs

    while sequenceRunning and GetGameTimer() < untilTime do
        DisableAllControlActions(0)
        Wait(0)
    end

    ClearPedTasks(ped)

    -- Give the engine a beat to stand the ped up naturally.
    Wait(550)

    FreezeEntityPosition(ped, false)
end

local function spawnAndDropBody()
    deleteBody()

    local hash, modelName = loadBodyModel()

    if not hash then
        print('^1[Murder of 8 Finale]^0 WARNING: no final corpse model could be loaded.')
        return false
    end

    local endCoords = Finale.dropEnd
    local startZ = endCoords.z + Finale.dropHeight

    bodyEntity = CreateObjectNoOffset(
        hash,
        endCoords.x,
        endCoords.y,
        startZ,
        false,
        false,
        false
    )

    if not bodyEntity or not DoesEntityExist(bodyEntity) then
        bodyEntity = nil
        SetModelAsNoLongerNeeded(hash)
        return false
    end

    SetEntityAsMissionEntity(bodyEntity, true, true)
    SetEntityHeading(bodyEntity, endCoords.w)
    SetEntityCollision(bodyEntity, false, false)
    FreezeEntityPosition(bodyEntity, true)

    local startedAt = GetGameTimer()
    local duration = math.max(1, Finale.dropDurationMs)

    SendNUIMessage({
        action = 'sound',
        name = 'body_drop',
        volume = 1.0,
        nativeBypass = true
    })

    while sequenceRunning do
        local elapsed = GetGameTimer() - startedAt
        local t = clamp(elapsed / duration, 0.0, 1.0)

        -- Fast initial fall with a slight ease-out at the bottom.
        local eased = 1.0 - ((1.0 - t) * (1.0 - t))
        local z = startZ + ((endCoords.z - startZ) * eased)

        SetEntityCoordsNoOffset(
            bodyEntity,
            endCoords.x,
            endCoords.y,
            z,
            false,
            false,
            false
        )

        if t >= 1.0 then
            break
        end

        Wait(0)
    end

    SetEntityCoordsNoOffset(
        bodyEntity,
        endCoords.x,
        endCoords.y,
        endCoords.z,
        false,
        false,
        false
    )

    SetEntityHeading(bodyEntity, endCoords.w)
    FreezeEntityPosition(bodyEntity, true)
    SetEntityCollision(bodyEntity, false, false)

    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.22)

    SetModelAsNoLongerNeeded(hash)

    if Config.Debug then
        print(
            ('^2[Murder of 8 Finale]^0 Dropped final corpse using %s at vector4(%.4f, %.4f, %.4f, %.4f)')
                :format(
                    modelName,
                    endCoords.x,
                    endCoords.y,
                    endCoords.z,
                    endCoords.w
                )
        )
    end

    return true
end

local function saveLastMessage()
    if lastMessageSaved then
        return
    end

    local progress = M8_GetProgress and M8_GetProgress() or nil

    if progress
        and progress.evidence
        and progress.evidence.last_message
    then
        lastMessageSaved = true
        return
    end

    lastMessageSaved = true

    TriggerServerEvent(
        'm8:server:findEvidence',
        'last_message'
    )
end

local function resetFinale()
    sequenceRunning = false
    lastMessageSaved = false

    clearFinaleText()
    deleteBody()
    deleteWallText()
    restoreDecor()

    local ped = PlayerPedId()

    if ped and DoesEntityExist(ped) then
        FreezeEntityPosition(ped, false)
        ClearPedTasks(ped)
    end
end

local function beginFinalBellSequence()
    if sequenceRunning then
        return
    end

    sequenceRunning = true
    lastMessageSaved = false

    clearFinaleText()
    deleteBody()
    deleteWallText()

    CreateThread(function()
        SendNUIMessage({
            action = 'sound',
            name = 'bell'
        })

        Wait(450)

        DoScreenFadeOut(Finale.fadeOutMs)
        waitForFadeOut(3000)

        teleportToBed()

        -- Let the room stream while the screen is black.
        Wait(Finale.streamWaitMs)

        -- Remove the two unwanted wall display/frame props first.
        hideFinalRoomDecor()

        -- Then put our finale text prop on the clean wall.
        spawnWallText()

        beginWakeUp()

        if not sequenceRunning then return end

        Wait(350)

        -- Re-center the view after the wake animation so the player begins by
        -- looking at the wall text.
        SetGameplayCamRelativeHeading(0.0)
        SetGameplayCamRelativePitch(-4.0, 1.0)

        Wait(250)

        local startHeading = cameraHeading()

        showFinaleText(
            'command',
            'Your mind tells you to turn around.',
            0
        )

        -- Do not trigger from a tiny camera twitch. Wait until the player has
        -- genuinely turned away from the wall AND is looking toward the place
        -- where the hanging corpse will fall.
        waitForTurnTowardBody(startHeading)

        if not sequenceRunning then return end

        clearFinaleText()

        local ped = PlayerPedId()

        -- Freeze movement for the actual drop so the scare lands consistently.
        FreezeEntityPosition(ped, true)

        Wait(90)

        spawnAndDropBody()

        -- This is the final story evidence and completes Chapter 8 silently.
        saveLastMessage()

        Wait(Finale.creditsDelayMs)

        showCredits()

        local creditEnd = GetGameTimer() + Finale.creditsDurationMs

        while sequenceRunning and GetGameTimer() < creditEnd do
            DisableAllControlActions(0)
            Wait(0)
        end

        FreezeEntityPosition(ped, false)

        sequenceRunning = false
    end)
end

RegisterNetEvent(
    'm8:compound:finalBell',
    beginFinalBellSequence
)

-- Reset/fresh progress removes the local finale.
RegisterNetEvent('m8:client:progress', function(progress)
    if not progress or not progress.evidence then
        return
    end

    if not progress.evidence.final_bell then
        resetFinale()
    elseif progress.evidence.last_message then
        lastMessageSaved = true
    end
end)

-- DEBUG ----------------------------------------------------------------------

-- Spawn only the final wall text so it can be positioned without replaying
-- the entire cinematic.
RegisterCommand('m8finalwall', function()
    if not Config.Debug then return end

    spawnWallText()

    TriggerEvent(
        'm8:client:notify',
        'Final wall text spawned. Use /m8finalwalloffset to tune it.'
    )
end, false)

-- /m8finalwalloffset <side> <forward> <height> [rotX] [rotY] [headingOffset]
--
-- Example:
-- /m8finalwalloffset 0.00 2.15 1.30 0 0 180
RegisterCommand('m8finalwalloffset', function(_, args)
    if not Config.Debug then return end

    local side = tonumber(args[1])
    local forward = tonumber(args[2])
    local height = tonumber(args[3])

    if not side or not forward or not height then
        print(
            '^1[Murder of 8 Finale]^0 Usage: /m8finalwalloffset <side> <forward> <height> [rotX] [rotY] [headingOffset]'
        )
        return
    end

    local cfg = Finale.wallText

    cfg.side = side
    cfg.forward = forward
    cfg.height = height
    cfg.rotX = tonumber(args[4]) or cfg.rotX or 0.0
    cfg.rotY = tonumber(args[5]) or cfg.rotY or 0.0
    cfg.headingOffset = tonumber(args[6]) or cfg.headingOffset or 180.0

    spawnWallText()

    local coords = getWallTextCoords()

    print('^5[Murder of 8 Finale]^0 Copy these wallText values into finale.lua:')
    print(
        ('side = %.3f, forward = %.3f, height = %.3f, rotX = %.2f, rotY = %.2f, headingOffset = %.2f')
            :format(
                cfg.side,
                cfg.forward,
                cfg.height,
                cfg.rotX,
                cfg.rotY,
                cfg.headingOffset
            )
    )

    print(
        ('^5[Murder of 8 Finale]^0 Current world coords: vector3(%.4f, %.4f, %.4f)')
            :format(coords.x, coords.y, coords.z)
    )
end, false)

RegisterCommand('m8finalwallremove', function()
    if not Config.Debug then return end
    deleteWallText()
end, false)

RegisterCommand('m8finaltest', function()
    if not Config.Debug then return end

    resetFinale()
    Wait(100)
    beginFinalBellSequence()
end, false)

RegisterCommand('m8finaldrop', function()
    if not Config.Debug then return end

    deleteBody()

    sequenceRunning = true
    spawnAndDropBody()
    sequenceRunning = false
end, false)

RegisterCommand('m8finalcleanup', function()
    if not Config.Debug then return end

    hideFinalRoomDecor()

    TriggerEvent(
        'm8:client:notify',
        ('Final room cleanup hid %d nearby prop(s). Check F8 for hashes/coords.')
            :format(#hiddenDecor)
    )
end, false)

RegisterCommand('m8finalrestore', function()
    if not Config.Debug then return end

    resetFinale()

    TriggerEvent(
        'm8:client:notify',
        'Finale body/decor restored/cleared.'
    )
end, false)

RegisterCommand('m8finalcoords', function()
    if not Config.Debug then return end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    print(
        ('^5[Murder of 8 Finale]^0 Player vector4(%.4f, %.4f, %.4f, %.4f)')
            :format(coords.x, coords.y, coords.z, heading)
    )

    local center = getCleanupCenter()

    print(
        ('^5[Murder of 8 Finale]^0 Cleanup center vector3(%.4f, %.4f, %.4f)')
            :format(center.x, center.y, center.z)
    )
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    resetFinale()
end)

print('^2[Murder of 8 Finale]^0 Final wake/wall-turn/body-drop/credits sequence loaded.')
