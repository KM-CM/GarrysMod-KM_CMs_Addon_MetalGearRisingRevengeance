function EFFECT:Init( pData )
	local pOwner = pData:GetEntity()

	local vPos = pOwner:GetPos()

	FX_EjectaCloud {
		vOrigin = vPos,
		flMagnitude = 1024,
		flStrengthOverride = 768
	}
end

function EFFECT:Think() return false end

function EFFECT:Render() end
