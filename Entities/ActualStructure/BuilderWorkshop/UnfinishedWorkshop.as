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
	
	AddIconToken("$icon_upgrade$", "InteractionIcons.png", Vec2f(32, 32), 21);
	
	this.set_Vec2f("shop offset",Vec2f(0,0));
	this.set_Vec2f("shop menu size",Vec2f(2,2));
	this.set_string("shop description", "");
	this.set_u8("shop icon",15);

	this.addCommandID("delete");
	
	{
		ShopItem@ s = addShopItem(this, "Build workshop", "$icon_upgrade$", "tflippy", "Build workshop.");
		AddRequirement(s.requirements,"blob","mat_stone","Stone",100);
		AddRequirement(s.requirements,"blob","mat_wood","Wood",350);
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

	if (sprite.isAnimation("building")) 
	{
		if (getGameTime() % 20 == 0) 
		{
			sprite.PlaySound("/Construct.ogg");
		}

		if (sprite.isAnimationEnded()) 
		{
			this.SendCommand(this.getCommandID("delete"));
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
		
		if (name == "tflippy")
		{		
			this.getSprite().PlaySound("/Construct.ogg");
			this.getSprite().SetAnimation("building");
			this.set_bool("shop available",false);
		}
	}
	if (cmd == this.getCommandID("delete")) 
	{
		if (isServer())
		{
			this.server_Die();
			CBlob@ newBlob = server_CreateBlob("builderworkshop", this.getTeamNum(), this.getPosition());
		}
	}
}
