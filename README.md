# doom-random-map-sh
A small random doom map launcher to discover those maps you downloaded and never actually played.

This is a random doom map launcher script i made for myself, tired of having to remember which maps i already played and what progress i made in them, and enjoying to make temporary slige maps to play and enjoy, i came with this idea to have a script, that get a random map to play, either be them PWAD files or PK3, wads or megawads in the doom subdirectories.

For getting the maps inside the PWAD files, i use GZDoom inside the script and then, you can use whatever source port is installed and available in your PATH

It launches the random map using the source port you put as a parameter, the main ones i use are available, but you can change the script to run with any source port, i choosed the main 4 because it can play any existing map almost always, and provide a wide range of doom maps and mods available: Chocolate-Doom, Crispy-Doom, Prboom-plus and GZDoom.

Dependencies:

(Required)
GZDoom: https://github.com/coelckers/gzdoom

(Optional)
Chocolate-doom: http://www.chocolate-doom.org/
Crispy-doom: http://fabiangreffrath.github.io/crispy-doom
Prboom-plus: https://prboom-plus.sourceforge.net/

Usage: Edit GAME_DIR and IWADS_DIR values with your doom installation directories and run:

./doom-random-map.sh <doom|doom2|tnt|plutonia> <chocolate-doom|crispy-doom|prboom-plus|gzdoom>

Your directory structure has to be like this if you don't modify the script "find" commands:

$ tree -L 2 -d ~/games/doom/
~/games/doom/
├── mods
│   ├── vanilla
│   └── zdoom
├── savegames
│   ├── doom
│   ├── doom2
│   ├── plutonia
│   └── tnt
├── mods
│   ├── vanilla
│   │   ├── bd_dehacked
│   │   ├── blackops
│   │   ├── d64d2
│   │   ├── deh4t
│   │   ├── dehacked
│   │   ├── dimm_pal
│   │   ├── doom_sound_bulb
│   │   ├── isopal
│   │   ├── jovian_palette
│   │   ├── obticfix
│   │   ├── pal_plus
│   │   ├── pk_anim
│   │   ├── pk_doom_sfx
│   │   ├── remaster_sfx
│   │   ├── screem_pals
│   │   ├── smoothed
│   │   ├── sprfix19
│   │   ├── ssdx-the_gameboy_palette_pack
│   │   ├── vanilla_doom_smooth_weapons
│   │   ├── vbrutal
│   └── zdoom
│       ├── 0verp0wer_weap0ns
│       ├── ambience_pack
│       ├── arcane_dungeons
│       ├── beautiful_doom
│       ├── boss_battles
│       ├── brightmaps
│       ├── brutal
│       ├── vanilla_essence
│       ├── smoothdoom
│       └── zdoom-dhtp
└── wads
    ├── doom
    │   ├── boom
    │   └── vanilla
    ├── doom2
    │   ├── boom
    │   │   ├── 2048vr
    │   │   ├── 300_min_vr
    │   │   ├── whispers_of_satan
    │   │   ├── world_orifice
    │   │   └── wormwood
    │   ├── limit_removing
    │   ├── vanilla
    │   │   ├── master_levels_doom_2
    │   │   ├── memento_mori
    │   │   ├── perditions_gate
    │   │   └── resurgence
    │   └── zdoom
    │       ├── altar_of_evil
    │       ├── crimson_canyon
    │       ├── dalida_satanica_mortis
    │       ├── dark_encounters
    │       ├── darkstar
    │       ├── zenblack
    │       └── zen_dynamics
    ├── original
    ├── plutonia
    │   ├── boom
    │   └── vanilla
    └── tnt
    │   ├── boom
    │   └── vanilla
