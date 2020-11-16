#!/bin/sh

# exit when any command fails
#set -e

### Configuration
GAME_DIR=~/games/doom
IWADS_DIR=$GAME_DIR/wads/original
USAGE_MESSAGE="Usage: doom-random-map.sh <doom|doom2|tnt|plutonia> <chocolate-doom|crispy-doom|prboom-plus|gzdoom> <vanilla|limit_removing|boom|zdoom>(Optional)"
if [[ $1 == "--help" || $1 == "-h" ]]; then
    echo $USAGE_MESSAGE
    exit 1
fi
if [[ -z $1 ]]; then
    echo $USAGE_MESSAGE
    exit 1
else
    IWAD=$1
fi
if [[ -z $2 ]]; then
    echo $USAGE_MESSAGE
    exit 1
else
    ENGINE=$2
fi
if [[ ! -z $3 ]]; then
    echo $PWAD_DIR
fi

### Script
get_map_file() {
    if [[ ! -z $PWAD_DIR ]]; then
        pwadfile=$(find $GAME_DIR/wads/$IWAD/$PWAD_DIR/*/*.wad ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* -type f 2>/dev/null | shuf -n 1)
    elif [[ $ENGINE == "chocolate-doom" ]]; then
        pwadfile=$(find $GAME_DIR/wads/$IWAD/vanilla/*/*.wad ! -name *tex*.* ! -name *res*.* ! -name *fix.* ! -name *demo*.* -type f 2>/dev/null | shuf -n 1)
    elif [[ $ENGINE == "crispy-doom" ]]; then
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
    gzdoom -iwad $IWADS_DIR/$IWAD.wad -file $pwadfile -norun -hashfiles > /dev/null

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
    MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/jovian_palette/JovPal.wad $GAME_DIR/mods/vanilla/smoothed/smoothed.wad $GAME_DIR/mods/zdoom/vanilla_essence/vanilla_essence_4_3.pk3"
elif [[ $ENGINE == "chocolate-doom" ]]; then
    MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/jovian_palette/JovPal.wad"
else
    MODS="$GAME_DIR/mods/vanilla/pk_doom_sfx/pk_doom_sfx_20120224.wad $GAME_DIR/mods/vanilla/jovian_palette/JovPal.wad $GAME_DIR/mods/vanilla/smoothed/smoothed.wad"
fi

if [[ $ENGINE == "chocolate-doom" ]]; then
    commandline="chocolate-doom -fullscreen -iwad $IWADS_DIR/$IWAD.wad -merge $pwadfile $MODS -savedir $GAME_DIR/savegames/$IWAD/ -skill 3 -warp $pwadmap"
elif [[ $ENGINE == "crispy-doom" ]]; then
    commandline="crispy-doom -fullscreen -iwad $IWADS_DIR/$IWAD.wad -file $pwadfile $MODS -savedir $GAME_DIR/savegames/$IWAD/ -skill 3 -warp $pwadmap"
elif [[ $ENGINE == "prboom-plus" ]]; then
    commandline="prboom-plus -vidmode gl -complevel 17 -width 1920 -height 1080 -fullscreen -geom 640x360f -aspect 16:9 -iwad $IWADS_DIR/$IWAD.wad -file $pwadfile $MODS -save $GAME_DIR/savegames/$IWAD/ -skill 3 -warp $pwadmap"
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
