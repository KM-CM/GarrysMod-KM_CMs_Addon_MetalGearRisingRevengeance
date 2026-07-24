AddCSLuaFile()
DEFINE_BASECLASS "UnmannedGearGRAD"
ENT.Base = "UnmannedGearGRAD"

scripted_ents.Register( ENT, "WorldMarshalUnmannedGearGRAD" )

list.Set( "NPC", "WorldMarshalUnmannedGearGRAD", {
	Name = "#WorldMarshalUnmannedGearGRAD",
	Class = "WorldMarshalUnmannedGearGRAD",
	Category = "#WorldMarshal"
} )

if !SERVER then return end

function ENT:Initialize()
	BaseClass.Initialize( self )
	self:SetSkin( 1 )
end
