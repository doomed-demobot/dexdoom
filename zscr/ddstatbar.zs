// #Class ddStats : BaseStatusBar()
//Status bar
class ddStats : BaseStatusBar
{
	ddPlayer dPlay;
	HUDFont bf;
	HUDFont fa;
	int qSwapPopUp, lwIconX, rwIconX;
	int PUSwapX;
	int dwDropX;
	int oscilator;
	int lInd, rInd; //for HUDB
	int lwyp, rwyp;
	float lwa, rwa;
	override void Init()
	{
		Super.Init();
		qSwapPopUp = -1;
		PUSwapX = 0;
		dwDropX = 0;
		lwIconX = 0;
		rwIconX = 0;
		bf = HUDFont.Create(BigFont);
		fa = HUDFont.Create(SmallFont);
		oscilator = 0;
		lInd = rInd = 0;
		lwa = rwa = 0.0;
		SetSize(0, 320, 200);
	}
	
	override void Tick()
	{
		Super.Tick();
		dPlay = ddPlayer(CPlayer.mo);
	}
	
	override void Draw(int state, double TicFrac)
	{
		if(!CPlayer.mo || !dPlay) {return;}		
		Super.Draw(state, TicFrac);
		if(automapactive)
		{
			DrawAutomapHUD(TicFrac);
			DrawAutomapStuff();
		}
		else
		{
			if(state == HUD_StatusBar) 
			{
				SetSize(0, 320, 200);
				BeginHud();
				DrawMainBar(TicFrac);
			}
			else if(state == HUD_Fullscreen) 
			{
				SetSize(0, 320, 200);
				BeginHUD();
				DrawFullScreenStuff(TicFrac);
			}
		}
		oscilator++;
		if(qSwapPopUp > -1) { qSwapPopUp--; }
	}
	
	//draw hud and weapon wheels
	void DrawMainBar(double TicFrac)
	{	
		if(dPlay)
		{
			let wep = ddWeapon(dPlay.player.readyweapon);
			ddWeapon rw, lw;
			let lWeap = dPlay.GetLeftWeapons();
			let rWeap = dPlay.GetRightWeapons();
			rw = dPlay.GetRightWeapon(dPlay.rwx);
			lw = dPlay.GetLeftWeapon(dPlay.lwx);
			if(wep) 
			{ 
				if(dPlay.debuggin) 
				{ 
					DrawString(bf, "d", (-20, 20), DI_SCREEN_RIGHT_TOP);
					DPlayDebug();
					if(dPlay.phyrec) { DrawString(fa, "p", (-25, 20), DI_SCREEN_RIGHT_TOP); }
					if(dPlay.visrec) { DrawString(fa, "v", (-25, 25), DI_SCREEN_RIGHT_TOP); }
				}
				wep.HUDB(self);
				if(rw && lw)
				{
					rw.HUDB(self);
					if(wep is "dualWielding") { lw.HUDB(self); }
					
					//draw weapon wheel
					if(!(wep is "playerinventory"))
					{
						int rwxp, lwxp, ind, not;
						if(lInd == wep.lSwapTarget && lwyp < 1)
						{
							ind = lInd;
							if(++ind > lWeap.items.Size() - 1) { ind = 0; }
							[lwxp, not] = TexMan.GetSize(TexMan.CheckForTexture(lWeap.RetItem(ind).GetWeaponSprite()));
							DrawImage(lWeap.RetItem(ind).GetWeaponSprite(), (10 + (lwxp/2), -25), DI_SCREEN_LEFT_CENTER, 0.3);
							[lwxp, not] = TexMan.GetSize(TexMan.CheckForTexture(lWeap.RetItem(lInd).GetWeaponSprite()));
							DrawImage(lWeap.RetItem(wep.lSwapTarget).GetWeaponSprite(), (10 + (lwxp/2), 0), DI_SCREEN_LEFT_CENTER, 0.8);
							ind = lInd;
							if(--ind < 0) { ind = lWeap.items.Size() - 1; }
							[lwxp, not] = TexMan.GetSize(TexMan.CheckForTexture(lWeap.RetItem(ind).GetWeaponSprite()));
							DrawImage(lWeap.RetItem(ind).GetWeaponSprite(), (10 + (lwxp/2), 25), DI_SCREEN_LEFT_CENTER, 0.3);
						}
						else
						{
							ind = lInd;
							if(++ind > lWeap.items.Size() - 1) { ind = 0; }
							[lwxp, not] = TexMan.GetSize(TexMan.CheckForTexture(lWeap.RetItem(ind).GetWeaponSprite()));
							DrawImage(lWeap.RetItem(ind).GetWeaponSprite(), (10 + (lwxp/2), -25 + lwyp), DI_SCREEN_LEFT_CENTER, 0.3);
							[lwxp, not] = TexMan.GetSize(TexMan.CheckForTexture(lWeap.RetItem(lInd).GetWeaponSprite()));
							DrawImage(lWeap.RetItem(lind).GetWeaponSprite(), (10 + (lwxp/2), 0 + lwyp), DI_SCREEN_LEFT_CENTER, 0.8);
							ind = lInd;
							if(--ind < 0) { ind = lWeap.items.Size() - 1; }
							[lwxp, not] = TexMan.GetSize(TexMan.CheckForTexture(lWeap.RetItem(ind).GetWeaponSprite()));
							DrawImage(lWeap.RetItem(ind).GetWeaponSprite(), (10 + (lwxp/2), 25 + lwyp), DI_SCREEN_LEFT_CENTER, 0.3);
							lwyp++;
							if(lwyp >= 25) { 
								if(++lInd > lWeap.items.Size() - 1) { lInd = 0; };
								lwyp = 0;							
							}
						}
						if(rInd == wep.rSwapTarget && rwyp < 1)
						{
							rInd = wep.rSwapTarget;
							ind = rInd;
							if(++ind > rWeap.items.Size() - 1) { ind = 0; }
							[rwxp, not] = TexMan.GetSize(TexMan.CheckForTexture(rWeap.RetItem(ind).GetWeaponSprite()));
							DrawImage(rWeap.RetItem(ind).GetWeaponSprite(), (-10 - (rwxp/2), -25), DI_SCREEN_RIGHT_CENTER, 0.45);	
							[rwxp, not] = TexMan.GetSize(TexMan.CheckForTexture(rWeap.RetItem(rInd).GetWeaponSprite()));
							DrawImage(rWeap.RetItem(wep.rSwapTarget).GetWeaponSprite(), (-10 - (rwxp/2), 0), DI_SCREEN_RIGHT_CENTER, 0.8);	
							ind = rInd;
							if(--ind < 0) { ind = rWeap.items.Size() - 1; }
							[rwxp, not] = TexMan.GetSize(TexMan.CheckForTexture(rWeap.RetItem(ind).GetWeaponSprite()));
							DrawImage(rWeap.RetItem(ind).GetWeaponSprite(), (-10 - (rwxp/2), 25), DI_SCREEN_RIGHT_CENTER, 0.45);
						}
						else
						{
							ind = rInd;
							if(++ind > rWeap.items.Size() - 1) { ind = 0; }
							[rwxp, not] = TexMan.GetSize(TexMan.CheckForTexture(rWeap.RetItem(ind).GetWeaponSprite()));
							DrawImage(rWeap.RetItem(ind).GetWeaponSprite(), (-10 - (rwxp/2), -25 + rwyp), DI_SCREEN_RIGHT_CENTER, 0.45);	
							[rwxp, not] = TexMan.GetSize(TexMan.CheckForTexture(rWeap.RetItem(rInd).GetWeaponSprite()));
							DrawImage(rWeap.RetItem(rind).GetWeaponSprite(), (-10 - (rwxp/2), 0 + rwyp), DI_SCREEN_RIGHT_CENTER, 0.8);	
							ind = rInd;
							if(--ind < 0) { ind = rWeap.items.Size() - 1; }
							[rwxp, not] = TexMan.GetSize(TexMan.CheckForTexture(rWeap.RetItem(ind).GetWeaponSprite()));
							DrawImage(rWeap.RetItem(ind).GetWeaponSprite(), (-10 - (rwxp/2), 25 + rwyp), DI_SCREEN_RIGHT_CENTER, 0.45);
							rwyp++;
							if(rwyp >= 25) { 
								if(++rInd > rWeap.items.Size() - 1) { rInd = 0; };
								rwyp = 0;							
							}
						}
					}
					
					if(dPlay.GetLeftWeapon(wep.lSwapTarget).bTwoHander) { DrawString(bf, "!", (-75 + lwIconX, 0), DI_SCREEN_LEFT_CENTER, Font.CR_RED); }
					if(dPlay.GetRightWeapon(wep.rSwapTarget).bTwoHander) { DrawString(bf, "!", (75 - rwIconX, 0), DI_SCREEN_RIGHT_CENTER, Font.CR_RED); }
					if(wep.weaponStatus == DDM_SWAPPING) { qSwapPopUp = 100; }
					if(dPlay.ddWeaponState & DDW_WANNAREPLACE) { PUSwapX += 5; if(PUSwapX > 120) { PUSwapX = 120; } }
					else { PUSwapX -= 5; if(PUSwapX < 0) { PUSwapX = 0; } }
					if(wep is "dualwielding")
					{
						if(dualWielding(wep).dropTimer > -1) { dwDropX += 5; if(dwDropX > 120) { dwDropX = 120; } }
						else { dwDropX -= 5; if(dwDropX < 0) { dwDropX = 0; } }
					}
					DrawImage("SWAPICON", (70 - PUSwapX, 45), DI_SCREEN_RIGHT_CENTER);
					DrawImage("DROPICON", (70 - dwDropX, 75), DI_SCREEN_RIGHT_CENTER);
				}
			}
			DrawString(fa, "[", (90, -15), DI_SCREEN_CENTER_BOTTOM, Font.CR_TEAL);
			int dis = 0;
			for(inventory keys = dPlay.Inv; keys != null; keys = keys.inv)
			{
				if(keys is "Key")
				{
					DrawTexture(keys.Icon, (101 + dis, -10), DI_SCREEN_CENTER_BOTTOM);
					dis += 10;
				}
			}
			DrawString(fa, "]", (95 + dis, -15), DI_SCREEN_CENTER_BOTTOM, Font.CR_TEAL);
			
			DrawCrosshair();
		}
	}
	
	//todo: learn math because this needs math
	void DrawCrosshair()
	{
		let lWeap = dPlay.GetLeftWeapon(dPlay.lwx);
		let rWeap = dPlay.GetRightWeapon(dPlay.rwx);
		let hscale = GetHUDScale();
		int scX = int(hscale.X);
		int scY = int(hscale.Y);
		int ht = Screen.GetHeight() / scX;
		int wd = Screen.GetWidth() / scX;
		int xposR = (wd / 2);// - (rweap.myInfo.aimOffsetAngle * ( Screen.GetWidth() / 360. )); 
		int yposR = (ht / 2);// + (rweap.myInfo.aimOffsetPitch * ( Screen.GetHeight() / 180. ));
		int xposL = (wd / 2);// - (lweap.myInfo.aimOffsetAngle * ( Screen.GetWidth() / 360. ));
		int yposL = (ht / 2);// + (lweap.myInfo.aimOffsetPitch * ( Screen.GetHeight()  / 180. ));
		Screen.DrawTexture(TexMan.CheckForTexture(rWeap.reticlename), false, xposR, yposR, DTA_Alpha, 0.80, DTA_KeepRatio, true,
		DTA_VirtualWidth, wd, DTA_VirtualHeight, ht, DTA_Color, 0xFFFF0000,
		DTA_ScaleX, (0.25 + (0.25 * (double(dPlay.rightInstability) / 200) ) + (0.2 * (double(dPlay.insTimerRight / 2) / 20 ) ) ) * rWeap.reticleScale, 
		DTA_ScaleY, (0.25 + (0.25 * (double(dPlay.rightInstability) / 200) ) + (0.2 * (double(dPlay.insTimerRight / 2) / 20 ) ) ) * rWeap.reticleScale );
		
		Screen.DrawTexture(TexMan.CheckForTexture(lWeap.reticlename), false, xposL, yposL, DTA_Alpha, 0.80, DTA_KeepRatio, true,
		DTA_VirtualWidth, wd, DTA_VirtualHeight, ht, DTA_Color, 0xFF0000FF,
		DTA_ScaleX, (0.25 + (0.25 * (double(dPlay.leftInstability) / 200) ) + (0.2 * (double(dPlay.insTimerLeft / 2) / 20 ) ) ) * lWeap.reticleScale, 
		DTA_ScaleY, (0.25 + (0.25 * (double(dPlay.leftInstability) / 200) ) + (0.2 * (double(dPlay.insTimerLeft / 2) / 20 ) ) ) * lWeap.reticleScale );
	}
	
	//draw hud
	void DrawFullScreenStuff(double TicFrac)
	{	
		if(dPlay)
		{
			let wep = ddWeapon(dPlay.player.ReadyWeapon);
			ddWeapon rw, lw;
			let lWeap = dPlay.GetLeftWeapons();
			let rWeap = dPlay.GetRightWeapons();
			rw = dPlay.GetRightWeapon(dPlay.rwx);
			lw = dPlay.GetLeftWeapon(dPlay.lwx);
			if(wep) 
			{ 
				if(dPlay.debuggin) 
				{ 
					DrawString(bf, "d", (-20, 20), DI_SCREEN_RIGHT_TOP);
					DPlayDebug();
					if(dPlay.phyrec) { DrawString(fa, "p", (-25, 20), DI_SCREEN_RIGHT_TOP); }
					if(dPlay.visrec) { DrawString(fa, "v", (-25, 25), DI_SCREEN_RIGHT_TOP); }
				}
				wep.HUDA(self);
				if(rw && lw)
				{
					rw.HUDA(self);
					if(wep is "dualWielding") { lw.HUDA(self); }
					DrawImage(lWeap.RetItem(wep.lSwapTarget).GetWeaponSprite(), (-70 + lwIconX, 0), DI_SCREEN_LEFT_CENTER);
					DrawImage(rWeap.RetItem(wep.rSwapTarget).GetWeaponSprite(), (70 - rwIconX, 0), DI_SCREEN_RIGHT_CENTER);
					if(dPlay.GetLeftWeapon(wep.lSwapTarget).bTwoHander) { DrawString(bf, "!", (-75 + lwIconX, 0), DI_SCREEN_LEFT_CENTER, Font.CR_RED); }
					if(dPlay.GetRightWeapon(wep.rSwapTarget).bTwoHander) { DrawString(bf, "!", (75 - rwIconX, 0), DI_SCREEN_RIGHT_CENTER, Font.CR_RED); }
					if(wep.weaponStatus == DDM_SWAPPING) { qSwapPopUp = 100; }
					if(dPlay.ddWeaponState & DDW_WANNAREPLACE) { PUSwapX += 5; if(PUSwapX > 120) { PUSwapX = 120; } }
					else { PUSwapX -= 5; if(PUSwapX < 0) { PUSwapX = 0; } }
					if(wep is "dualwielding")
					{
						if(dualWielding(wep).dropTimer > -1) { dwDropX += 5; if(dwDropX > 120) { dwDropX = 120; } }
						else { dwDropX -= 5; if(dwDropX < 0) { dwDropX = 0; } }
					}
					DrawImage("SWAPICON", (70 - PUSwapX, 45), DI_SCREEN_RIGHT_CENTER);
					DrawImage("DROPICON", (70 - dwDropX, 75), DI_SCREEN_RIGHT_CENTER);
					if(qSwapPopUp > -1)
					{
						if(lwIconX < 120) { lwIconX += 5; }	
						else { lwIconX = 120; }
						if(rwIconX < 120) { rwIconX += 5; }
						else { rwIconX = 120; }							
					}
					else
					{
						if(lwIconX > 0) { lwIconX -= 5; }	
						else { lwIconX = 0; }
						if(rwIconX > 0) { rwIconX -= 5; }	
						else { rwIconX = 0; }
					}
				}
			}
			DrawString(fa, "[", (90, -15), DI_SCREEN_CENTER_BOTTOM, Font.CR_TEAL);
			int dis = 0;
			for(inventory keys = dPlay.Inv; keys != null; keys = keys.inv)
			{
				if(keys is "Key")
				{
					DrawTexture(keys.Icon, (101 + dis, -10), DI_SCREEN_CENTER_BOTTOM);
					dis += 10;
				}
			}
			DrawString(fa, "]", (95 + dis, -15), DI_SCREEN_CENTER_BOTTOM, Font.CR_TEAL);
		}
	}
	//draw when on automap
	void DrawAutomapStuff()
	{
		SetSize(0, 320, 200);
		BeginHUD();
		String bk = (dPlay.FindInventory("Backpack", true)) ? "BPAKA0" : "TNT1A0";
		String ml = (dPlay.FindInventory("ddTactPack")) ? "MOLLE0" : "TNT1A0";
		DrawImage(bk, (10, -5), DI_SCREEN_RIGHT_CENTER, 1., (-1,-1), (0.75,0.75));
		DrawImage(ml, (35, -5), DI_SCREEN_RIGHT_CENTER, 1., (-1,-1), (0.75,0.75));
		DrawString(fa, "Ammo", (0,0), DI_SCREEN_RIGHT_CENTER | DI_TEXT_ALIGN_RIGHT);
		DrawImage("PCLPA0", (-25, 20), DI_SCREEN_RIGHT_CENTER);
		DrawString(fa, ""..dPlay.CountInv("d9Mil"), (-25, 20), DI_SCREEN_RIGHT_CENTER);
		DrawImage("CLIPA0", (-25, 38), DI_SCREEN_RIGHT_CENTER);
		DrawString(fa, ""..dPlay.CountInv("Clip"), (-25, 38), DI_SCREEN_RIGHT_CENTER);
		DrawImage("SHELA0", (-25, 56), DI_SCREEN_RIGHT_CENTER);
		DrawString(fa, ""..dPlay.CountInv("Shell"), (-25, 56), DI_SCREEN_RIGHT_CENTER);
		DrawImage("BFSSA0", (-25, 72), DI_SCREEN_RIGHT_CENTER);
		DrawString(fa, ""..dPlay.CountInv("BFS"), (-25, 72), DI_SCREEN_RIGHT_CENTER);
		DrawImage("ROCKA0", (-25, 106), DI_SCREEN_RIGHT_CENTER);
		DrawString(fa, ""..dPlay.CountInv("RocketAmmo"), (-25, 106), DI_SCREEN_RIGHT_CENTER);
		DrawImage("CELLA0", (-25, 130), DI_SCREEN_RIGHT_CENTER);
		DrawString(fa, ""..dPlay.CountInv("Cell"), (-25, 130), DI_SCREEN_RIGHT_CENTER);		
	}
	
	String ShortenCommandNames(String inp)
	{
		inp.MakeLower();
		inp.Replace("Mouse1", "M1"); 
		inp.Replace("Mouse2", "M2");
		inp.Replace("Mouse3", "M3");
		inp.Replace("Mouse4", "M4");
		inp.Replace("Mouse5", "M5");
		inp.Replace("Backspace", "BS");
		inp.Replace("Enter", "EN");
		inp.Replace("SHIFT", "SH");
		inp.Replace("Space", "SP");
		inp.Replace("Control", "CT");
		return inp;
	}
	
	//todo: add ability to see offsets + coords of different layers for psprite sides.
	void DPlayDebug()
	{
		let wep = ddWeapon(dPlay.player.ReadyWeapon);
		ddWeapon rw, lw;
		let lWeap = dPlay.GetLeftWeapons();
		let rWeap = dPlay.GetRightWeapons();
		let pspl = dPlay.player.GetPSprite(PSP_LEFTW0);
		let pspr = dPlay.player.GetPSprite(PSP_RIGHTW0);
		rw = dPlay.GetRightWeapon(dPlay.rwx);
		lw = dPlay.GetLeftWeapon(dPlay.lwx);
		if(dPlay.dddebug & DBG_VERBOSE)
		{
			int spindle = dPlay.ddWeaponState;
			String label = "";
			Color res;
			for(int x = 16; x > -1; x--)
			{				
				switch(x){
					case 16: label = "RIGHTRAISETOREL"; break;
					case 15: label = "RIGHTLOWERTOREL"; break;
					case 14: label = "LEFTRAISETOREL"; break;
					case 13: label = "LEFTLOWERTOREL"; break;
					case 12: label = "NORIGHTSPRITECHANGE"; break;
					case 11: label = "NOLEFTSPRITECHANGE"; break;
					case 10: label = "RITH"; break;
					case 9: label = "LITH"; break;
					case 8: label = "REPLLEFT"; break;
					case 7: label = "REPLRIGHT"; break;
					case 6: label = "WANTREPL"; break;
					case 5: label = "NOBLEFT"; break;
					case 4: label = "NOBRIGHT"; break;
					case 3: label = "BOBLEFT"; break;
					case 2: label = "BOBRIGHT"; break;
					case 1: label = "LEFTREADY"; break;
					case 0: label = "RIGHTREADY"; break;
				}
				if(spindle & 1 << x) { res = Font.CR_GREEN; }
				else { res = Font.CR_RED; }
				
				DrawString(fa, label, (5,8 + (15*(16-x))), DI_SCREEN_LEFT, res); 
			}
		}
		if(dPlay.dddebug & DBG_PLAYER)
		{
			DrawString(fa, "lins:"..FormatNumber(dPlay.leftInstability), (-70, 70), DI_SCREEN_RIGHT_TOP);
			DrawString(fa, "ltim:"..FormatNumber(dPlay.insTimerLeft), (-70, 80), DI_SCREEN_RIGHT_TOP);
			DrawString(fa, "rins:"..FormatNumber(dPlay.rightInstability), (-70, 90), DI_SCREEN_RIGHT_TOP);
			DrawString(fa, "rtim:"..FormatNumber(dPlay.insTimerRight), (-70, 100), DI_SCREEN_RIGHT_TOP);
			DrawString(fa, "leftheld", (-70, 110), DI_SCREEN_RIGHT_TOP, (wep.leftheld) ? FONT.CR_GREEN : FONT.CR_RED);
			DrawString(fa, "rightheld", (-70, 120), DI_SCREEN_RIGHT_TOP, (wep.rightheld) ? FONT.CR_GREEN : FONT.CR_RED);
		}
		if(dPlay.dddebug & DBG_WEAPONS)
		{				
			int lwfs, rwfs;
			String lwfs2, rwfs2;
			lwfs = lw.ddweaponflags;
			while(lwfs > 0) { lwfs2 = (lwfs % 2)..lwfs2; lwfs >>= 1; }
			rwfs = rw.ddweaponflags;
			while(rwfs > 0) { rwfs2 = (rwfs % 2)..rwfs2; rwfs >>= 1; }
			String lws, rws;
			int lwc, rwc;
			[rws, rwc] = GetddWeaponStatus(rw.weaponstatus);
			[lws, lwc] = GetddWeaponStatus(lw.weaponstatus);
			DrawString(fa, ("x: "..rw.myInfo.aimOffsetAngle.." y: "..rw.myInfo.aimOffsetPitch), (-50, -130), DI_SCREEN_RIGHT_BOTTOM | DI_TEXT_ALIGN_CENTER);
			DrawString(fa, ((rw.weaponside) ? "Left" : "Right"), (-50, -122), DI_SCREEN_RIGHT_BOTTOM | DI_TEXT_ALIGN_CENTER);
			DrawString(fa, rws, (-50, -115), DI_SCREEN_RIGHT_BOTTOM | DI_TEXT_ALIGN_CENTER, rwc);
			DrawString(fa, rwfs2, (-50, -106), DI_SCREEN_RIGHT_BOTTOM | DI_TEXT_ALIGN_CENTER, FONT.CR_RED);
			DrawString(fa, ("x: "..lw.myInfo.aimOffsetAngle.." y: "..lw.myInfo.aimOffsetPitch), (50, -130), DI_SCREEN_LEFT_BOTTOM | DI_TEXT_ALIGN_CENTER);
			DrawString(fa, ((lw.weaponside) ? "Left" : "Right"), (50, -122), DI_SCREEN_LEFT_BOTTOM | DI_TEXT_ALIGN_CENTER);
			DrawString(fa, lws, (50, -115), DI_SCREEN_LEFT_BOTTOM | DI_TEXT_ALIGN_CENTER, lwc);
			DrawString(fa, lwfs2, (50, -106), DI_SCREEN_LEFT_BOTTOM | DI_TEXT_ALIGN_CENTER, FONT.CR_RED);
		}
		if(dPlay.dddebug & DBG_WEAPSEQUENCE)
		{
		}
		if(dPlay.dddebug & DBG_INVENTORY && dPlay.dddebug & DBG_VERBOSE)
		{
			DrawString(fa, FormatNumber(dPlay.lwx), (70, 0), DI_SCREEN_LEFT_CENTER);
			DrawString(fa, FormatNumber(wep.lSwapTarget), (70, 10), DI_SCREEN_LEFT_CENTER, Font.CR_ORANGE);
			DrawString(fa, FormatNumber(dPlay.rwx), (-70, 0), DI_SCREEN_RIGHT_CENTER);
			DrawString(fa, FormatNumber(wep.rSwapTarget), (-70, 10), DI_SCREEN_RIGHT_CENTER, Font.CR_ORANGE);		
		}
		if(dPlay.dddebug & DBG_PSPRITES)
		{
			PSprite pp = dPlay.player.FindPSprite(CVar.GetCvar("pl_pspriteInd", dPlay.player).GetInt());
			PSpriteInfo pi;
			let t = dPlay.psInfo;
			while(t)
			{
				if(t.ID == CVar.GetCvar("pl_pspriteInd", dPlay.player).GetInt()) { pi = t; break; }
				t = t.next;
			}
			if(pp) 
			{
				DrawString(fa, "CALLER: "..pp.caller.getclassname(), (80,-176), DI_SCREEN_LEFT_BOTTOM);
				DrawString(fa, "ID: "..FormatNumber(pp.id).." "..IdSpriteIndex(pp.id), (80, -168), DI_SCREEN_LEFT_BOTTOM);
				DrawString(fa, "SPRITE: "..pp.Sprite, (80, -160), DI_SCREEN_LEFT_BOTTOM);
				DrawString(fa, "FRAME: "..(String.Format("%c", pp.frame + 65)), (80, -152), DI_SCREEN_LEFT_BOTTOM);
				//WHY CAN'T YOU FORMAT DOUBLES?????
				DrawString(fa, "X: "..FormatNumber(pp.x).."."..FormatNumber((pp.x-floor(pp.x)) * 1000).." Y: "..FormatNumber(pp.y).."."..FormatNumber((pp.y-floor(pp.y)) * 1000), (80, -144), DI_SCREEN_LEFT_BOTTOM);
				DrawString(fa, "SX: "..FormatNumber(pp.scale.x).."."..FormatNumber((pp.scale.y-floor(pp.scale.y)) * 1000).." SY: "..FormatNumber(pp.scale.y).."."..FormatNumber((pp.scale.y-floor(pp.scale.y)) * 1000), (80, -136), DI_SCREEN_LEFT_BOTTOM);
				DrawString(fa, "ROTD: "..FormatNumber(pp.rotation).."."..FormatNumber((pp.rotation-floor(pp.rotation))*1000), (80, -128), DI_SCREEN_LEFT_BOTTOM);
				DrawString(fa, "C0 ("..FormatNumber(pp.Coord0.x)..", "..FormatNumber(pp.Coord0.y)..")", (80, -120), DI_SCREEN_LEFT_BOTTOM);
				DrawString(fa, "C1 ("..FormatNumber(pp.Coord0.x)..", "..FormatNumber(pp.Coord0.y)..")", (80, -112), DI_SCREEN_LEFT_BOTTOM);
				DrawString(fa, "C2 ("..FormatNumber(pp.Coord0.x)..", "..FormatNumber(pp.Coord0.y)..")", (140, -120), DI_SCREEN_LEFT_BOTTOM);
				DrawString(fa, "C3 ("..FormatNumber(pp.Coord0.x)..", "..FormatNumber(pp.Coord0.y)..")", (140, -112), DI_SCREEN_LEFT_BOTTOM);
				DrawString(fa, "H_AL: "..FormatNumber(pp.HAlign),(80, -104), DI_SCREEN_LEFT_BOTTOM);
				DrawString(fa, "V_AL: "..FormatNumber(pp.VAlign),(144, -104), DI_SCREEN_LEFT_BOTTOM);
				if(pi)
				{
					DrawString(fa, "I_PROVIDER: "..((pi.Provider) ? pi.provider.GetClassName() : 'null'), (80, -88), DI_SCREEN_LEFT_BOTTOM);
					DrawString(fa, "I_NEXTCASE: "..FormatNumber(pi.nextCaseNumber), (80, -80), DI_SCREEN_LEFT_BOTTOM);
					DrawString(fa, "I_TLENGTH: "..FormatNumber(pi.transformationLength).." I_TTIMER: "..FormatNumber(pi.transformationTimer), (80, -72), DI_SCREEN_LEFT_BOTTOM);
					DrawString(fa, "I_ID: "..FormatNumber(pi.ID), (80, -64), DI_SCREEN_LEFT_BOTTOM);
					DrawString(fa, "I_TARTRANS: ("..FormatNumber(pi.translTarget.x)..", "..FormatNumber(pi.translTarget.y)..")", (80, -56), DI_SCREEN_LEFT_BOTTOM);
					DrawString(fa, "I_TARSCALE: ("..FormatNumber(pi.scaleTarget.x)..", "..FormatNumber(pi.scaleTarget.y)..")", (80, -48), DI_SCREEN_LEFT_BOTTOM);
					DrawString(fa, "I_TARROT: "..FormatNumber(pi.rotTarget), (80, -40), DI_SCREEN_LEFT_BOTTOM);
					DrawString(fa, "I_TSTATUS: "..StatusToBin(pi.PSPStatus, 3), (80, -32), DI_SCREEN_LEFT_BOTTOM);
					DrawString(fa, "RST", (154, -24), DI_SCREEN_LEFT_BOTTOM);
					DrawString(fa, "I_FLAGS: "..StatusToBin(pi.imethod, 6), (80, -16), DI_SCREEN_LEFT_BOTTOM);
				}
				else { DrawString(fa, "ERR:NO PSPINFO", (80, -64), DI_SCREEN_LEFT_BOTTOM);}
			}
			else
			{
				DrawString(fa, "ERR:NO PSPRITE ID "..FormatNumber(CVar.GetCvar("pl_pspriteInd", dPlay.player).GetInt()), (80, -96), DI_SCREEN_LEFT_BOTTOM);
			}
		}
	}
	
	String StatusToBin(int thread, int len)
	{
		string spindle;
		for(int x = len-1; x > -1; x--)
		{
			spindle = spindle..((thread & 1<<x) ? "X" : "O");
		}
		return spindle;
	}
	
	String IDSpriteIndex(int id)
	{
		switch(id)
		{
			case 1: return "(READYWEAPON)";
			case 6: return "(LEFTW4)";
			case 7: return "(LEFTW3)";
			case 8: return "(LEFTW2)";
			case 9: return "(LEFTW1)";
			case 10: return "(LEFTW0)";
			case 11: return "(RIGHTW4)";
			case 12: return "(RIGHTW3)";
			case 13: return "(RIGHTW2)";
			case 14: return "(RIGHTW1)";
			case 15: return "(RIGHTW0)";
			case 16: return "(LEFTWF4)";
			case 17: return "(LEFTWF3)";
			case 18: return "(LEFTWF2)";
			case 19: return "(LEFTWF1)";
			case 20: return "(LEFTWF0)";
			case 21: return "(RIGHTWF4)";
			case 22: return "(RIGHTWF3)";
			case 23: return "(RIGHTWF2)";
			case 24: return "(RIGHTWF1)";
			case 25: return "(RIGHTWF0)";
			default: return "";
		}
	}
	
	String, int GetddWeaponStatus(int id)
	{
		int i = id;
		switch(i)
		{
			case 0: return "READY", Font.CR_GREEN;
			case 1: return "RELOADING", Font.CR_WHITE;
			case 2: return "FIRING", Font.CR_RED;
			case 3: return "ALTFIRING", Font.CR_LIGHTBLUE;
			case 4: return "MODE SWAPPING", FONT.CR_RED;
			case 5: return "UNLOADING", FONT.CR_CREAM;
			default: return "undefined", FONT.CR_RED;
		}
	}
}