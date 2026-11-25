ENT.m_sIdleSequence = "idle"
ENT.m_sIdleSequenceAir = "jump"

ENT.flGravityMultiplierInAir = 3

function ENT:ForceTurnAroundLeft( MyTable )
	local f = math.Rand( .75, 1 )
	MyTable.flBoneActuatorsTime = math.max( MyTable.flBoneActuatorsTime, CurTime() + self:SequenceDuration( self:LookupSequence "turn_b" ) * f )
	MyTable.AnimationSystemHalt( self, MyTable )
	MyTable.PlaySequenceAndMove( self, "turn_b", -f, nil, function()
		MyTable.vaAimTargetBody = nil
		MyTable.Look( self, MyTable )
		MyTable.HandleTurning( self, MyTable )
	end, nil, -math.Rand( .75, 1.25 ), -math.Rand( .75, 1.25 ) )
end

function ENT:ForceTurnAroundRight( MyTable )
	local f = math.Rand( .75, 1 )
	MyTable.flBoneActuatorsTime = math.max( MyTable.flBoneActuatorsTime, CurTime() + self:SequenceDuration( self:LookupSequence "turn_b" ) * f )
	MyTable.AnimationSystemHalt( self, MyTable )
	MyTable.PlaySequenceAndMove( self, "turn_b", f, nil, function()
		MyTable.vaAimTargetBody = nil
		MyTable.Look( self, MyTable )
		MyTable.HandleTurning( self, MyTable )
	end, nil, math.Rand( .75, 1.25 ), math.Rand( .75, 1.25 ) )
end

function ENT:ForceTurn90Left( MyTable )
	local f = math.Rand( .75, 1 )
	MyTable.flBoneActuatorsTime = math.max( MyTable.flBoneActuatorsTime, CurTime() + self:SequenceDuration( self:LookupSequence "turn_l" ) * f )
	MyTable.AnimationSystemHalt( self, MyTable )
	MyTable.PlaySequenceAndMove( self, "turn_l", f, nil, function()
		MyTable.vaAimTargetBody = nil
		MyTable.Look( self, MyTable )
		MyTable.HandleTurning( self, MyTable )
	end, nil, math.Rand( .75, 1.2 ), math.Rand( .75, 1.2 ) )
end

function ENT:ForceTurn90Right( MyTable )
	local f = math.Rand( .75, 1 )
	MyTable.flBoneActuatorsTime = math.max( MyTable.flBoneActuatorsTime, CurTime() + self:SequenceDuration( self:LookupSequence "turn_r" ) * f )
	MyTable.AnimationSystemHalt( self, MyTable )
	MyTable.PlaySequenceAndMove( self, "turn_r", f, nil, function()
		MyTable.vaAimTargetBody = nil
		MyTable.Look( self, MyTable )
		MyTable.HandleTurning( self, MyTable )
	end, nil, math.Rand( .75, 1.2 ), math.Rand( .75, 1.2 ) )
end

ENT.flTopSpeed = 512
ENT.flJogSpeed = ENT.flTopSpeed
ENT.flWalkSpeed = 96
ENT.flPowerWalkSpeed = 140

ENT.flChargeSpeed = 820

ENT.flJumpHeight = 1536

ENT.flSpeedUpAnimationsTime = 0
ENT.flSpeedUpAnimationsWeight = 0

// TODO: Implement dynamic turning, I guess
function ENT:MoveAlongPath( pPath, flSpeed, flHeight, tFilter, bAllowSliding, flToleranceOverride, bNoAvoid, fJump, fDrop )
	local pLocomotion = self.loco
	pLocomotion:SetDesiredSpeed( flSpeed )
	local f = self.flTopSpeed * ACCELERATION_NORMAL
	pLocomotion:SetAcceleration( f )
	pLocomotion:SetDeceleration( f )
	pLocomotion:SetJumpHeight( self.flJumpHeight )

	local f = GetVelocity( self ):Length()
	local flMultiplier = 1
	if CurTime() <= self.flSpeedUpAnimationsTime then flMultiplier = 1 / ( 1 - self.flSpeedUpAnimationsWeight ) end

	if self:IsOnGround() then self.flBoneActuatorsTime = math.max( self.flBoneActuatorsTime, CurTime() + 1 / 3 ) end

	if f <= 12 || !self:IsOnGround() then
	elseif f <= ( self.flPowerWalkSpeed * 1.1 ) then
		self:PromoteSequence( "walk", GetVelocity( self ):Length() / self:GetSequenceGroundSpeed( self:LookupSequence "walk" ) * flMultiplier )
	else
		self:PromoteSequence( "run", GetVelocity( self ):Length() / self:GetSequenceGroundSpeed( self:LookupSequence "run" ) * flMultiplier )
	end

	self:GroundMovement( pPath, flSpeed, tFilter, flToleranceOverride, bNoAvoid, fJump, fDrop )
end

ENT.flBoneActuatorsTime = 0
ENT.flBoneActuatorsCurrent = 0

local vTemp = Vector()
local aTemp = Angle()

function ENT:ApplyGoddamnBonesFix()
	local flCurrent = math.Approach( self.flBoneActuatorsCurrent, CurTime() <= self.flBoneActuatorsTime && 1 || 0, 3 * FrameTime() )
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
