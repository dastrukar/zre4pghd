version 4.5

class REItemGlow : Actor
{
	Actor Master;
	TextureID CustomTex;
	int RenderTimer;
	int Ticker;
	int FrameTic;
	int FrameTime;
	int SpriteIndex;
	bool UseIcon;
	bool UseCustom;
	string TrueSprite;
	string ClassName;
	Array<int> Frames;
	static const string REPKUP_FRAMEINDEX[] = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"};

	private void Debugger()
	{
		TextureID texId;
		bool temp;
		Vector2 scl;
		[texid, temp, scl] = Master.CurState.NextState.GetSpriteTexture(Master.SpriteRotation);
		string n = TexMan.GetName(texId);
		Console.PrintF(string.format("%s %d %d", n, scl.x, scl.y));
	}

	private bool CheckIfTNT(State base)
	{
		return (TexMan.GetName(base.GetSpriteTexture(Master.SpriteRotation)) != "TNT1A0");
	}

	override void BeginPlay()
	{
		Ticker = 0;
		Alpha = 0;
		Frame = 0;
		RenderTimer = 0;
		Scale = (0, 0);
	}

	override void Tick()
	{
		Super.Tick();

		if (Master)
		{
			// Hide if no sprite
			if (
				Master.CurState.Sprite == 0 &&
				!(UseIcon && Inventory(Master) && !Inventory(Master).Owner)
			)
			{
				Alpha = 0;
				return;
			}

			// Make sure halo thing is on the item
			if (Master.pos != pos)
			{
				SetOrigin(Master.pos, true);
			}

			if (
				repkup_userendist &&
				RenderTimer <= 0
			)
			{
				// Fade out
				if (Alpha > 0) Alpha = Max(0, Alpha - repkup_fadeout);
				return;
			}

			if (RenderTimer > 0) RenderTimer--;

			// Fade in
			if (Alpha < repkup_alpha) Alpha = Min(Alpha + repkup_fadein, repkup_alpha);

			// Don't always do math stuff
			Ticker++;
			if (Ticker >= repkup_updatetic)
			{
				TextureID id;

				// What a thrill...
				if (UseCustom)
				{
					id = CustomTex;
				}
				else if (UseIcon && Inventory(Master).icon)
				{
					id = Inventory(Master).icon;
				}
				else if (
					Master.ResolveState("spawn") &&
					CheckIfTNT(Master.ResolveState("spawn"))
				)
				{
					id = Master.ResolveState("spawn").GetSpriteTexture(Master.SpriteRotation);
				}
				else if (
					Master.CurState &&
					CheckIfTNT(Master.CurState)
				)
				{
					id = Master.CurState.GetSpriteTexture(Master.SpriteRotation);
				}

				if (id) AdjustSprite(id);
				else Scale = (1, 1);

				if (repkup_overridescale) Scale = (repkup_scalex, 1);

				Ticker = 0;
			}
		}
		else
		{
			if (repkup_debug) Console.PrintF(string.Format("Bye, %s!", ClassName));
			Destroy();
		}
	}

	private void ResetTic()
	{
		// please stop aborting vm thanks
		if (FrameTic == Frames.Size()) FrameTic = 0;
	}

	private void AdjustSprite(TextureID texid)
	{
		Vector2 size = TexMan.GetScaledSize(texid);
		Vector2 offset = TexMan.GetScaledOffset(texid);
		Vector2 mScale = Master.Scale;

		ResetTic();
		string spriteName = string.Format("%s%s0", TrueSprite, REPKUP_FRAMEINDEX[Frames[FrameTic]]);
		Vector2 s = TexMan.GetScaledSize(TexMan.CheckForTexture(spriteName));
		float sc = (size.x / s.x * mScale.x);
		Scale = (sc + 0.05, 1);

		SpriteOffset = ((offset.x - int(size.x / 2)) * -1 * mScale.x, 0);
	}

	// Should be called every tick
	private action void A_DoAnimate()
	{
		// not taking any chances here
		invoker.ResetTic();
		invoker.Sprite = invoker.SpriteIndex;
		invoker.Frame = invoker.Frames[invoker.FrameTic];
		invoker.A_SetTics(invoker.FrameTime);
		invoker.FrameTic++;
		invoker.ResetTic();
	}

	Default
	{
		+Actor.NOGRAVITY
		+Actor.FORCEYBILLBOARD
		+Actor.SYNCHRONIZED
		-Actor.RANDOMIZE
		Radius 0;
		Height 0;
		FloatBobPhase 0; // i have no clue what this is, but it uses rng and causes desyncs in online play
		RenderStyle "Translucent";
	}

	States
	{
		Spawn:
			TNT1 A 1 A_DoAnimate();
			loop;
	}
}

class REUselessThingJustForLoadingSprites : Actor
{
	States
	{
		Spawn:
			REPK A 0;
			Stop;// i have to use REPKA0 here, because sprites won't load in, unless you use them
	}
}

class REItemInfo
{
	Array<string> Classes;
	Array<int> Frames;
	TextureID CustomTex;
	string Sprite;
	int FrameTime;
	bool UseIcon;
	bool UseCustom;
}

const REPKUP_MAXRNG = 21;

// Where the actors are assigned to each other
class REItemHandler : StaticEventHandler
{
	private bool _noGlows;
	private bool _hasReloaded; // Used for starting reload
	private int _rngTic;
	private Array<REItemInfo> _infoList;
	static const int RNGTABLE[] = {3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8, 9, 7, 9, 3, 2, 3, 8, 4, 6};

	// Checks if the class exists
	private bool CheckClass(string s)
	{
		class a;
		a = s;
		return (a);
	}

	// Remove all info thinkers
	private void ClearGroups()
	{
		for (int i = 0; i < _infoList.Size(); i++)
		{
			_infoList[i].Destroy();
		}

		_infoList.Clear();
	}

	// Remove all glows
	private void DeleteGlows()
	{
		let glows = ThinkerIterator.Create("REItemGlow", Thinker.STAT_DEFAULT);
		let glow = glows.Next();
		while (glow)
		{
			glow.Destroy();
			glow = glows.Next();
		}

		glows.Destroy();
	}

	private void ReloadItemGlows()
	{
		Console.PrintF("Reloading all glow effects...");
		DeleteGlows();

		let actors = ThinkerIterator.Create("Actor", Thinker.STAT_DEFAULT);
		let a = actors.Next();
		while (a)
		{
			for (int i = 0; i < _infoList.Size(); i++)
			{
				REItemInfo info = _infoList[i];
				bool found = SummonGlow(info, Actor(a));

				// Don't keep looping after found
				if (found) break;
			}

			a = actors.Next();
		}

		actors.Destroy();
	}

	private int GetRNGTic()
	{
		_rngTic++;
		// Don't overflow
		if (_rngTic >= REPKUP_MAXRNG) _rngTic = 0;
		return _rngTic;
	}

	// Because desyncs aren't fun
	private int PseudoRNG(int min, int max)
	{
		// Yes, these are the digits of pi
		int result = min + RNGTABLE[GetRNGTic()];
		while (result > max)
		{
			result -= RNGTABLE[GetRNGTic()];

			if (result < min) return min;
		}
		return result;
	}

	// Returns true if successfully summoned
	private bool SummonGlow(REItemInfo info, Actor T)
	{
		bool found = false;
		for (int i = 0; i < info.Classes.Size(); i++)
		{
			if (T is info.Classes[i])
			{
				// Is this a blacklisted item?
				if (info.Sprite == "TNT1")
				{
					// Don't spawn anything
					found = true;
					break;
				}
				if (repkup_debug)
				{
					if (info.UseIcon) Console.PrintF("USE ICON");
					Console.PrintF("Hi, "..T.GetClassName());
				}

				// Set variables
				let glow = REItemGlow(Actor.Spawn("REItemGlow", T.pos));
				glow.Master = T;
				glow.TrueSprite = info.Sprite;
				glow.SpriteIndex = Actor.GetSpriteIndex(info.Sprite);
				glow.ClassName = T.GetClassName();
				glow.Frames.Copy(info.Frames);
				glow.FrameTime = info.FrameTime;
				glow.UseIcon = info.UseIcon;
				glow.UseCustom = info.UseCustom;
				glow.CustomTex = info.CustomTex;
				glow.FrameTic = PseudoRNG(0, info.FrameTime);
				found = true;
				break;
			}
		}

		return found;
	}

	private void ParseGroups()
	{
		Console.PrintF("Reloading repkup_groups.txt...");

		// Get all the stuff
		Array<string> contents;

		let lump = Wads.FindLump("repkup_groups");
		let lt = Wads.ReadLump(lump);
		lt.replace("\r\n", "\n");
		lt.split(contents, "\n");

		for (int i = 0; i < contents.Size(); i++)
		{
			Array<string> temp;
			Array<string> iTemp;
			Array<string> cTemp;

			contents[i].Split(temp, ":");
			// Does it have enough arguments?
			if (temp.Size() < 4)
			{
				if (temp.Size() != 0 && i != (contents.Size() - 1))
				{
					Console.PrintF("Group at line "..i + 1..." provided "..temp.Size().." arguments, but a minimum of 4 is required.");
					Console.PrintF("Ignoring group at line"..i + 1);
				}
				continue;
			}

			// Just in case
			bool isNull = false;
			for (int a = 0; a < temp.Size(); a++)
			{
				if (temp[a] == "")
				{
					Console.PrintF("Group at line "..i + 1..." provided "..temp.Size().." arguments, but argument "..a + 1..." is null.");
					Console.PrintF("Ignoring group at line "..i + 1);
					isNull = true;
					break;
				}
			}

			// Skip if an argument is null
			if (isNull) continue;

			let t = new("REItemInfo");
			temp[0].Split(cTemp, ",");
			t.Sprite = temp[1];
			temp[2].Split(iTemp, ",");
			t.FrameTime = temp[3].ToInt(10);

			if (temp.Size() > 4)
			{
				let flag = temp[4];
				if (flag == "USEICON")
				{
					t.UseIcon = true;
				}
				else if (flag == "USECUSTOM")
				{
					if (temp.Size() > 5)
					{
						t.UseCustom = true;
						t.CustomTex = TexMan.CheckForTexture(temp[5]);
					}
					else
					{
						Console.PrintF(string.Format("Group at line %d used flag \"USECUSTOM\", but didn't provide an argument afterwards.\nIgnoring flag.", i + 1));
					}
				}
				else
				{
					Console.PrintF(string.Format("Group at line %d used an invalid flag.\nIgnoring flag.", i + 1));
				}
			}

			// If there's an invalid class, just remove it
			for (int i = 0; i < cTemp.Size(); i++)
			{
				if (CheckClass(cTemp[i])) t.Classes.Push(cTemp[i]);
			}

			for (int i = 0; i < iTemp.Size(); i++)
			{
				t.Frames.Push(iTemp[i].ToInt(10));
			}

			_infoList.Push(t);
		}
	}

	override void WorldThingSpawned(WorldEvent e)
	{
		if (_noGlows && !_hasReloaded) return;
		let T = e.Thing;

		for (int i = 0; i < _infoList.Size(); i++)
		{
			REItemInfo info = _infoList[i];
			bool found = SummonGlow(info, T);

			// Don't keep looping after found
			if (found) break;
		}
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		// Commands are fun
		if (e.Name ~== "repkup_reload")
		{
			// Hope you don't mind the lag
			if (_noGlows)
			{
				_noGlows = false;
				Console.PrintF("Pickup glows enabled. Use \"repkup_clear\" to disable pickup glows.");
			}

			ParseGroups();
			ReloadItemGlows();
		}
		else if (e.Name ~== "repkup_clear")
		{
			ClearGroups();
			DeleteGlows();
			_noGlows = true;
			Console.PrintF("Pickup glows temporarily disabled. Use \"repkup_reload\" to enable pickup glows.");
		}
	}

	override void WorldTick()
	{
		if (
			!_noGlows &&
			!_hasReloaded
		)
		{
			// No need for complex stuff, just do a quick reload ;]
			_hasReloaded = true;

			ParseGroups();
			ReloadItemGlows();
		}

		// Don't save glows and thinkers (does not work if the game is paused)
		if (
			!_noGlows &&
			repkup_nosave &&
			(gameaction == ga_savegame || gameaction == ga_autosave)
		)
		{
			// Force a reload after deleting
			_hasReloaded = false;

			Console.PrintF("Removing all glow effects...");
			ClearGroups();
			DeleteGlows();
		}

		// Render distance
		if (repkup_userendist)
		{
			BlockThingsIterator it = BlockThingsIterator.Create(players[ConsolePlayer].mo, repkup_renderdistance);
			while (it.Next())
			{
				if (it.Thing.GetClassName() == "REItemGlow")
				{
					REItemGlow(it.Thing).RenderTimer = 10;
				}
			}
		}
	}

	override void WorldLoaded(WorldEvent e)
	{
		_hasReloaded = false;
	}
}
