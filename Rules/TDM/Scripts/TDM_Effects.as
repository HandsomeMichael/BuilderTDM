// Client only
#define CLIENT_ONLY

// most code are from here
#include "ScriptBoss.as";

// draw some darkening effects
float effectLerp = 0.0f;

void onRender(CRules@ this) {

	// reset if null
	CBlob@ blob = ScriptBoss_GetBossAlive(this);
	if (blob is null) {
		effectLerp = 0.0f;
		return;
	}

	// do some darkening idk

	Driver@ driver = getDriver();
	effectLerp = Maths::Lerp(effectLerp,100.0f,0.1f);
	Vec2f screenSize(driver.getScreenWidth(), driver.getScreenHeight());
	GUI::DrawRectangle(Vec2f(0, 0), screenSize, SColor(Maths::Round(effectLerp), 255, 8, 0));
}