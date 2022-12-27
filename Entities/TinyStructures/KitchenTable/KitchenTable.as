// BuilderShop.as
#include "GenericButtonCommon.as"
#include "Hitters.as"

void onInit(CBlob@ this)
{
	this.getSprite().SetZ(-50); //background

	AddIconToken("$kitchen_meat$", "Food.png", Vec2f(16, 16), 0);
	AddIconToken("$kitchen_cut$", "KitchenTable_cut.png", Vec2f(13, 7), 0);

	this.addCommandID("consume_food");
	this.addCommandID("make_food");

	this.Tag("ignore fall");
	this.Tag("heavy weight");

	this.set_u8("food", 3);
	this.getSprite().SetFrameIndex(3);

	this.set_u32("next_food",0);

}

void onTick(CBlob@ this) {

	u8 food = this.get_u8("food");

	if (food < 3 && getGameTime() >= this.get_u32("next_food")) 
	{
		this.getSprite().PlaySound("/Heart.ogg", 0.5);
		this.getSprite().SetFrameIndex(food + 1);
		this.set_u8("food", food + 1);
		this.set_u32("next_food",getGameTime()+360);
	}

}
void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller is null) return;
	if (!canSeeButtons(this, caller)) return;

	if (this.getDistanceTo(caller) < 50.0f) {

		u8 food = this.get_u8("food");

		// consume food
		if (food > 0) {
			CBitStream params;
			params.write_u16(caller.getNetworkID());
			params.write_u8(food - 1);
			caller.CreateGenericButton("$kitchen_meat$", 
			Vec2f(0, 0), 
			this, 
			this.getCommandID("consume_food"), 
			getTranslatedString("Consume"), 
			params);
		}
		// cook food
		if (food < 3) {

			CBlob@ carried = caller.getCarriedBlob();
			if (carried is null) return;

			if (carried.getName() == "knight" || carried.getName() == "archer" || carried.getName() == "builder") {
				CBitStream params;
				params.write_u16(carried.getNetworkID());
				caller.CreateGenericButton("$kitchen_cut$", 
				Vec2f(6, 0), 
				this, 
				this.getCommandID("make_food"), 
				getTranslatedString("Cannibalism"), 
				params);
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("consume_food"))
	{
		u16 caller;
		if (!params.saferead_netid(caller))return;

		u8 food;
		if (!params.saferead_u8(food))return;

		CBlob@ callerBlob = getBlobByNetworkID(caller);
		if (callerBlob is null)return;

		this.set_u8("food", food);
		this.set_u32("next_food",getGameTime()+360);
		this.getSprite().PlaySound("/Eat.ogg");
		this.getSprite().SetFrameIndex(food);

		if (getNet().isServer())
		{
			callerBlob.server_SetHealth(callerBlob.getInitialHealth());
		}
	}
	if (cmd == this.getCommandID("make_food"))
	{
		u16 caller;
		if (!params.saferead_netid(caller))return;

		CBlob@ callerBlob = getBlobByNetworkID(caller);
		if (callerBlob is null)return;

		if (isServer()){
			// if you somehow managed to pickup and actual player , you can intakill it here 
			this.server_Hit(callerBlob, this.getPosition(), Vec2f(0, 0), 100.0f, Hitters::sword, true);
		}

		this.set_u32("next_food",getGameTime()+360);
		this.set_u8("food", 3);
		this.getSprite().SetFrameIndex(3);
		
		this.getSprite().PlaySound("/SwordKill1.ogg");
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