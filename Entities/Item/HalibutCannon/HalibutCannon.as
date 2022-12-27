// CALAMITY REFERENCE OMG

#include "Hitters.as";
#include "BuilderHittable.as";
#include "ParticleSparks.as";

const u8 heat_max = 600;

void onInit(CBlob@ this)
{
	// required so the builder dont do build animation
	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action1);
	}

	// icon token for heat display
	AddIconToken("$opaque_heatbar$", "Entities/Industry/Drill/HeatBar.png", Vec2f(24, 6), 0);
	AddIconToken("$transparent_heatbar$", "Entities/Industry/Drill/HeatBar.png", Vec2f(24, 6), 1);

	// shoot em
	this.set_u32("shootTime", 0);

	this.set_u16("holderID",0); // current holder network id for heat display
	this.set_u8("heat",0); // za heat

	this.Tag("place norotate"); // required to prevent item from locking in place (blame builder code :kag_angry:)
	this.Tag("ignore fall"); // ignore fall damage. i think.....

	this.addCommandID("shoot bullet"); 
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params ) 
{
	if (cmd == this.getCommandID("shoot bullet"))
    {
        Vec2f pos = params.read_Vec2f();
        Vec2f vel = params.read_Vec2f();

        if (isServer())
        {
			// in the example it just does this , idk why it dont use server_CreateBlob directly
            CBlob@ bullet = server_CreateBlobNoInit( "bullet" );
            if (bullet !is null)
            {
				bullet.Init();
				bullet.IgnoreCollisionWhileOverlapped( this );
                bullet.SetDamageOwnerPlayer( this.getPlayer() );
				bullet.server_setTeamNum( this.getTeamNum() );
				bullet.setPosition( pos );
                bullet.setVelocity( vel );
            }
        }
    }
}

// heat render from drill
void onRender(CSprite@ this)
{
	CPlayer@ local = getLocalPlayer();
	CBlob@ localBlob = local.getBlob();

	if (local is null || localBlob is null)return;

	CBlob@ blob = this.getBlob();
	u16 holderID = blob.get_u16("holderID");

	CPlayer@ holder = holderID == 0 ? null : getPlayerByNetworkId(holderID);
	if (holder is null){return;}

	CBlob@ holderBlob = holder.getBlob();
	if (holderBlob is null){return;}

	if (holder !is null && holder.isLocal())
	{
		int transparency = 255;
		u8 heat = blob.get_u8("heat");
		f32 percentage = Maths::Min(1.0, f32(heat) / f32(heat_max));

		//Vec2f pos = blob.getScreenPos() + Vec2f(-22, 16);

		Vec2f pos = holderBlob.getInterpolatedScreenPos() + (blob.getScreenPos() - holderBlob.getScreenPos()) + Vec2f(-22, 16);
		Vec2f dimension = Vec2f(42, 4);
		Vec2f bar = Vec2f(pos.x + (dimension.x * percentage), pos.y + dimension.y);

		// transparency = Maths::Lerp(168, 255, percentage);

		if (heat > 0){GUI::DrawIconByName("$opaque_heatbar$", pos);}
		else{
			transparency = 168;
			GUI::DrawIconByName("$transparent_heatbar$", pos);
		}

		// kag is weird. 
		// A,R,G,B
		GUI::DrawRectangle(pos + Vec2f(4, 4), bar + Vec2f(4, 4), SColor(transparency, Maths::Lerp(59, 89, percentage), 20, 6));
		GUI::DrawRectangle(pos + Vec2f(6, 6), bar + Vec2f(2, 4), SColor(transparency, Maths::Lerp(148, 168, percentage), 27, 27));
		GUI::DrawRectangle(pos + Vec2f(6, 6), bar + Vec2f(2, 2), SColor(transparency, Maths::Lerp(183, 213, percentage), 51, 51));
	}
}

void onTick(CBlob@ this)
{
	u8 heat = this.get_u8("heat");

	if (this.isAttached())
	{

		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		CBlob@ holder = point.getOccupied();

		if (holder is null || holder.isAttached()) return;

		// send holder id
		if (this.get_u16("holderID") != holder.getNetworkID()) this.set_u16("holderID",holder.getNetworkID());

		Vec2f pos = this.getPosition();
		Vec2f aim_vec = (pos - holder.getAimPos());
		aim_vec.Normalize();

		f32 mouseAngle = aim_vec.getAngleDegrees();
		if (!this.isFacingLeft()) mouseAngle += 180;
		this.setAngleDegrees(-mouseAngle); // set aim pos

		if (point.isKeyPressed(key_action1) && getGameTime() >= this.get_u32("shootTime")) {
			
			this.set_u32("shootTime",getGameTime()+5);
			this.set_u8("heat",heat + 10);

			if (isServer()) {
				for(int i = 0; i < 5; ++i) {
					ShootBullet( this, 
					holder,													// the holder
					pos + Vec2f(0.0f, this.isFacingLeft() ? -4.0f : -1.0f), // position
					holder.getAimPos() + Vec2f(0.0f,-3.0f), 				// aim position
					 20.0f ); 												// speed
				}
			}
			// terrari
			if (isClient()) {
				this.getSprite().PlaySound("TerrariaGun.ogg");
			}

		}
	}
	else {
		if (this.get_u16("holderID") != 0) this.set_u16("holderID",0);
	}
	// cool it down , man
	if (this.get_u32("shootTime") > getGameTime() + 240) {
		if (heat > 0) {
			this.set_u8("heat",heat - 1);
		}
	}
}

void ShootBullet(CBlob @this , CBlob @holder, Vec2f pos, Vec2f aimpos, f32 speed )
{
	// check if holder is client player , null or bot
    if (canSend(holder))
	{ 
		Vec2f velociteh = (aimpos - pos).RotateBy(0.0f,Vec2f(0,0));
		velociteh.Normalize();
		velociteh *= speed;
		CBitStream params;
		params.write_Vec2f( pos );
		params.write_Vec2f( velociteh );

		this.SendCommand( this.getCommandID("shoot bullet"), params );
	}
}

bool canSend( CBlob@ this )
{
	return (this.isMyPlayer() || this.getPlayer() is null || this.getPlayer().isBot());
}