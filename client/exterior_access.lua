-- Murder of 8 - exterior-only evidence access
--
-- When the custom Sandy interior detector reports that a configured location has
-- no interior, the normal physical evidence inside that building is disabled and
-- this script exposes ONE investigation point outside instead.
--
-- Each interaction documents the next currently-valid evidence ID from the same
-- chapter. The server, casebook, prerequisites and chapter progression remain
-- unchanged; only the physical way the player reaches the evidence changes.

local oxTargetAvailable = false
local oxZones = {}
local busy = false

local function settings()
    return Config.ExteriorAccess or {}
end

local function validCoords(coords)
    return coords
        and (math.abs(coords.x or 0.0) > 0.001
            or math.abs(coords.y or 0.0) > 0.001
            or math.abs(coords.z or 0.0) > 0.001)
end

function M8_GetExteriorAccessConfig(sceneId)
    local cfg = settings()
    return cfg.locations and cfg.locations[sceneId] or nil
end

function M8_GetExteriorAccessCoords(sceneId)
    local location = M8_GetExteriorAccessConfig(sceneId)
    if location and validCoords(location.coords) then
        return location.coords
    end
    return nil
end

-- True only once BOTH conditions are met:
--   1. the interior detector has positively classified this location as exterior-only
--   2. a reachable exterior interaction point has been configured
--
-- This prevents an unfinished 0,0,0 config from disabling the existing clue layout.
function M8_UsesExteriorEvidenceAccess(sceneId)
    local cfg = settings()
    if cfg.enabled == false then return false end

    local coords = M8_GetExteriorAccessCoords(sceneId)
    if not coords then return false end

    return M8_UsesExteriorFallback
        and M8_UsesExteriorFallback(sceneId) == true
end

local function getChapterForScene(sceneId)
    local scene = Config.Scenes and Config.Scenes[sceneId]
    if not scene then return nil, nil end

    local chapterIndex = tonumber(scene.chapter)
    local chapter = chapterIndex and M8Story.Chapters[chapterIndex] or nil
    return chapter, scene
end

-- Returns the next evidence item that can legitimately be documented right now.
-- requiredEvidence is ordered in story.lua, so exterior mode follows the authored
-- chapter order instead of whichever Lua table key happens to be iterated first.
function M8_GetNextExteriorEvidence(sceneId)
    if not M8_UsesExteriorEvidenceAccess(sceneId) then return nil end
    if not M8_HasProgress or not M8_HasProgress() then return nil end

    local chapter, scene = getChapterForScene(sceneId)
    if not chapter or not scene then return nil end

    local progress = M8_GetProgress and M8_GetProgress() or nil
    local found = progress and progress.evidence or {}
    local auto = settings().automaticEvidence or {}

    for _, evidenceId in ipairs(chapter.requiredEvidence or {}) do
        if not auto[evidenceId]
            and scene.evidence
            and scene.evidence[evidenceId]
            and not found[evidenceId]
        then
            local allowed = M8_CanUseEvidence
                and M8_CanUseEvidence(sceneId, evidenceId)

            if allowed then
                return evidenceId
            end
        end
    end

    return nil
end

local function investigate(sceneId)
    if busy then return end

    local evidenceId = M8_GetNextExteriorEvidence(sceneId)
    if not evidenceId then return end

    busy = true

    if M8_MarkInvestigationActivity then
        M8_MarkInvestigationActivity()
    end

    -- Same function the physical clue uses. The server remains authoritative and
    -- the normal evidenceResult handler opens the same casebook entry afterward.
    M8_ExamineEvidence(sceneId, evidenceId)

    SetTimeout(650, function()
        busy = false
    end)
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

    local cfg = settings()

    for sceneId, location in pairs(cfg.locations or {}) do
        if validCoords(location.coords) then
            local id = exports.ox_target:addSphereZone({
                coords = location.coords,
                radius = location.radius or cfg.targetRadius or 1.35,
                debug = false,
                options = {
                    {
                        name = ('m8_exterior_%s'):format(sceneId),
                        icon = 'fa-solid fa-magnifying-glass',
                        label = location.label or 'Investigate',
                        distance = location.distance or cfg.interactionDistance or 2.75,
                        canInteract = function()
                            return not busy
                                and M8_UsesExteriorEvidenceAccess(sceneId)
                                and M8_GetNextExteriorEvidence(sceneId) ~= nil
                        end,
                        onSelect = function()
                            investigate(sceneId)
                        end
                    }
                }
            })

            oxZones[#oxZones + 1] = id
        end
    end

    return true
end

CreateThread(function()
    Wait(1000)

    if Config.Interaction == 'ox_target' then
        while GetResourceState('ox_target') ~= 'started' do
            Wait(1000)
        end
    end

    setupOxTarget()
    if oxTargetAvailable then return end

    while true do
        local sleep = 1000

        if M8_HasProgress and M8_HasProgress() then
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)
            local cfg = settings()

            for sceneId, location in pairs(cfg.locations or {}) do
                local coords = location.coords

                if validCoords(coords)
                    and M8_UsesExteriorEvidenceAccess(sceneId)
                    and M8_GetNextExteriorEvidence(sceneId)
                then
                    local distance = #(playerCoords - coords)

                    if distance <= (location.drawDistance or cfg.drawDistance or 18.0) then
                        sleep = 0

                        if distance <= (location.distance or cfg.interactionDistance or 2.75) then
                            drawText3D(
                                coords + vector3(0.0, 0.0, 0.25),
                                ('~g~[E]~s~ %s'):format(location.label or 'Investigate')
                            )

                            if not busy and IsControlJustReleased(0, Config.InteractKey) then
                                investigate(sceneId)
                                Wait(250)
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

    for _, id in ipairs(oxZones) do
        exports.ox_target:removeZone(id)
    end
end)
