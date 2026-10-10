fx_version 'cerulean'
game 'gta5'

author 'Hotspot Creations & Prompt Studios'
description 'Murder of 8 - standalone Halloween investigation resource for sandy shores halloween event!'
version '1.7.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    'scenes.lua',
    'shared/haunt_config.lua',
    'shared/scare_config.lua',
    'shared/scripted_scare_config.lua',
    'shared/native_audio_config.lua',
    'shared/story.lua'
}

client_scripts {
    'client/halloween_audio.lua',
    'client/native_audio.lua',
    'client/main.lua',
    'client/interactions.lua',
    'client/finale.lua',
    'client/haunt.lua',
    'client/scripted_scares.lua',
    'client/evidence_props.lua',
    'client/church_interior.lua',
    'client/map_fixes.lua',
    'client/chair_evidence.lua',
    'client/compound_chairs.lua',
}

server_scripts {
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/scare_director.css',
    'html/app.js',
    'html/img/*.png',
    'html/audio/*.ogg'
}

escrow_ignore {
    'config.lua',
    'shared/haunt_config.lua',
    'shared/scare_config.lua',
    'shared/scripted_scare_config.lua',
    'shared/native_audio_config.lua'
}
