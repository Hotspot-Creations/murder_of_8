-- tests/progress_spec.lua   run from resource root:  lua tests/progress_spec.lua
RegisterNetEvent = function() end      -- stubs for load-time natives
AddEventHandler = function() end
dofile('server/main.lua')
local P = M8Progress
local passed, failed = 0, 0
local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then passed = passed + 1 else failed = failed + 1; print('FAIL ' .. name .. ': ' .. tostring(err)) end
end

test('a saved record comes back with numeric chapter keys (json turns them into strings)', function()
    local p = P.Normalize({ chapter = 3, evidence = { rusk_body = true, bell = true }, completed = { ['1'] = true, ['2'] = true } })
    assert(p.chapter == 3)
    assert(p.evidence.rusk_body and p.evidence.bell)
    assert(p.completed[1] == true and p.completed[2] == true)
    assert(p.completed['1'] == nil)
end)
test('numeric keys and a finished case survive as they are', function()
    local p = P.Normalize({ chapter = 8, evidence = { last_message = true }, completed = { [8] = true } })
    assert(p.completed[8] == true and p.chapter == 8)
end)
test('nothing saved, or garbage, gives a fresh case', function()
    for _, raw in ipairs({ 'x', 42, {}, { chapter = 'nope', evidence = 'no', completed = 7 } }) do
        local p = P.Normalize(raw)
        assert(p.chapter == 1 and next(p.evidence) == nil and next(p.completed) == nil)
    end
    local p = P.Normalize(nil)
    assert(p.chapter == 1 and next(p.evidence) == nil and next(p.completed) == nil)
end)
test('the KVP key is per license', function()
    assert(P.Key('license:abc') == 'm8_progress:license:abc')
end)

print(('%d passed, %d failed'):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
