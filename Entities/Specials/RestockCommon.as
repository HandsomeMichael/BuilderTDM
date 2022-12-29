// create restock easily


void CreateRestock(CBlob@ restocker,Vec2f pos, int resettime,int woodCount = 0,int stoneCount = 0, int goldCount = 0,bool parachute = false) {

	CBlob@ crate = server_CreateBlobNoInit("restockcrate");
	crate.Init();
	crate.setPosition(pos);
	crate.set_u16("reset_time",resettime);
	crate.set_netid("restockerID",restocker.getNetworkID());

	if (parachute) crate.Tag("parachute");

	if (woodCount > 0) {MakeMatInside(crate,"mat_wood",woodCount);}
	if (stoneCount > 0) {MakeMatInside(crate,"mat_stone",stoneCount);}
	if (goldCount > 0) {MakeMatInside(crate,"mat_gold",goldCount);}
}

void MakeMatInside(CBlob@ this,string matname,int count) 
{
	CBlob@ mat = server_CreateBlobNoInit(matname);

	if (mat !is null)
	{
		mat.Tag('custom quantity');
		mat.Init();
		mat.server_SetQuantity(count);
		this.server_PutInInventory(mat);
	}
}

// render timeleft for restock
void RenderTimeLeft(CSprite@ this)
{
	CBlob@ b = this.getBlob();
	u32 time = ( b.get_u32("drop_mats") - getGameTime() ) / 60;
	string text = ""+time + " second left for Restock";

	// wait
	if (b.hasTag("wait")) {
		text = "Wait for crate to unbox ...";
	}

	// is there a way to draw big and epic text ?
	GUI::SetFont("SNES");
	GUI::DrawTextCentered(text, b.getInterpolatedScreenPos(), SColor(255,255,255,255));
}