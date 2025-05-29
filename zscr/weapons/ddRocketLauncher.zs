// #Class ddRocketLauncher : ddWeapon replaces RocketLauncher()
// Doom Rocket Launcher. 4 mag, reloads automatically when two handed. Must lower other
// weapon to reload. Grenade launcher altfire.
//TODO: make grenades like tf2
enum ddRLFlags
{
	RKL_RSEQ = 1,
	RKL_RLOD = 2, //for interrupting reload with fire button in tick function [unused]
};

class ddRocketLauncher : ddWeapon replaces RocketLauncher
{
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
		ddWeapon.SwitchSpeed 1.2;
		ddWeapon.InitialMag 6;
		ddWeapon.MagUse1 1;
		ddWeapon.WeaponType "Launcher";
		+WEAPON.NOAUTOFIRE
		Inventory.PickupMessage "$GOTLAUNCHER";
		Tag "$TAG_ROCKETLAUNCHER";
	}
	
	override void InventoryInfo(ddStats ddhud, bool debug)
	{
		if(debug) { Super.InventoryInfo(ddhud, debug); return; }
		let hud = ddhud;
		hud.DrawString(hud.fa, GetTag(), (30, 45), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, "level "..hud.FormatNumber(rating).." heavy launcher", (30, 55), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, hud.FormatNumber(mag).."/"..hud.FormatNumber(default.mag), (30, 65), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
	}
	
	override void OnAutoReload()
	{
		ddWeaponFlags &= 3;
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
		if(fireMode == 0) { return TexMan.CheckForTexture("ICONSING"); }
		else if (fireMode == 1) { return TexMan.CheckForTexture("ICONGREN"); }
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

	override void onWeaponFire(int side, bool held)
	{
		if(!owner) { return; }
		if(held) { return; }
		if(ddWeaponFlags & RKL_RLOD) { ddWeaponFlags &= ~RKL_RLOD; ChangeState("RFinish", (weaponside) ? PSP_LEFTW : PSP_RIGHTW); }
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
	
	override State GetReadyState()
	{
		ddWeaponFlags &= ~RKL_RLOD;
		if(ddWeaponFlags & RKL_RSEQ) { weaponStatus = DDW_RELOADING; return FindState("RFinish"); }
		else { return FindState("Ready"); }
	}
	
	override State wannaReload()
	{
		if(mag > 0 && weaponstatus == DDW_UNLOADING) { return FindState("UnloadP"); }
		if(mag < default.mag) { ddWeaponFlags |= RKL_RSEQ; weaponStatus = DDW_RELOADING; return FindState('ReloadP'); }
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
		if(mag > 0) { mag--; A_FireDDGrenade(); }
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
			case 1: //init/ammo check
				if(res == RES_CLASSIC && ddp.CountInv("RocketAmmo") < 1) { ChangeState("NoAmmo", myside); break; }
				if(mag < 1 && ddp.CountInv("RocketAmmo") < 1) { ChangeState("NoAmmo", myside); break; }
				if(res == RES_DUALWLD) {
					if(mag < 1) { 
						LowerToReloadWeapon(); break; 
					}
					break;
				}
				else if(res == RES_HASESOA || res == RES_TWOHAND) {
					if(ddp.CountInv("RocketAmmo") < 1) { break; }
					if(mag < 1) { 
						weaponstatus = DDW_RELOADING;
						ChangeState("ReloadP", myside); break; 
					}
					ddp.PlayAttacking();
					break;
				}
				else { ddp.PlayAttacking(); break; }
			case 2: //auto reload if twohanding
				if(res == RES_HASESOA || res == RES_TWOHAND) { 
					if(mag < 1) { ddWeaponFlags |= RKL_RLOD; ddWeaponFlags |= RKL_RSEQ; weaponstatus = DDW_RELOADING; ChangeState("ReloadP", myside); break; } 
					else { break; } 
				}
				else { break; }
			case 3: //reload checks 1
				if(mag < default.mag && ddp.CountInv("RocketAmmo") > 0) { 
					mag++; ddp.TakeInventory("RocketAmmo", 1); ddp.A_StartSound("weapons/rocketload", CHAN_WEAPON, CHANF_OVERLAP);
					if(mag >= default.mag || ddp.CountInv("RocketAmmo") < 1) {
						ddWeaponFlags &= ~RKL_RLOD; ddWeaponFlags |= RKL_RSEQ; 
						ChangeState("RFinish", myside); 					
					}
				}
				else { 
					ddWeaponFlags &= ~RKL_RLOD; ddWeaponFlags |= RKL_RSEQ; 
					ChangeState("RFinish", myside); 
				}
				break;
			case 4: //reload checks 2
				if(mag < default.mag && ddp.CountInv("RocketAmmo") > 0) { 
					mag++; ddp.TakeInventory("RocketAmmo", 1); ddp.A_StartSound("weapons/rocketload", CHAN_WEAPON, CHANF_OVERLAP);
					if(mag >= default.mag || ddp.CountInv("RocketAmmo") < 1) {
						ddWeaponFlags &= ~RKL_RLOD; ddWeaponFlags |= RKL_RSEQ; 
						ChangeState("RFinish", myside); 					
					}
					else { ChangeState("Load", myside); break; }
				}
				else { 
					ddWeaponFlags &= ~RKL_RLOD; ddWeaponFlags |= RKL_RSEQ; 
					ChangeState("RFinish", myside); 
				}
				break;
			case 5: //checks during unload
				if(mag > 0 && PressingFireButton()) { ddp.A_StartSound("weapons/shotgp", CHAN_WEAPON, CHANF_OVERLAP); break; }
				else
				{
					if(mag > 0) {
						mag--; ddp.GiveInventory("RocketAmmo", 1); ddp.A_StartSound("weapons/rocketload", CHAN_WEAPON, CHANF_OVERLAP); ChangeState("Unload", myside);
					}
					else { ddp.A_StartSound("weapons/shotgp", CHAN_WEAPON, CHANF_OVERLAP); }
					break;
				}
			case 6:
				ddWeaponFlags |= RKL_RLOD;
				break;
			case 7:
				ddWeaponFlags &= ~RKL_RSEQ;
				break;
			default: ddp.A_Log("No action defined for tic "..no); break;
		}
	}
	
	// ## ddRocketLauncher States()
	States
	{
		NoAmmo:
			MISG A 10;
		Ready:
			MISG A 1 A_DDWeaponReady;
			Loop;
		Fire:
			MISG A 1 A_WeapAction;
			MISG B 0 A_DDFlash;
			MISG B 8;
			MISG B 12 A_FireDDWeapon;
			MISG B 2 A_WeapAction;
			MISG B 0 A_DDRefire;
			Goto Ready;
		Altfire:
			MISG A 1 A_WeapAction;
			MISG A 1;
			MISG B 14 A_FireDDWeapon;
			MISG B 2 A_WeapAction;
			MISG B 0 A_DDRefire;
			Goto Ready;
		ReloadA:
		ReloadP:
			MISG B 5;
			MISG B 6 A_WeapAction;
			MISG B 1;
		Load:
			MISG B 10;
			MISG B 3 A_WeapAction;
			MISG B 5;
			MISG B 4 A_WeapAction;
			MISG B 1;
		RFinish:
			MISG A 5;
			MISG A 5 A_RLPump1;
			MISG A 2 A_RLPump2;
			MISG A 7 A_WeapAction;
			Goto Ready;
		UnloadP:
			MISG B 5;
		Unload:
			MISG B 5;
			MISG A 5 A_WeapAction;
			MISG A 10;
			Goto Ready;
		Flash:
			MISF A 3 Bright A_Light1;
			MISF B 4 Bright;
			MISF CD 4 Bright A_Light2;
			Goto FlashDone;
		Select:
			MISG A 1;
			Loop;
		Deselect:
			MISG A 1;
			Loop;
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
			MISG A 1 A_DDWeaponReady;
			Loop;
		Fire:
			MISG A 1 A_WeapAction;
			MISG B 0 A_DDFlash;
			MISG B 8;
			MISG B 12 A_FireDDWeapon;
			MISG B 2 A_WeapAction;
			MISG B 0 A_DDRefire;
			Goto Ready;
		Altfire:
			MISG A 1 A_WeapAction;
			MISG A 1;
			MISG B 14 A_FireDDWeapon;
			MISG B 2 A_WeapAction;
			MISG B 0 A_DDRefire;
			Goto Ready;
		ReloadA:
		ReloadP:
			MISG B 5;
			MISG B 6 A_WeapAction;
			MISG B 1;
		Load:
			MISG B 10;
			MISG B 3 A_WeapAction;
			MISG B 5;
			MISG B 4 A_WeapAction;
			MISG B 1;
		RFinish:
			MISG A 5;
			MISG A 5 A_RLPump1;
			MISG A 2 A_RLPump2;
			MISG A 7 A_WeapAction;
			Goto Ready;
		UnloadP:
			MISG B 5;
		Unload:
			MISG B 5;
			MISG A 5 A_WeapAction;
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
			MISG A 1 A_DDWeaponReady;
			Loop;
		Fire:
			MISG A 1 A_WeapAction;
			MISG B 0 A_DDFlash;
			MISG B 8;
			MISG B 12 A_FireDDWeapon;
			MISG B 2 A_WeapAction;
			MISG B 0 A_DDRefire;
			Goto Ready;
		Altfire:
			MISG A 1 A_WeapAction;
			MISG A 1;
			MISG B 14 A_FireDDWeapon;
			MISG B 2 A_WeapAction;
			MISG B 0 A_DDRefire;
			Goto Ready;
		ReloadA:
		ReloadP:
			MISG B 5;
			MISG B 6 A_WeapAction;
			MISG B 1;
		Load:
			MISG B 10;
			MISG B 3 A_WeapAction;
			MISG B 5;
			MISG B 4 A_WeapAction;
			MISG B 1;
		RFinish:
			MISG A 5;
			MISG A 5 A_RLPump1;
			MISG A 2 A_RLPump2;
			MISG A 7 A_WeapAction;
			Goto Ready;
		UnloadP:
			MISG B 5;
		Unload:
			MISG B 5;
			MISG A 5 A_WeapAction;
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
	
	action void A_FireDDGrenade()
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
		AddRecoil(0.0, 0, 1.5);
		
	}
	
	action void A_RLPump1()
	{
		invoker.owner.A_StartSound("weapons/shotgp1", CHAN_WEAPON, CHANF_OVERLAP);
	}
	
	action void A_RLPump2()
	{
		invoker.owner.A_StartSound("weapons/shotgp2", CHAN_WEAPON, CHANF_OVERLAP);	
	}
}
//TODO: make it not explode after running out of speed/bounces
// #Class ddGrenade : Actor()

class ddGrenade : Actor
{
	bool contact;
	Default
	{
		Radius 11;
		Height 8;
		Speed 40;
		Damage 0;
		Projectile;
		-NOGRAVITY;
		+RANDOMIZE;
		Gravity 1;
		BounceType "None";
		BounceFactor 0.5;
		SeeSound "weapons/grenade";
		BounceSound "weapons/grenadeb";
		DeathSound "weapons/grenadeb";
		Obituary "%o blocked %k's pass.";
		+ALLOWBOUNCEONACTORS;
		+BOUNCEONACTORS;
		+BOUNCEONWALLS;
		+BOUNCEONFLOORS;
		+BOUNCEONCEILINGS;
		+BOUNCEAUTOOFF;
	}
	
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		contact = true;
	}
	
	override int SpecialBounceHit(Actor bounceMobj, Line bounceLine, readonly<SecPlane> bouncePlane)
	{
		if(bounceMobj)
		{
			if(contact && bounceMobj.bismonster)
			{
				console.printf("contact");
				let st = FindState("Death") + 1;
				self.vel = (0, 0, 0);
				SetState(st);
				return MHIT_DEFAULT;
			}
			else
			{
				contact = false;
				return MHIT_DEFAULT;
			}
		}
		else
		{
			contact = false;
			return MHIT_DEFAULT;
		}
	}
	// ##ddGrenade States()
	States
	{
		Spawn:
			GRNA A 1;
			Loop;
		Death:
			GRNA A 30;
			MISL B 0 { self.bNoGravity = true; }
			MISL B 0 A_StartSound("weapons/rocklx", CHAN_BODY);
			MISL B 8 Bright A_Explode;
			MISL C 6 Bright;
			MISL D 4 Bright;
			Stop;
	}
}