// BuilderShop.as

// #include "Requirements.as"
// #include "ShopCommon.as"
// #include "Descriptions.as"
// #include "Costs.as"
// #include "CheckSpam.as"
// #include "GenericButtonCommon.as"
// #include "TeamIconToken.as"

void onInit(CBlob@ this)
{
	// epic
	this.Tag("ignore fall");
	this.Tag("heavy weight");
}

void onDetach(CBlob@ this,CBlob@ detached,AttachmentPoint@ attachedPoint)
{
	detached.Untag("shielded");
}

void onAttach( CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint )
{
	attached.Tag("shielded");
}

