//consts and enums live here
enum WeapPSprites
{
	PSP_LEFTW = 2,	
	PSP_LEFTWF,
	PSP_RIGHTW,
	PSP_RIGHTWF,
};
enum KeyIdentities
{
	WRF_FULL = WRF_ALLOWRELOAD|WRF_ALLOWZOOM|WRF_ALLOWUSER1|WRF_ALLOWUSER2|WRF_ALLOWUSER3|WRF_ALLOWUSER4,
	BT_LEFTFIRE = BT_USER1,
	BT_LEFTALT = BT_USER2,
	BT_RIGHTSWITCH = BT_USER3,
	BT_LEFTSWITCH = BT_USER4,
};
enum WeaponSideIdentities
{
	CE_RIGHT = 0,
	CE_LEFT  = 1,
};
enum ModeCheckResults
{
	RES_TWOHAND = 1,
	RES_DUALWLD = 2,
	RES_HASESOA = 3,
	RES_CLASSIC = 4,
};
//hopefully augmenting weaponstate doesn't bring unforeseen consequences :)
enum ExtraStates
{
	WF_QUICKLEFTOK 	= 1 << 12,
	WF_QUICKRIGHTOK = 1 << 13,
};

enum ddWeaponStatus
{
	DDW_RIGHTREADY	= 1 << 0,
	DDW_LEFTREADY 	= 1 << 1,
	DDW_RIGHTBOBBING = 1 << 2,
	DDW_LEFTBOBBING = 1 << 3,
	DDW_RIGHTNOBOBBING = 1 << 4,
	DDW_LEFTNOBOBBING = 1 << 5,
	DDW_WANNAREPLACE = 1 << 6,
	DDW_REPLACERIGHT = 1 << 7,
	DDW_REPLACELEFT = 1 << 8,
	DDW_LEFTISTH = 1 << 9,
	DDW_RIGHTISTH = 1 << 10,
	DDW_NOLEFTSPRITECHANGE = 1 << 11,
	DDW_NORIGHTSPRITECHANGE = 1 << 12,
	DDW_LEFTLOWERTOREL = 1 << 13,
	DDW_LEFTRAISETOREL = 1 << 14,
	DDW_RIGHTLOWERTOREL = 1 << 15,
	DDW_RIGHTRAISETOREL = 1 << 16,
};

enum CommonCombo
{
	COM_SHOT = 1,
};