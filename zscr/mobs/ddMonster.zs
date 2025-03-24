//Default DOOM monsters wrapped for DexDoom stuff

class FormerHuman : Zombieman replaces Zombieman
{
	Default
	{
		DropItem "Clip", 255;
		DropItem "d9MSpawner", 24, 15;
		DropItem "ddPistol", 20, 1;
	}
}

class FormerSergeant : ShotgunGuy replaces ShotgunGuy
{
	Default
	{
		DropItem "ddPistol", 10, 1;
		DropItem "d9MSpawner", 24, 15;
		DropItem "ddShotgun", 40, 1;
		DropItem "Shelle", 255, 4;
	}
}

class Chaingunner : ChaingunGuy replaces ChaingunGuy
{
	Default
	{
		DropItem "ddChaingun", 10, 1;
		DropItem "Clip", 255, 20;
		DropItem "d9MSpawner", 10, 15;
	}
}

class Imp : DoomImp replaces DoomImp
{
	Default
	{
		DropItem "ddPistol", 10, 1;
	}
}

class Pinky : Demon replaces Demon
{
}

class SneakyPinky : Spectre replaces Spectre
{
}

class Meatball : Cacodemon replaces Cacodemon
{
}

class MrMan : PainElemental replaces PainElemental
{
}

class Mancubus : Fatso replaces Fatso
{
}

class Skelly : Revenant replaces Revenant
{
}

class FlameSkull : LostSoul replaces LostSoul
{
}

class SkinAndBones : Archvile replaces Archvile
{
}

class HellNoble : HellKnight replaces HellKnight
{
}

class HellBaron : BaronOfHell replaces BaronOfHell
{
}

class BabyKrang : Arachnotron replaces Arachnotron
{
}

class BigBoss : Cyberdemon replaces Cyberdemon
{
}

class Krang : SpiderMastermind replaces SpiderMastermind
{
}

//nothing planned for Icon of Sin yet but whatever
class JohnnyBoy : BossBrain replaces BossBrain
{
}

class GodDangNatzi : WolfensteinSS replaces WolfensteinSS
{
	Default
	{
		DropItem "Clip", 255, 30;
		DropItem "d9MSpawner", 24, 15;
	}	
}