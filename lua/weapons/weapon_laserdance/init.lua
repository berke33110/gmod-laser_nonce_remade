AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
 
include("shared.lua")
 
SWEP.Weight = 5
SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom = true

resource.AddFile("weapons/laserdance/echo1.wav");

util.AddNetworkString("LaserDanceHeal")