-- Murder of 8 - Compound chair evidence
-- Attaches configured Chapter 8 evidence props to chair_1 through chair_7.

local spawnedChairEvidence = {}

local function loadModel(modelName)
    local hash = joaat(modelName)

    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return nil
    end

    RequestModel(hash)

    local timeout = GetGameTimer() + 5000

    while not HasModelLoaded(hash) do
        Wait(10)

        if GetGameTimer() >= timeout then
            return nil
        end
    end

    return hash
end

local function deleteChairEvidence(id)
    local data = spawnedChairEvidence[id]

    if not data then
        return
    end

    if data.object and DoesEntityExist(data.object) then
        SetEntityAsMissionEntity(data.object, true, true)
        DeleteEntity(data.object)
    end

    spawnedChairEvidence[id] = nil
end

local function spawnChairEvidence(data)
    if not data or not data.id or not data.chair or not data.model then
        return
    end

    if spawnedChairEvidence[data.id] then
        return
    end

    if not M8_GetSpawnedEvidenceProp then
        return
    end

    local chair = M8_GetSpawnedEvidenceProp(data.chair)

    if not chair or not DoesEntityExist(chair) then
        return
    end

    local hash = loadModel(data.model)

    if not hash then
        return
    end

    local chairCoords = GetEntityCoords(chair)

    local object = CreateObjectNoOffset(
        hash,
        chairCoords.x,
        chairCoords.y,
        chairCoords.z,
        false,
        false,
        false
    )

    if not object or not DoesEntityExist(object) then
        SetModelAsNoLongerNeeded(hash)
        return
    end

    SetEntityAsMissionEntity(object, true, true)
    SetEntityCollision(object, false, false)

    local offset = data.offset or vector3(0.0, 0.0, 0.50)
    local rotation = data.rotation or vector3(0.0, 0.0, 0.0)

    AttachEntityToEntity(
        object,
        chair,
        0,
        offset.x,
        offset.y,
        offset.z,
        rotation.x,
        rotation.y,
        rotation.z,
        false,
        false,
        false,
        false,
        2,
        true
    )

    spawnedChairEvidence[data.id] = {
        object = object,
        chair = chair
    }

    SetModelAsNoLongerNeeded(hash)
end

CreateThread(function()
    Wait(2000)

    while true do
        for _, data in ipairs(Config.CompoundChairEvidence or {}) do
            local existing = spawnedChairEvidence[data.id]

            local chair =
                M8_GetSpawnedEvidenceProp
                and M8_GetSpawnedEvidenceProp(data.chair)

            if chair and DoesEntityExist(chair) then
                if not existing then
                    spawnChairEvidence(data)
                elseif existing.chair ~= chair then
                    deleteChairEvidence(data.id)
                    spawnChairEvidence(data)
                end
            elseif existing then
                deleteChairEvidence(data.id)
            end
        end

        Wait(750)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    local ids = {}

    for id in pairs(spawnedChairEvidence) do
        ids[#ids + 1] = id
    end

    for _, id in ipairs(ids) do
        deleteChairEvidence(id)
    end
end)
