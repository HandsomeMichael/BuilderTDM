

// Boss UI and boss camera management

// for linear interpolating purpose
float healthBarLerp = 0.0f;

// get boss that's still alive
CBlob@ ScriptBoss_GetBossAlive(CRules@ this) {

	// check existance
	if (!this.exists("bossNetID")) return null;

	// check valid id
	u16 bossNetID = this.get_netid("bossNetID");
	if (bossNetID < 1) return null;

	// check blob null and alive
	CBlob@ blob = getBlobByNetworkID(bossNetID);
	if (blob !is null) return (blob.hasTag("dead") ? null : blob);

	return null;
}

// set boss hit
void ScriptBoss_BossHit(CBlob@ this) 
{
	this.Tag("justGotHit");
	//this.set_bool("bossGotHit",true);
}

// set current boss
void ScriptBoss_SetBoss(CBlob@ blob , int time) {

	if (blob is null) return;

	getRules().set_netid("bossNetID",blob.getNetworkID());
	getRules().set_u32("bossFollowTime",getGameTime() + time);
}

// reset ui property
void ResetHealthBar() {
	healthBarLerp = 0.0f;
}

// draw boss ui healthbar and other stuff
void ScriptBoss_RenderBossUI(CRules@ this,CPlayer@ player) {

	// check existance
	if (!this.exists("bossNetID")) {
		ResetHealthBar();
		return;
	}

	// get net id
	u32 bossNetID = this.get_netid("bossNetID");
	if (bossNetID < 1) {
		ResetHealthBar();
		return;
	}

	// getblob
	CBlob@ blob = getBlobByNetworkID(bossNetID);
	if (blob is null) {
		ResetHealthBar();
		return;
	}
	
	// draw health bar
	if (blob.getInitialHealth() > 0.0f) {

		// i dont want to make my code messy , but my code is already messy
		const f32 perc = blob.getHealth() / blob.getInitialHealth(); // percent 
		Vec2f topLeft = Vec2f(15, 160);

		// draw terraria bar
		healthBarLerp = Maths::Lerp(healthBarLerp,perc,0.1f);
		GUI::DrawIcon("BossHealthBar.png", (blob.hasTag("justGotHit") ? 2 : 1), Vec2f(137,24), topLeft, healthBarLerp, 1.0f, SColor(255,255,255,255));
		GUI::DrawIcon("BossHealthBar.png", 0, Vec2f(137,24), topLeft);

		// draw boss icon
		GUI::DrawIcon(blob.getName()+"_Icon.png", 0, Vec2f(16,16), topLeft + Vec2f(1,3));

		// draw boss name
		GUI::DrawText(blob.getInventoryName(), topLeft + Vec2f(30, 10), SColor(255, 255, 255, 255));

		// reset boss hit
	}
	else {
		ResetHealthBar();
	}

	// draw titles
	if (this.exists("bossFollowTime")) {
		u32 bossFollowTime = this.get_u32("bossFollowTime");
		if (bossFollowTime >= getGameTime()) {
			// draw titles icon at center a bit at top
			Vec2f pos = Vec2f(getScreenWidth()/2,getScreenHeight()/3) - Vec2f(64,16);
			GUI::DrawIcon("BossTitles.png", 1, Vec2f(128, 32), pos);
		}
	}
}

// reset boss follow time
void _ResetFollowTime(CRules@ rules, bool checkNull = true) 
{
	rules.set_u32("bossFollowTime",0);
}

// handle boss camera
bool oneTickUnfollowBlob = false;

void onTick(CRules@ this) 
{
	// check existance
	if (!this.exists("bossNetID")) return;
	if (!this.exists("bossFollowTime")) return;

	// get vars
	u16 bossNetID = this.get_netid("bossNetID");
	u32 bossFollowTime = this.get_u32("bossFollowTime");
	CBlob@ blob = getBlobByNetworkID(bossNetID);
	CCamera@ camera = getCamera();
	if (camera is null) return;

	if (bossFollowTime >= getGameTime()) 
	{
		// if blob not found then we reset follow time
		if (blob is null) {_ResetFollowTime(this);}
		else {camera.setTarget(blob);}

		oneTickUnfollowBlob = true;
	}
	else if (oneTickUnfollowBlob) {
		// we reset follow time if the time passed
		camera.setTarget(getLocalPlayer().getBlob());
		oneTickUnfollowBlob = false;
	}

}
