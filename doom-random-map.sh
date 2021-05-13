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
  echo "    map limit          -> vanilla | limit-removing | boom | zdoom | slige | oblige"
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
#map_limit=(vanilla limit-removing boom zdoom)
#if [[ " "${map_limit[@]}" " != *" $3 "* ]]; then
#  echo "$3: not recognized. Valid map limits are:"
#  echo "${map_limit[@]/%/,}"
#  exit 1
#fi

### Configuration
GAME_DIR=~/games/doom
IWADS_DIR=$GAME_DIR/wads/iwads
IWAD=$1
ENGINE=$2
MAP_LIMIT=$3

### Script
get_map_file() {
    if [[ ! -z $MAP_LIMIT ]]; then
        pwadfile=$(find $GAME_DIR/wads/$IWAD/$MAP_LIMIT/*/*.wad ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* -type f 2>/dev/null | shuf -n 1)
    elif [[ $ENGINE == "chocolate" ]]; then
        pwadfile=$(find $GAME_DIR/wads/$IWAD/vanilla/*/*.wad ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* -type f 2>/dev/null | shuf -n 1)
    elif [[ $ENGINE == "crispy" ]]; then
        pwadfile=$(find $GAME_DIR/wads/$IWAD/{vanilla,limit_removing}/*/*.wad ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* -type f 2>/dev/null | shuf -n 1)
    elif [[ $ENGINE == "prboom-plus" ]]; then
        pwadfile=$(find $GAME_DIR/wads/$IWAD/{vanilla,limit_removing,boom}/*/*.wad ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* -type f 2>/dev/null | shuf -n 1)
    elif [[ $ENGINE == "gzdoom" ]]; then
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

# You can have separate mods "sets" for the source ports
if [[ $ENGINE == "gzdoom" ]]; then
    if [[ "$IWAD" == *"doom"* || "$IWAD" == "tnt" || "$IWAD" == "plutonia" ]]; then
        #MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/jovian_palette/JovPal.wad $GAME_DIR/mods/zdoom/vanilla_essence/vanilla_essence_4_3.pk3"
        #MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/jovian_palette/JovPal.wad $GAME_DIR/mods/zdoom/vanilla_essence/vanilla_essence_4_3.pk3"
        MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad $GAME_DIR/mods/zdoom/vanilla_essence/vanilla_essence_4_3.pk3"
    elif [[ "$IWAD" == "heretic" ]]; then
        #MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/jovian_palette/JovPal.wad $GAME_DIR/mods/zdoom/vanilla_essence/vanilla_essence_4_3.pk3"
        MODS="$GAME_DIR/mods/vanilla/dimm_pal/her-pal.wad $GAME_DIR/mods/zdoom/brutal/brutal_heretic/Heretic-Shadow_Collection/1_BRUTAL_HERETIC/BrutalHereticRPG_V2.2.pk3"
    elif [[ "$IWAD" == "hexen" ]]; then
        #MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/jovian_palette/JovPal.wad $GAME_DIR/mods/zdoom/vanilla_essence/vanilla_essence_4_3.pk3"
        MODS="$GAME_DIR/mods/vanilla/dimm_pal/hex-pal.wad $GAME_DIR/mods/zdoom/vanilla_essence/vanilla_essence_4_3.pk3"
    fi
    #MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/jovian_palette/JovPal.wad $GAME_DIR/mods/vanilla/smoothed/smoothed.wad $GAME_DIR/mods/zdoom/vanilla_essence/vanilla_essence_4_3.pk3"
elif [[ $ENGINE == "chocolate" ]]; then
    if [[ "$IWAD" == *"doom"* || "$IWAD" == "tnt" || "$IWAD" == "plutonia" ]]; then
        #MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/jovian_palette/JovPal.wad"
        MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad"
    elif [[ "$IWAD" == "heretic" ]]; then
        MODS="$GAME_DIR/mods/vanilla/dimm_pal/her-pal.wad"
    elif [[ "$IWAD" == "hexen" ]]; then
        MODS="$GAME_DIR/mods/vanilla/dimm_pal/hex-pal.wad"
    fi
elif [[ $ENGINE == "crispy" ]]; then
    if [[ "$IWAD" == *"doom"* || "$IWAD" == "tnt" || "$IWAD" == "plutonia" ]]; then
        #MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/jovian_palette/JovPal.wad"
        MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad"
    elif [[ "$IWAD" == "heretic" ]]; then
        MODS="$GAME_DIR/mods/vanilla/dimm_pal/her-pal.wad"
    elif [[ "$IWAD" == "hexen" ]]; then
        MODS="$GAME_DIR/mods/vanilla/dimm_pal/hex-pal.wad"
    fi
elif [[ $ENGINE == "prboom-plus" ]]; then
    #MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/jovian_palette/JovPal.wad"
    MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad"
else
    #MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/jovian_palette/JovPal.wad $GAME_DIR/mods/vanilla/smoothed/smoothed.wad"
    #MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad $GAME_DIR/mods/vanilla/smoothed/smoothed.wad"
    MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/dimm_pal/doom-pal.wad"
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
$commandline

echo "### Random game settings"
echo "IWAD              : $IWAD"
echo "ENGINE            : $ENGINE"
echo "PWAD file         : $pwadfile"
echo "PWAD map number   : $pwadmap"
echo "MOD files         : $MODS"
echo "Full command line : $commandline"
