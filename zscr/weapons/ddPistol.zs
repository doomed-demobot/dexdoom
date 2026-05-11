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
		ddWeapon.rating 2;
		ddWeapon.SwitchSpeed 3.2;
		ddWeapon.WeaponType "Handgun";
		ddWeapon.initialmag 16;
		ddWeapon.maguse1 1;
		ddWeapon.maguse2 1;
		ddWeapon.reticleScale 0.75;
		Obituary "$OB_MPPISTOL";
		Inventory.Pickupmessage "$PICKUP_PISTOL_DROPPED";
		Tag "$TAG_PISTOL";
	}
	
	
	override void InventoryInfo(ddStats ddhud, bool debug)
	{
		if(debug) { Super.InventoryInfo(ddhud, debug); return; }
		let hud = ddhud;		
		hud.DrawString(hud.fa, GetTag(), (32, 45), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, "level "..hud.FormatNumber(rating).." light handgun", (32, 55), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, hud.FormatNumber(mag).."/"..hud.FormatNumber(default.mag), (32, 65), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
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
		else if (fireMode == 1) { return TexMan.CheckForTexture("ICONBRST"); }
		else { return Super.GetFireModeIcon(); }
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
		//speed up reloading/unloading when berserk
		let myside = (weaponside) ? owner.player.getpsprite(PSP_LEFTW0) : owner.player.getpsprite(PSP_RIGHTW0);
		let myflash = (weaponside) ? owner.player.getpsprite(PSP_LEFTWF0) : owner.player.getpsprite(PSP_RIGHTWF0);
		if(owner.FindInventory("PowerBerserk") && (weaponstatus == DDW_UNLOADING || weaponstatus == DDW_RELOADING)) 
		{ if(myside.tics > 3) { myside.tics--; } if(myflash.tics > 1) { myflash.tics--; } }
	}
	
	override String, int GetSprites(int no)
	{
		let ddp = ddPlayer(owner);
		if(!ddp) { return "TNT1A0", -1; }
		int res = ModeCheck();
		switch(no)
		{
			case 0: //ready
				if(res == RES_TWOHAND) { return "PISD", ((mag < 1) ? 1 : 0); }
				else if(res == RES_DUALWLD || res == RES_HASESOA)  { return ((weaponside) ? "PISG" : "PSTL"), ((mag < 1) ? 1 : 0); }
				else { return "TNT1", -1; }
			case 1: //reload
				if(res == RES_TWOHAND || res == RES_DUALWLD) { return "PSTL", ((mag < 1) ? 1 : 2); }
				else if(res == RES_HASESOA)  { console.printf("esoa functionality has been disabled"); return "TNT1", -1; }
				else { return "TNT1", -1; }	
			case 2:
				if(res == RES_TWOHAND || res == RES_DUALWLD) { return "PISD", 0; }
				else if(res == RES_HASESOA)  { console.printf("esoa functionality has been disabled"); return "TNT1", -1; }
				else { return "TNT1", -1; }
			case 3: //select
				return ((weaponside) ? "PISG" : "PSTL"), ((mag < 1) ? 1 : 0);
			default:
				return "TNT1", -1;
		}
	}
		
	override State wannaReload()
	{
		let ddp = ddPlayer(owner);
		if(weaponstatus == DDW_UNLOADING) { return FindState("UnloadP"); }
		if(ddWeaponFlags & PIS_RSEQ) { weaponstatus = DDW_RELOADING; return FindState("Reload2"); }
		if(mag < default.mag) { weaponstatus = DDW_RELOADING; return FindState("ReloadP"); }
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
		if(ddweaponflags & PIS_RSEQ && (ModeCheck() == RES_TWOHAND)) 
			{ ddPlayer(owner).ddWeaponState &= ~DDW_RIGHTREADY; ddPlayer(owner).ddWeaponState &= ~DDW_RIGHTBOBBING; return FindState("Reload2"); }
		else { return FindState("Ready"); }
	}
	
	override void primaryattack()
	{
		let ddp = ddPlayer(owner);
		mag--;
		A_FireDDPistol();
	}
	
	override void alternativeattack()
	{
		let ddp = ddPlayer(owner);
		mag--;
		A_BurstFireDDPistol();
		burstcounter--;
	}
	
	override void OnRefire()
	{
		burstcounter = 3;
	}

	override void SetDDTransformations(int no, PSpriteInfo pspi)
	{
		let ddp = ddPlayer(owner);
		if(!ddp) { return; }
		int i = (weaponside) ? ddp.leftinstability : ddp.rightinstability;
		switch(no)
		{
			case 1: //pistol fire
				pspi.SetTransformationProperties(6, true, (INTR_TRANS_EXPO | INTR_SCALE_EXPO | INTR_ROTAT_INVEXPO));
				pspi.SetTranslations(0, 12);
				pspi.SetScaling(0, -12);
				//if flash state, copy weapons rotation
				if(pspi.id > 15) { pspi.GetRotation(pspi.id - 10); }
				else { pspi.SetRotation(random2(3)*(1 + (i/100.))); }
				return;
			case 2: //pistol reload 1
				pspi.SetTransformationProperties(4, false, (INTR_TRANS_INVEXPO | INTR_SCALE_INVEXPO));
				pspi.SetTranslations(-4, 16);
				pspi.SetScaling(10, 0);
				//pspi.SetRotation(8);				
				return;
			case 3: //pistol reload 2
				pspi.SetTransformationProperties(8, true, (INTR_TRANS_INVEXPO | INTR_SCALE_INVEXPO | INTR_ROTAT_INVEXPO));
				pspi.SetRotation(-6);
				pspi.SetScaling(-10,0);
				pspi.SetTranslations(4, -8);
				return;
			case 4: //reload hand up
				pspi.SetTransformationProperties((owner.FindInventory("PowerBerserk")) ? 2 : 3, false);
				pspi.SetTranslations(0,-20);
				return;
			case 5: //pistol slide forward
				pspi.SetTransformationProperties(3, true);
				pspi.SetTranslations(-4, 8);
				pspi.SetScaling(0, -12);
			case 6: //pistol 3
				pspi.SetTransformationProperties(2, true, (INTR_TRANS_EXPO));
				pspi.SetTranslations(0, -4);
				return;
			case 7: //pistol burst fire
				if(burstcounter > 1) 
				{ 
					pspi.SetTransformationProperties(2, false);
					pspi.SetTranslations(0, 6);
					pspi.SetScaling(0, 10);
				}
				else 
				{
					pspi.SetTransformationProperties(3, true, (INTR_TRANS_INVEXPO | INTR_SCALE_INVEXPO));
					pspi.SetTranslations(0, 8);
					pspi.SetScaling(0, -20);
					//if flash state, copy weapons rotation
					if(pspi.id > 15) { pspi.GetRotation(pspi.id - 10); }
					else { pspi.SetRotation(random2(3)*(1 + (i/100.))); }
				} 
				return;
			case 8: //unload pistol 1
				pspi.SetTransformationProperties(5, false, (INTR_TRANS_EXPO | INTR_ROTAT_INVEXPO), nextcase: 9);
				pspi.SetTranslations(0, 30);
				pspi.SetRotation(6);
				return;
			case 9: //unload pistol 2
				pspi.SetTransformationProperties(3, false, (INTR_TRANS_INVEXPO), nextcase: 10);
				pspi.SetTranslations(0, -16);
				pspi.SetRotation(-6);
				return;
			case 10: //unload pistol 3
				pspi.SetTransformationProperties(5, false, (INTR_TRANS_INVEXPO));
				pspi.SetTranslations(0, 12);
				pspi.SetRotation(8);
				return;
			case 11: //unload mag out
				pspi.SetTransformationProperties(4, false);
				pspi.SetTranslations(-28, 60);
				return;
			case 12: //hand slide back up
				pspi.SetTransformationProperties(5, false, (INTR_TRANS_INVEXPO), nextcase: 13);
				pspi.SetTranslations(50, -80);
				pspi.SetRotation(-8);
				return;
			case 13: //hand slide back down
				pspi.SetTransformationProperties(3, false, (INTR_TRANS_EXPO));
				pspi.SetTranslations(0, 64);
				return;
			case 14: //unload pistol 4
				pspi.SetTransformationProperties(5, false, (INTR_TRANS_INVEXPO));
				pspi.SetTranslations(0, 24);
				pspi.SetRotation(8);
				return;
			case 15:
				pspi.SetTransformationProperties(4, false, (INTR_SCALE_INVEXPO), nextcase: 16);
				pspi.SetScaling(-8, 15);
				return;
			case 16:
				pspi.SetTransformationProperties(2, false, (INTR_SCALE_INVEXPO));
				pspi.SetScaling(8, -15);
				return;
			default:
				return;			
		}
		return;
	}

	override void DD_WeapAction(int no)
	{		
		let ddp = ddPlayer(owner);
		let me = ddWeapon(self);
		let type = (!bAltFire) ? AmmoType1 : AmmoType2;
		let pspl = ddp.player.GetPSprite(PSP_LEFTW0);
		let psplf = ddp.player.GetPSprite(PSP_LEFTWF0);
		let pspr = ddp.player.GetPSprite(PSP_RIGHTW0);
		let psprf = ddp.player.GetPSprite(PSP_RIGHTWF0);
		let pspi = ddp.GetPSpriteInfo(PSP_RIGHTW0, ddp);
		int myside = (weaponside) ? PSP_LEFTW0 : PSP_RIGHTW0;
		int flashside = (weaponside) ? PSP_LEFTWF0 : PSP_RIGHTWF0;
		let res = ModeCheck();
		switch(no)
		{
			case 1: //init/ammo check
				if(mag < 1 && (ddp.CountInv(type) < 1)) {					
					if(ddp.dddebug & DBG_WEAPSEQUENCE) { ddp.A_Log("No ammo for Pistol fire"); } 
					ChangeState("NoAmmo", myside);
					break;
				}
				if((res == RES_TWOHAND || res == RES_HASESOA)) { if(mag < 1 || ddWeaponFlags & PIS_RSEQ) { weaponstatus = DDW_RELOADING; ChangeState("ReloadP", myside); break; } }
				if(res == RES_DUALWLD) { if(mag < 1 || ddWeaponFlags & PIS_RSEQ) { LowerToReloadWeapon(); break; } }				
				ddp.PlayAttacking();
				break;
			case 2: //primary
				//ddWeaponOffset(myside, 0, 0, WOF_KEEPX);
				if((res == RES_TWOHAND || res == RES_HASESOA) && ddp.CountInv(type) > 1 && mag < 1) { weaponstatus = DDW_RELOADING; ChangeState("ReloadP", myside); }				
				break;
			case 3: //alt burstcounter check
				if((res == RES_TWOHAND || res == RES_HASESOA) && ddp.CountInv(type) > 1 && mag < 1) { weaponstatus = DDW_RELOADING; self.burstcounter = 3; ChangeState("ReloadP", myside); break; }
				if(self.burstcounter < 1 || mag < 1) { self.burstcounter = 3; }
				else { ChangeState("Burst", myside); }
				break;
			case 4: //reload ")
				me.ddweaponflags |= PIS_RSEQ;
				break;
			case 5:
				me.ddweaponflags &= ~PIS_RSEQ;
				ReloadWeaponMag(((mag > 0) ? 16 : 15), 1); 
				break;
			case 6:
				UnloadWeaponMag();
				break;
			case 7:				
				SetSubSprite(pspi, 0, 38, 0, "HandReload");
				break;
			case 8: //unload hand 1
				SetSubSprite(pspi, 2, 24, 0, "HandUnload");
				break;
			case 9: //unload hand 2
				SetSubSprite(pspi, -34, 65, ((weaponside) ? 19 : 24), "HandSlideBack");
				break;
			default: ddp.A_Log("No action defined for tic "..no); break;
		}
	}
	
	override State GetWeapState(int no)
	{
		switch(no)
		{
			case 1: //skip slide release
				if(mag >= 1) { return FindState("Reload3"); } else { return FindState("DoNotJump"); }
			case 2: //skip mag out
				if(mag <= 1) 
				{ 
					A_DDTransformation(14);
					A_WeapAction(9);
					return FindState("SlideBack"); 
				} 
				else { return FindState("DoNotJump"); }
			default: return Super.GetWeapState(no);
		}
	}
	
	override int GetTicks(int no)
	{
		if(!owner) { return 0; }
		switch(no)
		{
			case 1:
				return (owner.FindInventory("PowerBerserk")) ? 6 : 8;
			case 2:
				return (owner.FindInventory("PowerBerserk")) ? 6 : 11;
			default: return 0;
		}
	}
	
	action void A_FireDDPistol()
	{
		bool accurate;
		int dam = 4 * random(2,3);
		let ddp = ddPlayer(invoker.owner);
		ddWeapon weap = ddWeapon(self);
		Class<Ammo> type = weap.AmmoType1;
		if(ddp.player == null) { return; }	
		double eA = 0;
		double eP = 0;
		accurate = !ddp.player.refire;
		bool pen = (ddp.player.readyweapon is "dualWielding"&&!ddp.CheckESOA(0));
		bool bz = (ddp.FindInventory("PowerBerserk"));
		if(pen) { eA = (Random2() * (1.99 / 256)); eP = (Random2() * (1.67 / 256)); } 
		else { eA = Random2() * (0.99 / 256); eP = Random2() * (0.99 / 256); }
		ddp.A_StartSound("weapons/pistolnew", CHAN_WEAPON, CHANF_OVERLAP);
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
		Class<Ammo> type = weap.AmmoType1;
		if(ddp.player == null) { return; }
		bool pen = (ddp.player.readyweapon is "dualWielding"&&!ddp.CheckESOA(0));
		if(ddp.dddebug & DBG_WEAPONS) { A_Log(""..weap.GetClassName().." dualwielding penalties "..((pen) ? "active" : "inactive")); }
		double eA = 0;
		double eP = 0;
		bool bz = (ddp.FindInventory("PowerBerserk"));
		if(pen) { eA = (Random2() * (3.67 / 256)); eP = (Random2() * (4.25 / 256)); } 
		else { eA = Random2() * (1.67 / 256); eP = Random2() * (2.25 / 256); }
		ddp.A_StartSound("weapons/pistolnew", CHAN_WEAPON, CHANF_OVERLAP);
		if(invoker.mag < 4) { ddp.A_StartSound("weapons/nofire", CHAN_WEAPON, CHANF_OVERLAP); }
		ddShot(false, "BulletPuff", dam, eA, eP,weap.weaponside, 5);
		if(pen) { AddRecoil(7.5, 4, 3.5); }
		else { AddRecoil(3, 1, 3.5); }
	}
	
	// ## ddPistol States()
	States
	{
		NoAmmo:
			#### # 10;
		Ready:
			PISD A 0 A_ChangeSprite;
			#### # 1 A_DDWeaponReady;
			Loop;
		Fire:
			#### # 1 A_WeapAction;
			#### A 1;
			#### A 1 A_DDTransformation;
			#### A 0 A_DDFlash;
			#### C 1 A_FireDDWeapon;
			#### B 2;
			#### B 0 A_ChangeSprite;
			#### C 2 A_WeapAction;
			#### # 0 A_ChangeSprite;
			#### ######## 1 A_DDHeavyRefire;
			#### # 1;
			Goto Ready;
		Select:
			PISD A 3 A_ChangeSprite;
			#### # 1;
			Loop;
		Deselect:
			PISD A 1;
			Loop;
		AltFire:
			#### A 1 A_WeapAction;
			#### A 4;
		Burst:
			#### B 7 A_DDTransformation;
			#### B 0 A_DDFlash;
			#### B 1 A_FireDDWeapon;
			#### C 1;
			#### # 0 A_ChangeSprite;
			#### # 3 A_WeapAction;
			#### # 1;
			#### # 3;
			#### # 5 A_DDRefire;
			Goto Ready;
		ReloadP:
			#### # 1 A_ChangeSprite;
			#### # 2 A_DDTransformation;
			#### # 3;
			#### # 2 A_PistolReload1;
			#### # 2;
			#### # 3 A_DDTransformation;
			#### # 4 A_WeapAction;
		Reload2:
			#### # 1 A_ChangeSprite;
			#### # 7 A_WeapAction;
			#### # 4;
			#### # 4;
			#### # 6 A_DDTransformation;
			#### # 12 A_PistolReload2;
			#### # 1 A_SetWeapState;
			PISD A 5 A_DDTransformation;
			PISD A 10 A_PistolReload3;
		Reload3:
			#### A 0 A_ChangeSprite;
			#### A 5 A_WeapAction;
			#### A 1;
			//#### A 2;
			Goto Ready;		
		UnloadP:
			#### # 2 A_ChangeSprite;
			#### # 2 A_SetWeapState;
			#### # 8 A_DDTransformation;
			#### # 6 A_PistolReload1;
			#### # 8 A_WeapAction;
		SlideBack:
			#### # 9 A_WeapAction;
			#### # 1 A_ChangeSprite;
			#### # 9;
			#### # 15 A_DDTransformation;
			#### B 2 A_PistolReload3;
			#### # 6 A_WeapAction;
			#### # 10;
			Goto Ready;
		HandReload:
			TNT1 A 1 A_SetTicks;
			PIMH A 4 A_DDTransformation;
			#### # 1;
			#### # 2 A_SetTicks;
			Stop;
		HandUnload:
			PIMH A 11 A_DDTransformation;
			PIMH A 4;
			TNT1 A -1;
			Stop;
		HandSlideBack:
			PIMH A 4;
			HNDA A 12 A_DDTransformation;
			HNDA A 12;
			TNT1 A -1;
			Stop;
		FlashP:
			PISF # 1 Bright A_DDTransformation;
			PISF # 1 Bright A_Light2;
			Goto FlashDone;
		FlashA:
			PISF # 7 Bright A_DDTransformation;
			PISF # 1 Bright A_Light2;
			Goto FlashDone;
		Spawn:
			PIST A -1;
			Stop;
		Ind:
			PISD A 1;
			PIFD A 1;
			PISL A 1;
			PISG A 1;
			PISE A 1;
			PSTL A 1;
			Stop;			
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
		return Super.ChooseSpawn();
	}
}

extend class ddWeapon
{	
	action void A_PistolReload1() { A_StartSound("weapons/shotgp1", CHAN_WEAPON, CHANF_OVERLAP); }
	action void A_PistolReload2() { A_StartSound("weapons/shotgp2", CHAN_WEAPON, CHANF_OVERLAP); }
	action void A_PistolReload3() { A_StartSound("weapons/shotgp2", CHAN_WEAPON, CHANF_OVERLAP, 1.0, ATTN_NORM, 1.5); }
}