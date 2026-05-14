// #Class ddBFG9000 : ddWeapon()
//Doom BFG9000. Twohanded weapon; cannot be used when dual-wielding. BFGBall updated to act similar to modern BFG, with increased ammo cost to compensate.
class ddBFG9000 : ddWeapon replaces BFG9000
{
	Default
	{
		Height 20;
		Weapon.SelectionOrder 2800;
		Weapon.AmmoUse 50;
		Weapon.AmmoUse2 50;
		Weapon.AmmoGive 50;
		Weapon.AmmoType "Cell";
		Weapon.AmmoType2 "Cell";
		ddWeapon.rating 9;
		ddWeapon.SwitchSpeed 1.0;
		ddWeapon.xOffset 24;
		ddWeapon.WeaponType "Cannon";
		+WEAPON.NOAUTOFIRE;
		+DDWEAPON.TWOHANDER;
		Inventory.PickupMessage "$GOTBFG9000";
		Tag "$TAG_BFG9000";
	}
	
	override void InventoryInfo(ddStats ddhud, bool debug)
	{
		if(debug) { Super.InventoryInfo(ddhud, debug); return; }
		let hud = ddhud;		
		hud.DrawString(hud.fa, GetTag(), (32, 45), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, "level "..hud.FormatNumber(rating).." heavy cannon", (32, 55), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, "twohander", (32, 65), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, "no mag", (32, 75), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
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
	
	override String, int GetSprites(int no)
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
		int myside = (weaponside) ? PSP_LEFTW0 : PSP_RIGHTW0; 
		int flashside = (weaponside) ? PSP_LEFTWF0 : PSP_RIGHTWF0;
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
	
	override void SetDDTransformations(int no, PSpriteInfo pspi)
	{
		let ddp = ddPlayer(owner);
		if(!ddp) { return; }
		let i = (weaponside) ? ddp.leftInstability : ddp.rightInstability;
		switch(no)
		{
			case 0: //fire 1
				pspi.SetTransformationProperties(5, true, (INTR_TRANS_INVEXPO));
				pspi.SetTranslations(0, 10);
				pspi.SetScaling(30, 40);
				return;
			case 1: //fire loop
				pspi.SetTransformationProperties(1, false, (INTR_TRANS_INVEXPO), nextcase:1);
				pspi.SetTranslations(clamp(random(-3, 3), -3 ,3), clamp(random(-2, 2), -2, 2));
				return;
			case 2: //flash 1
				pspi.SetTransformationProperties(5, true, (INTR_TRANS_INVEXPO), 0., 0.4, true, ddp.GetPSpriteInfo(((weaponside) ? PSP_LEFTW0 : PSP_RIGHTW0), ddp));
				pspi.GetTranslations(pspi.superInfo.ID);
				pspi.SetScaling(20, 0);
				return;
			case 3: 
				pspi.SetTransformationProperties(1, true, (INTR_TRANS_INVEXPO));
				pspi.SetTranslations(0, 0, TFL_TRANS_ORIGIN);
				return;
			default:
				return;
		}
	}
	
	// ## ddBFG9000 States()
	States
	{
		NoAmmo:
			BFGG A 10;
		Ready:
			BFGG A 1 A_DDWeaponReady;
			Loop;
		Select:
			BFGG A 1;
			Loop;
		Deselect:
			BFGG A 1;
			Loop;
		Fire:
			BFGG A 1 A_WeapAction;
			BFGG A 1;
			BFGG A 1 A_DDTransformation;
			BFGG A 20 A_BFGsound;
			BFGG A 3 A_DDTransformation;
			BFGG B 10 A_DDFlash;
			BFGG B 0 A_DDTransformation;
			BFGG B 10 A_FireDDWeapon;
			BFGG B 20 A_DDRefire;
			Goto Ready;
		Altfire:
			Goto Ready;
		Flash:
			BFGF A 9 Bright A_Light1;
			BFGF A 2 A_DDTransformation;
			BFGF A 2;
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

class BFGBalle : BFGBall
{
	//adapted from A_BFGSpray() https://github.com/UZDoom/UZDoom/blob/trunk/wadsrc/static/zscript/actors/doom/weaponbfg.zs line:216
	//BFG spray that projects in a 360 deg field around BFGBalle. Will incorporate horizontal autoaiming, but limit total amount of damage dealt via tracers to 1800-2400
	void NewBFGSpray()
	{
		int totalTracerDam, tracerDamMax, tracersUsed;
		tracerDamMax = 1800 + random(0,600);
		FTranslatedLineTarget lt;
		Actor orig = self;
		if(!target) { return; }
		for(int x = 0; x < 90; x++)
		{
			if(totalTracerDam >= tracerDamMax) { break; }
			//alternate quadrants to ensure a big creature doesn't take all the heat
			int ang = x + (90 * ((x % 4) + 1));
			orig.AimLineAttack(ang, 1024, lt, 32);
			if(!lt.linetarget)
			{				
				orig.AimLineAttack(ang + 5, 1024, lt, 32);
			}
			if(!lt.linetarget)
			{
				orig.AimLineAttack(ang - 5, 1024, lt, 32);				
			}
			if(!lt.linetarget) { continue; }
			BFGExtra spray = BFGExtra(Spawn("BFGExtra", lt.linetarget.pos + (0, 0, lt.linetarget.Height / 4), ALLOW_REPLACE));
			if(!spray) { continue; }
			if(target.GetSpecies() == lt.linetarget.GetSpecies()) { spray.Destroy(); continue; }
			int spraydam;
			for(int y = 0; y < 15; ++y)
			{
				spraydam += random(1,8);
				if(spraydam > lt.linetarget.health) //if overkilling, chance to stop doing more damage
				{
					if(random(35, 128) > 100) { break; }
				}
			}
			int dmg = lt.linetarget.DamageMobj(orig, target, spraydam, 'BFGSplash', DMG_USEANGLE, lt.angleFromSource);
			lt.TraceBleed(dmg, orig);
			if(ddPlayer(target).dddebug & DBG_WEAPONS) { console.printf("damaged "..lt.linetarget.GetClassName().." for "..dmg.." damage."); }
			totalTracerDam += dmg;
			if(ddPlayer(target).dddebug & DBG_WEAPONS) { console.printf("total tracer damage at "..totalTracerDam.." up to "..tracerDamMax.."."); }
			tracersUsed++;
		}
		if(ddPlayer(target).dddebug & DBG_WEAPONS) { console.printf("NewBFGSpray finished using "..tracersUsed.." tracers and dealing "..totalTracerDam.." damage out of "..tracerDamMax.."."); }
	}
	
	States
	{
		Spawn:
			BFS1 AB 2 Bright;
			Loop;
		Death:
			BFE1 AB 4 Bright;
			BFE1 C 4 Bright NewBFGSpray;
			BFE1 DEF 2 Bright;
			Stop;
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
		ddp.SpawnPlayerMissile("BFGBalle", ddp.angle, nofreeaim:sv_nobfgaim);
		ddp.TakeInventory("Cell", invoker.ammouse1);		
	}
	
	action void A_BFGAltFireStart()	{ A_StartSound("weapons/10kmodeg", CHAN_WEAPON);	}
	action void A_BFGAltFireSound() { invoker.owner.A_StartSound("weapons/10kmodef", CHAN_WEAPON, CHANF_OVERLAP); }
	action void A_BFGAltFireStop() { A_StartSound("weapons/10kmodes", CHAN_WEAPON, CHANF_OVERLAP); }	
}

// #Class BFGSpawner : RandomSpawner replaces BFG9000()
/* ##DISABLED##
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
*/