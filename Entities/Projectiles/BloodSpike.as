
#include "Hitters.as";
#include "Knocked.as"

//blob functions
void onInit( CBlob@ this )
{
    CShape@ shape = this.getShape();
	shape.SetGravityScale(0.0f);

	ShapeConsts@ consts = shape.getConsts();
    consts.mapCollisions = false;	 // no map collison
	consts.bullet = true;
	consts.net_threshold_multiplier = 4.0f;

	this.server_SetTimeToDie( 0.5f );
	this.Tag("projectile");
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1 )
{
    if (blob !is null && doesCollideWithBlob( this, blob ) && !this.hasTag("collided"))
    {
		if (!solid && !blob.hasTag("flesh") && !blob.hasTag("boss")) return;
		this.server_Hit( blob, point1, normal, 1.0f, Hitters::spikes);
	}
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
	return blob.hasTag("flesh") && !blob.hasTag("invincible") && !blob.hasTag("boss");
}


void onTick( CBlob@ this )
{
    f32 angle = (this.getVelocity()).Angle();
    this.setAngleDegrees(-angle);
}

f32 HitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{
    if (hitBlob !is null)this.server_Die();
	return damage;
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{
	// affect players velocity
	f32 force = 1.5f * Maths::Sqrt(hitBlob.getMass()+1);
	hitBlob.AddForce( velocity * force );
	hitBlob.getSprite().PlaySound("/SpikesCut.ogg");
}
