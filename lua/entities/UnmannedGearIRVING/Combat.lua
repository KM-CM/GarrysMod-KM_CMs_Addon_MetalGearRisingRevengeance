function ENT:OhBoyItsTimeToJump( pEnemy, MyTable, fOnComplete )
	local vIntercept = MyTable.InterceptJump( self, pEnemy, nil, MyTable.flJumpHeight )

	if !vIntercept then return end

	vIntercept:Sub( self:GetPos() )

	local pSchedule = MyTable.SetSchedule( self, "GekkoInterceptJump", MyTable )
	pSchedule.aLook = vIntercept:Angle()
	pSchedule.fOnComplete = fOnComplete
end

function ENT:Taunt( pEnemy, MyTable )
	local flMultiplier = math.Rand( .75, 1.1 )

	timer.Simple( .8 / flMultiplier, function()
		if !IsValid( self ) then return end
		util.ScreenShake( self:GetPos() + self:OBBCenter(), 8, 40, 2, 4096, true )
		self:EmitSound "GekkoTaunt"
	end )

	MyTable.AnimationSystemHalt( self, MyTable )

	MyTable.PlaySequenceAndWait( self, "taunt", flMultiplier, nil, function()
		MyTable.vaAimTargetBody = nil

		if IsValid( pEnemy ) then MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter() end

		MyTable.Look( self, MyTable )
		MyTable.HandleTurning( self, MyTable )

		if IsActiveDefenseAction( MyTable.HandleDefense( self, MyTable ) ) then
			return true
		end
	end )
end

local util_ScreenShake = util.ScreenShake

function ENT:DoChargeDamageInternal( pSchedule, MyTable, pTrueEnemy )
	local pHit = pSchedule.pHit
	if !pHit then
		pHit = {}
		pSchedule.pHit = pHit
	end

	local flVelocity = GetVelocity( self ):Length()

	local vMins, vMaxs = Vector( MyTable.vHullMins ), Vector( MyTable.vHullMaxs )

	vMins[ 1 ] = vMins[ 1 ] * .8
	vMins[ 2 ] = vMins[ 2 ] * .8
	vMaxs[ 1 ] = vMaxs[ 1 ] * .8
	vMaxs[ 2 ] = vMaxs[ 2 ] * .8

	vMins[ 3 ] = vMins[ 3 ] + 24

	local f, flNextHitSound, bStop = self:BoundingRadius(), 0
	if util.TraceHull( {
		start = self:GetPos(),
		endpos = self:GetPos() + self:GetForward() * 64,
		mins = vMins,
		maxs = vMaxs,
		filter = function( pEntity )
			if pHit[ pEntity ] then return false end
			pHit[ pEntity ] = true

			if IsBullshitNonSolidEntity( pEntity ) then return false end

			if MyTable.Disposition( self, pEntity, MyTable ) == D_LI then return false end

			if !bStop then
				if IsValid( pTrueEnemy ) && pEntity == pTrueEnemy then bStop = true end

				if pEntity:BoundingRadius() > f then bStop = true end
			end

			local dDamage = DamageInfo()
			dDamage:SetAttacker( self )
			dDamage:SetDamageType( DMG_CLUB )
			local flSpeed = GetVelocity( self ):Length()
			local flFraction = flSpeed / self.flChargeSpeed
			dDamage:SetDamage( flFraction * 8192 )
			local v = pEntity:GetPos()
			v:Add( pEntity:OBBCenter() )
			v:Sub( self:GetPos() )
			v:Sub( self:OBBCenter() )
			v:Normalize()
			v[ 3 ] = v[ 3 ] + math.Rand( .15, .3 )
			v = LerpVector( math.Rand( 0, .5 ), v, VectorRand() )
			v:Normalize()
			v:Mul( flFraction * math.Rand( flVelocity * 2 / 3 * 85, flVelocity * 85 + 512 * 85 ) )
			dDamage:SetDamageForce( v )
			pEntity:TakeDamageInfo( dDamage )

			if CurTime() > flNextHitSound then
				util_ScreenShake( self:GetPos() + self:OBBCenter(), 10, 15, 2, 4096, true )
				self:EmitSound "GekkoImpact"
			end

			return false
		end
	} ).HitWorld && !pSchedule.bHitWorld then
		util_ScreenShake( self:GetPos() + self:OBBCenter(), 16, 15, 4, 4096, true )
		bStop = true
		pSchedule.bHitWorld = true
	end

	return bStop
end

function ENT:EndChargeInternal( pSchedule, MyTable )
	MyTable.AnimationSystemHalt( self, MyTable )
	MyTable.PlaySequenceAndMove( self, "charge_end", math.Rand( .75, 1.25 ), nil, function( _, flCycle )
		if flCycle > .2 && IsActiveDefenseAction( MyTable.HandleDefense( self, MyTable ) ) then
			return true
		end

		if flCycle < .95 then
			MyTable.DoChargeDamageInternal( self, pSchedule, MyTable )
		end
	end )
end

ENT.sChargeSchedule = "GekkoCharge"
ENT.flChargeTimeMin = 10
ENT.flChargeTimeMax = 20
// Keep speeds all in one back at Server.lua
RegisterSchedule( "GekkoCharge", { Execute = function( self, pSchedule, MyTable )
	MyTable.flOverrideBodyStiffnessThisTick = 16
	MyTable.flOverrideBodyDampingThisTick = 8

	local pEnemy = MyTable.Enemy

	if !IsValid( pEnemy ) then
		if pSchedule.m_bInitialized then MyTable.EndChargeInternal( self, pSchedule, MyTable ) end
		return true
	end

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then pEnemyPath = Path "Follow" MyTable.pEnemyPath = pEnemyPath end

	MyTable.ManageFlankPath( self, pEnemyPath, pEnemy, pSchedule, MyTable )

	if !pSchedule.m_bInitialized then
		if !IsValid( pEnemy ) then return true end

		pSchedule.m_bInitialized = true

		local bInterrupt

		timer.Simple( math.Rand( 0, self:SequenceDuration( self:LookupSequence "charge_start" ) ), function()
			if !IsValid( self ) && !bInterrupt then return end
			if math.random( 3 ) == 1 then MyTable.LowIfAvailable( self, MyTable ) end
		end )

		MyTable.AnimationSystemHalt( self, MyTable )

		MyTable.PlaySequenceAndMove( self, "charge_start", 1, nil, function( _, flCycle )
			MyTable.m_flDontTurnHeadTime = CurTime() + .1

			if IsValid( pEnemy ) then
				MyTable.vaAimTargetBody = pEnemy:GetPos() + pEnemy:OBBCenter()
				MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
			end

			MyTable.Look( self, MyTable )
			MyTable.HandleTurning( self, MyTable )

			if IsActiveDefenseAction( MyTable.HandleDefense( self, MyTable ) ) then
				bInterrupt = true
				return true
			end
		end )

		if bInterrupt then
			local f = pSchedule.fOnInterrupt
			if f && f( self, pSchedule, MyTable ) then return end
			return true
		end

		local flDuration = math.Rand( MyTable.flChargeTimeMin, MyTable.flChargeTimeMax )
		pSchedule.flDuration = flDuration
		pSchedule.flEndTime = CurTime() + flDuration

		if IsValid( pEnemy ) && math.random( 4 ) == 1 && MyTable.IsInterceptJumpLegalShort( self, pEnemy, MyTable.flJumpHeight ) then
			MyTable.OhBoyItsTimeToJump( self, pEnemy, MyTable, MyTable.fOnComplete )
			return
		elseif math.random( 4 ) == 1 then
			pSchedule.flJumpChance = math.Rand( .08, .2 )
		else pSchedule.flJumpChance = math.Rand( .04, .08 ) end
	end

	if !IsValid( pEnemy ) then
		MyTable.EndChargeInternal( self, pSchedule, MyTable )
		return true
	end

	if CurTime() > pSchedule.flEndTime then
		MyTable.EndChargeInternal( self, pSchedule, MyTable )

		local f = pSchedule.fOnComplete
		if f && f( self, pSchedule, MyTable ) then return end

		return true
	end

	if math.random() <= pSchedule.flJumpChance * MyTable.m_flFrameTime && MyTable.IsInterceptJumpLegal( self, pEnemy, MyTable.flJumpHeight ) then
		MyTable.OhBoyItsTimeToJump( self, pEnemy, MyTable, MyTable.fOnComplete )
		return
	end

	MyTable.m_flDontTurnHeadTime = CurTime() + .1

	local pEnemy, pTrueEnemy = self:SetupEnemy( pEnemy )
	local f = self:BoundingRadius()
	f = f * f
	local v = self:GetPos()
	if pEnemy.__ACTOR_BULLSEYE__ && v:DistToSqr( pEnemy:NearestPoint( v ) ) <= f && ( pEnemy == pTrueEnemy || pTrueEnemy:NearestPoint( pEnemy:GetPos() ):DistToSqr( pEnemy:GetPos() ) > f ) then
		self:ReportPositionAsClear( pEnemy:GetPos() )
		MyTable.EndChargeInternal( self, pSchedule, MyTable )
		return
	end

	local pLocomotion = MyTable.loco
	pLocomotion:SetDesiredSpeed( 1 )
	pLocomotion:SetAcceleration( 1 )
	pLocomotion:SetDeceleration( 1 )
	pLocomotion:SetJumpHeight( 512 )

	local flSpeed = MyTable.flChargeSpeed
	local v = GetVelocity( self )

	MyTable.PromoteSequenceInstant( self, "charge", flSpeed / self:GetSequenceGroundSpeed( self:LookupSequence "charge" ) )

	pEnemyPath:MoveCursorToClosestPosition( self:GetPos() )

	pEnemyPath:MoveCursor( self:OBBMaxs()[ 1 ] * 5 )

	MyTable.vaAimTargetBody = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() )

	local vVelocity = self:GetForward() * flSpeed
	vVelocity[ 3 ] = v[ 3 ]
	pLocomotion:SetVelocity( vVelocity )

	MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()

	self:GroundMovement( pEnemyPath, flSpeed, tFilter )

	bStop = MyTable.DoChargeDamageInternal( self, pSchedule, MyTable, pTrueEnemy )

	if bStop then
		MyTable.EndChargeInternal( self, pSchedule, MyTable )

		local f = pSchedule.fOnComplete
		if f && f( self, pSchedule, MyTable ) then return end

		return true
	end
end } )

// TODO: Maybe implement the actual 360 cartwheel?
// This has a very interesting, very sloppy hitbox xD
RegisterSchedule( "GekkoAttackRoundhouse", { Execute = function( self, pSchedule, MyTable )
	local pEnemy, pTrueEnemy = MyTable.Enemy

	if IsValid( pEnemy ) then
		local pE, pTE = self:SetupEnemy( pEnemy )
		pEnemy, pTrueEnemy = pE, pTE
		local f = self:BoundingRadius()
		f = f * f
		local v = self:GetPos()
		if pEnemy.__ACTOR_BULLSEYE__ && v:DistToSqr( pEnemy:NearestPoint( v ) ) <= f && ( pEnemy == pTrueEnemy || pTrueEnemy:NearestPoint( pEnemy:GetPos() ):DistToSqr( pEnemy:GetPos() ) > f ) then
			self:ReportPositionAsClear( pEnemy:GetPos() )
			return
		end
	end

	MyTable.AnimationSystemHalt( self, MyTable )

	local sWarmupSequence = "att1_1"
	local flWarmupMultiplier = math.Rand( .75, 1 )

	local sSequence = "att1_2"
	local flMultiplier = math.Rand( .4, .45 )

	MyTable.MELEE_flStart = CurTime()
	MyTable.MELEE_flHit = CurTime() + self:SequenceDuration( sWarmupSequence ) / flWarmupMultiplier + .1 / flMultiplier
	MyTable.MELEE_flEnd = CurTime() + self:SequenceDuration( sWarmupSequence ) / flWarmupMultiplier + self:SequenceDuration( sSequence ) / flMultiplier
	MyTable.MELEE_flDamage = 4096 / flMultiplier
	MyTable.MELEE_fvStart = function( self ) return self:GetPos() end
	MyTable.MELEE_fvEnd = function( self ) return self:GetPos() + self:GetForward() * 80 end

	local vMins, vMaxs = Vector( MyTable.vHullMins ), Vector( MyTable.vHullMaxs )
	local flModelScale = self:GetModelScale()
	vMins:Mul( flModelScale )
	vMaxs:Mul( flModelScale )
	vMins[ 1 ] = vMins[ 1 ] * 2
	vMins[ 2 ] = vMins[ 2 ] * 2
	vMaxs[ 1 ] = vMaxs[ 1 ] * 2
	vMaxs[ 2 ] = vMaxs[ 2 ] * 2
	vMins[ 1 ] = vMins[ 1 ] + 24

	MyTable.MELEE_fvMins = function() return vMins end
	MyTable.MELEE_fvMaxs = function() return vMaxs end

	local bInterrupt

	MyTable.PlaySequenceAndMove( self, sWarmupSequence, flWarmupMultiplier, true, function()
		MyTable.Look( self, MyTable )

		if IsActiveDefenseAction( MyTable.HandleDefense( self, MyTable ) ) then
			bInterrupt = true
			return true
		end
	end )

	if bInterrupt then
		local f = pSchedule.fOnInterrupt
		if f && f( self, pSchedule, MyTable ) then return end
		return true
	end

	timer.Simple( .1 / flMultiplier, function()
		local bHit
		if !IsValid( self ) then return end
		/*if */util.TraceHull( {
			start = self:GetPos(),
			endpos = self:GetPos() + self:GetForward() * 80 * flModelScale,
			mins = vMins,
			maxs = vMaxs,
			filter = function( pEntity )
				if IsBullshitNonSolidEntity( pEntity ) then return false end
				if MyTable.Disposition( self, pEntity, MyTable ) == D_LI then return false end
				local dDamage = DamageInfo()
				dDamage:SetAttacker( self )
				dDamage:SetDamageType( DMG_CLUB )
				dDamage:SetDamage( 4096 / flMultiplier )
				local v = pEntity:GetPos()
				v:Add( pEntity:OBBCenter() )
				v:Sub( self:GetPos() )
				v:Normalize()
				v[ 3 ] = v[ 3 ] + math.Rand( .15, .3 )
				v = LerpVector( math.Rand( 0, .2 ), v, VectorRand() )
				v:Normalize()
				v:Mul( math.Rand( 1000 * 85, 1200 * 85 ) / flMultiplier )
				dDamage:SetDamageForce( v )
				pEntity:TakeDamageInfo( dDamage )
				if !bHit then self:EmitSound "GekkoImpact" bHit = true bShake = true end
				return false
			end,
			mask = MASK_SOLID
		// In case we hit the world
		} )/*.Hit && !bHit then self:EmitSound "GekkoImpact" bHit = true bShake = true end*/

		if !bHit then self:EmitSound "GekkoSwing" end

		util_ScreenShake( self:GetPos() + self:OBBCenter(), bHit && 512 || 24, 1, 1, 4096, true )
	end )

	timer.Simple( .18 / flMultiplier, function()
		local bHit
		if !IsValid( self ) then return end
		/*if */util.TraceHull( {
			start = self:GetPos(),
			endpos = self:GetPos() + self:GetForward() * 80 * flModelScale,
			mins = vMins,
			maxs = vMaxs,
			filter = function( pEntity )
				if IsBullshitNonSolidEntity( pEntity ) then return false end
				if MyTable.Disposition( self, pEntity, MyTable ) == D_LI then return false end
				local dDamage = DamageInfo()
				dDamage:SetAttacker( self )
				dDamage:SetDamageType( DMG_CLUB )
				dDamage:SetDamage( 4096 / flMultiplier )
				local v = pEntity:GetPos()
				v:Add( pEntity:OBBCenter() )
				v:Sub( self:GetPos() )
				v:Normalize()
				v[ 3 ] = v[ 3 ] + math.Rand( .15, .3 )
				v = LerpVector( math.Rand( 0, .2 ), v, VectorRand() )
				v:Normalize()
				v:Mul( math.Rand( 1000 * 85, 1200 * 85 ) / flMultiplier )
				dDamage:SetDamageForce( v )
				pEntity:TakeDamageInfo( dDamage )
				if !bHit then self:EmitSound "GekkoImpact" bHit = true bShake = true end
				return false
			end,
			mask = MASK_SOLID
		// In case we hit the world
		} )/*.Hit && !bHit then self:EmitSound "GekkoImpact" bHit = true bShake = true end*/

		if !bHit then self:EmitSound "GekkoSwing" end

		util_ScreenShake( self:GetPos() + self:OBBCenter(), bHit && 512 || 24, 1, 1, 4096, true )
	end )

	MyTable.AnimationSystemHalt( self, MyTable )

	local f = math.Rand( 1.75, 2.25 )

	MyTable.PlaySequenceAndMove( self, sSequence, flMultiplier, nil, function( _, flCycle )
		MyTable.Look( self, MyTable )

		if flCycle > .2 && IsActiveDefenseAction( MyTable.HandleDefense( self, MyTable ) ) then
			return true
		end
	end, nil, f, f )

	local f = pSchedule.fOnComplete
	if f && f( self, pSchedule, MyTable ) then return end

	return true
end } )

RegisterSchedule( "GekkoAttackStraight", { Execute = function( self, pSchedule, MyTable )
	local pEnemy, pTrueEnemy = MyTable.Enemy

	if IsValid( pEnemy ) then
		local pE, pTE = self:SetupEnemy( pEnemy )
		pEnemy, pTrueEnemy = pE, pTE
		local f = self:BoundingRadius()
		f = f * f
		local v = self:GetPos()
		if pEnemy.__ACTOR_BULLSEYE__ && v:DistToSqr( pEnemy:NearestPoint( v ) ) <= f && ( pEnemy == pTrueEnemy || pTrueEnemy:NearestPoint( pEnemy:GetPos() ):DistToSqr( pEnemy:GetPos() ) > f ) then
			self:ReportPositionAsClear( pEnemy:GetPos() )
			return
		end
	end

	MyTable.AnimationSystemHalt( self, MyTable )

	local sWarmupSequence = "att2_1"
	local flWarmupMultiplier = math.Rand( .75, 1 )

	local sSequence = "att2_2"
	local flMultiplier = flWarmupMultiplier

	MyTable.MELEE_flStart = CurTime()
	MyTable.MELEE_flHit = CurTime() + self:SequenceDuration( sWarmupSequence ) / flWarmupMultiplier + .1 / flMultiplier
	MyTable.MELEE_flEnd = CurTime() + self:SequenceDuration( sWarmupSequence ) / flWarmupMultiplier + self:SequenceDuration( sSequence ) / flMultiplier
	MyTable.MELEE_flDamage = 4096 / flMultiplier
	MyTable.MELEE_fvStart = function( self ) return self:GetPos() end
	MyTable.MELEE_fvEnd = function( self ) return self:GetPos() + self:GetForward() * 80 end

	local vMins, vMaxs = Vector( MyTable.vHullMins ), Vector( MyTable.vHullMaxs )
	local flModelScale = self:GetModelScale()
	vMins:Mul( flModelScale )
	vMaxs:Mul( flModelScale )
	vMins[ 1 ] = vMins[ 1 ] * 2
	vMins[ 2 ] = vMins[ 2 ] * 2
	vMaxs[ 1 ] = vMaxs[ 1 ] * 2
	vMaxs[ 2 ] = vMaxs[ 2 ] * 2
	vMins[ 1 ] = vMins[ 1 ] + 24

	MyTable.MELEE_fvMins = function() return vMins end
	MyTable.MELEE_fvMaxs = function() return vMaxs end

	local bInterrupt

	MyTable.PlaySequenceAndMove( self, sWarmupSequence, flWarmupMultiplier, true, function()
		if IsValid( pEnemy ) then
			MyTable.vaAimTargetBody = pEnemy:GetPos() + pEnemy:OBBCenter()
			MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
			MyTable.HandleTurning( self, MyTable )
		end

		MyTable.Look( self, MyTable )

		if IsActiveDefenseAction( MyTable.HandleDefense( self, MyTable ) ) then
			bInterrupt = true
			return true
		end
	end, nil, nil, 0 )

	if bInterrupt then
		local f = pSchedule.fOnInterrupt
		if f && f( self, pSchedule, MyTable ) then return end
		return true
	end

	self:EmitSound "GekkoSwing"

	timer.Simple( .1 / flMultiplier, function()
		local bHit, bHitEnemy, bShake
		if !IsValid( self ) then return end
		if util.TraceHull( {
			start = self:GetPos(),
			endpos = self:GetPos() + self:GetForward() * 180 * flModelScale,
			mins = vMins,
			maxs = vMaxs,
			filter = function( pEntity )
				if IsBullshitNonSolidEntity( pEntity ) then return false end
				if MyTable.Disposition( self, pEntity, MyTable ) == D_LI then return false end
				if !bHitEnemy && IsValid( pTrueEnemy ) && pEntity == pTrueEnemy then bHitEnemy = true end
				local dDamage = DamageInfo()
				dDamage:SetAttacker( self )
				dDamage:SetDamageType( DMG_CLUB )
				dDamage:SetDamage( 4096 / flMultiplier )
				local v = pEntity:GetPos()
				v:Add( pEntity:OBBCenter() )
				v:Sub( self:GetPos() )
				v:Normalize()
				v[ 3 ] = v[ 3 ] + math.Rand( .15, .3 )
				v = LerpVector( math.Rand( 0, .2 ), v, VectorRand() )
				v:Normalize()
				v:Mul( math.Rand( 1000 * 85, 1200 * 85 ) / flMultiplier )
				dDamage:SetDamageForce( v )
				pEntity:TakeDamageInfo( dDamage )
				if !bHit then self:EmitSound "GekkoImpact" bHit = true bShake = true end
				return false
			end,
			mask = MASK_SOLID
		// In case we hit the world
		} ).Hit && !bHit then self:EmitSound "GekkoImpact" bHit = true bShake = true end

		util_ScreenShake( self:GetPos() + self:OBBCenter(), bShake && 512 || 24, 1, 1, 4096, true )
	end )

	MyTable.AnimationSystemHalt( self, MyTable )

	MyTable.PlaySequenceAndMove( self, sSequence, flMultiplier, nil, function( _, flCycle )
		MyTable.Look( self, MyTable )

		if flCycle > .2 && IsActiveDefenseAction( MyTable.HandleDefense( self, MyTable ) ) then
			return true
		end
	end )

	local f = pSchedule.fOnComplete
	if f && f( self, pSchedule, MyTable ) then return end

	return true
end } )

function ENT:GetStompDamageRadius() return self:BoundingRadius() * 1.5 end

RegisterSchedule( "GekkoStomp", { Execute = function( self, pSchedule, MyTable )
	local pEnemy, pTrueEnemy = MyTable.Enemy

	if IsValid( pEnemy ) then
		local pE, pTE = self:SetupEnemy( pEnemy )
		pEnemy, pTrueEnemy = pE, pTE
		local f = self:BoundingRadius()
		f = f * f
		local v = self:GetPos()
		if pEnemy.__ACTOR_BULLSEYE__ && v:DistToSqr( pEnemy:NearestPoint( v ) ) <= f && ( pEnemy == pTrueEnemy || pTrueEnemy:NearestPoint( pEnemy:GetPos() ):DistToSqr( pEnemy:GetPos() ) > f ) then
			self:ReportPositionAsClear( pEnemy:GetPos() )
			return
		end
	end

	local flWarmupMultiplier = math.Rand( .75, 1 )
	local flMultiplier = flWarmupMultiplier

	ClearMeleeData( self, MyTable )

	MyTable.MELEE_flStart = CurTime()
	MyTable.MELEE_flHit = CurTime() + self:SequenceDuration( self:LookupSequence "stomp1" ) / flWarmupMultiplier + .1 / flMultiplier
	MyTable.MELEE_flEnd = CurTime() + self:SequenceDuration( self:LookupSequence "stomp1" ) / flWarmupMultiplier + self:SequenceDuration( self:LookupSequence "stomp2" ) / flMultiplier
	MyTable.MELEE_flRadius = MyTable.GetStompDamageRadius( self )
	MyTable.MELEE_flDamage = 3072

	MyTable.AnimationSystemHalt( self, MyTable )

	local bInterrupt
	MyTable.PlaySequenceAndMove( self, "stomp1", flWarmupMultiplier, true, function()
		if IsValid( pEnemy ) then
			MyTable.vaAimTargetBody = pEnemy:GetPos() + pEnemy:OBBCenter()
			MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
			MyTable.HandleTurning( self, MyTable )
		end

		MyTable.Look( self, MyTable )

		if IsActiveDefenseAction( MyTable.HandleDefense( self, MyTable ) ) then
			bInterrupt = true
			return true
		end
	end )

	if bInterrupt then
		local f = pSchedule.fOnInterrupt
		if f && f( self, pSchedule, MyTable ) then return end
		return true
	end

	MyTable.vaAimTargetBody = self:GetAngles()

	timer.Simple( .1 / flMultiplier, function()
		if !IsValid( self ) || bInterrupt then return end

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
			dDamage:SetDamage( 3072 )
			dDamage:SetDamageType( DMG_RAYLEIGH )
		end

		util.BlastDamage( self, self, vPos, MyTable.GetStompDamageRadius( self ), 1 )
		util_ScreenShake( vPos, 8, 40, 1.5, 4096, true )
		self.GAME_OnHurtSomething = nil

		if self:IsOnGround() then
			if math.random( 2 ) == 1 then
				for i = 1, 8 do self:EmitSound "GekkoStompA" end
			else
				for i = 1, 8 do self:EmitSound "GekkoStompA" end
			end
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 512, 1, 1, 4096, true )
		else
			self:EmitSound "GekkoSwing"
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 24, 1, 1, 4096, true )
		end
	end )

	MyTable.AnimationSystemHalt( self, MyTable )

	MyTable.PlaySequenceAndMove( self, "stomp2", flMultiplier, nil, function()
		if IsValid( pEnemy ) then
			MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()
			MyTable.HandleTurning( self, MyTable )
		end

		MyTable.Look( self, MyTable )

		if IsActiveDefenseAction( MyTable.HandleDefense( self, MyTable ) ) then
			bInterrupt = true
			return true
		end
	end )

	if bInterrupt then
		MyTable.PromoteSequenceInstant( self, "idle", 1 )
		local f = pSchedule.fOnInterrupt
		if f && f( self, pSchedule, MyTable ) then return end
		return true
	end

	local f = pSchedule.fOnComplete
	if f && f( self, pSchedule, MyTable ) then return end
	return true
end } )

RegisterSchedule( "GekkoInterceptJump", { Execute = function( self, pSchedule, MyTable )
	if self:IsOnGround() then
		local f = pSchedule.fOnComplete
		if f && f( self, pSchedule, MyTable ) then return end
		return true
	end

	local pEnemy = MyTable.Enemy
	if IsValid( pEnemy ) then
		MyTable.vaAimTargetBody = pSchedule.aLook
		MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()
	end
end } )

ENT.m_sDefaultCombatSchedule = "UnmannedGearIRVINGCombat"

RegisterSchedule( "UnmannedGearIRVINGCombat", { Execute = function( self, pSchedule, MyTable )
	MyTable.GekkoChirpControllerCombat( self, MyTable )

	if table.IsEmpty( MyTable.tEnemies ) then return true end

	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end

	local pEnemy, pTrueEnemy = self:SetupEnemy( pEnemy )

	local f = self:BoundingRadius()
	f = f * f
	local v = self:GetPos()
	if pEnemy.__ACTOR_BULLSEYE__ && v:DistToSqr( pEnemy:NearestPoint( v ) ) <= f && ( pEnemy == pTrueEnemy || pTrueEnemy:NearestPoint( pEnemy:GetPos() ):DistToSqr( pEnemy:GetPos() ) > f ) then
		self:ReportPositionAsClear( pEnemy:GetPos() )
		return
	end

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then
		pEnemyPath = Path "Follow"
		MyTable.pEnemyPath = pEnemyPath
	end

	MyTable.ManageFlankPath( self, pEnemyPath, pEnemy, pSchedule, MyTable )

	MyTable.SetSchedule( self, "IntimidationWalk", MyTable )
end } )

ENT.sJumpOnTheirHeadSchedule = "GekkoInterceptJump"

function ENT:HandleHeadJump( MyTable, pEnemy, pSchedule, fOnComplete )
	if !IsValid( pEnemy ) then return end

	if GetVelocity( self ):LengthSqr() <= ( MyTable.flWalkSpeed * .5 ) ^ 2 && math.random( 1, 2 ) == 1 then
		MyTable.AnimationSystemHalt( self, MyTable )

		MyTable.PlaySequenceAndWait( self, "jump_start", math.Rand( 1, 1.5 ), nil, function()
			if IsValid( pEnemy ) then
				MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()
			end

			MyTable.Look( self, MyTable )
			MyTable.HandleTurning( self, MyTable )
		end )

		if IsValid( pEnemy ) then MyTable.OhBoyItsTimeToJump( self, pEnemy, MyTable, fOnComplete ) end

		return
	end

	local iLayer = self:AddGestureSequence( self:LookupSequence "jump_start" )

	local flWeight = math.Rand( .3, .45 )
	MyTable.flSpeedUpAnimationsWeight = flWeight
	self:SetLayerWeight( iLayer, flWeight )

	MyTable.flSpeedUpAnimationsTime = CurTime() + self:SequenceDuration( self:LookupSequence "jump_start" )

	local flMultiplier = math.Rand( .75, 1.5 )
	self:SetLayerPlaybackRate( iLayer, flMultiplier )

	pSchedule.flPerformingJump = CurTime() + 1.5 / flMultiplier

	timer.Simple( .9 / flMultiplier, function()
		if IsValid( self ) && IsValid( pEnemy ) && MyTable.Schedule == pSchedule then
			MyTable.AnimationSystemHalt( self, MyTable )
			MyTable.OhBoyItsTimeToJump( self, pEnemy, MyTable, fOnComplete )
		end
	end )
end

function ENT:HandleHeadJumpStill( MyTable, pEnemy, pSchedule, fOnComplete )
	if !IsValid( pEnemy ) then return end

	MyTable.AnimationSystemHalt( self, MyTable )

	MyTable.PlaySequenceAndWait( self, "jump_start", math.Rand( 1, 1.5 ), nil, function()
		if IsValid( pEnemy ) then
			MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()
		end

		MyTable.Look( self, MyTable )
		MyTable.HandleTurning( self, MyTable )
	end )

	if IsValid( pEnemy ) then MyTable.OhBoyItsTimeToJump( self, pEnemy, MyTable, fOnComplete ) end
end

function ENT:CheckAndDoDumbMelee( MyTable, pEnemy, pTrueEnemy )
	local bHit
	local vMins, vMaxs = Vector( MyTable.vHullMins ), Vector( MyTable.vHullMaxs )
	vMins[ 3 ] = vMins[ 3 ] + 12
	vMaxs[ 3 ] = vMaxs[ 3 ] * .5

	if util.TraceHull( {
		start = self:GetPos(),
		endpos = self:GetPos() + self:GetForward() * 120 * self:GetModelScale(),
		mins = vMins,
		maxs = vMaxs,
		filter = function( pEntity )
			if IsBullshitNonSolidEntity( pEntity ) then return false end
			if pEntity == pTrueEnemy then bHit = true return true end
			return false
		end,
		mask = MASK_SOLID
	} ).Hit && !bHit then return end

	// Yes, I know this is fucked up
	local flStomp = MyTable.GetStompDamageRadius( self ) * 1.5
	flStomp = flStomp * flStomp

	local bStomp

	util.TraceLine( {
		start = self:GetPos(),
		endpos = self:GetPos() + ( pEnemy:GetPos() + pEnemy:OBBCenter() - self:GetPos() ):GetNormalized() * flStomp,
		filter = function( pHit )
			if pHit == self then return false end

			if self:Disposition( pHit ) != D_LI then
				bStomp = true
				return true
			end

			return true
		end,
		mask = MASK_SHOT
	} )

	if bHit && bStomp then
		return MyTable.SetSchedule( self, math.random( 1, 3 ) == 1 && "GekkoStomp" || ( math.random( 2 ) == 1 && "GekkoAttackRoundhouse" || "GekkoAttackStraight" ), MyTable )
	end
end
