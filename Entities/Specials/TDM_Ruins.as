// Patch : Added material drop or somethin

// TDM Ruins logic

#include "ClassSelectMenu.as"
#include "StandardRespawnCommand.as"
#include "StandardControlsCommon.as"
#include "RespawnCommandCommon.as"
#include "GenericButtonCommon.as"
#include "MakeCrate.as"


void onInit(CBlob@ this)
{
	this.CreateRespawnPoint("ruins", Vec2f(0.0f, 16.0f));

	AddIconToken("$builder_class$", "GUI/MenuItems.png", Vec2f(32, 32), 8);     // pickaxe
	AddIconToken("$enginer_class$", "ClassIcon.png", Vec2f(32, 32), 0); // hammer
	AddIconToken("$trapmaster_class$", "ClassIcon.png", Vec2f(32, 32), 1);      // a foking stick
	AddIconToken("$change_class$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 12, 2);

	//TDM classes
	addPlayerClass(this, "Chad Builder", "$builder_class$", "builder", "Build and Destroy Enemies");
	addPlayerClass(this, "Certified Enginer", "$enginer_class$", "enginer", "Build and Support Teammates");
	addPlayerClass(this, "Team Trapper", "$trapmaster_class$", "trapmaster", "Build traps and castles");

	this.getShape().SetStatic(true);
	this.getShape().getConsts().mapCollisions = false;

	this.addCommandID("class menu");
	this.addCommandID("getsupply");

	this.Tag("change class drop inventory");
	this.set_u32("drop_mats",getGameTime() + 60);

	this.getSprite().SetZ(-50.0f);   // push to background
}

void onTick(CBlob@ this)
{
	// dont drop any epic mats
	if (this.hasTag("wait")) return;

	if (getGameTime() >= this.get_u32("drop_mats"))
	{
		if (isClient() && this.getTeamNum() == getLocalPlayer().getTeamNum())
		{	
			client_AddToChat("Restock material dropped at spawn", SColor(255, 255, 0, 0));
		}

		if (!isServer()) return; /////////////////////////////////// SERVER ONLY

		CBlob@ crate = server_MakeCrate("", "", 0, this.getTeamNum(), this.getPosition());

		if (crate !is null)
		{
			// add tags for waiting and unpacking
			this.Tag("wait");
			crate.set_u16("ruinsID",this.getNetworkID());
			crate.Tag("unpackall");

			// wood mats
			for (uint i = 0; i < 2; i++){
				CBlob@ mat = server_CreateBlob("mat_wood");
				if (mat !is null){crate.server_PutInInventory(mat);}
			}
			// stone mats
			for (uint i = 0; i < 1; i++){
				CBlob@ mat = server_CreateBlob("mat_stone");
				if (mat !is null){crate.server_PutInInventory(mat);}
			}
			// gold mats
			CBlob@ gold = server_CreateBlob("mat_gold");
			if (gold !is null){crate.server_PutInInventory(gold);}

			// add crate material logo
			CSprite@ sprite = crate.getSprite();
			CSpriteLayer@ logo = sprite.addSpriteLayer("logo", "Materials.png" , 16, 16, this.getTeamNum(), this.getSkinNum());
			if (logo !is null){
				Animation@ anim = logo.addAnimation("default", 0, false);
				anim.AddFrame(26);
				logo.SetOffset( sprite.getOffset() + Vec2f(12.0f, -12.0f) );
				logo.SetRelativeZ(2);
			}
		}
	}
}

// render timeleft for restock
void onRender(CSprite@ this)
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

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("getsupply")) {

	}
	else if (cmd == this.getCommandID("class menu"))
	{
		u16 callerID = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(callerID);

		if (caller !is null && caller.isMyPlayer())
		{
			BuildRespawnMenuFor(this, caller);
		}
	}
	else
	{
		onRespawnCommand(this, cmd, params);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	
	if (!canSeeButtons(this, caller)) return;

	if (canChangeClass(this, caller))
	{
		if (isInRadius(this, caller))
		{
			BuildRespawnMenuFor(this, caller);
		}
		else
		{
			CBitStream params;
			params.write_u16(caller.getNetworkID());
			caller.CreateGenericButton("$change_class$", Vec2f(0, 6), this, this.getCommandID("class menu"), getTranslatedString("Change class"), params);
		}
	}

	// warning: if we don't have this button just spawn menu here we run into that infinite menus game freeze bug
}

bool isInRadius(CBlob@ this, CBlob @caller)
{
	return (this.getPosition() - caller.getPosition()).Length() < this.getRadius();
}
