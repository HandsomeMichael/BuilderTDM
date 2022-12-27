// THE SPEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEED

#include "RunnerCommon.as"

void onInit(CMovement@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CMovement@ this)
{
	CBlob@ blob = this.getBlob();
	RunnerMoveVars@ moveVars;
	if (!blob.get("moveVars", @moveVars)){return;}

	const bool left		= blob.isKeyPressed(key_left);
	const bool right	= blob.isKeyPressed(key_right);
	const bool up		= blob.isKeyPressed(key_up);
	const bool down		= blob.isKeyPressed(key_down);

	blob.getShape().SetGravityScale(0.0f);

	Vec2f lordeForce;
	if (up){lordeForce.y -= 1.0f;}
	if (down){lordeForce.y += 1.0f;}
	if (left){lordeForce.x -= 1.0f;}
	if (right){lordeForce.x += 1.0f;}
	
	blob.setVelocity(blob.getVelocity() * 0.90f);
	blob.AddForce(lordeForce * moveVars.overallScale * 100.0f);
}

bool checkForSolidMapBlob(CMap@ map, Vec2f pos){return false;}
