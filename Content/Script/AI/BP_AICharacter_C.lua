---@type BP_AICharacter_C
local M = UnLua.Class("BP_CharacterBase_C")

function M:Initialize(Initializer)
	self.Super.Initialize(self)
	self.Damage = 128.0
	self.DamageType = UE.UDamageType
end

--function M:UserConstructionScript()
--end

function M:ReceiveBeginPlay()
	self.Super.ReceiveBeginPlay(self)
	self.Sphere.OnComponentBeginOverlap:Add(self, M.OnComponentBeginOverlap_Sphere)
end

function M:Died_Multicast_RPC(DamageType)
	self.Super.Died_Multicast_RPC(self, DamageType)

	-- 禁用球体碰撞,防止后续交互
	self.Sphere:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)

	-- 将网格体移动到角色胶囊体半高处（模拟死亡后下沉效果）
	local NewLocation = UE.FVector(0.0, 0.0, self.CapsuleComponent.CapsuleHalfHeight)
	local SweepHitResult = UE.FHitResult()
	self.Mesh:K2_SetRelativeLocation(NewLocation, false, SweepHitResult, false)

	-- 启用指定骨骼以下的物理模拟（ ragdoll 效果）
	self.Mesh:SetAllBodiesBelowSimulatePhysics(self.BoneName, true, true)

	-- 通知游戏模式敌人死亡
	local GameMode = UE.UGameplayStatics.GetGameMode(self)
	if GameMode then
		local BPI_Interfaces = UE.UClass.Load("/Game/Core/Blueprints/BPI_Interfaces.BPI_Interfaces_C")
		BPI_Interfaces.NotifyEnemyDied(GameMode)
	end
	--self.Sphere.OnComponentBeginOverlap:Remove(self, M.OnComponentBeginOverlap_Sphere)
end

function M:OnComponentBeginOverlap_Sphere(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
	local BP_PlayerCharacter = UE.UClass.Load("/Game/Core/Blueprints/Player/BP_PlayerCharacter.BP_PlayerCharacter_C")
	local PlayerCharacter = OtherActor:Cast(BP_PlayerCharacter)
	if PlayerCharacter then
		local Controller = self:GetController()
		UE.UGameplayStatics.ApplyDamage(PlayerCharacter, self.Damage, Controller, self, self.DamageType)
	end
end

return M
