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
	}
	
	override void PostBeginPlay()
	{
		safeflasher = false;
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
		let ddp = ddPlayer(owner);
		if(ddp) 
		{
			if(ddp.wolfen && bAltFire && !PressingFireButton()) { 
				if(weaponSide) { ddp.altModeL = 0; }
				else { ddp.altModeR = 0; } 
			}
			if(--spintimer < 0) { spintimer = 0; }
			if(!spintimer) { if(spin > 0) { spin -= 10; spintimer += 35; } if(spin < 0) { spin = 0; } }
		}
	}
	
	override void InventoryInfo(ddStats ddhud)
	{
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
	
	override String, int GetSprites()
	{
		let ddp = ddPlayer(owner);
		if(ddp.FindInventory("ClassicModeToken")) { return "CHGGA", 0; } 
		if(spin > 0)
		{
			int mod;
			if(mod > 29) { mod = 1; } 
			else if(spin > 20) { mod = 2; }
			else if(spin > 12) { mod = 4; }
			else if(spin > 6)  { mod = 8; }
			else { mod = 16; } 
			
			if(level.mapTime & mod) { return "CHGGA", 1; }
			else { return "CHGGB", 0; }
		}
		else { 
			/*if(ddp.player.readyweapon is "dualWielding" || ddp.lastmode is "dualWielding") { return (weaponside) ? "CHGGA0" : "CHGRA0", 0; }
			else { return "CHGGA0", 0; }*/
			return "CHGGA0", 0;
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
		/*if(mode is "dualWielding" || ddp.player.pendingweapon is "dualWielding" || ddp.lastmode is "dualWielding") {
			ddp.player.GetPSprite(PSP_RIGHTWF).Frame = ((safeflasher) ? 5 : 4); 
		}*/
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
		spin += 5;
		spintimer = 35;
		if(spin > 40) { spin = 40; }
	}
	
	override int GetTicks()
	{
		let ddp = ddPlayer(owner);
		if(spin > 32) { return 2; }
		else if(spin > 24) { return 3; }
		else if(spin > 18) { return 4; }
		else if(spin > 9) { return 5; }
		else { return 12; } 
	}
	
	override void DD_WeapAction(int no)
	{
		let ddp = ddPlayer(owner);
		let weap = ddWeapon(self);
		switch(no)
		{
			case 1:
				spin += 5;
				spintimer = 35;
				if(spin > 40) { spin = 40; }
				break;
			default: ddp.A_Log("No action defined for tic "..no); break;
		}
	}
	
	// ## ddChaingun States()
	States
	{
		NoAmmo:
			CHGG A 10;
		Ready:
			CHGG A 1;
			Loop;
		Deselect:
			CHGG A 1 A_Lower;
			Loop;
		Select:
			CHGG A 1;
			Loop;
		Fire:
			Goto Ready;
		Altfire:
			Goto Ready;
		Flash:
			CHGF A 5 Bright A_Light2;
			Goto FlashDone;
		Flash2:
			CHGF B 5 Bright A_Light2;
			Goto FlashDone;
		Spawn:
			MGUN A -1;
			Stop;
	}
}
// #Class ddChaingunLeft : ddChaingun()
class ddChaingunLeft : ddChaingun
{
	Default { ddweapon.weaponside CE_LEFT; -DDWEAPON.GOESININV; }
	States
	{
		NoAmmo:
			#### # 10;
		Ready:
			CHGG A 0 A_ChangeSpriteLeft;
			#### # 1 A_LeftWeaponReady;
			Loop;
		Select:
			CHGG A 0 A_ChangeSpriteLeft;
			#### # 1;
			Loop;
		Fire:
			CHGG A 0 A_ChainSpin;
			CHGG A 0 A_FlashLeft;
			CHGG A 1 A_FireLeftWeapon;
			CHGG A 1 A_SetTicksLeft;
			CHGG A 0 A_FlashLeft;			
			CHGG A 0 A_ChainSpin;
			CHGG B 1 A_FireLeftWeapon;
			CHGG A 1 A_SetTicksLeft;
			CHGG B 0 A_ddRefireLeft;
			Goto Ready;
		FireClassic:
			CHGG A 0 A_FlashLeft;
			CHGG A 4 A_FireLeftWeapon;
			CHGG A 0 A_FlashLeft;
			CHGG B 4 A_FireLeftWeapon;
			CHGG B 0 A_ddRefireLeft;
			Goto Ready;
		Altfire:
			CHGG A 0 A_ChainSpin;
			CHGG A 1 A_WeapActionLeft;
			CHGG A 1;
			CHGG A 1 A_SetTicksLeft;
			CHGG B 0 A_ChainSpin;
			CHGG B 0 A_ChainSpin;
			CHGG B 1 A_WeapActionLeft;
			CHGG B 1;
			CHGG B 1 A_SetTicksLeft;
			CHGG B 0 A_ddRefireLeft;
			Goto Ready;
			/*
		Flash:
			CHGF # 5 Bright A_Light2;
			Goto FlashDone;
		Flash2:
			CHGF # 5 Bright A_Light2;
			Goto FlashDone;*/
	}
}
// #Class ddChaingunRight : ddChaingun()
class ddChaingunRight : ddChaingun
{
	Default { ddweapon.weaponside CE_RIGHT; -DDWEAPON.GOESININV; }
	States
	{
		NoAmmo:
			#### # 10;
		Ready:
			CHGR A 0 A_ChangeSpriteRight;
			#### # 1 A_RightWeaponReady;
			Loop;
		Select:
			CHGG A 0 A_ChangeSpriteRight;
			#### # 1;
			Loop;
		Fire:
			CHGG A 0 A_ChainSpin;
			CHGG A 0 A_FlashRight;
			CHGG A 1 A_FireRightWeapon;
			CHGG A 1 A_SetTicksRight;
			CHGG A 0 A_FlashRight;
			CHGG B 0 A_ChainSpin;
			CHGG B 1 A_FireRightWeapon;
			CHGG A 1 A_SetTicksRight;
			CHGG B 0 A_ddRefireRight;
			Goto Ready;
		FireClassic:
			CHGG A 0 A_FlashRight;
			CHGG A 4 A_FireRightWeapon;
			CHGG A 0 A_FlashRight;
			CHGG B 4 A_FireRightWeapon;
			CHGG B 0 A_ddRefireRight;
			Goto Ready;
		Altfire:
			CHGG A 0 A_ChainSpin;
			CHGG A 1 A_WeapActionRight;
			CHGG A 1;
			CHGG A 1 A_SetTicksRight;
			CHGG B 0 A_ChainSpin;
			CHGG B 0 A_ChainSpin;
			CHGG B 1 A_WeapActionRight;
			CHGG B 1;
			CHGG B 1 A_SetTicksRight;
			CHGG B 0 A_ddRefireRight;
			Goto Ready;
			/*
		Flash:
			CHGF # 5 Bright A_Light2;
			Goto FlashDone;
		Flash2:
			CHGF # 5 Bright A_Light2;
			Goto FlashDone;*/
	}
}


extend class ddWeapon
{	
	action void A_ChainSpin() { A_StartSound("weapons/chaingunspin", CHAN_WEAPON, CHANF_OVERLAP); }
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