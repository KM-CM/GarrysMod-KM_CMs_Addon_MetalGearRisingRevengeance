function ENT:OnSeeWeapon( pWeapon, vEyePos, tAllies, MyTable )
	if !pWeapon.WEAPON_bDeadDroppedWeapon && pWeapon.WEAPON_EWhoPutThatThere == MyTable.Classify( self ) then return end

	if pWeapon:NearestPoint( vEyePos ):DistToSqr( vEyePos ) > 9437184/*3072*/ then return end

	local pSchedule = MyTable.Schedule
	if pSchedule && pSchedule.m_sName == "GekkoInspectFirearm" then return end

	if MyTable.EScheduleState == ACTOR_STATE_IDLE then
		for pAlly in pairs( tAllies ) do if pAlly.pTargetWeapon == pWeapon then return end end
	
		pSchedule = MyTable.SetSchedule( self, "GekkoInspectFirearm", MyTable )
		pSchedule.pWeapon = pWeapon

		return
	end
end

RegisterSchedule( "GekkoInspectFirearm", { Execute = function( self, pSchedule, MyTable )
	if !table.IsEmpty( MyTable.tEnemies ) then return false end

	local pWeapon = pSchedule.pWeapon

	if !IsValid( pWeapon ) then return false end

	if IsValid( pWeapon:GetOwner() ) || IsValid( pWeapon:GetParent() ) then return false end

	MyTable.pTargetWeapon = pWeapon

	MyTable.EScheduleState = ACTOR_STATE_SOFTALERT

	local pPath = pSchedule.pPath

	if !pPath then
		pPath = Path "Follow"
		pSchedule.pPath = pPath
	end

	local _, b = MyTable.ComputePath( self, pPath, pWeapon:GetPos() + pWeapon:OBBCenter() )

	if b == false then return false end // NOT !b

	local pGoal = pPath:GetCurrentGoal()
	if pGoal then MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle() end

	MyTable.vaAimTargetPose = pWeapon:GetPos() + pWeapon:OBBCenter()

	if !pSchedule.bAcked then
		pSchedule.bAcked = true

		MyTable.EmitSentence( self, { sSound = "GekkoAck" }, MyTable )

		MyTable.HandleSentences( self, MyTable )

		MyTable.AnimationSystemHalt( self, MyTable )
		MyTable.PlaySequenceAndWait( self, "stun_start", math.Rand( .5, 2 / 3 ) )
	end

	if !IsValid( pWeapon ) then return true end

	local f = MyTable.GetStompDamageRadius( self ) * .75
	f = f * f
	if !self:Visible( pWeapon ) || self:GetPos():DistToSqr( pWeapon:GetPos() + pWeapon:OBBCenter() ) > f then
		MyTable.MoveAlongPath( self, pPath, MyTable.flPowerWalkSpeed, 1 )
		return
	end

	MyTable.PromoteSequence( self, "stun" )

	local flWatchTime = pSchedule.flWatchTime
	if flWatchTime then
		if CurTime() > flWatchTime then
			if pWeapon.WEAPON_EWhoPutThatThere != MyTable.Classify( self ) then
				MyTable.SetSchedule( self, "GekkoStompFirearm", MyTable ).pWeapon = pWeapon
			end
		end
	else pSchedule.flWatchTime = CurTime() + math.Rand( 0, 2 ) end
end } )

RegisterSchedule( "GekkoStompFirearm", { Execute = function( self, pSchedule, MyTable )
	if !table.IsEmpty( MyTable.tEnemies ) then return false end

	local pWeapon = pSchedule.pWeapon

	if !IsValid( pWeapon ) then return false end

	if IsValid( pWeapon:GetOwner() ) || IsValid( pWeapon:GetParent() ) then return false end

	MyTable.pTargetWeapon = pWeapon

	MyTable.EScheduleState = ACTOR_STATE_ALERT

	local pPath = pSchedule.pPath

	if !pPath then
		pPath = Path "Follow"
		pSchedule.pPath = pPath
	end

	local _, b = MyTable.ComputePath( self, pPath, pWeapon:GetPos() + pWeapon:OBBCenter() )

	if b == false then return false end // NOT !b

	local pGoal = pPath:GetCurrentGoal()
	if pGoal then MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle() end

	MyTable.vaAimTargetPose = pWeapon:GetPos() + pWeapon:OBBCenter()

	if !pSchedule.bLowed then
		pSchedule.bLowed = true

		MyTable.EmitSentence( self, { sSound = "GekkoAngry" }, MyTable )
		MyTable.HandleSentences( self, MyTable )
	end

	local f = MyTable.GetStompDamageRadius( self ) * .75
	f = f * f
	if !self:Visible( pWeapon ) || self:GetPos():DistToSqr( pWeapon:GetPos() + pWeapon:OBBCenter() ) > f then
		MyTable.MoveAlongPath( self, pPath, MyTable.flPowerWalkSpeed, 1 )
		return
	end

	MyTable.SetSchedule( self, "GekkoStomp", MyTable ).sNextScheduleOverride = "Alert"
end } )
