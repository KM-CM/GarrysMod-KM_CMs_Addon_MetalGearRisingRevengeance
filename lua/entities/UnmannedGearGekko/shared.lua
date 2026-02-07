// Purpose: cow (couldn't help myself, sorry xD)

AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

scripted_ents.Register( ENT, "UnmannedGearGekko" )

ENT.CATEGORIZE = { Gekko = true }

// NOTE: This MUST be cutoff by GekkoTaunt, or it sounds ass
sound.Add {
	name = "GekkoPreTaunt",
	channel = CHAN_VOICE,
	volume = 1,
	level = 150,
	pitch = { 20, 30 },
	sound = {
		"^Gekko/Taunt/1.wav",
		"^Gekko/Taunt/2.wav",
		"^Gekko/Taunt/3.wav"
	}
}

sound.Add {
	name = "GekkoTaunt",
	channel = CHAN_VOICE,
	volume = 1,
	level = 150,
	pitch = { 90, 110 },
	sound = {
		"^Gekko/Taunt/1.wav",
		"^Gekko/Taunt/2.wav",
		"^Gekko/Taunt/3.wav"
	}
}

sound.Add {
	name = "GekkoShakeOffTaunt",
	channel = CHAN_VOICE,
	volume = 1,
	level = 150,
	pitch = { 60, 70 },
	sound = {
		"^Gekko/Taunt/1.wav",
		"^Gekko/Taunt/2.wav",
		"^Gekko/Taunt/3.wav"
	}
}

sound.Add {
	name = "GekkoImpact",
	channel = CHAN_AUTO,
	volume = 1,
	level = 150,
	pitch = { 90, 100 },
	sound = {
		"^Gekko/ImpactA.wav",
		"^Gekko/ImpactB.wav"
	}
}

sound.Add {
	name = "GekkoCharge",
	channel = CHAN_AUTO,
	volume = 1,
	level = 150,
	pitch = { 90, 100 },
	sound = {
		"^Gekko/ChargeA.wav",
		"^Gekko/ChargeB.wav"
	}
}

sound.Add {
	name = "GekkoStep",
	channel = CHAN_STATIC,
	volume = 1,
	level = 80,
	pitch = { 90, 110 },
	sound = {
		"drgbase/mgr/l55/vc/step1.wav",
		"drgbase/mgr/l55/vc/step2.wav"
	}
}

sound.Add {
	name = "GekkoLand",
	channel = CHAN_STATIC,
	volume = 1,
	level = 100,
	pitch = { 90, 110 },
	sound = {
		"drgbase/mgr/l55/vc/step1.wav",
		"drgbase/mgr/l55/vc/step2.wav"
	}
}

if SERVER then include "Server.lua" end
