AddCSLuaFile()
DEFINE_BASECLASS "UnmannedGearGekko"
ENT.Base = "UnmannedGearGekko"

scripted_ents.Register( ENT, "WorldMarshalUnmannedGearGekko" )

list.Set( "NPC", "WorldMarshalUnmannedGearGekko", {
	Name = "#WorldMarshalUnmannedGearGekko",
	Class = "WorldMarshalUnmannedGearGekko",
	Category = "World Marshal PMC"
} )

if !SERVER then return end

function ENT:Initialize()
	self:SetModel "models/linux55/mgr/linux55_cow.mdl"
	BaseClass.Initialize( self )
end
