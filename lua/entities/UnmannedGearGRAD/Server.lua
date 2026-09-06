// NOTE: We desperately need to rely on more than just UnmannedGearGRAD.Kord.TactileLaser!
// But I didn't code those bone helpers into the base yet, so yeah...

DEFINE_BASECLASS "BaseActor"

if !CLASS_DESPERADO_WORLD_MARSHAL then Add_NPC_Class "CLASS_DESPERADO_WORLD_MARSHAL" end
ENT.iDefaultClass = CLASS_DESPERADO_WORLD_MARSHAL

local MACHINEGUN_BONE = "bone056"
local AUTOCANNON_BONE = "bone010"

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

ENT.flBodyStiffness = 4
ENT.flBodyDamping = -12

function ENT:Initialize()
	self:SetModel "models/dughoo/mgrr2025/grad.mdl"

	self:SetHealth( 65536 )
	self:SetMaxHealth( 65536 )

	self:SetCollisionBounds( self.vHullMins, self.vHullMaxs )

	self:SetBloodColor( BLOOD_COLOR_MECH )

	if self:PhysicsInitShadow( false, false ) then self:GetPhysicsObject():SetMass( 36288 ) end

	self:GrantDefaultSkills()

	self.aKordAngles = Angle()
	self.vKordVelocity = Vector()

	self.aCannonAngles = Angle()
	self.vCannonVelocity = Vector()

	BaseClass.Initialize( self )
end

function ENT:OnKilled( ... )
	if BaseClass.OnKilled( self, ... ) then return end
	self:Remove()
end

ENT.flTopSpeed = 1750
ENT.flJogSpeed = ENT.flTopSpeed
ENT.flWalkSpeed = 100

ENT.flSkateTime = 0

function ENT:MoveAlongPath( pPath, flSpeed, _, tFilter )
	local pLocomotion = self.loco
	pLocomotion:SetDesiredSpeed( flSpeed )
	local vVelocity = GetVelocity( self )
	local f = vVelocity:Length()
	local bWalking = f <= ( self.flWalkSpeed * 1.1 )
	local flAccelDecel = self.flTopSpeed * ( bWalking && 5 || .5 )
	pLocomotion:SetAcceleration( flAccelDecel )
	pLocomotion:SetDeceleration( flAccelDecel )
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
	self:GrountMovement( pPath, flSpeed, tFilter )
end

ENT.flNextMachineGunShot = 0

function ENT:FireKord()
	if CurTime() <= self.flNextMachineGunShot then return end
	self.flNextMachineGunShot = CurTime() + .08

	local iBoneID = self:LookupBone( MACHINEGUN_BONE )
	if !iBoneID then return end

	local vPos, aAngles = self:GetBonePosition( iBoneID )

	local dShoot = aAngles:Up()
	local vShoot = vPos + aAngles:Up() * 57 - aAngles:Right() * 3.1

	local pEffectData = EffectData()

	pEffectData:SetEntity( self )
	pEffectData:SetMaterialIndex( 0 )

	pEffectData:SetOrigin( vShoot )
	pEffectData:SetStart( vShoot )
	pEffectData:SetNormal( dShoot )
	pEffectData:SetAngles( dShoot:Angle() )
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

ENT.flNextCannonShot = 0

function ENT:FireCannon()
	if CurTime() <= self.flNextCannonShot then return end
	self.flNextCannonShot = CurTime() + 1 / 3

	local iBoneID = self:LookupBone( AUTOCANNON_BONE )
	if !iBoneID then return end

	local vPos, aAngles = self:GetBonePosition( iBoneID )

	local dShoot = aAngles:Up()
	local aShoot = dShoot:Angle()

	dShoot = ( aShoot:Forward() + ( math.Rand( -.5, .5 ) + math.Rand( -.5, .5 ) ) * .012 * aShoot:Right() + ( math.Rand( -.5, .5 ) + math.Rand( -.5, .5 ) ) * .012 * aShoot:Up() ):GetNormalized()
	aShoot = dShoot:Angle()

	local vShoot = vPos + aAngles:Up() * 73 + aAngles:Right() * 5

	local pEffectData = EffectData()
	pEffectData:SetEntity( self )
	pEffectData:SetOrigin( vShoot )
	pEffectData:SetStart( vShoot )
	pEffectData:SetNormal( dShoot )
	pEffectData:SetAngles( dShoot:Angle() )
	util.Effect( "UnmannedGearGRAD76MMMuzzleFlash", pEffectData )

	local pShell = ents.Create "UnmannedGearGRAD76MMShell"
	pShell:SetPos( vShoot )
	pShell:SetAngles( aShoot )
	pShell:SetOwner( self )
	pShell:Spawn()

	self:EmitSound "GRADCannonFire"
end

ENT.flKordStiffness = 24
ENT.flKordDamping = -4

ENT.flCannonStiffness = 16
ENT.flCannonDamping = -4

ENT.flLastCustomBodyYaw = 0

function ENT:Think( ... )
	local pSkateLoop = self.m_pSkateLoop

	if !pSkateLoop then
		pSkateLoop = CreateSound( self, "UnmannedGearGRADSkateLoop" )
		pSkateLoop:Play()
		pSkateLoop:ChangeVolume( 0 )
		self.m_pSkateLoop = pSkateLoop
	end

	local b = CurTime() <= self.flSkateTime
	self:SetIsSliding( b )
	if b then
		pSkateLoop:ChangeVolume( math.Approach( pSkateLoop:GetVolume(), 1, FrameTime() ) )
		local flSlide = GetVelocity( self ):Length() / self.flTopSpeed
		pSkateLoop:ChangePitch( flSlide ^ .5 * 125 )
		self:SetSlideStrength( flSlide )
	else
		pSkateLoop:ChangeVolume( math.Approach( pSkateLoop:GetVolume(), 0, FrameTime() ) )
	end

	local iBoneID = self:LookupBone( AUTOCANNON_BONE )
	if iBoneID && self.aCannonAngles then
		local vPos, aAngles = self:GetBonePosition( iBoneID )

		local aDesAim

		local vShoot = vPos + aAngles:Up() * 73 + aAngles:Right() * 5

		local vaCannonTarget = self.vaAimTargetCannon
		if isvector( vaCannonTarget ) then
			aDesAim = ( vaCannonTarget - vShoot ):Angle()
		elseif isangle( vaCannonTarget ) then
			aDesAim = vaCannonTarget
		else aDesAim = self:GetAngles() end

		local aCurrentAngles = self:GetAngles()
		if self.m_bInBunkerMode then
			// I don't know why, but for some reason, this simple inversion actually works :D
			aDesAim[ 1 ] = math.NormalizeAngle( aCurrentAngles[ 1 ] + math.Clamp( math.AngleDifference( aCurrentAngles[ 1 ], aDesAim[ 1 ] ), -60, 60 ) )
			aDesAim[ 2 ] = math.NormalizeAngle( aCurrentAngles[ 2 ] + math.Clamp( math.AngleDifference( aCurrentAngles[ 2 ], aDesAim[ 2 ] ), -60, 60 ) )
		else
			aDesAim[ 1 ] = math.NormalizeAngle( aCurrentAngles[ 1 ] + math.Clamp( math.AngleDifference( aDesAim[ 1 ], aCurrentAngles[ 1 ] ), -60, 60 ) )
			aDesAim[ 2 ] = math.NormalizeAngle( aCurrentAngles[ 2 ] + math.Clamp( math.AngleDifference( aDesAim[ 2 ], aCurrentAngles[ 2 ] ), -60, 60 ) )
		end

		local aCannonAngles = self.aCannonAngles
		aCurrentAngles:Add( aCannonAngles )

		local vCannonVelocity = self.vCannonVelocity
		vCannonVelocity:Add( Vector(
			math.AngleDifference( aDesAim[ 1 ], aCurrentAngles[ 1 ] ),
			math.AngleDifference( aDesAim[ 2 ], aCurrentAngles[ 2 ] )
		) * self.flCannonStiffness * FrameTime() )
		vCannonVelocity:Mul( math.exp( self.flCannonDamping * FrameTime() ) )

		aCannonAngles[ 1 ] = aCannonAngles[ 1 ] + vCannonVelocity[ 1 ] * FrameTime()
		aCannonAngles[ 2 ] = aCannonAngles[ 2 ] + vCannonVelocity[ 2 ] * FrameTime()

		self:ManipulateBoneAngles( iBoneID, Angle( aCannonAngles[ 2 ], 0, aCannonAngles[ 1 ] ) )
	end

	local iBoneID = self:LookupBone( MACHINEGUN_BONE )
	if iBoneID && self.aKordAngles then
		local vPos, aAngles = self:GetBonePosition( iBoneID )

		local aDesAim

		local vShoot = vPos + aAngles:Up() * 57 - aAngles:Right() * 3.1

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
			if IsValid( pEntity ) && self:UpdateMemory( pEntity ) == "Hostile" then self:FireKord() end
		end

		self:SetKordAngles( self:GetAngles() + Angle( aKordAngles[ 1 ], aKordAngles[ 2 ] ) )
		self:ManipulateBoneAngles( iBoneID, Angle( aKordAngles[ 2 ], 0, aKordAngles[ 1 ] ) )
	end

	return BaseClass.Think( self, ... )
end

function ENT:CanFireKord( pEnemy, pTrueEnemy, MyTable )
	local iBoneID = self:LookupBone( MACHINEGUN_BONE )
	if !iBoneID then return end

	local vPos, aAngles = self:GetBonePosition( iBoneID )

	return MyTable.CanAttackCustom( self, pEnemy, pTrueEnemy, MyTable, nil, aAngles:Up(), vPos + aAngles:Up() * 80 - aAngles:Right() * 17, .17, .17 )
end

function ENT:CanFireCannon( pEnemy, pTrueEnemy, MyTable )
	local iBoneID = self:LookupBone( AUTOCANNON_BONE )
	if !iBoneID then return end

	local vPos, aAngles = self:GetBonePosition( iBoneID )

	// TODO: Implement CanAttackCustomRadius
	return MyTable.CanAttackCustom( self, pEnemy, pTrueEnemy, MyTable, nil, aAngles:Up(), vPos + aAngles:Up() * 73 + aAngles:Right() * 5, .12, .12 )
end

function ENT:OnRemove()
	local p = self.m_pSkateLoop
	if p then p:Stop() self.m_pSkateLoop = nil end
	BaseClass.OnRemove( self )
end

function ENT:Stand() self.loco:SetJumpHeight( 0 ) BaseClass.Stand( self ) end

ENT.m_sDefaultCombatSchedule = "UnmannedGearGRADCombat"

RegisterSchedule( "UnmannedGearGRADCombat", { Execute = function( self, pSchedule, MyTable )
	if table.IsEmpty( MyTable.tEnemies ) then return true end

	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end

	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy )

	MyTable.vaAimTargetKord = pEnemy:GetPos() + pEnemy:OBBCenter()
	MyTable.vaAimTargetCannon = MyTable.vaAimTargetKord

	local f = self:BoundingRadius()
	f = f * f

	local v = self:GetPos()
	if pEnemy.__ACTOR_BULLSEYE__ && v:DistToSqr( pEnemy:NearestPoint( v ) ) <= f && ( pEnemy == pTrueEnemy || pTrueEnemy:NearestPoint( pEnemy:GetPos() ):DistToSqr( pEnemy:GetPos() ) > f ) then
		self:ReportPositionAsClear( pEnemy:GetPos() )
		return
	end

	if self:Visible( pEnemy ) && !MyTable.UpdatePursuitSenses( self, pEnemy, pTrueEnemy, MyTable ) && math.random( 2 ) == 1 then
		MyTable.SetSchedule( self, "GRADCombatWalk", MyTable )
	else MyTable.SetSchedule( self, "GRADSlideToMelee", MyTable ) end
end } )

RegisterSchedule( "GRADSlideToMelee", { Execute = function( self, pSchedule, MyTable )
	if table.IsEmpty( MyTable.tEnemies ) then return true end

	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end

	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy )

	MyTable.vaAimTargetKord = pEnemy:GetPos() + pEnemy:OBBCenter()
	MyTable.vaAimTargetCannon = MyTable.vaAimTargetKord

	local f = self:BoundingRadius()
	f = f * f

	local v = self:GetPos()
	if pEnemy.__ACTOR_BULLSEYE__ && v:DistToSqr( pEnemy:NearestPoint( v ) ) <= f && ( pEnemy == pTrueEnemy || pTrueEnemy:NearestPoint( pEnemy:GetPos() ):DistToSqr( pEnemy:GetPos() ) > f ) then
		self:ReportPositionAsClear( pEnemy:GetPos() )
		return
	end

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then pEnemyPath = Path "Follow" MyTable.pEnemyPath = pEnemyPath end
	if LevelOfDetail( pSchedule, "flNextRePath" ) then MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy, MyTable ) end

	MyTable.MoveAlongPath( self, pEnemyPath, MyTable.flTopSpeed )

	local pGoal = pEnemyPath:GetCurrentGoal()
	if pGoal then MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle() end


	MyTable.flWeaponPrimaryVolleyTimeMin = 0
	MyTable.flWeaponPrimaryVolleyTimeMax = 2

	MyTable.flWeaponPrimaryVolleyBreakMin = 0
	MyTable.flWeaponPrimaryVolleyBreakMax = 1

	if MyTable.WeaponPrimaryVolleyContainer( self, "Kord", true, MyTable ) && MyTable.CanFireKord( self, pEnemy, pTrueEnemy, MyTable ) then MyTable.FireKord( self, MyTable ) end


	MyTable.flWeaponPrimaryVolleyTimeMin = 0
	MyTable.flWeaponPrimaryVolleyTimeMax = 4

	MyTable.flWeaponPrimaryVolleyBreakMin = 0
	MyTable.flWeaponPrimaryVolleyBreakMax = 16

	MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMin = 0
	MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMax = 1

	if MyTable.WeaponPrimaryVolleyContainer( self, "Cannon", nil, MyTable ) && MyTable.CanFireCannon( self, pEnemy, pTrueEnemy, MyTable ) then MyTable.FireCannon( self, MyTable ) end

	if !MyTable.UpdatePursuitSenses( self, pEnemy, pTrueEnemy, MyTable ) && self:Visible( pEnemy ) && math.random() <= .2 * FrameTime() then
		MyTable.SetSchedule( self, "GRADCombatWalk", MyTable )
	end
end } )

RegisterSchedule( "GRADCombatWalk", { Execute = function( self, pSchedule, MyTable )
	if table.IsEmpty( MyTable.tEnemies ) then return true end

	local pEnemy = MyTable.Enemy
	if !IsValid( pEnemy ) then return true end

	local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy )

	MyTable.vaAimTargetKord = pEnemy:GetPos() + pEnemy:OBBCenter()
	MyTable.vaAimTargetCannon = MyTable.vaAimTargetKord

	local f = self:BoundingRadius()
	f = f * f

	local v = self:GetPos()
	if pEnemy.__ACTOR_BULLSEYE__ && v:DistToSqr( pEnemy:NearestPoint( v ) ) <= f && ( pEnemy == pTrueEnemy || pTrueEnemy:NearestPoint( pEnemy:GetPos() ):DistToSqr( pEnemy:GetPos() ) > f ) then
		self:ReportPositionAsClear( pEnemy:GetPos() )
		return
	end

	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then pEnemyPath = Path "Follow" MyTable.pEnemyPath = pEnemyPath end
	if LevelOfDetail( pSchedule, "flNextRePath" ) then MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy, MyTable ) end

	MyTable.MoveAlongPath( self, pEnemyPath, MyTable.flWalkSpeed )

	local pGoal = pEnemyPath:GetCurrentGoal()
	if pGoal then MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle() end


	MyTable.flWeaponPrimaryVolleyTimeMin = 0
	MyTable.flWeaponPrimaryVolleyTimeMax = 3

	MyTable.flWeaponPrimaryVolleyBreakMin = 0
	MyTable.flWeaponPrimaryVolleyBreakMax = 1

	if MyTable.WeaponPrimaryVolleyContainer( self, "Kord", true, MyTable ) && MyTable.CanFireKord( self, pEnemy, pTrueEnemy, MyTable ) then MyTable.FireKord( self, MyTable ) end


	MyTable.flWeaponPrimaryVolleyTimeMin = 0
	MyTable.flWeaponPrimaryVolleyTimeMax = 4

	MyTable.flWeaponPrimaryVolleyBreakMin = 0
	MyTable.flWeaponPrimaryVolleyBreakMax = 8

	MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMin = 0
	MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMax = 1

	if MyTable.WeaponPrimaryVolleyContainer( self, "Cannon", nil, MyTable ) && MyTable.CanFireCannon( self, pEnemy, pTrueEnemy, MyTable ) then MyTable.FireCannon( self, MyTable ) end

	if MyTable.UpdatePursuitSenses( self, pEnemy, pTrueEnemy, MyTable ) || math.random() <= ( self:Visible( pEnemy ) && .1 || .5 ) * MyTable.m_flFrameTime then
		MyTable.SetSchedule( self, "GRADSlideToMelee", MyTable )
	end
end } )

local math_Rand = math.Rand

local WALL_MELEE_MINS = Vector( -48, -48, 12 )
local WALL_MELEE_MAXS = Vector( 48, 48, 64 )

local function BunkerFire( self, pSchedule, MyTable, pEnemy, pTrueEnemy )
	MyTable.vaAimTargetKord = pEnemy:GetPos() + pEnemy:OBBCenter()
	MyTable.vaAimTargetCannon = MyTable.vaAimTargetKord
	
	MyTable.flWeaponPrimaryVolleyTimeMin = 0
	MyTable.flWeaponPrimaryVolleyTimeMax = 4
	
	MyTable.flWeaponPrimaryVolleyBreakMin = 0
	MyTable.flWeaponPrimaryVolleyBreakMax = 1
	
	if MyTable.WeaponPrimaryVolleyContainer( self, "Kord", true, MyTable ) && MyTable.CanFireKord( self, pEnemy, pTrueEnemy, MyTable ) then MyTable.FireKord( self, MyTable ) end

	// Autocannon is handled differently!
end

RegisterSchedule( "GRADBunker", {
	Execute = function( self, pSchedule, MyTable )
		MyTable.flAnimationSystemStopFor = CurTime() + 1

		MyTable.flOverrideAimStiffnessThisTick = 0

		MyTable.vaAimTargetBody = self:GetAngles()

		local pEnemy = MyTable.Enemy
		local bIdle = !IsValid( pEnemy ) || table.IsEmpty( MyTable.tEnemies )
		if !MyTable.m_bInBunkerMode then
			MyTable.AnimationSystemHalt( self, MyTable )
			MyTable.m_bInBunkerMode = true
			self:SetIsSliding( false )
			MyTable.PlaySequenceAndWait( self, "wall_enter", bIdle && math_Rand( .5, 1 ) || math_Rand( 1, 1.5 ), true )
			MyTable.flAnimationSystemStopFor = CurTime() + 1
			return
		end

		if bIdle then
			if math.random() <= .01 * MyTable.m_flFrameTime then return true end
			return
		end

		local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy )


		BunkerFire( self, pSchedule, MyTable, pEnemy, pTrueEnemy )


		MyTable.flWeaponPrimaryVolleyTimeMin = 0
		MyTable.flWeaponPrimaryVolleyTimeMax = 3

		MyTable.flWeaponPrimaryVolleyBreakMin = 0
		MyTable.flWeaponPrimaryVolleyBreakMax = 1

		if MyTable.WeaponPrimaryVolleyContainer( self, "Cannon", true, MyTable ) && MyTable.CanFireCannon( self, pEnemy, pTrueEnemy, MyTable ) then MyTable.FireCannon( self, MyTable ) end


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
			MyTable.PlaySequenceAndWait( self, "wall_attack1", flMultiplier, true, function()
				if !IsValid( pEnemy ) || !IsValid( pTrueEnemy ) then return end
				BunkerFire( self, pSchedule, MyTable, pEnemy, pTrueEnemy )
			end )
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
				self:SetIsSliding( false )
				MyTable.PlaySequenceAndWait( self, "wall_exit", ( !IsValid( MyTable.Enemy ) || table.IsEmpty( MyTable.tEnemies ) ) && math_Rand( .5, 1 ) || math_Rand( 1, 1.5 ), true )
			end
		end
	end
} )

function ENT:OnTakeDamage( dDamage )
	if BIOLOGICAL_ONLY_DAMAGE_TYPES[ dDamage:GetDamageType() ] then dDamage:ScaleDamage( 0 ) end
	dDamage:ScaleDamage( math.Remap( dDamage:GetDamage(), 0, self:Health(), .1, 1 / 3 ) )
	BaseClass.OnTakeDamage( self, dDamage )
end
