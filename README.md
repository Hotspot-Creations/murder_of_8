# Murder of 8 — The Last Witness

Complete 8-chapter standalone FiveM investigation/horror resource.

Version: `1.6.6`

## Chapters

1. The House That Only Burns At Night
2. No One Was Buried Here
3. Room Eight Does Not Exist
4. The Dead Have Two Names
5. The Train Never Came
6. The Water Kept Everything
7. Nova Was Here
8. The Last Witness

## Install

```cfg
ensure murder_of_8
```

## Casebook

```text
/casebook
```

Default key: `J`

## Interaction

```lua
Config.Interaction = 'auto'
```

Options: `auto`, `ox_target`, `native`.

## Debug commands

Requires `Config.Debug = true`.

```text
/m8uitest
/m8coords
/m8reset
/m8chapter 1-8
```

## Built-in horror events

- Brass bell
- Coffin knocks
- Metal/cell clang
- Whisper tone
- Morgue phone ringing
- Distant train horn
- 3-3-2 dock knocks
- University blackout
- Final Compound blackout / impact
- Optional Chapter 1 window silhouette

## External map/prop integration

Generic scene event:

```lua
AddEventHandler('m8:scene:active', function(sceneId, active)
    print(sceneId, active)
end)
```

Scene-specific events also fire, for example:

```lua
AddEventHandler('m8:burning_house:active', function(active)
    -- toggle your fire/smoke props
end)
```

Client exports:

```lua
exports.murder_of_8:IsSceneActive('church')
exports.murder_of_8:IsSceneActive('compound')
exports.murder_of_8:IsBurningHouseActive()
```

## Sandy Halloween integration

With `prompt_sandy_halloween` running (ensure it first):

- While a player is on the case (evidence found, chapter 8 not finished), the Halloween resource's own
  ambient scare director steps back for them, so the two never pile up. Its prop sounds, 3:11 knocks,
  Loch Ness and the midnight bell carry on. It asks `exports.murder_of_8:IsInvestigating()` once a second.
- The literal scare sounds play in 3D through the Halloween sound bank instead of the 2D NUI files:
  footsteps and whispers from the Bellman figure itself (a running figure's steps follow it), chains and
  the creak from the figure, the distant scream far behind you, the coffin knocks from the coffin and the
  3-3-2 dock knocks from under the dock. The story's own sounds live in that bank too: the Bellman's
  hand bell (from the figure when a watcher appears, from the old bell / final bell when examined, behind
  you as a micro-haunt), two breaths and the door creak from the figure, the body thud from the dropped
  body, and a cell door slam from cell eight before "YOU HEARD THAT TOO". Stingers, the phone and the
  train horn stay in the NUI. Switch: `Config.NativeHorrorAudio.useSandyHalloween`
  (`shared/native_audio_config.lua`), bridge: `client/halloween_audio.lua`. Without the Halloween
  resource everything plays as before.

## Progress persistence

Progress is saved per player (by license identifier) in the server's resource KVP as JSON, so it
survives disconnects, resource restarts and server restarts. No database needed. `/m8reset` (debug)
wipes the player's own record.


## v1.1.0 — Casebook NUI

The casebook was rebuilt around the supplied physical notepad visual style.

Changes:

- Leather ring-bound notebook instead of a generic UI panel
- Eight physical case-file tabs on the right side
- Evidence rendered as handwritten/field-note sections on the paper
- Locked evidence appears crossed out / redacted
- Old-blood paper marks
- Chapter-complete screen appears on an aged loose page
- Existing progression and evidence logic is unchanged

The NUI uses the paper/notebook image assets included in:

```text
html/img/
```

The manifest now includes:

```lua
'html/img/*.png'
```


## v1.1.1 — Chapter 8 reveal

Final bell teleport:

```text
1635.1184, 3519.9009, 50.5055, 312.4570
```

Final corpse:

```text
1633.5579, 3518.9634, 51.1866, 311.5444
```

The corpse and final message are intentionally absent when the player
first appears on the bed.

After the player starts turning or moving to leave, the script checks
that the corpse point is outside the camera view. Only then does the
corpse spawn and the final message interaction become available.

The logic lives in:

```text
client/finale.lua
```

Default corpse props attempted:

```text
prop_cs_dead_guy
prop_rub_corpse_01
prop_rub_corpse_03
```

Change `Finale.bodyModels` in `client/finale.lua` if you have a specific
custom corpse prop.


## v1.2.0 — 9 PM to 5 AM hunt + haunt system

The investigation is now playable only from **21:00 through 04:59** game time.
At 05:00, unfinished players receive:

> THE DAY IS APPROACHING
> Come back later tonight to finish... do not let your guard down.

Evidence is locked during daylight, but the case does not completely stop:
subtle daytime haunt events can still happen after the player has started the
investigation. At night, stronger random jump scares are enabled and several
specific discoveries have guaranteed delayed scares.

The Burning House keeps its existing scene/world-effect window of 01:00-03:00,
but its evidence can now be investigated during the full 21:00-05:00 hunt
window. This allows the overall mystery to start before 1 AM without forcing
map-side fire/smoke to remain active all night.

Settings are in `shared/haunt_config.lua`.

Debug commands:

```text
/m8timecheck
/m8scare day
/m8scare night
/m8scare jump
/m8scare impact
/m8scare warning
```

Night random scare default delay: 90-180 seconds.
Day random scare default delay: 4-8 minutes.