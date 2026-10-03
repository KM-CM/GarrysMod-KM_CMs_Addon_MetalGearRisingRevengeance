AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

scripted_ents.Register( ENT, "UnmannedMetalGearRAYMarkIII" )

sound.Add {
	name = "MetalGearRAYRoar",
	channel = CHAN_AUTO,
	level = 150,
	pitch = { 90, 110 },
	sound = {
		"^RAY/Roar1.wav",
		"^RAY/Roar2.wav",
		"^RAY/Roar3.wav",
		"^RAY/Roar4.wav"
	}
}

sound.Add {
	name = "MetalGearRAYShriek",
	channel = CHAN_AUTO,
	level = 150,
	pitch = { 90, 110 },
	sound = {
		"^RAY/Shriek1.wav",
		"^RAY/Shriek2.wav",
		"^RAY/Shriek3.wav"
	}
}

sound.Add {
	name = "MetalGearRAYWalkHydraulics",
	channel = CHAN_STATIC,
	level = 100,
	pitch = { 90, 110 },
	sound = {
		"^RAY/Hydraulics1.wav",
		"^RAY/Hydraulics2.wav",
		"^RAY/Hydraulics3.wav"
	}
}

sound.Add {
	name = "MetalGearRAYWalkStep",
	channel = CHAN_STATIC,
	level = 110,
	pitch = { 90, 110 },
	sound = {
		"^RAY/Step1.wav",
		"^RAY/Step2.wav"
	}
}

sound.Add {
	name = "MetalGearRAYLand",
	channel = CHAN_STATIC,
	level = 130,
	pitch = { 90, 110 },
	sound = {
		"^RAY/Land1.wav",
		"^RAY/Land2.wav",
		"^RAY/Land3.wav",
		"^RAY/Land4.wav"
	}
}

if SERVER then include "Server.lua" end
