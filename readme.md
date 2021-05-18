# RE4-like Pickup Glow for Hideous Destructor
> Also known as zRE4PGHD

A simple mod that adds Resident Evil 4/5 styled glowing thing on pickups.

This mod is intended to run with Hideous Destructor.\
While it can technically run without it, it's not recommended.

Known issues:
* After completing a map, the player's items *might* have their sprite appear in front of the glow, instead of being behind it. I still have no idea why this occurs. *(can be fixed by using "repkup_reload")*

## Default item colours
* **WHITE**: Skull keys and Computer Maps (keycards not included due to weird bug)
* **GREEN**: Medical stuff
* **LIGHT BLUE**: Armour and backpacks
* **BLUE**: Weapons
* **RED**: Ammo and any other pickups

## Console commands
* `repkup_reload`: Reloads all glow effects and groups. *(may cause lag)*
* `repkup_clear`: Removes all glow effects. Disables the mod.

*Note: Latest version breaks save? Just use `repkup_clear` before updating! (provided the version you have has it)*

## Direct link for mobile users
[`Latest master`](https://github.com/dastrukar/zre4pghd/archive/refs/heads/master.zip)

## Custom stuff
All custom stuff goes into `repkup_groups.txt`.

### Syntax:
*I hope you're using a monospace font while reading this.*
```
<CLASS1>,[CLASS2],[CLASS3],[CLASS4],...:<SPRITENAME>:<FRAME1>,[FRAME2],[FRAME3],[FRAME4],...:<TICS>:[FLAG]:[FLAGARG]


Terrible explanation:

     SPRITENAME
         ||
         ||
        /  \
        TNT1A0
            ^
            |
            |
          FRAME

```

`CLASS`\
The class name.


`SPRITENAME`\
The name of the sprite.\
If the sprite used is `TNT1A0`, the group becomes a blacklist.

For example:
* TNT1A0's name would be, "TNT1".
* REPKA0's name would be, "REPK".


`FRAME`\
The frame index.\
Must use integers.\

For example, `A` would be represented as `0`. `B` would be `1`, `C` would be `2`, and so on.


### Flags
`USEICON`\
If stated, will use the given `CLASS` inventory icon for scaling and offset.

Note: You should probably make a dummy actor that uses your sprites, else it might not load in.

`USECUSTOM`\
If stated, will use the given `ICON` for scaling and offset.

The following syntax will also apply:
```
<CLASS1>,[CLASS2],[CLASS3],[CLASS4],...:<SPRITENAME>:<FRAME1>,[FRAME2],[FRAME3],[FRAME4],...:<TICS>:USECUSTOM:<ICON>
```
