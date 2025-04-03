---@type BP_PlayerCharacter_C
local M= UnLua.Class("BP_CharacterBase_C")

local Lerp = UE.UKismetMathLibrary.Lerp

--function M:UserConstructionScript()
--end

-- 根据时间轴进度动态调整相机FOV
function M:OnZoomInOutUpdate(Alpha)
	-- 使用线性插值（Lerp）在默认视野和瞄准视野之间平滑过渡
	local FOV = Lerp(self.DefaultFOV, self.Weapon.AimingFOV, Alpha)

    -- 将计算得到的FOV值应用到相机组件,实现动态的镜头缩放效果
	self.Camera:SetFieldOfView(FOV)
end

function M:SpawnWeapon()
	local World = self:GetWorld()
	if not World then
		return
	end

	local WeaponClass = UE.UClass.Load("/Game/Core/Blueprints/Weapon/BP_DefaultWeapon.BP_DefaultWeapon_C")
	-- local NewWeapon = World:SpawnActor(WeaponClass, self:GetTransform(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, self, self, "Weapon.BP_DefaultWeapon_C")
	local sp = UE.FActorSpawnParameters()
	sp.SpawnCollisionHandlingOverride = UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn-- 强制生成，忽略碰撞
	sp.Owner = self-- 设置拥有者为当前对象
	sp.Instigator = self-- 设置行为发起者为当前对象

	-- 使用扩展生成方法创建武器实例
    -- 参数说明：
    -- 1. 要生成的类
    -- 2. 初始变换（使用当前对象的变换）
    -- 3. 父组件（nil表示不附加）
    -- 4. 对象名称
    -- 5. 生成参数
	local NewWeapon = World:SpawnActorEx(
		WeaponClass, self:GetTransform(), nil, "Weapon.BP_DefaultWeapon_C", sp)
	return NewWeapon
end

function M:ReceiveBeginPlay()
	self.Super.ReceiveBeginPlay(self)

	-- 记录相机默认视野值（用于后续缩放效果）
	self.DefaultFOV = self.Camera.FieldOfView

	--每 1 秒重复调用 M.FallCheck 函数，可能用于周期性检测某种状态（例如角色是否坠落）
	self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, M.FallCheck}, 1.0, true)

	-- 获取时间轴中的浮点插值轨道（用于相机缩放效果）
	local InterpFloats = self.ZoomInOut.TheTimeline.InterpFloats
	local FloatTrack = InterpFloats:GetRef(1)-- 获取第一条浮点轨道

	--将时间轴（ZoomInOut 时间轴资源）中的浮点插值轨道与 M.OnZoomInOutUpdate 函数绑定，
	--用于动态修改相机的 FOV（例如平滑的缩放效果）。
	FloatTrack.InterpFunc:Bind(self, M.OnZoomInOutUpdate)
end

function M:ReceiveDestroyed()
	UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)
end

function M:UpdateAiming(IsAiming)
	if self.Weapon then
		if IsAiming then
			self.ZoomInOut:Play()
		else
			self.ZoomInOut:Reverse()
		end
	end
end

function M:FallCheck()
	local Location = self:K2_GetActorLocation()
	if Location.Z < -200.0 then
	    UE.UKismetSystemLibrary.ExecuteConsoleCommand(self, "RestartLevel")
	end
end

function M:GetWeaponTraceInfo()
	local TraceLocation = self.Camera:K2_GetComponentLocation()
	local TraceDirection = self.Camera:GetForwardVector()
	return TraceLocation, TraceDirection
end

--[[
function M:GetWeaponTraceInfo(TraceStart, TraceDirection)
	self.Camera:K2_GetComponentLocation(TraceStart)
	self.Camera:GetForwardVector(TraceDirection)
end
]]

return M
