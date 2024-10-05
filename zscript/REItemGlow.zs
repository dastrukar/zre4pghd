class REItemGlow : Actor
{
	Actor Master;
	TextureID CustomTex;
	string CustomTranslation;
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

		// DoAnimate() Logic, runs on every tick anyways
		ResetTic();
		Sprite = SpriteIndex;
		A_SetTranslation(CustomTranslation);
		Frame = Frames[FrameTic];
		A_SetTics(FrameTime);
		FrameTic++;
		ResetTic();

		if (!Master)
		{
			if (repkup_debug)
				Console.PrintF(string.Format("Bye, %s!", ClassName));

			Destroy();
			return;
		}

		// Hide if no sprite
		if (
			Master.CurState.Sprite == 0 &&
			!(UseIcon && Inventory(Master) &&
			!Inventory(Master).Owner)
		)
		{
			Alpha = 0;
			return;
		}

		// Make sure halo thing is on the item
		if (Master.pos != pos)
			SetOrigin(Master.pos, true);

		if (
			repkup_userendist &&
			RenderTimer <= 0
		)
		{
			// Fade out
			if (Alpha > 0)
				Alpha = Max(0, Alpha - repkup_fadeout);
			return;
		}

		if (RenderTimer > 0)
			RenderTimer--;

		// Fade in
		if (Alpha < repkup_alpha)
			Alpha = Min(Alpha + repkup_fadein, repkup_alpha);

		// Don't always do math stuff
		Ticker++;
		if (Ticker >= repkup_updatetic)
		{
			TextureID id;

			// What a thrill...
			if (UseCustom)
				id = CustomTex;

			else if (UseIcon && Inventory(Master).icon)
				id = Inventory(Master).icon;

			else if (
				Master.ResolveState("spawn") &&
				CheckIfTNT(Master.ResolveState("spawn"))
			)
				id = Master.ResolveState("spawn").GetSpriteTexture(Master.SpriteRotation);

			else if (
				Master.CurState &&
				CheckIfTNT(Master.CurState)
			)
				id = Master.CurState.GetSpriteTexture(Master.SpriteRotation);

			if (id)
				AdjustSprite(id);

			else
				Scale = (1, 1);

			if (repkup_overridescale)
				Scale = (repkup_scalex, repkup_scaley);

			Ticker = 0;
		}
	}

	private void ResetTic()
	{
		// please stop aborting vm thanks
		if (FrameTic == Frames.Size())
			FrameTic = 0;
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

	Default
	{
		+Actor.NOGRAVITY
		+Actor.FORCEYBILLBOARD
		+Actor.SYNCHRONIZED
		-Actor.RANDOMIZE
		Radius 0;
		Height 0;
		FloatBobPhase 0; // i have no clue what this is, but it uses rng and causes desyncs in online play
		RenderStyle "Add";
	}

	States
	{
		PreCache:
			REPK A 0;
		Spawn:
			TNT1 A 1;
			loop;
	}
}
