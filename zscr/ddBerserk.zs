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
		Powerup.Duration -80;
		Powerup.Color "ff 00 00", 0.2;
	}
	
	override void DetachFromOwner()
	{
		Super.DetachFromOwner();
		if(owner) { owner.A_StartSound("skull/melee", CHAN_BODY, CHANF_OVERLAP, 1., ATTN_NONE, 0.5); }
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

//special item dropped when killing during berserk. increases berserk time. disappears once berserk ends.
class EssenceOfHate : Inventory
{
	ddPlayer guyWhoSpawnedMe;
	Default
	{
		+DROPPED;
		Inventory.Amount 1;
		Inventory.MaxAmount 1;
		Inventory.PickupSound "misc/mmmm";
		RenderStyle "Add";
		Alpha 1.;
	}
		
	void CheckSpawner()
	{
		if(!guyWhoSpawnedMe) { GoAwayAndDie(); return; }
		if(guyWhoSpawnedMe.FindInventory("PowerBerserk") == null)
		{
			SetState(FindState('FadeAway')); return;
		}
	}
	
	override bool CanPickup(Actor toucher)
	{
		if(toucher.FindInventory("PowerBerserk") == null) { return false; }
		if(toucher != guyWhoSpawnedMe) { return false; }
		return true;
	}
	
	override bool TryPickup(in out Actor toucher)
	{		
		if(toucher != guyWhoSpawnedMe) { return false; }
		let bz = PowerBerserk(guyWhoSpawnedMe.FindInventory("PowerBerserk"));
		if(!bz) { return false; }
		bz.effecttics = clamp(bz.effecttics + (35*random(2, 5)), 0, 2100);
		GoAwayAndDie();
		return true;
	}
	
	void FadeFromWorld() { self.Alpha -= 0.1; if(self.Alpha <= 0) { GoAwayAndDie(); } }
	
	States
	{
		Spawn:
			DOOM ABC 4 bright CheckSpawner();
			Loop;
		FadeAway:
			DOOM ABCABCABCAB 4 FadeFromWorld();
			TNT1 A -1;
			Stop;
	}
}