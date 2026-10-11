local Progress = { chapter = 1, evidence = {}, completed = {} }
local casebookOpen = false
local silhouetteShown = false
local silhouettePed = nil
local lastSceneStates = {}
local lastDaytimeWarningAt = 0
local lastInvestigationActivityAt = 0

local function notify(message)
    SendNUIMessage({
        action = 'notify',
        message = message,
        duration = 4200
    })
end


function M8_ShowWarning(title, message, durationMs)
    SendNUIMessage({
        action = 'warning',
        title = title or 'THE TRAIL HAS GONE COLD',
        message = message or '',
        duration = durationMs or ((Config.Hunt and Config.Hunt.warningDurationMs) or 8500)
    })
end

local function hourInWindow(hour, startHour, endHour)
    if startHour < endHour then
        return hour >= startHour and hour < endHour
    end

    return hour >= startHour or hour < endHour
end

-- The investigation itself is available from 9:00 PM until 5:00 AM.
function M8_IsHuntTime()
    local hunt = Config.Hunt or { startHour = 21, endHour = 5 }
    return hourInWindow(GetClockHours(), hunt.startHour or 21, hunt.endHour or 5)
end

function M8_IsInSandy()
    local hunt = Config.Hunt or {}

    if hunt.requireSandy == false then
        return true
    end

    local center = hunt.sandyCenter or vector3(1700.0, 3750.0, 35.0)
    local radius = hunt.sandyRadius or 900.0
    local coords = GetEntityCoords(PlayerPedId())

    local dx = coords.x - center.x
    local dy = coords.y - center.y

    return ((dx * dx) + (dy * dy)) <= (radius * radius)
end

function M8_IsNearActiveScene(radius)
    if not Config or type(Config.Scenes) ~= 'table' then
        return false
    end

    local coords = GetEntityCoords(PlayerPedId())
    local checkRadius = radius or ((Config.Hunt and Config.Hunt.activeSceneRadius) or 85.0)

    for _, scene in pairs(Config.Scenes) do
        if scene.enabled and Progress.chapter >= (scene.chapter or 1) then
            for evidenceId, sceneCoords in pairs(scene.evidence or {}) do
                local evidenceCoords = M8_GetEvidenceWorldCoords
                    and M8_GetEvidenceWorldCoords(evidenceId, sceneCoords)
                    or sceneCoords

                if evidenceCoords
                    and (evidenceCoords.x ~= 0.0 or evidenceCoords.y ~= 0.0)
                    and #(coords - evidenceCoords) <= checkRadius
                then
                    return true
                end
            end
        end
    end

    return false
end

function M8_MarkInvestigationActivity()
    lastInvestigationActivityAt = GetGameTimer()
end

function M8_IsActivelyInvestigating()
    if not M8_IsHuntTime() then
        return false
    end

    if lastInvestigationActivityAt <= 0 then
        return false
    end

    local timeout = (Config.Hunt and Config.Hunt.activeSessionTimeoutMs) or (12 * 60 * 1000)

    if GetGameTimer() - lastInvestigationActivityAt > timeout then
        return false
    end

    if not M8_IsInSandy() then
        return false
    end

    return M8_IsNearActiveScene()
end

-- Scene-specific time restrictions are reserved for visual/world effects.
-- Example: the Burning House evidence can be investigated all night, while
-- its fire/silhouette can still remain restricted to 1:00-3:00 AM.
local function isSceneVisualTimeActive(scene)
    if not scene.timeRestricted then return true end

    return hourInWindow(
        GetClockHours(),
        scene.startHour or 0,
        scene.endHour or 24
    )
end

-- Evidence access. This deliberately ignores a scene's visual-only time window.
function M8_IsSceneAccessible(sceneId)
    local scene = Config.Scenes[sceneId]
    if not scene or not scene.enabled then return false end
    if Progress.chapter < (scene.chapter or 1) then return false end
    return M8_IsHuntTime()
end

-- World/scene activity. Burning House keeps its existing 1-3 AM effect window.
function M8_IsSceneActive(sceneId)
    local scene = Config.Scenes[sceneId]
    if not scene or not scene.enabled then return false end
    if Progress.chapter < (scene.chapter or 1) then return false end
    if not M8_IsHuntTime() then return false end
    return isSceneVisualTimeActive(scene)
end

function M8_GetProgress()
    return Progress
end

function M8_IsCasebookOpen()
    return casebookOpen
end

function M8_CanUseEvidence(sceneId, evidenceId)
    local scene = Config.Scenes[sceneId]
    if not scene or not scene.enabled then return false, 'disabled' end
    if Progress.chapter < (scene.chapter or 1) then return false, 'chapter_locked' end
    if not M8_IsHuntTime() then return false, 'daytime' end

    local _, evidence = M8Story.GetEvidence(evidenceId)
    if not evidence then return false, 'invalid' end
    if not M8Story.HasPrerequisites(Progress, evidence) then return false, 'prerequisites' end
    return true
end

exports('IsBurningHouseActive', function()
    return M8_IsSceneActive('burning_house')
end)

exports('IsSceneActive', function(sceneId)
    return M8_IsSceneActive(sceneId)
end)

local function sendCasebookState()
    SendNUIMessage({
        action = 'state',
        title = M8Story.Title,
        subtitle = M8Story.Subtitle,
        progress = Progress,
        chapters = M8Story.Chapters
    })
end

local function openCasebook(focusEvidence)
    if M8_IsHuntTime() and M8_IsInSandy() and M8_IsNearActiveScene() then
        M8_MarkInvestigationActivity()
    end

    casebookOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', focusEvidence = focusEvidence })
    sendCasebookState()
end

local function closeCasebook()
    if not casebookOpen then return end
    casebookOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('close', function(_, cb)
    closeCasebook()
    cb({ ok = true })
end)

RegisterCommand(Config.OpenCasebookCommand, function()
    openCasebook(nil)
end, false)

RegisterKeyMapping(Config.OpenCasebookCommand, 'Open the Murder of 8 casebook', 'keyboard', Config.OpenCasebookKey)

local progressReady = false

-- true once the server has sent this player's real progress (before that Progress is a blank case)
function M8_HasProgress()
    return progressReady
end

RegisterNetEvent('m8:client:progress', function(progress)
    Progress = progress or Progress
    progressReady = true
    if casebookOpen then sendCasebookState() end
end)

RegisterNetEvent('m8:client:notify', function(message)
    notify(message)
end)

local function blackout(ms)
    CreateThread(function()
        DoScreenFadeOut(450)
        while not IsScreenFadedOut() do Wait(0) end
        Wait(ms or 1500)
        DoScreenFadeIn(700)
    end)
end

-- where a piece of evidence sits, so a scare sound can come from the coffin / the dock / the cell
function M8_EvidenceCoords(evidenceId)
    for _, scene in pairs(Config.Scenes or {}) do
        local sceneCoords = scene.evidence and scene.evidence[evidenceId]

        if sceneCoords then
            if M8_GetEvidenceWorldCoords then
                return M8_GetEvidenceWorldCoords(evidenceId, sceneCoords)
            end

            return sceneCoords
        end
    end

    if M8_GetEvidenceWorldCoords then
        return M8_GetEvidenceWorldCoords(evidenceId, nil)
    end
end

-- positional layers first (Sandy Halloween bank at the evidence spot, GTA native audio), NUI otherwise
local function playScareSound(name, at)
    if M8NativeAudio and M8NativeAudio.Play and M8NativeAudio.Play(name, { at = at }) then return end
    SendNUIMessage({ action = 'sound', name = name, nativeBypass = true })
end

local function triggerScare(scare, at)
    if not scare then return end

    if scare == 'archive_blackout' then
        SetTimeout(1800, function()
            SendNUIMessage({ action = 'sound', name = 'bell' })
            blackout(1400)
        end)
    elseif scare == 'final_blackout' then
        SetTimeout(1200, function()
            SendNUIMessage({ action = 'sound', name = 'bell' })
            blackout(2200)
            SetTimeout(1900, function()
                SendNUIMessage({ action = 'sound', name = 'impact' })
            end)
        end)
    elseif scare == 'coffin_knocks' then
        SetTimeout(3500, function()
            playScareSound(scare, at)
        end)
    elseif scare == 'metal_clang' then
        SetTimeout(4200, function()
            playScareSound(scare, at)
        end)
    else
        SetTimeout(1200, function()
            playScareSound(scare, at)
        end)
    end
end

local function showChapterComplete(chapterIndex)
    chapterIndex = tonumber(chapterIndex)
    local chapter = chapterIndex and M8Story.Chapters[chapterIndex]
    if not chapter then return end

    SendNUIMessage({
        action = 'chapterComplete',
        chapter = chapterIndex,
        text = chapter.completionText or '',
        hint = chapter.nextHint or '',
        place = chapter.placeHint or ''
    })
end

RegisterNetEvent('m8:client:chapterComplete', function(chapterIndex)
    showChapterComplete(chapterIndex)
end)

RegisterNetEvent('m8:client:evidenceResult', function(success, result, evidenceId, completedNow, chapterIndex)
    if not success then
        if result == 'already_found' then
            notify(Config.Messages.alreadyFound)
        elseif result == 'chapter_locked' then
            notify(Config.Messages.chapterLocked)
        elseif result == 'prerequisites' then
            notify(Config.Messages.evidenceLocked)
        elseif result == 'daytime' then
            -- Daylight attempts get a normal notice only.
            -- The large "day is approaching" warning is reserved for 04:59.
            notify(Config.Messages.daytimeLocked)
        end
        return
    end

    -- The cinematic saves last_message automatically; keep that final beat clean.
    if evidenceId ~= 'last_message' then
        notify(Config.Messages.progressSaved)
    end

    M8_MarkInvestigationActivity()

    local _, evidence = M8Story.GetEvidence(evidenceId)

    TriggerEvent('m8:client:evidenceFound', evidenceId, chapterIndex)

    if evidenceId == 'final_bell' then
        -- The finale handles its own blackout, teleport, and off-camera reveal.
        TriggerEvent('m8:compound:finalBell')
    elseif evidence and evidence.scare then
        triggerScare(evidence.scare, M8_EvidenceCoords(evidenceId))
    end

    -- Opening the casebook here would cover the Chapter 8 cinematic.
    if evidenceId ~= 'final_bell' and evidenceId ~= 'last_message' then
        SetTimeout(250, function()
            openCasebook(evidenceId)
        end)
    end

    if completedNow and chapterIndex and evidenceId ~= 'last_message' then
        SetTimeout(900, function()
            showChapterComplete(chapterIndex)
        end)
    end
end)

function M8_ExamineEvidence(sceneId, evidenceId)
    local scene = Config.Scenes[sceneId]
    if not scene or not scene.enabled then notify(Config.Messages.sceneDisabled) return end
    if Progress.chapter < (scene.chapter or 1) then notify(Config.Messages.chapterLocked) return end
    if not M8_IsHuntTime() then
        notify(Config.Messages.daytimeLocked)
        return
    end

    -- Being at an actual clue and attempting to investigate is what starts/
    -- refreshes the active investigation session for this night.
    if M8_IsInSandy() and M8_IsNearActiveScene() then
        M8_MarkInvestigationActivity()
    end

    if Progress.evidence[evidenceId] then
        notify(Config.Messages.alreadyFound)
        openCasebook(evidenceId)
        return
    end

    local _, evidence = M8Story.GetEvidence(evidenceId)
    if evidence and not M8Story.HasPrerequisites(Progress, evidence) then
        notify(Config.Messages.evidenceLocked)
        return
    end

    TriggerServerEvent('m8:server:findEvidence', evidenceId)
end

local function loadModel(modelName)
    local hash = joaat(modelName)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        Wait(25)
        if GetGameTimer() >= timeout then return nil end
    end
    return hash
end

local function removeSilhouette()
    if silhouettePed and DoesEntityExist(silhouettePed) then DeleteEntity(silhouettePed) end
    silhouettePed = nil
end

local function showSilhouette()
    local scene = Config.Scenes.burning_house
    local cfg = scene and scene.silhouette
    if not cfg or not cfg.enabled or silhouetteShown then return end
    if GetClockHours() ~= 2 then return end

    local minute = GetClockMinutes()
    if minute < cfg.startMinute or minute > cfg.endMinute then return end

    local hash = loadModel(cfg.model)
    if not hash then return end

    silhouetteShown = true
    silhouettePed = CreatePed(4, hash, cfg.coords.x, cfg.coords.y, cfg.coords.z, cfg.coords.w, false, false)
    if silhouettePed and DoesEntityExist(silhouettePed) then
        FreezeEntityPosition(silhouettePed, true)
        SetEntityInvincible(silhouettePed, true)
        SetBlockingOfNonTemporaryEvents(silhouettePed, true)
        SetPedCanRagdoll(silhouettePed, false)
        SetEntityAlpha(silhouettePed, 180, false)
        SetTimeout(cfg.visibleForMs, removeSilhouette)
    end
    SetModelAsNoLongerNeeded(hash)
end

CreateThread(function()
    Wait(1500)

    while not Config or type(Config.Scenes) ~= 'table' do
        Wait(100)
    end

    TriggerServerEvent('m8:server:requestProgress')

    while true do
        for sceneId in pairs(Config.Scenes or {}) do
            local active = M8_IsSceneActive(sceneId)
            if lastSceneStates[sceneId] ~= active then
                lastSceneStates[sceneId] = active
                TriggerEvent(('m8:%s:active'):format(sceneId), active)
                TriggerEvent('m8:scene:active', sceneId, active)
                 Wait(1000)
            end
        end

        if M8_IsSceneActive('burning_house') then
            showSilhouette()
        else
            removeSilhouette()
            if GetClockHours() < 2 or GetClockHours() >= 3 then silhouetteShown = false end
        end

        Wait(1000)
    end
end)

RegisterCommand('m8complete', function(_, args)
    local chapter = tonumber(args[1])

    if not chapter or chapter < 1 or chapter > #M8Story.Chapters then
        notify(('Usage: /m8complete 1-%d'):format(#M8Story.Chapters))
        return
    end

    TriggerServerEvent('m8:server:completeChapter', math.floor(chapter))
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    removeSilhouette()
    if casebookOpen then SetNuiFocus(false, false) end
end)
