// #Class ddFist : ddWeapon replaces Fist()
//Doom Fists. Base ddFist weapon, used when selecting an empty weapon slot.
//being remade
class ddFist : ddWeapon replaces Fist
{	
	int fistFlags;
	flagdef base : fistFlags, 0; //wont be used directly, only used for making clones for left/right weapon slot [is this being used?]
	flagdef addMe : fistFlags, 1; //set true for parent types to be added to fInv, false for left/right counterparts
	Default
	{
		Weapon.AmmoType1 "NotAnAmmo";
		Weapon.AmmoType2 "NotAnAmmo";
		Weapon.AmmoUse1  0;
		Weapon.AmmoUse2  0;
		Weapon.Kickback 100;
		ddWeapon.rating 0;
		ddWeapon.SwitchSpeed 4;
		ddWeapon.WeaponType "Fist";
		-DDWEAPON.GOESININV;
		+WEAPON.NOALERT;
		+DDFIST.ADDME;
		Obituary "%o was knocked out by %k";
		Tag "$TAG_FIST";
	}
	
	override void InventoryInfo(ddStats ddhud, bool debug)
	{
		if(debug) { Super.InventoryInfo(ddhud, debug); return; }
		let hud = ddhud;
		hud.DrawString(hud.fa, GetTag(), (30, 45), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, "Fist Weapon", (30, 55), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
	}	
	
	override void AttachToOwner(Actor other)
	{
		Super.AttachToOwner(other);
		let ddp = ddPlayer(other);
		let fls = fistlist(ddp.FindInventory("FistList"));
		if(bAddMe) { fls.AddItem(ddWeapon(self), true); }
		else { if(ddp.dddebug & DBG_INVENTORY && ddp.dddebug & DBG_VERBOSE)ddp.A_Log("I, "..self.GetClassName()..", wasn't added!"); }
	}
	
	override State GetAttackState()
	{
		if(weaponside) { return FindState('Jab'); }
		else { return FindState('Hook'); }
	}
	
	override State GetRefireState()
	{
		if(weaponside) { return FindState('Jab'); }
		else { return FindState('Hook'); }
	}
	
	override String, int GetSprites(int no)
	{
		let ddp = ddPlayer(owner);
		if(!ddp) { return "TNT1A0", -1; }
		if(weaponside == CE_LEFT) { return "FSTLA0", 0; }
		else if(weaponside == CE_RIGHT) { return "FSTRA0", 0; }
		else { return "TNT1A0", -1; }
	}
	
	override void primaryattack()
	{	
		if(weaponside == CE_RIGHT)
		{
			if(!bAltFire) { A_ddHook(); }
		}
		else if(weaponside == CE_LEFT)
		{
			if(!bAltFire) { A_ddJab(); }
		}
		else {}
	}
	
	clearscope virtual String GetIconSprite()
	{
		return "ICFIST";
	}
	
	override String GetWeaponSprite()
	{
		return "";
	}
	
	override String GetParentType()
	{
		return "ddFist";
	}
	
	override void DD_WeapAction(int no)
	{
		let ddp = ddPlayer(owner);
		let pspl = ddp.player.GetPSprite(PSP_LEFTW0);
		let psplf = ddp.player.GetPSprite(PSP_LEFTWF0);
		let pspr = ddp.player.GetPSprite(PSP_RIGHTW0);
		let psprf = ddp.player.GetPSprite(PSP_RIGHTWF0);
		int myside = (weaponside) ? PSP_LEFTW0 : PSP_RIGHTW0; 
		int flashside = (weaponside) ? PSP_LEFTWF0 : PSP_RIGHTWF0;
		switch(no)
		{
			case 1: //init/ready check
				if(weaponside)
				{
					if(!(ddp.ddWeaponState & DDW_RIGHTREADY)) { ChangeState("Ready", myside); }
					else { 
						if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("Left fist attack blocked by right attack"); } 
					}
				}
				else
				{
					if(!(ddp.ddWeaponState & DDW_LEFTREADY)) { ChangeState("Ready", myside); }
					else {
						if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("Right fist attack blocked by left attack"); } 
					}
				}			
				break;			
			default: ddp.A_Log("No action defined for tic "..no); break;
		}
	}
	
	// ## ddFist States()	
	States
	{
		NoAmmo:
			PUNG B 10;
		Ready:
			PUNG A 0 A_ChangeSprite;
			#### A 1 A_DDWeaponReady;
			Loop;
		Select:
			PUNG A 0 A_ChangeSprite;
			#### A 1;
			Loop;
		Deselect:
			PUNG A 0 A_ChangeSprite;
			#### A 1;
			Loop;
		Fire:
			PUNG A 1;
			Loop;
		Jab:
			PUNG B 1 A_WeapAction;
			PUNG B 1;
			PUNG C 1 A_Whoosh;
			PUNG D 6 A_FireDDWeapon;
			PUNG C 1;
			PUNG B 4;
			PUNG B 3 A_DDRefire;	
			Goto Ready;
		Hook:
			TNT1 A 1 A_WeapAction;
			TNT1 A 2;
			PUNH A 1;
			PUNH B 2 A_Whoosh;
			PUNH CD 2;
			PUNH E 5 A_FireDDWeapon;
			PUNH FGH 2;
			TNT1 A 2;
			TNT1 A 2 A_DDRefire;
			Goto Ready;
		Two:
			PUNH AB 1;
			PUNH C 1 A_Whoosh;
			PUNH D 1;
			PUNH E 6 A_FireDDWeapon;
			PUNH FGH 2;
			TNT1 A 2;
			Goto Ready;
		Altfire:
			Goto Ready;
		FireClassic:
			PUNG B 4;
			PUNG C 4 A_FireDDWeapon;
			PUNG D 5;
			PUNG C 4;
			PUNG B 5 A_DDRefire;
			Goto Ready;
		Ind:
			FSTL A 1;
			FSTR A 1;
			Stop;
			
	}
}

extend class ddWeapon
{
	action void A_ddPunch()
	{
		let ddp = ddPlayer(invoker.owner);
		FTranslatedLineTarget t;
		if(ddp.player == null) { return; }
		int damage = random[Punch](1, 10) << 1;

		if(ddp.FindInventory("PowerBerserk")) { damage *= 10; }

		double ang = ddp.angle + Random2[Punch]() * (5.625 / 256);
		double range = ddp.MeleeRange + MELEEDELTA;
		double pitch = ddp.AimLineAttack(ang, range, null, 0., ALF_CHECK3D);

		ddp.LineAttack(ang, range, pitch, damage, 'Melee', "BulletPuff", LAF_ISMELEEATTACK, t);

		if(t.linetarget)
		{
			ddp.A_StartSound("*fist", CHAN_WEAPON);
			ddp.angle = t.angleFromSource;
		}
	}
	
	action void A_ddHook()
	{
		let ddp = ddPlayer(invoker.owner);
		FTranslatedLineTarget t;

		if(ddp.player == null) { return; }
		int damage = random[Punch](1, 20) << 1;

		if(ddp.FindInventory("PowerBerserk")) {	damage *= 10; }

		double ang = ddp.angle + Random2[Punch]() * (5.625 / 256);
		double range = ddp.MeleeRange + ddp.MELEEDELTA;
		double pitch = ddp.AimLineAttack(ang, range, null, 0., ALF_CHECK3D);
		ddp.LineAttack(ang, range, pitch, damage, 'Melee', "BulletPuff", LAF_ISMELEEATTACK, t);
		if(t.linetarget)
		{
			ddp.A_StartSound ("*fist", CHAN_WEAPON);
			ddp.angle = t.angleFromSource;
		}
		
	}
	action void A_ddJab()
	{
		let ddp = ddPlayer(invoker.owner);
		FTranslatedLineTarget t;

		if(ddp.player == null) { return; }
		int damage = random[Punch](1, 4) << 1;

		if(ddp.FindInventory("PowerBerserk")) {	damage *= 10; }

		double ang = ddp.angle + Random2[Punch]() * (5.625 / 256);
		double range = ddp.MeleeRange + ddp.MELEEDELTA;
		double pitch = ddp.AimLineAttack(ang, range, null, 0., ALF_CHECK3D);

		ddp.LineAttack(ang, range + 10, pitch, damage, 'Melee', "BulletPuff", LAF_ISMELEEATTACK, t);
		if(t.linetarget)
		{
			ddp.A_StartSound ("*fist", CHAN_WEAPON);
			ddp.angle = t.angleFromSource;
		}
	}
	
	action void A_Whoosh() { A_StartSound("weapons/fistswing", CHAN_WEAPON, CHANF_OVERLAP); }
	action void A_Whoosh2() { A_StartSound("weapons/fistswing", CHAN_WEAPON, CHANF_OVERLAP, 1.0, ATTN_NORM, 0.87); }
}