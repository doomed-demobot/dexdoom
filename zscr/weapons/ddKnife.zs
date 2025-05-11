/* combos:
	quickjab : rp, rp, lp
*/
enum KnifeCombos
{
	COM_QUICK = 21,
};
// #Class ddKnife : ddFist()
//ddFist weapon. Quick attacks that only get 1/3 berserk bonus.
//Lefthand gets a stab, righthand get two quick slashes.
class ddKnife : ddFist
{
	Default
	{
		ddWeapon.SwitchSpeed 3;
		Weapon.AmmoType1 "NotAnAmmo";
		Weapon.AmmoType2 "NotAnAmmo";
		ddWeapon.ClassicAmmoType1 "NotAnAmmo";
		ddWeapon.ClassicAmmoType2 "NotAnAmmo";
		Weapon.AmmoUse1 0;
		Weapon.AmmoUse2 0;
		ddWeapon.WeaponType "Fist";
		+WEAPON.NOALERT;
		-DDWEAPON.GOESININV;
		Obituary "%o was mugged by %k";
		Tag "Knife";		
	}
	
	override String GetIconSprite()
	{
		return "ICKNFE";
	}
	
	override String, int GetSprites()
	{
		return "KNFGA0";
	}
	
	override String GetWeaponSprite()
	{
		return "";
	}
	
	override String GetParentType()
	{
		return "ddKnife";
	}	
	//a little hacky is it not?
	override State GetRefireState()
	{
		if(weaponside) { return Super.GetRefireState(); }
		else
		{
			return FindState('Fire');
		}
	}
	
	override void DD_WeapAction(int no)
	{		
		let ddp = ddPlayer(owner);
		let pspl = ddp.player.GetPSprite(PSP_LEFTW);
		let psplf = ddp.player.GetPSprite(PSP_LEFTWF);
		let pspr = ddp.player.GetPSprite(PSP_RIGHTW);
		let psprf = ddp.player.GetPSprite(PSP_RIGHTWF);
		int myside = (weaponside) ? PSP_LEFTW : PSP_RIGHTW; 
		int flashside = (weaponside) ? PSP_LEFTWF : PSP_RIGHTWF;
		switch(no)
		{
			case 1:
				if(weaponside) {
					if(ddp.combo == COM_QUICK) { ChangeState("QuickJab", myside); break; } 
					if(!(ddp.ddWeaponState & DDW_RIGHTREADY)) { ChangeState("Ready", myside); }
					else { 
						if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("Left fist attack blocked by right attack"); } 
					}
				}
				else {
					if(!(ddp.ddWeaponState & DDW_LEFTREADY)) { ChangeState("Ready", myside); }
					else {
						if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("Right fist attack blocked by left attack"); } 
					}				
				}
				break;				
			default: ddp.A_Log("No action defined for tic "..no); break;
		}
	}	
	
	// ## ddKnife States()
	States
	{
		NoAmmo:
			KNFR A 10;
		Ready:
			KNFR A 1;
			Loop;
		Select:
			Goto Ready;
		Deselect:
			Goto Ready;
		Fire:
			Goto Ready;
		AltFire:
			Goto Ready;
		
	}
}
// #Class ddKnifeLeft : ddKnife()
class ddKnifeLeft : ddKnife
{
	Default 
	{
		-DDFIST.ADDME;
		ddweapon.weaponside CE_LEFT; 
	}
	States
	{
		Ready:
			KNFL A 1 A_DDWeaponReady;
			Loop;
		Select:
			KNFL A 1;
			Loop;
		Fire:
			KNFL A 1 A_WeapAction;
			KNFL BC 2;
			KNFL CD 1;
			KNFL E 1 A_Whoosh2;
			KNFL F 4;
			KNFL G 4 A_Stab;
			KNFL HI 4;
			KNFL A 0 A_DDRefire;
			Goto Ready;
		QuickJab:
			KNFL C 0 A_ClearCombo;
			KNFL CD 1;
			KNFL E 1 A_Whoosh;
			KNFL F 1;
			KNFL G 5 A_Stab;
			KNFL HI 2;
			Goto Ready;
	}
}
// #Class ddKnifeRight : ddKnife()
class ddKnifeRight : ddKnife
{
	Default 
	{ 
		-DDFIST.ADDME;
		ddweapon.weaponside CE_RIGHT; 
	}
	States
	{
		Ready:
			KNFR A 1 A_DDWeaponReady;
			Loop;
		Select:
			KNFR A 1;
			Loop;
		Fire:
			KNFR A 1 A_WeapAction;
			KNFR BCD 1;
			KNFR E 1 A_Whoosh;
			KNFR F 2; 
			KNFR G 2 A_Slice;
			KNFR H 2;
			TNT1 A 2 A_DDRefire;
			KNFR MNO 1;
			Goto Ready;
		Fire2:
			KNFR I 1 A_Whoosh;
			KNFR J 2;
			KNFR K 2 A_Slice;
			KNFR L 2;
			TNT1 A 2 A_ComQuick;
			KNFR MNO 1;
			KNFR A 0 A_DDRefire;
			Goto Ready;
	}
}

// #Class Knife : CustomInventory()
class Knife : CustomInventory
{
	Default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 1;
		Inventory.PickupMessage "You found some Knives!";
		Inventory.PickupSound "misc/secret";
		-INVENTORY.INVBAR;
		+INVENTORY.UNTOSSABLE;
		+INVENTORY.UNDROPPABLE;	
	}
	
	States
	{	
		Spawn:
			KNIF E -1;
			Stop;
		Pickup:
			TNT1 A 1 A_GiveInventory("ddKnife", 1);
			TNT1 A 0 A_GiveInventory("ddKnifeLeft", 1);
			TNT1 A 0 A_GiveInventory("ddKnifeRight", 1);
			Stop;
	}
	
}

extend class ddWeapon
{
	
	action void A_Stab()
	{
		let ddp = ddPlayer(invoker.owner);
		FTranslatedLineTarget t;
		if(ddp.player == null) { return; }

		int damage = random[Punch](5, 18) << 1;

		if (FindInventory("PowerStrength")) { damage *= 3; }

		double ang = angle + Random2[Punch]() * (5.625 / 256);
		double range = MeleeRange + MELEEDELTA;
		double pitch = AimLineAttack (ang, range, null, 0., ALF_CHECK3D);

		LineAttack(ang, 64, pitch, damage, 'Melee', "BulletPuff", LAF_ISMELEEATTACK, t);
		if(t.linetarget)
		{
			ddp.bJustAttacked = true;
			A_StartSound ("*fist", CHAN_WEAPON);
			angle = t.angleFromSource;
		}
	}
	
	action void A_Slice()
	{
		let ddp = ddPlayer(invoker.owner);
		FTranslatedLineTarget t;
		if(ddp.player == null) { return; }

		int damage = random[Punch](5, 12) << 1;

		if (FindInventory("PowerStrength")) { damage *= 3; }

		double ang = angle + Random2[Punch]() * (5.625 / 256);
		double range = MeleeRange + MELEEDELTA;
		double pitch = AimLineAttack (ang, range, null, 0., ALF_CHECK3D);

		LineAttack(ang, 64, pitch, damage, 'Melee', "BulletPuff", LAF_ISMELEEATTACK, t);
		if(t.linetarget)
		{
			A_StartSound ("*fist", CHAN_WEAPON);
			angle = t.angleFromSource;
		}
	}
	
	action void A_ComQuick() { let ddp = ddPlayer(self); ddp.combo = COM_QUICK; ddp.comboTimer = 10; }
}