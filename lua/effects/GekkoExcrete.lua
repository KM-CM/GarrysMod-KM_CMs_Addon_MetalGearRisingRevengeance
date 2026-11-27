// It's totally not cow robot piss, trust me ;)

// Entity = Owner
// Magnitude = Volume (L)
// Scale = Volumetric flow rate (L/s)
// Radius = Nozzle diameter (m)

local ParticleEmitter = ParticleEmitter
local pi = math.pi
local min = math.min
local max = math.max
local sqrt = math.sqrt
local Clamp = math.Clamp
local Rand = math.Rand
local VectorRand = VectorRand
local IsValid = IsValid
local GetConVarNumber = GetConVarNumber
local CurTime = CurTime

function EFFECT:Init( pData )
	local pEntity = pData:GetEntity()
	if !IsValid( pEntity ) then return end

	self.m_pEntity = pEntity

	local flTotalLiters = pData:GetMagnitude()
	local flRate = pData:GetScale()

	self.m_flTotalLiters = flTotalLiters
	self.m_flRemainingLiters = flTotalLiters
	self.m_flRate = flRate

	self.m_flJetSpeed = 200
	self.m_flStreamRadius = 1

	self.m_flLastThink = CurTime()

	self.m_pEmitter = ParticleEmitter( vector_origin )
end

function EFFECT:Think()
	local pEntity = self.m_pEntity
	local pEmitter = self.m_pEmitter

	if !IsValid( pEntity ) || !IsValid( pEmitter ) || self.m_flRemainingLiters <= 0 then
		if IsValid( pEmitter ) then pEmitter:Finish() end
		return false
	end

	// Head pressure drops linearly as the tank empties (last 20% loses accumulator pressure)
	local flPressureRatio = Clamp( self.m_flRemainingLiters / ( self.m_flTotalLiters * .2 ), .05, 1 )

	// Bernoulli / Torricelli's Law: exit velocity & flow rate scale with sqrt( Pressure )
	local flVelocityScale = sqrt( flPressureRatio )

	local flDelta = CurTime() - self.m_flLastThink
	self.m_flLastThink = CurTime()

	local flCurrentFlow = self.m_flRate * flVelocityScale
	local flDrained = min( self.m_flRemainingLiters, flCurrentFlow * flDelta )
	self.m_flRemainingLiters = self.m_flRemainingLiters - flDrained

	local vPos = pEntity:GetBonePosition( pEntity:LookupBone "bone000" )

	local vPurge = -pEntity:GetUp()

	pEmitter:SetPos( vPos )

	local pPart = pEmitter:Add( "particles/smokey", vPos )
	if pPart then
		// Low pressure breaks laminar flow, causing slightly wider chaotic sputtering
		local flTurbulence = 1 + ( 1 - flVelocityScale ) * 1.5
		local vSpread = VectorRand():GetNormalized() * Rand( 0, self.m_flStreamRadius * 2 * flTurbulence )

		pPart:SetVelocity( ( vPurge * self.m_flJetSpeed * flVelocityScale ) + vSpread )
		pPart:SetGravity( Vector( 0, 0, -GetConVarNumber "gravity" ) )
		pPart:SetDieTime( .3 + math.random() * 1.2 )
		pPart:SetStartAlpha( 160 + 60 * flVelocityScale )
		pPart:SetEndAlpha( 0 )

		pPart:SetStartSize( self.m_flStreamRadius * 16 * ( .65 + .35 * flVelocityScale ) )
		pPart:SetEndSize( self.m_flStreamRadius * ( 16 * 6 ) )
		pPart:SetStartLength( self.m_flStreamRadius * 24 )
		pPart:SetEndLength( self.m_flStreamRadius * ( 16 * 6 ) )
		pPart:SetRoll( Rand( -180, 180 ) )

		local f = math.random() * math.random()
		pPart:SetColor( Lerp( f, 215, 255 ), Lerp( f, 235, 255 ), Lerp( f, 95, 255 ) )

		pPart:SetCollide( true )
		pPart:SetBounce( .2 )
		pPart:SetCollideCallback( function( _, vHitPos, vHitNormal )
			pPart:SetDieTime( pPart:GetDieTime() * .75 )

			EmitSound( "GekkoExcrementSplash", vHitPos, nil, nil, Rand( 1 / 3, 1 ) )

			if math.random() * math.random() <= flDelta then
				util.Decal( "Splash.Large", vHitPos + vHitNormal, vHitPos - vHitNormal )
			end
		end )
	end

	return true
end

function EFFECT:Render() end
