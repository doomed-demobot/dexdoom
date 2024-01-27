// #Class dualWielding : ddWeapon()
//Weapon mode for using two weapons simultaneously.
class dualWielding : ddWeapon
{
	int dropTimer, dropChoice;
	int dwgflags;
	flagdef lRaised	: dwgFlags, 0;
	flagdef rRaised	: dwgFlags, 1;
	Default
	{
		Weapon.SlotNumber 2;
		Weapon.MinSelectionAmmo1 0;
		Weapon.BobRangeX 0;
		Weapon.BobRangeY 0;
		Weapon.SelectionOrder 2;
		Weapon.UpSound "weapon/dualup";
		Inventory.Amount 1;
		Inventory.MaxAmount 1;
		Tag "Dual Wielding";
		+DDWEAPON.MODEREADY;
		-DDWEAPON.GOESININV;
		+WEAPON.NODEATHDESELECT;
		+WEAPON.NODEATHINPUT;
		+INVENTORY.UNDROPPABLE;
		-DUALWIELDING.LRAISED;
		-DUALWIELDING.RRAISED;
	}
	
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		dropTimer = -1;
		dropChoice = -1; //1 = left, 0 = right
	}
	
	override void Tick()
	{
		Super.Tick();
		if(dropTimer > -1) { dropTimer++; }
		if(dropTimer > (35*4) + 1) { dropTimer = -1; }
		if(!owner) { return; }
		let ddp = ddPlayer(owner);
		let lw = ddp.GetLeftWeapons();
		let rw = ddp.GetRightWeapons();
		if(ddp.FindInventory("PowerBerserk"))
		{
			if(lw.RetItem(ddp.lwx)) { lw.RetItem(ddp.lwx).WhileBerserk(); }
			if(rw.RetItem(ddp.rwx)) { rw.RetItem(ddp.rwx).WhileBerserk(); }
		}
		if(PressingLeftFire() || PressingLeftAltFire()) { leftheld = true; }
		else { leftheld = false; }
		if(PressingRightFire() || PressingRightAltFire()) { rightheld = true; }
		else { rightheld = false; }
	}
	
	override ddWeapon CreateTossable()
	{
		let ddp = ddPlayer(owner);
		let lWeap = ddp.GetLeftWeapons();
		let rWeap = ddp.GetRightWeapons();
		let pInv = ddp.GetWeaponsInventory();
		let lw = lWeap.RetItem(ddp.lwx);
		let rw = rWeap.RetItem(ddp.rwx);
		let pspl = ddp.player.GetPSprite(PSP_LEFTW);
		let psplf = ddp.player.GetPSprite(PSP_LEFTWF);
		let pspr = ddp.player.GetPSprite(PSP_RIGHTW);
		let psprf = ddp.player.GetPSprite(PSP_RIGHTWF);
		if(ddp.ddWeaponState & DDW_RIGHTREADY && ddp.ddWeaponState & DDW_LEFTREADY)
		{
			if(dropChoice == -1)
			{
				dropTimer++;
				ddp.A_StartSound("misc/chat2", CHAN_WEAPON, 0, 0.67);
				ddp.A_Log("\ctLeft primary\c-: Choose left\n\ctRight primary\c-: Choose Right\n\ctReload\c-: Cancel", 3);
				ddp.player.SetPSprite(PSP_WEAPON, FindState('ChooseSide'));
				return null;
			}
			else
			{
				if(dropChoice)
				{
					if(lw is "ddFist") { ddp.A_Print("no can do", 1); ddp.A_StartSound("misc/boowomp", CHAN_BODY, CHANF_OVERLAP); 
						dropChoice = -1;  ddp.player.SetPSprite(PSP_WEAPON, FindState('Ready')); bmodeready = true; return null; 
					}
					for(int x = 0; x < pInv.items.Size(); x++)
					{
						if(pInv.RetItem(x).weaponName == "emptie")
						{
							ddp.A_Log("Stored "..lw.GetTag());
							pInv.RetItem(x).construct(lw.GetParentType(), lw.rating, lw.GetWeaponSprite(), lw.mag);
							ddp.RemoveInventory(lw);
							lWeap.SetItem(ddWeapon(ddp.GetFists(1)), ddp.lwx);
							if(++ddp.lwx > lWeap.size - 1) { ddp.lwx = 0; }
							lSwapTarget = ddp.lwx;
							ddp.player.setpsprite(PSP_LEFTW, lWeap.RetItem(ddp.lwx).GetUpState());
							ddp.ddWeaponState &= ~DDW_LEFTREADY;
							pspl.y = 128;
							psplf.y = 128;	
							ddp.player.SetPSprite(PSP_WEAPON, FindState('QuickSwapDW'));
							rWeap.RetItem(ddp.rwx).companionpiece = lWeap.RetItem(ddp.lwx);
							lWeap.RetItem(ddp.lwx).companionpiece = rWeap.RetItem(ddp.rwx);	
							dropChoice = -1;
							return null;
						}
					}
					ddp.A_Log("Dropped "..lw.GetTag());
					let tos = ddWeapon(Spawn(lw.GetParentType()));
					tos.AmmoGive1 = 0;
					tos.AttachToOwner(owner);
					tos.mag = lw.mag;
					ddp.RemoveInventory(lw);				
					lWeap.SetItem(ddWeapon(ddp.GetFists(1)), ddp.lwx);
					if(++ddp.lwx > lWeap.size - 1) { ddp.lwx = 0; }
					lSwapTarget = ddp.lwx;
					ddp.player.setpsprite(PSP_LEFTW, lWeap.RetItem(ddp.lwx).GetUpState());
					ddp.ddWeaponState &= ~DDW_LEFTREADY;
					bModeReady = false;
					pspl.y = 128;
					psplf.y = 128;	
					ddp.player.SetPSprite(PSP_WEAPON, FindState('QuickSwapDW'));
					rWeap.RetItem(ddp.rwx).companionpiece = lWeap.RetItem(ddp.lwx);
					lWeap.RetItem(ddp.lwx).companionpiece = rWeap.RetItem(ddp.rwx);	
					dropChoice = -1;
					return ddWeapon(tos.CreateTossable());
				}
				else if(!dropChoice)
				{
					if(rw is "ddFist") { ddp.A_Print("no can do", 1); ddp.A_StartSound("misc/boowomp", CHAN_BODY, CHANF_OVERLAP);
						dropChoice = -1; ddp.player.SetPSprite(PSP_WEAPON, FindState('Ready')); bmodeready = true; return null; 
					}
					for(int x = 0; x < pInv.items.Size(); x++)
					{
						if(pInv.RetItem(x).weaponName == "emptie")
						{
							ddp.A_Log("Stored "..rw.GetTag());
							pInv.RetItem(x).construct(rw.GetParentType(), rw.rating, rw.GetWeaponSprite(), rw.mag);
							ddp.RemoveInventory(rw);
							rWeap.SetItem(ddWeapon(ddp.GetFists(0)), ddp.rwx);
							if(++ddp.rwx > rWeap.size - 1) { ddp.rwx = 0; }
							rSwapTarget = ddp.rwx;
							ddp.player.setpsprite(PSP_RIGHTW, rWeap.RetItem(ddp.rwx).GetUpState());
							ddp.ddWeaponState &= ~DDW_RIGHTREADY;
							bModeReady = false;
							pspr.y = 128;
							psprf.y = 128;	
							ddp.player.SetPSprite(PSP_WEAPON, FindState('QuickSwapDW'));
							rWeap.RetItem(ddp.rwx).companionpiece = lWeap.RetItem(ddp.lwx);
							lWeap.RetItem(ddp.lwx).companionpiece = rWeap.RetItem(ddp.rwx);
							dropChoice = -1;
							return null;
						}
					}
					ddp.A_Log("Dropped "..rw.GetTag());
					let tos = ddWeapon(Spawn(rw.GetParentType()));
					tos.AmmoGive1 = 0;
					tos.AttachToOwner(owner);
					tos.mag = rw.mag;
					ddp.RemoveInventory(rw);
					rWeap.SetItem(ddWeapon(ddp.GetFists(0)), ddp.rwx);
					if(++ddp.rwx > rWeap.size - 1) { ddp.rwx = 0; }
					rSwapTarget = ddp.rwx;
					ddp.player.setpsprite(PSP_RIGHTW, rWeap.RetItem(ddp.rwx).GetUpState());
					ddp.ddWeaponState &= ~DDW_RIGHTREADY;
					bModeReady = false;
					pspr.y = 128;
					psprf.y = 128;	
					ddp.player.SetPSprite(PSP_WEAPON, FindState('QuickSwapDW'));
					rWeap.RetItem(ddp.rwx).companionpiece = lWeap.RetItem(ddp.lwx);
					lWeap.RetItem(ddp.lwx).companionpiece = rWeap.RetItem(ddp.rwx);
					dropChoice = -1;
					return ddWeapon(tos.CreateTossable());
				}
				else { return null; }
			}
		}
		else { ddp.A_Log("\caWeapons not ready"); return null; }
	}
	
	action void ChooseSide()
	{
		if(invoker.dropTimer > (35*4)) { A_StartSound("misc/chat2", CHAN_WEAPON, 0, 0.67, ATTN_NORM, 0.18); A_Log("\cgDrop timeout"); invoker.dropChoice = -1; player.SetPSprite(PSP_WEAPON, invoker.FindState('Ready')); }
		if(A_PressingLeftFire())
		{	
			if(invoker.dropChoice != 1) { A_Log("Left side chosen. Press \ctdrop\c- again");
				A_StartSound("misc/chat2", CHAN_BODY, 0, 1.0, ATTN_NORM, 0.5); }
			invoker.dropChoice = 1;
			invoker.dropTimer = -1;
		}
		else if(A_PressingRightFire())
		{
			if(invoker.dropChoice != 0) { A_Log("Right side chosen. Press \ctdrop\c- again");
				A_StartSound("misc/chat2", CHAN_BODY, 0, 1.0, ATTN_NORM, 0.5); }
			invoker.dropChoice = 0;
			invoker.dropTimer = -1;
		}
		else if(PressingReload())
		{
			A_Log("\cgDrop cancelled"); 
			A_StartSound("misc/chat2", CHAN_WEAPON, 0, 0.67, ATTN_NORM, 0.18);
			invoker.dropChoice = -1;
			invoker.dropTimer = -1;
			invoker.bmodeready = true;
			player.SetPSprite(PSP_WEAPON, invoker.FindState('Ready'));
		}
		else {}
	}
	
	override void HUDA(ddStats hude)
	{
		let ddp = ddPlayer(owner);
		let lWeap = ddp.GetLeftWeapons();
		let rWeap = ddp.GetRightWeapons();
		let mode = dualWielding(self);
		let pInv = ddp.GetWeaponsInventory();
		ddWeapon CurLWp, CurRWp;
		if(lWeap.items.size())
		{
			CurLWp = ddp.GetLeftWeapon(ddp.lwx);
		}
		if(rWeap.items.size())
		{
			CurRWp = ddp.GetRightWeapon(ddp.rwx);	
		}
		let typel = (ddp.FindInventory("ClassicModeToken")) ?
		((!CurLWp.bAltFire) ? CurLWp.ClassicAmmoType1 : CurLWp.ClassicAmmoType2) :
		((!CurLWp.bAltFire) ? CurLWp.AmmoType1 : CurLWp.AmmoType2);
		let typer = (ddp.FindInventory("ClassicModeToken")) ?
		((!CurRWp.bAltFire) ? CurRWp.ClassicAmmoType1 : CurRWp.ClassicAmmoType2) :
		((!CurRWp.bAltFire) ? CurRWp.AmmoType1 : CurRWp.AmmoType2);
		if(CurLWp && CurRWp)
		{
			let plarm = ddp.FindInventory("BasicArmor");
			int CurLWAm, CurLWMx, CurRWAm, CurRWMx;
			double cellam, cellmx;
			[CurLWAm, CurLWMx] = hude.GetAmount(typel);
			[CurRWAm, CurRWMx] = hude.GetAmount(typer);
			[cellam, cellmx] = hude.GetAmount("Cell");
			let bz = ddp.FindInventory("PowerBerserk");
			let inv = ((ddp.player.cheats & CF_GODMODE) || ddp.FindInventory("PowerInvulnerable"));
			let mxl = (CurLWAm == CurLWMx);
			let mxr = (CurRWAm == CurRWMx);
			bool wolfen = CVar.GetCVar("pl_wolfen", ddp.player).GetBool();
			hude.DrawImage(bz ? "HCBRZK" : "HCNORM", (35, -20), hude.DI_SCREEN_LEFT_BOTTOM, bz ? 0.4 : 0.8);
			hude.DrawImage(inv ? "HCINVN" : "", (35, -20), hude.DI_SCREEN_LEFT_BOTTOM, 0.9);
			hude.DrawString(hude.bf, (ddp.Health > -200) ? hude.FormatNumber(ddp.Health) : "REALLY FREAKIN' DEAD", (50, -35), hude.DI_SCREEN_LEFT_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, 0, 0.5, -1, 4, (1.25,1.25));
			if(ddp.FindInventory("ESOA"))
			{				
				hude.DrawString(hude.fa, "esoa", (0, -25), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, 0, (ddp.esoaActive) ? 0.7 : 0.33);
				hude.DrawString(hude.fa, "[           ]", (0, -15), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, 0, (ddp.esoaActive) ? 0.7 : 0.33);
				double width = (40 * (cellam / cellmx));
				Color cl = (ddp.esoaActive) ? Color(200, 0, 120, 200) : Color(200, 200, 10, 0);
				hude.Fill(cl, -19, -14, width, 5, hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER);
			}
			if(mode.dropChoice > -1)
			{
				int fade = 50 - (50 * sin(hude.oscilator));
				int stretch = 2 - (2 * sin(hude.oscilator));
				if(mode.DropChoice == 1)
				{
					hude.Fill(Color(200-fade, 255, 0, 0), -82, -12-(stretch/2), 40, 2+stretch, hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER);
				}
				else if(mode.DropChoice == 0)
				{
					hude.Fill(Color(200-fade, 255, 0, 0), 46, -12-(stretch/2), 40, 2+stretch, hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER);
				}
				else {}				
			}
			if(ddp.ddWeaponState & DDW_WANNAREPLACE)
			{
				int fade = 50 - (50 * sin(hude.oscilator));
				int stretch = 2 - (2 * sin(hude.oscilator));
				if(ddp.ddWeaponState & DDW_REPLACELEFT)
				{
					hude.Fill(Color(200-fade, 120, 0, 255), -82, -12-(stretch/2), 40, 2+stretch, hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER);
				}
				else if(ddp.ddWeaponState & DDW_REPLACERIGHT)
				{
					hude.Fill(Color(200-fade, 120, 0, 255), 46, -12-(stretch/2), 40, 2+stretch, hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER);
				}
				else {}
			}
			
			if(!(CurLWp is "ddFist"))
			{
				hude.DrawString(hude.bf, hude.FormatNumber(curLWAm), (-64, -35), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, mxl ? Font.CR_DARKGREEN : 0, 0.5, -1, 4, (1.25,1.25));
			}
			else
			{
				hude.DrawString(hude.bf, "Empty", (-64, -35), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, mxl ? Font.CR_DARKGREEN : 0, 0.5, -1, 4, (1.25,1.25));
				hude.DrawString(hude.bf, curlWp.GetTag(), (-64, -20), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, mxl ? Font.CR_DARKGREEN : 0, 0.5, -1, 4, (0.5,0.5));
			}
			
			if(!(CurRWp is "ddFist"))
			{
				hude.DrawString(hude.bf, hude.FormatNumber(curRWAm), (64, -35), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, mxr ? Font.CR_DARKGREEN : 0, 0.5, -1, 4, (1.25,1.25));
			}
			else
			{
				hude.DrawString(hude.bf, "Empty", (65, -35), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, mxr ? Font.CR_DARKGREEN : 0, 0.5, -1, 4, (1.25,1.25));
				hude.DrawString(hude.bf, currwp.GetTag(), (65, -20), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, mxr ? Font.CR_DARKGREEN : 0, 0.5, -1, 4, (0.5,0.5));
			}
			if(wolfen)
			{
				if(!ddp.FindInventory("ClassicModeToken"))
				{
					hude.DrawString(hude.fa, ddp.altmodeL ? "A" : "P", (-64, -48), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER);
					hude.DrawString(hude.fa, ddp.altmodeR ? "A" : "P", (65, -48), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER);
				}
			}		
			if(ddp.desire)
			{
				if(ddp is "ddPlayerClassic")
				{
					hude.DrawString(hude.fa, ddp.desire.GetTag(), (12, 45), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
					hude.DrawString(hude.fa, "Spare ammo: "..hude.FormatNumber(ddp.desire.AmmoGive1), (12, 52), hude.DI_SCREEN_CENTER | hude.DI_TEXT_ALIGN_LEFT);
				}
				else { ddp.desire.PreviewInfo(hude); }
			}
			hude.DrawInventoryIcon(plarm, (-35, -20), 0, 0.4);
			hude.DrawString(hude.bf, hude.FormatNumber(plarm.Amount), (-50, -35), hude.DI_SCREEN_RIGHT_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, 0, 0.5, -1, 4, (1.25,1.25));
			if(ddp.dddebug & DBG_WEAPONS)
			{			
				
				hude.DrawString(hude.bf, ".", (50, -75), hude.DI_SCREEN_LEFT_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, (ddp.ddWeaponState & DDW_LEFTREADY) ? Font.CR_GREEN : Font.CR_RED);
				hude.DrawString(hude.bf, ".", (50, -65), hude.DI_SCREEN_LEFT_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, (curLWp.weaponready) ? Font.CR_CYAN : Font.CR_RED);	
				if(ddp.dddebug & DBG_VERBOSE && curLWp.companionpiece){
					hude.DrawImage(curLWp.companionpiece.GetWeaponSprite(), (50, -75), hude.DI_SCREEN_LEFT_BOTTOM);}
				hude.DrawString(hude.bf, ".", (0, -15), hude.DI_SCREEN_CENTER_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, (bModeReady) ? Font.CR_GREEN : Font.CR_RED);
				hude.DrawString(hude.bf, ".", (-50, -75), hude.DI_SCREEN_RIGHT_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, (ddp.ddWeaponState & DDW_RIGHTREADY) ? Font.CR_GREEN : Font.CR_RED);		
				hude.DrawString(hude.bf, ".", (-50, -65), hude.DI_SCREEN_RIGHT_BOTTOM | hude.DI_TEXT_ALIGN_CENTER, (curRWp.weaponready) ? Font.CR_CYAN : Font.CR_RED);			
				if(ddp.dddebug & DBG_VERBOSE && curRWp.companionpiece){
					hude.DrawImage(curRWp.companionpiece.GetWeaponSprite(), (-50, -75), hude.DI_SCREEN_RIGHT_BOTTOM);}
			}
		}
		
	}
	
	
	
	action void A_FireDualWield()
	{
		let ddp = ddPlayer(invoker.owner);
		let lw = ddp.GetLeftWeapon(ddp.lwx);
		let rw = ddp.GetRightWeapon(ddp.rwx);
		//left primary/alternative
		if(ddp.ddWeaponState & DDW_WANNAREPLACE) 
		{ 
			if(A_PressingLeftFire() || A_PressingLeftAltFire()) 
			{ 
				if(!(ddp.ddWeaponState & DDW_REPLACELEFT)) { A_StartSound("misc/chat2", CHAN_BODY, 0, 1.0, ATTN_NORM, 0.5); }
				ddp.ddWeaponState |= DDW_REPLACELEFT; 
				ddp.ddWeaponState &= ~DDW_REPLACERIGHT;
			}
			else if(A_PressingRightFire() || A_PressingRightAltFire()) 
			{ 
				if(!(ddp.ddWeaponState & DDW_REPLACERIGHT)) { A_StartSound("misc/chat2", CHAN_BODY, 0, 1.0, ATTN_NORM, 0.5); }
				ddp.ddWeaponState |= DDW_REPLACERIGHT; 
				ddp.ddWeaponState &= ~DDW_REPLACELEFT;
			}
		}
		else
		{
			if(A_PressingFireButton() || A_PressingLeftModeSwitch() || A_PressingRightModeSwitch())
			{
				//left primary/alternative
				if(A_PressingLeftFire())
				{
					if(ddp.ddWeaponState & DDW_LEFTREADY)
					{
						//ddp.PlayAttacking();
						lw.weaponStatus = DDW_FIRING;
						ddp.ddWeaponState &= ~DDW_LEFTREADY;
						ddp.ddWeaponState &= ~DDW_LEFTBOBBING;
						lw.bAltFire = false;
						player.SetPSprite(PSP_LEFTW, lw.GetAttackState());
						if(!lw.bNoAlert)
						{
							SoundAlert(self);
						}
						lw.weaponready = false;
					}		
				}
				else if(A_PressingLeftAltFire())
				{
					if(FindInventory("ClassicModeToken")) { return; }
					if(ddp.ddWeaponState & DDW_LEFTREADY)
					{
						//ddp.PlayAttacking();
						lw.weaponStatus = DDW_FIRING;
						ddp.ddWeaponState &= ~DDW_LEFTREADY;
						ddp.ddWeaponState &= ~DDW_LEFTBOBBING;
						lw.bAltFire = true;
						player.SetPSprite(PSP_LEFTW, lw.GetAttackState());
						if(!lw.bNoAlert)
						{
							SoundAlert(self);
						}
						lw.weaponready = false;
					}			
				}
				else if(A_PressingLeftModeSwitch())
				{
					if(FindInventory("ClassicModeToken")) { return; }
					if(ddp.ddWeaponState & DDW_LEFTREADY)
					{
						ddp.altmodeL = !ddp.altmodeL;
						lw.weaponStatus = DDW_FIRING;
						lw.bAltFire = false;
						A_StartSound("weapons/chaingunspin", CHAN_BODY, CHANF_OVERLAP);
						player.SetPSprite(PSP_LEFTW, lw.FindState('NoAmmo'));
						ddp.ddWeaponState &= ~DDW_LEFTREADY;
						lw.weaponready = false;
					}			
				}
				//right primary/alternative
				if(A_PressingRightFire())
				{
					if(ddp.ddWeaponState & DDW_RIGHTREADY)
					{
						//ddp.PlayAttacking();
						rw.weaponStatus = DDW_FIRING;
						ddp.ddWeaponState &= ~DDW_RIGHTREADY;
						ddp.ddWeaponState &= ~DDW_RIGHTBOBBING;
						rw.bAltFire = false;
						player.SetPSprite(PSP_RIGHTW, rw.GetAttackState());
						if(!rw.bNoAlert)
						{
							SoundAlert(self);
						}
						rw.weaponready = false;
					}			
				}
				else if(A_PressingRightAltFire())
				{
					if(FindInventory("ClassicModeToken")) { return; }
					if(ddp.ddWeaponState & DDW_RIGHTREADY)
					{
						//ddp.PlayAttacking();
						rw.weaponStatus = DDW_FIRING;
						ddp.ddWeaponState &= ~DDW_RIGHTREADY;
						ddp.ddWeaponState &= ~DDW_RIGHTBOBBING;
						rw.bAltFire = true;
						player.SetPSprite(PSP_RIGHTW, rw.GetAttackState());
						if(!rw.bNoAlert)
						{
							SoundAlert(self);
						}
						rw.weaponready = false;
					}			
				}
				else if(A_PressingRightModeSwitch())
				{
					if(FindInventory("ClassicModeToken")) { return; }
					if(ddp.ddWeaponState & DDW_RIGHTREADY)
					{
						ddp.altmodeR = !ddp.altmodeR;
						rw.weaponStatus = DDW_FIRING;
						rw.bAltFire = false;
						A_StartSound("weapons/chaingunspin", CHAN_BODY, CHANF_OVERLAP);
						player.SetPSprite(PSP_RIGHTW, rw.FindState('NoAmmo'));
						ddp.ddWeaponState &= ~DDW_RIGHTREADY;
						rw.weaponready = false;
					}			
				}
			}
			else if(A_PressingReload())
			{
				if(FindInventory("ClassicModeToken")) { return; }
				if(player.cmd.buttons & BT_USE)
				{
					if(ddp.ddWeaponState & DDW_RIGHTREADY)
					{
						A_CheckRightWeaponMag();
						lw.weaponready = false;
						rw.weaponready = false;
					}					
				}
				else
				{					
					if(ddp.ddWeaponState & DDW_LEFTREADY)
					{
						A_CheckLeftWeaponMag();
						lw.weaponready = false;
						rw.weaponready = false;		
					}	
				}
			}
		}
		
	}
	
	action void A_QuickSwapDW()
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
		int sFactor;
		if(lw && rw) 
		{ 
			sFactor = ((lw.sFactor + rw.sFactor) / 2) * 6;
			if(ddp.lwx != invoker.lSwapTarget) //lower left weapon
			{
				ddp.ddWeaponState &= ~DDW_LEFTREADY;
				pspl.y += sFactor; psplf.y += sFactor;
				if(pspl.y < WEAPONBOTTOM) { /* ") */ }
				else
				{
					pspl.y = 128; psplf.y = 128;
					pspl.x = -64 - lw.xOffset; 
					ddp.lwx = invoker.lSwapTarget;
					lw = lWeap.RetItem(ddp.lwx);
					if(lw.bTwoHander) { ddp.ddWeaponState |= DDW_LEFTISTH; }
					else { ddp.ddWeaponState &= ~DDW_LEFTISTH; }
					lw = ddp.GetLeftWeapon(ddp.lwx);
					if(lw.UpSound) { ddp.A_StartSound(lw.UpSound, CHAN_WEAPON); }
					player.SetPSprite(PSP_LEFTW, lw.GetUpState());
					player.SetPSprite(PSP_LEFTWF, null);
					player.GetPSprite(PSP_LEFTWF).x = -64 - lw.xOffset;
				}
			}
			else //raise left weapon
			{
				pspl.y -= sFactor; psplf.y -= sFactor;
				if(pspl.y > 0) { /* no */ }
				else
				{
					pspl.y = 0; psplf.y = 0;
					if(rw) { lw.companionpiece = rw; rw.companionpiece = rw; }
					player.SetPSprite(PSP_LEFTW, lw.GetReadyState());
				}
			}
			
			if(ddp.rwx != invoker.rSwapTarget) //lower right weapon
			{
				ddp.ddWeaponState &= ~DDW_RIGHTREADY;
				pspr.y += sFactor; psprf.y += sFactor;
				if(pspr.y < WEAPONBOTTOM) {  }
				else
				{
					pspr.y = 128; psprf.y = 128;
					pspr.x = 64 + rw.xOffset;
					ddp.rwx = invoker.rSwapTarget;
					rw = rWeap.RetItem(ddp.rwx);
					if(rw.bTwoHander) { ddp.ddWeaponState |= DDW_RIGHTISTH; }
					else { ddp.ddWeaponState &= ~DDW_RIGHTISTH; }
					rw = ddp.GetRightWeapon(ddp.rwx);
					if(rw.UpSound) { ddp.A_StartSound(rw.UpSound, CHAN_WEAPON); }
					player.SetPSprite(PSP_RIGHTW, rw.GetUpState());
					player.SetPSprite(PSP_RIGHTWF, null);
					player.GetPSprite(PSP_RIGHTWF).x = 64 + rw.xoffset;
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
				}
			}
			
			if(ddp.ddWeaponState & DDW_LEFTREADY && ddp.ddWeaponState & DDW_RIGHTREADY) //alt delete
			{
				invoker.bModeReady = true;
				invoker.weaponStatus = DDW_READY;
				A_ChangeState('Ready');
			}
		}
		
	}
	
	action void A_RaiseDual()
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
		double sFactor = (lw.sFactor + rw.sFactor) / 2.0;
		if(ddp.ddWeaponState & DDW_RIGHTISTH && pspr.y > 0)
		{
			pspr.y -= 4 * sFactor; psprf.y -= 4 * sFactor;	
			if(pspr.y < 1) { pspr.y = 0; psprf.y = 0; }
		}
		else
		{
			pspl.y -= 6 * sFactor;
			psplf.y -= 6 * sFactor;
			pspr.y -= 6 * sFactor;
			psprf.y -= 6 * sFactor;
			if(pspr.y > 0) { return; }
			pspl.y = 0; psplf.y = 0;
			pspl.x = -64; psplf.x = -64;
			pspr.y = 0; psprf.y = 0;
			pspr.x = 64 + rw.xOffset; psprf.x = 64 + rw.xOffset;
			if(ddp.dddebug & DBG_WEAPONS) { A_Log("mode ready"); }
			invoker.bmodeReady = true;
			if(lWeap.items.Size()) { player.setpsprite(PSP_LEFTW, lw.GetReadyState()); }
			if(rWeap.items.Size()) { player.setpsprite(PSP_RIGHTW, rw.GetReadyState()); }
			ddp.ddWeaponState &= ~DDW_LEFTNOBOBBING; 
			ddp.ddWeaponState &= ~DDW_RIGHTNOBOBBING;
			invoker.weaponstatus = DDW_READY;
			A_ChangeState("Ready");
		}
	}
	
	action void A_SwitchToSingle()
	{		
		let ddp = ddPlayer(self);
		let lWeap = ddp.GetLeftWeapons();
		let rWeap = ddp.GetRightWeapons();		
		if(ddp.ddWeaponState & DDW_WANNAREPLACE && ddPlayer(self).gethelp) { A_Log("\cgSwap cancelled"); }
		invoker.weaponStatus = DDM_SWAPPING;
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
		double sFactor = ((lw.sFactor + rw.sFactor) / 2.0) * bsk;			
		if(ddp.ddWeaponState & DDW_RIGHTISTH && pspr.y < 128)
		{			
			pspr.y += 6 * sFactor; psprf.y += 6 * sFactor;
			if(pspr.y > 128) { pspr.y = 128; psprf.y = 128; }
		}
		else
		{
			pspr.x -= 2 * sFactor; psprf.x -= 2 * sFactor;
			pspl.y += 6 * sFactor;
			psplf.y += 6 * sFactor;
			if(pspl.y < 128) { return; }
			pspl.y = 128; psplf.y = 128;
			pspl.x = -64; psplf.x = -64;
			if(!(ddp.ddWeaponState & DDW_RIGHTISTH)) { pspr.y = 0; psprf.y = 0; }
			pspr.x = 0; psprf.x = 0;
			let thd = ddWeapon(FindInventory("twoHanding"));
			thd.weaponstatus = DDW_RELOADING;
			thd.lSwapTarget = invoker.lSwapTarget;
			thd.rSwapTarget = invoker.rSwapTarget;
			player.pendingweapon = WP_NOCHANGE;
			player.readyweapon = thd;
			ddp.lastmode = thd;
			let rw = ddp.GetRightWeapon(ddp.rwx);
			player.setpsprite(PSP_RIGHTW, rw.GetUpState());
			player.SetPSprite(PSP_WEAPON, thd.GetUpState());
		}
		return;
	}
	
	// ## dualWielding States()
	States
	{
		Ready:
			TNT1 A 1 A_WeaponReady(WRF_FULL);
			Loop;
		Select:
		RaiseDual:
			TNT1 A 1 A_RaiseDual;
			Loop;
		Deselect:
			---- A 1 A_SwitchToSingle;
			Loop;
		ChooseSide:
			---- A 1 ChooseSide;
			Loop;
		Fire:
			---- A 1 A_FireDualWield;
			Goto Ready;
		AltFire:
			---- A 1 A_FireDualWield;
			Goto Ready;
		Reload:
			---- A 1 A_FireDualWield;
			Goto Ready;
		Zoom:
			---- A 10 
			{ 
				if(!(ddPlayer(self).ddWeaponState & DDW_WANNAREPLACE))
				{ A_StartSound("misc/chat2", CHAN_BODY, 0, 0.67); ddPlayer(self).ddWeaponState |= DDW_WANNAREPLACE; 
				  A_Log("\ctRight primary\c-: Select Right\n\ctLeft primary\c-: Select Left\n\ctZoom\c-: Cancel");
				}
				else { A_StartSound("misc/chat2", CHAN_BODY, 0, 0.67, ATTN_NORM, 0.18); 
					ddPlayer(self).ddWeaponState &= ~DDW_WANNAREPLACE; ddPlayer(self).ddWeaponState &= ~DDW_REPLACELEFT; ddPlayer(self).ddWeaponState &= ~DDW_REPLACERIGHT;
				    A_Log("\cgSwap cancelled");
				}
			}
			Goto Ready;
		User1:
			---- A 1 A_FireDualWield;
			Goto Ready;
		User2:
			---- A 1 A_FireDualWield;
			Goto Ready;
		User3:
			---- A 0;
			Goto Ready;
		User4:
			---- A 0;
			Goto Ready;
		QuickSwapDW:
			---- A 1 A_QuickSwapDW;
			Loop;
	}
}