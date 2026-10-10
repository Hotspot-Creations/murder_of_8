-- Murder of 8 - Native Horror Audio
--
-- Literal sounds should sound like literal sounds. This layer uses GTA V's own
-- recorded/positional audio and physics where possible. NUI OGG audio remains
-- for abstract stingers, sub-rumble, static and as a fallback.

Config = Config or {}

Config.NativeHorrorAudio = {
    enabled = false,
    -- When prompt_sandy_halloween is running, literal sounds (footsteps, whispers, chains, creak,
    -- distant scream, coffin/dock knocks) play in 3D through its sound bank - from the Bellman
    -- figure itself, from the coffin / the dock, or from behind the player. Stingers stay in the NUI.
    useSandyHalloween = true,

    -- Requires GTA Online Ghosts Exposed content (build 2944+).
    -- If unavailable, the script automatically falls back to other GTA sounds.
    useGhostAudio = true,
    ghostBank = 'DLC_MP2023_1/DLC_MP2023_1_GH',

    -- Invisible local ped used so footsteps come from GTA's actual surface-aware
    -- footstep system instead of a fake "knock" audio file.
    footstepPedModel = 'a_m_m_skidrow_01',

    defaultRange = 22,
    distantRange = 75,

    -- If true, NUI only handles sounds the native layer intentionally does not
    -- replace (rumble/static/abstract designed stingers).
    preferNative = true
}
