// Builder animations

#include "BuilderCommon.as"
#include "FireCommon.as"
#include "Requirements.as"
#include "RunnerAnimCommon.as"
#include "RunnerCommon.as"
#include "KnockedCommon.as"
#include "PixelOffsets.as"
#include "RunnerTextures.as"
#include "Accolades.as"


//

void onInit(CSprite@ this)
{
	LoadSprites(this);

	this.getCurrentScript().runFlags |= Script::tick_not_infire;
}

void onPlayerInfoChanged(CSprite@ this)
{
	LoadSprites(this);
}

void LoadSprites(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob !is null)
	{
		CPlayer@ player = this.getBlob().getPlayer();
		if (player !is null) {

			if (player.getUsername() == "Atheon" || player.getUsername() == "TFlippy" || player.getUsername() == "Guift" || player.getUsername() == "SkinnyBoy") 
			{
				ensureCorrectRunnerTexture(this, "trapmaster_skinny", "Stikmen");
				return;
			}
		}
	}

	ensureCorrectRunnerTexture(this, "trapmaster", "TrapMaster");

}

void onTick(CSprite@ this)
{
	// store some vars for ease and speed
	CBlob@ blob = this.getBlob();

	if (blob.hasTag("dead"))
	{
		this.SetAnimation("dead");
		Vec2f vel = blob.getVelocity();

		if (vel.y < -1.0f)
		{
			this.SetFrameIndex(0);
		}
		else if (vel.y > 1.0f)
		{
			this.SetFrameIndex(2);
		}
		else
		{
			this.SetFrameIndex(1);
		}
		return;
	}
	// animations

	bool knocked = isKnocked(blob);
	const bool action2 = blob.isKeyPressed(key_action2);
	const bool action1 = blob.isKeyPressed(key_action1);

	if (!blob.hasTag(burning_tag)) //give way to burning anim
	{
		const bool left = blob.isKeyPressed(key_left);
		const bool right = blob.isKeyPressed(key_right);
		const bool up = blob.isKeyPressed(key_up);
		const bool down = blob.isKeyPressed(key_down);
		const bool inair = (!blob.isOnGround() && !blob.isOnLadder());
		Vec2f pos = blob.getPosition();

		RunnerMoveVars@ moveVars;
		if (!blob.get("moveVars", @moveVars))
		{
			return;
		}

		if (knocked)
		{
			if (inair)
			{
				this.SetAnimation("knocked_air");
			}
			else
			{
				this.SetAnimation("knocked");
			}
		}
		else if (blob.hasTag("seated"))
		{
			this.SetAnimation("crouch");
		}
		else if (action2 || (this.isAnimation("strike")  && !this.isAnimationEnded()))
		{
			// same animation
			this.SetAnimation("strike");
		}
		else if (action1  || (this.isAnimation("build") && !this.isAnimationEnded()))
		{
			this.SetAnimation("build");
		}
		else if (inair)
		{
			RunnerMoveVars@ moveVars;
			if (!blob.get("moveVars", @moveVars))
			{
				return;
			}
			Vec2f vel = blob.getVelocity();
			f32 vy = vel.y;
			if (vy < -0.0f && moveVars.walljumped)
			{
				this.SetAnimation("run");
			}
			else
			{
				this.SetAnimation("fall");
				this.animation.timer = 0;
				bool inwater = blob.isInWater();

				if (vy < -1.5 * (inwater ? 0.7 : 1))
				{
					this.animation.frame = 0;
				}
				else if (vy > 1.5 * (inwater ? 0.7 : 1))
				{
					this.animation.frame = 2;
				}
				else
				{
					this.animation.frame = 1;
				}
			}
		}
		else if ((left || right) ||
		         (blob.isOnLadder() && (up || down)))
		{
			this.SetAnimation("run");
		}
		else
		{
			// get the angle of aiming with mouse
			Vec2f aimpos = blob.getAimPos();
			Vec2f vec = aimpos - pos;
			f32 angle = vec.Angle();
			int direction;

			if ((angle > 330 && angle < 361) || (angle > -1 && angle < 30) ||
			        (angle > 150 && angle < 210))
			{
				direction = 0;
			}
			else if (aimpos.y < pos.y)
			{
				direction = -1;
			}
			else
			{
				direction = 1;
			}

			defaultIdleAnim(this, blob, direction);
		}
	}

	//set the attack head

	if (knocked)
	{
		blob.Tag("dead head");
	}
	else if (action2 || blob.isInFlames())
	{
		blob.Tag("attack head");
		blob.Untag("dead head");
	}
	else
	{
		blob.Untag("attack head");
		blob.Untag("dead head");
	}
}

void DrawCursorAt(Vec2f position, string& in filename)
{
	position = getMap().getAlignedWorldPos(position);
	if (position == Vec2f_zero) return;
	position = getDriver().getScreenPosFromWorldPos(position - Vec2f(1, 1));
	GUI::DrawIcon(filename, position, getCamera().targetDistance * getDriver().getResolutionScaleFactor());
}

// render cursors

const string cursorTexture = "Entities/Characters/Sprites/TileCursor.png";

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (!blob.isMyPlayer())
	{
		return;
	}
	if (getHUD().hasButtons())
	{
		return;
	}

	// draw tile cursor

	if (blob.isKeyPressed(key_action1) || this.isAnimation("strike") || this.isAnimation("chop"))
	{
		HitData@ hitdata;
		blob.get("hitdata", @hitdata);
		CBlob@ hitBlob = hitdata.blobID > 0 ? getBlobByNetworkID(hitdata.blobID) : null;

		if (hitBlob !is null) // blob hit
		{
			if (!hitBlob.hasTag("flesh"))
			{
				hitBlob.RenderForHUD(RenderStyle::outline);

				// hacky fix for shitty z-buffer issue
				// the sprite layers go out of order while hitting with this fix,
				// but its better than the entire blob glowing brighter than the sun
				if (v_postprocess)
				{
					hitBlob.RenderForHUD(RenderStyle::normal);
				}
			}
		}
		else// map hit
		{
			DrawCursorAt(hitdata.tilepos, cursorTexture);
		}
	}

	// check blob
	if (blob is null) return;
	if (blob.hasTag("dead")) return;
	// make head facing cursor

	// get mouse angle
	Vec2f aim_vec = (blob.getPosition() - blob.getAimPos());
	aim_vec.Normalize();
	f32 mouseAngle = aim_vec.getAngleDegrees();
	if (!blob.isFacingLeft()) mouseAngle += 180;
	//print("head angle : "+mouseAngle+" deg");
	// rotate head
	CSpriteLayer@ head = this.getSpriteLayer("head");
	if (head !is null) {
		head.ResetTransform();
		head.RotateByDegrees(-mouseAngle,Vec2f(0,4));
	}

	// it would be funny if instead of rotating sprite. we rotate the blob :troll:

	// f32 xFactor =  (Maths::Clamp(blob.getVelocity().x, -50.0f, 50.0f) / 50.0f) * 10.0f;
	// this.ResetTransform();
	// this.RotateAllByDegrees(xFactor,Vec2f_zero);
}

void onGib(CSprite@ this)
{
	if (g_kidssafe)
	{
		return;
	}

	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0;
	const u8 team = blob.getTeamNum();
	CParticle@ Body     = makeGibParticle("Entities/Characters/Builder/BuilderGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 0, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Arm1     = makeGibParticle("Entities/Characters/Builder/BuilderGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Arm2     = makeGibParticle("Entities/Characters/Builder/BuilderGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Shield   = makeGibParticle("Entities/Characters/Builder/BuilderGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 2, 0, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
	CParticle@ Sword    = makeGibParticle("Entities/Characters/Builder/BuilderGibs.png", pos, vel + getRandomVelocity(90, hp + 1 , 80), 3, 0, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
}
