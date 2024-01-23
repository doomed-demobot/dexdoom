//event handlers
class ddHandlers : EventHandler
{
	override void PlayerEntered(PlayerEvent e)
	{
		let p = ddPlayer(players[e.Playernumber].mo);
		if(p)
		{	
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
			if(p.lastmode is "twoHanding" || p.player.readyweapon is "twoHanding") { p.InitTwoHanding(); }
			else if(p.lastmode is "dualWielding" || p.player.readyweapon is "dualWielding") { p.InitDualWielding(); }
			else { p.lastmode = p.lastmode; }
		}		
	}
}