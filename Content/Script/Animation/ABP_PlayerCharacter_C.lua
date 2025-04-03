---@type ABP_PlayerCharacter_C
local M = UnLua.Class()

function M:AnimNotify_NotifyPhysics()
	local BPI_Interfaces = UE.UClass.Load("/Game/Core/Blueprints/BPI_Interfaces.BPI_Interfaces_C")
	BPI_Interfaces.ChangeToRagdoll(self.Pawn)
end

function M:BlueprintBeginPlay()
	self.Velocity = UE.FVector()
	self.ForwardVec = UE.FVector()
	self.RightVec = UE.FVector()
	self.ControlRot = UE.FRotator()
	self.Pawn = self:TryGetPawnOwner()
end

function M:BlueprintUpdateAnimation(DeltaTimeX)
	-- 获取动画实例绑定的角色对象
	local Pawn = self:TryGetPawnOwner(self.Pawn)
	if not Pawn then
		return
	end

	local Vel = Pawn:GetVelocity(self.Velocity)
	if not Vel then
		return
	end

	local BP_CharacterBase = UE.UClass.Load("/Game/Core/Blueprints/BP_CharacterBase.BP_CharacterBase_C")
	local Character = Pawn:Cast(BP_CharacterBase)
	if Character then
		if Character.IsDead and not self.IsDead then
			self.IsDead = true
			self.DeathAnimIndex = UE.UKismetMathLibrary.RandomIntegerInRange(0, 2)
		end
	end

	local Speed = Vel:Size()
	self.Speed = Speed
	if Speed > 0.0 then
		-- 标准化速度向量（单位向量）
		Vel:Normalize()

		-- 获取角色控制旋转（仅保留Yaw轴）
		local Rot = Pawn:GetControlRotation(self.ControlRot)
		Rot:Set(0, Rot.Yaw, 0)

		-- 计算角色前进方向和右方向量
		local ForwardVec = Rot:GetForwardVector(self.ForwardVec)
		local RightVec = Rot:GetRightVector(self.RightVec)

		-- 计算速度向量与角色方向的点积
		local DP0 = Vel:Dot(RightVec)-- 与右方向的点积（判断左右）
		local DP1 = Vel:Dot(ForwardVec)-- 与前进方向的点积（判断前后）

		-- 通过反余弦计算移动角度（弧度值）
		local Angle = UE.UKismetMathLibrary.Acos(DP1)

		-- 根据左右方向确定最终角度（正为右转，负为左转）
		if DP0 > 0.0 then
			self.Direction = Angle-- 向右移动
		else
			self.Direction = -Angle-- 向左移动
		end
	end
end

return M
