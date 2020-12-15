#!/bin/bash


# Don't use space in file names as delimeter
IFS=$'\n'

input_bbg_root_folder="C:\Users\vango\Documents\My Games\Sid Meier's Civilization VI\Mods\BBGLocal"

# Root folder for BBG
bbg_root_folder="${input_bbg_root_folder//\\//}"
# Our completed translations
#  This is what we check to see if anything is missing
bbg_translation_folder="${bbg_root_folder}/lang"
bbg_translation_files=(`find "$bbg_translation_folder"`)

# Find our usages, ignore the translation files and hidden folders
bbg_source_files=(`find "$bbg_root_folder" -name "*.xml" -o -name "*.sql" -o -name "*.lua" | grep -v "$bbg_translation_folder" | grep -v "$bbg_root_folder/\." `)

function find_locs_in_file () {
    local file=$1
    # matches=(`grep -P "['\"](LOC.*)['\"]" "$1" |  sed -r "s/^.*['\"](LOC[\A-Za-z0-9_]*)['\"].*$/\1/g"`)
    matches=(`grep -P "['\"]\{?(LOC.*)\}?['\"]" "$1" | tr "\"'{}" "\n" |   grep -P ".*(LOC[A-Za-z0-9_]*).*" | sed -r "s/^.*['\"](LOC[\A-Za-z0-9_]*)['\"].*$/\1/g"`)
}

# Source LOCs: find all LOCs used in BBG
source_locs=()
for elem in "${bbg_source_files[@]}"
do 
    echo "Processing $elem..."
    find_locs_in_file "$elem" 
    echo "Found ${#matches[@]} locs..."
    for match in "${matches[@]}"
    do
        source_locs+=($match)
    done
    echo "${source_locs[@]}"
    echo "Total locs ${#source_locs[@]} ..."
done

# #Completed translations: Iterate through translation files
# completed_translations=()
# for elem in "${bbg_translation_files[@]}"
# do 
#     echo "Processing $elem..."
#     find_locs_in_file "$elem" 
#     echo "Found ${#matches[@]} translations..."
#     for match in "${matches[@]}"
#     do
#         completed_translations+=($match)
#     done
#     echo "Total translations ${#completed_translations[@]} ..."
# done

# file="C:/Users/vango/Documents/My Games/Sid Meier's Civilization VI/Mods/BBGLocal/lang/english.xml"
# echo "$file"

# matches=(`grep -P '\"(LOC.*)\"' "$file" |  sed -r 's/^.*\"(LOC[\A-Za-z0-9_]*)\".*$/\1/g'`)
# echo ${matches[1]}

# find_locs_in_file "C:/Users/vango/Documents/My Games/Sid Meier's Civilization VI/Mods/BBGLocal/sql/xp2__gathering_storm.sql"
# printf '%s\n' "${matches[@]}"