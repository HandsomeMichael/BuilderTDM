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

	AddIconToken("$_buildershop_bombertable$", "BomberTable_icon.png", Vec2f(12, 11), 0);
	AddIconToken("$_buildershop_filled_bucket$", "Bucket.png", Vec2f(16, 16), 1);
	AddIconToken("$_buildershop_kitchentable$", "KitchenTable_shop.png", Vec2f(13, 11), 0);
	AddIconToken("$upgrade_this$", "BuilderTable_upgrade.png", Vec2f(12, 11), 0);

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(4, 4));
	this.set_string("shop description", "Build");
	this.set_u8("shop icon", 15);
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
	// for Tier 2
	// {
	// 	ShopItem@ s = addShopItem(this, "Saw", getTeamIcon("saw", "VehicleIcons.png", team_num, Vec2f(32, 32), 3), "saw", Descriptions::saw, false);
	// 	s.customButton = true;
	// 	s.buttonwidth = 2;
	// 	s.buttonheight = 1;
	// 	AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
	// 	AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 150);
	// }
	{
		ShopItem@ s = addShopItem(this, "Crate", getTeamIcon("crate", "Crate.png", team_num, Vec2f(32, 16), 5), "crate", Descriptions::crate, false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
	}
	// for Tier 2
	// {
	// 	ShopItem@ s = addShopItem(this, "Long Spike", getTeamIcon("longspike", "LongSpike.png", team_num, Vec2f(34, 14), 0), "longspike", "A Long spike for trapping enemies and rude teammates", false);
	// 	s.customButton = true;
	// 	s.buttonwidth = 2;
	// 	s.buttonheight = 1;
	// 	AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 10);
	// 	AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 50);
	// 	AddRequirement(s.requirements, "coin", "", "Coins", 10);
	// }
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

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("sell_blob"))
	{
		this.getSprite().PlaySound("/ChaChing.ogg");

		if (!isServer()) return; /////////////////////// server only past here

		// check caller null
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		if (caller is null) return;

		// check carried blob , maybe check their name but im too lazy to do that
		// besides , nothing can harm them from this littlest tinniest codeh
		CBlob@ carried = caller.getCarriedBlob();
		if (carried is null) return;

		// kill carried blob
		carried.Tag("dead");
		carried.server_Die();
		
		// set coins
		u16 getCoins = params.read_u16();
		CPlayer@ player = caller.getPlayer();
		if (player is null) return;
		player.server_setCoins(player.getCoins() + getCoins);

	}
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("/Construct.ogg");

		if (!isServer()) return; /////////////////////// server only past here

		// check caller and item netid
		u16 caller, item;
		if (!params.saferead_netid(caller) || !params.saferead_netid(item)){return;}

		// get blob name
		string name = params.read_string();
		{
			// get caller
			CBlob@ callerBlob = getBlobByNetworkID(caller);
			if (callerBlob is null){return;}

			// upgrade to TIER 2
			if (name == "upgrade") 
			{
				CBlob@ b = server_CreateBlob("heavybuildertable",this.getTeamNum(),this.getPosition());
				this.set_bool("shop available", false);
				this.server_Die();
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
