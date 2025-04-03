---@type BP_WeaponBase_C
local M = UnLua.Class()

local EFireType = {	FT_Projectile = 0, FT_InstantHit = 1 }

function M:UserConstructionScript()
	self.IsFiring = false
	self.InfiniteAmmo = false
	self.FireInterval = 0.2
	self.MaxAmmo = 30
	self.AmmoPerShot = 1
	self.FireType = EFireType.FT_Projectile
	self.WeaponTraceDistance = 100000.0
	self.MuzzleSocketName = nil
	self.AimingFOV = 45.0
end

function M:ReceiveBeginPlay()
	self.CurrentAmmo = self.MaxAmmo
end

function M:StartFire()
	self.IsFiring = true
	self:FireAmmunition()
	self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, M.Refire}, self.FireInterval, true)
end

function M:StopFire()
	if self.IsFiring then
		self.IsFiring = false
		UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)
	end
end

function M:FireAmmunition()
	self:ConsumeAmmo()
	self:PlayWeaponAnimation()
	self:PlayMuzzleEffect()
	self:PlayFireSound()
	if self.FireType == EFireType.FT_Projectile then
		self:ProjectileFire()
	else
		self:InstantFire()
	end
end

--消耗弹药
function M:ConsumeAmmo()
	if not self.InfiniteAmmo then
		local Ammo = self.CurrentAmmo - self.AmmoPerShot
		self.CurrentAmmo = math.max(Ammo, 0)
	end
end

function M:PlayWeaponAnimation()
end

function M:PlayMuzzleEffect()
end

function M:PlayFireSound()
end

function M:ProjectileFire()
	self:SpawnProjectile()
end

function M:SpawnProjectile()
	return nil
end

function M:InstantFire()
	local Transform = self:GetFireInfo()
	local Start = Transform.Translation
	local ForwardVector = Transform.Rotation:GetForwardVector()
	local End = ForwardVector * self.WeaponTraceDistance
	End.Add(Start)
	--local HitResult = UE.FHitResult()
	--local ActorsToIgnore = TArray(AActor)
	local bResult = UE.UKismetSystemLibrary.LineTraceSingle(self, Start, End, UE.ETraceTypeQuery.Weapon, false, nil, UE.EDrawDebugTrace.None, nil, true)
	if bResult then
		-- todo:
	end
end

function M:GetFireInfo()
	local UBPI_Interfaces = UE.UClass.Load("/Game/Core/Blueprints/BPI_Interfaces.BPI_Interfaces_C")

	-- 从接口获取武器发射起点和方向（需要确保Instigator已实现该接口）
	local TraceStart, TraceDirection = UBPI_Interfaces.GetWeaponTraceInfo(self.Instigator)

	-- 计算追踪终点（根据武器射程）
	local Delta = TraceDirection * self.WeaponTraceDistance
	local TraceEnd = TraceStart + Delta

	-- 初始化命中结果容器
	local HitResult = UE.FHitResult()
	--local ActorsToIgnore = TArray(AActor)

	-- 执行射线检测（参数说明：上下文对象，起点，终点，追踪通道，忽略复杂碰撞，忽略的Actor数组，调试绘制模式，输出命中结果，是否忽略自身）
	local bResult = UE.UKismetSystemLibrary.LineTraceSingle(self, TraceStart, TraceEnd, UE.ETraceTypeQuery.Weapon, false, nil, UE.EDrawDebugTrace.None, HitResult, true)

	-- 获取枪口插槽的世界位置
	local Translation = self.SkeletalMesh:GetSocketLocation(self.MuzzleSocketName)

	-- 计算旋转方向
	local Rotation
	if bResult then
		-- 如果命中目标：朝向命中点
		local ImpactPoint = HitResult.ImpactPoint
		Rotation = UE.UKismetMathLibrary.FindLookAtRotation(Translation, ImpactPoint)
	else
		-- 如果未命中：朝向追踪终点
		Rotation = UE.UKismetMathLibrary.FindLookAtRotation(Translation, TraceEnd)
	end

	-- 组合为变换信息（可用于生成弹道/特效）
	local Transform = UE.FTransform(Rotation:ToQuat(), Translation)
	return Transform
end

function M:Refire()
	local bHasAmmo = self:HasAmmo()
	if bHasAmmo and self.IsFiring then
		self:FireAmmunition()
	end
end

function M:HasAmmo()
	return self.InfiniteAmmo or self.CurrentAmmo > 0
end

return M
