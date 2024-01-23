// #Class ddPowerFist : ddFist()
//Impactor Gauntlet by TheDoomedArchvile. Edits by me. Very slow, powerful ddFist weapon
//Pressing left and right simultaneous swings both fists at once.
class ddPowerFist : ddFist
{	
	
	Default
	{
		Weapon.Kickback 42000;
		Weapon.AmmoType1 "NotAnAmmo";
		Weapon.AmmoType2 "NotAnAmmo";
		ddWeapon.ClassicAmmoType1 "NotAnAmmo";
		ddWeapon.ClassicAmmoType2 "NotAnAmmo";
		Weapon.AmmoUse1 0;
		Weapon.AmmoUse2 0;
		DDWeapon.SwitchSpeed 1.8;
		-DDWEAPON.GOESININV;
		ddWeapon.WeaponType "Fist";		
		Obituary "%o was knocked out powerfully by %k";
		Tag "Power Fist";
	}
	
	override String GetIconSprite()
	{
		return "ICPFST";
	}
	
	override String, int GetSprites()
	{
		return "IMPAA0";
	}
	
	override String GetWeaponSprite()
	{
		return "";
	}
	
	override String GetParentType()
	{
		return "ddPowerFist";
	}
	
	override void primaryattack() { A_PowerPunch(); }
	
	override void DD_Condition(int cn)
	{
		int caseno = cn;
		let ddp = ddPlayer(owner);
		let pspl = ddp.player.GetPSprite(PSP_LEFTW);
		let psplf = ddp.player.GetPSprite(PSP_LEFTWF);
		let pspr = ddp.player.GetPSprite(PSP_RIGHTW);
		let psprf = ddp.player.GetPSprite(PSP_RIGHTWF);
		let me = ddWeapon(self);
		let cpiece = ddWeapon(me.companionpiece);
		int myside = (weaponside) ? PSP_LEFTW : PSP_RIGHTW;
		int flashside = (weaponside) ? PSP_LEFTWF : PSP_RIGHTWF;
		switch(caseno)
		{
			case 0: //init/ready check
				if(PressingLeftFire() && PressingRightFire())
				{
					if(me is "ddPowerFist" && cpiece is "ddPowerFist") { 
						if(me.weaponside) { pspl.SetState(me.FindState("Double")); }
						else { pspr.SetState(me.FindState("Double")); }
						if(cpiece.weaponside) { pspl.SetState(cpiece.FindState("Double")); }
						else { pspr.SetState(cpiece.FindState("Double")); }
						break;
					}
				}
				if(weaponside)
				{
					if(!(ddp.ddWeaponState & DDW_RIGHTREADY)) { ChangeState("NoAmmo", myside); }
					else { 
						if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("Left fist attack blocked by right attack"); } 
					}
				}
				else
				{
					if(!(ddp.ddWeaponState & DDW_LEFTREADY)) { ChangeState("NoAmmo", myside); }
					else {
						if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("Right fist attack blocked by left attack"); } 
					}
				}			
				break;
			default: break;
		}
	}
	
	// ## ddPowerFist States()
	States
	{
		NoAmmo:
			PFST A 10;
		Ready:
			PFST A 1;
			Loop;
		Deselect:
			PUNG A 1 A_Lower;
			Loop;
		Select:
			PFST A 1;
			Loop;
		Fire:
			Goto Ready;
		Altfire:
			Goto Ready;
		Double:
			Goto Ready;
	}
}
// #Class ddPowerFistLeft : ddPowerFist()
class ddPowerFistLeft : ddPowerFist
{
	Default
	{		
		-DDFIST.ADDME;
		ddweapon.weaponside CE_LEFT;
	}
	States
	{
		NoAmmo:
			PFSF A 10;
		Ready:
			PFSF A 1 A_LeftWeaponReady;
			Loop;
		Select:
			PFSF A 1;
			Loop;
		Fire:
			PFSF AA 0 A_ddActionLeft;
			//PFSF A 0 A_ddActionLeft;
			PFSF BC 2;
			PFSF D 3 A_PFist1;
			PFSF E 5 A_PFist2;
			PFSF F 5 A_FireLeftWeapon;
			PFSF G 3;
			PFSF H 3;
			TNT1 A 6;
			PFSF CB 4;
			PFSF A 0 A_ddRefireLeft;
			Goto Ready;
		Double:
			PFSF BC 2;
			PFSF D 3 A_PFist1;
			PFSF E 5 A_PFist2;
			PFSF F 5 A_FireLeftWeapon;
			PFSF G 5;
			PFSF H 5;
			TNT1 A 6;
			PFSF CB 7;
			PFSF A 0 A_ddRefireLeft;
			Goto Ready;
	}
}
// #Class ddPowerFistRight : ddPowerFist()
class ddPowerFistRight : ddPowerFist
{
	Default
	{		
		-DDFIST.ADDME;
		ddweapon.weaponside CE_RIGHT;
	}
	States
	{
		NoAmmo:
			PFST A 10;
		Ready:
			PFST A 1 A_RightWeaponReady;
			Loop;
		Select:
			PFST A 1;
			Loop;
		Fire:
			PFST AA 0 A_ddActionRight;
			//PFST A 0 A_ddActionRight;
			PFST BC 2;
			PFST D 3 A_PFist1;
			PFST E 5 A_PFist2;
			PFST F 5 A_FireRightWeapon;
			PFST G 3;
			PFST H 3;
			TNT1 A 6;
			PFST CB 4;
			PFST A 0 A_ddRefireRight;
			Goto Ready;
		Double:
			PFST BC 2;
			PFST D 3 A_PFist1;
			PFST E 5 A_PFist2;
			PFST F 5 A_FireRightWeapon;
			PFST G 5;
			PFST H 5;
			TNT1 A 6;
			PFST CB 7;
			PFST A 0 A_ddRefireRight;
			Goto Ready;
	}
}

extend class ddWeapon
{	
	action void A_PowerPunch()
	{
		let ddp = ddPlayer(invoker.owner);
		FTranslatedLineTarget t;
		if(ddp.player == null) { return; }

		int damage = random[Punch](50, 70) << 1;

		double ang = ddp.angle + Random2[Punch]() * (5.625 / 256);

		ddp.LineAttack(ang, 64, ddp.pitch, damage, 'Melee', "BulletPuff", LAF_ISMELEEATTACK, t);

		// turn to face target
		if(t.linetarget)
		{
			ddp.A_StartSound ("*fist", CHAN_WEAPON);
			angle = t.angleFromSource;
		}
	}
	
	action void A_PFist1() { A_StartSound("weapons/powfist1", CHAN_WEAPON, CHANF_OVERLAP); }
	action void A_PFist2() { A_StartSound("weapons/powfist2", CHAN_WEAPON, CHANF_OVERLAP); }
}

// #Class PowerFist : CustomInventory()
class PowerFist : CustomInventory
{
	Default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 1;
		Inventory.PickupMessage "You found some Powerfists!";
		Inventory.PickupSound "misc/secret";
		-INVENTORY.INVBAR;
		+INVENTORY.UNTOSSABLE;
		+INVENTORY.UNDROPPABLE;	
	}
	
	States
	{	
		Spawn:
			POWF A -1;
			Stop;
		Pickup:
			TNT1 A 1 A_GiveInventory("ddPowerFist", 1);
			TNT1 A 0 A_GiveInventory("ddPowerFistLeft", 1);
			TNT1 A 0 A_GiveInventory("ddPowerFistRight", 1);
			Stop;
	}
	
}
