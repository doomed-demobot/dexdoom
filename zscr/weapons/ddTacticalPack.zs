//backpack that increases holster slots by 1 and inventory space by 2
// #Class ddTactPack : Inventory()
class ddTactPack : BackpackItem
{
	bool ibuffed;
	Default
	{
		Height 36;
		Radius 14;
		Inventory.PickupMessage "Picked up a load-bearing backpack with extra pockets.";
		Inventory.PickupSound "misc/secret";
		Inventory.MaxAmount 1;
	}
		
	override bool TryPickup(in out Actor toucher)
	{
		if(ddPlayer(toucher).GetWeaponsInventory().size < 4) { ibuffed = BuffOwner(toucher); }
		return Super.TryPickup(toucher);
	}
	
	override String PickupMessage()
	{
		let ddp = ddPlayer(owner);
		String finalmsg = ((ibuffed) ? self.pickupmsg : "Took some ammo out of the load-bearing backpack.")..
		((ibuffed) ? "\nLeft weapon holster increased by 1!!\n" : "" )..
		((ibuffed) ? "Right weapon holster increased by 1!!\n" : "" )..
		((ibuffed) ? "Inventory size increased by 2!!" : "" );
		return finalmsg;
	}
	
	bool BuffOwner(Actor owner)
	{
		let ddp = ddPlayer(owner);
		let lWeap = ddp.GetLeftWeapons();
		let rWeap = ddp.GetRightWeapons();
		let pInv = ddp.GetWeaponsInventory();
		bool res = false;
		if(lWeap.size < 3) { ddp.IncreaseSlots(CE_LEFT, 1); res = true; }
		if(rWeap.size < 3) { ddp.IncreaseSlots(CE_RIGHT, 1); res = true; }
		if(pInv.size < 6) { ddp.IncreaseInventory(2); res = true; }
		int a = random(0, 5);
		switch(a)
		{
			case 0:
			case 1:
				ddp.GiveInventory("Clip", 80);
				break;
			case 2:
				break;
			case 3:
				ddp.GiveInventory("RocketAmmo", 12);
				break;
			case 4:
				ddp.GiveInventory("Shell", 36);
				break;
			case 5:
				break;
		}
		return res;
	}
	
	// ## ddTactPack States()
	States
	{
		Spawn:
			MOLL E -1;
			Stop;
	}
}

class Backpacke : Backpack {}
// #Class BackpackSpawner : RandomSpawner replaces Backpack()
class BackpackSpawner : RandomSpawner replaces Backpack
{
	Default
	{
		DropItem "Backpacke", 255, 54;
		DropItem "ddTactPack", 255, 15;
	}
}