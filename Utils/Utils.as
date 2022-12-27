// random ass math method or something
namespace Utils
{
	// from unity idk
	float AngleRepeat(float t,float m) {
		return Maths::Clamp(t - Maths::Floor( t / m ) * m , 0 , m);
	}
	float LerpAngleDegree(float start,float end, float value) {
		const float distance = AngleRepeat(end - start,360);
		return Maths::Lerp(start,start + (distance > 180 ? distance - 360 : distance ) , value);
	}

	// usefull stuff
	// honestly idk how does this "@" thing works

	u16 GetRealDamageOwnerID(CBlob@ hitterBlob) {
		return hitterBlob.hasTag("player") ? hitterBlob.getNetworkID() : 
				(hitterBlob.getDamageOwnerPlayer() !is null && hitterBlob.getDamageOwnerPlayer().getBlob() !is null) ?
				hitterBlob.getDamageOwnerPlayer().getBlob().getNetworkID() : 0;
	}

	void AutoFacing(CBlob@ this,bool keyPressBased = true) {

		f32 x = this.getVelocity().x;
		if (Maths::Abs(x) > 1.0f)
		{
			this.SetFacingLeft(x < 0);
		}
		else if (keyPressBased)
		{
			if (this.isKeyPressed(key_left))this.SetFacingLeft(true);
			if (this.isKeyPressed(key_right))this.SetFacingLeft(false);
		}
	}

	CBlob@ GetHolder(CBlob@ this) {
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		if (point is null) {return null;}
		CBlob@ holder = point.getOccupied();
		return holder;
	}
	Vec2f DirectionTo(CBlob@ this , CBlob@ target) {
		Vec2f dir = (target.getPosition() - this.getPosition());
		dir.Normalize();
		return dir;
	}
	Vec2f DirectionTo(Vec2f start , Vec2f target) {
		Vec2f dir = (target - start);
		dir.Normalize();
		return dir;
	}
}


