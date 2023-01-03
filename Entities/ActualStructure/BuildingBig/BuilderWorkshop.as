// BuilderShop.as

#include "Requirements.as"
#include "ShopCommon.as"
#include "Descriptions.as"
#include "Costs.as"
#include "CheckSpam.as"
#include "GenericButtonCommon.as"
#include "TeamIconToken.as"
#include "RestockCommon.as"
#include "TradingCommon.as"

void onInit(CBlob@ this)
{
	InitCosts(); //read from cfg

	// AddIconToken("$_buildershop_bombertable$", "BomberTable_icon.png", Vec2f(12, 11), 0);
	// AddIconToken("$_buildershop_filled_bucket$", "Bucket.png", Vec2f(16, 16), 1);
	// AddIconToken("$_buildershop_kitchentable$", "KitchenTable_shop.png", Vec2f(13, 11), 0);
	AddIconToken("$upgrade_this$", "BuilderTable_upgrade.png", Vec2f(12, 11), 0);

	this.set_TileType("background tile", CMap::tile_castle_back);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	// SHOP
	this.set_Vec2f("shop offset", Vec2f(0,10));
	this.set_Vec2f("shop menu size", Vec2f(8, 2));
	this.set_string("shop description", "Build portable workshop");
	this.set_u8("shop icon", 15);

	// sell stuff
	this.addCommandID("sell_blob");

	int team_num = this.getTeamNum();

	// {
	// 	ShopItem@ s = addShopItem(this, "Upgrade Builder Table", "$upgrade_this$", "upgrade", "Tier 2 Builder Table\n\nUpgrade this table to unlocks new stuff", false);
	// 	s.spawnNothing = true;
	// 	AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 300);
	// 	AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 100);
	// 	AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
	// 	AddRequirement(s.requirements, "coin", "", "Coins", 15);
	// }

	//addTradeSeparatorItem(this, "$MENU_GENERIC$", Vec2f(3, 1));

	{
		ShopItem@ s = addShopItem(this, "Kitchen Table" , "$kitchentable$",
		 "kitchentable", "Kitchen Table\n\nA table full of dishesh that refill itself overtime\n\nCan also turn dead body into a perfect meal", false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 150);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 25);
		AddRequirement(s.requirements, "blob", "food", "Any Food", 1);
		AddRequirement(s.requirements, "coin", "", "Coins", 10);
	}
	{
		ShopItem@ s = addShopItem(this, "Bomber Table" , "$bombertable$",
		 "bombertable", "Bomber Table\n\nA table that can produce explosives", false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 50);
		AddRequirement(s.requirements, "coin", "", "Coins", 20);
	}
	{
		ShopItem@ s = addShopItem(this, "Archery Table" , 
		getTeamIcon("archerytable", "ArcheryTable.png", team_num, Vec2f(23,24), 0),
		 "archerytable", "Archery Table\n\nA table that can produce arrows and mounted bow", false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 25);
		AddRequirement(s.requirements, "coin", "", "Coins", 15);
	}
	{
		ShopItem@ s = addShopItem(this, "Vehicle Assembler" ,
		 getTeamIcon("vehicleassembler", "VehicleAssembler_icon.png", team_num, Vec2f(15, 12), 0),
		  "vehicleassembler", "Vehicle Assembler\n\nA table that can produce vehicles , wheels and boats", false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 50);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
		AddRequirement(s.requirements, "coin", "", "Coins", 30);
	}
}

void onRender(CSprite@ this){

	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();
	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 0.95f;
	bool mouseOnBlob = (mouseWorld - center).getLength() < renderRadius;

	if (mouseOnBlob)
	{
		RenderTimeLeft(this,Vec2f(0,-32));
	}

}

void onTick(CBlob@ this)
{
	// dont drop any epic mats
	if (this.hasTag("wait")) return;

	if (getGameTime() >= this.get_u32("drop_mats"))
	{
		//if (!isServer()) return; /////////////////////////////////// SERVER ONLY

		// add tags for waiting and unpacking
		this.Tag("wait");

		bool parachute = true;
		Vec2f pos = this.getPosition();
		getMap().rayCastSolidNoBlobs(this.getPosition(), Vec2f(this.getPosition().x,0), pos);

		// if less than 10 block distance then just drop it on the ruins directly
		float dist = (this.getPosition().y - pos.y);
		if (dist < 160 && pos.y != 0) {

			pos = this.getPosition();
			parachute = false;
		}

		bool stoneRestock = (XORRandom(2) == 0) ? true : false;

		// parachuted crate give more material
		CBlob@ crate = CreateSmallRestock(this,
		pos, // pos
		1000, // delay
		(stoneRestock ? 0 : 100) , // wood count
		(stoneRestock ? 50 : 0), // stone count
		0, // gold count
		parachute); // parachute

		// wood
		crate.getSprite().SetFrameIndex((stoneRestock ? 2 : 3));
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
		Vec2f(0, -4),													// offset
		this, 															// blob
		this.getCommandID("sell_blob"), 								// command
		"Sell "+carried.getInventoryName()+" for "+price+ " coins", params);	// description
		// from shop.as
		button.enableRadius = 20;
	}
}

void onDie(CBlob@ this) 
{
	CBlob@ newBlob = server_CreateBlob("unfinishedworkshop", this.getTeamNum(), this.getPosition());
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
			if (callerBlob is null)return;

			if (name == "order_restock_stone") {
				//this.set_u8("restocktier",this.get_u8("restocktier") + 1);
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
