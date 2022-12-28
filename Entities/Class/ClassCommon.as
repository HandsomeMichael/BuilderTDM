// A common stuff for our builder class 

#include "Hitters.as";
#include "BuilderCommon.as";
#include "ThrowCommon.as";
#include "RunnerCommon.as";
#include "Help.as";
#include "Requirements.as"
#include "BuilderHittable.as";
#include "PlacementCommon.as";
#include "ParticleSparks.as";
#include "MaterialCommon.as";
#include "Utils.as";

// hit frammeeee
const s32 hit_frame = 2;

// my method
float GetHitDamage(CBlob@ this) {
	return this.get_f32("hitdamage");
}

void RotateBodyByVelocity(CBlob@ this) {
	// do dodge roll thingy
	if (this.hasTag("dodgeroll")) {

		// do dodgeroll thing
		this.setAngleDegrees(Maths::Lerp(this.getAngleDegrees(),this.get_f32("dodgeAngle"),0.175f));

		// untag earlier after dodgeroll
		if ((getGameTime() + 40) >= this.get_u32("dodgeroll_time")) {
			this.Untag("dodgeroll");
			this.Untag("invincible");
			this.Tag("flesh");
			// reset the angle so it doesnt rotate again
			this.setAngleDegrees(0);
		}

		return;
	}
	// kinda become like terraria overhaul
	f32 xFactor =  (Maths::Clamp(this.getVelocity().x, -3.0f, 3.0f) / 3.0f) * (this.isInWater() ? 150.0f : 30.0f);
	this.setAngleDegrees(Utils::LerpAngleDegree(this.getAngleDegrees(), xFactor, 0.3f));
}

// armor half the damage you took but loss its durability overtime
f32 ArmorBlockDamage(CBlob@ this,f32 damage) {
	if (this.hasTag("armored")) {
		this.set_f32("armorDamage",damage + this.get_f32("armorDamage")); // armor has 10 hp of durability
		return damage / 2;
	}
	return damage;
}

void HandleArmor(CBlob@ this) {

	if (!this.hasTag("armored")) {
		// remove layer
		if (isClient()) {
			CSpriteLayer@ layer = this.getSprite().getSpriteLayer("armorlayer");
			if (layer !is null) {
				this.getSprite().RemoveSpriteLayer("armorlayer");
			}
		}
		return;
	}

	// we break armor 
	if (this.get_f32("armorDamage") > 10.0f) {
		this.Untag("armored");
		this.set_f32("armorDamage",0.0f);
		this.getSprite().PlaySound("MinecraftBreak.ogg");
		return;
	}

	if (!isClient()) return;

	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ theArmor = sprite.getSpriteLayer("armorlayer");

	// if there is no armor then add one
	if (theArmor is null) {
		CSpriteLayer@ armor = sprite.addSpriteLayer("armorlayer", "ChainArmor.png" , 32, 32);
		Animation@ anim = armor.addAnimation("default", 0, false);
		anim.AddFrame(0);
		// a bit higher than our blob
		armor.SetOffset(sprite.getOffset());
		armor.SetRelativeZ(sprite.getRelativeZ()+1.0f);
		return;
	}

	// funk
	theArmor.SetFrame(sprite.getFrame());
}

void SendHitCommand(CBlob@ this, CBlob@ blob, const Vec2f tilepos, const Vec2f attackVel, const f32 attack_power)
{
	CBitStream params;
	params.write_netid(blob is null? 0 : blob.getNetworkID());
	params.write_Vec2f(tilepos);
	params.write_Vec2f(attackVel);
	params.write_f32(attack_power);

	this.SendCommand(this.getCommandID("pickaxe"), params);
}

//helper class to reduce function definition cancer
//and allow passing primitives &inout
class SortHitsParams
{
	Vec2f aimPos;
	Vec2f tilepos;
	Vec2f pos;
	bool justCheck;
	bool extra;
	bool hasHit;
	HitInfo@ bestinfo;
	f32 bestDistance;
};

void SortHits(CBlob@ this, HitInfo@[]@ hitInfos, f32 damage, SortHitsParams@ p)
{
	//HitInfo objects are sorted, first come closest hits
	for (uint i = 0; i < hitInfos.length; i++)
	{
		HitInfo@ hi = hitInfos[i];

		CBlob@ b = hi.blob;
		if (b !is null) // blob
		{
			if (!canHit(this, b, p.tilepos, p.extra))
			{
				continue;
			}

			if (!p.justCheck && isUrgent(this, b))
			{
				p.hasHit = true;
				SendHitCommand(this, hi.blob, hi.hitpos, hi.blob.getPosition() - p.pos, damage);
			}
			else
			{
				bool never_ambig = neverHitAmbiguous(b);
				f32 len = never_ambig ? 1000.0f : (p.aimPos - b.getPosition()).Length();
				if (len < p.bestDistance)
				{
					if (!never_ambig)
						p.bestDistance = len;

					@(p.bestinfo) = hi;
				}
			}
		}
	}
}

bool ExtraQualifiers(CBlob@ this, CBlob@ b, Vec2f tpos)
{
	//urgent stuff gets a pass here
	if (isUrgent(this, b))
		return true;

	//check facing - can't hit stuff we're facing away from
	f32 dx = (this.getPosition().x - b.getPosition().x) * (this.isFacingLeft() ? 1 : -1);
	if (dx < 0)
		return false;

	//only hit static blobs if aiming directly at them
	CShape@ bshape = b.getShape();
	if (bshape.isStatic())
	{
		bool bigenough = bshape.getWidth() >= 8 &&
		                 bshape.getHeight() >= 8;

		if (bigenough)
		{
			if (!b.isPointInside(this.getAimPos()) && !b.isPointInside(tpos))
				return false;
		}
		else
		{
			Vec2f bpos = b.getPosition();
			//get centered on the tile it's positioned on (for offset blobs like spikes)
			Vec2f tileCenterPos = Vec2f(s32(bpos.x / 8), s32(bpos.y / 8)) * 8 + Vec2f(4, 4);
			f32 dist = Maths::Min((tileCenterPos - this.getAimPos()).LengthSquared(),
			                      (tileCenterPos - tpos).LengthSquared());
			if (dist > 25) //>5*5
				return false;
		}
	}

	return true;
}


void Pickaxe(CBlob@ this)
{
	HitData@ hitdata;
	CSprite @sprite = this.getSprite();
	bool strikeAnim = sprite.isAnimation("strike") || sprite.isAnimation("strike_fast") || sprite.isAnimation("chop") || sprite.isAnimation("chop_fast");

	if (!strikeAnim)
	{
		this.get("hitdata", @hitdata);
		hitdata.blobID = 0;
		hitdata.tilepos = Vec2f_zero;
		return;
	}

	// no damage cause we just check hit for cursor display
	bool justCheck = !sprite.isFrameIndex(hit_frame);
	bool adjusttime = sprite.getFrameIndex() < hit_frame - 1;

	// pickaxe!

	this.get("hitdata", @hitdata);

	if (hitdata is null) return;

	Vec2f blobPos = this.getPosition();
	Vec2f aimPos = this.getAimPos();
	Vec2f aimDir = aimPos - blobPos;

	// get tile surface for aiming at little static blobs
	Vec2f normal = aimDir;
	normal.Normalize();

	Vec2f attackVel = normal;

	if (!adjusttime)
	{
		if (!justCheck)
		{
			if (hitdata.blobID == 0)
			{
				TileType t = getMap().getTile(hitdata.tilepos).type;
				if (t != CMap::tile_empty && t != CMap::tile_ground_back)
				{
					SendHitCommand(this, null, hitdata.tilepos, attackVel, GetHitDamage(this));
				}

			}
			else
			{
				CBlob@ b = getBlobByNetworkID(hitdata.blobID);
				if (b !is null)
				{
					SendHitCommand(this, b, (b.getPosition() + this.getPosition()) * 0.5f, attackVel, GetHitDamage(this));
				}
			}
		}
		return;
	}

	hitdata.blobID = 0;
	hitdata.tilepos = Vec2f_zero;

	f32 arcdegrees = 90.0f;

	f32 aimangle = aimDir.Angle();
	Vec2f pos = blobPos - Vec2f(2, 0).RotateBy(-aimangle);
	f32 attack_distance = this.getRadius() + this.get_f32("pickaxe_distance");
	f32 radius = this.getRadius();
	CMap@ map = this.getMap();
	bool dontHitMore = false;

	bool hasHit = false;

	const f32 tile_attack_distance = attack_distance * 1.5f;
	Vec2f tilepos = blobPos + normal * Maths::Min(aimDir.Length() - 1, tile_attack_distance);
	Vec2f surfacepos;
	map.rayCastSolid(blobPos, tilepos, surfacepos);

	Vec2f surfaceoff = (tilepos - surfacepos);
	f32 surfacedist = surfaceoff.Normalize();
	tilepos = (surfacepos + (surfaceoff * (map.tilesize * 0.5f)));

	// this gathers HitInfo objects which contain blob or tile hit information
	HitInfo@ bestinfo = null;
	f32 bestDistance = 100000.0f;

	HitInfo@[] hitInfos;

	//setup params for ferrying data in/out
	SortHitsParams@ hit_p = SortHitsParams();

	//copy in
	hit_p.aimPos = aimPos;
	hit_p.tilepos = tilepos;
	hit_p.pos = pos;
	hit_p.justCheck = justCheck;
	hit_p.extra = true;
	hit_p.hasHit = hasHit;
	@(hit_p.bestinfo) = bestinfo;
	hit_p.bestDistance = bestDistance;

	if (map.getHitInfosFromArc(pos, -aimangle, arcdegrees, attack_distance, this, @hitInfos))
	{
		SortHits(this, hitInfos, GetHitDamage(this), hit_p);
	}

	aimPos = hit_p.aimPos;
	tilepos = hit_p.tilepos;
	pos = hit_p.pos;
	justCheck = hit_p.justCheck;
	hasHit = hit_p.hasHit;
	@bestinfo = hit_p.bestinfo;
	bestDistance = hit_p.bestDistance;

	Tile tile = map.getTile(tilepos);
	bool noBuildZone = inNoBuildZone(map, tilepos, tile.type);
	bool isgrass = false;

	if ((tilepos - aimPos).Length() < bestDistance - 4.0f && map.getBlobAtPosition(tilepos) is null)
	{
		Tile tile = map.getTile(surfacepos);

		if (!noBuildZone && !map.isTileGroundBack(tile.type))
		{
			//normal, honest to god tile
			if (map.isTileBackgroundNonEmpty(tile) || map.isTileSolid(tile))
			{
				hasHit = true;
				hitdata.tilepos = tilepos;
			}
			else if (map.isTileGrass(tile.type))
			{
				//NOT hashit - check last for grass
				isgrass = true;
			}
		}
	}

	if (!hasHit)
	{
		//copy in
		hit_p.aimPos = aimPos;
		hit_p.tilepos = tilepos;
		hit_p.pos = pos;
		hit_p.justCheck = justCheck;
		hit_p.extra = false;
		hit_p.hasHit = hasHit;
		@(hit_p.bestinfo) = bestinfo;
		hit_p.bestDistance = bestDistance;

		//try to find another possible one
		if (bestinfo is null)
		{
			SortHits(this, hitInfos, GetHitDamage(this), hit_p);
		}

		//copy out
		aimPos = hit_p.aimPos;
		tilepos = hit_p.tilepos;
		pos = hit_p.pos;
		justCheck = hit_p.justCheck;
		hasHit = hit_p.hasHit;
		@bestinfo = hit_p.bestinfo;
		bestDistance = hit_p.bestDistance;

		//did we find one (or have one from before?)
		if (bestinfo !is null)
		{
			hitdata.blobID = bestinfo.blob.getNetworkID();
		}
	}

	if (isgrass && bestinfo is null)
	{
		hitdata.tilepos = tilepos;
	}

	CBitStream cbs;
	cbs.write_Vec2f(hitdata.tilepos);
	cbs.write_netid(hitdata.blobID);

	this.SendCommand(this.getCommandID("hitdata sync"), cbs);
}

bool neverHitAmbiguous(CBlob@ b)
{
	string name = b.getName();
	return name == "saw";
}

bool canHit(CBlob@ this, CBlob@ b, Vec2f tpos, bool extra = true)
{
	if (extra && !ExtraQualifiers(this, b, tpos))
	{
		return false;
	}

	if (b.hasTag("invincible"))
	{
		return false;
	}

	if (b.getTeamNum() == this.getTeamNum())
	{
		//no hitting friendly carried stuff
		if (b.isAttached())
			return false;

		if (BuilderAlwaysHit(b) || b.hasTag("dead") || b.hasTag("vehicle"))
			return true;

		if (b.getName() == "saw" || b.getName() == "trampoline" || b.getName() == "crate")
			return true;

		return false;

	}
	//no hitting stuff in hands
	else if (b.isAttached() && !b.hasTag("player"))
	{
		return false;
	}

	//static/background stuff
	CShape@ b_shape = b.getShape();
	if (!b.isCollidable() || (b_shape !is null && b_shape.isStatic()))
	{
		//maybe we shouldn't hit this..
		//check if we should always hit
		if (BuilderAlwaysHit(b))
		{
			if (!b.isCollidable() && !isUrgent(this, b))
			{
				//TODO: use a better overlap check here
				//this causes issues with quarters and
				//any other case where you "stop overlapping"
				if (!this.isOverlapping(b))
					return false;
			}
			return true;
		}
		//otherwise no hit
		return false;
	}

	return true;
}

void TempBlob_onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	// ignore collision for built blob
	BuildBlock[][]@ blocks;
	if (!this.get("blocks", @blocks))
	{
		return;
	}

	const u8 PAGE = this.get_u8("build page");
	for (u8 i = 0; i < blocks[PAGE].length; i++)
	{
		BuildBlock@ block = blocks[PAGE][i];
		if (block !is null && block.name == detached.getName())
		{
			this.IgnoreCollisionWhileOverlapped(null);
			detached.IgnoreCollisionWhileOverlapped(null);
		}
	}

	// BUILD BLOB
	// take requirements from blob that is built and play sound
	// put out another one of the same
	if (detached.hasTag("temp blob"))
	{
		detached.Untag("temp blob");
		
		if (!detached.hasTag("temp blob placed"))
		{
			detached.server_Die();
			return;
		}

		uint i = this.get_u8("buildblob");
		if (i >= 0 && i < blocks[PAGE].length)
		{
			BuildBlock@ b = blocks[PAGE][i];
			if (b.name == detached.getName())
			{
				this.set_u8("buildblob", 255);
				this.set_TileType("buildtile", 0);

				CInventory@ inv = this.getInventory();

				CBitStream missing;
				if (hasRequirements(inv, b.reqs, missing, not b.buildOnGround))
				{
					server_TakeRequirements(inv, b.reqs);
				}
				// take out another one if in inventory
				server_BuildBlob(this, blocks[PAGE], i);
			}
		}
	}
	else if (detached.getName() == "seed")
	{
		if (not detached.hasTag('temp blob placed')) return;

		CBlob@ anotherBlob = this.getInventory().getItem(detached.getName());
		if (anotherBlob !is null)
		{
			this.server_Pickup(anotherBlob);
		}
	}
}

void TempBlob_onAddToInventory(CBlob@ this, CBlob@ blob)
{
	// destroy built blob if somehow they got into inventory
	if (blob.hasTag("temp blob"))
	{
		blob.server_Die();
		blob.Untag("temp blob");
	}

	if (this.isMyPlayer() && blob.hasTag("material"))
	{
		SetHelp(this, "help inventory", "builder", "$Help_Block1$$Swap$$Help_Block2$           $KEY_HOLD$$KEY_F$", "", 3);
	}
}