// Leash logic , Modified from TC SlaveBall.as

#include "Utils.as";

// max distance of rope
const f32 maxDistance = 80.0f;

void onInit(CBlob@ this)
{
	// throwing wont instantly break this
	this.Tag("ignore fall");

	// reset leash id 
	this.set_netid("leashID",0);

	// reset and add rope layer
	this.getSprite().RemoveSpriteLayer("rope");
	CSpriteLayer@ rope = this.getSprite().addSpriteLayer("rope", "Leash_rope.png", 32, 2);
	Animation@ anim = rope.addAnimation("default", 0, false);
	anim.AddFrame(0);
	rope.SetRelativeZ(-10.0f);
	rope.SetVisible(false);
}

// TO DO : Find a way to make leash affected by mass , dragging around warbot is unfunny :anger:

void onTick(CBlob@ this)
{
	// leash id are blob's network id
	u16 leashID = this.get_netid("leashID");

	if (leashID < 1) 
	{
		// set to invisible if no leash id
		if (isClient()) {
			CSpriteLayer@ rope = this.getSprite().getSpriteLayer("rope");
			rope.SetVisible(false);
		}
		return;
	}

	// sometimes blob network id can become very weird
	CBlob@ blob = getBlobByNetworkID(leashID);

	// reset leash id if null
	if (blob is null) {this.set_netid("leashID",0);}
	else {

		// we do the funny
		// code modified from TC SlaveBall.as
		Vec2f blobPos = blob.getPosition();

		// leash offset for drawing
		if (blob.exists("leashOffset")) {
			Vec2f offset = blob.get_Vec2f("leashOffset").RotateByRadians(blob.getAngleRadians());
			blobPos.y += offset.y;
			blobPos.x += blob.isFacingLeft() ? -offset.x : offset.x;
		}

		// get dir
		Vec2f dir = (this.getPosition() - blobPos);
		f32 distance = dir.Length();
		dir.Normalize();

		// check max dist
		if (distance > maxDistance) {

			// push blobs
			DoPushBlobOwner(this,-dir); // this blob pushed into the blob
			DoPushBlobOwner(blob,dir * 2.0f); // leashed blob pushed more harder
		}

		// set rope line
		if (isClient()) {
			SetRopeLine(this,distance / 32, -dir.Angle());
		}
	}
}

// in tc they push it by setting velocity and position
void PushBlob(CBlob@ this,Vec2f dir) {

	//vehicle doesnt seems to get that much push effect meanwhile player get pushed into oblivion

	if (this.hasTag("vehicle")) {
		//this.setPosition(this.getPosition() - dir * maxDistance * 0.999f);	
		this.setVelocity(dir);
	}
	else {
		this.AddForce(dir*200.0f);
	}
}

// set blob velocity
void DoPushBlobOwner(CBlob@ this,Vec2f dir, bool finalCheck = false) {

	// push the owner of blob if its in inventory
	if (this.isInInventory()) {
		CBlob@ owner = this.getInventoryBlob();
		if (owner !is null) {
			PushBlob(owner,dir);
			return;
		}
	}

	// push holder of blob if its picked up
	if (this.isAttached()) {
		// use utils method that i made to shorten code
		CBlob@ holder = Utils::GetHolder(this);
		if (holder !is null) {
			// do another check incase this scummy is in crate
			if (finalCheck) {PushBlob(holder,dir);}
			else {DoPushBlobOwner(holder,dir,true);}
			return;
		}
	}

	// regulary push the blob
	PushBlob(this,dir);
}

// stolen from tc with few modification
void SetRopeLine(CBlob@ this, f32 length, f32 angle)
{
	CSpriteLayer@ rope = this.getSprite().getSpriteLayer("rope");

	// set offset when putted on inventory
	if (this.isInInventory()) {

		CBlob@ blob = this.getInventoryBlob();
		// if somehow the blob is null then we reset
		if (blob is null) {
			rope.SetOffset(Vec2f_zero);
			rope.SetVisible(false);
			return;
		}
		// offset the rope , x and y is very weird so i have to do this
		// rotation also still broken
		Vec2f drawPos = this.get_Vec2f("drawPos");
		float xPos = this.isFacingLeft() ? (blob.getPosition().x - drawPos.x) : (drawPos.x - blob.getPosition().x);
		rope.SetOffset(Vec2f(xPos, blob.getPosition().y - drawPos.y));
	}
	else {
		// reset offset
		rope.SetOffset(Vec2f_zero);
	}

	// stretch the sprite
	rope.SetVisible(true);
	rope.ResetTransform();
	rope.ScaleBy(Vec2f(length, 1.0f));
	rope.TranslateBy(Vec2f(length * 16.0f, 0.0f));
	rope.RotateBy(angle + 180, Vec2f());//(flip ? 180 : 0)
}

// also stolen from tc
void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	if (inventoryBlob is null) return;
	CInventory@ inv = inventoryBlob.getInventory();
	if (inv is null) return;

	// old pos for drawing
	this.set_Vec2f("drawPos",this.getPosition());

	this.doTickScripts = true;
	inv.doTickScripts = true;
}

// // render timeleft for restock
// void onRender(CSprite@ this)
// {
// 	// only king can debug

// 	CBlob@ b = this.getBlob();
// 	if (b is null) return;

// 	u32 leashID = b.get_netid("leashID");
// 	GUI::SetFont("SNES");
// 	GUI::DrawTextCentered("networkID = "+leashID, b.getInterpolatedScreenPos(), SColor(255,255,255,255));
// }