---@type BP_PlayerController_C
local M = UnLua.Class()

--UserConstructionScript在UnLua中扮演类似C++构造函数或蓝图Construction Script的角色，主要用于对象初始化阶段的操作‌
function M:UserConstructionScript()
	self.ForwardVec = UE.FVector() -- 初始化一个FVector类型的变量，表示向前方向
	self.RightVec = UE.FVector()-- 初始化一个FVector类型的变量，表示向右方向
	self.ControlRot = UE.FRotator()-- 初始化一个FRotator类型的变量，表示控制器的旋转

	self.BaseTurnRate = 45.0 -- 初始化基础转向速率
	self.BaseLookUpRate = 45.0	-- 初始化基础仰视速率
end

function M:ReceiveBeginPlay()
	if self:IsLocalPlayerController() then
		--生成UI，添加UI到Viewport
		local Widget = UE.UWidgetBlueprintLibrary.Create(self, UE.UClass.Load("/Game/Core/UI/UMG_Main.UMG_Main_C"))
		Widget:AddToViewport()
	end

	self.Overridden.ReceiveBeginPlay(self)
end

function M:Turn(AxisValue)
	self:AddYawInput(AxisValue)
end

--手柄转向
function M:TurnRate(AxisValue)
	local DeltaSeconds = UE.UGameplayStatics.GetWorldDeltaSeconds(self)
	local Value = AxisValue * DeltaSeconds * self.BaseTurnRate
	self:AddYawInput(Value)
end

function M:LookUp(AxisValue)
	self:AddPitchInput(AxisValue)
end

function M:LookUpRate(AxisValue)
	local DeltaSeconds = UE.UGameplayStatics.GetWorldDeltaSeconds(self)
	local Value = AxisValue * DeltaSeconds * self.BaseLookUpRate
	self:AddPitchInput(Value)
end

function M:MoveForward(AxisValue)
	if self.Pawn then
		-- 获取控制器的旋转，并仅保留 Yaw（偏航角）
		local Rotation = self:GetControlRotation(self.ControlRot)
		Rotation:Set(0, Rotation.Yaw, 0)

		-- 将旋转转换为方向向量
		local Direction = Rotation:ToVector(self.ForwardVec)		-- Rotation:GetForwardVector()

		 -- 根据方向和输入值添加移动输入
		self.Pawn:AddMovementInput(Direction, AxisValue)
	end
end

function M:MoveRight(AxisValue)
	if self.Pawn then
		local Rotation = self:GetControlRotation(self.ControlRot)
		Rotation:Set(0, Rotation.Yaw, 0)
		local Direction = Rotation:GetRightVector(self.RightVec)
		self.Pawn:AddMovementInput(Direction, AxisValue)
	end
end

function M:Fire_Pressed()
	if self.Pawn then
		self.Pawn:StartFire_Server()
	else
		UE.UKismetSystemLibrary.ExecuteConsoleCommand(self, "RestartLevel")
	end
end

function M:Fire_Released()
	if self.Pawn then
		self.Pawn:StopFire_Server()
	end
end

function M:Aim_Pressed()
	if self.Pawn then
		local BPI_Interfaces = UE.UClass.Load("/Game/Core/Blueprints/BPI_Interfaces.BPI_Interfaces_C")
		BPI_Interfaces.UpdateAiming(self.Pawn, true)
	end
end

function M:Aim_Released()
	if self.Pawn then
		local BPI_Interfaces = UE.UClass.Load("/Game/Core/Blueprints/BPI_Interfaces.BPI_Interfaces_C")
		BPI_Interfaces.UpdateAiming(self.Pawn, false)
	end
end

return M
