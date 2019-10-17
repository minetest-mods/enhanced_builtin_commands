# Enhanced Builtin Commands
Adds intllib support for builtin commands (and adds other features).  
Enhanced Builtin Commands is _Rolling Release_, which means you can use the latest commits without fear.

## Installation
- Unzip the archive, rename the folder to enhanced_builtin_commands and
place it in .. minetest/mods/

- GNU/Linux: If you use a system-wide installation place
    it in ~/.minetest/mods/.

- If you only want this to be used in a single world, place
    the folder in .. worldmods/ in your world directory.

For further information or help, see:  
https://wiki.minetest.net/Installing_Mods

## Dependencies
- [intllib](https://github.com/minetest-mods/intllib)

## Features
This mod overrides all builtin-chatcommands to add support for intllib (currently, there's only translation for spanish).   
You can also run some commands for other players (optional):

```
/admin player1
```
That will show the server administrator to `player1`.  
The command `/mods, /pulverize, /status` and `/days` can do the same, too.

## Requirements
This mod works with MT/MTG 5.0.0+.

## License
[LGPLv2.1+](https://minetest-mods/enhanced_builtin_commands/LICENSE) for everything.

## Issues, suggestions, features & bugfixes.
Report bugs or suggest ideas by [creating an issue](https://github.com/minetest-mods/enhanced_builtin_commands/issues/new/choose).    
If you know how to fix an issue, or want something to be added, consider opening a [pull request](https://github.com/minetest-mods/enhanced_builtin_commands/compare).

**Issue/PR templates are not required.**