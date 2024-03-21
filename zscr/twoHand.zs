// #Class twoHanding : ddWeapon()
//Weapon mode for using a single weapon.
class twoHanding : ddWeapon
{
	//flags; define flags when needed
	int thFlags;
	
	Default
	{	
		Weapon.SlotNumber 1;
		Weapon.MinSelectionAmmo1 0;
		Weapon.BobRangeX 0;
		Weapon.BobRangeY 0;
		Weapon.BobSpeed 0;
		Weapon.SelectionOrder 1;
		Weapon.UpSound "weapon/twohup";
		Inventory.Amount 1;
		Inventory.MaxAmount 1;
		-DDWEAPON.MODEREADY;
		-DDWEAPON.GOESININV;
		+WEAPON.NODEATHDESELECT;
		+WEAPON.NODEATHINPUT;
		+WEAPON.DONTBOB;
		+WEAPON.AMMO_OPTIONAL;
		+INVENTORY.UNDROPPABLE;
		Tag "Two Handing";
	}
		
	//constant checking
	
	override void Tick()
	{
		Super.Tick();
		if(!owner) { return; }
		let ddp = ddPlayer(owner);
		let rw = ddp.GetRightWeapons();
		if(ddp.FindInventory("PowerBerserk"))
		{
			if(rw.RetItem(ddp.rwx)) { rw.RetItem(ddp.rwx).WhileBerserk(); }
		}
		if(PressingLeftFire() || PressingLeftAltFire()) { leftheld = true; }
		else { leftheld = false; }
		if(PressingRightFire() || PressingRightAltFire()) { rightheld = true; }
		else { rightheld = false; }
	}
	
	override void HUDA(ddStats hude)
	{
		let ddp = ddPlayer(owner);
		let lWeap = ddp.GetLeftWeapons();
		let rWeap = ddp.GetRightWeapons();
		let mode = twoHanding(self);
		ddWeapon curWeap;
		if(rWeap.items.Size()) { curWeap = ddp.GetRightWeapon(ddp.rwx); }
		let type = (ddp is "ddPlayerClassic") ?
		((!curWeap.bAltFire) ? curWeap.ClassicAmmoType1 : curWeap.ClassicAmmoType2) :
		((!curWeap.bAltFire) ? curWeap.AmmoType1 : curWeap.AmmoType2);
		let plarm = ddp.FindInventory("BasicArmor");
		bool wolfen = CVar.GetCVar("pl_wolfen", ddp.player).GetBool();
		if(curWeap)
		{
			int curWeapAm, curWeapMx;
			[curWeapAm, curWeapMx] = hude.GetAmount(type);		
			let bz = ddp.FindInventory("PowerBerserk");
			let inv = ((ddp.player.cheats & CF_GODMODE) || ddp.FindInventory("PowerInvulnerable"));
			bool mx = (curWeapAm == curWeapMx);
			hude.DrawImage(bz ? "HCBRZK" : "HCNORM", (35, -20), hude.DI_SCREEN_LEFT_BOTTOM, bz ? 0.4 : 0.8);
			hude.DrawImage(inv ? "HCINVN" : "", (35, -20), hude.DI_SCREEN_LEFT_BOTTOM, 0.9);
			hude.DrawString(hude.bf, (ddp.Health > -200) ? hude.FormatNumber(ddp.Health) : "REALLY FREAKIN' DEAD", (50, -35), hude.DI_SCREEN_LEFT_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, 0, 0.5, -1, 4, (1.25,1.25));
			if(ddp.ddWeaponState & DDW_WANNAREPLACE) 
			{ 
				int fade = 50 - (50 * sin(hude.oscilator));
				int stretch = 2 - (2 * sin(hude.oscilator));
				if(ddp.ddWeaponState & DDW_REPLACERIGHT) 
				{ 
					hude.Fill(Color(200 - fade, 120, 0, 255), -17, -12-(stretch/2), 40, 2+stretch, hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER);
				} 
			}
			if(!(curWeap is "ddFist"))
			{
				hude.DrawString(hude.bf, hude.FormatNumber(curWeapAm), (0, -35), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, mx ? Font.CR_DARKGREEN : 0, 0.5, -1, 4, (1.25,1.25));
				
			}
			else
			{
				hude.DrawString(hude.bf, "Empty", (0, -35), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, mx ? Font.CR_DARKGREEN : 0, 0.5, -1, 4, (1.25,1.25));
				hude.DrawString(hude.bf, curWeap.GetTag(), (0, -20), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, mx ? Font.CR_DARKGREEN : 0, 0.5, -1, 4, (0.75,0.75));
			}
			if(wolfen) 
			{ 
				if(!ddp.FindInventory("ClassicModeToken")) { hude.DrawString(hude.fa, ddp.altmodeR ? "A" : "P", (0, -48), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER); } 
			}
			hude.DrawInventoryIcon(plarm, (-35, -20), 0, 0.4);
			hude.DrawString(hude.bf, hude.FormatNumber(plarm.Amount), (-50, -35), hude.DI_SCREEN_RIGHT_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, 0, 0.5, -1, 4, (1.25,1.25));			
			if(ddp.desire)
			{
				if(ddp is "ddPlayerClassic")
				{
					hude.DrawString(hude.fa, ddp.desire.GetTag(), (12, 45), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
					hude.DrawString(hude.fa, "Spare ammo: "..hude.FormatNumber(ddp.desire.AmmoGive1), (12, 52), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
				}
				else { ddp.desire.PreviewInfo(hude); }
			}
			if(ddp.dddebug & DBG_WEAPONS)			
			{
				hude.DrawString(hude.bf, ".", (-50, -85), hude.DI_SCREEN_RIGHT_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, (rightheld) ? Font.CR_GREEN : Font.CR_RED);		
				hude.DrawString(hude.bf, ".", (-50, -75), hude.DI_SCREEN_RIGHT_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, (ddp.ddWeaponState & DDW_RIGHTREADY) ? Font.CR_GREEN : Font.CR_RED);		
				hude.DrawString(hude.bf, ".", (-50, -65), hude.DI_SCREEN_RIGHT_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, (curWeap.weaponready) ? Font.CR_CYAN : Font.CR_RED);
				hude.DrawString(hude.bf, ".", (0, -15), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, (bModeReady) ? Font.CR_GREEN : Font.CR_RED);				
				if(ddp.dddebug & DBG_VERBOSE && curweap.companionpiece)
					hude.DrawImage(curWeap.companionpiece.GetWeaponSprite(), (-50, -85), hude.DI_SCREEN_RIGHT_BOTTOM | hude.DI_TEXT_ALIGN_CENTER);
			}
			
		}
		
	}
	
	override ddWeapon CreateTossable()
	{
		let ddp = ddPlayer(owner);
		let lWeap = ddp.GetLeftWeapons();
		let rWeap = ddp.GetRightWeapons();
		let pInv = ddp.GetWeaponsInventory();
		let pspr = ddp.player.getpsprite(PSP_RIGHTW);
		let psprf = ddp.player.getpsprite(PSP_RIGHTWF);
		let weap = rWeap.RetItem(ddp.rwx);
		if(weap is "ddFist") { ddp.A_Print("no can do", 1); ddp.A_StartSound("misc/boowomp", CHAN_BODY, CHANF_OVERLAP); return null; }
		for(int x = 0; x < pInv.items.Size(); x++)
		{
			if(pInv.RetItem(x).weaponName == "emptie")
			{
				ddp.A_Print("Stored "..weap.GetTag(), 1);
				pInv.RetItem(x).construct(weap.GetParentType(), weap.rating, weap.GetWeaponSprite(), weap.mag, weap.ddWeaponFlags);
				rWeap.SetItem(ddWeapon(ddp.GetFists(0)), ddp.rwx);
				if(++ddp.rwx > rWeap.size - 1) { ddp.rwx = 0; }
				rSwapTarget = ddp.rwx;
				rWeap.RetItem(ddp.rwx).companionpiece = lWeap.RetItem(ddp.lwx);
				lWeap.RetItem(ddp.lwx).companionpiece = rWeap.RetItem(ddp.rwx);		
				ddp.player.setpsprite(PSP_RIGHTW, rWeap.RetItem(ddp.rwx).GetUpState());	
				ddp.ddWeaponState &= ~DDW_RIGHTREADY;
				bmodeready = false;
				pspr.y = 128;
				psprf.y = 128;
				ddp.player.SetPSprite(PSP_WEAPON, FindState('QuickSwapTH'));
				return null;
			}
		}
		let tos = ddWeapon(Spawn(weap.GetParentType()));
		tos.AttachToOwner(owner);
		tos.mag = weap.mag;
		tos.ddWeaponFlags = weap.ddWeaponFlags;
		tos.AmmoGive1 = 0;		
		rWeap.SetItem(ddWeapon(ddp.GetFists(0)), ddp.rwx);
		if(++ddp.rwx > rWeap.size - 1) { ddp.rwx = 0; }
		rSwapTarget = ddp.rwx;
		rWeap.RetItem(ddp.rwx).companionpiece = lWeap.RetItem(ddp.lwx);
		lWeap.RetItem(ddp.lwx).companionpiece = rWeap.RetItem(ddp.rwx);	
		ddp.player.setpsprite(PSP_RIGHTW, rWeap.RetItem(ddp.rwx).GetUpState());	
		ddp.ddWeaponState &= ~DDW_RIGHTREADY;
		bmodeready = false;
		pspr.y = 128;
		psprf.y = 128;	
		ddp.player.SetPSprite(PSP_WEAPON, FindState('QuickSwapTH'));
		ddp.RemoveInventory(weap);
		ddp.A_Print("Dropped "..weap.GetTag(), 1);			
		return ddWeapon(tos.CreateTossable());
	}

	
	action void A_FireTwoHanded()
	{
		let ddp = ddPlayer(self);
		let weap = ddp.GetRightWeapon(ddp.rwx);
		let pspr = player.getpsprite(PSP_RIGHTW);
		if(ddp.ddWeaponState & DDW_WANNAREPLACE) 
		{ 
			if(A_PressingRightFire() || A_PressingRightAltFire()) 
			{ 
				if(!(ddp.ddWeaponState & DDW_REPLACERIGHT)) { A_StartSound("misc/chat2", CHAN_BODY, 0, 1.0, ATTN_NORM, 0.5); }
				ddp.ddWeaponState |= DDW_REPLACERIGHT; 
				ddp.ddWeaponState &= ~DDW_REPLACELEFT;
			}
		}
		else
		{
			if(A_PressingRightFire())
			{
				//primary fire
				weap.onWeaponFire(0, invoker.rightheld);
				if(ddp.ddWeaponState & DDW_RIGHTREADY)
				{
					//ddp.PlayAttacking();
					weap.weaponStatus = DDW_FIRING;
					ddp.ddWeaponState &= ~DDW_RIGHTREADY;
					ddp.ddWeaponState &= ~DDW_RIGHTBOBBING;
					weap.bAltFire = false;
					player.SetPSprite(PSP_RIGHTW, weap.GetAttackState());
					if(!weap.bNoAlert)
					{
						SoundAlert(self);
					}
					weap.weaponready = false;
				}
				
			}
			else if(A_PressingRightAltFire())
			{
				//secondary fire
				if(FindInventory("ClassicModeToken")) { return; } 
				weap.onWeaponFire(0, invoker.rightheld);
				if(ddp.ddWeaponState & DDW_RIGHTREADY)
				{
					//ddp.PlayAttacking();
					ddp.ddWeaponState &= ~DDW_RIGHTREADY;
					weap.weaponStatus = DDW_ALTFIRING;
					ddp.ddWeaponState &= ~DDW_RIGHTBOBBING;
					weap.bAltFire = true;
					player.SetPSprite(PSP_RIGHTW, weap.GetAttackState());
					if(!weap.bNoAlert)
					{
						SoundAlert(self);
					}
					weap.weaponready = false;
				}
			}
			else if(A_PressingRightModeSwitch())
			{
				if(ddp.ddWeaponState & DDW_RIGHTREADY)
				{
					ddp.altmodeR = !ddp.altmodeR;
					weap.weaponStatus = DDW_FIRING;
					weap.bAltFire = false;
					A_StartSound("weapons/chaingunspin", CHAN_BODY, CHANF_OVERLAP);
					player.SetPSprite(PSP_RIGHTW, weap.FindState('NoAmmo'));
					ddp.ddWeaponState &= ~DDW_RIGHTREADY;
					weap.weaponready = false;
				}
			}
			else if(A_PressingReload())
			{
				if(ddp.ddWeaponState & DDW_RIGHTREADY)
				{
					player.SetPSprite(PSP_RIGHTW, weap.FindState('Select'));
					A_CheckRightWeaponMag();
					weap.weaponready = false;
					ddp.ddWeaponState &= ~DDW_RIGHTREADY;
				}
			}
		}
	}
	
	action void A_QuickSwapTH()
	{
		let ddp = ddPlayer(self);
		let lWeap = ddp.GetLeftWeapons();
		let rWeap = ddp.GetRightWeapons();
		let lw = ddp.GetLeftWeapon(ddp.lwx);
		let rw = ddp.GetRightWeapon(ddp.rwx);
		let pspl = player.GetPSprite(PSP_LEFTW);
		let psplf = player.GetPSprite(PSP_LEFTWF);
		let pspr = player.GetPSprite(PSP_RIGHTW);
		let psprf = player.GetPSprite(PSP_RIGHTWF);
		double sFactor;
		if(rw) 
		{ 			
			sFactor = rw.sFactor * 6;
			if(ddp.rwx != invoker.rSwapTarget) //lower right weapon
			{
				pspr.y += sFactor; psprf.y += sFactor;
				if(pspr.y < WEAPONBOTTOM) {  }
				else
				{
					pspr.y = 128; psprf.y = 128;
					ddp.rwx = invoker.rSwapTarget;
					rw = rWeap.RetItem(ddp.rwx);
					if(rw.bTwoHander && !ddp.CheckESOA(2)) { ddp.ddWeaponState |= DDW_RIGHTISTH; }
					else { ddp.ddWeaponState &= ~DDW_RIGHTISTH; }
					pspr.x = 0;
					psprf.x = 0;
					if(rw.UpSound) { ddp.A_StartSound(rw.UpSound, CHAN_WEAPON); }
					player.SetPSprite(PSP_RIGHTW, rw.GetUpState());
					player.SetPSprite(PSP_RIGHTWF, null);
				}
			}
			else //raise right weapon
			{
				pspr.y -= sFactor; psprf.y -= sFactor;
				if(pspr.y > 0) {  }
				else
				{
					pspr.y = 0; psprf.y = 0;
					if(lw) { rw.companionpiece = lw; lw.companionpiece = rw; }
					player.SetPSprite(PSP_RIGHTW, rw.GetReadyState());
					invoker.bModeReady = true;
					invoker.weaponStatus = DDW_READY;
					A_ChangeState('Ready');
				}
			}
		}
		
	}
	
	action void A_RaiseSingle()
	{
		let ddp = ddplayer(self);
		if(!ddp.FindInventory("LeftWeapons")) { return; }
		if(!ddp.FindInventory("RightWeapons")) { return; }
		let lWeap = ddp.GetLeftWeapons();
		let rWeap = ddp.GetRightWeapons();
		let lw = ddp.GetLeftWeapon(ddp.lwx);
		let rw = ddp.GetRightWeapon(ddp.rwx);
		let pspl = player.getpsprite(PSP_LEFTW);
		let psplf = player.getpsprite(PSP_LEFTWF);
		let pspr = player.getpsprite(PSP_RIGHTW);
		let psprf = player.getpsprite(PSP_RIGHTWF);
		double sFactor = rw.sFactor;
		if(ddp.ddWeaponState & DDW_RIGHTISTH && pspr.y > 0)
		{			
			pspr.y -= 6 * sFactor; psprf.y -= 6 * sFactor;	
			if(pspr.y < 1) { pspr.y = 0; psprf.y = 0; }
		}
		else
		{
			pspr.y -= 6 * sFactor;
			psprf.y -= 6 * sFactor;
			if(pspr.y > 0) { return; }
			pspr.y = 0; psprf.y = 0;
			pspr.x = 0; psprf.x = 0;
			if(ddp.dddebug & DBG_WEAPONS) { A_Log("mode ready"); }
			invoker.bmodeReady = true;
			ddp.ddWeaponState &= ~DDW_LEFTNOBOBBING;
			ddp.ddWeaponState &= ~DDW_RIGHTNOBOBBING;
			if(lWeap.items.Size()) { player.setpsprite(PSP_LEFTW, lw.GetUpState()); }
			if(rWeap.items.Size()) { player.setpsprite(PSP_RIGHTW, rw.GetReadyState()); }
			ddp.ddWeaponState |= DDW_LEFTREADY;
			invoker.weaponstatus = DDW_READY;
			A_ChangeState("Ready");
		}
	}
	
	action void A_SwitchToDual()
	{
		let ddp = ddPlayer(self);	
		let lWeap = ddp.GetLeftWeapons();
		let rWeap = ddp.GetRightWeapons();
		if(lWeap.items.Size() < 1) { return; }
		if(rWeap.items.Size() < 1) { return; }
		if(ddp.ddWeaponState & DDW_WANNAREPLACE && ddPlayer(self).gethelp) { A_Log("\cgSwap cancelled"); }
		invoker.weaponstatus = DDM_SWAPPING;
		ddp.ddWeaponState &= ~DDW_WANNAREPLACE;
		ddp.ddWeaponState &= ~DDW_REPLACELEFT;
		ddp.ddWeaponState &= ~DDW_REPLACERIGHT;
		let lw = ddp.GetLeftWeapon(ddp.lwx);
		let rw = ddp.GetRightWeapon(ddp.rwx);
		let pspl = player.GetPSprite(PSP_LEFTW);
		let psplf = player.GetPSprite(PSP_LEFTWF);
		let pspr = player.GetPSprite(PSP_RIGHTW);
		let psprf = player.GetPSprite(PSP_RIGHTWF);	
		double bsk = (ddp.FindInventory("PowerBerserk")) ? 2.0 : 1.0;
		//invoker.bModeReady = false;
		double sFactor = ((lw.sFactor + rw.sFactor + 1) / 2.0) * bsk;	
		if(ddp.ddWeaponState & DDW_RIGHTISTH && pspr.y < 128)
		{			
			pspr.y += 6 * sFactor; psprf.y += 6 * sFactor;
			if(pspr.y > 128) { pspr.y = 128; psprf.y = 128; }
		}
		else
		{	
			pspr.x += 2 * sFactor; psprf.x += 2 * sFactor;
			pspl.y -= 6 * sFactor;
			psplf.y -= 6 * sFactor;
			if(pspl.y > 0) { return; }			
			pspl.y = 0; psplf.y = 0;
			pspl.x = -64; psplf.x = -64;			
			if(!(ddp.ddWeaponState & DDW_RIGHTISTH)) { pspr.y = 0; psprf.y = 0; }
			let dwd = ddWeapon(FindInventory("dualWielding"));
			dwd.weaponstatus = DDW_RELOADING;
			dwd.lSwapTarget = invoker.lSwapTarget;
			dwd.rSwapTarget = invoker.rSwapTarget;
			player.pendingweapon = WP_NOCHANGE;
			player.readyweapon = dwd;
			ddp.lastmode = dwd;
			let rw = ddp.GetRightWeapon(ddp.rwx);
			player.setpsprite(PSP_RIGHTW, rw.GetUpState());
			player.SetPSprite(PSP_WEAPON, dwd.GetUpState());
		}
		return;
	}
	
	action void A_LowerSwap()
	{
		let ddp = ddplayer(self);
		let lWeap = ddp.GetLeftWeapon(ddp.lwx);
		let rWeap = ddp.GetRightWeapon(ddp.rwx);
		let lw = ddp.GetLeftWeapons();
		let pspl = player.getpsprite(PSP_LEFTW);
		let psplf = player.getpsprite(PSP_LEFTWF);
		let pspr = player.getpsprite(PSP_RIGHTW);
		let psprf = player.getpsprite(PSP_RIGHTWF);
		pspr.y = 0; psprf.y = 0;
		pspr.x = 0; psprf.x = 0;
		if(ddp.lwx != invoker.lSwapTarget)
		{
			ddp.lwx = invoker.lSwapTarget;
			lWeap = lw.RetItem(ddp.lwx);
			if(lWeap.bTwoHander && !ddp.CheckESOA(2)) { ddp.ddWeaponState |= DDW_LEFTISTH; }
			else { ddp.ddWeaponState &= ~DDW_LEFTISTH; }	
			player.SetPSprite(PSP_LEFTW, lWeap.GetUpState());					
		}
		if(ddp.dddebug & DBG_WEAPONS) { A_Log("mode ready"); }
		invoker.bmodeready = true;  
		player.SetPSprite(PSP_LEFTW, lWeap.FindState('Ready'));
		ddp.ddWeaponState &= ~DDW_LEFTNOBOBBING;
		ddp.ddWeaponState &= ~DDW_RIGHTNOBOBBING;
		invoker.weaponstatus = DDW_READY;
		A_ChangeState("Ready");		
	}
		
	// ## twoHanding States()
	States
	{
		Ready:
			TNT1 A 1 A_WeaponReady(WRF_FULL);
			Loop;
		Select:
		RaiseSingle:
			TNT1 A 1 A_RaiseSingle;
			Loop;
		Deselect:
			TNT1 A 1 A_SwitchToDual;
			Loop;
		Fire:
			TNT1 A 1 A_FireTwoHanded;
			Goto Ready;
		Altfire:
			TNT1 A 1 A_FireTwoHanded;
			Goto Ready;
		Reload:
			TNT1 A 1 A_FireTwoHanded;
			Goto Ready;
		Unload:
			TNT1 A 1 A_Log("Nothing here yet");
			Goto ready;
		Zoom:
			---- A 10 
			{ 
				if(!(ddPlayer(self).ddWeaponState & DDW_WANNAREPLACE))
				{ A_StartSound("misc/chat2", CHAN_BODY, 0, 0.67); ddPlayer(self).ddWeaponState |= DDW_WANNAREPLACE; 
				  A_Log("\ctRight primary\c-: Select Right\n\ctLeft primary\c-: Select Left\n\ctZoom\c-: Cancel"); }
				else { A_StartSound("misc/chat2", CHAN_BODY, 0, 0.67, ATTN_NORM, 0.18);
					ddPlayer(self).ddWeaponState &= ~DDW_WANNAREPLACE; ddPlayer(self).ddWeaponState &= ~DDW_REPLACELEFT; ddPlayer(self).ddWeaponState &= ~DDW_REPLACERIGHT;
					A_Log("\cgSwap cancelled"); 
				}
			}
			Goto Ready;
		User1:
			Goto Ready;
		User2:
			Goto Fire;
		User3:
			Goto Ready;
		User4:
			Goto Ready;
		QuickSwapTH:
			TNT1 A 1 A_QuickSwapTH;
			Loop;
		LowerSwap:
			TNT1 A 1 A_LowerSwap;
			Loop;
	}
}