version 4.5

class REItemHalo : Actor {
    Actor master;
    int ticker;
    float actualalpha;

    void Debugger() {
        TextureID texid;
        bool temp;
        Vector2 scl;
        [texid, temp, scl] = master.CurState.NextState.GetSpriteTexture(master.SpriteRotation);
        let n = TexMan.GetName(texid);
        console.printf(string.format("%s %d %d", n, scl.x, scl.y));
    }

    override void BeginPlay() {
        ticker = 0;
        alpha  = 0;
        actualalpha = 0.50;
    }

    override void Tick() {
        Super.Tick();
        if (master) {
            // Hide if no sprite
            if (master.CurState.sprite == 0) { alpha = 0; return; }
            if (alpha < actualalpha) alpha += 0.001; // Fade in

            // Don't always do math stuff
            ticker++;
            if (ticker == 16) {
                if (master.CurState.ValidateSpriteFrame()) {
                    AdjustScale();
                    ticker = 0;
                }
            }
            // Make sure halo thing is on the item
            if (master.pos != pos) {
                SetOrigin(master.pos, true);
            }
        }
        else destroy();
    }

    void AdjustScale() {
        //let n = master.GetClassName();
        let texid = master.CurState.GetSpriteTexture(master.SpriteRotation);
        let s = TexMan.GetScaledSize(texid);
        let m_scale = master.scale;
        //console.printf(string.format("%d %d %s %s", s.x, s.y, TexMan.GetName(texid), n));
        let sc = (s.x / 30 * m_scale.x);
        scale = (sc, 1);
    }

    Default {
        +Actor.NOBLOCKMAP
        +Actor.NOGRAVITY
        +Actor.FORCEYBILLBOARD
        RenderStyle "Translucent";
    }

    States {
        Spawn:
            TNT1 A 0 A_Jump(128, 5);
            TNT1 A 0 A_Jump(128, 5);
            TNT1 A 0 A_Jump(128, 1);
        Animate:
            REPK ABCB 3;
            loop;
    }
}

class REIHAmmo : REItemHalo {
    States {
        Spawn:
            TNT1 A 0 A_Jump(128, 5);
            TNT1 A 0 A_Jump(128, 5);
            TNT1 A 0 A_Jump(128, 1);
        Animate:
            REPK DEFE 3;
            loop;
    }
}

class REIHWeap : REItemHalo {
    States {
        Spawn:
            TNT1 A 0 A_Jump(128, 5);
            TNT1 A 0 A_Jump(128, 5);
            TNT1 A 0 A_Jump(128, 1);
        Animate:
            REPK GHIH 3;
            loop;
    }
}

class REIHHealth : REItemHalo {
    States {
        Spawn:
            TNT1 A 0 A_Jump(128, 5);
            TNT1 A 0 A_Jump(128, 5);
            TNT1 A 0 A_Jump(128, 1);
        Animate:
            REPK JKLK 3;
            loop;
    }
}

// Where the actors are assigned to each other
class REItemHandler : EventHandler {
    override void WorldThingSpawned(WorldEvent e) {
        let T = e.Thing;

        bool is_health = (
            T is "PortableMedikit" ||
            T is "HDInjectorMaker" ||
            T is "HDWoundFixer"
        );
        bool is_blue = (
            T is "HDUPK" ||
            T is "HDAmmo" ||
            T is "HDPickup"
        );

        if (is_health) {
            let halo = REItemHalo(Actor.Spawn("REIHHealth", T.pos));
            halo.master = T;
        } else if (is_blue) {
            let halo = REItemHalo(Actor.Spawn("REIHAmmo", T.pos));
            halo.master = T;
        } else if (T is "Weapon") {
            let halo = REItemHalo(Actor.Spawn("REIHWeap", T.pos));
            halo.master = T;
        } else if (T is "Inventory") {
            let halo = REItemHalo(Actor.Spawn("REItemHalo", T.pos));
            halo.master = T;
        }
    }
}
