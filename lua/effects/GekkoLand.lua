// TODO: This effect is ugly. I don't know how to do it properly.
// Plus it really needs different surface support, which I am too lazy to code right now.

local ParticleEmitter = ParticleEmitter
local Vector = Vector
local math_Rand = math.Rand

function EFFECT:Init( pData )
	local vPos = pData:GetOrigin()

	local pEmitter = ParticleEmitter( vPos )

	for i = 1, 40 do
		local pPart = pEmitter:Add( "particle/particle_smokegrenade", vPos )

		pPart:SetVelocity( Vector( math_Rand( -1, 1 ), math_Rand( -1, 1 ), math_Rand( -1 / 3 , 1 / 3 ) ):GetNormalized() * math_Rand( 0, 256 ) )
		pPart:SetDieTime( math_Rand( 2, 4 ) )

		pPart:SetStartAlpha( 255 )
		pPart:SetEndAlpha( 0 )

		pPart:SetStartSize( 0 )
		pPart:SetEndSize( math_Rand( 160, 240 ) )

		pPart:SetRoll( math_Rand( 180, 480 ) )
		pPart:SetRollDelta( math_Rand( -1, 1 ) )

		pPart:SetColor( 255, 200, 150 )
		pPart:SetAirResistance( 120 )
	end

	pEmitter:Finish()
end

function EFFECT:Think() return false end
function EFFECT:Render() end
