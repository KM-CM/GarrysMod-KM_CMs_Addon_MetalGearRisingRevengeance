function EFFECT:Init( pData )
	local pOwner = pData:GetEntity()

	local vPos = pOwner:GetPos()

	FX_EjectaCloud( vPos, 896, ESurfaceProp )
end

function EFFECT:Think() return false end

function EFFECT:Render() end
