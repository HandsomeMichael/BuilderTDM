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
#include "ClassCommon.as";

//can't be <2 - needs one frame less for gathering infos
//const s32 hit_frame = 2;

void onInit(CBlob@ this)
{
	this.set_f32("pickaxe_distance", 10.0f);
	this.set_f32("gib health", -1.5f);
	this.set_f32("hitdamage",0.5f);

	this.Tag("player");
	this.Tag("flesh");

	HitData hitdata;
	this.set("hitdata", hitdata);

	this.addCommandID("pickaxe");
	this.addCommandID("hitdata sync");
	this.addCommandID("setarmor");

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
		player.SetScoreboardVars("ScoreboardIcons.png", 1, Vec2f(16, 16));
	}
}

void onTick(CBlob@ this)
{
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

	if (this.isKeyPressed(key_action2))
	{
		RunnerMoveVars@ moveVars;
		if (this.get("moveVars", @moveVars))
		{
			// increase it on that one tick
			if (this.getSprite().isFrameIndex(hit_frame)) {
				moveVars.walkFactor = 2.0f;
			}
			else {
				moveVars.walkFactor = 0.8f;
			}
			moveVars.jumpFactor = 0.5f;
		}
		this.Tag("prevent crouch");
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

	// handle armor
	HandleArmor(this);
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
						map.server_DestroyTile(tilepos, 1.0f, this);
						// replaced with more mats
						getMaterialFromTile(this, type, 1.0f);
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

			if (isdead) //double damage to corpses
			{
				attack_power *= 2.0f;
			}

			const bool teamHurt = !blob.hasTag("flesh") || isdead;

			if (getNet().isServer())
			{
				this.server_Hit(blob, tilepos, attackVel, attack_power, Hitters::builder, teamHurt);

				Material::fromBlob(this, blob, attack_power);
			}
		}
	}

	return true;
}

void getMaterialFromTile(CBlob@ this, uint16 &in type, float &in damage)
{
	if (damage <= 0.f) return;

	CMap@ map = getMap();

	// Only solid tiles yield materials
	if (not map.isTileSolid(type)) return;

	if (map.isTileThickStone(type))
	{
		Material::createFor(this, 'mat_stone', 9.f * damage);
	}
	else if (map.isTileStone(type))
	{
		Material::createFor(this, 'mat_stone', 6.f * damage);
	}
	else if (map.isTileCastle(type))
	{
		Material::createFor(this, 'mat_stone', damage);
	}
	else if (map.isTileWood(type))
	{
		Material::createFor(this, 'mat_wood', damage);
	}
	else if (map.isTileGold(type))
	{
		Material::createFor(this, 'mat_gold', 5.f * damage);
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
	return ArmorBlockDamage(this,damage);
}