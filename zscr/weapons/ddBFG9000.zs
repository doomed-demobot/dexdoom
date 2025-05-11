// #Class ddBFG9000 : ddWeapon()
//Doom BFG9000. Unchanged, but cannot be used in dualWielding. No altfire
class ddBFG9000 : ddWeapon
{
	Default
	{
		Height 20;
		Weapon.SelectionOrder 2800;
		Weapon.AmmoUse 40;
		Weapon.AmmoUse2 10;
		Weapon.AmmoGive 40;
		Weapon.AmmoType "Cell";
		Weapon.AmmoType2 "Cell";
		ddWeapon.ClassicAmmoType1 "Cell";
		ddWeapon.ClassicAmmoType2 "Cell";
		ddWeapon.rating 9;
		ddWeapon.SwitchSpeed 1.0;
		ddWeapon.xOffset 24;
		ddWeapon.WeaponType "Cannon";
		+WEAPON.NOAUTOFIRE;
		+DDWEAPON.TWOHANDER;
		Inventory.PickupMessage "$GOTBFG9000";
		Tag "$TAG_BFG9000";
	}
	
	override void InventoryInfo(ddStats ddhud)
	{
		let hud = ddhud;		
		hud.DrawString(hud.fa, GetTag(), (30, 45), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, "level "..hud.FormatNumber(rating).." heavy cannon", (30, 55), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, "twohander", (30, 65), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, "no mag", (30, 75), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
	}
	
	override void PreviewInfo(ddStats ddhud)
	{
		let hude = ddhud;
		hude.DrawString(hude.fa, GetTag(), (12, 45), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
		hude.DrawString(hude.fa, "Spare ammo: "..hude.FormatNumber(AmmoGive1), (12, 52), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
	}
	
	override String GetWeaponSprite()
	{
		return "BFUGA0";
	}
	
	override void primaryattack()
	{
		A_FireDDBFG();
	}
	
	override State GetFlashState()
	{
		if(!bAltFire) { return FindState('Flash'); }
		else { return FindState('Flash2'); }  
	}
	
	override String, int GetSprites()
	{
		return "BFGGA0", -1;
	}
	
	override String getParentType()
	{
		return "ddBFG9000";
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
			case 1:
				if(ddp.CountInv("Cell") < 40) { ChangeState("NoAmmo", myside); break; }
				ddp.PlayAttacking();
				break;
			default: ddp.A_Log("No action defined for tic "..no); break;
		}
	}
	
	// ## ddBFG9000 States()
	States
	{
		NoAmmo:
			BFGG A 10;
		Ready:
			BFGG A 1;
			Loop;
		Deselect:
			BFGG A 1 A_Lower;
			Loop;
		Select:
			BFGG A 1;
			Loop;
		Fire:
			Goto Ready;
		Altfire:
			Goto Ready;
		Flash:
			BFGF A 11 Bright A_Light1;
			BFGF B 6 Bright A_Light2;
			Goto FlashDone;
		Flash2:
			BFGF A 3 Bright A_Light1;
			BFGF B 3 Bright A_Light2;
			Goto FlashDone;
		Spawn:
			BFUG A -1;
			Stop;
	}
}
// #Class ddBFG9000Left : ddBFG9000()
class ddBFG9000Left : ddBFG9000
{	
	Default { ddweapon.weaponside CE_LEFT; -DDWEAPON.GOESININV; }
	States
	{
		NoAmmo:
			BFGG A 10;
		Ready:
			BFGG A 1 A_DDWeaponReady;
			Loop;
		Fire:
			BFGG A 1 A_WeapAction;
			BFGG A 1;
			BFGG A 20 A_BFGsound;
			BFGG B 10 A_DDFlash;
			BFGG B 10 A_FireDDWeapon;
			BFGG B 20 A_DDRefire;
			Goto Ready;
		AltFire:
			Goto Ready;
			/*
		Altfire:
			BFGG A 0  A_JumpIfNoAmmoLeft;
			BFGG A 45 A_BFGAltFireStart;
			BFGG A 0  A_ddRefireLeft;
		Spindown:
			BFGG A 45 A_BFGAltFireStop;
			Goto Ready;
		Blasting:
			BFGG B 0 A_FlashLeft;
			BFGG B 3 A_FireLeftWeapon;
			BFGG A 3;
			BFGG A 0 A_ddRefireLeft;
			Goto Spindown;
			*/
	}
}
// #Class ddBFG9000Right : ddBFG9000()
class ddBFG9000Right : ddBFG9000
{	
	Default { ddweapon.weaponside CE_RIGHT; -DDWEAPON.GOESININV; }
	States
	{
		NoAmmo:
			BFGG A 10;
		Ready:
			BFGG A 1 A_DDWeaponReady;
			Loop;
		Fire:
			BFGG A 1 A_WeapAction;
			BFGG A 1;
			BFGG A 20 A_BFGsound;
			BFGG B 10 A_DDFlash;
			BFGG B 10 A_FireDDWeapon;
			BFGG B 20 A_DDRefire;
			Goto Ready;
		AltFire:
			Goto Ready;
			/*
		Altfire:
			BFGG A 0  A_JumpIfNoAmmoRight;
			BFGG A 45 A_BFGAltFireStart;
			BFGG A 0 A_ddRefireRight;
		Spindown:
			BFGG A 45 A_BFGAltFireStop;
			Goto Ready;
		Blasting:
			BFGG B 0 A_FlashRight;
			BFGG B 3 A_FireRightWeapon;
			BFGG A 3;
			BFGG A 0 A_ddRefireRight;
			Goto Spindown;
			*/
	}
}

extend class ddWeapon
{
	action void A_FireDDBFG()
	{
		let ddp = ddPlayer(invoker.owner);
		if(ddp.player == null) { return; }
		ddWeapon weap = ddWeapon(self);
		bool pen = (ddp.player.readyweapon is "dualWielding"&&!ddp.CheckESOA(0));
		int kick = 90;
		ddp.instability += kick;
		ddp.instTimer = 40;
		ddp.SpawnPlayerMissile("BFGBall", ddp.angle, nofreeaim:sv_nobfgaim);
		ddp.TakeInventory("Cell", 40);		
	}
	//deprecated
	action void A_FireDDBFGBolt()
	{
		let own = ddPlayer(invoker.owner);
		if(own.player == null) { return; }
		A_BFGAltFireSound();
		own.SpawnPlayerMissile("BFGBlast", own.angle);
		own.TakeInventory("Cell", 10);
	}
	
	action void A_BFGAltFireStart()	{ A_StartSound("weapons/10kmodeg", CHAN_WEAPON);	}
	action void A_BFGAltFireSound() { invoker.owner.A_StartSound("weapons/10kmodef", CHAN_WEAPON, CHANF_OVERLAP); }
	action void A_BFGAltFireStop() { A_StartSound("weapons/10kmodes", CHAN_WEAPON, CHANF_OVERLAP); }
	
}
// #Class BFGSpawner : RandomSpawner replaces BFG9000()
class BFGSpawner : RandomSpawner replaces BFG9000
{

	Default
	{
		DropItem "ddBFG9000", 255, 59;
		DropItem "ESOA", 255, 10;
	}
	
	override Name ChooseSpawn()
	{
		for(int x = 0; x < 8; x++)
		{
			if(players[x].mo is "ddPlayerClassic")
			{
				return "ddBFG9000";
			}
		}
		return Super.ChooseSpawn();
	}
}

class BFGBlast : Actor //[unused]
{	
	Default
	{
		Radius 12;
		Height 12;
		Scale 0.5;
		Speed 500;
		Damage 100;
		Projectile
		+RANDOMIZE;
		+NOGRAVITY
		DeathSound "weapons/bfgx";
		Obituary "%o saw a bright light.";
	}
	States
	{
		Spawn:
			PLS2 AB 3 Bright;
			Loop;
		Death:
			BFE1 A 2 Bright A_Explode;
			BFE1 B 2;
			BFE1 C 2 Bright;
			BFE1 DEF 2 Bright;
			Stop;
	}
}