ENT.m_sIdleSequence = "idle"
ENT.m_sIdleSequenceAir = "jump"

ENT.flGravityMultiplierInAir = 3

ENT.vHullMins = Vector( -30, -30 )
ENT.vHullMaxs = Vector( 30, 30, 150 )

function ENT:ForceTurnAroundLeft( MyTable )
	MyTable.flBoneActuatorsTime = 0
	MyTable.AnimationSystemHalt( self, MyTable )
	local f = -math.Rand( .8, 1.2 )
	MyTable.PlaySequenceAndMove( self, "turn_b", -math.Rand( .75, 1 ), nil, function()
		MyTable.vaAimTargetBody = nil
		MyTable.Look( self, MyTable )
		MyTable.HandleTurning( self, MyTable )
	end, nil, f, f )
end

function ENT:ForceTurnAroundRight( MyTable )
	MyTable.flBoneActuatorsTime = 0
	MyTable.AnimationSystemHalt( self, MyTable )
	local f = math.Rand( .8, 1.2 )
	MyTable.PlaySequenceAndMove( self, "turn_b", math.Rand( .75, 1 ), nil, function()
		MyTable.vaAimTargetBody = nil
		MyTable.Look( self, MyTable )
		MyTable.HandleTurning( self, MyTable )
	end, nil, f, f )
end

function ENT:ForceTurnLeft( MyTable )
	MyTable.flBoneActuatorsTime = 0
	MyTable.AnimationSystemHalt( self, MyTable )
	local f = math.Rand( .8, 1.2 )
	MyTable.PlaySequenceAndMove( self, "turn_l", math.Rand( .75, 1 ), nil, function()
		MyTable.vaAimTargetBody = nil
		MyTable.Look( self, MyTable )
		MyTable.HandleTurning( self, MyTable )
	end, nil, f, f )
end

function ENT:ForceTurnRight( MyTable )
	local f = math.Rand( .75, 1 )
	MyTable.flBoneActuatorsTime = 0
	MyTable.AnimationSystemHalt( self, MyTable )
	local f = math.Rand( .8, 1.2 )
	MyTable.PlaySequenceAndMove( self, "turn_r", math.Rand( .75, 1 ), nil, function()
		MyTable.vaAimTargetBody = nil
		MyTable.Look( self, MyTable )
		MyTable.HandleTurning( self, MyTable )
	end, nil, f, f )
end

ENT.flTopSpeed = 313.5
ENT.flJogSpeed = ENT.flTopSpeed
ENT.flWalkSpeed = 120
ENT.flFasterWalkSpeed = 135
ENT.flPowerWalkSpeed = 150

ENT.flChargeSpeed = 500

ENT.flJumpHeight = 1536

ENT.flSpeedUpAnimationsTime = 0
ENT.flSpeedUpAnimationsWeight = 0

// TODO: Implement dynamic turning, I guess
function ENT:MoveAlongPath( pPath, flSpeed, flHeight, tFilter, bAllowSliding, flToleranceOverride, bNoAvoid, fJump, fDrop )
	local pLocomotion = self.loco

	pLocomotion:SetJumpHeight( self.flJumpHeight )

	local f = GetVelocity( self ):Length()
	local flMultiplier = 1
	if CurTime() <= self.flSpeedUpAnimationsTime then flMultiplier = 1 / ( 1 - self.flSpeedUpAnimationsWeight ) end

	if self:IsOnGround() then self.flBoneActuatorsTime = math.max( self.flBoneActuatorsTime, CurTime() + .2 ) end

	if !self:IsOnGround() then
	elseif flSpeed <= ( self.flPowerWalkSpeed * 1.1 ) then
		self:DoRootMotion( "walk", flSpeed * flMultiplier )
	else
		self:DoRootMotion( "run", flSpeed * flMultiplier )
	end

	self:GroundMovement( pPath, tFilter, flToleranceOverride, bNoAvoid, fJump, fDrop )
end

ENT.flBoneActuatorsTime = 0
ENT.flBoneActuatorsCurrent = 0

local vTemp = Vector()
local aTemp = Angle()

function ENT:ApplyGoddamnBonesFix()
	local flCurrent = math.Approach( self.flBoneActuatorsCurrent, CurTime() <= self.flBoneActuatorsTime && 1 || 0, 4 * FrameTime() )
	self.flBoneActuatorsCurrent = flCurrent

	local i = self:LookupBone "bone081"
	aTemp[ 1 ] = 0
	aTemp[ 2 ] = 0
	aTemp[ 3 ] = -10 * flCurrent
	self:ManipulateBoneAngles( i, aTemp )

	local i = self:LookupBone "bone049"
	aTemp[ 1 ] = 0
	aTemp[ 2 ] = 0
	aTemp[ 3 ] = -10 * flCurrent
	self:ManipulateBoneAngles( i, aTemp )

	local i = self:LookupBone "bone083"
	aTemp[ 1 ] = 0
	aTemp[ 2 ] = 0
	aTemp[ 3 ] = 40 * flCurrent
	self:ManipulateBoneAngles( i, aTemp )

	local i = self:LookupBone "bone051"
	aTemp[ 1 ] = 0
	aTemp[ 2 ] = 0
	aTemp[ 3 ] = 40 * flCurrent
	self:ManipulateBoneAngles( i, aTemp )

	local i = self:LookupBone "bone004"
	aTemp[ 1 ] = 0
	aTemp[ 2 ] = 0
	aTemp[ 3 ] = -30 * flCurrent
	self:ManipulateBoneAngles( i, aTemp )
	vTemp[ 1 ] = 1
	vTemp[ 2 ] = 1
	vTemp[ 3 ] = 1 - .5 * flCurrent
	self:ManipulateBoneScale( i, vTemp )
	vTemp[ 1 ] = 0
	vTemp[ 2 ] = -5 * flCurrent
	vTemp[ 3 ] = -5 * flCurrent
	self:ManipulateBonePosition( i, vTemp )
	local i = self:LookupBone "bone005"
	aTemp[ 1 ] = 0
	aTemp[ 2 ] = 0
	aTemp[ 3 ] = 32 * flCurrent
	self:ManipulateBoneAngles( i, aTemp )

	local i = self:LookupBone "bone000"
	aTemp[ 1 ] = 0
	aTemp[ 2 ] = 0
	aTemp[ 3 ] = -22.5 * flCurrent
	self:ManipulateBoneAngles( i, aTemp )

	local flMove = 0

	local iLayer = self.tSequences.walk
	if iLayer then flMove = flMove + self:GetLayerWeight( iLayer ) end
	
	local iLayer = self.tSequences.run
	if iLayer then flMove = flMove + self:GetLayerWeight( iLayer ) end

	vTemp[ 1 ] = 0
	vTemp[ 2 ] = 0
	vTemp[ 3 ] = ( 20 - flMove * 7 ) * flCurrent
	self:ManipulateBonePosition( i, vTemp )
end
