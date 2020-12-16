#!/bin/bash

# Don't use space in file names as delimeter
IFS=$'\n'

# input_root_game_folder="E:\Steam\steamapps\common\Sid Meier's Civilization VI"
# input_bbg_root_folder="C:\Users\vango\Documents\My Games\Sid Meier's Civilization VI\Mods\BBGLocal"
POSITIONAL=()
while [[ $# -gt 0 ]]
    do
    key="$1"

    case $key in
        --root|-root)
        input_root_game_folder="$2"
        shift # past argument
        shift # past value
        ;;
        --bbg|-bbg)
        input_bbg_root_folder="$2"
        shift # past argument
        shift # past value
        ;;
        *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters
echo "${input_root_game_folder}"
echo "${input_bbg_root_folder}"

# Settings
cache_dir="./cache"

# Setup cache dir
mkdir -p "$cache_dir"

# Root game folders
game_root_folder="${input_root_game_folder//\\//}"

# Base translation files
game_base_text_folder="$game_root_folder/Base/Assets/Text/"
game_base_translation_files=(`find $game_base_text_folder -name "*.xml"`)

# DLC translation files
game_dlc_root_folder="$game_root_folder/DLC"
game_dlc_translation_files=(`find  $game_dlc_root_folder -name "*.xml" | grep "/Text"`)

 
echo "# of base game translation files: ${#game_base_translation_files[@]}"
echo "# of base dlc  translation files: ${#game_dlc_translation_files[@]}"


# Root folder for BBG
bbg_root_folder="${input_bbg_root_folder//\\//}"

# Our completed translations
#  This is what we check to see if anything is missing
bbg_translation_folder="${bbg_root_folder}/lang"
bbg_translation_files=(`find "$bbg_translation_folder" -name "*.xml" `)

# Find our usages, ignore the translation files and hidden folders
bbg_source_files=(`find "$bbg_root_folder" -name "*.xml" -o -name "*.sql" -o -name "*.lua" | grep -v "$bbg_translation_folder" | grep -v "$bbg_root_folder/\." `)

function find_locs_in_file () {
    local file=$1
    # matches=(`grep -P "['\"](LOC.*)['\"]" "$1" |  sed -r "s/^.*['\"](LOC[\A-Za-z0-9_]*)['\"].*$/\1/g"`)
    matches=(`grep -P "['\"]\{?(LOC.*)\}?['\"]" "$1" | tr "\"'{}" "\n" |   grep -P ".*(LOC[A-Za-z0-9_]*).*" | sed -r "s/^.*['\"](LOC[\A-Za-z0-9_]*)['\"].*$/\1/g" | sort -u`)
}

function find_locs_in_files () {
    echo "Processing ${#@} files..."
    for elem in $@
    do 
        find_locs_in_file "$elem" 
        for match in "${matches[@]}"
        do
            locs+=($match)
        done  
    done
}

# Source LOCs: find all LOCs used in BBG
find_locs_in_files ${bbg_source_files[@]}
source_locs=( "${locs[@]}" )
echo "Found ${#source_locs[@]} LOCs..."

# Get and cache DLC translations
DLC_CACHE_FILENAME="$cache_dir/dlc_translations.temp"
if test -f "$DLC_CACHE_FILENAME"; then
    dlc_translations=( `cat "$DLC_CACHE_FILENAME" | tr " " "\n" `)
else
    find_locs_in_files ${game_dlc_translation_files[@]}
    dlc_translations=( "${locs[@]}" )
    touch "$DLC_CACHE_FILENAME" 
    echo "${dlc_translations[@]}" > "$DLC_CACHE_FILENAME"
fi
echo "DLC Translations: ${#dlc_translations[@]} ..."


# Get and cache Base translations
BASE_CACHE_FILENAME="$cache_dir/base_translations.temp"
if test -f "$BASE_CACHE_FILENAME"; then
    base_translations=( `cat "$BASE_CACHE_FILENAME" | tr " " "\n" `)
else
    find_locs_in_files ${game_base_translation_files[@]}
    base_translations=( "${locs[@]}" )
    touch "$BASE_CACHE_FILENAME" 
    echo "${base_translations[@]}" > "$BASE_CACHE_FILENAME"
fi
echo "Base translations: ${#base_translations[@]} ..."


# Get all current BBG Translations
find_locs_in_files ${bbg_translation_files[@]}
bbg_translations=( "${locs[@]}" )


##############################################################################
### Test #1: Ensure all used locs (source_locs) from BBG have some translation
##############################################################################

# Check if all source_locs are in the file
for loc in "${source_locs[@]}"
do
    if [[ ! " ${bbg_translations[@]} " =~ " ${loc} " ]]; then
        if [[ ! " ${dlc_translations[@]} " =~ " ${loc} " ]]; then
            if [[ ! " ${base_translations[@]} " =~ " ${loc} " ]]; then
                # This LOC is not found in any translation set 
                echo "[ERROR] No translation found for $loc!!!" 
            fi
        fi
    fi
done  


##############################################################################
### Test #2: Check the master (english) bbg translations against other languages
##############################################################################

# Get english BBG translations
bbg_translation_file_master=`find "$bbg_translation_folder" | grep -i english`
echo "BBG Translation Master file: '${bbg_translation_file_master}'"
find_locs_in_file "$bbg_translation_file_master" 
master_translations=( "${matches[@]}" )


# Completed translations: Iterate through translation files
for elem in "${bbg_translation_files[@]}"
do 
    echo "Processing $elem..."
    find_locs_in_file "$elem" 
    localization_translations=( "${matches[@]}" )

    # Clear missing translations for this locale
    missing_translations=()

    # Check if english is missing a locale counterpart
    for loc in "${master_translations[@]}"
    do
        # Missing counterpart in this language
        if [[ ! " ${localization_translations[@]} " =~ " ${loc} " ]]; then
            missing_translations+=($loc);
        fi
    done  

    # Print results
    echo "Missing ${#missing_translations[@]} translations: "
    printf  '\t%s\n' "${missing_translations[@]}"
done
