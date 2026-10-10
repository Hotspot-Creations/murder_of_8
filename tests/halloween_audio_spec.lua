-- tests/halloween_audio_spec.lua   run from resource root:  lua tests/halloween_audio_spec.lua
Config = { NativeHorrorAudio = { useSandyHalloween = true } }
vector3 = function(x, y, z) return { x = x, y = y, z = z } end
dofile('client/halloween_audio.lua')
local H = M8HalloweenAudio
local passed, failed = 0, 0
local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then passed = passed + 1 else failed = failed + 1; print('FAIL ' .. name .. ': ' .. tostring(err)) end
end

test('literal sounds map onto the Sandy Halloween bank, abstract stingers stay in the NUI', function()
    for _, n in ipairs({ 'footsteps', 'footsteps_run', 'whisper', 'breath', 'chain_drag', 'distant_scream', 'door_creak',
                         'bell', 'archive_bell', 'body_drop', 'metal_clang', 'cell_slam', 'coffin_knocks', 'dock_knocks',
                         'jump_sting', 'reverse_sting' }) do
        local e = H.Resolve(n)
        assert(e, n)
        assert(H.Pick(e):sub(1, 9) == 'promptsh_', n)
    end
    for _, n in ipairs({ 'static', 'heartbeat', 'sub_rumble', 'ambience', 'phone_ring', 'train_horn' }) do
        assert(H.Resolve(n) == nil, n)
    end
    assert(H.Resolve('impact').silent == true)                     -- removed: nothing plays, no NUI fallback
    assert(H.Resolve('jump_sting').back < 0)                       -- a hit is in your face
    assert(H.Pick(H.Resolve('jump_sting')):find('scream'))
    assert(H.Pick(H.Resolve('reverse_sting')) == 'promptsh_ghost_whisper')
end)
test('the bridge can be switched off in the config', function()
    Config.NativeHorrorAudio.useSandyHalloween = false
    assert(H.Resolve('footsteps') == nil)
    Config.NativeHorrorAudio.useSandyHalloween = true
    assert(H.Resolve('footsteps'))
end)
test('pan becomes a side offset (+-2.5 m); close sounds sit behind you, the body drops in front', function()
    local e = H.Resolve('whisper')
    local back, side, up = H.Offset(e, 1.0)
    assert(back > 0 and side == 2.5, side)
    local _, s2 = H.Offset(e, -0.5)
    assert(s2 == -1.25, s2)
    local _, s3 = H.Offset(e, nil)
    assert(s3 == 0)
    local _, s4 = H.Offset(e, 7)        -- clamped
    assert(s4 == 2.5)
    for _, n in ipairs({ 'footsteps', 'whisper', 'breath', 'chain_drag', 'door_creak', 'distant_scream' }) do
        assert(H.Resolve(n).back > 0, n)
    end
    assert(H.Resolve('body_drop').back < 0)
end)
test('the story sounds: bell / slam play from the evidence spot, breaths alternate', function()
    for _, n in ipairs({ 'bell', 'archive_bell', 'metal_clang', 'cell_slam', 'coffin_knocks', 'dock_knocks' }) do
        assert(H.Resolve(n).fromSpot, n)
    end
    assert(H.Pick(H.Resolve('bell')) == 'promptsh_m8_bell')
    assert(H.Pick(H.Resolve('cell_slam')) == 'promptsh_m8_cell_slam')
    local seen = {}
    for _ = 1, 50 do seen[H.Pick(H.Resolve('breath'))] = true end
    assert(seen.promptsh_m8_breath_01 and seen.promptsh_m8_breath_02)
end)
test('knock patterns: coffin 3 knocks, dock 3-3-2 = 8 knocks over ~3.5 s', function()
    local c, d = H.Resolve('coffin_knocks'), H.Resolve('dock_knocks')
    assert(#c.pattern == 3 and #d.pattern == 8)
    local total = 0
    for _, ms in ipairs(d.pattern) do total = total + ms end
    assert(total >= 3000 and total <= 4000, total)
    assert(d.sounds[1] == 'promptsh_knock_under' and d.up < 0)   -- from under the dock
    assert(#c.sounds == 3)
end)

print(('%d passed, %d failed'):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
