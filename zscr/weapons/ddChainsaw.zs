// #Class : ddChainsaw : ddWeapon replaces Chainsaw()
//Doom Chainsaw. Unchanged, but cannot be used in dualWielding. No altfire.
//todo: make fistweapon
class ddChainsaw : ddFist 
{
	Default
	{
		Inventory.MaxAmount 2;
		Weapon.UpSound "weapons/sawup";
		Weapon.ReadySound "weapons/sawidle";
		Weapon.AmmoType1 "NotAnAmmo";
		Weapon.AmmoType2 "NotAnAmmo";
		ddWeapon.ClassicAmmoType1 "NotAnAmmo";
		ddWeapon.ClassicAmmoType2 "NotAnAmmo";
		Weapon.AmmoUse1  0;
		Weapon.AmmoUse2  0;
		ddWeapon.rating 3;
		ddWeapon.SwitchSpeed 0.75;
		ddWeapon.WeaponType "Chainsaw";
		+DDWEAPON.TWOHANDER;
		-DDWEAPON.GOESININV;	
		+DDFIST.ADDME;
		ddWeapon.WeaponType "Fist";
		Inventory.PickupMessage "$GOTCHAINSAW";
		Obituary "$OB_MPCHAINSAW";
		Tag "$TAG_CHAINSAW";
	}
	/*
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
	*/
	
	override String GetIconSprite()
	{
		return "ICCHAI";
	}
	
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
	}
}

class ddChainsawLeft : ddChainsaw 
{
	Default { Inventory.MaxAmount 1; -DDFIST.ADDME; ddweapon.weaponside CE_LEFT; }
	
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
	Default { Inventory.MaxAmount 1; -DDFIST.ADDME; ddweapon.weaponside CE_RIGHT; }
	
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

// #Class ChainsawPK : CustomInventory()
class ChainsawPK : CustomInventory replaces Chainsaw
{
	Default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 2;
		Inventory.PickupMessage "You found a chainsaw!";
		Inventory.PickupSound "misc/secret";
		-INVENTORY.INVBAR;
		+INVENTORY.UNTOSSABLE;
		+INVENTORY.UNDROPPABLE;	
	}
	
	States
	{	
		Spawn:
			CSAW A -1;
			Stop;
		Pickup:
			TNT1 A 1 A_GiveInventory("ddChainsaw", 1);
			TNT1 A 0 A_GiveInventory("ddChainsawLeft", 1);
			TNT1 A 0 A_GiveInventory("ddChainsawRight", 1);
			Stop;
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
	