// BuilderShop.as

#include "Requirements.as"
#include "ShopCommon.as"
#include "Descriptions.as"
#include "Costs.as"
#include "CheckSpam.as"
#include "GenericButtonCommon.as"
#include "TeamIconToken.as"
#include "Hitters.as"

void onInit(CBlob@ this)
{

	this.getSprite().SetZ(-50); //background

	this.Tag("ignore fall");
	this.Tag("heavy weight");

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(4, 2));
	this.set_string("shop description", "Create");
	this.set_u8("shop icon", 15);

	{
		ShopItem@ s = addShopItem(this, "Mounted Bow", "$mounted_bow$", "mounted_bow", Descriptions::mounted_bow, true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 200);
		AddRequirement(s.requirements, "coin", "", "Coins", 30);
	}
	{
		ShopItem@ s = addShopItem(this, "Arrows", "$mat_arrows$", "mat_arrows", Descriptions::arrows, true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 5);
	}
	{
		ShopItem@ s = addShopItem(this, "Water Arrows", "$mat_waterarrows$", "mat_waterarrows", Descriptions::waterarrows, true);
		AddRequirement(s.requirements, "blob", "mat_arrows", "Arrows", 10);
		AddRequirement(s.requirements, "coin", "", "Coins", 5);
	}
	{
		ShopItem@ s = addShopItem(this, "Fire Arrows", "$mat_firearrows$", "mat_firearrows", Descriptions::firearrows, true);
		AddRequirement(s.requirements, "blob", "lantern", "Lantern", 1);
		AddRequirement(s.requirements, "blob", "mat_arrows", "Arrows", 5);
	}
	{
		ShopItem@ s = addShopItem(this, "Bomb Arrows", "$mat_bombarrows$", "mat_bombarrows", Descriptions::bombarrows, true);
		AddRequirement(s.requirements, "blob", "mat_arrows", "Arrows", 5);
		AddRequirement(s.requirements, "blob", "mat_bombs", "Bomb", 1);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this is null) {return;}
	if (caller is null) {return;}

	this.set_bool("shop available", this.getDistanceTo(caller) < 60.0f);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("/Construct.ogg");
	}
}

void onDetach(CBlob@ this,CBlob@ detached,AttachmentPoint@ attachedPoint)
{
	this.getSprite().SetZ(-50); //background
}

void onAttach( CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint )
{
	this.getSprite().SetZ(2); //front
}

