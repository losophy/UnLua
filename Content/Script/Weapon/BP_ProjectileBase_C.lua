---@type BP_ProjectileBase_C
local M = UnLua.Class()

function M:UserConstructionScript()
	self.Damage = 128.0
	self.DamageType = nil
	self.Sphere.OnComponentHit:Add(self, M.OnComponentHit_Sphere)
end

function M:ReceiveBeginPlay()
	--设置对象在场景中的存活时间, 4秒后对象会自动销毁
	self:SetLifeSpan(4.0)
end

function M:OnComponentHit_Sphere(HitComponent, OtherActor, OtherComp, NormalImpulse, Hit)
	local BP_CharacterBase = UE.UClass.Load("/Game/Core/Blueprints/BP_CharacterBase.BP_CharacterBase_C")
	local Character = OtherActor:Cast(BP_CharacterBase)
	if Character then
		-- 记录碰撞的骨骼名称（可用于受击部位判定）
		Character.BoneName = Hit.BoneName;

		-- 获取造成伤害的控制者（通常为玩家或AI控制器）
		local Controller = self.Instigator:GetController()

		-- 对角色应用伤害（参数说明：目标角色，伤害值，伤害来源控制器，伤害来源，伤害类型）
		UE.UGameplayStatics.ApplyDamage(Character, self.Damage, Controller, self.Instigator, self.DamageType)
	end
	self:K2_DestroyActor()
end

function M:ReceiveDestroyed()
	--self.Sphere.OnComponentHit:Remove(self, M.OnComponentHit_Sphere)
end

return M
