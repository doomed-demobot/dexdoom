//The base player
// #Class ddPlayer : DoomPlayer()
class ddPlayer : DoomPlayer
{	
	int rwx, lwx; //weapon slots, right and left;
	int waitToPickup;
	bool altmodeL, altmodeR; //true if alt, false if primary
	uint ddWeaponState;
	bool wolfen, swapc;
	double addPitch;
	double addAngle;
	bool esoaActive; //set with esoaActivator custominventory item
	uint8 Combo; //holds current combo indentifier
	int ComboTimer; //set by weapons
	int fwx;
	inventoryWeapon invTemp;
	ddWeapon lastmode; //remember previous mode [dual or 2h]
	bool swapDown;
	//player stuff
	float helpme; // holds transparency of help text
	uint8 dddebug;
	bool debuggin, visrec, phyrec, gethelp, autoreload; //cvars
	float plFOV;
	int instability, instTimer; //instability penalty
	Array<Actor> alfBlacklist;
	//other
	ddweapon desire;
	Vector3 tepos;
	TouchEntity myte;
	Default
	{
		Speed 1;
		Health 100;
		Radius 16;
		Height 56;
		Mass 100;
		PainChance 255;
		//Species 'PlayerThing';
		Player.DisplayName "Baseclass";
		Player.CrouchSprite "PLYC";
		Player.StartItem "twoHanding";	
		Player.StartItem "dualWielding";
		Player.StartItem "inventoryOpener";
		Player.StartItem "esoaActivator";
		Player.StartItem "unloadActivator";
		Player.StartItem "playerInventory";
		Player.StartItem "ddFist";
		Player.StartItem "ddFistLeft";
		Player.StartItem "ddFistRight";
		Player.StartItem "ddPistol";
		Player.StartItem "d9Mil", 64;
		Player.StartItem "emptie";
		Player.StartItem "inventoryWeapon";
		Player.StartItem "LeftWeapons";
		Player.StartItem "RightWeapons";
		Player.StartItem "WeaponsInventory";
		Player.StartItem "FistList";
		Player.WeaponSlot 1, "twoHanding";
		Player.WeaponSlot 2, "dualWielding";
		Player.WeaponSlot 3, "";
		Player.WeaponSlot 4, "";
		Player.WeaponSlot 5, "";
		Player.WeaponSlot 6, "";
		Player.WeaponSlot 7, "";
		Player.WeaponSlot 8, "";
		Player.WeaponSlot 9, "";
		Player.WeaponSlot 0, "";
		Player.ColorRange 112, 127;
		Player.Colorset 0, "$TXT_COLOR_GREEN",		0x70, 0x7F,  0x72;
		Player.Colorset 1, "$TXT_COLOR_GRAY",		0x60, 0x6F,  0x62;
		Player.Colorset 2, "$TXT_COLOR_BROWN",		0x40, 0x4F,  0x42;
		Player.Colorset 3, "$TXT_COLOR_RED",		0x20, 0x2F,  0x22;
		// Doom Legacy additions
		Player.Colorset 4, "$TXT_COLOR_LIGHTGRAY",	0x58, 0x67,  0x5A;
		Player.Colorset 5, "$TXT_COLOR_LIGHTBROWN",	0x38, 0x47,  0x3A;
		Player.Colorset 6, "$TXT_COLOR_LIGHTRED",	0xB0, 0xBF,  0xB2;
		Player.Colorset 7, "$TXT_COLOR_LIGHTBLUE",	0xC0, 0xCF,  0xC2;
	}

	// ##goto overrides()
	
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		debuggin = CVar.GetCVar("pl_debug", player).GetBool();
		wolfen = CVar.GetCVar("pl_wolfen", player).GetBool();
		swapc = CVar.GetCVar("pl_wolfcontrols", player).GetBool();
		gethelp = CVar.GetCVar("pl_givehelp", player).GetBool();
		waitToPickup = 0;
		altmodeL = false;
		altmodeR = false;
		esoaActive = true;
		combo = COM_SHOT;
		combotimer = 0;
		desire = null;
	}
	
	override void GiveDefaultInventory()
	{
		Super.GiveDefaultInventory();
		invtemp = inventoryWeapon(FindInventory("inventoryWeapon"));
		rwx = 0;
		lwx = 0;
		fwx = 0;
		let lWeap = LeftWeapons(FindInventory("LeftWeapons"));
		let rWeap = RightWeapons(FindInventory("RightWeapons"));
		let pInv = WeaponsInventory(FindInventory("WeaponsInventory"));
		let flst = FistList(FindInventory("FistList"));
		//only insert parent types
		lWeap.additem(FindInventory("ddPistol"));
		if(lWeap.size > 1)
		{
			for(int x = 1; x < lWeap.size; x++)
			{
				lWeap.additem(FindInventory("emptie"));
			}
		}
		rWeap.additem(FindInventory("ddPistol"));
		if(rWeap.size > 1)
		{
			for(int x = 1; x < rWeap.size; x++)
			{
				rWeap.additem(FindInventory("emptie"));
			}
		}
		invtemp.construct("", 0, "", 0, 0, false);
		FillInv();
	}
	override void ClearInventory()
	{
		Super.ClearInventory();
		let lw = GetLeftWeapons();
		let rw = GetRightWeapons();
		let pin = GetWeaponsInventory();
		let fst = GetFistList();
		if(lw) { lw.items.clear(); }
		if(rw) { rw.items.clear(); }
		if(pin) { pin.items.clear(); }
		if(fst) { fst.items.clear(); }
	}
	
	override void TickPSprites()
	{
		let player = self.player;
		let weap = ddWeapon(player.readyweapon);
		let psplw = player.GetPSprite(PSP_LEFTW);
		let psprw = player.GetPSprite(PSP_RIGHTW);
		let pspr = player.psprites;
		while(pspr)
		{
			if(pspr.Caller == null ||
			(pspr.Caller is "Inventory" && Inventory(pspr.Caller).Owner != pspr.Owner.Mo)
			|| (pspr.Caller is "Weapon" && pspr.Caller != pspr.Owner.ReadyWeapon))
			{
				pspr.Destroy();
			}
			else
			{
				pspr.Tick();
			}
			pspr = pspr.Next;
		}		
		if ((health > 0) || (player.ReadyWeapon != null && !player.ReadyWeapon.bNoDeathInput))
		{
			CheckSwapButtons();
			if(player.ReadyWeapon == null)
			{
				if(player.PendingWeapon != WP_NOCHANGE) 
				{ 
					player.mo.BringUpWeapon(); 
				}
			}
			else
			{	
				//if((ddWeaponState & DDW_RIGHTREADY) && (ddWeaponState & DDW_LEFTREADY)) { 
					CheckQuickSwap();	
				//}
				if(weap.bmodeReady) 
				{ 
					CheckWeaponChange();
					if (player.WeaponState & (WF_WEAPONREADY | WF_WEAPONREADYALT))
					{
						CheckWeaponFire();
					}
					CheckWeaponButtons();
				}
				
			}
		}
		else 
		{
			player.SetPSprite(PSP_WEAPON, weap.FindState('DeathLower'));
		}
	}
	
	override void CheckWeaponChange()
	{
		let lw = GetLeftWeapon(lwx);
		let rw = GetRightWeapon(rwx);
		let mode = ddWeapon(player.readyweapon);
		if(lw.weaponStatus != DDW_FIRING && rw.weaponStatus != DDW_FIRING)
		{
			if(player.PendingWeapon != WP_NOCHANGE)
			{
				if(player.readyweapon is "twoHanding")
				{
					if(FindInventory("ClassicModeToken")) { ddWeaponState &= ~DDW_LEFTISTH; ddWeaponState &= ~DDW_RIGHTISTH; }
					ddWeaponState |= DDW_LEFTNOBOBBING;
					ddWeaponState |= DDW_RIGHTNOBOBBING;
					player.SetPSprite(PSP_LEFTW, lw.GetUpState());
					player.SetPSprite(PSP_RIGHTW, rw.GetUpState());
					mode.bmodeready = false;
					player.SetPSprite(PSP_WEAPON, player.readyweapon.GetDownState());		
				}
				else if(player.readyweapon is "dualWielding")
				{
					if(FindInventory("ClassicModeToken")) { ddWeaponState &= ~DDW_LEFTISTH; ddWeaponState &= ~DDW_RIGHTISTH; }
					ddWeaponState |= DDW_LEFTNOBOBBING;
					ddWeaponState |= DDW_RIGHTNOBOBBING;
					player.SetPSprite(PSP_LEFTW, lw.GetUpState());
					player.SetPSprite(PSP_RIGHTW, rw.GetUpState());
					mode.bmodeready = false;
					player.SetPSprite(PSP_WEAPON, player.readyweapon.GetDownState());
					
				}
				else{}
			}
		}
		else
		{
			//player.PendingWeapon = WP_NOCHANGE;
		}		
	}
	
	override void FireWeapon(State stat)
	{
		let weap = ddWeapon(player.readyweapon);
		if(weap.bmodeready)
		{
			weap.bAltFire = false;
			player.SetPSprite(PSP_WEAPON, weap.GetAtkState(false));
		}
		else
		{
			if(dddebug & DBG_PLAYER) { A_Log("Weapon not ready"); }
		}
	}
	
	override void FireWeaponAlt(State stat)
	{
		let weap = ddWeapon(player.readyweapon);
		if(weap.bmodeready)
		{
			weap.bAltFire = true;
			player.SetPSprite(PSP_WEAPON, weap.GetAtkState(false));
		}
		else
		{			
			if(dddebug & DBG_PLAYER) { A_Log("Weapon not ready"); }
		}
	}
	
	override void Travelled()
	{
		let lw = GetLeftWeapons();
		let rw = GetRightWeapons();
		let pinv = GetWeaponsInventory();
		if(self is "ddPlayerNormal")
		{
			for(int x = 0; x < pinv.size; x++)
			{
				//remake inventoryweapons references
				let inw = pInv.RetItem(x);
				if(inw.ref == null) 
				{
					inw.construct(inw.weaponname, inw.rating, inw.weaponsprite, inw.mag, inw.ddWeaponFlags, true);
				}
			}
			if(autoreload)
			{
				for(int y = 0; y < pinv.size; y++)
				{
					//auto reload inventoryweapons
					let inw = pInv.RetItem(y);
					if(inw.ref)
					{
						if(inw.mag < inw.ref.default.mag)
						{
							int cost = (inw.ref.default.mag - inw.ref.mag) * inw.ref.costmultiplier;
							if(cost > 0)
							{
								if(CountInv(inw.ref.AmmoType1) < cost) { inw.ref.mag += CountInv(inw.ref.AmmoType1); inw.mag = inw.ref.mag; }
								else { inw.ref.mag += (cost/inw.ref.costmultiplier); inw.mag = inw.ref.mag; }
								TakeInventory(inw.ref.AmmoType1, cost);
							}
							else { inw.ref.mag = inw.ref.default.mag; inw.mag = inw.ref.mag; }
						}
						inw.ref.OnAutoReload();
						inw.ddWeaponFlags = inw.ref.ddWeaponFlags;
					}
					
				}
				ddWeapon weap;
				for(int z = 0; z < lw.size+rw.size; z++)
				{
					//auto reload ddweapons
					if(z < lw.size) { weap = lw.RetItem(z);	}
					else { weap = rw.RetItem(z-lw.size); }
					weap.OnAutoReload();
					if(weap.mag < weap.default.mag)
					{
						int cost = (weap.default.mag - weap.mag) * weap.costmultiplier;
						if(cost > 0)
						{
							if(CountInv(weap.AmmoType1) < cost) { weap.mag += CountInv(weap.AmmoType1); }
							else { weap.mag += (cost/weap.costmultiplier); }
							TakeInventory(weap.AmmoType1, cost);
						}
						else { weap.mag = weap.default.mag; }
					}
				}
			}
		}
	}
	
	override void Tick()
	{
		if(!player || !player.mo || player.mo != self)
		{
			Super.Tick();
			return;
		}
		Super.Tick();
		let mode = ddWeapon(player.readyweapon);
		debuggin = CVar.GetCVar("pl_debug", player).GetBool();
		phyrec = CVar.GetCVar("pl_phyrecoil", player).GetBool();
		visrec = CVar.GetCVar("pl_visrecoil", player).GetBool();
		gethelp = CVar.GetCVar("pl_givehelp", player).GetBool();
		autoreload = CVar.GetCVar("pl_autoreload", player).GetBool();		
		CVar fouv = Cvar.GetCVar("fov", player);
		if(helpme > 0.1) { helpme -= 0.5; } else { helpme = 0.0; } 
		//set debug flags
		//note: a tick must pass after setting through pl_dmode
		if(debuggin)
		{ 
			//use signal bit for one-time print of current options
			if(dddebug & 32) { 
			A_Log("DDDebug active: "..
			((dddebug & DBG_VERBOSE) ? "Verbose\n":"\n")..
			((dddebug & DBG_PLAYER) ? "Player trace\n" : "")..
			((dddebug & DBG_WEAPSEQUENCE) ? "Weapon sequence trace\n" : "")..
			((dddebug & DBG_WEAPONS) ? "Weapon trace\n" : "")..
			((dddebug & DBG_INVENTORY) ? "Inventory trace\n" : "")
			);			
			dddebug &= 31; }
			int dbt = CVar.GetCVar("pl_dmode", player).GetInt();
			dddebug ^= dbt;
			CVar.GetCVar("pl_dmode", player).SetInt(0);
		}
		else
		{
			dddebug = 0;
			CVar.GetCVar("pl_dmode", player).SetInt(0);			
		}
		if(comboTimer != 0) { comboTimer--; }
		if(comboTimer <= 0) { combo = 0; comboTimer = 0; }
 		if(instTimer != 0) { instTimer--; }
		if(instTimer <= 0) { instTimer = 0; if(instability > 0) { instability-=5; } else { instability = 0; } }
		plFOV = fouv.GetFloat();
		if(!FindInventory("ClassicModeToken") && visrec) { plFOV += (instTimer / 4); }
		BobDDWeapons();
		//get looked at weapon [on the way out]
		//int d = 64;
		//ftranslatedlinetarget sub;
		//Actor source = self;
		//source.AimLineAttack(angle, d, sub, 0., ALF_CHECKNONSHOOTABLE | ALF_CHECK3D);
		//if(sub.linetarget is "ddWeapon") { desire = ddWeapon(sub.linetarget); }
		//else { desire = null; }
		
		//get looked at weapon
		flinetracedata re;
		LineTrace(angle, 50, pitch, 0, 40, 0, 0, re);
		tepos = re.hitlocation;
		if(!myte) { myte = TouchEntity(Spawn("TouchEntity")); myte.owner = self; }
		if(myte) { if(myte.closest) { desire = ddWeapon(myte.closest); } else { desire = null; } }
		if(desire) { if(player.cmd.buttons & BT_USE) { desire.PickMeUp(self); } }
		if(waitToPickup != 0 && mode.weaponstatus != DDM_SWAPPING) { waitToPickup++; }
		if(waitToPickup >= 35) { waitToPickup = 0; }
		//physical and visual recoil control
		if(addPitch != 0) { double d = addPitch / 2; addPitch -= d;  if(addPitch < 0.5) { addPitch = 0; } ; if(phyrec) { pitch -= d; if(pitch < -60) { pitch += d; } } }
		else { if(player.FOV > plFOV) { player.DesiredFOV -= (player.FOV - plFOV) / 4; } else { player.DesiredFOV = plFOV; } }
		if(addAngle != 0) { double e = addAngle / 2; addAngle -= e; if(phyrec) { if(addAngle < (2 >> 8) && addAngle > -(2 >> 8)) { addAngle = 0; } angle += e; } }
	}	
	
	// ##goto inventory functions()
	
	clearscope LeftWeapons GetLeftWeapons() { return LeftWeapons(FindInventory("LeftWeapons")); }
	clearscope RightWeapons GetRightWeapons() { return RightWeapons(FindInventory("RightWeapons")); }
	clearscope WeaponsInventory GetWeaponsInventory() { return WeaponsInventory(FindInventory("WeaponsInventory")); }
	clearscope FistList GetFistList() { return FistList(FindInventory("FistList")); }
	
	void FillInv()
	{
		bool noIW = false;
		Actor last = self;
		let lWeap = GetLeftWeapons();
		let rWeap = GetRightWeapons();
		let pInv = GetWeaponsInventory();
		int slots = lWeap.size + rWeap.size;
		while(last.inv != null)
		{
			let item = last.inv;
			if(item is "ddWeapon")
			{
				if(!ddWeapon(item).bGoesInInv) { last = item; }
				else {
					//check if the item is in a weapon slot already
					if(slots > 0)
					{
						for(int x = 0; x < (lWeap.size + rWeap.size); x++)
						{
							if(x < lWeap.items.size())
							{
								if(lWeap.RetItem(x) is item.GetClassName())
								{
									let weap = ddWeapon(Spawn(""..item.GetClassName().."Left"));
									weap.AttachToOwner(self); weap.AmmoGive1 = 0; noIW = true;
									if(self is "ddPlayerClassic") { weap.sFactor = 1.0; }
									lWeap.SetItem(weap, x);
								}
							}
							else
							{
								if(rWeap.RetItem(x - lWeap.size) is item.GetClassName())
								{
									let weap = ddWeapon(Spawn(""..item.GetClassName().."Right"));
									weap.AttachToOwner(self); weap.AmmoGive1 = 0; noIW = true;
									if(self is "ddPlayerClassic") { weap.sFactor = 1.0; }
									rWeap.SetItem(weap, x - lWeap.size);
								}
							}
						}
					}
					//dont make inventoryweapon for weapon that is in slots
					if(!noIW)
					{
						let weap = inventoryWeapon(Spawn("inventoryWeapon")); 
						let it = ddWeapon(item);
						weap.construct(it.GetClassName(), it.GetRating(), it.GetWeaponSprite(), it.mag); 
						weap.AttachToOwner(self);
						pInv.additem(weap);
						item.DepleteOrDestroy();
					}
					else
					{
						item.DepleteOrDestroy();
						noIW = false;
					}
				}				
			}
			else
			{
				last = item;
			}
			
		}
		//replace emptie placeholders in weapon slots with respective ddFist weapons
		
		for(int c = 0; c < (lWeap.size + rWeap.size); c++)
		{
			if(c < lWeap.size) { if(lWeap.retitem(c) is "emptie")
			{ lWeap.SetItem(ddWeapon(GetFists(1)), c); }
			}
			else { if(rWeap.retitem(c - lWeap.size) is "emptie") 
			{ rWeap.SetItem(ddWeapon(GetFists(0)), c-lWeap.size); }
			}
		}
		
		//set companion pieces [active weapon in other hand]
		if(lWeap.RetItem(lwx)) { rWeap.RetItem(rwx).companionPiece = lWeap.RetItem(lwx); }
		if(rWeap.RetItem(rwx)) { lWeap.RetItem(lwx).companionPiece = rWeap.RetItem(rwx); }
		
		for(int c = 0; c < pInv.size; c++)
		{			
			let empt = inventoryWeapon(Spawn("inventoryWeapon"));
			pInv.additem(empt);
			empt.attachtoowner(self);
		}
		SortInv();
	}
	
	//selection sort
	void SortInv()
	{
		inventoryWeapon temp;
		let pin = GetWeaponsInventory();
		//sort [ensure copies are placed near eachother]
		for(int x = 0; x < pin.items.size(); x++)
		{
			int highest = x;
			for(int y = x; y < pin.items.size(); y++)
			{
				if(pin.retitem(y).rating >= pin.retitem(highest).rating)
				{
					highest = y;
				}
			}
			temp = pin.retitem(x);
			pin.setitem(pin.retitem(highest), x);
			pin.setitem(temp, highest);
			temp = null;
		}
		
		if(dddebug & DBG_INVENTORY) 
		{ 
			ReportInventory();
		}
	}
	
	void CheckSwapButtons()
	{
		let weap = ddWeapon(player.readyweapon);
		let lWeap = GetLeftWeapons();
		let rWeap = GetRightWeapons();
		if(!(weap is "playerInventory"))
		{
			if(ddWeaponState & (DDW_REPLACERIGHT | DDW_REPLACELEFT)) { return; }
			if((player.cmd.buttons & BT_USER4))
			{
				if(!swapDown)
				{
					A_StartSound("misc/quickswap", CHAN_BODY, CHANF_OVERLAP, 0.45, ATTN_NORM, 2.);
					if(++weap.lswapTarget > lWeap.items.Size() - 1) { weap.lswapTarget = 0; }
				}						
				swapDown = true;
			}
			else if((player.cmd.buttons & BT_USER3))
			{
				if(!swapDown)
				{
					A_StartSound("misc/quickswap", CHAN_BODY, CHANF_OVERLAP, 0.45, ATTN_NORM, 2.);
					if(++weap.rswapTarget > rWeap.items.Size() - 1) { weap.rswapTarget = 0; }
					
				}						
				swapDown = true;			
			}
			else
			{
				swapDown = false;
			}
		}
	}
	
	void CheckQuickSwap()
	{
		let weap = ddWeapon(player.readyweapon);
		let lw = GetLeftWeapon(lwx);
		let lWeap = GetLeftWeapons();
		let rw = GetRightWeapon(rwx);
		let rWeap = GetRightWeapons();
		if(player.readyweapon is "twoHanding")
		{
			if(lw)
			{
				if(lwx != weap.lSwapTarget)
				{
					lwx = weap.lSwapTarget;
					lw = lWeap.RetItem(lwx);
					if(lw.bTwoHander && !CheckESOA(2)) { ddWeaponState |= DDW_LEFTISTH; }
					else { ddWeaponState &= ~DDW_LEFTISTH; }
					lw.companionpiece = rw;
					rw.companionpiece = lw;
					player.SetPSprite(PSP_LEFTW, lw.GetUpState());
					player.SetPSprite(PSP_LEFTWF, null);
				}
			}
			if((rwx != weap.rSwapTarget) && weap.weaponStatus == DDW_READY)
			{
				if(rw.weaponstatus == DDW_FIRING) { return; }
				player.SetPSprite(PSP_RIGHTW, rw.GetUpState());
				ddWeaponState &= ~DDW_RIGHTREADY;
				weap.bmodeready = false;
				weap.weaponStatus = DDM_SWAPPING;
				waittopickup++;
				player.SetPSprite(PSP_WEAPON, ddWeapon(player.readyweapon).FindState('QuickSwapTH'));
			}
		}
		else if(player.readyweapon is "dualWielding")
		{
			//lower them
			if((lwx != weap.lSwapTarget || rwx != weap.rSwapTarget) && weap.weaponStatus == DDW_READY)
			{
				if(lw.weaponstatus == DDW_FIRING || rw.weaponstatus == DDW_FIRING) { return; }
				player.SetPSprite(PSP_LEFTW, lw.GetUpState());
				player.SetPSprite(PSP_RIGHTW, rw.GetUpState());
				ddWeaponState &= ~DDW_LEFTREADY;
				ddWeaponState &= ~DDW_RIGHTREADY;
				dualWielding(weap).blraised = false;
				dualWielding(weap).brraised = false;
				weap.bmodeready = false;
				weap.weaponStatus = DDM_SWAPPING;
				waittopickup++;
				player.SetPSprite(PSP_WEAPON, ddWeapon(player.readyweapon).FindState('QuickSwapDW'));
			}
		}
		else
			return;
	}
	
	void ReportInventory()
	{
		let lw = GetLeftWeapons();
		let rw = GetRightWeapons();
		let pin = GetWeaponsInventory();
		let fls = GetFistList();
		
		A_Log("========WEAPONSLOTS==========");
		A_Log("Player left weapons (lWeap): ");			
		for(int x = 0; x < lw.items.size(); x++)			
		{
			A_Log("lWeap["..x.."] : "..lw.retitem(x).GetClassName());
		}			
		A_Log("Player right weapons (rWeap):");			
		for(int x = 0; x < rw.items.size(); x++)			
		{
			A_Log("rWeap["..x.."] : "..rw.retitem(x).GetClassName());
		}			
		A_Log("Player fist weapons (fInv):");			
		for(int x = 0; x < fls.items.size(); x++)			
		{
			A_Log("fInv["..x.."] : "..fls.retitem(x).GetClassName());
		}
		A_Log("PlayerInventory:");
		A_Log("=======PLAYERINVENTORY========");
		for(int x = 0; x < pin.items.size(); x++)
		{
			A_Log(""..pin.retitem(x).GetClassName().." "..x.." / "..pin.retitem(x).weaponname.." / "..pin.retitem(x).rating);
		}
		A_Log("=============================");
	
	}
	
	void IncreaseSlots(int side, int am)
	{
		let lWeap = GetLeftWeapons();
		let rWeap = GetRightWeapons();
		if(side == CE_LEFT)
		{
			lWeap.size += am;
			for(int x = 0; x < am; x++)
			{
				lWeap.AddItem(ddWeapon(GetFists(1)));
			}
		}
		else if(side == CE_RIGHT)
		{
			rWeap.size += am;
			for(int x = 0; x < am; x++)
			{
				rWeap.AddItem(ddWeapon(GetFists(0)));
			}
		
		}
		else {}
	}
	
	void IncreaseInventory(int am)
	{
		let pInv = GetWeaponsInventory();
		pInv.size += am;
		for(int x = 0; x < am; x++)
		{
			let empt = inventoryWeapon(Spawn("inventoryWeapon"));
			pInv.AddItem(empt);
			empt.AttachToOwner(self);
		}
	}
	
	// ##goto weapon functions()
	
	void InitTwoHanding()
	{
		let lWeap = GetLeftWeapons();
		let rWeap = GetRightWeapons();
		swapdown = false;
		ddWeapon(player.readyweapon).lswaptarget = lwx;
		ddWeapon(player.readyweapon).rswaptarget = rwx;
		ddWeaponState |= DDW_LEFTNOBOBBING;
		ddWeaponState |= DDW_RIGHTNOBOBBING;
		if(lWeap.RetItem(lwx).bTwoHander) { ddWeaponState |= DDW_LEFTISTH; }
		else { ddWeaponState &= ~DDW_LEFTISTH; }
		if(rWeap.RetItem(rwx).bTwoHander) { ddWeaponState |= DDW_RIGHTISTH; }
		else { ddWeaponState &= ~DDW_RIGHTISTH; }
		let rw = GetRightWeapon(rwx);
		let lw = GetLeftWeapon(lwx);
		let pspl = player.GetPSprite(PSP_LEFTW);
		let psplf = player.GetPSprite(PSP_LEFTWF);
		let pspr = player.GetPSprite(PSP_RIGHTW);
		let psprf = player.GetPSprite(PSP_RIGHTWF);
		let mode = player.GetPSprite(PSP_WEAPON);
		lastmode = ddWeapon(FindInventory("twoHanding"));
		player.SetPSprite(PSP_LEFTW, lw.FindState('Select'));
		player.SetPSprite(PSP_RIGHTW, rw.FindState('Select'));
		pspr.x = 0; psprf.x = 0;
		pspr.y = 128; psprf.y = 128;
		pspl.x = -64 - lw.xoffset; psplf.x = -64 - lw.xoffset;
		pspl.y = 128; psplf.y = 128;
		ddWeapon(player.readyweapon).weaponStatus = DDW_READY;
		player.SetPSprite(PSP_WEAPON, player.readyweapon.FindState('Select'));
		mode.y = 32;
	}
	
	void InitDualWielding()
	{
		let lWeap = GetLeftWeapons();
		let rWeap = GetRightWeapons();
		swapdown = false;
		ddWeapon(player.readyweapon).lswaptarget = lwx;
		ddWeapon(player.readyweapon).rswaptarget = rwx;
		dualWielding(player.readyweapon).blraised = false;
		dualWielding(player.readyweapon).brraised = false;
		ddWeaponState |= DDW_LEFTNOBOBBING;
		ddWeaponState |= DDW_RIGHTNOBOBBING;
		if(lWeap.RetItem(lwx).bTwoHander) { ddWeaponState |= DDW_LEFTISTH; }
		else { ddWeaponState &= ~DDW_LEFTISTH; }
		if(rWeap.RetItem(rwx).bTwoHander) { ddWeaponState |= DDW_RIGHTISTH; }
		else { ddWeaponState &= ~DDW_RIGHTISTH; }
		let rw = GetRightWeapon(rwx);
		let lw = GetLeftWeapon(lwx);
		let pspl = player.GetPSprite(PSP_LEFTW);
		let psplf = player.GetPSprite(PSP_LEFTWF);
		let pspr = player.GetPSprite(PSP_RIGHTW);
		let psprf = player.GetPSprite(PSP_RIGHTWF);
		let mode = player.GetPSprite(PSP_WEAPON);
		lastmode = ddWeapon(FindInventory("dualWielding"));
		player.SetPSprite(PSP_LEFTW, lw.FindState('Select'));
		player.SetPSprite(PSP_RIGHTW, rw.FindState('Select'));
		pspr.x = -64; psprf.x = -64;
		pspr.y = 128; psprf.y = 128;
		pspr.x = 64 + rw.xOffset; psprf.x = 64 + rw.xOffset;
		pspl.x = -64; psplf.x = -64;
		pspl.y = 128; psplf.y = 128;
		ddWeapon(player.readyweapon).weaponStatus = DDW_READY;
		player.SetPSprite(PSP_WEAPON, player.readyweapon.FindState('Select'));
		mode.y = 32;
	}
	
	protected void BobDDWeapons()
	{
		let mode = ddWeapon(player.readyweapon);	
		if(mode == null) { return; }
		let pspl = player.GetPSprite(PSP_LEFTW);
		let psplf = player.GetPSprite(PSP_LEFTWF);
		let pspr = player.GetPSPrite(PSP_RIGHTW);
		let psprf = player.GetPSprite(PSP_RIGHTWF);
		ddWeapon lw = GetLeftWeapon(lwx);
		double LWBobSpeed = lw.BobSpeed;
		double LWBobX = lw.BobRangeX;
		double LWBobY = lw.BoBRangeY;
		ddWeapon rw = GetRightWeapon(rwx);
		double RWBobSpeed = rw.BobSpeed;
		double RWBobX = rw.BobRangeX;
		double RWBobY = rw.BobRangeY;	
		if(!mode.bmodeready) { return; }
		double angle = (128 * ((LWBobSpeed + RWBobSpeed) / 2) * player.GetWBobSpeed() * 35 / TICRATE*(Level.maptime)) * (360. / 8192.);
		curbob = player.bob;
		
		double lBobIntensity = (ddWeaponState & DDW_LEFTBOBBING) ? 1. : player.GetWBobFire();
		double rBobIntensity = (ddWeaponState & DDW_RIGHTBOBBING) ? 1. : player.GetWBobFire();
		
		if(curbob != 0)
		{
			double bobVal = player.bob;
			double lbobx = (BobVal * lBobIntensity * LWBobX * viewBob);
			double lboby = (BobVal * lBobIntensity * LWBobY * viewBob);
			double rbobx = (BobVal * rBobIntensity * RWBobX * viewBob);
			double rboby = (BobVal * rBobIntensity * RWBobY * viewBob);
			if(lastmode is "dualWielding")
			{
				double lx = (lbobx * abs(cos(angle))) - (64 + lw.xoffset);
				double ly = lboby * abs(sin(angle));
				if(!(ddWeaponState & DDW_LEFTNOBOBBING))
				{
					pspl.x = lx;
					psplf.x = lx;
					pspl.y = ly;
					psplf.y = ly;
				}
				double rx = (rbobx * abs(-sin(angle)));
				rx += (64 + rw.xoffset); 
				double ry = rboby * abs(-cos(angle));
				if(!(ddWeaponState & DDW_RIGHTNOBOBBING))
				{
					pspr.x = rx;
					psprf.x = rx;
					pspr.y = ry;
					psprf.y = ry;
				}
			}
			else if(lastmode is "twoHanding")
			{
				pspl.x = -64;
				psplf.x = -64;
				pspl.y = 128;
				psplf.y = 128;
				double rx = rbobx * cos(angle);
				double ry = rboby * abs(sin(angle));
				if(!(ddWeaponState & DDW_RIGHTNOBOBBING))
				{
					pspr.x = rx;
					psprf.x = rx;
					pspr.y = ry;
					psprf.y = ry;
				}
			}
		}
	}
	
	clearscope ddWeapon GetFists(int side = -1) 
	{ 
		let flst = GetFistList();
		if(side < 0) { return flst.RetItem(fwx); }
		else
		{
			ddWeapon fst = ddWeapon(FindInventory(flst.RetItem(fwx).GetClassName()..((side) ? "Left" : "Right")));
			return fst;
		}
	}
	
	// slot is 0th position
	clearscope ddWeapon GetLeftWeapon(int slot, bool bypass = false) 
	{ 
		let lWeap = GetLeftWeapons();
		if(slot > lWeap.items.size() - 1 || slot < 0) { return null; }
		if(!bypass && lWeap.RetItem(slot).bTwoHander && !FindInventory("ClassicModeToken")) { return ddWeapon(GetFists(1)); }
		else { return ddWeapon(lWeap.RetItem(slot)); }
	}
	
	clearscope ddWeapon GetRightWeapon(int slot, bool bypass = false)
	{
		let rWeap = GetRightWeapons();
		if(slot > rWeap.items.size() - 1 || slot < 0) { return null; }
		if(!bypass && rWeap.RetItem(slot).bTwoHander && (player.readyweapon is "dualWielding" || lastmode is "dualWielding") && !FindInventory("ClassicModeToken")) { 
			return ddWeapon(GetFists(0)); 
		}
		else { return ddWeapon(rWeap.RetItem(slot)); }
	}
	
	bool CheckESOA(int cost)
	{
		if(!FindInventory("ESOA")) { return false; }
		if(!esoaActive) { return false; }
		if(cost > CountInv("ESOACharge")) { return false; }
		return true;
	}
	
	// ##goto cheats()
	override void CheatGive(String name, int amount)
	{
		if(PlayerNumber() == consoleplayer)
		{	
			let pInv = GetWeaponsInventory();
			class<inventory> item;
			bool all;
			if(name ~== "all") { all = true; }			
			if(all || name ~== "health") { Super.CheatGive("health", amount); if(!all) { return; } }
			if(all || name ~== "ammo") { Super.CheatGive("ammo", amount); if(!all) { return; } }
			if(all || name ~== "armor") { Super.CheatGive("armor", amount); if(!all) { return; } }
			if(all || name ~== "backpack") { Super.CheatGive("backpack", amount); if(!all) { return; } }
			if(all || name ~== "keys") { Super.CheatGive("keys", amount); if(!all) { return; } }
			if(all || name ~== "artifacts") { Super.CheatGive("artifacts", amount); if(!all) { return; } }
			if(all || name ~== "puzzlepieces") { Super.CheatGive("puzzlepieces", amount); if(!all) { return; } }
			if(all || name ~== "weapons") 
			{
				Array<ddWeapon> dmp;
				ddWeapon tmp;
				for(int i = 0; i < AllActorClasses.Size(); i++)
				{
					if(AllActorClasses[i] is "ddWeapon")
					{
						tmp = ddWeapon(Spawn(AllActorClasses[i].GetClassName()));
						if(!tmp.bGoesInInv) { tmp.Destroy(); continue; }
						if(tmp.GetClassName() == "ddweapon") { tmp.Destroy(); continue; } //dont let in the actual ddweapon; probably should've made it abstract
						dmp.Push(tmp);
					}
				}
				if(dddebug & DBG_INVENTORY && dddebug & DBG_VERBOSE) { A_Log("Found "..dmp.Size().." ddWeapons"); }
				bool ok;
				for(int x = 0; x < dmp.size(); x++)
				{
					ok = false;
					for(int y = 0; y < pInv.items.size(); y++)
					{
						if(pInv.RetItem(y).weaponName == "emptie")
						{
							if(dddebug & DBG_INVENTORY) { A_Log(""..dmp[x].GetClassName().." placed in playerinventory at index "..y); }
							pInv.RetItem(y).construct(dmp[x].GetParentType(), dmp[x].rating, dmp[x].GetWeaponSprite(), dmp[x].mag);
							dmp[x].Destroy();
							ok = true;
							break;
						}						
					}
					if(!ok)
					{
						A_Log("Inventory full; the "..dmp[x].GetClassName().." slipped out!", 1.5);
						dmp[x].AttachToOwner(self);
						dmp[x].AmmoGive1 = 0;
						ddWeapon bye = ddWeapon(DropInventory(dmp[x]));
						bye.Angle += Random2() * (3.);
						bye.Vel = Vel;
						bye.VelFromAngle(5.);
						continue;						
					}
				}
				dmp.Clear();
				if(!all) { return; }
			}
			else
			{
				item = name;
				if(item is "ddWeapon")
				{
					ddWeapon wep = ddWeapon(Spawn(item));
					if(!wep.bGoesInInv) { Console.Printf("Item \"%s\" can't be placed in playerInventory", name); wep.Destroy(); return; }
					for(int x = 0; x < pInv.items.size(); x++)
					{
						if(pInv.RetItem(x).weaponName == "emptie")
						{
							if(dddebug & DBG_INVENTORY) { A_Log(""..item.GetClassName().." placed in playerinventory at index "..x); }
							pInv.RetItem(x).construct(wep.GetParentType(), wep.rating, wep.GetWeaponSprite(), wep.mag);
							GiveInventory(wep.AmmoType1, wep.AmmoGive1);
							wep.AmmoGive1 = 0;
							wep.Destroy();
							return;
						}						
					}	
					A_Print("Inventory full; the "..item.GetClassName().." slipped out!", 1.5);
					wep.AttachToOwner(self);
					wep.AmmoGive1 = 0;
					ddWeapon bye = ddWeapon(DropInventory(wep));
					bye.Angle += Random2() * (3.);
					bye.VelFromAngle(5.);
					bye.Vel = Vel;
					return;
				}
				else if(item is "berserk" || item is "powerstrength") { Super.CheatGive("powerberserk", amount); return; }
				else { Super.CheatGive(name, amount); return; }
			
			}	
		}
	}
	
	override void CheatTake(String name, int amount)
	{
		if(PlayerNumber() == consoleplayer)
		{
			let lWeap = GetLeftWeapons();
			let rWeap = GetRightWeapons();
			let pInv = GetWeaponsInventory();
			class<inventory> item;
			bool all;
			if(name ~== "all") { all = true; }
			else if(name ~== "everything") { A_Log("ok!"); Super.CheatTake("health", 200); if(!all) { return; } }			
			if(all || name ~== "health") { Super.CheatTake("health", amount); if(!all) { return; } }
			if(all || name ~== "ammo") { Super.CheatTake("ammo", amount); if(!all) { return; } }
			if(all || name ~== "armor") { Super.CheatTake("armor", amount); if(!all) { return; } }
			if(all || name ~== "keys") { Super.CheatTake("keys", amount); if(!all) { return; } }
			if(all || name ~== "backpack") { Super.CheatTake("backpack", amount); if(!all) { return; } }
			if(all || name ~== "artifacts") { Super.CheatTake("artifacts", amount); if(!all) { return; } }
			if(all || name ~== "puzzlepieces") { Super.CheatTake("puzzlepieces", amount); if(!all) { return; } }
			if(all || name ~== "weapons") 
			{ 
				//clear pInv
				for(int x = 0; x < pInv.items.size(); x++)
				{
					if(pInv.RetItem(x).weaponName != "emptie")
					{ 					
						if(dddebug & DBG_INVENTORY) { A_Log(""..pInv.RetItem(x).weaponName.." in inventory taken."); }
						pInv.RetItem(x).emptify(); 
					}
				}
				//clear weapon slots
				for(int z = 0; z < (lweap.size + rweap.size); z++)
				{
					if(z < lWeap.items.size()) 
					{ 
						if(!(lWeap.RetItem(z) is "ddFist")) 
						{ 
							if(dddebug & DBG_INVENTORY) { A_Log(""..lWeap.RetItem(z).GetTag().." in left slot "..z.." taken."); }							
							RemoveInventory(lWeap.RetItem(z));
							lWeap.SetItem(ddWeapon(GetFists(1)), z); 
						}	
					}
					else 
					{ 
						if(!(rWeap.RetItem(z - lWeap.items.size()) is "ddFist")) 
						{ 
							if(dddebug & DBG_INVENTORY) { A_Log(""..rWeap.RetItem(z-lWeap.items.size()).GetTag().." in right slot "..z-lWeap.items.size().." taken."); }
							RemoveInventory(rWeap.RetItem(z-lWeap.items.size()));
							rWeap.SetItem(GetFists(0),z - lWeap.items.size());
						}
					}  
				}
			}
			else
			{
				item = name;
				if(item is "ddWeapon")
				{
					for(int x = 0; x < pInv.items.size(); x++)
					{
						if(pInv.RetItem(x).weaponName == item)
						{ 					
							if(dddebug & DBG_INVENTORY) { A_Log(""..pInv.RetItem(x).weaponName.." taken from inventory slot "..x); }
							pInv.RetItem(x).emptify(); 
						}
					}
					
					for(int z = 0; z < (lweap.size + rweap.size); z++)
					{
						if(z < lWeap.items.size()) 
						{ 
							if(lWeap.RetItem(z) is item) 
							{ 
								if(dddebug & DBG_INVENTORY) { A_Log(""..lWeap.RetItem(z).GetTag().." taken from left slot "..z); }							
								RemoveInventory(lWeap.RetItem(z));								
								lWeap.SetItem(ddWeapon(GetFists(1)), z); 
							}	
						}
						else 
						{ 
							if(rWeap.RetItem(z - lWeap.items.size()) is item) 
							{ 
								if(dddebug & DBG_INVENTORY) { A_Log(""..rWeap.RetItem(z-lWeap.items.size()).GetTag().." taken from right slot "..z-lWeap.items.size()); }
								RemoveInventory(rWeap.RetItem(z-lWeap.items.size()));
								rWeap.SetItem(GetFists(0),z - lWeap.items.size());
							}
						}  
					}
				}
				else { Super.CheatTake(name, amount); return; }
			}
			
		}
	}
	
	override void CheatTakeWeaps()
	{
		if(PlayerNumber() == consoleplayer)
		{
			A_Log("no");
		}		
	}
	
	States
	{
		Spawn:
			PLAY A -1;
			Loop;
		See:
			PLAY ABCD 4;
			Loop;
		Missile:
			PLAY E 12;
			Goto Spawn;
		Melee:
			PLAY F 6 BRIGHT;
			Goto Missile;
		Pain:
			PLAY G 4;
			PLAY G 4 A_Pain;
			Goto Spawn;
		Death:
			PLAY H 0 A_PlayerSkinCheck("AltSkinDeath");
		Death1:
			PLAY H 10;
			PLAY I 10 A_PlayerScream;
			PLAY J 10 A_NoBlocking;
			PLAY KLM 10;
			PLAY N -1;
			Stop;
		XDeath:
			PLAY O 0 A_PlayerSkinCheck("AltSkinXDeath");
		XDeath1:
			PLAY O 5;
			PLAY P 5 A_XScream;
			PLAY Q 5 A_NoBlocking;
			PLAY RSTUV 5;
			PLAY W -1;
			Stop;
		AltSkinDeath:
			PLAY H 6;
			PLAY I 6 A_PlayerScream;
			PLAY JK 6;
			PLAY L 6 A_NoBlocking;
			PLAY MNO 6;
			PLAY P -1;
			Stop;
		AltSkinXDeath:
			PLAY Q 5 A_PlayerScream;
			PLAY R 0 A_NoBlocking;
			PLAY R 5 A_SkullPop;
			PLAY STUVWX 5;
			PLAY Y -1;
			Stop;
	}
}
// #Class ddPlayerNormal : ddPlayer()
class ddPlayerNormal : ddPlayer 
{
	Default
	{	
		Player.Portrait "";
		Player.DisplayName "Normal Mode";
	}
}
// #Class ddPlayerClassic : ddPlayer()
class ddPlayerClassic : ddPlayer 
{
	Default
	{
		Player.Portrait "";
		Player.DisplayName "Classic Mode";
		Player.StartItem "ClassicModeToken";
		Player.StartItem "twoHanding";
		Player.StartItem "dualWielding";	
		Player.StartItem "inventoryOpener";
		Player.StartItem "playerInventory";
		Player.StartItem "ddFist";
		Player.StartItem "ddFistLeft";
		Player.StartItem "ddFistRight";
		Player.StartItem "ddPistol";
		Player.StartItem "Clip", 30;
		Player.StartItem "LeftWeapons";
		Player.StartItem "RightWeapons";
		Player.StartItem "WeaponsInventory";
		Player.StartItem "FistList";
		Player.StartItem "emptie";
		Player.StartItem "inventoryWeapon";
	}
}

enum DebugState
{
	DBG_PLAYER = 1 << 0,
	DBG_WEAPSEQUENCE = 1 << 1,
	DBG_WEAPONS = 1 << 2,
	DBG_INVENTORY = 1 << 3,
	DBG_VERBOSE = 1 << 4,
};

//extra set of arms; if held, treat readyweapon as if its twohanding
// #Class ESOA : Inventory()
class ESOA : Inventory
{
	Default
	{
		Inventory.MaxAmount 1;
		Inventory.PickupSound "misc/secret";
		Inventory.PickupMessage "Attached an extra set of arms!";
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.UNTOSSABLE;
		-INVENTORY.INVBAR;
		+INVENTORY.IGNORESKILL;
	}
	
	States
	{
		Spawn:
			ESOA A -1;
			Stop;
	}
}
class ESOACharge : Ammo
{	
	Default
	{
		Inventory.PickupMessage "";
		Inventory.Amount 1;
		Inventory.MaxAmount 1000;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 1000;
		Inventory.Icon "";
		Tag "ESOACharge";	
	}
	States
	{
		Spawn:
			TNT1 A -1;
			Stop;
	}
}
/*
class CellPacke : CellPack {}

class ESOAPack : ESOACharge
{
	Default
	{
		Inventory.PickupMessage "Picked up an ESOA charge pack";
		Inventory.Amount 100;
	}
	
	States
	{
		Spawn:
			CELP A -1;
			Stop;
	}
}

class CellPackSpawner : RandomSpawner replaces CellPack
{
	Default
	{
		DropItem "CellPacke", 255, 45;
		DropItem "ESOAPack", 255, 24;
	}
	
	override Name ChooseSpawn()
	{
		for(int x = 0; x < 8; x++)
		{
			if(players[x].mo is "ddPlayerClassic")
			{
				return "CellPacke";
			}
		}
		return Super.ChooseSpawn();
	}
	
}
*/
// #Class esoaActivator : CustomInventory()
class esoaActivator : CustomInventory
{
	Default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 1;
		Inventory.UseSound "weapons/rocketload";
		-INVENTORY.INVBAR;
		-INVENTORY.AUTOACTIVATE;
		+INVENTORY.IGNORESKILL;
		+INVENTORY.QUIET;
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.UNTOSSABLE;
	}
	
	action void A_ToggleESOA()
	{
		let ddp = ddPlayer(self);
		if(ddp.ddWeaponState & DDW_LEFTREADY && ddp.ddWeaponState & DDW_RIGHTREADY)
		{
			if(ddp.FindInventory("ESOA", false))
			{
				if(!ddp.esoaActive) { A_StartSound("menu/activate", CHAN_BODY, CHANF_OVERLAP); }
				else { A_StartSound("menu/clear", CHAN_BODY, CHANF_OVERLAP); }
				ddp.esoaActive = !ddp.esoaActive;
				A_Log("Extra set of arms "..((ddp.esoaActive) ? "activated." : "deactivated"));
			}
			else { A_Log("No extra set of arms equipped"); }
		}
		else { if(ddp.dddebug & DBG_WEAPONS) { A_Log("Weapons not ready"); } }
		
	}
	
	States
	{
		Spawn:
			TNT1 A -1;
			Stop;
		Use:
			---- A 1 A_ToggleESOA;
			Loop;
	}	
}

class unloadActivator : custominventory
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
	
	action void A_UseUnload()
	{
		let ddp = ddPlayer(Self);
		let mode = ddWeapon(ddp.player.readyweapon);
		let lw = ddp.GetLeftWeapon(ddp.lwx);
		let rw = ddp.GetRightWeapon(ddp.rwx);
		if(ddp.ddWeaponState & DDW_LEFTREADY && ddp.ddWeaponState & DDW_RIGHTREADY)
		{
			lw.weaponready = false;
			rw.weaponready = false;
			//ddp.ddWeaponState &= ~DDW_RIGHTREADY;
			//ddp.ddWeaponState &= ~DDW_LEFTREADY;
			if(mode is "twoHanding" || ddp.player.cmd.buttons & BT_USE)
			{
				rw.weaponstatus = DDW_UNLOADING;
				mode.A_CheckRightWeaponMag();
				return;
			}
			else
			{
				lw.weaponstatus = DDW_UNLOADING;
				mode.A_CheckLeftWeaponMag();
				return;
			}
		}
		else
		{
			if(ddp.dddebug & DBG_WEAPONS) { A_Log("Weapons not ready"); return;}
		}
	}
	
	States
	{
		Spawn:
			TNT1 A -1;
			Stop;
		Use:
			---- A 1 A_UseUnload;
			Loop;
	}
	
}


//token given to classic mode player; disables altfire, extra items and special weapon handling
class ClassicModeToken : ESOA
{	
	Default
	{
		Inventory.RestrictedTo "ddPlayerClassic";
	}
}

class TouchEntity : Actor
{
	ddPlayer owner;
	ddWeapon closest;
	Default
	{
		Health 999;
		Radius 5;
		Height 5;
		Gravity 0;
		Mass 1;
		-SOLID;
		
	}
	
	void TEMove()
	{
		if(!owner) { Destroy(); }
		SetOrigin(owner.tepos, false);
		if(owner.dddebug & DBG_INVENTORY) { self.sprite = GetSpriteIndex("PKUPA0"); }
		else { self.sprite = GetSpriteIndex("TNT1A0"); }
		closest = null;
		CheckNeighbors();
	}
	
	void CheckNeighbors()
	{
		BlockThingsIterator blk = BlockThingsIterator.Create(self, 8);
		float rec = 666.f;
		while(blk.Next())
		{
			if(blk.thing is "ddWeapon" && (Distance2D(blk.thing) - (blk.thing.radius / 2) < rec)) { 
				rec = Distance2D(blk.thing) - (blk.thing.radius / 2); if(rec < 10 && 
				(abs(self.pos.z) - abs(blk.thing.pos.z) - (blk.thing.height / 16)) < 10 &&
				(abs(self.pos.z) - abs(blk.thing.pos.z) - (blk.thing.height / 16)) > -10) 
				{ closest = ddWeapon(blk.thing); }
			}
		}
	}
	
	States
	{
		Spawn:
			#### A 1 TEMove;
			Loop;
		Death:
			PKUP A 0;
			TNT1 A -1;
			Stop;
	}
}