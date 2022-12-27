#include "TradingCommon.as"
#include "Descriptions.as"
#include "GameplayEvents.as"
#include "AssistCommon.as"
#include "Hitters.as"

#define SERVER_ONLY

// bonus for being an offensive builder
int coinsOnDamageAdd = 8;
int coinsOnAssistAdd = 10;
int coinsOnKillAdd = 15;
int coinsOnDeathLose = 10; // percentage

int min_coins = 50;
int max_coins = 100;

const int coinsOnHitSiege = 2; //per heart of damage
const int coinsOnKillSiege = 20;

const int coinsOnBuildStoneBlock = 3;
const int coinsOnBuildWood = 1;
const int coinsOnBuildStoneDoor = 5;

const int warmupFactor = 2;

const f32 killstreakFactor = 1.3f;

string cost_config_file = "tdm_vars.cfg";
bool kill_traders_and_shops = false;

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	if (blob.getName() == "tradingpost")
	{
		if (kill_traders_and_shops)
		{
			blob.server_Die();
			// kill all trader 
			KillTradingPosts();
		}
		else
		{
			MakeTradeMenu(blob);
		}
	}
}

TradeItem@ addItemForCoin(CBlob@ this, const string &in name, int cost, const bool instantShipping, const string &in iconName, const string &in configFilename, const string &in description)
{
	// if cost set to 0 or less then it wont appear at shop
	if(cost <= 0) {return null;}

	TradeItem@ item = addTradeItem(this, name, 0, instantShipping, iconName, configFilename, description);
	if (item !is null)
	{
		AddRequirement(item.reqs, "coin", "", "Coins", cost);
		item.buyIntoInventory = true;
	}
	return item;
}

void MakeTradeMenu(CBlob@ trader)
{
	//load config

	if (getRules().exists("tdm_costs_config"))
		cost_config_file = getRules().get_string("tdm_costs_config");

	ConfigFile cfg = ConfigFile();
	cfg.loadFile(cost_config_file);

	s32 cost_bombs = cfg.read_s32("cost_bombs", 20);
	s32 cost_keg = cfg.read_s32("cost_keg", 80);
	s32 cost_mine = cfg.read_s32("cost_mine", 50);

	s32 cost_arrows = cfg.read_s32("cost_arrows", 10);

	s32 cost_boulder = cfg.read_s32("cost_boulder", 40);
	s32 cost_burger = cfg.read_s32("cost_burger", 30);

	s32 cost_mountedbow = cfg.read_s32("cost_mountedbow", 160);
	s32 cost_drill = cfg.read_s32("cost_drill", 120);

	s32 menu_width = cfg.read_s32("trade_menu_width", 3);
	s32 menu_height = cfg.read_s32("trade_menu_height", 6);

	// build menu
	CreateTradeMenu(trader, Vec2f(menu_width, menu_height), "Buy weapons");

	addTradeSeparatorItem(trader, "$MENU_GENERIC$", Vec2f(3, 1));

	// ive been thinking to remove merchant entirely or just make it sell material
	
	addItemForCoin(trader, "Drill", cost_drill, true, "$drill$", "drill", Descriptions::drill);

	//knighty stuff
	addItemForCoin(trader, "Bomb", cost_bombs, true, "$mat_bombs$", "mat_bombs", Descriptions::bomb);
	addItemForCoin(trader, "Keg", cost_keg, true, "$keg$", "keg", Descriptions::keg);
	addItemForCoin(trader, "Mine", cost_mine, true, "$mine$", "mine", Descriptions::mine);
	
	//yummy stuff
	addItemForCoin(trader, "Burger", cost_burger, true, "$food$", "food", Descriptions::food);
	//archery stuff
	addItemForCoin(trader, "Arrows", cost_arrows, true, "$mat_arrows$", "mat_arrows", Descriptions::arrows);

	addItemForCoin(trader, "Mounted Bow", cost_mountedbow, true, "$mounted_bow$", "mounted_bow", Descriptions::mounted_bow);
	addItemForCoin(trader, "Boulder", cost_boulder, true, "$boulder$", "boulder", Descriptions::boulder);

	// Gold trade
	{
		ShopItem@ s = addShopItem(trader, "100 Stone for 50 Gold" , "$mat_gold$", "mat_gold/50", "Trade 100 stone for 50 gold", false);
		s.spawnNothing = true;
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 100);
		AddRequirement(s.requirements, "coin", "", "Coins", 10);
	}
	{
		ShopItem@ s = addShopItem(trader, "200 Wood for 50 Gold" , "$mat_gold$", "mat_gold/50", "Trade 200 wood for 50 gold", false);
		s.spawnNothing = true;
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 200);
		AddRequirement(s.requirements, "coin", "", "Coins", 10);
	}
}

// load coins amount

void Reset(CRules@ this)
{
	//load the coins vars now, good a time as any
	if (this.exists("tdm_costs_config"))
		cost_config_file = this.get_string("tdm_costs_config");

	ConfigFile cfg = ConfigFile();
	cfg.loadFile(cost_config_file);

	coinsOnDamageAdd = cfg.read_s32("coinsOnDamageAdd", coinsOnDamageAdd);
	coinsOnAssistAdd = cfg.read_s32("coinsOnAssistAdd", coinsOnAssistAdd);
	coinsOnKillAdd = cfg.read_s32("coinsOnKillAdd", coinsOnKillAdd);
	coinsOnDeathLose = cfg.read_s32("coinsOnDeathLose", coinsOnDeathLose);

	min_coins = cfg.read_s32("minCoinsOnRestart", min_coins);

	kill_traders_and_shops = !(cfg.read_bool("spawn_traders_ever", true));

	if (kill_traders_and_shops)
	{
		KillTradingPosts();
	}

	//clamp coin vars each round
	for (int i = 0; i < getPlayersCount(); i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null) continue;

		s32 coins = player.getCoins();
		player.server_setCoins(min_coins);
	}

}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CRules@ this)
{
	Reset(this);
}

void KillTradingPosts() {
	CBlob@[] tradingposts;
	bool found = false;
	if (getBlobsByName("tradingpost", @tradingposts))
	{
		for (uint i = 0; i < tradingposts.length; i++)
		{
			CBlob @b = tradingposts[i];
			b.server_Die();
		}
	}
}

// CTF Trading

// give coins for killing
void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData)
{
	if (!getNet().isServer())
		return;

	if (victim !is null)
	{
		if (killer !is null)
		{
			// you can get coin from killing your teammate yes
			if (killer !is victim){
				killer.server_setCoins(killer.getCoins() + (coinsOnKillAdd * Maths::Pow(killstreakFactor, killer.get_u8("killstreak"))));
			}
			
			CPlayer@ helper = getAssistPlayer (victim, killer);
			if (helper !is null) 
			{ 
				helper.server_setCoins(helper.getCoins() + coinsOnAssistAdd);
			}
		}
	}
}

// give coins for damage

f32 onPlayerTakeDamage(CRules@ this, CPlayer@ victim, CPlayer@ attacker, f32 DamageScale)
{
	if (!getNet().isServer())
		return DamageScale;

	if (attacker !is null && attacker !is victim)
	{
		// secretly add double coins when hitting teammates
		bool friendlyFire = attacker.getTeamNum() == victim.getTeamNum();

        CBlob@ v = victim.getBlob();
        f32 health = 0.0f;
        if(v !is null)
            health = v.getHealth();
        f32 dmg = DamageScale;
        dmg = Maths::Min(health, dmg);

		attacker.server_setCoins(attacker.getCoins() + (dmg * coinsOnDamageAdd / this.attackdamage_modifier) * (friendlyFire ? 2 : 1));
	}

	return DamageScale;
}

// coins for various game events
void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	//rest of this are only important on server
	if (!getNet().isServer())
		return;

	if (cmd == getGameplayEventID(this))
	{
		GameplayEvent g(params);

		CPlayer@ p = g.getPlayer();
		if (p !is null)
		{
			u32 coins = 0;

			switch (g.getType())
			{
				case GE_built_block:

				{
					g.params.ResetBitIndex();
					u16 tile = g.params.read_u16();
					if (tile == CMap::tile_castle)
					{
						coins = coinsOnBuildStoneBlock;
					}
					else if (tile == CMap::tile_wood)
					{
						coins = coinsOnBuildWood;
					}
				}

				break;

				case GE_built_blob:

				{
					g.params.ResetBitIndex();
					string name = g.params.read_string();

					if (name == "trap_block" || name == "spikes"){
						coins = coinsOnBuildStoneBlock;
					}
					else if (name == "stone_door"){
						coins = coinsOnBuildStoneDoor;
					}
					else if (name == "wooden_platform" ||name == "wooden_door" ||name == "bridge" ||name == "ladder"){
						coins = coinsOnBuildWood;
					}
				}

				break;

				case GE_hit_vehicle:

				{
					g.params.ResetBitIndex();
					f32 damage = g.params.read_f32();
					coins = coinsOnHitSiege * damage;
				}

				break;

				case GE_kill_vehicle:
					coins = coinsOnKillSiege;
					break;
			}

			if (coins > 0)
			{
				if (this.isWarmup())
					coins /= warmupFactor;

				p.server_setCoins(p.getCoins() + coins);
			}
		}
	}
}
