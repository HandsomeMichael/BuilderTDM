
// Basic Fuse system

void Fuse_Setup(CBlob@ this) 
{
	this.addCommandID("fuse_bomb");
}

void Fuse_GetButton(CBlob@ this, CBlob@ caller)
{
	if (this is null) {return;}
	if (caller is null) {return;}

	CBlob@ carried = caller.getCarriedBlob();

	if (this.getMap().rayCastSolid(caller.getPosition(), this.getPosition())) return;

	// light bomb , i think making this a seperate script is better but idk how
	if (carried !is null) {

		string name = carried.getName();

		if (name == "mat_bombs" || name == "mat_waterbombs" || name == "keg") {

			CBitStream params;
			params.write_netid(caller.getNetworkID());

			CButton@ button = caller.CreateGenericButton(
			10,
			Vec2f(0, 0),
			this, 
			this.getCommandID("fuse_bomb"), 
			"Fuse explosive", params);

		}
	}
}

void Fuse_HandleCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("fuse_bomb"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		if (caller is null) return;

		CBlob@ carried = caller.getCarriedBlob();
		if (carried is null) return;

		if (carried.getName() == "mat_bombs")
		{
			CBlob@ blob = server_CreateBlob("bomb", this.getTeamNum(), this.getPosition());
			carried.server_Die();
			caller.server_Pickup(blob);

			if (this.getName() == "fireplace") {
				// make it more dangerous to the enemy and yourself
				blob.set_s32("bomb_timer", getGameTime() + 60);
				blob.set_f32("explosive_radius", 68.0f);
				blob.set_f32("map_damage_radius", 35.0f);
			}

			if (this.getName() == "bombertable") {
				// messes up with people bomb timing , hehehehaw
				blob.set_s32("bomb_timer", getGameTime() + 100);
				blob.set_f32("explosive_radius", 50.0f);
			}
		}
		if (carried.getName() == "mat_waterbombs")
		{
			CBlob@ blob = server_CreateBlob("waterbomb", this.getTeamNum(), this.getPosition());
			carried.server_Die();
			caller.server_Pickup(blob);

			// slightly damage map
			blob.set_f32("map_damage_ratio", 0.1f);
			blob.set_f32("explosive_damage", 0.0f);
			blob.set_f32("explosive_radius", 92.0f);
			blob.set_bool("map_damage_raycast", false);
			blob.set_string("custom_explosion_sound", "/GlassBreak");
			blob.set_u8("custom_hitter", Hitters::water);
			blob.Tag("splash ray cast");
		}
		if (carried.getName() == "keg")
		{
			if (!carried.hasTag("exploding"))
			{
				carried.SendCommand(carried.getCommandID("activate"));

				// fireplace gives off bad vibes
				// if (this.getName() == "fireplace") 
				// {
				// 	this.set_s32("explosion_timer", this.get_f32("keg_time") / 2.0f);
				// 	this.set_f32("explosive_radius", 73.0f);
				// }
				// else 
				// {
				// 	this.set_s32("explosion_timer", this.get_f32("keg_time"));
				// }
			}
		}

	}

}