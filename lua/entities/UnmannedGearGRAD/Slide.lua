ENT.m_flLastDrawCall = 0

local LEFT_WHEEL_BONE = "bone048"
local RIGHT_WHEEL_BONE = "bone038"

local math_Rand = math.Rand
local math_random = math.random

local vWhite, vOrange = Vector( 255, 255, 255 ), Vector( 255, 128, 64 )

local vGravity = Vector( 0, 0, -800 )
local vGravityWater = Vector( 0, 0, -100 )

local render_GetLightColor = render.GetLightColor
local util_PointContents = util.PointContents
local bit_band = bit.band

// TODO: Maybe weaker/stronger effects based on slide strength?

local function SlideEffects( self, vPos )
	local dNormal = self:GetUp()

	local pEmitter = ParticleEmitter( vPos )

	local pImpact = pEmitter:Add( "sprites/light_glow02_add", vPos )
	pImpact:SetAngles( AngleRand() )
	pImpact:SetDieTime( math_Rand( 0, 1 / 3 ) )
	pImpact:SetStartAlpha( 255 )
	pImpact:SetEndAlpha( 0 )
	pImpact:SetStartSize( math_Rand( 0, 128 ) )
	pImpact:SetEndSize( math_Rand( 0, 128 ) )
	pImpact:SetRoll( math_Rand( 0, 360 ) )
	pImpact:SetRollDelta( math_Rand( -4, 4 ) )
	local v = LerpVector( math_random(), vWhite, vOrange )
	pImpact:SetColor( v[ 1 ], v[ 2 ], v[ 3 ] )

	for i = 1, math_random( 1, 4 ) do
		local pPart = pEmitter:Add( "effects/spark", vPos )
		if pPart then
			local v = LerpVector( .75, dNormal, VectorRand() ):GetNormalized()
			pPart:SetBounce( math_Rand( 0, .1 ) )
			pPart:SetAngles( v:Angle() )
			pPart:SetDieTime( math_Rand( 0, 1 / 3 ) )
			pPart:SetStartAlpha( math_Rand( 190, 255 ) )
			pPart:SetEndAlpha( 0 )
			pPart:SetStartSize( math_Rand( 0, 8 ) )
			pPart:SetEndSize( math_Rand( 0, 8 ) )
			pPart:SetCollide( true )
			pPart:SetVelocity( v * math_Rand( 512, 1024 ) )
			pPart:SetNextThink( CurTime() )
			pPart:SetRoll( math_Rand( 0, 360 ) )
			pPart:SetRollDelta( math_Rand( -30, 30 ) )
		end
	end

	for i = 1, math_random( 1, 3 ) do
		local pPart = pEmitter:Add( "particles/smokey", vPos )
		if pPart then
			local v = LerpVector( .75, dNormal, VectorRand() ):GetNormalized()
			pPart:SetBounce( math_Rand( 0, .1 ) )
			pPart:SetAngles( v:Angle() )
			pPart:SetDieTime( math_Rand( 0, 1 ) )
			pPart:SetStartAlpha( math_Rand( 190, 255 ) )
			pPart:SetEndAlpha( 0 )
			pPart:SetStartSize( math_Rand( 0, 48 ) )
			pPart:SetEndSize( math_Rand( 0, 48 ) )
			pPart:SetCollide( true )
			pPart:SetVelocity( v * math_Rand( 128, 256 ) )
			pPart:SetNextThink( CurTime() )
			pPart:SetThinkFunction( function( pPart )
				local vPos = pPart:GetPos()
				local vColor = render_GetLightColor( vPos )
				pPart:SetColor(
					Lerp( vColor[ 1 ] ^ ( 1 / 3 ), 0, 128 ),
					Lerp( vColor[ 2 ] ^ ( 1 / 3 ), 0, 128 ),
					Lerp( vColor[ 3 ] ^ ( 1 / 3 ), 0, 128 )
				)
				if bit_band( util_PointContents( vPos ), CONTENTS_WATER ) == 0 then
					pPart:SetGravity( vGravity )
				else pPart:SetGravity( vGravityWater ) end
				pPart:SetNextThink( CurTime() )
			end )
			pPart:SetRoll( math_Rand( 0, 360 ) )
			pPart:SetRollDelta( math_Rand( -30, 30 ) )
		end
	end

	local pHaze = pEmitter:Add( "GRADWheelHeatHaze", vPos )

	pHaze:SetDieTime( math_Rand( 0, 1 / 3 ) )

	pHaze:SetStartSize( math_Rand( 0, 128 ) )
	pHaze:SetEndSize( math_Rand( 0, 128 ) )

	pHaze:SetRoll( math_Rand( 0, 360 ) )
	pHaze:SetRollDelta( math_Rand( -4, 4 ) )

	pHaze:SetStartAlpha( 255 )
	pHaze:SetEndAlpha( 0 )

	pEmitter:Finish()
end

function ENT:Draw()
	self:DrawModel()

	local flFrameTime = CurTime() - self.m_flLastDrawCall
	self.m_flLastDrawCall = CurTime()

	if flFrameTime > .2 then return end

	if !self:GetIsSliding() then return end

	if math.random() <= self:GetSlideStrength() ^ .5 * 32 * flFrameTime then
		SlideEffects( self, self:GetBonePosition( self:LookupBone( LEFT_WHEEL_BONE ) ) )
		SlideEffects( self, self:GetBonePosition( self:LookupBone( RIGHT_WHEEL_BONE ) ) )
	end
end
