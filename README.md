# Enhanced Builtin Commands
Adds intllib support for builtin commands (and adds other features).  
Enhanced Builtin Commands is _Rolling Release_, which means you can use the latest commits without fear.

## Installation
- Unzip the archive, rename the folder to enhanced_builtin_commands and
place it in .. minetest/mods/ ..

- GNU/Linux: If you use a system-wide installation place
    it in ~/.minetest/mods/.

- If you only want this to be used in a single world, place
    the folder in .. worldmods/ .. in your world directory.

For further information or help, see:  
https://wiki.minetest.net/Installing_Mods

## Dependencies
- [intllib](https://github.com/minetest-mods/intllib)
### Optional dependencies
- sethome (included in [minetest_game](https://github.com/minetest/minetest_game))
- game_commands (included in [minetest_game](https://github.com/minetest/minetest_game))

## Features
This mod overrides all builtin-chatcommands to add support for intllib (currently, there's only translation for spanish).   
You can also run some commands for other players (optional):

```
/admin player1
```
That will show the server administrator to `player1`.  
The command `/mods, /pulverize, /status` and `/days` can also do the same.

## Requirements
This mod works fine with MT/MTG 5.0.0+ (may work on older versions).

## License
[LGPLv2.1](https://Panquesito7/enhanced_builtin_commands/LICENSE) for everything.

## Issues, bugs, and feature requests
Pull requests and [issues](https://github.com/Panquesito7/enhanced_builtin_commands/issues/new/choose) are welcome.  
Create a [pull request](https://github.com/Panquesito7/enhanced_builtin_commands/compare) if you want to add new features.
