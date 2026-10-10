local oxTargetAvailable = false
local registeredOxZones = {}

CreateThread(function()
    Wait(2000)

    print('^5[M8 DEBUG] CLIENT CONFIG CHECK^0')
    print('Config exists:', Config ~= nil)
    print('Config.Scenes exists:', Config and Config.Scenes ~= nil)

    if Config and Config.Scenes then
        for sceneId, _ in pairs(Config.Scenes) do
            print('^2[M8 DEBUG] Scene:', sceneId, '^0')
        end
    end
end)

local function waitForScenes()
    local timeout = GetGameTimer() + 10000

    while not Config or type(Config.Scenes) ~= 'table' do
        Wait(100)

        if GetGameTimer() >= timeout then
            print('^1[Murder of 8] ERROR: Config.Scenes was not loaded. Check Scenes.lua and fxmanifest.lua.^0')
            return false
        end
    end

    return true
end

local function drawText3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end

    SetTextScale(0.31, 0.31)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextCentre(true)
    SetTextColour(255, 255, 255, 220)
    SetTextOutline()

    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function setupOxTarget()
    if Config.Interaction == 'native' then return false end
    if GetResourceState('ox_target') ~= 'started' then return false end

    oxTargetAvailable = true

    for sceneId, scene in pairs(Config.Scenes) do
        if scene.enabled then
            for evidenceId, sceneCoords in pairs(scene.evidence or {}) do
                local coords = M8_GetEvidenceWorldCoords
                    and M8_GetEvidenceWorldCoords(evidenceId, sceneCoords)
                    or sceneCoords

                local _, evidence = M8Story.GetEvidence(evidenceId)

                if evidence then
                    local zoneId = exports.ox_target:addSphereZone({
                        coords = coords,
                        radius = 1.25,
                        debug = false,
                        options = {
                            {
                                name = ('m8_%s_%s'):format(sceneId, evidenceId),
                                icon = 'fa-solid fa-magnifying-glass',
                                label = evidence.label,
                                distance = 1.8,
                                canInteract = function()
                                    local allowed = M8_CanUseEvidence(sceneId, evidenceId)
                                    return allowed
                                end,
                                onSelect = function()
                                    M8_ExamineEvidence(sceneId, evidenceId)
                                end
                            }
                        }
                    })

                    registeredOxZones[#registeredOxZones + 1] = zoneId
                end
            end
        end
    end

    return true
end

-- a soft pulsing glow on every piece of evidence you can examine right now (unfound, chapter open,
-- prerequisites met), so you know where to look and the next spots light up as you find things.
-- Night only, like the evidence itself. Works with both interaction modes.
CreateThread(function()
    Wait(500)

    if not waitForScenes() then
        return
    end

    local g = Config.EvidenceGlow
    if not (g and g.enabled) then return end
    local c = g.colour

    -- no glow until the real progress is in: found evidence must not flash for a second after a restart
    while not M8_HasProgress() do Wait(100) end

    while true do
        local sleep = 500
        local me = GetEntityCoords(PlayerPedId())
        local found = (M8_GetProgress() or {}).evidence or {}
        local pulse = 1.0 + g.pulse * math.sin(GetGameTimer() / 700.0) -- slow breathing, never out

        for sceneId, scene in pairs(Config.Scenes or {}) do
            if scene.enabled and M8_IsSceneAccessible(sceneId) then
                for evidenceId, sceneCoords in pairs(scene.evidence or {}) do
                    local coords = M8_GetEvidenceWorldCoords
                        and M8_GetEvidenceWorldCoords(evidenceId, sceneCoords)
                        or sceneCoords

                    if not found[evidenceId] and #(me - coords) <= Config.DrawDistance
                        and (M8_CanUseEvidence(sceneId, evidenceId)) then -- prerequisites met: examinable now
                        sleep = 0
                        DrawLightWithRange(coords.x, coords.y, coords.z + 0.4, c[1], c[2], c[3], g.range, g.intensity * pulse)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    Wait(500)

    if not waitForScenes() then
        return
    end

    if Config.Interaction == 'ox_target' then
        while GetResourceState('ox_target') ~= 'started' do
            Wait(1000)
        end
    end

    setupOxTarget()
    if oxTargetAvailable then return end

    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)

        for sceneId, scene in pairs(Config.Scenes or {}) do
            if scene.enabled and M8_IsSceneAccessible(sceneId) then
                for evidenceId, sceneCoords in pairs(scene.evidence or {}) do
                    local coords = M8_GetEvidenceWorldCoords
                        and M8_GetEvidenceWorldCoords(evidenceId, sceneCoords)
                        or sceneCoords

                    local distance = #(pCoords - coords)

                    if distance <= Config.DrawDistance then
                        sleep = 0

                        if distance <= Config.InteractionDistance then
                            local _, evidence = M8Story.GetEvidence(evidenceId)

                            if evidence then
                                local allowed, reason = M8_CanUseEvidence(sceneId, evidenceId)
                                local label = evidence.label

                                if not allowed and reason == 'prerequisites' then
                                    label = 'Examine'
                                end

                                drawText3D(coords + vector3(0.0, 0.0, 0.25), ('~g~[E]~s~ %s'):format(label))

                                if IsControlJustReleased(0, Config.InteractKey) then
                                    M8_ExamineEvidence(sceneId, evidenceId)
                                    Wait(350)
                                end
                            end
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if not oxTargetAvailable then return end

    for _, zoneId in ipairs(registeredOxZones) do
        exports.ox_target:removeZone(zoneId)
    end
end)
