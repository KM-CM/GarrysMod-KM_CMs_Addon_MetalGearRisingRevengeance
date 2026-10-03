function EFFECT:Init( pData )
	local pOwner = pData:GetEntity()

	local vPos = pOwner:GetPos()

	FX_EjectaCloud {
		vOrigin = vPos,
		flMagnitude = 896
	}
end

function EFFECT:Think() return false end

function EFFECT:Render() end
