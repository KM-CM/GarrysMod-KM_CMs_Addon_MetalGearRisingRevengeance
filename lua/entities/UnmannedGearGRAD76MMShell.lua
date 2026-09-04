AddCSLuaFile()
DEFINE_BASECLASS "BaseProjectile"

scripted_ents.Register( ENT, "UnmannedGearGRAD76MMShell" )

sound.Add {
	name = "GRADShellDetonate",
	channel = CHAN_STATIC,
	level = 150,
	pitch = { 80, 120 },
	sound = {
		"ambient/explosions/explode_1.wav",
		"ambient/explosions/explode_2.wav",
		"ambient/explosions/explode_4.wav"
	}
}

if CLIENT then
	local mMaterial = Material "effects/ar2_altfire1b"
	local COLOR = Color( 255, 128, 64 )

	local render_SetMaterial = render.SetMaterial
	local render_DrawSprite = render.DrawSprite

	local DynamicLight = DynamicLight

	local vTemp = Vector()
	local vTemp2 = Vector()

	function ENT:Draw()
		local vPos = self:GetPos()
		vPos:Add( self:OBBCenter() )
		local dDirection = self:GetForward()

		render_SetMaterial( mMaterial )

		local pLight = DynamicLight( self:EntIndex() )
		if pLight then
			pLight.pos = vPos
			pLight.r = 255
			pLight.g = 96
			pLight.b = 0
			pLight.brightness = 4
			pLight.decay = 1000
			pLight.size = 384
			pLight.dietime = CurTime() + 1
		end

		for i = 0, 40 do
			vTemp:Set( vPos )
			vTemp2:Set( dDirection )
			vTemp2:Mul( -i * 2 )
			vTemp:Sub( vTemp2 )

			local f = ( i / 40 ) ^ .5 * 24
			render_DrawSprite( vTemp, f, f, COLOR )
		end
	end

	return
end

local SOLID_VPHYSICS = SOLID_VPHYSICS
local ParticleEffectAttach = ParticleEffectAttach
local PATTACH_ABSORIGIN_FOLLOW = PATTACH_ABSORIGIN_FOLLOW

local CEntity = FindMetaTable "Entity"
local CEntity_SetModel = CEntity.SetModel
local CEntity_PhysicsInit = CEntity.PhysicsInit
local CEntity_SetHealth = CEntity.SetHealth
local CEntity_SetMaxHealth = CEntity.SetMaxHealth

function ENT:Initialize()
	CEntity_SetModel( self, "models/weapons/w_missile_launch.mdl" )
	CEntity_PhysicsInit( self, SOLID_VPHYSICS )
	CEntity_SetHealth( self, 128 )
	CEntity_SetMaxHealth( self, 128 )
end

ENT.__PROJECTILE_EXPLOSION__ = true
ENT.EXPLOSION_flDamage = 1600
ENT.EXPLOSION_flRadius = 84

ENT.__PROJECTILE_ROCKET__ = true
ENT.ROCKET_flSpeed = 16384

local CEntity_GetPhysicsObject = CEntity.GetPhysicsObject
local CEntity_GetForward = CEntity.GetForward
local CEntity_GetTable = CEntity.GetTable
local CEntity_NextThink = CEntity.NextThink
local CurTime = CurTime
local CreateSound = CreateSound

function ENT:Think()
	local pPhys = CEntity_GetPhysicsObject( self )

	if !IsValid( pPhys ) then return end

	pPhys:SetVelocity( CEntity_GetForward( self ) * CEntity_GetTable( self ).ROCKET_flSpeed )

	CEntity_NextThink( self, CurTime() )
	return true
end

local util_BlastDamage = util.BlastDamage
local CEntity_GetOwner = CEntity.GetOwner
local IsValid = IsValid
local ParticleEffect = ParticleEffect

local CEntity_GetPos = CEntity.GetPos
local CEntity_OBBCenter = CEntity.OBBCenter
local CEntity_EmitSound = CEntity.EmitSound
local CEntity_GetAngles = CEntity.GetAngles
local CEntity_EmitSound = CEntity.EmitSound
local CEntity_WaterLevel = CEntity.WaterLevel
local CEntity_Remove = CEntity.Remove
local util_Effect = util.Effect

function ENT:Detonate( MyTable )
	MyTable = MyTable || CEntity_GetTable( self )

	if MyTable.bDetonated then return end

	local vPos = CEntity_GetPos( self )

	local vCenter = CEntity_OBBCenter( self )
	vCenter:Add( vPos )

	local pOwner = GetOwner( self )

	CEntity_EmitSound( self, "GRADShellDetonate" )

	local flMagnitude = MyTable.flMagnitude
	local flDistance = MyTable.EXPLOSION_flRadius

	util_BlastDamage( self, pOwner, self:GetPos(), flDistance, MyTable.EXPLOSION_flDamage )

	// TODO: Explosion effects

	MyTable.bDetonated = true

	CEntity_Remove( self )
end

function ENT:PhysicsCollide()
	local MyTable = CEntity_GetTable( self )
	MyTable.Detonate( self, MyTable )
end

local CEntity_Health = CEntity.Health

function ENT:OnTakeDamage( dDamage )
	local MyTable = CEntity_GetTable( self )
	if MyTable.bDead then return 0 end
	local f = CEntity_Health( self ) - dDamage:GetDamage()
	CEntity_SetHealth( self, f )
	if f <= 0 then MyTable.bDead = true MyTable.Detonate( self, MyTable ) return 0 end
end
