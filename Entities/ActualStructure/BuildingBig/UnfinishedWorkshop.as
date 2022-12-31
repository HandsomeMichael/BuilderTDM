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
	// farting
	this.getSprite().SetAnimation("default");

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions=false;
	
	AddIconToken("$build_icon$", "InteractionIcons.png", Vec2f(32, 32), 21);
	
	this.set_Vec2f("shop offset",Vec2f(0,0));
	this.set_Vec2f("shop menu size",Vec2f(4,2));
	this.set_string("shop description", "");
	this.set_u8("shop icon",15);

	this.addCommandID("createworkshop");
	
	{
		ShopItem@ s = addShopItem(this, "Build builder workshop", "$build_icon$", "builder", "Build builder workshop.");
		AddRequirement(s.requirements,"blob","mat_stone","Stone",100);
		AddRequirement(s.requirements,"blob","mat_wood","Wood",350);
		s.customButton = true;
		s.buttonwidth = 2;	
		s.buttonheight = 2;
		
		s.spawnNothing = true;
	}

	{
		ShopItem@ s = addShopItem(this, "Build utility workshop", "$build_icon$", "utility", "Build utility workshop.");
		AddRequirement(s.requirements,"blob","mat_stone","Stone",150);
		AddRequirement(s.requirements,"blob","mat_wood","Wood",100);
		s.customButton = true;
		s.buttonwidth = 2;	
		s.buttonheight = 2;
		s.spawnNothing = true;
	}

	{
		ShopItem@ s = addShopItem(this, "Build altar", "$build_icon$", "utility", "Build altar.");
		AddRequirement(s.requirements,"blob","mat_stone","Stone",300);
		s.customButton = true;
		s.buttonwidth = 2;	
		s.buttonheight = 2;
		s.spawnNothing = true;
	}
}

void onTick(CBlob@ this) 
{
	// maybe i shouldnt use sprite animation for logic stuff :skull:
	CSprite@ sprite = this.getSprite();

	if (!sprite.isAnimation("default")) 
	{
		if (getGameTime() % 20 == 0) 
		{
			sprite.PlaySound("/Construct.ogg");
		}

		if (sprite.isAnimationEnded()) 
		{
			this.SendCommand(this.getCommandID(sprite.getAnimation().name));
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		u16 caller, item;
		if (!params.saferead_netid(caller) || !params.saferead_netid(item)) return;
		string name = params.read_string();

		this.getSprite().PlaySound("/Construct.ogg");
		this.getSprite().SetAnimation(name);
		this.set_bool("shop available",false);
		
		if (name == "builder")
		{		
			this.getSprite().PlaySound("/Construct.ogg");
			this.getSprite().SetAnimation("building");
			this.set_bool("shop available",false);
		}
		else if (name == "builder")
		{		
			this.getSprite().PlaySound("/Construct.ogg");
			this.getSprite().SetAnimation("building");
			this.set_bool("shop available",false);
		}
	}
	if (cmd == this.getCommandID("createworkshop")) 
	{
		string name = params.read_string();
		if (isServer())
		{
			this.server_Die();
			CBlob@ newBlob = server_CreateBlob(name, this.getTeamNum(), this.getPosition());
		}
	}
}
