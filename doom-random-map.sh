#!/bin/bash

# fail if any commands fails
set -e
# debug log
#set -x

Help() {
  # Display Help
  echo "Runs automation test locally sending results to Jenkins."
  echo ""
  echo "  Syntax: ./doom-random-map.sh [params]"
  echo ""
  echo "  Available parameters:"
  echo "    doom game          -> doom | doom2 | tnt | plutonia | heretic | hexen"
  echo "    engine             -> chocolate | crispy | prboom-plus | gzdoom"
  echo "    map limit          -> none | vanilla | limit-removing | boom | zdoom | slige | oblige"
  echo "    mods               -> none | vanilla | gzdoom | beautiful | brutal"
  echo "    mangohud           -> yes | no"
  echo ""
}

if [[ $1 == "--help" || $1 == "-h" ]]; then
    Help
    exit 1
fi
if [ -z "$1" ]; then
  Help
  exit 1
fi
if [ -z "$2" ]; then
  Help
  exit 1
fi
if [ -z "$3" ]; then
  Help
  exit 1
fi
if [ -z "$4" ]; then
  Help
  exit 1
fi
if [ -z "$5" ]; then
  Help
  exit 1
fi

### check parameter values
doom_game=(doom doom2 tnt plutonia heretic hexen)
if [[ " "${doom_game[@]}" " != *" $1 "* ]]; then
  echo "$1: not recognized. Valid doom games are:"
  echo "${doom_game[@]/%/,}"
  exit 1
fi
engine=(chocolate crispy prboom-plus gzdoom)
if [[ " "${engine[@]}" " != *" $2 "* ]]; then
  echo "$2: not recognized. Valid engines are:"
  echo "${engine[@]/%/,}"
  exit 1
fi
map_limit=(none vanilla limit-removing boom zdoom)
if [[ " "${map_limit[@]}" " != *" $3 "* ]]; then
  echo "$3: not recognized. Valid map limits are:"
  echo "${map_limit[@]/%/,}"
  exit 1
fi
mods=(none vanilla gzdoom beautiful brutal)
if [[ " "${mods[@]}" " != *" $4 "* ]]; then
    echo "$4: not recognized. Valid mods are:"
    echo "${mods[@]/%/,}"
    exit 1
fi
mangohud_enabled=(yes no)
if [[ " "${mangohud_enabled[@]}" " != *" $5 "* ]]; then
    echo "$5: not recognized. Valid mangohud options are:"
    echo "${mangohud_enabled[@]/%/,}"
    exit 1
fi

### Configuration
GAME_DIR=~/games/doom
IWADS_DIR=$GAME_DIR/wads/iwads
IWAD=$1
ENGINE=$2
MAP_LIMIT=$3
MODS_TYPE=$4
MANGOHUD_ENABLED=$5

### Script
get_map_file() {
    if [[ $MAP_LIMIT == "none" ]]; then
        if [[ $ENGINE == "chocolate" ]]; then
            pwadfile=$(find $GAME_DIR/wads/$IWAD/vanilla/*/*.wad ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* -type f 2>/dev/null | shuf -n 1)
        elif [[ $ENGINE == "crispy" ]]; then
            pwadfile=$(find $GAME_DIR/wads/$IWAD/{vanilla,limit_removing}/*/*.wad ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* -type f 2>/dev/null | shuf -n 1)
        elif [[ $ENGINE == "prboom-plus" ]]; then
            pwadfile=$(find $GAME_DIR/wads/$IWAD/{vanilla,limit_removing,boom}/*/*.wad ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* -type f 2>/dev/null | shuf -n 1)
        elif [[ $ENGINE == "gzdoom" ]]; then
            pwadfile=$(find $GAME_DIR/wads/$IWAD/{vanilla,limit_removing,boom,zdoom}/*/{*.wad,*.pk3} ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* -type f 2>/dev/null | shuf -n 1)
        fi
    elif [[ $MAP_LIMIT == "vanilla" ]]; then
        pwadfile=$(find $GAME_DIR/wads/$IWAD/vanilla/*/*.wad ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* -type f 2>/dev/null | shuf -n 1)
    elif [[ $MAP_LIMIT == "limit-removing" ]]; then
        pwadfile=$(find $GAME_DIR/wads/$IWAD/limit_removing/*/*.wad ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* -type f 2>/dev/null | shuf -n 1)
    elif [[ $MAP_LIMIT == "boom" ]]; then
        pwadfile=$(find $GAME_DIR/wads/$IWAD/boom/*/*.wad ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* -type f 2>/dev/null | shuf -n 1)
    elif [[ $MAP_LIMIT == "zdoom" ]]; then
        pwadfile=$(find $GAME_DIR/wads/$IWAD/zdoom/*/{*.wad,*.pk3} ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* -type f 2>/dev/null | shuf -n 1)
    elif [[ $MAP_LIMIT == "slige" ]]; then
        #TODO
        pwadfile=$(find $GAME_DIR/wads/$IWAD/{vanilla,limit_removing,boom,zdoom}/*/{*.wad,*.pk3} ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* -type f 2>/dev/null | shuf -n 1)
    elif [[ $MAP_LIMIT == "oblige" ]]; then
        #TODO
        pwadfile=$(find $GAME_DIR/wads/$IWAD/{vanilla,limit_removing,boom,zdoom}/*/{*.wad,*.pk3} ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* -type f 2>/dev/null | shuf -n 1)
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
    pwadfilename=$(awk -F/ '{print $10}' <<< ${pwadfile})
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
play_combination="${IWAD},${ENGINE},${pwadfile},${pwadmap}"
echo "${play_combination}" >> "./already_played_maps.txt"

# You can have separate mods "sets" for the source ports
if [[ $ENGINE == "gzdoom" ]]; then
    if [[ "$IWAD" == *"doom"* || "$IWAD" == "tnt" || "$IWAD" == "plutonia" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            #MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/jovian_palette/JovPal.wad"
            MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad"
        elif [[ $MODS_TYPE == "gzdoom" ]]; then
            MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad $GAME_DIR/mods/zdoom/vanilla_essence/vanilla_essence_4_3.pk3"
        elif [[ $MODS_TYPE == "beautiful" ]]; then
            MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad $GAME_DIR/mods/zdoom/beautiful_doom/Beautiful_Doom_710.pk3"            
        elif [[ $MODS_TYPE == "brutal" ]]; then
            MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad $GAME_DIR/mods/zdoom/brutal/brutal_doom/brutalv21.8.0.pk3"            
        fi
    elif [[ "$IWAD" == "heretic" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/her-pal.wad"
        elif [[ $MODS_TYPE == "gzdoom" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/her-pal.wad $GAME_DIR/mods/zdoom/vanilla_essence/vanilla_essence_4_3.pk3"
        elif [[ $MODS_TYPE == "brutal" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/her-pal.wad $GAME_DIR/mods/zdoom/brutal/brutal_heretic/Heretic-Shadow_Collection/1_BRUTAL_HERETIC/BrutalHereticRPG_V2.2.pk3"
        fi
    elif [[ "$IWAD" == "hexen" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/hex-pal.wad"
        elif [[ $MODS_TYPE == "gzdoom" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/hex-pal.wad $GAME_DIR/mods/zdoom/vanilla_essence/vanilla_essence_4_3.pk3"
        elif [[ $MODS_TYPE == "brutal" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/hex-pal.wad $GAME_DIR/mods/zdoom/brutal/brutal_hexen/Hexen/1_BRUTAL_HEXEN/BrutalHexenRPG_V4.7.pk3"
        fi
    fi
elif [[ $ENGINE == "chocolate" ]]; then
    if [[ "$IWAD" == *"doom"* || "$IWAD" == "tnt" || "$IWAD" == "plutonia" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad"
        fi
    elif [[ "$IWAD" == "heretic" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/her-pal.wad"
        fi
    elif [[ "$IWAD" == "hexen" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/hex-pal.wad"
        fi
    fi
elif [[ $ENGINE == "crispy" ]]; then
    if [[ "$IWAD" == *"doom"* || "$IWAD" == "tnt" || "$IWAD" == "plutonia" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad"
        fi
    elif [[ "$IWAD" == "heretic" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/her-pal.wad"
        fi
    elif [[ "$IWAD" == "hexen" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/hex-pal.wad"
        fi
    fi
elif [[ $ENGINE == "prboom-plus" ]]; then
    if [[ "$IWAD" == *"doom"* || "$IWAD" == "tnt" || "$IWAD" == "plutonia" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad"
        fi
    elif [[ "$IWAD" == "heretic" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/her-pal.wad"
        fi
    elif [[ "$IWAD" == "hexen" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/hex-pal.wad"
        fi
    fi
else
    if [[ "$IWAD" == *"doom"* || "$IWAD" == "tnt" || "$IWAD" == "plutonia" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad"
        fi
    elif [[ "$IWAD" == "heretic" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/her-pal.wad"
        fi
    elif [[ "$IWAD" == "hexen" ]]; then
        if [[ $MODS_TYPE == "none" ]]; then
            MODS=""
        elif [[ $MODS_TYPE == "vanilla" ]]; then
            MODS="$GAME_DIR/mods/vanilla/dimm_pal/hex-pal.wad"
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
        commandline="chocolate-doom -fullscreen -iwad $IWADS_DIR/$IWAD.wad -merge $pwadfile $MODS -savedir $GAME_DIR/savegames/$IWAD/ -skill 3 -warp $pwadmap"
    elif [[ "$IWAD" == "heretic" ]]; then
        commandline="chocolate-heretic -fullscreen -iwad $IWADS_DIR/$IWAD.wad -merge $pwadfile $MODS -savedir $GAME_DIR/savegames/$IWAD/ -skill 3 -warp $pwadmap"
    elif [[ "$IWAD" == "hexen" ]]; then
        commandline="chocolate-hexen -fullscreen -iwad $IWADS_DIR/$IWAD.wad -merge $pwadfile $MODS -savedir $GAME_DIR/savegames/$IWAD/ -skill 3 -warp $pwadmap"
    fi
elif [[ $ENGINE == "crispy" ]]; then
    if [[ "$IWAD" == *"doom"* || "$IWAD" == "tnt" || "$IWAD" == "plutonia" ]]; then
        commandline="crispy-doom -fullscreen -iwad $IWADS_DIR/$IWAD.wad -file $pwadfile $MODS -savedir $GAME_DIR/savegames/$IWAD/ -skill 3 -warp $pwadmap"
    elif [[ "$IWAD" == "heretic" ]]; then
        commandline="crispy-heretic -fullscreen -iwad $IWADS_DIR/$IWAD.wad -file $pwadfile $MODS -savedir $GAME_DIR/savegames/$IWAD/ -skill 3 -warp $pwadmap"
    elif [[ "$IWAD" == "hexen" ]]; then
        commandline="crispy-hexen -fullscreen -iwad $IWADS_DIR/$IWAD.wad -file $pwadfile $MODS -savedir $GAME_DIR/savegames/$IWAD/ -skill 3 -warp $pwadmap"
    fi
elif [[ $ENGINE == "prboom-plus" ]]; then
    #commandline="prboom-plus -vidmode gl -complevel 17 -width 1920 -height 1080 -fullscreen -geom 640x360f -aspect 16:9 -iwad $IWADS_DIR/$IWAD.wad -file $pwadfile $MODS -save $GAME_DIR/savegames/$IWAD/ -skill 3 -warp $pwadmap"
    commandline="prboom-plus -vidmode gl -complevel 17 -width 1920 -height 1080 -fullscreen -aspect 16:9 -iwad $IWADS_DIR/$IWAD.wad -file $pwadfile $MODS -save $GAME_DIR/savegames/$IWAD/ -skill 3 -warp $pwadmap"
elif [[ $ENGINE == "gzdoom" ]]; then
    commandline="gzdoom -width 1920 -height 1080 -fullscreen -iwad $IWADS_DIR/$IWAD.wad -file $pwadfile $MODS -savedir $GAME_DIR/savegames/$IWAD/ -skill 3 -warp $pwadmap"
fi

# Run
if [[ $MANGOHUD_ENABLED == "yes" ]]; then
    mangohud $commandline
else
    $commandline
fi

# Check played times in external file
played_times=$(cat ./already_played_maps.txt | grep -w -c ${play_combination})

echo "### Random game settings"
echo "IWAD              : $IWAD"
echo "ENGINE            : $ENGINE"
echo "PWAD file         : $pwadfile"
echo "PWAD map number   : $pwadmap"
echo "MOD files         : $MODS"
echo "Full command line : $commandline"
echo ""
echo "Iwad/Engine/Map combination: ${play_combination}"
echo "Iwad/Engine/Map combination played ${played_times} times"
