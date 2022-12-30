// BuilderShop.as

#include "Requirements.as"
#include "ShopCommon.as"
#include "Descriptions.as"
#include "Costs.as"
#include "CheckSpam.as"
#include "GenericButtonCommon.as"
#include "TeamIconToken.as"

void onInit(CBlob@ this)
{
	InitCosts(); //read from cfg

	AddIconToken("$_buildershop_bombertable$", "BomberTable_icon.png", Vec2f(12, 11), 0);
	AddIconToken("$_buildershop_filled_bucket$", "Bucket.png", Vec2f(16, 16), 1);
	AddIconToken("$_buildershop_kitchentable$", "KitchenTable_shop.png", Vec2f(13, 11), 0);
	AddIconToken("$upgrade_this$", "BuilderTable_upgrade.png", Vec2f(12, 11), 0);

	this.set_TileType("background tile", CMap::tile_castle_back);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(4, 5));
	this.set_string("shop description", "Build");
	this.set_u8("shop icon", 15);
	this.addCommandID("sell_blob");

	// sell stuff
	this.addCommandID("sell_blob");

	int team_num = this.getTeamNum();

	{
		ShopItem@ s = addShopItem(this, "Lantern", "$lantern$", "lantern", Descriptions::lantern, false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 10);
	}
	{
		ShopItem@ s = addShopItem(this, "Sponge", "$sponge$", "sponge", Descriptions::sponge, false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 5);
		AddRequirement(s.requirements, "coin", "", "Coins", 10);
	}
	{
		ShopItem@ s = addShopItem(this, "Filled Bucket", "$_buildershop_filled_bucket$", "filled_bucket", Descriptions::filled_bucket, false);
		s.spawnNothing = true;
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 10);
		AddRequirement(s.requirements, "coin", "", "Coins", 5);
	}
	{
		ShopItem@ s = addShopItem(this, "Upgrade Builder Table", "$upgrade_this$", "upgrade", "Tier 2 Builder Table\n\nUpgrade this table to unlocks new stuff", false);
		s.spawnNothing = true;
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 300);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 100);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
		AddRequirement(s.requirements, "coin", "", "Coins", 15);
	}
	// bucket is useless and used for spam so no
	// {
	// 	ShopItem@ s = addShopItem(this, "Bucket", "$bucket$", "bucket", Descriptions::bucket, false);
	// 	AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 5);
	// }
	{
		ShopItem@ s = addShopItem(this, "Drill", "$drill$", "drill", Descriptions::drill, false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 100);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 5);
		AddRequirement(s.requirements, "coin", "", "Coins", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Boulder", "$boulder$", "boulder", Descriptions::boulder, false);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Trampoline", getTeamIcon("trampoline", "Trampoline.png", team_num, Vec2f(32, 16), 3), "trampoline", Descriptions::trampoline, false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
	}

	{
		ShopItem@ s = addShopItem(this, "Kitchen Table" , "$_buildershop_kitchentable$", "kitchentable", "A table full of dishesh that refill itself overtime\n\nCan also turn dead body into a perfect meal", false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 150);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 25);
		AddRequirement(s.requirements, "blob", "food", "Any Food", 1);
		AddRequirement(s.requirements, "coin", "", "Coins", 10);
	}
	{
		ShopItem@ s = addShopItem(this, "Bomber Table" , "$_buildershop_bombertable$", "bombertable", "A table that can produce explosives", false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 50);
		AddRequirement(s.requirements, "coin", "", "Coins", 20);
	}
	{
		ShopItem@ s = addShopItem(this, "Archery Table" , getTeamIcon("archerytable", "ArcheryTable_icon.png", team_num, Vec2f(12, 12), 0), "archerytable", "A table that can produce arrows and mounted bow", false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 25);
		AddRequirement(s.requirements, "coin", "", "Coins", 15);
	}
	{
		ShopItem@ s = addShopItem(this, "Vehicle Assembler" , getTeamIcon("vehicleassembler", "VehicleAssembler_icon.png", team_num, Vec2f(15, 12), 0), "vehicleassembler", "A table that can produce vehicles , wheels and boats", false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 50);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
		AddRequirement(s.requirements, "coin", "", "Coins", 30);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;
	// Seems like either way the shop script already handled this
	this.set_bool("shop available",true);

	// Selling and buyying
	CBlob@ carried = caller.getCarriedBlob();
	if (carried !is null) {

		u16 price = 0;
		if (carried.getName() == "mat_gold") {price = carried.getQuantity() * 2;}
		if (carried.getName() == "mat_stone") {price = carried.getQuantity() / 2;}
		if (carried.getName() == "mat_wood") {price = carried.getQuantity() / 4;}
		if (carried.getName() == "log") {price = 50;}

		if (price < 1) return;

		CBitStream params;
		params.write_netid(caller.getNetworkID());
		params.write_u16(price);

		CButton@ button = caller.CreateGenericButton(
		25,																// icon
		Vec2f(0, -8),													// offset
		this, 															// blob
		this.getCommandID("sell_blob"), 								// command
		"Sell "+carried.getInventoryName()+" for "+price+ " coins", params);	// description
		// from shop.as
		button.enableRadius = 20;
	}
}

void onDie(CBlob@ this) {
	CBlob@ newBlob = server_CreateBlob("unfinishedworkshop", this.getTeamNum(), this.getPosition());
}
void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("/ChaChing.ogg");

		if (!getNet().isServer()) return; /////////////////////// server only past here

		u16 caller, item;
		if (!params.saferead_netid(caller) || !params.saferead_netid(item))
		{
			return;
		}
		string name = params.read_string();
		{
			CBlob@ callerBlob = getBlobByNetworkID(caller);
			if (callerBlob is null)
			{
				return;
			}

			if (name == "filled_bucket")
			{
				CBlob@ b = server_CreateBlobNoInit("bucket");
				b.setPosition(callerBlob.getPosition());
				b.server_setTeamNum(callerBlob.getTeamNum());
				b.Tag("_start_filled");
				b.Init();
				callerBlob.server_Pickup(b);
			}
		}
	}
}
