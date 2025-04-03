---@type BP_Game_C
local M = UnLua.Class()

function M:ReceiveBeginPlay()
	self.EnemySpawnInterval = 2.0-- 敌人生成间隔（秒）
	self.MaxEnemies = 4-- 最大敌人数
	self.AliveEnemies = 0 -- 当前存活敌人数
	self.SpawnOrigin = UE.FVector(650.0, 0.0, 100.0)-- 生成区域中心点
	self.SpawnLocation = UE.FVector()-- 实际生成位置（待计算）
	self.AICharacterClass = UE.UClass.Load("/Game/Core/Blueprints/AI/BP_AICharacter.BP_AICharacter_C")-- 加载AI蓝图
	UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, M.SpawnEnemy}, self.EnemySpawnInterval, true)--定时敌人生成
end

function M:SpawnEnemy()
	local PlayerCharacter = UE.UGameplayStatics.GetPlayerCharacter(self, 0)--‌获取玩家控制的角色（玩家索引0）
	if self.AliveEnemies < self.MaxEnemies and PlayerCharacter then--只有当前敌人数未达上限且玩家存在时才生成
		--在导航网格中随机获取可达点，并抬高100单位
		UE.UNavigationSystemV1.K2_GetRandomReachablePointInRadius(self, self.SpawnOrigin, self.SpawnLocation, 2000)
		self.SpawnLocation.Z = self.SpawnLocation.Z + 100

		--让生成的敌人面朝玩家
		local Target = PlayerCharacter:K2_GetActorLocation()
		local SpawnRotation = UE.UKismetMathLibrary.FindLookAtRotation(self.SpawnLocation, Target)

		--敌人生成
		UE.UAIBlueprintHelperLibrary.SpawnAIFromClass(self, self.AICharacterClass, nil, self.SpawnLocation, SpawnRotation)

		--敌人数管理
		self.AliveEnemies = self.AliveEnemies + 1
		if self.AliveEnemies > self.MaxEnemies then
			self.AliveEnemies = self.MaxEnemies
		end
	end
end

--敌人死亡计数
function M:NotifyEnemyDied()
	self.AliveEnemies = self.AliveEnemies - 1
	if self.AliveEnemies < 0 then
		self.AliveEnemies = 0
	end
end

return M
