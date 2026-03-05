// #Class ddChaingun : ddWeapon replaces Chaingun()
//Doom Chaingun. Firerate increases while firing like Doom 2016 Chaingun. Altfire revs barrel without
//using ammo.
enum ddChaingunFlags{
	CHG_ALTFR1 = 0,
	CHG_ALTFR2 = 1,
};

class ddChaingun : ddWeapon replaces Chaingun
{
	bool safeflasher; //true if flash 2, false if flash 1;
	bool chainFrame; //false for A, true for B
	int spin, spintimer;
	Default
	{
		Weapon.SelectionOrder 700;
		Weapon.AmmoUse 1;
		Weapon.AmmoGive 20;
		Weapon.AmmoType "Clip";
		Weapon.AmmoType2 "Clip";
		ddWeapon.ClassicAmmoType1 "Clip";
		ddWeapon.ClassicAmmoType2 "Clip";
		ddWeapon.rating 5;	
		ddWeapon.SwitchSpeed 1.3;
		ddWeapon.WeaponType "LMG";
		Inventory.PickupMessage "$GOTCHAINGUN";
		Obituary "$OB_MPCHAINGUN";
		Tag "$TAG_CHAINGUN";
		+DDWEAPON.BOBWHENREADY;
	}
	
	override void PostBeginPlay()
	{
		safeflasher = false;
		chainFrame = false;
		spin = 0;
		spintimer = 0;
	}
	
	override void OnInit()
	{
		spin = 0;
		spintimer = 0;
	}
	
	override void Tick()
	{
		Super.Tick();		
		if(owner) {
			if(--spintimer < 0) { spintimer = 0; }
			if(!spintimer) { if(spin > 0) { spin -= 1; spintimer += 35; } if(spin < 0) { spin = 0; } }
		}
	}
		
	override void InventoryInfo(ddStats ddhud, bool debug)
	{
		if(debug) { Super.InventoryInfo(ddhud, debug); return; }
		let hud = ddhud;		
		hud.DrawString(hud.fa, GetTag(), (30, 45), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, "level "..hud.FormatNumber(rating).." lmg", (30, 55), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, "NO MAG", (30, 65), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
	}
	
	override void PreviewInfo(ddStats ddhud)
	{
		let hude = ddhud;
		hude.DrawString(hude.fa, GetTag(), (12, 45), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
		hude.DrawString(hude.fa, "Spare ammo: "..hude.FormatNumber(AmmoGive1), (12, 52), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
	}
	
	override TextureID GetFireModeIcon()
	{
		if(fireMode == 0) { return TexMan.CheckForTexture("ICONDOUB"); }
		else if (fireMode == 1) { return TexMan.CheckForTexture("ICONSPIN"); }
		else { return Super.GetFireModeIcon(); }
	}
	
	override String, int GetSprites(int no)
	{
		let ddp = ddPlayer(owner);
		if(!ddp) { return "TNT1", -1; }
		switch(no)
		{
			case 0:
				if(spin > 0)
				{
					int mod;
					if(spin > 6) { mod = 2; }
					else if(spin > 5) { mod = 3; }
					else if(spin > 4) { mod = 4; }
					else if(spin > 3) { mod = 5; }
					else if(spin > 2) { mod = 6; }
					else if(spin > 1) { mod = 7; }
					else { mod = 8; } 
					
					if(level.mapTime % mod == 0) { console.printf(""..mod); ddp.A_StartSound("weapons/chaingunspin", CHAN_WEAPON, CHANF_OVERLAP, 1., ATTN_NORM, ((spin < 5) ? 1. : 1.2)); chainFrame = !chainFrame; }
					if(!chainFrame) { return "CHGG", 0; }
					else { return "CHGG", 1; }
				}
				else { 
					return "CHGGA0", 0;
				}				
			default:
				return "TNT1", -1;
		}
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
		else { return Super.GetRefireState(); }	
	}
	
	override String GetWeaponSprite()
	{
		return "MGUNA0";
	}
	
	override State GetFlashState()
	{
		let ddp = ddPlayer(owner);
		ddWeapon mode = ddWeapon(ddp.player.readyweapon);
		if(!safeflasher) { safeflasher = !safeflasher; if(owner.CountInv(AmmoType1.GetClassName()) >= AmmoUse1) { return FindState('Flash'); } else { return FindState('NoFlash'); } }
		else { safeflasher = !safeflasher; if(owner.CountInv(AmmoType1.GetClassName()) >= AmmoUse1) { return FindState('Flash2'); } else { return FindState('NoFlash'); } } 
	}
	
	override String getParentType()
	{
		return "ddChaingun";
	}
	
	override void primaryattack()
	{
		let ddp = ddPlayer(owner);
		A_FireDDCGun();
		spin += 1;
		spintimer = 35;
		if(spin > 7) { spin = 7; }
	}
	
	override int GetTicks(int no)
	{
		let ddp = ddPlayer(owner);
		if(!ddp) { return 0; } 
		switch(no)
		{
			case 0:
				if(spin > 6) { return 2; }
				else if(spin > 5) { return 3; }
				else if(spin > 4) { return 4; }
				else if(spin > 3) { return 5; }
				else if(spin > 2) { return 6; }
				else if(spin > 1) { return 7; }
				else { return 8; } 
			default:
				return 0;
		}
	}
	
	override void SetDDTransformations(int no, PSpriteInfo pspi)
	{
		let ddp = ddPlayer(owner);
		if(!ddp) { return; }
		if(ddp.CountInv("Clip") < 1) { pspi.SetTransformationProperties(); return; }
		int i = (weaponside) ? ddp.leftinstability : ddp.rightinstability;
		switch(no)
		{
			case 1:
				pspi.SetTransformationProperties(3, true, (INTR_TRANS_INVEXPO | INTR_SCALE_INVEXPO | INTR_ROTAT_INVEXPO));
				pspi.SetTranslations(0, 12);
				
				//pspi.SetScaling(6, 6);
				if(i > 50) 
				{
					//if flash state, copy weapons rotation
					//sets flash rotation by weapon rotation +/- 3
				if(pspi.id > 15) { int e = pspi.GetRotation(pspi.id - 10, false); 
					if(e > 0) { e = clamp(e-3, 2, 10); } else { e = clamp(e+3, -10, -2); }
				pspi.SetRotation(e); }
				else { pspi.SetRotation(random2(7)); }
				}
				return;
			case 2:
				pspi.SetTransformationProperties(3, true, (INTR_TRANS_INVEXPO | INTR_SCALE_INVEXPO | INTR_ROTAT_INVEXPO), 0., 0.4, true, ddp.GetPSpriteInfo(((weaponside) ? PSP_LEFTW0 : PSP_RIGHTW0), ddp));
				pspi.GetTranslations(pspi.superInfo.ID);
				pspi.GetRotation(pspi.superInfo.ID);
				return;
			default: return;
		}
	}
		
	override void DD_WeapAction(int no)
	{
		let ddp = ddPlayer(owner);
		let weap = ddWeapon(self);
		switch(no)
		{
			case 1:
				spin += 1;
				spintimer = 35;
				if(spin > 7) { spin = 7; }
			case 2:
				if(!PressingFireButton()) { 
					if(weaponside) { ddp.altModeL = 0; fireMode = ddp.altModeL; }
					else { ddp.altModeR = 0; fireMode = ddp.altModeR; }
				}
				break;
			case 3:
				if(spin > 0) { ddp.A_StartSound("weapons/chaingunspin", CHAN_WEAPON, CHANF_OVERLAP, 1., ATTN_NORM, ((spin < 5) ? 1. : 1.2)); }
				return;
			default: ddp.A_Log("No action defined for tic "..no); break;
		}
	}
	
	// ## ddChaingun States()
	States
	{
		NoAmmo:
			#### # 10;
		Ready:
			CHGR A 0 A_ChangeSprite;
			#### # 0 A_DDWeaponReady;
			#### # 1;
			Loop;
		Select:
			CHGG A 0 A_ChangeSprite;
			CHGG # 1;
			Loop;
		Deselect:
			CHGG A 1;
			Loop;
		Fire:
			CHGG A 3 A_WeapAction;
			CHGG A 1 A_DDTransformation;
			CHGG A 0 A_DDFlash;
			CHGG A 1 A_FireDDWeapon;
			CHGG A 0 A_SetTicks;
			CHGG A 1 A_DDTransformation;
			CHGG A 0 A_DDFlash;
			CHGG B 3 A_WeapAction;
			CHGG B 1 A_FireDDWeapon;
			CHGG A 0 A_SetTicks;
			CHGG B 0 A_DDRefire;
			Goto Ready;
		FireClassic:
			CHGG A 0 A_DDFlash;
			CHGG A 4 A_FireDDWeapon;
			CHGG A 0 A_DDFlash;
			CHGG B 4 A_FireDDWeapon;
			CHGG B 0 A_DDRefire;
			Goto Ready;
		Altfire:
			CHGG A 3 A_WeapAction;
			CHGG A 1 A_WeapAction;
			CHGG A 1;
			CHGG A 2 A_WeapAction;
			CHGG A 0 A_SetTicks;
			CHGG B 3 A_WeapAction;
			CHGG B 1 A_WeapAction;
			CHGG B 1;
			CHGG B 2 A_WeapAction;
			CHGG B 0 A_SetTicks;			
			CHGG B 2 A_WeapAction;
			CHGG B 0 A_DDRefire;
			Goto Ready;
		Flash:
			CHGF A 2 A_DDTransformation;
			CHGF A 2 Bright A_Light2;
			Goto FlashDone;
		Flash2:
			CHGF B 2 A_DDTransformation;
			CHGF B 2 Bright A_Light2;
			Goto FlashDone;
		Spawn:
			MGUN A -1;
			Stop;
	}
}

extend class ddWeapon
{	
	action void A_ChainSpin() { A_StartSound("weapons/chaingunspin", CHAN_WEAPON, CHANF_OVERLAP, 1., ATTN_NORM, 1.2); }
	action void A_FireDDCGun()
	{		
		let ddp = ddPlayer(invoker.owner);
		if(ddp.player == null) { return; }
		ddChaingun weap = ddChaingun(self);
		bool pen = (ddp.player.readyweapon is "dualWielding"&&!ddp.CheckESOA(0));
		int kick = (pen) ? 7 : 2;
		if(pen) { kick += weap.spin; } else { kick += (weap.spin / 5); }
		int dam = 5 * random(1,3);
		bool bz = (ddp.FindInventory("PowerBerserk"));
		double eA, eP;
		if(pen) 
		{ 
			eA = (bz) ? (Random2() * (3.75 / 256)) : (Random2() * (6.75 / 256));
			eP = (bz) ? (Random2() * (2.23 / 256)) : (Random2() * (4.75 / 256)); 
		} 
		else { eA = random2() * (2.067 / 256); eP = random2() * (2.35 / 256); }
		if(ddp.FindInventory("ClassicModeToken")) { eA = 0; eP = 0;}
		if(ddp.CountInv("Clip") > 0)
		{
			ddp.A_StartSound("weapons/chngun", CHAN_WEAPON, CHANF_OVERLAP);
			ddShot(!ddp.player.refire, "BulletPuff", dam, eA, eP, weap.weaponside, kick);
			ddp.TakeInventory("Clip", 1);
			double hrec, vrec;
			hrec = (pen) ? 3 + int(double(weap.spin / 15)) : 3 + int(double(weap.spin / 5)); 
			vrec = (pen) ? 3 + (weap.spin / 15) : 3 + (weap.spin / 5); 
			if(pen) { AddRecoil((bz) ? 2. : 3, (bz) ? 2 : 3, 3.5); }
			else { AddRecoil(2., 1, 3.5); }
		}
		else
		{
			ddp.A_StartSound("weapons/nofire", CHAN_WEAPON, CHANF_OVERLAP);
		}
		
	}

}