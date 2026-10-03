DEFINE_BASECLASS "BaseActor"

if !CLASS_DESPERADO_WORLD_MARSHAL then Add_NPC_Class "CLASS_DESPERADO_WORLD_MARSHAL" end

ENT.iDefaultClass = CLASS_DESPERADO_WORLD_MARSHAL

ENT.m_sIdleSequence = "idle"

ENT.vHullMins = Vector( -200, -200, 0 )
ENT.vHullMaxs = Vector( 200, 200, 800 )

ENT.flBodyStiffness = 2
ENT.flBodyDamping = -8

ENT.flGravityMultiplierInAir = 2

ENT.bCannotCarryWeapons = true

ENT.flVisionYaw = 120
ENT.flVisionPitch = 80

local LEFT_FOOT_BONE = "bone032"
local RIGHT_FOOT_BONE = "bone043"

local Shake = util.ScreenShake

ENT.tSequenceEvents = {
	walk = {
		[ .16 ] = function( self, _, flWeight )
			if flWeight <= .75 then return end

			local vFoot = self:GetBonePosition( self:LookupBone( RIGHT_FOOT_BONE ) )

			local pData = EffectData()
			pData:SetOrigin( vFoot )
			pData:SetStart( GetVelocity( self ) )
			util.Effect( "MetalGearRAYWalkStep", pData )

			self.SOUND_vOrigin = vFoot
			self:EmitSound "MetalGearRAYWalkHydraulics"

			self.SOUND_vOrigin = vFoot
			self:EmitSound "MetalGearRAYWalkStep"

			local pData = EffectData()
			pData:SetOrigin( vFoot )
			util.Effect( "MetalGearRAYLandFoot", pData )

			function self:GAME_OnHurtSomething( pEntity, dDamage )
				if self:Disposition( pEntity ) == D_LI then return true end
				dDamage:SetDamage( 8192 )
				dDamage:SetDamageType( DMG_RAYLEIGH )
			end

			util.BlastDamage( self, self, vFoot, 128, 1 )
			Shake( vFoot, 16, 1, 1, 8192, true )
			self.GAME_OnHurtSomething = nil
		end,

		[ .7 ] = function( self, _, flWeight )
			if flWeight <= .75 then return end

			local vFoot = self:GetBonePosition( self:LookupBone( LEFT_FOOT_BONE ) )

			local pData = EffectData()
			pData:SetOrigin( vFoot )
			pData:SetStart( GetVelocity( self ) )
			util.Effect( "MetalGearRAYWalkStep", pData )

			self.SOUND_vOrigin = vFoot
			self:EmitSound "MetalGearRAYWalkHydraulics"

			self.SOUND_vOrigin = vFoot
			self:EmitSound "MetalGearRAYWalkStep"

			local pData = EffectData()
			pData:SetOrigin( vFoot )
			util.Effect( "MetalGearRAYLandFoot", pData )

			function self:GAME_OnHurtSomething( pEntity, dDamage )
				if self:Disposition( pEntity ) == D_LI then return true end
				dDamage:SetDamage( 8192 )
				dDamage:SetDamageType( DMG_RAYLEIGH )
			end

			util.BlastDamage( self, self, vFoot, 128, 1 )
			Shake( vFoot, 16, 1, 1, 8192, true )
			self.GAME_OnHurtSomething = nil
		end
	}
}

function ENT:Initialize()
	self:SetModel "models/ray.mdl"

	self:SetHealth( 131072 )
	self:SetMaxHealth( 131072 )

	self:SetCollisionBounds( self.vHullMins, self.vHullMaxs )

	if self:PhysicsInitShadow( false, false ) then self:GetPhysicsObject():SetMass( 505000 ) end

	self.aHeadAngles = Angle()
	self.vHeadVelocity = Vector()

	BaseClass.Initialize( self )
end

function ENT:OnLandOnGround()
	self.sCallMeInRunBehaviour = "Land"
	self.fCallMeInRunBehaviour = function( self, MyTable )
		if MyTable.bCharging then return end

		MyTable.AnimationSystemHalt( self, MyTable )

		local bLanded, bSmoked
		MyTable.PlaySequenceAndWait( self, "fly_end", math.Rand( .75, 1.25 ), nil, function( _, flCycle )
			if bSmoked || flCycle < .1 then return end

			if !bLanded then
				bLanded = true

				self:EmitSound "MetalGearRAYLand"
			end

			if flCycle < .12 then return end

			bSmoked = true

			local vFoot = self:GetBonePosition( self:LookupBone( LEFT_FOOT_BONE ) )

			local pData = EffectData()
			pData:SetOrigin( vFoot )
			util.Effect( "MetalGearRAYLandFoot", pData )

			function self:GAME_OnHurtSomething( pEntity, dDamage )
				if self:Disposition( pEntity ) == D_LI then return true end
				local v = pEntity:GetPos()
				v:Add( pEntity:OBBCenter() )
				v:Sub( vFoot )
				v:Normalize()
				v[ 3 ] = v[ 3 ] + math.Rand( .15, .3 )
				v = LerpVector( math.Rand( 0, .2 ), v, VectorRand() )
				v:Normalize()
				v:Mul( math.Rand( 760 * 85, 780 * 85 ) )
				dDamage:SetDamageForce( v )
				dDamage:SetDamage( 8192 )
				dDamage:SetDamageType( DMG_RAYLEIGH )
			end

			util.BlastDamage( self, self, vFoot, 512, 1 )
			Shake( vFoot, 8, 40, 1.5, 8192, true )
			self.GAME_OnHurtSomething = nil

			local vFoot = self:GetBonePosition( self:LookupBone( RIGHT_FOOT_BONE ) )

			function self:GAME_OnHurtSomething( pEntity, dDamage )
				if self:Disposition( pEntity ) == D_LI then return true end
				local v = pEntity:GetPos()
				v:Add( pEntity:OBBCenter() )
				v:Sub( vFoot )
				v:Normalize()
				v[ 3 ] = v[ 3 ] + math.Rand( .15, .3 )
				v = LerpVector( math.Rand( 0, .2 ), v, VectorRand() )
				v:Normalize()
				v:Mul( math.Rand( 760 * 85, 780 * 85 ) )
				dDamage:SetDamageForce( v )
				dDamage:SetDamage( 8192 )
				dDamage:SetDamageType( DMG_RAYLEIGH )
			end

			util.BlastDamage( self, self, vFoot, 512, 1 )
			Shake( vFoot, 8, 40, 1.5, 8192, true )
			self.GAME_OnHurtSomething = nil

			local pData = EffectData()
			pData:SetOrigin( vFoot )
			util.Effect( "MetalGearRAYLandFoot", pData )
		end )

		return true
	end
end

function ENT:Think()
	self.m_sIdleSequence = self:IsOnGround() && "idle" || "fly_loop"
end

ENT.flTopSpeed = 500
ENT.flJogSpeed = ENT.flTopSpeed
ENT.flPowerWalkSpeed = 500
ENT.flFastWalkSpeed = 320
ENT.flWalkSpeed = 280

// TODO: This REALLY needs root motion. Sadly, I have no idea how to implement it :(
function ENT:MoveAlongPath( pPath, flSpeed, _, tFilter )
	local pLocomotion = self.loco

	pLocomotion:SetDesiredSpeed( flSpeed )

	local flAccelDecel = self.flTopSpeed * 3
	pLocomotion:SetAcceleration( flAccelDecel )
	pLocomotion:SetDeceleration( flAccelDecel )
	pLocomotion:SetJumpHeight( self.flJumpHeight )

	local flVelocity = GetVelocity( self ):Length()
	if flVelocity <= 12 || !self:IsOnGround() then
	elseif flVelocity <= ( self.flTopSpeed * 1.1 ) then
		self.flWalkTime = CurTime() + .1
		self:PromoteSequence( "walk", flVelocity / self:GetSequenceGroundSpeed( self:LookupSequence "walk" ) )
	end
	
	self:GrountMovement( pPath, flSpeed, tFilter )
end

ENT.m_sDefaultCombatSchedule = "IntimidationWalk"
