local fixes = {
    {
        model = "xm_prop_body_bag",

        -- Put the body bag's APPROXIMATE original location here.
        -- It only needs to be close enough for the script to identify
        -- the correct bag.
        coords = vector3(
            1515.48,
            3786.14,
            37.22
        ),

        radius = 10.0
    }
}

local fixedEntities = {}

local function findClosestObject(modelName, targetCoords, radius)
    local modelHash = joaat(modelName)

    local closest = nil
    local closestDistance = radius or 10.0

    for _, obj in ipairs(GetGamePool("CObject")) do
        if DoesEntityExist(obj)
            and GetEntityModel(obj) == modelHash
        then
            local objCoords = GetEntityCoords(obj)
            local distance = #(targetCoords - objCoords)

            if distance < closestDistance then
                closest = obj
                closestDistance = distance
            end
        end
    end

    return closest, closestDistance
end

local function fixProp(data)
    local object, distance = findClosestObject(
        data.model,
        data.coords,
        data.radius
    )

    if not object then
        return
    end

    -- Don't continuously mess with the same streamed entity.
    if fixedEntities[object] then
        return
    end

    local before = GetEntityCoords(object)

    PlaceObjectOnGroundProperly(object)

    local after = GetEntityCoords(object)

    FreezeEntityPosition(object, true)

    fixedEntities[object] = true

    if Config.Debug then
        print(
            ("^2[Murder of 8]^0 Grounded %s | %.2fm away")
            :format(data.model, distance)
        )

        print(
            ("Before: %.4f, %.4f, %.4f")
            :format(before.x, before.y, before.z)
        )

        print(
            ("After: %.4f, %.4f, %.4f")
            :format(after.x, after.y, after.z)
        )
    end
end

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())

        for _, data in ipairs(fixes) do
            -- Only bother searching when the player is near the area.
            if #(playerCoords - data.coords) <= 100.0 then
                fixProp(data)
            end
        end

        Wait(2000)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    fixedEntities = {}
end)
