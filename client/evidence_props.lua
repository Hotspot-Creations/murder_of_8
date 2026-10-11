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

local function getSceneData(evidenceId)
    for sceneId, scene in pairs(Config.Scenes or {}) do
        if scene.evidence and scene.evidence[evidenceId] then
            return sceneId, scene
        end
    end

    return nil, nil
end

local function getSceneChapter(evidenceId)
    local _, scene = getSceneData(evidenceId)
    return scene and (scene.chapter or 1) or 1
end

local function usesExteriorAccessForEvidence(evidenceId)
    local sceneId = getSceneData(evidenceId)
    return sceneId
        and M8_UsesExteriorEvidenceAccess
        and M8_UsesExteriorEvidenceAccess(sceneId)
end

local function validCoords(coords)
    return coords
        and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0)
end

local function loadModel(modelName)
    local hash = joaat(modelName)

    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return nil
    end

    RequestModel(hash)

    local timeout = GetGameTimer() + 5000

    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(20)
    end

    if not HasModelLoaded(hash) then
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
    if usesExteriorAccessForEvidence(prop.id) then return end

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
                    local exteriorAccess = usesExteriorAccessForEvidence(prop.id) == true

                    if not exteriorAccess
                        and currentChapter >= requiredChapter
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
                            or exteriorAccess
                        )
                    then
                        deleteProp(spawnKey)
                    end
                end
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

-- Where a clue is examined: at its spawned physical prop when there is one (so the glow, the E prompt
-- and the sounds sit on the object the player actually sees), otherwise at its scene point.
function M8_GetEvidenceWorldCoords(evidenceId, sceneCoords)
    local entity = M8_GetSpawnedEvidenceProp and M8_GetSpawnedEvidenceProp(evidenceId)

    if entity and DoesEntityExist(entity) then
        return GetEntityCoords(entity)
    end

    return sceneCoords
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    deleteAllProps()
end)

