local churchInterior = nil

-- Inside the nave, halfway between the entrance doors (1784, 3902) and the exit door (1805, 3920).
-- (1767, 3892 was 16 m outside the south-west wall: GetInteriorAtCoords returned 0 there.)
local CHURCH_COORDS = vector3(
    1795.0,
    3910.5,
    35.5
)

local FUNERAL_SET = 'church_funeral'
local OTHER_SETS = { 'church_married', 'church_service' }
local restoreSets = nil -- whatever was active before the funeral; put back in daylight / on stop

local function getChurchInterior()
    if churchInterior and churchInterior ~= 0 then
        return churchInterior
    end

    churchInterior = GetInteriorAtCoords(
        CHURCH_COORDS.x,
        CHURCH_COORDS.y,
        CHURCH_COORDS.z
    )

    return churchInterior
end

local function enableChurchFuneral()
    local interior = getChurchInterior()

    if not interior or interior == 0 then
        return false
    end

    PinInteriorInMemory(interior)

    restoreSets = {}
    for _, set in ipairs(OTHER_SETS) do
        if IsInteriorEntitySetActive(interior, set) then
            restoreSets[#restoreSets + 1] = set
            DeactivateInteriorEntitySet(interior, set)
        end
    end

    ActivateInteriorEntitySet(interior, FUNERAL_SET)

    RefreshInterior(interior)

    return true
end

local function disableChurchFuneral()
    local interior = getChurchInterior()

    if not interior or interior == 0 then
        return
    end

    DeactivateInteriorEntitySet(interior, FUNERAL_SET)

    for _, set in ipairs(restoreSets or {}) do
        ActivateInteriorEntitySet(interior, set)
    end
    restoreSets = nil

    RefreshInterior(interior)
end

-- THIS GOES HERE
CreateThread(function()
    local enabled = false

    while true do
        local huntTime = M8_IsHuntTime and M8_IsHuntTime()

        if huntTime and not enabled then
            if enableChurchFuneral() then
                enabled = true
            end

        elseif not huntTime and enabled then
            disableChurchFuneral()
            enabled = false
        end

        Wait(1000)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    disableChurchFuneral()
end)