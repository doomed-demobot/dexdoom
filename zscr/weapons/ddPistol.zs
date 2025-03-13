// #Class ddPistol : ddWeapon replaces Pistol()
//Doom Pistol. Fires as fast as you can pull the trigger. Altfire is a 3-round burst.
enum pistolFlags
{
	PIS_RSEQ = 2,
};


class ddPistol : ddWeapon replaces Pistol
{
	int burstcounter;
	Default
	{
		Weapon.SelectionOrder 1900;
		Weapon.AmmoUse 1;
		Weapon.AmmoUse2 1;
		Weapon.AmmoGive 15;
		Weapon.AmmoType "d9Mil";
		Weapon.AmmoType2 "d9Mil";
		ddWeapon.ClassicAmmoType1 "Clip";
		ddWeapon.ClassicAmmoType2 "Clip";
		ddWeapon.rating 2;
		ddWeapon.SwitchSpeed 3.2;
		ddWeapon.WeaponType "Handgun";
		ddWeapon.initialmag 16;
		ddWeapon.maguse1 1;
		ddWeapon.maguse2 1;
		Obituary "$OB_MPPISTOL";
		Inventory.Pickupmessage "$PICKUP_PISTOL_DROPPED";
		Tag "$TAG_PISTOL";
	}
	
	override void InventoryInfo(ddStats ddhud)
	{
		let hud = ddhud;		
		hud.DrawString(hud.fa, GetTag(), (30, 45), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, "level "..hud.FormatNumber(rating).." light handgun", (30, 55), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, hud.FormatNumber(mag).."/"..hud.FormatNumber(default.mag), (30, 65), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
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
	
	override void PreviewInfo(ddStats ddhud)
	{
		let hude = ddhud;
		hude.DrawString(hude.fa, GetTag(), (12, 45), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
		hude.DrawString(hude.fa, hude.FormatNumber(mag).."/"..hude.FormatNumber(default.mag), (12, 52), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
		hude.DrawString(hude.fa, "Spare ammo: "..hude.FormatNumber(AmmoGive1), (12, 59), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
	}
	
	override void PostBeginPlay()
	{
		self.burstcounter = 3;
	}	
	
	override void Tick()
	{
		Super.Tick();
		if(weaponReady) { self.burstcounter = 3; }
	}
	
	override void OnAutoReload()
	{
		ddWeaponFlags &= ~PIS_RSEQ;
	}
	
	override void WhileBerserk()
	{
		if(owner is "ddPlayerNormal")
		{
			//speed up reloading/unloading when berserk
			let myside = (weaponside) ? owner.player.getpsprite(PSP_LEFTW) : owner.player.getpsprite(PSP_RIGHTW);
			let myflash = (weaponside) ? owner.player.getpsprite(PSP_LEFTWF) : owner.player.getpsprite(PSP_RIGHTWF);
			if(owner.FindInventory("PowerBerserk") && (weaponstatus == DDW_UNLOADING || weaponstatus == DDW_RELOADING)) 
			{ if(myside.tics > 3) { myside.tics--; } if(myflash.tics > 1) { myflash.tics--; } }
		}
	}
	
	override String, int GetSprites(int forcemode)
	{
		let ddp = ddPlayer(owner);
		if(forcemode < 0)
		{
			if(ddp.player.readyweapon is "dualWielding" || ddp.player.pendingweapon is "dualWielding" || ddp.lastmode is "dualWielding") {
				String sp = (weaponside) ? "PISLA0" : "PIFDA0";
				int fr = ((ddweaponflags & PIS_RSEQ) ? 10 : 0);
				fr = ((mag < 1) ? 1 : fr);
				return sp, fr; 
			}
			else if(ddp.player.readyweapon is "twoHanding" || ddp.player.pendingweapon is "twoHanding" || ddp.lastmode is "twoHanding")  
			{
				int fr = ((ddweaponflags & PIS_RSEQ ? 5 : 0));
				fr = ((mag < 1) ? 5 : fr);
				return "PISDA0", fr; 
			}
			else { 
				return "TNT1A0"; }
		}
		else if(forcemode == 2) { return "PISLA0", ((ddweaponflags & PIS_RSEQ) ? 10 : 0); }
		else if(forcemode == 1) { return "PISDA0", -1; }
		else { return "TNT1A0", -1; }
	}
		
	override State wannaReload()
	{
		let ddp = ddPlayer(owner);
		if(weaponstatus == DDW_UNLOADING) { SetCaseNumber(4); return FindState("UnloadP"); }
		if(ddWeaponFlags & PIS_RSEQ) { weaponstatus = DDW_RELOADING; SetCaseNumber(3); return FindState("Reload2"); }
		if(mag < default.mag) { weaponstatus = DDW_RELOADING; SetCaseNumber(5); return FindState("ReloadP"); }
		else { return FindState("DoNotJump"); }
	}
	override String GetWeaponSprite()
	{
		return "PISTA0";
	}
	
	override String getParentType()
	{
		return "ddPistol";
	}
	
	override State GetReadyState()
	{
		if(ddweaponflags & PIS_RSEQ && (ModeCheck(4) == (RES_TWOHAND || RES_HASESOA))) 
			{ ddPlayer(owner).ddWeaponState &= ~DDW_RIGHTREADY; ddPlayer(owner).ddWeaponState |= DDW_RIGHTNOBOBBING; SetCaseNumber(3); return FindState("Reload2"); }
		else { return FindState("Ready"); }
	}
	
	override State GetAttackState()
	{
		let ddp = ddPlayer(owner);
		if(ddp.FindInventory("ClassicModeToken")) { return FindState("FireClassic"); }
		else { return Super.GetAttackState(); }
	}
	
	override State GetRefireState()
	{
		let ddp = ddPlayer(owner);
		if(ddp.FindInventory("ClassicModeToken")) { return FindState("FireClassic"); }
		else { return Super.GetAttackState(); }
	}
	
	override State GetFlashState()
	{
		let ddp = ddPlayer(owner);
		if(ddp.FindInventory("ClassicModeToken")) { return FindState("FlashC"); }
		if(ddp.player.readyweapon is "dualWielding" || ddp.player.pendingweapon is "dualWielding" || ddp.lastmode is "dualWielding") {
			ddp.player.GetPSprite(PSP_RIGHTWF).Frame = 2;
		}
		return Super.GetFlashState();
	}
	
	override void primaryattack()
	{
		let ddp = ddPlayer(owner);		
		Class<Ammo> type = (ddp.FindInventory("ClassicModeToken")) ? ClassicAmmoType1 : AmmoType1;
		if(ddp.FindInventory("ClassicModeToken")) { ddp.TakeInventory("Clip", 1); }
		else { mag--; }
		A_FireDDPistol();
	}
	
	override void alternativeattack()
	{
		let ddp = ddPlayer(owner);
		Class<Ammo> type = (ddp.FindInventory("ClassicModeToken")) ? ClassicAmmoType1 : AmmoType1;
		if(ddp.FindInventory("ClassicModeToken")) { if(ddp.CountInv(type) > 0) { ddp.TakeInventory(type, 1); } }
		else { mag--; }
		A_BurstFireDDPistol();
		burstcounter--;
	}
	
	override void OnRefire()
	{
		burstcounter = 3;
	}
	
	override void DD_Condition(int cn)
	{
		int caseno = cn;
		let ddp = ddPlayer(owner);
		let me = ddWeapon(self);
		let type = (ddp.FindInventory("ClassicModeToken")) ?
		((!bAltFire) ? ClassicAmmoType1 : ClassicAmmoType2) :
		((!bAltFire) ? AmmoType1 : AmmoType2);
		let pspl = ddp.player.GetPSprite(PSP_LEFTW);
		let psplf = ddp.player.GetPSprite(PSP_LEFTWF);
		let pspr = ddp.player.GetPSprite(PSP_RIGHTW);
		let psprf = ddp.player.GetPSprite(PSP_RIGHTWF);
		int myside = (weaponside) ? PSP_LEFTW : PSP_RIGHTW; 
		int flashside = (weaponside) ? PSP_LEFTWF : PSP_RIGHTWF;
		let res = ModeCheck();
		switch(caseno)
		{
			case 0: //init/ammo check
				if(res == RES_CLASSIC && (ddp.CountInv(type) < 1)) {					
					if(ddp.dddebug & DBG_WEAPSEQUENCE) { ddp.A_Log("No ammo for Pistol fire"); } 
					ChangeState("NoAmmo", myside);
					break;
				}
				if(mag < 1 && (ddp.CountInv(type) < 1)) {					
					if(ddp.dddebug & DBG_WEAPSEQUENCE) { ddp.A_Log("No ammo for Pistol fire"); } 
					ChangeState("NoAmmo", myside);
					break;
				}
				if((res == RES_TWOHAND || res == RES_HASESOA)) { if(mag < 1 || ddWeaponFlags & PIS_RSEQ) { weaponstatus = DDW_RELOADING; SetCaseNumber(5); ChangeState("ReloadP", myside); break; } }
				if(res == RES_DUALWLD) { if(mag < 1 || ddWeaponFlags & PIS_RSEQ) { SetCaseNumber(5); LowerToReloadWeapon(); break; } }				
				ddp.PlayAttacking(); 
				SetCaseNumber(((bAltFire) ? 2 : 1));
				break;
			case 1: //primary
				SetCaseNumber(0);
				if((res == RES_TWOHAND || res == RES_HASESOA) && ddp.CountInv(type) > 1 && mag < 1) { weaponstatus = DDW_RELOADING; SetCaseNumber(5); ChangeState("ReloadP", myside); }				
				break;
			case 2: //alt burstcounter check
				if((res == RES_TWOHAND || res == RES_HASESOA) && ddp.CountInv(type) > 1 && mag < 1) { weaponstatus = DDW_RELOADING; self.burstcounter = 3; SetCaseNumber(3); ChangeState("ReloadP", myside); break; }
				if(self.burstcounter < 1 || mag < 1) { self.burstcounter = 3; SetCaseNumber(0); }
				else { ChangeState("Burst", myside); SetCaseNumber(2); }
				break;
			case 3: //reload ")
				me.ddweaponflags &= ~PIS_RSEQ;
				ReloadWeaponMag(((mag > 0) ? 16 : 15), 1); 
				SetCaseNumber(0);
				break;
			case 4:
				UnloadWeaponMag();
				SetCaseNumber(0);
				break;
			case 5:
				me.ddweaponflags |= PIS_RSEQ;
				SetCaseNumber(3);
				break;
			default: break;
		}
	}
	
	// ## ddPistol States()
	States
	{
		NoAmmo:
			PISG A 10;
		Ready:
			PISG A 1;
			Loop;
		Deselect:
			PISG A 1;
			Loop;
		Select:
			PISG A 1;
			Loop;
		Fire:
			Goto Ready;
		AltFire:
			Goto Ready;
		ReloadP:
			Goto Ready;
		FlashP:
			PISF A 2 Bright A_Light1;
			Goto FlashDone;
		FlashA:
			PISF A 1 Bright A_Light1;
			Goto FlashDone;
		FlashC:
			PISF A 6 Bright A_Light1;
			Goto FlashDone;
		Spawn:
			PIST A -1;
			Stop;
		Ind:
			PISD A 0;
			PIFD A 0;
			PISL A 0;
			Stop;
	}
}
// #Class ddPistolLeft : ddPistol()
class ddPistolLeft : ddPistol
{
	Default { ddweapon.weaponside CE_LEFT; -DDWEAPON.GOESININV; }
	States
	{
		NoAmmo:
			#### # 10 A_ChangeSpriteLeft;
		Ready:
			PISD A 0 A_ChangeSpriteLeft;
			#### # 1 A_LeftWeaponReady;
			Loop;
		Fire:
			#### A 0 A_DDActionLeft;
			#### A 1;
			#### B 0 A_FlashLeft;
			#### B 2 A_FireLeftWeapon;
			#### C 0 A_DDActionLeft;
			#### # 1 A_ChangeSpriteLeft;
			#### ######## 1 A_ddRefireLeftHeavy;
			#### # 1;
			Goto Ready;
		FireClassic:
			#### A 0 A_DDActionLeft;
			#### A 4;
			#### B 0 A_FlashLeft;
			#### B 6 A_FireLeftWeapon;
			#### C 4;
			#### B 5 A_ddRefireLeft;
			Goto Ready;	
		Select:
			PISD A 1 A_ChangeSpriteLeft;
			Loop;	
		AltFire:
			#### A 0 A_DDActionLeft;
			#### A 4;
		Burst:
			#### B 0 A_FlashLeft;
			#### B 1 A_FireLeftWeapon;
			#### C 0;
			#### # 1 A_ChangeSpriteLeft;
			#### # 1 A_DDActionLeft;
			#### # 3;
			#### # 5 A_ddRefireLeft;
			Goto Ready;
		ReloadP:
			#### F 3;
			#### G 3 A_PistolReload1;
			#### G 0 A_DDActionLeft;
		Reload2:
			#### G 5 A_PistolReload2;
			#### H 10 A_PistolReload3;
			#### H 1 A_ddActionLeft;
			#### IJ 4;
			Goto Ready;
		UnloadP:
			#### F 5 A_PistolReload2;
			#### G 5;
			#### H 4 A_PistolReload3;
			#### I 4 A_DDActionLeft;
			#### J 4;
			Goto Ready;
		FlashP:
			PISF B 2 Bright A_Light2;
			Goto FlashDone;
		FlashA:
			PISF B 1 Bright A_Light2;
			Goto FlashDone;
	}
}
// #Class ddPistolRight : ddPistol()
class ddPistolRight : ddPistol
{
	Default { ddweapon.weaponside CE_RIGHT; -DDWEAPON.GOESININV; }
	States
	{
		NoAmmo:
			#### # 10 A_ChangeSpriteRight;
		Ready:
			PISD A 0 A_ChangeSpriteRight;
			#### # 1 A_RightWeaponReady;
			Loop;
		Select:
			PISD A 1 A_ChangeSpriteRight;
			Loop;	
		Fire:
			#### A 0 A_DDActionRight;
			#### A 1;
			#### B 0 A_FlashRight;
			#### B 2 A_FireRightWeapon;
			#### C 0 A_DDActionRight;
			#### # 1 A_ChangeSpriteRight;
			#### ######## 1 A_ddRefireRightHeavy;
			#### # 1;
			Goto Ready;
		FireClassic:
			#### A 0 A_DDActionRight;
			#### A 4;
			#### B 0 A_FlashRight;
			#### B 6 A_FireRightWeapon;
			#### C 4;
			#### B 5 A_ddRefireRight;
			Goto Ready;				
		AltFire:
			#### A 0 A_DDActionRight;
			#### A 4;
		Burst:
			#### B 0 A_FlashRight;
			#### B 1 A_FireRightWeapon;
			#### C 0;
			#### # 1 A_ChangeSpriteRight;
			#### # 1 A_DDActionRight;
			#### # 3;
			#### # 5 A_ddRefireRight;
			Goto Ready;
		ReloadP:
			#### F 3;
			#### G 3 A_PistolReload1;
			#### G 0 A_DDActionRight;
		Reload2:
			#### G 5 A_PistolReload2;
			#### H 10 A_PistolReload3;
			#### H 1 A_ddActionRight;
			#### IJ 4;
			Goto Ready;
		UnloadP:
			#### F 5 A_PistolReload2;
			#### G 5;
			#### H 4 A_PistolReload3;
			#### I 4 A_DDActionRight;
			#### J 4;
			Goto Ready;
		FlashP:
			PISF # 2 Bright A_Light2;
			Goto FlashDone;
		FlashA:
			PISF # 1 Bright A_Light2;
			Goto FlashDone;
			
			
	}
}
// #Class d9mil : Ammo()
class d9Mil : Ammo
{
	Default
	{
		Inventory.PickupMessage "Picked up a pistol mag.";
		Inventory.Amount 15;
		Inventory.MaxAmount 300;
		Ammo.BackpackAmount 45;
		Ammo.BackpackMaxAmount 500;
		Inventory.Icon "PCLPA0";
		Tag "$AMMO_CLIP";	
	}
	States
	{
		Spawn:
			PCLP A -1;
			Stop;
	}
}

// #Class d9MSpawner : RandomSpawner()
class d9MSpawner : RandomSpawner
{
	Default
	{
		DropItem "d9Mil", 255, 60;
		DropItem "Clip", 255, 0;
	}
	
	override Name ChooseSpawn()
	{
		for(int x = 0; x < 8; x++)
		{
			if(players[x].mo is "ddPlayerClassic")
			{
				return "Clip";
			}
		}
		return Super.ChooseSpawn();
	}
}

extend class ddWeapon
{
	action void A_FireDDPistol()
	{
		bool accurate;
		int dam = 4 * random(2,3);
		let ddp = ddPlayer(invoker.owner);
		ddWeapon weap = ddWeapon(self);
		Class<Ammo> type = (ddp.FindInventory("ClassicModeToken")) ? weap.ClassicAmmoType1 : weap.AmmoType1;
		if(ddp.player == null) { return; }	
		double eA = 0;
		double eP = 0;
		accurate = !ddp.player.refire;
		bool pen = (ddp.player.readyweapon is "dualWielding"&&!ddp.CheckESOA(0));
		bool bz = (ddp.FindInventory("PowerBerserk"));
		if(pen) { eA = (Random2() * (1.99 / 256)); eP = (Random2() * (1.67 / 256)); } 
		else { eA = Random2() * (0.99 / 256); eP = Random2() * (0.99 / 256); }
		if(ddp.FindInventory("ClassicModeToken")) { ddp.A_StartSound("weapons/pistol", CHAN_WEAPON, CHANF_OVERLAP); }
		else { ddp.A_StartSound("weapons/pistolnew", CHAN_WEAPON, CHANF_OVERLAP); }
		if(invoker.mag < 4) { ddp.A_StartSound("weapons/nofire", CHAN_WEAPON, CHANF_OVERLAP); }
		ddShot(accurate, "BulletPuff", dam, eA, eP, weap.weaponside, (pen) ? 10 : 3);
		if(pen) { AddRecoil(1.8, 1, 4.); }
		else { AddRecoil(1.5, 0, 4.); }
	}
	action void A_BurstFireDDPistol() 
	{
		bool accurate;
		int dam = 5 * random(2,3);		
		let ddp = ddPlayer(invoker.owner);
		ddWeapon weap = ddWeapon(self);
		Class<Ammo> type = (ddp.FindInventory("ClassicModeToken")) ? weap.ClassicAmmoType1 : weap.AmmoType1;
		if(ddp.player == null) { return; }
		bool pen = (ddp.player.readyweapon is "dualWielding"&&!ddp.CheckESOA(0));
		if(ddp.dddebug & DBG_WEAPONS) { A_Log(""..weap.GetClassName().." dualwielding penalties "..((pen) ? "active" : "inactive")); }
		double eA = 0;
		double eP = 0;
		bool bz = (ddp.FindInventory("PowerBerserk"));
		if(pen) { eA = (Random2() * (3.67 / 256)); eP = (Random2() * (4.25 / 256)); } 
		else { eA = Random2() * (1.67 / 256); eP = Random2() * (2.25 / 256); }
		if(ddp.FindInventory("ClassicModeToken")) { ddp.A_StartSound("weapons/pistol", CHAN_WEAPON, CHANF_OVERLAP); }
		else { ddp.A_StartSound("weapons/pistolnew", CHAN_WEAPON, CHANF_OVERLAP); }
		if(invoker.mag < 4) { ddp.A_StartSound("weapons/nofire", CHAN_WEAPON, CHANF_OVERLAP); }
		ddShot(false, "BulletPuff", dam, eA, eP,weap.weaponside, 5);
		if(pen) { AddRecoil(7.5, 4, 3.5); }
		else { AddRecoil(3, 1, 3.5); }
	}
	
	action void A_PistolReload1() { A_StartSound("weapons/preload1", CHAN_WEAPON, CHANF_OVERLAP); }
	action void A_PistolReload2() { A_StartSound("weapons/preload2", CHAN_WEAPON, CHANF_OVERLAP); }
	action void A_PistolReload3() { A_StartSound("weapons/preload3", CHAN_WEAPON, CHANF_OVERLAP); }
	
}