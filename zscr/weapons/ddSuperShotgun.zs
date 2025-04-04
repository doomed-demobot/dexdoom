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

class ddSuperShotgun : ddWeapon
{
	Default
	{
		Weapon.SelectionOrder 400;
		Weapon.AmmoUse 2;
		Weapon.AmmoGive 8;
		Weapon.AmmoUse2 1;
		Weapon.AmmoType "BFS";
		Weapon.AmmoType2 "BFS";
		ddWeapon.ClassicAmmoType1 "Shell";
		ddWeapon.ClassicAmmoType2 "Shell";
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
		if(owner is "ddPlayerNormal")
		{
			//speed up states when berserk
			let myside = (weaponside) ? owner.player.getpsprite(PSP_LEFTW) : owner.player.getpsprite(PSP_RIGHTW);
			let myflash = (weaponside) ? owner.player.getpsprite(PSP_LEFTWF) : owner.player.getpsprite(PSP_RIGHTWF);
			if(weaponstatus == DDW_RELOADING) { if(myside.tics > 3) { myside.tics--; } if(myflash.tics > 1) { myflash.tics--; } }
		}
	}
	
	override void OnAutoReload()
	{
		ddWeaponFlags &= ~SST_RALL;
	}
	
	override void InventoryInfo(ddStats ddhud)
	{
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
	
	override String getParentType()
	{
		return "ddSuperShotgun";
	}
	
	override String, int GetSprites(int forcemode)
	{
		let ddp = ddPlayer(owner);	
		if(forcemode < 0)
		{
			if(ddp.player.readyweapon is "dualWielding" || ddp.player.pendingweapon is "dualWielding" || ddp.lastmode is "dualWielding")  { return "SH2DA0", -1; }
			else if(ddp.player.readyweapon is "twoHanding" || ddp.player.pendingweapon is "twoHanding" || ddp.lastmode is "twoHanding")   { return "SHT2A0", -1; }
			else { return "TNT1A0"; }
		}
		else if(forcemode == 2) { return "SH2DA0", -1; }
		else if(forcemode == 1) { return "SHT2A0", -1; }
		else { return "TNT1A0", -1; }
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
		if(ModeCheck(4) == (RES_TWOHAND || RES_HASESOA)) 
		{ 
			ddPlayer(owner).ddWeaponState |= DDW_RIGHTNOBOBBING; 
			ddPlayer(owner).ddWeaponState &= ~DDW_RIGHTREADY;			
			weaponStatus = DDW_RELOADING;
			
			if(ddWeaponFlags & 4) { SetCaseNumber(2); return FindState("Reload2"); }
			else if(ddWeaponFlags & 5) { SetCaseNumber(5); return FindState("Reload3"); }
			else if(ddWeaponFlags & 6) { SetCaseNumber(2); return FindState("Reload2A"); }
			else if(ddWeaponFlags & 7) { SetCaseNumber(5); return FindState("Reload3A"); }
			else { return FindState("Ready"); }
		}
		else { return FindState("Ready"); }
	}
	
	override State wannaReload()
	{
		if(weaponstatus == DDW_UNLOADING) { SetCaseNumber(3); return FindState('UnloadP'); }
		if(ddWeaponFlags & SST_RSEQ1) { SetCaseNumber(2); weaponStatus = DDW_RELOADING; return FindState('Reload2'); }
		if(ddWeaponFlags & SST_RSEQ2) { SetCaseNumber(5); weaponStatus = DDW_RELOADING; return FindState('Reload3'); }
		else if(mag < default.mag) { SetCaseNumber(4); weaponStatus = DDW_RELOADING; return FindState('ReloadP'); }
		else { return FindState('DoNotJump'); }
	}
	
	override void primaryattack()
	{
		let ddp = ddPlayer(owner);		
		if(mag > 1) { if(!ddp.FindInventory("ClassicModeToken")) { mag -= 2; } else { ddp.TakeInventory("Shell", 2); } A_FireDDSShotgun(); }
		else if(mag > 0) { mag--; A_FireDDSShotgunSingle(); }
		else { }
	}
	
	override void alternativeattack()
	{
		let ddp = ddPlayer(owner);
		if(mag > 0) { mag--; A_FireDDSShotgunSingle(); }
		else { }
	}
	
	override void DD_WeapAction(int no)
	{
		let ddp = ddPlayer(owner);
		let mode = ddWeapon(ddp.player.readyweapon);
		let me = ddWeapon(self);
		let cpiece = ddWeapon(me.companionpiece);
		int myside = (weaponside) ? PSP_LEFTW : PSP_RIGHTW; 
		int flashside = (weaponside) ? PSP_LEFTWF : PSP_RIGHTWF;
		let res = ModeCheck();
		switch(no)
		{
			case 1: //init/mode check
				if(res == RES_CLASSIC && (ddp.CountInv("Shell") < 2)) { ChangeState("NoAmmo", myside); break; }
				if(mag < 1 && ddp.CountInv("BFS") < 1) { ChangeState("NoAmmo", myside); break; }
				if(res == RES_DUALWLD) { //lower to reload
					if(mag < 1 && !(ddWeaponFlags & 7)) { ddWeaponFlags |= SST_RQUIK; ChangeState("ReloadP", myside); break; }
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
				if(res == RES_CLASSIC && ddp.CountInv("Shell") >= 1) { ChangeState("ReloadP", myside); break; }
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
			default: ddp.A_Log("No action defined for tic "..no); break;
		}
		
	}
	
	
	// ## ddSuperShotgun States()
	States
	{
		NoAmmo:
			SHT2 A 10;
		Ready:
			SHT2 A 1;
			Loop;
		Deselect:
			SHT2 A 1;
			Loop;
		Select:
			SHT2 A 1;
			Loop;
		Fire:
			Goto Ready;
		Altfire:
			Goto Ready;
		ReloadP:		
			Goto Ready;	
		Reload:
		ReloadA:	
			Goto Ready;
		FlashP:
			SHT2 I 4 Bright A_Light1;
			SHT2 J 3 Bright A_Light2;
			Goto FlashDone;
		Spawn:
			SGN2 A -1;
			Stop;
	}
}
// #Class ddSuperShotgunLeft : ddSuperShotgun()
class ddSuperShotgunLeft : ddSuperShotgun
{
	Default { ddweapon.weaponside CE_LEFT; -DDWEAPON.GOESININV; }
	States
	{
		NoAmmo:
			#### A 10;
		Ready:
			SH2D A 0 A_ChangeSpriteLeft;
			#### A 1 A_LeftWeaponReady;
			Loop;
		Fire:
			#### A 1 A_WeapActionLeft;
			#### A 3;
			#### A 0 A_FlashLeft;
			#### A 1 A_FireLeftWeapon;
			#### A 6;
			#### A 2 A_WeapActionLeft;
			Goto Ready;
		Select:
			#### A 1 A_ChangeSpriteLeft;
			Loop;
		Altfire:
			#### A 1 A_WeapActionLeft;
			#### A 3;
			#### A 0 A_FlashLeft;
			#### A 1 A_FireLeftWeapon;
			#### A 6;
			#### A 2 A_WeapActionLeft;
			Goto Ready;
		Reload:
		ReloadA:
		ReloadP:			
			#### B 7;
			#### C 7;
			#### D 1 A_OpenShotgun2;
			#### D 5 A_WeapActionLeft;
			#### D 1;
		Reload2:
			#### D 5;
			#### E 7;
			#### F 0 A_LoadShotgun2;
			#### F 3 A_WeapActionLeft;
			#### F 1;
		Reload3:
			#### F 6;
			#### G 5;
			#### G 1 A_CloseShotgun2;
			#### H 6 A_WeapActionLeft;
			#### H 6 A_ddRefireLeft;
			#### A 5;
			Goto Ready;
		UnloadP:
			#### BC 7;
			#### D 7 A_OpenShotgun2;
			#### F 5 A_LoadShotgun2;
			#### E 4 A_WeapActionLeft;
			#### E 5;
			#### G 6 A_CloseShotgun2;
			#### HA 6;
			Goto Ready;			
		FlashA:
		Boom:
			SH2F A 2 Bright A_Light1;
			SH2F B 2 Bright A_Light1;
			Goto FlashDone;
		Blam:
			SH2F C 2 Bright A_Light1;
			SH2F D 2 Bright A_Light1;
			Goto FlashDone;
	}
}
// #Class ddSuperShotgunRight : ddSuperShotgun()
class ddSuperShotgunRight : ddSuperShotgun
{
	Default { ddweapon.weaponside CE_RIGHT; -DDWEAPON.GOESININV; }
	States
	{
		NoAmmo:
			#### A 10;
		Ready:
			SH2D A 0 A_ChangeSpriteRight;
			#### A 1 A_RightWeaponReady;
			Loop;
		Select:
			#### A 1 A_ChangeSpriteRight;
			Loop;
		Fire:
			#### A 1 A_WeapActionRight;
			#### A 3;
			#### A 0 A_FlashRight;
			#### A 1 A_FireRightWeapon;
			#### A 6;
			#### A 2 A_WeapActionRight;
			Goto Ready;
		Altfire:
			#### A 1 A_WeapActionRight;
			#### A 3;
			#### A 0 A_FlashRight;
			#### A 1 A_FireRightWeapon;
			#### A 6;
			#### A 2 A_WeapActionRight;
			Goto Ready;			
		Reload:
		ReloadA:
		ReloadP:
			#### B 7;
			#### C 7;
			#### D 1 A_OpenShotgun2;
			#### D 5 A_WeapActionRight;
			#### D 1;
		Reload2:
			#### D 5;
			#### E 7;
			#### F 0 A_LoadShotgun2;
			#### F 3 A_WeapActionRight;
			#### F 1;
		Reload3:
			#### F 6;
			#### G 5;
			#### G 1 A_CloseShotgun2;
			#### H 6 A_WeapActionRight;
			#### H 6 A_ddRefireRight;
			#### A 5;
			Goto Ready;
		UnloadP:
			#### BC 7;
			#### D 7 A_OpenShotgun2;
			#### F 5 A_LoadShotgun2;
			#### E 4 A_WeapActionRight;
			#### G 6 A_CloseShotgun2;
			#### HA 6;
			Goto Ready;
		FlashA:
		Boom:
			SH2F A 2 Bright A_Light1;
			SH2F B 2 Bright A_Light1;
			Goto FlashDone;
		Blam:
			SH2F C 2 Bright A_Light1;
			SH2F D 2 Bright A_Light1;
			Goto FlashDone;
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
		Tag "Box o' bio force";
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
		for(int x = 0; x < 8; x++)
		{
			if(players[x].mo is "ddPlayerClassic")
			{
				return "Shelle";
			}
		}
		if(TexMan.CheckForTexture("SGN2A0", TexMan.Type_Sprite).IsValid()) { return Super.ChooseSpawn(); }
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
		for(int x = 0; x < 8; x++)
		{
			if(players[x].mo is "ddPlayerClassic")
			{
				return "ShellBoxe";
			}
		}
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
			if(pen) { eA = Random2() * (8.75 / 256); eP = Random2() * (9.25 / 256); }
			else { eA = Random2() * (6.75 / 256); eP = Random2() * (5.097 / 256); }
			ddShot(false, "BulletPuff", dam, eA, eP, weap.weaponside, kick);
		}	
		if(pen) { AddRecoil(15., 6, 4.); }
		else { AddRecoil(9., 2, 4.); }
	}
}

// #Class BreakActionSpawner : RandomSpawner replaces SuperShotgun()
class BreakActionSpawner : RandomSpawner replaces SuperShotgun
{
	Default
	{
		DropItem "ddSuperShotgun", 255, 60;
		DropItem "PowerFist", 255, 9;
	}
	
	override Name ChooseSpawn()
	{
		for(int x = 0; x < 8; x++)
		{
			if(players[x].mo is "ddPlayerClassic")
			{
				return "ddSuperShotgun";
			}
		}
		return Super.ChooseSpawn();
	}
}