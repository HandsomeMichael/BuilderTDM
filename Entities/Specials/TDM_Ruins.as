// Patch : Added material drop or somethin

// TDM Ruins logic

#include "ClassSelectMenu.as"
#include "StandardRespawnCommand.as"
#include "StandardControlsCommon.as"
#include "RespawnCommandCommon.as"
#include "GenericButtonCommon.as"
#include "RestockCommon.as"

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
			client_AddToChat("Restock material dropped at spawn");
		}

		if (!isServer()) return; /////////////////////////////////// SERVER ONLY

		// add tags for waiting and unpacking
		this.Tag("wait");

		CreateRestock(this,
		this.getPosition(), // pos
		1500, // delay
		XORRandom(250) + 250 , // wood count
		XORRandom(125) + 125, // stone count
		XORRandom(25) + 10, // gold count
		false); // parachute
	}
}

// render timeleft for restock
void onRender(CSprite@ this){RenderTimeLeft(this);}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("class menu"))
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
