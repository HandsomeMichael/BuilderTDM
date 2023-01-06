// generic crate
// can hold items in inventory or unpacks to catapult/ship etc.

#include "CrateCommon.as"
#include "MiniIconsInc.as"
#include "Help.as"
#include "Hitters.as"

void ShowParachute(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ parachute = sprite.addSpriteLayer("parachute", "Crate.png", 32, 32);

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

CBlob@ GetRestocker(CBlob@ this) 
{
	// prevent error funny funky friday
	u16 restockerID = this.get_netid("restockerID");
	if (restockerID < 1) return null;

	return getBlobByNetworkID(restockerID);
}
void ResetRestockerTimer(CBlob@ this) {

	CBlob@ restocker = GetRestocker(this);
	if (restocker !is null) 
	{
		restocker.doTickScripts = true;
		restocker.set_u32("drop_mats",getGameTime() + (this.get_u16("reset_time")));
		restocker.Untag("wait");
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
			// unparachute the parachute
			this.Untag("parachute");
			HideParachute(this);

			// remove tick script 
			this.doTickScripts = false;

			// set despawn time
			if (this.exists("reset_time")) 
			{
				this.server_SetTimeToDie(this.get_u16("reset_time") * 2);
			}
			else 
			{
				this.server_SetTimeToDie(3600); // default to 1 minute
			}

			// do the funny
			CBlob@ restocker = GetRestocker(this);
			if (restocker !is null) 
			{
				restocker.Untag("RestockLanding");
			}
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob){
	return (this.getName() == blob.getName()) || ((blob.getShape().isStatic() || blob.hasTag("player") || blob.hasTag("projectile")) && !blob.hasTag("parachute"));
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob){return false;}
bool canBePickedUp(CBlob@ this, CBlob@ byBlob){return false;}

void DumpOutItems(CBlob@ this, float pop_out_speed = 5.0f)
{
	// get inventory
	CInventory@ inv = this.getInventory();
	if (inv is null) return;

	// play sound
	if (isClient()){
		if (inv.getItemsCount() > 0) this.getSprite().PlaySound("give.ogg");
	}

	// do actual math here
	if (isServer())
	{
		// loop over every item , i have a trauma when using while loop so i use for loops
		for(u8 i = 0; i < inv.getItemsCount(); i++)
		{
			// get item
			CBlob@ item = inv.getItem(i);
			if (item is null) continue;

			// put them out
			this.server_PutOutInventory(item);
			float magnitude = (1 - XORRandom(3) * 0.25) * pop_out_speed;
			item.setVelocity(this.getOldVelocity() + getRandomVelocity(90, magnitude, 45));
		}
	}
}

void onDie(CBlob@ this)
{
	HideParachute(this);
	ResetRestockerTimer(this);
	DumpOutItems(this);

	this.getSprite().Gib();
	Vec2f pos = this.getPosition();
	Vec2f vel = this.getVelocity();

	// NO WAY !!??!! custom gibs
	string fname = CFileMatcher("/Crate.png").getFirst();
	for (int i = 0; i < 4; i++)
	{
		CParticle@ temp = makeGibParticle(fname, pos, vel + getRandomVelocity(90, 1 , 120), 9, 2 + i, Vec2f(16, 16), 2.0f, 20, "Sounds/material_drop.ogg", 0);
	}
}