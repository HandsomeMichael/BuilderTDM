#define SERVER_ONLY

#include "PressOldKeys.as";
#include "AnimalConsts.as";

// do a completely custom ai using my knowledge of making dumb terraria mod

// AI plan :

// - teleport to player when its too far off
// - ignore player that is invincible to prevent spawn killing
// - basic targetting stuff idk
// - no fancy pathfinding

// states
const u8 STATE_SPAWNED = 0;	// do nothing
const u8 STATE_IDLE = 1; 	// search prey each tick, maybe add more delay on this
const u8 STATE_TARGET = 2;  // go to the target and smack em, if the target is too far then teleport to it
const u8 STATE_TELEPORT = 3;		// the most important state

const f32 TELEPORT_DISTANCE = 120.0f; // teleport distance

void onInit(CBrain@ this)
{
	CBlob @blob = this.getBlob();

	blob.set_u8(delay_property , 5 + XORRandom(5));
	blob.set_u8(state_property, STATE_SPAWNED);

	this.getCurrentScript().removeIfTag	= "dead";
	this.getCurrentScript().runFlags |= Script::tick_not_attached;

	// we want this to always run regardless of radius , always try to target players
	// if they run away or start ratting it will teleport to the current player, destroying them in process

	//this.getCurrentScript().runProximityTag = "player";
	//this.getCurrentScript().runProximityRadius = 200.0f;
	//this.getCurrentScript().runFlags |= Script::tick_blob_in_proximity; 

	// the best way to kill this bison is to gangbang him and make it confused of wich to attack first
	// however i plan to make this thing spam projectiles just like every terraria boss ever
	// player then forced to use custom dodgeroll mechanic to dodge it

	//this.getCurrentScript().tickFrequency = 5; // cant limit this, needs to press keys each frame
}


void onTick(CBrain@ this)
{
	// check blob , dis important cuz sometime it just broke
	CBlob @blob = this.getBlob();
	if (blob is null) return;

	// delay the ai , maybe change it to modulo or something
	u8 delay = blob.get_u8(delay_property);
	if (delay > 0) delay--;

	// update the ai each 4 to 8 tick
	if (delay == 0){
		delay = 4 + XORRandom(8);
		AI(blob);
	}
	else{PressOldKeys(blob);}

	blob.set_u8(delay_property, delay);
}

void AI(CBlob@ blob) 
{
	// states
	u8 STATE = blob.get_u8(state_property);

	// first state , wait for few ticks
	if (STATE == STATE_SPAWNED) {
		if (blob.getTickSinceCreated() > 60) {
			STATE = STATE_IDLE;
		}
	}
	// idle state , find nearest flesh blob
	else if (STATE == STATE_IDLE){
		if (FindFlesh(blob)) {
			STATE = STATE_TARGET;
		}
	}
	// target state , hunt the freeman
	else if (STATE == STATE_TARGET)
	{
		// never lose its target
		CBlob@ target = getBlobByNetworkID(blob.get_netid(target_property));
		if (target is null) 
		{
			STATE = STATE_IDLE;
		}
		else
		{
			Vec2f tpos = target.getPosition();

			// if the target is too far then teleport to it
			if (blob.getDistanceTo(target) > TELEPORT_DISTANCE) 
			{
				blob.set_Vec2f("teleport_target",target.getPosition());
				STATE = STATE_TELEPORT;
			}
			else {
				// go to the target
				Vec2f pos = blob.getPosition();

				blob.setKeyPressed((tpos.x < pos.x) ? key_left : key_right, true);

				if (blob.isOnGround() && tpos.y <= pos.y + 3 * blob.getRadius())
				{
					blob.setKeyPressed((tpos.y < pos.y) ? key_up : key_down, true);
				}
			}
		}
	}

	// reset state
	blob.set_u8(state_property, STATE);
}



// find za flesh
bool FindFlesh(CBlob@ blob) {

	// set up stuff
	CBlob@[] blobs;
	int targetIndex = -1;
	float shortestDistance = 0.0f;

	if (!getBlobsByTag("player", blobs)) return false;
	//blob.getMap().getBlobsInRadius(blob.getPosition(), TELEPORT_DISTANCE*10.0f, @blobs);

	// loop
	for (uint step = 0; step < blobs.length; ++step)
	{
		CBlob@ other = blobs[step];
		if (other is null || other is blob) continue; // ignore null and self
		if (other.hasTag("flesh")) // check if it has flesh
		{
			print("found candidate : "+other.getNetworkID());
			// calculate distance using kag built in method
			float curDistance = blob.getDistanceTo(other);
			// check if distance is shorter or first index
			if (targetIndex == -1 || shortestDistance < curDistance) {

				print("set candidate : "+other.getNetworkID() + " or "+step);

				targetIndex = step;
				shortestDistance = curDistance;
			}
		}
	}

	// attack nearest flesh blob
	if (targetIndex != -1) {
		blob.set_netid(target_property, blobs[targetIndex].getNetworkID());
		print("target found");
		return true;
	}

	print("target not found");

	return false;
}