function ENT:CustomMoo( MyTable )
	if math.random( 2 ) == 1 then
		MyTable.EmitSentence( self, { sSound = "GekkoTaunt" }, MyTable )
	
		MyTable.HandleSentences( self, MyTable )

		return true
	end
end

function ENT:OhBoyItsTimeToJump( pEnemy, MyTable, bCustomMoo )
	if !bCustomMoo then MyTable.CustomMoo( self, MyTable ) end

	local vIntercept = MyTable.InterceptJump( self, pEnemy, nil, MyTable.flJumpHeight )
	vIntercept:Sub( self:GetPos() )
	MyTable.SetSchedule( self, "GekkoInterceptJump", MyTable ).aLook = vIntercept:Angle()
end

local util_ScreenShake = util.ScreenShake

ENT.flChargeTimeMin = 10
ENT.flChargeTimeMax = 20
// Keep speeds all in one back at Server.lua
RegisterSchedule( "GekkoCharge", { Execute = function( self, pSchedule, MyTable )
	MyTable.flOverrideBodyStiffnessThisTick = 4
	MyTable.flOverrideBodyDampingThisTick = -6
	MyTable.bCharging = true

	local pEnemy = MyTable.Enemy

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then pEnemyPath = Path "Follow" MyTable.pEnemyPath = pEnemyPath end

	if LevelOfDetail( pSchedule, "flNextPath" ) then MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy, MyTable ) end

	if !pSchedule.m_bInitialized then
		if !IsValid( pEnemy ) then return true end

		pSchedule.m_bInitialized = true

		timer.Simple( .3, function()
			if !IsValid( self ) then return end
			self:EmitSound "GekkoTaunt"
		end )

		MyTable.AnimationSystemHalt( self, MyTable )
		MyTable.PlaySequenceAndWait( self, "charge_start", 1, nil, function()
			if IsValid( pEnemy ) then
				MyTable.vaAimTargetBody = pEnemy:GetPos() + pEnemy:OBBCenter()
				MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
			end

			MyTable.Look( self, MyTable )
			MyTable.HandleTurning( self, MyTable )
		end )

		local flDuration = math.Rand( MyTable.flChargeTimeMin, MyTable.flChargeTimeMax )
		pSchedule.flDuration = flDuration
		pSchedule.flEndTime = CurTime() + flDuration

		if IsValid( pEnemy ) && math.random( 5 ) == 1 && MyTable.IsInterceptJumpLegalShort( self, pEnemy, MyTable.flJumpHeight ) then
			MyTable.OhBoyItsTimeToJump( self, pEnemy, MyTable )
			return
		elseif math.random( 5 ) == 1 then
			pSchedule.flJumpChance = 6
		else pSchedule.flJumpChance = 1 end
	end

	if !IsValid( pEnemy ) then
		MyTable.AnimationSystemHalt( self, MyTable )
		MyTable.PlaySequenceAndWait( self, "charge_end", math.Rand( .75, 1.25 ) )
		return true
	end

	if CurTime() > pSchedule.flEndTime then
		MyTable.AnimationSystemHalt( self, MyTable )
		MyTable.PlaySequenceAndWait( self, "charge_end", math.Rand( .75, 1.25 ) )

		if IsValid( pEnemy ) && math.random( 3 ) == 1 && MyTable.IsInterceptJumpLegal( self, pEnemy, MyTable.flJumpHeight ) then
			MyTable.OhBoyItsTimeToJump( self, pEnemy, MyTable )
			return
		end

		return true
	end

	if math.random() <= pSchedule.flJumpChance * FrameTime() && MyTable.IsInterceptJumpLegalShort( self, pEnemy, MyTable.flJumpHeight ) then
		MyTable.OhBoyItsTimeToJump( self, pEnemy, MyTable )
		return
	end
	
	local pEnemy, pTrueEnemy = self:SetupEnemy( pEnemy )
	local f = self:BoundingRadius()
	f = f * f
	local v = self:GetPos()
	if pEnemy.__ACTOR_BULLSEYE__ && v:DistToSqr( pEnemy:NearestPoint( v ) ) <= f && ( pEnemy == pTrueEnemy || pTrueEnemy:NearestPoint( pEnemy:GetPos() ):DistToSqr( pEnemy:GetPos() ) > f ) then
		self:ReportPositionAsClear( pEnemy:GetPos() )
		MyTable.AnimationSystemHalt( self, MyTable )
		MyTable.PlaySequenceAndWait( self, "charge_end", 1 )
		return
	end

	local pLocomotion = MyTable.loco
	pLocomotion:SetDesiredSpeed( 1 )
	pLocomotion:SetAcceleration( 1 )
	pLocomotion:SetDeceleration( 1 )
	pLocomotion:SetJumpHeight( 512 )

	local flSpeed = MyTable.flChargeSpeed
	local v = GetVelocity( self )
	MyTable.PromoteSequenceInstant( self, "charge", flSpeed / self:GetSequenceGroundSpeed( self:LookupSequence "charge" ), MyTable )
	pEnemyPath:MoveCursorToClosestPosition( self:GetPos() )
	local vTarget = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() )
	pEnemyPath:MoveCursor( self:OBBMaxs()[ 1 ] * 3 )
	MyTable.vaAimTargetBody = ( pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() ) - vTarget ):Angle()
	vTarget = self:GetForward() * flSpeed
	vTarget[ 3 ] = v[ 3 ]

	MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()

	pLocomotion:SetVelocity( vTarget )

	self:GrountMovement( pEnemyPath, flSpeed, tFilter )

	local tHit, f, flNextHitSound, bStop = {}, self:BoundingRadius(), 0
	if util.TraceHull( {
		start = self:GetPos(),
		endpos = self:GetPos() + self:GetForward() * 64 * self:GetModelScale(),
		mins = MyTable.vHullMins + Vector( 0, 0, 24 ),
		maxs = MyTable.vHullMaxs,
		filter = function( pEntity )
			tHit[ pEntity ] = true
			if tHit[ pEntity ] then return false end

			if MyTable.Disposition( self, pEntity, MyTable ) == D_LI then return false end
			if !bStop && IsValid( pTrueEnemy ) && pEntity == pTrueEnemy then bStop = true end
			if pEntity:BoundingRadius() > f then bStop = true end
			local dDamage = DamageInfo()
			dDamage:SetAttacker( self )
			dDamage:SetDamageType( DMG_CLUB )
			local flFraction = GetVelocity( self ):Length() / self.flChargeSpeed
			dDamage:SetDamage( flFraction * 8192 )
			local v = pEntity:GetPos()
			v:Add( pEntity:OBBCenter() )
			v:Sub( self:GetPos() )
			v:Sub( self:OBBCenter() )
			v:Normalize()
			v[ 3 ] = v[ 3 ] + math.Rand( .15, .3 )
			v = LerpVector( math.Rand( 0, .5 ), v, VectorRand() )
			v:Normalize()
			v:Mul( flFraction * math.Rand( 1400 * 85, 1600 * 85 ) )
			dDamage:SetDamageForce( v )
			pEntity:TakeDamageInfo( dDamage )
			if CurTime() > flNextHitSound then
				util_ScreenShake( self:GetPos() + self:OBBCenter(), 256, 15, 4, 4096, true )
				self:EmitSound "GekkoImpact"
				self:EmitSound "GekkoImpact"
				self:EmitSound "GekkoImpact"
				flNextHitSound = CurTime() + .25
			end
			return false
		end,
		mask = MASK_SOLID
	} ).HitWorld then
		self:EmitSound "GekkoJump"
		util_ScreenShake( self:GetPos() + self:OBBCenter(), 256, 15, 4, 4096, true )
		bStop = true
	end

	if bStop then
		MyTable.AnimationSystemHalt( self, MyTable )
		MyTable.PlaySequenceAndWait( self, "charge_end", 1 )
		return true
	end
end } )

local tAttackSequences = { "att1", "att2", "att1_2", "att2_2" }

RegisterSchedule( "GekkoAttack", { Execute = function( self, sched, MyTable )
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

	local sWarmupSequence = math.random( 2 ) == 1 && "att1_1" || "att2_1"
	local flWarmupMultiplier = math.Rand( .5, 1.5 )

	local sSequence = tAttackSequences[ math.random( 1, 4 ) ]
	local flMultiplier = math.Rand( 2 / 3, 1 + 1 / 3 )

	// TODO: Melee data here!

	MyTable.PlaySequenceAndWait( self, sWarmupSequence, flWarmupMultiplier, nil, function()
		if IsValid( pEnemy ) then
			MyTable.vaAimTargetBody = pEnemy:GetPos() + pEnemy:OBBCenter()
			MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
		end

		MyTable.Look( self, MyTable )
		MyTable.HandleTurning( self, MyTable )
	end )

	// Nuh uh!
	if IsValid( pEnemy ) && math.random( 3 ) == 1 && MyTable.IsInterceptJumpLegal( self, pEnemy ) then
		MyTable.OhBoyItsTimeToJump( self, pEnemy, MyTable )
		return
	end

	self:EmitSound "GekkoSwing"

	timer.Simple( .1 / flMultiplier, function()
		local bHit, bHitEnemy, bShake
		if !IsValid( self ) then return end
		local vMins, vMaxs = Vector( MyTable.vHullMins ), Vector( MyTable.vHullMaxs )
		local flModelScale = self:GetModelScale()
		vMins:Mul( flModelScale )
		vMaxs:Mul( flModelScale )
		vMins[ 1 ] = vMins[ 1 ] * 2
		vMins[ 2 ] = vMins[ 2 ] * 2
		vMaxs[ 1 ] = vMaxs[ 1 ] * 2
		vMaxs[ 2 ] = vMaxs[ 2 ] * 2
		vMins[ 1 ] = vMins[ 1 ] + 24
		if util.TraceHull( {
			start = self:GetPos(),
			endpos = self:GetPos() + self:GetForward() * 160 * flModelScale,
			mins = vMins,
			maxs = vMaxs,
			filter = function( pEntity )
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

		if !bHitEnemy then MyTable.Schedule = nil end
	end )

	MyTable.AnimationSystemHalt( self, MyTable )

	MyTable.PlaySequenceAndWait( self, sSequence, flMultiplier, nil, function()
		if IsValid( pEnemy ) then
			MyTable.vaAimTargetBody = pEnemy:GetPos() + pEnemy:OBBCenter()
			MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
		end

		MyTable.Look( self, MyTable )
		MyTable.HandleTurning( self, MyTable )
	end )

	// Surprise, bitch!... Again!
	if IsValid( pEnemy ) && math.random( 4 ) == 1 && MyTable.IsInterceptJumpLegal( self, pEnemy ) then
		MyTable.OhBoyItsTimeToJump( self, pEnemy, MyTable )
		return
	end
end } )

function ENT:GetStompDamageRadius() return self:BoundingRadius() * 2 end

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

	local flWarmupMultiplier = math.Rand( .75, 1.25 )
	local flMultiplier = math.Rand( .5, 2 )
	local flLeaveMultiplier = math.Rand( .75, 1.25 )

	ClearMeleeData( self, MyTable )

	MyTable.MELEE_flStart = CurTime()
	MyTable.MELEE_flHit = CurTime() + self:SequenceDuration( self:LookupSequence "stomp1" ) / flWarmupMultiplier + .1 / flMultiplier
	MyTable.MELEE_flEnd = CurTime() + self:SequenceDuration( self:LookupSequence "stomp1" ) / flWarmupMultiplier + self:SequenceDuration( self:LookupSequence "att3" ) / flMultiplier + self:SequenceDuration( self:LookupSequence "att3_unstuck" ) / flLeaveMultiplier
	MyTable.MELEE_flRadius = MyTable.GetStompDamageRadius( self )
	MyTable.MELEE_flDamage = 3072

	MyTable.AnimationSystemHalt( self, MyTable )

	MyTable.PlaySequenceAndWait( self, "stomp1", flWarmupMultiplier, nil, function()
		if IsValid( pEnemy ) then
			MyTable.vaAimTargetBody = pEnemy:GetPos() + pEnemy:OBBCenter()
			MyTable.vaAimTargetPose = MyTable.vaAimTargetBody

			MyTable.Look( self, MyTable )
			MyTable.HandleTurning( self, MyTable )
		end
	end )

	MyTable.vaAimTargetBody = self:GetAngles()

	timer.Simple( .1 / flMultiplier, function()
		if !IsValid( self ) then return end

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

	MyTable.PlaySequenceAndWait( self, "att3", flMultiplier, nil, function()
		if IsValid( pEnemy ) then
			MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()

			MyTable.Look( self, MyTable )
			MyTable.HandleTurning( self, MyTable )
		end
	end )

	MyTable.PlaySequenceAndWait( self, "att3_unstuck", flLeaveMultiplier, nil, function()
		if IsValid( pEnemy ) then
			MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()
		end

		MyTable.Look( self, MyTable )
		MyTable.HandleTurning( self, MyTable )
	end )

	// Surprise, bitch!
	if IsValid( pEnemy ) && math.random( 3 ) == 1 && MyTable.IsInterceptJumpLegal( self, pEnemy ) then
		MyTable.OhBoyItsTimeToJump( self, pEnemy, MyTable )
		return
	end

	local sNextScheduleOverride = pSchedule.sNextScheduleOverride
	if sNextScheduleOverride then MyTable.SetSchedule( self, sNextScheduleOverride, MyTable ) return end

	return true
end } )

RegisterSchedule( "GekkoInterceptJump", { Execute = function( self, pSchedule, MyTable )
	if self:IsOnGround() then return true end

	local pEnemy = MyTable.Enemy
	if IsValid( pEnemy ) then
		MyTable.vaAimTargetBody = pSchedule.aLook
		MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()
	end
end } )

ENT.m_sDefaultCombatSchedule = "UnmannedGearGekkoCombat"

RegisterSchedule( "UnmannedGearGekkoCombat", { Execute = function( self, sched, MyTable )
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
	if !pEnemyPath then pEnemyPath = Path "Follow" MyTable.pEnemyPath = pEnemyPath end

	if LevelOfDetail( sched, "flNextPath" ) then MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy, MyTable ) end

	MyTable.MoveAlongPath( self, pEnemyPath, MyTable.flTopSpeed )

	local pGoal = pEnemyPath:GetCurrentGoal()
	if pGoal then MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle() end

	MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()

	local EDefense, flOptional = MyTable.HandleDefense( self, MyTable )
	if EDefense > DEF_NO_ACTION_NEEDED then
		if EDefense == DEF_DONT_ADVANCE_TO_RANGE then
			// TODO: Handle this, duh xD
		else return end
	end

	if !self:IsOnGround() then return end

	// Never charge or taunt if we can just smash 'em
	local bHit
	local vMins, vMaxs = Vector( MyTable.vHullMins ), Vector( MyTable.vHullMaxs )
	vMins[ 3 ] = vMins[ 3 ] + 12
	vMaxs[ 3 ] = vMaxs[ 3 ] * .5

	if util.TraceHull( {
		start = self:GetPos(),
		endpos = self:GetPos() + self:GetForward() * 96 * self:GetModelScale(),
		mins = vMins,
		maxs = vMaxs,
		filter = function( pEntity )
			if pEntity == pTrueEnemy then bHit = true return true end
			return false
		end,
		mask = MASK_SOLID
	} ).Hit && !bHit then return end

	// Yes, I know this is fucked up
	local bStomp = MyTable.GetStompDamageRadius( self ) * .75
	bStomp = bStomp * bStomp
	bStomp = self:GetPos():DistToSqr( pEnemy:NearestPoint( self:GetPos() ) ) <= bStomp

	if bHit && bStomp then
		MyTable.SetSchedule( self, math.random( 1, 3 ) == 1 && "GekkoStomp" || "GekkoAttack", MyTable )
		return
	end

	pEnemyPath:MoveCursorToClosestPosition( self:GetPos() )

	if !self:Visible( pEnemy ) then return end

	if math.random() <= 1 / 3 * FrameTime() && MyTable.IsInterceptJumpLegal( self, pEnemy ) then
		local bCustomMoo

		if math.random( 6 ) == 1 then
			bCustomMoo = MyTable.CustomMoo( self, MyTable )

			MyTable.AnimationSystemHalt( self, MyTable )

			MyTable.PlaySequenceAndWait( self, "jump_start", math.Rand( 1, 2 ), nil, function()
				if IsValid( pEnemy ) then
					MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()
				end

				MyTable.Look( self, MyTable )
				MyTable.HandleTurning( self, MyTable )
			end )

			MyTable.CustomMoo( self, MyTable )

			MyTable.PlaySequenceAndWait( self, "jump_start", -math.Rand( 1, 2 ), nil, function()
				if IsValid( pEnemy ) then
					MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()
				end

				MyTable.Look( self, MyTable )
				MyTable.HandleTurning( self, MyTable )
			end )

			return
		end

		if GetVelocity( self ):Length() <= MyTable.flPowerWalkSpeed && math.random( 1, 2 ) == 1 then
			bCustomMoo = MyTable.CustomMoo( self, MyTable )

			MyTable.AnimationSystemHalt( self, MyTable )

			MyTable.PlaySequenceAndWait( self, "jump_start", math.Rand( 1, 2 ), nil, function()
				if IsValid( pEnemy ) then
					MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()
				end

				MyTable.Look( self, MyTable )
				MyTable.HandleTurning( self, MyTable )
			end )
		end

		if IsValid( pEnemy ) then
			MyTable.OhBoyItsTimeToJump( self, pEnemy, MyTable, bCustomMoo )
			return
		else return true end
	end

	if CurTime() > ( sched.flNextLow || 0 ) && math.random() <= ( 1 / 3 ) * FrameTime() then
		self:EmitSound "GekkoTaunt"
		util_ScreenShake( self:GetPos() + self:OBBCenter(), 4, 6, 4, 4096, true )
		sched.flNextLow = CurTime() + math.Rand( 3, 4 )
	end

	local flDistance = pEnemyPath:GetLength() - pEnemyPath:GetCursorPosition()

	local f = MyTable.flChargeSpeed * MyTable.flChargeTimeMin * .8

	if flDistance <= f then
		local flChance = .1
		if flDistance <= MyTable.flJogSpeed * .75 then
		elseif flDistance <= MyTable.flJogSpeed * 2 then
			flChance = 1 / 3
		else flChance = .5 end

		if flDistance <= f && math.random() <= flChance * FrameTime() then
			if math.random( 2 ) == 1 then
				local flMultiplier = math.Rand( .75, 1.25 )

				timer.Simple( .8 / flMultiplier, function()
					if !IsValid( self ) then return end
					util_ScreenShake( self:GetPos() + self:OBBCenter(), 8, 40, 2, 4096, true )
					self:EmitSound "GekkoTaunt"
				end )

				MyTable.AnimationSystemHalt( self, MyTable )

				MyTable.PlaySequenceAndWait( self, "taunt", flMultiplier, nil, function()
					if IsValid( pEnemy ) then
						MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()
					end

					MyTable.Look( self, MyTable )
					MyTable.HandleTurning( self, MyTable )
				end )
				return
			end

			MyTable.SetSchedule( self, "GekkoCharge", MyTable )
		end
		return
	end
end } )
