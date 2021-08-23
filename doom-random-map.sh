#!/bin/bash

# fail if any commands fails
set -e
# debug log
#set -x

function show_usage (){
    printf "Usage: $0 [options [parameters]]\n"
    printf "\n"
    printf "Mandatory options:\n"
    printf " -g|--game          [doom|doom2|tnt|plutonia|heretic|hexen]\n"
    printf " -e|--engine        [chocolate|crispy|prboom-plus|gzdoom]\n"
    printf " -l|--map_limit     [none|vanilla|nolimit|boom|zdoom]\n"
    printf "\n"
    printf "Options:\n"
    printf " -d|--game-dir      [/path/to/doom/base/directory] (Optional, default: '~/games/doom')\n"
    printf " -s|--skill         [1, 2, 3, 4, 5] (Optional, default: '3')\n"
    printf " -r|--map_generator [none|slige|obsidian] (Optional, default: 'none')\n"
    printf " -m|--mods          [none|vanilla|improved|beautiful|brutal|samsara] (Optional, default: 'vanilla')\n"
    printf " -u|--mangohud      [yes|no] (Optional, default: 'no')\n"
    printf " -h|--help, Print help\n"

exit
}

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]];then
    show_usage
fi
if [[ -z $1 ]]; then
  show_usage
fi

while [ ! -z "$1" ]; do
  case "$1" in
     --game-dir|-d)
         shift
         echo "game directory: $1"
         GAME_DIR=$1
         ;;
     --game|-g)
         shift
         echo "game: $1"
         IWAD=$1
         ;;
     --engine|-e)
         shift
         echo "engine: $1"
         ENGINE=$1
         ;;
     --map_limit|-l)
        shift
        echo "map_limit: $1"
        MAP_LIMIT=$1
         ;;
     --skill|-s)
        shift
        echo "skill: $1"
        SKILL=$1
         ;;
     --map_generator|-r)
        shift
        echo "map_generator: $1"
        MAP_GENERATOR=$1
         ;;
     --mods|-m)
        shift
        echo "mods: $1"
        MODS_TYPE=$1
         ;;
     --mangohud|-u)
        shift
        echo "mangohud: $1"
        MANGOHUD_ENABLED=$1
         ;;
     *)
        show_usage
        ;;
  esac
shift
done

### Configuration
if [[ -z $GAME_DIR ]]; then
      GAME_DIR=~/games/doom
fi
SCRIPT_DIR="$(pwd $(dirname $0))"
IWADS_DIR=$GAME_DIR/wads/iwads
if [[ -z $MANGOHUD_ENABLED ]]; then
      MANGOHUD_ENABLED=no
fi
if [[ -z $MAP_GENERATOR ]]; then
      MAP_GENERATOR=none
fi
if [[ -z $SKILL ]]; then
      SKILL=3
fi
if [[ -z $MODS_TYPE ]]; then
      MODS_TYPE=vanilla
fi


### check parameter values
doom_game=(doom doom2 tnt plutonia heretic hexen)
if [[ " "${doom_game[@]}" " != *" $IWAD "* ]]; then
  echo "$IWAD: not recognized. Valid doom games are:"
  echo "${doom_game[@]/%/,}"
  exit 1
fi
engine=(chocolate crispy prboom-plus gzdoom)
if [[ " "${engine[@]}" " != *" $ENGINE "* ]]; then
  echo "$ENGINE: not recognized. Valid engines are:"
  echo "${engine[@]/%/,}"
  exit 1
fi
map_limit=(none vanilla nolimit boom zdoom)
if [[ " "${map_limit[@]}" " != *" $MAP_LIMIT "* ]]; then
  echo "$MAP_LIMIT: not recognized. Valid map limits are:"
  echo "${map_limit[@]/%/,}"
  exit 1
fi
map_generator=(none slige obsidian)
if [[ " "${map_generator[@]}" " != *" $MAP_GENERATOR "* ]]; then
  echo "$MAP_GENERATOR: not recognized. Valid map generators are:"
  echo "${map_generator[@]/%/,}"
  exit 1
fi
mods=(none vanilla improved beautiful brutal samsara)
if [[ " "${mods[@]}" " != *" $MODS_TYPE "* ]]; then
    echo "$MODS_TYPE: not recognized. Valid mods are:"
    echo "${mods[@]/%/,}"
    exit 1
fi
mangohud_enabled=(yes no)
if [[ " "${mangohud_enabled[@]}" " != *" $MANGOHUD_ENABLED "* ]]; then
    echo "$MANGOHUD_ENABLED: not recognized. Valid mangohud options are:"
    echo "${mangohud_enabled[@]/%/,}"
    exit 1
fi
skill=(1 2 3 4 5)
if [[ " "${skill[@]}" " != *" $SKILL "* ]]; then
    echo "$SKILL: not recognized. Valid skills are:"
    echo "${skill[@]/%/,}"
    exit 1
fi


### Script
get_map_file() {
    if [[ $MAP_GENERATOR == "none" ]]; then
        if [[ $MAP_LIMIT == "none" ]]; then
            if [[ $ENGINE == "chocolate" ]]; then
                pwadfile=$(find $GAME_DIR/wads/$IWAD/vanilla/*/*.wad ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* ! -name *credits*.* -type f 2>/dev/null | shuf -n 1)
            elif [[ $ENGINE == "crispy" ]]; then
                pwadfile=$(find $GAME_DIR/wads/$IWAD/{vanilla,nolimit}/*/*.wad ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* ! -name *credits*.* -type f 2>/dev/null | shuf -n 1)
            elif [[ $ENGINE == "prboom-plus" ]]; then
                pwadfile=$(find $GAME_DIR/wads/$IWAD/{vanilla,nolimit,boom}/*/*.wad ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* ! -name *credits*.* -type f 2>/dev/null | shuf -n 1)
            elif [[ $ENGINE == "gzdoom" ]]; then
                pwadfile=$(find $GAME_DIR/wads/$IWAD/{vanilla,nolimit,boom,zdoom}/*/{*.wad,*.pk3} ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* ! -name *credits*.* -type f 2>/dev/null | shuf -n 1)
            fi
        elif [[ $MAP_LIMIT == "vanilla" ]]; then
            pwadfile=$(find $GAME_DIR/wads/$IWAD/vanilla/*/*.wad ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* ! -name *credits*.* -type f 2>/dev/null | shuf -n 1)
        elif [[ $MAP_LIMIT == "nolimit" ]]; then
            pwadfile=$(find $GAME_DIR/wads/$IWAD/nolimit/*/*.wad ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* ! -name *credits*.* -type f 2>/dev/null | shuf -n 1)
        elif [[ $MAP_LIMIT == "boom" ]]; then
            pwadfile=$(find $GAME_DIR/wads/$IWAD/boom/*/*.wad ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* ! -name *credits*.* -type f 2>/dev/null | shuf -n 1)
        elif [[ $MAP_LIMIT == "zdoom" ]]; then
            pwadfile=$(find $GAME_DIR/wads/$IWAD/zdoom/*/{*.wad,*.pk3} ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* ! -name *credits*.* -type f 2>/dev/null | shuf -n 1)
        fi
    elif [[ $MAP_GENERATOR == "slige" ]]; then
        if [[ $MAP_LIMIT == "vanilla" ]]; then
            echo "Creating new slige map..."
            pwadfile="$GAME_DIR/wads/slige/slige_doom2.wad"
            $GAME_DIR/tools/slige/slige490/slige -config $GAME_DIR/tools/slige/slige490/slige.cfg -doom2 -levels 1 -rooms 18 -map1 -bimo -biwe -minlight 180 -nocustom $GAME_DIR/wads/slige/slige_doom2.out && $GAME_DIR/tools/bsp/bsp-5.2/bsp $GAME_DIR/wads/slige/slige_doom2.out -o $pwadfile
            echo "New slige map created... ${pwadfile}"
        else
            echo "ERROR: Slige can only make vanilla maps!"
            exit 1
        fi
    elif [[ $MAP_GENERATOR == "obsidian" ]]; then
        echo "Creating new obsidian map..."
        pwadfile="$GAME_DIR/wads/obsidian/obsidian_doom2.wad"
        ~/src/Obsidian/obsidian --install ~/src/Obsidian/ --batch $pwadfile --load $GAME_DIR/tools/obsidian/configs/${IWAD}_${MAP_LIMIT}.txt
        echo "New obsidian map created... ${pwadfile}"
    fi

    # Check pwad found
    if [[ -z $pwadfile ]]; then
        echo "No pwad file found"
        echo "### Random game settings"
        echo "IWAD              : $IWAD"
        echo "ENGINE            : $ENGINE"
        echo "PWAD file         : $pwadfile"
        exit 1
    else
        echo "PWAD file: $pwadfile"
    fi

    # Check maps in file
    if [[ $MAP_GENERATOR == "none" ]]; then
        pwadfilename=$(awk -F/ '{print $10}' <<< ${pwadfile})
    elif [[ $MAP_GENERATOR == "slige" || $MAP_GENERATOR == "obsidian" ]]; then
        pwadfilename=$(awk -F/ '{print $8}' <<< ${pwadfile})
    fi
    pwadfilename=$(basename -- "${pwadfilename%.*}")
    echo "PWAD name: $pwadfilename"

    # Get maps from pwad
    gzdoom -iwad $IWADS_DIR/$IWAD.wad -file $pwadfile -norun -hashfiles > /dev/null || true

    if [[ $IWAD == "doom2" ]]; then
        pwadmap=$(cat fileinfo.txt | grep $pwadfilename | grep " MAP" | awk '{print $4}' | sed -e "s/^MAP//" -e 's/,//g' | shuf -n 1)
        if [[ -z $pwadmap ]]; then
            pwadmap=$(cat fileinfo.txt | grep $pwadfilename | grep " maps/" | awk '{print $4}' | sed -e "s/^maps\/map//" -e 's/.wad,//g' | shuf -n 1)
        fi
        echo "PWAD map number: $pwadmap"

        mapnumbercheck=$(echo "$pwadmap" | awk '$0 ~/[^0-9]/ { print "NOT_NUMBER" }')
    elif [[ $IWAD == "doom" ]]; then
        pwadmap=$(cat fileinfo.txt | grep $pwadfilename | grep -E " E[1-5]M" | awk '{print $4}' | shuf -n 1 | sed -r 's/[EM]+/ /g' | sed -e "s/^0//" -e 's/,//g')
        echo "PWAD map number: $pwadmap"
    elif [[ $IWAD == "heretic" ]]; then
        pwadmap=$(cat fileinfo.txt | grep $pwadfilename | grep -E " E[1-5]M" | awk '{print $4}' | shuf -n 1 | sed -r 's/[EM]+/ /g' | sed -e "s/^0//" -e 's/,//g')
        echo "PWAD map number: $pwadmap"
    elif [[ $IWAD == "hexen" ]]; then
        pwadmap=$(cat fileinfo.txt | grep $pwadfilename | grep -E " E[1-5]M" | awk '{print $4}' | shuf -n 1 | sed -r 's/[EM]+/ /g' | sed -e "s/^0//" -e 's/,//g')
        echo "PWAD map number: $pwadmap"
    fi

    # Remove temporary file
    rm fileinfo.txt
}

###
# Doom random map script
###
get_map_file

#while [[ -z $pwadfile || $pwadfile == *"/b_"* || $pwadfile == *"_obj_"* || $pwadfile == *"_brk"* || $pwadfile == *"/m_"* || $pwadfile == *"bmodels"* ]]
while [[ -z $pwadmap || $pwadmap == "INFO" || $mapnumbercheck == "NOT_NUMBER" ]]
do
    echo "Incorrect map \"$pwadmap\" getting another map..."
    unset pwadmap
    get_map_file
done

# Save map info in external file
play_combination="${IWAD},${pwadfile},${pwadmap}"
play_combination=$(sed 's/ /_/g' <<< "${play_combination}")

# Check played times in external file
if [[ ! "$MAP_GENERATOR" == "slige"* && ! "$MAP_GENERATOR" == "oblige" && ! "$MAP_GENERATOR" == "obsidian"  ]]; then
    if [ ! -z $(grep "${play_combination}" ${SCRIPT_DIR}/already_played_maps.txt) ]; then 
        echo "Play combination found in file, updating file"
        current_times=$(cat ${SCRIPT_DIR}/already_played_maps.txt | grep ${play_combination} | awk -F, '{print $4}')
        played_times=$(echo "$(($current_times + 1))")

        # Update file
        sed -i "s|${play_combination},${current_times}|${play_combination},${played_times}|g" ${SCRIPT_DIR}/already_played_maps.txt
    else
        echo "Play combination not found in file, adding to file"
        played_times="1"
        new_played="${play_combination},${played_times}"
        echo "${new_played}" >> ${SCRIPT_DIR}/already_played_maps.txt
    fi
fi

# You can have separate mods "sets" for the source ports
if [[ $ENGINE == "gzdoom" ]]; then
    if [[ "$IWAD" == *"doom"* || "$IWAD" == "tnt" || "$IWAD" == "plutonia" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            #MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/jovian_palette/JovPal.wad"
            MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad $GAME_DIR/mods/zdoom/vanilla_essence/vanilla_essence_4_3.pk3"
        elif [[ $MODS_TYPE == "improved" ]]; then
            MODS="$GAME_DIR/mods/vanilla/doom_sound_bulb/doom_sound_bulb.wad $GAME_DIR/mods/vanilla/doom_sound_bulb/sound_bulb_extra_sfx.pk3 $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad $GAME_DIR/mods/zdoom/smoothdoom/smoothdoom.pk3 $GAME_DIR/mods/vanilla/vbright/vbright.wad $GAME_DIR/mods/vanilla/softfx/softfx.wad"
        elif [[ $MODS_TYPE == "beautiful" ]]; then
            MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad $GAME_DIR/mods/zdoom/beautiful_doom/Beautiful_Doom_716.pk3"
        elif [[ $MODS_TYPE == "brutal" ]]; then
            MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad $GAME_DIR/mods/zdoom/brutal/brutal_doom/brutalv21.8.0.pk3"
        elif [[ $MODS_TYPE == "samsara" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad $GAME_DIR/mods/zdoom/samsara/samsara-v0.3666-beta.pk3 $GAME_DIR/mods/zdoom/samsara/SchMonsterMixer.pk3"
        fi
    elif [[ "$IWAD" == "heretic" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/her-pal.wad $GAME_DIR/mods/vanilla/dwarss_heretic_hq_sfx_pack/sfx.wad $GAME_DIR/mods/zdoom/vanilla_essence/vanilla_essence_4_3.pk3"
        elif [[ $MODS_TYPE == "improved" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/her-pal.wad $GAME_DIR/mods/vanilla/dwarss_heretic_hq_sfx_pack/sfx.wad"
        elif [[ $MODS_TYPE == "brutal" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/her-pal.wad $GAME_DIR/mods/zdoom/brutal/brutal_heretic/Heretic-Shadow_Collection/1_BRUTAL_HERETIC/BrutalHereticRPG_V2.2.pk3"
        elif [[ $MODS_TYPE == "samsara" ]]; then
            echo "MOD Not available"
            exit 1
        fi
    elif [[ "$IWAD" == "hexen" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/hex-pal.wad"
        elif [[ $MODS_TYPE == "improved" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/hex-pal.wad $GAME_DIR/mods/zdoom/vanilla_essence/vanilla_essence_4_3.pk3"
        elif [[ $MODS_TYPE == "brutal" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/hex-pal.wad $GAME_DIR/mods/zdoom/brutal/brutal_hexen/Hexen/1_BRUTAL_HEXEN/BrutalHexenRPG_V4.7.pk3"
        elif [[ $MODS_TYPE == "samsara" ]]; then
            echo "MOD Not available"
            exit 1
        fi
    fi
elif [[ $ENGINE == "chocolate" ]]; then
    if [[ "$IWAD" == *"doom"* || "$IWAD" == "tnt" || "$IWAD" == "plutonia" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad"
        elif [[ $MODS_TYPE == "improved" ]]; then
            MODS="$GAME_DIR/mods/vanilla/doom_sound_bulb/doom_sound_bulb_legacy.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad $GAME_DIR/mods/vanilla/vbright/vbright.wad $GAME_DIR/mods/vanilla/softfx/softfx.wad $GAME_DIR/mods/vanilla/vanilla_doom_smooth_weapons/vsmooth.wad -dehlump"
        elif [[ $MODS_TYPE == "samsara" ]]; then
            echo "MOD Not available"
            exit 1
        fi
    elif [[ "$IWAD" == "heretic" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/her-pal.wad $GAME_DIR/mods/vanilla/dwarss_heretic_hq_sfx_pack/sfx.wad"
        elif [[ $MODS_TYPE == "samsara" ]]; then
            echo "MOD Not available"
            exit 1
        fi
    elif [[ "$IWAD" == "hexen" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/hex-pal.wad"
        elif [[ $MODS_TYPE == "samsara" ]]; then
            echo "MOD Not available"
            exit 1
        fi
    fi
elif [[ $ENGINE == "crispy" ]]; then
    if [[ "$IWAD" == *"doom"* || "$IWAD" == "tnt" || "$IWAD" == "plutonia" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad"
        elif [[ $MODS_TYPE == "improved" ]]; then
            MODS="$GAME_DIR/mods/vanilla/doom_sound_bulb/doom_sound_bulb_legacy.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad $GAME_DIR/mods/vanilla/vbright/vbright.wad $GAME_DIR/mods/vanilla/softfx/softfx.wad $GAME_DIR/mods/vanilla/vanilla_doom_smooth_weapons/vsmooth.wad"
        elif [[ $MODS_TYPE == "samsara" ]]; then
            echo "MOD Not available"
            exit 1
        fi
    elif [[ "$IWAD" == "heretic" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/her-pal.wad $GAME_DIR/mods/vanilla/dwarss_heretic_hq_sfx_pack/sfx.wad"
        elif [[ $MODS_TYPE == "samsara" ]]; then
            echo "MOD Not available"
            exit 1
        fi
    elif [[ "$IWAD" == "hexen" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/hex-pal.wad"
        elif [[ $MODS_TYPE == "samsara" ]]; then
            echo "MOD Not available"
            exit 1
        fi
    fi
elif [[ $ENGINE == "prboom-plus" ]]; then
    if [[ "$IWAD" == *"doom"* || "$IWAD" == "tnt" || "$IWAD" == "plutonia" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad"
        elif [[ $MODS_TYPE == "improved" ]]; then
            MODS="$GAME_DIR/mods/vanilla/doom_sound_bulb/doom_sound_bulb_legacy.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad $GAME_DIR/mods/vanilla/vbright/vbright.wad $GAME_DIR/mods/vanilla/softfx/softfx.wad $GAME_DIR/mods/vanilla/vanilla_doom_smooth_weapons/vsmooth.wad"
        elif [[ $MODS_TYPE == "samsara" ]]; then
            echo "MOD Not available"
            exit 1
        fi
    elif [[ "$IWAD" == "heretic" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/her-pal.wad"
        elif [[ $MODS_TYPE == "samsara" ]]; then
            echo "MOD Not available"
            exit 1
        fi
    elif [[ "$IWAD" == "hexen" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/hex-pal.wad"
        elif [[ $MODS_TYPE == "samsara" ]]; then
            echo "MOD Not available"
            exit 1
        fi
    fi
fi

if [[ $MANGOHUD_ENABLED == "yes" ]]; then
    export MANGOHUD_DLSYM=1
    #export MANGOHUD_CONFIG=cpu_temp,gpu_temp,core_load,cpu_core_clock,gpu_mem_clock,cpu_power,gpu_power,cpu_mhz,ram,vram,frametime,position=top-left,height=500,font_size=24
    export MANGOHUD_CONFIG=cpu_temp,gpu_temp,cpu_core_clock,gpu_mem_clock,cpu_power,gpu_power,cpu_mhz,ram,vram,frametime,position=top-left,height=500,font_size=18
fi

if [[ $ENGINE == "chocolate" ]]; then
    if [[ "$IWAD" == *"doom"* || "$IWAD" == "tnt" || "$IWAD" == "plutonia" ]]; then
        commandline="chocolate-doom -fullscreen -iwad $IWADS_DIR/$IWAD.wad -merge $pwadfile $MODS -savedir $GAME_DIR/savegames/$IWAD/ -skill $SKILL -warp $pwadmap"
    elif [[ "$IWAD" == "heretic" ]]; then
        commandline="chocolate-heretic -fullscreen -iwad $IWADS_DIR/$IWAD.wad -merge $pwadfile $MODS -savedir $GAME_DIR/savegames/$IWAD/ -skill $SKILL -warp $pwadmap"
    elif [[ "$IWAD" == "hexen" ]]; then
        commandline="chocolate-hexen -fullscreen -iwad $IWADS_DIR/$IWAD.wad -merge $pwadfile $MODS -savedir $GAME_DIR/savegames/$IWAD/ -skill $SKILL -warp $pwadmap"
    fi
elif [[ $ENGINE == "crispy" ]]; then
    if [[ "$IWAD" == *"doom"* || "$IWAD" == "tnt" || "$IWAD" == "plutonia" ]]; then
        commandline="crispy-doom -fullscreen -iwad $IWADS_DIR/$IWAD.wad -file $pwadfile $MODS -savedir $GAME_DIR/savegames/$IWAD/ -skill $SKILL -warp $pwadmap"
    elif [[ "$IWAD" == "heretic" ]]; then
        commandline="crispy-heretic -fullscreen -iwad $IWADS_DIR/$IWAD.wad -file $pwadfile $MODS -savedir $GAME_DIR/savegames/$IWAD/ -skill $SKILL -warp $pwadmap"
    elif [[ "$IWAD" == "hexen" ]]; then
        #commandline="crispy-hexen -fullscreen -iwad $IWADS_DIR/$IWAD.wad -file $pwadfile $MODS -savedir $GAME_DIR/savegames/$IWAD/ -skill $SKILL -warp $pwadmap"
        echo "ERROR: crispy engine is not available with hexen game!"
        exit 1
    fi
elif [[ $ENGINE == "prboom-plus" ]]; then
    #commandline="prboom-plus -vidmode gl -complevel 17 -width 1920 -height 1080 -fullscreen -geom 640x360f -aspect 16:9 -iwad $IWADS_DIR/$IWAD.wad -file $pwadfile $MODS -save $GAME_DIR/savegames/$IWAD/ -skill $SKILL -warp $pwadmap"
    commandline="prboom-plus -vidmode gl -complevel 17 -width 1920 -height 1080 -fullscreen -aspect 16:9 -iwad $IWADS_DIR/$IWAD.wad -file $pwadfile $MODS -save $GAME_DIR/savegames/$IWAD/ -skill $SKILL -warp $pwadmap"
elif [[ $ENGINE == "gzdoom" ]]; then
    commandline="gzdoom -width 1920 -height 1080 -fullscreen -iwad $IWADS_DIR/$IWAD.wad -file $pwadfile $MODS -savedir $GAME_DIR/savegames/$IWAD/ -skill $SKILL -warp $pwadmap"
fi

# Run
if [[ $MANGOHUD_ENABLED == "yes" ]]; then
    mangohud $commandline || true
else
    $commandline || true
fi

echo "### Random game settings"
echo "IWAD              : $IWAD"
echo "ENGINE            : $ENGINE"
echo "PWAD file         : $pwadfile"
echo "PWAD map number   : $pwadmap"
echo "MOD files         : $MODS"
echo "SKILL             : $SKILL"
echo "Full command line : $commandline"
echo ""
echo "Iwad/Engine/Map combination: ${play_combination}"
echo "Iwad/Engine/Map combination played ${played_times} times"
