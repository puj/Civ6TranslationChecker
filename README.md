# Civ6TranslationChecker

This tool has two goals:  
1. Check if any translations LOC_* used in BBG are missing translations  
2. Check if any languages in BBG are missing translations that are already in English  

## Usage:
### Parameters
-bbg - Path the BBG Mod 
-root - Path to the root Civ6 directory in steam
```
$ ./loc_tool.sh -bbg "<path_to_bbg_mod>" --root "<path_to_steam_common>/Sid Meier's Civilization VI"
```


Some sample output
```
Processing C:/Users/vango/Documents/My Games/Sid Meier's Civilization VI/Mods/BBGLocal/lang/portuguese.xml...  
Missing 15 translations: 
        LOC_ABILITY_TRAIT_MAPUCHE_DESCRIPTION
        LOC_ABILITY_TRAIT_MAPUCHE_NAME
        ...
```