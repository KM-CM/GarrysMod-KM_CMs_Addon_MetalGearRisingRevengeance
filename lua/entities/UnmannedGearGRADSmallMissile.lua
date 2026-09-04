AddCSLuaFile()
DEFINE_BASECLASS "BaseProjectile"

scripted_ents.Register( ENT, "UnmannedGearGRADSmallMissile" )

sound.Add {
	name = "GRADSmallMissileFizzleLoop",
	channel = CHAN_STATIC,
	level = 130,
	volume = .5,
	sound = "weapons/rpg/rocket1.wav"
}

sound.Add {
	name = "GRADSmallMissileDetonate",
	channel = CHAN_STATIC,
	level = 130,
	pitch = { 80, 120 },
	sound = {
		"^GRAD/SmallMissileDetonateA.wav",
		"^GRAD/SmallMissileDetonateB.wav"
	}
}

if CLIENT then return end

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
ENT.EXPLOSION_flDamage = 224
ENT.EXPLOSION_flRadius = 18

ENT.__PROJECTILE_ROCKET__ = true
ENT.ROCKET_flSpeed = 4096

local CEntity_GetPhysicsObject = CEntity.GetPhysicsObject
local CEntity_GetForward = CEntity.GetForward
local CEntity_GetTable = CEntity.GetTable
local CEntity_NextThink = CEntity.NextThink
local CurTime = CurTime
local CreateSound = CreateSound

function ENT:Think()
	local pPhys = CEntity_GetPhysicsObject( self )

	if !IsValid( pPhys ) then return end

	local MyTable = CEntity_GetTable( self )

	local pFizzleLoop = MyTable.m_pFizzleLoop
	if !pFizzleLoop then
		pFizzleLoop = CreateSound( self, "GRADSmallMissileFizzleLoop" )
		pFizzleLoop:PlayEx( 1, 175 )
		MyTable.m_pFizzleLoop = pFizzleLoop
	end

	local MyTable = CEntity_GetTable( self )
	local pEnemy = MyTable.m_pEnemy
	if IsValid( pEnemy ) then
		if self:Visible( pEnemy ) then
			local vEnemy = pEnemy:GetPos()
			vEnemy:Add( pEnemy:OBBCenter() )

			// TODO: Slowly steer towards vEnemy

			MyTable.m_vLastSeenEnemy = vEnemy
			MyTable.m_bSeekLastSeen = nil
		else
			// TODO: Slowly steer towards m_vLastSeenEnemy
			MyTable.m_bSeekLastSeen = true
		end
	elseif MyTable.m_bSeekLastSeen && MyTable.m_vLastSeenEnemy then
		// TODO: Slowly steer towards m_vLastSeenEnemy
	end

	// TODO: Proper acceleration, should also make the fizzle sound based on engine
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

	CEntity_EmitSound( self, "GRADSmallMissileDetonate" )

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

function ENT:OnRemove()
	local MyTable = CEntity_GetTable( self )
	local pFizzleLoop = MyTable.m_pFizzleLoop
	if pFizzleLoop then
		pFizzleLoop:Stop()
		MyTable.m_pFizzleLoop = nil
	end

	BaseClass.OnRemove( self )
end
