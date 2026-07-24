AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

scripted_ents.Register( ENT, "UnmannedGearGRAD" )

ENT.CATEGORIZE = { GRAD = true }

sound.Add {
	name = "UnmannedGearGRADTransformingShift",
	channel = CHAN_STATIC,
	level = 110,
	pitch = { 80, 120 },
	sound = {
		"dughoo_mgrr2025/grad/machinenoises1.wav",
		"dughoo_mgrr2025/grad/machinenoises2.wav",
		"dughoo_mgrr2025/grad/machinenoises3.wav",
		"dughoo_mgrr2025/grad/machinenoises4.wav"
	}
}

sound.Add {
	name = "UnmannedGearGRADTransformingMetal",
	channel = CHAN_STATIC,
	level = 110,
	pitch = { 80, 120 },
	sound = {
		"dughoo_mgrr2025/grad/metalbangsorstepsmaybe1.wav",
		"dughoo_mgrr2025/grad/metalbangsorstepsmaybe2.wav",
		"dughoo_mgrr2025/grad/metalbangsorstepsmaybe3.wav",
		"dughoo_mgrr2025/grad/metalbangsorstepsmaybe4.wav",
		"dughoo_mgrr2025/grad/metalbangsorstepsmaybe5.wav"
	}
}

sound.Add {
	name = "UnmannedGearGRADTransformingSetup",
	channel = CHAN_STATIC,
	level = 110,
	pitch = { 80, 120 },
	sound = {
		"dughoo_mgrr2025/grad/shield_setupmaybe1.wav",
		"dughoo_mgrr2025/grad/shield_setupmaybe2.wav"
	}
}

sound.Add {
	name = "UnmannedGearGRADTransformingChargeup",
	channel = CHAN_STATIC,
	level = 110,
	pitch = { 80, 120 },
	sound = "dughoo_mgrr2025/grad/chargeup.wav"
}

sound.Add {
	name = "UnmannedGearGRADWalkShift",
	channel = CHAN_STATIC,
	level = 80,
	pitch = { 80, 120 },
	sound = {
		"dughoo_mgrr2025/grad/machinenoises1.wav",
		"dughoo_mgrr2025/grad/machinenoises2.wav",
		"dughoo_mgrr2025/grad/machinenoises3.wav",
		"dughoo_mgrr2025/grad/machinenoises4.wav"
	}
}

sound.Add {
	name = "UnmannedGearGRADWalkMetal",
	channel = CHAN_STATIC,
	level = 80,
	pitch = { 80, 120 },
	sound = {
		"dughoo_mgrr2025/grad/metalbangsorstepsmaybe1.wav",
		"dughoo_mgrr2025/grad/metalbangsorstepsmaybe2.wav",
		"dughoo_mgrr2025/grad/metalbangsorstepsmaybe3.wav",
		"dughoo_mgrr2025/grad/metalbangsorstepsmaybe4.wav",
		"dughoo_mgrr2025/grad/metalbangsorstepsmaybe5.wav"
	}
}

sound.Add {
	name = "UnmannedGearGRADMelee",
	channel = CHAN_STATIC,
	level = 120,
	pitch = { 70, 130 },
	sound = {
		"dughoo_mgrr2025/grad/bigwhoosh1.wav",
		"dughoo_mgrr2025/grad/bigwhoosh2.wav"
	}
}

sound.Add {
	name = "UnmannedGearGRADImpact",
	channel = CHAN_STATIC,
	level = 120,
	pitch = { 70, 130 },
	sound = {
		"dughoo_mgrr2025/grad/shield_hit1.wav",
		"dughoo_mgrr2025/grad/shield_hit2.wav",
		"dughoo_mgrr2025/grad/shield_hit3.wav",
		"dughoo_mgrr2025/grad/shield_hit4.wav"
	}
}

sound.Add {
	name = "UnmannedGearGRADSkateLoop",
	channel = CHAN_STATIC,
	level = 120,
	sound = "physics/metal/canister_scrape_smooth_loop1.wav"
}

sound.Add {
	name = "KordFire",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = {
		"dughoo_mgrr2025/grad/gun_fire1.wav",
		"dughoo_mgrr2025/grad/gun_fire2.wav",
		"dughoo_mgrr2025/grad/gun_fire3.wav",
		"dughoo_mgrr2025/grad/gun_fire4.wav",
		"dughoo_mgrr2025/grad/gun_fire5.wav"
	}
}

function ENT:GetMuzzleFlashPosition( sMuzzleFlash )
	local iBoneID = self:LookupBone "bone055"
	if !iBoneID then return vector_origin end
	local vPos, aAngles = self:GetBonePosition( iBoneID )
	return vPos + aAngles:Up() * 80 - aAngles:Right() * 17
end

function ENT:GetMuzzleFlashAngles( sMuzzleFlash )
	local iBoneID = self:LookupBone "bone055"
	if !iBoneID then return angle_zero end
	local _, aAngles = self:GetBonePosition( iBoneID )
	return aAngles:Up():Angle()
end

if SERVER then include "Server.lua" end
