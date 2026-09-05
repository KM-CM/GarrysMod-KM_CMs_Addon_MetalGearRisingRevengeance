AddCSLuaFile()
DEFINE_BASECLASS "UnmannedGearGRAD"

scripted_ents.Register( ENT, "WorldMarshalUnmannedGearGRAD" )

list.Set( "NPC", "WorldMarshalUnmannedGearGRAD", {
	Name = "#WorldMarshalUnmannedGearGRAD",
	Class = "WorldMarshalUnmannedGearGRAD",
	Category = "#WorldMarshal"
} )

if CLIENT then return end

function ENT:Initialize()
	self:SetSkin( 1 )
	BaseClass.Initialize( self )
end
