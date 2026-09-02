// Purpose: cow
// See TM 9-2350-274-10 Operator's Manual for Unmanned Infantry Fighting Vehicle, IRVING for more information
// (That thing is my headcanon and doesn't exist lmfao)

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

// Keep these soundlevels semi low as there's no far sound variation
sound.Add {
	name = "GekkoStompA",
	channel = CHAN_STATIC,
	volume = 1,
	level = 120,
	pitch = 100,
	sound = "physics/concrete/concrete_break2.wav"
}
sound.Add {
	name = "GekkoStompB",
	channel = CHAN_STATIC,
	volume = 1,
	level = 120,
	pitch = { 90, 100 },
	sound = "physics/concrete/concrete_break3.wav"
}

sound.Add {
	name = "GekkoJump",
	channel = CHAN_STATIC,
	volume = 1,
	level = 130,
	pitch = { 90, 110 },
	sound = "^Gekko/Jump.wav"
}

sound.Add {
	name = "GekkoLand",
	channel = CHAN_STATIC,
	volume = 1,
	level = 140,
	pitch = { 90, 110 },
	sound = "^Gekko/Jump.wav"
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
	channel = CHAN_STATIC,
	volume = 1,
	level = 120,
	pitch = { 90, 110 },
	sound = {
		"^Gekko/Taunt/1.wav",
		"^Gekko/Taunt/2.wav",
		"^Gekko/Taunt/3.wav",
		"^Gekko/Taunt/4.wav",
		"^Gekko/Taunt/5.wav",
		"^Gekko/Taunt/6.wav",
		"^Gekko/Taunt/7.wav"
	}
}

sound.Add {
	name = "GekkoDistressed",
	channel = CHAN_STATIC,
	volume = 1,
	level = 120,
	pitch = { 90, 100 },
	sound = {
		"^Gekko/DistressA.wav",
		"^Gekko/DistressB.wav"
	}
}

sound.Add {
	name = "GekkoStepTiptoes",
	channel = CHAN_STATIC,
	volume = 1,
	level = 80,
	pitch = { 90, 110 },
	sound = {
		"Gekko/HooveA.wav",
		"Gekko/HooveB.wav",
		"Gekko/HooveC.wav"
	}
}

sound.Add {
	name = "GekkoStepJog",
	channel = CHAN_STATIC,
	volume = 1,
	level = 100,
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
	name = "GekkoDodgeJump",
	channel = CHAN_STATIC,
	level = 110,
	pitch = { 90, 110 },
	sound = {
		"^Gekko/StepA.wav",
		"^Gekko/StepB.wav"
	}
}

sound.Add {
	name = "GekkoDodgeLand",
	channel = CHAN_STATIC,
	level = 90,
	pitch = { 90, 110 },
	sound = {
		"Gekko/HooveA.wav",
		"Gekko/HooveB.wav",
		"Gekko/HooveC.wav"
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

sound.Add {
	name = "GekkoChirpLoop",
	channel = CHAN_STATIC,
	level = 120,
	sound = "^Gekko/ChirpLoop.wav"
}

if SERVER then include "Server.lua" end
