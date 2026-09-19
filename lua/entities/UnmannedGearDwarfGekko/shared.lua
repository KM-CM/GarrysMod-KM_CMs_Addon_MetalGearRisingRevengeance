AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

scripted_ents.Register( ENT, "UnmannedGearDwarfGekko" )

sound.Add {
	name = "DwarfGekkoImpact",
	channel = CHAN_AUTO,
	volume = 1,
	level = 90,
	pitch = { 90, 110 },
	sound = "Gekko/Dwarf/Slap.wav"
}

sound.Add {
	name = "DwarfGekkoZap",
	channel = CHAN_AUTO,
	volume = 1,
	level = 90,
	pitch = { 90, 110 },
	sound = {
		"ambient/energy/weld1.wav",
		"ambient/energy/weld2.wav"
	}
}

if SERVER then include "Server.lua" end
