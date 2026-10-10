local spawnedChairEvidence = {}

local function loadModel(modelName)
    local hash = joaat(modelName)

    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        print(
            ('^1[Murder of 8 Chairs]^0 Invalid model: %s')
                :format(modelName)
        )

        return nil
    end

    RequestModel(hash)

    local timeout = GetGameTimer() + 5000

    while not HasModelLoaded(hash) do
        Wait(10)

        if GetGameTimer() >= timeout then
            print(
                ('^1[Murder of 8 Chairs]^0 Failed loading: %s')
                    :format(modelName)
            )

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
        SetEntityAsMissionEntity(
            data.object,
            true,
            true
        )

        DeleteEntity(data.object)
    end

    spawnedChairEvidence[id] = nil
end

local function spawnChairEvidence(data)
    if not data then return end
    if not data.id then return end
    if not data.chair then return end
    if not data.model then return end

    if spawnedChairEvidence[data.id] then
        return
    end

    if not M8_GetSpawnedEvidenceProp then
        print(
            '^1[Murder of 8 Chairs]^0 M8_GetSpawnedEvidenceProp is missing.'
        )
        return
    end

    local chair = M8_GetSpawnedEvidenceProp(
        data.chair
    )

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

    SetEntityAsMissionEntity(
        object,
        true,
        true
    )

    SetEntityCollision(
        object,
        false,
        false
    )

    local offset = data.offset
        or vector3(
            0.0,
            0.0,
            0.50
        )

    local rotation = data.rotation
        or vector3(
            0.0,
            0.0,
            0.0
        )

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

    if Config.Debug then
        print(
            ('^2[Murder of 8 Chairs]^0 Attached %s to %s')
                :format(
                    data.id,
                    data.chair
                )
        )
    end
end

CreateThread(function()
    Wait(2000)

    while true do
        for _, data in ipairs(
            Config.CompoundChairEvidence or {}
        ) do

            local existing =
                spawnedChairEvidence[data.id]

            local chair =
                M8_GetSpawnedEvidenceProp
                and M8_GetSpawnedEvidenceProp(
                    data.chair
                )

            if chair
                and DoesEntityExist(chair)
            then

                if not existing then
                    spawnChairEvidence(data)

                elseif existing.chair ~= chair then
                    -- Chair was streamed out/in again.
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

RegisterCommand(
    'm8chairprops',
    function()
        if not Config.Debug then return end

        for _, data in ipairs(
            Config.CompoundChairEvidence or {}
        ) do
            deleteChairEvidence(data.id)
        end

        Wait(100)

        for _, data in ipairs(
            Config.CompoundChairEvidence or {}
        ) do
            spawnChairEvidence(data)
        end

        TriggerEvent(
            'm8:client:notify',
            'Chair evidence props reloaded.'
        )
    end,
    false
)

RegisterCommand(
    'm8chairpropstatus',
    function()
        if not Config.Debug then return end

        for _, data in ipairs(
            Config.CompoundChairEvidence or {}
        ) do

            local chair =
                M8_GetSpawnedEvidenceProp
                and M8_GetSpawnedEvidenceProp(
                    data.chair
                )

            local prop =
                spawnedChairEvidence[data.id]

            print(
                ('[M8] %s -> %s | chair=%s | prop=%s')
                    :format(
                        data.id,
                        data.chair,
                        tostring(
                            chair
                            and DoesEntityExist(chair)
                        ),
                        tostring(
                            prop
                            and prop.object
                            and DoesEntityExist(
                                prop.object
                            )
                        )
                    )
            )
        end
    end,
    false
)

AddEventHandler(
    'onResourceStop',
    function(resourceName)

        if resourceName
            ~= GetCurrentResourceName()
        then
            return
        end

        for id in pairs(
            spawnedChairEvidence
        ) do
            deleteChairEvidence(id)
        end
    end
)

print(
    '^2[Murder of 8 Chairs]^0 chair_evidence.lua loaded.'
)