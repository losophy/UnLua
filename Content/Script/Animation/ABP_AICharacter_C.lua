---@type ABP_AICharacter_C
local M = UnLua.Class()

function M:AnimNotify_NotifyPhysics()
	local BPI_Interfaces = UE.UClass.Load("/Game/Core/Blueprints/BPI_Interfaces.BPI_Interfaces_C")
	BPI_Interfaces.ChangeToRagdoll(self.Pawn)
end

function M:BlueprintBeginPlay()
	self.Velocity = UE.FVector()
	self.Pawn = self:TryGetPawnOwner()
end

function M:BlueprintUpdateAnimation(DeltaTimeX)
	-- 获取动画实例绑定的角色对象（Pawn）
	local Pawn = self:TryGetPawnOwner(self.Pawn)
	if not Pawn then
		return
	end

	-- 获取角色当前速度向量
	local Vel = Pawn:GetVelocity(self.Velocity)
	if not Vel then
		return
	end

	-- 计算并存储速度标量值（用于动画混合）
	self.Speed = Vel:Size()

	local BP_CharacterBase = UE.UClass.Load("/Game/Core/Blueprints/BP_CharacterBase.BP_CharacterBase_C")

	local Character = Pawn:Cast(BP_CharacterBase)
	if Character then
		-- 检测角色是否首次死亡
		if Character.IsDead and not self.IsDead then
			self.IsDead = true-- 标记动画实例为死亡状态
			self.DeathAnimIndex = UE.UKismetMathLibrary.RandomIntegerInRange(0, 2)-- 随机选择死亡动画（0/1/2）
		end
	end
end

return M
