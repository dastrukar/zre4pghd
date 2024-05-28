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
		foreach (info : _infoList)
		{
			info.Destroy();
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

		let actors = ThinkerIterator.Create("Actor");
		let a = actors.Next();
		while (a)
		{
			foreach (info : _infoList)
			{
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
		if (_rngTic >= REPKUP_MAXRNG)
			_rngTic = 0;

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

			if (result < min)
				return min;
		}
		return result;
	}

	// Returns true if successfully summoned
	private bool SummonGlow(REItemInfo info, Actor T)
	{
		bool found = false;
		foreach (cls : info.Classes)
		{
			if (T is cls)
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
					if (info.UseIcon)
						Console.PrintF("USE ICON");

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
				glow.CustomTranslation = info.CustomTranslation;
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

		let lumpNum = -1;
		while ((lumpNum = Wads.FindLump("repkup_groups", lumpNum + 1)) >= 0)
		{
			Array<string> lumpLines;
			lumpLines.Clear();

			let lt = Wads.ReadLump(lumpNum);
			lt.split(lumpLines, "\n");

			foreach (line : lumpLines)
			{
				// Remove excess newline and return characters
				line.Replace("\r", "");
				line.Replace("\n", "");

				// Remove tabs & spaces
				line.Replace("\t", "");
				line.Replace(" ", "");

				if (line != "") {
					contents.push(line);
					if (hd_debug) Console.PrintF("Adding Line '"..line.."'... ");
				}
			}
		}

		// Format = ITEM_CLASS:SPRITE:TRANSLATION:FRAMES:FRAME_TIME:FLAGS
		for (int i = 0; i < contents.Size(); i++)
		{
			Array<string> temp;
			Array<string> iTemp;
			Array<string> cTemp;

			contents[i].Split(temp, ":");
			// Does it have enough arguments?
			if (temp.Size() < 5)
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
			t.CustomTranslation = temp[2];
			temp[3].Split(iTemp, ",");
			t.FrameTime = temp[4].ToInt(10);

			if (temp.Size() > 5)
			{
				let flag = temp[5];

				if (flag == "USEICON")
				{
					t.UseIcon = true;

				}
				else if (flag == "USECUSTOM")
				{
					if (temp.Size() > 6)
					{
						t.UseCustom = true;
						t.CustomTex = TexMan.CheckForTexture(temp[6]);
					}
					else
						Console.PrintF(string.Format("Group at line %d used flag \"USECUSTOM\", but didn't provide an argument afterwards.\nIgnoring flag.", i + 1));
				}
				else
					Console.PrintF(string.Format("Group at line %d used an invalid flag.\nIgnoring flag.", i + 1));
			}

			// If there's an invalid class, just remove it
			foreach (c : cTemp)
			{
				if (CheckClass(c))
					t.Classes.Push(c);

				foreach (j : _infoList)
				{
					let prevClass = j.Classes.Find(c);
					if (prevClass < j.Classes.Size())
					{
						j.Classes.Delete(prevClass);
						// break;
					}
				}
			}

			foreach (i : iTemp)
			{
				t.Frames.Push(i.ToInt(10));
			}

			_infoList.Push(t);
		}
	}

	override void WorldThingSpawned(WorldEvent e)
	{
		if (_noGlows && !_hasReloaded)
			return;

		let T = e.Thing;
		foreach (info : _infoList)
		{
			bool found = SummonGlow(info, T);

			// Don't keep looping after found
			if (found)
				break;
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
			let it = BlockThingsIterator.Create(players[ConsolePlayer].mo, repkup_renderdistance);
			while (it.Next())
			{
				if (it.Thing.GetClassName() == "REItemGlow")
					REItemGlow(it.Thing).RenderTimer = 10;
			}
		}
	}

	override void WorldLoaded(WorldEvent e)
	{
		_hasReloaded = false;
	}
}

