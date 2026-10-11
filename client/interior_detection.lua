-- Murder of 8 - custom interior detection
--
-- Detects whether each configured Sandy location currently has a GTA/FiveM
-- interior registered at its known inside coordinate.
--
-- Public helpers:
--   M8_GetInteriorState(sceneId)    -> 'interior' | 'exterior' | 'unknown'
--   M8_HasInterior(sceneId)         -> true | false | nil
--   M8_UsesExteriorFallback(sceneId)-> true/false
--   M8_GetInteriorId(sceneId)       -> interior id or 0
--
-- Event:
--   m8:interiorStateChanged(sceneId, state, interiorId)

local states = {}
local interiorIds = {}
local lastExteriorCheck = {}
local checking = {}

local function cfg()
    return Config.InteriorDetection or {}
end

local function validPoint(point)
    return point
        and (math.abs(point.x or 0.0) > 0.001
            or math.abs(point.y or 0.0) > 0.001
            or math.abs(point.z or 0.0) > 0.001)
end

local function setState(sceneId, state, interiorId)
    interiorId = tonumber(interiorId) or 0

    local changed = states[sceneId] ~= state
        or (interiorIds[sceneId] or 0) ~= interiorId

    states[sceneId] = state
    interiorIds[sceneId] = interiorId

    if changed then
        TriggerEvent('m8:interiorStateChanged', sceneId, state, interiorId)
    end
end

function M8_GetInteriorState(sceneId)
    return states[sceneId] or 'unknown'
end

function M8_HasInterior(sceneId)
    local state = M8_GetInteriorState(sceneId)

    if state == 'interior' then
        return true
    elseif state == 'exterior' then
        return false
    end

    return nil
end

function M8_UsesExteriorFallback(sceneId)
    return M8_GetInteriorState(sceneId) == 'exterior'
end

function M8_GetInteriorId(sceneId)
    return interiorIds[sceneId] or 0
end

local function classify(sceneId, point)
    if checking[sceneId] or not validPoint(point) then
        return
    end

    checking[sceneId] = true

    CreateThread(function()
        local settings = cfg()
        local confirmations = math.max(1, tonumber(settings.zeroConfirmations) or 6)
        local interval = math.max(100, tonumber(settings.confirmationIntervalMs) or 500)

        -- Ask the engine to stream collision/map data around the known inside point.
        RequestCollisionAtCoord(point.x, point.y, point.z)

        for _ = 1, confirmations do
            RequestCollisionAtCoord(point.x, point.y, point.z)

            local interiorId = GetInteriorAtCoords(point.x, point.y, point.z)

            if interiorId and interiorId ~= 0 then
                setState(sceneId, 'interior', interiorId)
                checking[sceneId] = nil
                return
            end

            Wait(interval)
        end

        -- We were close to the location, repeatedly requested its map data,
        -- and GTA/FiveM still reports no interior at the known inside point.
        setState(sceneId, 'exterior', 0)
        lastExteriorCheck[sceneId] = GetGameTimer()
        checking[sceneId] = nil
    end)
end

CreateThread(function()
    Wait(2000)

    while true do
        local settings = cfg()

        if settings.enabled == false then
            Wait(5000)
        else
            local points = settings.points or {}
            local playerCoords = GetEntityCoords(PlayerPedId())
            local checkDistance = tonumber(settings.checkDistance) or 80.0
            local exteriorRecheckMs = tonumber(settings.exteriorRecheckMs) or 10000

            for sceneId, point in pairs(points) do
                if validPoint(point) then
                    local distance = #(playerCoords - point)

                    if distance <= checkDistance then
                        local state = states[sceneId] or 'unknown'

                        -- Interior is definitive for this session.
                        -- Exterior is re-checked because a custom MLO may stream late.
                        if state == 'unknown'
                            or (
                                state == 'exterior'
                                and GetGameTimer() - (lastExteriorCheck[sceneId] or 0) >= exteriorRecheckMs
                            )
                        then
                            classify(sceneId, point)
                        end
                    end
                end
            end

            Wait(1000)
        end
    end
end)
