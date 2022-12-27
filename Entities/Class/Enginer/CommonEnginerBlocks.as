// CommonBuilderBlocks.as

//////////////////////////////////////
// Builder menu documentation
//////////////////////////////////////

// To add a new page;

// 1) initialize a new BuildBlock array,
// example:
// BuildBlock[] my_page;
// blocks.push_back(my_page);

// 2)
// Add a new string to PAGE_NAME in
// BuilderInventory.as
// this will be what you see in the caption
// box below the menu

// 3)
// Extend BuilderPageIcons.png with your new
// page icon, do note, frame index is the same
// as array index

// To add new blocks to a page, push_back
// in the desired order to the desired page
// example:
// BuildBlock b(0, "name", "icon", "description");
// blocks[3].push_back(b);

#include "BuildBlock.as"
#include "Requirements.as"
#include "Costs.as"
#include "TeamIconToken.as"

const string blocks_property = "blocks";
const string inventory_offset = "inventory offset";

void addToken(int team_num) {
	AddIconToken("$build_woodchest$", "WoodChest.png", Vec2f(16, 16), team_num);
}

void addCommonBuilderBlocks(BuildBlock[][]@ blocks, int team_num = 0, const string&in gamemode_override = "")
{
	InitCosts();
	CRules@ rules = getRules();

	addToken(team_num);

	BuildBlock[] page_0;
	blocks.push_back(page_0);
	{
		BuildBlock b(CMap::tile_castle, "stone_block", "$stone_block$", "Stone Block\nBasic building block");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 10);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_castle_back, "back_stone_block", "$back_stone_block$", "Back Stone Wall\nExtra support");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", BuilderCosts::back_stone_block);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "stone_door", getTeamIcon("stone_door", "1x1StoneDoor.png", team_num, Vec2f(16, 8)), "Stone Door\nPlace next to walls");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", BuilderCosts::stone_door);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_wood, "wood_block", "$wood_block$", "Wood Block\nCheap block\nwatch out for fire!");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", BuilderCosts::wood_block);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_wood_back, "back_wood_block", "$back_wood_block$", "Back Wood Wall\nCheap extra support");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", BuilderCosts::back_wood_block);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "wooden_door", getTeamIcon("wooden_door", "1x1WoodDoor.png", team_num, Vec2f(16, 8)), "Wooden Door\nPlace next to walls");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", BuilderCosts::wooden_door);
		blocks[0].push_back(b);
	}
	// {
	// 	BuildBlock b(0, "trap_block", getTeamIcon("trap_block", "TrapBlock.png", team_num), "Trap Block\nOnly enemies can pass");
	// 	AddRequirement(b.reqs, "blob", "mat_stone", "Stone", BuilderCosts::trap_block);
	// 	blocks[0].push_back(b);
	// }
	// {
	// 	BuildBlock b(0, "bridge", getTeamIcon("bridge", "Bridge.png", team_num), "Trap Bridge\nOnly your team can stand on it");
	// 	AddRequirement(b.reqs, "blob", "mat_wood", "Wood", BuilderCosts::bridge);
	// 	blocks[0].push_back(b);
	// }
	{
		BuildBlock b(0, "ladder", "$ladder$", "Ladder\nAnyone can climb it");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", BuilderCosts::ladder);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "wooden_platform", "$wooden_platform$", "Wooden Platform\nOne way platform");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", BuilderCosts::wooden_platform);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "spikes", "$spikes$", "Spikes\nPlace on Stone Block\nfor Retracting Trap");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", BuilderCosts::spikes);
		blocks[0].push_back(b);
	}
	// custom structure
	{
		BuildBlock b(0, "woodenchest", "$build_woodchest$", "Wooden Chest\nAn ordinary wooden chest used for storage.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 80);
		b.buildOnGround = true;
		b.size.Set(16, 16);
		blocks[0].push_back(b);
	}

	// {
	// 	BuildBlock b(0, "workbench", "$workbench$", "Workbench\nCreate trampolines, saws, and more");
	// 	AddRequirement(b.reqs, "blob", "mat_wood", "Wood", WARCosts::workbench_wood);
	// 	b.buildOnGround = true;
	// 	b.size.Set(32, 16);
	// 	blocks[0].push_back(b);
	// }

	BuildBlock[] page_1;
	blocks.push_back(page_1);
	{
		BuildBlock b(0, "wire", "$wire$", "Wire\nSend a signal to a device");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "elbow", "$elbow$", "Elbow\nSend a signal at flipped direction to a device");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "tee", "$tee$", "Tee\nSend a signal at 2 direction to a device");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "junction", "$junction$", "Junction\nSend a signal at 4 direction to a device");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 20);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "diode", "$diode$", "Diode\nHonestly idk wat does this do");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 10);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "resistor", "$resistor$", "Resistor\nHonestly idk wat does this do");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 10);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "inverter", "$inverter$", "Inverter\nOutput inverted signal");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 20);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "oscillator", "$oscillator$", "Oscillator\nRepeat signal");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 10);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "transistor", "$transistor$", "Transistor");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 10);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "toggle", "$toggle$", "Toggle\nToggleable signal");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 20);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "randomizer", "$randomizer$", "Randomizer\nRandomly send signal");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 20);
		blocks[1].push_back(b);
	}

	BuildBlock[] page_2;
	blocks.push_back(page_2);
	{
		BuildBlock b(0, "lever", "$lever$", "Lever\nSend toggleable electricity");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 30);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "push_button", "$pushbutton$", "Button\nSend electricity");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 40);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "coin_slot", "$coin_slot$", "Coin Slot\nSend electricity from 60 coins");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 40);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "pressure_plate", "$pressureplate$", "Pressure Plate\nSend electricity if being pushed");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 30);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "sensor", "$sensor$", "Motion Sensor\nSend electricity if it detect movement");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 40);
		blocks[2].push_back(b);
	}

	BuildBlock[] page_3;
	blocks.push_back(page_3);
	{
		BuildBlock b(0, "lamp", "$lamp$", "Lamp\nGives light\nRequire power");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 10);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "emitter", "$emitter$", "Emitter\nHonestly idk what does this do");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 30);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "receiver", "$receiver$", "Receiver\nHonestly idk what does this do");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 30);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "magazine", "$magazine$", "Magazine\nStore item for dispenser and bolter");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 20);
		blocks[3].push_back(b);
	}
	{
		// custom block hell yeah
		BuildBlock b(0, "hopper", "$hopper$", "Hopper\nGrab nearest item and send it to magazine");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 10);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 5);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "bolter", "$bolter$", "Bolter\nShoot out projectiles\nRequire magazine behind and power");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 30);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "dispenser", "$dispenser$", "Dispenser\nDispense items\nRequire magazine behind and power");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 30);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "obstructor", "$obstructor$", "Obstructor\nHonestly idk what does this do");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 50);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "spiker", "$spiker$", "Spiker\nSpike any flesh\nRequire power");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 40);
		blocks[3].push_back(b);
	}
}

ConfigFile@ openBlockBindingsConfig()
{
	ConfigFile cfg = ConfigFile();
	if (!cfg.loadFile("../Cache/BlockBindings.cfg"))
	{
		// write EmoteBinding.cfg to Cache
		cfg.saveFile("BlockBindings.cfg");

	}

	return cfg;
}

u8 read_block(ConfigFile@ cfg, string name, u8 default_value)
{
	u8 read_val = cfg.read_u8(name, default_value);
	return read_val;
}
