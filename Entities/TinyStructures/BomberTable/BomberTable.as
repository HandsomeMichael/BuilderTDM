// BuilderShop.as

#include "Requirements.as"
#include "ShopCommon.as"
#include "Descriptions.as"
#include "Costs.as"
#include "CheckSpam.as"
#include "GenericButtonCommon.as"
#include "TeamIconToken.as"
#include "Hitters.as"
#include "FuseCommon.as"

void onInit(CBlob@ this)
{

	this.getSprite().SetZ(-50); //background

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(4, 1));
	this.set_string("shop description", "Create explosives");
	this.set_u8("shop icon", 15);

	this.Tag("ignore fall");
	this.Tag("heavy weight");

	Fuse_Setup(this);

	int team_num = this.getTeamNum();

	{
		ShopItem@ s = addShopItem(this, "Bomb", "$bomb$", "mat_bombs", Descriptions::bomb, true);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 10);
		AddRequirement(s.requirements, "coin", "", "Coins", 5);
	}
	{
		ShopItem@ s = addShopItem(this, "Water Bomb", "$waterbomb$", "mat_waterbombs", Descriptions::waterbomb, true);
		AddRequirement(s.requirements, "blob", "mat_bombs", "Bomb", 1);
		AddRequirement(s.requirements, "coin", "", "Coins", 10);
	}
	{
		ShopItem@ s = addShopItem(this, "Mine", getTeamIcon("mine", "Mine.png", team_num, Vec2f(16, 16), 1), "mine", Descriptions::mine, false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 10);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 10);
		AddRequirement(s.requirements, "coin", "", "Coins", 40);
	}
	{
		ShopItem@ s = addShopItem(this, "Keg", getTeamIcon("keg", "Keg.png", team_num, Vec2f(16, 16), 0), "keg", Descriptions::keg, false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 150);
		AddRequirement(s.requirements, "coin", "", "Coins", 50);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	Fuse_GetButton(this,caller);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("/Construct.ogg");
	}

	Fuse_HandleCommand(this,cmd,params);
}

void onDetach(CBlob@ this,CBlob@ detached,AttachmentPoint@ attachedPoint)
{
	this.getSprite().SetZ(-50); //background
}

void onAttach( CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint )
{
	this.getSprite().SetZ(2); //front
}

