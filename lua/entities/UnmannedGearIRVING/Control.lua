function ENT:ControlledHandleDodging( MyTable, pController )
	if bit.band( pController.CONTROL_iButtons || 0, IN_RELOAD ) != 0 then
		if bit.band( pController.CONTROL_iButtons || 0, IN_MOVELEFT ) != 0 then
			MyTable.Dodge.DodgeLeft.Perform( self, MyTable, 1 )
			return true
		elseif bit.band( pController.CONTROL_iButtons || 0, IN_MOVERIGHT ) != 0 then
			MyTable.Dodge.DodgeRight.Perform( self, MyTable, 1 )
			return true
		elseif bit.band( pController.CONTROL_iButtons || 0, IN_BACK ) != 0 then
			MyTable.Dodge.DodgeBack.Perform( self, MyTable, 1 )
			return true
		end
	end
end

function ENT:ControlOverridePlayerPosition( pController )
	local aAngle = pController:EyeAngles()

	return self:GetPos() + self:GetUp() * 128 - aAngle:Forward() * 128 + aAngle:Right() * 64 - pController:GetViewOffset()
end

function ENT:HandleControl( MyTable, pController )
	local pSchedule = MyTable.Schedule
	if pSchedule && pSchedule.m_sName == "GekkoBrainMachineInterfaceError" then
		MyTable.RunMind( self, MyTable )
		return
	end

	MyTable.vaAimTargetPose = pController:EyeAngles()

	// TODO: This should probably just use CONTROL_flForwardMove and CONTROL_flSideMove
	// I kinda forgot those existed when creating this lmfaooo
	local flMoveForward, bMoveForward = 0
	if bit.band( pController.CONTROL_iButtons || 0, IN_ATTACK2 ) != 0 then
		MyTable.vaAimTargetBody = MyTable.vaAimTargetPose

		bMoveForward = bit.band( pController.CONTROL_iButtons || 0, IN_FORWARD ) != 0
		flMoveForward = 1
	else
		local vDirection = Vector( 0, 0, 0 )

		if bit.band( pController.CONTROL_iButtons || 0, IN_FORWARD ) != 0 then
			vDirection = pController:GetAimVector()
			if bit.band( pController.CONTROL_iButtons || 0, IN_MOVELEFT ) != 0 then
				vDirection = vDirection + -pController:EyeAngles():Right()
			elseif bit.band( pController.CONTROL_iButtons || 0, IN_MOVERIGHT ) != 0 then
				vDirection = vDirection + pController:EyeAngles():Right()
			end
		elseif bit.band( pController.CONTROL_iButtons || 0, IN_BACK ) != 0 then
			vDirection = -pController:GetAimVector()
			if bit.band( pController.CONTROL_iButtons || 0, IN_MOVELEFT ) != 0 then
				vDirection = vDirection + -pController:EyeAngles():Right()
			elseif bit.band( pController.CONTROL_iButtons || 0, IN_MOVERIGHT ) != 0 then
				vDirection = vDirection + pController:EyeAngles():Right()
			end
		elseif bit.band( pController.CONTROL_iButtons || 0, IN_MOVELEFT ) != 0 then
			vDirection = -pController:EyeAngles():Right()
		elseif bit.band( pController.CONTROL_iButtons || 0, IN_MOVERIGHT ) != 0 then
			vDirection = pController:EyeAngles():Right()
		end

		vDirection[ 3 ] = 0
		vDirection:Normalize()

		if vDirection != vector_origin then
			MyTable.vaAimTargetBody = vDirection:Angle()
			bMoveForward = true
			flMoveForward = math.max( 0, self:GetForward():Dot( vDirection ) ) ^ ( 1 / 4 )
		end
	end

	if bit.band( pController.CONTROL_iButtons || 0, IN_ZOOM ) != 0 && flMoveForward > .8 then
		if bit.band( pController.CONTROL_iButtons || 0, IN_SPEED ) != 0 && ( pController.CONTROL_flSideMove != 0 || pController.CONTROL_flForwardMove != 0 ) then
			MyTable.AnimationSystemHalt( self, MyTable )

			local sWarmupSequence = "att2_1"
			local flWarmupMultiplier = math.Rand( .75, 1.25 )
		
			local sSequence = "att2_2"
			local flMultiplier = math.Rand( 2 / 3, 1 + 1 / 3 )
		
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

			MyTable.PlaySequenceAndMove( self, sWarmupSequence, flWarmupMultiplier, nil, function()
				if !IsValid( pController ) then return end
				if MyTable.ControlledHandleDodging( self, MyTable, pController ) then
					bInterrupt = true
					return true
				end
			end, nil, nil, true )

			if bInterrupt then return end

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

				util.ScreenShake( self:GetPos() + self:OBBCenter(), bShake && 512 || 24, 1, 1, 4096, true )
			end )

			MyTable.AnimationSystemHalt( self, MyTable )

			MyTable.PlaySequenceAndMove( self, sSequence, flMultiplier, nil, function( _, flCycle )
				if !IsValid( pController ) then return end
				if MyTable.ControlledHandleDodging( self, MyTable, pController ) then
					return true
				end
			end )

			return
		end
	end

	if bit.band( pController.CONTROL_iButtons || 0, IN_RELOAD ) != 0 then
		bMoveForward = false

		MyTable.vaAimTargetBody = MyTable.vaAimTargetPose

		if bit.band( pController.CONTROL_iButtons || 0, IN_MOVELEFT ) != 0 then
			MyTable.Dodge.DodgeLeft.Perform( self, MyTable, 1 )
		elseif bit.band( pController.CONTROL_iButtons || 0, IN_MOVERIGHT ) != 0 then
			MyTable.Dodge.DodgeRight.Perform( self, MyTable, 1 )
		elseif bit.band( pController.CONTROL_iButtons || 0, IN_BACK ) != 0 then
			MyTable.Dodge.DodgeBack.Perform( self, MyTable, 1 )
		else
			MyTable.EScheduleState = ACTOR_STATE_ALERT

			MyTable.tAlertContext = { flEnemySeen = CurTime() }

			local flMultiplier = math.Rand( .75, 1.25 )
		
			timer.Simple( .8 / flMultiplier, function()
				if !IsValid( self ) then return end
	
				util.ScreenShake( self:GetPos() + self:OBBCenter(), 8, 40, 2, 4096, true )
		
				MyTable.SOUND_CONTEXT_fCallOnAllHearers = function( pHearer )
					if pHearer.__ACTOR__ && MyTable.Disposition( self, pHearer ) == D_LI then
						MyTable.ShareAlertContext( self, pHearer, MyTable )
					end
				end
		
				self:EmitSound "GekkoTaunt"
			end )
		
			MyTable.AnimationSystemHalt( self, MyTable )
		
			MyTable.PlaySequenceAndWait( self, "taunt", flMultiplier, nil, function()
				if !IsValid( pController ) then return end
				if MyTable.ControlledHandleDodging( self, MyTable, pController ) then
					return true
				end
			end )

			MyTable.SetSchedule( self, "Alert", MyTable )
		end
		return
	end

	local flSpeed = bit.band( pController.CONTROL_iButtons || 0, IN_SPEED ) != 0 && MyTable.flTopSpeed || MyTable.flWalkSpeed

	local pLocomotion = MyTable.loco
	pLocomotion:SetDesiredSpeed( flSpeed * flMoveForward )
	local f = MyTable.flTopSpeed * ACCELERATION_NORMAL
	pLocomotion:SetAcceleration( f )
	pLocomotion:SetDeceleration( f )
	pLocomotion:SetJumpHeight( MyTable.flJumpHeight )

	local f = GetVelocity( self ):Length()
	local flMultiplier = 1
	if CurTime() <= MyTable.flSpeedUpAnimationsTime then flMultiplier = 1 / ( 1 - MyTable.flSpeedUpAnimationsWeight ) end

	if f <= 12 || !self:IsOnGround() then
	elseif f <= ( MyTable.flPowerWalkSpeed * 1.1 ) then
		MyTable.PromoteSequence( self, "walk", f / self:GetSequenceGroundSpeed( self:LookupSequence "walk" ) * flMultiplier )
	else
		MyTable.PromoteSequence( self, "run", f / self:GetSequenceGroundSpeed( self:LookupSequence "run" ) * flMultiplier )
	end

	if bMoveForward then
		pLocomotion:Approach( self:GetPos() + self:GetForward() * 128, 1 )
	end

	if bit.band( pController.CONTROL_iButtons || 0, IN_ATTACK ) != 0 then
		FireWeapon( self, "MachineGun", MyTable.tActiveWeaponTemplates.MachineGun )
	end

	if bit.band( pController.CONTROL_iButtons || 0, IN_USE ) != 0 then
		if bit.band( pController.CONTROL_iButtons || 0, IN_SPEED ) != 0 then
			MyTable.LowIfAvailable( self, MyTable )
		else
			local flMultiplier = math.Rand( .75, 1.25 )
	
			timer.Simple( .8 / flMultiplier, function()
				if !IsValid( self ) then return end
				util.ScreenShake( self:GetPos() + self:OBBCenter(), 8, 40, 2, 4096, true )
				self:EmitSound "GekkoTaunt"
			end )
	
			MyTable.AnimationSystemHalt( self, MyTable )
	
			MyTable.PlaySequenceAndWait( self, "taunt", flMultiplier, nil, function()
				if !IsValid( pController ) then return end
				if MyTable.ControlledHandleDodging( self, MyTable, pController ) then
					return true
				end
			end )
		end
	end
end
