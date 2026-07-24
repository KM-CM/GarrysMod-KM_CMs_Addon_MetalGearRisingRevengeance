// NOTE: We desperately need to rely on more than just UnmannedGearGRAD.Kord.TactileLaser!
// But I didn't code those bone helpers into the base yet, so yeah...

DEFINE_BASECLASS "BaseActor"

if !CLASS_DESPERADO_WORLD_MARSHAL then Add_NPC_Class "CLASS_DESPERADO_WORLD_MARSHAL" end
ENT.iDefaultClass = CLASS_DESPERADO_WORLD_MARSHAL

local MACHINEGUN_BONE = "bone055"
local AUTOCANNON_BONE = "bone000"

ENT.bNightVision = true

ENT.vHullMins = Vector( -100, -100 )
ENT.vHullMaxs = Vector( 100, 100, 240 )
ENT.vHullDuckMins = ENT.vHullMins
ENT.vHullDuckMaxs = ENT.vHullMaxs

ENT.bCannotCarryWeapons = true

ENT.flVisionYaw = 90
ENT.flVisionPitch = 60

ENT.m_sIdleSequence = "idle"

local util_ScreenShake = util.ScreenShake

ENT.tSequenceEvents = {
	wall_enter = {
		[ .1 ] = function( self )
			self:EmitSound "UnmannedGearGRADTransformingSetup"
			self:EmitSound "UnmannedGearGRADTransformingChargeup"
		end,
		[ .3 ] = function( self ) self:EmitSound "UnmannedGearGRADTransformingSetup" end,
		[ .4 ] = function( self )
			self:EmitSound "UnmannedGearGRADTransformingSetup"
			self:EmitSound "UnmannedGearGRADTransformingMetal"
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 4, 1, 1, 4096, true )
		end,
		[ .46 ] = function( self )
			self:EmitSound "UnmannedGearGRADTransformingShift"
			self:EmitSound "UnmannedGearGRADTransformingMetal"
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 4, 1, 1, 4096, true )
		end,
		[ .5 ] = function( self )
			self:EmitSound "UnmannedGearGRADTransformingShift"
		end,
		[ .75 ] = function( self )
			self:EmitSound "UnmannedGearGRADTransformingShift"
		end,
		[ .85 ] = function( self )
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 6, 1, 1, 4096, true )
			self:EmitSound "UnmannedGearGRADTransformingMetal"
		end
	},

	wall_exit = {
		[ .1 ] = function( self )
			self:EmitSound "UnmannedGearGRADTransformingSetup"
			self:EmitSound "UnmannedGearGRADTransformingChargeup"
		end,
		[ .4 ] = function( self )
			self:EmitSound "UnmannedGearGRADTransformingSetup"
		end,
		[ .6 ] = function( self )
			self:EmitSound "UnmannedGearGRADTransformingSetup"
		end,
		[ .72 ] = function( self )
			self:EmitSound "UnmannedGearGRADTransformingMetal"
		end,
		[ .8 ] = function( self )
			self:EmitSound "UnmannedGearGRADTransformingShift"
		end
	},

	walk_f = {
		[ .1 ] = function( self )
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 3, 1, 1, 4096, true )
			self:EmitSound "UnmannedGearGRADWalkShift"
			self:EmitSound "UnmannedGearGRADWalkMetal"
		end,
		[ .4 ] = function( self )
			util_ScreenShake( self:GetPos() + self:OBBCenter(), 3, 1, 1, 4096, true )
			self:EmitSound "UnmannedGearGRADWalkShift"
			self:EmitSound "UnmannedGearGRADWalkMetal"
		end,
	}
}

function ENT:CanTransformIntoBunker() return self:HasSkill "CanTransformIntoBunker" end
function ENT:CanTuck() return self:HasSkill "CanTuck" end

function ENT:GrantDefaultSkills()
	local MyTable = BaseClass.GrantDefaultSkills( self )
	if !MyTable then return end
	MyTable.GrantSkill( self, "UnmannedGearGRAD.CanTransformIntoBunker", MyTable )
	MyTable.GrantSkill( self, "UnmannedGearGRAD.CanAimPose", MyTable )
	MyTable.GrantSkill( self, "UnmannedGearGRAD.Kord.TactileLaser", MyTable )
end

ENT.flBodyStiffness = 40
ENT.flBodyDamping = -120

function ENT:Initialize()
	self:SetModel "models/dughoo/mgrr2025/grad.mdl"
	self:SetHealth( 1048576 )
	self:SetMaxHealth( 1048576 )
	self:SetCollisionBounds( self.vHullMins, self.vHullMaxs )
	self:SetBloodColor( BLOOD_COLOR_MECH )
	if self:PhysicsInitShadow( false, false ) then self:GetPhysicsObject():SetMass( 72576 ) end
	BaseClass.Initialize( self )
	self:GrantDefaultSkills()
end

function ENT:OnKilled( ... )
	if BaseClass.OnKilled( self, ... ) then return end
	self:Remove()
end

ENT.flTopSpeed = 1371
ENT.flRunSpeed = ENT.flTopSpeed
ENT.flWalkSpeed = 100

ENT.flTurnRate = 128

ENT.flSkateTime = 0

function ENT:MoveAlongPath( pPath, flSpeed, _, tFilter )
	local pLocomotion = self.loco
	pLocomotion:SetDesiredSpeed( flSpeed )
	local vVelocity = GetVelocity( self )
	local f = vVelocity:Length()
	local bWalking = f <= ( self.flWalkSpeed * 1.1 )
	pLocomotion:SetAcceleration( self.flTopSpeed * ( bWalking && 5 || .5 ) )
	pLocomotion:SetDeceleration( bWalking && ( self.flTopSpeed * 5 ) || 0 )
	pLocomotion:SetJumpHeight( 0 )
	if f <= 12 || !self:IsOnGround() then self:PromoteSequence( self.m_sIdleSequence )
	elseif bWalking then
		self:PromoteSequence( "walk_f", GetVelocity( self ):Length() / self:GetSequenceGroundSpeed( self:LookupSequence "walk_f" ) )
	else
		self.flSkateTime = CurTime() + .1
		self:PromoteSequence( self.m_sIdleSequence )
		// These loop badly, causing shakes... yeah
		//	vVelocity[ 3 ] = 0
		//	vVelocity:Normalize()
		//	local flDifference = math.AngleDifference( self:GetAngles()[ 3 ], vVelocity:Angle()[ 3 ] )
		//	if flDifference >= -45 || flDifference <= 45 then self:PromoteSequence "dash_f"
		//	elseif flDifference >= -135 || flDifference < 0 then self:PromoteSequence "dash_l"
		//	elseif flDifference <= 135 || flDifference > 0 then self:PromoteSequence "dash_r"
		//	else self:PromoteSequence "dash_b" end
	end
	self:HandleJumpingAlongPath( pPath, flSpeed, tFilter )
end

ENT.flNextMachineGunShot = 0

function ENT:FireMachineGun()
	if CurTime() <= self.flNextMachineGunShot then return end
	self.flNextMachineGunShot = CurTime() + .08

	local iBoneID = self:LookupBone( MACHINEGUN_BONE )
	if !iBoneID then return end
	local vPos, aAngles = self:GetBonePosition( iBoneID )

	local dShoot = aAngles:Up()
	local vShoot = vPos + aAngles:Up() * 80 - aAngles:Right() * 17

	local pEffectData = EffectData()

	pEffectData:SetEntity( self )
	pEffectData:SetMaterialIndex( 0 )

	pEffectData:SetOrigin( vShoot )
	pEffectData:SetStart( vShoot )
	pEffectData:SetNormal( dShoot )
	pEffectData:SetAngles( dShoot:Angle() )
	pEffectData:SetAttachment( 1 )
	pEffectData:SetMagnitude( 1 / ( .08 * math.Rand( .75, 1.25 ) ) )
	util.Effect( "MuzzleFlashGeneric", pEffectData )

	self:FireBullets {
		Attacker = self,
		Src = vShoot,
		Dir = dShoot,
		Tracer = 1,
		Spread = Vector( .17 / 90, .17 / 90 ),
		Damage = 150,
		Num = 1,
		Force = 1
	}

	self:EmitSound "KordFire"
end

ENT.aKordAngles = Angle()
ENT.vKordVelocity = Vector()

ENT.flKordStiffness = 24
ENT.flKordDamping = -4

function ENT:Think( ... )
	local pSkateLoop = self.m_pSkateLoop

	if !pSkateLoop then
		pSkateLoop = CreateSound( self, "UnmannedGearGRADSkateLoop" )
		pSkateLoop:Play()
		pSkateLoop:ChangeVolume( 0 )
		self.m_pSkateLoop = pSkateLoop
	end

	if CurTime() <= self.flSkateTime then
		pSkateLoop:ChangeVolume( math.Approach( pSkateLoop:GetVolume(), 1, FrameTime() ) )
		pSkateLoop:ChangePitch( GetVelocity( self ):Length() / self.flTopSpeed * 75 )
	else
		pSkateLoop:ChangeVolume( math.Approach( pSkateLoop:GetVolume(), 0, FrameTime() ) )
	end

	local iBoneID = self:LookupBone( MACHINEGUN_BONE )
	if iBoneID then
		local vPos, aAngles = self:GetBonePosition( iBoneID )

		local aDesAim

		local vShoot = vPos + aAngles:Up() * 80 - aAngles:Right() * 17

		local vaKordTarget = self.vaAimTargetKord
		if isvector( vaKordTarget ) then
			aDesAim = ( vaKordTarget - vShoot ):Angle()
		elseif isangle( vaKordTarget ) then
			aDesAim = vaKordTarget
		else aDesAim = self:GetAngles() end

		local aCurrentAngles = self:GetAngles()
		aDesAim[ 1 ] = math.NormalizeAngle( aCurrentAngles[ 1 ] + math.Clamp( math.AngleDifference( aDesAim[ 1 ], aCurrentAngles[ 1 ] ), -45, 45 ) )

		local aKordAngles = self.aKordAngles
		aCurrentAngles:Add( aKordAngles )

		local vKordVelocity = self.vKordVelocity
		vKordVelocity:Add( Vector(
			math.AngleDifference( aDesAim[ 1 ], aCurrentAngles[ 1 ] ),
			math.AngleDifference( aDesAim[ 2 ], aCurrentAngles[ 2 ] )
		) * self.flKordStiffness * FrameTime() )
		vKordVelocity:Mul( math.exp( self.flKordDamping * FrameTime() ) )

		aKordAngles[ 1 ] = aKordAngles[ 1 ] + vKordVelocity[ 1 ] * FrameTime()
		aKordAngles[ 2 ] = aKordAngles[ 2 ] + vKordVelocity[ 2 ] * FrameTime()

		if self:HasSkill "UnmannedGearGRAD.Kord.TactileLaser" then
			local tr = util.TraceLine {
				start = vShoot,
				endpos = vShoot + aAngles:Up() * 999999,
				filter = self,
				mask = MASK_OPAQUE_AND_NPCS
			}
			local pEntity = tr.Entity
			if IsValid( pEntity ) && self:UpdateMemory( pEntity ) == "Hostile" then self:FireMachineGun() end
		end

		self:ManipulateBoneAngles( iBoneID, Angle( aKordAngles[ 2 ], 0, aKordAngles[ 1 ] ) )
	end

	return BaseClass.Think( self, ... )
end

function ENT:OnRemove()
	local p = self.m_pSkateLoop
	if p then p:Stop() self.m_pSkateLoop = nil end
	BaseClass.OnRemove( self )
end

function ENT:Stand() self.loco:SetJumpHeight( 0 ) BaseClass.Stand( self ) end

ENT.m_sDefaultCombatSchedule = "UnmannedGearGRADCombat"

RegisterSchedule( "UnmannedGearGRADCombat", { Execute = function( self, sched, MyTable )
	if table.IsEmpty( MyTable.tEnemies ) then return true end
	local pEnemy = self.Enemy
	if !IsValid( pEnemy ) then return true end
	local pEnemy, pTrueEnemy = self:SetupEnemy( pEnemy )

	MyTable.vaAimTargetKord = pEnemy:GetPos() + pEnemy:OBBCenter()

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
	if pGoal then MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle() end

	if !self:IsOnGround() then return end
end } )

local math_Rand = math.Rand

local WALL_MELEE_MINS = Vector( -48, -48, 12 )
local WALL_MELEE_MAXS = Vector( 48, 48, 64 )

RegisterSchedule( "UnmannedGearGRADBunker", {
	Execute = function( self, sched, MyTable )
		MyTable.flAnimationSystemStopFor = CurTime() + 1

		MyTable.flOverrideAimStiffnessThisTick = 0

		MyTable.vaAimTargetBody = self:GetAngles()

		local pEnemy = self.Enemy
		local bIdle = !IsValid( pEnemy ) || table.IsEmpty( MyTable.tEnemies )
		if !MyTable.m_bInBunkerMode then
			MyTable.AnimationSystemHalt( self, MyTable )
			MyTable.m_bInBunkerMode = true
			MyTable.PlaySequenceAndWait( self, "wall_enter", bIdle && math_Rand( .5, 1 ) || math_Rand( 1, 1.5 ), true )
			MyTable.flAnimationSystemStopFor = CurTime() + 1
			return
		end

		if bIdle then
			return
		end

		local pEnemy, pTrueEnemy = self:SetupEnemy( pEnemy )

		MyTable.vaAimTargetKord = pEnemy:GetPos() + pEnemy:OBBCenter()

		local bHit
		if util.TraceHull( {
			start = self:GetPos() + self:GetForward() * 160 - self:GetRight() * 96,
			endpos = self:GetPos() + self:GetForward() * 160 + self:GetRight() * 96,
			mins = WALL_MELEE_MINS,
			maxs = WALL_MELEE_MAXS,
			filter = function( pEntity )
				if MyTable.Disposition( self, pEntity ) == D_HT then bHit = true return true end
				return false
			end,
			mask = MASK_SOLID
		} ).Hit && bHit then
			local flMultiplier = math_Rand( 2 / 3, 1.5 )

			timer.Simple( .8 / flMultiplier, function()
				if !IsValid( self ) then return end
				local bHit
				self:EmitSound "UnmannedGearGRADMelee"
				if util.TraceHull( {
					start = self:GetPos() + self:GetForward() * 160 - self:GetRight() * 96,
					endpos = self:GetPos() + self:GetForward() * 160 + self:GetRight() * 96,
					mins = WALL_MELEE_MINS,
					maxs = WALL_MELEE_MAXS,
					filter = function( pEntity )
						if MyTable.Disposition( self, pEntity, MyTable ) == D_LI then return false end
						local dDamage = DamageInfo()
						dDamage:SetAttacker( self )
						dDamage:SetDamageType( DMG_CLUB )
						dDamage:SetDamage( 16384 / flMultiplier )
						local v = pEntity:GetPos()
						v:Add( pEntity:OBBCenter() )
						v:Sub( self:GetPos() )
						v:Normalize()
						v[ 3 ] = v[ 3 ] + math.Rand( .15, .3 )
						v = LerpVector( math.Rand( 0, .2 ), v, VectorRand() )
						v:Normalize()
						v:Mul( math.Rand( 384 * 85, 768 * 85 ) / flMultiplier )
						dDamage:SetDamageForce( v )
						pEntity:TakeDamageInfo( dDamage )
						if !bHit then self:EmitSound "UnmannedGearGRADImpact" bHit = true end
						return false
					end,
					mask = MASK_SOLID
				// In case we hit the world
				} ).Hit && !bHit then self:EmitSound "UnmannedGearGRADImpact" bHit = true end
				if bHit then
					util_ScreenShake( self:GetPos() + self:OBBCenter(), 64, 48, 2, 4096, true )
				else
					util_ScreenShake( self:GetPos() + self:OBBCenter(), 24, 1, 1, 4096, true )
				end
			end )

			MyTable.AnimationSystemHalt( self, MyTable )
			MyTable.PlaySequenceAndWait( self, "wall_attack1", flMultiplier, true )
			MyTable.flAnimationSystemStopFor = CurTime() + 1
		end
	end,

	OnLeave = function( self, sched, MyTable )
		MyTable.sCallMeInRunBehaviour = "UnmannedGearGRADBunkerLeave"
		MyTable.fCallMeInRunBehaviour = function()
			if !IsValid( self ) then return end
			if MyTable.m_bInBunkerMode then
				MyTable.AnimationSystemHalt( self, MyTable )
				MyTable.m_bInBunkerMode = nil
				MyTable.PlaySequenceAndWait( self, "wall_exit", ( !IsValid( MyTable.Enemy ) || table.IsEmpty( MyTable.tEnemies ) ) && math_Rand( .5, 1 ) || math_Rand( 1, 1.5 ), true )
			end
		end
	end
} )

function ENT:OnTakeDamage( dDamage )
	if BIOLOGICAL_ONLY_DAMAGE_TYPES[ dDamage:GetDamageType() ] then dDamage:ScaleDamage( 0 ) end
	BaseClass.OnTakeDamage( self, dDamage )
end
