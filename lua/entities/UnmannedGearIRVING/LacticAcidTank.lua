ENT.LAT_flAmount = -1

ENT.LAT_flSize = 78.5

ENT.LAT_flManifoldFloor = 3.85 // Minimum hydrostatic head to unseat the check valve
ENT.LAT_flResidualMin = 4.2 // Resting post-void residual fluid left in bladder wall folds
ENT.LAT_flThreshold = 27.5 // Stretch receptors begin firing conscious "need to go" signals

// Meaning full
//	ENT.LAT_flTauntPurgeMax = nil

function ENT:LAT_GetCritical() return self.LAT_flSize * .95 end

function ENT:TauntExcrete( flAmount, MyTable, fCallback, fPreSound )
	fCallback = fCallback || function() end
	fPreSound = fPreSound || function() end

	MyTable = MyTable || self

	local flRealAmount = MyTable.LAT_flAmount

	flAmount = math.min( flAmount || flRealAmount, flRealAmount )

	if flAmount <= 0 then return end

	local flMultiplier = math.Rand( .8, 1 ) * ( flAmount <= 10 && 1 || flAmount <= 30 && ( 30 / flAmount ) ^ .2 || 30 / ( 30 + math.max( 0, flAmount - 30 ) ^ .9 ) )

	timer.Simple( 1 / flMultiplier, function()
		if !IsValid( self ) then return end
		util.ScreenShake( self:GetPos() + self:OBBCenter(), 8, 40, 2, 4096, true )
		fPreSound()
		self:EmitSound "GekkoTaunt"
	end )

	MyTable.AnimationSystemHalt( self, MyTable )

	timer.Simple( 1.2 / flMultiplier, function()
		if IsValid( self ) then
			MyTable.LAT_flAmount = math.Clamp( MyTable.LAT_flAmount - flAmount, 0, MyTable.LAT_flSize )
			local pEffectData = EffectData()
			pEffectData:SetEntity( self )
			pEffectData:SetMagnitude( flAmount )
			pEffectData:SetScale( 30 )
			util.Effect( "GekkoExcrete", pEffectData )
		end
	end )

	MyTable.PlaySequenceAndWait( self, "taunt", flMultiplier, nil, function()
		fCallback()

		MyTable.vaAimTargetBody = nil

		MyTable.Look( self, MyTable )
		MyTable.HandleTurning( self, MyTable )
	end )
end

function ENT:NormalExcrete( flAmount, MyTable, fCallback )
	fCallback = fCallback || function() end

	MyTable = MyTable || self

	local flRealAmount = MyTable.LAT_flAmount

	flAmount = math.min( flAmount || flRealAmount, flRealAmount )

	if flAmount <= 0 then return end

	local flMultiplier = math.Rand( .8, 1 ) * ( flAmount <= 10 && 1 || flAmount <= 30 && ( 30 / flAmount ) ^ .2 || 30 / ( 30 + math.max( 0, flAmount - 30 ) ^ .9 ) )

	timer.Simple( 1 / flMultiplier, function()
		if !IsValid( self ) then return end
		util.ScreenShake( self:GetPos() + self:OBBCenter(), 4, 40, 2, 4096, true )
		// TODO: Calmer moo
		self:EmitSound "GekkoTaunt"
	end )

	MyTable.AnimationSystemHalt( self, MyTable )

	timer.Simple( 1.2 / flMultiplier, function()
		if IsValid( self ) then
			MyTable.LAT_flAmount = math.Clamp( MyTable.LAT_flAmount - flAmount, 0, MyTable.LAT_flSize )
			local pEffectData = EffectData()
			pEffectData:SetEntity( self )
			pEffectData:SetMagnitude( flAmount )
			pEffectData:SetScale( 30 )
			util.Effect( "GekkoExcrete", pEffectData )
		end
	end )

	MyTable.PlaySequenceAndWait( self, "taunt", flMultiplier, nil, function()
		fCallback()

		MyTable.vaAimTargetBody = nil

		MyTable.Look( self, MyTable )
		MyTable.HandleTurning( self, MyTable )
	end )
end

ENT.LATW_flValidTime = -1

local WASTE_BY_ACTIVITY = {
	Idle = .0022,
	Walk = .0045,
	FasterWalk = .0062,
	PowerWalk = .008,
	Sprint = .058,
	Charge = .135
}

function ENT:DoSpecials( MyTable )
	if CurTime() <= MyTable.LATW_flValidTime then
		MyTable.LAT_flAmount = MyTable.LAT_flAmount + WASTE_BY_ACTIVITY[ MyTable.LATW_sActivity ] * MyTable.m_flFrameTime
	else MyTable.LAT_flAmount = MyTable.LAT_flAmount + WASTE_BY_ACTIVITY.Idle * MyTable.m_flFrameTime end

	if MyTable.LAT_flAmount >= MyTable:LAT_GetCritical() then
		MyTable.TauntExcrete( self, nil, MyTable )
	end
end
