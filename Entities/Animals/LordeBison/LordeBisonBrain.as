#define SERVER_ONLY

#include "PressOldKeys.as";
#include "AnimalConsts.as";

// do a completely custom ai using my knowledge of making dumb terraria mod

// AI plan :

// - teleport to player when its too far off
// - ignore player that is invincible to prevent spawn killing
// - basic targetting stuff idk

enum state
{
	STATE_IDLE = 0, // search prey each tick, maybe add more delay on this
	STATE_TARGET,  	// go to the target and smack em, if the target is too far then teleport to it
	STATE_SPAWNED, 	// do nothing
	STATE_TELEPORT 	// do teleport animation
}

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
	Vec2f pos = blob.getPosition();
	bool facing_left = blob.isFacingLeft();
	u8 mode = blob.get_u8(state_property);

	// "blind" attacking
	if (mode == STATE_TARGET)
	{
		// never lose its target
		CBlob@ target = getBlobByNetworkID(blob.get_netid(target_property));
		if (target is null){mode = STATE_IDLE;}
		else
		{
			Vec2f tpos = target.getPosition();


			if ((tpos - pos).getLength() >= (targetSearchRadius))
			{
				mode = STATE_IDLE;
			}

			blob.setKeyPressed((tpos.x < pos.x) ? key_left : key_right, true);

			// if (personality & DONT_GO_DOWN_BIT == 0 || (blob.isOnGround() && tpos.y <= pos.y + 3 * blob.getRadius()))
			// {
			// 	blob.setKeyPressed((tpos.y < pos.y) ? key_up : key_down, true);
			// }
		}
	}
	// 
	else 
	{
		// find nearest flesh blob
		if (mode == STATE_SPAWNED) {
			if (blob.getTickSinceCreated() > 70) {
				mode = STATE_IDLE;
			}
		}
		else {
			if (FindFlesh(blob)) {
				mode = STATE_TARGET;
			}
		}

		if (blob.getTickSinceCreated() > 30) // delay so we dont get false terriroty pos
		{
			Vec2f territory_pos = blob.get_Vec2f(terr_pos_property);

			Vec2f territory_dir = (territory_pos - pos);
			////("territory " + territory_pos.x + " " + territory_pos.y );
			//	printf("territory_dir " + territory_dir.Length() + " " + territoryRadius  );
			if (territory_dir.Length() > territoryRadius && !blob.hasAttached())
			{
				//head towards territory

				blob.setKeyPressed((territory_dir.x < 0.0f) ? key_left : key_right, true);
				blob.setKeyPressed((territory_dir.y > 0.0f) ? key_down : key_up, true);
			}
			else
			{
				//change direction at random or when on wall

				if (XORRandom(randomMoveFreq) == 0 || blob.isOnWall())
				{
					blob.setKeyPressed(blob.wasKeyPressed(key_right) ? key_left : key_right, true);
				}

				if (XORRandom(randomMoveFreq) == 0 || blob.isOnCeiling() || blob.isOnGround())
				{
					blob.setKeyPressed(blob.wasKeyPressed(key_down) ? key_down : key_down, true);
				}
			}
		}

	}

	blob.set_u8(state_property, mode);
}



// find za flesh
bool FindFlesh(CBlob@ blob) {

	// set up stuff
	CBlob@[] blobs;
	uint targetIndex = -1;
	float shortestDistance = 0.0f;
	blob.getMap().getBlobsInRadius(blob.getPosition(), targetSearchRadius, @blobs);

	// loop
	for (uint step = 0; step < blobs.length; ++step)
	{
		CBlob@ other = blobs[step];
		if (other is null || other is blob) continue; // ignore null and self
		if (other.hasTag("flesh")) // check if it has flesh
		{
			// calculate distance using kag built in method
			float curDistance = blob.getDistanceTo(other);
			// check if distance is shorter or first index
			if (targetIndex == -1 || shortestDistance < curDistance) {
				targetIndex = step;
				shortestDistance = curDistance;
			}
		}
	}

	// attack nearest flesh blob
	if (targetIndex > -1) {
		blob.set_netid(target_property, blobs[targetIndex].getNetworkID());
		return true;
	}

	return false;
}