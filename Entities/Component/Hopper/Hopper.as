// Hopper.as

#include "MechanismsCommon.as";
#include "DummyCommon.as";
//#include "GenericButtonCommon.as";

class Hopper : Component
{
	Hopper(Vec2f position)
	{
		x = position.x;
		y = position.y;
	}
}

void onInit(CBlob@ this)
{
	// used by BuilderHittable.as
	this.Tag("builder always hit");

	// // used by BlobPlacement.as
	this.Tag("place norotate");

	// used by TileBackground.as
	this.set_TileType("background tile", CMap::tile_wood_back);

	// 0.5 second per update , to prevent huge lag
	this.getCurrentScript().tickFrequency = 30;
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic || this.exists("component")) return;

	const Vec2f position = this.getPosition() / 8;
	const u16 angle = this.getAngleDegrees();

	Hopper component(position);
	this.set("component", component);

	if (getNet().isServer())
	{
		MapPowerGrid@ grid;
		if (!getRules().get("power grid", @grid)) return;

		grid.setAll(
		component.x,                        // x
		component.y,                        // y
		TOPO_NONE,                      	// input topology
		TOPO_CARDINAL,                      // output topology
		INFO_NONE,                          // information
		0,                                  // power
		0);                                 // id
	}

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	sprite.SetZ(500);
	sprite.SetFacingLeft(false);
}


// TO DO : 
// - Make hopper slowly taking item instead of instantly taking it away
// - Allow hopper to interact with other storage

// basically hopper grab nearby item or item from magazine above it to a magazine below it
// item or magazine > hopper > magazine > ....

void onTick(CBlob@ this) {
	// move items from hopper inventory
	if (this.getInventory().getItemsCount() > 0) 
	{
		MoveItemsToDown(this,this.getInventory().getItem(0));
		// any code above wont work if our inventory is full
		return;
	}

	// move items from mag above to this inventory
	if (MoveItemsToThis(this)) return;

	// move nearby items to hopper
	CBlob@[] items;
	getMap().getBlobsInBox(this.getPosition() + Vec2f(8,-8),this.getPosition() + Vec2f(-8,-8),items);
	// loop items
	if (items.length < 1) return;
	for(uint i = 0; i < items.length; i++)
	{
		// check items
		CBlob@ blob = items[i];
		if (blob is null) continue;
		if (!blob.isOnGround()) continue;
		if (blob.getShape().isStatic()) continue;
		if (blob.hasTag("player")) continue;
		if (!blob.canBePickedUp(this)) continue;
		// if found instantly move and return
		if (blob !is null) {
			MoveItemsToInv(this,blob);
			// slower tick update on hopper that only grab items
			this.getCurrentScript().tickFrequency = 60;
			return;
		}
	}
}

// the bools are for success and not
bool MoveItemsToInv(CBlob@ mag,CBlob@ blob) {
	// check inventory
	if (mag.getInventory().getItemsCount() > 0) return false;

	// put blob in inventory if its can
	if (blob.canBePutInInventory(mag)) 
	{
		if (isServer()) 
		{
			// actually send the blob to the mag
			mag.server_PutInInventory(blob);
			return true;
		}
	}
	return false;
}
// get items from a mag to us
bool MoveItemsToThis(CBlob@ this) {

	CBlob@[] magBlob;
	getMap().getBlobsAtPosition(this.getPosition() - Vec2f(0,8), @magBlob);
	// loop
	if (magBlob is null) return false;
	if (magBlob.length < 1) return false;
	for(uint i = 0; i < magBlob.length; i++)
	{
		// check if blob is magazine or hopper
		// print("check mag");
		CBlob@ mag = magBlob[i];
		if (mag is null) continue;
		if (!mag.getShape().isStatic()) continue;
		if (mag.getName() != "magazine") continue;
		if (mag.getInventory().getItemsCount() < 1) continue;
		// move items , if successful then return true
		if (MoveItemsToInv(this,mag.getInventory().getItem(0))) {
			// faster tick
			this.getCurrentScript().tickFrequency = 30;
			return true;
		}
	}
	// if not return false
	return false;
}

// move items to a mag or hopper downwards
void MoveItemsToDown(CBlob@ this,CBlob@ blob) 
{
	if (blob is null || blob.getShape().isStatic()) return;
	if (blob.hasTag("player")) return;

	// get magazine
	CBlob@[] blobs;
	getMap().getBlobsAtPosition(this.getPosition() + Vec2f(0,8), @blobs);

	if (blobs is null) return;
	if (blobs.length < 1) return;
	for(uint i = 0; i < blobs.length; i++)
	{
		// check if blob is magazine 
		CBlob@ mag = blobs[i];
		if (mag is null) continue;
		if (!mag.getShape().isStatic()) continue;
		if (mag.getName() != "magazine") continue;

		MoveItemsToInv(mag,blob);
	}
}

// send redstone signal everytime item is exported to this
void SendRedstoneSignal(CBlob@ this) {
	Component@ component = null;
	if (!this.get("component", @component)) return;

	MapPowerGrid@ grid;
	if (getRules().get("power grid", @grid)) {
		grid.setPower(
		component.x,                        // x
		component.y,                        // y
		power_source);                      // power
	}
}

// set frame
void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	if (isServer()) {SendRedstoneSignal(this);}
	this.getSprite().PlaySound("HopperLoad.ogg");
	this.getSprite().SetFrameIndex(1);
}

// reset frame
void onRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
	this.getSprite().SetFrameIndex(0);
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return false;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}