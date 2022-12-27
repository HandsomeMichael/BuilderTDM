#include "VehicleCommon.as"
#include "VehicleAttachmentCommon.as"
#include "GenericButtonCommon.as"
// Boat logic

void WheelBoat_Setup(CBlob@ this) 
{
	this.addCommandID("add wheel");
	this.addCommandID("flip_hard");
	this.addCommandID("leash_em");
}
void WheelBoat_HandleCommand(CBlob@ this, u8 cmd, CBitStream@ params) {
	if (cmd == this.getCommandID("add wheel") && !this.get_bool("addedwheel"))
	{
		CBlob@ carried = getBlobByNetworkID(params.read_netid());
		if (carried is null) return;

		if (carried.getName() == "woodwheel"){

			VehicleInfo@ v;
			if (!this.get("VehicleInfo", @v)){return;}

			if (isServer()) {
				carried.server_Die();
			}

			Vehicle_addWheel(this, v, "WoodenWheels.png", 16, 16, 1, Vec2f(-10.0f, 11.0f));
			Vehicle_addWheel(this, v, "WoodenWheels.png", 16, 16, 0, Vec2f(8.0f, 10.0f));

			this.set_bool("addedwheel",true);

			this.getSprite().PlaySound("/Construct.ogg");
		}

	}
	if (cmd == this.getCommandID("flip_hard"))
	{
		// flip em
		this.getShape().SetStatic(false);
		this.getShape().doTickScripts = true;
		f32 angle = this.getAngleDegrees();
		this.AddTorque(angle < 180 ? -7000 : 7000);
		this.AddForce(Vec2f(0, -7000));
	}
	if (cmd == this.getCommandID("leash_em")) 
	{
		CBlob@ carried = getBlobByNetworkID(params.read_netid());
		if (carried is null) return;

		if (carried.getName() == "leash")
		{
			// unleash if the id is same
			if (this.getNetworkID() == carried.get_netid("leashID")) {carried.set_netid("leashID",0);}
			else {
				carried.set_netid("leashID",this.getNetworkID());
				print("netID = "+this.getNetworkID() + " / "+carried.get_u32("leashID"));
			}

			if (isClient()) {
				carried.getSprite().PlaySound("EquipSomething.ogg");
			}
		}
	}
}
void WheelBoat_GetButtons(CBlob@ this, CBlob@ caller) 
{
	CBlob@ carried = caller.getCarriedBlob();
	if (carried !is null) {
		if (carried.getName() == "woodwheel" && !this.get_bool("addedwheel")) {
			CBitStream params;
			params.write_u16(carried.getNetworkID());
			caller.CreateGenericButton(15, Vec2f(0, 20), this, this.getCommandID("add wheel"), getTranslatedString("Add Wheel"), params);
		}
		if (carried.getName() == "vehicleflipper") {
			caller.CreateGenericButton("$vehicleflipper$", Vec2f(10, 0), this, this.getCommandID("flip_hard"), getTranslatedString("Flip Vehicle"));
		}
		if (carried.getName() == "leash") {
			CBitStream params;
			params.write_u16(carried.getNetworkID());
			caller.CreateGenericButton("$leash$", Vec2f(10, 10), this, this.getCommandID("leash_em"), getTranslatedString("Leash / Unleash"),params);
		}
	}
}

void WheelBoat_StandardControls(CBlob@ this, VehicleInfo@ v)
{
	v.move_direction = 0;
	AttachmentPoint@[] aps;
	if (this.getAttachmentPoints(@aps))
	{
		for (uint i = 0; i < aps.length; i++)
		{
			AttachmentPoint@ ap = aps[i];
			CBlob@ blob = ap.getOccupied();

			if (blob !is null && ap.socket)
			{
				// GET OUT
				if (blob.isMyPlayer() && ap.isKeyJustPressed(key_up))
				{
					CBitStream params;
					params.write_u16(blob.getNetworkID());
					this.SendCommand(this.getCommandID("vehicle getout"), params);
					return;
				} // get out

				// DRIVER
				bool hasWheel = this.get_bool("addedwheel");

				// act as driver if it has wheel and at ground
				if ((ap.name == "DRIVER" && !this.hasTag("immobile")) || (ap.name == "ROWER" && hasWheel && !this.isInWater()))
				{
					bool moveUp = false;
					const f32 angle = this.getAngleDegrees();
					// set facing
					blob.SetFacingLeft(this.isFacingLeft());
					const bool left = ap.isKeyPressed(key_left);
					const bool right = ap.isKeyPressed(key_right);
					const bool onground = this.isOnGround();
					const bool onwall = this.isOnWall();

					// left / right
					if (angle < 80 || angle > 290)
					{
						f32 moveForce = v.move_speed;
						f32 turnSpeed = v.turn_speed;

						Vec2f groundNormal = this.getGroundNormal();
						Vec2f vel = this.getVelocity();
						Vec2f force;

						// more force when starting
						if (this.getShape().vellen < 0.1f)
						{
							moveForce *= 10.0f;
						}

						// more force on boat
						if (!this.isOnMap() && this.isOnGround())
						{
							moveForce *= 1.5f;
						}

						bool slopeangle = (angle > 15 && angle < 345 && this.isOnMap());

						Vec2f pos = this.getPosition();

						if (left)
						{
							// Put more force on slope
							if (onground && groundNormal.y < -0.4f && groundNormal.x > 0.05f && vel.x < 1.0f && slopeangle)
							{
								// normally this putted at 6.0f , but it will be wacky if i keep that
								if (hasWheel) {
									force.x -= 1.5f * moveForce;
								}
								else {force.x -= 6.0f * moveForce;}
							}
							else{force.x -= moveForce;}

							if (vel.x < -turnSpeed)
							{
								this.SetFacingLeft(true);
							}

							if (onwall)
							{
								moveUp = true;
							}
						}

						if (right)
						{
							if (onground && groundNormal.y < -0.4f && groundNormal.x < -0.05f && vel.x > -1.0f && slopeangle)   // put more force when going up
							{
								if (hasWheel) {
									force.x += 1.5f * moveForce;
								}
								else {force.x += 6.0f * moveForce;}
							}
							else
							{
								force.x += moveForce;
							}

							if (vel.x > turnSpeed)
							{
								this.SetFacingLeft(false);
							}

							if (onwall)
								moveUp = true;
						}

						force.RotateBy(this.getShape().getAngleDegrees());

						if ((onwall /*|| (angle < 351 && angle > 9)*/) && (right || left))
						{
							Vec2f end;
							Vec2f forceoffset((this.isFacingLeft() ? this.getRadius() : -this.getRadius()) * 0.5f, 0.0f);
							Vec2f forcepos = pos + forceoffset;
							bool rearHasGround = this.getMap().rayCastSolid(pos, forcepos + Vec2f(0.0f, this.getMap().tilesize * 3.0f), end);
							if (rearHasGround)
							{
								this.AddForceAtPosition(Vec2f(0.0f, -290.0f), pos + Vec2f(-forceoffset.x, forceoffset.y) * 0.2f);
							}
						}

						this.AddForce(force);
					}
					else if (left || right)
					{
						moveUp = true;
					}

					// climb uphills

					const bool down = ap.isKeyPressed(key_down) || ap.isKeyPressed(key_action3);
					if (onground && (down || moveUp))
					{
						const bool faceleft = this.isFacingLeft();
						if (angle > 330 || angle < 30)
						{
							f32 wallMultiplier = (this.isOnWall() && (angle > 350 || angle < 10)) ? 1.5f : 1.0f;
							f32 torque = 150.0f * wallMultiplier;
							if (down)
								this.AddTorque(faceleft ? torque : -torque);
							else
								this.AddTorque(((faceleft && left) || (!faceleft && right)) ? torque : -torque);
							this.AddForce(Vec2f(0.0f, -200.0f * wallMultiplier));
						}

						if (isFlipped(this))
						{
							f32 angle = this.getAngleDegrees();
							if (!left && !right)
								this.AddTorque(angle < 180 ? -500 : 500);
							else
								this.AddTorque(((faceleft && left) || (!faceleft && right)) ? 500 : -500);
							this.AddForce(Vec2f(0, -400));
						}
					}
				}  // driver

				// ROWER
				if ((ap.name == "ROWER" && this.isInWater()) || (ap.name == "SAIL" && !this.hasTag("no sail")))
				{
					const f32 moveForce = v.move_speed;
					const f32 turnSpeed = v.turn_speed;
					Vec2f force;
					bool moving = false;
					const bool left = ap.isKeyPressed(key_left);
					const bool right = ap.isKeyPressed(key_right);
					const Vec2f vel = this.getVelocity();

					bool backwards = false;

					// row left/right

					if (left)
					{
						force.x -= moveForce;

						if (vel.x < -turnSpeed)
						{
							this.SetFacingLeft(true);
						}
						else
						{
							backwards = true;
						}

						moving = true;
					}

					if (right)
					{
						force.x += moveForce;

						if (vel.x > turnSpeed)
						{
							this.SetFacingLeft(false);
						}
						else
						{
							backwards = true;
						}

						moving = true;
					}

					if (moving)
					{
						this.AddForce(force);
					}
				} // flyer
			}  // ap.occupied
		}   // for
	}

}


