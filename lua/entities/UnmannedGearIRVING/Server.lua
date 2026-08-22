DEFINE_BASECLASS "BaseActor"

if !CLASS_DESPERADO_WORLD_MARSHAL then Add_NPC_Class "CLASS_DESPERADO_WORLD_MARSHAL" end
ENT.iDefaultClass = CLASS_DESPERADO_WORLD_MARSHAL

ENT.bNightVision = true

ENT.vHullMins = Vector( -36, -36 )
ENT.vHullMaxs = Vector( 36, 36, 170 )
ENT.vHullDuckMins = ENT.vHullMins
ENT.vHullDuckMaxs = ENT.vHullMaxs

ENT.bCannotCarryWeapons = true

ENT.flVisionYaw = 120
ENT.flVisionPitch = 80

ENT.m_sIdleSequence = "idle"

local util_ScreenShake = util.ScreenShake

NOT_A_VOICELINE[ "Gekko/StepA.wav" ] = true
NOT_A_VOICELINE[ "Gekko/StepB.wav" ] = true

local function fChargeOStep( self ) util_ScreenShake( self:GetPos() + self:OBBCenter(), 6, 1, 1, 2048, true ) end

ENT.tSequenceEvents = {
	walk = {
		[ .411 ] = function( self )
			self:EmitSound "GekkoStepTiptoes"
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 1, 1, 1, 512, true )
		end,

		[ .911 ] = function( self )
			self:EmitSound "GekkoStepTiptoes"
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 1, 1, 1, 512, true )
		end
	},

	run = {
		[ .2 ] = function( self )
			self:EmitSound "GekkoStepJog"
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 4, 1, 1, 2048, true )
		end,

		[ .54 ] = function( self )
			self:EmitSound "GekkoStepJog"
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 4, 1, 1, 2048, true )
		end
	},

	stomp1 = {
		[ .4 ] = function( self )
			self:EmitSound "GekkoStepTiptoes"
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 1, 1, 1, 512, true )
		end
	},

	stomp2 = {
		[ .8 ] = function( self )
			self:EmitSound "GekkoStepTiptoes"
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 1, 1, 1, 512, true )
		end
	},

	att3_unstuck = {
		[ .58 ] = function( self )
			self:EmitSound "GekkoStepJog"
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 4, 1, 1, 2048, true )
		end,

		[ .8 ] = function( self )
			self:EmitSound "GekkoStepJog"
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 4, 1, 1, 2048, true )
		end
	},

	charge = {
		[ .2 ] = function( self ) self:EmitSound "GekkoStepCharge" fChargeOStep( self ) end,
		[ .54 ] = function( self ) self:EmitSound "GekkoStepCharge" fChargeOStep( self ) end
	},

	charge_start = {
		[ .2 ] = function( self ) self:EmitSound "GekkoStepCharge" fChargeOStep( self ) end,
		[ .54 ] = function( self ) self:EmitSound "GekkoStepCharge" fChargeOStep( self ) end
	},

	charge_end = {
		[ .2 ] = function( self ) self:EmitSound "GekkoStepCharge" fChargeOStep( self ) end,
		[ .54 ] = function( self ) self:EmitSound "GekkoStepCharge" fChargeOStep( self ) end
	}
}

function ENT:Initialize()
	self:SetHealth( 16384 )
	self:SetMaxHealth( 16384 )
	self:SetCollisionBounds( self.vHullMins, self.vHullMaxs )
	if self:PhysicsInitShadow( false, false ) then self:GetPhysicsObject():SetMass( 9072 ) end
	BaseClass.Initialize( self )
end

function ENT:OnLandOnGround()
	local vPos = self:GetPos()

	function self:GAME_OnHurtSomething( pEntity, dDamage )
		if self:Disposition( pEntity ) == D_LI then return true end
		local v = pEntity:GetPos()
		v:Add( pEntity:OBBCenter() )
		v:Sub( vPos )
		v:Normalize()
		v[ 3 ] = v[ 3 ] + math.Rand( .15, .3 )
		v = LerpVector( math.Rand( 0, .2 ), v, VectorRand() )
		v:Normalize()
		v:Mul( math.Rand( 760 * 85, 780 * 85 ) )
		dDamage:SetDamageForce( v )
		dDamage:SetDamage( 8192 )
		// I would use DMG_CRUSH, but some entities (let's not point fingers... anyway it was npc_antlionguard), for SOME REASON, completely ignore it!
		dDamage:SetDamageType( DMG_CLUB )
	end

	util.BlastDamage( self, self, vPos, self:BoundingRadius() * 2, 1 )
	util_ScreenShake( vPos, 8, 40, 1.5, 4096, true )
	self.GAME_OnHurtSomething = nil

	if math.random( 2 ) == 1 then
		for i = 1, 24 do self:EmitSound "GekkoStompA" end
	else
		for i = 1, 24 do self:EmitSound "GekkoStompA" end
	end

	self.sCallMeInRunBehaviour = "Land"
	self.fCallMeInRunBehaviour = function( self, MyTable )
		if !MyTable.bCharging then
			MyTable.AnimationSystemHalt( self, MyTable )
			MyTable.PlaySequenceAndWait( self, "land", math.Rand( .75, 1.5 ) )
		end
		return true
	end
end

local HEAD_BONE = "bone003"

ENT.aHeadAngles = Angle()
ENT.vHeadVelocity = Vector()

ENT.flHeadStiffness = 32
ENT.flHeadDamping = -8

ENT.flLastCustomBodyYaw = 0

function ENT:Think()
	self.m_sIdleSequence = self:IsOnGround() && "idle" || "jump"

	return BaseClass.Think( self )
end

function ENT:HandleTurning( MyTable )
	local iBoneID = self:LookupBone( HEAD_BONE )
	if iBoneID then
		local vPos, aAngles = self:GetBonePosition( iBoneID )

		local aDesAim

		local vShoot = vPos + aAngles:Up() * 80 - aAngles:Right() * 17

		local vaHeadTarget = self.vaAimTargetPose
		if isvector( vaHeadTarget ) then
			aDesAim = ( vaHeadTarget - vShoot ):Angle()
		elseif isangle( vaHeadTarget ) then
			aDesAim = vaHeadTarget
		else aDesAim = self:GetAngles() end

		local aCurrentAngles = self:GetAngles()
		aDesAim[ 1 ] = math.NormalizeAngle( aCurrentAngles[ 1 ] + math.Clamp( math.AngleDifference( aDesAim[ 1 ], aCurrentAngles[ 1 ] ), -90, 90 ) )

		local aHeadAngles = self.aHeadAngles
		aCurrentAngles:Add( aHeadAngles )

		local vHeadVelocity = self.vHeadVelocity
		vHeadVelocity:Add( Vector(
			math.AngleDifference( aDesAim[ 1 ], aCurrentAngles[ 1 ] ),
			math.AngleDifference( aDesAim[ 2 ], aCurrentAngles[ 2 ] )
		) * self.flHeadStiffness * FrameTime() )
		vHeadVelocity:Mul( math.exp( self.flHeadDamping * FrameTime() ) )

		aHeadAngles[ 1 ] = aHeadAngles[ 1 ] + vHeadVelocity[ 1 ] * FrameTime()
		aHeadAngles[ 2 ] = aHeadAngles[ 2 ] + vHeadVelocity[ 2 ] * FrameTime() - math.AngleDifference( self:GetAngles()[ 2 ], self.flLastCustomBodyYaw )

		self:ManipulateBoneAngles( iBoneID, Angle( aHeadAngles[ 2 ], 0, aHeadAngles[ 1 ] ) )

		self.flLastCustomBodyYaw = self:GetAngles()[ 2 ]
	end

	BaseClass.HandleTurning( self, MyTable )
end

function ENT:OnKilled( ... )
	if BaseClass.OnKilled( self, ... ) then return end
	self:Remove()
end

ENT.flTopSpeed = 512
ENT.flJogSpeed = ENT.flTopSpeed
ENT.flWalkSpeed = 96
ENT.flPowerWalkSpeed = 160
ENT.flJumpHeight = 2048

function ENT:MoveAlongPath( pPath, flSpeed, _, tFilter )
	local pLocomotion = self.loco
	pLocomotion:SetDesiredSpeed( flSpeed )
	local f = self.flTopSpeed * ACCELERATION_NORMAL
	pLocomotion:SetAcceleration( f )
	pLocomotion:SetDeceleration( f )
	pLocomotion:SetJumpHeight( self.flJumpHeight )
	local f = GetVelocity( self ):Length()
	if f <= 12 || !self:IsOnGround() then self:PromoteSequence( self.m_sIdleSequence )
	elseif f <= ( self.flWalkSpeed * 1.1 ) then
		self:PromoteSequence( "walk", GetVelocity( self ):Length() / self:GetSequenceGroundSpeed( self:LookupSequence "walk" ) )
	elseif f <= ( self.flPowerWalkSpeed * 1.1 ) then
		self:PromoteSequence( "walk", GetVelocity( self ):Length() / self:GetSequenceGroundSpeed( self:LookupSequence "walk" ) )
	else
		self:PromoteSequence( "run", GetVelocity( self ):Length() / self:GetSequenceGroundSpeed( self:LookupSequence "run" )  )
	end
	self:GrountMovement( pPath, flSpeed, tFilter )
end

function ENT:Stand() self.loco:SetJumpHeight( 1640 ) BaseClass.Stand( self ) end

// MOO!
function ENT:Taunt()
// Dumbass function name
//	function ENT:DoRoar()
	self.sCallMeInRunBehaviour = "Roar"
	self.fCallMeInRunBehaviour = function( self, MyTable )
		self.bTaunting = true
		timer.Simple( .8, function()
			if !IsValid( self ) then return end
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 8, 40, 2, 4096, true )
			self:EmitSound "GekkoTaunt"
		end )
		MyTable.AnimationSystemHalt( self, MyTable )
		MyTable.PlaySequenceAndWait( self, "taunt", 1 )
		return true
	end
end

// After playing some MGR, this is the animation that plays (I think)
// where the Gekko stomps, gets its foot stuck in the ground,
// you press F (yes, I play KBM... it's lowk easy, not sure what people complain about),
// Raiden jumps on it... AND you SOMEHOW fail the RMB QTE.
// IIRC from videos I've seen, the Gekko throws you away with this exact animation.
// That's also why the foot is near the head.
// So this CAN be brought back if we make an enemy which jumps at the IRVING's head... somewhy.
//	function ENT:DoShakeOff()
//		self.sCallMeInRunBehaviour = "ShakeOff"
//		self.fCallMeInRunBehaviour = function( self, MyTable )
//			self.bTaunting = true
//			timer.Simple( .33, function()
//				if !IsValid( self ) then return end
//				util_ScreenShake( self:GetPos() + self:OBBCenter(), 128, 10, 4, 4096, true )
//				self:EmitSound "GekkoTauntShakeOff"
//			end )
//			MyTable.AnimationSystemHalt( self, MyTable )
//			MyTable.PlaySequenceAndWait( self, "taunt2", 1 )
//			return true
//		end
//	end

// Our nervous system is heavily damaged, either from heat, or the enemy, and is not
// working correctly (see the calibration test below). We must wait for it to go back
// to normal before we can do anything again. Good thing is, the motors themselves
// have default motion oscillations and positions in which they go when we aren't giving commands,
// which avoids hardware damage and bad posture. Unlike AI Errors, this is an issue with our
// biological part, therefore we can still see and hear while in it.
ENT.flWrongLegPing = 0
RegisterSchedule( "GekkoBrainMachineInterfaceError", { Execute = function( self, sched, MyTable )
	if !sched.m_bInitialized then
		MyTable.AnimationSystemHalt( self, MyTable )
		MyTable.PlaySequenceAndWait( self, "stun_start", 1 )
		sched.m_bInitialized = true
	end
	// When our nervous system integrity is good enough, perform a calibration test by giving it a shake, to test
	// whether commands such as "turn the turret 10 degrees right" actually turn it 10 degrees, and not 5 or 20.
	// We sometimes shake off slower or faster intentionally, to make the enemy unsure if the BMI Error is resolved
	// NOTE: The calibration test is important! We sometimes estimate it incorrectly, as our nerves may be damaged!
	local flLegStatus, flWrongLegPing = MyTable.flLegStatus, MyTable.flWrongLegPing
	if flWrongLegPing <= 0 && math.random() <= math.Remap( flLegStatus ^ 3, 0, 1, .00001, 1 ) * FrameTime() then
		if flLegStatus >= 1 then
			MyTable.Schedule = nil
			MyTable.AnimationSystemHalt( self, MyTable )
			MyTable.PlaySequenceAndWait( self, "stun_end", math.Rand( .6, 1.4 ) )
		else
			// We did not pass the calibration test. To not overload the system and
			// set the motors into their idle mode, do not test again for some time
			// NOTE: Do NOT base the time until the next attempt on the nervous
			// system status! It will make us repeatedly check when we are almost
			// back to normal, and as such will significantly slow down the process!
			MyTable.flWrongLegPing = math.Rand( 2, 4 )
			MyTable.AnimationSystemHalt( self, MyTable )
			MyTable.PlaySequenceAndWait( self, "stun_end", math.random( 2 ) == 1 && math.Rand( 1 - flLegStatus * .8, 1 - flLegStatus * .6 ) || math.Rand( 1 + flLegStatus * .6, 1 + flLegStatus * .8 ) )
		end
		return
	end
	MyTable.flWrongLegPing = math.Clamp( flWrongLegPing - flLegStatus * FrameTime(), 0, 1 )
	MyTable.flLegStatus = math.Clamp( flLegStatus + .33 * FrameTime(), 0, 1 )
	// Don't ping the nervous system if we're unsure whether it already works!
	// It will automatically get into a stable posture and perform repeating
	// oscillations when it loses connection with us.
	MyTable.PromoteSequence( self, "stun", 1 )
	MyTable.Stand( self )
end } )

ENT.flLegStatus = 1

function ENT:OnTakeDamage( dDamage )
	dDamage:ScaleDamage( math.Remap( dDamage:GetDamage(), 0, self:Health(), .1, 1 / 3 ) )
	local flHealth = Lerp( .25, self:Health(), self:GetMaxHealth() )
	if dDamage:IsDamageType( DMG_CLUB ) then flHealth = flHealth * 24 end
	local f = math.Clamp( self.flLegStatus - dDamage:GetDamage() / flHealth * 4, 0, 1 )
	self.flLegStatus = f
	local pSchedule = self.Schedule
	if !( pSchedule && pSchedule.m_sName == "GekkoBrainMachineInterfaceError" ) then
		if self.flLegStatus <= math.Rand( 0, dDamage:GetDamage() / flHealth * 100 ) then self:SetSchedule "GekkoBrainMachineInterfaceError" end
	end
	return BaseClass.OnTakeDamage( self, dDamage )
end

include "Combat.lua"
include "InspectFirearm.lua"
