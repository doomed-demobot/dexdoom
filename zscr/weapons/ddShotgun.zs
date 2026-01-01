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
		ddWeapon.ChargeUse1 2;
		ddWeapon.WeaponType "Shotgun";
		Inventory.PickupMessage "$GOTSHOTGUN";
		Obituary "$OB_MPSHOTGUN";
		Tag "$TAG_SHOTGUN";
		+DDWEAPON.BOBWHENREADY;
		+DDWEAPON.FLIPOFFSETS;
	}
	
	/*
	override void WhileBerserk()
	{
		if(owner is "ddPlayerNormal")
		{
			//speed up states when berserk
			let myside = (weaponside) ? owner.player.getpsprite(PSP_LEFTW0) : owner.player.getpsprite(PSP_RIGHTW0);
			let myflash = (weaponside) ? owner.player.getpsprite(PSP_LEFTWF0) : owner.player.getpsprite(PSP_RIGHTWF0);
			if(weaponstatus == DDW_RELOADING || weaponstatus == DDW_UNLOADING) { if(myside.tics > 3) { myside.tics--; } if(myflash.tics > 1) { myflash.tics--; } }
		}
	}*/
	/*
	//lame fix for dualWield refire states
	override void onRefire()
	{
		if(owner.player.readyweapon is "dualWielding")
		{
			PSPrite psp;
			if(weaponside == CE_RIGHT)
			{
				psp = owner.player.getpsprite(PSP_RIGHTW0);
				psp.sprite = GetSpriteIndex("SHH2A0");
			}
			else
			{
				psp = owner.player.getpsprite(PSP_LEFTW0);
				psp.sprite = GetSpriteIndex("SHOHA2");
			}
		}
	}*/
	
	override void OnAutoReload()
	{
		ddWeaponFlags &= ~SHT_RSEQ;
	}
	
	override void InventoryInfo(ddStats ddhud, bool debug)
	{
		if(debug) { Super.InventoryInfo(ddhud, debug); return; }
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
		if(ddWeaponFlags & SHT_RSEQ && ModeCheck(0) == (RES_TWOHAND || RES_HASESOA)) { 
			ddPlayer(owner).ddWeaponState |= DDW_RIGHTNOBOBBING; ddPlayer(owner).ddWeaponState &= ~DDW_RIGHTREADY; return FindState("Reload2"); 
		}
		else { return FindState("Ready"); }
	}
	/*
	override State GetFlashState()
	{
		let ddp = ddPlayer(owner);
		if(ddp.player.readyweapon is "dualWielding" || ddp.player.pendingweapon is "dualWielding" || ddp.lastmode is "dualWielding") 
		{ 
			if(weaponside) { return FindState("FlashDW"); }
			else { return FindState("FlashDW")+2; }
		}
		else { return Super.GetFlashState(); }
	}*/
	
	override String, int GetSprites(int forcemode)
	{
		let ddp = ddPlayer(owner);
		if(forcemode < 0)
		{
			if(ddp.player.readyweapon is "dualWielding" || ddp.player.pendingweapon is "dualWielding" || ddp.lastmode is "dualWielding") 
			{ 
				String sp; 
				int frame = -1;
				sp = (weaponside) ? "SHOHA0" : "SHH2A0";
				if(ddWeaponFlags & SHT_RSEQ) { 
					frame = 2; 
				}
				return sp, frame;
			}
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
		if(mag > 0 && weaponstatus == DDW_UNLOADING) { return FindState('UnloadP'); }
		if(ddWeaponFlags & SHT_RSEQ) { weaponstatus = DDW_RELOADING; return FindState("Reload2");	}
		if(mag > 0) { return FindState('DoNotJump'); }
		else { weaponStatus = DDW_RELOADING; return FindState('ReloadP'); }
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

	override void SetDDTransformations(int no, PSpriteInfo &pspi)
	{
		let ddp = ddPlayer(owner);
		if(!ddp) { return; }
		int i = (weaponside) ? ddp.leftinstability : ddp.rightinstability;
		switch(no)
		{
			case 1: //shotgun fire
				pspi.SetTransformationProperties(3, true, (INTR_TRANS_EXPO | INTR_SCALE_INVEXPO));
				//if flash state, copy weapons rotation
				if(pspi.id > 15) 
				{
					pspi.GetTranslations(pspi.id - 10);
					//pspi.GetRotation(pspi.id - 10);
				}
				else 
				{
					pspi.SetTranslations(random2(1), 12);
					//pspi.SetRotation(random2(7));
				}
				
				pspi.SetScaling(0, 20);
				return;
			case 2: //shotgun reload 1
				pspi.SetTransformationProperties(5, false, INTR_TRANS_EXPO);
				pspi.SetTranslations(-10, 4);
				return;
			case 3: //shotgun reload 2
				pspi.SetTransformationProperties(3, false, (INTR_TRANS_INVEXPO | INTR_SCALE_INVEXPO | INTR_ROTAT_LINEAR));
				pspi.SetTranslations(-1, 16);
				pspi.SetScaling(10, 0);
				pspi.SetRotation(6);
				return;
			case 4: //shotgun reload 3
				pspi.SetTransformationProperties(3, false, (INTR_TRANS_LINEAR | INTR_SCALE_INVEXPO | INTR_ROTAT_LINEAR));
				pspi.SetTranslations(8, -16);
				pspi.SetScaling(-10, 0);
				pspi.SetRotation(-4);
				return;
			case 5: //shotgun 1h reload 1
				pspi.SetTransformationProperties(5, false, (INTR_TRANS_INVEXPO));
				pspi.SetTranslations(((weaponside) ? -9 : 9), 16);
				return;
			case 6:
				pspi.SetTransformationProperties(2, false, (INTR_TRANS_EXPO));
				pspi.SetTranslations(0, -16);
				return;
			case 7:
				pspi.SetTransformationProperties(4, false, (INTR_TRANS_INVEXPO));
				pspi.SetTranslations(0, 8);
				return;
			case 8:
				pspi.SetTransformationProperties(4, false, (INTR_TRANS_INVEXPO));
				pspi.SetTranslations(0, -6);
				return;
			case 9:
				pspi.SetTransformationProperties(4, true, (INTR_TRANS_EXPO));
				pspi.SetTranslations(((weaponside) ? 9 : -9), -4);
				return;
			default: return;
		}
	}

	override void DD_WeapAction(int no)
	{
		let ddp = ddPlayer(owner);
		let mode = ddWeapon(ddp.player.readyweapon);
		let me = ddWeapon(self);
		let cpiece = ddWeapon(me.companionpiece);
		int myside = (weaponside) ? PSP_LEFTW0 : PSP_RIGHTW0; 
		int flashside = (weaponside) ? PSP_LEFTWF0 : PSP_RIGHTWF0;
		let res = ModeCheck();
		switch(no)
		{
			case 1: //init/mode check
				if(res == RES_CLASSIC && (ddp.CountInv("Shell") < 1)) { ChangeState("NoAmmo", myside); break; }
				if(mag < 1 && ddp.CountInv("Shell") < 1) { ChangeState("NoAmmo", myside); break; }
				if(res == RES_DUALWLD) { //lower to reload
					if(mag < 1) {
						if(ddWeaponFlags & SHT_RSEQ) { weaponStatus = DDW_RELOADING; ChangeState("Reload2B", myside); }
						 else { weaponStatus = DDW_RELOADING; ChangeState("ReloadOneHanded", myside); }
					}
					else { /*:))))*/ }
					break;
				}
				else if(res == RES_HASESOA)
				{
					if(ddWeaponFlags & SHT_RSEQ) { weaponStatus = DDW_RELOADING; ChangeState("Reload2", myside); break; }
					if(mag < 1) { weaponstatus = DDW_RELOADING; ChangeState("ReloadP", myside); break; }
					else { ddp.PlayAttacking(); break; }
				}
				else
				{
					if(ddWeaponFlags & SHT_RSEQ) { weaponStatus = DDW_RELOADING; ChangeState("Reload2", myside); break; }
					if(mag < 1) { weaponstatus = DDW_RELOADING; ChangeState("ReloadP", myside); break; }
					else { ddp.PlayAttacking(); }
					break;
				} 
			case 2: //jump to reload if twohanding
				if((res == RES_TWOHAND || res == RES_HASESOA || res == RES_CLASSIC) && ddp.CountInv("Shell") > 0) { weaponstatus = DDW_RELOADING; ChangeState("ReloadP", myside); }
				else { /*yes*/ }
				break;			
			case 3: //reload mag
				ReloadWeaponMag(1); ddWeaponFlags &= ~SHT_RSEQ; weaponstatus = DDW_READY; break;			
			case 4: //unload mag
				UnloadWeaponMag(); break;			
			case 5: //reload mag onehanded MOVE DOWN HERE V V V
				AddRecoil(0.0, 5, 0.0); ReloadWeaponMag(1); break;
			case 6: //reload checkpoint (tm)
				ddWeaponFlags |= SHT_RSEQ;
				break;
			default: ddp.A_Log("No action defined for tic "..no); break;
		}		
	}
		
	// ## ddShotgun States()
	States
	{
		NoAmmo:
			#### A 10;
		Ready:
			SHTD A 0 A_ChangeSprite;
			#### # 1 A_DDWeaponReady;
			Loop;
		Altfire:
		Fire:
			#### A 1 A_WeapAction;
			#### A 3;
			#### A 1 A_DDTransformation;
			#### A 0 A_DDFlash;
			#### A 1 A_FireDDWeapon;
			#### A 6;
			#### A 2 A_WeapAction;
			Goto Ready;	
		Select:
			SHTD A 1 A_ChangeSprite;
			Loop;
		Deselect:
			SHTD A 1 A_ChangeSprite;
			Loop;
		ReloadA:
		ReloadP:
			#### B 2 A_DDTransformation;
			#### BC 5;
			#### D 3 A_DDTransformation;
			#### D 4 A_RackShotgun;
			#### C 6 A_WeapAction;
			#### C 3;
			#### C 4 A_DDTransformation;
		Reload2:
			#### C 2 A_SlideShotgun;
			#### B 4;
			#### B 3 A_WeapAction;
			//#### B 6 A_DDWeaponOffset;
			#### B 1;
			#### A 2;
			#### A 1;
			#### A 7 A_DDRefire;
			Goto Ready;
		ReloadOneHanded:
			SHH2 A 0 A_ChangeSprite;
			#### A 5 A_DDTransformation;
			#### A 6;
			#### A 6 A_DDTransformation;
			#### BC 2;
			#### A 7 A_DDTransformation;
			#### D 6 A_WeapAction;
			#### D 1;
			#### D 12 A_RackShotgun;
		Reload2B:
			#### C 8 A_DDTransformation;
			#### C 6 A_SlideShotgun;
			#### B 9 A_DDTransformation;
			#### B 3 A_WeapAction;
			#### B 3;
			#### A 6;
			#### AAA 1 A_DDHeavyRefire;
			#### A 4;
			Goto Ready;			
		UnloadP:		
			#### BC 5;
			#### D 4 A_PumpShotgun;
			#### C 4 A_WeapAction;
			#### C 5;
			#### B 5;
			#### A 2;
			#### A 1;
			#### A 7;
			Goto Ready;
		/*
		FlashDW:
			SHTF C 1 Bright A_Light1;
			SHTF D 3 Bright A_Light2;
			Goto FlashDone;
			SHTF E 1 Bright A_Light1;
			SHTF F 3 Bright A_Light2;
			Goto FlashDone;
			*/
		FlashP:
			SHTF A 1 A_DDTransformation;
			SHTF A 1 Bright A_Light1;
			SHTF B 2 Bright A_Light2;
			Goto FlashDone;	
		Spawn:
			SHOT A -1;
			Stop;
		Ind:
			SHTR A 0;
			SHOH A 0;
			SHH2 A 0;
			Stop;
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
			if(pen) { eA = (Random2() * (4.44 / 256)); eP = (Random2() * (2.33 / 256)); } 
			else { eA = random2() * (3.925 / 256); eP = random2() * (1.225 / 256); }
			dam = 5 * random(1,((ddp is "ddPlayerClassic") ? 3 : 4));
			if(ddp is "ddPlayerClassic") { eP = 0; }
			ddShot(false, "BulletPuff", dam, eA, eP, weap.weaponside,kick);
		}		
		if(pen) { AddRecoil(12., 5, 4.); }
		else { AddRecoil(4, 1, 4.); }
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