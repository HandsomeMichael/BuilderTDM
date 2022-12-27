// BuilderShop.as

#include "Requirements.as"
#include "Requirements_Tech.as"
#include "ShopCommon.as"
#include "Descriptions.as"
#include "Costs.as"
#include "CheckSpam.as"
#include "GenericButtonCommon.as"
#include "TeamIconToken.as"
#include "Hitters.as"

void onInit(CBlob@ this)
{
	AddIconToken("$vehicleshop_woodwheel$", "WoodenWheels.png", Vec2f(16, 16), 0);
	this.getSprite().SetZ(-50); //background

	this.Tag("ignore fall");
	this.Tag("heavy weight");

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(6, 5));
	this.set_string("shop description", "Build Vehicle");
	this.set_u8("shop icon", 15);

	int team_num = this.getTeamNum();

	{
		string cata_icon = getTeamIcon("catapult", "VehicleIcons.png", team_num, Vec2f(32, 32), 0);
		ShopItem@ s = addShopItem(this, "Catapult", cata_icon, "catapult", cata_icon + "\n\n\n" + Descriptions::catapult, false, true);
		s.crate_icon = 4;
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 10);
		AddRequirement(s.requirements, "coin", "", "Coins", 80);
	}
	{
		string ballista_icon = getTeamIcon("ballista", "VehicleIcons.png", team_num, Vec2f(32, 32), 1);
		ShopItem@ s = addShopItem(this, "Ballista", ballista_icon, "ballista", ballista_icon + "\n\n\n" + Descriptions::ballista, false, true);
		s.crate_icon = 5;
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 60);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 20);
		AddRequirement(s.requirements, "coin", "", "Coins", 50);
	}

	// Might remove cuz its absolutely useless

	{
		string outpost_icon = getTeamIcon("outpost", "VehicleIcons.png", team_num, Vec2f(32, 32), 6);
		ShopItem@ s = addShopItem(this, "Outpost", outpost_icon, "outpost", outpost_icon + "\n\n\n" + Descriptions::outpost, false, true);
		s.crate_icon = 7;
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 50);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
		AddRequirement(s.requirements, "coin", "", "Coins", 50);
	}
	{
		ShopItem@ s = addShopItem(this, "Ballista Ammo", "$mat_bolts$", "mat_bolts", "$mat_bolts$\n\n\n" + Descriptions::ballista_ammo, false, false);
		s.crate_icon = 5;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		AddRequirement(s.requirements, "coin", "", "Coins", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Ballista Shells", "$mat_bomb_bolts$", "mat_bomb_bolts", "$mat_bomb_bolts$\n\n\n" + Descriptions::ballista_bomb_ammo, false, false);
		s.crate_icon = 5;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 10);
		AddRequirement(s.requirements, "blob", "mat_bolts", "Ballista Ammo", 1);
		AddRequirement(s.requirements, "blob", "mat_bombs", "Bomb", 1);
	}
	{
		string dinghy_icon = getTeamIcon("dinghy", "VehicleIcons.png", team_num, Vec2f(32, 32), 5);
		ShopItem@ s = addShopItem(this, "Dinghy", dinghy_icon, "dinghy", dinghy_icon + "\n\n\n" + Descriptions::dinghy);
		s.buttonwidth = 2;
		s.buttonheight = 1;
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
	}
	{
		string longboat_icon = getTeamIcon("longboat", "VehicleIcons.png", team_num, Vec2f(32, 32), 4);
		ShopItem@ s = addShopItem(this, "Longboat", longboat_icon, "longboat", longboat_icon + "\n\n\n" + Descriptions::longboat, false, true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 150);
		AddRequirement(s.requirements, "coin", "", "Coins", 25);
		s.crate_icon = 1;
	}
	{
		string warboat_icon = getTeamIcon("warboat", "VehicleIcons.png", team_num, Vec2f(32, 32), 2);
		ShopItem@ s = addShopItem(this, "War Boat", warboat_icon, "warboat", warboat_icon + "\n\n\n" + Descriptions::warboat, false, true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 200);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 25);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 25);
		AddRequirement(s.requirements, "coin", "", "Coins", 25);
		s.crate_icon = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Wooden Wheels", "$vehicleshop_woodwheel$", "woodwheel", "Can be put on dinghy and warboat");
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 25);
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
		this.getSprite().PlaySound("/ChaChing.ogg");

		bool isServer = (getNet().isServer());
		u16 caller, item;
		if (!params.saferead_netid(caller) || !params.saferead_netid(item))
		{
			return;
		}
		string name = params.read_string();
		{
			if (name == "upgradebolts")
			{
				GiveFakeTech(getRules(), "bomb ammo", this.getTeamNum());
			}
			else if (name == "outpost")
			{
				CBlob@ crate = getBlobByNetworkID(item);
				
				crate.set_Vec2f("required space", Vec2f(5, 5));
				crate.set_s32("gold building amount", CTFCosts::outpost_gold);
				crate.Tag("unpack_check_nobuild");
			}
		}
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

