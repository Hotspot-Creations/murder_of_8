local churchInterior = nil

local CHURCH_COORDS = vector3(
    1767.54,
    3891.87,
    36.64
)

local FUNERAL_SET = 'church_funeral'

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

    DeactivateInteriorEntitySet(interior, 'church_married')
    DeactivateInteriorEntitySet(interior, 'church_service')

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