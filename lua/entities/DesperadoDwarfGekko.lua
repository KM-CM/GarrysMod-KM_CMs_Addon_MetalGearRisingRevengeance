// I commented the file even when obvious, because I want this to be like
// a tutorial on how to make simple but high quality Actors for no reason

// Sends the file to the client. It's obviously necessary for the client to know what we are, duh.
AddCSLuaFile()
// We are an Actor. Duh.
DEFINE_BASECLASS "BaseActor"

// Garry's Mod's file capsing is weird. If we don't want it to be ugly desperadodwarfgekko,
// we must do this. Don't follow the standard Source classname rules
// (e.g. npc_desperado_dwarf_gekko), they are very ugly, just identify the object.
scripted_ents.Register( ENT, "DesperadoDwarfGekko" )

// Appears in the spawn menu, also duh
list.Set( "NPC", "DesperadoDwarfGekko", {
	Name = "#DesperadoDwarfGekko",
	Class = "DesperadoDwarfGekko",
	Category = "Desperado Enforcement LLC"
} )

// This noise is relatively silent, therefore it does not need a ^ variant
// Prefixing the sound with ^ splits the stereo into two mono channels:
// when the sound is close up, the left channel of the sound plays
// in both ears, and when the sound is far, the right does.
// They transition, too! This is how distant sounds are made.
// Distant sounds are very cool and very creepy.
sound.Add( {
	name = "DwarfGekkoImpact",
	channel = CHAN_AUTO,
	volume = 1,
	level = 90,
	pitch = { 90, 100 },
	sound = "dughoo_mgrr2025/gekkos/slap_hit.wav"
} )

// The client doesn't need to know anything below... you could replace this with an include
// so the client doesn't download all of this, but meh, who cares, anyway?
if !SERVER then return end

// There can, obviously, be multiple things using this class, therefore do not re-add it if it already exists
if !CLASS_DESPERADO_AND_WORLD_MARSHAL then Add_NPC_Class "CLASS_DESPERADO_AND_WORLD_MARSHAL" end

// What side we fight on. Using the line above, can you guess this from three tries?
ENT.iDefaultClass = CLASS_DESPERADO_AND_WORLD_MARSHAL

ENT.bCannotCarryWeapons = true

// This sequence will play whenever we don't set one, as a replacement for reference posing
ENT.m_sIdleSequence = "idle"

ENT.flTopSpeed = 200
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
	// We only have a running sequence, not a walking one, so play that
	else self:PromoteSequence( "run", GetVelocity( self ):Length() / self:GetSequenceGroundSpeed( self:LookupSequence "run" ) ) end
	self:HandleJumpingAlongPath( pPath, flSpeed, tFilter )
end

// Just freaking vanish when dead
function ENT:OnKilled( ... )
	// That is, unless we are already dead and this is somehow called again
	if BaseClass.OnKilled( self, ... ) then return end
	self:Remove()
end

// We don't have any special idle behaviour
// ENT.m_sDefaultIdleSchedule = "DwarfGekkoIdle"

// However, we do have special combat behaviour.
// This sets our combat schedule to the new one,
ENT.m_sDefaultCombatSchedule = "DwarfGekkoCombat"
// and below is the code of that schedule itself
Actor_RegisterSchedule( "DwarfGekkoCombat", function(
	// This is a pointer to what is running the schedule.
	// This is a special schedule, not a generic one,
	// so we can assume we are a Dwarf Gekko.
	self,
	// The schedule data so far. Will be removed when and if we stop
	// running the schedule, for example if we bail or get another
	sched,
	// The Lua part of the entity. Essentially FindMetaTable( "Entity" ).GetTable( self ).
	// When we do self.X, Lua calls the code I stated above each time. This has all the
	// variables set in Lua, but not C-side things like GetPos(), in which you'll either do
	// local CEntity_GetPos = FindMetaTable( "Entity" ).GetPos and then CEntity_GetPos( self ),
	// or do the dreaded __index metamethod of entities and call self:GetPos()... the latter
	// is not as bad, because __index finds entity methods before calling GetTable.
	// StrawWagen also uses this and passes it everywhere, so I'll quote him:
    -- why go through so much effort properly waterfall down this table?
    -- BECAUSE ~10X PERF GAINS!
    -- always pass this beautiful table, else reckon the fps-draining scourge of the _index call....
	MyTable )
	// If we do not have any enemies, bail
	if table.IsEmpty( MyTable.tEnemies ) then return true end
	local pEnemy = MyTable.Enemy
	// If we do not have a selected enemy, also bail
	if !IsValid( pEnemy ) then return true end
	// This resolves the bullseye (what we know of them, pEnemy) and the actual entity pointer (pTrueEnemy),
	// however do note that the entity may be already removed, or may have never existed to begin with,
	// in which case, the script won't fail you and just make it so that pEnemy = pTrueEnemy
	local pEnemy, pTrueEnemy = self:SetupEnemy( pEnemy )
	local f = self:BoundingRadius()
	f = f * f
	local v = self:GetPos()
	// If the enemy vanished, also ALSO bail
	if pEnemy.__ACTOR_BULLSEYE__ && v:DistToSqr( pEnemy:NearestPoint( v ) ) <= f && ( pEnemy == pTrueEnemy || pTrueEnemy:NearestPoint( pEnemy:GetPos() ):DistToSqr( pEnemy:GetPos() ) > f ) then
		self:ReportPositionAsClear( pEnemy:GetPos() )
		return true
	end
	local pEnemyPath = MyTable.pEnemyPath
	if !pEnemyPath then pEnemyPath = Path "Follow" MyTable.pEnemyPath = pEnemyPath end
	// Do not perform the very heavy action of recomputing our path to the enemy often
	if LevelOfDetail( sched, "flNextRePath" ) then MyTable.ComputeFlankPath( self, pEnemyPath, pEnemy, MyTable ) end
	MyTable.MoveAlongPath( self, pEnemyPath, MyTable.flTopSpeed )
	// Face wherever we are currently walking
	local pGoal = pEnemyPath:GetCurrentGoal()
	if pGoal then
		// This is the body facing
		MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
		// And this is the head facing. We don't have any, but keep the variable filled anyway.
		MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
	end
	// This is the variable that will determine if we'll hit the enemy. Not accounting for time, however.
	local bHit
	// Perform a trace with collision bounds
	util.TraceHull {
		start = self:GetPos(),
		endpos = self:GetPos() + self:GetForward() * MyTable.GAME_flReach,
		mins = MyTable.vHullMins * 1.5 + Vector( 0, 0, 12 ),
		maxs = MyTable.vHullMaxs * 1.5,
		filter = function( pEntity )
			// This is the enemy, meaning the actual attack trace will hit 'em too
			if pEntity == pTrueEnemy then bHit = true return true end
			return false
		end,
		mask = MASK_SOLID
	}
	// If we can hit them, do so
	if bHit then
		// Keep in mind that we are NOT bailing. If we bail, we'll call
		// SelectSchedule, and the schedule we set here will not be ran
		MyTable.SetSchedule( self, "DwarfGekkoAttackGrab", MyTable )
		return // Not a "return true" here, as we are not bailing
	end
end )

// This is the "in attack schedule"
Actor_RegisterSchedule( "DwarfGekkoAttackGrab", function( self, sched, MyTable )
	local pEnemy, pTrueEnemy = MyTable.Enemy
	// If there is no enemy BEFORE we started the animation, bail. Do not bail mid animation, though.
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
	// Roughly synchronized with the animation
	timer.Simple( .4, function()
		// If we do not exist anymore, bail
		if !IsValid( self ) then return end
		local bHit, bHitEnemy
		// Perform the actual attack trace...
		if util.TraceHull( {
			start = self:GetPos(),
			endpos = self:GetPos() + self:GetForward() * MyTable.GAME_flReach,
			mins = MyTable.vHullMins * 1.5 + Vector( 0, 0, 12 ),
			maxs = MyTable.vHullMaxs * 1.5,
			// We do damage effects via the filter instead of using the result's Entity field to
			// be able to damage multiple enemies and any object that happens to be in the way
			filter = function( pEntity )
				if MyTable.Disposition( self, pEntity, MyTable ) == D_LI then return false end
				if !bHitEnemy && IsValid( pTrueEnemy ) && pEntity == pTrueEnemy then bHitEnemy = true end
				// Slow them down, since we're grabbing them
				local v = GetVelocity( pEntity )
				local l = v:Length()
				SetVelocity( pEntity, v:GetNormalized() * math.max( l - 512, 0 ) )
				local dDamage = DamageInfo()
				dDamage:SetAttacker( self )
				dDamage:SetDamageType( DMG_CLUB )
				// Get slapped
				dDamage:SetDamage( math.Clamp( pEntity:GetMaxHealth() * .12, 8, 12 ) )
				pEntity:TakeDamageInfo( dDamage )
				if !bHit then self:EmitSound "DwarfGekkoImpact" bHit = true end
				return false
			end,
			mask = MASK_SOLID
		// This is done in case we hit the world (filter isn't called when we do)
		} ).Hit && !bHit then self:EmitSound "DwarfGekkoImpact" bHit = true end
	end )
	// Stop all walking, running, idle, etcetera animations
	MyTable.AnimationSystemHalt( self, MyTable )
	// And play an attack animation at 133% speed
	// NOTE: This yields the code HERE AND NOW
	MyTable.PlaySequenceAndWait( self, "attack_grab", 1.33 )
	// Then, put us right back into the idle sequence. If we don't,
	// we won't be immediately be put into it, but rather after it
	// lerps in, which will mean 1/4th of a second of reference posing
	MyTable.PromoteSequenceInstant( self, MyTable.m_sIdleSequence )
	// Force an animation system tick right now to apply it.
	// They are normally after each run, but since we're halting
	// the main coroutine with PlaySequenceAndWait, this is
	// necessary or the thing above doesn't work for some reason
	MyTable.AnimationSystemTick( self, MyTable )
	// We're now done attacking. Bail.
	return true
end )

// Called when we spawn
function ENT:Initialize()
	self:SetModel "models/dughoo/mgrr2025/tripod3.mdl"
	// they get hp, cuz they robot
	self:SetHealth( 512 )
	self:SetMaxHealth( 512 )
	// Give ourselves a physics object and the bounds.
	// No, this is not done manually in BaseClass.Initialize.
	self:SetCollisionBounds( self.vHullMins, self.vHullMaxs )
	self:PhysicsInitShadow( SOLID_OBB )
	// Initialize the Actor part of us, e.g. squad tracking,
	// making us count as an object, etcetera. This is very important!
	BaseClass.Initialize( self )
end
