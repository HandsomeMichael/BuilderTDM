// all storage code are from kag dinghy code

void StoreInv_Init(CBlob@ this) {

	this.addCommandID("store inventory");

}

void StoreInv_HandleCommand(CBlob@ this, u8 cmd, CBitStream @params) 
{
	if (getNet().isServer()){

		if (cmd == this.getCommandID("store inventory")){

			CBlob@ caller = getBlobByNetworkID(params.read_u16());

			if (caller !is null){

				CInventory @inv = caller.getInventory();
				if (caller.getConfig() == "builder"){
					CBlob@ carried = caller.getCarriedBlob();
					if (carried !is null){
						// TODO: find a better way to check and clear blocks + blob blocks 
						// fix the fundamental problem, blob blocks not double checking requirement prior to placement.
						if (carried.hasTag("temp blob")){carried.server_Die();}
					}
				}
				if (inv !is null){

					while (inv.getItemsCount() > 0)
					{
						CBlob @item = inv.getItem(0);
						caller.server_PutOutInventory(item);
						this.server_PutInInventory(item);
					}
				}
			}
		}
	}
}
void StoreInv_GetButtons(CBlob@ this, CBlob@ caller,Vec2f offset)
{
	CInventory @inv = caller.getInventory();
	if (inv is null) return;

	if (inv.getItemsCount() > 0)
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		
		caller.CreateGenericButton(28, offset, 
		this, this.getCommandID("store inventory"), getTranslatedString("Store"), params);
	}
}

bool StoreInv_Accesible(CBlob@ this, CBlob@ forBlob)
{
	// basic team access
	if (!forBlob.isOverlapping(this)) return false;
	if (this.getTeamNum() == forBlob.getTeamNum()) return true;

	// sabotage
	CBlob@ carried = this.getCarriedBlob();
	if (carried !is null) {
		if (carried.getTeamNum() == this.getTeamNum()) {
			return true;
		}
	}
	return false;
}
