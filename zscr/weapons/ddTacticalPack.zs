//backpack that increases holster slots by 1 and inventory space by 2
// #Class ddTactPack : Inventory()
class ddTactPack : Inventory
{
	Default
	{
		Height 36;
		Radius 14;
		Inventory.PickupMessage "Picked up a load-bearing backpack with extra pockets!!";
		Inventory.PickupSound "misc/secret";
	}
	
	override void AttachToOwner(Actor other)
	{
		Super.AttachToOwner(other);
		BuffOwner(other);
	}
	
	void BuffOwner(Actor owner)
	{
		let ddp = ddPlayer(owner);
		let lWeap = ddp.GetLeftWeapons();
		let rWeap = ddp.GetRightWeapons();
		let pInv = ddp.GetWeaponsInventory();
		if(lWeap.size < 3) { ddp.IncreaseSlots(CE_LEFT, 1); A_Log("Left weapon holster increased by 1!!"); }
		if(rWeap.size < 3) { ddp.IncreaseSlots(CE_RIGHT, 1); A_Log("Right weapon holster increased by 1!!"); }
		if(pInv.size < 6) { ddp.IncreaseInventory(2); A_Log("Inventory size increased by 2!!"); }
		int a = random(0, 5);
		switch(a)
		{
			case 0:
			case 1:
				ddp.GiveInventory("Clip", 20);
				break;
			case 2:
				break;
			case 3:
				ddp.GiveInventory("RocketAmmo", 2);
				break;
			case 4:
				ddp.GiveInventory("Shell", 12);
				break;
			case 5:
				break;
		}
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