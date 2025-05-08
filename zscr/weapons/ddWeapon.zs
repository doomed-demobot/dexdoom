enum WeaponStatus
{
	DDW_READY = 0,
	DDW_RELOADING,
	DDW_FIRING,
	DDW_ALTFIRING,
	DDM_SWAPPING,
	DDW_UNLOADING
};

class NoBlood : Blood
{
	Default 
	{
		-ALLOWPARTICLES;
	}
	
	States
	{
		Spawn:
			TNT1 A 1;
			Stop;
	}
	
}
//Weapons must be ddWeapon to be used
// #Class ddWeapon : Weapon()
class ddWeapon : Weapon
{
	//owner cvars
	bool debuggin, wolfen, swapc, altModeL, altModeR;
	//weapon stuff
	bool leftheld, rightheld, zoomheld;
	ddWeapon companionpiece; 
	Name weaponType; //general classification for some weapon relations
	int weaponside;
	int mag;
	int weaponStatus;
	int rating;
	bool weaponReady;
	double sFactor;
	int MagUse1, MagUse2;
	int ChargeUse1, ChargeUse2; //how much charge to ignore dualwield check and pass twohand check
	int costMultiplier; //multiplier for reloadweaponmag
	int xOffset;
	uint lswaptarget, rswapTarget;
	int caseno;
	int sndno;
	int fireMode; //true = alt; false = primary
	class<Ammo> ClassicAmmoType1, ClassicAmmoType2;
	ddWeapon swapHeld; //weapon stored here for pickupswapstore
	property ClassicAmmoType : ClassicAmmoType1;
	property ClassicAmmoType1 : ClassicAmmoType1;
	property ClassicAmmoType2 : ClassicAmmoType2;
	property Rating : rating; //rating used for sorting
	property SwitchSpeed : sFactor; // 1 = crawling, 1.5 = slow, 2 = normal, 2.5 = fast, 3 = faster
	property WeaponSide : weaponside;
	property WeaponType : weapontype;
	property InitialMag : mag;
	property MagUse : MagUse1;
	property MagUse1 : MagUse1;
	property MagUse2 : MagUse2;
	property costMulti : costMultiplier;
	property ChargeUse : ChargeUse1;
	property ChargeUse1 : ChargeUse1;
	property ChargeUse2 : ChargeUse2;
	property xOffset : xOffset;
	property initialddWFlags : ddWeaponFlags;
	//flags
	int ddweaponflags;
	int prFlags;
	flagdef modeReady	 : prFlags, 0; //twohanding/dual wielding can fire
	flagdef noLower		 : prFlags, 1; //weapon never needs to lower to center to reload
	flagdef noReload     : prFlags, 2; //weapon mag isn't check with reload key
	flagdef twoHander	 : prFlags, 3; //weapon can only be used in twoHanding; replaced with fists if equipped in dualWielding
	flagdef goesInInv	 : prFlags, 4; //weapon goes into playerInventory;
	Default
	{
		Weapon.MinSelectionAmmo1  0;
		Weapon.MinSelectionAmmo2 0;
		Weapon.Kickback 100;
		Weapon.BobSpeed 1;
		Weapon.BobRangeX 1;
		Weapon.BobRangeY 1;
		ddWeapon.Rating 0;
		ddWeapon.initialMag -1;
		ddWeapon.MagUse1 0;
		ddWeapon.MagUse2 0;
		ddWeapon.ChargeUse 1;
		ddWeapon.ChargeUse2 1;
		ddWeapon.costMulti 1;
		ddWeapon.xOffset 0;
		ddweapon.initialddWFlags 2<<6;
		BloodType "NoBlood";
		Decal "BulletChip"; //todo: see if this respects a ddWeapon's custom decals
		+NOBLOODDECALS;
		+DONTTHRUST;
		+INVULNERABLE;
		+DDWEAPON.GOESININV;
		-DDWEAPON.MODEREADY;
		-DDWEAPON.NOLOWER;
	}
	
	virtual ui void HUDA(ddStats hude) {} //screensize 11; minimal
	virtual ui void HUDB(ddStats hude) { self.HUDA(hude); } //screensize 10; more descriptive 
	
	bool PickMeUp(Actor pickerupper)
	{
		let ddp = ddPlayer(pickerupper);
		if(ddp.waitToPickup > 0) { if(ddp.dddebug & DBG_INVENTORY) { ddp.A_Log("WAIT!"); } return false; }
		if(ddp.desire != self) { if(ddp.dddebug & DBG_INVENTORY) { ddp.A_Log("ya missed!"); } return false; }
		else 
		{ 
			if(AddToDDPlayer(pickerupper))
			{
				PlayPickupSound(pickerupper);
				ddp.A_Log(PickupMessage());
				if(!bNoScreenFlash && ddp.player.playerstate != PST_DEAD)
				{
					ddp.player.bonuscount = BONUSADD;
				}
				ddp.waitToPickup++;
				if(ddp.player.readyweapon is "playerInventory") 
				{ 
						playerInventory(ddp.player.readyweapon).sW.nullify();
						playerInventory(ddp.player.readyweapon).storedIndex = -1;				
				}
				self.GoAwayAndDie();
				return true;
			}
			else
			{
				ddp.waitToPickup++;
				return false;
			}
		}
		
	}
	
	
	protected bool AddToDDPlayer(Actor wanter)
	{
		if(!(wanter is "ddPlayer")) { return false; }
		let ddp = ddPlayer(wanter);
		let lWeap = ddp.GetLeftWeapons();
		let rWeap = ddp.GetRightWeapons();
		let pInv = ddp.GetWeaponsInventory();
		let flst = ddp.GetFistList();
		let pspl = ddp.player.GetPSprite(PSP_LEFTW);
		let psplf = ddp.player.GetPSprite(PSP_LEFTWF);
		let pspr = ddp.player.GetPSprite(PSP_RIGHTW);
		let psprf = ddp.player.GetPSprite(PSP_RIGHTWF);
		let mode = ddWeapon(ddp.player.readyweapon);
		ddWeapon goner;
		if(ddp.ddWeaponState & DDW_WANNAREPLACE)
		{
			if(ddp.ddWeaponState & DDW_REPLACELEFT)
			{
				goner = ddWeapon(lWeap.RetItem(ddp.lwx));
				for(int x = 0; x < pInv.items.size(); x++)
				{
					if(pInv.RetItem(x).weaponName == "emptie")
					{
						//store
						if(!(goner is "ddFist")) { 
							ddp.A_Print("Stored "..goner.GetTag());
							pInv.RetItem(x).construct(goner.GetParentType(), goner.rating, goner.GetWeaponSprite(), goner.mag, goner.ddWeaponFlags); 
						}
						let comer = ddWeapon(Spawn(self.GetClassName().."Left"));
						if(wanter is "ddPlayerClassic") { comer.sFactor = 1.0; }
						comer.AmmoGive1 = self.AmmoGive1;
						comer.mag = self.mag;
						comer.ddWeaponFlags = self.ddWeaponFlags;
						comer.AttachToOwner(wanter);
						if(comer.bTwoHander) { ddp.ddWeaponState |= DDW_LEFTISTH; }
						else { ddp.ddWeaponState &= ~DDW_LEFTISTH; }
						wanter.player.setpsprite(PSP_LEFTW, ddp.GetLeftWeapon(ddp.lwx).GetUpState());
						mode.swapHeld = ddWeapon(comer);
						wanter.A_Print(""..goner.GetTag().." stored, replaced with "..comer.GetTag());
						ddp.ddWeaponState |= DDW_LEFTNOBOBBING;
						ddp.ddWeaponState &= ~DDW_LEFTREADY;
						ddp.ddWeaponState &= ~DDW_WANNAREPLACE;
						mode.bmodeready = false;
						mode.ChangeState("PickupSwapStore");
						return true;
					}
				}
				//drop
				if(!(lWeap.RetItem(ddp.lwx) is "ddFist"))
				{
					goner = ddWeapon(Spawn(lWeap.RetItem(ddp.lwx).GetParentType()));
					goner.AmmoGive1 = 0;
					goner.mag = ddWeapon(lWeap.RetItem(ddp.lwx)).mag;
					goner.ddWeaponFlags = ddWeapon(lWeap.RetItem(ddp.lwx)).ddWeaponFlags;
					goner.AttachToOwner(ddp);
					ddp.DropInventory(goner);
					ddp.RemoveInventory(lWeap.RetItem(ddp.lwx));
					wanter.A_Print(""..goner.GetTag().." dropped.");
				}
				let comer = ddWeapon(Spawn(self.GetClassName().."Left"));
				if(wanter is "ddPlayerClassic") { comer.sFactor = 1.0; }
				comer.AmmoGive1 = self.AmmoGive1;
				comer.mag = self.mag;
				comer.ddWeaponFlags = self.ddWeaponFlags;
				comer.AttachToOwner(wanter);
				if(comer.bTwoHander) { ddp.ddWeaponState |= DDW_LEFTISTH; }
				else { ddp.ddWeaponState &= ~DDW_LEFTISTH; }
				pspl.y = 128; psplf.y = 128;
				lWeap.SetItem(ddWeapon(comer), ddp.lwx);
				rWeap.RetItem(ddp.rwx).companionpiece = lWeap.RetItem(ddp.lwx);
				lWeap.RetItem(ddp.lwx).companionpiece = rWeap.RetItem(ddp.rwx);
				wanter.player.setpsprite(PSP_LEFTW, ddp.GetLeftWeapon(ddp.lwx).GetUpState());
				if(comer.UpSound) { wanter.A_StartSound(comer.UpSound, CHAN_WEAPON); }
				ddp.ddWeaponState |= DDW_LEFTNOBOBBING;
				ddp.ddWeaponState &= ~DDW_WANNAREPLACE;
				mode.bmodeready = false;
				mode.ChangeState("PickupSwapDrop");
				return true;
			}
			
			else if(ddp.ddWeaponState & DDW_REPLACERIGHT)
			{
				goner = ddWeapon(rWeap.RetItem(ddp.rwx)); 
				for(int x = 0; x < pInv.items.size(); x++)
				{
					if(pInv.RetItem(x).weaponName == "emptie")
					{
						//store
						if(!(goner is "ddFist")) {
							ddp.A_Print("Stored "..goner.GetTag());
							pInv.RetItem(x).construct(goner.GetParentType(), goner.rating, goner.GetWeaponSprite(), goner.mag, goner.ddWeaponFlags);
						}
						let comer = ddWeapon(Spawn(self.GetClassName().."Right"));
						if(wanter is "ddPlayerClassic") { comer.sFactor = 1.0; }
						comer.AmmoGive1 = self.AmmoGive1;
						comer.mag = self.mag;
						comer.ddWeaponFlags = self.ddWeaponFlags;
						comer.AttachToOwner(wanter);
						if(comer.bTwoHander) { ddp.ddWeaponState |= DDW_RIGHTISTH; }
						else { ddp.ddWeaponState &= ~DDW_RIGHTISTH; }
						wanter.player.setpsprite(PSP_RIGHTW, ddp.GetRightWeapon(ddp.rwx).GetUpState());
						mode.swapHeld = ddWeapon(comer);
						wanter.A_Print(""..goner.GetTag().." stored, replaced with "..comer.GetTag());
						ddp.ddWeaponState &= ~DDW_RIGHTREADY;
						ddp.ddWeaponState |= DDW_RIGHTNOBOBBING;
						ddp.ddWeaponState &= ~DDW_WANNAREPLACE;
						mode.bmodeready = false;
						mode.ChangeState("PickupSwapStore");
						return true;
					}
				}
				//drop
				if(!(rWeap.RetItem(ddp.rwx) is "ddFist"))
				{
					ddp.A_Log("Dropped "..goner.GetTag());
					goner = ddWeapon(Spawn(rWeap.RetItem(ddp.rwx).GetParentType()));
					goner.AmmoGive1 = 0;
					goner.mag = ddWeapon(rWeap.RetItem(ddp.rwx)).mag;
					goner.ddWeaponFlags = ddWeapon(rWeap.RetItem(ddp.rwx)).ddWeaponFlags;
					goner.AttachToOwner(ddp);
					ddp.DropInventory(goner);
					ddp.RemoveInventory(rWeap.RetItem(ddp.rwx));
					wanter.A_Print(""..goner.GetTag().." dropped.");
				}
				let comer = ddWeapon(Spawn(self.GetClassName().."Right"));
				if(wanter is "ddPlayerClassic") { comer.sFactor = 1.0; }
				comer.AmmoGive1 = self.AmmoGive1;
				comer.mag = self.mag;
				comer.ddWeaponFlags = self.ddWeaponFlags;
				comer.AttachToOwner(wanter);
				if(comer.bTwoHander) { ddp.ddWeaponState |= DDW_RIGHTISTH; }
				else { ddp.ddWeaponState &= ~DDW_RIGHTISTH; }
				pspr.y = 128; psprf.y = 128;
				rWeap.SetItem(ddWeapon(comer), ddp.rwx);
				rWeap.RetItem(ddp.rwx).companionpiece = lWeap.RetItem(ddp.lwx);
				lWeap.RetItem(ddp.lwx).companionpiece = rWeap.RetItem(ddp.rwx);						
				wanter.player.setpsprite(PSP_RIGHTW, ddp.GetRightWeapon(ddp.rwx).GetUpState());	
				if(comer.UpSound) { wanter.A_StartSound(comer.UpSound, CHAN_WEAPON); }
				ddp.ddWeaponState |= DDW_RIGHTNOBOBBING;
				ddp.ddWeaponState &= ~DDW_WANNAREPLACE;
				mode.bmodeready = false;
				mode.ChangeState("PickupSwapDrop");	
				return true;			
			}
			
			else { return false; }
		}
		else
		{
			if(pInv.AddWeapon(self) == false) { ddp.A_Log("Inventory full"); return false; }
			else 
			{ 
				Class<Ammo> myammo1 = (ddp is "ddPlayerNormal") ? AmmoType1 : ClassicAmmoType1;
				Class<Ammo> myammo2 = (ddp is "ddPlayerNormal") ? AmmoType2 : ClassicAmmoType2;
				AddAmmo(ddp, myammo1, ammogive1); AddAmmo(ddp, myammo2, ammogive2); 
			}
			if(CVar.GetCVar("pl_autosort",ddp.player).GetBool()) { ddp.SortInv(); }
			return true;			
		}
	}
	
	override void AttachToOwner(Actor other)
	{
		BecomeItem();
		other.AddInventory(self);
		Class<Ammo> myammo1 = (other is "ddPlayerNormal") ? AmmoType1 : ClassicAmmoType1;
		Class<Ammo> myammo2 = (other is "ddPlayerNormal") ? AmmoType2 : ClassicAmmoType2;
		Ammo1 = AddAmmo(other, myammo1, ammogive1);
		Ammo2 = AddAmmo(other, myammo2, ammogive2);
	}
	
	override void Touch(Actor toucher) 
	{ 
		if(toucher is "ddPlayerClassic")
		{
			if(AmmoGive1 > 0) 
			{ 
				toucher.A_Log("+"..AmmoGive1.." "..ClassicAmmoType1.GetClassName());
				toucher.GiveInventory(ClassicAmmoType1, AmmoGive1); AmmoGive1 = 0; 
				PlayPickupSound(toucher);
				if(!bNoScreenFlash && toucher.player.playerstate != PST_DEAD)
				{
					toucher.player.bonuscount = BONUSADD;
				}
			}
		}
		return;
	} 
	
	// ##goto action button checks()
	action bool A_PressingRightFire()
	{
		let own = ddPlayer(self); 
		let i = invoker;
		i.GetCVars();
		if(!i.wolfen) { return (player.cmd.buttons & BT_ATTACK); }
		else if(i.wolfen && !i.swapc && !i.altmodeR) { return (player.cmd.buttons & BT_ATTACK); }
		else if(i.wolfen && i.swapc && !i.altmodeR) 
		{ 
			if(player.readyweapon is "twoHanding") { return (player.cmd.buttons & BT_ATTACK); }
			else { return (player.cmd.buttons & BT_ALTATTACK); }
		}
		else { return false; }
	}
	action bool A_PressingRightAltFire()
	{ 
		let own = ddPlayer(self);
		let i = invoker;
		i.GetCVars();
		if(!i.wolfen) { return (player.cmd.buttons & BT_ALTATTACK); }
		else if(i.wolfen && !i.swapc && i.altmodeR) { return (player.cmd.buttons & BT_ATTACK); }		
		else if(i.wolfen && i.swapc && i.altmodeR) 
		{ 
			if(player.readyweapon is "twoHanding") { return (player.cmd.buttons & BT_ATTACK); }
			else { return (player.cmd.buttons & BT_ALTATTACK); }
		}
		else { return false; }
	}
	action bool A_PressingLeftFire() 
	{ 
		let own = ddPlayer(self);
		let i = invoker;
		i.GetCVars();
		if(!i.wolfen) { return (player.cmd.buttons & BT_LEFTFIRE); }
		else if(i.wolfen && !i.swapc && !i.altmodeL) { return (player.cmd.buttons & BT_ALTATTACK); }
		else if(i.wolfen && i.swapc && !i.altmodeL) { return (player.cmd.buttons & BT_ATTACK); }
		else { return false; }
	}
	action bool A_PressingLeftAltFire() 
	{ 
		let own = ddPlayer(self);
		let i = invoker;
		i.GetCVars();
		if(!i.wolfen) { return (player.cmd.buttons & BT_LEFTALT); }
		else if(i.wolfen && !i.swapc && i.altmodeL) { return (player.cmd.buttons & BT_ALTATTACK); }
		else if(i.wolfen && i.swapc && i.altmodeL) { return (player.cmd.buttons & BT_ATTACK); }
		else { return false; }
	}	
	
	action bool A_PressingFireButton() { return (A_PressingRightFire() || A_PressingRightAltFire() || A_PressingLeftFire() || A_PressingLeftAltFire()); }
	
	action bool A_PressingLeftModeSwitch()
	{
		let i = invoker;
		i.GetCVars();
		if(i.wolfen && !i.swapc) { return (player.cmd.buttons & BT_LEFTFIRE); }
		else if(i.wolfen && i.swapc) { return (player.cmd.buttons & BT_LEFTFIRE); }
		else { return false; }
	}
	action bool A_PressingRightModeSwitch()
	{
		let i = invoker;
		i.GetCVars();
		if(i.wolfen && !i.swapc) { return (player.cmd.buttons & BT_LEFTALT); }
		else if(i.wolfen && i.swapc) { return (player.cmd.buttons & BT_LEFTALT); }
		else { return false; }		
	}
	
	action bool A_PressingReload() { return (player.cmd.buttons & BT_RELOAD); }
	
	action bool A_PressingZoom() { return (player.cmd.buttons & BT_ZOOM); }
	
	
	// ##goto button checks()
	bool PressingRightFire() 
	{
		let own = ddPlayer(owner); 
		GetCVars();
		if(!wolfen) { return (own.player.cmd.buttons & BT_ATTACK); }
		else if(wolfen && !swapc && !altmodeR) { return (own.player.cmd.buttons & BT_ATTACK); }
		else if(wolfen && swapc && !altmodeR) 
		{ 
			if(own.player.readyweapon is "twoHanding") { return (own.player.cmd.buttons & BT_ATTACK); }
			else { return (own.player.cmd.buttons & BT_ALTATTACK); }
		}
		else { return false; }
	}
	bool PressingRightAltFire()
	{ 
		let own = ddPlayer(owner);
		GetCVars();
		if(!wolfen) { return (own.player.cmd.buttons & BT_ALTATTACK); }
		else if(wolfen && !swapc && altmodeR) { return (own.player.cmd.buttons & BT_ATTACK); }		
		else if(wolfen && swapc && altmodeR) 
		{ 
			if(own.player.readyweapon is "twoHanding") { return (own.player.cmd.buttons & BT_ATTACK); }
			else { return (own.player.cmd.buttons & BT_ALTATTACK); }
		}
		else { return false; }
	}
	bool PressingLeftFire() 
	{ 
		let own = ddPlayer(owner);
		GetCVars();
		if(!wolfen) { return (own.player.cmd.buttons & BT_LEFTFIRE); }
		else if(wolfen && !swapc && !altmodeL) { return (own.player.cmd.buttons & BT_ALTATTACK); }
		else if(wolfen && swapc && !altmodeL) { return (own.player.cmd.buttons & BT_ATTACK); }
		else { return false; }
	}
	bool PressingLeftAltFire() 
	{ 
		let own = ddPlayer(owner);
		GetCVars();
		if(!wolfen) { return (own.player.cmd.buttons & BT_LEFTALT); }
		else if(wolfen && !swapc && altmodeL) { return (own.player.cmd.buttons & BT_ALTATTACK); }
		else if(wolfen && swapc && altmodeL) { return (own.player.cmd.buttons & BT_ATTACK); }
		else { return false; }
	}		
	bool PressingFireButton() { return (PressingRightFire() || PressingRightAltFire() || PressingLeftFire() ||  PressingLeftAltFire()); }
	
	action bool PressingRightSwitch() { let own = ddPlayer(invoker.owner); return (own.player.cmd.buttons & BT_RIGHTSWITCH); }
	action bool PressingLeftSwitch() { let own = ddPlayer(invoker.owner); return (own.player.cmd.buttons & BT_LEFTSWITCH); }
	action bool PressingReload() { let own = ddPlayer(invoker.owner); return (own.player.cmd.buttons & BT_RELOAD); }
	bool PressingZoom() { let own = ddPlayer(owner); return (own.player.cmd.buttons & BT_ZOOM); }
	// ##goto weapon getters()	
	
	void GetCVars()
	{		
		debuggin = CVar.GetCVar("pl_debug", owner.player).GetBool();
		wolfen = CVar.GetCVar("pl_wolfen", owner.player).GetBool();
		swapc = CVar.GetCVar("pl_wolfcontrols", owner.player).GetBool();
		altmodeL = ddPlayer(owner).altmodeL; //ik these arent cvars
		altmodeR = ddPlayer(owner).altmodeR;
	}
	
	protected String GetLootedAmmo()
	{
		if(AmmoGive1 == 0)
		{
			return "(+nothing!)";
		}
		else
		{
			return "(+"..AmmoGive1..")";
		}
	}
	
	virtual State GetAttackState()
	{
		if(!bAltFire) { return FindState('Fire'); }
		else { return FindState('Altfire'); }
	}
	
	virtual State GetFlashState()
	{
		if(!bAltFire) { return FindState('FlashP'); }
		else { return FindState('FlashA'); }
	}
	
	virtual State GetRefireState()
	{
		if(!bAltFire) { return FindState('Fire'); }
		else { return FindState('Altfire'); }
	}
	
	virtual State wannaReload()
	{
		return FindState('DoNotJump');
	}
	
	virtual int GetTicks()
	{
		return 0;
	}
	
	virtual clearscope String GetWeaponSprite() { return ""; }
	
	int GetRating()
	{
		return rating;
	}
	
	virtual String GetParentType()
	{
		return "Weapon";
	}
	
	virtual String, int GetSprites(int forcemode = -1)
	{
		return "TNT1A0", -1;
	}
	
	clearscope virtual TextureID GetFireModeIcon()
	{
		return TexMan.CheckForTexture("TNT1");
	}
	
	virtual void DD_WeapAction(int no)
	{
		if(owner) { owner.A_Log("No action defined for tic "..no); }
	}
	
	virtual void DD_WeapSound(int no)
	{
		if(owner) { owner.A_Log("No sound defined for tic "..no); }
	}
	
	virtual State GetWeapState(int no)
	{
		if(owner) { owner.A_Log("No state defined for tic "..no); }
		return FindState('DoNotJump');
	}
	
	int ModeCheck(int esoaCost = -1)
	{
		let ddp = ddPlayer(owner);
		let mode = ddWeapon(ddp.player.readyweapon);
		let cpiece = ddWeapon(companionpiece);
		if(ddp.FindInventory("ClassicModeToken")) { return 4; }
		if(mode is "twoHanding") { return 1; }
		else if(mode is "dualWielding") 
		{
			let cost = (bAltFire) ? ChargeUse2 : ChargeUse1;
			if(esoaCost > -1) { cost = esoaCost; }
			let am = (bAltFire) ? AmmoType2 : AmmoType1;
			let au = (bAltFire) ? AmmoUse2 : AmmoUse1;
			if(!cpiece.weaponready) { au += ((cpiece.bAltFire) ? AmmoUse2 : AmmoUse1); }
			if(ddp.CheckESOA(cost) && ddp.CountInv(am) >= au) { ddp.TakeInventory("ESOACharge", cost); return 3; }
			else { return 2; }
		}
		else { return 0; }		
	}
	
	virtual ui void PreviewInfo(ddStats ddhud)
	{
		let hud = ddhud;
		hud.DrawString(hud.fa, "n/a", (30, 45), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);		
	}
	
	virtual ui void InventoryInfo(ddStats ddhud)
	{
		let hud = ddhud;
		hud.DrawString(hud.fa, "n/a", (30, 45), hud.DI_SCREEN_CENTER | hud.DI_TEXT_ALIGN_LEFT);
	}
	
	// ##goto weapon setters() 
	
	//commmon combos
	//todo: update these to utilize tic definitions
	action void A_ComShot() { let ddp = ddPlayer(invoker.owner); ddp.combo = COM_SHOT; ddp.comboTimer = 35; }
	
	action void A_ClearCombo() { let ddp = ddPlayer(invoker.owner); ddp.combo = 0; }
	
	// ##goto weapon actions()
	
	//extra stuff called by weapon modes. 1 = left, 0 = right
	virtual void OnWeaponFire(int side, bool held) {} 

	//do things when autoreloading after travelled is called
	virtual void OnAutoReload() {}
	
	//do things when initTwoHanding/initDualWielding is called
	virtual void onInit() {}
	
	//apply bonuses during berserk
	virtual void WhileBerserk() {} 
		
	action void A_ChangeSprite(int forcemode = -1)
	{
		let ddp = ddPlayer(invoker.owner);
		if(!ddp) { return; }
		ddWeapon weap;
		PSprite psp;
		if(stateinfo.mPSPIndex == PSP_LEFTW) {
			weap = ddp.GetLeftWeapon(ddp.lwx);
			psp = ddp.player.GetPSprite(PSP_LEFTW);
		}
		else if(stateinfo.mPSPIndex == PSP_RIGHTW) {
			weap = ddp.GetRightWeapon(ddp.rwx);
			psp = ddp.player.GetPSprite(PSP_RIGHTW);
		}
		else { console.printf("PSprite not a weapon sprite"); return; }
		String sp;
		int fr;
		[sp, fr] = weap.GetSprites(forcemode);
		psp.Sprite = GetSpriteIndex(sp);
		if(fr > 0) { psp.Frame = fr; }
	}
	
	action void A_ChangeSpriteLeft(int forcemode = -1)
	{
		let ddp = ddPlayer(invoker.owner);
		if(ddp.ddWeaponState & DDW_NOLEFTSPRITECHANGE) { return; }
		let lw = ddp.GetLeftWeapon(ddp.lwx);
		let pspl = ddp.player.GetPSprite(PSP_LEFTW);
		String sp;
		int fr;
		[sp, fr] = lw.GetSprites(forcemode);
		pspl.Sprite = GetSpriteIndex(sp);		
		if(fr > 0) { pspl.Frame = fr; }
	}
	
	action void A_ChangeSpriteRight(int forcemode = -1)
	{
		let ddp = ddPlayer(invoker.owner);
		if(ddp.ddWeaponState & DDW_NORIGHTSPRITECHANGE) { return; }
		let rw = ddp.GetRightWeapon(ddp.rwx);
		let pspr = ddp.player.GetPSprite(PSP_RIGHTW);
		String sp;
		int fr;
		[sp, fr] = rw.GetSprites(forcemode);
		pspr.Sprite = GetSpriteIndex(sp);
		if(fr > 0) { pspr.Frame = fr; }
	}
	
	void ChangeState(statelabel st, int layer = PSP_WEAPON)
	{
		let own = ddPlayer(owner);
		let psp = own.player.GetPSprite(layer);
		if(own.player) {
			//own.player.SetPSprite(layer, FindState(st));
			psp.SetState(FindState(st));
		}
	}
	action void A_ChangeState(statelabel st, int layer = PSP_WEAPON)
	{
		if(player)
			player.SetPSprite(layer, invoker.FindState(st));
	}
	
	//used for weapon states
	
	action void A_SetWeapState()
	{
		let ddp = ddPlayer(invoker.owner);
		if(!ddp) { return; }
		ddWeapon weap;
		PSprite psp;
		if(stateinfo.mPSPIndex == PSP_LEFTW) {
			weap = ddp.GetLeftWeapon(ddp.lwx);
			psp = ddp.player.GetPSprite(PSP_LEFTW);
		}
		else if(stateinfo.mPSPIndex == PSP_RIGHTW) {
			weap = ddp.GetRightWeapon(ddp.rwx);
			psp = ddp.player.GetPSprite(PSP_RIGHTW);
		}
		int no = psp.tics;
		psp.tics = 0;
		let st = weap.GetWeapState(no);
		if(st == weap.FindState('DoNotJump')) { return; }
		else { psp.SetState(st); }
	}
	
	action void A_WeapSetStateLeft()
	{
		let own = ddPlayer(invoker.owner);
		if(own)
		{
			let lw = own.GetLeftWeapon(own.lwx);
			let psp = own.player.GetPSprite(PSP_LEFTW);
			int no = psp.tics;
			psp.tics = 0;
			let st = lw.GetWeapState(no);
			if(st == lw.FindState('DoNotJump')) { return; }
			else { psp.SetState(st); }
		}
	}
	
	action void A_WeapSetStateRight()
	{
		let own = ddPlayer(invoker.owner);
		if(own)
		{
			let rw = own.GetRightWeapon(own.rwx);
			let psp = own.player.GetPSprite(PSP_RIGHTW);
			int no = psp.tics;
			psp.tics = 0;
			let st = rw.GetWeapState(no);
			if(st == rw.FindState('DoNotJump')) { return; }
			else { psp.SetState(st); }
		}
	}
	
	action void AddRecoil(double pitch, int angle, double desFOV)
	{
		let ddp = ddPlayer(invoker.owner);
		if(ddp.FindInventory("ClassicModeToken")) { return; }
		//visual recoil decrements when addpitch is zero, so physical recoil is 
		//disabled in ddPlayer.Tick()
		if(ddp.visrec)
		{
			int dF = clamp(desFOV, 0.1, 5.0);
			if(ddp.player.FOV < (ddp.plFOV + 5.)) { ddp.player.DesiredFOV += dF; } 
			else { ddp.player.DesiredFOV = (ddp.plFOV + 5.); }			
		}		
		ddp.AddPitch = pitch;
		ddp.AddAngle = ((random2() * angle) >> 8);
	}
	
	//todo: wrap ddWeaponState flag switching to a function similar to base WeaponReady
	action void A_DDWeaponReady(bool playUpSound = true)
	{
		let ddp = ddPlayer(self);
		if(!ddp) { return; }
		ddWeapon weap;
		if(stateinfo.mPSPIndex == PSP_LEFTW) { 
			weap = ddp.GetLeftWeapon(ddp.lwx);
			ddp.ddWeaponState |= DDW_LEFTREADY;
			ddp.ddWeaponState |= DDW_LEFTBOBBING;
			ddp.ddWeaponState &= ~DDW_LEFTNOBOBBING;
		}
		else if(stateinfo.mPSPIndex == PSP_RIGHTW) { 
			weap = ddp.GetRightWeapon(ddp.rwx);
			ddp.ddWeaponState |= DDW_RIGHTREADY;
			ddp.ddWeaponState |= DDW_RIGHTBOBBING;
			ddp.ddWeaponState &= ~DDW_RIGHTNOBOBBING;
		}
		if(weap.ReadySound && playUpSound) {
			if(weap.bReadySndHalf || random() < 128) { ddp.A_StartSound(weap.ReadySound, CHAN_WEAPON); }
		}
		weap.weaponStatus = DDW_READY;
		weap.weaponReady = true;
	}
	
	action void A_LeftWeaponReady(bool playUpSound = true)
	{
		let ddp = ddPlayer(self);
		let lw = ddp.GetLeftWeapon(ddp.lwx);
		if(lw.ReadySound && playUpSound)
		{
			if(!lw.breadysndhalf || random() < 128) { ddp.A_StartSound(lw.readysound, CHAN_WEAPON); }
		}
		ddp.ddWeaponState |= DDW_LEFTREADY;
		ddp.ddWeaponState |= DDW_LEFTBOBBING;
		ddp.ddWeaponState &= ~DDW_LEFTNOBOBBING;
		lw.weaponStatus = DDW_READY;
		lw.weaponready = true;
		lw.caseno = 0;
		lw.sndno = 0;
	}
	
	action void A_RightWeaponReady(bool playUpSound = true)
	{
		let ddp = ddPlayer(Self);
		let rw = ddp.GetRightWeapon(ddp.rwx);
		if(rw.ReadySound && playUpSound)
		{
			if(!rw.breadysndhalf || random() < 128) { ddp.A_StartSound(rw.readysound, CHAN_WEAPON); }
		}
		ddp.ddWeaponState |= DDW_RIGHTREADY;
		ddp.ddWeaponState |= DDW_RIGHTBOBBING;
		ddp.ddWeaponState &= ~DDW_RIGHTNOBOBBING;
		rw.weaponStatus = DDW_READY;
		rw.weaponready = true;
		rw.caseno = 0;
		rw.sndno = 0;
	}
	
	
	action void A_SetModeReady() { ddWeapon(player.readyweapon).bModeReady = true; }
	
	virtual void primaryattack() {}
	
	virtual void alternativeattack() {}
	
	action void A_FireDDWeapon()
	{
		let ddp = ddPlayer(self);
		if(!ddp) { return; }
		ddWeapon weap;
		if(stateinfo.mPSPIndex == PSP_LEFTW) { 
			weap = ddp.GetLeftWeapon(ddp.lwx);
			if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { 
				ddp.A_Log((weap.bAltFire) ? "Left alternative attack" : "Left primary attack"); 
			}
		}
		else if(stateinfo.mPSPIndex == PSP_RIGHTW) { 
			weap = ddp.GetRightWeapon(ddp.rwx);
			if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { 
				ddp.A_Log((weap.bAltFire) ? "Right alternative attack" : "Right primary attack"); 
			}
		}
		if(!weap.bAltFire) { weap.PrimaryAttack(); }
		else { weap.AlternativeAttack(); }
	}
	
	action void A_FireLeftWeapon()
	{
		let ddp = ddPlayer(self);
		let lWeap = ddp.GetLeftWeapon(ddp.lwx);	
		if(!lWeap.bAltFire) { 		
		if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("Left primary attack"); }
		lWeap.PrimaryAttack(); }
		else {
		if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("Left alternative attack"); }
		lWeap.AlternativeAttack(); }
	}
	
	action void A_FireRightWeapon()
	{
		let ddp = ddPlayer(self);
		let rWeap = ddp.GetRightWeapon(ddp.rwx);
		if(!rWeap.bAltFire) { 
		if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("Right primary attack"); }
		rWeap.PrimaryAttack(); }
		else { 
		if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("Right alternative attack"); }
		rWeap.AlternativeAttack(); }
	}
	
	action void A_DDFlash()
	{
		let ddp = ddPlayer(self);
		if(!ddp) { return; }
		ddWeapon weap;
		int pid;
		if(stateinfo.mPSPIndex == PSP_LEFTW) { 
			weap = ddp.GetLeftWeapon(ddp.lwx);
			pid = PSP_LEFTWF;
		}
		else if(stateinfo.mPSPIndex == PSP_RIGHTW) { 
			weap = ddp.GetRightWeapon(ddp.rwx);
			pid = PSP_RIGHTWF;
		}
		State st = weap.GetFlashState();
		if(st == weap.FindState('NoFlash')) { return; }
		ddp.PlayAttacking2();
		player.SetPSprite(pid, st);		
	}
	
	action void A_FlashLeft()
	{
		let ddp = ddPlayer(self);
		let lWeap = ddp.GetLeftWeapon(ddp.lwx);
		State st = lWeap.GetFlashState();
		if(st == lWeap.FindState('NoFlash')) { if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { A_Log("Left flash disabled"); } return; }
		ddp.PlayAttacking2();
		player.SetPSprite(PSP_LEFTWF, st);
	}
	
	action void A_FlashRight()
	{	
		let ddp = ddPlayer(self);
		let rWeap = ddp.GetRightWeapon(ddp.rwx);
		State st = rWeap.GetFlashState();
		if(st == rWeap.FindState('NoFlash')) { if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { A_Log("Right flash disabled"); } return; }
		ddp.PlayAttacking2();
		player.SetPSprite(PSP_RIGHTWF, st); 
		
	}
	
	virtual void OnRefire() {}
	//heavy refires cannot be completed if button is held down
	
	action void A_DDRefire()
	{
		let ddp = ddPlayer(self);
		if(!ddp) { return; }
		ddWeapon weap;
		PSprite psp;
		bool bPress;
		if(stateinfo.mPSPIndex == PSP_LEFTW) { 
			weap = ddp.GetLeftWeapon(ddp.lwx);
			psp = ddp.player.GetPSprite(PSP_LEFTW);
			bPress = (!weap.bAltFire) ? A_PressingLeftFire() : A_PressingLeftAltFire();
		}
		else if(stateinfo.mPSPIndex == PSP_RIGHTW) { 
			weap = ddp.GetRightWeapon(ddp.rwx);
			psp = ddp.player.GetPSprite(PSP_RIGHTW);
			bPress = (!weap.bAltFire) ? A_PressingRightFire() : A_PressingRightAltFire();
		}
		State st = weap.GetRefireState();
		if(player.ReadyWeapon is "playerInventory") { return; }
		if(!(player.weaponState & (WF_QUICKLEFTOK | WF_QUICKRIGHTOK)) && invoker.bModeReady && bPress && player.health > 0)
		{
			player.refire++;
			if(st == weap.FindState('DoNotJump')) { return; }
			else { weap.weaponStatus = (!weap.bAltFire) ? DDW_FIRING : DDW_ALTFIRING; psp.SetState(st); weap.OnRefire(); }
		}
	}
	
	action void A_DDHeavyRefire()
	{
		let ddp = ddPlayer(self);
		if(!ddp) { return; }
		let mode = ddWeapon(player.readyweapon);
		ddWeapon weap;
		PSprite psp;
		bool bPress;
		bool bHold;
		if(stateinfo.mPSPIndex == PSP_LEFTW) {
			weap = ddp.GetLeftWeapon(ddp.lwx);
			psp = ddp.player.GetPSprite(PSP_LEFTW);
			bPress = (!weap.bAltFire) ? A_PressingLeftFire() : A_PressingLeftAltFire();
			bhold = mode.leftheld;
		}
		else if(stateinfo.mPSPIndex == PSP_RIGHTW) {
			weap = ddp.GetRightWeapon(ddp.rwx);
			psp = ddp.player.GetPSprite(PSP_RIGHTW);
			bPress = (!weap.bAltFire) ? A_PressingRightFire() : A_PressingRightAltFire();
			bHold = mode.rightheld;
		}
		if(bHold) { console.printf("fire button held"); return; }
		State st = weap.GetRefireState();
		if(player.ReadyWeapon is "playerInventory") { return; }
		if(!(player.weaponState & (WF_QUICKLEFTOK | WF_QUICKRIGHTOK)) && invoker.bModeReady && bPress & player.health > 0)
		{
			player.refire++;
			if(st == weap.FindState('DoNotJump')) { return; }
			else { weap.weaponStatus = (!weap.bAltFire) ? DDW_FIRING : DDW_ALTFIRING; psp.SetState(st); weap.OnRefire(); }
		}
	}
	
	action void A_ddRefireLeft()
	{
		let ddp = ddPlayer(self);
		let pspl = player.GetPSprite(PSP_LEFTW);
		let lWeap = ddp.GetLeftWeapon(ddp.lwx);
		State st = lWeap.GetRefireState();
		if(ddp.player.readyweapon is "playerInventory") { return; }
		if(!(player.weaponstate & (WF_QUICKLEFTOK | WF_QUICKRIGHTOK)) && invoker.bmodeReady == true && !lWeap.bAltFire && A_PressingLeftFire() && player.health > 0)
		{ 	
			if(ddp.dddebug & DBG_WEAPSEQUENCE) { A_Log("Left refire!"); } 
			player.refire++; 
			if(st == lWeap.FindState('DoNotJump')) { return; }
			else { lWeap.weaponstatus = DDW_FIRING; player.SetPSprite(PSP_LEFTW, st); lWeap.OnRefire(); }
		}
		else if(!(player.weaponstate & (WF_QUICKLEFTOK | WF_QUICKRIGHTOK)) && invoker.bmodeReady == true && lWeap.bAltFire && A_PressingLeftAltFire() && player.health > 0)
		{ 
			if(ddp.dddebug & DBG_WEAPSEQUENCE) { A_Log("Left alt refire!"); }
			player.refire++; 
			if(st == lWeap.FindState('DoNotJump')) { return; }
			else { lWeap.weaponstatus = DDW_ALTFIRING; player.SetPSprite(PSP_LEFTW, st); lWeap.OnRefire(); }
		}
		else { player.refire = 0; if(ddp.dddebug & DBG_WEAPSEQUENCE) { A_Log("Refire left ignored!"); } }		
	}
	
	action void A_ddRefireLeftHeavy()
	{
		let ddp = ddPlayer(self);
		let pspl = player.GetPSprite(PSP_LEFTW);
		let lWeap = ddp.GetLeftWeapon(ddp.lwx);
		let mode = ddWeapon(ddp.player.readyweapon);
		State st = lWeap.GetRefireState();
		if(ddp.player.readyweapon is "playerInventory") { return; }
		if(mode.leftHeld) { return; }
		if(!(player.weaponstate & (WF_QUICKLEFTOK | WF_QUICKRIGHTOK)) && invoker.bmodeReady == true && !lWeap.bAltFire && A_PressingLeftFire() && player.health > 0)
		{ 	
			if(ddp.dddebug & DBG_WEAPSEQUENCE) { A_Log("Left refire!"); } 
			player.refire++; 
			if(st == lWeap.FindState('DoNotJump')) { return; }
			else { lWeap.weaponstatus = DDW_FIRING; player.SetPSprite(PSP_LEFTW, st); lWeap.OnRefire(); }
		}
		else if(!(player.weaponstate & (WF_QUICKLEFTOK | WF_QUICKRIGHTOK)) && invoker.bmodeReady == true && lWeap.bAltFire && A_PressingLeftAltFire() && player.health > 0)
		{ 
			if(ddp.dddebug & DBG_WEAPSEQUENCE) { A_Log("Left alt refire!"); }
			player.refire++; 
			if(st == lWeap.FindState('DoNotJump')) { return; }
			else { lWeap.weaponstatus = DDW_ALTFIRING; player.SetPSprite(PSP_LEFTW, st); lWeap.OnRefire(); }
		}
		else { player.refire = 0; if(ddp.dddebug & DBG_WEAPSEQUENCE) { A_Log("Refire left ignored!"); } }	
	}
	
	action void A_ddRefireRight()
	{		
		let ddp = ddPlayer(self);
		let pspr = player.GetPSprite(PSP_RIGHTW);
		let rWeap = ddp.GetRightWeapon(ddp.rwx);
		State st = rWeap.GetRefireState();
		if(ddp.player.readyweapon is "playerInventory") { return; }
		if(!(player.weaponstate & (WF_QUICKLEFTOK | WF_QUICKRIGHTOK)) && invoker.bmodeReady == true && !rWeap.bAltFire && A_PressingRightFire() && player.health > 0)
		{ 
			if(ddp.dddebug & DBG_WEAPSEQUENCE) { A_Log("Right refire!"); } 
			player.refire++; 
			if(st == rWeap.FindState('DoNotJump')) { return; }
			else { rWeap.weaponstatus = DDW_FIRING; player.SetPSprite(PSP_RIGHTW, st); rWeap.OnRefire(); }
		}
		else if(!(player.weaponstate & (WF_QUICKLEFTOK | WF_QUICKRIGHTOK)) && invoker.bmodeReady == true && rWeap.bAltFire && A_PressingRightAltFire() && player.health > 0)
		{ 
			if(ddp.dddebug & DBG_WEAPSEQUENCE) { A_Log("Right alt refire!"); } 
			player.refire++;
			if(st == rWeap.FindState('DoNotJump')) { return; }
			else { rWeap.weaponstatus = DDW_ALTFIRING; player.SetPSprite(PSP_RIGHTW, st); rWeap.OnRefire(); }
		}
		else { player.refire = 0; if(ddp.dddebug & DBG_WEAPSEQUENCE) { A_Log("Refire right ignored!"); } }		
	}
	
	action void A_ddRefireRightHeavy()
	{
		let ddp = ddPlayer(self);
		let pspr = player.GetPSprite(PSP_RIGHTW);
		let rWeap = ddp.GetRightWeapon(ddp.rwx);
		let mode = ddWeapon(ddp.player.readyweapon);
		State st = rWeap.GetRefireState();
		if(ddp.player.readyweapon is "playerInventory") { return; }
		if(mode.rightHeld) { return; }
		if(!(player.weaponstate & (WF_QUICKLEFTOK | WF_QUICKRIGHTOK)) && invoker.bmodeReady == true && !rWeap.bAltFire && A_PressingRightFire() && player.health > 0)
		{ 
			if(ddp.dddebug & DBG_WEAPSEQUENCE) { A_Log("Right refire!"); } 
			player.refire++; 
			if(st == rWeap.FindState('DoNotJump')) { return; }
			else { rWeap.weaponstatus = DDW_FIRING; player.SetPSprite(PSP_RIGHTW, st); rWeap.OnRefire(); }
		}
		else if(!(player.weaponstate & (WF_QUICKLEFTOK | WF_QUICKRIGHTOK)) && invoker.bmodeReady == true && rWeap.bAltFire && A_PressingRightAltFire() && player.health > 0)
		{ 
			if(ddp.dddebug & DBG_WEAPSEQUENCE) { A_Log("Right alt refire!"); } 
			player.refire++;
			if(st == rWeap.FindState('DoNotJump')) { return; }
			else { rWeap.weaponstatus = DDW_ALTFIRING; player.SetPSprite(PSP_RIGHTW, st); rWeap.OnRefire(); }
		}
		else { player.refire = 0; if(ddp.dddebug & DBG_WEAPSEQUENCE) { A_Log("Refire right ignored!"); } }			
	}
	
	action void A_SetTicksLeft()
	{
		let ddp = ddPlayer(self);
		if(FindInventory("ClassicModeToken")) { return; }
		let pspl = player.GetPSprite(PSP_LEFTW);
		let lWeap = ddp.GetLeftWeapon(ddp.lwx);
		int ticks = lWeap.GetTicks();
		pspl.Tics = ticks;
		if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { A_Log("Left weapon state set to "..ticks.." ticks!"); }
		return;
	}
	action void A_SetTicksRight()
	{
		let ddp = ddPlayer(self);
		if(FindInventory("ClassicModeToken")) { return; }
		let pspr = player.GetPSprite(PSP_RIGHTW);
		let rWeap = ddp.GetRightWeapon(ddp.rwx);
		int ticks = rWeap.GetTicks();
		pspr.Tics = ticks;
		if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { A_Log("Right weapon state set to "..ticks.." ticks!"); }
		return;
	}
	
	void ReloadWeaponMag(int max, int chamber = 0, int costMultiplier = 1)
	{
		let ddp = ddPlayer(owner);
		Class<Ammo> am = (!bAltFire) ? AmmoType1 : AmmoType2;
		if(mag < max)
		{
			int ma = max - mag;
			int cm = costMultiplier;
			if(!(mag < self.default.mag)) { return; }
			if(ma*cm > ddp.CountInv(am)) { ma = ddp.CountInv(am); ddp.TakeInventory(am, ma); }
			else { ddp.TakeInventory(am, ma*cm); }
			self.mag += ma;
		}
		else 
		{
			if(chamber > 0)
			{
				int c = chamber;
				if(c > ddp.CountInv(am)) { c = ddp.CountInv(am); ddp.TakeInventory(am, c); }
				else { ddp.TakeInventory(am, c); }
				self.mag += c;
			}
		}
	}
	
	void UnloadWeaponMag()
	{
		let ddp = ddPlayer(owner);
		ddp.GiveInventory(AmmoType1, mag);
		if(!bNoScreenFlash && ddp.player.playerstate != PST_DEAD)
		{
			ddp.A_Log("+"..mag.." "..AmmoType1.GetClassName());
			ddp.player.bonuscount = BONUSADD;
		}
		mag = 0;
	}
	
	action void TestFunc()
	{
		let ddp = ddPlayer(self);
		let pspl = ddp.player.GetPSprite(PSP_LEFTW);
		Console.printf(""..(pspl.Tics));
		pspl.Tics = 0;
	}
	
	//weapon sounds should be defined with the tics in the frame
	action void A_WeapSoundLeft()
	{
		let ddp = ddPlayer(self);
		let weap = ddp.GetLeftWeapon(ddp.lwx);
		let pspl = ddp.player.GetPSprite(PSP_LEFTW);
		int no = pspl.tics;
		pspl.tics = 0;
		if(weap) { weap.DD_WeapSound(no); }
	}
	
	action void A_WeapSoundRight()
	{
		let ddp = ddPlayer(self);
		let weap = ddp.GetRightWeapon(ddp.rwx);
		let pspr = ddp.player.GetPSprite(PSP_RIGHTW);
		int no = pspr.tics;
		pspr.tics = 0;
		if(weap) { weap.DD_WeapSound(no); }
	}
	
	action void A_WeapActionLeft()
	{
		let ddp = ddPlayer(self);
		let weap = ddp.GetLeftWeapon(ddp.lwx);
		let pspl = ddp.player.GetPSPrite(PSP_LEFTW);
		int no = pspl.tics;
		pspl.tics = 0;
		if(weap) { weap.DD_WeapAction(no); }
	}
	
	action void A_WeapActionRight()
	{
		let ddp = ddPlayer(self);
		let weap = ddp.GetRightWeapon(ddp.rwx);
		let pspr = ddp.player.GetPSprite(PSP_RIGHTW);
		int no = pspr.tics;
		pspr.tics = 0;
		if(weap) { weap.DD_WeapAction(no); }
	}
	
	//-1 = side independent; kick = added instability
	action void ddShot(bool accurate, Class<Actor> pufftype, int damage, double eAngle = 0, double ePitch = 0, int iSide = -1, int kick = 0)
	{	
		let ddp = ddPlayer(invoker.owner);
		let weap = ddWeapon(self);
		double ang = ddp.angle;
		double pitch = ddp.pitch;
		double extraAngle = eAngle;
		double extraPitch = ePitch;
		double zoff = 4.0;
		if(ddp.dddebug & DBG_WEAPONS && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("=======\nddShot from "..weap.GetClassName()); }
		if(ddp.dddebug & DBG_WEAPONS && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("original extraangle:"..extraangle.."\noriginal extrapitch:"..extrapitch); }
		if(!(ddp.FindInventory("ClassicModeToken")))
		{
			/*weapon ready penalties
			if(!iside) 
			{ 
				if(!(ddp.ddWeaponState & DDW_LEFTREADY))
				{
					extraAngle *= 1.6;
					if(ddp.dddebug & DBG_WEAPONS && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("+shaky penalty to extraAngle:"..extraangle); }
					extraPitch *= 1.2;
					if(ddp.dddebug & DBG_WEAPONS && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("+shaky penalty to extraPitch:"..extrapitch); }
				}
			}
			else if(iside)
			{
				if(!(ddp.ddWeaponState & DDW_RIGHTREADY))
				{
					extraAngle *= 1.6;
					if(ddp.dddebug & DBG_WEAPONS && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("+shaky penalty to extraAngle:"..extraangle); }
					extraPitch *= 1.2;
					if(ddp.dddebug & DBG_WEAPONS && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("+shaky penalty to extraPitch:"..extrapitch); }
				}
			}
			else{}*/
			//movement penalties
			if(ddp.player.bob > 8.) 
			{
				double mp = random2()*((2.0 * (ddp.player.bob / 16.0)) / 256);
				extraAngle *= mp;
				if(ddp.dddebug & DBG_WEAPONS && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("+movement penalty to extraAngle:"..extraangle); }
			}
			else { if(ddp.dddebug & DBG_WEAPONS && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("no movement penalties"); } }
			//instability penalties
			if(ddp.instability > 1)
			{
				double ip = random2()*((5.0 * (ddp.instability / 100)) / 256);
				extraAngle += ip;
				if(ddp.dddebug & DBG_WEAPONS && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("+instability to extraAngle:"..extraangle); }
				extraPitch += (ip / 2);
				if(ddp.dddebug & DBG_WEAPONS && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("+instability to extraPitch:"..extraPitch); }
			}
			else { if(ddp.dddebug & DBG_WEAPONS && ddp.dddebug & DBG_VERBOSE) { ddp.A_Log("no instability penalties"); } }
			if(kick) { ddp.instability += kick; ddp.instability = clamp(ddp.instability, 0, 100); ddp.instTimer = 20; }
			if(accurate)
			{
				extraAngle /= 2;
				extraPitch = 0;
				if(ddp.dddebug & DBG_WEAPONS && ddp.dddebug & DBG_VERBOSE) { 
				ddp.A_Log("+first shot bonus to extraAngle:"..extraangle.."\n+first shot bonus to extraPitch:"..extraPitch); }
			}
		}
		else
		{
			if(!accurate)
			{
				ang += random2() * (5.25 / 256);
			}
			if(ddp.dddebug & DBG_WEAPONS && ddp.dddebug & DBG_VERBOSE) 
			{ ddp.A_Log("Classic Mode sets extraangle:"..extraangle.."\nextrapitch:"..extrapitch); }
			zoff = 0;
		}
		if(ddp.dddebug & DBG_WEAPONS && ddp.dddebug & DBG_VERBOSE) 
		{ 
			ddp.A_Log("final extraAngle:"..extraangle.."\nfinal extraPitch:"..extrapitch.."\n=======");
		}
		ddp.LineAttack(ang + extraAngle, PLAYERMISSILERANGE, pitch + extraPitch, damage, 'hitscan', pufftype, 0, null, zoff);
	}
	
	//ddw_rightnobobbing unset while weapons are bobbing
	action void A_CheckLeftWeaponMag()
	{
		let ddp = ddPlayer(invoker.owner);
		let mode = ddWeapon(ddp.player.readyweapon);
		let lWeap = ddp.GetLeftWeapon(ddp.lwx);
		let rWeap = ddp.GetRightWeapon(ddp.rwx);
		Class<Ammo> type = (!lWeap.bAltFire) ? lWeap.AmmoType1 : lWeap.AmmoType2;
		if(lWeap.bnoReload) 
		{ 
			if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { A_Log("Left weapon doesn't reload, returning"); }
			if(ddp.ddWeaponState & DDW_RIGHTREADY) { mode.A_CheckRightWeaponMag(); }
			return; 
		}
		if(lWeap.weaponstatus != DDW_UNLOADING)
		{
			if(!(lWeap.mag < lWeap.default.mag)) 
			{ 
				if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { A_Log("Left weapon full, returning"); } 
				if(ddp.ddWeaponState & DDW_RIGHTREADY) { mode.A_CheckRightWeaponMag(); }
				return; 
			}		
			if(ddp.CountInv(type) < lWeap.MagUse1) 
			{ 
				if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { A_Log("No ammo for left weapon, returning"); } 
				if(ddp.ddWeaponState & DDW_RIGHTREADY) { mode.A_CheckRightWeaponMag(); }
				return; 
			}
		}
		else
		{
			if(lWeap.mag == 0) 
			{
				if(ddp.dddebug & DBG_WEAPSEQUENCE) { A_Log("Left weapon mag is empty"); }
				ddp.player.SetPSprite(PSP_LEFTW, lWeap.FindState('Ready'));
				invoker.bModeReady = true;
				//if(ddp.ddWeaponState & DDW_RIGHTREADY) { rWeap.weaponstatus = DDW_UNLOADING; mode.A_CheckRightWeaponMag(); }
				return;
			}
			
		}
		let pspl = ddp.player.GetPSprite(PSP_LEFTW);
		let psplf = ddp.player.GetPSprite(PSP_LEFTWF);
		ddp.ddWeaponState &= ~DDW_LEFTREADY;
		ddp.ddWeaponState &= ~DDW_RIGHTREADY;
		ddp.ddWeaponState &= ~DDW_LEFTBOBBING;
		ddp.ddWeaponState &= ~DDW_RIGHTBOBBING;
		lWeap.weaponready = false;
		int cost = (lWeap.bAltFire) ? lWeap.ChargeUse2 : lWeap.ChargeUse1;
		if(!ddp.CheckESOA(cost) && (!lWeap.bNoLower && ddp.player.readyweapon is "dualWielding")) 
		{ 
			if(ddp.dddebug & DBG_WEAPSEQUENCE) { A_Log("Lowering weapons to reload left weapon"); }
			ddp.player.SetPSprite(PSP_LEFTW, lweap.FindState('Select'));
			ddp.player.SetPSprite(PSP_RIGHTW, rweap.FindState('Select'));
			ddp.ddWeaponState |= DDW_LEFTNOBOBBING;
			ddp.ddWeaponState |= DDW_RIGHTNOBOBBING;
			ddp.ddWeaponState |= DDW_LEFTLOWERTOREL;
			//mode.ChangeState('LowerToReloadLeft');
			return; 
		}
		else { if(ddp.dddebug & DBG_WEAPSEQUENCE) { A_Log("Left weapon doesn't need to be lowered"); } }
		State st = lWeap.wannaReload();
		if(st == lWeap.FindState('DoNotJump')) 
		{ 
			if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { A_Log("Left weapon refused reload"); }
			A_CheckRightWeaponMag();
			mode.ChangeState('Ready'); 
			return; 
		}
		ddp.player.SetPSprite(PSP_LEFTW, st);
		mode.ChangeState('Ready');
	}
	
	action void A_CheckRightWeaponMag()
	{
		let ddp = ddPlayer(invoker.owner);
		let mode = ddWeapon(ddp.player.readyweapon);
		let lWeap = ddp.GetLeftWeapon(ddp.lwx);
		let rWeap = ddp.GetRightWeapon(ddp.rwx);
		Class<Ammo> type = (!rWeap.bAltFire) ? rWeap.AmmoType1 : rWeap.AmmoType2;
		if(rWeap.bnoReload) 
		{ 
			if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { A_Log("Right weapon doesn't reload, returning"); }
			ddp.player.setpsprite(PSP_RIGHTW, rWeap.FindState('Ready'));
			mode.ChangeState('Ready'); 
			return; 
		}
		if(rWeap.weaponstatus != DDW_UNLOADING)
		{
			if(!(rWeap.mag < rWeap.default.mag)) 
			{ 
				if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { A_Log("Right weapon full, returning"); } 
				ddp.player.setpsprite(PSP_RIGHTW, rWeap.FindState('Ready'));
				mode.ChangeState('Ready');
				return; 
			}
			if(ddp.CountInv(type) < rWeap.MagUse1) 
			{ 
				if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { A_Log("No ammo for right weapon, returning"); } 
				ddp.player.setpsprite(PSP_RIGHTW, rWeap.FindState('Ready'));
				invoker.bmodeReady = true; 
				mode.ChangeState('Ready'); 
				return; 
			}
		}
		else
		{
			if(rWeap.mag == 0) 
			{
				if(ddp.dddebug & DBG_WEAPSEQUENCE) { A_Log("Right weapon mag is empty"); }
				ddp.player.SetPSprite(PSP_RIGHTW, rWeap.FindState('Ready'));
				ddp.player.SetPSprite(PSP_LEFTW, lWeap.FindState('Ready'));
				invoker.bModeReady = true;
				mode.ChangeState('Ready');
				return;
			}
		}
		let pspr = ddp.player.GetPSprite(PSP_RIGHTW);
		let psprf = ddp.player.GetPSprite(PSP_RIGHTWF);
		ddp.ddWeaponState &= ~DDW_LEFTREADY;
		ddp.ddWeaponState &= ~DDW_RIGHTREADY;
		ddp.ddWeaponState &= ~DDW_LEFTBOBBING;
		ddp.ddWeaponState &= ~DDW_RIGHTBOBBING;
		rWeap.weaponready = false;
		int cost = (rWeap.bAltFire) ? rWeap.ChargeUse2 : rWeap.ChargeUse1;
		if(!ddp.CheckESOA(cost) && (!rWeap.bNoLower && ddp.player.readyweapon is "dualWielding")) 
		{ 
			if(ddp.dddebug & DBG_WEAPSEQUENCE) { A_Log("Lowering weapons to reload right weapon"); }
			ddp.player.SetPSprite(PSP_LEFTW, lweap.FindState('Select'));
			ddp.player.SetPSprite(PSP_RIGHTW, rweap.FindState('Select'));
			ddp.ddWeaponState |= DDW_LEFTNOBOBBING;
			ddp.ddWeaponState |= DDW_RIGHTNOBOBBING;
			ddp.ddWeaponState |= DDW_RIGHTLOWERTOREL;
			//mode.ChangeState('LowerToReloadRight'); 
			return;
		}
		else { if(ddp.dddebug & DBG_WEAPSEQUENCE) { A_Log("Weapons don't need to be lowered"); } }
		State st = rWeap.wannaReload();
		if(st == rWeap.FindState('DoNotJump')) 
		{ 			
			if(ddp.dddebug & DBG_WEAPSEQUENCE && ddp.dddebug & DBG_VERBOSE) { A_Log("Right weapon refused reload"); }
			rWeap.weaponready = true; 
			ddp.player.setpsprite(PSP_RIGHTW, rWeap.FindState('Ready'));
			mode.ChangeState('Ready'); 
			return; 
		}
		ddp.player.SetPSprite(PSP_RIGHTW, st);
		mode.ChangeState('Ready');
	}
	//called by weapons when they reload themselves
	void LowerToReloadWeapon()
	{
		let ddp = ddPlayer(owner);
		let mode = ddWeapon(ddp.player.readyweapon);
		let me = ddWeapon(self);
		let cpiece = ddWeapon(me.companionpiece);
		let pspl = ddp.player.GetPSprite(PSP_LEFTW);
		let psplf = ddp.player.GetPSprite(PSP_LEFTWF);
		let pspr = ddp.player.GetPSprite(PSP_RIGHTW);
		let psprf = ddp.player.GetPSprite(PSP_RIGHTWF);
		int myside = (weaponside) ? PSP_LEFTW : PSP_RIGHTW; 
		int flashside = (weaponside) ? PSP_LEFTWF : PSP_RIGHTWF;
		weaponready = false;
		cpiece.weaponready = false;
		if(weaponside)
		{
			if(cpiece.weaponstatus == DDW_FIRING) { ChangeState("Ready", myside); return; }
			mode.bmodeready = false;
			pspl.SetState(FindState('Select'));
			psplf.SetState(null);
			pspr.SetState(cpiece.FindState('Select'));
			psprf.SetState(null);
			ddp.ddWeaponState &= ~DDW_LEFTREADY;
			ddp.ddWeaponState &= ~DDW_RIGHTREADY;
			ddp.ddWeaponState &= ~DDW_LEFTBOBBING;
			ddp.ddWeaponState &= ~DDW_RIGHTBOBBING;
			ddp.ddWeaponState |= DDW_LEFTNOBOBBING;
			ddp.ddWeaponState |= DDW_RIGHTNOBOBBING;
			ddp.ddWeaponState |= DDW_LEFTLOWERTOREL;
		}
		else 
		{ 
			if(cpiece.weaponstatus == DDW_FIRING) { ChangeState("Ready", myside); return; }
			mode.bmodeready = false;
			pspl.SetState(cpiece.FindState('Select'));
			psplf.SetState(null);
			pspr.SetState(FindState('Select'));
			psprf.SetState(null);
			ddp.ddWeaponState &= ~DDW_LEFTBOBBING;
			ddp.ddWeaponState &= ~DDW_RIGHTBOBBING;
			ddp.ddWeaponState |= DDW_LEFTNOBOBBING;
			ddp.ddWeaponState |= DDW_RIGHTNOBOBBING;
			ddp.ddWeaponState |= DDW_RIGHTLOWERTOREL;
		} 		
	}

	void A_LowerToReloadLeft()
	{
		let ddp = ddPlayer(owner);
		if(ddp)
		{
			let mode = ddWeapon(ddp.player.readyweapon);
			let lWeap = ddp.GetLeftWeapon(ddp.lwx);
			let rWeap = ddp.GetRightWeapon(ddp.rwx);
			let lw = ddp.GetLeftWeapons();
			let rw = ddp.GetRightWeapons();
			let pspl = ddp.player.GetPSprite(PSP_LEFTW);
			let psplf = ddp.player.GetPSprite(PSP_LEFTWF);
			let pspr = ddp.player.GetPSprite(PSP_RIGHTW);
			let psprf = ddp.player.GetPSprite(PSP_RIGHTWF);
			int bz = (ddp.FindInventory("PowerBerserk")) ? 2 : 1;
			double sFactor = (12 + ((lWeap.sFactor + rWeap.sFactor) / 2)) * bz;
			if(PressingLeftFire()) { lweap.onWeaponFire(CE_LEFT, mode.leftheld); }
			else if(PressingLeftAltFire()) { lweap.onWeaponFire(CE_LEFT, mode.leftheld); }
			if(PressingRightFire()) { rweap.onWeaponFire(CE_RIGHT, mode.rightheld); }
			else if(PressingRightAltFire()) { rweap.onWeaponFire(CE_RIGHT, mode.rightheld); } 
			if(lWeap.weaponready || ddp.lwx != lSwapTarget) 
			{
				ddp.player.SetPSprite(PSP_LEFTW, lWeap.GetUpState()); 
				ddp.player.SetPSprite(PSP_RIGHTW, rWeap.GetUpState()); 
				ddp.ddWeaponState &= ~DDW_LEFTREADY;				
				ddp.ddWeaponState &= ~DDW_RIGHTREADY;
				ddp.ddWeaponState &= ~DDW_LEFTBOBBING;				
				ddp.ddWeaponState &= ~DDW_RIGHTBOBBING;
				ddp.ddWeaponState &= ~DDW_LEFTLOWERTOREL;
				ddp.ddWeaponState |= DDW_LEFTRAISETOREL;
			}
			if(mode.weaponstatus != DDW_RELOADING && mode.weaponstatus != DDW_UNLOADING)
			{
				if(pspr.y < 128) { pspr.y += sFactor; psprf.y += sFactor; }
				pspl.x += sFactor; psplf.x += sFactor;
				if(!(pspl.x >= 0)) { return; }
				pspl.x = 0; psplf.x = 0;
				pspl.y = 0; psplf.y = 0;
				pspr.x = 64 + rweap.xOffset; psprf.x = 64 + rweap.xOffset;
				pspr.y = 128; psprf.y = 128;	
				State st = lWeap.wannaReload();
				if(st == lWeap.FindState('DoNotJump')) { bmodeReady = true; lWeap.weaponready = true; return; }
				lWeap.A_ChangeSpriteLeft(1);
				mode.weaponstatus = lWeap.weaponStatus;
				ddp.player.SetPSprite(PSP_LEFTW, st);
				return;
			}
			else
			{
				if(ddp.rwx != rSwapTarget)
				{
					ddp.rwx = rSwapTarget;
					rWeap = rw.RetItem(ddp.rwx);
					lWeap.companionpiece = rWeap;
					rWeap.companionpiece = lWeap;
					if(rWeap.bTwoHander && !ddp.CheckESOA(2)) { ddp.ddWeaponState |= DDW_RIGHTISTH; }
					else { ddp.ddWeaponState &= ~DDW_RIGHTISTH; }	
					ddp.player.SetPSprite(PSP_RIGHTW, rWeap.GetUpState());
					ddp.player.SetPSprite(PSP_RIGHTWF, null);
				}
			}
			
		}
	}
	
	void A_RaiseToReloadLeft()
	{		
		let ddp = ddPlayer(owner);
		if(ddp)
		{
			ddWeapon mode = ddWeapon(ddp.player.readyweapon);			
			let lWeap = ddp.GetLeftWeapon(ddp.lwx);
			let rWeap = ddp.GetRightWeapon(ddp.rwx);
			let pspl = ddp.player.GetPSprite(PSP_LEFTW);
			let psplf = ddp.player.GetPSprite(PSP_LEFTWF);
			let pspr = ddp.player.GetPSprite(PSP_RIGHTW);
			let psprf = ddp.player.GetPSprite(PSP_RIGHTWF);
			int bz = (ddp.FindInventory("PowerBerserk")) ? 2 : 1;
			double sFactor = (14 + ((lWeap.sFactor + rWeap.sFactor) / 2)) * bz;
			if(PressingLeftFire()) { lweap.onWeaponFire(CE_LEFT, mode.leftheld); }
			else if(PressingLeftAltFire()) { lweap.onWeaponFire(CE_LEFT, mode.leftheld); }
			if(PressingRightFire()) { rweap.onWeaponFire(CE_RIGHT, mode.rightheld); }
			else if(PressingRightAltFire()) { rweap.onWeaponFire(CE_RIGHT, mode.rightheld); } 
			if(pspr.y > 0) { pspr.y -= sFactor; psprf.y -= sFactor; }
			pspl.x -= sFactor; psplf.x -= sFactor;
			if(!(pspl.x <= -64)) { return; }
			pspl.x = -64; psplf.x = -64;
			pspl.y = 0; psplf.y = 0;
			pspr.x = 64 + rweap.xOffset; psprf.x = 64 + rweap.xOffset;
			pspr.y = 0; psprf.y = 0;
			ddp.player.SetPSprite(PSP_RIGHTW, rWeap.GetReadyState());
			ddp.player.SetPSprite(PSP_LEFTW, lWeap.GetReadyState());
			bmodeready = true;
			ddp.ddWeaponState &= ~DDW_LEFTNOBOBBING;
			ddp.ddWeaponState &= ~DDW_RIGHTNOBOBBING;
			ddp.ddWeaponState &= ~DDW_LEFTRAISETOREL;
			mode.weaponstatus = DDW_READY;
			if(mode.weaponStatus != DDW_UNLOADING && (ddp.player.cmd.buttons & BT_RELOAD))
			{
				rWeap.weaponStatus = DDW_RELOADING;
				rWeap.weaponReady = false;
				A_CheckRightWeaponMag();
				return;
			}
			return;
		}
	}
	
	void A_LowerToReloadRight()
	{
		let ddp = ddPlayer(owner);
		if(ddp)
		{
			ddWeapon mode = ddWeapon(ddp.player.readyweapon);	
			let lWeap = ddp.GetLeftWeapon(ddp.lwx);
			let lw = ddp.GetLeftWeapons();
			let rWeap = ddp.GetRightWeapon(ddp.rwx);
			let rw = ddp.GetRightWeapons();
			let pspl = ddp.player.GetPSprite(PSP_LEFTW);
			let psplf = ddp.player.GetPSprite(PSP_LEFTWF);
			let pspr = ddp.player.GetPSprite(PSP_RIGHTW);
			let psprf = ddp.player.GetPSprite(PSP_RIGHTWF);
			if(PressingLeftFire()) { lweap.onWeaponFire(CE_LEFT, mode.leftheld); }
			else if(PressingLeftAltFire()) { lweap.onWeaponFire(CE_LEFT, mode.leftheld); }
			if(PressingRightFire()) { rweap.onWeaponFire(CE_RIGHT, mode.rightheld); }
			else if(PressingRightAltFire()) { rweap.onWeaponFire(CE_RIGHT, mode.rightheld); } 
			if(rWeap.weaponready || ddp.rwx != rSwapTarget) 
			{
				ddp.player.SetPSprite(PSP_LEFTW, lWeap.GetUpState()); 
				ddp.player.SetPSprite(PSP_RIGHTW, rWeap.GetUpState());
				//if mode was switched during reload time, swap to mode and dont raise back left weapon
				ddp.ddWeaponState &= ~DDW_LEFTREADY;				
				ddp.ddWeaponState &= ~DDW_RIGHTREADY;
				ddp.ddWeaponState &= ~DDW_LEFTBOBBING;
				ddp.ddWeaponState &= ~DDW_RIGHTBOBBING;
				ddp.ddWeaponState &= ~DDW_RIGHTLOWERTOREL;
				ddp.ddWeaponState |= DDW_RIGHTRAISETOREL;
			}
			int bz = (FindInventory("PowerBerserk")) ? 2 : 1;			
			double sFactor = (12 + ((lWeap.sFactor + rWeap.sFactor) / 2)) * bz;
			if(mode.weaponStatus != DDW_RELOADING && mode.weaponstatus != DDW_UNLOADING)
			{
				if(pspl.y < 128) { pspl.y += sFactor; psplf.y += sFactor; }	
				if((abs(pspr.x) - (sFactor)) > 0)
				{
					pspr.x -= sFactor; psprf.x -= sFactor;
					return;
				}
				else
				{
					pspl.x = -64; psplf.x = -64;
					pspl.y = 128; psplf.y = 128;
					pspr.x = 0; psprf.x = 0;
					pspr.y = 0; psprf.y = 0;
					State st = rWeap.wannaReload();
					if(st == rWeap.FindState('DoNotJump')) { bmodeReady = true; rWeap.weaponready = true; return; }
					ddp.player.SetPSprite(PSP_RIGHTW, st);
					mode.weaponstatus = rWeap.weaponstatus;
					rWeap.A_ChangeSpriteRight(1);
					if(ddp.player.pendingweapon is "twoHanding") { 
						ddWeapon thd = ddWeapon(ddp.FindInventory("twoHanding"));
						thd.lSwapTarget = mode.lSwapTarget;
						thd.rSwapTarget = mode.rSwapTarget;
						ddp.player.readyweapon = thd;
						ddp.lastmode = thd;
						mode = thd;
						ddp.player.pendingweapon = WP_NOCHANGE;
						ddp.player.SetPSprite(PSP_WEAPON, mode.GetReadyState());
						ddp.ddWeaponState &= ~DDW_RIGHTLOWERTOREL; 
						mode.bmodeready = true;
						mode.weaponstatus = DDW_READY;
					}
					return;
				}
			}
			else
			{
				if(ddp.lwx != lSwapTarget)
				{
					ddp.lwx = lSwapTarget;
					lWeap = lw.RetItem(ddp.lwx);
					rWeap.companionpiece = lWeap;
					lWeap.companionPiece = rWeap;
					if(lWeap.bTwoHander && !ddp.CheckESOA(2)) { ddp.ddWeaponState |= DDW_LEFTISTH; }
					else { ddp.ddWeaponState &= ~DDW_LEFTISTH; }	
					ddp.player.SetPSprite(PSP_LEFTW, lWeap.GetUpState());					
				}
				if(ddp.player.pendingweapon is "twoHanding") { 
					ddWeapon thd = ddWeapon(ddp.FindInventory("twoHanding"));
					thd.lSwapTarget = mode.lSwapTarget;
					thd.rSwapTarget = mode.rSwapTarget;
					ddp.player.readyweapon = thd;
					mode = thd;
					ddp.lastmode = thd;
					ddp.player.pendingweapon = WP_NOCHANGE;
					ddp.player.SetPSprite(PSP_WEAPON, mode.GetReadyState());
					ddp.ddWeaponState &= ~DDW_RIGHTLOWERTOREL; 
					mode.bmodeready = true;
					mode.weaponstatus = DDW_READY;
				}
			}
		}
	}
	
	void A_RaiseToReloadRight()
	{		
		let ddp = ddPlayer(owner);
		if(ddp)
		{
			ddWeapon mode = ddWeapon(ddp.player.readyweapon);			
			let lWeap = ddp.GetLeftWeapon(ddp.lwx);
			let rWeap = ddp.GetRightWeapon(ddp.rwx);
			let pspl = ddp.player.GetPSprite(PSP_LEFTW);
			let psplf = ddp.player.GetPSprite(PSP_LEFTWF);
			let pspr = ddp.player.GetPSprite(PSP_RIGHTW);
			let psprf = ddp.player.GetPSprite(PSP_RIGHTWF);
			int bz = (FindInventory("PowerBerserk")) ? 2 : 1;
			double sFactor = (14 + ((lWeap.sFactor + rWeap.sFactor) / 2)) * bz;
			if(PressingLeftFire()) { lweap.onWeaponFire(CE_LEFT, mode.leftheld); }
			else if(PressingLeftAltFire()) { lweap.onWeaponFire(CE_LEFT, mode.leftheld); }
			if(PressingRightFire()) { rweap.onWeaponFire(CE_RIGHT, mode.rightheld); }
			else if(PressingRightAltFire()) { rweap.onWeaponFire(CE_RIGHT, mode.rightheld); } 
			if(pspl.y > 0) { pspl.y -= sFactor; psplf.y -= sFactor; }	
			if((abs(pspr.x) + (2 * sFactor)) < 64)
			{
				pspr.x += 2 * sFactor; psprf.x += 2 * sFactor;
				return;
			}
			else
			{
				pspl.x = -64; psplf.x = -64;
				pspl.y = 0; psplf.y = 0;	
				pspr.x = 64 + rweap.xOffset; psprf.x = 64 + rweap.xOffset;
				pspr.y = 0; psprf.y = 0;
				bmodeready = true;
				bmodeready = true;  
				ddp.ddWeaponState &= ~DDW_LEFTNOBOBBING;
				ddp.ddWeaponState &= ~DDW_RIGHTNOBOBBING; 			
				ddp.player.SetPSprite(PSP_LEFTW, lWeap.GetReadyState()); 
				ddp.player.SetPSprite(PSP_RIGHTW, rWeap.GetReadyState());
				ddp.ddWeaponState &= ~DDW_RIGHTRAISETOREL;
				mode.weaponstatus = DDW_READY;
				if(mode.weaponStatus != DDW_UNLOADING && (ddp.player.cmd.buttons & BT_RELOAD))
				{
					lWeap.weaponStatus = DDW_RELOADING;
					lWeap.weaponReady = false;
					A_CheckLeftWeaponMag();
					return;
				}
				return;
			}
		}
	}
	
	action void A_DeathLower()
	{
		let ddp = ddPlayer(invoker.owner);
		let mode = ddp.player.GetPSprite(PSP_WEAPON);
		let pspl = ddp.player.GetPSprite(PSP_LEFTW);
		let pspr = ddp.player.GetPSprite(PSP_RIGHTW);
		let psplf = ddp.player.GetPSprite(PSP_LEFTWF);
		let psprf = ddp.player.GetPSprite(PSP_RIGHTWF);			
		let lWeap = ddp.GetLeftWeapon(ddp.lwx);
		let rWeap = ddp.GetRightWeapon(ddp.rwx);
		if(ddp.player.readyweapon)
		{
			if(lweap) { pspl.SetState(lweap.GetUpState()); }
			if(rweap) { pspr.SetState(rweap.GetUpState()); }
			ddp.ddWeaponState |= DDW_LEFTNOBOBBING;			
			ddp.ddWeaponState |= DDW_RIGHTNOBOBBING;
			psplf.SetState(null); psprf.SetState(null);
			mode.y += 4;
			if(mode.y < WEAPONBOTTOM) { return; }
			mode.y = WEAPONBOTTOM;
			return;
		}
		
	}
	
	action void A_PickupSwapDrop()
	{
		let ddp = ddPlayer(invoker.owner);
		if(!ddp) { return; }
		let mode = ddWeapon(ddp.player.readyweapon);			
		let lWeap = ddp.GetLeftWeapon(ddp.lwx);
		let rWeap = ddp.GetRightWeapon(ddp.rwx);
		let pspl = ddp.player.GetPSprite(PSP_LEFTW);
		let pspr = ddp.player.GetPSprite(PSP_RIGHTW);
		let psplf = ddp.player.GetPSprite(PSP_LEFTWF);
		let psprf = ddp.player.GetPSprite(PSP_RIGHTWF);
		if(ddp.ddWeaponState & DDW_REPLACERIGHT)
		{
			pspr.y -= 4 * rWeap.sFactor; psprf.y -= 4 * rWeap.sFactor;
			if(pspr.y < 1) { pspr.y = 0; psprf.y = 0; ddp.ddWeaponState &= ~DDW_REPLACERIGHT; ddp.ddWeaponState &= ~DDW_RIGHTNOBOBBING; }
		}
		else if(ddp.ddWeaponState & DDW_REPLACELEFT)
		{
			pspl.y -= 4 * lWeap.sFactor; psplf.y -= 4 * lWeap.sFactor;
			if(pspl.y < 1) { pspl.y = 0; psplf.y = 0; ddp.ddWeaponState &= ~DDW_REPLACELEFT; ddp.ddWeaponState &= ~DDW_LEFTNOBOBBING; }
		}
		else 
		{ 
			mode.bmodeready = true;
			pspl.SetState(lWeap.GetReadyState());
			pspr.SetState(rWeap.GetReadyState());
			A_ChangeState("Ready"); 
		} 
	}
	action void A_PickupSwapStore()
	{
		let ddp = ddPlayer(invoker.owner);
		if(!ddp) { return; }
		let mode = ddWeapon(ddp.player.readyweapon);			
		let lWeap = ddp.GetLeftWeapon(ddp.lwx);
		let rWeap = ddp.GetRightWeapon(ddp.rwx);	
		let leftw = ddp.GetLeftWeapons();
		let rightw = ddp.GetRightWeapons();	
		let pspl = ddp.player.GetPSprite(PSP_LEFTW);
		let pspr = ddp.player.GetPSprite(PSP_RIGHTW);
		let psplf = ddp.player.GetPSprite(PSP_LEFTWF);
		let psprf = ddp.player.GetPSprite(PSP_RIGHTWF);
		if(ddp.ddWeaponState & DDW_REPLACERIGHT)
		{
			pspr.y += 4 * rWeap.sFactor; psprf.y += 4 * rWeap.sFactor;
			if(pspr.y > 127) 
			{ 
				pspr.y = 128; psprf.y = 128; 
				ddp.ddWeaponState &= ~DDW_REPLACERIGHT; 
				if(!(rightw.RetItem(ddp.rwx) is "ddFist")) { ddp.RemoveInventory(rightw.RetItem(ddp.rwx)); }
				rightw.SetItem(invoker.swapHeld, ddp.rwx);
				rightw.RetItem(ddp.rwx).companionpiece = leftw.RetItem(ddp.lwx);
				leftw.RetItem(ddp.lwx).companionpiece = rightw.RetItem(ddp.rwx);
				pspr.SetState(ddp.GetRightWeapon(ddp.rwx).GetUpState());
				if(ddp.GetRightWeapon(ddp.rwx).UpSound) { ddp.A_StartSound(ddp.GetRightWeapon(ddp.rwx).UpSound, CHAN_WEAPON); }
				if(mode is "twoHanding") { A_ChangeState("QuickSwapTH"); }
				else { dualWielding(mode).brraised = false; A_ChangeState("QuickSwapDW"); }
			}
		}
		if(ddp.ddWeaponState & DDW_REPLACELEFT)
		{
			pspl.y += 4 * lWeap.sFactor; psplf.y += 4 * lWeap.sFactor;
			if(pspl.y > 127) 
			{					
				pspl.y = 128; psplf.y = 128; 
				ddp.ddWeaponState &= ~DDW_REPLACELEFT; 
				if(!(leftw.RetItem(ddp.lwx) is "ddFist")) { ddp.RemoveInventory(leftw.RetItem(ddp.lwx)); }
				leftw.SetItem(invoker.swapHeld, ddp.lwx);
				rightw.RetItem(ddp.rwx).companionpiece = leftw.RetItem(ddp.lwx);
				leftw.RetItem(ddp.lwx).companionpiece = rightw.RetItem(ddp.rwx);
				pspl.SetState(ddp.GetLeftWeapon(ddp.lwx).GetUpState());
				if(ddp.GetLeftWeapon(ddp.lwx).UpSound) { ddp.A_StartSound(ddp.GetLeftWeapon(ddp.lwx).UpSound, CHAN_WEAPON); }
				dualWielding(mode).blraised = false;
				A_ChangeState("QuickSwapDW");
			}
			
		}
		
	}
	
	// ##ddWeapon States()
	States
	{
		LowerToReloadLeft:
			---- A 1;
			Loop;
		RaiseToReloadLeft:
			---- A 1;
			Loop;
		LowerToReloadRight:
			---- A 1;
			Loop;
		RaiseToReloadRight:
			---- A 1;
			Loop;
		PickupSwapDrop:
			---- A 1 A_PickupSwapDrop;
			Loop;
		PickupSwapStore:
			---- A 1 A_PickupSwapStore;
			Loop;
		FlashP:
		FlashA:
		FlashDone:
			TNT1 A 1 A_Light0;
			Loop;
		NoFlash:
			TNT1 A 1 A_Light0;
			Loop;
		DeathLower:
			---- A 1 A_DeathLower;
			Loop;
		//marker labels
		DoNotJump:
			---- A 0;
			Stop;
		LowerToReload:
			---- A 0;
			Stop;
	}
}

//Fake weapon that becomes ddFist on GiveDefaultInventory; probably not needed?
// #Class emptie : ddWeapon()
class emptie : ddWeapon
{
	Default
	{
		Weapon.AmmoType 	"NotAnAmmo";
		Weapon.AmmoType2 	"NotAnAmmo";
		Weapon.AmmoUse		69;
		Weapon.AmmoUse2		69;
		ddWeapon.SwitchSpeed 3;
		-DDWEAPON.GOESININV;
		Inventory.Amount 1;
		Inventory.MaxAmount 1;
		Tag "N/A";
	}
	
	override String GetWeaponSprite()
	{
		return "";
	}
	
	override String getParentType()
	{
		return "emptie";
	}
	
	States
	{
		Ready:
			TNT1 A 1;
			Loop;
		Select:
			---- A 1;
			Loop;
		Deselect:
			---- A 1;
			Loop;
		Fire:
			---- A 1;
			Goto Ready;
		AltFire:
			---- A 1;
			Goto Ready;
	}
}

//Inventory item that holds references to items its owner would hold. Stores its size and current slot
class Pocket : Inventory
{
	Array<Inventory> items;
	int size;
	property Size : size;
	Default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE;
		pocket.size 2;
	}
	
	bool AddItem(Inventory it, bool stuff = false) //adds item to end of the list if it doesn't exceed size, if stuff is true, increase size to accomodate
	{
		if(stuff) { self.size++; }
		if(items.size() == self.size) { return false; }
		items.Insert(items.size(), it);
		return true;
	}
	
	bool SetItem(Inventory it, int slot) //replaces item at index slot with item it
	{
		if(slot < 0) { return false; }
		if(slot > size - 1) { return false; }
		if(!(it is "Inventory")) { return false; }
		items[slot] = it;
		return true;
	}
	
	bool RemoveItem(int slot) //remove index : TODO; remove item from owner when called
	{
		if(slot < 0) { return false; }
		if(slot > size - 1) { return false; }
		items.delete(slot);
		return true;
	}
	
	virtual bool AddWeapon(Inventory it, int slot = -1) { return false; } //for weapon inventories, replace empty slot with item it, 
	
	clearscope virtual Inventory RetItem(int slot) //return item at slot
	{
		if(slot < 0) { return null; }
		if(slot > size - 1) { return null; }
		return Inventory(items[slot]);
	}
	bool, String SearchList(Class<Inventory> it)  //return true and index of item, including relatives, false otherwise
	{
		let tgt = (Class<Inventory>)(it);
		if(!tgt) { return false, "Item is not a valid inventory item"; }
		String res = "Item "..tgt.GetClassName().." ";
		bool ae = false;
		for(int x = 0; x < items.size(); x++)
		{
			if(items[x].GetClassName() == tgt.GetClassName()) { if(!ae) { ae = true; res = res.."found at index "..x; } else { res = res..", "..x; } }
		}
		if(!ae) { res = res.."not found."; return false, res; }
		else { return true, res; }
	}
	/* TODO: Finish me
	void ValidateInventory() //remove items that no longer share owner
	{
	}
	*/
}

class LeftWeapons : Pocket 
{
	override bool AddWeapon(Inventory it, int slot)
	{
		for(int x = 0; x < items.size(); x++)
		{
			if(items[x] is "ddFist")
			{
				items[x] = ddWeapon(it);
				return true;
			}
		}
		return false;
	}
	
	override ddWeapon RetItem(int slot)
	{
		return ddWeapon(Super.RetItem(slot));
	}
}
class RightWeapons : Pocket 
{
	override bool AddWeapon(Inventory it, int slot)
	{
		for(int x = 0; x < items.size(); x++)
		{
			if(items[x] is "ddFist")
			{
				items[x] = ddWeapon(it);
				return true;
			}
		}
		return false;
	}
	
	override ddWeapon RetItem(int slot)
	{		
		return ddWeapon(Super.RetItem(slot));
	}
}
class WeaponsInventory : Pocket 
{ 
	Default { pocket.size 3; } 
	
	override bool AddWeapon(Inventory it, int slot)
	{
		for(int x = 0; x < items.size(); x++)
		{
			if(inventoryWeapon(items[x]).weaponname == "emptie")
			{
				ddWeapon nu = ddWeapon(it);
				inventoryWeapon(items[x]).construct(nu.GetParentType(), nu.rating, nu.GetWeaponSprite(), nu.mag, nu.ddWeaponFlags, true);
				return true;
			}
		}
		return false;
	}
	
	clearscope int GetInventoryCount()
	{
		int f = size;
		for(int x = 0; x < items.size(); x++)
		{
			if(inventoryWeapon(items[x]).weaponname == "emptie") { f--; }
		}
		return f;
	}
	
	clearscope int GetFreeSpace() 
	{
		int f = 0;
		for(int x = 0; x < items.size(); x++)
		{
			if(inventoryWeapon(items[x]).weaponname == "emptie") { f++; }
		}
		return f;
	}
	
	override inventoryWeapon RetItem(int slot)
	{
		return inventoryWeapon(Super.RetItem(slot));
	}
}
class FistList : Pocket 
{ 
	Default { pocket.size 0; } 
	override ddWeapon RetItem(int slot)
	{		
		return ddWeapon(Super.RetItem(slot));
	}
}

//Item stored in WeaponsInventory; holds weaponname, rating, weaponsprite, and mag for display and retrieval
//Also creates a copy of its referenced weapon. Probably should find alternative way to store info and flags
// #Class inventoryWeapon : Inventory()
class inventoryWeapon : Inventory
{
	Name weaponName;
	int rating;
	String weaponSprite;
	int mag;
	int ddWeaponFlags;
	ddWeapon ref; //copy of parent type for getting attributes
	
	Property weaponName : weaponName;
	Property rating : rating;
	Property weaponSprite : weaponSprite;
	Property Mag : mag;
	Property ddWeaponFlags : ddWeaponFlags;
	
	Default
	{
		Inventory.Amount 	1;
		Inventory.MaxAmount 1;	
		inventoryWeapon.weaponName	"emptie";
		inventoryWeapon.rating	 	0;
		inventoryWeapon.weaponSprite	"";
		inventoryWeapon.mag	1;
		//inventoryWeapon.ddWeaponFlags 0;
	}
	
	//give inventoryWeapon identifiers
	void construct(Name wName, int wRating, String wSprite, int ma, int wflags = 0, bool storeReference = true)
	{
		weaponName = wName;
		if(storeReference)
		{
			let wip = ddWeapon(Spawn(wName));
			wip.mag = ma;
			wip.ddWeaponFlags = wFlags;
			ref = wip;
			wip.BecomeItem();
		}
		ddWeaponFlags = wFlags;
		rating = wRating;		
		weaponSprite = wSprite;
		mag = ma;
	}
	
	void nullify()
	{
		weaponName = "";
		rating = 0;
		weaponsprite = "";
		mag = 1;
		if(ref)
		{
			ref.DepleteOrDestroy();
			ref = null;
		}
	}
	
	void emptify()
	{
		let ddp = ddPlayer(owner);
		weaponName = "emptie";
		rating = 0;
		weaponSprite = "";
		mag = 1;
		if(ref)
		{
			ref.DepleteOrDestroy();
			ref = null;
		}
	}
	
	ui void GetInventoryInfo(ddStats ddhud)
	{
		if (ref) { ref.InventoryInfo(ddhud); }
		else { ddhud.DrawString(ddhud.fa, "n/a", (30, 45), ddhud.DI_SCREEN_CENTER | ddhud.DI_TEXT_ALIGN_LEFT); }
	}
}
// #Class NotAnAmmo : Ammo()
class NotAnAmmo : Ammo
{	
	Default
	{
		Inventory.PickupMessage "";
		Inventory.Amount 1;
		Inventory.MaxAmount 1;
		Ammo.BackpackAmount 1;
		Ammo.BackpackMaxAmount 1;
		Inventory.Icon "";
		Tag "";
	}
	States
	{
		Spawn:
			TNT1 A -1;
			Stop;
	}
}