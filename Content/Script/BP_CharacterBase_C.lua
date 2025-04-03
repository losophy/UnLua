---@type BP_CharacterBase_C
local M = UnLua.Class()

function M:Initialize(Initializer)
	self.IsDead = false
	self.BodyDuration = 3.0
	self.BoneName = nil
	local Health = 100
	self.Health = Health
	self.MaxHealth = Health
end

--function M:UserConstructionScript()
--end

function M:ReceiveBeginPlay()
	-- 生成武器对象
	local Weapon = self:SpawnWeapon()

	if Weapon then
		-- 将武器附加到指定的组件（WeaponPoint）
		-- 参数说明：
		-- 1. 目标组件（self.WeaponPoint）
		-- 2. 附加插槽名称（nil表示默认插槽）
		-- 3-5. 位置/旋转/缩放规则（全部使用SnapToTarget立即对齐）
		Weapon:K2_AttachToComponent(self.WeaponPoint, nil, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget)
		self.Weapon = Weapon
	end
end

function M:SpawnWeapon()
	return nil
end

function M:StartFire_Server_RPC()
	self:StartFire_Multicast()
end

function M:StartFire_Multicast_RPC()
	if self.Weapon then
		self.Weapon:StartFire()
	end
end

function M:StopFire_Server_RPC()
	self:StopFire_Multicast()
end

function M:StopFire_Multicast_RPC()
	if self.Weapon then
		self.Weapon:StopFire()
	end
end

function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
	if not self.IsDead then
		local Health = self.Health - Damage
		self.Health = math.max(Health, 0)

		if Health <= 0.0 then
			-- 触发死亡事件（网络同步）
			self:Died_Multicast(DamageType)

			-- 启动协程延迟销毁（避免立即消失）
			local co = coroutine.create(M.Destroy)
			coroutine.resume(co, self, self.BodyDuration)
		end
	end
end

function M:Died_Multicast_RPC(DamageType)
	self.IsDead = true

	-- 禁用胶囊体碰撞（防止与其他物体继续交互）
	self.CapsuleComponent:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)

	-- 停止所有开火行为
	self:StopFire()

	-- 解除控制器的占有（使角色失去玩家控制）
	local Controller = self:GetController()
	if Controller then
		Controller:UnPossess()
	end
end

function M:Destroy(Duration)
	UE.UKismetSystemLibrary.Delay(self, Duration)
	if not self:IsValid() then
		return false
	end

	-- 优先销毁武器（避免悬空引用）
	if self.Weapon then
		self.Weapon:K2_DestroyActor()
	end

	-- 销毁自身
	self:K2_DestroyActor()
end

--让角色的网格体（Mesh）切换为布娃娃物理模拟状态
function M:ChangeToRagdoll()
	--角色会像布娃娃一样受重力影响自然倒下，关节部位会物理摆动
	self.Mesh:SetSimulatePhysics(true)
end

return M
