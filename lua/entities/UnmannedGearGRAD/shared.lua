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
		"GRAD/Shift1.wav",
		"GRAD/Shift2.wav",
		"GRAD/Shift3.wav",
		"GRAD/Shift4.wav"
	}
}

sound.Add {
	name = "UnmannedGearGRADTransformingMetal",
	channel = CHAN_STATIC,
	level = 110,
	pitch = { 80, 120 },
	sound = {
		"GRAD/Metal1.wav",
		"GRAD/Metal2.wav",
		"GRAD/Metal3.wav",
		"GRAD/Metal4.wav",
		"GRAD/Metal5.wav"
	}
}

sound.Add {
	name = "UnmannedGearGRADTransformingSetup",
	channel = CHAN_STATIC,
	level = 110,
	pitch = { 80, 120 },
	sound = {
		"GRAD/ShieldSetup1.wav",
		"GRAD/ShieldSetup2.wav"
	}
}

sound.Add {
	name = "UnmannedGearGRADTransformingChargeup",
	channel = CHAN_STATIC,
	level = 110,
	pitch = { 80, 120 },
	sound = "GRAD/Chargeup.wav"
}

sound.Add {
	name = "UnmannedGearGRADWalkShift",
	channel = CHAN_STATIC,
	level = 80,
	pitch = { 80, 120 },
	sound = {
		"GRAD/Shift1.wav",
		"GRAD/Shift2.wav",
		"GRAD/Shift3.wav",
		"GRAD/Shift4.wav"
	}
}

sound.Add {
	name = "UnmannedGearGRADWalkMetal",
	channel = CHAN_STATIC,
	level = 80,
	pitch = { 80, 120 },
	sound = {
		"GRAD/Metal1.wav",
		"GRAD/Metal2.wav",
		"GRAD/Metal3.wav",
		"GRAD/Metal4.wav",
		"GRAD/Metal5.wav"
	}
}

sound.Add {
	name = "UnmannedGearGRADMelee",
	channel = CHAN_STATIC,
	level = 120,
	pitch = { 70, 130 },
	sound = {
		"GRAD/Whoosh1.wav",
		"GRAD/Whoosh2.wav"
	}
}

sound.Add {
	name = "UnmannedGearGRADImpact",
	channel = CHAN_STATIC,
	level = 120,
	pitch = { 70, 130 },
	sound = {
		"GRAD/ShieldHit1.wav",
		"GRAD/ShieldHit2.wav",
		"GRAD/ShieldHit3.wav",
		"GRAD/ShieldHit4.wav"
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
		"GRAD/KordFire1.wav",
		"GRAD/KordFire2.wav",
		"GRAD/KordFire3.wav",
		"GRAD/KordFire4.wav",
		"GRAD/KordFire5.wav"
	}
}

sound.Add {
	name = "GRADSmallMissileFireShotgun",
	channel = CHAN_STATIC,
	level = 140,
	pitch = { 80, 120 },
	sound = {
		"^GRAD/SmallMissileFire1.wav",
		"^GRAD/SmallMissileFire2.wav",
		"^GRAD/SmallMissileFire3.wav",
		"^GRAD/SmallMissileFire4.wav"
	}
}

sound.Add {
	name = "GRADSmallMissileFireVolley",
	channel = CHAN_WEAPON,
	level = 140,
	pitch = { 80, 120 },
	sound = {
		"^GRAD/SmallMissileFire1.wav",
		"^GRAD/SmallMissileFire2.wav",
		"^GRAD/SmallMissileFire3.wav",
		"^GRAD/SmallMissileFire4.wav"
	}
}

// TODO: We REALLY need a better sound for this
sound.Add {
	name = "GRADCannonFire",
	channel = CHAN_STATIC,
	level = 150,
	pitch = { 90, 110 },
	sound = "weapons/mortar/mortar_fire1.wav"
}

function ENT:GetMuzzleFlashPosition( sMuzzleFlash )
	if sMuzzleFlash == "UnmannedGearGRAD76MMMuzzleFlash" then
		local iBoneID = self:LookupBone "bone010"
		if !iBoneID then return vector_origin end
		local vPos, aAngles = self:GetBonePosition( iBoneID )
		return vPos + aAngles:Up() * 73 + aAngles:Right() * 5
	end

	local iBoneID = self:LookupBone "bone056"
	if !iBoneID then return vector_origin end
	local vPos, aAngles = self:GetBonePosition( iBoneID )
	return vPos + aAngles:Up() * 57 - aAngles:Right() * 3.1
end

function ENT:GetMuzzleFlashAngles( sMuzzleFlash )
	if sMuzzleFlash == "UnmannedGearGRAD76MMMuzzleFlash" then
		local iBoneID = self:LookupBone "bone010"
		if !iBoneID then return angle_zero end
		local _, aAngles = self:GetBonePosition( iBoneID )
		return aAngles:Up():Angle()
	end

	return self:GetKordAngles()
end

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", "IsSliding" )
	self:NetworkVar( "Float", "SlideStrength" )
	self:NetworkVar( "Angle", "KordAngles" )
end

if SERVER then
	include "Server.lua"
	AddCSLuaFile "Slide.lua"
else include "Slide.lua" end
