// #Class inventoryOpener : CustomInventory()
//Fake button to initialize playerInventory
class inventoryOpener : CustomInventory
{
	Default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 1;
		Inventory.UseSound "";
		-INVENTORY.INVBAR;
		-INVENTORY.AUTOACTIVATE;
		+INVENTORY.IGNORESKILL;
		+INVENTORY.QUIET;
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.UNTOSSABLE;
	}
	
	action void A_ToggleInv()
	{
		let ddp = ddPlayer(self);
		let pspr = player.GetPSprite(PSP_RIGHTW);
		let psprf = player.GetPSprite(PSP_RIGHTWF);
		let mode = ddWeapon(player.readyweapon);
		if(!mode.bmodeready) { 
			if(ddp.dddebug & DBG_INVENTORY) { A_Log("Mode not ready"); } return; }
		if(!(ddp.ddWeaponState & DDW_LEFTREADY) || !(ddp.ddWeaponState & DDW_RIGHTREADY)) { 
			if(ddp.dddebug & DBG_INVENTORY) { A_Log("Weapons not ready"); } return; }
		if(mode is "playerInventory") 
		{
			if(playerInventory(mode).lowerL != -1 || playerInventory(mode).lowerR != -1 ) { 
			if(ddp.dddebug & DBG_INVENTORY) { A_Log("Weapons lowering"); } return; }
			ddp.helpme = 0.;
			playerInventory(mode).LeaveInventory();
			ddWeapon gto = ddWeapon(FindInventory(ddp.lastmode.GetClassName()));
			player.PendingWeapon = WP_NOCHANGE;
			player.ReadyWeapon = gto;
			if(ddp.dddebug & DBG_INVENTORY) { A_Log("Returned to "..gto.GetClassName()); }
			player.SetPSprite(PSP_WEAPON, gto.GetUpState());
		}
		else if(mode is "dualWielding" || mode is "twoHanding")
		{
			ddp.ddWeaponState &= ~DDW_WANNAREPLACE;
			ddp.ddWeaponState &= ~DDW_REPLACELEFT;
			ddp.ddWeaponState &= ~DDW_REPLACERIGHT;
			let inv = playerInventory(FindInventory("playerInventory"));
			if(mode is "dualwielding") { dualWielding(mode).dropChoice = -1; dualWielding(mode).dropTimer = -1; }
			inv.lx = inv.li = ddp.lwx;
			inv.rx = inv.ri = ddp.rwx;
			inv.lswaptarget = mode.lswaptarget;
			inv.rswaptarget = mode.rswaptarget;
			inv.sW.nullify();
			if(ddp.gethelp) { ddp.helpme = 120.; }
			ddp.lastmode = mode;
			let invn = ddWeapon(FindInventory("playerInventory"));
			player.PendingWeapon = WP_NOCHANGE;
			player.ReadyWeapon = invn;
			player.SetPSprite(PSP_WEAPON, invn.GetUpState());
			return;
		}
		else {}
	}
	
	// ##inventoryOpener States()
	States
	{
		Spawn:
			TNT1 A -1;
			Stop;
		Use:
			---- A 1 A_ToggleInv;
			Loop;
	}
}

// #Class playerInventory : ddWeapon()
//Used to access and equip ddWeapons. Also a weapon itself.
class playerInventory : ddWeapon
{
	String fIcon;
	int ix, ri, li;
	//extra variables used for loading next/previous items
	int lx, rx, isx;
	int lwxp, rwxp, inxp;
	int selDir;
	int storedIndex, targetIndex, storedSide, targetSide;
	Pocket storedSpot, targetSpot;
	int weapSide; //0 = right, 1 = left;
	int lowerL, lowerR; //1 = yes, 0 = raise, -1 = no;
	ddWeapon heldLeft, heldRight; //stores new weapon for slot if needed
	inventoryWeapon sW, tW; //store info about selected weapon/target weapon
	bool inInventory; // true if selecting inventory slots, false if selecting weapon slots
	Default
	{
		Weapon.AmmoType1 "NotAnAmmo";
		Weapon.AmmoType2 "NotAnAmmo";
		Weapon.AmmoUse1 69;
		Weapon.AmmoUse2 69;
		Weapon.MinSelectionAmmo1 0;
		Weapon.BobRangeX 0;
		Weapon.BobRangeY 0;
		Weapon.BobSpeed 0;
		+DDWEAPON.MODEREADY;
		-DDWEAPON.GOESININV;
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.UNTOSSABLE;
		+WEAPON.NODEATHDESELECT;
		+WEAPON.NODEATHINPUT;
		Tag "";
	}
	
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		ri = 0;
		li = 0;
		ix = 0;
		let pW = inventoryWeapon(Spawn("inventoryWeapon"));
		pW.BecomeItem();
		pW.construct("", 0, "", 0, 0, false);
		sW = pW;
		let pT = inventoryWeapon(Spawn("inventoryWeapon"));
		pT.BecomeItem();
		pT.construct("", 0, "", 0, 0, false);
		tW = pT;
		lowerL = -1;
		lowerR = -1;
		weapSide = 0;
		storedIndex = -2;
		targetIndex = -2;
		inInventory = true;
	}
	
	//todo: move item reassignment to end of lowering state
	override void Tick()
	{
		Super.Tick();		
		let ddp = ddPlayer(owner);
		let pInv = ddp.GetWeaponsInventory();
		let lWeap = ddp.GetLeftWeapons();
		let rWeap = ddp.GetRightWeapons();
		let pspl = ddp.player.GetPSprite(PSP_LEFTW);
		let psplf = ddp.player.GetPSprite(PSP_LEFTWF);
		let pspr = ddp.player.GetPSprite(PSP_RIGHTW);
		let psprf = ddp.player.GetPSprite(PSP_RIGHTWF);
		if(selDir != 0)
		{
			if(inInventory)
			{
				inxp += 5 * selDir;
				if(abs(inxp) >= 35) 
				{
					isx += selDir;
					if(isx < 0) { isx = pInv.items.Size() - 1; }
					if(isx > pInv.items.Size() - 1) { isx = 0; }
					if(isx == ix) { selDir = 0; }
					inxp = 0;
				}
			}
			else
			{
				if(weapside)
				{
					lwxp += 5 * selDir;
					if(abs(lwxp) >= 35) 
					{
						lx += selDir;
						if(lx < 0) { lx = lWeap.items.size() - 1; }
						if(lx > lWeap.items.size() - 1) { lx = 0; }
						if(lx == li)  { selDir = 0; }
						lwxp = 0;
					}
				}
				else
				{
					rwxp += 5 * selDir;
					if(abs(rwxp) >= 35) 
					{
						rx += selDir;
						if(rx < 0) { rx = rWeap.items.size() - 1; }
						if(rx > rWeap.items.size() - 1) { rx = 0; }
						if(rx == ri)  { selDir = 0; }
						rwxp = 0;
					}
				}
			}
		}
		if(ddp)
		{
			if(ddp.player.readyweapon is "playerInventory")
			{				
				if(!(ddp.ddWeaponState & DDW_LEFTREADY) || !(ddp.ddWeaponState & DDW_RIGHTREADY)) { ddp.A_Log("Weapons not ready"); return; }
				if(ddp.lastmode is "dualWielding")
				{
					if(lowerL == 1)
					{
						ddWeapon hole = heldleft;
						pspl.y += 6 * hole.sFactor;
						if(pspl.y > 127)
						{							
							if(ddp.dddebug & DBG_INVENTORY) { ddp.A_Log("Left weapon replaced with held weapon "..heldleft.GetTag()); }
							if(lWeap.RetItem(ddp.lwx).bTwoHander) { ddp.ddWeaponState |= DDW_LEFTISTH; }
							else { ddp.ddWeaponState &= ~DDW_LEFTISTH; }
							rWeap.RetItem(ddp.rwx).companionpiece = lWeap.RetItem(ddp.lwx);
							lWeap.RetItem(ddp.lwx).companionpiece = rWeap.RetItem(ddp.rwx);	
							pspl.SetState(ddp.GetLeftWeapon(ddp.lwx).GetUpState());
							if(!(hole is "ddFist")) {
							if(ddp.dddebug & DBG_INVENTORY && ddp.dddebug & DBG_VERBOSE) { A_Log("Previous left weapon "..hole.GetTag().." removed"); } 
							ddp.RemoveInventory(hole);	}					
							pspl.x = -64 - ddp.GetLeftWeapon(ddp.lwx).xoffset;		
							psplf.x = -64 - ddp.GetLeftWeapon(ddp.lwx).xoffset;
							if(lWeap.RetItem(ddp.rwx).UpSound) { ddp.A_StartSound(lWeap.RetItem(ddp.rwx).UpSound, CHAN_WEAPON); }
							ddp.ddWeaponState &= ~DDW_NOLEFTSPRITECHANGE;
							lowerL = 0;
						}
					}
					else if(lowerL == 0) 
					{
						pspl.y -= 6 * ddp.GetLeftWeapon(ddp.lwx).sFactor;
						if(pspl.y < 1)
						{
							pspl.y = 0;
							lowerL = -1;
							ddp.ddWeaponState &= ~DDW_LEFTNOBOBBING;
							pspl.SetState(ddp.GetLeftWeapon(ddp.lwx).GetReadyState());
						}
					}
					else {}
				}
				else
				{
					if(lowerL == 1)
					{
						ddWeapon hole = heldleft;
						if(lWeap.RetItem(ddp.lwx).bTwoHander) { ddp.ddWeaponState |= DDW_LEFTISTH; }
						else { ddp.ddWeaponState &= ~DDW_LEFTISTH; }
						if(!(hole is "ddFist")) { ddp.RemoveInventory(hole); }
						rWeap.RetItem(ddp.rwx).companionpiece = lWeap.RetItem(ddp.lwx);
						lWeap.RetItem(ddp.lwx).companionpiece = rWeap.RetItem(ddp.rwx);	
						ddp.ddWeaponState &= ~DDW_LEFTNOBOBBING;
						ddp.ddWeaponState &= ~DDW_NOLEFTSPRITECHANGE;
						ddp.player.SetPSprite(PSP_LEFTW, ddp.GetLeftWeapon(ddp.lwx).FindState('Ready'));
						lowerL = -1;
					}					
				}
				
				if(lowerR == 1)
				{
					ddWeapon hole = heldRight;
					pspr.y += 6 * hole.sFactor;
					if(pspr.y > 127)
					{
						if(ddp.dddebug & DBG_INVENTORY) { ddp.A_Log("Right weapon replaced with held weapon "..heldright.GetTag()); }
						if(rWeap.RetItem(ddp.rwx).bTwoHander) { ddp.ddWeaponState |= DDW_RIGHTISTH; }
						else { ddp.ddWeaponState &= ~DDW_RIGHTISTH; }
						rWeap.RetItem(ddp.rwx).companionpiece = lWeap.RetItem(ddp.lwx);
						lWeap.RetItem(ddp.lwx).companionpiece = rWeap.RetItem(ddp.rwx);
						ddp.player.SetPSprite(PSP_RIGHTW, ddp.GetRightWeapon(ddp.rwx).GetUpState());
						if(!(hole is "ddFist")) {
						if(ddp.dddebug & DBG_INVENTORY && ddp.dddebug & DBG_VERBOSE) { A_Log("Previous right weapon "..hole.GetTag().." removed"); } 
						ddp.RemoveInventory(hole); }
						if(ddp.lastmode is "dualWielding")
						{
							pspr.x = 64 + rWeap.RetItem(ddp.rwx).xoffset;
							psprf.x = 64 + rWeap.RetItem(ddp.rwx).xoffset;
						}
						if(rWeap.RetItem(ddp.rwx).UpSound) { ddp.A_StartSound(rWeap.RetItem(ddp.rwx).UpSound, CHAN_WEAPON); }
						ddp.ddWeaponState &= ~DDW_NORIGHTSPRITECHANGE;
						lowerR = 0;
					}
				}
				else if(lowerR == 0) 
				{
					pspr.y -= 6 * ddp.GetRightWeapon(ddp.rwx).sFactor;
					if(pspr.y < 1)
					{
						pspr.y = 0;
						lowerR = -1;
						ddp.ddWeaponState &= ~DDW_RIGHTNOBOBBING;
						ddp.player.SetPSprite(PSP_RIGHTW, ddp.GetRightWeapon(ddp.rwx).GetReadyState());
					}
				}
				else {}
			}
		}
	}
	
	override ddWeapon CreateTossable()
	{
		let ddp = ddPlayer(owner);
		let lWeap = ddp.GetLeftWeapons();
		let rWeap = ddp.GetRightWeapons();
		let pInv = ddp.GetWeaponsInventory();
		if(inInventory)
		{
			if(pInv.RetItem(ix).weaponName != "emptie")
			{
				let drp = ddWeapon(Spawn(pInv.RetItem(ix).weaponName));
				drp.mag = pInv.RetItem(ix).mag;
				drp.ddWeaponFlags = pInv.RetItem(ix).ddWeaponFlags;
				drp.AmmoGive1 = 0;
				drp.AttachToOwner(owner);
				pInv.RetItem(ix).emptify();
				if(ddp.dddebug & DBG_INVENTORY) { ddp.A_Log(""..drp.GetTag().." dropped"); }
				return ddWeapon(drp.CreateTossable());
			}
			else
			{
				ddp.A_StartSound("misc/boowomp", CHAN_WEAPON);
				return null;
			}
		}
		else
		{
			if(weapSide)
			{
				if(!(lWeap.RetItem(li) is "ddFist"))
				{					
					let lw = lWeap.RetItem(li);
					let drp = ddWeapon(Spawn(lw.GetParentType()));
					drp.mag = lw.mag;
					drp.ddWeaponFlags = lw.ddWeaponFlags;
					drp.AmmoGive1 = 0;
					drp.AttachToOwner(owner);
					if(ddp.dddebug & DBG_INVENTORY && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("Left weapon replaced with "..ddp.GetFists().GetTag()); }
					lWeap.SetItem(ddWeapon(ddp.GetFists(1)), li);
					ddp.ddWeaponState &= ~DDW_LEFTISTH;
					if(li == ddp.lwx)
					{
						rWeap.RetItem(ddp.rwx).companionpiece = lWeap.RetItem(ddp.lwx);
						lWeap.RetItem(ddp.lwx).companionpiece = rWeap.RetItem(ddp.rwx);
					}
					ddp.player.SetPSprite(PSP_LEFTW, lWeap.RetItem(li).FindState('Ready'));
					if(ddp.dddebug & DBG_INVENTORY) { ddp.A_Log(""..lw.GetTag().." removed from inventory"); }
					ddp.RemoveInventory(lw);
					return ddWeapon(drp.CreateTossable());
				}
				else
				{
					ddp.A_StartSound("misc/boowomp", CHAN_WEAPON);
					return null;						
				}
			}
			else
			{
				if(!(rWeap.RetItem(ri) is "ddFist"))
				{					
					let rw = rWeap.RetItem(ri);
					let drp = ddWeapon(Spawn(rw.GetParentType()));
					drp.mag = rw.mag;
					drp.ddWeaponFlags = rw.ddWeaponFlags;
					drp.AmmoGive1 = 0;
					drp.AttachToOwner(owner);
					if(ddp.dddebug & DBG_INVENTORY && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("Right weapon replaced with "..ddp.GetFists().GetTag()); }
					rWeap.SetItem(ddWeapon(ddp.GetFists(0)), ri);
					ddp.ddWeaponState &= ~DDW_RIGHTISTH;
					if(ri == ddp.rwx)
					{
						rWeap.RetItem(ddp.rwx).companionpiece = lWeap.RetItem(ddp.lwx);
						lWeap.RetItem(ddp.lwx).companionpiece = rWeap.RetItem(ddp.rwx);
					}
					ddp.player.SetPSprite(PSP_RIGHTW, rWeap.RetItem(ri).FindState('Ready'));
					if(ddp.dddebug & DBG_INVENTORY) { ddp.A_Log(""..rw.GetTag().." removed from inventory"); }
					ddp.RemoveInventory(rw);
					return ddWeapon(drp.CreateTossable());
				}
				else
				{
					ddp.A_StartSound("misc/boowomp", CHAN_WEAPON);
					return null;						
				}
			}
		}
	}
	
	override void PreTravelled()
	{
		let ddp = ddPlayer(owner);
		if(lowerL == 1) 
		{ 
			if(!(heldLeft is "ddFist")) { ddp.RemoveInventory(heldLeft); }
			ddp.player.SetPSprite(PSP_LEFTW, ddp.GetLeftWeapon(ddp.lwx).GetUpState());
			ddp.ddWeaponState &= ~DDW_NOLEFTSPRITECHANGE;
			lowerL = 0;
		}
		if(lowerR == 1)
		{
			if(!(heldRight is "ddFist")) { ddp.RemoveInventory(heldRight); }
			ddp.player.SetPSprite(PSP_RIGHTW, ddp.GetRightWeapon(ddp.rwx).GetUpState());
			ddp.ddWeaponState &= ~DDW_NORIGHTSPRITECHANGE;
			lowerR = 0;
		}
		ddp.GetRightWeapon(ddp.rwx).companionpiece = ddp.GetLeftWeapon(ddp.lwx);
		ddp.GetLeftWeapon(ddp.lwx).companionpiece = ddp.GetRightWeapon(ddp.rwx);
		if(ddp.GetLeftWeapon(ddp.lwx).bTwoHander) { ddp.ddWeaponState |= DDW_LEFTISTH; }
		else { ddp.ddWeaponState &= ~DDW_RIGHTISTH; }
		if(ddp.GetRightWeapon(ddp.rwx).bTwoHander) { ddp.ddWeaponState |= DDW_RIGHTISTH; }
		else { ddp.ddWeaponState &= ~DDW_RIGHTISTH; }
	}
	
	override void Travelled()
	{
		let pW = inventoryWeapon(Spawn("inventoryWeapon"));
		pW.BecomeItem();
		pW.construct("", 0, "", 0, 0, false);
		sW = pW;
		let pT = inventoryWeapon(Spawn("inventoryWeapon"));
		pT.BecomeItem();
		pT.construct("", 0, "", 0, 0, false);
		tW = pT;		
	}
	
	override void HUDA(ddStats hude)
	{
		let ddp = ddPlayer(owner);
		int fi = ddp.fwx;
		//temp ints
		int it, lt, rt;
		let lWeap = ddp.GetLeftWeapons();
		let rWeap = ddp.GetRightWeapons();
		let pInv = ddp.GetWeaponsInventory();
		let flst = ddp.GetFistList();
		let lw = lWeap.RetItem(lx);
		let rw = rWeap.RetItem(rx);
		let pi = pInv.RetItem(isx);
		let fx = ddFist(flst.RetItem(fi));		
		int lwd, lhg, rwd, rhg, pwd, phg;
		[lwd, lhg] = TexMan.GetSize(TexMan.CheckForTexture(lw.GetWeaponSprite()));
		[rwd, rhg] = TexMan.GetSize(TexMan.CheckForTexture(rw.GetWeaponSprite()));
		[pwd, phg] = TexMan.GetSize(TexMan.CheckForTexture(pi.weaponSprite));
		int haz, sel, tar;
		if(hude.oscilator & 32) { 
			sel = Font.CR_WHITE; tar = Font.CR_GREEN; haz = Font.CR_YELLOW;
		} 
		else { 
			sel = Font.CR_BLACK; tar = Font.CR_ICE; haz = Font.CR_RED;
		}
		//draw fist icons
		if(flst.items.Size() > 1)
		{			
			if(++fi > flst.items.Size() - 1) { fi = 0; }
			let fi2 = ddFist(flst.RetItem(fi));
			fi = ddp.fwx;
			if(--fi < 0) { fi = flst.items.Size() - 1; }
			let fi3 = ddFist(flst.RetItem(fi));	
			hude.DrawImage(fi2.GetIconSprite(), (15, -55), hude.DI_SCREEN_CENTER, 0.3);
			hude.DrawImage(fi3.GetIconSprite(), (-15, -55), hude.DI_SCREEN_CENTER, 0.3);		
		}
		hude.DrawImage(fx.GetIconSprite(), (0, -55), hude.DI_SCREEN_CENTER, 0.85);			
		//draw pInv	
		if(1)
		{
			it = isx;
			if(++it > pInv.items.Size() - 1) { it = 0; }
			let pi2 = pInv.RetItem(it);
			it = isx;
			if(--it < 0) { it = pInv.items.Size() - 1; }
			let pi3 = pInv.RetItem(it);	
			hude.DrawImage(pi2.weaponsprite, (35-inxp, 35), hude.DI_SCREEN_CENTER, (inInventory) ? 0.25 : 0.1);
			hude.DrawImage(pi3.weaponsprite, (-35-inxp, 35), hude.DI_SCREEN_CENTER, (inInventory) ? 0.25 : 0.1);		
			hude.DrawImage(pi.weaponsprite, (0-inxp, 35), hude.DI_SCREEN_CENTER, (inInventory) ? 0.75 : 0.33);			
			hude.DrawString(hude.fa, ""..hude.FormatNumber(pInv.GetInventoryCount()).."/"..hude.FormatNumber(pInv.size), (-30, 45), hude.DI_SCREEN_CENTER, 0, 0.75);
			Color icolor = ((inInventory) ? sel : Font.CR_DARKGRAY);
			if(ix == storedIndex && storedSide == -1) { iColor = tar; pwd += 11; }
			hude.DrawString(hude.fa, "[", (-5 - (pwd / 2), 25), hude.DI_SCREEN_CENTER, iColor, (inInventory) ? 0.85 : 0.3);
			hude.DrawString(hude.fa, "]", (0 + (pwd / 2), 25), hude.DI_SCREEN_CENTER, iColor, (inInventory) ? 0.85 : 0.3);
		}
		//draw lWeap
		if(1)
		{
			if(lWeap.items.Size() > 1)
			{
				lt = lx;
				if(++lt > lWeap.items.Size() - 1) { lt = 0; }
				ddWeapon lw2 = lWeap.RetItem(lt);
				lt = lx;
				if(--lt < 0) { lt = lWeap.items.Size() - 1; }
				ddWeapon lw3 = lWeap.RetItem(lt);
				hude.DrawImage(lw2.GetWeaponSprite(), (-45-lwxp,-20), hude.DI_SCREEN_CENTER, (!inInventory) ? 0.25 : 0.1);
				hude.DrawImage(lw3.GetWeaponSprite(), (-105-lwxp,-20), hude.DI_SCREEN_CENTER, (!inInventory) ? 0.25 : 0.1);
			}
			Color lcolor = (lWeap.RetItem(li).bTwoHander) ? haz : ((!inInventory && weapside) ? sel : ((weapside) ? Font.CR_TAN : Font.CR_DARKGRAY));
			if(li == storedIndex && storedSide == 1) { lColor = tar; lwd += 9; }
			hude.DrawString(hude.fa, "[", (-80 - (lwd / 2), -30), hude.DI_SCREEN_CENTER, lColor, (!inInventory) ? 0.85 : 0.3);
			hude.DrawString(hude.fa, "]", (-75 + (lwd / 2), -30), hude.DI_SCREEN_CENTER, lColor, (!inInventory) ? 0.85 : 0.3);
			hude.DrawImage(lw.GetWeaponSprite(), (-75-lwxp,-20), hude.DI_SCREEN_CENTER, (!inInventory) ? 0.75 : 0.3);
		}
		//draw rWeap
		if(1)
		{
			if(rWeap.items.Size() > 1)
			{
				rt = rx;
				if(++rt > rWeap.items.Size() - 1) { rt = 0; }
				ddWeapon rw2 = rWeap.RetItem(rt);
				rt = rx;
				if(--rt < 0) { rt = rWeap.items.Size() - 1; }
				ddWeapon rw3 = rWeap.RetItem(rt);
				hude.DrawImage(rw2.GetWeaponSprite(), (105-rwxp,-20), hude.DI_SCREEN_CENTER, (!inInventory) ? 0.25 : 0.1);
				hude.DrawImage(rw3.GetWeaponSprite(), (45-rwxp,-20), hude.DI_SCREEN_CENTER, (!inInventory) ? 0.25 : 0.1);
			}
			
			Color rColor = (rWeap.RetItem(ri).bTwoHander) ? haz : ((!inInventory && !weapside) ? sel : ((!weapside) ? Font.CR_TAN : Font.CR_DARKGRAY));
			if(ri == storedIndex && storedSide == 0) { rColor = tar; rwd += 9; }
			hude.DrawString(hude.fa, "[", (70 - (rwd / 2), -30), hude.DI_SCREEN_CENTER, rColor, (!inInventory) ? 0.85 : 0.3);
			hude.DrawString(hude.fa, "]", (75 + (rwd / 2), -30), hude.DI_SCREEN_CENTER, rColor, (!inInventory) ? 0.85 : 0.3);
			hude.DrawImage(rw.GetWeaponSprite(), (75-rwxp,-20), hude.DI_SCREEN_CENTER, (!inInventory) ? 0.75 : 0.3);
		}
		//draw selWeap info
		int pos;
		if(inInventory) { if(ddp is "ddPlayerNormal") {
			pos = ix;
			if(!(ddp.dddebug & DBG_INVENTORY)) { pos++; }
			hude.DrawString(hude.fa, "I"..hude.FormatNumber(pos)..": ", (12, 45), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
			pInv.RetItem(ix).GetInventoryInfo(hude); 
			if(ddp.dddebug & DBG_INVENTORY) 
			{
				int iwfs;
				String iwfs2;
				iwfs = pi.ddweaponflags;
				while(iwfs > 0) { iwfs2 = (iwfs % 2)..iwfs2; iwfs >>= 1; }	
				hude.DrawString(hude.fa, iwfs2, (-50, 60), hude.DI_SCREEN_CENTER);
			}
			} 
		}
		else { if(ddp is "ddPlayerNormal") { 
				if(weapside) { 
					pos = li;
					if(!(ddp.dddebug & DBG_INVENTORY)) { pos++; }
					hude.DrawString(hude.fa, "L"..hude.FormatNumber(pos)..": ", (12, 45), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
					lWeap.RetItem(li).InventoryInfo(hude); 
					if(ddp.dddebug & DBG_INVENTORY) 
					{
						int lwfs;
						String lwfs2;
						lwfs = lw.ddweaponflags;
						while(lwfs > 0) { lwfs2 = (lwfs % 2)..lwfs2; lwfs >>= 1; }	
						hude.DrawString(hude.fa, lwfs2, (-50, 60), hude.DI_SCREEN_CENTER);
					}
				} 
				else { 
					pos = ri;
					if(!(ddp.dddebug & DBG_INVENTORY)) { pos++; }
					hude.DrawString(hude.fa, "R"..hude.FormatNumber(pos)..": ", (12, 45), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
					rWeap.RetItem(ri).InventoryInfo(hude); 
					if(ddp.dddebug & DBG_INVENTORY) 
					{
						int rwfs;
						String rwfs2;
						rwfs = rw.ddweaponflags;
						while(rwfs > 0) { rwfs2 = (rwfs % 2)..rwfs2; rwfs >>= 1; }	
						hude.DrawString(hude.fa, rwfs2, (-50, 60), hude.DI_SCREEN_CENTER);
					}
				} 
			}				
		}			
		double helpt = (ddp.helpme/20.);
		if(ddp.GetHelp)
		{
			hude.DrawString(hude.fa, "\ctQuickswap Left"..":".."\ck Select left", (0, -190), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_CENTER, 0, helpt);
			hude.DrawString(hude.fa, "\ctQuickswap Right"..":".."\ck Select right", (0, -180), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_CENTER, Font.CR_RED, helpt);
			hude.DrawString(hude.fa, "\ctLeft Alternative"..":".."\ck Select weapon", (0, -170), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_CENTER, Font.CR_RED, helpt);
			hude.DrawString(hude.fa, "\ctLeft Primary"..":".."\ck Switch to "..((inInventory) ? "inventory" : "weapons"), (0, -160), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_CENTER, Font.CR_RED, helpt);
			hude.DrawString(hude.fa, "\ctReload"..":".."\ck Switch weapon side", (0, -150), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_CENTER, Font.CR_RED, helpt);
			hude.DrawString(hude.fa, "\ctRight Primary"..":".."\ck Fist select right", (0, -140), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_CENTER, Font.CR_RED, helpt);
			hude.DrawString(hude.fa, "\ctRight alternative"..":".."\ck Fist select left", (0, -130), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_CENTER, Font.CR_RED, helpt);
			hude.DrawString(hude.fa, "\ctZoom"..":".."\ck Sort inventory", (0, -120), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_CENTER, Font.CR_RED, helpt);
		}	
		
		//draw ammo
		hude.DrawString(hude.fa, "Ammo", (0,0), hude.DI_SCREEN_RIGHT_CENTER | hude.DI_TEXT_ALIGN_RIGHT);
		hude.DrawImage("PCLPA0", (-25, 20), hude.DI_SCREEN_RIGHT_CENTER);
		hude.DrawString(hude.fa, ""..ddp.CountInv("d9Mil"), (-25, 20), hude.DI_SCREEN_RIGHT_CENTER);
		hude.DrawImage("CLIPA0", (-25, 38), hude.DI_SCREEN_RIGHT_CENTER);
		hude.DrawString(hude.fa, ""..ddp.CountInv("Clip"), (-25, 38), hude.DI_SCREEN_RIGHT_CENTER);
		hude.DrawImage("SHELA0", (-25, 56), hude.DI_SCREEN_RIGHT_CENTER);
		hude.DrawString(hude.fa, ""..ddp.CountInv("Shell"), (-25, 56), hude.DI_SCREEN_RIGHT_CENTER);
		hude.DrawImage("BFSSA0", (-25, 72), hude.DI_SCREEN_RIGHT_CENTER);
		hude.DrawString(hude.fa, ""..ddp.CountInv("BFS"), (-25, 72), hude.DI_SCREEN_RIGHT_CENTER);
		hude.DrawImage("ROCKA0", (-25, 106), hude.DI_SCREEN_RIGHT_CENTER);
		hude.DrawString(hude.fa, ""..ddp.CountInv("RocketAmmo"), (-25, 106), hude.DI_SCREEN_RIGHT_CENTER);
		hude.DrawImage("CELLA0", (-25, 130), hude.DI_SCREEN_RIGHT_CENTER);
		hude.DrawString(hude.fa, ""..ddp.CountInv("Cell"), (-25, 130), hude.DI_SCREEN_RIGHT_CENTER);
		
		if(ddp.dddebug & DBG_INVENTORY)
		{			
			hude.DrawString(hude.bf, ".", (-75, -50), hude.DI_SCREEN_CENTER, (lWeap.RetItem(ddp.lwx).weaponready) ? Font.CR_GREEN : Font.CR_RED);
			hude.DrawString(hude.bf, ".", (0, -15), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, (bModeReady) ? Font.CR_GREEN : Font.CR_RED);
			hude.DrawString(hude.bf, ".", (75, -50), hude.DI_SCREEN_CENTER, (rWeap.RetItem(ddp.rwx).weaponready) ? Font.CR_GREEN : Font.CR_RED);
		}
	}
	
	action void EnterInventory()
	{
		let ddp = ddPlayer(self);
		let pspr = player.GetPSprite(PSP_RIGHTW);
		let psprf = player.GetPSprite(PSP_RIGHTWF);		
		if(ddp.dddebug & DBG_INVENTORY) 
		{ 
			ddp.ReportInventory();
		}
	}
	
	//reset values when returing to fire modes
	void LeaveInventory()
	{
		ix = 0;
		li = 0;
		ri = 0;
		lx = 0;
		rx = 0;
		isx = 0;
		selDir = 0;
		if(sW.weaponName != "") { owner.A_StartSound("misc/chat2", CHAN_WEAPON, 0, 1.0, ATTN_NORM, 0.18); }
		sW.nullify();
		tW.nullify();
		storedIndex = -2;
		storedSide = -2;
		storedSpot = null;
		targetIndex = -2;
		targetSide = -2;
		targetSpot = null;
		inInventory = true;
		if(ddPlayer(owner).dddebug & DBG_INVENTORY) { owner.A_Log("Inventory members cleared"); }
	}
	
	action void A_FistCycle()
	{
		ddPlayer ddp = ddPlayer(self);
		let lWeap = ddp.GetLeftWeapons();
		let rWeap = ddp.GetRightWeapons();
		let flst = ddp.GetFistList();
		if(!invoker.bAltFire) { if(++ddp.fwx > flst.items.Size() - 1) { ddp.fwx = 0; } }
		else { if(--ddp.fwx < 0) { ddp.fwx = flst.items.Size() -1; } }
		
		A_StartSound("misc/chat2", CHAN_WEAPON, 0, 0.67);
		//replaces fisted slots with new fists
		for(int z = 0; z < (lWeap.size + rWeap.size); z++)
		{
			if(z < lWeap.size) { if(lWeap.RetItem(z) is "ddFist") 
			{ lWeap.SetItem(ddWeapon(ddp.GetFists(1)), z); } }
			else { if(rWeap.RetItem(z - lWeap.size) is "ddFist") 
			{ rWeap.SetItem(ddWeapon(ddp.GetFists(0)), z - lWeap.size); } }
		}
		rWeap.RetItem(ddp.rwx).companionpiece = lWeap.RetItem(ddp.lwx);
		lWeap.RetItem(ddp.lwx).companionpiece = rWeap.RetItem(ddp.rwx);
	}
	
	action void A_ChangeSide()
	{
		if(!invoker.inInventory) 
		{
			A_StartSound("misc/chat2", CHAN_WEAPON, 0, 0.67); 
			invoker.weapSide = !invoker.weapSide; 
		}
	}
	
	action void A_ChangeInventory()
	{
		A_StartSound("misc/chat2", CHAN_WEAPON, 0, 0.67);
		invoker.inInventory = !invoker.inInventory;
	}
	
	action void A_InvSelect()
	{
		let ddp = ddPlayer(self);
		let lWeap = ddp.GetLeftWeapons();
		let rWeap = ddp.GetRightWeapons();
		let pInv = ddp.GetWeaponsInventory();
		let i = invoker;
		let pspl = ddp.player.GetPSprite(PSP_LEFTW);
		let pspr = ddp.player.GetPSprite(PSP_RIGHTW);
		if(i.sW.weaponName == "")
		{
			let weap = (i.inInventory) ? Inventory(pInv.RetItem(i.ix)) : ((i.weapside) ? Inventory(lWeap.RetItem(i.li)) : Inventory(rWeap.RetItem(i.ri)));
			i.storedIndex = (i.inInventory) ? i.ix : ((i.weapside) ? i.li : i.ri);
			i.storedSide = (i.inInventory) ? -1 : ((i.weapside) ? 1 : 0); 
			i.storedSpot = (i.inInventory) ? Pocket(pInv) : ((i.weapside) ? Pocket(lWeap) : Pocket(rWeap));
			if(weap is "ddWeapon") { 
				let sel = ddWeapon(weap);
				String nam = (sel is "ddFist") ? "emptie" : sel.GetParentType();
				i.sW.construct(nam, sel.rating, sel.GetWeaponSprite(), sel.mag, sel.ddWeaponFlags, false);
			}
			else { 
				let sel = inventoryWeapon(weap);
				i.sW.construct(sel.weaponName, sel.rating, sel.weaponSprite, sel.mag, sel.ddWeaponFlags, false); 
			}
			if(ddp.dddebug & DBG_INVENTORY) {
				A_Log("Weapon "..i.sW.weaponname.." selected from "..((i.storedSide == -1) ? "inventory slot " : ((i.storedside) ? "right slot " : "left slot "))..
				i.StoredIndex);
			}
			A_StartSound("misc/chat2", CHAN_WEAPON, 0, 1.0, ATTN_NORM, 0.5);
		}
		else
		{
			let weap2 = (i.inInventory) ? Inventory(pInv.RetItem(i.ix)) : ((i.weapside) ? Inventory(lWeap.RetItem(i.li)) : Inventory(rWeap.RetItem(i.ri)));
			i.targetIndex = (i.inInventory) ? i.ix : ((i.weapside) ? i.li : i.ri);
			i.targetSide = (i.inInventory) ? -1 : ((i.weapside) ? 1 : 0);
			i.targetSpot = (i.inInventory) ? Pocket(pInv) : ((i.weapside) ? Pocket(lWeap) : Pocket(rWeap));
			if(weap2 is "ddWeapon") { 
				let sel = ddWeapon(weap2);
				String nam = (sel is "ddFist") ? "emptie" : sel.GetParentType();
				i.tW.construct(nam, sel.rating, sel.GetWeaponSprite(), sel.mag, sel.ddWeaponFlags, false);
			}
			else { 
				let sel = inventoryWeapon(weap2);
				i.tW.construct(sel.weaponName, sel.rating, sel.weaponSprite, sel.mag, sel.ddWeaponFlags, false); 
			}
			
			if(i.storedSpot is "weaponsInventory")
			{
				let sts = weaponsInventory(i.storedSpot);
				sts.RetItem(i.storedIndex).construct(i.tW.weaponname, i.tW.rating, i.tW.weaponsprite, i.tW.mag, i.tW.ddWeaponFlags);
				if(ddp.dddebug & DBG_INVENTORY) {
					A_Log("Weapon \cq"..i.tW.weaponname.."\c- placed in inventory slot "..i.StoredIndex..", replacing \ci"..i.sW.weaponname);
				}
			}
			else
			{
				String new = (i.tW.weaponName == "emptie") ? ddp.GetFists().GetClassName() : i.tW.weaponName;
				new = (i.storedside) ? new.."left" : new.."right";
				let newWeap = ddWeapon(Spawn(new));
				newWeap.ddWeaponFlags = i.tW.ddWeaponFlags;
				newWeap.mag = i.tW.mag;
				newWeap.AmmoGive1 = 0;
				newWeap.AmmoGive2 = 0;
				newWeap.AttachToOwner(self);
				if((newWeap.btwoHander && i.storedside) && ddp.gethelp) { ddp.A_Log("You can't use a twohanded weapon in your left hand!"); }
				switch(i.storedSide)
				{
					case 0: //right
						let rss = RightWeapons(i.storedSpot);
						if(i.storedIndex == ddp.rwx) {
							ddp.ddWeaponState |= DDW_NORIGHTSPRITECHANGE;
							i.lowerR = 1; i.heldRight = rss.RetItem(i.storedIndex);  pspr.SetState(i.heldRight.GetUpState()); rss.Setitem(newWeap, i.storedIndex); ddp.ddWeaponState |= DDW_RIGHTNOBOBBING;
						}
						else { if(i.sW.weaponName != "emptie") { RemoveInventory(i.storedSpot.RetItem(i.storedIndex)); } rss.SetItem(newWeap, i.storedIndex);
						}
						if(ddp.dddebug & DBG_INVENTORY) {
							A_Log("Weapon \cq"..i.tW.weaponname.."\c- placed in right weapon slot "..i.TargetIndex..", replacing \ci"..i.sW.weaponname);
						}
						break;
					case 1: //left
						let lss = LeftWeapons(i.storedSpot);
						if(i.storedIndex == ddp.lwx) {
							ddp.ddWeaponState |= DDW_NOLEFTSPRITECHANGE;
							i.lowerL = 1; i.heldLeft = lss.RetItem(i.storedIndex); pspl.SetState(i.heldLeft.GetUpState()); ddp.ddWeaponState |= DDW_LEFTNOBOBBING; lss.SetItem(newWeap, i.storedIndex);
						}
						else { if(i.sW.weaponName != "emptie") { RemoveInventory(i.storedSpot.RetItem(i.storedIndex)); }  lss.SetItem(newWeap, i.storedIndex);
						}
						if(ddp.dddebug & DBG_INVENTORY) {
							A_Log("Weapon \cq"..i.tW.weaponname.."\c- placed in left weapon slot "..i.TargetIndex..", replacing \ci"..i.sW.weaponname);
						}
						break;
					default: break;
				}			
			}
			
			if(i.targetSpot is "weaponsInventory")
			{
				let tgs = weaponsInventory(i.targetSpot);
				tgs.RetItem(i.targetIndex).construct(i.sW.weaponname, i.sW.rating, i.sW.weaponsprite, i.sW.mag, i.sW.ddWeaponFlags);
				if(ddp.dddebug & DBG_INVENTORY) {
					A_Log("Weapon \ci"..i.sW.weaponname.."\c- placed in inventory slot "..i.TargetIndex..", replacing \cq"..i.tW.weaponname);
				}
			}
			else
			{
				String old = (i.sW.weaponName == "emptie") ? ddp.GetFists().GetClassName() : i.sW.weaponName;
				old = (i.weapside) ? old.."left" : old.."right";
				let oldWeap = ddWeapon(Spawn(old));
				oldWeap.ddWeaponFlags = i.sW.ddWeaponFlags;
				oldWeap.mag = i.sW.mag;
				oldWeap.AmmoGive1 = 0;
				oldWeap.AmmoGive2 = 0;
				oldWeap.AttachToOwner(self);
				if((oldWeap.btwoHander && i.targetside) && ddp.gethelp) { ddp.A_Log("You can't use a twohanded weapon in your left hand!"); }
				switch(i.targetSide)
				{
					case 0: //right
						let rts = RightWeapons(i.targetSpot);
						if(i.targetIndex == ddp.rwx) {
							ddp.ddWeaponState |= DDW_NORIGHTSPRITECHANGE;
							i.lowerR = 1; i.heldRight = rts.RetItem(i.targetIndex); pspr.SetState(i.heldRight.GetUpState()); ddp.ddWeaponState |= DDW_RIGHTNOBOBBING; rts.SetItem(oldWeap, i.targetindex);
						}
						else { if(i.tW.weaponName != "emptie") { RemoveInventory(i.targetSpot.RetItem(i.targetIndex));} rts.SetItem(oldWeap, i.targetIndex); 
						}
						if(ddp.dddebug & DBG_INVENTORY) {
							A_Log("Weapon \ci"..i.sW.weaponname.."\c- placed in right weapon slot "..i.TargetIndex..", replacing \cq"..i.tW.weaponname);
						}
						break;
					case 1: //left
						let lts = LeftWeapons(i.targetSpot);
						if(i.targetIndex == ddp.lwx) {
							ddp.ddWeaponState |= DDW_NOLEFTSPRITECHANGE;
							i.lowerL = 1; i.heldLeft = lts.RetItem(i.targetIndex); pspl.SetState(i.heldLeft.GetUpState()); ddp.ddWeaponState |= DDW_LEFTNOBOBBING; lts.SetItem(oldWeap, i.targetIndex);
						}
						else { if(i.tW.weaponName != "emptie") { RemoveInventory(i.targetSpot.RetItem(i.targetIndex)); } lts.SetItem(oldWeap, i.targetIndex);
						}
						if(ddp.dddebug & DBG_INVENTORY) {
							A_Log("Weapon \ci"..i.sW.weaponname.."\c- placed in left weapon slot "..i.TargetIndex..", replacing \cq"..i.tW.weaponname);
						}
						break;
					default: break;
				}			
			}
			ddp.A_StartSound("misc/w_pkup", CHAN_WEAPON, CHANF_OVERLAP);
			i.storedIndex = -2;
			i.storedSide = -2;
			i.storedSpot = null;
			i.sW.nullify();
			i.targetIndex = -2;
			i.targetSide = -2;
			i.targetSpot = null;
			i.tW.nullify();
			return;
		}
	}
	
	action void A_InvLeft()
	{
		let ddp = ddPlayer(self);
		let lWeap = ddp.GetLeftWeapons();
		let rWeap = ddp.GetRightWeapons();
		let pInv = ddp.GetWeaponsInventory();
		invoker.selDir = -1;
		if(invoker.inInventory)
		{
			if(--invoker.ix < 0) { invoker.ix = pInv.items.Size() - 1; }
			A_StartSound("misc/chat2", CHAN_WEAPON, 0, 0.67);
		}
		else
		{
			if(invoker.weapSide)
			{				
				if(--invoker.li < 0) { invoker.li = lWeap.items.Size() - 1; }
				A_StartSound("misc/chat2", CHAN_WEAPON, 0, 0.67);
			}
			else
			{		
				if(--invoker.ri < 0) { invoker.ri = rWeap.items.Size() - 1; }
				A_StartSound("misc/chat2", CHAN_WEAPON, 0, 0.67);				
			}
		}
	}
	
	action void A_InvRight()
	{
		let ddp = ddPlayer(self);
		let lWeap = ddp.GetLeftWeapons();
		let rWeap = ddp.GetRightWeapons();
		let pInv = ddp.GetWeaponsInventory();
		invoker.selDir = 1;
		if(invoker.inInventory)
		{
			if(++invoker.ix > pInv.items.Size() - 1) { invoker.ix = 0; }
			A_StartSound("misc/chat2", CHAN_WEAPON, 0, 0.67);
		}
		else
		{
			if(invoker.weapSide)
			{				
				if(++invoker.li > lWeap.items.Size() - 1) { invoker.li = 0; }
				A_StartSound("misc/chat2", CHAN_WEAPON, 0, 0.67);
			}
			else
			{		
				if(++invoker.ri > rWeap.items.Size() - 1) { invoker.ri = 0; }
				A_StartSound("misc/chat2", CHAN_WEAPON, 0, 0.67);				
			}
		}
	}
	
	action void SortInventoryIfYouWant()
	{
		let ddp = ddPlayer(self);
		let pspl = player.GetPSprite(PSP_LEFTW);
		let pspr = player.GetPSprite(PSP_RIGHTW);
		//use these to determine whether to lower side and dont return until both are true
		if(player.cmd.buttons & BT_ZOOM) 
		{ 
			A_StartSound("misc/i_pkup", CHAN_WEAPON, CHANF_OVERLAP, 1, ATTN_NORM, 1.7); ddplayer(self).SortInv(); A_Print("sorted!", 1); 
		}
		else { A_Log("Sort cancelled"); }
	}
	
	// ##playerInventory States()
	States
	{
		Deselect:
		Select:
			TNT1 A 0 EnterInventory;
		Ready:
			TNT1 A 1 A_WeaponReady(WRF_FULL);
			Loop;
		Fire:
			---- A 10 A_FistCycle;
			Goto Ready;
		Altfire:
			---- A 10 A_FistCycle;
			Goto Ready;
		Reload:
			---- A 8 A_ChangeSide;
			Goto Ready;
		User1: //q/
			---- A 8 A_ChangeInventory;
			Goto Ready;
		User2: //f/
			---- A 10 A_InvSelect;
			Goto Ready;
		User3: //c/
			---- A 8 A_InvRight;
			Goto Ready;
		User4: //z/
			---- A 8 A_InvLeft;
			Goto Ready;
		Zoom:
			---- A 35 A_Log("Hold to sort inventory...");
			---- A 20 SortInventoryIfYouWant;
			Goto Ready;
			
	}
	
}