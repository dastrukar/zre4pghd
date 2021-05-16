version 4.5

class REItemHalo : Actor {
    Actor master;
    TextureID custom;
    int ticker;
    int time;
    int tic;
    int frametime;
    int truesprite;
    bool useicon;
    bool usecustom;
    string classname;
    float actualalpha;
    array<int> frames;

    CVar repkup_alpha;
    CVar repkup_fadein;

    void Debugger() {
        TextureID texid;
        bool temp;
        Vector2 scl;
        [texid, temp, scl] = master.CurState.NextState.GetSpriteTexture(master.SpriteRotation);
        let n = TexMan.GetName(texid);
        Console.PrintF(string.format("%s %d %d", n, scl.x, scl.y));
    }

    override void BeginPlay() {
        Super.BeginPlay();
        ticker = 0;
        tic    = random(0, frametime);
        alpha  = 0;
        frame  = 0;
        repkup_alpha  = CVar.GetCVar("repkup_alpha", players[consoleplayer]);
        repkup_fadein = CVar.GetCVar("repkup_fadein", players[consoleplayer]);
    }

    override void Tick() {
        Super.Tick();
        if (master) {
            // Hide if no sprite
            if (
                master.CurState.sprite == 0 &&
                !(useicon && !Inventory(master).owner) &&
                !usecustom
            ) {
                alpha = 0;
                return;
            }
            if (alpha < repkup_alpha.GetFloat()) alpha += repkup_fadein.GetFloat(); // Fade in
            if (alpha >= repkup_alpha.GetFloat()) alpha = repkup_alpha.GetFloat(); // Just in case

            // Don't always do math stuff
            ticker++;
            if (ticker == 16) {
                TextureID id;
                if (usecustom) {
                    id = custom;
                } else if (useicon && Inventory(master).icon) {
                    id = Inventory(master).icon;
                } else if (master.CurState.ValidateSpriteFrame()) {
                    id = master.CurState.GetSpriteTexture(master.SpriteRotation);
                } else if (master.CurState.NextState) {
                    id = master.CurState.NextState.GetSpriteTexture(master.SpriteRotation);
                } else {
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
            if (REItemHandler.CheckDebug()) console.PrintF(string.Format("Bye, %s!", classname));
            destroy();
        }
    }

    void AdjustSprite(TextureID texid) {
        //let n = master.GetClassName();
        let size    = TexMan.GetScaledSize(texid);
        let offset  = TexMan.GetScaledOffset(texid);
        let m_scale = master.scale;
        //console.printf(string.format("%d %d %s %s", s.x, s.y, TexMan.GetName(texid), n));
        let sc = (size.x / 30 * m_scale.x);
        scale = (sc+0.05, 1);
        SpriteOffset = ((offset.x - int(size.x / 2)) * -1 * m_scale.x, 0);
    }

    // Should be called every tick
    action void A_DoAnimate() {
        if (invoker.tic == invoker.frames.Size()) invoker.tic = 0;
        invoker.sprite = invoker.truesprite;
        invoker.frame = invoker.frames[invoker.tic];
        invoker.A_SetTics(invoker.frametime);
        invoker.tic++;
    }

    Default {
        +Actor.NOBLOCKMAP
        +Actor.NOGRAVITY
        +Actor.FORCEYBILLBOARD
        +Actor.RANDOMIZE
        RenderStyle "Translucent";
    }

    States {
        Spawn:
            TNT1 A 0 A_DoAnimate();
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
class REItemHandler : EventHandler {
    array<REItemThinker> thinkers;

    // Checks if the class exists
    bool CheckClass(string s) {
        class a;
        a = s;
        return (a);
    }

    static bool CheckDebug() {
        return CVar.GetCVar("repkup_debug", players[consoleplayer]).GetBool();
    }

    override void WorldLoaded(WorldEvent e) {
        // Just in case?
        thinkers.Clear();

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
                    Console.PrintF(string.Format("Group at line %d provided %d arguments, but a minimum of 4 is required.", i+1, temp.Size()));
                    Console.PrintF(string.Format("Ignoring group at line %d.", i+1));
                }
                continue;
            }

            // Just in case
            bool is_null = false;
            for (int a = 0; a < temp.Size(); a++) {
                if (temp[a] == "") {
                    Console.PrintF(string.Format("Group at line %d provided %d arguments, but argument %d is null.", i+1, temp.Size(), a+1));
                    Console.PrintF(string.Format("Ignoring group at line %d.", i+1));
                    is_null = true;
                    break;
                }
            }

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
            thinkers.Push(t);
        }
    }

    override void WorldThingSpawned(WorldEvent e) {
        let T = e.Thing;

        for (int i = 0; i < thinkers.Size(); i++) {
            let info = thinkers[i];

            bool found = false;
            for (int i = 0; i < info.classes.Size(); i++) {
                if (T is info.classes[i]) {
                    // Is this a blacklisted item?
                    if (info.sprite == "TNT1") {
                        // Don't spawn anything
                        found = true;
                        break;
                    }
                    if (CheckDebug()) {
                        if (info.useicon) console.printf("USE ICON");
                        console.PrintF(string.Format("Found %s", T.GetClassName()));
                    }
                    let halo = REItemHalo(Actor.Spawn("REItemHalo", T.pos));
                    halo.master = T;
                    halo.truesprite = Actor.GetSpriteIndex(info.sprite);
                    halo.classname  = T.GetClassName();
                    halo.frames.Copy(info.frames);
                    halo.frametime = info.frametime;
                    halo.useicon   = info.useicon;
                    halo.usecustom = info.usecustom;
                    halo.custom    = info.custom;
                    found = true;
                    break;
                }
            }

            // Don't keep looping if found
            if (found) break;
        }
    }
}
