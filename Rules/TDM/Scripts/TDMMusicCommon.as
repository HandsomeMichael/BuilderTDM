// Game Music
#include "ScriptBoss.as";

enum MusicTags
{
	// kag musics
	world_intro,
	world_home,
	world_calm,
	world_battle,
	world_battle_2,
	world_outro,
	world_quick_out,
	// custom
	custom_cybergrind, 
	// bosses
	boss_lordebison
};

//sound references with tag
void AddGameMusic(CBlob@ this, CMixer@ mixer)
{
	if (mixer is null)
		return;

	this.set_bool("initialized game", true);
	mixer.ResetMixer();
	// kag music
	mixer.AddTrack("Sounds/Music/KAGWorldIntroShortA.ogg", world_intro);
	mixer.AddTrack("Sounds/Music/KAGWorld1-1a.ogg", world_home);
	mixer.AddTrack("Sounds/Music/KAGWorld1-2a.ogg", world_home);
	mixer.AddTrack("Sounds/Music/KAGWorld1-3a.ogg", world_home);
	mixer.AddTrack("Sounds/Music/KAGWorld1-4a.ogg", world_home);
	mixer.AddTrack("Sounds/Music/KAGWorld1-5a.ogg", world_calm);
	mixer.AddTrack("Sounds/Music/KAGWorld1-6a.ogg", world_calm);
	mixer.AddTrack("Sounds/Music/KAGWorld1-7a.ogg", world_calm);
	mixer.AddTrack("Sounds/Music/KAGWorld1-8a.ogg", world_calm);
	mixer.AddTrack("Sounds/Music/KAGWorld1-9a.ogg", world_home);
	mixer.AddTrack("Sounds/Music/KAGWorld1-10a.ogg", world_battle);
	mixer.AddTrack("Sounds/Music/KAGWorld1-11a.ogg", world_battle);
	mixer.AddTrack("Sounds/Music/KAGWorld1-12a.ogg", world_battle);
	mixer.AddTrack("Sounds/Music/KAGWorld1-13+Intro.ogg", world_battle_2);
	mixer.AddTrack("Sounds/Music/KAGWorld1-14.ogg", world_battle_2);
	mixer.AddTrack("Sounds/Music/KAGWorldQuickOut.ogg", world_quick_out);
	// custom music
	mixer.AddTrack("Sound/Music/BangerMusic_HiveMind.ogg", boss_lordebison);
	mixer.AddTrack("Sound/Music/BangerMusic_TheCyberGrind.ogg", custom_cybergrind);
}

uint timer = 0;
u8 prevBossMusic = 0;

void GameMusicLogic(CBlob@ this, CMixer@ mixer)
{
	if (mixer is null)
		return;

	//warmup
	CRules @rules = getRules();

	// do boss music
	CBlob@ boss = ScriptBoss_GetBossAlive(rules);

	// stop boss music
	if (boss is null) {
		if (mixer.isPlaying(prevBossMusic)) mixer.FadeOut(prevBossMusic,1.0f);
	}
	if (boss !is null) {

		// play our very own music
		u8 musicID = boss.get_u8("musicID");
		mixer.FadeInRandom(musicID, 1.0f);
		prevBossMusic = musicID; // cache boss music

		// stop any other music, 
		if (mixer.isPlaying(world_home)) mixer.FadeOut(world_home,1.0f);
		if (mixer.isPlaying(world_battle)) mixer.FadeOut(world_battle,1.0f);
	}
	else if (rules.isWarmup())
	{
		if (mixer.getPlayingCount() == 0)
		{
			mixer.FadeInRandom(world_home , 0.0f);
		}
	}
	else if (rules.isMatchRunning()) //battle music
	{
		if (mixer.getPlayingCount() == 0)
		{
			mixer.FadeInRandom(world_battle , 1.0f);
		}
	}
	else
	{
		mixer.FadeOutAll(0.0f, 1.0f);
	}
}
