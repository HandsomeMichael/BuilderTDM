//Ghost logic

#include "Hitters.as";
#include "Knocked.as";
#include "ThrowCommon.as";
#include "RunnerCommon.as";
#include "Help.as";
#include "Requirements.as"

void onInit(CBlob@ this)
{
	this.Tag("noCapturing");
	this.Tag("truesight");

	this.set_f32("gib health", -3.0f);

	this.getShape().getConsts().mapCollisions = false;

	this.Tag("player");
	this.Tag("invincible");
	this.set_Vec2f("inventory offset", Vec2f(0.0f, 2.0f));

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";

	this.SetLight(true);
	this.SetLightRadius(80.0f);
	this.SetLightColor(SColor(255, 255, 255, 255));
}

// funny funky friday
void onSetPlayer(CBlob@ this, CPlayer@ player){
	if (player !is null){
		player.SetScoreboardVars("ScoreboardIcons.png", 5, Vec2f(16, 16));
	}
}

void onDie(CBlob@ this)
{
	CPlayer@ player = this.getPlayer();
	if (player !is null){
		client_AddToChat("Something terrifying has despawned", SColor(255, 255, 255, 255));
	}
}

void onTick(CBlob@ this)
{
	// if you reading this , i live at 157 Tasman RD , Otaki , Wellington
	// i deleted all of my other data 
	// this is the proof of my innocent

	if (this.isKeyPressed(key_action1)) this.AddForce(this.getAimPos()-this.getPosition());
}

// very friendly interaction
void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null && blob.hasTag("player") && !this.hasTag("dead"))
	{
		blob.Tag("dead");
		if (isServer()) {blob.server_Die();}
		blob.getSprite().Gib();
	}
}

// no pain
f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData){return 0;}
