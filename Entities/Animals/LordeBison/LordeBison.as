
// script for a LORDE BISON
// more comment about ai on lordebisonbrain

#include "AnimalConsts.as"; // reference state_property
#include "LordeBisonBrain.as"; // reference state enum
#include "ScriptBoss.as"; // setting boss
#include "Hitters.as";
#include "Utils.as"; // math stuff

// ================================ SPRITE ================================================

void onInit(CSprite@ this) 
{
	this.SetAnimation("awoken");
	this.ReloadSprites(0, 0); // always blue
}

// for debugging
// void onRender(CSprite@ this) {

// 	CBlob@ b = this.getBlob();
// 	if (b is null) return;

// 	string text = "state = "+b.get_u8(state_property);
// 	text += "\ntarget = "+b.get_netid(target_property);
// 	text += "\ndelay = "+b.get_u8(delay_property);
// 	text += "\nanimation = "+this.animation.name;

// 	GUI::SetFont("SNES");
// 	GUI::DrawTextCentered(text, b.getInterpolatedScreenPos(), SColor(255,255,255,255));
// }

void onTick(CSprite@ this)
{	
	// check blob
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	if (!blob.hasTag("dead"))
	{
		// walking animation
		u8 state = blob.get_u8(state_property);

		if (state == STATE_TARGET) {
			f32 x = blob.getVelocity().x;
			this.SetAnimation(((Maths::Abs(x) > 0.2f) ? "walk" : "idle"));
		}
		else if (state == STATE_SPAWNED) {
			if (!this.isAnimation("awoken"))this.SetAnimation("awoken");
		}
		else if (state == STATE_TELEPORT) 
		{
			this.SetAnimation("teleport");
		}
	}
	else
	{
		this.SetAnimation("dead");
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
}

// ================================ BLOB ================================================

void onInit(CBlob@ this)
{
	// apply brain
	this.getBrain().server_SetActive(true);

	// camera set current boss
	ScriptBoss_SetBoss(this,120);

	//for shape
	this.getShape().SetRotationsAllowed(false);
	this.getShape().SetOffset(Vec2f(0, 12));

	this.set_f32("gib health", -0.0f); //for flesh hit
	this.set_u8("number of steaks", 9); //for steaks

	// required tags
	this.Tag("flesh");
	this.Tag("boss");

	// minimap icon
	this.SetMinimapVars("/lordebison_Icon.png", 1, Vec2f(16, 16));
}

// sorry , but you cant pickup the godly terrific monster from the nightmares
bool canBePickedUp(CBlob@ this, CBlob@ byBlob){return false;}

// projectile spam go brrrrrr
void ShootSpike(CBlob@ this , Vec2f velocity) {
	CBlob@ spike = server_CreateBlob("bloodspike");
	if (spike !is null)
	{
		spike.IgnoreCollisionWhileOverlapped( this );
		spike.setPosition( this.getPosition() );
		spike.setVelocity( velocity );
	}
}

// check bison spawning or teleport
bool IsSpawning(CBlob@ this) {
	u8 state = this.get_u8(state_property);
	return state == STATE_SPAWNED || state == STATE_TELEPORT;
}

void onTick(CBlob@ this)
{
	// untag blob 
	if (this.hasTag("justGotHit")) this.Untag("justGotHit");
	
	// do nothing when spawned
	u8 state = this.get_u8(state_property);
	if (state == STATE_SPAWNED) return;

	// teleport state
	if (state == STATE_TELEPORT) 
	{
		u32 teleport_time = this.get_u32("teleport_time");

		if (teleport_time == 0) {
			this.set_u32("teleport_time",getGameTime() + 30); // will teleport after few ticks
			this.getSprite().PlaySound("DisgustingFleshIn.ogg");
		}
		else if (getGameTime() >= teleport_time) 
		{
			this.setPosition(this.get_Vec2f("teleport_target"));
			this.getSprite().PlaySound("DisgustingFleshOut.ogg");
			this.set_u32("teleport_time",0);
			this.set_u8(state_property,STATE_SPAWNED);
		}
	}

	// shooting spikes each 30 ticks when targetting
	if (state == STATE_TARGET) {
		if (this.getTickSinceCreated() % (35 + this.get_u8("spike_delay")) == 0) 
		{
			ShootSpike(this,Vec2f(0,-20));
			this.set_u8("spike_delay",XORRandom(10));
		}
	}

	// facing
	Utils::AutoFacing(this);

	// footsteps
	if (this.isOnGround() && (this.isKeyPressed(key_left) || this.isKeyPressed(key_right)))
	{
		if ((this.getNetworkID() + getGameTime()) % 9 == 0)
		{
			f32 volume = Maths::Min(0.1f + Maths::Abs(this.getVelocity().x) * 0.1f, 1.0f);
			TileType tile = this.getMap().getTile(this.getPosition() + Vec2f(0.0f, this.getRadius() + 4.0f)).type;
			this.getSprite().PlaySound( (this.getMap().isTileGroundStuff(tile) ? "/EarthStep" : "/StoneStep"), volume, 0.75f);
		}
	}
}

void MadAt(CBlob@ this, CBlob@ hitterBlob)
{
	// get really angry
	this.set_u8(state_property, STATE_TARGET);
	this.set_netid(target_property, Utils::GetRealDamageOwnerID(hitterBlob));
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	// no damage on spawn
	if (IsSpawning(this)) return 0.0f;

	ScriptBoss_BossHit(this);
	MadAt(this, hitterBlob);

	return damage;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob) 
{
	// no collison on spawn
	if (IsSpawning(this)) return false;
	return !blob.hasTag("dead");
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	// do nothing on spawning animation
	if (blob is null)return;
	if (IsSpawning(this)) return;

	if (blob.hasTag("flesh"))
	{
		const f32 vellen = this.getShape().vellen;
		if (vellen > 0.1f)
		{
			Vec2f vel = this.getVelocity();
			Vec2f other_pos = blob.getPosition();
			Vec2f direction = other_pos - this.getPosition();
			direction.Normalize();
			vel.Normalize();
			if (vel * direction > 0.33f)
			{
				f32 power = Maths::Max(0.25f, 1.0f * vellen);
				this.server_Hit(blob, point1, vel, power, Hitters::flying, false);
			}
		}

		MadAt(this, blob);
	}
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (hitBlob !is null && customData == Hitters::flying)
	{
		Vec2f force = velocity * this.getMass() * 0.35f ;
		force.y -= 100.0f;
		hitBlob.AddForce(force);
	}
}