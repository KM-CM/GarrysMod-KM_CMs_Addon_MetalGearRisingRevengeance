AddCSLuaFile()
DEFINE_BASECLASS "UnmannedGearIRVING"

scripted_ents.Register( ENT, "WorldMarshalUnmannedGearIRVING" )

list.Set( "NPC", "WorldMarshalUnmannedGearIRVING", {
	Name = "#WorldMarshalUnmannedGearIRVING",
	Class = "WorldMarshalUnmannedGearIRVING",
	Category = "#WorldMarshal"
} )

if !SERVER then return end

function ENT:Initialize()
	self:SetModel "models/linux55/mgr/linux55_cow.mdl"
	BaseClass.Initialize( self )
end
