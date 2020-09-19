/*
	SM DM weapons by time

	Copyright (C) 2017-2018 Francisco 'Franc1sco' García

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <colorvariables>


#define PLUGIN_VERSION "2.3.1"

char sConfig[PLATFORM_MAX_PATH];
Handle kv;
//int iColor[4] =  { 0, 0, 0, 100 };

char armas[64];

Menu menu_weapons = null;

Handle g_hTimer[MAXPLAYERS + 1] = INVALID_HANDLE;

char g_arma[MAXPLAYERS + 1][64];
bool g_show[MAXPLAYERS + 1];
bool g_random[MAXPLAYERS + 1];

int g_contador;

Handle g_weapons, g_flags, g_types;

int g_iTiempo = 0;

int g_iTiempoHS = 0;

ConVar cv_hs;

ConVar cv_everytime, cv_everytime_hs, cv_everytime_hs_duration, cv_countdown;

public Plugin:myinfo = 
{
	name = "SM DM weapons by time",
	author = "Franc1sco franug",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/franug"
}

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_start", Event_Start);
	
	AddCommandListener(Event_Say, "say");
	AddCommandListener(Event_Say, "say_team");
	
	AddCommandListener(BlockCommand, "drop");
	
	cv_everytime = CreateConVar("sm_weaponsbytime_duration", "5", "Duration for each stage in minutes by default");
	cv_everytime_hs = CreateConVar("sm_weaponsbytime_hs", "6", "Every X minutes, enable only hs");
	cv_everytime_hs_duration = CreateConVar("sm_weaponsbytime_hsduration", "2", "Duration in minutes for only hs");
	cv_countdown = CreateConVar("sm_weaponsbytime_countdown", "10", "Start a countdown in the chat when only X seconds for next weapons. (0 = disabled)");
	
	g_weapons = CreateArray(64);
	g_types = CreateArray(64);
	g_flags = CreateArray(12);
	
	CreateTimer(1.0, Timer_Change, _, TIMER_REPEAT);
	
	cv_hs = FindConVar("mp_damage_headshot_only");
}

public Action BlockCommand(int client, const char[] command, int argc)
{
	PrintCenterText(client, "You cant drop your weapon on DM!");
	return Plugin_Handled;
}

public Action Event_Say(int client, const char[] command, int argc)
{
	static char menuTriggers[][] = { "gun", "!gun", "/gun", "guns", "!guns", "/guns", "menu", "!menu", "/menu", "weapon", "!weapon", "/weapon", "weapons", "!weapons", "/weapons" };

	char text[24];
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);
	TrimString(text);

	for(int i = 0; i < sizeof(menuTriggers); i++)
	{
			if (StrEqual(text, menuTriggers[i], false))
			{
				DisplayMenu(menu_weapons, client, 0);
				return Plugin_Handled;
			}
	}
	return Plugin_Continue;
}

public OnMapStart()
{
	g_iTiempoHS = 0;
	g_contador = 0;
	GetTypes();
	SetConVarBool(cv_hs, false);
	GetArrayString(g_types, g_contador, armas, 64);
	MontarMenu();
}

public void Event_Start(Event event, const char[] name, bool dontBroadcast)
{
	g_iTiempoHS = 0;
	g_contador = 0;
	GetTypes();
	SetConVarBool(cv_hs, false);
	GetArrayString(g_types, g_contador, armas, 64);
	MontarMenu();
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	CloseTimer(client);
	g_hTimer[client] = CreateTimer(0.0, GiveWeapons, client);
}

public Action GiveWeapons(Handle timer, any client)
{
	g_hTimer[client] = INVALID_HANDLE;
	if(!IsPlayerAlive(client))
		return;
	
	StripAllPlayerWeapons(client);
	if(!GetConVarBool(cv_hs)) GivePlayerItem(client, "weapon_knife");
	
	if (g_random[client])Aleatorio(client);
	else GivePlayerItem(client, g_arma[client]);
	
	//PrintToChat(client, "dado %s", g_arma[client]);
	if(!IsFakeClient(client) && g_show[client]) DisplayMenu(menu_weapons, client, 0);
}

public OnClientPostAdminCheck(client)
{
	g_show[client] = true;
	g_random[client] = true;
}

public Action Timer_Change(Handle hTimer)
{
	g_iTiempo++;
	g_iTiempoHS++;
	
	bool bhs = GetConVarBool(cv_hs);
	
	char thetime[128];
	
	//char sBuffer[128];
	
	if(!bhs)
	{
		if(g_iTiempoHS >= GetConVarInt(cv_everytime_hs)*60)
		{
			g_iTiempoHS = 0;
		
			SetConVarBool(cv_hs, true);
			
			bhs = true;
			
			PrintCenterTextAll("Only HS: Enabled!");
			
		}
	}
	else if(g_iTiempoHS >= GetConVarInt(cv_everytime_hs_duration)*60)
	{
		g_iTiempoHS = 0;
		
		SetConVarBool(cv_hs, false);
		
		PrintCenterTextAll("Only HS: Disabled!");
		
		bhs = false;
	}
	
	if(g_iTiempo < 60*GetConVarInt(cv_everytime))
	{
		int countdown = GetConVarInt(cv_countdown);
		
		if(countdown != 0)
		{
			int faltan = (60 * GetConVarInt(cv_everytime)) - g_iTiempo;
			
			if(faltan <= countdown)
				CPrintToChatAll("{red}Next weapons in: %i seconds", faltan);
		}
		
		ShowTimer(60*GetConVarInt(cv_everytime)-g_iTiempo, thetime, sizeof(thetime));
		
		char armas2[64];
		GetArrayString(g_types, g_contador+1>=GetArraySize(g_types)?0:g_contador+1, armas2, 64);
		int weapon;
		for (int i = 1; i <= MaxClients; i++) 
			if (IsClientInGame(i) && GetClientTeam(i) > 1)
			{
				if(IsPlayerAlive(i))
				{
					if(bhs)
					{
						while((weapon = GetPlayerWeaponSlot(i, CS_SLOT_KNIFE)) != -1)
						{
							RemovePlayerItem(i, weapon);
							AcceptEntityInput(weapon, "Kill");
						}
					}
					else if(GetPlayerWeaponSlot(i, CS_SLOT_KNIFE) == -1)
						GivePlayerItem(i, "weapon_knife");
					
				}
				// SetHudTextParamsEx(-1.0, 0.9, 1.1, iColor, {0, 0, 0, 100}, 0, 0.0, 0.0, 0.0);
				// Format(sBuffer, sizeof(sBuffer), "Next weapons in: %s", thetime);
				// ShowHudText(i, 3, sBuffer);
				
				//SetHudTextParamsEx(-1.0, 0.88, 1.1, iColor, {0, 0, 0, 100}, 0, 0.0, 0.0, 0.0);
				//Format(sBuffer, sizeof(sBuffer), "Only HS: %s", bhs?"Enabled":"Disabled");
				//ShowHudText(i, 4, sBuffer);
				
				if(!IsFakeClient(i))
					PrintHintText(i, "Current: %s\n%s in: %s\nOnly HS: %s",armas, armas2,  thetime, bhs ? "Enabled":"Disabled");
			}
		return;
		
	}
	
	g_contador++;
	if (g_contador >= GetArraySize(g_types))g_contador = 0;
	
	GetArrayString(g_types, g_contador, armas, 64);
	MontarMenu();
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
		{
			g_random[i] = true;
			g_show[i] = true;
			StripAllPlayerWeapons(i);
			
			if(!GetConVarBool(cv_hs)) GivePlayerItem(i, "weapon_knife");
			Aleatorio(i);
			
			if(!IsFakeClient(i)){
				CancelClientMenu(i);
				DisplayMenu(menu_weapons, i, 0);
			}
		}
}

Aleatorio(client)
{
	int suerte = GetRandomInt(0, GetArraySize(g_weapons) - 1);
	
	char weapons[64];
	
	GetArrayString(g_weapons, suerte, weapons, 64);
	
	GivePlayerItem(client, weapons);
}

MontarMenu()
{
	g_iTiempo = 0;
	BuildPath(Path_SM, sConfig, PLATFORM_MAX_PATH, "configs/franug_dmweapons.txt");
	
	if(kv != INVALID_HANDLE) CloseHandle(kv);
	
	kv = CreateKeyValues("weapons");
	FileToKeyValues(kv, sConfig);
	
			
	char nombre[64], entidad[64], tipo[64];
	
	if(menu_weapons != null)
		CloseHandle(menu_weapons);
	
	menu_weapons = new Menu(Menu_Handler);
	
	ClearArray(g_weapons);
	ClearArray(g_flags);
	int time;
	char flags[12];
	SetMenuTitle(menu_weapons, armas);
	AddMenuItem(menu_weapons, "no", "Dont show more");
	AddMenuItem(menu_weapons, "random", "Random");
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			KvGetSectionName(kv, nombre, 64);
			KvGetString(kv, "weapontype", tipo, 64);
			KvGetString(kv, "flags", flags, 12, "");
			KvGetString(kv, "weaponentity", entidad, 64);
			time = KvGetNum(kv, "time", 0);
			if(StrEqual(tipo, armas))
			{
				if(time != 0)
					SetConVarInt(cv_everytime, time);
				
				if(!StrEqual(flags, "", false))
					Format(nombre, 64, "%s (VIP)", nombre);
					
				AddMenuItem(menu_weapons, entidad, nombre);
				PushArrayString(g_weapons, entidad);
				PushArrayString(g_flags, flags);
			}
			
		} while (KvGotoNextKey(kv));
	}
	KvRewind(kv);
	SetMenuExitBackButton(menu_weapons, true);
}

GetTypes()
{	
	BuildPath(Path_SM, sConfig, PLATFORM_MAX_PATH, "configs/franug_dmweapons.txt");
	
	if(kv != INVALID_HANDLE) CloseHandle(kv);
	
	kv = CreateKeyValues("weapons");
	FileToKeyValues(kv, sConfig);
	
	char tipo[64];
	ClearArray(g_types);
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			KvGetString(kv, "weapontype", tipo, 64);
			
			if(FindStringInArray(g_types, tipo) == -1)
			{
				PushArrayString(g_types, tipo);
			}	
		} while (KvGotoNextKey(kv));
	}
	KvRewind(kv);
}

public int Menu_Handler(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{

			char item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			
			if(StrEqual(item, "no"))
				g_show[client] = false;
			else if (StrEqual(item, "random")) g_random[client] = true;
			else{
				
				char flags[12];
				GetArrayString(g_flags, FindStringInArray(g_weapons, item), flags, 12);
				if(!HasPermission(client, flags))
				{
					PrintToChat(client, "You dont have access to use this weapon!");
					
					DisplayMenuAtItem(menu_weapons, client, GetMenuSelectionPosition(), 0);
					return;
				}
				
				
				g_random[client] = false;
				strcopy(g_arma[client], 64, item);
			}
			
			PrintToChat(client, "The changes are applied in the next spawn");
		}

	}
}

public void OnClientDisconnect(int client)
{
	CloseTimer(client);
}

public void CloseTimer(int client)
{
	if (g_hTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTimer[client]);
		g_hTimer[client] = INVALID_HANDLE;
	}
}

stock void StripAllPlayerWeapons(int client)
{
	int weapon;
	for (int i = 0; i <= 5; i++)
	{
		while ((weapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, weapon);
			AcceptEntityInput(weapon, "Kill");
		}
	}
}

int ShowTimer(int Time, char[] buffer,int sizef)
{
	int g_iHours = 0;
	int g_iMinutes = 0;
	int g_iSeconds = Time;
	
	while(g_iSeconds > 3600)
	{
		g_iHours++;
		g_iSeconds -= 3600;
	}
	while(g_iSeconds >= 60)
	{
		g_iMinutes++;
		g_iSeconds -= 60;
	}
	if(g_iHours >= 1)
	{
		if(g_iMinutes == 0 && g_iSeconds == 0) Format(buffer, sizef, "%d hour%s", g_iHours);
		else if(g_iMinutes > 0 && g_iSeconds == 0) Format(buffer, sizef, "%d h %d min", g_iHours, g_iMinutes);
		else Format(buffer, sizef, "%d h %d min %d sec", g_iHours, g_iMinutes, g_iSeconds);
	}
	else if(g_iMinutes >= 1)
	{
		if(g_iSeconds == 0)
			Format(buffer, sizef, "%d min", g_iMinutes);
		else Format(buffer, sizef, "%d min %d sec", g_iMinutes, g_iSeconds);
	}
	else
	{
		Format(buffer, sizef, "%d sec", g_iSeconds);
	}
}

stock bool HasPermission(int iClient, char[] flagString) 
{
	if (StrEqual(flagString, "")) 
	{
		return true;
	}
	
	AdminId admin = GetUserAdmin(iClient);
	
	if (admin != INVALID_ADMIN_ID)
	{
		int count, found, flags = ReadFlagString(flagString);
		for (int i = 0; i <= 20; i++) 
		{
			if (flags & (1<<i)) 
			{
				count++;
				
				if (GetAdminFlag(admin, view_as<AdminFlag>(i))) 
				{
					found++;
				}
			}
		}

		if (count == found) {
			return true;
		}
	}

	return false;
} 