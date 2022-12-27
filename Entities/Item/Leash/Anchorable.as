
// Script for anchor , i decided it will be better if it were anchor

void onInit(CBlob@ this) 
{
	this.addCommandID("leash_em");
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params) 
{
	if (cmd == this.getCommandID("leash_em")) 
	{
		CBlob@ carried = getBlobByNetworkID(params.read_netid());
		if (carried is null) return;

		if (carried.getName() == "anchor")
		{
			if (this.getNetworkID() == carried.get_netid("leashID")) {carried.set_netid("leashID",0);}
			else {
				carried.set_netid("leashID",this.getNetworkID());
			}

			if (isClient()) {
				carried.getSprite().PlaySound("EquipSomething.ogg");
			}
		}
	}
}
void GetButtonsFor(CBlob@ this, CBlob@ caller) 
{
	CBlob@ carried = caller.getCarriedBlob();
	if (carried !is null) {
		if (carried.getName() == "anchor") {
			CBitStream params;
			params.write_u16(carried.getNetworkID());
			caller.CreateGenericButton("$anchor$", Vec2f(10, 10), this, this.getCommandID("leash_em"), getTranslatedString("Leash / Unleash"),params);
		}
	}
}