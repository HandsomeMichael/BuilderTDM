#include "Hitters.as";
#include "ParticleSparks.as";

void onInit(CBlob@ this)
{
	this.set_bool("active", false);

	this.Tag("ignore fall");
	this.Tag("heavy weight");
	
	this.addCommandID("activate");

	this.getShape().SetRotationsAllowed(false);

	this.getCurrentScript().tickFrequency = 15;
}

void onInit(CSprite@ this)
{
	this.SetEmitSound("Drill.ogg");
	this.SetEmitSoundVolume(1.0f);
	this.SetEmitSoundSpeed(0.7f);
	
	this.SetEmitSoundPaused(!this.getBlob().get_bool("active"));
}


void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("activate"))
	{
		bool state = params.read_bool();
		this.set_bool("active", state);
		
		this.getSprite().PlaySound("/LeverToggle.ogg");
		this.getSprite().SetAnimation(state ? "active" : "default");
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller is null) return;

	CBlob@ carried = caller.getCarriedBlob();
	if (carried !is null) {
		if (carried.getNetworkID() == this.getNetworkID()) {
			return;
		}
	}

	if (caller.getTeamNum() == this.getTeamNum())
	{
		if (this.getMap().rayCastSolid(caller.getPosition(), this.getPosition())) return;
		
		bool active = this.get_bool("active");
		
		CBitStream params;
		params.write_bool(!active);

		if (active) 
		{
			CButton@ button = caller.CreateGenericButton(9, Vec2f(0, 0), this, this.getCommandID("activate"), "Stop", params);
		}
		else 
		{
			CButton@ button = caller.CreateGenericButton("$drill$", Vec2f(0, 0), this, this.getCommandID("activate"), "Drill Em !", params);
		}
	}
}


void onTick(CBlob@ this)
{
	if (!this.get_bool("active")) return;

	DrillEm(this);

	//this.getSprite().PlaySound("/Drill.ogg");
}


void DrillEm(CBlob@ this) {

	Vec2f attackVel = Vec2f(0, 6.0f);
	const f32 distance = 20.0f;

	CMap@ map = getMap();
	if (map !is null)
	{
		HitInfo@[] hitInfos;
		if (map.getHitInfosFromArc((this.getPosition()), -attackVel.Angle(), 80, distance, this, true, @hitInfos))
		{
			for (uint i = 0; i < hitInfos.length; i++)
			{
				HitInfo@ hi = hitInfos[i];

				if (map.getSectorAtPosition(hi.hitpos, "no build") !is null)continue;

				TileType tile = hi.tile;

				if (isServer())
				{
					for (uint i = 0; i < 2; i++)
					{
						//tile destroyed last hit

						if (!map.isTileSolid(map.getTile(hi.tileOffset))){ break; }

						map.server_DestroyTile(hi.hitpos, 1.0f, this);

					}

				}

				if (isClient())
				{
					if (map.isTileBedrock(tile))
					{
						this.getSprite().PlaySound("metal_stone.ogg");
						sparks(hi.hitpos, attackVel.Angle(), 1.0f);
					}
				}
			}
		}
	}

}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob){return false;}
bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob){return false;}
bool canBePickedUp(CBlob@ this, CBlob@ byBlob){return !this.get_bool("active") && this.getTeamNum() == byBlob.getTeamNum();}