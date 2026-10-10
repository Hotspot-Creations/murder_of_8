-- Progress survives disconnects and restarts: one JSON record per player license in the server
-- KVP (no database). PlayerProgress is only a cache by server id; the KVP is the record.
M8Progress = M8Progress or {}

function M8Progress.Blank()
    return { chapter = 1, evidence = {}, completed = {} }
end

function M8Progress.Key(license)
    return 'm8_progress:' .. license
end

-- json turns the completed[chapter] keys into strings; back to numbers, missing/garbage -> fresh
function M8Progress.Normalize(p)
    local out = M8Progress.Blank()
    if type(p) ~= 'table' then return out end
    out.chapter = tonumber(p.chapter) or 1
    for id, v in pairs(type(p.evidence) == 'table' and p.evidence or {}) do
        if v then out.evidence[id] = true end
    end
    for k, v in pairs(type(p.completed) == 'table' and p.completed or {}) do
        local n = tonumber(k)
        if n and v then out.completed[n] = true end
    end
    return out
end

local PlayerProgress = {}

local function blankProgress()
    return M8Progress.Blank()
end

local function licenseOf(src)
    return GetPlayerIdentifierByType(src, 'license') or ('src:' .. src) -- no license: this session only
end

local function loadProgress(src)
    local raw = GetResourceKvpString(M8Progress.Key(licenseOf(src)))
    return M8Progress.Normalize(raw and json.decode(raw) or nil)
end

local function saveProgress(src)
    if PlayerProgress[src] then
        SetResourceKvp(M8Progress.Key(licenseOf(src)), json.encode(PlayerProgress[src]))
    end
end

local function getProgress(src)
    if not PlayerProgress[src] then PlayerProgress[src] = loadProgress(src) end
    return PlayerProgress[src]
end

-- every change ends with sendProgress, so this is also where it is saved
local function sendProgress(src)
    saveProgress(src)
    TriggerClientEvent('m8:client:progress', src, getProgress(src))
end

local function chapterComplete(progress, chapterIndex)
    local chapter = M8Story.Chapters[chapterIndex]
    if not chapter or not chapter.requiredEvidence then return false end
    for _, evidenceId in ipairs(chapter.requiredEvidence) do
        if not progress.evidence[evidenceId] then return false end
    end
    return true
end

RegisterNetEvent('m8:server:requestProgress', function()
    sendProgress(source)
end)

RegisterNetEvent('m8:server:findEvidence', function(evidenceId)
    local src = source
    if type(evidenceId) ~= 'string' then return end

    local chapterIndex, evidence = M8Story.GetEvidence(evidenceId)
    if not chapterIndex or not evidence then
        print(('[Murder of 8] %s attempted invalid evidence id: %s'):format(src, tostring(evidenceId)))
        return
    end

    local progress = getProgress(src)
    if chapterIndex > progress.chapter then
        TriggerClientEvent('m8:client:evidenceResult', src, false, 'chapter_locked', evidenceId, false, chapterIndex)
        return
    end
    if progress.evidence[evidenceId] then
        TriggerClientEvent('m8:client:evidenceResult', src, false, 'already_found', evidenceId, false, chapterIndex)
        return
    end
    if not M8Story.HasPrerequisites(progress, evidence) then
        TriggerClientEvent('m8:client:evidenceResult', src, false, 'prerequisites', evidenceId, false, chapterIndex)
        return
    end

    progress.evidence[evidenceId] = true
    local completedNow = false

    if chapterComplete(progress, chapterIndex) and not progress.completed[chapterIndex] then
        progress.completed[chapterIndex] = true
        completedNow = true
        if chapterIndex < #M8Story.Chapters then
            progress.chapter = math.max(progress.chapter, chapterIndex + 1)
        end
    end

    TriggerClientEvent('m8:client:evidenceResult', src, true, 'added', evidenceId, completedNow, chapterIndex)
    sendProgress(src)
end)

RegisterNetEvent('m8:server:debugReset', function()
    local src = source
    if not Config.Debug then return end
    PlayerProgress[src] = blankProgress()
    sendProgress(src)
    TriggerClientEvent('m8:client:notify', src, 'Progress reset.')
end)

RegisterNetEvent('m8:server:debugChapter', function(chapter)
    local src = source
    if not Config.Debug then return end
    chapter = tonumber(chapter)
    if not chapter then return end
    chapter = math.max(1, math.min(#M8Story.Chapters, math.floor(chapter)))
    getProgress(src).chapter = chapter
    sendProgress(src)
    TriggerClientEvent('m8:client:notify', src, ('Debug chapter set to %s.'):format(chapter))
end)

RegisterNetEvent('m8:server:debugEvidence', function(evidenceId)
    local src = source
    if not Config.Debug then return end
    local chapterIndex, evidence = M8Story.GetEvidence(evidenceId)
    if not chapterIndex or not evidence then
        TriggerClientEvent('m8:client:notify', src, 'Unknown evidence ID.')
        return
    end
    local progress = getProgress(src)
    progress.chapter = math.max(progress.chapter, chapterIndex)
    progress.evidence[evidenceId] = true
    if chapterComplete(progress, chapterIndex) then
        progress.completed[chapterIndex] = true
        if chapterIndex < #M8Story.Chapters then
            progress.chapter = math.max(progress.chapter, chapterIndex + 1)
        end
    end
    sendProgress(src)
    TriggerClientEvent('m8:client:notify', src, ('Debug evidence added: %s'):format(evidenceId))
end)

RegisterNetEvent('m8:server:debugCompleteChapter', function(chapterIndex)
    local src = source
    if not Config.Debug then return end
    chapterIndex = tonumber(chapterIndex)
    if not chapterIndex then return end
    chapterIndex = math.max(1, math.min(#M8Story.Chapters, math.floor(chapterIndex)))

    local progress = getProgress(src)
    local chapter = M8Story.Chapters[chapterIndex]
    for _, evidenceId in ipairs(chapter.requiredEvidence or {}) do
        progress.evidence[evidenceId] = true
    end
    progress.completed[chapterIndex] = true
    if chapterIndex < #M8Story.Chapters then
        progress.chapter = math.max(progress.chapter, chapterIndex + 1)
    else
        progress.chapter = 8
    end
    sendProgress(src)
    TriggerClientEvent('m8:client:notify', src, ('Debug completed chapter %s.'):format(chapterIndex))
end)

AddEventHandler('playerDropped', function()
    PlayerProgress[source] = nil
end)
