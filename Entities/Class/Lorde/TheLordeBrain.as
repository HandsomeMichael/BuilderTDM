// Princess brain

#include "BrainCommon.as"

void onInit(CBrain@ this)
{
	if (isServer())
	{
		InitBrain(this);

		this.server_SetActive(true);   // always running
	}

	CBlob @blob = this.getBlob();
	blob.set_f32("gib health", -1.5f);
}

void onTick(CBrain@ this)
{
	// if there is player no morr bren , ded bren
	CPlayer@ player = this.getBlob().getPlayer();
	if (player !is null) return;

	if (isServer())
	{
		SearchTarget(this);

		CBlob @blob = this.getBlob();
		CBlob @target = this.getTarget();

		// logic for target

		this.getCurrentScript().tickFrequency = 29;
		if (target !is null)
		{
			this.getCurrentScript().tickFrequency = 1;
			FlyToTheTargetLol(blob, target);
		}
		else
		{
			RandomTurn(blob);
		}
	}
}

bool FlyToTheTargetLol(CBlob@ blob, CBlob@ target)
{
	Vec2f mypos = blob.getPosition();
	Vec2f point = target.getPosition();
	const f32 horiz_distance = Maths::Abs(point.x - mypos.x);

	if (horiz_distance > blob.getRadius() * 0.75f)
	{
		if (point.x < mypos.x){blob.setKeyPressed(key_left, true);}
		else{blob.setKeyPressed(key_right, true);}
		if (point.y + getMap().tilesize * 0.7f < mypos.y){blob.setKeyPressed(key_up, true);}
		if (point.y > mypos.y){blob.setKeyPressed(key_down, true);}

		return true;
	}

	return false;
}