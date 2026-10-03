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
	level = 120,
	pitch = 100,
	sound = "physics/concrete/concrete_break2.wav"
}
sound.Add {
	name = "GekkoStompB",
	channel = CHAN_STATIC,
	level = 120,
	pitch = { 90, 100 },
	sound = "physics/concrete/concrete_break3.wav"
}

sound.Add {
	name = "GekkoJump",
	channel = CHAN_STATIC,
	level = 90,
	pitch = { 90, 110 },
	sound = "^Gekko/Jump.wav"
}

sound.Add {
	name = "GekkoLand",
	channel = CHAN_STATIC,
	level = 110,
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
	level = 120,
	pitch = { 90, 110 },
	sound = {
		"Gekko/Taunt1.wav",
		"Gekko/Taunt2.wav",
		"Gekko/Taunt3.wav",
		"Gekko/Taunt4.wav",
		"Gekko/Taunt5.wav",
		"Gekko/Taunt6.wav",
		"Gekko/Taunt7.wav",
		"Gekko/Taunt8.wav",
		"Gekko/Taunt9.wav"
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
	level = 100,
	pitch = { 75, 100 },
	sound = {
		"^Gekko/Ack1.wav",
		"^Gekko/Ack2.wav",
		"^Gekko/Ack3.wav",
		"^Gekko/Ack4.wav"
	}
}

sound.Add {
	name = "GekkoChirpLoop",
	channel = CHAN_STATIC,
	level = 120,
	sound = "^Gekko/ChirpLoop.wav"
}

sound.Add {
	name = "GekkoMachineGunFire",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "weapons/smg1/smg1_fire1.wav"
}

function ENT:GetMuzzleFlashPosition( sMuzzleFlash )
	local vPos, aAngles = self:GetBonePosition( self:LookupBone "bone006" )
	return vPos + aAngles:Up() * 47 + aAngles:Right() * -12 + aAngles:Forward() * 2.7
end

function ENT:GetMuzzleFlashAngles( sMuzzleFlash )
	return self:GetMachineGunAngles()
end

function ENT:SetupDataTables()
	self:NetworkVar( "Angle", "MachineGunAngles" )
end

if SERVER then include "Server.lua" end
