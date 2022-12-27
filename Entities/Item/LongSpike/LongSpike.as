#include "Hitters.as";
#include "Knocked.as";

void onInit(CBlob@ this)
{
	this.set_bool("active", false);
	this.Tag("ignore fall");
	this.Tag("heavy weight");
	this.set_u32("next_pickup", 0);
	
	this.addCommandID("activate");

	this.getShape().SetRotationsAllowed(false);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("activate"))
	{
		bool state = params.read_bool();
		this.set_bool("active", state);
		
		state ? this.getSprite().PlaySound("/SpikesOut.ogg") : this.getSprite().PlaySound("/SpikesCut.ogg");
		this.getSprite().SetFrameIndex(state ? 1 : 0);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller.getTeamNum() == this.getTeamNum())
	{
		if (this.getMap().rayCastSolid(caller.getPosition(), this.getPosition())) return;
		
		bool active = this.get_bool("active");
		
		CBitStream params;
		params.write_bool(!active);
		CButton@ button = caller.CreateGenericButton("$spikes$", Vec2f(0, 0), this, this.getCommandID("activate"), (active ? "Disarm" : "Arm"), params);
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) {return;}

	if (blob.getOldVelocity().y > 0 && blob.hasTag("flesh") && this.get_bool("active") && blob.hasTag("flesh") && !isKnocked(blob))
	{
		this.getSprite().PlaySound("/SpikesCut.ogg");
		this.set_u32("next_pickup", getGameTime()+270);
		this.set_bool("active", false);
		this.getSprite().SetFrameIndex(0);
		
		if (isServer()){
			this.server_Hit(blob, this.getPosition(), Vec2f(0, 0), 1.0f, Hitters::spikes, true);
		}
	}
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	return false;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return getGameTime() >= this.get_u32("next_pickup") && this.getTeamNum() == byBlob.getTeamNum();
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return damage;
}