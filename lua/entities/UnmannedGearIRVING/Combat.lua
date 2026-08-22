local util_ScreenShake = util.ScreenShake

ENT.flChargeTimeMin = 10
ENT.flChargeTimeMax = 20
ENT.flChargeSpeed = 1024
RegisterSchedule( "GekkoCharge", { Execute = function( self, sched, MyTable )
	MyTable.flOverrideBodyStiffnessThisTick = 4
	MyTable.flOverrideBodyDampingThisTick = -6
	MyTable.bCharging = true

	if !sched.m_bInitialized then
		timer.Simple( .3, function()
			if !IsValid( self ) then return end
			self:EmitSound "GekkoCharge"
		end )

		timer.Simple( .6, function()
			if !IsValid( self ) then return end
			self:EmitSound "GekkoCharge"
		end )

		timer.Simple( 1, function()
			if !IsValid( self ) then return end
			self:EmitSound "GekkoCharge"
		end )

		MyTable.AnimationSystemHalt( self, MyTable )
		MyTable.PlaySequenceAndWait( self, "charge_start", 1 )
		sched.m_bInitialized = true
		sched.flEndTime = CurTime() + math.Rand( MyTable.flChargeTimeMax, MyTable.flChargeTimeMax )
	end

	if CurTime() > sched.flEndTime || table.IsEmpty( MyTable.tEnemies ) then
		MyTable.AnimationSystemHalt( self, MyTable )
		MyTable.PlaySequenceAndWait( self, "charge_end", 1 )
		return true
	end

	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then
		MyTable.AnimationSystemHalt( self, MyTable )
		MyTable.PlaySequenceAndWait( self, "charge_end", 1 )
		return true
	end
	
	local pEnemy, pTrueEnemy = self:SetupEnemy( pEnemy )
	local f = self:BoundingRadius()
	f = f * f
	local v = self:GetPos()
	if pEnemy.__ACTOR_BULLSEYE__ && v:DistToSqr( pEnemy:NearestPoint( v ) ) <= f && ( pEnemy == pTrueEnemy || pTrueEnemy:NearestPoint( pEnemy:GetPos() ):DistToSqr( pEnemy:GetPos() ) > f ) then
		self:ReportPositionAsClear( pEnemy:GetPos() )
		MyTable.AnimationSystemHalt( self, MyTable )
		MyTable.PlaySequenceAndWait( self, "charge_end", 1 )
		return true
	end

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then pEnemyPath = Path "Follow" MyTable.pEnemyPath = pEnemyPath end

	self.loco:SetDesiredSpeed( 1 )
	self.loco:SetAcceleration( 1 )
	self.loco:SetDeceleration( 1 )
	self.loco:SetJumpHeight( 512 )

	local flSpeed = MyTable.flChargeSpeed
	local v = GetVelocity( self )
	MyTable.PromoteSequence( self, "charge", flSpeed / self:GetSequenceGroundSpeed( self:LookupSequence "charge" ), MyTable )
	pEnemyPath:MoveCursorToClosestPosition( self:GetPos() )
	local vTarget = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() )
	pEnemyPath:MoveCursor( 1 )
	MyTable.vaAimTargetBody = ( pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() ) - vTarget ):Angle()
	vTarget = self:GetForward() * flSpeed
	vTarget[ 3 ] = v[ 3 ]

	MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()

	self.loco:SetVelocity( vTarget )

	self:GrountMovement( pEnemyPath, flSpeed, tFilter )

	local tHit, f, flNextHitSound, bStop = {}, self:BoundingRadius(), 0
	if util.TraceHull( {
		start = self:GetPos(),
		endpos = self:GetPos() + self:GetForward() * 64 * self:GetModelScale(),
		mins = MyTable.vHullMins + Vector( 0, 0, 24 ),
		maxs = MyTable.vHullMaxs,
		filter = function( pEntity )
			if MyTable.Disposition( self, pEntity, MyTable ) == D_LI then return false end
			if tHit[ pEntity ] then return false end
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
			tHit[ pEntity ] = true
			return false
		end,
		mask = MASK_SOLID
	} ).HitWorld then util_ScreenShake( self:GetPos() + self:OBBCenter(), 256, 15, 4, 4096, true ) bStop = true end
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
			return true
		end
	end

	MyTable.AnimationSystemHalt( self, MyTable )

	MyTable.PlaySequenceAndWait( self, math.random( 2 ) == 1 && "att1_1" || "att2_1", math.Rand( .5, 1.5 ) )

	local flMultiplier = math.Rand( .5, 2 )

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

	MyTable.PlaySequenceAndWait( self, tAttackSequences[ math.random( 1, 4 ) ], flMultiplier )
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
			return true
		end
	end

	MyTable.AnimationSystemHalt( self, MyTable )

	MyTable.PlaySequenceAndWait( self, "stomp1", math.Rand( .75, 1.25 ) )

	local flMultiplier = math.Rand( .5, 2 )

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
			dDamage:SetDamage( 8192 )
			dDamage:SetDamageType( DMG_CLUB )
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

	MyTable.PlaySequenceAndWait( self, "stomp2", flMultiplier )
	MyTable.PlaySequenceAndWait( self, "att3_unstuck", math.Rand( .75, 1.25 ) )

	local sNextScheduleOverride = pSchedule.sNextScheduleOverride
	if sNextScheduleOverride then MyTable.SetSchedule( self, sNextScheduleOverride, MyTable ) return end

	return true
end } )

ENT.m_sDefaultCombatSchedule = "UnmannedGearGekkoCombat"

RegisterSchedule( "UnmannedGearGekkoCombat", { Execute = function( self, sched, MyTable )
	if table.IsEmpty( MyTable.tEnemies ) then return true end

	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end

	local pEnemy, pTrueEnemy = self:SetupEnemy( pEnemy )

	local f = self:BoundingRadius()
	f = f * f
	local v = self:GetPos()
	if pEnemy.__ACTOR_BULLSEYE__ && v:DistToSqr( pEnemy:NearestPoint( v ) ) <= f && ( pEnemy == pTrueEnemy || pTrueEnemy:NearestPoint( pEnemy:GetPos() ):DistToSqr( pEnemy:GetPos() ) > f ) then
		self:ReportPositionAsClear( pEnemy:GetPos() )
		return true
	end

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then pEnemyPath = Path "Follow" MyTable.pEnemyPath = pEnemyPath end

	if LevelOfDetail( sched, "flNextRePath" ) then MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy, MyTable ) end

	MyTable.MoveAlongPath( self, pEnemyPath, MyTable.flTopSpeed )

	local pGoal = pEnemyPath:GetCurrentGoal()
	if pGoal then
		MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
	end

	MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter()

	if !self:IsOnGround() then return end

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

	// Never charge or taunt if we can just smash 'em
	if bHit then MyTable.SetSchedule( self, "GekkoAttack", MyTable ) return end

	pEnemyPath:MoveCursorToClosestPosition( self:GetPos() )

	if !self:Visible( pEnemy ) then return end

	if CurTime() > ( sched.flNextLow || 0 ) && math.random() <= .5 * FrameTime() then
		self:EmitSound "GekkoCombatLow"
		util_ScreenShake( self:GetPos() + self:OBBCenter(), 12, 6, 4, 4096, true )
		sched.flNextLow = CurTime() + math.Rand( 3, 4 )
	end

	local flDistance = pEnemyPath:GetLength() - pEnemyPath:GetCursorPosition()

	local f = MyTable.flChargeSpeed * MyTable.flChargeTimeMin * .8

	if flDistance <= f then
		local flChance = .1
		if flDistance <= MyTable.flJogSpeed then
		elseif flDistance <= MyTable.flJogSpeed * 2 then
			flChance = .25
		else flChance = 1 / 3 end

		if flDistance <= f && math.random() <= flChance * FrameTime() then
			if math.random( 2 ) == 1 then self:Taunt() return end
			MyTable.SetSchedule( self, "GekkoCharge", MyTable )
		end

		return
	end
end } )
