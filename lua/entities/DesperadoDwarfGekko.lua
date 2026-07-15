AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

scripted_ents.Register( ENT, "DesperadoDwarfGekko" )

list.Set( "NPC", "DesperadoDwarfGekko", {
	Name = "#DesperadoDwarfGekko",
	Class = "DesperadoDwarfGekko",
	Category = "Desperado Enforcement LLC"
} )

sound.Add {
	name = "DwarfGekkoImpact",
	channel = CHAN_AUTO,
	volume = 1,
	level = 90,
	pitch = { 90, 100 },
	sound = "dughoo_mgrr2025/gekkos/slap_hit.wav"
}

if !SERVER then return end

if !CLASS_DESPERADO_AND_WORLD_MARSHAL then Add_NPC_Class "CLASS_DESPERADO_AND_WORLD_MARSHAL" end

ENT.bNightVision = true

ENT.iDefaultClass = CLASS_DESPERADO_AND_WORLD_MARSHAL

ENT.bCannotCarryWeapons = true

ENT.m_sIdleSequence = "idle"

ENT.flTopSpeed = 200
ENT.flRunSpeed = ENT.flTopSpeed
ENT.flWalkSpeed = 100

ENT.flTurnRate = 128

ENT.flVisionYaw = 60
ENT.flVisionPitch = 45

function ENT:MoveAlongPath( pPath, flSpeed, _, tFilter )
	self.loco:SetDesiredSpeed( flSpeed )
	local f = flSpeed * ACCELERATION_NORMAL
	self.loco:SetAcceleration( f )
	self.loco:SetDeceleration( f )
	self.loco:SetJumpHeight( 256 )
	local f = GetVelocity( self ):Length()
	if f <= 12 then self:PromoteSequence "idle"
	// We only have a running sequence, not a walking one, so play that
	else self:PromoteSequence( "run", GetVelocity( self ):Length() / self:GetSequenceGroundSpeed( self:LookupSequence "run" ) ) end
	self:HandleJumpingAlongPath( pPath, flSpeed, tFilter )
end

function ENT:OnKilled( ... )
	if BaseClass.OnKilled( self, ... ) then return end
	self:Remove()
end

ENT.m_sDefaultCombatSchedule = "DwarfGekkoCombat"
RegisterSchedule( "DwarfGekkoCombat", { Execute = function( self, sched, MyTable )
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
		MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
	end
	local bHit
	util.TraceHull {
		start = self:GetPos(),
		endpos = self:GetPos() + self:GetForward() * MyTable.GAME_flReach,
		mins = MyTable.vHullMins * 1.5 + Vector( 0, 0, 12 ),
		maxs = MyTable.vHullMaxs * 1.5,
		filter = function( pEntity )
			if pEntity == pTrueEnemy then bHit = true return true end
			return false
		end,
		mask = MASK_SOLID
	}
	if bHit then
		MyTable.SetSchedule( self, "DwarfGekkoAttackGrab", MyTable )
		//	return
	end
end } )

RegisterSchedule( "DwarfGekkoAttackGrab", { Execute = function( self, sched, MyTable )
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
	timer.Simple( .4, function()
		if !IsValid( self ) then return end
		local bHit, bHitEnemy
		if util.TraceHull( {
			start = self:GetPos(),
			endpos = self:GetPos() + self:GetForward() * MyTable.GAME_flReach,
			mins = MyTable.vHullMins * 1.5 + Vector( 0, 0, 12 ),
			maxs = MyTable.vHullMaxs * 1.5,
			filter = function( pEntity )
				if MyTable.Disposition( self, pEntity, MyTable ) == D_LI then return false end
				if !bHitEnemy && IsValid( pTrueEnemy ) && pEntity == pTrueEnemy then bHitEnemy = true end
				local v = GetVelocity( pEntity )
				local l = v:Length()
				SetVelocity( pEntity, v:GetNormalized() * math.max( l - 512, 0 ) )
				local dDamage = DamageInfo()
				dDamage:SetAttacker( self )
				dDamage:SetDamageType( DMG_CLUB )
				dDamage:SetDamage( math.Clamp( pEntity:GetMaxHealth() * .12, 8, 12 ) )
				pEntity:TakeDamageInfo( dDamage )
				if !bHit then self:EmitSound "DwarfGekkoImpact" bHit = true end
				return false
			end,
			mask = MASK_SOLID
		} ).Hit && !bHit then self:EmitSound "DwarfGekkoImpact" bHit = true end
	end )
	MyTable.AnimationSystemHalt( self, MyTable )
	MyTable.PlaySequenceAndWait( self, "attack_grab", 1.33 )
	MyTable.PromoteSequenceInstant( self, MyTable.m_sIdleSequence )
	MyTable.AnimationSystemTick( self, MyTable )
	return true
end } )

function ENT:Initialize()
	self:SetModel "models/dughoo/mgrr2025/tripod3.mdl"
	// they get hp, cuz they robot
	self:SetHealth( 256 )
	self:SetMaxHealth( 256 )
	self:SetCollisionBounds( self.vHullMins, self.vHullMaxs )
	self:PhysicsInitShadow( SOLID_OBB )
	BaseClass.Initialize( self )
end
