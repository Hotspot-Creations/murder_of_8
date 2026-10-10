-- Murder of 8 - physical evidence props
--
-- Placement source:
--     Config.EvidenceProps in scenes.lua
--
-- IMPORTANT:
-- Physical evidence is NIGHT ONLY.
-- It spawns during Config.Hunt.startHour -> Config.Hunt.endHour
-- (currently 21:00 -> 05:00) and is deleted in daylight.

local spawned = {}
local currentChapter = 1

local function isHuntTime()
    -- Prefer the main script's shared helper once it is available.
    if M8_IsHuntTime then
        return M8_IsHuntTime()
    end

    local hunt = Config.Hunt or { startHour = 21, endHour = 5 }
    local hour = GetClockHours()
    local startHour = hunt.startHour or 21
    local endHour = hunt.endHour or 5

    if startHour > endHour then
        return hour >= startHour or hour < endHour
    end

    return hour >= startHour and hour < endHour
end

local function getSceneChapter(evidenceId)
    for _, scene in pairs(Config.Scenes or {}) do
        if scene.evidence and scene.evidence[evidenceId] then
            return scene.chapter or 1
        end
    end

    return 1
end

local function validCoords(coords)
    return coords
        and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0)
end

local function loadModel(modelName)
    local hash = joaat(modelName)

    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        if Config.Debug then
            print(
                ('^1[Murder of 8 Props]^0 Invalid model for %s: %s')
                :format(tostring(modelName), tostring(modelName))
            )
        end
        return nil
    end

    RequestModel(hash)

    local timeout = GetGameTimer() + 5000

    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(20)
    end

    if not HasModelLoaded(hash) then
        if Config.Debug then
            print(
                ('^1[Murder of 8 Props]^0 Timed out loading model: %s')
                :format(tostring(modelName))
            )
        end
        return nil
    end

    return hash
end

local function deleteProp(id)
    local entity = spawned[id]

    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end

    spawned[id] = nil
end

local function deleteAllProps()
    local ids = {}

    for id in pairs(spawned) do
        ids[#ids + 1] = id
    end

    for _, id in ipairs(ids) do
        deleteProp(id)
    end
end

local function spawnProp(prop)
    if not prop or not prop.id then return end

    -- Allows multiple physical props to share one evidence ID.
    -- Example:
    -- id = 'eight_chairs', instance = 'chair_1'
    local spawnKey = prop.instance or prop.id

    if spawned[spawnKey] then return end
    if prop.enabled == false then return end
    if not prop.model or not validCoords(prop.coords) then return end
    if not isHuntTime() then return end

    local requiredChapter = prop.chapter or getSceneChapter(prop.id)

    if currentChapter < requiredChapter then
        return
    end

    local hash = loadModel(prop.model)
    if not hash then return end

    local coords = prop.coords

    local object = CreateObjectNoOffset(
        hash,
        coords.x,
        coords.y,
        coords.z,
        false,
        false,
        false
    )

    if object and DoesEntityExist(object) then
        if prop.rotation then
            SetEntityRotation(
                object,
                prop.rotation.x or 0.0,
                prop.rotation.y or 0.0,
                prop.rotation.z or coords.w or 0.0,
                2,
                true
            )
        else
            SetEntityHeading(
                object,
                coords.w or 0.0
            )
        end

        FreezeEntityPosition(
            object,
            prop.freeze ~= false
        )

        SetEntityCollision(
            object,
            prop.collision ~= false,
            prop.collision ~= false
        )

        if prop.alpha then
            SetEntityAlpha(
                object,
                prop.alpha,
                false
            )
        end

        -- IMPORTANT:
        -- Store by instance instead of evidence ID.
        spawned[spawnKey] = object

        if Config.Debug then
            print(
                ('^2[Murder of 8 Props]^0 Spawned %s [%s] at %.2f, %.2f, %.2f')
                :format(
                    prop.id,
                    spawnKey,
                    coords.x,
                    coords.y,
                    coords.z
                )
            )
        end
    end

    SetModelAsNoLongerNeeded(hash)
end

local function updateChapter(progress)
    currentChapter = tonumber(progress and progress.chapter) or currentChapter or 1
end

RegisterNetEvent('m8:client:progress', function(progress)
    updateChapter(progress)
end)

CreateThread(function()
    Wait(1500)

    local progress = M8_GetProgress and M8_GetProgress() or nil
    updateChapter(progress)

    local wasHuntTime = nil

    while true do
        local night = isHuntTime()

        -- Immediately remove all physical clues when daylight starts.
        if not night then
            if next(spawned) ~= nil then
                deleteAllProps()

                if Config.Debug and wasHuntTime == true then
                    print('^3[Murder of 8 Props]^0 Daylight reached - all evidence props removed.')
                end
            end

            wasHuntTime = false
            Wait(1000)
        else
            local playerCoords = GetEntityCoords(PlayerPedId())

            for _, prop in ipairs(Config.EvidenceProps or {}) do
                if prop.id and validCoords(prop.coords) then
                    local requiredChapter = prop.chapter or getSceneChapter(prop.id)
                    local spawnDistance = prop.spawnDistance or 150.0
                    local despawnDistance = prop.despawnDistance or 190.0
                    local distance = #(playerCoords - vector3(
                        prop.coords.x,
                        prop.coords.y,
                        prop.coords.z
                    ))

                    local spawnKey = prop.instance or prop.id

                    if currentChapter >= requiredChapter
                        and prop.enabled ~= false
                        and distance <= spawnDistance
                    then
                        if not spawned[spawnKey] then
                            spawnProp(prop)
                        end
                    elseif spawned[spawnKey]
                        and (
                            distance > despawnDistance
                            or currentChapter < requiredChapter
                            or prop.enabled == false
                        )
                    then
                        deleteProp(spawnKey)
                    end
                end
            end

            if Config.Debug and wasHuntTime == false then
                print('^2[Murder of 8 Props]^0 Hunt hours started - evidence props enabled.')
            end

            wasHuntTime = true
            Wait(750)
        end
    end
end)

-- Expose a specific spawned physical instance to other Murder of 8 scripts.
function M8_GetSpawnedEvidenceProp(key)
    local entity = spawned[key]

    if entity and DoesEntityExist(entity) then
        return entity
    end

    return nil
end

-- DEBUG -----------------------------------------------------------------------

RegisterCommand('m8propstatus', function()
    if not Config.Debug then return end

    local count = 0
    for _ in pairs(spawned) do count = count + 1 end

    local hunt = Config.Hunt or {}
    local msg = ('Time %02d:%02d | hunt=%s | chapter=%s | spawned=%s')
        :format(
            GetClockHours(),
            GetClockMinutes(),
            tostring(isHuntTime()),
            tostring(currentChapter),
            tostring(count)
        )

    print('^5[Murder of 8 Props]^0 ' .. msg)

    if TriggerEvent then
        TriggerEvent('m8:client:notify', msg)
    end
end, false)

RegisterCommand('m8propsreload', function()
    if not Config.Debug then return end

    deleteAllProps()

    if isHuntTime() then
        TriggerEvent('m8:client:notify', 'Evidence props cleared. They will respawn nearby.')
    else
        TriggerEvent('m8:client:notify', 'Evidence props cleared. Daylight gate is active.')
    end
end, false)

RegisterCommand('m8propcoords', function(_, args)
    if not Config.Debug then return end

    local id = args[1]

    if not id or not M8_GetEvidenceProp or not M8_GetEvidenceProp(id) then
        print('^1[Murder of 8 Props]^0 Usage: /m8propcoords <evidenceId>')
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    print(('^2[Murder of 8 Props]^0 %s'):format(id))
    print(
        ('coords = vector4(%.4f, %.4f, %.4f, %.4f)')
        :format(coords.x, coords.y, coords.z, heading)
    )
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    deleteAllProps()
end)

print('^2[Murder of 8 Props]^0 Time-gated evidence prop spawner loaded.')
