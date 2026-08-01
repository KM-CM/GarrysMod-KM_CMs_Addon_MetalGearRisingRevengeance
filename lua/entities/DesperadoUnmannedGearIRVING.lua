AddCSLuaFile()
DEFINE_BASECLASS "UnmannedGearIRVING"

scripted_ents.Register( ENT, "DesperadoUnmannedGearIRVING" )

list.Set( "NPC", "DesperadoUnmannedGearIRVING", {
	Name = "#DesperadoUnmannedGearIRVING",
	Class = "DesperadoUnmannedGearIRVING",
	Category = "#DesperadoEnforcementLLC"
} )

if !SERVER then return end

function ENT:Initialize()
	self:SetModel "models/linux55/mgr/linux55_cow_desperado.mdl"
	BaseClass.Initialize( self )
end
