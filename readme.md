# RE4-like Pickup Glow for Hideous Destructor
> Also knowns as RE4PGHD

A simple mod that adds Resident Evil 4/5 styled glowing thing on pickups.

It should be noted that this mod was made with Hideous Destructor in mind.\
Although, this mod could possibly work with other mods if tweaked correctly.

## Default item colours
* **WHITE**: Skull keys and Computer Maps (keycards not included due to weird bug)
* **GREEN**: Medical stuff
* **BLUE**: Weapons and armour
* **RED**: Ammo and any other pickups


## Syntax for custom stuff

All custom stuff goes into `repkup_groups.txt`.

*I hope you're using a monospace font while reading this.*
```
<CLASS1>,[CLASS2],[CLASS3],[CLASS4],...:<SPRITENAME>:<FRAME1>,[FRAME2],[FRAME3],[FRAME4],...:<TICS>:[FLAG]


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
The name of the sprite.

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
