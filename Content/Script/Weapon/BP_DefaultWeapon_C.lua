---@type BP_WeaponBase_C
local M = UnLua.Class("Weapon.BP_WeaponBase_C")

function M:UserConstructionScript()
	self.Super.UserConstructionScript(self)
	self.InfiniteAmmo = true
	self.ProjectileClass = UE.UClass.Load("/Game/Core/Blueprints/Weapon/BP_DefaultProjectile.BP_DefaultProjectile_C")
	self.MuzzleSocketName = "Muzzle"
	self.World = self:GetWorld()
end

function M:SpawnProjectile()
	-- 获取射击位置和旋转信息
	local Transform = self:GetFireInfo()

	-- 生成随机RGB颜色值（范围0-1）
	local R = UE.UKismetMathLibrary.RandomFloat()-- 红色分量
	local G = UE.UKismetMathLibrary.RandomFloat()-- 绿色分量
	local B = UE.UKismetMathLibrary.RandomFloat()-- 蓝色分量

	-- 创建基础颜色表（使用不透明度1.0）
	local BaseColor = {}
	BaseColor[0] = UE.FLinearColor(R, G, B, 1.0)-- 索引0存储颜色数据

	-- 在世界中生成投射物(要生成的投射物类,生成位置和旋转,碰撞处理方式,所有者,控制者,投射物蓝图路径,传递的颜色参数)
	self.World:SpawnActor(self.ProjectileClass, Transform, UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, self, self.Instigator, "Weapon.BP_DefaultProjectile_C", BaseColor)
end

return M
