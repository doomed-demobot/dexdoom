// #Class ddShotgun : ddWeapon
//Doom Shotgun. Mag must be reloaded after every shot. Weapon must be lower to reload.
//No altfire, but altfire goes to primary

enum ddShotgunFlags
{
	SHT_RSEQ = 1 << 1,
};

class ddShotgun : ddWeapon
{
	Default
	{
		Weapon.SelectionOrder 1300;
		Weapon.AmmoUse 1;
		Weapon.AmmoGive 8;
		Weapon.AmmoUse2 1;
		Weapon.AmmoType "Shell";
		Weapon.AmmoType2 "Shell";
		ddWeapon.ClassicAmmoType1 "Shell";
		ddWeapon.ClassicAmmoType2 "Shell";
		ddWeapon.rating 4;
		ddWeapon.SwitchSpeed 2.8;
		ddWeapon.initialMag 1;
		ddWeapon.MagUse1 1;
		ddWeapon.CellUse1 2;
		ddWeapon.WeaponType "Shotgun";
		Inventory.PickupMessage "$GOTSHOTGUN";
		Obituary "$OB_MPSHOTGUN";
		Tag "$TAG_SHOTGUN";
	}
	/*
	override void WhileBerserk()
	{
		if(owner is "ddPlayerNormal")
		{
			//speed up states when berserk
			let myside = (weaponside) ? owner.player.getpsprite(PSP_LEFTW) : owner.player.getpsprite(PSP_RIGHTW);
			let myflash = (weaponside) ? owner.player.getpsprite(PSP_LEFTWF) : owner.player.getpsprite(PSP_RIGHTWF);
			if(weaponstatus == DDW_RELOADING || weaponstatus == DDW_UNLOADING) { if(myside.tics > 3) { myside.tics--; } if(myflash.tics > 1) { myflash.tics--; } }
		}
	}*/
	
	override void InventoryInfo(ddStats ddhud)
	{
		let hud = ddhud;		
		hud.DrawString(hud.fa, GetTag(), (30, 45), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, "level "..hud.FormatNumber(rating).." light shotgun", (30, 55), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, hud.FormatNumber(mag).."/"..hud.FormatNumber(default.mag), (30, 65), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
	}
	
	override void PreviewInfo(ddStats ddhud)
	{
		let hude = ddhud;
		hude.DrawString(hude.fa, GetTag(), (12, 45), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
		hude.DrawString(hude.fa, hude.FormatNumber(mag).."/"..hude.FormatNumber(default.mag), (12, 52), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
		hude.DrawString(hude.fa, "Spare ammo: "..hude.FormatNumber(AmmoGive1), (12, 59), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
	}
	
	override void HUDA(ddStats hude)
	{
		if(owner.player.readyweapon is "twoHanding")
		{
			if(!owner.FindInventory("ClassicModeToken"))
				hude.DrawString(hude.bf, hude.FormatNumber(mag), (0, -20), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, 0, 0.5, -1, 4, (0.75,0.75));
		}
		else if(owner.player.readyweapon is "dualWielding")
		{
			if(weaponside == CE_LEFT)
			{
				if(!owner.FindInventory("ClassicModeToken"))
					hude.DrawString(hude.bf, hude.FormatNumber(mag), (-64, -20), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, 0, 0.5, -1, 4, (0.75,0.75));
			}
			else
			{
				if(!owner.FindInventory("ClassicModeToken"))
					hude.DrawString(hude.bf, hude.FormatNumber(mag), (64, -20), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, 0, 0.5, -1, 4, (0.75,0.75));				
			}
		}
	}
	
	override State GetReadyState()
	{
		if(ddWeaponFlags & SHT_RSEQ && ModeCheck(4) == (RES_TWOHAND || RES_HASESOA)) { SetCaseNumber(2); return FindState("Reload2"); }
		else { return FindState("Ready"); }
	}
	
	override String, int GetSprites(int forcemode)
	{
		let ddp = ddPlayer(owner);
		if(forcemode < 0)
		{
			if(ddp.player.readyweapon is "dualWielding" || ddp.player.pendingweapon is "dualWielding" || ddp.lastmode is "dualWielding") { return "SHTDA0", -1; }
			else if(ddp.player.readyweapon is "twoHanding" || ddp.player.pendingweapon is "twoHanding" || ddp.lastmode is "twoHanding")  { return "SHTGA0", -1; }
			else { return "TNT1A0", -1; }
		}
		else if(forcemode == 2) { return "SHTDA0", -1; }
		else if(forcemode == 1) { return "SHTGA0", -1; }
		else { return "TNT1A0", -1; }
	}
	
	override String getParentType()
	{
		return "ddShotgun";
	}
	
	override String GetWeaponSprite()
	{
		return "SHOTA0";
	}
	
	override State wannaReload()
	{
		if(mag > 0 && weaponstatus == DDW_UNLOADING) { SetCaseNumber(3); return FindState('UnloadP'); }
		if(ddWeaponFlags & SHT_RSEQ) { weaponstatus = DDW_RELOADING; SetCaseNumber(5); return FindState("Reload2");	}
		if(mag > 0) { return FindState('DoNotJump'); }
		else { SetCaseNumber(2); weaponStatus = DDW_RELOADING; return FindState('ReloadP'); }
	}
	
	override void primaryattack()
	{
		let ddp = ddPlayer(owner);
		if(!ddp.FindInventory("ClassicModeToken"))
		{
			if(mag > 0) { mag--; A_FireDDShotgun(); }
		}
		else
		{
			if(ddp.CountInv("Shell") > 0) { ddp.TakeInventory("Shell", 1); A_FireDDShotgun(); }
		}
	}
	
	override void alternativeattack() { primaryattack(); } 
	
	override void DD_Condition(int cn)
	{
		int caseno = cn;
		let ddp = ddPlayer(owner);
		let mode = ddWeapon(ddp.player.readyweapon);
		let me = ddWeapon(self);
		let cpiece = ddWeapon(me.companionpiece);
		int myside = (weaponside) ? PSP_LEFTW : PSP_RIGHTW; 
		int flashside = (weaponside) ? PSP_LEFTWF : PSP_RIGHTWF;
		let res = ModeCheck();
		switch(caseno)
		{
			case 0: //init/mode check
				if(res == RES_CLASSIC && (ddp.CountInv("Shell") < 1)) { ChangeState("NoAmmo", myside); break; }
				if(mag < 1 && ddp.CountInv("Shell") < 1) { ChangeState("NoAmmo", myside); break; }
				if(res == RES_DUALWLD) { //lower to reload
					if(mag < 1) { /*LowerToReloadWeapon();*/ SetCaseNumber(5); 
						if(ddWeaponFlags & SHT_RSEQ) { SetCaseNumber(2); ChangeState("Reload2B", myside); } 
						 else { ChangeState("ReloadOneHanded", myside); } 
					}	
					else { SetCaseNumber(1); }
					break;
				}
				else if(res == RES_HASESOA) { if(mag < 1) { weaponstatus = DDW_RELOADING; SetCaseNumber(5); ChangeState("ReloadP", myside); break; }
					else { ddp.PlayAttacking(); SetCaseNumber(1); break; } 
				}
				else { if(mag < 1 || ddWeaponFlags & SHT_RSEQ) { weaponstatus = DDW_RELOADING; SetCaseNumber(2); ChangeState("ReloadP", myside); break; } else { ddp.PlayAttacking(); SetCaseNumber(1); } break; } 
			case 1: //jump to reload if twohanding
				if((res == RES_TWOHAND || res == RES_HASESOA || res == RES_CLASSIC) && ddp.CountInv("Shell") > 0) { weaponstatus = DDW_RELOADING; ChangeState("ReloadP", myside); SetCaseNumber(5); }
				else { SetCaseNumber(0); }
				break;	
			case 2: //reload mag
				ReloadWeaponMag(1); SetCaseNumber(0); ddWeaponFlags &= ~SHT_RSEQ; break;
			case 3: //unload mag
				UnloadWeaponMag(); SetCaseNumber(0); break;
			case 4: //unload mag
				AddRecoil(0.0, 5, 0.0); ReloadWeaponMag(1); SetCaseNumber(0); break;
			case 5: //reload checkpoint (tm)
				ddWeaponFlags |= SHT_RSEQ;
				SetCaseNumber(2);
				break;
			default: break;
		}
	}
	
	// ## ddShotgun States()
	States
	{
		NoAmmo:
			SHTG A 10;
		Ready:
			SHTG A 1;
			Loop;
		Deselect:
			SHTG A 1;
			Loop;
		Select:
			SHTG A 1;
			Loop;
		Fire:
			Goto Ready;		
		Altfire:
			Goto Ready;
		FlashA:
		FlashP:
			SHTF A 4 Bright A_Light1;
			SHTF B 3 Bright A_Light2;
			Goto FlashDone;	
		Spawn:
			SHOT A -1;
			Stop;
	}
	
}
// #Class ddShotgunLeft : ddShotgun()
class ddShotgunLeft : ddShotgun
{
	Default { ddweapon.weaponside CE_LEFT; -DDWEAPON.GOESININV; }
	States
	{
		NoAmmo:
			#### A 10;
		Ready:
			SHTD A 0 A_ChangeSpriteLeft;
			#### A 1 A_LeftWeaponReady;
			Loop;
		Altfire:
		Fire:
			#### A 0 A_DDActionLeft;
			#### A 3;
			#### A 0 A_FlashLeft;
			#### A 1 A_FireLeftWeapon;
			#### A 6;
			#### A 0 A_DDActionLeft;
			Goto Ready;	
		Select:
			#### A 1 A_ChangeSpriteLeft;
			Loop;
		ReloadA:
		ReloadP:			
			#### BC 5;
			#### D 4 A_RackShotgun;
			#### C 3 A_DDActionLeft;
		Reload2:
			#### C 2 A_SlideShotgun;
			#### B 4;
			#### B 1 A_DDActionLeft;
			#### A 2;
			#### A 1;
			#### A 7 A_ddRefireLeft;
			Goto Ready;
		ReloadOneHanded:
			SHOH ABCDE 2;
			SHOH F 1 A_DDActionLeft;
			SHOH F 14 A_RackShotgun;
		Reload2B:
			SHOH E 6 A_SlideShotgun;
			SHOH D 3 A_DDActionLeft;
			SHOH CBA 3;
			SHOH A 7 A_ddRefireLeftHeavy;
			Goto Ready;			
		UnloadP:		
			#### BC 5;
			#### D 4 A_PumpShotgun;
			#### C 5 A_DDActionLeft;
			#### B 5;
			#### A 2;
			#### A 1;
			#### A 7;
			Goto Ready;
	}
}
// #Class ddShotgunRight : ddShotgun()
class ddShotgunRight : ddShotgun
{
	Default { ddweapon.weaponside CE_RIGHT; -DDWEAPON.GOESININV; }
	States
	{
		NoAmmo:
			#### A 10;
		Ready:
			SHTD A 0 A_ChangeSpriteRight;
			#### A 1 A_RightWeaponReady;
			Loop;	
		Altfire:
		Fire:
			#### A 0 A_DDActionRight;
			#### A 3;
			#### A 0 A_FlashRight;
			#### A 1 A_FireRightWeapon;
			#### A 6;
			#### A 0 A_DDActionRight;
			Goto Ready;	
		Select:
			#### A 1 A_ChangeSpriteRight;
			Loop;
		ReloadA:
		ReloadP:		
			#### BC 5;
			#### D 4 A_RackShotgun;
			#### C 3 A_DDActionRight;
		Reload2:
			#### C 2 A_SlideShotgun;
			#### B 4;
			#### B 1 A_DDActionRight;
			#### A 2;
			#### A 1;
			#### A 7 A_ddRefireRight;
			Goto Ready;
		ReloadOneHanded:
			SHOH GHIJK 2;
			SHOH L 1 A_DDActionRight;
			SHOH L 14 A_RackShotgun;
		Reload2B:
			SHOH K 6 A_SlideShotgun;
			SHOH J 3 A_DDActionRight;
			SHOH IHG 3;
			SHOH A 7 A_ddRefireRightHeavy;
			Goto Ready;			
		UnloadP:		
			#### BC 5;
			#### D 4 A_PumpShotgun;
			#### C 5 A_DDActionRight;
			#### B 5;
			#### A 2;
			#### A 1;
			#### A 7;
			Goto Ready;
	}
}
// #Class ShotgunSpawner : RandomSpawner replaces Shotgun()
class ShotgunSpawner : RandomSpawner replaces Shotgun
{
	Default
	{
		DropItem "ddShotgun", 255, 60;
		DropItem "Knife", 255, 9;
	}
	
	override Name ChooseSpawn()
	{
		for(int x = 0; x < 8; x++)
		{
			if(players[x].mo is "ddPlayerClassic")
			{
				return "ddShotgun";
			}
		}
		return Super.ChooseSpawn();
	}
}


extend class ddWeapon
{
	action void A_FireDDShotgun()
	{
		let ddp = ddPlayer(invoker.owner);
		if(ddp.player == null) { return; }
		ddWeapon weap = ddWeapon(self);
		bool pen = (ddp.player.readyweapon is "dualWielding"&&!ddp.CheckESOA(0));
		double eA = 0;
		double eP = 0;
		int kick = (pen) ? 7 : 2;
		int pels = 7;
		bool bz = (ddp.FindInventory("PowerBerserk"));
		int dam;
		ddp.A_StartSound ("weapons/shotgf", CHAN_WEAPON, CHANF_OVERLAP);
		double pitch = BulletSlope ();
		for (int i = 0; i < pels; i++)
		{
			if(pen) { eA = (Random2() * (6.67 / 256)); eP = (Random2() * (3.45 / 256)); } 
			else { eA = random2() * (3.925 / 256); eP = random2() * (1.225 / 256); }
			dam = 5 * random(1,((ddp is "ddPlayerClassic") ? 3 : 4));
			if(ddp is "ddPlayerClassic") { eP = 0; }
			ddShot(false, "BulletPuff", dam, eA, eP, weap.weaponside,kick);
		}		
		if(pen) { AddRecoil(12., 8, 4.); }
		else { AddRecoil(6, 1, 4.); }
	}
	
	action void A_PumpShotgun()
	{
		invoker.owner.A_StartSound("weapons/shotgp", CHAN_WEAPON, CHANF_OVERLAP);
	}
	
	action void A_RackShotgun()
	{
		invoker.owner.A_StartSound("weapons/shotgp1", CHAN_WEAPON, CHANF_OVERLAP);
	}
	
	action void A_SlideShotgun()
	{
		invoker.owner.A_StartSound("weapons/shotgp2", CHAN_WEAPON, CHANF_OVERLAP);	
	}

}	