function EFFECT:Init( pData )
	FX_EjectaCloud {
		vOrigin = pData:GetOrigin(),
		flMagnitude = 2048,
		flStrengthOverride = 512,
		vBaseVelocity = pData:GetStart()
	}
end

function EFFECT:Think() return false end

function EFFECT:Render() end
