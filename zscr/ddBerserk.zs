// #Class ddBerserk : Berserk replaces Berserk()
class ddBerserk : Berserk replaces Berserk
{
	Default
	{
		Inventory.PickupMessage "You feel invigorated...";
		Inventory.PickupSound "weapons/berserkget";
	}
	States
	{
		Pickup:
			TNT1 A 0 A_GiveInventory("PowerBerserk");
			TNT1 A 0 HealThing(100, 0);
			Stop;
	}
}

//time limited berserk
// #Class PowerBerserk : Powerup()
class PowerBerserk : Powerup
{
	Default
	{
		Powerup.Duration -60;
		Powerup.Color "ff 00 00", 0.2;
	}
	
	override void Tick()
	{
		Super.Tick();
		if(owner is "ddPlayerNormal") { if(effecttics == (35*3)) { owner.A_Log("Your muscles start to ache..."); owner.A_StartSound("weapons/berserkfade", CHAN_BODY, CHANF_OVERLAP); } }
		else { if(effecttics < 35) { effecttics = -1; } }
	}
	override color GetBlend ()
	{
		int cnt = effecttics;
		if (cnt < 350)
		{
			double mod = (cnt/350.);
			return Color((int)(BlendColor.a*mod),
				BlendColor.r, BlendColor.g, BlendColor.b);
		}
		return Color(BlendColor.a, BlendColor.r, BlendColor.g, BlendColor.b);
	}
	
	override bool isBlinking() const { return false; }
}