AddCSLuaFile()
DEFINE_BASECLASS "UnmannedGearGekko"
ENT.Base = "UnmannedGearGekko"

scripted_ents.Register( ENT, "DesperadoUnmannedGearGekko" )

list.Set( "NPC", "DesperadoUnmannedGearGekko", {
	Name = "#DesperadoUnmannedGearGekko",
	Class = "DesperadoUnmannedGearGekko",
	Category = "Desperado Enforcement LLC"
} )

if !SERVER then return end

function ENT:Initialize()
	self:SetModel "models/linux55/mgr/linux55_cow_desperado.mdl"
	BaseClass.Initialize( self )
end
