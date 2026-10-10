-- Murder of 8 - Chair 8 / Voss
-- Chair 8 is spawned by evidence_props.lua as instance `chair_8`.
-- This file never creates another chair.

local vossPed = nil
local vossCuffs = nil
local novaFound = false

-- Voss reveal / HELP sequence
local helpLoopRunning = false
local helpLoopToken = 0
local vossReached = false

local HELP_SOUND = 'voss_help'
local HELP_MAX_DISTANCE = 45.0
local HELP_STOP_DISTANCE = 5.0
local HELP_INTERVAL_MS = 6500

local function config()
    return Config.CompoundChair8 or {}
end

local function loadModel(modelName)
    local hash = joaat(modelName)

    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        print(('^1[Murder of 8 Chair 8]^0 Invalid model: %s'):format(tostring(modelName)))
        return nil
    end

    RequestModel(hash)

    local timeout = GetGameTimer() + 5000

    while not HasModelLoaded(hash) do
        Wait(10)

        if GetGameTimer() >= timeout then
            print(('^1[Murder of 8 Chair 8]^0 Failed loading model: %s'):format(tostring(modelName)))
            return nil
        end
    end

    return hash
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
            print(('^1[Murder of 8 Chair 8]^0 Failed loading anim dict: %s'):format(dict))
            return false
        end
    end

    return true
end

local function getChair8()
    if not M8_GetSpawnedEvidenceProp then
        return nil
    end

    return M8_GetSpawnedEvidenceProp(config().instance or 'chair_8')
end


-- VOSS HELP AUDIO -------------------------------------------------------------

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function getPanToWorldPoint(target)
    local playerCoords = GetEntityCoords(PlayerPedId())

    local dx = target.x - playerCoords.x
    local dy = target.y - playerCoords.y

    local length = math.sqrt((dx * dx) + (dy * dy))
    if length < 0.001 then
        return 0.0
    end

    dx = dx / length
    dy = dy / length

    local yaw = math.rad(GetGameplayCamRot(2).z)
    local forwardX = -math.sin(yaw)
    local forwardY =  math.cos(yaw)
    local rightX = forwardY
    local rightY = -forwardX

    return clamp((dx * rightX) + (dy * rightY), -1.0, 1.0)
end

local function playVossHelp()
    local chair = getChair8()
    if not chair or not DoesEntityExist(chair) then
        return false
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local chairCoords = GetEntityCoords(chair)
    local distance = #(playerCoords - chairCoords)

    if distance > HELP_MAX_DISTANCE then
        return false
    end

    local range = HELP_MAX_DISTANCE - HELP_STOP_DISTANCE
    local progress = 1.0

    if range > 0.0 then
        progress = 1.0 - clamp(
            (distance - HELP_STOP_DISTANCE) / range,
            0.0,
            1.0
        )
    end

    local volume = 0.18 + (progress * 0.82)
    local pan = getPanToWorldPoint(chairCoords)

    SendNUIMessage({
        action = 'sound',
        name = HELP_SOUND,
        volume = volume,
        pan = pan,
        rate = 1.0,
        nativeBypass = true
    })

    return true
end

local function stopVossHelp()
    helpLoopToken = helpLoopToken + 1
    helpLoopRunning = false
end

local function startVossHelp()
    if helpLoopRunning or vossReached then
        return
    end

    local chair = getChair8()
    if not chair then
        return
    end

    helpLoopRunning = true
    helpLoopToken = helpLoopToken + 1

    local myToken = helpLoopToken

    CreateThread(function()
        local nextCall = 0

        while helpLoopRunning and helpLoopToken == myToken do
            if not vossPed or not DoesEntityExist(vossPed) then
                break
            end

            local currentChair = getChair8()
            if not currentChair or not DoesEntityExist(currentChair) then
                break
            end

            local playerCoords = GetEntityCoords(PlayerPedId())
            local chairCoords = GetEntityCoords(currentChair)
            local distance = #(playerCoords - chairCoords)

            if distance <= HELP_STOP_DISTANCE then
                vossReached = true

                TriggerEvent('m8:client:vossReached', vossPed, currentChair)
                break
            end

            local now = GetGameTimer()

            if distance <= HELP_MAX_DISTANCE and now >= nextCall then
                playVossHelp()
                nextCall = now + HELP_INTERVAL_MS
            end

            Wait(250)
        end

        if helpLoopToken == myToken then
            helpLoopRunning = false
        end
    end)
end

local function removeVossCuffs()
    if vossCuffs and DoesEntityExist(vossCuffs) then
        DetachEntity(vossCuffs, true, true)
        SetEntityAsMissionEntity(vossCuffs, true, true)
        DeleteEntity(vossCuffs)
    end

    vossCuffs = nil
end

local function addVossCuffs(ped)
    if not ped or not DoesEntityExist(ped) then return end

    removeVossCuffs()
    SetEnableHandcuffs(ped, true)

    local cuffModel = 'p_cs_cuffs_02_s'
    local hash = loadModel(cuffModel)
    if not hash then return end

    local coords = GetEntityCoords(ped)

    vossCuffs = CreateObjectNoOffset(
        hash,
        coords.x,
        coords.y,
        coords.z,
        false,
        false,
        false
    )

    if not vossCuffs or not DoesEntityExist(vossCuffs) then
        vossCuffs = nil
        SetModelAsNoLongerNeeded(hash)
        return
    end

    SetEntityAsMissionEntity(vossCuffs, true, true)
    SetEntityCollision(vossCuffs, false, false)

    local handBone = GetPedBoneIndex(ped, 57005)

    AttachEntityToEntity(
        vossCuffs,
        ped,
        handBone,
        0.02,
        0.02,
        0.00,
        0.0,
        90.0,
        90.0,
        true,
        true,
        false,
        true,
        1,
        true
    )

    SetModelAsNoLongerNeeded(hash)
end

local function removeVoss()
    stopVossHelp()
    removeVossCuffs()

    if vossPed and DoesEntityExist(vossPed) then
        FreezeEntityPosition(vossPed, false)
        SetEnableHandcuffs(vossPed, false)
        SetEntityAsMissionEntity(vossPed, true, true)
        DeleteEntity(vossPed)
    end

    vossPed = nil
end

local function refreshNovaState(progress)
    progress = progress or (M8_GetProgress and M8_GetProgress() or nil)

    novaFound =
        progress
        and progress.evidence
        and progress.evidence.nova_body == true
        or false
end

local function applyRestrainedPose(ped)
    if not ped or not DoesEntityExist(ped) then return end

    local dict = 'mp_arresting'
    local anim = 'idle'

    if not loadAnimDict(dict) then
        return
    end

    TaskPlayAnim(
        ped,
        dict,
        anim,
        8.0,
        -8.0,
        -1,
        49,
        0.0,
        false,
        false,
        false
    )

    SetPedKeepTask(ped, true)
end

local function spawnVoss(ignoreGate)
    if vossPed and DoesEntityExist(vossPed) then
        return vossPed
    end

    if not ignoreGate and not novaFound then
        return nil
    end

    local chair = getChair8()

    if not chair then
        return nil
    end

    local vossCfg = config().voss

    if not vossCfg then
        print('^1[Murder of 8 Chair 8]^0 Missing Config.CompoundChair8.voss')
        return nil
    end

    local hash = loadModel(vossCfg.model)
    if not hash then return nil end

    local offset = vossCfg.offset or vector3(0.0, -0.12, 0.47)

    local seatCoords = GetOffsetFromEntityInWorldCoords(
        chair,
        offset.x,
        offset.y,
        offset.z
    )

    local heading =
        GetEntityHeading(chair)
        + (vossCfg.headingOffset or 0.0)

    vossPed = CreatePed(
        4,
        hash,
        seatCoords.x,
        seatCoords.y,
        seatCoords.z,
        heading,
        false,
        false
    )

    if not vossPed or not DoesEntityExist(vossPed) then
        vossPed = nil
        SetModelAsNoLongerNeeded(hash)
        return nil
    end

    SetEntityAsMissionEntity(vossPed, true, true)
    SetBlockingOfNonTemporaryEvents(vossPed, true)
    SetEntityInvincible(vossPed, true)
    SetPedCanRagdoll(vossPed, false)
    SetPedCanEvasiveDive(vossPed, false)
    SetPedFleeAttributes(vossPed, 0, false)
    SetPedCombatAttributes(vossPed, 5, false)
    SetPedCombatAttributes(vossPed, 17, false)
    SetPedCombatAttributes(vossPed, 46, false)
    SetPedKeepTask(vossPed, true)
    SetEntityCollision(vossPed, false, false)
    SetEntityHeading(vossPed, heading)

    Wait(50)

    TaskStartScenarioAtPosition(
        vossPed,
        'PROP_HUMAN_SEAT_CHAIR',
        seatCoords.x,
        seatCoords.y,
        seatCoords.z,
        heading,
        -1,
        true,
        false
    )

    SetModelAsNoLongerNeeded(hash)

    CreateThread(function()
        Wait(1200)

        if not vossPed or not DoesEntityExist(vossPed) then return end

        SetEnableHandcuffs(vossPed, true)
        applyRestrainedPose(vossPed)

        Wait(500)

        if not vossPed or not DoesEntityExist(vossPed) then return end

        addVossCuffs(vossPed)
        FreezeEntityPosition(vossPed, true)
    end)

    print(
        ('^2[Murder of 8 Chair 8]^0 Voss spawned on chair_8 | offset %.3f %.3f %.3f | headingOffset %.2f')
            :format(
                offset.x,
                offset.y,
                offset.z,
                vossCfg.headingOffset or 0.0
            )
    )

    return vossPed
end

RegisterNetEvent('m8:client:progress', function(progress)
    refreshNovaState(progress)

    if not novaFound then
        removeVoss()
    end
end)

AddEventHandler('m8:client:evidenceFound', function(evidenceId)
    if evidenceId ~= 'nova_body' then return end

    novaFound = true
    vossReached = false

    CreateThread(function()
        Wait(1500)

        local ped = spawnVoss(false)

        if ped then
            startVossHelp()
        end
    end)
end)

CreateThread(function()
    Wait(2000)

    refreshNovaState()

    while true do
        local chair = getChair8()

        if chair then
            if novaFound
                and not (vossPed and DoesEntityExist(vossPed))
            then
                local ped = spawnVoss(false)

                if ped and novaFound and not vossReached then
                    startVossHelp()
                end
            elseif novaFound and not vossReached and not helpLoopRunning then
                startVossHelp()
            end
        elseif vossPed then
            removeVoss()
        end

        Wait(750)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    removeVoss()
end)

