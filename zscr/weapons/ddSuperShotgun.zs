// Doom 2 Super Shotgun. 2 mag, reloads automatically in two hands. Must lower other
// weapon to reload. Single-fire alternative fire
// #Class ddSuperShotgun : ddWeapon()
enum ddSShotgunFlags{
	SST_RSEQA = 1,
	SST_RQUIK = 2,
	SST_RSEQ1 = 4,
	SST_RSEQ2 = 6,
	SST_RALL = 7,
};

class ddSuperShotgun : ddWeapon replaces SuperShotgun
{
	Default
	{
		Weapon.SelectionOrder 400;
		Weapon.AmmoUse 2;
		Weapon.AmmoGive 8;
		Weapon.AmmoUse2 1;
		Weapon.AmmoType "BFS";
		Weapon.AmmoType2 "BFS";
		ddWeapon.rating 5;
		ddWeapon.SwitchSpeed 1.5;
		ddWeapon.initialmag 2;
		ddWeapon.MagUse 1;
		ddWeapon.WeaponType "Shotgun";
		Inventory.PickupMessage "$GOTSHOTGUN2";
		Obituary "$OB_MPSSHOTGUN";
		Tag "$TAG_SUPERSHOTGUN";
	}
	
	override void WhileBerserk()
	{
		//speed up states when berserk
		let myside = (weaponside) ? owner.player.getpsprite(PSP_LEFTW0) : owner.player.getpsprite(PSP_RIGHTW0);
		let myflash = (weaponside) ? owner.player.getpsprite(PSP_LEFTWF0) : owner.player.getpsprite(PSP_RIGHTWF0);
		if(weaponstatus == DDW_RELOADING) { if(myside.tics > 3) { myside.tics--; } if(myflash.tics > 1) { myflash.tics--; } }
	}
	
	override void OnAutoReload()
	{
		ddWeaponFlags &= ~SST_RALL;
	}
		
	override void InventoryInfo(ddStats ddhud, bool debug)
	{
		if(debug) { Super.InventoryInfo(ddhud, debug); return; }
		let hud = ddhud;		
		hud.DrawString(hud.fa, GetTag(), (30, 45), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, "level "..hud.FormatNumber(rating).." heavy shotgun", (30, 55), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, hud.FormatNumber(mag).."/"..hud.FormatNumber(default.mag), (30, 65), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
	}
	
	override void PreviewInfo(ddStats ddhud)
	{
		let hude = ddhud;
		hude.DrawString(hude.fa, GetTag(), (12, 45), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
		hude.DrawString(hude.fa, hude.FormatNumber(mag).."/"..hude.FormatNumber(default.mag), (12, 52), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
		hude.DrawString(hude.fa, "Spare ammo: "..hude.FormatNumber(AmmoGive1), (12, 59), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
	}
	
	override TextureID GetFireModeIcon()
	{
		if(fireMode == 0) { return TexMan.CheckForTexture("ICONDOUB"); }
		else if (fireMode == 1) { return TexMan.CheckForTexture("ICONSING"); }
		else { return Super.GetFireModeIcon(); }
	}
	
	override void HUDA(ddStats hude)
	{
		if(owner.player.readyweapon is "twoHanding")
		{
			hude.DrawString(hude.bf, hude.FormatNumber(mag), (0, -20), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, 0, 0.5, -1, 4, (0.75,0.75));
		}
		else if(owner.player.readyweapon is "dualWielding")
		{
			if(weaponside == CE_LEFT)
			{
				hude.DrawString(hude.bf, hude.FormatNumber(mag), (-64, -20), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, 0, 0.5, -1, 4, (0.75,0.75));
			}
			else
			{
				hude.DrawString(hude.bf, hude.FormatNumber(mag), (64, -20), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, 0, 0.5, -1, 4, (0.75,0.75));				
			}
		}
	}
	
	override String getParentType()
	{
		return "ddSuperShotgun";
	}
	
	override String, int GetSprites(int no)
	{
		let ddp = ddPlayer(owner);
		if(!ddp) { return "TNT1", -1; }
		int res = ModeCheck();
		switch(no)
		{
			case 0:
				if(res == RES_TWOHAND) { return "SHT2", ((ddWeaponFlags & SST_RALL) ? 6 : 0 ); }
				else if(res == RES_DUALWLD) { return ((weaponside) ? "SH2L" : "SH2R"), ((ddWeaponFlags & SST_RALL) ? 6 : 0 ); }
				else { return "TNT1", -1; }
			case 1: //one hand reload
				if(ddp.playingFreedoom) { return (weaponside) ? "SH2L" : "SH2R", ((ddWeaponFlags & SST_RALL) ? 6 : 0); }
				else { return ((weaponside) ? "SHT2" : "SH2R"), ((ddWeaponFlags & SST_RALL) ? 6 : 0 ); }
			case 2: //force sht2
				return "SHT2", -1;
			case 3: //sprite for arm
				return "SARM", ((mag >= 1 || ddp.CountInv("BFS") <= 1) ? 1 : 2);
			default:
				return "TNT1", -1;
		}
	}
	
	override String GetWeaponSprite()
	{
		return "SGN2A0";
	}	
	
	override State GetFlashState()
	{
		if(!bAltFire) 
		{ 
			if(mag > 1) { return FindState('FlashP'); }
			else { return FindState('Blam'); }
		}
		else
		{
			if(mag > 1) { return FindState("Boom"); }
			else { return FindState("Blam"); }
		}
	}
	
	override State GetReadyState()
	{
		if(ModeCheck(4) == RES_TWOHAND) 
		{ 
			ddPlayer(owner).ddWeaponState &= ~DDW_RIGHTBOBBING; 
			ddPlayer(owner).ddWeaponState &= ~DDW_RIGHTREADY;			
			weaponStatus = DDW_RELOADING;
			
			if(ddWeaponFlags & 4) { return FindState("Reload2"); }
			else if(ddWeaponFlags & 5) { return FindState("Reload3"); }
			else if(ddWeaponFlags & 6) { return FindState("Reload2A"); }
			else if(ddWeaponFlags & 7) { return FindState("Reload3A"); }
			else { return FindState("Ready"); }
		}
		else { return FindState("Ready"); }
	}
	
	override State wannaReload()
	{
		if(weaponstatus == DDW_UNLOADING) { return FindState('UnloadP'); }
		if(ddWeaponFlags & SST_RSEQ1) { weaponStatus = DDW_RELOADING; return FindState('Reload2'); }
		if(ddWeaponFlags & SST_RSEQ2) { weaponStatus = DDW_RELOADING; return FindState('Reload3'); }
		else if(mag < default.mag) { weaponStatus = DDW_RELOADING; return FindState('ReloadP'); }
		else { return FindState('DoNotJump'); }
	}
	
	override void primaryattack()
	{
		let ddp = ddPlayer(owner);		
		if(mag > 1) { mag -= 2; A_FireDDSShotgun(); }
		else if(mag > 0) { mag--; A_FireDDSShotgunSingle(); }
		else { }
	}
	
	override void alternativeattack()
	{
		let ddp = ddPlayer(owner);
		if(mag > 0) { mag--; A_FireDDSShotgunSingle(); }
		else { }
	}
	
	override void SetDDTransformations(int no, PSpriteInfo pspi)
	{
		let ddp = ddPlayer(owner);
		if(!ddp) { return; }
		let i = (weaponside) ? ddp.leftInstability : ddp.rightInstability;
		switch(no)
		{
			case 1:
				pspi.SetTransformationProperties(4, true, (INTR_TRANS_INVEXPO | INTR_SCALE_INVEXPO));
				pspi.SetTranslations(0, 9);
				pspi.SetScaling(12, 30);
				return;
			case 2:
				pspi.SetTransformationProperties(3, true, (INTR_TRANS_INVEXPO | INTR_SCALE_INVEXPO | INTR_ROTAT_EXPO));
				pspi.SetTranslations(0, 3);
				pspi.SetScaling(5, 15);
				pspi.SetRotation((mag > 1) ? -2 : 2);
				return;
			case 3: //flash
				pspi.SetTransformationProperties(4, true, (INTR_TRANS_INVEXPO | INTR_SCALE_INVEXPO), 0, 30);
				pspi.SetTranslations(0, 9);
				pspi.SetScaling(12, 30);
				return;
			case 4: //flash alt
				pspi.SetTransformationProperties(3, true, (INTR_TRANS_INVEXPO | INTR_SCALE_INVEXPO | INTR_ROTAT_EXPO), 0, 30);
				pspi.SetTranslations(0, 3);
				pspi.SetScaling(5, 15);
				pspi.SetRotation((mag > 1) ? -2 : 2);
				return;
			case 5: //reload 1
				if(ddp.playingFreedoom)
				{
					pspi.SetTransformationProperties(12, false, (INTR_TRANS_EXPO | INTR_ROTAT_INVEXPO), nextcase: 6);
					pspi.SetTranslations(20, 0);
					pspi.SetRotation(14);
				}
				else
				{
					pspi.SetTransformationProperties(14, false, (INTR_TRANS_EXPO | INTR_SCALE_EXPO | INTR_ROTAT_INVEXPO), nextcase: 6);
					pspi.SetTranslations(0, 0);
					pspi.SetScaling(-5, 0);
					pspi.SetRotation(9);
				}
				return;
			case 6:	//reload 2
				if(ddp.playingFreedoom)
				{
					pspi.SetTransformationProperties(3, false, (INTR_TRANS_INVEXPO | INTR_SCALE_EXPO), nextcase: 9);
					pspi.SetTranslations(10,0);
					pspi.SetScaling(-10, 10);
				}
				else
				{
					pspi.SetTransformationProperties(6, false, (INTR_TRANS_EXPO | INTR_SCALE_LINEAR | INTR_ROTAT_EXPO), nextcase: 7);
					pspi.SetTranslations(0, 20);
					pspi.SetScaling(10,0);
					pspi.SetRotation(-6);
				}
				return;
			case 7:
				pspi.SetTransformationProperties(2, false, (INTR_TRANS_INVEXPO | INTR_SCALE_INVEXPO | INTR_ROTAT_EXPO));
				pspi.SetTranslations(0, -20);
				pspi.SetScaling(-5, 0);
				pspi.SetRotation(-3);
				return;
			case 8:
				pspi.SetTransformationProperties(7, true, (INTR_TRANS_EXPO));
				pspi.SetTranslations(0, 20);
				return;
			case 9:
				pspi.SetTransformationProperties(3, false, (INTR_TRANS_INVEXPO | INTR_SCALE_EXPO));
				pspi.SetTranslations(-20,0);
				pspi.SetScaling(10, -10);
				pspi.SetRotation(-14);
				return;
			case 10: //arm reload up
				pspi.SetTransformationProperties(6, false, (INTR_TRANS_INVEXPO));
				pspi.SetTranslations(20, -30);
				return;
			case 11: //arm reload down
				pspi.SetTransformationProperties(5, false, (INTR_TRANS_INVEXPO));
				pspi.SetTranslations(0, 45);
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
		PSpriteInfo pspi = ddp.GetPSpriteInfo(((weaponside) ? PSP_LEFTW0 : PSP_RIGHTW0), ddp);
		let res = ModeCheck();
		switch(no)
		{
			case 1: //init/mode check
				if(mag < 1 && ddp.CountInv("BFS") < 1) { ChangeState("NoAmmo", myside); break; }
				if(res == RES_DUALWLD) { //lower to reload
					if(mag < 1 && !(ddWeaponFlags & 7)) { ddWeaponFlags |= SST_RQUIK; ChangeState("ReloadOneHanded", myside); break; }
					if(ddWeaponFlags & 7) { LowerToReloadWeapon(); break; }
					break;
				}
				else if(ddWeaponFlags & SST_RSEQ1) { ChangeState("Reload2", myside); break; }
				else if(ddWeaponFlags & SST_RSEQ2) { ChangeState("Reload3", myside); break; }
				else if(res == RES_HASESOA) 
				{ 
					if(mag < 1) 
					{ weaponstatus = DDW_RELOADING; ChangeState("ReloadP", myside); break; } 
					ddp.PlayAttacking(); break; 
				}
				else { if(mag < 1) { weaponstatus = DDW_RELOADING; ChangeState("ReloadP", myside); break; } else { ddp.PlayAttacking(); } break; }
			case 2: //jump to reload if twohanding
				if((res == RES_TWOHAND || res == RES_HASESOA) && ddp.CountInv("BFS") >= 1 && mag < 1) { weaponstatus = DDW_RELOADING; ChangeState("ReloadP", myside); }
				else { }
				break;
			case 3:
				if(mag < 1) { ddWeaponFlags |= SST_RSEQA; ReloadWeaponMag(2); break; }
				else { ReloadWeaponMag(2); break; }
			case 4:
				UnloadWeaponMag();
				break;
			case 5: //eject
				ddWeaponFlags |= SST_RSEQ1;
				if(ddWeaponFlags & SST_RQUIK) { ddWeaponFlags &= ~SST_RQUIK; ChangeState("Ready", myside); }
				break;
			case 6: //close
				ddWeaponFlags &= ~SST_RALL;
				break;
			case 7: //spawn arm sprite (freedoom only)
				if(ddp.playingFreedoom) { SetSubSprite(pspi, 8, 50, 0, "ReloadingArm"); }
				break;
			default: ddp.A_Log("No action defined for tic "..no); break;
		}
		
	}
	
	
	// ## ddSuperShotgun States()
	States
	{
		NoAmmo:
			#### A 10;
		Ready:
			SH2D A 0 A_ChangeSprite;
			#### # 1 A_DDWeaponReady;
			Loop;
		Fire:
			#### A 1 A_WeapAction;
			#### A 3;
			#### A 0 A_DDFlash;
			#### A 1 A_DDTransformation;
			#### A 1 A_FireDDWeapon;
			#### A 6;
			#### A 2 A_WeapAction;
			Goto Ready;
		Select:
			#### A 0 A_ChangeSprite;
			#### # 1;
			Loop;
		Deselect:
			#### A 0 A_ChangeSprite;
			#### # 1;
			Loop;
		Altfire:
			#### A 1 A_WeapAction;
			#### A 3;
			#### A 0 A_DDFlash;
			#### A 2 A_DDTransformation;
			#### A 1 A_FireDDWeapon;
			#### A 6;
			#### A 2 A_WeapAction;
			Goto Ready;
		Reload:
		ReloadA:
		ReloadP:
			#### A 2 A_ChangeSprite;
			#### # 5 A_DDTransformation;
			#### B 7;
			#### C 8;
			#### D 1 A_OpenShotgun2;
			#### D 5 A_WeapAction;
			#### D 1;
		Reload2:
			#### A 7 A_WeapAction;
			#### A 2 A_ChangeSprite;
			#### D 5;
			#### E 7;
			#### F 0 A_LoadShotgun2;
			#### F 3 A_WeapAction;
			#### F 1;
		Reload3:
			#### F 6;
			#### G 5;
			#### G 1 A_CloseShotgun2;
			#### H 6 A_WeapAction;
			#### H 6 A_DDRefire;
			#### A 5;
			Goto Ready;
		ReloadOneHanded:
			ST2R A 1 A_ChangeSprite;
			#### A 4;
			#### B 5 A_OpenShotgun2;
			#### B 8 A_DDTransformation;
			#### C 5;
			#### C 4 A_LoadShotgun2;
			#### C 3;
			#### B 5 A_WeapAction;
			Goto Ready;
		UnloadP:
			Goto Ready;
		ReloadingArm:
			TNT1 A 8;
			SARM C 0;
			#### # 10 A_DDTransformation;
			SARM C 4;
			SARM D 5;
			SARM D 11 A_DDTransformation;
			SARM D 4;
			TNT1 A 1;
			Stop;
		FlashA:
		Boom:
			SH2F A 4 A_DDTransformation;
			SH2F A 2 Bright A_Light1;
			SH2F B 2 Bright A_Light1;
			Goto FlashDone;
		Blam:
			SH2F A 4 A_DDTransformation;
			SH2F C 2 Bright A_Light1;
			SH2F D 2 Bright A_Light1;
			Goto FlashDone;
		FlashP:
			SHT2 A 3 A_DDTransformation;
			SHT2 I 4 Bright A_Light1;
			SHT2 J 3 Bright A_Light2;
			Goto FlashDone;
		Ind:
			SH2R A 1;
			SH2L A 1;
			Stop;
		Spawn:
			SGN2 A -1;
			Stop;
	}
}

// #Class BFS : Ammo()
class BFS : Ammo
{	
	Default
	{
		Inventory.PickupMessage "Picked up a couple of big f#@kin' shells.";
		Inventory.Amount 2;
		Inventory.MaxAmount 50;
		Ammo.BackpackAmount 10;
		Ammo.BackpackMaxAmount 100;
		Inventory.Icon "BFSSA0";
		Tag "Big freakin shells";	
	}
	States
	{
		Spawn:
			BFSS A -1;
			Stop;
	}
}

class BFShellBox : BFS
{
	Default
	{
		Inventory.PickupMessage "Picked up a whole box of BFS! Oh yea.";
		Inventory.Amount 16;
		Tag "Box o' abnormally sized shells";
	}
	States
	{
		Spawn:
			BFKB A -1;
			Stop;
	}
}

class Shelle : Shell{}
class ShellBoxe : ShellBox{}
class ShellSpawner : RandomSpawner replaces Shell
{
	Default
	{
		DropItem "Shelle", 255, 45;
		DropItem "BFS", 255, 24;
	}
	
	override Name ChooseSpawn()
	{
		//check if doom2
		if(TexMan.CheckForTexture("SGN2A0", TexMan.Type_Sprite).IsValid()) 	{ return Super.ChooseSpawn(); }
		else { return "Shelle"; }
	}	
}

class ShellBoxSpawner : RandomSpawner replaces ShellBox
{
	Default
	{
		DropItem "ShellBoxe", 255, 45;
		DropItem "BFShellBox", 255, 24;
	}
	
	override Name ChooseSpawn()
	{
		if(TexMan.CheckForTexture("SGN2A0", TexMan.Type_Sprite).IsValid()) { return Super.ChooseSpawn(); }
		else { return "ShellBoxe"; }
		
	}	
}

extend class ddWeapon
{
	action void A_FireDDSShotgun()
	{
		let ddp = ddPlayer(invoker.owner);
		if(ddp.player == null) { return; } 
		ddWeapon weap = ddWeapon(self);
		bool pen = (ddp.player.readyweapon is "dualWielding"&&!ddp.CheckESOA(0));
		int kick = (pen) ? 2 : 1;
		double eA = 0;
		double eP = 0;
		int dam;

		double pitch = BulletSlope ();
		ddp.A_StartSound ("weapons/sshotf", CHAN_WEAPON, CHANF_OVERLAP);
		for(int i = 0 ; i < 20 ; i++)
		{
			dam = 5 * random[FireSG2](1, 3);
			if(pen) { eA = Random2() * (15.75 / 256); eP = Random2() * (11.25 / 256); }
			else { eA = Random2() * (11.25 / 256); eP = Random2() * (7.097 / 256); }
			ddShot(false, "BulletPuff", dam, eA, eP, weap.weaponside, kick);
		}	
		if(pen) { AddRecoil(18., 7, 4.5); }
		else { AddRecoil(12., 2, 4.0); }
	}
	
	action void A_FireDDSShotgunSingle()
	{
		let ddp = ddPlayer(invoker.owner);
		if(ddp.player == null) { return; }
		ddWeapon weap = ddWeapon(self);
		bool pen = (ddp.player.readyweapon is "dualWielding"&&!ddp.CheckESOA(0));
		int kick = (pen) ? 2 : 1;
		double eA, eP = 0;
		int dam;
		ddp.A_StartSound("weapons/sshotf", CHAN_WEAPON, CHANF_OVERLAP);
		for(int x = 0; x < 10; x++)
		{
			dam = 5 * random(1,3);
			if(pen) { eA = Random2() * (5.65 / 256); eP = Random2() * (6.66 / 256); }
			else { eA = Random2() * (4.75 / 256); eP = Random2() * (5.097 / 256); }
			ddShot(false, "BulletPuff", dam, eA, eP, weap.weaponside, kick);
		}	
		if(pen) { AddRecoil(15., 6, 4.); }
		else { AddRecoil(9., 2, 4.); }
	}
}