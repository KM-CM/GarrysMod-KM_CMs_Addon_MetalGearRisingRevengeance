DEFINE_BASECLASS "BaseActor"

if !CLASS_DESPERADO_AND_WORLD_MARSHAL then Add_NPC_Class "CLASS_DESPERADO_AND_WORLD_MARSHAL" end
ENT.iDefaultClass = CLASS_DESPERADO_AND_WORLD_MARSHAL

ENT.vHullMins = Vector( -36, -36 )
ENT.vHullMaxs = Vector( 36, 36, 170 )
ENT.vHullDuckMins = ENT.vHullMins
ENT.vHullDuckMaxs = ENT.vHullMaxs

ENT.bCannotCarryWeapons = true

ENT.m_sIdleSequence = "idle"

function ENT:Initialize()
	self:SetHealth( 131072 )
	self:SetMaxHealth( 131072 )
	self:SetCollisionBounds( self.vHullMins, self.vHullMaxs )
	self:PhysicsInit( SOLID_OBB )
	BaseClass.Initialize( self )
end

function ENT:OnKilled( ... )
	if BaseClass.OnKilled( self, ... ) then return end
	self:Remove()
end

ENT.flTopSpeed = 500
ENT.flRunSpeed = ENT.flTopSpeed
ENT.flWalkSpeed = 100

ENT.flTurnRate = 128

function ENT:MoveAlongPath( pPath, flSpeed, _, tFilter )
	self.loco:SetDesiredSpeed( flSpeed )
	local f = flSpeed * ACCELERATION_NORMAL
	self.loco:SetAcceleration( f )
	self.loco:SetDeceleration( f )
	self.loco:SetJumpHeight( 256 )
	local f = GetVelocity( self ):Length()
	if f <= 12 then self:PromoteSequence "idle"
	elseif f <= ( self.flWalkSpeed * 1.1 ) then
		self:PromoteSequence( "walk", GetVelocity( self ):Length() / self:GetSequenceGroundSpeed( self:LookupSequence "walk" ) )
	else
		self:PromoteSequence( "run", GetVelocity( self ):Length() / self:GetSequenceGroundSpeed( self:LookupSequence "run" ) )
	end
	self:HandleJumpingAlongPath( pPath, flSpeed, tFilter )
end

// MOO!
function ENT:DoRoar()
	self.sCallMeInRunBehaviour = "Roar"
	self.fCallMeInRunBehaviour = function( self, MyTable )
		self.bTaunting = true
		self:EmitSound "GekkoPreTaunt"
		timer.Simple( .8, function()
			if !IsValid( self ) then return end
			self:EmitSound "GekkoTaunt"
		end )
		MyTable.AnimationSystemHalt( self, MyTable )
		MyTable.PlaySequenceAndWait( self, "taunt", 1 )
		return true
	end
end

function ENT:DoShakeOff()
	self.sCallMeInRunBehaviour = "ShakeOff"
	self.fCallMeInRunBehaviour = function( self, MyTable )
		self.bTaunting = true
		timer.Simple( .33, function()
			if !IsValid( self ) then return end
			self:EmitSound "GekkoShakeOffTaunt"
		end )
		MyTable.AnimationSystemHalt( self, MyTable )
		MyTable.PlaySequenceAndWait( self, "taunt2", 1 )
		return true
	end
end

// Our nervous system is heavily damaged, either from heat, or the enemy, and is not
// working correctly (see the calibration test below). We must wait for it to go back
// to normal before we can do anything again. Good thing is, the motors themselves
// have default motion oscillations and positions in which they go when we aren't giving commands,
// which avoids hardware damage and bad posture. Unlike AI Errors, this is an issue with our
// biological part, therefore we can still see and hear while in it.
ENT.flWrongLegPing = 0
Actor_RegisterSchedule( "GekkoBioMechanicalInterfaceError", function( self, sched, MyTable )
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
	if flWrongLegPing <= 0 && math.Rand( 0, math.Remap( flLegStatus ^ 3, 0, 1, 100000, 1 ) * FrameTime() ) <= 1 then
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
end )

ENT.flLegStatus = 1

function ENT:OnTakeDamage( dDamage )
	local flAverage = Lerp( .25, self:Health(), self:GetMaxHealth() )
	local f = math.Clamp( self.flLegStatus - dDamage:GetDamage() / flAverage * 4, 0, 1 )
	self.flLegStatus = f
	local pSchedule = self.Schedule
	if !( pSchedule && pSchedule.m_sName == "GekkoBioMechanicalInterfaceError" ) then
		if self.flLegStatus <= math.Rand( 0, dDamage:GetDamage() / flAverage * 100 ) then self:SetSchedule "GekkoBioMechanicalInterfaceError" end
	end
	return BaseClass.OnTakeDamage( self, dDamage )
end

ENT.bCanCharge = true
ENT.flChargeTimeMin = 10
ENT.flChargeTimeMax = 20
ENT.flChargeSpeed = 1000
ENT.flChargeTurnRate = 64
Actor_RegisterSchedule( "GekkoCharge", function( self, sched, MyTable )
	sched.bCharging = true
	MyTable.flOverrideTurnRateThisTick = MyTable.flChargeTurnRate
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
	// MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy, MyTable )
	MyTable.ComputePath( self, pEnemyPath, pEnemy:GetPos(), MyTable )
	self.loco:SetDesiredSpeed( 1 )
	self.loco:SetAcceleration( 1 )
	self.loco:SetDeceleration( 1 )
	self.loco:SetJumpHeight( 256 )
	local flSpeed = MyTable.flChargeSpeed
	local v = GetVelocity( self )
	self:PromoteSequence( "charge", flSpeed / self:GetSequenceGroundSpeed( self:LookupSequence "charge" ) )
	pEnemyPath:MoveCursorToClosestPosition( self:GetPos() )
	local vTarget = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() )
	pEnemyPath:MoveCursor( 1 )
	MyTable.vaAimTargetBody = ( pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() ) - vTarget ):Angle()
	MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
	vTarget = self:GetForward() * flSpeed
	vTarget[ 3 ] = v[ 3 ]
	self.loco:SetVelocity( vTarget )
	self:HandleJumpingAlongPath( pEnemyPath, flSpeed, tFilter )
	local tHit, f, flNextHitSound, bStop = {}, self:BoundingRadius(), 0
	util.TraceHull {
		start = self:GetPos(),
		endpos = self:GetPos() + self:GetForward() * 92,
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
			dDamage:SetDamage( math.Clamp( pEntity:GetMaxHealth(), 512, 65536 ) )
			pEntity:TakeDamageInfo( dDamage )
			if CurTime() > flNextHitSound then
				self:EmitSound "GekkoImpact"
				self:EmitSound "GekkoImpact"
				self:EmitSound "GekkoImpact"
				flNextHitSound = CurTime() + .25
			end
			tHit[ pEntity ] = true
			return false
		end,
		mask = MASK_SOLID
	}
	if bStop then
		MyTable.AnimationSystemHalt( self, MyTable )
		MyTable.PlaySequenceAndWait( self, "charge_end", 1 )
		return true
	end
end )

// TODO: Attack the same way Gekkos actually do in MGR:R, maybe unless a Desperado Gekko or unless something else happens?
Actor_RegisterSchedule( "GekkoAttack", function( self, sched, MyTable )
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
	local iState = ( sched.iState || 0 ) + 1
	if iState > 3 then
		iState = 1
		MyTable.bGekkoAlternateAttack = !MyTable.bGekkoAlternateAttack
		if math.random( 4 ) == 1 then if math.random( 2 ) == 1 then self:DoRoar() else self:DoShakeOff() end end
	end
	if iState == 1 && math.random( 2 ) == 1 then iState = 2 end
	sched.iState = iState
	timer.Simple( .1, function()
		local bHit, bHitEnemy
		if !IsValid( self ) then return end
		if util.TraceHull( {
			start = self:GetPos(),
			endpos = self:GetPos() + self:GetForward() * 92,
			mins = MyTable.vHullMins + Vector( 0, 0, 12 ),
			maxs = MyTable.vHullMaxs,
			filter = function( pEntity )
				if MyTable.Disposition( self, pEntity, MyTable ) == D_LI then return false end
				if !bHitEnemy && IsValid( pTrueEnemy ) && pEntity == pTrueEnemy then bHitEnemy = true end
				local dDamage = DamageInfo()
				dDamage:SetAttacker( self )
				dDamage:SetDamageType( DMG_CLUB )
				dDamage:SetDamage( math.Clamp( pEntity:GetMaxHealth(), 512, 32768 ) )
				pEntity:TakeDamageInfo( dDamage )
				if !bHit then self:EmitSound "GekkoImpact" bHit = true end
				return false
			end,
			mask = MASK_SOLID
		// In case we hit the world
		} ).Hit && !bHit then self:EmitSound "GekkoImpact" bHit = true end
		if iState != 2 && !bHitEnemy then MyTable.Schedule = nil end
	end )
	MyTable.AnimationSystemHalt( self, MyTable )
	if iState == 1 then
		MyTable.PlaySequenceAndWait( self, MyTable.bGekkoAlternateAttack && "att2" || "att1", 1 )
	elseif iState == 2 then
		MyTable.PlaySequenceAndWait( self, MyTable.bGekkoAlternateAttack && "att2_1" || "att1_1", 1 )
	elseif iState == 3 then
		MyTable.PlaySequenceAndWait( self, MyTable.bGekkoAlternateAttack && "att2_2" || "att1_2", 1 )
	end
end )

ENT.m_sDefaultIdleSchedule = "UnmannedGearGekkoIdle"
ENT.m_sDefaultCombatSchedule = "UnmannedGearGekkoCombat"

Actor_RegisterSchedule( "UnmannedGearGekkoIdle", function( self, sched )
	if IsValid( self.Enemy ) then return true end
	if CurTime() > ( sched.flStandTime || 0 ) then
		if !sched.vGoal then
			local tAllies = self:GetAlliesByClass()
			local area, vec = self:GetLastKnownArea() || navmesh.GetNearestNavArea( self:GetPos() )
			if !area then
				sched.flStandTime = CurTime() + math.Rand( self.flIdleStandTimeMin, self.flIdleStandTimeMax )
				self.vaAimTargetBody = nil
				self.vaAimTargetPose = nil
				sched.Path = nil
				sched.vGoal = nil
				return
			end
			local tQueue, tVisited, flDistSqr = { { area, 0 } }, {}, math.Rand( 0, 1024 )
			flDistSqr = flDistSqr * flDistSqr
			local bDisAllowWater = !self.bCanSwim
			while !table.IsEmpty( tQueue ) do
				local area, dist = unpack( table.remove( tQueue ) )
				for _, t in ipairs( area:GetAdjacentAreaDistances() ) do
					local new = t.area
					if tVisited[ new:GetID() ] then continue end
					if bDisAllowWater && area:IsUnderwater() then continue end
					table.insert( tQueue, { new, dist + t.dist } )
					tVisited[ new:GetID() ] = true
				end
				table.SortByMember( tQueue, 2 )
				local v = area:GetRandomPoint()
				if v:DistToSqr( self:GetPos() ) >= flDistSqr then vec = v break end
			end
			if vec then sched.vGoal = vec else sched.flStandTime = CurTime() + math.Rand( 0, 4 ) return end
		end
		if !sched.pPath then sched.pPath = Path "Follow" end
		local goal = sched.pPath:GetCurrentGoal()
		if goal then self.vaAimTargetBody = ( goal.pos - self:GetPos() ):Angle() self.vaAimTargetPose = self.vaAimTargetBody end
		self:ComputePath( sched.pPath, sched.vGoal )
		self:MoveAlongPath( sched.pPath, self.flWalkSpeed )
		if math.abs( sched.pPath:GetCursorPosition() - sched.pPath:GetLength() ) <= self.flPathTolerance then
			sched.flStandTime = CurTime() + math.Rand( self.flIdleStandTimeMin, self.flIdleStandTimeMax )
			self.vaAimTargetBody = nil
			self.vaAimTargetPose = nil
			sched.pPath = nil
			sched.vGoal = nil
		end
	else self.vaAimTargetBody = nil self.vaAimTargetPose = nil sched.pPath = nil sched.vGoal = nil self:Stand() end
end )

Actor_RegisterSchedule( "UnmannedGearGekkoCombat", function( self, sched, MyTable )
	if table.IsEmpty( MyTable.tEnemies ) then return true end
	local pEnemy = self.Enemy
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
	MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy, MyTable )
	MyTable.MoveAlongPath( self, pEnemyPath, MyTable.flTopSpeed )
	local pGoal = pEnemyPath:GetCurrentGoal()
	if pGoal then
		MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
		MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
	end
	local bHit
	util.TraceHull {
		start = self:GetPos(),
		endpos = self:GetPos() + self:GetForward() * 92,
		mins = MyTable.vHullMins + Vector( 0, 0, 12 ),
		maxs = MyTable.vHullMaxs,
		filter = function( pEntity )
			if pEntity == pTrueEnemy then bHit = true return true end
			return false
		end,
		mask = MASK_SOLID
	}
	// Never charge or taunt if we can just smash 'em
	if bHit then MyTable.SetSchedule( self, "GekkoAttack", MyTable ) return end
	pEnemyPath:MoveCursorToClosestPosition( self:GetPos() )
	local flDistance = ( pEnemyPath:GetLength() - pEnemyPath:GetCursorPosition() )
	// if flDistance <= 256 then return end
	local f = MyTable.flChargeSpeed * MyTable.flChargeTimeMin * .5
	if flDistance > f then return end
	local flCharging, flNotCharging = 0, 1
	for pAlly in pairs( self:GetAlliesByClass() || {} ) do
		if !IsValid( pAlly ) || pAlly == self then continue end
		if !pAlly.bCanCharge then continue end
		local pEnemyPath = pAlly.pEnemyPath
		if !pEnemyPath then continue end
		local flTime = pAlly.flChargeTimeMin
		if !flTime then continue end
		local flSpeed = pAlly.flChargeSpeed
		if !flSpeed then continue end
		pEnemyPath:MoveCursorToClosestPosition( pAlly:GetPos() )
		local flDistance = ( pEnemyPath:GetLength() - pEnemyPath:GetCursorPosition() )
		if flDistance > ( flSpeed * flTime * .5 ) then continue end
		flNotCharging = flNotCharging + 1
		if pAlly.bCharging then flCharging = flCharging + 1 end
	end
	if flCharging == 0 then flCharging = 1 end
	local f = flCharging + flNotCharging
	if math.Rand( 0, 32768 * ( ( flNotCharging / flCharging ) / f ) * FrameTime() ) <= 1 then
		if math.random( 2 ) == 1 then self:DoRoar() else self:DoShakeOff() end
		return
	end
	if math.Rand( 0, 32768 * ( ( flCharging / flNotCharging ) * f ) * FrameTime() ) > 1 then return end
	MyTable.SetSchedule( self, "GekkoCharge", MyTable )
end )
