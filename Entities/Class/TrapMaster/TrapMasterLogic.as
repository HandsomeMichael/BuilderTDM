// Builder logic

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
#include "KnockedCommon.as";
#include "ClassCommon.as";

//can't be <2 - needs one frame less for gathering infos
//const s32 hit_frame = 2;

void onInit(CBlob@ this)
{
	this.set_f32("pickaxe_distance", 10.0f);
	this.set_f32("gib health", -1.5f);
	this.set_f32("hitdamage",0.125f); // low hit damage
	this.set_u8("exhaustedPoint",0); // base stamina

	this.Tag("player");
	this.Tag("flesh");

	HitData hitdata;
	this.set("hitdata", hitdata);

	this.addCommandID("pickaxe");
	this.addCommandID("hitdata sync");

	CShape@ shape = this.getShape();
	shape.SetRotationsAllowed(false);
	shape.getConsts().net_threshold_multiplier = 0.5f;

	this.set_Vec2f("inventory offset", Vec2f(0.0f, 160.0f));

	SetHelp(this, "help self action2", "builder", getTranslatedString("$Pick$Dig/Chop  $KEY_HOLD$$RMB$"), "", 3);

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null)
	{
		player.SetScoreboardVars("ScoreboardIcons.png", 5, Vec2f(16, 16));
	}
}

void onTick(CBlob@ this)
{
	RegenerateExhaustedPoint(this);
	EditMovement(this);
	RotateBodyByVelocity(this);

	if (this.isInInventory())
		return;

	const bool ismyplayer = this.isMyPlayer();

	if (ismyplayer && getHUD().hasMenus())
	{
		return;
	}

	// activate/throw
	if (ismyplayer)
	{
		Pickaxe(this);

		if (this.isKeyJustPressed(key_action3))
		{
			CBlob@ carried = this.getCarriedBlob();
			if (carried is null || !carried.hasTag("temp blob"))
			{
				client_SendThrowOrActivateCommand(this);
			}
		}
	}

	if (ismyplayer && this.isKeyPressed(key_action1) && !this.isKeyPressed(key_inventory)) //Don't let the builder place blocks if he/she is selecting which one to place
	{
		BlockCursor @bc;
		this.get("blockCursor", @bc);

		HitData@ hitdata;
		this.get("hitdata", @hitdata);
		hitdata.blobID = 0;
		hitdata.tilepos = bc.buildable ? bc.tileAimPos : Vec2f(-8, -8);
	}

	// get rid of the built item
	if (this.isKeyJustPressed(key_inventory) || this.isKeyJustPressed(key_pickup))
	{
		this.set_u8("buildblob", 255);
		this.set_TileType("buildtile", 0);

		CBlob@ blob = this.getCarriedBlob();
		if (blob !is null && blob.hasTag("temp blob"))
		{
			blob.Untag("temp blob");
			blob.server_Die();
		}
	}

	HandleArmor(this);
}

void RegenerateExhaustedPoint(CBlob@ this) 
{
	if (getGameTime() >= this.get_u32("exhaustedRestoreTime")) 
	{
		int exp = this.get_u8("exhaustedPoint");
		int regen = 1;

		if (this.isInWater()) {regen += 1;}
		if (this.isOnGround()) {regen += 1;}
		if (this.getVelocity().getLengthSquared() < 5.0f) {regen += 1;}

		if ((exp - regen) >= 0) 
		{
			if (isClient() && getGameTime() % 5 == 0) {
				f32 randomness = (XORRandom(32) + 32) * 0.015625f * 0.5f + 0.75f;
				Vec2f vel = getRandomVelocity(-90, 3.0f * randomness, 360.0f);
				makeSteamParticle(this, vel);
			}

			this.set_u8("exhaustedPoint",exp - regen);
		}
		else {
			this.set_u8("exhaustedPoint",0);
		}

		this.Sync("exhaustedPoint", true);
	}

	float expf32 = this.get_u8("exhaustedPoint");

	Animation@ animation_strike = this.getSprite().getAnimation("strike");
	if (animation_strike !is null) animation_strike.time = ((expf32 > 40) ? 1 : ((expf32 > 20) ? 2 : 3));

	this.set_f32("hitdamage",0.125f + (expf32 / 255.0f) + (IsThisWoman(this) ? 0 : 0.15f)); // hit damage is based on exhaust point
	this.Sync("hitdamage", true);
}

// woman
bool IsThisWoman(CBlob@ this) {

	CPlayer@ player = this.getPlayer();
	if (player !is null) {
		return (player.getSex() == 1); 
	}

	return false;
}

void AddExhausePoint(CBlob@ this,int point,int restoreTime = 60) {
	
	u8 exp = this.get_u8("exhaustedPoint");

	// destroy muscles if too exhausted
	if ((exp + point) >= 255) 
	{
		if (isKnockable(this))
		{
			setKnocked(this, 60);
			this.getSprite().PlaySound("/Stun.ogg");
		}

		makeSteamPuff(this);

		this.server_Hit(this, this.getPosition(), Vec2f_zero, 0.25f, Hitters::builder, true);
		this.set_u32("exhaustedRestoreTime",0); // automaticly restore so you cant die from this
	}
	// add exhausted point
	else 
	{
		this.set_u8("exhaustedPoint",exp + point);
		// less restore time when exhausted point is bigger
		this.set_u32("exhaustedRestoreTime",getGameTime() + ((exp > 125) ? (restoreTime / 2) : restoreTime)); 
	}
}

void makeSteamParticle(CBlob@ this, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;

	const f32 rad = this.getRadius();
	Vec2f random = Vec2f(XORRandom(128) - 64, XORRandom(128) - 64) * 0.015625f * rad;
	ParticleAnimated(filename, this.getPosition() + random, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
}
void makeSteamPuff(CBlob@ this, const int smallparticles = 10)
{
	const f32 velocity = this.getOldVelocity().getLength();
	this.getSprite().PlaySound("/Steam.ogg");
	makeSteamParticle(this, Vec2f(), "MediumSteam");

	for (int i = 0; i < smallparticles; i++)
	{
		f32 randomness = (XORRandom(32) + 32) * 0.015625f * 0.5f + 0.75f;
		Vec2f vel = getRandomVelocity(-90, velocity * randomness, 360.0f);
		makeSteamParticle(this, vel);
	}
}

void EditMovement(CBlob@ this) {
	// funky
	RunnerMoveVars@ moveVars;
	if (this.get("moveVars", @moveVars))
	{
		// the fastest class
		moveVars.walkFactor = 1.1f;
		if (!this.isOnGround()) {
			// fastest on water and on air
			moveVars.walkFactor = 1.5f + (IsThisWoman(this) ? 0 : 0.1f);
		}

		// reduce speed if you are overheating
		const f32 exp = this.get_u8("exhaustedPoint");
		moveVars.walkFactor -= (exp / 255.0f);

		if (this.isKeyPressed(key_action2)) 
		{
			// very slow
			moveVars.walkFactor = 0.2f;
			moveVars.jumpFactor = 0.5f;

			// increase it on that one tick
			if (this.isOnGround())  {
				if (this.getSprite().isFrameIndex(hit_frame)) {
					moveVars.walkFactor = 2.0f;
					AddExhausePoint(this,2);
				}
			}
			this.Tag("prevent crouch");
		}
	}
}

bool RecdHitCommand(CBlob@ this, CBitStream@ params)
{
	u16 blobID;
	Vec2f tilepos, attackVel;
	f32 attack_power;

	if (!params.saferead_netid(blobID))
		return false;
	if (!params.saferead_Vec2f(tilepos))
		return false;
	if (!params.saferead_Vec2f(attackVel))
		return false;
	if (!params.saferead_f32(attack_power))
		return false;

	if (blobID == 0)
	{
		CMap@ map = getMap();
		if (map !is null)
		{
			uint16 type = map.getTile(tilepos).type;
			if (!inNoBuildZone(map, tilepos, type))
			{
				CBlob@[] blobs_here;
				map.getBlobsAtPosition(tilepos + Vec2f(1, 1), blobs_here);

				bool no_dmg = false;

				// dont dmg backwall if it's behind a blob-block
				// hack: fixes the issue where with specific timing you can damage backwall behind blob-blocks right after placing it
				for(int i=0; i < blobs_here.size(); ++i)
				{
					CBlob@ current_blob = blobs_here[i];
					if (current_blob !is null && (current_blob.hasTag("door") || current_blob.getName() == "bridge" || current_blob.getName() == "wooden_platform"))
					{
						no_dmg = true;
					}
				}

				if (!no_dmg)
				{
					if (getNet().isServer())
					{
						if (this.get_u8("exhaustedPoint") > 150) {
							map.server_DestroyTile(tilepos, 1.0f, this);
						}

						map.server_DestroyTile(tilepos, 1.0f, this);
						Material::fromTile(this, type, 0.5f);

						AddExhausePoint(this,5);
					}

					if (getNet().isClient())
					{
						if (map.isTileBedrock(type))
						{
							this.getSprite().PlaySound("/metal_stone.ogg");
							sparks(tilepos, attackVel.Angle(), 1.0f);
						}
					}
				}
			}
		}
	}
	else
	{
		// blob
		CBlob@ blob = getBlobByNetworkID(blobID);
		if (blob !is null)
		{
			bool isdead = blob.hasTag("dead");

			// cant kill a death body
			if (isdead) {
				attack_power *= 0.5f;
			}

			// instakill any trap kind blob
			if (blob.getName() == "spikes" || blob.getName() == "trap_block" ||
			 blob.getName() == "bridge" || blob.getName() == "wooden_platform") {
				attack_power = 10.0f;
			}

			const bool teamHurt = !blob.hasTag("flesh") || isdead;

			if (getNet().isServer())
			{
				this.server_Hit(blob, tilepos, attackVel, attack_power, Hitters::builder, teamHurt);
				Material::fromBlob(this, blob, attack_power);
				AddExhausePoint(this,4);
			}
		}
	}

	return true;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("pickaxe"))
	{
		if (!RecdHitCommand(this, params))
		{
			warn("error when recieving pickaxe command");
		}
	}
	else if (cmd == this.getCommandID("hitdata sync") && !this.isMyPlayer())
	{
		HitData@ hitdata;
		this.get("hitdata", @hitdata);

		hitdata.tilepos = params.read_Vec2f();
		hitdata.blobID = params.read_netid();
	}
	
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	TempBlob_onDetach(this,detached,attachedPoint);
}

void onAddToInventory(CBlob@ this, CBlob@ blob) 
{
	TempBlob_onAddToInventory(this,blob);
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData ) {

	// immortal
	float expf32 = this.get_u8("exhaustedPoint");
	f32 dmg = damage * (1.0f - (expf32 / 255.0f));

	// make em farting
	if (customData == Hitters::fire)
	{
		AddExhausePoint(this,20);
		makeSteamPuff(this);
	}

	// weak against water
	if (customData == Hitters::water)
	{
		this.set_u32("exhaustedRestoreTime",0);
		makeSteamPuff(this);
	}
	
	return ArmorBlockDamage(this,dmg);
}