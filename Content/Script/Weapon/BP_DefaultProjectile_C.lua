---@type BP_DefaultProjectile_C
local M = UnLua.Class("Weapon.BP_ProjectileBase_C")

function M:Initialize(Initializer)
	if Initializer then
		self.BaseColor = Initializer[0]
	end
end

function M:UserConstructionScript()
	self.Super.UserConstructionScript(self)
	self.DamageType = UE.UClass.Load("/Game/Core/Blueprints/BP_DamageType.BP_DamageType_C")
end

function M:ReceiveBeginPlay()
	self.Super.ReceiveBeginPlay(self)

	-- 为静态网格体的第一个材质槽（索引0）创建动态材质实例
    -- 动态材质实例允许运行时修改材质参数
	local MID = self.StaticMesh:CreateDynamicMaterialInstance(0)
	if MID then
		-- 设置材质的"BaseColor"向量参数
		MID:SetVectorParameterValue("BaseColor", self.BaseColor)
	end
end

return M
