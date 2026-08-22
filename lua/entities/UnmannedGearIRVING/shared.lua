// Purpose: cow

AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

scripted_ents.Register( ENT, "UnmannedGearIRVING" )

ENT.CATEGORIZE = { Gekko = true, IRVING = true }

sound.Add {
	name = "GekkoImpact",
	channel = CHAN_AUTO,
	volume = 1,
	level = 120,
	pitch = { 90, 100 },
	sound = {
		"^Gekko/ImpactA.wav",
		"^Gekko/ImpactB.wav"
	}
}

sound.Add {
	name = "GekkoStompA",
	channel = CHAN_STATIC,
	volume = 1,
	level = 140,
	pitch = 100,
	sound = "physics/concrete/concrete_break2.wav"
}

sound.Add {
	name = "GekkoStompB",
	channel = CHAN_STATIC,
	volume = 1,
	level = 140,
	pitch = { 90, 100 },
	sound = "physics/concrete/concrete_break3.wav"
}

sound.Add {
	name = "GekkoSwing",
	channel = CHAN_STATIC,
	volume = 1,
	level = 120,
	pitch = { 90, 110 },
	sound = {
		"^Gekko/SwingA.wav",
		"^Gekko/SwingB.wav"
	}
}

sound.Add {
	name = "GekkoTaunt",
	channel = CHAN_VOICE,
	volume = 1,
	level = 120,
	pitch = { 90, 110 },
	sound = {
		"^Gekko/Taunt/1.wav",
		"^Gekko/Taunt/2.wav",
		"^Gekko/Taunt/3.wav"
	}
}

sound.Add {
	name = "GekkoCombatLow",
	channel = CHAN_VOICE,
	volume = .5,
	level = 120,
	pitch = { 60, 110 },
	sound = {
		"^Gekko/Taunt/1.wav",
		"^Gekko/Taunt/2.wav",
		"^Gekko/Taunt/3.wav"
	}
}

sound.Add {
	name = "GekkoCharge",
	channel = CHAN_AUTO,
	volume = 1,
	level = 120,
	pitch = { 90, 100 },
	sound = {
		"^Gekko/ChargeA.wav",
		"^Gekko/ChargeB.wav"
	}
}

sound.Add {
	name = "GekkoStepTiptoes",
	channel = CHAN_STATIC,
	volume = .3,
	level = 80,
	pitch = { 90, 110 },
	sound = {
		"^Gekko/StepA.wav",
		"^Gekko/StepB.wav"
	}
}

sound.Add {
	name = "GekkoStepJog",
	channel = CHAN_STATIC,
	volume = 1,
	level = 90,
	pitch = { 90, 110 },
	sound = {
		"^Gekko/StepA.wav",
		"^Gekko/StepB.wav"
	}
}
sound.Add {
	name = "GekkoStepCharge",
	channel = CHAN_STATIC,
	volume = 1,
	level = 110,
	pitch = { 90, 110 },
	sound = {
		"^Gekko/StepA.wav",
		"^Gekko/StepB.wav"
	}
}

sound.Add {
	name = "GekkoAngry",
	channel = CHAN_VOICE,
	volume = 1,
	level = 140,
	pitch = { 90, 110 },
	sound = {
		"^Gekko/AngryA.wav",
		"^Gekko/AngryB.wav"
	}
}

sound.Add {
	name = "GekkoAck",
	channel = CHAN_VOICE,
	volume = 1,
	level = 100,
	pitch = { 75, 100 },
	sound = {
		"^Gekko/Ack/1.wav",
		"^Gekko/Ack/2.wav",
		"^Gekko/Ack/3.wav",
		"^Gekko/Ack/4.wav"
	}
}

if SERVER then include "Server.lua" end
