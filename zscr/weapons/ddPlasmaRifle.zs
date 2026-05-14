// #Class ddPlasmaRifle : ddWeapon replaces PlasmaRifle()
//Doom Plasma Rifle. Battery (mag) must be manually charged to fire.
//Altfire charges shot, using more cells and battery. Don't waste it.
class ddPlasmaRifle : ddWeapon replaces PlasmaRifle
{
	int charge; 
	
	Default
	{
		Weapon.SelectionOrder 100;
		Weapon.AmmoUse 1;
		Weapon.AmmoUse2 2;
		Weapon.AmmoGive 40; 
		Weapon.AmmoType "Cell";
		Weapon.AmmoType2 "Cell";
		ddWeapon.rating 7;
		ddWeapon.SwitchSpeed 1.25;
		ddWeapon.InitialMag 50;
		ddWeapon.ChargeUse 0;
		ddWeapon.ChargeUse2 0;
		ddWeapon.WeaponType "Rifle";
		ddWeapon.costMulti 0;
		+DDWEAPON.NOLOWER;
		Inventory.PickupMessage "$GOTPLASMA";
		Tag "$TAG_PLASMARIFLE";
	}
	
	override void InventoryInfo(ddStats ddhud, bool debug)
	{
		if(debug) { Super.InventoryInfo(ddhud, debug); return; }
		let hud = ddhud;		
		hud.DrawString(hud.fa, GetTag(), (30, 45), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, "level "..hud.FormatNumber(rating).." rifle", (30, 55), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		double per = 100. - ((((default.mag - mag) + 0.0) / default.mag + 0.0) * 100.);
		hud.DrawString(hud.fa, "BATTERY: "..hud.FormatNumber(per).."%", (30, 65), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
	}
	
	override void PreviewInfo(ddStats ddhud)
	{
		let hude = ddhud;
		hude.DrawString(hude.fa, GetTag(), (12, 45), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
		double per = 100. - ((((default.mag - mag) + 0.0) / default.mag + 0.0) * 100.);
		hude.DrawString(hude.fa, "BATTERY: "..hude.FormatNumber(per).."%", (12, 52), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
		hude.DrawString(hude.fa, "Spare ammo: "..hude.FormatNumber(AmmoGive1), (12, 59), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
	}
	
	override TextureID GetFireModeIcon()
	{
		if(fireMode == 0) { return TexMan.CheckForTexture("ICONSING"); }
		else if (fireMode == 1) { return TexMan.CheckForTexture("ICONGREN"); }
		else { return Super.GetFireModeIcon(); }
	}
	
	override void Travelled()
	{
		Super.Travelled();
		if(owner) { owner.GiveInventory("Cell", (charge * 2)); }
		charge = 0;
	}
	
	override void HUDA(ddStats hude)
	{	
		int warn = (mag < 6) ? 255 : ((mag < 16) ? 128 : 0); 
		int big = (charge < 15) ? 255 : 20;
		double bar = 40 * ((mag + 0.0)/(default.mag + 0.0));
		double cbar = 40 * ((charge + 0.0)/25.);
		if(owner.player.readyweapon is "twoHanding")
		{ 
			hude.Fill(Color(150, warn, 0, 255 - warn), -18, -19, bar, 4, hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER); 
			hude.Fill(Color(150, big, 255, 0), -18, -15, cbar, 4, hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER); 
		}
		else if(owner.player.readyweapon is "dualWielding")
		{
			if(weaponside == CE_LEFT)
			{
				hude.Fill(Color(150, warn, 0, 255 - warn), -82, -19, bar, 4, hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER);
				hude.Fill(Color(150, big, 255, 0), -82, -15, cbar, 4, hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER);
					
			}
			else
			{
				hude.Fill(Color(150, warn, 0, 255 - warn), 46, -19, bar, 4, hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER); 
				hude.Fill(Color(150, big, 255, 0), 46, -15, cbar, 4, hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER);				
			}
			
		}
	}
	
	override String, int GetSprites(int no)
	{
		let ddp = ddPlayer(owner);
		if(!ddp) { return "TNT1", -1; }
		int res = ModeCheck();
		if(res == RES_TWOHAND) { return "PLSG", 1; }
		else if(res == RES_DUALWLD) { return "PLSG", 2; }
		else { return "TNT1", -1; }
	}
	
	override String GetWeaponSprite()
	{
		return "PLASA0";
	}
	
	override String getParentType()
	{
		return "ddPlasmaRifle";
	}
	
	override int GetTicks(int no)
	{
		if(!bAltFire)
		{
			if(mag < 10)
			{
				return 6;
			}
			else if(mag < 20)
			{
				return 3;
			}
			else
			{
				return 2;
			}
		}
		else
		{
			return 2;
		}
	}	
		
	override State GetRefireState()
	{
		if(!bAltFire) {return Super.GetRefireState(); } 
		else { if(mag > 0 && charge < 25) { return FindState('Charging'); }
				else { return FindState('DoNotJump'); }
		}
	}
	
	override State GetFlashState()
	{		
		let ddp = ddPlayer(owner);
		if(weaponstatus == DDW_RELOADING) {
			if(ddp.player.readyweapon is "dualWielding" || ddp.player.pendingweapon is "dualWielding" || ddp.lastmode is "dualWielding") { return FindState('FlashRechargeDW'); }
			else if(ddp.player.readyweapon is "twoHanding" || ddp.player.pendingweapon is "twoHanding" || ddp.lastmode is "twoHanding") { return FindState('FlashRechargeTH'); }
			else { }
		}
		if(bAltFire)
		{
			if(charge < 4) { return FindState('Altflash'); }
			else { return FindState('AltFlash2'); }
		}
		
		State st = (random(0,1)) ? FindState('Flash') : FindState('Flash2');
		return st;
	}
	
	override void primaryattack()
	{
		let ddp = ddPlayer(owner);
		if(owner.CountInv("Cell") > 0 && mag > 0) { mag--; A_FireDDPlasma(); }
	}
	
	override void alternativeattack()
	{
		A_FirePlasmaBlast(charge); 
		charge = 0;
	}
	
	override State wannaReload()
	{
		let ddp = ddPlayer(owner);
		if(mag < default.mag) { weaponstatus = DDW_RELOADING; return FindState("ReloadP"); }
		else { return FindState("DoNotJump"); }
	}
	
	override void SetDDTransformations(int no, PSpriteInfo pspi)
	{
		let ddp = ddPlayer(owner);
		if(!ddp) { return; }
		let i = (weaponside) ? ddp.leftInstability : ddp.rightInstability;
		switch(no)
		{
			case 1: //fire
				pspi.SetTransformationProperties(3, true, (INTR_TRANS_INVEXPO));
				pspi.SetTranslations(0, 5);
				return;
			case 2: //reload
				let pspif = ddp.GetPSpriteInfo(pspi.id + 10, ddp);
				pspi.SetTransformationProperties(6, false, (INTR_TRANS_INVEXPO));
				pspi.SetTranslations(-5, 8);
				pspif.SetTransformationProperties(6, false, (INTR_TRANS_INVEXPO));
				pspif.SetTranslations(-5, 8);
				return;
			default:
				return;
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
		switch(no)
		{
			case 1: //init/ammo check
				int cost = (bAltFire) ? AmmoUse2 : AmmoUse1;
				if(ddp.CountInv("Cell") < cost) { charge = 0; ChangeState('NoAmmo', myside); break; }
				ddp.PlayAttacking();
				break;
			case 2: //mag check
				if(mag < 1) { weaponstatus = DDW_RELOADING; ChangeState('ReloadP', myside); break; }
				break;
			case 3: //alt charge shot
				if(mag > 0 && ddp.CountInv("Cell") > 1)
				{
					ddp.A_StartSound("weapons/plasmax", CHAN_WEAPON, 0, 0.5, ATTN_NORM, (1.1 + (0.1 * charge)));
					charge++;
					ddp.TakeInventory("Cell", 2);
					mag-=1;
				}
				else { charge = 0; ddp.A_StartSound("misc/woosh", CHAN_WEAPON, CHANF_OVERLAP); ChangeState("NoAmmo", myside); ChangeState(null, flashside); break; }
				break;
			case 4: //reload
				mag += 5;
				double pit = 1. * ((mag+0.0)/(default.mag+0.0));
				ddp.A_StartSound("weapons/plasmax", CHAN_WEAPON, CHANF_OVERLAP, 1., ATTN_NORM, pit);
				if(mag > 50) { mag = 50; }
				break;
			case 5: //reload loop
				if(weaponside) { if(mag < 50 && !(PressingLeftFire())) { ChangeState("ReloadP2", myside); break; } }
				else { if(mag < 50 && !(PressingRightFire())) { ChangeState("ReloadP2", myside); break; } }
				break;
				
			default: ddp.A_Log("No action defined for tic "..no); break;
		}
	}
	
	// ## ddPlasmaRifle States()
	States
	{
		NoAmmo:
			PLSG A 10;
		Ready:
			PLSG A 1 A_DDWeaponReady;
			Loop;
		Select:
			PLSG A 1;
			Loop;
		Deselect:
			PLSG A 1;
			Loop;
		Fire:
			PLSG A 1 A_WeapAction;
			PLSG A 2 A_SetTicks;
			PLSG A 0 A_DDFlash;
			PLSG A 1 A_DDTransformation;
			PLSG A 1 A_FireDDWeapon;
			PLSG A 2 A_WeapAction;
			PLSG A 2 A_DDRefire;
			Goto Ready;
		Altfire:
			PLSG A 1 A_WeapAction;
			PLSG A 5;
			PLSG A 0 A_DDFlash;
			PLSG A 3 A_WeapAction;
			PLSG A 6;
			PLSG A 3 A_WeapAction;
			PLSG A 6;
			PLSG A 3 A_WeapAction;
			PLSG A 4;
			PLSG A 3 A_WeapAction;
			PLSG A 4;
		Charging:
			PLSG A 0 A_DDFlash;
			PLSG A 3 A_WeapAction;
			PLSG A 4;
			PLSG A 2 A_DDRefire;
			PLSG A 25 A_FireDDWeapon;
			Goto Ready;
		ReloadP:
			#### # 2 A_DDTransformation;
		ReloadP2:
			#### # 0 A_ChangeSprite;
			#### # 0 A_DDFlash;
			#### # 2;
			#### # 4 A_WeapAction;
			#### # 2;
			#### # 5 A_WeapAction;
			#### # 10;
			Goto Ready;
		Flash:
			PLSF A 1 A_DDTransformation;
			PLSF A 3 Bright A_Light2;
			Goto FlashDone;
		Flash2:
			PLSF B 1 A_DDTransformation;
			PLSF B 3 Bright A_Light2;
			Goto FlashDone;
		Altflash: //initial charge
			PLSF ABAB 4 Bright;
			PLSF ABAB 3 Bright;
			Goto FlashDone;
		Altflash2: //charge loop
			PLSF AB 2 Bright;
			Goto FlashDone;
		FlashRechargeDW:
			PLSR DEF 2 Bright A_Light2;
			PLSR ED 2 Bright A_Light1;
			Goto FlashDone;
		FlashRechargeTH:
			PLSR ABC 2 Bright A_Light2;
			PLSR BA 2 Bright A_Light1;
			Goto FlashDone;
		Spawn:
			PLAS A -1;
			Stop;
		Ind:
			PLGF B 0;
			Stop;
	}
}

extend class ddWeapon
{
	action void A_FireDDPlasma()
	{
		let ddp = ddPlayer(invoker.owner);
		if(ddp.player == null) { return; }
		ddWeapon weap = ddWeapon(self);
		bool pen = (ddp.player.readyweapon is "dualWielding"&&!ddp.CheckESOA(0));
		int kick = (pen) ? 2 : 1;
		if(ddp.CountInv("Cell") > 0)
		{
			ddp.PlayAttacking2 ();
			ddp.SpawnPlayerMissile("PlasmaBall");			
			ddp.TakeInventory("Cell", 1);
			AddRecoil(0.5, 0, 1.0);
			ddp.instability += kick;
			ddp.instTimer = 25;
		}
		else
		{
			ddp.A_StartSound("weapons/nofire", CHAN_WEAPON, CHANF_OVERLAP);			
		}
	}
	
	action void A_FirePlasmaBlast(int charge)
	{
		let ddp = ddPlayer(invoker.owner);
		if(!ddp) { return; }
		ddWeapon weap = ddWeapon(self);
		bool pen = (ddp.player.readyweapon is "dualWielding"&&!ddp.CheckESOA(0));
		int kick = (pen) ? 20 : 10;
		ddp.instability += kick + charge;
		ddp.instTimer = 25;
		Actor mis, mis2;
		[mis, mis2] = ddp.SpawnPlayerMissile("PlasmaBolt", ddp.angle);
		if(mis) { PlasmaBolt(mis).power = charge;  }
		else { PlasmaBolt(mis2).power = charge; }
		AddRecoil(5., 3 * ((charge / 10) + 2), 4.0);
	}
}

//reintroduce once esoa/berserker suit is introduced
class Celle : Cell replaces Cell
{
	Default
	{
		//+INVENTORY.ALWAYSPICKUP;
	}
	/*
	override void DoPickupSpecial(Actor toucher)
	{
		Super.DoPickupSpecial(toucher);
		if(!toucher.player) { return; } 
		if(toucher.FindInventory("ESOA"))
		{
			toucher.A_Log("...and used some to charge your ESOA!");
			toucher.GiveInventory("ESOACharge", 65);
		}
	}
	*/
}

class CellPacke : CellPack replaces CellPack
{
	Default
	{
		//+INVENTORY.ALWAYSPICKUP;
	}
	/*
	override void DoPickupSpecial(Actor toucher)
	{
		Super.DoPickupSpecial(toucher);
		if(!toucher.player) { return; }
		if(toucher.FindInventory("ESOA"))
		{
			toucher.A_Log("...and used some to charge your ESOA!");
			toucher.GiveInventory("ESOACharge", 300);
		}
	}
	*/
}

class PlasmaBolt : Actor
{
	int power; //player charge
	Default
	{
		Projectile;
		Radius 10;
		Height 10;
		ProjectileKickback 0;
		Speed 60;
		Gravity 0.69;
		SeeSound "weapons/pboltlaunch";
		DeathSound "weapons/bfgx";
	}
	
	override void PostBeginPlay()
	{ 
		Super.PostBeginPlay();
		if(power > 14)
		{
			bNoGravity = false;
		}		
	}
	
	action void A_BlowUp()
	{
		int damage = 30 * invoker.power;
		int range = 10 * invoker.power;
		if(invoker.power > 10) { A_SetScale(3.0, 3.0); }
		if(invoker.power > 20) { A_SetScale(2.0, 2.0); range = 200; }
		invoker.A_Explode(damage, range, XF_HURTSOURCE, true);
	}
	
	States
	{
		Spawn:
			PLSE A 1 Bright;
			Loop;
		Death:
			PLSE B 0 A_NoGravity;
			PLSE BC 3 Bright A_JumpIf(power > 14, "DeathBig");
			PLSE D 5 Bright A_BlowUp;
			PLSE E 5 Bright;
			Stop;
		DeathBig:
			BFE2 CD 3 Bright;
			BFE2 CB 3 Bright;
			BFE1 A 4 Bright A_BlowUp;
			BFE1 BC 4 Bright;
			BFE2 BCD 5 Bright;
			Stop;
	}
}

//deprecated
class PlasmaPellet : PlasmaBall
{
	Default
	{
		Radius 7;
		Height 4;
		Scale 0.5;
		Speed 35;
		Damage 2;
		SeeSound "";
	}		
}