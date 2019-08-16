# Enhanced Builtin Commands
Adds intllib support for builtin commands (and adds other features).

## Installation
- Unzip the archive, rename the folder to enhanced_builtin_commands and
place it in ..minetest/mods/

- GNU/Linux: If you use a system-wide installation place
    it in ~/.minetest/mods/.

- If you only want this to be used in a single world, place
    the folder in ..worldmods/ in your world directory.

For further information or help, see:
https://wiki.minetest.net/Installing_Mods

## Dependencies
There are no dependencies.   
#### Optional dependencies are:
- [intllib](https://github.com/minetest-mods/intllib)

## Features
This mod overrides all builtin-chatcommands to add support for intllib (currently, there's only translation for spanish).   
You can also run some commands for other players (optional):

```
/admin player1
```
That will show the server administrator to `player1`.  
Commands such as `/mods, /pulverize, /status` and `/days` do the same.

## Requirements
This mod works fine with MT/MTG 5.0.0+ (may work on older versions).

## License
[LGPLv2.1](https://Panquesito7/enhanced-builtin-commands/LICENSE) for everything.

## Issues, bugs, and feature requests
Pull requests and issues are welcome.  
Create a pull request if you want to add more languages.  

This mod works fine, but may have some minimal issues that I haven't noticed.
