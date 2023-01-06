// create restock easily


CBlob@ CreateRestock(CBlob@ restocker,Vec2f pos, int resettime,int woodCount = 0,int stoneCount = 0, int goldCount = 0,bool parachute = false) {

	CBlob@ crate = server_CreateBlobNoInit("restockcrate");

	crate.Init();
	crate.setPosition(pos);

	if (parachute) {
		crate.Tag("parachute");
		restocker.Tag("RestockLanding");
	}

	crate.set_u16("reset_time",resettime);
	crate.set_netid("restockerID",restocker.getNetworkID());

	FillBasicMats(crate,woodCount,stoneCount,goldCount);

	return crate;
}

CBlob@ CreateSmallRestock(CBlob@ restocker,Vec2f pos, int resettime,int woodCount = 0,int stoneCount = 0, int goldCount = 0,bool parachute = false) {

	CBlob@ crate = server_CreateBlobNoInit("smallrestockcrate");

	crate.Init();
	crate.setPosition(pos);

	crate.Tag("multipledrop");

	if (parachute) {
		crate.Tag("parachute");
		restocker.Tag("RestockLanding");
	}

	crate.set_u16("reset_time",resettime);
	crate.set_netid("restockerID",restocker.getNetworkID());

	FillBasicMats(crate,woodCount,stoneCount,goldCount);

	return crate;
}

void FillBasicMats(CBlob@ crate,int woodCount = 0,int stoneCount = 0, int goldCount = 0) 
{
	MakeMatInside(crate,"mat_wood",woodCount);
	MakeMatInside(crate,"mat_stone",stoneCount);
	MakeMatInside(crate,"mat_gold",goldCount);
}

void MakeMatInside(CBlob@ this,string matname,int count) 
{
	if (count < 1) return;

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
void RenderTimeLeft(CSprite@ this,Vec2f offset = Vec2f_zero)
{
	CBlob@ b = this.getBlob();
	u32 time = ( b.get_u32("drop_mats") - getGameTime() ) / 60;
	string text = ""+time + " second left for Restock";

	// check if its waiting for restock
	if (getGameTime() >= b.get_u32("drop_mats")) 
	{
		if (b.hasTag("RestockLanding")) 
		{
			text = "Crate is landing ...";
		}
		else 
		{
			text = "Wait for crate to unbox ...";
		}
	}

	// is there a way to draw big and epic text ?
	GUI::SetFont("SNES");
	GUI::DrawTextCentered(text, b.getInterpolatedScreenPos() + offset, SColor(255,255,255,255));
}