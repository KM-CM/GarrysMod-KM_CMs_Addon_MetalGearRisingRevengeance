// TODO: Big fucking boom, duh :)
function EFFECT:Init( pData )
	local vPos = pData:GetOrigin()

	local pEmitter = ParticleEmitter( vPos )

    for _ = 1, 5 do
        local pPart = pEmitter:Add( "effects/muzzleflash" .. math.random( 1, 4 ), vPos )
        if pPart then
            pPart:SetVelocity( VectorRand():GetNormalized() * 100 )
            pPart:SetAirResistance( 200 )
            pPart:SetDieTime( .4 )
            pPart:SetStartAlpha( 255 )
            pPart:SetEndAlpha( 0 )
            pPart:SetStartSize( 360 )
            pPart:SetEndSize( 0 )
            pPart:SetRoll( math.Rand( -480, 480 ) )
            pPart:SetRollDelta( math.Rand( -1, 1 ) )
            pPart:SetColor( 255, 255, 255 )
            pPart:SetCollide( true )
        end
    end

	pEmitter:Finish()

	FX_EjectaCloud {
		vOrigin = vPos,
		flMagnitude = 1600
	}
end

function EFFECT:Render() end
function EFFECT:Think() return false end
