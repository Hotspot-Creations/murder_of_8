-- Murder of 8 - v1.5 Native Horror Audio
--
-- This script intentionally does NOT redistribute GTA audio.
-- It calls audio already present in the player's GTA V install.
--
-- Mapped examples:
--   whispers        -> GTA Online Ghost Hunt voices
--   jumpscare hit   -> Halloween Slasher spawn + GTA impact
--   breathing       -> FBI gas-mask breathing
--   footsteps       -> an invisible local ped actually walking/running
--   body drop       -> GTA body/bag landing + real ragdoll physics
--   door creak      -> GTA slow squeak
--   metal clang     -> crane/container + construction pipe impacts
--   phone           -> iFruit remote-ring audio
--   train horn      -> GTA's distant train-horn master

M8NativeAudio = M8NativeAudio or {}

local activeSoundIds = {}
local temporaryPeds = {}
local ghostBankRequested = false
local ghostBankAvailable = false

local function cfg()
    Config.NativeHorrorAudio = Config.NativeHorrorAudio or {}
    return Config.NativeHorrorAudio
end

local function releaseSound(id)
    if not id or id == -1 then return end

    if activeSoundIds[id] then
        StopSound(id)
        ReleaseSoundId(id)
        activeSoundIds[id] = nil
    end
end

local function trackedSoundId()
    local id = GetSoundId()
    activeSoundIds[id] = true
    return id
end

local function stopLater(id, ms)
    SetTimeout(ms or 2500, function()
        releaseSound(id)
    end)
end

local function cleanupPed(ped)
    if ped and DoesEntityExist(ped) then
        DeleteEntity(ped)
    end

    temporaryPeds[ped] = nil
end

local function loadModel(modelName)
    local hash = joaat(modelName)

    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return nil
    end

    RequestModel(hash)

    local timeout = GetGameTimer() + 4500
    while not HasModelLoaded(hash) do
        Wait(15)
        if GetGameTimer() >= timeout then
            return nil
        end
    end

    return hash
end

local function playerBasis()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    -- Camera yaw is more useful for scares than ped heading.
    local rot = GetGameplayCamRot(2)
    local yaw = math.rad(rot.z)

    local forward = vector3(-math.sin(yaw), math.cos(yaw), 0.0)
    local right = vector3(forward.y, -forward.x, 0.0)

    return ped, coords, forward, right
end

local function relativeCoords(forwardDistance, sideDistance, zOffset)
    local _, p, forward, right = playerBasis()

    return p
        + (forward * (forwardDistance or 0.0))
        + (right * (sideDistance or 0.0))
        + vector3(0.0, 0.0, zOffset or 0.0)
end

local function panToSide(pan, maxDistance)
    pan = tonumber(pan) or 0.0
    maxDistance = maxDistance or 2.5
    return math.max(-1.0, math.min(1.0, pan)) * maxDistance
end

local function playAt(name, soundSet, coords, range)
    if not coords then return false end

    PlaySoundFromCoord(
        -1,
        name,
        coords.x,
        coords.y,
        coords.z,
        soundSet or 0,
        false,
        range or cfg().defaultRange or 22,
        false
    )

    return true
end

local function playOnEntity(name, soundSet, entity)
    if not entity or not DoesEntityExist(entity) then return false end

    PlaySoundFromEntity(
        -1,
        name,
        entity,
        soundSet or 0,
        false,
        0
    )

    return true
end

local function playLoopOnEntity(name, soundSet, entity, duration)
    if not entity or not DoesEntityExist(entity) then return false end

    local id = trackedSoundId()

    PlaySoundFromEntity(
        id,
        name,
        entity,
        soundSet or 0,
        false,
        0
    )

    stopLater(id, duration or 2200)
    return true
end

local function ensureGhostBank()
    if ghostBankRequested then
        return ghostBankAvailable
    end

    ghostBankRequested = true

    if not cfg().useGhostAudio then
        ghostBankAvailable = false
        return false
    end

    ghostBankAvailable = RequestScriptAudioBank(
        cfg().ghostBank or 'DLC_MP2023_1/DLC_MP2023_1_GH',
        false
    ) == true
    return ghostBankAvailable
end

local function ghostVoice(pan)
    local side = panToSide(pan, 2.2)
    local pos = relativeCoords(-1.35, side, 0.65)

    if ensureGhostBank() then
        local sound = math.random(1, 2) == 1 and 'Female_Ghost' or 'Male_Ghost'
        return playAt(sound, 'Ghost_Hunt_Sounds', pos, 14)
    end

    -- Old-build fallback: a real GTA scream rather than synthetic noise.
    return playAt('Ejector_Scream', 'CAR_STEAL_3_AGENT', pos, 18)
end

local function slasherSpawn(entity)
    entity = entity or PlayerPedId()

    return playOnEntity(
        'INGAME_SPAWN',
        'DLC_TUNER_HALLOWEEN_SLASHER_SOUNDSET',
        entity
    )
end

local function slasherDespawn(entity)
    entity = entity or PlayerPedId()

    return playOnEntity(
        'DESPAWN_INGAME',
        'DLC_TUNER_HALLOWEEN_SLASHER_SOUNDSET',
        entity
    )
end

local function slasherLoop(entity, duration)
    entity = entity or PlayerPedId()

    return playLoopOnEntity(
        'CHARACTER_LOOP',
        'DLC_TUNER_HALLOWEEN_SLASHER_SOUNDSET',
        entity,
        duration or 1800
    )
end

local function invisibleFootsteps(running, pan)
    CreateThread(function()
        local player = PlayerPedId()
        local model = cfg().footstepPedModel or 'a_m_m_skidrow_01'
        local hash = loadModel(model)

        if not hash then
            return
        end

        local side = panToSide(pan, 2.8)
        local start = relativeCoords(running and -8.0 or -5.0, side, 0.0)
        local finish = relativeCoords(running and 4.0 or 1.5, -side * 0.25, 0.0)

        local ped = CreatePed(
            4,
            hash,
            start.x,
            start.y,
            start.z,
            GetEntityHeading(player),
            false,
            false
        )

        SetModelAsNoLongerNeeded(hash)

        if not ped or not DoesEntityExist(ped) then
            return
        end

        temporaryPeds[ped] = true

        -- Keep the ped technically visible but alpha 0; this preserves normal
        -- movement/foley behavior more reliably than SetEntityVisible(false).
        SetEntityAlpha(ped, 0, false)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedCanRagdoll(ped, false)
        SetEntityCollision(ped, false, false)
        SetPedFleeAttributes(ped, 0, false)

        local speed = running and 5.3 or 1.45

        TaskGoStraightToCoord(
            ped,
            finish.x,
            finish.y,
            finish.z,
            speed,
            running and 3000 or 5000,
            GetEntityHeading(player),
            0.0
        )

        local sprintId = nil

        if running then
            sprintId = trackedSoundId()

            PlaySoundFromEntity(
                sprintId,
                'BEAST_SPRINT_LOOP',
                ped,
                'DLC_AR_BEAST_SOUNDSET',
                false,
                0
            )
        end

        Wait(running and 2300 or 3900)

        if sprintId then
            releaseSound(sprintId)
        end

        cleanupPed(ped)
    end)

    return true
end

local function repeatedCrateKnocks(pattern, pan)
    local side = panToSide(pan, 2.0)
    local pos = relativeCoords(-2.0, side, 0.15)

    CreateThread(function()
        for _, delay in ipairs(pattern) do
            Wait(delay)
            playAt('Crate_Land', 'FBI_05_SOUNDS', pos, 16)
        end
    end)

    return true
end

function M8NativeAudio.Play(name, opts)
    -- Sandy Halloween bank first: real 3D sounds from the figure / the world (client/halloween_audio.lua)
    if M8HalloweenAudio and M8HalloweenAudio.Play(name, opts) then return true end

    if cfg().enabled == false then return false end

    opts = opts or {}
    local pan = tonumber(opts.pan) or 0.0
    local side = panToSide(pan, 3.0)

    if name == 'bell' then
        return playAt('Bell_01', 'ALARMS_SOUNDSET', relativeCoords(-2.5, side, 0.5), 24)

    elseif name == 'archive_bell' then
        return playAt('RING', 'CHURCH_BELL_SOUNDSET', relativeCoords(-7.0, side, 1.0), 40)

    elseif name == 'whisper' then
        return ghostVoice(pan)

    elseif name == 'distant_scream' then
        local useEjector = math.random(1, 2) == 1
        local soundName = useEjector and 'Ejector_Scream' or 'MICHAEL_LONG_SCREAM'
        local soundSet = useEjector and 'CAR_STEAL_3_AGENT' or 'FAMILY_5_SOUNDS'

        return playAt(
            soundName,
            soundSet,
            relativeCoords(-13.0, side * 2.3, 0.5),
            cfg().distantRange or 75
        )

    elseif name == 'breath' then
        -- FBI gas-mask breathing is real recorded breathing tied to an entity.
        return playLoopOnEntity('Gasmask', 'FBI_05_SOUNDS', PlayerPedId(), 1700)

    elseif name == 'footsteps' then
        return invisibleFootsteps(false, pan)

    elseif name == 'footsteps_run' then
        return invisibleFootsteps(true, pan)

    elseif name == 'coffin_knocks' then
        -- Three distinct physical crate/body impacts.
        return repeatedCrateKnocks({ 0, 520, 610 }, pan)

    elseif name == 'dock_knocks' then
        -- 3 / 3 / 2 pattern = 8.
        return repeatedCrateKnocks({
            0, 320, 320,
            780,
            320, 320,
            780,
            320
        }, pan)

    elseif name == 'metal_clang' or name == 'cell_slam' then
        local pos = relativeCoords(-2.2, side, 0.4)

        playAt('Container_Impact_Land', 'CRANE_SOUNDS', pos, 26)

        SetTimeout(95, function()
            playAt('PIPES_LAND', 'CONSTRUCTION_ACCIDENT_1_SOUNDS', pos, 28)
        end)

        return true

    elseif name == 'impact' then
        local pos = relativeCoords(0.4, side * 0.25, 0.2)
        playAt('Container_Impact', 'CRANE_SOUNDS', pos, 24)
        PlaySoundFrontend(-1, 'MP_Impact', 'WastedSounds', true)
        return true

    elseif name == 'body_drop' then
        local pos = relativeCoords(2.0, side * 0.4, 0.0)
        playAt('FBI_01_DMW_GARBAGE_LAND', 'FBI_01_DMW_02_SOUNDS', pos, 24)
        return true

    elseif name == 'chain_drag' then
        return playAt(
            'CAR_STEAL_4_RAMP_SCRAPE',
            'CAR_STEAL_4_SOUNDSET',
            relativeCoords(-3.5, side, 0.0),
            26
        )

    elseif name == 'door_creak' then
        return playAt(
            'SLOW_SQUEAK',
            'THE_FERRIS_WHALE_SOUNDSET',
            relativeCoords(-2.8, side, 0.65),
            20
        )

    elseif name == 'phone_ring' then
        PlaySoundFrontend(
            -1,
            'Dial_and_Remote_Ring',
            'Phone_SoundSet_Default',
            true
        )
        return true

    elseif name == 'train_horn' then
        -- A genuine GTA distant train-horn master. AudioRef 0 is intentional.
        return playAt(
            'MARTIN1_DISTANT_TRAIN_HORNS_MASTER',
            0,
            relativeCoords(-35.0, side * 5.0, 1.5),
            120
        )

    elseif name == 'jump_sting' then
        slasherSpawn(PlayerPedId())

        SetTimeout(55, function()
            PlaySoundFrontend(-1, 'MP_Impact', 'WastedSounds', true)
        end)

        return true

    elseif name == 'slasher_spawn' then
        return slasherSpawn(opts.entity)

    elseif name == 'slasher_despawn' then
        return slasherDespawn(opts.entity)

    elseif name == 'slasher_loop' then
        return slasherLoop(opts.entity, opts.duration)

    elseif name == 'reverse_sting' then
        return playOnEntity(
            'INGAME_SPAWN',
            'FREEMODE_MIRROR_SLASH_SOUNDS',
            PlayerPedId()
        )
    end

    -- Intentionally stay NUI:
    -- static, heartbeat, sub_rumble, ambience and other abstract layers.
    return false
end

-- Existing main.lua/story scares reach JS first. JS forwards literal sounds here.
RegisterNUICallback('nativeSound', function(data, cb)
    local ok = M8NativeAudio.Play(data and data.name or '', {
        pan = data and data.pan,
        volume = data and data.volume,
        rate = data and data.rate
    })

    cb({ ok = ok == true })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for id in pairs(activeSoundIds) do
        releaseSound(id)
    end

    for ped in pairs(temporaryPeds) do
        cleanupPed(ped)
    end

    -- Releases the currently requested script bank.
    ReleaseScriptAudioBank()
end)
