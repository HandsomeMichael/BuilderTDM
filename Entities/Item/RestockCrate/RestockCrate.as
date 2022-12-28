// generic crate
// can hold items in inventory or unpacks to catapult/ship etc.

#include "CrateCommon.as"
#include "MiniIconsInc.as"
#include "Help.as"
#include "Hitters.as"

void ShowParachute(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ parachute = sprite.addSpriteLayer("parachute",   32, 32);

	if (parachute !is null)
	{
		Animation@ anim = parachute.addAnimation("default", 0, true);
		anim.AddFrame(4);
		parachute.SetOffset(Vec2f(0.0f, - 17.0f));
	}
}

void HideParachute(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ parachute = sprite.getSpriteLayer("parachute");

	if (parachute !is null && parachute.isVisible())
	{
		parachute.SetVisible(false);
		ParticlesFromSprite(parachute);
	}
}

void ResetRestockerTimer(CBlob@ this) {

	u16 restockerID = this.get_netid("restockerID");
	if (restockerID > 0) 
	{
		CBlob@ restocker = getBlobByNetworkID(restockerID);
		if (restocker !is null) 
		{
			restocker.set_u32("drop_mats",getGameTime() + (this.get_u16("reset_time")));
			restocker.Untag("wait");
		}
	}
}

void onTick(CBlob@ this)
{
	// parachute
	if (this.hasTag("parachute"))		// wont work with the tick frequency
	{
		if (this.getSprite().getSpriteLayer("parachute") is null)
		{
			ShowParachute(this);
		}

		// para force + swing in wind
		this.AddForce(Vec2f(Maths::Sin(getGameTime() * 0.03f) * 1.0f, -30.0f * this.getVelocity().y));

		if (this.isOnGround() || this.isInWater() || this.isAttached())
		{
			this.Untag("parachute");
			HideParachute(this);
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob){
	return (this.getName() == blob.getName()) || ((blob.getShape().isStatic() || blob.hasTag("player") || blob.hasTag("projectile")) && !blob.hasTag("parachute"));
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob) { return false; }

void onDie(CBlob@ this)
{
	HideParachute(this);
	ResetRestockerTimer(this);

	this.getSprite().Gib();
	Vec2f pos = this.getPosition();
	Vec2f vel = this.getVelocity();

	//custom gibs
	string fname = CFileMatcher("/Crate.png").getFirst();
	for (int i = 0; i < 4; i++)
	{
		CParticle@ temp = makeGibParticle(fname, pos, vel + getRandomVelocity(90, 1 , 120), 9, 2 + i, Vec2f(16, 16), 2.0f, 20, "Sounds/material_drop.ogg", 0);
	}
}