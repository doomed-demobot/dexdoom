//event handlers
class ddHandlers : EventHandler
{
	override void PlayerEntered(PlayerEvent e)
	{
		let p = ddPlayer(players[e.Playernumber].mo);
		if(p)
		{	
			if(p.player.readyweapon is "playerInventory") { p.player.readyweapon = ddWeapon(p.lastmode); }
			if(p.lastmode is "twoHanding" || p.player.readyweapon is "twoHanding") { p.InitTwoHanding(); }
			else if(p.lastmode is "dualWielding" || p.player.readyweapon is "dualWielding") { p.InitDualWielding(); }
			else { p.lastmode = p.lastmode; }
		}		
	}
	override void PlayerRespawned(PlayerEvent e)
	{
		let p = ddPlayer(players[e.Playernumber].mo);
		if(p)
		{	
			if(p.lastmode == null) { console.printf("no last mode"); }
			let thd = twoHanding(p.FindInventory("twoHanding"));
			p.player.readyweapon = thd;
			p.player.pendingweapon = WP_NOCHANGE;
			if(p.player.readyweapon is "playerInventory") { p.player.readyweapon = ddWeapon(p.lastmode); }
			if(p.lastmode is "twoHanding" || p.player.readyweapon is "twoHanding") { p.InitTwoHanding(); }
			else if(p.lastmode is "dualWielding" || p.player.readyweapon is "dualWielding") { p.InitDualWielding(); }
			else { p.lastmode = p.lastmode; }
		}		
	}
}