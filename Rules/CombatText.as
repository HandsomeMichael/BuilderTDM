// a WIP terraria combat text 

#define CLIENT_ONLY

CombatTextHandler gabriel_v1;

void onRestart( CRules@ this )
{
	gabriel_v1.Init();
}

void onTick( CRules@ this ) 
{
	gabriel_v1.UpdateAll();
}

void onRender( CRules@ this ) 
{
	gabriel_v1.RenderAll();
}

f32 onPlayerTakeDamage(CRules@ this, CPlayer@ victim, CPlayer@ attacker, f32 DamageScale)
{
	print("cum");

	if (isClient()) 
	{
		gabriel_v1.AddCombatText(victim.getBlob(),DamageScale,80);
	}

	return DamageScale;
}

class CombatTextHandler
{
	CombatText[] combatTexts = CombatText[](255); // idk how array works in angel script

	CombatTextHandler() {}

	void Init() 
	{
		// idk how array works please help
		combatTexts = CombatText[](255);
	}

	void AddCombatText(CBlob@ victim,f32 dmg = 1 ,u8 time = 255) 
	{
		CombatText cbt = CombatText(victim,dmg ,time);

		for(u8 i = 0; i < combatTexts.length(); i++) 
		{
			CombatText@ text = combatTexts[i];
			if (text is null) continue;

			if (text.timeleft == 0) 
			{
				combatTexts[i] = cbt;
				return;
			}
		}

		// replace the oldest one
		combatTexts[0] = cbt;
	}

	void UpdateAll() 
	{
		for(u8 i = 0; i < combatTexts.length(); i++) 
		{
			CombatText@ text = combatTexts[i];
			text.Update();
			//print("poo "+text.position.x);
		}
	}

	void RenderAll() 
	{
		for(u8 i = 0; i < combatTexts.length(); i++) 
		{
			CombatText@ text = combatTexts[i];
			text.Render();
		}
	}
}

class CombatText 
{
	Vec2f position;
	f32 damage;
	u8 timeleft;

	CombatText() { }
	CombatText(CBlob@ victim,f32 dmg = 1 ,u8 time = 255) 
	{
		position = victim.getInterpolatedScreenPos() + Vec2f((XORRandom(30) - 15),(XORRandom(30) - 15));
		damage = dmg;
		time = timeleft;
	}

	void Update() 
	{
		if (timeleft != 0) timeleft--;
	}

	void Render() 
	{
		if (timeleft != 0) GUI::DrawTextCentered("" + damage, position + Vec2f(0,timeleft*2) , SColor(255,255,255,255));
	}
}

