#include "GenericButtonCommon.as"

void onInit(CBlob@ this)
{
	this.addCommandID("equip_this");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;
	// only work on builder
	if (caller.getName() != "builder" && 
		caller.getName() != "enginer" && 
		caller.getName() != "trapmaster") return;

	CBitStream params;
	params.write_netid(caller.getNetworkID());

	CButton@ button = caller.CreateGenericButton(
	10,																// icon
	Vec2f_zero,														// offset
	this, 															// blob
	this.getCommandID("equip_this"), 								// command
	"Equip", params);												// description
	// from shop.as
	button.enableRadius = 20;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("equip_this"))
	{
		// play sound
		this.getSprite().PlaySound("/EquipSomething.ogg");

		// check caller null
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		if (caller is null) return;

		// Tag em
		caller.Tag("armored");
		this.Tag("dead");
		if (isServer()) {this.server_Die();}
	}
}