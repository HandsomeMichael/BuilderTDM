// Always draws a health bar 

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	//VV right here VV
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	Vec2f pos2d = blob.getScreenPos() + Vec2f(0, 20);
	Vec2f dim = Vec2f(24, 8);
	const f32 y = blob.getHeight() * 2.4f;
	const f32 initialHealth = blob.getInitialHealth();
	if (initialHealth > 0.0f)
	{
		const f32 perc = blob.getHealth() / initialHealth;
		if (perc >= 0.0f)
		{
			GUI::DrawRectangle(Vec2f(pos2d.x - dim.x - 2, pos2d.y + y - 2), Vec2f(pos2d.x + dim.x + 2, pos2d.y + y + dim.y + 2));
			GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 2, pos2d.y + y + 2), Vec2f(pos2d.x - dim.x + perc * 2.0f * dim.x - 2, pos2d.y + y + dim.y - 2), SColor(0xffac1512));
		}
	}
}