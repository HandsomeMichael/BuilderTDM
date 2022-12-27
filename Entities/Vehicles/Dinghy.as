// Patch : Attemp to add wheels

#include "VehicleCommon.as"
#include "GenericButtonCommon.as"
#include "WheelBoatCommon.as"
#include "RunOverCommon.as"
#include "StorageCommon.as"

// Boat logic

void onInit(CBlob@ this)
{
	// leash offset
	this.set_Vec2f("leashOffset",Vec2f(21,2));

	StoreInv_Init(this);
	WheelBoat_Setup(this);

	Vehicle_Setup(this,
	              250.0f, // move speed
	              0.31f,  // turn speed
	              Vec2f(0.0f, -2.5f), // jump out velocity
	              true  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	Vehicle_SetupWaterSound(this, v, "BoatRowing",  // movement sound
	                        0.0f, // movement sound volume modifier   0.0f = no manipulation
	                        0.0f // movement sound pitch modifier     0.0f = no manipulation
	                       );
	this.getShape().SetOffset(Vec2f(0, 9));
	this.getShape().SetCenterOfMassOffset(Vec2f(-1.5f, 4.5f));
	this.getShape().getConsts().transports = true;
	this.Tag("medium weight");
	this.Tag("short raid time"); // captures quicker
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;
	if (caller.getTeamNum() == this.getTeamNum()){
		StoreInv_GetButtons(this,caller,Vec2f(0, 10));
		WheelBoat_GetButtons(this,caller);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	StoreInv_HandleCommand(this,cmd,params);
	WheelBoat_HandleCommand(this,cmd,params);

}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return !this.hasAttached() &&
	       (!this.isInWater() || this.isOnMap()) &&
	       this.getOldVelocity().LengthSquared() < 4.0f &&
		   this.getTeamNum() == byBlob.getTeamNum();
}

void onTick(CBlob@ this)
{
	const int time = this.getTickSinceCreated();
	if (this.hasAttached() || time < 30) //driver, seat or gunner, or just created
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		WheelBoat_StandardControls(this, v);
	}
}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 charge) {}
bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return Vehicle_doesCollideWithBlob_boat(this, blob);
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	Vehicle_onAttach(this, v, attached, attachedPoint);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	Vehicle_onDetach(this, v, detached, attachedPoint);
}

// Handled at RunOverCommon , instead of relying on RunOverPeople.as
void onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData) 
{
	if (!this.hasAttached()) return;
	RunOver_HitBlob(this, worldPoint, velocity, damage, hitBlob, customData);
}
void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1) 
{
	if (!this.hasAttached()) return;
	RunOver_Collision(this,blob,solid,normal,point1);
}