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


-- Admin-only chapter completion shortcut used by /m8complete on the client.
-- Permission: add_ace group.admin command.m8complete allow
RegisterNetEvent('m8:server:completeChapter', function(chapterIndex)
    local src = source

    if src <= 0 or not IsPlayerAceAllowed(src, 'command.m8complete') then
        TriggerClientEvent('m8:client:notify', src, 'You do not have permission to use /m8complete.')
        return
    end

    chapterIndex = tonumber(chapterIndex)
    if not chapterIndex then return end

    chapterIndex = math.floor(chapterIndex)
    if chapterIndex < 1 or chapterIndex > #M8Story.Chapters then return end

    local progress = getProgress(src)
    local chapter = M8Story.Chapters[chapterIndex]
    if not chapter then return end

    for _, evidenceId in ipairs(chapter.requiredEvidence or {}) do
        progress.evidence[evidenceId] = true
    end

    progress.completed[chapterIndex] = true

    if chapterIndex < #M8Story.Chapters then
        progress.chapter = math.max(progress.chapter, chapterIndex + 1)
    else
        progress.chapter = #M8Story.Chapters
    end

    sendProgress(src)
    TriggerClientEvent('m8:client:chapterComplete', src, chapterIndex)
    TriggerClientEvent('m8:client:notify', src, ('Chapter %d marked complete.'):format(chapterIndex))
end)

-- Admin reset from the server console / txAdmin: m8reset <serverId>. Restricted (console, or the
-- command.m8reset ace). Wipes that player's saved case so they can replay or get unstuck.
RegisterCommand('m8reset', function(source, args)
    local target = tonumber(args[1])
    if not target or not GetPlayerName(target) then
        print('[Murder of 8] usage: m8reset <serverId>  (the player must be online)')
        return
    end
    PlayerProgress[target] = blankProgress()
    sendProgress(target)
    TriggerClientEvent('m8:client:notify', target, 'Your case has been reset.')
    print(('[Murder of 8] progress reset for %s (%d)'):format(GetPlayerName(target), target))
end, true)

AddEventHandler('playerDropped', function()
    PlayerProgress[source] = nil
end)
