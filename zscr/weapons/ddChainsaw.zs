// #Class : ddChainsaw : ddWeapon replaces Chainsaw()
//Doom Chainsaw. Unchanged, but cannot be used in dualWielding. No altfire.
class ddChainsaw : ddWeapon replaces Chainsaw
{
	Default
	{
		Weapon.Kickback 0;
		Weapon.SelectionOrder 2200;
		Weapon.UpSound "weapons/sawup";
		Weapon.ReadySound "weapons/sawidle";
		Weapon.AmmoType1 "NotAnAmmo";
		Weapon.AmmoType2 "NotAnAmmo";
		ddWeapon.ClassicAmmoType1 "NotAnAmmo";
		ddWeapon.ClassicAmmoType2 "NotAnAmmo";
		Weapon.AmmoUse1  0;
		Weapon.AmmoUse2  0;
		ddWeapon.rating 3;
		ddWeapon.SwitchSpeed 2;
		ddWeapon.WeaponType "Chainsaw";
		+DDWEAPON.TWOHANDER;
		Inventory.PickupMessage "$GOTCHAINSAW";
		Obituary "$OB_MPCHAINSAW";
		Tag "$TAG_CHAINSAW";
	}
	
	override void InventoryInfo(ddStats ddhud)
	{
		let hud = ddhud;		
		hud.DrawString(hud.fa, GetTag(), (30, 45), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, "level "..hud.FormatNumber(rating).." chainsaw", (30, 55), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, "twohander", (30, 65), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
		hud.DrawString(hud.fa, "no mag", (30, 75), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
	}
	
	override void PreviewInfo(ddStats ddhud)
	{
		let hude = ddhud;
		hude.DrawString(hude.fa, GetTag(), (12, 45), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
	}
	
	override String GetWeaponSprite() { return "CSAWA0"; }
	override String GetParentType() { return "ddChainsaw"; }
	
	override void primaryattack() { A_ddSaw(); }
	override void alternativeattack() { A_ddSaw(); } 
	
	override State GetAttackState()
	{
		return FindState("Fire");
	}
	
	
	// ##ddChainsaw States()
	States
	{
		Ready:
			SAWG CD 4;
			Loop;
		Deselect:
		Select:
			Goto Ready;
		Fire:
			Goto Ready;
		Spawn:
			CSAW A -1;
			Stop;
	}
}

class ddChainsawLeft : ddChainsaw 
{
	Default { ddweapon.weaponside CE_LEFT; -DDWEAPON.GOESININV; }
	
	States
	{
		Ready:
			SAWG CD 4 A_LeftWeaponReady;
			Loop;
		Select:
			SAWG B 1;
			Loop;
		Fire:
			SAWG AB 4 A_FireLeftWeapon;
			SAWG B 0 A_ddRefireLeft;
			Goto Ready;	
		Altfire:
			Goto Ready;
	}
}

class ddChainsawRight : ddChainsaw 
{	
	Default { ddweapon.weaponside CE_RIGHT; -DDWEAPON.GOESININV; }
	
	States
	{
		Ready:
			SAWG C 4 A_RightWeaponReady;
			SAWG D 4;
			Loop;
		Select:
			SAWG B 1;
			Loop;
		Fire:
			SAWG AB 4 A_FireRightWeapon;
			SAWG B 0 A_ddRefireRight;
			Goto Ready;	
		Altfire:
			Goto Ready;	
	}
}

extend class ddWeapon
{
	action void A_ddSaw()
	{
		FTranslatedLineTarget t;
		let ddp = ddPlayer(invoker.owner);
		if(!ddp) { return; }
		let weap = ddWeapon(self);
		let ang = ddp.angle + 2.8125 * (random2() / 256);
		let pit = ddp.pitch;
		int dam = 2 * random(1,10);
		ddp.LineAttack(ang, 64, pit, dam, 'Melee', "BulletPuff", 0, t);
		if(t.LineTarget)
		{
			ddp.A_StartSound("weapons/sawhit", CHAN_WEAPON);
			//classic mode chainsaw gets stuck in target.
			ddp.bJustAttacked = true;
			double anglediff = deltaangle(ddp.angle, t.angleFromSource);
			if(anglediff < 0.0)
			{
				if(anglediff < -4.5)
					angle = t.angleFromSource + 90.0 / 21;
				else
					angle -= 4.5;
			}
			else
			{
				if(anglediff > 4.5)
					angle = t.angleFromSource - 90.0 / 21;
				else
					angle += 4.5;
			}
			return;
		}
		else { ddp.A_StartSound("weapons/sawfull", CHAN_WEAPON); return; }
	}
}
	