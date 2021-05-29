version 4.5

const REPKUP_MAXRNG = 21;

class REItemGlow : Actor {
    Actor master;
    TextureID custom;
    int ticker;
    int tic;
    int frametime;
    int spriteindex;
    bool useicon;
    bool usecustom;
    string truesprite;
    string classname;
    float actualalpha;
    array<int> frames;
    static const string REPKUP_FRAMEINDEX[] = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"};

    void Debugger() {
        TextureID texid;
        bool temp;
        Vector2 scl;
        [texid, temp, scl] = master.CurState.NextState.GetSpriteTexture(master.SpriteRotation);
        let n = TexMan.GetName(texid);
        Console.PrintF(string.format("%s %d %d", n, scl.x, scl.y));
    }

    bool CheckIfTNT(State base) {
        return (TexMan.GetName(base.GetSpriteTexture(master.SpriteRotation)) != "TNT1A0");
    }

    override void BeginPlay() {
        ticker = 0;
        alpha  = 0;
        frame  = 0;
    }

    override void Tick() {
        Super.Tick();

        if (master) {
            // Hide if no sprite
            if (
                master.CurState.sprite == 0 &&
                !(useicon && !Inventory(master).owner)
            ) {
                alpha = 0;
                return;
            }

            // Fade in
            if (alpha < repkup_alpha) {
                alpha += repkup_fadein;
            }
            // Just in case
            if (alpha >= repkup_alpha) {
                alpha = repkup_alpha;
            }

            // Don't always do math stuff
            ticker++;
            if (ticker >= repkup_updatetic) {
                TextureID id;

                // What a thrill...
                if (usecustom) {
                    id = custom;
                } else if (useicon && Inventory(master).icon) {
                    id = Inventory(master).icon;
                } else if (
                    master.ResolveState("spawn") &&
                    CheckIfTNT(master.ResolveState("spawn"))
                ) {
                    id = master.ResolveState("spawn").GetSpriteTexture(master.SpriteRotation);
                } else if (
                    master.CurState &&
                    CheckIfTNT(master.CurState)
                ) {
                    id = master.CurState.NextState.GetSpriteTexture(master.SpriteRotation);
                } else if (
                    master.CurState.NextState &&
                    CheckIfTNT(master.CurState.NextState)
                ) {
                    id = master.CurState.NextState.GetSpriteTexture(master.SpriteRotation);
                } else {
                    // fuck it
                    scale  = (1, 1);
                }

                if (id) AdjustSprite(id);
                ticker = 0;
            }
            // Make sure halo thing is on the item
            if (master.pos != pos) {
                SetOrigin(master.pos, true);
            }
        } else {
            if (repkup_debug) Console.PrintF(string.Format("Bye, %s!", classname));
            Destroy();
        }
    }

    void ResetTic() {
        // please stop aborting vm thanks
        if (tic == frames.Size()) {
            tic = 0;
        }
    }

    void AdjustSprite(TextureID texid) {
        let size    = TexMan.GetScaledSize(texid);
        let offset  = TexMan.GetScaledOffset(texid);
        let m_scale = master.scale;
        if (repkup_overridescale) {
            scale = (repkup_scalex, 1);
        } else {
            ResetTic();
            let sprite_name = string.Format("%s%s0", truesprite, REPKUP_FRAMEINDEX[frames[tic]]);
            let s = TexMan.GetScaledSize(TexMan.CheckForTexture(sprite_name));
            let sc = (size.x / s.x * m_scale.x);
            scale = (sc+0.05, 1);
        }
        SpriteOffset = ((offset.x - int(size.x / 2)) * -1 * m_scale.x, 0);
    }

    // Should be called every tick
    action void A_DoAnimate() {
        // not taking any chances here
        invoker.ResetTic();
        invoker.sprite = invoker.spriteindex;
        invoker.frame = invoker.frames[invoker.tic];
        invoker.A_SetTics(invoker.frametime);
        invoker.tic++;
        invoker.ResetTic();
    }

    Default {
        +Actor.NOBLOCKMAP
        +Actor.NOINTERACTION
        +Actor.NOGRAVITY
        +Actor.FORCEYBILLBOARD
        -Actor.RANDOMIZE
        FloatBobPhase 0; // i have no clue what this is, but it uses rng and causes desyncs in online play
        RenderStyle "Translucent";
    }

    States {
        Spawn:
            TNT1 A 1 A_DoAnimate();
            loop;
    }
}

class REUselessThingJustForLoadingSprites : Actor {
    States {
        Spawn: REPK A 0; stop;// i have to use REPKA0 here, because sprites won't load in, unless you use them
    }
}

class REItemThinker : Thinker {
    array<string> classes;
    array<int> frames;
    TextureID custom;
    string sprite;
    int frametime;
    bool useicon;
    bool usecustom;
}

// Where the actors are assigned to each other
class REItemHandler : StaticEventHandler {
    bool temp_no_glows;
    bool no_glows;
    int timer;
    int rngtic;

    // Checks if the class exists
    bool CheckClass(string s) {
        class a;
        a = s;
        return (a);
    }

    // Say goodbye to all your glows :[
    void ClearAll() {
        // Remove all info thinkers
        let infos = ThinkerIterator.Create("REItemThinker");
        let info = infos.Next();
        while (info) {
            info.Destroy();
            info = infos.Next();
        }

        infos.Destroy();

        DeleteGlows();
    }

    void ReloadThinkers() {
        WorldEvent e;
        WorldLoaded(e);
    }

    // Remove all glows
    void DeleteGlows() {
        let glows = ThinkerIterator.Create("REItemGlow");
        let glow = glows.Next();
        while (glow) {
            glow.Destroy();
            glow = glows.Next();
        }

        glows.Destroy();
    }

    void ReloadAllItemGlows() {
        DeleteGlows();

        let actors = ThinkerIterator.Create("Actor");
        let a = actors.Next();
        while (a) {
            let infos = ThinkerIterator.Create("REItemThinker");
            let info = infos.Next();
            while (info) {
                let found = SummonGlow(REItemThinker(info), Actor(a));

                // Don't keep looping after found
                if (found) break;
                info = infos.Next();
            }

            a = actors.Next();
            infos.Destroy();
        }

        actors.Destroy();
    }

    int GetRNGTic() {
        rngtic++;
        // Don't overflow
        if (rngtic >= REPKUP_MAXRNG) {
            rngtic = 0;
        }
        return rngtic;
    }

    // Because desyncs aren't fun
    int PseudoRNG(int min, int max) {
        // Yes, these are the digits of pi
        int rngtable[REPKUP_MAXRNG] = {3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8, 9, 7, 9, 3, 2, 3, 8, 4, 6};

        int result = min + rngtable[GetRNGTic()];
        while (result > max) {
            result -= rngtable[GetRNGTic()];

            if (result < min) {
                return min;
            }
        }
        return result;
    }

    // Returns true if successfully summoned
    bool SummonGlow(REItemThinker info, Actor T) {
        bool found = false;
        for (int i = 0; i < info.classes.Size(); i++) {
            if (T is info.classes[i]) {
                // Is this a blacklisted item?
                if (info.sprite == "TNT1") {
                    // Don't spawn anything
                    found = true;
                    break;
                }
                if (repkup_debug) {
                    if (info.useicon) console.printf("USE ICON");
                    console.PrintF("Found"..T.GetClassName());
                }

                // Set variables
                let glow = REItemGlow(Actor.Spawn("REItemGlow", T.pos));
                glow.master = T;
                glow.truesprite  = info.sprite;
                glow.spriteindex = Actor.GetSpriteIndex(info.sprite);
                glow.classname   = T.GetClassName();
                glow.frames.Copy(info.frames);
                glow.frametime = info.frametime;
                glow.useicon   = info.useicon;
                glow.usecustom = info.usecustom;
                glow.custom    = info.custom;
                glow.tic       = PseudoRNG(0, info.frametime); //Random(0, info.frametime);
                found = true;
                break;
            }
        }

        return found;
    }

    // Also known as the group parser
    override void WorldLoaded(WorldEvent e) {
        if (no_glows) {
            return;
        }

        let infos = ThinkerIterator.Create("REItemThinker");
        let info = infos.Next();
        while (info) {
            info.Destroy();
            info = infos.Next();
        }

        // Get all the stuff
        array<string> contents; contents.Clear();

        let lump = Wads.FindLump("repkup_groups");
        Wads.ReadLump(lump).split(contents, "\n");

        for (int i = 0; i < contents.Size(); i++) {
            array<string> temp; temp.Clear();
            array<string> i_temp; i_temp.Clear();
            array<string> c_temp; c_temp.Clear();

            contents[i].Split(temp, ":");
            // Does it have enough arguments?
            if (temp.Size() < 4) {
                if (temp.Size() != 0 && i != (contents.Size() - 1)) {
                    Console.PrintF("Group at line "..i + 1..." provided "..temp.Size().." arguments, but a minimum of 4 is required.");
                    Console.PrintF("Ignoring group at line"..i + 1);
                }
                continue;
            }

            // Just in case
            bool is_null = false;
            for (int a = 0; a < temp.Size(); a++) {
                if (temp[a] == "") {
                    Console.PrintF("Group at line "..i + 1..." provided "..temp.Size().." arguments, but argument "..a + 1..." is null.");
                    Console.PrintF("Ignoring group at line "..i + 1);
                    is_null = true;
                    break;
                }
            }

            // Skip if an argument is null
            if (is_null) continue;

            let t = new("REItemThinker");
            temp[0].Split(c_temp, ",");
            t.sprite = temp[1];
            temp[2].Split(i_temp, ",");
            t.frametime = temp[3].ToInt(10);

            if (temp.Size() > 4) {
                let flag = temp[4];
                if (flag == "USEICON") {
                    t.useicon = true;
                } else if (flag == "USECUSTOM") {
                    if (temp.Size() > 5) {
                        t.usecustom = true;
                        t.custom = TexMan.CheckForTexture(temp[5]);
                    } else {
                        Console.PrintF(string.Format("Group at line %d used flag \"usecustom\", but didn't provide an argument afterwards.\nIgnoring flag.", i+1));
                    }
                } else {
                    Console.PrintF(string.Format("Group at line %d used an invalid flag.\nIgnoring flag.", i+1));
                }
            }

            // If there's an invalid class, just remove it
            for (int i = 0; i < c_temp.Size(); i++) {
                if (CheckClass(c_temp[i])) {
                    t.classes.Push(c_temp[i]);
                }
            }

            for (int i = 0; i < i_temp.Size(); i++) {
                t.frames.Push(i_temp[i].ToInt(10));
            }

            let iter = ThinkerIterator.Create("REItemThinker");
        }
    }

    override void WorldThingSpawned(WorldEvent e) {
        if (no_glows || level.maptime < 2) return;
        let T = e.Thing;

        let infos = ThinkerIterator.Create("REItemThinker");
        let info = infos.Next();
        while (info) {
            let found = SummonGlow(REItemThinker(info), T);

            // Don't keep looping after found
            if (found) break;
            info = infos.Next();
        }

        infos.Destroy();
    }

    override void NetworkProcess(ConsoleEvent e) {
        // Commands are fun
        if (e.name ~== "repkup_reload") {
            // Hope you don't mind the lag
            if (no_glows) {
                no_glows = false;
                Console.PrintF("Pickup glows enabled. Use \"repkup_clear\" to disable pickup glows.");
            }
            Console.PrintF("Reloading repkup_groups.txt...");
            ReloadThinkers();
            Console.PrintF("Reloading all glow effects...");
            ReloadAllItemGlows();
        } else if (e.name ~== "repkup_clear") {
            if (timer > 0) {
                ClearAll();
                no_glows = true;
                Console.PrintF("Pickup glows disabled. Use \"repkup_reload\" to enable pickup glows.");
                timer = 0;
            } else {
                Console.PrintF("You're about to disable all pickup glows.");
                Console.PrintF("Please re-enter \"repkup_clear\" again in 30 seconds to confirm that you actually want to do this.");
                timer = 1050;
            }
        }
    }

    override void WorldTick() {
        // Player's inventory doesn't initialize immediately, curse you inventory system.
        // Also, I have no idea why, but if I summoned the glows when maptime = 0, the pistol will overlay the glow.
        // Why is this a thing???
        // Better safe than sorry, I guess.
        // Hopefully the player doesn't drop anything during the very first tic :]
        if (level.maptime == 2 && !no_glows) {
            // No need for complex stuff, just do a quick reload ;]
            ReloadAllItemGlows();
        }

        if (timer > 0) timer--;

        if (temp_no_glows) {
            temp_no_glows = false;
            Console.PrintF("Reloading repkup_groups.txt...");
            ReloadThinkers();
            Console.PrintF("Reloading all glow effects...");
            ReloadAllItemGlows();
        }

        // Don't save glows and thinkers
        if (
            !no_glows &&
            repkup_nosave &&
            (gameaction == ga_savegame || gameaction == ga_autosave)
        ) {
            temp_no_glows = true;
            ClearAll();
        }
    }
}
