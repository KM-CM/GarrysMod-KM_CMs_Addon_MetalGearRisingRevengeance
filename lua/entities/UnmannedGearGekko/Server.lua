DEFINE_BASECLASS "BaseActor"

if !CLASS_DESPERADO_AND_WORLD_MARSHAL then Add_NPC_Class "CLASS_DESPERADO_AND_WORLD_MARSHAL" end
ENT.iDefaultClass = CLASS_DESPERADO_AND_WORLD_MARSHAL

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

local function fChargeOStep( self ) util_ScreenShake( self:GetPos() + self:OBBCenter(), 24, 1, 1, 2048, true ) end

ENT.tSequenceEvents = {
	walk = {
		[ .411 ] = function( self )
			self:EmitSound "GekkoStepTiptoes"
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 4, 1, 1, 1024, true )
		end,
		[ .911 ] = function( self )
			self:EmitSound "GekkoStepTiptoes"
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 4, 1, 1, 1024, true )
		end
	},
	run = {
		[ .2 ] = function( self )
			self:EmitSound "GekkoStepJog"
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 12, 1, 1, 2048, true )
		end,
		[ .54 ] = function( self )
			self:EmitSound "GekkoStepJog"
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 12, 1, 1, 2048, true )
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
	self:SetHealth( 131072 )
	self:SetMaxHealth( 131072 )
	self:SetCollisionBounds( self.vHullMins, self.vHullMaxs )
	if self:PhysicsInitShadow( false, false ) then self:GetPhysicsObject():SetMass( 9072 ) end
	BaseClass.Initialize( self )
end

function ENT:OnLandOnGround()
	function self:GAME_OnHurtSomething( pEntity, dDamage )
		if self:Disposition( pEntity ) == D_LI then return true end
		local v = pEntity:GetPos()
		v:Add( pEntity:OBBCenter() )
		v:Sub( self:GetPos() )
		v:Normalize()
		v[ 3 ] = v[ 3 ] + math.Rand( .15, .3 )
		v = LerpVector( math.Rand( 0, .2 ), v, VectorRand() )
		v:Normalize()
		v:Mul( math.Rand( 760 * 85, 780 * 85 ) )
		dDamage:SetDamageForce( v )
		dDamage:SetDamage( 32768 )
		// I would use DMG_CRUSH, but some entities (let's not point fingers... anyway it's npc_antlionguard), for SOME REASON, completely ignore it!
		dDamage:SetDamageType( DMG_CLUB )
	end
	util.BlastDamage( self, self, self:GetPos(), self:BoundingRadius() * 2, 1 )
	self.GAME_OnHurtSomething = nil
	self.sCallMeInRunBehaviour = "Land"
	self.fCallMeInRunBehaviour = function( self, MyTable )
		util_ScreenShake( self:GetPos() + self:OBBCenter(), 1024, 15, 4, 4096, true )
		self:EmitSound "GekkoLand"
		if !MyTable.bCharging then
			MyTable.AnimationSystemHalt( self, MyTable )
			MyTable.PlaySequenceAndWait( self, "land", 1 )
		end
		return true
	end
end

function ENT:Think()
	self.m_sIdleSequence = self:IsOnGround() && "idle" || "jump"
	return BaseClass.Think( self )
end

function ENT:OnKilled( ... )
	if BaseClass.OnKilled( self, ... ) then return end
	self:Remove()
end

ENT.flTopSpeed = 512
ENT.flRunSpeed = ENT.flTopSpeed
ENT.flWalkSpeed = 96

ENT.flTurnRate = 128

function ENT:MoveAlongPath( pPath, flSpeed, _, tFilter )
	local pLocomotion = self.loco
	pLocomotion:SetDesiredSpeed( flSpeed )
	local f = self.flTopSpeed * ACCELERATION_NORMAL
	pLocomotion:SetAcceleration( f )
	pLocomotion:SetDeceleration( f )
	pLocomotion:SetJumpHeight( 1640 )
	local f = GetVelocity( self ):Length()
	if f <= 12 || !self:IsOnGround() then self:PromoteSequence( self.m_sIdleSequence )
	elseif f <= ( self.flWalkSpeed * 1.1 ) then
		self:PromoteSequence( "walk", GetVelocity( self ):Length() / self:GetSequenceGroundSpeed( self:LookupSequence "walk" ) )
	else
		self:PromoteSequence( "run", GetVelocity( self ):Length() / self:GetSequenceGroundSpeed( self:LookupSequence "run" )  )
	end
	self:HandleJumpingAlongPath( pPath, flSpeed, tFilter )
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
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 128, 10, 4, 4096, true )
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
	MyTable.Stand( self, MyTable )
end } )

ENT.flLegStatus = 1

function ENT:OnTakeDamage( dDamage )
	local flHealth = Lerp( .25, self:Health(), self:GetMaxHealth() )
	if dDamage:IsDamageType( DMG_CLUB ) then flHealth = flHealth * 24
	// Unlike being kicked, being crushed is blunt damage that is not directed at our parts
	elseif dDamage:IsDamageType( DMG_FALL ) then flHealth = flHealth * 48 end
	local f = math.Clamp( self.flLegStatus - dDamage:GetDamage() / flHealth * 4, 0, 1 )
	self.flLegStatus = f
	local pSchedule = self.Schedule
	if !( pSchedule && pSchedule.m_sName == "GekkoBrainMachineInterfaceError" ) then
		if self.flLegStatus <= math.Rand( 0, dDamage:GetDamage() / flHealth * 100 ) then self:SetSchedule "GekkoBrainMachineInterfaceError" end
	end
	return BaseClass.OnTakeDamage( self, dDamage )
end

ENT.bCanCharge = true
ENT.flChargeTimeMin = 10
ENT.flChargeTimeMax = 20
ENT.flChargeSpeed = 1536
ENT.flChargeTurnRate = 64
RegisterSchedule( "GekkoCharge", { Execute = function( self, sched, MyTable )
	MyTable.flOverrideBodyStiffnessThisTick = 3
	MyTable.flOverrideBodyDampingThisTick = -6
	MyTable.bCharging = true
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
	MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy, MyTable )
	//	MyTable.ComputePath( self, pEnemyPath, pEnemy:GetPos(), MyTable )
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
	MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
	vTarget = self:GetForward() * flSpeed
	vTarget[ 3 ] = v[ 3 ]
	self.loco:SetVelocity( vTarget )
	self:HandleJumpingAlongPath( pEnemyPath, flSpeed, tFilter )
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
			dDamage:SetDamage( flFraction * 65535 )
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
				dDamage:SetDamage( 32768 / flMultiplier )
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

ENT.m_sDefaultIdleSchedule = "UnmannedGearGekkoIdle"
ENT.m_sDefaultCombatSchedule = "UnmannedGearGekkoCombat"

RegisterSchedule( "UnmannedGearGekkoIdle", { Execute = function( self, sched, MyTable )
	if IsValid( MyTable.Enemy ) then return true end
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
end } )

RegisterSchedule( "UnmannedGearGekkoCombat", { Execute = function( self, sched, MyTable )
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
	if LevelOfDetail( sched, "flNextRePath", .5 ) then MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy, MyTable ) end
	MyTable.MoveAlongPath( self, pEnemyPath, MyTable.flTopSpeed )
	local pGoal = pEnemyPath:GetCurrentGoal()
	if pGoal then
		MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
		MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
	end
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
	if CurTime() > ( sched.flNextLow || 0 ) && math.random() <= 2 * FrameTime() then
		self:EmitSound "GekkoLowing"
		util_ScreenShake( self:GetPos() + self:OBBCenter(), 12, 6, 4, 4096, true )
		sched.flNextLow = CurTime() + math.Rand( 3, 4 )
	end
	local flDistance = pEnemyPath:GetLength() - pEnemyPath:GetCursorPosition()
	if flDistance <= MyTable.flRunSpeed then return end
	if math.random() <= flDistance ^ 1.2 / 12288 * FrameTime() then
		local f = MyTable.flChargeSpeed * MyTable.flChargeTimeMin * .5
		if math.random( 3 ) == 1 then self:Taunt() return end
		if flDistance > f then self:Taunt() return end
		MyTable.SetSchedule( self, "GekkoCharge", MyTable )
	end
end } )
