local spawnedVictim = nil
local spawnedChair = nil
local spawnedBindings = {}

local function loadModel(model)
    local modelHash = joaat(model)

    if not IsModelInCdimage(modelHash) or not IsModelValid(modelHash) then
        print(("[TiedVictim] Invalid model: %s"):format(model))
        return nil
    end

    RequestModel(modelHash)

    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(modelHash) do
        if GetGameTimer() > timeout then
            print(("[TiedVictim] Timed out loading model: %s"):format(model))
            return nil
        end

        Wait(0)
    end

    return modelHash
end

local function loadAnimDict(dict)
    RequestAnimDict(dict)

    local timeout = GetGameTimer() + 10000
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > timeout then
            print(("[TiedVictim] Timed out loading animation dictionary: %s"):format(dict))
            return false
        end

        Wait(0)
    end

    return true
end

local function cleanupTiedVictim()
    if spawnedVictim and DoesEntityExist(spawnedVictim) then
        DeleteEntity(spawnedVictim)
    end

    if spawnedChair and DoesEntityExist(spawnedChair) then
        DeleteEntity(spawnedChair)
    end

    for _, entity in ipairs(spawnedBindings) do
        if entity and DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end

    spawnedVictim = nil
    spawnedChair = nil
    spawnedBindings = {}

    print("[TiedVictim] Scene cleaned up.")
end

local function SpawnTiedVictim(coords, heading)
    -- Clean up the previous test scene first.
    cleanupTiedVictim()

    local pedModel = loadModel("a_m_m_hillbilly_01")
    local chairModel = loadModel("prop_torture_ch_01")
    local bindingModel = loadModel("p_arm_bind_cut_s")

    if not pedModel or not chairModel or not bindingModel then
        print("[TiedVictim] Failed to load one or more required models.")
        return
    end

    local animDict = "missfbi3_wrench"

    if not loadAnimDict(animDict) then
        return
    end

    -- Victim ped
    local ped = CreatePed(
        4,
        pedModel,
        coords.x,
        coords.y,
        coords.z,
        heading,
        true,
        true
    )

    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetEntityInvincible(ped, true)

    -- Torture chair
    local chair = CreateObject(
        chairModel,
        coords.x,
        coords.y,
        coords.z,
        true,
        true,
        false
    )

    SetEntityAsMissionEntity(chair, true, true)

    -- Wrist restraint props
    local leftBind = CreateObject(
        bindingModel,
        coords.x,
        coords.y,
        coords.z,
        true,
        true,
        false
    )

    local rightBind = CreateObject(
        bindingModel,
        coords.x,
        coords.y,
        coords.z,
        true,
        true,
        false
    )

    SetEntityAsMissionEntity(leftBind, true, true)
    SetEntityAsMissionEntity(rightBind, true, true)

    local sceneHeading = heading + 180.0

    if sceneHeading >= 360.0 then
        sceneHeading = sceneHeading - 360.0
    end

    local scene = NetworkCreateSynchronisedScene(
        coords.x,
        coords.y,
        coords.z,
        0.0,
        0.0,
        sceneHeading,
        2,
        true,
        true,
        1.0,
        0.0,
        1.0
    )

    NetworkAddPedToSynchronisedScene(
        ped,
        scene,
        animDict,
        "wrench_idle_victim",
        8.0,
        -8.0,
        -1,
        1,
        0.0,
        0
    )

    NetworkAddEntityToSynchronisedScene(
        chair,
        scene,
        animDict,
        "wrench_idle_chair",
        8.0,
        -8.0,
        1
    )

    NetworkAddEntityToSynchronisedScene(
        leftBind,
        scene,
        animDict,
        "wrench_idle_hand_l",
        8.0,
        -8.0,
        1
    )

    NetworkAddEntityToSynchronisedScene(
        rightBind,
        scene,
        animDict,
        "wrench_idle_hand_r",
        8.0,
        -8.0,
        1
    )

    NetworkStartSynchronisedScene(scene)

    spawnedVictim = ped
    spawnedChair = chair
    spawnedBindings = {
        leftBind,
        rightBind
    }

    SetModelAsNoLongerNeeded(pedModel)
    SetModelAsNoLongerNeeded(chairModel)
    SetModelAsNoLongerNeeded(bindingModel)

    print("[TiedVictim] Tied victim scene spawned.")
end

-- Spawns the tied victim about 3 meters in front of you.
RegisterCommand("tiedvictim", function()
    local playerPed = PlayerPedId()

    local coords = GetOffsetFromEntityInWorldCoords(
        playerPed,
        0.0,
        3.0,
        -1.0
    )

    local heading = GetEntityHeading(playerPed)

    SpawnTiedVictim(coords, heading)
end, false)

-- Removes the test scene.
RegisterCommand("removetiedvictim", function()
    cleanupTiedVictim()
end, false)

-- Automatically cleans up spawned entities if the resource stops/restarts.
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    cleanupTiedVictim()
end)
