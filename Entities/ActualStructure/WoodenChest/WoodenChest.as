// A script by TFlippy
// stolen by yours truly Chyota

// wat is the difference between putting semicolon or not in include ??!?
#include "StorageCommon.as";
#include "GenericButtonCommon.as"

void onInit(CSprite@ this)
{
	this.SetZ(-60);
}

void onInit(CBlob@ this)
{
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("builder always hit");
	this.Tag("extractable"); // used for hoppers, in TC it used for extractor machine thing

	StoreInv_Init(this);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getMap().rayCastSolid(caller.getPosition(), this.getPosition())) return;
	CBlob@ carried = caller.getCarriedBlob();
	if(carried is null && this.isOverlapping(caller)) {
		if (caller.getTeamNum() == this.getTeamNum()){
			StoreInv_GetButtons(this,caller,Vec2f(0, -10));
		}
	}
}

void onCreateInventoryMenu( CBlob@ this, CBlob@ forBlob, CGridMenu @gridmenu ) {
	if (isClient()) {
		CSprite@ sprite = this.getSprite();
		if (sprite !is null) {
			sprite.SetAnimation("open");
			sprite.PlaySound("ChestOpen.ogg");
		}
	}
}

void DoClose(CBlob@ this, bool doStore = true) {
	if (isClient()) {
		CSprite@ sprite = this.getSprite();
		if (sprite !is null) {
			if (sprite.isAnimation("open")) {
				sprite.SetAnimation("close");
				sprite.PlaySound("ChestClose.ogg");
			}
			else if (doStore) {
				if (sprite.isAnimation("store")) {sprite.SetFrameIndex(0);}
				sprite.SetAnimation("store");
				sprite.PlaySound("ChestOpen.ogg");
			}
		}
	}
}

void onAddToInventory( CBlob@ this, CBlob@ blob ) {DoClose(this);}
void onRemoveFromInventory( CBlob@ this, CBlob@ blob ) {DoClose(this,false);}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params) {StoreInv_HandleCommand(this,cmd,params);}
bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob){return StoreInv_Accesible(this,forBlob);}
