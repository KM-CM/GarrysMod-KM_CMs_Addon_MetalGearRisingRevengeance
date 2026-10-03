function EFFECT:Init( pData )
	FX_EjectaCloud {
		vOrigin = pData:GetOrigin(),
		flMagnitude = 3072,
		flStrengthOverride = 768
	}
end

function EFFECT:Think() return false end

function EFFECT:Render() end
