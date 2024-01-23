// #Class ddRocketLauncher : ddWeapon replaces RocketLauncher()
// Doom Rocket Launcher. 4 mag, reloads automatically when two handed. Must lower other
// weapon to reload. Grenade launcher altfire.
//TODO: make grenades like tf2
class ddRocketLauncher : ddWeapon replaces RocketLauncher
{
	int grenadeFuse;
	Default
	{
		Weapon.SelectionOrder 2500;
		Weapon.AmmoUse 1;
		Weapon.AmmoGive 2;
		Weapon.AmmoType "RocketAmmo";
		Weapon.AmmoType2 "RocketAmmo";
		ddWeapon.ClassicAmmoType1 "RocketAmmo";
		ddWeapon.ClassicAmmoType2 "RocketAmmo";
		ddWeapon.rating 7;
		ddWeapon.SwitchSpeed 1.0;
		ddWeapon.InitialMag 4;
		ddWeapon.MagUse1 1;
		ddWeapon.WeaponType "Launcher";
		+WEAPON.NOAUTOFIRE
		Inventory.PickupMessage "$GOTLAUNCHER";
		Tag "$TAG_ROCKETLAUNCHER";
	}
	
	override void InventoryInfo(ddStats ddhud)
	{
		let hud = ddhud;		
		hud.DrawString(hud.fa, GetTag(), (30, 45), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, "level "..hud.FormatNumber(rating).." heavy launcher", (30, 55), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
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
	
	override String getParentType()
	{
		return "ddRocketLauncher";
	}	
	
	override String, int GetSprites()
	{
		return "MISGA0", -1;
	}
	
	override String GetWeaponSprite()
	{
		return "LAUNA0";
	}
	
	override State GetFlashState()
	{
		if(!bAltFire) { return FindState('Flash'); } 
		else { return FindState('NoFlash'); }  
	}
	
	override State wannaReload()
	{
		if(mag > 0 && weaponstatus == DDW_UNLOADING) { SetCaseNumber(4); return FindState("UnloadP"); }
		if(mag < default.mag) { SetCaseNumber(2); weaponStatus = DDW_RELOADING; return FindState('ReloadP'); }
		else { return FindState('DoNotJump'); }
	}
	
	override void primaryattack()
	{
		let ddp = ddPlayer(owner);
		if(mag > 0) 
		{ 
			if(!ddp.FindInventory("ClassicModeToken")) { mag--; }
			else { ddp.TakeInventory("RocketAmmo", 1); }
			A_FireDDMissile(); 
		}
	}	
	
	override void alternativeattack()
	{
		let ddp = ddPlayer(owner);
		if(mag > 0) { mag--; A_FireDDGrenade(grenadeFuse); }
	}
	
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
			case 0: //init/ammo check
				if(res == RES_CLASSIC && ddp.CountInv("RocketAmmo") < 1) { ChangeState("NoAmmo", myside); break; }
				if(mag < 1 && ddp.CountInv("RocketAmmo") < 1) { ChangeState("NoAmmo", myside); break; }
				if(res == RES_DUALWLD)
				{
					if(mag < 1) { 
						LowerToReloadWeapon(); SetCaseNumber(2); break; 
					}
					SetCaseNumber(1);
					break;
				}
				else if(res == RES_HASESOA || res == RES_TWOHAND)
				{
					if(ddp.CountInv("RocketAmmo") < 1) { break; }
					if(mag < 1) { 
						weaponstatus = DDW_RELOADING;
						ChangeState("ReloadP", myside); SetCaseNumber(2); break; 
					}
					grenadeFuse = 140; 
					SetCaseNumber(1);
					ddp.PlayAttacking();
					break;
				}
				else { ddp.PlayAttacking(); SetCaseNumber(1); break; }
			case 1: //auto reload if twohanding
				if(res == RES_HASESOA || res == RES_TWOHAND) { 
					if(mag < 1) { weaponstatus = DDW_RELOADING; ChangeState("ReloadP", myside); SetCaseNumber(2); break; } 
					else { SetCaseNumber(0); break; } 
				}
				else { SetCaseNumber(0); break; }
			case 2: //reload checks 1
				if(mag > 0 && PressingFireButton()) { ChangeState("RFinish", myside); ddp.A_StartSound("weapons/shotgp", CHAN_WEAPON, CHANF_OVERLAP); break; }
				else
				{
					if(mag < default.mag && ddp.CountInv("RocketAmmo") > 0) { 
						mag++; ddp.TakeInventory("RocketAmmo", 1); ddp.A_StartSound("weapons/rocketload", CHAN_WEAPON, CHANF_OVERLAP); SetCaseNumber(3);
					}
					else { ChangeState("RFinish", myside); ddp.A_StartSound("weapons/shotgp", CHAN_WEAPON, CHANF_OVERLAP); }
					break;
				}
			case 3: //reload checks 2
				if(mag > 0 && PressingFireButton()) { ChangeState("RFinish", myside); ddp.A_StartSound("weapons/shotgp", CHAN_WEAPON, CHANF_OVERLAP); break; }
				else
				{
					if(mag < default.mag && ddp.CountInv("RocketAmmo") > 0) { 
						mag++; ddp.TakeInventory("RocketAmmo", 1); ddp.A_StartSound("weapons/rocketload", CHAN_WEAPON, CHANF_OVERLAP); SetCaseNumber(2); ChangeState("Load", myside); 
					}
					else { ChangeState("RFinish", myside); ddp.A_StartSound("weapons/shotgp", CHAN_WEAPON, CHANF_OVERLAP); }
					break;
				}
			case 4: //checks during unload
				if(mag > 0 && PressingFireButton()) { ddp.A_StartSound("weapons/shotgp", CHAN_WEAPON, CHANF_OVERLAP); break; }
				else
				{
					if(mag > 0) {
						mag--; ddp.GiveInventory("RocketAmmo", 1); ddp.A_StartSound("weapons/rocketload", CHAN_WEAPON, CHANF_OVERLAP); ChangeState("Unload", myside);
					}
					else { ddp.A_StartSound("weapons/shotgp", CHAN_WEAPON, CHANF_OVERLAP); }
					break;
				}
			case 5: /*countdown timer during altfire
				grenadeFuse--;
				ddp.A_Log(""..grenadefuse);
				bool ret = (myside == PSP_LEFTW) ? (PressingLeftAltFire()) : (PressingRightAltFire());
				if(ret) { ChangeState("Cook", myside); break; }
				else { break; }
				*/
				break;
			default: break;
		}
	}
	
	// ## ddRocketLauncher States()
	States
	{
		NoAmmo:
			MISG A 10;
		Ready:
			MISG A 1;
			Loop;
		Deselect:
			MISG A 1 A_Lower;
			Loop;
		Select:
			MISG A 1;
			Loop;
		Fire:
			Goto Ready;
		Altfire:
			Goto Ready;
		Flash:
			MISF A 3 Bright A_Light1;
			MISF B 4 Bright;
			MISF CD 4 Bright A_Light2;
			Goto FlashDone;
		Spawn:
			LAUN A -1;
			Stop;
	}
}
// #Class ddRocketLauncherLeft : ddRocketLauncher()
class ddRocketLauncherLeft : ddRocketLauncher
{
	Default { ddweapon.weaponside CE_LEFT; -DDWEAPON.GOESININV; }
	States
	{
		NoAmmo:
			MISG A 10;
		Ready:
			MISG A 1 A_LeftWeaponReady;
			Loop;
		Fire:
			MISG A 0 A_DDActionLeft;
			MISG B 0 A_FlashLeft;
			MISG B 8;
			MISG B 12 A_FireLeftWeapon;
			MISG B 0 A_DDActionLeft;
			MISG B 0 A_ddRefireLeft;
			Goto Ready;
		Altfire:
			MISG A 0 A_DDActionLeft;
			MISG A 1 A_DDActionLeft;
			MISG B 12 A_FireLeftWeapon;
			MISG B 0 A_DDActionLeft;
			MISG B 0 A_ddRefireLeft;
			Goto Ready;
		ReloadA:
		ReloadP:
			MISG B 5;
		Load:
			MISG B 15;
			MISG B 5 A_DDActionLeft;
			MISG B 1 A_DDActionLeft;
		RFinish:
			MISG A 2;
			Goto Ready;
		UnloadP:
			MISG B 5;
		Unload:
			MISG B 10;
			MISG A 10 A_DDActionLeft;
			MISG A 10;
			Goto Ready;
			
	}
}
// #Class ddRocketLauncherRight : ddRocketLauncher()
class ddRocketLauncherRight : ddRocketLauncher
{
	Default { ddweapon.weaponside CE_RIGHT; -DDWEAPON.GOESININV; }
	States
	{
		NoAmmo:
			MISG A 10;
		Ready:
			MISG A 1 A_RightWeaponReady;
			Loop;
		Fire:
			MSIG A 0 A_DDActionRight;
			MISG B 0 A_FlashRight;
			MISG B 8;
			MISG B 12 A_FireRightWeapon;
			MISG B 0 A_DDActionRight;
			MISG B 0 A_ddRefireRight;
			Goto Ready;
		Altfire:
			MISG A 0 A_DDActionRight;	
			MISG A 1 A_DDActionRight;
			MISG B 12 A_FireRightWeapon;
			MISG B 0 A_DDActionRight;
			MISG B 0 A_ddRefireRight;
			Goto Ready;
		ReloadA:
		ReloadP:
			MISG B 5;
		Load:
			MISG B 15;
			MISG B 5 A_DDActionRight;
			MISG B 1 A_DDActionRight;
		RFinish:
			MISG A 2;
			Goto Ready;
		UnloadP:
			MISG B 5;
		Unload:
			MISG B 10;
			MISG A 10 A_DDActionRight;
			MISG A 10;
			Goto Ready;
			
	}
}


extend class ddWeapon
{
	action void A_FireDDMissile()
	{
		let ddp = ddPlayer(invoker.owner);
		if(ddp.player == null) { return; }
		ddWeapon weap = ddWeapon(self);
		bool pen = (ddp.player.readyweapon is "dualWielding"&&!ddp.CheckESOA(0));
		int kick = (pen) ? 7 : 2;
		ddp.instability += kick;
		ddp.instTimer = 30;
		ddp.SpawnPlayerMissile("Rocket");
		if(pen) { AddRecoil(0.5, 0, 2.0); } 
		else { AddRecoil(0.0, 0, 1.5); }
	}
	
	action void A_FireDDGrenade(int fuse)
	{
		let ddp = ddPlayer(invoker.owner);
		if(ddp.player == null) { return; }
		ddWeapon weap = ddWeapon(self);
		let pen = (ddp.player.readyweapon is "dualWielding");
		int kick = (pen) ? 7 : 2;
		ddp.instability += kick;
		ddp.instTimer = 20;
		Actor mis1, mis2;
		[mis1, mis2] = ddp.SpawnPlayerMissile("ddGrenade");
		//if(mis1) { ddGrenade(mis1).timer = fuse; }
		//else { ddGrenade(mis2).timer = fuse; }
		AddRecoil(0.0, 0, 1.5);
		
	}
}
//TODO: make it not explode after running out of speed/bounces
// #Class ddGrenade : Actor()
class ddGrenade : Actor
{
	Default
	{
		Radius 11;
		Height 8;
		Speed 40;
		Damage 15;
		Projectile;
		-NOGRAVITY;
		+RANDOMIZE;
		Gravity 1;
		BounceType "None";
		BounceFactor 0.5;
		SeeSound "weapons/grenade";
		BounceSound "weapons/grenadeb";
		DeathSound "weapons/rocklx";
		Obituary "%o blocked %k's pass.";
		+BOUNCEONWALLS;
		+BOUNCEONFLOORS;
		+BOUNCEONCEILINGS;
		+BOUNCEAUTOOFF;
	}
	// ##ddGrenade States()
	States
	{
		Spawn:
			GRNA A 1;
			Loop;
		Death:
			MISL B 0 { self.bNoGravity = true; }
			MISL B 8 Bright A_Explode;
			MISL C 6 Bright;
			MISL D 4 Bright;
			Stop;
	}
}