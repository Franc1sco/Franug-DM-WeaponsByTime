/*
	SM DM weapons by time

	Copyright (C) 2017 Francisco 'Franc1sco' García

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
#include <sdktools>

#define EVERYTIME 5 // 4

#define EVERYTIME_HS 6 // 6
#define EVERYTIME_HS_DURATION 2 // 2

#define PLUGIN_VERSION "1.0"

char sConfig[PLATFORM_MAX_PATH];
Handle kv;
int iColor[4] =  { 0, 0, 0, 100 };

char armas[64];

Menu menu_weapons = null;

Handle g_hTimer[MAXPLAYERS + 1] = INVALID_HANDLE;

char g_arma[MAXPLAYERS + 1][64];
bool g_show[MAXPLAYERS + 1];
bool g_random[MAXPLAYERS + 1];

int g_contador;

Handle g_weapons;

int g_iTiempo = 0;

int g_iTiempoHS = 0;

ConVar cv_hs;

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
	
	g_weapons = CreateArray(64);
	
	CreateTimer(1.0, Timer_Change, _, TIMER_REPEAT);
	
	cv_hs = FindConVar("mp_damage_headshot_only");
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
	g_contador = 1;
	SetConVarBool(cv_hs, false);
	strcopy(armas, 64, "Pistol");
	MontarMenu();
}

public void Event_Start(Event event, const char[] name, bool dontBroadcast)
{
	g_iTiempoHS = 0;
	g_contador = 1;
	SetConVarBool(cv_hs, false);
	strcopy(armas, 64, "Pistol");
	MontarMenu();
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	CloseTimer(client);
	g_hTimer[client] = CreateTimer(0.5, GiveWeapons, client);
}

public Action GiveWeapons(Handle timer, any client)
{
	g_hTimer[client] = INVALID_HANDLE;
	if(!IsPlayerAlive(client))
		return;
		
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
	
	char sBuffer[128], thetime[128];
	
	if(!bhs)
	{
		if(g_iTiempoHS >= EVERYTIME_HS*60)
		{
			g_iTiempoHS = 0;
		
			SetConVarBool(cv_hs, true);
			
			PrintCenterTextAll("Only HS: Enabled!");
		}
	}
	else if(g_iTiempoHS >= EVERYTIME_HS_DURATION*60)
	{
		g_iTiempoHS = 0;
		
		SetConVarBool(cv_hs, false);
		
		PrintCenterTextAll("Only HS: Disabled!");
	}
	
	if(g_iTiempo < 60*EVERYTIME)
	{
		ShowTimer(60*EVERYTIME-g_iTiempo, thetime, sizeof(thetime));
		
		
		for (int i = 1; i <= MaxClients; i++) 
			if (IsClientInGame(i) && GetClientTeam(i) > 1 && !IsFakeClient(i))
			{
				
				SetHudTextParamsEx(-1.0, 0.9, 1.1, iColor, {0, 0, 0, 100}, 0, 0.0, 0.0, 0.0);
				Format(sBuffer, sizeof(sBuffer), "Next weapons in: %s", thetime);
				ShowHudText(i, 3, sBuffer);
				
				SetHudTextParamsEx(-1.0, 0.88, 1.1, iColor, {0, 0, 0, 100}, 0, 0.0, 0.0, 0.0);
				Format(sBuffer, sizeof(sBuffer), "Only HS: %s", bhs?"Enabled":"Disabled");
				ShowHudText(i, 4, sBuffer);
			}
		return;
		
	}
	
	g_contador++;
	if (g_contador > 6)g_contador = 1;
	
	switch (g_contador)
	{
		case 1:
			Format(armas, 64, "Pistol");
		case 2:
			Format(armas, 64, "Shotgun");
		case 3:
			Format(armas, 64, "SMG");
		case 4:
			Format(armas, 64, "Rifle");
		case 5:
			Format(armas, 64, "Sniper");
		case 6:
			Format(armas, 64, "Machine Gun");
		default:
			Format(armas, 64, "Pistol");
		
	}
	
	MontarMenu();
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
		{
			g_random[i] = true;
			g_show[i] = true;
			StripAllPlayerWeapons(i);
			GivePlayerItem(i, "weapon_knife");
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
	
	SetMenuTitle(menu_weapons, armas);
	AddMenuItem(menu_weapons, "no", "Dont show more");
	AddMenuItem(menu_weapons, "random", "Random");
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			KvGetSectionName(kv, nombre, 64);
			KvGetString(kv, "weapontype", tipo, 64);
			KvGetString(kv, "weaponentity", entidad, 64);
			if(StrEqual(tipo, armas))
			{
				AddMenuItem(menu_weapons, entidad, nombre);
				PushArrayString(g_weapons, entidad);
			}
			
		} while (KvGotoNextKey(kv));
	}
	KvRewind(kv);
	SetMenuExitBackButton(menu_weapons, true);
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
		if(g_iMinutes == 0 && g_iSeconds == 0) Format(buffer, sizef, "%d hour%s", g_iHours,g_iHours!=1?"s":"");
		else if(g_iMinutes > 0 && g_iSeconds == 0) Format(buffer, sizef, "%d hour%s and %d minute%s", g_iHours,g_iHours!=1?"s":"", g_iMinutes,g_iMinutes!=1?"s":"");
		else Format(buffer, sizef, "%d hour%s, %d minute%s and %d second%s", g_iHours,g_iHours!=1?"s":"", g_iMinutes,g_iMinutes!=1?"s":"", g_iSeconds,g_iSeconds!=1?"s":"");
	}
	else if(g_iMinutes >= 1)
	{
		if(g_iSeconds == 0)
			Format(buffer, sizef, "%d minute%s", g_iMinutes,g_iMinutes!=1?"s":"");
		else Format(buffer, sizef, "%d minute%s and %d second%s", g_iMinutes,g_iMinutes!=1?"s":"", g_iSeconds,g_iSeconds!=1?"s":"");
	}
	else
	{
		Format(buffer, sizef, "%d second%s", g_iSeconds,g_iSeconds!=1?"s":"");
	}
}