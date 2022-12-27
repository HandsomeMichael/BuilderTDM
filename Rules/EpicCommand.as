// in memory of Mirsario , stolen by yours truly Chyota

#include "MakeSeed.as";
// #include "MakeCrate.as";
// #include "MakeScroll.as";
// #include "MiscCommon.as";
#include "BasePNGLoader.as";
#include "LoadWarPNG.as";
#include "TournamentMapcycle.as";

void onInit(CRules@ this)
{
	this.addCommandID("addbot");
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("addbot"))
	{
		string botName;
		string botDisplayName;

		if (!params.saferead_string(botName)) return;

		if (!params.saferead_string(botDisplayName)) return;

		CPlayer@ bot=AddBot(botName);
		bot.server_setCharacterName(botDisplayName);
		bot.server_setTeamNum(1);
	}
}

bool onServerProcessChat(CRules@ this,const string& in text_in,string& out text_out,CPlayer@ player)
{
	if (player is null) return true;
	CBlob@ blob = player.getBlob();
	if (blob is null) return true;

	if (text_in.substr(0,1) == "!")
	{
		print("Command by player "+player.getUsername()+" (Team "+player.getTeamNum()+"): "+text_in);
		tcpr("[MISC] Command by player" +player.getUsername()+" (Team "+player.getTeamNum()+"): "+text_in);

		string[]@ tokens = text_in.split(" ");

		// shame
		if (tokens.length > 0) {
			if (tokens[0] == "!heyguysdidyouknowthatintermsofwatertypepokemonandhumanbreedingvaporeonisthemostcompatibletohumannotonlybecausethebodyishotbutalsoitwillmakeyougocrazyjustlikemepleaseineedhelpmytherapisschargememoremoneybutidonthaveanypleasegodiwantsomeonetolovemeplease" && player.isMyPlayer()) {

				// litteraly me
				if (XORRandom(3) == 2) {return true;}

				CBlob@ newBlob = server_CreateBlob("princess",68,blob.getPosition());
				if (newBlob !is null){
					newBlob.server_SetPlayer(player);
					blob.server_Die();
				}
				return false;
			}
		}

		// op
		if (tokens.length > 0 && (player.isMod() || player.getUsername() == "Chyota" || blob.hasTag("king")))
		{
			if (tokens[0] == "!ultrakill") {
				// create burgir
				CBlob@ newBlob = server_CreateBlob("food", blob.getTeamNum(), blob.getPosition());
				if (isClient()) {
					CSprite@ sprite = newBlob.getSprite();
					sprite.RewindEmitSound();
					sprite.SetEmitSound("BangerMusic_TheCyberGrind.ogg");
					sprite.SetEmitSoundPaused(false);
				}
			}
			if (tokens[0]=="!iamhorny")
			{
				CBlob@ newBlob = server_CreateBlob("princess",68,blob.getPosition());
				if (newBlob !is null){
					newBlob.server_SetPlayer(player);
					blob.server_Die();
				}
			}
			if (tokens[0] == "!help" && player.isMyPlayer()) {
				client_AddToChat("List of command : !iamhorny, !ultrakill, !coins <amount>, !removebot <name> , !addbot <name> , !teambot , !tree , !bigtree , !spawnwater , !team <team> , !class <blob> , !nextmap , !randommap , !<blob> <quantity>, !morph, !loadmap <mapfilepath>, !addTag <Tag>, !addTagHold <Tag>, !op");
			}
			if (tokens[0]=="!coins")
			{
				int amount=	tokens.length>=2 ? parseInt(tokens[1]) : 100;
				player.server_setCoins(player.getCoins()+amount);
			}
			if (tokens[0]=="!removebot" || tokens[0]=="!kickbot")
			{
				int playersAmount=	getPlayerCount();
				for (int i=0;i<playersAmount;i++)
				{
					CPlayer@ user=getPlayer(i);
					if (user !is null && user.isBot())
					{
						CBitStream params;
						params.write_u16(getPlayerIndex(user));
						this.SendCommand(this.getCommandID("kickPlayer"),params);
					}
				}
			}
			else if (tokens[0]=="!addbot" || tokens[0]=="!bot")
			{
				if (tokens.length<2) return false;
				string botName=			tokens[1];
				string botDisplayName=	tokens[1];
				for (int i=2;i<tokens.length;i++)
				{
					botName+=		tokens[i];
					botDisplayName+=" "+tokens[i];
				}

				CBitStream params;
				params.write_string(botName);
				params.write_string(botDisplayName);
				this.SendCommand(this.getCommandID("addbot"),params);
			}
			else if (tokens[0]=="!teambot")
			{
				CPlayer@ bot = AddBot("gregor_builder");
				bot.server_setTeamNum(player.getTeamNum());

				CBlob@ newBlob = server_CreateBlob("builder",player.getTeamNum(),blob.getPosition());
				newBlob.server_SetPlayer(bot);
			}
			else if (tokens[0]=="!tree") 
				server_MakeSeed(blob.getPosition(),"tree_pine",600,1,16);

			else if (tokens[0]=="!bigtree") 
				server_MakeSeed(blob.getPosition(),"tree_bushy",400,2,16);

			else if (tokens[0]=="!spawnwater") 
				getMap().server_setFloodWaterWorldspace(blob.getPosition(),true);

			else if (tokens[0]=="!team")
			{
				if (tokens.length<2) return false;
				int team=parseInt(tokens[1]);
				blob.server_setTeamNum(team);

				player.server_setTeamNum(team); // Finally
			}
			else if (tokens[0]=="!op")
			{
				CBlob@ newBlob = server_CreateBlob("lordeneko",69,blob.getPosition());
				if (newBlob !is null){
					newBlob.server_SetPlayer(player);
					blob.server_Die();
				}
			}
			else if (tokens[0]=="!class")
			{
				if (tokens.length!=2) return false;
				CBlob@ newBlob = server_CreateBlob(tokens[1],blob.getTeamNum(),blob.getPosition());
				if (newBlob !is null)
				{
					newBlob.server_SetPlayer(player);
					blob.server_Die();
				}
			}
			else if (tokens[0]=="!nextmap") LoadNextMap();
			else if (tokens[0]=="!randommap")
			{
				string[]@ OffiMaps;
				getRules().get("maptypes-offi", @OffiMaps);
				if (OffiMaps is null) return true;
				LoadMap(OffiMaps[XORRandom(OffiMaps.length)]);
			}
			else if (tokens[0] == "!loadmap") 
			{
				LoadMap(tokens[1]);
			}
			else if (tokens[0] == "!addTagHold") 
			{
				if (tokens.length > 2) {

					CBlob@ pb = player.getBlob();
					if (pb is null) return true;

					CBlob@ carried = pb.getCarriedBlob();
					if (carried is null) return true;

					carried.Tag(tokens[1]);
				}
			}
			else if (tokens[0] == "!addTag") 
			{
				if (tokens.length > 2) {
					CBlob@ pb = player.getBlob();
					if (pb is null) return true;

					pb.Tag(tokens[1]);
				}
			}
			else if (tokens[0] == "!morph") 
			{
				CBlob@ pb = player.getBlob();
				if (pb is null) return true;

				CBlob@ carried = pb.getCarriedBlob();
				if (carried is null) return true;

				carried.server_DetachFrom(pb);
				carried.server_SetPlayer(player);

				pb.Tag("dead");
				pb.server_Die();
			}
			else
			{
				if (tokens.length > 0)
				{
					string name = tokens[0].substr(1);

					CBlob@ newBlob = server_CreateBlob(name, blob.getTeamNum(), blob.getPosition());
					if (newBlob !is null && player !is null)
					{
						newBlob.SetDamageOwnerPlayer(player);

						int quantity;
						if (tokens.length > 1) quantity = parseInt(tokens[1]);
						else quantity = newBlob.maxQuantity;

						newBlob.server_SetQuantity(quantity);
					}
				}
			}
		}
		return false;
	}
	return true;
}

